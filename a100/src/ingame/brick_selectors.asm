  ifnd        BRICK_SELECTORS_ASM
BRICK_SELECTORS_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"

bs_init:

  bsr         .init_data

; fills all three selectors  with empty bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_small,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                            ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                                ; source mask data

  ; init first selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16)+24,d2
  bsr.s       .is_sub_selector

  ; init second selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*76)+24,d2
  bsr.s       .is_sub_selector

  ; init third selector
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*136)+24,d2

; fills one selector with empty bricks
; in:
;   d0 - pointer to source gfx
;   d1 - pointer to source mask
;   d2 - pointer to target
.is_sub_selector:

  WAIT_BLT

  ; empty brick is on the left of word
  move.w      #$ff00,BLTAFWM(a6)
  move.w      #$ff00,BLTALWM(a6)

  ; modulos
  move.w      df_iff_width(a1),d7
  lsr.w       #3,d7
  subq.w      #2,d7
  move.w      d7,BLTAMOD(a6)
  move.w      d7,BLTBMOD(a6)
  move.w      #IgScreenWidthBytes-2,d7
  move.w      d7,BLTCMOD(a6)
  move.w      d7,BLTDMOD(a6)

  ; rows loop
  moveq.l     #4,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #4,d6
  move.l      d2,d3
  move.l      #$8000,d5
.ig_columns_loop:

  WAIT_BLT
  ; shift 0 or 8 px to the right; masked copy
  move.w      d5,d4
  move.w      d4,BLTCON1(a6)
  or.w        #%0000111111001010,d4
  move.w      d4,BLTCON0(a6)

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(8*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next columns loop iteration
  btst        #0,d6
  bne.s       .1
  addq.l      #2,d3
.1:
  swap        d5
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*8),d2
  dbf         d7,.ig_rows_loop

  rts

; initializes data structure
.init_data:
  lea.l       selectors(pc),a0
  moveq.l     #0,d0
  moveq.l     #74,d7
.id_array_loop:
  move.b      d0,(a0)+
  dbf         d7,.id_array_loop

  rts


;
; vars section
;

selectors: ; index arrays for brick per field
  dcb.b       3*25
  even

  endif                                                            ; ifnd BRICK_SELECTORS_ASM
