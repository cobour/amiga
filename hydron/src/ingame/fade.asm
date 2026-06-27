  ifnd       INGAME_FADE_ASM
INGAME_FADE_ASM equ 1

  include    "src/ingame.i"

FadeStepDelay   equ 1

fade_ingame_init:
  ; get color tab
  move.l     #"COLS",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1

  ; init color values
  moveq.l    #32,d0
  moveq.l    #0,d1
  lea.l      ig_om_fade_color_tab_fade_in(a4),a0
  lea.l      ig_om_fade_in_struct(a4),a3
  bsr        fade_init
  moveq.l    #1,d1
  lea.l      ig_om_fade_color_tab_fade_out(a4),a0
  lea.l      ig_om_fade_out_struct(a4),a3
  bsr        fade_init

  ; set default values
  move.b     #16,ig_om_fade_in_step(a4)
  move.b     #-1,ig_om_fade_out_step(a4)
  clr.b      ig_om_fade_step_delay(a4)
  move.b     #1,ig_om_fade_first_step_fade_in(a4)
  
  rts

fade_ingame_start_fade_out:
  move.b     #16,ig_om_fade_out_step(a4)
  clr.b      ig_om_fade_step_delay(a4)
  rts

fade_ingame_update:
  tst.b      ig_om_fade_out_step(a4)
  blt        .check_fade_in

  ; fade out
  cmp.b      #FadeStepDelay,ig_om_fade_step_delay(a4)
  beq        .copy_front_to_back
  tst.b      ig_om_fade_step_delay(a4)
  beq.s      .fade_out_next_step
  sub.b      #1,ig_om_fade_step_delay(a4)
  bra        .exit

.fade_out_next_step:
  move.b     #FadeStepDelay,ig_om_fade_step_delay(a4)
  sub.b      #1,ig_om_fade_out_step(a4)
  bne.s      .fade_out_normal_step
  
  ; last fade out step
  move.b     #1,ig_om_end_mainloop(a4)                                  ; trigger end of mainloop

  move.l     ig_om_buffers_frontbuffer(a4),a0
  bsr        .clear_colors
  bsr        .clear_panel_data
  move.l     ig_om_buffers_backbuffer(a4),a0
  bsr        .clear_colors
  bsr        .clear_panel_data

  bra        .exit

.fade_out_normal_step:
  ; step 16-1

  ; panel (flood out)
  moveq.l    #16,d7
  moveq.l    #0,d6
  move.b     ig_om_fade_out_step(a4),d6
  sub.b      d6,d7
  lsl.w      #2,d7
  lea.l      .flood_out_copperlist_offset_tab(pc),a0
  move.l     (a0,d7.w),d7

  move.l     ig_om_buffers_backbuffer(a4),a0
  move.l     ig_buffers_copperlist_pointer(a0),a0
  lea.l      ig_cm_cl_panel(a0),a0
  move.l     a0,a2
  add.l      d7,a0
  move.l     a0,a1
.fo_flood_loop:
  ; copy a0 to a1
  move.w     panel_clrow_lives_0+6(a0),panel_clrow_lives_0+6(a1)
  move.w     panel_clrow_lives_1+6(a0),panel_clrow_lives_1+6(a1)
  move.w     panel_clrow_score_0+6(a0),panel_clrow_score_0+6(a1)
  move.w     panel_clrow_score_1+6(a0),panel_clrow_score_1+6(a1)
  move.w     panel_clrow_score_2+6(a0),panel_clrow_score_2+6(a1)
  move.w     panel_clrow_hiscore_0+6(a0),panel_clrow_hiscore_0+6(a1)
  move.w     panel_clrow_hiscore_1+6(a0),panel_clrow_hiscore_1+6(a1)
  move.w     panel_clrow_hiscore_2+6(a0),panel_clrow_hiscore_2+6(a1)
  lea.l      -panel_clrow_sizeof(a1),a1
  cmp.l      a2,a1
  bge.s      .fo_flood_loop

  ; colors
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a1
  lea.l      ig_cm_cl_colors(a1),a0
  lea.l      ig_om_fade_out_struct(a4),a3
  bsr        fade_next_step

  ; ig_cm_cl_reset_color17
  lea.l      ig_cm_cl_reset_color17+2(a1),a0
  lea.l      ig_cm_cl_colors+70(a1),a1
  move.w     (a1),(a0)
  bra        .exit

.check_fade_in:
  tst.b      ig_om_fade_in_step(a4)
  blt        .exit

  ; first step of fade in?
  tst.b      ig_om_fade_first_step_fade_in(a4)
  beq.s      .do_not_init_panel_colors
  clr.b      ig_om_fade_first_step_fade_in(a4)
  bsr        panel_set_colors
