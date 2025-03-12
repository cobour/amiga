  section    A100Code , code

  include    "src/globals.i"

  ifd        TEST_MEM_SIZES
  move.l     #A100ChipMemSize,d0
  move.l     #ig_cm_sizeof,d1
  move.l     #mm_cm_sizeof,d2
  move.l     #hs_cm_sizeof,d3
  move.l     #A100OtherMemSize,d4
  move.l     #ig_om_sizeof,d5
  move.l     #mm_om_sizeof,d6
  move.l     #hs_om_sizeof,d7
  endif                                                      ; TEST_MEM_SIZES

main:
  bsr.s      .init_ram_and_file_list
  bsr        ctrl_save_orig_system_state

  move.l     chip_mem_ptr(pc),a0
  lea.l      c_cm_all_black_copperlist(a0),a0
  bsr        ctrl_set_black_screen

  SETPTRS
  clr.l      c_om_framecounter(a4)                           ; global framecounter for all parts
  move.b     #NextPartMainmenu,c_om_next_part(a4)
  
  ; REMOVE ME - for testing
  ;move.b     #NextPartHighscores,c_om_next_part(a4)
  ;move.b     #GameModeSpeedRun,c_om_gamemode(a4)
  ;move.b     #GameModeInfinite,c_om_gamemode(a4)
  ; REMOVE ME - for testing

.loop:
  cmp.b      #NextPartIngame,c_om_next_part(a4)
  bne.s      .0
  bsr        ig_start                                        ; MUST call ctrl_take_system and ctrl_free_system
  bra.s      .loop
.0:
  cmp.b      #NextPartHighscores,c_om_next_part(a4)
  bne.s      .1
  bsr        hs_start                                        ; MUST call ctrl_take_system and ctrl_free_system
  bra.s      .loop
.1:
  cmp.b      #NextPartMainmenu,c_om_next_part(a4)
  bne.s      .2
  bsr        mm_start                                        ; MUST call ctrl_take_system and ctrl_free_system
  bra.s      .loop
.2:

  ;
  ; exit program
  ;
.exit_game:
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

.init_ram_and_file_list:

  ifd        DEBUG
  ; allocate mem
  moveq.l    #MemScheme,d0
  move.l     #A100ChipMemSize,d1
  move.l     #A100OtherMemSize,d2
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      .error
  bsr.s      .save_a4_and_a5
  ; read file list from floppy drive
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .error
  move.l     chip_mem_ptr(pc),a3                             ; at this point in program flow there is nothing in chip mem area, so just use its beginning
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
  bsr.s      .save_a4_and_a5
  endif

  rts

.save_a4_and_a5:
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  lea.l      disk_struct_ptr(pc),a0
  move.l     a4,(a0)
  rts

;
; Includes
;
  include    "files_index.i"
  include    "../common/src/system/bcd.asm"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/control.asm"
  include    "../common/src/system/keyboard.asm"
  include    "../common/src/system/joystick.asm"
  include    "../common/src/system/fade.asm"
  include    "../a100/src/ingame/ingame.asm"
  include    "../a100/src/ingame/playfield.asm"
  include    "../a100/src/ingame/brick_selectors.asm"
  include    "../a100/src/ingame/bricks.asm"
  include    "../a100/src/ingame/events.asm"
  include    "../a100/src/ingame/sfx.asm"
  include    "../a100/src/ingame/score.asm"
  include    "../a100/src/ingame/game_over_detection.asm"
  include    "../a100/src/ingame/timer.asm"
  include    "../a100/src/highscores/highscores.asm"
  include    "../a100/src/highscores/view.asm"
  include    "../a100/src/highscores/sfx.asm"
  include    "../a100/src/mainmenu/mainmenu.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"