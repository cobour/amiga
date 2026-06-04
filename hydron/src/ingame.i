                                          ifnd       INGAME_I
INGAME_I           equ 1
                                          include    "src/globals.i"
                                          include    "src/ingame/background.i"
                                          include    "src/ingame/buffers.i"
                                          include    "src/ingame/panel.i"
                                          include    "src/ingame/player.i"

; Ingame screen definitions
IgScreenBitPlanes  equ 6
IgScreenWidth      equ 256
IgScreenWidthBytes equ (IgScreenWidth/8)
IgScreenHeight     equ 256
IgScreenStartX     equ $a1
IgScreenStartY     equ $2c
IgScreenStopX      equ IgScreenStartX+IgScreenWidth
IgScreenStopY      equ IgScreenStartY+IgScreenHeight

; Ingame copperlist struct
                                          rsreset
ig_cm_cl_sprites:                         rs.l       16
ig_cm_cl_sprite01_init:                   rs.l       4
ig_cm_cl_bitplanes:                       rs.l       12
ig_cm_cl_bpl_config:                      rs.l       9
ig_cm_cl_colors:                          rs.l       32
ig_cm_cl_panel:                           rs.b       panel_clrow_sizeof*16                                   ; includes re-setting bitplane pointers at end of each panel row
ig_cm_cl_sprite01_off:                    rs.l       3
ig_cm_cl_reset_color17:                   rs.l       1
ig_cm_cl_reuse_sprites:                   rs.l       8
ig_cm_cl_wait_and_bitplane_pointers:      rs.l       13
ig_cm_cl_irq:                             rs.l       3
ig_cm_cl_end:                             rs.l       1
ig_cm_cl_sizeof:                          rs.b       0

; Ingame chip mem struct
                                          rsreset
ig_cm_common:                             rs.b       c_cm_sizeof
; ingame/player.asm
ig_cm_player_sprites_buffer_0:            rs.b       ig_player_sprite_sizeof                                 ; buffer for hardware sprite data
ig_cm_player_sprites_buffer_1:            rs.b       ig_player_sprite_sizeof                                 ; buffer for hardware sprite data
; ingame/buffers.asm - should be last before data files area (because framebuffers are very large and otherwise e.g. "move.l ig_cm_xxx(a4),d0" would be out of range)
ig_cm_copperlist:                         rs.b       ig_cm_cl_sizeof                                         ; second copperlist (first one is inside loaded file)
ig_cm_framebuffer_one:                    rs.b       IgFrameBufferSize                                       ; first framebuffer  - MUST be placed one after another without anything between them
ig_cm_framebuffer_two:                    rs.b       IgFrameBufferSize                                       ; second framebuffer - MUST be placed one after another without anything between them
ig_cm_framebuffer_three:                  rs.b       IgFrameBufferSize                                       ; third framebuffer  - MUST be placed one after another without anything between them
; data files area
ig_cm_datfile:                            rs.b       0                                                       ; variable filesizes, therefore this MUST be the last entry in this struct
ig_cm_sizeof:                             rs.b       0

; Ingame other mem struct
                                          rsreset
