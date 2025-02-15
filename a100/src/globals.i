                            ifnd       GLOBALS_I
GLOBALS_I equ 1
                            include    "../a100/src/mem.i"
                            include    "../common/src/system/custom.i"
                            include    "../common/src/system/disk.i"

; Set base pointers
; sets a4-a6
SETPTRS                     macro
                            lea.l      CustomBase,a6
                            move.l     chip_mem_ptr(pc),a5
                            move.l     other_mem_ptr(pc),a4
                            endm

; Select Memory Scheme
MemScheme equ MemCustom

; *********************
; common memory structs
; *********************

; common chip-mem base struct (MUST be included in any chip-mem-struct at the beginning)
                            rsreset
c_cm_all_black_copperlist:  rs.l       3
c_cm_sizeof:                rs.b       0

; common other-mem base struct (MUST be included in any other-mem-struct at the beginning)
                            rsreset
c_om_disk:                  rs.b       disk_sizeof
c_om_score:                 rs.l       1                                  ; score of player (set ingame, needed in highscore-table)
c_om_sizeof:                rs.b       0

                            endif                                         ; ifnd GLOBALS_I
