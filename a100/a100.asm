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
  bsr.s      .init_ram
  bsr        ctrl_save_orig_system_state
  bsr        dos_init

  SETPTRS
  clr.l      c_om_framecounter(a4)                           ; global framecounter for all parts
  move.b     #NextPartMainmenu,c_om_next_part(a4)
  move.b     #GameModeInfinite,c_om_gamemode(a4)             ; init here (and not init in mainmenu-part, so once the player changes game mode it keeps the same until reboot)
  
  ; REMOVE ME - for testing
  ;move.l     #$00000099,c_om_score(a4)
  ;move.l     #$00000123,c_om_score(a4)
  ;move.l     #$00000200,c_om_score(a4)
  ;move.l     #$00000234,c_om_score(a4)
  ;move.l     #$00000345,c_om_score(a4)
  ;move.l     #$00000456,c_om_score(a4)
  ;move.l     #$00000567,c_om_score(a4)
  ;move.l     #$000004567,c_om_score(a4)
  ;move.b     #NextPartIngame,c_om_next_part(a4)
  ;move.b     #NextPartHighscores,c_om_next_part(a4)
  ;move.b     #GameModeSpeedRun,c_om_gamemode(a4)
  ;move.b     #GameModeInfinite,c_om_gamemode(a4)
  ; REMOVE ME - for testing

.loop:
  move.l     chip_mem_ptr(pc),a0
  lea.l      c_cm_all_black_copperlist(a0),a0
  bsr        ctrl_set_black_screen

  ; REMOVE ME
  ;lea.l      .filename(pc),a0
  ;move.l     a0,d5
  ;lea.l      .filebuffer(pc),a0
  ;clr.l      (a0)
  ;clr.l      4(a0)
  ;move.l     a0,d6
  ;move.l     #600,d7
  ;bsr        dos_readfile
  ;lea.l      .filebuffer(pc),a0
  ;bra        .behind_dos_test
;.filename:
  ;dc.b       "TST",0
;.filebuffer:
  ;dcb.b      600
;.behind_dos_test:
  ; REMOVE ME

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
  bsr        dos_cleanup
  bsr        exec_free_mem
  moveq.l    #0,d0
  rts
.error
  bsr        exec_free_mem
  moveq.l    #1,d0
  rts

.init_ram:
  ; allocate mem
  moveq.l    #MemScheme,d0
  move.l     #A100ChipMemSize,d1
  move.l     #A100OtherMemSize,d2
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      .error
  ; store pointers
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  rts

;
; Includes
;
  include    "files_index.i"
  include    "../common/src/system/bcd.asm"
  include    "../common/src/system/exec.asm"
;USE_TRACKDISK equ 1
USE_DOS equ 1
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"                 ; REMOVE ME
  include    "../common/src/system/dos.asm"
  include    "../common/src/system/control.asm"
  include    "../common/src/system/keyboard.asm"
  include    "../common/src/system/joystick.asm"
  include    "../common/src/system/fade.asm"
  include    "../a100/src/ingame/ingame.asm"
  include    "../a100/src/ingame/playfield.asm"
  include    "../a100/src/ingame/brick_selectors.asm"
  include    "../a100/src/ingame/bricks.asm"
  include    "../a100/src/system/events.asm"
  include    "../a100/src/system/savegame.asm"
  include    "../a100/src/ingame/sfx.asm"
  include    "../a100/src/ingame/score.asm"
  include    "../a100/src/ingame/game_over_detection.asm"
  include    "../a100/src/ingame/timer.asm"
  include    "../a100/src/highscores/highscores.asm"
  include    "../a100/src/highscores/view.asm"
  include    "../a100/src/highscores/sfx.asm"
  include    "../a100/src/highscores/edit.asm"
  include    "../a100/src/mainmenu/mainmenu.asm"
  include    "../a100/src/mainmenu/menupart.asm"
  include    "../a100/src/mainmenu/sfx.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"