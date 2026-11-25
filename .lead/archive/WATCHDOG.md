# THE WATCHDOG — how the pipeline is kept moving without an agent

## What it is
A **deterministic (no-LLM) watchdog** that keeps the merge queue flowing: it comments the exact
`job — line` on a failing PR, re-runs failed jobs once, enqueues green PRs, and dequeues+re-enqueues
a stuck queue entry. Two halves, deliberately:

| half | where it runs | what drives it |
|---|---|---|
| **`tools/pr_watcher.py`** (in the repo, on `main`) | GitHub Actions (`.github/workflows/pr-watcher.yml`) | `workflow_run` + a `schedule` cron |
| **`.lead/scripts/watchdog.sh`** | THIS machine, `launchd` | the machine's clock, every 120 s |

## THE LAW (learned the hard way, 2026-10-10)
**A WATCHDOG MUST NOT BE POWERED BY THE ACTIVITY IT WATCHES.**
The GitHub workflow fires on `workflow_run` — i.e. when *another workflow completes*. A stalled
pipeline completes nothing, so the watcher slept through a **5-hour** stall. Its `schedule` fallback
is GitHub's cron, which is **best-effort**: it fired **once in 4.5 hours** instead of every 5 minutes.
The local `launchd` driver exists precisely to supply a clock that is not GitHub's.

## The local driver, exactly
- **`~/Library/LaunchAgents/lang.avra.watchdog.plist`** — `StartInterval: 120`, `RunAtLoad: true`.
- **`.lead/scripts/watchdog.sh`** — sets a real `PATH` (launchd's is minimal; without it `gh` is not
  found and the script exits SILENTLY — the first trap hit), then **always runs `origin/main`'s copy**
  of `tools/pr_watcher.py` (`git show origin/main:tools/pr_watcher.py` into `~/.avra-pr-watcher/`), so
  a stale worktree can never drive a stale watchdog (the second trap hit).
- **State**: `~/.avra-pr-watcher/state.json` — what it has already commented/re-run. Shared across
  every harness, so Claude and pi never post duplicate comments.
- **Log**: `~/.avra-pr-watcher/watchdog.log` — one line per run plus every action. `tail` is the
  liveness check; there is no other way to know it is alive.

## WHAT IT DOES NOT DO (the holes, stated so they are not mistaken for coverage)
- **It does not message any agent session or any human.** Nothing pushes into Claude, pi, or a chat.
  A harness learns what happened only by reading GitHub or the log.
- **It only runs while this Mac is awake.** `StartInterval` does not fire while asleep; a closed laptop
  for a weekend is a dead watchdog, silently.
- **It is one machine.** A second driver on a machine that does not sleep (a Sprite timer) is wanted.

## Install / check / remove
    cp .lead/scripts/watchdog.sh ~/   # or run it in place
    launchctl load  ~/Library/LaunchAgents/lang.avra.watchdog.plist
    launchctl list | grep avra                       # is it loaded?
    tail -20 ~/.avra-pr-watcher/watchdog.log         # is it RUNNING (not just loaded)?
    launchctl unload ~/Library/LaunchAgents/lang.avra.watchdog.plist   # stop it

## What is still owed
1. **A notification channel** so any harness can pick up "the queue stalled, here is what I did"
   without a human noticing (a file to poll, or a GitHub issue it opens/labels).
2. **A second driver off this machine** (Sprt timer), so the Mac is not a single point of failure.
3. **Make the GitHub-side cron real** or delete it and say the local driver is the driver — a
   scheduled workflow that never fires is the same defect (a signal on one path only) this file exists to end.
