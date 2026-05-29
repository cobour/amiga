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
  add.l      #IgScreenWidthBytes*(IgScreenHeight+16)*IgScreenBitPlanes,d1            ; pointer to beginning of last row in framebuffer
  move.l     #IgScreenWidthBytes*16*IgScreenBitPlanes,d2                             ; size of one tile-row in framebuffer (target)
  move.l     ig_om_background_tiles_width_in_bytes(a4),d3                            ; size of one row in tile gfx data (source)
  moveq.l    #0,d5                                                                   ; for tile gfx offset

  moveq.l    #17-1,d7                                                                ; loop over 17 rows (16 are initially visible, 1 is scolled in)
.bi_row_loop:

  move.l     d1,d4                                                                   ; target pointer for this row
  moveq.l    #16-1,d6                                                                ; loop over 16 columns
.bi_column_loop:

  move.w     (a0)+,d5                                                                ; get next tile offset

  ; draw one 16x16 tile
  move.l     ig_om_background_tiles_gfx_pointer(a4),a1
  add.l      d5,a1                                                                   ; source pointer
  move.l     d4,a2                                                                   ; target pointer

  moveq.l    #16-1,d0                                                                ; loop over 16 pixel rows in tile
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

  addq.l     #2,d4                                                                   ; move target pointer to next column
  dbf        d6,.bi_column_loop

  sub.l      d2,d1                                                                   ; one row up in framebuffer
  dbf        d7,.bi_row_loop

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

  rts

  endif                                                                              ; ifnd INGAME_BACKGROUND_ASM
