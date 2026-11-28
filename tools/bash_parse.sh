#!/bin/sh
# EVERY SHELL SCRIPT PARSES UNDER BASH: a Mac's /bin/sh is bash 3.2, where dash and bash 5 can accept
# what it refuses, and a script that does not parse exits 2 before its first line runs. `bash -n` over
# every tracked `.sh` file and every tracked script whose first line names sh or bash, with /bin/bash
# where it stands (macOS's 3.2), else the bash on the PATH; each refusal is named with bash's own words.
#
#   sh tools/bash_parse.sh              the tree
#   sh tools/bash_parse.sh --self-test  a known-bad script is refused and a clean one passes
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
bash_=/bin/bash
[ -x "$bash_" ] || bash_=$(command -v bash) || { echo "bash_parse: no bash here" >&2; exit 1; }

# the scripts git tracks: `.sh` files, and any other whose first line is a sh or bash interpreter
scripts() {
    git -C "$root" ls-files | while IFS= read -r f; do
        [ -f "$root/$f" ] || continue
        case $f in
            (*.sh) echo "$f" ;;
            (*) head -n 1 "$root/$f" 2>/dev/null | grep -qE '^#!.*[/ ](sh|bash)( |$)' && echo "$f" ;;
        esac
    done
}

# THE SHAPE BASH 3.2 REFUSES AND BASH 5 ACCEPTS: a `case` inside a command substitution, on one line, whose
# pattern has no leading `(` — 3.2 ends the substitution at the pattern's `)`. Spelled `(pattern)`, every
# bash reads it, so the line is refused under any bash; a `case` opened on a line of its own is not seen.
unparenthesised() {
    grep -nE '\$\([^)]*(^|[ ;])case [^;]* in +[^ (]' "$1"
}

# parsed <file…>: each file through `bash -n`, and the 3.2 shape above; the refusals on stderr, the count
# of files refused answered
parsed() {
    bad=0
    for f in "$@"; do
        if ! out=$("$bash_" -n "$f" 2>&1); then
            bad=$((bad + 1))
            printf 'bash_parse: %s does not parse:\n%s\n' "$f" "$out" >&2
        elif lines=$(unparenthesised "$f"); then
            bad=$((bad + 1))
            printf 'bash_parse: %s has a `case` inside `$( )` with no `(` before its pattern, which bash 3.2 does not parse — write `(pattern)`:\n%s\n' "$f" "$lines" >&2
        fi
    done
    echo "$bad"
}

if [ "${1:-}" = --self-test ]; then
    scratch_dir d
    # an apostrophe in `${v:+…}` inside double quotes opens a quote to bash and to no other sh
    printf '#!/bin/sh\necho "x${v:+ (the hour'"'"'s limit)}"\ncase $1 in (a) echo a ;; esac\n' > "$d/bad.sh"
    printf '#!/bin/sh\necho "x${v:+ (the hourly limit)}"\ncase $1 in (a) echo a ;; esac\n' > "$d/good.sh"
    # bash 3.2 ends the substitution at the unparenthesised pattern's `)`; bash 5 does not, so the shape is read
    printf '#!/bin/sh\nr=%sfor p in a b; do case " $p " in *" a "*) ;; *) printf x ;; esac; done)\n' '$(' > "$d/case32.sh"
    printf '#!/bin/sh\nr=$(for p in a b; do case " $p " in (*" a "*) ;; (*) printf x ;; esac; done)\n' > "$d/case.sh"
    b=$(parsed "$d/bad.sh" 2>/dev/null)
    g=$(parsed "$d/good.sh" 2>/dev/null)
    c=$(parsed "$d/case32.sh" 2>/dev/null)
    p=$(parsed "$d/case.sh" 2>/dev/null)
    find "$d" -delete
    [ "$b" = 1 ] || { echo "bash_parse: self-test — the apostrophe inside \${v:+…} was not refused" >&2; exit 1; }
    [ "$g" = 0 ] || { echo "bash_parse: self-test — a clean script was refused" >&2; exit 1; }
    [ "$c" = 1 ] || { echo "bash_parse: self-test — a case inside \$( ) with no \`(\` before its pattern was not refused" >&2; exit 1; }
    [ "$p" = 0 ] || { echo "bash_parse: self-test — a case inside \$( ) spelled \`(pattern)\` was refused" >&2; exit 1; }
    echo "bash_parse: self-test passed — 2 refusals and 2 accepts"
    exit 0
fi

list=$(scripts)
n=$(printf '%s\n' "$list" | grep -c .)
cd "$root" || exit 1
# shellcheck disable=SC2086
bad=$(parsed $list)
v=$("$bash_" -c 'echo $BASH_VERSION')
if [ "$bad" != 0 ]; then
    echo "bash_parse: REFUSED — $bad of $n script(s) do not parse under $bash_ $v" >&2
    exit 1
fi
echo "bash_parse: clean — $n script(s) parse under $bash_ $v"
