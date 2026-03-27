  ifnd     INGAME_PLAYER_I
INGAME_PLAYER_I           equ 1

; anim steps player ship (byte offsets)
PlayerShipAnimHardLeft    equ 0
PlayerShipAnimLeft        equ 4
PlayerShipAnimCentered    equ 8
PlayerShipAnimRight       equ 12
PlayerShipAnimHardRight   equ 16

; delay in frames between e.g. left and hard left
PlayerShipAnimSwitchDelay equ 10

  endif                       ; ifnd INGAME_PLAYER_I
