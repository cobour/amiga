
  ifnd       GFX_ASM
GFX_ASM       equ 1

  include    "src/system/custom.i"

Level3Handler equ $6c

CurrentView   equ $22
CurrentCopper equ $26
LoadView      equ -$de

; Waits vor vertical blank period
  macro      WAITVB
  movem.l    d0/a6,-(sp)
  lea.l      CustomBase,a6
.1\@:  
  move.l     VPOSR(a6),d0
  and.l      #$1ff00,d0
  cmp.l      #303<<8,d0
  bne.s      .1\@
  movem.l    (sp)+,d0/a6
  endm

; Waits for two vbp's - may be necessary when screen was/is in interlaced mode (then there are two different frames with two different copperlists)
  macro      WAITVB2
  movem.l    d0/a6,-(sp)
  lea.l      CustomBase,a6
.1\@:  
  move.l     VPOSR(a6),d0
  and.l      #$1ff00,d0
  cmp.l      #304<<8,d0
  bne.s      .1\@
.2\@:  
  move.l     VPOSR(a6),d0
  and.l      #$1ff00,d0
  cmp.l      #303<<8,d0
  bne.s      .2\@
  movem.l    (sp)+,d0/a6
  endm

; Saves system state for later restoring
gfx_save_orig_system_state:
  movem.l    d0-d7/a0-a6,-(sp)

  move.l     ExecBase,a6
  lea        gfx_name(pc),a1
  moveq.l    #0,d0
  jsr        OpenLibrary(a6)
  lea.l      gfx_base(pc),a0
  move.l     d0,(a0)

  lea.l      CustomBase,a6

  move.w     DMACONR(a6),d0
  or.w       #$8000,d0
  lea.l      gfx_cur_dmacon(pc),a0
  move.w     d0,(a0)

  move.w     INTENAR(a6),d0
  or.w       #$8000,d0
  lea.l      gfx_cur_intena(pc),a0
  move.w     d0,(a0)

  move.w     INTREQR(a6),d0
  or.w       #$8000,d0
  lea.l      gfx_cur_intreq(pc),a0
  move.w     d0,(a0)

  WAITVB2

  move.l     gfx_base(pc),a6

  lea.l      gfx_cur_view(pc),a0
  move.l     CurrentView(a6),(a0)

  lea.l      gfx_cur_copper(pc),a0
  move.l     CurrentCopper(a6),(a0)

  lea.l      gfx_cur_lvl3hdl(pc),a0
  move.l     Level3Handler,(a0)

  sub.l      a1,a1
  jsr        LoadView(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Restores screen at end of program
gfx_restore_screen:
  movem.l    d0-d7/a0-a6,-(sp)
  lea.l      CustomBase,a6
  move.l     gfx_cur_copper(pc),COP1LC(a6)

  move.l     gfx_base(pc),a6
  move.l     gfx_cur_view(pc),a1
  jsr        LoadView(a6)

  lea.l      CustomBase,a6
  WAITVB2

  move.l     ExecBase,a6
  move.l     gfx_base(pc),a1
  jsr        CloseLibrary(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Sets black screen
; in:
;   a0 - Pointer to 12 bytes of chip mem to store the copperlist
gfx_set_black_screen:
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

gfx_name:
  dc.b       "graphics.library",0
  even

gfx_base:
  dc.l       0

gfx_cur_view:
  dc.l       0

gfx_cur_copper:
  dc.l       0

gfx_cur_dmacon:
  dc.w       0

gfx_cur_intena:
  dc.w       0

gfx_cur_intreq:
  dc.w       0

gfx_cur_lvl3hdl:
  dc.l       0

  endif                                       ; ifnd GFX_ASM
