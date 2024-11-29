  ifnd       INGAME_ASM
INGAME_ASM equ 1

  include    "../a100/src/ingame/ingame.i"
  include    "../common/src/system/screen.i"

; called by loader when system is not yet taken
; a4 - other mem pointer
; a5 - chip mem pointer
ig_start:
  ; init stuff
  bsr        .load_and_inflate_files
  SETPTRS
  clr.l      ig_om_framecounter(a4)
  bsr        .init_screen_buffer_pointers
  bsr        playfield_init
  bsr        brick_selectors_init
  bsr        bricks_init
  bsr        brick_selectors_refill
  bsr        .init_screen_buffers
  bsr        .init_copper_list
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        keyboard_init
  bsr        .set_copper_list
  bsr        .init_music

.ig_loop:
  bsr        brick_selectors_draw

  ; ----------------- REMOVE ME -----------------
  ; read all available key codes
.1:
  bsr        keyboard_get_key
  ; play sample when S is pressed
  cmp.b      #$21,d0
  bne.s      .2

  move.l     #f000_sfx_enter,d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx

.2:
  tst.b      d0
  bge.s      .1
  ; ----------------- REMOVE ME -----------------

  WAITVB
  bsr.s      .swap_buffers
  btst       #6,$bfe001
  bne.s      .ig_loop

  bsr        _mt_end
  bsr        keyboard_cleanup

.error:
  rts

.swap_buffers:
  ; swap pointers
  move.l     ig_om_backbuffer(a4),d0
  move.l     ig_om_frontbuffer(a4),d1
  move.l     d0,ig_om_frontbuffer(a4)
  move.l     d1,ig_om_backbuffer(a4)

  ; update copperlist
  move.l     ig_om_copperlist(a4),a0
  lea.l      ig_cm_cl_bitplanes(a0),a0
  moveq.l    #IgScreenBitPlanes-1,d7
.icl:
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl
  rts

.load_and_inflate_files:
  move.l     #fn_ingame_other,d1
  move.l     #fn_ingame_chip,d2
  move.l     chip_mem_ptr(pc),d5
  add.l      #ig_cm_screenbuffer,d5
  move.l     d5,d6
  add.l      #512,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #ig_om_datfile,a0
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  tst.l      d0
  bne.s      .error
  rts

.init_screen_buffer_pointers:
  ; init pointers for both buffers
  move.l     #f000_gfx_ingame_screen,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      ig_cm_screenbuffer(a5),a1
  move.l     a0,ig_om_frontbuffer(a4)
  move.l     a1,ig_om_backbuffer(a4)
  rts

.init_screen_buffers:
  ; copy screen-image from buffer in loaded file to empty buffer
  move.l     ig_om_frontbuffer(a4),a0
  move.l     ig_om_backbuffer(a4),a1
  move.w     #((IgScreenWidthBytes*IgScreenHeight*IgScreenBitPlanes)/2)-1,d7
.isb_loop:
  move.w     (a0)+,(a1)+
  dbf        d7,.isb_loop
  rts

.init_copper_list:
; set bitplane pointers
  move.l     #f000_src_ingame_copperlist,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a0,ig_om_copperlist(a4)
  move.l     a0,a1
  lea.l      ig_cm_cl_bitplanes(a0),a0
  move.l     ig_om_frontbuffer(a4),d0
  moveq.l    #IgScreenBitPlanes-1,d7
.icl1
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl1

; set colors
  move.l     #f001_gfx_ingame_screen_colors,d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a2
  moveq.l    #0,d7
  move.w     (a2),d7
  lsr.w      #1,d7
  subq.w     #1,d7
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      ig_cm_cl_colors+2(a1),a1
.icl2:
  move.w     (a0)+,(a1)
  addq.l     #4,a1
  dbf        d7,.icl2
  rts

.set_copper_list
  move.l     #f000_src_ingame_copperlist,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  move.w     #$0000,COPJMP1(a6)
  rts

.init_music:
  move.l     #f000_music_peace_of_mind_samples,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #f001_music_peace_of_mind_mod,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  moveq.l    #0,d0
  bsr        _mt_init
  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)
  rts

lvl3_irq_handler:
  movem.l    d0-d7/a0-a6,-(sp)

  SETPTRS

  ; increment frame counter
  moveq.l    #1,d0
  add.l      d0,ig_om_framecounter(a4)

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rte


  endif                                                                         ; ifnd INGAME_ASM
