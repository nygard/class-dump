BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

all:
	# make ios-class-guard
	# make ios-class-guard-commit

ios-class-guard:
	xctool -project ios-class-guard.xcodeproj -scheme ios-class-guard -configuration Release clean build OBJROOT=build/ SYMROOT=build/
	
ios-class-guard-commit: ios-class-guard
	git checkout gh-pages
	cp build/Release/ios-class-guard ios-class-guard
	git add ios-class-guard
	git commit -m "Compiled on $(shell date)"
	git checkout $(BRANCH)
