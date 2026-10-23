#!/bin/sh
# A STORE NAMES NO PLACE. Every key and every read name is `package:relative/path`
# (`Workspace.stored_name`), so a tree checked in one directory and copied whole to
# another reads its rows warm there: the copy parses no file, its store holds no byte
# of the first tree's absolute path, and an edit made after the copy is still seen.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
who=store-names
. tools/lib/steps.sh

R=build/store-names
rm -rf "$R" && mkdir -p $R/a/.git $R/a/p/src
cat > $R/a/p/avra.toml <<'TOML'
[package]
name = "sn-p"
version = "0.1.0"
TOML
cat > $R/a/p/src/main.av <<'AV'
use @std.json.{to_text}
use @std.text.{from_codepoint}
fn main() -> int { 1 + 2 }
AV

tab="$(printf '\t')"

./avra check $R/a/p > $R/cold.out 2>&1 || { fail "the cold check did not pass"; cat $R/cold.out; verdict; exit 1; }
[ "$(ls $R/a/.avra-cache/store 2>/dev/null | wc -l)" -ge 1 ] || { fail "the cold check kept nothing, so the copy proves nothing"; verdict; exit 1; }

cp -R $R/a $R/b
AVRA_QTRACE=1 ./avra check $R/b/p > $R/copy.out 2>&1 || fail "the check of the copy did not pass"
parsed=$(grep -c "^Q${tab}parse${tab}" $R/copy.out)
[ "$parsed" = 0 ] && say "the copy parsed no file" || fail "the copy parsed $parsed file(s): a row is filed under where the tree stood"

origin="$(pwd)/$R/a"
named=$(grep -rlaF "$origin" $R/b/.avra-cache/store | wc -l | tr -d ' ')
[ "$named" = 0 ] && say "the copy's store names no byte of the first tree's path" || fail "$named store file(s) name $origin"

printf 'use @std.json.{to_text}\nfn main() -> int { nope }\n' > $R/b/p/src/main.av
./avra check $R/b/p > $R/edit.out 2>&1
grep -q 'nope' $R/edit.out && say "an edit after the copy is seen" || fail "an edit after the copy was not seen"

verdict "a store copied whole is warm and names no place"
