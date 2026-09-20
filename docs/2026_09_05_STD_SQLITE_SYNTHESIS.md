# `@std/sqlite` — THE MERGED DESIGN

> **What this is.** One design, made from three. It takes the
> DECLARATIVE face's spine (a query is a value, the ceremony lives in the
> library, the call site is a comprehension), the TYPED design's row
> architecture (one reading contract, two lifetimes) and the RESOURCE
> design's two instruments (the guarantee ledger, and an error
> materialised at the failure site). Where the three judges disagreed,
> the disagreement was a false dichotomy seven times and a real trade
> twice; §0.2 names each collapse and §19 answers every worst-idea
> criticism, by fixing it or by arguing it wrong.
>
> **Its bar.** Every Avra fragment either compiles against this
> worktree's compiler as it stands on 2026-09-05, or carries `[ASK n]`
> and is listed in §20 with its wanting site. A fragment contradicted by
> `RESEARCH_probe_log.md` is a defect in this document, not a language
> ask. Fragments assume the campaign's three prerequisites — `float`,
> `bytes`, `mut` seats on externs — which ARE the campaign; §20 is what
> remains after they land. Claims are marked HIGH / MEDIUM / LOW and the
> ledger at the tail says how each was verified.
>
> **Its sources.** The ten research reports beside this file, the three
> designs, the three judge verdicts, and this worktree's own source,
> read. Where a law is cited as `LAW X1`, `LAW S12`, `B-3`, it is a
> research report's and that report carries the SQLite documentation
> quote.

---

## 0. THE SPINE, AND THE SEVEN COLLAPSES

### 0.1 The one line, and the one loop

```avra
use @std.sqlite.{open, sql, Db, Row, Cursor, Cells, SqlError}

type Note = { id: int, body: string }

/// One row of `select id, body from notes` — from a LIVE cursor or a
/// COPIED row, because both sign the same contract.
fn note_of<C: Cells>(c: C) -> Result<Note, SqlError> {
    Note { id: c.int(0)?, body: c.text(1)? }
}

/// Every note, newest first. Materialised, and the verb says so.
fn recent(db: Db, limit: int) -> Result<List<Note>, SqlError> {
    [note_of(r)? for r in db.all(sql("select id, body from notes order by id desc limit ?").args([.Int(limit)]))?]
}

/// The same rows, none of them materialised. One statement, N steps,
/// zero row allocations, THE SAME READER.
fn longest(db: Db) -> Result<int, SqlError> {
    mut w = db.walk(sql("select id, body from notes"))?
    mut best = 0
    while w.step()? {
        let n = note_of(w)?
        if n.body.length > best { best = n.body.length }
    }
    best
}
```

That is the whole design in fourteen lines. `recent` is DECLARATIVE's
call site — a comprehension, `?` in element and iterable, no prepare, no
bind index, no finalize, no close. `longest` is TYPED's substrate — a
live cursor, nothing materialised. **`note_of` is written once and both
call it**, which is the bridge TYPED did not have and DECLARATIVE could
not build.

The bridge is not new machinery. `fn f<T: Show>(v: T)` with a trait
bound is proven in this tree by a passing test, **including a call to a
trait method whose body is a DEFAULT** —
`fn eight<T: Show>(v: T) -> int { v.quad() * 2 }`,
`eight(P { x: 2 })` is `16`
(`packages/std-avrac/src/features/impls/tests/impls_test.av:304`; the
bound is enforced at instantiation, `features/fns/check.av:176-193`). A
bare `T` argument is direct evidence, so no pin is written and no
fn-typed argument is threaded through a generic — the mono defect is
never touched. **HIGH.**

### 0.2 The seven collapses

Each is a place two judges disagreed and the model, not the
requirements, was wrong.

**C1 — SAFE ROWS vs FAST ROWS → the width is the witness.**
TYPED's `Cells` trait with two implementors is the right architecture
and the safety judge's objection to it was exact: a `Cursor` was
mintable before any step, so thirteen verbs were callable with no row
standing — `sqlite3_column_type` on nothing, undefined behaviour. The
fix is one field. `Cursor` carries `cols`, written by `step` from
`sqlite3_data_count`, which is **0 before the first row, 0 after DONE
and 0 after a reset** — SQLite's own answer, never a flag of ours. Every
checked verb guards `i < self.width()`, a register compare, and a read
with no row standing is refused BY NAME by the same guard that refuses
column 7 of 4. It costs nothing per cell and it buys three things at
once: the hole closes, an out-of-range column gets a message, and —
because `step` now writes an Avra field — **`mut fn step()` makes the
compiler demand a `mut` binding** (`impls_test.av:136-142`), which
closes RESOURCE's G17, the guarantee its own ledger called
unenforceable.

**C2 — A ROW THAT ESCAPES vs A ROW THAT STREAMS → both, and one reader.**
DECLARATIVE's C3 ("a row owns its cells") is the only design that closed
row STALENESS, and it is kept: `Row` is `{ cells, names }`, materialised,
and it is what `all`, `one` and `first` answer. TYPED's `Cursor` is kept
for the scan. They are not two APIs, because both implement `Cells` and
a reader generic over `C: Cells` reads either. Nothing is lost and the
ORM's streaming hydrate — which the substrate judge called
DECLARATIVE's unfixable defect — is `db.walk(q)` plus `note_of(w)?`.

**C3 — A HIDDEN CACHE vs A CALLER-HELD CACHE → an in-use bit.**
The cache is ON by default and every verb routes through it
(DECLARATIVE, and the substrate judge's strongest point: the largest
per-query constant is paid once without the caller opting in). The
safety judge's reentrancy attack — `db.each` holding a cached handle
while the step re-runs the same SQL — is closed by one bool per row: a
checked-out text prepares a FRESH statement owned by the CALLER.
RESOURCE's `Owner { Caller, Cache }` is exactly the mechanism that makes
letting go mean the right thing for both (`finalize` versus
`reset` + `clear_bindings` + release the bit). Three ideas, one seam.

**C4 — A `Tx` VALUE vs A `tx` BRACKET → `commit` is a `mut fn`.**
The safety judge's demolition of TYPED's `Tx` was correct and its cause
was precise: a Drop that rolls back, and a `commit` with no way to
disarm it. `commit` here is a **`mut fn` that writes the frame's own
`open` field**, so every rollback path reads a field and does nothing
when the frame is closed. `mut fn` writing the receiver is proven
(`impls_test.av:136-139`). With that one word the value form is safe,
and all three forms coexist over one mechanism: `db.batch([…])` (the
list IS the transaction — grafted verbatim, the commonest transaction
with no transaction vocabulary in it), `db.tx(body)` (the bracket, six
lines over `begin`), and `db.begin(mode)` (the value, for a transaction
that spans functions).

**C5 — A CONSTANT SAVEPOINT NAME vs A DEPTH COUNTER → a monotonic mint.**
RESOURCE's constant name nests correctly only under strict LIFO, and the
safety judge's four-line counter-example silently COMMITS work the
caller rolled back. DECLARATIVE's depth counter had the opposite bug in
its own showcase — `settled` never decrements, so the second `db.tx`
issues a bare `SAVEPOINT` outside any transaction, which LAW X6 makes a
`BEGIN DEFERRED`, discarding the IMMEDIATE the design existed to
guarantee. Both bugs come from a counter that has to go two ways. **A
monotonic mint only goes up**, so it cannot leak and it cannot be
reused; an out-of-order release becomes SQLite's own named refusal
(*"no such savepoint: sp_7"*). And nothing counts depth at all: whether
this frame is a BEGIN or a SAVEPOINT is `sqlite3_get_autocommit`.
**The counter names, autocommit decides.**

**C6 — A PER-CELL STORAGE-CLASS ENUM → the class is a machine word.**
All three designs minted an enum per cell to say what the cell holds,
and `features/values.av:78-84` allocates a box for every tagged value —
a payload-free variant included (`expr_spine/lower.av:84` builds one
with an empty payload list). So every design paid a heap box per cell
before it had read anything, and none noticed. `Class` here is
`{ code: int }`, a FLAT record with **no impl block** — `scalar_field`
admits a single `.Int` field (`typing_declare.av:441-449`) and an impl
UNFLATTENS its target (`typing_impls.av:95-103`) — so it rides a
register and allocates nothing. The `Storage` ENUM survives where a
human reads it: in a refusal's wording and inside `SqlValue`, where one
box is nothing.

**C7 — STRICT TEXT vs A SCAN PER CELL → there is no third text type.**
DECLARATIVE made the validated reader the long name (`text_utf8`) and
its own W10 conceded a judge was entitled to call that the coercion it
refuses everywhere else. This tree has DECIDED the invariant —
*"**Encoding is UTF-8, always**"*
(`2026_09_05_STRING_REPRESENTATION.md`) — so `r.text(i)` VALIDATES and
wears the short name. The escape hatch is not a second text verb: it is
`r.blob(i)`, which answers `bytes` and makes no encoding claim at all.
One pass over bytes the driver is already copying, fused into the
copying row, on TEXT cells only. **Two types, one law, no third
category.**

---

## 1. THE FIVE COMMITMENTS

**K1 — A QUERY IS A VALUE.** `Query` carries the SQL and every value its
holes take, so there is one verb family and not one per binding style,
and a query can be logged, cached, described, checked at compile time and
sent elsewhere because it is data (P11).

**K2 — THE STORAGE CLASS IS ASKED, NEVER ASSUMED, AND NEVER COERCED.**
`sqlite3_column_int` on the text `"abc"` answers `0` and on `"12abc"`
answers `12`. That is `?? 0` implemented in C and shipped to five
million applications — DOGFOODING's **I18** exactly. Every checked read
asks the class first and refuses a mismatch, naming both classes. The
two lossy escapes are spelled (`r.value(i)`, `r.cast_int(i)`).

**K3 — ONE READING CONTRACT, TWO LIFETIMES.** `Cells` is written once;
`Cursor` (live) and `Row` (copied) sign it. A reader is generic over the
bound, so a live read and a copied read cannot disagree — and the drift
would be a wrong answer, not a cosmetic one.

**K4 — CEREMONY LIVES IN THE LIBRARY OR NOWHERE.** Prepare, finalize,
reset, `clear_bindings`, index arithmetic, `BEGIN`/`COMMIT`/`ROLLBACK`,
savepoint names and `close_v2` are the driver's. A caller who wants them
goes one layer down, where they are spelled (P8, §13). Every deletion has
a named inspector (§15) and a gate that calls it (§18).

