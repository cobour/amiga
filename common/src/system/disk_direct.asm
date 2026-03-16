  ifnd       DISK_DIRECT_ASM
DISK_DIRECT_ASM equ 1

  ifnd       DISK_DRIVE_BIT
DISK_DRIVE_BIT  equ 4                           ; default to df1
  endif

  include    "../common/src/system/cia.i"
  include    "../common/src/system/custom.i"

; inits disk-direct module
; in:
;   d0 - drive (3 = df0, 4 = df1 ...)
dd_init:
  movem.l    d1/a0-a1,-(sp)
  lea.l      dd_drive(pc),a0
  move.w     d0,(a0)
  lea.l      dd_cia(pc),a0
  lea.l      CIAB+CIACRA,a1
  move.b     (a1),(a0)
  lea.l      CIAB+CIAPRB,a0
  move.b     #%01111111,d1
  move.b     d1,(a0)
  nop
  nop
  bclr       d0,d1
  move.b     d1,(a0)
  nop
  nop
  move.b     #%01001100,(a1)                    ; stop timer, one-shot mode
  movem.l    (sp)+,d1/a0-a1
.wait_ready:
  btst       #5,CIAA+CIAPRA
  bne.s      .wait_ready
  rts

; does cleanup
; field "drive" must have been set before calling
dd_cleanup:
  movem.l    d0-d1/a0,-(sp)
  lea.l      CIAB+CIACRA,a0
  move.b     dd_cia,(a0)
  move.w     dd_drive(pc),d0
  move.b     #%11111111,d1
  lea.l      CIAB+CIAPRB,a0
  move.b     d1,(a0)
  nop
  nop
  bclr       d0,d1
  move.b     d1,(a0)
  movem.l    (sp)+,d0-d1/a0
  rts

; loads file
; in:
;   a0   - target pointer
;   a1   - buffer (13000 bytes of chip ram)
;   d0.w - first block
;   d1.w - number of blocks
dd_load_file:
  movem.l    d0-a6,-(sp)

  move.l     a1,a4                              ; save trackbuffer for all subroutines
  lea.l      CIAB+CIAPRB,a5                     ; set bfd100 for all subroutines
  lea.l      CustomBase,a6                      ; set dff000 for all subroutines

  moveq.l    #0,d7
  move.w     d0,d7
  divu       #11,d7                             ; low-word: ergebnis, high-word: rest
  move.w     d7,d2                              ; track
  swap       d7                                 ; block offset inside track
.load_file_loop:
  moveq.l    #11,d4
  cmp.w      d4,d1
  bge.s      .more_blocks_to_read
  move.w     d1,d4
  bra.s      .last_track
.more_blocks_to_read:
  sub.w      d7,d4                              ; num of blocks to read from track
.last_track:
  move.w     d2,d6
  bsr        .seek_track                
  move.w     d4,d0
  move.w     d7,d5
  bsr        .read_blocks
  ; inc target pointer
  moveq.l    #0,d3
  move.w     d4,d3
  mulu       #512,d3
  add.l      d3,a0
  ; next iteration
  addq.w     #1,d2                              ; next track
  moveq.l    #0,d7                              ; start at block zero in next track
  sub.l      d4,d1                              ; less blocks to read
  bgt.s      .load_file_loop                    ; still blocks to read?
  ; all is read
  movem.l    (sp)+,d0-a6
  moveq.l    #0,d0
  rts

; reads blocks
; in:
;   d0 - number of blocks to read
;   d5 - first block
;   a0 - target pointer
; out:
;   d5 - bytes read
.read_blocks:  
  movem.l    d0-d4/d6-a6,-(sp)
  move.w     d0,-(sp)
.read_error:     
  bsr.s      .read_track
  move.w     (sp),d0
  move.w     d5,d7
  bra.s      .next_track
.track_loop:   
  tst.l      (a1)
  beq.s      .reseek
  move.w     dd_track(pc),d1
  cmp.b      1(a1),d1                           ; correct track?
  bne.s      .reseek
  cmp.b      2(a1),d7                           ; block found?
  bne.s      .next_block
  moveq.l    #127,d6
  addq.l     #4,a1
