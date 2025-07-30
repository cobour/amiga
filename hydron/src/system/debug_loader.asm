
;
; to debug the bootblock loader (bootblock itself and init code that is called by bootblock that inits mem pointers and reads file directory)
;

MAIN_CODE_FILE equ $43303030                      ; "C000"

  include    "../common/src/system/loader.asm"
