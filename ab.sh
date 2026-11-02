# usage: sh ab.sh <label> — micro and package medians for build/avra-try, on its own store
./build/avra-try build bench_ask > /tmp/ba.out 2>&1 || { echo "$1 bench build failed"; grep -a "^error" -A4 /tmp/ba.out | head; }
for i in 1 2 3; do ./bench_ask/src/main | tr '\n' ' '; echo; done | sed "s/^/$1 micro: /"
B=build/avra-try; F=packages/cli/src/commands/shared.av
A="then the memo's hits and misses."; Z="then the memozz hits and misses."
find .avra-cache -mindepth 1 -delete
$B check packages/cli > /dev/null 2>&1; $B check packages/cli > /dev/null 2>&1
w=""; c=""
for i in 1 2 3 4 5; do
  s=$(date +%s%N); $B check packages/cli > /dev/null 2>&1; e=$(date +%s%N); w="$w $(( (e-s)/1000000 ))"
  python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();a,z=\"$A\",\"$Z\";p.write_text(s.replace(a,z,1) if a in s else s.replace(z,a,1))"
  s=$(date +%s%N); $B check packages/cli > /dev/null 2>&1; e=$(date +%s%N); c="$c $(( (e-s)/1000000 ))"
done
python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();p.write_text(s.replace(\"$Z\",\"$A\",1))"
med() { echo $* | tr ' ' '\n' | sort -n | sed -n 3p; }
echo "$1 warm ms:$w median $(med $w); comment edit ms:$c median $(med $c)"
