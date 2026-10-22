
## 2026-10-12T18:59:08Z
- docs PR opened (NODES.md step 5, +37/-1); tickets avra-8sb5.89.5.1-.8 filed; ruling comment on .89.3. Slice 1a next.

## 2026-10-12T19:54:25Z
- heartbeat: PR #610 (docs) open. Slice 1a branch nodes-records-1a: Slots +5 accessors (expr_opt/stmts/pats/type/types), Makes covers Scoped/Plain/ExprId?/TypeRef?/List<StmtId|PatId|TypeRef>; 17 builders+rows dropped (call, pinned_call, return, fail, named_arg, not, variant_pat/lit, member_pat, typed_pat, map_empty, match_opt, mut, while, bare break/continue; let/const/ident from #583 cherry-pick). Building on the Sprite. FINDING: variant ctors take no defaults (probed: type.variant_arity "N.A carries 3 values, given 1"; named args refused) and Field crosses only `defaulted: bool`, not the default expr, and node records are not nameable from core/nodes.av - so non-null defaults (e.g. FnDecl.ret = void) need Field.default growth (two-commit seed ladder). Arity-law defaults (null/[]) need nothing.

## 2026-10-12T20:38:38Z
- PR #623 (draft) slice 1a: 26 files, +100/-200 (net -100); 5 builders.av deleted; 17 builders gone; make try green, avrac test exit 0, fmt/idioms clean. Waiting CI. Blocker: non-null field defaults need Field.default growth (see above) - proposing as 1a2 after seed ladder; next: 1b @at.

## 2026-10-12T21:23:46Z
- #623 accepted by lead (cache-attacks skip = path rule; make cache-attacks exit 0 on Sprite). 1b/1c/1d reported blocked (no @at consumer; @facet needs variant-field gathering change; nested records need a LangNode carrier). Asked lead; meanwhile continuing 1a-style conversions (Scoped?, Alias, Setting, SyntaxDecl, Collect, Block) on branch nodes-records-1b.

## 2026-10-12T21:24:38Z — rulings 1-3 (lead): facet/@local, carrier scope
FACET vs nodes-self's `@local` — one mechanism could serve both, with two routings:
- A field mark is read by ONE helper (`kept_fields(v, mark)`) that every shape derive uses to skip a field: Children, Rebuild, Flow (a marked field is no child), Matchable, Exact.
- They differ in two places only. IDENTITY: `@local` is out of Identity/Fingerprint ("not what the node IS"); a facet stays IN (`state x` and `mut x` are different statements), so a facet cannot reuse `@local` as is.
- STORAGE: `@local` stays on the record; a facet's value leaves the gathered payload for a side table the mark names (`@facet(state)` -> `mark_state`), which needs the gather (Variant.fields) to drop it and the maker to write it.
- So: one field-mark registry {skips children, in identity?, stored where}; `@local` = (skip, out, node), `@facet` = (skip, in, side table). Only the registry row is new; each derive asks the row, not the word.
- Cost: the gather change (a field absent from Variant.fields but present in the record) is the compiler-model part; nodes-self owns the identity half.

CARRIER SCOPE (nested group -> its own record; the biggest class, 32 fns / 764 lines):
- Existing carriers: NType(TypeRef), NArm, NCompClause, NCases, NMark. These cover arms, cases, marks, comp clauses and types — records whose groups already build via small hand builders. Param, enum Variant payload and struct Field have NONE; they are what the parallel-capture fns (fn, once fn, extern, lambda, fn type, trait, component decl, on handler, enum decl, type decl: ~10 of the 32) zip by span windows.
- Smallest core change: one LangNode variant per record that needs it, added when its first rule converts: `NParam(Param)` first. A generic `NRecord(kind, slots)` is refused: untyped, and every consumer's exhaustive match would learn nothing. LangNode matches are few (builder.av accessors + list_at), so a variant is cheap; each one pays its accessor.
- Binder: Build.Node resolves against PayloadRows of Expr/Pat/Stmt; add rows for plain records (`Param`) from the SAME `@derive(Makes)` extended to a record's fields; `-> Param` then resolves like `-> Stmt.X`.
- Slots: `params_of(label) -> List<Param>` (Many of NParam), `flag_present(label)` for the keyword-presence marks (const/mut/state/isolated), and Param.id needs a store alloc at the NAME token's span — that is the first honest consumer of `@at(name)`.
- Before (fn params): one 400-char rule line with 10 parallel labels (ck mk sk ik ps pt pd sp ...) + marked_seats/isolating/stating/aligned_param_types/one_between/seat_since/seat_mark_of/mark_within/window_end (about 55 lines in builder.av) + ~20 lines of zipping in build_fn.
- After: `param = ck:"const"? mk:"mut"? sk:STATE? ik:"isolated"? name:NAME ( ":" ty:type )? ( "=" default:expression )? -> Param`; `stmt = "fn" name:NAME ... "(" ( params:param ( "," params:param )* ","? )? ")" ( "->" ret:type )? body:block END -> Stmt.FnDecl`. The window helpers die (they exist only to re-align flat lists). builder.av's param/field helpers total about 110 lines (aligned_*, marked_seats, isolating, stating, fields_zipped, spread_*, mark window fns); the fn/once/extern/lambda/fn-type/trait param zips add roughly another 100.
- Open: the `..HOLE` spread seat and tparam bounds are second shapes of Param; both are extra branches of `param`.

