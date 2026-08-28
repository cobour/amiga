  ifnd       LOADER_DD_ASM
LOADER_DD_ASM equ 1

  include    "main_code.i"
  include    "../common/src/system/loader.i"
  include    "../common/src/system/custom.i"

  ; check cpu type and get vbr
  move.w     $128(a6),d3                               ; exec AttnFlags
  btst       #0,d3                                     ; 68010 or greater?
  beq.s      .just_68000
  lea.l      .get_vbr_handler(pc),a5
  jsr        -$1e(a6)                                  ; Supervisor
  bra.s      .check_cpu_type_end
.get_vbr_handler:
  dc.l       $4e7a2801                                 ; = movec vbr,d2
  rte
.just_68000:
  moveq.l    #0,d2
.check_cpu_type_end:
  jsr        -$96(a6)                                  ; SuperState

  ; fade color zero to black on KS 1.x
  move.w     20(a6),d0                                 ; version of exec.library
  lea.l      CUSTOM,a6
  lea.l      .copperlist(pc),a0
  move.l     a0,COP1LC(a6)
  move.w     #%0011111111111111,INTENA(a6)             ; no ints
  move.w     #%0011111111111111,INTREQ(a6)             ; at all
  cmp.b      #36,d0                                    ; KS 2.x or greater
  bge.s      .fade_out_end
  move.w     #$0eee,d1
  move.l     #$1ff00,d4
.fade_out_loop:
  move.w     d1,6(a0)
  beq.s      .fade_out_end
.fade_out_wait_vbl:  
  move.l     VPOSR(a6),d0
  and.l      d4,d0
  cmp.l      #300<<8,d0
  bne.s      .fade_out_wait_vbl
  sub.w      #$0111,d1
.fade_out_wait_vbl2:  
  move.l     VPOSR(a6),d0
  and.l      d4,d0
  cmp.l      #302<<8,d0
  bne.s      .fade_out_wait_vbl2
  bra.s      .fade_out_loop
.fade_out_end:
  clr.w      6(a0)

  ; check memory requirements

  ; do we have 512kb chip ram?
  move.w     #$1887,d0
  lea.l      $7fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  bne.s      error

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

.copperlist:
  dc.w       BPLCON0,BplColorOn
  dc.w       COLOR00,$0fff
  dc.w       $ffff,$fffe

error:
  move.w     #$f00,COLOR00(a6)
  bra.s      error

; restart point after jmp (a1)
load_main_code:
  moveq.l    #DISK_DRIVE_BIT,d0
  bsr.s      dd_init

  ; a0 points to begin of other-mem (exactly behind stack)
  lea.l      $50000,a1
  moveq.l    #MAIN_CODE_FILE_START_BLOCK,d0
  moveq.l    #MAIN_CODE_FILE_BLOCK_COUNT,d1
  bsr        dd_load_file

  move.w     dd_track(pc),d0
  move.w     dd_drive(pc),d1
  ; d2 (vbr base) is still set
  ; d3 (cpu type) is still set
  move.l     a0,a4
  add.l      #MAIN_CODE_SIZE,a4
  move.l     #$400,a5
  jmp        (a0)

  include    "../common/src/system/disk_direct.asm"

_end:

  endif                                                ; ifnd LOADER_DD_ASM
