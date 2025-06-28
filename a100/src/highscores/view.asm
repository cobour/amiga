  ifnd        VIEW_HIGHSCORES_ASM
VIEW_HIGHSCORES_ASM equ 1

  include     "../a100/src/highscores/highscores.i"
  include     "../a100/src/highscores/sfx.i"
  include     "../common/src/system/blitter.i"
  include     "../a100/src/highscores/screen.i"

hs_view_save_background:
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #HsScreenWidthBytes-32,BLTAMOD(a6)                   ; modulos for source and target
  clr.w       BLTDMOD(a6)
  lea.l       hs_cm_textarea_restore_buffer(a5),a2                 ; pointers
  move.l      a2,BLTDPTH(a6)
  move.l      hs_om_backbuffer(a4),a2
  add.l       #HsOffsetOfTextArea,a2
  move.l      a2,BLTAPTH(a6)
  move.w      #(98*HsScreenBitPlanes<<6)+16,BLTSIZE(a6)            ; start blit
  rts

; in:
;   d1.b - zero = do not restore background ; any other value = restore background
hs_view_init:
  ; init gfx and mask pointers
  lea.l       hsv_font_metadata(pc),a3
  move.l      #f002_gfx_font16_2c,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      a1,(a3)+                                             ; metadata
  move.l      df_idx_ptr_rawdata(a0),d0
  move.l      d0,(a3)+                                             ; gfx
  add.l       df_iff_rawsize(a1),d0
  move.l      d0,(a3)                                              ; mask

  lea.l       hsv_restore_background_countdown(pc),a0
  tst.b       d1
  beq.s       .no_restore
  move.b      #2,(a0)
  bra.s       .go_on
.no_restore:
  clr.b       (a0)
.go_on:  
  cmp.b       #HsViewScreenYourScore,hs_om_view_screen(a4)
  beq.s       .show_your_score
  bsr.s       .init_score_table_string
  bra.s       .iv
.show_your_score
  bsr.s       .init_your_score
.iv:
  bsr.s       .init_values

  rts

.init_score_table_string:
  lea.l       hsv_scores_string(pc),a3
  move.l      hs_om_highscore_data_pointer(a4),a2
  moveq.l     #4,d7
.ists_create_string_loop:
  ; copy name
  move.l      (a2)+,(a3)+
  move.w      (a2)+,(a3)+
  ; add two spaces
  move.w      #$2020,(a3)+
  ; score
  move.l      (a2)+,d0
  bsr         bcd_to_string_of_8
  move.l      (a0)+,(a3)+
  move.l      (a0),(a3)+
  ; next row
  dbf         d7,.ists_create_string_loop
  rts

.init_your_score:
  move.l      c_om_score(a4),d0
  bsr         bcd_to_string_of_8
  lea.l       hsv_your_score+20(pc),a2
  move.l      (a0)+,(a2)+
  move.l      (a0),(a2)

  lea.l       hsv_your_score_end(pc),a2
  move.l      a2,d7
  lea.l       hsv_your_score(pc),a2
  sub.l       a2,d7
  subq.w      #1,d7
  lea.l       hsv_scores_string(pc),a3
.iys_loop:
  move.b      (a2)+,(a3)+
  dbf         d7,.iys_loop

  rts

.init_values:
  lea.l       hsv_scores_string(pc),a0
  lea.l       hsv_scores_next_char(pc),a1
  moveq.l     #0,d0
  move.l      a0,(a1)+                                             ; hsv_scores_next_char
  move.l      #HsOffsetOfTextArea,(a1)+                            ; hsv_draw_row_start_offset
  move.l      d0,(a1)+                                             ; hsv_draw_inner_row_offset
  move.b      d0,(a1)+                                             ; hsv_draw_buffer_counter
  move.b      #CursorWait,(a1)+                                    ; hsv_draw_cursor_wait
  move.b      #CursorUpdateDelay,(a1)+                             ; hsv_cursor_blink_delay
  move.b      #1,(a1)+                                             ; hsv_cursor_show
  move.l      d0,(a1)+                                             ; hsv_cursor_last_pos
  move.l      d0,(a1)+                                             ; hsv_cursor_last_pos (twice)
  move.l      #HsOffsetOfTextArea,(a1)                             ; hsv_cursor_offset_in_buffer

  move.l      hsv_font_gfx_ptr(pc),d0
  moveq.l     #118,d1
  add.l       d1,d0
  lea.l       hsv_draw_cursor_gfx(pc),a0
  move.l      d0,(a0)+                                             ; hsv_draw_cursor_gfx
  move.l      hsv_font_mask_ptr(pc),d0
  add.l       d1,d0
  move.l      d0,(a0)                                              ; hsv_draw_cursor_mask

  rts

