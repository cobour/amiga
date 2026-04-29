                                ifnd       INGAME_PANEL_I
INGAME_PANEL_I equ 1

; structure of one panel-row in the copperlist
                                rsreset
panel_clrow_wait_0:             rs.l       1
panel_clrow_color:              rs.l       1
panel_clrow_lives_0:            rs.l       2
panel_clrow_wait_1:             rs.l       1
panel_clrow_lives_1:            rs.l       2
panel_clrow_noop:               rs.l       2
panel_clrow_score_0:            rs.l       2
panel_clrow_score_1:            rs.l       2
panel_clrow_score_2:            rs.l       2
panel_clrow_hiscore_0:          rs.l       2
panel_clrow_hiscore_1:          rs.l       2
panel_clrow_hiscore_2:          rs.l       2
panel_clrow_wait_3:             rs.l       1
panel_clrow_bitplane_pointers:  rs.l       12
panel_clrow_sizeof:             rs.b       0

                                endif                        ; ifnd INGAME_PANEL_I
