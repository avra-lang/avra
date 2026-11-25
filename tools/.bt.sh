export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
make bootstrap > /tmp/bs.log 2>&1; echo "bootstrap=$?"
AVRA_TRAP_BT=1 build/avra build packages/cli > /tmp/bt.log 2>&1; echo "gen1 cli=$?"
grep -aoE "\[0x[0-9a-f]+\]|\(\+0x[0-9a-f]+\)" /tmp/bt.log | head -40 > /tmp/addrs
grep -a "avra:" /tmp/bt.log | head -2
grep -aoE "\(\+0x[0-9a-f]+\)" /tmp/bt.log | tr -d '()+' | head -30 | /usr/lib/llvm-22/bin/llvm-symbolizer --obj=build/avra --functions=short 2>/dev/null | grep -v "^$" | grep -v "^??" | head -60
