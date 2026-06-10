                           ifnd       FADE_I
FADE_I equ 1

                           rsreset
fade_color_tab:            rs.l       1         ; pointer to color tab for fade
fade_color_tab_next_step:  rs.l       1         ; pointer to next step in color tab
fade_color_tab_step_size:  rs.l       1         ; color tab step size
fade_step_countdown:       rs.w       1         ; countdown (how many steps left)
fade_number_of_colors:     rs.w       1         ; num of colors minus 1 = for dbf-loops
fade_sizeof:               rs.b       0


                           endif                ; ifnd FADE_I
