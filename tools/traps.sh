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

# AN EVALUATED row, which `trapped` cannot reach: it builds and runs a
# BINARY, so a law belonging to `avra run` — the frame that hosts a
# package's C inside the compiler's own process — has no row there at
# all. A nested watchdog's own lines are not the program's words.
trapped_run() {
    rows=$((rows + 1))
    scaffold "$1" "$4" "$5"
    ./avra run "$dir" > "$dir/run.out" 2>&1 && status=0 || status=$?
    verdict "$1" "$2" "$3" "$(grep -v '^watch: ' "$dir/run.out")" "$status"
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
trapped bytes_at "avra: index 3 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.at(3)
'
trapped bytes_slice "avra: slice 2..4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
let s = b.slice(2, 4)
s.length
'
trapped bytes_from "avra: index 4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.index_of([2].bytes()!, 4)
'
trapped bytes_table "avra: a class table holds 256 bytes (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.run(0, b)
'
trapped bytes_eq_at "avra: slice 1..4 is out of bounds (length 3)" 2 '' 'let b = [1, 2, 3].bytes()!
b.eq_at(1, 4, b)
'
trapped take_at_eof "avra: a take at EOF — \`read\` answered 0, which names no bytes" 2 '' 'extern fn avra_fd_taken(token: int) -> Bytes
avra_fd_taken(0).length
'
trapped take_of_error "avra: a take of an error — \`read\` answered -35, not a token" 2 '' 'extern fn avra_fd_taken(token: int) -> Bytes
avra_fd_taken(-35).length
'
# A STRING CROSSING TO C IS ONE STRING. Avra measures text by the
# header and C reads to the first NUL, so a string holding one is TWO
# VALUES at the seam — a name that was checked is not the name that is
# used. Every mature runtime refuses rather than truncates; ours traps
# with the OFFSET, and the same helper is called by the extern frame,
# so the two engines cannot disagree about which strings may cross.
#
# THREE POSITIONS, because a scan that stops early passes one of them:
# a NUL first, last and inside. "Last" is inside the LENGTH — a
# five-byte string ending in NUL is four bytes to C and five to the
# program, which is the same two values.
trapped nul_crossing_first "avra: a string holding a NUL crossed to C as two strings — byte 0" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_host_env(name: string) -> string
let s = avra_str_from_codepoint(0) + "PATH"
avra_host_env(s).length'

trapped nul_crossing_inside "avra: a string holding a NUL crossed to C as two strings — byte 2" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_host_env(name: string) -> string
let s = "PA" + avra_str_from_codepoint(0) + "TH"
avra_host_env(s).length'

trapped nul_crossing_last "avra: a string holding a NUL crossed to C as two strings — byte 4" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_host_env(name: string) -> string
let s = "PATH" + avra_str_from_codepoint(0)
avra_host_env(s).length'

# THE FOURTH POSITION IS NOT WHERE THE NUL SITS — IT IS WHICH BOX
# CARRIES IT. A row's seat kind is `Ptr`, which a string and a `Bytes`
# both fill, so the same bytes spelled `Bytes` reach the same
# `getenv`. The exemption a `Bytes` wears is EARNED BY THE CALLEE
# KNOWING THE LENGTH — a blob and its `n` — and CORE's name-resolving
# rows carry no length at all, so there the octets mean a PREFIX of
# themselves exactly as text does. Three positions of the NUL were
# attacked above and this axis was not, so `avra_host_env` read a
# different variable and `avra_spawn_status` ran a different program,
# each with the guard one spelling away.
trapped nul_crossing_bytes "avra: a string holding a NUL crossed to C as two strings — byte 2" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_host_env(name: Bytes) -> string
let s = ("PA" + avra_str_from_codepoint(0) + "TH").bytes()
avra_host_env(s).length'

trapped nul_crossing_bytes_prog "avra: a string holding a NUL crossed to C as two strings — byte 13" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_spawn_status(prog: Bytes, args: List<string>) -> int
let prog = ("/usr/bin/true" + avra_str_from_codepoint(0) + "/evil").bytes()
avra_spawn_status(prog, [])'

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

# A WORD INSIDE A LIST, which the per-SEAT check cannot see. The seam
# checks a seat, and a `List<string>` seat is a pointer to a BOX — so
# every word inside it crosses unexamined while the host RESOLVES each
# one. `avra_spawn_status` and `avra_exec_self` are ROWS for that
# reason (their C reads an `AvraArray`, which §2.1 makes core's), and
# their C bodies check each word at the crossing itself.
#
# THE CHILD IS `/bin/echo` DELIBERATELY: `avra_exec_self` is the same
# law and cannot be a row here, because a program that re-execs ITSELF
# with a word the check no longer refuses would loop. A contract whose
# regression is a fork bomb does not belong in a harness.
trapped nul_in_a_spawned_word "avra: a string holding a NUL crossed to C as two strings — byte 1" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
extern fn avra_spawn_status(prog: string, args: List<string>) -> int
avra_spawn_status("/bin/echo", ["a" + avra_str_from_codepoint(0) + "b"])'

# AND THE EXEMPTION IS NOT A HOLE: an INERT row reads the bytes it was
# handed and resolves nothing, so a NUL rides through it untouched —
# the trap here is the BOUNDS one, reached only because the string
# carried all five of its bytes past `join`, `length` and `char_code`.
trapped nul_through_inert "avra: index 9 is out of bounds (length 5)" 2 '' 'extern fn avra_str_from_codepoint(code: int) -> string
let s = "ab" + avra_str_from_codepoint(0) + "cd"
let joined = ["x", s].join("|")
let codes = [s.char_code(i) for i in 0..s.length]
codes[9]'

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
