# nodes-operators status

## Landed or batched
- `runs` fix (held file's runs survive a record rewrite) + witness + late-defect fix with db-warm's `names_stand`: branch `nodes-g3` (271b4480) on #1031's tip; warm-edit, attacks a+b, witness green.
- Dropped: 0590bb94 and beeb2af2 (regressed warm-edit counters), 5ff5ce97 (no gain on #1031's tip).

## Measurements (Sprite, cli build)
- Edit build on #1031's tip: 11-27 s, discarded 0, held 499/501. Main's base before it: ~64 s.
- Cold build 180 s: analyze 41, lower 34, keep 26-33, emit 35 (already parallel, ~6 of 8 cores), link 32 (the Sprite's disk: lld blocked in D state on a cold page cache; 0.5 s standalone).
- keep: all_said 10 (rule findings 6.8 of it over 501 files), interfaces 7.7, codes 3.4, const_units 2.3, instances 1.6, unit_rows 1.0, asks 0.4.

## Shelved
- Parallel rule findings: ~5-6 s of a 180 s cold build (3%), nothing warm; needs a new C fork-join row + two landings.
- CORES language check: no usable fan-out. `run(cores:)` only forks server cores that return two counters; `isolated` is a capture law. Ask filed: avra-8sb5.10.180 (cores.map).
- Parallel lower: shelved (14% cold, nothing warm, type-id risk).
