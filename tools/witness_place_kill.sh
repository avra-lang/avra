#!/bin/sh
# A BUILD KILLED BETWEEN PLACING ITS BINARY AND SAVING ITS STORE LEAVES BOTH RIGHT. A build places
# its binary first and saves its store after; this kills one between the two (AVRA_KILL_AFTER_PLACE)
# and asks of what it leaves: the binary it placed is the cold build's of the edited tree; the store
# is the one the build before left, file for file; the next build over it, warm, places the same
# binary and saves; and the edit taken back over that store builds the first cold product. On the
# cli, with a literal edited, through the program layer.
#   sh tools/witness_place_kill.sh [compiler]   (default build/avra-try)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${1:-build/avra-try}
[ -x "$avra" ] || { echo "witness_place_kill: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
export AVRA_CACHE_DIR="$tmp/machine"
export AVRA_PROGRAM=1
# A PRODUCT COMPARED BYTE FOR BYTE IS THE RELEASE ONE: a dev build's binary is an overlay linked
# beside the world it last linked, so a warm dev product never holds a cold one's bytes.
export AVRA_PROGRAM_MODE=release
mkdir -p "$AVRA_CACHE_DIR"
file=packages/cli/src/commands/cache.av
cp "$file" "$tmp/orig.av"
restore() { cp "$tmp/orig.av" "$file"; find "$tmp" -delete; }
trap restore EXIT

store=packages/cli/.avra-cache
afresh() { find "$store" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
unsigned() { cp packages/cli/src/main "$1"; codesign --remove-signature "$1" 2>/dev/null || :; }
built() { "$avra" build packages/cli >"$tmp/log" 2>&1 || { echo "witness_place_kill: $1 failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; }
# every file the store holds, with its size and digest, in path order; a draft, which no build
# reads and the next store opened removes once its process is gone, left out
held() { (cd "$store" && find . -type f ! -path './tapes-build/*' ! -name '*.draft' -exec cksum {} + | sort -k3); }
drafts() { find "$store" -name '*.draft' ! -path '*/tapes-build/*' | wc -l | tr -d ' '; }
edit() { sed 's/shared store kept ${shared.kept} blob(s)/shared store holds ${shared.kept} blob(s)/' "$tmp/orig.av" >"$file"; }

afresh
built "the cold build"
unsigned "$tmp/base"
held >"$tmp/held.before"

edit
status=0
AVRA_KILL_AFTER_PLACE=1 "$avra" build packages/cli >"$tmp/log" 2>&1 || status=$?
[ "$status" = 137 ] || { echo "witness_place_kill: the killed build exited $status, not 137" >&2; tail -5 "$tmp/log" >&2; exit 1; }
unsigned "$tmp/killed"
held >"$tmp/held.after"
cmp -s "$tmp/held.before" "$tmp/held.after" || { echo "witness_place_kill: the killed build changed the store:" >&2; diff "$tmp/held.before" "$tmp/held.after" | head -10 >&2; exit 1; }
cmp -s "$tmp/killed" "$tmp/base" && { echo "witness_place_kill: the killed build placed the unedited binary" >&2; exit 1; }
echo "witness_place_kill: killed after placing, exit 137 — the store is the one the build before left, beside $(drafts) abandoned draft(s)"

built "the build after the kill"
unsigned "$tmp/after"
cmp -s "$tmp/after" "$tmp/killed" || { echo "witness_place_kill: the build after the kill placed another binary" >&2; exit 1; }
held >"$tmp/held.saved"
cmp -s "$tmp/held.before" "$tmp/held.saved" && { echo "witness_place_kill: the build after the kill saved nothing" >&2; exit 1; }
[ "$(drafts)" = 0 ] || { echo "witness_place_kill: the build after the kill left a draft" >&2; exit 1; }
echo "witness_place_kill: the build after the kill placed the same binary and saved"

afresh
built "the edited tree's cold build"
unsigned "$tmp/cold"
cmp -s "$tmp/cold" "$tmp/killed" || { echo "witness_place_kill: the killed build's binary is not the edited tree's cold one" >&2; exit 1; }
echo "witness_place_kill: the binary the killed build placed is the cold one — warm == cold"

afresh
built "the cold build again"
edit
AVRA_KILL_AFTER_PLACE=1 "$avra" build packages/cli >"$tmp/log" 2>&1 || :
cp "$tmp/orig.av" "$file"
built "the edit taken back after a kill"
unsigned "$tmp/back"
cmp -s "$tmp/back" "$tmp/base" || { echo "witness_place_kill: taken back after a kill, the product is not the first cold one" >&2; exit 1; }
echo "witness_place_kill: taken back after a kill — warm == cold"
