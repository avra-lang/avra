# `@std/sqlite` — THE DECLARATIVE FACE

> **What this is.** The public Avra surface of `@std/sqlite`: the values a
> programmer touches, the verbs they call, and the code they write. Its
> philosophy is stated once and obeyed everywhere: **the common case is
> one line with no ceremony.** No prepare, no finalize, no bind index, no
> close, no cursor, no transaction bookkeeping. What cannot be deleted is
> pushed into the library or the type system until the call site is
> prose.
>
> **Its risk, managed explicitly.** Deleted ceremony becomes hidden
> machinery, and hidden machinery violates P7. §14 is an INSPECTABILITY
> LEDGER: every piece of magic in this design, and the named verb that
> shows it.
>
> **Its sources.** The ten research reports beside this file
> (`2026_09_05_STD_SQLITE_RESEARCH_*.md`) and `..._VISION.md`. Where a
> law is cited as `LAW X1`, `LAW S12`, `B-3`, it is that report's, and the
> report carries the SQLite documentation quote.
>
> **Its bar.** Every Avra fragment below either compiles against this
> worktree's compiler as it stands on 2026-09-05, or is marked
> `[ASK n]` and listed in §18 with its wanting site. A fragment that
> `RESEARCH_probe_log.md` contradicts is a defect in this document, not a
> language ask. Fragments assume the campaign's three prerequisites —
> `float`, `bytes`, `mut` seats on externs — which are the campaign, not
> this design's asks; §18 is what remains after they land.

---

## 1. THE ONE LINE

Everything below is elaboration of this.

```avra
use @std.sqlite.{open, sql, Db, Row, SqliteError}

/// Every note, newest first.
fn recent(db: Db, limit: int) -> Result<List<Note>, SqliteError> {
    [note_of(r)? for r in db.all(sql("select id, body from notes order by id desc limit ?", [.Int(limit)]))?]
}
```

One statement opened nothing, prepared nothing, bound no index, stepped
no cursor, finalized nothing and closed nothing. It named a connection, a
verb, a query and a row reader. The `?` on the iterable and the `?` on
the element are Avra's, not the driver's.

The whole program around it:

```avra
use @std.sqlite.{open, sql, Db, Row, SqliteError}

type Note = { id: int, body: string }

/// One row of `select id, body from notes`.
fn note_of(r: Row) -> Result<Note, SqliteError> {
    Note { id: r.int(0)?, body: r.text(1)? }
}

fn seeded(path: string) -> Result<Db, SqliteError> {
    let db = open(path)?
    db.run(sql("create table if not exists notes(id integer primary key, body text not null) strict", []))?
    db
}
```

`seeded` never closes `db`. `db` is a value; the connection dies when the
last reference to it does, and its death is `sqlite3_close_v2` (§4).

---

## 2. THE FIVE COMMITMENTS

Every decision below follows from these, and each is a P6 collapse of a
choice the field treats as forced.

**C1 — A QUERY IS A VALUE, NEVER A CALL SHAPE.** `Query` carries the SQL
text and every value its holes take. So there is one verb family
(`run`/`all`/`each`/`one`/`scalar`), not one per binding style; and a
query can be logged, cached, described, checked at compile time and sent
elsewhere, because it is data (P11). *Collapses:* "positional or named
binding" — both, in one value.

**C2 — THE STORAGE CLASS IS ASKED, NEVER ASSUMED, AND NEVER COERCED.**
Every cell arrives as a `Sql` value carrying its class. A typed read
refuses a mismatch and names both classes. *Collapses:* "strict or
convenient" — the total value is the escape hatch, so nothing is lost by
refusing (LAW T1; §I.6 of `RESEARCH_semantics_traps.md`).

**C3 — A ROW OWNS ITS CELLS.** `Row` is materialised. There is no borrowed
cursor in the public API, so LAW S12 (a `column_text` pointer dies at the
next `step`) cannot reach a caller, and the field's commonest binding bug
(`RESEARCH_prior_art.md` §3.5) is unrepresentable rather than documented.
*Collapses:* "safe rows or fast rows" — the copy LAW S12 forces was going
to happen for every value the caller keeps anyway; §16.3 prices what
remains.

**C4 — CEREMONY LIVES IN THE LIBRARY OR NOWHERE.** Prepare, finalize,
reset, `clear_bindings`, index arithmetic, `BEGIN`/`COMMIT`/`ROLLBACK`,
savepoint names and `close_v2` are the driver's. A caller who wants them
goes one layer down, where they are spelled (P8, §13).

**C5 — NOTHING IN THIS DRIVER READS SQL TO DECIDE BEHAVIOUR.** Not to
decide whether a statement returns rows (`sqlite3_column_count` decides,
so `INSERT … RETURNING` needs no special case — `RESEARCH_orm_substrate.md`
§1.5), not to decide whether to open a transaction, not to decide
anything. That is CLAUDE.md:127 ("No string tags or string-matching to
detect behavior"), and its absence is Python's sixteen-year
`LEGACY_TRANSACTION_CONTROL` bug (`RESEARCH_prior_art.md` §3.1).

---

## 3. THE VALUES

Nine types. A programmer meets six.

```avra
//! @std.sqlite — SQL is the language; everything else is a value.
use @std.errors.{Error, ErrorInfo, Loc, info}
use @std.time.{Duration, secs}

/// One of SQLite's five storage classes, carrying its value. This is
/// the total type: every cell is exactly one of these, and no read can
/// fail to produce one.
export enum Sql {
    Null
    Int(v: int)
    Real(v: float)
    Text(v: string)
    Blob(v: bytes)
}

/// A storage class with no value — what a mismatch names.
export enum Class {
    Null
    Int
    Real
    Text
    Blob
}

/// The SQL and the values its holes take. `args` fill the `?` slots in
/// the order written — 0-based here, 1-based in C, and the driver owns
/// the difference (LAW S5). `named` fill `:name`, `@name` and `$name`.
/// Every slot must be filled: an unbound slot binds NULL in silence
/// (LAW S6), so the driver counts slots against values and refuses
/// before it steps.
export type Query = { text: string, args: List<Sql> = [], named: Map<string, Sql> = {} }

/// One row, materialised: every cell copied into a box Avra owns before
/// the statement moved on. `names` is the result set's column names,
/// shared by every row of it — one word per row, never a copy.
export type Row = { cells: List<Sql>, names: List<string> }

/// A connection. Copy it freely: the copies share one `sqlite3*`, one
/// statement cache and one transaction depth, and the last copy to die
/// closes the connection.
export type Db = { conn: Conn, cfg: Config, cache: Cache, depth: List<int> }
```

`Conn` is the opaque handle:

```avra
/// The `sqlite3*` itself. Nothing in Avra may look inside it; the
/// compiler calls `sqlite3_close_v2` when the last reference dies.
opaque type Conn @free_with(sqlite3_close_v2)          // [ASK 1]
```

`Cache` and `depth` are the driver's own state (§10, §9). `depth` is a
one-slot list — the tree's mut-cell protocol, as
`features/decls.av:54` spells it (`ensure: List<fn(DeclId)>`).

### 3.1 The mints

```avra
/// A query and its positional values — the everyday mint.
export fn sql(text: string, args: List<Sql>) -> Query {
    Query { text: text, args: args }
}

/// A query whose holes are named. `:city`, `@city` and `$city` are one
/// name; the leading sigil is not part of it.
export fn named(text: string, by_name: Map<string, Sql>) -> Query {
    Query { text: text, named: by_name }
}
```

The bare-variant spelling `[.Int(limit)]` reads the seat's enum through
the hunger protocol (DOGFOODING.md, THE EXPECTED-TYPE CHANNEL: a list
literal under a known slot judges every element by the agreement door).
`[Sql.Int(limit)]` is the same value spelled long. **Confidence: MEDIUM**
on the bare form in an *argument* seat — a struct-literal FIELD seat
plants no want (CLAUDE.md, The subset today) while an argument seat does;
probe before the first slice and use the long form if it refuses.

---

## 4. OPENING AND CLOSING — THE OWNERSHIP STORY

### 4.1 The verbs

```avra
/// A database at a path, opened for reading and writing, created if it
/// is not there, with the driver's defaults (§4.3).
export fn open(path: string) -> Result<Db, SqliteError>

/// The same file, read-only. `query_only` is set too, so a write is
/// refused by SQLite rather than by convention.
export fn open_read(path: string) -> Result<Db, SqliteError>

/// A private database in memory: no file, no journal, no lock. Dies
/// with the connection.
export fn memory() -> Result<Db, SqliteError>

/// Every knob, spelled. `open(p)` is `open_with(Config { path: p })`.
export fn open_with(c: Config) -> Result<Db, SqliteError>
```

Four verbs, three of them one argument. `open(path)` is the line a
first-generation LLM writes, and it is correct (P1).

### 4.2 Who closes, when, and what guarantees it

**The owner is the reference count, and the drop is `sqlite3_close_v2`.**

- `Conn` is an `opaque type @free_with(sqlite3_close_v2)` — spec 15.5,
  whose own motivating example is this exact call. Its release runs the
  drop; the header's `rc` decides when (CLAUDE.md:188, EVERY POINTER AVRA
  HOLDS CARRIES A HEADER).
- **Exactly once**, because the drop hangs off the refcount and the count
  reaches zero once. A double close is unrepresentable.
- **Never too early**, because `close_v2` is the zombie form (LAW S22): a
  connection with an outstanding statement or blob handle is marked and
  deallocates when the last derived object goes. Even the pathological
  order is safe. `sqlite3_close` — which answers `SQLITE_BUSY`, leaves the
  file locked, and lets a driver report success — is never called here.
- **On an early exit**, because `?`, `fail` and `return` all reach
  `FnExit`, which settles every open scope at the site (ROADMAP.md:864).
- **On a trap, not at all — and that is right.** `avra_trap` exits 2 and
  nothing runs after it (CLAUDE.md:255). An aborted process leaves a hot
  journal or an uncheckpointed WAL and the next connection recovers
  (`SQLITE_NOTICE_RECOVER_ROLLBACK`/`_WAL`). The failure to avoid is the
  opposite one — a driver that catches a wreck and carries on with a
  half-applied transaction visible to itself. No such path exists here.

**THE CYCLE THIS DESIGN REFUSES.** CLAUDE.md:211: a closure stored in a
value that captures the value's owner is a cycle, and counting never
frees a cycle — the workspace's 922 MB. Two shapes in a database driver
are exactly that, and both are designed out:

| the shape | why it is a cycle | what this design does |
|---|---|---|
| a cached statement holding its `Db` | `Db` owns the cache; the cache would own the `Db` back | the cache holds the raw statement handle, and the connection is the cache's **owner, never its member**; no statement value is public at all (§10) |
| a `trace` fn capturing the `Db` | the config is a field of `Db` | the trace seat's contract says so at the field, and `Trace` carries what a logger needs **as data**, so nothing needs to capture the connection (§14) |

