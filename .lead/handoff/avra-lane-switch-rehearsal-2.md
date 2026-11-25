# avra-lane-switch-rehearsal-2 — why a new-path-built compiler is 25–30 % slower, and the emit level

Branch `avra-lane-switch-rehearsal-2` at **50594ec**, on trunk 763009d7. The bundle `program..50594ec` also
carries 9d68581 (the cores test on Linux, from the first rehearsal) and three merges of `program`.

## The cause

The new path emitted every object at level 0: `objects_owed` (packages/cli/src/commands/tapes.av)
called `handed(programs[i], [o], 0, "")`. At level 0, `object_written` (backend/llvm_wrapper.c) runs
no pass pipeline and links none of the hot leaves (rc_retain/release, array_get/len, slot_get…) in for inlining.
The old path emits at `opt_level(tools.opt)` = `-O1` (packages/std-avrac/src/compiler/build.av:790,
Toolchain built in packages/cli/src/commands/shared.av:583).

Evidence (baa28a8, one source, new-path product P2 vs old-path product O2):
- Call sites to the 11 hot leaves: 272,031 vs 51,854. rc_release 130,554 vs 23,295; array_get 41,469 vs 8,063;
  slot_get 39,922 vs 0; rc_retain 24,913 vs 2,598; array_len 10,404 vs 0.
- `edit_distance`: 6 calls to `avra_array_get` (the old product inlines them), and 86 vs 32 stack references.
- Census compilers, built by P2 from e8760228 with AVRA_FRAME_POINTERS=1 and AVRA_INLINE_RUNTIME=0, on cold
  `tapes cli --built`:

  | | old lowering | new lowering |
  |---|---|---|
  | user | 92.6 s | 98.8 s (+6.6 %) |
  | retains / releases | 1023.4 M / 1519.9 M | 811.4 M / 1319.4 M |
  | list reads / writes | 6669.6 M / 1831.4 M | 6629.3 M / 1870.1 M |
  | boxes | 511.2 M | 522.9 M |

  The new memory pass does LESS rc work. With runtime inlining off on both, the gap is 6.6 %, not 25–30 %.

## The change (50594ec)

- `opt_level` in compiler/build.av is exported. It is the one definition both paths use.
- `objects_owed` emits at `opt_level(asked.opt)`; at level > 0 the hot leaves come with it, as on the old path.
- The level is `BinaryAsked.opt`. It is an argument of `program_binary` (so it is in the build's question) and part of
  `objects_salt` (so objects at two levels never share a key).
- No option or env sets the old path's level: `toolchain()` fixes `-O1` native / `-Oz` wasm. So the level comes from
  a new env, `AVRA_PROGRAM_OPT` (a clang word: `-O0`…`-O3`, `-Oz`). It **defaults to `-O0`: no default changed.** The
  default-built product is byte-identical to the product of a compiler without the change (A0 == N0).
- avra-lane-emit-speed-3 will fold this into AVRA_PROGRAM_MODE.

## The 2×2 (trunk 763009d7, BEFORE emit-speed's parallel emit + lld)

Builder for both rows: S2 = an old-path `make try` of this tree. Package: cli, new path.

| | emit `-O0` (default) | `AVRA_PROGRAM_OPT=-O1` |
|---|---|---|
| cold build, wall / user / RSS | 78.7 s / 147.8 s / 4.71 GB | 109.4 s / 268.2 s / 4.98 GB |
| cold phases: emit / store saved / buckets made / link | 13.1 / 17.3 / 2.7 / 0.0 s | 135.4 / 15.9 / 2.5 / 0.1 s |
| warm one-literal edit (cache.av), wall / user / RSS | 4.65 s / 3.75 s / 0.94 GB (emit 0.2 s) | 7.76 s / 6.88 s / 0.99 GB (emit 3.6 s) |
| product size | 92,208,384 B | 93,777,544 B |
| product doing cold `tapes cli --built`, wall / user | 79.9 / 80.6 s | 68.1 / 68.3 s |
| product doing `test packages/std-program`, wall / user | 118.9 / 128.2 s | 95.6 / 105.5 s |

Reference, the old-path product S2 on the same jobs: `--built` 64.9 / 65.4 s; `std-program` 94.6 / 105.1 s.

So `-O1` closes the gap on std-program (105.5 vs 105.1 s user). On `--built` it leaves +4.5 % (68.3 vs 65.4 s); at
`-O0` that gap is +23 %. The price is +120 s user / +31 s wall on a cold build and +3.1 s on a one-literal warm edit
(the edited bucket's emit at -O1).

Phase seconds are the engine's `AVRA_QUERY_TIMES=1` phases. The emit workers' times are summed, so emit can
exceed wall.

Every product: `--built` 43569 of 43569 made. `test std-program` 401/402; the one failure is the read-only-directory
test, which cannot hold as root.

## Fixed point at -O1

A1 (S2, `-O1`) → A1b (A1, `-O1`) → A1c (A1b, `-O1`): A1b == A1c byte-identical (sha 4bc3c910…, 93,777,544 B).
Cold A1 → A1b: 114.3 s / 279.6 s / 5.00 GB; A1b → A1c: 108.8 s / 269.4 s / 5.02 GB.

## Gate (50594ec, standing compiler S2)

- `AVRA_PROGRAM=1 make try`: exit 0 (76.2 s wall / 143.5 s user / 4.71 GB).
- `sh tools/witness_program_edit.sh`: exit 0, every edit and take-back warm == cold (12 lines), 815 s.
- `check packages/cli --baseline tools/idioms.baseline`: exit 0.
- `check packages/std-avrac --baseline tools/idioms.baseline`: exit 1, `idioms: 3 NEW violation(s)`. All three are in files
  trunk 763009d brought, none in mine: packages/std-avrac/src/compiler/tests/code_hash_test.av
  [let_stmt.unmutated_mut] ×2 (`mut g = code_graph(…)`), packages/std-avrac/src/core/tests/reach_test.av
  [closures.pronoun_lambda] (`us.any((u) -> sets.of[u] > sets.of[v])`). Not fixed here.

## Next

- Re-run this 2×2 once emit-speed's parallel emit + lld are on trunk.
- Like-for-like by-site box diff: a third census compiler, new lowering at `-O1`. Comparing against an old-path build at
  `-O1` that inlines Avra fns blurs the old side's sites into their callers. This also sizes the residual +4.5 %.
- The `rules --json` / voices / docs / fmt --check / check family checklist.
