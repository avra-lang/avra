# ci-design status (2026-10-17, ~13:30 local)

## Done / open
- #858 (features as 3 path groups): rebased onto main, force-pushed (test-paths). Carries only its own 4 commits; ci_invariants + shards --check-splits pass. GitHub showed DIRTY right after the push (recomputing); re-check.
- #874 watcher reads behind-ness from compare (green PRs). #881 (stacked on #874): only the order's owner may merge (disarm others), ci-image dispatch on .github/ci merges. Land #874 first. The watcher runs main's pr_watcher.py, so neither works until merged.
- K1: stood down (db-gather has it). Emit parallelism: not worth it (measured, sent earlier).

## Why the features pre-output phase grew (in progress)
Facts from job logs (runs 39061506996 @d76ec8f8 vs 39064532277 @2c7977a5, both whole-main dispatches):
- features job 905 s -> 1413 s; pre-output phase 756 s -> 1217 s; tests identical (7218/7218), peak RSS 4.31 vs 4.37 GB.
- The two commits between them (#860 ui fetch, #867 watcher) touch no compiler or features file; the other shards did not slow (632->496, 612->604 s). Not runner variance.
- prepare took 296 s in the first (compiler cache MISS for the tree key: built from the latest release + make avra generations, so the handed-down .avra-cache was warmed by builds of THIS tree) and 100 s in the second (EXACT compiler-cache HIT: no builds, the handed-down store is the cached one from an earlier commit).
- Hand-down tar 848 -> 866 MB (store 837 -> 855 MB; store cap 600 MB did not bite: "store before 978 / after 837" in the first, unchanged in the second). Budget fail is at 1 GB.
- Across 16 recent runs, features wall is 559 s (prepare 1887 s, i.e. a long build) up to 1850 s (prepare ~270-330 s). Long prepare correlates with fast suites; a short prepare (cache hit) with slow ones: the suites compile against a store that is held less (older store, tree moved).
- Not yet proven: `held N/M` is not printed in suite jobs, so the "held less" claim is an inference from the correlation. A local cold run of `avra test --time packages/std-avrac/src/features` is in flight to see which phases (analyze/lower/emit) carry the cold cost; next is the same run warm after a one-file edit.

## BLOCKED (13:45)
The local cold features measurement cannot start: the data volume has 2.0 GiB free (watchdog floor 2048 MB refuses; `df` 100%). I may not delete (my rm of my own 695 MB scratch dir .avra-cache.cold-aside in avra-whole-names was denied). Needs: someone to free disk (or delete that dir), then I run `./avra-try test --time packages/std-avrac/src/features` cold, then after a one-file edit.
Cheaper CI-side proof meanwhile (no disk needed): add `--time` to the suites step on main dispatch so the job log prints `held N/M` and the analyze/lower/emit split; that settles "held less?" from the next run. I have not pushed that; say go and it rides #858.

## 13:55 #881 rebased
#881 now holds only rule (o) (owner-only merging, 4 fixtures, 36 scenarios pass) on top of main (#896 landed the behind-by rule and ci-image dispatch). `gh pr edit` lacks scope, so #881's title/body still describe the old stack: read the diff, not the body. #874 is superseded by #896; close it.
Pre-output investigation: still blocked on disk (see above) unless disk is freed.

## 14:10 Findings on the pre-output growth (CI logs only; disk still blocks local runs)
- My "prepare cache miss -> warm store -> fast suites" lead is REFUTED: 11 recent PR runs all missed the exact compiler cache (prepare 268-831 s) and every one has features at 1372-1852 s. Only main dispatches hit the exact cache (97 s) and they are no faster (1683 s).
- Features wall on main runs, by commit (s): 5a7d552d 541, 754c828c 711, b5eddc83 1012, 0726493e 1056, d76ec8f8 905, 4ce90425 1022, 2c7977a5 1413, d273a756 1537, 0f8f3151 1604, 45b41983 1733, 2c2a8d80 1455, 4e4f23dc 1223, 4e12a9fc 1583, cbf99386 1683. A day-long climb, ~3x.
- 4ce90425 -> 2c7977a5 changed ONLY tools/pr_watcher.py yet features went 1022 -> 1413 s. So a share of the movement is not the tree: runner/host variance (different Azure regions seen: eastus, northcentralus, centralus) or store state. The trend (541 -> ~1650) is real on top.
- Peak RSS 4.3 GB in both; no OOM signal.
- Next measurement is in place: #858 (rebased onto main again, force-pushed) now runs `avra test --time` in the suites step, so the next main dispatch logs the phase split (analyze/lower/emit) and `held N/M` for the features shard. Read that before changing anything.
- Hypothesis to check with it: the shard compiles the whole std-avrac program (~1100+ files) for tests; its cost grows with the tree and with every compiler change that moves the store, regardless of hold (db-warm's flat compiler number is a warm run, the CI suite is a cold-ish compile).

## 15:20 Where the features wall goes (from the --time logs of main push run 39097405041 @6449beae; local logs since cleaned)
Per shard job the suite prints `time:` lines. Every std-avrac shard compiles the WHOLE package cold: `held 0/1131` (analyze 25 s, lower 23 s, keep 13 s, emit 70 s, parse 16 s ~ 160 s on a 4-core runner). Nothing is held because the hand-down store carries no proofs/objects for the test program, and each job is a fresh machine.
Wall vs compile, by group: core 145 s wall / 151 s compile (all compile). features-b 637 s wall / 169 s compile phases. features-a 501 / ~205. features-c 816 / ~183 (a second derivation of 417 files, emit 43 s, is the programs' evaluation build).
=> 330-630 s of every features group is NOT compile: it is the program tests (150-290 per job; "eval == native == expected" lines; ~3-4 s each).
Program-test count is FLAT today (391 -> 393 `.expected` under features), so growth is per-program cost or shard assignment, not count. The 3x climb (541 -> 1700 s) is not explained by count.
Design fact (suite.av `suite()`): a program is `owed` (evaluated by the interpreter at build time) unless `store.has(proved_key)`; the proof key is path + expected text + texts of the files its module sees (NOT the compiler). In CI the suites' store is prepare's, which never ran a suite, so every program is owed in every job, on every PR and main run. Proof rows are valid across runs while a program's reachable files are unchanged.
Proposal (not built): persist proof rows across CI runs. Cheapest shape: after a main push run's suites, save the `proved` Unit rows (a few KB per program, ~400 rows) as a small cache/branch file keyed by nothing but their own keys; prepare restores them into the store before the hand-down. A PR then re-evaluates only programs whose reachable files changed. Expected: removes the evaluator leg (the 330-630 s per group) for unchanged programs; the 160 s whole-package compile per shard remains (second lever: share one compiled suite binary across shards).
Measurement still owed (needs a compiler: local build/ was cleaned): per-program eval seconds and how many programs are owed per CI job. Smallest instrument: under `--time`, print `programs owed N, evaluated in S s` from suite.av `suite()` around `evaluated(...)`. I did not write it: no local compiler and the disk is the limit.

## 00:30 Owed live check
Watcher's own dispatch of an unchecked main head is unproven live. On the next bot-pushed merge (seed refresh): within ~5 min of the push (MAIN_GRACE 180 s) the pr-watcher log should say "main <sha> has no `checks` run — dispatching one" and a workflow_dispatch checks run should appear on that sha (`gh run list --commit <sha> --workflow=checks.yml`). Failure guard (issue open/close) is proven (#1021).
