#!/bin/sh
# A QUERY'S ANSWER IS STALE WHEN ITS CODE MOVES, AND ONLY THEN. Each
# case is one program whose `@query` reaches a leaf by one path. It is
# built and run to keep its answer, its leaf is edited so the answer
# changes, and it is built and run again over the same records: the
# answer must be the edited one, computed afresh. A control edits a fn
# the query never reaches: its answer must still be read back, so a
# store that never answers cannot pass.
#
#   sh tools/code_hash_attacks.sh
set -u
cd "$(dirname "$0")/.."
A=$(pwd)/avra
R=build/code-hash-attacks; fails=0; cases=0
rm -rf "$R" && mkdir -p "$R"

# One program: the leaf's value, the path's declarations, the query's body,
# and what the program does before it asks.
program() {
    cat <<AV
use @std.relation.{query}
use @std.relation.db.{Db, Durable, durable_db}
use @std.io.{read_bytes, write_bytes, make_dirs, env_or}

fn dir() -> string { env_or("QH_STORE", "") }

fn path(q: string, a: int) -> string { "\${dir()}/\${q}-\${a}" }

fn read_record(q: string, a: int) -> Bytes? {
    match read_bytes(path(q, a)) { .Ok(b) -> b, .Err(_) -> null }
}

fn keep_record(q: string, a: int, record: Bytes) {
    let _ = make_dirs(dir())
    let _ = write_bytes(path(q, a), record)
}

once fn computes() -> Cell<int> { Cell.new(0) }

fn unrelated() -> int { $2 }

$3

@query
fn answer(_db: Db) -> int {
    let c = computes()
    c.set(c.get() + 1)
    $4
}

$5
let db = durable_db(Durable { answer: read_record, keep: keep_record })
println("answer=\${answer(db)} computed=\${computes().get()} unrelated=\${unrelated()}")
AV
}

# The path's own words, by name: declarations, the query's body, the setup.
decls() {
    case $1 in
    direct) echo "fn leaf() -> int { $2 }" ;;
    closure) printf 'type Held = { f: fn() -> int }\n\nonce fn held() -> Held { Held { f: () -> %s } }\n' "$2" ;;
    passed) printf 'fn leaf() -> int { %s }\n\nonce fn slot() -> Cell<fn() -> int> { Cell.new(zero) }\n\nfn zero() -> int { 0 }\n' "$2" ;;
    dyn) printf 'trait Valued { fn v() -> int }\n\ntype A = { n: int }\n\nimpl Valued for A { fn v() -> int { %s } }\n\nonce fn chosen() -> Cell<dyn Valued?> {\n    let none: dyn Valued? = null\n    Cell.new(none)\n}\n' "$2" ;;
    generic) echo "fn scaled<T>(_x: T) -> int { $2 }" ;;
    const) echo "const TABLE: List<int> = [$2, 7]" ;;
    esac
}
body() {
    case $1 in
    direct) echo "leaf()" ;;
    closure) echo "held().f()" ;;
    passed) echo "slot().get()()" ;;
    dyn) echo "chosen().get()?.v() ?? 0" ;;
    generic) echo "scaled(\"x\")" ;;
    const) echo "TABLE[0]" ;;
    esac
}
setup() {
    case $1 in
    passed) echo "slot().set(leaf)" ;;
    dyn) printf 'let a: dyn Valued = A { n: 1 }\nchosen().set(a)\n' ;;
    *) echo "" ;;
    esac
}

# The path's own names renamed — what reaches the leaf, and nothing it does.
renamed() {
    case $1 in
    direct | passed) sed -e 's/leaf(/leaf_renamed(/g' -e 's/(leaf)/(leaf_renamed)/g' ;;
    closure) sed 's/held(/held_renamed(/g' ;;
    dyn) sed -e 's/fn v()/fn worth()/g' -e 's/\.v()/.worth()/g' ;;
    generic) sed 's/scaled/scaled_renamed/g' ;;
    const) sed 's/TABLE/TABLE_RENAMED/g' ;;
    esac
}

# Build `$1` for path `$2` with leaf `$3` and unrelated `$4`, its names
# renamed when `$6` says so; run it over store `$5`.
ran() {
    mkdir -p "$R/$1/src"
    printf '[package]\nname = "qh-%s"\nversion = "0.1.0"\n' "$1" > "$R/$1/avra.toml"
    program "$2" "$4" "$(decls "$2" "$3")" "$(body "$2")" "$(setup "$2")" > "$R/$1/src/main.v0"
    if [ "${6:-}" = renamed ]; then renamed "$2" < "$R/$1/src/main.v0" > "$R/$1/src/main.av"; else cp "$R/$1/src/main.v0" "$R/$1/src/main.av"; fi
    "$A" build "$R/$1" > "$R/$1.build" 2>&1 || { echo "BUILD FAILED"; return; }
    QH_STORE="$5" "$R/$1/src/main"
}

