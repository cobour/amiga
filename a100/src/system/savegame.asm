  ifnd       SAVEGAME_ASM
SAVEGAME_ASM equ 1

  include    "src/system/savegame.i"
  include    "files_index.i"

; in:
;   a2 - target pointer
; out:
;   d0 - zero for success, other for error
sg_load:
  movem.l    d5-d7/a0,-(sp)
  lea.l      sg_filename(pc),a0
  move.l     a0,d5
  move.l     a2,d6
  move.l     #s000_unzipped_filesize,d7
  bsr        dos_readfile
  movem.l    (sp)+,d5-d7/a0
  rts

sg_filename:
  dc.b       "S000.dat",0
  even

; in:
;   a3 - pointer to struct sg_data*
; out:
;   d0 - zero if unused, other if used 
sg_is_used:
  move.l     sg_data_score(a3),d0
  rts

; in:
;   a2 - pointer to struct sg_data*
;   a3 - buffer in chip ram
; out:
;   d0 - zero for success, other for error
sg_save:
  move.l     other_mem_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .exit

  moveq.l    #s000_unzipped_filesize,d7
  move.l     #fn_savegame,d4
  bsr        disk_write_file
  ; ignore possible write error
  moveq.l    #0,d0

  bsr        disk_end_io
.exit
  rts

  endif                                    ; ifnd SAVEGAME_ASM
