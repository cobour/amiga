  ifnd       INGAME_PANEL_ASM
INGAME_PANEL_ASM equ 1

  include    "src/ingame.i"

panel_init:
  movem.l    d0/d7/a0-a3,-(sp)

  ; init label texts
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a3
  lea.l      ig_cm_cl_panel+4(a3),a3

  move.l     #"PAHI",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a2

  move.l     #"PASC",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1

  move.l     #"PALI",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0

  moveq.l    #9,d7                        ; 10 rows
.pi_loop:
  move.w     (a0)+,6(a3)
  move.w     (a0)+,18(a3)

  move.w     (a1)+,34(a3)
  move.w     (a1)+,42(a3)
  move.w     (a1)+,50(a3)

  move.w     (a2)+,58(a3)
  move.w     (a2)+,66(a3)
  move.w     (a2)+,74(a3)

  lea.l      132(a3),a3
  dbf        d7,.pi_loop

  ; print dummy values - TODO: switch to real values
  move.l     #"PAFO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0

  moveq.l    #10,d0
  moveq.l    #5,d7                        ; 6 rows
.pi_dummy_values_loop:
  move.w     (a0),6(a3)
  move.w     2(a0),18(a3)

  move.w     (a0),34(a3)
  move.w     2(a0),42(a3)
  move.w     4(a0),50(a3)

  move.w     (a0),58(a3)
  move.w     2(a0),66(a3)
  move.w     4(a0),74(a3)

  add.l      d0,a0
  lea.l      132(a3),a3
  dbf        d7,.pi_dummy_values_loop

  movem.l    (sp)+,d0/d7/a0-a3
  rts

  endif                                   ; ifnd INGAME_PANEL_ASM
