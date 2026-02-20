  ifnd       DISK_DIRECT_ASM
DISK_DIRECT_ASM equ 1

  ifnd       DISK_DRIVE_BIT
DISK_DRIVE_BIT  equ 4                        ; default to df1
  endif

; TODOs
; DONE  read-subroutine that takes start-block and blockcount as parameters
; DONE  add buffer (13000 bytes) as parameter
; DONE  split into loader.asm and disk_direct.asm (complete init code with mem etc. from Hydron)
; DONE  API calls are "dd_init", "dd_cleanup" and "dd_load_file" => rest as inner-labels oder INTERNAL-labels
; DONE  drive as parameter for dd_init
; DONE  drive as parameter for move.b commands (no branching in dd_init and dd_cleanup)
; DONE  optimize long addresses (BFD100, DFFxxx)
;       refactor
;           constants cia.i and custom.i
;           A0 -> a0
;           renames (labels)
;       use CIA timer for delay

; inits disk-direct module
; in:
;   d0 - drive (3 = df0, 4 = df1 ...)
dd_init:
  movem.l    d1/a0,-(sp)
  lea.l      drive(pc),a0
  move.w     d0,(a0)
  lea.l      $bfd100,a0
  move.b     #%01111111,d1
  move.b     d1,(a0)
  nop
  nop
  bclr       d0,d1
  move.b     d1,(a0)
  nop
  nop
  movem.l    (sp)+,d1/a0
.wait_ready:
  btst       #5,$00BFE001
  bne.s      .wait_ready
  rts

; does cleanup
; field "drive" must have been set before calling
dd_cleanup:
  movem.l    d0-d1/a0,-(sp)
  move.w     drive(pc),d0
  move.b     #%11111111,d1
  lea.l      $bfd100,a0
  move.b     d1,(a0)
  nop
  nop
  bclr       d0,d1
  move.b     d1,(a0)
  movem.l    (sp)+,d0-d1/a0
  rts

; loads file
; in:
;   a0   - target pointer
;   a1   - buffer (13000 bytes of chip ram)
;   d0.w - first block
;   d1.w - number of blocks
dd_load_file:
  movem.l    d0-a6,-(sp)

  move.l     a1,a4                           ; save trackbuffer for all subroutines
  lea.l      $bfd100,a5                      ; set bfd100 for all subroutines
  lea.l      $dff000,a6                      ; set dff000 for all subroutines

  moveq.l    #0,d7
  move.w     d0,d7
  divu       #11,d7                          ; low-word: ergebnis, high-word: rest
  move.w     d7,d2                           ; track
  swap       d7                              ; block offset inside track
.load_file_loop:
  moveq.l    #11,d4
  cmp.w      d4,d1
  bge.s      .more_blocks_to_read
  move.w     d1,d4
  bra.s      .last_track
.more_blocks_to_read:
  sub.w      d7,d4                           ; num of blocks to read from track
.last_track:
  move.w     d2,d6
  bsr        .seek_track                
  move.w     d4,d0
  move.w     d7,d5
  bsr        .read_sektoren
  ; inc target pointer
  moveq.l    #0,d3
  move.w     d4,d3
  mulu       #512,d3
  add.l      d3,a0
  ; next iteration
  addq.w     #1,d2                           ; next track
  moveq.l    #0,d7                           ; start at block zero in next track
  sub.l      d4,d1                           ; less blocks to read
  bgt.s      .load_file_loop                 ; still blocks to read?
  ; all is read
  movem.l    (sp)+,d0-a6
  moveq.l    #0,d0
  rts

;Liest ab Startsektor Sektoren ein. Gibt in D5 512*n zurück.
;-> D0: Anzahl der Sektoren
;   D5: Startsektor
;   A0: Ladeadresse
.read_sektoren:  
  movem.l    D0-D4/D6-A6,-(SP)
  move.w     D0,-(SP)                        ;Anzahl retten
.read_error:     
  bsr.s      .read_track                     ;Track lesen
  move.w     (SP),D0                         ;Anzahl holen
  move.w     D5,D7                           ;Aktueller Sektor
  bra.s      .ss_dbra
.sektor_trans:   
  tst.l      (A1)                            ;Wurde überhaupt was geladen?
  beq.s      .lesefehler
  move.w     track(PC),D1
  cmp.b      1(A1),D1                        ;Richtiger Track?
  bne.s      .lesefehler
  cmp.b      2(A1),D7                        ;Sektor gefunden?
  bne.s      .nxt_sektor3
  moveq      #127,D6
  addq.l     #4,A1                           ;Miniheader überspringen
