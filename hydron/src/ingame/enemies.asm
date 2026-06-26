  ifnd       ENEMIES_ASM
ENEMIES_ASM equ 1

  include    "src/ingame.i"
  include    "../common/src/system/blitter.i"

enemies_init:
  ; init enemy-structs
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.init_structs_loop:
  move.w     #-1,enemy_status(a0)
  clr.l      enemy_xpos(a0)
  clr.l      enemy_ypos(a0)
  clr.w      enemy_width(a0)
  clr.w      enemy_height(a0)
  clr.w      enemy_width_words(a0)
  clr.w      enemy_height_blt(a0)
  clr.l      enemy_data_pointer(a0)
  clr.l      enemy_mask_pointer(a0)
  clr.l      enemy_anim_offset(a0)
  clr.w      enemy_src_mod_no_shift(a0)
  clr.w      enemy_src_mod_shift(a0)
  clr.w      enemy_trg_mod_no_shift(a0)
  clr.w      enemy_trg_mod_shift(a0)
  clr.w      enemy_restore_1a+enemy_restore_offset(a0)
  clr.w      enemy_restore_1a+enemy_restore_bltsize(a0)
  clr.w      enemy_restore_1a+enemy_restore_modulo(a0)
  clr.w      enemy_restore_2a+enemy_restore_offset(a0)
  clr.w      enemy_restore_2a+enemy_restore_bltsize(a0)
  clr.w      enemy_restore_2a+enemy_restore_modulo(a0)
  clr.w      enemy_restore_1b+enemy_restore_offset(a0)
  clr.w      enemy_restore_1b+enemy_restore_bltsize(a0)
  clr.w      enemy_restore_1b+enemy_restore_modulo(a0)
  clr.w      enemy_restore_2b+enemy_restore_offset(a0)
  clr.w      enemy_restore_2b+enemy_restore_bltsize(a0)
  clr.w      enemy_restore_2b+enemy_restore_modulo(a0)
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.init_structs_loop

  ; init ig_om_enemies_framebuffer_offsets
  lea.l      ig_om_enemies_framebuffer_offsets(a4),a0
  move.w     #IgScreenHeight-1,d7
  move.l     #IgScreenWidthBytes*IgScreenBitPlanes,d1
  moveq.l    #0,d0
.init_offsets_table_loop:
  move.l     d0,(a0)+
  add.l      d1,d0
  dbf        d7,.init_offsets_table_loop

  ; init TEST bob
  lea.l      ig_om_enemies(a4),a1
  move.w     #1,enemy_status(a1)
  move.l     #"TEST",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,enemy_data_pointer(a1)
  lea.l      df_idx_metadata(a0),a0
  add.l      df_iff_rawsize(a0),d0
  move.l     d0,enemy_mask_pointer(a1)
  move.w     df_iff_width(a0),enemy_width(a1)
  move.w     df_iff_height(a0),enemy_height(a1)
  move.w     #2,enemy_width_words(a1)
  move.w     #32*6,enemy_height_blt(a1)
  move.l     #$00700000,enemy_xpos(a1)
  move.l     #$00700000,enemy_ypos(a1)
  move.w     #$0000,enemy_src_mod_no_shift(a1)
  move.w     #-2,enemy_src_mod_shift(a1)
  move.w     #28,enemy_trg_mod_no_shift(a1)
  move.w     #26,enemy_trg_mod_shift(a1)

  rts

enemies_update:
  ; do not move right now
  rts

enemies_restore:
  ; set pointer to framebuffer of backbuffer for restore enemies_restore and enemies_draw
  move.l     ig_om_buffers_backbuffer(a4),a0
  move.l     ig_buffers_framebuffer_pointer(a0),a1         ; base pointer of target buffer
  move.l     a1,ig_om_enemies_targetbuffer(a4)
  move.l     ig_om_buffer_three(a4),a2                     ; base pointer of source buffer

  ; restore
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
  moveq.l    #0,d4
