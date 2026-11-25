# Replay report: lane spec-harness (transcript cse_01QBqJunmLveoUPzoVNUMNKB)

Bundle: `/work/out/avra-lane-replay-spec-harness.bundle`, prerequisite e2bce925. Branches:

| branch | base | head | lane's head |
|---|---|---|---|
| `store-p0` | 48cbe855 (group3-base, held) | ada031eb | 459e07b6 |
| `group3` | 48cbe855 (group3-base, held) | 9a2d9b78 | e76033b4 |
| `group3r` | 60e0c1ab (false-refusals/g3c, held) | e1581bb4 | c6cf7fcf |

No `-wip` branch: the lane's last commands left both worktrees clean (store-p0 amended, group3r committed).
Group 1/2 ends e09f912f / 8fe404a4 are already in held 48cbe855's history, so nothing to rebuild there.

## Rebuilt commits

### store-p0 (one commit, amended three times by the lane)
| lane sha | new sha | subject | verified against | notes |
|---|---|---|---|---|
| dc727c07 → cbeb39ab → 705b8b08 → 459e07b6 | ada031eb | store: a walk over what a store holds ends, whatever it holds | each edit's printed output (python asserts, grep lines, fmt counts); first-commit stat; witness stored_cycles_test 5/5 | UNCERTAIN (1 line): the first commit's stat is 230 insertions against the lane's 229. The extra line is in stored_cycles_test.av, from my fmt (48cbe855 compiler; the lane formatted with its 02e216a2 compiler). Lines 1–111 match the lane's own Read of the file. Test file taken whole from the full transcript's Write. |

### group3 (on 48cbe855)
The first commit applies Fbulk3.patch. It was rebuilt from the controller's deletion-F-bulk-wip.patch (on 735eb06d) by replaying, in /work/avra: the orphan cleanup, prune_imports over `make try` #1, cut_sites over `make try` #2 (62/60 errors against the lane's 63/60; the one missing is the orphan parse error, already cut), the twenty test ports and the split. Fbulk2.patch matched to the line (16569; testport 1185). It was then applied on 77f0b87b + rebased 641372f8 + 7c99889b (the held equivalents of bbbebcad), with the family-code cut. Fbulk3 stat matches: 54 files, +4, −15691.

| lane sha | new sha | subject | verified against |
|---|---|---|---|
| 5e14810b | 3e79d8bf | WIP deletion F, bulk: the old path's Workspace, Program and their callers (compile-red) | Fbulk3 stat; std-avrac check 78 errors (lane 78) |
| 179a76cc → (refolded, sha not printed) | 96c963fc | deletion F, bulk: forty-two tests … and their fixtures | 41-file stat before the fold; fold diff "1 file, 46 deletions" |
| 3967168a → (rehashed by fold) | efecbc57 | WIP … what the old path alone reached, to a fixed point | delete-loop counts and check errors per step |
| 07b5b745 → … | e905332d | WIP … the old path's core types (Workspace, Program, Analysis) … | per-step outputs |
| 3ef5468c → … | 13d360d2 | WIP … the cli's old-path command (family-hashes) and imports; testing/old_path | per-step outputs |
| 72e38813 → … | 9bea6748 | WIP … fmt, and the impls the deletion emptied | per-step outputs |
| 4d40ba8b → 136d994b | cbc395e0 | WIP … cli's dead imports and what only they reached | per-step outputs |
| 004b454b → 11a10d9e | cf1d9a42 | WIP … cli's imports of what the deletion took | **group3-base..group3 stat: 133 files, +28, −25883 = the lane's exactly** |
| 2c1551f7 → e76033b4 | 9a2d9b78 | ctx: the shared typer's word on a ctx form is a defect, never reached | every ctx step's output identical |

### group3r (cherry-picked onto 60e0c1ab, as the lane did)
| lane sha | new sha |
|---|---|
| 836888eb | 1d3cd9e8 |
| 5c3d9c2a | d70a5b0e |
| 865d1d29 | 985c88e4 |
| 9aa91d74 | 0fc1575b |
| 9a606ea8 | 22e160cd |
| d0825c29 | c65e4020 |
| 4572075c | fd5f8b17 |
| 06b4930d | d2d11d26 |
| c6cf7fcf | e1581bb4 |

The three conflicts came up at the same commits the lane hit (structural_workspace_test DU, read_set_workspace_test DU, decl_facts_test UU), resolved the lane's way: the ports' version wins and the deleted files stay deleted. The lane's final listing (ZoUCa9eG) matches apart from the shas.

## Where the replay departed from the lane
- **delfn.py.** I first rebuilt only its original (line 23653). The lane had changed it in place five times since (WdnsiBmP, NsGckDpH, AUCrcQcy, NYZQayFk, nGj3cgoM). With those applied its `head -30` matches. I reran the one deletion it drove: 337 items in 47 files, −2688, the lane's numbers.
- **g3loop prune.** It took three checks where the lane's took two. It ends in the same place (159 errors, 0 not_exported), and the stats of the commits that follow match.
- **cli idioms after "fmt, and the impls".** My run hit its 1800 s timeout: the stale-cli-cache hang the lane itself found. That check only reports. I cleared the cli cache, and the prune loop then matched to the line, with cli idioms exit 0.
- **Commands not run:** uploads (curl), cost runs, the repro1 scratch package, and the hang/gdb investigation (caches only). I also skipped the red-before test toggles, which revert the fix, run, and reapply it.

## Compilers
The committed seed can't build this tree. I used the lead's chain from /opt/avra-tc: a73903d2 → 6abff86d → 48cbe855 (gen-1, gen-2). The b56 → b57 hop needed `[lifted] memory = 64` in packages/cli/avra.toml, only in the chain worktree and reverted afterwards. The 02e216a2 compiler (gen-2), the one the lane used, ran the group 2/3 replay, so the error lists match.

## Receipts
- Fbulk2.patch: 16569 lines (lane 16569); testport.patch 1185 (lane 1185).
- Fbulk3.patch: `54 files changed, 4 insertions(+), 15691 deletions(-)` (lane: the same).
- group3-base..group3: `133 files changed, 28 insertions(+), 25883 deletions(-)` (lane: the same).
- store-p0: `make avra` ×2 from the 48cbe855 gen-2 compiler: gen-1 rc=0, 0 errors; gen-2 rc=0, 0 errors.
- store-p0 witness `std-program/src/tests/stored_cycles_test.av`: 5/5.
- store-p0 `AVRA_SUITE_ALL=1 avra test packages/std-program`: 470/471. The one red is the pinned sandbox case "a store that can't write", as in the lane's run.
- group3r: `make avra` ×2: gen-1 rc=0, 0 errors; gen-2 rc=0, 0 errors.
- group3r `compiler/tests/witnesses_test.av`: 11/13. The same two cases (lines 37, 47) are red on 48cbe855 itself and in the lane's own run (transcript line 46958): pre-existing, layer-commands' four silent codes.
- Bundle: `git bundle verify` okay. Its heads are store-p0 ada031eb, group3 9a2d9b78 and group3r e1581bb4. Its prerequisites are e2bce925, plus 0b8fdb09 and d12f29ce, both ancestors of e2bce925. A fresh clone fetches all three heads.
- Not run, per the brief: the cost slice and the full gate. The lane's own next steps were never done: squashing the WIPs, the leftover-dead sweep and the group 3 gate. So the WIP commits stay WIP, as the lane left them.
