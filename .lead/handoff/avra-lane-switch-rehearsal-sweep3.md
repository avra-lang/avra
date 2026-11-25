# avra-lane-switch-rehearsal — package sweep 3 (trunk 3d35d216)

Same method as sweep 2: 48 targets (47 packages + tools/ui-board), cold per package. Compiler S5 = an old-path
`make try` of 3d35d216. C objects and evaluator libs built first:
`make libs build/sqlite3.o build/sqlite_sentinel.o build/width_witness.o build/std_tls.a`.

Exceptions:
- **std-task**: `signals` and `signals_usr1` skipped (`--only` over the other 12).
- **std-http**: run ONE TEST AT A TIME (300 s timeout), because the whole-package `--ran` still hangs on this trunk.
  None timed out. One, `h2_reads_beside`, crashes the compiler (item 2 below), so std-http counts 55 of its 56.

## Totals

**`tapes --ran`: 794 program tests / 677 made / 674 eval / 675 native / 4 failing.**
Sweep 2 (5e7ff03b): 785 / 651 / 41. Sweep 1 (31f3d60): 761 / 521 / 1.

**Package-shaped tests (`--ran` does not discover them): 97, built in place with `AVRA_PROGRAM=1` and run, stdout
against `src/main.expected` with trailing newlines ignored: 70 right / 8 wrong / 19 not built.**
- Where they are: std-avrac 89, std-db 2, std-meta 2, std-prelude 2, std-relation 1, std-ui 1.
- My first pass compared bytes exactly and called 18 wrong. 10 of those differed only by the missing final newline
  of `.expected`.

Together: **891 program tests / 747 made / 12 not right** (4 failing runs on 2 tests + 8 wrong package-shaped).

## Table

