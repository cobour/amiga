  ifnd        BRICK_SELECTORS_ASM
BRICK_SELECTORS_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/brick_selectors_internal.i"
  include     "../a100/src/ingame/sfx.i"

bs_init:

  bsr         .init_data

; fills all three selectors with placeholder bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get active selector - gfx and mask pointers
  move.l      #f000_gfx_active_selector_2,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data
  lea.l       bs_active_selector_metadata(pc),a2
  move.l      a1,(a2)+
  move.l      d0,(a2)+
  move.l      d1,(a2)

  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_small_2,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data

  ; store values for later use
  lea.l       bs_small_bricks_metadata(pc),a2
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

  bsr         bs_draw_one_brick

  ; next columns loop iteration
  addq.l      #1,d3
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*8),d2
  dbf         d7,.ig_rows_loop

  rts

.init_data:
  bsr         bs_clear_vars

  ; initializes selectors data structures
  lea.l       bs_selectors(pc),a1
  moveq.l     #bs_sizeof,d6
  moveq.l     #2,d7
.id_loop:
  move.l      a1,a0
  bsr.s       bs_reset_selector
  add.l       d6,a1
  dbf         d7,.id_loop

  rts

; resets data structure of a single brick selector
; does not trigger redraw
; does not check structure size, code MUST be changed when structure size is changed
; in:
;   a0 - pointer to data structure
bs_reset_selector:
  movem.l     d0-d1/a3,-(sp)
  move.l      a0,a3
  bsr         bs_clear_selector
  moveq.l     #0,d0
  move.l      d0,(a0)+
  move.l      d0,(a0)
  movem.l     (sp)+,d0-d1/a3
  rts

; called when switched to selection-mode
bs_gained_mode:

  ; count empty selectors
  lea.l       bs_selectors(pc),a0
  moveq.l     #bs_sizeof,d0
  moveq.l     #0,d1                                              ; d1 = number of empty selectors
  
  tst.b       bs_empty(a0)
  beq.s       .empty_0
  addq.l      #1,d1
.empty_0:
  add.l       d0,a0
  tst.b       bs_empty(a0)
  beq.s       .empty_1
  addq.l      #1,d1
.empty_1:
  add.l       d0,a0
  tst.b       bs_empty(a0)
  beq.s       .empty_2
  addq.l      #1,d1
.empty_2:

  ; find first filled selector
  lea.l       bs_selectors(pc),a0
  moveq.l     #-1,d2                                             ; d2 = index of first filled selector

  tst.b       bs_empty(a0)
  bne.s       .first_filled_0
  moveq.l     #0,d2
  bra.s       .check_refill
.first_filled_0:
  add.l       d0,a0
  tst.b       bs_empty(a0)
  bne.s       .first_filled_1
  moveq.l     #1,d2
  bra.s       .check_refill
.first_filled_1:
  add.l       d0,a0
  tst.b       bs_empty(a0)
  bne.s       .check_refill
  moveq.l     #2,d2

.check_refill:
  ; refill when all three selectors are empty
  cmp.b       #3,d1
  bne.s       .check_single
  moveq.l     #0,d6                                              ; random bricks
  bra         bs_refill                                          ; implicit rts

.check_single:
  ; set marker to selector, when exactly one selector is filled
  cmp.b       #2,d1
  bne.s       .exit
  lea.l       bs_active_selection(pc),a0
  move.w      (a0),d1                                            ; old pos
  move.w      d2,(a0)
  sub.w       d2,d1
  tst.w       d1
  beq.s       .fill_sel_struct                                   ; no need to move selector mark
  lea.l       bs_active_selector_mark_add(pc),a0
  tst.w       d1
  blt.s       .pos_add
  move.l      #ActiveSelectorMarkAddUp,(a0)
  bra.s       .fill_sel_struct
.pos_add:
  move.l      #ActiveSelectorMarkAddDown,(a0)
.fill_sel_struct:
  add.w       d2,d2
  add.w       d2,d2
  lea.l       .struct_positions(pc),a1
  move.l      (a1,d2.w),d2
  lea.l       bs_selectors(pc),a1
  add.l       d2,a1
  lea.l       bs_active_selection_struct(pc),a0
  move.l      a1,(a0)

.exit:
  rts

.struct_positions:
  dc.l        0
  dc.l        bs_sizeof
  dc.l        bs_sizeof+bs_sizeof

