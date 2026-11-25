# .195 follow-up: replay the empty_index sample on a small package.
cd "$(dirname "$0")/../.." || exit 1
n=0
find . -name .avra-cache -type d -prune | while read -r d; do
  n=$((n + 1))
  mv "$d" "build/aside.ei.$$.$n"
done
AVRA_RC_GUARD=1 AVRA_MEM_SITE=8dca1c AVRA_MEM_SITES=30 AVRA_MEM_STATS=1 \
  ./avra check packages/std-text > build/ei.out 2> build/ei.err
echo "exit $?"
echo "== the site (made count) =="
grep '^mem:   site' build/ei.err | head -8
echo "== the sample's life =="
grep -nE 'LEAK at site|retain from|release from|history truncated|RELEASED box' build/ei.err | head -60