## 2026-10-12T21:57:54Z
- docs PR #627 (corrections: no @at, facet/carrier scope in table). Facet/carrier analysis written above. Stacked draft #635 on #623: Setting, SyntaxDecl, Alias, ForEach -> node rules; 11 files +22/-47 (net -25); make try/test/fmt/idioms green on Sprite.

## Note from the lead's batch (db05c-reland)

- #635 (nodes-records-1b) conflicts with #623 (nodes-records-1a) when merged: its conflicting files are core/makers_derive.av, core/slots.av, features/builder.av, and the components, loops, structs and sublang builders.
- Batch 8 is #638 (draft, on main eaff334c). It carries #623 in squashed form. Once #638 lands, rebase #635 onto main, so its conflicts are with #623's squashed form rather than its pre-squash commits.
- #638 is not yet merged; the lead readies it after #624 lands.

## 2026-10-13T00:01:49Z
- carrier ladder: pin PR #637 (28 pin cases, base #635); PR A #650 (carrier: Record.ParamSyntax row via Grammar derive on records, NParam, Slots.params_of/present_of, Builder.seat; +101/-10, nothing uses it; 8753/8753, idioms 0). Next PR B: fn params rule. No seed refresh needed between A and B (grammar text is data to the standing compiler).

## 2026-10-13T02:18:47Z
- PR B #659 (fn params, +24/-65 = -41) and PR C #673 (once/extern/method/lambda seats, +132/-147 = -15 incl. a 104-line pin test; -119 without it) on the stack pin #637 -> A #650 -> B #659 -> C #673 (all drafts, stacked on #635). Sprite: gen-1+gen-2 build green, std-avrac 8753/8753 (B) and 8766/8766 (C), idioms 0, fmt --check packages 0 differing. Not converted: fn-type seats and trait sigs (need NSeat / member carriers).

## 2026-10-13T02:19:39Z
- stack restacked onto main c48bc794 (force-with-lease): #635 (1b, base main) -> #637 pin -> #650 A -> #659 B -> #673 C, PR bases patched. A: built, tests-first = #637 pin (28 cases), +101/-10. B -9: +24/-65. C: -119 prod lines. No Sprite exec refused. Running make cache-attacks on C tree next; CI by name pending after the force-push.

## 2026-10-13T02:44:02Z
- BLOCKER (Sprite, >10 min): after the restack onto c48bc794 the lane Sprite cannot build a compiler: make avra fails fast and make bootstrap (seed) fails at link with ~20 undefined av_@std.* symbols (main, std.net, std.http, std.relation derive) - not in code I touched; a Sprite OOM-restart preceded it. So make cache-attacks was NOT run for #635/#637. CI on GitHub runs: #650 prepare/gate/codecs/keepers-b/seed-check pass, others pending; #635 shows no checks yet.

## 2026-10-13T03:13:09Z
- nodes-records: stack on main 444e00b5 (bottom-up): #635 (prepare pending), #637 pin and #650 A GREEN by name (test-equivalent: gate, keepers-a/b/static, seed-check, suites std-avrac + rest, codecs, runtime-keep; cache-attacks SKIPPED by path rule - run by hand on Sprite avra-prof: make cache-attacks exit 0, 11 steps 0 failed). Land order: #635, #637, #650, then #659, #673 (drafts).

## 2026-10-13T03:13:29Z
- GREEN by name (test, gate, suites std-avrac, seed-check, prepare): #637, #650, #659. #635 prepare not reported yet (no checks), #673 prepare pending. cache-attacks by hand on Sprite for the C tree: exit 0.

## 2026-10-13T03:13:54Z
- Remaining 91 build_* fns / 1124 lines. With mechanisms existing after C (accessors + node rules + NParam): NOTHING over ~80 lines; what is left pure is <40 (each hides a decode, a refusal or a desugar: int_lit 9, comp 9, format_pat 8, quote_pat 7, neg 10). Clusters, each needing a NEW mechanism: (1) operator folds ~230 (postfix 180, bitwise 12, cmp 11, binary 10, with 9, coalesce 8) need grammar @fold; (2) declarers over parallel captures ~270 (enum_decl 34, type_decl 23, struct_lit 14, component_decl 35, keyed 29, trait 37, fn_type 19, use 18, impl 22, collect decl 22+16) need one record carrier each (NField/NVariant/NSig/NSeat) plus ~110 lines of window helpers in builder.av; (3) desugar+refusal builders ~270 (quote 29, table 28, grammar_lit 37, sublang 22, when 23, if_stmt 14, if 7, for 12, annotated 12, mark 18, catch 53, trailing_arms 15) need means() and checker-side refusals. End of the accessor vein.

## 2026-10-13T04:30:44Z
- nodes-records: stack simplified. ONE draft PR #689 (base main, branch nodes-records-C, 5 commits = old #635 + pin + A + B + C; tree 5eccc28e == the tree cache-attacks ran on, exit 0). #635 and #673 closed with pointers; #637/#650/#659 had been auto-closed as merged into base nodes-records-1b (not main) by my tangled restack - content is only in #689. Land #689 only; nothing else of mine is pending. Stacked PRs banned from now on.
