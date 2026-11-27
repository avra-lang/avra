#!/bin/sh
# A MEASUREMENT'S STREAM AS LEDGER ROWS, judged by `wisp cost` against the record under cost/. The
# stream is the lines tools/speed_measure.sh, tools/warm_edit_bench.sh and tools/ci_wall.sh print:
#   host <host>                       the machine that measured; it keys every clock row
#   build|check <phase> <ms>          a phase of the cli's build or check   speed:<host>:<cmd> <phase>
#   warm <scenario> <ms>              a warm check's wall                   warm:<host>:warm <scenario>
#   wall <job> <ms>                   a run's job clock                     wall:<host>:wall <job>
#   counts <scenario> <counter> <n>   the work a warm check counted         work:-:warm-<scenario> <counter>
#                                     — an edit's `_ppm` ratio a `share` row, the program's sizes and the
#                                     raw counts behind a ratio `told` rows
#   skip <what>                       the measurement could not judge — refused, unless WARM_EDIT_SKIP
#                                     is set by hand, which says so
# A round is a line, and the ledger's kind folds a row's rounds. CLOCK rows are a stream's timings, WORK
# rows its counts; a caller judges each family with its own verb.
#   sh tools/ledger_rows.sh <stream> <name> clock|work judge|accept|tell
set -eu
. "$(dirname "$0")/lib/tree.sh"
stream=${1:?ledger_rows: a stream}
name=${2:?ledger_rows: a name}
family=${3:?ledger_rows: clock or work}
verb=${4:?ledger_rows: judge, accept or tell}
cause=${5:-}
case $family in clock | work) ;; *) echo "ledger_rows: clock or work, never $family" >&2; exit 2 ;; esac
case $verb in judge | accept | tell) ;; *) echo "ledger_rows: judge, accept or tell, never $verb" >&2; exit 2 ;; esac
[ -f "$stream" ] || { echo "ledger_rows: no stream at $stream" >&2; exit 1; }
skipped=$(grep -E '^skip ' "$stream" | head -1 || :)
if [ -n "$skipped" ]; then
    if [ -n "${WARM_EDIT_SKIP:-}" ]; then
        echo "ledger_rows: $name SKIPPED BY REQUEST (WARM_EDIT_SKIP=$WARM_EDIT_SKIP) — not judged"
        exit 0
    fi
    echo "ledger_rows: REFUSED — the measurement said \`$skipped\`, and a skip is not a pass; set WARM_EDIT_SKIP=1 by hand only to skip" >&2
    exit 1
fi
host=$(sed -n 's/^host \([^ ]*\)$/\1/p' "$stream" | head -1)
[ -n "$host" ] || host=$(sh "$here/host_key.sh")
out=$tree/build/ledger/$name
mkdir -p "$out"
find "$out" -mindepth 1 -delete
# the program's sizes and the raw counts whose ratios are held: reported, never judged
told=" rule_ms program_files program_modules program_decls files_minted modules_minted queries_computed store_rows_written "
if [ "$family" = clock ]; then
    awk -v h="$host" '
        $1 ~ /^(build|check)$/ && NF == 3 && $3 ~ /^[0-9]+$/ { print "speed:" h ":" $1 " " $2 " " $3 }
        $1 == "warm" && NF == 3 && $3 ~ /^[0-9]+$/ { print "warm:" h ":warm " $2 " " $3 }
        $1 == "wall" && NF == 3 && $3 ~ /^[0-9]+$/ { print "wall:" h ":wall " $2 " " $3 }' "$stream" > "$out/rows"
else
    awk -v told="$told" '
        $1 == "counts" && NF == 4 && $4 ~ /^[0-9]+$/ {
            kind = "work"
            if (index(told, " " $3 " ") > 0) kind = "told"
            else if ($2 == "edit" && $3 ~ /_ppm$/) kind = "share"
            print kind ":-:warm-" $2 " " $3 " " $4
        }' "$stream" > "$out/rows"
fi
[ -s "$out/rows" ] || { echo "ledger_rows: REFUSED — $name's stream holds no $family row (did the measurement run?)" >&2; exit 1; }
echo "ledger_rows: $name, $(wc -l < "$out/rows" | tr -d ' ') $family row(s) measured on $host"
if [ "$verb" = accept ]; then exec sh "$here/../wisp" cost accept "$out" "$cause"; fi
exec sh "$here/../wisp" cost "$verb" "$out"
