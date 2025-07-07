                             ifnd       DISK_I
DISK_I                          equ 1

                             ifd        DEBUG
DiskDriveNum                    equ 1
                             else
DiskDriveNum                    equ 0
                             endif                ; ifd DEBUG

; DOS Rootblock
RbBlocknumber                   equ 880
RbHashTableFileHeaderBlocks     equ 24
RbHashTableFileHeaderBlocksSize equ 72

; DOS FileHeaderBlock
FhbFilenameLength               equ 432
FhbFilename                     equ 433
FhbFirstDataBlock               equ 16
FhbHashChain                    equ 496

; DOS FileDataBlock
FdbDataSize                     equ 12
FdbNextDataBlock                equ 16
FdbData                         equ 24

; Message Port
MpNodeType                      equ 8
MpPriority                      equ 9
MpFlags                         equ 14
MpSignalNumber                  equ 15
MpSignalTask                    equ 16
MpMessageList                   equ 20
NodeTypeMessage                 equ 4

; IO Standard Request
IoSrNodeType                    equ 8
IoSrMessagePort                 equ 14
IoSrCommand                     equ 28
IoSrActual                      equ 32
IoSrLength                      equ 36
IoSrData                        equ 40
IoSrOffset                      equ 44
NodeTypeMessagePort             equ 5

; IO Commands
IoCmdRead                       equ 2
IoCmdWrite                      equ 3
IoCmdUpdate                     equ 4
IoCmdNonStandard                equ 9
IoCmdProtStatus                 equ 15

; Exec
ExecBaseD                       equ 4
DoIO                            equ -456
OpenDevice                      equ -444
CloseDevice                     equ -450
AllocSignal                     equ -330
FreeSignal                      equ -336
FindTask                        equ -294

; DOS
AccessRead                      equ -2
ModeOldFile                     equ 1005
ModeNewFile                     equ 1006
Open                            equ -$1e
Close                           equ -$24
Read                            equ -$2a
Write                           equ -$30
Lock                            equ -$54
UnLock                          equ -$5a
CurrentDir                      equ -$7e

; main disk structure - needed for accessing files when using trackdisk-device - USE_TRACKDISK
                             rsreset
disk_dat_files:              rs.l       72*8      ; per ".dat"-file 8 bytes (4 bytes name before dot, 4 bytes number of first data block)
disk_message_port:           rs.b       34
disk_io_std_req:             rs.b       48
disk_sizeof:                 rs.b       0         ; size after scanning for dat-files is completed
disk_file_header_blocks:     rs.l       73        ; 72 possible plus NULL indicating end-of-list
disk_while_scanning_sizeof:  rs.b       0         ; size before/while scanning for dat-files

                             endif                ; ifnd DISK_I
