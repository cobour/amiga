  ifnd       SCREEN_I
SCREEN_I equ 1

; Waits for vertical blank period
  macro      WAITVB
  movem.l    d0/a6,-(sp)
  lea.l      CustomBase,a6
.1\@:  
  move.l     VPOSR(a6),d0
  and.l      #$1ff00,d0
  cmp.l      #299<<8,d0
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
  cmp.l      #300<<8,d0
  bne.s      .1\@
.2\@:  
  move.l     VPOSR(a6),d0
  and.l      #$1ff00,d0
  cmp.l      #299<<8,d0
  bne.s      .2\@
  movem.l    (sp)+,d0/a6
  endm

  endif                       ; ifnd SCREEN_I