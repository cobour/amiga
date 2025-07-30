
; FOR USE WITH USE_DISK_DMA
; currently not used

_entrypoint:

  lea.l      $dff180,a5
  clr.w      (a5)

; first of all check memory requirements

  ; do we have 512kb chip ram?
  move.w     #$1887,d0
  lea.l      $7fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  bne        error

  ; do we have 512kb fast ram?
  lea.l      $27fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  beq        .other_mem_found

  ; do we have 512kb slow ram?
  lea.l      $c7fffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  beq        .other_mem_found

  ; do we have another 512kb chip ram?
  lea.l      $ffffe,a0
  move.w     d0,(a0)
  move.w     (a0),d1
  cmp.w      d0,d1
  bne        error

.other_mem_found:
  sub.l      #$7fffe,a0                                          ; a0 -  beginning of other mem block of 512kb

; from now on we have:
;     512kb chip mem starting at $0 (511kb usable starting at $400)
;     512kb other mem (pointer in a0)

; set stack pointer to end of other mem
  move.l     a0,a1
  add.l      #$80000,a1
  move.l     a1,a7

; copy bootblock code to end of 256kb chip ram block
  move.l     #$40000,a1
  lea.l      _end+2(pc),a3
  lea.l      load_main_code(pc),a2
.copy_loop:
  move.w     -(a3),-(a1)
  cmp.l      a3,a2
  bne.s      .copy_loop
  jmp        (a1)                                                ; for bootblock execution
  ;bra.s      load_main_code                                      ; for debugging

error:
  move.w     #$f00,(a5)
  bra.s      error

; restart point after jmp (a1)
load_main_code:

  lea.l      $dff000,a6
  lea.l      $bfd000,a5
  lea.l      $bfe001,a4
  lea.l      $10000,a3
  lea.l      $18000,a2
  bsr.s      disk_dma_init

  ; load directory to disk_dma_files
  lea.l      _end(pc),a2
  bsr        disk_dma_read_directory

  ; get descriptor of main code file
  move.l     #MAIN_CODE_FILE,d0
  bsr        disk_dma_get_file_desc

  ; load main code file
  moveq.l    #0,d0
  moveq.l    #0,d1
  move.w     disk_dma_file_start_block(a2),d0
  move.w     disk_dma_file_num_blocks(a2),d1
  bsr        disk_dma_load

  bsr        disk_dma_cleanup

  ; execute main code
  ; main code can be sure that there is 
  ;    * 511kb of chip ram starting at $400
  ;    * (512kb - main code file size - some room for stack) of other ram starting directly behind main code
  jmp        (a0)

  include    "../../../common/src/system/disk_dma_intern.asm"

_end:
