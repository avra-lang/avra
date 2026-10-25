#!/bin/sh
# tool-witness: --self-test
# A BOUNDED STEP NAMES ITS CAUSE. The command runs under `timeout` (and a
# kill ten seconds after), answers its own status, and on failure says which
# of three it was: past its bound (124), killed (137: a memory cap or the
# bound's kill), or a failure with its exit code. Under GitHub Actions the
# words are an `::error::` annotation.
#
#   sh tools/bounded.sh <seconds> <command> [args...]
#   sh tools/bounded.sh --self-test

said() {
    rc=$1 secs=$2; shift 2
    case $rc in
        124) why="ran past its $secs s bound" ;;
        137) why="was killed (exit 137: a memory cap or the bound's kill; see the peak line)" ;;
        *) why="failed (exit $rc)" ;;
    esac
    echo "${GITHUB_ACTIONS:+::error::}\`$*\` $why"
}

bounded() {
    secs=$1; shift
    timeout -k 10 "$secs" "$@"
    rc=$?
    [ "$rc" = 0 ] || said "$rc" "$secs" "$@"
    return "$rc"
}

self_test() {
    fails=0
    bad() { fails=$((fails + 1)); echo "bounded: FAIL — $1"; }
    out=$(bounded 5 true) || bad "a passing command failed"
    [ -z "$out" ] || bad "a passing command spoke: $out"
    out=$(bounded 5 sh -c 'exit 3'); rc=$?
    [ "$rc" = 3 ] || bad "a failure answered $rc, not its own 3"
    case "$out" in *"failed (exit 3)"*) ;; *) bad "a failure said: $out" ;; esac
    out=$(bounded 1 sleep 5); rc=$?
    [ "$rc" = 124 ] || bad "a command past its bound answered $rc, not 124"
    case "$out" in *"ran past its 1 s bound"*) ;; *) bad "a command past its bound said: $out" ;; esac
    out=$(GITHUB_ACTIONS=true bounded 5 false)
    case "$out" in "::error::"*) ;; *) bad "under Actions the words are no annotation: $out" ;; esac
    [ "$fails" = 0 ] || exit 1
    echo "bounded: self-test passed — 4 fixtures (silent pass, own status, the bound, the annotation)"
}

case "$1" in
    --self-test) self_test ;;
    ''|*[!0-9]*) echo "usage: sh tools/bounded.sh <seconds> <command> [args...] | --self-test" >&2; exit 2 ;;
    *) bounded "$@" ;;
esac
