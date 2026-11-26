#!/bin/sh
# tool-witness: run by the gate's refusal-* slice (tools/gate.sh), never twice
# THE PROGRAM LAYER REFUSES WHAT THE OLD PATH REFUSED, IN ITS WORDS, AND BUILDS WHAT IT BUILT. The old
# path's last word on each case is frozen in the case: it was asked once, at cbc437f4, before its
# deletion, and every expectation below is what it said then (a case it never judged holds the
# program layer's, for the reason its `layer-only` file gives). Each case under
# tools/program-refusals/ is a package of its own, built on the program layer:
#   refuses.expected — the source must be refused: the build exits 1, and what it says, its warnings
#     aside, is exactly this text;
#   prints.expected — the source must not be refused: the program layer builds it, and what the
#     product prints is exactly this text;
#   target — a case for another target, its triple: it is BUILT for that target, the build's
#     refusal is its words, and a printing case's module runs under node (`tools/run_wasm.mjs`); on a
#     machine with no toolchain for the target, the build refuses in the toolchain's words, exit 2,
#     and the case is said untooled, neither held nor failed;
#   warns.expected — beside either: the build's warnings, their first lines in the order said, are
#     exactly this text; an empty one says no warning is said;
#   differs.why — the program layer is known to differ from the expectation, for the reason written
#     there: it is said and not failed while it differs, and FAILS once it holds, until the file is
#     taken away;
#   layer-only — the old path's words were no law of the language's, for the reason written there:
#     the expectation is the program layer's.
# Every case is copied to a directory of its own with no store and a machine store of its own, so
# each judgement is cold; a path into that copy is said as `<case>`. Prints each failing case with
# what differs, then the counts; exits 1 on any failure. With PIN=1, a case holding neither
# expectation is first given the program layer's: its build's words where it refuses, else what its
# product prints.
#   sh tools/witness_program_refusal.sh [compiler] [case…]   (default build/avra-try, every case)
#   sh tools/witness_program_refusal.sh --known   (each case known to differ, and why; runs nothing)
#   sh tools/witness_program_refusal.sh --cases   (each case's name, one a line, as the gate deals them)
# A case is a directory holding its `avra.toml` (tools/lib/cases.sh); one that holds none is no case.
# Every case run, each such directory is named; one named on the command line is refused.
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cases_dir="$root/tools/program-refusals"
# the node a wasm case's module runs under: NODE, else /opt/node24's, else the PATH's
node=${NODE:-$( [ -x /opt/node24/bin/node ] && echo /opt/node24/bin/node || echo node )}

. "$root/tools/lib/cases.sh"
# every case, by name
cases() { cases_in "$cases_dir"; }

if [ "${1:-}" = --cases ]; then
    cases
    exit 0
fi

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

# whether the case `$1` holds on the program layer: 3 where it does, 1 with what differs said on
# stderr where it doesn't, and 2 where its `target` has no toolchain on this machine (the build
# refuses in the toolchain's words, exit 2). A case for a target is built through the same door,
# `build --target`, and its module runs under node (`tools/run_wasm.mjs`). With PIN=1 a case holding
# neither expectation is first given the program layer's.
judged_alone() {
    name=$1
    from="$cases_dir/$name"
    (cd "$tmp/$name" && AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 "$avra" build ${target:+--target "$target"} . >"$tmp/$name.new" 2>&1)
    new=$?
    said "$name" new >"$tmp/$name.new.said"
    if [ -n "$target" ] && [ "$new" = 2 ]; then return 2; fi
    if [ "${PIN:-}" = 1 ] && [ ! -e "$from/refuses.expected" ] && [ ! -e "$from/prints.expected" ]; then
        if [ "$new" = 1 ]; then
            cp "$tmp/$name.new.said" "$from/refuses.expected"
        elif [ -n "$target" ]; then
            (cd "$tmp/$name" && "$node" --no-warnings "$root/tools/run_wasm.mjs" src/main.wasm >"$from/prints.expected" 2>/dev/null)
        else
            "$tmp/$name/src/main" >"$from/prints.expected" 2>/dev/null
        fi
    fi
    if [ -e "$from/warns.expected" ]; then
        grep '^warning\[' "$tmp/$name.new" | cmp -s - "$from/warns.expected" || {
            echo "$name: the program layer's warnings differ from warns.expected" >&2
            grep '^warning\[' "$tmp/$name.new" | diff "$from/warns.expected" - >&2
            return 1
        }
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
    return 3
}

# whether the case `$1` holds on the program layer, against the expectation it holds: 3 where it
# does, 2 where its `target` has no toolchain here, else 1 with what differs said on stderr
judged() {
    name=$1
    from="$cases_dir/$name"
    cp -R "$from" "$tmp/$name"
    find "$tmp/$name" -name .avra-cache -prune -exec find {} -delete \;
    mkdir -p "$tmp/$name.machine"
    export AVRA_CACHE_DIR="$tmp/$name.machine"
    target=$(cat "$from/target" 2>/dev/null || true)
    judged_alone "$name"
}

held=0
failed=0
if [ $# -gt 0 ]; then
    names=""
    for name in "$@"; do
        if [ -f "$cases_dir/$name/avra.toml" ]; then
            names="$names $name"
        else
            echo "$name: no case — tools/program-refusals/$name holds no avra.toml"
            failed=$((failed + 1))
        fi
    done
else
    names=$(cases)
    leftovers_in "$cases_dir" | sed 's/^/witness_program_refusal: leftover /'
fi
known=0
untooled=0
for name in $names; do
    why="$cases_dir/$name/differs.why"
    judged "$name" 2>"$tmp/$name.why"
    judgement=$?
    # A CASE'S COPY AND ITS MACHINE STORE GO THE MOMENT IT IS JUDGED: a store is 120 MB to 1 GB, so
    # kept to the run's end they made a runner's disk grow with the count of cases
    find "$tmp/$name" "$tmp/$name.machine" -delete 2>/dev/null || :
    if [ "$judgement" = 3 ]; then
        if [ -e "$why" ]; then
            echo "$name: holds now, yet differs.why says it differs — take the file away"
            failed=$((failed + 1))
        else
            held=$((held + 1))
        fi
    elif [ "$judgement" = 2 ]; then
        echo "$name: untooled — no toolchain here for $(cat "$cases_dir/$name/target"); the build refuses in the toolchain's words"
        untooled=$((untooled + 1))
    elif [ -e "$why" ]; then
        echo "$name: known to differ — $(head -1 "$why")"
        known=$((known + 1))
    else
        cat "$tmp/$name.why"
        failed=$((failed + 1))
    fi
done
echo "witness_program_refusal: $held of $((held + failed + known)) cases hold, $known known to differ, $failed failing$([ "$untooled" = 0 ] || echo ", $untooled untooled")"
[ "$failed" = 0 ]
