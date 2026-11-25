# The warm path in the no-hold world (L-typed, 2026-11-03) — for L-hold's review

## What is measured (hd-clean 9c466570, `check packages/cli`, one body edit, machine load ~6)
Median 1.6 s. Phases (ms): names 177, rows stand 164, interfaces 375 (names + rows stand + loaded +
held only), resolve ~100, bodies ~70, analyze 210-260, lower ~190, keep 160-170, ~250 outside any phase.
Every one of them scales with the ~580 files of the program, not with the edit. Cutting the bytes read
does not help: reading 1,000 fewer Sig rows (97 bodies read instead of every module's) moved nothing
(median 1.61 s vs 1.70 s). The cost is per-file WORK — a call per file in each phase — so the design
must remove the calls, not shrink their reads.

## The shape: the run is a root ask over recorded reads (10-06 §6.2, §6.5; ONE_PATH 1-6)
1. **Inputs first.** Read each source once (580 files is ~40 ms: 691 `text_digest_of` computes, measured)
   and compare each digest with the one the last run settled on. A dependency package's files are one
   unit: `package_digest(p)` (its listing + content digests) is verified ONCE per package against a
   durability-HIGH revision, and the files of a package whose digest did not move are never asked
   individually. Installed `@std` is immutable per compiler id, so it is confirmed by that id alone.
2. **Moved inputs mark their readers suspect** (reverse index of recorded reads; ids only).
3. **Ask the roots** (`diagnostics(f)` per file of the entry's program, `linked(entry)`). An answer not
   suspect STANDS — its row is not decoded, its dependencies not asked. A suspect answer re-verifies its
   reads root-down; **early cutoff**: a recomputed answer with the same digest leaves its readers standing.
4. There is no `names` phase, no `rows stand`, no `interfaces`, no `bodies`: they are queries
   (`names(m)`, `items(f)`, `sig(d)`, `typed(d)`, `lowered(u)`) that are never asked unless something
   suspect reads them. A body edit moves `typed(d)` of one declaration; its `sig(d)` digest is unchanged,
   so `names(m)` of its module, and every importer's answers, stand.
5. **Restore is the one path** (ONE_PATH 6): a not-asked answer is simply not asked; one asked and not in
   process is restored by the engine, never by a per-file hold question.

## Cost
| run | steps | estimate |
|---|---|---|
| unchanged | start 15 + inputs 20-40 + roots 2 | **<= 60 ms** (10-06 §6.2 floor 40-60) |
| body edit | + parse 1 file, `typed(d)` of the edited declaration(s), its file's diagnostics, the units that read it, append rows | **100-250 ms**, gate <= 300 |

## What has to change (each deletes code; none adds a mechanism)
- `bare_interface` per module (names 177 ms) and `hold_asks` per file (rows stand 164 ms) leave `holding`:
  the hold's question is the engine's restore (derive.av's `holding` loop and `held_by_rule`/`hold_only`).
- Declarations of unread files are minted on first read (the doc comment on `holding` already promises
  it; the loop over every root module's names still pays for all of them).
- Keys name FILES, never the program: `items_key`, `okey_row`, `record_key` carry `self.root`. Measured
  today: two packages sharing a library hold 0 of 19 files for the second; two programs of ONE package hold
  4 of 5 (tools/cache_attacks.sh `sp`). That is DB 08's `program_key` defect (10-06 A2 "hand format 4",
  build.av `program_key`/`held_objects`; DB_REDESIGN ledger) alive in the object and record keys.
- `package_digest(p)` is new but it is an `@query` over inputs, not a mechanism beside one.

## Checked against ONE_PATH and the 10-06 doc
ONE_PATH: one key speller, reads recorded by the frame, digest of the answer, derived codec, one validity
rule, one restore path (the hold deleted by it), a query writes only its answer — nothing here keeps a
verdict beside the engine. 10-06: §6.2 steps 1-7 are exactly the list above; §6.5's durability tiers are
`package_digest`; §7.3's gates (60 / 300 ms) are the cost table. Prior attempts: DB 07 d (saved syntax,
nothing loaded until asked, ~1.3 s), the hold-deletion family (hd-*), DB 08 `program_key`. REFUSED by the
lead and not proposed: a program-level "standing verdict" deciding held per file (a second hold).
