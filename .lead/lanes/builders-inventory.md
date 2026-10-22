# Builders inventory

## Builder inventory: origin/main `features/*/builders.av` + `node_scaffold.av`

Hand-read on origin/main (read-only). 115 `build_*` fns in 33 builder files; `node_scaffold.av` holds no `build_*` fn. Every fn is in exactly one row below; a fn may carry several letters. Lines = the fn from its `fn` line to its closing brace. The reading was split: the lead's reader read `annotations`, `block`, `closures`, `collects` directly; four delegated readers hand-read the rest, and the nine fns no reader covered were read directly. Helpers called from these fns (e.g. `applied`, `seat_marks`, `collect_decl_node`, `with_body`) are described in the evidence of their caller's row, not as rows.

### Letters

- **A** PURE
- **B** SPAN ANCHOR
- **C** DEFAULT
- **D** SIDE TABLE
- **E** PARALLEL/NESTED
- **F** CHOICE
- **G** DESUGAR
- **H** OTHER

### Totals per letter (a fn with several letters counts in each)

| letter | fns | lines |
|---|---|---|
| A PURE | 36 | 186 |
| B SPAN ANCHOR | 15 | 448 |
| C DEFAULT | 51 | 805 |
| D SIDE TABLE | 24 | 404 |
| E PARALLEL/NESTED | 32 | 764 |
| F CHOICE | 22 | 512 |
| G DESUGAR | 31 | 644 |
| H OTHER | 51 | 877 |

Fns: 115. Lines across all fns: 1327 (each fn once). Per-letter lines overlap, so the column sums to more than that.

### Combinations

| letters | fns |
|---|---|
| A | 20 |
| H | 9 |
| A,C | 9 |
| C,H | 7 |
| C | 4 |
| C,E | 3 |
| E,H | 3 |
| F,G | 3 |
| D,H | 3 |
| G | 3 |
| C,D,E,G | 2 |
| C,G | 2 |
| C,F | 2 |
| G,H | 2 |
| B,C,E,F,G,H | 2 |
| E | 2 |
| C,D,E,H | 2 |
| A,D | 2 |
| A,E | 2 |
| C,E,H | 2 |
| B,D,G | 1 |
| B,C,G | 1 |
| B,E,H | 1 |
| C,D,E,G,H | 1 |
| D,F,G,H | 1 |
| B,C,H | 1 |
| C,E,F,G,H | 1 |
| C,D,G,H | 1 |
| D | 1 |
| F | 1 |
| E,G,H | 1 |
| C,F,H | 1 |
| B,C,E,F,G | 1 |
| B,F,G,H | 1 |
| E,F,H | 1 |
| E,C,H | 1 |
| C,D,E,F,G,H | 1 |
| F,H | 1 |
| D,G,H | 1 |
| B,D,G,H | 1 |
| D,F,G | 1 |
| C,D,F,H | 1 |
| C,D | 1 |
| B,D,E,F,G,H | 1 |
| A,B,C | 1 |
| A,C,E | 1 |
| A,B,D,E,F,H | 1 |
| C,E,G,H | 1 |
| B,C,D,F,G,H | 1 |
| B,D,E,G,H | 1 |
| B,C,E,F | 1 |

### 10 largest fns

| fn | file:lines | lines | letters |
|---|---|---|---|
| `build_fold_postfix` | `expr_spine/builders.av:226-405` | 180 | B,C,E,F,G,H |
| `build_catch` | `expr_spine/builders.av:546-598` | 53 | B,C,E,F,G,H |
| `build_fn` | `fns/builders.av:17-67` | 51 | E,C,H |
| `build_trait` | `impls/builders.av:147-183` | 37 | C,D,E,H |
| `build_component_decl` | `components/builders.av:60-94` | 35 | C,D,E,G,H |
| `build_enum_decl` | `enums/builders.av:27-60` | 34 | E,H |
| `build_component_keyed` | `components/builders.av:117-145` | 29 | D,F,G,H |
| `build_quote` | `quote/builders.av:8-36` | 29 | B,D,E,F,G,H |
| `build_once_fn` | `fns/builders.av:72-99` | 28 | C,D,E,H |
| `build_table` | `tables/builders.av:7-34` | 28 | B,D,E,G,H |

