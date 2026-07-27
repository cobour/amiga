                         ifnd       DATAFILES_I
DATAFILES_I           equ 1

; SourceType enum
df_st_assembler       equ "ASM "
df_st_iff_ilbm        equ "IFF "
df_st_pt_module       equ "MOD "
df_st_sfx             equ "WAV "
df_st_tiled_playfield equ "TLDP"
df_st_iff_palette     equ "COLS"
df_st_svg_path        equ "SVGP"

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

; TiledSource enemy spawn info metadata
                         rsreset
df_tld_enm_enemytype:    rs.l       1              ; enemytype to spawn (should be overwritten with pointer to enemytype-struct during init)
df_tld_enm_xpos:         rs.l       1              ; spawn xpos in screen-coordinates as fixed-point value
df_tld_enm_ypos:         rs.l       1              ; spawn ypos in screen-coordinates as fixed-point value
df_tld_enm_level_ypos:   rs.l       1              ; ypos of level in level-coordinates that triggers the spawn
df_tld_enm_movement:     rs.l       1              ; id of movement, must e replaced with pointer to actual movement data in memory
df_tld_enm_sizeof:       rs.b       0

; TiledSource metadata
                         rsreset
df_tld_plf_width:        rs.w       1              ; number of tiles
df_tld_plf_height:       rs.w       1              ; number of tiles
df_tld_plf_tile_width:   rs.w       1              ; pixels of tile
df_tld_plf_tile_height:  rs.w       1              ; pixels of tile
df_tld_plf_rawsize:      rs.l       1              ; size of playfield data in bytes
df_tld_enm_rawsize:      rs.l       1              ; size of enemy spawn info (= number of enemy spawn entries * df_tld_enm_sizeof) in bytes

; SvgPathSource metadata
                         rsreset
df_svgp_steps:           rs.w       1              ; number of steps
df_svgp_size:            rs.l       1              ; size of step table in bytes

; SvgPathSource rawdata per step
                         rsreset
df_svgp_step_xpos_add:   rs.l       1              ; add to xpos
df_svgp_step_ypos_add:   rs.l       1              ; add to ypos
df_svgp_step_direction:  rs.w       1              ; direction number (0 = right, incrementing counter-clockwise)
df_svgp_step_sizeof:     rs.b       0

                         endif                     ; ifnd DATAFILES_I
