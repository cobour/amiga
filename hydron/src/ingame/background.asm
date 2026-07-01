  ifnd       INGAME_BACKGROUND_ASM
INGAME_BACKGROUND_ASM equ 1

  include    "src/ingame.i"

background_init:
  ; init ranges
  clr.w      ig_om_background_range_1_row_start(a4)
  move.w     #IgScreenHeight-1,ig_om_background_range_1_row_end(a4)
  move.l     #32*IgScreenWidthBytes*IgScreenBitPlanes,ig_om_background_range_1_row_offset(a4)
  move.w     #-1,ig_om_background_range_2_row_start(a4)
  move.w     #IgScreenHeight-1,ig_om_background_range_2_row_end(a4)
  clr.l      ig_om_background_range_2_row_offset(a4)

  ; tiles gfx pointer
  move.l     #"TLS0",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_background_tiles_gfx_pointer(a4)

  ; calc tiles width in bytes
  lea.l      df_idx_metadata(a0),a1
  moveq.l    #0,d0
  move.w     df_iff_width(a1),d0
  lsr.w      #3,d0
  move.l     d0,ig_om_background_tiles_width_in_bytes(a4)

  ; level data pointer and current level ypos
  move.l     #"MAPT",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_background_level_data_pointer(a4)
  lea.l      df_idx_metadata(a0),a0
  move.w     df_tld_plf_height(a0),d0
  mulu       df_tld_plf_tile_height(a0),d0
  move.l     d0,ig_om_background_level_ypos(a4)
  move.l     df_tld_plf_rawsize(a0),d0
  add.l      ig_om_background_level_data_pointer(a4),d0
  move.l     d0,ig_om_background_level_data_end_pointer(a4)

  ; draw to third buffer
  move.l     ig_om_background_level_data_pointer(a4),a0
  move.l     ig_om_buffer_three(a4),d1
  add.l      #IgScreenWidthBytes*(IgScreenHeight+16)*IgScreenBitPlanes,d1                          ; pointer to beginning of last row in framebuffer
  move.l     #IgScreenWidthBytes*16*IgScreenBitPlanes,d2                                           ; size of one tile-row in framebuffer (target)
  move.l     ig_om_background_tiles_width_in_bytes(a4),d3                                          ; size of one row in tile gfx data (source)
  moveq.l    #0,d5                                                                                 ; for tile gfx offset

  moveq.l    #17-1,d7                                                                              ; loop over 17 rows (16 are initially visible, 1 is scolled in)
.bi_row_loop:

  move.l     d1,d4                                                                                 ; target pointer for this row
  moveq.l    #16-1,d6                                                                              ; loop over 16 columns
.bi_column_loop:

  move.w     (a0)+,d5                                                                              ; get next tile offset

  ; draw one 16x16 tile
  move.l     ig_om_background_tiles_gfx_pointer(a4),a1
  add.l      d5,a1                                                                                 ; source pointer
  move.l     d4,a2                                                                                 ; target pointer

  moveq.l    #16-1,d0                                                                              ; loop over 16 pixel rows in tile
.bi_tile_loop:
  ; unrolled copy loop for one tile-row - 6 bitplanes => 6x move.w
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  move.w     (a1),(a2)
  add.l      d3,a1
  lea.l      IgScreenWidthBytes(a2),a2
  dbf        d0,.bi_tile_loop

  addq.l     #2,d4                                                                                 ; move target pointer to next column
  dbf        d6,.bi_column_loop

  sub.l      d2,d1                                                                                 ; one row up in framebuffer
  dbf        d7,.bi_row_loop

  move.l     a0,ig_om_background_level_data_pointer(a4)                                            ; store new position of pointer to level data

  ; copy buffer 3 to buffer 1
  move.l     ig_om_buffer_three(a4),a0
  add.l      #IgScreenWidthBytes*16*IgScreenBitPlanes,a0
  move.l     ig_om_buffer_one+ig_buffers_framebuffer_pointer(a4),a1
  add.l      #IgScreenWidthBytes*16*IgScreenBitPlanes,a1
  move.w     #((IgScreenWidthBytes*(IgScreenHeight+16)*IgScreenBitPlanes)/4)-1,d7
.bi_copy_one_loop:
  move.l     (a0)+,(a1)+
  dbf        d7,.bi_copy_one_loop

  ; copy buffer 3 to buffer 2
  move.l     ig_om_buffer_three(a4),a0
  add.l      #IgScreenWidthBytes*16*IgScreenBitPlanes,a0
  move.l     ig_om_buffer_two+ig_buffers_framebuffer_pointer(a4),a1
  add.l      #IgScreenWidthBytes*16*IgScreenBitPlanes,a1
  move.w     #((IgScreenWidthBytes*(IgScreenHeight+16)*IgScreenBitPlanes)/4)-1,d7
