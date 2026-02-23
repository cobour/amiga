;
; to fully debug game with standard app and symbols
;

DISK_DRIVE_BIT    equ 4                         ; default to df1 for debugging

MEM_1MB_ALL_DEBUG equ 1                         ; signalling exec_alloc_mem that we are debugging with a standard app, but in release mode we use ALL of ram

  include    "main_code.i"
  include    "../common/src/system/custom.i"

  moveq.l    #-1,d0
  move.w     #DISK_DRIVE_BIT,d1
  lea.l      dd_track(pc),a0
  move.w     d0,(a0)
  lea.l      dd_drive(pc),a0
  move.w     d1,(a0)

  lea.l      CustomBase,a6
  move.w     #%0000000000100000,INTENA(a6)      ; disable vbl irq
  move.w     #%0000000000100000,INTENAR(a6)     ; otherwise wait diskready does loop eternally

  include    "../../hydron.asm"
