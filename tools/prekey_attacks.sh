#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/.."
# The shim's own lines are no program's output: its `watch:` reports, and the
# warning a shell with no terminal prints when the watchdog asks for job control.
unwatched() { grep -v -e '^watch:' -e 'job control turned off'; }

R=build/cache-attacks; fails=0; steps=0; holds=0
S() { # S <label> <app>
    steps=$((steps+1))
    out=$(./avra build --time $R/$2 2>$R/$2.err); st=$?; bin=$(printf '%s\n' "$out" | tail -1)
    held=$(grep -oE "held [0-9]+/[0-9]+" $R/$2.err | tail -1)
    case "$held" in "held 0/"*|"") ;; *) holds=$((holds+1)) ;; esac
    if [ ! -x "$bin" ]; then fails=$((fails+1)); echo "FAIL  $1 [$2] did not build (status $st): $(printf '%s\n' "$out" | cat - $R/$2.err | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')"; return; fi
    # A REFUSED HOLD IS A FINDING HERE: the build is right and the hold was wrong.
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep 'the hold was refused' $R/$2.err | head -1 | cut -c1-200)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | unwatched)
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
# THE PREKEY, ATTACKED. A held file's object key is remembered under the inputs it was
# keyed by (its dependency list), so an edit that moves none of them is answered from
# the store and not re-keyed. Each edit is held to the evaluator, and the trace names
# what the check did: a `prekey hit` for a file the edit cannot reach, a `prekey miss`
# for a file it moved.
pk=$R/pk
rm -rf $pk && mkdir -p $pk/dep/src $pk/lib/src $pk/a/src
NL=$(printf '\nx'); NL=${NL%x}
cat > $pk/dep/avra.toml <<'TOML'
[package]
name = "@rt/pkd"
version = "0.1.0"

[lib]
name = "rt-pkd"
path = "src/d.av"
TOML
cat > $pk/dep/src/d.av <<'AV'
export type Tag = { n: int }
export fn base() -> int { 1 }
AV
cat > $pk/lib/avra.toml <<'TOML'
[package]
name = "@rt/pk"
version = "0.1.0"

[dependencies]
"@rt/pkd" = { path = "../dep" }

[lib]
name = "rt-pk"
path = "src/lib.av"
TOML
cat > $pk/lib/src/lib.av <<'AV'
use @rt.pkd.{base, Tag}
use @std.meta.{embed}
export fn one() -> int { leaf() + base() }
export fn tag() -> Tag { Tag { n: 1 } }
export const banner: string = embed("banner.txt")
AV
printf 'fn leaf() -> int { 1 }\n' > $pk/lib/src/leaf.av
printf 'first\n' > $pk/lib/src/banner.txt
cat > $pk/a/avra.toml <<'TOML'
[package]
name = "rt-pk-a"
version = "0.1.0"

[dependencies]
"@rt/pk" = { path = "../lib" }
TOML
cat > $pk/a/src/main.av <<'AV'
use @rt.pk.{one, tag, banner}
println("a ${one()} ${tag().n} ${banner}")
AV

# pk_expect <label> <hit|miss> <path suffix> <app>: the trace names the file's pre-key
pk_expect() {
    if grep -F "$(printf 'Q\tprekey\t%s\t' "$2")" "$R/$4.err" | grep -q "$3\$"; then [ -n "${VERBOSE:-}" ] && echo "ok    $1: prekey $2 $3"; else fails=$((fails+1)); echo "FAIL  $1: no prekey $2 for $3"; fi
}
export AVRA_QTRACE=1
S "pk cold" pk/a
S "pk warm, nothing edited" pk/a
ed $pk/lib/src/leaf.av "{ 1 }" "{ 100 }";                                   S "pk private body edit in lib" pk/a
pk_expect "private body edit: main is reached by no moved input" hit pk/a/src/main.av pk/a
printf 'export fn extra() -> int { 2 }\n' > $pk/lib/src/extra.av;          S "pk new file in a seen module" pk/a
pk_expect "new file in a seen module: main re-keyed" miss pk/a/src/main.av pk/a
ed $pk/lib/src/banner.txt "first" "second";                                 S "pk embed text edit" pk/a
pk_expect "embed text edit: the file that embeds it re-keyed" miss pk/lib/src/lib.av pk/a
ed $pk/lib/src/lib.av "use @std.meta.{embed}" "use @std.meta.{embed}${NL}use @std.text.{codepoints}"; S "pk import added in a reached file" pk/a
pk_expect "import added in a reached file: that file re-keyed" miss pk/lib/src/lib.av pk/a
ed $pk/dep/src/d.av "{ n: int }" "{ n: string }"
ed $pk/lib/src/lib.av 'Tag { n: 1 }' 'Tag { n: "1" }';                      S "pk dependency's type changes shape" pk/a
pk_expect "dependency interface change: main re-keyed" miss pk/a/src/main.av pk/a
unset AVRA_QTRACE
echo "prekey: $steps builds through one store, $holds under a hold, $fails failed"
[ "$fails" -eq 0 ]
