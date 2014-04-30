all:
	# make ios-class-guard
	# make ios-class-guard-commit

ios-class-guard:
	xcodebuild -project ios-class-guard.xcodeproj -scheme ios-class-guard -configuration Release -archivePath ios-class-guard-archive/ clean archive
	
ios-class-guard-commit: ios-class-guard
	git checkout gh-pages
	cp ios-class-guard-archive.xcarchive/Products/ios-class-guard ios-class-guard
	git add ios-class-guard
	git commit -m "Compiled on $(shell date)"
	git checkout master
