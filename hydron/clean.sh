#!/bin/bash -x
rm -rf dist/*.adf
rm -rf build/*.o
rm -rf build/*.bb
rm -rf data/_converted/*.asm
rm -rf data/_converted/*.o
rm -rf data/_converted/*.dat
rm -rf data/_converted/*.dat.tmp
rm -rf uae/dh0/Hydron
rm -rf uae/dh0/*.dat
rm -rf uae/dh0/*.uaem
rm -rf uae/dh0test/HydronUnitTest
rm -f main_code.i
rm -rf build/whdload/*.o
rm -rf dist/whdload/*.exe
rm -rf dist/whdload/*.dat
rm -f ~/Documents/FS-UAE/Save\ States/Default/*.sdf