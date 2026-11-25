# Soundness sweep, half A: results as the transcript shows them (reconstructed)

The lane's results TSVs (`/tmp/claude-0/sweep/results.tsv`, 1,191 rows, and `results-redo.tsv`,
75 rows rerun under the revised one.sh) lived in its sandbox and are lost. The transcript keeps
only what it printed: the merged category counts, the head of each category, the triage tables,
and the posted ranked list. Those are copied below verbatim. Rows the transcript cut
(`…[N chars cut]…`) are not invented. To get the full TSV again, rerun half A with this kit on a
built d00e7c64 tree:

    xargs -a fixtures-A.txt -P 4 -I{} sh one.sh "$TREE" out-A {} > results-A.tsv 2>/dev/null

(about 20 minutes on 4 cores; build the sqlite, compress and tls objects first, as README says).

## Merged counts (results.tsv + results-redo.tsv, before the last 6 link reruns)

    == 1 soundness: old refuses, layer accepts: 32
    == 2 wrong words: both refuse, first error differs: 34
    == 3 false refusal: layer refuses, old accepts: 6
    == 4 layer fails without a diagnostic, old accepts: 6
    == 5 old fails without a diagnostic, layer accepts: 13
    == agree: 1099
    == timeout: 1

The 6 category-4 rows were missing `build/std_compress.a` / `build/std_tls.a`; rerun after
building them, all six agree (exit 0 on both paths).

## Merged ranking, as printed (rank.py 80, agree omitted; the middle was cut by the transcript)

       69 redo1.txt
       54 redo2.txt
       69 redo.txt
      192 total
    redo done 69 in 36s
    
    [exited with code 0]
    == 1 soundness: old refuses, layer accepts: 32
       	graph/repro/generic-ref	type.method
       	packages/std-db/src/tests/model_stacked	language.defect
       	tools/program-refusals/builds_annotation_fields_of_the_record	resolve.unresolved
       	tools/program-refusals/builds_composition_body	resolve.receiver
       	tools/program-refusals/builds_ctx_dyn_two_traits	ctx.old_path
       	tools/program-refusals/builds_ctx_fn_value_read	ctx.old_path
       	tools/program-refusals/builds_ctx_fn_value_default	ctx.old_path
       	tools/program-refusals/builds_ctx_handler_made_outside	ctx.old_path
       	tools/program-refusals/builds_ctx_imported	ctx.old_path
       	tools/program-refusals/builds_ctx_required_set	ctx.old_path
       	tools/program-refusals/builds_ctx_set_unread	ctx.old_path
       	tools/program-refusals/builds_ctx_placed_set	ctx.old_path
       	tools/program-refusals/builds_ctx_spawn_method	ctx.old_path
       	tools/program-refusals/builds_ctx_spawn_handler	ctx.old_path
       	tools/program-refusals/builds_default_never_method	type.struct_targs
       	tools/program-refusals/builds_db_model_index	resolve.unresolved
       	tools/program-refusals/builds_db_model_key	resolve.unresolved
       	tools/program-refusals/builds_generic_method_prefix	type.impl
       	tools/program-refusals/builds_generic_methods	type.impl
       	tools/program-refusals/builds_phantom_param_defaulted	type.struct_fields
       	tools/program-refusals/builds_prefix_
    …[4691 chars cut]…
    ections/c8	2
       	tools/bench/collections/c5	2
       	tools/bench/hpack	2
       	tools/program-fixes/23_quiet	1
       	tools/program-fixes/25_nullable_if_null_ternary	1
       	tools/program-fixes/26_quiet	1
    == timeout: 1
       	packages/std-avrac/src/features/quote/tests/whole_binder	124	0		
    == 1 soundness: old refuses, layer accepts: 32
    == 2 wrong words: both refuse, first error differs: 34
    == 3 false refusal: layer refuses, old accepts: 6
    == 4 layer fails without a diagnostic, old accepts: 6
    == 5 old fails without a diagnostic, layer accepts: 13
    == agree: 1099
    == timeout: 1

## Triage table (layer-only forms from `avra tapes --new-only`, `differs.why`), as printed

    == 1: 32  {'UNEXPLAINED': 2, 'layer-only form': 26, 'differs.why': 4}
       	UNEXPLAINED	graph/repro/generic-ref	type.method			
       	UNEXPLAINED	packages/std-db/src/tests/model_stacked	language.defect			
       	differs.why	tools/program-refusals/shown_typed_empty_list	lower.no_projection			the old path reads the binding as its value's type, `[]`, and refuses the answer; the bind
       	differs.why	tools/program-refusals/sibling_pin_coalesce	type.mismatch			lead ruling: a generic call's T may be pinned by a sibling arm's type — the layer pins it 
       	differs.why	tools/program-refusals/sibling_pin_if	type.mismatch			lead ruling: a generic call's T may be pinned by a sibling arm's type — the layer pins it 
       	differs.why	tools/program-refusals/sibling_pin_match	type.mismatch			lead ruling: a generic call's T may be pinned by a sibling arm's type — the layer pins it 
       	layer-only form	tools/program-refusals/builds_annotation_fields_of_the_record	resolve.unresolved		an annotation naming fields of the record it stands on	
       	layer-only form	tools/program-refusals/builds_composition_body	resolve.receiver		a component member whose default reads the instance's inputs	
       	layer-only form	tools/program-refusals/builds_ctx_dyn_two_traits	ctx.old_path		a context (`ctx`)	
       	layer-only form	tools/program-refusals/builds_ctx_fn_value_default	ctx.old_path		a context (`ctx`)	
       	layer-only form	tools/program-refusals/builds_ctx_fn_value_read	ctx.old_path		a context (`ctx`)	
       	layer-only form	t
    …[3865 chars cut]…
    c/src/features/quote/tests/open_shape				
       	UNEXPLAINED	packages/std-avrac/src/features/tests/ordinary_widen				
       	UNEXPLAINED	tools/bench/collections/c5				
       	UNEXPLAINED	tools/bench/collections/c7				
       	UNEXPLAINED	tools/bench/collections/c8				
       	UNEXPLAINED	tools/bench/hpack				
       	UNEXPLAINED	tools/program-fixes/23_quiet				
       	UNEXPLAINED	tools/program-fixes/25_nullable_if_null_ternary				
       	UNEXPLAINED	tools/program-fixes/26_quiet				
    == timeout: 1  {'UNEXPLAINED': 1}
       	UNEXPLAINED	packages/std-avrac/src/features/quote/tests/whole_binder

