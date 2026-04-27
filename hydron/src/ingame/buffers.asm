  ifnd       INGAME_BUFFERS_ASM
INGAME_BUFFERS_ASM equ 1

  include    "src/ingame.i"

buffers_init_vars:
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_copperlist_front(a4)
  lea.l      ig_cm_copperlist(a5),a0
  move.l     a0,ig_om_copperlist_back(a4)
  rts

buffers_init:
  bsr.s      .init_copper_list
  bsr.s      .copy_copperlist
  bra.s      .set_copper_list                                     ; implicit rts

.init_copper_list:
; get pointer to copperlist in chip mem
  move.l     ig_om_copperlist_front(a4),a2

; set bitplane pointer
  move.l     #"TSTB",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a0,d0

  move.l     a2,a0
  lea.l      ig_cm_cl_bitplanes(a0),a0

  moveq.l    #5,d7
.icl1
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl1

; set colors
  move.l     #"COLS",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a1
  move.w     df_cols_count(a1),d7
  subq.w     #1,d7
  move.l     df_idx_ptr_rawdata(a0),a0
  move.l     a2,a1
  lea.l      ig_cm_cl_colors+2(a1),a1
.icl2:
  move.w     (a0)+,(a1)
  addq.l     #4,a1
  dbf        d7,.icl2

  rts

.copy_copperlist
  movem.l    a0-a1/d7,-(sp)
  move.l     ig_om_copperlist_front(a4),a0
  move.l     ig_om_copperlist_back(a4),a1
  move.w     #(ig_cm_cl_sizeof/4)-1,d7
.ccl_loop:
  move.l     (a0)+,(a1)+
  dbf        d7,.ccl_loop
  movem.l    (sp)+,a0-a1/d7
  rts

.set_copper_list
  movem.l    d0/a0,-(sp)
  move.l     ig_om_copperlist_front(a4),a0
  move.l     a0,COP1LC(a6)
  move.w     #$0000,COPJMP1(a6)
  movem.l    (sp)+,d0/a0
  rts

buffers_swap:
  movem.l    d0/a0-a1,-(sp)
  move.l     ig_om_copperlist_front(a4),a0
  move.l     ig_om_copperlist_back(a4),a1
  move.l     a1,COP1LC(a6)
  ; no COMJMP1, because we do not know at which beam position this is executed
  move.l     a0,ig_om_copperlist_back(a4)
  move.l     a1,ig_om_copperlist_front(a4)
  movem.l    (sp)+,d0/a0-a1
  rts
  rts

  endif                                                           ; ifnd INGAME_BUFFERS_ASM
