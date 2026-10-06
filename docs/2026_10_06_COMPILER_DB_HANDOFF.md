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
| M3 harness | `origin/db-measure` @ `7182161`: one script, `tools/db_measure/warm_edit.sh`. First numbers are in the design §7.1 | finish the bisect (below) |
| M1/M2 counters | **not written**. The db-measure lane is writing them | if that lane has stopped, write them to the spec below |
| defects | filed: `.57.182`, `.57.183`, `.57.184`, `.57.185` | `.57.182` (the annotation trap) is independent — fix it any time |

One ask for the owner, not a task: making `keepers` and `cache-attacks` **required** checks
is a repository setting only he can change.

**The M1/M2 counter spec.** Counters only, behind one env flag, printed once at exit to
stderr as tab-separated lines; no behaviour change. Extend `Kernel.stats`
(`query/kernel.av`). On a cold `check packages/cli`:

| line | what is counted |
|---|---|
| M1, one per family (32) | cells settled · direct deps recorded · distinct keys · the key's type |
| M1, one per relation | **row cells** and **bucket cells** counted separately from families: cells, deps recorded *on* them (reads), whether the relation is keyed |
| M1 totals | cells, deps, bytes per edge and per cell |
| M2, one per family | under "every family key has a name": saved answers · direct durable reads per answer (min, median, p95, max, total) after a row or bucket read is replaced by a read of its producer's named part · encoded bytes of the answer if a codec exists, else "blocked by …" |
| M2 totals | saved answers, reads, the count of reads that land on a **keyless** row (the only cells L4 refuses), digest cost per answer |

Compare with `origin/perf/witness-folded` (13,578 direct deps over 770 files).

**The M3 bisect.** Points, oldest first — measure 1, 5, 8, then halve:

| # | commit | date | why |
|---|---|---|---|
| 1 | `86d7009` | 09-21 | the 0.18 s tree (measured: one body edit 0.36–0.51 s on the Sprite) |
| 2 | `1c0cad6` | 09-26 | one Db per command |
| 3 | `e4d4420` | 09-28 | the witness landed, off |
| 4 | `e203c0d` | 09-30 | #48, held row reads |
| 5 | `cd3df92` | 10-01 | #102 `DeclAt`: declarations in recorded relation rows |
| 6 | `83d4877` | 10-01 | #109, the pack deleted |
| 7 | `b8311ee` | 10-01 | #124, 4.27 s |
| 8 | `05fe643` | 10-06 | main (measured: 4.8–7.2 s) |

Per point: `git worktree add ../avra-db-measure-<sha> <sha>` → `sh tools/work bind` →
`sh tools/work run --for 12 "AVRA_MEM_CEILING_MB=5000 make bootstrap"` (the compiler is
built from **that commit's own seed**; never with today's binary) → copy today's
`warm_edit.sh` in and run it with that tree's `build/avra`. An old commit may lack
`tools/work`; then run from the db-measure worktree with the old tree synced beside it.
The db-measure lane has done point 1 this way; its `tools/db_measure/RESULTS.md`, when
pushed, is the authority on the recipe. A scenario whose literal an old tree lacks says so.

Done when: `make keepers` and `make cache-attacks` are green in CI; the counters print the
lines above; the bisect names the commit(s); the three PENDING rows in the design are filled.

### DB 01 — one engine (`.57.170`) · five PRs · **blocked on D3 from 01b**

Today `@query` is a second memo (std-relation `Memo<V>`, `db.av:475-580`) whose validity is
one write counter for the whole Db, and `@input` records no read. The compiler's hooks
`opened` / `settled` / `running` answer "no opinion" (`workspace.av:581`, `decls.av:702`).

