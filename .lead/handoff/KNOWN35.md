# The 35 known-to-differ — triage (read only, on f62f0f88's avra-try)

Every case was run cold on both paths (old `check`, layer `build` NET=0), and each diff was read beside its `differs.why`.
Verdicts: **L** = the layer is right, so it becomes a plain layer case at deletion · **F** = the layer must change · **R** = a ruling is needed · **S** = stale pin: both paths already agree, and only the expectation is old.

**Totals: L 28 · F 2 · R 5 · S 2** (two cases carry two verdicts, so the total is 37. `generator_reaches_world` is L+F and `w_annotation_unplaceable` is R→L.)

## values / annotations — mine (avra-lane-parity-values)
| case | verdict | note |
|---|---|---|
| body_const_budget, const_over_budget, w_const_default_steps | L | the help names the declaring package's avra.toml, where the old path says "the package manifest" (ruling (c)) |
| w_dependency_const_budget_is_its_own | L | ruling (c): a dependency's const is held to its own `[lifted]`; the old path accepts under the root's |
| validator_handed_what_does_not_cross_is_an_error, validator_past_its_budget_is_an_error, validator_that_traps_is_an_error | L | the old path exits 0 silently; the layer refuses as annotation.unsettled |
| builds_annotation_crossing_whole | L | places are item-relative (`main.av#1:55-141`), while the old path hands file offsets. Also the old path says a fns.dead_parameter warning |
| w_annotation_unplaceable | R→L | recommend L: the layer places it at the `@derive` and names the template `@x/c:src/c.av`; the old one places it in the provider's file with a raw disk path and offset (`c.av:545`) |
| generator_reaches_world | **F** (small, mine) + L | the layer's label spells the fn `@std/prelude/src/prelude.av.println`, and it should say `@std.prelude.println` as the old path does. The old path's extra `resolve.unresolved` (`one_stamped`, a twin never made) is a follow-on of the refused annotation, so the layer's silence is L. The differs.why says the reverse of today's output, so I'll rewrite it |

## types
| case | verdict | note |
|---|---|---|
| pw_generic_literal_argument, pw_rest_spread_element | L | ruled: the layer points at the field or element that is wrong |
| spread_generic_seat, spread_missing_cascade | L | ruled |
| sibling_pin_coalesce, sibling_pin_if, sibling_pin_match | L | ruled: a sibling arm pins T, and the layer accepts |
| w_variant_lit_branch | L | ruled: one rule across if/match/when/?? |
| shown_typed_empty_list | L | the old path types a declared `List<int>` as its value `[]` and refuses the answer (lower.no_projection); the layer prints `[]` |
| pw_task_escape_owner | L | ruling R2 |
| pw_lambda_seats_after_parse | L | ruled: a follow-on after a parse error |
| pw_collect_element | **F** (small, types) | same kind, message and place. The layer says the generic `make the value string…`, where the old path says `text is made by interpolation, never by conversion` with the `"${1}"` fix. Fix: the layer's list-element mismatch should reach the old path's int→string voice (the same voice type.mismatch already uses?) |
| pw_const_cycle_unnamed_type | **R** | the same two refusals at one place in the opposite order. Ruling wanted: "at one place, refusals are said in law order: the item's const.cycle before its signature's type.unknown". The layer does this, and I recommend keeping it |
| seat_c5 | **S** | both paths say `this list holds \`int\`, this is \`string\``. refuses.expected still has the old wording. Re-pin it and drop differs.why |
| pw_spread_into_typed_list | **S** | both paths ACCEPT `[null, ..xs]` into `List<int?>` (exit 0), which is right, since int widens to int?. refuses.expected is stale. Re-pin it as a printing case and drop differs.why |

## resolve
| case | verdict | note |
|---|---|---|
| self_lambda_param | L | ruled: the old path's type.method is a follow-on of resolve.reserved |

## layer-commands (the layer parses and lowers each item alone)
| case | verdict | note |
|---|---|---|
| pw_parse_trailing_operator | L | ruled: the item's rule is `stmt`. The layer's help also lists what may start one |
| pw_parse_component_instance | L | ruled for the parse part. The differs.why is incomplete: the layer also says a true `type.duplicate_field` (component `x` declares `x` twice), where the old path says one build.failed head-count error. Update the note |
| select_anyof_arm, select_every_arm, select_fair | L | the old path's `language.defect` (register out of mint order) is an old-path lowering bug after flow.select; the layer refuses before lowering |

## ui-language (the sugar's note frame)
| case | verdict | note |
|---|---|---|
| is_binds_twice, w_match_is_binds_on_int | **R** | the old path adds a frame that explains `if … is` (as a `match` with an `else` arm) |
| pw_chain_apply_argument | **R** | the same, for `f?.(…)` |
| pw_type_hole_text | **R** | the same, for `n.type(s)` |

One ruling covers all four: *"does the layer speak the sugar's own note frame beside a refusal inside it?"*
- If yes: **F** for ui-language, medium (one frame voice per sugar, 3 sugars, said where the refusal falls inside the desugared span).
- If no: **L**, and the old frames go away with the old path.

I lean no. The refusal already names the place and the law, and the frame retells the desugaring.

## Not in the 35
`wasm_package_c` has a differs.why but runs untooled here, so it isn't counted.

## What I take now
- generator_reaches_world (F): **done in b292c013**. A generator's run, a seat's settled default and trait_claims now pass `reader_spelled(package)`, the speller consts already used, so the label says `@std.prelude.println`. The differs.why now names the one remaining difference, the old path's follow-on resolve.unresolved, which is L. Not changed: item_instance_checks.av's run has the same gap, but laws-fusion is in that file for the P0, so it's theirs to add.
- If the lead agrees, also the two S re-pins (seat_c5, pw_spread_into_typed_list). They are expectation-only, so not my lane's code, but two minutes.
