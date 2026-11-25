wc -l build/w-head/diagnostics.txt; tail -n 3 build/w-head/diagnostics.err
echo "programs using |>: $(grep -l '|>' /tmp/nodes-corpus2/src/*/*.av | wc -l), table<: $(grep -l 'table<' /tmp/nodes-corpus2/src/*/*.av | wc -l), ~: $(grep -lE '~[a-z0-9(]' /tmp/nodes-corpus2/src/*/*.av | wc -l)"
grep -h "pipe's right side\|cells, and the header\|means \`" build/w-head/diagnostics.txt | head -5
