#!/bin/sh
# THE LIBRARY SCOPE, KEPT. A package's library is opened `RTLD_LOCAL`,
# so its symbols are reachable through that handle and NOWHERE else —
# in particular not through the process, which `dlsym(RTLD_DEFAULT)`
# asks. That is the whole of S2c's narrowing, and it is the one
# property whose failure looks exactly like success.
#
# WHY NOT AN ORDERED PAIR OF PROGRAMS, which is what the design asked
# for first: a package's program tests run in ONE process over ONE
# WORKSPACE, so every program in it shares one dependency closure. "A program that does not depend on
# sqlite, running after one that does" is not expressible there — the
# second program would have the first's closure. No harness in the
# tree runs two closures in one process.
#
# SO THE MECHANISM IS TESTED DIRECTLY INSTEAD, in ONE program, and it
# is strictly better than the pair would have been: there is no order
# to get wrong, no directory-walk luck, and no rename that silently
# reverses it. The program asks the IMAGE-ONLY lookup for a symbol
# that lives in a library its own closure opened. Under `RTLD_LOCAL`
# that answers 0. Under `RTLD_GLOBAL` it answers an address, which is
# the leak, and flipping the flag in `ffi.c` turns row 2 red.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

ROOT=build/libscope
fails=0
rows=0

# A program run under the EVALUATOR alone: `avra run`, its printed
# value compared with the contract. Native is a different question —
# a native binary links its packages' objects directly and has no
# library to scope.
scoped() {
    name="$1"; want="$2"; deps="$3"; src="$4"
    rows=$((rows + 1))
    dir="$ROOT/$name"
    mkdir -p "$dir/src"
    printf '[package]\nname    = "zz-scope-%s"\nversion = "0.0.1"\n%s' "$name" "$deps" > "$dir/avra.toml"
    printf '%s' "$src" > "$dir/src/main.av"
    got=$(./avra run "$dir/src/main.av" 2>&1) || true
    if [ "$got" != "$want" ]; then
        echo "libscope: $name said"; echo "  $got"; echo "  the contract says"; echo "  $want"
        fails=$((fails + 1))
    fi
}

SQLITE='
[dependencies]
"@std/sqlite" = { path = "../../../packages/std-sqlite" }
"@std/errors" = { path = "../../../packages/std-errors" }
'

# 1. THE LIBRARY IS REACHED BY A PROGRAM THAT DEPENDS ON THE PACKAGE.
#    Before S2c this refused by name under the evaluator — sqlite's
#    object is not in `build/avra`, which is why sqlite's programs were
#    native-only.
scoped reached "true" "$SQLITE" 'use @std.sqlite.{version}
version().length > 0
'

# 2. AND ITS SYMBOLS ARE NOT IN THE PROCESS. This is the row that
#    holds the flag. `avra_ffi_symbol` is the frame's IMAGE-ONLY
#    lookup — `dlsym(RTLD_DEFAULT)` — and it must answer 0 for a
#    symbol that lives only behind a handle. Flip `RTLD_LOCAL` to
#    `RTLD_GLOBAL` in packages/std-avrac/src/c/ffi.c and this row goes
#    red; that is how it was witnessed before it was trusted.
scoped not_in_the_process "true" "$SQLITE" 'use @std.sqlite.{version}
extern fn avra_ffi_symbol(name: string) -> int
let _ = version()
avra_ffi_symbol("sqlite3_libversion") == 0
'

# 3. A PROGRAM THAT DECLARES THE DEPENDENCY NOWHERE CANNOT REACH IT,
#    and the refusal names the symbol. This row does NOT test the
#    flag — nothing opened the library in this process either way —
#    it tests that the image fallback did not quietly widen.
scoped undeclared "avra: \`sqlite3_libversion\` is extern and this image does not carry it — build natively" "" 'extern fn sqlite3_libversion() -> string
sqlite3_libversion().length > 0
'

# 4. A SYMBOL WHOSE LIBRARY WAS NEVER BUILT IS BLAMED ON THE PACKAGE THAT
#    DECLARES IT — never on another package of the closure with no
#    library of its own (one the image carries has none), which would
#    send the reader to rebuild the wrong one.
mkdir -p "$ROOT/owner/src"
printf '[package]\nname    = "@zz/owner"\nversion = "0.0.1"\n\n[link]\nobjects = ["never_built.o"]\n' > "$ROOT/owner/avra.toml"
printf 'extern fn zz_owned() -> int\nexport fn held() -> int { zz_owned() }\n' > "$ROOT/owner/src/owner.av"
scoped blamed "avra: \`zz_owned\` is extern and this image does not carry it, and @zz/owner declares it but has no library built — run \`make libs\` — build natively" '
[dependencies]
"@zz/owner" = { path = "../owner" }
' 'use @zz.owner.{held}
held()
'

# 5. AND A LIBRARY BUILT WITHOUT IT IS NAMED AS THAT: the package's own
#    library opened and lacks the symbol, so the rebuild it asks for is
#    that package's.
printf 'int zz_unrelated(void) { return 0; }\n' > "$ROOT/owner/empty.c"
cc -dynamiclib -o build/libzz-owner.dylib "$ROOT/owner/empty.c" 2>/dev/null || cc -shared -fPIC -o build/libzz-owner.so "$ROOT/owner/empty.c"
scoped without "avra: \`zz_owned\` is extern and this image does not carry it, and @zz/owner declares it but its library does not carry it — rebuild it with \`make libs\` — build natively" '
[dependencies]
"@zz/owner" = { path = "../owner" }
' 'use @zz.owner.{held}
held()
'
rm -f build/libzz-owner.dylib build/libzz-owner.so

if [ "$fails" != 0 ]; then
    echo "libscope: $fails of $rows rows failed"
    exit 1
fi
echo "libscope: $rows rows — a package's library is reached by its dependents and by nobody else"
