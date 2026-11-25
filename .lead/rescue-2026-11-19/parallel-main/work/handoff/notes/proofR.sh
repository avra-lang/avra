#!/bin/bash
# proofR.sh <tag> : proof of a change that moves the binary by design (release rows): the new
# compiler's binary held to ITSELF across every way of building, findings held to the base's, a
# self-rebuilt compiler held to a fixed point and run under the RC guard, then the suites and witnesses.
tag=$1; L=/work/lane/proof-$tag; mkdir -p $L; : > $L/summary
cd /work/avra && . /etc/profile.d/avra.sh
export AVRA_PROGRAM_NET=0
T=$PWD/build/avra-try; B=$PWD/build/avra-base
cold() { find . -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \; ; find ~/.avra/cache -mindepth 1 -delete 2>/dev/null; }
settle() { while pgrep -x avra-try >/dev/null || pgrep -x avra-base >/dev/null || pgrep -x cli1 >/dev/null || pgrep -x cli0 >/dev/null || pgrep -x cli2 >/dev/null; do sleep 0.3; done; }
findings() { grep -av '^core \|^ahead\|^time:\|^phases:\|^split:\|^kept by\|^within\|^beside' "$1" > "$2"; }
r() { echo "== $*" | tee -a $L/summary; }
same() { cmp packages/cli/src/main $L/try.rel && echo "CMP ok: $1" | tee -a $L/summary || echo "CMP FAIL: $1" | tee -a $L/summary; }
{
r "the new compiler's binary, held to itself"
cold; $B build packages/cli --release > $L/base.rel.log 2>&1; echo "base rel exit $?" | tee -a $L/summary; settle
cold; $B build packages/cli > $L/base.dev.log 2>&1; echo "base dev exit $?" | tee -a $L/summary; settle
cold; $T build packages/cli --release > $L/try.rel.log 2>&1; echo "try rel exit $?" | tee -a $L/summary; settle; cp packages/cli/src/main $L/try.rel
cold; AVRA_WORK_AHEAD_OFF=1 $T build packages/cli --release > $L/try.rel.off.log 2>&1; settle; same "ahead off, cold"
cold; $T build packages/cli > $L/try.dev.log 2>&1; echo "try dev exit $?" | tee -a $L/summary
$T build packages/cli --release > $L/try.rel.afterdev.log 2>&1; settle; same "ahead on, after dev"
for n in 1 2 3; do cold; AVRA_WORK_AHEAD_CORES=$n $T build packages/cli --release > $L/try.rel.c$n.log 2>&1; settle; same "$n core(s), cold"; done
cold; AVRA_WAVE_ALONE=1 $T build packages/cli --release > $L/try.rel.alone.log 2>&1; settle; same "wave alone, cold"
r "findings"
for k in rel dev; do findings $L/base.$k.log $L/base.$k.f; findings $L/try.$k.log $L/try.$k.f; cmp $L/base.$k.f $L/try.$k.f && echo "findings $k identical ($(wc -l < $L/try.$k.f) lines)" | tee -a $L/summary || echo "FINDINGS DIFFER $k" | tee -a $L/summary; done
findings $L/try.rel.off.log $L/try.rel.off.f; cmp $L/base.rel.f $L/try.rel.off.f && echo "findings rel off identical" | tee -a $L/summary || echo "FINDINGS DIFFER rel off" | tee -a $L/summary
r "fixed point"
cp $L/try.rel build/cli1; cold; build/cli1 build packages/cli --release > $L/cli1.rel.log 2>&1; echo "cli1 builds the cli: exit $?" | tee -a $L/summary; settle
cmp packages/cli/src/main $L/try.rel && echo "FIXED POINT ok: the cli built by the cli the new compiler built is that cli" | tee -a $L/summary || echo "FIXED POINT FAIL" | tee -a $L/summary
findings $L/cli1.rel.log $L/cli1.rel.f; cmp $L/base.rel.f $L/cli1.rel.f && echo "findings by cli1 identical" | tee -a $L/summary || echo "FINDINGS DIFFER by cli1" | tee -a $L/summary
r "the dev-built compiler builds the release cli"
cold; $T build packages/cli > $L/dev-for-cli0.log 2>&1; settle; cp packages/cli/src/main build/cli0; find /tmp/cli0layers -delete 2>/dev/null; cp -r packages/cli/.avra-cache/tapes-build/layers /tmp/cli0layers
cold; LD_LIBRARY_PATH=/tmp/cli0layers/overlay:$(ls -d /tmp/cli0layers/world-*) build/cli0 build packages/cli --release > $L/cli0.rel.log 2>&1; echo "dev-built cli builds the release cli: exit $?" | tee -a $L/summary; settle
cmp packages/cli/src/main $L/try.rel && echo "CMP ok: the release cli the dev-built cli made is the try compiler's" | tee -a $L/summary || echo "CMP FAIL: dev-built cli's release cli" | tee -a $L/summary
findings $L/cli0.rel.log $L/cli0.rel.f; cmp $L/base.rel.f $L/cli0.rel.f && echo "findings by the dev-built cli identical" | tee -a $L/summary || echo "FINDINGS DIFFER by the dev-built cli" | tee -a $L/summary
r "gen2 checks std-avrac cold"
cold; build/cli1 check packages/std-avrac > $L/gen2-check.log 2>&1; echo "release gen2 check std-avrac: exit $?, language.defect $(grep -ac 'language.defect' $L/gen2-check.log)" | tee -a $L/summary
cold; LD_LIBRARY_PATH=/tmp/cli0layers/overlay:$(ls -d /tmp/cli0layers/world-*) build/cli0 check packages/std-avrac > $L/gen2-dev-check.log 2>&1; echo "dev gen2 check std-avrac: exit $?, language.defect $(grep -ac 'language.defect' $L/gen2-dev-check.log)" | tee -a $L/summary
r "the self-built compiler under the RC guard"
find /tmp/guard-one -delete 2>/dev/null; mkdir -p /tmp/guard-one; cp packages/std-avrac/src/features/fns/tests/early_return/early_return.av /tmp/guard-one/
AVRA_RC_GUARD=1 AVRA_STORE_KEPT_HERE=1 build/cli1 build /tmp/guard-one/early_return.av > $L/guard-one.log 2>&1; echo "guarded cli1 builds a program: exit $? $(grep -aci 'released twice\|double\|guard' $L/guard-one.log) guard lines" | tee -a $L/summary
(cd /tmp/guard-one && AVRA_RC_GUARD=1 ./early_return > out 2>&1; echo "its run under the guard: exit $?"; diff -q out /work/avra/packages/std-avrac/src/features/fns/tests/early_return/early_return.expected && echo "output as expected") | tee -a $L/summary
r "every emitted fn verified"
cold; AVRA_VERIFY_LLVM=1 $T build packages/cli > $L/verified.log 2>&1; echo "verified dev build exit $? ($(grep -ac 'verification failed' $L/verified.log) failures)" | tee -a $L/summary; settle
r "guarded program tests (fns, defers, loops, results, nullable)"
sh /work/lane/guarded.sh $T $L/guarded-try.txt; sh /work/lane/guarded.sh $B $L/guarded-base.txt
echo "try: $(awk '{print $2}' $L/guarded-try.txt | sort | uniq -c | tr '\n' ' ') | base: $(awk '{print $2}' $L/guarded-base.txt | sort | uniq -c | tr '\n' ' ')" | tee -a $L/summary
diff <(awk '{print $1, $2}' $L/guarded-base.txt) <(awk '{print $1, $2}' $L/guarded-try.txt) > /dev/null && echo "guarded verdicts identical" | tee -a $L/summary || echo "GUARDED VERDICTS DIFFER" | tee -a $L/summary
r "suites and witnesses"
AVRA_STORE_KEPT_HERE=1 $T test packages/std-program > $L/std-program.log 2>&1; echo "std-program test exit $?: $(grep -a 'tests passed' $L/std-program.log | tail -1)" | tee -a $L/summary
sh tools/witness_program_runs.sh build/avra-try > $L/runs.log 2>&1; echo "witness_program_runs exit $?" | tee -a $L/summary; tail -3 $L/runs.log | tee -a $L/summary
AHEAD_ATTACK_AVRA=$T sh tools/ahead_edit_attack.sh 2>&1 | tail -2 | tee -a $L/summary
HEIR_ATTACK_AVRA=$T sh tools/heir_save_attack.sh 2>&1 | tail -2 | tee -a $L/summary
HELD_ATTACK_AVRA=$T sh tools/held_store_attack.sh 2>&1 | tail -2 | tee -a $L/summary
SHARE_ATTACK_AVRA=$T sh tools/share_merge_attack.sh 2>&1 | tail -2 | tee -a $L/summary
WAVE_ATTACK_AVRA=$T sh tools/wave_share_attack.sh 2>&1 | tail -2 | tee -a $L/summary
BESIDE_ATTACK_AVRA=$T sh tools/beside_attack.sh 2>&1 | tail -2 | tee -a $L/summary
r "a store an older compiler left, read by this one"
if [ -x "$OLD" ]; then
  cold; $OLD build packages/cli > $L/old-store.log 2>&1; settle; echo "old-format packs: $(ls packages/cli/.avra-cache/tapes/*.pack | while read f; do tail -c 8 $f; echo; done | sort | uniq -c | tr '\n' ' ')" | tee -a $L/summary
  $T build packages/cli --time > $L/over-old.log 2>&1; echo "this compiler over it: exit $?, $(grep -ac 'cache hit' $L/over-old.log) cache hit line(s)" | tee -a $L/summary; settle
  findings $L/over-old.log $L/over-old.f; findings $L/try.dev.log $L/try.dev.f; cmp $L/try.dev.f $L/over-old.f > /dev/null && echo "findings over the old store identical to a cold build's" | tee -a $L/summary || echo "FINDINGS DIFFER over the old store" | tee -a $L/summary
fi
LEVEL_ATTACK_AVRA=$T sh tools/level_mix_attack.sh 2>&1 | tail -3 | tee -a $L/summary
WITNESS_ONLY="embed infer composed 1 5 rename" sh tools/witness_program_edit.sh build/avra-try > $L/witness.log 2>&1; echo "witness subset exit $?" | tee -a $L/summary
WITNESS_ONLY=modes-whole sh tools/witness_program_edit.sh build/avra-try > $L/modes-whole.log 2>&1; echo "modes-whole exit $?" | tee -a $L/summary
WITNESS_ONLY=modes-layered sh tools/witness_program_edit.sh build/avra-try > $L/modes-layered.log 2>&1; echo "modes-layered exit $?" | tee -a $L/summary
git status --short | head -20 | tee -a $L/summary
echo PROOF-DONE | tee -a $L/summary
} > $L/out 2>&1
