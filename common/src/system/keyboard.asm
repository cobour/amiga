  ifnd       KEYBOARD_ASM
KEYBOARD_ASM equ 1

  include    "../common/src/system/keyboard.i"

; README: more or less copied from the game "Solid Gold" (Thank you!)

; Inits keyboard handler (must be called after ctrl_take_system and ctrl_set_handler)
keyboard_init:
  movem.l    d0/a1-a2/a6,-(sp)
  lea.l      CIAA,a2
  lea.l      CustomBase,a6

	; disable all PORTS interrupts
  moveq.l    #8,d0
  move.w     d0,INTENA(a6)
  move.w     d0,INTREQ(a6)

	; disable all CIA-A interrupts
  move.b     #$7f,CIAICR(a2)

  move.b     #%00011000,CIACRA(a2)

  ; set level 2 handler
  lea.l      keyboard_handler(pc),a1
  move.l     a1,Level2Handler

	; enable PORTS interrupts and CIA-A SP interupt for the keyboard
  move.w     #$c008,INTENA(a6)
  move.b     #$88,CIAICR(a2)

  movem.l    (sp)+,d0/a1-a2/a6
  rts

; Cleans up keyboard handler (must be called before ctrl_free_system)
keyboard_cleanup:
  movem.l    d0/a0/a6,-(sp)

	; disable PORTS interrupts
  moveq.l    #8,d0
  move.w     d0,INTENA(a6)
  move.w     d0,INTREQ(a6)

	; AmigaOS enables TA, TB, ALRM and SP interrupts (still blocked by INTENA at this point).
  lea.l      CIAA,a0
  move.b     #$8f,CIAICR(a0)                      ; enable CIA-A interrupts for AmigaOS

  movem.l    (sp)+,d0/a0/a6
  rts

; level 2 interrupt handler; reads raw key codes from pressed keys
keyboard_handler:
  movem.l    d0-d2/a0-a1/a6,-(sp)
  lea.l      CIAA,a0
  lea.l      CustomBase,a6

	; read CIA-A ICR and check for SP interrupt
  moveq.l    #8,d0
  and.b      CIAICR(a0),d0
  beq.s      .clrirq

	; SP interrupt detected, get key code
  move.b     CIASDR(a0),d0

	; get initial scanline, wait via scanline-counting, not via CIA-timer
  ; yeah, this wastes lots of time for the game, but this works on A500 and A1200 and KS 1.3-3.1 without interfering with dos loading
  ; using TimerB on CIAA worked with KS1.3 but made dos-loading on KS2.x or KS3.x hang when using floppy :-(
  move.b     VHPOSR(a6),d2

  ; initiate SP handshaking
  or.b       #%01000000,CIACRA(a0)

	; process the keycode in the meantime
  not.b      d0
  lsr.b      #1,d0
  bcs.s      .handshake                           ; ignore key releases

	; stuff raw key code into the FIFO queue
  lea.l      kbd_struct(pc),a1
  move.w     (a1),d1                              ; kbd_write_index
  move.b     d0,kbd_queue(a1,d1.w)
  addq.w     #1,d1
  and.w      #KBD_QUEUE_SIZE-1,d1                 ; ring buffer
  move.w     d1,(a1)                              ; update kbd_write_index

.handshake:
	; wait for 3 scanlines to finish handshaking
  moveq.l    #2,d0
.handshake_loop:
  move.b     VHPOSR(a6),d1
  cmp.b      d2,d1
  beq.s      .handshake_loop
  move.b     d1,d2
  dbf        d0,.handshake_loop

  and.b      #%10111111,CIACRA(a0)                ; switch SP back to input

.clrirq:
  move.w     #8,INTREQ(a6)                        ; clear PORTS interrupt

  movem.l    (sp)+,d0-d2/a0-a1/a6
  rte

; Gets the raw key code of the next pressed key. 
; out:
;  d0.b   - raw key code or -1 when no more key code is in the buffer
keyboard_get_key:
  movem.l    d1/a0,-(sp)

  lea.l      kbd_struct(pc),a0
  move.w     (a0)+,d0                             ; kbd_write_index
  move.w     (a0)+,d1                             ; kbd_read_index
  cmp.w      d0,d1
  bne        .1

	; queue is empty
  moveq.l    #-1,d0

  movem.l    (sp)+,d1/a0
  rts

.1:  
  move.b     (a0,d1.w),d0                         ; kbd_queue
  addq.w     #1,d1
  and.w      #KBD_QUEUE_SIZE-1,d1                 ; ring buffer
  move.w     d1,-(a0)                             ; kbd_read_index

  movem.l    (sp)+,d1/a0
  rts

; Clears the keyboard buffer
keyboard_clear_buffer:
  move.l     a0,-(sp)
  lea.l      kbd_struct(pc),a0
  clr.l      (a0)                                 ; clear write and read indexes
  move.l     (sp)+,a0
  rts

kbd_struct:
  dcb.b      kbd_size,0

  endif                                           ; ifnd KEYBOARD_ASM
 