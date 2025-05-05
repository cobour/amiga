  ifnd       MM_SFX_ASM
MM_SFX_ASM equ 1

sfx_mm_init:
  lea.l      sfx_mm(pc),a1
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

sfx_mm_play:
  movem.l    d1/a0-a1,-(sp)
  lea.l      sfx_mm-8(pc),a1
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

sfx_mm:
  dc.l       f004_sfx_select
  dc.l       0
  dc.l       f004_sfx_step
  dc.l       0
  dc.l       f004_sfx_error
  dc.l       0
  dc.l       -1                        ; end of list

  endif                                ; ifnd MM_SFX_ASM
