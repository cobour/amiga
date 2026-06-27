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

  ; init TEST bob
  lea.l      ig_om_enemies(a4),a1
  move.w     #1,bob_status(a1)
  move.l     #"TEST",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,bob_data_pointer(a1)
  lea.l      df_idx_metadata(a0),a0
  add.l      df_iff_rawsize(a0),d0
  move.l     d0,bob_mask_pointer(a1)
  move.w     df_iff_width(a0),bob_width(a1)
  move.w     df_iff_height(a0),bob_height(a1)
  move.w     #2,bob_width_words(a1)
  move.w     #32*6,bob_height_blt(a1)
  move.l     #$00700000,bob_xpos(a1)
  move.l     #$00700000,bob_ypos(a1)
  move.w     #$0000,bob_src_mod_no_shift(a1)
  move.w     #-2,bob_src_mod_shift(a1)
  move.w     #28,bob_trg_mod_no_shift(a1)
  move.w     #26,bob_trg_mod_shift(a1)

  rts

enemies_update:
  ; do not move right now
  rts

enemies_restore:
  move.l     ig_om_bob_targetbuffer(a4),a1               ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                   ; base pointer of source buffer

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
  move.l     ig_om_bob_targetbuffer(a4),a1               ; base pointer of target buffer
  move.l     ig_om_buffer_three(a4),a2                   ; base pointer of source buffer

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

  endif                                                  ; ifnd ENEMIES_ASM
