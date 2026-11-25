cd /Users/tristan/projects/tristanMatthias/avra-ho-c
export LLVM_PREFIX=/opt/homebrew/opt/llvm AVRA_MEM_CEILING_MB=9500 AVRA_MEM_POOL_WAIT_MS=420000 AVRA_CACHE_DIR=/Users/tristan/projects/tristanMatthias/avra-ho-c/build/machine-cache
T=build/avra-try
echo "built: $(timeout 590 $T tapes $PWD/packages/cli --built 2>&1 | grep -E '^built:')"
echo "ran: $(timeout 900 $T tapes $PWD/packages/std-avrac --ran 2>&1 | grep -E '^ran:' | cut -c1-140)"
echo "sig avrac: $(timeout 590 $T tapes $PWD/packages/std-avrac --signatures 2>&1 | grep -E '^tapes:|^differs' | cut -c1-110 | tr '\n' ' ')"
echo "sig program: $(timeout 590 $T tapes $PWD/packages/std-program --signatures 2>&1 | grep -E '^tapes:')"
echo "test program: $(timeout 590 $T test $PWD/packages/std-program 2>&1 | tail -1)"
AVRA_PROGRAM=1 timeout 590 $T build $PWD/packages/cli > /tmp/c5_self5.txt 2>&1; echo "self: exit $? $(grep 'program layer' /tmp/c5_self5.txt | cut -c1-120)"
find packages/cli/src/.main.print -delete 2>/dev/null
find /tmp/c5wit -mindepth 1 -delete; timeout 60 $T tapes /tmp/c5wit --law-witnesses > /dev/null
for d in /tmp/c5wit/*/; do d=${d%/}; timeout 120 $T tapes $d --findings > $d.new 2>/dev/null; timeout 120 $T check $d > $d.full 2>&1; python3 /tmp/c5gate3.py $d.full /tmp/c5_allkinds.txt > $d.old; cmp -s $d.new $d.old && echo "witness $(basename $d) same $(grep -c '^warning\|^error' $d.new)" || echo "WITNESS DIFFER $d"; done
for p in std-text std-program cli; do d=$PWD/packages/$p; timeout 590 $T tapes $d --findings > /tmp/c5z_$p.all 2>/dev/null; e1=$?; timeout 900 $T check $d > /tmp/c5z_$p.full 2>&1; e2=$?; python3 /tmp/c5gate3.py /tmp/c5z_$p.full /tmp/c5_allkinds.txt > /tmp/c5z.old; python3 /tmp/c5drop.py /tmp/c5z.old /packages/std-http/ > /tmp/c5z.old2; python3 /tmp/c5drop.py /tmp/c5z_$p.all /packages/std-http/ > /tmp/c5z.new2; cmp -s /tmp/c5z.new2 /tmp/c5z.old2 && r=IDENTICAL || r=DIFFER; echo "$p findings=$e1 check=$e2 $r $(grep -c '^warning\|^error' /tmp/c5z.new2)/$(grep -c '^warning\|^error' /tmp/c5z.old2) std-http-only-new=$(( $(grep -c '^warning\|^error' /tmp/c5z_$p.all) - $(grep -c '^warning\|^error' /tmp/c5z.new2) ))"; done
echo DONE1
# fixed point
AVRA_PROGRAM=1 timeout 590 build/avra-try build $PWD/packages/cli > /tmp/c5_fp1.txt 2>&1 && cp packages/cli/src/main build/avra-p2 && echo "P1->P2 ok" || echo "P1->P2 FAIL $(tail -1 /tmp/c5_fp1.txt)"
AVRA_PROGRAM=1 timeout 590 build/avra-p2 build $PWD/packages/cli > /tmp/c5_fp2.txt 2>&1 && cp packages/cli/src/main build/avra-p3 && echo "P2->P3 ok" || echo "P2->P3 FAIL $(tail -1 /tmp/c5_fp2.txt)"
timeout 590 build/avra-try check $PWD/packages/std-program > /tmp/c5_fp_p1.txt 2>&1; timeout 590 build/avra-p3 check $PWD/packages/std-program > /tmp/c5_fp_p3.txt 2>&1
grep -v "waiting for memory" /tmp/c5_fp_p1.txt > /tmp/c5_fp_p1b.txt; grep -v "waiting for memory" /tmp/c5_fp_p3.txt > /tmp/c5_fp_p3b.txt
cmp -s /tmp/c5_fp_p1b.txt /tmp/c5_fp_p3b.txt && echo "fixed point: P3 check std-program == P1 ($(wc -l < /tmp/c5_fp_p1b.txt) lines)" || echo "fixed point: DIFFER"
find build/avra-p2 build/avra-p3 packages/cli/src/.main.print -delete 2>/dev/null
find build/machine-cache -mindepth 1 -delete; find . -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \;
df -m /Users/tristan | tail -1 | awk '{print "free after cleanup: "$4" MB"}'
echo DONE2
