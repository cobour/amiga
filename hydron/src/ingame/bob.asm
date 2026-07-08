  ifnd       INGAME_BOB_ASM
INGAME_BBOB_ASM equ 1

  include    "src/ingame.i"
  include    "../common/src/system/blitter.i"

bob_init:
  ; init ig_om_bob_blt_height
  lea.l      ig_om_bob_blt_height(a4),a0
  moveq.l    #0,d0
  moveq.l    #IgScreenBitPlanes,d1
  moveq.l    #BobMaxHeight-1,d7
.blt_height_loop:
  move.w     d0,(a0)+
  add.w      d1,d0
  dbf        d7,.blt_height_loop

  rts

; in:
;   a0 - pointer to bob-struct
bob_clear:
  move.w     #-1,bob_status(a0)
  clr.l      bob_xpos(a0)
  clr.l      bob_ypos(a0)
  clr.l      bob_anim_offset(a0)
  clr.l      bob_restore_1a+bob_restore_offset(a0)
  clr.w      bob_restore_1a+bob_restore_bltsize(a0)
  clr.w      bob_restore_1a+bob_restore_modulo(a0)
  clr.l      bob_restore_2a+bob_restore_offset(a0)
  clr.w      bob_restore_2a+bob_restore_bltsize(a0)
  clr.w      bob_restore_2a+bob_restore_modulo(a0)
  clr.l      bob_restore_1b+bob_restore_offset(a0)
  clr.w      bob_restore_1b+bob_restore_bltsize(a0)
  clr.w      bob_restore_1b+bob_restore_modulo(a0)
  clr.l      bob_restore_2b+bob_restore_offset(a0)
  clr.w      bob_restore_2b+bob_restore_bltsize(a0)
  clr.w      bob_restore_2b+bob_restore_modulo(a0)
  rts

; for reuse of bob inside game-loop
; should be called when bob is removed
; in:
;   a0 - pointer to bob-struct
bob_clear_quick:
  move.w     #-1,bob_status(a0)
  clr.w      bob_restore_1a+bob_restore_bltsize(a0)
  clr.w      bob_restore_2a+bob_restore_bltsize(a0)
  clr.w      bob_restore_1b+bob_restore_bltsize(a0)
  clr.w      bob_restore_2b+bob_restore_bltsize(a0)
  rts

bob_update:
  move.l     ig_om_buffers_backbuffer(a4),a0
  move.l     ig_buffers_framebuffer_pointer(a0),ig_om_bob_targetbuffer(a4)
  rts

; in:
;   a0 - pointer to bob-struct
;   a1 - base pointer of target buffer
;   a2 - base pointer of source buffer
bob_restore:
  ; bob_restore_2a
  lea.l      bob_restore_2a(a0),a3
  move.w     bob_restore_bltsize(a3),d3
  beq.s      .restore_done
  bsr.s      .do_restore
  ; bob_restore_2b
  lea.l      bob_restore_2b(a0),a3
  move.w     bob_restore_bltsize(a3),d3
  beq.s      .restore_done
  bsr.s      .do_restore
.restore_done:
  ; copy restore 1 to restore 2
  move.l     a4,d4
  lea.l      bob_restore_1a(a0),a3
  lea.l      bob_restore_2a(a0),a4
  move.l     (a3)+,(a4)+
  move.l     (a3)+,(a4)+
  move.l     (a3)+,(a4)+
  move.l     (a3),(a4)
  move.l     d4,a4
  rts

; in:
;   a1   - base pointer of target buffer
;   a2   - base pointer of source buffer
;   a3   - pointer to bob_restore-struct
;   d3.w - BLTSIZE
.do_restore:
  move.l     bob_restore_offset(a3),d4
  move.l     a2,d0
  add.l      d4,d0                                                            ; source pointer
  move.l     a1,d1
  add.l      d4,d1                                                            ; target pointer
  move.w     bob_restore_modulo(a3),d2
  move.w     #$ffff,d6
  WAITBLT
  move.w     d6,BLTAFWM(a6)
  move.w     d6,BLTALWM(a6)
  move.w     #%0000100111110000,BLTCON0(a6)
  clr.w      BLTCON1(a6)
  move.w     d2,BLTAMOD(a6)
  move.w     d2,BLTDMOD(a6)
  move.l     d0,BLTAPT(a6)
  move.l     d1,BLTDPT(a6)
  move.w     d3,BLTSIZE(a6)
  rts

