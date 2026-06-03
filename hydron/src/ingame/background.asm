  ifnd       INGAME_BACKGROUND_ASM
INGAME_BACKGROUND_ASM equ 1

  include    "src/ingame.i"

background_init:
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

  ; level data pointer
  move.l     #"MAPT",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_background_level_data_pointer(a4)

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
  rts

background_pause_scroll:
  clr.b      ig_om_background_do_scroll(a4)
  move.b     #2,ig_om_background_stop_scroll_count(a4)
  rts

background_resume_scroll:
  move.b     #1,ig_om_background_do_scroll(a4)
  clr.b      ig_om_background_stop_scroll_count(a4)
  rts

background_update:
  tst.b      ig_om_background_stop_scroll_count(a4)
  beq.s      .check_normal_scroll
  sub.b      #1,ig_om_background_stop_scroll_count(a4)
  bra.s      .calc_and_set_bpl_pointers_in_copperlist
.check_normal_scroll:
  tst.b      ig_om_background_do_scroll(a4)
  beq.s      .exit
  
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

  ; draw one 16x16 tile to all 3 buffers and update ig_om_background_fill_row_offset+ig_om_background_fill_column_offset
  move.w     ig_om_background_fill_column_offset(a4),d0
  move.w     ig_om_background_fill_row_offset(a4),d1
  bsr.s      .draw_tile
  addq.w     #2,d0
  cmp.w      #IgScreenWidthBytes,d0
  blt.s      .end_of_draw_tile
  moveq.l    #0,d0
  sub.w      #IgScreenWidthBytes*IgScreenBitPlanes*16,d1
  bge.s      .end_of_draw_tile
  move.w     #IgScreenWidthBytes*IgScreenBitPlanes*(IgScreenHeight+16),d1
.end_of_draw_tile:
  move.w     d0,ig_om_background_fill_column_offset(a4)
  move.w     d1,ig_om_background_fill_row_offset(a4)

  ; set bitplane pointers in copperlist - MUST be last task before .exit (because must be executed even when there is no actual scroll, see ig_om_background_stop_scroll_count)
.calc_and_set_bpl_pointers_in_copperlist:
  ; calc absolute pointer to be set in copperlist for first visible line
  moveq.l    #0,d0
  move.w     ig_om_background_first_visible_offset(a4),d0
  move.l     ig_om_backbuffer(a4),a0
  add.l      ig_buffers_framebuffer_pointer(a0),d0
  ; set in copperlist
  move.l     ig_buffers_copperlist_pointer(a0),a1
  lea.l      ig_cm_cl_bitplanes(a1),a1
  moveq.l    #IgScreenBitPlanes-1,d7
.update_first_bpl_pointers_in_copperlist_loop:
  move.w     d0,6(a1)
  swap       d0
  move.w     d0,2(a1)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a1
  dbf        d7,.update_first_bpl_pointers_in_copperlist_loop
  ; TODO: when framebuffer needs to be splitted, set second absolute pointer in copperlist

.exit:
  rts

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
  
  ; TODO stop scrolling when end of level data is reached

  ; get tile offset
  move.l     ig_om_background_level_data_pointer(a4),a0
  moveq.l    #0,d2
  move.w     (a0)+,d2
  move.l     a0,ig_om_background_level_data_pointer(a4)

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
