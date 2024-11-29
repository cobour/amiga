  ifnd        BRICK_SELECTORS_ASM
BRICK_SELECTORS_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/brick_selectors_internal.i"

brick_selectors_init:

  bsr         .init_data

; fills all three selectors  with empty bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
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

; fills one selector with empty bricks
; in:
;   a1 - pointer to small bricks metadata
;   d0 - pointer to source gfx
;   d1 - pointer to source mask
;   d2 - pointer to target
.is_sub_selector:

  WAIT_BLT

  ; empty brick is on the left of word
  move.w      #$ff00,BLTAFWM(a6)
  move.w      #$ff00,BLTALWM(a6)

  ; modulos
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; rows loop
  moveq.l     #4,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #4,d6
  move.l      d2,d3
  move.l      #$8000,d5
.ig_columns_loop:

  WAIT_BLT
  ; shift 0 or 8 px to the right; masked copy
  move.w      d5,d4
  move.w      d4,BLTCON1(a6)
  or.w        #%0000111111001010,d4
  move.w      d4,BLTCON0(a6)

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(8*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next columns loop iteration
  btst        #0,d6
  bne.s       .1
  addq.l      #2,d3
.1:
  swap        d5
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*8),d2
  dbf         d7,.ig_rows_loop

  rts

; initializes data structure
.init_data:
  lea.l       selectors(pc),a0
  moveq.l     #0,d0
  moveq.l     #(3*bs_sizeof/2)-1,d7
.id_array_loop:
  move.w      d0,(a0)+
  dbf         d7,.id_array_loop

  rts

brick_selectors_refill:
  lea.l       selectors(pc),a1
  moveq.l     #bs_sizeof,d0
  moveq.l     #2,d7
.bsr_loop: 

; get random brick
  bsr         get_random_brick
  move.l      (a0),bs_big(a1)
  move.l      4(a0),bs_small(a1)

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

brick_selectors_draw:
  ; check if redraw is currently taking place
  lea.l       redraw_countdown(pc),a0
  move.w      (a0)+,d0
  tst.w       d0
  beq.s       .exit

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
  add.l       d3,d4
  add.l       ig_om_backbuffer(a4),d4
  ; d4 = destination address

  ; number of gfx brick
  move.l      a1,a2
  lea.l       bs_area(a2),a2
  moveq.l     #0,d5
  move.b      (a2,d2.w),d5
  ; d5 = number of gfx brick

  WAIT_BLT

  ; modulos
  move.l      small_bricks_metadata(pc),a2
  move.w      df_iff_width(a2),d6
  lsr.w       #3,d6
  subq.w      #2,d6
  move.w      d6,BLTAMOD(a6)
  move.w      d6,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d6
  move.w      d6,BLTCMOD(a6)
  move.w      d6,BLTDMOD(a6)

  ; check for alignment of source
  btst        #0,d5
  bne.s       .odd_source

  move.w      #$ff00,BLTAFWM(a6)
  move.w      #$ff00,BLTALWM(a6)

  btst        #0,d4
  bne.s       .even_source_odd_destination

  clr.w       BLTCON1(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  bra.s       .set_pointers_and_blit

.even_source_odd_destination:
  move.w      #$8000,BLTCON1(a6)
  move.w      #%1000111111001010,BLTCON0(a6)
  bra.s       .set_pointers_and_blit

.odd_source:
  
  move.w      #$00ff,BLTAFWM(a6)
  move.w      #$00ff,BLTALWM(a6)

  btst        #0,d4
  bne.s       .odd_source_odd_destination

  move.w      #$8000,BLTCON1(a6)
  move.w      #%1000111111001010,BLTCON0(a6)
  addq.l      #8,d5                                              ; TODO: check correctness
  bra.s       .set_pointers_and_blit

.odd_source_odd_destination:
  clr.w       BLTCON1(a6)
  move.w      #%0000111111001010,BLTCON0(a6)

.set_pointers_and_blit:
  ; source pointers
  move.l      small_bricks_mask(pc),d6
  add.l       d5,d6
  move.l      d6,BLTAPTH(a6)
  move.l      small_bricks_gfx(pc),d6
  add.l       d5,d6
  move.l      d6,BLTBPTH(a6)

  ; destination pointers
  move.l      d4,BLTCPTH(a6)
  move.l      d4,BLTDPTH(a6)

  ; start blit
  move.w      #(8*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

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

;
; vars section
;

small_bricks_metadata:
  dc.l        0
small_bricks_gfx:
  dc.l        0
small_bricks_mask:
  dc.l        0

selectors: ; see bs_*
  dcb.b       3*bs_sizeof

redraw_countdown:
  dc.w        0
redraw_scheme:
  dc.l        0

  endif                                                          ; ifnd BRICK_SELECTORS_ASM
