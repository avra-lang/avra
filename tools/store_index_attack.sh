#!/bin/sh
# AN OPEN READS THE INDEX ONLY. Two packages, the same program shape, one with
# far more records. A warm no-op check opens the newest body; its read covers that
# body's index (the .pack), never its value tier (.val), and the number of values
# a warm check reads does not grow with the record count: 400 and 1600 records read at most
# the three rows of its answer.
set -u
. "$(dirname "$0")/lib/attack.sh"
AVRA=${AVRA:-./avra}

R=build/store-index
rm -rf "$R" .avra-cache && mkdir -p $R
fixture() { # fixture <dir> <count>
    mkdir -p $1/src
    printf '[package]\nname = "si-p"\nversion = "0.1.0"\n' > $1/avra.toml
    : > $1/src/main.av
    i=0; sum=""
    while [ $i -lt $2 ]; do
        echo "fn f$i() -> int { $i }" >> $1/src/main.av
        sum="$sum${sum:+ + }f$i()"
        i=$((i + 1))
    done
    echo "println(\"\${$sum}\")" >> $1/src/main.av
}
fixture $R/small 10
fixture $R/medium 400
fixture $R/large 1600

# measure <name>: a warm no-op check of <name>, and what its open read.
measure() {
    $AVRA check $R/$1 > $R/$1.cold 2>&1 || { echo "store-index: FAILED — the cold $1 check did not pass"; fails=1; return; }
    AVRA_QTRACE=1 $AVRA check $R/$1 > $R/$1.warm 2> $R/$1.err
    body=$(grep '^Q	store	body	' $R/$1.err | tail -1)
    bodies=$(grep -c '^Q	store	body	' $R/$1.err)
    values=$(grep -c '^Q	store	value	' $R/$1.err)
    rows=$(grep -c '^Q	store	row	' $R/$1.err)
    pack=$(ls -l .avra-cache/store/body-*.pack | sort -k9 | tail -1 | awk '{print $5}')
    val=$(ls -l .avra-cache/store/body-*.val | sort -k9 | tail -1 | awk '{print $5}')
    read_bytes=$(printf '%s' "$body" | awk -F'\t' '{print $5}')
    echo "$1: bodies read $bodies, body bytes $read_bytes (pack $pack), value tier $val bytes, values read $values, rows decoded $rows"
    eval "bodies_$1=$bodies; read_$1=${read_bytes:-0}; pack_$1=$pack; val_$1=$val; values_$1=$values; rows_$1=$rows"
}
measure small
measure medium
measure large
rm -f $R/*.cold
# the body the open reads is its head and index: a part of the .pack, and never the value tier
[ "$bodies_small" = 1 ] && [ "$bodies_large" = 1 ] || { fails=$((fails + 1)); echo "store-index: FAILED — a warm open read $bodies_small / $bodies_large bodies, not one each"; }
[ "$read_large" -lt "$pack_large" ] || { fails=$((fails + 1)); echo "store-index: FAILED — the large open read $read_large bytes, all of its $pack_large: the rows were read at open"; }
[ "$read_large" -lt "$val_large" ] || { fails=$((fails + 1)); echo "store-index: FAILED — the large open read as much as the value tier ($read_large >= $val_large)"; }
# the value reads of a warm check do not grow with the record count: they are the rows of its
# own answer (warnings, findings, licenses), and a row still in a segment is read from memory
[ "$values_large" -le 3 ] && [ "$values_medium" -le 3 ] || { fails=$((fails + 1)); echo "store-index: FAILED — a warm check read $values_large values on 1600 records and $values_medium on 400, more than the three rows of its answer"; }
# the ROWS a warm check decodes are the ones it asks for, never the body's: a count, not a
# time, and it does not grow with the record count
[ "$rows_large" -le 8 ] && [ "$rows_medium" -le 8 ] && [ "$rows_small" -le 8 ] || { fails=$((fails + 1)); echo "store-index: FAILED — a warm check decoded $rows_large rows on 1600 records, $rows_medium on 400 and $rows_small on 10, more than its answer's eight"; }
[ "$fails" = 0 ] && echo "store-index: the open read the index only, and rows and values read did not grow with records" || exit 1
