                            ifnd       ENEMIES_I
ENEMIES_I    equ 1

                            include    "src/ingame/bob.i"
                            include    "src/ingame/collisions.i"

EnemiesCount equ 16                                                 ; max enemies

                            rsreset
enemytype_bobtype_id:       rs.l       1                            ; ID of corresponding bobtype
enemytype_bobtype_pointer:  rs.l       1                            ; pointer to corresponding bobtype
enemytype_bounding_box:     rs.b       coll_bounding_box_sizeof     ; bounding box of enemy (relative to screen position)
; later: enemytype_initial_hitpoints, enemytype_score_when_killed ...
enemytype_sizeof:           rs.b       0

                            rsreset
enemy_bob_struct:           rs.b       bob_sizeof                   ; embedded bob-struct
enemy_enemytype_pointer:    rs.l       1                            ; pointer to enemytype-struct
enemy_move_next_step:       rs.l       1                            ; pointer to next step of movement table OR zero when there is no movement table
enemy_move_end_of_table:    rs.l       1                            ; pointer directly behind movement table
enemy_bounding_box:         rs.b       coll_bounding_box_sizeof     ; bounding box of enemy (absolute screen position values, updated for every frame depending on current screen position)
enemy_sizeof:               rs.b       0

                            endif                                   ; ifnd ENEMIES_I
