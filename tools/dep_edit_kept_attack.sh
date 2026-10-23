#!/bin/sh
# A DEPENDENCY FILE THAT CHANGED UNDER AN EXISTING STORE IS PARSED ONCE, THEN KEPT. A store warm
# for tree A meets a tree whose dependency package has one file changed: the next check parses that
# file (its text moved), and every check after answers it from the store — an unchanged check
# parses nothing, and an edit elsewhere never parses it again. A file the store forgot to keep
# would be parsed by every later edit. Parses are counted from AVRA_QTRACE's `Q parse` lines.
# It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/dep-edit-kept; fails=0
find "$R" .avra-cache -type f -delete 2>/dev/null
mkdir -p $R/app/src $R/dep/src
cat > $R/dep/avra.toml <<'TOML'
[package]
name = "@rt/dep"
version = "0.1.0"
TOML
cat > $R/app/avra.toml <<'TOML'
[package]
name = "dk-app"
version = "0.1.0"

[dependencies]
"@rt/dep" = { path = "../dep" }
TOML
put() { printf '%s\n' "$2" > "$1"; }
dep() { # dep <n>: the dependency file the attack changes
    put $R/dep/src/dep.av "export fn weight() -> int { $1 }"
    put $R/dep/src/other.av "export fn side() -> int { 7 }"
    put $R/dep/src/lib.av "use @rt.dep.dep.{weight}
use @rt.dep.other.{side}

export fn total() -> int { weight() + side() }"
}
app() { # app <n>: the app file the later edit changes
    put $R/app/src/main.av "use @rt.dep.lib.{total}

println(\"\${total()} $1\")"
}
parsed() { # parsed <label> <wanted: some|none|not <file>>
    AVRA_QTRACE=1 ./avra check $R/app > $R/out 2> $R/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails + 1)); echo "FAIL  $1: status $st: $(grep -v '^Q' $R/err | tail -n 4 | cut -c1-200 | tr '\n' ' ')"; return; fi
    files=$(grep '^Q	parse	' $R/err | cut -f3 | sort -u)
    n=$(printf '%s' "$files" | grep -c .)
    echo "$1: $n file(s) parsed"
    case "$2" in
        none) [ "$n" = 0 ] || { fails=$((fails + 1)); echo "FAIL  $1: parsed $n file(s), wanted none: $(printf '%s' "$files" | tr '\n' ' ')"; } ;;
        dep) printf '%s\n' "$files" | grep -q 'dep/src/dep.av$' || { fails=$((fails + 1)); echo "FAIL  $1: the changed dependency file was not parsed"; } ;;
        notdep) ! printf '%s\n' "$files" | grep -q 'dep/src/' || { fails=$((fails + 1)); echo "FAIL  $1: a dependency file was parsed again: $(printf '%s' "$files" | grep 'dep/src/' | tr '\n' ' ')"; } ;;
    esac
}
dep 1; app 1
parsed "cold" any
parsed "nothing changed" none
dep 2
parsed "a dependency file changed" dep
parsed "the same tree again" none
app 2
parsed "an edit elsewhere" notdep
app 3
parsed "another edit elsewhere" notdep
if [ "$fails" -eq 0 ]; then echo "dep_edit_kept: clean"; else echo "dep_edit_kept: $fails failure(s)"; exit 1; fi
