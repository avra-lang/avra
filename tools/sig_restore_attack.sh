#!/bin/sh
# A RESTORED SIGNING WRITES WHAT SIGNING WROTE, over a whole package. A cold check of the
# package writes every signing's tables (`AVRA_SIGN_TABLES`); a check after an export is added
# to a file most of the package imports reads those importers again, and lands the saved
# signings whose reads stand instead of signing them. Every declaration the second
# check landed must read as the first left it — a write a signing makes and its answer does
# not carry is a table that differs here.
set -u
. "$(dirname "$0")/lib/attack.sh"
AVRA=${AVRA:-./avra}
PKG=${1:-packages/std-avrac}
R=$(cd "$(mktemp -d)" && pwd -P)
export AVRA_CACHE_DIR="$R/cache"
EDITED=${2:-$PKG/src/core/types.av}
cp "$EDITED" "$R/edited"
trap 'cp "$R/edited" "$EDITED"' EXIT
AVRA_SIGN_TABLES="$R/cold" $AVRA check "$PKG" > "$R/out" 2>&1 || fail "the cold check refused: $(tail -2 "$R/out" | tr '\n' ' ')"
printf '\nexport fn sig_restore_probe() -> int { 1 }\n' >> "$EDITED"
AVRA_SIGN_TABLES="$R/warm" $AVRA check "$PKG" > "$R/out" 2>&1 || fail "the warm check refused: $(tail -2 "$R/out" | tr '\n' ' ')"
cp "$R/edited" "$EDITED"
[ -s "$R/cold" ] || fail "the cold check wrote no tables"
landed=$(awk -F '\t' '$2 == "L"' "$R/warm" 2>/dev/null | wc -l | tr -d ' ')
[ "$landed" -gt 0 ] || fail "the warm check landed no signing"
# each landed line against the cold line of its declaration, the made-or-landed column aside
awk -F '\t' 'NR == FNR { $2 = ""; cold[$1] = $0; next } $2 == "L" { $2 = ""; if (!($1 in cold)) print "absent " $1; else if (cold[$1] != $0) print "differs " $0 "\n   cold " cold[$1] }' "$R/cold" "$R/warm" > "$R/diff"
[ -s "$R/diff" ] && fail "$(grep -c '^absent\|^differs' "$R/diff") landed declaration(s) read otherwise, e.g. $(head -2 "$R/diff" | cut -c1-300 | tr '\n' ' ')"
echo "sig-restore-attack: $landed landed signing(s) compared, $(awk -F "\t" '$2 == "S"' "$R/warm" | wc -l | tr -d " ") signed again"
trap - EXIT
find "$R" -delete
verdict "sig-restore-attack" "$PKG cold, then warm after an export was added"
