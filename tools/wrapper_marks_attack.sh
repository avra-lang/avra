#!/bin/sh
# A WRAPPER IS REMADE WHEN THE BODY IT CALLS CHANGES WHETHER IT CONSUMES A SEAT. A fn taken as a value
# is called through its wrapper (`b$w`), which retains each seat the body consumes before the call: the
# retains are the memory pass's, made from the body's consumed seats as the bodies naming it see them.
# A body that went from borrowing its seat to consuming it, with its signature unmoved, left its
# wrapper's chunk standing on a warm build, so no retain ran and the seat was released twice. Held: after
# such an edit the chunk holding `b$w` is owed, and the program prints what its source says; edited back,
# the objects the first build made stand again.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=wrapper-marks-attack
. tools/lib/steps.sh
R=build/wrapper-marks
avra=${WRAPPER_ATTACK_AVRA:-./avra}
find "$R" -delete 2>/dev/null
mkdir -p $R/src
own_store $R
printf '[package]\nname = "wrapped"\nversion = "0.1.0"\n' > $R/avra.toml
main() { # main <b's body>
    printf 'type R = { s: string }\ntype H = { r: R, n: int }\n\nfn b(r: R) -> int %s\n\nfn kept(h: H) -> int { h.n + h.r.s.length }\n\nfn apply(f: fn(R) -> int, r: R) -> int { f(r) }\n\nlet r = R { s: "hello" }\nprintln("${apply(b, r)} ${r.s}")\n' "$1" > $R/src/main.av
}
# built <step> <want> [wrapper]: built (traced), the program prints <want>, and with "wrapper" the
# chunk holding `b$w` is owed
built() {
    AVRA_QTRACE=1 $avra build $R > $R/out 2> $R/err || { fail "$1: the build failed: $(grep -v '^Q' $R/err | head -3 | tr '\n' ' ')"; return; }
    got=$($R/src/main 2>&1)
    [ "$got" = "$2" ] || { fail "$1: printed '$got', the source says '$2'"; return; }
    if [ "${3:-}" = wrapper ] && ! grep '^Q	owed	' $R/err | grep -q 'main\.av\.b\$w'; then
        fail "$1: the chunk holding b\$w was not remade: owed $(grep '^Q	owed	' $R/err | tr '\t' ' ' | tr '\n' ';')"
        return
    fi
    say "$1: printed '$got'${3:+, the wrapper's chunk remade}"
}
main '{ r.s.length }'
built "cold, b borrows its seat" "5 hello" wrapper
main '{ kept(H { r: r, n: 1 }) }'
built "b consumes its seat, warm" "6 hello" wrapper
# back to the first body: every key is one a build made, so its objects stand again and none is owed
main '{ r.s.length }'
built "b borrows it again, warm" "5 hello"
verdict
