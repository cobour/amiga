  ifnd       INGAME_BOB_ASM
INGAME_BBOB_ASM equ 1

  include    "src/ingame.i"
  include    "../common/src/system/blitter.i"

; in:
;   a0 - pointer to bob-struct
bob_clear:
  move.w     #-1,bob_status(a0)
  clr.l      bob_xpos(a0)
  clr.l      bob_ypos(a0)
  clr.w      bob_width(a0)
  clr.w      bob_height(a0)
  clr.w      bob_width_words(a0)
  clr.w      bob_height_blt(a0)
  clr.l      bob_data_pointer(a0)
  clr.l      bob_mask_pointer(a0)
  clr.l      bob_anim_offset(a0)
  clr.w      bob_src_mod_no_shift(a0)
  clr.w      bob_src_mod_shift(a0)
  clr.w      bob_trg_mod_no_shift(a0)
  clr.w      bob_trg_mod_shift(a0)
  clr.w      bob_restore_1a+bob_restore_offset(a0)
  clr.w      bob_restore_1a+bob_restore_bltsize(a0)
  clr.w      bob_restore_1a+bob_restore_modulo(a0)
  clr.w      bob_restore_2a+bob_restore_offset(a0)
  clr.w      bob_restore_2a+bob_restore_bltsize(a0)
  clr.w      bob_restore_2a+bob_restore_modulo(a0)
  clr.w      bob_restore_1b+bob_restore_offset(a0)
  clr.w      bob_restore_1b+bob_restore_bltsize(a0)
  clr.w      bob_restore_1b+bob_restore_modulo(a0)
  clr.w      bob_restore_2b+bob_restore_offset(a0)
  clr.w      bob_restore_2b+bob_restore_bltsize(a0)
  clr.w      bob_restore_2b+bob_restore_modulo(a0)
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
  tst.w      bob_status(a0)
  blt.s      .do_not_restore
  ; TODO bob_restore_2b
  lea.l      bob_restore_2a(a0),a3
  move.w     bob_restore_bltsize(a3),d3
  beq.s      .restore_done
  ; restore
  move.w     bob_restore_offset(a3),d4
  move.l     a2,d0
  add.l      d4,d0                                                            ; source pointer
  move.l     a1,d1
  add.l      d4,d1                                                            ; target pointer
  move.w     bob_restore_modulo(a3),d2
  WAITBLT
  move.w     #$ffff,d6
  move.w     d6,BLTAFWM(a6)
  move.w     d6,BLTALWM(a6)
  move.w     #%0000100111110000,BLTCON0(a6)
  clr.w      BLTCON1(a6)
  move.w     d2,BLTAMOD(a6)
  move.w     d2,BLTDMOD(a6)
  move.l     d0,BLTAPT(a6)
  move.l     d1,BLTDPT(a6)
  move.w     d3,BLTSIZE(a6)
.restore_done:
  ; copy restore 1 to restore 2
  lea.l      bob_restore_1a(a0),a1
  lea.l      bob_restore_2a(a0),a2
  move.l     (a1)+,(a2)+
  move.l     (a1)+,(a2)+
  move.l     (a1),(a2)
.do_not_restore:
  rts

; in:
;   a0 - pointer to bob-struct
bob_draw:
  move.w     d7,-(sp)
  ; get enemy dimensions
  move.w     bob_ypos(a0),d0                                                  ; min y
  move.w     d0,d1
  add.w      bob_height(a0),d1                                                ; max y
  move.w     bob_xpos(a0),d2                                                  ; min x
  move.w     d2,d3
  add.w      bob_width(a0),d3                                                 ; max x
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
  bra.s      .draw_unsplitted
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
  bra.s      .draw_unsplitted
.split_necessary:
  ; TODO
  nop

.end_draw_bob:
  move.w     (sp)+,d7
  rts

; in:
;   a0   - pointer to enemy-struct
;   a1   - pointer to enemy_restore-struct
;   d0.w - ypos          (min y)
;   d1.w - ypos+height   (max y)
;   d2.w - xpos          (min x)
;   d3.w - xpos+width    (max x)
;   d4.w - first row of range
;   d5.l - offset of first row of range in framebuffer
.draw_unsplitted:
  move.w     d0,d6
  sub.w      d4,d6
  lsl.w      #2,d6
  lea.l      ig_om_enemies_framebuffer_offsets(a4),a2
  add.l      (a2,d6.w),d5                                                     ; offset in framebuffer of first row of bob
  moveq.l    #0,d6
  move.w     d2,d6
  lsr.w      #4,d6
  lsl.w      #1,d6
  add.l      d6,d5                                                            ; offset in framebuffer to bob position
  move.w     d2,d4
  and.w      #$000f,d4                                                        ; 0 = no shift, >0 = shift by pixels
  ; intended fall-through

; in:
;   a0   - pointer to enemy-struct
;   a1   - pointer to enemy_restore-struct
;   d0.w - ypos          (min y)
;   d1.w - ypos+height   (max y)
;   d2.w - xpos          (min x)
;   d3.w - xpos+width    (max x)
;   d4.w - 0 = no shift, >0 = shift by pixels
;   d5.l - offset in framebuffer
.do_blit:
  move.w     d5,bob_restore_offset(a1)

  WAITBLT

  tst.b      d4
  bne.s      .do_blit_with_shift

  ; no pixel shift - full masked copy
  move.w     #$ffff,d6
  move.w     d6,BLTAFWM(a6)
  move.w     d6,BLTALWM(a6)
  move.w     #%0000111111001010,BLTCON0(a6)
  clr.w      BLTCON1(a6)
  ; modulos
  move.w     bob_src_mod_no_shift(a0),d7
  move.w     d7,BLTAMOD(a6)
  move.w     d7,BLTBMOD(a6)
  move.w     bob_trg_mod_no_shift(a0),d7
  move.w     d7,BLTCMOD(a6)
  move.w     d7,BLTDMOD(a6)
  move.w     d7,bob_restore_modulo(a1)
  ; pointers
  move.l     bob_anim_offset(a0),d7
  move.l     bob_data_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTBPT(a6)
  move.l     bob_mask_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_bob_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  move.w     bob_height_blt(a0),d7
  lsl.w      #6,d7
  add.w      bob_width_words(a0),d7
  move.w     d7,BLTSIZE(a6)
  move.w     d7,bob_restore_bltsize(a1)
  ; end
  bra        .end_draw_bob

.do_blit_with_shift:
  ; pixel shift - full masked copy
  move.w     #$ffff,BLTAFWM(a6)
  clr.w      BLTALWM(a6)
  ror.w      #4,d4
  move.w     d4,BLTCON1(a6)
  or.w       #%0000111111001010,d4
  move.w     d4,BLTCON0(a6)
  ; modulos
  move.w     bob_src_mod_shift(a0),d7
  move.w     d7,BLTAMOD(a6)
  move.w     d7,BLTBMOD(a6)
  move.w     bob_trg_mod_shift(a0),d7
  move.w     d7,BLTCMOD(a6)
  move.w     d7,BLTDMOD(a6)
  move.w     d7,bob_restore_modulo(a1)
  ; pointers
  move.l     bob_anim_offset(a0),d7
  move.l     bob_data_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTBPT(a6)
  move.l     bob_mask_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_bob_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  move.w     bob_height_blt(a0),d7
  lsl.w      #6,d7
  add.w      bob_width_words(a0),d7
  addq.w     #1,d7
  move.w     d7,BLTSIZE(a6)
  move.w     d7,bob_restore_bltsize(a1)
  ; end
  bra        .end_draw_bob

  endif                                                                       ; ifnd INGAME_BOB_ASM
