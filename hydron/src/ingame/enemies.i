                         ifnd       ENEMIES_I
ENEMIES_I              equ 1

EnemiesCount           equ 16                               ; max enemies

; see enemy_status
EnemyStatusInactive    equ -1
EnemyStatusRestoreOnly equ 0
EnemyStatusActive      equ 1

                         rsreset
enemy_restore_offset:    rs.w       1                       ; offset for restore
enemy_restore_bltsize:   rs.w       1                       ; bltsize for restore
enemy_restore_modulo:    rs.w       1                       ; modulo for restore
enemy_restore_sizeof:    rs.b       0

                         rsreset
enemy_status:            rs.w       1                       ; status of enemy
enemy_xpos:              rs.l       1                       ; xpos in screen coordinates as fixed-point
enemy_ypos:              rs.l       1                       ; ypos in screen coordinates as fixed-point
enemy_width:             rs.w       1                       ; width of enemy in pixels
enemy_height:            rs.w       1                       ; height of enemy in pixels
enemy_width_words:       rs.w       1                       ; width of enemy in words
enemy_height_blt:        rs.w       1                       ; height for blitter (height * bitplanes)
enemy_data_pointer:      rs.l       1                       ; pointer to gfx data
enemy_mask_pointer:      rs.l       1                       ; pointer to mask
enemy_anim_offset:       rs.l       1                       ; offset in gfx (and mask) data for current anim step)
enemy_src_mod_no_shift:  rs.w       1                       ; source-modulo without pixel shift (xpos is at word-border) if full width of enemy is visible
enemy_src_mod_shift:     rs.w       1                       ; source-modulo with pixel shift (xpos is NOT at word-border) if full width of enemy is visible
enemy_trg_mod_no_shift:  rs.w       1                       ; target-modulo without pixel shift (xpos is at word-border) if full width of enemy is visible
enemy_trg_mod_shift:     rs.w       1                       ; target-modulo with pixel shift (xpos is NOT at word-border) if full width of enemy is visible
enemy_restore_1a:        rs.b       enemy_restore_sizeof    ; restore-struct for current blit (all or first part if split)
enemy_restore_1b:        rs.b       enemy_restore_sizeof    ; restore-struct fur corrent blit (second part if split)
enemy_restore_2a:        rs.b       enemy_restore_sizeof    ; restore-struct for current restore (all or first part if split)
enemy_restore_2b:        rs.b       enemy_restore_sizeof    ; restore-struct fur corrent restore (second part if split)
enemy_sizeof:            rs.b       0
                         endif                              ; ifnd ENEMIES_I
