[ -d .avra-cache ] && mv .avra-cache .avra-cache.old.$(date +%s)
./avra build packages/cli > /dev/null 2>&1 &
b=$!
t0=$(date +%s)
while kill -0 $b 2>/dev/null; do
  sleep 4
  echo "t=$(( $(date +%s) - t0 )) $(ps -eo pid,pcpu,rss,stat,comm --sort=-pcpu | sed -n '2,5p' | tr -s ' ' | tr '\n' '|') mem $(free -m | awk '/Mem/{print $3"/"$2" avail "$7}') $(ps -C ld.lld,clang -o pid,etime,time,stat,wchan:20 --no-headers | tr -s ' ' | tr '\n' '|')"
done
