                                ifnd       HIGHSCORES_I
HIGHSCORES_I               equ 1

                                include    "src/globals.i"
                                include    "src/highscores/screen.i"

; highscores data struct (file)
                                rsreset
hs_data_entry_name:             rs.b       6
hs_data_entry_score:            rs.b       4
hs_data_entry_sizeof:           rs.b       0
                                rsreset
hs_data_speedrun:               rs.b       hs_data_entry_sizeof*5
hs_data_infinite:               rs.b       hs_data_entry_sizeof*5
hs_data_sizeof:                 rs.b       0

HsDataNameLength           equ hs_data_entry_score-hs_data_entry_name

; copperlist struct
                                rsreset
hs_cm_cl_initial_wait:          rs.l       1                                
hs_cm_cl_sprites:               rs.l       16
hs_cm_cl_bitplanes:             rs.l       12
hs_cm_cl_bpl_config:            rs.l       9
hs_cm_cl_colors:                rs.l       32
hs_cm_cl_wait_for_eof:          rs.l       2
hs_cm_cl_irq:                   rs.l       1
hs_cm_cl_end:                   rs.l       1
hs_cm_cl_sizeof:                rs.b       0

; chip mem struct
                                rsreset
hs_cm_common:                   rs.b       c_cm_sizeof
hs_cm_cursor_restore_buffer:    rs.b       2*HsScreenBitPlanes*16
hs_cm_textarea_restore_buffer:  rs.b       (256/8)*98*HsScreenBitPlanes
hs_cm_screenbuffer:             rs.b       HsScreenWidthBytes*HsScreenHeight*HsScreenBitPlanes
hs_cm_datfile:                  rs.b       f002_unzipped_filesize
hs_cm_sizeof:                   rs.b       0

; other mem struct
                                rsreset
hs_om_common:                   rs.b       c_om_sizeof
hs_om_frontbuffer:              rs.l       1                                                      ; points to currently shown buffer
hs_om_backbuffer:               rs.l       1                                                      ; points to buffer that is currently drawn to
hs_om_copperlist:               rs.l       1                                                      ; points to copperlist in chip mem
hs_om_fade_color_tab:           rs.b       32*2*16
hs_om_highscore_data_pointer:   rs.l       1                                                      ; points to the data (depending on GameMode)
hs_om_highscore_data:           rs.b       h000_unzipped_filesize
hs_om_music_volume:             rs.w       1
hs_om_end_countdown:            rs.b       1                                                      ; < 0 when not ending
hs_om_save_on_exit:             rs.b       1                                                      ; 0 = no; any other value = yes
hs_om_view_screen:              rs.b       1                                                      ; see HsViewScreen...
hs_om_new_entry_index:          rs.b       1                                                      ; index of new entry when added (0-4)
hs_om_new_entry_pointer:        rs.l       1
hs_om_datfile:                  rs.b       f003_unzipped_filesize
hs_om_sizeof:                   rs.b       0

HsViewScreenYourScore      equ 0
HsViewScreenHighScoreTable equ 1
HsViewScreenEditEntry      equ 2

HsOffsetOfTextArea         equ (HsScreenBitPlanes*HsScreenWidthBytes*127)+4
HsTextAreaLineAdd          equ HsScreenBitPlanes*HsScreenWidthBytes*20

                                endif                                                             ; ifnd HIGHSCORES_I
