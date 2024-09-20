  ifnd       BRICKS_ASM
BRICKS_ASM             equ 1

BRICKS_ARRAY_SIZE      equ 32
BRICKS_ARRAY_SIZE_MASK equ $1f          ; mask for BRICKS_ARRAY_SIZE fragment

bricks_init:

  bsr        .init_randomizer

; read index pointers of all bricks
.init_brick_pointers:

  move.l     #"B01 ",d1
  move.l     d1,d2
  moveq.l    #0,d3
  move.l     #$100,d4
  move.l     #$10000,d5
  lea.l      brick_pointers(pc),a1
  moveq.l    #BRICKS_ARRAY_SIZE-1,d7

.ibp_loop:

  ; lookup big brick
  move.l     d1,d0
  move.b     #"B",d0
  bsr        datafiles_get_pointer
  cmp.l      d3,a0
  bne.s      .ibp_loop_found
  ; not found - reset to first brick
  move.l     d2,d1
  bra.s      .ibp_loop
.ibp_loop_found:

  ; lookup small brick - must exist when corresponding big brick exists
  move.l     a0,(a1)+
  move.l     d1,d0
  move.b     #"S",d0
  bsr        datafiles_get_pointer
  move.l     a0,(a1)+

  ; next iteration
  add.l      d4,d1
  cmp.w      #": ",d1                   ; ascii sign after '9'
  bne.s      .ibp_loop_next
  move.w     #"0 ",d1
  add.l      d5,d1
.ibp_loop_next:
  dbf        d7,.ibp_loop

  rts

.init_randomizer:
; generate two "random" seed numbers in d5 and d6
  move.l     #$deadbeef,d5
  move.l     #$12345678,d6
  move.w     VHPOSR(a6),d7
.ir_loop:
  swap       d5
  add.l      d6,d5
  add.l      d5,d6
  dbf        d7,.ir_loop

  ; store numbers
  lea.l      random(pc),a0
  move.l     d5,(a0)+
  move.l     d6,(a0)

  rts

;
; vars section
;

random:
  dcb.l      2

brick_pointers: ; two longs for one brick (first big, second small) - for up to BRICKS_ARRAY_SIZE bricks with repeating bricks (for easier randomized lookup)
  dcb.l      BRICKS_ARRAY_SIZE*2

  endif                                 ; ifnd BRICKS_ASM