### 4.3 The config, and the defaults defended at the field

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
    /// the caller's decision and this is where it is made — `.Full` is
    /// one field away. Under any other journal the driver keeps FULL
    /// regardless, because NORMAL is not corruption-safe there.
    sync: Sync = .Normal,
    /// SQLite ships foreign keys OFF for backwards compatibility. A
    /// database with referential integrity is worth a parent lookup per
    /// write. Set at open, before anything: inside a transaction the
    /// pragma is a silent no-op (LAW X8).
    foreign_keys: bool = true,
    /// How long a lock is waited for. A long timeout turns a lock-order
    /// bug into a hang, and no timeout can save a promotion deadlock
    /// (LAW K8) — which is why writes take IMMEDIATE (§9).
    busy_timeout: Duration = secs(5),
    /// Page cache, in bytes, per connection — the negative `cache_size`
    /// form, so its meaning does not move with the page size.
    cache_bytes: int = 2097152,
    /// Temp tables and the sorter in RAM. A large ORDER BY without an
    /// index now costs memory instead of disk, and can run out.
    temp_in_memory: bool = true,
    /// How many prepared statements are kept (§10). `0` disables the
    /// cache and every call prepares.
    statements_cached: int = 64,
    /// Where every statement's timing goes. A fn, never a closure over
    /// the `Db` — that is the cycle of §4.2.
    trace: fn(Trace) = untraced,
}
```

Three settings are **not** fields, and their absence is the design:

- **Extended result codes** are always on. A driver that cannot tell
  `SQLITE_CONSTRAINT_UNIQUE` from `SQLITE_CONSTRAINT_FOREIGNKEY` cannot
  give a caller `Cause` (LAW E2), and nobody wants them off.
- **Double-quoted string literals** are always off, twice over: the
  vendored build takes `-DSQLITE_DQS=0` and the driver calls
  `sqlite3_db_config` for DDL and DML at open. `WHERE name = "alice"` with
  a misspelled column is otherwise `WHERE "alice" = "alice"` — the whole
  table, always, silently (quirks §10). The tag is the belt and the law is
  the braces, exactly as the box header is treated (CLAUDE.md:188).
- **`PRAGMA optimize`** runs on the way out, once, at the last release.

`mmap_size` stays off: a mapped I/O error is a segfault rather than a
code, and a driver whose thesis is "no silent wrong answers" does not
default into a mode that turns a recoverable error into a crash. It is
reachable through `db.set_pragma` (§12).

---

## 5. THE ERROR, AND HOW A FAILURE READS

### 5.1 The value

```avra
/// Why SQLite refused, built where it refused and owning everything it
/// says. It holds no borrowed pointer and no connection: `errmsg`'s
/// buffer is overwritten by the next call on the connection (LAW E4),
/// and a connection inside an error is a cycle (CLAUDE.md:211).
export type SqliteError = {
    /// What to DO — the arm a caller branches on.
    cause: Cause,
    /// The primary result code, exact. `extended & 0xFF` (LAW E1).
    code: int,
    /// The extended result code, exact.
    extended: int,
    /// `sqlite3_errmsg` at the moment of the failure, copied.
    message: string,
    /// The SQL that failed, when there was one.
    sql: string?,
    /// Where in `sql` the parser stopped — `sqlite3_error_offset`,
    /// absent when it answers −1. A `Loc` because that is the tree's
    /// exchange form for a span (`@std.errors`), which is what lets the
    /// compile-time SQL checker underline the word (§15).
    at: Loc?,
}
```

`at: Loc?` and `sql: string?` are nullable POINTER slots, which the
declared-slot law allows; `at: int?` would be a scalar nullable — a
register pair, not a word — and is refused
(`language/typing_declare.av:113-121`: *"a slot inside an aggregate holds
ONE WORD … a scalar nullable is a register PAIR"*). The `Loc` is the
better field anyway.

```avra
/// What went wrong, as the thing to do about it. Every arm changes the
/// caller's next move; the exact codes ride beside it for everything
/// else. A registry, so no `_ ->` (I22): a result code this enum
/// forgets is a caller acting on `.Other`.
export enum Cause {
    /// Another connection holds the lock. Retry after a wait.
    Busy
    /// The read snapshot cannot be promoted (`BUSY_SNAPSHOT`, 517), or
    /// the transaction is already gone (`ABORT_ROLLBACK`, 516). NOT
    /// retryable in place: roll back and run the whole thing again.
    Stale
    /// This connection's own lock conflicts with itself. A retry loop
    /// spins forever — the program's shape is what is wrong (LAW K6).
    Locked
    /// A UNIQUE index or a PRIMARY KEY already holds this value.
    Unique
    /// A NOT NULL column was left null.
    NotNull
    /// A foreign key names a parent row that is not there.
    ForeignKey
    /// A CHECK, a trigger's RAISE, or a STRICT table's datatype rule.
    Check
    /// A constraint with no arm of its own; `extended` names it.
    Constraint
    /// The SQL did not parse, or named something that is not there.
    /// `at` points at the byte it stopped on.
    Syntax
    /// The cell holds one storage class and the read asked for another.
    /// The driver never coerces (C2).
    Mismatch(column: int, wanted: Class, found: Class)
    /// A slot count and a value count that disagree, caught before
    /// anything was bound (LAW S6).
    Unfilled(slots: int, given: int)
    /// A read named a column this result set does not have. Result
    /// column names are UNSPECIFIED without an `AS` (LAW S20), so this
    /// is where a missing `AS` is reported.
    NoColumn(name: string)
    /// A TEXT cell that is not well-formed UTF-8, from `text_utf8`
    /// alone. SQLite stores what it was given and validates nothing;
    /// Avra's `string` says UTF-8 (`2026_09_05_STRING_REPRESENTATION.md`).
    /// `at` is the byte offset of the first ill-formed sequence.
    NotUtf8(column: int, at: int)
    /// `one` or `scalar` found no row.
    NoRow
    /// `one` found more than one.
    ManyRows
    /// The connection, the file or the statement may not write.
    ReadOnly
    /// The file is missing, is a directory, or is not a database.
    CantOpen
    /// The file is damaged.
    Corrupt
    /// The disk is full.
    Full
    /// A value crossed `SQLITE_MAX_LENGTH`, or the SQL crossed
    /// `SQLITE_MAX_SQL_LENGTH`.
    TooBig
    /// `sqlite3_interrupt` stopped it.
    Interrupted
    /// The operating system refused a read or a write.
    Io
    /// SQLite could not allocate.
    NoMemory
    /// A BLOB handle whose row was written under it (LAW B6). Re-open
    /// and restart; writes already made are NOT undone by the expiry.
    Expired
    /// THE DRIVER'S OWN BUG — `SQLITE_MISUSE`, `SQLITE_RANGE`, a
    /// statement used after finalize (LAW S9). Never the caller's
    /// mistake, never retryable, and never to be caught: report it.
    Defect(what: string)
    /// A code with no arm of its own. `code` and `extended` are exact.
    Other
}
```

```avra
impl Error for SqliteError {
    fn describe() -> ErrorInfo { info(self.cause.kind(), self.message) }
}
```

One line, because SQLite already wrote the message and the driver copied
it. The registry is the kind:

```avra
impl Cause {
    /// The stable dotted kind — hierarchical, matched by prefix, never
    /// by a class hierarchy (`@std.errors`).
    fn kind() -> string {
        match self {
            .Busy -> "sqlite.busy",
            .Stale -> "sqlite.stale",
            .Locked -> "sqlite.locked",
            .Unique -> "sqlite.constraint.unique",
            .NotNull -> "sqlite.constraint.not_null",
            .ForeignKey -> "sqlite.constraint.foreign_key",
            .Check -> "sqlite.constraint.check",
            .Constraint -> "sqlite.constraint",
            .Syntax -> "sqlite.syntax",
            .Mismatch(_, _, _) -> "sqlite.mismatch",
            .Unfilled(_, _) -> "sqlite.unfilled",
            .NoColumn(_) -> "sqlite.no_column",
            .NotUtf8(_, _) -> "sqlite.not_utf8",
            .NoRow -> "sqlite.no_row",
            .ManyRows -> "sqlite.many_rows",
            .ReadOnly -> "sqlite.read_only",
            .CantOpen -> "sqlite.cant_open",
            .Corrupt -> "sqlite.corrupt",
            .Full -> "sqlite.full",
            .TooBig -> "sqlite.too_big",
            .Interrupted -> "sqlite.interrupted",
            .Io -> "sqlite.io",
            .NoMemory -> "sqlite.no_memory",
            .Expired -> "sqlite.expired",
            .Defect(_) -> "sqlite.defect",
            .Other -> "sqlite.other",
        }
    }

    /// Whether waiting could change the answer. `.Stale` is NOT here:
    /// its answer never becomes OK without a rollback (LAW X1), and a
    /// retry loop that includes it is the "database is locked" bug the
    /// field reports most (LAW E3).
    fn retryable() -> bool {
        self is .Busy
    }
}
```

### 5.2 How a failure reads at a call site

Four shapes, in the order a program reaches for them.

**Propagate — the default, and all most code ever does.**

```avra
fn count_notes(db: Db) -> Result<int, SqliteError> {
    (db.scalar(sql("select count(*) from notes", []))?).as_int()
}
```

**Answer with a default, where absence is not a failure.**

```avra
/// The stored setting, or the built-in one. A missing row is an answer
/// here, not a problem, so it is read and not propagated.
fn setting(db: Db, key: string) -> string {
    let cell = db.scalar(named("select v from settings where k = :k", { "k": Sql.Text(key) })) catch Sql.Null
    cell.as_text() catch "off"
}
```

**Branch on the cause — one `is`, no payload pattern, no string match.**

```avra
export enum Signup { Created(id: int), Taken }

/// A duplicate email is an ANSWER, not a failure. Everything else still
/// is one.
fn signup(db: Db, email: string) -> Result<Signup, SqliteError> {
    match db.insert(sql("insert into users(email) values (?)", [.Text(email)])) {
        .Ok(id) -> Signup.Created(id),
        .Err(e) -> { if e.cause is .Unique { return Signup.Taken } fail e },
    }
}
```

`e.cause is .Unique` is a bare-variant question, which is what `is` takes
(CLAUDE.md, The subset today: *"`e is .TimedOut` is the test"*). The
two-arm `match` is a registry — both arms answer, so neither may be `_`.
The arm's body is braced because a bare `fail` in an arm is refused.

**Read the exact codes, when the cause is not enough.** `e.code`,
`e.extended`, `e.message`, `e.sql`, `e.at` are all fields. Nothing is
folded: `Cause` is a *projection* of the extended code, never a
replacement for it (P8).

### 5.3 Three properties this error has that the field's do not

1. **The extended code is the discriminator; the message is only the
   payload.** Every ORM in the survey separates
   `SQLITE_CONSTRAINT_UNIQUE` from `SQLITE_CONSTRAINT_FOREIGNKEY` with a
   regex over English. CLAUDE.md:127 forbids that, and 2067 vs 787 makes
   it unnecessary.
2. **`at` is a span.** `sqlite3_error_offset` costs one call and gives the
   byte offset of the token the parser stopped on. Mapped into the Avra
   string literal's own span it underlines the word, in the `.av` file,
   with an F-code — the compile-time checker's whole diagnostic story
   (§15), and why the field is in the error type on day one.
3. **`Cause.Defect` is not in the caller's channel.** `SQLITE_MISUSE` and
   `SQLITE_RANGE` mean the driver did something wrong. Folding them into
   the ordinary error enum teaches callers to retry past the driver's own
   bug (LAW S9). It is named, unignorable, and its message says so.

---

## 6. RUNNING A STATEMENT

Six verbs on `Db`. There is no `prepare`, no `execute`, no `cursor`, and
no verb whose name says whether the SQL is a SELECT — `sqlite3_column_count`
answers that at prepare time, before any step (C5).

```avra
impl Db {
    /// A statement that answers no rows. The answer is
    /// `sqlite3_changes64` — rows this statement inserted, updated or
    /// deleted DIRECTLY: trigger, foreign-key and REPLACE side effects
    /// are not counted (LAW Q5). A statement that DOES answer rows is
    /// refused here, naming `all`.
    fn run(q: Query) -> Result<int, SqliteError>

    /// An INSERT whose answer is the row it made — `last_insert_rowid`,
    /// read inside the same statement's frame. Meaningless for a
    /// WITHOUT ROWID table and for a non-INTEGER primary key, where it
    /// answers the PREVIOUS insert's rowid with no error at all (LAW
    /// Q4): use `RETURNING` there, which `all` handles with no special
    /// case.
    fn insert(q: Query) -> Result<int, SqliteError>

    /// Every row, materialised in order.
    fn all(q: Query) -> Result<List<Row>, SqliteError>

    /// Exactly one row. No row is `Cause.NoRow`; a second row is
    /// `Cause.ManyRows` — a query that meant `limit 1` and did not say
    /// so is a bug this refuses instead of hiding.
    fn one(q: Query) -> Result<Row, SqliteError>

    /// The first column of the first row. No row is `Cause.NoRow`.
    fn scalar(q: Query) -> Result<Sql, SqliteError>

    /// Every row, one at a time, with only one row's cells ever live.
    /// The step answers whether to keep going; the verb answers how
    /// many rows it saw. See §12.
    fn each(q: Query, step: fn(Row) -> Result<bool, SqliteError>) -> Result<int, SqliteError>
}
```

There is no `first` verb, and its absence is deliberate: `Result<Row?, E>`
is refused today (§18, ASK 4), and `(db.all(q)?).first()` already says it
with a list verb the language owns (P17).

### 6.1 Parameters — by position and by name

```avra
/// Positional: the values fill the `?` slots in the order written.
fn in_city(db: Db, city: string, min_age: int) -> Result<List<Row>, SqliteError> {
    db.all(sql("select id, email from users where city = ? and age >= ?", [.Text(city), .Int(min_age)]))
}

/// Named: the SQL says what each value is for, and the order is the
/// caller's business only in the SQL.
fn in_city_named(db: Db, city: string, min_age: int) -> Result<List<Row>, SqliteError> {
    db.all(named("select id, email from users where city = :city and age >= :age",
                 { "city": Sql.Text(city), "age": Sql.Int(min_age) }))
}
```

Both forms obey three laws the field gets wrong:

- **No caller ever types a bind index.** SQLite's parameters are 1-based
  and its columns 0-based (LAW S5); the driver adds the one. The most
  common SQLite binding bug in the field cannot be written here.
- **An under-filled statement is refused before it steps.** The driver
  asks `sqlite3_bind_parameter_count`, compares it to what it was given,
  and answers `Cause.Unfilled(slots, given)`. An unbound slot binds NULL
  in silence (LAW S6) — a wrong answer, not an error, and P9 says a
  boundary does not let one through.
- **A value is never interpolated into SQL.** There is no verb here that
  takes an assembled SQL string with values in it, exactly as there is no
  verb in `@std/process` that takes a command line (CLAUDE.md:258, A
  COMMAND IS AN ARGV). Interpolation re-parses, destroys the storage
  class, invites injection, and under DQS can turn a misspelled
  identifier into a string literal — there is no axis on which it wins
  (`RESEARCH_semantics_traps.md` F5).

### 6.2 What the ceremony would have been

The same query, spelled the way every C-shaped binding spells it, is the
measure of what C4 deleted:

```text
prepare_v3 → check → bind_text(1) → check → bind_int64(2) → check
→ step ⇄ column_type ⇄ column_text ⇄ column_bytes ⇄ copy → step
→ reset → clear_bindings → finalize → check
```

Fourteen calls, five of which have an ordering law attached (LAW S14: the
value before the length, or a `column_bytes` first converts an INTEGER to
TEXT and the following `column_blob` answers the rendering). All of it is
§16.

---

## 7. READING A ROW

### 7.1 The untyped path — the row is data

`Row` has two fields and nothing hidden. A program that wants the truth
takes it:

```avra
fn shape_of(r: Row) -> string {
    joined([r.names[i] + ":" + c.class().name() for (i, c) in r.cells.enumerate()], " ")
}
```

### 7.2 The typed path — the reader is a named fn, the mapper is a comprehension

```avra
type User = { id: int, email: string, city: string?, score: float }

