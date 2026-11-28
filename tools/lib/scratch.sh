# SCRATCH THAT NEVER OUTLIVES ITS RUN, sourced by every tool that needs a temporary path or a cleanup
# (`. "$(dirname "$0")/lib/scratch.sh"`). It owns the run's exit: one EXIT trap runs every cleanup a tool
# handed it, then removes every directory it made; HUP, INT and TERM become an exit with that signal's
# own status, because sh runs no EXIT trap for a run a signal ends. A tool never spells `mktemp` or an
# EXIT, HUP, INT or TERM trap itself: `wisp scratch_law` refuses one anywhere else.
#
#   scratch_dir <var>       a fresh directory in <var>, gone when the run ends
#   scratch_under <dir>     a fresh directory inside one scratch_dir made, on stdout — for a subshell,
#                           whose own variables die with it
#   scratch_also <command>  run when the run ends, before the directories go, in the order handed
#   scratch_signals         the signal forwards again, after a stretch a tool's own licensed trap held
#
# `scratch_dir` and `scratch_also` speak for the shell they run in, so neither is called in a `$(…)`:
# a subshell holds the caller's list without its trap, and what it made there would never go.

if [ -z "${scratch_loaded:-}" ]; then
    scratch_loaded=1
    scratch_dirs=
    scratch_hooks=
    scratch_armed=
fi

# The exit trap and the signal forwards, armed once.
scratch_arm() {
    [ -z "$scratch_armed" ] || return 0
    scratch_armed=1
    trap scratch_cleanup EXIT
    scratch_signals
}

scratch_signals() {
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

# Every cleanup handed, then every directory made. A cleanup that fails stops none after it.
scratch_cleanup() {
    eval "$scratch_hooks" || :
    for scratch_d in $scratch_dirs; do
        if [ -d "$scratch_d" ]; then find "$scratch_d" -delete 2>/dev/null || :; fi
    done
}

scratch_dir() {
    scratch_arm
    scratch_made=$(mktemp -d "${TMPDIR:-/tmp}/avra-scratch.XXXXXX") || { echo "scratch: no temporary directory could be made" >&2; exit 1; }
    scratch_dirs="$scratch_dirs $scratch_made"
    eval "$1=\$scratch_made"
}

scratch_under() {
    [ -d "$1" ] || { echo "scratch: $1 is no directory to make one under" >&2; return 1; }
    mktemp -d "$1/s.XXXXXX"
}

scratch_also() {
    scratch_arm
    scratch_hooks="$scratch_hooks
$1"
}
