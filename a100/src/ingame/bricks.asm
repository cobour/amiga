  ifnd       BRICKS_ASM
BRICKS_ASM             equ 1

BRICKS_ARRAY_SIZE      equ 32
BRICKS_ARRAY_SIZE_MASK equ $1f             ; mask for BRICKS_ARRAY_SIZE fragment

b_init:

  bsr        .init_randomizer

; read index pointers of all bricks
.init_brick_pointers:

  move.l     #"B01 ",d1
  move.l     d1,d2
  moveq.l    #0,d3
  move.l     #$100,d4
  move.l     #$10000,d5
  lea.l      b_brick_pointers(pc),a1
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
  cmp.w      #": ",d1                      ; ascii sign after '9'
  bne.s      .ibp_loop_next
  move.w     #"0 ",d1
  add.l      d5,d1
.ibp_loop_next:
  dbf        d7,.ibp_loop

  rts

.init_randomizer:
; generate two "random" seed numbers in d0 and d1

  move.l     $4.w,a0
  move.l     280(a0),d7                    ; exec IdleCount
  move.l     #$deadbeef,d0
  move.l     #$12345678,d1
  add.w      c_om_framecounter+2(a4),d7
  and.w      #$1ff,d7
.ir_loop:
  swap       d0
  add.l      d1,d0
  add.l      d0,d1
  dbf        d7,.ir_loop

  ; store numbers
  lea.l      b_random(pc),a0
  move.l     d0,(a0)+
  move.l     d1,(a0)

  rts

; get specific brick
; in:
;   d1 - ID of big brick
; out:
;   d2 - pointer to big brick struct
;   d3 - pointer to corresponding small brick struct
b_get_brick:
  movem.l    d0/a0,-(sp)
  move.l     d1,d0
  bsr        datafiles_get_pointer
  move.l     a0,d2
  move.b     #"S",d0
  bsr        datafiles_get_pointer
  move.l     a0,d3  
  movem.l    (sp)+,d0/a0
  rts

; get new random brick
; out:
;    a0 - pointer to big and small brick index pointers
b_get_random_brick:
  movem.l    d0-d2/d7,-(sp)

; get new random number in d2
  lea.l      b_random(pc),a0
  move.l     (a0),d0
  move.l     4(a0),d1
  move.l     c_om_framecounter(a4),d7
  add.w      VHPOSR(a6),d7
  and.w      #$f,d7
.grb_loop
  swap       d0
  add.l      d1,d0
  add.l      d0,d1
  dbf        d7,.grb_loop

  move.w     VHPOSR(a6),d2
  btst       #0,d2
  bne.s      .grb_other
  move.l     d0,d2
  bra.s      .grb_store_values
.grb_other:
  move.l     d1,d2

.grb_store_values:
  move.l     d0,(a0)
  move.l     d1,4(a0)

  and.l      #BRICKS_ARRAY_SIZE_MASK,d2
  lsl.l      #3,d2

  lea.l      b_brick_pointers(pc),a0
  add.l      d2,a0
 
  movem.l    (sp)+,d0-d2/d7
  rts

;
; vars section
;

b_random:
  dcb.l      2

b_brick_pointers: ; two longs for one brick (first big, second small) - for up to BRICKS_ARRAY_SIZE bricks with repeating bricks (for easier randomized lookup)
  dcb.l      BRICKS_ARRAY_SIZE*2

  endif                                    ; ifnd BRICKS_ASM
