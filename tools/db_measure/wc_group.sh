# Clone sites of one wc_measure log, by count and by elements, resolved with addr2line.
cd "$(dirname "$0")/../.."
L=build/wc/$1/log.txt
P=build/wc/$1/parsed.txt
sed -E 's/^ALIAS_CLONE site=([^ ]+) kind=([0-9]+) n=([0-9]+).*/\1 \2 \3/' $L | awk 'NF==3' > $P
echo "parsed: $(wc -l < $P)"
echo "top 6 by count (count elements site):"
awk '{c[$1]++; e[$1]+=$3} END{for (s in c) print c[s], e[s], s}' $P | sort -rn | head -n 6 | tee build/wc/$1/by_count.txt
echo "top 6 by elements (elements count site):"
awk '{c[$1]++; e[$1]+=$3} END{for (s in c) print e[s], c[s], s}' $P | sort -rn | head -n 6 | tee build/wc/$1/by_elems.txt
cat build/wc/$1/by_count.txt build/wc/$1/by_elems.txt | awk '{print $3}' | sort -u | while read -r a; do echo "$a $(addr2line -f -e build/avra $a | paste -sd' ' -)"; done
