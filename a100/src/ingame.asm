  ifnd       INGAME_ASM
INGAME_ASM equ 1

  include    "src/ingame.i"

; called by loader when system is not yet taken
; a4 - other mem pointer
; a5 - chip mem pointer
ig_start:
  ; init stuff
  bsr        .load_and_inflate_files
  SETPTRS
  bsr        .init_screen_buffers
  bsr        .init_copper_list
  bsr        ctrl_take_system
  lea.l      lvl3_irq_handler(pc),a0
  bsr        ctrl_set_handler
  bsr        keyboard_init
  bsr        .set_copper_list

  ; init and start music
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

  ; play sample initially
  move.l     #"SFX1",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx

.0:
  btst       #6,$bfe001
  bne.s      .0

  bsr        _mt_end
  bsr        keyboard_cleanup

.error:
  rts

.load_and_inflate_files:
  move.l     #fn_ingame_other,d1
  move.l     #fn_ingame_chip,d2
  move.l     chip_mem_ptr(pc),d5
  add.l      #ig_cm_screenbuffer,d5
  move.l     d5,d6
  add.l      #512,d6
  move.l     other_mem_ptr(pc),a0
  add.l      #ig_om_datfile,a0
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_datfile,a1
  bsr        datafiles_load_and_unzip
  tst.l      d0
  bne.s      .error
  rts

.init_screen_buffers:
  ; init pointers for both buffers
  move.l     #"SCRN",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      ig_cm_screenbuffer(a5),a1
  move.l     a0,ig_om_frontbuffer(a4)
  move.l     a1,ig_om_backbuffer(a4)

  ; copy screen-image from buffer in loaded file to empty buffer
  move.w     #((IgScreenWidthBytes*IgScreenHeight*IgScreenBitPlanes)/2)-1,d7
.isb_loop:
  move.w     (a0)+,(a1)+
  dbf        d7,.isb_loop

  rts

.init_copper_list:
; copy to chip mem
  move.l     #(ig_cm_cl_sizeof/4)-1,d7
  lea.l      .copper_list(pc),a0
  move.l     chip_mem_ptr(pc),a1
  add.l      #ig_cm_copperlist,a1
.icl0:
  move.l     (a0)+,(a1)+
  dbf        d7,.icl0  

; set bitplane pointer
  move.l     ig_om_frontbuffer(a4),d0
  move.l     chip_mem_ptr(pc),a0
  add.l      #ig_cm_copperlist+ig_cm_cl_bitplanes,a0
  moveq.l    #5,d7
.icl1
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  swap       d0
  add.l      #IgScreenWidthBytes,d0
  addq.l     #8,a0
  dbf        d7,.icl1

  rts

.set_copper_list
  move.l     chip_mem_ptr(pc),a0
  add.l      #ig_cm_copperlist,a0
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  rts

.copper_list:
; sprite pointer
  dc.w       SPR0PTH,$0000
  dc.w       SPR0PTL,$0000
  dc.w       SPR1PTH,$0000
  dc.w       SPR1PTL,$0000
  dc.w       SPR2PTH,$0000
  dc.w       SPR2PTL,$0000
  dc.w       SPR3PTH,$0000
  dc.w       SPR3PTL,$0000
  dc.w       SPR4PTH,$0000
  dc.w       SPR4PTL,$0000
  dc.w       SPR5PTH,$0000
  dc.w       SPR5PTL,$0000
  dc.w       SPR6PTH,$0000
  dc.w       SPR6PTL,$0000
  dc.w       SPR7PTH,$0000
  dc.w       SPR7PTL,$0000
; bitplane pointer
  dc.w       BPL1PTH,$0000
  dc.w       BPL1PTL,$0000
  dc.w       BPL2PTH,$0000
  dc.w       BPL2PTL,$0000
  dc.w       BPL3PTH,$0000
  dc.w       BPL3PTL,$0000
  dc.w       BPL4PTH,$0000
  dc.w       BPL4PTL,$0000
  dc.w       BPL5PTH,$0000
  dc.w       BPL5PTL,$0000
  dc.w       BPL6PTH,$0000
  dc.w       BPL6PTL,$0000
; bitplane config
  dc.w       BPLCON0,(IgScreenBitPlanes<<12)|BplColorOn
  dc.w       BPLCON1,$0000
  dc.w       BPLCON2,$0000
  dc.w       BPL1MOD,IgScreenWidthBytes*(IgScreenBitPlanes-1)
  dc.w       BPL2MOD,IgScreenWidthBytes*(IgScreenBitPlanes-1)
  dc.w       DDFSTRT,(IgScreenStartX/2-DdfResolution)
  dc.w       DDFSTOP,(IgScreenStartX/2-DdfResolution)+(8*((IgScreenWidth/16)-1))
  dc.w       DIWSTRT,(IgScreenStartY<<8)|IgScreenStartX
  dc.w       DIWSTOP,((IgScreenStopY-256)<<8)|(IgScreenStopX-256)
; trigger Copper-IRQ after all bitplane and sprite registers are set => irq routine can safely modify copperlist for next frame
  dc.w       INTREQ,%1000000000010000
; colors
  dc.w       COLOR00,$0000
  dc.w       COLOR01,$0444
  dc.w       COLOR02,$0666
  dc.w       COLOR03,$0888
  dc.w       COLOR04,$0aaa
  dc.w       COLOR05,$0ccc
  dc.w       COLOR06,$0eee
  dc.w       COLOR07,$0fff
  dc.w       COLOR08,$0200
  dc.w       COLOR09,$0400
  dc.w       COLOR10,$0600
  dc.w       COLOR11,$0800
  dc.w       COLOR12,$0a00
  dc.w       COLOR13,$0c00
  dc.w       COLOR14,$0e00
  dc.w       COLOR15,$0f00
  dc.w       COLOR16,$0020
  dc.w       COLOR17,$0040
  dc.w       COLOR18,$0060
  dc.w       COLOR19,$0080
  dc.w       COLOR20,$00a0
  dc.w       COLOR21,$00c0
  dc.w       COLOR22,$00e0
  dc.w       COLOR23,$00f0
  dc.w       COLOR24,$0002
  dc.w       COLOR25,$0004
  dc.w       COLOR26,$0006
  dc.w       COLOR27,$0008
  dc.w       COLOR28,$000a
  dc.w       COLOR29,$000c
  dc.w       COLOR30,$000e
  dc.w       COLOR31,$000f
; end
  dc.w       $ffff,$fffe

lvl3_irq_handler:
  movem.l    d0-d7/a0-a6,-(sp)

  ; read all available key codes
.1:
  bsr        keyboard_get_key
  ; play sample when S is pressed
  cmp.b      #$21,d0
  bne.s      .2

  move.l     #"SFX1",d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx

.2:
  tst.b      d0
  bge.s      .1

  ; clear Copper-IRQ-Bit
  move.w     #%0000000000010000,INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rte


  endif                                                                             ; ifnd INGAME_ASM
