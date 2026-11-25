set -u
S=/tmp/claude-0/-home-user/b070374e-a97e-5ce7-b4c0-0401871fa94b/scratchpad/we
cd /work/rung-wide && . /etc/profile.d/avra.sh && export AVRA_STORE_KEPT_HERE=1
git show alloc54:tools/gate.sh > $S/gate_unfixed.sh
holds() { d=$(mktemp -d); tar -xzf "$1" -C $d build/libavra_runtime.a 2>/dev/null; n=$(nm $d/build/libavra_runtime.a 2>/dev/null | grep -c " T avra_enum_boxed2"); find $d -delete; echo "$n"; }
stale() {
  git checkout -q --detach batch53 && make build/libavra_runtime.a > /dev/null 2>&1
  git checkout -q pack-fix && cp /work/cut45/build/keep-h2 build/avra
  sh tools/work built-from . > build/.avra-built-from
  find build/gate -maxdepth 1 -name 'compiler-*.tar.gz' -delete 2>/dev/null
  echo "  archive before the pack holds boxed2: $(nm build/libavra_runtime.a | grep -c ' T avra_enum_boxed2')"
}
echo "BEFORE (unfixed pack), after the checkout switch:"
stale; sh $S/gate_unfixed.sh pack > $S/packwit_before.out 2>&1; echo "  pack rc=$?"
echo "  packed archive holds boxed2: $(holds $(ls -t build/gate/compiler-*.tar.gz | head -1))"
echo "AFTER (fixed pack), the same switch:"
stale; sh tools/gate.sh pack > $S/packwit_after.out 2>&1; echo "  pack rc=$?"
echo "  packed archive holds boxed2: $(holds $(ls -t build/gate/compiler-*.tar.gz | head -1))"
echo PACKWITDONE
