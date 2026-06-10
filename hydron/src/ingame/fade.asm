  ifnd       INGAME_FADE_ASM
INGAME_FADE_ASM equ 1

  include    "src/ingame.i"

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
  
  rts

fade_ingame_start_fade_out:
  move.b     #16,ig_om_fade_out_step(a4)
  rts

fade_ingame_update:

  tst.b      ig_om_fade_out_step(a4)
  blt.s      .check_fade_in

  ; fade out
  sub.b      #1,ig_om_fade_out_step(a4)
  bne.s      .fade_out_normal_step
  
  ; last fade out step
  move.b     #1,ig_om_end_mainloop(a4)               ; trigger end of mainloop

  move.l     ig_om_buffers_frontbuffer(a4),a0
  bsr        .clear_colors
  move.l     ig_om_buffers_backbuffer(a4),a0
  bsr        .clear_colors

  bra.s      .exit

.fade_out_normal_step:
  ; TODO: panel (remove data from cl, clear panel-update-trigger)

  ; step 16-1
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a1
  lea.l      ig_cm_cl_colors(a1),a0
  lea.l      ig_om_fade_out_struct(a4),a3
  bsr        fade_next_step

  ; ig_cm_cl_reset_color17
  lea.l      ig_cm_cl_reset_color17+2(a1),a0
  lea.l      ig_cm_cl_colors+70(a1),a1
  move.w     (a1),(a0)
  bra.s      .exit

.check_fade_in:
  tst.b      ig_om_fade_in_step(a4)
  blt.s      .exit
  sub.b      #1,ig_om_fade_in_step(a4)
  beq.s      .set_final_colors_in_both_buffers

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

  ; TODO panel (bump in, adjust all copper waits between beginning of ig_cm_cl_panel and end of ig_cm_cl_sprite01_off)

  bra.s      .exit

  ; step 0
.set_final_colors_in_both_buffers:
  move.l     ig_om_buffers_frontbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a2
  bsr        buffers_set_colors_in_copperlist
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a2
  bsr        buffers_set_colors_in_copperlist

  ; TODO panel
  
.exit:
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

  endif                                              ; ifnd INGAME_FADE_ASM
