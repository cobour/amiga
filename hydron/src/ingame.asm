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
  ; REMOVE ME - test values

  bsr        buffers_init                       ; MUST be called FIRST, because sets vars needed by other inits
  bsr        panel_init
  bsr        player_init
  bsr        player_update                      ; update here once => init sprite data
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .init_music

.main_loop:
  clr.b      c_om_vbl(a4)
  bsr        player_update
  bsr        panel_update
.ml_wait_vbl:
  tst.b      c_om_vbl(a4)
  beq.s      .ml_wait_vbl
  bsr        buffers_swap
  ; for now: quit on mouse click
  btst       #6,$bfe001
  bne.s      .main_loop

  bsr        _mt_end
  bsr        ctrl_set_black_screen

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

  ; clear Copper-IRQ-Bit
  lea.l      CUSTOM,a6
  move.w     #%0000000000010000,INTREQ(a6)

  ; set vbl flag in common om struct
  move.l     other_mem_ptr(pc),a4
  move.b     #1,c_om_vbl(a4)

  movem.l    (sp)+,a4/a6
  rte


  endif                                         ; ifnd INGAME_ASM
