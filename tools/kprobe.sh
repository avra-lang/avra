#!/bin/bash
export LLVM_PREFIX=/usr/lib/llvm-22
d=$(mktemp -d)/kp; mkdir -p $d/src/lib $d/src/shapes
printf '[package]\nname = "kept"\nversion = "0.1.0"\n' > $d/avra.toml
cat > $d/src/main.av <<'X'
use lib.{one, maybe, L}
use shapes.{Count, Box}
extern fn avra_puts(s: string)
fn base() -> int { 2 }
fn side() -> int {
    1
}
fn pick(b: bool) -> int { if b { side() } else { 0 } }
fn total(c: dyn Count) -> int { c.count() }
const K: int = base() * 10 + one() + L + pick(false) + maybe(false) + total(Box { n: 3 })
println("${K}")
X
cat > $d/src/lib/lib.av <<'X'
extern fn avra_puts(s: string)
export fn one() -> int { 100 }
export const L: int = 1000
fn quiet() -> int {
    7
}
export fn maybe(b: bool) -> int { if b { quiet() } else { 0 } }
X
cat > $d/src/shapes/shapes.av <<'X'
extern fn avra_puts(s: string)
export trait Count {
    fn count() -> int
}
export type Box = { n: int }
impl Count for Box {
    fn count() -> int {
        self.n
    }
}
X
build/avra check $d 2>&1 | tail -3
echo "== cold done"
sed -i 's/^    1$/    avra_puts("x")\n    1/' $d/src/main.av; sed -n 4,9p $d/src/main.av
build/avra check --time $d 2>&1 | grep -v "^ *$" | head -30
