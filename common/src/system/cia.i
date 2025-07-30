  ifnd     CIA_I
CIA_I     equ 1

; CIA registers
CIAA      equ $bfe001
CIAB      equ $bfd000
CIAPRA    equ $000
CIAPRB    equ $100
CIADDRA   equ $200
CIADDRB   equ $300
CIATALO   equ $400
CIATAHI   equ $500
CIATBLO   equ $600
CIATBHI   equ $700
CIATODLO  equ $800
CIATODMID equ $900
CIATODHI  equ $a00
CIASDR    equ $c00
CIAICR    equ $d00
CIACRA    equ $e00
CIACRB    equ $f00

  endif             ; ifnd CIA_I