;
; you must define USE_TRACKDISK or USE_DOS before including this!!
;

  ifnd       DATAFILES_ASM
DATAFILES_ASM equ 1

  include    "../common/src/system/datafiles.i"

; loads and unzips the given other-mem and chip-mem datafiles
; in:
;   d1 - filename of other-mem datafile
;   d2 - filename of chip-mem datafile
;   d5 - pointer to 512 byte buffer in chip mem (only needed when USE_TRACKDISK)
;   d6 - pointer to filebuffer in any mem
;   a0 - target pointer of other-mem datafile
;   a1 - target pointer of chip-mem datafile
; out:
;   d0 - zero if successfull, non-zero otherwise
datafiles_load_and_unzip:
  movem.l    d3-d4/d7/a2-a6,-(sp)

  ; init
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .error

  ; load other-mem file
  move.l     d1,d4
  move.l     d6,a2
  move.l     d5,a3
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_read_file
  tst.l      d0
  bne.s      .error

  ; unzip other-mem file
  move.l     a0,a4
  move.l     d6,a5
  bsr        inflate

  ; load chip-mem file
  move.l     d2,d4
  move.l     d6,a2
  move.l     d5,a3
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_read_file
  tst.l      d0
  bne.s      .error

  ; unzip chip-mem file
  move.l     a1,a4
  move.l     d6,a5
  bsr        inflate

  ; cleanup
  move.l     disk_struct_ptr(pc),a4
  bsr        disk_end_io
  tst.l      d0
  bne.s      .error

  ; set pointers
  bsr.s      .datafiles_set_pointers_in_index

  ; do type-specific initializations
  bsr.s      .datafiles_type_specific_init

  ; success
  movem.l    (sp)+,d3-d4/d7/a2-a6
  moveq.l    #0,d0
  rts
.error:
  movem.l    (sp)+,d3-d4/d7/a2-a6
  moveq.l    #-1,d0
  rts

; updates the offset-fields in index entries to the absolute pointers to the raw data of each entry
; called after loading and unzipping the files
; in:
;   a0 - points to other-mem-file
;   a1 - points to chip-mem-file
.datafiles_set_pointers_in_index:
  ; save pointer to index
  lea.l      datafiles_index(pc),a2
  move.l     a0,(a2)

  ; prepare loop
  move.l     a0,a2
  moveq.l    #0,d5
  move.l     #$01000000,d6

  moveq.l    #0,d7
  move.w     (a0)+,d7
  subq.l     #1,d7
.loop:
  ; skip ID and type
  addq.l     #(df_idx_ptr_rawdata-df_idx_id),a0

  move.l     (a0),d0
  cmp.l      d0,d6
  bgt.s      .om_file
  ; cm-file
  sub.l      d6,d0
  add.l      a1,d0
  bra.s      .next
.om_file:
  add.l      a2,d0

.next:
  move.l     d0,(a0)+
  move.w     (a0)+,d5
  add.l      d5,a0
  dbf        d7,.loop

  rts

; does type-specific initializations
; called after pointers in index are set
.datafiles_type_specific_init:
  move.l     datafiles_index(pc),a0

  moveq.l    #0,d7
  move.w     (a0)+,d7
  subq.l     #1,d7
  moveq.l    #df_idx_header_sizeof,d6
  moveq.l    #0,d5
.loop2:
  cmp.l      #df_st_sfx,df_idx_source_type(a0)
  bne.s      .next_no_wav

  ; wav
  move.l     df_idx_ptr_rawdata(a0),df_idx_metadata+sfx_ptr(a0)

.next_no_wav:

  move.w     df_idx_metadata_sizeof(a0),d5
  add.l      d5,a0
  add.l      d6,a0
  dbf        d7,.loop2

  rts

; returns pointer to df_idx-struct for given file-ID
; in:
;   d0 - file-ID
; out:
;   a0 - pointer to df_idx-struct or zero if not found
datafiles_get_pointer:
  movem.l    d6-d7,-(sp)
  move.l     datafiles_index(pc),a0
  moveq.l    #0,d6
  moveq.l    #0,d7
  move.w     (a0)+,d7
  subq.l     #1,d7
.loop:
  cmp.l      (a0),d0
  beq.s      .exit

  ; set to next  
  add.l      #(df_idx_header_sizeof-2),a0
  move.w     (a0)+,d6
  add.l      d6,a0
  dbf        d7,.loop

  ; not found
  sub.l      a0,a0
.exit:
  movem.l    (sp)+,d6-d7
  rts

datafiles_index:
  dc.l       0

disk_struct_ptr:
  dc.l       0

  endif                                                            ; ifnd DATAFILES_ASM
