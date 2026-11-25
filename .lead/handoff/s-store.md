# s-store handoff (2026-11-02)
Branch hd-store at 9945407d (= origin/hd-clean + 1 commit), pushed. Worktree ../avra-hd-store.
Untracked probes live in ../avra-hd-store/.measure (stale*.sh, recompute.sh, cold2.sh); delete packages/std-avrac/src/compiler/tests/probe_test.av before any commit.

## Done
- store-clean (cache-attacks b2) fixed: a3c62745, integrated in hd-clean by s-gate. pack.av `within_bodies`: window N keeps the newest heads whose chains stand on <= N bodies. tools/store_attacks.sh body flip hits the newest body, damages every 3rd octet from 1/8 in.
- Cold keep: 16.7 s (keep 16749ms, cli cold) = baseline; +2 s gone. 209 seals = 4.3 s, 8 whole seals = 2.5 s.
- 9945407d (NOT yet integrated): store_attacks.sh "second print" is a measured assertion (unit misses == 0 after AVRA_INLINE_RUNTIME=0 rebuild), replacing the unconditional fail. Ticket avra-8sb5.57.306 filed, id in MAIN_GATE row 12.

## Unverified
- The new assertion's grep (`Q	store	kind	get	miss	unit`) was never run: the probe needs `make try` to build the cli, blocked by #1. Must show a non-zero miss count today; use `grep -a` (trace lines in logs are binary-flagged).

## #1 (cli parse: ~77-170 "expected BREAK" on `command`) — NOT fixed
Repro (one `sh tools/work run`): append `// probe` to packages/std-avrac/src/compiler/answers.av, `make try` => 77 errors, status 2. Control without the edit: 0. `./avra check packages/cli` afterwards: 0 errors.
Facts: `cache show <rev>` of the failing store lists family@stamp: prints are `<binary digest>.<language_mark 4ee26b..>`; TWO binary digests present (3579431.. 14726 unit/1587 answer rows; 7e707be.. 1517 answer rows), plus `unit@own 48ef2c..` with no language suffix. Rows keyed answer@own<print>, key = node_key(Answer,[durable name "...#codehash", args hash]) (compiler/answers.av). Validity = Leaf digests (std-relation/db.av leaf_holds); a miss on an unstaged input is false.
Hypothesis space left: (a) a stale TextScan row stands with no/short leaves (leaves_of -> Unnamed => nothing judges validity); (b) reader print equals writer print because a comment-only change gives a byte-identical binary, so rows written by the rung chain on an older tree are "valid" for the reader — then the leaves (file_text, language_words) must be what differ; check Q leaf lines.
Next step: get a trace OF `make try` — AVRA_QTRACE reaches only `ask` events there (6564), no store/leaf lines; run the failing step directly: after the failed make try, run the standing compiler on packages/cli with AVRA_QTRACE=1 against the poisoned store BEFORE any successful run (the stale2 run ran it after and got 0 errors). Also dump a stored text_scan_of TextScan for std-cli/src/cli.av (opens_block false = stale).
Then .57.306: key rows by the answering query's transitive code hash.

## Standing reds not mine
store_attacks.sh S2 property (now measured), cache-attacks (a)/hold, keepers-a, cli/avrac suites (#1).
