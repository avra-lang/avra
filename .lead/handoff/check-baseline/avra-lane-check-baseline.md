# avra-lane-check-baseline: steps 0–2

Branch avra-lane-check-baseline, merged with program e8760228. The bundle is program..branch: 1ec3670, fe11c2b, 56fb7c9 (step 0), 162ba8e (steps 1–2), plus merges.

## Step 0: `avra check --baseline` on the program layer
- check.av routes to check_program.av when AVRA_PROGRAM=1, the path is a package dir, `--baseline` is given and not `--baseline_accept`.
- The check reads saved per-file rows: query `file_rule_rows` (std-avrac compiler/item_rules.av).
- A law error refuses (program_erring). A NEW site refuses (Baseline.news, unchanged). It refuses while any rule is unheld, naming each one.

## Steps 1–2: fact rules written once, through RuleFacts
- features/code.av:
  - `Code = { of: RuleFile, at }`, with `RuleFile = { view: SyntaxView, facts: RuleFacts }`.
  - `enum RuleFacts { Analysed(Analysed) | Typed(types, package, seat_fns) }` answers `type_at`, `package`, `seat_fns`.
  - `RuleType` (Interned | Signed) answers `is_text`, `is_declared(DeclaredType{package,name})`, `element`, `carried`, `same` (`same_type` structurally on the Signed side).
  - `Code.annotations()` is now a syntax read; `Code.shaped_by_a_query()` reads `seat_fns`.
- Program layer: @query `item_fact_rows(file, at)` runs every `fact_rule` over the item's statements. The types are the merged typed bodies from `item_bodies` (the same columns the laws read). @query `file_seat_fns(file)` gives the fns the file's declarations name in `@cycled_by`/`@scoped_by`.
- Transitional: a rule that still reads the old tables is an `analysed_rule` (features/analysed_rule.av, same shape as fact_rule). Only the old path runs it, and the check names it. `Code.analysed()` is the only door to the old tables. Moving a rule = switching the keyword back to fact_rule; both go away when the last rule moves.
- Moved:
  - str_grown_quadratically: `is_text`.
  - modified_copy_literal: `same`.
  - file_id_across_relation: Db/ExprId/... by declaration. `NodeStore` is dropped: nothing declares it.
  - host_asked_directly: Host by declaration; the package is asked instead of matching a disk path.
  - free_state_verb.
- Still analysed_rule (8): bypass_outside_bracket, one_body_arms, dead_parameter, default_override, unmutated_mut, unused_import, if_null_ternary (needs built-in method effects on Signed types), repeated_unwrap.

## Receipts (merged tree, one compiler, sorted file:line:rule)

| Package | Path | Cold | Warm | Sites |
|---|---|---|---|---|
| std-program | old | 17.13 s / 855 MB | 0.05 s | 13 |
| std-program | new | 11.37 s / 355 MB | 0.04 s (warm == cold) | 12 |
| cli | old | 245.62 s / 7.42 GB | 0.12 s | 66 |
| cli | new | 126.21 s / 1.64 GB | 0.17 s (warm == cold) | 64 |

- std-program diff: only fns.dead_parameter (std-grammar collected.av:28).
- cli diff: only 3 fns.dead_parameter (step 3), plus std-http route.av:722 lists.bool_comprehension_range, which only the new path finds. The old path finds that site when it checks std-http, but not when it checks cli, which imports @std.http.route: old-path coverage of a dependency file depends on what reaches it. The new path's per-file answer is the right one.
- 16 of the 19 fact-rule sites that cli was missing are now closed (14 free_state_verb, 2 str_grown_quadratically).
- The old path on the refactored tree gives the same sites as trunk's old path, apart from line shifts inside the compiler/idioms.av I edited.
- New site on a scratch copy of std-program (a nullable_flag_local site plus a str_grown_quadratically site): old and new print the identical `idioms: 2 NEW violation(s)` lines, both exit 1.

## Gate
- idioms: 0 NEW (old path, `check --baseline tools/idioms.baseline`, packages/cli and packages/std-program, exit 0).
- make try exit 0, built with AVRA_BIN=build/avra-builder (a copy of a trunk avra-try). The standing build/avra traps on a warm store: the old warm-edit trap.
- tapes cli --built 43399/43403 (same 4 unmade as trunk).
- `avra-try test` features/tests/code_test.av + rule_test.av: 26/26.
- witness_program_edit: same as trunk (fails at the 4th edit, enum_signature fold).

## Found on the way (not fixed)
- A compiler built through the program layer drops every annotation-filled component field (@says, @law, @keeps, @fixes). `rules --json` on a trunk-built avra-try gives says 0/83 and law 0, versus 64/6 on the old-built build/avra, and `rules --check-examples` examines 0 examples. The cause: compiler/item_lowered.av `instance_read` reads `it.<field>` off the instance's built value, which the program layer lowers without features/components/lower.av's `augmented`.
- The old type checker accepted `self.of.view.decls` where `view` was a `SyntaxView`, which has no `decls` field: three formatter-split chains in code.av. Only the program layer caught them.

## Unproven / next
- Step 3: the local-seat column beside TypedBody.types (core/checking.av), then repeated_unwrap, one_body_arms, dead_parameter, unmutated_mut; if_null_ternary.
- Step 4: default_override, unused_import, bypass_outside_bracket.
- --baseline_accept on the new path.
