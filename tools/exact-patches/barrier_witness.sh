#!/bin/sh
# Every write to a `state` place leaves its version one higher under
# AVRA_EXACT, and the program answers the same with the flag off. The witness
# writes through five kinds of place: a local, a top-level declaration, a
# state field, a state seat and a capture.
# usage: sh tools/exact-patches/barrier_witness.sh [avra-binary]
set -eu
avra=${1:-build/avra-try}
dir=$(dirname "$0")/witness
off=$(env -u AVRA_EXACT "$avra" run "$dir" 2>/dev/null | tail -1)
on=$(AVRA_EXACT=1 "$avra" run "$dir" 2>/dev/null | tail -1)
writes=5
bumps=$(AVRA_EXACT=1 "$avra" ir "$dir" 2>/dev/null | grep -c 'avra_slot_set(r[0-9]*, r[0-9]*, r[0-9]*)$' || true)
plain=$(env -u AVRA_EXACT "$avra" ir "$dir" 2>/dev/null | grep -c 'avra_slot_set(r[0-9]*, r[0-9]*, r[0-9]*)$' || true)
echo "answers: off='$off' on='$on'; value stores $plain, with versions $bumps (writes $writes)"
[ "$off" = "$on" ] && [ "$plain" -eq "$writes" ] && [ "$bumps" -eq $((2 * writes)) ]
