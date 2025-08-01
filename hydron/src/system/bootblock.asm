
; bootblock metadata and loader

MAIN_CODE_FILE equ $43303030                      ; "C000"

  dc.b       "DOS",0                              ; disk type
  dc.l       0                                    ; checksum
  dc.l       880                                  ; root block

  include    "../common/src/system/loader.asm"
