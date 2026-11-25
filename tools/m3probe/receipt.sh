#!/bin/sh
# The M3 receipt over this tree's source: `check packages/cli` cold, warm,
# after a body edit, after a new declaration, each restored — for every
# binary named, every store moved aside before each binary's cold run.
# usage: sh tools/m3probe/receipt.sh <label>=<binary> ...
set -u
out=build/m3receipt; mkdir -p $out
body=packages/cli/src/commands/cache.av
cp $body $out/body.orig
now() { date +%s.%N; }
run() { # run <bin> <label> <step>
    t0=$(now)
    "$1" check --time packages/cli > $out/$2-$3.log 2>&1; st=$?
    t1=$(now)
    line=$(grep -m1 '^time:' $out/$2-$3.log)
    held=$(printf '%s' "$line" | grep -oE 'held [0-9]+/[0-9]+')
    case "$line" in *"cache hit"*) held="whole-check cache hit" ;; esac
    reads=$(sed -n '/^read:/,$p' $out/$2-$3.log | grep '^  ' | head -14 | tr '\n' ';')
    printf '%-6s %-10s exit %s  %6.2fs  %s  %s\n' "$2" "$3" "$st" "$(awk -v a="$t0" -v b="$t1" 'BEGIN { print b - a }')" "$held" "$reads"
    grep -m1 'hold was refused' $out/$2-$3.log
}
for pair in "$@"; do
    label=${pair%%=*}; bin=${pair#*=}
    [ -d .avra-cache ] && mv .avra-cache "$out/aside-$label-$(date +%s)"
    run "$bin" "$label" cold
    run "$bin" "$label" warm
    python3 - "$body" <<'PY'
import sys
p=sys.argv[1]; t=open(p).read(); old="not `${word}`\""; assert old in t; open(p,'w').write(t.replace(old,"not `${word}` \"",1))
PY
    run "$bin" "$label" body-edit
    cp $out/body.orig $body
    run "$bin" "$label" restored
    printf '\nfn witness_receipt_probe() -> int { 1 }\n' >> $body
    run "$bin" "$label" new-decl
    cp $out/body.orig $body
    run "$bin" "$label" restored2
done
