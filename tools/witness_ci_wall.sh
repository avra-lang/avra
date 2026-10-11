#!/bin/sh
# THE WALL-CLOCK MEASUREMENT, proved against a local fake of the jobs API:
# a skipped job is not measured, the running job takes `now`, and total is
# the run's start to its last job.
set -eu
exec python3 "$(dirname "$0")/ci_wall.py" --self-test
