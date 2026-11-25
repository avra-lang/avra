#!/bin/sh
. /etc/profile.d/avra.sh
unset AVRA_PROGRAM AVRA_PROGRAM_MODE AVRA_WORK_AHEAD_OFF AVRA_QTRACE
O=/work/meas/wc/pH; mkdir -p $O
cd /work/wt-t
A=/work/wt-t/build/avra-e3
s=$(date +%s); sh tools/witness_program_edit.sh $A > $O/edit.out 2>&1; echo "rc=$? $(( $(date +%s)-s ))s" >> $O/edit.out
echo done > $O/done
