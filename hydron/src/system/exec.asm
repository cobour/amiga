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

MEMF_CHIP                equ $2
MEMF_CLEAR               equ $10000

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
;   d0 - zero = 512k chip only, non-zero = 512k chip and 512k other
; out:
;   d0 - zero if successfull, non-zero otherwise
;   a5 - pointer to chip mem var
;   a4 - pointer to other mem var or zero
exec_alloc_mem:
  movem.l    d1-d7/a0-a3/a6,-(sp)

  ; 512k or 1m
  tst.l      d0
  beq.s      .chip_only

  ; alloc chip
  move.l     #ChipMemSize,d0
  move.l     #MEMF_CHIP,d1                      ; move.l     #MEMF_CHIP|MEMF_CLEAR,d1
  move.l     ExecBase,a6
  jsr        AllocMem(a6)
  tst.l      d0
  beq.s      .error
  move.l     d0,a5

  ; alloc other
  move.l     #OtherMemSize,d0
  moveq.l    #0,d1                              ; move.l     #MEMF_CLEAR,d1
  move.l     ExecBase,a6
  jsr        AllocMem(a6)
  tst.l      d0
  beq.s      .error
  move.l     d0,a4

  bra.s      .exit
.chip_only:

  ; alloc chip
  move.l     #ChipMemSize512k,d0
  move.l     #MEMF_CHIP,d1                      ; move.l     #MEMF_CHIP|MEMF_CLEAR,d1
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

  ifd        DEBUG

; Frees allocated memory blocks
; in:
;    d5 - Pointer to chip mem block
;    d6 - Pointer to other mem block
exec_free_mem:
  movem.l    d0-d7/a0-a6,-(sp)

  tst.l      d5
  beq.s      .no_chip
  move.l     d5,a1
  move.l     #ChipMemSize,d0
  move.l     ExecBase,a6
  jsr        FreeMem(a6)

.no_chip:
  tst.l      d6
  beq.s      .no_other
  move.l     d6,a1
  move.l     #OtherMemSize,d0
  move.l     ExecBase,a6
  jsr        FreeMem(a6)

.no_other:
  movem.l    (sp)+,d0-d7/a0-a6
  rts

  endif                                         ; ifnd  DEBUG

  ifd        RELEASE

; Performs a reset
exec_reboot:
  move.l     ExecBase,a6
  cmp.w      #KickstartV36,LibVersion(a6)
  blt.s      .1
  jmp        ColdReboot(a6)
.1:
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

  endif                                         ; ifnd RELEASE

  endif                                         ; ifnd EXEC_ASM