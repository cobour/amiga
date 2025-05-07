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
  move.l      a1,(a3)+                                                                ; metadata
  move.l      df_idx_ptr_rawdata(a0),d0
  move.l      d0,(a3)+                                                                ; gfx
  add.l       df_iff_rawsize(a1),d0
  move.l      d0,(a3)+                                                                ; mask

  ; init more vars
  clr.l       (a3)+                                                                   ; mp_zoom_in_counter and mp_zoom_out_counter - 12 bytes - MUST BE ADJUSTED WHEN MenuPartRows IS CHANGED
  clr.l       (a3)+
  clr.l       (a3)+

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

  ; if there is already something visible, old zoom-counters must be set into zoom-out-counters
  tst.l       (a1)
  beq.s       .0
  move.l      (a1),a2
  lea.l       mp_row_zoom_counter(a2),a2
  lea.l       mp_zoom_out_counter(pc),a3
  moveq.l     #MenuPartRows-1,d1
.copy_loop:
  move.b      (a2)+,(a3)+
  dbf         d1,.copy_loop
.0:
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
  lea.l       mp_rowdata(a0),a0
  moveq.l     #MenuPartRowLength,d7
.draw_loop:
  bsr.s       mp_draw_line_to_print_buffer
  addq.l      #1,d0
  cmp.b       #MenuPartRows,d0
  beq.s       .draw_end
  add.l       d7,a0
  bra.s       .draw_loop
.draw_end:

  ; set zoom-in counter for part
  move.l      (a1),a2
  lea.l       mp_row_zoom_counter(a2),a2
  lea.l       mp_zoom_in_counter(pc),a3
  moveq.l     #MenuPartRows-1,d1
.copy_loop2:
  move.b      (a2)+,(a3)+
  dbf         d1,.copy_loop2

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
  bsr         mm_clear_text_print_buffer_line
  add.l       a5,d1
  add.l       #mm_cm_textarea_print_buffer,d1                                         ; target pointer (begin of row)

  move.l      mp_font_gfx_ptr(pc),d3                                                  ; source pointer gfx  (base pointer, space char)
  move.l      mp_font_mask_ptr(pc),d2                                                 ; source pointer mask (base pointer, space char)

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
  add.l       d0,d5                                                                   ; source pointer gfx
  move.l      d2,d4
  add.l       d0,d4                                                                   ; source pointer mask

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

  ; while zoom-counters (in or out) are set, do not process events
  ISZOOM      mp_zoom_out_counter,d0
  tst.w       d0
  bne.s       .exit
  ISZOOM      mp_zoom_in_counter,d0
  tst.w       d0
  bne.s       .exit

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
  cmp.b       #$21,d0                                                                 ; S
  beq.s       .mp_main_start
  cmp.b       #$37,d0                                                                 ; M
  beq.s       .mp_main_mode
  cmp.b       #$12,d0                                                                 ; E
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
  ; switch to timer mode
  MODE_T
  move.b      #GameModeSpeedRun,c_om_gamemode(a4)
  bra.s       .mp_main_mode_switch_redraw_second_line
.mp_main_mode_switch_to_infinite:
  ; switch to infinite mode
  MODE_I
  move.b      #GameModeInfinite,c_om_gamemode(a4)
.mp_main_mode_switch_redraw_second_line:
  ; redraw second menu line
  moveq.l     #1,d0
  lea.l       mp_data_mode(pc),a0
  bsr         mp_draw_line_to_print_buffer
  ; trigger zoom out and zoom in of second menu line
  lea.l       mp_zoom_out_counter+1(pc),a0
  move.b      #MenuPartRowZoomCounter,(a0)
  lea.l       mp_zoom_in_counter+1(pc),a0
  move.b      #MenuPartRowZoomCounter,(a0)
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
  bra         fade_init                                                               ; implicit rts

mp_update:

  ISZOOM      mp_zoom_out_counter,d0
  tst.w       d0
  beq.s       .test_zoom_in

  ; init values for line of menu
  lea.l       mp_zoom_out_counter(pc),a0
  move.l      a5,d5                                                                   ; pointer to restore buffer
  add.l       #mm_cm_textarea_restore_buffer,d5
  move.l      #MmOffsetOfTextArea,d6                                                  ; offset in screenbuffer
  moveq.l     #MenuPartRows-1,d7
.zo_find_line_loop:
  tst.b       (a0)
  bne.s       .zo_line_found
  addq.l      #1,a0
  add.l       #MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20,d5
  add.l       #MmScreenWidthBytes*MmScreenBitPlanes*20,d6
  dbf         d7,.zo_find_line_loop
.zo_line_found:

  sub.b       #1,(a0)                                                                 ; sub first because counter must be executed for 16 to 1 and not for zero - but zero-based access to data-table
  moveq.l     #0,d0
  move.b      (a0),d0                                                                 ; step for zoom out -> use to pick values in zoom_data
  lsl.w       #3,d0
  lea.l       .zoom_data(pc),a0
  moveq.l     #0,d4
  move.w      (a0,d0.w),d4
  add.l       d4,d5                                                                   ; BLTAPTH
  move.w      2(a0,d0.w),d4
  add.l       d4,d6                                                                   ; BLTDPTH
  move.w      4(a0,d0.w),d4                                                           ; BLTSIZE
  bra.s       .do_blit

