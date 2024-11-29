             ifnd       BRICK_SELECTORS_INTERNAL_I
BRICK_SELECTORS_INTERNAL_I equ 1

; smallest value must be greater than 1, otherwise not drawn to both buffers
BsDrawCountdown            equ 42
BsDrCd_1                   equ 42
BsDrCd_2                   equ 32
BsDrCd_3                   equ 22
BsDrCd_4                   equ 12
BsDrCd_5                   equ 2

; offsets of selectors in framebuffer
SelectorOffset_1           equ (IgScreenWidthBytes*IgScreenBitPlanes*16)+25
SelectorOffset_2           equ (IgScreenWidthBytes*IgScreenBitPlanes*76)+25
SelectorOffset_3           equ (IgScreenWidthBytes*IgScreenBitPlanes*136)+25

             rsreset
bs_big:      rs.l       1
bs_small:    rs.l       1
bs_area:     rs.b       25
bs_padding:  rs.b       1
bs_sizeof:   rs.b       0

             endif                                    ; ifnd BRICK_SELECTORS_INTERNAL_I
