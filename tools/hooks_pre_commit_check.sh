#!/bin/sh
# THE PRE-COMMIT HOOK REFUSES WITHOUT A COMPILER: staged `.av` and no `build/avra` is exit 1
# naming how to get one; no staged `.av` passes with no compiler. A compiler's stamp: unstamped
# refuses, one older than the merge-base refuses (naming the way out), one at the merge-base or
# built from its own edits is accepted and reported.
#
#   sh tools/hooks_pre_commit_check.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
hook=$here/hooks/pre-commit
fail() { echo "hooks_pre_commit_check: $1"; exit 1; }

# hook_in <dir>: the hook's status in the repo, its stderr in $err.
hook_in() {
    err=$(cd "$1" && sh "$hook" 2>&1 >/dev/null)
    status=$?
}

staged() { # staged <name> <text>: a fresh repo with one file staged
    d=$(mktemp -d)
    (cd "$d" && git init -q && printf '%s' "$2" > "$1" && git add "$1")
    echo "$d"
}

d=$(staged a.av 'let x = 1
')
hook_in "$d"
{ [ "$status" = 1 ] && printf '%s' "$err" | grep -q refused && printf '%s' "$err" | grep -q tools/work; } ||
    fail "staged .av with no compiler gave $status: $err"
d=$(staged notes.txt 'x
')
hook_in "$d"
[ "$status" = 0 ] || fail "no .av staged must pass with no compiler, gave $status: $err"

stamped_repo() { # stamped_repo <stamp>: a repo with a compiler stamped as asked and a.av staged
    d=$(mktemp -d)
    git="git -c user.name=t -c user.email=t@t"
    (
        cd "$d" || exit 1
        $git init -q -b main
        mkdir tools build
        cp "$here/compiler_paths.sh" tools/compiler_paths.sh
        echo one > Makefile
        $git add -A
        $git commit -q -m one
        git rev-parse HEAD > /tmp/hpc_first.$$
        echo two > Makefile
        $git commit -q -am two
        git rev-parse HEAD > /tmp/hpc_second.$$
        $git update-ref refs/remotes/origin/main HEAD
        printf '#!/bin/sh\nexit 0\n' > build/avra
        chmod 755 build/avra
        case "$1" in
            none) ;;
            old) printf 'hash000 %s\n' "$(cat /tmp/hpc_first.$$)" > build/.avra-built-from ;;
            current) printf 'hash000 %s\n' "$(cat /tmp/hpc_second.$$)" > build/.avra-built-from ;;
            edited) printf 'hash000 edited\n' > build/.avra-built-from ;;
        esac
        printf 'let x = 1\n' > a.av
        $git add a.av
    )
    echo "$d"
}

hook_in "$(stamped_repo none)"
{ [ "$status" = 1 ] && printf '%s' "$err" | grep -q "says nothing about what it was built from"; } ||
    fail "an unstamped compiler gave $status: $err"
hook_in "$(stamped_repo old)"
{ [ "$status" = 1 ] && printf '%s' "$err" | grep -q "1 compiler commit(s) older" && printf '%s' "$err" | grep -q "tools/work compiler"; } ||
    fail "a compiler older than the merge-base gave $status: $err"
for kind in current edited; do
    hook_in "$(stamped_repo $kind)"
    { [ "$status" = 0 ] && printf '%s' "$err" | grep -q "formatting with"; } ||
        fail "a $kind compiler gave $status: $err"
done
echo "hooks_pre_commit_check: refusal and accept witnessed — 6 fixtures"
