  ifnd       COMMON_INIT_ASM
COMMON_INIT_ASM equ 1

; does global init
; out:
;   d0 - zero = success, non-zero = error
common_init:

  ; bootblock has allocated mem, pointers in a4 and a5
  ; bootblock has also read file directory block

  ; standard exe must allocate mem amd read file directory block itself

  ifd        STANDARD_EXE

  moveq.l    #Mem1MB,d0
  bsr        exec_alloc_mem

  endif                                ; ifd STANDARD_EXE

  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  lea.l      disk_struct_ptr(pc),a0
  move.l     a4,(a0)

  ifnd       BOOTBLOCK

  move.l     a5,a3
  move.l     other_mem_ptr(pc),a4
  bsr        disk_init                 ; will set d0 as return value

  else 

  moveq.l    #0,d0

  endif                                ; ifnd BOOTBLOCK

  rts

  endif                                ; ifnd COMMON_INIT_ASM
