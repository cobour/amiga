  ifnd       DISK_ASM
DISK_ASM equ 1

  include    "../common/src/system/disk.i"

; inits disk access (one call at beginning of game)
; in:
;   a3 - pointer to read buffer (must be in chip mem) / USE_TRACKDISK 512 byte, USE_DISK_DMA 12800+512 byte
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
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
  endif                                                ; ifd DEBUG
  endif                                                ; ifd USE_DOS

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK
  bsr        disk_begin_io
  bsr.s      .read_file_list
  bsr        disk_end_io
  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  bsr        disk_begin_io
  bsr.s      .read_file_list
  bsr        disk_end_io
  endif                                                ; ifd USE_DISK_DMA

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

  ifd        USE_TRACKDISK

; reads file directory block created by data_tool
.read_file_list:
  movem.l    d1-d7/a0-a6,-(sp)

  moveq.l    #DiskDriveNum,d5
  ; read rootblock
  moveq.l    #RbBlocknumber,d6                         ; number of block to read
  moveq.l    #1,d7
  bsr        disk_internal_read_blocks
  tst.l      d0
  bne        .rfl_exit

  move.w     disk_directory_filecount(a3),d7
  subq.w     #1,d7
  lea.l      disk_directory_sizeof(a3),a3
.loop:
  ; THIS CODE MUST BE CHANGED WHEN disk_file_sizeof CHANGES
  move.l     (a3)+,(a4)+
  move.l     (a3)+,(a4)+
  move.w     (a3)+,(a4)+
  dbf        d7,.loop

  ; empty entry at end of list
  clr.l      (a4)+
  clr.l      (a4)+
  clr.w      (a4)
.rfl_exit:
  movem.l    (sp)+,d1-d7/a0-a6
  rts

  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA

; reads file directory block created by data_tool
.read_file_list:
  movem.l    d1-d7/a0-a6,-(sp)

  ; read rootblock
  moveq.l    #RbBlocknumber,d0                         ; number of block to read
  moveq.l    #1,d1
  move.l     a3,a0
  move.l     a3,a1
  lea.l      512(a1),a1
  bsr        dd_load_file
  tst.l      d0
  bne        .rfl_exit

  move.w     disk_directory_filecount(a3),d7
  subq.w     #1,d7
  lea.l      disk_directory_sizeof(a3),a3
.loop:
  ; THIS CODE MUST BE CHANGED WHEN disk_file_sizeof CHANGES
  move.l     (a3)+,(a4)+
  move.l     (a3)+,(a4)+
  move.w     (a3)+,(a4)+
  dbf        d7,.loop

  ; empty entry at end of list
  clr.l      (a4)+
  clr.l      (a4)+
  clr.w      (a4)
.rfl_exit:
  movem.l    (sp)+,d1-d7/a0-a6
  rts

  endif                                                ; ifd USE_DISK_DMA

; cleans up at end of program
disk_cleanup:

  ; USE_TRACKDISK and USE_DISK_DMA not necessary

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
  endif                                                ; ifd DEBUG

