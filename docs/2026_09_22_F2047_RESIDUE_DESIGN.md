# F2047 residue: the capture-wall sites, a design

avra-2y5c.4. Measured on std/f2047-residue @ 71f127a (`./avra check
packages/cli`, sibling lane std/f2047 not merged here, so this
worktree still carries the full pre-payment count).

## 1. The sites

69 F2047 warnings total on 71f127a: 43 `is not \`mut\`` (the sibling
STD-F2047 lane's ground — a root that just needs `mut` or a shadow),
4 `writes its receiver, and this is a value` (a call-result receiver,
also that lane's — `self.program().run()` in analysis.av:55 etc.,
already named in its own comments as paid by binding to a local
first), and **22** `is captured by value` — this ticket's ground.
The task named 21; the true count here is 22 (one more,
`store_ensured`, was not in the description's list — consistent with
"the count may differ, say what it is").

| # | file:line:col | capture | writes |
|---|---|---|---|
| 1 | build.av:190:62 | `self` | `kept_digest` |
| 2 | derive.av:239:71 | `self` | `home_moved` |
| 3 | derive.av:329:38 / :122 | `self` | `kept_boxed`, `record_type` |
| 4 | expand.av:317:43 | `ws` | `spliced` |
| 5 | program.av:348:107 | `ws` | `lowered` |
| 6 | workspace.av:395:39 | `ws` | `refetched` |
| 7–14 | workspace.av:398:33 … 405:166 | `ws` | `ensured`, `store_ensured`, `file_ensured`, `const_type_ensured`, `methods_ensured`, `writes_ensured`, `marks_ensured`, `lifted` |
| 15 | workspace.av:596:19 | `self` | `parsed_under_blocks` |
| 16–17 | workspace.av:750:42 / 751:45 | `self` | `generated_named`, `visible` |
| 18 | workspace_analysis.av:75:28 | `self` | `program` |
| 19 | workspace_analysis.av:146:150 | `ws` | `settled` |
| 20 | workspace_analysis.av:185:67 | `ws` | `lowered_for_eval` |
| 21 | sublang/builders.av:46:78 | `sink` | `minted_action` |

(All paths under `packages/std-avrac/src/compiler/` unless noted;
#21 is under `features/`. 21 rows, 22 warnings — #3 is two warnings
on one line.)

Sites 7–18 are exactly `built()`'s hook registrations
(compiler/workspace.av:392–406: `ws.decls.arm(...)`, `arm_store`,
`arm_file`, `arm_const`, `arm_methods`, `arm_writes`, `arm_marks`,
`arm_lifter`, plus the `families()` loop) and two later re-arms
(`parsed_under_blocks`, `generated_named`/`visible` — likely
`decls.arm(...)` called again per compile-time run, not traced
further here). Traced each write:

- **#1, #6**: `kept_digest`/`refetched` reach `query.Db`'s
  `verifiers: List<fn(int) -> int>` (query/db.av:36) and
  `Workspace.keys.stamped: Map<string,string>`
  (workspace.av:46, build.av:202) — both **bare**, not Cell'd.
- **#7–14**: `ensured`/.../`lifted` all reach
  `Decls.mint`/`.file_id`/`.module_id` (decls_mint.av:9,65,308),
  which push onto `Decls`' own bare fields: `decls`, `keys`, `sigs`,
  `provenance`, `marks`, `targets`, `seat_marks`, `declared_writes`,
  `faces`, `files`, `stores`, `mains`, `generations`, `origins`,
  `modules`, `paths`, `module_ids` (decls.av:98–187) — none Cell'd.
- **#3**: `kept_boxed`/`record_type` read `Decls.decls_of_file` (a
  read) but the enclosing derive round writes elsewhere in the same
  pass; not traced to one field in this note's time — verify at
  payment.
- **#2**: `home_moved` calls `text_digest` (build.av:189) → `Keys`
  fields, same as #1.
- **#4, #21**: `spliced`/`minted_action` reach
  `NodeStore.alloc_expr`/`alloc_stmt` (core/store.av:58,344), which
  push onto ~20 bare `List<T>` fields on `NodeStore` (core/store.av:
  4–41) — a **wider** admission table than Decls, same shape.
