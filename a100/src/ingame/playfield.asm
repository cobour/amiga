  ifnd        PLAYFIELD_ASM
PLAYFIELD_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/sfx.i"

  ; add constant value to score
  macro       SCORE_C
  movem.l     d0-d1/a0,-(sp)
  lea.l       c_om_score(a4),a0
  move.l      (a0),d0
  moveq.l     #\1,d1
  bsr         bcd_add
  move.l      d0,(a0)
  move.b      #2,ig_om_score_draw_counter(a4)
  movem.l     (sp)+,d0-d1/a0
  endm

  ; add value from data-register to score
  macro       SCORE_D
  movem.l     d0-d1/a0,-(sp)
  lea.l       c_om_score(a4),a0
  move.l      (a0),d0
  move.l      \1,d1
  bsr         bcd_add
  move.l      d0,(a0)
  move.b      #2,ig_om_score_draw_counter(a4)
  movem.l     (sp)+,d0-d1/a0
  endm

; is called before anything is seen on screen
pf_init:
  bsr         .init_data

; fills playfield with empty bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_big_2,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                            ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                                ; source mask data

  ; get target pointer for first brick
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16)+6,d2

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

  ; playfield data
  lea.l       pf_data(pc),a0
  moveq.l     #0,d5

  ; rows loop
  moveq.l     #9,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #9,d6
  move.l      d2,d3
.ig_columns_loop:

  move.b      (a0)+,d5                                             ; brick offset

  WAIT_BLT

  ; source pointers
  move.l      d1,d4
  add.l       d5,d4
  move.l      d4,BLTAPTH(a6)
  move.l      d0,d4
  add.l       d5,d4
  move.l      d4,BLTBPTH(a6)

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
  ; init from savegame data
  lea.l       ig_om_savegame(a4),a3
  bsr         sg_is_used
  tst.l       d0
  beq.s       .id_no_savegame

  lea.l       pf_data(pc),a0
  lea.l       sg_data_playfield(a3),a1
  moveq.l     #24,d7                                               ; 100 bytes = 25 longs
.id_sg_array_loop:
  move.l      (a1)+,(a0)+
  dbf         d7,.id_sg_array_loop

  bra.s       .id_exit
.id_no_savegame:

  lea.l       pf_data(pc),a0
  moveq.l     #0,d0
  moveq.l     #24,d7                                               ; 100 bytes = 25 longs
.id_array_loop:
  move.l      d0,(a0)+
  dbf         d7,.id_array_loop

.id_exit:
  bsr         pf_clear_vars
  rts

; called when switched to placement-mode
pf_gained_mode:
  ; empty for now
  rts

; sets the brick that is to be placed
; in:
;   a1 - pointer to metadata of brick
pf_set_brick:
  movem.l     d0/a0/a2,-(sp)

  ; copy relevant data
  lea.l       df_idx_metadata(a1),a0
  lea.l       pf_brick_width(pc),a2
  move.b      df_tld_plf_width+1(a0),(a2)+
  move.b      df_tld_plf_height+1(a0),(a2)+
  move.l      df_idx_ptr_rawdata(a1),(a2)+

  ; clear pf_brick_is_placable
  moveq.l     #0,d0
  lea.l       pf_brick_is_placable(pc),a0
  move.b      d0,(a0)

  ; set initial position
  lea.l       .initial_position_tab(pc),a0
  move.b      pf_brick_width(pc),d0
  move.b      (a0,d0.w),(a2)+
  move.b      pf_brick_height(pc),d0
  move.b      (a0,d0.w),(a2)

  movem.l     (sp)+,d0/a0/a2
  rts

.initial_position_tab:
  dc.b        -1,4,4,3,3,2                                         ; width/height start with 1 not 0, so first entry is never used

pf_process_events:
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .exit

.process_event:
  bsr         ev_get_next_event
  tst.b       d0
  blt.s       .exit

  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  bne.s       .pe_select
  cmp.b       #$21,d0                                              ; S
  bne.s       .pe_select
  bsr         ig_save_game_and_return_to_mm
  bra.s       .process_event
.pe_select:
  cmp.b       #EventSelect,d0
  bne.s       .pe_unselect
  bra.s       .pe_process_select
.pe_unselect:
  cmp.b       #EventUnselect,d0
  bne.s       .pe_up
  bra         .pe_process_unselect
