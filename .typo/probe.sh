#!/bin/sh
# usage: probe.sh <dir> <use-line> ; runs clean cold, clean warm, typo warm, valid warm
set -u
D=$1; USE=$2; AV=${AV:-$PWD/build/avra}
find "$D" -delete 2>/dev/null; mkdir -p "$D/src"
printf '[package]\nname = "probe"\nversion = "0.1.0"\n\n[bin]\nname = "probe"\npath = "src/main.av"\n' > "$D/avra.toml"
run() { label=$1; s=$(date +%s%N); AVRA_QTRACE=1 $AV check --time "$D" 2>"$D/trace.$label" >"$D/out.$label"; st=$?; e=$(date +%s%N)
  printf '%s status=%s %sms computes=%s typed=%s parses=%s attempts=%s\n' "$label" $st $(( (e - s) / 1000000 )) \
   $(grep -c '^Q.ask.*compute$' "$D/trace.$label") $(grep -c '^Q.ask.Typed.*compute$' "$D/trace.$label") $(grep -c '^Q.parse' "$D/trace.$label") $(grep -c '^Q.attempt' "$D/trace.$label"); }
printf '%s\nfn main() { let x = 1 }\n' "$USE" > "$D/src/main.av"; run clean
printf '%s\nfn main() { let x = 2 }\n' "$USE" > "$D/src/main.av"; run valid
printf '%s\nfn main() { let _ _ = 1 }\n' "$USE" > "$D/src/main.av"; run typo
printf '%s\nfn main() { let x = 3 }\n' "$USE" > "$D/src/main.av"; run valid2
printf '%s\nfn main() { let x: string = 1 }\n' "$USE" > "$D/src/main.av"; run typeerr
printf '%s\nfn main() { let x = 4 }\n' "$USE" > "$D/src/main.av"; run valid3
