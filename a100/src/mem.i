  ifnd       MEM_I
MEM_I            equ 1

  include    "../a100/asm_files_index.i"
  include    "../a100/files_index.i"
  include    "../a100/src/ingame.i"

A100ChipMemSize  equ ig_cm_sizeof

A100OtherMemSize equ (ig_om_sizeof+c000_unzipped_filesize)

  endif                                     ; ifnd MEM_I