.pe_up:
  cmp.b       #EventUp,d0
  bne.s       .pe_down
  moveq.l     #0,d1
  moveq.l     #-1,d2
  bra         .pe_process_movement
.pe_down:
  cmp.b       #EventDown,d0
  bne.s       .pe_left
  moveq.l     #0,d1
  moveq.l     #1,d2
  bra         .pe_process_movement
.pe_left:
  cmp.b       #EventLeft,d0
  bne.s       .pe_right
  moveq.l     #-1,d1
  moveq.l     #0,d2
  bra         .pe_process_movement
.pe_right:
  cmp.b       #EventRight,d0
  bne.s       .pe_other
  moveq.l     #1,d1
  moveq.l     #0,d2
  bra         .pe_process_movement
.pe_other:
  ; ignore all other events
  SFX         f000_sfx_error
  bra         .process_event

.exit:
  rts

.pe_process_select:
  lea.l       pf_brick_is_placable(pc),a0
  tst.b       (a0)
  beq.s       .pe_process_select__not_placable

  ; update pf_data with data from brick's tiled area with the not-empty bricks from that area
  bsr         pf_init_pos_brick
  bsr         pf_init_loop_counters
  bsr         pf_get_pointer_for_pos
  move.l      pf_brick_rawdata(pc),a1
  moveq.l     #10,d2
  moveq.l     #0,d4
.pe_process_select__row_loop:
  move.w      d5,d6
  move.l      a0,a2
.pe_process_select__column_loop:
  move.w      (a1)+,d3
  tst.w       d3
  beq.s       .pe_process_select__skip
  move.b      d3,(a2)
  addq.b      #1,d4                                                ; calc score for placement of brick
.pe_process_select__skip:
  addq.l      #1,a2
  dbf         d6,.pe_process_select__column_loop
  add.l       d2,a0
  dbf         d7,.pe_process_select__row_loop
  SCORE_D     d4

  bsr         pf_check_completed
  bsr         ig_switch_mode_select
  bsr         ev_clear_event_queue
  SFX         f000_sfx_placed
  move.b      #1,ig_om_god_request(a4)
  bra         .process_event
.pe_process_select__not_placable:
  SFX         f000_sfx_error
  bra         .process_event

.pe_process_unselect:
  bsr         bs_refill_selected_brick_selector                    ; before mode switch - otherwise selectors get refilled when unselected brick was the last one
  bsr         ig_switch_mode_select
  bsr         ev_clear_event_queue
  SFX         f000_sfx_unselect
  bra         .process_event

; moves the brick to be placed
; in:
;   d1 - x-pos-add (-1, 0 or +1)
;   d2 - y-pos-add (-1, 0 or +1)
.pe_process_movement:
  lea.l       pf_brick_xpos(pc),a0
  lea.l       pf_brick_ypos(pc),a1

  move.b      (a0),d3
  move.b      (a1),d4
  add.b       d1,d3
  add.b       d2,d4

  ; check left border
  tst.b       d3
  blt.s       .pe_process_movement__invalid_position

  ; check top border
  tst.b       d4
  blt.s       .pe_process_movement__invalid_position

  ; check right border
  move.b      d3,d1
  add.b       pf_brick_width(pc),d1
  cmp.b       #10,d1
  bgt.s       .pe_process_movement__invalid_position

  ; check bottom border
  move.b      d4,d1
  add.b       pf_brick_height(pc),d1
  cmp.b       #10,d1
  bgt.s       .pe_process_movement__invalid_position
  
  ; new position is inside playfield
  move.b      d3,(a0)
  move.b      d4,(a1)
  SFX         f000_sfx_step
  bra         .process_event

.pe_process_movement__invalid_position:
  SFX         f000_sfx_error
  bra         .process_event

; draws relevant parts of the playfield
pf_draw:

  ; restore background behind brick to be placed (may be necessary even when not in placement-mode)
  lea.l       pf_brick_old_positions(pc),a0
  tst.w       2(a0)
  blt.s       .check_clearance_in_progress
  bsr.s       .restore_background

.check_clearance_in_progress:
  move.b      ig_om_clearance_in_progress(a4),d0
  tst.b       d0
  beq.s       .check_draw_brick
  bsr.s       .clearance_of_completed_rows_columns
  bra.s       .update_pf_brick_old_positions

