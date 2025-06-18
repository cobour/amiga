                                ifnd       MAINMENU_I
MAINMENU_I                 equ 1

                                include    "src/globals.i"
                                include    "src/system/savegame.i"
                                include    "src/mainmenu/screen.i"

; copperlist struct
                                rsreset
mm_cm_cl_initial_wait:          rs.l       1                                
mm_cm_cl_sprites:               rs.l       16
mm_cm_cl_bitplanes:             rs.l       12
mm_cm_cl_bpl_config:            rs.l       9
mm_cm_cl_colors:                rs.l       32
mm_cm_cl_wait_for_eof:          rs.l       2
mm_cm_cl_irq:                   rs.l       1
mm_cm_cl_end:                   rs.l       1
mm_cm_cl_sizeof:                rs.b       0

; chip mem struct
MmTextAreaBufferWidth      equ 256
MmTextAreaBufferWidthBytes equ MmTextAreaBufferWidth/8
MmTextAreaBufferWidthWords equ MmTextAreaBufferWidth/16
MmTextAreaBufferHeight     equ 118
MmTextAreaBufferSize       equ (MmTextAreaBufferWidth/8)*MmTextAreaBufferHeight*MmScreenBitPlanes
MmOffsetOfTextArea         equ (MmScreenBitPlanes*MmScreenWidthBytes*108)+4

                                rsreset
mm_cm_common:                   rs.b       c_cm_sizeof
mm_cm_screenbuffer:             rs.b       MmScreenWidthBytes*MmScreenHeight*MmScreenBitPlanes
mm_cm_textarea_restore_buffer:  rs.b       MmTextAreaBufferSize                                   ; for restoring when changing content
mm_cm_textarea_print_buffer:    rs.b       MmTextAreaBufferSize                                   ; pre-print here before drawing to screenbuffer => for transition effect
mm_cm_datfile:                  rs.b       f004_unzipped_filesize
mm_cm_sizeof:                   rs.b       0

; other mem struct
                                rsreset
mm_om_common:                   rs.b       c_om_sizeof
mm_om_frontbuffer:              rs.l       1                                                      ; points to currently shown buffer
mm_om_backbuffer:               rs.l       1                                                      ; points to buffer that is currently drawn to
mm_om_copperlist:               rs.l       1                                                      ; points to copperlist in chip mem
mm_om_fade_color_tab:           rs.b       32*2*16
mm_om_music_volume:             rs.w       1
mm_om_end_countdown:            rs.b       1                                                      ; < 0 when not ending
mm_om_savegame_is_used:         rs.b       1                                                      ; boolean
mm_om_highscore_data:           rs.b       h000_unzipped_filesize
mm_om_datfile:                  rs.b       f005_unzipped_filesize
mm_om_sizeof:                   rs.b       0

                                endif                                                             ; ifnd MAINMENU_I