.block_copy_loop:       
  move.l     (a1)+,(a0)+
  dbf        d6,.block_copy_loop

  cmp.b      #10,d7
  bne.s      .no_step
  ; step to next track and begin with first block of that track
  move.w     dd_track(pc),d6
  addq.w     #1,d6
  moveq.l    #0,d5
  move.l     d5,d7
  bsr        .seek

.no_step:
  addq.w     #1,d7
.next_track: 
  move.l     a4,a1
  dbf        d0,.track_loop

  move.w     (sp)+,d0
  move.w     d0,d5
  mulu       #512,d5                            ; calc bytes read
  movem.l    (sp)+,d0-d4/d6-a6
  rts

.next_block:
  lea        512+4(a1),a1
  bra.s      .track_loop

.reseek:
  move.w     dd_track(pc),-(sp)
  moveq      #0,d6
  bsr        .seek_track
  move.w     (sp)+,d6
  bsr        .seek_track
  bra.s      .read_error


; read and decode complete track
.read_track: 
  movem.l    d0-a6,-(sp)

  ; init
  move.l     a4,a0
  move.w     #%1000000000010000,DMACON(a6)
  move.w     #%0111111100000000,ADKCON(a6)
  move.w     #%1001010100000000,ADKCON(a6)
  move.w     #$4489,DSKSYNC(a6)
  move.w     #$4489,(a0)+
  move.l     a0,DSKPTH(a6)

  ; wait for drive
  bsr        .wait_ready

  ; start dma
  move.w     #12980,d0
  lsr.w      #1,d0
  or.w       #$8000,d0
  move.w     d0,DSKLEN(a6)
  move.w     d0,DSKLEN(a6)

  ; wait for dma to finish
  bsr        .wait_dma

  ; mfm decode
  subq.l     #2,a0
  bsr.s      .decode_track

  movem.l    (sp)+,d0-a6
  rts


; mfm decoding
.decode_track: 
  movem.l    d0-a6,-(sp)

  move.l     a0,a1
  lea.l      12800(a0),a3
  move.l     #$55555555,d2

.search_block:  
  cmp.w      #$4489,(a0)
  bne.s      .no_sync
.check_second_sync: 
  cmp.w      #$4489,2(a0)
  bne.s      .no_second_sync
  addq.l     #2,a0
  bra.s      .check_second_sync
.no_second_sync:  
  cmp.b      #$55,2(a0)                         ; format-mark?
  bne.s      .no_sync
  cmp.b      #$55,6(a0)                         ; second format-mark?
  bne.s      .no_sync

  move.l     2(a0),d0
  move.l     6(a0),d1
  and.l      d2,d0
  and.l      d2,d1
  add.l      d0,d0
  or.l       d1,d0
  move.l     d0,(a1)                            ; buffer mark

  lea        2(a0),a2
  moveq.l    #40,d0
  bsr.s      .calc_crc

  move.l     42(a0),d1
  move.l     46(a0),d3
  and.l      d2,d1
  and.l      d2,d3
  add.l      d1,d1
  or.l       d3,d1
  cmp.l      d1,d0
  bne.s      .crc_error

  lea        58(a0),a2
  move.w     #1024,d0
  bsr.s      .calc_crc

  move.l     50(a0),d1
  move.l     54(a0),d3
  and.l      d2,d1
  and.l      d2,d3
  add.l      d1,d1
  or.l       d3,d1
  cmp.l      d1,d0
  bne.s      .crc_error

  lea        58(a0),a2
  addq.l     #4,a1
  bsr.s      .decode_block

.crc_error:
.no_sync:     
  addq.l     #2,a0
  cmpa.l     a3,a0
  blt.s      .search_block

  clr.l      (a1)
  movem.l    (sp)+,d0-a6


; calc crc
; in:
;   a2 - pointer to data
;   d0 - length of data in bytes
.calc_crc:    
  movem.l    d1-a6,-(sp)

  move.w     d0,d1
  lsr.w      #2,d1
  subq.w     #1,d1
  moveq.l    #0,d0