ig_om_common:                             rs.b       c_om_sizeof
; ingame.asm
ig_om_backbuffer:                         rs.l       1                                                       ; pointer to current backbuffer struct, set in game loop
; ingame/player.asm
ig_om_player_gfx_ptr:                     rs.l       1                                                       ; pointer to the beginning of the gfx rawdata
ig_om_player_anim_offset:                 rs.l       1                                                       ; offset to the current anim step (to be added to ig_om_player_gfx_ptr)
ig_om_player_gfx_width_bytes:             rs.w       1                                                       ; width of the source graphics in bytes
ig_om_player_speed:                       rs.l       1                                                       ; current speed of player ship as fixed-point 16/16 value
ig_om_player_xpos:                        rs.l       1                                                       ; current xpos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_ypos:                        rs.l       1                                                       ; current ypos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_min_xpos:                    rs.w       1                                                       ; minimum valid xpos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_min_ypos:                    rs.w       1                                                       ; minimum valid ypos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_max_xpos:                    rs.w       1                                                       ; maximum valid xpos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_max_ypos:                    rs.w       1                                                       ; maximum valid ypos of player ship in screen coordinates as fixed-point 16/16 value
ig_om_player_left_for_frames:             rs.w       1                                                       ; player is moving left for x number of frames (for decision which animation frame to show)
ig_om_player_right_for_frames:            rs.w       1                                                       ; player is moving right for x number of frames (for decision which animation frame to show)
ig_om_player_centered_for_frames:         rs.w       1                                                       ; player is centered for x number of frames (for decision which animation frame to show)
ig_om_player_bullets_stack_0:             rs.b       ig_player_bullet_sizeof*PlayerBulletsMaxCountStacked    ; player bullets structs of stack 0
ig_om_player_bullets_stack_1:             rs.b       ig_player_bullet_sizeof*PlayerBulletsMaxCountStacked    ; player bullets structs of stack 1
ig_om_player_bullets_stack_2:             rs.b       ig_player_bullet_sizeof*PlayerBulletsMaxCountStacked    ; player bullets structs of stack 2
ig_om_player_bullets_fire_delay:          rs.w       1                                                       ; frames, until next bullet is fired
ig_om_player_bullets_fire_delay_count:    rs.w       1                                                       ; actual frame count since last bullet was fired
ig_om_player_bullets_stack_0_list:        rs.l       PlayerBulletsMaxCountStacked                            ; list of pointers to active bullets, sorted top-down (ypos), for stack 0
ig_om_player_bullets_stack_1_list:        rs.l       PlayerBulletsMaxCountStacked                            ; list of pointers to active bullets, sorted top-down (ypos), for stack 1
ig_om_player_bullets_stack_2_list:        rs.l       PlayerBulletsMaxCountStacked                            ; list of pointers to active bullets, sorted top-down (ypos), for stack 2
ig_om_player_fire_sfx:                    rs.l       1                                                       ; pointer to metadata struct for playback with ptplayer
ig_om_player_sprite_0_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_1_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_2_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_3_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_4_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_5_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_6_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
ig_om_player_sprite_7_work_pointer:       rs.l       1                                                       ; temporary pointers used during drawing all sprite data (bullets, satellites, player ship)
; ingame/panel.asm
ig_om_panel_font_pointer:                 rs.l       1                                                       ; pointer to the font rawdata
ig_om_panel_cl_offset:                    rs.l       1                                                       ; offset to the area of the copperlist where the panel values must be drawn
ig_om_panel_redraw_lives:                 rs.b       1                                                       ; boolean / must lives counter be drawn?
ig_om_panel_redraw_score:                 rs.b       1                                                       ; boolean / must score be drawn? (if new score is higher than old hiscore => update and redraw hiscore as well)
; ingame/buffers.asm
ig_om_buffers_framecount:                 rs.l       1                                                       ; counts the displayed frames (means drawn and manually swapped frames, not real monitor frames; should be the same, but when gameplay gets busy, maybe it will take two monitor frames to draw one game frame)
ig_om_buffer_one:                         rs.b       ig_buffers_sizeof                                       ; buffers-struct of buffer one (display swaps between one and two)
ig_om_buffer_two:                         rs.b       ig_buffers_sizeof                                       ; buffers-struct of buffer two (display swaps between one and two)
ig_om_buffer_three:                       rs.l       1                                                       ; pointer to third buffer; used only for restoring background of bobs
; ingame/background.asm
ig_om_background_tiles_gfx_pointer:       rs.l       1                                                       ; pointer to gfx data of background tiles
ig_om_background_tiles_width_in_bytes:    rs.l       1                                                       ; width of background tiles in bytes
ig_om_background_level_data_pointer:      rs.l       1                                                       ; pointer to level data
ig_om_background_level_data_end_pointer:  rs.l       1                                                       ; pointer to end of level data
ig_om_background_do_scroll:               rs.b       1                                                       ; boolean - must background scroll?
ig_om_background_stop_scroll_count:       rs.b       1                                                       ; counter - when scrolling stops, countdown how often the bpl pointers must be set again
ig_om_background_last_row_countdown:      rs.b       1                                                       ; last row of level data is drawn but needs to be scrolled in - when this countdown gets zero, scrolling must be stopped
ig_om_background_dummy:                   rs.b       1                                                       ; padding byte
ig_om_background_first_visible_line:      rs.w       1                                                       ; which line of the framebuffer is the first line that is visible onscreen? starts at 32
ig_om_background_first_visible_offset:    rs.w       1                                                       ; offset in framebuffer of ig_om_background_first_visible_line
ig_om_background_fill_row_offset:         rs.w       1                                                       ; offset in framebuffer of the row that is actually refilled
ig_om_background_fill_column_offset:      rs.w       1                                                       ; offset in framebuffer of the column that is refilled next
ig_om_background_copperwait_split:        rs.l       1                                                       ; first word of copperwait command
; data files area
ig_om_datfile:                            rs.b       0                                                       ; variable filesizes, therefore this MUST be the last entry in this struct
ig_om_sizeof:                             rs.b       0

                                          endif                                                              ; ifnd INGAME_I