hs_view_draw:
  ; is everything drawn?
  move.l      hsv_scores_next_char(pc),a0
  tst.b       (a0)
  bne.s       .check_restore

  ; check if HsViewScreenEditEntry must be set
  cmp.b       #HsViewScreenHighScoreTable,hs_om_view_screen(a4)
  bne         .exit
  tst.l       hs_om_new_entry_pointer(a4)
  beq         .exit
  move.b      #HsViewScreenEditEntry,hs_om_view_screen(a4)
  bra         .exit

.check_restore:
  ; is restore necessary?
  lea.l       hsv_restore_background_countdown(pc),a1
  tst.b       (a1)
  beq.s       .go_on

  ; restore background of printing area
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #HsScreenWidthBytes-32,BLTDMOD(a6)                   ; modulos for source and target
  clr.w       BLTAMOD(a6)
  lea.l       hs_cm_textarea_restore_buffer(a5),a2                 ; pointers
  move.l      a2,BLTAPTH(a6)
  move.l      hs_om_backbuffer(a4),a2
  add.l       #HsOffsetOfTextArea,a2
  move.l      a2,BLTDPTH(a6)
  move.w      #(98*HsScreenBitPlanes<<6)+16,BLTSIZE(a6)            ; start blit

  sub.b       #1,(a1)
  bra         .exit
.go_on:
  ; restore cursor background at old position
  move.l      hsv_cursor_last_pos+4(pc),d0
  tst.l       d0
  beq.s       .no_cursor_restore
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #HsScreenWidthBytes-2,BLTDMOD(a6)                    ; modulos for source and target
  clr.w       BLTAMOD(a6)
  lea.l       hs_cm_cursor_restore_buffer(a5),a2                   ; pointers
  move.l      a2,BLTAPTH(a6)
  move.l      hsv_cursor_last_pos+4(pc),BLTDPTH(a6)
  move.w      #(16*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)             ; start blit
  lea.l       hsv_cursor_last_pos+4(pc),a1
  clr.l       (a1)

.no_cursor_restore:
  ; cursor or char draw?
  lea.l       hsv_draw_cursor_wait(pc),a1
  tst.b       (a1)
  beq         .draw_char
  sub.b       #1,(a1)

  ; save cursor background
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #HsScreenWidthBytes-2,BLTAMOD(a6)                    ; modulos for source and target
  clr.w       BLTDMOD(a6)
  lea.l       hs_cm_cursor_restore_buffer(a5),a2                   ; pointers
  move.l      a2,BLTDPTH(a6)
  move.l      hs_om_backbuffer(a4),d1
  add.l       hsv_cursor_offset_in_buffer(pc),d1
  move.l      d1,BLTAPTH(a6)
  move.w      #(16*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)             ; start blit
  lea.l       hsv_cursor_last_pos(pc),a3
  move.l      (a3),4(a3)
  move.l      d1,(a3)

  ; use CursorUpdateDelay to decide whether to draw cursor or not (make it blink)
  lea.l       hsv_cursor_blink_delay(pc),a3
  tst.b       (a3)
  bne.s       .show_cursor_or_not
  ; switch between show and not show (blink)
  move.b      #CursorUpdateDelay,(a3)
  move.b      1(a3),d1
  bchg        #0,d1
  move.b      d1,1(a3)
  tst.b       d1
  beq.s       .show_cursor_or_not
  SFX         f002_sfx_tick
.show_cursor_or_not:
  sub.b       #1,(a3)
  tst.b       1(a3)
  beq         .exit

  ; draw_cursor
  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d7
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  move.l      hsv_font_metadata(pc),a1
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #HsScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; source pointers
  move.l      hsv_draw_cursor_mask(pc),BLTAPTH(a6)
  move.l      hsv_draw_cursor_gfx(pc),BLTBPTH(a6)

  ; destination pointers
  move.l      hs_om_backbuffer(a4),d1
  add.l       hsv_cursor_offset_in_buffer(pc),d1
  move.l      d1,BLTCPTH(a6)
  move.l      d1,BLTDPTH(a6)

  ; start blit
  move.w      #(12*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)

  bra         .exit

