  ifnd        PLAYFIELD_ASM
PLAYFIELD_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/sfx.i"

; is called before anything is seen on screen
playfield_init:
  bsr         .init_data

; fills playfield with empty bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_big,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data

  ; get target pointer for first brick
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16)+2,d2

  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d7
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; rows loop
  moveq.l     #9,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #9,d6
  move.l      d2,d3
.ig_columns_loop:

  WAIT_BLT

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next columns loop iteration
  addq.l      #2,d3
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16),d2
  dbf         d7,.ig_rows_loop

  rts

; initializes data structure
.init_data:
  lea.l       playfield_data(pc),a0
  moveq.l     #0,d0
  moveq.l     #24,d7                                             ; 100 bytes = 25 longs
.id_array_loop:
  move.l      d0,(a0)+
  dbf         d7,.id_array_loop
  bsr         pf_clear_vars
  rts

; sets the brick that is to be placed
; in:
;   a1 - pointer to metadata of brick
playfield_set_brick:
  movem.l     d0/a0/a2,-(sp)

  ; copy relevant data
  lea.l       df_idx_metadata(a1),a0
  lea.l       pf_brick_width(pc),a2
  move.b      df_tld_plf_width+1(a0),(a2)+
  move.b      df_tld_plf_height+1(a0),(a2)+
  move.l      df_idx_ptr_rawdata(a1),(a2)+

  ; set initial position
  moveq.l     #0,d0
  lea.l       .initial_position_tab(pc),a0
  move.b      pf_brick_width(pc),d0
  move.b      (a0,d0.w),(a2)+
  move.b      pf_brick_height(pc),d0
  move.b      (a0,d0.w),(a2)

  movem.l     (sp)+,d0/a0/a2
  rts

.initial_position_tab:
  dc.b        -1,4,4,3,3,2                                       ; width/height start with 1 not 0, so first entry is never used

playfield_process_events:
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .exit

.process_event:
  bsr         get_next_event
  tst.b       d0
  blt.s       .exit

.pe_select:
  cmp.b       #EventSelect,d0
  bne.s       .pe_unselect
  bra.s       .pe_process_select
.pe_unselect:
  cmp.b       #EventUnselect,d0
  bne.s       .pe_up
  bra.s       .pe_process_unselect
.pe_up:
  cmp.b       #EventUp,d0
  bne.s       .pe_down
  moveq.l     #0,d1
  moveq.l     #-1,d2
  bra.s       .pr_process_movement
.pe_down:
  cmp.b       #EventDown,d0
  bne.s       .pe_left
  moveq.l     #0,d1
  moveq.l     #1,d2
  bra.s       .pr_process_movement
.pe_left:
  cmp.b       #EventLeft,d0
  bne.s       .pe_right
  moveq.l     #-1,d1
  moveq.l     #0,d2
  bra.s       .pr_process_movement
.pe_right:
  cmp.b       #EventRight,d0
  bne.s       .pe_other
  moveq.l     #1,d1
  moveq.l     #0,d2
  bra.s       .pr_process_movement
.pe_other:
  ; ignore all other events
  SFX         f000_sfx_error
  bra         .process_event

.exit:
  rts

