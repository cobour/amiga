  ifnd     JOYSTICK_I
JOYSTICK_I equ 1

; commented constants already defined in ptplayer.asm
;CIAA           equ $bfe001
FireButton equ $7        ; Joystick in Port 1

; bits of joystick state (returned by joystick.asm -> joystick_read)
; 1 = yes, 0 = no
JsUp       equ 0
JsDown     equ 1
JsLeft     equ 2
JsRight    equ 3
JsFire     equ 4

  endif                  ; ifnd JOYSTICK_I
