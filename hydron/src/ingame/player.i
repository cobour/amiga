                          ifnd       INGAME_PLAYER_I
INGAME_PLAYER_I           equ 1

; anim steps player ship (byte offsets)
PlayerShipAnimHardLeft    equ 0
PlayerShipAnimLeft        equ 4
PlayerShipAnimCentered    equ 8
PlayerShipAnimRight       equ 12
PlayerShipAnimHardRight   equ 16

; delay in frames between e.g. left and hard left
PlayerShipAnimSwitchDelay equ 10

; height of player ship in pixels
PlayerShipHeight          equ 22

; struct holding data for hardware sprites
                          rsreset
ig_player_sprite0:        rs.l       1                     ; player satellites --- just empty for now
ig_player_sprite1:        rs.l       1                     ; player satellites --- just empty for now
ig_player_sprite2:        rs.l       1                     ; player satellites / player shots --- just empty for now
ig_player_sprite3:        rs.l       1                     ; player satellites / player shots --- just empty for now
ig_player_sprite4:        rs.l       PlayerShipHeight+2    ; player ship / player shots
ig_player_sprite5:        rs.l       PlayerShipHeight+2    ; player ship / player shots
ig_player_sprite6:        rs.l       PlayerShipHeight+2    ; player ship / player shots
ig_player_sprite7:        rs.l       PlayerShipHeight+2    ; player ship / player shots
ig_player_sprite_sizeof:  rs.b       0

                          endif                            ; ifnd INGAME_PLAYER_I
