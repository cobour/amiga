  section       A100UnitTest , code

  macro         PRINT
  lea.l         \1(pc),a0
  move.l        a0,d2
  moveq.l       #0,d3
.count_loop\@:
  tst.b         (a0)+
  beq.s         .do_write\@
  addq.l        #1,d3
  bra.s         .count_loop\@
.do_write\@:
  move.l        output_handle(pc),d1
  move.l        dos_base(pc),a6
  jsr           Write(a6)
  endm

  macro         NEWLINE
  bra.s         .do_print\@
.char\@:
  dc.b          10,0
.do_print\@:
  move.l        output_handle(pc),d1
  lea.l         .char\@(pc),a0
  move.l        a0,d2
  moveq.l       #1,d3
  move.l        dos_base(pc),a6
  jsr           Write(a6)
  endm

;*****************************************************************************************************

main:
  bsr           init

  bsr           test_god___empty_playfield___1x1_brick___should_be_placable
  bsr           test_god___full_playfield___1x1_brick___should_not_be_placable
  bsr           test_god___filled_playfield___1x5_brick___should_be_placable

  NEWLINE
  bsr           cleanup
  moveq.l       #0,d0
  rts

;*****************************************************************************************************

  macro         ASSERT_C_D
  bra.s         .start\@
.failed\@:
  dc.b          10," => FAILED",10,0
  even
.passed\@:
  dc.b          10," => passed",10,0
  even
.start\@:
  cmp.l         #\1,\2
  beq.s         .0\@
  PRINT         .failed\@
  bra.s         .end\@
.0\@:
  PRINT         .passed\@
.end\@:
  endm

;*****************************************************************************************************

test_god___empty_playfield___1x1_brick___should_be_placable:

  PRINT         .name
.given:
  lea.l         .rawdata_brick(pc),a1
  lea.l         .playfield(pc),a2
  moveq.l       #1,d0
  moveq.l       #1,d1
  bra.s         .when
.playfield:
  dcb.b         100,0
.rawdata_brick:
  dc.w          2

.when:
  bsr           unittest_check_one_brick

.then:
  ASSERT_C_D    1,d2

  rts

.name:
  dc.b          10,"test_god___empty_playfield___1x1_brick___should_be_placable",0
  even

;*****************************************************************************************************

test_god___full_playfield___1x1_brick___should_not_be_placable:

  PRINT         .name
.given:
  lea.l         .rawdata_brick(pc),a1
  lea.l         .playfield(pc),a2
  moveq.l       #1,d0
  moveq.l       #1,d1
  bra.s         .when
.playfield:
  dcb.b         100,1
.rawdata_brick:
  dc.w          2

.when:
  bsr           unittest_check_one_brick

.then:
  ASSERT_C_D    0,d2

  rts

.name:
  dc.b          10,"test_god___full_playfield___1x1_brick___should_not_be_placable",0
  even

;*****************************************************************************************************

test_god___filled_playfield___1x5_brick___should_be_placable:

  PRINT         .name
.given:
  lea.l         .rawdata_brick(pc),a1
  lea.l         .playfield(pc),a2
  moveq.l       #1,d0
  moveq.l       #5,d1
  bra.s         .when
.playfield:
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,1,1,1,1,1
  dc.b          1,1,1,1,1,0,0,0,0,0
.rawdata_brick:
  dc.w          2,2,2,2,2

.when:
  bsr           unittest_check_one_brick

.then:
  ASSERT_C_D    1,d2

  rts

.name:
  dc.b          10,"test_god___filled_playfield___1x5_brick___should_be_placable",0
  even

;*****************************************************************************************************

; exec.library
OpenLibrary  equ -$198
CloseLibrary equ -$19e
; dos.library
Output       equ -$3c
Write        equ -$30

init:
  ; open dos.library
  move.l        4.w,a6
  lea.l         dos_name(pc),a1
  moveq.l       #0,d0
  jsr           OpenLibrary(a6)
  lea           dos_base(pc),a0
  move.l        d0,(a0)
  ; get output handle
  move.l        d0,a6
  jsr           Output(a6)
  lea.l         output_handle(pc),a0
  move.l        d0,(a0)
  ; end
  rts

cleanup:
  ; close dos.library
  move.l        4.w,a6
  move.l        dos_base(pc),a1
  jsr           CloseLibrary(a6)
  ; end
  rts

dos_name:
  dc.b          "dos.library",0
  even
dos_base:
  dc.l          0
output_handle:
  dc.l          0

;*****************************************************************************************************

  include       "../a100/src/ingame/game_over_detection.asm"