/// One row of `select id, email, city, score from users`. A nullable
/// column asks its class first; every other read refuses a mismatch.
fn user_of(r: Row) -> Result<User, SqliteError> {
    let raw = r.cells[2]
    let city: string? = if raw is .Null { null } else { r.text(2)? }
    User { id: r.int(0)?, email: r.text(1)?, city: city, score: r.real(3)? }
}

fn users_in(db: Db, city: string) -> Result<List<User>, SqliteError> {
    [user_of(r)? for r in db.all(sql("select id, email, city, score from users where city = ?", [.Text(city)]))?]
}
```

Three facts make this the design rather than a compromise:

- **A NAMED fn in the mapper seat works everywhere**, including with `?`
  inside it. A lambda there does not hear the seat's answer today
  (CLAUDE.md, The subset today), so a lambda mapper's `?` would refuse.
  The named fn is not a workaround: it is a value with a name, reusable
  across every query that selects that shape, and it is exactly what
  `@derive Row` will generate (ASK 6) — so the CALL SITE never changes
  when the derive lands.
- **The mapping is a comprehension**, which is the tree's own beautiful
  form (DOGFOODING.md, "List comprehensions for filter/map"), and `?`
  works in both the element and the iterable (CLAUDE.md's idiom bar, 1).
- **No generic is threaded through a fn argument.** `all` answers
  `List<Row>` and the caller maps. A `db.all<User>(q, user_of)` would put
  `User` behind a fn-typed parameter, which the tree's own note forbids —
  *"Fn-typed arguments carry no T-evidence, and pinning `<T>` over one
  corrupts scalar payloads through mono"* (DOGFOODING.md, Generics). The
  design does not want a rule bent; it wants the rule not to apply.

### 7.3 The readers

```avra
impl Row {
    /// The cell as an `int`. INTEGER only: a REAL is refused even when
    /// it is integral, because `1.5` in an INT-affinity column is
    /// stored REAL (LAW T4) and a truncating read is a silent wrong
    /// answer.
    fn int(i: int) -> Result<int, SqliteError>

    /// The cell as a `float`. INTEGER and REAL both: REAL affinity may
    /// store an integral value in integer form and hand it back as
    /// INTEGER (LAW T5), so a `float` seat that refused INTEGER would
    /// refuse a column it declared REAL and wrote a REAL to.
    fn real(i: int) -> Result<float, SqliteError>

    /// The cell as text. TEXT only — a BLOB is refused, because
    /// SQLite's TEXT is not required to be well-formed UTF-8 and
    /// `bytes` is where undecided bytes live.
    fn text(i: int) -> Result<string, SqliteError>

    /// The cell as text, VALIDATED. SQLite stores what it was given
    /// and checks no encoding, so a TEXT column in a database this
    /// program did not write may hold bytes that are not UTF-8, which
    /// Avra's `string` says it is
    /// (`2026_09_05_STRING_REPRESENTATION.md`). This is the one
    /// checkpoint, it costs one pass over the bytes, and it is a
    /// SEPARATE verb because the condition that needs it is the same
    /// condition the whole mismatch ladder exists for: a schema this
    /// program does not own. Against our own STRICT schema every text
    /// was written by an Avra `string` and the scan is provably
    /// redundant.
    fn text_utf8(i: int) -> Result<string, SqliteError>

    /// The cell as bytes. BLOB and TEXT both: text IS bytes, and that
    /// direction is lossless. This is also the escape from a TEXT
    /// column that is not UTF-8 — read the bytes and decode them
    /// lossily.
    fn blob(i: int) -> Result<bytes, SqliteError>

    /// The cell as a bool. INTEGER 0 or 1 only. SQLite has no BOOLEAN
    /// (quirks §3) and a 2 is refused: no `bool` should silently become
    /// one.
    fn bool(i: int) -> Result<bool, SqliteError>

    /// The cell, whatever it is. The escape hatch (P8): no refusal is
    /// possible, and the storage class rides the value.
    fn value(i: int) -> Result<Sql, SqliteError>

    /// The column with this name, or `Cause.NoColumn`. Names are
    /// UNSPECIFIED for a result column with no `AS` and may change
    /// between SQLite releases (LAW S20) — write the `AS`.
    fn index_of(name: string) -> Result<int, SqliteError>
}
```

Every one is one line over the `Sql` projections of §8, so there is one
law and two spellings of reaching it, not two laws.

### 7.4 The mismatch, read

```avra
/// A `then` answers a bool and may not carry `?`, so every suite here
/// hoists its work into a named helper and compares one exact string —
/// the shape `@std/process`'s suites take.
fn first_as_int(text: string) -> Result<int, SqliteError> {
    let db = memory()?
    let r = db.one(sql(text, []))?
    r.int(0)
}

then "an `int` read of a TEXT cell refuses, and names both classes" {
    shown(first_as_int("select 'abc'")) == "err sqlite.mismatch: column 0 holds TEXT, and `int` was asked for"
}
```

That refusal is the design's whole position on flexible typing. The C API
answers `0` for `sqlite3_column_int` on `"abc"`, and `12` on `"12abc"` —
which is `?? 0` implemented in C and shipped to five million
applications, and is precisely DOGFOODING's **I18**. A new driver that
forwards it adds nothing and inherits the entire bug class.

**The two lossy escapes, both explicit, neither the default (P8):**

1. `r.value(i)` — the total type. Decide in Avra; nothing can refuse.
2. `r.cast_int(i)` / `r.cast_text(i)` — SQLite's own CAST rules, named so
   nobody mistakes them for the strict readers. The longest integer
   prefix, `0` when there is none (LAW Q6). This is the ONLY place in the
   driver where that rule runs.

### 7.5 The nullable column, and the one place this design bends

`city: string?` above costs three tokens more than it should:

```avra
let raw = r.cells[2]
let city: string? = if raw is .Null { null } else { r.text(2)? }
```

The verb that should exist is `r.text_or_null(2)?`, answering
`Result<string?, SqliteError>` — and `Result<T?, E>` is refused today:
*"a `Result` slot cannot hold this yet"*
(`features/results/tests/results_test.av:166-169`). This is **ASK 4** and
it has a large wanting site: a nullable column is the commonest thing in
a database, and every row reader in every program pays these three
tokens. When it lands, ten verbs appear (`int_or_null` … `bool_or_null`),
the local disappears, and nothing else in this design changes.

The form above is chosen over `r.text(2) catch null` deliberately: the
`catch` form would swallow a CLASS MISMATCH as absence, which is C2 bent
where it matters most.

---

## 8. THE FIVE STORAGE CLASSES

### 8.1 The projections

```avra
impl Sql {
    /// Which class this is.
    fn class() -> Class {
        match self {
            .Null -> Class.Null,
            .Int(_) -> Class.Int,
            .Real(_) -> Class.Real,
            .Text(_) -> Class.Text,
            .Blob(_) -> Class.Blob,
        }
    }

    fn as_int() -> Result<int, SqliteError> {
        match self {
            .Int(v) -> v,
            .Null or .Real(_) or .Text(_) or .Blob(_) -> { fail mismatched(Class.Int, self.class()) },
        }
    }

    fn as_real() -> Result<float, SqliteError> {
        match self {
            .Real(v) -> v,
            .Int(v) -> v.to_float(),
            .Null or .Text(_) or .Blob(_) -> { fail mismatched(Class.Real, self.class()) },
        }
    }

    fn as_text() -> Result<string, SqliteError> {
        match self {
            .Text(v) -> v,
            .Null or .Int(_) or .Real(_) or .Blob(_) -> { fail mismatched(Class.Text, self.class()) },
        }
    }

    fn as_blob() -> Result<bytes, SqliteError> {
        match self {
            .Blob(v) -> v,
            .Text(v) -> v.bytes(),
            .Null or .Int(_) or .Real(_) -> { fail mismatched(Class.Blob, self.class()) },
        }
    }
}
```

`or`-runs keep a registry that spells every arm affordable (I22,
CLAUDE.md's `_ ->` rule). The `.Int` arm of `as_real` and the `.Text` arm
of `as_blob` are the only two widenings in the driver, and both are
lossless; they are in the code rather than in the prose because P7 says
so.

`v.to_float()` is explicit because the spec makes int↔float conversion
explicit in both directions (spec 31.5 / 6290) — `let x: float = 5` is a
compile error, and that is what stops `int / int` from silently being the
wrong number in a float context.

### 8.2 The ladder, as a table

| cell class ↓ / read → | `int` | `float` | `string` | `bytes` | `bool` | `Sql` |
|---|---|---|---|---|---|---|
| `NULL` | refuse | refuse | refuse | refuse | refuse | `.Null` |
| `INTEGER` | exact | exact | refuse | refuse | 0/1 only | `.Int` |
| `REAL` | refuse | exact | refuse | refuse | refuse | `.Real` |
| `TEXT` | refuse | refuse | exact | exact | refuse | `.Text` |
| `BLOB` | refuse | refuse | refuse | exact | refuse | `.Blob` |

Five classes, so a registry, so no `_ ->`: a sixth storage class would
break every arm at compile time, which is the guarantee.

### 8.3 What a value costs going in

```avra
/// The five, written. NULL is a value here, never an absence — SQLite's
/// NULL is a thing a column holds, and `x = NULL` is neither true nor
/// false (LAW N1).
db.run(sql("insert into m(a, b, c, d, e) values (?, ?, ?, ?, ?)",
           [.Null, .Int(7), .Real(1.5), .Text("hi"), .Blob(payload)]))?
```

- `.Text` and `.Blob` bind with **`SQLITE_TRANSIENT`, always**, and with
  the header's length, never `−1`. The length is not negotiable: `−1`
  means `strlen`, which truncates a text holding a NUL — the exact bug
  commit `3c622be` fixed in this tree's `@std/io` (LAW B2). `TRANSIENT` is
  not negotiable either until `@borrows` lands: a `CallRt` argument is
  BORROWED (CLAUDE.md's runtime-row law), so the Avra box a
  `SQLITE_STATIC` bind handed over is freed at the enclosing scope's exit
  and the next `step` reads freed memory. The cost is one `memcpy` per
  bind, and the escape is ASK 5.
- **`.Real(nan)` is refused, not bound.** `sqlite3_bind_double` of a NaN
  writes SQL NULL, silently (BLOCK-8 of `RESEARCH_numeric_tower.md`) —
  which is a value turning into an absence at the boundary, the one thing
  this driver exists to stop.
- A `bool` has no class of its own. `.Int(1)` is what goes in, because
  SQLite has none (quirks §3), and the driver does not invent one.

### 8.4 NULL, said once

`Sql.Null` is a cell that holds SQL NULL. It is NOT Avra's `null`, and
the design never conflates them:

- **A read** answers `.Null` for a NULL cell; only the caller's `T?` seat
  turns it into absence (§7.5).
- **A pointer is never tested to detect it.** `sqlite3_column_blob`
  answers NULL for SQL NULL, for a ZERO-LENGTH BLOB and for an
  out-of-memory alike (LAW S16, LAW S17). The class is asked first,
  always; §16.1 is the code and the reason.
- **A query builder that binds a possibly-null value must emit `IS ?`,
  not `= ?`** — `x = NULL` is NULL, so `WHERE col = ?` with NULL bound
  matches nothing, silently (LAW N1). That is the ORM's job, and it is on
  the list the driver publishes to it (§15).

---

## 9. TRANSACTIONS

### 9.1 The zero-ceremony form: the list IS the transaction

```avra
/// Two writes that land together or not at all. Nothing to open,
/// nothing to close, nothing to forget.
fn transfer(db: Db, from: int, to: int, cents: int) -> Result<List<int>, SqliteError> {
    db.batch([
        sql("update accounts set cents = cents - ? where id = ?", [.Int(cents), .Int(from)]),
        sql("update accounts set cents = cents + ? where id = ?", [.Int(cents), .Int(to)]),
    ])
}
```

```avra
impl Db {
    /// Every query, in order, inside ONE `BEGIN IMMEDIATE`…`COMMIT`.
    /// The answer is each statement's change count, in the same order.
    /// A failure rolls the whole thing back and answers the cause.
    fn batch(qs: List<Query>) -> Result<List<int>, SqliteError>
}
```

`batch` is `BEGIN IMMEDIATE`, each statement in order, `COMMIT`; the
answer is each statement's change count. Any failure rolls back and
answers the error. **There is no state a caller can leave behind**, which
is the whole point: the commonest transaction in every program is a fixed
list of statements, and for that case the correct code has no
transaction vocabulary in it at all.

It is also the bulk-write path: one transaction is one fsync instead of
N, which on spinning media is three orders of magnitude
(`RESEARCH_semantics_traps.md` F2), and it is what the ORM's batch insert
compiles to.

### 9.2 The general form: a body the wrapper brackets

```avra
/// A transaction whose later statements read its earlier ones. The
/// wrapper owns BEGIN, COMMIT and ROLLBACK; the body owns the work.
fn post(db: Db, author: string, body: string) -> Result<int, SqliteError> {
    let work: fn() -> Result<int, SqliteError> = () -> {
        db.run(sql("insert into authors(name) values (?) on conflict(name) do nothing", [.Text(author)]))?
        let id = (db.scalar(sql("select id from authors where name = ?", [.Text(author)]))?).as_int()?
        db.insert(sql("insert into posts(author, body) values (?, ?)", [.Int(id), .Text(body)]))
    }
    db.tx(work)
}
```

```avra
impl Db {
    /// The body, inside one transaction. Depth 0 opens `BEGIN
    /// IMMEDIATE`; deeper opens a SAVEPOINT the driver names. On the
    /// body's answer: COMMIT or RELEASE. On its failure: ROLLBACK, or
    /// nothing when SQLite already rolled back itself (LAW X4). The
    /// body's answer is the transaction's answer.
    fn tx(body: fn() -> Result<int, SqliteError>) -> Result<int, SqliteError>

