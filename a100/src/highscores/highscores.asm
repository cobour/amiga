  ifnd       HIGHSCORES_ASM
HIGHSCORES_ASM equ 1

  include    "../a100/src/highscores/highscores.i"
  include    "../common/src/system/screen.i"

hs_start:
  bsr        .load_and_inflate_files
  tst.l      d0
  bne        .error

  SETPTRS

  bsr        .init_fade
  bsr        .init_screen_buffer_pointers
  bsr        .init_copper_list
  ; TODO copy front- to backbuffer
  bsr        ctrl_take_system
  bsr        .set_copper_list

  lea.l      hs_lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .init_music

.loop:
  bsr        .update_fade

  WAITVB

  btst       #6,$bfe001
  bne.s      .loop

  ; TODO: fade out music
  ; TODO: fade out colors
  bsr        _mt_end
  bsr        ctrl_free_system
  move.b     #NextPartMainmenu,c_om_next_part(a4)
  rts

.error:
  move.b     #NextPartExit,c_om_next_part(a4)
  rts

.load_and_inflate_files:
  move.l     #fn_highscores_other,d1
  move.l     #fn_highscores_chip,d2
  move.l     chip_mem_ptr(pc),d5
  add.l      #hs_cm_screenbuffer,d5
  move.l     d5,d6
  add.l      #512,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #hs_om_datfile,a0
  move.l     chip_mem_ptr(pc),a1
  add.l      #hs_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  rts

.init_screen_buffer_pointers:
  ; init pointers for both buffers
  move.l     #f002_gfx_highscores_screen,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      hs_cm_screenbuffer(a5),a1
  move.l     a0,hs_om_frontbuffer(a4)
  move.l     a1,hs_om_backbuffer(a4)
  rts

.init_copper_list:
; set bitplane pointers
  move.l     #f002_src_highscores_hs_copperlist,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a0,hs_om_copperlist(a4)
  move.l     a0,a1
  lea.l      hs_cm_cl_bitplanes(a0),a0
  move.l     hs_om_frontbuffer(a4),d0
  moveq.l    #HsScreenBitPlanes-1,d7
.icl1
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #HsScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl1
  rts

.set_copper_list
  move.l     #f002_src_highscores_hs_copperlist,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  move.w     #$0000,COPJMP1(a6)
  rts

.init_fade:
  move.l     #f003_gfx_highscores_screen_colors,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  lea.l      hs_om_fade_color_tab(a4),a0
  moveq.l    #32,d0
  moveq.l    #0,d1
  bra        fade_init                                ; indirect rts

.update_fade:
  move.l     hs_om_copperlist(a4),a0
  add.l      #hs_cm_cl_colors,a0
  bra        fade_next_step                           ; indirect rts

.init_music:
  move.l     #f002_music_spearhead_samples,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #f003_music_spearhead_mod,d0
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

hs_lvl3_irq_handler:
  movem.l    d0/a4-a6,-(sp)

  SETPTRS

  ; increment frame counter
  moveq.l    #1,d0
  add.l      d0,c_om_framecounter(a4)

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0/a4-a6
  rte

  endif                                               ; ifnd HIGHSCORES_ASM
