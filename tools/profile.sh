#!/bin/sh
# A FUNCTION-LEVEL PROFILE OF A COMMAND, on a Sprite: the command runs under
# callgrind, and callgrind_annotate prints the inclusive top 40. Both outputs are
# capped (tools/capped.sh), and the command's own status is the script's.
#
#   sh tools/profile.sh <cmd> [args...]
#   sh tools/profile.sh --self-test
#
# The command runs as one process: children are not followed, because the
# compiler forks a worker per core and each one under callgrind takes far longer
# than the work. Give the compiler itself (build/avra), not the `./avra` shell.
# The profile and the top list are written to build/profile/.
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

[ "$#" -ge 1 ] || { echo "usage: sh tools/profile.sh <cmd> [args...]" >&2; exit 2; }
command -v valgrind >/dev/null 2>&1 || { echo "profile: REFUSED — valgrind is not installed here (a Sprite carries it: .github/ci/packages-dev.txt)" >&2; exit 1; }

cd "$here/.."
mkdir -p build/profile

status=0
profile=build/profile/callgrind.out
sh tools/capped.sh build/profile/run.log 200000 \
    valgrind --tool=callgrind --callgrind-out-file="$profile" "$@" || status=$?
sh tools/capped.sh build/profile/top.txt 60000 \
    sh -c "callgrind_annotate --inclusive=yes '$profile' 2>/dev/null | head -n 40" || :
cat build/profile/top.txt
echo "profile: $* — exit $status; callgrind.out and top.txt in build/profile/"
exit "$status"
