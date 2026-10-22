cd /tmp
grep -E "^type:" before.out | awk '{n=$2; $1=$2=$3=""; print $0 "\t" n}' | sort > tb
grep -E "^type:" after.out | awk '{n=$2; $1=$2=$3=""; print $0 "\t" n}' | sort > ta
join -t "$(printf '\t')" -a1 -a2 -e0 -o 0,1.2,2.2 tb ta | awk -F'\t' '{d=$3-$2; if (d*d>10000000000) print d "\t" $0}' | sort -n | head -15
echo ---; join -t "$(printf '\t')" -a1 -a2 -e0 -o 0,1.2,2.2 tb ta | awk -F'\t' '{d=$3-$2; if (d*d>10000000000) print d "\t" $0}' | sort -n | tail -15
echo --- labels; grep -vE "^type:" after.out | grep -E "^[a-z]+:" | cut -d: -f1 | sort | uniq -c
