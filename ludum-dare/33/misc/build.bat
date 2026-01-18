@echo off

pushd W:\LudumDare\LD33

set compiler_flags=-std=c++11 ^
	--embed-file res@/ ^
	-s USE_SDL=1 ^
	-s AGGRESSIVE_VARIABLE_ELIMINATION=1 ^
	-s ALLOW_MEMORY_GROWTH=1 ^
	-Wno-c++11-narrowing -Wno-absolute-value ^
	-O0
:: For some reason, optimizations like O2 etc. make it slower!!!
:: TODO(bill): Figure out why

emcc src\unity_build.cpp %compiler_flags% -o game.js

popd