### Every fn

| file | fn | lines | letters | node built |
|---|---|---|---|---|
| `annotations/builders.av` | `build_annotated` (6-17) | 12 | B,D,G | NStmt (annotated decl) + Annotation fact |
| `annotations/builders.av` | `build_mark` (22-39) | 18 | B,C,G | NMark |
| `block/builders.av` | `build_block` (5-7) | 3 | A | Block expr |
| `closures/builders.av` | `build_lambda` (18-40) | 23 | C,E | Lambda |
| `closures/builders.av` | `build_fn_type` (47-65) | 19 | C,E | TypeRef fn |
| `closures/builders.av` | `build_trailing_arms` (75-89) | 15 | C,D,E,G | Lambda over Match |
| `collects/builders.av` | `build_collect_decl` (26-47) | 22 | H | Stmt.Collect (via collect_decl_node: E,F,C,D) |
| `collects/builders.av` | `build_collect_enum_decl` (89-104) | 16 | B,E,H | Stmt.CollectEnum (via collect_enum_node: E,F,D) |
| `components/builders.av` | `build_component_decl` (60-94) | 35 | C,D,E,G,H | Stmt.ComponentDecl |
| `components/builders.av` | `build_component_value` (105-108) | 4 | H | Expr.Component |
| `components/builders.av` | `build_component_keyed` (117-145) | 29 | D,F,G,H | Expr.Component (keyed) |
| `components/builders.av` | `build_component_name_head` (190-204) | 15 | B,C,H | Expr.Component |
| `components/builders.av` | `build_component_headless` (207-210) | 4 | C,H | Expr.Component |
| `components/builders.av` | `build_component_blockless` (213-216) | 4 | C,H | Expr.Component |
| `components/builders.av` | `build_component_named` (221-223) | 3 | H | NStmt |
| `components/builders.av` | `build_component_named_bare` (226-228) | 3 | C,H | NStmt |
| `components/builders.av` | `build_instance_body` (233-244) | 12 | C,E,F,G,H | Expr.Block or Lambda |
| `components/builders.av` | `build_instance_arms_body` (257-271) | 15 | C,D,G,H | Lambda over Match |
| `components/builders.av` | `build_setting` (274-276) | 3 | A | Stmt.Setting |
| `components/builders.av` | `build_on_handler` (284-296) | 13 | C,D,E,G | Stmt.Setting (Lambda) |
| `components/builders.av` | `build_on_value` (300-305) | 6 | D | Stmt.Setting |
| `consts/builders.av` | `build_const` (5-10) | 6 | A,C | Stmt.ConstDecl |
| `defers/builders.av` | `build_defer` (7-9) | 3 | H | Stmt.Defer |
| `defers/builders.av` | `build_errdefer` (11-13) | 3 | H | Stmt.Defer |
| `enums/builders.av` | `build_enum_decl` (27-60) | 34 | E,H | Stmt.EnumDecl |
| `enums/builders.av` | `build_match` (94-97) | 4 | A | Expr.Match |
| `enums/builders.av` | `build_arm` (99-102) | 4 | A | Arm |
| `enums/builders.av` | `build_hole_arm` (107-111) | 5 | C,G | Arm |
| `enums/builders.av` | `build_variant_pat` (113-116) | 4 | A | Pat.Variant |
| `enums/builders.av` | `build_member_pat` (119-123) | 5 | A | Pat.Member |
| `enums/builders.av` | `build_bind_pat` (128-133) | 6 | F,G | Pat.Rest / Pat.Lit / Pat.Bind |
| `enums/builders.av` | `build_num_pat` (135-138) | 4 | A,C | Pat.Lit(IntLit) |
| `enums/builders.av` | `build_true_pat` (140-142) | 3 | A | Pat.Lit(BoolLit) |
| `enums/builders.av` | `build_false_pat` (144-146) | 3 | A | Pat.Lit(BoolLit) |
| `enums/builders.av` | `build_variant_lit` (149-152) | 4 | A | Expr.VariantLit |
| `expr_stmt/builders.av` | `build_expr_stmt` (8-13) | 6 | F | Stmt.ExprStmt / Stmt.Assign |
| `expr_spine/builders.av` | `build_int_lit` (30-38) | 9 | C,F | Expr.FloatLit / Expr.IntLit |
| `expr_spine/builders.av` | `build_named_arg` (41-44) | 4 | A | Expr.Named |
| `expr_spine/builders.av` | `build_ident` (46-49) | 4 | A | Expr.Ident |
| `expr_spine/builders.av` | `build_fold_binary` (53-62) | 10 | E,H | Expr.Binary (left fold) |
| `expr_spine/builders.av` | `build_fold_bitwise` (77-88) | 12 | E,G,H | Expr.Binary (left fold) |
| `expr_spine/builders.av` | `build_bitnot` (110-115) | 6 | G,H | Expr.Binary(^, v, -1) |
| `expr_spine/builders.av` | `build_fold_cmp` (119-129) | 11 | C,F,H | Expr.Is / Expr.Binary / operand |
| `expr_spine/builders.av` | `build_asked_bind` (135-140) | 6 | F,G | Pat.Rest / Pat.Lit / Pat.Bind |
| `expr_spine/builders.av` | `build_fold_postfix` (226-405) | 180 | B,C,E,F,G,H | Prop / Chain / MethodCall / MatchOpt / Index / CallValue / Force / Propagate / Lambda |
| `expr_spine/builders.av` | `build_trailing` (525-534) | 10 | B,C,E,F,G | Expr.Lambda |
| `expr_spine/builders.av` | `build_catch` (546-598) | 53 | B,C,E,F,G,H | Expr.Catch |
| `expr_spine/builders.av` | `build_not` (163-166) | 4 | A | Expr.Not |
| `expr_spine/builders.av` | `build_neg` (173-182) | 10 | B,F,G,H | Expr.IntLit / FloatLit / Binary(-) |
| `expr_spine/builders.av` | `build_fold_with` (186-194) | 9 | E,F,H | Expr.With |
| `expr_spine/builders.av` | `build_fold_coalesce` (208-215) | 8 | E | Expr.Coalesce (left fold) |
| `fns/builders.av` | `build_fn` (17-67) | 51 | E,C,H | Stmt.FnDecl |
| `fns/builders.av` | `build_once_fn` (72-99) | 28 | C,D,E,H | Stmt.FnDecl (once) |
| `fns/builders.av` | `build_call` (102-106) | 5 | A,C | Expr.Call |
| `fns/builders.av` | `build_pinned_call` (111-116) | 6 | A | Expr.Call |
| `fns/builders.av` | `build_return` (118-120) | 3 | C | Stmt.Return |
| `fns/builders.av` | `build_extern` (126-150) | 25 | C,D,E,F,G,H | Stmt.ExternFn / Stmt.FnDecl (host) |
| `formats/builders.av` | `build_format_pat` (26-33) | 8 | F,H | Pat.Format / Pat.Lit |
| `formats/builders.av` | `build_grammar_decl` (51-55) | 5 | D,G,H | Stmt.StructDecl (grammar) |
| `grammar_lit/builders.av` | `build_grammar_lit` (23-32) | 10 | B,D,G,H | Expr (Grammar literal) |
| `grammar_lit/builders.av` | `build_expr` (112-138) | 27 | C,G | Expr (grammar literal writer) |
| `if_expr/builders.av` | `build_if` (6-12) | 7 | F,G | Expr.If / Expr.Match |
| `if_expr/builders.av` | `build_if_stmt` (40-53) | 14 | D,F,G | Stmt.IfStmt / Stmt.ExprStmt(Match) |
| `impls/builders.av` | `build_mut_fn` (93-97) | 5 | D,H | Stmt.FnDecl (mut) |
| `impls/builders.av` | `build_static_fn` (101-105) | 5 | D,H | Stmt.FnDecl (static) |
| `impls/builders.av` | `build_impl` (112-133) | 22 | C,D,F,H | Stmt.ImplDecl |
| `impls/builders.av` | `build_trait` (147-183) | 37 | C,D,E,H | Stmt.TraitDecl |
| `let_stmt/builders.av` | `build_state` (8-15) | 8 | C,D | Stmt.MutLet |
| `let_stmt/builders.av` | `build_let` (17-22) | 6 | A,C | Stmt.Let |
| `let_stmt/builders.av` | `build_let_else` (29-34) | 6 | A,C | Stmt.LetElse |
| `lists/builders.av` | `build_list` (7-10) | 4 | C,F | Expr.ListLit |
| `lists/builders.av` | `build_comp` (15-23) | 9 | H | Expr.Comp |
| `lists/builders.av` | `build_comp_head` (27-32) | 6 | A,C | CompClause.Head |
| `lists/builders.av` | `build_comp_filter` (35-37) | 3 | A | CompClause.Filter |
| `lists/builders.av` | `build_collect` (41-43) | 3 | A,C | Expr.Collect |
| `lists/builders.av` | `build_collect_blockless` (46-48) | 3 | H | none (refusal) |
| `loops/builders.av` | `build_while` (10-14) | 5 | A | Stmt.While |
| `loops/builders.av` | `build_for_each` (18-25) | 8 | A,C | Stmt.ForEach |
| `loops/builders.av` | `build_for` (27-38) | 12 | G | Stmt.For |
| `loops/builders.av` | `build_break` (40-42) | 3 | H | Stmt.Jump |
| `loops/builders.av` | `build_continue` (44-46) | 3 | H | Stmt.Jump |
| `loops/builders.av` | `build_bare_break` (48-50) | 3 | C | Stmt.Jump |
| `loops/builders.av` | `build_bare_continue` (52-54) | 3 | C | Stmt.Jump |
| `maps/builders.av` | `build_map` (6-10) | 5 | E | Expr.MapLit |
| `maps/builders.av` | `build_map_empty` (14-16) | 3 | C | Expr.MapLit |
| `modules/builders.av` | `build_use` (7-24) | 18 | C,E | Stmt.Use |
| `modules/builders.av` | `build_export` (39-44) | 6 | D,H | declaration (NStmt) |
| `mutation/builders.av` | `build_mut` (7-12) | 6 | A,C | Stmt.MutLet |
| `narrows/builders.av` | `build_typed_pat` (5-8) | 4 | A | Pat.Typed |
| `nullable/builders.av` | `build_match_opt` (7-13) | 7 | A | Expr.MatchOpt |
| `quote/builders.av` | `build_quote` (8-36) | 29 | B,D,E,F,G,H | Expr.Body (quote) |
| `quote/builders.av` | `build_quote_pat` (40-46) | 7 | G,H | Pat.Quote |
| `quote/builders.av` | `build_run_hole` (52-57) | 6 | A,D | Expr.Ident (run hole) |
| `results/builders.av` | `build_fail` (7-10) | 4 | A | Stmt.Fail |
| `specs/builders.av` | `build_given` (12-15) | 4 | A,E | LangNode.NCases |
| `specs/builders.av` | `build_spec` (17-20) | 4 | A,E | Stmt.Spec |
| `specs/builders.av` | `build_then` (6-10) | 5 | A,B,C | LangNode.NCases |
| `str_lit/builders.av` | `build_body_text` (8-10) | 3 | A,C,E | Expr.Body(text) |
| `str_lit/builders.av` | `build_str_lit` (16-21) | 6 | A,D | Expr.StrLit |
| `structs/builders.av` | `build_type_decl` (21-43) | 23 | A,B,D,E,F,H | Stmt.NamedType / Stmt.StructDecl |
| `structs/builders.av` | `build_alias_decl` (46-51) | 6 | A | Stmt.Alias |
| `structs/builders.av` | `build_struct_lit` (57-70) | 14 | C,E,G,H | Expr.StructLit |
| `sublang/builders.av` | `build_syntax_decl` (35-39) | 5 | A | Stmt.SyntaxDecl |
| `sublang/builders.av` | `build_sublang` (41-62) | 22 | B,C,D,F,G,H | Expr.Body (sublang) |
| `tables/builders.av` | `build_table` (7-34) | 28 | B,D,E,G,H | Expr.ListLit of StructLit rows |
| `tasks/builders.av` | `build_spawn` (9-11) | 3 | G | Expr.Spawn |
| `tasks/builders.av` | `build_within` (13-16) | 4 | G | Expr.Within |
| `type_expr/builders.av` | `build_applied_opt_type` (6-8) | 3 | C,E,H | TypeRef |
| `type_expr/builders.av` | `build_applied_type` (10-12) | 3 | C,E,H | TypeRef |
| `type_expr/builders.av` | `build_opt_type` (14-16) | 3 | C,H | TypeRef |
| `type_expr/builders.av` | `build_plain_type` (18-20) | 3 | C,H | TypeRef |
| `type_expr/builders.av` | `build_dyn_type` (24-26) | 3 | C,H | TypeRef |
| `type_expr/builders.av` | `build_dyn_opt_type` (28-30) | 3 | C,H | TypeRef |
| `type_expr/builders.av` | `build_union_type` (69-85) | 17 | B,C,E,F | TypeRef |
| `when_expr/builders.av` | `build_when` (9-31) | 23 | E,H | Expr.When |

