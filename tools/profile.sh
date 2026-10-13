#!/bin/sh
# A FUNCTION-LEVEL PROFILE OF A COMMAND, on a Sprite: the command runs under
# callgrind. The output is the total Ir on one line, the self top 40, and the
# inclusive top 40; the outputs are capped (tools/capped.sh), and the command's
# own status is the script's.
#
#   sh tools/profile.sh <cmd> [args...]          # the command's own process
#   sh tools/profile.sh --child <cmd> [args...]  # the largest forked worker instead
#   sh tools/profile.sh --self-test
#
# The compiler forks a worker per core. The parent is profiled by default: each
# worker under callgrind takes far longer than the work. `--child` follows the
# forks and reads the largest worker. Give the compiler itself (build/avra), not
# the `./avra` shell. The profiles and the top list are written to build/profile/.
set -eu

here=$(cd "$(dirname "$0")" && pwd)

if [ "${1:-}" = --self-test ]; then
    fails=0
    out=$(/bin/sh "$0" 2>&1) && st=0 || st=$?
    [ "$st" = 2 ] || { fails=$((fails + 1)); echo "FAIL  no command: wanted exit 2, got $st"; }
    printf '%s\n' "$out" | grep -qF "usage: sh tools/profile.sh" || { fails=$((fails + 1)); echo "FAIL  no command: the usage is not named"; }
    out=$(PATH=/nonexistent /bin/sh "$0" true 2>&1) && st=0 || st=$?
    [ "$st" = 1 ] || { fails=$((fails + 1)); echo "FAIL  no valgrind: wanted exit 1, got $st"; }
    printf '%s\n' "$out" | grep -qF "valgrind is not installed here" || { fails=$((fails + 1)); echo "FAIL  no valgrind: the refusal is not named"; }
    if [ "$fails" = 0 ]; then echo "profile: self-test clean — 4 case(s)"; exit 0; fi
    echo "profile: self-test FAILED — $fails case(s)"
    exit 1
fi

[ "$#" -ge 1 ] || { echo "usage: sh tools/profile.sh [--child] <cmd> [args...]" >&2; exit 2; }
command -v valgrind >/dev/null 2>&1 || { echo "profile: REFUSED — valgrind is not installed here (a Sprite carries it: .github/ci/packages-dev.txt)" >&2; exit 1; }

child=
if [ "${1:-}" = --child ]; then child=1; shift; fi
[ "$#" -ge 1 ] || { echo "usage: sh tools/profile.sh [--child] <cmd> [args...]" >&2; exit 2; }

cd "$here/.."
mkdir -p build/profile
status=0
if [ -n "$child" ]; then
    # Every fork is profiled. The parent has the lowest pid, so a worker is the largest of the rest.
    sh tools/capped.sh build/profile/run.log 200000 \
        valgrind --tool=callgrind --trace-children=yes --callgrind-out-file=build/profile/callgrind.out.%p "$@" || status=$?
    parent=$(ls build/profile/callgrind.out.* 2>/dev/null | sort -t. -k3 -n | head -n 1)
    profile=$(ls -S build/profile/callgrind.out.* 2>/dev/null | grep -v -F "$parent" | head -n 1 || :)
    [ -n "$profile" ] || { echo "profile: no forked worker was profiled — see build/profile/run.log" >&2; exit "$status"; }
else
    profile=build/profile/callgrind.out
    sh tools/capped.sh build/profile/run.log 200000 \
        valgrind --tool=callgrind --callgrind-out-file="$profile" "$@" || status=$?
fi

python3 - "$profile" <<'PY' > build/profile/top.txt
import re, subprocess, sys
profile = sys.argv[1]

def annotate(inclusive):
    return subprocess.run(["callgrind_annotate", "--inclusive=" + inclusive, profile],
                          capture_output=True, text=True).stdout.splitlines()

def rows(lines, n):
    out = []
    for line in lines:
        if re.match(r"^\s*[0-9][0-9,]* \(", line) and "PROGRAM TOTALS" not in line:
            out.append(line.rstrip())
        if len(out) == n:
            break
    return out

total = next((re.match(r"^\s*([0-9][0-9,]*) ", l).group(1)
              for l in annotate("no") if "PROGRAM TOTALS" in l), "?")
print("total Ir: %s  (%s)" % (total, profile))
print("== self (exclusive) top 40")
print("\n".join(rows(annotate("no"), 40)))
print("== inclusive top 40")
print("\n".join(rows(annotate("yes"), 40)))
PY
cat build/profile/top.txt
echo "profile: $* — exit $status; profiles and top.txt in build/profile/"
exit "$status"
