#!/bin/sh
# A DEVELOPER'S STORE BOUNDS ITSELF. Every changed program keeps a whole linked binary under
# `.avra-cache/bin`, one per program key, and nothing ever evicted one: a session of edits grew a
# store to 14.8 GB. The kept binaries now stand under a ceiling (`AVRA_BIN_MAX_BYTES`, a gigabyte
# by default), oldest out first, the newest always kept. N edit-build cycles under a small
# ceiling must leave `bin/` under it plus one binary, and the newest build must still hit.
# It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/store-bound; fails=0; N=6; CAP=${CAP:-50000}
find "$R" .avra-cache -type f -delete 2>/dev/null
mkdir -p $R/app/src
printf '[package]\nname = "sb"\nversion = "0.1.0"\n' > $R/app/avra.toml
bin_bytes() { find .avra-cache/bin -type f ! -name '*.deps' -exec wc -c {} + 2>/dev/null | awk '$2 != "total" {s += $1} END {print s + 0}'; }
bin_files() { find .avra-cache/bin -type f ! -name '*.deps' 2>/dev/null | wc -l | tr -d ' '; }
i=0
while [ $i -lt $N ]; do
    i=$((i + 1))
    printf 'println("cycle %s")\n' $i > $R/app/src/main.av
    AVRA_BIN_MAX_BYTES=$CAP AVRA_STORE_SEAL_FRAMES=1 ./avra build $R/app > $R/out 2>&1 || { fails=$((fails + 1)); echo "FAIL  cycle $i did not build: $(tail -n 5 $R/out | cut -c1-200)"; break; }
    echo "cycle $i: bin $(bin_bytes) bytes in $(bin_files) file(s)"
done
one=$(find .avra-cache/bin -type f ! -name '*.deps' -exec wc -c {} + 2>/dev/null | awk '$2 != "total" && $1 > m {m = $1} END {print m + 0}')
[ "$(bin_bytes)" -le $((CAP + one)) ] || { fails=$((fails + 1)); echo "FAIL  after $N cycles bin holds $(bin_bytes) bytes, over $CAP plus one binary ($one)"; }
[ "$(bin_files)" -ge 1 ] || { fails=$((fails + 1)); echo "FAIL  the newest binary was evicted"; }
AVRA_BIN_MAX_BYTES=$CAP ./avra build --time $R/app 2>&1 | grep -q "cache hit" || { fails=$((fails + 1)); echo "FAIL  the newest build did not hit after trimming"; }
echo "store-bound-attack: $N edit-build cycles under a $CAP-byte ceiling, $fails failed"
[ "$fails" -eq 0 ]
