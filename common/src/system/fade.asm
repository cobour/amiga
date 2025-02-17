  ifnd       FADE_ASM
FADE_ASM equ 1

; inits the color tab and vars
; in:
;   a0   - pointer to color tab area; must have size = colors * 2 * 16
;   a1   - pointer to color values (words)
;   d0.w - number of colors
;   d1.b - fade-in = 0 ; fade_out <> 0
fade_init:
  movem.l    d2-d7/a2-a3,-(sp)

  ; set pointers
  lea.l      fade_color_tab(pc),a2
  move.l     a0,(a2)+
  move.l     a0,(a2)+

  ; set step size
  moveq.l    #0,d7
  move.w     d0,d7
  add.w      d7,d7
  move.l     d7,(a2)+

  ; set initial countdown and color count
  move.w     #16,(a2)+
  subq.w     #1,d0
  move.w     d0,(a2)

  ;
  ; init color tab
  ;

  moveq.l    #0,d5                              ; d5 = initial mulu
  tst.b      d1
  beq.s      .fi_do_loop
  ; when fade-out: copy orig colors as first step
  move.w     fade_number_of_colors(pc),d7
  move.l     a1,a2
.fo_copy_loop:
  move.w     (a2)+,(a0)+
  dbf        d7,.fo_copy_loop
  moveq.l    #14,d5                             ; d5 = initial mulu

  ; calc in-between-steps
.fi_do_loop:
  moveq.l    #14,d7
.fade_outer_loop:

  move.w     fade_number_of_colors(pc),d6
  move.l     a1,a3
.fade_inner_loop:

  move.w     (a3)+,d2                           ; target color
  
  ; red
  move.w     d2,d3
  and.w      #$0f00,d3
  lsr.w      #8,d3
  mulu       d5,d3
  lsr.w      #4,d3                              ; get rid of fraction
  lsl.w      #8,d3
  move.w     d3,d4                              ; step
  ; green
  move.w     d2,d3
  and.w      #$00f0,d3
  lsr.w      #4,d3
  mulu       d5,d3
  lsr.w      #4,d3                              ; get rid of fraction
  lsl.w      #4,d3
  add.w      d3,d4                              ; step
  ; blue
  move.w     d2,d3
  and.w      #$000f,d3
  mulu       d5,d3
  lsr.w      #4,d3                              ; get rid of fraction
  add.w      d3,d4                              ; step

  move.w     d4,(a0)+

  dbf        d6,.fade_inner_loop

  ; adjust mulu
  tst.b      d1
  beq.s      .0
  subq.l     #1,d5
  bra.s      .1
.0:
  addq.l     #1,d5
.1:

  dbf        d7,.fade_outer_loop

  ; when fade-in: copy orig colors as last step
  tst.b      d1
  bne.s      .exit
  move.w     fade_number_of_colors(pc),d7
  move.l     a1,a2
.fi_copy_loop:
  move.w     (a2)+,(a0)+
  dbf        d7,.fi_copy_loop

.exit:
  movem.l    (sp)+,d2-d7/a2-a3
  rts

; executes next fading step
; in:
;   a0 - pointer to copperlist-moves to color regs (MODIFIED by this code)
fade_next_step:
  movem.l    d7/a1-a2,-(sp)
  lea.l      fade_step_countdown(pc),a1
  tst.w      (a1)
  beq.s      .exit

  move.l     fade_color_tab_next_step(pc),a1
  move.w     fade_number_of_colors(pc),d7
  addq.l     #2,a0
.loop:
  move.w     (a1)+,(a0)
  addq.l     #4,a0
  dbf        d7,.loop

.next:
  ; countdown
  lea.l      fade_step_countdown(pc),a1
  sub.w      #1,(a1)
  ; pointer to next step
  lea.l      fade_color_tab_next_step(pc),a1
  move.l     (a1),a2
  add.l      fade_color_tab_step_size(pc),a2
  move.l     a2,(a1)

.exit:
  movem.l    (sp)+,d7/a1-a2
  rts

;
; vars (all initialized by fade_init)
;

fade_color_tab:
  dc.l       0
fade_color_tab_next_step:
  dc.l       0
fade_color_tab_step_size:
  dc.l       0
fade_step_countdown:
  dc.w       0
fade_number_of_colors:
  dc.w       0                                  ; num of colors minus 1 = for dbf-loops

  endif                                         ; ifnd FADE_ASM
 