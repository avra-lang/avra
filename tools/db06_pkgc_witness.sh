#!/bin/sh
# DB 06 step 6: A PACKAGE'S OWN C — WHICH ROW NAMES IT, AND WHAT COVERS IT ALREADY.
#
# §6.4 names three things folded into what may read an answer: the runtime's C, package C, and
# the builder. This witness answers the PACKAGE half by measurement, in three parts.
#
# 1. THE INVENTORY. A package's C reaches a program only through its manifest's
#    `[link] objects` / `[link] wasm_objects` rows — never its `.c` files, which the toolchain's
#    own build reads. Printed per package, with the path each row resolves to in the tree.
#
# 2. WHAT ALREADY COVERS IT, ON THE NATIVE PATH. `linked_files` is the runtime archive plus
#    EVERY reached package's objects, and `build.av`'s `linked_reads` keeps those bytes as the
#    reads the kept binary's row stands on (`host_fns_key`). So package C is covered by a READ
#    SET, not by a producer stamp. The witness is two builds: a cache hit, then one package's
#    object gains a symbol, and the build is not a hit — it relinks.
#
# 3. THE GAP. `code_hashes` answers a symbol's code hash, and a runtime row or an extern hashes
#    by its NAME (`CodeGraph.hash` -> `digest_of_name`), never by the C body it runs: §6.4's
#    "each `CallRt` row's C body digest" is not folded. Measured by asking the program for
#    `code_hash` of a fn that calls a row, with the package's C moved and moved back.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
R=build/db06-pkgc
pkg=packages/std-time
obj=build/std_time.o
src=$pkg/src/c/std_time.c

# The reuse line a timed build prints: `· cache hit` or `· built`.
reused() { sed -n 's/.*lower+emit · \(.*\)/\1/p' "$1" | tail -1; }

mkdir -p $R/p/src
# ONE entry: a package with a second file holding statements is refused (lower.entry_only),
# and a probe from an earlier run is exactly how that happens.
find $R/p/src -name '*.av' ! -name 'main.av' -delete
cat > $R/p/avra.toml <<'TOML'
[package]
name = "pkgc-p"
version = "0.1.0"
TOML
cat > $R/p/src/main.av <<'AV'
use @std.time.{now_ms}
use @std.meta.{code_hash}

fn timed() -> int { now_ms() }

println("hash ${code_hash(timed) ?? "none"}")
AV

