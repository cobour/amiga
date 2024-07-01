  section    HydronCode , code

  include    "src/globals.i"

; DONE  all black at beginning
; DONE  allblack-copperlist in alloc'd chip mem
; DONE  allocmem
; DONE  demo-code (gfx) in asm under src
; DONE  loader-lib for function calls
; DONE  irq_take_system in module (add to loader_lib) => only one jump from loader to module
; DONE  ingame-copperlist in alloc'd chip mem + ingame chip mem struct (incl c_cm_*)
; DONE  refactor memory management
; DONE  refactor to use of disk.asm
; DONE  rename g_om_ to c_om_
; DONE  generate ADF from uae/dh0-folder (only include *.dat), delete uae/dh0_adf-folder
; DONE  DEBUG-profile: assembles executable to uae/dh0, runs from there, inserts disk in drive 1, reads all data from disk
; DONE  RELEASE-profile: does not assemble, runs from disk in drive 0, calls executable from bootblock, no hdd, add bootblock to ADF-generation
; DONE  Data-Tool: include guard for files_index.i
; DONE  Data-Tool: set equ with count of dat-files, so length of disk_dat_files can be set properly
; DONE  refactor disk.asm / disk_begin and disk_end with OpenDevice and CloseDevice / replace magic values with constants
; DONE  rename hydron_loader.asm to hydron.asm
; DONE  add ptplayer.asm and play mod
; DONE  remove old datatool
; DONE  NEW DATATOOL: write files_index.i before assembling source files => otherwise build errors in rs-structures
; DONE  NEW DATATOOL: check for unused setters/getters
; DONE  switch from system control back to loading files and then again back to system control // load sample(wav)
; DONE  lvl3 handler (+ copperlist issuer)
; DONE  move ig_cm_ + ig_om_ from globals.i to ingame.i
; DONE  when not enough memory, not just guru
; DONE  Data-Tool: optionally flatten iff source (all tiles in one row)
; DONE  Data-Tool: tmx sourcefile
; DONE  Data-Tool: each source must return its length in bytes
; DONE  Data-Tool: 4-char ID of each source file as reference
; DONE  Data-Tool: other-mem file knows related chip-mem file; info as metadata in yaml and in other-mem file (no metadata in chip-mem files, use ID's for reference)
; DONE  Data-Tool: no more index.i but data structures for metadata in other-mem files // index needed for dat-files count and codesize of asm files (and nice for filenames)
; DONE  rename in structs: ig_cm_datfile and ig_om_datfile to generic names (set rs.b 0) => nothing behind that point!!
; DONE  Data-Tool: second pass not necessary anymore, because metadata is in master file and include is mostly gone
; DONE  datafiles.asm: load other-mem file and related chip-mem file and unzip both of them
; DONE  Data-Tool: reactivate wav
; DONE  Data-Tool: reactivate tmx
; DONE  Data-Tool: extra category for uncompressed code-only files
; DONE  Data-Tool: convert these code files last (after files_index.i is written)
; DONE  Data-Tool: add uncompressed filesizes to files_index.i
; DONE  Data-Tool: optionally remove tiles from end of flattened iff file
; DONE  switch 512k/1m => redo exec_*_mem subroutines: let the caller set one or two registers as pointer to chip-/other-mem and then alloc/free chip or chip+other
; DONE  Data-Tool: IffSource new switch "colors-only"
;       Data-Tool: level as source // contains embedded tmx-file and iff-file (more later) => better: level references tmx, iff... via ID

main:

  ifd        DEBUG
  ; allocate mem
  moveq.l    #1,d0
  bsr        exec_alloc_mem
  tst.l      d0
  bne.s      .error
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  ; read file list from floppy drive
  move.l     other_mem_ptr(pc),a4
  bsr        disk_begin_io
  tst.l      d0
  bne.s      .error
  move.l     chip_mem_ptr(pc),a3                      ; TODO: inside framebuffer
  bsr        disk_read_file_list
  tst.l      d0
  bne.s      .error
  bsr        disk_end_io
  tst.l      d0
  bne.s      .error
  endif
  ifd        RELEASE
  ; bootblock allocated memory, pointers in a4 + a5
  ; bootblock already read file list from floppy drive
  lea.l      chip_mem_ptr(pc),a0
  move.l     a5,(a0)
  lea.l      other_mem_ptr(pc),a0
  move.l     a4,(a0)
  endif

  bsr        gfx_save_orig_system_state
  move.l     chip_mem_ptr(pc),a0
  lea.l      c_cm_all_black_copperlist(a0),a0
  bsr        gfx_set_black_screen

  move.l     other_mem_ptr(pc),a4
  move.l     chip_mem_ptr(pc),a5
  bsr        ig_start
  bsr        irq_free_system

  bsr        gfx_restore_screen

  ifd        DEBUG
  move.l     chip_mem_ptr(pc),d5
  move.l     other_mem_ptr(pc),d6
  bsr        exec_free_mem
  moveq.l    #0,d0
  rts
.error
  move.l     chip_mem_ptr(pc),d5
  move.l     other_mem_ptr(pc),d6
  bsr        exec_free_mem
  moveq.l    #1,d0
  rts
  endif
  ifd        RELEASE
  bsr        exec_reboot
  endif

chip_mem_ptr:
  dc.l       0
other_mem_ptr:
  dc.l       0

;
; Includes
;
  include    "files_index.i"
  include    "../common/src/system/exec.asm"
  include    "../common/src/system/datafiles.asm"
  include    "../common/src/system/disk.asm"
  include    "../common/src/system/gfx.asm"
  include    "../common/src/system/irq.asm"
  include    "src/ingame.asm"
  include    "../common/src/3rdparty/inflate.asm"
  include    "../common/src/3rdparty/ptplayer.asm"