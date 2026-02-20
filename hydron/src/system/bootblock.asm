
; bootblock metadata and loader

DISK_DRIVE_BIT equ 3                                 ; default to df0

  include    "main_code.i"

  dc.b       "DOS",0                                 ; disk type
  dc.l       0                                       ; checksum
  dc.l       880                                     ; root block

  include    "../common/src/system/loader_dd.asm"
