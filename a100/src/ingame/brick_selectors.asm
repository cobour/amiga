  ifnd        BRICK_SELECTORS_ASM
BRICK_SELECTORS_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/brick_selectors_internal.i"
  include     "../a100/src/ingame/sfx.i"

brick_selectors_init:

  bsr         .init_data

; fills all three selectors with placeholder bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get active selector - gfx and mask pointers
  move.l      #f000_gfx_active_selector,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data
  lea.l       active_selector_metadata(pc),a2
  move.l      a1,(a2)+
  move.l      d0,(a2)+
  move.l      d1,(a2)

  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_small,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data

  ; store values for later use
  lea.l       small_bricks_metadata(pc),a2
  move.l      a1,(a2)+
  move.l      d0,(a2)+
  move.l      d1,(a2)

  ; use 8th brick as placeholder
  addq.l      #7,d0
  addq.l      #7,d1

  ; init first selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #SelectorOffset_1,d2
  bsr.s       .is_sub_selector

  ; init second selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #SelectorOffset_2,d2
  bsr.s       .is_sub_selector

  ; init third selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #SelectorOffset_3,d2

; fills one selector with identical bricks
; in:
;   d0 - pointer to source gfx
;   d1 - pointer to source mask
;   d2 - pointer to target
.is_sub_selector:

  ; rows loop
  moveq.l     #4,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #4,d6
  move.l      d2,d3
.ig_columns_loop:

  bsr         draw_one_brick

  ; next columns loop iteration
  addq.l      #1,d3
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*8),d2
  dbf         d7,.ig_rows_loop

  rts

.init_data:
  bsr         clear_vars

  ; initializes selectors data structures
  lea.l       selectors(pc),a1
  moveq.l     #bs_sizeof,d6
  moveq.l     #2,d7
.id_loop:
  move.l      a1,a0
  bsr.s       reset_brick_selector
  add.l       d6,a1
  dbf         d7,.id_loop

  rts

; resets data structure of a single brick selector
; does not trigger redraw
; does not check structure size, code MUST be changed when structure size is changed
; in:
;   a0 - pointer to data structure
reset_brick_selector:
  moveq.l     #0,d0
  move.l      #$07070707,d1
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.w      d1,(a0)
  rts

; fills data structures of all three selectors with new random bricks
brick_selectors_refill:
  lea.l       selectors(pc),a1
  moveq.l     #bs_sizeof,d0
  moveq.l     #2,d7
.bsr_loop: 

; get random brick
  bsr         get_random_brick
  move.l      (a0),bs_big(a1)
  move.l      4(a0),bs_small(a1)
  clr.b       bs_empty(a1)

; clear bs_area
  moveq.l     #24,d6
  lea.l       bs_area(a1),a0
.bsr_bs_area_clr_loop:
  clr.b       (a0)+
  dbf         d6,.bsr_bs_area_clr_loop

; fill bs_area - init
  move.l      bs_small(a1),a0
  move.l      df_idx_ptr_rawdata(a0),a2
  lea.l       df_idx_metadata(a0),a3
  move.w      df_tld_plf_width(a3),d1
  move.w      df_tld_plf_height(a3),d2
  subq.w      #1,d1
  subq.w      #1,d2

; x- and y-offsets in bs_area
  lea.l       bs_area(a1),a3
  move.l      a3,d4
  moveq.l     #0,d5
  lea.l       .x_offsets(pc),a3
  move.b      (a3,d1.w),d5
  add.l       d5,d4
  lea.l       .y_offsets(pc),a3
  move.b      (a3,d2.w),d5
  add.l       d5,d4

; fill bs_area - loops
  move.w      d2,d6
.bsr_bs_area_fill_row_loop:
  move.w      d1,d5
  move.l      d4,a3
.bsr_bs_area_fill_column_loop:
  move.w      (a2)+,d3
  move.b      d3,(a3)+
  dbf         d5,.bsr_bs_area_fill_column_loop
  addq.w      #5,d4
  dbf         d6,.bsr_bs_area_fill_row_loop

; next selector
  add.l       d0,a1
  dbf         d7,.bsr_loop

; trigger redraw (all draw-operations in main loop; not in IRQ)
  lea.l       redraw_countdown(pc),a0
  move.w      #BsDrawCountdown,(a0)+
  clr.l       (a0)

  rts

.x_offsets:
  dc.b        2,1,1,0,0,0
.y_offsets:
  dc.b        10,5,5,0,0,0

