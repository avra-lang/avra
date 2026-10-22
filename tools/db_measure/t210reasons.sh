# .210: the read reasons the after-check build spoke, and the store's shape.
cd "$(dirname "$0")/../.." || exit 1
echo "== read reasons (after-check build)"
grep -h ' — ' build/t210bc/b1.err | sed 's/^.* — //' | sort | uniq -c | sort -rn | head -8
echo "== store shape (packages/cli)"
for d in packages/cli/.avra-cache .avra-cache; do
  [ -d "$d" ] && echo "$d: $(ls "$d" | head -3 | tr '\n' ' ')  dirs=$(ls -1 "$d" | wc -l)  o=$(find "$d" -name '*.o' 2>/dev/null | wc -l)  size=$(du -sh "$d" 2>/dev/null | cut -f1)"
done
echo "== b1 first read lines"
grep -h ' — ' build/t210bc/b1.err | head -4
