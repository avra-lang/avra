# DB 01 — one engine: the design note

2026-10-06 · branch `db-engine` · worktree `../avra-db-engine` · ticket `avra-8sb5.57.170`
Plan: `docs/2026_10_06_COMPILER_DB.md` and its hand-off, on `origin/db-design`.
Base: `origin/main` @ `4294595`. Nothing here is built unless a line says so.

**Status.** Second draft, after the independent review (`REVIEW3.md`: GO WITH CHANGES for
P3–P6, NO-GO for P4c as first written) and two owner decisions (§5.1). P0 and P1 are
being verified. Order of work: P0 → P1 → P2, P3 → P4a1 … a4 one at a time → P4b → P5 →
P6. P4c is not on the compiler's path and is built only from §5 as rewritten here.

Labels: READ (I opened the line) · PROBED (I ran it) · MEASURED · PROPOSED (not built).

## 1. End state — files and types

1. **The engine's files live in `@std/relation`.** `kernel.av` (today's
   `query/kernel.av`), `answers.av` (today's `query/memo.av`: the typed `Relation<T>` =
   kernel + family + value table), `fixpoint.av`, `key_marks.av`, `table.av` (core's
   `Table` / `new_table` / `list_cell` / `map_cell`). std-avrac's `query/` and
   `core/table.av` are DELETED; their tests move. What the first draft left out (review
   §3):
   - `core/` then imports `@std/relation` for `Table` (16 non-test files use it, 24 import
     `query.`). The layering line becomes `@std/relation → core → grammar → features →
     compiler`.
   - **The engine reads no environment and needs no `@std/io`.** `AVRA_QTRACE` and
     `AVRA_DB_GRAPH` are read by the compiler's driver, which hands the kernel a trace
     sink and a graph sink (two `fn(string) -> void` cells, quiet by default — the shape
     the audit's `sink` already has). `qtrace` (a runtime row behind a core fn) stays in
     core, behind that sink. std-relation's manifest gains no row.
   - the paths `make vocab`, `make cited` and CLAUDE.md name move in the same commit.
2. **`Db`** (std-relation `db.av`) = `@identity { id, kernel, closed, closers,
   sweepers, runs, names, durable }`. Every Db HAS an engine — its own, or one it is
   given (`db_over(kernel, …)`; P4a1's seam, gone at P4a3) — and its own is made on the
   first reach (`db.engine()`): a Db that only ever holds rows allocates no kernel.
   MEASURED why: with a kernel per `new_db()`, std-avrac's suite peaked 227 MB over P3
   (4,579 against 4,352 MB), because the compiler builds throwaway Dbs by the thousand
   and the suite keeps its workspaces; lazily, with a hashed family carrying its own
   seen-state, it is 4,381 MB. WRITTEN in P4a1 (branch
   `db-04a1-one-kernel`), what is left of the nine closures is three small modes and
   one cell, each with the step that removes it: `Verifying` (by hash, or by the
   revision a write stamped — the compiler's two hook records differed exactly so; one
   verb at P4a4), `framed` (a write outside every `@query` belongs to the open kernel
   query — `failures_db`'s shape; gone with frames at P4a2/a3), `Late` (below; stays),
   and `hears`, who is told a refusal instead of the program ending (tests assert a
   law's words through it). Deleted: `Hooks` (all nine),
   `quiet_hooks`, `hooked_db`, `armed` / `quieted` / `rearmed` / `registrars`, `Memo<V>`,
   `Kept`, `InputSlot`, `writes`, `running`, `owner_frames`, `last_query` /
   `last_frame`. KEPT until DB 07a, unchanged in meaning: named owners and their sweep
   (`owner_named`, `opened_run`, `closed_run`, `put_owned`, `runs`, `sweepers`) —
   `decls_mint.av` mints Decl rows through them. `owner_named` interns through `names`
   (the first draft listed its map, `cells`, as deleted).
3. **The compiler: a Workspace has ONE std-relation Db.** Today it has three plus a bare
   kernel: `decl_rows` (armed to the kernel), `failures_db` (hooked to it), `refs_db` (a
   plain `new_db()`, nothing recorded — READ `decls.av:843`), and compiler `Db.kernel`.
   `compiler/db.av`'s `Db` keeps its `DbRow` store until DB 06 / 12 but holds that one
   Db. `relation_hooks`, `kernel_hooks`, and the two copies of the hash→revision
   conversion (`workspace.av` `revision_of_hash`, decls' `move_stamps` — string-keyed
   maps per cell) become ONE kernel verb over dense int rows.

## 2. How a query finds its engine (D3)

**One law, held at one door: inside any open frame, the ambient Db is that frame's Db.**

- `current()` answers the ambient Db; `within_db(d) { … }` enters one and restores the
  previous under `defer` (a free fn: generic methods are F2031). The ambient starts as
  the process's default Db.
- **`kernel.begin` refuses a frame opened while the ambient Db is not the kernel's own
  Db**, naming the query and both Dbs. One compare per frame, none per read. Every ask
  made BY HANDLE (`self.db.ask(k)` — the 31 unconverted families, READ
  `workspace.av:1683-1707`) enters `within_db(self.rel)`. So the law holds for converted
  and unconverted families alike, and for every stored closure (verifiers, closers,
  sweepers, `Analysis`'s closures, the declaration table's hooks): each reaches the
  kernel through `begin`. This REPLACES the first draft's per-face check, which an
  unconverted body calling `sig_of(d)` directly walked past.
- **THE FRAME LAW: a frame opened on kernel K only ever records K's keys.** The open
  stack, the cycle test and the stamps are per kernel (they are today, and P1 keeps them
  so), so a key of Db B can never sit in a dep list of Db A, and two Dbs' unrelated
  queries can never read as a cycle — by construction, not by comparing a Db id on each
  frame (agreed with team-lead in place of the review's item 2). What is per ASKER is
  only which Db is ambient (and, at P4c, which task's frames: §5). Its tests, in P4a1:
  a throwaway Db built and read inside an open query, once in the shape of
  `features/code.av:1078` and once in that of `features/decls.av:767` — the outer
  frame's dep list holds only the outer kernel's keys, the inner Db's cells hold only
  the inner's, and the same key number open on both is no cycle.
- **A nested Db inside an open frame.** The compiler builds throwaway Dbs inside open
  queries today (READ `features/code.av:1078`, `features/decls.av:767`). The rule: from
  inside an open frame, `within_db(d)` is allowed only for a Db BORN inside that frame
  (a Db remembers the reader it was made under); any other is refused by name. Reads on
  the inner Db are recorded on the inner kernel alone. The inner Db is the outer query's
  local scratch: built from the outer's own recorded reads, dead with it.
- **The query wrapper abandons its frame under `errdefer`**, so a body left by `fail`,
  `?`, a trap that unwinds or a cancel leaves no frame behind. Without it one failed
  body kills the engine for the process. BUILT in P4a1 as a `defer` over a settled flag;
  it drops the Db's own frame (`Db.left`) as well as the kernel's. A DEADLINE, NOT A
  GUARANTEE (CLAUDE.md): the branch is UNREACHABLE today — nothing leaves a query body
  early but a trap, and a trap ends the process — so it has no test, and a green one
  would prove an untaken branch. It becomes reachable the day a body can fail or be
  cancelled: P4c. TEST OWED THERE, before P4c's code: a body left by `fail` and one left
  by a cancel each leave the kernel's open stack and `db.running` as they found them,
  and the next row write is stamped to no run.
- **A converted compiler query finds its Workspace** as `workspaces()[current().id]`.
  The slot is cleared by that Db's CLOSERS — every Db, not only a one-shot one (a
  process-wide list of workspaces is the recorded 922 MB leak; CLAUDE.md's cycle law).
  Asks after `disarmed` are legitimate ("an Analysis asked after is remade over the
  memoized parts"), so the slot outlives `disarmed` and dies at close; the one-shot
  suites prove it before P6. The looked-up workspace is never bound to `mut` (F2106:
  a copy forks it). The default Db has no workspace: a compiler query asked there is a
  named refusal. `Syntax` and `Names` (P6) need no registry at all.
- The evaluator: `once` answers are per machine (READ `backend/interp.av:107`), so an
  evaluated program has its own ambient and default Db and never sees the host's.
- Tests that build many Dbs: ids are dense and never reused; per-query answer slots are
  indexed by Db id and released by the Db's closers, as `Stores<R>` does today. The list
  only grows; `test packages/std-avrac` time and peak are published per PR (§7).

## 3. How each thing becomes a kernel cell

- **`@query fn q(k: K) -> V`** generates `once fn q_answers() -> Answers<K, V>` (slots by
  Db id, each a `Relation<V>` plus its keys) and a wrapper = today's `Relation.start` /
  `finish_lazy`. The family registers on first ask by stable NAME (module path + fn
  name); ids then follow ask order, so every dump (`AVRA_DB_GRAPH`, `AVRA_QTRACE`)
  prints the name, never the id. Its verifier re-asks `q` for that arg.
- **Keys.** Any key is interned per family by its ENCODED BYTES (`stable.av`'s writer,
  the octets spelled out), not by a hash: a hash collision hands one key another key's
  answer, and this work promotes that from two test paths to every running program
  (`avra-8sb5.46`). WRITTEN in P4a1. A `@dense` key (std-meta's existing mark; `DeclId`,
  `FileId`) becomes its own int at P6, where its first user is — a `@dense` argument is
  refused by `@query` today.
- **Digests.** An answer with a stable encoding is digested by it, lazily. An answer
  without one (`DeclSig`, `TypeFacts`) implements a one-method `Digest` trait that the
  wrapper calls — built at P6 with its first user; until then `@query` refuses such an
  answer, as it does today. Not an annotation argument — PROBED by the review: `@tagged(dg)` with a
  fn is "must name a literal", `@tagged(digest: dg)` is "an annotation's arguments fill
  its seats" — and not a sibling fn found by name, which is a name match.
- **Re-entry.** A `@query` that reaches itself is a named refusal that spells the cycle.
  A query that MEANS to be re-entered declares it and answers `V?`, absent on re-entry
  (PROPOSED spelling: a second mark, `@reentrant`, beside `@query`; probed before P6's
  second conversion). Nine families use `start_recursive` today; each takes this form or
  stays a family until its recursion is removed.
- **`@input fn i(k) -> V`**: the same `Answers`, through today's `Relation.input`;
  `set_i` is `kernel.set_input`. It records its read. `@input` and `Memo.input` are one
  definition.
- **A relation's row set and index buckets**: the same cells as today (0 = the set,
  b + 1 = bucket b), registered straight on `db.kernel`; a read is `kernel.record_at`.
  The late-write law is unchanged for the compiler (§5 scopes the run-time change).
- **A late write on a plain Db is an input arriving** (`Late.Taken`; PROBED in P4a1's
  scratch suite). A Db over its own kernel has a live revision, so the compiler's law —
  refuse a write to a cell a reader holds this revision — would refuse a program's
  ordinary insert. There a write to a cell ANY reader ever read moves the revision,
  and every reader is verified again against the cell's hash. "Ever", not "this
  revision": a reader re-verified green by the dep walk leaves no mark on the cell, so
  a mark-this-revision test would miss it. The compiler's Dbs keep `Late.Refused`.
- **NO VERIFIER HOLDS ITS OWN KERNEL.** The hash→revision conversion as a closure
  captures the kernel it is registered in — a cycle counting never frees (CLAUDE.md's
  cycle law). One per workspace was survivable while `disarm` broke it; one per Db is
  not. So the kernel has three kinds of family: `By(verify)` (its owner's fn),
  `Input` (changed when last set to a new value) and `Hash(live, seen, moved)` (the
  kernel compares the live hash with what it saw; `live` holds no kernel). PROBED:
  20,000 throwaway Dbs, each closed, leave 1.6 MB alive, the same as on P3. This is
  P4a4's "one verb", pulled forward for the hashed half; `ByMove`'s string-keyed maps
  remain for P4a4.
- **A Db that asked a query lives until it is closed.** A `@query`'s and an `@input`'s
  answers are kept, by Db id, where the query is declared, so they hold the Db's
  kernel, and a query's way to be asked again holds the Db. `close` (and being given
  another kernel) lets them go. The compiler's throwaway findings Dbs, which read an
  `@input`, are closed under `defer`.
- **An answer READ BACK from the owner (`Durable`) brings no reads with it**, so it
  stands only until the next write to its Db: it depends on one input cell every write
  moves — a row write or an input set (`Db.unsettles_restored`). And a run is KEPT only
  when it wrote no rows and read nothing but its own Db's rows (`Db.rows_alone`): a
  record that read an input or another query would be restored blind by the next
  process (review 5, F1 — PROBED wrong answer `2 2 2`, now `2 2 10` in
  `tests/durable`). A STOPGAP, PENDING DB 06, which replaces `Durable` with records
  that carry their reads: `avra-8sb5.57.203` names every piece that goes then.
- **D4.** An un-owned row insert inside an open `@query` BODY is REFUSED with a named
  voice. `Frame`, `began`, `ended`, `framed`, `Rel.prior` and the self-read law are
  deleted with it. Compiler families keep named owners until DB 07a. BUILT in P4a2 as:
  - ROWS ARE A NAMED OWNER'S OR NO ONE'S. `db.opened_run(owner)` … `db.closed_run(owner)`
    brackets a run; every insert inside it with no other owner named is stamped to it,
    and its close sweeps what it did not write again. The open runs are the Db's one
    stack; a `@query`'s wrapper opens none.
  - A RELATION AN OPEN RUN HAS WRITTEN IS READ BY NO ONE UNTIL THE RUN CLOSES — refused
    naming the relation and the owner. That is the self-read law's read-after-write
    half; its write-after-read half is the late-write law, unchanged. Refusal, not "the
    last closed run": the second needs every write buffered until close.
  - NARROWER THAN "any open kernel query", and L6's row in the law doc says so: the
    refusal is for a `@query` body. COUNTED (probe on a2, rows through `put_in` with no
    run open while a kernel query is open): cold `check packages/cli` — `File` 287,
    `Module` 41; the std-avrac suite's own process — `File` 846, `Module` 436 (and one
    test relation). Two relations, both in the declaration table's Db.
    `avra-8sb5.57.206` gives them owners and widens the refusal to any open kernel query.
  - FROM THE BRACKET TO L6's "RETURN ROWS", three steps. TODAY a row-writing query
    writes four lines — `owner_named`, `opened_run`, its inserts, `closed_run` — and a
    body that leaves early leaves the run open. NEXT a block verb closes it under
    `defer` (`db.run_of("icons") { … }`); it needs a generic METHOD, which is not landed
    (`avra-8sb5.11.368`). LAST (DB 07a) the query RETURNS its rows — `@query fn icons(dir)
    -> List<Icon>` — and the wrapper is the only writer: the owner is the call's own
    cell, the run is the wrapper's, the rows are the answer, and the body holds no
    insert at all. The bracket is what the wrapper will call; no body keeps it.
  - THE ONE GRAPH DELTA against P4a1: one read call fewer in a cold `check cli`, on
    family 34 — the `Decl` relation — its whole-relation cell (cell 0), read twice by
    one open kernel query. The repeat is now skipped at the cell's mark for every Db;
    before, only a framed Db or a `@query` frame had that path. Cells and edges are the
    same bytes.
  - `failures.av` is TWO runs: `error sites` closes before `raised` reads it. It fixes
    `avra-8sb5.57.204`: a recompute replaces its rows (`tests/rerun_swept`: 3 → 2).
  - A read mark is now (revision, reader): each open kernel query is its own reader, so
    a nested query's read never stands for its caller's, with no frame to say so.
- **`@family`**: `Workspace.built`'s loop calls the same `kernel.family(name, verify)`;
  `Family` and its ordinals stay until each family converts. The two unchecked strings
  (`"DeclId"`, `"DeclSig"`) leave the marker in P5.

### 3.1 The first conversion is `Syntax`, not `Sig`

`Syntax` is `DeclId → int`: a `@dense` key, an encodable answer, no recursion, no held
branch, no side table, three non-test uses. It proves registration by name, the wrapper,
the digest, `families-left` = 31 and the measurement harness with nothing else moving.

### 3.2 `Sig` second — what its conversion really is

READ `workspace.av:1682-1708`. `Sig`'s body is not a function of its key alone today, so
it converts only after each row below is settled. "80 lines → 3" does not describe it.

| today | after | DELETED or MOVED |
|---|---|---|
| `key(Family.Sig, …)`, `db.ask`, `db.begin`, `db.settle` | the generated wrapper | deleted |
| `sig_hash` | `impl Digest for Signed` | moved |
| `Family.Sig` and its arms (`refetched`, `family_word`, `reads_rows_whole`, `dep_audit.av:92`) | — | deleted. `Family` is a `collect enum … dense`, so ranks 7–31 renumber in the same commit (legal once P5 retires `families.order`) |
| `decls.sigs`, a table `declare_one` writes AS IT RUNS and callers read back | the answer table inside `Answers` | moved, and not for free: signing must RETURN its `DeclSig` instead of writing a shared row. OPEN: whether a re-entrant ask today reads a partly written row; read `declare_*` before P6 and say so here |
| re-entry: "a sig reached from inside its own computation is simply not there yet" | `@reentrant`, answering `Signed?` | moved into the declared form (§3) |
| `sig_voices.keep(d.index, …)` | a field of `Signed` | moved |
| "the language's own declarations were signed at admission" (`x.kind is .Builtin`) | the body answers the admitted row | moved: a table the driver fills, read inside a query — an input in all but name until DB 04 |
| the held branch (`held_sig_dep`, `file_ensured`, `fill_ensured`) | inside the body | moved: a store read with a hand-recorded dependency, exactly what L1 / L3 exist to delete. It dies at DB 07e and is not "gone" before then |
| 106 non-test `.sig(` call sites; `features/` reaches signatures through the declaration table's hook because features may not import `compiler/` | unchanged spelling; the hook's target becomes `sig_of` | moved: the hook stays until by-name loading (DB 07d). A query declared low and defined high has no spelling today (sugar ask, recorded at P6) |

Also recorded against DB 06: signing has an effect outside its answer — the type
registry's flat-record mark ("ITS MARK IS MADE AT ITS DECLARATION"). In one process the
body runs once, so P6 is safe; the day an answer is restored instead of computed, the
mark is not made.

## 4. PR sequence

Each off `origin/main`, green alone, reported before the next.

| PR | what | proof beyond the standing list (§7) |
|---|---|---|
| P0 | the instrument: `tools/db_measure` + `AVRA_DB_GRAPH` from `origin/db-measure`, plus `ab.sh` (two compilers over one pinned source) | it prints M1's table |
| P1 | edges as packed ints; the kernel's state split into cells, engine half and asker half; the repeat-read fast path. Inside today's kernel | the graph IDENTICAL, byte for byte |
| P2 | `read_cost.sh` over db-measure's readbench: instructions per recorded read, the ambient lookup and the Db check included once they exist | the number, for a kernel cell and a relation row |
| P3 | the move (§1 item 1): files only | the graph identical |
| P4a1 | a Db holds a kernel, its own or one given; `Hooks` deleted; `@query` / `@input` are cells; keys interned by bytes; a call left before it settles abandons its frame. The compiler's three Dbs are GIVEN the workspace's kernel, so it records what it records today. BUILT and verified (branch `db-04a1-one-kernel`) | MEASURED: the graph byte-identical to P3's, kernel ids included; c3's assertion on a plain Db (`tests/unrelated_writes`) and under an owner's kernel (`tests/given_kernel_test.av`) — in std-relation, where the engine now is, not `compiler/tests` |
| P4a2 | D4: the insert refusal; `Frame` / `began` / `ended` and the self-read law deleted; std-relation's own program tests rewritten (`query/`, `owner_frames/` → `owner_runs/`, `named_owner/`, `swept_heard/`, `quiet_self_read/`, `unrelated_writes/`, `durable/`), `rerun_swept/` added. BUILT (branch `db-04a2-owned-runs`) | each rewritten test names the law it now proves; a mid-run read or an un-owned query write anywhere in the compiler would trap, so the whole std-avrac suite and a cold `check cli` passing IS the count: 0 |
| P4a3 | three Dbs → one, verified BY MOVE throughout (ruling: no per-relation verifier flag; the hash's cutoff for `ErrorSite` / `Raised` is a deadline, `avra-8sb5.57.207`, paid for every relation at the saved-answer step); `Ref` rows a named owner's run, their reads recorded while the Db has its kernel (after a one-shot workspace disarms they are unheard, as today: `avra-8sb5.57.208`); `db_over` deleted; the Db's kind is two spellings, `new_db()` and `given_to(kernel)`, the second refused by name once a query has read the Db (`avra-8sb5.57.200`) | the graph CHANGES: the expected delta is stated before the run (the reference relation's cells and their readers' edges appear; nothing else moves) and compared after |
| P4a4 | `revision_of_hash` + `move_stamps` → one kernel verb over dense rows. ABSORBED: the hashed half went into P4a1 and the by-move half into P4a3 (a write's stamp is two list indexes, no key spelled) — P4a3 could not hold the warm line without it. No step is left under this name | the graph identical |
| P4b | the D3 spelling: `@query`, `@input` and the generated relation accessors lose the Db seat (27 non-test call sites, 215 in tests); the ambient Db, `within_db` (restoring under `defer`) and THE `begin` LAW arrive here together — while the Db is still an argument (P4a1–a4) there is no ambient to disagree with it, and three Dbs share the workspace's kernel until P4a3, so "the kernel's own Db" has no meaning before then | the two-live-workspaces interleaved test, with a stored closure in it, failing without the `begin` law |
| P5 | families register by name; refusals speak; `make families-left` = 32; `make families` and `families.order` retired on the hand-off's two conditions | — |
| P6 | `Syntax` converted (families-left = 31); then `Sig`, once §3.2 has no OPEN row | `Syntax`'s cells and edges unchanged |
| P4c | the per-task asker (§5): two landings and a seed refresh. Its first consumer is `avra-8sb5.57.187` | §5.3 |

The plan's 01a → 01b: a Db constructed over a given kernel IS the seam, for P4a1–a2;
P4a3 removes it.

## 5. Tasks — what the law is at run time

The owner put the engine in `@std/relation` so RUNNING programs get it. The first such
program is a server with a task per connection whose query bodies wait (a database
read). "A query body never yields" cannot be the run-time law.

### 5.1 The owner's two decisions (2026-10-06) — DECIDED

| # | question | decided |
|---|---|---|
| O1 | an input changes while a request's query is running: what does the request get? | **A.** The query runs again, so every answer is true at one moment. The retries are capped; at the cap the ask answers a NAMED error, never a mixed answer |
| O2 | may a query's body start tasks? | **A for now.** A query body that starts a task is REFUSED by name. **B is ticketed, `avra-8sb5.57.187`**: structured children (`all`, `parallel`) whose reads count as the query's; `race` and detached spawns stay refused |

"Why can't we do B now? Don't we have all the parallelization needed?" The
parallelism is there. What is missing is one fact the engine cannot learn today: **inside
a child task, which open query is this read for?** The engine finds the open query
through its asker, and the runtime has no per-task value to hang an asker on (PROBED:
no task-local in `runtime/`). That per-task slot is P4c. So B is P4c's FIRST consumer and
lands right behind it: a structured child inherits its spawner's open frame as the place
its reads go, and the join is where they are folded in.

### 5.2 What is per task, and what is shared

| state | whose |
|---|---|
| which Db is ambient | the task's |
| the open-frame stack of each kernel: `open`, `pending`, `restore`, `began`, `readers`, `reader`, `last` (P1's `Asker`) | the task's, per kernel |
| cells, verifiers, the revision, the last-reader stamps | the engine's, shared |

The task's value is reached through ONE accessor. It is fetched once per frame and
carried through the wrapper; a bare relation read pays one call. Its cost is in
`read_cost.sh`'s number.

### 5.3 The rules P4c is built to (each a test before the code)

1. **The slot.** One managed pointer per task behind a runtime row pair, released when
   the task ends. The row lives OUTSIDE the scheduler's object with a main-task fallback,
   so a program that never spawns still links no scheduler; the wasm runtime carries it.
   Two landings: the row `Unhosted` with its C body, `avra_rt.h` and `make externs`; then
   the declaration, the evaluator's arm and the callers.
2. **The evaluator traps by name** on a query asked from an interpreted task other than
   the first, until its arm lands — never a silent eval ≠ native.
3. **A body that starts a task is refused by name** (O2 = A): a child's first touch of the
   engine finds frames that are its spawner's and says so. Nothing ships in which a
   child's reads are dropped. Before P4c this cannot be detected, so no run-time consumer
   is told the engine is ready before P4c.
4. **A key in flight in another task is computed again.** Queries are pure, so the
   answers are equal — except an INPUT's first load, which is single-flight per key: the
   second asker waits for the first load or reuses it. The count of duplicate
   computations is published (0 for the compiler). Waiting on another task's key instead
   is NOT free to add later: a cycle can then span tasks, which a per-task cycle test
   cannot see; it needs a cross-task wait graph, and is not designed here.
5. **A settle whose `began` is older than the cell's `verified_at` is dropped.** The
   value still returns to its caller; the cell keeps the newer answer.
6. **O1 = A.** When the outermost ask of a task settles and an input one of its frames
   read has moved since it began, it runs again. After the cap (PROPOSED: 8) the ask
   answers the named failure `Unsettled { query, key, attempts }`. OPEN for P4c's first
   design round: how a call site whose type is plain `V` hears it — a trap by that name,
   or a last attempt that holds writers off until it settles.
7. **The late-write law changes only for a write from OUTSIDE the reader's task.** A
   write by the task that holds the reader stays refused — the compiler's `collect` /
   mint ordering rests on that refusal, and §3 keeps it. A write from a driver or another
   task is an input arriving: taken, and rule 6 decides what the reader does.
8. **Duplicates in a frame's dep list are bounded.** Stamps stay shared, so two tasks
   reading the same keys in turn clobber each other's stamp and each read re-records. A
   frame's list is deduplicated at settle (the edges are ints: sort and compact).
9. A cancelled task: the wrapper's `errdefer` (§2, already in P4a1) abandons its frames;
   its value is dropped with it.

### 5.4 What the compiler-only steps assume meanwhile

The compiler asks from one task per process, so a per-process asker is a per-task one for
it. P1 already splits kernel state into the engine's half and the asker's. From P4a1 the
`begin` law, the `errdefer` and bytes-interned keys are in. Until P4c the kernel refuses
an out-of-order settle or abandon by name, so an interleave is a loud trap and never a
wrong dep list. P5 and P6 do not depend on P4c.

## 6. Generation, seed and bridge cost

No step P0–P6 needs a bridge or a seed refresh by design: none adds syntax, a runtime
row, a node variant or a moved `@std/meta` shape, and derives run from source. Each is
still proven by `make bootstrap` from the committed seed, `seed-check`, and gen-2 ==
gen-3. P4c is the exception (§5.3 rule 1).

Watch points: P3 — the seed must resolve the new files in std-relation (std-relation
already imports `@std` packages with no manifest rows, so the resolver is in the seed).
P4a1 / P4b — the compiler's own source wears `@query` / `@input` in `doc_rows`,
`inputs`, `findings`, `answers`; rewritten in the same commit. P6 — a `Family` variant
removed and the ranks after it renumbered: source only. `@reentrant`, if it needs more
than a mark the derive reads, is probed before it is relied on.

### 4.0 P4a3 as built (branch `db-04a3-one-db`, stacked on P4a2)

- ONE RELATION Db in the compiler, `Decls.rows_db`: declarations, files and modules,
  references, error sites and raised sets. `failures_db`, `refs_db`, `settle_refs`,
  `db_over`, `Verifying` and `Late` are gone. A Db's kind is one private two-variant
  `Home` — `Own` (its own kernel: verified by hash, a late write taken) or `Given`
  (an owner's: verified by move, a late write refused) — reached by two spellings,
  `new_db()` and `db.given_to(kernel)`; `given_to` is refused by name once a query has
  read the Db (`tests/given_kernel_test.av`). `avra-8sb5.57.200` closes with it.
- REFERENCES IS ONE NAMED RUN, AND WHAT IT ASKS STANDS FIRST: every file's resolved
  names and folded facts, and every module a held file's kept lines name, are asked
  BEFORE the run opens — inside it nothing is asked that could mint a row, so a row
  written there is a reference and nothing else joins the run.
- THE GRAPH DELTA, measured on a cold `check packages/cli` (which computes References):
  cells 71,480 → 71,480; families 70 → 71 (`Ref`, family 35); edges +9,981, each from
  a `Lowered` cell to the `Ref` bucket `consumes` reads; the References cell holds the
  same 13,284 reads in another order (the stand-first loop); read calls +462 on
  `Resolved` and on `Folded`, +9,981 on `Ref`. `check --baseline` of std-text: 48 `Ref`
  edges; `build tools/db_measure/readbench`: 473.
- WHAT AN OWNED ROW COSTS, and what was done so the warm line held. The 93,608 `Ref`
  rows a warm edit writes were un-owned rows in a kernel-less Db; owned rows in the
  compiler's Db first cost +1.46 % retains on the warm check. Paid down by count:
  stamps and per-owner id lists indexed by number, never by a spelled key; a row's
  stamp one unboxed word; a run's stamp and its last relation's answer kept on the Db;
  the close of a run walks no list stamped in that run; a relation no query has read
  owes no late-write walk and no stamp (asked of the kernel's own record, nothing kept
  on the read path). `read_cost.budget` holds the result: a written row un-owned
  20 retains / 104 list reads / 58 list writes, owned 21 / 110 / 59.
  COUNTED AGAINST P4a2 (census, same source): cold `check cli` is better on all four —
  retains 1,336.6 M → 1,335.3 M, releases 1,755.8 M → 1,754.0 M, list reads 6,502.8 M →
  6,498.3 M, list writes 1,746.5 M → 1,745.7 M. The one-edit warm check: retains
  102.07 M → 102.26 M (+0.19 %), releases +0.03 %, list reads 459.2 M → 460.3 M
  (+0.24 %), list writes 247.98 M → 247.49 M (−0.20 %). THE RESIDUE IS THE PRICE OF AN
  OWNER: about two retains and twelve list reads a `Ref` row, 93,608 rows a warm edit.
  Wall time cannot see it (±5 % on the Sprite). What removes it is not writing those
  rows on a warm edit at all — a held file's references read from its record on
  demand — which is the saved-answer step, not this one.
- AN OPEN RUN'S WRITES ARE KEPT BY THE RELATION'S SEAT IN ITS Db (its number among the
  relations reached), never by its kernel family: with no kernel every relation's
  family is −1, and a run that wrote one relation kept every reader out. Found by
  P4a3's suite; fixed in P4a2 as well (`tests/given_kernel_test.av`, failing without).
- DEADLINES it leaves, each ticketed: the hash's cutoff for `ErrorSite` / `Raised`
  (`avra-8sb5.57.207`); reads unheard after a one-shot workspace disarms
  (`avra-8sb5.57.208`).

### 4.1 Tickets P4a1's review left (review 5), each owed outside P4a1

| ticket | what | where it is paid |
|---|---|---|
| `avra-8sb5.57.197` | a plain Db never clears a read mark and never evicts | the run-time work, before any server relies on `@std/relation` |
| `avra-8sb5.57.198` | a Db that asked a `@query` lives until `close()` — a loop making Dbs leaks | P4b (the Db leaves the wrapper's closure with its seat) |
| `avra-8sb5.57.199` | the durable record named by the args HASH, the cell by bytes | DB 06 |
| `avra-8sb5.57.200` | named Db constructors, the three flags private | P4a3 |
| `avra-8sb5.57.201` | refuse a write while the reader that marked the cell is still open | after P4a2 |
| `avra-8sb5.57.202` | a `@query` ask re-encodes its arguments on every hit — the int / `@dense` fast path | P6, before its first conversion |
| `avra-8sb5.57.203` | the durable stopgap (`rows_alone`, `Db.restored`) | DB 06 |

`avra-8sb5.57.204` — rows a kernel query writes into a framed Db are never swept (a
rerun doubles them; `ErrorSite` is written so) — is fixed by P4a2's named owner.

WHAT A KEPT ANSWER CANNOT SEE (review 8, pinned in `tests/durable` as today's
behaviour, inherited by DB 06 as attacks, cited on `avra-8sb5.57.203`): a read of
ANOTHER Db's rows is recorded in that Db's kernel, so the asked Db's dep list is empty
and the answer is kept and read back stale (`1`, where `2` is right); and an answer
over this Db's own rows is read back by a process whose Db holds other rows before it
asks — the owner's key alone decides.

A float argument or answer is REFUSED by `@query` (`query_arg` / `query_answer`: no
stable encoding); a record and a list of records key a call by value
(`tests/query_cells`). A payload enum is refused by the codec today.

## 7. What each PR is verified by and publishes

Standing list: `make bootstrap` from the seed, `seed-check`, gen-2 and gen-3, the whole
`sh tools/work test` selection, `make cache-attacks`, `turn-memory-attack`, the keepers,
idioms per touched package, `fmt --check`.

Published, from `tools/db_measure/ab.sh` on a Sprite — both compilers over ONE pinned
source, every store moved aside, three rounds: cells · edges · read calls per family ·
bytes per edge · bytes per cell · `Kernel.newly_read` MB · cold `check packages/cli`
in INSTRUCTIONS, wall time and peak · no-op and one-edit time · instructions per recorded
read (a kernel cell, a relation row) · bytes per `new_db()` · `test packages/std-avrac`
time and peak · duplicate computations. PER READ MEANS `tools/db_measure/read_cost.sh`
(P2): (count at 2N − count at N) / N on the census runtime — retains, releases, list
reads and list writes, the same on every machine — with instructions printed beside
them as the measuring machine's own. A whole-process figure divided by one pass's reads
is not a per-read figure (the "3,563 → 3,432" P4a1 first published was that).

| PR | budget |
|---|---|
| every PR | cold instructions and peak no worse than its base; the graph as §4 says |
| P1 | `newly_read` < 60 MB (375 today) |
| P4a1 | a relation's recorded read ≤ 350 instructions (~938 today), the ambient and Db checks included; c3 = once. NEITHER MET NOR MISSED YET: the "3,563 → 3,432" P4a1 first published was the readbench's WHOLE PROCESS (fill, list pass and all four read passes) divided by ONE pass's 1,000,000 reads — not a per-read figure. The per-read quantity is P2's `read_cost.sh` (N against 2N, so setup cancels); readbench's own figure for a recorded dense-id read is ~100 ns on the Mac. A `@query` asked again costs 286 ns by an int and 953 ns by a 25-character text (`avra-8sb5.57.202`) |
| P3, P4a4, P4b, P5 | neutral |
| P6 | neutral; the converted family's cells and edges unchanged. ENTRY CONDITION (`avra-8sb5.57.202`): a dense-keyed `@query` hit does NO encoding and NO list write, with its row in `tools/db_measure/read_cost.budget` at or under a recorded dense read. Today a hit costs 16 list writes and 295 ns by an int (82 and 978 ns by a 25-character text) against 70 ns for a recorded dense read; the 37.2 M read calls M1 counted on a cold `check cli` would cost ~11 s at that price. No family converts before the row is in the budget |

## 8. The three riskiest points

1. The ambient Db answering for the wrong workspace, silently. De-risk: the `begin` law
   of §2, proved by a test with two live workspaces, interleaved asks and a stored
   closure, shown failing without it.
2. Collapsing `Hooks` while Decl minting depends on named owners, sweeps and the
   late-write law — an error is a stale or doubled Decl row and a gen-2 trap. De-risk:
   P4a1 keeps the named-owner API as it is and the compiler's three Dbs apart; the proof
   is the graph byte-identical, `AVRA_QTRACE` gen-1 against gen-2 identical,
   `cache-attacks`, `turn-memory-attack`. Only P4a3 moves the graph, by a delta stated
   first.
3. Packed deps and the hot-path rewrite breaking red-green only on warm edits. De-risk:
   the adversarial kernel tests (stamp restore under nesting, abandon, a write while
   open, a cycle, the last read across a begin and a close), each killed by a mutant;
   the graph diff; `warm_edit.sh`.

## 9. Questions, answered

| # | question | answer | by |
|---|---|---|---|
| Q1 | does 01 enforce D4? | yes, in P4a2 | team-lead |
| Q2 | do relation accessors lose the Db seat? | yes, in P4b | team-lead |
| Q3 | who lands the instrument? | this lane, as P0 | team-lead |
| O1 | an input moves mid-query | the query runs again; capped; a named error at the cap | owner |
| O2 | may a query body start tasks? | refused for now; structured children are `.57.187`, P4c's first consumer | owner |

P1's negative-arg refusal has no trap test of its own in P1. A program that proves a
trap runs as a child, and one that imports `@std.avrac.query` has to load the compiler's
package: PROBED, the child was stopped at the suite's 30 s and std-avrac's suite ended
there. The program lives in `@std/relation`'s engine tests from P3, where the kernel
loads alone. In P1 the refusal rests on the native-cli count (0 negative args in
37,541,053 reads) and on the old kernel already trapping.

A correction to the review, for the record: P1's "a negative arg refused at the record
site" is not a behaviour change. PROBED on the old kernel, the same program
(`query/tests/negative_arg`) already traps — `index -1 is out of bounds (length 0)`,
from the stamp row's write. P1 changes the words of that trap, not whether it happens.
