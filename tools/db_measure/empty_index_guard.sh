# .195 follow-up: replay the empty_index sample's life under the guard,
# on a tiny package (never a whole package).
cd "$(dirname "$0")/../.." || exit 1
D=/tmp/guardpkg.$$
mkdir -p "$D/src"
printf '[package]\nname = "guardpkg"\nversion = "0.1.0"\n' > "$D/avra.toml"
printf 'println("guarded")\n' > "$D/src/main.av"
AVRA_RC_GUARD=1 AVRA_MEM_SITE=8dca1c AVRA_MEM_STATS=1 ./avra build "$D" > build/guard.out 2> build/guard.err
echo "exit $?"
echo "== the sample's life =="
grep -nE 'LEAK at site|retain from|release from|history truncated|RELEASED box' build/guard.err | head -50
echo "== peak/live (guard inflated; only the site's made is read here) =="
grep '^mem:   site' build/guard.err | head -6
grep '^mem: live' build/guard.err | head -2
