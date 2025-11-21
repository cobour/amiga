#!/bin/bash -x
cd ../common/data_tool/app/
../gradlew run --args='config.file=../../../hydron/data/data_files_config.yml vasm=../common/bin/macos/vasmm68k_mot'
cd ../../../hydron/
../common/bin/macos/vasmm68k_mot -m68000 -Fhunk -DRELEASE -DSTANDARD_EXE -DUSE_DOS -o build/whdload/hydron.o hydron.asm
../common/bin/macos/vlink -bamigahunk -Bstatic -o dist/whdload/Hydron.exe build/whdload/hydron.o 
cp uae/dh0/*.dat dist/whdload
rm -f dist/whdload/C000.dat