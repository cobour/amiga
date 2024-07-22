  include    "../common/src/system/exec.asm"

  ifnd       DOS_ASM
DOS_ASM     equ 1

AccessRead  equ -2
ModeOldfile equ 1005
Open        equ -$1e
Close       equ -$24
Read        equ -$2a
Lock        equ -$54
UnLock      equ -$5a
CurrentDir  equ -$7e

dos_init:
  movem.l    d0-d7/a0-a6,-(sp)

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
  endif                                         ; ifd DEBUG

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; Reads file from disk
; d5 = filename
; d6 = target location
; d7 = no. of bytes
dos_readfile: 
  movem.l    d0-d7/a0-a6,-(sp)
; open file for read
  move.l     d5,d1
  move.l     #ModeOldfile,d2
  move.l     dos_base(pc),a6
  jsr        Open(a6)
  lea.l      dos_file_handle(pc),a0
  move.l     d0,(a0)

; read data from file
  move.l     dos_file_handle(pc),d1
  move.l     d6,d2
  move.l     d7,d3
  jsr        Read(a6)

; close file
  move.l     dos_file_handle(pc),d1
  jsr        Close(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; cleans up at end of program
dos_cleanup:
  movem.l    d0-d7/a0-a6,-(sp)

  ifd        DEBUG
; reset current directory
  move.l     dos_base(pc),a6
  move.l     dos_old_curdir(pc),d1
  jsr        CurrentDir(a6)

; unlock DH0:
  move.l     dos_dh0_lock(pc),d1
  jsr        UnLock(a6)
  endif                                         ; ifd DEBUG

; close dos.library
  move.l     ExecBase,a6
  move.l     dos_base(pc),a1
  jsr        CloseLibrary(a6)

  movem.l    (sp)+,d0-d7/a0-a6
  rts

dos_name:         
  dc.b       "dos.library",0
  even
dos_base:         
  dc.l       0
dos_file_handle:
  dc.l       0

  ifd        DEBUG
dos_dh0_name:
  dc.b       "dh0:",0
  even
dos_dh0_lock:
  dc.l       0
dos_old_curdir:
  dc.l       0
  endif                                         ; ifd DEBUG

  endif                                         ; ifnd DOS_ASM