bs_init_from_savegame_or_random:
  ; init from savegame data
  lea.l       ig_om_savegame(a4),a3
  bsr         sg_is_used
  tst.l       d0
  beq.s       .no_savegame
  ; bricks from savegame
  moveq.l     #1,d6
  bsr.s       bs_refill
  ; init active selector mark (set to first filled selector)
  lea.l       bs_selectors(pc),a0
  moveq.l     #bs_sizeof,d0
  moveq.l     #0,d7
.find_first_filled_loop:
  tst.b       bs_empty(a0)
  bne.s       .find_first_filled_loop_next
  lea.l       bs_active_selection(pc),a1
  move.w      d7,(a1)+
  move.l      a0,(a1)
  ; set bs_active_selector_mark_add (only if second or third selector)
  tst.b       d7
  beq.s       .exit
  lea.l       bs_active_selector_mark_add(pc),a0
  move.l      #ActiveSelectorMarkAddDown,(a0)
  bra.s       .exit
.find_first_filled_loop_next:
  add.l       d0,a0
  addq.l      #1,d7
  cmp.b       #3,d7
  bne.s       .find_first_filled_loop
  bra.s       .exit
.no_savegame:
  ; random bricks
  moveq.l     #0,d6
  bsr.s       bs_refill

.exit:
  rts

; fills data structures of all three selectors with new bricks
; in:
;   d6 - zero => get random bricks; non-zero => get from savegame
bs_refill:
  lea.l       bs_selectors(pc),a1
  lea.l       ig_om_savegame(a4),a2
  lea.l       sg_data_bricks(a3),a2
  moveq.l     #bs_sizeof,d0
  moveq.l     #2,d7
.bsr_loop: 

  tst.l       d6
  beq.s       .bsr_loop_random
  move.l      (a2)+,d1
  tst.l       d1
  bne.s       .bsr_loop_from_savegame_not_empty
  move.b      #1,bs_empty(a1)
  bra.s       .bsr_loop_next
.bsr_loop_from_savegame_not_empty:
  bsr         b_get_brick
  move.l      d2,bs_big(a1)
  move.l      d3,bs_small(a1)
  bra.s       .bsr_loop_init_brick
.bsr_loop_random:
; get random brick
  bsr         b_get_random_brick
  move.l      (a0),bs_big(a1)
  move.l      4(a0),bs_small(a1)

.bsr_loop_init_brick:
  bsr         bs_fill_bs_area

.bsr_loop_next:
; next selector
  add.l       d0,a1
  dbf         d7,.bsr_loop

; trigger redraw (all draw-operations in main loop; not in IRQ)
  lea.l       bs_redraw_all_struct(pc),a0
  move.w      #BsDrawCountdown,(a0)+
  clr.l       (a0)

  move.b      #1,ig_om_god_request(a4)

  rts

; gets pointer list (null-terminated) to selectable bricks
; out:
;   a0 - pointer to pointerlist
bs_get_selectable_bricks:
  movem.l     d6-d7/a1,-(sp)

  lea         .pointerlist(pc),a0
  lea         bs_selectors(pc),a1
  moveq.l     #bs_sizeof,d6
  moveq.l     #2,d7
.loop:
  tst.b       bs_empty(a1)
  bne.s       .next
  move.l      bs_big(a1),(a0)+
.next:
  add.l       d6,a1
  dbf         d7,.loop

  ; TODO: check for redundant pointers in pointerlist and remove them

  clr.l       (a0)
  lea         .pointerlist(pc),a0

  movem.l     (sp)+,d6-d7/a1
  rts

.pointerlist:
  dcb.l       4

; fills bs_area of bs-struct with brick from metadata (bs_small)
; in:
;   a1 - pointer to bs-struct
bs_fill_bs_area:
  movem.l     d1-d6/a0/a2-a3,-(sp)

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

  movem.l     (sp)+,d1-d6/a0/a2-a3
  rts

.x_offsets:
  dc.b        2,1,1,0,0,0
.y_offsets:
  dc.b        10,5,5,0,0,0

; fills bs_area from bs_small and triggers redraw of active (aka selected) brick selector
bs_refill_selected_brick_selector:
  move.l      bs_active_selection_struct(pc),a1
  bsr         bs_fill_bs_area
  bra         bs_redraw_active_selector
  ; no rts - bra to bs_redraw_active_selector which does rts at the end

