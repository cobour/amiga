                      ifnd       INGAME_I
INGAME_I equ 1

                      include    "src/globals.i"
                      include    "src/ingame/screen.i"

; Ingame copperlist struct
                      rsreset
ig_cm_cl_sprites:     rs.l       16
ig_cm_cl_bitplanes:   rs.l       12
ig_cm_cl_bpl_config:  rs.l       9
ig_cm_cl_irq:         rs.l       1
ig_cm_cl_colors:      rs.l       32
ig_cm_cl_end:         rs.l       1
ig_cm_cl_sizeof:      rs.b       0

; Ingame chip mem struct
                      rsreset
ig_cm_common:         rs.b       c_cm_sizeof
ig_cm_copperlist:     rs.b       ig_cm_cl_sizeof
ig_cm_screenbuffer:   rs.b       IgScreenWidthBytes*IgScreenHeight*IgScreenBitPlanes    ; double-buffering with this buffer and screen-gfx loaded with file
ig_cm_datfile:        rs.b       f000_unzipped_filesize
ig_cm_sizeof:         rs.b       0

; Ingame other mem struct
                      rsreset
ig_om_common:         rs.b       c_om_sizeof
ig_om_framecounter:   rs.l       1                                                      ; incremented by copper irq
ig_om_frontbuffer:    rs.l       1                                                      ; points to currently shown buffer
ig_om_backbuffer:     rs.l       1                                                      ; points to buffer that is currently drawn to
ig_om_copperlist:     rs.l       1                                                      ; points to copperlist in chip mem
ig_om_datfile:        rs.b       f001_unzipped_filesize
ig_om_sizeof:         rs.b       0

                      endif                                                             ; ifnd INGAME_I
