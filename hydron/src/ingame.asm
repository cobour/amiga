  ifnd       INGAME_ASM
INGAME_ASM equ 1

  include    "src/ingame.i"
  include    "../common/src/system/screen.i"

; called by loader when system is not yet taken
; a4 - other mem pointer
; a5 - chip mem pointer
ig_start:

; load and inflate files
  bsr        .load_datafiles
  tst.l      d0
  bne        .error

  SETPTRS

  ; REMOVE ME - test values
  move.b     #$03,c_om_lives(a4)
  move.l     #$012345,c_om_score(a4)
  move.l     #$123456,c_om_hiscore(a4)
  ; REMOVE ME - test values

  clr.b      ig_om_end_mainloop(a4)
  clr.b      ig_om_trigger_fade_out_countdown(a4)

  bsr        buffers_init                               ; MUST be called FIRST, because sets vars needed by other inits
  bsr        panel_init
  bsr        player_init
  bsr        background_init
  bsr        fade_ingame_init
  bsr        bob_init
  bsr        enemies_init
  bsr        explosions_init
  bsr        ctrl_take_system
  bsr        .init_music

.main_loop:
  tst.b      ig_om_end_mainloop(a4)
  bne.s      .exit

  tst.b      ig_om_trigger_fade_out_countdown(a4)
  beq.s      .end_fade_out_countdown
  sub.b      #1,ig_om_trigger_fade_out_countdown(a4)
  tst.b      ig_om_trigger_fade_out_countdown(a4)
  bgt.s      .end_fade_out_countdown
  bsr        fade_ingame_start_fade_out
.end_fade_out_countdown:

  bsr        buffers_set_pointers

  bsr        fade_ingame_update
  bsr        player_update
  bsr        player_weapon_update
  bsr        panel_update
  bsr        enemies_update
  bsr        background_update                          ; MUST be called before any update-routines that modify the bitplanes
  bsr        bob_update
  bsr        explosions_update

  bsr        coll_player_enemies

  bsr        player_and_weapon_draw
  bsr        explosions_restore
  bsr        enemies_restore
  bsr        explosions_draw
  bsr        enemies_draw

  ifd        RED_TIMING
  move.w     #$0f00,COLOR00(a6)                         ; end of preparation of next frame
  endif                                                 ; ifd RED_TIMING

  ; check position of vertical beam, MUST be below visible area
.wait_for_beam:
  move.l     VPOSR(a6),d0
  and.l      #$0001ff00,d0
  cmp.l      #$00012b00,d0
  ble.s      .wait_for_beam
  ; swap buffers
  bsr        buffers_swap

  bra.s      .main_loop

.exit:
  bsr        buffers_clear
  bsr        _mt_end

.error:
  rts

.init_music:
  move.l     #"MODS",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #"MODP",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  moveq.l    #0,d0
  bsr        _mt_init
  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)
  rts

.load_datafiles:
  move.l     #"F101",d1                                 ; TODO: table with level number -> file id
  move.l     chip_mem_ptr(pc),d6
  add.l      #ig_cm_framebuffer_one+15000,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #ig_om_datfile,a0
  move.l     chip_mem_ptr(pc),d7
  add.l      #ig_cm_framebuffer_one,d7
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bra        datafiles_load_and_unzip                   ; implicit rts

  endif                                                 ; ifnd INGAME_ASM
