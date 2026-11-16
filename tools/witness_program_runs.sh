#!/bin/sh
# `tapes --ran` RUNS EVERY PROGRAM TEST THE SUITES RUN, AND OUTLIVES WHAT THEY DO. Over the packages
# under tools/program-runs/, each copied cold:
#   nested — a program test laid out as a package of its own (avra.toml, src/main.av and its
#     `.expected`) is found and run, and passes;
#   forks — a program that forks processes which return out of it rather than leave: the run ends
#     within its bound, says its tally once (no forked process ran the harness on), its evaluator
#     leg answers, and no process of it is left;
#   guarded — a program test's native run is handed AVRA_RC_GUARD when the harness was: it prints
#     the guard it sees, and passes only when that is `1`;
#   rc — the guard's control: a box made at run time released twice fails its native leg;
#   static_write — a row driven past its open writes into the binary's own data: each native leg
#     ends with status 2, the runtime's refusal;
#   traps — a test whose making traps the compiler (AVRA_RAN_TRAP, the hook that traps the making
#     of the test it names) fails, named with the trap's words, and the run goes on to the next,
#     which passes.
#   sh tools/witness_program_runs.sh [compiler]   (default build/avra-try)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_runs: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
cp -R "$root/tools/program-runs/." "$tmp/"
find "$tmp" -name .avra-cache -prune -exec find {} -delete \;
failed=0

# the run of `tapes --ran` over the package `$1`, bounded, its words at $tmp/$1.log; its exit
ran() { name=$1; shift; env "$@" timeout 300 "$avra" tapes "$tmp/$name" --ran >"$tmp/$name.log" 2>&1; }
refused() { echo "witness_program_runs: $1" >&2; sed 's/^/  /' "$tmp/$2.log" | head -20 >&2; failed=$((failed + 1)); }

ran nested AVRA_PROGRAM=1
[ $? = 0 ] && grep -q "^ran: 1 program tests found" "$tmp/nested.log" ||
    refused "nested: a program test laid out as a package was not found and passed" nested

ran forks AVRA_PROGRAM=1
code=$?
[ "$code" != 124 ] || refused "forks: the run did not end within 300 s" forks
[ "$(grep -c '^ran:' "$tmp/forks.log")" = 1 ] || refused "forks: the tally was said other than once: a forked process ran the harness on" forks
grep -q "(eval)" "$tmp/forks.log" && refused "forks: the evaluator's leg did not answer what its parent prints" forks
pgrep -f "$tmp/forks" >/dev/null && refused "forks: a process of the run is left" forks

ran guarded AVRA_RC_GUARD=1
[ $? = 0 ] || refused "guarded: the native run was not handed AVRA_RC_GUARD" guarded

ran rc AVRA_RC_GUARD=1
grep -q "(native)" "$tmp/rc.log" || refused "rc: a box released twice passed its native leg under the guard" rc

ran static_write AVRA_PROGRAM=1
[ "$(grep -c '(native): .* native != expected' "$tmp/static_write.log")" = 2 ] && [ "$(grep -c '^(it ended with status 2)' "$tmp/static_write.log")" = 2 ] ||
    refused "static_write: a write into the binary's own data was not refused by the runtime" static_write

ran traps AVRA_RAN_TRAP=a_traps/a_traps.av
code=$?
[ "$code" = 1 ] || refused "traps: the run exited $code, not 1" traps
grep -q "a_traps.av (making): the compiler trapped making it: the making of .* trapped, as AVRA_RAN_TRAP asks" "$tmp/traps.log" || refused "traps: the trapping test was not named failing" traps
grep -q "^ran: 2 program tests found.* 1 made on the program layer, 1 printing their ..expected. in the evaluator, 1 natively, 1 runs failing" "$tmp/traps.log" ||
    refused "traps: the run did not go on to the test after it" traps

[ "$failed" = 0 ] && echo "witness_program_runs: nested, forks, guarded, rc, static_write and traps hold"
[ "$failed" = 0 ]
