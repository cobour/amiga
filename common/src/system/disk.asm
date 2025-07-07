  ifnd       DISK_ASM
DISK_ASM equ 1

  include    "../common/src/system/disk.i"

; inits disk access
; in:
;   a3 - pointer to 512 byte read buffer (must be in chip mem)
;   a4 - pointer to disk-struct
; out:
;   d0 - zero for success, other for error
disk_init:
  movem.l    d1-d7/a0-a6,-(sp)

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS
; open dos.library
  move.l     ExecBase,a6
  lea.l      dos_name(pc),a1
  moveq.l    #0,d0
  jsr        OpenLibrary(a6)
  lea.l      dos_base(pc),a0
  move.l     d0,(a0)
  move.l     d0,a6

  ifd        DEBUG
; debug-launcher uses dh0: for executable, so we need to set current directory
; lock dh0:
  lea.l      dos_dh0_name(pc),a0
  move.l     a0,d1
  move.l     #AccessRead,d2
  jsr        Lock(a6)
  lea.l      dos_dh0_lock(pc),a0
  move.l     d0,(a0)

; set current directory to dh0:
  move.l     d0,d1
  jsr        CurrentDir(a6)
  lea.l      dos_old_curdir(pc),a0
  move.l     d0,(a0)
  endif                                               ; ifd DEBUG
  endif                                               ; ifd USE_DOS

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK
  bsr        disk_begin_io
  bsr.s      .read_file_list
  bsr        disk_end_io
  endif                                               ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  fail       'TODO'
  endif                                               ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifnd       USE_DOS

; scans disk for DAT-files
.read_file_list:
  moveq.l    #DiskDriveNum,d5
  ; read rootblock
  move.l     #RbBlocknumber,d6                        ; number of block to read
  bsr        disk_internal_read_block
  tst.l      d0
  bne        .error

  ; search for root entries
  move.l     a3,a0
  lea.l      RbHashTableFileHeaderBlocks(a0),a0
  lea.l      disk_file_header_blocks(a4),a1
  moveq.l    #RbHashTableFileHeaderBlocksSize-1,d7
.search_loop:
  move.l     (a0)+,d0
  tst.l      d0
  beq.s      .search_loop_next
  move.l     d0,(a1)+
.search_loop_next:
  dbf        d7,.search_loop

  ; read file header blocks
  lea.l      disk_file_header_blocks(a4),a0
  lea.l      disk_dat_files(a4),a1
.read_file_header_blocks_loop:
  move.l     (a0)+,d6
  tst.l      d6
  beq.s      .read_file_header_blocks_end
  bsr.s      .read_file_header_block
  tst.l      d0
  bne.s      .error
  bra.s      .read_file_header_blocks_loop
.read_file_header_blocks_end:
  rts

; reads a file header block and adds metadata to file-list when dat-file
; in:
;   a1 - pointer to dat_files
;   a3 - pointer to 512 byte read buffer (must be in chip mem)
;   a4 - pointer to disk-struct
;   d5 - which floppy drive (0-3)
;   d6 - blocknumber of file header block
; out:
;   a1 - maybe incremented pointer to dat_files
;   d0 - zero for success, other for error
.read_file_header_block:
  movem.l    d1-d7/a0/a2-a6,-(sp)
  bsr        disk_internal_read_block
  tst.l      d0
  bne.s      .rfhb_error

  ; is it a dat-file?
  move.b     FhbFilenameLength(a3),d0
  cmp.b      #8,d0
  bne.s      .no_dat_file
  moveq.l    #0,d0
  lea.l      FhbFilename+4(a3),a2                     ; +4 because we just want the extension (filenames are like F000.dat)
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  move.l     #".dat",d1
  cmp.l      d0,d1
  bne.s      .no_dat_file

  ; dat-file found - put filename and first data block in dat_files
  moveq.l    #0,d0
  lea.l      FhbFilename(a3),a2
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  lsl.l      #8,d0
  move.b     (a2)+,d0
  move.l     d0,(a1)+
  move.l     FhbFirstDataBlock(a3),(a1)+

.no_dat_file:

  ; check hash_chain for files with same hash value => recursion
  move.l     FhbHashChain(a3),d0
  tst.l      d0
  beq.s      .no_hash_chain
  move.l     d0,d6
  bsr.s      .read_file_header_block
  tst.l      d0
  bne.s      .rfhb_error

.no_hash_chain:
  movem.l    (sp)+,d1-d7/a0/a2-a6
  moveq.l    #0,d0
  rts

.rfhb_error:
  movem.l    (sp)+,d1-d7/a0/a2-a6
  moveq.l    #1,d0
  rts

  endif                                               ; ifnd USE_DOS

; cleans up at end of program
disk_cleanup:

  ; USE_DISK_DMA not necessary
  ; USE_TRACKDISK not necessary

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS
  movem.l    d0-d7/a0-a6,-(sp)

  ifd        DEBUG
; reset current directory
  move.l     dos_base(pc),a6
  move.l     dos_old_curdir(pc),d1
  jsr        CurrentDir(a6)

