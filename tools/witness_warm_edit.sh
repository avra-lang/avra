#!/bin/sh
# THE WARM-EDIT KEEPER'S SKIP LAW, proved: a run that cannot judge FAILS
# with a named reason, and only a hand-set WARM_EDIT_SKIP — the workflow's
# `warm_skip` input — may stand it down, loudly. No compiler is needed: the
# cold-store refusal stands before one is asked for, so the proof runs
# anywhere, and the ratchet is handed a skip stream the way the bench
# writes one.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
unset WARM_EDIT_SKIP
mkdir -p "$tmp/tools"
cp "$root/tools/warm_edit_bench.sh" "$root/tools/host_key.sh" "$tmp/tools/"

# 1. no compiler, no opt-out: FAIL, with the reason named.
if SPEED_LOCAL=1 sh "$tmp/tools/warm_edit_bench.sh" >"$tmp/fail.stdout" 2>"$tmp/fail.err"; then
    echo "witness_warm_edit: the bench PASSED with no compiler — a skip is not a pass" >&2
    exit 1
fi
grep -q "no compiler" "$tmp/fail.err" \
    || { echo "witness_warm_edit: the refusal does not name the compiler" >&2; cat "$tmp/fail.err" >&2; exit 1; }
grep -q "FAILURE" "$tmp/fail.err" \
    || { echo "witness_warm_edit: the refusal does not say FAILURE" >&2; cat "$tmp/fail.err" >&2; exit 1; }

# 1a. a store the tree holds is set aside, never read by the measurement, and put back as it stood;
# the store the measurement ran over is the compiler's own.
mkdir -p "$tmp/s/tools" "$tmp/s/build" "$tmp/s/packages/cli/src/commands" "$tmp/s/.avra-cache"
cp "$root/tools/warm_edit_bench.sh" "$root/tools/host_key.sh" "$tmp/s/tools/"
printf 'x · memo y\n' > "$tmp/s/packages/cli/src/commands/shared.av"
: > "$tmp/s/build/libavra_runtime.a"
echo theirs > "$tmp/s/.avra-cache/sentinel"
cat > "$tmp/s/build/avra" <<'RECORDS'
#!/bin/sh
[ ! -e .avra-cache/sentinel ] || echo SAW >> "$AVRA_WITNESS_LOG"
mkdir -p .avra-cache
echo own > .avra-cache/own
RECORDS
chmod +x "$tmp/s/build/avra"
AVRA_WITNESS_LOG="$tmp/saw" SPEED_LOCAL=1 SPEED_ROUNDS=1 AVRA_SPEED_BIN="$tmp/s/build/avra" sh "$tmp/s/tools/warm_edit_bench.sh" >/dev/null 2>"$tmp/s.err" || :
[ ! -e "$tmp/saw" ] \
    || { echo "witness_warm_edit: the measurement ran over a store it did not write" >&2; cat "$tmp/s.err" >&2; exit 1; }
{ [ -e "$tmp/s/.avra-cache/sentinel" ] && [ ! -e "$tmp/s/.avra-cache/own" ]; } \
    || { echo "witness_warm_edit: the tree's own store was not put back as it stood" >&2; cat "$tmp/s.err" >&2; exit 1; }

# 1b. a measurement whose subshell dies is a NAMED refusal, never an unbound `$1`.
mkdir -p "$tmp/m/tools" "$tmp/m/build" "$tmp/m/packages/cli/src/commands" "$tmp/m/.avra-cache"
cp "$root/tools/warm_edit_bench.sh" "$root/tools/host_key.sh" "$tmp/m/tools/"
printf 'x · memo y\n' > "$tmp/m/packages/cli/src/commands/shared.av"
: > "$tmp/m/build/libavra_runtime.a"
cat > "$tmp/m/build/avra" <<'DIES'
#!/bin/sh
kill -KILL $PPID
DIES
chmod +x "$tmp/m/build/avra"
if SPEED_LOCAL=1 SPEED_ROUNDS=1 AVRA_SPEED_BIN="$tmp/m/build/avra" sh "$tmp/m/tools/warm_edit_bench.sh" >"$tmp/dead.stdout" 2>"$tmp/dead.err"; then
    echo "witness_warm_edit: the bench PASSED with a measurement that never answered" >&2
    exit 1
fi
grep -q "not measured" "$tmp/dead.err" \
    || { echo "witness_warm_edit: a dead measurement was not a named refusal" >&2; cat "$tmp/dead.err" >&2; exit 1; }
! grep -qE "unbound variable|parameter not set" "$tmp/dead.err" \
    || { echo "witness_warm_edit: a dead measurement is an unbound parameter" >&2; cat "$tmp/dead.err" >&2; exit 1; }

# 2. the hand-set opt-out: SKIP, loudly, status 0.
WARM_EDIT_SKIP=1 SPEED_LOCAL=1 sh "$tmp/tools/warm_edit_bench.sh" \
    >"$tmp/skip.stdout" 2>"$tmp/skip.err" \
    || { echo "witness_warm_edit: WARM_EDIT_SKIP did not stand the gate down" >&2; cat "$tmp/skip.err" >&2; exit 1; }
grep -q "SKIPPED BY REQUEST" "$tmp/skip.err" \
    || { echo "witness_warm_edit: the skip did not say so loudly" >&2; cat "$tmp/skip.err" >&2; exit 1; }

# 3. the ratchet refuses a skip stream it was handed, and the opt-out stands it.
printf 'host ci-warm\nskip warm-edit\n' > "$tmp/skip.metrics"
if python3 "$root/tools/speed_ratchet.py" --warm --raw "$tmp/skip.metrics" >"$tmp/ratchet.out" 2>&1; then
    echo "witness_warm_edit: the ratchet PASSED a skipped measurement" >&2
    cat "$tmp/ratchet.out" >&2
    exit 1
fi
grep -q "REFUSED" "$tmp/ratchet.out" \
    || { echo "witness_warm_edit: the ratchet did not name the skip" >&2; cat "$tmp/ratchet.out" >&2; exit 1; }
WARM_EDIT_SKIP=1 python3 "$root/tools/speed_ratchet.py" --warm --raw "$tmp/skip.metrics" \
    >"$tmp/ratchet-skip.out" 2>&1 \
    || { echo "witness_warm_edit: WARM_EDIT_SKIP did not stand the ratchet down" >&2; cat "$tmp/ratchet-skip.out" >&2; exit 1; }

# 4. the rules themselves, on fixtures.
python3 "$root/tools/speed_ratchet.py" --self-test >/dev/null
echo "witness_warm_edit: clean — a skip FAILS, and only WARM_EDIT_SKIP stands it down"
