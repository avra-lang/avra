find /tmp/t2 -delete 2>/dev/null; mkdir -p /tmp/t2
tar cf - --exclude=./build --exclude=./.avra-cache . | (cd /tmp/t2 && tar xf -)
mkdir -p /tmp/t2/build && cp build/avra build/*.a build/*.o /tmp/t2/build/ 2>/dev/null
cd /tmp/t2 && git apply .typo/wip.diff && ./avra check packages/std-avrac 2>&1 | grep -B2 -A14 'error\[' | head -80
