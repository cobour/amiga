                    ifnd       SAVEGAME_I
SAVEGAME_I equ 1

                    rsreset
sg_data_score:      rs.l       1
sg_data_bricks:     rs.l       3
sg_data_playfield:  rs.b       100
sg_data_sizeof:     rs.b       0

                    endif                    ; ifnd SAVEGAME_I
