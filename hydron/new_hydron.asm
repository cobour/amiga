
main_code_start:

  bsr        common_init
  tst.l      d0
  bne.s      .end

  ; DUMMY CODE START
  bsr        ctrl_take_system
  lea.l      $dff000,a6
  lea.l      $bfe001,a5
  moveq.l    #0,d0
.color_loop:
  move.w     d0,$0180(a6)
  addq.w     #1,d0
  cmp.w      #$1000,d0
  bne.s      .no_overflow
  moveq.l    #0,d0
.no_overflow:
  btst       #6,(a5)
  bne.s      .color_loop

  moveq.l    #0,d0
.end:
  move.l     d0,$0180(a6)
  move.l     d0,$0184(a6)
  bra.s      .end
  ; DUMMY CODE END

  include    "files_index.i"
  include    "../common/src/system/common_init.asm"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/control.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"