.restore_loop:
  tst.w      enemy_status(a0)
  blt.s      .do_not_restore
  ; TODO enemy_restore_2b
  lea.l      enemy_restore_2a(a0),a3
  move.w     enemy_restore_bltsize(a3),d3
  beq.s      .restore_done
  ; restore
  move.w     enemy_restore_offset(a3),d4
  move.l     a2,d0
  add.l      d4,d0                                         ; source pointer
  move.l     a1,d1
  add.l      d4,d1                                         ; target pointer
  move.w     enemy_restore_modulo(a3),d2
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
  lea.l      enemy_restore_1a(a0),a1
  lea.l      enemy_restore_2a(a0),a2
  move.l     (a1)+,(a2)+
  move.l     (a1)+,(a2)+
  move.l     (a1),(a2)
.do_not_restore:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.restore_loop
  rts

enemies_draw:
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.draw_loop:
  tst.w      enemy_status(a0)
  ble.s      .do_not_draw
  bsr.s      .draw_bob
.do_not_draw:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.draw_loop
  rts

; in:
;   a0 - pointer to enemy-struct
.draw_bob:
  move.w     d7,-(sp)
  ; get enemy dimensions
  move.w     enemy_ypos(a0),d0                             ; min y
  move.w     d0,d1
  add.w      enemy_height(a0),d1                           ; max y
  move.w     enemy_xpos(a0),d2                             ; min x
  move.w     d2,d3
  add.w      enemy_width(a0),d3                            ; max x
.check_split:
  lea.l      ig_om_background_range_1_row_start(a4),a1
  move.w     (a1)+,d4
  move.w     (a1)+,d5
  cmp.w      d4,d0
  blt.s      .check_range_2
  cmp.w      d5,d1
  bgt.s      .check_range_2
  ; completely inside range 1
  move.l     (a1),d5                                       ; offset in framebuffer
  lea.l      enemy_restore_1a(a0),a1
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
  move.l     (a1),d5                                       ; offset in framebuffer
  lea.l      enemy_restore_1a(a0),a1
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
  add.l      (a2,d6.w),d5                                  ; offset in framebuffer of first row of bob
  moveq.l    #0,d6
  move.w     d2,d6
  lsr.w      #4,d6
  lsl.w      #1,d6
  add.l      d6,d5                                         ; offset in framebuffer to bob position
  move.w     d2,d4
  and.w      #$000f,d4                                     ; 0 = no shift, >0 = shift by pixels
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
  move.w     d5,enemy_restore_offset(a1)

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
  move.w     enemy_src_mod_no_shift(a0),d7
  move.w     d7,BLTAMOD(a6)
  move.w     d7,BLTBMOD(a6)
  move.w     enemy_trg_mod_no_shift(a0),d7
  move.w     d7,BLTCMOD(a6)
  move.w     d7,BLTDMOD(a6)
  move.w     d7,enemy_restore_modulo(a1)
  ; pointers
  move.l     enemy_anim_offset(a0),d7
  move.l     enemy_data_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTBPT(a6)
  move.l     enemy_mask_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_enemies_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  move.w     enemy_height_blt(a0),d7
  lsl.w      #6,d7
  add.w      enemy_width_words(a0),d7
  move.w     d7,BLTSIZE(a6)
  move.w     d7,enemy_restore_bltsize(a1)
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
  move.w     enemy_src_mod_shift(a0),d7
  move.w     d7,BLTAMOD(a6)
  move.w     d7,BLTBMOD(a6)
  move.w     enemy_trg_mod_shift(a0),d7
  move.w     d7,BLTCMOD(a6)
  move.w     d7,BLTDMOD(a6)
  move.w     d7,enemy_restore_modulo(a1)
  ; pointers
  move.l     enemy_anim_offset(a0),d7
  move.l     enemy_data_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTBPT(a6)
  move.l     enemy_mask_pointer(a0),d6
  add.l      d7,d6
  move.l     d6,BLTAPT(a6)
  add.l      ig_om_enemies_targetbuffer(a4),d5
  move.l     d5,BLTCPT(a6)
  move.l     d5,BLTDPT(a6)
  ; bltsize
  move.w     enemy_height_blt(a0),d7
  lsl.w      #6,d7
  add.w      enemy_width_words(a0),d7
  addq.w     #1,d7
  move.w     d7,BLTSIZE(a6)
  move.w     d7,enemy_restore_bltsize(a1)
  ; end
  bra        .end_draw_bob

  endif                                                    ; ifnd ENEMIES_ASM
