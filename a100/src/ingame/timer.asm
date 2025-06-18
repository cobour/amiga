  ifnd        TIMER_ASM
TIMER_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"
  include     "../a100/src/ingame/sfx.i"

t_init:

  ; init timer value
  lea.l       t_timer(pc),a0
  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  beq.s       .0
  move.b      #$99,(a0)

  ; init vars
  lea.l       t_framenumber_last_update(pc),a0
  move.l      c_om_framecounter(a4),(a0)
  ; use font-metadata from score.asm

  ; save background for restore
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                      ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                           ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-4,BLTAMOD(a6)                   ; modulos for source and target
  clr.w       BLTDMOD(a6)
  move.l      a5,a0
  add.l       #ig_cm_timer_backup,a0
  move.l      a0,BLTDPTH(a6)                                      ; pointers
  move.l      ig_om_frontbuffer(a4),d7
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*208)+6,d7
  move.l      d7,BLTAPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+2,BLTSIZE(a6)            ; start blit

  bra.s       .1
.0:
  move.b      #-1,(a0)
.1:

  ; initial draw
  move.l      ig_om_frontbuffer(a4),d7
  bsr         t_draw

  rts

t_update:
  tst.b       ig_om_gameover(a4)
  bne         .exit

  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  beq         .exit

  ;
  ; speedrun: decrement timer (once every 50 frames), check end-of-game
  ;
  lea.l       t_framenumber_last_update(pc),a0
  move.l      c_om_framecounter(a4),d0
  move.l      d0,d2
  sub.l       (a0),d0
  moveq.l     #50,d1
  cmp.l       d0,d1
  bgt.s       .restore
  move.l      d2,(a0)

  lea.l       t_timer(pc),a0
  tst.b       (a0)
  bne.s       .go_on

  ;
  ; game over
  ;

  move.b      #1,ig_om_gameover(a4)
  move.b      #50,ig_om_end_countdown(a4)

  ; play sfx
  SFX         f000_sfx_gameover

  ; init fade-out
  move.l      #f001_gfx_ingame_screen_2a_colors,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a1
  lea.l       ig_om_fade_color_tab(a4),a0
  moveq.l     #32,d0
  moveq.l     #1,d1
  bra         fade_init                                           ; indirect rts

  ;
  ; continue game, draw timer value
  ;

.go_on:
  move.b      (a0),d0
  moveq.l     #1,d1
  sbcd        d1,d0
  move.b      d0,(a0)
  ; play sfx on last 5 seconds
  cmp.w       #$05,d0
  bgt.s       .restore
  SFX         f000_sfx_alarm

.restore:
  ;
  ; restore background
  ;
  move.l      ig_om_backbuffer(a4),d7
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                      ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                           ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-4,BLTDMOD(a6)                   ; modulos for source and target
  clr.w       BLTAMOD(a6)
  move.l      a5,a0
  add.l       #ig_cm_timer_backup,a0
  move.l      a0,BLTAPTH(a6)                                      ; pointers
  move.l      d7,d0
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*208)+6,d0
  move.l      d0,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+2,BLTSIZE(a6)            ; start blit

  bra.s       t_draw
.exit:
  rts

t_draw:

  ; init pointer
  move.l      sc_font_metadata_ptr(pc),a1
  move.l      d7,d3
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*209)+6,d3    ; d3 = target pointer
  move.l      sc_font_gfx_ptr(pc),d1                              ; d1 = gfx pointer
  move.l      sc_font_mask_ptr(pc),d2                             ; d2 = mask pointer

  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d7
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  beq.s       .mod_infinite
  moveq.l     #2,d6
  bra.s       .set_mods
.mod_infinite:
  moveq.l     #4,d6
.set_mods:
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  sub.w       d6,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes,d7
  sub.w       d6,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  cmp.b       #GameModeInfinite,c_om_gamemode(a4)
  beq         .infinite

  ; convert timer value
  move.b      t_timer(pc),d0
  bsr         bcd_to_string_of_2

  ;
  ; print timer value
  ;
  
  move.l      sc_font_metadata_ptr(pc),a1

  moveq.l     #32,d0                                              ; offset zero char
  move.l      sc_font_gfx_ptr(pc),d7
  add.l       d0,d7
  move.l      sc_font_mask_ptr(pc),d6
  add.l       d0,d6
  moveq.l     #0,d5
.loop:
  move.b      (a0)+,d5
  tst.b       d5
  beq.s       .exit

  sub.b       #$30,d5
  add.b       d5,d5
  move.l      d7,d0
  add.l       d5,d0                                               ; gfx ptr
  move.l      d6,d1
  add.l       d5,d1                                               ; mask ptr

  WAIT_BLT

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(12*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next
  addq.l      #2,d3
  bra.s       .loop

  bra.s       .exit

.infinite:

  ; set source pointers to infinite-sign
  addq.l      #8,d1
  addq.l      #8,d2

  ; source pointers
  move.l      d2,BLTAPTH(a6)
  move.l      d1,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(12*IgScreenBitPlanes<<6)+2,BLTSIZE(a6)

.exit:
  rts

;
; vars, initialized by t_init
;

t_timer:
  dc.b        0
.padding_byte:
  dc.b        0
t_framenumber_last_update:
  dc.l        0

  endif                                                           ; ifnd TIMER_ASM
