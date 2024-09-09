  ifnd     BLITTER_I
BLITTER_I equ 1

; Waits for the blitter to be ready
  macro    WAIT_BLT 
; tst for compatibility with A1000 with first Agnus revision
  tst.w    DMACONR(a6)
.1\@:
  btst     #6,DMACONR(a6)
  bne.s    .1\@
  endm

  endif                      ; ifnd BLITTER_I