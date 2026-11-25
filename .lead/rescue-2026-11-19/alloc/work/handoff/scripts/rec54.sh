set -u
S=/tmp/claude-0/-home-user/b070374e-a97e-5ce7-b4c0-0401871fa94b/scratchpad/we
cd /work/cut45 && . /etc/profile.d/avra.sh && export AVRA_STORE_KEPT_HERE=1
cold() { for d in $(find packages tools -maxdepth 3 -name .avra-cache -type d) .avra-cache; do [ -d $d ] && find "$d" -mindepth 1 -delete; done; }
# CENSUS — base: batch53's census compiler, built from 53 by b53g2
git checkout -q --detach batch53 && cp build/keep-b53g2 build/avra
find build -maxdepth 1 -name avra.census -delete; find packages/cli/src -maxdepth 1 -name main -delete
cold; AVRA_CENSUS_TOP=400 AVRA_CENSUS_TYPES_TOP=400 CENSUS_CAP_MB=60000 AVRA_WORK_AHEAD_OFF=1 make census CMD="build packages/cli" > $S/c54_base.out 2>&1; echo "base census rc=$?"
cp build/census-raw.out $S/c54_base_raw.out; cp build/avra.census build/keep-census-b53
# after: HEAD's census compiler, built from HEAD by h2, run over 53's sources
git checkout -q alloc54 && cp build/keep-h2 build/avra
find build -maxdepth 1 -name avra.census -delete; find packages/cli/src -maxdepth 1 -name main -delete
cold; AVRA_CENSUS_TOP=400 AVRA_CENSUS_TYPES_TOP=400 CENSUS_CAP_MB=60000 AVRA_WORK_AHEAD_OFF=1 make census CMD="build packages/cli" > $S/c54_head_own.out 2>&1; echo "head census build rc=$?"
cp build/avra.census build/keep-census-a54
git checkout -q --detach batch53
cold; AVRA_PROGRAM_NET=0 AVRA_WORK_AHEAD_OFF=1 AVRA_CENSUS_TOP=400 AVRA_MEM_STATS=1 sh tools/memcap.sh 60000 build/keep-census-a54 build packages/cli 2>$S/c54_head_raw.out >/dev/null; echo "head census on 53 sources rc=$?"
# FINDINGS on 53's sources, each compiler cold
for c in keep-b53g2 keep-h2; do cold; for p in std-avrac std-program cli; do timeout 1500 build/$c check packages/$p > $S/f54_${c}_$p.out 2>&1; echo "$c $p rc=$?"; done; done
for p in std-avrac std-program cli; do cmp -s $S/f54_keep-b53g2_$p.out $S/f54_keep-h2_$p.out && echo "findings $p IDENTICAL" || echo "findings $p DIFFER"; done
git checkout -q alloc54; cp build/keep-h2 build/avra; make build/llvm_wrapper.o build/ffi.o > /dev/null 2>&1; make libs > /dev/null 2>&1
cold; timeout 2400 sh tools/witness_program_refusal.sh build/avra > $S/wit54.out 2>&1; echo "witness rc=$?"; tail -1 $S/wit54.out
cold; df -h / | tail -1
for sl in idioms-avrac idioms idioms-cli; do sh tools/gate.sh $sl batch53 > $S/i54_$sl.out 2>&1; tail -1 $S/i54_$sl.out; done
echo RECDONE
