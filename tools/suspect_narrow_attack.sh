#!/bin/sh
# A LITERAL EDIT SUSPECTS ONLY WHAT IT CAN MOVE. The suspect set names the rows that read an input
# which moved; the rows that read the edited file's MODULE only through its names were all suspect
# whatever the edit, so a literal inside a fn body suspected every file seeing the module (7741
# rows over 533 files for one cli edit). The set is narrowed to the rows that read the file itself
# — and the narrowing must not lie where a literal IS interface-relevant: a const's value (public,
# and private read by a sibling), a template body spliced into another package, a default seat
# copied into callers. Each edit is built warm and held to the output its change implies, under
# AVRA_DB_VERIFY=filesaid, whose `suspect-missed` line is the oracle for a row judged moved that
# the set did not name. A fn-body literal is held to a counted ceiling. It CLEARS the store, as
# the attacks beside it do. NARROW_CEILING (rows) gates the fn-body edit's count once a narrowing lands;
# without it the count is reported.
set -u
cd "$(dirname "$0")/.."
R=build/suspect-narrow; fails=0; steps=0
find "$R" .avra-cache -type f -delete 2>/dev/null
mkdir -p $R/app/src/m $R/app/src/n $R/prov/src
cat > $R/prov/avra.toml <<'TOML'
[package]
name = "@rt/prov"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "../../../packages/std-meta" }
TOML
cat > $R/app/avra.toml <<'TOML'
[package]
name = "sn-app"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "../../../packages/std-meta" }
"@rt/prov" = { path = "../prov" }
TOML
put() { # put <file> <content>
    printf '%s\n' "$2" > "$1"
}
A=$R/app/src/m/a.av
base() {
    put $R/prov/src/counted.av 'use @std.meta.{Fn, Directive, wrapped}

export fn counted(f: Fn) -> List<Directive> {
    [Directive { twin: "", name: f.name, at: f.at, wraps: true, source: quote { fn ${f.name}(n: int) -> int { ${wrapped(f)}(n) + 1 } } }]
}'
    put $A "export const K: int = $1
const P: int = $2
export fn base() -> int { $3 }
export fn withd(x: int, y: int = $4) -> int { x + y }
export fn pv() -> int { P }"
    put $R/app/src/m/b.av 'export fn sib() -> int { P + 1 }'
    put $R/app/src/n/c.av 'use @rt.prov.counted.{counted}
use m.{K, base, withd, sib}

export fn all() -> string { "${K} ${base()} ${withd(1)} ${sib()}" }

@counted
export fn tw(n: int) -> int { n * 2 }'
    put $R/app/src/main.av 'use n.{all, tw}

println("${all()} ${tw(5)}")'
}
want_of() { # <K> <P> <base> <y> <plus>
    echo "$1 $3 $((1 + $4)) $(($2 + 1)) $((10 + $5))"
}
B() { # B <label> <wanted output> [<max suspects>]
    steps=$((steps + 1))
    AVRA_DB_VERIFY=filesaid AVRA_QTRACE=1 ./avra build $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails + 1)); echo "FAIL  $1: status $st: $(grep -v '^Q' $R/err | tail -n 6 | cut -c1-200 | tr '\n' ' ')"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails + 1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
    missed=$(grep -c '^Q	suspect-missed' $R/err)
    [ "$missed" = 0 ] || { fails=$((fails + 1)); echo "FAIL  $1: $missed row(s) judged moved that the suspect set did not name: $(grep '^Q	suspect-missed' $R/err | head -n 2 | cut -c1-200 | tr '\n' ' ')"; }
    rows=$(grep '^Q	suspects' $R/err | tail -n 1 | cut -f4 | cut -d' ' -f1)
    echo "$1: suspects ${rows:-0} row(s)"
    if [ -n "${3:-}" ] && [ "${rows:-0}" -gt "$3" ]; then fails=$((fails + 1)); echo "FAIL  $1: $rows suspect rows, over $3"; fi
}
base 5 7 100 3
B "cold" "$(want_of 5 7 100 3 1)"
base 5 7 100 3; B "nothing changed" "$(want_of 5 7 100 3 1)" 0
base 6 7 100 3; B "a const's literal, read in another module" "$(want_of 6 7 100 3 1)"
base 5 9 100 3; B "a private const, read by a sibling file" "$(want_of 5 9 100 3 1)"
base 5 7 100 4; B "a default seat's literal, copied into callers" "$(want_of 5 7 100 4 1)"
base 5 7 100 3; B "restored" "$(want_of 5 7 100 3 1)"
sed -i.bak 's/+ 1 }/+ 2 }/' $R/prov/src/counted.av; find $R -name '*.bak' -delete
B "a template body spliced into another package" "$(want_of 5 7 100 3 2)"
base 5 7 100 3; B "restored again" "$(want_of 5 7 100 3 1)"
base 5 7 250 3; B "a fn body's literal" "$(want_of 5 7 250 3 1)" ${NARROW_CEILING:-}
echo "suspect-narrow-attack: $steps edit(s) built warm, $fails failed"
[ "$fails" -eq 0 ]