**K5 — NOTHING IN THIS DRIVER READS SQL TO DECIDE BEHAVIOUR.**
`sqlite3_column_count` decides whether a statement yields rows, so
`INSERT … RETURNING` needs no special case; `sqlite3_get_autocommit`
decides whether a transaction is open. That is CLAUDE.md:127 ("No string
tags or string-matching to detect behavior"), and its absence is
Python's sixteen-year `LEGACY_TRANSACTION_CONTROL` bug.

---

## 2. THE VALUES

Twelve types. A programmer meets six: `Db`, `Query`, `SqlValue`, `Row`,
`Cursor`, `SqlError`.

```avra
//! @std.sqlite — SQL is the language; everything else is a value.
use @std.errors.{Error, ErrorInfo, Loc, info}
use @std.time.{Duration, secs}

/// One of SQLite's five storage classes, carrying its value. The TOTAL
/// type: every cell is exactly one of these and no read of it can fail.
export enum SqlValue {
    Null
    Int(v: int)
    Real(v: float)
    Text(v: string)
    Blob(v: bytes)
}

/// A storage class with no value — what a mismatch names, and what a
/// cell read asks BEFORE it reads. A FLAT record of one `int`, so it
/// rides a register: `sqlite3_column_type`'s answer never allocates
/// (`typing_declare.av:441-449` admits a single `.Int` field as flat).
/// LICENSED: free fns below, never an `impl` — an impl UNFLATTENS its
/// target (`typing_impls.av:95-103`) and this value must stay a word.
export type Class = { code: int }

/// The class as a name — one box, on the refusal path only.
export enum Storage { Null, Int, Real, Text, Blob }

/// A named parameter and its value. `:city`, `@city` and `$city` are
/// one name and the sigil is the caller's, because SQLite has three of
/// them and guessing which is string-matching.
export type Bind = { name: string, value: SqlValue }

/// The SQL and the values its holes take. `args` fill the `?` slots in
/// the order written — 0-based here, 1-based in C, and the driver owns
/// the difference (LAW S5). Every slot must be filled: an unbound slot
/// binds NULL in silence (LAW S6), so the driver counts slots against
/// values and refuses before it steps.
export type Query = { text: string, args: List<SqlValue> = [], named: List<Bind> = [] }

/// A row that has ESCAPED its step: every cell copied into a box Avra
/// owns before the statement moved on. `names` is the result set's
/// column names, shared by every row of it — one word per row.
export type Row = { cells: List<SqlValue>, names: List<string> }

/// THE CURRENT ROW of a live statement, and the walk that advances it.
/// `cols` is `sqlite3_data_count` after the last step: 0 before the
/// first row, 0 after DONE, 0 after a reset, N while a row stands. It
/// is the WITNESS — every read is bounded by it, so a read with no row
/// standing is refused rather than undefined, and writing it is what
/// makes `step` a `mut fn` the compiler can hold a caller to.
export type Cursor = { db: Db, stmt: ptr, names: List<string>, cols: int, sql: string, owner: Owner }

/// A connection. Copy it freely: the copies share one `sqlite3*`, one
/// statement cache and one savepoint mint, and the last copy to die
/// closes the connection.
export type Db = { conn: Conn, cfg: Config, cache: Cache, minted: List<int> }

/// The `sqlite3*` itself. Nothing in Avra may look inside it; the
/// compiler calls `sqlite3_close_v2` when the last reference dies.
opaque type Conn @free_with(sqlite3_close_v2)              // [ASK 2]
```

`minted` is a one-slot list — the tree's mut-cell protocol, as
`features/decls.av:54` spells it (`ensure: List<fn(DeclId)>`) — holding
the savepoint counter. It is a LIST and not an `int` field because a
`Db`'s copies must share it (§9.3): a list is a pointer and a receiver's
direct field write reaches through it, while an `int` field is a copy.

```avra
/// One cell's class, projected. Free fns, because `Class` must stay
/// flat (see its declaration).
fn class_of(code: int) -> Class { Class { code: code } }
fn is_null(c: Class) -> bool { c.code == class_null() }
fn is_int(c: Class) -> bool { c.code == class_integer() }
fn is_real(c: Class) -> bool { c.code == class_real() }
fn is_text(c: Class) -> bool { c.code == class_text() }
fn is_blob(c: Class) -> bool { c.code == class_blob() }

/// The class as the enum a message reads. `Class` is an OPEN domain —
/// an integer from C — so the `_` is honest here; absence is a DEFECT
/// of ours and never a storage class we invent. (`_ -> Storage.Null`
/// is I18's exact shape: an unknown code reading as SQL NULL, which is
/// the one answer a database driver must never make up.)
fn storage_of(c: Class) -> Storage? {
    when {
        c.code == class_null() -> Storage.Null
        c.code == class_integer() -> Storage.Int
        c.code == class_real() -> Storage.Real
        c.code == class_text() -> Storage.Text
        c.code == class_blob() -> Storage.Blob
        _ -> null
    }
}
```

### 2.1 The mints

```avra
/// A statement with no values. DDL, and every parameterless query.
export fn sql(text: string) -> Query { Query { text: text } }

/// A named parameter's value.
export fn bind(name: string, v: SqlValue) -> Bind { Bind { name: name, value: v } }

impl Query {
    /// Every positional value, in the order the `?` slots are written.
    /// The WHOLE list at once: a fluent one-value-at-a-time chain
    /// (`.int(1).text("x")`) copies the argument list per value —
    /// `avra_array_concat` allocates a fresh array and copies both
    /// sides (`runtime/avra_runtime.c:1095-1103`) — so k values cost
    /// O(k²). One literal costs one allocation.
    fn args(vs: List<SqlValue>) -> Query { self with { args: vs } }

    /// Every named value, likewise whole.
    fn named(bs: List<Bind>) -> Query { self with { named: bs } }
}
```

Three mints, and the no-argument case needs no `[]` — the cost the
beauty judge charged DECLARATIVE at every DDL site.

```avra
let q = sql("select id, email from users where city = ? and age >= ?")
            .args([.Text(city), .Int(min_age)])

let n = sql("select id from users where city = :city and age >= :age")
            .named([bind(":city", .Text(city)), bind(":age", .Int(min_age))])
```

The bare-variant spelling `[.Int(limit)]` reads the seat's enum through
the hunger protocol (a list literal under a known slot judges every
element by the agreement door). **MEDIUM** on the bare form in an
ARGUMENT seat — probe 3 of §21 settles it before the first slice, and
`[SqlValue.Int(limit)]` is the same value spelled long.

Three laws the field gets wrong, obeyed here by construction:

- **No caller ever types a bind index.** SQLite's parameters are 1-based
  and its columns 0-based (LAW S5); the driver adds the one. The most
  common SQLite binding bug in the field cannot be written.
- **An under-filled statement is refused before it steps.**
  `sqlite3_bind_parameter_count` against what was given →
  `Cause.Unfilled(slots, given)`. An unbound slot binds NULL in silence
  (LAW S6) — a wrong answer, not an error, and P9 says a boundary does
  not let one through.
- **A value is never interpolated into SQL.** There is no verb here that
  takes assembled SQL with values in it, exactly as `@std/process` has
  no verb that takes a command line (CLAUDE.md:258, A COMMAND IS AN
  ARGV). Interpolation re-parses, destroys the storage class, invites
  injection, and under DQS turns a misspelled identifier into a string
  literal that matches every row.

---

## 3. OPENING AND CLOSING

### 3.1 The verbs

```avra
/// A database at a path, opened for reading and writing, created if it
/// is not there, with the driver's defaults (§3.3).
export fn open(path: string) -> Result<Db, SqlError>

/// The same file, read-only. `query_only` is set too, so a write is
/// refused by SQLite rather than by convention.
export fn open_read(path: string) -> Result<Db, SqlError>

/// A private database in memory: no file, no journal, no lock. Dies
/// with the connection.
export fn memory() -> Result<Db, SqlError>

/// Every knob, spelled. `open(p)` is `open_with(Config { path: p })`.
export fn open_with(c: Config) -> Result<Db, SqlError>
```

`open(path)` is the line a first-generation LLM writes, and it is
correct (P1).

### 3.2 Who closes, when, and what guarantees it

**The owner is the reference count, and the drop is `sqlite3_close_v2`.**

- `Conn` is `opaque type @free_with(sqlite3_close_v2)` [ASK 2]. Its
  release runs the drop; the header's `rc` decides when (CLAUDE.md:188).
- **Exactly once**, because the drop hangs off the refcount and the count
  reaches zero once. A double close is unrepresentable — which is
  RESOURCE's `Db = { raw: ptr }` bug (two `defer db.close()` across a
  copy is a double `sqlite3_close_v2`, undefined behaviour, three lines)
  deleted rather than documented.
- **Never too early**, because `close_v2` is the zombie form (LAW S22): a
  connection with an outstanding statement or blob handle is marked and
  deallocates when the last derived object goes. `sqlite3_close` — which
  answers `SQLITE_BUSY`, leaves the file locked, and lets a driver report
  success — is never called here.
- **On an early exit**, because `?`, `fail` and `return` all reach
  `FnExit`, which settles every open scope at the site.
- **On a trap, not at all — and that is right.** `avra_trap` exits 2 and
  nothing runs after it (CLAUDE.md:255). An aborted process leaves a hot
  journal or an uncheckpointed WAL and the next connection recovers. The
  failure to avoid is the opposite one — a driver that catches a wreck
  and carries on with a half-applied transaction visible to itself. No
  such path exists here.

**THE TWO CYCLES THIS DESIGN REFUSES.** CLAUDE.md:211: a closure stored
in a value that captures the value's owner is a cycle, and counting never
frees a cycle — the workspace's 922 MB.

| the shape | why it is a cycle | what this design does |
|---|---|---|
| a cached statement holding its `Db` | `Db` owns the cache; the cache would own the `Db` back | the cache holds the raw `sqlite3_stmt*` and no reference to the connection — the connection is the cache's OWNER, never its member |
| a `trace` fn capturing the `Db` | the config is a field of `Db` | the seat is a plain `fn(Trace)` and `Trace` carries what a logger needs AS DATA, so nothing needs to capture the connection (§15) |

### 3.3 The config, and the defaults defended at the field

```avra
export enum Mode { ReadWrite, ReadOnly }
export enum Journal { Wal, Delete, Truncate, Persist, Memory, Off }
export enum Sync { Full, Normal, Off }

/// Everything a connection is. Every default below is a decision this
/// driver made, and each one names what it costs.
export type Config = {
    /// The file, or `":memory:"`. A URI needs `uri = true`.
    path: string,
    mode: Mode = .ReadWrite,
    /// Create the file when it is not there. `false` makes a missing
    /// file `Cause.CantOpen` instead of a new empty database.
    create: bool = true,
    uri: bool = false,
    /// WAL lets readers and the writer run together. It needs shared
    /// memory, so it needs ONE HOST: a database on NFS or SMB must take
    /// `.Delete` (LAW K2). The mode is persistent in the file, and the
    /// driver CHECKS what the pragma answered (LAW P1).
    journal: Journal = .Wal,
    /// NORMAL is corruption-safe under WAL and loses durability: a
    /// committed transaction may roll back after a power loss. That is
    /// the caller's decision and this is where it is made. Under any
    /// other journal the driver keeps FULL regardless, because NORMAL
    /// is not corruption-safe there.
    sync: Sync = .Normal,
    /// SQLite ships foreign keys OFF for backwards compatibility. Set
    /// at open, before anything: inside a transaction the pragma is a
    /// silent no-op (LAW X8).
    foreign_keys: bool = true,
    /// How long a lock is waited for. A long timeout turns a lock-order
    /// bug into a hang, and no timeout can save a promotion deadlock
    /// (LAW K8) — which is why writes take IMMEDIATE (§9).
    busy_timeout: Duration = secs(5),
    /// Page cache, in bytes, per connection — the negative
    /// `cache_size` form, so its meaning does not move with page size.
    cache_bytes: int = 2097152,
    /// Temp tables and the sorter in RAM. A large ORDER BY without an
    /// index now costs memory instead of disk, and can run out.
    temp_in_memory: bool = true,
    /// How many prepared statements are kept (§10). `0` disables the
    /// cache and every call prepares.
    statements_cached: int = 64,
    /// Where every statement's timing goes. A fn, never a closure over
    /// the `Db` — that is the cycle of §3.2.
    trace: fn(Trace) = untraced,
}
```

Three settings are **not** fields, and their absence is the design:

- **Extended result codes are always on.** A driver that cannot tell
  `SQLITE_CONSTRAINT_UNIQUE` from `SQLITE_CONSTRAINT_FOREIGNKEY` cannot
  give a caller a `Cause` (LAW E2), and nobody wants them off.
- **Double-quoted string literals are always off**, twice over: the
  vendored build takes `-DSQLITE_DQS=0`, and the driver calls
  `sqlite3_db_config` at open the day [ASK 12] lands.
  `WHERE name = "alice"` with a misspelled column is otherwise
  `WHERE "alice" = "alice"` — the whole table, always, silently.
  The tag is the belt and the law is the braces (CLAUDE.md:188).
- **`PRAGMA optimize`** runs on the way out, once, at the last release.

`mmap_size` stays off: a mapped I/O error is a segfault rather than a
code, and a driver whose thesis is "no silent wrong answers" does not
default into a mode that turns a recoverable error into a crash. It is
reachable through `db.set_pragma`.

---

## 4. THE ERROR

### 4.1 The value, materialised at the failure site

```avra
/// Why SQLite refused, built WHERE it refused and owning everything it
/// says. It holds no borrowed pointer and no connection: `errmsg`'s
/// buffer is overwritten by the next call on the connection (LAW E4),
/// and a connection inside an error is a cycle (CLAUDE.md:211).
export type SqlError = {
    /// What to DO — the arm a caller branches on.
    cause: Cause,
    /// The primary result code, exact: `extended & 0xFF` (LAW E1).
    code: int,
    /// The extended result code, exact.
    extended: int,
    /// `sqlite3_errmsg` at the moment of the failure, copied.
    message: string,
    /// The SQL that failed, when there was one.
    sql: string?,
    /// Where in `sql` the parser stopped — `sqlite3_error_offset`,
    /// absent when it answers −1. A `Loc` and not an `int?`, because a
    /// SCALAR nullable is not a slot (`typing_declare.av:113-131`) and
    /// because a `Loc` is the tree's exchange form for a span, which is
    /// what lets the compile-time SQL checker underline the word (§14).
    at: Loc?,
}
```

