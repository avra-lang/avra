# Shape-memo reference: a COLD build of packages/cli, keep phase.
cd "$(dirname "$0")/../.." || exit 1
n=0
find . -name .avra-cache -type d -prune | while read -r d; do
  n=$((n + 1))
  mv "$d" "build/aside.mref.$$.$n"
done
./avra build --time packages/cli > build/mref.log 2>&1
echo "exit $?"
grep -h "^time:" build/mref.log | tail -1
echo "compiler link: $(readelf -p .comment build/avra 2>/dev/null | grep -io 'Linker: [^]]*' | head -1)"