.bi_copy_two_loop:
  move.l     (a0)+,(a1)+
  dbf        d7,.bi_copy_two_loop

  ; set starting values and exit
  move.w     #32,ig_om_background_first_visible_line(a4)
  move.w     #32*IgScreenWidthBytes*IgScreenBitPlanes,ig_om_background_first_visible_offset(a4)
  move.b     #1,ig_om_background_do_scroll(a4)
  clr.b      ig_om_background_stop_scroll_count(a4)
  clr.w      ig_om_background_fill_row_offset(a4)
  clr.w      ig_om_background_fill_column_offset(a4)
  clr.l      ig_om_background_copperwait_split(a4)
  clr.b      ig_om_background_last_row_countdown(a4)
  rts

background_pause_scroll:
  tst.b      ig_om_background_do_scroll(a4)
  beq.s      .exit
  clr.b      ig_om_background_do_scroll(a4)
  move.b     #2,ig_om_background_stop_scroll_count(a4)
.exit:
  rts

background_resume_scroll:
  move.l     d0,-(sp)
  move.l     ig_om_background_level_data_end_pointer(a4),d0
  cmp.l      ig_om_background_level_data_pointer(a4),d0
  beq.s      .exit
  move.b     #1,ig_om_background_do_scroll(a4)
  clr.b      ig_om_background_stop_scroll_count(a4)
.exit:
  move.l     (sp)+,d0
  rts

background_update:
  tst.b      ig_om_background_stop_scroll_count(a4)
  beq.s      .check_normal_scroll
  sub.b      #1,ig_om_background_stop_scroll_count(a4)
  bra.s      .calc_and_set_bpl_pointers_in_copperlist
.check_normal_scroll:
  tst.b      ig_om_background_do_scroll(a4)
  beq        .exit
  
  ; update level position
  move.l     ig_om_background_level_ypos(a4),d0
  subq.l     #1,d0
  move.l     d0,ig_om_background_level_ypos(a4)

  ; update first visible line/offset and set d0.w/d1.w
  moveq.l    #0,d0
  moveq.l    #0,d1
  move.w     ig_om_background_first_visible_offset(a4),d1
  move.w     ig_om_background_first_visible_line(a4),d0
  sub.w      #IgScreenWidthBytes*IgScreenBitPlanes,d1
  subq.w     #1,d0
  bge.s      .update_first_visible_line
  move.w     #IgFrameBufferHeight-1,d0
  move.w     #(IgFrameBufferHeight-1)*IgScreenWidthBytes*IgScreenBitPlanes,d1
.update_first_visible_line:
  move.w     d0,ig_om_background_first_visible_line(a4)
  move.w     d1,ig_om_background_first_visible_offset(a4)

  ; set offset for first range
  move.l     d1,ig_om_background_range_1_row_offset(a4)

  ; draw one 16x16 tile to all 3 buffers and update ig_om_background_fill_row_offset+ig_om_background_fill_column_offset
  tst.b      ig_om_background_last_row_countdown(a4)
  beq.s      .must_draw
  sub.b      #1,ig_om_background_last_row_countdown(a4)
  tst.b      ig_om_background_last_row_countdown(a4)
  bne.s      .no_draw
  bsr        background_pause_scroll
  bra.s      .no_draw
.must_draw:
  move.w     ig_om_background_fill_column_offset(a4),d0
  move.w     ig_om_background_fill_row_offset(a4),d1
  bsr        .draw_tile
  addq.w     #2,d0
  cmp.w      #IgScreenWidthBytes,d0
  blt.s      .end_of_draw_tile
  moveq.l    #0,d0
  sub.l      #IgScreenWidthBytes*IgScreenBitPlanes*16,d1                                           ; MUST be sub.L (not .w) so cc's are set correctly
  bge.s      .end_of_draw_tile
  move.w     #IgScreenWidthBytes*IgScreenBitPlanes*(IgScreenHeight+16),d1
.end_of_draw_tile:
  move.w     d0,ig_om_background_fill_column_offset(a4)
  move.w     d1,ig_om_background_fill_row_offset(a4)