    /// The read-only twin: `BEGIN DEFERRED`, for several reads that
    /// must see ONE snapshot. Never for a read that will later write —
    /// promoting a read lock can fail with `SQLITE_BUSY_SNAPSHOT`,
    /// which no timeout can wait out (LAW X1).
    fn read_tx(body: fn() -> Result<int, SqliteError>) -> Result<int, SqliteError>
}
```

Two costs, both filed:

- **The typed `let` on the lambda** is there because a lambda in an
  argument seat does not hear the seat's answer today, so a `?` inside it
  would name the lambda rather than the enclosing fn (CLAUDE.md, The
  subset today). Under the typed let the body hears it. **ASK 3.**
- **The answer is `int`, not `T`.** `tx<T>(body: fn() -> Result<T, E>)`
  puts `T` behind a fn-typed parameter, which mono corrupts for scalar
  `T` (DOGFOODING.md, Generics). A transaction that must answer something
  richer writes it to the database and reads it after, or uses the raw
  bracket (§13). **ASK 2.**

### 9.3 Nesting is a SAVEPOINT, and the name is the driver's

`db.tx` inside `db.tx` does not open a second transaction. SQLite refuses
that outright — *"An attempt to invoke the BEGIN command within a
transaction will fail"* (LAW X2) — and a binding that models only
BEGIN/COMMIT has thrown away the mechanism SQLite gives for it.

```avra
impl Db {
    /// One deeper. The depth IS the savepoint's name, so the name is
    /// the driver's and never a caller's word: `SAVEPOINT ?` does not
    /// exist, so a caller-supplied name would be concatenated into SQL
    /// — an identifier is not a parameter, so the driver mints it.
    /// (CLAUDE.md:258, one level down.)
    fn deeper() -> int {
        mut d = self.depth
        d.set(0, d[0] + 1)
        d[0]
    }
}
```

`mut d = self.depth` is the tree's rebind-alias idiom (DOGFOODING.md,
"Rebind-alias for shared mutation"): every copy of a `Db` shares the one
array, so the depth is the connection's and not a copy's.

The savepoint discipline is exact, because `ROLLBACK TO` does not pop:
success is `RELEASE sp_n`; failure is `ROLLBACK TO sp_n` **then**
`RELEASE sp_n` (LAW X6). A nesting that forgets the second `RELEASE`
leaks a stack entry per failed inner block, and the outer `RELEASE` then
releases the wrong frame.

### 9.4 What happens on failure inside one

Five rules, all of which the wrapper implements and none of which a
caller sees.

1. **Some errors roll the transaction back by themselves** —
   `SQLITE_FULL`, `SQLITE_IOERR`, `SQLITE_BUSY`, `SQLITE_NOMEM`,
   `SQLITE_INTERRUPT` (LAW X4), and the documentation's word is *might*.
   So the wrapper asks `sqlite3_get_autocommit` and issues `ROLLBACK`
   only if a transaction is still open. A wrapper that rolls back blindly
   gets *"cannot rollback - no transaction is active"* on top of the real
   error and reports THAT — losing the cause.
2. **COMMIT can fail with `SQLITE_BUSY` and leave the transaction open**
   (LAW X5). The wrapper retries the COMMIT under the busy policy; if it
   still fails it ROLLS BACK and answers the error, and never leaves an
   open write transaction behind. Leaving one blocks every other writer
   until the connection closes, at which point the work is silently lost.
3. **The error the caller gets is the body's, not the cleanup's.** Code
   and message are read FIRST, at the failure, and the cleanup runs
   second — `sqlite3_errcode` reflects the most recent failed API call
   (LAW E5), so a `reset` before the read reports the reset.
4. **A trap is not caught.** Nothing unwinds, the connection is not
   closed, and SQLite's journal is what makes the next process correct
   (§4.2). A wrapper that caught a wreck and continued would leave a
   half-applied transaction visible to itself; there is no such path.
5. **`Cause.Stale` is not retried by any loop in this driver.** Its
   answer never becomes OK in place: the whole transaction must be rolled
   back and run again, which is a decision only the caller can make
   (LAW X1, `Cause.retryable()` in §5.1).

### 9.5 Why the write transaction is IMMEDIATE

`BEGIN` (deferred) takes its write lock at the first statement that needs
one, so a transaction that reads and then writes must PROMOTE — and
promotion can fail with `SQLITE_BUSY_SNAPSHOT`, which a busy timeout
cannot help with, because waiting would be a deadlock (LAW K8). It is the
single most reported SQLite-in-production bug, from code that only ever
reads then writes. `db.tx` takes IMMEDIATE; `db.read_tx` is the explicit
deferred, read-only form, and its name says which it is.

---

## 10. PREPARED STATEMENTS — INVISIBLE, AND INSPECTABLE

**There is no `Stmt` in the public API.** Not a hidden one: none. A
prepared statement is a resource with an ordering law
(prepare → bind → step ⇄ column → reset → finalize), three ways to leak
it, and a documented `SQLITE_MISUSE` for every mis-order. C4 says that
belongs to the driver.

### 10.1 What the cache is

```avra
/// The per-connection statement cache. A cache with no bound cannot be
/// constructed: `Config.statements_cached` is its capacity and `0`
/// turns it off. Keyed by SQL TEXT, scoped to ONE connection — a
/// `sqlite3_stmt` belongs to one `sqlite3*`, and sharing one across
/// connections is a use-after-free waiting for a pool.
export type Cache = { rows: List<CacheRow>, cap: int }

/// A `sqlite3_stmt*`. Never public: it is what §10 exists to keep off
/// the call site, and it is the cache's to finalize.
opaque type Stmt @free_with(sqlite3_finalize)          // [ASK 1]

/// One cached statement, as the caller may read it (§14). `handle` is
/// the raw `sqlite3_stmt*`: the cache OWNS it and finalizes it on
/// eviction, and it holds no reference back to the connection — that
/// would be the cycle of §4.2.
export type CacheRow = { text: string, handle: Stmt, hits: int, prepared_us: int }
```

Every verb of §6 goes through it. The reuse ritual is one place:

- `sqlite3_prepare_v3` with **`SQLITE_PREPARE_PERSISTENT`**, which exists
  precisely to tell SQLite a statement will be retained, so its memory
  comes from the general heap rather than the lookaside pool.
- `sqlite3_reset` **and** `sqlite3_clear_bindings` between uses. `reset`
  does not clear bindings (LAW S7); skipping `clear_bindings` writes the
  *previous* row's values into the slots the next caller does not bind —
  a data-corruption bug that passes every test in which all parameters
  are always bound.
- Eviction finalizes. A missing `sqlite3_finalize` leaks until process
  exit, by SQLite's own documentation, and an unbounded text-keyed cache
  is how sqlite4java killed its heap (`RESEARCH_prior_art.md` §3.6).

### 10.2 What the cache does NOT do

**It never caches a row SHAPE.** `prepare_v2`/`v3` silently re-prepare on
a schema change, and the column count, the names and the decltypes can
all differ across that re-prepare (LAW S21). A driver that cached a
decoded shape beside a statement decodes the new schema with the old
one. The shape is read at each `SQLITE_ROW`; `describe`'s answer (§15) is
keyed on `PRAGMA schema_version`, which is what changes.

### 10.3 The escape hatch is P4's, not P8's

`db.uncached(q)` prepares, runs and finalizes without touching the cache
— for a one-shot statement of a megabyte of SQL that should not be
retained. It is the only reason a caller ever thinks about preparing, and
it is a performance verb, not a correctness one.

---

## 11. INCREMENTAL BLOB I/O

A blob larger than memory is not a value, and `sqlite3_blob_*` exists so
it need not be one.

```avra
export enum BlobMode { Read, Write }

impl Db {
    /// A handle onto one BLOB, by its row. `zeroblob(n)` reserves the
    /// space first: the size may NOT be changed through the handle
    /// (LAW B7), so `n` is known before the stream starts. Only a real
    /// rowid table column — not a view, not a virtual table, not
    /// WITHOUT ROWID; and for writing, not indexed, not a PRIMARY KEY,
    /// not UNIQUE, not a foreign-key child (LAW B5).
    fn blob(schema: string, table: string, column: string, rowid: int, mode: BlobMode) -> Result<BlobIo, SqliteError>
}

/// An open BLOB. Closed by its own drop: an unclosed handle keeps the
/// connection a zombie forever (LAW B9, LAW S22).
opaque type BlobIo @free_with(sqlite3_blob_close)      // [ASK 1]

impl BlobIo {
    /// `n` bytes from `at`. Refused when `at + n` passes the end.
    fn read(at: int, n: int) -> Result<bytes, SqliteError>
    /// `data` at `at`. Refused when it would pass the end, and
    /// `Cause.ReadOnly` on a handle opened `.Read`.
    fn write(at: int, data: bytes) -> Result<int, SqliteError>
    /// The blob's size — fixed for this handle's life.
    fn size() -> int
    /// The same column of a different row, without a new open.
    fn reopen(rowid: int) -> Result<int, SqliteError>
}
```

```avra
/// A big value written without ever holding it whole.
fn store(db: Db, id: int, total: int, chunks: List<bytes>) -> Result<int, SqliteError> {
    db.run(sql("update docs set body = zeroblob(?) where id = ?", [.Int(total), .Int(id)]))?
    let io = db.blob("main", "docs", "body", id, .Write)?
    mut at = 0
    for c in chunks {
        io.write(at, c)?
        at = at + c.length
    }
    at
}
```

The loop earns its keep on two of the three grounds DOGFOODING allows —
`?` propagation in the body and index arithmetic.

**The expiry is named, not generic.** If the row is UPDATEd or DELETEd
under an open handle, the handle expires and every later read or write
answers `SQLITE_ABORT` (LAW B6). That is `Cause.Expired`, whose message
says *re-open the handle and restart* — and whose documentation says the
part that bites: writes made **before** the expiry are not undone by it
(LAW B8), so a retry from offset 0 double-writes the prefix. A driver
that folded this into a generic error would tell the caller nothing they
could act on.

---

## 12. STREAMING, AND THE POSITION ON AGGREGATION

### 12.1 The two verbs, and the cost in the name

```avra
db.all(q)          // materialises: every row live at once
db.each(q, step)   // streams: one row live at a time
```

`sqlite3_step` yields one row per call with no buffer — SQLite is already
streaming, and materialising is what a driver *adds*. So the naming rule
is P7's: `all` says it holds everything, `each` says it does not, and
neither hides which.

```avra
/// Every note to stdout, with one row's cells live at a time.
fn dump(db: Db) -> Result<int, SqliteError> {
    db.each(sql("select id, body from notes order by id", []), print_note)
}

