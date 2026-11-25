# Steps red on BOTH paths (c2daa608 + avra-lane-unpin-2, measured 2026-11-17/18)

The pin cannot help these. Before the switch each one is fixed, or deleted together with
its old-path subject.

| Step | Unpinned (program layer) | Pinned (old path) | Subject / likely fate |
|---|---|---|---|
| census-gate | FIXED 06e5f4f9: releases 127098 ≤ ceiling; budget lowered to the layer | — | done |
| warm-edit | FIXED 765f9a82 241ac75b 80850baa d3d3a7a3 2133000b: net off, unchanged 111 ms, edit 489 ms; 22 counters held | — | open: first edit after a settled run works 1545 queries / 18 files, later ones 421 / 3 |
| read-cost | FIXED 5a9cb139: census runtime + bench keep frame pointers (box_alloc walked 2 frames up) | — | done |
| read-lists | FIXED e6cba0e6 386a6e78: on the layer (check --read-lists); 8 hubs accepted as debt (Lead) | — | warm lane splits them |
| leaves | DELETED eff400f2 with the old derivation | — | done |
| cache-attacks-a | DELETED 1b3453f2 (12 old-path scripts, reason per script) | — | done |
| cache-attacks-b1 | FIXED: docs_cache ff7ff20a, obj_gone 930c5a81, moved_tree 4f2dd5dd, closure_gather 8796b38f, store_bound 8afbc30c (gate rows, witness-b); path_leak 5→2 leaks/checkout (store rows: ruling asked) | — | cancel_bits/cancel_cache: old explain words, ruling asked |
| cache-attacks-b2 | expanded/held attacks deleted with a (1b3453f2) | — | done |
| code-hash-attacks | rename case ×6: attack expects a read-back, law (summed_hash) says recompute | same | decide the law; fix the attack or the law |
| seed-check | the committed seed can't read HEAD (type.host_seat on avra_cell_bytes_word) | same | refresh the seed (cadence) |
| flow-gate | c_gate_round_trip 3.00x vs baseline (gate 2.0x) | same | machine baseline: accept on the CI machine |
| inputs | FIXED 02c88f8b: std-program in scope (source_facts a door), 132 sites licensed by reason | — | done |
| whole-reads | FIXED e8889331: baseline 7→5, old-path sites licensed whole.cold | — | done |
| trap-marks | FIXED ab269bbf | — | done |
| db-corpus | 3 FAIL "the edit changed nothing the corpus can see" (dependency doc / same-name decl in new file / removed) | same on batch39 | batch39's own (Lead: leave) |
| wasm-tasks-mutations | two C mutations "do not build" here | same | this sandbox's WASI sysroot; CI image builds them |
| cli suite: explain ×17 | explain over a layer check's store | 17 too | `explain` is old-path-only (Workspace, cache_walk): give it a layer form or delete it |
| std-http / std-net / std-program suites | 1 / 6 / 1 cases (loopback, IPv6, root writes) | same | sandbox environment (pinned names in tools/gate) |

Pinned on its own step (needs the old path): std-avrac's suite (checks.yml/orders.yml suites loop) —
its spec harness checks through the old Workspace; unpinned: decl_grain_test red, alias_copy_adversarial
red under AVRA_SOUND_CHECK.
