
  include    "src/globals.i"
  include    "../common/src/system/screen.i"

;RED_TIMING equ 1                                       ; show end of frame preparation as red COLOR00

main_code_start:

  bsr        common_init
  tst.l      d0
  bne.s      .end
  SETPTRS

  bsr        ctrl_save_orig_system_state

  WAITVB
  move.l     chip_mem_ptr(pc),a0
  lea.l      c_cm_all_black_copperlist(a0),a0
  bsr        ctrl_set_black_screen

  bsr        ig_start

  ifnd       USE_DISK_DMA
  bsr        ctrl_free_system
  bsr        ctrl_restore_screen
  endif                                                ; ifnd USE_DISK_DMA

.end:
  bsr        disk_cleanup

; end-of-game code
  ifd        STANDARD_EXE
  bsr        exec_free_mem
  moveq.l    #0,d0
  rts
  bsr        exec_free_mem
  moveq.l    #1,d0
  rts
  endif                                                ; ifd STANDARD_EXE

  ifd        USE_TRACKDISK
  bsr        exec_reboot
  endif                                                ; ifd USE_TRACKDISK

  ifd        USE_DISK_DMA
.loop_forever:
  bra.s      .loop_forever
  endif                                                ; ifd USE_DISK_DMA

  include    "../common/src/system/common_init.asm"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/control.asm"
  include    "../common/src/system/joystick.asm"
  include    "../common/src/system/bcd.asm"
  include    "../common/src/system/fade.asm"
  include    "src/ingame.asm"
  include    "src/ingame/background.asm"
  include    "src/ingame/buffers.asm"
  include    "src/ingame/panel.asm"
  include    "src/ingame/player.asm"
  include    "src/ingame/fade.asm"
  include    "src/ingame/enemies.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"
