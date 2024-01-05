all:
	cd ./matte/ && make -f ./makefile_gcc_static
	gcc *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread -lssl -lcrypto

debug:
	cd ./matte/ && make -f ./makefile_gcc_static
	gcc -g -fsanitize=address -fsanitize=undefined *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread -lssl -lcrypto

