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
#   sh benchmarks/run.sh --g1                  each Avra row beside Go's, with the target verdict
#   sh benchmarks/run.sh --gate                the C floor and each Avra row's target against Go
#   sh benchmarks/run.sh --g1 --gate --require the same, a machine with no row refusing
#   sh benchmarks/run.sh --list                benchmarks and languages
#   sh benchmarks/run.sh --self-test           the way gate, the contract, the report
#
# The runner builds and runs each language's twin on the toolchains the
# machine has and SKIPS the rest with the reason (never silently). A
# `--gate` keeps the C floor AND judges each Avra row against Go's row
# from the SAME run (nothing is ever compared across machines); where the
# machine has no Go, the RECORDED Go row for this machine is the fallback.
# A row Go never measures is a SKIP, a row Go measures elsewhere but not
# here is a word, and `--require` turns that word into a refusal. The
# target factors are data in bench.toml's [gate.target].
set -eu
here=$(cd "$(dirname "$0")" && pwd)
exec python3 "$here/lib/harness.py" "$@"
