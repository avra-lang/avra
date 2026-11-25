
## Auto-batcher dry run against real GitHub (`batch --plan`)

Branch `batch-autobatcher` at 35dd8a8e (PR #631). Members: #623 #628 #629 #631 #625. Only reads ran against GitHub (`pr view`, `pr list`, `ls-remote`); local writes were object-only (`commit-tree`) and remote-tracking refs (`git fetch`). Verified after the run: no `batch-8` on origin, no batch PR, #631 still draft.

### Run 1: no evidence given

```
plan: would refuse: #623: cache-attacks is SKIPPED, so it did not run — pass --attacks-ran 623="<the Sprite result>"
plan: would refuse: #628: cache-attacks is SKIPPED, so it did not run — pass --attacks-ran 628="<the Sprite result>"
plan: would refuse: #629: cache-attacks is SKIPPED, so it did not run — pass --attacks-ran 629="<the Sprite result>"
plan: would refuse: #631: cache-attacks is SKIPPED, so it did not run — pass --attacks-ran 631="<the Sprite result>"
plan: would refuse: #625: cache-attacks is SKIPPED, so it did not run — pass --attacks-ran 625="<the Sprite result>"
plan: #623 (nodes-records-1a) merges cleanly
plan: #628 (sprite-sync-probe) merges cleanly
plan: #629 (queue-guard) merges cleanly
plan: #631 (batch-autobatcher) merges cleanly
plan: #625 (scenarios) merges cleanly
plan: batch-8 would be: PR title "batch #8: #623 #628 #629 #631 #625", members in order: #623 #628 #629 #631 #625
plan: it would arm auto-merge (squash) on the batch PR and retitle each member
plan: NOT BUILDABLE as given
```

### Run 2: a preview with labelled placeholder evidence (the real Sprite result is still to come)

```
plan: #623 (nodes-records-1a) merges cleanly
plan: #628 (sprite-sync-probe) merges cleanly
plan: #629 (queue-guard) merges cleanly
plan: #631 (batch-autobatcher) merges cleanly
plan: #625 (scenarios) merges cleanly
plan: batch-8 would be: PR title "batch #8: #623 #628 #629 #631 #625", members in order: #623 #628 #629 #631 #625
plan: the batch PR body would be:
plan: body | Integration of the members below (`sh tools/work batch`).
plan: body | 
plan: body | <!-- batch-members: 623 628 629 631 625 -->
plan: body | 
plan: body | Members, in merge order:
plan: body | - #623 nodes 5.1a — the maker reads optional, list and written-type payloads (17 builders gone)
plan: body | - #628 sprite: keepers-static runs on a Sprite; AVRA_PROBE_BUILD=one; a run prints its source hash
plan: body | - #629 land waits its turn; pipeline-status names what a landing would restart
plan: body | - #631 tools: the auto-batcher (sh tools/work batch)
plan: body | - #625 measure: the scenario table
plan: body | 
plan: body | Cache-attacks did not run for these members; the evidence given:
plan: body | #623: PREVIEW ONLY: no Sprite result yet
plan: body | #628: PREVIEW ONLY
plan: body | #629: PREVIEW ONLY
plan: body | #631: PREVIEW ONLY
plan: body | #625: PREVIEW ONLY
plan: would retitle #623: DO NOT MERGE (lands via batch #8) — nodes 5.1a — the maker reads optional, list and written-type payloads (17 builders gone)
plan: would retitle #628: DO NOT MERGE (lands via batch #8) — sprite: keepers-static runs on a Sprite; AVRA_PROBE_BUILD=one; a run prints its source hash
plan: would retitle #629: DO NOT MERGE (lands via batch #8) — land waits its turn; pipeline-status names what a landing would restart
plan: would retitle #631: DO NOT MERGE (lands via batch #8) — tools: the auto-batcher (sh tools/work batch)
plan: would retitle #625: DO NOT MERGE (lands via batch #8) — measure: the scenario table
plan: it would arm auto-merge (squash) on the batch PR
plan: buildable — nothing was pushed, opened, merged or retitled
```

### What the live run showed that the fixtures did not

- All five members pass the `test` check. Every one reports `cache-attacks` SKIPPED, so every member needs `--attacks-ran` before a real batch: the plan names each flag.
- Merge order and conflicts were checked for real: all five merge cleanly in the order given.
- Batch numbering skipped the existing remote `batch-4` and `batch-7`, so the first buildable number is 8.
- Member titles already carry "DO NOT MERGE: "; the retitle strips it so the result reads "DO NOT MERGE (lands via batch #8) — <title>". The plan showed the unstripped form before this was fixed.
- The plan now prints the body and each retitle the real run would post.

## Batch 8 evidence (prepared before #606 merged; #606 is now MERGED)

| member | kind | evidence | result |
|---|---|---|---|
| #623 | compiler source (features/*) | cache-attacks on origin/main + #606 + #623, composed locally at 80c7612c, nothing pushed | 0 failed: 373 builds (129 under a hold), link 13, turn-memory, gathered, static-names (17 objects), moved-tree, held-runs, cancel 11 steps |
| #625 | tools only | tools/db_measure/scenarios.py, a measurement script | no self-test exists: --attacks-na |
| #628 | tools only | tools/sprite-remote.sh, tools/work | tools/sprite_remote_test.sh: 16 checks, 0 failed, on the Sprite (Linux half) |
| #629 | tools only | tools/work, tools/work_test.sh, pipeline_status.py | tools/work_test.sh: 72 checks, 0 failed, on the Sprite (Linux half included) |
| #631 | tools only | tools/batch.sh, tools/batch_test.sh | tools/batch_test.sh: 52 checks, 0 failed (local) |

Batch plan, all members but #631 ready: #623 #628 #629 #631 #625 merge cleanly in that order. #631's new head dfc687fd has its test check running since 22:21, so the batch is refused until it is green. Build it then as a draft with `sh tools/work batch --draft --attacks-ran … --attacks-na …`.
- 00:40Z batch 9 = PR #657 (DRAFT, not armed, base main 97c0bcc5): members #607 #630 #609 #631 #634 #644; #616 dropped (conflicts with #607 on tools/cache_attacks.sh); evidence on composed tree ea864ada: cache-attacks 0 failed, std-avrac exit 0, cli 368/371 (same 3 sound-check failures on main 97c0bcc5). NOT yet built: #647, #655 (not composed); main is now c05da931 (#618 merged). Next: rebuild on c05da931 with #647/#655 if they compose, once told which set.
- 01:00Z #657 (batch 9) was built from the batch worktree with: sh tools/work batch --draft --n 9 --attacks-ran "630=composed tree ea864ada (main + 607,630,609,631,634,644): make cache-attacks 0 failed (379 builds, 131 under a hold); std-avrac exit 0; cli 368/371, same 3 sound-check failures as main 97c0bcc5" --attacks-ran "609=composed tree ea864ada: cache-attacks 0 failed; std-avrac exit 0; cli 368/371, same 3 as main 97c0bcc5" --attacks-na "631=tools only: tools/batch.sh, tools/batch_test.sh 52 checks" --attacks-na "634=tools only: removes tools/ep_b.sh" --attacks-na "644=tools only: ci/tools change; its test check is green" 607 630 609 631 634 644 (run from the avra-batch worktree on batch-autobatcher; #616 dropped, conflicts with #607 on tools/cache_attacks.sh).
- FINAL (db05c-reland): the 368/371 cli suite runs. cwd: /home/sprite/avra-build/avra-db05c/tree on Sprite avra-rb468 (worktree ../avra-db05c), no AVRA_* env set beyond the defaults. Command, run through sh tools/work run --for 60 from the worktree: ./avra test packages/cli > build/t-cli-main.log 2>&1 (on origin/main 97c0bcc5, with the tree checked out detached there; log build/t-cli-main.log). Two other full runs also showed 368/371: build/t-cli.log (composed tree ea864ada = main 97c0bcc5 + #607 #630 #609 #631 #634 #644), and build/t-cli-132.log (after make avra from origin/main 132bc456). All three fail the same three sound-check cases in packages/cli/src/commands/tests/sound_check_cache_test.av.