| PR | what | done when |
|---|---|---|
| **01a** the kernel moves | `packages/std-avrac/src/query/kernel.av` and `marks.av` → a new package `packages/std-query` (`[package] name = "@std/query"`, `[lib] path = "src/query.av"`). No manifest row is needed anywhere: `@std/*` resolves from the toolchain, and `std-avrac/avra.toml` has no dependency rows today. The kernel imports only `core.{list_cell, map_cell}` and `@std.meta.identity`; the two seeders move with it and `core` re-exports them. `memo.av` and `fixpoint.av` use `core.Table` and stay. CLAUDE.md's layering line becomes `@std/query -> core -> …` | `make bootstrap` and `seed-check` green; `grep -rn "use query" packages/std-avrac/src` shows only re-exports |
| **01b** one memo | `@query` and `@input` expand to kernel cells; a plain `new_db()` owns a private kernel; `Memo<V>`, the write counter and the three unarmed hooks deleted. A plain Db and the compiler's kernel do **not** share family ids: an id is a per-kernel interning of the query's name | the program below prints `icons,fonts,pure`; design §3.1's program still prints `/a b 2->3`; std-relation's suite green |
| **01c** packed deps | a dependency is `family << 40 \| arg` in a `List<int>`. A negative `arg` is read as "no cell" today (`kernel.av:689`: `key.arg < 0 → null`); packing **refuses** one at the record site instead. Consumers of `deps_of` move with it: `cache_walk.av`, `dep_audit.av`, `searched`. The audit's `first_visit` stamp is the audit's; do not share it | on a Sprite, `AVRA_MEM_STATS=1 build/avra check packages/cli`: `Kernel.newly_read` under 60 MB (375 today, ticket `.57.167`) |
| **01d** the read-cost census | there is **no tool in the tree**: the ~938 and ~315 figures came from the PERF lane's `kbench`, outside the repo (tickets `.57.8.1`, `.57.30`). Land `tools/db_measure/read_cost.sh`: one program doing N and 2N recorded reads under an instruction counter on a Sprite; the difference ÷ N | it prints instructions per recorded read for a kernel cell and a relation row; CI holds ≤ 350 once 01b makes it reachable |
| **01e** names, not ordinals | every family (and `@query`) registers by stable name; every kernel refusal names the query and its key. `make families-left` prints how many families still wear `@family` (32) and fails if it rose. The existing `make families` (`tools/families.py`, `tools/families.order`) holds the *opposite* contract — ordinals append-only, because "kernel rows, kept caches and witnesses are keyed by `ordinal`". It is retired **in this PR**, after showing both of: nothing saved is keyed by an ordinal across compilers (a store is one compiler print's), and no family fingerprint folds the ordinal (fold the name instead). Until 01e lands, no family is removed | `make families-left` → 32; `make families` and `tools/families.order` are gone from the Makefile, `checks.yml:110` and the gate; a two-owner refusal names its query |

D3 (is the Db implicit inside a query?) changes the signature 01b generates. If the owner
has not answered: build 01b with the explicit `db` (today's spelling) so nothing waits, and
note that the 21 test queries change when he says "implicit".

The acceptance program for 01b (the review's `c3`). PROBED 2026-10-06: `build/avra run` on
it prints `icons,fonts,pure,icons,fonts,pure,icons,fonts,pure` — any insert invalidates
every answer:

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

(Under D4 the two inserting queries become answers; the test keeps `pure` and two base
inserts by the driver.) If M3 says recorded relation reads did **not** cost the regression,
01c–01d may follow DB 02–03 instead of leading.

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
| quoting "≥51.6 M deps" | never committed; two later measurements say ~5 M |
| a number without its source | label it MEASURED (command), PROBED, READ or ESTIMATED |

## PENDING OWNER

The design is written with the recommendation for each. Ask before building on one.

| # | question | recommended | first PR that needs it |
|---|---|---|---|
| D3 | is the Db implicit inside a query, or passed by hand? | implicit | **DB 01b — the second PR. Ask first** |
| D4 | may a query write rows? | no: a relation is an input or one query's answer. Consequence: a producer's keys must be listable (design A11) | DB 06; due before DB 03 |
| D5 | one way to write a lint (`rule`), or two? | one | DB 10 |
| D6 | may a plugin read anything, or only what its manifest grants? | only what is granted | DB 10 |
| D8 | one store per compiler binary, or answers keyed by their query's code? | per binary now | DB 05 |
| D9 | a tool's identity: digest every time, or path + size + mtime? | path + size + mtime, tools and the compiler only | DB 04 d |
| D10 | is "a failure under a held answer is asked again of the sources" retired? | yes, replaced by the edit corpus and the attack suite in CI | DB 07 — which keeps the re-ask behind a flag and as a CI mode until he says yes |

Waiting on measurements: M1 (how big the kernel graph is), M2 (saved answers and reads per
answer), M3 (where 0.18 s → 4.27 s went; first numbers are in the design's §7.1, the bisect is pending). The design's §7.3 says what each result changes.

## Questions a cold session cannot answer from the code

| # | question | answer |
|---|---|---|
| 1 | The M1/M2 counters do not exist — do I write them? What does M2 simulate now that no family is local? | The db-measure lane is writing them; if it has stopped, yes, to the spec under DB 00. M2 simulates "every family key has a name", replaces each row or bucket read by a read of its producer's part, and counts reads that land on keyless rows |
| 2 | M3: which commits, and how is an old compiler built? | the table under DB 00; `make bootstrap` in a worktree at that commit, from its own seed |
| 3 | PR #289 — land it or wait? Is the memory attack in CI? | merged (`9163515`); `turn-memory-attack` is in `checks.yml:110` |
| 4 | keepers-green: what was unverified, what counts as verified? | its top four commits. Verified = the keeper each touches is green on a Sprite from that branch, then `make keepers` and `make cache-attacks` whole. Ask team-lead first whether its lane is alive |
| 5 | Who makes a CI job required? | **the owner** (a repository setting) |
| 6 | D3 is pending and 01b needs it — build or wait? | **the owner decides D3.** Do not wait: 01a needs nothing; build 01b with the explicit `db` |
| 7 | `make families` exists with the opposite meaning | mine is `make families-left`; the old keeper and `tools/families.order` are retired in 01e, on the two conditions written there |
| 8 | Where does the kernel live, and is there a manifest or seed ladder? | `packages/std-query`, `@std/query`. No manifest row. No new syntax, so the seed compiles it; `seed-check` is the proof |
| 9 | Do a plain Db's kernel and the compiler's share family ids? | no. An id is a per-kernel interning of the query's stable name |
| 10 | What does a negative `arg` mean before I pack? | today it reads as "no cell" (`kernel.av:689`). Nothing should mint one; refuse it at the record site and see what trips |
| 11 | What gives "instructions per recorded read"? | nothing in the tree. 01d adds `tools/db_measure/read_cost.sh` |
| 12 | Where is `c3`? | inline above, under DB 01 |
| 13 | Do the documents land on main? | yes, one docs PR, opened by team-lead |
| 14 | Tickets `.169–.185` are owned by `db-doc` — re-own them? | yes: `tasks update --claim <id>` as you start each. `db-doc` was the author of the plan, not an owner of the work |
