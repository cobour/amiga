  ifnd       CONTROL_ASM
CONTROL_ASM   equ 1

  include    "../common/src/system/custom.i"
  include    "../common/src/system/screen.i"

; vectors
Level2Handler equ $68
Level3Handler equ $6c

; graphics.library
CurrentView   equ $22
CurrentCopper equ $26
LoadView      equ -$de

; Saves system state for later restoring
ctrl_save_orig_system_state:
  movem.l    d0-d7/a0-a6,-(sp)

  move.l     ExecBase,a6
  lea        graphics_name(pc),a1
  moveq.l    #0,d0
  jsr        OpenLibrary(a6)
  lea.l      graphics_base(pc),a0
  move.l     d0,(a0)

  lea.l      CustomBase,a6

  move.w     DMACONR(a6),d0
  or.w       #$8000,d0
  lea.l      ctrl_cur_dmacon(pc),a0
  move.w     d0,(a0)

  move.w     INTENAR(a6),d0
  or.w       #$8000,d0
  lea.l      ctrl_cur_intena(pc),a0
  move.w     d0,(a0)

  move.w     INTREQR(a6),d0
  or.w       #$8000,d0
  lea.l      ctrl_cur_intreq(pc),a0
  move.w     d0,(a0)

  WAITVB2

  move.l     graphics_base(pc),a6

  lea.l      ctrl_cur_view(pc),a0
  move.l     CurrentView(a6),(a0)

  lea.l      ctrl_cur_copper(pc),a0
  move.l     CurrentCopper(a6),(a0)

  lea.l      ctrl_cur_lvl2hdl(pc),a0
  move.l     Level2Handler,(a0)

  lea.l      ctrl_cur_lvl3hdl(pc),a0
  move.l     Level3Handler,(a0)

  sub.l      a1,a1
  jsr        LoadView(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Restores screen at end of program
ctrl_restore_screen:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6
  move.l     ctrl_cur_copper(pc),COP1LC(a6)

  move.l     graphics_base(pc),a6
  move.l     ctrl_cur_view(pc),a1
  jsr        LoadView(a6)

  lea.l      CustomBase,a6
  WAITVB2

  move.l     ExecBase,a6
  move.l     graphics_base(pc),a1
  jsr        CloseLibrary(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Sets black screen
; in:
;   a0 - Pointer to 12 bytes of chip mem to store the copperlist
ctrl_set_black_screen:
  movem.l    a1/a6,-(sp)
  move.l     a0,a1
  move.w     #BPLCON0,(a1)+
  move.w     #BplColorOn,(a1)+
  move.w     #COLOR00,(a1)+
  move.w     #$0000,(a1)+
  move.w     #$ffff,(a1)+
  move.w     #$fffe,(a1)+
  lea.l      CustomBase,a6
  move.l     a0,COP1LC(a6)
  WAITVB2
  movem.l    (sp)+,a1/a6
  rts

; Takes full control of system
ctrl_take_system:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6

  WAITVB2

  ; stop floppy drive motor
  ; found here: http://eab.abime.net/showthread.php?t=84507
  lea.l      $bfd100,a0
  or.b       #$f8,(a0)
  nop
  and.b      #$87,(a0)
  nop
  or.b       #$78,(a0)
  nop

  ; set our dma and irq settings
  move.w     #%1000010111100000,DMACON(a6)
  move.w     #%0000000000011111,DMACON(a6)
  move.w     #%0111111111111111,INTENA(a6)

  WAITVB2

  sub.l      a0,a0
  moveq.l    #1,d0
  bsr        _mt_install_cia

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Gives control back to system
ctrl_free_system:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6
  bsr        _mt_remove_cia

  move.w     #$7fff,d0
  move.w     d0,DMACON(a6)
  move.w     d0,INTENA(a6)
  move.w     d0,INTREQ(a6)

  move.w     ctrl_cur_dmacon(pc),DMACON(a6)
  move.l     ctrl_cur_lvl2hdl(pc),Level2Handler
  move.l     ctrl_cur_lvl3hdl(pc),Level3Handler
  move.w     ctrl_cur_intena(pc),INTENA(a6)
  move.w     ctrl_cur_intreq(pc),INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Sets level 3 IRQ handler
; in:
;   a0 - points to handler code
ctrl_set_handler:
  move.l     a6,-(sp)
  lea.l      CustomBase,a6

  move.w     #%0111111111111111,INTENA(a6)         ; disable ALL IRQ's
  move.l     a0,Level3Handler
  move.w     #%1110000000010000,INTENA(a6)         ; Copper-IRQ (for our code) and External-IRQ (for ptplayer) only

  move.l     (sp)+,a6
  rts

graphics_name:
  dc.b       "graphics.library",0
  even

graphics_base:
  dc.l       0

ctrl_cur_view:
  dc.l       0

ctrl_cur_copper:
  dc.l       0

ctrl_cur_dmacon:
  dc.w       0

ctrl_cur_intena:
  dc.w       0

ctrl_cur_intreq:
  dc.w       0

ctrl_cur_lvl2hdl:
  dc.l       0

ctrl_cur_lvl3hdl:
  dc.l       0

  endif                                            ; ifnd CONTROL_ASM
 