  ifnd       INGAME_PLAYER_ASM
INGAME_PLAYER_ASM equ 1

  include    "src/ingame.i"
  include    "src/ingame/player.i"
  include    "../common/src/system/joystick.i"

player_init:

  ; init player ship gfx and metadata
  move.l     #"PLYR",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_player_gfx_ptr(a4)
  clr.l      ig_om_player_anim_offset(a4)                                         ; clear once, after this move.b is sufficient
  move.b     #PlayerShipAnimCentered,ig_om_player_anim_offset+3(a4)
  lea.l      df_idx_metadata(a0),a0
  move.w     df_iff_width(a0),d0
  lsr.w      #3,d0
  move.w     d0,ig_om_player_gfx_width_bytes(a4)
  move.l     #$00010000,ig_om_player_speed(a4)                                    ; alternatively move 1 and a half pixel per frame with #$00018000
  move.l     #$00700000,ig_om_player_xpos(a4)
  move.l     #$00700000,ig_om_player_ypos(a4)
  clr.l      ig_om_player_min_xpos(a4)
  clr.l      ig_om_player_min_ypos(a4)
  move.l     #$00e00000,ig_om_player_max_xpos(a4)
  move.l     #$00e00000,ig_om_player_max_ypos(a4)
  clr.w      ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_right_for_frames(a4)
  clr.w      ig_om_player_centered_for_frames(a4)
  clr.l      ig_cm_player_sprite0(a5)
  clr.l      ig_cm_player_sprite1(a5)
  clr.l      ig_cm_player_sprite2(a5)
  clr.l      ig_cm_player_sprite3(a5)

  ; set sprite pointers in copperlist
  move.l     ig_om_copperlist_front(a4),a0

  ; external guns / satellites (playershots first when visible)
  ; reuse sprites 0-1
  lea.l      ig_cm_cl_reuse_sprites(a0),a1
  move.l     a5,d0
  add.l      #ig_cm_player_sprite0,d0
  move.w     d0,6(a1)                                                             ; SPR0PTL
  swap       d0
  move.w     d0,2(a1)                                                             ; SPR0PTH
  move.l     a5,d0
  add.l      #ig_cm_player_sprite1,d0
  move.w     d0,22(a1)                                                            ; SPR1PTL
  swap       d0
  move.w     d0,18(a1)                                                            ; SPR1PTH
  moveq.l    #0,d0
  move.w     d0,10(a1)                                                            ; SPR0POS
  move.w     d0,14(a1)                                                            ; SPR0CTL
  move.w     d0,26(a1)                                                            ; SPR1POS
  move.w     d0,30(a1)                                                            ; SPR1CTL
  ; sprites 2-3
  lea.l      ig_cm_cl_sprites(a0),a1
  move.l     a5,d0
  add.l      #ig_cm_player_sprite2,d0
  move.w     d0,22(a1)
  swap       d0
  move.w     d0,18(a1)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite3,d0
  move.w     d0,30(a1)
  swap       d0
  move.w     d0,26(a1)

  ; player ship (playershots first when visible)
  ; sprites 4-7
  lea.l      ig_cm_cl_sprites(a0),a0
  move.l     a5,d0
  add.l      #ig_cm_player_sprite4,d0
  move.w     d0,38(a0)
  swap       d0
  move.w     d0,34(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite5,d0
  move.w     d0,46(a0)
  swap       d0
  move.w     d0,42(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite6,d0
  move.w     d0,54(a0)
  swap       d0
  move.w     d0,50(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite7,d0
  move.w     d0,62(a0)
  swap       d0
  move.w     d0,58(a0)

  rts

player_update:

  move.l     ig_om_player_xpos(a4),d4
  move.l     ig_om_player_ypos(a4),d5

  ; read joystick, update player position and check against boundaries
  bsr        joystick_read
  btst       #JsDown,d0
  beq.s      .test_up
  add.l      ig_om_player_speed(a4),d5
  cmp.l      ig_om_player_max_ypos(a4),d5
  ble.s      .test_up
  move.l     ig_om_player_max_ypos(a4),d5
.test_up:
  btst       #JsUp,d0
  beq.s      .test_left
  sub.l      ig_om_player_speed(a4),d5
  cmp.l      ig_om_player_min_ypos(a4),d5
  bge.s      .test_left
  move.l     ig_om_player_min_ypos(a4),d5
.test_left:
  btst       #JsLeft,d0
  beq.s      .test_right
  sub.l      ig_om_player_speed(a4),d4
  add.w      #1,ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_right_for_frames(a4)
  clr.w      ig_om_player_centered_for_frames(a4)
  cmp.l      ig_om_player_min_xpos(a4),d4
  bge.s      .test_right
  move.l     ig_om_player_min_xpos(a4),d4
.test_right:
  btst       #JsRight,d0
  beq.s      .test_end
  add.l      ig_om_player_speed(a4),d4
  add.w      #1,ig_om_player_right_for_frames(a4)
  clr.w      ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_centered_for_frames(a4)
  cmp.l      ig_om_player_max_xpos(a4),d4
  ble.s      .test_end
  move.l     ig_om_player_max_xpos(a4),d4
.test_end:
  move.l     d4,ig_om_player_xpos(a4)
  move.l     d5,ig_om_player_ypos(a4)
  and.b      #1<<JsLeft|1<<JsRight,d0
  tst.b      d0
  bne.s      .not_centered

  ; choose anim step for player ship when joystick is centered
  ; move back softly (when it was hard right or hard left, then switch to right or left first)
  clr.w      ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_right_for_frames(a4)
  add.w      #1,ig_om_player_centered_for_frames(a4)
  cmp.w      #PlayerShipAnimSwitchDelay/2,ig_om_player_centered_for_frames(a4)
  ble.s      .centered_soft_back
  move.b     #PlayerShipAnimCentered,ig_om_player_anim_offset+3(a4)               ; default
  bra.s      .anim_chosen
.centered_soft_back:
  cmp.b      #PlayerShipAnimHardLeft,ig_om_player_anim_offset+3(a4)
  bne.s      .centered_check_hard_right
  move.b     #PlayerShipAnimLeft,ig_om_player_anim_offset+3(a4)
  bra.s      .anim_chosen
.centered_check_hard_right:
  cmp.b      #PlayerShipAnimHardRight,ig_om_player_anim_offset+3(a4)
  bne.s      .not_centered
  move.b     #PlayerShipAnimRight,ig_om_player_anim_offset+3(a4)
  bra.s      .anim_chosen
.not_centered:

  ; choose anim step for player ship when joystick is left or right
  move.w     ig_om_player_left_for_frames(a4),d0
  tst.w      d0
  beq.s      .not_left
  cmp.w      #PlayerShipAnimSwitchDelay,d0
  blt.s      .not_hard_left
  move.b     #PlayerShipAnimHardLeft,ig_om_player_anim_offset+3(a4)
  bra.s      .anim_chosen
.not_hard_left:
  moveq.l    #PlayerShipAnimLeft,d1
  move.b     #PlayerShipAnimLeft,ig_om_player_anim_offset+3(a4)
  bra.s      .anim_chosen
.not_left:
  move.w     ig_om_player_right_for_frames(a4),d0
  tst.w      d0
  beq.s      .not_right
  cmp.w      #PlayerShipAnimSwitchDelay,d0
  blt.s      .not_hard_right
  move.b     #PlayerShipAnimHardRight,ig_om_player_anim_offset+3(a4)
  bra.s      .anim_chosen
.not_hard_right:
  move.b     #PlayerShipAnimRight,ig_om_player_anim_offset+3(a4)
.not_right:
.anim_chosen:


  ; player ship

  swap       d4                                                                   ; no fraction needed anymore
  swap       d5                                                                   ; no fraction needed anymore
  add.w      #IgScreenStartX,d4                                                   ; add beam start pos
  add.w      #IgScreenStartY,d5                                                   ; add beam start pos

  bsr        .calc_pos_ctl
  move.l     ig_om_player_anim_offset(a4),d3
  lea.l      ig_cm_player_sprite4(a5),a2                                          ; target pointer SPR4
  lea.l      ig_cm_player_sprite5(a5),a3                                          ; target pointer SPR5
  bsr.s      .pu_sub

  addq.w     #8,d1                                                                ; 6+7 are placed exactly to the right of 4+5
  moveq.l    #2,d3                                                                ; 6+7 are placed exactly to the right of 4+5
  add.l      ig_om_player_anim_offset(a4),d3
  lea.l      ig_cm_player_sprite6(a5),a2                                          ; target pointer SPR6
  lea.l      ig_cm_player_sprite7(a5),a3                                          ; target pointer SPR7
  ; fall-through intended

.pu_sub:
  ; control words
  move.w     d1,(a2)+
  move.w     d2,(a2)+
  bset       #7,d2                                                                ; set attach bit
  move.w     d1,(a3)+
  move.w     d2,(a3)+
  bclr       #7,d2                                                                ; clear attach bit

  ; bitmap data
  moveq.l    #0,d0
  move.w     ig_om_player_gfx_width_bytes(a4),d0
  move.l     ig_om_player_gfx_ptr(a4),a1
  lea.l      (a1,d3.w),a1
  moveq.l    #32-1,d7
.copy_loop:
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  dbf        d7,.copy_loop

  ; end of sprite data
  clr.l      (a2)+
  clr.l      (a3)+

  rts

; in:
;   d4.w - xpos
;   d5.w - ypos
; out:
;   d1.w - SPRxPOS
;   d2.w - SPRxCTL
.calc_pos_ctl:
  move.w     d5,d1
  lsl.w      #8,d1
  move.w     d4,d0
  lsr.w      #1,d0
  add.w      d0,d1                                                                ; SPRxPOS
  move.w     d5,d0
  add.w      #32,d0                                                               ; vstop
  move.w     d0,d2
  and.w      #$00ff,d2
  lsl.w      #8,d2                                                                ; SPRxCTL

  cmp.w      #$0100,d5
  blt.s      .no_v8_v_start
  bset       #2,d2                                                                ; SPRxCTL
.no_v8_v_start: 
  cmp.w      #$0100,d0
  blt.s      .no_v8_v_stop
  bset       #1,d2                                                                ; SPRxCTL
.no_v8_v_stop:
  btst       #0,d4
  beq.s      .no_h0_h_start
  bset       #0,d2                                                                ; SPRxCTL
.no_h0_h_start:

  rts

  endif                                                                           ; ifnd INGAME_PLAYER_ASM
