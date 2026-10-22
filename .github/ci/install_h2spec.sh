#!/bin/sh
# Install the h2spec `make h2spec` runs against std-http's HTTP/2 server, from
# its own release, pinned by version and checked by digest. Idempotent; it
# lands at /usr/local/bin/h2spec. Linux x86-64 only; elsewhere it does nothing.
#
#   sh .github/ci/install_h2spec.sh
set -eu
. "$(dirname "$0")/fetch_pinned.sh"

version=2.6.0
sha256=157ee0de702e01ad40e752dbf074b366027e550c8e7504f9450da2809e279318

[ "$(uname -s)" = Linux ] && [ "$(uname -m)" = x86_64 ] || exit 0
if [ -x /usr/local/bin/h2spec ] && /usr/local/bin/h2spec --version 2>/dev/null | grep -q "$version"; then
    exit 0
fi
fetch_pinned install_h2spec "https://github.com/summerwind/h2spec/releases/download/v$version/h2spec_linux_amd64.tar.gz" "$sha256"
SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
$SUDO install -m 0755 "$pinned/h2spec" /usr/local/bin/h2spec
echo "install_h2spec: h2spec $version at /usr/local/bin/h2spec"
