  ifnd       EXEC_ASM
EXEC_ASM                 equ 1

ExecBase                 equ $4
OpenLibrary              equ -$198
CloseLibrary             equ -$19e
AllocMem                 equ -$c6
FreeMem                  equ -$d2
ColdReboot               equ -$2d6
Supervisor               equ -$1e
FindResident             equ -$60

KickstartV36             equ $24
LibVersion               equ $14

EndOfKickstartROM        equ $01000000
KickstartOffsetResetFunc equ -$14

MEMF_ANY                 equ $0
MEMF_PUBLIC              equ $1
MEMF_CHIP                equ $2
MEMF_CLEAR               equ $10000

Mem512K                  equ 0
Mem1MB                   equ 1
MemCustom                equ 2

; Memory sizes
; When program is loaded from bootblock and Amiga has 512k chip + 512k chip/slow/fast mem, 
; then these sizes are allocatable under KickStart 1.3, 2.0 and 3.1
ChipMemSize              equ 500650
OtherMemSize             equ 475100
; When program is loaded from bootblock and Amiga has 512k chip
; then this size is allocatable under KickStart 1.3, 2.0 and 3.1
ChipMemSize512k          equ 453700             ; 1.3: 476000, 2.0: 454900, 3.1: 453700

; Allocates memory
; in:
;   d0 - zero = 512k chip only, 1 = 512k chip and 512k other, 2 = chip-mem size in d1 and other-mem size in d2
; out:
;   d0 - zero if successfull, non-zero otherwise
;   a5 - pointer to chip mem block
;   a4 - pointer to other mem block or zero
exec_alloc_mem:
  movem.l    d1-d7/a0-a3/a6,-(sp)

  ; 512k?
  tst.l      d0
  beq.s      .chip_only

  move.l     d1,d5
  move.l     d2,d6

  ; 1M or custom?
  moveq.l    #MemCustom,d3
  cmp.l      d3,d0
  beq.s      .do_alloc
  move.l     #ChipMemSize,d5
  move.l     #OtherMemSize,d6

.do_alloc:
  ; save sizes
  lea.l      chip_mem_size(pc),a0
  move.l     d5,(a0)
  lea.l      other_mem_size(pc),a0
  move.l     d6,(a0)

  ; alloc chip
  move.l     d5,d0
  moveq.l    #MEMF_PUBLIC|MEMF_CHIP,d1
  move.l     ExecBase,a6
  jsr        AllocMem(a6)
  tst.l      d0
  beq.s      .error
  move.l     d0,a5

  ; alloc other
  move.l     d6,d0
  moveq.l    #MEMF_PUBLIC|MEMF_ANY,d1
  move.l     ExecBase,a6
  jsr        AllocMem(a6)
  tst.l      d0
  beq.s      .error
  move.l     d0,a4

  bra.s      .exit
.chip_only:
  ; save sizes
  lea.l      chip_mem_size(pc),a0
  move.l     d5,(a0)
  lea.l      other_mem_size(pc),a0
  clr.l      (a0)

  ; alloc chip
  move.l     #ChipMemSize512k,d0
  moveq.l    #MEMF_PUBLIC|MEMF_CHIP,d1
  move.l     ExecBase,a6
  jsr        AllocMem(a6)
  tst.l      d0
  beq.s      .error
  move.l     d0,a5
  sub.l      a4,a4

.exit:
  moveq.l    #0,d0
  movem.l    (sp)+,d1-d7/a0-a3/a6
  rts
.error:
  moveq.l    #-1,d0
  movem.l    (sp)+,d1-d7/a0-a3/a6
  rts

  ifd        IS_STANDARD_EXE
; Frees allocated memory blocks
exec_free_mem:
  movem.l    d0-d7/a0-a6,-(sp)

  move.l     chip_mem_ptr(pc),d0
  tst.l      d0
  beq.s      .no_chip
  move.l     d0,a1
  move.l     chip_mem_size(pc),d0
  move.l     ExecBase,a6
  jsr        FreeMem(a6)

.no_chip:
  move.l     other_mem_ptr(pc),d0
  tst.l      d0
  beq.s      .no_other
  move.l     d0,a1
  move.l     other_mem_size(pc),d0
  move.l     ExecBase,a6
  jsr        FreeMem(a6)

.no_other:
  movem.l    (sp)+,d0-d7/a0-a6
  rts

  else                                          ; ifd IS_STANDARD_EXE

; Performs a reset
exec_reboot:
  move.l     ExecBase,a6
  cmp.w      #KickstartV36,LibVersion(a6)
  blt.s      .1
  jmp        ColdReboot(a6)
.1:
  not.l      ExecBase                           ; invalidate ExecBase in memory => lets boot-checks fail and force exec to init everything
  lea.l      .2(pc),a5
  jsr        Supervisor(a6)
  CNOP       0,4
.2:  
  lea.l      EndOfKickstartROM,a0
  sub.l      KickstartOffsetResetFunc(a0),a0
  move.l     4(a0),a0
  subq.l     #2,a0
  reset
  jmp        (a0)

  endif                                         ; else - ifd IS_STANDARD_EXE
chip_mem_ptr:
  dc.l       0
other_mem_ptr:
  dc.l       0

chip_mem_size:
  dc.l       0
other_mem_size:
  dc.l       0

  endif                                         ; ifnd EXEC_ASM