; in:
;   a0 - pointer to bob-struct
; DIRTIES A5 !!
bob_draw:
  move.w     d7,-(sp)
  move.l     bob_bobtype_pointer(a0),a2

  ; must clear BLTSIZE in both restore-structs to prevent phantom-restores
  clr.w      bob_restore_1a+bob_restore_bltsize(a0)
  clr.w      bob_restore_1b+bob_restore_bltsize(a0)

  ; default for BLTAFWM (lowword) and BLTALWM (highword)
  moveq.l    #-1,d7

  ; get bob dimensions
  move.w     bob_ypos(a0),d0                                                  ; d0 = min y
  swap       d0
  move.w     bobtype_height_blt(a2),d0
  swap       d0                                                               ; highword d0 = bob height for blit (lines*bitplanes)
  move.w     d0,d1
  move.w     bobtype_height(a2),d3
  add.w      d3,d1
  subq.w     #1,d1                                                            ; d1 = max y (-1 so it's the last row inside the bob, not the first line below the bob)
  swap       d1
  move.w     d3,d1
  swap       d1                                                               ; highword d1 = bob height
  move.w     bob_xpos(a0),d2                                                  ; d2 = min x
  swap       d2
  move.w     bobtype_width_words(a2),d2                                       ; highword d2 = blitter width in words
  swap       d2
  moveq.l    #0,d3
  move.w     d2,d3
  add.w      bobtype_width(a2),d3
  subq.w     #1,d3                                                            ; d3 = max x (-1 so it's the last column inside the bob, bot the first column right to the bob)
  moveq.l    #0,d4                                                            ; highword d4 = add to modulo
  
  ; adjust BLTALWM
  move.w     d2,d5
  and.w      #$000f,d5
  beq.s      .bltalwm_is_fine
  swap       d7
  clr.w      d7
  swap       d7
.bltalwm_is_fine:

  ;
  ; check if bob is completely outside screen
  ;
 
  ; upper border
  tst.w      d1
  blt        .end_draw_bob
  ; lower border
  cmp.w      #IgScreenHeight-1,d0
  bgt        .end_draw_bob
  ; left border
  tst.w      d3
  blt        .end_draw_bob
  ; right border
  cmp.w      #IgScreenWidth-1,d2
  bgt        .end_draw_bob

  ;
  ; check border intersection
  ;

  moveq.l    #0,d6
  sub.l      a5,a5

  ; check bob against upper screen border
  tst.w      d0
  bge.s      .check_lower_border
  move.w     d0,d6
  swap       d1
  add.w      d6,d1
  swap       d1                                                               ; highword d1 = reduced bob height
  neg.w      d6
  add.w      d6,d6
  lea.l      ig_om_bob_blt_height(a4),a3
  swap       d0
  sub.w      (a3,d6.w),d0
  swap       d0                                                               ; highword d0 = reduced bob height for blit (lines*bitplanes)
  clr.w      d0                                                               ; d0 = adjusted min y
  add.w      d6,d6
  lea.l      bobtype_row_offsets(a2),a3
  move.l     (a3,d6.w),a5                                                     ; a5 = offset for gfx and mask

  ; bob can't intersect upper AND lower border
  bra.s      .check_left_border

  ; check bob against lower screen border
.check_lower_border:
  cmp.w      #IgScreenHeight-1,d1
  ble.s      .check_left_border
  move.w     d1,d6
  sub.w      #IgScreenHeight-1,d6
  swap       d1
  sub.w      d6,d1
  swap       d1                                                               ; highword d1 = reduced bob height
  add.w      d6,d6
  lea.l      ig_om_bob_blt_height(a4),a3
  move.w     (a3,d6.w),d6
  swap       d0
  sub.w      d6,d0
  swap       d0                                                               ; highword d0 = reduced bob height for blit (lines*bitplanes)
  move.w     #IgScreenHeight-1,d1                                             ; d1 = reduced max y

  ; check bob against left screen border
