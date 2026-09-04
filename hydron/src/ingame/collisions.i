                                 ifnd       INGAME_COLLISIONS_I
INGAME_COLLISIONS_I equ 1

                                 rsreset
coll_bounding_box_x1:            rs.w       1                      ; xpos of top-left edge
coll_bounding_box_y1:            rs.w       1                      ; ypos of top-left edge
coll_bounding_box_x2:            rs.w       1                      ; xpos of bottom-right edge
coll_bounding_box_y2:            rs.w       1                      ; ypos of bottom-right edge
coll_bounding_box_sizeof:        rs.b       0

                                 rsreset
coll_line_x1:                    rs.w       1                      ; xpos of (upper) starting point
coll_line_y1:                    rs.w       1                      ; ypos of (upper) starting point
coll_line_x2:                    rs.w       1                      ; xpos of (lower) end point
coll_line_y2:                    rs.w       1                      ; ypos of (lower) end point
coll_line_bullet_pointer:        rs.l       1                      ; pointer to bullet (see ig_player_bullet_sizeof)
coll_line_bullet_stack_pointer:  rs.l       1                      ; pointer to stack the bullet belongs to
coll_line_sizeof:                rs.b       0

                                 endif                             ; ifnd INGAME_COLLISIONS_I
