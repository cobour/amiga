  ifnd     INGAME_SCREEN_I
INGAME_SCREEN_I    equ 1

IgScreenBitPlanes  equ 5
IgScreenWidth      equ 320
IgScreenWidthBytes equ (IgScreenWidth/8)
IgScreenHeight     equ 256
IgScreenStartX     equ $81
IgScreenStartY     equ $2c
IgScreenStopX      equ IgScreenStartX+IgScreenWidth
IgScreenStopY      equ IgScreenStartY+IgScreenHeight

  endif                       ; ifnd INGAME_SCREEN_I