echo "=== 1. the rows that name C, per package (a package's C reaches a program here, never as a .c)"
printf '%-16s %-28s %s\n' package row "resolves to"
linked=0
for m in packages/*/avra.toml; do
    p=$(dirname "$m")
    n=$(find "$p" -name '*.c' -not -path '*/vendor/*' | wc -l | tr -d ' ')
    v=$(find "$p" -name '*.c' -path '*/vendor/*' | wc -l | tr -d ' ')
    [ "$n" = 0 ] && [ "$v" = 0 ] && continue
    row=$(sh tools/manifest_objects.sh --rows objects "$m" | head -1)
    wrow=$(sh tools/manifest_objects.sh --rows wasm_objects "$m" | head -1)
    if [ -z "$row" ]; then
        printf '%-16s %-28s %s\n' "${p#packages/}" "- none -" "no program links this C (${n} src, ${v} vendor)"
        continue
    fi
    linked=$((linked + 1))
    printf '%-16s %-28s %s\n' "${p#packages/}" "$row" "$( [ -f "$p/$row" ] && echo "built" || echo "not built here" )"
    [ -n "$wrow" ] && printf '%-16s %-28s %s\n' "" "$wrow" "$( [ -f "$p/$wrow" ] && echo "built" || echo "not built here" )"
done
echo "packages that link objects into a program: $linked"

echo
echo "=== 2. the native path: does a package object's byte move the kept answer?"
cp "$src" $R/std_time.c.kept
cp "$obj" $R/std_time.o.kept
restore() { cp $R/std_time.c.kept "$src"; cp $R/std_time.o.kept "$obj"; }
trap restore EXIT INT TERM
if [ -d .avra-cache ]; then find .avra-cache -delete; fi
built() { ./avra build --time $R/p/src/main.av >$R/$1.out 2>$R/$1.err; echo "$(reused $R/$1.err)"; }
bin=$(sed '/^time: \|^host fn: /d' $R/cold.out 2>/dev/null | tail -1)
echo "first build: $(built cold)"
echo "second build: $(built warm)"
kept=$(shasum -a 256 "$(tail -1 $R/warm.out)" | cut -d' ' -f1 | cut -c1-16)
echo "binary $kept"

echo "--- one package's C gains a symbol; nothing it does changes"
printf '\n/* the witness`s own symbol: the package C of a second build */\nint avra_db06_pkgc_probe(void) { return 0; }\n' >> "$src"
make -s $obj >$R/make.log 2>&1 || { echo "MAKE FAILED"; tail -20 $R/make.log; exit 1; }
echo "the object: $(shasum -a 256 $R/std_time.o.kept | cut -d' ' -f1 | cut -c1-16) -> $(shasum -a 256 "$obj" | cut -d' ' -f1 | cut -c1-16)"
echo "third build: $(built moved)"
now=$(shasum -a 256 "$(tail -1 $R/moved.out)" | cut -d' ' -f1 | cut -c1-16)
# A read set is exact about its INPUTS, not about its output: the appended symbol is unused, so
# the relinked binary is byte-identical — and the reuse was still refused, which is the point.
[ "$now" = "$kept" ] && echo "the relinked binary is byte-identical ($kept): the read set refused the reuse, not a difference in the answer" || echo "the binary was relinked ($kept -> $now)"

echo
echo "=== 3. the gap: does the query code hash see a C body under an unchanged name?"
moved_hash=$(sh tools/capped.sh --last ./avra run $R/p/src/main.av 2>/dev/null) || moved_hash="(status $?)"
restore
restored_hash=$(sh tools/capped.sh --last ./avra run $R/p/src/main.av 2>/dev/null) || restored_hash="(status $?)"
echo "C moved:    $moved_hash"
echo "C restored: $restored_hash"
# THE INSTRUMENT'S OWN CONTROL: a hash that moved for nothing would make the line above say
# nothing. One word of the FN's OWN body changes, and the hash must move.
cp $R/p/src/main.av $R/main.av.kept
sed -i.bak 's/now_ms() }/now_ms() + 1 }/' $R/p/src/main.av
source_hash=$(sh tools/capped.sh --last ./avra run $R/p/src/main.av 2>/dev/null) || source_hash="(status $?)"
cp $R/main.av.kept $R/p/src/main.av
echo "Avra moved: $source_hash  (the control)"

echo
warm=$(reused $R/warm.err)
moved=$(reused $R/moved.err)
echo "WITNESS: package C, native path — second build: ${warm}; after one package object moved: ${moved}"
[ "$warm" = "cache hit" ] || { echo "FAIL: the second build was not a hit, so nothing was witnessed"; exit 1; }
[ "$moved" != "cache hit" ] || { echo "FAIL: a build whose package object moved was a cache hit"; exit 1; }

echo "WITNESS: the query code hash — '${moved_hash}' with the C moved, '${restored_hash}' restored"
[ "$source_hash" != "$restored_hash" ] || { echo "FAIL: the hash did not move when the FN's own body changed, so the instrument is dead"; exit 1; }
if [ "$moved_hash" = "$restored_hash" ]; then
    echo "GAP: the hash did not move: §6.4's \"each CallRt row's C body digest\" is not folded"
    echo "     — a package's C is covered on the native path by a read set, and nowhere in a code hash"
else
    echo "the hash moved with the C body"
fi
echo "PASS"
