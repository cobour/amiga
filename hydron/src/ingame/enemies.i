                            ifnd       ENEMIES_I
ENEMIES_I    equ 1

                            include    "src/ingame/bob.i"

EnemiesCount equ 16                                          ; max enemies

                            rsreset
enemytype_bobtype_id:       rs.l       1                     ; ID of corresponding bobtype
enemytype_bobtype_pointer:  rs.l       1                     ; pointer to corresponding bobtype
; later: enemytype_initial_hitpoints, enemytype_score_when_killed ...
enemytype_sizeof:           rs.b       0

                            rsreset
enemy_bob_struct:           rs.b       bob_sizeof            ; embedded bob-struct
enemy_enemytype_pointer:    rs.l       1                     ; pointer to enemytype-struct
enemy_sizeof:               rs.b       0

                            endif                            ; ifnd ENEMIES_I
