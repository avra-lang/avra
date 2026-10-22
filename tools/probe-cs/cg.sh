cp /home/sprite/avra-compilers/$1/avra build/avra.main
P=/tmp/mt/packages/${2:-std-relation}
for who in avra.main avra; do
  rm -rf /tmp/mt/.avra-cache $P/.avra-cache .avra-cache
  s=$(date +%s); build/$who check $P >/dev/null 2>&1; echo "$who plain $(( $(date +%s) - s ))s"
done
for who in avra.main avra; do
  rm -rf /tmp/mt/.avra-cache $P/.avra-cache .avra-cache
  timeout 1500 valgrind --tool=callgrind --callgrind-out-file=/tmp/cg.$who build/$who check $P >/dev/null 2>/tmp/cg.$who.err
  tail -2 /tmp/cg.$who.err
  callgrind_annotate --inclusive=yes /tmp/cg.$who 2>/dev/null | grep -E "PROGRAM TOTALS|borrow_outlives|takes_twin|leaves_or_changes|memory_ins|held_below|cell_root|death_points|owned_form|read_outlives|aliased_write" | head -14
done