.test_zoom_in:
  ISZOOM      mp_zoom_in_counter,d0
  tst.w       d0
  beq         .exit
  
  ; init values for line of menu
  lea.l       mp_zoom_in_counter(pc),a0
  move.l      a5,d5                                                                   ; pointer to print buffer
  add.l       #mm_cm_textarea_print_buffer,d5
  move.l      #MmOffsetOfTextArea,d6                                                  ; offset in screenbuffer
  moveq.l     #MenuPartRows-1,d7
.zi_find_line_loop:
  tst.b       (a0)
  bne.s       .zi_line_found
  addq.l      #1,a0
  add.l       #MmTextAreaBufferWidthBytes*MmScreenBitPlanes*20,d5
  add.l       #MmScreenWidthBytes*MmScreenBitPlanes*20,d6
  dbf         d7,.zi_find_line_loop
.zi_line_found:

  sub.b       #1,(a0)                                                                 ; sub first because counter must be executed for 16 to 1 and not for zero - but zero-based access to data-table
  moveq.l     #0,d0
  move.b      (a0),d0                                                                 ; step for zoom in -> use to pick values in zoom_data
  lsl.w       #3,d0
  lea.l       .zoom_data(pc),a0
  moveq.l     #0,d4
  move.w      (a0,d0.w),d4
  add.l       d4,d5                                                                   ; BLTAPTH
  move.w      2(a0,d0.w),d4
  add.l       d4,d6                                                                   ; BLTDPTH
  move.w      4(a0,d0.w),d4                                                           ; BLTSIZE

.do_blit:
  WAIT_BLT
  move.w      #%0000100111110000,BLTCON0(a6)                                          ; simple A -> D copy, no shifting
  clr.w       BLTCON1(a6)
  move.w      #$ffff,d0                                                               ; no first/last word mask
  move.w      d0,BLTAFWM(a6)
  move.w      d0,BLTALWM(a6)
  clr.w       BLTAMOD(a6)                                                             ; modulos for source and target
  move.w      #MmScreenWidthBytes-MmTextAreaBufferWidthBytes,BLTDMOD(a6)
  move.l      d5,BLTAPTH(a6)                                                          ; pointers
  move.l      mm_om_backbuffer(a4),d0
  add.l       d6,d0
  move.l      d0,BLTDPTH(a6)
  move.w      d4,BLTSIZE(a6)                                                          ; start blit - TODO use d4

.exit:
  rts

.zoom_data: ; offset src, offset dest and bltsize (and dummy word so size is power of 2)
  ; 0
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*0
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*0
  dc.w        (16*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 1
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*0
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*0
  dc.w        (16*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 2
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*1
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*1
  dc.w        (14*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 3
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*1
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*1
  dc.w        (14*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 4
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*2
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*2
  dc.w        (12*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 5
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*2
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*2
  dc.w        (12*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 6
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*3
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*3
  dc.w        (10*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 7
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*3
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*3
  dc.w        (10*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 8
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*4
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*4
  dc.w        (8*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 9
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*4
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*4
  dc.w        (8*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 10
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*5
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*5
  dc.w        (6*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 11
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*5
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*5
  dc.w        (6*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 12
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*6
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*6
  dc.w        (4*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 13
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*6
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*6
  dc.w        (4*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 14
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*7
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*7
  dc.w        (2*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1
  ; 15
  dc.w        MmTextAreaBufferWidthBytes*MmScreenBitPlanes*7
  dc.w        MmScreenWidthBytes*MmScreenBitPlanes*7
  dc.w        (2*MmScreenBitPlanes<<6)+MmTextAreaBufferWidthWords
  dc.w        -1

;
; vars
;

mp_current_part:
  dc.w        0                                                                       ; id of current part
mp_current_part_data:
  dc.l        0

mp_font_metadata_ptr:
  dc.l        0
mp_font_gfx_ptr:
  dc.l        0
mp_font_mask_ptr:
  dc.l        0

mp_zoom_in_counter:
  dcb.b       MenuPartRows
  even
mp_zoom_out_counter:
  dcb.b       MenuPartRows
  even

;
; menupart data section (see mp_* struct)
;

mp_data:
  ; main menu section
  dc.w        MpMain
  dc.w        -1
  dc.b        MenuPartRowZoomCounter,MenuPartRowZoomCounter,MenuPartRowZoomCounter
  dc.b        MenuPartRowZoomCounter,MenuPartRowZoomCounter,MenuPartRowZoomCounter
  dc.b        "  (S)TART GAME  "
mp_data_mode:
  dcb.b       MenuPartRowLength                                                       ; set via macros MODE_I and MODE_T
  dc.b        " (I)NSTRUCTIONS "
  dc.b        "  (H)IGHSCORES  "
  dc.b        "   (C)REDITS    "
  dc.b        "     (E)XIT     "


  dc.w        -1                                                                      ; end of list

  endif                                                                               ; ifnd MENUPART_ASM
