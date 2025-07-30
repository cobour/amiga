
; FOR USE_TRACKDISK ONLY
; needs defined MAIN_CODE_FILE and MAIN_CODE_FILE_SIZE

  ; set first 4 colors to black
  lea.l      $dff180,a0
  moveq.l    #0,d0
  move.l     d0,(a0)+
  move.l     d0,(a0)

alloc:
  moveq.l    #Mem1MB,d0
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      error

  ; init disk
  move.l     a5,a3
  bsr        disk_init
  tst.l      d0
  bne.s      error

  ; read code file
  bsr        disk_begin_io
  move.l     a4,a2
  add.l      other_mem_size(pc),a2
  sub.l      #MAIN_CODE_FILE_SIZE+512,a2
  move.l     a5,a3
  move.l     #MAIN_CODE_FILE,d4
  bsr        disk_read_file
  tst.l      d0
  bne.s      error
  bsr        disk_end_io

  ; jump to loaded code
  jmp        (a2)

; do not start the game but exit to dos
error:
  lea.l      dos_name(pc),a1
  jsr        FindResident(a6)
  tst.l      d0
  beq.s      dos_lib_not_found
  move.l     d0,a0
  move.l     22(a0),a0                          ; DosInit
  moveq.l    #0,d0
  rts
dos_lib_not_found:
  moveq.l    #-1,d0
  rts

dos_name:  
  dc.b       "dos.library",0
  even

  include    "../common/src/system/exec.asm"
  include    "../common/src/system/disk.asm"