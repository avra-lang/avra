#!/bin/sh
# THE TRAP CONTRACT, kept. A trap is a VERDICT (exit 2) and its words
# name the fault — laws no program test can hold, because a suite
# runs every program in one process and a trap ends it. Each row builds
# a program, runs it, and demands the exact words and the exact status.
#
# A ROW IS A PACKAGE, NEVER A BARE FILE. A bare file cannot `use` one
# — F3015, "this file is not in a package" — so a bare-file harness
# reaches only contracts that touch no package, which is half the
# tree and not the half where a driver holds a transaction open. The
# package is scaffolded under build/, so a dependency path climbs to
# `packages/`, and the whole directory is swept at the end.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

ROOT=build/traps
fails=0
rows=0

# `deps` is a manifest fragment, empty for a row that needs none.
# `avra build <dir>` answers the binary at <dir>/src/main.
trapped() {
    name="$1"; want_msg="$2"; want_status="$3"; deps="$4"; src="$5"
    rows=$((rows + 1))
    dir="$ROOT/$name"
    mkdir -p "$dir/src"
    printf '[package]\nname    = "zz-trap-%s"\nversion = "0.0.1"\n%s' "$name" "$deps" > "$dir/avra.toml"
    printf '%s' "$src" > "$dir/src/main.av"
    if ! ./avra build "$dir" > "$dir/build.out" 2>&1; then
        echo "traps: $name did not COMPILE"; sed -n '1,4p' "$dir/build.out"
        fails=$((fails + 1)); return
    fi
    got=$("$dir/src/main" 2>&1) && status=0 || status=$?
    if [ "$status" != "$want_status" ]; then
        echo "traps: $name exited $status, the contract says $want_status"
        fails=$((fails + 1))
    elif [ "$got" != "$want_msg" ]; then
        echo "traps: $name said"; echo "  $got"; echo "  the contract says"; echo "  $want_msg"
        fails=$((fails + 1))
    fi
}

trapped past_end "avra: index 3 is out of bounds (length 3)" 2 '' 'let xs = [1, 2, 3]
xs[3]
'
trapped negative "avra: index -1 is out of bounds (length 3)" 2 '' 'let xs = [1, 2, 3]
mut i = 0
i = i - 1
xs[i]
'
trapped empty "avra: index 0 is out of bounds (length 0)" 2 '' 'let xs: List<int> = []
xs[0]
'
# A SHIFT COUNT the compiler cannot read. A literal one is refused
# where it is written (F2057); this is its twin — the count arrives at
# run time, so one C body decides the edge and BOTH engines call it.
# The words name the LAW, never the mechanism that would enforce it.
trapped shift_wide "avra: a shift count must be between 0 and 63" 2 '' 'let a = 1
mut n = 0
n = n + 64
a << n
'
trapped shift_negative "avra: a shift count must be between 0 and 63" 2 '' 'let a = 1
mut n = 0
n = n - 1
a >> n
'

# A trap raised with a PACKAGE in use is still a verdict — the row
# that proves this harness reaches past a bare file, so the capability
# is exercised rather than merely available.
trapped in_package "avra: index 5 is out of bounds (length 1)" 2 '
[dependencies]
"@std/text" = { path = "../../../packages/std-text" }
' 'use @std.text.{from_codepoint}
let a = from_codepoint(65)
let xs = [a]
xs[5]
'

# HAZARD 4: A PROCESS THAT DIES INSIDE A TRANSACTION. `avra_trap` exits
# 2 with no unwinding — no `defer`, no ROLLBACK — so what survives a
# half-written transaction is SQLITE's guarantee and not a driver's, and
# the only way to witness it is to kill a process holding one.
#
# ONE ROW, TWO PROCESSES: the program SPAWNS ITSELF with a word, and the
# child is the half that dies. Both halves are one artifact, the row is
# self-contained and order-independent like every other row here, and it
# TRAPS BY CONSTRUCTION — the recovered row count rides the trap's own
# words, so a recovery that yields 3 fails with the number printed.
trapped tx_hot_journal "avra: index 5 is out of bounds (length 1)
avra: the writer exited 2, and of the 3 rows it wrote the database kept 1" 2 '
[dependencies]
"@std/sqlite" = { path = "../../../packages/std-sqlite" }
' 'use @std.sqlite.open.{Db, open, close}
use @std.sqlite.stmt.{Stmt, run, prepare, step, finalize, int_at}
use @std.sqlite.tx.{begin}
use @std.sqlite.error.{SqlError}

extern fn avra_trap(message: string)
extern fn avra_selfhost_argc() -> int
extern fn avra_selfhost_get_arg_cstr(i: int) -> string
extern fn avra_spawn_status(prog: string, args: List<string>) -> int

fn db_path() -> string { "build/traps/tx_hot_journal.db" }

/// The half that dies: one row committed, a transaction opened, two more
/// written, and the process gone with the transaction standing.
fn wrote() -> Result<int, SqlError> {
    mut db = open(db_path())?
    let _ = run(db, "drop table if exists t")?
    let _ = run(db, "create table t (n int)")?
    let _ = run(db, "insert into t values (1)")?
    let _ = begin(db)?
    let _ = run(db, "insert into t values (2)")?
    let _ = run(db, "insert into t values (3)")?
    let xs = [0]
    xs[5]
}

/// The half that reads what the other half left behind.
fn counted() -> Result<int, SqlError> {
    mut db = open(db_path())?
    mut s = prepare(db, "select count(*) from t")?
    let n = read_one(s)?
    let _ = finalize(s)
    let _ = close(db)
    n
}

fn read_one(mut s: Stmt) -> Result<int, SqlError> {
    let _ = step(s)?
    int_at(s, 0)?
}

fn said(r: Result<int, SqlError>) -> string {
    match r {
        .Ok(n) -> "${n}",
        .Err(e) -> "FAILED ${e.cause.kind()}",
    }
}

fn story() -> string {
    if avra_selfhost_argc() > 1 { return said(wrote()) }
    let rc = avra_spawn_status(avra_selfhost_get_arg_cstr(0), ["child"])
    let kept = said(counted())
    avra_trap("the writer exited ${rc}, and of the 3 rows it wrote the database kept ${kept}")
    "the trap above never returns"
}

story()
'

rm -rf "$ROOT"
if [ "$fails" -gt 0 ]; then
    echo "traps: $fails of $rows contracts broken"
    exit 1
fi
echo "traps: $rows contracts held"
