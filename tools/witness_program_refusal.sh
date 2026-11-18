#!/bin/sh
# THE PROGRAM LAYER REFUSES WHAT THE OLD PATH REFUSES, IN ITS WORDS, AND BUILDS WHAT IT BUILDS.
# Each case under tools/program-refusals/ is a package of its own:
#   refuses.expected — the source must be refused: the old path's `check` and the program
#     layer's `build` each exit 1, and what each says, its warnings aside, is exactly this text;
#   prints.expected — the source must not be refused: the old path's `check` exits 0, the
#     program layer builds it, and what the product prints is exactly this text;
#   target — a case for another target, its triple: each path BUILDS it for that target, the build's
#     refusal is its words, and a printing case's module runs under node (`tools/run_wasm.mjs`); on a
#     machine with no toolchain for the target, both paths refuse in the toolchain's same words, exit 2,
#     and the case is said untooled, neither held nor failed;
#   warns.expected — beside either: each path's warnings, their first lines in the order said, are
#     exactly this text;
#   differs.why — the paths are known to differ on it, for the reason written there: it is said
#     and not failed while it differs, and FAILS once it holds, until the file is taken away.
# A case that uses a form only the program layer builds (`avra tapes <case> --new-only`) is never
# asked of the old path, which never learned the form: the program layer alone is held to the
# expectation, and the count of such cases is said.
# Every case is copied to a directory of its own with no store and a machine store of its own, so
# each judgement is cold; a path into that copy is said as `<case>`. Prints each failing case with what differs, then the
# counts; exits 1 on any failure. With PIN=1, a case holding neither expectation is first given
# the old path's: its `check`'s words where it refuses, else what its `run` prints.
#   sh tools/witness_program_refusal.sh [compiler] [case…]   (default build/avra-try, every case)
#   sh tools/witness_program_refusal.sh --known   (each case known to differ, and why; runs nothing)
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cases_dir="$root/tools/program-refusals"
# the node a wasm case's module runs under: NODE, else /opt/node24's, else the PATH's
node=${NODE:-$( [ -x /opt/node24/bin/node ] && echo /opt/node24/bin/node || echo node )}

