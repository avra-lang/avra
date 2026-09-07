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
# THE FILTER DROPS `mem:`, IT DOES NOT SELECT LABELS. An allowlist of
# census labels is a second registry of them, and it goes stale
# silently: a new counter prints and this grep eats it, so the tool
# reports the ABSENCE of what it cut. It hid `once:` when that landed,
# and hid `retain:` when that did — twice, in one session, from the
# author of both. An OMISSION is invisible and NOISE is not, so this
# refuses only the one label it knows it does not want.
out="$(AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 sh tools/watch.sh 4000 ./avra "$@" 2>&1 >/dev/null \
    | grep -Ev '^(mem:|watch:)' || true)"

# A SITE IS RESOLVED HERE OR NEVER. The tables print raw addresses into
# the census BINARY, and the trap above puts the shipping compiler back
# on exit — so by the time a reader runs `atos` the file those
# addresses belong to is gone, and they resolve against a different
# build or not at all. Name them while the binary is still standing.
printf '%s\n' "$out" | while IFS= read -r line; do
    case "$line" in
        *": site 0x"*)
            # shellcheck disable=SC2086
            set -- $line
            name="$(atos -o build/avra "$3" 2>/dev/null | head -1)"
            case "$name" in
                ""|*"0x"*) echo "$line" ;;
                *) echo "$1 $name $4" ;;
            esac
            ;;
        *) echo "$line" ;;
    esac
done
