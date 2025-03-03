                        ifnd       MAINMENU_I
MAINMENU_I equ 1

                        include    "src/globals.i"
                        include    "src/mainmenu/screen.i"

; copperlist struct
                        rsreset
mm_cm_cl_sprites:       rs.l       16
mm_cm_cl_bitplanes:     rs.l       12
mm_cm_cl_bpl_config:    rs.l       9
mm_cm_cl_colors:        rs.l       32
mm_cm_cl_wait_for_eof:  rs.l       2
mm_cm_cl_irq:           rs.l       1
mm_cm_cl_end:           rs.l       1
mm_cm_cl_sizeof:        rs.b       0

; chip mem struct
                        rsreset
mm_cm_common:           rs.b       c_cm_sizeof
mm_cm_screenbuffer:     rs.b       MmScreenWidthBytes*MmScreenHeight*MmScreenBitPlanes
mm_cm_datfile:          rs.b       f004_unzipped_filesize
mm_cm_sizeof:           rs.b       0

; other mem struct
                        rsreset
mm_om_common:           rs.b       c_om_sizeof
mm_om_datfile:          rs.b       f005_unzipped_filesize
mm_om_sizeof:           rs.b       0

                        endif                                                             ; ifnd MAINMENU_I