.no_draw:

  ; set bitplane pointers in copperlist - MUST be last task before .exit (because must be executed even when there is no actual scroll, see ig_om_background_stop_scroll_count)
  ; in this section (until .exit):
  ;   a0 - ig_om_buffers_backbuffer(a4)
.calc_and_set_bpl_pointers_in_copperlist:
  ; calc absolute pointer to be set in copperlist for first visible line
  moveq.l    #0,d0
  move.w     ig_om_background_first_visible_offset(a4),d0
  move.l     ig_om_buffers_backbuffer(a4),a0
  add.l      ig_buffers_framebuffer_pointer(a0),d0
  ; set in copperlist
  move.l     ig_buffers_copperlist_pointer(a0),a2
  lea.l      ig_cm_cl_bitplanes(a2),a2
  moveq.l    #IgScreenBitPlanes-1,d7
.update_first_bpl_pointers_in_copperlist_loop:
  move.w     d0,6(a2)
  swap       d0
  move.w     d0,2(a2)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a2
  dbf        d7,.update_first_bpl_pointers_in_copperlist_loop

  ; when framebuffer needs to be splitted, set second absolute pointer in copperlist
  ; if ig_buffers_last_panel_split or ig_buffers_last_split is set, then reset that area and clear ig_buffers_last_panel_split or ig_buffers_last_split
  tst.l      ig_buffers_last_panel_split(a0)
  beq.s      .check_ig_buffers_last_split
  move.l     ig_buffers_last_panel_split(a0),a1
  move.l     #$01fe0000,d0
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)
  clr.l      ig_buffers_last_panel_split(a0)
.check_ig_buffers_last_split:
  tst.l      ig_buffers_last_split(a0)
  beq.s      .end_reset
  move.l     ig_buffers_last_split(a0),a1
  move.l     #$01fe0000,d0
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     d0,(a1)+
  move.l     #$ffdffffe,(a1)                                                                       ; first WAIT of ig_cm_cl_irq
  clr.l      ig_buffers_last_split(a0)
.end_reset:
  ; check if split is necessary
  moveq.l    #0,d0
  move.w     ig_om_background_first_visible_line(a4),d0
  cmp.w      #IgFrameBufferHeight-16,d0
  blt.s      .check_split_below_panel
  ; split inside panel
  ; get copperlist position
  sub.w      #$0110,d0
  lsl.w      #1,d0
  lea.l      .split_in_panel(pc),a1
  move.w     (a1,d0.w),d0
  move.l     ig_buffers_copperlist_pointer(a0),a2
  add.l      d0,a2
  move.l     a2,ig_buffers_last_panel_split(a0)
  ; copper wait
  move.w     52(a2),d0
  move.b     #$d1,d0
  sub.w      #$100,d0
  move.w     d0,(a2)+
  move.l     d0,ig_om_background_copperwait_split(a4)
  move.w     #$fffe,(a2)+
  ; set bitplane pointers
  move.l     ig_buffers_framebuffer_pointer(a0),d0
  bsr.s      .set_bitplane_pointer_in_copperlist
  bra.s      .end_split
.check_split_below_panel:
  cmp.w      #32,d0
  ble.s      .no_split
  ; split below panel
  move.l     ig_buffers_copperlist_pointer(a0),a2
  lea.l      ig_cm_cl_wait_and_bitplane_pointers(a2),a2
  move.l     a2,ig_buffers_last_split(a0)
  ; copper wait(s)
  move.l     ig_om_background_copperwait_split(a4),d0
  tst.b      ig_om_background_do_scroll(a4)
  beq.s      .split_below_panel_no_add
  add.l      #$00000100,d0
.split_below_panel_no_add:
  move.l     d0,ig_om_background_copperwait_split(a4)
  cmp.l      #$00010000,d0
  blt.s      .split_below_panel_one_wait
  move.l     #$ffdffffe,(a2)+
.split_below_panel_one_wait:
  move.w     d0,d1
  move.w     d0,(a2)+
  move.w     #$fffe,(a2)+
  ; set bitplane pointers
  move.l     ig_buffers_framebuffer_pointer(a0),d0
  bsr.s      .set_bitplane_pointer_in_copperlist
  ; in row $ff the first wait of ig_cm_cl_irq must be noop'd out, otherwise there would be two $ffxx-waits and because of this the copper irq will never be triggered again
  and.w      #$ff00,d1
  cmp.w      #$ff00,d1
  bne.s      .end_split
  move.l     #$01fe0000,(a2)
.end_split:
  ; set correct end/start rows for both ranges
  tst.w      ig_om_background_range_2_row_start(a4)
  bge.s      .no_switch_to_split
  clr.w      ig_om_background_range_2_row_start(a4)
