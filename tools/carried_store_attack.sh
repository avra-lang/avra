#!/bin/sh
# AN ANSWER IS THE SAME BYTES IN ANY TREE. A package whose generator writes the place a field was
# written in into the code it generates is built cold in one directory; then, its own store and the
# machine's carried with it, in another, deeper one; then cold there. A stored answer holding the
# first directory's path would build a second binary naming it: the three binaries are the same
# bytes, and each says the place as the package spells it.
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${CARRIED_ATTACK_AVRA:-$(pwd)/avra}
R=build/carried-store-attack
find "$R" -delete 2>/dev/null; mkdir -p "$R/one" "$R/two/deeper"
unset AVRA_CACHE_DIR
app="$R/one/app"
mkdir -p "$app/src/gen"
printf '[package]\nname = "carried-store-attack"\nversion = "0.1.0"\n' > "$app/avra.toml"
cat > "$app/src/gen/gen.av" <<'AV'
use @std.meta.{Declared, Type, beside, literal}

/// `@placed`: the type says where its first field was written.
export fn placed(t: Type) -> Declared {
    let file = t.fields.first()?.at?.file ?? "nowhere"
    Declared { made: [beside(t, quote { impl ${t} { static fn written_in() -> string { ${literal(file)} } } })] }
}
AV
printf 'use gen.{placed}\n\n@placed\ntype P = { x: int }\n\nprintln(P.written_in())\n' > "$app/src/main.av"

# `built <dir> <machine cache> <name>`: the package at <dir> built over <machine cache>, its binary kept
built() {
    AVRA_PROGRAM_MODE=release AVRA_CACHE_DIR="$2" "$A" build "$1" > "$R/$3.out" 2> "$R/$3.err" ||
        { fail "$3 did not build: $(head -3 "$R/$3.err" | tr '\n' ' ')"; return; }
    said=$("$1/src/main" 2>&1)
    # the place as the package spells it — its own path first — and naming no directory of either tree
    case $said in
        carried-store-attack/src/main.av*) ;;
        *) fail "$3 says its place as '$said'" ;;
    esac
    case $said in *"$PWD"*) fail "$3 says its place under this tree: '$said'" ;; esac
    cp "$1/src/main" "$R/$3.bin"
    command -v codesign > /dev/null && codesign --remove-signature "$R/$3.bin"
    :
}

built "$app" "$R/machine-one" first
# the package and both stores carried to another directory, deeper
cp -R "$app" "$R/two/deeper/app"
cp -R "$R/machine-one" "$R/machine-carried"
find "$R/two/deeper/app/src" -maxdepth 1 -name main -delete
built "$R/two/deeper/app" "$R/machine-carried" carried
find "$R/two/deeper/app" -name .avra-cache -type d -prune -exec find {} -delete \;
find "$R/two/deeper/app/src" -maxdepth 1 -name main -delete
built "$R/two/deeper/app" "$R/machine-cold" cold
if [ "$fails" -eq 0 ]; then
    for b in first carried; do
        n=$(cmp -l "$R/$b.bin" "$R/cold.bin" 2>&1 | wc -l | tr -d ' ')
        [ "$n" = 0 ] || fail "the $b binary and the cold one differ in $n byte(s): $(strings -n 8 "$R/$b.bin" | grep -F "$PWD/$R" | head -3 | tr '\n' ' ')"
    done
fi
verdict "carried-store-attack" "one package built in two trees, its stores carried, against cold"
