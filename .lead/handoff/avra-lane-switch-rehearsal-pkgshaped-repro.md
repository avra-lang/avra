# Package-shaped program tests on the program layer — repro commands (trunk 3d35d216)

From /work/avra (or your tree's root), with a trunk-built standing compiler. Each builds the test package IN PLACE on the new path, runs it, and diffs its stdout against its .expected (the .expected files carry no final newline; compare text, not bytes):

```sh
pk() { d=$1; find $d -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \; ; AVRA_PROGRAM=1 ./avra build $d && (cd $d && ./src/main) > /tmp/pk.out; [ "$(cat /tmp/pk.out)" = "$(cat $d/src/main.expected)" ] && echo RIGHT || diff /tmp/pk.out $d/src/main.expected; }
```

## Wrong (8)
- `pk packages/std-avrac/src/features/collects/tests/closure_entry_private ` — wrong(exit 0): < [] 1
- `pk packages/std-avrac/src/features/collects/tests/gathered_same_name ` — wrong(exit 0): < Error()@ Collect(of:int/Int)@ | Error()@ Collect(word:string/Str,dense:bool/Bool)@ | 4 2
- `pk packages/std-avrac/src/features/collects/tests/gathered_package ` — wrong(exit 0): < 3 Dot()@ Line(from:int/Int,to:int/Int)@ Box(width:Width/Named,inner:List<Shape>/List)@ 10 0 3 35
- `pk packages/std-avrac/src/features/collects/tests/closure_entry_b ` — wrong(exit 0): < []
- `pk packages/std-avrac/src/features/collects/tests/gathered_mutual ` — wrong(exit 0): < Tip()@ Fork(under:Tree/Named,kids:List<Leaf>/List)@ | Stump()@ Limb(leaf:Leaf/Named,next:Tree?/Opt
- `pk packages/std-avrac/src/features/annotations/tests/wrap_method ` — wrong(exit 0): < 10 6 12
- `pk packages/std-avrac/src/features/annotations/tests/prop_told ` — wrong(exit 0): < title prop=false state=false kind=string · kids prop=false state=false kind=List<string> · tone 
- `pk packages/std-meta/src/tests/record_reads ` — wrong(exit 0): < items: List<Elem> is NOT readable from the enum's module

## Not built (19)
- `pk packages/std-avrac/src/features/consts/tests/private_const ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- `pk packages/std-avrac/src/features/consts/tests/generated_const ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- `pk packages/std-avrac/src/features/collects/tests/gathered_exact ` — not-built(exit 1): error[type.method]: `SyntaxArena` has no method `exact_pat`
- `pk packages/std-avrac/src/features/asset/tests/hygiene ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a const whose value reaches a body not lowered yet: a call of the generic `unreached` whose arguments
- `pk packages/std-avrac/src/features/fns/tests/const_seat ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- `pk packages/std-avrac/src/features/fns/tests/provided ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a const whose value reaches a body not lowered yet: a call of the generic `unreached` whose arguments
- `pk packages/std-avrac/src/features/annotations/tests/traced ` — not-built(exit 1): error[resolve.unresolved]: no `fn sum_traced` is defined
- `pk packages/std-avrac/src/features/annotations/tests/default_seats ` — not-built(exit 1): error[resolve.unresolved]: no `fn two_default` is defined
- `pk packages/std-avrac/src/features/annotations/tests/const_argument ` — not-built(exit 1): error[resolve.unresolved]: no `fn one_s` is defined
- `pk packages/std-avrac/src/features/tests/crossing ` — not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: crossing/src/main.av.seed
- `pk packages/std-avrac/src/features/tests/ordinary_widen ` — not-built(exit 1): error[type.mismatch]: the body answers `Code` but `widen_add` declares `Fix?`
- `pk packages/std-avrac/src/features/quote/tests/hygiene ` — not-built(exit 1): error[resolve.unresolved]: no `fn go_wrapped` is defined
- `pk packages/std-avrac/src/features/quote/tests/binders ` — not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: binders/src/main.av.P.binders
- `pk packages/std-avrac/src/features/quote/tests/statements ` — not-built(exit 1): error[resolve.unresolved]: no `fn base_run` is defined
- `pk packages/std-avrac/src/features/enums/tests/const_pat_template ` — not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: const_pat_template/src/main.av.Point.class
- `pk packages/std-avrac/src/features/sublang/tests/sql ` — not-built(exit 1): avra: the program layer doesn't build this program yet — another language's body, at the entry
- `pk packages/std-avrac/src/compiler/tests/query_annotation ` — not-built(exit 1): error[resolve.unresolved]: `a_close` is not defined
- `pk packages/std-avrac/src/compiler/tests/package_rule ` — not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: package_rule/src/main.av.plus_zero
- `pk packages/std-ui/src/tests/seat_entry ` — not-built(exit 1): avra: the program layer doesn't build this program yet — a record literal leaving a field no declared default fills, at the entry

## All 97 (the list the sweep ran)
```
packages/std-relation/src/tests/plugin_guide
packages/std-prelude/src/tests/hello
packages/std-prelude/src/tests/entry
packages/std-db/src/tests/two_packages
packages/std-db/src/tests/model_stacked
packages/std-avrac/src/features/consts/tests/export_const
packages/std-avrac/src/features/consts/tests/private_const
packages/std-avrac/src/features/consts/tests/generated_const
packages/std-avrac/src/features/components/tests/template
packages/std-avrac/src/features/collects/tests/collect_module_root
packages/std-avrac/src/features/collects/tests/const_member
packages/std-avrac/src/features/collects/tests/gathered_member_first_far
packages/std-avrac/src/features/collects/tests/delegated_package_two_derived
packages/std-avrac/src/features/collects/tests/closure_entry_private
packages/std-avrac/src/features/collects/tests/generated_member
packages/std-avrac/src/features/collects/tests/gathered_same_name
packages/std-avrac/src/features/collects/tests/gathered_package
packages/std-avrac/src/features/collects/tests/delegated_package_derive
packages/std-avrac/src/features/collects/tests/delegated_package_self
packages/std-avrac/src/features/collects/tests/gathered_exact
packages/std-avrac/src/features/collects/tests/derived_member
packages/std-avrac/src/features/collects/tests/closure_entry_a
packages/std-avrac/src/features/collects/tests/collect_function_derived
packages/std-avrac/src/features/collects/tests/delegated_package
packages/std-avrac/src/features/collects/tests/closure_entry_b
packages/std-avrac/src/features/collects/tests/collect_module_derived
packages/std-avrac/src/features/collects/tests/gathered_field_marks
packages/std-avrac/src/features/collects/tests/delegated_package_self_param
packages/std-avrac/src/features/collects/tests/gathered_mutual
packages/std-avrac/src/features/asset/tests/hygiene
packages/std-avrac/src/features/narrows/tests/narrow_across
packages/std-avrac/src/features/fns/tests/const_seat
packages/std-avrac/src/features/fns/tests/contained_const
packages/std-avrac/src/features/fns/tests/provided
packages/std-avrac/src/features/fns/tests/default_owner_functions
packages/std-avrac/src/features/formats/tests/hygiene_format
packages/std-avrac/src/features/annotations/tests/marks
packages/std-avrac/src/features/annotations/tests/wrap_method
packages/std-avrac/src/features/annotations/tests/doc_and_annotations
packages/std-avrac/src/features/annotations/tests/derive_type_args
packages/std-avrac/src/features/annotations/tests/comptime_annotations
packages/std-avrac/src/features/annotations/tests/annotation_args
packages/std-avrac/src/features/annotations/tests/wrap_query_outside
packages/std-avrac/src/features/annotations/tests/prop_told
packages/std-avrac/src/features/annotations/tests/traced
packages/std-avrac/src/features/annotations/tests/derive_name_hole
packages/std-avrac/src/features/annotations/tests/default_seats
packages/std-avrac/src/features/annotations/tests/wrap_and_generate
packages/std-avrac/src/features/annotations/tests/const_argument
packages/std-avrac/src/features/annotations/tests/derive
packages/std-avrac/src/features/annotations/tests/derive_closure
packages/std-avrac/src/features/annotations/tests/wrap_free_fn
packages/std-avrac/src/features/annotations/tests/derive_construct
packages/std-avrac/src/features/tests/derive_field_default
packages/std-avrac/src/features/tests/kinds
packages/std-avrac/src/features/tests/derive_sibling_floor
packages/std-avrac/src/features/tests/crossing
packages/std-avrac/src/features/tests/identity_path
packages/std-avrac/src/features/tests/earned_sig
packages/std-avrac/src/features/tests/derive_sibling_floor_native
packages/std-avrac/src/features/tests/ordinary_widen
packages/std-avrac/src/features/tests/declares_generic_sub
packages/std-avrac/src/features/tests/declares_bool_splice
packages/std-avrac/src/features/quote/tests/identity
packages/std-avrac/src/features/quote/tests/hygiene
packages/std-avrac/src/features/quote/tests/kitchen
packages/std-avrac/src/features/quote/tests/open_shape
packages/std-avrac/src/features/quote/tests/two_impls
packages/std-avrac/src/features/quote/tests/nested
packages/std-avrac/src/features/quote/tests/self_read
packages/std-avrac/src/features/quote/tests/arms
packages/std-avrac/src/features/quote/tests/seat_read
packages/std-avrac/src/features/quote/tests/param_spread
packages/std-avrac/src/features/quote/tests/names
packages/std-avrac/src/features/quote/tests/whole_binder
packages/std-avrac/src/features/quote/tests/many
packages/std-avrac/src/features/quote/tests/binders
packages/std-avrac/src/features/quote/tests/quote
packages/std-avrac/src/features/quote/tests/template_gaps
packages/std-avrac/src/features/quote/tests/nested_holed
packages/std-avrac/src/features/quote/tests/statements
packages/std-avrac/src/features/quote/tests/spread
packages/std-avrac/src/features/enums/tests/type_names_template
packages/std-avrac/src/features/enums/tests/const_pat_template
packages/std-avrac/src/features/enums/tests/const_pat_modules
packages/std-avrac/src/features/closures/tests/template_lambdas
packages/std-avrac/src/features/sublang/tests/sql
packages/std-avrac/src/compiler/tests/modules
packages/std-avrac/src/compiler/tests/generated_surface
packages/std-avrac/src/compiler/tests/query_annotation
packages/std-avrac/src/compiler/tests/packages
packages/std-avrac/src/compiler/tests/merge_functions
packages/std-avrac/src/compiler/tests/package_rule
packages/std-avrac/src/compiler/memory/tests/borrowed_cell_read
packages/std-meta/src/tests/list_of
packages/std-meta/src/tests/record_reads
packages/std-ui/src/tests/seat_entry
```
