  ifnd       INGAME_SFX_I
INGAME_SFX_I equ 1

; macro for playing a sfx
  macro      SFX
  movem.l    d0/a0,-(sp)
  move.l     #\1,d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx
  movem.l    (sp)+,d0/a0
  endm

  endif                                ; ifnd INGAME_SFX_I
