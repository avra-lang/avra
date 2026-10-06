# The compiler DB — hand-off

2026-10-06 · for the session that does the work.
The design is [`2026_10_06_COMPILER_DB.md`](2026_10_06_COMPILER_DB.md). Read its first two
sections and §8 before anything else. This page is how to start.

## What this is

The compiler's facts become query answers in one database. Every answer is saved
automatically with the list of what it read, and stands only while every digest in that list
still matches. Plugins use the same three words the compiler uses (`@relation`, `@query`,
`@input`). Warm commands are fast in a cold process: unchanged `check packages/cli` ≤ 60 ms,
one body edit ≤ 300 ms, no daemon.

The compiler is the first consumer: each language feature writes a query instead of a
family marker, a side table, a memo map and a validity format (design §2b).

The work is thirteen PRs, `DB 00` … `DB 12`, one ticket each under epic `avra-8sb5.57`
(`.57.169` … `.57.181`). Each lands alone and leaves main green. DB 01, DB 03, DB 04 and
DB 07 are several PRs each, lettered. Both documents land on main in one docs PR that
team-lead opens; after that they live in `docs/` on main and `db-design` is retired.

## The first three PRs

### DB 00 — secure, measure, fence (`.57.169`) · ladder: none

Nothing after this can be believed without it. True state, checked 2026-10-06:

| part | state | to do |
|---|---|---|
| one derivation alive at a time | **merged**: PR #289 → `9163515`. `turn-memory-attack` is in the CI keepers list (`checks.yml:110`) | nothing |
| keepers in CI | `origin/keepers-green` @ `a23c730`: a branch, **no PR**. Four good commits (`5de48f0`, `1caf3d9`, `01c219c` the `Line` layout fix, `5f495f5` the CI list) and four titled `WIP`, the last "(unverified)". Its lane is still verifying | ask team-lead whether that lane is alive. If not: run `make keepers` and `make cache-attacks` on a Sprite from that branch; a WIP commit is verified when the keeper it touches is green there. Then `sh tools/work land` |
| the measuring harness | `origin/db-measure` @ `6b12cf8`, no PR yet: `tools/db_measure/` holds `warm_edit.sh` (the one-edit check, per-family trace counts), `graph.py` + the kernel's `AVRA_DB_GRAPH=1` (every settled cell with the keys it read; it also tries the saved-answer rule on the graph), `digest_bench.sh`, `readbench/` (a row-read bench), `hist_point.sh`, `archive.sh` | land it as its own PR once its lane reports M2 and M3; do not rewrite it |
| M1 · M2 · M3 | **M1 measured** (design §7.3: 70,015 cells, 5,314,590 edges). M2 and M3 are that lane's, in progress | if the lane has stopped: M2 to the spec below with `graph.py`; M3 as written below |
| defects | filed: `.57.182`, `.57.183`, `.57.184`, `.57.185` | `.57.182` (the annotation trap) is independent — fix it any time |

One ask for the owner, not a task: making `keepers` and `cache-attacks` **required** checks
is a repository setting only he can change.

**What M1/M2 must print** (`AVRA_DB_GRAPH=1` writes the graph; `graph.py` counts it). On a
cold `check packages/cli`:

| line | what is counted |
|---|---|
| M1, one per family (32) | cells settled · direct deps recorded · distinct keys · the key's type |
| M1, one per relation | **row cells** and **bucket cells** counted separately from families: cells, deps recorded *on* them (reads), whether the relation is keyed |
| M1 totals | cells, deps, bytes per edge and per cell |
| M2, one per family | under "every family key has a name": saved answers · direct durable reads per answer (min, median, p95, max, total) after a row or bucket read is replaced by a read of its producer's named part · encoded bytes of the answer if a codec exists, else "blocked by …" |
| M2 totals | saved answers, reads, the count of reads that land on a **keyless** row (the only cells L4 refuses), digest cost per answer |

Compare with `origin/perf/witness-folded` (13,578 direct deps over 770 files).

**M3 — no bisect** (owner: "it's too expensive"). On main **today**, on a Sprite, for the
warm one-edit `check packages/cli` that `warm_edit.sh` already drives: the compiler's own
`--time` phase line and the `AVRA_QTRACE` reuse/compute/parse counts (the script's
`traced()` prints them). Deliver one table: every phase that walks the whole program, its
milliseconds, and how many queries it recomputed for a one-line edit. The two measured
points (the 09-21 tree and main) are in the design §7.1; nothing in between is measured.

Done when: `make keepers` and `make cache-attacks` are green in CI; the counters print the
lines above; the phase table exists; the three PENDING rows in the design are filled.

### DB 01 — one engine (`.57.170`) · five PRs · the first build

**The defect this fixes** (the owner: "PLEASE fix this"). There are two engines today:

