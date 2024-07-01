                      ifnd       INGAME_I
INGAME_I           equ 1
                      include    "src/globals.i"

; Ingame screen definitions
IgScreenBitPlanes  equ 6
IgScreenWidth      equ 256
IgScreenWidthBytes equ (IgScreenWidth/8)
IgScreenHeight     equ 256
IgScreenStartX     equ $a1
IgScreenStartY     equ $2c
IgScreenStopX      equ IgScreenStartX+IgScreenWidth
IgScreenStopY      equ IgScreenStartY+IgScreenHeight

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
ig_cm_blockbuffer:    rs.b       512                ; TODO: inside framebuffer
ig_cm_filebuffer:     rs.b       100000             ; TODO: inside framebuffer
ig_cm_datfile:        rs.b       0                  ; variable filesizes, therefore this MUST be the last entry in this struct
ig_cm_sizeof:         rs.b       0

; Ingame other mem struct
                      rsreset
ig_om_common:         rs.b       c_om_sizeof
ig_om_datfile:        rs.b       0                  ; variable filesizes, therefore this MUST be the last entry in this struct
ig_om_sizeof:         rs.b       0

                      endif                         ; ifnd INGAME_I
