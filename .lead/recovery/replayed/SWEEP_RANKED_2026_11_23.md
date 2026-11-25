# Soundness sweep, both halves, ranked (d00e7c64 gen-2, 2026-11-23)

Inputs: results-A.tsv (1,191), results-B.tsv (1,191: 245 dirs + 946 singles under the revised runner), results-redo.tsv (memory-pool and timeout reruns, one at a time). Tags: layer-only form = `avra tapes --new-only` names one; differs.why = the case's own known difference; dependency = the old path's first error lands in a library, not the fixture.

```
== 1 SOUNDNESS candidates: old refuses, layer accepts: 118  {'dependency': 1, 'UNEXPLAINED': 1, 'layer-only form': 111, 'differs.why': 5}
    dependency	1x	type.method	dep:packages/std-validate/src/derive.av
   	UNEXPLAINED	packages/std-db/src/tests/model_stacked	language.defect			
== 1b old refuses, layer fails with no diagnostic: 6  {'layer-only form': 4, 'UNEXPLAINED': 2}
   	UNEXPLAINED	packages/std-relation/src/tests/codec_scope/codec_scope.av	resolve.no_module		fixture	
   	UNEXPLAINED	packages/std-relation/src/tests/nameless_key/nameless_key.av	resolve.no_module		fixture	
== 2 wrong words: both refuse, first error differs: 36  {'UNEXPLAINED': 3, 'layer-only form': 24, 'differs.why': 9}
   	UNEXPLAINED	graph	annotation.unsettled	resolve.duplicate_type	fixture	
   	UNEXPLAINED	graph/tests/unrelated	type.method	type.unknown_prop	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/components/tests/quoted_home/quoted_home.av	parse.expected	resolve.no_module	fixture	
== 3 layer false refusals: layer refuses, old accepts: 11  {'UNEXPLAINED': 4, 'layer-only form': 3, 'differs.why': 4}
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/doc_and_annotations		annotation.said	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/field_spelled		annotation.unsettled	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/flat_nested_crossing		annotation.unsettled	fixture	
   	UNEXPLAINED	tools/program-refusals/w_dependency_const_budget_is_its_own/vendor/heavy		const.budget	fixture	
== 4 layer fails without a diagnostic, old accepts: 3  {'differs.why': 1, 'UNEXPLAINED': 2}
   	UNEXPLAINED	packages/std-process/src/tests/proc_seam/proc_seam.av				
   	UNEXPLAINED	tools/program-warnings/unreachable_arm				
== 5 old fails without a diagnostic, layer accepts: 9  {'UNEXPLAINED': 9}
   	UNEXPLAINED	packages/std-avrac/src/core/tests/arena_mode/arena_mode.av				
   	UNEXPLAINED	packages/std-avrac/src/core/tests/side_mode/side_mode.av				
   	UNEXPLAINED	packages/std-avrac/src/core/tests/type_content_key/type_content_key.av				
   	UNEXPLAINED	packages/std-avrac/src/diagnostics/tests/cause_chain/cause_chain.av				
   	UNEXPLAINED	packages/std-avrac/src/features/collects/tests/gathered_exact				
   	UNEXPLAINED	packages/std-avrac/src/features/tests/ordinary_widen				
   	UNEXPLAINED	tools/program-fixes/23_quiet				
   	UNEXPLAINED	tools/program-fixes/25_nullable_if_null_ternary				
   	UNEXPLAINED	tools/program-fixes/26_quiet				
== timeout timeouts: 0  {}
struck shapes (A-E, afc3e0a8): 3576157f b8329f82 49d54716 241b9b16 272a5c54 afc3e0a8
```

## Full rows, every category (tag, path, old error, layer error, where, form or why)