; draws one small brick with cpu (because 8px draws are pita with blitter)
; does not check metadata, code MUST be changed when small bricks gfx or screen dimensions are changed
;   d0 - pointer to source gfx
;   d1 - pointer to source mask
;   d3 - pointer to target
bs_draw_one_brick:
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

bs_draw:
  bsr         .draw_active_selector_mark

  ; check if redraw of all three selectors is currently happening
  lea.l       bs_redraw_all_struct(pc),a0
  move.w      (a0)+,d0
  tst.w       d0
  bne.s       .redraw_all

  ; check if redraw of single selector is currently happening
  lea.l       bs_redraw_single_structs(pc),a0
  ; check 0
  lea.l       bs_selectors(pc),a1
  move.l      #SelectorOffset_1,d3
  moveq.l     #0,d1
  move.w      (a0)+,d0
  tst.w       d0
  bne.s       .redraw_single
  ; check 1
  lea.l       bs_selectors+bs_sizeof(pc),a1
  move.l      #SelectorOffset_2,d3
  moveq.l     #bs_sizeof,d1
  addq.l      #bsrd_sizeof-2,a0
  move.w      (a0)+,d0
  tst.w       d0
  bne.s       .redraw_single
  ; check 2
  lea.l       bs_selectors+bs_sizeof+bs_sizeof(pc),a1
  move.l      #SelectorOffset_3,d3
  moveq.l     #bs_sizeof*2,d1
  addq.l      #bsrd_sizeof-2,a0
  move.w      (a0)+,d0
  tst.w       d0
  bne.s       .redraw_single

  ; no redraw at all
  bra.s       .exit

.redraw_all:
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
  lea.l       bs_selectors(pc),a1
  move.l      #SelectorOffset_1,d3
  bsr.s       .draw_brick
  ; selector 1
  lea.l       bs_selectors+bs_sizeof(pc),a1
  move.l      #SelectorOffset_2,d3
  bsr.s       .draw_brick
  ; selector 2
  lea.l       bs_selectors+bs_sizeof+bs_sizeof(pc),a1
  move.l      #SelectorOffset_3,d3
  bsr.s       .draw_brick
.next:
  addq.b      #1,d2
  dbf         d7,.check_loop

  ; redraw is done for this frame
  lea.l       bs_redraw_all_struct(pc),a0
  sub.w       #1,(a0)
.exit:
  rts

; redraws single selector
; in:
;   a0 - pointer to scheme pointer
;   a1 - pointer to bs struct
;   d1 - offset of struct in selectors(pc)
;   d3 - offset of selectors in framebuffer
.redraw_single:

  ; set redraw scheme if necessary (different schemes possible)
  tst.l       (a0)
  bne.s       .single_scheme_is_set
  lea.l       .redraw_scheme(pc),a2
  move.l      a2,(a0)
.single_scheme_is_set:

  lea.l       bs_selectors(pc),a2
  add.l       d1,a2                                              ; a2 = selector struct

  ; check if and which bricks must be drawn
  move.l      (a0),a2
  moveq.l     #0,d2
  moveq.l     #24,d7
.single_check_loop:
  move.b      (a2,d2.w),d1
  cmp.b       d0,d1
  beq.s       .single_draw  
.single_check_second_draw:
  subq.b      #1,d1
  cmp.b       d0,d1
  bne.s       .single_next
.single_draw:
  movem.l     d3/a2,-(sp)
  bsr.s       .draw_brick
  movem.l     (sp)+,d3/a2
.single_next:
  addq.b      #1,d2
  dbf         d7,.single_check_loop

  subq.l      #2,a0
  sub.w       #1,(a0)
  rts

; in:
;   a1 - pointer to bs struct
;   d2 - number of brick (0..24)
;   d3 - offset of selector in framebuffer
; ALLOWED TO USE: a2,a3,d4,d5
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
  move.l      bs_small_bricks_gfx(pc),d0
  add.l       d5,d0
  ; d0 = gfx pointer
  move.l      bs_small_bricks_mask(pc),d1
  add.l       d5,d1
  ; d1 = mask pointer
  bsr         bs_draw_one_brick
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
  lea.l       bs_active_selector_mark_backups(pc),a0
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

  ; which marker?
  move.l      bs_active_selector_mask(pc),d6
  move.l      bs_active_selector_gfx(pc),d7
  cmp.b       #IgModeSelect,ig_om_act_mode(a4)
  beq.s       .asm_calc_pos
  addq.l      #2,d6
  addq.l      #2,d7

