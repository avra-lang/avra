# two clean builds of one small package under lld: byte-identical, with a build id
cd "$(dirname "$0")/../.."
D=$HOME/lld-witness-pkg; mkdir -p $D/src
printf '[package]\nname = "lldw"\nversion = "0.1.0"\n' > $D/avra.toml
printf 'println("lld witness")\n' > $D/src/main.av
for i in 1 2; do
  [ -d $D/.avra-cache ] && mv $D/.avra-cache $D/cache.$i.$$
  ./avra build $D > build/lldw.$i.out 2>&1; echo "build $i exit $?"
  cp $D/src/main $D/w.$i
done
cmp -s $D/w.1 $D/w.2 && echo "two clean builds: SAME ($(wc -c < $D/w.1) bytes)" || echo "two clean builds: DIFFER"
readelf -p .comment $D/w.1 2>/dev/null
readelf -n $D/w.1 2>/dev/null | grep -i "build id" | head -1
