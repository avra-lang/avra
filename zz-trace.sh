echo "--- was the probe build ok? ---"; tail -4 zz-try.out
find .avra-cache -mindepth 1 -delete 2>/dev/null; true
AVRA_QTRACE=1 ./avra-try check packages/cli >/dev/null 2>zz-t-cold.txt; echo cold $?
AVRA_QTRACE=1 ./avra-try check packages/cli >/dev/null 2>zz-t-warm.txt; echo warm $?
sed -i 's/· memo/· memo zz9/' packages/cli/src/commands/shared.av
AVRA_QTRACE=1 ./avra-try check packages/cli >/dev/null 2>zz-t-edit.txt; echo edit $?
sed -i 's/· memo zz9/· memo/' packages/cli/src/commands/shared.av
for f in zz-t-cold zz-t-warm zz-t-edit; do
  echo "===== $f: $(grep -c '' $f.txt) lines"
  awk -F'\t' '{print $1" "$2" "$3}' $f.txt | sort | uniq -c | sort -rn | head -14
done
echo "===== edit: what expr.av / stmt.av did"
grep -a "core/stmt/stmt.av\|core/expr/expr.av" zz-t-edit.txt | awk -F'\t' '{print $1" "$2" "$3}' | sort | uniq -c | sort -rn | head -20
echo "===== edit: family hits/misses"
grep -a "store\tkind" zz-t-edit.txt | awk -F'\t' '{print $5" "$6" "$7}' | sort | uniq -c | sort -rn | head -25
echo "===== edit: first 12 non-store lines"
grep -av "store" zz-t-edit.txt | head -12 | cut -c1-160
