  ifnd       EVENTS_ASM
EVENTS_ASM equ 1

  include    "../a100/src/system/events.i"
  include    "../common/src/system/joystick.i"

ev_init:
  lea.l      ev_delay(pc),a0
  move.l     #EventDelay,(a0)
  bsr        ev_clear_event_queue
  rts

; checks for new events
ev_check:

  ;
  ; check keyboard
  ;

.check_keyboard:
  bsr        keyboard_get_key
  tst.b      d0
  blt        .check_joystick
  
  cmp.b      #$41,d0                              ; Backspace
  bne.s      .ck0
  moveq.l    #EventUnselect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck0:

  cmp.b      #$45,d0                              ; Esc
  bne.s      .ck1
  moveq.l    #EventUnselect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck1:

  cmp.b      #$46,d0                              ; Del
  bne.s      .ck2
  moveq.l    #EventUnselect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck2:

  cmp.b      #$43,d0                              ; Enter
  bne.s      .ck3
  moveq.l    #EventSelect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck3:

  cmp.b      #$44,d0                              ; Return
  bne.s      .ck4
  moveq.l    #EventSelect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck4:

  cmp.b      #$4c,d0                              ; Cursor Up
  bne.s      .ck5
  moveq.l    #EventUp,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck5:

  cmp.b      #$4d,d0                              ; Cursor Down
  bne.s      .ck6
  moveq.l    #EventDown,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra.s      .check_keyboard
.ck6:

  cmp.b      #$4e,d0                              ; Cursor Right
  bne.s      .ck7
  moveq.l    #EventRight,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard
.ck7:

  cmp.b      #$4f,d0                              ; Cursor Left
  bne.s      .ck8
  moveq.l    #EventLeft,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard
.ck8:

  cmp.b      #$40,d0                              ; Space
  bne.s      .ck8_first_row
  move.b     d0,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard

.ck8_first_row:
  cmp.b      #$10,d0                              ; characters Q-P
  blt        .check_keyboard
  cmp.b      #$19,d0
  bgt.s      .ck8_second_row
  move.b     d0,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard

.ck8_second_row:
  cmp.b      #$20,d0                              ; characters A-L
  blt        .check_keyboard
  cmp.b      #$28,d0
  bgt.s      .ck8_third_row
  move.b     d0,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard

.ck8_third_row:
  cmp.b      #$31,d0                              ; characters Z-M
  blt        .check_keyboard
  cmp.b      #$37,d0
  bgt.s      .ck9
  move.b     d0,d1
  moveq.l    #1,d2
  bsr        ev_add_event_to_queue
  bra        .check_keyboard

.ck9:
  bra        .check_keyboard                      ; another key?

  ;
  ; check joystick
  ;

.check_joystick:
  bsr        joystick_read
  tst.b      d0
  beq.s      .exit

  btst       #JsUp,d0
  beq.s      .cj0
  moveq.l    #EventUp,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
.cj0:

  btst       #JsDown,d0
  beq.s      .cj1
  moveq.l    #EventDown,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
.cj1:

  btst       #JsLeft,d0
  beq.s      .cj2
  moveq.l    #EventLeft,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
.cj2:

  btst       #JsRight,d0
  beq.s      .cj3
  moveq.l    #EventRight,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
.cj3:

  btst       #JsFire,d0
  beq.s      .cj4
  moveq.l    #EventSelect,d1
  moveq.l    #0,d2
  bsr        ev_add_event_to_queue
.cj4:

.exit:
  rts

; in:
;   d1 - Event-ID (see events.i)
;   d2 - zero = delay check, non-zero = no delay-check
ev_add_event_to_queue:
  movem.l    d2-d3/a1,-(sp)

  ; do delay-check?
  tst.b      d2
  bne.s      .new_event

  ; check if event may be issued again
  move.l     d1,d2
  subq.l     #1,d2
  add.l      d2,d2
  add.l      d2,d2
  lea.l      (.events_last_issued,pc,d2.w),a1
  move.l     (a1),d2
  move.l     c_om_framecounter(a4),d3

  add.l      ev_delay(pc),d2
  cmp.l      d2,d3
  ble.s      .no_new_event

  ; update last issued
  move.l     d3,(a1)

.new_event:
  ; add event to queue
  lea.l      ev_struct(pc),a1
  move.w     (a1),d2                              ; event_write_index
  move.b     d1,event_queue(a1,d2.w)
  addq.w     #1,d2
  and.w      #EventQueueSize-1,d2                 ; ring buffer
  move.w     d2,(a1)                              ; update event_write_index

.no_new_event:
  movem.l    (sp)+,d2-d3/a1
  rts

; framenumbers when events where last issued
.events_last_issued:
  dcb.l      EventsCount,0

; returns next event from queue or -1 when queue is empty
; out:
;   d0.b - next event
ev_get_next_event:
  movem.l    d1/a0,-(sp)

  lea.l      ev_struct(pc),a0
  move.w     (a0)+,d0                             ; event_write_index
  move.w     (a0)+,d1                             ; event_read_index
  cmp.w      d0,d1
  bne        .1

	; queue is empty
  moveq.l    #-1,d0

  movem.l    (sp)+,d1/a0
  rts

.1:  
  move.b     (a0,d1.w),d0                         ; event_queue
  addq.w     #1,d1
  and.w      #EventQueueSize-1,d1                 ; ring buffer
  move.w     d1,-(a0)                             ; event_read_index

  movem.l    (sp)+,d1/a0
  rts

; clears all staging events in queue
ev_clear_event_queue:
  move.l     d0,-(sp)
.loop:
  bsr        ev_get_next_event
  tst.b      d0
  bge.s      .loop
  move.l     (sp)+,d0
  rts

;
; vars
;

ev_delay:
  dc.l       0

ev_struct:
  dcb.b      event_size

  endif                                           ; ifnd EVENTS_ASM
