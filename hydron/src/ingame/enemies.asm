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

  ; TESTCODE - test bob
  lea.l      ig_om_enemies(a4),a1
  lea.l      ig_om_bob_types(a4),a2
  move.l     a2,bob_bobtype_pointer(a1)
  move.w     #1,bob_status(a1)
  move.l     #$00700000,bob_xpos(a1)
  move.l     #$00700000,bob_ypos(a1)
  ; TESTCODE - test bob

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
