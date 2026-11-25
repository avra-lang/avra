# Cold `check --time` then `build --time` of packages/cli, or the reverse with the first argument `build`.
cd "$(dirname "$0")/../.."
A=${1:-check}
B=build
[ "$A" = build ] && B=check
S=build/cb
mkdir -p $S
clear_store() {
  i=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    i=$((i + 1)); mv "$d" "build/aside.cb.$1.$$.$i"
  done
}
clear_store first
AVRA_QTRACE=1 ./avra $A --time packages/cli > $S/$A.out 2> $S/$A.err; echo "$A exit $?"
AVRA_QTRACE=1 ./avra $B --time packages/cli > $S/$B.out 2> $S/$B.err; echo "$B exit $?"
for t in $A $B; do echo "== $t"; grep -h "^time:\|held" $S/$t.out $S/$t.err | head -n 12; echo "attempts: $(grep -c -P '^Q\tattempt' $S/$t.err)"; grep -P '^Q\tattempt' $S/$t.err | head -n 8; done
