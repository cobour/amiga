  ifnd       INGAME_COLLISIONS_ASM
INGAME_COLLISIONS_ASM equ 1

  include    "src/ingame.i"

coll_player_enemies:

  ; can player be hit?
  tst.b      ig_om_player_status(a4)
  bne.s      .exit

  ; calc bounding box of player ship in screen coordinates (d0.w - d3.w)
  lea.l      .player_bounding_boxes(pc),a0
  move.l     ig_om_player_anim_offset(a4),d0
  add.w      d0,d0
  add.l      d0,a0
  move.w     (a0)+,d0
  move.w     (a0)+,d1
  move.w     (a0)+,d2
  move.w     (a0),d3
  move.w     ig_om_player_xpos(a4),d4
  move.w     ig_om_player_ypos(a4),d5
  add.w      d4,d0
  add.w      d4,d2
  add.w      d5,d1
  add.w      d5,d3

  ; check collision enemy <-> player
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.enemies_loop:
  tst.w      bob_status(a0)
  blt.s      .enemies_loop_next
  lea.l      enemy_bounding_box(a0),a1
  move.w     (a1)+,d4
  cmp.w      d4,d2
  blt.s      .enemies_loop_next                                         ; enemy completely to the right of player ship => no collision
  move.w     (a1)+,d4
  cmp.w      d4,d3
  blt.s      .enemies_loop_next                                         ; enemy completely below player ship => no collision
  move.w     (a1)+,d4
  cmp.w      d4,d0
  bgt.s      .enemies_loop_next                                         ; enemy completely to the left of player ship => no collision
  move.w     (a1),d4
  cmp.w      d4,d1
  bgt.s      .enemies_loop_next                                         ; enemy completely above player ship => no collision
  bra.s      coll_player_was_hit                                        ; implicit rts
.enemies_loop_next:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.enemies_loop

.exit:
  rts

; see coll_bounding_box_sizeof
.player_bounding_boxes:
  dc.w       7,1,25,20                                                  ; hard left
  dc.w       4,1,27,20                                                  ; left
  dc.w       2,1,30,20                                                  ; centered
  dc.w       5,1,28,20                                                  ; right
  dc.w       7,1,25,20                                                  ; hard right

; INTERNAL USE ONLY
coll_player_was_hit:
  ; update player status
  move.b     #PlayerStatusNoHit,ig_om_player_status(a4)
  move.b     #PlayerNoHitCountdown,ig_om_player_no_hit_countdown(a4)
  move.w     #PlayerRespawnBegin,ig_om_player_respawn_ypos(a4)

  ; trigger explosion
  move.w     ig_om_player_xpos(a4),d0
  move.w     ig_om_player_ypos(a4),d1
  sub.w      #(32-PlayerShipHeight)/2,d1
  bsr        explosions_new_large

  ; decrement lives counter and check for game over
  move.b     c_om_lives(a4),d0
  moveq.l    #1,d1
  move       #0,ccr
  sbcd       d1,d0
  move.b     d0,c_om_lives(a4)
  move.b     #2,ig_om_panel_redraw_lives(a4)

  tst.b      c_om_lives(a4)
  bgt.s      .no_game_over
  move.b     #50,ig_om_trigger_fade_out_countdown(a4)
.no_game_over:

  ; later maybe: fade out everything but the panel, reset to respawn position, fade in again

  rts

  endif                                                                 ; ifnd INGAME_COLLISIONS_ASM
