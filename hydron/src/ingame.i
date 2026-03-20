                               ifnd       INGAME_I
INGAME_I           equ 1
                               include    "src/globals.i"

; Ingame screen definitions
IgScreenBitPlanes  equ 6
IgScreenWidth      equ 256
IgScreenWidthBytes equ (IgScreenWidth/8)
IgScreenHeight     equ 256
IgScreenStartX     equ $a1
IgScreenStartY     equ $2c
IgScreenStopX      equ IgScreenStartX+IgScreenWidth
IgScreenStopY      equ IgScreenStartY+IgScreenHeight

; Ingame copperlist struct
                               rsreset
ig_cm_cl_sprites:              rs.l       16
ig_cm_cl_sprite01_init:        rs.l       4
ig_cm_cl_bitplanes:            rs.l       12
ig_cm_cl_bpl_config:           rs.l       9
ig_cm_cl_irq:                  rs.l       1
ig_cm_cl_colors:               rs.l       32
ig_cm_cl_panel:                rs.l       531                ; includes re-setting bitplane pointers at end of each panel row
ig_cm_cl_reuse_sprites:        rs.l       8
ig_cm_cl_end:                  rs.l       1
ig_cm_cl_sizeof:               rs.b       0

; Ingame chip mem struct
                               rsreset
ig_cm_common:                  rs.b       c_cm_sizeof
ig_cm_copperlist:              rs.b       ig_cm_cl_sizeof
; ingame/player.asm
ig_cm_dummysprite1:            rs.b       28                 ; TODO: remove
ig_cm_dummysprite2:            rs.b       28                 ; TODO: remove
ig_cm_dummysprite3:            rs.b       28                 ; TODO: remove
ig_cm_player_sprite4:          rs.l       34
ig_cm_player_sprite5:          rs.l       34
ig_cm_player_sprite6:          rs.l       34
ig_cm_player_sprite7:          rs.l       34
;
ig_cm_filebuffer:              rs.b       100000             ; TODO: inside framebuffer
ig_cm_dmabuffer:               rs.b       15000              ; TODO: inside framebuffer
; data files area
ig_cm_datfile:                 rs.b       0                  ; variable filesizes, therefore this MUST be the last entry in this struct
ig_cm_sizeof:                  rs.b       0

; Ingame other mem struct
                               rsreset
ig_om_common:                  rs.b       c_om_sizeof
; ingame/player.asm
ig_om_player_gfx_ptr:          rs.l       1                  ; pointer to the beginning of the gfx rawdata
ig_om_player_anim_offset:      rs.l       1                  ; offset to the current anim step (to be added to ig_om_player_gfx_ptr)
ig_om_player_gfx_width_bytes:  rs.w       1                  ; width of the source graphics in bytes
; data files area
ig_om_datfile:                 rs.b       0                  ; variable filesizes, therefore this MUST be the last entry in this struct
ig_om_sizeof:                  rs.b       0

                               endif                         ; ifnd INGAME_I