> **THE ERRCODE FRAME LAW** (RESOURCE's, grafted unconditionally). The
> error is BUILT before the `fail`, by one fn, from the connection, on
> the spot. SQLite requires `sqlite3_errcode` be called *before any
> other interface on that connection*; Avra's `?`, `fail` and a
> propagating `catch` are early exits that run every open frame's
> deferred calls FIRST, so a `defer stmt.close()` twenty lines up fires
> in the gap and the errcode is already gone (probe log §2b). TYPED and
> DECLARATIVE answer that hazard with discipline — *"no `defer` near a
> read"* — which holds only while every future author keeps it.
> Materialisation makes a `defer` beside a `?` provably safe, and it is
> what makes any resource-scoped verb writable at all.

```avra
/// The connection's failure, taken WHOLE, on the spot. Every field is
/// copied here because every one is stale after the next call.
fn failure_of(db: ptr, text: string?) -> SqlError {
    let ext = sqlite3_extended_errcode(db)
    SqlError {
        cause: cause_of(ext),
        code: ext % 256,
        extended: ext,
        message: text_from_host(sqlite3_errmsg(db)),
        sql: text,
        at: span_at(text, sqlite3_error_offset(db)),
    }
}

/// `sqlite3_error_offset` answers −1 when the error names no token.
/// Absence is a `Loc?`, never a sentinel the caller must remember.
fn span_at(text: string?, at: int) -> Loc? {
    if at < 0 || text == null { return null }
    Loc { file: null, lo: at, hi: at + 1 }
}
```

`code: ext % 256` is **LAW E1** — the primary code is the low eight bits
of the extended one, and an enum matched on the extended value without
the mask never matches its own primary arm (`SQLITE_CONSTRAINT_UNIQUE`
is 2067, and `2067 == 19` is false).

### 4.2 The cause is a DECISION, and the decisions nest

```avra
/// What went wrong, at the granularity that changes what a caller DOES.
/// Every arm is a different fix; the exact codes ride beside it in
/// `code` and `extended` for everything else. A REGISTRY, so no `_ ->`
/// (I22): a result code this enum forgets is a caller acting on
/// `.Other`, which is why `.Other` carries the code.
export enum Cause {
    Constraint(v: Violation)
    Busy(b: Waiting)
    Denied(d: Denial)
    /// The cell holds one storage class and the read asked for another.
    /// The driver's OWN refusal, riding the same enum deliberately: a
    /// caller matching on `Cause` sees the schema disagreeing with the
    /// code beside every way SQLite can disagree with the disk.
    Mismatch(column: int, wanted: Storage, found: Storage)
    /// A read named a column this result set does not have, or an index
    /// past the row's width — which includes reading with NO ROW
    /// STANDING, because the width is zero there (§6).
    NoColumn(name: string)
    OutOfRow(column: int, width: int)
    /// A slot count and a value count that disagree, caught before
    /// anything was bound (LAW S6).
    Unfilled(slots: int, given: int)
    /// A TEXT cell that is not well-formed UTF-8. SQLite stores what it
    /// was given and validates nothing; Avra's `string` says UTF-8.
    NotUtf8(column: int, at: int)
    /// `one` or `scalar` found no row / found a second.
    NoRow
    ManyRows
    Syntax
    Corrupt
    Full
    TooBig
    Interrupted
    Io(op: int)
    NoMemory
    CantOpen
    NotADatabase
    /// A BLOB handle whose row was written under it (LAW B6). Re-open
    /// and restart; writes already made are NOT undone by the expiry.
    Expired
    /// THE DRIVER'S OWN BUG — `SQLITE_MISUSE`, `SQLITE_RANGE`, a
    /// statement used after finalize (LAW S9). Never the caller's
    /// mistake, never retryable, never to be caught: report it.
    Defect(what: string)
    /// A code with no arm of its own; `code` and `extended` are exact.
    Other(code: int)
}

/// The constraint family, whole — because "email already taken" and
/// "no such author" are different sentences to a user, and the field
/// derives them by REGEX over the message.
export enum Violation {
    Check, ForeignKey, NotNull, PrimaryKey, Unique, RowId,
    Trigger, DataType, Function, CommitHook, Pinned, VTab,
}

/// The retry decision, and nothing else. `.Snapshot` is 517: a stale
/// read snapshot never becomes OK in place.
export enum Waiting { Locked, Recovery, Snapshot, Timeout }

export enum Denial { Plain, Recovery, CantLock, Rollback, DbMoved, CantInit, Directory }
```

TYPED's nesting is grafted whole, and after the eager error it is the
campaign's best correctness idea: **`.Busy(.Snapshot)` is structurally
excluded from every retry loop**, because a `Waiting` payload is what
`retryable` reads. A boolean `is_busy` merges them and the ORM retries a
stale snapshot forever — the most reported SQLite-in-production bug.

```avra
impl Cause {
    /// Whether waiting could change the answer. A blanket retry turns a
    /// constraint violation into an infinite loop and a corrupt
    /// database into a hot spin (LAW E3); `.Busy(.Snapshot)` and
    /// `ABORT_ROLLBACK` need a full rollback and re-run, which is a
    /// decision only the caller can make (LAW X1).
    fn retryable() -> bool {
        match self {
            .Busy(b) -> b is .Locked || b is .Recovery || b is .Timeout,
            .Constraint(_) or .Denied(_) or .Mismatch(_, _, _) or .NoColumn(_) or
            .OutOfRow(_, _) or .Unfilled(_, _) or .NotUtf8(_, _) or .NoRow or
            .ManyRows or .Syntax or .Corrupt or .Full or .TooBig or .Interrupted or
            .Io(_) or .NoMemory or .CantOpen or .NotADatabase or .Expired or
            .Defect(_) or .Other(_) -> false,
        }
    }

    /// The stable dotted kind — hierarchical, matched by prefix, never
    /// by a class hierarchy (`@std.errors`).
    fn kind() -> string {
        match self {
            .Constraint(v) -> "sqlite.constraint.${violation_word(v)}",
            .Busy(_) -> "sqlite.busy",
            .Denied(_) -> "sqlite.denied",
            .Mismatch(_, _, _) -> "sqlite.mismatch",
            .NoColumn(_) -> "sqlite.no_column",
            .OutOfRow(_, _) -> "sqlite.out_of_row",
            .Unfilled(_, _) -> "sqlite.unfilled",
            .NotUtf8(_, _) -> "sqlite.not_utf8",
            .NoRow -> "sqlite.no_row",
            .ManyRows -> "sqlite.many_rows",
            .Syntax -> "sqlite.syntax",
            .Corrupt -> "sqlite.corrupt",
            .Full -> "sqlite.full",
            .TooBig -> "sqlite.too_big",
            .Interrupted -> "sqlite.interrupted",
            .Io(_) -> "sqlite.io",
            .NoMemory -> "sqlite.no_memory",
            .CantOpen -> "sqlite.cant_open",
            .NotADatabase -> "sqlite.not_a_database",
            .Expired -> "sqlite.expired",
            .Defect(_) -> "sqlite.defect",
            .Other(_) -> "sqlite.other",
        }
    }
}

impl Error for SqlError {
    fn describe() -> ErrorInfo { info(self.cause.kind(), self.message) }
}
```

Two or more arms answer in both, so both are registries and neither may
end in `_ ->` (I22); `or`-runs keep the enumeration one line each. The
mapping from extended code to `Cause` is a `table<CodeRow>` — the shape
I10 names for data consumed in more than one direction — and §18's gate
enumerates every extended code the vendored header declares and asserts
its arm, which is the test DECLARATIVE's W5 admitted it did not have.

### 4.3 How a failure reads at a call site

```avra
// 1. propagate — the default, and all most code ever does
let n = db.run(sql("delete from sessions where stale"))?

// 2. a default, where absence is not a failure
let n = db.run(sql("delete from sessions where stale")) catch 0

// 3. one cause, by name — a bare-variant question, which is what `is` takes
export enum Signup { Created(id: int), Taken }

fn signup(db: Db, email: string) -> Result<Signup, SqlError> {
    match db.insert(sql("insert into users(email) values (?)").args([.Text(email)])) {
        .Ok(id) -> Signup.Created(id),
        .Err(e) -> { if e.cause is .Constraint { return Signup.Taken } fail e },
    }
}

// 4. the decision, exhaustively — the outer match hands the inner one
// to a NAMED fn, so the enumeration reads as a sentence per decision
fn verdict_of(e: SqlError) -> Verdict {
    match e.cause {
        .Constraint(.Unique) -> Verdict.EmailTaken(e.message),
        .Constraint(v) -> Verdict.Rejected(v),
        .Busy(_) -> Verdict.RetryLater,
        .Denied(_) or .Mismatch(_, _, _) or .NoColumn(_) or .OutOfRow(_, _) or
        .Unfilled(_, _) or .NotUtf8(_, _) or .NoRow or .ManyRows or .Syntax or
        .Corrupt or .Full or .TooBig or .Interrupted or .Io(_) or .NoMemory or
        .CantOpen or .NotADatabase or .Expired or .Defect(_) or .Other(_) -> Verdict.Broken(e),
    }
}
```

The braced arm in (3) is because a bare `fail` in a match arm is refused
(CLAUDE.md, The subset today); `.Constraint(.Unique)` is a nested variant
pattern, which is ONE match and not an unwrap ladder.

Three properties this error has that the field's do not:

1. **The extended code is the discriminator; the message is only the
   payload.** Every ORM in the survey separates
   `SQLITE_CONSTRAINT_UNIQUE` from `SQLITE_CONSTRAINT_FOREIGNKEY` with a
   regex over English. 2067 versus 787 makes that unnecessary and
   CLAUDE.md:127 makes it forbidden.
2. **`at` is a span.** One C call gives the byte offset of the token the
   parser stopped on; mapped into the Avra string literal's own span it
   underlines the word, in the `.av` file, with an F-code (§14). sqlx
   reports the error; nothing in the field points at the character.
3. **`Cause.Defect` is not in the caller's channel.** `SQLITE_MISUSE`
   and `SQLITE_RANGE` mean the driver did something wrong. Folding them
   into the ordinary enum teaches callers to retry past the driver's own
   bug (LAW S9).

---

## 5. READING A ROW: ONE CONTRACT, TWO LIFETIMES

### 5.1 The problem, exactly

SQLite's column pointers die at the next `step`, `reset` or `finalize`,
and *also* at a type conversion on the same column (LAWS S12, S13). So a
row that ESCAPES must have been copied, and a row read in place must not
be. Those are two different values with two different costs — and every
binding in the field either materialises both (an allocation per cell on
the hot path) or hands out a borrowed row and documents the hazard.
The tempting design is one `Row` type that is "lazy"; that is precisely
the bug class (prior art §3.5).

### 5.2 The contract

```avra
/// What every row source can answer. The SEVEN required methods are
/// the irreducible per-source facts; every CHECKED reader below them is
/// a DEFAULT BODY, so a live row and a copied row cannot disagree about
/// what `int(3)` means — and the drift would be a wrong READ, not a
/// cosmetic one.
///
/// THE THREE READING LAWS, enforced by construction:
///   R1  CLASS FIRST. `class_at` decides what a cell holds. The pointer
///       is never tested and the declared type is never consulted —
///       `sqlite3_column_blob` answers NULL for SQL NULL, for a
///       ZERO-LENGTH BLOB and for out-of-memory alike (LAW S16, S17).
///       The raw readers' only callers are default bodies that have
///       already asked.
///   R2  WIDTH IS THE WITNESS. `width()` is zero before the first row,
///       after DONE and after a reset, so `class_of` refuses a read
///       with no row standing and a read past the last column with ONE
///       guard, in registers, once per cell.
///   R3  REFUSE, NEVER COERCE. `sqlite3_column_int` on `"abc"` answers
///       `0` — `?? 0` implemented in C (I18). The ladder refuses and
///       names both classes; `value` and §13's wall are the escapes.
export trait Cells {
    /// How many columns THIS ROW has. Never the statement's — a
    /// statement with no row standing has a column count and no width.
    fn width() -> int
    /// The name the statement gives column `i`.
    fn name_at(i: int) -> string
    /// The storage class of the value in column `i`, as a machine word.
    fn class_at(i: int) -> Class
    /// The raw readers. Each is correct ONLY after `class_at` answered
    /// its own class; the checked verbs below are their only callers.
    fn int_at(i: int) -> int
    fn real_at(i: int) -> float
    /// TEXT, validated — Avra's `string` says UTF-8 and SQLite
    /// validates nothing, so the one checkpoint is here, fused into the
    /// copy that LAW S12 forces anyway.
    fn text_at(i: int) -> Result<string, SqlError>
    /// BLOB, copied. The OOM check is adjacent to the read, in the
    /// implementor, with nothing between them that can leave the frame.
    fn blob_at(i: int) -> Result<bytes, SqlError>

    // ── The checked ladder. One definition, every row source. ──

    /// The class of column `i`, or the refusal that says why there is
    /// no column `i`. THE ONE GUARD (R2).
    fn class_of(i: int) -> Result<Class, SqlError> {
        if i < 0 || i >= self.width() { fail out_of_row(i, self.width()) }
        self.class_at(i)
    }

    fn int(i: int) -> Result<int, SqlError> {
        let c = self.class_of(i)?
        if !is_int(c) { fail self.wrong_class(i, Storage.Int, c) }
        self.int_at(i)
    }

    /// INTEGER widens to REAL and REAL does not narrow to INTEGER: an
    /// INT-affinity column stores `1.5` as REAL (LAW T4), so a
    /// truncating `int` read is a silent wrong answer, while a
    /// REAL-affinity column may hand an integral value back as INTEGER
    /// (LAW T5) and a `real` reader that refused it would refuse a
    /// column it wrote itself. Past 2^53 the widening is not exact and
    /// is REFUSED rather than rounded.
    fn real(i: int) -> Result<float, SqlError> {
        let c = self.class_of(i)?
        if is_real(c) { return self.real_at(i) }
        if !is_int(c) { fail self.wrong_class(i, Storage.Real, c) }
        exactly(self.int_at(i), i)
    }

    /// TEXT only. A BLOB is refused, because SQLite's TEXT is not
    /// required to be well-formed UTF-8 and `bytes` is where undecided
    /// bytes live.
    fn text(i: int) -> Result<string, SqlError> {
        let c = self.class_of(i)?
        if !is_text(c) { fail self.wrong_class(i, Storage.Text, c) }
        self.text_at(i)
    }

    /// BLOB and TEXT both: text IS bytes, and that direction is
    /// lossless. This is also the escape from a TEXT column that is not
    /// UTF-8 — read the bytes and decode them how you like.
    fn blob(i: int) -> Result<bytes, SqlError> {
        let c = self.class_of(i)?
        if !is_blob(c) && !is_text(c) { fail self.wrong_class(i, Storage.Blob, c) }
        self.blob_at(i)
    }

    /// INTEGER 0 or 1 only. SQLite has no BOOLEAN and a 2 is refused:
    /// no `bool` should silently become one.
    fn bool(i: int) -> Result<bool, SqlError> {
        let v = self.int(i)?
        if v != 0 && v != 1 { fail not_a_bool(i, v) }
        v == 1
    }

    fn cell_is_null(i: int) -> Result<bool, SqlError> { is_null(self.class_of(i)?) }

    /// The cell, whatever it is — the total read (P8). Nothing can
    /// refuse it but the row's own bounds and an ill-formed TEXT.
    fn value(i: int) -> Result<SqlValue, SqlError> {
        let c = self.class_of(i)?
        when {
            is_null(c) -> SqlValue.Null
            is_int(c) -> SqlValue.Int(self.int_at(i))
            is_real(c) -> SqlValue.Real(self.real_at(i))
            is_text(c) -> SqlValue.Text(self.text_at(i)?)
            is_blob(c) -> SqlValue.Blob(self.blob_at(i)?)
            _ -> { fail unknown_class(i, c) }
        }
    }

    /// Every cell, as values — what a `Row` is made of.
    fn values() -> Result<List<SqlValue>, SqlError> {
        [self.value(i)? for i in 0..self.width()]
    }

    // ── The nullable readers. TEXT and BLOB land TODAY (§5.4). ──

    fn text_or_null(i: int) -> Result<string?, SqlError> {
        if self.cell_is_null(i)? { return absent<string>() }
        let v: string? = self.text(i)?
        v
    }

    fn blob_or_null(i: int) -> Result<bytes?, SqlError> {
        if self.cell_is_null(i)? { return absent<bytes>() }
        let v: bytes? = self.blob(i)?
        v
    }

    /// The index of a column by name, or absence. Mapping a result
    /// column to a field BY NAME is refused as a design — a name
    /// without `AS` is UNSPECIFIED and may change between SQLite
    /// releases (LAW S20) — so this exists for reflection and
    /// diagnostics, and `describe` is where a name is resolved once.
    fn index_of(name: string) -> int? {
        [j for j in 0..self.width() if self.name_at(j) == name].first()
    }

    /// The refusal, in the row source's own words.
    fn wrong_class(i: int, want: Storage, got: Class) -> SqlError {
        column_disagrees(i, self.name_at(i), want, got)
    }
}

/// Absence, as a reader's answer. A `T?`-answering fn fills a nullable
/// slot where a bare `null` does not infer, and a generic FREE fn's
/// body MAY annotate a local with its own `T` — `new_table<T>` is the
/// tree's instance (`core/table.av:9-13`). `slot_worthy` passes a
/// nullable VAR abstractly and RE-JUDGES each instantiation
/// (`features/unify.av:131-143`), so `absent<string>()` is lawful today
/// and `absent<int>()` is refused by the slot law's own voice until
/// [ASK 1] lands. The language draws the line; this fn does not.
export fn absent<T>() -> Result<T?, SqlError> {
    let none: T? = null
    none
}
```

### 5.3 The two implementors

```avra
/// Who finalizes. A statement the caller prepared is theirs; one the
/// cache lent is the cache's, and letting it go RESETS it instead —
/// which releases the read transaction the walk was holding, clears the
/// bindings the next caller must not inherit, and drops the in-use bit.
export enum Owner { Caller, Cache }

impl Cells for Cursor {
    fn width() -> int { self.cols }
    fn name_at(i: int) -> string { self.names[i] }
    fn class_at(i: int) -> Class { class_of(sqlite3_column_type(self.stmt, i)) }
    fn int_at(i: int) -> int { sqlite3_column_int64(self.stmt, i) }
    fn real_at(i: int) -> float { sqlite3_column_double(self.stmt, i) }
    fn text_at(i: int) -> Result<string, SqlError> { text_of_column(self.stmt, i) }
    fn blob_at(i: int) -> Result<bytes, SqlError> { blob_of_column(self.stmt, i) }
}

/// Advancing is NOT a `Cells` method — an `impl Trait for` answers the
/// trait's members exactly and an extra one is refused (F2032) — so
/// stepping lives in the cursor's own inherent impl, and it is `mut`
/// because it moves SQLite's position AND writes the width that every
/// read is bounded by.
impl Cursor {
    /// One step. `true` while a row stands. At DONE the statement is
    /// RESET, because an unreset statement holds a read transaction
    /// open and a WAL whose readers never let go grows without bound
    /// (LAW K3) — the only design in the campaign that releases it at
    /// the walk's END rather than at close.
    mut fn step() -> Result<bool, SqlError> {
        let rc = sqlite3_step(self.stmt)
        if rc == rc_row() {
            self.cols = sqlite3_data_count(self.stmt)
            return true
        }
        self.cols = 0
        if rc == rc_done() { return self.ended() }
        fail failure_of(sqlite3_db_handle(self.stmt), self.sql)
    }

    /// This row, copied out, so it can escape.
    fn taken() -> Result<Row, SqlError> {
        Row { cells: self.values()?, names: self.names }
    }

    /// The walk is over: reset, and answer that no row stands. `reset`
    /// re-reports the last failing step's code, so its answer is never
    /// discarded.
    mut fn ended() -> Result<bool, SqlError> {
        if sqlite3_reset(self.stmt) != rc_ok() { fail failure_of(sqlite3_db_handle(self.stmt), self.sql) }
        false
    }

    /// Let the statement go — a caller's is finalized, the cache's is
    /// reset, cleared and released back (§10).
    mut fn close() -> int { released(self) }
}

impl Cells for Row {
    fn width() -> int { self.cells.length }
    fn name_at(i: int) -> string { self.names[i] }
    fn class_at(i: int) -> Class { class_held(self.cells[i]) }
    fn int_at(i: int) -> int { int_held(self.cells[i]) }
    fn real_at(i: int) -> float { real_held(self.cells[i]) }
    fn text_at(i: int) -> Result<string, SqlError> { text_held(self.cells[i]) }
    fn blob_at(i: int) -> Result<bytes, SqlError> { bytes_held(self.cells[i]) }
}
```

`mut fn step()` is what makes the compiler carry the contract: a `let`
receiver of a `mut fn` is refused, naming the remedy — *"`d` is not
`mut` — `tick` writes through it"* (`impls_test.av:140-142`). RESOURCE's
G17 — *"a `mut` handle is required to advance a cursor: **nothing**"* —
is closed, and it is closed because the width had to be somewhere.

What the trait buys, stated plainly:

1. **The checked ladder is written ONCE.** Fourteen verbs, one
   definition, two lifetimes.
2. **The hot path allocates nothing per row and no class box per cell.**
   `c.int(3)` on a `Cursor` is a register compare (`i < cols`), one
   `sqlite3_column_type`, a register compare, and one
   `sqlite3_column_int64`. The `SqlValue` enum is never built unless the
   caller asks for `value`.
3. **A hand-built `Row` is a row source**, so a decoder's laws are unit
   tested with no database at all — the campaign's Tier 1.
4. **A third source costs seven methods.** A `sqlite3_value*` from a
   custom SQL function joins the day trampolines land.

### 5.4 The nullable column, and where the line actually is

**The finding that outranks all three designs, and it was read from the
compiler rather than inferred.** The slot law is ONE law about
REPRESENTATION, not about nullability:

```avra
// packages/std-avrac/src/features/unify.av:131-143
.Opt(inner) -> types.opt_rides_pointer(inner) || types.shape_of(inner) is .Var,
```

and `opt_rides_pointer(inner)` is `rides_pointer(inner) || is_flat(inner)`
(`core/types.av:184-186`), where `ptr_shape` answers TRUE for `.Str`,
`.List`, `.Struct`, `.Enum`, `.Map`, `.Res`, `.Dyn`, `.Fn` and `.Ptr`,
and FALSE for `.Int` and `.Bool` (`core/types.av:118-125`). `Result`
declares `slots | true` (`features/results/mod.av:26-28`) and
`declare_applied` judges each argument by `slot_worthy`
(`typing_declare.av:335`).

**So `Result<string?, E>`, `Result<bytes?, E>`, `Result<Row?, E>` and
`List<string?>` are lawful TODAY. Only the SCALAR nullables refuse** —
and the pinned test everyone cited uses `int?`
(`features/results/tests/results_test.av:166-169`), as do all three slot
voices in `nullable_adversarial_test.av:205-218` and the struct-field
test at `nullable_test.av:23`. `List<string?>` is not merely lawful, it
is exercised: `let holes: List<string?> = filled<string?>(3, null)`
passes in `core/tests/lists_test.av:74-77`. **HIGH.**

Three consequences, each a correction to a design:

- TYPED's `integer_or_null` / `real_or_null` and RESOURCE's
  `int_or_null` / `float_or_null` — with `int()` DERIVED from
  `int_or_null()` — were marked `[today]` and do not compile. Their
  integer and float read paths do not exist.
- DECLARATIVE generalised the pinned test the other way and paid for it:
  it deleted its `first` verb, invented `ParamShape` to dodge
  `List<string?>`, and spends three tokens at every nullable TEXT read
  for a refusal that does not apply.
- The ask is therefore not ten verbs. **It is one representation
  question**, and §20's ASK 1 carries a proposed shape the compiler
  already implements for a neighbouring case.

So: `text_or_null` and `blob_or_null` are in the ladder above, unmarked.
`int_or_null`, `real_or_null` and `bool_or_null` are one ask away and are
written here so the diff is visible when it lands:

```avra
// [ASK 1] — a nullable SCALAR in a slot
fn int_or_null(i: int) -> Result<int?, SqlError> {
    if self.cell_is_null(i)? { return absent<int>() }
    let v: int? = self.int(i)?
    v
}
```

**And the ask is bigger than the driver, which is why it is ranked
first.** A user's own row type cannot hold a nullable integer column at
all: `type P = { x: int? }` is *"a struct field cannot hold this yet"*
(`nullable_test.av:23`). A nullable INTEGER is the second commonest
thing in a database and Avra cannot represent one. Until it lands, such
a column is read as `SqlValue` and the row type holds that.

---

## 6. THE FIVE STORAGE CLASSES, GOING IN

```avra
db.run(sql("insert into m(a, b, c, d, e) values (?, ?, ?, ?, ?)")
    .args([.Null, .Int(7), .Real(1.5), .Text("hi"), .Blob(payload)]))?
```

| cell class ↓ / read → | `int` | `real` | `text` | `blob` | `bool` | `value` |
|---|---|---|---|---|---|---|
| `NULL` | refuse | refuse | refuse | refuse | refuse | `.Null` |
| `INTEGER` | exact | exact ≤ 2^53 | refuse | refuse | 0/1 only | `.Int` |
| `REAL` | refuse | exact | refuse | refuse | refuse | `.Real` |
| `TEXT` | refuse | refuse | exact, validated | exact | refuse | `.Text` |
| `BLOB` | refuse | refuse | refuse | exact | refuse | `.Blob` |

Five classes, so `value`'s dispatch is a registry over a closed set and
its `_` arm is a DEFECT (`unknown_class`), never a storage class the
driver invents.

Four binding laws, each with a named cost:

- **`.Text` and `.Blob` bind with `SQLITE_TRANSIENT`, always, and with
  the header's length, never `−1`.** `−1` means `strlen`, which
  truncates a text holding a NUL — the exact bug commit `3c622be` fixed
  in this tree's `@std/io` (LAW B2). `TRANSIENT` is not negotiable until
  [ASK 9]: a `CallRt` argument is BORROWED (CLAUDE.md's runtime-row
  law), so an Avra box handed over under `SQLITE_STATIC` is freed at the
  enclosing scope's exit and the next `step` reads freed memory. The
  cost is one `memcpy` per bind.
- **`.Real(nan)` is refused, not bound.** `sqlite3_bind_double` of a NaN
  writes SQL NULL, silently (measured; the numeric-tower research, in
  git history, records it as BLOCK-8) —
  a value turning into an absence at the boundary, the one thing this
  driver exists to stop.
- **A `bool` has no class of its own.** `.Int(1)` is what goes in,
  because SQLite has none, and the driver does not invent one.
- **`SqlValue.Null` is a cell that holds SQL NULL and is NOT Avra's
  `null`.** A query builder binding a possibly-absent value must emit
  `IS ?` and not `= ?`: `x = NULL` is NULL, so `WHERE col = ?` with NULL
  bound matches nothing, silently (LAW N1). That is the ORM's job and it
  is on the list this driver publishes to it (§14).

---

## 7. RUNNING A STATEMENT

Seven verbs on `Db`. There is no `prepare`, no `execute`, no `cursor`,
and no verb whose name says whether the SQL is a SELECT —
`sqlite3_column_count` answers that at prepare time (K5).

```avra
impl Db {
    /// A statement that answers no rows. The answer is
    /// `sqlite3_changes64` — rows this statement inserted, updated or
    /// deleted DIRECTLY: trigger, foreign-key and REPLACE side effects
    /// are not counted (LAW Q5). A row-yielding statement is refused
    /// here, naming `all`.
    fn run(q: Query) -> Result<int, SqlError>

    /// An INSERT whose answer is the row it made — `last_insert_rowid`,
    /// read inside the same statement's frame. Meaningless for a
    /// WITHOUT ROWID table and for a non-INTEGER primary key, where it
    /// answers the PREVIOUS insert's rowid with no error at all (LAW
    /// Q4): use `RETURNING` there, which `all` handles with no special
    /// case.
    fn insert(q: Query) -> Result<int, SqlError>

    /// Every row, materialised in order.
    fn all(q: Query) -> Result<List<Row>, SqlError>

    /// The first row, or absence. Steps once and stops.
    fn first(q: Query) -> Result<Row?, SqlError>

    /// Exactly one row. No row is `Cause.NoRow`; a second row is
    /// `Cause.ManyRows` — a query that meant `limit 1` and did not say
    /// so is a bug this refuses instead of hiding.
    fn one(q: Query) -> Result<Row, SqlError>

    /// The first column of the first row. No row is `Cause.NoRow`.
    fn scalar(q: Query) -> Result<SqlValue, SqlError>

    /// A LIVE cursor: nothing materialised, one row at a time, the
    /// statement held for as long as the value is. See §11's hazard.
    fn walk(q: Query) -> Result<Cursor, SqlError>
}
```

`first` exists because `Result<Row?, E>` is lawful (§5.4) — DECLARATIVE
deleted it for a refusal that does not apply.

### 7.1 Reading, whole

```avra
type User = { id: int, email: string, city: string?, score: float }

/// One row of `select id, email, city, score from users`. Reads a live
/// cursor and a copied row alike.
fn user_of<C: Cells>(c: C) -> Result<User, SqlError> {
    User { id: c.int(0)?, email: c.text(1)?, city: c.text_or_null(2)?, score: c.real(3)? }
}

fn users_in(db: Db, city: string) -> Result<List<User>, SqlError> {
    [user_of(r)? for r in db.all(sql("select id, email, city, score from users where city = ?").args([.Text(city)]))?]
}

/// The untyped path, at the same power — a report, an aggregate, a
/// GROUP BY: the queries that are not entity-shaped, which is most of
/// them. A `Row` is a `Cells`, so there is no second vocabulary.
fn print_cities(db: Db) -> Result<int, SqlError> {
    let rows = db.all(sql("select city, count(*), avg(score) from users group by city"))?
    for r in rows {
        println("${r.text(0)?} ${r.int(1)?} ${r.real(2)?}")
    }
    rows.length
}
```

Four facts make the mapper a comprehension over a NAMED fn rather than
anything else:

- **A named fn in the mapper seat works everywhere, `?` included**; a
  LAMBDA there does not hear the seat's answer today (CLAUDE.md, The
  subset today), so a lambda mapper's `?` would name the lambda.
