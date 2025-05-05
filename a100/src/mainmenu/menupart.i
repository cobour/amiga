             ifnd       MENUPART_I
MENUPART_I        equ 1

MenuPartRows      equ 6
MenuPartRowLength equ 16

; MenuParts
MpMain            equ 1

             rsreset
mp_id:       rs.w       1                                 ; unique id
mp_timer:    rs.w       1                                 ; frames until switched to next menupart (-1 if no automatic switch)
mp_rowdata:  rs.b       MenuPartRows*MenuPartRowLength    ; not-terminated strings for the rows to be displayed
mp_sizeof:   rs.b       0             

             macro      MODE_I
             move.l     a0,-(sp)
             lea.l      mp_data_mode(pc),a0
             move.l     #"(M)O",(a0)+
             move.l     #"DE: ",(a0)+
             move.l     #"INFI",(a0)+
             move.l     #"NITE",(a0)
             move.l     (sp)+,a0
             endm

             macro      MODE_T
             move.l     a0,-(sp)
             lea.l      mp_data_mode(pc),a0
             move.l     #" (M)",(a0)+
             move.l     #"ODE:",(a0)+
             move.l     #"  TI",(a0)+
             move.l     #"MER ",(a0)
             move.l     (sp)+,a0
             endm

             endif                                        ; ifnd MENUPART_I
