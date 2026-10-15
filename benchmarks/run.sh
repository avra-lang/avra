#!/bin/sh
# THE BENCHMARK SUITE'S ONE DOOR. A run prints one JSON row per
# (benchmark, language); `--record` stores it and accepts a baseline;
# `--report` projects the report; `--gate` refuses past a margin.
#
#   sh benchmarks/run.sh                       every registered language
#   sh benchmarks/run.sh --lang c,rust,go      the named languages
#   sh benchmarks/run.sh --bench tasks/drain   the named benchmarks
#   sh benchmarks/run.sh --record              store + accept a baseline
#   sh benchmarks/run.sh --report              regenerate report/
#   sh benchmarks/run.sh --gate                the C floor against the baseline
#   sh benchmarks/run.sh --gate --require      a machine with no row refuses
#   sh benchmarks/run.sh --list                benchmarks and languages
#   sh benchmarks/run.sh --self-test           the gate, the contract, the report
#
# The runner builds and runs each language's twin on the toolchains the
# machine has and SKIPS the rest with the reason (never silently). The
# gate's floor is C alone, so the regression seam needs no compiler and no
# other toolchain.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
exec python3 "$here/lib/harness.py" "$@"
