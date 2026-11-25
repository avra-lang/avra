# nodes_probe.sh: each probe's check/ir/run output under base and head, compared
D=$(pwd)
P=/tmp/nodes-probes; find $P -delete 2>/dev/null; mkdir -p $P
for f in nodes_probes/*.av; do
  k=$(basename $f .av); mkdir -p $P/$k; cp $f $P/$k/$k.av; printf '[package]\nname = "probe"\nversion = "0.0.1"\n' > $P/$k/avra.toml
  for b in base head; do
    B=$D/build/avra; [ $b = base ] && B=$D/build/avra.base
    (cd $P/$k && { timeout 60 $B check $k.av; echo "check $?"; timeout 60 $B ir $k.av; echo "ir $?"; timeout 60 $B run $k.av; echo "run $?"; }) > $P/$k.$b 2>&1
  done
  if cmp -s $P/$k.base $P/$k.head; then echo "SAME $k"; else echo "DIFF $k"; diff $P/$k.base $P/$k.head | head -30; fi
done
echo ---; cat $P/bad_stage.head | head -12; cat $P/ok.head | tail -n 3