.calc_crc_loop:   
  move.l     (a2)+,d2
  eor.l      d2,d0
  dbf        d1,.calc_crc_loop
  and.l      #$55555555,d0

  movem.l    (sp)+,d1-a6
  rts

; mfm decode one block
; in:
;   a2 - source pointer
;   a1 - target pointer (changed)
.decode_block: 
  movem.l    d0-a0/a2-a6,-(sp)

  moveq.l    #127,d7
  move.l     #$55555555,d2
.decode_block_loop:     
  move.l     (a2)+,d0
  move.l     508(a2),d1
  and.l      d2,d1
  and.l      d2,d0
  add.l      d0,d0
  or.l       d1,d0
  move.l     d0,(a1)+
  dbf        d7,.decode_block_loop

  movem.l    (sp)+,d0-a0/a2-a6
  rts

; moves head to track
; in:
;   d6.w - track
.seek_track:   
  move.w     dd_track(pc),d0                    ; first call?
  bpl.s      .seek                              ; no, go to track

  move.l     d6,-(sp)                           ; move to track zero first
  moveq.l    #0,d6
  bsr.s      .seek
  move.l     (sp)+,d6

.seek:     
  movem.l    d0-a6,-(sp)

  move.w     dd_track(pc),d7
  lsr.w      #1,D7
  lsr.w      #1,D6
  bcs.s      .lower_side
  bset       #2,(a5)                            ; upper side
  bra.s      .do_seek
.lower_side:  
  bclr       #2,(a5)

.do_seek:     
  tst.w      d6                                 ; track zero?
  beq.s      .restore

.seek_loop:  
  cmp.w      d7,d6                              ; track reached?
  beq.s      .seek_end
  bgt.s      .move_inward
  bsr.s      .outward
  subq.w     #1,d7
  bra.s      .seek_loop
.move_inward: 
  bsr.s      .inward
  addq.w     #1,D7
  bra.s      .seek_loop

.restore:     
  btst       #4,CIAA+CIAPRA                     ; track zero reached?
  beq.s      .seek_end
  bsr.s      .outward
  bra.s      .restore

.seek_end:    
  movem.l    (sp)+,d0-a6
  lea        dd_track(pc),a2
  move.w     d6,(a2)
  rts

.inward:   
  movem.l    d0-a6,-(sp)
  bsr        .wait_ready
  bclr       #1,(a5)
  bclr       #0,(a5)
  bset       #0,(a5)
  bsr.s      .short_delay
  bsr.s      .wait_ready
  movem.l    (sp)+,d0-a6
  rts

.outward:   
  movem.l    d0-a6,-(sp)
  bsr.s      .wait_ready
  bset       #1,(a5)
  bclr       #0,(a5)
  bset       #0,(a5)
  bsr.s      .short_delay
  bsr.s      .wait_ready
  movem.l    (sp)+,d0-a6
  rts

.short_delay:
  ; (a5 points to CIAPRB aka $bfd100)
  move.b     #$e1,CIATALO-CIAPRB(a5)            ; timer a low
  move.b     #$31,CIATAHI-CIAPRB(a5)            ; timer a hi, and starts timer
.short_delay_loop:
  btst       #0,CIAICR-CIAPRB(a5)
  beq.s      .short_delay_loop
  rts

; waits for end of disk dma
.wait_dma:     
  movem.l    d1-a6,-(sp)

  move.l     #$00020000,d0
  move.w     #$0002,INTREQ(a6)
.wait_dma_loop:   
  btst       #1,INTREQR+1(a6)
  bne.s      .wait_dma_exit
  subq.l     #1,d0
  bne.s      .wait_dma_loop
.wait_dma_exit: 
  move.w     #$0000,DSKLEN(a6)

  movem.l    (sp)+,d1-a6
  rts

; waits for disk operation to finish, drive be ready again
.wait_ready:  
  btst       #5,CIAA+CIAPRA
  bne.s      .wait_ready
  rts

dd_track:        
  dc.w       -1
dd_drive:       
  dc.w       -1                                 ; 3 = df0, 4 = df1 ...
dd_cia:
  dc.b       -1
  even

  endif                                         ; ifnd DISK_DIRECT_ASM