.asm_calc_pos:
  ; calc position
  lea.l       .active_selector_mark_offsets(pc),a1
  move.w      bs_active_selection(pc),d0
  add.w       d0,d0
  add.w       d0,d0
  move.l      (a1,d0.w),d1                                       ; d1 = target offset in screenbuffer

  lea.l       bs_active_selector_mark_ypos(pc),a2
  lea.l       bs_active_selector_mark_add(pc),a3
  move.l      (a2),d2
  move.l      (a3),d3
  add.l       d3,d2                                              ; d2 = current offset in screenbuffer
  move.l      d2,(a2)
  cmp.l       d1,d2
  bne.s       .target_offset_not_reached
  clr.l       (a3)
.target_offset_not_reached:
  move.l      d2,d1

  ; backup background
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
  moveq.l     #2,d0                                              ; modulos for source and target
  move.w      d0,BLTAMOD(a6)
  move.w      d0,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,BLTCMOD(a6)
  move.w      #IgScreenWidthBytes-2,BLTDMOD(a6)
  move.l      d6,BLTAPTH(a6)                                     ; pointers
  move.l      d7,BLTBPTH(a6)
  move.l      d1,BLTCPTH(a6)
  move.l      d1,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)           ; start blit
 
  ; switch pointers for next frame
.asm_next:
  lea.l       bs_active_selector_mark_backups(pc),a0
  move.l      (a0),d0
  move.l      4(a0),d1
  move.l      8(a0),(a0)
  move.l      12(a0),4(a0)
  move.l      d0,8(a0)
  move.l      d1,12(a0)

  rts

; offsets in screenbuffer of the three possible target positions
.active_selector_mark_offsets:
  dc.l        ActiveSelectorMarkerOffset0
  dc.l        ActiveSelectorMarkerOffset1
  dc.l        ActiveSelectorMarkerOffset2

; processes pending events if ig_om_act_mode is IgModeSelect
bs_process_events:
  cmp.b       #IgModeSelect,ig_om_act_mode(a4)
  bne         .exit

.process_event:
  bsr         ev_get_next_event
  tst.b       d0
  blt         .exit

  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  bne.s       .pe_up
  cmp.b       #$21,d0                                            ; S
  bne.s       .pe_up
  bsr         ig_save_game_and_return_to_mm
  bra.s       .process_event
.pe_up:
  cmp.b       #EventUp,d0
  bne.s       .pe_down
  bra.s       .pe_process_up
.pe_down:
  cmp.b       #EventDown,d0
  bne.s       .pe_select
  bra.s       .pe_process_down
.pe_select:
  cmp.b       #EventSelect,d0
  bne.s       .pe_other
  bra         .pe_process_select
.pe_other:
  ; ignore all other events
  SFX         f000_sfx_error
  bra.s       .process_event

.exit:
  rts

.pe_process_up:
  lea.l       bs_active_selection(pc),a0
  tst.w       (a0)
  beq         .pe_other
  sub.w       #1,(a0)
  lea.l       bs_active_selection_struct(pc),a0
  sub.l       #bs_sizeof,(a0)
  lea.l       bs_active_selector_mark_add(pc),a0
  move.l      #ActiveSelectorMarkAddUp,(a0)
  SFX         f000_sfx_step
  bra         .process_event

.pe_process_down:
  lea.l       bs_active_selection(pc),a0
  cmp.w       #2,(a0)
  beq.s       .pe_other
  add.w       #1,(a0)
  lea.l       bs_active_selection_struct(pc),a0
  add.l       #bs_sizeof,(a0)
  lea.l       bs_active_selector_mark_add(pc),a0
  move.l      #ActiveSelectorMarkAddDown,(a0)
  SFX         f000_sfx_step
  bra         .process_event

.pe_process_select:
  move.l      bs_active_selection_struct(pc),a1
  tst.b       bs_empty(a1)
  bne.s       .pe_process_select__empty
  bsr         ig_switch_mode_place
  bsr         ev_clear_event_queue
  bsr         bs_clear_selector
  bsr         bs_redraw_active_selector
  move.l      bs_big(a1),a1
  bsr         pf_set_brick
  SFX         f000_sfx_select
  bra         .process_event
