  ifnd       EDIT_HIGHSCORES_ASM
EDIT_HIGHSCORES_ASM equ 1

  include    "../a100/src/highscores/sfx.i"

hse_init:
  moveq.l    #0,d0
  lea.l      hse_char_count(pc),a0
  move.w     d0,(a0)
  rts

hse_update:
  rts

hse_process_events:
  cmp.b      #HsViewScreenEditEntry,hs_om_view_screen(a4)
  bne.s      .exit

.process_event:
  bsr        ev_get_next_event
  tst.b      d0
  blt.s      .exit

  cmp.b      #EventSelect,d0
  bne.s      .pe_check_unselect
  bra.s      .pe_handle_select

.pe_check_unselect:
  cmp.b      #EventUnselect,d0
  bne.s      .pe_check_char
  bra.s      .pe_handle_unselect

.pe_check_char:
  cmp.b      #$40,d0
  ble.s      .pe_handle_char

  bra.s      .process_event

.exit:
  rts

.pe_handle_select:
  ; name input finished, switch back to view of table
  move.b     #HsViewScreenHighScoreTable,hs_om_view_screen(a4)
  move.b     #1,hs_om_save_on_exit(a4)
  ; replace dots in table with spaces
  move.l     hs_om_new_entry_pointer(a4),a1
.pehs_loop:
  cmp.b      #'.',(a1)
  bne.s      .pehs_loop_end
  move.b     #' ',(a1)+
  bra.s      .pehs_loop
.pehs_loop_end:
  ; clear vars
  moveq.l    #0,d0
  move.l     d0,hs_om_new_entry_pointer(a4)
  move.b     d0,hs_om_new_entry_index(a4)
  SFX        f002_sfx_enter
  bra.s      .exit

.pe_handle_unselect:
  lea.l      hse_char_count(pc),a0
  tst.b      (a0)
  bgt.s      .pehu_remove_char
  SFX        f002_sfx_error
  bra.s      .process_event
.pehu_remove_char:
  sub.b      #1,(a0)
  ; replace char in table with dot
  move.l     hs_om_new_entry_pointer(a4),a1
  subq.l     #1,a1
  move.b     #'.',(a1)
  move.l     a1,hs_om_new_entry_pointer(a4)
  ; TODO: remove char gfx (same routine for remove and add; just restore background and print char at position, use hs_om_new_entry_pointer(a4) and hse_char_count(pc) to determine char and position)
  SFX        f002_sfx_delete
  bra        .process_event

.pe_handle_char:
  lea.l      hse_char_count(pc),a0
  cmp.b      #6,(a0)
  blt.s      .pehc_add_char
  SFX        f002_sfx_error
  bra        .process_event
.pehc_add_char:
  add.b      #1,(a0)
  ; set char in table
  move.l     hs_om_new_entry_pointer(a4),a1
  bsr.s      .keycode_to_char
  move.b     d0,(a1)+
  move.l     a1,hs_om_new_entry_pointer(a4)
  ; TODO: add char gfx (same routine for remove and add; just restore background and print char at position, use hs_om_new_entry_pointer(a4) and hse_char_count(pc) to determine char and position)
  SFX        f002_sfx_print
  bra        .process_event

; in:  d0.b
; out: d0.b
.keycode_to_char:
  lea        .tab(pc),a2
.k2c_loop:
  cmp.b      (a2),d0
  beq.s      .k2c_found
  addq.l     #2,a2
  cmp.b      #$ff,(a2)
  bne.s      .k2c_loop
.k2c_found:
  move.b     1(a2),d0
  rts

.tab:
  dc.b       $10,'Q'
  dc.b       $11,'W'
  dc.b       $12,'E'
  dc.b       $13,'R'
  dc.b       $14,'T'
  dc.b       $15,'Y'
  dc.b       $16,'U'
  dc.b       $17,'I'
  dc.b       $18,'O'
  dc.b       $19,'P'
  dc.b       $20,'A'
  dc.b       $21,'S'
  dc.b       $22,'D'
  dc.b       $23,'F'
  dc.b       $24,'G'
  dc.b       $25,'H'
  dc.b       $26,'J'
  dc.b       $27,'K'
  dc.b       $28,'L'
  dc.b       $31,'Z'
  dc.b       $32,'X'
  dc.b       $33,'C'
  dc.b       $34,'V'
  dc.b       $35,'B'
  dc.b       $36,'N'
  dc.b       $37,'M'
  dc.b       $40,' '
  dc.w       $ffff                                                ; end of list

  
  ; TODO: using hs_om_new_entry_index(a4) and hs_om_new_entry_pointer(a4)
  ;       let the user enter his name
  ;       switch to HsViewScreenEditEntry when drawing of table is done
  ;       when HsViewScreenEditEntry is set, edit.asm takes control of the users input
  ;       set hs_om_save_on_exit(a4) to save
  ;       let dot blick as cursor, stop blinking when switching back to view-mode

;
; vars
;

hse_char_count:
  dc.b       0
.filler:
  dc.b       0

  endif                                                           ; ifnd EDIT_HIGHSCORES_ASM
