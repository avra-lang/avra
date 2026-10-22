cd "$(dirname "$0")/../.." || exit 1
grep -n '^mem: peak' build/t168mem.log
grep -n '^mem: live' build/t168mem.log
echo "-- compiler category block (first 8) --"
grep -n '^mem:   [a-z]' build/t168mem.log | head -8
