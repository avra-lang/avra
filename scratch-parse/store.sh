export AVRA_CWD=$PWD
for b in avra-base avra; do
  find .avra-cache -delete 2>/dev/null
  build/$b check packages/cli >/dev/null 2>&1
  echo "== $b total $(du -sb .avra-cache/store | cut -f1)"
  ls .avra-cache/store | head -3
  find .avra-cache/store -type f | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -8
  find .avra-cache/store -type f -size +300k -exec ls -la {} \; | awk '{print $5, $9}' | sort -rn | head -8
done
