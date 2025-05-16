                      ifnd       MENUPART_I
MENUPART_I             equ 1

                      include    "src/system/savegame.i"

MenuPartRows           equ 6
MenuPartRowLength      equ 16
MenuPartRowZoomCounter equ 16

; MenuParts
MpMain                 equ 1
MpCreditsGfx           equ 2
MpCreditsMusic         equ 3
MpCreditsCode          equ 4
MpInstructions1        equ 5
MpInstructions2        equ 6
MpInstructions3        equ 7
MpHighscoresInfinite   equ 8
MpHighscoresTimer      equ 9

                      rsreset
mp_id:                rs.w       1                                 ; unique id
mp_timer:             rs.w       1                                 ; frames until switched to next menupart (-1 if no automatic switch)
mp_row_zoom_counter:  rs.b       MenuPartRows
                      align      2
mp_rowdata:           rs.b       MenuPartRows*MenuPartRowLength    ; not-terminated strings for the rows to be displayed
mp_sizeof:            rs.b       0             

                      macro      ISZOOM
                      movem.l    a0/d7,-(sp)
                      lea.l      \1(pc),a0
                      moveq.l    #0,\2
                      moveq.l    #MenuPartRows-1,d7
.1\@:
                      add.b      (a0)+,\2
                      dbf        d7,.1\@ 
                      movem.l    (sp)+,a0/d7
                      endm

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

                      macro      GAME_S
                      move.l     a0,-(sp)
                      lea.l      mp_data_start_or_resume(pc),a0
                      move.l     #"  (S",(a0)+
                      move.l     #")TAR",(a0)+
                      move.l     #"T GA",(a0)+
                      move.l     #"ME  ",(a0)
                      move.l     (sp)+,a0
                      endm

                      macro      GAME_R
                      move.l     a0,-(sp)
                      lea.l      mp_data_start_or_resume(pc),a0
                      move.l     #" (R)",(a0)+
                      move.l     #"ESUM",(a0)+
                      move.l     #"E  G",(a0)+
                      move.l     #"AME ",(a0)
                      move.l     (sp)+,a0
                      endm

                      endif                                        ; ifnd MENUPART_I