- **The mapping is a comprehension**, the tree's own beautiful form, and
  `?` works in both the element and the iterable (idiom bar, item 1).
- **No generic is threaded through a fn argument.** `all` answers
  `List<Row>` and the caller maps; `user_of` is generic over its own
  RECEIVER-shaped argument, which is direct evidence. A
  `db.all<User>(q, user_of)` would put `User` behind a fn-typed
  parameter, which mono corrupts for scalar payloads.
- **It is exactly what a derive emits** ([ASK 8]), so the call site never
  changes when the derive lands.

---

## 8. THE MUTATION SEAM — why `Db` is never `mut` and a walk always is

A finding none of the three designs made, and it decides three
signatures.

**A method that writes through a receiver's field PATH forces `mut` on
every receiver.** `impl Arena<N> { fn add(n: N) { self.nodes.push(n) } }`
with `let ints: Arena<int>` is refused — *"`ints` is not `mut` — `add`
writes through it"* (`impls_test.av:99-101`), and `Table.keep` (which
pushes and sets through `self.rows`) is called only on `mut t`
(`core/tests/table_test.av:24-26`). So a `db.run(q)` that admitted to
the cache through `self.cache.rows.push(row)` would make **every**
signature in every user's program `fn recent(mut db: Db, …)`, and THE
EXCLUSIVITY LAW would then bite the day two connections meet in one
call.

