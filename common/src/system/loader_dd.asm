  ifnd       LOADER_DD_ASM
LOADER_DD_ASM equ 1

  include    "main_code.i"
  include    "../common/src/system/loader.i"

  ; set first 4 colors to black
  lea.l      $dff180,a0
  moveq.l    #0,d0
  move.l     d0,(a0)+
  move.l     d0,(a0)

; first of all check memory requirements

  ; do we have 512kb chip ram?
  move.w     #$1887,d0
  lea.l      $7fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  bne.s      error

  ; do we have 512kb fast ram?
  lea.l      $27fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  beq.s      .other_mem_found

  ; do we have 512kb slow ram?
  lea.l      $c7fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  beq.s      .other_mem_found

  ; do we have another 512kb chip ram?
  lea.l      $ffffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  bne.s      error

.other_mem_found:
  sub.l      #$7fffe,a0                                ; a0 -  beginning of other mem block of 512kb

; from now on we may use the first 512kb chip mem and 512kb other mem (pointer in a0)

; set stack pointer to beginning of other mem
  lea.l      STACK_SIZE(a0),a0
  move.l     a0,a7

; copy bootblock code to end of 256kb chip ram block
; (so we can be sure which memory regions to use for disk dma without overwriting the code)
  move.l     #$40000,a1
  lea.l      _end+2(pc),a3
  lea.l      load_main_code(pc),a2
.copy_loop:
  move.w     -(a3),-(a1)
  cmp.l      a3,a2
  bne.s      .copy_loop
  jmp        (a1)

error:
  move.w     #$f00,$180(a5)
  bra.s      error

; restart point after jmp (a1)
load_main_code:

  lea.l      $dff000,a6
  move.w     #%0011111111111111,$9A(a6)                ; no ints
  move.w     #%0011111111111111,$9C(a6)                ; at all

  moveq.l    #DISK_DRIVE_BIT,d0
  bsr.s      dd_init

  ; a0 points to begin of other-mem (right behind 1kb stack)
  lea.l      $50000,a1
  moveq.l    #MAIN_CODE_FILE_START_BLOCK,d0
  moveq.l    #MAIN_CODE_FILE_BLOCK_COUNT,d1
  bsr        dd_load_file

  bsr.s      dd_cleanup

  move.w     dd_track(pc),d0
  move.w     dd_drive(pc),d1
  move.l     a0,a4
  add.l      #MAIN_CODE_SIZE,a4
  move.l     #$400,a5
  jmp        (a0)

  include    "../common/src/system/disk_direct.asm"

_end:

  endif                                                ; ifnd LOADER_DD_ASM