.check_left_border:
  tst.w      d2
  bge.s      .check_right_border
  move.w     d2,d5
  neg.w      d5
  move.w     d5,d6
  and.w      #$000f,d5
  beq.s      .check_left_border_exact_word

  ; left border clipping WITH shift
  lea.l      .left_border_intersection_bltafwm_tab(pc),a3
  add.w      d5,d5
  move.w     (a3,d5.w),d7                                                     ; d7 = adjusted BLTAFWM
  ; most of the adjustments are done in.draw_in_range_negative_xpos because I need the info about the unaltered xpos there
  ; do NOT clr.w d2 because the negative xpos is needed!!

  ; bob can't intersect left AND right border
  bra.s      .check_borders_end

.check_left_border_exact_word:
  lsr.w      #4,d6
  swap       d2
  sub.w      d6,d2
  swap       d2                                                               ; highword d2 = reduced blitter width in bytes
  add.w      d6,d6
  swap       d4
  add.w      d6,d4
  swap       d4                                                               ; highword d4 = adjusted add to modulo
  move.w     d6,a5                                                            ; a5 = offset for gfx and mask
  clr.w      d2                                                               ; d2 = adjusted min x

  ; bob can't intersect left AND right border
  bra.s      .check_borders_end

  ; check bob against right screen border
.check_right_border:
  cmp.w      #IgScreenWidth-1,d3
  ble.s      .check_borders_end
  move.w     d3,d6
  sub.w      #IgScreenWidth-1,d6
  move.w     d6,d5
  and.w      #$000f,d5
  beq.s      .check_right_border_exact_word

  lea.l      .right_border_intersection_bltalwm_tab(pc),a3
  add.w      d5,d5
  swap       d7
  move.w     (a3,d5.w),d7
  swap       d7                                                               ; highword d7 = adjusted BLTALWM
  move.w     d3,d5
  sub.w      #IgScreenWidth-1,d5
  lsr.w      #4,d5
  addq.w     #1,d5
  swap       d2
  sub.w      d5,d2
  swap       d2                                                               ; highword d2 = reduced blitter width in bytes
  add.w      d5,d5
  swap       d4
  add.w      d5,d4
  swap       d4                                                               ; highword d4 = adjusted add to modulo
  move.w     #IgScreenWidth-1,d3                                              ; d3 = reduced max x
  bra.s      .check_borders_end
.check_right_border_exact_word:
  lsr.w      #4,d6
  swap       d2
  sub.w      d6,d2
  swap       d4
  move.w     d2,d4
  add.w      d4,d4
  swap       d4                                                               ; highword d4 = adjusted add to modulo
  swap       d2                                                               ; highword d2 = reduced blitter width in bytes
  move.w     #IgScreenWidth-1,d3                                              ; d3 = reduced max x

.check_borders_end:

;
; check if bob intersects the ranges border and needs to be splitted
;

.check_split:
  lea.l      ig_om_background_range_1_row_start(a4),a1
  move.w     (a1)+,d4
  move.w     (a1)+,d5
  cmp.w      d4,d0
  blt.s      .check_range_2
  cmp.w      d5,d1
  bgt.s      .check_range_2
  ; completely inside range 1
  move.l     (a1),d5                                                          ; offset in framebuffer
  lea.l      bob_restore_1a(a0),a1
  clr.w      d1                                                               ; clr.w = do not touch highword
  moveq.l    #0,d3
  bsr.s      .draw_in_range
  bra.s      .end_draw_bob
.check_range_2:
  addq.l     #4,a1
  move.w     (a1)+,d4
  move.w     (a1)+,d5
  cmp.w      d4,d0
  blt.s      .split_necessary
  cmp.w      d5,d1
  bgt.s      .split_necessary
  ; completely inside range 2
  move.l     (a1),d5                                                          ; offset in framebuffer
  lea.l      bob_restore_1a(a0),a1
  clr.w      d1                                                               ; clr.w = do not touch highword
  moveq.l    #0,d3
  bsr.s      .draw_in_range
  bra.s      .end_draw_bob
