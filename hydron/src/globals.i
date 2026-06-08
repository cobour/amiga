                            ifnd       GLOBALS_I
GLOBALS_I equ 1
                            include    "../common/src/system/custom.i"
                            include    "../common/src/system/disk.i"

; Set base pointers
; sets a4-a6
SETPTRS                     macro
                            lea.l      CustomBase,a6
                            move.l     chip_mem_ptr(pc),a5
                            move.l     other_mem_ptr(pc),a4
                            endm

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
c_om_vbl:                   rs.b       1                                  ; set to 1 when vbl occurred (by irq handlers of game parts)
c_om_next_frame_ready:      rs.b       1                                  ; set to 1 when next frame that is rendered in backbuffer is ready to be displayed
c_om_dummy:                 rs.b       1                                  ; padding byte
c_om_lives:                 rs.b       1                                  ; lives of player as bcd
c_om_score:                 rs.l       1                                  ; current score of player as bcd
c_om_hiscore:               rs.l       1                                  ; hiscore as bcd
c_om_sizeof:                rs.b       0

                            endif                                         ; ifnd GLOBALS_I
