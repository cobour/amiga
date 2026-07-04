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

  ; init enemytypes and bobtypes
  move.l     ig_om_enemies_spawn_data_pointer(a4),a1
  move.l     ig_om_enemies_spawn_data_end_pointer(a4),d7
.init_types_loop:
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
  cmp.l      a1,d7
  bne.s      .init_types_loop

  ; first spawn check, maybe enemies are there at the very beginning
  bsr.s      enemies_spawn

  ; init finished
  rts

enemies_spawn:
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
  move.w     #1,bob_status(a1)
  move.l     df_tld_enm_xpos(a2),bob_xpos(a1)
  move.l     df_tld_enm_ypos(a2),bob_ypos(a1)
  move.l     df_tld_enm_enemytype(a2),a0
  move.l     a0,enemy_enemytype_pointer(a1)
  move.l     enemytype_bobtype_pointer(a0),bob_bobtype_pointer(a1)

  ; next spawn info
  lea.l      df_tld_enm_sizeof(a2),a2
  cmp.l      a2,d6
  bne.s      .spawn_loop

.no_more_spawns:
  move.l     a2,ig_om_enemies_spawn_data_pointer(a4)
  rts

enemies_update:
  bsr.s      enemies_spawn
  ; do not move right now
  rts

enemies_restore:
  move.l     ig_om_bob_targetbuffer(a4),a1                            ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                                ; base pointer of source buffer

  ; restore
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.restore_loop:
  bsr        bob_restore
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.restore_loop
  rts

enemies_draw:
  move.l     a5,-(sp)
  move.l     ig_om_bob_targetbuffer(a4),a1                            ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                                ; base pointer of source buffer

  ; draw
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.draw_loop:
  tst.w      bob_status(a0)
  ble.s      .do_not_draw
  bsr        bob_draw
.do_not_draw:
  lea.l      enemy_sizeof(a0),a0
  dbf        d7,.draw_loop

  move.l     (sp)+,a5
  rts

  endif                                                               ; ifnd ENEMIES_ASM
