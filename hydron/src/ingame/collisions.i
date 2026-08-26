                           ifnd       INGAME_COLLISIONS_I
INGAME_COLLISIONS_I equ 1

                           rsreset
coll_bounding_box_x1:      rs.w       1                      ; xpos of top-left edge
coll_bounding_box_y1:      rs.w       1                      ; ypos of top-left edge
coll_bounding_box_x2:      rs.w       1                      ; xpos of bottom-right edge
coll_bounding_box_y2:      rs.w       1                      ; ypos of bottom-right edge
coll_bounding_box_sizeof:  rs.b       0

                           endif                             ; ifnd INGAME_COLLISIONS_I
