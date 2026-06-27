                           ifnd       INGAME_BOB_I
INGAME_BOB_I         equ 1

BobTypeCount         equ 32

; see bob_status
BobStatusInactive    equ -1
BobStatusRestoreOnly equ 0
BobStatusActive      equ 1

                           rsreset
bob_restore_offset:        rs.w       1                     ; offset for restore
bob_restore_bltsize:       rs.w       1                     ; bltsize for restore
bob_restore_modulo:        rs.w       1                     ; modulo for restore
bob_restore_sizeof:        rs.b       0

                           rsreset
bobtype_width:             rs.w       1                     ; width of bob in pixels
bobtype_height:            rs.w       1                     ; height of bob in pixels
bobtype_width_words:       rs.w       1                     ; width of bob in words
bobtype_height_blt:        rs.w       1                     ; height for blitter (height * bitplanes)
bobtype_data_pointer:      rs.l       1                     ; pointer to gfx data
bobtype_mask_pointer:      rs.l       1                     ; pointer to mask
bobtype_src_mod_no_shift:  rs.w       1                     ; source-modulo without pixel shift (xpos is at word-border) if full width of bob is visible
bobtype_src_mod_shift:     rs.w       1                     ; source-modulo with pixel shift (xpos is NOT at word-border) if full width of bob is visible
bobtype_trg_mod_no_shift:  rs.w       1                     ; target-modulo without pixel shift (xpos is at word-border) if full width of bob is visible
bobtype_trg_mod_shift:     rs.w       1                     ; target-modulo with pixel shift (xpos is NOT at word-border) if full width of bob is visible
bobtype_sizeof:            rs.b       0


                           rsreset
bob_bobtype_pointer:       rs.l       1                     ; pointer to bobtype-struct
bob_status:                rs.w       1                     ; status of bob
bob_xpos:                  rs.l       1                     ; xpos in screen coordinates as fixed-point
bob_ypos:                  rs.l       1                     ; ypos in screen coordinates as fixed-point
bob_anim_offset:           rs.l       1                     ; offset in gfx (and mask) data for current anim step)
bob_restore_1a:            rs.b       bob_restore_sizeof    ; restore-struct for current blit (all or first part if split)
bob_restore_1b:            rs.b       bob_restore_sizeof    ; restore-struct fur corrent blit (second part if split)
bob_restore_2a:            rs.b       bob_restore_sizeof    ; restore-struct for current restore (all or first part if split)
bob_restore_2b:            rs.b       bob_restore_sizeof    ; restore-struct fur corrent restore (second part if split)
bob_sizeof:                rs.b       0

                           endif                            ; ifnd INGAME_BOB_I
