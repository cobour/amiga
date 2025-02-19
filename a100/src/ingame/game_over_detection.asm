  ifnd       GAME_OVER_DETECTION_ASM
GAME_OVER_DETECTION_ASM equ 1

  include    "../a100/src/globals.i"
  include    "../a100/src/ingame/sfx.i"

god_init:
  lea.l      god_last_check(pc),a0
  clr.l      (a0)
  rts

; must be called when brick selectors are refilled 
; and when one brick is placed on the playfield
game_over_detection:

  ; check if necessary
  move.l     god_last_check(pc),d0
  cmp.l      ig_om_framecounter(a4),d0
  beq        .god_exit

  bsr        bs_get_selectable_bricks

.bricks_loop:
  tst.l      (a0)
  beq.s      .god_no_brick_is_placable
  move.l     (a0)+,a1

  move.l     df_idx_ptr_rawdata(a1),a2
  lea.l      df_idx_metadata(a1),a1
  move.w     df_tld_plf_height(a1),d0
  move.w     df_tld_plf_width(a1),d1
  move.l     a2,a1

; check one brick
; a1   - pointer to rawdata of brick
; d0.w - height of brick
; d1.w - width of brick
  lea.l      pf_data(pc),a2

  moveq.l    #10,d7
  sub.w      d0,d7
  addq.w     #1,d7                                     ; d7 = max ypos for check for position
  moveq.l    #10,d6
  sub.w      d1,d6
  addq.w     #1,d6                                     ; d6 = max xpos to check for position

  moveq.l    #0,d5                                     ; d5 = ypos for check

.check_brick_row_loop:
  moveq.l    #0,d4                                     ; d4 = xpos for check
  move.l     a2,a3                                     ; a3 = pointer to playfield-data, beginning of row for position check

.check_brick_column_loop:

; check one position for one brick
; a1   - pointer to rawdata of brick
; a3   - pointer to position in playfield-data
; d0.w - height of brick
; d1.w - width of brick
  sub.l      a5,a5                                     ; a5 = row-counter for position-check
  move.l     a1,a4                                     ; a4 = pointer to rawdata of brick for position-check
.check_brick_position_row_loop:
  moveq.l    #0,d3                                     ; d3 = column-counter for position-check
.check_brick_position_column_loop:
  move.w     (a4)+,d2
  tst.b      d2
  beq.s      .check_brick_position_column_loop_next    ; brick element empty = okay
  move.b     (a3,d3.w),d2
  tst.b      d2
  bne.s      .check_brick_one_check_failed             ; this one brick cannot be placed at this one position = try next position
.check_brick_position_column_loop_next:
  addq.l     #1,d3
  cmp.b      d3,d1
  bne.s      .check_brick_position_column_loop

  addq.l     #8,a3
  addq.l     #2,a3
  addq.l     #1,a5
  cmp.l      a5,d0
  bne.s      .check_brick_position_row_loop

  ; arrived here, brick can be placed at checked position = game may proceed
  bra.s      .god_exit

.check_brick_one_check_failed:
  addq.l     #1,d4
  addq.l     #1,a3
  cmp.w      d4,d6
  bne.s      .check_brick_column_loop

  addq.l     #8,a2
  addq.l     #2,a2
  addq.l     #1,d5
  cmp.w      d5,d7
  bne.s      .check_brick_row_loop

  bra.s      .bricks_loop

.god_no_brick_is_placable:
  SETPTRS                                              ; because a4-a5 are used here

  move.b     #1,ig_om_gameover(a4)                     ; signal game over
  move.b     #50,ig_om_end_countdown(a4)

  ; play sfx
  SFX        f000_sfx_gameover

  ; init fade-out
  move.l     #f001_gfx_ingame_screen_colors,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  lea.l      ig_om_fade_color_tab(a4),a0
  moveq.l    #32,d0
  moveq.l    #1,d1
  bra        fade_init                                 ; indirect rts
  
.god_exit:
  SETPTRS                                              ; because a4-a5 are used here
  lea.l      god_last_check(pc),a0
  move.l     ig_om_framecounter(a4),(a0)
  rts

;
; vars
;
god_last_check:
  dc.l       0                                         ; frame number when last check was performed

  endif                                                ; ifnd GAME_OVER_DETECTION_ASM
