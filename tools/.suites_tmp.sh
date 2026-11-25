make cache-attacks-a 2>&1 | grep -av "^watch\|awk\|^cc " | tail -6 | cut -c1-400
echo "== all done"
