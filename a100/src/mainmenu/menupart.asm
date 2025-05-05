  ifnd        MENUPART_ASM
MENUPART_ASM equ 1

  include     "../a100/src/mainmenu/mainmenu.i"
  include     "../a100/src/mainmenu/menupart.i"
  include     "../a100/src/mainmenu/sfx.i"
  include     "../common/src/system/screen.i"
  include     "../common/src/system/blitter.i"

mp_init:
  ; font vars - mus be done before mp_set_part
  lea.l       mp_font_metadata_ptr(pc),a3
  move.l      #f004_gfx_font16,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      a1,(a3)+                                                                                 ; metadata
  move.l      df_idx_ptr_rawdata(a0),d0
  move.l      d0,(a3)+                                                                                 ; gfx
  add.l       df_iff_rawsize(a1),d0
  move.l      d0,(a3)+                                                                                 ; mask

  ; init more vars
  clr.w       (a3)                                                                                     ; mp_pending_update_counter

  ; set string for current game mode - must be done before mp_set_part
  bsr.s       mp_set_string_for_game_mode

  ; set menupart
  move.w      #MpMain,d0
  bsr.s       mp_set_part

.exit:
  rts

mp_set_string_for_game_mode:
  cmp.b       #GameModeSpeedRun,c_om_gamemode(a4)
  bne.s       .infinite
  MODE_T
  bra.s       .exit
.infinite:
  MODE_I
.exit:
  rts

; in:
;    d0.w - menupart
mp_set_part:
  lea.l       mp_current_part(pc),a0
  lea.l       mp_current_part_data(pc),a1
  clr.l       (a1)
  move.w      d0,(a0)

  ; set data
  lea.l       mp_data(pc),a0
.loop:
  move.w      (a0),d1
  cmp.w       #-1,d1
  beq.s       .exit
  cmp.w       d0,d1
  bne.s       .loop_next
  move.l      a0,(a1)
  bra.s       .set_data_end
.loop_next:
  lea.l       mp_sizeof(a0),a0
  bra.s       .loop
.set_data_end:

  ; draw to print buffer
  bsr         mm_clear_text_print_buffer
  moveq.l     #0,d0
  move.l      mp_current_part_data(pc),a0
  addq.l      #mp_rowdata,a0
  moveq.l     #MenuPartRowLength,d7
.draw_loop:
  bsr.s       mp_draw_line_to_print_buffer
  addq.l      #1,d0
  cmp.b       #MenuPartRows,d0
  beq.s       .draw_end
  add.l       d7,a0
  bra.s       .draw_loop
.draw_end:

  lea.l       mp_pending_update_counter(pc),a0
  move.b      #2,(a0)

.exit:
  rts

; in:
;   d0 - number of line (0-5)
;   a0 - pointer to string (16 chars, not null-terminated)
mp_draw_line_to_print_buffer:
  movem.l     d0-d5/d7/a0-a1,-(sp)

  add.w       d0,d0
  add.w       d0,d0
  lea.l       .line_offsets(pc),a1
  move.l      (a1,d0.w),d1
  add.l       a5,d1
  add.l       #mm_cm_textarea_print_buffer,d1                                                          ; target pointer (begin of row)

  move.l      mp_font_gfx_ptr(pc),d3                                                                   ; source pointer gfx  (base pointer, space char)
  move.l      mp_font_mask_ptr(pc),d2                                                                  ; source pointer mask (base pointer, space char)

  WAIT_BLT

  ; no pixel shift; masked copy
  moveq.l     #-1,d0
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; modulos
  move.l      mp_font_metadata_ptr(pc),a1
  move.w      df_iff_width(a1),d0
  lsr.w       #3,d0
  subq.w      #2,d0
  move.w      d0,BLTAMOD(a6)
  move.w      d0,BLTBMOD(a6)
  move.w      #MmTextAreaBufferWidthBytes-2,d0
  move.w      d0,BLTCMOD(a6)
  move.w      d0,BLTDMOD(a6)

  moveq.l     #MenuPartRowLength-1,d7
.loop:
  moveq.l     #0,d0
  move.b      (a0)+,d0
  sub.b       #$20,d0
  add.w       d0,d0
  move.l      d3,d5
  add.l       d0,d5                                                                                    ; source pointer gfx
  move.l      d2,d4
  add.l       d0,d4                                                                                    ; source pointer mask

  WAIT_BLT

  move.l      d4,BLTAPTH(a6)
  move.l      d5,BLTBPTH(a6)
  move.l      d1,BLTCPTH(a6)
  move.l      d1,BLTDPTH(a6)
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  addq.l      #2,d1
  dbf         d7,.loop

  movem.l     (sp)+,d0-d5/d7/a0-a1
  rts

