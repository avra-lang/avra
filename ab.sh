#!/bin/sh
# A/B one-body edits: sh ab.sh <binA> <binB> <rounds>
# Each binary keeps its own store; edits alternate A, B per scenario round.
set -u
A=$1; B=$2; R=${3:-3}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-6000}
pkg=packages/cli
now() { date +%s%N; }
run() { # label bin store
    s=$(now)
    AVRA_CACHE_DIR=$3 "$2" check --time --counts $pkg > build/ab.out 2>&1
    st=$?
    e=$(now)
    echo "$1	wall_ms=$(((e - s) / 1000000))	st=$st	$(grep '^time:' build/ab.out | tail -n 1)	$(grep -E '^(edit|held|count)' build/ab.out | tr '\n' ' ' | cut -c1-400)"
}
edit() { python3 -c "import sys,time;t=open(sys.argv[1]).read();open(sys.argv[1],'w').write(t.replace(sys.argv[2],sys.argv[2]+' e'+str(time.time_ns()),1))" "$1" "$2"; }
scen() { # label file literal
    cp "$2" build/ab.orig
    i=1
    while [ $i -le $R ]; do
        edit "$2" "$3"; run "$1.A$i" "$A" build/cacheA
        cp build/ab.orig "$2"; edit "$2" "$3"; run "$1.B$i" "$B" build/cacheB
        cp build/ab.orig "$2"
        i=$((i + 1))
    done
}
for c in build/cacheA build/cacheB; do [ -d $c ] && find $c -delete; done
run coldA "$A" build/cacheA
run coldB "$B" build/cacheB
run noopA "$A" build/cacheA
run noopB "$B" build/cacheB
scen receipt packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'
scen cli packages/cli/src/commands/shared.av '· memo'
scen avrac packages/std-avrac/src/diagnostics/render.av '<source>'
run noopA "$A" build/cacheA
run noopB "$B" build/cacheB
