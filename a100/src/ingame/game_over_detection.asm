  ifnd       GAME_OVER_DETECTION_ASM
GAME_OVER_DETECTION_ASM equ 1

  ifnd       UNITTEST

  include    "../a100/src/globals.i"
  include    "../a100/src/ingame/sfx.i"

god_init:
  clr.b      ig_om_god_request(a4)
  rts

; must be triggered with ig_om_god_request when brick selectors are refilled 
; and when a brick is placed on the playfield
game_over_detection:

  ; check if necessary/allowed
  tst.b      ig_om_god_request(a4)
  beq        .god_exit
  tst.b      ig_om_clearance_in_progress(a4)
  bne        .god_exit
  clr.b      ig_om_god_request(a4)

  ; get list of all selectable bricks and set pointer to playfield-data
  bsr        bs_get_selectable_bricks
  lea.l      pf_data(pc),a2

  ; check if any of the bricks is placable on the playfield
.bricks_loop:
  tst.l      (a0)
  beq.s      .god_no_brick_is_placable
  move.l     (a0)+,a1

  move.l     df_idx_ptr_rawdata(a1),a3
  lea.l      df_idx_metadata(a1),a1
  move.w     df_tld_plf_height(a1),d0
  move.w     df_tld_plf_width(a1),d1
  move.l     a3,a1
  bsr.s      .check_one_brick
  tst.b      d2
  bne.s      .god_exit

  bra.s      .bricks_loop

  ; no brick can be placed on the playfield => game over
.god_no_brick_is_placable:
  SETPTRS                                            ; restore a4-a6
  move.b     #1,ig_om_gameover(a4)                   ; signal game over
  move.b     #50,ig_om_end_countdown(a4)

  ; play sfx
  SFX        f000_sfx_gameover

  ; clear savegame
  move.b     #1,ig_om_clear_savegame(a4)

  ; init fade-out
  move.l     #f001_gfx_ingame_screen_2a_colors,d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  lea.l      ig_om_fade_color_tab(a4),a0
  moveq.l    #32,d0
  moveq.l    #1,d1
  bra        fade_init                               ; indirect rts
  
  ; any of the bricks can be placed on the playfield => all fine
.god_exit:
  SETPTRS                                            ; restore a4-a6
  rts

  endif                                              ; ifnd UNITTEST

  ifd        UNITTEST
unittest_check_one_brick:
  endif                                              ; ifd UNITTEST

; checks all possible positions on the playfield for one brick
; in:
;   a1 - rawdata of brick
;   a2 - playfield-data
;   d0 - height of brick
;   d1 - width of brick
; out:
;   d2 - boolean: is brick placable?
.check_one_brick:
  moveq.l    #0,d2
  moveq.l    #10,d7
  sub.b      d0,d7
  move.l     a2,a3
.cob_rows_loop:
  moveq.l    #10,d6
  sub.b      d1,d6
  move.l     a3,a4
.cob_columns_loop:
  bsr.s      .check_one_brick_one_position
  tst.b      d2
  bne.s      .cob_exit
  addq.l     #1,a4
  dbf        d6,.cob_columns_loop
  add.l      #10,a3
  dbf        d7,.cob_rows_loop
.cob_exit:
  rts

; checks one possible position on the playfield for one brick
; in:
;   a1 - rawdata of brick
;   a4 - playfield-data
;   d0 - height of brick
;   d1 - width of brick
; out:
;   d2 - boolean: is brick placable?
.check_one_brick_one_position:
  move.w     d0,d5
  subq.w     #1,d5
  move.l     a4,a5
  moveq.l    #0,d2
.cobop_rows_loop:
  move.w     d1,d4
  subq.w     #1,d4
  move.l     a5,a6
.cobop_columns_loop:
  move.w     (a1,d2.w),d3
  tst.b      d3
  beq.s      .cobop_columns_loop_next                ; brick element empty => next
  move.b     (a6),d3
  tst.b      d3
  beq.s      .cobop_columns_loop_next
  moveq.l    #0,d2                                   ; brick element not empty and playfield element not empty => brick not placable at this position
  rts
.cobop_columns_loop_next:
  addq.w     #2,d2
  addq.l     #1,a6
  dbf        d4,.cobop_columns_loop
  add.l      #10,a5
  dbf        d5,.cobop_rows_loop
  moveq.l    #1,d2
  rts

  endif                                              ; ifnd GAME_OVER_DETECTION_ASM
