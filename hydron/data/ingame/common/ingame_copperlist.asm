  include    "src/ingame.i"

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
; sprite 0+1 init
  dc.w       SPR0CTL, $0000
  dc.w       SPR0DATB,$0000
  dc.w       SPR1CTL, $0000
  dc.w       SPR1DATB,$0000
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
  dc.w       BPLCON0,(IgScreenBitPlanes<<12)|BplColorOn
  dc.w       BPLCON1,$0000
  dc.w       BPLCON2,%0000000000100100
  dc.w       BPL1MOD,IgScreenWidthBytes*(IgScreenBitPlanes-1)
  dc.w       BPL2MOD,IgScreenWidthBytes*(IgScreenBitPlanes-1)
  dc.w       DDFSTRT,(IgScreenStartX/2-DdfResolution)
  dc.w       DDFSTOP,(IgScreenStartX/2-DdfResolution)+(8*((IgScreenWidth/16)-1))
  dc.w       DIWSTRT,(IgScreenStartY<<8)|IgScreenStartX
  dc.w       DIWSTOP,((IgScreenStopY-256)<<8)|(IgScreenStopX-256)
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
; panel (sprite 0 and 1, manual mode)
  dc.w       $2c07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $2c47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $2d07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $2d47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $2e07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $2e47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $2f07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $2f47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3007,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3047,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3107,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3147,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3207,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3247,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3307,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3347,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3407,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3447,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3507,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3547,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3607,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3647,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3707,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3747,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3807,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3847,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3907,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3947,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3a07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3a47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3b07,$fffe
  dc.w       COLOR17,$0000
  dc.w       SPR0POS, $0050
  dc.w       SPR0DATA,$0000
  dc.w       $3b47,$fffe
  dc.w       SPR1POS, $0058
  dc.w       SPR1DATA,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       SPR1POS, $0084
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $008c
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $0094
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00b8
  dc.w       SPR0DATA,$0000
  dc.w       SPR1POS, $00c0
  dc.w       SPR1DATA,$0000
  dc.w       SPR0POS, $00c8
  dc.w       SPR0DATA,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one copper wait and 12 copper moves)
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

  dc.w       $3c07,$fffe
  dc.w       SPR0CTL, $0000                                                         ; spr0 off
  dc.w       SPR1CTL, $0000                                                         ; spr1 off

  ; reset color 17
  dc.w       COLOR17, $0000

; reuse sprites used in panel
  dc.w       SPR0PTH,$0000
  dc.w       SPR0PTL,$0000
  dc.w       SPR0POS,$0000
  dc.w       SPR0CTL,$0000
  dc.w       SPR1PTH,$0000
  dc.w       SPR1PTL,$0000
  dc.w       SPR1POS,$0000
  dc.w       SPR1CTL,$0000

  ; placeholder copper moves for re-setting the bitplane-pointers (will be one or two copper wait and 12 copper moves)
  ; in case two waits are necessary, the first wait of "wait till raster beam is directly behind visible area" wil be overwritten bith bitplane pointer move
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000
  dc.w       $01fe,$0000

; wait till raster beam is directly behind visible area
  dc.w       $ffdf,$fffe                                                            ; when above re-setting of bitplane pointers already has a $ffdffffe, then this wait is overwritten and needs to be replaced once it is no longer necessary above
  dc.w       $2bd1,$fffe

; trigger Copper-IRQ
  dc.w       INTREQ,%1000000000010000

; end
  dc.w       $ffff,$fffe