| package | old build | new build (text) | old tests | new tests/made/eval/native/failing | package-shaped (not discovered by --ran) | not-made reasons |
|---|---|---|---|---|---|---|
| cli | 0 | 0 (DIFFERS) | 420/438 (exit 1) | 0/0/0/0/0 | 0 |  |
| site | 0 | 1 (DIFFERS) | 18/18 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-action | 1 | 1 (DIFFERS) | 127/127 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-assets | 1 | 1 (DIFFERS) | 19/19 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-cli | 1 | 1 (DIFFERS) | 43/43, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-compress | 1 | 1 (DIFFERS) | 33/33, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-convert | 1 | 1 (DIFFERS) | 3/3, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-crud | 1 | 1 (DIFFERS) | 2/2, 7 proved (exit 0) | 7/7/7/7/0 | 0 |  |
| std-db | 1 | 1 (DIFFERS) | 187/187, 1 proved (exit 0) | 7/7/5/5/4 | 2: 2 right / 0 wrong / 0 not built |  |
| std-derive | 1 | 1 (DIFFERS) | - (exit 0) | 0/0/0/0/0 | 0 |  |
| std-errors | 1 | 1 (DIFFERS) | 21/21 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-grammar | 1 | 1 (DIFFERS) | 56/56 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-hash | 1 | 1 (DIFFERS) | 14/14 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-http-fuzz | 0 | 0 (same) | - (exit 0) | 0/0/0/0/0 | 0 |  |
| std-http-soak | 0 | 0 (same) | - (exit 0) | 0/0/0/0/0 | 0 |  |
| std-http_compress | 1 | 1 (DIFFERS) | 78/78, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-http_message | 1 | 1 (DIFFERS) | 17/17 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-http_session | 1 | 1 (DIFFERS) | 22/22, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-https | 1 | 1 (DIFFERS) | 19/19, 7 proved (exit 0) | 7/7/7/7/0 | 0 |  |
| std-io | 1 | 1 (DIFFERS) | 121/121, 5 proved (exit 0) | 5/5/5/5/0 | 0 |  |
| std-json | 1 | 1 (DIFFERS) | 183/183, 3 proved (exit 0) | 3/3/3/3/0 | 0 |  |
| std-mcp | 1 | 1 (DIFFERS) | 143/143 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-meta | 1 | 1 (DIFFERS) | -, 1 proved (exit 0) | 1/1/1/1/0 | 2: 1 right / 1 wrong / 0 not built |  |
| std-net | 1 | 1 (DIFFERS) | 84/90 (exit 1) | 19/19/18/19/0 | 0 |  |
| std-openapi | 1 | 1 (DIFFERS) | 12/12, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-path | 1 | 1 (DIFFERS) | 31/31, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-prelude | 1 | 1 (DIFFERS) | -, 1 proved (exit 0) | 0/0/0/0/0 | 2: 2 right / 0 wrong / 0 not built |  |
| std-process | 1 | 1 (DIFFERS) | 119/119, 4 proved (exit 0) | 4/4/4/4/0 | 0 |  |
| std-program | 1 | 1 (DIFFERS) | 414/415 (exit 1) | 0/0/0/0/0 | 0 |  |
| std-queue | 1 | 1 (DIFFERS) | 10/10, 10 proved (exit 0) | 10/0/0/0/0 | 0 | a default of the generic `queue<Job>` 9, `StructLit` 1 |
| std-relation | 1 | 1 (DIFFERS) | 312/312, 1 proved (exit 0) | 42/42/42/42/0 | 1: 1 right / 0 wrong / 0 not built |  |
| std-sql | 1 | 1 (DIFFERS) | 96/96 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-sqlite | 1 | 1 (DIFFERS) | 517/517, 3 proved (exit 0) | 3/3/3/3/0 | 0 |  |
| std-task | 1 | 1 (DIFFERS) | 11/11, 14 proved (exit 0) | 12/12/12/12/0 | 0 |  |
| std-testing | 1 | 1 (DIFFERS) | 9/9 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-text | 1 | 1 (DIFFERS) | 200/200, 4 proved (exit 0) | 4/3/3/3/0 | 0 | `float.round` 1 |
| std-time | 1 | 1 (DIFFERS) | 49/49, 11 proved (exit 0) | 11/11/11/11/0 | 0 |  |
| std-tls | 1 | 1 (DIFFERS) | 64/64, 5 proved (exit 0) | 5/5/5/5/0 | 0 |  |
| std-toml | 1 | 1 (DIFFERS) | 46/46 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-ui | 1 | 1 (DIFFERS) | 975/975, 1 proved (exit 0) | 75/6/6/6/0 | 1: 0 right / 0 wrong / 1 not built | a record literal leaving a field no declared default fills 53, a `dyn` box over a method the type doesn't write 6, `StructLit` 2, an untyped `Comp`, first under it an untyped `StructLit` 2, `MutLet` 2, the method `describe` of `tap` 1, a call of the generic `headless` whose arguments don't lay out its type parameters 1, the method `describe` of `panel` 1, `Lambda` 1 |
| std-ui_gallery | 1 | 1 (DIFFERS) | 38/38 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-ui_http | 1 | 1 (DIFFERS) | 17/17 (exit 0) | 0/0/0/0/0 | 0 |  |
| std-url | 1 | 1 (DIFFERS) | 177/177, 1 proved (exit 0) | 1/1/1/1/0 | 0 |  |
| std-validate | 1 | 1 (DIFFERS) | 152/152, 6 proved (exit 0) | 6/6/6/6/0 | 0 |  |
| width-witness | 0 | 0 (same) | - (exit 0) | 0/0/0/0/0 | 0 |  |
| ui-board | 1 | 1 (DIFFERS) | - (exit 0) | 0/0/0/0/0 | 0 |  |
| std-avrac | 1 | 1 (DIFFERS) | - (exit 2) | 510/474/474/474/0 | 89: 64 right / 7 wrong / 18 not built | `MethodCall` 4, `StructLit` 3, `ConstDecl` 2, an untyped `Call` 2, `MutLet` 2, an untyped call through a type 1, `Index` 1, `int.float` 1, `float.round` 1, `Binary` 1, the method `grown` of `dyn Grows` 1, `int.checked_add` 1, the prelude's `filter_map`, whose arguments' layouts aren't known 1, a `contains` over elements that don't compare by value 1, `string.char_code` leaving a seat to its defaul |
| std-http | 1 | 1 (DIFFERS) | 1364/1365 (exit 1) | 55/54/54/54/0 | 0 | a call of the generic `declared` whose arguments don't lay out its type parameters 1 |

## What fails or is wrong, ranked

