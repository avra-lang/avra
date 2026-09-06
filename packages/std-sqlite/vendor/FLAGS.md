# The vendored SQLite, and the flags it is compiled with

SQLite 3.53.4, the official amalgamation, one translation unit.
`README.md` beside the package carries the version, the URL and the
checksums; this file carries the flag set and the reason for each flag.

**THE FLAG SET IS A TESTABLE ARTIFACT.** Every line below is observable at
runtime through `sqlite3_compileoption_used(name)` — measured: 31 asked, 0
not observable. The driver's first corpus program asserts the whole list,
which turns "compiled with our flags" from a build-file claim into a gate.

Compile:

```
clang -c -O2 <the flags below> vendor/sqlite3.c -o build/sqlite3.o
```

Measured on Apple clang 21.0.0, arm64-apple-darwin25.5.0:
**12.5 s, 2 182 536 bytes, 357 exported `sqlite3_*` text symbols**, no
warnings. Link needs `-lm` and `-lpthread` on Linux/BSD; on darwin both live
in libSystem and the object links with neither (measured). They stay in the
manifest's `[link] flags` because they cost nothing here and are required
elsewhere.

---

## Surface — everything the campaign calls "full"

| Flag | Reason |
|---|---|
| `-DSQLITE_ENABLE_COLUMN_METADATA=1` | the 6 origin-name fns; the ORM maps a result column back to its table and column |
| `-DSQLITE_ENABLE_PREUPDATE_HOOK=1` | the 6 preupdate fns, and SESSION does not compile without it |
| `-DSQLITE_ENABLE_SESSION=1` | the 49 session/changeset fns |
| `-DSQLITE_ENABLE_SNAPSHOT=1` | the 5 snapshot fns |
| `-DSQLITE_ENABLE_NORMALIZE=1` | `sqlite3_normalized_sql` — a statement's shape without its literals |
| `-DSQLITE_ENABLE_STMT_SCANSTATUS=1` | per-loop query profiling |
| `-DSQLITE_ENABLE_UNLOCK_NOTIFY=1` | `sqlite3_unlock_notify` |
| `-DSQLITE_ENABLE_FTS5=1` | full-text search; SQL vtab plus the `fts5_api` handshake |
| `-DSQLITE_ENABLE_RTREE=1` | R*Tree index and its 2 C registrars |
| `-DSQLITE_ENABLE_GEOPOLY=1` | polygon queries; implies RTREE |
| `-DSQLITE_ENABLE_MATH_FUNCTIONS=1` | `ceil`/`floor`/`pow`/`log`/trig; every one answers REAL |
| `-DSQLITE_ENABLE_DBSTAT_VTAB=1` | `dbstat` — per-page storage introspection |
| `-DSQLITE_ENABLE_DBPAGE_VTAB=1` | `sqlite_dbpage` — raw page access |
| `-DSQLITE_ENABLE_BYTECODE_VTAB=1` | `bytecode()`/`tables_used()`; a query's plan as rows (P7) |
| `-DSQLITE_ENABLE_STAT4=1` | query-planner histograms |
| `-DSQLITE_ENABLE_EXPLAIN_COMMENTS=1` | readable `EXPLAIN` output (P7) |
| `-DSQLITE_ENABLE_OFFSET_SQL_FUNC=1` | `sqlite_offset()` |

Deserialize and JSON take **no flag**: both are on unless omitted
(`#ifndef SQLITE_OMIT_DESERIALIZE`, verified in the vendored source;
`SQLITE_ENABLE_DESERIALIZE` does not appear in 3.53.4 at all). Setting
`SQLITE_OMIT_DESERIALIZE` or `SQLITE_OMIT_JSON` would remove them.

## Correctness and safety

| Flag | Reason |
|---|---|
| `-DSQLITE_DQS=0` | a double-quoted string is an IDENTIFIER, never a string literal — the misfeature off at the source |
| `-DSQLITE_ENABLE_API_ARMOR=1` | every argument crossing the wall is validated |
| `-DSQLITE_LIKE_DOESNT_MATCH_BLOBS=1` | `LIKE`/`GLOB` answer false on BLOBs instead of coercing |
| `-DSQLITE_STRICT_SUBTYPE=1` | a subtype misuse is an error, not a silent result |
| `-DSQLITE_DEFAULT_FOREIGN_KEYS=1` | FKs enforced without a PRAGMA; off by default in SQLite for compatibility alone |
| `-DSQLITE_THREADSAFE=1` | serialized — a connection carries its own mutex (P2) |
| ~~`-DSQLITE_USE_URI=1`~~ | **REMOVED — see below.** URI parsing is now off at compile time and `SQLITE_OPEN_URI` turns it on per connection |
| `-DSQLITE_MAX_EXPR_DEPTH=1000` | the expression-tree height check stays ON — see the divergence below |

