  ifnd      HIGHSCORES_SFX_I
HIGHSCORES_SFX_I equ 1

; macro for playing a sfx
  macro     SFX
  move.l    d0,-(sp)
  move.l    #\1,d0
  bsr       sfx_highscores_play
  move.l    (sp)+,d0
  endm

  endif                            ; ifnd HIGHSCORES_SFX_I
