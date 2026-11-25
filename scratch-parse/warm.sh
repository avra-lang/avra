export AVRA_CWD=$PWD
find .avra-cache -delete 2>/dev/null
build/avra check packages/cli >/dev/null 2>&1
sh tools/warm_edit_bench.sh > build/warm-new.out 2>&1
find .avra-cache -delete 2>/dev/null
build/avra-base check packages/cli >/dev/null 2>&1
AVRA_SPEED_BIN=build/avra-base sh tools/warm_edit_bench.sh > build/warm-base.out 2>&1
echo ==NEW; cat build/warm-new.out; echo ==BASE; cat build/warm-base.out
