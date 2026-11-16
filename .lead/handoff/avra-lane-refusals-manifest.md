# avra-lane-refusals-manifest — hand-over
Branch avra-lane-refusals-manifest, merged with next-base abe09ce4 (the merge was resolved by hand in program_tested).
DONE: per-manifest kinds refuse on the program layer in the old path's voices (host/manifest.av manifest_read), at every door.
- compiler/item_manifests.av: manifest_judged(engine, pkg) is a saved query over source_text({pkg, avra.toml}); manifests_refused and manifests_voiced walk the deps rows in admission order (dev rows from the root only).
- tapes.av manifests_door(engine, disk): says every manifest's voices (warnings first, as the old path does) and exits 1 where one refuses. It is called in disk_built (build/run), in program_tested's per-root loop (test) and in check_program (check --baseline). program_erring and program_refused also return the refusing manifests (for made_program).
- 21 cases in tools/program-refusals/manifest_*: 19 refusals and 2 warning cases (unknown_key, unknown_section, prints.expected); 21/21 hold.
RECEIPTS: make try 0; AVRA_PROGRAM=1 build packages/cli 0, no manifest lines; WITNESS_ONLY=10 witness_program_edit (new edit: a line added to cli's avra.toml) warm == cold, taken back == cold.
KNOWN DIFFERENCE: where a manifest refuses, the old path also says the source errors after it; the door stops at the manifests. First line and exit are the same.
OPEN: borrowed_raw (its voice takes the dependency row's place, so it needs the graph) and unset_link_variable (it needs env as an engine input); both await the lead's call on whose they are. Graph kinds belong to whole-program.
