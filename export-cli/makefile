all:
	cd ./matte/ && make -f ./makefile DEFINES="-DMATTE_USE_SYSTEM_EXTENSIONS -DMATTE_USE_SYSTEM_EXTENSIONS__BASIC"
	gcc *.c ./matte/libmatte.a -o ../bin/wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

ncurses:
	cd ./matte/ && make -f ./makefile DEFINES="-DMATTE_USE_SYSTEM_EXTENSIONS -DMATTE_USE_SYSTEM_EXTENSIONS__BASIC"
	gcc -DWYVERN_NCURSES *.c ./matte/libmatte.a -o ../bin/wyvern-gate-cli -lm -lpthread -lncursesw
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

debug:
	cd ./matte/ && make -f ./makefile debug DEFINES="-DMATTE_USE_SYSTEM_EXTENSIONS -DMATTE_USE_SYSTEM_EXTENSIONS__BASIC"
	gcc -g  *.c ./matte/libmatte.a -o ../bin/wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit


debug2:
	cd ./matte/ && make -f ./makefile debug DEFINES="-DMATTE_USE_SYSTEM_EXTENSIONS -DMATTE_USE_SYSTEM_EXTENSIONS__BASIC"
	gcc -g -fsanitize=address -fsanitize=undefined *.c ./matte/libmatte.a -o ../bin/wyvern-gate-cli -lm -lpthread
	cp ../git_hooks/post-commit ../.git/hooks/
	cd ../ && ./.git/hooks/post-commit