# CODE_HASH_ATTACKS names the one group to run: a path, or `held`.
for path in ${CODE_HASH_ATTACKS:-direct closure passed dyn generic const}; do
    case $path in held | held-dyn) continue ;; esac
    cases=$((cases + 1))
    store=$(pwd)/$R/store-$path
    kept=$(ran $path-v1 $path 1 0 "$store")
    edited=$(ran $path-v2 $path 2 0 "$store")
    cold=$(ran $path-cold $path 2 0 "$(pwd)/$R/cold-$path")
    if [ "$kept" != "answer=1 computed=1 unrelated=0" ]; then
        fails=$((fails + 1)); echo "code-hash-attacks: FAILED — $path: the first run answered '$kept'"
    elif [ "$edited" != "$cold" ]; then
        fails=$((fails + 1)); echo "code-hash-attacks: FAILED — $path: after its leaf moved the query answered '$edited', cold answers '$cold'"
    else
        echo "code-hash-attacks: $path — an edited leaf is computed afresh"
    fi
    # The control: an edit the query never reaches keeps the record.
    control=$(ran $path-ctl $path 1 9 "$store")
    case $control in
    *"computed=0 unrelated=9") echo "code-hash-attacks: $path — an unreached edit reads the record back" ;;
    *) fails=$((fails + 1)); echo "code-hash-attacks: FAILED — $path: an edit the query never reaches recomputed it ('$control')" ;;
    esac
    # A rename moves no code: its record is read back.
    fresh=$(pwd)/$R/rename-$path
    first=$(ran $path-rn1 $path 1 0 "$fresh")
    again=$(ran $path-rn2 $path 1 0 "$fresh" renamed)
    case $again in
    "answer=1 computed=0 unrelated=0") echo "code-hash-attacks: $path — a rename reads the record back" ;;
    *) fails=$((fails + 1)); echo "code-hash-attacks: FAILED — $path: a rename recomputed it ('$first' then '$again')" ;;
    esac
done

# A HELD FILE STANDS IN WITH ITS CODE. One package of three files, built
# in place, so an unchanged file is held from the build before: an edit
# the query never reaches holds the query's own file and must read the
# record back; an edit to its leaf's file must compute afresh.
H=$R/held
held_build() {
    mkdir -p "$H/src"
    printf '[package]\nname = "qh-held"\nversion = "0.1.0"\n' > "$H/avra.toml"
    { printf 'use leaf.{leaf}\nuse other.{shown}\n'; program x "$2" "" "leaf()" "" | sed 's/^println("answer=/println(shown() + " answer=/'; } > "$H/src/main.av"
    printf 'export fn leaf() -> int { %s }\n' "$1" > "$H/src/leaf.av"
    printf 'export fn shown() -> string { "%s" }\n' "$3" > "$H/src/other.av"
    "$A" build "$H" > "$H.build" 2>&1 || { echo "BUILD FAILED"; return; }
    QH_STORE="$(pwd)/$R/store-held" "$H/src/main"
}
case " ${CODE_HASH_ATTACKS:-held} " in *" held "*)
cases=$((cases + 1))
first=$(held_build 1 0 a)
quiet=$(held_build 1 0 b)
moved=$(held_build 2 0 b)
case "$first|$quiet|$moved" in
"a answer=1 computed=1 unrelated=0|b answer=1 computed=0 unrelated=0|b answer=2 computed=1 unrelated=0")
    echo "code-hash-attacks: held — a held query reads its record back, and its leaf's edit is computed afresh" ;;
*)
    fails=$((fails + 1)); echo "code-hash-attacks: FAILED — held: '$first' then '$quiet' then '$moved'" ;;
esac
;; esac

# A HELD FILE'S FN VALUES COUNT. The dyn value is made in one file and its
# impl lives in another: an edit to the impl holds the maker's file, whose
# vtable is the only address of the edited method — the hash must move. A
# rebuild with nothing edited must read the record back first, so a store
# that never answers cannot pass; then the query's own file is edited where
# the query never reaches, the maker and the impl held, and the record still
# stands.
D=$R/held-dyn
dyn_build() {
    mkdir -p "$D/src"
    printf '[package]\nname = "qh-held-dyn"\nversion = "0.1.0"\n' > "$D/avra.toml"
    { printf 'use valued.{Valued, chosen}\nuse maker.{make}\n'; program x "${2:-0}" "" "chosen().get()?.v() ?? 0" "make()"; } > "$D/src/main.av"
    printf 'export trait Valued { fn v() -> int }\n\nexport once fn chosen() -> Cell<dyn Valued?> {\n    let none: dyn Valued? = null\n    Cell.new(none)\n}\n' > "$D/src/valued.av"
    printf 'use valued.{Valued, chosen}\nuse impl.{A}\n\nexport fn make() {\n    let a: dyn Valued = A { n: 1 }\n    chosen().set(a)\n}\n' > "$D/src/maker.av"
    printf 'use valued.{Valued}\n\nexport type A = { n: int }\n\nimpl Valued for A { fn v() -> int { %s } }\n' "$1" > "$D/src/impl.av"
    "$A" build "$D" > "$D.build" 2>&1 || { echo "BUILD FAILED"; return; }
    QH_STORE="$(pwd)/$R/store-held-dyn" "$D/src/main"
}
case " ${CODE_HASH_ATTACKS:-held-dyn} " in *" held-dyn "*)
cases=$((cases + 1))
first=$(dyn_build 1)
again=$(dyn_build 1)
own=$(dyn_build 1 9)
moved=$(dyn_build 2 9)
case "$first|$again|$own|$moved" in
"answer=1 computed=1 unrelated=0|answer=1 computed=0 unrelated=0|answer=1 computed=0 unrelated=9|answer=2 computed=1 unrelated=9")
    echo "code-hash-attacks: held-dyn — an impl edited behind a held maker's vtable is computed afresh" ;;
*)
    fails=$((fails + 1)); echo "code-hash-attacks: FAILED — held-dyn: '$first' then '$again' then '$own' then '$moved'" ;;
esac
;; esac

echo "code-hash-attacks: $cases path(s), $fails failure(s)"
[ "$fails" = 0 ]
