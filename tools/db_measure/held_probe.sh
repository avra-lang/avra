#!/bin/bash
# a file held while what its compile-time run read moved: warm against cold, same final source
export AVRA_MEM_CEILING_MB=5000 LLVM_PREFIX=/usr/lib/llvm-22
make -s -o avra objects libs > /dev/null 2>&1
clear() { find . -name .avra-cache -type d -prune -exec rm -rf {} +; }
P=packages/cli; F=$P/src/commands/shared.av; cp $F /tmp/shared.orig
ed() { python3 - "$F" "$1" "$2" <<'PY'
import sys
p, old, new = sys.argv[1:4]; t = open(p).read(); assert t.count(old) >= 1, old; open(p, "w").write(t.replace(old, new, 1))
PY
}
line() { grep -a '^time:' $1 | grep -o 'held [0-9/]*, attempt [0-9]*, discarded [0-9]*'; }
readset() { sed -n '/^read:/,$p' $1 | grep -a -o 'commands/[a-z_]*\.av' | sort -u | tr '\n' ' '; }
shot() { # shot <label>: check, build, what the program says, the binary's print
    build/avra check --time $P > /tmp/chk_$1.txt 2>&1; echo "$1 check: exit $? $(line /tmp/chk_$1.txt)"
    echo "$1 check read, of commands/: $(readset /tmp/chk_$1.txt | cut -c1-400)"
    ./avra build $P > /tmp/bld_$1.txt 2>&1; echo "$1 build: exit $?"
    $P/src/main ir --help > /tmp/help_$1.txt 2>&1; $P/src/main expand --help >> /tmp/help_$1.txt 2>&1
    echo "$1 help mentions PROBE: $(grep -c PROBE /tmp/help_$1.txt)  binary $(shasum -a 256 $P/src/main | cut -c1-16)"
    grep -v '^time:\|discarded:\|^read:\|^  ' /tmp/chk_$1.txt > /tmp/diag_$1.txt
}
clear; build/avra check $P > /dev/null 2>&1; ./avra build $P > /dev/null 2>&1
ed '· memo' '· memo one'; build/avra check --time $P > /tmp/e1.txt 2>&1; echo "edit 1: $(line /tmp/e1.txt)"
ed '· memo one' '· memo two'; build/avra check --time $P > /tmp/e2.txt 2>&1; echo "edit 2: $(line /tmp/e2.txt); read of commands/: $(readset /tmp/e2.txt | cut -c1-300)"
ed 'description: "the source file"' 'description: "the source file PROBE"'
ed 'description: "print phase timings and memo hits"' 'description: "print phase timings and memo hits PROBE"'
shot warm
clear; shot cold
echo "diagnostics warm == cold: $(cmp -s /tmp/diag_warm.txt /tmp/diag_cold.txt && echo yes || echo NO)"
echo "help warm == cold: $(cmp -s /tmp/help_warm.txt /tmp/help_cold.txt && echo yes || echo NO)"
grep -a PROBE /tmp/help_warm.txt | head -3 | cut -c1-160
cp /tmp/shared.orig $F
echo FINISHED
