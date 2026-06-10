  ifnd       INGAME_PLAYER_ASM
INGAME_PLAYER_ASM equ 1

  include    "src/ingame.i"
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
  move.l     #$00100000,ig_om_player_min_ypos(a4)
  move.l     #$00e00000,ig_om_player_max_xpos(a4)
  move.l     #$00ea0000,ig_om_player_max_ypos(a4)
  clr.w      ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_right_for_frames(a4)
  clr.w      ig_om_player_centered_for_frames(a4)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite0(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite1(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite2(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite3(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite4(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite5(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite6(a5)
  clr.l      ig_cm_player_sprites_buffer_0+ig_player_sprite7(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite0(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite1(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite2(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite3(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite4(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite5(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite6(a5)
  clr.l      ig_cm_player_sprites_buffer_1+ig_player_sprite7(a5)

  ; init player fire sfx
  move.l     #"SBU0",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  move.l     a0,ig_om_player_fire_sfx(a4)

  ; init player bullet gfx
  move.l     #"PBU0",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),d0
  lea.l      df_idx_metadata(a0),a1
  moveq.l    #0,d1
  move.w     df_iff_width(a1),d1
  lsr.w      #3,d1
  lea.l      player_bullettype_simple_for_stack_0(pc),a0
  move.l     d0,ig_player_bullettype_gfx_pointer(a0)
  move.l     d1,ig_player_bullettype_gfx_width_bytes(a0)
  lea.l      player_bullettype_simple_for_stack_1(pc),a0
  move.l     d0,ig_player_bullettype_gfx_pointer(a0)
  move.l     d1,ig_player_bullettype_gfx_width_bytes(a0)
  lea.l      player_bullettype_simple_for_stack_2(pc),a0
  move.l     d0,ig_player_bullettype_gfx_pointer(a0)
  move.l     d1,ig_player_bullettype_gfx_width_bytes(a0)

  ; init bullet structs and lists
  lea.l      ig_om_player_bullets_stack_0(a4),a0
  lea.l      ig_om_player_bullets_stack_0_list(a4),a1
  moveq.l    #ig_player_bullet_sizeof,d0
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
.bullets_loop_0:
  clr.b      ig_player_bullet_active(a0)
  add.l      d0,a0
  clr.l      (a1)+
  dbf        d7,.bullets_loop_0

  lea.l      ig_om_player_bullets_stack_1(a4),a0
  lea.l      ig_om_player_bullets_stack_1_list(a4),a1
  moveq.l    #ig_player_bullet_sizeof,d0
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
.bullets_loop_1:
  clr.b      ig_player_bullet_active(a0)
  add.l      d0,a0
  clr.l      (a1)+
  dbf        d7,.bullets_loop_1

  lea.l      ig_om_player_bullets_stack_2(a4),a0
  lea.l      ig_om_player_bullets_stack_2_list(a4),a1
  moveq.l    #ig_player_bullet_sizeof,d0
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
.bullets_loop_2:
  clr.b      ig_player_bullet_active(a0)
  add.l      d0,a0
  clr.l      (a1)+
  dbf        d7,.bullets_loop_2

  ; init bullet/firing values
  move.w     #PlayerFireDelay,ig_om_player_bullets_fire_delay(a4)
  move.w     #PlayerFireDelay,ig_om_player_bullets_fire_delay_count(a4)           ; so bullet can be fired immediately

  ; set sprite pointers in copperlist
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a0
  lea.l      ig_cm_player_sprites_buffer_0(a5),a3
  bsr.s      .set_pointers_in_copperlist
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a0
  lea.l      ig_cm_player_sprites_buffer_1(a5),a3
  ; fall-through intended

.set_pointers_in_copperlist
  ; external guns / satellites (no playershots)
  ; reuse sprites 0-1 from panel
  lea.l      ig_cm_cl_reuse_sprites(a0),a1
  move.l     a3,d0
  add.l      #ig_player_sprite0,d0
  move.w     d0,6(a1)                                                             ; SPR0PTL
  swap       d0
  move.w     d0,2(a1)                                                             ; SPR0PTH
  move.l     a3,d0
  add.l      #ig_player_sprite1,d0
  move.w     d0,22(a1)                                                            ; SPR1PTL
  swap       d0
  move.w     d0,18(a1)                                                            ; SPR1PTH
  moveq.l    #0,d0
  move.w     d0,10(a1)                                                            ; SPR0POS
  move.w     d0,14(a1)                                                            ; SPR0CTL
  move.w     d0,26(a1)                                                            ; SPR1POS
  move.w     d0,30(a1)                                                            ; SPR1CTL

  ; external guns / satellites (playershots first when visible)
  ; sprites 2-3
  lea.l      ig_cm_cl_sprites(a0),a1
  move.l     a3,d0
  add.l      #ig_player_sprite2,d0
  move.w     d0,22(a1)
  swap       d0
  move.w     d0,18(a1)
  move.l     a3,d0
  add.l      #ig_player_sprite3,d0
  move.w     d0,30(a1)
  swap       d0
  move.w     d0,26(a1)

  ; player ship (playershots first when visible)
  ; sprites 4-7
  lea.l      ig_cm_cl_sprites(a0),a0
  move.l     a3,d0
  add.l      #ig_player_sprite4,d0
  move.w     d0,38(a0)
  swap       d0
  move.w     d0,34(a0)
  move.l     a3,d0
  add.l      #ig_player_sprite5,d0
  move.w     d0,46(a0)
  swap       d0
  move.w     d0,42(a0)
  move.l     a3,d0
  add.l      #ig_player_sprite6,d0
  move.w     d0,54(a0)
  swap       d0
  move.w     d0,50(a0)
  move.l     a3,d0
  add.l      #ig_player_sprite7,d0
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
  beq.s      .test_fire
  add.l      ig_om_player_speed(a4),d4
  add.w      #1,ig_om_player_right_for_frames(a4)
  clr.w      ig_om_player_left_for_frames(a4)
  clr.w      ig_om_player_centered_for_frames(a4)
  cmp.l      ig_om_player_max_xpos(a4),d4
  ble.s      .test_fire
  move.l     ig_om_player_max_xpos(a4),d4
.test_fire:
  move.l     d4,ig_om_player_xpos(a4)
  move.l     d5,ig_om_player_ypos(a4)
  add.w      #1,ig_om_player_bullets_fire_delay_count(a4)                         ; increment fire delay counter
  btst       #JsFire,d0
  beq.s      .test_end
  bsr        player_weapon_fire
.test_end:

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

  bsr        player_weapon_update

  ; *******************************
  ; begin of drawing to sprite data
  ; *******************************

  ; init working pointers
  move.l     ig_om_buffers_backbuffer(a4),a0
  move.l     ig_buffers_sprites_pointer(a0),a1

  lea.l      ig_om_player_sprite_0_work_pointer(a4),a3
  move.l     a1,(a3)+
  lea.l      ig_player_sprite1(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite2(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite3(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite4(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite5(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite6(a1),a2
  move.l     a2,(a3)+
  lea.l      ig_player_sprite7(a1),a2
  move.l     a2,(a3)
  
  ; draw bullet stack 0 bullets to SPR2+SPR3
  lea.l      ig_om_player_bullets_stack_0_list(a4),a1
  move.l     ig_om_player_sprite_2_work_pointer(a4),a2
  move.l     ig_om_player_sprite_3_work_pointer(a4),a3
  bsr        .draw_bullet_stack
  move.l     a2,ig_om_player_sprite_2_work_pointer(a4)
  move.l     a3,ig_om_player_sprite_3_work_pointer(a4)

  ; draw bullet stack 1 bullets to SPR4+SPR5
  lea.l      ig_om_player_bullets_stack_1_list(a4),a1
  move.l     ig_om_player_sprite_4_work_pointer(a4),a2
  move.l     ig_om_player_sprite_5_work_pointer(a4),a3
  bsr        .draw_bullet_stack
  move.l     a2,ig_om_player_sprite_4_work_pointer(a4)
  move.l     a3,ig_om_player_sprite_5_work_pointer(a4)

  ; draw bullet stack 2 bullets to SPR6+SPR7
  lea.l      ig_om_player_bullets_stack_2_list(a4),a1
  move.l     ig_om_player_sprite_6_work_pointer(a4),a2
  move.l     ig_om_player_sprite_7_work_pointer(a4),a3
  bsr        .draw_bullet_stack
  move.l     a2,ig_om_player_sprite_6_work_pointer(a4)
  move.l     a3,ig_om_player_sprite_7_work_pointer(a4)

  ; TODO: draw satellites / side guns TO SPR0+SPR1 and SPR2+SPR3

  ; end of sprite data SPR0-SPR3    
  move.l     ig_om_player_sprite_0_work_pointer(a4),a2
  clr.l      (a2)
  move.l     ig_om_player_sprite_1_work_pointer(a4),a2
  clr.l      (a2)
  move.l     ig_om_player_sprite_2_work_pointer(a4),a2
  clr.l      (a2)
  move.l     ig_om_player_sprite_3_work_pointer(a4),a2
  clr.l      (a2)

  ; draw player ship to sprite data
  move.w     ig_om_player_xpos(a4),d4                                             ; no fraction needed
  move.w     ig_om_player_ypos(a4),d5                                             ; no fraction needed
  move.w     #PlayerShipHeight,d6
  bsr        .calc_pos_ctl

  moveq.l    #0,d0
  move.w     ig_om_player_gfx_width_bytes(a4),d0

  move.l     ig_om_player_gfx_ptr(a4),a1
  move.l     ig_om_player_anim_offset(a4),d3
  move.l     ig_om_player_sprite_4_work_pointer(a4),a2
  move.l     ig_om_player_sprite_5_work_pointer(a4),a3
  bsr.s      .write_control_words_and_gfx_to_sprite_data
  ; end of sprite data SPR4 and SPR5
  clr.l      (a2)
  clr.l      (a3)

  addq.w     #8,d1                                                                ; 6+7 are placed exactly to the right of 4+5
  moveq.l    #2,d3                                                                ; 6+7 are placed exactly to the right of 4+5
  add.l      ig_om_player_anim_offset(a4),d3
  move.l     ig_om_player_gfx_ptr(a4),a1
  move.l     ig_om_player_sprite_6_work_pointer(a4),a2
  move.l     ig_om_player_sprite_7_work_pointer(a4),a3
  bsr.s      .write_control_words_and_gfx_to_sprite_data
  ; end of sprite data SPR6 and SPR7
  clr.l      (a2)
  clr.l      (a3)

  rts

; in:
;  d0.l - width of source gfx in bytes
;  d1.w - SPRxPOS
;  d2.w - SPRxCTL
;  d3.w - offset of anim step in source gfx in bytes
;  d6.w - height of sprite in pixels
;  a1.l - pointer to source gfx
;  a2.l - pointer to first sprite data
;  a3.l - pointer to second sprite data
.write_control_words_and_gfx_to_sprite_data:
  ; control words
  move.w     d1,(a2)+
  move.w     d2,(a2)+
  bset       #7,d2                                                                ; set attach bit
  move.w     d1,(a3)+
  move.w     d2,(a3)+
  bclr       #7,d2                                                                ; clear attach bit

  ; bitmap data
  lea.l      (a1,d3.w),a1
  move.w     d6,d7
  subq.w     #1,d7
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

  rts

; in:
;   d4.w - xpos
;   d5.w - ypos
;   d6.w - height of sprite in pixels
; out:
;   d1.w - SPRxPOS
;   d2.w - SPRxCTL
.calc_pos_ctl:

  ; add beam start pos
  add.w      #IgScreenStartX,d4
  add.w      #IgScreenStartY,d5

  move.w     d5,d1
  lsl.w      #8,d1
  move.w     d4,d0
  lsr.w      #1,d0
  add.w      d0,d1                                                                ; SPRxPOS
  move.w     d5,d0
  add.w      d6,d0                                                                ; vstop
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

; in:
;   a1 - pointer to bullet stack struct
;   a2 - pointer to first sprite data
;   a3 - pointer to second sprite data
.draw_bullet_stack:
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
.draw_bullets_stack_loop:
  move.l     (a1)+,a0
  cmp.l      #0,a0
  beq.s      .draw_bullets_stack_loop_next
  tst.b      ig_player_bullet_active(a0)
  beq.s      .draw_bullets_stack_loop_next
  ; actually active bullet
  movem.l    d7/a0-a1,-(sp)
  move.w     ig_player_bullet_xpos(a0),d4                                         ; no fraction needed
  move.w     ig_player_bullet_ypos(a0),d5                                         ; no fraction needed
  move.w     ig_player_bullet_height(a0),d6
  bsr.s      .calc_pos_ctl
  move.l     ig_player_bullet_gfx_width_bytes(a0),d0
  move.w     ig_player_bullet_anim_offset(a0),d3
  move.l     ig_player_bullet_gfx_pointer(a0),a1
  bsr        .write_control_words_and_gfx_to_sprite_data
  movem.l    (sp)+,d7/a0-a1
.draw_bullets_stack_loop_next:
  addq.l     #4,a0
  dbf        d7,.draw_bullets_stack_loop
  rts

player_weapon_fire:
  movem.l    d0-d1/d4-d5,-(sp)

  ; check fire delay
  move.w     ig_om_player_bullets_fire_delay(a4),d0
  cmp.w      ig_om_player_bullets_fire_delay_count(a4),d0
  bgt.s      .exit

  ; spawn new bullet
  bsr        player_weapon_fire_simple                                            ; TODO: jsr to pointer when multiple weapons are available

  ; reset fire delay counter
  clr.w      ig_om_player_bullets_fire_delay_count(a4)

.exit:
  movem.l    (sp)+,d0-d1/d4-d5
  rts

player_weapon_update:
  movem.l    d0-d1/d4-d5,-(sp)

  ; update all bullet positions
  lea.l      ig_om_player_bullets_stack_0(a4),a0
  bsr.s      .position_update_per_stack
  lea.l      ig_om_player_bullets_stack_1(a4),a0
  bsr.s      .position_update_per_stack
  lea.l      ig_om_player_bullets_stack_2(a4),a0
  bsr.s      .position_update_per_stack

  ; check visibility of all bullets
  lea.l      ig_om_player_bullets_stack_0_list(a4),a0
  bsr.s      .bullet_still_visible_check_per_stack
  lea.l      ig_om_player_bullets_stack_1_list(a4),a0
  bsr.s      .bullet_still_visible_check_per_stack
  lea.l      ig_om_player_bullets_stack_2_list(a4),a0
  bsr.s      .bullet_still_visible_check_per_stack

  nop                                                                             ; TODO: jsr to pointer when multiple weapons are available (maybe height or anything else must be updated, too)

  movem.l    (sp)+,d0-d1/d4-d5
  rts

.position_update_per_stack:
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
  moveq.l    #ig_player_bullet_sizeof,d6
.position_update_per_stack_loop:
  tst.b      ig_player_bullet_active(a0)
  beq.s      .position_update_per_stack_loop_next
  move.l     ig_player_bullet_speed_x(a0),d0
  add.l      d0,ig_player_bullet_xpos(a0)
  move.l     ig_player_bullet_speed_y(a0),d0
  add.l      d0,ig_player_bullet_ypos(a0)
.position_update_per_stack_loop_next:
  add.l      d6,a0
  dbf        d7,.position_update_per_stack_loop
  rts

.bullet_still_visible_check_per_stack:
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
.bullet_still_visible_check_per_stack_loop:
  move.l     (a0),d0
  tst.l      d0
  beq.s      .bullet_still_visible_check_per_stack_loop_next
  move.l     d0,a1
  move.w     ig_player_bullet_xpos(a1),d0
  cmp.w      ig_player_bullet_min_xpos(a1),d0
  blt.s      .bullet_still_visible_check_per_stack_loop_remove_bullet
  cmp.w      ig_player_bullet_max_xpos(a1),d0
  bgt.s      .bullet_still_visible_check_per_stack_loop_remove_bullet
  move.w     ig_player_bullet_ypos(a1),d0
  cmp.w      ig_player_bullet_min_ypos(a1),d0
  blt.s      .bullet_still_visible_check_per_stack_loop_remove_bullet
  cmp.w      ig_player_bullet_max_ypos(a1),d0
  bgt.s      .bullet_still_visible_check_per_stack_loop_remove_bullet
  bra.s      .bullet_still_visible_check_per_stack_loop_next
.bullet_still_visible_check_per_stack_loop_remove_bullet:
  clr.l      (a0)
  clr.b      ig_player_bullet_active(a1)
.bullet_still_visible_check_per_stack_loop_next:
  addq.l     #4,a0
  dbf        d7,.bullet_still_visible_check_per_stack_loop
  rts

; TODO: for now no flexibility regarding 1-3 bullets and strength of 1-3 and speed-x and speed-y
player_weapon_fire_simple:
  lea.l      player_bullettype_simple_for_stack_0(pc),a1
  lea.l      ig_om_player_bullets_stack_0(a4),a2
  lea.l      ig_om_player_bullets_stack_0_list(a4),a3
  bsr        player_bullet_add_to_stack

  lea.l      player_bullettype_simple_for_stack_1(pc),a1
  lea.l      ig_om_player_bullets_stack_1(a4),a2
  lea.l      ig_om_player_bullets_stack_1_list(a4),a3
  bsr        player_bullet_add_to_stack

  lea.l      player_bullettype_simple_for_stack_2(pc),a1
  lea.l      ig_om_player_bullets_stack_2(a4),a2
  lea.l      ig_om_player_bullets_stack_2_list(a4),a3
  bsr        player_bullet_add_to_stack

  move.l     ig_om_player_fire_sfx(a4),a0
  bsr        _mt_playfx

  rts

; in:
;   a1 - pointer to struct ig_player_bullettype
;   a2 - pointer to ig_om_player_bullets_stack_XX
;   a3 - pointer to ig_om_player_bullets_stack_XX_list
; TODO: for now no flexibility regarding 1-3 bullets and strength of 1-3 and speed-x and speed-y
player_bullet_add_to_stack:

  ; check if empty slot is available
  moveq.l    #PlayerBulletsMaxCountStacked-1,d7
  moveq.l    #ig_player_bullet_sizeof,d6
  move.l     a2,a0
.check_loop:
  tst.b      ig_player_bullet_active(a0)
  beq.s      .found_empty_slot
  add.l      d6,a0
  dbf        d7,.check_loop

.no_empty_slot:
  rts

.found_empty_slot:
  move.l     a1,d6                                                                ; save a1 parameter
  ; move pointers up in sorted list
  moveq.l    #PlayerBulletsMaxCountStacked-2,d7
  move.l     a3,a1
.move_pointers_up_loop:
  move.l     4(a1),(a1)+
  dbf        d7,.move_pointers_up_loop

  ; add pointer to sorted list
  move.l     a0,(a1)

  ; init struct ig_player_bullet - MUST be changed accordingly when struct is changed
  move.l     d6,a1                                                                ; restore a1 parameter
  move.w     #$0100,(a0)+
  move.l     ig_om_player_xpos(a4),d0
  add.l      (a1)+,d0
  move.l     d0,(a0)+
  move.l     ig_om_player_ypos(a4),d0
  add.l      (a1)+,d0
  move.l     d0,(a0)+
  move.l     (a1)+,(a0)+
  move.l     (a1)+,(a0)+
  move.w     (a1)+,(a0)+
  move.w     (a1)+,(a0)+
  move.w     (a1)+,(a0)+
  move.w     (a1)+,(a0)+
  move.w     (a1)+,(a0)+
  move.l     (a1)+,(a0)+
  move.l     (a1)+,(a0)+
  move.w     (a1),(a0)
  rts

; must match struct ig_player_bullettype
player_bullettype_simple_for_stack_0:
  dc.w       0,0                                                                  ; xpos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       -10,0                                                                ; ypos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       -4,0                                                                 ; xpos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -16,0                                                                ; ypos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -15                                                                  ; minimum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is lower than this value
  dc.w       IgScreenWidth+1                                                      ; maximum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is greater than this value
  dc.w       -15                                                                  ; minimum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is lower than this value
  dc.w       IgScreenHeight+1                                                     ; maximum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is greater than this value
  dc.w       16                                                                   ; height of bullet in pixels
  dc.l       0                                                                    ; pointer to raw gfx data
  dc.l       0                                                                    ; width of source gfx in bytes
  dc.w       12                                                                   ; initial anim step offset in raw gfx data in bytes

; must match struct ig_player_bullettype
player_bullettype_simple_for_stack_1:
  dc.w       8,0                                                                  ; xpos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       -10,0                                                                ; ypos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       0,0                                                                  ; xpos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -16,0                                                                ; ypos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -15                                                                  ; minimum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is lower than this value
  dc.w       IgScreenWidth+1                                                      ; maximum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is greater than this value
  dc.w       -15                                                                  ; minimum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is lower than this value
  dc.w       IgScreenHeight+1                                                     ; maximum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is greater than this value
  dc.w       16                                                                   ; height of bullet in pixels
  dc.l       0                                                                    ; pointer to raw gfx data
  dc.l       0                                                                    ; width of source gfx in bytes
  dc.w       0                                                                    ; initial anim step offset in raw gfx data in bytes

; must match struct ig_player_bullettype
player_bullettype_simple_for_stack_2:
  dc.w       16,0                                                                 ; xpos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       -10,0                                                                ; ypos in screen coordinates as fixed-point 16/16 value relative to player position
  dc.w       4,0                                                                  ; xpos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -16,0                                                                ; ypos-add in screen coordinates as fixed-point 16/16 value
  dc.w       -15                                                                  ; minimum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is lower than this value
  dc.w       IgScreenWidth+1                                                      ; maximum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is greater than this value
  dc.w       -15                                                                  ; minimum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is lower than this value
  dc.w       IgScreenHeight+1                                                     ; maximum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is greater than this value
  dc.w       16                                                                   ; height of bullet in pixels
  dc.l       0                                                                    ; pointer to raw gfx data
  dc.l       0                                                                    ; width of source gfx in bytes
  dc.w       6                                                                    ; initial anim step offset in raw gfx data in bytes

  endif                                                                           ; ifnd INGAME_PLAYER_ASM
