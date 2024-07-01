  ifnd       IRQ_ASM
IRQ_ASM equ 1

  include    "src/system/custom.i"
  include    "src/system/gfx.asm"

; Takes full control of system
irq_take_system:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6

  WAITVB2

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
irq_free_system:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6
  bsr        _mt_remove_cia

  move.w     #$7fff,DMACON(a6)
  move.w     gfx_cur_dmacon(pc),DMACON(a6)
  move.w     #$7fff,INTENA(a6)
  move.l     gfx_cur_lvl3hdl(pc),Level3Handler
  move.w     gfx_cur_intena(pc),INTENA(a6)
  move.w     #$7fff,INTREQ(a6)
  move.w     gfx_cur_intreq(pc),INTREQ(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Sets level 3 IRQ handler
; in:
;   a0 - points to handler code
irq_set_handler:
  move.l     a6,-(sp)
  lea.l      CustomBase,a6

  move.w     #%0111111111111111,INTENA(a6)        ; disable ALL IRQ's
  move.l     a0,Level3Handler
  move.w     #%1110000000010000,INTENA(a6)        ; Copper-IRQ (for our code) and External-IRQ (for ptplayer) only

  move.l     (sp)+,a6
  rts

  endif                                           ; ifnd IRQ_ASM
 