                                   ifnd       DISK_DMA_INTERN_I
DISK_DMA_INTERN_I equ 1

                                   ifnd       DISK_DMA_DRIVE
DISK_DMA_DRIVE    equ 4                                                  ; default to df1 when not defined elsewhere
                                   endif

MFM_SYNC_WORD     equ $4489

                                   rsreset

disk_dma_file_name:                rs.l       1
disk_dma_file_start_block:         rs.w       1
disk_dma_file_num_blocks:          rs.w       1
disk_dma_file_size_in_last_block:  rs.w       1
disk_dma_file_sizeof:              rs.b       0

                                   rsreset

disk_dma_buffer:                   rs.l       1
;disk_dma_old_intena:               rs.w       1
;disk_dma_old_intreq:               rs.w       1
;disk_dma_old_dmacon:               rs.w       1
disk_dma_old_ciab_cra:             rs.b       1
;disk_dma_old_adkcon:               rs.b       1
disk_dma_position:                 rs.b       1
disk_dma_direction:                rs.b       1
disk_dma_start_track:              rs.b       1
disk_dma_start_sector:             rs.b       1
disk_dma_track:                    rs.b       1
disk_dma_end_sector:               rs.b       1
disk_dma_dummy:                    rs.b       1
disk_dma_files:                    rs.b       disk_dma_file_sizeof*51    ; 51 = (512-6)/disk_dma_file_sizeof + 1 for null long
disk_dma_sizeof:                   rs.b       0

                                   endif                                 ; ifnd DISK_DMA_INTERN_I
