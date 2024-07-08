                  ifnd       KEYBOARD_I
KEYBOARD_I     equ 1

KBD_HANDSHAKE  equ 65                          ; duration for keyboard SP handshaking
KBD_QUEUE_SIZE equ 16                          ; size of key buffer, must be a power of 2, below 256

; commented constants already defined in ptplayer.asm

;CIAA           equ $bfe001
;CIAB           equ $bfd000

;CIAPRA         equ $000
CIAPRB         equ $100
CIADDRA        equ $200
CIADDRB        equ $300
;CIATALO        equ $400
;CIATAHI        equ $500
;CIATBLO        equ $600
;CIATBHI        equ $700
CIATODLO       equ $800
CIATODMID      equ $900
CIATODHI       equ $a00
CIASDR         equ $c00
;CIAICR         equ $d00
;CIACRA         equ $e00
;CIACRB         equ $f00

                  rsreset
; do not change order of fields - when adding fields, add at the end
kbd_write_index:  rs.w       1
kbd_read_index:   rs.w       1
kbd_queue:        rs.b       KBD_QUEUE_SIZE
kbd_size:         rs.b       0

                  endif                        ; ifnd KEYBOARD_I