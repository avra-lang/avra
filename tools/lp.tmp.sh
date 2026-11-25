cd /home/sprite/avra-build/avra-whole-names/tree
build/avra check packages/std-avrac 2>&1 | grep -a "PROBE" | head -6 | cut -c1-300
