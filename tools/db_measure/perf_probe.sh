#!/bin/sh
# ONE-EDIT CHECK, WALL AND COUNT. Usage:
#   sh tools/db_measure/perf_probe.sh <rounds> <pkg> <file> <literal> <label>
# Cold, two no-ops, then each round ONE body edit (the literal + a fresh
# stamp), timed whole and by the compiler's own phases. A separate round
# runs under AVRA_DB_GRAPH and counts the cells that SETTLE per family
# (Methods among them), so a wall win is attributable.
set -u
A=${AVRA_BIN:-build/avra}
R=${1:-3}
pkg=${2:-packages/cli}
file=${3:-packages/cli/src/commands/shared.av}
lit=${4:-' · memo ${p.cache}'}
label=${5:-edit}
out=${TMPDIR:-/tmp}/perf_probe.$$
now() { date +%s%N; }
# the families in the collect's own minted order (name order), index = ordinal
families="Admitted Analysis BlockScan CancelBits CancelSummary ComponentNames ComponentScan ConstTyped Consumed DeclReads Expanded Failures FileRefs Folded HeldSig Input Items LiftLowered Lifted Lowered Manifest Marks MethodDiags Methods Named Names Namespace Parsed Placed Plain Raised ReadFound ReadReach References Resolved Settled Sig Source Syntax Typed Visible WriteSummary Writes"
methods_ordinal=$(echo "$families" | tr ' ' '\n' | grep -n '^Methods$' | cut -d: -f1)
methods_ordinal=$((methods_ordinal - 1))

checked() {
    s=$(now)
    "$A" check --time "$pkg" > "$out" 2>&1
    st=$?
    e=$(now)
    printf '%s\twall_ms=%s\tstatus=%s\t%s\n' "$1" "$(((e - s) / 1000000))" "$st" "$(grep '^time:' "$out" | tail -n 1)"
}
graphed() {
    s=$(now)
    AVRA_DB_GRAPH=1 AVRA_QTRACE=1 "$A" check "$pkg" > "$out.g" 2>&1
    st=$?
    e=$(now)
    all=$(grep -c '^G	' "$out.g")
    m=$(grep -c "^G	[0-9]*	${methods_ordinal}	" "$out.g")
    built=$(grep -c '^M	' "$out.g")
    abandoned=$(grep '^M	' "$out.g" | cut -f2 | sort -n | uniq | wc -l | tr -d ' ')
    printf '%s\tgraph_ms=%s\tstatus=%s\tsettled=%s\tmethods_settled=%s\tmethods_built=%s\tmethods_distinct=%s\n' "$1" "$(((e - s) / 1000000))" "$st" "$all" "$m" "$built" "$abandoned"
    cp "$out.g" build/last_graph.txt
    grep '^C\t' "$out.g" | tail -n 3
    python3 - "$out.g" "$families" <<'PY'
import sys
from collections import Counter, defaultdict
path, names = sys.argv[1], sys.argv[2].split()
settled = Counter(); inputs = Counter(); abandoned = Counter(); args = defaultdict(set)
for line in open(path, encoding="utf-8", errors="replace"):
    p = line.rstrip("\n").split("\t")
    if p[0] == "G" and len(p) >= 4:
        fam = int(p[2]); settled[fam] += 1; args[fam].add(p[3])
    elif p[0] == "I":
        inputs[int(p[2])] += 1
    elif p[0] == "A":
        abandoned[int(p[2])] += 1
print("family\tsettled\tinputs\tabandoned\targs")
for fam, n in settled.most_common():
    name = names[fam] if fam < len(names) else str(fam)
    print(f"{name}\t{n}\t{inputs[fam]}\t{abandoned[fam]}\t{len(args[fam])}")
PY
}
edited() {
    python3 - "$file" "$lit" "$1$(now)" <<'PY'
import sys
path, lit, word = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
assert text.count(lit) == 1, (path, lit, text.count(lit))
open(path, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
}
cp "$file" "$out.orig"
find . -path '*/.avra-cache/*' -delete 2>/dev/null
find . -name .avra-cache -type d -delete 2>/dev/null
echo "probe	package=$pkg	file=$file	lit=$lit	methods_ordinal=$methods_ordinal	binary=$A"
checked cold
checked noop1
checked noop2
i=1
while [ "$i" -le "$R" ]; do
    edited "$label$i"
    checked "$label.edit$i"
    i=$((i + 1))
done
edited "$label-g1"
graphed "$label.graph1"
args1=$(grep "^G	[0-9]*	${methods_ordinal}	" "$out.g" | cut -f4 | sort -n | tr '\n' ' ')
edited "$label-g2"
graphed "$label.graph2"
args2=$(grep "^G	[0-9]*	${methods_ordinal}	" "$out.g" | cut -f4 | sort -n | tr '\n' ' ')
echo "methods_args1	$args1"
echo "methods_args2	$args2"
cp "$out.orig" "$file"
checked "$label.restored"
find . -path '*/.avra-cache/*' -delete 2>/dev/null
find . -name .avra-cache -type d -delete 2>/dev/null
find . -maxdepth 1 -name "$out*" -delete 2>/dev/null
