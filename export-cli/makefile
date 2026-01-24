all:
	cd ./matte/ && make -f ./makefile_gcc_static
	gcc *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

ncurses:
	cd ./matte/ && make -f ./makefile_gcc_static
	gcc -DWYVERN_NCURSES *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread -lncursesw
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

debug:
	cd ./matte/ && make -f ./makefile_gcc_static debug
	gcc -g  *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit


debug2:
	cd ./matte/ && make -f ./makefile_gcc_static debug
	gcc -g -fsanitize=address -fsanitize=undefined *.c ./matte/libmatte.a -o ../wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

