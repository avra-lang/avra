# Handoff — lane laws-fusion (2026-11-25 11:44)

## Goal
Lead's queue, in order: (a) map phase 1 on program d7cd84d9 + small-map build fix — DONE, pushed;
(b) derived `Eq`: `==` over every value whose parts compare, killing the hand-rolled `same_*` family
(the equality family), measured — HALF-DONE (this WIP); (c) the ONE NAME census — NOT STARTED.
Later rulings: interpolation calls `Show` (language change, own witness, eval == native); fold
std-ui `Words` into `Worded`; `trait_family` rule built with the first trait (done in this WIP).

## Tickets
avra-8sb5.104 (traits standardization; receiver-first cleanup filed under it by the Lead),
avra-8sb5.99 (Map/Set epic; set literal avra-8sb5.99.4). The tracker reachable from the sandbox lacks avra-8sb5 ids.

## Branches (GitHub avra-lang/avra)
- lane/laws-fusion/maps-phase1 @ 922be15a2b9665a5383acbe7274ecff12de5083c — finished, on gh/program e02d71ab
  (tested at d7cd84d9; not rebuilt at e02d71ab).
- lane/laws-fusion/fmt-parens @ 5ac8310b887e5a5f08aae5acf7d2c7088880b7cb — finished.
- lane/laws-fusion/traits-census @ 0dd54f1195752cc8202cc61f76022958a07b7332 — finished (docs).
- handoff/20261125-1144/laws-fusion — this WIP, ONE commit on top of lane/laws-fusion/maps-phase1
  (it needs phase 1's runtime and rows beneath it).

## Base
WIP sits on lane/laws-fusion/maps-phase1 (922be15a2), itself on gh/program e02d71ab.
Locally it was developed on 39f8e80e9 (phase 1 over d92250443 = program d7cd84d9).

## Done in the WIP
- Equality law: core `Shapes.compares_by_value` (core/checking.av: compared/enum_compared/record_compared)
  and features `TypeCx.compares_by_value` (features/checks.av): records, payload enums, lists of
  comparable parts; refuses a float inside a composite, fn/cell/map/task, and a type that holds itself.
  New message: "`==` compares by value — a value whose every part does: …".
- Lowering, type-directed inline: core/equality.av (same_value/same_list/same_variant/same_fields…),
  features/values.av. The runtime row avra_value_same was REMOVED (the mark walk was unsound).
- `compares_flat` (old law: scalar/text/unit enum/one-field record) in both layers, used where the old
  meaning matters: component prop cells (compiler/typing/declare.av, compiler/item_signatures.av),
  cached-fn contexts (compiler/item_context_reads.av), the match lowering's scalar path
  (features/enums/lowers.av, `cx.flat`). This fixed record/list patterns + destructuring let (10 lists tests).
- 37 structural same_* fns replaced by `==` (sweep scripts /work/rp/eqsweep/sweep*.py); ~50 others
  carry `// LICENSED compiler.trait_family: <the law>`.
- Rule compiler.trait_family (compiler/idioms.av) + `Code.fn_head`/`FnHead` (features/code.av);
  DOGFOODING registry block regenerated; docs/VOICES.md regenerated; CLAUDE.md equality line updated.
- Tests: new features/expr_spine/tests/derived_eq (eval == native == expected); spine_test, structs,
  lists, enums, bytes, subset refusals tests rewritten to the new law; refusal-witness cases
  compare_record/compare_list/compare_carrying_enum/contains_unvalued*/const_pattern_compares now
  prints.expected; compare_fn/compare_map re-pinned to the new wording.

## Verified BEFORE the compares_flat fix (last full run)
double build OK; make idioms clean; make witnesses OK; make voices OK (after regen);
suites: core 382/382, bytes 146/146, std-ui 1056, std-relation 349, std-text 208, std-grammar 56,
std-openapi 12; structs/nullable/std-http/std-program/compiler-tests/expr_spine/maps/features-tests
fail exactly the base compiler's tests (by name). lists had 10 record-pattern regressions + enums 3
old-law tests -> fixed/updated in this WIP but NOT re-verified.

## Half-done / NOT verified
The compares_flat fix + 4 updated tests (enums bare_compare, const_pat x2, lists named_scan) were
being rebuilt when the handoff stopped the run (killed). Nothing after it has been run.

## Next (exact)
cd <checkout of handoff branch>; AVRA_STD_ANSWERS=0 make avra && make avra
then: build/avra test packages/std-avrac/src/features/lists (expect only the base's 3 failures),
      features/enums, features/structs, features/expr_spine, std-ui, compiler/tests;
      make idioms; sh tools/witness_program_refusal.sh build/avra (expect 1173+ hold, 1 known);
      cost slice vs a control at the base (snapshot 91ebc6c5, tools/cost.sh, `--accept` control, `--judge` tip);
then squash the handoff commit into proper commits and push lane/laws-fusion/derived-eq.
Then (c) the ONE NAME census.

## Open questions
- remove_8 map row is VM-noisy (1.48–2.17× Go) — the Lead knows.
- DOGFOODING generated block was already stale on the base (loops.push_loop doc); the regen fixes it.

## Runs in flight
None (all stopped for the handoff).

## Rebase onto 922be15a2 (handoff time) — two conflicts resolved, NOT rebuilt
- docs/VOICES.md: took the WIP's generated copy; REGENERATE it on the new base (`./avra voices --report > docs/VOICES.md`).
- packages/std-relation/src/tests/shape_test.av: upstream added `a.name == d.name && a.scoped == d.scoped`;
  merged with the WIP's `a.slots[i] == d.slots[i]`. Upstream also added `same_reach` (and any remaining
  `same_slot` reference) — compiler.trait_family will flag new same_* there: convert to `==` or license.
- Run `make idioms` on the new base: program's new code since d7cd may hold more same_* fns the rule flags.