.check_draw_brick:
  cmp.b       #IgModePlace,ig_om_act_mode(a4)
  bne.s       .update_pf_brick_old_positions
  bsr         .draw_brick

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
  bsr         pf_init_loop_counters
  bsr         .get_gfx_and_mask_pointers_and_init_blitter
.rb_row_loop:
  bsr         .get_target_offset_in_framebuffer
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

; clearance of completed rows/columns
.clearance_of_completed_rows_columns:
  lea.l       pf_clearance_frame_counter(pc),a0
  moveq.l     #0,d0
  move.b      (a0),d0                                              ; d0 = frames since ig_om_clearance_in_progress was set
  cmp.b       #3,d0
  blt         .clearance_update_vars

  bsr         .get_gfx_and_mask_pointers_and_init_blitter          ; a0+a1 not needed, a2+a3 needed

.clearance_columns_to_clear:
  lea.l       pf_columns_to_clear(pc),a0
  lea.l       pf_clearance_column_offset_framebuffer(pc),a1
  move.l      (a1),d3
  moveq.l     #0,d1
  moveq.l     #0,d2
  moveq.l     #0,d4
.clearance_columns_loop:
  tst.b       (a0,d2.w)
  blt.s       .clearance_columns_loop_next

  ; clear field in pf_data
  move.b      (a0,d2.w),d1
  bsr         .set_field

  ; blit empty block (.draw_single_field)
  bsr         .draw_single_field

  move.b      pf_clearance_frame_counter(pc),d7
  btst        #0,d7
  bne.s       .clearance_columns_loop_next
  ; update values every second run (because of double-buffering)
  add.b       #1,(a0,d2.w)

.clearance_columns_loop_next:
  addq.l      #2,d3
  addq.l      #1,d2
  cmp.b       #10,d2
  blt.s       .clearance_columns_loop

  move.b      pf_clearance_frame_counter(pc),d7
  btst        #0,d7
  bne.s       .clearance_rows_to_clear
  ; update values every second run (because of double-buffering)
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16),(a1)

.clearance_rows_to_clear:
  lea.l       pf_rows_to_clear(pc),a0
  lea.l       pf_clearance_row_offset_framebuffer(pc),a1
  move.l      (a1),d3
  moveq.l     #0,d1
  moveq.l     #0,d2
  moveq.l     #0,d4
.clearance_rows_loop:
  tst.b       (a0,d1.w)
  blt.s       .clearance_rows_loop_next

  ; clear field in pf_data
  move.b      (a0,d1.w),d2
  bsr         .set_field

  ; blit empty block (.draw_single_field)
  bsr         .draw_single_field

  move.b      pf_clearance_frame_counter(pc),d7
  btst        #0,d7
  bne.s       .clearance_rows_loop_next
  ; update values every second run (because of double-buffering)
  add.b       #1,(a0,d1.w)

.clearance_rows_loop_next:
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16),d3
  addq.l      #1,d1
  cmp.b       #10,d1
  blt.s       .clearance_rows_loop

  move.b      pf_clearance_frame_counter(pc),d7
  btst        #0,d7
  bne.s       .clearance_update_vars
  ; update values every second run (because of double-buffering)
  moveq.l     #2,d7
  add.l       d7,(a1)

.clearance_update_vars:
  lea.l       pf_clearance_frame_counter(pc),a0
  add.b       #1,(a0)
  cmp.b       #23,(a0)
  ; clearance is done - reset all relevant values
  bne.s       .clearance_exit
  clr.b       (a0)
  clr.b       ig_om_clearance_in_progress(a4)
  lea.l       pf_rows_to_clear(pc),a0
  moveq.l     #-1,d0
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)

.clearance_exit:
  rts

; draw_brick
.draw_brick:
  bsr         pf_init_pos_brick
  bsr         pf_init_loop_counters
  bsr         .get_gfx_and_mask_pointers_and_init_blitter
  move.b      #1,(a1)                                              ; pf_brick_is_placable
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
  clr.b       (a1)                                                 ; pf_brick_is_placable
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
  move.l      (a0,d4.w),d3                                         ; target offset in framebuffer for the beginning of the row
  move.w      d0,d4
  add.w       d4,d4
  add.l       d4,d3                                                ; target offset in framebuffer for first field to draw
  movem.l     (sp)+,a0/d4
  rts
.row_offsets:
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*16)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*32)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*48)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*64)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*80)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*96)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*112)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*128)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*144)+6
  dc.l        (IgScreenWidthBytes*IgScreenBitPlanes*160)+6

