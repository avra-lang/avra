| code | verdict | owner (guess) | old first line | program layer first line |
|---|---|---|---|---|
| const.cycle | COMPILER-DEFECT | embed | error[const.cycle]: a const's value asks for its own type | exit 2: avra: `const_value_type` (fs3:apps11:src/main.avs1:a) was asked while it was being answered, under program_refused -> file_erring -> |
| type.coalesce | COMPILER-DEFECT | seat-laws | error[type.coalesce]: this is always absent, so `??` always answers with the right side | exit 1: PHI node operands are not the same type as the result! |
| type.extern_value | COMPILER-DEFECT | seat-laws | error[type.extern_value]: an extern fn is not a value — it names a C symbol, not an Avra fn | exit -6: [CRASH] avra_llvm_fn_type_of: fn_val is NULL |
| type.fraction_pattern | COMPILER-DEFECT | seat-laws | error[type.fraction_pattern]: `1.5` is no integer — a number pattern matches an `int` | exit 1: Both operands to ICmp instruction are not of the same type! |
| type.spread | COMPILER-DEFECT | seat-laws | error[type.spread]: `P` spreads itself | exit 2: avra: `record_signature` (fs3:apps11:src/main.avs1:P) was asked while it was being answered, under program_refused -> file_erring -> |
| type.unknown_prop | COMPILER-DEFECT | seat-laws | error[type.unknown_prop]: no property `x` on `int` | exit 2: avra: index 0 is out of bounds (length 0) |
| manifest.link_option | COMPILER-DEFECT | type-refusals | error[manifest.link_option]: `libs` takes library names, and `-lm` spells a linker option | exit 1: avra: the link failed: ld.lld: error: unable to find library -l-lm |
| resolve.reexport_unreached | COMPILER-DEFECT | type-refusals | error[resolve.reexport_unreached]: `b` re-exports `x`, and no declaration stands behind it | exit 2: avra: `file_generated` (fs3:apps8:src/a.av) was asked while it was being answered, under package_generated_impls -> file_generated - |
| type.format | COMPILER-DEFECT | type-refusals | error[type.format]: a format pattern reads text, found `int` | exit 1: Call parameter type does not match function signature! |
| type.format_parse | COMPILER-DEFECT | type-refusals | error[type.format_parse]: `{n: float}` reads its span as `float`, and a hole reads text as `string` or `int` | exit 2: avra: index 0 is out of bounds (length 0) |
| lower.host_fn_answers | COMPILER-DEFECT | whole-program | error[lower.host_fn_answers]: `page_row` is `@x/near`'s to name, and `@x/far` answers it — only the package that names an extern, or the pro | exit 1: avra: the link failed: ld.lld: error: undefined symbol: page_row |
| lower.host_fn_unasked | COMPILER-DEFECT | whole-program | error[lower.host_fn_unasked]: the host fn `far_event` of `@x/far` would be this program's export, and the program's own sources never import | exit 1: avra: the link failed: ld.lld: error: undefined symbol: page_row |
| lower.host_fn_unhosted | COMPILER-DEFECT | whole-program | error[lower.host_fn_unhosted]: the host fn `far_event` of `@x/far` names no host, so no build can say whose it is | exit 1: avra: the link failed: ld.lld: error: undefined symbol: page_row |
| flow.unbounded_cleanup | ACCEPTED | body-laws | error[flow.unbounded_cleanup]: this `defer`'s body waits, and no `within` it writes bounds the wait — it calls the runtime row `avra_fiber_s |  |
| collect.dense | ACCEPTED | decl-shape | error[collect.dense]: `it.mark.args[0]` is not unique and gap-free from 0 |  |
| collect.fields | ACCEPTED | decl-shape | error[collect.fields]: `Entry`'s fields are not each filled exactly once — missing module |  |
| collect.kind | ACCEPTED | decl-shape | error[collect.kind]: `spell` is not a declaration kind `collect` gathers yet |  |
| collect.not_a_list | ACCEPTED | decl-shape | error[collect.not_a_list]: `collect xs` must declare a `List<T>` |  |
| collect.not_a_record | ACCEPTED | decl-shape | error[collect.not_a_record]: `int` has no fields a projection can fill |  |
| collect.order | ACCEPTED | decl-shape | error[collect.order]: a collection declares its order — `by …` |  |
| collect.order_key | ACCEPTED | decl-shape | error[collect.order_key]: `it.nope` is not a field this kind's declarations answer |  |
| collect.order_mixed | ACCEPTED | decl-shape | error[collect.order_mixed]: `it.mark.args[0]` mixes int and string arguments — a `by` column is one kind |  |
| collect.order_uncomparable | ACCEPTED | decl-shape | error[collect.order_uncomparable]: `it.mark` is not a value a `by` key can compare |  |
| collect.path | ACCEPTED | decl-shape | error[collect.path]: `it.label` is not a field this kind's declarations answer |  |
| collect.proj_type | ACCEPTED | decl-shape | error[collect.proj_type]: `as Other` disagrees with the declared element `Entry` |  |
| collect.scope | ACCEPTED | decl-shape | error[collect.scope]: `everywhere` is not a collect scope |  |
| collect.self_read | ACCEPTED | decl-shape | error[collect.self_read]: `cyclic` is collected into `xs`, so it cannot read `xs` while compiling |  |
| collect_enum.member | ACCEPTED | decl-shape | error[collect_enum.member]: a gathered variant carries fixed types — `Wrap` takes type parameters |  |
| collect_enum.scope | ACCEPTED | decl-shape | error[collect_enum.scope]: an enum's variants are one set for every reader — `S` gathers `in closure`, which is what imports have reached so |  |
| collect_enum.self | ACCEPTED | decl-shape | error[collect_enum.self]: `Rank.versus` takes `Self` and answers `int` — members of different variants have no such answer |  |
| collect_enum.tie | ACCEPTED | decl-shape | error[collect_enum.tie]: an enum's `by` order is its variants' ordinals — two members share a key |  |
| collect_enum.variant | ACCEPTED | decl-shape | error[collect_enum.variant]: `Command` declares `run` more than once |  |
| type.trait | ACCEPTED | decl-shape | error[type.trait]: `extra` is not part of `T` — an impl-for holds only the trait's methods |  |
| type.binds_twice | ACCEPTED | seat-laws | error[type.binds_twice]: this pattern binds `n` twice — a name binds one value |  |
| type.builtin_name | ACCEPTED | seat-laws | error[type.builtin_name]: `string` already answers `length` — an impl on a builtin type adds names, it never changes one |  |
| type.const_seat | ACCEPTED | seat-laws | error[type.const_seat]: `n` is a `const` seat — `take` settles it at compile time, and this is computed at run time |  |
| type.contract_write | ACCEPTED | seat-laws | error[type.contract_write]: `a` writes through `self`, but `T.a` declares no `mut` |  |
| type.isolated | ACCEPTED | seat-laws | error[type.isolated]: `make` of `run` is `isolated`, and this fn captures `c`, which is `Cell<int>` — an isolated fn shares nothing with its |  |
| type.sealed | ACCEPTED | seat-laws | error[type.sealed]: `Url` is sealed — only `urls`, the module that declares it, builds or rewrites one |  |
| type.spread_field | ACCEPTED | seat-laws | error[type.spread_field]: this spread carries `w`, and `P` declares no such field |  |
| type.state_seat | ACCEPTED | seat-laws | error[type.state_seat]: `state n` is a free fn's seat — a method has no caller's cell to reach |  |
| type.syntax_action | ACCEPTED | seat-laws | error[type.syntax_action]: references undefined rule `nothing` |  |
| flow.arm_binder | ACCEPTED | select-lowering | error[flow.arm_binder]: `i` counts a list's members, and this arm waits on one task |  |
| flow.no_fate | ACCEPTED | select-lowering | error[flow.no_fate]: a handler that can fail must name a fate for its failure, and `work` names none |  |
| flow.spent_arm | ACCEPTED | select-lowering | error[flow.spent_arm]: a list arm is taken once, so no loop holds it |  |
| annotation.answer | ACCEPTED | type-refusals | error[annotation.answer]: an annotation answers an effect |  |
| annotation.derive | ACCEPTED | type-refusals | error[annotation.derive]: an annotation derives through a trait that declares `derive` |  |
| annotation.kind | ACCEPTED | type-refusals | error[annotation.kind]: an annotation's kind is a word |  |
| annotation.meta | ACCEPTED | type-refusals | error[annotation.meta]: the compiler crosses `@std/meta`'s own shapes |  |
| annotation.said | ACCEPTED | type-refusals | error[annotation.said]: `f` is plain |  |
| annotation.seats | ACCEPTED | type-refusals | error[annotation.seats]: an annotation's arguments fill its seats |  |
| annotation.unplaceable | ACCEPTED | type-refusals | error[annotation.unplaceable]: a hole was filled with something no seat can hold |  |
| annotation.unsettled | ACCEPTED | type-refusals | error[annotation.unsettled]: an annotation could not run |  |
| manifest.bad_budget | ACCEPTED | type-refusals | error[manifest.bad_budget]: `[lifted] steps` is a count of at least 1 |  |
| manifest.bad_name | ACCEPTED | type-refusals | error[manifest.bad_name]: a package is named `@scope/name` — `Bad Name` is not |  |
| manifest.bad_opt_level | ACCEPTED | type-refusals | error[manifest.bad_opt_level]: `opt_level` is 0, 1, 2, 3, "s" or "z" |  |
| manifest.bad_path | ACCEPTED | type-refusals | error[manifest.bad_path]: `@x/y` points at `/tmp/tmp.1xceEaZEAG/cases/manifest.bad_path/w/nowhere`, which holds no `avra.toml` |  |
| manifest.bad_profile | ACCEPTED | type-refusals | error[manifest.bad_profile]: a profile name is `[a-z0-9_-]+` — `Bad` is not |  |
| manifest.bad_tool_from | ACCEPTED | type-refusals | error[manifest.bad_tool_from]: `git` comes from `nowhere` — a tool comes from `path`, `env` or `abs` |  |
| manifest.bad_version | ACCEPTED | type-refusals | error[manifest.bad_version]: a version is `MAJOR.MINOR.PATCH` — `one` is not |  |
| manifest.borrowed_raw | ACCEPTED | type-refusals | error[manifest.borrowed_raw]: `@acme/dep` asks for raw linker options, and `[link.raw]` is the program's own |  |
| manifest.cycle | ACCEPTED | type-refusals | error[manifest.cycle]: packages depend in a cycle: @x/root -> @x/y -> @x/root |  |
| manifest.duplicate_package | ACCEPTED | type-refusals | error[manifest.duplicate_package]: `@x/y` is claimed by two directories: `/tmp/tmp.1xceEaZEAG/cases/manifest.duplicate_package/w/vendor/y` a |  |
| manifest.lib_name | ACCEPTED | type-refusals | error[manifest.lib_name]: a library is named for its package — `app` is `app`, not `other` |  |
| manifest.link_flag | ACCEPTED | type-refusals | error[manifest.link_flag]: `dynamic_symbols` under `[link]` is `true` or `false` |  |
| manifest.name_mismatch | ACCEPTED | type-refusals | error[manifest.name_mismatch]: the package at `/tmp/tmp.1xceEaZEAG/cases/manifest.name_mismatch/w/vendor/y` calls itself `@x/z`, not `@x/y` |  |
| manifest.no_name | ACCEPTED | type-refusals | error[manifest.no_name]: `[package]` needs a name — `name = "@scope/name"` |  |
| manifest.no_package | ACCEPTED | type-refusals | error[manifest.no_package]: a manifest declares its package — `[package]` is missing |  |
| manifest.no_version | ACCEPTED | type-refusals | error[manifest.no_version]: `[package]` needs a version — `version = "0.1.0"` |  |
| manifest.prelude_floor | ACCEPTED | type-refusals | error[manifest.prelude_floor]: `@std/prelude` depends on nothing — it is the floor every package stands on |  |
| manifest.self_dependency | ACCEPTED | type-refusals | error[manifest.self_dependency]: `app` is this package — a package does not depend on itself |  |
| manifest.syntax | ACCEPTED | type-refusals | error[manifest.syntax]: `[package]` is declared twice — the first stays, and this one's keys are not read |  |
| manifest.tool_abs_at | ACCEPTED | type-refusals | error[manifest.tool_abs_at]: `cc` is an absolute tool and names no `at` |  |
| manifest.tool_env_var | ACCEPTED | type-refusals | error[manifest.tool_env_var]: `cc` comes from the environment and names no `var` |  |
| manifest.unknown_process_key | ACCEPTED | type-refusals | error[manifest.unknown_process_key]: `frobnicate` is not a key of a tool row — and `[process]` bounds what this program may run |  |
| manifest.unscoped_dependency | ACCEPTED | type-refusals | error[manifest.unscoped_dependency]: a dependency is named `@scope/name` — `y` has no scope |  |
| manifest.unset_link_variable | ACCEPTED | type-refusals | error[manifest.unset_link_variable]: `${NOPE_VAR}/lib` in `search` needs `NOPE_VAR`, which is not set — without it the word names another pa |  |
| manifest.unsupported_dependency | ACCEPTED | type-refusals | error[manifest.unsupported_dependency]: `@x/y` is not a path dependency — only `{ path = "…" }` resolves |  |
| resolve.block_word | ACCEPTED | type-refusals | error[resolve.block_word]: `work` is a block word here, and nothing else in this file may wear it |  |
| resolve.export_kind | ACCEPTED | type-refusals | error[resolve.export_kind]: `export` marks a fn, type, enum or trait — not this statement |  |
| resolve.import_clash | ACCEPTED | type-refusals | error[resolve.import_clash]: `f` is listed twice |  |
| resolve.module_ambiguous | ACCEPTED | type-refusals | error[resolve.module_ambiguous]: `util` is both a directory and a file under the root |  |
| resolve.no_module | ACCEPTED | type-refusals | error[resolve.no_module]: no module `nope` under the package's source root |  |
| resolve.not_a_dependency | ACCEPTED | type-refusals | error[resolve.not_a_dependency]: `@x/y` is not a dependency of this package |  |
| resolve.not_exported | ACCEPTED | type-refusals | error[resolve.not_exported]: `util` does not export `hidden` |  |
| resolve.package_form | ACCEPTED | type-refusals | error[resolve.package_form]: `@solo` names no package — a package is `@scope.name` |  |
| resolve.private_apart | ACCEPTED | type-refusals | error[resolve.private_apart]: `h` is private to each of `a.av` and `b.av` in `util` — a test reads a private name its module declares once |  |
| resolve.unpackaged | ACCEPTED | type-refusals | error[resolve.no_module]: no module `util` under the package's source root |  |
| type.component_check | ACCEPTED | type-refusals | error[type.component_check]: a component's `check` answers `List<Diagnostic>` and takes nothing — this answers `int` |  |
| type.component_format | ACCEPTED | type-refusals | error[type.component_format]: a `Format` head is `@std.meta`'s pattern type, and `path`'s `Format` names another |  |
| type.component_row | ACCEPTED | type-refusals | error[type.component_row]: a repeated `tick` keeps state and wears no key, so its state stays with its place and lands on whichever row hold |  |
| type.match_opt | ACCEPTED | type-refusals | error[type.match_opt]: this is always absent, so `v?` can never bind |  |
| lower.entry_only | ACCEPTED | whole-program | error[lower.entry_only]: a module file holds declarations — only the entry `/tmp/tmp.1xceEaZEAG/cases/lower.entry_only/w/src/main.av` runs s |  |
| lower.host_fn_shadows | ACCEPTED | whole-program | error[lower.host_fn_shadows]: `malloc` is a platform symbol — a host fn of that name would answer every caller of it |  |
| lower.host_fn_twice | ACCEPTED | whole-program | error[lower.host_fn_twice]: two host fns define `far_event` — a symbol has one body |  |
| type.applied | OTHER-ERROR | seat-laws | error[type.applied]: a map's keys are strings, not `int` | error[type.binding]: `m` declares `Map<int, int>`, this is `{}` |
| type.kept_arm | OTHER-ERROR | seat-laws | error[type.kept_arm]: a kept arm answers one `int`, and this one answers `List<int>` | error[type.mismatch]: this seat wants `int`, found `List<int>` |
| type.map_key | OTHER-ERROR | seat-laws | error[type.map_key]: a map's keys are strings, this is `int` | error[type.mismatch]: this seat wants `string`, found `int` |
| annotation.unread_mark | OTHER-ERROR | type-refusals | error[annotation.unread_mark]: every mark is read by something that claims it | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| resolve.kept_apart | OTHER-ERROR | type-refusals | error[resolve.kept_apart]: `h` is private to each of `a.av` and `b.av` — a private name two files declare is each file's own | error[resolve.unresolved]: no `fn h` is defined |
| resolve.reexport_twice | OTHER-ERROR | type-refusals | error[resolve.reexport_twice]: `f` is already on this module's surface | error[resolve.unresolved]: no `fn f` is defined |
| resolve.reserved | OTHER-ERROR | type-refusals | error[resolve.reserved]: `if` is a keyword | error[resolve.unresolved]: no `fn if` is defined |
| type.quote_pat_hole | OTHER-ERROR | type-refusals | error[type.quote_pat_hole]: a hole in a pattern names a fresh variable — write a bare name | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_mixed | OTHER-ERROR | type-refusals | error[type.quote_pat_mixed]: `x` binds code once and a name once — one binder answers one type | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_run | OTHER-ERROR | type-refusals | error[type.quote_pat_run]: two run holes with nothing between them — no scan can split them | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_seat | OTHER-ERROR | type-refusals | error[type.quote_pat_seat]: a hole in name position binds only a lone `${x}` — at a let/for/const binder, a bind pattern, a variant test, a  | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_shape | OTHER-ERROR | type-refusals | error[type.quote_pat_shape]: a `quote` pattern matches one node — one statement, no arms | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_subj | OTHER-ERROR | type-refusals | error[type.quote_pat_subj]: a `quote` pattern reads code — this program does not load `@std/avrac` | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.quote_pat_type | OTHER-ERROR | type-refusals | error[type.quote_pat_type]: a hole in type position binds only a lone `${T}` — at a `let`/`mut`/`const` annotation, a call's one pinned type | error[type.quote_meta]: a `quote` answers `@std.meta.Code`, and this program does not load `@std/meta` |
| type.mismatch | DIFFERENT | seat-laws | error[type.mismatch]: `!` negates a `bool`, found `int` | error[type.mismatch]: this seat wants `bool`, found `int` |
| flow.guard_binder | UNBUILT | body-laws | error[flow.guard_binder]: a guard is read before its arm's head, so it reads no name the arm binds | avra: the program layer doesn't build this program yet — `Ident`, at the entry |
| loop.jump | UNBUILT | body-laws | error[loop.jump]: `break` ends the turn of a loop around it, and no loop encloses it | avra: the program layer doesn't build this program yet — a jump outside a loop, at the entry |
| loop.label | UNBUILT | body-laws | error[loop.label]: `break` names a loop by its `for` binder, and `y` is no enclosing `for`'s name here | avra: the program layer doesn't build this program yet — a jump naming no loop around it, at the entry |
| resolve.builtin_type | UNBUILT | decl-shape | error[resolve.builtin_type]: `bool` is a built-in type | avra: the program layer doesn't build this program yet — a file that runs no statement, at app/src/main.av |
| resolve.duplicate_case | UNBUILT | decl-shape | error[resolve.duplicate_case]: `s / g` declares `t` more than once | avra: the program layer doesn't build this program yet — a file that runs no statement, at app/src/main.av |
| type.named_arg | UNBUILT | decl-shape | error[type.named_arg]: `sub` has no seat named `c` | avra: the program layer doesn't build this program yet — a call of `sub` handing a generic unit a rest or a default its type parameters type |
| const.form | UNBUILT | embed | error[const.form]: a computed const needs a compile-time value form | avra: the program layer doesn't build this program yet — a call of `f`, which names a value, at the entry |
| type.case | UNBUILT | seat-laws | error[type.case]: a `then` answers a `bool`, this one answers `int` | avra: the program layer doesn't build this program yet — a file that runs no statement, at app/src/main.av |
| type.cell_map | UNBUILT | seat-laws | error[type.cell_map]: `put` inserts into the map a cell holds, and this cell holds `int` | avra: the program layer doesn't build this program yet — a write whose receiver holds no seat for it, at the entry |
| type.chain | UNBUILT | seat-laws | error[type.chain]: `?.` reaches into a nullable, this is `int` | avra: the program layer doesn't build this program yet — `Chain`, at the entry |
| type.code_hash_named | UNBUILT | seat-laws | error[type.code_hash_named]: `code_hash` hashes a declared fn, named where it is called | avra: the program layer doesn't build this program yet — a code hash of what names no declared fn, at the entry |
| type.enum_all | UNBUILT | seat-laws | error[type.enum_all]: `all` lists an enum whose variants carry nothing, and `K.B` carries a payload | avra: the program layer doesn't build this program yet — an untyped call through a type, at the entry |
| type.is_bind | UNBUILT | seat-laws | error[type.is_bind]: a payload `is` binds only in an `if` condition | avra: the program layer doesn't build this program yet — an `is` that binds or tests a type, at the entry |
| type.lambda | UNBUILT | seat-laws | error[type.lambda]: this is not callable — it holds a `null` | avra: the program layer doesn't build this program yet — `CallValue`, at the entry |
| type.list | UNBUILT | seat-laws | error[type.list]: a comprehension walks a list, found `int` | avra: the program layer doesn't build this program yet — an untyped `Comp`, first under it an untyped `Ident`, at the entry |
| type.list_element | UNBUILT | seat-laws | error[type.list_element]: a list's elements share one type — the first is `int`, this is `bool` | avra: the program layer doesn't build this program yet — an untyped `ListLit`, at the entry |
| type.list_pattern | UNBUILT | seat-laws | error[type.list_pattern]: a list pattern matches a list, found `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.map_value | UNBUILT | seat-laws | error[type.map_value]: this map holds `int`, this is `bool` | avra: the program layer doesn't build this program yet — an untyped `MapLit`, at the entry |
| type.member_pattern | UNBUILT | seat-laws | error[type.member_pattern]: `as` takes a gathered variant whole, as its member's record | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.method | UNBUILT | seat-laws | error[type.method]: `.reverse(…)` calls a method, and `List<int>` has none | avra: the program layer doesn't build this program yet — `List.reverse`, at the entry |
| type.narrow | UNBUILT | seat-laws | error[type.narrow]: a type pattern narrows a `dyn` — this is `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.not_offered | UNBUILT | seat-laws | error[type.not_offered]: `reqq` is not offered here — this seat offers `req`, `db` | avra: the program layer doesn't build this program yet — `Lambda`, at the entry |
| type.or_binds | UNBUILT | seat-laws | error[type.or_binds]: every alternative of an `or` arm binds the same names — the first binds `n`, alternative 2 binds nothing | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.pattern | UNBUILT | seat-laws | error[type.pattern]: `.x` tests a variant, but this is `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.record_pattern | UNBUILT | seat-laws | error[type.record_pattern]: `P { … }` matches a record, found `int` | avra: the program layer doesn't build this program yet — a match whose patterns aren't each one variant or the rest, at the entry |
| type.return | UNBUILT | seat-laws | error[type.return]: a `return` answers a fn, and there is none enclosing | avra: the program layer doesn't build this program yet — the layout of `never`, at the entry |
| type.spread_generic | UNBUILT | seat-laws | error[type.spread_generic]: `G` takes type parameters, and a literal that spreads builds only a record that takes none | avra: the program layer doesn't build this program yet — an untyped record literal `G`, at the entry |
| type.spread_list | UNBUILT | seat-laws | error[type.spread_list]: `..` in a list spreads a list, found `int` | avra: the program layer doesn't build this program yet — an untyped `ListLit`, at the entry |
| type.spread_map | UNBUILT | seat-laws | error[type.spread_map]: `..` in a map spreads a map, found `int` | avra: the program layer doesn't build this program yet — an untyped `MapLit`, at the entry |
| type.spread_nullable | UNBUILT | seat-laws | error[type.spread_nullable]: `..` spreads `P?`, which may be null | avra: the program layer doesn't build this program yet — a record literal spreading what isn't a record, at the entry |
| type.spread_seat | UNBUILT | seat-laws | error[type.spread_seat]: `..` spreads into a seat that takes the rest of the arguments, and `g` declares none | avra: the program layer doesn't build this program yet — a call of `g` handing a generic unit a rest or a default its type parameters type,  |
| type.spread_value | UNBUILT | seat-laws | error[type.spread_value]: `..` spreads `int`, which has no fields | avra: the program layer doesn't build this program yet — a record literal spreading what isn't a record, at the entry |
| type.type_value | UNBUILT | seat-laws | error[type.type_value]: `P` is a type, not a value | avra: the program layer doesn't build this program yet — `Ident`, at the entry |
| type.variant_arity | UNBUILT | seat-laws | error[type.variant_arity]: `S.a` carries `int`, given nothing | avra: the program layer doesn't build this program yet — an untyped call through a type, at the entry |
| type.variant_lit | UNBUILT | seat-laws | error[type.variant_lit]: `.foo` needs a known enum — nothing here says which | avra: the program layer doesn't build this program yet — `VariantLit`, at the entry |
| type.when_arms | UNBUILT | seat-laws | error[type.when_arms]: a `when` needs its `_` arm | avra: the program layer doesn't build this program yet — `When`, at the entry |
| type.with_struct | UNBUILT | seat-laws | error[type.with_struct]: `with` copies a struct, found `int` | avra: the program layer doesn't build this program yet — `With`, at the entry |
| flow.arm | UNBUILT | select-lowering | error[flow.arm]: a `select` arm waits on a task, a list of tasks, a source or a timer, and this is `int` | avra: the program layer doesn't build this program yet — an arm waiting on `int`, at the entry |
| resolve.immutable | UNBUILT | type-refusals | error[resolve.immutable]: `x` is not `mut` | avra: the program layer doesn't build this program yet — a write to a `let`, at the entry |
| resolve.place | UNBUILT | type-refusals | error[resolve.place]: a mutation lands on a place — a name, a field, or an index | avra: the program layer doesn't build this program yet — a write to a value, at the entry |
| type.catch | UNBUILT | type-refusals | error[type.catch]: `catch` recovers a `Result`, this is `int` | avra: the program layer doesn't build this program yet — a catch over a read whose failure is its row's own, at the entry |
| type.interp_hole | UNBUILT | type-refusals | error[type.interp_hole]: an interpolation hole prints as a scalar or string, found `List<int>` | avra: the program layer doesn't build this program yet — a hole that isn't a number, a truth or text, at the entry |
| type.let_else | UNBUILT | type-refusals | error[type.let_else]: the `else` must LEAVE — control cannot fall through to `v` | avra: the program layer doesn't build this program yet — a narrowed read, at the entry |
| type.let_pattern | UNBUILT | type-refusals | error[type.let_pattern]: a destructuring `let` takes the rest of a block as its scope, and a file's top level is no block | avra: the program layer doesn't build this program yet — `LetPattern`, at the entry |
| lower.component_checked | UNBUILT | whole-program | error[lower.component_checked]: a port is 1 to 65535, this is 70000 | avra: the program layer doesn't build this program yet — `Prop`, at the entry |
| lower.no_projection | UNBUILT | whole-program | error[lower.no_projection]: a `P` has no text projection, so it cannot be the program's answer | avra: the program layer doesn't build this program yet — a shown `P`, which no text spells yet, at the entry |
| type.coalesce_never | WARN-MISSING | seat-laws | warning[type.coalesce_never]: `??` never fires — `int` is never absent |  |
| type.const_pattern | WARN-MISSING | seat-laws | warning[type.const_pattern]: `a` is a const here, so this arm compares |  |
| type.receiver | WARN-MISSING | seat-laws | warning[type.receiver]: `b` is not `mut` — `put` writes through it |  |
| type.registry_hole | WARN-MISSING | seat-laws | warning[type.registry_hole]: arms answer for several variants and this hole takes the rest: .C, .D |  |
| type.spread_dead | WARN-MISSING | seat-laws | warning[type.spread_dead]: field `x` is overwritten by a spread after it |  |
| type.unreachable_arm | WARN-MISSING | seat-laws | warning[type.unreachable_arm]: this arm is never reached — `gone` above binds, and takes every value |  |
| annotation.warning | WARN-MISSING | type-refusals | warning[annotation.warning]: `sum` is deprecated — use add |  |
| manifest.unknown_key | WARN-MISSING | type-refusals | warning[manifest.unknown_key]: `frobnicate` is not a key of `[package]` |  |
| manifest.unknown_section | WARN-MISSING | type-refusals | warning[manifest.unknown_section]: `[nonsense]` is not a section this compiler reads |  |
| type.map_entry | OLD-SILENT | seat-laws | exit 0 |  |
| type.to_int | OLD-SILENT | seat-laws | exit 0 |  |
| flow.end_arm | STD-ROOT | body-laws |  |  |
| const.reach | STD-ROOT | embed |  |  |
| type.within | STD-ROOT | seat-laws |  |  |
| resolve.reexport_cycle | STD-ROOT | type-refusals |  |  |
| language.defect | BEYOND | ? | it is the compiler blaming its own grammar or builders, which no program can cause |  |
| shape.identity_clash | BEYOND | ? | two variant names fold to one 64-bit identity, which no source can be written to produce — the refusal is reached only by a hash collision |  |
| flow.broken | BEYOND | body-laws | `@unbroken` resolves to `@std/meta`'s own declaration, which a lone source cannot import — the golden is compiler/tests/unbroken_test.av |  |
| flow.fresh_deadline | BEYOND | body-laws | a timer is `@std/time`'s own declaration, which a lone source cannot import — the golden is features/select_expr/tests/select_expr_test.av |  |
| flow.never_ends | BEYOND | body-laws | a `channel` needs `@std/task`'s carrier, which a lone source cannot import — the golden is features/tasks/tests/channel_test.av |  |
| flow.quiet_never | BEYOND | body-laws | a timer is `@std/time`'s own declaration, which a lone source cannot import — the golden is features/select_expr/tests/select_expr_test.av |  |
| type.guard_value | BEYOND | seat-laws | `guarded` is `@std/meta`'s own declaration, which a lone source cannot import — the golden is features/fns/tests/contained_test.av |  |
| type.identity_field | BEYOND | seat-laws | `@identity` resolves to `@std/meta`'s own declaration, which a lone source cannot import — the golden is features/structs/tests/identity_tes |  |
| type.lacks | BEYOND | seat-laws | `@lacks` resolves to `@std/meta`'s own declaration, which a lone source cannot import — the golden is features/structs/tests/lacks_test.av |  |
| type.plan_residual | BEYOND | seat-laws | a planned relation's `@plans` marks come from `@std/meta`, which a lone source cannot import — the golden is features/lists/tests/plan_test. |  |
| type.plan_scan | BEYOND | seat-laws | a planned relation's `@plans` marks come from `@std/meta`, which a lone source cannot import — the golden is features/lists/tests/plan_test. |  |
| type.plans_mismatch | BEYOND | seat-laws | a planned relation's `@plans` marks come from `@std/meta`, which a lone source cannot import — the golden is features/lists/tests/plan_test. |  |
| type.provided_kind | BEYOND | seat-laws | `provided` is `@std/meta`'s, which a lone source cannot import — the golden is features/fns/tests/provided_test.av |  |
| annotation.generated_taken | BEYOND | type-refusals | the real `@std/meta` ships no annotator that generates a twin or wraps a fn, so the fixtures are the suite's own — the golden is features/an |  |
| annotation.wrap_bodiless | BEYOND | type-refusals | the real `@std/meta` ships no annotator that generates a twin or wraps a fn, so the fixtures are the suite's own — the golden is features/an |  |
| annotation.wrap_kind | BEYOND | type-refusals | a declaration with a body root that is no fn or method is a seat default or a spec case, and no annotation can stand on either — `@a` before |  |
| annotation.wrap_mismatch | BEYOND | type-refusals | the real `@std/meta` ships no annotator that generates a twin or wraps a fn, so the fixtures are the suite's own — the golden is features/an |  |
| annotation.wrap_missing | BEYOND | type-refusals | the real `@std/meta` ships no annotator that generates a twin or wraps a fn, so the fixtures are the suite's own — the golden is features/an |  |
| manifest.no_source | BEYOND | type-refusals | it names a directory's own shape — no src/ and no direct .av file — which no lone source text can stand in for |  |
| manifest.no_target | BEYOND | type-refusals | it is what `avra run` says of a package with no entry, which a check never asks |  |
| resolve.hole_bound | BEYOND | type-refusals | a binder named through a hole comes from a derive, which a lone source cannot import — the golden is features/quote/tests/seat_hygiene_test. |  |
| type.component_event | BEYOND | type-refusals | an instance's component is another file's, which a lone source cannot import — the golden is features/components/tests/components_test.av |  |
| type.component_expand | BEYOND | type-refusals | a component's `expand` answers `@std/meta`'s `Code`, which a lone source cannot import — the golden is features/components/tests/components_ |  |
| type.component_head | BEYOND | type-refusals | an instance's component is another file's, which a lone source cannot import — the golden is features/components/tests/components_head_test. |  |
| type.component_twice | BEYOND | type-refusals | a template is a `quote` of `@std/meta`'s `Code`, which a lone source cannot import — the golden is features/components/tests/components_temp |  |
| lower.code_hash_const | BEYOND | whole-program | the refusal is spoken inside a const's settlement and reaches a program as `const.trap` carrying its words — the golden is compiler/tests/co |  |
| type.alias_copy | WARNED | decl-shape | warning[type.alias_copy]: `q` is a copy of `p` — a write through it will not reach `p` | warning[type.alias_copy]: `q` is a copy of `p` — a write through it will not reach `p` |
| type.mut_fn_unused | WARNED | decl-shape | warning[type.mut_fn_unused]: `mut fn` — `get` never writes through `self` | warning[type.mut_fn_unused]: `mut fn` — `get` never writes through `self` |
| type.seat_unused | WARNED | seat-laws | warning[type.seat_unused]: `n` is a `mut` seat — `show` never writes through it | warning[type.seat_unused]: `n` is a `mut` seat — `show` never writes through it |

witness_program_differential: 13 COMPILER-DEFECT, 82 ACCEPTED, 14 OTHER-ERROR, 1 DIFFERENT, 46 UNBUILT, 9 WARN-MISSING, 2 OLD-SILENT, 4 STD-ROOT, 26 BEYOND, 3 WARNED, 84 SAME — 284 codes
