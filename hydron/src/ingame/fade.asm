  ifnd       INGAME_FADE_ASM
INGAME_FADE_ASM equ 1

  include    "src/ingame.i"

fade_ingame_init:
  ; get color tab
  move.l     #"COLS",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1

  ; init color values
  lea.l      ig_om_fade_color_tab(a4),a0
  moveq.l    #32,d0
  moveq.l    #0,d1
  bsr        fade_init

  ; set default values
  move.b     #16,ig_om_fade_step(a4)
  
  rts

fade_ingame_update:
  tst.b      ig_om_fade_step(a4)
  blt.s      .exit
  sub.b      #1,ig_om_fade_step(a4)
  beq.s      .set_final_colors_in_both_buffers

  ; step 16-1
  move.l     ig_om_buffers_backbuffer(a4),a2
  move.l     ig_buffers_copperlist_pointer(a2),a1
  lea.l      ig_cm_cl_colors(a1),a0
  bsr        fade_next_step

  ; ig_cm_cl_reset_color17
  lea.l      ig_cm_cl_reset_color17+2(a1),a0
  lea.l      ig_cm_cl_colors+70(a1),a1
  move.w     (a1),(a0)

  ; TODO panel

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

  endif                                              ; ifnd INGAME_FADE_ASM