## The six link reruns (results-redo.tsv tail)

    make 0
    build/std_compress.a
    build/std_tls.a
    tools/bench/reach/sign	0			0		
    tools/bench/handshake	0			0		
    tools/bench/reach/tls	0			0		
    tools/bench/app	0	warning:enums.bool_variant_match		0		
    tools/bench/reach/unreached	0	warning:modules.unused_import		0		
    tools/h2spec	0			0

## Warning-only differences

    83 rows agree on exit and error but differ in first diagnostic
    21 ('warning:fns.dead_parameter', '')
    12 ('warning:nullable.nullable_flag_local', '')
    8 ('warning:type.alias_copy', '')
    7 ('warning:closures.pronoun_lambda', '')
    7 ('warning:modules.unused_import', '')
    3 ('warning:loops.push_loop', '')
    3 ('warning:nullable.if_null_ternary', '')
    3 ('warning:compiler.one_body_arms', '')
    3 ('warning:type.seat_unused', 'error:type.host_seat')
    2 ('warning:compiler.duplicated_literal', '')
    2 ('warning:enums.bool_variant_match', '')
    2 ('', 'warning:type.unreachable_arm')
    25:Building the tree, if it isn't built (and the objects a plain `make` leaves out: `make build/sqlite3.o build/sqlite_sentinel.o build/std_compress.a build/std_tls.a`): `cd $TREE && AVRA_PROGRAM_NET=0 make` (from a `build/` that has

## The posted ranked list (03:35)


SWEEP, half A: 1,191 of 1,191 done, with suspect rows rerun under the fixed runner. B is pending from wrong-answers. Agree: 1,099. Not fixing anything.
1. SOUNDNESS (old refuses, layer accepts): 32. 30 are expected: 26 use a layer-only form (`tapes --new-only`: ctx, generic methods, type-param defaults, annotations naming fields, state seats); 4 have `differs.why` (the sibling-pin ruling, shown_typed_empty_list).
   Both unexplained ones are the layer RIGHT:
   - graph/repro/generic-ref: `run` answers `p1`; the old derive takes the `.value()` branch for `Ref<T>`.
   - std-db model_stacked: prints its `.expected`; the old path says `language.defect`.
   No soundness hole in A.
2. LAYER FALSE REFUSALS of passing program tests: the real finds. All three are annotations whose compile-time reads of crossing/field facts come back absent or unmatched:
   - features/annotations/tests/doc_and_annotations: annotation.said, "variant crossing did not match".
   - field_spelled: annotation.unsettled (`spelled_are` unwraps an absent value).
   - flat_nested_crossing: annotation.unsettled (`marks_read`).
   Also 3 layer refusals carrying a layer-only form.
3. WRONG WORDS: 34. 32 are explained (23 layer-only forms, 9 `differs.why`). Unexplained: graph (old annotation.unsettled, layer resolve.duplicate_type `Catalog`) and graph/tests/unrelated (type.method vs type.unknown_prop).
4. Old path fails with no diagnostic: 13 (crashes; the layer builds). One old timeout: quote/whole_binder.
- Warnings: 83 rows differ only in a warning, nearly all lint rules that `check` runs and `build` doesn't.
- None of A's candidates matches A–E or afc3e0a8.
- Kit: README now also says to build `std_compress.a` and `std_tls.a`, or tls and compress fixtures fail to link.

## After the annotation fix (11812d5c on d00e7c64): 162 meta-heavy fixtures rerun

    162
    162 rerun; 3 changed on the layer:
      	packages/std-avrac/src/features/annotations/tests/doc_and_annotations	1	annotation.said	0	
      	packages/std-avrac/src/features/annotations/tests/field_spelled	1	annotation.unsettled	0	
      	packages/std-avrac/src/features/annotations/tests/flat_nested_crossing	1	annotation.unsettled	0	
    
    [exited with code 0]
    162 rerun; 3 changed on the layer (path, was exit, was err, now exit, now err):
      	packages/std-avrac/src/features/annotations/tests/doc_and_annotations	1	annotation.said	0	
      	packages/std-avrac/src/features/annotations/tests/field_spelled	1	annotation.unsettled	0	
      	packages/std-avrac/src/features/annotations/tests/flat_nested_crossing	1	annotation.unsettled	0	
    
    [exited with code 0]

## Triage notes

- graph/repro/generic-ref: the layer is right; `avra run` answers `p1`. The old derive in
  std-validate takes the `.value()` branch for a generic `Ref<T>` and over-refuses.
- std-db model_stacked: the layer prints its `.expected` (`Before 1 After 1 refused`); the old
  path says `language.defect` (`After`'s flatness read before a `mut` seat sealed it).
- graph and graph/tests/unrelated (wrong words) share one cause, a layer false refusal:
  `export use schema.{Ref}` re-exporting a same-module sibling's declaration is counted as
  declared twice (resolve.duplicate_type). Repro in reexport_repro/; it belongs to
  parity-resolve-2.
- The three annotation false refusals are fixed by 11812d5c (branch …-crossing).
