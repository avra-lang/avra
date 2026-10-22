# Reproduces the one-literal-edit refusal over a cold store, then rebuilds with the edit in place.
# Usage: sh tools/db_measure/pin_edit.sh <tag> [qtrace]   (qtrace: the first rebuild runs under AVRA_QTRACE=1)
cd "$(dirname "$0")/../.."
P=packages/cli
F=$P/src/commands/shared.av
T=${1:-pin}
clear_store() {
  i=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    i=$((i + 1)); mv "$d" "build/aside.$T.$1.$$.$i"
  done
}
build() {
  if [ "$2" = qtrace ]; then
    AVRA_QTRACE=1 ./avra build $P > build/$T.$1.out 2> build/$T.$1.err; echo "$1 exit $?"
  else
    ./avra build $P > build/$T.$1.out 2> build/$T.$1.err; echo "$1 exit $?"
  fi
  grep -h 'did not stabilize' build/$T.$1.out build/$T.$1.err | cut -c1-200
}
clear_store cold
build cold plain
cp $F build/$T.orig
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(text.replace("· memo", "· memo peakedit", 1))
PY
build edit1 "${2:-plain}"
[ "${2:-plain}" = qtrace ] || build edit2 plain
cp build/$T.orig $F
cmp -s build/$T.orig $F && echo "restored: $F"
