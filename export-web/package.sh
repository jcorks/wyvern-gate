#!/bin/sh
cd ..
for f in `ls -1`; do 
	if [[ $f == *"mt" ]]; then 
		echo ./export-cli/matte/cli/matte compile "$f" "./export-web/$f"
		./export-cli/matte/cli/matte compile "$f" "./export-web/$f"
	fi
done
cd ./export-web/
../export-cli/matte/cli/matte compile ../export-cli/matte/src/rom/core/class.mt "./Matte.Core.Class"
../export-cli/matte/cli/matte compile ../export-cli/matte/src/rom/core/core.mt "./Matte.Core"
../export-cli/matte/cli/matte compile ../export-cli/matte/src/rom/core/eventsystem.mt "./Matte.Core.EventSystem"
../export-cli/matte/cli/matte compile ../export-cli/matte/src/rom/core/introspect.mt "./Matte.Core.Introspect"
../export-cli/matte/cli/matte compile ../export-cli/matte/src/rom/core/json.mt "./Matte.Core.JSON"
echo "var GIT_VERSION=\"`git show --no-patch --format=tformat:'%D %h'`\"" > GIT_VERSION.js
cp ../export-cli/matte/js/matte.js ./
GITSHORT=`git rev-parse --short HEAD`


