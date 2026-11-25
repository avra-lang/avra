# DB07 lane — HANDOFF (parse_diff harness, #630 vs main)
- Harness: tools/parse_diff.py, draft PR #668 (DO NOT MERGE), branch parse-diff; self-test passes; exit 0 no diff, 1 differences, 2 nothing examined.
- Usage: parse_diff.py --a <binary A> --b <binary B> --walk --mutants --mutant-stride 256 --shard I/16 --check-every 64 --corpus <tree>.
- Perturbed-binary check: 9 diffs in 21 mutant checks, exit 1 (the harness does fail when it should).
- #630 (first-sets) vs main 02874a27, corpus = parse-diff tree: walk of 1775 .av files, 0 differences.
- Mutant shards 0 through 15 of 16 (stride 256): 0 differences in every shard, about 42 mutants each.
- Verdict: #630's parser matches main on the walk and on all 16 mutant shards. No differences found.
- CI: #609 and #630 green on the required checks. #630 is in batch 9 (#657), landing after #642.
- Parked: DB 09 double-parse (145/505 files parsed twice, <=3.5 s; needs words-before-parse); no PR.
- Not pursued: frames (~4–6%), memo (~0–2%), literal ids (~2.5%); executor micro-cuts exhausted.
- Op-rule lane uses parse_diff.py for its table work (see .lead/lanes/op-rule.md). Lane parked; no new work.


## 2026-10-12 — parse cuts, report 1 (cut 1 done, cut 2 reported as a design choice)

