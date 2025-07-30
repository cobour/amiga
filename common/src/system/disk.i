                               ifnd       DISK_I
DISK_I              equ 1

                               ifd        DEBUG
DiskDriveNum        equ 1
                               else
DiskDriveNum        equ 0
                               endif                                             ; ifd DEBUG

; file directory block (as written by data_tool)
RbBlocknumber       equ 2

; Message Port
MpNodeType          equ 8
MpPriority          equ 9
MpFlags             equ 14
MpSignalNumber      equ 15
MpSignalTask        equ 16
MpMessageList       equ 20
NodeTypeMessage     equ 4

; IO Standard Request
IoSrNodeType        equ 8
IoSrMessagePort     equ 14
IoSrCommand         equ 28
IoSrActual          equ 32
IoSrLength          equ 36
IoSrData            equ 40
IoSrOffset          equ 44
NodeTypeMessagePort equ 5

; IO Commands
IoCmdRead           equ 2
IoCmdWrite          equ 3
IoCmdUpdate         equ 4
IoCmdNonStandard    equ 9
IoCmdProtStatus     equ 15

; Exec
ExecBaseD           equ 4
DoIO                equ -456
OpenDevice          equ -444
CloseDevice         equ -450
AllocSignal         equ -330
FreeSignal          equ -336
FindTask            equ -294

; DOS
AccessRead          equ -2
ModeOldFile         equ 1005
ModeNewFile         equ 1006
Open                equ -$1e
Close               equ -$24
Read                equ -$2a
Write               equ -$30
Lock                equ -$54
UnLock              equ -$5a
CurrentDir          equ -$7e

; TRACKDISK
MaxFilesOnDisk      equ 50

; file directory block (as written by data_tool)
                               rsreset
disk_directory_diskname:       rs.l       1
disk_directory_filecount:      rs.w       1
disk_directory_sizeof:         rs.b       0

; file entry in directory block (as written by data_tool)
                               rsreset

disk_file_name:                rs.l       1
disk_file_start_block:         rs.w       1
disk_file_num_blocks:          rs.w       1
disk_file_size_in_last_block:  rs.w       1
disk_file_sizeof:              rs.b       0                                      ; SEE .read_file_list WHEN CHANGED

; main disk structure - needed for accessing files when USE_TRACKDISK
                               rsreset
disk_dat_files:                rs.l       (MaxFilesOnDisk+1)*disk_file_sizeof    ; per ".dat"-file 8 bytes (4 bytes name before dot, 4 bytes number of first data block)
disk_message_port:             rs.b       34
disk_io_std_req:               rs.b       48
disk_sizeof:                   rs.b       0                                      ; size after scanning for dat-files is completed
disk_file_header_blocks:       rs.l       73                                     ; 72 possible plus NULL indicating end-of-list
disk_while_scanning_sizeof:    rs.b       0                                      ; size before/while scanning for dat-files

                               endif                                             ; ifnd DISK_I