.draw_char:
  moveq.l     #0,d0
  move.b      (a0),d0

  ; calc offset for char
  sub.b       #$20,d0
  add.w       d0,d0
  tst.w       d0
  beq.s       .no_print_sfx
  SFX         f002_sfx_print
.no_print_sfx:
  move.l      hsv_font_metadata(pc),a1
  move.l      hsv_font_gfx_ptr(pc),d1
  add.l       d0,d1                                                ; d1 = gfx pointer
  move.l      hsv_font_mask_ptr(pc),d2
  add.l       d0,d2                                                ; d2 = mask pointer
  move.l      hs_om_backbuffer(a4),d3
  add.l       hsv_draw_row_start_offset(pc),d3
  add.l       hsv_draw_inner_row_offset(pc),d3                     ; d3 = target pointer

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
  move.w      #HsScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; source pointers
  move.l      d2,BLTAPTH(a6)
  move.l      d1,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(12*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)

.upd_pointers_and_offsets:
  lea.l       hsv_draw_buffer_counter(pc),a1
  add.b       #1,(a1)
  cmp.b       #2,(a1)
  bne.s       .exit

  ; actual char drawn to both buffers - switch to next char
  clr.b       (a1)
  lea.l       hsv_scores_next_char(pc),a0
  moveq.l     #1,d0
  add.l       d0,(a0)

  ; update offsets for next char
  lea.l       hsv_draw_row_start_offset(pc),a0
  lea.l       hsv_draw_inner_row_offset(pc),a1
  moveq.l     #2,d0
  add.l       d0,(a1)
  cmp.l       #MaxInnerRowOffset,(a1)
  blt.s       .exit
  ; new row
  moveq.l     #0,d0
  move.w      d0,2(a1)
  add.l       #HsTextAreaLineAdd,(a0)
  lea.l       hsv_draw_cursor_wait(pc),a1
  move.b      #CursorWait,(a1)
  lea.l       hsv_cursor_offset_in_buffer(pc),a2
  add.l       #HsTextAreaLineAdd,(a2)
  lea.l       hsv_cursor_last_pos(pc),a2
  move.l      d0,(a2)+
  move.l      d0,(a2)

.exit:
  rts

;
; constant values
;

hsv_your_score:
  dc.b        " YOUR SCORE WAS "
  dc.b        "    XXXXXXXX    "
  dc.b        0,0
hsv_your_score_end:

;
; vars (initialized by hs_view_init)
;

RowLength           equ 6+2+8                                      ; 6 chars = name ; 2 spaces ; 8 chars = score
MaxInnerRowOffset   equ RowLength*2                                ; max value for hsv_draw_inner_row_offset
CursorWait          equ 90
CursorUpdateDelay   equ CursorWait/6

hsv_font_metadata:
  dc.l        0

hsv_font_gfx_ptr:
  dc.l        0

hsv_font_mask_ptr:
  dc.l        0

hsv_scores_string:
  dcb.b       RowLength*5           
  dc.w        0                                   

hsv_scores_next_char:
  dc.l        0

hsv_draw_row_start_offset:
  dc.l        0

hsv_draw_inner_row_offset:
  dc.l        0

hsv_draw_buffer_counter:
  dc.b        0                                                    ; draw when this is 0 or 1; then reset to 0 and draw next char

hsv_draw_cursor_wait:
  dc.b        0

hsv_cursor_blink_delay:
  dc.b        0

hsv_cursor_show:
  dc.b        0

hsv_cursor_last_pos:
  dc.l        0                                                    ; for both framebuffers, absolute pointers (no offsets)
  dc.l        0

hsv_cursor_offset_in_buffer:
  dc.l        0

hsv_draw_cursor_gfx:
  dc.l        0

hsv_draw_cursor_mask:
  dc.l        0

hsv_restore_background_countdown:
  dc.b        0
.padding_byte:
  dc.b        0

  endif                                                            ; ifnd VIEW_HIGHSCORES_ASM
