# usage: sh memo_bench.sh <label> — build/avra-try on a cleared store: warm check, then a comment edit, timed thrice
B=build/avra-try; F=packages/cli/src/commands/shared.av
A="then the memo's hits and misses."; Z="then the memozz hits and misses."
find .avra-cache -mindepth 1 -delete
$B check packages/cli > /dev/null 2>&1; $B check packages/cli > /dev/null 2>&1
for i in 1 2 3; do
  s=$(date +%s%N); $B check packages/cli > /dev/null 2>&1; e=$(date +%s%N); w=$(( (e-s)/1000000 ))
  python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();a,z=\"$A\",\"$Z\";p.write_text(s.replace(a,z,1) if a in s else s.replace(z,a,1))"
  s=$(date +%s%N); $B check packages/cli > /dev/null 2>&1; e=$(date +%s%N); echo "$1 run $i: warm ${w} ms, comment edit $(( (e-s)/1000000 )) ms"
done
python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();p.write_text(s.replace(\"$Z\",\"$A\",1))"