.do_not_init_panel_colors:

  ; fade in
  cmp.b      #FadeStepDelay,ig_om_fade_step_delay(a4)
  beq        .copy_front_to_back
  tst.b      ig_om_fade_step_delay(a4)
  beq.s      .fade_in_next_step
  sub.b      #1,ig_om_fade_step_delay(a4)
  bra        .exit

.fade_in_next_step:
  move.b     #FadeStepDelay,ig_om_fade_step_delay(a4)
  sub.b      #1,ig_om_fade_in_step(a4)
  beq        .fade_in_final_step

.fi_no_sub:
  ; step 16-1
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a1
  lea.l      ig_cm_cl_colors(a1),a0
  lea.l      ig_om_fade_in_struct(a4),a3
  bsr        fade_next_step

  ; ig_cm_cl_reset_color17
  lea.l      ig_cm_cl_reset_color17+2(a1),a0
  lea.l      ig_cm_cl_colors+70(a1),a1
  move.w     (a1),(a0)

  ; panel (flood in)
  moveq.l    #0,d7
  move.b     ig_om_fade_in_step(a4),d7                                  ; loop counter for lines to flood-copy

  moveq.l    #14,d6
  sub.w      d7,d6                                                      ; loop counter for lines to copy target data into (if negative no copy needed)

  lea.l      ig_om_panel_backup_for_fade(a4),a0
  add.l      #16*15,a0                                                  ; source pointer - offset to last row of backup copy of data
  move.l     ig_om_buffers_backbuffer(a4),a1
  move.l     ig_buffers_copperlist_pointer(a1),a1
  lea.l      ig_cm_cl_panel(a1),a1                   
  add.l      #panel_clrow_sizeof*15,a1                                  ; target pointer - offset to last panel row in copperlist

  tst.w      d6
  blt.s      .fi_panel_loop_flood_data

.fi_panel_loop_target_data:
  move.l     a0,a2
  move.w     (a2)+,panel_clrow_lives_0+6(a1)
  move.w     (a2)+,panel_clrow_lives_1+6(a1)
  move.w     (a2)+,panel_clrow_score_0+6(a1)
  move.w     (a2)+,panel_clrow_score_1+6(a1)
  move.w     (a2)+,panel_clrow_score_2+6(a1)
  move.w     (a2)+,panel_clrow_hiscore_0+6(a1)
  move.w     (a2)+,panel_clrow_hiscore_1+6(a1)
  move.w     (a2),panel_clrow_hiscore_2+6(a1)
  lea.l      -16(a0),a0
  lea.l      -panel_clrow_sizeof(a1),a1
  dbf        d6,.fi_panel_loop_target_data

.fi_panel_loop_flood_data:
  move.l     a0,a2
  move.w     (a2)+,panel_clrow_lives_0+6(a1)
  move.w     (a2)+,panel_clrow_lives_1+6(a1)
  move.w     (a2)+,panel_clrow_score_0+6(a1)
  move.w     (a2)+,panel_clrow_score_1+6(a1)
  move.w     (a2)+,panel_clrow_score_2+6(a1)
  move.w     (a2)+,panel_clrow_hiscore_0+6(a1)
  move.w     (a2)+,panel_clrow_hiscore_1+6(a1)
  move.w     (a2),panel_clrow_hiscore_2+6(a1)
  ; a0 stays the same
  lea.l      -panel_clrow_sizeof(a1),a1
  dbf        d7,.fi_panel_loop_flood_data

  bra.s      .exit

.fade_in_final_step:
  ; colors
  move.l     ig_om_buffers_frontbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a2
  bsr        buffers_set_colors_in_copperlist
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a2
  bsr        buffers_set_colors_in_copperlist

  ; panel
  move.l     ig_om_buffers_frontbuffer(a4),a1
  move.l     ig_buffers_copperlist_pointer(a1),a1
  lea.l      ig_cm_cl_panel(a1),a1
  bsr.s      .set_complete_panel_data
  move.l     ig_om_buffers_backbuffer(a4),a1
  move.l     ig_buffers_copperlist_pointer(a1),a1
  lea.l      ig_cm_cl_panel(a1),a1
  bsr.s      .set_complete_panel_data

  ; end fade in (both copperlists are in final state)
  move.b     #-1,ig_om_fade_in_step(a4)

.exit:
  rts

.set_complete_panel_data:
  lea.l      ig_om_panel_backup_for_fade(a4),a0
  moveq.l    #15,d7
.set_complete_panel_data_loop:
  move.w     (a0)+,panel_clrow_lives_0+6(a1)
  move.w     (a0)+,panel_clrow_lives_1+6(a1)
  move.w     (a0)+,panel_clrow_score_0+6(a1)
  move.w     (a0)+,panel_clrow_score_1+6(a1)
  move.w     (a0)+,panel_clrow_score_2+6(a1)
  move.w     (a0)+,panel_clrow_hiscore_0+6(a1)
  move.w     (a0)+,panel_clrow_hiscore_1+6(a1)
  move.w     (a0)+,panel_clrow_hiscore_2+6(a1)
  lea.l      panel_clrow_sizeof(a1),a1
  dbf        d7,.set_complete_panel_data_loop
  rts

