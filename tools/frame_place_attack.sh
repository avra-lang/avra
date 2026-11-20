#!/bin/sh
# A FRAME SAYS WHERE ITS BODY STANDS IN ITS FILE, HOWEVER THE ITEMS ABOVE IT MOVED, AND MOVING THEM
# REMAKES NO CHUNK OF THE BODY'S. A body's frame counts its place from its item's start, and its file's
# frames module places it once, at emit, so an edit above the body remakes that module and the edited
# body's chunk. Held to each step: the program prints where a `within`'s unwind says `nap` stands, which
# must be the place and the line of `nap`'s body in the source as it now reads, and an edit above `nap`
# — one that lengthens a line, one that adds lines — owes no chunk `nap` is home to.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=frame-place-attack
. tools/lib/steps.sh
R=build/frame-place
avra=${FRAME_ATTACK_AVRA:-./avra}
find "$R" -delete 2>/dev/null
mkdir -p $R/src
own_store $R
printf '[package]\nname = "placed"\nversion = "0.1.0"\n' > $R/avra.toml
main() { # main <pad's body>
    printf 'use @std.time.{ms, secs, sleep, TimedOut}\n\nfn pad() -> int %s\n\nfn nap() -> int {\n    sleep(secs(60))\n    1\n}\n\nfn told(r: Result<int, TimedOut>) -> string {\n    match r {\n        .Ok(v) -> "ok ${v}",\n        .Err(t) -> [placed(f.label, f.loc?.lo, f.loc?.hi) for f in t.at if f.label == "nap"].join(" "),\n    }\n}\n\nfn placed(label: string?, lo: int?, hi: int?) -> string { "${label ?? "?"}:${lo ?? -1}-${hi ?? -1}" }\n\nprintln("${pad()} ${told(within ms(5) { nap() })}")\n' "$1" > $R/src/main.av
}
# where <file>: `nap`'s body as the source reads it — its first and past-last byte and its line
where() {
    python3 -I -c '
import sys
t = open(sys.argv[1]).read()
head = "fn nap() -> int "
lo = t.index(head) + len(head)
hi = t.index("}\n", lo) + 1
print("nap:%d-%d line %d" % (lo, hi, t.count("\n", 0, lo) + 1))
' "$1"
}
# placed <label> <want pad>: built (traced), the frame says where `nap` stands, and no owed chunk is
# home to it unless <owes nap> is "nap"
placed() {
    AVRA_QTRACE=1 $avra build $R > $R/out 2> $R/err || { fail "$1: the build failed: $(grep -v '^Q' $R/err | head -3 | tr '\n' ' ')"; return; }
    got=$($R/src/main 2>&1)
    want=$(where $R/src/main.av)
    place=${want% line *}
    [ "$got" = "$2 $place" ] || { fail "$1: printed '$got', the source puts $want"; return; }
    if [ "${3:-}" != nap ] && grep '^Q	owed	' $R/err | grep -q 'main\.av\.nap'; then
        fail "$1: owed the chunk nap is home to: $(grep '^Q	owed	' $R/err | tr '\t' ' ' | tr '\n' ';')"
        return
    fi
    say "$1: the frame says $place, where the source puts $want"
}
main '{ 1 }'
placed "cold" 1 nap
main '{ 1 + 10 }'
placed "pad lengthened on its line" 11
main '{
    let one = 1
    one + 20
}'
placed "pad given two more lines" 21
main '{ 1 }'
placed "pad as it was" 1
verdict
