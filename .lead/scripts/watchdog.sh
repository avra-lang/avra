#!/bin/sh
# THE WATCHDOG — driven by the MACHINE's clock (launchd), never GitHub's best-effort cron.
# Law: a watchdog must not be powered by the activity it watches.
# It always runs origin/main's copy, so a stale worktree can never run a stale watchdog.
PATH="/opt/homebrew/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH
R=/Users/tristan/projects/tristanMatthias/avra
W="$HOME/.avra-pr-watcher"
mkdir -p "$W"
cd "$R" || exit 0
git fetch -q origin main 2>/dev/null || exit 0
git show origin/main:tools/pr_watcher.py > "$W/pr_watcher.py" 2>/dev/null || exit 0
[ -s "$W/pr_watcher.py" ] || exit 0
export GH_REPO=avra-lang/avra
export AVRA_WATCHER_STATE="$W/state.json"
echo "[$(date -u +%H:%M:%S)] watchdog run" >> "$W/watchdog.log"
"/opt/homebrew/bin/python3" "$W/pr_watcher.py" >> "$W/watchdog.log" 2>&1
