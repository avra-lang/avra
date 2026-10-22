# nodes-step3 lane

[2026-10-16] Branch nodes-step3 (worktree ../avra-nodes3). Head 6ece437b6,
base main 99dd79ae. DRAFT PR #820, base main, NOT armed.

LANDED (the landable half of step 3): the walk's `@local` law + adversarial
tests. `@derive(Children)`, `@derive(Matchable)` and `@derive(Flow)` now skip a
`@local` field (a span, a process-local id) — it is not part of what a node
HOLDS/IS/DOES, mirroring Identity/Fingerprint. One definition
(`local`/`local_word`, core/fingerprint.av), three derives claiming it. No node
declares a `@local` id field yet, so the guard is a law-keeper today; the first
such field is its first real test (recorded trigger). Tests:
core/tests/children_adversarial_test.av (degenerate none/one/many, declaration
order, hidden match arms, lambda body, clause order) and
features/tests/kids_walk (eval == native).

Receipts: make bootstrap gen-1+gen-2 green (peak ~2270/~2200 MB);
gate_changed --refs origin/main HEAD --no-keepers clean; make keepers-static
exit 0; AVRA_CAP_MB=12000 avra test packages/std-avrac — 429 programs proved,
status 0.

BLOCKED (owner decision; full details in PR #820 body and below):
per-record `kids`/`heirs` generated from the record's shape cannot land on the
#813 base.
1. `Children` is applied to the gathered enum; its output lands in nodes.av
   where the member records are out of scope (`impl Binary` -> "serves no
   declared type"). The shape can only be `impl Expr { fn shape_kids() }`.
2. A trait default cannot call an inherent method on `Self` (PROBED:
   `fn a() -> int { self.b() }` -> ``type.method: `T` has no method `b` ``).
   So `NodeSemantics.kids()`'s default cannot read `self.shape_kids()`.
3. A per-record `@derive` must be in the trait's package; `NodeSemantics` is in
   features, so core records (~40) cannot import a features derive, and moving
   the trait to core orphans the features impls for core records.
RECOMMENDED: `impl Expr { fn shape_kids() }` from `Children` + a single
`impl NodeSemantics for Expr` (overrides + `rest -> self.shape_kids()`),
accepting that it undoes #813 for kids/heirs only; or a `@delegates` shape
fallback. Awaiting the owner.

Earlier (obsolete) attempt on pre-#813 main 9cdec783: `kids(store,id)` default
`store.expr_children(id)` SEGFAULTED in gen-2; origin/main bootstrapped clean,
so the change was at fault. Superseded by #813.
