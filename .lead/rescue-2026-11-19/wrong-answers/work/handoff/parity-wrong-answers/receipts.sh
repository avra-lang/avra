cd /work/avra && . /etc/profile.d/avra.sh
make try > /tmp/rc-try.log 2>&1; echo "try $?"
AVRA_MEM_POOL_MB=12500 build/avra-try check packages/std-avrac > /tmp/rc-check.log 2>&1; echo "check $?"
AVRA_MEM_POOL_MB=12500 build/avra-try check packages/std-avrac --baseline tools/idioms.baseline > /tmp/rc-idioms.log 2>&1; echo "idioms $? $(grep -c NEW /tmp/rc-idioms.log)"
for s in avrac-a avrac-b avrac-c avrac-d avrac-e avrac-f avrac-g refusal-a refusal-b refusal-c; do sh tools/gate.sh $s > /tmp/rc-$s.log 2>&1; echo "$s $? $(tail -1 /tmp/rc-$s.log | cut -c1-100)"; done
echo DONE
