  ifnd       INGAME_BUFFERS_ASM
INGAME_BUFFERS_ASM equ 1

  include    "src/ingame.i"

buffers_init:
  clr.l      ig_om_buffers_framecount(a4)

  ; framebuffer pointers
  move.l     a5,a0
  add.l      #ig_cm_framebuffer_one,a0
  move.l     a0,ig_om_buffer_one+ig_buffers_framebuffer_pointer(a4)
  bsr.s      .clear_framebuffer
  move.l     a5,a0
  add.l      #ig_cm_framebuffer_two,a0
  move.l     a0,ig_om_buffer_two+ig_buffers_framebuffer_pointer(a4)
  bsr.s      .clear_framebuffer
  move.l     a5,a0
  add.l      #ig_cm_framebuffer_three,a0
  move.l     a0,ig_om_buffer_three(a4)                                                    ; just framebuffer pointer
  bsr.s      .clear_framebuffer

  ; copperlist vars
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_buffer_one+ig_buffers_copperlist_pointer(a4)
  lea.l      ig_cm_copperlist(a5),a0
  move.l     a0,ig_om_buffer_two+ig_buffers_copperlist_pointer(a4)

  ; sprites vars
  lea.l      ig_cm_player_sprites_buffer_0(a5),a0
  move.l     a0,ig_om_buffer_one+ig_buffers_sprites_pointer(a4)
  lea.l      ig_cm_player_sprites_buffer_1(a5),a0
  move.l     a0,ig_om_buffer_two+ig_buffers_sprites_pointer(a4)

  ; copperlists
  bsr.s      .copy_copperlist
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a2
  move.l     ig_om_buffer_one+ig_buffers_framebuffer_pointer(a4),d0
  bsr.s      .init_bitplane_pointers
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a2
  move.l     ig_om_buffer_two+ig_buffers_framebuffer_pointer(a4),d0
  bsr.s      .init_bitplane_pointers
  bra.s      .set_copper_list                                                             ; implicit rts

.copy_copperlist
  movem.l    a0-a1/d7,-(sp)
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a0
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a1
  move.w     #(ig_cm_cl_sizeof/4)-1,d7
.ccl_loop:
  move.l     (a0)+,(a1)+
  dbf        d7,.ccl_loop
  movem.l    (sp)+,a0-a1/d7
  rts

; in:
;   a0 - pointer to framebuffer
.clear_framebuffer:
  move.w     #(IgFrameBufferSize/2)-1,d7
.clear_framebuffer_loop:
  clr.w      (a0)+
  dbf        d7,.clear_framebuffer_loop
  rts

; in:
;   a2 - pointer to copperlist
;   d0 - pointer to framebuffer to be shown
.init_bitplane_pointers:
  add.l      #IgScreenWidthBytes*32*IgScreenBitPlanes,d0
  move.l     a2,a0
  lea.l      ig_cm_cl_bitplanes(a0),a0
  moveq.l    #IgScreenBitPlanes-1,d7
.icl1
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl1
  rts

.set_copper_list
  movem.l    d0/a0,-(sp)
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a0
  move.l     a0,COP1LC(a6)
  move.w     #$0000,COPJMP1(a6)
  movem.l    (sp)+,d0/a0
  rts

; in:
;   a2 - pointer to copperlist
buffers_set_colors_in_copperlist:
; set colors
  move.l     #"COLS",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a1
  move.w     df_cols_count(a1),d7
  subq.w     #1,d7
  move.l     df_idx_ptr_rawdata(a0),a0
  ; reset color 17 below panel
  move.l     a2,a1
  lea.l      ig_cm_cl_reset_color17+2(a1),a1
  move.w     34(a0),(a1)
  ; set color block
  move.l     a2,a1
  lea.l      ig_cm_cl_colors+2(a1),a1
.icl2:
  move.w     (a0)+,(a1)
  addq.l     #4,a1
  dbf        d7,.icl2

  rts

buffers_swap:
  movem.l    d0/a0,-(sp)

  ; set copperlist pointer
  move.l     ig_om_backbuffer(a4),a0
  move.l     ig_buffers_copperlist_pointer(a0),a0
  move.l     a0,COP1LC(a6)
  ; no COPJMP1, because we do not know at which beam position this is executed

  ; increment framecount
  moveq.l    #1,d0
  add.l      d0,ig_om_buffers_framecount(a4)
  
  movem.l    (sp)+,d0/a0
  rts

buffers_get_backbuffer:
  move.l     d0,-(sp)
  move.b     ig_om_buffers_framecount+3(a4),d0
  btst       #0,d0
  beq.s      .buffer_two
  lea.l      ig_om_buffer_one(a4),a0
  bra.s      .exit
.buffer_two:
  lea.l      ig_om_buffer_two(a4),a0
.exit:
  move.l     (sp)+,d0
  rts

  endif                                                                                   ; ifnd INGAME_BUFFERS_ASM