.split_necessary:
  move.w     d4,d6
  sub.w      d0,d6                                                            ; d6 = lines to cut from top of bob in range 2
  ; first draw part in range 2
  move.l     (a1),d5                                                          ; offset in framebuffer
  lea.l      bob_restore_1a(a0),a1
  move.w     d6,d1
  add.w      d1,d1
  lea.l      ig_om_bob_blt_height(a4),a3
  move.w     (a3,d1.w),d1
  move.w     d6,d3
  add.w      d3,d3
  add.w      d3,d3
  lea.l      bobtype_row_offsets(a2),a3
  move.l     (a3,d3.w),d3
  movem.l    d0-d2/d4/d6,-(sp)
  move.w     d4,d0
  bsr.s      .draw_in_range
  movem.l    (sp)+,d0-d2/d4/d6
  ; then draw part in range 1
  lea.l      bob_restore_1b(a0),a1
  swap       d1
  sub.w      d6,d1
  add.w      d1,d1
  lea.l      ig_om_bob_blt_height(a4),a3
  move.w     (a3,d1.w),d1
  moveq.l    #0,d3
  move.w     ig_om_background_range_1_row_start(a4),d4
  move.l     ig_om_background_range_1_row_offset(a4),d5
  bsr.s      .draw_in_range

.end_draw_bob:
  move.w     (sp)+,d7
  rts

; in:
;   a0   - pointer to bob-struct
;   a1   - pointer to bob_restore-struct
;   a2   - pointer to bobtype-struct
;   a5.l - offset for gfx and mask (because of screen border clipping)
;   d0.w - ypos / highword d0 = bob height for blit (lines*bitplanes)
;   d1.w - reduce blitter height by this value / highword d1 = bob height
;   d2.w - xpos / highword d2 = blitter width in words
;   d3.l - add this value to source offset
;   d4.w - first row of range / highword d4 = add to modulo
;   d5.l - offset of first row of range in framebuffer
;   d7.w - BLTAFWM / highword d7 = BLTALWM
.draw_in_range:
  move.w     d0,d6
  sub.w      d4,d6
  lsl.w      #2,d6
  lea.l      ig_om_enemies_framebuffer_offsets(a4),a3
  add.l      (a3,d6.w),d5                                                     ; offset in framebuffer of first row of bob
  moveq.l    #0,d6
  move.w     d2,d6
  swap       d0                                                               ; bob height for blit (lines*bitplanes)
  sub.w      d1,d0
  move.w     d2,d4
  swap       d2
  move.w     d2,d1
  move.l     bob_anim_offset(a0),d2
  add.l      d3,d2
  add.l      a5,d2                                                            ; source offset (gfx and mask)
  tst.w      d6
  blt.s      .draw_in_range_negative_xpos
  lsr.w      #4,d6
  lsl.w      #1,d6
  add.l      d6,d5                                                            ; offset in framebuffer to bob position
  and.w      #$000f,d4                                                        ; 0 = no shift, >0 = shift by pixels
  beq.s      .draw_in_range_no_shift
  addq.w     #1,d1
.draw_in_range_no_shift:
  bra.s      .do_blit

.draw_in_range_negative_xpos:
  ; only executed if clipping with left screen border occurs
  subq.l     #2,d5                                                            ; target offset
  moveq.l    #0,d3
  move.w     d6,d3
  neg.w      d3
  move.w     d3,d6
  and.w      #$000f,d3
  neg.w      d3
  add.w      #16,d3
  move.w     d3,d4                                                            ; shift by pixels
  lsr.w      #4,d6
  beq.s      .neg_xpos_under_16
  lsl.w      #1,d6
  add.l      d6,d2                                                            ; source offset
  swap       d4
  add.w      d6,d4                                                            ; modulo
  swap       d4
  bra.s      .do_blit
.neg_xpos_under_16:
  addq.w     #1,d1                                                            ; blitter width in words
  ; intended fall-through

