# peak of a cold build of packages/cli, then of a rebuild after ONE literal edit over the store it left.
# Each build runs under the watchdog, whose `watch: peak N MB` line is read back.
cd "$(dirname "$0")/../.."
P=packages/cli
F=$P/src/commands/shared.av
clear_store() {
  i=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    i=$((i + 1)); mv "$d" "build/aside.$1.$$.$i"
  done
}
timed() {
  sh tools/watch.sh 4000 ./avra build $P > build/peak.$1.out 2> build/peak.$1.err
  echo "$1: $(grep '^watch: peak' build/peak.$1.err)"
  grep -i held build/peak.$1.out | tail -n 2
  tail -n 4 build/peak.$1.out build/peak.$1.err
}
clear_store cold
timed cold
cp $F build/shared.orig
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo peakedit", 1))
PY
timed edit
cp build/shared.orig $F
cmp -s build/shared.orig $F && echo "restored: $F"
