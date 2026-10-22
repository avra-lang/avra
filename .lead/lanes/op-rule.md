# op-rule lane

## 2026-10-12 22:10 UTC — PHASE A design (no build yet). Worktree ../avra-op-rule exists, NO Sprite free (free: avra-measure-ref avra-triage2 were not bindable in 20s); no compiler binary yet either (42 commits behind). Phase B needs both.

### 1. The ladder today (expr_spine/mod.av:55-68), loosest to tightest
catch(expression) > disjunction `||` > conjunction `&&` > comparison (one optional `op r` OR `is` test) > coalescing `??` > pipeline `|>` > bitwise `| ^ & << >>` > additive > multiplicative > unary (`! - ~`, prefix, right-recursive) > withed (`with {…}` once) > postfix (star of 8 link kinds) > primary.
Builders: fold_binary (left fold, `want(binop_of)`); fold_bitwise (same + REFUSES mixed ops in one run, `a | b & c`; `>>` is two `>` tokens, the second matched and dropped); fold_cmp (no chain: second `<` is left unconsumed so the statement dies there; `is .V`, `is .V(p)`, `is n: T` build Is + payload pattern); fold_coalesce, fold_pipe (application desugar), build_neg/not/bitnot (desugars, literal folding).
ABSORBED by the table: the 8 binary levels (disjunction .. multiplicative, incl. pipe, coalesce, bitwise, comparison incl. `is`).
STAY RULES: unary, withed, postfix, primary, `catch` wrapper (`expression`), `argument`, `trailing`. They are operand-side, not infix. Postfix is a separate construct (below).

### 2. Surface: one rule, an operator table (spelling for your veto)
    expression  = l:unary @operators {
        left 1: "||"
        left 2: "&&"
        none 3: "==" "!=" "<=" ">=" "<" ">"   suffix "is" is_test
        left 4: "??"                -> Expr.Coalesce
        left 5: "|>"                -> pipe_apply
        same 6: "|" "^" "&" "<<" ">" ">"      // `>` `>` : two tokens, as today
        left 7: "+" "-"
        left 8: "*" "/" "%"
    } -> Expr.Binary    // default node of a level; a level may name its own
Associativity words: `left`; `none` (a second operator of the level is not consumed, as `fold_cmp`); `same` (left, and one operator per run: mixing is refused with the LEVEL's voice, replacing mixed_bitwise's call). `suffix W rule` = operator whose right side is a named rule, not an operand (`is`). Higher number binds tighter. The `catch` tail stays on its own rule around `expression`.
Engine: new `Prim`-level item `Operators(levels)` in ast.av (Level{prec, assoc, words: List<List<string>>, suffixes, build}); the DSL grammar (seed.av grammar_of_grammars + compiler grammar/bridge.av) learns `@operators {…}`; validate.av checks levels dense/unique, words non-empty; first.av: the item's first-set is the operand's (operators are never a first token); executor: ONE function `match_operators` = precedence climbing: operand via Ref(l); loop: peek, find the level whose word-run matches (`lit_matches` per word, longest run first), stop if prec < min; consume; rhs = climb(min = prec+1) for left/same/none; build pair via the level's Build over labels l, op, r (so the engine, not the builder, folds); none: after a none-level node, that level is spent for this chain; same: record the level's first op, a different op in the run -> the level's refusal.
Memo/head/trailer: the operand Ref keeps `capped||head`; the climb is inside one rule so memo is per (rule, cursor) as now. @expect/@recover: neither is allowed on the operators item itself (a miss after the operand is just the loop ending; a missing RHS operand is the operand rule's own committed failure, exactly as the ladder's `r:` ref). Line law: untouched, the lexer already drops a break after a trailing operator.
Farthest/expected: at the end cursor the loop does ONE far_merge of a PRECOMPUTED word list = every level's words, tightest first, which is the order the nested stars merge today; a spent `none` level's words are omitted exactly where the ladder omits them (its Opt is not retried). Same for `is`: its words join comparison's, in place.

### 3. What must stay identical, tests written FIRST (against the OLD ladder, before the engine exists)
a) DIFFERENTIAL harness (the real guard): old ladder vs table over (i) the 1,644-file corpus: `fmt --check packages` 0 differing and AST dump byte-equal; (ii) a MUTATION corpus: every file truncated at each 50th token and with one token deleted/duplicated per 50th: diagnostics (message, loc, expected list ORDER) byte-equal. That tests farthest-failure on thousands of cases, not hand-picked ones.
b) golden unit tests per operator: associativity (`1-2-3`, `a??b??c`), precedence pairs across ALL adjacent levels, `-a*b`, `a is .V && b`, `a < b < c` refused with today's words, `a|b&c` refused with mixed_bitwise's words, `a > > b`, `x>>2` vs `List<List<T>>` in type position.
c) keywords: `g.keywords()` list identical (the table's identifier-shaped words — `is` — must be counted by Grammar.keywords: needs an arm for the new Prim, exhaustive match enforces it).
d) every existing parse diagnostic golden unchanged; `make vocab` rows for Prim/Build gain the new arms.

