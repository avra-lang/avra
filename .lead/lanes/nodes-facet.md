# nodes-facet

Branch `nodes-facet` off `origin/main` 9cdec783 (worktree
`/Users/tristan/projects/tristanMatthias/avra-nodes-facet`). No Sprite
free (SPRITES_TOKEN unset, all bound): heavy builds run locally under
`tools/watch.sh`, contended with other lanes.

## 2026-10-16 ~00:47 — implementation drafted, waiting on the build lock

Built `@facet` as the sibling of `@local` through ONE field-mark
registry (`core/field_marks.av`): `@local` = (no child, out of identity,
value on the node); `@facet(table)` = (no child, value leaves the
gathered payload for the side table the mark names).

- Every shape derive (Children, Flow, Exact, Matchable, Identity,
  Fingerprint, Makes) now asks `reached`/`carried` instead of testing the
  word; the marks claimed.
- Gather: `declared_fields`/`Variant.payload` drop `@facet` fields, so
  the gathered enum payload omits them while the record declares them.
- Write: `Builder.make_stmt` calls `settle_facets(id)` — the side-table
  registry (`facet_rows`) writes `store.mark_<table>(id)`, which restamps
  the node's fingerprint (a facet is IN identity; `@local` is not).
- Converted ONE feature: `FnDecl.@facet(once) once: bool = false`; the
  `once fn` rule ends `-> Stmt.FnDecl`; `build_once_fn` deleted.
- Tests: `core/tests/facet_mark_test.av` (registry + once side table +
  identity difference); the existing `fns/tests/once*` program tests
  exercise the conversion end to end.

BLOCKER: the machine build lock has been held ~14 min by another lane's
`gate_changed`; `make try` cannot start. Next: build, fix, then
red-team + review-round, pre-flight, draft PR.

## 2026-10-16 ~01:30 — machine lock was self-deadlocked; unstuck

`avra-nodes-field-default`'s preflight (`tools/_nfd_1.sh`) invoked
`sh tools/watch.sh 12000 sh tools/_nfd_1.sh` — itself — so the inner
watcher queued behind the lock its own outer wrapper held: a permanent
self-deadlock blocking every lane. Killed only the queued inner watcher
(pid 49968); the lane's real `build/avra test packages/std-avrac`
resumed and held the lock legitimately. Memory at that moment: 29% free,
swap 8462/9216 MB used — no second heavy run attempted.

Repro of the trap pending the lock. Status: `make try` trapped with
`avra: index 0 is out of bounds (length 0)` before this; a probe using
the standing compiler is NOT a valid repro (it reports `fp_str`/`reached`
"without a body", a probe-context artifact). Need a real backtrace.

## 2026-10-16 ~11:00 — LANDED (draft PR #819, base main, NOT armed)

Branch `nodes-facet`, head `ad6090a8`. 15 files (+3 new: 2 tests +
registry is in fingerprint.av). `@facet(table)` built as the sibling of
`@local` through ONE field-mark registry; the gather drops a facet from
the enum payload while the record keeps it; `Builder.faceted_stmt`
writes the named side table (restamping the fingerprint = IN identity);
`FnDecl.@facet(once) is_once` converts `once` (build_once_fn gone). The
committed seed is refreshed (the enum payload is compiler-computed, so
the mechanism must be in the seed).

Root cause of the early `make try` trap: my own `Result<(), string>`
(unit type unspellable — parse error) + `table` is a reserved keyword;
the parse failure cascaded into features/enums/check.av
`alternative_law`. Fixed; registry checks green.

RED TEAM run: every field position (plain/local/facet/facet-no-arg);
payload/record split (row 6, enum 5); side table absent for fn / present
for once; identity once != fn. SURVIVOR FOUND + FIXED: a `@facet` on an
Expr/Pat record was silently dropped (no expr/pat side table) — now
refused loudly (builder `no_facets_here`). Tests land permanent
(`core/tests/facet_mark_test.av`, `facet_adversarial_test.av`).

REVIEW ROUND: registry is the one definition (no second copy of the
mark→route question); or-runs for shared bodies (idiom keeper clean);
no debris. Leave-alone: the registry lives in `fingerprint.av` (a
derive file already home to `binders`/`folding`) rather than a new
`field_marks.av`, because a new file forces another seed emit — a
recorded trigger for the next slice.

PRE-FLIGHT: gate_changed --no-keepers clean; keepers-static exit 0;
AVRA_CAP_MB=12000 avra test packages/std-avrac exit 0 (peak 3214 MB);
fns program tests eval == native.
