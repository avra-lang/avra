sh nodes_round.sh "$@"
./avra diagnostics > build/DIAG.gen 2>/dev/null; cmp build/DIAG.gen docs/DIAGNOSTICS.md || diff docs/DIAGNOSTICS.md build/DIAG.gen > build/DIAG.diff; echo "DIAGDIFF $(wc -l < build/DIAG.diff)"
./avra voices --baseline tools/voices.baseline 2>&1 | tail -n 3; ./avra voices --report > build/VOICES.gen; diff docs/VOICES.md build/VOICES.gen
