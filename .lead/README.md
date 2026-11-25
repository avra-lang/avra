# .lead — the local campaign kit (thin index)

Nothing here is committed. The durable process lives in the tree.

## START HERE
- **`../.lanes`** — the BOARD: every live lane, its worktree/branch and its
  task. Update it every turn.
- **`docs/2026_10_11_THE_PIPELINE.md`** — the committed single source for the
  landing path (no merge queue: "up to date" plus auto-merge), Sprites, the
  watcher, the gates and the keepers. Read it
  instead of any landing note that used to live here.
- **`GOAL_2026_10_10.md`** — the current owner goal.

## LIVE SCRIPTS
- `scripts/watchdog.sh` — the local `launchd` clock for the committed watcher
  (`tools/pr_watcher.py`); see the pipeline doc §3.
- `scripts/store_attacks.sh`, `scripts/store_baseline.sh`, `scripts/witness.sh`
  — the DB store's acceptance and witness helpers.

## LIVE REFERENCE
- `store-explainer.html` — the interactive walkthrough of DB05.

## ARCHIVE (superseded; kept, never deleted)
- `archive/handoff/` — the old handoffs and lane rulebook, the nodes designs.
- `archive/LANDING_GUIDE.md`, `archive/WATCHDOG.md` — the landing and watcher
  notes the committed pipeline doc now holds.
- `archive/one-okey-v2.patch`, `archive/build/` — an old code patch and test
  output.
- `archive/` also carries `LEAD.md`, the 2026-10-08 handoffs, per-lane briefs
  and `archive/logs/` (retired watcher logs, including the dead `qw*.log`s).

## HEARTBEAT — a lane must never go silent (learned 2026-10-11)
A lead can only see a lane that FINISHES; a working-but-silent lane is invisible, and one lane went
quiet 28 minutes with no PR while the owner waited.
1. Every lane reports a one-line status every ~10 minutes (`still measuring X`, `blocked on Z`).
2. No PR and no receipt after ~20 minutes → open a DRAFT PR and push what you have. A draft is a
   heartbeat; silence is a failure.
3. Never end a turn without saying what you do next if you intend to keep going.
4. Blocked → say so IMMEDIATELY with the exact blocker; do not work around it silently.