; draws one small brick with cpu (because 8px draws are pita with blitter)
; does not check metadata, code MUST be changed when small bricks gfx or screen dimensions are changed
;   d0 - pointer to source gfx
;   d1 - pointer to source mask
;   d3 - pointer to target
draw_one_brick:
  movem.l     d4/a0-a2,-(sp)

  move.l      d0,a0
  move.l      d1,a1
  move.l      d3,a2

  macro       BLT_ROW
  move.b      \1*8(a1),d4
  and.b       \1*IgScreenWidthBytes(a2),d4
  or.b        \1*8(a0),d4
  move.b      d4,\1*IgScreenWidthBytes(a2)
  endm

  BLT_ROW     0
  BLT_ROW     1
  BLT_ROW     2
  BLT_ROW     3
  BLT_ROW     4
  BLT_ROW     5
  BLT_ROW     6
  BLT_ROW     7
  BLT_ROW     8
  BLT_ROW     9
  BLT_ROW     10
  BLT_ROW     11
  BLT_ROW     12
  BLT_ROW     13
  BLT_ROW     14
  BLT_ROW     15
  BLT_ROW     16
  BLT_ROW     17
  BLT_ROW     18
  BLT_ROW     19
  BLT_ROW     20
  BLT_ROW     21
  BLT_ROW     22
  BLT_ROW     23
  BLT_ROW     24
  BLT_ROW     25
  BLT_ROW     26
  BLT_ROW     27
  BLT_ROW     28
  BLT_ROW     29
  BLT_ROW     30
  BLT_ROW     31
  BLT_ROW     32
  BLT_ROW     33
  BLT_ROW     34
  BLT_ROW     35
  BLT_ROW     36
  BLT_ROW     37
  BLT_ROW     38
  BLT_ROW     39

  movem.l     (sp)+,d4/a0-a2
  rts

brick_selectors_draw:
  bsr         .draw_active_selector_mark

  ; check if redraw of all three selectors is currently happening
  lea.l       redraw_countdown(pc),a0
  move.w      (a0)+,d0
  tst.w       d0
  beq.s       .exit
  ; TODO: if not, check if redraw of single selector is currently happening

  ; set redraw scheme if necessary (different schemes possible)
  tst.l       (a0)
  bne.s       .scheme_is_set
  lea.l       .redraw_scheme(pc),a1
  move.l      a1,(a0)
.scheme_is_set:

  ; check if and which bricks must be drawn
  move.l      (a0),a0
  moveq.l     #0,d2
  moveq.l     #24,d7
.check_loop:
  move.b      (a0,d2.w),d1
  cmp.b       d0,d1
  beq.s       .draw  
.check_second_draw:
  subq.b      #1,d1
  cmp.b       d0,d1
  bne.s       .next
.draw:
  ; selector 0
  lea.l       selectors(pc),a1
  move.l      #SelectorOffset_1,d3
  bsr.s       .draw_brick
  ; selector 1
  lea.l       selectors+bs_sizeof(pc),a1
  move.l      #SelectorOffset_2,d3
  bsr.s       .draw_brick
  ; selector 2
  lea.l       selectors+bs_sizeof+bs_sizeof(pc),a1
  move.l      #SelectorOffset_3,d3
  bsr.s       .draw_brick
.next:
  addq.b      #1,d2
  dbf         d7,.check_loop

  ; redraw is done for this frame
  lea.l       redraw_countdown(pc),a0
  sub.w       #1,(a0)
.exit:
  rts

; in:
;   a1 - pointer to bs_area
;   d2 - number of brick (0..24)
;   d3 - offset of selector in framebuffer
; ALLOWED TO USE: a2,a3,d4,d5,d6
.draw_brick:
  ; destination address
  move.l      d2,d4
  add.l       d4,d4
  add.l       d4,d4
  lea.l       .brick_offsets(pc),a2
  move.l      (a2,d4.w),d4
  add.l       d4,d3
  add.l       ig_om_backbuffer(a4),d3
  ; d3 = destination pointer

  ; number of gfx brick
  move.l      a1,a2
  lea.l       bs_area(a2),a2
  moveq.l     #0,d5
  move.b      (a2,d2.w),d5
  ; d5 = number of gfx brick

  movem.l     d0-d1,-(sp)
  move.l      small_bricks_gfx(pc),d0
  add.l       d5,d0
  ; d0 = gfx pointer
  move.l      small_bricks_mask(pc),d1
  add.l       d5,d1
  ; d1 = mask pointer
  bsr         draw_one_brick
  movem.l     (sp)+,d0-d1
  rts

.redraw_scheme:
  dc.b        BsDrCd_1,BsDrCd_1,BsDrCd_1,BsDrCd_1,BsDrCd_1
  dc.b        BsDrCd_2,BsDrCd_2,BsDrCd_2,BsDrCd_2,BsDrCd_2
  dc.b        BsDrCd_3,BsDrCd_3,BsDrCd_3,BsDrCd_3,BsDrCd_3
  dc.b        BsDrCd_4,BsDrCd_4,BsDrCd_4,BsDrCd_4,BsDrCd_4
  dc.b        BsDrCd_5,BsDrCd_5,BsDrCd_5,BsDrCd_5,BsDrCd_5
  even

; offsets of bricks in selector in framebuffer
.brick_offsets:
; row 0
  dc.l        0,1,2,3,4
; row 1
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*8)
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*8)+1
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*8)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*8)+3
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*8)+4
; row 2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+1
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+3
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+4
; row 3
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*24)
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*24)+1
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*24)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*24)+3
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*24)+4
; row 4
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+1
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+3
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+4