.no_switch_to_split:
  move.w     ig_om_background_range_2_row_start(a4),d0
  addq.w     #1,d0
  move.w     d0,ig_om_background_range_2_row_start(a4)
  subq.w     #1,d0
  move.w     d0,ig_om_background_range_1_row_end(a4)
  bra.s      .exit

.no_split:
  move.w     #-1,ig_om_background_range_2_row_start(a4)
  move.w     #IgScreenHeight-1,ig_om_background_range_1_row_end(a4)

.exit:
  rts

; in:
;   a2   - pointer into copperlist where bitplane pointers are set
;   d0.l - bitplane pointer
.set_bitplane_pointer_in_copperlist:
  moveq.l    #IgScreenBitPlanes-1,d7
  move.w     #BPL1PTH,d6
.set_bitplane_pointer_in_copperlist_loop:
  move.w     d6,(a2)
  addq.w     #2,d6
  move.w     d6,4(a2)
  addq.w     #2,d6
  move.w     d0,6(a2)
  swap       d0
  move.w     d0,2(a2)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a2
  dbf        d7,.set_bitplane_pointer_in_copperlist_loop
  rts

.split_in_panel:
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*16)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*15)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*14)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*13)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*12)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*11)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*10)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*09)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*08)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*07)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*06)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*05)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*04)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*03)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*02)-(panel_clrow_sizeof-panel_clrow_wait_3)
  dc.w       ig_cm_cl_panel+(panel_clrow_sizeof*01)-(panel_clrow_sizeof-panel_clrow_wait_3)

  ; draw one row of one bitplane to all three buffers
  macro      TROW1
  move.w     (a0),d4
  move.w     d4,(a1)
  move.w     d4,(a2)
  move.w     d4,(a3)
  add.l      d2,a0
  add.l      d3,a1
  add.l      d3,a2
  add.l      d3,a3
  endm

  ; draw one row of all bitplanes to all three buffers
  macro      TROWA
  TROW1
  TROW1
  TROW1
  TROW1
  TROW1
  TROW1
  endm

; actually draw tile (all loops unrolled)
; in:
;   d0.l  ig_om_background_fill_column_offset
;   d1.l  ig_om_background_fill_row_offset
; DO NOT CHANGE d0+d1
.draw_tile:
  move.l     a0,-(sp)
  
  ; get tile offset
  move.l     ig_om_background_level_data_pointer(a4),a0
  moveq.l    #0,d2
  move.w     (a0)+,d2
  move.l     a0,ig_om_background_level_data_pointer(a4)

  ; stop scrolling when end of level data is reached
  cmp.l      ig_om_background_level_data_end_pointer(a4),a0
  bne.s      .no_stop
  move.b     #16,ig_om_background_last_row_countdown(a4)
.no_stop:

  ; set source pointer (tile gfx)
  move.l     ig_om_background_tiles_gfx_pointer(a4),a0
  add.l      d2,a0

  ; set all three target pointers (framebuffers)
  move.l     ig_om_buffer_one+ig_buffers_framebuffer_pointer(a4),a1
  move.l     ig_om_buffer_two+ig_buffers_framebuffer_pointer(a4),a2
  move.l     ig_om_buffer_three(a4),a3
  move.l     d0,d2
  add.l      d1,d2
  add.l      d2,a1
  add.l      d2,a2
  add.l      d2,a3

  ; set modulos
  move.l     ig_om_background_tiles_width_in_bytes(a4),d2
  move.l     #IgScreenWidthBytes,d3
  
  ; TODO: check if it's faster to copy to one buffer with cpu and then copy to other buffers with blitter

  TROWA                                                                                            ; row 0
  TROWA                                                                                            ; row 1
  TROWA                                                                                            ; row 2
  TROWA                                                                                            ; row 3
  TROWA                                                                                            ; row 4
  TROWA                                                                                            ; row 5
  TROWA                                                                                            ; row 6
  TROWA                                                                                            ; row 7
  TROWA                                                                                            ; row 8
  TROWA                                                                                            ; row 9
  TROWA                                                                                            ; row a
  TROWA                                                                                            ; row b
  TROWA                                                                                            ; row c
  TROWA                                                                                            ; row d
  TROWA                                                                                            ; row e
  TROWA                                                                                            ; row f

  move.l     (sp)+,a0
  rts

  endif                                                                                            ; ifnd INGAME_BACKGROUND_ASM
