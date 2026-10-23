#!/bin/sh
# THE COMPILE SLOT, kept. A package-scale build, check or test takes one
# of AVRA_MAX_COMPILES machine-wide slots and waits, saying so once,
# while every slot is held; a single file never waits; a process whose
# parent holds a slot takes none; 0 turns the cap off. Waiters are served
# in the order they began waiting and sleep in the kernel between: the
# witness counts a waiter's voluntary context switches over a two-second
# wait, which a timer poll would run up and a block does not. A holder made
# of the slot's own C holds a slot until it is killed, so every row is
# deterministic.
set -u
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
D=build/compile-slots
mkdir -p "$D"
fails=0
rows=0

cat > "$D/holder.c" <<'C'
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/resource.h>
int64_t avra_io_compile_slot(void);
/* holder [label order-file switches-file]: takes a slot, says which; with a label,
   appends it to the order file and writes its voluntary context switches so far. */
int main(int argc, char** argv) {
    printf("%lld\n", (long long)avra_io_compile_slot());
    fflush(stdout);
    if (argc > 3) {
        struct rusage ru;
        getrusage(RUSAGE_SELF, &ru);
        FILE* r = fopen(argv[3], "w");
#ifdef __APPLE__
        fprintf(r, "unread\n"); /* Darwin does not fill ru_nvcsw */
#else
        fprintf(r, "%ld\n", (long)ru.ru_nvcsw);
#endif
        fclose(r);
        FILE* o = fopen(argv[2], "a");
        fprintf(o, "%s\n", argv[1]);
        fclose(o);
    }
    pause();
    return 0;
}
C
cc -O1 -o "$D/holder" "$D/holder.c" build/std_io.o build/libavra_runtime.a || { echo "compile-slots: the holder did not build"; exit 1; }

row() {
    rows=$((rows + 1))
    if [ "$2" != "$3" ]; then
        echo "compile-slots: $1 — got '$2', the contract says '$3'"
        fails=$((fails + 1))
    fi
}
waited() { grep -c "avra: waiting for a compile slot" "$1" | tr -d ' '; }

# THE KERNEL'S SEMAPHORE TABLE IS BOUNDED AND A SET OUTLIVES ITS PROCESSES: the
# keeper counts the sets it makes and removes them when it is done.
sets() {
    if [ "$(uname)" = Darwin ]; then ipcs -s | awk '$1 == "s" { print $2 }'; else ipcs -s | awk '/^0x/ { print $2 }'; fi | sort
}
sets_before="$D/sets.before"
sets > "$sets_before"

export AVRA_MAX_COMPILES=1
# a private slot directory: another session's compile never holds these
export AVRA_SLOT_DIR="$PWD/$D/slots"
unset AVRA_COMPILE_SLOT

"$D/holder" > "$D/held.out" &
H=$!
sleep 1
row "the holder took slot 0" "$(cat "$D/held.out")" "0"

build/avra check packages/std-json/src/json.av > "$D/file.out" 2>&1
row "a single file never waits" "$(waited "$D/file.out")" "0"

AVRA_COMPILE_SLOT=0 build/avra check packages/std-json > "$D/inherited.out" 2>&1
row "a process whose parent holds a slot takes none" "$(waited "$D/inherited.out")" "0"

AVRA_MAX_COMPILES=0 build/avra check packages/std-json > "$D/off.out" 2>&1
row "a cap of 0 is off" "$(waited "$D/off.out")" "0"

build/avra check packages/std-json > "$D/package.out" 2>&1 &
P=$!
sleep 1
kill $H
wait $H 2>/dev/null
wait $P && s=0 || s=$?
row "a package check waits while every slot is held, and says so once" "$(waited "$D/package.out")" "1"
row "a package check that waited runs once the slot frees" "$s" "0"

# ARRIVAL ORDER, AND A WAIT THAT SLEEPS: one slot, a holder, five waiters begun one
# after the other (each begun once the one before has said it waits); the holder
# goes, then each acquirer in turn. The order they acquire in is the order they came.
F="$D/fair"
find "$F" -delete 2>/dev/null
mkdir -p "$F"
export AVRA_SLOT_DIR="$F/slots"
until_gone() { n=0; until eval "$1"; do n=$((n + 1)); [ "$n" -gt 400 ] && return 1; sleep 0.05; done; }
"$D/holder" 0 "$F/order" "$F/switches.0" > "$F/out.0" 2>&1 &
HOLD=$!
until_gone "[ -s '$F/order' ]"
pids=""
for i in 1 2 3 4 5; do
    "$D/holder" $i "$F/order" "$F/switches.$i" > "$F/out.$i" 2>&1 &
    pids="$pids $!"
    until_gone "grep -q 'waiting for a compile slot' '$F/out.$i'"
done
sleep 2
kill $HOLD
i=0
for p in $pids; do
    i=$((i + 1))
    until_gone "[ \$(wc -l < '$F/order') -ge $((i + 1)) ]"
    kill $p
done
wait 2>/dev/null
row "five waiters over one slot acquire in the order they began waiting" "$(tr '\n' ' ' < "$F/order")" "0 1 2 3 4 5 "
if [ "$(cat "$F/switches.1")" = unread ]; then
    echo "compile-slots: the wait's wakeups are unread on this host (Darwin keeps no voluntary-switch count); the quiet-wait row is held on Linux"
else
    echo "compile-slots: the waiter's wakeups over a two-second wait: $(cat "$F/switches.1")"
    row "a waiter that waited two seconds woke at most six times (a block, not a poll)" "$([ "$(cat "$F/switches.1")" -le 6 ] && echo yes || echo "no: $(cat "$F/switches.1")")" "yes"
fi

# A SLOT DIRECTORY MADE AGAIN FINDS ITS SET: the same name and cap add no set.
sets > "$D/sets.mid"
find "$F/slots" -delete 2>/dev/null
"$D/holder" > "$F/again.out" 2>&1 &
AGAIN=$!
until_gone "[ -s '$F/again.out' ]"
kill $AGAIN
wait $AGAIN 2>/dev/null
sets > "$D/sets.after"
row "a slot directory made again adds no semaphore set" "$(cmp -s "$D/sets.mid" "$D/sets.after" && echo same || echo grew)" "same"
for id in $(comm -13 "$sets_before" "$D/sets.after"); do ipcrm -s "$id" 2>/dev/null; done
row "the keeper leaves the kernel's semaphore table as it found it" "$(sets | cmp -s - "$sets_before" && echo same || echo changed)" "same"

if [ "$fails" -gt 0 ]; then
    echo "compile-slots: $fails of $rows contracts broken"
    exit 1
fi
echo "compile-slots: $rows contracts held"