| | where | evidence |
|---|---|---|
| the kernel | `packages/std-avrac/src/query/kernel.av` (717 lines): cells, deps, red-green, early cutoff | READ |
| a second memo | `packages/std-relation/src/db.av:475-580` `Memo<V>`: a `@query` is reused only while one whole-Db write counter has not moved (`:511-519`); `@input` records no read (`:625-649`) | READ(agent) |
| the bridge | `Hooks`, nine closures (`db.av:50-62`). The compiler answers `opened: -1`, a no-op `settled`, `running: -1` (`workspace.av:581-582`, `features/decls.av:702-706`) | READ |
| the result | M1, MEASURED: the three std-relation families hold **2** edges; declaration reads are recorded on `Named`, `Items`, `Methods` instead | branch `db-measure`, `AVRA_DB_GRAPH=1` |

The engine moves into `@std/relation` (owner decision D11: one engine for the compiler *and*
a running program; no new package). `std-avrac` depends on `@std/relation` as today.

| PR | what | done when |
|---|---|---|
| **01a** the kernel moves | `query/kernel.av` and `query/marks.av` → `packages/std-relation/src/kernel.av`, `marks.av`. They import only `core.{list_cell, map_cell}` (two four-line seeders, `core/table.av:48-57`) and `@std.meta.identity`: the seeders move with the kernel and `core` re-exports them. `query/memo.av` (190) and `query/fixpoint.av` (261) use `core.Table` and **stay** — they are the compiler's own use of the engine. `query/` re-exports the kernel's names, so the 12 files that `use query.{…}` do not change in this PR. No manifest row is needed (`@std/*` resolves from the toolchain; no manifest in the tree carries dependency rows for it). **Layering**: no keeper pins `core → query → grammar → features → compiler` today (nothing in `tools/` checks it). This PR restates CLAUDE.md's rule truthfully — "`@std/relation` holds the engine and sits below the compiler; inside `std-avrac`: `core → query → grammar → features → compiler`" — and adds the keeper `make layers`: a directory never imports one to its right, and `@std/relation` never imports `@std.avrac` | behaviour unchanged: `make bootstrap`, `seed-check`, std-relation's and std-avrac's suites green; `make layers` green, and red when a fixture imports upward |
| **01b** one memo | `@query` and `@input` expand to kernel cells on **every** Db. `new_db()` owns a kernel; the compiler builds its relation Dbs on the workspace's kernel. `Memo<V>`, the write counter and `Hooks` are deleted (a refusal still speaks through one fn). `@input` and `Memo.input` become one thing and record the read. The Db is not an argument (D3): the generated fn takes the key only, and std-relation's 21 test queries are rewritten to that spelling — their memo assertions stay meaningful and stay | (1) a **program test in std-relation**: the program below prints `pure` once; (2) a **compiler test**: `named_decls` asked twice across an unrelated `Decl` write runs once; (3) the M1 graph (`AVRA_DB_GRAPH=1`) shows the compiler's `@query` cells holding their own edges, not 2 |
| **01c** packed deps | a dependency is `family << 40 \| arg` in a `List<int>`. A negative `arg` is read as "no cell" today (`kernel.av:689`: `key.arg < 0 → null`); packing **refuses** one at the record site instead. Consumers of `deps_of` move with it: `cache_walk.av`, `dep_audit.av`, `searched`. The audit's `first_visit` stamp is the audit's; do not share it | on a Sprite, `AVRA_MEM_STATS=1 build/avra check packages/cli`: `Kernel.newly_read` under 60 MB (375 today, ticket `.57.167`) |
| **01d** the read-cost census | the ~938 and ~315 figures came from the PERF lane's `kbench`, outside the repo (tickets `.57.8.1`, `.57.30`). In the tree there is now `tools/db_measure/readbench/` on `origin/db-measure` (a row-read bench). Wire it under an instruction counter on a Sprite: N and 2N recorded reads, the difference ÷ N | it prints instructions per recorded read for a kernel cell and a relation row; CI holds ≤ 350 once 01b–01c make it reachable |
| **01e** names, not ordinals | every family (and `@query`) registers by stable name; every kernel refusal names the query and its key. `make families-left` prints how many families still wear `@family` (32) and fails if it rose. The existing `make families` (`tools/families.py`, `tools/families.order`) holds the *opposite* contract — ordinals append-only, because "kernel rows, kept caches and witnesses are keyed by `ordinal`". It is retired **in this PR**, after showing both of: nothing saved is keyed by an ordinal across compilers (a store is one compiler print's), and no family fingerprint folds the ordinal (fold the name instead). Until 01e lands, no family is removed | `make families-left` → 32; `make families` and `tools/families.order` are gone from the Makefile, `checks.yml:110` and the gate; a two-owner refusal names its query |

The acceptance program for 01b, in today's spelling. PROBED 2026-10-06 on a plain Db:
`icons,fonts,pure,icons,fonts,pure,icons,fonts,pure` — any write invalidates every answer.
In 01b the `db` arguments go (D3). `icons` and `fonts` write rows inside a query, which D4
ends at DB 06; until then they stay as the "unrelated writes". The assertion: **`pure`
appears once.**

```avra
use @std.relation.{relation, query}
use @std.relation.db.{Db, new_db}

@relation
type Icon = { id: int, @key name: string, @index set: string, svg: string }
@relation
type Font = { id: int, @key name: string }

once fn runs() -> Cell<List<string>> { Cell.new([]) }

@query
fn icons(db: Db, dir: string) -> int {
    runs().push("icons")
    Icon.insert(db, name: "a", set: dir, svg: "1").id
}
@query
fn fonts(db: Db, dir: string) -> int {
    runs().push("fonts")
    Font.insert(db, name: "f").id
}
@query
fn pure(db: Db, n: int) -> int {
    runs().push("pure")
    n + 1
}

let db = new_db()
for _i in 0..3 {
    let _a = icons(db, "d")
    let _b = fonts(db, "d")
    let _p = pure(db, 1)
}
runs().get().join(",")
```

If M3 says recorded relation reads are **not** where the warm edit goes, 01c–01d may follow
DB 02–03 instead of leading.

### DB 02 — `avra explain` (`.57.171`) · ladder: none

The instrument every later PR is debugged with.

- `avra explain --stats [pkg]`: the DB 00 counters, permanent.
- `avra explain <file | @decl | query(key)> [--json]`: the answer's digest, what it read,
  who reads it — over the in-memory graph of this process.
- `--why` at this stage **re-derives in process with the store set aside**, exactly as
  `avra cache why` does today (`cache_walk.av:1-8`). It reads saved records instead from
  DB 06, when a record holds its reads.
- It never writes the store it inspects (`Keeping.Aside`; the `.57.153` law).
- `avra cache why / dependents / changed / held` become aliases; `cache_walk.av` shrinks.

Done when: `build/avra explain --stats packages/cli` prints one table; `explain <file>`
prints its reads; two runs print the same thing.

## How to work here

| | |
|---|---|
| worktree | `../avra-db-design` on `db-design` holds the documents. Code goes in a lane per PR: `sh tools/work new db-NN` (off GitHub's main, with its own Sprite) |
| verbs | `sh tools/work new · run · test · land · status · bind · wait · done` (`sh tools/work --help`; `attach` if your tree has it). Main moves only through `land` |
| heavy runs | on the lane's Sprite: `sh tools/work run --for <min> "<cmd>"`. Bootstraps, suites and censuses never run on the Mac |
| memory | `AVRA_MEM_CEILING_MB=5000` on every compiler run. A "Killed" build: move `.avra-cache` aside on the Sprite and retry |
| time | every command ≤ ~2 minutes except a full test run on a Sprite; never a `sleep` loop, never Monitor |
| before a risky build | `cp build/avra build/avra.pre` |
| the loop per PR | an author implements → a second agent attacks it with no access to the author's reasoning (`/red-team`) → `/review-round` → land. Every survivor of the attack becomes a permanent test |
| measuring | `make census CMD="check packages/cli"` for counts; compare two compilers on the **same** source; fresh edit text every timing round |
| tickets | `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db`, then `/Users/tristan/go/bin/tasks`. Never the MCP task tools |
| other sessions | the peer sessions on this machine are legacy: never message or use them |

CLAUDE.md sections to re-read before the PR that meets them: "A CHANGE THE COMPILER MUST
THEN READ REACHES THE PRODUCT ON THE SECOND BUILD" (DB 01) · "A REGISTRY ROW THE COMPILER'S
OWN SOURCE DECLARES CANNOT BE GATED IN THE COMMIT THAT ADDS IT" (DB 04 a, DB 10) · "A FLAT
CONCATENATION OF TWO SEQUENCES HAS A BOUNDARY THAT MOVES" and "A HASH THAT FORGETS A PAYLOAD"
(DB 03, DB 05) · "AN EARLY-CUTOFF HASH MUST COVER THE WHOLE VALUE" (DB 06) · "A CHECK THAT
EXAMINED NOTHING" and "A CHECK CAN PASS *BECAUSE* OF THE BUG" (every acceptance test) ·
"A BOUNDARY CHECK MAKES A MOVED SHAPE UNMOVABLE IN ONE GENERATION" (DB 10).

## Traps — do not re-introduce these

| trap | why |
|---|---|
| a mark that says "save this" (`@kept`), a grain flag, a hand-written `cover` | the owner decided always-save. A cover that digests less than a reader saw is a stale answer nobody can detect |
| flattening a read list | the 09-28 failure: 33,286,285 edges where the direct reads were 13,578. A saved answer lists **direct** durable reads only |
| a per-key cache of a flattened set | 4 GB, reverted |
| rows inserted inside a query | readers see nothing until someone asks the producer, and stay stale; one key under two producer calls traps |
| an interface digest standing for a module | an importer also reads a generic's body, a const's value, a copied template (`.57.101.11`) |
| one file per saved record | 1,300 opens cost the whole no-op budget |
| any phase that walks the whole program when warm | that is the 4.27 s: ast, sublang, load, admit |
| "run it twice and compare" as the purity check | an unchanged tree agrees with itself. Use the edit corpus |
| an attack that passes with zero answers held | assert the count of answers that stood |
| sharing the kernel audit's visit stamp | it clobbers an audit search in flight |
| a per-load fold over every row; a per-build memo of record fields | 3.7× slower; `record_known` rewrites `record_fields` mid-build (`.57.101.12`) |
| a string that selects declarations (`by_marks("model")`) or names a rule | two packages' `@model` collide; select by the annotation's own declaration |
| a relation named `Field`, `Variant`, `Param` or `Decl` | `@std/meta` already exports the first three and forbids the fourth |
| converting more facts to recorded relation rows before the read costs ≤ 350 instructions | the likely cause of the regression (INFERRED until M3) |
| a new package for the kernel (`@std/query`), a kernel inside `std-avrac` that a program cannot link, or a flag that keeps the old re-ask of the sources | the owner decided all three on 10-06: the engine lives in `@std/relation`; no switch |
| a second kernel in the evaluator's heap for a plugin | a plugin's Db is the compiler's: an ask is a host row into the same kernel |
| quoting "≥51.6 M deps" | never committed; two later measurements say ~5 M |
| a number without its source | label it MEASURED (command), PROBED, READ or ESTIMATED |

## The owner's decisions (2026-10-06)

Nothing is pending. Decided: always save · one engine first · the Db is never an argument
(D3) · a query never writes rows — you return them (D4) · `rule` is the one way to write a
lint (D5) · a plugin reads only what its manifest grants (D6) · one store per compiler
binary now, keyed by the query's code later (D8; ticket `.57.186`) · a tool is identified by
path + size + modified-time, full digest on demand (D9) · the re-ask of the sources is
retired at DB 07 with **no switch** (D10) · the engine lives in `@std/relation`, no new
package (D11) · no bisect.

M1 is measured: 70,015 cells, 5.3 M direct edges, 37.2 M read calls (design §7.3). Waiting
on: M2 (saved answers and reads per answer) and M3 (the phase table for a warm edit on main
today). The design's §7.3 says what each result changes.

## Questions a cold session cannot answer from the code

| # | question | answer |
|---|---|---|
| 1 | The M1/M2 counters — do I write them? | no: they exist on `origin/db-measure` (`AVRA_DB_GRAPH=1`, `graph.py`). M1 is measured; M2 is that lane's. Land the harness; do not rewrite it |
| 2 | M3: which commits, and how is an old compiler built? | none: no bisect. Phase timings on main today (under DB 00) |
| 3 | PR #289 — land it or wait? Is the memory attack in CI? | merged (`9163515`); `turn-memory-attack` is in `checks.yml:110` |
| 4 | keepers-green: what was unverified, what counts as verified? | its top four commits. Verified = the keeper each touches is green on a Sprite from that branch, then `make keepers` and `make cache-attacks` whole. Ask team-lead first whether its lane is alive |
| 5 | Who makes a CI job required? | **the owner** (a repository setting) |
| 6 | D3 is pending and 01b needs it — build or wait? | decided 10-06: the Db is never an argument. Build 01a to that spelling |
| 7 | `make families` exists with the opposite meaning | mine is `make families-left`; the old keeper and `tools/families.order` are retired in 01e, on the two conditions written there |
| 8 | Where does the kernel live, and is there a manifest or seed ladder? | `packages/std-relation/src/kernel.av` after 01a. No manifest row. No new syntax, so the seed compiles it; `seed-check` is the proof |
| 9 | Do a plain Db's kernel and the compiler's share family ids? | no. Each kernel interns a query's stable name to its own dense id |
| 10 | What does a negative `arg` mean before I pack? | today it reads as "no cell" (`kernel.av:689`). Nothing should mint one; refuse it at the record site and see what trips |
| 11 | What gives "instructions per recorded read"? | `tools/db_measure/readbench/` on `origin/db-measure`, under an instruction counter (01d) |
| 12 | Where is `c3`? | inline above, under DB 01 |
| 13 | Do the documents land on main? | yes, one docs PR, opened by team-lead |
| 14 | Tickets `.169–.185` are owned by `db-doc` — re-own them? | yes: `tasks update --claim <id>` as you start each. `db-doc` was the author of the plan, not an owner of the work |
