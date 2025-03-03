  ifnd     MAINMENU_SCREEN_I
MAINMENU_SCREEN_I  equ 1

MmScreenBitPlanes  equ 5
MmScreenWidth      equ 320
MmScreenWidthBytes equ (MmScreenWidth/8)
MmScreenHeight     equ 256
MmScreenStartX     equ $81
MmScreenStartY     equ $2c
MmScreenStopX      equ MmScreenStartX+MmScreenWidth
MmScreenStopY      equ MmScreenStartY+MmScreenHeight

  endif                         ; ifnd MAINMENU_SCREEN_I