.pe_process_select:
  ; TODO: handle placement of brick (updates playfield_data with data from brick's tiled area with the not-empty bricks from that area)
  SFX         f000_sfx_error
  bra.s       .process_event

.pe_process_unselect:
  move.b      #IgModeSelect,ig_om_act_mode(a4)
  bsr         clear_event_queue
  bsr         refill_selected_brick_selector
  SFX         f000_sfx_unselect
  bra         .process_event

; moves the brick to be placed
; in:
;   d1 - x-pos-add (-1, 0 or +1)
;   d2 - y-pos-add (-1, 0 or +1)
.pr_process_movement:
  lea.l       pf_brick_xpos(pc),a0
  lea.l       pf_brick_ypos(pc),a1

  move.b      (a0),d3
  move.b      (a1),d4
  add.b       d1,d3
  add.b       d2,d4

  ; check left border
  tst.b       d3
  blt.s       .invalid_position

  ; check top border
  tst.b       d4
  blt.s       .invalid_position

  ; check right border
  move.b      d3,d1
  add.b       pf_brick_width(pc),d1
  cmp.b       #10,d1
  bgt.s       .invalid_position

  ; check bottom border
  move.b      d4,d1
  add.b       pf_brick_height(pc),d1
  cmp.b       #10,d1
  bgt.s       .invalid_position
  
  ; new position is inside playfield
  move.b      d3,(a0)
  move.b      d4,(a1)
  SFX         f000_sfx_step
  bra         .process_event

.invalid_position:
  SFX         f000_sfx_error
  bra         .process_event

; draws relevant parts of the playfield
playfield_draw:

  ; restore background behind brick to be placed (may be necessary even when not in placement-mode)
  lea.l       pf_brick_old_positions(pc),a0
  tst.w       2(a0)
  blt.s       .check_draw_brick
  bsr.s       .restore_background

.check_draw_brick:
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .update_pf_brick_old_positions
  bsr.s       .draw_brick

.update_pf_brick_old_positions:
  lea.l       pf_brick_old_positions(pc),a0
  move.w      (a0),2(a0)
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .0
  move.b      pf_brick_xpos(pc),(a0)
  move.b      pf_brick_ypos(pc),1(a0)
  bra.s       .exit
.0:
  move.w      #-1,(a0)

.exit:
  rts

; restore background
.restore_background:
  bsr         .init_pos_restore
  bsr         .init_loop_counters
  bsr         .get_gfx_and_mask_pointers_and_init_blitter
.rb_row_loop:
  bsr.s       .get_target_offset_in_framebuffer
  move.w      d0,d2
  move.w      d5,d6
.rb_column_loop:
  move.w      (a0)+,d4
  tst.w       d4
  beq.s       .rb_skip
  bsr         .get_field
  bsr         .draw_single_field
.rb_skip:
  addq.w      #1,d2
  addq.l      #2,d3
  dbf         d6,.rb_column_loop
  addq.w      #1,d1
  dbf         d7,.rb_row_loop

  rts

; draw_brick
.draw_brick:
  bsr         .init_pos_draw
  bsr         .init_loop_counters
  bsr         .get_gfx_and_mask_pointers_and_init_blitter
.db_row_loop:
  bsr.s       .get_target_offset_in_framebuffer
  move.w      d0,d2
  move.w      d5,d6
.db_column_loop:
  bsr         .get_field
  tst.w       d4
  beq.s       .db_draw_normal
  tst.w       (a0)
  beq.s       .db_skip
  ; draw stop sign = field is occupied AND brick is solid in this square
  move.w      #14,d4
  bra.s       .db_draw
.db_draw_normal:
  move.w      (a0),d4
.db_draw:
  bsr.s       .draw_single_field
.db_skip:
  addq.w      #1,d2
  addq.l      #2,d3
  addq.l      #2,a0
  dbf         d6,.db_column_loop
  addq.w      #1,d1
  dbf         d7,.db_row_loop

  rts

; gets target offset in backbuffer
; in:
;   d1 - ypos
;   d0 - xpos
; out:
;   d3 - target offset in backbuffer
.get_target_offset_in_framebuffer:
  movem.l     a0/d4,-(sp)
  moveq.l     #0,d4
  move.w      d1,d4
  add.w       d4,d4
  add.w       d4,d4
  lea.l       .row_offsets(pc),a0
  move.l      (a0,d4.w),d3                                       ; target offset in framebuffer for the beginning of the row
  move.w      d0,d4
  add.w       d4,d4
  add.l       d4,d3                                              ; target offset in framebuffer for first field to draw
  movem.l     (sp)+,a0/d4
  rts
.row_offsets:
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*48)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*64)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*80)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*96)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*112)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*128)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*144)+2
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*160)+2

