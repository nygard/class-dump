#!/bin/sh

fail() {
	echo "ERROR: $@" 1>&2
	exit 1
}

curl --silent -o /tmp/ios-class-guard https://polidea.github.io/ios-class-guard/ios-class-guard || fail "Failed to download latest ios-class-guard"
chmod +x /tmp/ios-class-guard || fail "Failed to chmod ios-class-guard"
sudo mv /tmp/ios-class-guard /usr/local/bin/ios-class-guard || fail "Failed to install ios-class-guard"

echo "Installed!"
