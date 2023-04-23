#!/bin/bash
for f in `ls -1`; do 
	if [[ $f == *"mt" ]]; then 
		../matte/cli/matte compile "$f" "./export-web/$f"
	fi
done
../matte/cli/matte compile ../matte/src/rom/core/class.mt "./export-web/Matte.Core.Class"
../matte/cli/matte compile ../matte/src/rom/core/core.mt "./export-web/Matte.Core"
../matte/cli/matte compile ../matte/src/rom/core/eventsystem.mt "./export-web/Matte.Core.EventSystem"
../matte/cli/matte compile ../matte/src/rom/core/introspect.mt "./export-web/Matte.Core.Introspect"
../matte/cli/matte compile ../matte/src/rom/core/json.mt "./export-web/Matte.Core.JSON"

cd ./export-web
GITSHORT=`git rev-parse --short HEAD`
make GIT_SHORT_HASH=\"$GITSHORT\"
cd ..

