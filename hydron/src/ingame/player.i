                                           ifnd       INGAME_PLAYER_I
INGAME_PLAYER_I              equ 1

; anim steps player ship (byte offsets)
PlayerShipAnimHardLeft       equ 0
PlayerShipAnimLeft           equ 4
PlayerShipAnimCentered       equ 8
PlayerShipAnimRight          equ 12
PlayerShipAnimHardRight      equ 16

; delay in frames between e.g. left and hard left
PlayerShipAnimSwitchDelay    equ 10

; delay between two bullets are fired
PlayerFireDelay              equ 8

; height of player ship in pixels
PlayerShipHeight             equ 22

; player bullets (must be updated when new weapons are added)
PlayerBulletsMaxHeight       equ 16
PlayerBulletsMaxCountStacked equ 4                                                                                                      ; maximum number of bullets that are displayed in one stack (player bullets are shown in max 3 stacks)

; player status and no-hit-countdown
PlayerStatusNormal           equ 0
PlayerStatusNoHit            equ 1
PlayerNoHitCountdown         equ 100                                                                                                    ; (odd means do not draw player ship, even means draw player ship)

; player respawn initial ypos add
PlayerRespawnBegin           equ 50

; struct holding data for hardware sprites
                                           rsreset                                                                                      ; contains one long for each control word pair and another long at the end for null bytes
ig_player_sprite0:                         rs.l       1                                                                                 ; player satellites --- just empty for now
ig_player_sprite1:                         rs.l       1                                                                                 ; player satellites --- just empty for now
ig_player_sprite2:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1                       ; player satellites / player bullets
ig_player_sprite3:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1                       ; player satellites / player bullets
ig_player_sprite4:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1+PlayerShipHeight+1    ; player ship / player bullets
ig_player_sprite5:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1+PlayerShipHeight+1    ; player ship / player bullets
ig_player_sprite6:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1+PlayerShipHeight+1    ; player ship / player bullets
ig_player_sprite7:                         rs.l       ((1+PlayerBulletsMaxHeight)*PlayerBulletsMaxCountStacked)+1+PlayerShipHeight+1    ; player ship / player bullets
ig_player_sprite_sizeof:                   rs.b       0

; struct holding metadata for bullets of a specific weapon type - each change MUST be reflected in descriptors in player.asm AND player_bullet_add_to_stack
                                           rsreset
ig_player_bullettype_rel_xpos:             rs.l       1                                                                                 ; xpos in screen coordinates as fixed-point 16/16 value relative to player position
ig_player_bullettype_rel_ypos:             rs.l       1                                                                                 ; ypos in screen coordinates as fixed-point 16/16 value relative to player position
ig_player_bullettype_speed_x:              rs.l       1                                                                                 ; xpos-add in screen coordinates as fixed-point 16/16 value
ig_player_bullettype_speed_y:              rs.l       1                                                                                 ; ypos-add in screen coordinates as fixed-point 16/16 value
ig_player_bullettype_line_left_xadd:       rs.w       1                                                                                 ; value that is added to the xpos for the left collision detection line
ig_player_bullettype_line_right_xadd:      rs.w       1                                                                                 ; value that is added to the xpos for the right collision detection line
ig_player_bullettype_min_xpos:             rs.w       1                                                                                 ; minimum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is lower than this value
ig_player_bullettype_max_xpos:             rs.w       1                                                                                 ; maximum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is greater than this value
ig_player_bullettype_min_ypos:             rs.w       1                                                                                 ; minimum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is lower than this value
ig_player_bullettype_max_ypos:             rs.w       1                                                                                 ; maximum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is greater than this value
ig_player_bullettype_height:               rs.w       1                                                                                 ; height of bullet in pixels
ig_player_bullettype_gfx_pointer:          rs.l       1                                                                                 ; pointer to raw gfx data
ig_player_bullettype_gfx_width_bytes:      rs.l       1                                                                                 ; width of source gfx in bytes
ig_player_bullettype_initial_anim_offset:  rs.w       1                                                                                 ; initial anim step offset in raw gfx data in bytes
ig_player_bullettype_sizeof:               rs.b       0

; struct defining one player bullet
                                           rsreset
ig_player_bullet_active:                   rs.b       1                                                                                 ; boolean
ig_player_bullet_dummy:                    rs.b       1
ig_player_bullet_xpos:                     rs.l       1                                                                                 ; xpos in screen coordinates as fixed-point 16/16 value
ig_player_bullet_ypos:                     rs.l       1                                                                                 ; ypos in screen coordinates as fixed-point 16/16 value
; values must match ig_player_bullettype_xxx - begin
ig_player_bullet_speed_x:                  rs.l       1                                                                                 ; xpos-add in screen coordinates as fixed-point 16/16 value
ig_player_bullet_speed_y:                  rs.l       1                                                                                 ; ypos-add in screen coordinates as fixed-point 16/16 value
ig_player_bullet_line_left_xadd:           rs.w       1                                                                                 ; value that is added to the xpos for the left collision detection line
ig_player_bullet_line_right_xadd:          rs.w       1                                                                                 ; value that is added to the xpos for the right collision detection line
ig_player_bullet_min_xpos:                 rs.w       1                                                                                 ; minimum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is lower than this value
ig_player_bullet_max_xpos:                 rs.w       1                                                                                 ; maximum valid xpos of bullet as int value (no fraction), delete bullet when current xpos is greater than this value
ig_player_bullet_min_ypos:                 rs.w       1                                                                                 ; minimum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is lower than this value
ig_player_bullet_max_ypos:                 rs.w       1                                                                                 ; maximum valid ypos of bullet as int value (no fraction), delete bullet when current ypos is greater than this value
ig_player_bullet_height:                   rs.w       1                                                                                 ; height of bullet in pixels
ig_player_bullet_gfx_pointer:              rs.l       1                                                                                 ; pointer to raw gfx data
ig_player_bullet_gfx_width_bytes:          rs.l       1                                                                                 ; width of source gfx in bytes
ig_player_bullet_anim_offset:              rs.w       1                                                                                 ; initial anim step offset in raw gfx data in bytes
; values must match ig_player_bullettype_xxx - end
ig_player_bullet_sizeof:                   rs.b       0


                                           endif                                                                                        ; ifnd INGAME_PLAYER_I
