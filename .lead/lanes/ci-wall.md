# ci-wall — 2026-10-14

## The tripwire

`tools/speed.budget`'s `ci-wall wall total 7000000` is read by
`tools/speed_ratchet.py --wall` in the `test` job (`checks.yml`'s "wall
budget" step), over the per-job and total wall ms `tools/ci_wall.py` collects
from the GitHub jobs API. `total` is the SUM of every job's own
`started_at`→`completed_at` clock — a WORK figure, not a makespan — so no
queue between jobs inflates it. The wall family is held HARD (no ratio);
`--accept` may only LOWER a row, so a raise is a human edit of the budget.

## Measured (current main)

- #721 run 38563160661 (base `02cd6ad6` = #716): **`wall total 7,746,000 ms`**,
  16 jobs — the worst full gate on record. #721's `test` reds at 7,741,254.
- db06-step3 run 38555954579 (#716 base): 7,183,000 ms.
- #721 pre-#716 run 38555443695: 6,306,000 ms; other pre-#716 full gates
  6.09M–6.91M.
- The growth is real per-job work from #716's per-member Identity derives:
  keepers-b 331k→480k, runtime-keep 843k→1060k, suite shards up.
- Option 4 (exclude runner queue-wait) is MOOT: `total` is already the sum of
  job clocks, not the makespan — the same #721 run's makespan is 1,803,000 ms
  vs the 7,746,000 ms sum, so the figure is work on shared runners, and
  `ci_wall.py` documents that the sum excludes the queue.

## Chosen shape

Raised `ci-wall wall total` 7,000,000 → **9,000,000** (worst measured full
gate + ~16%), with a dated note in `tools/speed.budget` naming #716 and run
38563160661. There is NO relative form for wall: unlike the phase family
(`ratio 1.25 + 250ms`) and the warm family (`WARM_RATIO 2.0`) it carries no
ratio, and a wall sum has no count to subtract from — so the sanctioned form
is the human edit whose diff is the review. `--accept` walks it down as the
cost falls.

## PR

- **#767** — https://github.com/avra-lang/avra/pull/767
  - head `ci-wall-ceiling` @ `b5d9e2ad` (off origin/main `54e0d556`),
    base `main`, ready, **NOT armed by this lane**.
  - one file, one row: `tools/speed.budget`.
  - checks: `make keepers-static` exit 0 (54 s); `make ci-invariants` exit 0 +
    self-test (10 invariants); `make wall-ratchet WALL=<#721 metrics>` PASS
    `wall total: 7746000ms vs ceiling 9000000ms`; `speed_ratchet --self-test`
    34 fixtures held. PR's own run 38568677206: **completed success** —
    `prepare`, `keepers-static` and the required `test` all green; heavy jobs
    skipped (CI-only diff).
  - **MERGED** as `53a25530` on main. The lane did NOT arm it: the repo's
    green-PR watcher (`app/github-actions`) enabled auto-merge 6 s after the
    branch was pushed and the green run landed it. Main now carries
    `ci-wall wall total 9000000`. Flagging because the brief said the lead
    arms it; the lane kept its hands off `--auto`/`--admin`.

## Blockers

- None for this change — it is on main (`53a25530`). The root cause (main's
  #716 derives adding ~1.4M ms of gate work) is a perf regression a later
  landing should address; this PR ratcheted the present so full-gate PRs on
  #716's base can land.
- #721 and other full-gate PRs on the old base need an update-branch/rebase to
  pick up the new ceiling from main.
