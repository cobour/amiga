             ifnd       BRICK_SELECTORS_INTERNAL_I
BRICK_SELECTORS_INTERNAL_I equ 1

             rsreset
bs_big:      rs.l       1
bs_small:    rs.l       1
bs_area:     rs.b       25
bs_padding:  rs.b       1
bs_sizeof:   rs.b       0

             endif                                    ; ifnd BRICK_SELECTORS_INTERNAL_I
