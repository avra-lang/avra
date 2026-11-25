# Three cold `check packages/cli` runs timed in seconds; the first also writes the clone log.
cd "$(dirname "$0")/../.."
T=$1
S=build/wc/$T
mkdir -p $S
for i in 1 2 3; do
  j=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    j=$((j + 1)); mv "$d" "build/aside.wc.$T.$$.$i.$j"
  done
  s=$(date +%s)
  if [ $i = 1 ]; then AVRA_ALIAS_LOG=1 ./avra check packages/cli 2> $S/log.txt > /dev/null; else ./avra check packages/cli > /dev/null 2>&1; fi
  st=$?
  e=$(date +%s)
  echo "$T run $i exit $st wall $((e - s)) s"
done
