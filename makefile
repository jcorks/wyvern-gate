all:
	emcc -O3 -sEXTRA_EXPORTED_RUNTIME_METHODS='["cwrap", "allocate", "intArrayFromString"]' -DWYVERN_GIT_COMMIT=\"$(GIT_SHORT_HASH)\" -sASYNCIFY_STACK_SIZE=8000000 -sALLOW_MEMORY_GROWTH --preload-file ../out@/ --js-library ./bridge.js -sASYNCIFY ./main.c ./matte/src/*.c ./matte/src/rom/native.c -o ./wyvern.js
