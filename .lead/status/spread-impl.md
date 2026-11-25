# spread-impl status

- #901 (spread-1): rebased onto origin/main, DIAGNOSTICS/VOICES regenerated (VOICES conflicted, retaken from main then regenerated), force-pushed with lease. Witnesses for all six record-spread voices in compiler/dev/witnesses.av.
- spread-2 (list spread, 83f05c2b, stacked): waits for #901 to merge; then `git rebase --onto origin/main spread-1 spread-2`, add a witness for type.spread_list, regenerate docs, open draft. Its commit adds list-spread syntax, so the pre-commit hook needs the new-syntax protocol (tell lead).
- #902 (spread-extend): landing 1 of avra_array_extend row, draft, nothing declares it. Landing 2 (arm + one-allocation lowering) after the seed refresh.
