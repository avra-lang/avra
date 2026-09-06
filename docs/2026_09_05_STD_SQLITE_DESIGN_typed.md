# @std/sqlite — THE TYPED FACE

> **What this is.** The public Avra surface of `@std/sqlite`: the values a
> programmer touches, in real Avra, written against this tree's idiom bar
> and its subset. Synthesis of the research reports beside it
> (`2026_09_05_STD_SQLITE_RESEARCH_*.md`); `RESEARCH_probe_log.md` is
> LAW where anything here disagrees, because everything in it was run.
> Above that, this tree's own decided documents —
> `2026_09_05_STRING_REPRESENTATION.md` first, since every byte-level
> claim below rests on it (a `string` is a pointer to a headered box; a
> length is CARRIED, never measured; a foreign pointer is not a
> `string`). `2026_04_18_FULL_SPEC.md` is a LEGACY reference wherever
> this tree has decided otherwise.
>
> **The philosophy, committed to.** MAXIMUM TYPE POWER. Every fact the
> driver knows is carried by a TYPE or by a VALUE, never by a convention,
> a string, or a comment. The reading ladder is a trait with default
> bodies so a checked read cannot differ between two row sources. The
> row-to-struct mapping is a generic value with an inherent generic impl.
> The result codes are enums whose variants are the caller's DECISIONS.
> A transaction, a statement, a cursor and a blob stream are each a value
> whose type states its contract. Nothing is inferred from SQL text; the
> driver never reads the caller's SQL to decide behaviour.
>
> **The reading key.** Every code block is marked:
>
> | mark | means |
> |---|---|
> | `[today]` | compiles against this worktree (`lane/sqlite`, base `d96a328`) as the subset stands. Where a shape is read from the tree rather than probed, the confidence ledger says so. |
> | `[asks: An]` | uses LANGUAGE ASK *n*. The ask is listed at the tail with its wanting site, per CLAUDE.md's dogfooding rule. |
> | `[v2]` | the compile-time-checked-SQL rung. Shown only to prove the shapes below are the layer it slots into. |
>
> A block marked `[today]` that does not compile is a defect in this
> document, not a language ask.
>
> **One documentation convention, so it is never read as a defect.** A
> method shown as a signature with no body is a CONTRACT being published,
> not code being written — `fn all(q: Sql) -> Result<List<Row>, SqlError>`
> inside an `impl` block means "this is the verb and this is its type".
> Only a trait may hold a bodiless signature in real Avra; every block
> here that shows a BODY is code the compiler is meant to accept as
> written.

---

## Part 0 — THE ONE SENTENCE

> **The database is a value, a query is a value, an error is a value, and
> a row is a contract two different lifetimes both sign — so the only
> thing a caller ever writes is the type it wanted.**

Everything below is that sentence made to compile.

---

## Part 1 — WHAT THE TYPE SYSTEM CAN CARRY TODAY, MEASURED

The philosophy is maximum type power, so the ceiling has to be read from
the compiler, not assumed. Read from source in this worktree:

| capability | today | evidence |
|---|---|---|
| generic struct with fn-typed fields | **YES** | DOGFOODING.md "Generics: what infers"; `MatchContext<N>.build` |
| generic **inherent** impl (`impl Table<T>`) | **YES** | `packages/std-avrac/src/core/{table,arena,stack}.av` |
| **trait bound** on a generic free fn (`fn f<T: Show>`) | **YES**, and ENFORCED at instantiation | grammar `features/impls/../fns/mod.av:33` (`( ":" tb:NAME )?`); `bounds_hold` → `bound_held` → `cx.implements`, `features/fns/check.av:176-193` |
| **trait default method bodies** | **YES**, landed 2026-09-05 | trait grammar's `( mb:block )?`, `features/impls/mod.av:46`; ROADMAP sugar backlog "TRAIT DEFAULT METHOD BODIES — LANDED" |
| `dyn Trait` values, heterogeneous dispatch | **YES** | `Subcommand { body: dyn Runnable }`; `NodeSemantics` |
| `mut fn` method writing its receiver | **YES** | `features/impls/mod.av:47`; ROADMAP `mut self` block |
| trait impl for a **scalar** (`impl Decode for int`) | **NO** | `declared_decl` answers `null` for `.Int/.Str/.Bool/.List/.Opt/.App`, `features/contexts.av:139-150`; `implements_of` reads it |
| trait impl over a **generic** type (`impl Row for Box<T>`) | **NO — F2031** | probe log Part II; `contexts.av:139-143` records the reason |
| **generic method** (`impl Db { fn all<R>(…) }`) | **NO, in practice** | `declared_call` never unifies a method's own tparams (`features/impls/check.av:36-52`); **zero generic methods exist in the tree** (grep of `packages/*/src`) |
| **type-argument pin on a method call** (`db.all<User>(…)`) | **NO** | the postfix rule takes no `<…>`: `features/expr_spine/mod.av:40` |
| **associated / static trait fn** (`fn make() -> Self`) | **NO** | every impl and trait method gets `self` prepended as param 0: `typing_impls.av:22-25`, `impls/lower.av:30` |
| generic answer through a **fn-typed argument** | **NO, and it CORRUPTS** | DOGFOODING.md: "Fn-typed arguments carry no T-evidence, and pinning `<T>` over one corrupts scalar payloads through mono — never thread fn args through generics" |
| capture written inside a lambda | **NO — F3005** | captures are copies (DOGFOODING I15) |

**Four of those shape everything.** No generic methods and no method-call
pins mean *the type parameter must ride the RECEIVER*. No associated fns
mean *a type cannot hand back its own decoder*. No trait impl for scalars
means *the column readers cannot be `impl FromSql for int`*. And a
generic answer through a callback is a mono bug, so *the streaming
primitive cannot be `each(fn)`*.

Every one of those is dissolved below rather than worked around, and each
dissolution is an affordance rather than a compromise. Where it is not, it
is a LANGUAGE ASK with a wanting site.

---

## Part 2 — THE MODEL: eleven values

| value | what it guarantees | lifetime |
|---|---|---|
| `Db` | an open connection; closes exactly once, when the last thing derived from it dies | drop |
| `Prepared` | one compiled statement, reusable; finalizes exactly once | drop |
| `Cursor` | THE CURRENT ROW of a live statement; reads copy | between two `step`s |
| `Row` | a row that has ESCAPED — every cell already copied | forever |
| `Sql` | a statement's text and its arguments, both typed | value |
| `SqlValue` | one cell: the five storage classes, exhaustively | value |
| `SqlError` | a failure, self-contained: code, extended code, owned message, SQL, byte offset | value |
| `Tx` | an open transaction or savepoint, at a known depth | drop |
| `Decode<R>` | how a row becomes an `R`, and which columns it needs | value |
| `Stream` | one BLOB as a byte stream | drop |
| `Cache` | a bounded, caller-held statement cache | value |