; draws a single field in the playfield
; in:
;   a2 - base gfx pointer
;   a3 - base mask pointer
;   d3 - target offset in framebuffer
;   d4 - index in big_bricks gfx and mask
.draw_single_field:
  movem.l     d0-d2,-(sp)

  move.l      ig_om_backbuffer(a4),d0
  add.l       d3,d0                                                ; d0 = target pointer
  move.l      a2,d1
  add.l       d4,d1                                                ; d1 = source gfx pointer
  move.l      a3,d2
  add.l       d4,d2                                                ; d2 = source mask pointer

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

; gets index from pf_data for given position
; in:
;   d2 - xpos
;   d1 - ypos
; out:
;   d4 - index in big_bricks gfx and mask
.get_field:
  movem.l     d7/a0,-(sp)
  lea.l       pf_row_offsets(pc),a0
  move.w      d1,d7
  add.w       d7,d7
  move.w      (a0,d7.w),d7
  add.w       d2,d7
  lea.l       pf_data(pc),a0
  moveq.l     #0,d4
  move.b      (a0,d7.w),d4
  movem.l     (sp)+,d7/a0
  rts

; sets index in pf_data for given position
; in:
;   d2 - xpos
;   d1 - ypos
;   d4 - index in big_bricks gfx and mask
.set_field:
  movem.l     d7/a0,-(sp)
  lea.l       pf_row_offsets(pc),a0
  move.w      d1,d7
  add.w       d7,d7
  move.w      (a0,d7.w),d7
  add.w       d2,d7
  lea.l       pf_data(pc),a0
  move.b      d4,(a0,d7.w)
  movem.l     (sp)+,d7/a0
  rts

; out:
;   a0 - brick tiled raw data
;   a1 - pointer to pf_brick_is_placable
;   a2 - base gfx pointer
;   a3 - base mask pointer
.get_gfx_and_mask_pointers_and_init_blitter:
  movem.l     d0/d7,-(sp)
  ; get pointers
  move.l      #f000_gfx_bricks_big_2,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),a2                            ; a2 = source gfx data
  move.l      a2,a3
  add.l       df_iff_rawsize(a1),a3                                ; a3 = source mask data
  move.l      pf_brick_rawdata(pc),a0                              ; a0 = brick tiled raw data

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

  lea.l       pf_brick_is_placable(pc),a1                          ; a1 = pointer to pf_brick_is_placable

  movem.l     (sp)+,d0/d7
  rts

; out:
;   d0.w - xpos (0-9)
;   d1.w - ypos (0-9)
pf_init_pos_brick:
  clr.w       d0
  clr.w       d1
  move.b      pf_brick_xpos(pc),d0
  move.b      pf_brick_ypos(pc),d1
  rts

; get counters for row- and column-loops
; out:
;   d5.w - counter for columns-loop
;   d7.w - counter for rows-loop
pf_init_loop_counters:
  clr.w       d5
  clr.w       d7
  move.b      pf_brick_width(pc),d5
  subq.w      #1,d5
  move.b      pf_brick_height(pc),d7
  subq.w      #1,d7
  rts

; gets pointer in pf_data for given position
; in:
;    d0.w - xpos
;    d1.w - ypos
; out:
;    a0 - pointer in pf_data
pf_get_pointer_for_pos:
  move.l      d2,-(sp)
  moveq.l     #0,d2
  move.w      d1,d2
  add.w       d2,d2
  lea.l       pf_row_offsets(pc),a0
  move.w      (a0,d2.w),d2
  add.w       d0,d2
  lea.l       pf_data(pc),a0
  add.l       d2,a0
  move.l      (sp)+,d2
  rts

; checks for completed rows and/or columns and updates pf_rows_to_clear, pf_columns_to_clear and ig_om_clearance_in_progress
pf_check_completed:
  lea.l       pf_clearance_frame_counter(pc),a1
  moveq.l     #10,d0
  moveq.l     #1,d1
  moveq.l     #0,d2
  moveq.l     #0,d6                                                ; any clearance detected?

  ; check rows
  lea.l       pf_rows_to_clear(pc),a0
  lea.l       pf_clearance_row_offset_framebuffer(pc),a2
  lea.l       pf_data(pc),a3
  moveq.l     #9,d7