; unlock DH0:
  move.l     dos_dh0_lock(pc),d1
  jsr        UnLock(a6)
  endif                                               ; ifd DEBUG

; close dos.library
  move.l     ExecBase,a6
  move.l     dos_base(pc),a1
  jsr        CloseLibrary(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  endif                                               ; ifd USE_DOS

  rts

; reads file from floppy disk
; in:
;   a2 - pointer to target where file data will be stored
;   a3 - pointer to 512 byte read buffer (must be in chip mem)
;   a4 - pointer to disk-struct
;   d4 - filename (first 4 chars before dot)
; out:
;   d0 - zero for success, other for error
disk_read_file:
  movem.l    d1-d7/a0-a6,-(sp)

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS
; remap parameters
  move.l     a2,d6
  lea.l      dos_filename(pc),a0
  move.l     d4,(a0)
  move.l     a0,d1
; open file for read
  move.l     #ModeOldFile,d2
  move.l     dos_base(pc),a6
  jsr        Open(a6)
  tst.l      d0
  beq.s      .error

  lea.l      dos_file_handle(pc),a0
  move.l     d0,(a0)

; read data from file
  move.l     dos_file_handle(pc),d1
  move.l     d6,d2
  move.l     #880*1024,d3                             ; max possible file size
  jsr        Read(a6)
  tst.l      d0
  blt.s      .error

; close file
  move.l     dos_file_handle(pc),d1
  jsr        Close(a6)
  endif                                               ; ifd USE_DOS

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifnd       USE_DOS

  ; find first block of file
  lea.l      disk_dat_files(a4),a1
.find_first_block_loop:
  move.l     (a1),d0
  tst.l      d0
  beq.s      .error                                   ; file not found
  cmp.l      d0,d4
  beq.s      .file_found
  addq.l     #8,a1
  bra.s      .find_first_block_loop
.file_found:
  move.l     4(a1),d6                                 ; first data block

.read_file_data_loop:
  tst.l      d6                                       ; eof
  beq.s      .success
  bsr        disk_internal_read_block
  tst.l      d0
  bne.s      .error

  ; data copy - inner loop
  move.l     FdbDataSize(a3),d7
  subq.l     #1,d7
  lea.l      FdbData(a3),a1
.copy_file_data_loop:
  move.b     (a1)+,(a2)+
  dbf        d7,.copy_file_data_loop

  move.l     FdbNextDataBlock(a3),d6
  bra.s      .read_file_data_loop

  endif                                               ; ifnd USE_DOS

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts


; initializes disk io
; in:
;   a4 - pointer to disk-struct
; out:
;   d0 - zero for success, other for error
disk_begin_io:
  movem.l    d1-d7/a0-a6,-(sp)

  ; USE_DOS not necessary

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK

  ; AllocSignal
  move.l     ExecBaseD,a6
  moveq.l    #-1,d0
  jsr        AllocSignal(a6)
  tst.b      d0
  blt        .error

  ; set signal in message_port
  lea.l      disk_message_port(a4),a2
  move.b     d0,MpSignalNumber(a2)

  ; FindTask
  sub.l      a1,a1
  jsr        FindTask(a6)
  tst.l      d0
  beq        .error

  ; fill message_port struct
  move.l     d0,MpSignalTask(a2)
  clr.b      MpFlags(a2)
  move.b     #NodeTypeMessage,MpNodeType(a2)
  move.b     #120,MpPriority(a2)
  lea.l      MpMessageList(a2),a0
  move.l     a0,(a0)
  addq.l     #4,(a0)
  clr.l      4(a0)
  move.l     a0,8(a0)

  ; OpenDevice
  lea.l      disk_io_std_req(a4),a1
  move.b     #NodeTypeMessagePort,IoSrNodeType(a1)
  move.l     a2,IoSrMessagePort(a1)
  lea.l      .trackdisk_device_name(pc),a0
  moveq.l    #DiskDriveNum,d0
  moveq.l    #0,d1
  jsr        OpenDevice(a6)
  tst.l      d0
  bne.s      .error
  bra.s      .success
.trackdisk_device_name:
  dc.b       "trackdisk.device",0
  even

  endif                                               ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  fail       'TODO'
  endif                                               ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts


; cleans up after disk io
; in:
;   a4 - pointer to disk-struct
; out:
;   d0 - zero for success, other for error
disk_end_io:
  movem.l    d1-d7/a0-a6,-(sp)

  ; USE_DOS not necessary

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK

  move.l     ExecBaseD,a6

  ; stop floppy drive motors
  lea.l      disk_io_std_req(a4),a1
  clr.l      IoSrLength(a1)
  move.w     #IoCmdNonStandard,IoSrCommand(a1)
  jsr        DoIO(a6)

  ; FreeSignal
  lea.l      disk_message_port(a4),a2
  moveq.l    #0,d0
  move.b     MpSignalNumber(a2),d0
  jsr        FreeSignal(a6)

  ; CloseDevice
  lea.l      disk_io_std_req(a4),a1
  jsr        CloseDevice(a6)

  endif                                               ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  fail       'TODO'
  endif                                               ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts

; reads one block from floppy disk
; FOR INTERNAL USE OF DISK.ASM ONLY
; in:
;   a3 - pointer to 512 byte read buffer (must be in chip mem)
;   a4 - pointer to disk-struct
;   d6 - number of block
; out:
;   d0 - zero for success, other for error
disk_internal_read_block:
  movem.l    d1-d7/a0-a6,-(sp)

  ; USE_DOS not necessary

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK

  move.l     ExecBaseD,a6

  ; DoIO - read block
  lea.l      disk_io_std_req(a4),a1
  move.l     a3,IoSrData(a1)
  move.w     #IoCmdRead,IoSrCommand(a1)               ; CMD_READ
  move.l     #512,IoSrLength(a1)                      ; length of one block
  lsl.l      #8,d6                                    ; block number * 512
  add.l      d6,d6                                    ; block number * 512
  move.l     d6,IoSrOffset(a1)
  jsr        DoIO(a6)                                 ; call DoIO
  tst.l      d0
  bne.s      .error

  endif                                               ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  fail       'TODO'
  endif                                               ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0                                    ; ignore error here, may be just a warning, program will not work if it is an error anyway
  rts

  ifnd       BOOTBLOCK

; writes data to a single-block file
; in:
;   d4 - filename (first 4 chars before dot)
;   d7 - length of data in bytes (must not be more than 488 bytes!!)
;   a2 - pointer to data to be written
;   a3 - pointer to 512 byte buffer (must be in chip mem)
;   a4 - pointer to disk-struct
; out:
;   d0 - zero for success, other for error
disk_write_file:
  movem.l    d1-d7/a0-a6,-(sp)

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS

; remap parameter
  move.l     a2,d6
  lea.l      dos_filename(pc),a0
  move.l     d4,(a0)
  move.l     a0,d1

; open file for write
  move.l     #ModeNewFile,d2
  move.l     dos_base(pc),a6
  jsr        Open(a6)
  tst.l      d0
  beq.s      .error

  lea.l      dos_file_handle(pc),a0
  move.l     d0,(a0)

; write data to file
  move.l     dos_file_handle(pc),d1
  move.l     d6,d2
  move.l     d7,d3
  jsr        Write(a6)
  tst.l      d0
  blt.s      .error

; close file
  move.l     dos_file_handle(pc),d1
  jsr        Close(a6)

  endif                                               ; ifd USE_DOS

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK

  ; check for write protection on disk
  move.l     ExecBaseD,a6
  lea.l      disk_io_std_req(a4),a1
  move.w     #IoCmdProtStatus,IoSrCommand(a1)
  jsr        DoIO(a6)
  tst.l      d0
  bne.s      .error
  tst.l      IoSrActual(a1)                           ; zero = not write-protected ; non-zero = write-protected
  bne.s      .error

  ; find data block of file
  lea.l      disk_dat_files(a4),a1
.find_first_block_loop:
  move.l     (a1),d0
  tst.l      d0
  beq.s      .error                                   ; file not found
  cmp.l      d0,d4
  beq.s      .file_found
  addq.l     #8,a1
  bra.s      .find_first_block_loop
.file_found:
  move.l     4(a1),d6                                 ; data block

  ; read block from disk
  bsr.s      disk_internal_read_block
  tst.l      d0
  bne.s      .error

  ; copy data to block buffer
  subq.l     #1,d7
  move.l     a2,a0
  move.l     a3,a1
  lea.l      24(a1),a1                                ; 24 bytes = size of data block header
.copy_loop:
  move.b     (a0)+,(a1)+
  dbf        d7,.copy_loop

  ; DoIO - write block to trackdisk buffer
  move.l     ExecBaseD,a6
  lea.l      disk_io_std_req(a4),a1
  move.w     #IoCmdWrite,IoSrCommand(a1)
  jsr        DoIO(a6)
  tst.l      d0
  bne.s      .error

  ; DoIO - write trackdisk buffer to disk
  move.w     #IoCmdUpdate,IoSrCommand(a1)
  jsr        DoIO(a6)
  tst.l      d0
  bne.s      .error

  endif                                               ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  fail       'TODO'
  endif                                               ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts

  endif                                               ; ifnd BOOTBLOCK

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS
dos_name:         
  dc.b       "dos.library",0
  even
dos_base:         
  dc.l       0
dos_file_handle:
  dc.l       0
dos_filename:
  dc.b       0,0,0,0                                  ; space for filename before the dot
  dc.b       ".dat",0
  even

  ifd        DEBUG
dos_dh0_name:
  dc.b       "dh0:",0
  even
dos_dh0_lock:
  dc.l       0
dos_old_curdir:
  dc.l       0
  endif                                               ; ifd DEBUG
  endif                                               ; ifd USE_DOS

  endif                                               ; ifnd DISK_ASM
