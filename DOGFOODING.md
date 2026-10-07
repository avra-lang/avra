# Dogfooding Avra

Patterns proven in this tree — reach for these before writing the
C-style version. Probe unfamiliar features in scratch first; known
gaps live in CLAUDE.md "The subset today".

### A write reaches a PLACE, never a value

A fn changes its caller's data only through a PARAMETER'S FIELD
PATH (`mut rows = o.inner.rows; rows.push(v)`) or through its own
RECEIVER (`self.rows.push(v)`). A list handed over as an argument
is a VALUE — writing to it changes nothing the caller can see — and
so is an ELEMENT read out of a container (`mut r = xs[i]`), which
is why a mutated element must be written BACK (`xs.set(i, r)`).

So a mutable out-parameter is a one-field STRUCT, never a bare
list: `type Pins = { slots: List<TypeId?> }` for the unifier's
bindings, `type Table<T> = { rows: List<T?> }` for every memo. The
struct's field is the place; the bare list was only ever bs2's
aliasing in disguise. There is no field shorthand — a literal
spells every pair (`Pins { slots: slots }`) — and a generic literal
takes its type from a typed `let`, never from `<int>` at the
construction (`let t: Table<int> = Table { rows: [] }`).

Discovered by self-hosting: every one of these sites worked under
bs2 and silently did nothing under Avra's own semantics.

## The idiom registry

This file is the RULEBOOK of the future idiom engine (ROADMAP, Era
IV): every entry below is a lint rule being written by hand. The
mechanically-greppable subset is ENFORCED today by the ratchet
(`make idioms`, wired into the gate — smells may never rise;
deliberate exceptions bump `tools/idioms.baseline` in the same
commit). When a review round or a milestone discovers a NEW idiom,
it lands here AT DISCOVERY, with its smell, its licensed
exceptions, and — where greppable — a ratchet rule.