## Speed

| Flag | Reason |
|---|---|
| `-DSQLITE_DEFAULT_MEMSTATUS=0` | the per-allocation memory counters off; `sqlite3_status` memory figures go with them — **and so does heap-limit ENFORCEMENT**: `sqlite3_soft_heap_limit64`/`hard_heap_limit64` still store and report a limit, and never apply it (measured: 8 MB allocated under a 100 KB hard limit). The two declarations say so at their own site. |
| `-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1` | NORMAL under WAL, which is durable and materially faster than FULL |
| `-DSQLITE_DEFAULT_MMAP_SIZE=268435456` | 256 MB memory-mapped read window |
| `-DSQLITE_MAX_MMAP_SIZE=1099511627776` | the ceiling a connection may raise `PRAGMA mmap_size` to |
| `-DSQLITE_DEFAULT_CACHE_SIZE=-8000` | 8 MB page cache (negative is KiB) |
| `-DSQLITE_DEFAULT_WORKER_THREADS=0` | deterministic sorts; a connection raises it when it wants them |
| `-DNDEBUG=1` | `assert()` off; SQLite is built and tested this way |
| `-O2` | not `-O3` — upstream tests at `-O2` |

---

## The two divergences from the research report, each measured

The api_surface research report recommends `SQLITE_OMIT_AUTOINIT=1` and
`SQLITE_MAX_EXPR_DEPTH=0`, both from sqlite.org's "Recommended Compile-time
Options". Both were compiled and run. **Each turns a caller's mistake into a
segmentation fault**, which this tree's law refuses: a trap is not a verdict.

### `SQLITE_OMIT_AUTOINIT` — REJECTED

It makes `sqlite3_initialize()` mandatory. A first call that forgets it does
not answer `SQLITE_MISUSE`; it crashes, and `SQLITE_ENABLE_API_ARMOR` does
not catch it.

```
=== with -DSQLITE_OMIT_AUTOINIT=1 ===
A: version 3.53.4 (3053004)
C: about to open_v2
exit=139                              <- SIGSEGV, no diagnostic

=== same binary, sqlite3_initialize() called first ===
A: version 3.53.4 (3053004)
B: initialize -> 0
C: about to open_v2
D: open_v2 -> rc=0 db=0x100dbe010
exit=0

=== without the flag (this flag set) ===
A: version 3.53.4 (3053004)
C: about to open_v2
D: open_v2 -> rc=0 db=0x102aca0b0
exit=0
```

The face could satisfy the precondition in `open`. The wall cannot: II.1
makes every `sqlite3_*` entry point public and says dropping to it is a
continuation, not an escape, so a caller reaching the wall directly is a
supported path — and under this flag that path segfaults. A hidden
precondition on a public surface is not worth 1–2% of a static-flag load.

### `SQLITE_USE_URI=1` — REMOVED, and the flag is now load-bearing BY ITS ABSENCE

The flag makes URI filename parsing GLOBAL: every filename reaching
`sqlite3_open_v2` is parsed as a URI whether or not the caller asked.
Measured, with NO `SQLITE_OPEN_URI` in the open flags:

```
sqlite3_open_v2("file:/tmp/x.db", &db, READWRITE|CREATE, 0)
  -> rc=0   db_filename=[/private/tmp/x.db]        <- the prefix was STRIPPED
```

So a caller's raw path is a URI, `?mode=ro` and `?cache=shared` ride in
it, and the driver's rule "a path is a filename" is enforceable only by
the driver's own refusal at one verb. Any path reaching `open_v2` by
another route — a second verb, or the raw wall a caller may drop to
(II.1 makes that a supported path) — is reinterpreted with nothing to
stop it.

**AND THERE IS NO RUNTIME WAY BACK.** `SQLITE_OPEN_URI` only turns URI
parsing ON. The single off switch is
`sqlite3_config(SQLITE_CONFIG_URI, 0)` (`sqlite3.h:2230`), and
`sqlite3_config` is VARIADIC — a class the driver refuses at the
declaration permanently, because on arm64 a variadic callee reads its
arguments from the stack while a fixed-arity call puts them in
registers. **A compile-time decision we could not undo at runtime,
because the undo lives in the class that was ruled out.**

