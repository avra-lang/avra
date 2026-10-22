export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
make bootstrap > /tmp/bs.log 2>&1; echo "bootstrap=$?"
make -o avra libs >/dev/null 2>&1
build/avra run packages/std-avrac/src/compiler/tests/zzdbg/zzdbg.av 2>/dev/null | grep -a RESULT
AVRA_QTRACE=1 build/avra test packages/std-meta > /tmp/meta.log 2>&1; echo "std-meta=$?"; grep -aE "Q.mint.*reader=[0-9]|avra:|tests passed" /tmp/meta.log | head -8
