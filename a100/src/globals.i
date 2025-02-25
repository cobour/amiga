                            ifnd       GLOBALS_I
GLOBALS_I        equ 1
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
MemScheme        equ MemCustom

; Game-Modes
GameModeInfinite equ 1
GameModeSpeedRun equ 2

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
c_om_framecounter:          rs.l       1                                  ; incremented by copper irq - WARNING: this counts "real" frames aka 50Hz, not the actually drawn frames which may be less when drawing a frame takes more time than 1/50th of a second
c_om_score:                 rs.l       1                                  ; score of player (set ingame, needed in highscore-table)
c_om_gamemode:              rs.b       1                                  ; GameModeInfinite or GameModeSpeedRun - set by mainmenu, used by ingame
c_om_padding_byte:          rs.b       1
c_om_sizeof:                rs.b       0

                            endif                                         ; ifnd GLOBALS_I
