  ifnd        EDIT_HIGHSCORES_ASM
EDIT_HIGHSCORES_ASM equ 1

  include     "../a100/src/highscores/highscores.i"
  include     "../a100/src/highscores/sfx.i"
  include     "../common/src/system/blitter.i"
  include     "../a100/src/highscores/screen.i"

hse_init:
  moveq.l     #0,d0
  lea.l       hse_char_count(pc),a0
  move.w      d0,(a0)+
  move.l      d0,(a0)+
  move.l      d0,(a0)
  rts

hse_update:
  moveq.l     #0,d0
  moveq.l     #0,d1
  bsr         hse_print_char

  bsr         hse_print_cursor

  rts

hse_process_events:
  cmp.b       #HsViewScreenEditEntry,hs_om_view_screen(a4)
  bne.s       .exit

  ; only one event per frame !

.process_event:
  moveq.l     #0,d0
  bsr         ev_get_next_event
  tst.b       d0
  blt.s       .exit

  cmp.b       #EventSelect,d0
  bne.s       .pe_check_unselect
  bra.s       .pe_handle_select

.pe_check_unselect:
  cmp.b       #EventUnselect,d0
  bne.s       .pe_check_char
  bra.s       .pe_handle_unselect

.pe_check_char:
  cmp.b       #$40,d0
  ble         .pe_handle_char

  bra.s       .process_event

.exit:
  rts

.pe_handle_select:
  ; name input finished, switch back to view of table
  move.b      #HsViewScreenHighScoreTable,hs_om_view_screen(a4)
  move.b      #1,hs_om_save_on_exit(a4)
  ; replace dots in table with spaces
  move.l      hs_om_new_entry_pointer(a4),a1
.pehs_loop:
  cmp.b       #'.',(a1)
  bne.s       .pehs_loop_end
  move.b      #' ',(a1)+
  bra.s       .pehs_loop
.pehs_loop_end:
  ; clear vars
  moveq.l     #0,d0
  move.l      d0,hs_om_new_entry_pointer(a4)
  ; do not clear hs_om_new_entry_index(a4) - still needed for clearance of dots
  SFX         f002_sfx_enter
  bra.s       .exit

.pe_handle_unselect:
  lea.l       hse_char_count(pc),a0
  tst.b       (a0)
  bgt.s       .pehu_remove_char
  SFX         f002_sfx_error
  bra.s       .process_event
.pehu_remove_char:
  sub.b       #1,(a0)
  ; replace char in table with dot
  move.l      hs_om_new_entry_pointer(a4),a1
  subq.l      #1,a1
  move.b      #'.',(a1)
  move.l      a1,hs_om_new_entry_pointer(a4)
  moveq.l     #0,d1
  move.b      (a0),d1
  move.b      #'.',d0
  bsr         hse_print_char
  SFX         f002_sfx_delete
  lea.l       hse_cursor_back_restore_count(pc),a0
  move.b      #2,(a0)
  bra         .exit

.pe_handle_char:
  lea.l       hse_char_count(pc),a0
  cmp.b       #6,(a0)
  blt.s       .pehc_add_char
  SFX         f002_sfx_error
  bra         .process_event
.pehc_add_char:
  add.b       #1,(a0)
  ; set char in table
  move.l      hs_om_new_entry_pointer(a4),a1
  bsr.s       .keycode_to_char
  move.b      d0,(a1)+
  move.l      a1,hs_om_new_entry_pointer(a4)
  moveq.l     #0,d1
  move.b      (a0),d1
  subq.b      #1,d1
  bsr         hse_print_char
  SFX         f002_sfx_print
  bra         .exit

; in:  d0.b
; out: d0.b
.keycode_to_char:
  lea         .tab(pc),a2
.k2c_loop:
  cmp.b       (a2),d0
  beq.s       .k2c_found
  addq.l      #2,a2
  cmp.b       #$ff,(a2)
  bne.s       .k2c_loop
.k2c_found:
  move.b      1(a2),d0
  rts

.tab:
  dc.b        $10,'Q'
  dc.b        $11,'W'
  dc.b        $12,'E'
  dc.b        $13,'R'
  dc.b        $14,'T'
  dc.b        $15,'Y'
  dc.b        $16,'U'
  dc.b        $17,'I'
  dc.b        $18,'O'
  dc.b        $19,'P'
  dc.b        $20,'A'
  dc.b        $21,'S'
  dc.b        $22,'D'
  dc.b        $23,'F'
  dc.b        $24,'G'
  dc.b        $25,'H'
  dc.b        $26,'J'
  dc.b        $27,'K'
  dc.b        $28,'L'
  dc.b        $31,'Z'
  dc.b        $32,'X'
  dc.b        $33,'C'
  dc.b        $34,'V'
  dc.b        $35,'B'
  dc.b        $36,'N'
  dc.b        $37,'M'
  dc.b        $40,' '
  dc.w        $ffff                                                ; end of list

hse_print_cursor:
  tst.b       hs_om_save_on_exit(a4)
  beq.s       .not_exiting

  ; clearing dots when exiting
  move.b      hse_char_count(pc),d6
.clear_dots_loop:
  moveq.l     #0,d0
  moveq.l     #0,d1
  move.b      #' ',d0
  move.b      d6,d1
  bsr.s       hse_print_char_do
  add.b       #1,d6
  cmp.b       #6,d6
  blt.s       .clear_dots_loop
  rts

