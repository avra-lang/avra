cd /work/avra; . /etc/profile.d/avra.sh
for f in "$@"; do o=$(AVRA_PROGRAM=0 build/avra-try check $f 2>&1 | grep "^error\|^warning\|avra:"); n=$(AVRA_PROGRAM_NET=0 build/avra-try check $f 2>&1 | grep "^error\|^warning\|avra:"); if [ "$o" = "$n" ]; then echo "SAME $(basename $f): $o"; else echo "DIFF $(basename $f): $(head -c 200 $f | tr '\n' '~')"; echo "   old: $o"; echo "   new: $n"; fi; done