- **#5, #18–20**: `lowered`/`program`/`settled`/`lowered_for_eval`
  trace into the query kernel. `Workspace.asks`/`.settle_asks`
  (workspace.av:388,390) are **already** `Cell<List<...>>`, with a
  comment saying so (workspace_analysis.av:79–86,192–199) —
  already safe, and so is `Memo<T>.values: Cell<Table<T>>`
  (query/memo.av:17). The residue is `query.Db`'s own `verifiers`
  (#1/#6 above) and possibly `DbState.cells`'s outer chunk list
  (query/db.av:36) on the rare chunk-boundary grow.

## 2. What a shared growable handle would be

**The mechanism** (confirmed by reading, not assumed): `Decls` and
`Workspace` are boxed — any type with a method that writes through
`self` is sealed non-flat at `declare_impl_block`
(compiler/typing/impls.av:107–113: "A METHOD THAT WRITES THROUGH
`self` KEEPS ITS BOX"). A box is shared identity ONLY while it has
one holder; `built()` hands **11+ separate closures** their own
retained copy of `ws` (compiler/workspace.av:398–405 alone), so at
the moment any hook fires the box's refcount is >1. Per CLAUDE.md's
own law ("A BORROW ALIASES, A PATH WRITE THROUGH A SHARED
INTERMEDIATE COPIES" — "a VOCABULARY write (`push`, `set`, `pop`) on
a nested struct copies"), a `List.push`/`Map.set` reached through
`self.field` where `self` is non-uniquely held clones `self` (or the
field) to do the write, and the clone is discarded when the call
returns. This is not speculative: it is the exact mechanism the
STD-F2047 lane's own report described, and it is why `Cell<T>` (not
a plain field) is the fix — `Cell`'s `.push`/`.set`/`.set_at` carry
`ReceiverEffect.Shared`, which `receiver_law`
(features/checks.av:600) never gates on `mut_place` at all — a
Shared-effect call needs no mut root, by construction.

**(a) A vocabulary verb on Cell — ALREADY BUILT, already proven.**
`Cell<T>.push(v)` and `Cell<T>.set_at(i, v)` exist today
(features/cells/mod.av:13–14, `check_push`/`lower_push`,
`check_set_at`/`lower_set_at`), with the exact justification this
note would otherwise have to make: "the cell OWNS its list, so this
reads slot 0 and pushes — no `unique_box`, no round trip." They are
in production use for `Decls.module_files`, `.decl_ids`,
`.file_decls`, `.expansion_voices`, `.children`, `.methods`,
`.impls`, `.written_seats` (all `List<Cell<List<T>>>`, comment "ONE
SLOT, SHARED... an append must not copy the table") and, more to the
point, for **exactly this class of warning**: `Workspace.asks` and
`.settle_asks` were wrapped in `Cell<List<...>>` specifically to
close `spec_id`'s F2047 (workspace_analysis.av:79: "The table is a
Cell the capture shares, so minting is a read of the receiver — the
write a capture would hide is gone, and with it the warning"). **Cost
per push: O(1)**, same as a plain list (`avra_array_push` on the
slot's value, no clone). Against Q2(a) ("get/set, not forwarding"):
`push`/`set_at` are not forwarding — they are two more NAMED verbs in
Cell's own closed method table, not a mechanism that makes `Cell<T>`
call arbitrary `T` methods. The precedent above shows this reading
already stood without a fresh owner ask.

Remaining gap: **Map growth has no equivalent verb.** `Decls.paths`,
`.keys`, `.module_ids`, and `Keys`' five maps are all
`Map<K,V>.set(...)`, `ReceiverEffect.Write`
(features/maps/mod.av:23) — same hazard, no Cell escape hatch yet.
One new verb, `Cell<Map<K,V>>.put(k, v)`, symmetric to `push`
(`ReceiverEffect.Shared`, writes the key in place, no `unique_box`),
closes it the same way.

**(b) A `Table<T>` shared-by-construction type — rejected on cost
and on the ruling.** `core.Table<T>` already exists (core/table.av:
11) but is an ordinary aggregate, not an always-shared category;
"option (b)" as posed means a NEW value category that is a box with
no `Cell<T>` wrapper required — a SECOND, implicit sharing mechanism
alongside Cell. That is Q1's question again: "anything shared is
spelled `Cell<T>` and visible at the type" was the ruling precisely
to avoid a second channel. Even setting the ruling aside, it costs
the full IR/vocabulary growth protocol — every pass, every consumer
— for what two more Cell verbs already buy.

**(c) Hoist the mint out of the captured hook — rejected,
architecturally incompatible.** Read against all nine `built()`
registrations (workspace.av:398–405): each exists because its query
must be answerable **lazily, on demand, in any order** — the file's
own doc comment: "asked LAZILY — the table's own reads are the
queries, armed here — so declaration order stops mattering, a cycle
speaks." A hook that only runs when some later query needs row `d`
has no "outside the hook" point to hoist to; that point is exactly
what the design deleted by making minting demand-driven.

## 3. Recommendation

**(a).** Cell-wrap `Decls`' bare dense-by-id/bare-map fields (17
named in §1), `NodeStore`'s ~20 (a wider but same-shaped follow-up),
`Keys`' five maps, and `query.Db`'s `verifiers`; add
`Cell<Map<K,V>>.put`; rewrite `mint`/`file_id`/`module_id`/`admit`/
`alloc_expr`/`alloc_stmt`/`db.family` to read/grow through the
Cells. Once every write inside those functions is Shared-effect,
none of them need `mut fn` — the capture-site warnings (all 22)
disappear because nothing left in their call graphs is a
Write-effect call on a non-mut root.

Acceptance:
- `./avra check packages/cli 2>&1 | grep -c 'captured by value'` = 0.
- `./avra test packages/std-avrac` — eval == native == expected.
- `make census CMD="check packages/cli"` — no regression (`Cell.push`
  is the same runtime call as `List.push`, no new allocation shape).
- Flip `"type.receiver" | "F2047" | ...` (features/impls/mod.av:33)
  from warning to refusal — **only after std/f2047's 47 ALSO land**
  (this worktree still carries them; flipping alone here would
  refuse 43+ untouched sites). Name the commit as whichever of
  {std/f2047 merge, this redesign} lands second.

## 4. Risks / what needs the owner

- **`Cell<Map>.put` is new**, not yet built. Same shape as `push`
  (one named verb, `ReceiverEffect.Shared`, no forwarding) — likely
  needs no fresh Q2 ask, but if the master wants a re-ask, the
  wording is: *"does closing map-keyed growth need its own owner
  ruling, given `push`/`set_at` already extended Cell's vocabulary
  without one?"*
- **Read-site cost, not just write-site.** Cell-wrapping `Decls`'
  fields changes every READER too (`self.decls[id.index]`,
  `.length`, iteration) across every `impl Decls` block
  (decls.av, decls_mint.av, contexts.av, crossing.av, namespace.av,
  facts.av, interface.av) — mechanical but wide; size it before
  starting, it is bigger than the write sites alone.
- **A documented perf trap sits exactly here.** `mint`'s own comment
  (features/decls_mint.av:308–311): "the read of `keys` ends with
  `known_id`'s scope... held to this scope's end, it cloned the map
  per declaration, a tenth of every compile" — already hand-tuned to
  avoid a clone-per-declaration regression. Cell-wrapping must keep
  reads short-lived the same way, or reintroduce it.
- **NodeStore and the query kernel widen the blast radius** beyond
  "Decls' admission path." Pay Decls first (proves the pattern at
  the 17 named fields), land it, then file NodeStore's arena and
  `query.Db`'s `verifiers` as an explicit follow-up rather than
  folding them in silently here.
- Sites #3 (`kept_boxed`/`record_type`) and the derive-round writes
  were not traced to one field in this note's time budget — verify
  each specifically before paying it; do not assume it is Decls
  without checking.