With the flag off, the safe default is enforced BY THE LIBRARY and a
deliberate verb passes `SQLITE_OPEN_URI` for its own connection. Defence
at the boundary rather than a rule at one door — the same shape as the
argv law.

**THIS FLAG'S ABSENCE IS THEREFORE LOAD-BEARING.** Anyone re-adding it
takes URI reinterpretation back for every caller with no way to switch
it off. Do not re-add it without reading `src/c/CENSUS.md` §19.

### `SQLITE_MAX_EXPR_DEPTH=0` — REJECTED, kept at the default 1000

It removes `sqlite3ExprCheckHeight` ("Height enforcement off" in the
source). The lemon parser's own recursion limit still catches deeply
*nested* expressions, so the flag looks harmless:

```
depth 100:    prepare -> rc=0 (OK)
depth 1000:   prepare -> rc=0 (OK)
depth 10000:  prepare -> rc=1 (Recursion limit)
depth 100000: prepare -> rc=1 (Recursion limit)
```

It is not harmless. A LEFT-DEEP chain — `select 1+1+1+…` — keeps the parser
stack shallow while the expression tree's height grows with the input, which
is exactly the case the height check exists for:

```
=== with -DSQLITE_MAX_EXPR_DEPTH=0 ===
chain 1000:   prepare -> rc=0 (OK)
chain 20000:  prepare -> rc=0 (OK)
chain 50000:  exit=139               <- SIGSEGV in prepare
chain 200000: exit=139

=== with -DSQLITE_MAX_EXPR_DEPTH=1000 ===
chain 20000:  prepare -> rc=1 (Expression tree is too large (maximum depth 1000))
chain 50000:  prepare -> rc=1 (Expression tree is too large (maximum depth 1000))
chain 200000: prepare -> rc=1 (Expression tree is too large (maximum depth 1000))
```

sqlite.org's set optimizes for an application that owns every byte of its
SQL. A standard library does not: its SQL arrives from wherever its caller's
SQL arrives from. The limit is a per-connection `SQLITE_LIMIT_EXPR_DEPTH`, so
a caller who truly owns their SQL raises it at runtime — which the flag would
have taken away from everyone.

The value is spelled explicitly rather than left to the header's `#ifndef`
default so that `sqlite3_compileoption_used("MAX_EXPR_DEPTH=1000")` can
assert it.

---

## Refused from sqlite.org's twelve

- `SQLITE_THREADSAFE=0` — 2%, and a connection unusable from more than one
  thread. P2 refuses it.
- `SQLITE_OMIT_DECLTYPE` — deletes `sqlite3_column_decltype`, which the ORM
  needs to reach a column's declared type.
- `SQLITE_OMIT_PROGRESS_CALLBACK` — deletes the smallest trampoline in the
  API, the right first target for the FFI's callback slice.
- `SQLITE_OMIT_SHARED_CACHE` — harmless to keep; the entry point stays
  bindable and deprecated.
- `SQLITE_OMIT_DEPRECATED` — **later, not never.** It removes 9 classified
  functions. It is taken once the driver's DEPRECATED verdicts are locked and
  its tests prove nothing calls them. A checklist item, not a flag today.

## Facts worth knowing before this file changes

- `SQLITE_ENABLE_SESSION` does not compile alone: the implementation is
  gated on `defined(SQLITE_ENABLE_SESSION) && defined(SQLITE_ENABLE_PREUPDATE_HOOK)`.
- `SQLITE_DEFAULT_MMAP_SIZE` maps file pages, which `AVRA_MEM_STATS` cannot
  see (it counts boxes) and which the watchdog's RSS tripwire can. A test
  over a large database measures a footprint the runtime's accounting will
  not explain. `PRAGMA mmap_size = 0` per connection is the answer where it
  matters.
- The amalgamation is self-contained: its four `#include "…"` lines are all
  guarded off (`SQLITE_AMALGAMATION`, `sqlite_cfg.h`, Windows, TCL). No
  include path is needed to compile it. `sqlite3.h` is vendored as the
  reference the `extern fn` declarations are checked against by hand — Avra
  does not read C headers, so the `extern fn` line is the contract and the
  header is what keeps it honest.
- `shell.c` is not vendored: it is a separate program with its own
  dependencies, and the driver needs none of it.
