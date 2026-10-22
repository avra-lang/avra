export LLVM_PREFIX=/usr/lib/llvm-22
good=$(ls -t /home/sprite/avra-compilers/*/avra 2>/dev/null | head -1); echo "seed: $good"; mkdir -p build; cp "$good" build/avra
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
for g in 1 2; do make avra > /tmp/all_g$g.log 2>&1 || { echo "gen$g FAILED"; grep -aE "avra:|^error|status" /tmp/all_g$g.log | head -5; exit 1; }; echo "gen$g ok"; done
make -o avra libs >/dev/null 2>&1
build/avra build packages/cli > /tmp/clib.log 2>&1 & pid=$!; peak=0; while kill -0 $pid 2>/dev/null; do v=$(awk '/VmHWM/{print $2}' /proc/$pid/status 2>/dev/null); [ -n "$v" ] && [ "$v" -gt "$peak" ] && peak=$v; sleep 1; done; wait $pid; echo "cli build=$? peak=$((peak/1024)) MB"
for p in packages/std-relation packages/std-avrac packages/cli; do build/avra test $p > /tmp/all_s.log 2>&1; echo "$p=$?"; grep -E "✗|avra:" /tmp/all_s.log | head -5; grep "tests passed" /tmp/all_s.log | tail -1; done
build/avra check packages/std-avrac --baseline tools/idioms.baseline > /tmp/all_id.log 2>&1; echo "idioms(std-avrac)=$?"; tail -2 /tmp/all_id.log
