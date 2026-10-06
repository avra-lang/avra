# DB 01 — one engine: the design note

2026-10-06 · branch `db-engine` · worktree `../avra-db-engine` · ticket `avra-8sb5.57.170`
Plan: `docs/2026_10_06_COMPILER_DB.md` and its hand-off, on `origin/db-design`.
Base: `origin/main` @ `4294595`. Nothing here is built unless a line says so.

Status: P0 and P1 have a go. P3 onward is held for the review of this note.
Decided by team-lead after the first draft: Q1 yes, Q2 yes, Q3 this lane (§9).
§5 (tasks) was added after the first draft and has not been reviewed.

READ (opened, each): the plan and hand-off, `query/kernel.av`, `query/memo.av`,
std-relation `db.av` / `query.av` / `input.av`, `families.av`, `workspace.av`
:500-800 / :965 / :1682, `decls.av` :680-1090, `compiler/db.av` :540-660, REVIEW
B2 / B3 / E2 / G1, REVIEW2 N1 / N2 / N4 / N6, the db-measure kernel diff.

## 1. End state — files and types

1. `packages/std-relation/src/kernel.av` (today's `query/kernel.av`), `answers.av`
   (today's `query/memo.av`: the typed `Relation<T>` = kernel + family + value table),
   `fixpoint.av`, `key_marks.av`, `table.av` (core's `Table` / `list_cell` / `map_cell`,
   which the kernel needs and std-relation cannot import from std-avrac). std-avrac's
   `query/` is DELETED; its tests move too. The layering line becomes
   `core → grammar → features → compiler`, all over `@std/relation`. The moved files
   name nothing in std-avrac (the derive-file law: `relation.av`'s import closure grows
   by them).
2. `Db` (std-relation `db.av`) = `@identity { id, kernel: Kernel, closed, closers,
   sweepers, runs, names, durable }`. EVERY Db owns a kernel, `new_db()` included, so a
   run-time program has the same engine. Deleted: `Hooks` (all nine), `quiet_hooks`,
   `hooked_db`, `armed` / `quieted` / `rearmed` / `registrars`, `Memo<V>`, `Kept`,
   `InputSlot`, `writes`, `cells`, `running`, `owner_frames`, `last_query` /
   `last_frame`. Kept until DB 07a, unchanged in meaning: named owners and their sweep
   (`owner_named`, `opened_run`, `closed_run`, `put_owned`) — `decls_mint.av` mints
   Decl rows through them.
3. The compiler: a Workspace has ONE std-relation Db. Today it has three plus a bare
   kernel (`decl_rows` armed to the kernel, `failures_db` hooked to it, `refs_db` a
   plain unrecorded `new_db()`, compiler `Db.kernel`). `compiler/db.av`'s `Db` keeps its
   `DbRow` store until DB 06 / 12 but holds that one Db. `relation_hooks`,
   `kernel_hooks`, and the two copies of the hash→revision conversion (`workspace.av`
   `revision_of_hash`, decls' `move_stamps` — both string-keyed maps per cell) become
   ONE kernel verb over dense int rows.

## 2. How a query finds its engine (D3)

- `once fn ambient() -> Cell<Db>` in std-relation, seeded with the process's default
  Db; `current()` reads it; `within_db(d) { … }` swaps and restores (a free fn: generic
  methods are F2031). A `@query` wrapper reads the ambient to find its engine, so inside
  a body the ambient is, by induction, the Db the query was asked on. Nothing else sets
  it. §5 replaces the `once` cell with a per-task value; the accessor does not change.
- Several workspaces in one process: each command or test entry enters its workspace's
  Db. A converted compiler query finds its Workspace as `workspaces()[current().id]`
  (the dense-by-Db-id pattern `Stores<R>` already uses), cleared at `disarmed`. The
  default Db has no workspace, so a compiler query asked outside an entered workspace is
  a named refusal, never a wrong answer. Each Workspace face that fronts a converted
  query checks `current().id == self.rel.id` (one compare) and refuses on a mismatch —
  the only defence against "B entered, A's method called"; its cost is measured and
  held to the read budget.
- The evaluator: `once` answers are per machine (`backend/interp.av:107`, `onces`), so
  an evaluated program has its own ambient and default Db and can never see the host's.
  A plugin query reaching the compiler's kernel stays DB 10's host row.
- Tests that build many Dbs: ids are dense and never reused; per-query answer slots are
  indexed by Db id and released by the Db's closers, exactly as `Stores<R>` today.

## 3. How each thing becomes a kernel cell

- `@query fn q(k: K) -> V`: generates `once fn q_answers() -> Answers<K, V>` (slots by
  Db id, each a `Relation<V>` plus its keys) and a wrapper = today's
  `Relation.start` / `finish_lazy`. The family is registered on first ask by stable name
  (module path + fn name); its verifier re-asks `q` for that arg. The arg is the int of
  a `@dense` key (std-meta's existing mark; `DeclId` / `FileId` take it), else the key
  interned per family — by stable hash in 01, as today; by encoded bytes at DB 03 (the
  collision weakness exists today and is not added). V's digest: its stable hash when it
  has one, asked lazily; for an answer with no encoding (`DeclSig`, `TypeFacts`) the
  query names a digest fn.
- `@input fn i(k) -> V`: the same `Answers`, through today's `Relation.input`; `set_i`
  is `kernel.set_input`. It records its read. `@input` and `Memo.input` are one
  definition.
- A relation's row set and index buckets: the same cells as today (0 = the set,
  b + 1 = bucket b), registered straight on `db.kernel`; a read is `kernel.record_at`.
  The late-write law is unchanged.
- An un-owned row insert inside an open `@query` is REFUSED with a named voice (D4;
  Q1). `Frame`, `began`, `ended` and the self-read law are deleted with it. Compiler
  families keep named owners until DB 07a.
- `@family`: `Workspace.built`'s loop calls the same `kernel.family(name, verify)`;
  `Family` and its ordinals stay until each family converts. The two unchecked strings
  (`"DeclId"`, `"DeclSig"`) leave the marker in the names PR; real types return per
  conversion.
- `Sig`, end to end (the worked example): `@query fn sig_of(d: DeclId) -> Signed`, its
  body today's `sign_cx_for` + `declare_one`. Gone: `Family.Sig`, its `refetched` /
  `family_word` / `reads_rows_whole` arms, `decls.sigs`, `sig_voices`, the hand-written
  ask / begin / settle. The held branch moves inside the body and dies at DB 07e.

## 4. PR sequence

Each off `origin/main`, green alone, reported before the next.

| PR | what | plan's name |
|---|---|---|
| P0 | the instrument: `tools/db_measure` + `AVRA_DB_GRAPH` from `origin/db-measure` | DB 00 |
| P1 | deps as packed ints (`family << 40 \| arg`; a negative arg refused at the record site); the kernel's state no longer copied per new read; the repeat-read fast path cut for `Named` / `Items`. Inside today's kernel, behaviour unchanged | 01c |
| P2 | `read_cost.sh` over db-measure's readbench | 01d |
| P3 | the move (§1 item 1): files only, no behaviour | — |
| P4a | one engine: §1 items 2 and 3, the `Db` argument still spelled. c3's assertion (`pure` runs once after unrelated writes) in std-relation's suite on a plain Db AND in `compiler/tests` | 01a + 01b |
| P4b | the D3 spelling: `@query`, `@input` and the generated relation accessors lose the Db seat (27 non-test call sites, 215 in tests; mechanical) | 01a |
| P4c | the task-local row (§5): two landings | new |
| P5 | names, speaking refusals, `make families-left` = 32; `make families` and `families.order` retired on the two stated conditions | 01e |
| P6 | `Sig` converted: families-left = 31 | DB 12 |

Why not 01a → 01b as written: with the engine in std-relation there is no seam for the
compiler to arm, so a and b collapse into P4a. The semantic change (P4a) is split from
the spelling change (P4b) instead.

## 5. Tasks — what the law is at run time  (added after the first draft)

The owner put the engine in `@std/relation` so RUNNING programs get it. The first such
program is a server with a task per connection whose query bodies wait (a database
read). So "a query body never yields" cannot be the run-time law.

What is per ASKER, not per engine — three things, and they travel together:

| state | today | why it is the asker's |
|---|---|---|
| the ambient Db | (new) | two tasks may work on two Dbs |
| the open-frame stack: `open`, `pending`, `restore`, `began`, `readers` | fields of `KernelState` and `Kernel` | a task that waits mid-body must find its own frames when it resumes, and another task's reads are not its deps |
| "is this key in flight for ME" (the cycle test) | `open.any(same_key)` over the one stack | a key open in ANOTHER task is not a cycle |

Everything else is the engine's and is shared: cells, verifiers, the revision, the
last-reader stamps.

**The design: one `Asker` value per task, found through one accessor.**

```avra
type Asker = { db: Cell<Db>, open: …, pending: …, restore: …, began: …, readers: … }
fn asker() -> Asker      // the running task's
```

- `asker()` reads ONE task-local slot: a runtime row pair (`avra_task_slot` /
  `avra_task_slot_set`) over one managed pointer on the task record, released when the
  task ends. That is the whole runtime change. It is two landings by the registry-row
  law: the row `Unhosted` plus its C body, then the declaration, the evaluator's arm and
  the callers.
- A spawned task starts with an EMPTY frame stack and the spawner's ambient Db. A
  query's reads are its own task's: what a child task read is not a dep of the parent's
  open query. A body that fans out and joins asks its facts itself, or the join is an
  input.
- A key in flight in another task: the second asker COMPUTES it too. Queries are pure,
  so both answers are equal and the second settle is an early cutoff. It wastes work and
  is never wrong; waiting on the first asker instead is a later refinement that needs
  nothing here to change.
- Stamps stay shared and stay sound: a reader id names one frame, so a stamp another
  task left is simply "not mine" and the read is recorded again. A dep list may then
  hold a key twice. P1's packed lists must therefore tolerate a duplicate — they do
  today, since a stamp a nested frame clobbered already re-records.
- A revision that moves while a task waits is already handled: a frame settles as
  verified at the revision it BEGAN at (`began`).
- A late write from another task while a reader holds the old value this revision is
  refused today. At run time that is wrong for a driver that sets an input while a
  request is in flight; the write must be TAKEN (the revision moves; the in-flight
  frame settles stale and is re-verified at its next ask). This is the one semantic
  change §5 asks of the kernel and it lands with P4c, under its own tests.

**What the compiler-only steps assume meanwhile.** The compiler asks from one task per
process, so a per-process asker is exactly a per-task one for it. To keep run time out
of a corner:

1. P1 already splits the kernel's state in two — engine state and asker state — because
   that split is what stops the per-read copy. The asker half is one value from then on.
2. From P4a every reach for the ambient Db or the frame stack goes through `asker()`,
   defined in one file. Until P4c its body is a `once` cell; P4c changes that body and
   nothing else.
3. Until P4c the kernel refuses an out-of-order settle or abandon, naming both queries,
   so an interleave at run time is a loud trap and never a wrong dep list. P4c deletes
   that refusal's run-time reach by making the interleave legal.
4. P4c lands before any run-time consumer is told the engine is ready. P5 and P6 do not
   depend on it.

Not designed here: the evaluator runs interpreted tasks, so its arm for the slot keys
by the interpreted task, not the host's. That is the second landing's work.

## 6. Generation, seed and bridge cost

No step P0–P6 needs a bridge or a seed refresh by design: none adds syntax, a runtime
row, a node variant or a moved `@std/meta` shape, and derives run from source. Each is
still proven by `make bootstrap` from the committed seed, `seed-check`, and gen-2 ==
gen-3. P4c is the exception: a runtime row the compiler's own source declares is two
landings with a seed refresh between.

Watch points: P3 — the seed must resolve the new files in std-relation (std-relation
already imports `@std` packages with no manifest rows, so the resolver is in the seed).
P4a / P4b — the compiler's own source wears `@query` / `@input` in `doc_rows`,
`inputs`, `findings`, `answers`; rewritten in the same commit. P6 — a `Family` variant
removed: every exhaustive match loses an arm, source only.

The one thing that WOULD cost a bridge before P4c: `@query(digest: some_fn)`, if a fn
name is not a legal Declares-annotation argument (F2067). Probed first; the fallback is
a sibling fn by convention, with no language change.

## 7. Measurements each PR publishes

On a Sprite, both compilers over ONE pinned source snapshot, the cache moved aside,
three runs: cells · edges · read calls per family · bytes per edge · bytes per cell ·
`Kernel.newly_read` MB · cold, no-op and one-edit `check packages/cli` time and peak ·
instructions per recorded read (a kernel cell, a relation row).

| PR | budget |
|---|---|
| every PR | cold time and peak no worse than its base beyond run-to-run noise; the graph identical where behaviour is unchanged |
| P1 | `newly_read` < 60 MB (375 today) |
| P4a | a relation's recorded read ≤ 350 instructions (~938 today); c3 = once |
| P3, P4b, P5 | neutral |
| P6 | neutral; `Sig`'s cells and edges unchanged |

## 8. The three riskiest points

1. The ambient Db answering for the wrong workspace, silently. De-risk: the face check
   and the no-workspace refusal of §2; a two-live-workspaces interleaved test written
   before P4b and shown failing without the check.
2. Collapsing `Hooks` while Decl minting depends on owner frames, sweeps and the
   late-write law — an error is a stale or doubled Decl row and a gen-2 trap. De-risk:
   P4a keeps the named-owner API as it is; the proof is an `AVRA_DB_GRAPH` dump
   edge-for-edge identical before and after on the pinned snapshot, `AVRA_QTRACE` gen-1
   against gen-2 identical, `cache-attacks`, `turn-memory-attack`.
3. Packed deps and the hot-path rewrite breaking red-green only on warm edits (stamp
   restore under nesting, abandon, a late write, a cycle). De-risk: adversarial kernel
   tests for those four written first; the same graph diff; `warm_edit.sh`.

## 9. Questions, answered by team-lead

| # | question | answer |
|---|---|---|
| Q1 | does 01 enforce D4? | yes: P4a refuses an un-owned insert inside an open `@query` |
| Q2 | do relation accessors lose the Db seat in P4b? | yes |
| Q3 | who lands the instrument? | this lane, as P0 |
