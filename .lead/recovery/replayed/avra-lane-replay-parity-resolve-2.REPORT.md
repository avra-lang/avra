# Replay: parity-resolve-2 (transcript cse_01QBqJuoGGj1nb24ZC7g83MU)

Branch `avra-lane-replay-parity-resolve-2`, on held `refs/lanes/parity-resolve-2/laws2` = bb4859f1.
Bundle: `/work/out/avra-lane-replay-parity-resolve-2.bundle`, prerequisite e2bce925 and its ancestors (the same 30 boundary refs `all-lanes.bundle` lists). No `-wip` branch: the lane's tree was clean after its last commit.

| original | new | subject | verified against | notes |
|---|---|---|---|---|
| bbe499c0 | 83595291 | cost: an item that runs no statement … asks nothing of its file's entry … | transcript `git diff --stat` [9Dw4MBM3] (with 74fa57d1's source): item_assignments 5 +- | replayed HvKZE2iz (entry_share early return) |
| 74fa57d1 | 5ca0ed14 | resolve: an impl of an undeclared type beside a generator is refused (type.impl), not a query cycle … | same diffstat: item_methods 84, item_scope 7, total 73+/23-, exact; witness `refuses.expected` matches the pinned text the lane printed [d4tcCNRw] | replayed X1cZJQg3, HqzqxJWj, fmt --write; the trace and cut-query experiments (query_engine, law_findings, item_names, module_kept/winners) were reverted by the lane and are skipped; witness main.av taken from the repro the lane printed [sr3phW9V]; refuses.expected re-pinned with PIN=1 and matches |
| 3148393a | 1e177af8 | witness: a type one file re-exports, imported by another file from where it is declared, builds and prints … | the lane's printf commands [sLjBQUtx], [bKmpKwhs] | prints.expected = `a\n` |

Not rebuilt, since they are not in git: the lane's notes file `/work/avra-lane-parity-resolve-2.md` ("bisect notes"). Its bisect findings are in the transcript's AGENT messages at 03:28 and 03:50 (edit-signature +6 traced to `entry_share`; cost slice at 74fa57d1 "54 rows, 21 over, 21 fell"; edit-added +1 still open).

UNCERTAIN: none in the commits' content. The two whole-tree diffstats match exactly. Authors and dates differ from the originals, so the shas differ.

## Receipts