### 4. Landing ladder (generation laws; `cp build/avra build/avra.pre` before each self-build; AVRA_CAP_MB=6000)
 PR1 `grammar: @operators engine` — std-grammar (ast/seed/validate/first/executor/render) + bridge.av + the tests in 3 using data-constructed grammars. NO grammar text uses it, so the standing binary and the seed build it. Gates on the standing seed. Draft, DO NOT MERGE.
 PR2 `seed: carries @operators` — `make seed` refresh only. Required: seed-check compiles HEAD with the seed, and PR3's grammar text is unreadable to an older seed (CLAUDE.md "ADDED GRAMMAR ALTERNATIVE").
 PR3 `expr_spine: the ladder is one table` — mod.av gram text + builders (delete build_fold_binary/bitwise/cmp/coalesce/with-as-fold, mixed_bitwise moves to the level voice) + goldens. First `make avra` succeeds with the OLD engine knowledge only if PR1 is in the standing binary (it is: PR1+PR2 landed first); then `make avra` again (fixed point), seed-check, fmt --check corpus.
 PR4 (later) postfix links. Sketch: `postfix = v:primary @links(v) { "." p:NAME ( "(" a:argument* ")" )? -> Expr.MethodCall(subject = v, …) | "[" i:expression "]" -> Expr.Index(subject = v, index = i) | … }` — each iteration builds a node whose named field takes the previous result; kills build_fold_postfix (180 lines) with a link-by-link span rule. The `?.` desugar-to-match links and the trailing-block/`else` widening reach back into the accumulator, so that part may need to stay a builder: I will measure it before promising the 180 lines.
 Interlock: db07-runs' #630 edits executor.av (run_as / cannot_take) — I add a separate fn and one match arm in match_prim, so I rebase onto it after it lands, never before. nodes-records owns node_scaffold makers; `-> Expr.Binary` uses their Node build, so PR3 follows their Binary conversion or keeps build_binary_pair.

### 5. Expected numbers and deletions
Attempts: ladder 66k of 83.9k now; table leaves ~5.4k operators + 4 operand rules ~= 29k total -> ~1.5 attempts/token (from 4.2), i.e. -65%. Time: the executor is ~90% of a 392 ms parse and per-attempt cost stays; I expect decls.av grammar ~392 -> ~230-260 ms (the climb itself is not free: one loop turn per token). ast+parse of the cold cli check 17-20 s -> ~11-13 s. This is an ESTIMATE; I will report the measured figure, and drop the plan if the decls harness shows < 20%.
Deleted: 8 rules, 5 builder fns (fold_binary/bitwise/cmp/coalesce + tail of pipe) ~ 60 lines of Avra, 8 table rows; added ~150 lines of engine.
Open questions for you: (1) `suffix` and `same` spellings OK? (2) PR3 waits on nodes-records' Binary conversion, or keeps one pair builder? (3) a Sprite + a compiler for the lane.

## 2026-10-12 ~22:50 UTC — Phase B started (PR1 only, per lead rulings)
- Sprite avra-measure-ref bound; compiler builds there (first run ~4 min bootstrap).
- Engine drafted, `check packages/std-grammar` clean (warnings only): ast.av (Assoc/Tier/Suffix/OpEntry/Operators, Seq.operators), operators.av (tables), seed.av + builders.av (`@operators { left "||" … none … suffix "is" rule … unmixed(refuse) … (">" ">") -> build }`), validate.av, render.av, executor.av (`climb`).
- Reserved word hit: `level` is reserved (resolve.reserved) -> the word is `tier` in code. DSL: no numbers, order = precedence loosest first; lex_grammar emits no BREAK inside a rule, so tiers delimit by their assoc word.
- Next: harness (ladder vs mutated ladder fails first, then vs table), parse_test dsl_text update, measure.

## 2026-10-12 ~23:10 UTC — status
- Sprite bootstrap done (compiler warm). `check packages/std-grammar` clean (warnings only).
- Harness written: std-avrac/src/grammar/tests/operators_diff_test.av (ladder vs table over ~45 written inputs + all their token-prefixes + 1500 LCG-generated; compares tree, message, loc, expected list, in_rule). Control spec (ladder with add/mul swapped) PASSES: the comparison names "a * b + c" first.
- Ladder-vs-table spec first run trapped (reach[] index = tier count); fixed (reach has n+1 rows). Re-run in flight now. parse_test.av dsl_text updated for the new DSL rules.
- attempts/token: not measured yet (needs the table to agree first).

## 2026-10-12 22:52 UTC — from db07-runs: capture-frame API (DB 09 step 3), for your rebase

- Assembly: each Rule gets its distinct label slots (first-seen order); each Item carries `slot: int` (-1 = none).
- `match_rule` allocates ONE frame per rule attempt: `filled(slot_count, null)`.
- A branch attempt copies the frame once (`mut f = frame`), then `f.set(slot, v)` per bind. No `bindings.concat` per bind, no `any`/`find` scan.
- `binding_for` becomes `frame[slot]`; repetition accumulation reads the slot.
- Builders get args in slot order, fixed at assembly.
- Your `match_operators` should take the frame in and return the frame out, the same as `match_seq`, so PR3 rebases onto this with no extra shape.
- I am not building this until the lead rules on the order (literal ids first, or capture frames first). Reply here if you need a different signature.

