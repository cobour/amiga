; DO NOT INCLUDE ANYWHERE IN OTHER ASM-FILES --- file is included in datafile
; MUST MATCH sg_data_* structs
  include    "src/system/savegame.i"
  dcb.b      sg_data_sizeof,0
