  ifnd      INGAME_SFX_I
INGAME_SFX_I equ 1

; macro for playing a sfx
  macro     SFX
  move.l    d0,-(sp)
  move.l    #\1,d0
  bsr       sfx_ingame_play
  move.l    (sp)+,d0
  endm

  endif                        ; ifnd INGAME_SFX_I
