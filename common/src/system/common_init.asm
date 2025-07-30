  ifnd       COMMON_INIT_ASM
COMMON_INIT_ASM equ 1

; does global init
; out:
;   d0 - zero = success, non-zero = error
common_init:

  ifd        STANDARD_EXE

  moveq.l    #Mem1MB,d0
  bsr        exec_alloc_mem

  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)

  ifd        USE_TRACKDISK

  move.l     a5,a3
  move.l     other_mem_ptr(pc),a4
  bsr        disk_init

  endif                              ; ifd USE_TRACKDISK

  endif                              ; ifd STANDARD_EXE

  ifd        BOOTBLOCK

  ; bootblock has allocated mem, pointers in a4 and a5
  ; bootblock has also read file directory block
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  moveq.l    #0,d0

  endif                              ; ifd BOOTBLOCK

  rts

  endif                              ; ifnd COMMON_INIT_ASM
