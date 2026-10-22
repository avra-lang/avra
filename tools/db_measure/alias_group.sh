# Groups the clone log written by alias_log.sh: top sites by count and by elements, with addr2line.
cd "$(dirname "$0")/../.."
L=build/alias/log.txt
P=build/alias/parsed.txt
sed -E 's/^ALIAS_CLONE site=([^ ]+) kind=([0-9]+) n=([0-9]+).*/\1 \2 \3/' $L | awk 'NF==3' > $P
echo "parsed: $(wc -l < $P)"
echo "kinds:"; awk '{k[$2]++} END{for (x in k) print k[x], "kind", x}' $P
echo "top 10 by count (count elements site):"
awk '{c[$1]++; e[$1]+=$3} END{for (s in c) print c[s], e[s], s}' $P | sort -rn | head -n 10 | tee build/alias/by_count.txt
echo "top 10 by elements (elements count site):"
awk '{c[$1]++; e[$1]+=$3} END{for (s in c) print e[s], c[s], s}' $P | sort -rn | head -n 10 | tee build/alias/by_elems.txt
echo "addr2line:"
cat build/alias/by_count.txt build/alias/by_elems.txt | awk '{print $3}' | sort -u | while read -r a; do echo "$a $(addr2line -f -e build/avra $a | paste -sd' ' -)"; done