```
    dependency	1x	type.method	dep:packages/std-validate/src/derive.av
   	UNEXPLAINED	packages/std-db/src/tests/model_stacked	language.defect			
   	differs.why	tools/program-refusals/shown_typed_empty_list	lower.no_projection		fixture	the old path reads the binding as its value's type, `[]`, and refuses the answer
   	differs.why	tools/program-refusals/sibling_pin_coalesce	type.mismatch		fixture	lead ruling: a generic call's T may be pinned by a sibling arm's type — the laye
   	differs.why	tools/program-refusals/sibling_pin_if	type.mismatch		fixture	lead ruling: a generic call's T may be pinned by a sibling arm's type — the laye
   	differs.why	tools/program-refusals/sibling_pin_match	type.mismatch		fixture	lead ruling: a generic call's T may be pinned by a sibling arm's type — the laye
   	differs.why	tools/program-refusals/w_variant_lit_branch	type.variant_lit		fixture	lead ruling: one rule across if/match/when/?? — a bare variant beside a typed si
   	layer-only form	packages/std-avrac/src/features/components/tests/partial_targs/partial_targs.av	type.struct_targs		fixture	a type parameter's default (`<E = never>`) type arguments wr
   	layer-only form	packages/std-avrac/src/features/ctxs/tests/captured/captured.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-avrac/src/features/ctxs/tests/frames/frames.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-avrac/src/features/ctxs/tests/spawned_method/spawned_method.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-avrac/src/features/ctxs/tests/trap_back/trap_back.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-avrac/src/features/ctxs/tests/value_cycle/value_cycle.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-queue_store/src/tests/durable_emails/durable_emails.av	resolve.not_exported		fixture	a context (`ctx`)
   	layer-only form	packages/std-queue_store/src/tests/in_tx_late/in_tx_late.av	resolve.not_exported		fixture	a context (`ctx`)
   	layer-only form	packages/std-queue_store/src/tests/store_seam/store_seam.av	ctx.old_path		dep:packages/std-queue_store/src/durable.av	a context (`ctx`)
   	layer-only form	packages/std-relation/src/tests/ctx_heard/ctx_heard.av	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_comp/exact_comp.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_empty/exact_empty.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_for/exact_for.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_gap/exact_gap.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_handlers/exact_handlers.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_helper/exact_helper.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_if/exact_if.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_list/exact_list.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_prop/exact_prop.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_turns/exact_turns.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/exact_why1/exact_why1.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/frame/frame.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/realize/dom/tests/host_corpus/host_corpus.av	type.struct_fields		dep:packages/std-ui/src/realize/dom/tests/support/sketch.av	a field of `@std/meta`'s `Key` written in a literal
   	layer-only form	packages/std-ui/src/realize/dom/tests/repaint_law/repaint_law.av	type.struct_fields		dep:packages/std-ui/src/realize/dom/tests/support/sketch.av	a field of `@std/meta`'s `Key` written in a literal
   	layer-only form	packages/std-ui/src/realize/dom/tests/wire/wire.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/board/board.av	type.struct_fields		fixture	a component's `state` member written at its instance a field
   	layer-only form	packages/std-ui/src/tests/components/components.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/contained/contained.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/contained_roots/contained_roots.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/contained_state/contained_state.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/contained_terminal/contained_terminal.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/driver/driver.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/handlers/handlers.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/identity/identity.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instance_attacks/instance_attacks.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instance_life/instance_life.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/instance_page/instance_page.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instance_rows/instance_rows.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instance_sites/instance_sites.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instance_terminal/instance_terminal.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/instances/instances.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/keyed_list/keyed_list.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/loop_adversarial/loop_adversarial.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_async/loop_async.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_async_edges/loop_async_edges.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_clock/loop_clock.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_door/loop_door.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_door_nested/loop_door_nested.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_fetch/loop_fetch.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_frames/loop_frames.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_owner/loop_owner.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_owner_edges/loop_owner_edges.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/loop_owner_flat/loop_owner_flat.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/loop_owner_race/loop_owner_race.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/loop_reap/loop_reap.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/model_form/model_form.av	type.struct_fields		dep:packages/std-ui/src/forms/form_inputs.av	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/observed/observed.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_feed/observed_feed.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_feed_attacks/observed_feed_attacks.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_layer_attacks/observed_layer_attacks.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_layers/observed_layers.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_reask/observed_reask.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_trapped_parse/observed_trapped_parse.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_unmount/observed_unmount.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_versions/observed_versions.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_watch/observed_watch.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/observed_writes/observed_writes.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/ordered_joined/ordered_joined.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/ordered_owner/ordered_owner.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/placed/placed.av	ctx.old_path		fixture	a context (`ctx`) a component's `List` field marked `@defaul
   	layer-only form	packages/std-ui/src/tests/placed_rows/placed_rows.av	type.struct_fields		fixture	a context (`ctx`) a field of `@std/meta`'s `Key` written in 
   	layer-only form	packages/std-ui/src/tests/prop_cell/prop_cell.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/seat_entry	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/sited_comp/sited_comp.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/sited_text/sited_text.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/slots/slots.av	type.component_event		fixture	a component's `List` field marked `@default` a component mem
   	layer-only form	packages/std-ui/src/tests/state_seat/state_seat.av	type.struct_fields		fixture	a `state` seat in a component's head a component's `state` m
   	layer-only form	packages/std-ui/src/tests/terminal/terminal.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/terminal_timer/terminal_timer.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/terminal_window/terminal_window.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	packages/std-ui/src/tests/trapped_turn/trapped_turn.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/typed_asks/typed_asks.av	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	packages/std-ui/src/tests/unkeyed_owner/unkeyed_owner.av	type.struct_fields		fixture	a field of `@std/meta`'s `Key` written in a literal a compon
   	layer-only form	tools/program-refusals/builds_annotation_fields_of_the_record	resolve.unresolved		fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/builds_composition_body	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	tools/program-refusals/builds_ctx_dyn_two_traits	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_fn_value_default	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_fn_value_read	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_handler_made_outside	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_imported	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_placed_set	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_required_set	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_set_unread	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_spawn_handler	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_ctx_spawn_method	ctx.old_path		fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/builds_db_model_index	resolve.unresolved		fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/builds_db_model_key	resolve.unresolved		fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/builds_default_never_method	type.struct_targs		fixture	a type parameter's default (`<E = never>`) type arguments wr
   	layer-only form	tools/program-refusals/builds_generic_method_prefix	type.impl		fixture	a method declaring type parameters of its own type arguments
   	layer-only form	tools/program-refusals/builds_generic_methods	type.impl		fixture	a type parameter's default (`<E = never>`) a method declarin
   	layer-only form	tools/program-refusals/builds_phantom_param_defaulted	type.struct_fields		fixture	a type parameter's default (`<E = never>`)
   	layer-only form	tools/program-refusals/builds_prefix_type_args	type.struct_targs		fixture	a type parameter's default (`<E = never>`) type arguments wr
   	layer-only form	tools/program-refusals/builds_slot_named_block	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	tools/program-refusals/builds_slot_shadowed	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	tools/program-refusals/builds_state_member_seeded	resolve.receiver		fixture	a component member whose default reads the instance's inputs
   	layer-only form	tools/program-refusals/builds_state_seat_field_path	type.seat		fixture	a `state` seat handed a module's `state` or a `state` field
   	layer-only form	tools/program-refusals/builds_state_seat_module	type.seat		fixture	a `state` seat handed a module's `state` or a `state` field
   	layer-only form	tools/program-refusals/builds_type_param_defaults	type.applied		fixture	a type parameter's default (`<E = never>`) type arguments wr
   	layer-only form	tools/program-refusals/impl_generic_method	type.impl		fixture	a method declaring type parameters of its own
   	layer-only form	tools/queue-witness	resolve.not_exported		fixture	a context (`ctx`)
   	layer-only form	tools/ui-board/term	type.component_event		dep:tools/ui-board/src/board.av	a `state` seat in a component's head a component's `List` fi
   	UNEXPLAINED	packages/std-relation/src/tests/codec_scope/codec_scope.av	resolve.no_module		fixture	
   	UNEXPLAINED	packages/std-relation/src/tests/nameless_key/nameless_key.av	resolve.no_module		fixture	
   	layer-only form	tools/ui-bench	type.struct_fields		fixture	a component's `state` member written at its instance a field
   	layer-only form	tools/ui-bench/native	type.struct_fields		dep:tools/ui-bench/src/bench.av	a component's `state` member written at its instance a field
   	layer-only form	tools/ui-board	type.component_event		fixture	a `state` seat in a component's head a component's `List` fi
   	layer-only form	tools/ui-warns	resolve.receiver		dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	UNEXPLAINED	graph	annotation.unsettled	resolve.duplicate_type	fixture	
   	UNEXPLAINED	graph/tests/unrelated	type.method	type.unknown_prop	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/components/tests/quoted_home/quoted_home.av	parse.expected	resolve.no_module	fixture	
   	differs.why	tools/program-refusals/generator_reaches_world	resolve.unresolved	annotation.unsettled	fixture	the old path also says resolve.unresolved for `one_stamped`, the twin the refuse
   	differs.why	tools/program-refusals/phantom_param_instance	type.struct_fields	type.struct_targs	fixture	lead ruling: a phantom type parameter — one no field names, and no argument or a
   	differs.why	tools/program-refusals/phantom_param_literal	type.struct_fields	type.struct_targs	fixture	lead ruling: a phantom type parameter — one no field names, and no argument or a
   	differs.why	tools/program-refusals/pw_const_cycle_unnamed_type	type.unknown	const.cycle	fixture	RULED (L): at one place, refusals are said in law order — the item's own const.c
   	differs.why	tools/program-refusals/pw_generic_literal_argument	type.mismatch	type.struct_fields	fixture	lead ruling: the layer's law is kept — it points at the field or element that is
   	differs.why	tools/program-refusals/pw_parse_component_instance	build.failed	type.duplicate_field	fixture	lead ruling: the layer parses each item alone (its design, what keeps edits chea
   	differs.why	tools/program-refusals/pw_rest_spread_element	type.mismatch	type.list_element	fixture	lead ruling: the layer's law is kept — it points at the field or element that is
   	differs.why	tools/program-refusals/spread_generic_seat	type.spread_field	type.mismatch	fixture	RULED, the layer's answer is the law: a seat typed by a type parameter takes the
   	differs.why	tools/program-refusals/spread_missing_cascade	type.spread_missing	type.variant_lit	fixture	RULED, the layer stops at the first fault: `...a` spreads the variant literal `.
   	layer-only form	packages/std-ui/src/web/tests/mount/mount.av	resolve.receiver	lower.host_fn_answers	dep:packages/std-ui/src/components/checkbox.av	a component member whose default reads the instance's inputs
   	layer-only form	tools/program-refusals/annotation_field_misnamed	resolve.unresolved	annotation.seats	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/annotation_fields_on_an_enum	resolve.unresolved	annotation.receiver	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/ctx_cached_untold	ctx.old_path	ctx.cached	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_declared_in_body	ctx.old_path	ctx.where	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_placed_required	ctx.old_path	ctx.required	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_required_dyn	ctx.old_path	ctx.required	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_required_in_case	ctx.old_path	ctx.required	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_required_in_host_fn	ctx.old_path	ctx.required	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_required_unset	ctx.old_path	ctx.required	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_set_at_top	ctx.old_path	ctx.where	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_set_mistyped	ctx.old_path	type.binding	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/ctx_unknown	ctx.old_path	ctx.unknown	fixture	a context (`ctx`)
   	layer-only form	tools/program-refusals/db_model_key_refused	resolve.unresolved	@std/db:unique_repeats	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/durable_db_unset	ctx.old_path	ctx.required	dep:packages/std-queue_store/src/durable.av	a context (`ctx`)
   	layer-only form	tools/program-refusals/generic_method_bound_unmet	type.impl	type.mismatch	fixture	a method declaring type parameters of its own
   	layer-only form	tools/program-refusals/generic_method_prefix_counted	type.impl	type.mismatch	fixture	a method declaring type parameters of its own type arguments
   	layer-only form	tools/program-refusals/inferred_param_answer_judged	type.struct_targs	type.binding	fixture	type arguments written for only the leading parameters
   	layer-only form	tools/program-refusals/model_index_empty	annotation.seats	@std/db:index_empty	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/model_index_one_field	resolve.unresolved	@std/db:index_single	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/model_index_twice_across	resolve.unresolved	@std/db:index_twice	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/model_unique_one_field	resolve.unresolved	@std/db:unique_single	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/shown_beside_place	resolve.receiver	type.seat	dep:packages/std-ui/src/components/checkbox.av	a component's `state` member written at its instance a compo
   	layer-only form	tools/program-refusals/state_member_default_reads_state	resolve.receiver	type.component_default	fixture	a component member whose default reads the instance's inputs
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/doc_and_annotations		annotation.said	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/field_spelled		annotation.unsettled	fixture	
   	UNEXPLAINED	packages/std-avrac/src/features/annotations/tests/flat_nested_crossing		annotation.unsettled	fixture	
   	UNEXPLAINED	tools/program-refusals/w_dependency_const_budget_is_its_own/vendor/heavy		const.budget	fixture	
   	differs.why	tools/program-refusals/validator_handed_what_does_not_cross_is_an_error		annotation.unsettled	fixture	a validator handed an argument that doesn't cross into its seat is an error, nev
   	differs.why	tools/program-refusals/validator_past_its_budget_is_an_error		annotation.unsettled	fixture	a validator past its budget is an error, never a silent exit 0: the program laye
   	differs.why	tools/program-refusals/validator_that_traps_is_an_error		annotation.unsettled	fixture	a validator that traps is an error, never a silent exit 0: the program layer ref
   	differs.why	tools/program-refusals/w_dependency_const_budget_is_its_own		const.budget	fixture	a const's budget is its own package's on the program layer — one settlement shar
   	layer-only form	tools/program-refusals/field_seat_without_a_type		annotation.seats	fixture	an annotation naming fields of the record it stands on
   	layer-only form	tools/program-refusals/state_member_valued		type.seat	fixture	a component's `state` member written at its instance
   	layer-only form	tools/program-refusals/state_seat_component_valued		type.seat	fixture	a `state` seat in a component's head a component's `state` m
   	UNEXPLAINED	packages/std-process/src/tests/proc_seam/proc_seam.av				
   	UNEXPLAINED	tools/program-warnings/unreachable_arm				
   	differs.why	tools/program-refusals/wasm_package_c				the entry is named by each path's own symbol: the old path says `program$<case>_
   	UNEXPLAINED	packages/std-avrac/src/core/tests/arena_mode/arena_mode.av				
   	UNEXPLAINED	packages/std-avrac/src/core/tests/side_mode/side_mode.av				
   	UNEXPLAINED	packages/std-avrac/src/core/tests/type_content_key/type_content_key.av				
   	UNEXPLAINED	packages/std-avrac/src/diagnostics/tests/cause_chain/cause_chain.av				
   	UNEXPLAINED	packages/std-avrac/src/features/collects/tests/gathered_exact				
   	UNEXPLAINED	packages/std-avrac/src/features/tests/ordinary_widen				
   	UNEXPLAINED	tools/program-fixes/23_quiet				
   	UNEXPLAINED	tools/program-fixes/25_nullable_if_null_ternary				
   	UNEXPLAINED	tools/program-fixes/26_quiet				
```