.line_offsets:
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*0
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*1
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*2
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*3
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*4
  dc.l        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20*5

mp_process_events:
  tst.b       mm_om_end_countdown(a4)
  bge.s       .exit

  moveq.l     #0,d0

.process_event:
  bsr         ev_get_next_event
  tst.b       d0
  blt.s       .exit

  move.w      mp_current_part(pc),d1
  cmp.w       #MpMain,d1
  bne.s       .0
  bsr.s       .mp_main
  bra.s       .process_event

.0:
  bra.s       .process_event

.exit:
  rts

.mp_main:
  cmp.b       #$21,d0                                                                                  ; S
  beq.s       .mp_main_start
  cmp.b       #$37,d0                                                                                  ; M
  beq.s       .mp_main_mode
  cmp.b       #$12,d0                                                                                  ; E
  beq         .mp_main_exit
  SFX         f004_sfx_error
  rts

.mp_main_start:
  bsr         .exit_mainmenu
  move.b      #NextPartIngame,c_om_next_part(a4)
  SFX         f004_sfx_select
  rts

.mp_main_mode:
  SFX         f004_sfx_step
  move.b      c_om_gamemode(a4),d0
  cmp.b       #GameModeSpeedRun,d0
  beq.s       .mp_main_mode_switch_to_infinite
  MODE_T
  move.b      #GameModeSpeedRun,c_om_gamemode(a4)
  ; for now: redraw complete menupart - CHANGE WHEN ADDING TRANSITION EFFECT
  moveq.l     #MpMain,d0
  bsr         mp_set_part
  ; for now: redraw complete menupart - CHANGE WHEN ADDING TRANSITION EFFECT
  rts
.mp_main_mode_switch_to_infinite:
  MODE_I
  move.b      #GameModeInfinite,c_om_gamemode(a4)
  ; for now: redraw complete menupart - CHANGE WHEN ADDING TRANSITION EFFECT
  moveq.l     #MpMain,d0
  bsr         mp_set_part
  ; for now: redraw complete menupart - CHANGE WHEN ADDING TRANSITION EFFECT
  rts

.mp_main_exit:
  bsr.s       .exit_mainmenu
  move.b      #NextPartExit,c_om_next_part(a4)
  SFX         f004_sfx_select
  rts

.exit_mainmenu:
  ; set end countdown
  move.b      #35,mm_om_end_countdown(a4)
  ; trigger fade out
  move.l      #f005_gfx_mainmenu_screen_colors,d0
  bsr         datafiles_get_pointer
  move.l      df_idx_ptr_rawdata(a0),a1
  lea.l       mm_om_fade_color_tab(a4),a0
  moveq.l     #32,d0
  moveq.l     #1,d1
  bra         fade_init                                                                                ; implicit rts

mp_update:
  lea.l       mp_pending_update_counter(pc),a0
  tst.b       (a0)
  beq.s       .exit
  sub.b       #1,(a0)

  ; blit printbuffer to screenbuffer
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                                                           ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                                                                ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  clr.w       BLTAMOD(a6)                                                                              ; modulos for source and target
  move.w      #MmScreenWidthBytes-MmTextAreaBufferWidthBytes,BLTDMOD(a6)
  move.l      a5,d0                                                                                    ; pointers
  add.l       #mm_cm_textarea_print_buffer,d0
  move.l      d0,BLTAPTH(a6)
  move.l      mm_om_backbuffer(a4),d0
  add.l       #MmOffsetOfTextArea,d0
  move.l      d0,BLTDPTH(a6)
  move.w      #(MmTextAreaBufferHeight*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords,BLTSIZE(a6)    ; start blit

.exit:
  rts

;
; vars
;

mp_current_part:
  dc.w        0                                                                                        ; id of current part
mp_current_part_data:
  dc.l        0

mp_font_metadata_ptr:
  dc.l        0
mp_font_gfx_ptr:
  dc.l        0
mp_font_mask_ptr:
  dc.l        0

mp_pending_update_counter:
  dc.b        0
.padding_byte:
  dc.b        0

;
; menupart data section (see mp_* struct)
;

mp_data:
  ; main menu section
  dc.w        MpMain
  dc.w        -1
  dc.b        "  (S)TART GAME  "
mp_data_mode:
  dcb.b       MenuPartRowLength                                                                        ; set via macros MODE_I and MODE_T
  dc.b        " (I)NSTRUCTIONS "
  dc.b        "  (H)IGHSCORES  "
  dc.b        "   (C)REDITS    "
  dc.b        "     (E)XIT     "


  dc.w        -1                                                                                       ; end of list

  endif                                                                                                ; ifnd MENUPART_ASM
