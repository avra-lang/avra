#!/bin/sh
# A BUILD THAT FILLS ITS DISK SAYS SO, AND WHERE. A package is built on a small filesystem with less
# room each time, so the build runs out at its object, then at its link; then its store alone stands
# on a small one, saved by the build itself and by its heir. Every one of them must end with words that
# name the file it could not write and the disk's free bytes — never an exit with nothing said.
#
# The filesystems are tmpfs mounts: made here where the process may mount, else in a mount namespace
# of its own (`unshare -rm`); a machine that allows neither cannot witness this, and says so.
#   sh tools/witness_disk_full.sh [compiler]   (default build/avra)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=$(cd "$(dirname "${1:-$root/build/avra}")" && pwd)/$(basename "${1:-$root/build/avra}")
if [ "${WITNESS_DISK_FULL_INSIDE:-}" != 1 ]; then
    probe=$(mktemp -d)
    if mount -t tmpfs -o size=64k tmpfs "$probe" 2>/dev/null; then
        umount "$probe"; find "$probe" -delete
        WITNESS_DISK_FULL_INSIDE=1 exec sh "$0" "$avra"
    fi
    find "$probe" -delete
    if unshare -rm true 2>/dev/null; then WITNESS_DISK_FULL_INSIDE=1 exec unshare -rm sh "$0" "$avra"; fi
    echo "witness_disk_full: NOT WITNESSED — this machine can mount no small filesystem (neither mount nor unshare -rm)"
    exit 0
fi

w=$(mktemp -d)
fail() { echo "witness_disk_full: $*"; for m in "$w/disk" "$w/store/.avra-cache/tapes"; do umount "$m" 2>/dev/null; done; find "$w" -delete 2>/dev/null; exit 1; }
package() { mkdir -p "$1/src" && printf '[package]\nname = "disk-full"\nversion = "0.1.0"\n' >"$1/avra.toml" && printf 'println("hi")\n' >"$1/src/main.av"; }
# `$1` the build's words; `$2` what they must name; `$3` the case
said() { grep -q "$2" "$1" && grep -q 'bytes free' "$1" || { cat "$1"; fail "$3: the build did not say the disk is full and where"; }; }

# the object, then the link: the whole build on a 3 MB disk with `$1` KB left
mkdir -p "$w/disk" && mount -t tmpfs -o size=3m tmpfs "$w/disk" || fail "the small disk did not mount"
squeezed() {
    find "$w/disk" -mindepth 1 -delete
    package "$w/disk/p"
    avail=$(df -k "$w/disk" | tail -1 | awk '{ print $4 }')
    dd if=/dev/zero of="$w/disk/fill" bs=1k count=$((avail - $1)) 2>/dev/null
    AVRA_CACHE_DIR="$w/disk/machine" "$avra" build "$w/disk/p" >"$w/out" 2>&1 && fail "$2: the build passed on a full disk"
}
squeezed 40 "the object"
said "$w/out" '\.o needed' "the object"
echo "witness_disk_full: an object that does not fit — named, its bytes and the disk's free bytes said"
squeezed 400 "the link"
said "$w/out" 'this link writes' "the link"
echo "witness_disk_full: a link that does not fit — named, with the disk's free bytes"
umount "$w/disk"

# the store: only its directory small, saved by the build (`AVRA_STORE_KEPT_HERE`) and by its heir
package "$w/store"
mkdir -p "$w/store/.avra-cache/tapes" && mount -t tmpfs -o size=64k tmpfs "$w/store/.avra-cache/tapes" || fail "the small store did not mount"
AVRA_STORE_KEPT_HERE=1 AVRA_CACHE_DIR="$w/machine" "$avra" build "$w/store" >"$w/out" 2>&1 || fail "the build failed for a store it couldn't save"
said "$w/out" "wasn't saved" "the store saved by the build"
echo "witness_disk_full: a store the build cannot save — said, with the file and the disk's free bytes"
find "$w/store/.avra-cache/tapes" -mindepth 1 -delete
find "$w/store/.avra-cache/tapes-build" -delete 2>/dev/null
env -u AVRA_STORE_KEPT_HERE AVRA_CACHE_DIR="$w/machine" "$avra" build "$w/store" >/dev/null 2>&1 || fail "the build failed for a store its heir couldn't save"
tries=0
until [ -s "$w/store/.avra-cache/tapes/saving.unfinished" ] && ! grep -q 'did not finish' "$w/store/.avra-cache/tapes/saving.unfinished" || [ $tries -ge 50 ]; do sleep 0.2; tries=$((tries + 1)); done
env -u AVRA_STORE_KEPT_HERE AVRA_CACHE_DIR="$w/machine" "$avra" build "$w/store" >"$w/out" 2>&1
said "$w/out" "save of .* failed: .*No space left" "the store saved by the heir"
echo "witness_disk_full: a store the heir cannot save — said by the next build, with the cause and the disk's free bytes"
umount "$w/store/.avra-cache/tapes"
find "$w" -delete
