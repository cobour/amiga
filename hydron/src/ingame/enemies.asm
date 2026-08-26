  ifnd       ENEMIES_ASM
ENEMIES_ASM equ 1

  include    "src/ingame.i"

enemies_init:
  ; init enemy-structs
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.init_structs_loop:
  bsr        bob_clear
  clr.l      enemy_enemytype_pointer(a0)
  clr.l      enemy_bounding_box(a0)
  clr.l      enemy_bounding_box+4(a0)
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.init_structs_loop

  ; init ig_om_enemies_framebuffer_offsets
  lea.l      ig_om_enemies_framebuffer_offsets(a4),a0
  move.w     #IgScreenHeight-1,d7
  move.l     #IgScreenWidthBytes*IgScreenBitPlanes,d1
  moveq.l    #0,d0
.init_offsets_table_loop:
  move.l     d0,(a0)+
  add.l      d1,d0
  dbf        d7,.init_offsets_table_loop

  ; enemy spawn info
  move.l     #"MAPT",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  lea.l      df_idx_metadata(a0),a0
  move.l     df_tld_plf_rawsize(a0),d0
  move.l     df_tld_enm_rawsize(a0),d1
  add.l      d0,a1
  move.l     a1,ig_om_enemies_spawn_data_pointer(a4)
  add.l      d1,a1
  move.l     a1,ig_om_enemies_spawn_data_end_pointer(a4)

  ; init enemy spawn info / replace movement id with pointer
  move.l     ig_om_enemies_spawn_data_pointer(a4),a1
  move.l     ig_om_enemies_spawn_data_end_pointer(a4),d7
.init_spawn_info_loop:
  move.l     df_tld_enm_movement(a1),d0
  beq.s      .init_spawn_info_loop_next
  bsr        datafiles_get_pointer
  move.l     a0,df_tld_enm_movement(a1)
.init_spawn_info_loop_next:
  lea.l      df_tld_enm_sizeof(a1),a1
  cmp.l      a1,d7
  bne.s      .init_spawn_info_loop

  ; init enemytypes and bobtypes
  move.l     ig_om_enemies_spawn_data_pointer(a4),a1
  move.l     ig_om_enemies_spawn_data_end_pointer(a4),d7
.init_types_loop:
  cmp.l      a1,d7
  beq.s      .init_types_loop_end
  move.l     df_tld_enm_enemytype(a1),d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a2                                ; pointer to enemytype-struct
  move.l     a2,df_tld_enm_enemytype(a1)
  move.l     enemytype_bobtype_id(a2),d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a3                                ; pointer to bobtype-struct
  move.l     a3,enemytype_bobtype_pointer(a2)
  move.l     bobtype_gfx_id(a3),d0
  bsr        datafiles_get_pointer                                    ; pointer to gfx-struct
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,bobtype_data_pointer(a3)
  lea.l      df_idx_metadata(a0),a0
  add.l      df_iff_rawsize(a0),d0
  move.l     d0,bobtype_mask_pointer(a3)
  ; next
  lea.l      df_tld_enm_sizeof(a1),a1
  bra.s      .init_types_loop
.init_types_loop_end:

  ; first spawn check, maybe enemies are there at the very beginning
  bsr.s      enemies_spawn

  ; init finished
  rts

enemies_spawn:
  moveq.l    #0,d5
  move.l     ig_om_enemies_spawn_data_pointer(a4),a2
  move.l     ig_om_enemies_spawn_data_end_pointer(a4),d6
  cmp.l      d6,a2
  beq.s      .no_more_spawns

.spawn_loop:
  ; check for spawns to process
  move.l     df_tld_enm_level_ypos(a2),d0
  cmp.l      ig_om_background_level_ypos(a4),d0
  blt.s      .no_more_spawns

  ; find empty spot
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemiesCount-1,d7
  moveq.l    #-1,d0
.find_empty_spot_loop:
  cmp.w      bob_status(a1),d0
  beq.s      .add_enemy
  lea.l      enemy_sizeof(a1),a1
  dbf        d7,.find_empty_spot_loop
  ; no empty spot found
  bra.s      .no_more_spawns