; draws a single field in the playfield
; in:
;   a2 - base gfx pointer
;   a3 - base mask pointer
;   d3 - target offset in framebuffer
;   d4 - index in big_bricks gfx and mask
.draw_single_field:
  movem.l     d0-d2,-(sp)

  move.l      ig_om_backbuffer(a4),d0
  add.l       d3,d0                                              ; d0 = target pointer
  move.l      a2,d1
  add.l       d4,d1                                              ; d1 = source gfx pointer
  move.l      a3,d2
  add.l       d4,d2                                              ; d2 = source mask pointer

  WAIT_BLT

  move.l      d2,BLTAPTH(a6)
  move.l      d1,BLTBPTH(a6)
  move.l      d0,BLTCPTH(a6)
  move.l      d0,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  movem.l     (sp)+,d0-d2
  rts

; in:
;   a0 - pf_brick_old_positions
; out:
;   d0.w - xpos (0-9)
;   d1.w - ypos (0-9)
.init_pos_restore:
  clr.w       d0
  clr.w       d1
  move.b      2(a0),d0
  move.b      3(a0),d1
  rts

; out:
;   d0.w - xpos (0-9)
;   d1.w - ypos (0-9)
.init_pos_draw:
  clr.w       d0
  clr.w       d1
  move.b      pf_brick_xpos(pc),d0
  move.b      pf_brick_ypos(pc),d1
  rts

; get counters for row- and column-loops
; out:
;   d5.w - counter for columns-loop
;   d7.w - counter for rows-loop
.init_loop_counters:
  clr.w       d5
  clr.w       d7
  move.b      pf_brick_width(pc),d5
  subq.w      #1,d5
  move.b      pf_brick_height(pc),d7
  subq.w      #1,d7
  rts

; gets index from playfield_data for given position
; in:
;   d2 - xpos
;   d1 - ypos
; out:
;   d4 - index in big_bricks gfx and mask
.get_field:
  movem.l     d7/a0,-(sp)
  lea.l       .gf_row_offsets(pc),a0
  move.w      d1,d7
  add.w       d7,d7
  move.w      (a0,d7.w),d7
  add.w       d2,d7
  lea.l       playfield_data(pc),a0
  clr.w       d4
  move.b      (a0,d7.w),d4
  movem.l     (sp)+,d7/a0
  rts

.gf_row_offsets:
  dc.w        0
  dc.w        10
  dc.w        20
  dc.w        30
  dc.w        40
  dc.w        50
  dc.w        60
  dc.w        70
  dc.w        80
  dc.w        90

; out:
;   a0 - brick tiled raw data
;   a1 - big_bricks metadata
;   a2 - base gfx pointer
;   a3 - base mask pointer
.get_gfx_and_mask_pointers_and_init_blitter:
  movem.l     d0/d7,-(sp)
  ; get pointers
  move.l      #f000_gfx_bricks_big,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1                             ; a1 = big_bricks metadata
  move.l      df_idx_ptr_rawdata(a0),a2                          ; a2 = source gfx data
  move.l      a2,a3
  add.l       df_iff_rawsize(a1),a3                              ; a3 = source mask data
  move.l      pf_brick_rawdata(pc),a0                            ; a0 = brick tiled raw data

  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d7
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  movem.l     (sp)+,d0/d7
  rts

;
; vars section
;

pf_clear_vars:
  moveq.l     #0,d0
  moveq.l     #-1,d1
  lea.l       pf_brick_width(pc),a0

  ; brick to be placed
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d1,(a0)

  rts

; brick to be placed
pf_brick_width:
  dc.b        0                                                  ; 1-5
pf_brick_height:
  dc.b        0                                                  ; 1-5
pf_brick_rawdata:
  dc.l        0
pf_brick_xpos:
  dc.b        0                                                  ; 0-9
pf_brick_ypos:
  dc.b        0                                                  ; 0-9
pf_brick_old_positions:
  dc.l        0                                                  ; x- and y-positions from the last 2 drawn frames, used for restoring the background

playfield_data: ; index array for brick per field
  dcb.b       100

  endif                                                          ; ifnd PLAYFIELD_ASM
