#!/bin/sh
# A ROW'S STAMP MOVES WITH THE PRODUCER'S REAL CODE HASH. One tiny program files a
# row under `producer_of([code_hash(producer)])` in a store, is built, run to keep the row,
# edited and built again, and run over the same store from a compiler of ANOTHER print.
# A control edits a fn the producer never reaches: the row must still be read, so a store
# that never answers cannot pass. A leaf the producer reaches moves its hash: no read.
#
#   sh tools/stamp_attack.sh
set -u
cd "$(dirname "$0")/.."
A=$(pwd)/avra
R=build/stamp-attack; fails=0; cases=0
rm -rf "$R" && mkdir -p "$R"

# Build `$1` with leaf `$2` and unrelated `$3`; run it as print `$5` in store `$4`, keeping
# the row first when `$6` says write.
ran() {
    mkdir -p "$R/$1/src"
    printf '[package]\nname = "sa-%s"\nversion = "0.1.0"\n' "$1" > "$R/$1/avra.toml"
    cat > "$R/$1/src/main.av" <<AV
use @std.avrac.compiler.store.{Keeping, Producers, Stored, node_key, producer_of, store_stamped}
use @std.meta.{code_hash}
use @std.io.{env_or}

fn leaf() -> int { $2 }

fn unrelated() -> int { $3 }

fn producer() -> int { leaf() + 1 }

let store = store_stamped(
    env_or("SA_STORE", ""),
    env_or("SA_PRINT", ""),
    Producers { sig: producer_of([code_hash(producer)]) },
    Keeping.Disk,
)
let key = node_key(Stored.Sig, ["m"])
if env_or("SA_MODE", "") == "write" { let _ = store.keep(Stored.Sig, key, "record", []) }
println("read=\${store.get(Stored.Sig, key) ?? "none"} unrelated=\${unrelated()}")
AV
    "$A" build "$R/$1" > "$R/$1.build" 2>&1 || { echo "BUILD FAILED"; return; }
    SA_STORE="$4" SA_PRINT="$5" SA_MODE="${6:-read}" "$R/$1/src/main"
}

store=$(pwd)/$R/store
check() {
    cases=$((cases + 1))
    if [ "$2" = "$3" ]; then echo "stamp-attack: $1"; else fails=$((fails + 1)); echo "stamp-attack: FAILED — $1: '$2', wanted '$3'"; fi
}
check "the first run keeps its row" "$(ran v1 1 0 "$store" print-a write)" "read=record unrelated=0"
check "the same producer under another print reads the row" "$(ran v1b 1 0 "$store" print-b)" "read=record unrelated=0"
check "an edit the producer never reaches still reads the row" "$(ran ctl 1 9 "$store" print-b)" "read=record unrelated=9"
check "a leaf the producer reaches moves its hash: the row is not read" "$(ran v2 2 0 "$store" print-b)" "read=none unrelated=0"
check "the edited producer reads the rows it files itself" "$(ran v2w 2 0 "$store" print-b write)" "read=record unrelated=0"

[ $fails -eq 0 ] || { echo "stamp-attack: $fails of $cases FAILED"; exit 1; }
echo "stamp-attack: $cases cases passed"
