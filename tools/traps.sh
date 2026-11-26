#!/bin/sh
# THE TRAP CONTRACT, kept where a program test cannot hold it. A trap is a
# VERDICT (exit 2) and its words name the fault; a `<name>.refuses` program
# test holds one in both engines, on stderr alone (packages/std-avrac/src/
# compiler/tests/traps). The rows here are the rest: one engine only, words
# that span stdout and stderr, an environment the program runs under, or
# words the two engines do not share. Each row builds a program, runs it, and
# demands the exact words and the exact status.
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

# A row's package on disk. `deps` is a manifest fragment, empty for a
# row that needs none; the directory is left in `$dir` for the caller.
scaffold() {
    dir="$ROOT/$1"
    mkdir -p "$dir/src"
    printf '[package]\nname    = "zz-trap-%s"\nversion = "0.0.1"\n%s' "$1" "$2" > "$dir/avra.toml"
    printf '%s' "$3" > "$dir/src/main.av"
}

# The words and the status a row must have answered.
verdict() {
    name="$1"; want_msg="$2"; want_status="$3"; got="$4"; status="$5"
    if [ "$status" != "$want_status" ]; then
        echo "traps: $name exited $status, the contract says $want_status"
        fails=$((fails + 1))
    elif [ "$got" != "$want_msg" ]; then
        echo "traps: $name said"; echo "  $got"; echo "  the contract says"; echo "  $want_msg"
        fails=$((fails + 1))
    fi
}

# A NATIVE row. `avra build <dir>` answers the binary at <dir>/src/main.
trapped() {
    rows=$((rows + 1))
    scaffold "$1" "$4" "$5"
    if ! ./avra build "$dir" > "$dir/build.out" 2>&1; then
        echo "traps: $1 did not COMPILE"; sed -n '1,4p' "$dir/build.out"
        fails=$((fails + 1)); return
    fi
    got=$("$dir/src/main" 2>&1) && status=0 || status=$?
    verdict "$1" "$2" "$3" "$got" "$status"
}

# AN EVALUATED row (`avra run --eval`), which `trapped` cannot reach: it builds and runs a
# BINARY, so a law belonging to `avra run` — the frame that hosts a
# package's C inside the compiler's own process — has no row there at
# all. A nested watchdog's own lines are not the program's words, nor is
# the compiler's word that it waits for the last build's heir to save.
trapped_run() {
    rows=$((rows + 1))
    scaffold "$1" "$4" "$5"
    ./avra run --eval "$dir" > "$dir/run.out" 2>&1 && status=0 || status=$?
    verdict "$1" "$2" "$3" "$(grep -v -e '^watch: ' -e "^avra: waiting for the last build's save$" "$dir/run.out")" "$status"
}

trapped stale_take "avra: a take of read 1, but read 2 has landed since" 2 '
[dependencies]
"@std/net"  = { path = "../../../packages/std-net" }
"@std/time" = { path = "../../../packages/std-time" }
' 'use @std.net.{listen, connect, NetError}
use @std.time.{secs}
extern fn avra_fd_read(fd: int, max: int) -> int
extern fn avra_fd_taken(token: int) -> Bytes
extern fn avra_fiber_park_fd(fd: int, write: int, timeout: int) -> int
fn landed(fd: int) -> int {
    let _ = avra_fiber_park_fd(fd, 0, -1)
    avra_fd_read(fd, 10)
}
fn run() -> Result<int, NetError> {
    let l = listen("127.0.0.1", 0)?
    let c = connect("127.0.0.1", l.port, secs(2))?
    let s = l.accept()?
    c.try_write("a".bytes(), 0)?
    let first = landed(s.fd)
    c.try_write("b".bytes(), 0)?
    let second = landed(s.fd)
    .Ok(avra_fd_taken(first).length + second)
}
match run() {
    .Ok(n) -> "${n}",
    .Err(e) -> e.verb,
}
'
# A PACKAGE'S BARE `const char*` SEAT, which is where the rule was
# WRITTEN DOWN before it was enforced. @std/sqlite's adversarial suite
# pinned the truncation for years — text comparing equal to its own
# prefix, a longer name reading as the shorter one it hides — and
# recorded its own trigger: "a `Bytes` value, or a caller who meets
# it." The trigger fired, and the cases that ASSERTED the lie cannot
# live in a suite any more, because they end the process. They are
# here, which is what this harness is for.
#
# The seat is `sqlite3_stricmp(const char*, const char*)`: two bare
# pointers, no length, so C measures both with `strlen`. The face
# above it (`equal_nocase`) refuses these bytes with a named cause of
# its own — a library refuses before the language traps — so this
# row calls the WALL, as a package that has not thought about it
# would, and meets the floor beneath that face.
trapped nul_at_a_package_wall "avra: a string holding a NUL crossed to C as two strings — byte 2" 2 '
[dependencies]
"@std/sqlite" = { path = "../../../packages/std-sqlite" }
"@std/errors" = { path = "../../../packages/std-errors" }
"@std/text"   = { path = "../../../packages/std-text" }
' 'use @std.sqlite.c.{sqlite3_stricmp}
use @std.text.{from_codepoint}
let holed = "ab" + from_codepoint(0) + "cd"
sqlite3_stricmp(holed, "ab")
'

