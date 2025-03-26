  ifnd       HIGHSCORES_ASM
HIGHSCORES_ASM equ 1

  include    "../a100/src/highscores/highscores.i"
  include    "../common/src/system/screen.i"

hs_start:
  bsr        .load_and_inflate_files
  tst.l      d0
  bne        .error
  bsr        .load_highscores
  tst.l      d0
  bne        .error

  SETPTRS

  bsr        .init_vars
  bsr        .init_fade
  bsr        .init_screen_buffer_pointers
  bsr        .init_screen_buffers
  bsr        .init_copper_list
  bsr        .init_viewed_data
  bsr        sfx_highscores_init
  bsr        ev_init
  bsr        ctrl_take_system
  lea.l      hs_lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        keyboard_init
  bsr        .set_copper_list
  bsr        .init_music

.loop:
  bsr        .update_fade
  bsr        hs_view_draw
  bsr        ev_check
  bsr        hs_process_events

  WAITVB
  bsr        .swap_buffers

  tst.b      hs_om_end_countdown(a4)
  blt.s      .loop
  bsr        .fade_out_music
  sub.b      #1,hs_om_end_countdown(a4)
  tst.b      hs_om_end_countdown(a4)
  bgt.s      .loop

  bsr        keyboard_cleanup
  bsr        _mt_end
  bsr        ctrl_free_system
  bsr        .save_highscores
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

.load_highscores:
  move.l     other_mem_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .lh_exit

  move.l     other_mem_ptr(pc),a2
  add.l      #hs_om_highscore_data,a2
  move.l     chip_mem_ptr(pc),a3
  add.l      #hs_cm_screenbuffer,a3
  move.l     #fn_highscores,d4
  bsr        disk_read_file
  tst.l      d0
  bne.s      .lh_exit

  bsr        disk_end_io
.lh_exit
  rts

.save_highscores:
  tst.b      hs_om_save_on_exit(a4)
  beq.s      .sh_exit

  move.l     other_mem_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .sh_exit

  moveq.l    #h000_unzipped_filesize,d7
  move.l     #fn_highscores,d4
  move.l     other_mem_ptr(pc),a2
  add.l      #hs_om_highscore_data,a2
  move.l     chip_mem_ptr(pc),a3
  add.l      #hs_cm_screenbuffer,a3
  bsr        disk_write_file
  tst.l      d0
  bne.s      .sh_exit

  bsr        disk_end_io
.sh_exit
  rts

.init_vars:
  move.b     #-1,hs_om_end_countdown(a4)
  clr.b      hs_om_save_on_exit(a4)
  rts

.init_viewed_data:
  bsr        hs_view_save_background

  ; TODO: decide if players score is in highscore table or not
  ;       here - it's not
  ; is score is to be added to table, move the lower scores and insert players score with empty name => in hs_om_highscore_data(a4)
  ; also set the save-flag => hs_om_save_on_exit(a4)
  move.b     #HsViewScreenYourScore,hs_om_view_screen(a4)
  moveq.l    #0,d1
  bsr        hs_view_init
  rts

.init_screen_buffers:
  ; copy screen-image from buffer in loaded file to empty buffer
  move.l     hs_om_frontbuffer(a4),a0
  move.l     hs_om_backbuffer(a4),a1
  move.w     #((HsScreenWidthBytes*HsScreenHeight*HsScreenBitPlanes)/2)-1,d7
.isb_loop:
  move.w     (a0)+,(a1)+
  dbf        d7,.isb_loop
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

.swap_buffers:
  ; swap pointers
  move.l     hs_om_backbuffer(a4),d0
  move.l     hs_om_frontbuffer(a4),d1
  move.l     d0,hs_om_frontbuffer(a4)
  move.l     d1,hs_om_backbuffer(a4)

  ; update copperlist
  move.l     hs_om_copperlist(a4),a0
  lea.l      hs_cm_cl_bitplanes(a0),a0
  moveq.l    #HsScreenBitPlanes-1,d7
.sb_loop:
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #HsScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.sb_loop
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
  bra        fade_init                                                          ; indirect rts

.update_fade:
  move.l     hs_om_copperlist(a4),a0
  add.l      #hs_cm_cl_colors,a0
  bra        fade_next_step                                                     ; indirect rts

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
  move.w     d0,hs_om_music_volume(a4)
  bsr        _mt_mastervol
  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)
  rts

.fade_out_music:
  sub.w      #1,hs_om_music_volume(a4)
  move.w     hs_om_music_volume(a4),d0
  tst.w      d0
  bge.s      .fom_0
  moveq.l    #0,d0
.fom_0:
  bsr        _mt_mastervol
  rts

hs_process_events:
  tst.b      hs_om_end_countdown(a4)
  bge.s      .exit

.process_event:
  bsr        ev_get_next_event
  tst.b      d0
  blt        .exit

.pe_select:
  cmp.b      #EventSelect,d0
  bne.s      .pe_other
  bsr.s      .pe_handle_select

.pe_other:
  ; ignore all other events
  bra.s      .process_event

.exit:
  rts

.pe_handle_select:
  cmp.b      #HsViewScreenYourScore,hs_om_view_screen(a4)
  beq.s      .pehs_switch_to_table
  move.b     #35,hs_om_end_countdown(a4)
  move.l     #f003_gfx_highscores_screen_colors,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  lea.l      hs_om_fade_color_tab(a4),a0
  moveq.l    #32,d0
  moveq.l    #1,d1
  bra        fade_init                                                          ; implicit rts
.pehs_switch_to_table:
  move.b     #HsViewScreenHighScoreTable,hs_om_view_screen(a4)
  moveq.l    #1,d1
  bra        hs_view_init                                                       ; implicit rts

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

  endif                                                                         ; ifnd HIGHSCORES_ASM
