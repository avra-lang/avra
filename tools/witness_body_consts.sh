#!/bin/sh
# A CONST A BODY DECLARES, ITS VALUE READING, OF WHAT THE BODY BINDS, ONLY CONSTS BEFORE IT, IS
# SETTLED AT COMPILE TIME on the program layer, and a read of it is the binary's own data. A package
# whose fns declare them: a list a lambda computes, a record, a scalar, and a chain of three each
# reading the one before. It must print on the program layer what the old path's run printed (its
# last word, frozen at cbc437f4 before its deletion: `70 o42 43 126`); each
# fn's lowered code must read its const as a `static` — an address — and build nothing that
# computes it; a control whose const reads a `let` is seen built at run time. Then THE CONST'S
# INITIALIZER EDITED, at its own length, is worked out again in that one body: the warm build is the
# cold one, one `lowered_under` answer is worked out (counted with no work ahead on other cores),
# and taken back the first product again.
#   sh tools/witness_body_consts.sh [compiler]   (default build/avra-try)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_body_consts: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
pkg="$tmp/consts"
mkdir -p "$pkg/src"
export AVRA_CACHE_DIR="$tmp/machine"
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
mkdir -p "$AVRA_CACHE_DIR"
printf '[package]\nname = "consts"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
cat >"$pkg/src/main.av" <<'EOF'
type P = { x: int, tag: string }

fn primed(i: int) -> int {
    const PRIMES: List<int> = [2, 3, 5, 7, 11, 13].map((p) -> p * 10)
    PRIMES[i]
}

fn point() -> string {
    const ORIGIN: P = P { x: 40 + 2, tag: "o" }
    "${ORIGIN.tag}${ORIGIN.x}"
}

fn scaled(n: int) -> int {
    const K: int = 6 * 7
    K + n
}

fn chained() -> int {
    const A: int = 6
    const B: int = A * 7
    const C: List<int> = [1, 2, 3].map((x) -> x * B)
    C[2]
}

println("${primed(3)} ${point()} ${scaled(1)} ${chained()}")
EOF

fail() { echo "witness_body_consts: $1" >&2; exit 1; }
# A product compared byte for byte is the release one: a dev build's binary is an overlay linked beside
# the world it last linked, so a warm dev product never holds a cold one's bytes.
new() { (cd "$pkg" && AVRA_PROGRAM_MODE=release "$@" "$avra" build . >"$tmp/log" 2>&1) || { tail -5 "$tmp/log" >&2; fail "the program layer refused it"; }; }

# what the old path's run printed, its last word on this package
echo "70 o42 43 126" >"$tmp/old.out"
new env
"$pkg/src/main" >"$tmp/new.out"
cmp -s "$tmp/old.out" "$tmp/new.out" || fail "the program layer prints otherwise than the old path did: $(cat "$tmp/old.out") / $(cat "$tmp/new.out")"
echo "witness_body_consts: prints $(cat "$tmp/new.out"), as the old path did"
cp "$pkg/src/main" "$tmp/base"

# what builds a list or a record at run time
builds='call avra_array_(sized|push)'
for f in primed point chained; do
    find "$pkg/.avra-cache" -mindepth 1 -delete
    new env AVRA_IR_OF="main.av.$f"
    grep -q '= static .*\$const' "$tmp/log" || { cat "$tmp/log" >&2; fail "$f reads its const otherwise than as a static"; }
    if grep -qE "$builds|lambda" "$tmp/log"; then cat "$tmp/log" >&2; fail "$f computes its const at run time"; fi
    echo "witness_body_consts: $f reads its const as the binary's own data"
done

# the control: a const that reads what its body binds is computed where it stands, and the IR says so
ctl="$tmp/control"
mkdir -p "$ctl/src"
printf '[package]\nname = "control"\nversion = "0.0.1"\n' >"$ctl/avra.toml"
printf 'fn primed(i: int) -> int {\n    let k = i\n    const PRIMES: List<int> = [2, 3, 5].map((p) -> p * k)\n    PRIMES[i]\n}\nprintln("${primed(1)}")\n' >"$ctl/src/main.av"
(cd "$ctl" && AVRA_PROGRAM=1 AVRA_IR_OF=main.av.primed "$avra" build . >"$tmp/ctl.log" 2>&1) || fail "the control: the program layer refused it"
grep -qE "$builds" "$tmp/ctl.log" || { cat "$tmp/ctl.log" >&2; fail "the control: a const that reads its body is not seen built at run time"; }
[ "$("$ctl/src/main")" = 3 ] || fail "the control printed $("$ctl/src/main")"
echo "witness_body_consts: the control — a const that reads its body is built where it stands"

sed 's/p \* 10)/p * 20)/' "$pkg/src/main.av" >"$tmp/edited" && cp "$tmp/edited" "$pkg/src/main.av"
new env AVRA_FOLD_CHECK=1 AVRA_QUERY_TIMES=1 AVRA_WORK_AHEAD_OFF=1
lowered=$(grep -oE 'lowered_under [^,]*' "$tmp/log" | grep -oE '\([0-9]+\)' | tr -d '()')
cp "$pkg/src/main" "$tmp/warm"
"$pkg/src/main" >"$tmp/warm.out"
find "$pkg/.avra-cache" -mindepth 1 -delete
new env
cmp -s "$pkg/src/main" "$tmp/warm" || fail "after the initializer's edit the warm product is not the cold one"
cmp -s "$tmp/warm" "$tmp/base" && fail "the initializer's edit moved nothing"
[ "$lowered" = 1 ] || { grep -E '^time:|^avra' "$tmp/log" >&2; fail "the initializer's edit worked out ${lowered:-no} \`lowered_under\` answers, not one"; }
echo "witness_body_consts: the initializer edited — warm == cold, printing $(cat "$tmp/warm.out"), one body worked out again"
sed 's/p \* 20)/p * 10)/' "$pkg/src/main.av" >"$tmp/back" && cp "$tmp/back" "$pkg/src/main.av"
new env AVRA_FOLD_CHECK=1
cmp -s "$pkg/src/main" "$tmp/base" || fail "with the edit taken back the warm product is not the first"
echo "witness_body_consts: taken back — warm == the first product"