.ttz:       
  move.l     (A1)+,(A0)+                     ;eintragen
  dbra       D6,.ttz
  addq.w     #1,D7                           ;nächster Sektor
.ss_dbra: 
  move.l     a4,A1
  dbf        D0,.sektor_trans

  move.w     (SP)+,D0
  move.w     D0,D5
  mulu       #512,D5                         ;Soviel Bytes wurden gelesen
  movem.l    (SP)+,D0-D4/D6-A6
  rts

.nxt_sektor3:
  lea        512+4(A1),A1
  bra.s      .sektor_trans

.lesefehler:
  move.w     track(PC),-(SP)                 ;gewünschter Track
  moveq      #0,D6
  bsr        .seek_track                     ;Restore ausführen
  move.w     (SP)+,D6
  bsr        .seek_track                     ;und nochmal anfahren
  bra.s      .read_error


;Liest einen Track von Diskette ein und dekodiert ihn.
.read_track: 
  movem.l    D0-A6,-(SP)

  move.l     a4,A0                           ;hier hin lesen

  move.w     #%1000001000010000,$0096(a6)    ;Disk DMA an
  move.w     #%0111111100000000,$009E(a6)    ;alle Bits aus
  move.w     #%1001010100000000,$009E(a6)    ;MFM+Sync
  move.w     #$4489,$007E(a6)                ;Sync-Wert
  move.w     #$4489,(A0)+                    ;1. Sync eintragen
  move.w     #$4000,$0024(a6)                ;Disk-DMA aus
  move.l     A0,$0020(a6)                    ;DMA-Adresse
  bsr        .wait_ready
  move.w     #12980,D0                       ;Anzahl Bytes
  lsr.w      #1,D0
  ori.w      #$8000,D0                       ;DMA lesen
  move.w     D0,$0024(a6)
  move.w     D0,$0024(a6)
  bsr        .wait_dma

  subq.l     #2,A0                           ;Bufferadresse
  bsr.s      .decode_track

  movem.l    (SP)+,D0-A6
  rts


;Diese Routine decodiert einen Track.
;-> A0.L: Adresse des Tracks
.decode_track: 
  movem.l    D0-A6,-(SP)

  movea.l    A0,A1                           ;hier wieder hin

  lea        12800(A0),A3                    ;Ende des Buffers
  move.l     #$55555555,D2                   ;zum MFM dekodieren

.such_sektor:  
  cmpi.w     #$4489,(A0)                     ;Sync?
  bne.s      .no_sync
.weitere_sync: 
  cmpi.w     #$4489,2(A0)                    ;2. Sync?
  bne.s      .keine_zweite
  addq.l     #2,A0                           ;Eine Sync weitergehen
  bra.s      .weitere_sync
.keine_zweite:  
  cmpi.b     #$55,2(A0)                      ;$FF (Format-Mark)?
  bne.s      .no_sync
  cmpi.b     #$55,6(A0)                      ;2. Mark?
  bne.s      .no_sync

  move.l     2(A0),D0
  move.l     6(A0),D1
  and.l      D2,D0
  and.l      D2,D1
  add.l      D0,D0
  or.l       D1,D0
  move.l     D0,(A1)                         ;Buffer Mark merken

  lea        2(A0),A2                        ;Sync nicht CRC
  moveq      #40,D0                          ;40 Bytes
  bsr.s      .calc_crc

  move.l     42(A0),D1
  move.l     46(A0),D3
  and.l      D2,D1
  and.l      D2,D3
  add.l      D1,D1
  or.l       D3,D1
  cmp.l      D1,D0                           ;CRC korrekt?
  bne.s      .crc_error

  lea        58(A0),A2                       ;Datenbuffer
  move.w     #1024,D0
  bsr.s      .calc_crc

  move.l     50(A0),D1
  move.l     54(A0),D3
  and.l      D2,D1
  and.l      D2,D3
  add.l      D1,D1
  or.l       D3,D1
  cmp.l      D1,D0                           ;CRC korrekt?
  bne.s      .crc_error

  lea        58(A0),A2                       ;Datenbuffer
  addq.l     #4,A1                           ;Header Ok
  bsr.s      .decode_sektor

.crc_error:
.no_sync:     
  addq.l     #2,A0                           ;nächstes Wort
  cmpa.l     A3,A0
  blt.s      .such_sektor

  clr.l      (A1)                            ;Ende der Sektoren

  movem.l    (SP)+,D0-A6
  rts

;Diese Routine berechnet eine Prüfsumme über den angegebenen Bereich
;-> A2.L: Adresse des Bereichs (wird NICHT erhöht)
;   D0.L: Länge in Bytes
.calc_crc:    
  movem.l    D1-A6,-(SP)

  move.w     D0,D1
  lsr.w      #2,D1                           ;Langworte
  subq.w     #1,D1
  moveq      #0,D0
