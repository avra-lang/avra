# Parity by law — 11-17 23:55 (owner: "2 + 3")
Split of 736 (fe40e0fe): A follow-on 68 (still counted), B real miss 433, C 235 (same-site 110, layer-only 86, run-only 39). File: scratchpad split/work/split-736.tsv, pushed to all parity lanes.
- values cghM2: type.lambda 42, variant_lit 25, unknown_prop 25, type.match 8, type.pattern 7
- types d5ubq: (after batch38 merge 5d9c28e0) type.mismatch 38, method 16, list_element 13, struct_fields 12; then Bytes parse, implements query
- resolve eq1wy: type.trait 15, resolve.unresolved 13, receiver 9, reserved 8, immutable 8
- wrong-answers dAmJ7: const loop via method, trap≠false refusal, then run-only 39
- NEW parity-words cse_01F8zAGb6X17dKV2D9r8jEAk: C same-site 110
- NEW parity-false-refusals cse_01F8zAGepj6T4XzLuFxZbJxS: C layer-only 86
Batch 38 = 63346623 on program-land-34 (../avra-ho-land), gating; batch 39 queue: par/parallel-main 12548d1a, UI 17b3819d1 2cf79133c, values type.lambda.
## 00:55 cold-build map (parallel-main, 3b9134bc): ~172 CPU-s per cold cli build
parse ~10, generators 39, bodies 80 (laws ~39, lowering ~30), main 11, placement 7.6, emit ~16, link 1.5, heir 7. One core: 1/3 allocation.
- RESUMED cold-sweep cse_01F8zAGd6gyKDsPnGPrFaqSE: all laws in one walk per item (39 → ≤10 CPU-s).
- RESUMED alloc cse_01F8zAGcBiofuCXAKtpTFRJ5: allocation third (arena, in-place rows, census).
- parallel-main: (b) laws read held typing; then generators wave breakdown. (a) laws-later REFUSED.
- NEW ui-language cse_01F8zAGduwLdaehWEhgee7MP: net steps aside + #5; 1-3 approved by UI lead; ctx 2nd pass; owner decides H2 (i)/(ii).
## 04:20 — ownership by kind (ONE lane per kind; check here before assigning)
- types d5ubq: type.mismatch (all), struct_fields? NO -> wrong
- wrong dAmJ7: struct_fields, variant_arity, type_value, type.unknown `_`, type.binding (const seat), run-only, small B tail
- resolve-2 cgp3B: resolve.*, type.method, list_element, dyn-implements law, map_value voice
- values cghM2: type.lambda, variant_lit, unknown_prop, type.pattern, type.match
- layer-commands 5uYv2: alias_copy, type.list, type.seat, spread, record_pattern ONLY
- words b6X17: C same-site; false-refusals epj6T: C layer-only, propagate/fail, cascades
Batch 40 (program-land-34 in ../avra-ho-land): d750dfa7 + traps pin + types t5 + cmds 0eb57719/b4c12ccd. Waiting: wrong const-seat direction, sweep idiom (item_entry repeated_unwrap), resolve-2 merge (maps voice).
- variant_arity -> resolve-2 (04:58)
- RULE 05:20: every parity bundle's receipts include (a) layer `check packages/std-avrac` exit 0, (b) the std-avrac suite's UNPINNED list empty (tools/gate.sh avrac-* slices, or a full test vs tools/gate/std-avrac.names). Batch 40 broke 10 slices from cases no lane ran.
- alloc 06:30: nullable pair layout PARKED on layout-pair-wip (−0.9% boxes; gen2 old-path lowering miscompiles with ids+FindingAt/Entry/Duration/CancelReach/ContentHash pairs: 'chain link without its stage', 'register rN defines out of mint order'). Next: HashKeyedTable runtime slots, then store-decode boxes (69 M).
- services stream (avra-84): branch services 457eb4d95 docs-only (SERVICES.md index) for batch 41; epic avra-8sb5.98
- 07:20 cold-sweep (FaqSE) ENDED (context). NEW laws-fusion cse_01F8zAGdaATzCsa4VkdD19eK from scratchpad cold-sweep-handoff.md + cold-sweep-final.bundle (4f2a30c7). parallel-main -> emit total work (LLVM phases).
- RULE 08:00: a gate red NOT from a lane's own commits is reported, never fixed by that lane; the lead routes it to ONE owner (duplicates seen: refused_once x2, self-seat x2, bounds x2, gathered-enum trap x2, map voice x2).
- layer-commands: + spread_nullable/missing/field, package kinds component_event 17, sealed 10. Unowned package kinds: annotation.said 9, plan_scan 8, plan_residual 8, not-made 17.
- values: + package kinds annotation.said 9, plan_scan 8, plan_residual 8. Values' singles parked.
- resolve-2: family empty -> package kinds resolve.not_exported 6, private_apart, import_clash, hole_bound 3, annotation.unread_mark 7. types: [].fold receiver voice.
- false-refusals: + package flow.* (end_arm 6, fresh_deadline 3, arm/never_ends/quiet_never) + quote_hole 6; verify one variant_lit mechanism vs values c15de25c.
- harness 10:45: ir_of on layer; 29 IR instruction gaps (layer emits worse: defer via closure box, chars() via list, const seat one body, map_set no probe) -> /work/ir-gaps.md -> a codegen lane later.
- 10:50 NEW lowering-quality cse_01F8zAGbRJMZ3mcmRep8NJWk: ir-gaps.md (31 rows; soundness #13 #25 #27 first, then H #1-5 #11-12, M #6-10 #23 #26 #28).
- 12:20 resolve-2: generated bodies are checked (layer typed no generator output = switch blocker); step 1 measure new findings by law across std pkgs.
- 13:40 parallel-main serial well dry (floor ~7s: walk 3.2, reached 1.3, hashes||refusals 1.3, emit tail 1.1) -> moved to TYPING total work (typed_fn/method_body_typed).
## 13:50 SWITCH TEST LIST: .lead/handoff/switch-old-path-files-2026-11-18.tsv (83 old_path spec files: 32 INTERNAL delete, 51 GUARANTEE port)
- harness: doors, kind1 (~230 portable), kind2 incremental (warm_agrees first), kind3 store safety, kind5 doors
- TO ROUTE: kind4 order-independence (cancel_scc, writes_scc, seal_order, cancel_reach, consumes, slot_names); kind6 other features (rule_fix/rule_proof = avra fix on layer; references/reexport_unused; error_sites; read_set/structural/pure_decl = UI repaint; unbroken; silent_cut; input_host; tree_root)
- RULE 14:20: cli suite receipts run with AVRA_BIN=build/avra-try (else tests spawn the tree's stale build/avra and regressions hide) — from ui-language.
- 14:25 defects: delete old-path cache-attacks; layer ones owned: docs_cache(stale!) > obj_gone > moved_tree > path_leak > closure_gather > store_bound > cancel_bits/cache.
- 15:35 false-refusals: package NOT-MADE 17, then collect_enum.trait 3, type.lacks 3, embed_literal, guard_value, language.defect. (annotation.meta 5 -> values later)
- services probe: after batch 50 lands, run models.txt (scratchpad/services-models.txt) on layer NET=0 vs old; expect unique_unstored x2, unique_repeats x2, unique_twice x1
- sugar backlog asks (services, 11-18): (1) fn TYPE seat names `fn(max: int)` (wanting: std-queue's record of fn verbs); (2) state "this Result cannot fail" at a top-level statement (~30 std-queue test sites gained `catch`); (3) component partial targs inferred from fields -> parity-types design post.
- batch 52 queue after resolve-2: warm/grain (06969a2e), par/p17 (323fe0a1, gate.sh conflict), fr (false-refusals batch51 rebase pending)
- batch 52 queue: fusion/f6 (a6d4fee8)
- batch 52 queue: ui/unread (de6acba4, ctx fn-value unread fix)
- batch 52 queue: lq/vt (643928aa static vtables)
- batch 53 queue: fr/f13 (36be5018)
- batch 53 queue: defects/b51 (8386d7a6 fix/--repair on layer)
- batch 53 queue: ui/r3 (3a9fae30 fn-value fix + R3 rung)
- batch 53 queue: values/v13 (c83c540d Field seats + std-db @unique model key; supersedes v12)
- batch 53 queue: types/t11 (3f5cfede, supersedes t10)
- batch 53 queue: lq/tags (50782690 dyn tag identity) — pull from lowering-quality /work/tags-50782690.bundle
- sugar asks (services Q3, 11-19): durable queue at file top level (ctx.db charged at lambda making); component reading its own instance name; @std.time hours(); `each: (d) -> .Ok(d.item)` at a component field = type.variant_lit false refusal; `limit -> Ran.Cut` in select arm can't pin T; generic method in impl; `r.await catch 0 - 1` on Task<Result> = layer "doesn't build this yet — Match at entry".
- batch 53 queue: fusion/f7 (437ac954 fold -12s)
- batch 53 queue: par/p18 (3c9e9862: leaf scalars, pack index, bodies_wave; drop abb3031b)
- batch 55 queue: ui A2 31c02d8aa (needs R4 builder)
- sugar/backlog (services Q4, 11-19): one seat taking Cron or Duration (impl on a specific instantiation Result<Cron,CronError> refused); component reading own instance name; nullable fn type spelling.
