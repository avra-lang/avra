#!/bin/sh
# AN EDIT OWES THE CHUNKS ITS MOVED BODIES FALL IN, AND NO OTHERS. A program's bodies fall in chunks by
# their symbols' hashes, each chunk an object kept under the keys of what it holds, so one edit of each
# kind, made to a built program, owes exactly the chunks pinned here — counted from the build's
# `Q objects` line and named by the symbols each owed chunk is home to — and the binary prints what the
# source says. A count that grows is the cache missing where it held; one that falls is a key that
# stopped seeing what codegen reads.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=chunk-owed-attack
. tools/lib/steps.sh
R=build/chunk-owed
avra=${OWED_ATTACK_AVRA:-./avra}
find "$R" -delete 2>/dev/null
mkdir -p $R/src
own_store $R
printf '[package]\nname = "owed"\nversion = "0.1.0"\n' > $R/avra.toml
lib() { # lib <P> <callee> <shown> [extra]
    printf 'export type P = %s\n\nexport fn make(n: int) -> P { P { a: n } }\n\nexport fn callee%s\n\nexport fn shown%s\n\nexport fn other(x: int) -> int { x * 2 }\n%s' \
        "$1" "$2" "$3" "${4:-}" > $R/src/lib.av
}
main() { # main [tail]
    printf 'use lib.{P, make, callee, shown, other}\n\nfn get(p: P) -> int { p.a }\n\nfn twice(x: int) -> int { callee(x) + callee(x) }\n\nfn said(x: int) -> string { "${shown(x)}" }\n\nfn plain(x: int) -> int { other(x) - 1 }\n\nprintln("${twice(1)} ${get(make(5))} ${said(7)} ${plain(3)}%s")\n%s' \
        "${1:-}" "${2:-}" > $R/src/main.av
}
plain_lib() { lib '{ a: int }' '(x: int) -> int { x + 1 }' '(x: int) -> int { x }'; }
# owed <label> <want printed> <want owed> <want symbols>: the program built from empty stores, then
# edited as the caller just wrote it and built again, owes <want owed> chunks home to <want symbols>
owed() {
    find $R/.avra-cache $R/src/main -delete 2>/dev/null
    plain_lib; main
    $avra build $R > $R/out 2> $R/err || { fail "$1: the unedited build failed: $(grep -v '^Q' $R/err | head -3 | tr '\n' ' ')"; return; }
    cp $R/edit.lib $R/src/lib.av; cp $R/edit.main $R/src/main.av
    AVRA_QTRACE=1 $avra build $R > $R/out 2> $R/err || { fail "$1: the edited build failed: $(grep -v '^Q' $R/err | head -3 | tr '\n' ' ')"; return; }
    got=$($R/src/main 2>&1)
    [ "$got" = "$2" ] || { fail "$1: printed '$got', the source says '$2'"; return; }
    n=$(grep '^Q	objects	' $R/err | cut -f3 | head -1)
    syms=$(grep '^Q	owed	' $R/err | cut -f4 | tr ',' '\n' | grep . | sed 's|^owed/src/||' | sort | tr '\n' ' ')
    [ "${n:-0}" = "$3" ] || { fail "$1: owed ${n:-0} chunks ($syms), wanted $3"; return; }
    [ "$syms" = "$4" ] || { fail "$1: the owed chunks are home to '$syms', wanted '$4'"; return; }
    say "$1: owed $3 chunks, home to '$syms', printed '$got'"
}
# kept: the sources as the caller just wrote them, kept as the edit `owed` makes
kept() { cp $R/src/lib.av $R/edit.lib; cp $R/src/main.av $R/edit.main; }
main
lib '{ a: int }' '(x: int) -> int { x + 2 }' '(x: int) -> int { x }'; kept
owed "a callee's body edited" "6 5 7 5" 1 "lib.av.callee "
lib '{ a: int }' '(x: int) -> int { x + 1 }' '(x: int) -> string { "s${x}" }'; kept
owed "a callee's answer retyped, its caller unedited" "4 5 s7 5" 2 "lib.av.shown main.av.said "
lib '{ a: int }' '(x: int, by: int = 1) -> int { x + by }' '(x: int) -> int { x }'; kept
owed "a callee given a defaulted seat, its caller unedited" "4 5 7 5" 3 'lib.av.callee lib.av.callee.by$default main.av.twice '
lib '{ b: int = 9, a: int }' '(x: int) -> int { x + 1 }' '(x: int) -> int { x }'; kept
owed "a record laid out anew, its readers unedited" "4 5 7 5" 5 'lib.av.P.b$default lib.av.make main.av.get '
plain_lib
lib '{ a: int }' '(x: int) -> int { x + 1 }' '(x: int) -> int { x }' 'export fn extra() -> int { 42 }
'
main ' ${extra()}' 'use lib.{extra}
'
kept
main
owed "a fn added at a file's end, called from the entry" "4 5 7 5 42" 3 "lib.av.extra "
verdict
