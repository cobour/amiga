  ifnd     HIGHSCORES_SCREEN_I
HIGHSCORES_SCREEN_I equ 1

HsScreenBitPlanes   equ 5
HsScreenWidth       equ 320
HsScreenWidthBytes  equ (HsScreenWidth/8)
HsScreenHeight      equ 256
HsScreenStartX      equ $81
HsScreenStartY      equ $2c
HsScreenStopX       equ HsScreenStartX+HsScreenWidth
HsScreenStopY       equ HsScreenStartY+HsScreenHeight

  endif                           ; ifnd HIGHSCORES_SCREEN_I
