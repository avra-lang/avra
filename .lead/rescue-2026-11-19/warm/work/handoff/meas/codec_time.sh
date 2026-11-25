# Cold `check packages/std-avrac` user time, base vs 0001+0002, alternating, two samples each.
cd /work/avra
R=/work/meas/ip/codec_time.txt; : > $R
cold() { find . -name .avra-cache -type d -prune -exec find {} -delete \; 2>/dev/null; }
one() { cold; /usr/bin/time -f "%U %e" -o /tmp/claude-0/-home-user/ad3c4af4-7a80-56a8-91c1-4dbb22fe5b6b/scratchpad/t.txt build/avra check packages/std-avrac >/dev/null 2>&1; echo "$1 rc=$? $(cat /tmp/claude-0/-home-user/ad3c4af4-7a80-56a8-91c1-4dbb22fe5b6b/scratchpad/t.txt)" >> $R; }
patch_on() { git apply /work/codec15p/0001-*.patch && git apply /work/codec15p/0002-*.patch; }
patch_off() { git checkout -- packages/std-relation; find packages/std-relation/src -name shape.av -newer /work/meas/ip/codec_time.sh -delete; find packages/std-relation/src/tests -name 'shape_test.av' -newer /work/meas/ip/codec_time.sh -delete; find packages/std-relation/src/tests -name 'storable_test.av' -newer /work/meas/ip/codec_time.sh -delete; }
for i in 1 2; do
  one base
  patch_on; one codec; patch_off
done
git status --short | head -5
cat $R
