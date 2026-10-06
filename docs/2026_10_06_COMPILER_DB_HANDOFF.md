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
| the measuring harness | `origin/db-measure` @ `064cd27`, no PR yet: `tools/db_measure/` — `warm_edit.sh`, `graph.py` + the kernel's `AVRA_DB_GRAPH=1`, `digest_bench.sh`, `readbench/`, `hist_point.sh`, and `RESULTS.md` with `raw/` | land it as its own PR; do not rewrite it |
| M1 · M2 · M3 | **all measured** (design §7, A20, A21; `RESULTS.md`) | nothing |
| defects | filed: `.57.182`, `.57.183`, `.57.184`, `.57.185` | `.57.182` (the annotation trap) is independent — fix it any time |

One ask for the owner, not a task: making `keepers` and `cache-attacks` **required** checks
is a repository setting only he can change.

**What M3 found, and the three small PRs it adds to DB 00.** A one-literal edit re-checks
the cli in 4.7–6.4 s: load 1.85 s (every held module's record met; ~4 ms per held file
whatever was edited), admit 1.1–2.1 s (23–50 files parsed for one edited), analyze 0.5 s
(all 994 method tables rebuilt), lower 0.75 s. Recorded relation reads are **not** the
cause: 3 of them on that path.

| PR | ticket | what | done when |
|---|---|---|---|
| **00a** why unchanged files are parsed | `.57.191` | run the edit once and keep the whole `check --time` output: it already names each file a record knows that was read anyway, with why (`Reads`; the list is capped at 12 by `READ_NAMED`, `compiler/derive.av:109` — lift the cap for the run) | a table: each of the 22–49 unchanged files with its reason; each reason has a fix or names its PR |
| **00b** the load profile, then maybe an early fix | `.57.193` | `load` is `Derived.holding` (`derive.av:476-500`). First split its 1.85 s between meeting records and asking holds (`AVRA_SAMPLE` on a Sprite). Only if the hold's key work dominates: remember a held file's key parts beside its key and re-key only a file with a moved part (`record.av:1104-1113`, `:1297-1306`, the `parts`/`seen` rows `:1310`, `:1323`). It is a memo of a pure function of digests on code DB 07 deletes — nothing more | the split table; if the fix is taken, `load` < 300 ms for the std-avrac-file edit and cache-attacks green |
| **00c** a discarded attempt says what it cost | `.57.189` | `--time` prints the count only (`discarded 1`). std-avrac's one edit is 8.4–8.7 s wall with 4.5 s of printed phases. Sites: `derive.av:120-134` (`timed`), `:455-470` (`tried_anew`, `turned`) | one line per discarded attempt: wall ms, phases, the attempt it named instead |

Also filed from M3, not part of DB 00: `.57.190` (std-http refuses its hold for a one-body
edit: held 0/121, a 13 s cold check) and `.57.192` (all 994 method tables rebuilt per edit —
if one whole-table read is the cause, narrow it now; otherwise DB 07 c).

Done when: `make keepers` and `make cache-attacks` are green in CI; the harness is on
main; 00a's table exists; 00b's split exists; 00c prints.

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
| **01d** the read-cost bound | no instruction counter exists on a Sprite, so the old ~938 / ~90 instruction figures (PERF's `kbench`, tickets `.57.8.1`, `.57.30`) cannot be re-measured. Use `tools/db_measure/readbench/` in nanoseconds: MEASURED today list 4, relation unrecorded 35–38, recorded 67–75. The bound is for DB 12 (32 families becoming queries), not a fix for today's slowness | CI holds a recorded relation read ≤ 2 × an unrecorded one |
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

M3 measured that recorded relation reads are **not** where the warm edit goes (3 on the
path). So 01c–01d need not lead: do 01a, 01b, 01e first. 01c is still worth its memory
(375 MB of edges); 01d bounds DB 12's migration.

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
| blaming recorded relation reads for the slow warm edit | M3 measured 3 of them on the one-edit path, and all 1.5 M kernel reads bound to 0.11 s. The time is in load, admit, analyze and lower (design §7.2) |
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

M1, M2 and M3 are measured (design §7, A20, A21): 70,015 cells and 5.3 M direct edges;
54,947 saved answers with a median of 3 reads. Always-save is blocked by **names, not
size**. Three things follow for whoever builds DB 03, 06 and 07:

- a read with no durable name makes its reader unsavable — never drop it. Name buckets
  (2.27 M edges) get names in DB 03 a, before DB 06 saves any compiler family;
- `Lowered` and `Settled` are roots keyed by ask numbers: DB 03 a names them (declaration ·
  type arguments; const · seat fingerprint);
- `Receivers` (41,435 reads), `References` (13,030) and `MethodDiags` (994 a file) are
  split in DB 07 c; an unchanged run must walk none of them.

Nothing is waiting on a measurement. The 300 ms gate first becomes reachable at DB 07;
until then the gate is "never slower than the last landing" (design §7.3).

## Questions a cold session cannot answer from the code

| # | question | answer |
|---|---|---|
| 1 | The M1/M2 counters — do I write them? | no: measured, on `origin/db-measure` (`AVRA_DB_GRAPH=1`, `graph.py`, `RESULTS.md`). Land the harness |
| 2 | M3: which commits, and how is an old compiler built? | none: no bisect. M3 is measured; it added DB 00 a–c |
| 3 | PR #289 — land it or wait? Is the memory attack in CI? | merged (`9163515`); `turn-memory-attack` is in `checks.yml:110` |
| 4 | keepers-green: what was unverified, what counts as verified? | its top four commits. Verified = the keeper each touches is green on a Sprite from that branch, then `make keepers` and `make cache-attacks` whole. Ask team-lead first whether its lane is alive |
| 5 | Who makes a CI job required? | **the owner** (a repository setting) |
| 6 | D3 is pending and 01b needs it — build or wait? | decided 10-06: the Db is never an argument. Build 01a to that spelling |
| 7 | `make families` exists with the opposite meaning | mine is `make families-left`; the old keeper and `tools/families.order` are retired in 01e, on the two conditions written there |
| 8 | Where does the kernel live, and is there a manifest or seed ladder? | `packages/std-relation/src/kernel.av` after 01a. No manifest row. No new syntax, so the seed compiles it; `seed-check` is the proof |
| 9 | Do a plain Db's kernel and the compiler's share family ids? | no. Each kernel interns a query's stable name to its own dense id |
| 10 | What does a negative `arg` mean before I pack? | today it reads as "no cell" (`kernel.av:689`). Nothing should mint one; refuse it at the record site and see what trips |
| 11 | What gives "instructions per recorded read"? | nothing can on a Sprite. `readbench/` gives nanoseconds per read; the bound is in those (01d) |
| 12 | Where is `c3`? | inline above, under DB 01 |
| 13 | Do the documents land on main? | yes, one docs PR, opened by team-lead |
| 14 | Tickets `.169–.185` are owned by `db-doc` — re-own them? | yes: `tasks update --claim <id>` as you start each. `db-doc` was the author of the plan, not an owner of the work |
