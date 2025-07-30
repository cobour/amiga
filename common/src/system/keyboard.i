                  ifnd       KEYBOARD_I
KEYBOARD_I     equ 1

KBD_HANDSHAKE  equ 65                          ; duration for keyboard SP handshaking
KBD_QUEUE_SIZE equ 16                          ; size of key buffer, must be a power of 2, below 256

                  rsreset
; do not change order of fields - when adding fields, add at the end
kbd_write_index:  rs.w       1
kbd_read_index:   rs.w       1
kbd_queue:        rs.b       KBD_QUEUE_SIZE
kbd_size:         rs.b       0

                  endif                        ; ifnd KEYBOARD_I