THE BAR rests on five laws, and the first three exist because the
old ratchet had a hole under each. Every idiom the language can
state is a `rule` declaration now, found by `avra check` itself
(compiler/idioms.av, or a feature's own idioms.av) — `tools/idioms.py`,
the regex tool this section originally described, is gone, ported
out to the last shape (avra-8sb5.25.16); `tools/idioms.baseline` and
`avra check --baseline` (wired into `make idioms`/`make idioms-accept`)
carry the five laws below now.

  1. THE BASELINE LISTS SITES, NEVER COUNTS. The old tool compared
     totals, so fixing one smell while adding another passed
     silently — a net-zero swap. Now a new site fails on its own.
  2. NO TOOL PATH ADDS TO THE BASELINE. `--accept` only PRUNES what
     is gone, so the debt can only fall. The old escape hatch was
     "bump the pinned number", which is how a ratchet becomes
     theatre: style.accumulator_declaration drifted 39 -> 41 -> 40 -> 41 -> 43 across four
     milestones, each bump self-licensed in its own commit.
  3. A LICENSE LIVES AT THE SITE: `// LICENSED loops.push_loop: a ZIP of
     parallel captures`. The reason sits where the code is,
     forever, instead of as an integer nobody reads. A new
     violation therefore has two honest exits — write the
     idiomatic form, or say why it cannot be written.
  4. THE REGISTRY MAY NOT OUTRUN THE RATCHET. Every idiom named here
     must have a matcher or an entry in the tool's UNRATCHETED with
     its reason; the tool fails otherwise. New idioms arrive with
     enforcement or with a written admission of why they cannot.
  5. THE ROOTS ARE THE PACKAGES, ASKED OF THE TREE. The scan list was
     hand-kept, so std-http, std-net and std-sqlite were never on it
     and the bar reported ZERO DEBT over three packages it had never
     opened — 71 unlicensed sites, including three `xs[xs.length - 1]`
     that lists.last_index has ratcheted for four milestones. A check that examined
     nothing is not a check that passed, so the roots are read from
     `packages/*/src` and the run PRINTS WHAT IT LOOKED AT (389 files
     in 16 packages today). The same disease has two other known
     hosts: the Makefile's two link sites, and any keeper whose
     subject list a new arrival does not join.

Matchers are MULTI-LINE where the smell is: the old greps required
the loop and its push on ONE line, catching the rare shape (11
sites) while 14 ordinary multi-line loops were invisible.

A LICENSE SILENCES THE FINDING, NOT ONLY THE BASELINE. `// LICENSED
<rule>: <reason>` on the line directly above a site used to answer
only the ratchet — `avra check`'s own rule pass fired there anyway,
and the baseline was the only thing standing between the finding and
the reader. `compiler/licenses.av`'s `site_licensed` reads the same
citation before a finding is even built (`rule_pass.av`'s door), so a
licensed site never fires at all — never a loose "mentions LICENSED
nearby" guess: the id must be the EXACT firing rule's own, the reason
non-empty, the comment the line right above, never two lines up, and
licensing one rule at a site never silences a different rule's
finding on that same line.

A MULTI-ARM RULE SITS IN EVERY ARM'S OWN BUCKET, NEVER "ANY NODE" FOR
THAT ALONE. Two arms narrowing to different kinds — structs.index_compared's
`==` and `!=`, compiler.repeated_projection's `&&` and `||` — once
forced the WHOLE rule to any-node the moment they disagreed, since
the index kept one kind per rule. `core.root_kind_of` answers a LIST
now, one kind per pattern that narrows; a rule sits in every one of
those buckets, and only a SINGLE pattern that cannot narrow AT ALL
still falls back to any node.

A CITATION IS RATCHETED TOO, by a different keeper: `make cited`
refuses a name or a path this file or CLAUDE.md cites that the
tree cannot answer, and a bare `file.av:NNN`, which the next edit
of that file moves. It reaches a THIRD of doctrine rot — an audit
of 99 laws found 17 stale decorations, 5 of them names a grep
finds and 12 counts, line numbers and attributions no tool can
see. Licences live in `tools/cited.allow`, each with its reason.

Ratcheted: `avra rules --json` answers every native rule the
compiler carries, by its `<module>.<rule>` id — `avra rules
--markdown` prints this section's own bullet shape, one line per
DOCUMENTED rule, and `make dogfooding-rules` (`avra rules
--check-markdown DOGFOODING.md`) refuses the two disagreeing (paid off avra-8sb5.25.16's own follow-up). The block
below is GENERATED: edit a rule's `///` doc and regenerate, never
a bullet here.

<!-- GENERATED:RULES:START -->
- closures.pronoun_lambda A one-parameter lambda handed to a method call is `it` — the pronoun says the predicate and nothing else: no binder, no annotation, no arrow. THE ONE LAMBDA THAT STAYS: `it` binds at the NEAREST enclosing method call, so a parameter handed on to ANOTHER call's own arguments cannot be the pronoun — that is the language's own spelling; nor a block body, a nested lambda (any `->` inside reaches this the same way), or a body that already says `it`.
- compiler.bool_of_defaulted A payload the value-protocol dispatch GUARANTEES, papered over with a `??` default — absence here is a DEFECT the caller should speak (`cx.lower_defect(e, ...)`), never a plausible fallback. All six of core/protocol.av's projections (`bool_of`, `text_of`, `int_of`, `bits_of`, `elems_of`, `pairs_of`) are the same shape.
- compiler.bracket_ritual A `push` held open across a stretch of work until a later `pop` on the same name — a bracket fn taking a thunk owns the pop on every path out, not just the one written.
- compiler.bypass_outside_bracket A HOOK-FREE TABLE READ (features/bypass.av's `Bypassed`) called from outside its own bracket, or the method table's own CELL read past every wrapper's name. `sig_so_far`, `seat_written_so_far` and `inferred_errors_so_far` answer a fixpoint's table AS IT STANDS, mid-computation, and `registered_methods` a type's method table the same way — none of the four records a dependency, so each is safe only from inside the member that IS the computation trusted to see the table that way. THE CALLEE'S OWN NAME is held open (`${name}`, a text seat, never a held code position) so the four verbs are ONE arm sharing ONE bracket-lookup, over the one call shape a bypass takes whatever its arity — gating a NAMED wrapper alone would still leave `self.methods.get()` itself open to a new site reading it inline, so that raw field-then-`.get()` shape is a second arm over the SAME "methods" bracket. The declaration relation's two pinned handles (`decl_cells`, `decl_row_rows`) are that shape too, over the "decls" bracket: only `Decls`' own readers see its rows unrecorded.
- compiler.cell_get_copy A `Cell` read out, written through, then stored back — `mut t = c.get()`, a write through `t` (`push`, `set_at`, `set`, `put`, `grow_to`, `pop`, a field write), then `c.set(t)` — copies what the cell holds on EVERY turn (spec 11.5: `get` answers a COPY). `Cell` exists to make mutation through sharing cheap, and when the loop is hot the copy is quadratic. Write in place through the cell's own verbs (`push`, `set_at`, `put`), or for a `SideTable` through core's `side_put`/`side_grow`, which DETACH the cell first (`c.set(t with { … })`) so nothing shares the box the write would copy whole. That detach is what the guard reads: a body storing the same cell with a `with` form is the in-place written shape, never this smell, and a store of any value but the very one `t` names never fires.
- compiler.duplicated_literal A struct literal written twice in one PRODUCT file, field for field — a fixture built by hand rather than named. Tests are exempt: a fixture built twice there is the test being explicit.
- compiler.duplicated_message A long string literal written twice in one PRODUCT file — a message repeated rather than named. Guarded to a SHARED-SENTENCE shape (20+ characters, starting lowercase, the house style every diagnostic and fixture message already wears) so a short symbolic literal repeated by coincidence (a type name, a key) never fires; `fingerprint_siblings()` answers by STRUCTURE, never by re-reading `.text()`. Tests are exempt: a repeated fixture there is not a message that can drift.
- compiler.emit_then_error `emit` immediately followed by `intern(Type.Error)` — the pair a typing law's refusal tail always ends with — is `spoken(d)`.
- compiler.file_id_across_relation A PER-FILE id matched across a WHOLE relation store: a scan over `T.all(db)` — a comprehension's head, or a `find`/`any`/`all` call's subject — whose tests read a column typed `ExprId`, `StmtId`, `PatId` or `At` and no column typed `DeclId` or `FileId`. An arena id names a node only within its own file, and every file mints the same small numbers, so the match answers every file's node at that index. The honest scan narrows by a workspace-global column first — read through its `by_<column>` index, or test it beside the id.
- compiler.filled_by_arena_count `hand_sized_index`'s sibling half of ONE idiom: a fact column SEEDED from an arena's own count — `filled(store.exprs.count(), null)` — rather than through `SideTable<V>`, which states the storage, the window, the growth and the out-of-window defect once. TWO ARMS, one shape: `filled(...)` and `filled<T>(...)` — a pinned type argument is a TYPE-seat hole (avra-8sb5.25.10), held open only so the SECOND arm's message can quote it back; the smell is the same either way, the first ARGUMENT ending in `.count()`.
- compiler.fixed_tmp_path A test's fixed `/tmp/` path: two runs on one machine share it, so the second reads what the first left behind — a cache, a database, a built program. A test file that names a per-run base (a `now_ns()` call, or a `*_base()` helper) owns its directory.
- compiler.free_state_verb A VOCABULARY VERB written as a free fn taking a pass STATE first — `open_region(cx, c)`, `sig(ws, d)` — where the state's own impl IS its vocabulary, so the verb belongs there as a method (`cx.open_region(c)`, `ws.sig(d)`). A BARE-HOLE ROOT, structural GUARD (`Code.fn_params`, features/code.av, the same door `modified_copy_literal`/`one_body_arms` read a struct literal's fields and a `match`'s arms through): a param LIST has no fixed arity a quote pattern can spell, so only the FIRST param's own written type is asked, structurally, never bound through the pattern itself. THE REACH is the pass's own files — a `fn` declared directly under `features/` or `compiler/`, never one nested a directory deeper (`features/quote/lower.av`'s own dispatch targets stay free, `push_loop`'s same file-shape test).
- compiler.hand_sized_index A fact column sized by hand, or an id read through an offset — `SideTable<V>` states the window, the growth and the out-of-window defect once: `side_table(name, lo, hi, seed)`, `get(id)`, `grow_to(n)`.
- compiler.host_asked_directly A `Host` question asked outside the door — `host.read(p)`, `.exists`, `.list`, `.is_dir`, `.stamp`, `(host.peek)(p)` — records nothing: what it answers is no input, no query that depends on it is ordered after it, and a workspace that lives across turns never reads it again.
- compiler.if_start_raw A region instruction emitted raw in a feature — the emission vocabulary (features/emit.av) speaks it: `open_region`, `arm_end`, `close_region`/`close_region_as`. The vocabulary's own file is exempt. Every `Ins` variant `open_region`'s family covers: `IfStart`, `ArmEnd`, `RegionEnd`, `LoopStart`, `LoopCond`, `LoopEnd`.
- compiler.interned_int A structural type interned by hand where a type literal spells it — a scalar shape's own constructor call, held by hand instead of read off the surface syntax. The scalar shapes rewrite directly; the aggregate ones (`Opt`/`List`/`Map`/`Res`) carry an inner shape a rewrite cannot re-spell without re-deriving it (`intern(Type.Str)` vs `Type.Str` vs an already-bound `TypeId` all reach the same inner type by different routes), so they Say. core/types.av's own `interned`/`substituted` is the fold that GIVES a type literal its meaning, recursing through `intern(...)` by construction — the family's one exempt file, on every rule below: rewriting its OWN base case into `.type(T)` would call back into the fold this rule's rewrite exists to shortcut.
- compiler.modified_copy_literal A struct literal copying every other field from ONE subject — that is `with`. Guarded RULE-SIDE over `kids()` (`Expr.StructLit` has no fixed field count a quote pattern can spell): a field COPIES when its value is STRUCTURALLY `subject.<its own field name>` — a `Prop` node whose own name agrees, never a text guess (a compound value that merely ENDS in `.field`, `a.x + b.x`, is not a `Prop` and is refused before its "subject" is trusted). The rule fires only when AT LEAST TWO fields agree on ONE copied subject (the MOST-COPIED one, when more than one candidate appears) and at least one other field does not — a lone copy is too weak a signal. A field copying a DIFFERENT subject than the winner is read as "modified" too, same as one copying nothing at all — `with` only ever names ONE subject, so every other field is what it says explicitly, whatever its own value happens to look like. Narrower than the retired regex: no DECLARED-TYPE trace for the FIELDS (a coincidental `x.field` name match is accused too) — but the SUBJECT's own type IS asked (`same_type`), because `with` requires it: a subject typed differently from the literal being built merely SHARES some field names, and `subject with { … }` there is not a rewrite, it is a type error (`Parsed`'s `store`/ `stmts`/`source` read exactly like a `FileView`'s until the two are checked against each other).
- compiler.one_body_arms Two ADJACENT `match` arms answering one IDENTICAL body — `or` joins their patterns (`.Struct(d, _) -> d`, `.Enum(d, _) -> d` is `.Struct(d, _) or .Enum(d, _) -> d`), since the alternatives may bind (every one binding the same names at the same types, F2039's law). GUARDED RULE-SIDE over `Code.arms()` (`Expr.Match` has no fixed arm count a quote pattern can spell): two sibling arms agree when neither carries a guard, their VALUE Codes are text-equal, and they BIND ALIKE — the same names, each at the type typing gave it on both arms (`ArmInfo.binds`). `.Text(p)` and `.Heading(p)` share a body's text while `p` wears two types, and `or` refuses that join; an arm typing never reached binds nothing it can vouch for, so it joins only when it binds no name at all.
- compiler.raw_mint_emit_bin A register MINTED, then DEFINED by a raw `emit(Ins...)` a few statements later, outside the emission vocabulary itself — where a vocabulary verb mints and emits in ONE call (`cx.bin(sh, op, a, b)`, features/emit.av). THE MINT LAW ("a register is defined in the order it was minted") holds by CONSTRUCTION once the mint and the emit are one call; split across two statements, a refactor can separate them and the register defines out of order with nothing to catch it. `features/emit.av` is exempt — it IS the vocabulary these verbs collapse into, so its own bodies mint then emit by hand once, on purpose. Nine sibling rules, one per Ins variant a vocabulary verb covers (`CallRt`/`CallRtVoid` are `raw_rt_call`'s concern, never this one's; `FnAddr`, `ConstFloat` and a bare `Alloca` have no covering verb in any form, so there is nothing for a rule to measure there yet).
- compiler.raw_rt_call A runtime row named by a BARE STRING — `Ins.CallRt(dst, "avra_x", args)` / `Ins.CallRtVoid("avra_x", args)` — instead of through its GENERATED method (`cx.x(sh, args)`, features/rt.av, minted from `core/rt_namespace.av`'s projection of `rt_sigs()`). A row's method carries the row's own arity in its signature, so a misspelled row is the ordinary "no method" refusal at typing and a wrong seat count the ordinary fn-arity refusal; a bare string reopens both holes a typo can hide behind. Two files spell the string BY DESIGN and are exempt: `compiler/suite_entry.av` builds the TEST BINARY's own entry from its own separate row table, never `rt_sigs()`; `compiler/memory/memory.av` rewrites an ALREADY-LOWERED instruction's string field (the owned-twin substitution) — neither reads a row through `LowerCx`.
- compiler.raw_rt_call_void The void twin — no `dst` to bind.
- compiler.refusal_assembled A refusal assembled from `pointed`/`error_at` by hand — the one shape is `refusal(kind, at, message, label, help)`.
- compiler.repeated_projection The same method call computed twice on both sides of one `&&`/ `||` — `cx.shape_at(e) && cx.shape_at(e)` — where the second call answers exactly what the first already holds. Guarded by FINGERPRINT, so `cx.shape_at(e) && cx.shape_at(f)` (a different argument) never fires.
- compiler.scope_enter_raw A raw scope bracket through a lowering context — the frame verbs (`scope_enter`/`scope_exit`, `seats_enter`/`seats_exit`, `arm_stmts`) are the spelling; a raw bracket is invisible to the `defer` frames. Their own implementation (compiler/lower/walk.av) is exempt.
- compiler.seen_accumulator A `mut` list built to answer "have I seen this before" — a POSITION law once the whole list is already in hand: the first index a value occurs at is decided by `.index_of`, compared against the current one (`xs.index_of(x) < j`, over `enumerate`), which is what `duplicate_names` (features/contract.av) already reads instead of accumulating. `${..head}`/`${..body}` — a run hole (avra-8sb5.25.10) — is what lets this rule sit ANYWHERE in the enclosing block rather than only as its first statement.
- compiler.stmt_index_walk A walk over a SyntaxArena's own statements BY INDEX — `for i in 0..store.stmts.count() { … }` — where `for s in store.stmt_ids()` hands the ids themselves, the thing every such walk actually wants. A BARE-HOLE ROOT, structural GUARD (`Code.for_range`, features/code.av, the same shape `loops.index_walk` reads its own range head off): the bound is `${owner}.stmts.count()` here rather than a list's `.length`. `core/store.av` is exempt — its own `stmt_ids()` IS this walk, the one place it is allowed to be spelled out.
- compiler.str_grown_quadratically Text grown THROUGH A PLACE by `p = p + piece` — quadratic: a field is read out beside the value that holds it, so the text is never held alone and every turn copies it. A LOCAL `mut` grows in place (the memory pass hands the cell's text to the append), so a bare name is not this smell. Guarded to STRINGS ONLY — `n = n + 1` is an ordinary int accumulator.
- compiler.uncounted_refusal A refusal asserted as `>= 1` — a cascade of five passes it just as easily as one; pin the count (`refused_with`, `refused_n`, or `== n`). Every receiver shape the tree has worn it in: `refusals(...)`, `.diagnostics`/`.diagnostics.length`, and `.voices.list.length`.
- enums.bool_variant_match A `match` answering only true/false, one arm a bare variant and the other the wildcard, is `is` — `x is .Ready`. THE ONE MATCH THAT STAYS: an `or`-run on the untested side (`.Narrow or .Ptr -> false`) spells a REGISTRY's remaining variants by NAME, so folding it to a boolean forgets the next one exactly as a catch-all would — the pattern's own WILDCARD seat (`_`, never an `or`-run) refuses that shape structurally, before any guard is asked.
- enums.bool_variant_match_negated The arms-swapped twin: the bare variant answers `false`, the wildcard `true` — `!(x is .Ready)`.
- fns.dead_parameter A parameter nothing reads — the signature lies about what the fn needs, and every call site carries the lie. `dead_params()` (features/code.av) already exempts a contract-bound member (a `trait` signature or an `impl Trait for` method — the TRAIT owns the seat count) and a bodiless declaration.
- grammar_lit.comma_list_open A repeated comma list inside a `grammar { }` block with no trailing-comma option: CLAUDE.md's grammar law, `( "," x )*` ends `","?` before its closer, in every rule. A list that refuses the comma is a defect, not a style.
- if_expr.when_ladder An if/else-if ladder of 3+ arms answering a value is `when`. The pattern's own three parts (`if`, `else if`, `else`) are the floor — "3+ arms" — and a LONGER chain nests the same shape one level down, so this rule fires again there rather than needing a pattern that spans every length: `Expr.If`'s own kids are three ExprIds fixed by arity, never a list a `${..}` run could span, so a chain of unbounded depth is read by RECURSING a bound Code, never by one wider pattern. THE FORM ITSELF excludes what the retired regex excluded by construction: a chain that answers VOID (used for its side effects, never its value) parses as `Stmt.IfStmt` — a different node kind by POSITION (avra-8sb5.25.21) — so it never reaches this pattern's `Expr.If` shape at all, and a bare two-arm `if … else …` (no `else if`) has no THIRD part to fill this pattern's own `else` seat.
- impls.default_override An `impl Trait for T` method whose body is the trait's own DEFAULT body for that name, span-blind and with a written no-op (`nothing()`) elided on either side, is a copy: omitting it inherits the identical default (`Decls.defaulted`), so the override says nothing the trait does not already say.
- let_stmt.unmutated_mut `mut` that nothing ever mutates — the reader is told to expect a change that never comes. `writes()` (features/code.av) already counts a place written through a call (`x.push(v)`), so this is stricter than a text scan: a local only ever READ, or handed where nothing writes back, is caught the same way a bare assignment's absence is.
- lists.bool_comprehension_list A comprehension over a LIST folded to a bool is a SCAN — `xs.all(pred)` stops at the first answer and builds nothing, where `[e for j in src].all(it)` mints the whole list first. A comprehension with its own `if` filter is not yet reached (the subset today).
- lists.bool_comprehension_range The range-source twin — `[e for j in lo..hi].all(it)`.
- lists.last_index Last-element index arithmetic is `xs.last()!` — the same trap on an empty list, spelled once.
- loops.branched_push_loop `push_loop`'s BRANCHED twin: each arm of a per-element `if`/`else` pushes to the SAME accumulator, one shape or the other depending on a condition — `[if ${cond} { a } else { b } for x in xs]` builds the identical list.
- loops.flag_loop A `while` over a flag that only ever turns FALSE to stop it is a loop written around `break`: `mut open = true` / `while open { … open = false … }` is `while true { … break … }`, and the flag, its declaration and the turn it wastes re-reading itself all go. A flag assigned a COMPUTED value is still a condition and stays.
- loops.index_walk `for j in 0..xs.length` that then reads `xs[j]` — that walk is `for (j, x) in xs.enumerate()`, which hands over both. The rewrite reads every exact `${xs}[${j}]` inside `body` as bare `x` — the same token-splice `let_else_guard`'s `unforced` and `pronoun_lambda`'s `renamed` already use for a substitution a hole only ever holds as OPAQUE re-splicable text, never as editable structure; a body this pattern cannot walk as structure it can still walk as characters.
- loops.push_loop A `for` loop whose WHOLE body is one `push` is a MAP — a comprehension, or a `concat` when the pushed list already exists. `${out}.concat([${v} for ${x} in ${xs}])` is sound whether `out` started `[]` or already held content: appending N values one push at a time equals concatenating those same N values at the end, GUARDED to a `v` that never itself reads `out` — a push whose pushed value depends on `out`'s length-so-far (a running index, a running total) is not this shape, and the rewrite refuses it. The matched root is the `for` STATEMENT itself, and a `Fix.Rewrite`'s payload is always `@std.meta.Code` — a single EXPRESSION shape — so the replacement ASSIGNMENT (a statement, not an expression in this language) crosses through `@std/meta`'s raw-text door rather than `quote{}`'s own grammar, the same seam `modified_copy_literal` and `pronoun_lambda` use for a shape `quote{}` cannot hold.
- modules.unused_import A name imported and never used ANYWHERE in its MODULE — never per FILE, since bs2 merges a module's own files into one bundle, so an import in one file may serve another (`program.av`'s import can be `mod.av`'s to use); a per-file scan deletes an import a sibling still depends on. The compiler refuses a MISSING import (F3000) and one a module does not export (F3012); an unused one is silent, so this rule keeps that direction. `unused_imports()`/`unused_import_decls()` (features/code.av, THE REFERENCES RELATION) already exempt a component instance (`DeclFacts.instance`): its use is being REACHABLE for a `collect`, not being read.
- nullable.if_null_ternary A null test that picks the value or a default is `??`.
- nullable.let_else_guard `let x = E` guarded by an immediate absence-exit — `let x? = E else { … }` — with every later `x!` in the block reading `x` bare. A `mut` never matches: the pattern's own `let` name-seat sees only a `let`'s binder, a different node kind entirely.
- nullable.nullable_flag_local A `mut` local seeded `null` with an explicit nullable type — is this scan a `find`/`index_of`? A BARE-HOLE ROOT: a `mut`'s own binder NAME would need to open to match any local, and `root_kind_of` refuses to index a root whose own NAME or TYPE field is a lone hole — the raw fold keys on that literal spelling, which no real declaration shares (core/quote_pat.av). `is_nullable_flag_mut` reads both fields structurally off `self` instead.
- nullable.repeated_unwrap A `let` LOCAL forced open (`!`) three or more times within its own declaration — a value the code already knows it has, insisted on again and again instead of guarded once. A `mut` never matches (`forces()`'s own law): it changes every turn, so there is no one value to bind.
- specs.refusal_uncounted_contains A `then` case asserting only `.report().contains(...)` — the shape that lets a cascade of refusals hide behind a message that happens to appear. Pin the count too (`diagnostics.length`, `refusals(...) == n`, `refused_with`/`refused_n`/`refused_in`).
- structs.index_compared A hand-rolled identity comparison — every typed id (`TypeId`, `ExprId`, a struct wrapping one field) is compared by `.index` pervasively in this compiler's own source, but the SHAPE that makes the comparison honest — one word, nothing more — is a property of the type, not of the site that wrote it. `avra fix` names no mechanical rewrite here: a `.index` comparison names no verb the type doesn't already carry, so this rule only SAYS, never rewrites.
<!-- GENERATED:RULES:END -->

Unratcheted, read by a human: style.dedupe_union_fold (a matcher cannot see whether a
predicate has effects), style.doc_run_stolen (a stolen doc and a legitimate
multi-paragraph header are the same shape).
style.duplicated_literal came BACK from unratcheted once its regex was repaired: it had
been reading `if x is .Error { return ... }` as a struct literal,
so it was retired for false positives that were the rule's fault,
not the code's. Requiring a `field:` pair inside the braces fixed
it, and it immediately found three constructors waiting for names
(Span's four spellings, seed's `alt`, memory's nested scope).
Not ratcheted — the tool's UNRATCHETED table, entire, each with its
reason there: style.accumulator_declaration (the accumulator DECLARATION is a weak proxy — loops.push_loop
matches the real smell), style.evaluated_payload_chain (died with the eval collapse), style.dedupe_union_fold
(duplicate DETECTION), style.head_plus_tail_build (subsumed by loops.push_loop), style.statement_value_ritual (the ritual and the
only legitimate use are textually identical), style.value_if_ladder and style.name_generalization
(semantic — the review round hunts them), style.wrong_payload_count_pattern and style.restrlen_loop (RETIRED —
the compiler's F2015 and the string header answer them), style.early_answer_mint (mint
order is structure, not a token), style.doc_run_stolen (above), style.whole_table_scan (only a profile
tells the per-query scan from the one-shot walk), style.same_scope_borrow (the matcher
needs the enclosing fn's scope), style.fold_as_flag (above).

A RULE MUST BE ABLE TO FIRE. Every matcher carries a specimen the
tool re-checks on every run — added after compiler.bool_of_defaulted shipped with a regex
that could not span a nested call, which would have reported
success forever. A dead rule is the same disease as a drifting
baseline, one level up.

DEBT TODAY: ZERO. Every site is either idiomatic or licensed in
place with a reason. From here a single new violation fails the
gate — there is no amnesty left to hide in.

- style.accumulator_declaration  (ratcheted) an empty-list accumulator asks: is this loop a
      MAP? If yes, it is a comprehension (`switch_start`'s arm
      blocks). LICENSED where it cannot be: a STACK (`open_scopes`,
      ir_text's `switched`), a dual-channel fold, or a filter that
      needs the INDEX (`arm_cases` — comprehensions cannot
      destructure an enumerate).
- style.evaluated_payload_chain  RETIRED: the evaluated-payload chain. It died with the eval
      collapse — no site can exist to catch, so the matcher is gone.
      The number stays retired.
- style.hand_rolled_scan  hand-rolled scans that ARE `find`/`index_of`/`any` — SWEPT:
      the scan is `xs.index_of(x)` (returns -1 on a miss — wrap to
      `int?`), as `core/modules.av` reads a key's cut.
- bytes.clipped_scan  a scan CLIPPED AFTER it ran — `i = b.index_of(n, lo)`
      then `if i < hi { i } else { -1 }` — is right about the answer and
      wrong about the cost: it reads past `hi`, into every later field
      and the body, once per call. `b.index_in(n, lo, hi)` never reads
      past `hi` (std-http's framer paid 5.6 s -> 0.05 s native over
      2000 hostile heads). No rule: the clip is any comparison.
- lists.range_built_to_find  `[i for i in lo..n].find(p)` BUILDS the whole range
      before `find` reads it, so an early hit still costs `n - lo`. Where
      the range is a buffer's rest and the hit is near, that is the whole
      buffer per call: the evaluator's `index_of`/`run` twins cost a
      megabyte per scan until they became `while` walks. A range whose
      every element is read anyway (`all` over two equal lengths) is not
      this smell. No rule: the harmful half cannot be told from the
      harmless by shape. Sugar backlog: a lazy range `find`.
- style.dedupe_union_fold  the dedupe/union fold — NAMED: core `distinct(xs)` (STRING-
      only on purpose — `contains` compares non-strings by
      identity). The grammar's own folds use it — `first.av`,
      `diagnostics.av`, `ast.av`;
      validate's and coherence's `seen` folds are duplicate
      DETECTION (they emit on the dup), a different concept, left.
- style.head_plus_tail_build  head-plus-tail list builds — `concat`/`flatten` today, spread
      literals when the sugar lands (backlog). WHERE THE LIST LIVES
      DECIDES WHAT AN APPEND COSTS. Through a LOCAL `mut` binding,
      `out = out.concat(x)` and `s = s + x` append IN PLACE — the
      memory pass hands the cell's box to the reusing twin
      (docs/2026_09_23_REUSE_IN_PLACE.md). MEASURED (2026-09-23),
      100,000 appends: list 13.7s -> 0.001s, text 0.385s -> 0.004s.
      Through a RECORD FIELD of a shared value, or a `Cell`'s
      `get`→`push`→`set`, the whole value is still copied per append
      (measured 2026-09-17: 20,000 appends, 0.45s) — that growth is
      quadratic, and `compiler.str_grown_quadratically` names the text case.
      So a loop that appends builds through a local `mut` binding or
      is a comprehension. The two worst sites in the tree
      were both this shape: `Db.record_dep` (97% of the `bodies`
      phase) and `Decls.note_origins` (97% of `resolve`). AND THE
      COST IS NOT THE COPY-ON-WRITE — a push on a local that shares
      its list with another binding is in place, measured at the
      same 0.002s. It is that a write reaching a list through a
      field of a shared value, or a `Cell` round trip, cannot keep
      the unique copy, so no write is ever the one that pays.
- style.statement_value_ritual  the statement-value ritual is a VERB, never a two-step:
      `cx.walk_value(s)` / `cx.eval_value(s)` / `cx.lower_value(s)`
      (features/values.av) — eight spelled-out copies collapsed
      across let_stmt, expr_stmt, and mutation.
- style.value_if_ladder an if-ladder mapping a value to values is a MATCH, returned
      directly — match is an expression, `_ -> null` closes a
      non-exhaustive subject (`shape_named`, `term_kind`). A TABLE
      only when the mapping is consumed AS DATA: iterated, rows
      with several fields, or queried in more than one direction
      (the operator roster, builder registries). `when` is for
      CONDITION arms — mapping one subject through `when` repeats
      the subject in every arm. (Reserved words refuse as field
      names: `shape`/`table`/`ref`/`none`.)

- style.name_generalization a construct that GENERALIZES gets a general NAME. When one
      shape starts serving two masters, the special-case name
      becomes a lie the vocabulary carries forever: `Else` and
      `IfEnd` separated and closed a SWITCH's arms once regions
      went N-way, so they became `ArmEnd` and `RegionEnd` — nine
      files, zero test churn, and the compiler found every site.
      Rename AT the generalization, never later: the names are the
      published surface (`avra ir`, the IR goldens, every feature
      that emits them).

- A test asserting `A || B` asserts NEITHER (`style.disjunctive_refusal_test`,
      never its own registry entry — no matcher, no UNRATCHETED reason,
      just the name for citation): if the outcome is
      uncertain, run it and pin what happens. (Found writing the
      first adversarial suite — the disjunction was hiding that I
      did not know whether forward type references worked. They do.)
- style.registry_catchall a match where TWO OR MORE variants answer is a REGISTRY, and
      a registry ending in `_ ->` silently forgets the NEXT variant.
      One answering arm is a PROJECTION and its catch-all is honest:
      the contract already pins the answer for variants that do not
      exist yet. Eight registries were hiding behind catch-alls —
      `type_decl_name` (a third type-declaring statement would never
      have reached the type namespace), the answer projection's
      unprintable shapes, `give`'s runtime-callee validation, the
      bool comparison, and four capture shapes in the grammar
      builders. LICENSED where the doctrine FORBIDS exhaustiveness:
      a feature cannot enumerate other features' variants, and
      interp's run loop delegates everything else to `step`.
      GREW 2026-09-05: the LICENSE IS NOW A SPELLING, not a comment.
      `rest ->` says in the LANGUAGE what `// LICENSED style.registry_catchall` said in
      prose — the compiler reads it (F2040 goes quiet), the ratchet
      reads it (`_ ->` is what it looks for), and a reader sees the
      deliberate remainder without a tooling footnote. The old law
      fired at 191 sites tree-wide and none was the defect it names.
      All 42 prose
      licenses were measured DEAD the day the compiler's own law
      started counting answering arms: 15 became `rest ->` and 27
      were licensing a one-arm PROJECTION, which was never a
      violation. Their reasons stayed as plain comments; the claim of
      an approved deviation went. A rule with two enforcers keeps the
      one that can SEE — the grep still fails the gate on a new `_
      ->`, the compiler names the variants it forgets.
      THE PROSE LICENSE STAYS AVAILABLE, and one shape needs it: a
      registry hole that BINDS (`other -> f(other)`) cannot be
      spelled `rest`, which binds nothing. The compiler says so at
      that site rather than giving advice that will not compile, and
      `// LICENSED style.registry_catchall` is the exit left for it. A spelling that
      covers most cases does not get to close the escape hatch for
      the rest (P8).
      RETIRED (avra-8sb5.25.16): the regex found ZERO sites at the
      moment of retirement — no baseline debt, no `// LICENSED
      style.registry_catchall` comment anywhere in the tree — which is
      what "the old law fired at 191 sites and none was the defect it
      names" already predicted: once `rest ->`'s spelling and F2040's
      (now `type.registry_hole`'s) own count took over, the grep's
      SYNTACTIC net over `_ ->` text did no work a TYPED count over
      the declared enum's own variants was not already doing more
      precisely — and doing it for every package `avra check` touches,
      not only the ones this tool's own sweep reached. Not ported as a
      `rule`: the enforcement was never idioms.py's to hand off, it
      already lived in the type checker. `registry_forgets`/
      `registry_forgets_bound` (features/enums/check.av) are the live
      voices; a NEW catch-all still refuses there, gate or no gate.

- style.wrong_payload_count_pattern RETIRED (2026-09-04): a variant pattern writing the WRONG
      payload count. The bootstrap accepted `.A(_, _)` against a
      three-payload variant and bound the wrong things silently, so
      this rule kept the doctrine's "a new field breaks every site"
      promise by hand (and found two stale sites). Our compiler
      refuses it — F2015 "`.A` carries 3, the pattern names 2", on
      constructions too, one-line enums included — so the rule is a
      LAW now and the matcher is gone. The number stays retired.

A REFUSAL TEST THAT SAYS `>= 1` ASSERTS ALMOST NOTHING. One mistake
earns one message, so the COUNT is half the assertion — a cascade of
five passes `>= 1` silently. style.refusal_uncounted_contains already demands a count beside
`contains`, but it never saw this spelling, and 33 sites used it.
`refused_with(source, phrase)` in @std.avrac.testing makes the honest
form the SHORT one: it pins the count at one and the phrase together,
replacing a shape hand-spelled at 131 sites. A `refused_n` for the
shapes where a cascade is today's truth — pinning the count so a
later improvement is VISIBLE, every malformed fn signature being
exactly 2 — LANDED with the comptime lane, and HOW it landed is the
lesson: THREE test modules each wrote their own (two over a `Program`,
one over a source) while this paragraph still said it had never
landed. A WANT RECORDED AS ABSENT IS READ AS ABSENT — nobody greps
for a fn the rulebook says does not exist — so three authors wrote it
instead of one moving it. `testing/mod.av` exports it now, with
`said` (everything a program said — its files' diagnostics, the
workspace's voices, its defects) and `refused_in` beside it. Spell a
cascade `refused_n(p, phrase, n)` or `refusals(src) == n`.

The remainder is no longer a hand-kept tally: compiler.uncounted_refusal ratchets the
`>= 1` spelling and style.refusal_uncounted_contains's guard demands a real count, so the number
is whatever `make idioms` prints and the gate refuses a new one. The
sites were converted a suite at a time — a script conversion had
FAILED, because each suite interpolates its own fixtures, so the
programs measured were not the programs the tests run, and nine
tests broke.

THE REACH LAW (learned the hard way, four times): a rule claims a
SHAPE, and one specimen proves only that its matcher is ALIVE. Four
rules shipped blind spots a single specimen walked straight past —
lists.last_index could not see a dotted receiver, loops.push_loop could not see a one-line
loop, style.hand_rolled_scan could not see a generic with two parameters, and style.repeated_unwrap read
`s.token!` as a local. SPECIMENS now holds EVERY spelling a rule
claims, and the self-test refuses the tool when any is missed:
reintroducing loops.push_loop's blind spot names the two spellings it lost.

- lists.last_index's matcher was BLIND to a dotted receiver: it read
      `xs[xs.length - 1]` but never `m.frames[m.frames.length - 1]`,
      so six product sites hid from it — including the interpreter's
      register path, run on every instruction. Two matchers in a row
      have now been wrong in the same direction (style.repeated_unwrap over-counted
      field unwraps; lists.last_index under-counted dotted ones), which is the
      lesson: a rule's REACH is as much a claim as its wording, and
      both need a hit list read by eye before the rule is believed.

- ONE SURFACE, KINDS FORK AT TYPING. When two features want the
      same SPELLING, the parse stays ONE node and the meaning forks
      where knowledge exists: `X.y(args)` is MethodCall, and typing
      routes a VALUE receiver to the impl table, a TYPE NAME to
      variant construction (the shared `construct_variant` law);
      `catch`'s four surfaces fork on which CAPTURES arrived. The
      smell this kills: two grammar branches racing for one shape —
      the loser's @recover eats the winner (the let/let-else and
      for/for-each merges are the ordering lessons; the
      variant-lit/method clash was the breaking case). The dot-call
      is the exemplar since 2026-09-05: `impls/callee.av` decides
      WHO ANSWERS once (`Callee`), and typing and lowering each match
      it exhaustively — a new receiver kind breaks both passes at
      compile time.
- DECLARE THE WRECKAGE. A declaration that REFUSES still records a
      total, error-typed stand-in (a method without `self` declares
      every param a hole; an annotated binding records its declared
      type before refusing its value). One mistake, one message —
      and every downstream pass stays total instead of crashing on
      the gap. rt19's index-out-of-bounds is why this is a rule.
- THE INSTANTIATION RITUALS (unify.av): every generic surface
      (calls, struct lits, variant lits) shares three verbs —
      `tparams_refused` (the declaration already spoke; absorb),
      `unpinned_of` (the first open Var, voiced by the caller in
      its surface's words), `bound_closed` (ask after unpinned_of
      answered absence). The rule of three minted them: the absorb
      loop and the closing walk had each been hand-spelled three
      times before the extraction. A fourth generic surface joins
      by calling the verbs, never re-spelling the walks.
- style.restrlen_loop RETIRED (2026-09-05): a STRING's `.length` re-measured in a
      loop condition. It was `strlen`, so a re-measure was O(length)
      per turn and the rule ratcheted the hoists. Lane A gave the
      string box a length in its header, so the measure is a load and
      the re-measure costs nothing; the hoists that stand are
      harmless. The number stays retired.
- style.early_answer_mint an EMISSION VERB that mints its answer register early. The
      lowering contract is one line — registers are numbered in
      emission order — and a shared verb that takes `dst` from its
      caller invites the caller to mint it BEFORE the verb's own
      scratch registers, which desynchronizes numbering from
      definition order and crashes the backend on a recycled
      index. The idiomatic form: the verb mints its ANSWER LAST
      (taking `e` and calling `cx.result(e)` after its scratch),
      or emits the answer's defining instruction FIRST
      (tagged_value's shape — dst minted by the caller, defined
      by the verb's first emit). Found when called_through's
      first draft took a pre-minted dst: the corpus caught native
      reading register 7 of 7. RATCHETED BY THE LOWERING itself
      (2026-09-02, after R2's three property lowerings re-hit it
      and only the red-team ladder noticed): `give` records every
      defining instruction's register and refuses a mint-order
      break as a NAMED build defect — never a native crash.
      A second specimen (2026-09-05): a mint passed as an ARGUMENT
      to a verb that `reg_of`s its operands — `measured(cx, e,
      subject, cx.result(e))` — is the answer minted early by
      another route; `reg_of` may lower lazily and mint, so the
      answer is minted after every `reg_of`, never handed in.
- style.fold_as_flag a FOLD written as a flag where a scan would short-circuit past
      a needed SIDE EFFECT. `all`/`any` stop at the first answer, so
      a loop whose body must run for every element — `paired_unify`
      unifies each pair for its effect of BINDING the declaration's
      Vars, including the pairs after the first miss — keeps its
      `mut ok` and says why AT the site. The smell is a flag fold
      with no annotation; the idiom is `all(...)` whenever the body
      is a pure test. UNRATCHETED: a matcher cannot see whether a
      predicate has effects, so this one is read by a human.
      (Under the tree's old numbering this idiom took a TAKEN number
      until 2026-09-05 — it was filed as a second "I5", so seven
      `LICENSED I5` sites pointed at the dedupe rule that is the
      real I5, `style.dedupe_union_fold` today. Lane A found the
      collision; the tool refused a repeated NUMBER after that, and
      refuses a repeated NAME now that numbers are gone.)
- style.doc_run_stolen a `///` RUN THAT HEADS TWO DECLARATIONS. An inserted
      definition takes the doc of the one below it, and both lose:
      the newcomer wears a contract it does not have, and the
      original is left bare. Five sites the day the rule landed, all
      from one arc — `unflatten` wearing `mark_flat`'s doc,
      `flat_at` wearing three paragraphs about `field_read` and
      `slot_read`, `unified_lift` wearing THE ASSIGNMENT LAW that
      belongs to `accepts`, `bare_value` wearing `pack_value`'s, and
      `FlatRow` wearing the interner's. The smell is greppable: two
      or more `///` lines where an earlier line ENDS a sentence and a
      later one OPENS a new definition ("A ", "The ", "One ",
      "Whether ", "Mark "). NOT the smell: a multi-paragraph header
      whose continuations ELABORATE one definition (`Repr`,
      `rides_pointer`). The habit that causes it is inserting a
      definition above an existing one without moving its doc —
      which is exactly what a patch script does. UNRATCHETED: a
      stolen doc and a legitimate multi-paragraph header are the SAME
      shape — a sentence ends, the next line opens with `A`/`The`.
      The difference is whether the second paragraph ELABORATES one
      definition or DEFINES another, which is semantic. A first
      matcher printed 78 hits and the two inspected split one real
      (`workspace`'s `shown`) and one legitimate (`full_type`); a
      rule must justify every hit it prints.
- style.whole_table_scan A WHOLE-TABLE SCAN FOR A KEYED SUBSET. A verb asked per
      query that walks every row of a workspace-wide table to keep
      the few with one key — `[x.id for x in ws.decls.decls if
      is_impl_of(x, name)]`, asked per method dispatch — is a
      quadratic hiding as a comprehension. The idiomatic form is an
      INDEX filled where the rows are minted (`Decl`'s `@index name`,
      read by `Decls.impls_named` — one bucket), or a memo per key (`Workspace.sources`: one read
      and one line index per file per run, where `source(ws, f)` had
      re-read and re-indexed the file for every declaration typed).
      Found by a `sample`, not by reading: the two frames were the
      hottest in the compiler by self time and the ledger had
      guessed elsewhere. NOT the smell: a one-shot walk that builds
      the index itself, or a scan a program performs once.
- style.same_scope_borrow THE BORROW UNDER A SAME-SCOPE READ. `mut xs = self.field`
      followed by `xs.push(v)` is the alias form of a write — the
      smell is the alias where a path write (`self.field.push(v)`)
      says the same thing without a second name. It is LICENSED, and
      only there, where the SAME SCOPE has already READ the field
      (`self.field.length`, `self.field[i]`, a loop over it): today's
      memory pass holds that read's owned reference to the scope's
      end, so a path write after it finds the list SHARED and CLONES
      it (`slot_written` cloned the interpreter's whole array table
      per store — 60x slower). Two laws bound the license: the
      borrow is taken AFTER any callee that path-writes the field
      (a path write behind a live alias copies, and the alias goes
      stale — `file_id`'s borrow before `module_id` trapped), and it
      dies with liveness (S3 releases a read at its last use, and
      every such borrow becomes the path write).
      RETIRED 2026-09-05, and the second half of that prediction was
      WRONG in a way worth keeping. S3's liveness alone did NOT
      retire it: the sweep to path writes made the compiler 3.4x
      SLOWER (7.5s to 25.6s), because a read of `self.field` goes
      through the OWNED TWIN whenever the destination is managed,
      and that +1 lives to the scope's end whatever the retain rule
      says. Liveness had to reach the TWIN CHOICE too (S3b): a
      LENDING row's answer — one the subject still holds, which the
      registry now says in a `lends` column — is a borrow unless it
      must outlive the subject. With that, the sweep is FREE (6.87s
      against 6.90s) and all 17 licenses are gone. The lesson is the
      registry's: `avra_array_pop` also has an owned twin and must
      NEVER be borrowed, because a pop HANDS OVER — declining its
      twin trapped "a managed slot popped as a scalar". Which rows
      lend is DATA, and `lends` defaults to false so a row nobody
      has thought about is safe. UNRATCHETED: the
      matcher needs the enclosing fn's scope (a read BEFORE the
      write); the read-then-write scan lives in lane C's landing.

- memory.slot_alias_write (unratcheted) A RECORD READ OUT OF A LIST SLOT
      AND HELD ACROSS A WRITE TO THAT SLOT CLONES IT. `let s =
      self.streams[at]` then `self.streams[at].state = …` finds the
      element shared — the binding holds it to the scope's end — and
      copies the whole record on every such write: two clones of a
      13-field record per HTTP/2 request in `h2.av` (callgrind,
      `array_clone`). Read the fields through the slot, or bind the
      SCALARS the verb needs (`let id = self.streams[at].id`), never
      the record, in a verb that then writes the slot. The same law as
      `style.same_scope_borrow`, one level down: the element, not the
      list.
- style.unwritable_spelling_key (unratcheted) AN UNWRITABLE SPELLING IS A KEY — a name or a
      key that must never collide with what a program writes is
      spelled with a character the lexer refuses in that position,
      and the reader tests that one character. Three instances name
      the concept: the resolver's scope keys (`name@<file>`, `@`),
      generated declaration keys (`$`), and a template's hole
      placeholders (`${k}`, `l${2}` — `core/holes.av`, read by
      `hole_name`, whose test is `contains("$")`). THE SMELL: an
      in-band tag a program COULD write (a `__gen_` prefix, a
      numbered suffix) or a parallel side table asked "is this
      synthetic". Not ratcheted: the smell is a naming choice, not a
      shape a grep can see.

- style.arm_duplicates_sibling_answer (unratcheted) A MATCH ARM'S VALUE THAT IS `if c { x } else { y }`,
      WHERE ONE BRANCH ANSWERS WHAT ANOTHER ARM OF THE SAME MATCH
      ALREADY ANSWERS, IS A GUARD — the branch that duplicates becomes
      the fall-through, and the arm keeps only the branch that does
      not: `.Struct(_, _) -> if meta_type(ret, "Derived") { Derives }
      else { null }` beside a trailing `rest -> null` becomes
      `.Struct(_, _) if meta_type(ret, "Derived") -> Derives` (rest
      already answers `null` for everything else, Struct included);
      `.Variant(n, args) -> if n.of == name { padded(args, arity) }
      else { null }` beside `.Wild or .Rest or .Bind(_) or .Lit(_) or
      .Format(_, _) -> null` becomes the guarded arm plus `.Variant(_,
      _) or .Wild or …` — the payload-blind or-run widened to include
      the tested variant, since here nothing else already caught it.
      THE ONE SHAPE THAT STAYS: an arm whose EITHER branch answers a
      value no other arm shares (`.B(b) -> if b { "true" } else {
      "false" }` with no sibling saying either word) — nothing to fall
      to, so the `if`/`else` is the honest spelling; and a wide
      REGISTRY dispatch where every arm computes its own distinct
      answer (the interpreter's instruction stepper: `pc + 1` against
      `b.past_else(pc)`, `b.past_loop(pc)` — CLAUDE.md's own "wide
      REGISTRY, every arm distinct" case). UNRATCHETED: telling "this
      branch is what a DIFFERENT arm already answers" apart from two
      branches that merely LOOK similar needs reading every other
      arm's own answer and judging whether they are the same
      computation — the payload-blind or-run growing to include the
      guarded variant's own pattern is itself a per-site call a grep
      cannot make safely. Found sweeping the 52 `-> if` arm lines
      landed before arm guards existed (avra-8sb5.25.1): 23 converted,
      29 stayed — most of the survivors are the wide-registry shape,
      the rest genuinely answer two unrelated values.

- style.named_type_representation_check (unratcheted) A NAMED TYPE'S REPRESENTATION IS NOT PART OF
      `Kind` — `Kind.Named(name, args)` answers a declared name and
      its type arguments alone, never whether the declaration is a
      real record or enum (boxed, built) or a flat wrapper over one
      scalar (`type X = string`, free at runtime, filled from a
      token exactly as the scalar itself is). A rule that must tell
      these apart — `node_grammar.av`'s `flat_named`, deciding
      whether a grammar payload is text-filled or built — has no
      `Kind` arm to dispatch on, so it names the tree's three free
      wrappers (`Scoped`, `Plain`, `Nominal`) by hand, LICENSED at
      the site. THE SMELL nothing greps for cleanly: any OTHER named
      type this check would need to widen for is itself the trigger
      to give `Kind` (or `Field`) a representation bit, not to grow
      this list further. Not ratcheted — the exception is one closed
      site, not a shape a grep can generalize from.

- style.pack_unpack_one_table (unratcheted) A PACK AND ITS UNPACK READ ONE TABLE — two
      conversions that are inverses name their categories ONCE, as a
      registry enum, and each direction is an exhaustive match over
      it, arm for arm. The word slot is the instance: `slot_form`
      says which conversion a category owes the runtime's `int64_t`
      cells, `worded` casts in and `unworded` casts back, and neither
      can learn a category the other has not. THE SMELL: each
      direction written as its own chain of `is` tests, so the two
      drift a category at a time and the gap is not a refusal — an
      unconverted value rides the wrong register file and the callee
      reads a different number. Not ratcheted: no grep links two fns
      as inverses. THE KEEPER IS `make vocab`, which names both
      directions as consumers of the SAME enum and refuses a
      catch-all or an `is` test inside either — so a hole in one
      direction fails the gate whichever direction grew it.

- style.seen_shape_vs_seat_shape (unratcheted) A READ ASKS THE SEEN SHAPE, A SEAT ASKS THE
      TYPE — the named-type law (`type Rows = List<int>`) written as
      a code shape. A rule that DISPATCHES ON A SHAPE to read,
      print, measure, walk, index or compare asks `cx.seen_at(e)` /
      `types.seen_shape(ty)`; a rule that JUDGES AGREEMENT asks
      `cx.shape_at(e)` / `types.shape_of(ty)` and keeps the name.
      THE SMELL: a vocabulary row, a property row, a walk head or an
      operand law reading `shape_at` — it answers `.Struct` for
      every named value and the row then absorbs, sometimes with NO
      diagnostic (the map rows did exactly that). Every instance
      found in this slice was a READ. Not ratcheted: no grep tells a
      read site from a seat site, and both spellings are correct
      somewhere. The keeper is the adversarial suite —
      `named_adversarial_test.av` reaches every vocabulary a name
      can stand over.

- style.positional_boundary_unspelled (unratcheted) A POSITIONAL BOUNDARY SPELLS ITS ORDER ONCE — a
      value crossing between two compilations of the same
      declaration travels by SLOT, so the order is a REGISTRY ROW
      carrying the name, the payload count and the reader together
      (`node_readers`, `features/crossing.av`), and the writer takes
      its tag from that same list. THE SMELL: a reader that matches
      slot names as STRINGS, a writer that spells literal tags, or a
      check that lists the expected order in a second place — each is
      the order written twice, and the two spellings part silently
      the day the other side moves a field. The row is what makes the
      boundary check and the dispatch ONE fact. Not ratcheted: no
      grep tells a boundary registry from any other list of rows; the
      keeper is the boundary check itself, whose fixtures move each
      shape and demand the refusal name it.

- style.derive_file_not_alone (unratcheted) A DERIVE STANDS ALONE IN ITS FILE — a file that
      declares a trait's associated `derive` declares that trait, its
      helpers and `use @std.meta` and NOTHING ELSE. Running the derive
      TYPES the whole declaring file, and it runs while the ANNOTATED
      file's own impls are still registering, so anything else in the
      derive's file is typed against a half-built neighbour. THE
      SMELL: a `static fn derive` beside a walk, a state record's
      impl, or any fn that reads the annotated file's types. THE
      FAILURE IS SILENT AND BLAMES THE INNOCENT — the annotated file
      loses its methods and every CALLER is diagnosed, with nothing
      said at the annotation (51 such errors, all naming a file that
      was not at fault). `core/rebuild_derive.av` is the form;
      `core/protocol.av` and `features/projections.av` already had it
      by accident. Not ratcheted: no grep tells "declares a derive and
      nothing else" from an ordinary file with a trait in it, and the
      shape that breaks it is whatever ELSE the file holds; the keeper
      is the law in CLAUDE.md and the first build that tries.
- style.span_anchor_incomplete (unratcheted) A SPAN WINDOW'S ANCHOR SET HOLDS EVERY MEMBER IT
      COULD CLOSE ON. Optional pieces of a declaration are attached to
      the member they precede by WINDOWS over spans — a window opens
      at the previous anchor and closes at this one — and the whole
      correctness of that lives in the ANCHOR LIST. An anchor list
      that names only SOME of the members leaves the others' pieces
      inside a neighbour's window, so they attach to the wrong member
      SILENTLY: `aligned_marks` opened a variant's window at the
      previous variant NAME's end, which contains that variant's
      entire payload list, so the moment payloads could carry marks a
      variant's LAST payload's mark became the NEXT VARIANT'S. THE
      SMELL: a window helper whose anchors are one KIND of member
      (`List<Token>` of names) while the range it spans holds members
      of another kind (the payload types between them). THE IDIOM:
      one `MarkWindows`-shaped value carrying EVERY anchor, in any
      order, asked per anchor (`w.at(lo)`), so adding a kind of
      member that can carry the piece is adding it to the anchor list
      and nothing else. Not ratcheted: no grep tells a complete
      anchor list from a partial one — the anchors are whatever the
      grammar can put there. THE KEEPER IS THE ATTACK, and it is
      cheap: for each member kind, write the piece on the LAST member
      of one group with another group following, and read it back
      through the printer. Nine such cases round-trip at
      `annotations_adversarial_test.av`'s "payload marks — alignment";
      every one of them would have failed the partial anchor set.
- style.per_decl_walk_asks_stmt (unratcheted) A PER-DECLARATION WALK ASKS A STATEMENT'S
      QUESTION TWICE. A declared MEMBER can carry a declaration of its
      own standing on its OWNER'S statement — a record field's DEFAULT
      is minted with the struct's `s` (`decls.av`'s `mint("${owner}#${field}", f, s, …)`)
      — so a law asked `for d in decls_of_file(f)` about that
      statement's members runs once per member declaration too, each
      time with a DIFFERENT view of the owner's annotations. The mark
      law shipped that way for one build: four refusals for one
      mistake, three of them computed with an empty claim set because
      the field's default decl carries none of its owner's `@derive`s.
      THE SMELL: a decl loop that reads `decl(d).stmt` and asks a
      question about the STATEMENT rather than about `d`. The idiom is
      to walk `p.stmts` and find the owning decl once. NOT the smell: a
      question genuinely about the declaration (its sig, its name, its
      own annotations). Not ratcheted — no grep tells a statement
      question from a declaration one; the keeper is a test that pins
      the COUNT (`refused_in`, one mistake one message) over a member
      that has a declaration of its own, which is a field with a
      default.

- style.mutable_slot_not_cell (unratcheted) A MUTABLE SLOT IS A `Cell`, NEVER A ONE-ELEMENT
      LIST. `ensure: List<fn(DeclId)>` written `self.ensure.set(0, f)`
      and read `self.ensure[0]` is a Cell spelled as a list: its writes
      are list writes, so a copy of the holder forks them and the
      receiver law counts every arming as a write through `self`.
      `ensure: Cell<fn(DeclId)>`, `.set(f)`, `.get()(d)` says what it is,
      and a copy shares it. Decls held nine; the tree holds none now.
      Not ratcheted: no grep tells a one-slot list from a list whose
      first element is written.

- style.encoding_empty_field_dropped (unratcheted) A DELIMITED ENCODING
      DECODES ITS EMPTY LAST FIELD. `split` drops a trailing empty
      segment, so a name joined by a separator and ending in an empty
      field reads back one field short: `stable_line("module", [""])` is
      "module\n" and splits to one piece. The root module's name is
      empty, so every witness edge naming it answered unresolved, in
      both processes, and no root-module file could ever reuse an
      answer. A refusal case cannot see this — it passes when
      everything is refused — and only a positive control (an unchanged
      source is reused) failed. `wire_fields` restores the field.
      THE SMELL: a decoder that splits on the separator its encoder
      joined with and takes the field count from the result. THE IDIOM:
      write the empty case first — an empty last field, an empty first
      one, an empty middle one — as a round trip beside the codec, and
      ask of every such decoder whether its encoder can emit an empty
      tail. Not ratcheted: no grep tells a decoder from any other split.

- compiler.publish_by_rename (unratcheted) A PATH OTHER PROCESSES READ IS
      PUBLISHED, NEVER WRITTEN. A linker unlinks and re-creates its output,
      and a placed row is written at mode 0644, so writing a shared path in
      place shows a reader — a peer building the same package, the suite's
      own re-exec — the file missing, half-written or not yet executable:
      a package's suite binary was seen non-executable in 5 of 6 warm
      rounds, the window between the place and the mode set after it.
      `staged_beside` names a path no other process names, the file is
      finished THERE (linked, placed, mode set), and `published` renames
      it on in one step. THE SMELL: a verb that writes a path and then
      adjusts it — a mode, a stamp, a second write. THE IDIOM: adjust the
      staged file, then rename. A guard that samples the path proves it:
      tools/witness_parallel_build.sh reads mode and size in one `stat`
      while runs repeat, and a poller that read nothing is no witness.
      Not ratcheted: no grep tells a path others read from one nobody does.

## A scan that ACCEPTS beside a parser that EXPLAINS

A hot reader over a grammar answers a position, or -1 where the text
is not the grammar, and never words a refusal: on -1 it steps aside
and the ONE parser that explains says why. The two agree on which
texts are accepted — a boolean a differential test pins over
generated and mutated input — and never on messages, which would be
a second copy of every voice. @std/json's scans (`skip`, `string_end`,
`int_end`) beside `parse`; @std/validate's `T.from_json` beside the
tree path (`from_json` then `T.decode`), which answers every refusal
the direct reader meets. Smell: a fast path carrying its own error
enum that mirrors the slow path's.

## Lowering: MINT IN EMISSION ORDER

A register must be minted in the order its defining instruction is
emitted. The backend walks instructions once and indexes its value
table by register number, so a register minted early and emitted
late reads past the end — `index 6 out of bounds (length 6)` at
`avra build`, with the interpreter answering correctly the whole
time (it resolves by lookup, not by position). Found writing `??`:
the payload register was minted before the constant it indexes with.

```avra
let one = cx.const_int(1)              // mint and emit, one call (style.raw_mint_emit)
let carried = cx.array_get(sh, v, one) // the row's own typed method (style.raw_rt_call)
```

THE COMPOSITION COROLLARY (found collapsing the presence verbs,
relied on again by `flagged_pair`): a helper that mints IMMEDIATELY
before each emit is order-independent AT ITS CALL SITE — nesting
such helpers as sibling arguments (`nonzero(cx, tag_of(cx, v),
zeroed(cx, ...))`) keeps mint/emit aligned no matter which argument
evaluates first, because no register ever waits, unemitted, while
another helper runs. Helpers that mint EARLY and emit late lose
this and must stay sequential statements.

## `when` for dispatch chains

Any if/return ladder over conditions is a `when` expression:

```avra
when {
    c == 10 -> emit(token(TokenKind.Break, "", i, i + 1), i + 1)
    is_space(c) -> skip(i + 1)
    is_name_start(c) -> { ... }
    _ -> fail("unexpected character", i, i + 1)
}
```

## List comprehensions for filter/map

```avra
fn op_texts(r: LexResult) -> List<string> {
    [t.text for t in r.tokens if t.kind == TokenKind.Op]
}
```

Lists AND ranges: `[f(i) for i in lo..hi]` counts and `[f(i, x) for
i, x in xs]` pairs — the head is the `for` statement's, so whatever
that spells, a comprehension spells too.

## The enum vocabulary

`E.all()` is every variant of a payload-free enum, in declaration
order — a registry over an enum is never a second list beside it.
`v.name` is the word a variant was declared with (every enum, carrying
or not) and `v.ordinal` its place. A bare variant beside `==`/`!=`
reads its enum off the other side, through one `?`: `style.color ==
.Danger`, never `== Tone.Danger`.

## A named code is matched by name

A table of named numbers is ONE match: `match c { escape -> …, tab or
newline -> …, _ -> … }`. A bare name in a pattern that is a `const`'s
compares the subject to it by the equality law, anywhere a pattern
stands — an or-run, a variant's payload. The smells it replaces: a
`when { c == escape -> … }` ladder over one subject, an arm that binds
only to test (`x -> if x == K { … }`), and a literal repeated beside
the const that names it. The same spelling BINDS when no const wears
the name, so end such a match with `_ -> …`, never with a name: the
compiler warns where a match ends on a const, and where an arm follows
a name that turned out to bind.

## The native list vocabulary

`length`, indexing, `push`, `set(i, v)`, `pop` (-> `T`, never
`T?`), `concat(ys)`, `slice(lo, hi)`, `join(sep)`, `map`, `filter`,
`contains(v)` (-> bool), `index_of(v)`, `find(pred)` (-> `T?`),
`find_map(f)` (-> `U?` for `f: fn(T) -> U?` — the first PRESENT
projection, and the walk stops there), `any(pred)`, `all(pred)`,
`first()`/`last()` (-> `T?`), `get(i)` (-> `T?`: absence outside
the list, where `xs[i]` traps), `fold(seed, f)` (the seed carried
through `f(acc, x)`; a seed with no type of its own — `[]`, `null` —
takes the fold's declared answer),
`is_empty()` — all native, and native closures are mono-safe
(unlike fn args through OUR generics). They work in `<N>`-generic
bodies too (`bindings.find(it.label == label)`). The list is
features/lists/mod.av's method table, entire.

`enumerate` is a `for`-head and a comprehension head only, never a
value: `xs.enumerate()` alone is F2005 "`enumerate` pairs only
under a paired `for` head". And the runtime has NO `insert`,
`reduce`, `foreach`, `zip`, `sort` or `reverse` — each is F2030
"`.sort(…)` calls a method, and `List<int>` has none". core/lists
answers two of them with COPIES (`reversed`, `inserted`); `reduce`
is `fold`, and there is no sort.

A position a caller supplies is read with `get`, never guarded by
hand: `named.get(nth)`, not `if nth < 0 || nth >= named.length {
return null }` then `named[nth]`. And one accumulator rewritten per
element is a `fold`, not a `mut` and a loop: `attrs.fold(Reads {},
heard)`. Two accumulators stay a loop.

A scan READS, so a list of a NAMED type scans by the shape its name
stands over: `ids.contains(id)` over `type NodeId = string` needs no
one-field record to wrap the text. The needle's seat still wants the
name.

A scan is never a loop:

```avra
codes.find(it.kind == kind)?.id                        // first match, projected
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
f.builders.any(it.name == name)
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
if !defects.is_empty() { return unassembled(features, defects) }
let tail: Token? = tokens.last()
```

A loop earns its keep only for: `?` propagation in the body, folds
with ordering semantics (`closest`'s tie-break), index arithmetic,
and stateful transforms.

## Absence reads STRAIGHT — the if-null rule

One of the most important patterns in this tree.
A two-arm `null ->` / `x? ->` MATCH earns its lines only when both
arms carry real payload logic — absence handling reads straight,
never as a two-arm ceremony:

```avra
if target == null { return null }     // not: a `null ->` / `s? ->` match
self.slots[target!.index]

let f = r.farthest ?? FarthestFailure { cursor: c, expected: [p], in_rule: r }
let ptypes: List<TypeId> = sig?.params ?? []      // ?. + ?? collapse both arms
if m.label == null { repped } else { "${m.label!}:${repped}" }
```

And reach for the store's PROJECTION before writing an inline
match: `stmt_value`, `fn_parts`, and the value protocol trio exist so no caller
re-derives them. The proof case: a match enumerating statement
kinds whose arms cannot differ is pure ceremony — `stmt_value`
plus `if null` is the whole truth.

Projections come ONE PER VARIANT, never one per field: four
sibling `fn_name`/`fn_params`/`fn_ret`/`fn_body` projections were
the same match four times — `fn_parts` returns the parts struct
once and callers pick fields:

```avra
let name: string? = store.fn_parts(s)?.name
let parts: FnParts? = store.fn_parts(s)
if parts != null { declare_sig(s, parts!.params, parts!.ret) }
```

A projection that COMPOSES a pipeline gets a verb too: the
evaluated payload of a child is `cx.int_at(e)` / `cx.truth_at(e)` /
`cx.elems_at(e)` (features/values.av) — never the spelled-out
`int_of(cx.store.expr(cx.value_at(e)))`, which appeared eight times
before it was named. And after a null guard, a value read more than
once REBINDS (`let es = elems!`) so the `!` happens exactly once —
flow narrowing is tracked as avra-8sb5.10.100 in the tasks db; until
the language absorbs it, the rebind is the pattern.

## A field default is evaluated per construction

A default that CALLS something runs at every construction, so each
value gets its own:

    type Stmt = { raw: Cell<ptr?>, done: Cell<bool> = Cell.new(false) }

Two `Stmt`s hold two cells; setting one leaves the other alone
(measured, both engines). So a default may mint a box — the shared
mutable default that bites in other languages does not exist here, and
a field whose initial value is a fresh box belongs at the field rather
than repeated at every construction site.

## A pure map never mutates

An accumulate loop that only pushes `f(x)` is a MAP — write the
comprehension; the loop form is for effects, conditional pushes the
filter can't spell, and index arithmetic:

```avra
.ListLit(elems) -> fp(20, self.expr_fps(elems)),   // not: mut parts + for + push
let regs = [cx.reg_of(k) for k in elems]
```

A map the tree repeats gets a NAME (`expr_fps`, `stmt_fps`); a
mixed head-plus-tail builds with `concat`/`flatten` (spread
literals `[head, ..tail]` are tracked as avra-8sb5.10.24); and a
two-per-item map is `flatten([[a, b] for p in ps])` — proven in
the subset (param_fps).

## `it` projection for lambdas

```avra
let names = self.rules.map(it.name)
self.ranges.find(offset >= it.lo && offset < it.hi)?.feature
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
causes.all(cause_registered(it))
```

`it` binds at the nearest enclosing METHOD call — call wrappers and
bare-argument use inside the body are fine. A nested method call in
the body starts its own `it` scope (innermost method wins).

## Typed table literals for fixture data

```avra
type BreakCase = { src: string, breaks: int }
let cases = table<BreakCase> {
    src                    | breaks
    "a = b\n   | c\nd = e" | 2
    "\na = b"              | 1
}
```

The row type rides the literal (`table<Row>`) — the one form every
compile mode accepts. Use for pure data cases; keep named `then`
blocks where per-case failure names matter. Cells hold fn VALUES and
enum values too — a registry or an operator set is literally a table:

```avra
let rows = table<BuilderRow> {
    name          | build
    "int_lit"     | build_int_lit
    "fold_binary" | build_fold_binary
}
let ops = table<OpRow> {
    text | op
    "+"  | BinOp.Add
    "-"  | BinOp.Sub
}
```

## `with` for modified copies

```avra
cap("rules", rule_ref("rule")) with { rep: Rep.Plus }   // rare modifiers
r with { farthest: merged }                             // struct update
feature("clash", "clash_rule = NAME") with { diags: rows }  // extend a factory value
```

`with` chains, takes several fields at once, and applies to any
expression — a whole mut-reassignment ladder is one push:

```avra
ds.push(pointed(error_at(kind, at, msg), "used here")
    with { secondary: defined, help: "move the definition above this use" })
```

## Methods via `impl` (cross-file works)

```avra
impl Grammar {
    fn defects() -> List<Diagnostic> { ... }
}
// callers: g.defects()
```

A method is also the place a CONTRACT gets its name:

```avra
impl Token {
    /// Text equality, never against quoted input — data, not syntax.
    fn lit_matches(text: string) -> bool { ... }
}
```

`impl` works on enums too — derived properties live with the type:

```avra
impl Rep {
    fn suffix() -> string { match self { .One -> "", .Star -> "*", ... } }
}
impl Prim {
    fn token_name() -> string? { ... }
    fn answers_to(token: string) -> bool { ... }  // null-guarded ==
}
```

## Nullability instead of sentinels

Absence is `T?`, never `-1` or `""`: `label: string?`, `build: Build?`
(null = pass-through), `expect: Expect?`. Consume with `??`, `!`, and
`null ->` / `x? ->` match arms — one arm per LINE, since a
comma-ended arm swallows the `x?` that follows it.

```avra
text = text + (unescape(e) ?? src.substring(j, j + 2))
```

`?.` projects a field out of an optional; with `??` it collapses the
whole "if null, default, else unwrap and read" ladder — including
directly on a nullable call's result:

```avra
fn later_def(name: string) -> StmtId? {
    self.all_defs.find(it.name == name)?.stmt
}
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
```

`?.` reaches FIELDS and METHODS — `p?.doubled()` answers the
method's type, nullable — and a FN THAT MAY BE ABSENT: `self.press?.()`
calls the handler when one is held and answers absence when none is
(its arguments unevaluated), where `let f? = self.press else { return
}` then `f()` took three lines. `f?(x)` is not that form — it is `?`
then a call, and passes the absence to the caller. Mapping a present
value through a FREE fn or a constructor is still a guarded `if`.

## Extractor + `want` for typed unwrapping

Per-kind extractors return `T?`; one `want` owns the Result plumbing
and the error vocabulary. `?` chains the rest:

```avra
fn want<T>(x: T?, what: string) -> Result<T, string> {
    let out: Result<T, string> = if x == null { Result.Err("expected ${what}") } else { Result.Ok(x!) }
    out
}
// let body = want(alt_of(args[1]), "an alternation")?
```

A `T?` argument is direct evidence, so `want` needs no explicit `<T>`.

## `?` propagation on Result

```avra
fn call_args(v: Captured<GrammarNode>) -> Result<List<string>, string> {
    mut out: List<string> = []
    for x in as_list(v)? {
        let t = want(tok_of(x), "an argument name")?
        out.push(t.text)
    }
    Result.Ok(out)
}
```

## Generics: what infers, what needs pins

Proven capabilities:

- Generic enums with payload fields (`Captured<N>`), generic structs
  with fn-typed fields (`MatchContext<N>.build`), generic fns taking
  fn-typed params, and generic impls (`impl Arena<N>` — methods
  specialize per instantiation) all work — including TWO
  instantiations of the same fn in one compile unit.
- A bare `T`/`T?` argument is direct evidence — `want(x: T?, what)`
  never needs `<T>` at call sites.
- Constructions infer under a typed `let` and in a fn's TAIL position
  (expected types thread through match arms, if-branches, and list
  elements) — `Captured.Many([Captured.Terminal(t), v])` needs no
  pinned intermediate, a generic ctor works as a match-arm tail, and
  an early `return` reads the declared answer type too. What does
  NOT infer is a construction whose only N-evidence is SIBLING
  fields (`MatchResult { status: st, state: state, held:
  Captured.Absent }` — F2003 "`Captured.Absent` cannot pin `N` —
  nothing carries it"): that one keeps its typed-let pin.

Pin explicitly (`f<N>(...)`) when the arguments carry no evidence.
The case the compiler names is a bare `null`: `filled(3, null)` is
F2000 "argument 2 of `filled` wants `T`, found `null`", help "a bare
`null` cannot pin `T` — write `filled<...>(...)`". A struct argument
carries its own evidence (fn-typed fields included), and so does a
call sitting inside another generic body — probe before adding a
pin, and nesting a generic inside the pin (`f<Captured<N>>(...)`)
takes fine. Fn-typed ARGUMENTS carry no T-evidence, and pinning
`<T>` over one corrupts scalar payloads through mono — never thread
fn args through generics.

```avra
fn captured_absent<N>() -> Captured<N> { Captured.Absent }
```

## Vocabulary over ceremony

When every author would write the same wrap/unwrap stack, name it once
and the stack disappears from every call site. Bundle a call's world
into a context struct and the vocabulary becomes methods on it:

```avra
fn build_int_lit(b: Builder) -> Result<LangNode, string> {
    let t = b.token(0)?                    // not want(token_at(args, 0), "...")?
    b.make_expr(Expr.IntLit(t.int_value()))  // not Ok(Node(NExpr(alloc(..., span))))
}
```

The context carries what the engine knows (`b.span`, the store) so
authors never thread it; raw fields stay public as the escape hatch.

## Generic engine, concrete client

A generic engine takes ONE node type; a client with many node kinds
supplies a wrapper enum and unwraps behind its own accessors:

```avra
export enum GrammarNode { NGrammar(g: Grammar), NRule(r: Rule), ... }
run_grammar<GrammarNode>(g, tokens, grammar_build)
// consumers never match GrammarNode — they call grammar_result(o)
```

## First-class functions

```avra
fn scan_while(src: string, from: int, pred: fn(int) -> bool) -> int
// call: scan_while(src, i + 1, is_name_cont)
```

## Operator/escape sets as data

```avra
fn is_single_op(ch: string) -> bool { "=|()*+?:,-".contains(ch) }
```

## Map as a built-once index

`.get` returns `T?`; missing keys are honest nulls.

```avra
mut rules: Map<string, Rule> = {}
for r in g.rules { rules.set(r.name, r) }
// lookup: let found: Rule? = cx.rules.get(name)
```

## Range `for` over index windows

```avra
for i in 1..xs.length - 1 { out = "${out}, ${xs[i]}" }
```

## Rebind-alias for shared mutation

Params and captured structs are immutable, but rebinding a ptr-backed
list to a `mut` local aliases the same storage — the arena idiom:

```avra
fn alloc_expr(e: Expr, span: Span?) -> ExprId {
    mut nodes = self.exprs
    nodes.push(e)
    ExprId { index: nodes.length - 1 }
}
```

(A closure captures by VALUE: capture the `let` struct and go
through a fn like this; a write to a captured `mut` is refused.)

## Comprehension as list copy

The safe-snapshot idiom (never alias a list a rollback still holds):

```avra
mut xs = [x for x in items]
xs.push(v)
```

## `is` for single-variant questions

```avra
tail.prim is .Group && tail.rep == Rep.Star
```

A full match earns its place only when payloads are extracted.

## `or` arms for shared bodies

Same-body arms are ONE arm — the interesting variant stands alone and
the rest read as a set. Wildcards only; a binding cannot ride an `or`:

```avra
match p {
    .Group(inner) -> call_names_in_alt(inner),
    .Ref(_) or .Lit(_) or .Named(_) -> [],
}
```

## `_` by match species: projection vs dispatch

A PROJECTION asks one variant for its payload; every other arm is the
same absence or rejection. A new variant can never change the right
answer — the fn's contract pins it — so `_` is correct and
enumeration is churn:

```avra
fn node_of(v: Captured<GrammarNode>) -> GrammarNode? {
    match v {
        .Node(g) -> g,
        _ -> null,
    }
}
```

A DISPATCH decides behavior per variant — a walker's recursion, a
renderer's shapes, a checker's rules. There a new variant needs a
human decision, so `_` is banned (CLAUDE.md) and the site must break
at compile time; `or`-runs keep the enumeration one line:

```avra
match self.store.expr(e) {
    .Ident(name) -> self.use_name(e, name),
    .Binary(_, l, right) -> { ... recurse ... }
    .IntLit(_) or .Error -> self.nothing(),   // a new Expr must land HERE, visibly
}
```

Open domains (strings, codepoints, `when` chains) always take `_` —
there is nothing to enumerate.

Test assertions are projections-of-truth: "is this a Let named x,
else false" ends in `_ -> false`, so tests never break when the node
model grows. Only the PASSES' dispatch matches enumerate — those are
the sites a new variant must visibly break.

## Absence flows through, never re-matched

A mapping fn takes the OPTIONAL and passes absence through, so every
caller with a `T?` in hand maps in place instead of re-matching
(`loc_at(file, span?) -> Loc?`). Where a present value becomes 0-or-1
things, `some_list` turns the optional into a comprehension source:

```avra
let edits = [Edit { loc: l, replacement: n.name } for l in some_list(at)]
```

Both idioms end the `null -> []` / `null -> null` arms `??` cannot
reach (it defaults — yields the LEFT side when present — it does not
map).

And before reaching for either: check whether the optional should
exist at all. TWO levels of absence (`primary: Frame?` wrapping
`Frame.loc: Loc?`) forced a mapping match at every construction and
read; collapsing to ONE level (the frame is always present, only its
loc is optional — P6) deleted the matches everywhere at once:

```avra
primary: Frame { label: null, loc: loc }          // error_at: no match
d with { primary: d.primary with { label: label } }  // pointed: no match
if d.primary.loc != null { ... }                  // render: one check
```

## `enumerate` for indexed walks

```avra
for (i, m) in out.enumerate() {
    if i == idx { next.push(m with { expect: ... }) } else { next.push(m) }
}
```

## `flatten` / `joined` / `filled` / `some_list` from core/lists

```avra
diagnostics = diagnostics.concat(r.diagnostics)          // two lists — the native method
diagnostics: flatten([p.diagnostics, r.diagnostics, t.diagnostics])  // N lists, in order
"[${joined([render(x) for x in items], " ")}]"
targets: filled<StmtId?>(p.store.exprs.count(), null)   // dense-table prefill
```

`concat` is the LIST's own method, not a core fn — there is no free
`concat` anywhere (`concat<int>(a, b)` is F3000 "no `fn concat` is
defined"). `filled` keeps its pin because its only T-carrying
argument is a bare `null`.

## Components for self-describing bundles

A named bundle with defaulted fields is a `component` (the spec's
feature shape): only the fields that matter get spelled. Instantiation
is a STATEMENT binding the instance name — bind, then return it.

```avra
export component LanguageFeature {
    config {
        name: string,
        docs: string = "",
        gram: string = "",
        builders: List<BuilderRow> = [],
    }
}

fn let_stmt() -> LanguageFeature {
    component LanguageFeature f {
        name = "let_stmt"
        docs = "`let <name> = <expression>`, ended by the line."
        gram = """
stmt = "let" n:NAME "=" v:expression BREAK @recover(sync_to: "BREAK") -> let_stmt(n, v)
"""
        builders = rows
    }
    f
}
```

Config pairs are newline-separated; the `component`-prefixed
instantiation works cross-file (the bare form does not). A consumer
that cannot instantiate (metadata-compiled tests) goes through an
in-package factory and extends the value with `with`.

## Triple-quoted strings for embedded text

Grammar fragments, docs, fixtures, and GOLDEN test expectations —
an exact multi-line rendering compares against one `"""` block —
never `\n`-joined literals. Interpolation (`${name}`, fn calls
included) works inside them, and `\"\"\"` embeds a literal fence —
so a triple-quoted TEMPLATE can generate a file that itself
contains triple-quoted strings (the scaffolder's trick):

```avra
gram = """
expression = additive
primary = v:NUMBER -> int_lit(v) | n:NAME -> ident(n)
"""
```

In gram text, a zero-capture build is `-> f()` — bare `-> f` is a
CAPTURE reference and defects at assembly ("uncaptured label").

## Typed ids are single-field structs

`type ExprId = { index: int }`, never an int newtype — newtype scalars
corrupt through generic/mono flows (subset note). Struct ids ride
every boundary safely and stay nominally distinct.

## A value type earns identity through ONE minted id, not a new arena

A value that flows by-value everywhere (`Param`: embedded inline in
six different node payloads, read by dozens of passes) does not need
a full arena — `List<Param>` fields, its readers, and the four
derive-macro generators that fold/compare it all stay untouched — to
give it a real, side-table-keyed fact. Replace the inline fact
(`span: Span?`) with a minted id field (`id: ParamId`) and grow ONLY
the store's span table (`param_spans: Cell<List<Span?>>`,
`alloc_param_id`/`param_id_span` beside `alloc_pat`/`pat_span`) — the
value's OTHER fields, and every consumer of them, never change. The
mint happens at every CONSTRUCTION site (a builder threads the store
through, or gains one), and a REBUILD (quote/macro expansion) mints
its own fresh id rather than carrying the source's unchanged — an id
names a slot in ONE store's table, and `src`/`dst` in a splice are not
the same store, so an unminted copy would read a foreign index the
day the two tables diverge in length. A synthetic constant with no
store to mint from (`pronoun_param`) takes a reserved sentinel index
(`ParamId { index: -1 }`, matching `no_stmt`'s reserved slot 0) — an
identity question (`same_param_id`), never an absence check
(`span == null`) that any real value could also satisfy by accident.

## Match guards

```avra
match self {
    .A(n) if n > 10 -> "big",
    .A(_) -> "small",
    .B -> "none",
}
```

## Traits for contracts

A trait names a contract; types join by `impl Trait for` — across
package boundaries too. Keep mandatory methods to the one thing every
implementor must say; a method most implementors need not repeat
takes a DEFAULT BODY instead, typed once against the trait's own
`Self` and lowered per signatory — an override wins over its default
(ROADMAP, "trait default method bodies", landed 2026-09-05):

```avra
// @std.errors
export trait Error {
    fn describe() -> ErrorInfo
    fn cause() -> dyn Error? { null }
}

// any package
impl Error for Diag {
    fn describe() -> ErrorInfo { info(self.kind, self.message) }
}
```

Heterogeneous behaviour pairs data with `dyn Trait` — the CLI's
`Subcommand { meta: CommandSpec, body: dyn Runnable }` dispatches
each command through the one-method trait. `NodeSemantics` scales the
same shape to a MULTI-method contract: a feature's whole per-pass
behavior as one impl, and `semantics_of` — the ONE exhaustive map —
returns it directly (typed-let boxed; no strings, no lookup, no miss
possible). The impl is the completeness gate: a missing pass method
fails to compile. A method that deliberately does no work calls
`nothing()` — the decision is written, never implied. One limit: no
generic-enum returns through `dyn` — report through a capability fn
instead.

## The three seams of a pass

Every pass is standard at exactly two seams, and hand-shaped between:

1. DRIVER: `pass(p: ParsedProgram, ...upstream Facts) -> Facts` —
   facts own their diagnostics; `analyze` is the only place order
   exists.
2. FEATURE: one `NodeSemantics` method per pass, `(self, cx, e)` —
   and `StmtSemantics` is its statement twin: one impl per
   statement kind, one `<pass>_stmts` loop per driver serving top
   level and blocks alike.
3. Between them, the driver's own walk stays plain code — three
   similar 8-line visitors beat one generic walker until a fourth
   pass proves the shape.

A pass's STATE is `{ p: ParsedProgram, ...upstream Facts, ...own
tables }` — the program held as ONE immutable field, never exploded
into copied store/features/file fields. That is the "one big
context", done right: read-context is one shared value; write-state
stays owned per pass, because shared mutable context is the
god-object that makes pass order implicit and memoization
impossible. And passes are NOT a trait: their typed signatures ARE
the data-flow contract (`type_check(p, r)` cannot run without
resolution, provably); a `trait Pass` erases that and has no
consumer until the query engine memoizes passes uniformly — that is
its trigger, not before.

## Capability contexts: the state's impl is its vocabulary

A pass context (`TypeCx`, `LowerCx`, `ResolveCx`) is the pass's own
STATE, declared in features/contract.av and given its verbs as
METHODS: the walk's verbs where the walk lives (compiler/typing/typing.av's
`impl TypeCx`), the reads over facts (features/contexts.av), and the
shared vocabularies every feature speaks (checks.av, emit.av,
values.av, unify.av, variants.av, places.av) — so a feature's rule
reads as prose on its receiver, `cx.accepts(e, want)`,
`cx.open_region(c)`, `cx.presence(v, held, e) { cx, carried -> … }
else { … }`, and never as `accepts(cx, e, want)`. style.free_state_verb ratchets it
(the pass's own files); a feature dir's rule bodies dispatch on the
context and stay free.

```avra
fn coalesce_reg(mut cx: LowerCx, e: ExprId, l: ExprId, r: ExprId) -> Reg {
    let v = cx.reg_of(l)
    let held = cx.type_at(l)
    if cx.view.types.carried(held) == null { return v }
    cx.region(cx.presence_of(v, held), e) { cx -> cx.carried_of(v, held) } else { cx -> cx.reg_of(r) }
}
```

A block handed the context takes it as a `mut` seat — heard from the
slot's `fn(mut LowerCx) -> Reg`, never captured: a capture is a copy,
and a copy's `depth` diverges from the box's list. The earlier shape
— fn fields wired at construction, captured by every closure — is
gone with the sweep (the engine's `MatchContext.build` keeps one such
field, the builder dispatch, because a grammar run IS parameterised
by its builders).

## One semantics: lowering IS the meaning

A feature defines what its constructs DO exactly once — in
lower.av. Evaluation is the IR interpreted (compiler/backend/interp.av)
over the SAME instruction stream the backend compiles, so eval and
native cannot disagree by construction; the interpreter's Val enum
and runtime dispatch are the host twins of runtime/avra_runtime.c,
refusal wording included. (The earlier "values are literal nodes"
tree-walking evaluator was RETIRED by the north star's L3 collapse
— its whole per-feature eval.av layer died with it.)

## A table's read is the query

A fact table that consumers read by id (`Decls.sig(d)`) holds ONE
hook the driver arms (`ensure: fn(DeclId)`); the read calls it
first. The hook is the memoized query — it computes on first ask,
records the dependency, and detects a cycle — so every reader,
features included, asks lazily without knowing there is a kernel,
and declaration ORDER stops being a concern anywhere. The hook is a
one-slot list of a fn (the mut-cell protocol), armed after the
workspace exists; the table's default is a no-op. This is how the
four declaration rounds were deleted.

## A body's reads are its own

A body — a fn's, a method's, a field default's — is typed and
lowered as ONE unit over its own expression range, so it must never
read another body's facts. The language guarantees it with the BODY
FLOOR (resolve refuses a body's read of the top level's run-time
bindings — `F3020`, the remedy a parameter) and with one rule for
cross-module expressions: an expression another body needs is a
DECLARATION with a body of its own, and the needing body CALLS it.
A field default is the first instance (`DeclKind.Default`, `P.y`);
a struct literal that omits the field emits one `Call`. When a
feature wants to lower "that expression over there" inline, that is
the smell — mint the declaration.

## A type's methods are a namespace

Registration is the container's job (an impl block registers its
methods under the target when its own sig computes), and a name
taken twice is a CLASH computed once per table, in declaration
order, blamed at the later one — `method_clashes` beside
`module_names`, folded into the file that holds the later
declaration. A "declared twice" spoken by the second REGISTRANT is
ask-order dependent (the lone-file path asks bodies before sigs and
blamed the first block); a clash law over the finished table is not.

## A refused declaration still declares

A declaration the checker REFUSES (an orphan impl, an impl of an
undeclared type, a selfless method) still lands a signature — every
param a hole, the answer a hole — so every later walk stays total:
the body walk reads `self` from a real param list, the fn loop
finds a sig, mono finds a home. The alternative was found as a
crash: `impl Pair` on another module's type spoke its refusal and
then the body walk indexed an empty param list. One mistake, one
message, no crash downstream — `declare_wreckage(f)` in typing is
the one verb (`typing/impls.av`), called for every method of a
refused impl.

## The hunger protocol: go hungry, be fed, speak when starving

A typing rule that needs the EXPECTED type and has none does not
guess and does not refuse: it goes hungry (`cx.go_hungry(e)`,
answering the hole silently) and lets the one agreement door feed
it — `accepts` hands every hungry expression the want it meets
(`cx.feed`), and the rule runs again with it. At the walk's end
the rules still hungry run once more STARVING (`cx.starving()`)
and each speaks in its own words. Three rules ride it: the
annotation-less lambda (fed its seats), the bare variant
literal `.name(args)` (fed its enum — by a seat, or by the other
side of `==`), and a list or map literal of nothing but `null`
(fed its element). A CALL THAT WENT HUNGRY REFUSED NOTHING: its
hungry arguments wait with it (`settled_call`), or each would be
silenced with nobody left to speak. The smell it replaces: a
rule refusing "cannot infer" at a site the door was about to
feed, or a driver speaking a feature's refusal. UNRATCHETED: a
placement, read for at review.

## A bodied declaration: the driver brackets, the feature judges

A declaration with a body that must answer a type — a fn, a field
default, a test case — is typed in TWO halves that never trade
places: the DRIVER brackets the walk (the declared answer pushed on
the context's `fn_ret` for exactly the walk — `walk_under`,
`case_body` — one bracket for every kind, so `return` judges where
it stands) and the FEATURE
judges the answer (`fits_default`, `fits_case`: one `accepts`, one
voice, in the feature's own check.av). The smell that names this
idiom: a `// ── voices ──` section opening in a pass driver — the
voice belongs to the feature whose code registers it. UNRATCHETED:
the shape is a placement, not a greppable token; the review round
reads for it.

## A hole's `$` needs escaping ONCE, matching every other escape

A fixture that embeds another file's SOURCE as an Avra string
literal (a vendored template, a derive's fixture) writes a hole's
`${...}` the same way it writes `\n` or `\"` — ONE backslash. `\$` is
a real escape yielding a literal `$`; `\\$` yields a literal
BACKSLASH followed by `$`, which the INNER file's own lexer then
reads as a stray character before an ordinary `${...}` (or, in a
`quote` body specifically, breaks the hole's own tokenization) —
and the failure reads as an unrelated name-resolution defect ("no
fn X is defined") rather than an escaping mistake, because the
generated text still LOOKS like a hole to a human skimming it.
Diffing the string's DECODED bytes (a tiny probe program printing
`"a\$b"`, or `python3 -c "print(repr(...))"` on the raw file) settles
it in one step; guessing from the source text does not, since both
one and two backslashes render identically at a glance.

## A parked file survives a merge by CONTENT, never by BRANCH

Restoring a file wholesale from a parking branch or a backed-up copy
— after a merge that ALSO touched that same file — overwrites the
merge's own changes with whatever the parking branch happened to
hold, silently: no conflict marker fires, because git never sees the
two changes as one operation. This is the record-literal-merge law's
sibling one level up: `--theirs` taken whole loses a field the other
side added; a parked file taken whole loses whatever the merge
added, over the FULL FILE instead of one field list. Diff the
restored content against the merged HEAD before trusting it, on
every restore, not only when a conflict marker would have warned —
the merge's own diff already names the ground truth to check against.

## A fixture stands where the real thing stands, or it tests the stand-in

A keeper's fixture builds a small stand-in tree, and every place the
stand-in differs from the real tree is a place the keeper is not
tested. land.sh's batch fixtures passed 44/44 while every real batch
failed: the stub repo COMMITTED its fake `build/avra`, so each fresh
worktree carried a compiler, where the real tree ignores `build/` and
a fresh worktree has none. The same fixtures had no idioms baseline,
no warm cache, no `@fixes` rules and no symlinked `/tmp` path — four
more differences, and a real batch failed on each of them in turn.
The stand-in is written to make the fixture run, so it quietly
supplies whatever the code under test forgot to. Give the stand-in the
real tree's absences (an ignored `build/`, an empty cache, a physical
path), and before trusting a keeper built on stubs, run it once
through the real thing — one real branch through the real pipeline
is the receipt a green fixture cannot be.

## A rewrite that keeps its length keeps every span

When a value must be normalized before it is read, and spans already
index it, rewrite it OCTET FOR OCTET: the replacement is exactly as
long as what it replaces, so every offset taken before or after still
points where it did and no span map is needed. `frame.av`'s `unfolded`
spells a reply's obs-fold — `OWS CRLF RWS` — as that many spaces, and
the framer, the field spans and the client's field reads run unchanged
over the result. The smell it replaces is a second, shifted coordinate
system for one buffer.

## A per-core cache is a `once fn` of Cells

State one process keeps for all its requests is a `once fn` answering
a record whose FIELDS are Cells (`date.av`'s `stamp()`): each read is a
Cell read, never a copy of the record. A `Cell<Record>` there copies
the record on every `get` (spec 11.5), which on a request path is an
allocation per request. Seed it as the update computes it — the first
second's line is formatted by the same `line_at` every later one is.

## A layer's constant work is spelled once, in its closure

A layer is a fn made once and called per request, so whatever does
not depend on the request belongs in the maker, captured by the
lambda it answers: `hardening(h)` spells its fixed headers there,
`rated(r)` holds its bucket table there, and `served_at(path, api)`
writes its document there. The smell is a layer body rebuilding the
same list or text on every call. Measured: spelling the security
headers once took that layer from 1.0 to 0.8 µs a request.

## A layer hands its handler a field through `Request.set`, never the buffer

A request's head is spans into the connection's read buffer (up to
16 KB), so appending a field line to `raw` copies that buffer once
per field. `with_field` records the field in `Request.set`, which
every header read answers first, and costs no copy. The observe layer
paid 1.7 µs a request for the append before this form existed.
Anything that rebuilds a Request from another carries `set` along
(route.av's dispatch does).

## Proven but awaiting their first honest use

- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.

- THE ROOTS GREW 2026-09-05: the ratchet reads every std package (`packages/std-time`, `std-process`, `std-io`, `std-cli`), not the compiler and the cli alone — the first sweep found 13 sites in packages written under the bar but outside the tool's eye, all paid; a new `packages/std-<name>/src` joins SRC in tools/idioms.py with its first slice.
- style.refusal_uncounted_contains/style.wrong_payload_count_pattern GREW 2026-09-03: a counted refusal also spells `voices.length == n` (a Program's package voices are diagnostics); the ratchet's roots now include packages/std-toml/src, so a standalone package is held to the same bar; style.wrong_payload_count_pattern reads one variant per line (CLAUDE.md records the one-line-enum blind spot).

## A spliced call reads its value by a binder no program spells

A derive that splices a caller's own expression over a value it read
(`@range(13, 130)` → `range(v, 13, 130)`, `@std/validate`'s `Decode`)
binds that value where the call lands, under a name with a `$` in it
(`judged$`), and fills the call's hole with the NAME
(`applied(a, name(judged))`). Two things follow: the call reads the
value at the splice site, beside the siblings it may name, and a
refusal about the value points at the annotation — a spanless fill
stands where its hole does. The smell it replaces: filling the hole
with a template (`quote { got! }`), whose refusals point into the
library, and binding the value under the field's own name, which
shadows a rule of the same name (`@email email`). Not ratcheted: the
shape is one derive's until a second reader splices calls.

## AVRA_QTRACE's `declare` line is not a typing signal

`Q declare <name> <path>` fires for every declaration in the whole
program on every run, held files included — it is signature-table
reconstruction, not evidence that anything was freshly typed. A
measurement that windows "what did this edit cause" by counting or
timing `declare` lines near a file's own parse event is counting the
wrong thing; `declare` answers "the program has this name," not
"this name's facts were recomputed this run." The signal for "was
this recomputed" is the family-specific `ask`/`settle` pair
(`Q ask <family> <arg> compute` then `Q settle <family> <arg> …`),
read by family ordinal (`family_word`, compiler/cache_walk.av), never
by proximity to a `declare` or `parse` line.

## Typing is one later whole-program pass, not per-file

A file's own `parse`/`declare` events cluster together in the trace,
so it is tempting to assume that file's `Typed`/`Lowered` events
follow soon after, in the same window. They do not: the window
immediately after a file's last `declare` line is typically empty of
`Typed`/`Lowered` activity — typing runs as one pass over the whole
program's declarations after admission settles, not interleaved
file-by-file as each one parses. A per-file attribution of typing or
lowering cost needs a count or a direct per-arg timing (or compiler
instrumentation that tags a `Typed`/`Lowered` event with its owning
file), never a time-window read off file-adjacency in the trace —
found measuring compiler-db-57.18's S3 cut (per-decl warm-check
reuse), where this cost a wasted first attempt before falling back to
counting `Typed`/`Lowered` compute events directly.

## A warm edit is timed with text no earlier run checked

`check` keeps its whole answer under the source's bytes, so an edit
whose text some earlier run already saw is a cache HIT — it examines
nothing and answers in ~225 ms. A timing loop that alternates one edit
with its restore measures that hit from the second round on: main and
a branch both read ~225 ms while the real warm edit took 8 s and 6 s.
Each round writes text never checked before (`avra $i-$RANDOM: …`) and
the restore is untimed; only the first round of a toggling loop was
ever an edit. Measure main and the branch interleaved on one machine,
each tree with its own compiler, and quote every round, not the best.

## A derive's vocabulary is its library's declarations

A derive that maps a word a member wrote (`@attr(.Label)`, `on press`)
onto the library's own types reads those types — `type_exported(module,
name)` (`@std/meta`) — and never a table of names kept in the derive.
The enum IS the table: its variants are the words, a variant's payload
is the type that fits, a mark on a variant (`@word(press)`,
`@facet(content)`) is the fact about it. A word that is not there, a
type that does not fit and a thing said twice are each refused at the
MEMBER, in the derive's own voice; a refusal that surfaces inside the
derive's own `quote` is a check the derive forgot.
packages/std-ui/src/tree/view.av is the exemplar. A derive that
cannot read its vocabulary says so as its own defect, never `?? []`.

## A code rides its variant, and both directions are generated

A number a wire spells a variant with is a mark on the variant (`@code(3)
SetText`); `@derive(Codes)` (packages/std-ui/src/tree/codes.av)
answers `code()`, the reverse `coded_as(n)` and `coded()` — every
variant with its word, which is what writes a host's table
(`runtime/dom/wire.gen.js`, held by `make ui-host`). THE TRAP: a `${n}`
hole in a PATTERN position is a binder, not the literal — `match code {
${1} -> .A, … }` compiles and its first arm takes everything. The reverse
read is `[…variants].find(it.code() == code)`.

## A law the parse knows and the typer speaks

A builder that finds a law broken returns `.Err`, and that ends the
file's parse under `build.failed` with no help. Where the mistake is
ordinary — a mistyped event name — the builder MARKS the node with what
it found (`store.mark_unheard(handler, why)`), leaves the node out of
what it builds, and the feature's typing rule speaks the refusal with its
own kind and help (features/components: `Builder.unheard`, `event_law`).
One mistake is one diagnostic and the rest of the file is still checked.

## A refusal test compares every refusal the run spoke

A test that asks `report.contains("…")` passes over a run that said that
and ten things more, and a negative `!contains` passes over a run that
never ran. Collect the run's `error[` lines once and compare the WHOLE
list to the list owed, with its count; give a run that did not answer a
text no assertion can pass over (packages/cli/src/commands/tests/
ui_view_test.av: `spoken()`, `owed`, `never_ran`).

## A diff is a fold over what stood and what is wanted

Matching two trees needs no table of ids kept between them: lower each to
elements that know their SEAT among their siblings, and fold old against
new — a kept element carries its number across, a new one takes the
next. The fold answers the numbered page and the next number
(packages/std-ui/src/realize/dom/patch.av), and SAYS its patches into
one `Cell` list as it goes: a level that returns its patches for the
level above to concatenate copies its whole subtree's once per ancestor,
which is quadratic in depth in both engines. A table written through a
`mut` seat is the shape to avoid under `avra run`: a map copies on every
insert there, so `set` in a loop is quadratic in time and in memory,
while a `Cell`'s list grows in place in both engines.

## A host-only extern stands in a module only that host's programs import

A suite links what its files reach, so one `extern fn` a native link
cannot answer refuses every test that reaches its module. Keep the
extern, the exports and nothing else in ONE module (packages/std-ui/src/
web/web.av: `avra_dom_frame`, `mount`, `event`, `seat`), and put the
logic one module down behind a fn seat the host fills (realize/dom/
page.av: `paged(view, theme, page, send)`), where a native test hands it
a list to collect into.

## A generic seat is erased once, at the door

A value kept in a record cannot stay generic, and a trait impl over a
generic type is not landed. Take the type parameter at the constructor
and store the one closure the record needs (packages/std-ui/src/app/
app.av: `app<V: View>(view: fn() -> V, …)` keeps `(at: Standing) ->
rooted(view().describe(at))`), so every caller passes its own fn by
name and the record holds one shape.

## A loop is one door that answers whether it ran

Event, timer and arriving answer are the same thing to a loop: something
that may have changed the state. Give the loop one verb that runs it and
acts only when it answers true (`App.turn(act: fn() -> bool)`), and each
source is a caller of that verb — never a queue of typed messages with a
dispatch beside it.

## A match answers what the pair IS, never an index to look up again

Pairing two runs and handing back positions makes every consumer re-read
both sides and write an arm for the pair that cannot happen. Answer an
enum of the cases that can — packages/std-ui/src/realize/dom/patch.av's
`Stands { Made, KeptText, KeptTag }` — built in the ONE place both kinds
are in hand, and the consumer is one exhaustive match with no fallback.

## A seam only a real host exercises gets a run that builds the real thing

A module a native link cannot reach has no unit test that is not a test
of a stand-in. Keep its logic behind a fn seat a native test fills, AND
give the seam itself a gate step that builds and runs the real artifact
with every claim checked (`make ui-board`: tools/ui_board.sh builds the
board for wasm and runs tools/ui-board/demo.mjs). It skips aloud where
the toolchain is absent, naming what is missing, so a machine without it
is never read as green.
