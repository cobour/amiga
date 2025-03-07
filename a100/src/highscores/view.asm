  ifnd        VIEW_HIGHSCORES_ASM
VIEW_HIGHSCORES_ASM equ 1

  include     "../a100/src/highscores/highscores.i"
  include     "../common/src/system/blitter.i"
  include     "../a100/src/highscores/screen.i"


hs_view_init:
  ; init gfx and mask pointers
  lea.l       hsv_font_metadata(pc),a3
  move.l      #f002_gfx_font16,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      a1,(a3)+                                               ; metadata
  move.l      df_idx_ptr_rawdata(a0),d0
  move.l      d0,(a3)+                                               ; gfx
  add.l       df_iff_rawsize(a1),d0
  move.l      d0,(a3)+                                               ; mask
  
  ; init scores-string
  lea.l       hs_om_highscore_data(a4),a2
  move.b      c_om_gamemode(a4),d0
  cmp.b       #GameModeSpeedRun,d0
  beq.s       .0
  ; step to infinite-mode-highscores
  lea.l       hs_data_entry_sizeof*5(a2),a2
.0:
  moveq.l     #4,d7
.create_string_loop:
  ; copy name
  move.l      (a2)+,(a3)+
  move.w      (a2)+,(a3)+
  ; add two spaces
  move.w      #$2020,(a3)+
  ; score
  move.l      (a2)+,d0
  bsr         bcd_to_string_of_8
  move.l      (a0)+,(a3)+
  move.l      (a0),(a3)+
  ; next row
  dbf         d7,.create_string_loop

  ; init values
  lea.l       hsv_scores_string(pc),a0
  lea.l       hsv_scores_next_char(pc),a1
  moveq.l     #0,d0
  move.l      a0,(a1)+                                               ; hsv_scores_next_char
  move.l      #(HsScreenBitPlanes*HsScreenWidthBytes*127)+4,(a1)+    ; hsv_draw_row_start_offset
  move.l      d0,(a1)+                                               ; hsv_draw_inner_row_offset
  move.w      d0,(a1)+                                               ; hsv_draw_buffer_counter

  rts

hs_view_draw:
  move.l      hsv_scores_next_char(pc),a0
  tst.b       (a0)
  beq         .exit

  moveq.l     #0,d0
  move.b      (a0),d0

  ; calc offset for char
  sub.b       #$20,d0
  add.w       d0,d0

  move.l      hsv_font_metadata(pc),a1
  move.l      hsv_font_gfx_ptr(pc),d1
  add.l       d0,d1                                                  ; d1 = gfx pointer
  move.l      hsv_font_mask_ptr(pc),d2
  add.l       d0,d2                                                  ; d2 = mask pointer
  move.l      hs_om_backbuffer(a4),d3
  add.l       hsv_draw_row_start_offset(pc),d3
  add.l       hsv_draw_inner_row_offset(pc),d3                       ; d3 = target pointer

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
  move.w      #HsScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; source pointers
  move.l      d2,BLTAPTH(a6)
  move.l      d1,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(16*HsScreenBitPlanes<<6)+1,BLTSIZE(a6)

.upd_pointers_and_offsets:
  lea.l       hsv_draw_buffer_counter(pc),a1
  add.b       #1,(a1)
  cmp.b       #2,(a1)
  bne.s       .exit

  ; actual char drawn to both buffers - switch to next char
  clr.b       (a1)
  lea.l       hsv_scores_next_char(pc),a0
  moveq.l     #1,d0
  add.l       d0,(a0)

  ; update offsets for next char
  lea.l       hsv_draw_row_start_offset(pc),a0
  lea.l       hsv_draw_inner_row_offset(pc),a1
  moveq.l     #2,d0
  add.l       d0,(a1)
  cmp.l       #MaxInnerRowOffset,(a1)
  blt.s       .exit
  ; new row
  clr.w       2(a1)
  add.l       #HsScreenBitPlanes*HsScreenWidthBytes*20,(a0)

.exit:
  rts

;
; vars (initialized by hs_view_init)
;

RowLength           equ 6+2+8                                        ; 6 chars = name ; 2 spaces ; 8 chars = score
MaxInnerRowOffset   equ RowLength*2                                  ; max value for hsv_draw_inner_row_offset

hsv_font_metadata:
  dc.l        0

hsv_font_gfx_ptr:
  dc.l        0

hsv_font_mask_ptr:
  dc.l        0

hsv_scores_string:
  dcb.b       RowLength*5           
  dc.w        0                                   

hsv_scores_next_char:
  dc.l        0

hsv_draw_row_start_offset:
  dc.l        0

hsv_draw_inner_row_offset:
  dc.l        0

hsv_draw_buffer_counter:
  dc.b        0                                                      ; draw when this is 0 or 1; then reset to 0 and draw next char
.padding_byte:
  dc.b        0

  endif                                                              ; ifnd VIEW_HIGHSCORES_ASM
