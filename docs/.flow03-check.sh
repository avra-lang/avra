#!/bin/sh
# flow-03k targeted checks (STEP A). Output whole to a file; a summary on stderr.
LOG=/tmp/flow03-check.log
: > "$LOG"
export AVRA_MEM_CEILING_MB=5000
status=0
run() {
    name="$1"; shift
    echo "=== $name ==="
    if "$@" >>"$LOG" 2>&1; then echo "PASS $name"; else echo "FAIL $name"; status=1; fi
}
run compiler          make avra
run runtime-tests      make runtime-tests
run runtime-mutations  make runtime-mutations
run std-avrac-core     ./build/avra test packages/std-avrac/src/core/tests
run std-net            ./build/avra test packages/std-net
run std-tls            ./build/avra test packages/std-tls
run std-http           ./build/avra test packages/std-http
run idioms             make idioms
run fmt                ./build/avra fmt --check packages/std-avrac/src/core/ir.av packages/std-http/src/tests/http_stop_zero/http_stop_zero.av packages/std-net/src/net.av packages/std-tls/src/tests/parked_tls_interrupt/parked_tls_interrupt.av
echo "=== SUMMARY status=$status ==="
if [ "$status" -ne 0 ]; then
    echo "--- failures ---"
    grep -nE "FAIL|refused|refus|error\[|does not|trap|panic|assert" "$LOG" | head -60
    echo "--- last 60 lines ---"
    tail -60 "$LOG"
fi
exit "$status"
