#!/bin/sh
# Install the Firefox `make ui-browser` drives, from Mozilla's own release
# tarball, pinned by version and checked by digest: the distro's `firefox` is
# a snap, which neither a container nor a Sprite can run. Idempotent; the
# binary lands at /usr/local/bin/firefox, where tools/ui-board/firefox.mjs
# looks. Linux x86-64 only; elsewhere it does nothing.
#
#   sh .github/ci/install_firefox.sh
set -eu
. "$(dirname "$0")/fetch_pinned.sh"

version=158.0
sha256=9549b054ec4cf85f50f6a19d8c6fb79580312e71ebc4ec2cb217ec9af09dc12a

[ "$(uname -s)" = Linux ] && [ "$(uname -m)" = x86_64 ] || exit 0
if [ -x /opt/firefox/firefox ] && [ "$(/opt/firefox/firefox --version 2>/dev/null | awk '{print $3}')" = "$version" ]; then
    exit 0
fi

fetch_pinned install_firefox "https://ftp.mozilla.org/pub/firefox/releases/$version/linux-x86_64/en-US/firefox-$version.tar.xz" "$sha256"
SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
$SUDO rm -rf /opt/firefox
$SUDO mv "$pinned/firefox" /opt/firefox
$SUDO ln -sf /opt/firefox/firefox /usr/local/bin/firefox
echo "install_firefox: Firefox $version at /usr/local/bin/firefox"
