
  include    "src/globals.i"
  include    "../common/src/system/screen.i"

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

  bsr        ctrl_free_system
  bsr        disk_cleanup
  bsr        ctrl_restore_screen

.end:
  bsr        disk_cleanup

  ifd        STANDARD_EXE

  bsr        exec_free_mem
  moveq.l    #0,d0
  rts
.error
  bsr        exec_free_mem
  moveq.l    #1,d0
  rts
  endif                                                ; ifd STANDARD_EXE

  ifd        BOOTBLOCK
  bsr        exec_reboot
  endif                                                ; ifd BOOTBLOCK

  include    "../common/src/system/common_init.asm"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/control.asm"
  include    "src/ingame.asm"
  include    "src/ingame/panel.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"