**A REBIND ALIAS does not.** `mut rows = self.cache.rows` followed by
`rows.push(r)` reads the receiver and writes the list's storage, which
is DOGFOODING's "Rebind-alias for shared mutation" and is why
`alloc_expr` is a plain `fn`. It is I34's licensed shape exactly — the
same scope has already READ the field (the cache lookup precedes the
admission) — so the license is written at the site and not in prose.

So the seam is stated once and obeyed everywhere:

> **THE DRIVER'S SHARED STATE IS LIST-BACKED, SO `Db` IS NEVER `mut`;
> THE CURSOR'S WITNESS IS A WORD, SO A WALK IS ALWAYS `mut`.**
> `Db.cache.rows` and `Db.minted` are lists, written through a licensed
> rebind alias, so `fn recent(db: Db, limit: int)` — §0.1's one-liner —
> stays as written. `Cursor.cols` is an `int`, so `step` is a `mut fn`
> and a `let` walk is REFUSED. The one place the compiler must hold the
> caller to a contract is the one place it does.

```avra
impl Db {
    /// The next savepoint number. Monotonic and never reused (§9.3).
    fn mint() -> int {
        let next = self.minted[0] + 1
        // LICENSED I34: a BORROW — the field is read on the line above,
        // and a `Db`'s copies must share one counter, which a receiver
        // field write would give them and a path write would not
        mut m = self.minted
        m.set(0, next)
        next
    }
}
```

---

## 9. TRANSACTIONS

### 9.1 The zero-ceremony form: the list IS the transaction

```avra
/// Two writes that land together or not at all. Nothing to open,
/// nothing to close, nothing to forget.
fn transfer(db: Db, from: int, to: int, cents: int) -> Result<List<int>, SqlError> {
    db.batch([
        sql("update accounts set cents = cents - ? where id = ?").args([.Int(cents), .Int(from)]),
        sql("update accounts set cents = cents + ? where id = ?").args([.Int(cents), .Int(to)]),
    ])
}
```

Grafted verbatim from DECLARATIVE, which all three judges named as a
best idea. **There is no state a caller can leave behind**: the commonest
transaction in every program is a fixed list of statements, and for that
case the correct code has no transaction vocabulary in it at all. It is
also the bulk-write path — one transaction is one fsync instead of N —
and because it routes through the cache, a thousand identical inserts
reuse one prepared statement.

### 9.2 The bracket, and the value

```avra
export enum TxMode { Deferred, Immediate, Exclusive }

/// An open transaction frame. `name` is ONE nullable, not a `Frame`
/// enum beside a `string?`: a base transaction has no savepoint name
/// and a savepoint always has one, so two levels of absence for one
/// fact collapse to one (CLAUDE.md's own `Frame`/`Loc` lesson, and
/// TYPED's `Origin?` graft applied a second time).
export type Tx = { db: Db, name: string?, open: bool, changes_at_open: int }

impl Db {
    /// The frame this connection needs: `BEGIN <mode>` outside a
    /// transaction, a SAVEPOINT inside one. WHICH is
    /// `sqlite3_get_autocommit`'s answer, never a depth counter of ours
    /// — a counter drifts the moment a caller runs BEGIN through the
    /// hatch, and drifts again every time an error rolls back by
    /// itself (LAW X4).
    fn begin(mode: TxMode) -> Result<Tx, SqlError>

    /// The body, inside one transaction, committed on its answer and
    /// rolled back on its failure. Six lines over `begin`, and it is
    /// the whole of the bracket.
    fn tx(body: fn() -> Result<int, SqlError>) -> Result<int, SqlError> {
        mut t = self.begin(TxMode.Immediate)?
        match body() {
            .Ok(v) -> { t.commit()? },
            .Err(e) -> { t.abandon() fail e },
        }
    }

    /// Whether a transaction is open — SQLITE's answer, never a
    /// counter (LAW X3).
    fn in_transaction() -> bool { sqlite3_get_autocommit(self.conn) == 0 }
}

impl Tx {
    /// Close the frame, keeping its work, and answer how many rows it
    /// changed. COMMIT at the base, RELEASE inside.
    ///
    /// `mut fn`, and that one word is the whole difference between this
    /// and the `Tx` a judge demolished: `commit` CLOSES the frame, so
    /// every later rollback path reads `open` and does nothing. A
    /// commit that cannot disarm its own rollback silently loses
    /// committed work at depth > 0, which TYPED's own `one_row` did on
    /// every SUCCESSFUL row.
    mut fn commit() -> Result<int, SqlError>

    /// Undo the frame. A no-op once `commit` has closed it, and a no-op
    /// when SQLite has already rolled back for us: `SQLITE_FULL`,
    /// `IOERR`, `BUSY`, `NOMEM` and `INTERRUPT` *might* roll a
    /// transaction back themselves (LAW X4), and a blind ROLLBACK then
    /// answers "cannot rollback — no transaction is active" and buries
    /// the real cause under its own.
    mut fn rollback() -> Result<int, SqlError>

    /// Undo the frame and say nothing — what an `errdefer` runs while a
    /// failure is already travelling. A rollback that itself fails has
    /// nowhere to report and needs none: an abandoned transaction is
    /// rolled back when the connection closes, and a crashed process
    /// leaves a journal the next connection recovers.
    mut fn abandon() { let _ = self.rollback() }
}
```

```avra
/// A transaction whose later statements read its earlier ones.
fn post(db: Db, author: string, body: string) -> Result<int, SqlError> {
    let work: fn() -> Result<int, SqlError> = () -> {
        db.run(sql("insert into authors(name) values (?) on conflict(name) do nothing").args([.Text(author)]))?
        let id = (db.scalar(sql("select id from authors where name = ?").args([.Text(author)]))?).as_int()?
        db.insert(sql("insert into posts(author, body) values (?, ?)").args([.Int(id), .Text(body)]))
    }
    db.tx(work)
}

/// A transaction that spans functions — the shape a bracket cannot
/// hold, and the reason the value exists. `errdefer` runs on the
/// failure channel and only there, which is exactly a transaction's
/// contract; when [ASK 2]'s drop lands the line is deleted and the API
/// does not move.
fn import(db: Db, rows: List<Row>) -> Result<int, SqlError> {
    mut t = db.begin(TxMode.Immediate)?
    errdefer t.abandon()
    let n = staged(db, rows)?
    t.commit()
}
```

The typed `let` on the lambda is because a lambda in an argument seat
does not hear the seat's answer today, so a `?` inside it would name the
lambda ([ASK 6]); under the typed let the body hears it, and
`tx(() -> 42)` is proven accepted (probe log §5).

**`errdefer` beside `commit` is safe twice over**: `commit` closes the
frame's `open` flag, so a rollback the errdefer runs after a *successful*
commit does nothing; and `rollback` asks `in_transaction()` first, so a
rollback after SQLite has already rolled back issues nothing. The value
guards the Avra side and SQLite's own answer guards the SQL side.

### 9.3 Nesting is a savepoint, and the name is MINTED

`db.begin` inside a transaction does not open a second one. SQLite
refuses that outright — *"An attempt to invoke the BEGIN command within
a transaction will fail"* (LAW X2) — and a binding that models only
BEGIN/COMMIT has thrown away the mechanism SQLite gives for it.

```avra
/// The savepoint's name, minted. Monotonic and NEVER REUSED.
///
/// A CONSTANT name nests correctly only while frames close
/// innermost-first, and nothing in a plain value enforces that: with
/// one shared name, `outer.rollback()` then `inner.commit()` rolls back
/// and releases INNER while the caller believes OUTER is discarded,
/// then RELEASEs OUTER — silently COMMITTING the work the caller rolled
/// back. A DEPTH counter has the mirror bug: it must go down as well as
/// up, and the decrement is what gets forgotten, after which the next
/// frame issues a bare SAVEPOINT outside any transaction — which LAW X6
/// makes a `BEGIN DEFERRED`, discarding the IMMEDIATE that exists to
/// keep `SQLITE_BUSY_SNAPSHOT` away.
///
/// A counter that only goes UP has neither failure: no two live frames
/// share a name, and an out-of-order release is SQLite's own named
/// refusal — "no such savepoint: sp_7" — rather than the wrong frame
/// committed. It costs one int per connection and one interpolation per
/// savepoint. THE COUNTER NAMES; AUTOCOMMIT DECIDES.
fn savepoint_name(n: int) -> string { "avra_sp_${n}" }
```

The discipline is exact, because `ROLLBACK TO` does not pop: success is
`RELEASE sp_n`; failure is `ROLLBACK TO sp_n` **then** `RELEASE sp_n`
(LAW X6). A nesting that forgets the second `RELEASE` leaks a stack
entry per failed inner block, and the outer `RELEASE` then closes the
wrong frame.

### 9.4 Why the write transaction is IMMEDIATE

`BEGIN` (deferred) takes its write lock at the first statement that
needs one, so a transaction that reads and then writes must PROMOTE —
and promotion can fail with `SQLITE_BUSY_SNAPSHOT`, which no busy
timeout can help with, because waiting would be a deadlock (LAW K8). It
is the single most reported SQLite-in-production bug, from code that
only ever reads then writes. `db.tx` and `db.batch` take IMMEDIATE;
`db.begin(TxMode.Deferred)` is the explicit read-snapshot form and its
argument says which.

**COMMIT can fail with `SQLITE_BUSY` and leave the transaction OPEN**
(LAW X5). `commit` retries under the busy policy and, if it still fails,
ROLLS BACK rather than leaving a write transaction to block every other
writer until the connection closes — at which point the work is silently
lost.

---

## 10. THE STATEMENT CACHE — ON, INVISIBLE, AND REENTRANT-SAFE

```avra
/// The per-connection statement cache. Keyed by SQL TEXT, scoped to ONE
/// connection — a `sqlite3_stmt` belongs to one `sqlite3*`, and sharing
/// one across connections is a use-after-free waiting for a pool. A
/// cache with no bound cannot be constructed: `Config.statements_cached`
/// is its capacity and `0` turns it off.
export type Cache = { rows: List<CacheRow>, cap: int }

/// One cached statement, as a caller may read it (§15). `handle` is the
/// raw `sqlite3_stmt*`; the cache OWNS it and finalizes it on eviction,
/// and it holds no reference back to the connection — that would be the
/// cycle of §3.2.
///
/// `in_use` is the whole answer to reentrancy. A walk holds a cached
/// handle open across every step; a step function that runs the SAME
/// SQL would otherwise get the SAME `sqlite3_stmt*`, and the inner
/// call's reset restarts the outer walk — six accepted lines, and the
/// loop repeats or truncates with no diagnostic. On a hit for a
/// checked-out text the cache PREPARES A FRESH statement owned by the
/// CALLER, which finalizes at its end. rusqlite avoids this by checking
/// a statement OUT of a pool; this cache does the same with one bool.
export type CacheRow = { text: string, handle: ptr, in_use: bool, hits: int, prepared_ns: int }
```

The reuse ritual is one place, and it is `Owner`'s dispatch:

