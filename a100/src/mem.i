  ifnd       MEM_I
MEM_I            equ 1

  include    "../a100/files_index.i"
  include    "../a100/src/ingame/ingame.i"
  include    "../a100/src/highscores/highscores.i"
  include    "../a100/src/mainmenu/mainmenu.i"

A100ChipMemSize  equ hs_cm_sizeof
A100OtherMemSize equ mm_om_sizeof

  endif                                               ; ifnd MEM_I