; draws active selector marker
.draw_active_selector_mark:

  ; restore background if necessary
  lea.l       active_selector_mark_backups(pc),a0
  move.l      (a0),d1
  tst.l       d1
  beq.s       .restore_not_necessary

  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                     ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                          ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-2,BLTDMOD(a6)                  ; modulos for source and target
  clr.w       BLTAMOD(a6)
  move.l      d1,BLTDPTH(a6)                                     ; pointers
  move.l      4(a0),BLTAPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)           ; start blit

.restore_not_necessary:

  ; backup background
  lea.l       .active_selector_mark_offsets(pc),a1
  move.w      active_selection(pc),d0
  add.w       d0,d0
  add.w       d0,d0
  move.l      (a1,d0.w),d1                                       ; d1 = offset in screenbuffer
  add.l       ig_om_backbuffer(a4),d1
  move.l      d1,(a0)

  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                     ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                          ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-2,BLTAMOD(a6)                  ; modulos for source and target
  clr.w       BLTDMOD(a6)
  move.l      d1,BLTAPTH(a6)                                     ; pointers
  move.l      4(a0),BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)           ; start blit

  ; draw marker
  WAIT_BLT
  move.w      #%0000111111001010,BLTCON0(a6)                     ; masked copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                          ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  clr.w       BLTAMOD(a6)                                        ; modulos for source and target
  clr.w       BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,BLTCMOD(a6)
  move.w      #IgScreenWidthBytes-2,BLTDMOD(a6)
  move.l      active_selector_mask(pc),BLTAPTH(a6)               ; pointers
  move.l      active_selector_gfx(pc),BLTBPTH(a6)
  move.l      d1,BLTCPTH(a6)
  move.l      d1,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)           ; start blit
 
  ; switch pointers for next frame
  lea.l       active_selector_mark_backups(pc),a0
  move.l      (a0),d0
  move.l      4(a0),d1
  move.l      8(a0),(a0)
  move.l      12(a0),4(a0)
  move.l      d0,8(a0)
  move.l      d1,12(a0)

  rts

; offsets in screenbuffer of the three possible positions
.active_selector_mark_offsets:
  dc.l        22+(IgScreenBitPlanes*IgScreenWidthBytes*27)
  dc.l        22+(IgScreenBitPlanes*IgScreenWidthBytes*87)
  dc.l        22+(IgScreenBitPlanes*IgScreenWidthBytes*147)

; processes pending events if ig_om_act_mode is IgModeSelect
brick_selectors_process_events:
  cmp.b       #IgModeSelect,ig_om_act_mode(a4)
  bne         .exit

.process_event:
  bsr         get_next_event
  tst.b       d0
  blt         .exit

.pe_up:
  cmp.b       #EventUp,d0
  bne.s       .pe_down
  lea.l       active_selection(pc),a0
  tst.w       (a0)
  beq.s       .pe_other
  sub.w       #1,(a0)
  SFX         f000_sfx_step
  bra.s       .process_event
.pe_down:
  cmp.b       #EventDown,d0
  bne.s       .pe_select
  lea.l       active_selection(pc),a0
  cmp.w       #2,(a0)
  beq.s       .pe_other
  add.w       #1,(a0)
  SFX         f000_sfx_step
  bra.s       .process_event
.pe_select:
  cmp.b       #EventSelect,d0
  bne.s       .pe_other
  SFX         f000_sfx_select
  nop                                                            ; TODO: handle selection of brick
  bra         .process_event
.pe_other:
  ; ignore all other events
  SFX         f000_sfx_error
  bra         .process_event

.exit:
  rts

;
; vars section
;

clear_vars:
  moveq.l     #0,d0
  lea.l       small_bricks_metadata(pc),a0

  ; gfx ptrs
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  ; redraw all three selectors
  move.w      d0,(a0)+
  move.l      d0,(a0)+
  ; selection
  move.w      d0,(a0)+
  move.l      d0,(a0)+
  move.l      a5,(a0)
  add.l       #ig_cm_asm_backup_0,(a0)+
  move.l      d0,(a0)+
  move.l      a5,(a0)
  add.l       #ig_cm_asm_backup_1,(a0)+
  move.l      a1,(a0)+

  rts

; gfx ptrs
small_bricks_metadata:
  dc.l        0
small_bricks_gfx:
  dc.l        0
small_bricks_mask:
  dc.l        0
active_selector_metadata:
  dc.l        0
active_selector_gfx:
  dc.l        0
active_selector_mask:
  dc.l        0

; redraw all three selectors
redraw_countdown:
  dc.w        0
redraw_scheme:
  dc.l        0

; selection
active_selection:
  dc.w        0                                                  ; 0, 1 or 2
active_selector_mark_backups:
  dcb.l       4                                                  ; 2 pairs of: pointer in screenbuffer for background backups and pointer to backup buffer


; brick selectors structures
selectors: ; see bs_*
  dcb.b       3*bs_sizeof

  endif                                                          ; ifnd BRICK_SELECTORS_ASM
