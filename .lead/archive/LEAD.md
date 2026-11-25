# Lead handoff (team-lead, Compiler DB + nodes), 2026-10-08 ~08:50 PDT

I lead epics avra-8sb5.57 (Compiler DB) and avra-8sb5.89 (A node is one declaration). Repo /Users/tristan/projects/tristanMatthias/avra; main on GitHub avra-lang/avra, merge queue only. Tasks: TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db, `tasks` CLI.

## Owner orders in force
- Speak only for merges, drops, big decisions, blockers. Routine lane traffic: reply "-" or nothing.
- AFTER RESTART: respawn every lane on **haiku** (Agent model "haiku"). Lead them with small explicit tasks; I keep all design; review every diff before a PR (one opus reviewer for correctness-critical ones). See memory haiku-lanes-restart.
- Lanes report ≤10 min and end their turn ONLY to wait on a run.
- No whole suites on Sprites; targeted tests only, the PR check runs suites.
- Owner wants extreme centralization/derivation/beauty (the nodes plan).

## Lane handoffs: this directory (handoff/<lane>.md)
db-store, nodes, db-a3, db-inputs-2, db-explain-2, fast-loop, db-measure. Read each before respawning.

## Open PRs (mine)
- #429 MERGED (code_hash keys). db-code-hash-shape must rebase onto main.
- #435 nodes-trait: `.V as r` (nodes step 1a). Needs checks → queue. NOTE: docs/2026_10_08_NODES.md was NOT included; the design draft is scratchpad/NODES_DESIGN.md (update it: no `syntax` clause/indent; step 5 = existing `grammar { … -> When }`; step 7 dropped; sugar = `fn means() -> Code?` + driver rule; needs assembly-time template parse, error voice hook `says`). Commit it in the next nodes PR.
- #434 MERGED.
- #411 db-inputs-d2 e1fa559: tools as inputs. Rebased, review fixes in; run targeted tests + gate, squash (vs merge-base!), then queue. .258 folds in after.
- #396 store design doc: waiting on owner review. #345/#338/#339: not mine to touch.

## Unpushed / stacked branches
- db-code-hash-shape b9603a2 (types by shape, codec in key; on #429) — Sprite run unread.
- db-store-05c-drafts 8b66182.
- nodes-delegate d39f9c1 (step 1b-pre: `collect enum E: T`), WIP: last failure "`impl Size for` names no trait" (trait name resolved in @std/meta's file, not the landing file); unbuilt fix in core/rebuild.av. Squash out qtrace `Q dlg` probes + the --no-verify commit 7ff4037. Owe db-a3 the file list (in nodes.md).
- db-node-identity 84e46b1 (step 4: rule shapes by id; collision must be a NAMED VOICE, not an undefined call; maybe a bridge landing — build probe unread).
- rule-meta-l1 1f76afa (.378 L1, rules into @std/meta) — Sprite run Mac-mini-60861-1791449028 unread.
- link-lld e69b80e (lld linker; two-line change after #411; byte-identical witness owed).

## Merged this session (07→08 Oct)
#394 #395 #397 #398 #400 #401 #403 #404 #405 #407 #408 #409 #410 #412 #413 #414 #415 #416 #417 #418 #419 #420 #422 #423 #424 #425 #426 #428 #430 #433.
Fast loop: make try ~4 s leaf / ~12 s core edit; warm==cold objects; mac bootstrap fixed (#433).

## Nodes road (docs/2026_10_08_NODES.md, epic .89): 1 `collect enum E: Trait` (1a `.V as r` = #435; 1b-pre written; 1b moves Control on, deletes flow_derive) · 2 check/lower as trait methods (deletes semantics_of) · 3 shape-reading trait defaults · 4 stable node identity (db-a3) · 5 grammar `-> Node` derived builder + rule-driven printer · 6 sugar `means()` (prove on `when`) · 7 dropped.

## My tooling
- run_end_watch.sh: /private/tmp/claude-502/-Users-tristan-projects-tristanMatthias-avra/3aeb1f09-0e16-40f5-a723-2dec304f3e44/scratchpad/run_end_watch.sh 40 (background; reports which lane's Sprite run ended).
- Queue watcher one-liner: wait for `test` pass, enqueuePullRequest via graphql, poll MERGED/DROPPED (see earlier commands in transcript 9b89a1a9…jsonl).
- PR bodies in scratchpad/*.md.
- Reviews in /private/tmp/claude-502/-Users-tristan-projects-tristanMatthias-avra/3aeb1f09-…/scratchpad/db-review/.

## Lessons tonight
- Lanes kept pushing without `gate_changed --no-keepers` → idioms red ×4. Require it + `make keepers-pr` before every push.
- cli tests spawn build/avra: install the product before running them (#416 dropped twice on this).
- A PR touching no cli doesn't run cli suites in its check; the train does.
- Sprite avra-phase-c is wedged/slow (.77.4).

## After restart (2026-10-08 ~09:20)
- Lanes respawned on haiku with "-h" names: db-inputs-h, nodes-h, fast-loop-h, db-store-h, db-a3-h, db-explain-h, db-measure-h. Rules: handoff/HAIKU_RULES.md. One task → report → stop; I give the next.
- #435 queued (watcher: scratchpad/qwatch.sh 435). #411 CI red: idiom pronoun_lambda in build.av + cli build_report_test (both headers missing) — db-inputs-h reproducing.

## State at ~14:35 (after haiku respawn)
Merged today after respawn: #434 #429 #435 #437 #439 #440 #411 #442 #443 #444 #446 #448 #449 #450 #452 #453 #455 #456 #458.
Queued/open: #454 int-key (read-cost fixed d06cfb8), #459 build-rules, #460 embed-watch, #461 seed-refresh-2 (unblocks node-identity landing 2: RuleEntry.kinds + stale-rule line; db-a3's reference in its scratchpad a3-l2-ref.txt), nodes PR pending (nodes-1b 7010874: `impl Meaning` + @delegates + docs/2026_10_08_NODES.md; nodes-h verifying enums_test on gen 2).
Lanes now: nodes-h (2 → then 2d: bodies read self fields), db-a3-h (.183 spliced TypeRef resolves in decl.file), db-store-h (hermetic attacks + CI wiring, then .266 name-hash), db-inputs-h (graph-stats: counting behind a switch), db-explain-h (.171 --why reran list + delete cache aliases), db-measure-h (.210 reverse: check keeps objects), fast-loop-h (.218 verdicts-first: 3-field row guard + pre-attempt verdicts).
Parked with recover/* branches: prekey (.193 no gain), query-two-annotations (.182 needs expand-before-analyse ordering design), record-reads (.203 needs cross-Db read naming design).
Design owed by me: .182 ordering, .203 record reads, .198 Db owns its tables, .197 eviction, .211 keyless id compaction.
Mac disk ~2-3 GB free (floor 2 GB): lanes use Sprites; all Sprites repaired.
