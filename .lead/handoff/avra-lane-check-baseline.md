# avra-lane-check-baseline — hand-over
Branch avra-lane-check-baseline-8, on next-base abe09ce4. Bundle /work/avra-lane-check-baseline-8.bundle.
DONE: plain `check <dir|file>`, `check --baseline`, `--baseline_accept` answer from the program layer
(check.av, check_program.av; rule findings saved as KeptDiag in item_rules.av, old walk order).
Fact rules read a program file's running statements as its entry (entry_fact_found; TypedFacts.entry).
Receipts on abe09ce4: std-text, std-relation, std-http `check` byte-identical old vs new; cli self-build
49901/49901; doors witness green; refusal suite 360/376 (6 failing = unpinned jump_* cases of base).
unmutated_mut on std-avrac = old sites, minus 2 old false positives (fn_seats:28, trait_defaults:61, both
baselined), plus 8 table gaps: dyn receivers (dyn_written x3, static_receiver:69, borrow_dyn:20,27 — routed
to ui-build). Named types over a shape: closed in item_writes.av shape_evidence.
Known not identical: type.coalesce_never has no program-layer law (old typing only).
Next: unused_import false negative — file_reads reads value names syntactically (local `items` shadows).
Mine: check.av, check_program.av, idiom_baseline.av, item_rules.av, rule_pass.av.