; close dos.library
  move.l     ExecBase,a6
  move.l     dos_base(pc),a1
  jsr        CloseLibrary(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  endif                                                ; ifd USE_DOS

  rts

; reads file from floppy disk
; in:
;   a2 - pointer to read buffer (must be in chip mem) / USE_TRACKDISK 512 byte, USE_DISK_DMA 12800+512 byte
;   a3 - pointer to target where file data will be stored (must be in chip mem)
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
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
  move.l     a3,d6
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
  move.l     #880*1024,d3                              ; max possible file size
  jsr        Read(a6)
  tst.l      d0
  blt.s      .error

; close file
  move.l     dos_file_handle(pc),d1
  jsr        Close(a6)
  endif                                                ; ifd USE_DOS

  ; ***********************
  ; **** USE_TRACKDISK ****
  ; ***********************

  ifd        USE_TRACKDISK

  ; find first block of file
  lea.l      disk_dat_files(a4),a1
.find_first_block_loop:
  move.l     (a1),d0
  tst.l      d0
  beq.s      .error                                    ; file not found
  cmp.l      d0,d4
  beq.s      .file_found
  lea.l      disk_file_sizeof(a1),a1
  bra.s      .find_first_block_loop
.file_found:
  moveq.l    #0,d6
  moveq.l    #0,d7
  move.w     disk_file_start_block(a1),d6
  move.w     disk_file_num_blocks(a1),d7
  bsr        disk_internal_read_blocks
  tst.l      d0
  bne.s      .error

  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA

  ; find first block of file
  lea.l      disk_dat_files(a4),a1
.find_first_block_loop:
  move.l     (a1),d0
  tst.l      d0
  beq.s      .error                                    ; file not found
  cmp.l      d0,d4
  beq.s      .file_found
  lea.l      disk_file_sizeof(a1),a1
  bra.s      .find_first_block_loop
.file_found:
  moveq.l    #0,d0
  moveq.l    #0,d1
  move.w     disk_file_start_block(a1),d0
  move.w     disk_file_num_blocks(a1),d1
  move.l     a3,a0
  move.l     a2,a1
  bsr        dd_load_file
  tst.l      d0
  bne.s      .error

  endif                                                ; ifd USE_DISK_DMA

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
;   a3 - pointer to read buffer (must be in chip mem) / USE_TRACKDISK 512 byte, USE_DISK_DMA 12800+512 byte
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
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

  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  move.w     dd_drive(pc),d0
  bsr        dd_init
  endif                                                ; ifd USE_DISK_DMA

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
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
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

  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA ****
  ; ***********************

  ifd        USE_DISK_DMA
  bsr        dd_cleanup
  endif                                                ; ifd USE_DISK_DMA

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

  ifd        USE_TRACKDISK

; reads blocks from floppy disk
; FOR INTERNAL USE OF DISK.ASM ONLY
; in:
;   a3 - pointer to target buffer (must be in chip mem)
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
;   d6 - number of first block
;   d7 - number of blocks to read
; out:
;   d0 - zero for success, other for error
disk_internal_read_blocks:
  movem.l    d1-d7/a0-a6,-(sp)

  move.l     ExecBaseD,a6
  lea.l      disk_io_std_req(a4),a1
  move.l     a3,IoSrData(a1)
  move.w     #IoCmdRead,IoSrCommand(a1)
  move.w     #512,d5
  mulu       d5,d6
  mulu       d5,d7
  move.l     d6,IoSrOffset(a1)
  move.l     d7,IoSrLength(a1)
  jsr        DoIO(a6)
  tst.l      d0
  bne.s      .error

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0                                     ; ignore error here, may be just a warning, program will not work if it is an error anyway
  rts

  endif                                                ; ifd USE_TRACKDISK

  ifnd       BOOTBLOCK

  ifd        USE_TRACKDISK

; calculates size of file depending on metadata stored in file directory
; in:
;   d0 - filename
;   a0 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
; out:
;   d1 - size of file in bytes or -1 if file not found
disk_get_file_size:
  movem.l    a0/d0,-(sp)
.loop:
  tst.l      disk_file_name(a0)
  beq.s      .error
  cmp.l      disk_file_name(a0),d0
  bne.s      .next
  moveq.l    #0,d0
  moveq.l    #0,d1
  move.w     disk_file_num_blocks(a0),d0
  move.w     disk_file_size_in_last_block(a0),d1
  subq.w     #1,d0
  lsl.l      #8,d0                                     ; d0 * 512
  add.l      d0,d0                                     ; d0 * 512
  add.l      d0,d1
  bra.s      .success
.next:
  lea.l      disk_file_sizeof(a0),a0
  bra.s      .loop

.error:
  moveq.l    #-1,d1
.success:
  movem.l    (sp)+,a0/d0
  rts

  endif                                                ; ifd USE_TRACKDISK

; writes data to a single-block file
; in:
;   d4 - filename (first 4 chars before dot)
;   d7 - length of data in bytes
;   a3 - pointer to data to be written (must be in chip mem)
;   a4 - pointer to disk-struct (disk_sizeof for USE_TRACKDISK and USE_DISK_DMA)
; out:
;   d0 - zero for success, other for error
disk_write_file:
  movem.l    d1-d7/a0-a6,-(sp)

  ; ***********************
  ; **** USE_DOS       ****
  ; ***********************

  ifd        USE_DOS

; remap parameter
  move.l     a3,d6
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

  endif                                                ; ifd USE_DOS

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
  tst.l      IoSrActual(a1)                            ; zero = not write-protected ; non-zero = write-protected
  bne.s      .error

  ; find data block of file
  lea.l      disk_dat_files(a4),a1
.find_first_block_loop:
  move.l     (a1),d0
  tst.l      d0
  beq.s      .error                                    ; file not found
  cmp.l      d0,d4
  beq.s      .file_found
  addq.l     #8,a1
  bra.s      .find_first_block_loop
.file_found:
  move.l     4(a1),d6                                  ; data block

  ; read block from disk --- FIXME no longer necessary because NODOS disk is used (no need to preserve DOS block header)
  moveq.l    #1,d7
  bsr        disk_internal_read_blocks
  tst.l      d0
  bne.s      .error

  ; copy data to block buffer --- FIXME no longer necessary because NODOS disk is used (no need to preserve DOS block header)
  subq.l     #1,d7
  move.l     a2,a0
  move.l     a3,a1
  lea.l      24(a1),a1                                 ; 24 bytes = size of data block header
.copy_loop:
  move.b     (a0)+,(a1)+
  dbf        d7,.copy_loop

  ; DoIO - write block to trackdisk buffer --- TODO set offset, length and pointer in struct (was set before by read block)
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

  endif                                                ; ifd USE_TRACKDISK

  ; ***********************
  ; **** USE_DISK_DMA ****
  ; ***********************

  ifd        USE_DISK_DMA
.1:
  move.w     #$0f00,$dff180
  bra.s      .1
  endif                                                ; ifd USE_DISK_DMA

.success:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #0,d0
  rts

.error:
  movem.l    (sp)+,d1-d7/a0-a6
  moveq.l    #1,d0
  rts

  endif                                                ; ifnd BOOTBLOCK

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
  dc.b       0,0,0,0                                   ; space for filename before the dot
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
  endif                                                ; ifd DEBUG
  endif                                                ; ifd USE_DOS

  ; ***********************
  ; **** USE_DISK_DMA  ****
  ; ***********************

  ifd        USE_DISK_DMA
  include    "../common/src/system/disk_direct.asm"
  endif                                                ; ifd USE_DISK_DMA
  endif                                                ; ifnd DISK_ASM
