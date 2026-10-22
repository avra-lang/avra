# Clone log of a cold cli `check`: the cloning sites grouped by return address, by count and by elements.
cd "$(dirname "$0")/../.."
S=build/alias
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.alias.$$.$i"
done
AVRA_ALIAS_LOG=1 ./avra check packages/cli 2> $S/log.txt > /dev/null; echo "cold check exit $?"
echo "lines: $(wc -l < $S/log.txt)"
echo "head:"; head -n 4 $S/log.txt | cut -c1-200
echo "top by count:"
awk '{for(i=1;i<=NF;i++) if ($i ~ /^0x[0-9a-f]+$/) {a=$i; break}; n=$NF; if (n ~ /^[0-9]+$/) {c[a]++; e[a]+=n}} END{for (k in c) print c[k], e[k], k}' $S/log.txt | sort -rn | head -n 10
echo "top by elements:"
awk '{for(i=1;i<=NF;i++) if ($i ~ /^0x[0-9a-f]+$/) {a=$i; break}; n=$NF; if (n ~ /^[0-9]+$/) {c[a]++; e[a]+=n}} END{for (k in c) print e[k], c[k], k}' $S/log.txt | sort -rn | head -n 10
echo "addr2line:"
for a in $(awk '{for(i=1;i<=NF;i++) if ($i ~ /^0x[0-9a-f]+$/) {print $i; break}}' $S/log.txt | sort | uniq -c | sort -rn | head -n 10 | awk '{print $2}'); do echo "$a $(addr2line -f -e build/avra $a | paste -sd' ' -)"; done
