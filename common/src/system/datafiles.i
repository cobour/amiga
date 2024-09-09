                         ifnd       DATAFILES_I
DATAFILES_I           equ 1

; SourceType enum
df_st_assembler       equ "ASM "
df_st_iff_ilbm        equ "IFF "
df_st_pt_module       equ "MOD "
df_st_sfx             equ "WAV "
df_st_tiled_playfield equ "TLDP"
df_st_iff_palette     equ "COLS"

; IndexEntry
                         rsreset
df_idx_id:               rs.l       1
df_idx_source_type       rs.l       1              ; see df_st_*
df_idx_ptr_rawdata:      rs.l       1
df_idx_metadata_sizeof:  rs.w       1
df_idx_metadata:         rs.b       0              ; depending on source type, see structs below
df_idx_header_sizeof:    rs.b       0

; IffSource metadata
                         rsreset
df_iff_width:            rs.w       1
df_iff_height:           rs.w       1
df_iff_rawsize:          rs.l       1
df_iff_bitplanes:        rs.b       1
df_iff_mask:             rs.b       1
df_iff_sizeof:           rs.b       0

; IffSource metadata - colorsOnly
                         rsreset
df_cols_count:           rs.w       1
df_cols_sizeof:          rs.b       0

; ModSource metadata
; - not necessary -

; WavSource metadata
; using this: ptplayer.asm sfx_*

; TiledSource playfield metadata
                         rsreset
df_tld_plf_width:        rs.w       1              ; number of tiles
df_tld_plf_height:       rs.w       1              ; number of tiles
df_tld_plf_tile_width:   rs.w       1              ; pixels of tile
df_tld_plf_tile_height:  rs.w       1              ; pixels of tile

                         endif                     ; ifnd DATAFILES_I
