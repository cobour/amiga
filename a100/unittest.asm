  section       A100UnitTest , code

;*****************************************************************************************************

main:
  bsr           test_god___empty_playfield___1x1_brick___should_be_placable
  bsr           test_god___full_playfield___1x1_brick___should_not_be_placable
  bsr           test_god___filled_playfield___1x5_brick___should_be_placable
  moveq.l       #0,d0
  rts

;*****************************************************************************************************

  macro         ASSERT_C_D
  cmp.l         #\1,\2
  beq.s         .0
  divu          #0,d0
.0:
  endm

;*****************************************************************************************************

test_god___empty_playfield___1x1_brick___should_be_placable:

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

;*****************************************************************************************************

test_god___full_playfield___1x1_brick___should_not_be_placable:

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

;*****************************************************************************************************

test_god___filled_playfield___1x5_brick___should_be_placable:

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

;*****************************************************************************************************

  include       "../a100/src/ingame/game_over_detection.asm"
