# lld on the host link: the one-leaf `make try`, the link's own time, which
# linker wrote the binary, and two clean builds of one program byte-identical.
cd "$(dirname "$0")/../.."
LEAF=packages/cli/src/commands/rules.av
make -s try >/dev/null 2>&1
for i in 1 2; do
  cp $LEAF build/leaf.keep; printf '\n// lld %s\n' "$(date +%s%N)" >> $LEAF
  t0=$(date +%s%N); make -s try >/dev/null 2>&1; echo "make try (one leaf edit): $(( ($(date +%s%N)-t0)/1000000 )) ms, $(grep -oE 'link [0-9]+ms' build/avra-try-build.out | tail -1)"
  cp build/leaf.keep $LEAF
done
echo "linker of build/avra-try: $(readelf -p .comment build/avra-try 2>/dev/null | grep -ioE 'linker: [a-z]+[^]]*' | head -1)"
D=$HOME/lld-witness; mkdir -p $D; printf 'println("lld witness")\n' > $D/w.av
for i in 1 2; do mv $D/.avra-cache $D/cache.$i.$$ 2>/dev/null; ./avra build $D/w.av >/dev/null 2>&1; cp $D/w $D/w.$i; done
cmp $D/w.1 $D/w.2 && echo "two clean builds: byte-identical ($(wc -c < $D/w.1) bytes)"; readelf -n $D/w.1 2>/dev/null | grep -i "build id" | head -1
