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
  move.b     #$05,c_om_lives(a4)
  move.l     #$012345,c_om_score(a4)
  move.l     #$123456,c_om_hiscore(a4)
  ;
  move.l     #"EM01",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  ; REMOVE ME - test values

  clr.b      c_om_next_frame_ready(a4)
  clr.b      c_om_vbl(a4)
  clr.b      ig_om_end_mainloop(a4)

  bsr        buffers_init                       ; MUST be called FIRST, because sets vars needed by other inits
  bsr        panel_init
  bsr        player_init
  bsr        background_init
  bsr        fade_ingame_init
  bsr        enemies_init
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .init_music

.main_loop:
  clr.b      c_om_next_frame_ready(a4)

  tst.b      ig_om_end_mainloop(a4)
  bne.s      .exit

  bsr        buffers_set_pointers

  bsr        fade_ingame_update
  bsr        player_update                      ; TODO: only update of position and fire new bullets
  bsr        panel_update
  bsr        enemies_update
  bsr        background_update                  ; MUST be called before any update-routines that modify the bitplanes

  bsr        enemies_restore
  bsr        enemies_draw

  move.b     #1,c_om_next_frame_ready(a4)
  clr.b      c_om_vbl(a4)
  ifd        RED_TIMING
  move.w     #$0f00,COLOR00(a6)                 ; end of preparation of next frame
  endif                                         ; ifd RED_TIMING
.ml_wait_vbl:
  tst.b      c_om_vbl(a4)
  beq.s      .ml_wait_vbl

  ; TEST CODE - fade out on mouse click
  lea.l      .is_fade_out(pc),a0
  tst.w      (a0)
  bne.s      .end_fade_out
  btst       #6,$bfe001
  bne.s      .end_fade_out
  bsr        fade_ingame_start_fade_out
  lea.l      .is_fade_out(pc),a0
  move.w     #1,(a0)
  bra.s      .end_fade_out
.is_fade_out:
  dc.w       0
.end_fade_out:
  ; TEST CODE - fade out on mouse click

  bra.s      .main_loop

.exit:
  clr.b      c_om_next_frame_ready(a4)
  bsr        buffers_clear
  bsr        _mt_end

.error:
  rts

.init_music:
  move.l     #"MS02",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #"MP02",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  moveq.l    #0,d0
  bsr        _mt_init
  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)
  rts

.load_datafiles:
  move.l     #"F101",d1
  move.l     chip_mem_ptr(pc),d6
  add.l      #ig_cm_framebuffer_one+15000,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #ig_om_datfile,a0
  move.l     chip_mem_ptr(pc),d7
  add.l      #ig_cm_framebuffer_one,d7
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bra        datafiles_load_and_unzip           ; implicit rts

lvl3_irq_handler:
  movem.l    a4/a6,-(sp)
  lea.l      CUSTOM,a6
  move.l     other_mem_ptr(pc),a4

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  ; set vbl flag in common om struct
  move.b     #1,c_om_vbl(a4)

  ; is end-of-mainloog trigger set?
  tst.b      ig_om_end_mainloop(a4)
  bne.s      .exit

  ; is frame rendered completely into backbuffer?
  tst.b      c_om_next_frame_ready(a4)
  beq.s      .exit

  ; swap buffers
  bsr        buffers_swap

.exit:
  movem.l    (sp)+,a4/a6
  rte


  endif                                         ; ifnd INGAME_ASM