.not_exiting:
  cmp.b       #HsViewScreenEditEntry,hs_om_view_screen(a4)
  bne.s       .exit

  moveq.l     #0,d0
  moveq.l     #0,d1

  lea.l       hse_cursor_back_restore_count(pc),a0
  tst.b       (a0)
  beq.s       .no_cursor_restore
  sub.b       #1,(a0)
  move.b      hse_char_count(pc),d1
  add.b       #1,d1
  cmp.b       #5,d1
  bgt.s       .no_cursor_restore
  move.b      #'.',d0
  bsr.s       hse_print_char_do
    
.no_cursor_restore:

  moveq.l     #0,d1                                                ; because "bsr.s hse_print_char_do" modifies d1, moving a 24bit value into it
  move.b      hse_char_count(pc),d1
  cmp.b       #6,d1
  bge.s       .exit

  move.l      c_om_framecounter(a4),d2
  btst        #0,d2
  bne.s       .0
  move.b      #' ',d0
  bra.s       .1
.0:
  move.b      #'.',d0
.1:
  
  bra.s       hse_print_char_do                                    ; implicit rts

.exit:
  rts

; in:
;   d0 - char to print (ascii)
;   d1 - index of char to print (NOT same as hse_char_count(pc), because that is already incremented od decremented)
hse_print_char:
  lea.l       hse_reprint_char_params(pc),a0

  tst.b       d0
  bne.s       .1st_run

  ; restore params from 1st run and clear in mem
  move.l      (a0),d0
  tst.l       d0
  beq         .exit
  move.l      4(a0),d1
  moveq.l     #0,d4
  move.l      d4,(a0)
  move.l      d4,4(a0)
  bra.s       hse_print_char_do

.1st_run:
  ; save params for 2nd run
  move.l      d0,(a0)+
  move.l      d1,(a0)
  bra.s       hse_print_char_do
.exit:
  rts

; in:
;   d0 - char to print (ascii)
;   d1 - index of char to print
hse_print_char_do:
  moveq.l     #0,d4
  move.b      hs_om_new_entry_index(a4),d4
  add.w       d4,d4
  add.w       d4,d4
  lea.l       .pc_line_offset_tab_screenbuffer(pc),a0
  move.l      (a0,d4.w),d2
  add.l       #HsOffsetOfTextArea,d2                               ; target offset in screenbuffer (begin of line)
  add.w       d1,d1
  add.l       d1,d2                                                ; target offset in screenbuffer (char to print)
  add.l       hs_om_backbuffer(a4),d2                              ; target pointer

  ; restore background
  lea.l       .pc_line_offset_tab_restorebuffer(pc),a0
  move.l      (a0,d4.w),d3
  add.l       d1,d3
  add.l       a5,d3
  add.l       #hs_cm_textarea_restore_buffer,d3                    ; source pointer for restore

  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d4                                            ; no first/last word mask
  move.w      d4,BLTAFWM(a6)
  move.w      d4,BLTALWM(a6)
  move.w      #30,BLTAMOD(a6)                                      ; modulos for source and target
  move.w      #HsScreenWidthBytes-2,BLTDMOD(a6)
  move.l      d3,BLTAPTH(a6)
  move.l      d2,BLTDPTH(a6)
  move.w      #(16*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)             ; start blit
  
  ; print char
  sub.b       #$20,d0                                              ; ascii - $20 => number of char in font
  add.w       d0,d0                                                ; offset of char to print in font
  move.l      hsv_font_mask_ptr(pc),d1
  add.l       d0,d1                                                ; mask source pointer BLTA
  move.l      hsv_font_gfx_ptr(pc),d3
  add.l       d0,d3                                                ; gfx source pointer BLTB
  move.l      hsv_font_metadata(pc),a1
  move.w      df_iff_width(a1),d0
  lsr.w       #3,d0
  subq.w      #2,d0                                                ; source modulo BLTA + BLTB

  WAIT_BLT
  moveq.l     #-1,d7                                               ; no first/last word mask
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)                       ; no pixel shift; masked copy
  clr.w       BLTCON1(a6)
  move.w      d0,BLTAMOD(a6)                                       ; modulos
  move.w      d0,BLTBMOD(a6)
  move.w      #HsScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)
  move.l      d1,BLTAPTH(a6)                                       ; pointers
  move.l      d3,BLTBPTH(a6)
  move.l      d2,BLTCPTH(a6)
  move.l      d2,BLTDPTH(a6)
  move.w      #(12*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)             ; start blit

  rts

.pc_line_offset_tab_screenbuffer:
  dc.l        HsTextAreaLineAdd*0
  dc.l        HsTextAreaLineAdd*1
  dc.l        HsTextAreaLineAdd*2
  dc.l        HsTextAreaLineAdd*3
  dc.l        HsTextAreaLineAdd*4

.pc_line_offset_tab_restorebuffer:
  dc.l        32*HsScreenBitPlanes*20*0
  dc.l        32*HsScreenBitPlanes*20*1
  dc.l        32*HsScreenBitPlanes*20*2
  dc.l        32*HsScreenBitPlanes*20*3
  dc.l        32*HsScreenBitPlanes*20*4

;
; vars
;

hse_char_count:
  dc.b        0
hse_cursor_back_restore_count:
  dc.b        0

hse_reprint_char_params:
  dc.l        0
  dc.l        0

  endif                                                            ; ifnd EDIT_HIGHSCORES_ASM
