                              ifnd       INGAME_I
INGAME_I     equ 1

                              include    "src/globals.i"
                              include    "src/ingame/screen.i"
                              include    "src/system/savegame.i"

; copperlist struct
                              rsreset
ig_cm_cl_initial_wait:        rs.l       1                                
ig_cm_cl_sprites:             rs.l       16
ig_cm_cl_bitplanes:           rs.l       12
ig_cm_cl_bpl_config:          rs.l       9
ig_cm_cl_colors:              rs.l       32
ig_cm_cl_wait_for_eof:        rs.l       2
ig_cm_cl_irq:                 rs.l       1
ig_cm_cl_end:                 rs.l       1
ig_cm_cl_sizeof:              rs.b       0

; chip mem struct
                              rsreset
ig_cm_common:                 rs.b       c_cm_sizeof
ig_cm_screenbuffer:           rs.b       IgScreenWidthBytes*IgScreenHeight*IgScreenBitPlanes    ; double-buffering with this buffer and screen-gfx loaded with file
ig_cm_asm_backup_0:           rs.b       IgScreenBitPlanes*2*16                                 ; size of active selector mark gfx - MUST be adjusted when marker size is changed from currently 16x16 px
ig_cm_asm_backup_1:           rs.b       IgScreenBitPlanes*2*16                                 ; size of active selector mark gfx - MUST be adjusted when marker size is changed from currently 16x16 px
ig_cm_score_backup:           rs.b       IgScreenBitPlanes*16*16                                ; size of score panel - 16 bytes wide (8 numbers * 2 bytes each), 16 rows, all bitplanes
ig_cm_timer_backup:           rs.b       IgScreenBitPlanes*4*16                                 ; size of score panel -  4 bytes wide (2 numbers * 2 bytes each), 16 rows, all bitplanes
ig_cm_datfile:                rs.b       f000_unzipped_filesize
ig_cm_sizeof:                 rs.b       0

; constants

IgModeSelect equ 1
IgModePlace  equ 2

; other mem struct
                              rsreset
ig_om_common:                 rs.b       c_om_sizeof
ig_om_frontbuffer:            rs.l       1                                                      ; points to currently shown buffer
ig_om_backbuffer:             rs.l       1                                                      ; points to buffer that is currently drawn to
ig_om_copperlist:             rs.l       1                                                      ; points to copperlist in chip mem
ig_om_act_mode:               rs.b       1                                                      ; IgModeSelect or IgModePlace
ig_om_score_draw_counter:     rs.b       1
ig_om_gameover:               rs.b       1                                                      ; 0 = game may proceed, 1 = game is over
ig_om_end_countdown:          rs.b       1                                                      ; 0 = nothing to do; >0 = decrement by 1 and exit when reaching 0
ig_om_music_volume:           rs.w       1
ig_om_god_request:            rs.b       1                                                      ; request for a game-over-detection; 1 = request pending, otherwise 0
ig_om_clearance_in_progress:  rs.b       1                                                      ; boolean; completed rows/columns waiting for clearance?
ig_om_save_and_back_to_mm:    rs.b       1                                                      ; boolean
ig_om_clear_savegame:         rs.b       1                                                      ; boolean
ig_om_fade_color_tab:         rs.b       32*2*16
ig_om_savegame:               rs.b       s000_unzipped_filesize
ig_om_datfile:                rs.b       f001_unzipped_filesize
ig_om_sizeof:                 rs.b       0

                              endif                                                             ; ifnd INGAME_I
