  ifnd       EVENTS_ASM
EVENTS_ASM equ 1

  include    "../a100/src/ingame/events.i"
  include    "../common/src/system/joystick.i"

; checks for new events
events_check:

  ;
  ; check keyboard
  ;

  bsr        keyboard_get_key
  tst.b      d0
  blt.s      .check_joystick
  
  cmp.b      #$41,d0                              ; Backspace
  bne.s      .ck0
  moveq.l    #EventUnselect,d1
  bsr        .add_event_to_queue
.ck0:

  cmp.b      #$45,d0                              ; Esc
  bne.s      .ck1
  moveq.l    #EventUnselect,d1
  bsr        .add_event_to_queue
.ck1:

  cmp.b      #$46,d0                              ; Del
  bne.s      .ck2
  moveq.l    #EventUnselect,d1
  bsr        .add_event_to_queue
.ck2:

  cmp.b      #$43,d0                              ; Enter
  bne.s      .ck3
  moveq.l    #EventSelect,d1
  bsr        .add_event_to_queue
.ck3:

  cmp.b      #$44,d0                              ; Return
  bne.s      .ck4
  moveq.l    #EventSelect,d1
  bsr        .add_event_to_queue
.ck4:

  cmp.b      #$4c,d0                              ; Cursor Up
  bne.s      .ck5
  moveq.l    #EventUp,d1
  bsr        .add_event_to_queue
.ck5:

  cmp.b      #$4d,d0                              ; Cursor Down
  bne.s      .ck6
  moveq.l    #EventDown,d1
  bsr        .add_event_to_queue
.ck6:

  cmp.b      #$4e,d0                              ; Cursor Right
  bne.s      .ck7
  moveq.l    #EventRight,d1
  bsr        .add_event_to_queue
.ck7:

  cmp.b      #$4f,d0                              ; Cursor Left
  bne.s      .ck8
  moveq.l    #EventLeft,d1
  bsr        .add_event_to_queue
.ck8:

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
  bsr        .add_event_to_queue
.cj0:

  btst       #JsDown,d0
  beq.s      .cj1
  moveq.l    #EventDown,d1
  bsr        .add_event_to_queue
.cj1:

  btst       #JsLeft,d0
  beq.s      .cj2
  moveq.l    #EventLeft,d1
  bsr        .add_event_to_queue
.cj2:

  btst       #JsRight,d0
  beq.s      .cj3
  moveq.l    #EventRight,d1
  bsr        .add_event_to_queue
.cj3:

  btst       #JsFire,d0
  beq.s      .cj4
  moveq.l    #EventSelect,d1
  bsr        .add_event_to_queue
.cj4:

.exit:
  rts

; in:
;   d1 - Event-ID (see events.i)
.add_event_to_queue:

  ; check if event may be issued again
  move.l     d1,d2
  subq.l     #1,d2
  add.l      d2,d2
  add.l      d2,d2
  lea.l      (.events_last_issued,pc,d2.w),a1
  move.l     (a1),d2
  move.l     ig_om_framecounter(a4),d3

  add.l      #50,d2                               ; TODO: configurable delay value
  cmp.l      d2,d3
  ble.s      .no_new_event

  ; update last issued
  move.l     d3,(a1)

  ; TODO: add event to queue

  ; ################### REMOVE ME - play sample for testing purposes ####
  move.l     d0,-(sp)
  move.l     d1,d2
  subq.l     #1,d2
  add.l      d2,d2
  add.l      d2,d2
  move.l     (.sfx_ids,pc,d2.w),d0
  bsr        datafiles_get_pointer
  lea.l      df_idx_metadata(a0),a0
  bsr        _mt_playfx
  move.l     (sp)+,d0
  bra.s      .no_new_event
.sfx_ids:
  dc.l       f000_sfx_step
  dc.l       f000_sfx_step
  dc.l       f000_sfx_step
  dc.l       f000_sfx_step
  dc.l       f000_sfx_select
  dc.l       f000_sfx_unselect
  ; ################################# REMOVE ME #########################

.no_new_event:
  rts

; framenumbers when events where last issued
.events_last_issued:
  dcb.l      EventsCount,0

  endif                                           ; ifnd EVENTS_ASM
