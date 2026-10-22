# Lead handoff — 2026-10-08 ~19:15 local

You are team-lead of the Compiler DB campaign (avra-8sb5.57) and the nodes epic (avra-8sb5.89).
This file is the whole state. Read it, then `ListAgents`, then act.

## Owner rules (non-negotiable)
- Lanes run on **haiku** (`Agent` model "haiku"). TIGHT loops: small explicit tasks, report, next task in the SAME reply. Never park a lane.
- Lanes obey `handoff/HAIKU_RULES.md` (this dir). Every lane prompt starts "FIRST read …/HAIKU_RULES.md".
- Owner is short on tokens and has ADHD: terse, action first. Routine lane traffic gets "-" or nothing. Speak only for merges, drops, big decisions, blockers.
- Never `rm -rf`; never pkill by pattern; never push main; land only via PR + merge queue; never `--no-verify`; never `git stash`; rebase onto origin/main only.
- No whole test suites on Sprites (cost). Targeted tests + keepers there; whole suites on the PR's GitHub check.
- Never edit the primary checkout /Users/tristan/projects/tristanMatthias/avra (lanes have their own worktrees).
- Keep current pace (owner declined line-by-line diff review before queueing).
- When the owner Ctrl-C's, all lanes die: respawn them with their exact task (see the lane table).

## Landing mechanics
- PR: `gh pr create -R avra-lang/avra --base main --head <branch> --title … --body-file …` (body ends with the 🤖 Claude Code line).
- Queue + watch: `(sh .lead/scripts/qwatch.sh <n> > .lead/qw<n>.log 2>&1 &)`. It waits for checks, enqueues, polls MERGED/DROPPED. `tail -1 .lead/qw<n>.log`.
- On FAIL/DROP: `gh pr checks <n> -R avra-lang/avra`, then `gh run view -R avra-lang/avra --job <id> --log | sed 's/^[^Z]*Z //' | grep -E "NEW|differing|✗|eval !=|error"`. Send the lane the exact failure. Lanes must run `sh tools/gate_changed.sh --files <changed .av> --packages <pkg> --no-keepers` (fmt + idioms) + `make keepers-static` before every push.
- A DROPPED PR with no failing check = a train-mate failed; just re-run qwatch.

## Disk (CRITICAL)
Mac hit ENOSPC at ~19:00 (everything froze, even SendMessage). Owner cleared every worktree's `.avra-cache` → ~10 GB free (disk 99%, 878 GB used; `build/` dirs total only ~3 GB, so the bulk is elsewhere). Owner was asked to run:
`du -sh ~/projects ~/Library/Caches ~/Library/Developer /private/tmp /private/var/folders ~/.cache ~/.cargo ~/.npm 2>/dev/null | sort -h` — follow up and advise what's safe. `avra-land-batch-wt/build` (1.4 GB) is deletable. Lanes' standing rule: `rm -r` their own build/cache-attacks, build/code-hash-attacks, build/seed-check after each run; heavy runs on Sprites.

