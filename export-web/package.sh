#!/bin/sh
cd ../matte/
make
cd ../export-web/
rm -rf ./output
mkdir ./output
echo "var matteList = [" > ./output/filelist.js
cd ../bin
for f in `find * -iname '*.mt'`; do 
  echo "Compiling $f"
  mkdir -p "../export-web/output/"$(dirname "$f")
  ../matte/matte compile-debug "$f" "../export-web/output/$f"
  echo "\"$f\"," >> ../export-web/output/filelist.js
done

for f in `find * -iname '*.json'`; do 
  echo "Copying $f"
  mkdir -p "../export-web/output/"$(dirname "$f")
  cp "$f" "../export-web/output/$f"
  echo "\"$f\"," >> ../export-web/output/filelist.js
done

cd ../export-web/
../matte/matte compile "../GIT_COMMIT" "./GIT_COMMIT"
../matte/matte compile-debug ../matte/src/rom/core/class.mt "./output/Matte.Core.Class"
../matte/matte compile-debug ../matte/src/rom/core/core.mt "./output/Matte.Core"
../matte/matte compile-debug ../matte/src/rom/core/eventsystem.mt "./output/Matte.Core.EventSystem"
../matte/matte compile-debug ../matte/src/rom/core/introspect.mt "./output/Matte.Core.Introspect"
../matte/matte compile-debug ../matte/src/rom/core/json.mt "./output/Matte.Core.JSON"
../matte/matte compile-debug ../main.external.mt "output/main.external.mt"

cp ./*.js ./output/
cp ./*.css ./output/
cp ./*.png ./output/
cp ./*.ttf ./output/
cp ./index.html ./output/

echo "\"Matte.Core.Class\"," >> ./output/filelist.js
echo "\"Matte.Core\"," >> ./output/filelist.js
echo "\"Matte.Core.EventSystem\"," >> ./output/filelist.js
echo "\"Matte.Core.Introspect\"," >> ./output/filelist.js
echo "\"Matte.Core.JSON\"," >> ./output/filelist.js
echo "\"main.external.mt\"];" >> ./output/filelist.js


echo "var GIT_VERSION=\"`git show --no-patch --format=tformat:'%D %h'`\"" > output/GIT_VERSION.js
cp ../matte/js/matte.js ./output/
GITSHORT=`git rev-parse --short HEAD`
echo "Web output is ready! Look in ./output"
echo "Thanks for checking out my silly game"
echo "   -Rasa"