- PR #588 closed with the comment "no measured gain; the discard-count fix can ride a later PR".
- Parse profile: delivered earlier (parse-profile branch, ac50eb35, probes local).
- Cut 1 (branch parse-cuts, commit 96504db1, draft PR #609, DO NOT MERGE): core/shape.av `bound_hole`, `bound_name_hole`, `bound_type_hole`, `bound_run` build the accumulator once through `with_hole`, not copy-then-set.
  - AVRA_ALIAS_LOG, cold `check packages/cli`: `core.bound_hole` 6,356,813 clones → 0; `bound_name_hole` 114,322 → 0; `bound_run` 60,965 → 0; total clone elements 8,935,115 → 953,525.
  - Wall, two rounds each (base = main 216f3c10, compiled once from gen-2): base 157,967 / 139,230 ms; cut 145,871 / see PR body. ast round 1 / 2: base 17,348 / 17,294; cut 18,875 / 16,986. No ast change, as expected: the copy is in matching, not in the lexer.
  - `fmt --check` clean; `make keepers-static` clean on the Mac; `sh tools/work test`: all suites passed on the Sprite.
- Cut 2 (`ast2` re-parse, workspace.av ~1368–1372): NOT built; it needs a design choice. The second parse needs the block words: `use`-derived grammars and instances (`block_words` workspace.av:1435, `line_words`), the own module's components (`module_components` workspace.av:1453, which reads sibling plain parses), and `named_instances` over the source text (workspace.av:1441). Getting those before the first parse means a light scanner of `use` and component lines, which is a second, lexer-shaped reader. Choice for the lead: (a) that scanner, or (b) cache the words per module in the kept record, keyed by the imports' digests.
- Not touched: the lexer loop (cut 4), sublang.

## 2026-10-12 19:33 UTC — parse split of one big file (probes only, branch parse-split, 9dceb7ae)

File: packages/std-avrac/src/features/decls.av, 137,864 bytes, 19,934 tokens. Harness: `AVRA_QTRACE=1 build/avra fmt --check <file>` (parses, no typing), 10 runs. Probes add overhead (per-builder qtrace), so the absolute ms are a little high; the shares are from the same run.

- Per parse (median of 10): lex ~17 ms (4%); grammar ~392 ms; post-grammar ~2 ms. Two parses per decls.av: the plain parse and the block-word parse (ast2) — both the same cost, so ~0.8 s per cold pass over this file.
- Inside grammar (one run): builders 31–33 ms (~8%, 36,329 builder calls, ~0.9 µs each); executor ~355 ms (~90%).
- Rule attempts (executor, `match_rule`): 83,908 for 19,934 tokens = 4.2 per token. Memo hits 898 (1%). ~4.6 µs per attempt.
- The expression ladder is most of it: 12 rules (unary, withed, primary, postfix, multiplicative, pipeline, bitwise, additive, coalescing, expression, comparison, conjunction), ~5,100–5,600 attempts each, ~66k of the 84k total (~79%). Each expression start walks all 12 levels, and the memo never hits because each (rule, cursor) is tried once.
- Census (`make census CMD='fmt --check decls.av'`, cold): 6.11 M boxes (5.54 M list boxes), 1.41 M list buffers, 24.5 M retains, 30.5 M releases, 34.7 M list writes. Top list-write sites: grammar.run_as 3,079,954; avra_array_slice 537,739; grammar.starts_at ~996k at three sites + 498k at one; matched 283k ×2; match_seq 498k; built 701k; binding_for 702k and 351k. Top retain: avra_insist 2.85 M.

Cuts with the largest expected gain (no building):
1. Expression ladder (grammar, std-avrac/src/grammar/grammar text — the `expression` rules): replace the 12 precedence rules with one precedence-climbing rule. That removes ~66k of 84k rule attempts (~79% of the executor). Design choice: the grammar's diagnostics and farthest-failure must stay identical; needs a decision.
2. Branch pre-check (std-grammar/src/executor.av `starts_at` line ~418, `cannot_take` ~439): `terms.any(takes_term(...))` allocates per branch per attempt (run_as 3.08 M list writes; starts_at ~2.5 M). Precompute a per-kind first-set table so the check is one array index. Expected to remove most of the list writes and retains; a smaller share of time than cut 1.

Not measured: attempts per token for the non-expression rules beyond the top 12 (the qtrace listed all rules; only the top 12 are above 5k).

## 2026-10-12 21:34 UTC — cut 2 built (first-sets, draft PR #630); cut 1 written up, not built

### Cut 2: branch start check reads a per-token bit mask (branch first-sets)
- Branch: first-sets, PR #630 (DO NOT MERGE). Commits: a loop instead of a closure in `starts_at` (3af9cd61), the per-token mask (5178aad6), formatting, and the mask as comprehension plus fold.
- Change, std-grammar/src/executor.av: `run_as` computes one int per token (bit s = wears class of slot s; bit 62 = closes body). `cannot_take` reads the token's bits for each start terminal; unanswerable terminals (no slot in range, literal, reference) take the exact `takes_term` path.
- Not the full brief: the table is not indexed by token kind (the Lexeme has no token-kind verb; adding one is a lexeme-contract change). Reuses `BranchStart.terminals` from first.av.
- Equivalence: `sh tools/work test` all suites passed (28, 369, 8723, 96); `fmt --check packages` 1644 examined, 0 differing; candidate built by itself is byte-identical (fixed point); `make seed-check` passes ("the seed compiles HEAD").
- Measured:
  - decls.av `fmt --check`, 10 runs, two batches: baseline median ~665–670 ms, candidate ~620–630 ms (about 7%, incl. process start).
  - Cold `check packages/cli --time` (one run each): ast 17,842 → 16,927 ms; parse 20,327 → 19,637 ms; wall 166,571 → 144,622 ms.
  - Experiment: with the branch check disabled entirely, the decls parse got SLOWER (~780 ms median vs ~665), so the check saves work; the gain from cheapening it is real but modest.
- Census (list writes, boxes) not re-run for the candidate.

### Cut 1 (not built): one precedence-climbing rule in place of the ladder
The ladder today (std-avrac/src/features/expr_spine/mod.av:55–68), quoted:
```
disjunction = l:conjunction ( op:"||" r:conjunction )* -> fold_binary(l, op, r)
conjunction = l:comparison ( op:"&&" r:comparison )* -> fold_binary(l, op, r)
comparison  = l:coalescing ( op:( "==" | "!=" | "<=" | ">=" | "<" | ">" ) r:coalescing | "is" ( "." iv:NAME ( "(" ( ip:asked_payload ( "," ip:asked_payload )* ","? )? ")" )? | an:NAME ":" at:type_atom ) )? -> fold_cmp(l, op, r, iv, ip, an, at)
coalescing  = l:pipeline ( "??" r:pipeline )* -> fold_coalesce(l, r)
pipeline    = l:bitwise ( "|>" r:bitwise )* -> fold_pipe(l, r)
bitwise     = l:additive ( op:( "|" | "^" | "&" | "<<" ) r:additive | op:">" ">" r:additive )* -> fold_bitwise(l, op, r)
additive    = l:multiplicative ( op:( "+" | "-" ) r:multiplicative )* -> fold_binary(l, op, r)
multiplicative = l:unary ( op:( "*" | "/" | "%" ) r:unary )* -> fold_binary(l, op, r)
unary       = "!" v:unary -> not_expr(v) | "-" v:unary -> neg_expr(v) | "~" v:unary -> bitnot_expr(v) | withed
withed      = v:postfix ( "with" "{" ... "}" )? -> fold_with(v, wn, wv)
postfix     = v:primary ( "." "type" ... | "?." "type" ... | q:( "?." | "." ) p:NAME ... | "[" i:expression "]" ... | ... )
primary     = v:NUMBER -> int_lit(v) | n:NAME -> ident(n) | "(" e:expression ")" @expect(")", ...) -> e
```
(12 rules: disjunction, conjunction, comparison, coalescing, pipeline, bitwise, additive, multiplicative, unary, withed, postfix, primary; the trace's top twelve are the same set, with `expression` as the catch-wrapper.)

What a single operator-table rule would look like (sketch in the grammar DSL, not built):
```
expression = operand:unary ( op:BINOP r:unary )* -> climb(operand, op, r)
// BINOP and each level's precedence and associativity come from one table:
// 1 "||" left, 2 "&&" left, 3 comparisons nonassoc (== != <= >= < >), 4 "??" left,
// 5 "|>" left, 6 "|" "^" "&" "<<" ">>" left, 7 "+" "-" left, 8 "*" "/" "%" left
```
Needs the owner's operator/fold construct (the nodes work): a precedence-climbing builder, not a plain repeat.

What must stay identical:
- Associativity per level: left for all binary levels; comparisons non-associative (a single compare; `a < b < c` refused).
- The `is` forms (`is .V`, `is .V(x)`, `is name: Type`) exist only at the comparison level and bind after `coalescing`.
- Unary is tighter than multiplicative (`-a * b` is `(-a) * b`); `withed` and postfix bind tighter than unary.
- `>>` is two tokens joined at the bitwise level (`op:">" ">"`); `<<` one token.
- Farthest-failure and expected lists: every level contributes its own first words (`||`, `&&`, `==`, ..., `is`) to the expected set at the same cursor. A single rule must merge the same expected words at the same point, or the diagnostics text changes (the goldens pin it).
- `@expect` messages in postfix and primary keep their text.

Expected attempts per token (measured on decls.av today: 4.2): each expression start visits all 12 levels, so about 12 rule attempts per primary. One precedence rule plus unary, withed, postfix and primary is about 5 attempts per primary, so roughly 1.5–2 rule attempts per token overall, down from 4.2 (about 60–65% fewer rule attempts). Not yet measured: the executor's share of the rule cost (cut 2's measured share is ~7%; the ladder is most of the attempts).

## 2026-10-12 — #630 goldens, rule attempts, callgrind (branch first-sets, PR #630)

- Goldens: `sh tools/work test` passed on the candidate (28, 369, 8723, 96 …). Diagnostics diff: 120 mutated copies of decls.av, mod.av, rule.av, expr_spine/mod.av, each run through `check` with the baseline and the candidate; 53 carried a parser "expected" message; stdout and stderr identical in all 120 (0 diffs).
- Rule attempts (callgrind call count of `match_rule`): 83,908 on both binaries, the same as the probe count.
- Callgrind on `fmt --check decls.av` (Ir): 3.934 G (bit-mask candidate) → 3.830 G (+ binding_for loop), −2.6%.
- Wall (10 runs each): baseline ~680 ms median, bit masks ~640, + binding_for ~617 (−9% vs baseline).
- Per-attempt breakdown (callgrind call counts ÷ 83,908 attempts; baseline-with-masks build):
  - rc_release ~203, cell_release ~131, rc_retain ~99, array_push ~97, array_made ~53, memset ~54, streq ~49, array_sized ~47, str_char_code ~31.
  - Inclusive: the matcher chain is ~58% of Ir; `parsed_as` ~75%. Self cost: memory management (array_made 6.1%, rc_release 5.7%, box_free 4.8%, release_dead 4.5%, malloc 3%, rc_retain 2.9%, memset 1.9%, buf alloc/free 2%) ≈ 30–35%. avra_streq 4.5% (token_lit_matches 1.56 M, is_end 0.52 M).
  - Array_sized callers: bind_label 362k, binding_for 351k (now removed), scan_step 269k, match_seq 258k, token_loc 234k, match_repetition 208k, match_prim 183k.
- The two changes measured: the bit-mask branch check (−5–7%, wall) and binding_for returning from a loop (−2.6% Ir). Next levers, not built: sparse memo (the table is rules × (tokens+1) × 2 slots, zeroed per parse, 1% hit rate); per-rule capture frames instead of a list copy per bind (`bind_label` concat); string literal ids instead of streq per literal check.

## 2026-10-12 — double-parse measurement on main eaff334c; #609 and #630 rebased

- Build: main eaff334c, compiled by the bootstrap path (gen-2 could not read main's source, so the wrapper bootstrapped from the seed).
- Cold `check packages/cli --time` with AVRA_QTRACE (build/avra.main):
  - 505 files. `Plain` computed for all 505; `Parsed` computed for all 505 (memo asks).
  - `Q parse` lines: 650 = 360 files parsed once + 145 files parsed twice.
  - Phase times for the same run: ast 17,870 ms, sublang 2,926 ms, parse 20,722 ms, analyze 31,700 ms.
- Reading of the premise: NOT every file is parsed twice. `parsed_under_blocks` (workspace.av ~1368) already returns the plain tree when `block_words` is empty (`if words.is_empty() { return self.with_import_remedies(first, words) }`). The 360 files with no block words take one parse. The 145 that are parsed twice are the ones with block words (component instances such as `command` in cli/commands, grammar blocks), so the second parse is needed and reusing the plain tree would be unsound for them.
- Measured cost of the second parse (earlier probe on main 708e712b-era tree): ast2 = 3.45 s over 145 files. Savings ceiling from removing it: ~3.5 s of ~18 s ast. The fix that avoids it is the words-before-first-parse design (cut 2 option (b): block words kept in the module's record keyed by imports' digests), not the "reuse when no word occurs" check (those 145 files do contain words).
- Expected 38 s → 22 s in the brief does not hold: the parse-phase total is ast 17.9 + sublang 2.9, and only ~3.5 s is the removable second parse.
- #609 (parse-cuts, shape holes) rebased onto eaff334c, one commit 160b9fba, force-pushed. #630 (first-sets) rebased onto eaff334c, five commits, head ac8af548, force-pushed. Both OPEN; CI started on #609 (prepare pending); #630 pending.

## 2026-10-12 — DB 09 (parked): double-parse is 145 of 505 files; ≤3.5 s; needs words-before-parse. No PR.

## 2026-10-12 — (2) literal ids: ceiling measured, no PR yet
- callgrind on decls.av (build/cg5.out, candidate fs5): `token_lit_matches` 94.3 M Ir inclusive = 2.46% of 3.83 G; `avra_streq` total 195 M = 5.09% (all callers: lexer collapse_breaks/opened/word_before_brace, match-side token_lit_matches, executor closures). `is_end` is inlined, not listed.
- Ceiling for a literal-id scheme on the executor side ≈ 2.5%; with the lexer side ≈ 3–4%. Not worth a PR on its own; I am not building it unless the lead wants the 3–4%.

## 2026-10-12 — (3) capture-frame design (15 lines), posted to op-rule.md
- Assembly: each Rule gets its label slots (distinct labels, first-seen order); each Item gets `slot` (-1 none).
- match_rule allocates ONE frame per rule attempt: `filled(slot_count, null)`.
- A branch attempt copies the frame once (`mut f = frame`), then writes `f.set(slot, v)` per bind. No `bindings.concat` per bind, no `any`/`find` scan.
- binding_for becomes `frame[slot]`; repetition accumulation reads the slot.
- Builders receive args in the same label order (the sort `labeled_bindings` does today is replaced by the slot order fixed at assembly).
- Witness: the 1,644-file `fmt --check` plus the 120-mutation diagnostics diff; callgrind call counts for bind_label and binding_for to show the drop.
- Interlock: op-rule's `match_operators` uses the same frame API, so PR3 of op-rule rebases onto this.

## 2026-10-12 — capture frames: ceiling under the bar, NOT built; memo per-rule: hits concentrated, no gain

### Capture frames (ceiling, from callgrind on the candidate, decls.av)
- `bind_label` inclusive: 136 M Ir = 3.56% of 3.83 G (includes its allocations).
- `binding_for` was already reduced (commit ac8af548). `labeled_bindings` and `bind_label_all` are inlined into `match_repetition`, so they are not separable.
- Upper bound from the frame design: ~4–6%. Below the 10% bar, so NOT built (lead rule). The op-rule lane was told the API is not in flight (.lead/lanes/op-rule.md).

### Per-rule memo hits (probe on first-sets + one trace line in match_rule, decls.av, 83,944 attempts)
- Memo hits: 900 total (1.1% of attempts).
- Hits by rule: `type` 672, `expression` 228. The other 24 attempted rules: 0 hits. Rules attempted: 26.
- So memo is useful for two rules in this file; a per-rule flag would keep those two and drop the rest.

### Memo table cost (experiment: no memo table, slots allocated empty, guarded writes; measurement only, branch memo-exp)
- decls.av Ir: 3.821 G without the table vs 3.777–3.830 G with it (callgrind run-to-run noise ~1%): no measurable difference.
- Wall median of 10: 604 ms without the table vs 618 ms with it (−2%).
- The memo table is not worth a per-rule flag for this file. Not measured on the 505-file cold cli (per-file table zeroing would be larger there; untested).
01:45 UTC — parse_diff: written (PR #668), shown failing on perturbed binary (9 diffs), #630 vs main: walk 1775 files 0 diffs, mutant shards 0 and 1 of 16: 0 diffs; no run in flight; context not near full.
02:02 UTC — #630 vs main, shard 1/16 (stride 256, walk-less): mutants 43, check runs 1, differences 0
02:08 UTC — shard 2/16: mutants 43, check runs 1, differences 0
02:18 UTC — shards 3/16 and 4/16: mutants 43 each, check runs 1 each, differences 0
02:33 UTC — shard 5/16: mutants 43, check runs 1, differences 0 (shard 6 hit the 15-min run bound, rerunning alone)
02:43 UTC — shard 6/16: mutants 43, check runs 1, differences 0
02:48 UTC — shard 7/16: mutants 43, check runs 1, differences 0
02:54 UTC — shard 8/16: mutants 43, check runs 1, differences 0
03:05 UTC — shard 9/16: mutants 43, check runs 1, differences 0
03:15 UTC — shard 10/16: mutants 42, check runs 1, differences 0
03:23 UTC — shard 11/16: mutants 42, check runs 1, differences 0
03:32 UTC — shard 12/16: mutants 42, check runs 1, differences 0
03:38 UTC — shard 13/16: mutants 42, check runs 1, differences 0
03:44 UTC — shard 14/16: mutants 42, check runs 1, differences 0
03:50 UTC — shard 15/16: mutants 42, check runs 1, differences 0 (last shard; all 16 at 0)
