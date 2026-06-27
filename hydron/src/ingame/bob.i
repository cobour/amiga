                       ifnd       INGAME_BOB_I
INGAME_BOB_I         equ 1

; see bob_status
BobStatusInactive    equ -1
BobStatusRestoreOnly equ 0
BobStatusActive      equ 1

                       rsreset
bob_restore_offset:    rs.w       1                     ; offset for restore
bob_restore_bltsize:   rs.w       1                     ; bltsize for restore
bob_restore_modulo:    rs.w       1                     ; modulo for restore
bob_restore_sizeof:    rs.b       0

                       rsreset
bob_status:            rs.w       1                     ; status of enemy
bob_xpos:              rs.l       1                     ; xpos in screen coordinates as fixed-point
bob_ypos:              rs.l       1                     ; ypos in screen coordinates as fixed-point
bob_width:             rs.w       1                     ; width of enemy in pixels
bob_height:            rs.w       1                     ; height of enemy in pixels
bob_width_words:       rs.w       1                     ; width of enemy in words
bob_height_blt:        rs.w       1                     ; height for blitter (height * bitplanes)
bob_data_pointer:      rs.l       1                     ; pointer to gfx data
bob_mask_pointer:      rs.l       1                     ; pointer to mask
bob_anim_offset:       rs.l       1                     ; offset in gfx (and mask) data for current anim step)
bob_src_mod_no_shift:  rs.w       1                     ; source-modulo without pixel shift (xpos is at word-border) if full width of enemy is visible
bob_src_mod_shift:     rs.w       1                     ; source-modulo with pixel shift (xpos is NOT at word-border) if full width of enemy is visible
bob_trg_mod_no_shift:  rs.w       1                     ; target-modulo without pixel shift (xpos is at word-border) if full width of enemy is visible
bob_trg_mod_shift:     rs.w       1                     ; target-modulo with pixel shift (xpos is NOT at word-border) if full width of enemy is visible
bob_restore_1a:        rs.b       bob_restore_sizeof    ; restore-struct for current blit (all or first part if split)
bob_restore_1b:        rs.b       bob_restore_sizeof    ; restore-struct fur corrent blit (second part if split)
bob_restore_2a:        rs.b       bob_restore_sizeof    ; restore-struct for current restore (all or first part if split)
bob_restore_2b:        rs.b       bob_restore_sizeof    ; restore-struct fur corrent restore (second part if split)
bob_sizeof:            rs.b       0

                       endif                            ; ifnd INGAME_BOB_I
