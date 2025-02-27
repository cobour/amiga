                 ifnd       BRICK_SELECTORS_INTERNAL_I
BRICK_SELECTORS_INTERNAL_I  equ 1

; smallest value must be greater than 1, otherwise not drawn to both buffers
BsDrawCountdown             equ 14
BsDrCd_1                    equ 14
BsDrCd_2                    equ 11
BsDrCd_3                    equ 8
BsDrCd_4                    equ 5
BsDrCd_5                    equ 2

; offsets of selectors in framebuffer
SelectorOffset_1            equ (IgScreenWidthBytes*IgScreenBitPlanes*16)+29
SelectorOffset_2            equ (IgScreenWidthBytes*IgScreenBitPlanes*76)+29
SelectorOffset_3            equ (IgScreenWidthBytes*IgScreenBitPlanes*136)+29

; offsets for active selector marker
ActiveSelectorMarkerOffset0 equ 26+(IgScreenBitPlanes*IgScreenWidthBytes*27)
ActiveSelectorMarkerOffset1 equ 26+(IgScreenBitPlanes*IgScreenWidthBytes*87)
ActiveSelectorMarkerOffset2 equ 26+(IgScreenBitPlanes*IgScreenWidthBytes*147)
ActiveSelectorMarkAddUp     equ -(IgScreenBitPlanes*IgScreenWidthBytes*6) ; diff between positions is 60 rows, multiplier here (5) must be divider of 60
ActiveSelectorMarkAddDown   equ (IgScreenBitPlanes*IgScreenWidthBytes*6) ; diff between positions is 60 rows, multiplier here (5) must be divider of 60

; brick selector struct
                 rsreset
bs_big:          rs.l       1
bs_small:        rs.l       1
bs_area:         rs.b       25
bs_empty:        rs.b       1                             ; is selector empty (no = 0, yes = any other value)
bs_sizeof:       rs.b       0
; when changing size, see reset_brick_selector

; brick selector redraw struct
                 rsreset
bsrd_countdown:  rs.w       1
bsrd_scheme:     rs.l       1
bsrd_sizeof:     rs.b       0
; when changing size, see clear_vars

                 endif                                    ; ifnd BRICK_SELECTORS_INTERNAL_I
