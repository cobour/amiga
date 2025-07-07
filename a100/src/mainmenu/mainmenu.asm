  ifnd        MAINMENU_ASM
MAINMENU_ASM equ 1

  include     "../a100/src/mainmenu/mainmenu.i"
  include     "../common/src/system/screen.i"
  include     "../common/src/system/blitter.i"

mm_start:
  bsr         .load_and_inflate_files
  tst.l       d0
  bne         .error

  bsr         .load_highscores
  tst.l       d0
  bne         .error

  bsr         .load_savegame
  tst.l       d0
  bne         .error

  WAITVB2
  SETPTRS

  bsr         .init_vars                                                                               ; must be called first -=> savegame data is loaded at a5+mm_cm_screenbuffer
  bsr         .init_fade
  bsr         .init_screen_buffer_pointers
  bsr         .init_screen_buffers
  bsr         .init_restore_buffer
  bsr         mm_clear_text_print_buffer                                                               ; must be called after .init_restore_buffer
  bsr         mp_init                                                                                  ; must be called after .init_screen_buffer_pointers, .init_screen_buffers, .init_restore_buffer and mm_clear_text_print_buffer (because draws to printbuffer and screenbuffer)
  bsr         .init_copper_list
  bsr         sfx_mm_init
  bsr         ev_init
  bsr         ctrl_take_system
  lea.l       mm_lvl3_irq_handler(pc),a0
  bsr         ctrl_set_handler
  bsr         keyboard_init
  bsr         .set_copper_list
  bsr         .init_music
  clr.b       c_om_end_of_frame(a4)

.loop:
  bsr         .update_fade
  bsr         mp_update
  bsr         ev_check
  bsr         mp_process_events

  WAITEOF
  bsr         .swap_buffers

  tst.b       mm_om_end_countdown(a4)
  blt.s       .loop
  bsr         .fade_out_music
  sub.b       #1,mm_om_end_countdown(a4)
  tst.b       mm_om_end_countdown(a4)
  bgt.s       .loop

  bsr         keyboard_cleanup
  bsr         _mt_end
  bsr         ctrl_free_system
  WAITVB2
  rts

.error:
  move.b      #NextPartExit,c_om_next_part(a4)
  rts

.load_and_inflate_files:
  move.l      #fn_mainmenu_other,d1
  move.l      #fn_mainmenu_chip,d2
  move.l      chip_mem_ptr(pc),d5
  add.l       #mm_cm_screenbuffer,d5
  move.l      d5,d6
  add.l       #512,d6
  move.l      other_mem_ptr(pc),a0
  add.l       #mm_om_datfile,a0
  move.l      chip_mem_ptr(pc),a1
  add.l       #mm_cm_datfile,a1
  bsr         datafiles_load_and_unzip
  rts

.load_highscores:

  move.l      other_mem_ptr(pc),a4
  bsr         disk_begin_io
  tst.l       d0
  bne.s       .lh_exit

  move.l      other_mem_ptr(pc),a2
  add.l       #mm_om_highscore_data,a2
  move.l      chip_mem_ptr(pc),a3
  add.l       #mm_cm_screenbuffer,a3
  move.l      #fn_highscores,d4
  bsr         disk_read_file
  tst.l       d0
  bne.s       .lh_exit

  bsr         disk_end_io
.lh_exit:
  rts

.load_savegame:
  move.l      chip_mem_ptr(pc),a2
  add.l       #mm_cm_screenbuffer,a2
  move.l      chip_mem_ptr(pc),a3
  add.l       #mm_cm_screenbuffer+sg_data_sizeof,a3
  bsr         sg_load
  rts

.init_vars:
  ; is savegame used?
  move.l      a5,a3
  add.l       #mm_cm_screenbuffer,a3
  bsr         sg_is_used
  lea.l       mm_om_savegame_is_used(a4),a0
  tst.l       d0
  beq.s       .save_not_used
  move.b      #1,(a0)
  bra.s       .after_is_savegame_used
.save_not_used:
  clr.b       (a0)
.after_is_savegame_used:

  move.b      #-1,mm_om_end_countdown(a4)
  rts

.init_screen_buffer_pointers:
  ; init pointers for both buffers
  move.l      #f004_gfx_mainmenu_screen_3b,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a0
  lea.l       mm_cm_screenbuffer(a5),a1
  move.l      a0,mm_om_frontbuffer(a4)
  move.l      a1,mm_om_backbuffer(a4)
  rts

.init_screen_buffers:
  ; copy screen-image from buffer in loaded file to empty buffer
  move.l      mm_om_frontbuffer(a4),a0
  move.l      mm_om_backbuffer(a4),a1
  move.w      #((MmScreenWidthBytes*MmScreenHeight*MmScreenBitPlanes)/2)-1,d7
.isb_loop:
  move.w      (a0)+,(a1)+
  dbf         d7,.isb_loop
  rts

.init_copper_list:
; set bitplane pointers
  move.l      #f004_src_mainmenu_mm_copperlist,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a0
  move.l      a0,mm_om_copperlist(a4)
  move.l      a0,a1
  lea.l       mm_cm_cl_bitplanes(a0),a0
  move.l      mm_om_frontbuffer(a4),d0
  moveq.l     #MmScreenBitPlanes-1,d7