**Two values are missing on purpose, and each absence is a law.**
There is no *connection pool* (prior art §3.3: a pool over an embedded
single-writer library is the field's worst bug; a `Db` is one `sqlite3*`).
There is no *cursor that outlives its statement* (LAW S12): a row either
is live (`Cursor`) or has been copied (`Row`), and the type says which.

---

## Part 3 — OPENING AND CLOSING: who closes, when, and what guarantees it

### 3.1 The target shape

```avra
// [asks: A1 opaque types + drop, A2 out-params on externs, A3 annotations]
opaque type Db     @free_with(sqlite3_close_v2)
opaque type Stmt   @free_with(sqlite3_finalize)
opaque type Stream @free_with(sqlite3_blob_close)
```

### 3.2 The paradox, collapsed: refcounting IS SQLite's zombie protocol

`sqlite3_close()` answers `SQLITE_BUSY` while any statement, blob handle
or backup is outstanding; `sqlite3_close_v2()` always answers OK and marks
the connection a **zombie** that deallocates when the last derived object
is released (LAW S22). That is a reference count, written in C, twenty
years before this tree existed.

So the ownership story needs no policy at all:

> **THE CLOSING LAW.** A `Stmt` holds its `Db`, a `Stream` holds its `Db`,
> and a `Tx` holds its `Db`. Avra's count therefore cannot reach zero on
> a connection while anything derived from it is alive; when it does,
> `close_v2` runs and the file is closed. **The refcount graph and
> SQLite's zombie protocol are the same graph.** Nobody writes `close`.

`close_v2` is the only correct `@free_with` — `close` in a drop would
answer `SQLITE_BUSY`, leave the connection open and the file locked, and
report success. The design records the difference at the declaration
site, where it is enforceable.

### 3.3 The cycle this would have created, and where it went

CLAUDE.md's cycle law: *a closure stored in a value that captures the
value's owner is a cycle, and counting never frees a cycle.* The obvious
driver design has one: `Db` holds a statement cache, the cache holds
`Stmt`s, each `Stmt` holds its `Db`. **No connection would ever close.**

The collapse is the affordance the prior art already recommends
(`bun:sqlite`'s named verb; the sqlite4java unbounded-cache heap death):

> **THE CACHE IS A VALUE THE CALLER HOLDS**, with a declared capacity —
> never a hidden field on `Db`. `db.query(…)` prepares fresh;
> `cache.query(…)` reuses. The verb says which you got, and the cycle
> cannot be constructed.

Two independent justifications for one decision is what a P6 collapse
looks like from the inside.

### 3.4 Opening

```avra
// [asks: A2, A3]

/// How a connection is opened. Every field is a value; there is no
/// DSN string, no URL query, no mode that changes what a call MEANS.
export type Config = {
    mode: Access = .ReadWriteCreate,
    vfs: string? = null,
    busy_timeout: Duration = secs(5),
    journal: Journal = .Wal,
    synchronous: Sync = .Normal,
    foreign_keys: bool = true,
    trusted_schema: bool = false,
    extended_codes: bool = true,
}

export enum Access { ReadOnly, ReadWrite, ReadWriteCreate, Memory }
export enum Journal { Delete, Truncate, Persist, Memory, Wal, Off }
export enum Sync { Off, Normal, Full, Extra }

/// Open `path`, with the defaults every production connection wants
/// already set. `":memory:"` is `Access.Memory`, spelled.
export fn open(path: string) -> Result<Db, SqlError>

/// Open with the configuration spelled. The pragmas are applied HERE,
/// before anything else runs — `PRAGMA foreign_keys` is a silent no-op
/// inside a transaction (LAW X8), so a lazily-applied pragma is a
/// wrong program that reports success.
export fn open_with(path: string, c: Config) -> Result<Db, SqlError>
```

`open` is not `open_with(path, Config { })` spelled twice: it *is* that,
and it exists so that the ninety-per-cent call is four words (P3).

### 3.5 What it degrades to before A1 lands

```avra
// [today] — the same surface, the drop written by hand at the call site.
export type Db = { raw: ptr }

impl Db {
    /// The connection's raw `sqlite3*` — the escape hatch, spelled (P8).
    fn handle() -> ptr { self.raw }

    /// Close the connection. `close_v2` never refuses: an outstanding
    /// statement makes the connection a zombie that deallocates when the
    /// last derived object is released.
    fn close() -> int { sqlite3_close_v2(self.raw) }
}
```

```avra
// [today]
fn count_users(path: string) -> Result<int, SqlError> {
    let db = open(path)?
    defer db.close()                     // the drop, written out
    db.one_integer(sql("SELECT count(*) FROM users"))
}
```

**And the degradation has a cost worth naming**, because it is the exact
reason A1 is on the critical path rather than a nicety: with `defer` the
close is a FRAME's, so a `Db` returned from this fn would be closed on
the way out; with drop it is the VALUE's, so it is not. Every design in
the field that lacks the value-scoped close has a connection-leak issue in
its tracker (VISION Part II §4). The `[today]` form is a bridge, and it is
marked as one everywhere it appears.

**The `opaque type` ask is smaller than it looks, and this is the useful
finding for whoever lands it.** A single-field record of one pointer
already rides as the pointer (`is_flat`, `core/types.av:174-185`), already
bears methods (`Callee.Declared`, `features/impls/callee.av:58-67`), and
already crosses an extern seat as `RtKind.Ptr`. So

> `opaque type Db @free_with(f)`  ≡  `type Db = { raw: ptr }` + a drop
> hook on the declaration + field privacy.

which is **a drop hook on a declared type**, not a new kind of type. The
one thing the design REQUIRES of it: an `opaque type` must answer
`Callee.Declared`, or `impl Db { … }` does not land and the whole face
below has nowhere to live.

---

## Part 4 — THE ERROR: a failure reads as a decision

### 4.1 The type

```avra
// [today]

/// Why SQLite refused. Self-contained BY LAW (LAW E8): the message is
/// an owned copy taken at the failure site, before any other call on
/// the connection could overwrite it, and nothing here borrows.
export type SqlError = {
    cause: Cause,
    extended: int,
    message: string,
    sql: string?,
    offset: int?,
}
```

`extended` is kept as the exact integer beside the enum, always. The enum
is what the caller BRANCHES on; the integer is what the caller REPORTS,
and dropping it would make a driver that cannot say which of 37 I/O
errors happened.

### 4.2 The cause is a DECISION, not a number

```avra
// [today]

/// What went wrong, at the granularity that changes what a caller DOES.
/// Every variant is a different fix. `Misuse` is a DRIVER DEFECT and is
/// never reachable through this package's public API (LAW S9).
export enum Cause {
    Constraint(v: Violation)
    Busy(b: Busy)
    ReadOnly(r: ReadOnly)
    Corrupt
    NotFound
    Full
    Interrupted
    Range
    Auth
    Io(op: int)
    Syntax
    Expired
    Mismatch(want: Storage, got: Storage)
    Misuse
    Other(code: int)
}

/// The constraint family, whole — because "email already taken" and
/// "no such author" are different sentences to a user, and the field
/// derives them by REGEX over the message. The extended code is the
/// discriminator; the message only fills the payload.
export enum Violation {
    Check, ForeignKey, NotNull, PrimaryKey, Unique, RowId,
    Trigger, DataType, Function, CommitHook, Pinned, VTab,
}

/// The retry decision, and nothing else.
export enum Busy { Locked, Recovery, Snapshot, Timeout }

export enum ReadOnly { Plain, Recovery, CantLock, Rollback, DbMoved, CantInit, Directory }
```

`Mismatch` is the driver's OWN refusal — a read that named a class the
cell does not hold (Part 6). It rides the same enum deliberately: a caller
matching on `Cause` sees the schema disagreeing with the code beside every
way SQLite can disagree with the disk, in one place.

```avra
// [today]

/// Whether waiting could help. LAW E3: the retryable set is small and
/// explicit, and a blanket retry turns a constraint violation into an
/// infinite loop.
impl Cause {
    fn retryable() -> bool {
        match self {
            .Busy(b) -> b is .Recovery || b is .Timeout || b is .Locked,
            .Constraint(_) or .ReadOnly(_) or .Corrupt or .NotFound or .Full or
            .Interrupted or .Range or .Auth or .Io(_) or .Syntax or .Expired or
            .Mismatch(_, _) or .Misuse or .Other(_) -> false,
        }
    }
}
```

Note the shape: **`match` over our own enum with no `_ ->`.** Two arms
answer, so it is a REGISTRY and a catch-all would silently forget the next
cause (CLAUDE.md's `_ ->` law, I22). `or`-runs keep it one line.

> `.Busy(.Snapshot)` is **not** retryable and `.Busy(.Locked)` is: a
> snapshot conflict needs a full rollback and re-run, a lock needs a wait.
> A boolean `is_busy` would have merged them, and the ORM would retry a
> conflict forever. This is why the payload enums exist.

### 4.3 How a failure reads at a call site

```avra
// [today] — four readings, in rising specificity

// 1. propagate
let n = db.run(sql("DELETE FROM sessions WHERE stale"))?

// 2. a default, no ceremony
let n = db.run(sql("DELETE FROM sessions WHERE stale")) catch 0

// 3. one cause, by name
let saved = db.run(insert) catch e -> {
    if e.cause is .Constraint { return AlreadyThere }
    fail e
}

// 4. the decision, exhaustively
match db.run(insert) {
    .Ok(n) -> Verdict.Saved(n),
    .Err(e) -> refusal_of(e),
}

fn refusal_of(e: SqlError) -> Verdict {
    match e.cause {
        .Constraint(.Unique) -> Verdict.EmailTaken(e.message),
        .Constraint(v) -> Verdict.Rejected(v),
        .Busy(_) -> Verdict.RetryLater,
        .ReadOnly(_) or .Corrupt or .NotFound or .Full or .Interrupted or
        .Range or .Auth or .Io(_) or .Syntax or .Expired or .Mismatch(_, _) or
        .Misuse or .Other(_) -> Verdict.Broken(e),
    }
}
```

The nested arm is one match, not an unwrap ladder (CLAUDE.md: "A
projection is ONE match"), and the outer `match` hands the inner one to a
NAMED fn rather than nesting two registries in one expression — the
enumeration then reads as a sentence per decision.

`.Constraint(.Unique)` is a nested variant pattern — one match, no unwrap
ladder (CLAUDE.md style: "A projection is ONE match").

### 4.4 The byte offset, and why it is the highest-leverage field here

```avra
// [today]
impl SqlError {
    /// Where in the SQL the parser stopped, as a `@std.errors.Loc` over
    /// the statement text. `sqlite3_error_offset` answers −1 when there
    /// is no such token, and −1 becomes absence.
    fn at() -> Loc? {
        if self.offset == null || self.sql == null { return null }
        Loc { file: null, lo: self.offset!, hi: self.offset! + 1 }
    }
}

impl Error for SqlError {
    fn describe() -> ErrorInfo { info(kind_of(self.cause), self.message) }
}
```

A `Loc` is the tree's own diagnostic currency. At runtime it points a
caret into the SQL a program printed. At **compile time** (Part 13) the
same offset, added to the span of the `sql("…")` string literal, underlines
the offending word *in the user's `.av` file*. sqlx reports the error;
nothing in the field points at the character. It costs one C call and one
nullable int, and it is designed in from the first line for exactly that
reason.

---

## Part 5 — SQL IS A VALUE

### 5.1 The type

```avra
// [today]

/// A statement and its arguments, together. The driver NEVER reads
/// `source` to decide behaviour — no sniffing for INSERT, no leading-verb
/// classification (prior art §3.1); `column_count` decides whether a
/// statement yields rows, and it is known at prepare time.
/// (The field is `source`, not `text`, because `text` is a BIND VERB
/// below and a field of a fn-free type would shadow nothing but would
/// read as if it did.)
export type Sql = { source: string, args: List<Arg> }

/// One argument. The two spellings SQLite offers, kept apart, so no
/// index is ever typed by a caller and the 1-based/0-based off-by-one
/// — the field's single commonest sqlite bug — cannot be written.
export enum Arg {
    Next(v: SqlValue)
    Named(name: string, v: SqlValue)
}

/// A statement with no arguments yet.
export fn sql(source: string) -> Sql { Sql { source: source, args: [] } }

/// Arguments with no statement — what a `Prepared` is run with.
export fn args() -> Sql { Sql { source: "", args: [] } }
```

### 5.2 Binding: one vocabulary, and it is the storage classes'

```avra
// [today]
impl Sql {
    /// The next unfilled slot, in order. There is no index to get wrong.
    fn integer(v: int) -> Sql  { self.next(SqlValue.Integer(v)) }
    fn real(v: float) -> Sql   { self.next(SqlValue.Real(v)) }
    fn text(v: string) -> Sql  { self.next(SqlValue.Text(v)) }
    fn blob(v: bytes) -> Sql   { self.next(SqlValue.Blob(v)) }

    /// A value already in hand — including `.Null`, which has no verb of
    /// its own because `null` is a keyword and `.value(.Null)` says it.
    fn value(v: SqlValue) -> Sql { self.next(v) }

    /// A named slot, spelled exactly as the statement spells it —
    /// `":min"`, `"@min"`, `"$min"`. The sigil is the caller's because
    /// SQLite has three and guessing is string-matching.
    fn set(name: string, v: SqlValue) -> Sql {
        self with { args: self.args.concat([Arg.Named(name, v)]) }
    }

    fn next(v: SqlValue) -> Sql {
        self with { args: self.args.concat([Arg.Next(v)]) }
    }
}
```

The five verbs are one projection each; `next` is the one that appends,
so the append is written once (I12 — an identical struct literal written
twice is a constructor waiting for its name).

```avra
// [today]
let q = sql("SELECT id, name FROM users WHERE score > ? AND city = ?")
    .integer(40)
    .text("Berlin")

let q = sql("SELECT id, name FROM users WHERE score > :min AND city = :city")
    .set(":min", .Integer(40))
    .set(":city", .Text("Berlin"))
```

`.Integer(40)` is a bare variant literal in an argument seat — the hunger
protocol feeds it the enum from `set`'s declared seat (DOGFOODING, "The
hunger protocol"). So the caller never spells `SqlValue`.

**The read verbs and the bind verbs are the same five words** —
`integer`, `real`, `text`, `blob`, `null`. One vocabulary for both
directions of the boundary is what makes an LLM correct on the first
generation (P1), and the words are SQLite's own storage-class names, so
there is nothing to translate from the documentation.

### 5.3 The binding law

> **THE FILLING LAW.** `Arg.Next` values fill slots 1..k in the order
> written. Every remaining slot must be filled by name. **A slot filled
> twice is refused. A slot left empty is refused.** An unbound parameter
> is a silent SQL NULL — a wrong answer, not an error — and P9 says a
> boundary does not let that through.

```avra
// [today] — the voices, at the file's tail (I28: a law never assembles prose)
fn slot_unfilled(source: string, want: int, got: int, names: List<string>) -> SqlError
fn slot_twice(source: string, name: string) -> SqlError
fn no_such_parameter(source: string, name: string, known: List<string>) -> SqlError
```

`no_such_parameter` lists the statement's real parameter names from
`sqlite3_bind_parameter_name`. That refusal is the difference between
"binding failed" and "this statement takes `:min`, `:city` — you wrote
`:minimum`".

---

## Part 6 — READING A ROW: one contract, two lifetimes

This is the design's spine.

### 6.1 The problem, exactly

SQLite's column pointers die at the next `step`, `reset` or `finalize`,
and *also* at a type conversion on the same column (LAWS S12, S13). So a
row that ESCAPES must have been copied, and a row read in place must not
be. Those are two different values with two different costs — and every
binding in the field either materialises both (paying an allocation per
cell on the hot path) or hands out a borrowed row and documents the
hazard (rusqlite cannot make `Rows` an `Iterator`; better-sqlite3's
`unsafeMode`).

The tempting design is one `Row` type that is "lazy". That is precisely
the bug class (prior art §3.5).

### 6.2 The collapse: two implementors, one contract, written once

```avra
// [today]

/// The five storage classes. SQLite is dynamically typed PER VALUE, so
/// this is a fact about the cell in front of you, never about the column
/// it came from (LAW T13).
export enum Storage { Null, Integer, Real, Text, Blob }

/// What every row source can answer. The SEVEN required methods are the
/// irreducible per-source facts; every CHECKED reader below them is a
/// default body, so a live row and a copied row cannot disagree about
/// what `integer(3)` means.
export trait Cells {
    /// How many columns.
    fn width() -> int
    /// The name the statement gives column `i`.
    fn name_at(i: int) -> string
    /// The storage class of the value in column `i`. Asked FIRST,
    /// always — a column read NEVER tests a pointer to decide what it
    /// found (LAW S16: a zero-length blob is a NULL pointer and is not
    /// a NULL value).
    fn class_at(i: int) -> Storage
    /// The raw readers. Each is correct ONLY after `class_at` answered
    /// its own class; the checked verbs below are their only callers.
    fn integer_at(i: int) -> int
    fn real_at(i: int) -> float
    fn text_at(i: int) -> string
    fn blob_at(i: int) -> bytes

    // ── The checked ladder. One definition, every row source. ──

    fn integer(i: int) -> Result<int, SqlError> {
        if !(self.class_at(i) is .Integer) { fail self.wrong_class(i, Storage.Integer) }
        self.integer_at(i)
    }
    fn real(i: int) -> Result<float, SqlError> {
        if !(self.class_at(i) is .Real) { fail self.wrong_class(i, Storage.Real) }
        self.real_at(i)
    }
    fn text(i: int) -> Result<string, SqlError> {
        if !(self.class_at(i) is .Text) { fail self.wrong_class(i, Storage.Text) }
        self.text_at(i)
    }
    fn blob(i: int) -> Result<bytes, SqlError> {
        if !(self.class_at(i) is .Blob) { fail self.wrong_class(i, Storage.Blob) }
        self.blob_at(i)
    }

    fn is_null(i: int) -> bool { self.class_at(i) is .Null }

    fn integer_or_null(i: int) -> Result<int?, SqlError> {
        if self.is_null(i) { return absent<int>() }
        let v: int? = self.integer(i)?
        v
    }
    fn real_or_null(i: int) -> Result<float?, SqlError> {
        if self.is_null(i) { return absent<float>() }
        let v: float? = self.real(i)?
        v
    }
    fn text_or_null(i: int) -> Result<string?, SqlError> {
        if self.is_null(i) { return absent<string>() }
        let v: string? = self.text(i)?
        v
    }
    fn blob_or_null(i: int) -> Result<bytes?, SqlError> {
        if self.is_null(i) { return absent<bytes>() }
        let v: bytes? = self.blob(i)?
        v
    }

    /// The total type — the escape hatch (P8). No refusal is possible;
    /// the storage class rides the value.
    fn value_at(i: int) -> SqlValue {
        match self.class_at(i) {
            .Null -> SqlValue.Null,
            .Integer -> SqlValue.Integer(self.integer_at(i)),
            .Real -> SqlValue.Real(self.real_at(i)),
            .Text -> SqlValue.Text(self.text_at(i)),
            .Blob -> SqlValue.Blob(self.blob_at(i)),
        }
    }

    /// Every cell, as values. What `Row` is made of.
    fn values() -> List<SqlValue> { [self.value_at(i) for i in 0..self.width()] }

    /// The index of a column by name, or absence. Mapping a result
    /// column to a row field BY NAME is refused as a design (LAW S20 —
    /// a name without `AS` is unspecified and may change between SQLite
    /// releases); this exists for reflection and diagnostics.
    fn index_of(name: string) -> int? {
        [j for j in 0..self.width() if self.name_at(j) == name].first()
    }

    /// The refusal, in the row source's own words.
    fn wrong_class(i: int, want: Storage) -> SqlError {
        column_disagrees(i, self.name_at(i), want, self.class_at(i))
    }
}
```

```avra
// [today] — the one helper the nullable readers need, because a bare
// `null` does not infer into a `T?` seat and a `T?`-answering fn does
// (CLAUDE.md, the subset; the tree's own `captured_absent<N>()`).
export fn absent<T>() -> Result<T?, SqlError> {
    let v: T? = null
    v
}
```

```avra
// [today] — the two implementors

/// The CURRENT row of a live statement. Reads copy at the boundary; the
/// value never escapes the step it was read in.
export type Cursor = { stmt: Prepared }

/// A row that has escaped. Every cell copied, the names shared with the
/// statement that produced it.
export type Row = { cells: List<SqlValue>, names: List<string> }

impl Cells for Cursor {
    fn width() -> int { sqlite3_data_count(self.stmt.handle()) }
    fn name_at(i: int) -> string { text_from_host(sqlite3_column_name(self.stmt.handle(), i)) }
    fn class_at(i: int) -> Storage { storage_of(sqlite3_column_type(self.stmt.handle(), i)) }
    fn integer_at(i: int) -> int { sqlite3_column_int64(self.stmt.handle(), i) }
    fn real_at(i: int) -> float { sqlite3_column_double(self.stmt.handle(), i) }
    fn text_at(i: int) -> string { text_of_column(self.stmt.handle(), i) }
    fn blob_at(i: int) -> bytes { blob_of_column(self.stmt.handle(), i) }
}

/// Advancing is NOT a `Cells` method: an impl-for answers every trait
/// method exactly, and an extra one is refused (F2032). Stepping is the
/// cursor's own, in its own inherent impl, and it is `mut` because it
/// moves SQLite's position.
impl Cursor {
    mut fn step() -> Result<bool, SqlError>
    /// Copy this row out, so it can escape (Part 8.5's `all` is a loop
    /// over exactly this).
    fn taken() -> Row
}

impl Cells for Row {
    fn width() -> int { self.cells.length }
    fn name_at(i: int) -> string { self.names[i] }
    fn class_at(i: int) -> Storage { class_of_value(self.cells[i]) }
    fn integer_at(i: int) -> int { int_of_value(self.cells[i]) }
    fn real_at(i: int) -> float { real_of_value(self.cells[i]) }
    fn text_at(i: int) -> string { text_of_value(self.cells[i]) }
    fn blob_at(i: int) -> bytes { bytes_of_value(self.cells[i]) }
}
```

**What the trait buys, stated plainly.**

1. **The checked ladder is written ONCE.** Thirteen verbs, one definition.
   Two hand-written copies would be I11 and I12 waiting to drift, and the
   drift would be a *wrong read*, not a cosmetic one.
2. **The hot path allocates nothing.** `c.integer(3)` on a `Cursor` is
   `sqlite3_column_type` then `sqlite3_column_int64`: two C calls, zero
   boxes. The value enum is never built unless the caller asks for
   `value_at`. That is the P4 story and it is why the required methods
   are the raw readers rather than a `SqlValue` getter.
3. **A hand-built `Row` is a row source**, so a decoder's laws can be
   unit-tested with no database at all (`tdd_and_gates` Tier 1) — with
   one caveat that is NOT free: DOGFOODING records "no generic-enum
   returns through `dyn`", and every checked verb answers a
   `Result<…, SqlError>`, which is a generic enum. **So a `dyn Cells`
   may reach `width`, `name_at`, `class_at`, `is_null` and `value_at`,
   and possibly not the checked ladder.** The design does not depend on
   `dyn Cells` anywhere; it is listed as an affordance the trait would
   give if that limit lifts, and it is probe 8 below.
4. **A third source costs seven methods.** A `sqlite3_value*` from a custom
   SQL function, when trampolines land, joins by implementing the seven.

### 6.3 The reading laws, and where they are enforced

> **LAW R1 — CLASS FIRST, ALWAYS.** `class_at` is the only thing that
> decides what a cell holds. The pointer is never tested; the declared
> type is never consulted. Enforced by construction: the raw readers are
> only ever called from a default body that has already asked.

> **LAW R2 — VALUE, THEN LENGTH, THEN COPY, THEN MOVE ON.** `column_text`
> then `column_bytes`; `column_blob` then `column_bytes`; never the
> reverse and never mixed (LAWS S13, S14). Both orders live inside
> `text_of_column` / `blob_of_column`, which are the only two fns in the
> package that touch a column pointer.

> **LAW R3 — NO `defer` IN THIS DRIVER TOUCHES A CONNECTION.** SQLite
> requires `sqlite3_errcode` before any other interface on that
> connection; Avra's early exits (`?`, `fail`, a propagating `catch`) run
> every open frame's deferred calls FIRST, so a `defer stmt.reset()`
> twenty lines up fires between a suspect read and its check (probe log
> §2b). Cleanup in this package is the VALUE's drop, never a frame's, and
> the two OOM checks live in `text_of_column` and `blob_of_column` with no
> statement between the read and the check.

> **LAW R4 — REFUSE, NEVER COERCE.** `sqlite3_column_int` on the text
> `"abc"` answers `0`. That is `?? 0` implemented in C and shipped to five
> million applications — DOGFOODING's I18, exactly. The checked ladder
> refuses and names both classes. The two escape hatches are spelled:
> `value_at` (the total type) and Part 12's raw wall.

The refusal, in full:

```avra
// [today] — a voice; its whole body is the one refusal (I28)
fn column_disagrees(i: int, name: string, want: Storage, got: Storage) -> SqlError {
    SqlError {
        cause: Cause.Mismatch(want, got),
        extended: 0,
        message: "column ${i} (`${name}`) holds ${word(got)}; `${verb(want)}` reads ${word(want)}",
        sql: null,
        offset: null,
    }
}

/// The storage class as SQL spells it, and the verb that reads it —
/// the ONE definition each, so the message and the API cannot drift.
fn word(s: Storage) -> string {
    match s {
        .Null -> "NULL", .Integer -> "INTEGER", .Real -> "REAL",
        .Text -> "TEXT", .Blob -> "BLOB",
    }
}

fn verb(s: Storage) -> string {
    match s {
        .Null -> "is_null", .Integer -> "integer", .Real -> "real",
        .Text -> "text", .Blob -> "blob",
    }
}
```

Both are registries over `Storage` with every arm spelled — a `_ ->`
there would silently answer the wrong word for a sixth storage class the
day SQLite grows one (I22).

---

## Part 7 — THE FIVE STORAGE CLASSES

```avra
// [asks: A4 float, A5 bytes]

/// A cell, totally. The one type in which no read can fail, and the
/// escape hatch a caller reaches for when the schema is not trusted.
export enum SqlValue {
    Null
    Integer(v: int)
    Real(v: float)
    Text(v: string)
    Blob(v: bytes)
}
```

### 7.1 INTEGER — free, and better than the field's

Avra's `int` IS i64, so `sqlite3_column_int64` and `sqlite3_bind_int64`
are exact with no conversion and no `safeIntegers` mode. Every JavaScript
and Python binding in the survey has a fidelity flag here; this one has
nothing to configure. Bind the 64-bit forms; do not bind the 32-bit twins.

### 7.2 REAL — `float`, and three named hazards

REAL is IEEE-754 binary64 and `float` is IEEE-754 binary64, so the
round-trip is bit-exact. Three things are not:

> **LAW V1 — `bind_real` REFUSES NaN.** `sqlite3_bind_double` converts NaN
> to **NULL** before writing. So writing `nan` and reading back answers
> absence where a value was written. A value that cannot round-trip is not
> written in silence — the refusal names `to_bits()` as the deliberate
> spelling.

> **LAW V2 — A REAL IS NEVER READ AS TEXT.** SQLite's REAL→TEXT rule
> (3.52.0: round to 15 digits, re-parse, redo at 17 if it differs)
> guarantees round-trip but is not shortest, so `column_text` on a REAL and
> Avra's `${x}` disagree on some values. `column_text` on a REAL is for
> diagnostics only.

> **LAW V3 — A FLOAT COLUMN IS DECLARED `REAL`.** NUMERIC affinity
> converts a float that is exactly an integer INTO an integer, so `3.0`
> written to a `NUMERIC` column reads back with class `Integer` and the
> checked reader refuses — correctly, and confusingly. Affinity rule 4
> (the declared type contains `REAL`, `FLOA` or `DOUB`) forces the float
> representation. The reflection layer refuses a float column declared
> anything else, and names why.

### 7.3 TEXT — and the reason `string` is not enough for BLOB

A `string` is a pointer to a refcounted heap box whose header carries its
length, and whose payload is followed by a NUL that lies OUTSIDE the
recorded length (`2026_09_05_STRING_REPRESENTATION.md`, decided). So
`.length`, `substring`, `char_code`, `trim`, `+`, `join` and `ends_with`
are all length-driven and byte-exact — and a `string` is passable to C as
a `const char*` while still able to hold a NUL of its own.

But `==`, `contains`, `index_of`, `replace`, `split` and `starts_with` go
through `strcmp`/`strstr`/`strncmp`, so **a five-byte value reads equal to
its own two-byte prefix**. A type whose equality lies cannot carry a BLOB.
Hence `bytes` (ask A5), sharing `string`'s box exactly — two types, one
layout, one allocator, one refcount, a different kind tag. It is only
expressible BECAUSE a string is a pointer, which is the same reason the
wall can hand C the payload address of any text with no copy: the SSO the
legacy spec chose would have taxed every short string crossing the
boundary, and this tree decided against it on exactly that ground.

### 7.4 BLOB — `bytes`, and the empty/absent collision

> **LAW V4 — A ROW ANSWERS AN EMPTY BOX FOR EMPTY AND NULL ONLY FOR
> ABSENT.** `sqlite3_column_blob` returns NULL for *three* things: SQL
> NULL, a zero-length blob, and an out-of-memory error. Avra's nullable
> pointer is a niche — absence IS the null pointer — so the null cannot
> carry a second meaning across the boundary. The class is asked first
> (LAW R1), which separates SQL NULL; the empty blob mints a real,
> non-NULL, zero-length box; and OOM is separated by `sqlite3_errcode`
> immediately, in the same frame, with nothing between (LAW R3).

### 7.5 NULL — absence is `T?`, never a sentinel

> **LAW V5 — A NULL NEVER FILLS A NON-NULLABLE SEAT.** No zero, no empty
> string, no `false`. The canonical SQLite data-loss bug is `SUM()` over
> an empty set answering NULL, `column_int` answering `0`, and a balance
> of "no rows" becoming a balance of zero with no diagnostic. `integer(i)`
> on a NULL is a refusal; `integer_or_null(i)` answers `int?`. The type
> the caller wrote decides which happened.

### 7.6 `decimal` — a library type, riding TEXT, and the trap that decides it

Spec 31.3 decides exact base-10 is `BigDecimal` in `@std/numbers`, a
LIBRARY type — not a core value category. The driver agrees and adds one
hard requirement:

> **LAW V6 — A DECIMAL COLUMN IS DECLARED `TEXT`.** A column declared
> `DECIMAL(10,5)` gets NUMERIC affinity (rule 5), and "when text data is
> inserted into a NUMERIC column, the storage class of the text is
> converted to INTEGER or REAL … if the text is a well-formed … literal".
> So binding `'19.99'` into a `DECIMAL(10,5)` column **stores a REAL** and
> the exactness the type exists for is gone on the way IN; `'100.00'`
> stores INTEGER `100` and the scale is gone too. The reflection layer
> refuses `DECIMAL`, `NUMERIC` and `MONEY` as a decimal column's declared
> type and names the reason.

Sorting is `ORDER BY amount COLLATE decimal`, registered from
`ext/misc/decimal.c` — one extra `.c` beside the vendored amalgamation,
which the campaign is already compiling itself.

---

## Part 8 — THE TYPED PATH

### 8.1 The shape, and why it is the receiver that carries `R`

No generic methods, no method-call pins, no associated fns (Part 1). So
the type parameter rides a VALUE the caller holds, and the verbs are that
value's inherent methods — which is the `Arena<N>` / `Table<T>` pattern
this tree already uses everywhere.

```avra
// [today]

/// How a row becomes an `R`, and which columns it needs. One value per
/// row type; the value `@derive Row` will mint (ask A6).
export type Decode<R> = {
    columns: List<string>,
    read: fn(Cursor) -> Result<R, SqlError>,
}
```

A generic struct with a fn-typed field is proven in this tree
(`MatchContext<N>.build`). Threading a bare fn ARGUMENT through a generic
is not — it carries no evidence and pinning over it corrupts scalar
payloads through mono (DOGFOODING). The fn rides inside the struct for
exactly that reason, and the constraint turned out to be the better
design: the columns travel with the reader.

### 8.2 Writing one

```avra
// [today]

export type User = { id: int, name: string, email: string?, score: float }

/// The decode for a `User`. Hand-written today; `@derive Row` writes
/// exactly this from the struct (ask A6).
export fn user_row() -> Decode<User> {
    Decode { columns: ["id", "name", "email", "score"], read: read_user }
}

fn read_user(c: Cursor) -> Result<User, SqlError> {
    User {
        id: c.integer(0)?,
        name: c.text(1)?,
        email: c.text_or_null(2)?,
        score: c.real(3)?,
    }
}
```

Read that decoder against the struct beside it. `email: string?` and
`text_or_null`; `score: float` and `real`. **A field's type and its
reader's verb are the same statement written twice, adjacent, in five
lines** — which is precisely why a derive can write it, and precisely
what a compile-time checker will compare against `sqlite3_column_decltype`
and the NOT NULL bit (Part 13).

### 8.3 The verbs

```avra
// [today]
impl Decode<R> {
    /// Every row, decoded. Materialises — and says so.
    fn all(db: Db, q: Sql) -> Result<List<R>, SqlError>

    /// The first row, or absence. Steps once and stops.
    fn first(db: Db, q: Sql) -> Result<R?, SqlError>

    /// Exactly one row: absence and a second row are both refusals.
    /// The shape a primary-key lookup wants, so no caller writes
    /// `.first()!`.
    fn one(db: Db, q: Sql) -> Result<R, SqlError>

    /// A live typed cursor. Nothing is materialised and the statement
    /// is held for as long as the value is (Part 10).
    fn over(db: Db, q: Sql) -> Result<Rows<R>, SqlError>

    /// The SELECT list this decode names — `"id, name, email, score"`.
    /// A query builder's column clause, and the string a compile-time
    /// checker compares against `sqlite3_column_name` (Part 13).
    fn select() -> string { self.columns.join(", ") }
}
```

```avra
// [today]
let everyone = user_row().all(db, sql("SELECT id, name, email, score FROM users"))?

let one = user_row().one(db, sql("SELECT id, name, email, score FROM users WHERE id = ?").integer(7))?

let d = user_row()
let best = d.first(db, sql("SELECT ${d.select()} FROM users ORDER BY score DESC LIMIT 1"))?
```

The third line is the shape the ORM inherits: the decode names its own
columns, so the SELECT list and the reader cannot drift. It is also the
one place this design tolerates SQL built by interpolation, and it is
tolerable because the interpolated text is a *list of identifiers the
decode owns*, never a value — CLAUDE.md's "A COMMAND IS AN ARGV, never a
shell line", one level down.

### 8.4 What the reading reads like, whole

```avra
// [today]
fn leaderboard(db: Db, city: string, floor: float) -> Result<List<User>, SqlError> {
    user_row().all(db, sql("""
        SELECT id, name, email, score
        FROM users
        WHERE city = :city AND score >= :floor
        ORDER BY score DESC
    """).set(":city", .Text(city)).set(":floor", .Real(floor)))
}
```

Nine lines, no ceremony, every value typed, no index typed, no lifetime to
reason about, and the failure channel is one `?` at the call site above.

### 8.5 The untyped path, at the same power (P8)

```avra
// [today]
impl Db {
    /// Every row, as rows. For a report, an aggregate, a `GROUP BY` —
    /// the queries that are not entity-shaped, which is most of them.
    fn all(q: Sql) -> Result<List<Row>, SqlError>
    fn first(q: Sql) -> Result<Row?, SqlError>
    /// A live cursor over any statement (Part 11).
    fn over(q: Sql) -> Result<Cursor, SqlError>
    /// Run a statement that yields no rows; answer what changed.
    fn run(q: Sql) -> Result<int, SqlError>
    /// The one-cell shorthands, which every report needs.
    fn one_integer(q: Sql) -> Result<int, SqlError>
    fn one_text(q: Sql) -> Result<string, SqlError>
    fn one_real(q: Sql) -> Result<float, SqlError>
}
```

```avra
// [today]
fn print_cities(db: Db) -> Result<int, SqlError> {
    let rows = db.all(sql("SELECT city, count(*), avg(score) FROM users GROUP BY city"))?
    for r in rows {
        println("${r.text(0)?} ${r.integer(1)?} ${r.real(2)?}")
    }
    rows.length
}
```

A `Row` is a `Cells`, so **the untyped path uses the same thirteen verbs
as the typed one.** An escape hatch at lower power than the main road is
the wart every ORM in the field grows (`@Query(nativeQuery=true)`); here
there is no second vocabulary to learn.

### 8.6 `run` and RETURNING — classified by the statement, never by its verb

> **LAW Q1 — WHETHER A STATEMENT YIELDS ROWS IS `sqlite3_column_count`,
> ASKED AT PREPARE TIME.** Never the leading verb. `INSERT … RETURNING`
> yields rows; `sqlite3_stmt_readonly` is false for it and true for
> `BEGIN` but false for `BEGIN IMMEDIATE`. A driver that splits `exec`
> from `query` by sniffing the SQL breaks on RETURNING and forces the ORM
> to special-case (ORM §1.5). `db.run` on a row-yielding statement is a
> refusal that names `all`; `all` on a row-less statement answers `[]`.

> **LAW Q2 — RETURNING'S ROWS ARRIVE IN ARBITRARY ORDER.** A multi-row
> `INSERT … RETURNING` cannot be zipped positionally against its input.
> The doc says so at the verb, because the ORM's algorithm depends on it:
> match by primary key, which means RETURNING must include the PK.

---

## Part 9 — TRANSACTIONS AND SAVEPOINTS

### 9.1 The value

```avra
// [asks: A1 drop]

/// An open transaction or savepoint. Its DROP rolls back — so a `Tx`
/// that leaves scope uncommitted cannot leave a half-applied write
/// visible, and there is no path on which a caller forgets.
opaque type Tx

impl Tx {
    /// COMMIT at depth 0, RELEASE inside. A `SQLITE_BUSY` from COMMIT
    /// is retried under the connection's busy policy and, if it still
    /// fails, the transaction is ROLLED BACK rather than left open
    /// (LAW X5). Answers the rows the transaction changed.
    fn commit() -> Result<int, SqlError>

    /// ROLLBACK at depth 0, `ROLLBACK TO` + `RELEASE` inside — because
    /// `ROLLBACK TO` does not pop the savepoint, and a nesting that
    /// treats it as a pop leaks a stack entry per failed inner block
    /// (LAW X6). Asks `sqlite3_get_autocommit` first and does nothing
    /// when SQLite has already rolled back for us (LAW X4).
    fn rollback() -> Result<int, SqlError>

    /// A nested block, as a SAVEPOINT one level deeper. The name is
    /// MINTED from this Tx's depth and is never the caller's: a
    /// savepoint name is an IDENTIFIER, not a bindable parameter, so a
    /// caller-supplied name is a SQL injection with no `?` to close it.
    fn nested() -> Result<Tx, SqlError>

    /// The depth, for a caller that wants to know. 0 is not a Tx.
    fn depth() -> int
}

impl Db {
    /// `BEGIN IMMEDIATE` — the write lock taken at the BEGIN, so a
    /// writer discovers contention now rather than at its first write
    /// with work already done.
    fn write() -> Result<Tx, SqlError>

    /// `BEGIN DEFERRED` — a read snapshot.
    fn read() -> Result<Tx, SqlError>

    /// Whether this connection is outside a transaction, asked of
    /// SQLite rather than tracked (LAW X3).
    fn autocommit() -> bool
}
```

### 9.2 What it reads like

```avra
// [asks: A1]
fn transfer(db: Db, from: int, to: int, amount: int) -> Result<int, SqlError> {
    let tx = db.write()?
    db.run(sql("UPDATE accounts SET cents = cents - ? WHERE id = ?").integer(amount).integer(from))?
    db.run(sql("UPDATE accounts SET cents = cents + ? WHERE id = ?").integer(amount).integer(to))?
    tx.commit()
}
```

Four lines. Both `?`s are early exits, so `tx` drops on the way out and
rolls back. Nothing to balance, nothing to remember, and the `BEGIN` and
`COMMIT` are still visible words the reader can point at (P7).

Nesting is a value, not a hidden counter:

```avra
// [asks: A1]

/// Import what can be imported: each row gets its own savepoint, so one
/// bad row rolls back to the row before it and the batch continues.
fn import_batch(db: Db, tx: Tx, rows: List<Row>) -> Result<int, SqlError> {
    mut ok = 0
    for r in rows {
        ok = ok + one_row(db, tx.nested()?, r)
    }
    ok
}

/// One row under its own savepoint: 1 when it landed, 0 when the
/// savepoint took the damage. `sp` drops at the end of this fn either
/// way, so the frame is exactly one row's.
fn one_row(db: Db, sp: Tx, r: Row) -> int {
    let n = insert_one(db, r) catch 0
    if n == 0 { return 0 }
    sp.commit() catch 0
}
```

The savepoint's frame is a FUNCTION, not a block, because a `Tx`'s
lifetime is its value's and a value's lifetime is its scope's. That is
the same discipline CLAUDE.md states for `defer`: the frame is the thing
you can point at.

### 9.3 Why no `db.tx(() -> …)` combinator, and what it costs

The affordance every survey praises (better-sqlite3, `bun:sqlite`,
GRDB) is `db.transaction(fn)`. It cannot be written here:

- it must be **generic in the body's answer**, and the answer's only
  evidence would ride a **fn-typed argument** — which carries no evidence,
  and pinning `<T>` over one **corrupts scalar payloads through mono**
  (DOGFOODING, "Generics: what infers, what needs pins"). So
  `write<int>(db, (d) -> …)` is not merely unavailable, it is the
  corrupting case;
- a body that accumulated into a captured local would write to a **copy**
  (F3005), so the accumulate-in-the-block idiom does not survive the
  translation anyway;
- and `db.tx { … }` — trailing-lambda — does not parse (probe log Part II).

**Wanting site: `Tx`, Part 9.** The ask is A7 (a generic answer through a
fn-typed argument) and it is a mono defect the tree already names, not a
sugar want. Until it lands, the bracket above is the whole story — and it
is, honestly, the better fit for LAW R3: a combinator's cleanup is a
frame's, and a frame's cleanup runs on the way out of every `?`.

### 9.4 The failure laws, stated at the verb

> **LAW X4 — SOME ERRORS ROLL BACK BY THEMSELVES.** `SQLITE_FULL`,
> `SQLITE_IOERR`, `SQLITE_BUSY`, `SQLITE_NOMEM`, `SQLITE_INTERRUPT` *might*
> roll the transaction back. A wrapper that issues `ROLLBACK`
> unconditionally then gets "cannot rollback — no transaction is active"
> on top of the real error and reports THAT. `Tx.rollback` asks
> `get_autocommit` first.

> **LAW X5 — `COMMIT` CAN FAIL WITH BUSY AND LEAVE THE TRANSACTION OPEN.**
> Treating a failed commit as "over" leaks an open write transaction for
> the life of the connection, blocking every other writer, until the
> connection closes and the work is silently lost. `Tx.commit` retries
> under the busy policy and rolls back if it still fails.

> **LAW X9 — A TRAP IS NOT A ROLLBACK PATH.** `avra_trap` exits 2 and
> nothing after it runs, so no drop and no `defer` executes. That is
> enough: the process leaves a hot journal or an uncheckpointed WAL and the
> next connection recovers. The failure to avoid is the opposite one — a
> wrapper that catches a trap and continues, leaving a half-applied
> transaction visible to the same process. **This package has no such
> path.**

---

## Part 10 — PREPARED STATEMENTS, REUSE, AND THE CACHE

### 10.1 Prepared

```avra
// [asks: A1, A2]

/// One compiled statement. `mut` because stepping it moves SQLite's
/// cursor: the receiver is written, and the compiler should say so.
opaque type Prepared

impl Db {
    /// Compile once. `sqlite3_prepare_v3` with `SQLITE_PREPARE_PERSISTENT`
    /// when the statement is going into a cache — v2/v3 also re-compile
    /// automatically on a schema change, so `SQLITE_SCHEMA` never reaches
    /// a caller (LAW S1).
    fn prepare(source: string) -> Result<Prepared, SqlError>
}

impl Prepared {
    /// Reset, clear, bind, step to DONE. The reuse ritual is ONE verb:
    /// a statement left un-reset holds a read transaction open, and
    /// skipping `clear_bindings` leaves a stale value in a slot the next
    /// caller does not bind, which SQLite will silently use.
    mut fn run(a: Sql) -> Result<int, SqlError>

    /// Reset, clear, bind, step once; the row or absence.
    mut fn first(a: Sql) -> Result<Row?, SqlError>

    /// Reset, clear, bind, and hand back a live cursor (Part 11).
    mut fn over(a: Sql) -> Result<Cursor, SqlError>

    /// What the statement says about itself, before any step (Part 13).
    fn describe() -> StmtInfo

    /// The raw `sqlite3_stmt*` — the escape hatch (P8).
    fn handle() -> ptr
}
```

```avra
// [asks: A1]
fn insert_all(db: Db, people: List<User>) -> Result<int, SqlError> {
    let tx = db.write()?
    mut ins = db.prepare("INSERT INTO users(name, email, score) VALUES(?, ?, ?)")?
    mut n = 0
    for u in people {
        n = n + ins.run(args().text(u.name).value(email_value(u.email)).real(u.score))?
    }
    let _ = tx.commit()?
    n
}
```

One compile, N binds, one fsync. That is the fast path in the field and
it is four lines here.

### 10.2 The cache, named by the verb

```avra
// [asks: A1]

/// A bounded, caller-held statement cache. It holds `Db` and `Prepared`s;
/// `Db` holds NEITHER, which is what keeps the connection's refcount
/// able to reach zero (Part 3.3). A cache with no bound cannot be
/// constructed.
export type Held = { key: string, stmt: Prepared }
export type Cache = { db: Db, cap: int, held: List<Held> }

export fn cache(db: Db, cap: int) -> Cache

impl Cache {
    /// Prepared once per SQL text, evicted least-recently-used at `cap`;
    /// eviction finalizes. `db.all(…)` prepares fresh — the verb says
    /// which you got.
    mut fn all(q: Sql) -> Result<List<Row>, SqlError>
    mut fn run(q: Sql) -> Result<int, SqlError>
    mut fn clear() -> int
}
```

> **LAW C1 — A CACHED STATEMENT'S SHAPE IS NOT CACHED.** `prepare_v2`/`v3`
> silently re-prepare on a schema change, and the column count, the names
> and the decltypes can all change across that re-prepare (LAW S21). The
> statement is keyed on its text and nothing else; anything DESCRIBED
> about it is keyed on `PRAGMA schema_version`.

---

## Part 11 — STREAMING A LARGE RESULT SET

### 11.1 The collapse: Avra can have the loop that Rust cannot

Every binding in the survey streams with a callback or an iterator, and
each pays for it: rusqlite's `Rows` cannot be an `Iterator` because the row
borrows the statement; better-sqlite3 leaves the connection "busy" if an
iterator is abandoned; SeaORM's stream "exclusively holds onto the
connection until dropped". The prior art's conclusion was *streaming is a
fold, not an iterator*.

**In Avra it is neither, and the reason is this design's own copy rule.**
A `Cursor`'s reads COPY (LAW S12 forces it), so nothing a caller holds
points into SQLite's buffers. The borrow that forces a callback elsewhere
does not exist here. So the streaming primitive is the loop:

```avra
// [asks: A1]
fn total_score(db: Db) -> Result<float, SqlError> {
    mut rows = db.over(sql("SELECT score FROM users"))?
    mut total = 0.0
    while rows.step()? {
        total = total + rows.real(0)?
    }
    total
}
```

- Nothing is materialised. One statement, N steps, zero row allocations.
- The accumulator is an ordinary `mut` local — no capture, no copy, no
  `F3005`.
- No generic answer crosses a fn-typed argument, so the mono defect
  (A7) is never touched.
- `rows` holds the statement; the statement holds the connection; the
  drop at the end of the fn finalizes and releases in that order.

`Cursor` is a `Cells`, so `rows.real(0)` is the same verb as everywhere
else in this document.

### 11.2 Typed streaming

```avra
// [today, given A1]

/// A live typed cursor: a statement plus the decode that reads it.
export type Rows<R> = { cursor: Cursor, decode: Decode<R> }

impl Rows<R> {
    /// Advance. `false` at DONE.
    mut fn step() -> Result<bool, SqlError>
    /// Decode the CURRENT row. Valid only between two `step`s — and the
    /// value it answers is not, because decoding copies.
    fn row() -> Result<R, SqlError>
}
```

```avra
// [asks: A1]
fn highest(db: Db) -> Result<User?, SqlError> {
    mut rows = user_row().over(db, sql("SELECT id, name, email, score FROM users"))?
    mut best: User? = null
    while rows.step()? {
        let u = rows.row()?
        if best == null || u.score > best!.score { best = u }
    }
    best
}
```

`Rows<R>` is a generic struct with an inherent generic impl — the
`Table<T>` pattern, proven in `core/table.av`. **The receiver carries `R`,
so no pin is written and no generic method is needed.**

### 11.3 The hazard, named at the verb

> **LAW S23 — AN OPEN STATEMENT HOLDS A READ TRANSACTION.** A second query
> on the same connection while a cursor is open sees the older snapshot or
> contends on a write. Every ORM in the survey documents this; the doc
> comment on `over` says it, and `all` exists so the caller who does not
> want it does not get it. `all` materialises **and its name says so** —
> the cost is in the word (P7).

---

## Part 12 — THE ESCAPE HATCH: the raw wall, spelled

```avra
// [asks: A2, A3, A4] — packages/std-sqlite/src/wall.av, in full,
// mechanically. NOTE THE DIRECTION ASYMMETRY: a `string` may go OUT
// (an Avra box's payload is NUL-terminated — `str_box` allocates n + 1 —
// so it IS a `const char*`), and may never come BACK (WALL LAW 1).

export extern fn sqlite3_open_v2(path: string, mut db: ptr, flags: int, vfs: ptr) -> int
export extern fn sqlite3_close_v2(db: ptr) -> int
export extern fn sqlite3_prepare_v3(db: ptr, sql: string, n: int, flags: int, mut stmt: ptr, mut tail: ptr) -> int
export extern fn sqlite3_step(stmt: ptr) -> int
export extern fn sqlite3_reset(stmt: ptr) -> int
export extern fn sqlite3_finalize(stmt: ptr) -> int
export extern fn sqlite3_column_count(stmt: ptr) -> int
export extern fn sqlite3_column_type(stmt: ptr, col: int) -> int
export extern fn sqlite3_column_int64(stmt: ptr, col: int) -> int
export extern fn sqlite3_column_double(stmt: ptr, col: int) -> float
export extern fn sqlite3_column_text(stmt: ptr, col: int) -> ptr
export extern fn sqlite3_column_blob(stmt: ptr, col: int) -> ptr
export extern fn sqlite3_column_bytes(stmt: ptr, col: int) -> int
export extern fn sqlite3_errcode(db: ptr) -> int
export extern fn sqlite3_extended_errcode(db: ptr) -> int
export extern fn sqlite3_errmsg(db: ptr) -> ptr
export extern fn sqlite3_error_offset(db: ptr) -> int
// … and every other public entry point, one line each.
```

### 12.1 The four rules the wall obeys, and they are general FFI law

> **WALL LAW 1 — AN EXTERN NEVER DECLARES `string` OR `bytes` AS ITS
> ANSWER.** A foreign `const char*` typed as `string` works today by
> accident: `hdr` refuses the untagged pointer so retain and release
> no-op, and `str_len` falls back to `strlen`. That belt holds only for
> text that is IMMORTAL and NUL-TERMINATED, and it hides exactly the three
> cases a driver is made of — text with a lifetime, bytes, and text
> holding a NUL. **And `AVRA_RC_GUARD` cannot see any of them**: it watches
> retain and release EVENTS, and an untagged pointer raises none, so it
> prints clean for a correct borrow and a use-after-free alike. The wall
> answers `ptr`, and Avra text and bytes are minted from a `(ptr, len)`
> pair by ONE copying verb.

> **WALL LAW 2 — A STATUS PLUS AN OUT-PARAM IS A `Result`.** C splits one
> answer in two because C has no sum type. Avra has the type that reunites
> them. Spec 15.4 stops at annotating the parameter and then writes
> `sqlite3_open_wrapped` in its own example, conceding a hand-written
> wrapper per function; going one step further — the compiler projecting
> `(status, mut out T)` straight to `Result<T, E>` at the declaration —
> deletes that layer **for every C library, not just this one**. Ask A2.

> **WALL LAW 3 — A DESTRUCTOR SENTINEL IS NOT A CALLBACK.** Fourteen
> functions take an `xDel` pointer, and only two values of it are ever
> used: `SQLITE_STATIC` (`(void*)0`) and `SQLITE_TRANSIENT` (`(void*)-1`).
> They are spelled as `ptr` sentinels and need no trampolines. Binding
> uses `SQLITE_TRANSIENT` in v1, always; `SQLITE_STATIC` becomes legal the
> day a `Prepared` holds its bound `bytes` in a field until finalize or a
> rebind — at which point the language's own counting discharges SQLite's
> lifetime clause, and the type system proves what a comment would have
> asserted.

> **WALL LAW 4 — THE VARIADICS ARE OP-DISPATCH, NOT VARIADIC.**
> `sqlite3_config` / `db_config` / `vtab_config` are a fixed set of
> `(op, …)` overloads. The right binding is **one narrow monomorphic
> extern per argument shape against the same C symbol**, not a variadic.
> The printf family is not bound at all: Avra has interpolation, and
> SQLite's printf exists to build SQL by concatenation, which a
> parameter-binding driver never does.

### 12.2 How a caller reaches it

```avra
// [asks: A1]
use @std.sqlite.{Db, sqlite3_db_config, sqlite3_stmt_status}

fn tighten(db: Db) -> int {
    sqlite3_db_config_int(db.handle(), dbconfig_dqs_ddl(), 0)
}
```

`db.handle()` and `prep.handle()` are the two doors, and there are only
two. The wall is `export`ed from the package root, so one import brings
the whole C surface into scope: a binding that offers only the pretty
layer is a binding people abandon at their first unusual requirement, and
one that offers only the wall is one they wrap. **Both, layered, and most
callers never leave the top.**

---

## Part 13 — DESCRIBE, AND WHAT THE ORM BUILDS ON

### 13.1 `describe` — the verb the whole later story hangs from

```avra
// [today, given A1]

export type ColumnInfo = {
    name: string,
    decltype: string?,
    origin: Origin?,
}

/// Which REAL column a result column came from. ONE optional, not three:
/// SQLite answers NULL for all three at once (a result column is either a
/// table column or it is an expression), so three nullable fields would be
/// three levels of absence for one fact — the collapse CLAUDE.md's own
/// `Frame`/`Loc` lesson names, and it deletes a mapping match at every
/// construction and every read.
export type Origin = { database: string, in_table: string, column: string }

export type StmtInfo = {
    params: List<string?>,
    columns: List<ColumnInfo>,
    readonly: bool,
}

impl Db {
    /// Prepare, read everything a statement says about itself, finalize.
    /// NEVER steps — preparing DDL does not run it and preparing DML does
    /// not execute it, which is exactly what makes this safe to run at
    /// COMPILE time (Part 13.3).
    fn describe(source: string) -> Result<StmtInfo, SqlError>
}
```

`Origin` is the `SQLITE_ENABLE_COLUMN_METADATA` payload: it is join
hydration, writable-result-set identity, and nullability inference for raw
SQL — the single largest quality delta in the ORM report's ranking, and it
is unreachable on macOS's system SQLite, which is one of the two reasons
the amalgamation is vendored.

(The field is `in_table`, not `table`, because `table` is a reserved word
in this tree — the `table<Row> { … }` literal claims it, and it refuses as
a field name. Recorded here rather than discovered later.)

> **THE CEILING, PUBLISHED.** SQLite will tell you a parameter's *arity*
> and never its *type*. A compile-time checker can verify column names,
> column count and result types; for parameters it can verify only how
> many. Inferring a parameter's type from its syntactic position is the
> ORM's job, above this seam. This is stated in the driver's own docs so
> the ORM is not designed as if it were absent.

### 13.2 Reflection: below the line, because it is facts about SQLite

Since 3.16.0 every side-effect-free pragma is also a table-valued
function, so reflection needs **no new C entry point** — it is a query,
and the driver grows nothing:

```avra
// [today, given A1]
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
columns, and a migration diff that cannot see a generated column will try
to add it. The schema argument is always passed: `PRAGMA table_info`
resolves across attached databases implicitly, and SQLAlchemy carries a
bug for exactly that.

`foreign_key_list`'s own column names are `table`, `from` and `to`; they
become `parent`, `child_column` and `parent_column` — partly because
`table` is reserved, and mostly because *"from"* and *"to"* on a foreign
key are ambiguous in the direction that matters, and every ORM that keeps
the pragma's names re-explains them in a comment.

### 13.3 The line the ORM sits above, and the four shapes it inherits

**BELOW (this package):** connection, statement, values with their
storage class readable, describe, transactions and savepoints,
`last_insert_rowid`/`changes64`, typed errors with the extended code and
the byte offset, reflection records, blob streaming, serialize/deserialize,
backup, the statement cache, the parameter limit.

**ABOVE (the ORM):** the schema model, SQL generation, type mapping
beyond the five storage classes, identity, change tracking, relations,
migrations, validation, the further projections.

**The four shapes this design chose so that layer is a small step, not a
rewrite:**

1. **`Decode<R>` is a VALUE with a `columns` list.** A derive that reads a
   struct writes it mechanically; a checker that reads it can compare the
   names against `sqlite3_column_name` with no SQL parser anywhere.
2. **`Sql` is a struct built from a STRING LITERAL at the call site**, and
   the args are typed and counted. So arity checking is a pass over one
   literal — the "nearly free" first rung — and full checking is the same
   pass with a schema beside it.
3. **`SqlError.offset` is a byte offset into that literal.** Added to the
   literal's own span it is a *span in the user's `.av` file*. The
   diagnostic underlines the exact word in the SQL, with an F-code, a help
   line and a structured fix. Nothing in the field points at the character.
4. **Nothing above `sql("…")` changes when the check lands.** The v2 form

   ```avra
   // [v2]
   let q = sql"SELECT id, name, email, score FROM users WHERE id = ?".integer(7)
   let u = user_row().one(db, q)?
   ```

   answers the same `Sql` value the fn call answers today. The checker is a
   compiler pass over two literals; the runtime path is byte-identical.

**And the thing nobody else has.** All four systems in the field are
out-of-band: sqlx needs a live database at build time, sqlc a generated
artifact, jOOQ a codegen step, Kysely a hand-kept TypeScript mirror. Avra's
compiler links SQLite itself, so it can open `:memory:`, run the package's
own migrations, `prepare_v3` the query, read the describe and finalize —
**never step**. That is sqlx's fidelity with sqlc's hermeticity, using the
*same engine that will run the query in production*, which sqlc's
hand-written Go parser structurally cannot promise.

### 13.4 The five things the ORM cannot add later

Stated here because they are this package's obligations and nobody else's:
typed values **including `float` and `bytes`**; a **describe that runs
before any row exists**; **savepoints**; an error naming its **extended
code and byte offset**; and the **storage class readable per value**.
Everything else can be built above the seam.

---

## Part 14 — INCREMENTAL BLOB I/O

```avra
// [asks: A1, A5]

/// One BLOB as a byte stream. A large value that need not be a value.
opaque type Stream @free_with(sqlite3_blob_close)

impl Db {
    /// Open one cell as a stream. `writable` false opens read-only.
    fn open_blob(schema: string, of_table: string, column: string, rowid: int, writable: bool) -> Result<Stream, SqlError>
}

impl Stream {
    fn length() -> int
    /// `n` bytes at `at`. The handle CANNOT change the value's size:
    /// a shorter or longer write is an `UPDATE`, and reading or writing
    /// past `length()` is a refusal, not a truncation.
    fn read(at: int, n: int) -> Result<bytes, SqlError>
    /// Answers the count written — `Result<void, E>` is refused (F2019),
    /// so a writing verb answers what it wrote.
    mut fn write(at: int, b: bytes) -> Result<int, SqlError>
    /// Move to the same column of another row. Cheaper than reopening.
    mut fn move_to(rowid: int) -> Result<int, SqlError>
}
```

> **LAW B1 — A BLOB HANDLE EXPIRES WHEN ITS ROW IS MODIFIED**, and the
> next call answers `SQLITE_ABORT`. That is a `Cause.Other(4)` today; it
> deserves its own variant, and the design gives it one:
> `Cause.Expired`, because "your handle is stale, reopen it" is a
> different action from every other failure.

`Stream.read` needs a WRITABLE box, and `bytes` is immutable by design.
The shape is small and it is BLOCKER 3 below: one row that mints a
zero-filled box of `n` bytes and one that borrows its payload address, with
the write sound only while the box is uniquely referenced — which it is at
the moment of minting, and which the language cannot yet PROVE.

---

## Part 15 — THE DAY IN THE PERFECT WORLD

One program, whole. Every gap closed; nothing marked.

```avra
//! A leaderboard service's data layer, whole.
use @std.sqlite.{Db, Sql, SqlValue, Cursor, Decode, SqlError, open_with, sql, Config}

export type User = { id: int, name: string, email: string?, score: float, avatar: bytes? }

fn user_row() -> Decode<User> {
    Decode { columns: ["id", "name", "email", "score", "avatar"], read: read_user }
}

fn read_user(c: Cursor) -> Result<User, SqlError> {
    User {
        id: c.integer(0)?,
        name: c.text(1)?,
        email: c.text_or_null(2)?,
        score: c.real(3)?,
        avatar: c.blob_or_null(4)?,
    }
}

fn schema() -> string {
    """
    CREATE TABLE IF NOT EXISTS users (
        id     INTEGER PRIMARY KEY,
        name   TEXT NOT NULL,
        email  TEXT,
        score  REAL NOT NULL DEFAULT 0.0,
        avatar BLOB,
        city   TEXT NOT NULL
    )
    """
}

export fn connect(path: string) -> Result<Db, SqlError> {
    let db = open_with(path, Config { })?
    let _ = db.run(sql(schema()))?
    db
}

export fn add(db: Db, name: string, email: string?, score: float, city: string) -> Result<User, SqlError> {
    let tx = db.write()?
    let made = user_row().one(db, sql("""
        INSERT INTO users(name, email, score, city) VALUES(?, ?, ?, ?)
        RETURNING id, name, email, score, avatar
    """).text(name).value(email_value(email)).real(score).text(city))?
    let _ = tx.commit()?
    made
}

fn email_value(e: string?) -> SqlValue {
    if e == null { return SqlValue.Null }
    SqlValue.Text(e!)
}

export fn top(db: Db, city: string, n: int) -> Result<List<User>, SqlError> {
    user_row().all(db, sql("""
        SELECT id, name, email, score, avatar
        FROM users WHERE city = :city
        ORDER BY score DESC LIMIT :n
    """).set(":city", .Text(city)).set(":n", .Integer(n)))
}

/// The whole table's mean, streamed — nothing materialised, one
/// allocation for the statement and none per row.
export fn mean_score(db: Db) -> Result<float, SqlError> {
    mut rows = db.over(sql("SELECT score FROM users"))?
    mut total = 0.0
    mut seen = 0
    while rows.step()? {
        total = total + rows.real(0)?
        seen = seen + 1
    }
    if seen == 0 { return 0.0 }
    total / seen.to_float()
}

/// A failure reads as a decision, and the message points at the word.
export fn report(e: SqlError) -> string {
    match e.cause {
        .Constraint(.Unique) -> "that email is already taken",
        .Constraint(.NotNull) -> "a required field was empty",
        .Constraint(_) -> "the database refused it: ${e.message}",
        .Busy(.Snapshot) -> "conflicted — retry the whole transaction",
        .Busy(_) -> "busy, try again",
        .Syntax -> "the query is malformed at byte ${e.offset ?? 0}: ${e.message}",
        .Mismatch(_, _) -> "the schema and the row type disagree: ${e.message}",
        .Expired -> "that blob handle is stale — reopen it",
        .ReadOnly(_) or .Corrupt or .NotFound or .Full or .Interrupted or
        .Range or .Auth or .Io(_) or .Misuse or .Other(_) -> e.message,
    }
}
```

Read it once for ceremony. There is a `Config { }`, a `?` per fallible
call, one `tx` line and one `commit` line, and five reader verbs whose
names are the storage classes. There is no cursor lifetime, no index
arithmetic, no `NULL` sentinel, no connection string, no pool, no ORM, no
codegen step and no generated file.

---

## Part 16 — THE PACKAGE

```
packages/std-sqlite/
  avra.toml                 [link] objects = the vendored sqlite3.o (+ decimal.o)
  vendor/sqlite3.c          3.53.4, 269,649 lines, our flags
  vendor/sqlite3.h
  vendor/decimal.c          ext/misc — the `decimal` collation for LAW V6
  src/
    sqlite.av               the face: Db, Sql, Cells, Cursor, Row, Decode, Tx
    wall.av                 one `export extern fn` per C entry point (Part 12)
    codes.av                the result-code registry — a `table<CodeRow>`
    reflect.av              the pragma records (Part 13.2)
    tests/
      sqlite_test.av        the unit tier: no database at all
      memory_test.av        `:memory:`
      file_test.av          a real file under TMPDIR
      schema_test.av        a real schema, describe, reflection
      adversarial_test.av   the red-team catalogue
corpus/
  sqlite.av + .expected     eval == native, once the extern host lands
```

**One import brings the whole surface**, face and wall together, because
the wall is part of the package's root module rather than a sub-module a
caller has to discover:

```avra
use @std.sqlite.{Db, Sql, Decode, SqlError, open, sql}                 // the face
use @std.sqlite.{sqlite3_db_config_int, sqlite3_stmt_status}           // the wall
```

The result codes are a `table<CodeRow>` — a registry, iterated in one
direction to name a code and queried in the other to classify one, which
is exactly when I10 says a mapping is DATA rather than a `match`:

```avra
// [today]
export type CodeRow = { code: int, name: string, cause: Cause }

fn codes() -> List<CodeRow> {
    let rows = table<CodeRow> {
        code | name                          | cause
        2067 | "SQLITE_CONSTRAINT_UNIQUE"    | Cause.Constraint(Violation.Unique)
        1299 | "SQLITE_CONSTRAINT_NOTNULL"   | Cause.Constraint(Violation.NotNull)
        787  | "SQLITE_CONSTRAINT_FOREIGNKEY"| Cause.Constraint(Violation.ForeignKey)
        517  | "SQLITE_BUSY_SNAPSHOT"        | Cause.Busy(Busy.Snapshot)
        // … one row per extended code the design names
    }
    rows
}
```

A cell holds an enum value, which the tree's table literal already
carries (`BinOp.Add` in DOGFOODING's operator table). The 37 I/O codes get
no rows: the driver keeps the NUMBER and renders the name from
`sqlite3_errstr`, because none of them changes what the caller does.

---

## BLOCKERS

Things that stop this design from being written at all. Each names the
evidence and a proposed shape. Ordered by what must land first; every one
is already recorded in the campaign's own checklist, and these entries add
only what THIS design requires of them.

### BLOCKER 1 — An `opaque type` must bear methods, or the whole face has nowhere to live

`opaque type Db` is `F0100: expected BREAK`. The campaign already owns
that. **What this design adds:** the opaque type must answer
`Callee.Declared` (`features/impls/callee.av:58-67`), because every verb in
this document is `impl Db { … }`, `impl Prepared { … }`, `impl Tx { … }`.
An opaque type that is a bare pointer with no impl table would give a
correct handle and no API.

**PROPOSED SHAPE.** A single-field record of one pointer already rides as
the pointer, already bears methods, and already crosses an extern seat as
`RtKind.Ptr`. So `opaque type T @free_with(f)` is `type T = { raw: ptr }`
plus (a) a drop hook on the declaration, (b) field privacy outside the
declaring package, (c) a `handle()` verb as the spelled escape hatch.
**The ask reduces to a drop hook on a declared type** — which the
`Tx`-rolls-back-on-drop and `Cache`-evicts-by-finalize designs both need,
and which no other feature in the tree has asked for yet.

### BLOCKER 2 — No out-params on an extern; nothing runs

`extern fn f(p: string, mut out: ptr) -> int` is `F0100: expected ')'`.
`sqlite3_open_v2` and `sqlite3_prepare_v3` answer their handles through a
`T**` and SQLite offers no variant that returns the handle directly. The
cause is one line: `features/fns/mod.av:32` (extern) is a narrower copy of
`:33` (fn) — it lacks `( mk:"mut" )?`. No workaround is permitted and none
exists: a one-element `List<int>` hands C the `AvraArray` pointer whose
FIRST FIELD IS THE CAPACITY.

**PROPOSED SHAPE.** Two halves. Syntactic: align the two grammar rules.
Semantic: a `mut` seat on an extern lowers to *the address of the caller's
slot*. And then the collapse — `(status, mut out T) -> Result<T, E>`
projected at the declaration, which deletes a hand-written wrapper per
function for every C library.

### BLOCKER 3 — No `bytes`, so BLOB has no representation and `Stream.read` has no buffer

`let b: bytes = "hi"` is `F2001`. `string` is a headered byte box but
`==`, `contains`, `index_of`, `replace`, `split` and `starts_with` all go
through C string calls, so a blob compares equal to its own truncation.

**PROPOSED SHAPE.** A distinct type `bytes` sharing `string`'s box exactly:
same allocator, same header, same refcount, `KIND_BYTES`. Thirteen runtime
rows, no new IR instruction. **What THIS design adds:** `Stream.read` needs
a WRITABLE box — `bytes.zeroed(n)` plus `avra_bytes_ptr(b)` — and that
write is sound only while the box is uniquely referenced, which it is at
the moment of minting and which the language cannot yet prove. It is the
one place this design's immutability is bent, and it should land with a
named voice rather than a comment.

### BLOCKER 4 — No `float`, so REAL has no home

`let x: float = 1.0` is `F0100` pointing AT the `.` — the lexer has no
float literal, so the gap starts before the type surface. Four SQLite
functions take or answer a `double` and two of them are on the spine.
`RtKind` is `I64 | Ptr | Void`, so the ABI cannot carry one either.

**PROPOSED SHAPE.** Spec 31.2, verbatim: `float` is binary64, no implicit
int↔float conversion, IEEE comparison, a literal that must carry a point or
an exponent. The literal's payload is the BIT PATTERN as an `int`, so the
standing binary and `bootstrap/seed.ll` can carry it and the self-hosting
chain is never broken.

### BLOCKER 5 — `Result<void, E>` is refused, and this package is full of writing verbs

`F2019` — "a `Result` slot cannot hold this yet". `Tx.commit`,
`Stream.write`, `Cache.clear` and `Prepared.run` all only succeed or fail.

**TODAY'S SHAPE, and it is not a bad one:** a writing verb answers what it
wrote — `commit` the rows changed, `write` the bytes written, `clear` the
statements finalized. `@std/io`'s `write_text` answers its path for the
same reason. The cost is real anyway: `let _ = tx.commit()?` appears in
this document three times, and every one of them is ceremony a
`Result<void, E>` would delete.

### BLOCKER 6 — The interpreter traps on every extern

`avra run` answers "`sqlite3_step` is extern — the evaluator cannot host
it; build natively", exit 1. So no corpus program can prove any binding,
and a user's first `avra run` of a database program is a dead end rather
than an answer. **What this design adds:** the `Cells` trait's default
bodies are the one place where a divergence between engines would be
invisible — they are shared code, so if they run at all they run the same.
Every remaining divergence risk is in the six required methods, which are
six externs each. That makes the extern host's value here concrete and
small: host those six shapes and the whole reading ladder is proven on
both engines by construction.

### BLOCKER 7 — No trampolines, so seven capabilities are unreachable

`update`/`commit`/`rollback` hooks (reactive queries, cache invalidation),
custom SQL functions and collations, the authorizer, the progress handler,
the busy handler. **None of them is on the spine** — 61% of the C surface
is callable the day out-params land, and the whole of
open/prepare/step/column/finalize is in that 61%.

**WHAT THIS DESIGN DOES INSTEAD, and it covers logging entirely:** the
driver is the only path to the database, so it times its own step loop and
offers the hook as an Avra fn field on a capability context. `trace_v2`
becomes necessary only for statements the driver did not issue, of which
there are none. Cache invalidation is the one that genuinely cannot be
faked; `PRAGMA data_version` detects *that* something changed, never
*what*, and the design says so rather than pretending.

### BLOCKER 8 — A package cannot build its own native dependency

`[link] objects = […]` names an object file that must already exist;
nothing in `avra.toml` says how it comes to exist. Today the root
`Makefile` builds `llvm_wrapper.o` for `@std/avrac`. `@std/sqlite` cannot
ship that way: a consumer who adds the dependency gets a manifest pointing
at an object no step in their build produces.

**PROPOSED SHAPE.** A package declares its own native build (source, flags,
output) and the compiler runs it before linking, under the same argv
discipline the `[link]` rows already have — `avra_spawn_status(prog,
args)`, no shell line, nothing quoting, nothing fencing. It blocks
*shipping*, not building, so it is not on the critical path to the first
row.

---

## LANGUAGE ASKS

Per CLAUDE.md's dogfooding rule: each names the construct, the wanting
site in this design, and what it buys.

**A1 — `opaque type T @free_with(f)`, and a DROP on a declared type.**
*Wanting sites:* `Db` (Part 3), `Prepared` (Part 10), `Tx` (Part 9),
`Stream` (Part 14), `Cache`'s eviction (Part 10.2). *Buys:* the closing
law of Part 3.2 — the refcount graph and SQLite's zombie protocol become
the same graph, and nobody writes `close`. Reduces to a drop hook plus
field privacy on a single-pointer record (BLOCKER 1).

**A2 — A `mut` seat on an `extern fn`, and `(status, mut out T)`
projected to `Result<T, E>`.** *Wanting site:* `open`, the first call the
driver makes (Part 3.4), and `Db.prepare` (Part 10.1). *Buys:* the driver
existing at all, plus the deletion of a hand-written wrapper per function
for every C library.

**A3 — The FFI annotation grammar and its ownership vocabulary**
(`@returns_ownership`, `@borrows`, `@takes_ownership`, `@free_with`,
`@error_if`/`@error_null`). *Wanting site:* the wall, Part 12 — roughly
200 entry points answer an `int` result code, and hand-written that is a
thousand lines of `if rc != 0`. *Buys:* the boundary's ownership stated in
the compiler rather than in a convention, and `@returns_borrowed` locking
a door the whole tree already steps around.

**A4 — `float` (IEEE-754 binary64), and an `F64` kind in the host-call
ABI.** *Wanting sites:* `SqlValue.Real` (Part 7), `Cells.real_at` (Part
6.2), `Sql.real` (Part 5.2). *Buys:* the REAL storage class. Spec 31.2
already specifies it in full.

**A5 — `bytes`, a distinct type sharing `string`'s box.** *Wanting sites:*
`SqlValue.Blob`, `Cells.blob_at`, `Sql.blob`, all of Part 14. *Buys:* the
BLOB storage class, and an equality that does not lie.

**A6 — `@derive Row` (the annotation surface plus a derive that returns
declarations).** *Wanting site:* `user_row()` and `read_user`, Part 8.2 —
five lines that restate the struct's fields and their nullability, once
per row type, forever. *Buys:* the two declarations written from the
struct; and it is the same machinery spec 22.2 already promises for
`@derive Model`.

**A7 — A generic answer through a fn-typed argument (a mono defect, not a
sugar want).** *Wanting site:* the `db.tx(() -> …)` combinator this design
could not write, Part 9.3. Fn-typed arguments carry no T-evidence, and
pinning `<T>` over one **corrupts scalar payloads through mono**
(DOGFOODING). *Buys:* the transaction combinator every survey praises, and
every other `bracket(fn) -> T` shape in the language.

**A8 — `Result<void, E>`.** *Wanting sites:* `Tx.commit`, `Stream.write`,
`Cache.clear`, Parts 9, 10, 14. Standing sugar-backlog item; recorded again
because this package hits it six times.

**A9 — A trailing-lambda form (`db.each(q) { … }`).** *Wanting site:* Part
11's streaming, where the loop won on merit — so this is a genuine want
rather than a need, and it is filed at the lower priority it deserves.

**A10 — `while let x = f()? { … }`.** *Wanting site:* `Rows<R>` iteration,
Part 11.2, which is a `step()` then a `row()` because there is no way to
bind and test in one line.

**A11 — A `mut` seat in a fn TYPE.** *Wanting site:* `Decode<R>.read` will
want `fn(mut Cursor) -> Result<R, SqlError>` the day a decoder advances
the cursor (a `hasMany` hydration reads several rows into one `R`).
**Closed on main at `656e650`; still `F0100` at this lane's base.** Named
here so the design is written *against* it rather than around it.

**A12 — A package declares its own native build.** *Wanting site:* the
vendored `sqlite3.o`, BLOCKER 8. A toolchain ask, not a language one, but
it blocks shipping and it belongs on the same list.

---

## TYPE-SYSTEM ASKS

Listed separately because they are what MAXIMUM TYPE POWER cost, and each
one is a place where this design writes a VALUE where it wanted a TYPE.

**T1 — Associated (static) trait functions: a trait method with no
receiver, answering `Self`.**
*Wanted:* `trait Row { fn decode() -> Decode<Self> }`, so that `R` alone
reaches its own decoder and the typed verbs need no decoder argument at
all. *Today:* every impl and trait method gets `self` prepended as param 0
(`typing_impls.av:22-25`), so a constructor cannot be a trait member.
*Wanting site:* `user_row()` in Part 8.2, and every `user_row().all(db, q)`
in this document, which would become `all<User>(db, q)`.
*What it also buys:* it is the missing half of GRDB's `FetchableRecord`
and Diesel's `Queryable`, and it is what `@derive Row` would target.

**T2 — Generic methods, and a type-argument pin on a method call.**
*Wanted:* `impl Db { fn all<R>(q: Sql) -> Result<List<R>, SqlError> }` and
`db.all<User>(q)`. *Today:* `declared_call` never unifies a method's own
tparams (`features/impls/check.av:36-52`); zero generic methods exist in
the tree; the postfix rule takes no `<…>`
(`features/expr_spine/mod.av:40`). *Wanting site:* the whole of Part 8.3,
which is `impl Decode<R>` rather than `impl Db` **only** because the
receiver is the only thing that can carry `R`. The design is fine — it is
the `Table<T>` pattern — but the verbs read backwards from the way a
programmer thinks about them.

**T3 — A trait implementable by a scalar (`impl Decode for int`).**
*Wanted:* the sqlx/Diesel shape, where each Avra type says how it reads
itself out of a column and a row decoder is generic over its fields.
*Today:* `declared_decl` answers absence for `.Int`, `.Str`, `.Bool`,
`.List(_)`, `.Opt(_)`, `.App(_,_,_)` (`features/contexts.av:139-150`), so
only a struct or an enum can sign a contract. *Wanting site:* Part 6.2's
`Cells` trait, whose checked ladder is thirteen hand-named verbs precisely
because it cannot be one generic verb over a per-type decoder.
*Honest note:* the hand-named ladder is arguably BETTER for P1 — an LLM
writing `c.text_or_null(2)` cannot get the type parameter wrong — so this
ask is filed as a capability, not as a complaint.

**T4 — A trait impl over a generic type (F2031).**
*Wanted:* `impl Cells for Rows<R>`, so a typed cursor is also a row source
and `Decode` composes with itself for a joined hydration.
*Today:* "`Rows` is generic — a trait impl over a generic type is recorded,
not landed". *Wanting site:* `Rows<R>`, Part 11.2, which therefore has its
own `step`/`row` pair rather than being a `Cells`.

**T5 — A `dyn` want that reaches a call's argument seat.**
*Wanted:* `decode_from(cursor)` where the seat is `dyn Cells` and a
concrete `Cursor` boxes at the call. *Today:* F2000 — "argument 1 wants
`dyn Cells`, found `Cursor`"; the box must be bound to a typed `let`
first. *Wanting site:* `Decode<R>.read`, Part 8.1, which is typed
`fn(Cursor) -> …` rather than `fn(dyn Cells) -> …`. *Consequence, and it
is not all bad:* a `Decode` reads a LIVE cursor only, which is what makes
the typed path allocate nothing per row.

**T6 — Flow narrowing across statements.**
*Wanted:* `if best != null { … best.score … }` without the `!`.
*Wanting site:* `highest`, Part 11.2, and every nullable read in a decoder
that is guarded once and read twice. Standing sugar-backlog item; recorded
here because a typed driver is full of `T?` by design.

---

## WEAKNESSES

Written to be attacked, and answered where there is an answer.

**W1 — `Cells` is a fat interface: 7 required methods and 13 defaults.**
An implementor must supply seven things to join, and four of them
(`integer_at`, `real_at`, `text_at`, `blob_at`) are *unchecked* — a raw
reader that is wrong when called out of order. That is a footgun inside the
package, mitigated only by the fact that their sole callers are the
default bodies. **A judge will say:** make `value_at` the one required
method and derive the rest. **The answer:** that costs an allocation per
cell on the hot path, and P4 says the fastest path is the DEFAULT path.
The footgun is bought deliberately and the trait's doc says so. It is
still a footgun.

**W2 — The typed verbs read backwards.** `user_row().all(db, q)` puts the
row type first and the database second, because the receiver is the only
thing that can carry `R` (T2). Every other driver in the field writes
`db.all::<User>(q)`. This is the single most visible place where the type
system's ceiling shows through into the API's ergonomics, and no amount of
naming fixes it.

**W3 — The decoder is hand-written until `@derive Row` lands.** Five lines
per row type that restate the struct's fields and their nullability. They
can drift from the struct, and nothing checks them. A 32-column table is
32 lines of `c.text(17)?`. That is exactly the "hand-maintained schema
mirror" the prior art names as a bug class (§3.11) — **this design has one,
and it is a mirror of the Avra struct rather than of the database, which is
the smaller of the two evils but is still one.**

**W4 — Column indices are integers, and they are the one thing a caller
can get wrong.** `c.text(1)` versus `c.text(2)` is a silent wrong answer
whenever both columns are TEXT. Mapping by NAME was refused on good
grounds (LAW S20 — a result column's name without `AS` is unspecified and
may change between SQLite releases), and the compile-time checker will
close it, but **until then the design has traded one off-by-one (the
1-based bind index, which it eliminated) for another (the 0-based column
index, which it did not).**

**W5 — No transaction combinator.** The affordance every survey praises is
absent, and the replacement leans on a language feature (drop) that does
not exist yet. Between now and A1, `Tx` without a drop is exactly prior art
§3.7's "resource lifetime tied to the wrong scope": a `Tx` that leaves
scope uncommitted leaves the transaction open until the connection closes.
**The `[today]` bridge for `Tx` is worse than the bridge for `Db`**, because
a leaked transaction blocks every other writer, and this document does not
pretend otherwise.

**W6 — `Row` costs an allocation per cell, and `all` is the verb most
people will type first.** The typed path is the fast one and the untyped
path is the ergonomic one, which is the correct way round for P4 and the
wrong way round for discoverability. The name says the cost; names are a
weak instrument.

**W7 — The `Cause` enum is a curation, and curations rot.** Twelve
constraint variants, four busy variants, seven read-only variants, and
thirty-seven I/O codes deliberately NOT enumerated because "the disk
failed" is one action. If SQLite adds an extended code that changes what a
caller does, it lands in `Other(code)` and nothing breaks — which is the
design working, and also the design silently under-serving. `I22` says a
registry that ends in a catch-all forgets the next variant; this one ends
in `Other` on purpose, and that purpose is a judgement call about a foreign
library's future.

**W8 — Two row types is two things to learn.** `Cursor` and `Row`, and a
`Decode` reads only the first. A reader who has a `Row` in hand and wants a
`User` has no verb. That is a real hole, and it exists because T5 made the
`dyn Cells` seat unwritable. The honest fix is T5; the dishonest fix would
be a second `read_row` field on `Decode`, which is a duplicated projection
(I12) waiting to drift.

**W9 — The whole design is unprobed at the shapes that matter most.**
`impl Cells for Cursor` with twelve default bodies, `impl Decode<R>` with
`R` from the receiver, a trait default body calling `fail`, and
`export extern fn` are each read from the compiler's source rather than
run. The tree's own discipline is PROBE, DON'T REASON, and this document
reasons. Every one of them is in the confidence ledger below at MEDIUM, and
each is a sub-second scratch probe.

**W9a — The trait may not be reachable through `dyn`, which is half of
why a trait was chosen.** Every checked verb answers a `Result`, which is
a generic enum, and DOGFOODING records that a generic-enum return does not
come back through `dyn`. If that holds, `Cells` buys the shared
definition and NOT the heterogeneous dispatch — still worth it, but the
case for the trait over two hand-written ladders gets thinner, and the
"hand-built row as a test fixture" story needs `Row` concretely rather
than `dyn Cells`. Probe 8 decides it; the design is written so that
either answer costs nothing.

**W10 — Maximum type power buys nothing against SQLite's actual danger.**
The type system can prove that `c.real(3)` is a `float`. It cannot prove
that column 3 is the score, that the schema has not changed under a cached
statement, that a `REAL`-declared column has not been handed an integer by
NUMERIC affinity, or that the row you are reading is from the transaction
you think you are in. **Every one of those is a run-time refusal in this
design**, and the compile-time-checked-SQL rung is what turns three of the
four into compile-time refusals. Until then, the type power is real but it
is guarding the near half of the boundary.

---

## THE PROBE LIST — what turns this document's MEDIUMs into HIGHs

Seven scratch files, each sub-second, each needing no lock (CLAUDE.md's
working discipline: a `./avra check` of one file is a probe, not a run).
They are listed in the order that de-risks the most first, and **no driver
code should be written before probe 1, 2 and 3 answer.**

1. **A trait with default bodies, two implementors, one of them reading a
   struct field and the other calling a free fn.** Does the default body
   see `self`'s required methods? Does an implementor that supplies only
   the required set satisfy F2032? *(Ledger 18, 23c.)*
2. **`impl Decode<R>` — a method on a generic type calling its own
   fn-typed field with `R` from the receiver.** The `Table<T>` precedent
   covers the method; the fn-FIELD call through a generic receiver is the
   unproven half. *(Ledger 19.)*
3. **A trait default body that `fail`s and answers a `Result`, and one
   that calls a pinned generic (`absent<int>()`).** *(Ledger 20, 23a,
   23b.)*
4. **`export extern fn`.** One line. *(Ledger 21.)*
5. **A struct of one `ptr` field with an `impl` block** — does it bear
   methods, and does it flatten? *(Ledger 22.)*
6. **A `table<CodeRow>` whose cell holds `Cause.Constraint(Violation.Unique)`**
   — a table cell holding a PAYLOAD-carrying enum value, which the tree's
   own tables do not yet do. *(Ledger 23d covers payload-free variants
   only.)*
7. **`.set(":min", .Integer(40))`** — a bare variant literal in an
   argument seat whose declared type is the enum, fed by the hunger
   protocol.
8. **A `dyn Cells` calling a method that answers `Result<int, SqlError>`**
   — DOGFOODING records "no generic-enum returns through `dyn`", and
   `Result` is a generic enum. Nothing in the design depends on it; the
   probe decides whether §6.2's third bullet is an affordance or a
   footnote.

Two of the seven are the design's load-bearing bets: probe 1 (the trait
carries the reading ladder) and probe 2 (the receiver carries `R`). If
either fails, the shape changes rather than the wording — probe 1's
fallback is two hand-written ladders behind a `make idioms` license, and
probe 2's is free generic fns with explicit pins (`all<User>(db, q,
user_row())`). Both fallbacks are worse; neither is fatal.

---

## CONFIDENCE LEDGER

| # | Claim | How verified | Confidence |
|---|---|---|---|
| 1 | Trait bounds on a generic free fn exist and are enforced at instantiation | grammar read at `features/fns/mod.av:33`; `bounds_hold`/`bound_held` read at `features/fns/check.av:176-193` | HIGH |
| 2 | Trait default method bodies landed | trait grammar `( mb:block )?` at `features/impls/mod.av:46`; ROADMAP sugar-backlog entry "TRAIT DEFAULT METHOD BODIES — LANDED 2026-09-05" | HIGH |
| 3 | Only a struct or an enum can implement a trait | `declared_decl` and `implements_of` read in full at `features/contexts.av:122-150` | HIGH |
| 4 | A trait impl over a generic type is refused (F2031) | probe log Part II (run); `contexts.av:139-143` records the same | HIGH |
| 5 | Generic inherent impls on generic types land | `core/{table,arena,stack}.av`, three live instances; DOGFOODING "Generics: what infers" | HIGH |
| 6 | No generic methods are usable | `declared_call` read at `features/impls/check.av:36-52` — it substitutes only the RECEIVER's args; grep of `packages/*/src` finds zero generic methods in the tree | MEDIUM-HIGH (read + absence of counterexample, not probed) |
| 7 | A method call takes no type-argument pin | postfix rule read at `features/expr_spine/mod.av:40` | HIGH |
| 8 | Every impl/trait method gets `self` as param 0, so there are no associated fns | `typing_impls.av:22-25` (`params: [self.impl_self_type(contract)].concat(…)`); `impls/lower.av:30` ("slot 0 rides the self seat") | HIGH |
| 9 | Threading a fn arg through a generic corrupts scalar payloads under mono | DOGFOODING.md, "Generics: what infers, what needs pins" — the tree's own recorded finding | HIGH (as a prohibition) |
| 10 | A capture is a copy; a write to one is F3005 | DOGFOODING I15; CLAUDE.md's subset | HIGH |
| 11 | `defer` + `?` can eat an errcode | probe log §2b, mechanism from the lane that built `defer`; NOT reproduced (needs an open connection) | MEDIUM |
| 12 | `sqlite3_column_blob` returns NULL for three distinct things | `sqlite3.h:5411`, `:5519-25`, quoted in the probe log | HIGH |
| 13 | `close_v2` zombifies; `close` answers BUSY | c3ref/close.html, quoted in semantics_traps LAW S22 | HIGH |
| 14 | A `ptr?` is a niche and a C NULL reads as Avra `null` | probe log §2 — built and ran against libc `getenv` | HIGH |
| 15 | A `ptr` rides safely in a struct field and across an extern seat | probe log §3, §4 — built and ran | HIGH |
| 16 | A foreign `const char*` declared `string` is a defect that AVRA_RC_GUARD cannot see | probe log §6 — ran; mechanism read in `avra_runtime.c` (`hdr`'s tag check gates `rc_note`) | HIGH |
| 17 | Every refusal quoted in this document | probe log Part II — `./avra check` on scratch, text copied | HIGH |
| 18 | `impl Cells for Cursor` with twelve default bodies compiles | NOT PROBED — read from the trait grammar and `typing_impls.av`'s default handling | **MEDIUM** |
| 19 | `impl Decode<R>` methods see `R` from the receiver with no pin | NOT PROBED — read from `instantiated_sig`, `features/impls/check.av:82-94`; the `Table<T>` precedent is the same shape | **MEDIUM** |
| 20 | A trait default body may `fail` and answer a `Result` | NOT PROBED — a default body is an ordinary fn body typed under the trait's `Self` | **MEDIUM** |
| 21 | `export extern fn` parses | NOT PROBED — `export_stmt(d)` wraps any `stmt` and `extern fn` is one (`features/modules/mod.av:51`) | **MEDIUM** |
| 22 | A single-pointer record is flattened and bears methods | `is_flat`/`flat_fields` read at `core/types.av:174-185`; `Callee.Declared` at `callee.av:58-67`. Whether `ptr` counts as the flattenable scalar is **not** established | MEDIUM |
| 23 | Comprehensions may iterate a range (`[f(i) for i in 0..n]`) | CLAUDE.md's subset ("`[f(i) for i in lo..hi]` counts"); ROADMAP's LANGUAGE SLICE entry, 2026-09-05 | HIGH |
| 23a | A bare `null` does not infer into a `T?` seat, so `absent<T>()` is the form | CLAUDE.md's subset ("A `null` LITERAL as a list element under `List<T?>` … a `T?`-answering fn fills the slot"); probe log's "an empty literal does NOT infer into a nullable seat" | HIGH |
| 23b | A pinned generic call is needed inside a generic body, and a trait DEFAULT body is one (it is a generic method over `Self`) | DOGFOODING "Pin explicitly … the call happens inside another generic fn's body, even at a concrete type"; ROADMAP's lane C entry describes a default as a generic method over `Self` | MEDIUM-HIGH |
| 23c | `impl Cells for Cursor` and `impl Cursor` may coexist; an EXTRA method inside the impl-for is refused (F2032) | CLAUDE.md's subset names F2032; DOGFOODING "A type's methods are a namespace" (clash detection is per table, so two impls are the norm) | MEDIUM-HIGH |
| 23d | A table literal cell may hold an enum value | DOGFOODING "Typed table literals": `"+" \| BinOp.Add` | HIGH |
| 24 | The C surface's ABI split — 61% callable today, the spine needing exactly out-params + float + bytes | `RESEARCH_api_surface.md` §2, mechanically classified from the SDK header and hand-corrected | HIGH |
| 25 | REAL is binary64, so `float` ↔ REAL is bit-exact | sqlite.org/floatingpoint.html, cited in `RESEARCH_numeric_tower.md` §4.1 | HIGH |
| 26 | `bind_double(nan)` writes NULL; NUMERIC affinity collapses a whole float to an integer | sqlite.org/datatype3.html and c3ref/bind_blob.html, cited in numeric_tower §4.1 | HIGH |
| 27 | A `DECIMAL(10,5)` column gets NUMERIC affinity and converts bound text to REAL/INTEGER | sqlite.org/datatype3.html affinity rules 1-5, quoted in numeric_tower §4.2 | HIGH |
| 28 | A savepoint name cannot be a bound parameter, so the driver must mint it | lang_savepoint.html; ORM report §1.8 | HIGH |
| 29 | `column_count` (not the leading verb) decides whether a statement yields rows; RETURNING rows arrive in arbitrary order | ORM report §1.5, from lang_returning.html | HIGH |
| 30 | Column metadata (`database_name`/`table_name`/`origin_name`) is absent from macOS's system build | api_surface §3.2, read from the SDK header and `PRAGMA compile_options` | HIGH |
| 31 | A `string` is a pointer to a headered box, NUL-terminated outside its recorded length, so it may go OUT to C as `const char*` and may never come BACK as an answer | `2026_09_05_STRING_REPRESENTATION.md` — DECIDED by the owner, superseding legacy 9.15; the runtime lines it cites read directly | HIGH |
| 32 | `table` is a reserved word and refuses as a field name — hence `Origin.in_table`, `ColumnFacts`' renamed pragma columns | DOGFOODING I10 ("Reserved words refuse as field names: `shape`/`table`/`ref`/`none`") | HIGH |
| 33 | `null` is a keyword, so `Sql` has no `.null()` verb and binds NULL as `.value(.Null)` | the nullable feature's grammar; CLAUDE.md's reserved-word law (F3002 names the word and its status) | HIGH |
