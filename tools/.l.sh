export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
make bootstrap > /tmp/bs.log 2>&1; echo "bootstrap=$?"
mkdir -p /tmp/pr2; printf "extern fn avra_bytes_len(s: string) -> int\nprintln(\"\${avra_bytes_len(\"hi\")}\")\n" > /tmp/pr2/p.av
build/avra run /tmp/pr2/p.av 2>&1 | head -3
build/avra test packages/std-avrac/src/compiler/tests/bytes_adversarial_test.av 2>&1 | tail -2
