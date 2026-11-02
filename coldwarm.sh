# usage: sh coldwarm.sh <label> — a cold check of the cli equals a warm one, a comment edit's and a restored one's
B=build/avra-try; F=packages/cli/src/commands/shared.av
A="then the memo's hits and misses."; Z="then the memozz hits and misses."
find .avra-cache -mindepth 1 -delete
$B check packages/cli > /tmp/cw.cold 2>&1; c=$?
$B check packages/cli > /tmp/cw.warm 2>&1; w=$?
python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();p.write_text(s.replace(\"$A\",\"$Z\",1))"
$B check packages/cli > /tmp/cw.edit 2>&1; e=$?
python3 -c "import pathlib;p=pathlib.Path('$F');s=p.read_text();p.write_text(s.replace(\"$Z\",\"$A\",1))"
$B check packages/cli > /tmp/cw.back 2>&1; b=$?
same() { cmp -s /tmp/cw.cold $1 && echo same || echo "DIFFERS ($(diff /tmp/cw.cold $1 | wc -l) lines)"; }
echo "$1 cold==warm: exits $c/$w/$e/$b; warm $(same /tmp/cw.warm); comment edit $(same /tmp/cw.edit); restored $(same /tmp/cw.back); $(grep -ac '^warning' /tmp/cw.cold) warnings"
