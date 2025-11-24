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
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  tst.l      d0
  bne.s      .error

  SETPTRS
  bsr        .init_copper_list
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        .set_copper_list

  move.l     #"MS01",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a1
  move.l     #"MP01",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0

  moveq.l    #0,d0
  bsr        _mt_init

  lea.l      _mt_Enable(pc),a0
  move.b     #1,(a0)

  move.l     #"SFX1",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx

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

  rts

.set_copper_list
  lea.l      CustomBase,a6
  move.l     a2,COP1LC(a6)
  rts

lvl3_irq_handler:
  movem.l    d0-d7/a0-a6,-(sp)

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rte


  endif                                       ; ifnd INGAME_ASM
