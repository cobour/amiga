; DO NOT INCLUDE ANYWHERE IN OTHER ASM-FILES --- file is included in datafile

  include    "../a100/src/mainmenu/screen.i"
  include    "../common/src/system/custom.i"

; MUST MATCH STRUCT mm_cm_cl_*

; initial wait
  dc.w       $2a01,$ff00
; sprite pointer
  dc.w       SPR0PTH,$0000
  dc.w       SPR0PTL,$0000
  dc.w       SPR1PTH,$0000
  dc.w       SPR1PTL,$0000
  dc.w       SPR2PTH,$0000
  dc.w       SPR2PTL,$0000
  dc.w       SPR3PTH,$0000
  dc.w       SPR3PTL,$0000
  dc.w       SPR4PTH,$0000
  dc.w       SPR4PTL,$0000
  dc.w       SPR5PTH,$0000
  dc.w       SPR5PTL,$0000
  dc.w       SPR6PTH,$0000
  dc.w       SPR6PTL,$0000
  dc.w       SPR7PTH,$0000
  dc.w       SPR7PTL,$0000
; bitplane pointer
  dc.w       BPL1PTH,$0000
  dc.w       BPL1PTL,$0000
  dc.w       BPL2PTH,$0000
  dc.w       BPL2PTL,$0000
  dc.w       BPL3PTH,$0000
  dc.w       BPL3PTL,$0000
  dc.w       BPL4PTH,$0000
  dc.w       BPL4PTL,$0000
  dc.w       BPL5PTH,$0000
  dc.w       BPL5PTL,$0000
  dc.w       BPL6PTH,$0000
  dc.w       BPL6PTL,$0000
; bitplane config
  dc.w       BPLCON0,(MmScreenBitPlanes<<12)|BplColorOn
  dc.w       BPLCON1,$0000
  dc.w       BPLCON2,$0000
  dc.w       BPL1MOD,MmScreenWidthBytes*(MmScreenBitPlanes-1)
  dc.w       BPL2MOD,MmScreenWidthBytes*(MmScreenBitPlanes-1)
  dc.w       DDFSTRT,(MmScreenStartX/2-DdfResolution)
  dc.w       DDFSTOP,(MmScreenStartX/2-DdfResolution)+(8*((MmScreenWidth/16)-1))
  dc.w       DIWSTRT,(MmScreenStartY<<8)|MmScreenStartX
  dc.w       DIWSTOP,((MmScreenStopY-256)<<8)|(MmScreenStopX-256)
; colors
  dc.w       COLOR00,$0000
  dc.w       COLOR01,$0000
  dc.w       COLOR02,$0000
  dc.w       COLOR03,$0000
  dc.w       COLOR04,$0000
  dc.w       COLOR05,$0000
  dc.w       COLOR06,$0000
  dc.w       COLOR07,$0000
  dc.w       COLOR08,$0000
  dc.w       COLOR09,$0000
  dc.w       COLOR10,$0000
  dc.w       COLOR11,$0000
  dc.w       COLOR12,$0000
  dc.w       COLOR13,$0000
  dc.w       COLOR14,$0000
  dc.w       COLOR15,$0000
  dc.w       COLOR16,$0000
  dc.w       COLOR17,$0000
  dc.w       COLOR18,$0000
  dc.w       COLOR19,$0000
  dc.w       COLOR20,$0000
  dc.w       COLOR21,$0000
  dc.w       COLOR22,$0000
  dc.w       COLOR23,$0000
  dc.w       COLOR24,$0000
  dc.w       COLOR25,$0000
  dc.w       COLOR26,$0000
  dc.w       COLOR27,$0000
  dc.w       COLOR28,$0000
  dc.w       COLOR29,$0000
  dc.w       COLOR30,$0000
  dc.w       COLOR31,$0000
; wait till raster beam is directly behind visible area
  dc.w       $ffdf,$fffe
  dc.w       $2bd1,$fffe
; trigger Copper-IRQ after all is shown => irq routine can safely modify copperlist for next frame
  dc.w       INTREQ,%1000000000010000
; end
  dc.w       $ffff,$fffe
