
;
; to debug the bootblock loader (bootblock itself and init code that is called by bootblock that inits mem pointers and reads file directory)
;

  include    "asm_files_index.i"

MAIN_CODE_FILE      equ $43303030                 ; "C000"
MAIN_CODE_FILE_SIZE equ c000_unzipped_filesize

  include    "../common/src/system/loader.asm"
