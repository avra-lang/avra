# L2 soundness backlog — the door's remaining 152

Base: `origin/main` @ `02cd6ad6` (carries #763). Lane tree `avra-l2backlog`,
Sprite `avra-phase-d`. Probed with the detailed renderer preserved at
`.lead/lanes/soundness-wip-preserved-by-nodes.patch` (leak message repainted
to `born[D]=… still alive at …=…`, plus a `calls:` line naming each `.Call`
reading the register and whether the checker's marks table knows the callee).

Command: `AVRA_SOUND_CHECK=1 build/avra test packages/std-avrac`
Result: STATUS 1, **152 `language.defect` = 142 "fresh box still alive" + 10
"released on one arm and not another"**. 0 use-after-release, 0 view.

## 1. Findings

Leak birth tag (of 142): 101 `.Call`, 27 `.CallRt`, 13 `.RegionEnd`, 1 `.Pack`.
Leak site tag: 103 `.FnExit`, 34 `.ScopeExit`, 5 `.ArmEnd`.
=> the shape is always "a fresh box minted before a conditional region is
still owned on the early-`return`/unwind arm that leaves the body".

By function (leaks): `compiler.Workspace.linked` 31, `manifest_objects` 14,
`tree_root` 10, `program_objects` 10, `keep_parts` 10, `settle_holds` 9,
`read_okey` 7, `compiler.said_of` 6, `refusal_noted` 4, `resolve_pending_reads`
3, `opened_store` 3, `keep_asks` 3, `keep_instances` 2, `keep_codes` 2,
`case_of` 2, `core.reach_of` 2, `core.flow_answer` 1, `stores_dir` 1,
`held_said` 1, `parts_moved_at` 1, `store.opened_at` 1, `Workspace.kept` 1,
`Workspace.checked` 1, plus `@std.grammar.*` 2 generics × 5 each.

By function (regions, 10): `@std.grammar.match_prim` 5 (all one instantiation
set, region `[5..341]`, `r1` a param, `SwitchStart`), `Workspace.stands_in` 2,
`Workspace.asked_print` 1, `Workspace.holding` 1, `Workspace.read_okey` 1.

## 2. Root cause — one root, not N

The probe's `calls:` line is decisive: across the 178 `.Call`s that read a
leaking register, **165 report `known=false`** — the checker's `by_name` map
does not contain the callee at all — and 13 report `known=true consumed=false`.
Only 165/178 is `known=false` because a few leaks have several callers.

The mechanism is written down in the pass's own comment and then contradicted
by its code:

- `compiler/lower/lower.av` mints a HELD callee as a **marks-only stub**
  (`weak`, no `ins`) precisely "so this lookup can still see its declared
  `consumed` seats" — `memory.av:50-59` says so.
- `memory.av:63` builds `by_name = marks_by_name(l.fns)` from the INPUT.
- `memory.av:64` `named = [b for b in l.fns if !(b.weak && b.ins.is_empty())]`
  drops exactly those stubs before the pass returns.
- `memory.av:76` then calls `checked(out, …)` — and `soundness.av:62`
  re-derives `by_name = marks_by_name(l.fns)` from the POST-FILTER `out.fns`,
  which no longer holds the stubs.

So the pass's map and the checker's map differ on every held callee. The pass
disowns a consumed-seat argument (correct transfer, no release on the exit
arm); the checker cannot see the `consumed` bit, never spends the argument's
born reference, and reports it leaked at the next `FnExit`/`ScopeExit`.

Worked example: `compiler.Workspace.keep_parts` `r3` (`module_path_of` result)
`born[2]`, passed to `key_parts_cached(r0,r1,r3,r2)` at seat 2, leaked at
`FnExit 23`. Probe: `compiler.Workspace.key_parts_cached known=false nmarks=0
consumed=false`. `key_parts_cached(store, m, path)` stores `m` into the
`KeyParts` it answers, so the seat IS consumed; the pass disowned `r3` (its
second region's `FnExit` releases `r10`/`r1` and not `r3`), and the checker
could not know. `manifest_objects r3` (`joined_path`) leaked at its early
`return []`: the pass emitted `Retain(r3)` for `there`'s consumed `path` seat
and `Release(r3)` at the exit, but the checker credited birth + retain and
missed the call's for `there` (`known=false`).

Held callees named by the probe (distinct, unknown to the checker):
`compiler.Workspace.there` 17, `key_parts_cached` 17, `@std.path.joined_path`
17, `program_host_fns` 16, `compiler.link_objects` 13,
`diagnostics.new_source_file` 11, `listed_text` 7, `core.ModulePath.text` 6,
`compiler.wire_number` 6, `@std.grammar.item` 6, `@std.grammar.join_expected` 5,
`@std.grammar.defect` 5, `core.module_path` 4, `core.concatenated` 3,
`compiler.store.store_with` 3, `segments_of` 3, `host.read_manifest` 3,
`mint_module` 3, `key_parts` 3, `asks_key` 3, `text_of_field` 2,
`Store.keep_reading` 2, `Store.keep_once` 2, `findings_read` 2, `codes_key` 2,
`callees_key` 2, `seen_key` 1, `@std.grammar.listed_grammar` 1.

This class is a CHECKER/OBSERVER gap, not (proven) a real leak: the pass used
the stub's marks. Whether the stub's `consumed` bits are themselves right is a
separate question — the 13 `known=true consumed=false` occurrences are where
the checker DOES see the marks and still disagrees.

Residue: 13 occurrences over <=13 leaks are `known=true` and still leak (e.g.
rows where the register's only consumer is a `.CallRt`; the probe's `calls:`
line only covers `.Call`). The 10 region disagreements are a separate class —
`r1` a param, 5× `SwitchStart` in `@std.grammar.match_prim`, 5× `IfStart` in
`derive.av`/`build.av`.

## 3. Sites, smallest change / largest yield first

1. `packages/std-avrac/src/compiler/soundness/soundness.av:62,218,227` +
   `packages/std-avrac/src/compiler/memory/memory.av:63,64,76` — feed the
   checker the SAME marks map the pass used. Either pass `by_name` into
   `checked` (new parameter) or have `checked` build it from the pre-filter
   list. One map, one door; no memory-pass rule changes. Yield ~129-139 of
   152. CLASS: memory-pass/observer gap (not a lowering bug).
2. `soundness.av:407-412` (`.Call` consumed-seat accounting), the
   `.CallRt` reusing-twin arm (`soundness.av:373`) and the `.CallRtVoid`
   moving-twin arm (`soundness.av:376`) — the 13 `consumed=false` residue.
   Probe which shapes (owned twins `avra_array_push_owned`/
   `avra_slot_set_owned`, `avra_str_split`, `avra_insist`) the checker
   mis-models before changing. CLASS: checker rule gap; may also expose a
   real pass leak.
3. `packages/std-avrac/src/compiler/derive.av` (`read_okey`, `asked_print`,
   `stands_in`, `holding`) and `packages/std-grammar/src/lexing.av`
   (`match_prim`) — the 10 region disagreements. CLASS: to be decided by a
   per-arm probe of each finding's `open[tag=…]` site; likely a genuine arm
   asymmetry (a region's `ArmEnd`/`RegionEnd` bracket) or the same marks gap
   surfacing in the merge.

## 4. Landing shape

Three PRs, one per class, each its own witness = the `AVRA_SOUND_CHECK=1`
count dropping by exactly that class:

- PR-1 (stub marks): expected 152 -> ~13-23 (all `known=false` leaks gone).
  Witness: `AVRA_SOUND_CHECK=1 build/avra test packages/std-avrac`; count
  `language.defect` == prior - (leaks whose `calls:` were all `known=false`).
  Also assert the checker still catches a SYNTHETIC consumed-seat leak (do not
  trade the false positive for a blind spot).
- PR-2 (residue + CallRt twins): expected -> ~10 (leaks only).
- PR-3 (regions): expected -> 0.

The door (#760) gates only after all three; it should gate on `language.defect`
count == 0, not on absence of the flag.

## 5. Receipts / re-run

- Probe: `.lead/lanes/soundness-wip-preserved-by-nodes.patch` + the `calls:`
  patch (this run); script `tools/_l2_4.sh` in `avra-l2backlog`.
- Full raw: `build/l2/l2_test.out` on `avra-phase-d` (5607 lines).
- Top line: `===TOTAL=152 LEAK=142 REGION=10`; `===CALLS` `165 false false /
  13 true false`.
- Unconfirmed by this lane: whether the 13 residue and 10 regions are real
  leaks or further observer gaps — do NOT assume they are false positives.
