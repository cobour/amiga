  ifnd       INGAME_ASM
INGAME_ASM equ 1

  include    "src/ingame.i"

; called by loader when system is not yet taken
; a4 - other mem pointer
; a5 - chip mem pointer
ig_start:
; load and inflate files, TODO: just dummy data

  move.l     #"F101",d1
  move.l     chip_mem_ptr(pc),d6
  add.l      #ig_cm_filebuffer,d6             ; TODO: inside framebuffer
  move.l     other_mem_ptr(pc),a0
  add.l      #ig_om_datfile,a0
  move.l     chip_mem_ptr(pc),d7
  add.l      #ig_cm_dmabuffer,d7              ; TODO: inside framebuffer
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  tst.l      d0
  bne.s      .error

  SETPTRS
  bsr        .init_copper_list
  bsr        panel_init
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .set_copper_list

  move.l     #"MS02",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #"MP02",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0

  moveq.l    #0,d0
  bsr        _mt_init

  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)

  move.l     #"SFX1",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  ;bsr        _mt_playfx

.0:
  btst       #6,$bfe001
  bne.s      .0

  bsr        _mt_end

.error:
  rts

.init_copper_list:
; get pointer to copperlist in chip mem
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a2

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


  ; init dummysprites - REMOVE ME - START
  move.l     #"AUTO",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),d0
  move.l     d0,a0

  lea.l      ig_cm_dummysprite1(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite2(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite3(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite4(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite5(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite6(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_dummysprite7(a5),a1
  move.l     (a0),(a1)
  move.l     4(a0),4(a1)
  move.l     8(a0),8(a1)
  move.l     12(a0),12(a1)
  move.l     16(a0),16(a1)
  move.l     20(a0),20(a1)
  move.l     24(a0),24(a1)

  lea.l      ig_cm_cl_reuse_sprites(a2),a1
  addq.l     #4,d0                            ; skip control words
  move.w     d0,6(a1)
  swap       d0
  move.w     d0,2(a1)
  move.w     (a0),10(a1)
  move.w     2(a0),14(a1)

  lea.l      ig_cm_dummysprite1(a5),a3
  move.l     a3,d0
  addq.l     #4,d0
  move.w     d0,22(a1)
  swap       d0
  move.w     d0,18(a1)
  move.w     (a3),26(a1)
  add.w      #$0010,26(a1)
  move.w     2(a3),30(a1)

  lea.l      ig_cm_cl_sprites+16(a2),a1
  lea.l      ig_cm_dummysprite2(a5),a3
  move.l     a3,d0
  move.w     d0,6(a1)
  swap       d0
  move.w     d0,2(a1)
  move.w     #$3a74,(a3)
  move.w     #$3f00,2(a3)

  lea.l      ig_cm_dummysprite3(a5),a3
  move.l     a3,d0
  move.w     d0,14(a1)
  swap       d0
  move.w     d0,10(a1)
  move.w     #$3a84,(a3)
  move.w     #$3f00,2(a3)

  lea.l      ig_cm_dummysprite4(a5),a3
  move.l     a3,d0
  move.w     d0,22(a1)
  swap       d0
  move.w     d0,18(a1)
  move.w     #$3a94,(a3)
  move.w     #$3f00,2(a3)

  lea.l      ig_cm_dummysprite5(a5),a3
  move.l     a3,d0
  move.w     d0,30(a1)
  swap       d0
  move.w     d0,26(a1)
  move.w     #$3aa4,(a3)
  move.w     #$3f00,2(a3)

  lea.l      ig_cm_dummysprite6(a5),a3
  move.l     a3,d0
  move.w     d0,38(a1)
  swap       d0
  move.w     d0,34(a1)
  move.w     #$3ab4,(a3)
  move.w     #$3f00,2(a3)

  lea.l      ig_cm_dummysprite7(a5),a3
  move.l     a3,d0
  move.w     d0,46(a1)
  swap       d0
  move.w     d0,42(a1)
  move.w     #$3ac4,(a3)
  move.w     #$3f00,2(a3)

  ; init dummysprites - REMOVE ME - END

  rts

.set_copper_list
  movem.l    d0/a0/a6,-(sp)
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  movem.l    (sp)+,d0/a0/a6
  rts

lvl3_irq_handler:
  movem.l    d0-d7/a0-a6,-(sp)

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rte


  endif                                       ; ifnd INGAME_ASM