```avra
/// Let a statement go. The cache's is RESET and CLEARED and released
/// back; a caller's is finalized. `reset` does NOT clear bindings (LAW
/// S7), and a cached statement reused with only some parameters rebound
/// writes the PREVIOUS caller's values into the slots nobody bound — a
/// data-corruption bug that passes every test in which all parameters
/// are always bound.
fn released(mut c: Cursor) -> int {
    match c.owner {
        .Caller -> sqlite3_finalize(c.stmt),
        .Cache -> c.db.returned(c.stmt),
    }
}
```

- `sqlite3_prepare_v3` with **`SQLITE_PREPARE_PERSISTENT`** for a cached
  statement — the flag exists to tell SQLite a statement will be
  retained, so its memory comes from the general heap rather than the
  lookaside pool.
- **Eviction finalizes.** A missing `sqlite3_finalize` leaks until
  process exit, by SQLite's own documentation, and an unbounded
  text-keyed cache is how sqlite4java killed its heap.
- **It never caches a row SHAPE.** `prepare_v2`/`v3` silently re-prepare
  on a schema change, and the column count, the names and the decltypes
  can all differ across that re-prepare (LAW S21). A driver that cached
  a decoded shape beside a statement decodes the new schema with the old
  one. The shape is read at each row; `describe`'s answer (§14) is keyed
  on `PRAGMA schema_version`.
- **`db.uncached(q)`** prepares, runs and finalizes without touching the
  cache — for a one-shot statement of a megabyte of SQL that should not
  be retained. It is a performance verb, not a correctness one.

The cache being ON by default is the substrate judge's strongest point
and it is kept: *the fastest path is the DEFAULT path, not an expert's
exception* (P4). RESOURCE demoted it to a caller-held value and then
made `run` and `value_of` prepare-and-finalize per call — a parse, a
name resolution and a plan compile on the two verbs everyone types
first, which is a P4 failure with no upside.

---

## 11. STREAMING, AND THE POSITION ON AGGREGATION

```avra
db.all(q)     // materialises: every row live at once
db.walk(q)    // streams: one row live at a time, nothing allocated per row
```

`sqlite3_step` yields one row per call with no buffer — SQLite is
already streaming, and materialising is what a driver *adds*. So the
naming rule is P7's: `all` says it holds everything, `walk` says it does
not, and neither hides which.

```avra
/// Every row of one database into another, one at a time, with a
/// running count. An ordinary `mut` local, no capture, no copy, no
/// F3005, and no generic answer crossing a fn-typed argument — so the
/// mono defect is never touched and the fold that DECLARATIVE could not
/// write is just a loop.
fn copy_notes(from: Db, into: Db) -> Result<int, SqlError> {
    mut w = from.walk(sql("select id, body from notes order by id"))?
    mut n = 0
    while w.step()? {
        into.run(sql("insert into notes(id, body) values (?, ?)")
            .args([.Int(w.int(0)?), .Text(w.text(1)?)]))?
        n = n + 1
    }
    n
}
```

**This is the collapse Rust cannot have.** rusqlite's `Rows` cannot be
an `Iterator` because a row borrows the statement; better-sqlite3 leaves
the connection busy if an iterator is abandoned; SeaORM's stream holds
the connection until dropped. Here a `Cursor`'s reads COPY (LAW S12
forces it), so nothing a caller holds points into SQLite's buffers, and
the streaming primitive is the ordinary `while` loop.

> **LAW S23 — AN OPEN STATEMENT HOLDS A READ TRANSACTION.** A second
> query on the same connection while a walk is open sees the older
> snapshot or contends on a write; SQLite's own isolation documentation
> calls modifying a table while a SELECT over it is still stepping
> *undefined*, not merely locked. The doc comment on `walk` says so, and
> `all` exists so the caller who does not want it does not get it.

**Aggregation is SQL's job.** A driver that streams a million rows to
count them has already lost:

```avra
(db.scalar(sql("select count(*) from ledger where posted_at >= ?").args([.Int(since)]))?).as_int()?
```

Streaming is for EXPORT, TRANSFORM and HYDRATE. There is no `each(fn)`
and no `fold(seed, fn)` in this design, and their absence is not a gap:
the loop is more capable than either (it accumulates into a `mut` local
that a captured one could not — F3005), and neither could be generic in
its answer without the mono defect ([ASK 5]).

---

## 12. INCREMENTAL BLOB I/O

```avra
export enum BlobMode { Read, Write }

impl Db {
    /// A handle onto one BLOB, by its row. `zeroblob(n)` reserves the
    /// space first: the size may NOT be changed through the handle
    /// (LAW B7). Only a real rowid table column — not a view, not a
    /// virtual table, not WITHOUT ROWID; and for writing, not indexed,
    /// not a PRIMARY KEY, not UNIQUE, not a foreign-key child (LAW B5).
    fn blob(schema: string, of_table: string, column: string, rowid: int, mode: BlobMode) -> Result<BlobIo, SqlError>
}

/// An open BLOB. Closed by its own drop: an unclosed handle keeps the
/// connection a zombie forever (LAW B9, LAW S22).
opaque type BlobIo @free_with(sqlite3_blob_close)          // [ASK 2]

impl BlobIo {
    /// `n` bytes from `at`. Refused when `at + n` passes the end.
    fn read(at: int, n: int) -> Result<bytes, SqlError>
    /// `data` at `at`. Refused when it would pass the end, and
    /// `Cause.Denied` on a handle opened `.Read`. Answers the count
    /// written, because `Result<void, E>` is refused (F2019).
    fn write(at: int, data: bytes) -> Result<int, SqlError>
    /// The blob's size — fixed for this handle's life.
    fn size() -> int
    /// The same column of a different row, without a new open.
    fn move_to(rowid: int) -> Result<int, SqlError>
}
```

```avra
/// A big value written without ever holding it whole.
fn store(db: Db, id: int, total: int, chunks: List<bytes>) -> Result<int, SqlError> {
    db.run(sql("update docs set body = zeroblob(?) where id = ?").args([.Int(total), .Int(id)]))?
    let io = db.blob("main", "docs", "body", id, .Write)?
    mut at = 0
    for c in chunks {
        io.write(at, c)?
        at = at + c.length
    }
    at
}
```

The loop earns its keep on two of the three grounds DOGFOODING allows:
`?` propagation in the body, and index arithmetic.

**The expiry is named, not generic.** If the row is UPDATEd or DELETEd
under an open handle, every later read or write answers `SQLITE_ABORT`
(LAW B6). That is `Cause.Expired`, whose message says *re-open the
handle and restart* — and whose documentation says the part that bites:
writes made **before** the expiry are not undone by it (LAW B8), so a
retry from offset 0 double-writes the prefix.

`BlobIo.read` needs a WRITABLE box and `bytes` is immutable by design:
one runtime row mints a zero-filled box of `n` bytes and hands its
payload address to `sqlite3_blob_read`, sound because the box is
uniquely referenced at the moment of minting — which the language cannot
yet PROVE. That is [ASK 4]'s second half.

---

## 13. THE ESCAPE HATCH — THE RAW WALL

P8 is not a courtesy here. A binding that offers only the pretty layer is
one people abandon at their first unusual requirement; a binding that
offers only the wall is one they wrap. This design has both, and the
lower one is **complete**: every public `sqlite3_*` entry point, spelled,
with nothing hidden and no C written by us.

```avra
//! @std.sqlite.wall — SQLite's C API, declared. One `extern fn` per
//! entry point, in the order the header declares them, nothing wrapped
//! and nothing renamed. A name here is the C name.
//!
//! FOUR LAWS, and they are general FFI law rather than this driver's:
//!
//!  W1  AN EXTERN NEVER ANSWERS `string` OR `bytes`. A foreign
//!      `const char*` typed as `string` works by accident — `hdr`
//!      refuses the untagged pointer so retain and release no-op, and
//!      `str_len` falls back to `strlen` — and that belt holds ONLY for
//!      text that is immortal and NUL-terminated. It hides exactly the
//!      three cases a driver is made of: text with a lifetime, bytes,
//!      and text holding a NUL. AND `AVRA_RC_GUARD` CANNOT SEE ANY OF
//!      THEM: it watches retain and release EVENTS and an untagged
//!      pointer raises none, so it prints clean for a correct borrow
//!      and a use-after-free alike. This is the one seam in the tree
//!      where the instrument of record is silent by construction.
//!      The wall answers `ptr`; ONE copying verb mints a box.
//!
//!  W2  A STATUS PLUS AN OUT-PARAM IS A `Result`. C splits one answer
//!      in two because C has no sum type; Avra has the type that
//!      reunites them. Spec 15.4 annotates the parameter and then
//!      writes `sqlite3_open_wrapped` in its own example, conceding a
//!      hand-written wrapper per function. [ASK 3] goes the last step.
//!
//!  W3  A DESTRUCTOR SENTINEL IS NOT A CALLBACK. Fourteen entry points
//!      take an `xDel` pointer and only two values are ever used:
//!      `SQLITE_STATIC` (`(void*)0`) and `SQLITE_TRANSIENT`
//!      (`(void*)-1`). They need no trampolines, and they need [ASK 10].
//!
//!  W4  A C `int` IS 32 BITS AND AVRA'S IS 64, AND THE SEAM IS WRONG
//!      TODAY. `declare_externs` declares every `RtKind.I64` extern as
//!      `i64` (`compiler/llvm.av:169-181`) and `rt_kind_of` maps Avra's
//!      `int` there (`core/runtime_api.av:110-114`), while both ABIs
//!      leave the bits above a 32-bit result unspecified and both
//!      compilers zero them. So `sqlite3_column_int` on a column
//!      holding −1 answers **4294967295**, on BOTH engines — eval ==
//!      native is not the same property as correct. Every narrow seat
//!      and answer below says its width, which is [ASK 7].

// (a) all-int/pointer — 173 of 284 entry points are this shape
extern fn sqlite3_libversion_number() -> i32                          // [ASK 7]
extern fn sqlite3_step(stmt: ptr) -> i32
extern fn sqlite3_reset(stmt: ptr) -> i32
extern fn sqlite3_clear_bindings(stmt: ptr) -> i32
extern fn sqlite3_finalize(stmt: ptr) -> i32
extern fn sqlite3_column_count(stmt: ptr) -> i32
extern fn sqlite3_data_count(stmt: ptr) -> i32
extern fn sqlite3_column_type(stmt: ptr, col: i32) -> i32
extern fn sqlite3_column_int64(stmt: ptr, col: i32) -> int
extern fn sqlite3_column_bytes(stmt: ptr, col: i32) -> i32
extern fn sqlite3_column_name(stmt: ptr, col: i32) -> ptr
extern fn sqlite3_db_handle(stmt: ptr) -> ptr
extern fn sqlite3_errcode(db: ptr) -> i32
extern fn sqlite3_extended_errcode(db: ptr) -> i32
extern fn sqlite3_errmsg(db: ptr) -> ptr
extern fn sqlite3_error_offset(db: ptr) -> i32
extern fn sqlite3_get_autocommit(db: ptr) -> i32
extern fn sqlite3_last_insert_rowid(db: ptr) -> int
extern fn sqlite3_changes64(db: ptr) -> int
extern fn sqlite3_total_changes64(db: ptr) -> int
extern fn sqlite3_bind_parameter_count(stmt: ptr) -> i32
extern fn sqlite3_bind_parameter_index(stmt: ptr, name: ptr) -> i32
extern fn sqlite3_bind_parameter_name(stmt: ptr, at: i32) -> ptr
extern fn sqlite3_stmt_readonly(stmt: ptr) -> i32
extern fn sqlite3_limit(db: ptr, which: i32, v: i32) -> i32
extern fn sqlite3_interrupt(db: ptr)

// (b) double — FOUR functions, and that is SQLite's whole `double`
extern fn sqlite3_column_double(stmt: ptr, col: i32) -> float          // [ASK 0]
extern fn sqlite3_bind_double(stmt: ptr, slot: i32, v: float) -> i32

// (c) out-param — a `mut` seat is the address of the caller's slot
extern fn sqlite3_open_v2(path: ptr, mut db: ptr, flags: i32, vfs: ptr) -> i32          // [ASK 3]
extern fn sqlite3_prepare_v3(db: ptr, sql: ptr, n: i32, flags: i32,
                             mut stmt: ptr, mut tail: ptr) -> i32                       // [ASK 3]
extern fn sqlite3_blob_open(db: ptr, schema: ptr, tbl: ptr, col: ptr,
                            rowid: int, rw: i32, mut blob: ptr) -> i32                  // [ASK 3]

// (d) length-carrying bytes — the pointer answers, the length rides
extern fn sqlite3_column_blob(stmt: ptr, col: i32) -> ptr
extern fn sqlite3_column_text(stmt: ptr, col: i32) -> ptr
extern fn sqlite3_bind_text64(stmt: ptr, slot: i32, p: ptr, n: int, dtor: ptr, enc: i32) -> i32
extern fn sqlite3_bind_blob64(stmt: ptr, slot: i32, p: ptr, n: int, dtor: ptr) -> i32

// Constants are fns: a module file holds declarations, and only the
// entry runs statements (F0902) — the shape `@std/process` takes.
fn class_null() -> int { 5 }
fn class_integer() -> int { 1 }
fn class_real() -> int { 2 }
fn class_text() -> int { 3 }
fn class_blob() -> int { 4 }
fn rc_ok() -> int { 0 }
fn rc_row() -> int { 100 }
fn rc_done() -> int { 101 }
fn rc_nomem() -> int { 7 }
fn prepare_persistent() -> int { 1 }
```

### 13.1 How a caller reaches it