fn print_note(r: Row) -> Result<bool, SqliteError> {
    println("${r.int(0)?}\t${r.text(1)?}")
    true
}
```

`step` is a NAMED fn for the same reason the row reader is (§7.2): `?`
inside it needs the answer type, and a named fn has one everywhere.
Answering `false` stops the scan; the verb answers how many rows it saw.

### 12.2 The hazard, named at the verb

An open statement holds a read transaction on its connection. A second
query on the same connection while a stream is open sees the older
snapshot or contends on a write; SQLite's own isolation documentation
calls modifying a table while a SELECT over it is still stepping
*undefined*, not merely locked. The contract of `each` says so, and its
step function is handed a materialised `Row` precisely so that stopping
early and doing something else is safe.

### 12.3 What a step may and may not do

A lambda step closes over its locals, so a stream into another
destination is one value away — a captured pointer (a `Db`, an open file)
is the same object on both sides:

```avra
/// Every row of one database into another, one at a time.
fn copy_notes(from: Db, into: Db) -> Result<int, SqliteError> {
    let step: fn(Row) -> Result<bool, SqliteError> = (r) -> {
        into.run(sql("insert into notes(id, body) values (?, ?)", [.Int(r.int(0)?), .Text(r.text(1)?)]))?
        true
    }
    from.each(sql("select id, body from notes order by id", []), step)
}
```

The typed `let` is the same pin as §9.2's, for the same reason, and the
same **ASK 3**.

What a step may NOT do is accumulate into an Avra value: a write to a
capture is refused (F3005, captures are copies). That is a **safety
property before it is a limitation** — it is the structural reason a row
cannot escape a callback, which is what would make C3 enforceable even if
`Row` were a borrowed cursor.

What is genuinely missing is a FOLD — `db.fold(q, seed, step)` with
`step: fn(A, Row) -> Result<A, E>` — and it is missing for one reason:
`A` would ride behind a fn-typed parameter, which mono corrupts for
scalar `A`. **ASK 2**, same ask as `tx`'s answer type, same wanting site
shape.

### 12.4 The position: aggregation is SQL's job

A driver that streams a million rows to count them has already lost. The
count belongs in the query:

```avra
(db.scalar(sql("select count(*) from ledger where posted_at >= ?", [.Int(since)]))?).as_int()?
```

Streaming is for EXPORT and TRANSFORM — a row at a time out of the
database, or into another one. That is what `each` is shaped for, and it
is why the missing fold is a want rather than a blocker.

### 12.5 Pragmas and the small introspections

```avra
impl Db {
    /// A pragma's value. The NAME is an identifier, not a parameter —
    /// `PRAGMA ?` does not exist — so the driver validates it against
    /// `[A-Za-z_][A-Za-z0-9_]*` and refuses anything else. Same law as
    /// the savepoint's name (§9.3).
    fn pragma(name: string) -> Result<Sql, SqliteError>

    /// A pragma set, answering what is ACTUALLY in force. `PRAGMA
    /// journal_mode=WAL` returns the mode it got, which can differ — a
    /// network filesystem, a read-only directory, another connection in
    /// another mode. A driver that ignores the answer reports WAL and
    /// runs DELETE, and every concurrency claim it made is false
    /// (LAW P1).
    fn set_pragma(name: string, v: Sql) -> Result<Sql, SqliteError>

    /// Rows changed by the last statement, and since the connection
    /// opened. Both `*64`: Avra's `int` is i64, so the narrow twins buy
    /// nothing.
    fn changes() -> int
    fn total_changes() -> int

    /// Whether a transaction is open — SQLite's own answer, never a
    /// counter the driver kept.
    fn in_transaction() -> bool

    /// A connection limit, read or set — `SQLITE_LIMIT_VARIABLE_NUMBER`
    /// above all, which is 32766 since 3.32.0 and 999 before. An `IN
    /// (…)` generator that hard-codes 999 is every ORM's open issue.
    fn limit(which: Limit) -> int

    /// Stop whatever this connection is running, from anywhere.
    fn interrupt()

    /// `EXPLAIN QUERY PLAN`, as text. Plain SQL, so it costs the driver
    /// nothing — and it is what makes a query's cost inspectable (P7).
    fn explain(q: Query) -> Result<List<string>, SqliteError>
}
```

---

## 13. THE ESCAPE HATCH — THE RAW WALL

P8 is not a courtesy here. A binding that offers only the pretty layer is
one people abandon at their first unusual requirement; a binding that
offers only the wall is one they wrap. This design has both, and the
lower one is **complete**: every public `sqlite3_*` entry point, spelled,
with nothing hidden and no C written by us.

```avra
//! @std.sqlite.raw — SQLite's C API, declared. One `extern fn` per
//! entry point, in the order the header declares them, with nothing
//! wrapped and nothing renamed. A name here is the C name.
//!
//! THREE LAWS THIS FILE OBEYS:
//!   1. A foreign `const char*` answers `ptr`, NEVER `string`. It
//!      works by accident — an untagged pointer no-ops retain and
//!      release, and `str_len` falls back to `strlen` — and it hides a
//!      lifetime, a length and a NUL all at once (probe log §6).
//!   2. A C `int` is 32 bits and Avra's `int` is 64. Every seat and
//!      answer below says which.
//!   3. An out-parameter is a `mut` seat: the address of the caller's
//!      slot, which is what `sqlite3**` wants.

// (a) all-int/pointer — 173 of the 284 entry points are this shape
extern fn sqlite3_libversion_number() -> i32
extern fn sqlite3_step(stmt: Stmt) -> i32
extern fn sqlite3_reset(stmt: Stmt) -> i32
extern fn sqlite3_clear_bindings(stmt: Stmt) -> i32
extern fn sqlite3_finalize(stmt: Stmt) -> i32
extern fn sqlite3_column_count(stmt: Stmt) -> i32
extern fn sqlite3_column_type(stmt: Stmt, col: i32) -> i32
extern fn sqlite3_column_int64(stmt: Stmt, col: i32) -> int
extern fn sqlite3_column_bytes(stmt: Stmt, col: i32) -> i32
extern fn sqlite3_column_name(stmt: Stmt, col: i32) -> ptr
extern fn sqlite3_db_handle(stmt: Stmt) -> Conn
extern fn sqlite3_errcode(db: Conn) -> i32
extern fn sqlite3_extended_errcode(db: Conn) -> i32
extern fn sqlite3_errmsg(db: Conn) -> ptr
extern fn sqlite3_error_offset(db: Conn) -> i32
extern fn sqlite3_get_autocommit(db: Conn) -> i32
extern fn sqlite3_last_insert_rowid(db: Conn) -> int
extern fn sqlite3_changes64(db: Conn) -> int
extern fn sqlite3_bind_parameter_count(stmt: Stmt) -> i32
extern fn sqlite3_bind_parameter_index(stmt: Stmt, name: ptr) -> i32
extern fn sqlite3_stmt_readonly(stmt: Stmt) -> i32
extern fn sqlite3_limit(db: Conn, which: i32, v: i32) -> i32
extern fn sqlite3_interrupt(db: Conn)

// (b) double — FOUR functions, and that is SQLite's whole `double`
extern fn sqlite3_column_double(stmt: Stmt, col: i32) -> float
extern fn sqlite3_bind_double(stmt: Stmt, slot: i32, v: float) -> i32

// (c) out-param — a `mut` seat is the address of the caller's slot
extern fn sqlite3_open_v2(path: ptr, mut db: Conn, flags: i32, vfs: ptr) -> i32       // [ASK 0]
extern fn sqlite3_prepare_v3(db: Conn, sql: ptr, n: i32, flags: i32,
                             mut stmt: Stmt, mut tail: ptr) -> i32                     // [ASK 0]
extern fn sqlite3_blob_open(db: Conn, schema: ptr, table: ptr, column: ptr,
                            rowid: int, flags: i32, mut blob: BlobIo) -> i32           // [ASK 0]
extern fn sqlite3_wal_checkpoint_v2(db: Conn, name: ptr, mode: i32,
                                    mut frames: i32, mut moved: i32) -> i32            // [ASK 0]

// (g) length-carrying bytes — the pointer answers, the length rides
extern fn sqlite3_column_blob(stmt: Stmt, col: i32) -> ptr
extern fn sqlite3_column_text(stmt: Stmt, col: i32) -> ptr
extern fn sqlite3_bind_text64(stmt: Stmt, slot: i32, p: ptr, n: int, dtor: ptr, enc: i32) -> i32
extern fn sqlite3_bind_blob64(stmt: Stmt, slot: i32, p: ptr, n: int, dtor: ptr) -> i32

// (d) function pointer, used ONLY as a SENTINEL — `SQLITE_TRANSIENT` is
// `(void*)-1` and `SQLITE_STATIC` is `0`. Fourteen entry points look
// like callbacks and are not (`RESEARCH_api_surface.md` B-4).
fn transient() -> ptr
fn static_lifetime() -> ptr

// Constants are fns: a module file holds declarations, and only the
// entry runs statements (F0902) — the shape `@std/process` takes for
// its flag words.
fn class_null() -> i32 { 5 }
fn class_integer() -> i32 { 1 }
fn class_real() -> i32 { 2 }
fn class_text() -> i32 { 3 }
fn class_blob() -> i32 { 4 }
fn rc_ok() -> i32 { 0 }
fn rc_row() -> i32 { 100 }
fn rc_done() -> i32 { 101 }
fn rc_nomem() -> i32 { 7 }
fn prepare_persistent() -> i32 { 1 }
```

### 13.1 How a caller reaches it

Three things, all spelled: the connection's own handle, the raw entry
point, and the driver's judge for the code it answers.

```avra
use @std.sqlite.{Db, SqliteError}
use @std.sqlite.raw.{sqlite3_wal_checkpoint_v2, checkpoint_truncate}

/// Checkpoint the WAL and truncate it — a scheduled maintenance verb
/// the driver does not (and should not) have.
fn checkpoint(db: Db) -> Result<int, SqliteError> {
    mut frames = 0
    mut moved = 0
    db.check(sqlite3_wal_checkpoint_v2(db.conn, null, checkpoint_truncate(), frames, moved))?
    moved
}
```

- **`db.conn` is a public field.** DOGFOODING's rule for a context value
  holds here: *raw fields stay public as the escape hatch*. A driver that
  hid its handle would force a fork.
- **`db.check(rc)`** is the one verb that turns a raw result code into a
  `SqliteError` — cause, extended code, an owned message copy, the
  offset. So a caller who leaves the paved road does not also lose the
  error vocabulary.
- **The hatch is proven by the driver's own use of it.** Everything in
  §16 is written against exactly this wall. There is no privileged
  interior.

---

## 14. THE INSPECTABILITY LEDGER (P7)

This design deletes ten things from the call site. Each one, and the
named verb that shows it. A row with no inspector would be a defect.

| what was deleted | where it went | how it is SEEN |
|---|---|---|
| `sqlite3_prepare` / `finalize` | the statement cache (§10) | `db.cached()` → `List<CacheRow>`: the SQL text, hit count, prepare time and bytes of every retained statement |
| bind indices | `Query.args` / `Query.named` (§6.1) | the values are a FIELD of the query; `db.explain(q)` prints the plan; the raw and expanded SQL are separate verbs |
| `close` | the refcount + `@free_with` (§4.2) | `AVRA_MEM_STATS=1` names live boxes by allocation site; `db.open_statements()` answers what would keep a `close_v2` zombie alive |
| `BEGIN`/`COMMIT`/`ROLLBACK` | `batch` / `tx` (§9) | `db.in_transaction()` is `sqlite3_get_autocommit`, SQLite's own answer, never a counter the driver kept; the depth is `db.depth[0]` |
| savepoint names | minted from the depth (§9.3) | the minted name is in the trace line for the `SAVEPOINT` statement |
| the step loop | `all` / `each` (§12) | the verb NAMES which it is; `each` publishes the rows-seen count as its answer |
| the cell copy | `Row` is materialised (§7) | `row.cells` is a field — the whole row, classes and all, with no verb in the way |
| result-code branching | `Cause` (§5) | `e.code` and `e.extended` are exact fields beside it; `Cause` never replaces them |
| the pragma set at open | `Config` (§4.3) | `db.cfg` is a field, and `db.pragma(name)` reads what is ACTUALLY in force — which is not always what was asked (LAW P1) |
| the timing | `Config.trace` (§4.3) | one `Trace` per statement: the raw SQL, the parameter COUNT, the rows, the nanoseconds, whether the cache hit |

```avra
/// One statement, as it ran. `sql` is the RAW text: the expanded form —
/// `sqlite3_expanded_sql`, with the values substituted — is a separate
/// verb and never the default, because a log line carrying it leaks
/// credentials and PII into a file. The same instinct as the spec's
/// automatic exclusion of `Secret<T>` from every projection (22.2).
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
`mattn/go-sqlite3`, whose documented cure is `SetMaxOpenConns(1)`, is the
whole argument (`RESEARCH_prior_art.md` §3.3).

---

## 15. WHAT THE ORM WILL BUILD ON

The line is drawn where Ecto and SQLAlchemy Core draw it: *the query
layer is a function of SQL and rows; the mapping layer is a function of
types and identity, and they do not share a value*
(`RESEARCH_orm_substrate.md` §2.2). `@std/sqlite` never learns the ORM
exists — CLAUDE.md's layering is one-way — which means the driver must be
**complete enough to be an endpoint on its own**. A person writing plain
SQL should never need the ORM. That is the test of whether the line is in
the right place.

### 15.1 Describe — the verb the ORM cannot be built without