.pe_process_select__empty:
  SFX         f000_sfx_error
  bra         .process_event

; fills empty blocks in selector's data structure
; in:
;   a1 - pointer to bs-struct
bs_clear_selector:
  movem.l     d0/a0,-(sp)
  move.l      #$07070707,d0
  move.l      a1,a0
  lea.l       bs_area(a0),a0
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.w      d0,(a0)
  movem.l     (sp)+,d0/a0
  rts

; triggers redraw of active selected selector
; bs_area must be set to desired result before calling this
bs_redraw_active_selector:
  movem.l     d0/a0,-(sp)
  moveq.l     #0,d0
  move.w      bs_active_selection(pc),d0
  add.w       d0,d0
  lea.l       .offsets(pc),a0
  move.w      (a0,d0.w),d0
  lea.l       bs_redraw_single_structs(pc),a0
  add.l       d0,a0
  move.w      #BsDrawCountdown,bsrd_countdown(a0)
  movem.l     (sp)+,d0/a0
  rts
.offsets:
  dc.w        0
  dc.w        bsrd_sizeof
  dc.w        bsrd_sizeof*2

; in:
;   a0 - pointer to sg_data* struct
bs_add_to_savegame:
  movem.l     d7/a0-a2,-(sp)

  ; when in placement mode, unselect the currently selected brick (so it is saved, too)
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .just_add
  move.l      bs_active_selection_struct(pc),a1
  clr.b       bs_empty(a1)
.just_add:

  ; add to savegame struct
  lea.l       bs_selectors(pc),a1
  lea.l       sg_data_bricks(a0),a0
  moveq.l     #2,d7
.loop:
  tst.b       bs_empty(a1)
  bne.s       .loop_is_empty
  move.l      bs_big(a1),a2
  move.l      (a2),(a0)+
  bra.s       .loop_next
.loop_is_empty:
  clr.l       (a0)+
.loop_next:
  lea.l       bs_sizeof(a1),a1
  dbf         d7,.loop
  movem.l     (sp)+,d7/a0-a2
  rts

;
; vars section
;

bs_clear_vars:
  moveq.l     #0,d0
  lea.l       bs_small_bricks_metadata(pc),a0

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
  ; redraw single selectors
  move.w      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  ; selection
  move.w      d0,(a0)+
  lea.l       bs_selectors(pc),a1
  move.l      a1,(a0)+
  move.l      d0,(a0)+
  move.l      a5,(a0)
  add.l       #ig_cm_asm_backup_0,(a0)+
  move.l      d0,(a0)+
  move.l      a5,(a0)
  add.l       #ig_cm_asm_backup_1,(a0)+
  move.l      #ActiveSelectorMarkerOffset0,(a0)+
  move.l      d0,(a0)+

  rts

; gfx ptrs
bs_small_bricks_metadata:
  dc.l        0
bs_small_bricks_gfx:
  dc.l        0
bs_small_bricks_mask:
  dc.l        0
bs_active_selector_metadata: ; marker
  dc.l        0
bs_active_selector_gfx: ; marker
  dc.l        0
bs_active_selector_mask: ; marker
  dc.l        0

; redraw all three selectors
bs_redraw_all_struct:
  dcb.b       bsrd_sizeof

; redraw single selectors
bs_redraw_single_structs:
  dcb.b       3*bsrd_sizeof

; selection
bs_active_selection:
  dc.w        0                                                  ; 0, 1 or 2
bs_active_selection_struct:
  dc.l        0                                                  ; pointer to bs-struct of bs_active_selection
bs_active_selector_mark_backups:
  dcb.l       4                                                  ; 2 pairs of: pointer in screenbuffer for background backups and pointer to backup buffer
bs_active_selector_mark_ypos:
  dc.l        ActiveSelectorMarkerOffset0                        ; actual y-pos as offset in screenbuffer
bs_active_selector_mark_add:
  dc.l        0                                                  ; value to add to ypos each drawn frame

; brick selectors structures
bs_selectors: ; see bs_*
  dcb.b       3*bs_sizeof

  endif                                                          ; ifnd BRICK_SELECTORS_ASM