1. **std-db db_diff and migrate_all**, both engines (the 4 failing runs). Native: "(it ended with status 2)". Eval:
   "defect: a read from a non-array in a clean program". package-sweep-2's std-db settle (ba2aad9, std-db 7/7 on
   your Mac) landed AFTER 3d35d216; recheck on 70c41adc+.
2. **Compiler crash on std-http `h2_reads_beside`**: `tapes … --ran --only src/tests/h2_reads_beside/` →
   "avra: index 1 is out of bounds (length 1)". gdb: `avra_trap_bounds` ← `Lowering.jumped_to` ← `lists.walk_lowers`
   ← `Lowering.void_region` ← `lists.walk_lowered` ← `Lowering.list_walked` ← `impls.owned_rule` ←
   `MethodCall.lowered` ← `Not.lowered`. That is a walk that ends early, lowered under `!`. Probably the
   while/early-ending-walk crash a5e95c34 fixes; unverified.
3. **8 package-shaped programs print the wrong thing**:
   - `collects/tests/closure_entry_private` (`[] 1` vs `[knob] 1`) and `closure_entry_b` (`[]` vs `[knob]`): a collect
     over the program's closure is empty. package-sweep-2's "closure collects" (70c41adc) should fix both.
   - `collects/tests/gathered_same_name`, `gathered_package`, `gathered_mutual`: each type prints `@` with no
     mark names (`Error()@` vs `Error()@expr_node+stmt_node`). lowering-gaps-2's "gathered marks" (f904476, on
     70c41adc) should fix these.
   - `annotations/tests/wrap_method`: `10 6 12` vs `11 16 13`, so the method wrapper is not applied.
     Owner: annotation calls (lowering-gaps).
   - `annotations/tests/prop_told`: a different `prop=/state=` reading for one field (the line differs after `tone`).
   - `std-meta/src/tests/record_reads`: `items: List<Elem> is NOT readable from the enum's module` vs `… is a
     record of [a, b]`. A meta readability answer differs.
4. **19 package-shaped programs not built**, reasons as printed:
   - "a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't…" ×3 (private_const,
     generated_const, const_seat): const seats, package-sweep-2 (on 70c41adc).
   - "a const whose value reaches a body not lowered yet: a call of the generic `unreached`…" ×2 (asset/hygiene,
     fns/provided).
   - `resolve.unresolved` for a GENERATED fn ×5 (`sum_traced`, `two_default`, `one_s`, `go_wrapped`, `base_run`) plus
     `a_close` (query_annotation): annotation- and quote-generated items aren't visible to the program layer's
     resolver. lowering-gaps (annotation calls) or the quote lane.
   - `type.method` "`SyntaxArena` has no method `exact_pat`" (gathered_exact). `type.mismatch` "the body answers
     `Code` but `widen_add` declares `Fix?`" (ordinary_widen). These are type-refusals on the new path that the
     old path accepts.
   - bodies left to trap ×4: `crossing` `seed`, `quote/binders` `P.binders`, `const_pat_template` `Point.class`,
     `package_rule` `plus_zero`. Then sublang/sql "another language's body, at the entry", and std-ui `seat_entry`
     "a record literal leaving a field no declared default fills" (ui-build).
5. **std-ui 69 not made**: "a record literal leaving a field no declared default fills" 53, dyn box 6, plus others.
   The site package's new build refuses on the same 11 traps. Owner: ui-build.
6. **std-queue 9/10 not made**: "a default of the generic `queue<Job>`". Owner: package-sweep-2 (generic defaults).
7. **tools/ui-board new build**: LLVM verifier "PHI node operands are not the same type as the result!
   `%regval339 = phi i64 [ 2, … ], [ { i64 -1, i64 0 }, … ]`" in `Show.read_from`. Unchanged since sweep 2. The old
   build fails at link: `undefined symbol: avra_ui_stood`.
