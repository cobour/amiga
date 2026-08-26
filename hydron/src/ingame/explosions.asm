  ifnd       INGAME_EXPLOSIONS_ASM
INGAME_EXPLOSIONS_ASM equ 1

  include    "src/ingame.i"

explosions_init:

  ; init large explosion sfx
  move.l     #"SLEX",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  move.l     a0,ig_om_explosions_sfx_large(a4)

  ; init large explosion bobtype
  move.l     #"BLEX",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a3                                              ; pointer to bobtype-struct
  move.l     a3,ig_om_explosions_bobtype_large(a4)
  move.l     bobtype_gfx_id(a3),d0
  bsr        datafiles_get_pointer                                                  ; pointer to gfx-struct
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,bobtype_data_pointer(a3)
  lea.l      df_idx_metadata(a0),a0
  add.l      df_iff_rawsize(a0),d0
  move.l     d0,bobtype_mask_pointer(a3)

  ; init anim structs
  moveq.l    #ExplosionsCount-1,d7
  lea.l      ig_om_explosions_anims(a4),a0
.init_anim_loop:
  bsr        bob_clear
  lea.l      explosion_sizeof(a0),a0
  dbf        d7,.init_anim_loop

  rts

explosions_update:

  moveq.l    #ExplosionsCount-1,d7
  lea.l      ig_om_explosions_anims(a4),a0
.loop:

  ; active anim?
  cmp.w      #BobStatusInactive,bob_status(a0)
  beq.s      .loop_next

  ; restore only?
  cmp.w      #BobStatusRestoreOnly,bob_status(a0)
  bne.s      .draw_anim
  sub.b      #1,explosion_current_frame_delay_counter(a0)
  tst.b      explosion_current_frame_delay_counter(a0)
  bgt.s      .loop_next
  move.w     #BobStatusInactive,bob_status(a0)
  bra.s      .loop_next

.draw_anim:
  ; switch to next anim frame?
  sub.b      #1,explosion_current_frame_delay_counter(a0)
  tst.b      explosion_current_frame_delay_counter(a0)
  bne.s      .anim_frame_still_valid
  move.b     explosion_frame_delay(a0),explosion_current_frame_delay_counter(a0)
  move.w     explosion_anim_step_add(a0),d0
  add.w      d0,bob_anim_offset+2(a0)
.anim_frame_still_valid:

  ; last anim frame reached?
  move.w     explosion_max_anim_step_offset(a0),d0
  move.w     bob_anim_offset+2(a0),d1
  cmp.w      d0,d1
  ble.s      .anim_end_not_reached
  move.w     #BobStatusRestoreOnly,bob_status(a0)
  move.b     #2,explosion_current_frame_delay_counter(a0)
.anim_end_not_reached:

.loop_next:
  lea.l      explosion_sizeof(a0),a0
  dbf        d7,.loop

  rts

explosions_restore:
  move.l     ig_om_bob_targetbuffer(a4),a1                                          ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                                              ; base pointer of source buffer

  lea.l      ig_om_explosions_anims(a4),a0
  moveq.l    #ExplosionsCount-1,d7
.restore_loop:
  tst.w      bob_status(a0)
  blt.s      .do_not_restore
  bsr        bob_restore
.do_not_restore:
  lea.l      explosion_sizeof(a0),a0
  dbf        d7,.restore_loop
  rts

explosions_draw:
  lea.l      ig_om_explosions_anims(a4),a0
  moveq.l    #ExplosionsCount-1,d7
.draw_loop:
  tst.w      bob_status(a0)
  ble.s      .do_not_draw
  bsr        bob_draw
.do_not_draw:
  lea.l      explosion_sizeof(a0),a0
  dbf        d7,.draw_loop

  move.l     chip_mem_ptr(pc),a5
  rts

; in:
;   d0.w - xpos
;   d1.w - ypos
explosions_new_large:

  ; play sfx
  movem.w    d0-d1,-(sp)
  move.l     ig_om_explosions_sfx_large(a4),a0
  bsr        _mt_playfx
  movem.w    (sp)+,d0-d1

  ; find anim slot
  bsr.s      explosions_new
  moveq.l    #0,d2
  cmp.l      d2,a0
  beq.s      .exit

  ; init vars
  move.w     #BobStatusActive,bob_status(a0)
  move.b     #2,explosion_frame_delay(a0)
  move.b     #2,explosion_current_frame_delay_counter(a0)
  move.w     #56,explosion_max_anim_step_offset(a0)
  move.w     #4,explosion_anim_step_add(a0)
  move.l     d2,bob_anim_offset(a0)                                                 ; d2 = still zero
  move.l     ig_om_explosions_bobtype_large(a4),bob_bobtype_pointer(a0)
  move.w     d0,bob_xpos(a0)                                                        ; fraction is irrelevant because explosion does not move
  move.w     d1,bob_ypos(a0)                                                        ; fraction is irrelevant because explosion does not move

.exit:
  rts

; INTERNAL USE ONLY
; out:
;  a0 - pointer to explosions-struct or zero when none is available
explosions_new:
  moveq.l    #ExplosionsCount-1,d7
  lea.l      ig_om_explosions_anims(a4),a0
.find_anim_loop:
  cmp.w      #BobStatusInactive,bob_status(a0)
  bne.s      .find_anim_loop_next
  bra        bob_clear_quick                                                        ; implicit rts
.find_anim_loop_next:
  lea.l      explosion_sizeof(a0),a0
  dbf        d7,.find_anim_loop
  sub.l      a0,a0                                                                  ; no empty slot available
  rts

  endif                                                                             ; ifnd INGAME_EXPLOSIONS_ASM