## 2026-10-12 ~23:35 UTC — not idle; harness green
- Harness (std-avrac/src/grammar/tests/operators_diff_test.av) is PROVEN BOTH WAYS on the Sprite: control spec (ladder with add/mul swapped) names "a * b + c" as the first differing input; the real spec — ladder vs `@operators` table over 45 written inputs + all their token prefixes + 1500 generated (tree, message, loc, expected-word order, in_rule) — passes, 2/2. It first failed on my own harness bug and on a reach[] off-by-one, both fixed. Only normalization: in_rule of a builder refusal names the table rule instead of the tier rule (tier rule names do not exist in the table) — PR3 must check whether any golden pins that.
- Now: fmt --check + idioms baseline on the touched files (run in flight), then std-grammar + std-avrac grammar suites, PR1 draft with before/after text. Will rebase onto the capture-frame work (#630/#640) after it lands; match_seq edit is 15 lines + `built` takes a Build?.

## 2026-10-13 ~01:30 UTC — PR1 open: #661 (DRAFT, DO NOT MERGE)
- Green on the Sprite: idioms baseline no NEW (fixed 3: duplicated message, nullable flag local, seed_test rule count 10->13); std-grammar 28/28; std-avrac grammar executor 38, parse 5, compose 6, builders 15, operators_diff 2/2; fmt clean.
- Not yet: attempts/token and decls.av ms (need PR3's real grammar; next I build a throwaway version of expr_spine on the Sprite to measure before promising). CI result pending.

## 2026-10-13 — parser differential harness is built: use it, do not write a second one

- Tool: tools/parse_diff.py on branch parse-diff, draft PR #668 (DO NOT MERGE). Stdlib Python, no build step.
- Usage: `python3 tools/parse_diff.py --a <A> --b <B> --walk --mutants --shard I/N --mutant-stride 256 --check-every 64`; `--self-test` runs without a compiler.
- It compares, byte for byte: `fmt --check` of the tree (one walk, or per file), `fmt --check` of each mutant, `check` stdout+stderr of sampled mutants (expected-word order included). Mutants: truncate / delete / duplicate every 50th token.
- Two-binary rule: the store is cleared between A's and B's units, per shard.
- Exit codes: 0 no differences, 1 differences, 2 nothing examined.
- Shown failing on a perturbed binary: 9 differences in 21 mutant checks (perturbation: the group's close voice reads differently).
- Your use: run it with A = main's binary and B = your branch's binary, and give a count of files and mutants examined. The shard command is the same; pick the --mutant-stride so a shard fits a bounded run.

## 2026-10-13 ~02:10 UTC — #661 gate red, cause found; measurement blocked by the generation law
- #661 `gate` failed on 2 NEW idioms in my test file: compiler.one_body_arms (`"lit"`/`"id"` arms with one body -> joined with `or`) and fns.dead_parameter (`loc` -> `_loc`, stale LICENSED comment dropped). Fix in the tree; re-running `check --baseline packages/std-avrac` on the Sprite before pushing.
- Throwaway measurement (expr_spine rewritten to the table, uncommitted): failed with "references undefined rule operators / builder never called" — NOT a table bug: the Sprite's standing build/avra had been rebuilt by `make bootstrap` from the committed SEED, which predates `@operators`, so it cannot read the new grammar text. This is the PR2 (seed refresh) rung showing up early: a compiler that READS `@operators` must be built from the PR1 tree first (gen1 via bootstrap, gen2 via make avra) and only then can compile a grammar that uses it. Current run builds that compiler and saves it as build/avra.base; then I apply the throwaway and measure idioms.av (72 KB, 0 `is` expressions, since `is` needs the suffix builder only PR3 writes).

## 2026-10-13T03:17:42Z — fold inventory from nodes-records (expr_spine/builders.av, origin/main 444e00b5 + stack)
| fn | lines | what it hides |
|---|---|---|
| build_fold_postfix | 180 | one fold over ten postfix forms: Prop / Chain / MethodCall / MatchOpt / Index / CallValue / Force / Propagate / Lambda (trailing block), type literal; mixes captures flat by position (q p mo ma i co ca f tb te tt tq cq), desugars `?.` into a match, trailing-block lifts, `else` fills a fn seat |
| build_fold_binary | 10 | left fold of `l (op r)*`, op token -> BinOp |
| build_fold_bitwise | 12 | same fold, one band of ops (tighter than comparison) |
| build_fold_cmp | 11 | `l (op r)?` never a chain; or `l is .variant` -> Expr.Is |
| build_fold_with | 9 | `v (with { f: e, .. })?` absent tail is v itself |
| build_fold_coalesce | 8 | left fold of `??` |
| build_neg | 10 | folds a literal operand (`-5` -> IntLit, float sign bit) else Binary(0 - v) |
| build_catch | 53 | not a fold: arm patterns (Plain + Scoped bind) from two spellings, Result desugar |
| build_trailing | 10 | trailing block as a lambda: written seats or the pronoun seat (uses marked_seats) |
Binary folds total ~50; postfix + catch are the bulk (~230 with the rest). After the stack (#635..#673) these are untouched; seats they read (marked_seats, window_end) are the only helpers still shared with them.

## 2026-10-13 ~08:50 UTC — status (3 items owed)
### (1) measurement: NOT a number yet — what stopped it, and the fix in flight
- 4 attempts; each failure was the generation law, not the table: (a) Sprite binary rebuilt from the SEED (cannot read `@operators`); (b) `grammar {}` literals are serialized to code at compile time (features/grammar_lit/builders.av `seq_expr`) and that dropped `Seq.operators` -> fixed in PR1 (`operators_of([Tier{…}])`, `Tier/Assoc/Suffix` imports needed in the using file); (c) features/coherence.av counted only `Seq.build` as "called", so tier builders read as dead -> fixed (`branch_calls`); (d) the throwaway product (table grammar, no `is`) cannot compile the compiler's own source, so `make avra`'s second build fails and the harness bootstraps over it. Now: `make try` builds the candidate beside the base, script `tools/_op-rule_5.sh` (running) times `fmt --check compiler/idioms.av` x10 for both. idioms.av has no `is` expression, so the throwaway needs no suffix builder. Numbers will be appended here.
- Cost to know for PR3: tier `Node` builds are refused (validate) until node_grammar.av binds them.
### (2) #661
- pushed 5814f2ad (gate idioms). Local, NOT pushed yet (one push per unit): grammar_lit serializer + coherence.av tier builders + validate tier-Node refusal. Not rebased onto 98b652a5 yet. parse_diff not run (it belongs to PR3: a corpus differential needs the table grammar in the compiler).
### (3) postfix design note (for the owner's eye, before any build)
Today: ONE star over 11 link kinds; each kind captures into its own label family (names, opens, margs, indexes, calls, cargs, forces, blocks, elses, spellings, chained, call_chains) and `build_fold_postfix` (180 lines) re-merges the families by SOURCE SPAN with 8 cursors, plus `more_links`/`next_anchor`/`args_between` to recover where each link ends.
Proposed construct: `@links(v)` — an ordered repeat of link branches, each branch's build receives the PREVIOUS result as `v`:
    postfix = v:primary @links(v) {
        "." "type" "(" t:type ")"                      -> type_literal(v, t)
        "?." "type" "(" t:type ")"                     -> chained_type_literal(v, t)
        "." p:NAME "(" ( a:argument ( "," a:argument )* ","? )? ")"   -> method_call(v, p, a)
        "?." p:NAME "(" ( a:argument ( "," a:argument )* ","? )? ")"  -> chained_call(v, p, a)
        "." p:NAME                                     -> prop(v, p)
        "?." p:NAME                                    -> chained_prop(v, p)
        "[" i:expression "]" @expect("]", "expected `]` to close the index")  -> index(v, i)
        "(" ( a:argument … )? ")"                      -> apply(v, a)
        "?." "(" ( a:argument … )? ")"                 -> chained_apply(v, a)
        f:( "!" | "?" )                                -> force(v, f)
        tb:trailing ( "else" te:trailing )? @trailer(tb) -> trailed(v, tb, te)
    }
Engine: a Seq with `links` runs `match_alt` over the link branches in a loop (the head-law `@trailer` mark stays on `tb`); each branch gets its own capture scope (so no family merging), the engine adds the label `v` = the accumulator, and the loc handed to the builder is operand-start..this link's end — which retires `more_links`, `next_anchor`, `args_between`, `span_lo/hi`, `call_hi` (the span arithmetic exists only to find where a link ends). The same `v` convention as `@operators`' `l`.
What still reaches the accumulator: `trailed` widens the call built so far (the builder reads `v`); the "second block" and "block after a type literal" refusals need to know what `v` is — today two loop flags; they become two store questions (is `v` a trailed call / a type literal), i.e. one mark each on the node, or kept as the two refusals reading `v`'s node. `?.` desugar to a match is per branch (chained_call/chained_apply exist already).
Net: build_fold_postfix 180 lines + 5 helpers (~100) -> 11 builders of 3–6 lines (several exist). Estimated -190 lines, grammar line grows by ~11 short branches.
Risk: farthest-failure words for a failed link — same differential harness applies (ladder vs links).

## 2026-10-13 ~11:40 UTC — status after the stop/resume
- (1) Measurement: the throwaway-grammar product (table) does NOT assemble; cause not yet isolated. Facts: DSL line of the throwaway parses clean in the mini harness (probe test, base compiler); the product built from it reports `expression: references undefined rule operators` and every rule after `stmt` missing, i.e. the compile-time grammar literal for expr_spine comes out truncated. Suspect: the literal's serialization (features/grammar_lit) of the real, large grammar, or a node_grammar/compose pass that rebuilds Seq without `operators` (bound_seq uses `s with {…}` so keeps it; collected.av `sole_labeled/synthesized_build` build new Seqs). NOT chased further: it is a PR3 bring-up item.
- INSTEAD, a like-for-like proxy: same executor, same token streams, mini language ladder vs table (bench_*_test.av, 25 inputs x 60 loops = 1500 parses): wall 30 s vs 30 s including a ~30 s compile -> parse cost below the noise at that size. Re-running at 40x the work now; no go/no-go claim from the proxy until that lands. The real <20% question stays open until the throwaway assembles.
- (2) #661: rebased onto origin/main 7f12f428; 3 commits (engine, test fixes, serializer+coherence+validate). Verification run on the Sprite in flight (fmt on the 3 new files, check --baseline std-avrac, operators_diff, parse, std-grammar). Pushing ONCE after it is green.
- (3) postfix note additions:
  * `@links(v)` engine cost, by file: ast.av ~8 (Seq.links: Links?), seed.av ~25 (annot + a `link` rule; a link branch ends at its `->`, so no separator is needed), builders.av ~25, executor.av ~45 (`links` loop: match_alt over the branches, bindings + `v`, loc = operand-start..link-end, same refusal path as climb), validate.av ~20 (every branch builds; `v` counts as a capture; trailer/head marks checked), first.av ~10 (link literals `?.`, `else`, `type` claim keywords), render.av ~15, grammar_lit ~25, coherence ~8: ~180 total, ~75 of it in executor+validate+first. Removes ~280 (build_fold_postfix 180 + helpers).
  * `a.b(` unclosed: BEFORE = measured below (to be filled by the probe); AFTER = predicted, not measured: each link branch is tried in order and fails at the same `)`, the property branch `"." p:NAME` then succeeds and `(` fails as an apply link at the same cursor, so farthest is the same cursor with the same expected set and the same rule name `postfix` -> text unchanged. That prediction is what the ladder-vs-links differential test would prove; I will not claim it before it runs.

## 2026-10-13 ~13:10 UTC — #661 pushed once (1329f160), rebased on origin/main 0e1126a2
- Sprite verification of the rebased tree (binary fea4a1e62109, built by bootstrap): operators_diff 2/2, parse_test 5/5, std-grammar 28/28, `check --baseline` std-avrac: no NEW; fmt --check flagged the 3 files of the 3rd commit -> fmt --write, amended, pushed (one push).
- Measurement: still not a number. Next step is isolating why the product built from the table grammar drops the rules after `stmt` (below the lane-file line for 11:40). Note for later: after #734 (`select`) merges, bootstrap before measuring. executor.av: I will touch only `match_seq`'s 15-line operators hook and the climb fns at the file's tail; nodes-self owns the choice dispatch — I will not edit match_alt/starts_at.

## 2026-10-13 ~21:50 UTC — DROP ISOLATED (generation law) + numbers measured (lane worktree /Users/tristan/projects/tristanMatthias/avra-op-rule)

### (1) The drop: NOT a table-grammar bug. It is the generation law + a silent-accept hole.
Built by a compiler whose DSL seed knows `@operators`, the table grammar assembles and parses cleanly.
- `_or_3.sh` on Sprite avra-measure-ref (tree = PR1, `make avra` once -> gen1 that knows @operators, then apply the
  throwaway, then `make try`): `gen1 exit 0` / `try exit 0` / `try: build/avra-try` / `held 0/470`.
  Product sanity: `build/avra-try fmt --check packages/std-grammar/src/seed.av` ->
  `fmt --check: 1 examined, 0 differing, 0 refused`. No dropped rules.
- The earlier drop was the builder predating PR1: the committed `bootstrap/seed.ll` has **0** occurrences of
  `build_operators`, `AOperators`, `operators_of` (its only `operators` is the doc string "bitwise operators").
  A compiler built from that seed runs a `grammar_of_grammars` with no `@operators` branch, so while compiling
  `expr_spine/mod.av` the DSL parse stops at the `operators` rule and every rule after `stmt` is lost
  (`expression` then references undefined `operators`).
- REPRODUCED the assembly (not the drop) with the lane's saved `build/avra.base` (a correct-gen compiler):
  product built by it, standing beside `build/avra`, reports ONLY the missing-`is` errors —
  `error[parse.expected]: expected BREAK while parsing stmt` at `tail.prim is .Group` (ast_test.av:162) and
  `if answer is .Void` (std-meta/meta.av:135) — and NOTHING about `operators`. The table assembled in full;
  only the omitted `suffix "is"` refused.
- WHY THE DROP WAS SILENT: `features/grammar_lit/builders.av::build_grammar_lit` tests only
  `if gp.built == null`. `parse_grammar` returns a PARTIAL `built` plus a `Cause.Trailing`
  "unexpected input after `grammar`" when the start rule hits with tokens left, and that diagnostic is
  discarded. Remedy (not committed — freeze): refuse when `gp.diagnostics` is non-empty (or on Trailing),
  which turns the next silent truncation into a loud refusal.
- Verified: `_or_6.sh` showed the test binary must stand beside `build/avra` for `@std/*` to resolve.

### (2) The numbers (measured)
Operator table, `fmt --check --time`, `ast` phase (lex+build = parse), both binaries built from the same tree
(ladder = `build/avra.op`, table = `build/avra-try`):
| file | ladder ast ms | table ast ms | change |
|---|---|---|---|
| `packages/std-grammar/src/seed.av` (424 ln, 0 `is`) | 46.6 / 60.9 / 47.1 (med 47.1) | 29.3 / 29.3 / 31.2 (med 29.3) | **-38%** |
| `packages/std-grammar/src/builders.av` (423 ln, 0 `is`) | 62.0 / 67.5 / 63.3 (med 63.3) | 44.6 / 41.3 / 44.5 (med 44.5) | **-30%** |
Both clear the <20% go/no-go. Caveat: the throwaway omits the `is` suffix; these files use no `is`, so the win
is the operator climb.

Postfix `@links(v)` line/def count (exact, `expr_spine/builders.av`):
`build_fold_postfix` **184** lines; retired helpers `more_links` 26 + `next_anchor` 21 + `call_hi` 11 +
`span_hi` 10 + `args_between` 9 + `span_lo` 5 = **82**; total **266** lines retired. The 11 link builders of
3–6 lines (~50) replace it, and 4 already exist (`chained_call` 10, `chained_apply` 9, `prop_link` 7,
`force_link` 7). Net ≈ **-200 lines** (lane estimate -190).

### (3) Next step
Add `suffix "is" is_test` to the table (removes the last caveat; let it compile the compiler's own source),
then PR3 bring-up; and land the `build_grammar_lit` refusal so a seed-behind drop is loud.

### (4) Blockers
FREEZE (#710): no landing. #661 rebased onto b0d98c49 and pushed as a DRAFT (`d8656224`), NOT armed.

---

## 2026-10-13 ~23:45 UTC — THREE ITEMS DONE (worktree ../avra-op-rule, Sprite avra-measure-ref)

### (1) The `build_grammar_lit` refusal — its OWN draft PR

Off `main` b0d98c49, branch `op-rule-refusal`, commit **`d868fd43`**, DRAFT PR **#752** (not armed).

`parse_grammar` answers a NON-NULL `built` whenever the start rule hits, plus a
`Cause.Trailing` diagnostic when tokens are left. `build_grammar_lit` tested only
`if gp.built == null`, so a partial DSL parse became a tree silently. Fix: refuse when
`built` is absent OR any diagnostic is not a coherence defect (`Cause.Defect` — those are
gated where the assembled grammar validates, so no double-report).

Fixture (in `grammar_lit_test.av`, its last `then`):

    then "a start rule that hits with tokens left refuses rather than keeps a partial tree" {
        refused_with(
            "let g = grammar {\na = \"x\" -> f()\nb =\n}\n1",
            "the grammar does not parse",
        )
    }

`rule+` matches `a`, stops at `b =`, and the parse still answers a Grammar.

WITNESS (Sprite, one generation rebuilt with the condition reverted):
- refusal present: `13/13 tests passed`
- refusal removed: `12/13 tests passed`, the failure naming exactly the new case at
  `grammar_lit_test.av:190` (the other 12 pass, so it fails for the right reason).
- `./avra fmt --check` on both changed files: `2 examined, 0 differing`.

This is the "a check that examined nothing is not a check that passed" law: the partial
DSL parse is now loud, which is what would have turned the 2026-10-12 @operators
truncation into a refusal instead of `references undefined rule operators`.

### (2) `suffix "is" is_test` added; re-measured

The table now carries `none "==" ... suffix "is" is_test -> build_cmp(l, op, r)`;
`is_test` builds the SEAT as a `Pat` (`Pat.Variant(name, payloads)` / `Pat.Typed(name, ty)`) and
the tier builder reads it (exported `pat_id_at`) and builds `Expr.Is(l, name)` + marks the
payload — mirroring `asked_expr`/`narrowed_expr`, INCLUDING not marking a payload-free
variant (always marking produced a false `type.is_bind` on `tail.prim is .Group`).

`fmt --check --time`, ast phase, both binaries built from the same base (ladder = `build/avra`,
table+is = `build/avra.table`), 7 runs each, median:

| file | ladder ast ms | table+is ast ms | change |
|---|---|---|---|
| `packages/std-grammar/src/seed.av` (424 ln) | 43.7 | 27.5 | **-37%** |
| `packages/std-grammar/src/builders.av` (423 ln) | 58.0 | 38.5 | **-34%** |

Prior run (no `is`): seed 47.1 -> 29.3 (-38%), builders 63.3 -> 44.5 (-30%). Both clear the
<20% bar; `is` does not change these two files' number (they use no `is`) and removes the last
caveat.

AND IT NOW COMPILES THE COMPILER'S OWN SOURCE: `build/avra.table check
packages/std-grammar/src/seed.av` -> 0 errors; `build/avra.table check packages/std-meta/src/meta.av`
(heavy `is` use, `if answer is .Void`) -> 0 errors. `fmt --check` on seed.av, builders.av and
meta.av: `0 refused` for both engines. The product was built by a `@operators`-aware gen1; the
committed seed must be refreshed (PR2) before a table grammar text is readable.

Measurement vehicle kept at `tools/_or_throwaway2.patch` (untracked/ignored, PR3's table,
including `is`) and `tools/_or_1..18.sh`.

### (3) PR3 bring-up plan

`@links(v)` — a `Seq` runs its link branches in a loop, each branch's builder receiving the
accumulator as label `v` (the `@operators` `l` convention) plus its own captures, loc =
operand-start..link-end:

    postfix = v:primary @links(v) {
        "." "type" "(" t:type ")"                                -> type_literal_link(v, t)
        "?." "type" "(" t:type ")"                              -> chained_type_literal(v, t)
        "." p:NAME "(" ( a:argument ( "," a:argument )* ","? )? ")" -> method_link(v, p, a)
        "?." p:NAME "(" ... ")"                                -> chained_call(v, p, a)   // exists
        "." p:NAME                                             -> prop_link(v, p)         // exists
        "?." p:NAME                                            -> chained_prop(v, p)
        "[" i:expression "]" @expect("]", "...")               -> index_link(v, i)
        "(" ( a:argument ... )? ")"                             -> apply_link(v, a)
        "?." "(" ( a:argument ... )? ")"                        -> chained_apply(v, a)     // exists
        f:( "!" | "?" )                                       -> force_link(v, f)        // exists
        tb:trailing ( "else" te:trailing )? @trailer(tb)       -> trailed(v, tb, te)
    }

- The engine adds `Seq.links` and a `links` loop over `match_alt` (each branch its own capture
  scope, so no family merging), plus `v` as a supplied binding and the link's span. Arms in
  ast / seed (annot + a `link` rule) / builders / executor / validate / first / render /
  grammar_lit / coherence (~180 lines, ~75 of it in executor+validate+first).
- RETIRES `build_fold_postfix` **180** lines + helpers `more_links` 24, `next_anchor` 19,
  `args_between` 8, `call_hi` 4, `span_hi` 4, `span_lo` 4 = **63** (measured now; the earlier
  184/82 note in this file was an estimate) — total **243**. The 11 builders are 3–6 lines
  (~50; 4 exist: `chained_call` 6, `chained_apply` 6, `prop_link` 4, `force_link` 4).
  Net ≈ **-190 lines**.
- What reaches back into the accumulator: the two refusals ("a second block", "a block after a
  type literal") become store questions on `v` (one mark each) rather than loop flags; the `?.`
  desugar is per branch (already exists).
- Farthest-failure words for a failed link must be proven by the ladder-vs-links differential
  (tools/parse_diff.py, #668) — predicted same cursor/expected set/rule, NOT yet measured.
- WHERE `is` FITS: the table (from the throwaway) lands WITH the suffix, and the comparison
  tier's build dispatches on the `is` word to build the seat node. PR3 may instead give a
  `Suffix` its own build (an engine change) to avoid a word check; decide at bring-up.
- INTERLOCKS: rebase `match_links` onto db07-runs' capture-frame API (#630/#640) — same
  frame-in/frame-out shape as `match_seq`; `Expr.Binary` makers are nodes-records'.
- LADDER: PR1 engine (#661 `d8656224`) -> PR2 seed refresh -> PR3 table+links (delete the
  now-dead `additive`/`multiplicative` rules) -> PR4 the remaining shared shapes.

### (4) Shas + blockers

- #752 `op-rule-refusal` head **`d868fd43`** — DRAFT, not armed (the refusal).
- #661 `op-rule` head **`d8656224`** — still DRAFT, not armed (PR1 engine); untouched this run.
- No blocker on items 1-3. The item-2 product build stalled the Sprite twice under
  `make try` (OOM); a fresh Sprite completed it (`try exit 0`). FREEZE (#710) still blocks landing.

---

## 2026-10-14 00:45 UTC — #752 REBASED + GREEN on 707ab829; PR2 ladder plan

### (1) #752 rebased head + green receipts

`op-rule-refusal` rebased from `d868fd43` onto main **`707ab829`** -> head **`46b74f3d`**
(clean one-commit rebase; `b0d98c49` is an ancestor of `707ab829`, so no conflict).
Force-pushed: `git ls-remote origin refs/heads/op-rule-refusal` =
`46b74f3dd6f7ebe1bfc1434cb3f2f8323f4d70c5`. PR **#752** now reports head `46b74f3d`,
DRAFT, `autoMergeRequest: null` (NOT armed).

Verified on Sprite `avra-measure-ref` (`sh tools/work run --for 40 'sh tools/_or_19.sh'`,
`_or_20.sh`, `_or_22.sh`), `build/avra` = gen-2 from the post-flip seed:

- `make bootstrap` — `BOOT-LAST: bootstrap: build/avra is gen-2` (`recover` from the seed,
  then gen-1, then gen-2; source hash `ec9f039df511`, binary `20c38e80c4ac`).
- gate (`sh tools/gate_changed.sh --files packages/std-avrac/src/features/grammar_lit/builders.av
  packages/std-avrac/src/features/grammar_lit/tests/grammar_lit_test.av --packages std-avrac
  --no-keepers --pr-minimum`) — `GATE-LAST: gate_changed: clean — changed .av and affected idioms hold`.
- `make keepers-static` — **GREEN locally** (`LOCAL keepers-static exit 0`, last line
  `pipeline-doc: docs/2026_10_11_THE_PIPELINE.md — every command resolves (123 target(s) declared, 22 tools/ path(s) named)`,
  `fetch_compiler: self-test clean — 12 case(s)`). On the Sprite it refused ONLY
  `ci-invariants` because `tools/work`'s rsync excludes `.git`, so `fetch_compiler`'s self-test
  reports `no git repository here` (4 cases) — the other 12 keepers were green there. This is the
  "A COMPILER UNDER TEST MUST STAND WHERE A COMPILER STANDS" family; CI runs on a checkout, and
  #661's own `keepers-static` check passes on the runner.
- `make cache-attacks` — exit 0; `CA-LAST: cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`;
  every attack 0 failed (`static-names-attack: 15 kept object(s) byte-identical warm and cold, 0 failed`,
  `moved-tree-attack: one package built at two depths, 0 failed`,
  `held-runs-attack: ... rebuilt with 1 turned attempt(s), 0 failed`,
  `turn-memory-attack: ... 0 failed`).
- `avra test packages/std-grammar` — exit 0; `GRAMMAR-LAST: 28/28 tests passed`.
- `avra test packages/std-avrac` (the compiler package the change reaches) — exit 0;
  `8805/8805 tests passed`, `349 programs proved`, `watch: peak 3128 MB, status 0`.
- `fmt --check` on both changed files is the gate's `clean` line above.

GitHub's check on the new head is queued (`prepare pending`) at the time of writing; the runner is
CI's to answer.

### (2) Fixture + witness re-verified on 707ab829 (`tools/_or_21.sh`, one generation)

- refusal present — `PRESENT-LAST: 13/13 tests passed`
- condition reverted (`if gp.built == null || gp.diagnostics.any(it.cause != Cause.Defect)` ->
  `if gp.built == null`), `make avra` ONCE — `REVERTED-LAST: 12/13 tests passed`, the one failure
  naming exactly the new case at
  `packages/std-avrac/src/features/grammar_lit/tests/grammar_lit_test.av:190`
- restored — `RESTORED-LAST: 13/13 tests passed`

### (3) PR2 seed-ladder plan (written, NOT built)

**Why a refresh is owed.** `make seed` (Makefile:381) does `./avra emit packages/cli >
build/seed.ll.new`, refuses under `SEED_FLOOR := 100000` lines, `mv`s to `bootstrap/seed.ll`, and
writes `sh tools/sources_hash.sh > bootstrap/seed.sources`. Today's seed (#710) is
`bootstrap/seed.sources` = `1668bfad6ee095ed5d942ba7ead83956925d378aedea1975990be98373bc8641`,
`bootstrap/seed.ll` = 62519330 bytes. It carries the `within` flip but NOT `@operators`, so a
compiler built from it cannot read a grammar text that uses `@operators` (its
`grammar_of_grammars` stops at the `operators` rule and every rule after `stmt` is lost).
`seed-check` compiles HEAD with that seed, so a tree whose grammar text uses `@operators` is red
until the seed is refreshed.

**The two landings, and the refresh between them.**

*Landing 1 — the ENGINE (ROW), gates on the standing seed.* No grammar TEXT uses `@operators`, so
the committed pre-`@operators` seed compiles HEAD. This is #661's content
(`op-rule` @ `d8656224`, to be rebased onto main when it lands):

- `packages/std-grammar/src/ast.av` — `Assoc`, `Tier`, `Suffix`, `Operators`; `Seq.operators`
- `packages/std-grammar/src/operators.av` — NEW; the tier/word tables
- `packages/std-grammar/src/seed.av` — the `@operators { … }` DSL rule and its `grammar_of_grammars` arm
- `packages/std-grammar/src/builders.av` — the tier builders
- `packages/std-grammar/src/executor.av` — `match_operators` / the precedence climb
- `packages/std-grammar/src/validate.av` — tiers dense/unique, words non-empty
- `packages/std-grammar/src/render.av`
- `packages/std-avrac/src/features/coherence.av` — tier builders count as "called"
- `packages/std-avrac/src/features/grammar_lit/builders.av` — the literal serializer writes
  `Seq.operators` (`operators_of([Tier{…}])`). **THE ONE FILE #752 ALSO EDITS.**
- tests: `packages/std-grammar/src/tests/seed_test.av`,
  `packages/std-avrac/src/grammar/tests/parse_test.av`,
  `packages/std-avrac/src/grammar/tests/operators_diff_test.av` (new)

*Seed refresh (PR2) — commits exactly two artifacts, no `.av`:*

- `bootstrap/seed.ll`
- `bootstrap/seed.sources`

Run on the post-#661 tree with a `@operators`-aware compiler (`make bootstrap`, then `make avra`),
it must be a standalone landing so every other open PR's `seed-check` moves to the new seed at once.

*Landing 2 — the DECLARATION (the table + `suffix "is"`), gates because the seed now knows the row:*

- `packages/std-avrac/src/features/expr_spine/mod.av` — replace the 8-rule ladder with one
  `l:unary @operators { left "||" left "&&" none "==" "!=" "<=" ">=" "<" ">" suffix "is" is_test -> build_cmp(l, op, r) left "??" -> build_coalesce_pair(l, op, r) left "|>" -> build_pipe_pair(l, op, r) unmixed(build_mixed) "|" "^" "&" "<<" (">" ">") -> build_bitwise_pair(l, op, r) left "+" "-" left "*" "/" "%" } -> build_pair(l, op, r)`,
  plus `is_test = ( "." iv:NAME ( "(" … ")" )? | an:NAME ":" at:type_atom ) -> build_is_seat(…)`
- `packages/std-avrac/src/features/expr_spine/builders.av` — add `build_pair`, `build_coalesce_pair`,
  `build_pipe_pair`, `build_bitwise_pair`, `build_mixed`, `build_cmp`, `is_test_node`,
  `build_is_seat`, and export `pat_id_at`; DELETE `build_fold_binary`, `build_fold_bitwise`,
  `build_fold_cmp`, `build_fold_coalesce` and the 8 ladder rules; `mixed_bitwise` becomes the
  tier's `unmixed` refusal voice
- the goldens/tests the table pins

The measurement vehicle is `tools/_or_throwaway2.patch` (untracked/ignored, PR3's table incl. `is`):
seed −37%, builders −34%, and it now compiles the compiler's own source.

**Order:** (1) #752 lands (queued behind #742 and #735; #727 already landed). (2) #661 rebases onto
the post-#752 main, bootstraps, lands = Landing 1; the rebase must reconcile the
`grammar_lit/builders.av` overlap (#752's `build_grammar_lit`/`unparsed` vs #661's imports and
`operators_expr`). (3) PR2 (seed refresh) lands immediately after #661, before any grammar text
uses `@operators`. (4) PR3 = Landing 2 rebases onto the post-PR2 main; `make bootstrap` now
succeeds because the seed reads `@operators`, and `seed-check` compiles HEAD with the refreshed
seed. #752 first matters because, without the refusal, a pre-`@operators` compiler truncates the
table grammar SILENTLY (`references undefined rule operators`); with it the truncation is the loud
`the grammar does not parse`.

### (4) #661 state

`op-rule` head **`d8656224`** (3 commits on `b0d98c49`), DRAFT PR **#661** titled "DO NOT MERGE:
grammar: @operators — precedence-climbing branch (op-rule PR1)", `autoMergeRequest: null`, NOT
armed, `mergeStateStatus: BEHIND`. Its earlier full CI run is GREEN (`gate`, `keepers-static`,
`seed-check`, `suites (std-avrac)` and every other suite pass) — as expected for an engine-only
change. It needs the same rebase onto current main + a fresh bootstrap before landing, and it
overlaps #752 in `packages/std-avrac/src/features/grammar_lit/builders.av` (so #752 must land
first). Untouched this run.

### (5) Blockers

None for #752. The `make keepers-static` Sprite refusal is environmental (no `.git` in the synced
tree), not the change; it is green on a checkout. Main advanced to **`7a5b4b78`** (batch #12 / #727)
during this run, so the PR is `BEHIND`; per the queue #752 waits behind #742 and #735, and the lead
rebases before arming. Not armed, no `--admin`, no push to main.
