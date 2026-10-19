#!/bin/sh
# Install the Node `make wasm-host-check` runs the JSPI half of the hosted
# scheduler under, from nodejs.org's release tarball, pinned by version and
# checked by digest: the distro's `nodejs` (22) has only the old JSPI API,
# with no `WebAssembly.Suspending`. It lands as /usr/local/bin/node-jspi and
# the distro's `node` stays what the other keepers run. Idempotent; Linux
# x86-64 only, elsewhere it does nothing.
#
#   sh .github/ci/install_node.sh
set -eu

version=24.18.0
sha256=55aa7153f9d88f28d765fcdad5ae6945b5c0f98a36881703817e4c450fa76742

[ "$(uname -s)" = Linux ] && [ "$(uname -m)" = x86_64 ] || exit 0
if [ -x /opt/node-jspi/bin/node ] && [ "$(/opt/node-jspi/bin/node --version 2>/dev/null)" = "v$version" ]; then
    exit 0
fi

work=$(mktemp -d)
trap 'find "$work" -delete' EXIT
curl -fsSL -o "$work/node.tar.xz" "https://nodejs.org/dist/v$version/node-v$version-linux-x64.tar.xz"
[ "$(sha256sum "$work/node.tar.xz" | awk '{print $1}')" = "$sha256" ] \
    || { echo "install_node: the tarball for $version is not the one pinned" >&2; exit 1; }
tar -xJf "$work/node.tar.xz" -C "$work"
SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo
$SUDO mv "$work/node-v$version-linux-x64" /opt/node-jspi
$SUDO ln -sf /opt/node-jspi/bin/node /usr/local/bin/node-jspi
echo "install_node: Node $version at /usr/local/bin/node-jspi"
