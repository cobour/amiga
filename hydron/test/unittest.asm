  section       HydronUnitTest , code

;*****************************************************************************************************
; console macros

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

  macro         CLEAR
  bra.s         .do_print\@
.char\@:
  dc.b          12,0
.do_print\@:
  move.l        output_handle(pc),d1
  lea.l         .char\@(pc),a0
  move.l        a0,d2
  moveq.l       #1,d3
  move.l        dos_base(pc),a6
  jsr           Write(a6)
  endm

  macro         WAIT
  bra.s         .do_wait\@
.buffer\@:
  dc.b          0,0
.do_wait\@:
  move.l        output_handle(pc),d1
  lea.l         .buffer\@(pc),a0
  move.l        a0,d2
  moveq.l       #1,d3
  move.l        dos_base(pc),a6
  jsr           Read(a6)
  endm

;*****************************************************************************************************
; assertion macros

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
; test suite

main:
  bsr           init
  CLEAR

  bsr           test_cd_enemy_bullet___line_25_75_to_45_85___should_be_a_hit
  bsr           test_cd_enemy_bullet___line_66_114_to_84_128___should_be_no_hit
  bsr           test_cd_enemy_bullet___line_47_76_to_65_86___should_be_a_hit
  bsr           test_cd_enemy_bullet___line_67_109_to_50_119___should_be_no_hit
  bsr           test_cd_enemy_bullet___line_25_105_to_45_115___should_be_a_hit
  WAIT
  CLEAR
  bsr           test_cd_enemy_bullet___line_25_110_to_45_120___should_be_no_hit
  bsr           test_cd_enemy_bullet___line_5_80_to_25_90___should_be_no_hit

  NEWLINE
  bsr           cleanup
  moveq.l       #0,d0
  rts

;*****************************************************************************************************
; unit tests

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_25_75_to_45_85___should_be_a_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          25,75,45,85,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    1,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_25_75_to_45_85___should_be_a_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_66_114_to_84_128___should_be_no_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          66,114,84,128,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    0,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_66_114_to_84_128___should_be_no_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_47_76_to_65_86___should_be_a_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          47,76,65,86,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    1,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_47_76_to_65_86___should_be_a_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_67_109_to_50_119___should_be_no_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          67,109,50,119,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    0,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_67_109_to_50_119___should_be_no_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_25_105_to_45_115___should_be_a_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          25,105,45,115,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    1,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_25_105_to_45_115___should_be_a_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_25_110_to_45_120___should_be_no_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          25,110,45,120,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    0,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_25_110_to_45_120___should_be_no_hit",0
  even

;-----------------------------------------------------------------------------------------------------
test_cd_enemy_bullet___line_5_80_to_25_90___should_be_no_hit:

  PRINT         .name
.given:
  move.w        .counter(pc),d7
  lea.l         .enemy_bbox(pc),a1
  lea.l         .lines(pc),a2
  bra.s         .when
.enemy_bbox:
  dc.w          30,80,60,110
.lines:
  dc.w          5,80,25,90,0,0
.counter:
  dc.w          0

.when:
  bsr           coll_check_one_enemy

.then:
  ASSERT_C_D    0,d0

  rts

.name:
  dc.b          10,"test_cd_enemy_bullet___line_5_80_to_25_90___should_be_no_hit",0
  even

;*****************************************************************************************************
; code includes

  include       "../src/ingame/collisions.asm"

;*****************************************************************************************************
; init and cleanup

; exec.library
OpenLibrary  equ -$198
CloseLibrary equ -$19e
; dos.library
Output       equ -$3c
; Read         equ -$2a ; already defined in disk.i
; Write        equ -$30 ; already defined in disk.i

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
