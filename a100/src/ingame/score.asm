  ifnd        INGAME_SCORE_ASM
INGAME_SCORE_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"

sc_init:

  ; clear values
  clr.l       c_om_score(a4)
  clr.b       ig_om_score_draw_counter(a4)

  ; init from savegame data
  lea.l       ig_om_savegame(a4),a3
  bsr         sg_is_used
  tst.l       d0
  beq.s       .no_savegame
  move.l      sg_data_score(a3),c_om_score(a4)
.no_savegame:

  ; init vars
  lea.l       sc_font_metadata_ptr(pc),a3
  move.l      #f000_gfx_font16_2c,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      a1,(a3)+                                             ; metadata
  move.l      df_idx_ptr_rawdata(a0),d0
  move.l      d0,(a3)+                                             ; gfx
  add.l       df_iff_rawsize(a1),d0
  move.l      d0,(a3)                                              ; mask

  ; save background for restore
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-16,BLTAMOD(a6)                   ; modulos for source and target
  clr.w       BLTDMOD(a6)
  move.l      a5,a0
  add.l       #ig_cm_score_backup,a0
  move.l      a0,BLTDPTH(a6)                                       ; pointers
  move.l      ig_om_frontbuffer(a4),d7
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*208)+18,d7
  move.l      d7,BLTAPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+8,BLTSIZE(a6)             ; start blit

  ; initial draw
  move.l      ig_om_frontbuffer(a4),d7
  bsr.s       sc_update

  rts

; draws score
sc_draw:
  tst.b       ig_om_score_draw_counter(a4)
  beq.s       .exit

  move.l      ig_om_backbuffer(a4),d7
  bsr.s       sc_update

.next:
  lea.l       ig_om_score_draw_counter(a4),a0
  sub.b       #1,(a0)
.exit:
  rts

; draws score
; in:
;   d7 - pointer to framebuffer
sc_update:

  ;
  ; restore background
  ;
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                       ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                            ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #IgScreenWidthBytes-16,BLTDMOD(a6)                   ; modulos for source and target
  clr.w       BLTAMOD(a6)
  move.l      a5,a0
  add.l       #ig_cm_score_backup,a0
  move.l      a0,BLTAPTH(a6)                                       ; pointers
  move.l      d7,d0
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*208)+18,d0
  move.l      d0,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+8,BLTSIZE(a6)             ; start blit

  ;
  ; score to string
  ;
  move.l      c_om_score(a4),d0
  bsr         bcd_to_string_of_8

  ;
  ; print score
  ;
  move.l      sc_font_metadata_ptr(pc),a1
  move.l      d7,d4
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*209)+18,d4    ; target pointer

  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d7
  move.w      d7,BLTAFWM(a6)
  move.w      d7,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  moveq.l     #32,d0                                               ; offset zero char
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
  add.l       d5,d0                                                ; gfx ptr
  move.l      d6,d1
  add.l       d5,d1                                                ; mask ptr

  WAIT_BLT

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d4,BLTCPTH(a6)
  move.l      d4,BLTDPTH(a6)

  ; start blit
  move.w      #(12*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next
  addq.l      #2,d4
  bra.s       .loop

.exit:
  rts

;
; vars section (initialized in sc_init)
;

sc_font_metadata_ptr:
  dc.l        0
sc_font_gfx_ptr:
  dc.l        0
sc_font_mask_ptr:
  dc.l        0

  endif                                                            ; ifnd INGAME_SCORE_ASM
