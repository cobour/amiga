  ifnd       COMMON_INIT_ASM
COMMON_INIT_ASM equ 1

; does global init
; out:
;   d0 - zero = success, non-zero = error
common_init:

  ; bootblock has allocated mem, pointers in a4 and a5
  ; loader_dd: bootblock did not read file directory block, but gives values for disk_direct in d0,d1
  ; loader_td: bootblock also read file directory block

  ; standard exe must allocate mem and read file directory block itself


  ifd        STANDARD_EXE
  bsr        ctrl_get_vbr
  moveq.l    #Mem1MB,d0
  bsr        exec_alloc_mem
  else                                 ; ifd STANDARD_EXE
  ifd        USE_DISK_DMA
  lea.l      dd_track(pc),a0
  move.w     d0,(a0)
  lea.l      dd_drive(pc),a0
  move.w     d1,(a0)
  lea.l      ctrl_vbr(pc),a0           ; control.asm
  move.l     d2,(a0)
  lea.l      cpu_type(pc),a0           ; control.asm
  move.w     d3,(a0)
  endif                                ; ifd USE_DISK_DMA
  endif                                ; ifd STANDARD_EXE

  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  lea.l      disk_struct_ptr(pc),a0
  move.l     a4,(a0)

  ifnd       USE_TRACKDISK
  move.l     a5,a3
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_init                 ; will set d0 as return value
  endif                                ; ifd USE_DISK_DMA

  moveq.l    #0,d0
  rts

  endif                                ; ifnd COMMON_INIT_ASM