; in:
;   a0   - pointer to enemy-struct
;   a1   - pointer to enemy_restore-struct
;   a2   - pointer to bobtype-struct
;   d0.w - blitter height (lines*bitplanes)
;   d1.w - blitter width in words
;   d2.l - anim offset plus additional offset for gfx and mask pointer (multiplies of lines*bitplanes to skip upper lines of bob)
;   d4.w - 0 = no shift, >0 = shift by pixels / highword d4 = add to modulo
;   d5.l - offset in framebuffer
;   d7.w - BLTAFWM / highword d7 = BLTALWM
.do_blit:
  move.l     d5,bob_restore_offset(a1)

  WAITBLT

  tst.b      d4
  bne.s      .do_blit_with_shift

  ; a-channel masks and blitter controls
  move.w     d7,BLTAFWM(a6)
  swap       d7
  move.w     d7,BLTALWM(a6)
  swap       d7
  move.w     #%0000111111001010,BLTCON0(a6)
  clr.w      BLTCON1(a6)
  ; modulos
  move.w     bobtype_src_mod_no_shift(a2),d6
  swap       d4
  add.w      d4,d6
  move.w     d6,BLTAMOD(a6)
  move.w     d6,BLTBMOD(a6)
  move.w     bobtype_trg_mod_no_shift(a2),d6
  add.w      d4,d6
  move.w     d6,BLTCMOD(a6)
  move.w     d6,BLTDMOD(a6)
  move.w     d6,bob_restore_modulo(a1)
  ; pointers
  move.l     bobtype_data_pointer(a2),d6
  add.l      d2,d6
  move.l     d6,BLTBPT(a6)
  move.l     bobtype_mask_pointer(a2),d6
  add.l      d2,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_bob_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  lsl.w      #6,d0
  add.w      d1,d0
  move.w     d0,BLTSIZE(a6)
  move.w     d0,bob_restore_bltsize(a1)
  ; end
  rts

.do_blit_with_shift:
  ; pixel shift - full masked copy
  move.w     d7,BLTAFWM(a6)
  swap       d7
  move.w     d7,BLTALWM(a6)
  swap       d7
  ror.w      #4,d4
  move.w     d4,BLTCON1(a6)
  or.w       #%0000111111001010,d4
  move.w     d4,BLTCON0(a6)
  ; modulos
  move.w     bobtype_src_mod_shift(a2),d6
  swap       d4
  add        d4,d6
  move.w     d6,BLTAMOD(a6)
  move.w     d6,BLTBMOD(a6)
  move.w     bobtype_trg_mod_shift(a2),d6
  add        d4,d6
  move.w     d6,BLTCMOD(a6)
  move.w     d6,BLTDMOD(a6)
  move.w     d6,bob_restore_modulo(a1)
  ; pointers
  move.l     bobtype_data_pointer(a2),d6
  add.l      d2,d6
  move.l     d6,BLTBPT(a6)
  move.l     bobtype_mask_pointer(a2),d6
  add.l      d2,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_bob_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  lsl.w      #6,d0
  add.w      d1,d0
  move.w     d0,BLTSIZE(a6)
  move.w     d0,bob_restore_bltsize(a1)
  ; end
  rts

.right_border_intersection_bltalwm_tab:
  dc.w       %1111111111111111
  dc.w       %1111111111111110
  dc.w       %1111111111111100
  dc.w       %1111111111111000
  dc.w       %1111111111110000
  dc.w       %1111111111100000
  dc.w       %1111111111000000
  dc.w       %1111111110000000
  dc.w       %1111111100000000
  dc.w       %1111111000000000
  dc.w       %1111110000000000
  dc.w       %1111100000000000
  dc.w       %1111000000000000
  dc.w       %1110000000000000
  dc.w       %1100000000000000
  dc.w       %1000000000000000

.left_border_intersection_bltafwm_tab:
  dc.w       %1111111111111111
  dc.w       %0111111111111111
  dc.w       %0011111111111111
  dc.w       %0001111111111111
  dc.w       %0000111111111111
  dc.w       %0000011111111111
  dc.w       %0000001111111111
  dc.w       %0000000111111111
  dc.w       %0000000011111111
  dc.w       %0000000001111111
  dc.w       %0000000000111111
  dc.w       %0000000000011111
  dc.w       %0000000000001111
  dc.w       %0000000000000111
  dc.w       %0000000000000011
  dc.w       %0000000000000001

  endif                                                                       ; ifnd INGAME_BOB_ASM
