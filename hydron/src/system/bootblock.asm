
; no build task - define these here
BOOTBLOCK      equ 1
RELEASE        equ 1
USE_TRACKDISK  equ 1

MAIN_CODE_FILE equ $43303030                      ; "C000"

  dc.b       "DOS",0                              ; disk type
  dc.l       0                                    ; checksum
  dc.l       880                                  ; root block

  include    "../common/src/system/loader.asm"
