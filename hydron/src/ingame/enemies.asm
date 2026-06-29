  ifnd       ENEMIES_ASM
ENEMIES_ASM equ 1

  include    "src/ingame.i"

enemies_init:
  ; init enemy-structs
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
.init_structs_loop:
  bsr        bob_clear
  lea.l      bob_sizeof(a0),a0
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

  ; TESTCODE - test enemy
  ; TODO: when enemy-spawn info is read from tiled-file, ALL enemytype's and thus ALL bobtype's 
  ;       will be initialised here to avoid time-consuming pointer look-ups via datafiles_get_pointer
  ; init bobtype
  move.l     #"BT00",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     bobtype_gfx_id(a1),d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,bobtype_data_pointer(a1)
  lea.l      df_idx_metadata(a0),a0
  add.l      df_iff_rawsize(a0),d0
  move.l     d0,bobtype_mask_pointer(a1)
  ; init enemytype
  move.l     #"ET00",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a1,enemytype_bobtype_pointer(a0)
  ; spawn enemy
  move.l     #$00700000,d0
  move.l     #$00700000,d1
  bsr.s      enemies_spawn_new_enemy
  ; TESTCODE - test enemy

  rts

; in:
;   a0   - pointer to enemytype-struct
;   d0.l - xpos (fixed-point-value)
;   d1.l - ypos (fixed-point-value)
enemies_spawn_new_enemy:
  ; find empty spot
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemiesCount-1,d7
  moveq.l    #-1,d5
  moveq.l    #enemy_sizeof,d6
.find_empty_spot_loop:
  cmp.w      bob_status(a1),d5
  beq.s      .add_enemy
  add.l      d6,a1
  dbf        d7,.find_empty_spot_loop
  ; no empty spot found
  bra.s      .exit

.add_enemy:
  move.w     #1,bob_status(a1)
  move.l     d0,bob_xpos(a1)
  move.l     d1,bob_ypos(a1)
  move.l     a0,enemy_enemytype_pointer(a1)
  move.l     enemytype_bobtype_pointer(a0),bob_bobtype_pointer(a1)

.exit:
  rts

enemies_update:
  ; do not move right now
  rts

enemies_restore:
  move.l     ig_om_bob_targetbuffer(a4),a1                            ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                                ; base pointer of source buffer

  ; restore
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemiesCount-1,d7
  moveq.l    #0,d4
.restore_loop:
  bsr        bob_restore
  lea.l      bob_sizeof(a0),a0
  dbf        d7,.restore_loop
  rts

enemies_draw:
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
  lea.l      bob_sizeof(a0),a0
  dbf        d7,.draw_loop
  rts

  endif                                                               ; ifnd ENEMIES_ASM
