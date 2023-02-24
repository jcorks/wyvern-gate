#!/bin/bash
for f in `ls -1`; do 
	if [[ $f == *"mt" ]]; then 
		./matte compile "$f" "./out/$f"
	fi
done
cd ./export-web
GITSHORT=`git rev-parse --short HEAD`
make GIT_SHORT_HASH=\"$GITSHORT\"
cd ..

