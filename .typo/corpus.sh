#!/bin/sh
# usage: corpus.sh <binary> <outdir> — each case warmed clean, then broken; prints the broken check's output
set -u
AV=$1; OUT=$2; mkdir -p "$OUT"
USE='use @std.ui.components.{column}'
case_run() { name=$1; main=$2; other=${3:-}
  D=/tmp/corpus-$(basename "$OUT")-$name; find "$D" -delete 2>/dev/null; mkdir -p "$D/src"
  printf '[package]\nname = "probe"\nversion = "0.1.0"\n\n[bin]\nname = "probe"\npath = "src/main.av"\n' > "$D/avra.toml"
  printf '%s\nfn main() { let x = 1 }\n' "$USE" > "$D/src/main.av"
  printf 'export fn helper() -> int { 1 }\n' > "$D/src/other.av"
  $AV check "$D" >/dev/null 2>&1
  printf '%s' "$main" > "$D/src/main.av"
  [ -n "$other" ] && printf '%s' "$other" > "$D/src/other.av"
  $AV check "$D" > "$OUT/$name.out" 2>&1; echo "status $?" >> "$OUT/$name.out"
  sed -i "s|$D|<D>|g" "$OUT/$name.out"
}
case_run let_wild "$USE
fn main() { let _ _ = 1 }
"
case_run missing_rhs "$USE
fn main() { let x = }
"
case_run unimported_button "$USE
fn main() { button b { label: \"x\" } }
"
case_run unimported_top "button b { label: \"x\" }
"
case_run semicolon "$USE
let a = 1; a
"
case_run open_paren "$USE
fn main() { if (true { } }
"
case_run two_errors "$USE
fn main() { let _ _ = 1 }
fn g() { let = 2 }
"
case_run other_file "$USE
fn main() { let x = helper() }
" "export fn helper() -> int { let _ _ = 1 }
"
case_run parse_and_type "$USE
fn main() { let y: string = 1 }
" "export fn helper() -> int { let _ _ = 1 }
"
case_run stray_brace "$USE
fn main() { let x = 1 }}
"
