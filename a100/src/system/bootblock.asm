
; DO NOT include this file anywhere!

; define profile because adf-generator-tool does not support additional assembler options (e.g. -DRELEASE)
RELEASE equ 1

  dc.b       "DOS",0                                    ; disk type
  dc.l       0                                          ; checksum
  dc.l       880                                        ; rootblock

  ; set first 4 colors to black
  lea.l      $dff180,a0
  moveq.l    #0,d0
  move.l     d0,(a0)+
  move.l     d0,(a0)

alloc:
  moveq.l    #1,d0
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      error

  ; begin disk io
  bsr        disk_begin_io

  ; read file list
  move.l     a5,a3
  bsr        disk_read_file_list
  tst.l      d0
  bne.s      error

  ; calc memory location for code
  move.l     a4,a2
  add.l      #OtherMemSize-c000_unzipped_filesize,a2

  ; read code file
  move.l     a5,a3
  move.l     #fn_main_code_file,d4
  bsr        disk_read_file
  tst.l      d0
  bne.s      error

  ; end disk io
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
  move.l     22(a0),a0                                  ; DosInit
  moveq.l    #0,d0
  rts
dos_lib_not_found:
  moveq.l    #-1,d0
  ; TODO: how to show error in dos window?
  rts

dos_name:  
  dc.b       "dos.library",0
  even

  include    "src/globals.i"
  include    "asm_files_index.i"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/disk.asm"