set -u
S=/tmp/claude-0/-home-user/b070374e-a97e-5ce7-b4c0-0401871fa94b/scratchpad/we
cd /work/cut45 && . /etc/profile.d/avra.sh && export AVRA_STORE_KEPT_HERE=1
cold() { for d in $(find packages tools -maxdepth 3 -name .avra-cache -type d) .avra-cache; do [ -d $d ] && find "$d" -mindepth 1 -delete; done; }
cp build/keep-h2 build/avra
make build/libavra_runtime.a build/llvm_wrapper.o build/ffi.o > $S/g54_objs.out 2>&1; echo "objects rc=$?"
nm build/libavra_runtime.a 2>/dev/null | grep -c " T avra_enum_boxed2" | sed 's/^/archive holds boxed2: /'
find build/gate -maxdepth 1 -name 'compiler-*.tar.gz' -delete
cold; sh tools/gate.sh seed > $S/g54_seed.out 2>&1; echo "seed rc=$?"; tail -1 $S/g54_seed.out
pack=$(ls -t build/gate/compiler-b6381f9a*.tar.gz 2>/dev/null | head -1); echo "pack=$pack"
for slice in program build avrac-a avrac-b avrac-c avrac-d avrac-e avrac-f avrac-g cli; do
  cold; [ -n "$pack" ] && sh tools/gate.sh unpack "$pack" > /dev/null 2>&1
  sh tools/gate.sh $slice > $S/g54_$slice.out 2>&1
  tail -1 $S/g54_$slice.out
  df -h / | tail -1 | awk '{print "disk avail " $4}'
done
echo GATEDONE
