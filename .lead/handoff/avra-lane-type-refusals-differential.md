# Differential sweep: old-path witness per code (compiler/dev/witnesses.av, 133 Source witnesses) on the new path

Verdicts: SAME = refused in the same first line; DIFFERENT = same kind, other words; OTHER-ERROR = refused under another kind; ACCEPTED = the new path BUILDS a program the old path refuses; UNBUILT = new path says "doesn't build this program yet" (no refusal, no binary); OLD-SILENT = the witness no longer fires on the old path either.

| verdict | count |
|---|---|
| ACCEPTED | 49 |
| DIFFERENT | 1 |
| OTHER-ERROR | 4 |
| UNBUILT | 55 |
| SAME | 18 |
| OLD-SILENT | 6 |

| code | verdict | old first line | new first line |
|---|---|---|---|
| annotation.callee | ACCEPTED | error[annotation.callee]: an annotation names a fn over a declaration | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/annotation_callee/src/main |
| annotation.receiver | ACCEPTED | error[annotation.receiver]: an annotation's first seat says what it takes | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/annotation_receiver/src/main |
| build.failed | ACCEPTED | error[build.failed]: the brace after an instance's head opens the instance's block, so `Span { … }` is no record literal here — a record lit | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/build_failed/src/main |
| collect_enum.empty | ACCEPTED | error[collect_enum.empty]: `Shape` gathers no member, and an enum names at least one variant | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/collect_enum_empty/src/main |
| const.param | ACCEPTED | error[const.param]: a const cannot read a run-time parameter | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/const_param/src/main |
| flow.channel | ACCEPTED | error[flow.channel]: `channel` answers `@std.task.Channel`, and this program loads no `@std/task` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/flow_channel/src/main |
| flow.produce | ACCEPTED | error[flow.produce]: `produce` answers `@std.task.Source`, and this program loads no `@std/task` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/flow_produce/src/main |
| flow.yield | ACCEPTED | error[flow.yield]: `yield` sends into the producer it stands in, and no producer encloses it | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/flow_yield/src/main |
| lex.error | ACCEPTED | error[lex.error]: unexpected character `$` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/lex_error/src/main |
| parse.spread | ACCEPTED | error[parse.spread]: a spread places a record's fields and takes no value | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/parse_spread/src/main |
| resolve.impl_member | ACCEPTED | error[resolve.impl_member]: an `impl` block holds `fn` declarations only | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_impl_member/src/main |
| resolve.nested_fn | ACCEPTED | error[resolve.nested_fn]: fn declarations live at the top level | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_nested_fn/src/main |
| resolve.nested_spec | ACCEPTED | error[resolve.nested_spec]: spec blocks live at the top level | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_nested_spec/src/main |
| resolve.nested_type | ACCEPTED | error[resolve.nested_type]: type declarations live at the top level | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_nested_type/src/main |
| resolve.paired | ACCEPTED | error[resolve.paired]: `i` names both the index and the element | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_paired/src/main |
| type.alias | ACCEPTED | error[type.alias]: `Box<...>` is given `void`, which is no value | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_alias/src/main |
| type.component_body | ACCEPTED | error[type.component_body]: a component is made of what its body holds, and nothing here says what `made`'s is | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_component_body/src/main |
| type.defer | ACCEPTED | error[type.defer]: `defer` drops what its body answers, and this one answers `Result<int, string>` — a failure nobody would hear | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_defer/src/main |
| type.defer_inert | ACCEPTED | error[type.defer_inert]: `defer` runs its body later, and this one only names `int` — deferring a value does nothing | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_defer_inert/src/main |
| type.derive_contract | ACCEPTED | error[type.derive_contract]: a trait's `derive` answers the declarations it makes | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_derive_contract/src/main |
| type.duplicate_field | ACCEPTED | error[type.duplicate_field]: `P` declares `x` more than once | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_duplicate_field/src/main |
| type.duplicate_param | ACCEPTED | error[type.duplicate_param]: `f` declares `a` more than once | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_duplicate_param/src/main |
| type.enum_decl | ACCEPTED | error[type.enum_decl]: `E` declares no variants | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_enum_decl/src/main |
| type.enum_payload | ACCEPTED | error[type.enum_payload]: an enum payload cannot hold nothing | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_enum_payload/src/main |
| type.errdefer | ACCEPTED | error[type.errdefer]: an `errdefer` runs when the enclosing fn fails, and there is none enclosing | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_errdefer/src/main |
| type.fail | ACCEPTED | error[type.fail]: `fail` raises on a `Result`'s failure channel, and this fn promises `int` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_fail/src/main |
| type.force | ACCEPTED | error[type.force]: `!` insists on a nullable, this is `int` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_force/src/main |
| type.format_repeat | ACCEPTED | error[type.format_repeat]: `a` names two spans of this format | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_format_repeat/src/main |
| type.format_shape | ACCEPTED | error[type.format_shape]: `{a}` and `{b}` have nothing between them | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_format_shape/src/main |
| type.infer_result | ACCEPTED | error[type.infer_result]: nothing here can fail — write the fn's true answer type, not `Result<T, _>` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_infer_result/src/main |
| type.list_scalar | ACCEPTED | error[type.list_scalar]: a list element takes its type from its value, and `null` has none | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_list_scalar/src/main |
| type.match_opt | ACCEPTED | error[type.match_opt]: this is always absent, so `v?` can never bind | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_match_opt/src/main |
| type.mixed_bitwise | ACCEPTED | error[type.mixed_bitwise]: `\|` and `&` in one expression have no agreed order | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_mixed_bitwise/src/main |
| type.mut_fn | ACCEPTED | error[type.mut_fn]: `mut fn` marks a method that writes its receiver — `f` has none | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_mut_fn/src/main |
| type.named | ACCEPTED | error[type.named]: `X` stands over itself | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_named/src/main |
| type.once_fn | ACCEPTED | error[type.once_fn]: `once fn seed` answers `int`, which the runtime cannot keep | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_once_fn/src/main |
| type.orphan | ACCEPTED | error[type.orphan]: `int` is the language's own type — a package adds to it only by implementing its own trait | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_orphan/src/main |
| type.param_default | ACCEPTED | error[type.param_default]: `b` has no default and follows `a`, which has one — defaulted seats come last | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_param_default/src/main |
| type.propagate | ACCEPTED | error[type.propagate]: `?` propagates a nullable, this is `int` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_propagate/src/main |
| type.quote_meta | ACCEPTED | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_quote_meta/src/main |
| type.shift_count | ACCEPTED | error[type.shift_count]: a shift count must be between 0 and 63, this is 99 | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_shift_count/src/main |
| type.static_fn | ACCEPTED | error[type.static_fn]: `static fn` marks a method with no receiver — `f` is already a plain fn | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_static_fn/src/main |
| type.static_name | ACCEPTED | error[type.static_name]: `E.a` is already a variant — a `static fn` of that name is uncallable | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_static_name/src/main |
| type.struct_scalar | ACCEPTED | error[type.struct_scalar]: a struct field cannot hold nothing | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_struct_scalar/src/main |
| type.struct_targs | ACCEPTED | error[type.struct_targs]: `G` takes 1 type argument, and this literal writes 2 | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_struct_targs/src/main |
| type.task_escape | ACCEPTED | error[type.task_escape]: a task cannot outlive the block that spawned it | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_task_escape/src/main |
| type.tparam | ACCEPTED | error[type.tparam]: `f` declares `T` more than once | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_tparam/src/main |
| type.trait_member | ACCEPTED | error[type.trait_member]: `T.a` is declared twice | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_trait_member/src/main |
| type.variadic | ACCEPTED | error[type.variadic]: `..r` takes the rest of `h`'s arguments, so it is the one seat that stands last | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_variadic/src/main |
| type.mismatch | DIFFERENT | error[type.mismatch]: `!` negates a `bool`, found `int` | error[type.mismatch]: this seat wants `bool`, found `int` |
| resolve.receiver | OTHER-ERROR | error[resolve.receiver]: `self` names a method's receiver — this is not a method | error[resolve.reserved]: `self` is a keyword |
| resolve.use_before_def | OTHER-ERROR | error[resolve.use_before_def]: `x` is used before its definition | error[resolve.runtime_binding]: `x` is a run-time binding of the top level — a fn body or a const sees declarations, not the values around i |
| type.applied | OTHER-ERROR | error[type.applied]: a map's keys are strings, not `int` | error[type.binding]: `m` declares `Map<int, int>`, this is `{}` |
| type.map_key | OTHER-ERROR | error[type.map_key]: a map's keys are strings, this is `int` | error[type.mismatch]: this seat wants `string`, found `int` |
| annotation.unread_mark | UNBUILT | error[annotation.unread_mark]: every mark is read by something that claims it | avra: the program layer doesn't build this program yet — a file that runs no statement, at annotation_unread_mark/src/main.av |
| const.cycle | UNBUILT | error[const.cycle]: a const's value asks for its own type | avra: `const_value_type` (fs11:const_cycles11:src/main.avs1:a) was asked while it was being answered, under program_refused -> file_erring - |
| flow.arm | UNBUILT | error[flow.arm]: a `select` arm waits on a task, a list of tasks, a source or a timer, and this is `int` | avra: the program layer doesn't build this program yet — an arm waiting on `int`, at the entry |
| loop.jump | UNBUILT | error[loop.jump]: `break` ends the turn of a loop around it, and no loop encloses it | avra: the program layer doesn't build this program yet — a jump outside a loop, at the entry |
| loop.label | UNBUILT | error[loop.label]: `break` names a loop by its `for` binder, and `y` is no enclosing `for`'s name here | avra: the program layer doesn't build this program yet — a jump naming no loop around it, at the entry |
| lower.no_projection | UNBUILT | error[lower.no_projection]: a `P` has no text projection, so it cannot be the program's answer | avra: the program layer doesn't build this program yet — a shown `P`, which no text spells yet, at the entry |
| parse.blockless_collect | UNBUILT | error[parse.blockless_collect]: `collect` gathers the values its block's statements leave | avra: the program layer doesn't build this program yet — `Error`, at the entry |
| parse.leading_pipe | UNBUILT | error[parse.leading_pipe]: a line never begins with `\|>` | avra: the program layer doesn't build this program yet — `Error`, at the entry |
| resolve.builtin_type | UNBUILT | error[resolve.builtin_type]: `bool` is a built-in type | avra: the program layer doesn't build this program yet — a file that runs no statement, at resolve_builtin_type/src/main.av |
| resolve.immutable | UNBUILT | error[resolve.immutable]: `x` is not `mut` | avra: the program layer doesn't build this program yet — a write to a `let`, at the entry |
| resolve.place | UNBUILT | error[resolve.place]: a mutation lands on a place — a name, a field, or an index | avra: the program layer doesn't build this program yet — a write to a value, at the entry |
| type.case | UNBUILT | error[type.case]: a `then` answers a `bool`, this one answers `int` | avra: the program layer doesn't build this program yet — a file that runs no statement, at type_case/src/main.av |
| type.catch | UNBUILT | error[type.catch]: `catch` recovers a `Result`, this is `int` | avra: the program layer doesn't build this program yet — a catch over a read whose failure is its row's own, at the entry |
| type.cell_map | UNBUILT | error[type.cell_map]: `put` inserts into the map a cell holds, and this cell holds `int` | avra: the program layer doesn't build this program yet — a write whose receiver holds no seat for it, at the entry |
| type.chain | UNBUILT | error[type.chain]: `?.` reaches into a nullable, this is `int` | avra: the program layer doesn't build this program yet — `Chain`, at the entry |
| type.coalesce | UNBUILT | error[type.coalesce]: this is always absent, so `??` always answers with the right side | PHI node operands are not the same type as the result! |
| type.enum_all | UNBUILT | error[type.enum_all]: `all` lists an enum whose variants carry nothing, and `K.B` carries a payload | avra: the program layer doesn't build this program yet — an untyped call through a type, at the entry |
| type.format | UNBUILT | error[type.format]: a format pattern reads text, found `int` | Call parameter type does not match function signature! |
| type.format_parse | UNBUILT | error[type.format_parse]: `{n: float}` reads its span as `float`, and a hole reads text as `string` or `int` | avra: index 0 is out of bounds (length 0) |
| type.fraction_pattern | UNBUILT | error[type.fraction_pattern]: `1.5` is no integer — a number pattern matches an `int` | Both operands to ICmp instruction are not of the same type! |
| type.interp_hole | UNBUILT | error[type.interp_hole]: an interpolation hole prints as a scalar or string, found `List<int>` | avra: the program layer doesn't build this program yet — a hole that isn't a number, a truth or text, at the entry |
| type.is_bind | UNBUILT | error[type.is_bind]: a payload `is` binds only in an `if` condition | avra: the program layer doesn't build this program yet — an `is` that binds or tests a type, at the entry |
| type.lambda | UNBUILT | error[type.lambda]: this is not callable — it holds a `null` | avra: the program layer doesn't build this program yet — `CallValue`, at the entry |
| type.let_else | UNBUILT | error[type.let_else]: the `else` must LEAVE — control cannot fall through to `v` | avra: the program layer doesn't build this program yet — a narrowed read, at the entry |
| type.let_pattern | UNBUILT | error[type.let_pattern]: a destructuring `let` takes the rest of a block as its scope, and a file's top level is no block | avra: the program layer doesn't build this program yet — `LetPattern`, at the entry |
| type.list | UNBUILT | error[type.list]: a comprehension walks a list, found `int` | avra: the program layer doesn't build this program yet — an untyped `Comp`, first under it an untyped `Ident`, at the entry |
| type.list_element | UNBUILT | error[type.list_element]: a list's elements share one type — the first is `int`, this is `bool` | avra: the program layer doesn't build this program yet — an untyped `ListLit`, at the entry |
| type.list_pattern | UNBUILT | error[type.list_pattern]: a list pattern matches a list, found `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.map_value | UNBUILT | error[type.map_value]: this map holds `int`, this is `bool` | avra: the program layer doesn't build this program yet — an untyped `MapLit`, at the entry |
| type.match | UNBUILT | error[type.match]: `match` chooses over an enum, found `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.member_pattern | UNBUILT | error[type.member_pattern]: `as` takes a gathered variant whole, as its member's record | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.method | UNBUILT | error[type.method]: `.reverse(…)` calls a method, and `List<int>` has none | avra: the program layer doesn't build this program yet — `List.reverse`, at the entry |
| type.named_arg | UNBUILT | error[type.named_arg]: `sub` has no seat named `c` | avra: the program layer doesn't build this program yet — a call of `sub` handing a generic unit a rest or a default its type parameters type |
| type.narrow | UNBUILT | error[type.narrow]: a type pattern narrows a `dyn` — this is `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.quote_pat_hole | UNBUILT | error[type.quote_pat_hole]: a hole in a pattern names a fresh variable — write a bare name | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_mixed | UNBUILT | error[type.quote_pat_mixed]: `x` binds code once and a name once — one binder answers one type | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_run | UNBUILT | error[type.quote_pat_run]: two run holes with nothing between them — no scan can split them | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_seat | UNBUILT | error[type.quote_pat_seat]: a hole in name position binds only a lone `${x}` — at a let/for/const binder, a bind pattern, a variant test, a  | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_shape | UNBUILT | error[type.quote_pat_shape]: a `quote` pattern matches one node — one statement, no arms | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_subj | UNBUILT | error[type.quote_pat_subj]: a `quote` pattern reads code — this program does not load `@std/avrac` | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.quote_pat_type | UNBUILT | error[type.quote_pat_type]: a hole in type position binds only a lone `${T}` — at a `let`/`mut`/`const` annotation, a call's one pinned type | avra: the program layer doesn't build this program yet — a quote pattern over `int`, which isn't code a matcher reads, at the entry |
| type.return | UNBUILT | error[type.return]: a `return` answers a fn, and there is none enclosing | avra: the program layer doesn't build this program yet — the layout of `never`, at the entry |
| type.spread | UNBUILT | error[type.spread]: `P` spreads itself | avra: `record_signature` (fs11:type_spreads11:src/main.avs1:P) was asked while it was being answered, under program_refused -> file_erring - |
| type.spread_generic | UNBUILT | error[type.spread_generic]: `G` takes type parameters, and a literal that spreads builds only a record that takes none | avra: the program layer doesn't build this program yet — `StructLit`, at the entry |
| type.spread_list | UNBUILT | error[type.spread_list]: `..` in a list spreads a list, found `int` | avra: the program layer doesn't build this program yet — an untyped `ListLit`, at the entry |
| type.spread_map | UNBUILT | error[type.spread_map]: `..` in a map spreads a map, found `int` | avra: the program layer doesn't build this program yet — a map literal's spread, at the entry |
| type.spread_nullable | UNBUILT | error[type.spread_nullable]: `..` spreads `P?`, which may be null | avra: the program layer doesn't build this program yet — `StructLit`, at the entry |
| type.spread_seat | UNBUILT | error[type.spread_seat]: `..` spreads into a seat that takes the rest of the arguments, and `g` declares none | avra: the program layer doesn't build this program yet — an untyped `Call`, at the entry |
| type.spread_value | UNBUILT | error[type.spread_value]: `..` spreads `int`, which has no fields | avra: the program layer doesn't build this program yet — `StructLit`, at the entry |
| type.type_value | UNBUILT | error[type.type_value]: `P` is a type, not a value | avra: the program layer doesn't build this program yet — `Ident`, at the entry |
| type.unknown_prop | UNBUILT | error[type.unknown_prop]: no property `x` on `int` | avra: index 0 is out of bounds (length 0) |
| type.variant_arity | UNBUILT | error[type.variant_arity]: `S.a` carries `int`, given nothing | avra: the program layer doesn't build this program yet — an untyped call through a type, at the entry |
| type.variant_lit | UNBUILT | error[type.variant_lit]: `.foo` needs a known enum — nothing here says which | avra: the program layer doesn't build this program yet — `VariantLit`, at the entry |
| type.when_arms | UNBUILT | error[type.when_arms]: a `when` needs its `_` arm | avra: the program layer doesn't build this program yet — `When`, at the entry |
| type.with_struct | UNBUILT | error[type.with_struct]: `with` copies a struct, found `int` | avra: the program layer doesn't build this program yet — `With`, at the entry |
| const.budget | SAME | error[const.budget]: a const ran past its budget | error[const.budget]: a const ran past its budget |
| flow.callback_pointer | SAME | error[flow.callback_pointer]: seat `cb` of `avra_probe_cb` is a callback under a cancel, and it answers a pointer the C would follow | error[flow.callback_pointer]: seat `cb` of `avra_probe_cb` is a callback under a cancel, and it answers a pointer the C would follow |
| parse.expected | SAME | error[parse.expected]: this cannot start or continue a `stmt` | error[parse.expected]: this cannot start or continue a `stmt` |
| resolve.duplicate_fn | SAME | error[resolve.duplicate_fn]: `f` is defined more than once | error[resolve.duplicate_fn]: `f` is defined more than once |
| resolve.duplicate_type | SAME | error[resolve.duplicate_type]: `P` is declared more than once | error[resolve.duplicate_type]: `P` is declared more than once |
| resolve.reserved | SAME | error[resolve.reserved]: `if` is a keyword | error[resolve.reserved]: `if` is a keyword |
| resolve.runtime_binding | SAME | error[resolve.runtime_binding]: `x` is a run-time binding of the top level — a fn body or a const sees declarations, not the values around i | error[resolve.runtime_binding]: `x` is a run-time binding of the top level — a fn body or a const sees declarations, not the values around i |
| resolve.unresolved | SAME | error[resolve.unresolved]: no `fn nope` is defined | error[resolve.unresolved]: no `fn nope` is defined |
| type.binding | SAME | error[type.binding]: `x` declares `int`, this is `bool` | error[type.binding]: `x` declares `int`, this is `bool` |
| type.host_absence | SAME | error[type.host_absence]: seat 1 of `avra_str_len` wears `string?`, and a runtime row's seat takes no absence | error[type.host_absence]: seat 1 of `avra_str_len` wears `string?`, and a runtime row's seat takes no absence |
| type.host_fn | SAME | error[type.host_fn]: `avra_bool_text` is the runtime's own symbol — a host fn cannot define it again | error[type.host_fn]: `avra_bool_text` is the runtime's own symbol — a host fn cannot define it again |
| type.host_seat | SAME | error[type.host_seat]: seat 1 of `c_count` is `mut` and wears `string` — a `mut` host seat hands C the ADDRESS of the caller's cell | error[type.host_seat]: seat 1 of `c_count` is `mut` and wears `string` — a `mut` host seat hands C the ADDRESS of the caller's cell |
| type.impl | SAME | error[type.impl]: `impl Nope` serves no declared type | error[type.impl]: `impl Nope` serves no declared type |
| type.place | SAME | error[type.place]: `xs` is not `mut` — `push` mutates it | error[type.place]: `xs` is not `mut` — `push` mutates it |
| type.row_shape | SAME | error[type.row_shape]: `avra_array_new` is a runtime row of 0 seat(s), declared here with 1 | error[type.row_shape]: `avra_array_new` is a runtime row of 0 seat(s), declared here with 1 |
| type.seat | SAME | error[type.seat]: seat 1 of `f` is `mut`, and this is a value | error[type.seat]: seat 1 of `f` is `mut`, and this is a value |
| type.struct_fields | SAME | error[type.struct_fields]: field `x` is `int`, this is `bool` | error[type.struct_fields]: field `x` is `int`, this is `bool` |
| type.unknown | SAME | error[type.unknown]: `decimal` names no type | error[type.unknown]: `decimal` names no type |
| resolve.unpackaged | OLD-SILENT |  | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/resolve_unpackaged/src/main |
| type.coalesce_never | OLD-SILENT |  | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_coalesce_never/src/main |
| type.map_entry | OLD-SILENT |  | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_map_entry/src/main |
| type.seat_unused | OLD-SILENT |  | /tmp/claude-0/-home-user/d3c61785-f5e5-5973-9293-00598934e751/scratchpad/diff/pk/type_seat_unused/src/main |
| type.spread_dead | OLD-SILENT |  | avra: the program layer doesn't build this program yet — `StructLit`, at the entry |
| type.to_int | OLD-SILENT |  | avra: the program layer doesn't build this program yet — `float.floor`, at the entry |
