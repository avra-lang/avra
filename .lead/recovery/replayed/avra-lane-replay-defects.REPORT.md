# Replay report: lane `defects` (transcript cse_01QBqJunBfP8CSkAgkaCuvu3)

## Rebuilt commits
None. The held ref refs/lanes/defects/qtimes = 43a6cfa2 is the lane's last commit (04:19:40);
the transcript shows no later `git commit`. No bundle is produced.

## Uncommitted work (delivered as a patch, by the controller's decision)
`avra-lane-replay-defects-wip.patch` (sha256 d0de7c90…793296), 3 files, +146/-39, against
**109c1e37** (the lane's /work/prof was a detached worktree there).

| step | source in transcript | verified against |
|---|---|---|
| disk_store.av = cr's copy at 00:45 + `mapping_of` fix (ZDpTFwJc) | PHHGtmp4, ZDpTFwJc | equals b94091e9's file: that commit (FtRi5SFA) followed with no edits between, and its fmt --check passed |
| query_engine.av, worked_ahead.av copied from /work/c2 | UGr7KTTT (02:43) | equal to 43a6cfa2's: no c2 edits between 02:43 and the 04:19 commit; the lane said "Clean (no probe code left)" |
| the take's sub-phase probes (read, decoded, taken, inputs/stood proved, settled) | UGr7KTTT python, extracted verbatim | printed "probes on"; the lane's build of that tree was green (pf4: build 0) |
| cut-3 probes: "taken: lent indexed" (query_engine) and "taken: rows read" (worked_ahead) | LU4YXvRV python, extracted verbatim | printed "ok"; `grep -B12 'self.lent.push(lent)'` matches lines 1200–1212 of the transcript exactly |

Earlier probe edits (XRmphTUR, HvGvXuaU) were overwritten by these file copies, so the patch leaves them out.

## UNCERTAIN
- No build was proven. The lane's own build of the final tree (pf5) never reported back, and here
  `make bootstrap` fails: the only seed (a8fb2188) is 2,444 commits behind and refuses
  std-text/text.av. The controller chose not to spend a build on this.
- The probe edits were never fmt-checked, by the lane or here. They are MEASUREMENT ONLY and are not meant to land.

## Receipts
- `git fetch /work/in/all-lanes.bundle` → refs/remotes/in/lanes/defects/qtimes = 43a6cfa2
- worktree /work/prof @109c1e37; `git checkout b94091e9 -- disk_store.av`; `git checkout 43a6cfa2 -- query_engine.av worked_ahead.av`; both probe scripts run with `python3 -I`
- `git diff --stat`: 3 files changed, 146 insertions(+), 39 deletions(-)
- `make bootstrap` → exit 2 (refusals in std-text/text.av: host_seat; `Seating` has no `written_into`/`read_from`)