.icl1
  move.w      d0,6(a0)
  swap        d0
  move.w      d0,2(a0)
  swap        d0
  add.l       #MmScreenWidthBytes,d0
  addq.l      #8,a0
  dbf         d7,.icl1
  rts

.set_copper_list
  move.l      mm_om_copperlist(a4),a0
  move.l      a0,COP1LC(a6)
  move.w      #$0000,COPJMP1(a6)
  rts

.init_music:
  move.l      #f004_music_space_odyssey_samples,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a1
  move.l      #f005_music_space_odyssey_mod,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a0
  moveq.l     #0,d0
  bsr         _mt_init
  move.w      #32,d0
  move.w      d0,mm_om_music_volume(a4)
  bsr         _mt_mastervol
  lea.l       _mt_Enable(pc),a0
  move.b      #1,(a0)
  rts

.init_fade:
  move.l      #f005_gfx_mainmenu_screen_3b_colors,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a1
  lea.l       mm_om_fade_color_tab(a4),a0
  moveq.l     #32,d0
  moveq.l     #0,d1
  bra         fade_init                                                                                ; indirect rts

.update_fade:
  move.l      mm_om_copperlist(a4),a0
  add.l       #mm_cm_cl_colors,a0
  bra         fade_next_step                                                                           ; indirect rts

.swap_buffers:
  ; swap pointers
  move.l      mm_om_backbuffer(a4),d0
  move.l      mm_om_frontbuffer(a4),d1
  move.l      d0,mm_om_frontbuffer(a4)
  move.l      d1,mm_om_backbuffer(a4)

  ; update copperlist
  move.l      mm_om_copperlist(a4),a0
  lea.l       mm_cm_cl_bitplanes(a0),a0
  moveq.l     #MmScreenBitPlanes-1,d7
.sb_loop:
  move.w      d0,6(a0)
  swap        d0
  move.w      d0,2(a0)
  swap        d0
  add.l       #MmScreenWidthBytes,d0
  addq.l      #8,a0
  dbf         d7,.sb_loop
  rts

.fade_out_music:
  sub.w       #1,mm_om_music_volume(a4)
  move.w      mm_om_music_volume(a4),d0
  tst.w       d0
  bge.s       .fom_0
  moveq.l     #0,d0
.fom_0:
  bsr         _mt_mastervol
  rts

.init_restore_buffer:
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                                                           ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                                                                ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #MmScreenWidthBytes-32,BLTAMOD(a6)                                                       ; modulos for source and target
  clr.w       BLTDMOD(a6)
  move.l      a5,a2
  add.l       #mm_cm_textarea_restore_buffer,a2                                                        ; pointers
  move.l      a2,BLTDPTH(a6)
  move.l      mm_om_backbuffer(a4),a2
  add.l       #MmOffsetOfTextArea,a2
  move.l      a2,BLTAPTH(a6)
  move.w      #(MmTextAreaBufferHeight*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords,BLTSIZE(a6)    ; start blit
  rts

mm_clear_text_print_buffer:
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                                                           ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                                                                ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  moveq.l     #0,d0                                                                                    ; modulos for source and target
  move.w      d0,BLTAMOD(a6)
  move.w      d0,BLTDMOD(a6)
  move.l      a5,a0                                                                                    ; pointers
  add.l       #mm_cm_textarea_restore_buffer,a0
  move.l      a0,BLTAPTH(a6)
  move.l      a5,a0
  add.l       #mm_cm_textarea_print_buffer,a0
  move.l      a0,BLTDPTH(a6)
  move.w      #(MmTextAreaBufferHeight*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords,BLTSIZE(a6)    ; start blit
  rts

; in:
;   d1 - offset of line in restore buffer
mm_clear_text_print_buffer_line:
  move.l      d0,-(sp)
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                                                           ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                                                                ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  moveq.l     #0,d0                                                                                    ; modulos for source and target
  move.w      d0,BLTAMOD(a6)
  move.w      d0,BLTDMOD(a6)
  move.l      a5,d0                                                                                    ; pointers
  add.l       #mm_cm_textarea_restore_buffer,d0
  add.l       d1,d0
  move.l      d0,BLTAPTH(a6)
  move.l      a5,d0
  add.l       #mm_cm_textarea_print_buffer,d0
  add.l       d1,d0
  move.l      d0,BLTDPTH(a6)
  move.w      #(16*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords,BLTSIZE(a6)                        ; start blit
  move.l      (sp)+,d0
  rts

mm_lvl3_irq_handler:
  movem.l     d0/a4-a6,-(sp)

  SETPTRS

  ; increment frame counter
  moveq.l     #1,d0
  add.l       d0,c_om_framecounter(a4)
  add.b       d0,c_om_end_of_frame(a4)

  ; clear Copper-IRQ-Bit
  move.w      #%0000000000010000,INTREQ(a6)

  movem.l     (sp)+,d0/a4-a6
  rte

  endif                                                                                                ; ifnd MAINMENU_ASM
