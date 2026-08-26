                                        ifnd       INGAME_EXPLOSIONS_I
INGAME_EXPLOSIONS_I equ 1

                                        include    "src/ingame.i"

ExplosionsCount     equ 4

                                        rsreset
explosion_bob:                          rs.b       bob_sizeof             ; bob struct
explosion_frame_delay:                  rs.b       1                      ; delay between frames
explosion_current_frame_delay_counter:  rs.b       1                      ; current counter of frame delay ; countdown when BobStatusRestoreOnly to inactivate completely
explosion_max_anim_step_offset:         rs.w       1                      ; offset of the last valid anim step (anim end)
explosion_anim_step_add:                rs.w       1                      ; this will be added to offset for next anim frame
explosion_sizeof:                       rs.b       0

                                        endif                             ; ifnd INGAME_EXPLOSIONS_I