.crc_loop:   
  move.l     (A2)+,D2
  eor.l      D2,D0
  dbf        D1,.crc_loop

  andi.l     #$55555555,D0                   ;Taktbits raus

  movem.l    (SP)+,D1-A6
  rts

;Diese Routine dekodiert einen Sektor von A0 nach A1.
;-> A2.L: Quelle
;   A1.L: Ziel (wird erhöht)
.decode_sektor: 
  movem.l    D0-A0/A2-A6,-(SP)

  moveq      #127,D7                         ;256 Langworte
  move.l     #$55555555,D2
.dat_loop:     
  move.l     (A2)+,D0
  move.l     508(A2),D1
  and.l      D2,D1
  and.l      D2,D0
  add.l      D0,D0
  or.l       D1,D0
  move.l     D0,(A1)+
  dbf        D7,.dat_loop

  movem.l    (SP)+,D0-A0/A2-A6
  rts

;Routine fährt einen bestimmten Track an und selektiert entspr. Seite
;-> D6.W: gewünschter Track
.seek_track:   
  move.w     track(PC),D0                    ;Ist dies der 1. Aufruf?
  bpl.s      .seek                           ;Nein, direkt anfahren

  move.l     D6,-(SP)                        ;gewünschter Track merken
  moveq      #0,D6
  bsr.s      .seek                           ;zuerst Restore
  move.l     (SP)+,D6


;Fährt Track an
;-> D6.W: Track
.seek:     
  movem.l    D0-A6,-(SP)

  move.w     track(PC),D7                    ;aktueller Track
  lsr.w      #1,D7                           ;tatsächliche Tracknummer
  lsr.w      #1,D6                           ;gewünschter Track
  bcs.s      .untere_seite
  bset       #2,(a5)                         ;Obere Seite
  bra.s      .seeken
.untere_seite:  
  bclr       #2,(a5)

.seeken:     
  tst.w      D6                              ;Track 0?
  beq.s      .restore

.seek_loop:  
  cmp.w      D7,D6                           ;Sind wir schon auf Track?
  beq.s      .seek_end
  bgt.s      .nach_innen
  bsr.s      .aussen
  subq.w     #1,D7
  bra.s      .seek_loop
.nach_innen: 
  bsr.s      .innen
  addq.w     #1,D7
  bra.s      .seek_loop

.restore:     
  btst       #4,$bfe001                      ;Kopf auf Spur 0?
  beq.s      .seek_end
  bsr.s      .aussen
  bra.s      .restore

.seek_end:    
  movem.l    (SP)+,D0-A6
  lea        track(PC),A2
  move.w     D6,(A2)                         ;angekommen
  rts

;Bewegt Kopf auf Track 80 zu:
.innen:   
  movem.l    D0-A6,-(SP)
  bsr        .wait_ready
  bclr       #1,(a5)
  bclr       #0,(a5)
  bset       #0,(a5)
  bsr.s      .minipause
  bsr.s      .wait_ready
  movem.l    (SP)+,D0-A6
  rts

;Bewegt Kopf auf Track 0 zu:
.aussen:   
  movem.l    D0-A6,-(SP)
  bsr.s      .wait_ready
  bset       #1,(a5)
  bclr       #0,(a5)
  bset       #0,(a5)
  bsr.s      .minipause
  bsr.s      .wait_ready
  movem.l    (SP)+,D0-A6
  rts

.minipause:   
  move.w     #$2000,D7
.mini2:        
  tst.w      $4(a6)                          ;Zeit verzögern
  dbf        D7,.mini2
  rts


;Diese Routine wartet auf das Ende einer DMA-Floppyaktion
;<- D0.W: 0=Kein Timeout, -1=Timeout
.wait_dma:     
  movem.l    D1-A6,-(SP)

  move.l     #$00020000,D0
  move.w     #$0002,$9C(a6)
.wait_loop:   
  btst       #1,$1E+1(a6)
  bne.s      .fertig_hiller
  subq.l     #1,D0
  bne.s      .wait_loop

.fertig_hiller: 
  move.w     #$0000,$24(a6)                  ;DMA ausschalten
  movem.l    (SP)+,D1-A6
  rts

;Wartet auf die Ausführung eines normalen Diskbefehls:
.wait_ready:  
  btst       #5,$bfe001
  bne.s      .wait_ready
  rts


track:        
  dc.w       -1
drive:       
  dc.w       -1                              ; 3 = df0, 4 = df1 ...

  endif                                      ; ifnd DISK_DIRECT_ASM