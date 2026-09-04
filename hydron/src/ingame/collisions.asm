  ifnd       INGAME_COLLISIONS_ASM
INGAME_COLLISIONS_ASM equ 1

  include    "src/ingame.i"

  ifnd       UNITTEST

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
  cmp.w      #BobStatusActive,bob_status(a0)
  bne.s      .enemies_loop_next
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
  bra.s      .coll_player_was_hit                                       ; implicit rts
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

.coll_player_was_hit:
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

coll_enemies_bullets:
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.enemies_loop:
  tst.w      bob_status(a0)
  blt.s      .enemies_loop_next
  move.w     d7,-(sp)
  move.w     ig_om_coll_bullet_loop_counter(a4),d7
  tst.w      d7
  blt.s      .no_bullets
  lea.l      enemy_bounding_box(a0),a1
  lea.l      ig_om_coll_bullet_lines(a4),a2
  bsr.s      .coll_check_one_enemy
.no_bullets:
  move.w     (sp)+,d7
.enemies_loop_next:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.enemies_loop

  rts

  endif                                                                 ; ifnd UNITTEST

  ifd        UNITTEST
coll_check_one_enemy:
  endif                                                                 ; ifd UNITTEST

; checks an array of lines (represent moving bullets) against the bounding box of one enemy
; in:
;   a0.l = pointer to enemy (see enemy_sizeof)
;   a1.l = pointer to bounding box of enemy (see coll_bounding_box_sizeof)
;   a2.l = pointer to line array (see coll_line_sizeof)
;   d7.w = counter for line array (number of lines - 1)
.coll_check_one_enemy:
  move.l     a6,-(sp)

  ; cache enemy bounding box into registers
  move.w     (a1)+,d3                                                   ; d3 = left
  move.w     (a1)+,d5                                                   ; d5 = top
  move.w     (a1)+,d4                                                   ; d4 = right
  move.w     (a1)+,d6                                                   ; d6 = bottom

.lines_loop:
  ; fetch line coordinates from array (y2 >= y1)
  move.w     (a2)+,d0                                                   ; d0 = x1
  move.w     (a2)+,d1                                                   ; d1 = y1
  move.w     (a2)+,d2                                                   ; d2 = x2
  move.w     (a2)+,a3                                                   ; a3 = y2

  ; vertical range check
  cmp.w      d5,a3
  blt.s      .lines_loop_next
  cmp.w      d6,d1
  bgt.s      .lines_loop_next

  ; is direction down left or down right?
  cmp.w      d0,d2
  bge.s      .direction_down_right
  exg.l      d0,d2
.direction_down_right:

  ; bounding box checks
  cmp.w      d4,d0
  bgt.s      .lines_loop_next
  cmp.w      d3,d2
  blt.s      .lines_loop_next

  ; calculate midpoint to see if line actually crosses the boundary
  move.w     d0,d1                                                      ; d1 = min x
  add.w      d2,d1                                                      ; d1 = x1 + x2
  asr.w      #1,d1                                                      ; d1 = mid x

  move.w     a3,d0                                                      ; d0 = y2
  add.w      -6(a2),d0                                                  ; d0 = y1 + y2
  asr.w      #1,d0                                                      ; d0 = mid y

  ; check midpoint against bounding box
  cmp.w      d3,d1
  blt.s      .lines_loop_next
  cmp.w      d4,d1
  bgt.s      .lines_loop_next
  cmp.w      d5,d0
  blt.s      .lines_loop_next
  cmp.w      d6,d0
  bgt.s      .lines_loop_next

.intersect:

  ifd        UNITTEST
  moveq.l    #1,d0                                                      ; Output: 1 (Hit)
  bra.s      .exit
  else                                                                  ; ifd UNITTEST
  bsr.s      .enemy_hit_by_bullet
  bra.s      .lines_loop_next_after_hit
  endif                                                                 ; ifd UNITTEST

.lines_loop_next:
  addq.l     #8,a2                                                      ; skip coll_line_bullet_pointer and coll_line_bullet_stack_pointer
.lines_loop_next_after_hit:
  dbf        d7,.lines_loop

  ifd        UNITTEST
  moveq.l    #0,d0                                                      ; Output: 0 (Miss)
.exit:
  endif                                                                 ; ifd UNITTEST

  move.l     (sp)+,a6
  rts

  ifnd       UNITTEST

; DIRTIES A6!!
.enemy_hit_by_bullet:
  move.l     (a2)+,a3                                                   ; get coll_line_bullet_pointer
  move.l     (a2)+,a6                                                   ; get coll_line_bullet_stack_pointer

  ; remove bullet from bullet stack (reset ig_player_bullet_active and remove from stack list)
  ; IMPORTANT: if PlayerBulletsMaxCountStacked (currently 4) is changed, this must be changed, too
  ; each bullet is represented by two collision lines (left and right border), so maybe the bullet is already removed
  ; maybe tst.b ig_player_bullet_active(a3) and bra to .bullet_removed immediately?
  clr.b      ig_player_bullet_active(a3)
  cmp.l      (a6),a3
  bne.s      .not_in_first_slot
  clr.l      (a6)
  bra.s      .bullet_removed
.not_in_first_slot:
  cmp.l      4(a6),a3
  bne.s      .not_in_second_slot
  move.l     (a6),4(a6)
  clr.l      (a6)
  bra.s      .bullet_removed
.not_in_second_slot:
  cmp.l      8(a6),a3
  bne.s      .not_in_third_slot
  move.l     4(a6),8(a6)
  move.l     (a6),4(a6)
  clr.l      (a6)
  bra.s      .bullet_removed
.not_in_third_slot:
  cmp.l      12(a6),a3
  bne.s      .not_in_fourth_slot
  move.l     8(a6),12(a6)
  move.l     4(a6),8(a6)
  move.l     (a6),4(a6)
  clr.l      (a6)
  ; end of list, no bra necessary
.not_in_fourth_slot:
.bullet_removed:

  ; remove enemy
  move.w     #BobStatusRestoreOnly,bob_status(a0)

  ; trigger explosion
  bra        explosions_new_for_enemy                                   ; implicit rts

  endif                                                                 ; ifnd UNITTEST

  endif                                                                 ; ifnd INGAME_COLLISIONS_ASM