## H sub-classes (added after the inventory)

Every H-carrying fn (51) has one sub-class and one line on what it does that A–G do not. A fn with several letters is placed by its own H content.

| sub-class | meaning | fns | lines |
|---|---|---|---|
| H1 | OPERATOR FOLD: a left-assoc chain over a repeated group | 5 | 222 |
| H2 | REFUSAL/VALIDATION: a law or defect the grammar cannot state | 24 | 522 |
| H3 | TYPE-REF construction: the *_type builders fill TypeRef fields | 6 | 18 |
| H4 | DISPATCH: the builder body is only a call into a shared helper | 13 | 52 |
| H5 | CONTEXT: reads builder or store state beyond its own tokens | 3 | 63 |
| H6 | anything left | 0 | 0 |

### Per fn

| sub | fn | file:lines | lines | what it does that A–G do not |
|---|---|---|---|---|
| H1 | `build_fold_binary` | `expr_spine/builders.av:53-62` | 10 | left-folds each `op right` pair into Binary; refuses an operator the language does not have (`want(binop_of(…))`). |
| H1 | `build_fold_bitwise` | `expr_spine/builders.av:77-88` | 12 | left-folds the bitwise run; refuses two different bitwise operators in one run (`mixed_bitwise`: “…mixed bitwise operators…”). |
| H1 | `build_fold_cmp` | `expr_spine/builders.av:119-129` | 11 | one optional comparison over an operand: returns the operand, an Is, or a Binary; refuses an operator not wanted. |
| H1 | `build_fold_postfix` | `expr_spine/builders.av:226-405` | 180 | folds the postfix star left in source order across five families; refuses a block after a type literal and a second block. |
| H1 | `build_fold_with` | `expr_spine/builders.av:186-194` | 9 | a `with` tail over a subject: absent tail returns the subject; refuses mismatched name and value counts (`zip_defect`). |
| H2 | `build_collect_decl` | `collects/builders.av:26-47` | 22 | refuses a projection that reads its declaration through a word other than `it` (“a collect's projection reads its declaration through `it`”), then dispatches. |
| H2 | `build_collect_enum_decl` | `collects/builders.av:89-104` | 16 | refuses an order that reads through a word other than `it`, and a defect with no span (“defect: a collect enum without a span”), then dispatches. |
| H2 | `build_component_keyed` | `components/builders.av:117-145` | 29 | refuses a keyed clause that is not `by`, a pronoun other than `it`, a body that is not a lambda, or a missing binder. |
| H2 | `build_component_name_head` | `components/builders.av:190-204` | 15 | refuses a head given as braces or parentheses when expressions were written (“…braced head… parenthesised head…”). |
| H2 | `build_instance_body` | `components/builders.av:233-244` | 12 | refuses a `req ->` body that holds a setting (`fn_body_setting`), and chooses a Block or a Lambda over the seats. |
| H2 | `build_instance_arms_body` | `components/builders.av:257-271` | 15 | defect refusal when the first arm's pattern is missing (“the arena and the grammar disagree”). |
| H2 | `build_enum_decl` | `enums/builders.av:27-60` | 34 | defect refusal when the declaration has no span (“defect: an enum without a span …”). |
| H2 | `build_bitnot` | `expr_spine/builders.av:110-115` | 6 | refuses when `^` is not an operator the language has (`want(binop_of("^"))`). |
| H2 | `build_catch` | `expr_spine/builders.av:546-598` | 53 | refuses a catch with no arms (“a `catch` needs at least one arm”) and a defect on a union/enum zip; keyword-only empty catch returns the operand. |
| H2 | `build_neg` | `expr_spine/builders.av:173-182` | 10 | refuses when `-` is not an operator the language has (`want(binop_of("-"))`). |
| H2 | `build_fn` | `fns/builders.av:17-67` | 51 | defect refusal when the fn has no span (“defect: …”). |
| H2 | `build_once_fn` | `fns/builders.av:72-99` | 28 | defect refusal when the once fn has no span. |
| H2 | `build_extern` | `fns/builders.av:126-150` | 25 | defect refusal when the extern has no span. |
| H2 | `build_format_pat` | `formats/builders.av:26-33` | 8 | refuses a format whose text is malformed: “a `{` … opens a hole that is never closed”, “a `}` … closes nothing”, “is no hole”. |
| H2 | `build_grammar_lit` | `grammar_lit/builders.av:23-32` | 10 | refuses a grammar literal that does not parse: “the grammar does not parse: …”. |
| H2 | `build_impl` | `impls/builders.av:112-133` | 22 | refuses an item in an impl block that is not a `fn`: “an `impl` block holds `fn` declarations only”. |
| H2 | `build_trait` | `impls/builders.av:147-183` | 37 | defect refusal when the trait has no span (“defect: a trait…”). |
| H2 | `build_comp` | `lists/builders.av:15-23` | 9 | defect refusal when a comprehension has no head. |
| H2 | `build_collect_blockless` | `lists/builders.av:46-48` | 3 | refuses a collect written without its block (`blockless_collect`). |
| H2 | `build_quote` | `quote/builders.av:8-36` | 29 | refuses unequal begin/end hole counts (“a hole is empty — `${e}` takes an expression”, zip defect) and a quote that holds arms and statements (“a quote holds arms or statements, not both”). |
| H2 | `build_type_decl` | `structs/builders.av:21-43` | 23 | refuses a `...` in a struct body (`three_dots`). |
| H2 | `build_struct_lit` | `structs/builders.av:57-70` | 14 | refuses a field-name/value count mismatch (`zip_defect`). |
| H2 | `build_table` | `tables/builders.av:7-34` | 28 | refuses a row that is not a cell list (“defect: a table row that is not a cell list”) and a cell-count mismatch. |
| H2 | `build_when` | `when_expr/builders.av:9-31` | 23 | refuses a `when` with no `_` arm, two `_` arms, or a `_` arm that is not last (“a `when` needs its `_` arm”, “has ONE `_` arm”, “the `_` arm ends a `when`”). |
| H3 | `build_applied_opt_type` | `type_expr/builders.av:6-8` | 3 | builds TypeRef(args from type_refs, optional true) by calling `written`. |
| H3 | `build_applied_type` | `type_expr/builders.av:10-12` | 3 | builds TypeRef(args from type_refs, optional false) by calling `written`. |
| H3 | `build_opt_type` | `type_expr/builders.av:14-16` | 3 | builds TypeRef(no args, optional true) by calling `written`. |
| H3 | `build_plain_type` | `type_expr/builders.av:18-20` | 3 | builds TypeRef(no args, optional false) by calling `written`. |
| H3 | `build_dyn_type` | `type_expr/builders.av:24-26` | 3 | builds TypeRef(dynamic true, optional false) by calling `dyn_written`. |
| H3 | `build_dyn_opt_type` | `type_expr/builders.av:28-30` | 3 | builds TypeRef(dynamic true, optional true) by calling `dyn_written`. |
| H4 | `build_component_value` | `components/builders.av:105-108` | 4 | dispatches to `instance` with a null name. |
| H4 | `build_component_headless` | `components/builders.av:207-210` | 4 | dispatches to `instance` with no heads and no name. |
| H4 | `build_component_blockless` | `components/builders.av:213-216` | 4 | dispatches to `instance` with no block. |
| H4 | `build_component_named` | `components/builders.av:221-223` | 3 | dispatches to `named`. |
| H4 | `build_component_named_bare` | `components/builders.av:226-228` | 3 | dispatches to `named` with no block. |
| H4 | `build_defer` | `defers/builders.av:7-9` | 3 | dispatches to `deferred(b, false)`, which wraps the expression in a zero-seat Lambda. |
| H4 | `build_errdefer` | `defers/builders.av:11-13` | 3 | dispatches to `deferred(b, true)`. |
| H4 | `build_grammar_decl` | `formats/builders.av:51-55` | 5 | dispatches to `declared_format` (SyntaxArena), which refuses undeclarable formats and marks the grammar. |
| H4 | `build_mut_fn` | `impls/builders.av:93-97` | 5 | dispatches to `marked_fn` with the `mut` mark. |
| H4 | `build_static_fn` | `impls/builders.av:101-105` | 5 | dispatches to `marked_fn` with the `static` mark. |
| H4 | `build_break` | `loops/builders.av:40-42` | 3 | dispatches to `labelled(b, false)`: a jump with an optional label read as a name. |
| H4 | `build_continue` | `loops/builders.av:44-46` | 3 | dispatches to `labelled(b, true)`. |
| H4 | `build_quote_pat` | `quote/builders.av:40-46` | 7 | dispatches to `build_quote` and wraps the result as Pat.Quote; refuses when no expression came back. |
| H5 | `build_component_decl` | `components/builders.av:60-94` | 35 | refuses when a made statement is a state declaration or a declaration (`b.store.is_state_stmt`, `is_declaration`), so its refusal depends on what its siblings are. |
| H5 | `build_export` | `modules/builders.av:39-44` | 6 | refuses when the declaration is already marked exported (`b.store.is_exported(d)`). |
| H5 | `build_sublang` | `sublang/builders.av:41-62` | 22 | reads the grammar registry (`b.words.grammars`) to decide the block's view, and refuses a block with a hole mismatch. |

### Five largest H fns (3-line logic summaries)

- **`build_fold_postfix`** (`expr_spine/builders.av:226-405`, 180 lines, H1). Folds `v ( .name | .name(args) | ?.name | [i] | (args) | ?.(args) | { … } | .type(T) )*` left in source order by merging five capture families on their spans. Each link becomes its node (Prop, MethodCall, Chain, Index, CallValue, MatchOpt, type literal), with `?.` forms desugared to matches. Refuses a zip mismatch, a block after a type literal, and a second block.
- **`build_catch`** (`expr_spine/builders.av:546-598`, 53 lines, H2). Picks one of six `catch` surfaces from which captures arrived (value, catch-all, union arm, selective enum, braced union, braced enum) and builds Expr.Catch over Plain arms. Refuses an empty catch (“a `catch` needs at least one arm”); a keyword-only empty catch returns the operand. Zip defects are refused on the union and enum arm lists.
- **`build_fn`** (`fns/builders.av:17-67`, 51 lines, H2). Builds a FnDecl: type parameters zipped with bounds, parameters zipped with types, `mut`, `const`, state, and defaults, aligned by span. Its only H content is the defect refusal when the fn has no span.
- **`build_trait`** (`impls/builders.av:147-183`, 37 lines, H2). Builds a TraitDecl whose members each take their params, return, and body from a span window, marking mutating, static, and trait type parameters. Its only H content is the defect refusal when the trait has no span.
- **`build_component_decl`** (`components/builders.av:60-94`, 35 lines, H5). Builds a ComponentDecl: fields zipped by position, events, record spreads, and marks per token, with the body folded into one quote. H5 is the refusal on a state declaration or declaration among the statements it just made, checked against the store.

## Scope correction

- `features/` has **33** `builders.av` files, not 36. `node_scaffold.av` is a 34th file with no `build_` fn. Six feature directories have no `builders.av` at all: `bool_lit/`, `bytes/`, `cells/`, `ranges/`, `stmt_spine/`, `tests/`.
- Every one of the 33 `builders.av` files contains at least one `build_` fn, so no file is skipped. All 33 were read: the lead's reader read 4 files, the delegated readers read 29 files, and the nine uncovered fns were read directly.