```avra
use @std.sqlite.{Db, SqlError}
use @std.sqlite.wall.{sqlite3_wal_checkpoint_v2, checkpoint_truncate}

/// Checkpoint the WAL and truncate it — a scheduled maintenance verb
/// the driver does not (and should not) have.
fn checkpoint(db: Db) -> Result<int, SqlError> {
    mut frames = 0
    mut moved = 0
    db.check(sqlite3_wal_checkpoint_v2(db.handle(), null, checkpoint_truncate(), frames, moved))?
    moved
}
```

- **`db.handle()` and `cursor.stmt` are the two doors, and there are
  only two.** A driver that hid its handle would force a fork.
- **`db.check(rc)`** turns a raw result code into a `SqlError` — cause,
  extended code, an owned message copy, the offset — so a caller who
  leaves the paved road does not also lose the error vocabulary.
- **The hatch is proven by the driver's own use of it.** Everything in
  §17 is written against exactly this wall. There is no privileged
  interior.

**The printf family is not bound at all**: Avra has interpolation, and
SQLite's printf exists to build SQL by concatenation, which a
parameter-binding driver never does. **The variadics are op-dispatch,
not variadic** for `sqlite3_config`/`db_config`/`vtab_config` — but
TYPED's WALL LAW 4 ("one narrow monomorphic extern per argument shape")
is **wrong on the platform this tree is developed on**: Apple's arm64
ABI reads variadic arguments from the STACK, so calling a variadic
symbol through a non-variadic prototype is incorrect there. DECLARATIVE
named this correctly and it is [ASK 12].

---

## 14. DESCRIBE, REFLECTION, AND WHAT THE ORM BUILDS ON

### 14.1 Describe — the verb the whole later story hangs from

```avra
/// Which REAL column a result column came from. ONE optional, not
/// three: SQLite answers NULL for all three at once (a result column is
/// either a table column or it is an expression), so three nullable
/// fields would encode states that cannot exist. It deletes a match at
/// every construction and every read, and costs one box instead of
/// three. `in_table`, not `table` — `table` is reserved by the
/// `table<Row> { … }` literal and refuses as a field name.
export type Origin = { database: string, in_table: string, column: string }

/// One result column, as the statement declares it before any row
/// exists. `decltype` is the DECLARED type TEXT (`VARCHAR(255)`,
/// verbatim) and is absent for an expression or a subquery — a computed
/// column has no declared type and never will (LAW T13). `origin` is
/// the `SQLITE_ENABLE_COLUMN_METADATA` payload, which is why the
/// vendored build sets that flag and why macOS's system SQLite cannot
/// serve this driver.
export type ColumnShape = { name: string, decltype: string?, origin: Origin? }

/// One parameter slot. `name` is absent for a bare `?`.
export type ParamShape = { slot: int, name: string? }

/// What a statement IS, read without running it.
export type Shape = { params: List<ParamShape>, columns: List<ColumnShape>, writes: bool }

impl Db {
    /// Prepare, read the shape, finalize. NEVER steps: preparing DDL
    /// does not execute it and preparing DML does not either, which is
    /// exactly what makes this safe to run at COMPILE time against a
    /// schema-only database (§14.3).
    fn describe(q: Query) -> Result<Shape, SqlError>
}
```

`params: List<ParamShape>` rather than `List<string?>` — not because a
`List<string?>` is refused (it is lawful: `core/tests/lists_test.av:74-77`)
but because the slot NUMBER is worth carrying and a bare list of
nullable names loses it. TYPED's `StmtInfo.params: List<string?>` was
marked as impossible and is not; DECLARATIVE's `ParamShape` was chosen
for a refusal that does not exist and is right anyway.

> **THE CEILING, PUBLISHED.** SQLite will tell you a parameter's ARITY
> and never its TYPE. A compile-time checker can verify column names,
> column count and result types; for parameters it can verify only how
> many. Inferring a parameter's type from its syntactic position
> (`WHERE email = ?` against a known column) is the ORM's job, above
> this seam. It is stated in the driver's own docs so the ORM is not
> designed as if it were absent.

### 14.2 Reflection is a query, so it costs nothing

Since 3.16.0 every side-effect-free pragma is also a table-valued
function, so reflection needs **no new C entry point** and the driver
grows nothing:

```avra
export type ColumnFacts = { cid: int, name: string, decl: string, notnull: bool, dflt: string?, pk: int, hidden: int }
export type ForeignKey  = { id: int, seq: int, parent: string, child_column: string, parent_column: string?, on_update: string, on_delete: string }
export type IndexFacts  = { seq: int, name: string, unique: bool, origin: string, partial: bool }
export type TableFacts  = { schema: string, name: string, kind: string, ncol: int, without_rowid: bool, strict: bool }

impl Db {
    fn columns_of(schema: string, of_table: string) -> Result<List<ColumnFacts>, SqlError>
    fn foreign_keys_of(schema: string, of_table: string) -> Result<List<ForeignKey>, SqlError>
    fn indexes_of(schema: string, of_table: string) -> Result<List<IndexFacts>, SqlError>
    fn tables_of(schema: string) -> Result<List<TableFacts>, SqlError>
    /// The cheap invalidation token an ORM's schema cache keys on.
    /// Exposed, never used here: the cache is a policy and policy lives
    /// above the seam.
    fn schema_version(schema: string) -> Result<int, SqlError>
}
```

`table_xinfo`, not `table_info` — the latter hides generated and hidden
columns, and a migration diff that cannot see a generated column will
try to add it. The schema argument is always passed: `PRAGMA table_info`
resolves across attached databases implicitly, and SQLAlchemy carries a
bug for exactly that. `foreign_key_list`'s own column names are `table`,
`from` and `to`; they become `parent`, `child_column` and
`parent_column`, partly because `table` is reserved and mostly because
*"from"* and *"to"* on a foreign key are ambiguous in the direction that
matters.

### 14.3 The line, and the four shapes the ORM inherits

**BELOW (this package):** connection, statement, values with their
storage class readable, describe, transactions and savepoints,
`last_insert_rowid`/`changes64`, typed errors with the extended code and
the byte offset, reflection records, blob streaming,
serialize/deserialize, backup, the statement cache, and
`sqlite3_limit(SQLITE_LIMIT_VARIABLE_NUMBER)` — which is 32766 since
3.32.0 and 999 before, and whose absence is every ORM's open issue,
because a generated `IN (…)` that hard-codes 999 crashes at a thousand
elements. TYPED omitted it entirely.

**ABOVE (the ORM):** the schema model, SQL generation, type mapping
beyond the five storage classes, identity, change tracking, relations,
migrations, validation, the further projections.

**The four shapes chosen so that layer is a small step, not a rewrite:**

1. **A row reader is a plain generic fn over `Cells`.** It reads a live
   cursor, so an ORM's streaming hydrate is `db.walk(q)` plus the
   reader, with zero rows materialised — the thing the substrate judge
   found DECLARATIVE structurally could not do. A `Decode<R>` VALUE
   still exists for the ORM's own use, carrying the column list a
   generator needs:

   ```avra
   /// How a row becomes an `R`, and which columns it needs. Not the
   /// reading vocabulary — the ORM's, for generating a SELECT list and
   /// for a checker to compare against `sqlite3_column_name`.
   export type Decode<R> = { columns: List<string>, read: fn(Cursor) -> Result<R, SqlError> }

   impl Decode<R> {
       /// The SELECT list this decode names — `"id, name, email"`.
       fn select() -> string { self.columns.join(", ") }
   }
   ```

   The reading verbs are NOT on it. `user_row().all(db, q)` reads
   backwards and, worse, `db.all(q)` would dead-end at a `Row` with no
   route to a `User`; here `db.all(q)` and `db.walk(q)` are the verbs
   and `user_of` is the reader, both forward.
2. **`Query` is a struct built from a STRING LITERAL at the call site**,
   with typed, counted args. Arity checking is a pass over one literal —
   the nearly-free first rung — and full checking is the same pass with
   a schema beside it.
3. **`SqlError.at` is a span into that literal.** Added to the literal's
   own span it is a span in the user's `.av` file: the diagnostic
   underlines the exact word in the SQL, with an F-code, a help line and
   a structured fix.
4. **Nothing above `sql("…")` changes when the check lands.** The `[v2]`
   form `sql"select … where id = ${id}"` answers the same `Query` value
   the fn call answers today; the checker is a compiler pass over two
   literals and the runtime path is byte-identical.

**And the thing nobody else has.** All four systems in the field are
out-of-band: sqlx needs a live database at build time, sqlc a generated
artifact, jOOQ a codegen step, Kysely a hand-kept mirror. Avra's
compiler links SQLite itself, so it can open `:memory:`, run the
package's own migrations, `prepare_v3` the query, read the describe and
finalize — **never step**. That is sqlx's fidelity with sqlc's
hermeticity, using the *same engine* that will run the query in
production.

**`table<Row> { … }` BACKED BY SQLITE** places one constraint here, and
it is met: the row path must be expressible generically over a row type
later, which is why `Row` is DATA (`cells` + `names`) and why the
reading contract is a TRAIT rather than a closed object with private
readers.

---

## 15. THE INSPECTABILITY LEDGER (P7)

This design deletes eleven things from the call site. Each one, and the
named verb that shows it. **A row with no inspector is a defect**, and
§18's gate calls every verb in this column.

| what was deleted | where it went | how it is SEEN |
|---|---|---|
| `prepare` / `finalize` | the statement cache (§10) | `db.cached()` → `List<CacheRow>`: text, hit count, prepare nanoseconds and the IN-USE bit of every retained statement |
| the reentrancy rule | the in-use bit (§10) | the same row's `in_use`, and `Trace.cached` says which statement a call got |
| bind indices | `Query.args` / `Query.named` (§2.1) | the values are FIELDS of the query; `db.explain(q)` prints the plan |
| `close` | the refcount + `@free_with` (§3.2) | `AVRA_MEM_STATS=1` names live boxes by allocation site; `db.open_statements()` answers what would keep a `close_v2` zombie alive |
| `BEGIN`/`COMMIT`/`ROLLBACK` | `batch` / `tx` / `begin` (§9) | `db.in_transaction()` is `sqlite3_get_autocommit`, SQLite's own answer, never a counter |
| savepoint names | the monotonic mint (§9.3) | `db.minted[0]` is the last number issued, and the name is in that statement's `Trace` |
| the step loop | `all` / `walk` (§11) | the verb NAMES which it is; a `Cursor`'s `cols` is a public field |
| the cell copy | `Row` is materialised (§5) | `row.cells` is a field — the whole row, classes and all, with no verb in the way |
| result-code branching | `Cause` (§4) | `e.code` and `e.extended` are exact fields beside it; `Cause` never replaces them |
| the pragmas set at open | `Config` (§3.3) | `db.cfg` is a field, and `db.pragma(name)` reads what is ACTUALLY in force — which is not always what was asked (LAW P1) |
| the timing | `Config.trace` (§3.3) | one `Trace` per statement |

```avra
/// One statement, as it ran. `sql` is the RAW text: the expanded form —
/// `sqlite3_expanded_sql`, with the values substituted — is a separate
/// verb and never the default, because a log line carrying it leaks
/// credentials and PII into a file.
export type Trace = {
    sql: string,
    params: int,
    rows: int,
    nanos: int,
    cached: bool,
    savepoint: string?,
}
```

**And one piece of magic that is deliberately NOT hidden**: there is no
connection pool and never will be. A `Db` is one `sqlite3*`. Concurrency
is expressed the way SQLite expresses it — WAL, one writer, N readers,
each reader its own connection opened explicitly — and the driver never
hands back a connection nobody opened. `database/sql` over
`mattn/go-sqlite3`, whose documented cure is `SetMaxOpenConns(1)`, is
the whole argument.

---

## 16. THE GUARANTEE LEDGER

RESOURCE's instrument, kept whole and re-scored against this design.
"Today" is this worktree at `d96a328` plus the campaign's three
prerequisites; "landed" is after §20's asks.