```avra
/// One result column, as the statement declares it before any row
/// exists. `decltype` is the DECLARED type TEXT (`VARCHAR(255)`,
/// verbatim) and is NULL for an expression or a subquery — so a
/// computed column has no declared type and never will (LAW T13). The
/// last three are the `SQLITE_ENABLE_COLUMN_METADATA` payload, which
/// is why the vendored build sets that flag.
export type ColumnShape = {
    name: string,
    decltype: string?,
    database: string?,
    table: string?,
    origin: string?,
}

/// One parameter slot. `name` is absent for a bare `?`.
export type ParamShape = { slot: int, name: string? }

/// What a statement IS, read without running it.
export type Shape = {
    params: List<ParamShape>,
    columns: List<ColumnShape>,
    writes: bool,
}

impl Db {
    /// Prepare, read the shape, finalize. NEVER step: preparing a DDL
    /// statement does not execute it and preparing a DML statement
    /// does not either, which is exactly what makes this safe to run at
    /// COMPILE time against a schema-only database (§15.3).
    fn describe(q: Query) -> Result<Shape, SqliteError>
}
```

`params: List<ParamShape>` rather than `List<string?>`, because a list
slot may not be a nullable (`language/typing_declare.av:113-121`), and
because the slot number is worth carrying anyway.

**The ceiling, stated so the ORM is not designed as if it were absent:**
SQLite will tell you how many parameters a statement has and nothing
about their types. A compile-time checker can verify column names, column
count and result types; for parameters it can verify only ARITY. Type
checking a parameter means inferring it from its syntactic position
(`WHERE email = ?` against a known column), which is the ORM's job.

### 15.2 The rest of the list, ranked as the ORM feels it

| what | why the ORM is hurt without it | in this design |
|---|---|---|
| typed values with the class readable per value | a column declared INTEGER may hold TEXT; an ORM must see it | `Sql`, §3 |
| `float` and `bytes` | REAL and BLOB have no representation at all | the campaign's prerequisites |
| refusal on an under-filled statement | an unbound slot is a silent NULL | `Cause.Unfilled`, §6.1 |
| truthful autocommit | "am I in a transaction" answered by tracking is a lie | `db.in_transaction()`, §12.5 |
| the EXTENDED code | otherwise every constraint failure is one undifferentiated error and the ORM regexes English | `SqliteError.extended` + `Cause`, §5 |
| the statement cache with the reset ritual as one verb | its correctness depends on discipline the ORM cannot see | §10 |
| `describe` without stepping | there is no other way to get a row shape before a row | §15.1 |
| `last_insert_rowid` + `changes64`, with the caveats published | the identity path when RETURNING is unavailable | §6, and LAW Q4/Q5 quoted at the verbs |
| savepoints with driver-minted names | nested transactions AND the roll-back-per-test-case pattern every ORM test helper uses | §9.3 |
| streaming without materialising | a report over a large table | `each`, §12 |
| reflection as typed records | a migration cannot diff without them | §15.4 |
| `SQLITE_LIMIT_VARIABLE_NUMBER` | otherwise every generated `IN (…)` is a latent crash at 1000 elements | `db.limit`, §12.5 |
| binding by NAME | the raw-SQL escape hatch is unusable without it | `named`, §6.1 |
| the origin triple | join hydration, writable result sets, nullability inference — the single largest quality delta | `ColumnShape`, §15.1 |
| `sqlite3_error_offset` | the compile-time span story; one C call, and nothing else buys as much | `SqliteError.at`, §5.1 |
| RETURNING classified by `column_count`, never by the leading verb | otherwise the ORM special-cases its whole write path | C5 |

### 15.3 The two later expansions, and the constraints they place on this design NOW

**COMPILE-TIME-CHECKED SQL.** The compiler can open `:memory:`, run the
package's migrations, `sqlite3_prepare_v3` the query, read the describe
and finalize — never step. That is sqlx's fidelity with sqlc's
hermeticity, from the same engine that will run the query in production,
which no system in the field has both of. Two constraints it places here,
and both are already met:

1. **The SQL text must reach the compiler as a literal it can read**, so
   `Query.text` is a `string` on the primary path and the C-string
   conversion stays inside the driver, below the API.
2. **`Query` is a VALUE with a text field and an args field.** A checker
   reads it. A builder that assembled SQL inside the driver would have
   nothing to read.

And the thing nobody else has: `sqlite3_error_offset` gives the byte
offset of the failing token; mapped into the string literal's own span it
underlines the exact word, in the `.av` file, with an F-code, help and a
structured fix. sqlx reports the error; it does not point at the
character.

**`table<Row> { … }` BACKED BY SQLITE.** The language already has a typed
table literal. Backing it means the same literal is a fixture in a test
and a persisted table in a service. The constraint it places here: the
driver's row path must be expressible generically over a row type later —
which is why `Row` is DATA (`cells` + `names`) rather than a closed
object with private readers. A derive that generates `note_of` writes an
ordinary fn against an ordinary value.

### 15.4 Reflection is a query, so it costs nothing

Since 3.16.0 every side-effect-free pragma is also a table-valued
function: `SELECT * FROM pragma_table_xinfo('users')`, joinable and
filterable. So the driver grows no reflection subsystem; it grows
nothing, and reflection is a schema over the query surface it already
has (P6). What it does ship is the ROWS as typed records — `ColumnInfo`
from `table_xinfo` (not `table_info`, which hides generated and hidden
columns a migration diff must see), `ForeignKeyInfo`, `IndexInfo`,
`TableInfo` — because those are facts about SQLite, not about any
mapping. The schema CACHE and its invalidation are a policy and live
above the line; `PRAGMA schema_version` is the token they key on, and the
driver exposes it and does not use it.

---

## 16. THE DRIVER'S OWN CODE, WHERE IT IS LOAD-BEARING

Three fns. Each is where a law of the research reports becomes a line.

### 16.1 One cell — the class is asked first, and the errcode is adjacent

```avra
/// One cell, copied into a box Avra owns. The CLASS is asked first and
/// the pointer is never tested to decide what was found:
/// `sqlite3_column_blob` answers NULL for SQL NULL, for a ZERO-LENGTH
/// BLOB and for an out-of-memory alike (LAW S16, LAW S17).
fn cell(h: Stmt, i: i32) -> Result<Sql, SqliteError> {
    let class = sqlite3_column_type(h, i)
    when {
        class == class_null() -> Sql.Null
        class == class_integer() -> Sql.Int(sqlite3_column_int64(h, i))
        class == class_real() -> Sql.Real(sqlite3_column_double(h, i))
        class == class_text() -> Sql.Text(text_cell(h, i)?)
        _ -> Sql.Blob(blob_cell(h, i)?)
    }
}

/// A TEXT cell. VALUE FIRST, THEN LENGTH (LAW S14): asking
/// `column_bytes` first on a column holding an INTEGER converts the
/// value to TEXT to measure it, and the following read answers the
/// rendering rather than the integer. `column_text` never answers NULL
/// for a TEXT cell — a text is zero-terminated even when empty (LAW
/// S15) — so NULL here is an allocation failure and nothing else.
fn text_cell(h: Stmt, i: i32) -> Result<string, SqliteError> {
    let p: ptr? = sqlite3_column_text(h, i)
    if p == null { fail no_memory(h) }
    text_from_host(p!, sqlite3_column_bytes(h, i))
}

/// A BLOB cell. NULL means a zero-length blob OR an out-of-memory, and
/// the errcode is the only thing that tells them apart — so it is asked
/// IMMEDIATELY: no other SQLite call between the read and the check, no
/// `?`, no `fail`, and no `defer` frame open in this fn.
///
/// THIS IS THE LAW THE PROBE LOG NAMES (§2b): a `?` between the suspect
/// read and its check runs every open frame's deferred calls first, so
/// a `defer stmt.reset()` twenty lines up fires in the gap and the
/// errcode is already gone. `blob_cell` has no `?` before its check and
/// no `defer` anywhere.
fn blob_cell(h: Stmt, i: i32) -> Result<bytes, SqliteError> {
    let p: ptr? = sqlite3_column_blob(h, i)
    if p == null {
        let rc = sqlite3_errcode(sqlite3_db_handle(h))
        if rc == rc_nomem() { return failed_with(h, rc) }
        return empty_bytes()
    }
    bytes_from_host(p!, sqlite3_column_bytes(h, i))
}
```

Four properties worth naming:

- **`when` rather than an if-ladder**, and `class` bound once — the
  tree's dispatch idiom, and I13 (the same projection twice binds a
  local).
- **The pointers answer `ptr`, never `string`.** A foreign `const char*`
  crossing as an Avra `string` *appears* to work — an untagged pointer
  no-ops retain and release, and `str_len` falls back to `strlen` — and
  hides a lifetime, a length and a NUL all at once. `AVRA_RC_GUARD`
  cannot see it: it watches retain and release EVENTS, and an untagged
  pointer raises none, so it prints clean for a correct borrow and a
  use-after-free alike. This is the one seam in the tree where the
  instrument of record is silent by construction, and the answer is the
  copy at the boundary (probe log §6).
- **`text_from_host` / `bytes_from_host` are runtime rows**, one `memcpy`
  each into a headered box, and `str_box` allocates `n + 1` and writes
  the NUL itself (LAW S15).
- **An empty blob answers an EMPTY BOX, never null** — lane D's rule, and
  the reason the empty/absent collision stays at the C boundary and never
  enters Avra (probe log §2b: an empty list, an empty string, a
  zero-field record and a zero all read PRESENT through a nullable, on
  both engines).

### 16.2 One transaction — the wrapper that cannot be written blind

```avra
/// The body inside one transaction. Depth 0 is `BEGIN IMMEDIATE`,
/// deeper is a savepoint the driver named. The body's answer is the
/// transaction's answer: compute, then commit or roll back, then
/// answer — never a `defer` deciding it.
fn tx(body: fn() -> Result<int, SqliteError>) -> Result<int, SqliteError> {
    let d = self.deeper()
    self.opened(d)?
    match body() {
        .Ok(v) -> { self.settled(d)?; v },
        .Err(e) -> { self.unwound(d); fail e },
    }
}

/// Close the frame on success: RELEASE inside, COMMIT at the top. A
/// COMMIT refused as BUSY leaves the transaction OPEN and is retried
/// (LAW X5); a retry that still fails rolls back rather than leaving a
/// write transaction to block every other writer until close.
fn settled(d: int) -> Result<int, SqliteError> {
    if d > 1 { return self.exec("RELEASE ${savepoint(d)}") }
    match self.exec("COMMIT") {
        .Ok(v) -> v,
        .Err(e) -> { if e.cause is .Busy { return self.commit_again() } self.unwound(d); fail e },
    }
}

/// Close the frame on failure, and NEVER blindly. Some errors roll the
/// transaction back by themselves — FULL, IOERR, BUSY, NOMEM, INTERRUPT
/// (LAW X4) — and a ROLLBACK issued after one answers "cannot rollback
/// - no transaction is active", which a wrapper then reports INSTEAD of
/// the real error. So SQLite is asked whether a transaction is still
/// open, and the answer decides. Nothing here can fail into the
/// caller's channel: the body's error is the one that travels.
fn unwound(d: int) {
    self.shallower()
    if self.in_transaction() { return }
    if d > 1 {
        let _ = self.exec("ROLLBACK TO ${savepoint(d)}")
        let _ = self.exec("RELEASE ${savepoint(d)}")
        return
    }
    let _ = self.exec("ROLLBACK")
}
```

`ROLLBACK TO` does not pop the savepoint — *"the ROLLBACK TO command
restarts the transaction again at the beginning"* — so the `RELEASE`
after it is not optional (LAW X6). Its absence leaks a stack entry per
failed inner block and the outer `RELEASE` then closes the wrong frame.

### 16.3 One query — the whole path, and what it costs

```avra
/// Every row, materialised. The cached statement is reset and cleared
/// before it is bound (LAW S7), the slot count is checked against the
/// values before anything is bound (LAW S6), and the column names are
/// read ONCE and shared by every row of the answer.
fn all(q: Query) -> Result<List<Row>, SqliteError> {
    let h = self.cached(q.text)?
    self.bound(h, q)?
    let names = self.names_of(h)
    mut out: List<Row> = []
    mut rc = sqlite3_step(h)
    while rc == rc_row() {
        out.push(Row { cells: [cell(h, i)? for i in 0..sqlite3_column_count(h)], names: names })
        rc = sqlite3_step(h)
    }
    if rc != rc_done() { return self.failed(h, rc, q.text) }
    out
}
```

The loop earns its keep on two grounds DOGFOODING allows: `?` propagation
in the body, and a stateful transform (`rc` is a step's answer, not an
index). The inner map is a comprehension over the range, which is the
only list built per row.

**The measured budget this design commits to** (`RESEARCH_semantics_traps.md`
§IX.2, restated for the shapes above):

