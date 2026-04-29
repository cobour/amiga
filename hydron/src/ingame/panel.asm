  ifnd       INGAME_PANEL_ASM
INGAME_PANEL_ASM equ 1

  include    "src/ingame.i"
  include    "src/ingame/panel.i"

; inits panel (should be called once before game loop)
panel_init:
  movem.l    d0-a6,-(sp)

  ; init copper colors
  move.l     #"PACO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     ig_om_copperlist_front(a4),a1
  lea.l      ig_cm_cl_panel+6(a1),a1
  moveq.l    #15,d7
.pi_cols_loop:
  move.w     (a0)+,(a1)
  lea.l      panel_clrow_sizeof(a1),a1
  dbf        d7,.pi_cols_loop

  ; init label texts
  move.l     ig_om_copperlist_front(a4),a3
  lea.l      ig_cm_cl_panel(a3),a3

  move.l     #"PAHI",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a2

  move.l     #"PASC",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1

  move.l     #"PALI",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0

  moveq.l    #9,d7                                ; 10 rows
.pi_loop:
  move.w     (a0)+,panel_clrow_lives_0+6(a3)
  move.w     (a0)+,panel_clrow_lives_1+6(a3)

  move.w     (a1)+,panel_clrow_score_0+6(a3)
  move.w     (a1)+,panel_clrow_score_1+6(a3)
  move.w     (a1)+,panel_clrow_score_2+6(a3)

  move.w     (a2)+,panel_clrow_hiscore_0+6(a3)
  move.w     (a2)+,panel_clrow_hiscore_1+6(a3)
  move.w     (a2)+,panel_clrow_hiscore_2+6(a3)

  lea.l      panel_clrow_sizeof(a3),a3
  dbf        d7,.pi_loop
  move.l     a3,ig_om_panel_cl_pointer(a4)
  
  ; init data
  move.l     #"PAFO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a0,ig_om_panel_font_pointer(a4)
  clr.b      ig_om_panel_redraw_lives(a4)
  clr.b      ig_om_panel_redraw_score(a4)

  ; initial draw of values  
  bsr        panel_draw_lives
  bsr        panel_draw_score
  bsr        panel_draw_hiscore

  movem.l    (sp)+,d0-a6
  rts

; updates panel values if necessary (should be called each frame)
panel_update:
  movem.l    d0-d2/a0-a3,-(sp)

  tst.b      ig_om_panel_redraw_lives(a4)
  beq.s      .check_score
  bsr.s      panel_draw_lives
  clr.b      ig_om_panel_redraw_lives(a4)

.check_score:
  tst.b      ig_om_panel_redraw_score(a4)
  beq.s      .exit
  bsr        panel_draw_score
  move.l     c_om_hiscore(a4),d0
  cmp.l      c_om_score(a4),d0
  bge.s      .no_hiscore_update
  move.l     c_om_score(a4),c_om_hiscore(a4)
  bsr        panel_draw_hiscore
.no_hiscore_update:
  clr.b      ig_om_panel_redraw_score(a4)

.exit:
  movem.l    (sp)+,d0-d2/a0-a3
  rts

; INTERNAL USE ONLY
panel_draw_lives:
  move.b     c_om_lives(a4),d0
  bsr        bcd_to_string_of_2                   ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  move.l     ig_om_panel_cl_pointer(a4),a1
  moveq.l    #10,d1                               ; modulo of font
  moveq.l    #0,d2

  move.b     (a0)+,d2
  lea.l      panel_clrow_lives_0+7(a1),a3
  bsr        panel_print_digit

  move.b     (a0),d2
  lea.l      panel_clrow_lives_1+6(a1),a3
  bsr        panel_print_digit

  rts

; INTERNAL USE ONLY
panel_draw_score:
  move.l     c_om_score(a4),d0
  bsr        bcd_to_string_of_6                   ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  move.l     ig_om_panel_cl_pointer(a4),a1
  moveq.l    #10,d1                               ; modulo of font
  moveq.l    #0,d2

  move.b     (a0)+,d2
  lea.l      panel_clrow_score_0+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_score_0+7(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_score_1+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_score_1+7(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_score_2+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0),d2
  lea.l      panel_clrow_score_2+7(a1),a3
  bsr        panel_print_digit

  rts

; INTERNAL USE ONLY
panel_draw_hiscore:
  move.l     c_om_hiscore(a4),d0
  bsr        bcd_to_string_of_6                   ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  move.l     ig_om_panel_cl_pointer(a4),a1
  moveq.l    #10,d1                               ; modulo of font
  moveq.l    #0,d2

  move.b     (a0)+,d2
  lea.l      panel_clrow_hiscore_0+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_hiscore_0+7(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_hiscore_1+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_hiscore_1+7(a1),a3
  bsr        panel_print_digit

  move.b     (a0)+,d2
  lea.l      panel_clrow_hiscore_2+6(a1),a3
  bsr        panel_print_digit

  move.b     (a0),d2
  lea.l      panel_clrow_hiscore_2+7(a1),a3
  bsr        panel_print_digit

  rts

; INTERNAL USE ONLY
; in:
;   d2.b  ascii of digit to print
;   d0    pointer to rawdata of font
;   d1    modulo of font
;   a3    pointer to first position in copperlist
panel_print_digit:
  sub.b      #$30,d2                              ; ascii value of zero char
  move.l     d0,a2
  add.l      d2,a2

  move.b     (a2),(a3)
  add.l      d1,a2
  lea.l      panel_clrow_sizeof(a3),a3

  move.b     (a2),(a3)
  add.l      d1,a2
  lea.l      panel_clrow_sizeof(a3),a3

  move.b     (a2),(a3)
  add.l      d1,a2
  lea.l      panel_clrow_sizeof(a3),a3

  move.b     (a2),(a3)
  add.l      d1,a2
  lea.l      panel_clrow_sizeof(a3),a3

  move.b     (a2),(a3)
  add.l      d1,a2
  lea.l      panel_clrow_sizeof(a3),a3

  move.b     (a2),(a3)

  rts

  endif                                           ; ifnd INGAME_PANEL_ASM
