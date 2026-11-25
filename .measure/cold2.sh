#!/bin/sh
find .avra-cache -mindepth 1 -delete 2>/dev/null
AVRA_QTRACE=1 ./build/avra check --time packages/cli > /dev/null 2> .measure/cold.err
grep '^time:' .measure/cold.err | grep -o 'keep [0-9]*ms'
echo "rev runs rows us — top 15 by us"
grep 'Q	store	sealed' .measure/cold.err | awk -F'\t' '{print $4, $5, $6, $7}' | sort -k4 -n -r | head -15
echo "histogram of us (<1ms,<5ms,<20ms,<100ms,more)"
grep 'Q	store	sealed' .measure/cold.err | awk -F'\t' '{u=$7+0; if(u<1000)a++; else if(u<5000)b++; else if(u<20000)c++; else if(u<100000)d++; else e++; t[ (u<1000)?0:(u<5000)?1:(u<20000)?2:(u<100000)?3:4 ]+=u} END{print a,b,c,d,e; for(i=0;i<5;i++)print i,t[i]}'
