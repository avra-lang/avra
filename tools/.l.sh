export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
make bootstrap > /tmp/bs.log 2>&1; echo "bootstrap=$?"
make -o avra libs >/dev/null 2>&1
build/avra test packages/std-avrac > /tmp/l.log 2>&1; echo "std-avrac=$?"; grep -aE "undefined reference|clang failed" /tmp/l.log | head -2; grep -a "tests passed" /tmp/l.log | tail -1
