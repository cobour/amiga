  section    A100Code , code

;       mem.i that calcs sizes for chip and other mem => use for exec.asm // WATCH OUT FOR FIXME's



  include    "src/globals.i"

main:

  ifd        DEBUG
  ; allocate mem
  moveq.l    #MemScheme,d0
  move.l     #200000,d1                               ; FIXME: value from mem.i
  move.l     #200000,d2                               ; FIXME: value from mem.i
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      .error
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  lea.l      disk_struct_ptr(pc),a0
  move.l     a4,(a0)
  ; read file list from floppy drive
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .error
  move.l     chip_mem_ptr(pc),a3                      ; TODO: inside framebuffer
  bsr        disk_read_file_list
  tst.l      d0
  bne.s      .error
  bsr        disk_end_io
  tst.l      d0
  bne.s      .error
  endif
  ifd        RELEASE
  ; bootblock allocated memory, pointers in a4 + a5
  ; bootblock already read file list from floppy drive
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  lea.l      disk_struct_ptr(pc),a0
  move.l     a4,(a0)
  endif

  bsr        ctrl_save_orig_system_state
  move.l     chip_mem_ptr(pc),a0
  lea.l      c_cm_all_black_copperlist(a0),a0
  bsr        ctrl_set_black_screen

  move.l     other_mem_ptr(pc),a4
  move.l     chip_mem_ptr(pc),a5
  bsr        ig_start
  bsr        ctrl_free_system

  bsr        ctrl_restore_screen

  ifd        DEBUG
  bsr        exec_free_mem
  moveq.l    #0,d0
  rts
.error
  bsr        exec_free_mem
  moveq.l    #1,d0
  rts
  endif
  ifd        RELEASE
  bsr        exec_reboot
  endif

;
; Includes
;
  include    "files_index.i"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/control.asm"
  include    "../common/src/system/keyboard.asm"
  include    "src/ingame.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"