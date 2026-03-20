  ifnd       INGAME_PLAYER_ASM
INGAME_PLAYER_ASM equ 1

  include    "src/ingame.i"

player_init:

  move.l     #"PLYR",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),ig_om_player_gfx_ptr(a4)
  moveq.l    #8,d0
  move.l     d0,ig_om_player_anim_offset(a4)
  lea.l      df_idx_metadata(a0),a0
  move.w     df_iff_width(a0),d0
  lsr.w      #3,d0
  move.w     d0,ig_om_player_gfx_width_bytes(a4)

  ; set sprite pointers in copperlist
  move.l     #"IGCL",d0
  bsr        datafiles_get_pointer
  move.l     df_idx_ptr_rawdata(a0),a0
  lea.l      ig_cm_cl_sprites+16(a0),a0
  move.l     a5,d0
  add.l      #ig_cm_player_sprite4,d0
  move.w     d0,22(a0)
  swap       d0
  move.w     d0,18(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite5,d0
  move.w     d0,30(a0)
  swap       d0
  move.w     d0,26(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite6,d0
  move.w     d0,38(a0)
  swap       d0
  move.w     d0,34(a0)
  move.l     a5,d0
  add.l      #ig_cm_player_sprite7,d0
  move.w     d0,46(a0)
  swap       d0
  move.w     d0,42(a0)

  rts

player_update:

  move.w     #$3894,d1                                          ; SPRxPOS
  move.w     #$5900,d2                                          ; SPRxCTL
  move.l     ig_om_player_anim_offset(a4),d3
  lea.l      ig_cm_player_sprite4(a5),a2                        ; target pointer SPR4
  lea.l      ig_cm_player_sprite5(a5),a3                        ; target pointer SPR5
  bsr.s      .pu_sub

  move.w     #$389c,d1                                          ; SPRxPOS
  move.w     #$5900,d2                                          ; SPRxCTL
  moveq.l    #2,d3
  add.l      ig_om_player_anim_offset(a4),d3
  lea.l      ig_cm_player_sprite6(a5),a2                        ; target pointer SPR4
  lea.l      ig_cm_player_sprite7(a5),a3                        ; target pointer SPR5
  ; fall-through intended

.pu_sub:
  ; control words
  move.w     d1,(a2)+
  move.w     d2,(a2)+
  add.b      #$80,d2                                            ; attach bit
  move.w     d1,(a3)+
  move.w     d2,(a3)+

  ; bitmap data
  moveq.l    #0,d0
  move.w     ig_om_player_gfx_width_bytes(a4),d0
  move.l     ig_om_player_gfx_ptr(a4),a1
  lea.l      (a1,d3.w),a1
  moveq.l    #32-1,d7
.copy_loop:
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  dbf        d7,.copy_loop

  ; end of sprite data
  clr.l      (a2)+
  clr.l      (a3)+

  rts

  endif                                                         ; ifnd INGAME_PLAYER_ASM