.clear_panel_data:
  move.l     ig_buffers_copperlist_pointer(a0),a1
  lea.l      ig_cm_cl_panel(a1),a1
  moveq.l    #15,d7
.clear_panel_data_loop:
  clr.w      panel_clrow_lives_0+6(a1)
  clr.w      panel_clrow_lives_1+6(a1)
  clr.w      panel_clrow_score_0+6(a1)
  clr.w      panel_clrow_score_1+6(a1)
  clr.w      panel_clrow_score_2+6(a1)
  clr.w      panel_clrow_hiscore_0+6(a1)
  clr.w      panel_clrow_hiscore_1+6(a1)
  clr.w      panel_clrow_hiscore_2+6(a1)
  lea.l      panel_clrow_sizeof(a1),a1
  dbf        d7,.clear_panel_data_loop
  rts

.clear_colors:
  move.l     ig_buffers_copperlist_pointer(a0),a1
  lea.l      ig_cm_cl_colors+2(a1),a2
  moveq.l    #31,d7
.clear_colors_loop:
  clr.w      (a2)
  addq.l     #4,a2
  dbf        d7,.clear_colors_loop
  lea.l      ig_cm_cl_reset_color17+2(a1),a2
  clr.w      (a2)
  rts

.copy_front_to_back:
  ; panel
  move.l     ig_om_buffers_frontbuffer(a4),a0
  move.l     ig_buffers_copperlist_pointer(a0),a0
  lea.l      ig_cm_cl_panel(a0),a0
  move.l     ig_om_buffers_backbuffer(a4),a1
  move.l     ig_buffers_copperlist_pointer(a1),a1
  lea.l      ig_cm_cl_panel(a1),a1
  moveq.l    #15,d7
.copy_front_to_back_panel_loop:
  move.w     panel_clrow_lives_0+6(a0),panel_clrow_lives_0+6(a1)
  move.w     panel_clrow_lives_1+6(a0),panel_clrow_lives_1+6(a1)
  move.w     panel_clrow_score_0+6(a0),panel_clrow_score_0+6(a1)
  move.w     panel_clrow_score_1+6(a0),panel_clrow_score_1+6(a1)
  move.w     panel_clrow_score_2+6(a0),panel_clrow_score_2+6(a1)
  move.w     panel_clrow_hiscore_0+6(a0),panel_clrow_hiscore_0+6(a1)
  move.w     panel_clrow_hiscore_1+6(a0),panel_clrow_hiscore_1+6(a1)
  move.w     panel_clrow_hiscore_2+6(a0),panel_clrow_hiscore_2+6(a1)
  lea.l      panel_clrow_sizeof(a0),a0
  lea.l      panel_clrow_sizeof(a1),a1
  dbf        d7,.copy_front_to_back_panel_loop

  ; colors
  move.l     ig_om_buffers_frontbuffer(a4),a0
  move.l     ig_buffers_copperlist_pointer(a0),a0
  lea.l      ig_cm_cl_reset_color17+2(a0),a2
  lea.l      ig_cm_cl_colors+2(a0),a0
  move.l     ig_om_buffers_backbuffer(a4),a1
  move.l     ig_buffers_copperlist_pointer(a1),a1
  lea.l      ig_cm_cl_reset_color17+2(a1),a3
  lea.l      ig_cm_cl_colors+2(a1),a1
  move.w     (a2),(a3)                                                  ; color 17
  moveq.l    #31,d7
.copy_front_to_back_colors_loop:
  move.w     (a0),(a1)
  addq.l     #4,a0
  addq.l     #4,a1
  dbf        d7,.copy_front_to_back_colors_loop

  sub.b      #1,ig_om_fade_step_delay(a4)
  rts                                                                   ; bra.s .exit when .exit does more than rts

.flood_out_copperlist_offset_tab: ; to avoid mulu
  dc.l       panel_clrow_sizeof*0
  dc.l       panel_clrow_sizeof*1
  dc.l       panel_clrow_sizeof*2
  dc.l       panel_clrow_sizeof*3
  dc.l       panel_clrow_sizeof*4
  dc.l       panel_clrow_sizeof*5
  dc.l       panel_clrow_sizeof*6
  dc.l       panel_clrow_sizeof*7
  dc.l       panel_clrow_sizeof*8
  dc.l       panel_clrow_sizeof*9
  dc.l       panel_clrow_sizeof*10
  dc.l       panel_clrow_sizeof*11
  dc.l       panel_clrow_sizeof*12
  dc.l       panel_clrow_sizeof*13
  dc.l       panel_clrow_sizeof*14
  dc.l       panel_clrow_sizeof*15

  endif                                                                 ; ifnd INGAME_FADE_ASM
