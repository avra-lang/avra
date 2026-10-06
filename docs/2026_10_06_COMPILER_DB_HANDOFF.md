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
(`.57.169` … `.57.181`). Each lands alone and leaves main green.

## The first three PRs

### DB 00 — secure, measure, fence (`.57.169`) · ladder: none

Nothing after this can be believed without it.

| part | where it is now | to do |
|---|---|---|
| the M1–M3 harness | branch `origin/db-measure`, `tools/db_measure/` (`warm_edit.sh` and kernel counters behind an env flag) | land it; copy its results into the design's §7.3 "PENDING M1/M2/M3" rows and apply what each says it changes |
| one derivation alive at a time | PR #289 (`origin/warm-memory`) — in the merge queue on 10-06 | confirm it merged with `make turn-memory-attack` in CI |
| keepers in CI | `origin/keepers-green` @ `a23c730` (the `Line` layout fix `01c219c`; `make keepers` = codecs + fmt-lossless + cache-attacks) | open its PR and land it; four of its commits say "WIP (unverified)" — verify them |
| defects | filed: `.57.182` (annotation trap), `.57.183` (template hygiene), `.57.184` (four unrecorded reads), `.57.185` (`avra dev` watch set) | nothing; they are fixed by DB 04 and DB 10 |

Done when: `make keepers` is green and a required CI job; the counters print cells and deps
per family on a cold `check packages/cli`; `sh tools/db_measure/warm_edit.sh` prints the
one-edit median; the three PENDING rows in the design are filled.

### DB 01 — one engine (`.57.170`) · ladder: `seed-check` must pass; build twice

Today `@query` is a second memo (std-relation `Memo<V>`, `db.av:475-580`) whose validity is
one write counter for the whole Db, and `@input` records no read. The compiler's hooks
`opened` / `settled` / `running` answer "no opinion" (`workspace.av:581`, `decls.av:702`).

1. Move the kernel (`packages/std-avrac/src/query/`) below `@std/relation`, so both use it.
2. `@query` and `@input` expand to kernel cells. A plain `new_db()` owns a private kernel.
3. Delete `Memo<V>`, the write counter and the three unarmed hooks.
4. `@family` registers through the same call. Add `make families` (prints 32; may only fall).
5. A dependency becomes a packed int (`family << 40 | arg`), not a boxed `Key`
   (ticket `.57.167`: 375 MB in 5.3 M boxes). The audit's `first_visit` stamp is the
   audit's; do not share it.
6. A census in CI holds a recorded read to ≤ 350 instructions (~938 today for a relation).
7. Every kernel refusal names the query and its key.

Done when: three pure queries each run once after an unrelated insert (nine runs today —
the review's probe `c3`); `AVRA_MEM_STATS=1 build/avra check packages/cli` shows
`Kernel.newly_read` under 60 MB; `/tmp/db-doc/t1`'s program (design §3.1) still prints
`/a b 2->3`.

If M3 says recorded relation reads did **not** cost the 0.18 s → 4.27 s, steps 5–6 may
follow DB 02–03 instead of leading.

### DB 02 — `avra explain` (`.57.171`) · ladder: none

The instrument every later PR is debugged with.

- `avra explain --stats [pkg]`: the DB 00 counters, permanent: cells, deps, saved answers,
  reads per answer p50/p99, the longest in-memory list.
- `avra explain <file | @decl | query(key)> [--why] [--json]` over the in-memory graph
  (the store arrives in DB 05).
- It never writes the store it inspects (`Keeping.Aside`; the `.57.153` law).
- `avra cache why / dependents / changed / held` become aliases; `cache_walk.av` shrinks.

Done when: `build/avra explain --stats packages/cli` prints one table; after an edit,
`explain <file> --why` names the moved input; two runs print the same thing.

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
| D3 | is the Db implicit inside a query, or passed by hand? | implicit | DB 01 (the generated signature) |
| D4 | may a query write rows? | no: a relation is an input or one query's answer | DB 06 |
| D5 | one way to write a lint (`rule`), or two? | one | DB 10 |
| D6 | may a plugin read anything, or only what its manifest grants? | only what is granted | DB 10 |
| D8 | one store per compiler binary, or answers keyed by their query's code? | per binary now | DB 05 |
| D9 | a tool's identity: digest every time, or path + size + mtime? | path + size + mtime, tools and the compiler only | DB 04 d |

Also named for the owner in the design's §9: COMPILER.md's law "the sources are the hold's
oracle" is retired when the hold is deleted (DB 07); the edit corpus replaces it.

Waiting on measurements: M1 (how big the kernel graph is), M2 (saved answers and reads per
answer), M3 (where 0.18 s → 4.27 s went). The design's §7.3 says what each result changes.
