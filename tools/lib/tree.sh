# THE TREE A TOOL STANDS IN, sourced first by the tools that ask it (`. "$(dirname "$0")/lib/tree.sh"`; in a
# sourced file `$0` is still the caller's): `here` is tools/, `tree` its root, `avra` the compiler (AVRA,
# else the tree's build).
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
