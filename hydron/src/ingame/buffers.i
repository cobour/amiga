                                ifnd       INGAME_BUFFERS_I
INGAME_BUFFERS_I equ 1

; struct that holds all pointers that represent one of the two buffers (double buffering)
                                rsreset
ig_buffers_copperlist_pointer:  rs.l       1                   ; pointer to copperlist
ig_buffers_sprites_pointer:     rs.l       1                   ; pointer to struct ig_player_sprite_sizeof
ig_buffers_sizeof:              rs.b       0

                                endif                          ; ifnd INGAME_BUFFERS_I
