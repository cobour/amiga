  ifnd       MAINMENU_ASM
MAINMENU_ASM equ 1

  include    "../a100/src/mainmenu/mainmenu.i"
  include    "../common/src/system/screen.i"

mm_start:
  bsr        .load_and_inflate_files
  tst.l      d0
  bne        .error

  SETPTRS

  bsr        ctrl_take_system
  bsr        .set_copper_list

  lea.l      mm_lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .init_music

.loop:
  btst       #6,$bfe001
  bne.s      .loop

  ; TODO: fade out music
  bsr        _mt_end
  bsr        ctrl_free_system
  move.b     #GameModeSpeedRun,c_om_gamemode(a4)     ; for testing
  move.b     #NextPartIngame,c_om_next_part(a4)      ; or NextPartExit
  rts

.error:
  move.b     #NextPartExit,c_om_next_part(a4)
  rts

.load_and_inflate_files:
  move.l     #fn_mainmenu_other,d1
  move.l     #fn_mainmenu_chip,d2
  move.l     chip_mem_ptr(pc),d5
  add.l      #mm_cm_screenbuffer,d5
  move.l     d5,d6
  add.l      #512,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #mm_om_datfile,a0
  move.l     chip_mem_ptr(pc),a1
  add.l      #mm_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  rts

.set_copper_list
  move.l     #f004_src_mainmenu_mm_copperlist,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  move.w     #$0000,COPJMP1(a6)
  rts

.init_music:
  move.l     #f004_music_space_odyssey_samples,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #f005_music_space_odyssey_mod,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  moveq.l    #0,d0
  bsr        _mt_init
  move.w     #32,d0
  move.w     d0,ig_om_music_volume(a4)
  bsr        _mt_mastervol
  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)
  rts

mm_lvl3_irq_handler:
  movem.l    d0/a4-a6,-(sp)

  SETPTRS

  ; increment frame counter
  moveq.l    #1,d0
  add.l      d0,c_om_framecounter(a4)

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0/a4-a6
  rte

  endif                                              ; ifnd MAINMENU_ASM
