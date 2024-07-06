all:
	cd ./matte/ && make -f ./makefile_gcc_static
	gcc *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread

debug:
	cd ./matte/ && make -f ./makefile_gcc_static debug
	gcc -g *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread

