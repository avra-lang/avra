#!/bin/sh
# THE CENSUS BUILD: exact retain/release/list-write counts, and the
# callers that cause them. Counting costs ~8% of a run, so it never
# ships — the runtime is rebuilt with -DAVRA_CENSUS here and the
# shipping one is put back ON EVERY EXIT, because a census runtime
# left in build/ is a slower compiler that nothing announces.
#   sh tools/census.sh check packages/std-avrac
set -e
cd "$(dirname "$0")/.."

restore() {
    rm -f build/avra_runtime.o build/avra
    make --no-print-directory avra > /dev/null 2>&1 || \
        echo "census: the shipping compiler did NOT rebuild — run \`make avra\`"
}
trap restore EXIT INT TERM

cc -O2 -Wall -Werror -DAVRA_CENSUS -c runtime/avra_runtime.c -o build/avra_runtime.o
rm -f build/avra
make --no-print-directory avra > /dev/null
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 sh tools/watch.sh 4000 ./avra "$@" 2>&1 >/dev/null \
    | grep -E '^(rc|push|copy):' || true
