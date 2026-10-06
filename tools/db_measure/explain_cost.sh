#!/bin/sh
# What each explain form costs over packages/cli beside the two checks it is
# made of: a check from an empty store and one from a full store. Each line is
# wall and peak; each form's largest allocation sites follow, named.
set -u
out=build/explain_measure
mkdir -p "$out"
aside="$out/aside.$$"
mkdir -p "$aside"
n=0
for store in .avra-cache packages/cli/.avra-cache; do
    if [ -d "$store" ]; then
        n=$((n + 1))
        mv "$store" "$aside/$n"
    fi
done
echo "stores set aside: $n"
one() {
    name=$1
    shift
    AVRA_MEM_STATS=1 python3 -c '
import resource, subprocess, sys, time
began = time.time()
status = subprocess.call(sys.argv[1:])
peak = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
print("status %d, wall %.1f s, peak %d MB" % (status, time.time() - began, peak // 1024), file=sys.stderr)
' build/avra "$@" >"$out/$name.out" 2>"$out/$name.err"
    echo "== $name: $(tail -1 "$out/$name.err"), $(wc -l <"$out/$name.out") lines out =="
    python3 tools/memsites.py build/avra "$out/$name.err" | grep -E "mem: peak|list boxes|list buffers|strings|site " | head -18
}
one check_empty_store check packages/cli
one check_full_store check packages/cli
one why explain --why packages/cli
one stats explain --stats packages/cli
one file explain packages/cli/src/main.av
one why_held_file explain packages/cli/src/main.av --why
