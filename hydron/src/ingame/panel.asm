  ifnd       INGAME_PANEL_ASM
INGAME_PANEL_ASM equ 1

  include    "src/ingame.i"

; inits panel (should be called once before game loop)
panel_init:
  ; init both copperlists
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a1
  bsr        .init_sub
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a1
  bsr        .init_sub
  
  ; init ig_om_panel_backup_for_fade and clear data in both copperlists
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a1
  lea.l      ig_cm_cl_panel(a1),a1
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a3
  lea.l      ig_cm_cl_panel(a3),a3
  lea.l      ig_om_panel_backup_for_fade(a4),a2
  moveq.l    #15,d7
.pi_backup_loop:
  move.w     panel_clrow_lives_0+6(a1),(a2)+
  move.w     panel_clrow_lives_1+6(a1),(a2)+
  move.w     panel_clrow_score_0+6(a1),(a2)+
  move.w     panel_clrow_score_1+6(a1),(a2)+
  move.w     panel_clrow_score_2+6(a1),(a2)+
  move.w     panel_clrow_hiscore_0+6(a1),(a2)+
  move.w     panel_clrow_hiscore_1+6(a1),(a2)+
  move.w     panel_clrow_hiscore_2+6(a1),(a2)+
  clr.w      panel_clrow_lives_0+6(a1)
  clr.w      panel_clrow_lives_1+6(a1)
  clr.w      panel_clrow_score_0+6(a1)
  clr.w      panel_clrow_score_1+6(a1)
  clr.w      panel_clrow_score_2+6(a1)
  clr.w      panel_clrow_hiscore_0+6(a1)
  clr.w      panel_clrow_hiscore_1+6(a1)
  clr.w      panel_clrow_hiscore_2+6(a1)
  clr.w      panel_clrow_lives_0+6(a3)
  clr.w      panel_clrow_lives_1+6(a3)
  clr.w      panel_clrow_score_0+6(a3)
  clr.w      panel_clrow_score_1+6(a3)
  clr.w      panel_clrow_score_2+6(a3)
  clr.w      panel_clrow_hiscore_0+6(a3)
  clr.w      panel_clrow_hiscore_1+6(a3)
  clr.w      panel_clrow_hiscore_2+6(a3)
  lea.l      panel_clrow_sizeof(a1),a1
  lea.l      panel_clrow_sizeof(a3),a3
  dbf        d7,.pi_backup_loop

  rts

.init_sub:
  move.l     a1,a3
  move.l     a1,-(sp)

  ; clear copper colors
  lea.l      ig_cm_cl_panel+6(a1),a1
  moveq.l    #15,d7
.pi_cols_loop:
  clr.w      (a1)
  lea.l      panel_clrow_sizeof(a1),a1
  dbf        d7,.pi_cols_loop

  ; init label texts
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

  moveq.l    #9,d7                                                    ; 10 rows
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
  move.l     (sp)+,a1
  sub.l      a1,a3
  move.l     a3,ig_om_panel_cl_offset(a4)                             ; offset in copperlist is needed, not absolute address
  
  ; init data
  move.l     #"PAFO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a0,ig_om_panel_font_pointer(a4)
  clr.b      ig_om_panel_redraw_lives(a4)
  clr.b      ig_om_panel_redraw_score(a4)

  ; initial draw of values
  move.l     a1,-(sp)
  bsr        panel_draw_lives
  move.l     (sp),a1
  bsr        panel_draw_score
  move.l     (sp)+,a1
  bsr        panel_draw_hiscore

  rts

panel_set_colors:
  move.l     #"PACO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     ig_om_buffer_one+ig_buffers_copperlist_pointer(a4),a1
  lea.l      ig_cm_cl_panel+6(a1),a1
  move.l     ig_om_buffer_two+ig_buffers_copperlist_pointer(a4),a2
  lea.l      ig_cm_cl_panel+6(a2),a2
  moveq.l    #15,d7
.pi_cols_loop:
  move.w     (a0),(a1)
  move.w     (a0),(a2)
  addq.l     #2,a0
  lea.l      panel_clrow_sizeof(a1),a1
  lea.l      panel_clrow_sizeof(a2),a2
  dbf        d7,.pi_cols_loop
  rts

; updates panel values if necessary (should be called each frame)
panel_update:
  ; no update while fading
  tst.b      ig_om_fade_in_step(a4)
  bge.s      .exit_no_update
  tst.b      ig_om_fade_out_step(a4)
  bge.s      .exit_no_update

  movem.l    d0-d2/a0-a3,-(sp)

  tst.b      ig_om_panel_redraw_lives(a4)
  beq.s      .check_score
  move.l     ig_om_buffers_backbuffer(a4),a0
  move.l     ig_buffers_copperlist_pointer(a0),a1
  bsr.s      panel_draw_lives
  clr.b      ig_om_panel_redraw_lives(a4)

.check_score:
  tst.b      ig_om_panel_redraw_score(a4)
  beq.s      .exit
  move.l     ig_buffers_copperlist_pointer(a0),a1
  bsr        panel_draw_score
  move.l     c_om_hiscore(a4),d0
  cmp.l      c_om_score(a4),d0
  bge.s      .no_hiscore_update
  move.l     c_om_score(a4),c_om_hiscore(a4)
  move.l     ig_buffers_copperlist_pointer(a0),a1
  bsr        panel_draw_hiscore
.no_hiscore_update:
  clr.b      ig_om_panel_redraw_score(a4)

.exit:
  movem.l    (sp)+,d0-d2/a0-a3
.exit_no_update:
  rts

; INTERNAL USE ONLY
panel_draw_lives:
  move.b     c_om_lives(a4),d0
  bsr        bcd_to_string_of_2                                       ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  add.l      ig_om_panel_cl_offset(a4),a1
  moveq.l    #10,d1                                                   ; modulo of font
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
  bsr        bcd_to_string_of_6                                       ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  add.l      ig_om_panel_cl_offset(a4),a1
  moveq.l    #10,d1                                                   ; modulo of font
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
  bsr        bcd_to_string_of_6                                       ; string in a0

  move.l     ig_om_panel_font_pointer(a4),d0
  add.l      ig_om_panel_cl_offset(a4),a1
  moveq.l    #10,d1                                                   ; modulo of font
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
  sub.b      #$30,d2                                                  ; ascii value of zero char
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

  endif                                                               ; ifnd INGAME_PANEL_ASM