# A FOREIGN BODY'S WRECK IS THE PROGRAM'S VERDICT, NOT THE COMPILER'S.
# Under `avra run` a package's C is called inside the COMPILER's own
# process, so a callee that dereferences what it was handed took that
# process down with exit 139 and no words at all — a wreck no reader
# can tell from a defect of ours. A null at a host seat is how a
# program reaches it, and the null is not itself the fault: `free(null)`
# is defined and @std/sqlite hands `SQLITE_STATIC` — a null — at every
# bind seat and means it (both stand, pinned in features/fns). So the
# guard is on the FAULT, and its words name the callee and the seats
# that carried absence into it.
trapped_run null_at_a_package_seat 'avra: a foreign body faulted inside `atoi` — seat 1 was handed `null`' 2 '' 'extern fn atoi(x: string?) -> int
atoi(null)
'

# A TRAP UNDER `avra run` ENDS THE PROGRAM AS A NATIVE ONE ENDS: the lines
# printed before it stand, its words carry `avra:`, and the status is 2.
# The evaluator held every line until the program ended, so a trap took
# them all with it — and a program that never ends was never heard.
trapped_run printed_before_a_trap 'before
avra: index 5 is out of bounds (length 2)' 2 '' 'println("before")
let xs = [1, 2]
println("${xs[5]}")
'
trapped printed_before_a_trap_native 'before
avra: index 5 is out of bounds (length 2)' 2 '' 'println("before")
let xs = [1, 2]
println("${xs[5]}")
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
' 'use @std.sqlite.open.{Db}
use @std.sqlite.stmt.{Stmt, run}
use @std.sqlite.error.{SqlError}

extern fn avra_trap(message: string)
extern fn avra_selfhost_argc() -> int
extern fn avra_selfhost_get_arg_cstr(i: int) -> string
extern fn avra_spawn_status(prog: string, args: List<string>) -> int

fn db_path() -> string { "build/traps/tx_hot_journal.db" }

/// The half that dies: one row committed, a transaction opened, two more
/// written, and the process gone with the transaction standing.
fn wrote() -> Result<int, SqlError> {
    mut db = Db.open(db_path())?
    let _ = run(db, "drop table if exists t")?
    let _ = run(db, "create table t (n int)")?
    let _ = run(db, "insert into t values (1)")?
    let _ = db.begin()?
    let _ = run(db, "insert into t values (2)")?
    let _ = run(db, "insert into t values (3)")?
    let xs = [0]
    xs[5]
}

/// The half that reads what the other half left behind.
fn counted() -> Result<int, SqlError> {
    mut db = Db.open(db_path())?
    mut s = db.prepare("select count(*) from t")?
    let n = read_one(s)?
    let _ = s.finalize()
    let _ = db.close()
    n
}

fn read_one(mut s: Stmt) -> Result<int, SqlError> {
    let _ = s.step()?
    s.int_at(0)?
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

# THE MEMORY CEILING, in both engines. A program that allocates forever
# ends as a wreck at AVRA_MEM_CEILING_MB, never as the machine's. Native:
# the program's own runtime counts it. Evaluated: the compiler's runtime
# counts the values it holds for the program, so the same words end it.
FOREVER='mut xs: List<string> = []
while true { xs.push("${xs.length} and more text to fill the box") }
xs.length'
rows=$((rows + 1))
scaffold ceiling_native '' "$FOREVER"
if ./avra build "$dir" > "$dir/build.out" 2>&1; then
    got=$(AVRA_MEM_CEILING_MB=64 "$dir/src/main" 2>&1) && status=0 || status=$?
    verdict ceiling_native "avra: memory ceiling exceeded: 64 MB (AVRA_MEM_CEILING_MB)" 2 "$got" "$status"
else
    echo "traps: ceiling_native did not COMPILE"; sed -n '1,4p' "$dir/build.out"; fails=$((fails + 1))
fi
rows=$((rows + 1))
scaffold ceiling_run '' "$FOREVER"
AVRA_MEM_CEILING_MB=512 ./avra run "$dir" > "$dir/run.out" 2>&1 && status=0 || status=$?
verdict ceiling_run "avra: memory ceiling exceeded: 512 MB (AVRA_MEM_CEILING_MB)" 2 "$(grep -v '^watch: ' "$dir/run.out")" "$status"

# A CHILD CARRIES THE CEILING: the variable is inherited, so a process a
# program spawns meets the same ceiling in its own runtime, and a server
# or worker cannot outlive the cap its parent was started under.
rows=$((rows + 1))
scaffold ceiling_child '' 'extern fn avra_selfhost_argc() -> int
extern fn avra_selfhost_get_arg_cstr(i: int) -> string
extern fn avra_spawn_status(prog: string, args: List<string>) -> int
mut xs: List<string> = []
if avra_selfhost_argc() > 1 {
    while true { xs.push("${xs.length} and more text to fill the box") }
}
println("child exited ${avra_spawn_status(avra_selfhost_get_arg_cstr(0), ["child"])}")
'
if ./avra build "$dir" > "$dir/build.out" 2>&1; then
    got=$(AVRA_MEM_CEILING_MB=64 "$dir/src/main" 2>&1) && status=0 || status=$?
    verdict ceiling_child "avra: memory ceiling exceeded: 64 MB (AVRA_MEM_CEILING_MB)
child exited 2" 0 "$got" "$status"
else
    echo "traps: ceiling_child did not COMPILE"; sed -n '1,4p' "$dir/build.out"; fails=$((fails + 1))
fi

rm -rf "$ROOT"
if [ "$fails" -gt 0 ]; then
    echo "traps: $fails of $rows contracts broken"
    exit 1
fi
echo "traps: $rows contracts held"
