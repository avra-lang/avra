#!/bin/sh
# A DIRECTORY BESIDE THE SOURCES MOVES NO ANSWER. A package's root gains directories its sources
# never name — `build/` after a first build, `.avra-cache`, a user's own — and its listing moves with
# them. What reads that listing asks only whether a manifest stands there (`holds_manifest`), so
# nothing typed or lowered from the sources is worked out again. Held over the suites fixture,
# whose tests reach every `use` line's check: tested cold, then warm after a directory is added at
# the package's root, and after another under `src/`; the warm runs type and lower nothing.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=root-listing-attack
. tools/lib/steps.sh
R=build/root-listing-attack
find "$R" -delete 2>/dev/null
mkdir -p "$R/m"
cp -R tools/program-suites/suited "$R/"
tested() { (cd "$R" && AVRA_CACHE_DIR="$PWD/m" AVRA_QUERY_TIMES=1 "$OLDPWD/build/avra" test suited >out 2>err); }
# worked again: the typing and lowering rows a run worked out, `name count`, one a line
worked() { grep "^worked:" "$R/err" | tr ',' '\n' | sed 's/.*; //; s/^ *//' | grep -E '^(lowered_case|lowered_under|entry_lowered|typed_fn|case_source) ' ; }
tested
grep -q "^worked:" "$R/err" && say "cold: tested, the work counted" || fail "the cold run counted no work: $(tail -2 "$R/err" | tr '\n' ' ')"
for added in notes src/drafts; do
    mkdir -p "$R/suited/$added"
    tested
    again=$(worked | tr '\n' ' ')
    [ -z "$again" ] && say "a directory added at suited/$added: nothing typed or lowered again" || fail "a directory added at suited/$added, and worked again: $again"
done
verdict