## PR queue (at handoff)
| PR | branch | state | note |
|---|---|---|---|
| #464 | graph-stats | DROPPED, no failing check → re-queue | explain --stats read calls / abandoned frames (counting switch) |
| #468 | verdicts-first | DROPPED, no failing check → re-queue | kept verdict cheap-row reads up front; CACHE_ATTACKS section filter |
| #471 | edit-loop | queued (qw471) | `make edit-loop` |
| #474 | why-reran | queued a long time — check | explain --why "reached by the change"; cache aliases deleted |
| #479 | own-db-law | queued (qw479) | a query reads its own Db; foreign read refuses |
| #396 | db-store-design | queued (qw396) | DB 05 store design doc (owner decisions on .174) |
| (not PR'd) | explain-moved @ ae5b131 | stacked on why-reran | explain reports a held file's text move; PR after #474 merges (rebase onto main) |
| (not PR'd) | nodes-2e @ 5fc22c1 | on 2d (#472 MERGED) | rebase onto main, then PR (nodes-h) |
| (not PR'd) | one-okey-2 @ 1400365 | db-store-h verifying | see db-store-h |
Other teams' PRs (#481, #477, #465, #345) and the DO-NOT-MERGE #338/#339: not ours.
Closed today: #476 (keyless id reuse — breaks id-order read contract), #445.

Merged today (ours): #439 #442 #443 #444 #446 #448 #449 #450 #452 #453 #454 #455 #456 #458 #459 #460 #461 #462 #466 #467 #469 #470 #472 #473 #478 #480 (+ #411).

## Lanes (all haiku, all running at handoff)
| lane | worktree / branch | task now | next |
|---|---|---|---|
| db-inputs-h | avra-db-inputs / shape-memo (uncommitted) | `type_shape` as a Workspace query (Family Shape, keyed by TypeId), threading the open list, settling only loop-free walks (texts identical); ONE walk shared with the lone seam (`lower(a)`), callers take `shape: fn(TypeId)->string`; warn-skip `same_on_disk` in store.av. Witnesses: identical 676 shape-text dump, keep/code_facts time before/after (keep 8.2 s, code_facts 7.15 s today), code_hash_test, code-hash-attacks. Report before push. | — |
| nodes-h | avra-nodes / nodes-2f | 2f: components, when, impls method_call_*, closures → bodies into records' `impl Meaning`, shared dispatch fns die | rebase+PR nodes-2e, then 2f; then the Stmt/Pat halves of step 2 |
| fast-loop-h | avra-fast-loop / verdict-decls @ 2bb73fb (local) | per-declaration const verdict ('t' type-shape rows, 'n' names row). Must add staleness attacks f (body-only type read), g (variant literal), h (method receiver) in CACHE_ATTACKS `vd`, and hook them or fall back to the full outline. Report before push. | object key part (2) of .218 is MY design, not theirs |
| db-store-h | avra-db-store / one-okey-2 @ 1400365 | (1) check-after-check held count (db-measure-h's parallel version held 0/492 with `language.defect: IntLit's flatness read before a mut seat sealed it` because gathered sets were read during holding; ref patch scratchpad/one-okey-v2.patch); explain witness on core/nodes.av (main READ vs fix HELD). (2) DB 05c-1: link @std/hash BLAKE3 at both link sites, no callers, `make bootstrap` green | 05c-2 keys → BLAKE3 (seed ladder), then packed store (.174 rows 3–8); handoff/db-store.md |
| db-a3-h | avra-db-a3 / kids-derived @ 9beaf9c | LATENT MISCOMPILE chase (top priority): an explicit no-op `kids = []` on Block makes gen2 fail to parse cli main.av:37; flipping NodeSemantics default kids to `kids_of` makes gen2 segfault. Keep build/avra.gen1/.gen2; gen1 parse check → IR diff gen0 vs gen1 of a parser fn | then .195 (std-avrac test 2.2 GB peak; findings commented) ; recover/kids-derived holds step 1 |
| db-explain-h | avra-db-explain / db-names-2 (clean @ origin/main) | DB 03: land origin/db-names (4 commits) onto #385. DECIDED: keep #385's shape (`mint` computes key, `within` = owner path), take db-names's sibling rule (counter per file,within,kind,maker,name). Insert-above attack FIRST. | then origin/static-names (2 commits, 66 behind) ; then DB 03b codec |
| db-measure-h | avra-db-said (detached) | bisect the make-try regression: yesterday leaf `make try` 6.1 s (Sprite receipt, .57.257), today edit-loop 24 s leaf / 77 s core. Suspect #443 (type_shape) / #459 | — |

## Decisions made today (don't re-litigate)
- .203 → LAW: a query reads its own Db or a scratch Db born inside it; a Db born before the outermost frame refuses loudly (#479). read-cost bumped 3 rows for it, reason in the budget file.
- .211 → no id reuse (id order is a contract); tombstones halved by shared values (#480); last ~73 B/removed id unidentified.
- .197 → opt-in `with_cap(n)` epoch eviction with arg free list (#467).
- .198 parked (needs Db-owned AnswersUnder<V> — type-system design). .192 parked under DB 06 (methods <1% of a one-edit check).
- .183 parked as MY design: generated members must be RE-HOMED into the landing file's arena (spans pointing home, as `within`'s copies do), not routed per node. Findings on ticket; recover/hole-lands, recover/hole-lands-2.
- .182 parked (expand-before-analyse ordering): recover/query-two-annotations.
- Nodes step 3 (kids/heirs from shape): residue = Block, Lambda, Comp, Body, Component, Match, Catch, Spawn, Collect; parked behind the miscompile.
- Speed: soft speed ratchet landed (#478; per-job baselines from main push + trains). Owner wants each hot-path change to report before/after timing; a nightly edit-loop run was proposed, not approved yet.
- Owner direction: fix by making things QUERIES, not by patching hand-written caches (the DB migration is the answer to regressions).

## DB migration status (corrected; from PRs+branches, not tickets)
DB00 ✅ mostly · DB01 ✅ · DB02 🟡~80% · DB03 🟡~30% (db-explain-h) · DB04 🟡 partial · DB05 🟡~35% (code-hash merged; store format not started; db-store-h) · DB06 🟡~15% (user @query saved answers only) · DB07 🟡~10% (fast-loop-h) · DB08 🟡 small · DB09 ⬜ (kept_settle.av 414 lines) · DB10 🟡 (#446; .182 open) · DB11 ⬜ · DB12 🔴 37 families (tools/families.ceiling).
Lesson: tickets have no children; ALWAYS check merged PRs + `git branch -r --sort=-committerdate` before saying "not started".

## Owed by me (design)
.183 re-home design; .218 part (2) object key per declaration; .182; DB 03b codec; nightly edit-loop (ask owner); the owner's disk follow-up.

## Files
- This dir (handoff/): HAIKU_RULES.md, per-lane handoffs (db-store.md, db-measure.md, …), NODES_2.md, INST_FACTS.md, 2026_10_08_NODES.md.
- .lead/scripts/qwatch.sh, .lead/one-okey-v2.patch.
- Tasks: `TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db tasks …` (never the MCP task tools).
- Design: docs/2026_10_06_COMPILER_DB.md (§6.3 names, §7 speed, appendix), docs/2026_10_08_NODES.md.