| property | budget |
|---|---|
| SQLite calls per column read | ≤ 3 — `column_type`, the value fn, `column_bytes`; a scalar is 2 |
| `strlen` calls per bind and per read | 0 — the header carries the length on both sides |
| prepares per distinct SQL text per connection | 1 |
| allocations per TEXT/BLOB cell | exactly 1 — the mandatory copy of LAW S12, sized from `column_bytes`, never a second copy for a diagnostic |
| allocations per row, `all`, ncols columns | 1 for the cell list, + 1 per non-scalar cell, + whatever `List<Sql>` costs per element |
| allocations per row, `each` | the same, freed each turn: O(1) rows live |
| interpreted vs native answers | identical, by construction — the interpreter hosts the externs (the campaign's dlsym decision), so `eval == native` is a test, not a hope |

That last row of the allocation budget is the honest one and it is
**MEDIUM confidence**: whether a `List<Sql>` element costs a box depends
on the enum layout, which is a compiler fact this design has not
measured. If it does, the fix is a compiler-side layout for
scalar-payload enums (**ASK 7**) and NOT an API change — which is why the
budget is written as a measurement to take rather than a number to trust.
`AVRA_MEM_STATS=1` answers it: live bytes by category, by list capacity,
and by the allocation site that made them.

---

## 17. THE PACKAGE, AND HOW IT IS PROVED

```
packages/std-sqlite/
  avra.toml            [link] objects = the vendored amalgamation
  vendor/sqlite3.c     3.53.4, 269,649 lines, our flags
  src/
    sqlite.av          Db, Query, Row, Sql, Class, SqliteError, Cause, the verbs
    raw/mod.av         every extern fn, every constant as a fn
    blob.av            BlobIo
    shape.av           describe, and the reflection records
    tests/
      sqlite_test.av              the surface, per verb
      sqlite_adversarial_test.av  the red-team catalogue
```

Three test facts shape the suites from the first line:

- **A `then` answers `bool` and may not carry `?`.** So every suite
  hoists its work into named `Result`-answering helpers above the spec
  block and each case compares one exact string — the shape
  `@std/process`'s adversarial suite takes with 25 helpers feeding 35
  one-line cases. `shown(r)` folds ok and err into one string; `kind(e)`
  turns a cause into `tag:payload`.
- **A trap kills every later case in the package.** All of a package's
  cases run in one process, in declaration order, in one address space,
  with no isolation. A segfault in a driver case is a trap. So a
  connection leaked in case 3 is still open in case 40, and the fixture
  discipline is `@std/io`'s: **cleanup is BEFORE, not after** — `fresh()`
  clears what an earlier run left and then answers the path, so nothing
  depends on a case having finished.
- **`avra test` compiles the cases to LLVM and links a native binary**,
  and the link line carries every package's `[link]` promise. So spec
  cases can call SQLite today, natively, with no compiler change. That
  is the campaign's most important machinery fact.

`:memory:` is the default fixture, and `sqlite3_serialize` /
`sqlite3_deserialize` are the better one: build the schema once,
serialize the image, deserialize a fresh copy per case in microseconds.
Both are on by default since 3.36.0.

### 17.1 Idiom compliance

The design was written against the bar rather than cleaned up afterwards.
Where it touches a registry entry:

| idiom | where |
|---|---|
| I22 (a registry spells every arm) | `Cause.kind()`, `Sql.class()`, the four `as_*` projections, `cell`'s `when`; `or`-runs keep them one line |
| I18 (a guaranteed projection read with a plausible default is a silent wrong answer) | the whole of C2: `sqlite3_column_int` on `"abc"` → `0` is `?? 0` implemented in C, and §7.4 refuses to forward it |
| I13 (the same projection twice binds a local) | `let class = …` in `cell`; `let raw = r.cells[2]` in `user_of` |
| I10 (an if-ladder mapping a value to values is a `when`) | `cell` |
| I3 / the comprehension | `all`'s inner cell map, `users_in`, `recent` |
| I12 (an identical struct literal twice is a constructor) | `sql()` and `named()` are the two mints, and no call site writes `Query { … }` |
| I28 (a law never assembles prose) | every refusal is one named voice fn — `mismatched`, `unfilled`, `no_memory`, `stale_snapshot` — in a voices section at each file's tail |
| I36 (text grown by `s = s + piece` in a loop) | nothing in the driver builds SQL by concatenation, which is C5 from the other side |
| I34 (the borrow under a same-scope read) | `deeper()`'s `mut d = self.depth` is the rebind-alias idiom, not a same-scope borrow |
| I35 (a raw scope bracket) | the driver emits no IR; its `defer` use is `errdefer { let _ = … }` in `batch` alone, and §16.1 says why it is nowhere near a cell read |

---

## 18. LANGUAGE ASKS

Each names the construct, the site in THIS design that wants it, and what
the design does until it lands. **ASK 0 is a campaign prerequisite** and
is listed only so the wall's `mut` seats are not mistaken for a new
request. The rest are what remains after `float`, `bytes` and out-params
have landed.

### ASK 0 — `mut` seats on an `extern fn` (prerequisite, not new)
`extern fn sqlite3_open_v2(path: ptr, mut db: Conn, …) -> i32` — refused
today, `F0100: expected ')'`. **Wanting sites:** `open_v2`,
`prepare_v3`, `blob_open`, `wal_checkpoint_v2` (§13). **Until then:** the
driver cannot open a database. The cause is one line — `features/fns/mod.av:32`
lacks the `( mk:"mut" )?` that `:33` has.

### ASK 1 — `opaque type T @free_with(f)`, and the drop that makes it real
**Wanting sites:** `Conn` (§3), `Stmt` (§10), `BlobIo` (§11). **What the
design does until then:** nothing that works. `close_v2`, `finalize` and
`blob_close` would each become a `defer` in every user's code — which is
exactly the problem spec 15.5 exists to solve, and the reason nearly
every language's SQLite binding has a connection-leak bug in its issue
tracker. **This is the ask that makes §4.2 a guarantee rather than a
convention.**

### ASK 2 — a generic answer behind a fn-typed parameter
`fn tx<T>(body: fn() -> Result<T, E>) -> Result<T, E>` and
`fn fold<A>(q: Query, seed: A, step: fn(A, Row) -> Result<A, E>) -> Result<A, E>`.
Today `T` is only evidenced by the fn argument, which carries no
T-evidence, and pinning `<T>` over one corrupts scalar payloads through
mono (DOGFOODING.md, Generics). **Wanting sites:** `Db.tx` (§9.2), the
`fold` that does not exist (§12.3). **Until then:** `tx` answers `int`,
and streaming aggregation is a SQL aggregate or an effect.

### ASK 3 — a lambda in an ARGUMENT seat hears the seat's answer
Today a lambda there types on its own, so `?` inside it names the lambda
rather than the enclosing fn; a typed `let` first is the workaround.
**Wanting sites:** `db.tx(work)` (§9.2), `db.each(q, step)` with a
capturing step (§12.3). **Until then:** every scoped-body call site
carries a `let name: fn(…) -> Result<…> = …` line whose only job is to
say what the seat already knows. Already a known subset entry; this
design adds two more wanting sites and a shape (a driver's bracket verb)
that will keep producing them.

### ASK 4 — `Result<T?, E>`
`fn f() -> Result<int?, E>` is refused: *"a `Result` slot cannot hold
this yet"* (`features/results/tests/results_test.av:166-169`). **Wanting
sites:** the ten nullable readers that should exist on `Row`
(`int_or_null` … `bool_or_null`, §7.5), and `db.first(q) -> Result<Row?, E>`
(§6). **Until then:** a nullable column costs a class guard and a typed
local at every row reader in every program, and there is no `first` verb.
**This is the largest ergonomic ask in the list**, because a nullable
column is the commonest thing in a database.

### ASK 5 — `@borrows(param)`, the `SQLITE_STATIC` contract
Spec 15.4's annotation is exactly SQLite's `SQLITE_STATIC` rule: *C
borrows the parameter for the duration of the call; Avra retains
ownership*. **Wanting site:** `bind_text64` / `bind_blob64` (§8.3).
**Until then:** every bind is `SQLITE_TRANSIENT` — one `memcpy` per bind,
which is nothing for a 40-byte string and 10 MB per bind for a 10 MB
blob. The reason it cannot be skipped today is precise: a `CallRt`
argument is BORROWED (CLAUDE.md's runtime-row law), so the Avra box is
freed at the enclosing scope's exit and the next `step` reads freed
memory. This is the P6 answer to "safe or fast" and it is one annotation.

### ASK 6 — `@derive Row`, a row reader generated from a struct
`note_of` in §1 and `user_of` in §7.2 are mechanical: field order, field
type, the class guard for a nullable. **Wanting site:** every row type in
every program. **Until then:** the reader is hand-written — which is a
NAMED FN, which is exactly what the derive will emit, so **the call site
never changes when it lands**. That is why the design uses a named fn
rather than a lambda or a trait: the ceremony is in a place a derive can
take over without moving anything.

### ASK 7 — an enum of scalar payloads that rides registers
`List<Sql>` is one allocation for the list plus, if a payload enum is
boxed, one per cell. **Wanting site:** `Row.cells` (§16.3), on every row
of every query. **Until then:** measure it (`AVRA_MEM_STATS=1`) before
claiming a per-row budget. This is a compiler-side layout question and
**must not be answered with an API change** — the API is right either
way.

### ASK 8 — A TAGGED INTERPOLATION: `sql"select … where id = ${id}"`
**The headline ask, and the one that would delete the last ceremony from
§6.** A tag names a fn; the compiler hands it the literal PIECES and the
HOLE VALUES separately, instead of concatenating them:

```avra
// what the design wants
db.all(sql"select id, email from users where city = ${city} and age >= ${min}")?

// exactly what it means, and the library is IDENTICAL
db.all(sql("select id, email from users where city = ? and age >= ?", [.Text(city), .Int(min)]))?
```

The desugar is `sql_parts(pieces: List<string>, holes: List<Sql>) -> Query`:
the pieces join with `?` between them, and each hole becomes a `Sql` by
its own Avra type — which the compiler already does one axis over for
`${}` in a plain string, where `type.interp_hole` dispatches on the
hole's type to project it to TEXT. This dispatches it to a VALUE instead.

**Why it is more than sugar, and why it belongs to the LANGUAGE and not
to this driver:**

- It is CLAUDE.md:258 one level up. *A COMMAND IS AN ARGV, never a shell
  line*: `avra_spawn_status(prog, args)` exists so no character in a path
  means anything but itself. A tagged interpolation is the same law for
  every embedded language — SQL, shell, HTML, a path — and it makes
  injection unrepresentable rather than discouraged.
- It deletes an entire error class from P1's path. An LLM writing
  `"… where id = " + id` is writing the injection; an LLM writing
  `sql"… where id = ${id}"` is writing a bound parameter. The shape it
  reaches for FIRST becomes the correct one.
- It makes bind arity unmistakable: there is one hole per value, so
  `Cause.Unfilled` becomes unreachable from the sugared form.
- It is the surface the compile-time SQL checker wants: the pieces are
  literals the compiler can read and the holes are typed expressions it
  already types (§15.3).

**Wanting site:** every call in this document. **Until then:** `sql(text, args)`,
which is the same value spelled in two arguments.

### ASK 9 — `?.` and a method after `?` on a `Result`
`(db.scalar(q)?).as_int()` needs its parens because `x()?.f` lexes as
`?.` and refuses for a `Result` (F2023, whose help says "write `.out`" —
wrong for propagate-then-read). **Wanting site:** `count_notes` (§5.2),
every scalar read. Already a subset entry; this adds a high-traffic site.

### ASK 10 — a trailing lambda
`db.tx { … }` refuses; the spelling is `db.tx(work)`. **Wanting site:**
`tx`, `read_tx`, `each`. With ASK 3, this is what makes a scoped-resource
verb read as a block rather than as a call.

### ASK 11 — `List<T?>`
Refused for every `T` (a list slot is one word). **Wanting site:**
`Shape.params`, which wants `List<string?>` and takes `List<ParamShape>`
instead (§15.1). The workaround is honest here and worse elsewhere.

### ASK 12 — variadics on an extern, or a narrow extern over a variadic symbol
`sqlite3_db_config(db, op, …)` is the only way to turn DQS off per
connection, and it is variadic. Apple's arm64 ABI reads variadic
arguments from the STACK, so calling it through a non-variadic prototype
is wrong on the platform this tree is developed on — this cannot be
worked around by declaring a narrow signature. **Wanting site:** the
belt-and-braces DQS setting at open (§4.3). **Until then:** the vendored
build's `-DSQLITE_DQS=0` is the braces alone. The grammar needs one
token, the row one field, and `language/llvm.av:189-195` already carries
the `vararg` knob hard-wired `false`.

### ASK 13 — a package declares its own native build
`[link] objects = […]` names an object that must already exist, and
nothing in `avra.toml` says how it comes to exist. **Wanting site:**
`packages/std-sqlite/vendor/sqlite3.c` — a consumer who adds this
dependency gets a manifest pointing at an object no step in their build
produces. **Until then:** `@std/sqlite` can be built in this tree and not
shipped. A toolchain ask, with the same argv discipline the `[link]` rows
already have.

### ASK 14 — `null` into a `ptr` seat
`ptr?` works and reads a C NULL correctly (probe log §2); passing `null`
INTO a `ptr` seat is the missing half. **Wanting sites:**
`sqlite3_open_v2`'s `vfs` argument, `sqlite3_wal_checkpoint_v2`'s `name`
(§13.1).

### ASK 15 — a `ptr` sentinel verb
`SQLITE_TRANSIENT` is `(void*)-1`. **Wanting site:** every `bind_text64`
and `bind_blob64` (§8.3). There is no bind path without it. One `@std/c`
fn or one runtime row.

---

## 19. WEAKNESSES

Where this philosophy costs something. Written to be attacked, so the
attack lands on the real thing.

**W1 — P4 is not satisfied for a large scan, and the default path is the
one that pays.** C3 makes every row materialised, so a scan of a hundred
million rows allocates a `List<Sql>` per row even when the step reads two
integers and keeps nothing. The zero-copy path — read the columns off the
live statement inside the step — exists only at the raw wall (§13). The
vision's own words are *"the fastest path is the DEFAULT path, not an
expert's exception"*, and for a scan this design fails that test. The
defence is that the alternative (a borrowed cursor) cannot be made safe
without a lifetime the language does not have, and that a borrowed cursor
was the field's commonest bug. It is a defence, not a denial.

**W2 — `db.tx` answers `int`, and that is an amputation.** A transaction
that builds a `List<User>` cannot answer it. The workaround (write it,
read it after) is worse than the problem, and the real workaround — the
raw `begin`/`commit` bracket — puts back exactly the ceremony §9 deleted.
ASK 2 is the fix and until it lands, `tx` is a second-class verb next to
`batch`.

**W3 — a transaction cannot span function boundaries.** `db.tx(body)`
brackets a body; there is no `Tx` VALUE a caller can hold, pass and
commit elsewhere. That shape needs a drop (ASK 1) AND a must-use
obligation, because an uncommitted `Tx` that rolls back at scope end
while the fn answers success is a silent wrong answer — the exact
critique of Rust's `Transaction`. This design refuses to ship the value
without the obligation, and so ships neither.

**W4 — the nullable column bends C2, and it bends it in the commonest
place.** §7.5's guard is correct but it is three tokens of ceremony in
the one line every row reader has. Worse, the shorter spelling a hurried
caller will reach for — `r.text(2) catch null` — swallows a class
MISMATCH as absence, which is the exact silent-wrong-answer this design
exists to refuse. The design cannot prevent it; it can only not
recommend it.

**W5 — twenty-six `Cause` arms is a maintenance surface, and `.Other`
is a catch-all wearing a name.** A new SQLite extended code lands in
`.Other` silently, which is the failure mode I22 exists to prevent, one
level out from where the compiler can enforce it. The mapping from
extended code to `Cause` is a hand-written table with no gate; the
honest mitigation is a test that enumerates every extended code SQLite's
header declares and asserts its arm, and that test does not exist yet.

**W6 — the statement cache is keyed by SQL TEXT, and that is a hash and
a compare on every call.** rusqlite documents its own version of this as
"kind of sub-optimal". A query built by concatenation never hits, and the
cache then silently becomes a bounded leak of near-identical statements.
The cache's bound makes it survivable; it does not make it good. The real
fix is upstream — a query whose text is a compile-time literal has a
compile-time key — which is ASK 8's second payoff.

**W7 — `Query`'s `named` field costs something on every query that does
not use it.** A record with a `Map` default pays for the empty map at
every mint. C1's "one value, both binding styles" is bought with an
allocation the positional path never wanted. Measure before defending;
if it is real, the fix is two query types and C1 loses.

**W8 — `Db` is a record with shared mutable state reached through
copies.** The depth cell and the cache are correct only because a list is
a pointer and a receiver's direct field writes through. That is exactly
the seam CLAUDE.md warns about (A BORROW ALIASES, A PATH WRITE THROUGH A
SHARED INTERMEDIATE COPIES): the day someone nests the depth one level
deeper, a savepoint counter starts writing into a copy and the nesting
silently targets the wrong frame. It needs a test that opens a nested
transaction through a COPIED `Db` and asserts the depth, and that test is
the first one to write.

**W9 — no threads, and the design cannot yet say so in the type system.**
LAW K10 wants `SQLITE_THREADSAFE=2` plus one owner at a time; Avra has no
facility to express "one owner at a time", so the constraint lives in
prose and in the API's shape. P2 (substrate for autonomous services) is
therefore promised and not yet kept.

**W10 — the UTF-8 checkpoint is opt-in, so `string`'s invariant is
advisory at this boundary.** `r.text(i)` hands back whatever bytes
SQLite stored. That matches the tree's status today (the invariant is
already violable) and it is still an invariant this driver could have
enforced and chose not to, for a per-cell scan. A judge is entitled to
call that the same coercion the design refuses everywhere else; the
answer is that it is a different axis and that `text_utf8` is one word
away, and that answer is weaker than the rest of C2.

**W11 — the design leans on asks for its best lines.** §1's one-liner is
real today; §9's `tx`, §12's capturing step and every nullable read are
not as short as they read here without ASKs 2, 3 and 4. The document is
honest about which, but a reader who skims the code and not the marks
will over-estimate what compiles.

---

## BLOCKERS

Everything that stops this design from being written, beyond the
campaign's three prerequisites. Each has a proposed shape.

**B1 — no `opaque type` and no drop (ASK 1).** Without it there is no
`Conn`, no `Stmt` and no `BlobIo`, so §4.2's ownership story is prose and
§10's cache cannot own anything. **Shape:** spec 15.5 as written —
`opaque type Conn @free_with(sqlite3_close_v2)`, values are heap
pointers, drop calls the named fn at the last release. It needs the
annotation grammar (nothing in Axis 15 lands without it) and a Drop hook
in the memory pass, which already has the seam.

**B2 — `Result<T?, E>` is refused (ASK 4).** Blocks ten row readers and
the `first` verb. **Shape:** the compiler's own help already names it —
*"nullable slots arrive with ownership's next slice"*. A `Result` payload
is not an aggregate slot, so this may be narrower than the general
nullable-slot work; measure that first.

**B3 — a generic behind a fn-typed parameter corrupts scalar payloads
(ASK 2).** Blocks `tx<T>` and `fold<A>`. **Shape:** a fn argument's
DECLARED signature is T-evidence, and mono keys on the pinned type rather
than on what it can see through the seat. This is a mono question, not a
typing one, and it has three customers beyond this driver.

**B4 — no variadic extern (ASK 12).** Blocks `sqlite3_db_config`, hence
the per-connection half of the DQS defence. **Shape:** one grammar token
(`...` in the extern's parameter list), one row field, and the `vararg`
knob at `language/llvm.av:189-195` stops being hard-wired `false`. The
interpreter refuses variadics and says so, per the extern-host report's
recommended order.

**B5 — no `null` into a `ptr` seat and no `ptr` sentinel (ASKs 14, 15).**
Blocks `open_v2`'s `vfs` argument and every `bind_text64`/`bind_blob64`.
**Shape:** one widening edge, and one `@std/c` fn answering `(void*)-1`.
Both are the smallest items in the campaign and both are on the critical
path to the first bound parameter.

**B6 — a package cannot build its own vendored C (ASK 13).** Blocks
SHIPPING, not building. **Shape:** a manifest section naming sources,
flags and an output, run before linking, through
`avra_spawn_status(prog, args)` — no shell line, so no character in a
path means anything but itself.

**B7 — no trait impl over a generic type (F2031).** Not blocking this
design, and named because it is what a different design would have hit: a
generic decoding trait (`impl Decode for Column<T>`) does not land. This
design has no such trait, which is a reason to prefer it, not an accident.

---

## CONFIDENCE LEDGER

| claim | how verified | confidence |
|---|---|---|
| A record type may declare defaulted fields, including a bare-variant default (`Config`, `Query`) | read `packages/std-process/src/process.av:107-119` — `stdin: Stdin = .Closed`, `env: Env = minimal()` | HIGH |
| A struct field may hold a nullable POINTER (`sql: string?`, `at: Loc?`) and may NOT hold a nullable scalar (`at: int?`) | read the law at `packages/std-avrac/src/language/typing_declare.av:113-121` — *"a slot inside an aggregate holds ONE WORD … a scalar nullable is a register PAIR"*; `Tool.terminator: string?` at `process.av:61` is the working instance | HIGH |
| `List<T?>` is refused for every `T` | ROADMAP.md's NULLABLE SLOTS entry: *"lists now refuse the same way at BOTH construction paths"* | HIGH |
| `Result<T?, E>` is refused | the tree's own test: `packages/std-avrac/src/features/results/tests/results_test.av:166-169`, pinned to *"a `Result` slot cannot hold this yet"* | HIGH |
| `?` works in a comprehension's ELEMENT and ITERABLE | CLAUDE.md's idiom bar, item 1; and the subset entry *"in a comprehension element too"* | HIGH |
| A NAMED fn in a mapper/lambda seat works everywhere including `?`; a LAMBDA there does not hear the seat's answer | CLAUDE.md, The subset today — *"a NAMED fn in the seat works everywhere, `?` on the field's call included"* | HIGH |
| A generic pinned over a fn-typed argument corrupts scalar payloads through mono | DOGFOODING.md, Generics — *"never thread fn args through generics"*. NOT probed here | MEDIUM as a measurement, HIGH as a prohibition |
| `is` takes a bare variant even when the variant carries payloads (`e.cause is .Unique`) | CLAUDE.md, The subset today — *"`e is .TimedOut` is the test"* | HIGH |
| `fail` in a `catch` arm is refused; `fail` in a braced `match` arm is not | CLAUDE.md, The subset today (F2029, and the braced-arm entry). The match-arm half is INFERRED from the absence of a refusal, not probed | HIGH / MEDIUM |
| A trailing lambda (`db.tx { … }`) refuses; `db.tx(body)` is the spelling, and a lambda in an argument seat is accepted | probe log Part II and §5 — `tx(() -> 42)` accepted, `tx { 42 }` refused | HIGH |
| `extern fn` cannot take a `mut` seat; the cause is `features/fns/mod.av:32` lacking `( mk:"mut" )?` | probe log Part II, quoted refusal `F0100: expected ')'` and the two grammar lines side by side | HIGH |
| A C NULL crosses as Avra `null` through `ptr?` at no cost | probe log §2, built and run against libc `getenv`; and `features/values.av:229-231` gives the niche layout | HIGH |
| A foreign `const char*` declared `-> string` works by accident and hides a lifetime, a length and a NUL; `AVRA_RC_GUARD` cannot see it | probe log §6, run, with the mechanism read in `runtime/avra_runtime.c:68` (`hdr`) | HIGH |
| An empty blob must answer an EMPTY BOX and not null; empty and absent stay distinct inside Avra | probe log §2b, run on both engines across four representations | HIGH |
| `sqlite3_column_blob` answers NULL for SQL NULL, a zero-length blob and an OOM alike; the errcode must be read immediately | `sqlite3.h:5411` and `:5519-5525`, quoted in the probe log §2a | HIGH |
| `defer` + `?` can eat an errcode between a suspect read and its check | mechanism from the lane that built `defer`, recorded in probe log §2b; NOT reproduced (needs an open connection) | MEDIUM |
| SQLite semantics cited as LAW T*/S*/X*/K*/E*/B*/N*/Q* | each quoted from a SQLite documentation page in `RESEARCH_semantics_traps.md`, with the page named | HIGH |
| 173 of 284 entry points are callable with no new ABI feature; `double` touches exactly four | mechanical classification of the joined header in `RESEARCH_api_surface.md` §2, false positives corrected by hand | HIGH |
| `avra test` links a native binary carrying every package's `[link]` promise, so a spec case can call SQLite today | `RESEARCH_tdd_and_gates.md` §2, read from `packages/cli/src/commands/test.av` and `shared.av:275` | HIGH |
| A `then` may not carry `?` and prints no value on failure; a trap kills every later case in the package | `RESEARCH_tdd_and_gates.md` §3, read from `features/nullable/check.av:241` and `language/test_run.av:160-166` | HIGH |
| The bare-variant list spelling `[.Int(3)]` in an ARGUMENT seat | INFERRED from THE EXPECTED-TYPE CHANNEL (a list literal under a known slot judges elements by the door) plus the hunger protocol for bare variants. NOT probed | MEDIUM |
| A void-returning fn type (`trace: fn(Trace)`) is spellable as a field | `packages/std-avrac/src/features/decls.av:54` holds `ensure: List<fn(DeclId)>`; the BARE (non-list) field form is INFERRED | HIGH / MEDIUM |
| The per-row allocation count of `List<Sql>` | NOT measured. The API is unaffected either way; `AVRA_MEM_STATS=1` answers it | LOW |
| A `string` is a headered box, `.length` is a load, and the UTF-8 invariant is stated but not enforced at every entry | `2026_09_05_STRING_REPRESENTATION.md` (owner-decided, supersedes the legacy spec's 9.15) and `RESEARCH_strings_reconciliation.md` T5 | HIGH |
| Spec citations (15.4, 15.5, 15.6, 31.5) | read in `../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md` via `RESEARCH_avra_ffi_spec.md`. NOTE: the vision now records that tree as LEGACY — these are cited as the origin of a shape, never as law over a decision this tree has made | HIGH as citations, N/A as authority |

