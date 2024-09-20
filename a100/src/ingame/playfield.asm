  ifnd        PLAYFIELD_ASM
PLAYFIELD_ASM equ 1

  include     "../common/src/system/blitter.i"
  include     "../a100/src/ingame/screen.i"

; is called before anything is seen on screen
pf_init:
  bsr         .init_data

; fills playfield with empty bricks
; draws to frontbuffer (which is copied to backbuffer after init)
.init_gfx:
  ; get empty brick - gfx and mask pointers
  move.l      #f000_gfx_bricks_big,d0
  bsr         datafiles_get_pointer
  lea.l       df_idx_metadata(a0),a1
  move.l      df_idx_ptr_rawdata(a0),d0                          ; source gfx data
  move.l      d0,d1
  add.l       df_iff_rawsize(a1),d1                              ; source mask data

  ; get target pointer for first brick
  move.l      ig_om_frontbuffer(a4),d2
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16)+2,d2

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

  ; rows loop
  moveq.l     #9,d7
.ig_rows_loop:

  ; columns loop
  moveq.l     #9,d6
  move.l      d2,d3
.ig_columns_loop:

  WAIT_BLT

  ; source pointers
  move.l      d1,BLTAPTH(a6)
  move.l      d0,BLTBPTH(a6)

  ; destination pointers
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; start blit
  move.w      #(16*IgScreenBitPlanes<<6)+1,BLTSIZE(a6)

  ; next columns loop iteration
  addq.l      #2,d3
  dbf         d6,.ig_columns_loop

  ; next rows loop iteration
  add.l       #(IgScreenWidthBytes*IgScreenBitPlanes*16),d2
  dbf         d7,.ig_rows_loop

  rts

; initializes data structure
.init_data:
  lea.l       playfield_data(pc),a0
  moveq.l     #0,d0
  moveq.l     #24,d7                                             ; 100 bytes = 25 longs
.id_array_loop:
  move.l      d0,(a0)+
  dbf         d7,.id_array_loop

  rts

;
; vars section
;

playfield_data: ; index array for brick per field
  dcb.b       100

  endif                                                          ; ifnd PLAYFIELD_ASM
