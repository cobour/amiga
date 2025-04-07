  ifnd       HIGHSCORES_SFX_ASM
HIGHSCORES_SFX_ASM equ 1

sfx_highscores_init:
  lea.l      sfx_highscores(pc),a1
.next:
  move.l     (a1)+,d0
  tst.l      d0
  blt.s      .exit
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  move.l     a0,(a1)+
  bra.s      .next
.exit:
  rts

sfx_highscores_play:
  movem.l    d1/a0-a1,-(sp)
  lea.l      sfx_highscores-8(pc),a1
.next:
  addq.l     #8,a1
  move.l     (a1),d1
  tst.l      d1
  blt.s      .exit
  cmp.l      d0,d1
  bne.s      .next
  move.l     4(a1),a0
  bsr        _mt_playfx
.exit:
  movem.l    (sp)+,d1/a0-a1
  rts

sfx_highscores:
  dc.l       f002_sfx_tick
  dc.l       0
  dc.l       f002_sfx_print
  dc.l       0
  dc.l       f002_sfx_delete
  dc.l       0
  dc.l       f002_sfx_enter
  dc.l       0
  dc.l       f002_sfx_error
  dc.l       0
  dc.l       -1                         ; end of list

  endif                                 ; ifnd HIGHSCORES_SFX_ASM
