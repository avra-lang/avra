#!/bin/sh
# THE COMPILE SLOT, kept. A package-scale build, check or test takes one
# of AVRA_MAX_COMPILES machine-wide slots and waits, saying so once,
# while every slot is held; a single file never waits; a process whose
# parent holds a slot takes none; 0 turns the cap off. A holder made of
# the slot's own C holds slot 0 until it is killed, so every row is
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
int64_t avra_io_compile_slot(void);
int main(void) { printf("%lld\n", (long long)avra_io_compile_slot()); fflush(stdout); pause(); return 0; }
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

if [ "$fails" -gt 0 ]; then
    echo "compile-slots: $fails of $rows contracts broken"
    exit 1
fi
echo "compile-slots: $rows contracts held"