.add_enemy:
  move.w     #BobStatusActive,bob_status(a1)
  move.l     df_tld_enm_xpos(a2),bob_xpos(a1)
  move.l     df_tld_enm_ypos(a2),bob_ypos(a1)
  move.l     df_tld_enm_enemytype(a2),a0
  move.l     a0,enemy_enemytype_pointer(a1)
  move.l     enemytype_bobtype_pointer(a0),bob_bobtype_pointer(a1)
  clr.l      enemy_move_next_step(a1)
  move.l     df_tld_enm_movement(a2),a0
  cmp.l      d5,a0                                                    ; d5 = zero
  beq.s      .next_spawn_info
  move.l     df_idx_ptr_rawdata(a0),a3
  move.l     a3,enemy_move_next_step(a1)
  add.l      df_idx_metadata+df_svgp_size(a0),a3
  move.l     a3,enemy_move_end_of_table(a1)

.next_spawn_info:
  lea.l      df_tld_enm_sizeof(a2),a2
  cmp.l      a2,d6
  bne.s      .spawn_loop

.no_more_spawns:
  move.l     a2,ig_om_enemies_spawn_data_pointer(a4)
  rts

enemies_update:
  bsr.s      enemies_spawn
  bsr.s      enemies_move
  rts

enemies_move:
  ; move enemies
  moveq.l    #0,d5
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.move_loop:
  tst.w      bob_status(a0)
  blt.s      .move_loop_next
  move.l     enemy_move_next_step(a0),a1
  cmp.l      d5,a1                                                    ; d5 = zero
  beq.s      .move_loop_next
  ; apply step
  move.l     df_svgp_step_xpos_add(a1),d0
  move.l     df_svgp_step_ypos_add(a1),d1
  move.w     df_svgp_step_direction(a1),d2
  move.l     bob_bobtype_pointer(a0),a3
  move.w     bobtype_width_shift(a3),d3
  lsl.w      d3,d2
  add.l      d0,bob_xpos(a0)
  add.l      d1,bob_ypos(a0)
  move.w     d2,bob_anim_offset+2(a0)
  ; update bounding box
  move.l     enemy_enemytype_pointer(a0),a2
  lea.l      enemytype_bounding_box(a2),a2
  move.w     (a2)+,d0
  move.w     (a2)+,d1
  move.w     (a2)+,d2
  move.w     (a2),d3
  move.w     bob_xpos(a0),d6
  add.w      d6,d0
  add.w      d6,d2
  move.w     bob_ypos(a0),d6
  add.w      d6,d1
  add.w      d6,d3
  lea.l      enemy_bounding_box(a0),a2
  move.w     d0,(a2)+
  move.w     d1,(a2)+
  move.w     d2,(a2)+
  move.w     d3,(a2)
  ; switch to next step (or stay at last step)
  lea.l      df_svgp_step_sizeof(a1),a1
  cmp.l      enemy_move_end_of_table(a0),a1
  beq.s      .move_loop_end_of_table
  move.l     a1,enemy_move_next_step(a0)
  bra.s      .move_loop_next
.move_loop_end_of_table:
  ; check if bob is no longer drawn, means it exited the visible screen, means it can be removed
  move.w     bob_restore_1a+bob_restore_bltsize(a0),d0
  swap       d0
  move.w     bob_restore_2a+bob_restore_bltsize(a0),d0
  tst.l      d0
  bne.s      .move_loop_next
  ; remove enemy/bob
  bsr        bob_clear_quick
.move_loop_next:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.move_loop

  rts

enemies_restore:
  move.l     ig_om_bob_targetbuffer(a4),a1                            ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                                ; base pointer of source buffer

  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.restore_loop:
  tst.w      bob_status(a0)
  blt.s      .do_not_restore
  bsr        bob_restore
.do_not_restore:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.restore_loop
  rts

enemies_draw:
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.draw_loop:
  tst.w      bob_status(a0)
  ble.s      .do_not_draw
  bsr        bob_draw
.do_not_draw:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.draw_loop

  move.l     chip_mem_ptr(pc),a5
  rts

  endif                                                               ; ifnd ENEMIES_ASM