# every case, by name: each directory under the cases
cases() { for d in "$cases_dir"/*/; do basename "$d"; done; }

if [ "${1:-}" = --known ]; then
    n=0
    for name in $(cases); do
        [ -e "$cases_dir/$name/differs.why" ] || continue
        echo "$name: $(head -1 "$cases_dir/$name/differs.why")"
        n=$((n + 1))
    done
    echo "witness_program_refusal: $n of $(cases | wc -l | tr -d ' ') cases known to differ"
    exit 0
fi
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_refusal: no compiler at $avra" >&2; exit 1; }
[ $# -gt 0 ] && shift
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT

# what one run of the case `$1` said, its warnings aside, its copy's path said as `<case>`: a blank
# line is said only before what is kept, so a warning goes with the line that parts it from the rest
said() {
    sed "s#$tmp/$1#<case>#g" "$tmp/$1.$2" |
        awk '/^warning\[/ { warned = 1; next }
            warned { if ($0 == "") warned = 0; next }
            $0 == "" { gap = gap + 1; next }
            { while (gap > 0) { print ""; gap = gap - 1 } print }'
}

# whether the case `$1`, which uses a form only the program layer builds, holds on the program layer
# alone: 3 where it does, 1 with what differs said on stderr where it doesn't. With PIN=1 a case
# holding neither expectation is first given the program layer's.
judged_alone() {
    name=$1
    from="$cases_dir/$name"
    (cd "$tmp/$name" && AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 "$avra" build . >"$tmp/$name.new" 2>&1)
    new=$?
    said "$name" new >"$tmp/$name.new.said"
    if [ "${PIN:-}" = 1 ] && [ ! -e "$from/refuses.expected" ] && [ ! -e "$from/prints.expected" ]; then
        if [ "$new" = 1 ]; then cp "$tmp/$name.new.said" "$from/refuses.expected"; else "$tmp/$name/src/main" >"$from/prints.expected" 2>/dev/null; fi
    fi
    if [ -e "$from/refuses.expected" ]; then
        [ "$new" = 1 ] || { echo "$name: the program layer's build exited $new, not 1" >&2; cat "$tmp/$name.new.said" >&2; return 1; }
        cmp -s "$tmp/$name.new.said" "$from/refuses.expected" || {
            echo "$name: the program layer's words differ from refuses.expected" >&2
            diff "$from/refuses.expected" "$tmp/$name.new.said" >&2
            return 1
        }
        return 3
    fi
    [ "$new" = 0 ] || { echo "$name: the program layer refused it ($new)" >&2; cat "$tmp/$name.new.said" >&2; return 1; }
    "$tmp/$name/src/main" >"$tmp/$name.ran" 2>&1 || { echo "$name: its product failed" >&2; cat "$tmp/$name.ran" >&2; return 1; }
    cmp -s "$tmp/$name.ran" "$from/prints.expected" || {
        echo "$name: its product printed otherwise" >&2
        diff "$from/prints.expected" "$tmp/$name.ran" >&2
        return 1
    }
    return 3
}

# whether the case `$1` holds; what differs said on stderr where it doesn't
judged() {
    name=$1
    from="$cases_dir/$name"
    cp -R "$from" "$tmp/$name"
    find "$tmp/$name" -name .avra-cache -prune -exec find {} -delete \;
    mkdir -p "$tmp/$name.machine"
    export AVRA_CACHE_DIR="$tmp/$name.machine"
    target=$(cat "$from/target" 2>/dev/null || true)
    forms=$(AVRA_PROGRAM=1 "$avra" tapes "$tmp/$name" --new-only 2>/dev/null)
    [ -z "$forms" ] || { judged_alone "$name"; return $?; }
    if [ -n "$target" ]; then
        (cd "$tmp/$name" && AVRA_PROGRAM=0 "$avra" build --target "$target" . >"$tmp/$name.old" 2>&1)
    else
        (cd "$tmp/$name" && AVRA_PROGRAM=0 "$avra" check . >"$tmp/$name.old" 2>&1)
    fi
    old=$?
    (cd "$tmp/$name" && AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 "$avra" build ${target:+--target "$target"} . >"$tmp/$name.new" 2>&1)
    new=$?
    said "$name" old >"$tmp/$name.old.said"
    said "$name" new >"$tmp/$name.new.said"
    if [ -n "$target" ] && [ "$old" = 2 ] && [ "$new" = 2 ] && cmp -s "$tmp/$name.old.said" "$tmp/$name.new.said"; then
        return 2
    fi
    if [ "${PIN:-}" = 1 ] && [ ! -e "$from/refuses.expected" ] && [ ! -e "$from/prints.expected" ]; then
        if [ "$old" = 1 ]; then
            cp "$tmp/$name.old.said" "$from/refuses.expected"
        else
            if [ -n "$target" ]; then
                (cd "$tmp/$name" && AVRA_PROGRAM=0 "$avra" build --target "$target" . >/dev/null 2>&1 && "$node" --no-warnings "$root/tools/run_wasm.mjs" src/main.wasm >"$from/prints.expected" 2>/dev/null)
            else
                (cd "$tmp/$name" && AVRA_PROGRAM=0 "$avra" run . >"$from/prints.expected" 2>/dev/null)
            fi
        fi
    fi
    if [ -e "$from/warns.expected" ]; then
        for path in old new; do
            grep '^warning\[' "$tmp/$name.$path" | cmp -s - "$from/warns.expected" || {
                echo "$name: the $path path's warnings differ from warns.expected" >&2
                grep '^warning\[' "$tmp/$name.$path" | diff "$from/warns.expected" - >&2
                return 1
            }
        done
    fi
    if [ -e "$from/refuses.expected" ]; then
        [ "$old" = 1 ] || { echo "$name: the old path's check exited $old, not 1" >&2; cat "$tmp/$name.old.said" >&2; return 1; }
        [ "$new" = 1 ] || { echo "$name: the program layer's build exited $new, not 1" >&2; cat "$tmp/$name.new.said" >&2; return 1; }
        cmp -s "$tmp/$name.old.said" "$from/refuses.expected" || {
            echo "$name: the old path's words differ from refuses.expected" >&2
            diff "$from/refuses.expected" "$tmp/$name.old.said" >&2
            return 1
        }
        cmp -s "$tmp/$name.new.said" "$from/refuses.expected" || {
            echo "$name: the program layer's words differ from refuses.expected" >&2
            diff "$from/refuses.expected" "$tmp/$name.new.said" >&2
            return 1
        }
        return 0
    fi
    [ "$old" = 0 ] || { echo "$name: the old path's check refused it ($old)" >&2; cat "$tmp/$name.old.said" >&2; return 1; }
    [ "$new" = 0 ] || { echo "$name: the program layer refused it ($new)" >&2; cat "$tmp/$name.new.said" >&2; return 1; }
    if [ -n "$target" ]; then
        (cd "$tmp/$name" && "$node" --no-warnings "$root/tools/run_wasm.mjs" src/main.wasm) >"$tmp/$name.ran" 2>&1 || { echo "$name: its module failed" >&2; cat "$tmp/$name.ran" >&2; return 1; }
    else
        "$tmp/$name/src/main" >"$tmp/$name.ran" 2>&1 || { echo "$name: its product failed" >&2; cat "$tmp/$name.ran" >&2; return 1; }
    fi
    cmp -s "$tmp/$name.ran" "$from/prints.expected" || {
        echo "$name: its product printed otherwise" >&2
        diff "$from/prints.expected" "$tmp/$name.ran" >&2
        return 1
    }
}

if [ $# -gt 0 ]; then names="$*"; else names=$(cases); fi
held=0
failed=0
known=0
untooled=0
alone=0
for name in $names; do
    why="$cases_dir/$name/differs.why"
    judged "$name" 2>"$tmp/$name.why"
    judgement=$?
    if [ "$judgement" = 3 ]; then
        held=$((held + 1))
        alone=$((alone + 1))
    elif [ "$judgement" = 2 ]; then
        echo "$name: untooled — no toolchain here for $(cat "$cases_dir/$name/target"); both paths refuse alike"
        untooled=$((untooled + 1))
    elif [ "$judgement" = 0 ]; then
        if [ -e "$why" ]; then
            echo "$name: holds now, yet differs.why says the paths differ — take the file away"
            failed=$((failed + 1))
        else
            held=$((held + 1))
        fi
    elif [ -e "$why" ]; then
        echo "$name: known to differ — $(head -1 "$why")"
        known=$((known + 1))
    else
        cat "$tmp/$name.why"
        failed=$((failed + 1))
    fi
done
echo "witness_program_refusal: $held of $((held + failed + known)) cases hold, $known known to differ, $failed failing$([ "$untooled" = 0 ] || echo ", $untooled untooled"); $alone skipped by the old path (a form only the program layer builds), held on the program layer alone"
[ "$failed" = 0 ]
