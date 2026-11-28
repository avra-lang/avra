#!/bin/sh
# A DIRECTORY'S STORE ANSWERS THE PROGRAM IN IT AS A FRESH ONE DOES, whatever stood there before. Three
# programs are checked in turn in one directory, on one machine store of its own: a delegated trait over
# a collect enum keyed by a field nobody declares (refused), a relation, then the same delegated trait
# keyed right. The last check must answer as it does in a directory of its own: what the earlier
# programs left is kept under the same file, so the generator's kept record reads the file's generated
# items while they are being worked out — a question being answered vouches for no read of itself.
#   sh tools/witness_store_programs.sh [compiler]
set -u
. "$(dirname "$0")/lib/tree.sh"
[ $# -gt 0 ] && avra=$1
case $avra in /*) ;; *) avra=$PWD/$avra ;; esac
[ -x "$avra" ] || { echo "store-programs: no compiler at $avra"; exit 1; }
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-store-programs.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM
mkdir -p "$work/home"
# program <dir> <file>: <dir> holds a package whose program is <file>
program() {
    mkdir -p "$work/$1/src"
    printf '[package]\nname = "probe"\nversion = "0.1.0"\n\n[bin]\npath = "src/main.av"\n' > "$work/$1/avra.toml"
    cp "$work/$2" "$work/$1/src/main.av"
}
# checked <dir> <name>: the package in <dir> checked on the witness's own store, its words in <name>.out
checked() {
    (cd "$work/$1" && HOME="$work/home" AVRA_CACHE_DIR="$work/home/cache" AVRA_MACHINE_STORE_DIR="$work/store" \
        AVRA_PROGRAM_NET=0 "$avra" check .) > "$work/$2.out" 2>&1
    echo $? > "$work/$2.status"
}
cat > "$work/keyed.av" << 'EOF'
use @std.meta.{Named, delegates}

fn node(_t: Named, _rank: int) {}

@delegates(Shape)
trait Size {
    fn size() -> int
    fn scaled(by: int) -> int
}

@node(0)
type Dot = { at: int }

impl Size for Dot {
    fn size() -> int { 1 }
    fn scaled(by: int) -> int { by }
}

@node(1)
type Line = { from: int, to: int }

impl Size for Line {
    fn size() -> int { self.to - self.from }
    fn scaled(by: int) -> int { (self.to - self.from) * by }
}

collect enum Shape = @node in self by it.mark.args[0] dense

let d = Shape.Dot(4)
let l = Shape.Line(2, 9)
"${d.size()} ${l.size()} ${d.scaled(3)} ${l.scaled(3)}"
EOF
sed 's/it\.mark\.args\[0\]/it.mark.in[0]/' "$work/keyed.av" > "$work/miskeyed.av"
cat > "$work/relation.av" << 'EOF'
use @std.relation.{relation}

@relation
type Icon = { @key name: string }

1
EOF
program alone keyed.av
checked alone alone
[ "$(cat "$work/alone.status")" = 0 ] || { echo "store-programs: the delegated trait did not check in a directory of its own:"; tail -3 "$work/alone.out"; exit 1; }
program shared miskeyed.av
checked shared miskeyed
[ "$(cat "$work/miskeyed.status")" = 1 ] || { echo "store-programs: the trait keyed by an undeclared field was not refused (exit $(cat "$work/miskeyed.status")):"; tail -3 "$work/miskeyed.out"; exit 1; }
cp "$work/relation.av" "$work/shared/src/main.av"
checked shared relation
[ "$(cat "$work/relation.status")" = 0 ] || { echo "store-programs: the relation did not check (exit $(cat "$work/relation.status")):"; tail -3 "$work/relation.out"; exit 1; }
cp "$work/keyed.av" "$work/shared/src/main.av"
checked shared after
if [ "$(cat "$work/after.status")" != 0 ] || ! cmp -s "$work/alone.out" "$work/after.out"; then
    echo "store-programs: after two other programs in its directory, the delegated trait answered otherwise than alone (exit $(cat "$work/after.status")):"
    tail -3 "$work/after.out" | cut -c1-300
    exit 1
fi
echo "store-programs: the delegated trait checks after a refused trait and a relation in its directory as it does alone"