8. **Refusal text for the 42 library packages**: unchanged ("declares no entry point" vs "a file that runs no
   statement").
9. **The new build prints no warnings** (cli). Unchanged.

Fixed since sweep 2: the 30 evaluator `sqlite3_open_v2` refusals (std-crud 7/7, std-sqlite 3/3 now). The four std-http
wrong answers (h2c_client, h2c_serve, http_server_decl, http_specificity now pass). width-witness's new build now
succeeds.

Not-right list (package-shaped):
- std-avrac/src/features/consts/tests/private_const | not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- std-avrac/src/features/consts/tests/generated_const | not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- std-avrac/src/features/collects/tests/closure_entry_private | wrong(exit 0): < [] 1
- std-avrac/src/features/collects/tests/gathered_same_name | wrong(exit 0): < Error()@ Collect(of:int/Int)@ | Error()@ Collect(word:string/Str,dense:bool/Bool)@ | 4 2
- std-avrac/src/features/collects/tests/gathered_package | wrong(exit 0): < 3 Dot()@ Line(from:int/Int,to:int/Int)@ Box(width:Width/Named,inner:List<Shape>/List)@ 10 0 3 35
- std-avrac/src/features/collects/tests/gathered_exact | not-built(exit 1): error[type.method]: `SyntaxArena` has no method `exact_pat`
- std-avrac/src/features/collects/tests/closure_entry_b | wrong(exit 0): < []
- std-avrac/src/features/collects/tests/gathered_mutual | wrong(exit 0): < Tip()@ Fork(under:Tree/Named,kids:List<Leaf>/List)@ | Stump()@ Limb(leaf:Leaf/Named,next:Tree?/Opt
- std-avrac/src/features/asset/tests/hygiene | not-built(exit 1): avra: the program layer doesn't build this program yet — a const whose value reaches a body not lowered yet: a call of the generic `unreached` whose arguments
- std-avrac/src/features/fns/tests/const_seat | not-built(exit 1): avra: the program layer doesn't build this program yet — a call of `scaled` with type arguments it doesn't declare, or into seats a call doesn't fill, at the 
- std-avrac/src/features/fns/tests/provided | not-built(exit 1): avra: the program layer doesn't build this program yet — a const whose value reaches a body not lowered yet: a call of the generic `unreached` whose arguments
- std-avrac/src/features/annotations/tests/wrap_method | wrong(exit 0): < 10 6 12
- std-avrac/src/features/annotations/tests/prop_told | wrong(exit 0): < title prop=false state=false kind=string · kids prop=false state=false kind=List<string> · tone 
- std-avrac/src/features/annotations/tests/traced | not-built(exit 1): error[resolve.unresolved]: no `fn sum_traced` is defined
- std-avrac/src/features/annotations/tests/default_seats | not-built(exit 1): error[resolve.unresolved]: no `fn two_default` is defined
- std-avrac/src/features/annotations/tests/const_argument | not-built(exit 1): error[resolve.unresolved]: no `fn one_s` is defined
- std-avrac/src/features/tests/crossing | not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: crossing/src/main.av.seed
- std-avrac/src/features/tests/ordinary_widen | not-built(exit 1): error[type.mismatch]: the body answers `Code` but `widen_add` declares `Fix?`
- std-avrac/src/features/quote/tests/hygiene | not-built(exit 1): error[resolve.unresolved]: no `fn go_wrapped` is defined
- std-avrac/src/features/quote/tests/binders | not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: binders/src/main.av.P.binders
- std-avrac/src/features/quote/tests/statements | not-built(exit 1): error[resolve.unresolved]: no `fn base_run` is defined
- std-avrac/src/features/enums/tests/const_pat_template | not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: const_pat_template/src/main.av.Point.class
- std-avrac/src/features/sublang/tests/sql | not-built(exit 1): avra: the program layer doesn't build this program yet — another language's body, at the entry
- std-avrac/src/compiler/tests/query_annotation | not-built(exit 1): error[resolve.unresolved]: `a_close` is not defined
- std-avrac/src/compiler/tests/package_rule | not-built(exit 1): avra: built on the program layer; 1 bodies not lowered yet trap where they're reached: package_rule/src/main.av.plus_zero
- std-meta/src/tests/record_reads | wrong(exit 0): < items: List<Elem> is NOT readable from the enum's module
- std-ui/src/tests/seat_entry | not-built(exit 1): avra: the program layer doesn't build this program yet — a record literal leaving a field no declared default fills, at the entry

Old-tests column: unchanged from sweep 2. cli 420/438 (the pre-existing explain debt); std-net 84/90 and std-http
1364/1365 (sandbox networking); std-program 414/415 (the root-only test); std-avrac exit 2 (the memory pool).
