# Use of hardware sprites

Due to DMA bandwith limitations not all 8 hardware sprites can be used when using full screen width of 320 pixels. So we use just a 256 pixels wide screen and therefore can utilise all hardware sprites.

The sprites will be attached giving 4 sprites with 16 colors. Since this is a limitation for each row, sprites can be reused when the intended image part do not overlap vertically.

![ingame sketch-alt](hydron-ingame-sketch-alt.png)

## Score/lives panel

I will try to use the Hybris-trick with two not attached hardware sprites (should be sprites 0 and 1 because they are on top of the other ones). For the text the colors 17-19 will be usable (color registers counted from 0 to 31). 

Color 16 is transparent for sprites 0 and 1 (and transparent to all attached 16-color sprites).
If I cannot accomplish to recreate the sprite-trick we have to use a separated panel of 16 pixels height and 256 pixels width built with normal bitmaps.

## Player sprite

The spaceship of the player is built by 4 hardware sprites, attached to two 16 pixels wide 16-color sprites giving a total width of 32 pixels. Optionally depending of the actual weapon of the player there may be two guns attached to the left and right of the spaceship, each using two attached sprites of 16 pixels width and 16 colors.

Player movement is restricted so the spaceship always stays below the panel, so the sprites cannot interfere when using the guns attached to the spaceship.

![ingame sketch](hydron-ingame-sketch.png)

## Playershot sprites

Built of two attached sprites resulting in 16 pixels width and unlimited height. There can be up to 4 shots at each row.

All playershots are drawn only above the playersprite initially and because shots always move faster as the player himself they cannot interfere.

# Usage of color palette

| Color   | Usage                                                                                       |
| ------- | ------------------------------------------------------------------------------------------- |
| 00      | always black and transparent                                                                |
| 01-15   | usable for backgrounds, enemies, enemyshots ; may change each level for unique color design |
| 16      | transparent color for attached hardware sprites and sprite 0 and 1 for panel. usable for backgrounds, enemies, enemyshots ; may change each level for unique color design |
| 17-19   | for panel sprites and for player and playershots ; may NOT change each level                |
| 20-31   | for player and playershots sprites ; may NOT change each level                              |
| 32      | EHB pseudo color  ; always black and solid                                                  |
| 33-48   | EHB pseudo colors ; automatically changed each level by "master-colors" 01-16               |
| 49-63   | EHB pseudo colors ; automatically set by "master-colors" 17-31 ; stay the same each level   |

![palette usage](HYDRON_Usage-of-color-palette.png)

# Backgrounds

The backgrounds will be built of 16x16 pixels blocks and put together with Tiled. May use full color palette (00-63) giving massive options for design.

Maybe use mainly the EHB pseudo colors (colors 32-63) for background blocks to create a dark environment.

# Blitter objects for enemies, enemyshots and upgrades

Enemies and enemyshots are drawn as blitter objects (aka bobs). So they may use the full palette (00-63) when used for a single level exclusively. Optionally use colors 17-32 and 49-63 only for reusing in multiple levels (maybe for enemyshots).

Upgrades may use colors 17-32 and 49-63 only because they will appear in all levels.

# Basic concept for enemies

I have a flexible system in mind that makes it possible to move the enemies along bezier curves and optionally insert custom assembler code for updating enemies so they will be able to chase the player etc.

The basic idea that I have for the enemies is that there will not be many but they will be big and robust. So my intention is to create an atmosphere of tightness and uneasiness for the player.
