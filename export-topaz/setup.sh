#!/bin/sh
mkdir ./output/
git clone https://github.com/jcorks/topaz/
cd ./topaz/ && git pull && cd ..
cp ../*.mt ./output/
cd ../ && ./git_hooks/post-commit && cd ./export-topaz
cp ../GIT_COMMIT ./output/
cp ./sys_* ./output/
cd ./topaz/system/script/matte/src
./get_matte.sh
cd ./matte
git pull
make -f ./makefile_gcc_static clean
make -f ./makefile_gcc_static

