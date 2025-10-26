all:
	scons platform=windows
	scons platform=windows target=template_release
	cp ./project/bin/*.mt ./project/bin/output/
	cp ./project/bin/*.dll ./project/bin/output/
	cp ../*.mt ./project/bin/output/
	cd ../ && ./.git/hooks/post-commit
	cp ../GIT_COMMIT ./project/bin/output
