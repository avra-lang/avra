#!/bin/sh
cd /Users/tristan/projects/tristanMatthias/avra-graph-v2
export REPLAY_FROM=graph/acceptance/results/score-e2e-20261022T102354.json
run() { python3 graph/acceptance/score.py --mode e2e --extractor "python3 graph/extract/replay.py" --planner "python3 graph/planner/plan.py" --resolver "python3 graph/extract/resolve.py"; }
AVRA_NO_RETRIEVAL=1 run > graph/retrieval/data/e2e-before.log 2>&1
run > graph/retrieval/data/e2e-after.log 2>&1
