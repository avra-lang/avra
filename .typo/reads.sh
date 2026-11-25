AV=$PWD/build/avra-try
find /tmp/rdr -delete 2>/dev/null; mkdir -p /tmp/rdr; cp -r packages/std-http /tmp/rdr/p 2>/dev/null
AVRA_QTRACE=1 $AV check /tmp/rdr/p 2>/tmp/rdr/trace >/tmp/rdr/out; echo "check status=$?"; tail -2 /tmp/rdr/out | cut -c1-200
echo "-- Q reads per family: answers, total reads, max"
grep -a "^Q.reads" /tmp/rdr/trace | awk -F'\t' '{n[$3]++; s[$3]+=$4; if($4>m[$3])m[$3]=$4} END{for(f in n) print f, n[f], s[f], m[f]}'
echo "-- Sig and Items reads by family (summed)"
for F in Sig Items NameEnv; do echo "== $F"; grep -a "^Q.reads.$F" /tmp/rdr/trace | awk -F'\t' '{n=split($5,w," "); for(i=1;i<=n;i++){split(w[i],kv,":"); t[kv[1]]+=kv[2]}} END{for(k in t) print "  " k, t[k]}'; done
