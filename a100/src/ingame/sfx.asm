  ifnd       INGAME_SFX_ASM
INGAME_SFX_ASM equ 1

sfx_ingame_init:
  lea.l      sfx_ingame(pc),a1
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

sfx_ingame_play:
  movem.l    d1/a0-a1,-(sp)
  lea.l      sfx_ingame-8(pc),a1
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

sfx_ingame:
  dc.l       f000_sfx_select
  dc.l       0
  dc.l       f000_sfx_unselect
  dc.l       0
  dc.l       f000_sfx_step
  dc.l       0
  dc.l       f000_sfx_error
  dc.l       0
  dc.l       f000_sfx_clear_row_column
  dc.l       0
  dc.l       f000_sfx_placed
  dc.l       0
  dc.l       f000_sfx_gameover
  dc.l       0
  dc.l       f000_sfx_alarm
  dc.l       0
  dc.l       -1                           ; end of list

  endif                                   ; ifnd INGAME_SFX_ASM