| # | guarantee | today | landed | enforced by |
|---|---|---|---|---|
| G1 | a connection is closed exactly once | CONVENTION (`errdefer`) | **COMPILER** | `opaque type Conn @free_with(sqlite3_close_v2)` — a double close is unrepresentable, not documented |
| G2 | a statement outliving its connection cannot corrupt | **RUNTIME** | RUNTIME | `close_v2` zombifies (LAW S22) |
| G3 | a row read after its step is never a use-after-free | **DESIGN** | DESIGN | `Row` holds no foreign pointer; a `Cursor`'s reads copy inside the read |
| G4 | a row read with no row standing is refused | **DESIGN** | DESIGN | THE WIDTH IS THE WITNESS: `class_of` guards `i < width()`, and `width()` is `data_count` — zero before, after DONE, after reset (§5.2) |
| G5 | a stale `Cursor` cannot answer a previous row's cells | **DESIGN** | DESIGN | the same guard: `step` rewrites `cols` before any read of the new row, and a failed step zeroes it |
| G6 | advancing a cursor needs a `mut` binding | **COMPILER** | COMPILER | `mut fn step()` writes `self.cols`; a `let` receiver is refused (`impls_test.av:140-142`). RESOURCE's G17, closed |
| G7 | a transaction not committed rolls back | CONVENTION (`errdefer tx.abandon()`) | **COMPILER** | `Tx`'s drop, once an Avra-level drop exists ([ASK 2b]) |
| G8 | a committed transaction is never rolled back afterwards | **COMPILER** | COMPILER | `mut fn commit()` closes `open`; every rollback path reads it |
| G9 | a `ROLLBACK` is never issued blind | **RUNTIME** | RUNTIME | `sqlite3_get_autocommit` asked first (LAW X4) |
| G10 | a nested transaction is a savepoint, never a second BEGIN | **RUNTIME** | RUNTIME | `get_autocommit` decides at `begin` |
| G11 | two live savepoint frames never share a name | **DESIGN** | DESIGN | the monotonic mint; an out-of-order release is SQLite's named refusal |
| G12 | a cached statement never carries a previous caller's bindings | **RUNTIME** | RUNTIME | `reset` + `clear_bindings` in `released` (LAW S7) |
| G13 | one `sqlite3_stmt*` is never walked by two walkers | **RUNTIME** | RUNTIME | the in-use bit; a hit on a checked-out text prepares fresh |
| G14 | a finished walk does not hold a read transaction | **RUNTIME** | RUNTIME | `step` resets at DONE (LAW K3) |
| G15 | an under-filled statement never runs | **RUNTIME** | RUNTIME | `bind_parameter_count` checked before binding (LAW S6) |
| G16 | a class mismatch never becomes a plausible number | **RUNTIME** | RUNTIME + COMPILER | `column_type` asked first, then refuse (LAW T1, I18); later, checked SQL |
| G17 | the errcode belongs to the failure it names | **DESIGN** | DESIGN | `failure_of` materialises before the `fail` |
| G18 | a `string` from a TEXT cell is well-formed UTF-8 | **RUNTIME** | RUNTIME | validated in the copying row; `Cause.NotUtf8` names the byte |
| G19 | a `bytes` value never truncates at a NUL | nothing (no `bytes`) | **COMPILER** | the type: `==` is `memcmp`, `.length` is a header load |
| G20 | an `extern fn` never answers `string`/`bytes` | nothing | **COMPILER** | [ASK 11] — a named refusal in the compiler |
| G21 | a narrow C result is not sign-extended wrongly | **nothing — WRONG TODAY** | **COMPILER** | [ASK 7]; today `sqlite3_column_int` on −1 answers 4294967295 on both engines |
| G22 | the cache is bounded | **RUNTIME** | RUNTIME | a declared `cap`; a cache with no bound cannot be constructed |
| G23 | the SQL we run is the SQL we checked | nothing | nothing | [ASK 14] — comptime SQL, the campaign's later era |

**Three lines are the honest bad news.** G21 is a defect that exists
right now, in the tree, independent of this driver, and it is a NATIVE
defect and not only an interpreted one. G7 is a convention until an
Avra-level drop exists — `@free_with` names a C function and a
transaction's rollback is not one, which is a distinction TYPED's A1
elided. G23 is an era away.

---

## 17. THE DRIVER'S OWN CODE, WHERE IT IS LOAD-BEARING

### 17.1 One cell — the class is asked first, the errcode is adjacent

```avra
/// A TEXT cell. VALUE FIRST, THEN LENGTH (LAW S14): asking
/// `column_bytes` first on a column holding an INTEGER converts the
/// value to TEXT to measure it, and the following read answers the
/// rendering rather than the integer. `column_text` never answers NULL
/// for a TEXT cell — a text is zero-terminated even when empty (LAW
/// S15) — so NULL here is an allocation failure and nothing else.
/// The UTF-8 check rides the copy: one pass, in the C row, on the
/// bytes already in cache.
fn text_of_column(stmt: ptr, i: int) -> Result<string, SqlError> {
    let p: ptr? = sqlite3_column_text(stmt, i)
    if p == null { fail failure_of(sqlite3_db_handle(stmt), null) }
    let box: ptr? = avra_text_from_host(p!, sqlite3_column_bytes(stmt, i))
    if box == null { fail not_utf8(i, avra_text_bad_at()) }
    text_box(box!)
}

/// A BLOB cell. NULL means a zero-length blob OR an out-of-memory, and
/// the errcode is the only thing that tells them apart — so it is asked
/// IMMEDIATELY: no other SQLite call between the read and the check, no
/// `?`, no `fail`, and no `defer` frame open in this fn. THIS IS THE
/// LAW THE PROBE LOG NAMES (§2b): a `?` between the suspect read and
/// its check runs every open frame's deferred calls first.
fn blob_of_column(stmt: ptr, i: int) -> Result<bytes, SqlError> {
    let p: ptr? = sqlite3_column_blob(stmt, i)
    if p == null {
        let rc = sqlite3_errcode(sqlite3_db_handle(stmt))
        if rc == rc_nomem() { fail failure_of(sqlite3_db_handle(stmt), null) }
        return empty_bytes()
    }
    bytes_from_host(p!, sqlite3_column_bytes(stmt, i))
}
```

Four properties worth naming:

- **The pointers answer `ptr`, never `string`** (W1). The copy at the
  boundary is not a tax this design chose; it is the only correct
  reading, and every memory-safe binding in the field pays exactly it.
- **`avra_text_from_host` / `bytes_from_host` are runtime rows**, one
  `memcpy` each into a headered box through `str_box` → `box_alloc`
  (never a bare `malloc` — CLAUDE.md's header law), declared
  `owns_result: true` so the memory pass gives the result an owner.
- **An empty blob answers an EMPTY BOX, never null** — lane D's rule,
  and the reason the empty/absent collision stays at the C boundary and
  never enters Avra (an empty list, an empty string, a zero-field record
  and a zero all read PRESENT through a nullable, on both engines).
- **`str_len`'s zero fallback must be fixed with `bytes`**, or an empty
  blob measures whatever follows its payload:
  `h ? (size_t)h->len : strlen(s)` (`2026_09_05_STRING_REPRESENTATION.md`,
  "WHERE THE TREE DOES NOT YET OBEY IT").

### 17.2 One query — the whole path, and what it costs

```avra
/// Every row, materialised. The cached statement is reset and cleared
/// before it is bound (LAW S7), the slot count is checked against the
/// values before anything is bound (LAW S6), the column names are read
/// ONCE and shared by every row, and the walk's `close` releases the
/// statement to whoever owns it.
fn all(q: Query) -> Result<List<Row>, SqlError> {
    mut w = self.walk(q)?
    mut out: List<Row> = []
    while w.step()? {
        out.push(w.taken()?)
    }
    let _ = w.close()
    out
}
```

The loop earns its keep on the two grounds DOGFOODING allows: `?`
propagation in the body, and a stateful transform. `out.push` and not
`out = out.concat([…])` — `avra_array_concat` allocates a fresh array
and copies both sides (`runtime/avra_runtime.c:1095-1103`), so the
concat spelling is O(n²) and it is the list twin of I36. RESOURCE wrote
the concat form three times, including in its own day-in-the-perfect-world.

**The measured budget this design commits to:**

| property | budget |
|---|---|
| SQLite calls per scalar cell read, checked | **2** — `column_type`, the value fn. The bounds guard is a register compare |
| SQLite calls per TEXT/BLOB cell read | 3 — `column_type`, the value fn, `column_bytes` |
| heap boxes per cell, `walk` + a scalar read | **1** — the `Result`. No class box (§0.2 C6), no cell box |
| heap boxes per cell, `walk` + a TEXT read | 2 — the `Result` and the mandatory copy of LAW S12 |
| heap boxes per ROW, `walk` | **0** |
| heap boxes per ROW, `all` (n columns) | 1 `Row` + 1 cell list + n `SqlValue` + the per-cell costs above |
| `strlen` calls per bind and per read | 0 — the header carries the length on both sides |
| prepares per distinct SQL text per connection | 1 |
| interpreted vs native answers | identical by construction — the interpreter hosts the externs (§20 ASK 13), so `eval == native` is a test, not a hope |

**The one box left on the hot path is the `Result`**, and it is a
compiler-layout question rather than an API one: a `Result` whose Ok
side rides a register could be a register pair instead of a tagged box.
That is [ASK 15], it must not be answered with an API change, and
`AVRA_MEM_STATS=1` measures it before anyone claims a number.

---

## 18. THE PACKAGE, AND HOW IT IS PROVED

```
packages/std-sqlite/
  avra.toml            [link] objects = the vendored amalgamation
  vendor/sqlite3.c     3.53.4, 269,649 lines, our flags
  src/
    sqlite.av          Db, Query, SqlValue, Class, Row, Cursor, Cells, the verbs
    error.av           SqlError, Cause, the code table, the voices
    wall/mod.av        every extern fn, every constant as a fn
    blob.av            BlobIo
    shape.av           describe, and the reflection records
    tests/
      sqlite_test.av              Tier 1 — no database
      sqlite_memory_test.av       Tier 2 — `:memory:`
      sqlite_file_test.av         Tier 3 — a real file
      sqlite_adversarial_test.av  Tier 5 — the red-team catalogue
      sqlite_ledger_test.av       §15's ledger, as a gate
```

Four test facts shape the suites from the first line, all read from the
tree:

- **A `then` answers `bool` and may not carry `?`** — *"`?` makes this
  fn answer the failure, but it promises a `bool`"*
  (`features/nullable/check.av:241`). So every suite hoists its work
  into named `Result`-answering helpers above the spec block and each
  case compares one exact string — the shape `@std/process`'s
  adversarial suite takes with 25 helpers feeding 35 one-line cases.
- **No value is printed on failure.** The runner prints `✗ <label>` and
  nothing else (`compiler/test_run.av:160-166`): **a case's NAME is its
  entire diagnosis**, which is why every name in this tree reads as a
  sentence stating the claim.
- **A trap kills every later case in the package.** All of a package's
  cases run in one process, in declaration order, in one address space,
  with no isolation. A segfault in a driver case is a trap. So the
  fixture discipline is `@std/io`'s: **cleanup is BEFORE, not after** —
  `fresh()` clears what an earlier run left and then answers the path.
- **`avra test` compiles the cases to LLVM and links a native binary**,
  and the link line carries every package's `[link]` promise. So spec
  cases can call SQLite today, natively, with no compiler change. That
  is the campaign's most important machinery fact.

`:memory:` is the default fixture and `sqlite3_serialize` /
`sqlite3_deserialize` is the better one: build the schema once,
serialize the image, deserialize a fresh copy per case in microseconds.

**Three gates this design adds:**

1. **THE LEDGER GATE.** §15's right-hand column is a `table<LedgerRow>`
   and one case per row calls the inspector and asserts it answers. A
   deleted ceremony with no working inspector fails the build — the
   beauty judge's *"make it a gate, not a table"*.
2. **THE CAUSE GATE.** Every extended result code the vendored header
   declares, enumerated, each asserted to reach an arm that is not
   `.Other`. DECLARATIVE's W5 named this test as missing; it is what
   keeps a 26-arm registry honest.
3. **THE COPY GATE.** A `Db` copied into another fn, a nested `begin`
   through the copy, and an assertion on `db.minted[0]` — the test
   DECLARATIVE's W8 called "the first one to write", and the one that
   proves §8's mutation seam rather than arguing it.

### 18.1 Idiom compliance

Written against the bar rather than cleaned up afterwards.

| idiom | where |
|---|---|
| I22 (a registry spells every arm) | `Cause.kind`, `Cause.retryable`, `SqlValue`'s projections, `Cells.value`'s `when`; `or`-runs keep them one line |
| I18 (a guaranteed projection read with a plausible default is a silent wrong answer) | the whole of K2; `storage_of` answers `Storage?` and its absence is a DEFECT — RESOURCE's `_ -> Class.Null` is the shape this refuses |
| I13 (the same projection twice binds a local) | `let c = self.class_of(i)?` in every checked verb, so the class is asked ONCE and the refusal names what it found |
| I10 (an if-ladder mapping a value to values is a `when`) | `storage_of`, `Cells.value` |
| I12 (an identical struct literal twice is a constructor) | `sql()`, `bind()`, `class_of()` are the mints; no call site writes `Query { … }` |
| I28 (a law never assembles prose) | every refusal is a NAMED VOICE — `column_disagrees`, `out_of_row`, `unfilled`, `not_utf8`, `not_a_bool`, `unknown_class` — in a voices section at each file's tail |
| I36 / the list twin | `out.push(r)` in `all`, never `out = out.concat([r])` |
| I34 (the borrow under a same-scope read) | `Db.mint` and the cache's admission, both LICENSED at the site with the read that precedes them (§8) |
| I3 / the comprehension | `recent`, `users_in`, `Cells.values`, `Cells.index_of` |
| I26 (a nullable forced open three times) | no reader forces one: `class_of` answers a `Result` and `?` unwraps once |
| I35 (a raw scope bracket) | the driver emits no IR; its `defer` use is `errdefer t.abandon()` in `import`/`batch` alone, and §17.1 says why it is nowhere near a cell read |

---

---

## 19. WHERE THE REST OF THIS DESIGN LIVES

This document is the DESIGN. Three things that were once appended to it
are ledger entries, and the ledger owns them:

- **The language asks, the ladder, and the blockers** — `ROADMAP.md`,
  under `LANE SQLITE`. It carries the gaps as a checklist in dependency
  order, each proved by a quoted refusal, and it is the copy that gets
  ticked. A second copy here would drift from it.
- **The trap numbers this design cites** (T1, T14, T29, T36, T37, T49,
  T84, T95, T96, T97, T125, T127, T129, T130, T164) —
  `2026_09_05_STD_SQLITE_TRAPS.md`, which indexes all 174 and carries
  the cited ones in full.
- **The ABI census** — `packages/std-sqlite/src/c/CENSUS.md`, measured
  against the VENDORED header with the package's own flags. It is the
  only census that counts the surface this package actually links.

Cut from this file when the campaign's documentation was compressed: the
eighteen-criticism review table, the probe list, and the completeness
critic. The first two were spent once acted on; the third's central
claim ("no database has ever been opened") stopped being true when the
driver landed. Git history has all three.