.rows_loop:
  tst.b       (a3)
  beq.s       .next_row
  tst.b       1(a3)
  beq.s       .next_row
  tst.b       2(a3)
  beq.s       .next_row
  tst.b       3(a3)
  beq.s       .next_row
  tst.b       4(a3)
  beq.s       .next_row
  tst.b       5(a3)
  beq.s       .next_row
  tst.b       6(a3)
  beq.s       .next_row
  tst.b       7(a3)
  beq.s       .next_row
  tst.b       8(a3)
  beq.s       .next_row
  tst.b       9(a3)
  beq.s       .next_row
  move.b      d2,(a0)
  move.b      d1,ig_om_clearance_in_progress(a4)
  move.b      d2,(a1)
  move.l      #(IgScreenWidthBytes*IgScreenBitPlanes*16)+6,(a2)
  moveq.l     #1,d6
  SCORE_C     $10
.next_row:
  addq.l      #1,a0
  add.l       d0,a3
  dbf         d7,.rows_loop

  ; check columns
  lea.l       pf_columns_to_clear(pc),a0
  lea.l       pf_clearance_column_offset_framebuffer(pc),a2
  lea.l       pf_data(pc),a3
  moveq.l     #9,d7
.columns_loop:
  tst.b       (a3)
  beq.s       .next_column
  tst.b       10(a3)
  beq.s       .next_column
  tst.b       20(a3)
  beq.s       .next_column
  tst.b       30(a3)
  beq.s       .next_column
  tst.b       40(a3)
  beq.s       .next_column
  tst.b       50(a3)
  beq.s       .next_column
  tst.b       60(a3)
  beq.s       .next_column
  tst.b       70(a3)
  beq.s       .next_column
  tst.b       80(a3)
  beq.s       .next_column
  tst.b       90(a3)
  beq.s       .next_column
  move.b      d2,(a0)
  move.b      d1,ig_om_clearance_in_progress(a4)
  move.b      d2,(a1)
  move.l      #(IgScreenWidthBytes*IgScreenBitPlanes*16)+6,(a2)
  moveq.l     #1,d6
  SCORE_C     $10
.next_column:
  addq.l      #1,a0
  addq.l      #1,a3
  dbf         d7,.columns_loop

  tst.b       d6
  beq.s       .exit
  SFX         f000_sfx_clear_row_column
.exit:
  rts

; offsets of beginning of rows in pf_data
pf_row_offsets:
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

; in:
;   a0 - pointer to sg_data* struct
pf_add_to_savegame:
  movem.l     d7/a0-a1,-(sp)
  lea.l       sg_data_playfield(a0),a0
  lea.l       pf_data(pc),a1
  moveq.l     #99,d7
.loop:
  move.b      (a1)+,(a0)+
  dbf         d7,.loop
  movem.l     (sp)+,d7/a0-a1
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
  move.l      d1,(a0)+
  move.w      d1,(a0)+

  ; completed rows/columns must be cleared
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.l      d1,(a0)+
  move.w      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)+

  rts

; brick to be placed
pf_brick_width:
  dc.b        0                                                    ; 1-5
pf_brick_height:
  dc.b        0                                                    ; 1-5
pf_brick_rawdata:
  dc.l        0
pf_brick_xpos:
  dc.b        0                                                    ; 0-9
pf_brick_ypos:
  dc.b        0                                                    ; 0-9
pf_brick_old_positions:
  dc.l        0                                                    ; x- and y-positions from the last 2 drawn frames, used for restoring the background
pf_brick_is_placable:
  dc.b        0                                                    ; 0 = false; any other value = true
.padding_byte:
  dc.b        0

; completed rows/columns must be cleared
pf_rows_to_clear:
  dcb.b       10,-1                                                ; -1 = false; 0-9 intervall to be cleared
pf_columns_to_clear:
  dcb.b       10,-1                                                ; -1 = false; 0-9 intervall to be cleared
pf_clearance_frame_counter:
  dc.b        0                                                    ; framecount since ig_om_clearance_in_progress was set
.padding_byte:
  dc.b        0
pf_clearance_row_offset_framebuffer:
  dc.l        0                                                    ; offset in framebuffer for next row clearance
pf_clearance_column_offset_framebuffer:
  dc.l        0                                                    ; offset in framebuffer for next column clearance

pf_data:
  dcb.b       100                                                  ; index array for brick per field

  endif                                                            ; ifnd PLAYFIELD_ASM
