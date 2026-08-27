#!/bin/sh
echo "var matteList = [" > filelist.js

cd ../bin
for f in `find * -iname '*.mt'`; do 
  echo "Compiling $f"
  mkdir -p "../export-web/"$(dirname "$f")
  ../matte/matte compile "$f" "../export-web/$f"
  echo "\"$f\"," >> ../export-web/filelist.js
done

for f in `find * -iname '*.json'`; do 
  echo "Copying $f"
  mkdir -p "./export-web/"$(dirname "$f")
  cp "$f" "./export-web/$f"
  echo "\"$f\"," >> ./export-web/filelist.js
done


cd ../export-web/
../matte/matte compile "../GIT_COMMIT" "./GIT_COMMIT"
../matte/matte compile-debug ../matte/src/rom/core/class.mt "./Matte.Core.Class"
../matte/matte compile-debug ../matte/src/rom/core/core.mt "./Matte.Core"
../matte/matte compile-debug ../matte/src/rom/core/eventsystem.mt "./Matte.Core.EventSystem"
../matte/matte compile-debug ../matte/src/rom/core/introspect.mt "./Matte.Core.Introspect"
../matte/matte compile-debug ../matte/src/rom/core/json.mt "./Matte.Core.JSON"
../matte/matte compile-debug ../main.external.mt "main.external.mt"

echo "\"main.external.mt\"];" >> ./filelist.js


echo "var GIT_VERSION=\"`git show --no-patch --format=tformat:'%D %h'`\"" > GIT_VERSION.js
cp ../matte/js/matte.js ./
GITSHORT=`git rev-parse --short HEAD`


