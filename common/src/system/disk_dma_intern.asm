
; ************************************************************************************************************************************************
; this is a refactored version of the original trackdisk_dma_load by Patrik Lundquist (source: https://aminet.net/package/dev/asm/t-disk_dma_load)
; optimized for small size so that it can be used in a bootblock
; ************************************************************************************************************************************************

  ifnd       DISK_DMA_INTERN_ASM
DISK_DMA_INTERN_ASM equ 1

  include    "../common/src/system/disk_dma_intern.i"
  include    "../common/src/system/custom.i"
  include    "../common/src/system/cia.i"

; reads directory block of floppy disk and copies file info to field "disk_dma_files"
; disk_dma_init must have been called before this
; in:
;   a2 - pointer to 512 bytes as temporary buffer
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
;   a6 - $dff000
disk_dma_read_directory:
  movem.l    d0-d7/a0-a6,-(sp)

  ; load directory block
  moveq.l    #2,d0
  moveq.l    #1,d1
  move.l     a2,a0
  bsr        disk_dma_load

  ; copy entries to disk_dma_files
  move.w     4(a2),d7
  subq.w     #1,d7
  lea.l      disk_dma_files(a3),a1
  lea.l      6(a2),a2
.loop:
  ; MUST be adapted when size of file entry in directory is changed (currently 10 bytes)
  move.l     (a2)+,(a1)+
  move.l     (a2)+,(a1)+
  move.w     (a2)+,(a1)+
  dbf        d7,.loop
  clr.l      (a1)                                        ; null long indicates end of list

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; returns pointer to disk_dma_file struct
; disk_dma_read_directory must have been called before this
; in:
;   d0 - filename
;   a3 - pointer to struct disk_dma
; out:
;   a2 - pointer to disk_dma_file struct or zero when not found
disk_dma_get_file_desc:
  lea.l      disk_dma_files(a3),a2
.loop:
  tst.l      disk_dma_file_name(a2)
  beq.s      .not_found
  cmp.l      disk_dma_file_name(a2),d0
  beq.s      .found
  lea.l      disk_dma_file_sizeof(a2),a2
  bra.s      .loop
.not_found:
  sub.l      a2,a2
.found:
  rts

; initializes the floppy drive and all vars in the struct
; in:
;   a2 - trackbuffer (pointer to 12800 bytes of chip mem)
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
;   a6 - $dff000
disk_dma_init:
  movem.l    d0-d7/a0-a6,-(sp)

  move.l     a2,disk_dma_buffer(a3)
  move.b     CIACRA(a5),disk_dma_old_ciab_cra(a3)
  ;move.w       $2(a6),disk_dma_old_dmacon(a3)
  ;bset         #7,disk_dma_old_dmacon(a3)
  ;move.b       $10(a6),disk_dma_old_adkcon(a3)
  ;bset         #7,disk_dma_old_adkcon(a3)
  ;move.w       $1c(a6),disk_dma_old_intena(a3)
  ;bset         #7,disk_dma_old_intena(a3)
  ;move.w       $1e(a6),disk_dma_old_intreq(a3)
  ;bset         #7,disk_dma_old_intreq(a3)

  move.w     #$7fff,d1
  move.w     d1,INTENA(a6)
  move.w     d1,INTREQ(a6)
  move.w     d1,DMACON(a6)

  move.w     #MFM_SYNC_WORD,DSKSYNC(a6)
  move.w     #$9500,ADKCON(a6)
  move.w     #$8200,DMACON(a6)                           ; $8010 sufficient?
  move.b     #%01001100,CIACRA(a5)                       ; stop timer, one-shot mode.

  bsr.s      disk_dma_motor_on
  bsr.s      disk_dma_goto_track_zero
  bsr.s      disk_dma_motor_off

  movem.l    (sp)+,d0-d7/a0-a6
  rts

; cleans up after disk loading is finished
; in:
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
;   a6 - $dff000
disk_dma_cleanup:
  ;move.w       disk_dma_old_dmacon(a3),$96(a6)
  move.b     disk_dma_old_ciab_cra(a3),CIACRA(a5)
  ;move.b       disk_dma_old_adkcon(a3),$9e(a6)
  ;move.w       disk_dma_old_intena(a3),$9a(a6)
  ;move.w       disk_dma_old_intreq(a3),$9c(a6)
  moveq.l    #0,d0
  rts

; turns floppy motor on
; INTERNAL USE ONLY
; in:
;   a5 - $bfd000
disk_dma_motor_on:
  or.b       #$78,CIAPRB(a5)                             ; deselect all drives
  bclr       #7,CIAPRB(a5)                               ; switch motor on
  nop
  nop
  bclr       #DISK_DMA_DRIVE,CIAPRB(a5)
  rts

; turns floppy motor off
; INTERNAL USE ONLY
; in:
;   a5 - $bfd000
disk_dma_motor_off:
  or.b       #$f8,CIAPRB(a5)                             ; deselect all drives, motor off
  nop
  nop
  bclr       #DISK_DMA_DRIVE,CIAPRB(a5)
  rts

; moves head to track zero
; INTERNAL USE ONLY
; in:
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
disk_dma_goto_track_zero:
  btst       #4,(a4)                                     ; CIAPRA
  beq.s      .exit
  bsr        disk_dma_move_head_outward
.continue:
  btst       #4,(a4)                                     ; CIAPRA
  beq.s      .exit
  bclr       #0,CIAPRB(a5)
  nop
  nop
  bset       #0,CIAPRB(a5)
  move.b     #$69,CIATALO(a5)
  move.b     #$0e,CIATAHI(a5)
  bsr        disk_dma_wait_timer
  bra.s      .continue
.exit:
  clr.b      disk_dma_position(a3)
  rts

; loads the data from floppy disk
; in:
;   d0 - start block (0-1759)
;   d1 - number of blocks to load
;   a0 - target pointer
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
;   a6 - $dff000
disk_dma_load:
  movem.l    d0-d7/a0-a6,-(sp)

  tst.l      d1
  beq        .exit
  bmi        .exit
  tst.l      d0
  bmi        .exit                                       ; boundary check
  move.l     d1,d2
  add.l      d0,d2
  cmp.l      #1760,d2
  bgt        .exit

  bsr        disk_dma_motor_on
  divu       #11,d0
  move.b     d0,disk_dma_start_track(a3)
  move.l     d0,d2
  swap       d2
  move.b     d2,disk_dma_start_sector(a3)
  add.b      d2,d1
  divu       #11,d1
  move.l     d1,d2
  swap       d2
  tst.b      d2
  bne.s      .same_track
  subq.b     #1,d1
  move.b     #11,d2
.same_track:
  move.b     d1,disk_dma_track(a3)
  move.b     d2,disk_dma_end_sector(a3)

  move.b     d0,d1                                       ; start-track in d0.
  move.b     disk_dma_position(a3),d2
  lsr.b      #1,d1
  lsr.b      #1,d2
  cmp.b      d1,d2
  beq.s      .correct_cylinder                           ; no need to move head.
  blt.s      .move_head_in
  sub.b      d1,d2
  bsr        disk_dma_move_head_outward
  subq.b     #1,d2
  beq.s      .correct_cylinder
  subq.b     #1,d2
  ext.w      d2
.move_head_out_loop:
  bsr        disk_dma_move_head
  dbra       d2,.move_head_out_loop
  bra.s      .correct_cylinder
.move_head_in:
  sub.b      d2,d1
  bsr        disk_dma_move_head_inward
  subq.b     #1,d1
  beq.s      .correct_cylinder
  subq.b     #1,d1
  ext.w      d1
.move_head_in_loop:
  bsr        disk_dma_move_head
  dbra       d1,.move_head_in_loop
.correct_cylinder:
  btst       #0,disk_dma_start_track(a3)                 ; choose side.
  beq.s      .lower_it
  btst       #2,CIAPRB(a5)
  beq.s      .correct_track
  bsr        disk_dma_select_upper_side
  bra.s      .correct_track
.lower_it:
  btst       #2,CIAPRB(a5)
  bne.s      .correct_track
  bsr        disk_dma_select_lower_side
.correct_track:
  move.b     disk_dma_start_sector(a3),d3                ; the reading begins.
  move.b     disk_dma_track(a3),d2
  beq.s      .last_track
  moveq      #11,d4
  bsr.s      disk_dma_read_cylinder
.next_track:
  moveq      #0,d3
  btst       #2,CIAPRB(a5)
  bne.s      .next_side
  bsr        disk_dma_select_lower_side
  btst       #1,CIAPRB(a5)
  bne.s      .first_move_in
  bsr        disk_dma_move_head
  bra.s      .next_read
.first_move_in:
  bsr        disk_dma_move_head_inward
  bra.s      .next_read
.next_side:
  bsr        disk_dma_select_upper_side
.next_read:
  subq.b     #1,d2
  beq.s      .last_track
  bsr.s      disk_dma_read_cylinder
  bra.s      .next_track
.last_track:
  move.b     disk_dma_end_sector(a3),d4
  bsr.s      disk_dma_read_cylinder
  bsr        disk_dma_motor_off
.exit:
  movem.l    (sp)+,d0-d7/a0-a6
  rts

; read one cylinder
; INTERNAL USE ONLY
; in:
;   a3 - pointer to struct disk_dma
;   a4 - $bfe001
;   a5 - $bfd000
;   a6 - $dff000
disk_dma_read_cylinder:
  btst       #5,(a4)                                     ; await Disk ready. CIAPRA
  bne.s      disk_dma_read_cylinder
  move.b     #$91,CIATALO(a5)                            ; timer A low.
  move.b     #$29,CIATAHI(a5)                            ; timer A hi, and starts timer.
  bsr        disk_dma_wait_timer
  move.w     #2,INTREQ(a6)                               ; clear disk intrequest.
  move.l     disk_dma_buffer(a3),DSKPTH(a6)
  move.w     #$8010,DMACON(a6)                           ; disk dma on.
  move.w     #$4000,DSKLEN(a6)                           ; dsklen.  FIXME: WHY THIS ???
  move.w     #$9900,DSKLEN(a6)                           ; dsklen, read length.
  move.w     #$9900,DSKLEN(a6)                           ; dsklen
.wait_dma:
  btst       #1,$1f(a6)                                  ; dma transfer done when high.
  beq.s      .wait_dma
  move.w     #$4000,DSKLEN(a6)
  move.w     #$0010,DMACON(a6)                           ; disk dma off.

  ; mfm decoding

  move.w     #MFM_SYNC_WORD,d5
  move.l     #$55555555,d7

.find_sector:
  move.l     disk_dma_buffer(a3),a1
.sync_search:
  cmp.w      (a1)+,d5
  bne.s      .sync_search
  cmp.w      (a1),d5
  beq.s      .sync_search
  move.l     (a1),d0
  move.l     4(a1),d1
  and.l      d7,d0
  asl.l      #1,d0
  and.l      d7,d1
  or.l       d1,d0
  ror.l      #8,d0
  cmp.b      d3,d0
  beq.s      .sector_ok
  lea        $43E(a1),a1                                 ; add to next sector.
  bra.s      .sync_search

.sector_ok:
  addq.b     #1,d3
  lea        $38(a1),a1                                  ; skip info bytes.
  moveq.l    #$7f,d6
.loop:
  move.l     $200(a1),d1
  move.l     (a1)+,d0
  and.l      d7,d0
  asl.l      #1,d0
  and.l      d7,d1
  or.l       d1,d0
  move.l     d0,(a0)+
  dbra       d6,.loop

  cmp.b      d4,d3
  bne.s      .find_sector
  rts

; selects upper side of floppy disk
; INTERNAL USE ONLY
; in:
;   a5 - $bfd000
disk_dma_select_upper_side:
  bclr       #2,CIAPRB(a5)                               ; upper side.
  move.b     #$47,CIATALO(a5)                            ; timer A low.
  move.b     #$00,CIATAHI(a5)                            ; timer A hi, and starts timer.
  bra.s      disk_dma_wait_timer                         ; implicit rts

; selects lower side of floppy disk
; INTERNAL USE ONLY
; in:
;   a5 - $bfd000
disk_dma_select_lower_side:
  bset       #2,CIAPRB(a5)                               ; lower side.
  move.b     #$47,CIATALO(a5)                            ; timer A low.
  move.b     #$00,CIATAHI(a5)                            ; timer A hi, and starts timer.
  bra.s      disk_dma_wait_timer                         ; implicit rts

; sets direction to move header inward
; INTERNAL USE ONLY
; in:
;   a3 - pointer to struct disk_dma
;   a5 - $bfd000
disk_dma_move_head_inward:
  and.b      #$fc,CIAPRB(a5)                             ; Clear bits 0 and 1,
  nop                                                    ; which results in diskdirec=inwards, head moved.
  nop
  bset       #0,CIAPRB(a5)                               ; prepare to move head.
  move.b     #$e1,CIATALO(a5)                            ; timer A low.
  move.b     #$31,CIATAHI(a5)                            ; timer A hi, and starts timer.
  move.b     #2,disk_dma_direction(a3)
  addq.b     #2,disk_dma_position(a3)
  bra.s      disk_dma_wait_timer                         ; implicit rts

; sets direction to move header outward
; INTERNAL USE ONLY
; in:
;   a3 - pointer to struct disk_dma
;   a5 - $bfd000
disk_dma_move_head_outward:
  bset       #1,CIAPRB(a5)                               ; head direction outward.
  bclr       #0,CIAPRB(a5)                               ; move head.
  nop
  nop
  bset       #0,CIAPRB(a5)                               ; prepare to move head.
  move.b     #$e1,CIATALO(a5)                            ; timer A low.
  move.b     #$31,CIATAHI(a5)                            ; timer A hi, and starts timer.
  move.b     #-2,disk_dma_direction(a3)
  add.b      #-2,disk_dma_position(a3)
  ; intended fall-through to disk_dma_wait_timer

; waits for timer to finish
; INTERNAL USE ONLY
; in:
;   a5 - $bfd000
disk_dma_wait_timer:
  move.b     CIAICR(a5),d0                               ;	await timer ready.
  btst       #0,d0
  beq.s      disk_dma_wait_timer
  rts

; actually moves head in previously set direction
; INTERNAL USE ONLY
; in:
;   a3 - pointer to struct disk_dma
;   a5 - $bfd000
disk_dma_move_head:
  bclr       #0,CIAPRB(a5)                               ; move head.
  nop
  nop
  bset       #0,CIAPRB(a5)                               ; prepare to move head.
  move.b     #$50,CIATALO(a5)                            ; timer A low.
  move.b     #$08,CIATAHI(a5)                            ; timer A hi, and starts timer.
  move.b     disk_dma_direction(a3),d0
  add.b      d0,disk_dma_position(a3)
  bra.s      disk_dma_wait_timer                         ; implicit rts

  endif                                                  ; ifnd DISK_DMA_INTERN_ASM
