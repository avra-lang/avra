export LLVM_PREFIX=/usr/lib/llvm-22
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
make bootstrap > /tmp/bs.log 2>&1; echo "bootstrap=$?"; grep -aE "bootstrap:|avra:" /tmp/bs.log | tail -3
