
;
; to debug the bootblock loader (bootblock itself and init code that is called by bootblock that inits mem pointers and reads file directory)
;

DISK_DRIVE_BIT equ 4                                 ; default to df1 for debugging

  include    "main_code.i"
  include    "../common/src/system/loader_dd.asm"
