#!/bin/sh
# A WARM EDIT BUILDS WHAT A COLD BUILD OF THE EDIT BUILDS, on the program layer.
# A no-op build over a cold store first builds the cold product. Then for each
# edit: the store the cold build left, the edit, a warm build with every fold
# held to its body (AVRA_FOLD_CHECK) — then the same edited tree built cold; the
# two unsigned products must be one file (a layered product compares as
# `unsigned_at` below says). Then the edit taken back, built warm
# over the edited tree's cold store, must be the first cold product. The edits:
# a literal, a literal in a file of queries, two that change how many task tests
# a body holds (the change a placement keyed by test position trapped on), one in
# the cli and one in another package, an enum given a variant and a record given
# a field, and a method given a seat: one with a default its caller in another
# file leaves out, one that caller is changed to fill, and one with a default
# the impls of a gathered trait in other files leave out; then a defaulted seat
# added and renamed twice, each built over the store the one before left; a line added to the
# cli's manifest, which re-judges that manifest alone; a call added to a body the program already
# reaches, a body's only call of another dropped, so that one leaves the program, and two bodies
# calling each other called anew, so taken back, the pair is cut loose of everything reaching it
# and must leave the program though each still calls the other. Empties every
# `.avra-cache` under packages/ and its own machine store.
# Then AN INFERRED ERROR FOLLOWS ITS REACH: in a package of its own, a fn a `?` reaches gains a
# `fail` of a new type; the warm build must be the cold one, and taken back, the first cold product.
# Then A LAW FOLLOWS ITS ITEM: in a package of its own, an impl's method renamed to a name an earlier
# impl took; the warm refusal must be the cold one word for word, and taken back, the first cold product.
# First, A FILE A BUILD READS AS DATA IS AN INPUT: a package whose consts read one
# file through `provided` and another through `embed`; the first file edited, the
# warm build must be the cold one, worked out again through that file's read and
# the const that reads it alone; taken back, the first cold product.
#   sh tools/witness_program_edit.sh [compiler]   (default build/avra-try, built
#   through the program layer and standing beside build/avra)
#   WITNESS_ONLY="7 8" runs just the edits of those numbers, counted from one;
#   WITNESS_ONLY=embed runs the embedded file's edit alone; WITNESS_ONLY=rename the seat renamed
#   twice; WITNESS_ONLY=infer the inferred error's alone; WITNESS_ONLY=check the instance check's edits;
#   WITNESS_ONLY=derived one of three derived records' alone; WITNESS_ONLY=gathered a member appended to
#   a collect gathered in closure, which a const folds.
#   WITNESS_ONLY=lawed a law's edit alone; WITNESS_ONLY=modes the cli built in each mode over a store
#   the other left, working ahead and alone (modes-whole, modes-layered: one mode's).
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${1:-build/avra-try}
[ -x "$avra" ] || { echo "witness_program_edit: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
export AVRA_CACHE_DIR="$tmp/machine"
export AVRA_PROGRAM=1
# the stores are copied, emptied and read between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
mkdir -p "$AVRA_CACHE_DIR"

# file|a line of it|what the line becomes, `\n` between lines; an edit of several
# files joins its parts with ` ;; `
edits='packages/cli/src/commands/cache.av|        println("avra cache log: no pack")|        println("avra cache log: no packs")
packages/std-avrac/src/compiler/item_program.av|fn runs_nothing() -> string { "a file that runs no statement" }|fn runs_nothing() -> string { "a file that runs no statements" }
packages/cli/src/commands/cache.av|    let before = packs_listed(dir)|    let before = packs_listed(dir)\n    let _ = packs_listed(dir).length
packages/std-time/src/time.av|    avra_fiber_sleep(d.ms())|    avra_fiber_sleep(d.ms())\n    parked_until(avra_now_ns())
packages/cli/src/commands/fmt.av|enum Walk { Check, Write }|enum Walk { Check, Write, Listed }
packages/cli/src/commands/fmt.av|type Tally = { examined: int, differing: int, refused: int, diffs: List<string> }|type Tally = { examined: int, differing: int, refused: int, diffs: List<string>, skipped: int = 0 }
packages/cli/src/commands/idiom_baseline.av|    fn news(findings: List<Finding>) -> List<Finding> {|    fn news(findings: List<Finding>, most: int = 0) -> List<Finding> {
packages/cli/src/commands/idiom_baseline.av|    fn news(findings: List<Finding>) -> List<Finding> {|    fn news(findings: List<Finding>, most: int) -> List<Finding> { ;; packages/cli/src/commands/check.av|        let bad = loaded_baseline(baseline).news(c.findings)|        let bad = loaded_baseline(baseline).news(c.findings, 0) ;; packages/cli/src/commands/check_program.av|        let bad = loaded_baseline(baseline).news([s.finding for s in sites])|        let bad = loaded_baseline(baseline).news([s.finding for s in sites], 0)
packages/std-avrac/src/core/checking.av|        binder: BindSite? = null,|        binder: BindSite? = null,\n        kept: bool = false,
packages/cli/avra.toml|description = "The avra command"|description = "The avra command"\n# a note no law reads
packages/cli/src/commands/cache.av|    let shared? = machine_layer() else { return 0 }|    let shared? = machine_layer() else { return 0 }\n    let _ = cache_dir().length
packages/cli/src/commands/cache.av|            "packs ${before.length} → ${after.length} · bytes ${octets_of(before)} → ${octets_of(after)} · ${distinct([p.print for p in after]).length} compiler(s) kept"|            "packs ${before.length} → ${after.length} · ${distinct([p.print for p in after]).length} compiler(s) kept"
packages/cli/src/commands/cache.av|fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }|fn cycle_a(n: int) -> int { if n > 0 { cycle_b(n - 1) } else { 0 } }\n\nfn cycle_b(n: int) -> int { if n > 0 { cycle_a(n - 1) } else { 0 } }\n\nfn octets_of(packs: List<PackListed>) -> int { packs.fold(cycle_a(2), (sum, p) -> sum + p.octets) }'

restore() {
    for p in "$tmp"/orig/*.path; do [ -e "$p" ] && cp "${p%.path}.av" "$(cat "$p")"; done
    find "$tmp" -delete
}
trap restore EXIT
mkdir -p "$tmp/orig"

# The embedded file's edit, over a package of its own.
embedded_edit() {
    pkg="$tmp/embedded"
    mkdir -p "$pkg/src" "$pkg/data"
    printf '[package]\nname = "embedded"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    printf 'use @std.meta.{embed, provided, Provider}\ntype K = { n: int, d: string }\nimpl Provider for K {\n    static fn provide(path: string, octets: Bytes, digest: string) -> K? { K { n: octets.length, d: digest } }\n}\nconst A: K = provided<K>("data/side.txt")\nconst T: string = embed("../data/note.txt")\nfn other() -> int { 7 }\nprintln("${A.n} ${A.d} ${T} ${other()}")\n' >"$pkg/src/main.av"
    printf 'side data\n' >"$pkg/data/side.txt"
    printf 'note' >"$pkg/data/note.txt"
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the embedded build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    afresh
    made "$tmp/embedded.base"
    printf 'side data, longer\n' >"$pkg/data/side.txt"
    AVRA_FOLD_CHECK=1 made "$tmp/embedded.warm"
    way=$(cat "$pkg/.avra-cache/tapes-build/rebuilt.txt")
    afresh
    made "$tmp/embedded.cold"
    cmp -s "$tmp/embedded.warm" "$tmp/embedded.cold" || { echo "witness_program_edit: after the embedded file's edit the warm product is not the cold one" >&2; exit 1; }
    cmp -s "$tmp/embedded.cold" "$tmp/embedded.base" && { echo "witness_program_edit: the embedded file's edit moved nothing" >&2; exit 1; }
    expected='the build was worked out again, by this way:
  source_octets(embedded/data/side.txt)
  const_settlement(embedded/src/main.av)
  entry_lowered(embedded/src/main.av)
  program_binary(embedded/src/main.av)'
    [ "$way" = "$expected" ] || { echo "witness_program_edit: the embedded file's edit was worked out another way:" >&2; printf '%s\n' "$way" >&2; exit 1; }
    echo "witness_program_edit: an embedded file — warm == cold, worked out through its read and its const alone"
    printf 'side data\n' >"$pkg/data/side.txt"
    AVRA_FOLD_CHECK=1 made "$tmp/embedded.back"
    cmp -s "$tmp/embedded.back" "$tmp/embedded.base" || { echo "witness_program_edit: with the embedded file's edit taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: an embedded file taken back — warm == cold"
}
# The inferred error's edit, over a package of its own: a fn reached through a `?` gains a
# `fail` of a type nothing raised before, so what the fn forwarding it infers grows.
inferred_edit() {
    pkg="$tmp/inferred"
    mkdir -p "$pkg/src"
    printf '[package]\nname = "inferred"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    printf 'enum A { A(n: int) }\nenum B { B(n: int) }\nfn g(k: int) -> Result<int, _> {\n    if k == 0 { fail A.A(0) }\n    k\n}\nfn f(k: int) -> Result<int, _> {\n    let v = g(k)?\n    v\n}\nfn read(k: int) -> string { "${f(k) catch e -> 0 - 1}" }\nprintln("${read(0)} ${read(1)} ${read(2)}")\n' >"$pkg/src/main.av"
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the inferred build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    afresh
    made "$tmp/inferred.base"
    cp "$pkg/src/main.av" "$tmp/inferred.av"
    awk '$0 == "    if k == 0 { fail A.A(0) }" { print; print "    if k == 1 { fail B.B(1) }"; next } { print }' "$tmp/inferred.av" >"$pkg/src/main.av"
    AVRA_FOLD_CHECK=1 made "$tmp/inferred.warm"
    afresh
    made "$tmp/inferred.cold"
    cmp -s "$tmp/inferred.warm" "$tmp/inferred.cold" || { echo "witness_program_edit: after a reached fn gains a failure the warm product is not the cold one" >&2; exit 1; }
    cmp -s "$tmp/inferred.cold" "$tmp/inferred.base" && { echo "witness_program_edit: a reached fn's new failure moved nothing" >&2; exit 1; }
    echo "witness_program_edit: a reached fn gains a failure — warm == cold"
    cp "$tmp/inferred.av" "$pkg/src/main.av"
    AVRA_FOLD_CHECK=1 made "$tmp/inferred.back"
    cmp -s "$tmp/inferred.back" "$tmp/inferred.base" || { echo "witness_program_edit: with the new failure taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a reached fn's new failure taken back — warm == cold"
}

# A composition's body edit, over a package of its own: two compositions boxed as the trait that
# composes them, one's body edited.
composed_edit() {
    pkg="$tmp/composed"
    mkdir -p "$pkg/src"
    printf '[package]\nname = "composed"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    body() { printf 'use @std.ui.components.{text}\nuse @std.ui.tree.view.{View}\n\ncomponent first(label: string) {\n    text "a ${self.label}"\n}\n\ncomponent second(label: string) {\n    text "%s ${self.label}"\n}\n\nlet views: List<dyn View> = [first "x", second "y"]\nprintln("${views.length} ${views[1].stand().key == null}")\n' "$1" >"$pkg/src/main.av"; }
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the composed build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    body b
    afresh
    made "$tmp/composed.base"
    body bee
    AVRA_FOLD_CHECK=1 made "$tmp/composed.warm"
    afresh
    made "$tmp/composed.cold"
    cmp -s "$tmp/composed.warm" "$tmp/composed.cold" || { echo "witness_program_edit: after a composition's body edit the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a composition's body — warm == cold"
    body b
    AVRA_FOLD_CHECK=1 made "$tmp/composed.back"
    cmp -s "$tmp/composed.back" "$tmp/composed.base" || { echo "witness_program_edit: with a composition's body edit taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a composition's body taken back — warm == cold"
}
# A member appended to a collect gathered `in closure`, over a package of its own: a library declares
# the collect, a const folding it and a fn reading the const; the program declares the members. The
# product prints the count only the program's own closure answers, never the library's.
gathered_edit() {
    pkg="$tmp/gathered"
    lib="$tmp/gathered-lib"
    mkdir -p "$pkg/src" "$lib/src"
    printf '[package]\nname = "@w/gather"\nversion = "0.0.1"\n\n[dependencies]\n"@std/meta" = { path = "%s/packages/std-meta" }\n' "$root" >"$lib/avra.toml"
    printf 'use @std.meta.{Named, Marker}\n\nexport fn seat(_d: Named) -> Marker { Marker {} }\n\nexport type Row = { owner: string }\n\nexport type Gathered = { row: Row }\n\nexport collect rows: List<Gathered> = @seat in closure as Gathered { row: it } by it.name\n\nexport const count: int = rows.length * 10\n\nexport fn told() -> int { count }\n' >"$lib/src/gather.av"
    printf '[package]\nname = "gathered"\nversion = "0.0.1"\n\n[dependencies]\n"@std/meta" = { path = "%s/packages/std-meta" }\n"@w/gather" = { path = "../gathered-lib" }\n' "$root" >"$pkg/avra.toml"
    printf 'use @w.gather.{told, Row, seat}\n\n@seat\nexport const knob: Row = Row { owner: "knob" }\n\nprintln("${told()}")\n' >"$pkg/src/main.av"
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the gathered build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    afresh() { find "$pkg/.avra-cache" "$lib/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    says() { [ "$("$pkg/src/main")" = "$1" ] || { echo "witness_program_edit: the gathered program printed $("$pkg/src/main") $2, not $1" >&2; exit 1; }; }
    afresh
    made "$tmp/gathered.base"
    says 10 "cold"
    cp "$pkg/src/main.av" "$tmp/gathered.av"
    printf '\n@seat\nexport const lamp: Row = Row { owner: "lamp" }\n' >>"$pkg/src/main.av"
    AVRA_FOLD_CHECK=1 made "$tmp/gathered.warm"
    says 20 "warm, a member appended"
    afresh
    made "$tmp/gathered.cold"
    cmp -s "$tmp/gathered.warm" "$tmp/gathered.cold" || { echo "witness_program_edit: after a gathered member's edit the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a member gathered in closure — warm == cold, its fold read over the program's own closure"
    cp "$tmp/gathered.av" "$pkg/src/main.av"
    AVRA_FOLD_CHECK=1 made "$tmp/gathered.back"
    says 10 "warm, the member taken back"
    cmp -s "$tmp/gathered.back" "$tmp/gathered.base" || { echo "witness_program_edit: with a gathered member taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a member gathered in closure taken back — warm == cold"
}
# A derived record's edit, over a package of its own: three records each deriving one trait in one
# file, the middle one given a field. Only its site runs its generator again.
derived_edit() {
    pkg="$tmp/derived"
    mkdir -p "$pkg/src"
    printf '[package]\nname = "derived"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    printf 'use @std.meta.{Type, Directive}\n\nexport trait Count {\n    static fn derive(t: Type) -> List<Directive> {\n        [Directive { twin: "", name: t.name, at: t.at, source: quote { impl ${t} { static fn count() -> int { ${t.fields.length} } } } }]\n    }\n}\n' >"$pkg/src/count.av"
    body() { printf 'use @std.meta.{derive}\nuse count.{Count}\n\n@derive(Count)\ntype A = { a: int }\n\n@derive(Count)\ntype B = { %s }\n\n@derive(Count)\ntype C = { c: int }\n\nprintln("${A.count()} ${B.count()} ${C.count()}")\n' "$1" >"$pkg/src/main.av"; }
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the derived build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    body 'b: int'
    afresh
    made "$tmp/derived.base"
    body 'b: int, b2: int'
    AVRA_QUERY_TIMES=1 AVRA_FOLD_CHECK=1 made "$tmp/derived.warm"
    asked=$(grep -oE '(^|[ ,;])generated [0-9.]+s / [0-9.]+s \([0-9]+\)' "$tmp/log" | grep -oE '\([0-9]+\)' | tr -d '()')
    afresh
    made "$tmp/derived.cold"
    cmp -s "$tmp/derived.warm" "$tmp/derived.cold" || { echo "witness_program_edit: after a derived record's edit the warm product is not the cold one" >&2; exit 1; }
    [ "$asked" = 1 ] || { echo "witness_program_edit: one derived record's edit ran its file's generators ${asked:-no} times, not once" >&2; exit 1; }
    echo "witness_program_edit: one of three derived records — warm == cold, its generator run once"
    body 'b: int'
    AVRA_FOLD_CHECK=1 made "$tmp/derived.back"
    cmp -s "$tmp/derived.back" "$tmp/derived.base" || { echo "witness_program_edit: with a derived record's edit taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a derived record's edit taken back — warm == cold"
}
# A law's edit, over a package of its own: an impl's method renamed to a name an earlier impl of its
# type already took, so a law silent before refuses; the warm refusal must be the cold one, word for
# word, and taken back, the first cold product.
lawed_edit() {
    pkg="$tmp/lawed"
    mkdir -p "$pkg/src"
    printf '[package]\nname = "lawed"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    body() { printf 'type P = { n: int }\nimpl P {\n    fn a() -> int { self.n }\n}\nimpl P {\n    fn %s() -> int { self.n + 1 }\n}\nfn shown(p: P) -> int { p.a() }\nprintln("${shown(P { n: 1 })}")\n' "$1" >"$pkg/src/main.av"; }
    made() { "$avra" build "$pkg" >"$tmp/log" 2>&1 || { echo "witness_program_edit: the lawed build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1" ""; }
    refused() { if "$avra" build "$pkg" >"$tmp/log" 2>&1; then echo "witness_program_edit: the lawed edit was not refused" >&2; exit 1; fi; grep -v '^warning' "$tmp/log" | sed "s|$pkg|<pkg>|g" >"$1"; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    body b
    afresh
    made "$tmp/lawed.base"
    body a
    AVRA_FOLD_CHECK=1 refused "$tmp/lawed.warm"
    afresh
    refused "$tmp/lawed.cold"
    cmp -s "$tmp/lawed.warm" "$tmp/lawed.cold" || { echo "witness_program_edit: after a law's edit the warm refusal is not the cold one:" >&2; diff "$tmp/lawed.warm" "$tmp/lawed.cold" >&2; exit 1; }
    echo "witness_program_edit: an item's edit a law refuses — warm == cold"
    body b
    AVRA_FOLD_CHECK=1 made "$tmp/lawed.back"
    cmp -s "$tmp/lawed.back" "$tmp/lawed.base" || { echo "witness_program_edit: with a law's edit taken back the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: an item's edit a law refuses, taken back — warm == cold"
}
# THE PRODUCT AS COMPARED: the binary `$1` into the file `$2`. A whole binary: its
# unsigned bytes. A layered one (the dev build, `avra build`'s own unless
# AVRA_PROGRAM_MODE says `release` or `link=whole`), whose bytes name the
# directories its layers stand in, which a warm build keeps and a cold one makes
# afresh: the
# content digest of every object its package's layers link, in order, then what
# it prints and exits with for each of the remaining words (each a command line;
# empty runs it bare) — run now, while its layers stand.
digest() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; }
layered() {
    l=1
    for w in $(printf '%s' "${AVRA_PROGRAM_MODE:-}" | tr ',' ' '); do
        case $w in dev | link=layered) l=1 ;; release | link=whole) l=0 ;; esac
    done
    [ "$l" = 1 ]
}
unsigned_at() {
    bin=$1; out=$2; shift 2
    if layered; then
        built="$(dirname "$(dirname "$bin")")/.avra-cache/tapes-build"
        for k in $(for f in "$built"/layers/*/keys.txt; do cat "$f"; echo; done | sort); do
            digest < "$built/obj/$k.o"
        done > "$out"
        for words in "$@"; do
            said=0
            "$bin" $words >> "$out" 2>&1 || said=$?
            echo "exit $said" >> "$out"
        done
    else
        cp "$bin" "$out"; codesign --remove-signature "$out" 2>/dev/null || :
    fi
}

# AN INSTANCE'S CHECK READS WHAT ITS RUN CALLS, AND NOTHING IT ONLY HOLDS: a component whose `check`
# calls one fn its instance holds and holds another it never calls, both in a module of their own.
# The fn it never calls edited: the warm build is the cold one, and no instance's check is judged
# again. Taken back, the fn it calls edited: the check is judged again; edited so the check refuses,
# the warm build refuses as the cold one does.
checked_edit() {
    pkg="$tmp/checked"
    mkdir -p "$pkg/src/fns"
    printf '[package]\nname = "checked"\nversion = "0.0.1"\n' >"$pkg/avra.toml"
    fns='export fn fitting(n: int) -> bool { n >= 1 }\nexport fn unsaid(n: int) -> string { "held: ${n}" }\n'
    printf "$fns" >"$pkg/src/fns/fns.av"
    printf 'use @std.meta.{Diagnostic, refuse}\nuse fns.{fitting, unsaid}\ncomponent tray {\n    capacity: int = 1\n    fits: fn(int) -> bool = fitting\n    held: fn(int) -> string = unsaid\n    fn check() -> List<Diagnostic> { if (self.fits)(self.capacity) { [] } else { [refuse("a tray this small does not fit")] } }\n}\ntray t { capacity: 3 }\nprintln("${t.capacity}")\n' >"$pkg/src/main.av"
    built() { AVRA_QUERY_TIMES=1 "$avra" build "$pkg" >"$tmp/log" 2>&1; }
    made() { built || { echo "witness_program_edit: the checked build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1; }; unsigned_at "$pkg/src/main" "$1"; }
    judged() { grep -oE 'item_instances_checked [0-9.]+s / [0-9.]+s \([0-9]+\)' "$tmp/log" | grep -oE '[0-9]+\)$' | tr -d ')' | awk '{ n += $1 } END { print n + 0 }'; }
    afresh() { find "$pkg/.avra-cache" -mindepth 1 -delete 2>/dev/null || :; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
    afresh
    made "$tmp/checked.base"
    printf "$fns" | sed 's/held: /kept: /' >"$pkg/src/fns/fns.av"
    AVRA_FOLD_CHECK=1 made "$tmp/checked.warm"
    held=$(judged)
    afresh
    made "$tmp/checked.cold"
    cmp -s "$tmp/checked.warm" "$tmp/checked.cold" || { echo "witness_program_edit: after the held fn's edit the warm product is not the cold one" >&2; exit 1; }
    [ "$held" = 0 ] || { echo "witness_program_edit: a fn the check never calls, edited, judged $held instance checks again" >&2; exit 1; }
    echo "witness_program_edit: a fn an instance only holds, edited — warm == cold, no check judged again"
    printf "$fns" >"$pkg/src/fns/fns.av"
    made "$tmp/checked.back"
    printf "$fns" | sed 's/n >= 1 }/n >= 0 }/' >"$pkg/src/fns/fns.av"
    AVRA_FOLD_CHECK=1 made "$tmp/checked.warm"
    called=$(judged)
    [ "$called" -gt 0 ] || { echo "witness_program_edit: a fn the check calls, edited, judged no check again" >&2; exit 1; }
    printf "$fns" | sed 's/n >= 1 }/n >= 5 }/' >"$pkg/src/fns/fns.av"
    if AVRA_FOLD_CHECK=1 built; then echo "witness_program_edit: with the fn its check calls edited to refuse, the warm build kept the instance" >&2; exit 1; fi
    grep '^error' "$tmp/log" >"$tmp/checked.warm.said"
    afresh
    if built; then echo "witness_program_edit: with the fn its check calls edited to refuse, the cold build kept the instance" >&2; exit 1; fi
    grep '^error' "$tmp/log" >"$tmp/checked.cold.said"
    grep -q 'a tray this small does not fit' "$tmp/checked.cold.said" || { echo "witness_program_edit: the cold build refused otherwise:" >&2; cat "$tmp/checked.cold.said" >&2; exit 1; }
    cmp -s "$tmp/checked.warm.said" "$tmp/checked.cold.said" || { echo "witness_program_edit: the warm refusal is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a fn an instance's check calls, edited — judged again ($called), and refusing, warm == cold"
}

if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " check "; then
    checked_edit
    [ "${WITNESS_ONLY:-}" = check ] && exit 0
fi

if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " embed "; then
    embedded_edit
    [ "${WITNESS_ONLY:-}" = embed ] && exit 0
fi

if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " infer "; then
    inferred_edit
    [ "${WITNESS_ONLY:-}" = infer ] && exit 0
fi
if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " derived "; then
    derived_edit
    [ "${WITNESS_ONLY:-}" = derived ] && exit 0
fi
if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " lawed "; then
    lawed_edit
    [ "${WITNESS_ONLY:-}" = lawed ] && exit 0
fi
if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " composed "; then
    composed_edit
    [ "${WITNESS_ONLY:-}" = composed ] && exit 0
fi
if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " gathered "; then
    gathered_edit
    [ "${WITNESS_ONLY:-}" = gathered ] && exit 0
fi

stores() { find packages -name .avra-cache -type d -prune; }
cold() { for d in $(stores); do find "$d" -mindepth 1 -delete; done; find "$AVRA_CACHE_DIR" -mindepth 1 -delete; }
build() {
    if ! "$@" "$avra" build packages/cli >"$tmp/log" 2>&1; then
        echo "witness_program_edit: the build failed:" >&2; tail -5 "$tmp/log" >&2; exit 1
    fi
}
unsigned() { unsigned_at packages/cli/src/main "$1" "--help" "check packages/std-time/src/time.av"; }

# The cold product and its store, which every edit starts from; a run of the modes alone needs neither.
if [ -z "${WITNESS_ONLY:-}" ] || printf '%s\n' $WITNESS_ONLY | grep -qvE '^modes(-whole|-layered)?$'; then
    cold
    build env
    unsigned "$tmp/base"
    mkdir -p "$tmp/snap"
    for d in $(stores); do mkdir -p "$tmp/snap/$d"; cp -R "$d/." "$tmp/snap/$d/"; done
    mkdir -p "$tmp/snap-machine"
    cp -R "$AVRA_CACHE_DIR/." "$tmp/snap-machine/"
    build env
    unsigned "$tmp/again"
    cmp -s "$tmp/base" "$tmp/again" || { echo "witness_program_edit: a no-op build is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: no-op == cold"
fi

# Each part of the edit `$1`, numbered `$2`, kept aside and made.
applied() {
    printf '%s\n' "$1" | awk 'BEGIN { RS = " ;; " } { sub(/\n$/, ""); print }' > "$tmp/parts"
    k=0
    while IFS='|' read -r part line becomes; do
        k=$((k + 1))
        [ "$(grep -cxF "$line" "$part")" = 1 ] || { echo "witness_program_edit: \`$line\` is not one line of $part" >&2; exit 1; }
        cp "$part" "$tmp/orig/$2.$k.av"; printf '%s' "$part" > "$tmp/orig/$2.$k.path"
        awk -v a="$line" -v b="$becomes" '$0 == a { print b; next } { print }' "$tmp/orig/$2.$k.av" > "$part"
    done < "$tmp/parts"
}
# Each part of the edit numbered `$1` taken back.
taken_back() { for p in "$tmp"/orig/"$1".*.path; do cp "${p%.path}.av" "$(cat "$p")"; done; }

n=0
printf '%s\n' "$edits" | while read -r edit; do
    n=$((n + 1))
    if [ -n "${WITNESS_ONLY:-}" ] && ! printf ' %s ' "$WITNESS_ONLY" | grep -q " $n "; then continue; fi
    file=${edit%%|*}
    cold
    cp -R "$tmp/snap/." .
    cp -R "$tmp/snap-machine/." "$AVRA_CACHE_DIR/"
    applied "$edit" "$n"
    build env AVRA_FOLD_CHECK=1
    unsigned "$tmp/warm"
    cold
    build env
    unsigned "$tmp/cold"
    taken_back "$n"
    if ! cmp -s "$tmp/warm" "$tmp/cold"; then
        echo "witness_program_edit: after the edit of $file the warm product is not the cold one" >&2; exit 1
    fi
    if cmp -s "$tmp/cold" "$tmp/base"; then moved="the product unmoved"; else moved="the product moved"; fi
    echo "witness_program_edit: $file — warm == cold, $moved"
    build env AVRA_FOLD_CHECK=1
    unsigned "$tmp/back"
    if ! cmp -s "$tmp/back" "$tmp/base"; then
        echo "witness_program_edit: with the edit of $file taken back the warm product is not the cold one" >&2; exit 1
    fi
    echo "witness_program_edit: $file taken back — warm == cold"
done

# A METHOD'S DEFAULTED SEAT ADDED, THEN RENAMED TWICE, each built warm over the store the build
# before it left: a body renamed with its code unmoved is a body its bucket must make again, so each
# build links, and the last warm product is the cold one of the same tree.
if [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " rename "; then
    f=packages/cli/src/commands/idiom_baseline.av
    line='    fn news(findings: List<Finding>) -> List<Finding> {'
    [ "$(grep -cxF "$line" "$f")" = 1 ] || { echo "witness_program_edit: \`$line\` is not one line of $f" >&2; exit 1; }
    cp "$f" "$tmp/orig/rename.1.av"; printf '%s' "$f" > "$tmp/orig/rename.1.path"
    cold
    cp -R "$tmp/snap/." .
    cp -R "$tmp/snap-machine/." "$AVRA_CACHE_DIR/"
    for seat in most_a most_b most_c; do
        awk -v a="$line" -v b="    fn news(findings: List<Finding>, $seat: int = 0) -> List<Finding> {" '$0 == a { print b; next } { print }' "$tmp/orig/rename.1.av" > "$f"
        build env AVRA_FOLD_CHECK=1
    done
    unsigned "$tmp/renamed.warm"
    cold
    build env
    unsigned "$tmp/renamed.cold"
    cp "$tmp/orig/rename.1.av" "$f"
    cmp -s "$tmp/renamed.warm" "$tmp/renamed.cold" || { echo "witness_program_edit: after a defaulted seat renamed twice the warm product is not the cold one" >&2; exit 1; }
    echo "witness_program_edit: a method's defaulted seat added, then renamed twice — each build links, warm == cold"
fi

# A STORE IS ONE STORE WHICHEVER BUILD FILLED IT: the cli built cold in one mode, the product that
# mode must make; then that mode built over the store a build of the other mode left, that build
# working ahead on the cores or in one process alone (`AVRA_WORK_AHEAD_OFF`), and the second build
# the other way about. Each product must be the cold one: an answer one mode's build saved is the
# answer the other's would work out. `modes-whole` ends each case whole, `modes-layered` layered,
# `modes` both; `modes-whole-1` (or -2, and the same of layered) runs that mode's first (or second)
# case alone, over its own cold product, so a gate deals the cases to runners of their own.
asked_mode=${AVRA_PROGRAM_MODE-}
# The cli built as `$1` (whole or layered), alone in one process where `$2` is `alone`.
built_as() {
    case $1 in whole) AVRA_PROGRAM_MODE=release ;; layered) AVRA_PROGRAM_MODE=dev ;; esac
    export AVRA_PROGRAM_MODE
    if [ "$2" = alone ]; then build env AVRA_WORK_AHEAD_OFF=1; else build env; fi
}
# The cli's product as `$1` builds it, into `$2`.
product_as() { case $1 in whole) AVRA_PROGRAM_MODE=release ;; layered) AVRA_PROGRAM_MODE=dev ;; esac; export AVRA_PROGRAM_MODE; unsigned "$2"; }
for m in whole layered; do
    if [ -n "${WITNESS_ONLY:-}" ] && ! printf ' %s ' "$WITNESS_ONLY" | grep -qE " (modes|modes-$m|modes-$m-[12]) "; then continue; fi
    cold
    built_as $m ahead
    product_as $m "$tmp/modes.$m"
    if [ $m = whole ]; then other=layered; else other=whole; fi
    n=0
    for case in "alone ahead" "ahead alone"; do
        n=$((n + 1))
        if [ -n "${WITNESS_ONLY:-}" ] && printf ' %s ' "$WITNESS_ONLY" | grep -qE " modes-$m-[12] " &&
            ! printf ' %s ' "$WITNESS_ONLY" | grep -qE " (modes|modes-$m|modes-$m-$n) "; then continue; fi
        set -- $case
        cold
        built_as $other "$1"
        built_as $m "$2"
        product_as $m "$tmp/modes.after"
        cmp -s "$tmp/modes.after" "$tmp/modes.$m" || { echo "witness_program_edit: built $m ($2) over the store a $other build ($1) left, the product is not the cold one" >&2; exit 1; }
        echo "witness_program_edit: $m ($2) over a $other build's store ($1) — == cold"
    done
done
if [ -n "$asked_mode" ]; then AVRA_PROGRAM_MODE=$asked_mode; export AVRA_PROGRAM_MODE; else unset AVRA_PROGRAM_MODE; fi
