# `@std/sqlite` — THE AVRA FACE: every resource is a scope

> **Status:** design, written to be built from. Sibling to
> `2026_09_05_STD_SQLITE_VISION.md`; the eleven
> `2026_09_05_STD_SQLITE_RESEARCH_*.md` are its evidence and
> `RESEARCH_probe_log.md` is its floor — **code here that contradicts
> the probe log is a defect in this document, not a language ask.**
> `2026_09_05_STRING_REPRESENTATION.md` is DECIDED and binding on
> Parts II, V and VI. `../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`
> is a LEGACY reference: it is cited here for Axis 15's FFI vocabulary,
> which this tree has not superseded, and it does not outrank a decision
> recorded in this `docs/`.
>
> **The thesis:** a database is a set of OWNED, ORDERED resources — a
> connection owns statements, a statement owns its bindings and its
> current row, a blob handle owns a lock, a transaction owns a scope.
> Almost every SQLite binding bug in the field is one of those
> lifetimes outlived. This design spends its whole budget making those
> bugs unwritable, and says exactly which guarantee is the compiler's,
> which is the runtime's, and which is still only a convention.

---

## Part 0 — THE ONE LAW, AND THE TWO PARADOXES IT COLLAPSES

> **THE RESOURCE IS THE SCOPE.** Nothing here is handed to a closure and
> nothing here is closed by hand: a `Db`, a `Stmt`, a `Tx` and a `Blob`
> are values whose END is their type's, and the end that is right is the
> SAFE end — a transaction that never reached `commit` rolls back, a
> cached statement that leaves a walk resets, a connection that leaves a
> scope closes.

### Paradox 1 — "closure-scoped handles" vs "free handles"

GRDB scopes the connection to a block, and it works: *"statement
outlived its connection" becomes unrepresentable rather than diagnosed*
(prior_art §1.7, §2.2). Everyone else hands out free handles and pays in
issue trackers. The field treats this as the trade.

**Both horns are wrong, and Avra can see why.** A generic scope
combinator cannot even be written in this tree: DOGFOODING.md:807 —
*"Fn-typed arguments carry no T-evidence, and pinning `<T>` over one
corrupts scalar payloads through mono — never thread fn args through
generics."* So `fn with_db<T>(o: Open, body: fn(Db) -> Result<T, E>) ->
Result<T, E>` is refused by doctrine before it is refused by the
compiler. And the lambda in that seat would not hear its own answer
type either (CLAUDE.md, The subset today: *"A LAMBDA in a FIELD or
ARGUMENT seat does not read the seat's answer … F2043"*).

The collapse: **closure-scoping is what a language reaches for when it
has no Drop.** Spec 15.5 gives Avra Drop — `opaque type SQLite3
@free_with(sqlite3_close)`, with SQLite as the spec's own worked example
(spec:2989–3029) — and Drop delivers the same guarantee with no closure,
no generic, no capture, and no nesting tax:

```avra
let db = open(at("app.db"))?          // closes when this scope ends
let tx = db.begin(TxMode.Immediate)?  // rolls back unless commit is reached
```

So the design is Drop-shaped, and the closure question never arises.

### Paradox 2 — "materialise the row (safe)" vs "alias it (fast)"

Every binding in the survey makes this trade, and the ones that alias
ship the use-after-free (prior_art §3.5; api_surface §4.2 CLASS 1;
sqlite3.h:5500–5505).

**There is no trade.** `sqlite3_column_text`/`_blob` hand back a pointer
that dies at the next `step`, so an honest driver copies. The copy is
therefore not the safe option's price — it is the ONLY option's price,
and every memory-safe binding pays exactly it (api_surface §4.3). What
IS a choice is *where the copy lands*, and the answer that costs nothing
is: **at the read, into the value the caller asked for.** An INTEGER or
REAL cell copies nothing at all; a TEXT or BLOB cell copies once, sized
from the header. There is no intermediate `Row` object to allocate,
because — see Part VI — **`Row` carries no data.**

### What the two collapses buy, stated as the design's spine

| resource | its scope | what ends it, and how |
|---|---|---|
| `Db` | the binding's scope | `sqlite3_close_v2` — a *zombie* close, so a statement outliving it is safe rather than fatal |
| `Stmt` | the binding's scope | `sqlite3_finalize` when the CALLER owns it; `reset` + `clear_bindings` when the CACHE does |
| `Row` | one step | nothing — it holds no pointer; every read copies at the read |
| `Tx` | the binding's scope | `COMMIT`/`RELEASE` if reached, `ROLLBACK`/`ROLLBACK TO` + `RELEASE` otherwise |
| `Blob` | the binding's scope | `sqlite3_blob_close`, which is also a commit point |
| `Cache` | the binding's scope | finalizes every statement it holds |

---

## Part I — THE GUARANTEE LEDGER

The brief asks which guarantees are the COMPILER's, which the
RUNTIME's, and which are conventions. Here is the whole answer, up
front. "Today" is this worktree at `d96a328`; "landed" is after the
LANGUAGE ASKS of Part XVI.

| # | guarantee | today | landed | enforced by |
|---|---|---|---|---|
| G1 | a connection is closed exactly once | CONVENTION (`defer db.close()`) | **COMPILER** | Drop, `opaque type Db @free_with(sqlite3_close_v2)` (spec 15.5) |
| G2 | a statement that outlives its connection cannot corrupt | **RUNTIME** | RUNTIME | `sqlite3_close_v2` zombifies; the connection dies with its last derived object (semantics_traps LAW S22) |
| G3 | a row read after its step is never a use-after-free | **DESIGN** | DESIGN | `Row` holds no foreign pointer; every read copies inside the read |
| G4 | a row read after its step is never STALE | nothing | nothing | **CONVENTION.** ASK A9 (a walk protocol) removes the escape; ASK A10 (`while let`) removes the `!` |
| G5 | a transaction not committed rolls back | CONVENTION (`errdefer tx.abandon()`) | **COMPILER** | `Tx`'s Drop |
| G6 | a `ROLLBACK` is never issued blind | **RUNTIME** | RUNTIME | `sqlite3_get_autocommit` asked first (LAW X4) |
| G7 | a nested transaction is a savepoint, never a second `BEGIN` | **RUNTIME** | RUNTIME | `get_autocommit` decides at `begin`, and `begin` refuses a second one by name |
| G8 | a cached statement never carries a previous caller's bindings | **RUNTIME** | COMPILER | `reset` + `clear_bindings` in `close()`; Drop makes it unskippable (LAW S7) |
| G9 | a finished walk does not hold a read transaction | **RUNTIME** | RUNTIME | `next()` resets at `.Done` (LAW K3) |
| G10 | an under-filled statement never runs | **RUNTIME** | RUNTIME | `bind_parameter_count` checked in `bind_all` (LAW S6) |
| G11 | a class mismatch never becomes a plausible number | **RUNTIME** | RUNTIME + COMPILER | `column_type` asked first, then refuse (LAW T1, I18); later, checked SQL (P10) |
| G12 | a blob handle used after its row changed | **RUNTIME** | RUNTIME | SQLite answers `SQLITE_ABORT`; the driver names it distinctly (LAW B6) |
| G13 | a `bytes` value never truncates at a NUL | nothing (no `bytes`) | **COMPILER** | the type: `==` is `memcmp`, `.length` is a header load |
| G14 | an `extern fn` never answers `string`/`bytes` | nothing | **COMPILER** | ASK A7 — a named refusal in the compiler |
| G15 | the errcode belongs to the failure it names | **DESIGN** + a test | DESIGN | `SqlError` is built EAGERLY at the failure site (Part IV) |
| G16 | the cache is bounded | **RUNTIME** | RUNTIME | a declared `cap`; a cache with no bound cannot be constructed |
| G17 | a `mut` handle is required to advance a cursor | nothing | nothing | **CONVENTION.** ASK A12 — `mut` does not reach through a `ptr` |
| G18 | the SQL we run is the SQL we checked | nothing | nothing | ASK A20 (comptime SQL, P10) — the campaign's later era |

Two lines of that table are the honest bad news, and they are named
again in WEAKNESSES: **G4** (a stale row is a quiet wrong answer) and
**G17** (`let stmt` + `stmt.step()` compiles, and the compiler cannot
see that anything moved).

---

## Part II — THE WALL, AND THE ONE LAW THAT GOVERNS IT

`packages/std-sqlite/src/raw.av` is the whole C surface, one
`extern fn` per entry point, exported, nothing hidden (P8). It is
mechanical, and it is the reason the beautiful layer can be a projection
rather than a subset (prior_art §0).

**THE WALL LAW, one line:** *the wall answers `ptr` and `int`. Never
`string`, never `bytes`.* It is not this design's invention — it is
`2026_09_05_STRING_REPRESENTATION.md`'s "A FOREIGN POINTER IS NOT A
`string`", quoted: *"Foreign text is COPIED at the boundary, into a real
box."*

```avra
//! @std.sqlite.raw — SQLite's C API, one declaration per entry point,
//! nothing hidden and nothing wrapped. Every answer is `ptr` or `int`:
//! a foreign buffer stays a `ptr` until a copying verb mints an Avra box
//! from it, because a `const char*` SQLite owns carries no header and
//! Avra's whole memory model is the header.

extern fn sqlite3_libversion_number() -> int
extern fn sqlite3_close_v2(db: ptr) -> int
extern fn sqlite3_step(stmt: ptr) -> int
extern fn sqlite3_reset(stmt: ptr) -> int
extern fn sqlite3_finalize(stmt: ptr) -> int
extern fn sqlite3_clear_bindings(stmt: ptr) -> int
extern fn sqlite3_column_count(stmt: ptr) -> int
extern fn sqlite3_data_count(stmt: ptr) -> int
extern fn sqlite3_column_type(stmt: ptr, col: int) -> int
extern fn sqlite3_column_int64(stmt: ptr, col: int) -> int
extern fn sqlite3_column_text(stmt: ptr, col: int) -> ptr
extern fn sqlite3_column_blob(stmt: ptr, col: int) -> ptr
extern fn sqlite3_column_bytes(stmt: ptr, col: int) -> int
extern fn sqlite3_column_name(stmt: ptr, col: int) -> ptr
extern fn sqlite3_db_handle(stmt: ptr) -> ptr
extern fn sqlite3_errcode(db: ptr) -> int
extern fn sqlite3_extended_errcode(db: ptr) -> int
extern fn sqlite3_errmsg(db: ptr) -> ptr
extern fn sqlite3_error_offset(db: ptr) -> int
extern fn sqlite3_get_autocommit(db: ptr) -> int
extern fn sqlite3_changes64(db: ptr) -> int
extern fn sqlite3_total_changes64(db: ptr) -> int
extern fn sqlite3_last_insert_rowid(db: ptr) -> int
extern fn sqlite3_busy_timeout(db: ptr, ms: int) -> int
extern fn sqlite3_extended_result_codes(db: ptr, on: int) -> int
extern fn sqlite3_stmt_readonly(stmt: ptr) -> int
extern fn sqlite3_bind_parameter_count(stmt: ptr) -> int
extern fn sqlite3_bind_parameter_index(stmt: ptr, name: string) -> int
extern fn sqlite3_bind_parameter_name(stmt: ptr, at: int) -> ptr
extern fn sqlite3_bind_null(stmt: ptr, at: int) -> int
extern fn sqlite3_bind_int64(stmt: ptr, at: int, v: int) -> int
extern fn sqlite3_bind_text(stmt: ptr, at: int, p: ptr, n: int, dtor: ptr) -> int
extern fn sqlite3_blob_bytes(blob: ptr) -> int
extern fn sqlite3_blob_read(blob: ptr, into: ptr, n: int, at: int) -> int
extern fn sqlite3_blob_write(blob: ptr, from: ptr, n: int, at: int) -> int
extern fn sqlite3_blob_close(blob: ptr) -> int
```

Three seats of that page do not exist yet, and each is a LANGUAGE ASK,
never a workaround:

```avra
// ASK A2 — an out-param is a `mut` seat, and the (status, out T) pair
// IS a Result. None of these can be spelled today: F0100 "expected `)`".
extern fn sqlite3_open_v2(path: string, mut db: ptr, flags: int, vfs: ptr) -> int
extern fn sqlite3_prepare_v3(db: ptr, sql: string, n: int, flags: int, mut stmt: ptr, mut tail: ptr) -> int
extern fn sqlite3_blob_open(db: ptr, schema: string, tbl: string, col: string, row: int, rw: int, mut blob: ptr) -> int

// ASK A3 — a REAL column's only C door.
extern fn sqlite3_bind_double(stmt: ptr, at: int, v: float) -> int
extern fn sqlite3_column_double(stmt: ptr, col: int) -> float

// ASK A4 and A6 — a BLOB's door, and the destructor sentinel `(void*)-1`.
extern fn sqlite3_bind_blob(stmt: ptr, at: int, p: ptr, n: int, dtor: ptr) -> int
```

The wall is the escape hatch and it is spelled — Part XIV shows the door
from the face down to it, in both directions.

---

## Part III — OPENING AND CLOSING

### The source, and the options that are genuinely a caller's

```avra
/// Which database. `Memory` is a private one per connection —
/// `Uri("file:x?mode=memory&cache=shared")` is how two connections share
/// one, and it is spelled rather than inferred from a magic path.
export enum Source {
    File(path: string)
    Memory
    Temp
    Uri(text: string)
}

export enum Mode {
    ReadOnly
    ReadWrite
    ReadWriteCreate
}

/// The journal the connection asks for. `Wal` needs shared memory, so it
/// needs one host: it is wrong on a network filesystem, and the driver
/// CHECKS what it got rather than assuming (LAW K2, LAW P1).
export enum Journal {
    Wal
    Delete
    Truncate
    Persist
    Memory
    Off
}

/// How durable a commit is. `Normal` under WAL is the documented balance
/// and it LOSES DURABILITY: a committed transaction can roll back after a
/// power loss. That is the caller's decision, so it is a field here and
/// not a default buried in a C file.
export enum Sync {
    Full
    Normal
    Off
}

/// Everything about a connection that is a real choice. What is NOT a
/// choice is absent: extended result codes are always on (without them a
/// UNIQUE violation and a FOREIGN KEY violation are one error), and
/// double-quoted string literals are always off at both DDL and DML (a
/// misspelled column in `WHERE name = "alice"` otherwise becomes
/// `"alice" = "alice"` and returns the whole table).
export type Open = {
    source: Source,
    mode: Mode = .ReadWriteCreate,
    journal: Journal = .Wal,
    synchronous: Sync = .Normal,
    foreign_keys: bool = true,
    busy_timeout: Duration = secs(5),
    cache_kib: int = 8000,
    temp_in_memory: bool = true,
    query_only: bool = false,
    vfs: string? = null,
}

/// A database at a path.
export fn at(path: string) -> Open {
    Open { source: Source.File(path) }
}

/// A private in-memory database: nothing on disk, nothing shared.
export fn memory() -> Open {
    Open { source: Source.Memory }
}
```

### The connection

```avra
/// An open connection. One `sqlite3*`, never a pool: SQLite is a
/// replacement for `fopen`, not for a database server, and a pool over a
/// single-writer in-process library is the survey's clearest abstraction
/// inversion. Concurrency is spelled the way SQLite spells it — WAL, one
/// writer, N readers, each reader its own connection, opened by the
/// caller.
export type Db = { raw: ptr }

/// Open, configure, and PROVE the configuration. A pragma answers the
/// setting actually in force, so every one is read back: a connection
/// that asked for WAL and got `delete` is refused here rather than
/// discovered under load.
export fn open(o: Open) -> Result<Db, SqlError> {
    let db = Db { raw: opened(o)? }
    errdefer db.close()
    let _ = sqlite3_extended_result_codes(db.raw, 1)
    let _ = sqlite3_busy_timeout(db.raw, o.busy_timeout.ms)
    db.refuse_double_quoted_strings()
    db.settle(o)?
}

impl Db {
    /// The pragmas, in the one order that works: foreign keys FIRST,
    /// because `PRAGMA foreign_keys` is a no-op inside a transaction and
    /// every later statement may open one.
    fn settle(o: Open) -> Result<Db, SqlError> {
        self.set_pragma("foreign_keys", bool_word(o.foreign_keys))?
        self.demand_pragma("journal_mode", journal_word(o.journal))?
        self.set_pragma("synchronous", sync_word(o.synchronous))?
        self.set_pragma("cache_size", "${0 - o.cache_kib}")?
        self.set_pragma("temp_store", temp_word(o.temp_in_memory))?
        self.set_pragma("query_only", bool_word(o.query_only))?
        self
    }

    /// A pragma whose answer must equal what was asked. `journal_mode` is
    /// the one that lies most usefully: it answers the mode in force.
    fn demand_pragma(name: string, want: string) -> Result<Db, SqlError> {
        let got = self.pragma(name, want)?
        if !same_word(got, want) { fail pragma_refused(name, want, got) }
        self
    }

    /// Let the connection go. `close_v2`, never `close`: `close` answers
    /// BUSY while any statement, blob handle or backup is still alive and
    /// leaves the connection OPEN — a `defer` that ignores its answer then
    /// reports success and holds the file lock forever. `close_v2` always
    /// succeeds and the connection dies with its last derived object,
    /// which is what makes the order of every other drop here not matter.
    fn close() {
        let _ = self.set_pragma("optimize", "")
        let _ = sqlite3_close_v2(self.raw)
    }
}
```

**The ownership story, precisely.**

- Today `Db` is a one-field record over `ptr`, so CLAUDE.md's flattening
  law applies: *"WHETHER A VALUE RIDES A POINTER IS ITS DECLARATION'S
  ANSWER"* — a one-scalar-field record is flattened and travels as its
  `ptr`. That is fine for the ABI and **fatal for a drop hook**, which is
  why the real feature is `opaque type`, not a struct (prior_art B3).
- A `ptr` is UNMANAGED (`language/memory.av:42–43`), so no retain and no
  release is ever emitted for a handle. **A copied `Db` is a second name
  for one connection, and nothing counts them.** Under Drop that becomes
  a double close, so `opaque type` must carry the refcount — spec 15.5's
  own open question, and this design's answer is the one-slot managed
  BOX (api_surface B-6): the box carries the header, the foreign pointer
  inside it does not.
- Until then, exactly one `defer db.close()` per `open`, at the mint
  site, and the driver's own tests count live connections with
  `sqlite3_next_stmt` and `AVRA_MEM_STATS=1`.

---

## Part IV — THE ERROR, AND HOW A FAILURE READS

```avra
/// Why SQLite refused. A VALUE, never a view: the message is copied at
/// the failure and the codes are taken there too, so nothing a `defer`
/// runs on the way out can change what this says. That is not tidiness —
/// `sqlite3_errmsg`'s buffer is overwritten by the next call on the
/// connection, and Avra's `defer` fires on the way out of a `?`.
export type SqlError = {
    code: int,
    extended: int,
    message: string,
    sql: string,
    offset: int?,
}

/// What the caller DOES about it. The extended result code is the
/// discriminator — never a scan of the message, which is how every ORM in
/// the field tells a UNIQUE collision from a missing parent, and which
/// this tree forbids outright ("No string tags or string-matching to
/// detect behavior").
export enum Fault {
    Busy
    Snapshot
    Locked
    Constraint(k: Broken)
    ReadOnly
    Corrupt
    Full
    TooBig
    Interrupted
    Auth
    Mismatch
    NotADatabase
    CantOpen
    IoFailed
    Range
    Defect
    Other
}

/// Which constraint. Each names a different fix, which is the whole
/// reason to carry the extended code.
export enum Broken {
    Unique
    NotNull
    ForeignKey
    Check
    PrimaryKey
    Rowid
    Trigger
    Datatype
    Other
}

/// Whether trying again can work. Three answers, and the middle one is
/// what every retry loop in the field gets wrong: a read transaction that
/// could not promote to a write transaction will NEVER become OK where it
/// stands — the snapshot is stale and the whole transaction must re-run.
export enum Retry {
    Now
    AfterRollback
    Never
}
```

### The one fn that builds a failure

```avra
/// The connection's failure, taken WHOLE, on the spot. Every field is
/// copied here because every one is stale after the next call: the
/// message may be reallocated, the codes reflect only the most recent
/// failed call, and the offset belongs to this SQL.
fn failure_of(db: ptr, sql: string) -> SqlError {
    let ext = sqlite3_extended_errcode(db)
    SqlError {
        code: ext % 256,
        extended: ext,
        message: avra_str_from_host(sqlite3_errmsg(db), errmsg_len(db)),
        sql: sql,
        offset: byte_offset(sqlite3_error_offset(db)),
    }
}

/// `sqlite3_error_offset` answers -1 when the error names no token.
/// Absence is an `int?`, never a sentinel the caller must remember.
fn byte_offset(at: int) -> int? {
    if at < 0 { return nothing<int>() }
    just(at)
}
```

**`code: ext % 256` is LAW E1** — the primary code is the low eight bits
of the extended code, and an enum matched on the extended value without
the mask never matches its own primary arm (`SQLITE_CONSTRAINT_UNIQUE`
is 2067, and `2067 == 19` is false).

### The projections — registries, spelled

Two or more arms answer, so CLAUDE.md's `_ ->` law makes each of these a
REGISTRY: every arm is written, and a catch-all here silently forgets the
next result code SQLite adds.

```avra
impl SqlError {
    /// What went wrong, as the caller's decision rather than a number.
    fn fault() -> Fault {
        if self.code == 19 { return Fault.Constraint(broken_of(self.extended)) }
        match self.code {
            5 -> busy_of(self.extended)
            6 -> Fault.Locked
            8 -> Fault.ReadOnly
            9 -> Fault.Interrupted
            10 -> Fault.IoFailed
            11 -> Fault.Corrupt
            13 -> Fault.Full
            14 -> Fault.CantOpen
            18 -> Fault.TooBig
            20 -> Fault.Mismatch
            21 -> Fault.Defect
            23 -> Fault.Auth
            25 -> Fault.Range
            26 -> Fault.NotADatabase
            _ -> Fault.Other
        }
    }

    /// Whether the same call can succeed later. The set is small and
    /// explicit: a blanket retry turns a constraint violation into an
    /// infinite loop and a corrupt database into a hot spin.
    fn retry() -> Retry {
        if self.extended == 517 { return Retry.AfterRollback }
        if self.extended == 516 { return Retry.AfterRollback }
        match self.code {
            5 -> Retry.Now
            15 -> Retry.Now
            _ -> Retry.Never
        }
    }
}

impl Error for SqlError {
    fn describe() -> ErrorInfo {
        info("sqlite.${code_word(self.code)}", self.message)
    }
}
```

`Fault.Range` and `Fault.Defect` (`SQLITE_RANGE`, `SQLITE_MISUSE`) are in
the enum with a message that names them as the DRIVER's bug, because they
are: a bind index out of range and a finalized statement re-used are
things a caller cannot cause through this API. They are the driver's own
tests' assertion targets (semantics_traps LAW S9).

### How a failure reads at a call site

```avra
let hit = db.run("INSERT INTO users(email) VALUES(?1)", [SqlValue.Text(addr)])
match hit {
    .Ok(n) -> println("inserted ${n}")
    .Err(e) -> println(taken(e))
}

/// A refusal in the caller's words: the fault decides the sentence, and
/// the message fills the specifics SQLite already wrote ("UNIQUE
/// constraint failed: users.email").
fn taken(e: SqlError) -> string {
    match e.fault() {
        .Constraint(k) -> "${broken_word(k)}: ${e.message}"
        .Busy -> "the database is busy — ${retry_word(e.retry())}"
        .Snapshot -> "this transaction saw a stale snapshot — roll back and re-run"
        .Locked -> "this connection is holding the lock it is waiting for"
        .ReadOnly -> "the database is read-only"
        .Corrupt -> "the database file is corrupt"
        .Full -> "the disk is full"
        .TooBig -> "a value exceeded the length limit"
        .Interrupted -> "the query was interrupted"
        .Auth -> "the authorizer refused the statement"
        .Mismatch -> "a value is not the type this read asked for"
        .NotADatabase -> "this file is not a database"
        .CantOpen -> "the file could not be opened"
        .IoFailed -> "the disk failed: ${e.message}"
        .Range -> defect_word(e)
        .Defect -> defect_word(e)
        .Other -> e.message
    }
}

/// The two codes a caller cannot cause through this API. They name the
/// driver, so the message does too.
fn defect_word(e: SqlError) -> string {
    "a defect in @std/sqlite (${e.extended}): ${e.message}"
}
```

**THE ERRCODE FRAME LAW, and why this design is immune to it.**
The probe log's §2b hazard is real: a `defer` in an open frame runs on the
way out of a `?`, and a deferred call on the same connection destroys the
errcode the caller is about to read. This design closes it with one rule,
not with discipline:

> **`SqlError` is materialised before the `fail`.** Every field is copied
> at the failure site; nothing downstream reads the connection again.

The one place adjacency is still load-bearing is a SUSPECT READ that is
not a failure — a zero-length blob, where SQLite spends one NULL on three
meanings (`sqlite3.h:5519–5525`: SQL NULL, an empty blob, out-of-memory).
There the `sqlite3_errcode` call is on the next line and that frame
registers no `defer` at all. It is stated at the site (Part VI) and it is
the driver's own red-team test.

---

## Part V — VALUES: FIVE STORAGE CLASSES, AND THE REFUSAL LADDER

```avra
/// SQLite's five storage classes, per VALUE. Never per column: two rows
/// of one column may hold different classes, and a driver that reads the
/// class once and caches it for the cursor decodes row 2 through row 1's
/// reader (LAW T1).
export enum Class {
    Null
    Integer
    Real
    Text
    Blob
}

/// A value crossing in either direction — bound, or read whole. ONE enum
/// for both, because SQLite's value is one concept: the same five shapes
/// go in and come out.
export enum SqlValue {
    Null
    Int(v: int)
    Real(v: float)
    Text(v: string)
    Blob(v: bytes)
}

/// A storage-class code as the class it names. SQLite's contract is that
/// this is 1 through 5, and 5 is NULL.
fn class_of(code: int) -> Class {
    match code {
        1 -> Class.Integer
        2 -> Class.Real
        3 -> Class.Text
        4 -> Class.Blob
        _ -> Class.Null
    }
}
```

### The ladder, and why REFUSE

| class ↓ / seat → | `int` | `float` | `string` | `bytes` | `bool` | `T?` |
|---|---|---|---|---|---|---|
| NULL | refuse | refuse | refuse | refuse | refuse | `null` |
| INTEGER | exact | **exact** ¹ | refuse | refuse | 0/1 only ² | inner |
| REAL | refuse | exact | refuse | refuse | refuse | inner |
| TEXT | refuse | refuse | exact | **exact** ³ | refuse | inner |
| BLOB | refuse | refuse | refuse | exact | refuse | inner |

¹ REAL affinity may store an integral REAL as an INTEGER, so a `float`
seat that refused INTEGER would refuse a column it declared REAL and
wrote a REAL to (LAW T5). The conversion is exact up to 2⁵³ and REFUSED
above it — a silent rounding is the bug this whole ladder exists to stop.
² `2` in a bool column is refused: SQLite has no BOOLEAN, and a value no
`bool` should silently become is a value no `bool` becomes.
³ text *is* bytes; the widening is free and lossless.

**Four reasons to refuse rather than coerce, each from this tree's own
doctrine.** *P9* — a row type is a declaration, and a driver that coerces
turns a declaration into a preference. *I18* — a projection the dispatch
guarantees, read with a plausible default, is a SILENT WRONG ANSWER;
`sqlite3_column_int("abc")` answering `0` is `?? 0` written in C and
shipped to five million applications. *P1* — an LLM gets exactly one
signal that its schema and its row type disagree, and coercion deletes
it. *P7* — the two lossless exceptions are spelled in the table above
instead of discovered.

**The escape hatches (P8), both explicit, neither the default.**

```avra
/// The cell as it is, class and all. No refusal is possible: the storage
/// class rides the value and the caller decides.
fn value(i: int) -> SqlValue { … }

/// SQLite's own CAST rules, named so no reader mistakes them for the
/// strict ladder: the longest prefix that parses, and 0 when none does.
/// `"12abc"` reads 12 and `"abc"` reads 0, both without error.
fn int_lossy(i: int) -> int { sqlite3_column_int64(self.stmt.raw, i) }
```

**Reading a BLOB as text is the caller's move, and it is fallible.** The
ladder above refuses BLOB in a `string` seat, because a `string` is
UTF-8 by invariant and a blob is arbitrary bytes. The door is the
conversion, not a relaxed reader:

```avra
let raw = row.bytes(3)?
let name: string? = raw.text()          // validated; absent on bad UTF-8
let shown = raw.text_lossy()            // total; ill-formed becomes U+FFFD
```

Encode is total and decode is fallible, which is the asymmetry that makes
the invariant pay: a `string` is already bytes, and bytes are not already
a `string`. That is `@std/text`'s contract, not the driver's — the driver
only refuses to blur it.

### Two tiny fns the whole file leans on

```avra
/// Absence at a named type — a `T?` a match arm can answer beside a
/// present one, where a bare `null` would make the arms disagree.
export fn nothing<T>() -> T? { null }

/// A value as its own nullable: the widen, named, so match arms agree.
export fn just<T>(v: T) -> T? { v }
```

`nothing<int>()` needs its pin (no argument carries the evidence);
`just(v)` never does. This is DOGFOODING's `captured_absent<N>` shape
exactly, and it belongs in core rather than here — ASK A19.

---

## Part VI — THE STATEMENT, AND THE ROW THAT CARRIES NO DATA

```avra
/// Who finalizes. A statement the caller prepared is theirs; one the
/// cache lent is the cache's, and letting it go RESETS it instead —
/// which releases the read transaction the walk was holding and clears
/// the bindings the next caller must not inherit.
export enum Owner {
    Caller
    Cache
}

/// A prepared statement: the compiled plan, its parameter slots, and the
/// row it currently stands on.
export type Stmt = { raw: ptr, owner: Owner, sql: string }

/// The row that stands. It holds NO foreign pointer — only the statement
/// it reads through — so a `Row` that escapes its step can mislead but
/// can never corrupt: every read copies inside the read, and a read with
/// no row standing is refused by name.
export type Row = { stmt: Stmt }

/// What one step did.
export enum Step {
    Row
    Done
}
```

### Stepping

```avra
impl Stmt {
    /// One step of the plan. `.Row` says a row stands; `.Done` says the
    /// statement finished. Every other code is the failure, taken whole
    /// before anything else touches the connection.
    fn step() -> Result<Step, SqlError> {
        let rc = sqlite3_step(self.raw)
        if rc == 100 { return Step.Row }
        if rc == 101 { return Step.Done }
        fail failure_of(sqlite3_db_handle(self.raw), self.sql)
    }

    /// The next row, or absence when the walk is over — and the walk's
    /// end RESETS the statement, because an unreset statement holds a
    /// read transaction open and a WAL whose readers never let go grows
    /// without bound.
    fn next() -> Result<Row?, SqlError> {
        match self.step()? {
            .Row -> just(Row { stmt: self })
            .Done -> self.ended()
        }
    }

    /// The walk is over: reset, and answer absence. `reset` re-reports
    /// the last failing step's code, so its answer is never discarded.
    fn ended() -> Result<Row?, SqlError> {
        if sqlite3_reset(self.raw) != 0 { fail failure_of(sqlite3_db_handle(self.raw), self.sql) }
        nothing<Row>()
    }

    /// The row that stands, if one does. `data_count` is zero before the
    /// first row, after the last, and after a reset — so this is the
    /// statement's own answer and not a flag of ours.
    fn row() -> Row? {
        if sqlite3_data_count(self.raw) == 0 { return nothing<Row>() }
        just(Row { stmt: self })
    }

    /// Let the statement go.
    fn close() {
        match self.owner {
            .Caller -> { let _ = sqlite3_finalize(self.raw) }
            .Cache -> self.returned()
        }
    }

    /// Back to the cache: reset first, then clear. `reset` does NOT clear
    /// bindings, and a cached statement reused with only some parameters
    /// rebound writes the PREVIOUS caller's values into the slots nobody
    /// bound — a data-corruption bug that passes every test where all
    /// parameters are always bound.
    fn returned() {
        let _ = sqlite3_reset(self.raw)
        let _ = sqlite3_clear_bindings(self.raw)
    }
}
```

### Reading a cell

```avra
impl Row {
    /// This cell's storage class, asked FIRST and once. A type conversion
    /// on a column invalidates the pointer the previous read handed back,
    /// and asking the class AFTER a read reports the class the read
    /// forced — so every refusal message would name TEXT.
    fn class(i: int) -> Class {
        class_of(sqlite3_column_type(self.stmt.raw, i))
    }

    /// An INTEGER cell, or absence. Every other class is refused by name:
    /// SQLite's own accessor would answer a plausible number.
    fn int_or_null(i: int) -> Result<int?, SqlError> {
        let c = self.class(i)
        match c {
            .Null -> nothing<int>()
            .Integer -> just(sqlite3_column_int64(self.stmt.raw, i))
            .Real or .Text or .Blob -> { fail wrong_class(self, i, "int", c) }
        }
    }

    /// An INTEGER cell that must be there. A NULL filling a non-nullable
    /// seat is the canonical SQLite data-loss bug — `sum()` over no rows
    /// is NULL, `column_int` answers 0, and a balance of "no rows"
    /// becomes a balance of zero.
    fn int(i: int) -> Result<int, SqlError> {
        let v: int? = self.int_or_null(i)?
        if v == null { fail unexpected_null(self, i, "int") }
        v!
    }

    /// A TEXT cell, or absence — copied into an Avra box at the read,
    /// because SQLite's buffer dies at the next step.
    fn text_or_null(i: int) -> Result<string?, SqlError> {
        let c = self.class(i)
        match c {
            .Null -> nothing<string>()
            .Text -> just(text_at(self.stmt.raw, i))
            .Integer or .Real or .Blob -> { fail wrong_class(self, i, "string", c) }
        }
    }

    /// A BLOB cell, or absence. TEXT widens: text IS bytes, and the
    /// widening loses nothing. It is minted from SQLite's buffer
    /// directly rather than through a `string` — a text read then
    /// converted would copy twice, and a `bytes` box and a `string` box
    /// are the same box with a different kind.
    fn bytes_or_null(i: int) -> Result<bytes?, SqlError> {
        let c = self.class(i)
        match c {
            .Null -> nothing<bytes>()
            .Blob -> just(blob_at(self.stmt.raw, i)?)
            .Text -> just(text_as_bytes(self.stmt.raw, i))
            .Integer or .Real -> { fail wrong_class(self, i, "bytes", c) }
        }
    }

    /// A REAL cell, or absence. INTEGER is accepted and exact: REAL
    /// affinity may store an integral REAL as an INTEGER, so a reader
    /// that refused it would refuse a column it wrote itself. Above 2⁵³
    /// the conversion is not exact and it is REFUSED, never rounded.
    fn float_or_null(i: int) -> Result<float?, SqlError> {
        let c = self.class(i)
        match c {
            .Null -> nothing<float>()
            .Real -> just(sqlite3_column_double(self.stmt.raw, i))
            .Integer -> just(widened(self, i)?)
            .Text or .Blob -> { fail wrong_class(self, i, "float", c) }
        }
    }
}

/// The cell's text as an Avra string: the VALUE first to force the
/// format, its LENGTH second, then one copy into a headered box. The
/// order is the law — `column_bytes` first on an INTEGER cell converts it
/// to text to measure it, and the following `column_text` then answers
/// the rendering rather than the number.
fn text_at(stmt: ptr, i: int) -> string {
    let p = sqlite3_column_text(stmt, i)
    avra_str_from_host(p, sqlite3_column_bytes(stmt, i))
}

/// A TEXT cell read as bytes: the same two calls in the same order, into
/// a `bytes` box instead of a `string` one. One copy, not two.
fn text_as_bytes(stmt: ptr, i: int) -> bytes {
    let p = sqlite3_column_text(stmt, i)
    avra_bytes_from_host(p, sqlite3_column_bytes(stmt, i))
}

/// The cell's bytes, copied. An empty answer is checked against `errcode`
/// ON THE SPOT: SQLite returns NULL for a zero-length blob AND for
/// out-of-memory, and nothing between this read and this check may leave
/// the frame. Nothing here defers, and the caller's `?` is on the answer.
fn blob_at(stmt: ptr, i: int) -> Result<bytes, SqlError> {
    let p = sqlite3_column_blob(stmt, i)
    let n = sqlite3_column_bytes(stmt, i)
    if n == 0 && sqlite3_errcode(sqlite3_db_handle(stmt)) == 7 {
        fail failure_of(sqlite3_db_handle(stmt), "")
    }
    avra_bytes_from_host(p, n)
}
```

**Why `Row` is worth the type.** It is a one-field record over `Stmt`, so
it costs nothing at runtime (flattened to the same pointer), and it buys
the sentence *"a read needs a row"* in the type system. `stmt.next()` is
the only door that mints one, and it mints one only when a row stands.

**The names.** `int` / `int_or_null`, `text` / `text_or_null`, `bytes` /
`bytes_or_null`, `float` / `float_or_null`, `bool` / `bool_or_null`, plus
`value` and the `_lossy` family. Thirteen verbs is a lot, and it is a
REGISTRY: each is a different contract, and a catch-all among them would
be a coercion. Column NAMES do not appear — a result column's name is
undefined without an `AS` and its string has a lifetime (LAW S20). Names
are a describe-time projection: `stmt.index_of("email")` resolves once,
at prepare.

---

## Part VII — BINDING: BY INDEX AND BY NAME, NEVER ONE AT A TIME

```avra
/// A parameter named in the SQL, and the value for it.
export type Bind = { name: string, value: SqlValue }

impl Stmt {
    /// Every parameter, in order. The count is checked against the
    /// statement's own before anything is bound: an unbound parameter is
    /// SQL NULL, silently, and a silent NULL is a wrong answer rather
    /// than an error. SQLite's indices are 1-based and no caller ever
    /// types one.
    fn bind_all(args: List<SqlValue>) -> Result<int, SqlError> {
        let wanted = sqlite3_bind_parameter_count(self.raw)
        if wanted != args.length { fail arity(self, wanted, args.length) }
        for (j, v) in args.enumerate() { self.bind_at(j + 1, v)? }
        wanted
    }

    /// Every parameter, by the name the author wrote. A statement holding
    /// a bare `?` is refused here by name: a bare `?` has no name to bind
    /// by, and silently leaving it NULL is the bug this verb exists to
    /// prevent.
    fn bind_named(binds: List<Bind>) -> Result<int, SqlError> {
        let wanted = sqlite3_bind_parameter_count(self.raw)
        if wanted != binds.length { fail arity(self, wanted, binds.length) }
        for b in binds { self.bind_at(self.slot_of(b.name)?, b.value)? }
        wanted
    }

    /// The 1-based slot a name occupies. Zero means the statement has no
    /// such parameter, which is a caller's typo and is named as one.
    fn slot_of(name: string) -> Result<int, SqlError> {
        let at = sqlite3_bind_parameter_index(self.raw, name)
        if at == 0 { fail no_such_parameter(self, name) }
        at
    }

    /// One value into one slot. Text and blobs bind TRANSIENT: SQLite
    /// copies before returning, so the Avra box may die the instant
    /// after — and it may, because a runtime row BORROWS its arguments
    /// and the memory pass releases at the enclosing scope's end.
    /// `SQLITE_STATIC` becomes legal the day a statement holds its bound
    /// values in a field until finalize (ASK A14).
    fn bind_at(at: int, v: SqlValue) -> Result<int, SqlError> {
        match v {
            .Null -> self.checked(sqlite3_bind_null(self.raw, at))
            .Int(n) -> self.checked(sqlite3_bind_int64(self.raw, at, n))
            .Real(x) -> self.bound_real(at, x)
            .Text(s) -> self.checked(sqlite3_bind_text(self.raw, at, avra_str_ptr(s), s.length, sqlite_transient()))
            .Blob(b) -> self.checked(sqlite3_bind_blob(self.raw, at, avra_bytes_ptr(b), b.length, sqlite_transient()))
        }
    }

    /// A REAL parameter. A `nan` is REFUSED: `sqlite3_bind_double` writes
    /// NULL for it, so a `float` column would read back absence where a
    /// value was written. A value that cannot round-trip is not written
    /// in silence.
    fn bound_real(at: int, x: float) -> Result<int, SqlError> {
        if x.is_nan() { fail nan_refused(self, at) }
        self.checked(sqlite3_bind_double(self.raw, at, x))
    }
}
```

Two laws are load-bearing in `bind_at` and neither is a comment.
**A length is passed, never `-1`** — a negative length means `strlen`,
which truncates a text holding a NUL, the exact bug commit `3c622be`
fixed in `@std/io`. And **an empty `bytes` binds a zero-length BLOB,
never SQL NULL** — an Avra box is always non-NULL, so SQLite's "a NULL
pointer means bind_null" rule can never fire by accident.

---

## Part VIII — RUNNING A STATEMENT

Three verbs on `Db`, split by what they ANSWER and never by what the SQL
says. `INSERT … RETURNING` yields rows and `BEGIN IMMEDIATE` is not
read-only, so any split by the SQL's leading verb is wrong before it is
written. The decider is `sqlite3_column_count`, a prepare-time property
safe to ask before any step.

```avra
impl Db {
    /// Prepare, bind, step to the end, finalize — and answer how many
    /// rows changed. A statement that YIELDS rows is refused here, by its
    /// column count, with the verb that reads them named.
    fn run(sql: string, args: List<SqlValue>) -> Result<int, SqlError> {
        let stmt = self.prepare(sql)?
        defer stmt.close()
        if sqlite3_column_count(stmt.raw) > 0 { fail yields_rows(sql) }
        stmt.bind_all(args)?
        stmt.drain()?
        sqlite3_changes64(self.raw)
    }

    /// The first row's first column, when a query answers one value.
    /// Absence is NO ROW; a NULL cell is `SqlValue.Null`, which is a
    /// different fact and reads as one.
    fn value_of(sql: string, args: List<SqlValue>) -> Result<SqlValue?, SqlError> {
        let stmt = self.prepare(sql)?
        defer stmt.close()
        stmt.bind_all(args)?
        let row: Row? = stmt.next()?
        if row == null { return nothing<SqlValue>() }
        just(row!.value(0))
    }

    /// A script: every statement in it, in order, with no parameters.
    /// `prepare` compiles only the FIRST statement of a text, so a
    /// migration file of six `CREATE TABLE`s applies one unless the tail
    /// is walked — which is what this does. A trailing comment prepares
    /// to a NULL statement and OK, and is skipped rather than refused.
    fn run_script(sql: string) -> Result<int, SqlError> { … }
}
```

`db.run` holds `defer stmt.close()` in the same frame as failures that
travel by `?`. That is safe here, and only here, because **the error was
already materialised** (Part IV): by the time the `?` leaves, `SqlError`
holds copies, and the deferred `finalize` cannot change what it says.

---

## Part IX — READING ROWS: THE UNTYPED PATH AND THE TYPED PATH

### The untyped path — this is what compiles today

```avra
/// Every account, projected AS it is read: the row never becomes a value
/// the loop keeps, so nothing outlives the step that made it.
fn all_accounts(db: Db) -> Result<List<Account>, SqlError> {
    let stmt = db.prepare("SELECT id, name, cents FROM accounts ORDER BY id")?
    defer stmt.close()
    // LICENSED I3: a statement is not a list. The comprehension this
    // wants — `[account_of(row)? for row in stmt.rows()]` — needs the
    // walk protocol of ASK A9, and this site is its wanting site.
    mut out: List<Account> = []
    mut cur: Row? = stmt.next()?
    while cur != null {
        out = out.concat([account_of(cur!)?])
        cur = stmt.next()?
    }
    out
}

/// One account. The columns are named once, in the SQL, and the reader
/// agrees with them by index — a result column's NAME is undefined
/// without an `AS` and may change between SQLite releases.
fn account_of(row: Row) -> Result<Account, SqlError> {
    Account { id: row.int(0)?, name: row.text(1)?, cents: row.int(2)? }
}
```

`cur` is read twice and `next()` is spelled twice — the shape every
language writes before it has `while let`. **ASK A10** names this site.

### The typed path — a named fn per row type, and nothing more

Avra has generics and traits, and neither of them can carry this today:

- **A trait cannot.** `impl FromRow for Account` would need a method with
  no `self` to construct one, and every trait method in this tree takes
  an implicit receiver (`@std/errors`'s `fn describe() -> ErrorInfo`,
  `@std/cli`'s `fn run(args: CliResult) -> int`). A constructor is not a
  method on a value that does not exist yet.
- **A generic collector cannot.** `fn all<T>(sql: string, of: fn(Row) ->
  Result<T, SqlError>) -> Result<List<T>, SqlError>` puts T's ONLY
  evidence inside a fn-typed argument, which DOGFOODING.md:807 forbids
  outright and warns corrupts scalar payloads through mono when pinned.
- **A generic impl cannot.** `impl FromRow for Box<T>` is F2031 —
  *"`Box` is generic — a trait impl over a generic type is recorded, not
  landed"*.

So the typed path is a NAMED FN and the caller writes the walk. That is
P17 (composability over featurefulness) and it is honest: the mapping is
five words per column and it needs no machinery at all. When **ASK A8**
lands, the same named fn becomes a collector's argument with no change to
what the author wrote:

```avra
// ASK A8 — the same `account_of`, with the loop deleted.
let rows = db.all<Account>(account_of, "SELECT id, name, cents FROM accounts", [])?
```

### Streaming a large result set — the same code, with no list

The untyped path above already streams: `sqlite3_step` yields one row per
call with no buffer, and materialising is what a bad driver ADDS.
Dropping the accumulator is the whole difference:

```avra
/// The total, over a result set of any size. Nothing is materialised —
/// not the rows, not a list of them — and the statement is reset the
/// moment the walk ends, so the read transaction it held is released
/// there rather than at close.
fn total_cents(db: Db) -> Result<int, SqlError> {
    let stmt = db.prepare("SELECT cents FROM accounts")?
    defer stmt.close()
    mut sum = 0
    mut cur: Row? = stmt.next()?
    while cur != null {
        sum = sum + cur!.int(0)?
        cur = stmt.next()?
    }
    sum
}
```

**The hazard, named at the verb rather than in a footnote:** an open
statement holds a read transaction on its connection, so a second query
on the same connection mid-walk sees the older snapshot, and a WAL whose
readers never let go grows without bound. `next()` resetting at `.Done`
is what bounds it, and `close()` is what bounds an abandoned walk.

---

## Part X — PREPARED STATEMENTS, AND A CACHE THAT IS A VALUE

Prepare is a parse, a name resolution and a plan compile; step is the
plan running. Reuse is the only documented-mechanism reason a SQLite
binding is ever slow at the driver layer. And a hidden cache is the
commonest hidden-state bug in the survey — sqlite4java's grew until the
heap died; rusqlite's keys on the query string and is documented as "kind
of sub-optimal" for it.

**So the cache is not on the connection. It is a value the caller holds,
with a declared capacity, and the verb says which statement you got.**

```avra
/// A bounded per-connection statement cache. `db.prepare` never consults
/// it; `cache.prepare` says so in its name. A cache with no bound cannot
/// be constructed, and a capacity of zero is the honest way to turn
/// caching off.
export type Cache = { cap: int, rows: List<Kept> }

type Kept = { sql: string, raw: ptr }

export fn cache(cap: int) -> Cache {
    Cache { cap: cap, rows: [] }
}

impl Cache {
    /// This SQL's statement, prepared once per connection. The answer's
    /// owner is the CACHE: letting it go resets and clears it instead of
    /// finalizing it, so the next caller inherits neither a read
    /// transaction nor a binding.
    fn prepare(db: Db, sql: string) -> Result<Stmt, SqlError> {
        let hit: Kept? = self.rows.find(it.sql == sql)
        if hit != null { return Stmt { raw: hit!.raw, owner: Owner.Cache, sql: sql } }
        let fresh = db.prepared(sql, persistent())?
        self.admit(sql, fresh)
        Stmt { raw: fresh, owner: Owner.Cache, sql: sql }
    }

    /// Room for one more: the OLDEST goes, finalized on the way out.
    /// Eviction is by age and not by use, because a use-ordered index is
    /// rebuilt on every read and this one is read once per query — the
    /// policy is written here because a hidden one is what grew
    /// sqlite4java's heap until it died.
    fn admit(sql: string, raw: ptr) {
        if self.rows.length >= self.cap { self.evict() }
        self.rows = self.rows.concat([Kept { sql: sql, raw: raw }])
    }

    /// Every statement finalized. A cache outliving its connection is
    /// SAFE — `close_v2` zombifies rather than closing — but it is still
    /// a leak until this runs, so this IS the cache's drop.
    fn close() {
        for k in self.rows { let _ = sqlite3_finalize(k.raw) }
        self.rows = []
    }
}
```

`prepare_v3` with `SQLITE_PREPARE_PERSISTENT` for cached statements: the
flag exists to tell SQLite the statement will be retained, which changes
its allocation away from the lookaside pool.

**What a cache must NOT hold, and does not:** the row SHAPE. With
`prepare_v2`/`v3` a schema change silently re-prepares a statement, and
the column count, names and decltypes may all change across it. Shapes
are read at describe time and keyed by `PRAGMA schema_version`; the
statement itself is keyed on nothing.

---

## Part XI — TRANSACTIONS AND SAVEPOINTS

```avra
export enum TxMode {
    Deferred
    Immediate
    Exclusive
}

/// Which frame this is. A base transaction commits; a savepoint releases
/// — and a savepoint OUTSIDE a transaction is a `BEGIN DEFERRED` whose
/// release is a commit, so one shape serves both.
export enum Frame {
    Base
    Savepoint
}

/// An open transaction frame. `commit` closes it; anything else that
/// leaves the scope rolls it back, which is the correct default: a
/// transaction whose commit was never reached must not commit.
export type Tx = { db: Db, frame: Frame, changes_at_open: int }
```

```avra
impl Db {
    /// The outermost transaction. A read/write transaction is
    /// `.Immediate`: a `.Deferred` one that reads and then writes must
    /// PROMOTE its lock, and a failed promotion answers
    /// `SQLITE_BUSY_SNAPSHOT`, which is not retryable in place — the
    /// snapshot is stale and the whole transaction re-runs. That single
    /// fact is the most reported SQLite-in-production bug there is.
    fn begin(mode: TxMode) -> Result<Tx, SqlError> {
        if self.in_transaction() { fail already_open() }
        self.run(begin_words(mode), [])?
        self.framed(Frame.Base)
    }

    /// A nested frame, legal at any depth. Transactions do not nest in
    /// SQLite — a second `BEGIN` fails, and the inner block's rollback
    /// takes the OUTER transaction with it — so a library verb that may
    /// be called inside someone else's transaction calls this.
    fn savepoint() -> Result<Tx, SqlError> {
        self.run("SAVEPOINT ${frame_name()}", [])?
        self.framed(Frame.Savepoint)
    }

    /// Whether a transaction is open, asked of SQLITE and never of a
    /// counter of ours. A counter drifts the moment a caller runs `BEGIN`
    /// through the escape hatch, and drifts again every time an error
    /// rolls the transaction back by itself.
    fn in_transaction() -> bool {
        sqlite3_get_autocommit(self.raw) == 0
    }

    /// The frame value, with the change count taken at its open — the
    /// only number a commit can honestly answer, since `Result<void, E>`
    /// is refused (ASK A11).
    fn framed(f: Frame) -> Tx {
        Tx { db: self, frame: f, changes_at_open: sqlite3_total_changes64(self.raw) }
    }
}

impl Tx {
    /// Close the frame, keeping its work, and answer how many rows it
    /// changed — trigger and foreign-key actions included, REPLACE
    /// constraint resolution not.
    fn commit() -> Result<int, SqlError> {
        match self.frame {
            .Base -> self.committed()
            .Savepoint -> self.released()
        }
    }

    /// `COMMIT` can answer BUSY and LEAVE THE TRANSACTION OPEN. A wrapper
    /// that treats a failed commit as "over" leaks an open write
    /// transaction for the life of the connection, blocking every other
    /// writer, until close rolls it back and the work is lost. So a
    /// commit that will not take is ROLLED BACK here, and the caller is
    /// told which of the two happened.
    fn committed() -> Result<int, SqlError> {
        match self.db.run("COMMIT", []) {
            .Ok(_) -> self.changed()
            .Err(e) -> self.commit_failed(e)
        }
    }

    /// Undo the frame. SQLite rolls a transaction back BY ITSELF for
    /// FULL, IOERR, BUSY, NOMEM and INTERRUPT, so this asks whether one
    /// is still open first: a blind `ROLLBACK` answers "cannot rollback —
    /// no transaction is active" and buries the real cause under its own.
    fn rollback() -> Result<int, SqlError> {
        if !self.db.in_transaction() { return 0 }
        match self.frame {
            .Base -> self.db.run("ROLLBACK", [])
            .Savepoint -> self.reverted()
        }
    }

    /// `ROLLBACK TO` does NOT pop the savepoint — it restarts the
    /// transaction at that point and leaves the name on the stack — so
    /// the release is not optional, and an implementation that omits it
    /// leaks a stack entry per failed inner block until an outer release
    /// targets the wrong frame.
    fn reverted() -> Result<int, SqlError> {
        self.db.run("ROLLBACK TO ${frame_name()}", [])?
        self.db.run("RELEASE ${frame_name()}", [])
    }

    /// Undo the frame and say nothing: what an `errdefer` runs while a
    /// failure is already travelling. A rollback that itself fails has
    /// nowhere to report — and needs none: an abandoned transaction is
    /// rolled back when the connection closes, and a crashed process
    /// leaves a journal the next connection recovers.
    fn abandon() {
        let _ = self.rollback()
    }
}

/// The savepoint name every frame uses. It need not be unique: RELEASE
/// and ROLLBACK TO both target the MOST RECENT savepoint with a matching
/// name, and the most recent is always the innermost — so one constant
/// nests correctly to any depth and no counter lives anywhere. The name
/// is reserved: a caller who spells it in raw SQL breaks the nesting,
/// which is why it is not a word anyone would type.
fn frame_name() -> string { "avra_frame" }
```

### What a transaction reads like — today, and after Drop

```avra
/// Move money, or move none of it. `errdefer` runs on the failure channel
/// and only there, so this is exactly a transaction's contract: a `?`
/// anywhere below rolls back, and reaching the commit does not.
fn transfer(db: Db, from: int, to: int, cents: int) -> Result<int, SqlError> {
    let tx = db.begin(TxMode.Immediate)?
    errdefer tx.abandon()
    db.run("UPDATE accounts SET cents = cents - ?1 WHERE id = ?2", [SqlValue.Int(cents), SqlValue.Int(from)])?
    db.run("UPDATE accounts SET cents = cents + ?1 WHERE id = ?2", [SqlValue.Int(cents), SqlValue.Int(to)])?
    tx.commit()?
}
```

After **ASK A1** the `errdefer` line is deleted and the guarantee moves
from the author to the compiler — the API does not change:

```avra
fn transfer(db: Db, from: int, to: int, cents: int) -> Result<int, SqlError> {
    let tx = db.begin(TxMode.Immediate)?     // Drop is ROLLBACK
    db.run(…)?
    db.run(…)?
    tx.commit()?
}
```

**What happens on failure inside a transaction, exhaustively.**

| what failed | what SQLite did | what `Tx` does |
|---|---|---|
| a statement, ordinary error | nothing — the transaction is open | `rollback()` issues `ROLLBACK` |
| a statement, `FULL`/`IOERR`/`BUSY`/`NOMEM`/`INTERRUPT` | *may* have rolled the transaction back itself | `in_transaction()` is asked first; nothing is issued if it is already gone |
| `COMMIT` answered BUSY | the transaction is STILL OPEN and the commit is retryable | retried under the busy policy, then rolled back — never left open |
| an inner savepoint's body | the outer transaction is untouched | `ROLLBACK TO` then `RELEASE`; the outer frame survives |
| a trap (`avra_trap`, exit 2) | nothing; no `defer` runs | the connection's close-time rollback and the journal recover it. **A wrapper that caught a trap and continued would leave a half-applied transaction visible to the same process — so none exists.** |

---

## Part XII — INCREMENTAL BLOB IO

```avra
/// One cell of one row, opened as a byte stream: a lock on that cell for
/// as long as this value lives. The size is fixed at open — a blob grows
/// only through an UPDATE — and the handle EXPIRES the moment anything
/// modifies its row, after which every read and write answers
/// `SQLITE_ABORT` and the fix is to reopen rather than to retry.
export type Blob = { raw: ptr, db: Db }

impl Db {
    /// A cell as a stream. Only a real rowid table's TEXT or BLOB column
    /// can be opened; a writable one may not be indexed, PRIMARY KEY,
    /// UNIQUE, or a foreign key's child with constraints on.
    fn open_blob(schema: string, table: string, column: string, rowid: int, write: bool) -> Result<Blob, SqlError> { … }

    /// Room for a blob of `n` bytes without moving `n` bytes: the SQL
    /// `zeroblob(n)` reserves the space and SQLite manages it very
    /// efficiently. This is the ONLY way to write a blob larger than
    /// memory, and a driver without it bounds every blob by RAM.
    fn reserve_blob(sql: string, n: int) -> Result<int, SqlError> { … }
}

impl Blob {
    fn size() -> int { sqlite3_blob_bytes(self.raw) }

    /// `n` bytes from `at`. The range is checked HERE, because SQLite
    /// answers a generic error for a read past the end and the caller
    /// cannot tell it from an I/O failure.
    fn read_at(at: int, n: int) -> Result<bytes, SqlError> {
        if at < 0 || n < 0 || at + n > self.size() { fail out_of_range(at, n, self.size()) }
        // ASK A5 — a writable byte box, uniquely referenced at the mint.
        mut buf = bytes_builder(n)
        if sqlite3_blob_read(self.raw, buf.at(), n, at) != 0 { fail failure_of(self.db.raw, "") }
        buf.finish()
    }

    /// `data` at `at`. A blob cannot be resized through a handle, so a
    /// write past the end is refused by name with `reserve_blob` in the
    /// message — SQLite would answer a bare `SQLITE_ERROR`.
    fn write_at(at: int, data: bytes) -> Result<int, SqlError> {
        if at + data.length > self.size() { fail would_grow(at, data.length, self.size()) }
        if sqlite3_blob_write(self.raw, avra_bytes_ptr(data), data.length, at) != 0 { fail failure_of(self.db.raw, "") }
        data.length
    }

    /// Let it go. This is a COMMIT POINT: an unclosed handle keeps
    /// `close_v2` from finishing and pins the connection open forever.
    fn close() {
        let _ = sqlite3_blob_close(self.raw)
    }
}
```

**The expiry law, and why it is a distinct fault.** Writes that happened
BEFORE a handle expired are not undone by the expiry — they are inside
whatever transaction is open, so a rollback undoes them and the expiry
alone does not. A driver that reads `SQLITE_ABORT` as "nothing was
written" and restarts from offset 0 double-writes the prefix. So the
abort is carried distinctly and the message says *reopen and re-read the
size*, never *retry*.

---

## Part XIII — DESCRIBE, REFLECTION, AND WHAT THE ORM WILL BUILD ON

```avra
/// What a statement IS, read without running it. Preparing a statement
/// never executes it — not DDL, not DML — so this is safe against a
/// database that has a schema and no data, which is exactly what makes it
/// the compile-time checker's verb.
export type StmtInfo = {
    sql: string,
    params: List<string?>,
    columns: List<ColumnInfo>,
    writes: bool,
}

/// One result column. The last three are the
/// `SQLITE_ENABLE_COLUMN_METADATA` payload, and they are what lets a
/// mapping layer split a join's flat row without rewriting the user's
/// SQL — every ORM that lacks them emits `users_id`/`posts_id` aliases
/// instead. `decltype` is TEXT, verbatim (`VARCHAR(255)`), and absent for
/// any expression or subquery: it is INTROSPECTION and never a reader's
/// authority.
export type ColumnInfo = {
    name: string,
    decltype: string?,
    schema: string?,
    table: string?,
    origin: string?,
}

export fn describe(db: Db, sql: string) -> Result<StmtInfo, SqlError> {
    let stmt = db.prepare(sql)?
    defer stmt.close()
    StmtInfo {
        sql: sql,
        params: [param_name(stmt, j + 1) for j in 0..sqlite3_bind_parameter_count(stmt.raw)],
        columns: [column_info(stmt, j) for j in 0..sqlite3_column_count(stmt.raw)],
        writes: sqlite3_stmt_readonly(stmt.raw) == 0,
    }
}
```

Reflection is a QUERY, not a subsystem: since 3.16.0 every side-effect-
free pragma is also a table-valued function, so `SELECT * FROM
pragma_table_xinfo(?, ?)` is joinable and filterable and the driver grows
nothing to support it. What the driver DOES owe is the rows as typed
records, because they are facts about SQLite rather than about any
mapping:

```avra
export type ColumnFacts = { cid: int, name: string, kind: string, notnull: bool, default_sql: string?, pk: int, hidden: int }
export type ForeignKey  = { id: int, seq: int, table: string, from: string, to: string?, on_update: string, on_delete: string }
export type IndexInfo   = { seq: int, name: string, unique: bool, origin: string, partial: bool }
export type TableInfo   = { schema: string, name: string, kind: string, columns: int, without_rowid: bool, strict: bool }
```

`table_xinfo`, not `table_info`: the latter hides generated and hidden
columns, and a migration diff that cannot see a generated column tries to
add it. The schema argument is always passed, because `pragma_table_info`
resolves across attached databases implicitly.

**The nine things the ORM cannot add later, and this driver ships.**
Typed values including `float` and `bytes` with the STORAGE CLASS
readable per value; `describe` before any row exists; savepoints with a
driver-minted name; the extended result code; `sqlite3_error_offset` as
an `int?` (a byte offset into the SQL, which maps to a SPAN inside the
string literal in a `.av` file — the diagnostic underlines the exact word
of the SQL, which nothing in the field does); `last_insert_rowid` and
`changes64` with their caveats published at the call site;
`sqlite3_limit(SQLITE_LIMIT_VARIABLE_NUMBER)` so a generated `IN (…)`
chunks at the real bound instead of a hard-coded 999; `stmt_readonly`;
and `serialize`/`deserialize` so a schema is built once and cloned per
test case.

**And the line the ORM sits above, drawn here so neither side drifts:**
the driver owns connections, statements, values, describe, transactions,
errors, reflection records, blob streaming, backup, and the statement
cache. The driver owns NO SQL generation, NO query builder, NO schema
model, NO type mapping past the five storage classes, and NO identity,
change tracking or relations. The test of whether the line is in the right
place: **a person writing plain SQL against this driver should never need
the ORM.**

---

## Part XIV — THE ESCAPE HATCH (P8), SPELLED

```avra
use @std.sqlite.raw.{sqlite3_stmt_status, sqlite3_serialize}

/// How many rows this statement's plan visited without an index — P7,
/// and it needs no driver support: the handle is available and the wall
/// is a package the caller may import.
fn full_scan_steps(stmt: Stmt) -> int {
    sqlite3_stmt_status(stmt.handle(), 1, 0)
}
```

Three doors, each one-way and each named:

```avra
impl Db {
    /// The `sqlite3*` this connection wraps. BORROWED: the connection
    /// still closes it.
    fn handle() -> ptr { self.raw }
}

/// A connection this driver did NOT open, adopted WITH its ownership.
/// The caller is handing over the close.
export fn owning(raw: ptr) -> Db { Db { raw: raw } }

/// A foreign region as an Avra value. This is the ONLY door from a
/// pointer to a box, and it is core language infrastructure rather than a
/// SQLite shim: the same two rows serve every C library.
extern fn avra_str_from_host(p: ptr, n: int) -> string
extern fn avra_bytes_from_host(p: ptr, n: int) -> bytes
```

**The rule the hatch carries:** an `extern fn` may never declare `string`
or `bytes` as its ANSWER, and that should be a compiler refusal with a
named voice rather than a convention (ASK A7). Today a foreign
`const char*` typed `string` appears to work — `hdr` refuses the untagged
pointer so retain and release no-op, and `str_len` falls back to `strlen`
— and `AVRA_RC_GUARD=1` prints clean for a correct borrow and a
use-after-free alike, because it watches retain and release EVENTS and an
untagged pointer raises none. **At this one seam the tree's instrument of
record is blind by construction.** That is why the rule is a law and not
advice.

---

## Part XV — THE DAY IN THE PERFECT WORLD

One program, end to end, with every part of the design in it.

```avra
use @std.sqlite.{Db, Row, SqlValue, SqlError, TxMode, at, open, describe}
use @std.io.{println}

type Account = { id: int, name: string, cents: int }

fn schema() -> string {
    """
    CREATE TABLE IF NOT EXISTS accounts (
        id     INTEGER PRIMARY KEY,
        name   TEXT    NOT NULL,
        cents  INTEGER NOT NULL DEFAULT 0,
        avatar BLOB
    ) STRICT;
    """
}

fn account_of(row: Row) -> Result<Account, SqlError> {
    Account { id: row.int(0)?, name: row.text(1)?, cents: row.int(2)? }
}

fn seeded(db: Db) -> Result<int, SqlError> {
    let tx = db.begin(TxMode.Immediate)?
    errdefer tx.abandon()
    db.run("INSERT INTO accounts(name, cents) VALUES(?1, ?2)", [SqlValue.Text("ada"), SqlValue.Int(10000)])?
    db.run("INSERT INTO accounts(name, cents) VALUES(?1, ?2)", [SqlValue.Text("grace"), SqlValue.Int(2500)])?
    tx.commit()?
}

fn richer_than(db: Db, floor: int) -> Result<List<Account>, SqlError> {
    let stmt = db.prepare("SELECT id, name, cents FROM accounts WHERE cents > ?1 ORDER BY id")?
    defer stmt.close()
    stmt.bind_all([SqlValue.Int(floor)])?
    // LICENSED I3: ASK A9's wanting site — the walk protocol would make
    // this `[account_of(row)? for row in stmt.rows()]`.
    mut out: List<Account> = []
    mut cur: Row? = stmt.next()?
    while cur != null {
        out = out.concat([account_of(cur!)?])
        cur = stmt.next()?
    }
    out
}

fn report(db: Db) -> Result<int, SqlError> {
    for a in richer_than(db, 1000)? { println("${a.name}: ${a.cents}") }
    let shape = describe(db, "SELECT id, name FROM accounts")?
    println("${shape.columns.length} columns, writes=${shape.writes}")
    0
}

fn served(path: string) -> Result<int, SqlError> {
    let db = open(at(path))?
    defer db.close()                    // ASK A1 deletes this line
    db.run_script(schema())?
    seeded(db)?
    transfer(db, 1, 2, 500)?
    report(db)
}
```

`STRICT` in the driver's own DDL is deliberate, and it is the P6 answer
to "refuse or coerce": neither — **make the question unaskable where we
own the schema, and refuse where we do not.** On a STRICT table the
storage class equals the declared type by construction, so the whole
refusal ladder of Part V is dead code against our own databases and live
only against foreign ones.

---

## Part XVI — THE TESTS THAT PROVE THE LEDGER

Every guarantee in Part I gets a case. These are the ones that would
otherwise be claims.

```avra
spec "@std/sqlite — resources" {
    given "a statement lent by the cache" {
        then "letting it go clears the bindings the next caller must not inherit" {
            bindings_do_not_survive_a_return()
        }
    }
    given "a transaction that never reaches commit" {
        then "the work is gone" { rolled_back_leaves_nothing() }
        then "an error that rolled itself back is not rolled back twice" { no_double_rollback() }
        then "three savepoints deep, a failure at two leaves one and three consistent" { nesting_holds() }
    }
    given "a column read" {
        then "an INTEGER read as text is refused, naming both classes" {
            refused_reading("SELECT 1", "holds INTEGER")
        }
        then "a zero-length blob is an EMPTY value, never absence" { empty_blob_is_present() }
        then "a text holding a NUL survives the round trip byte for byte" { nul_survives() }
    }
    given "the frames" {
        then "a defer on the same connection cannot change what an error says" {
            errcode_survives_a_defer()
        }
    }
}
```

The last one is the probe log's §2b test, made deterministic: a frame
holding a `defer` that touches the connection, a failing statement, and a
`?` between the failure and the assertion. It passes only because
`SqlError` was materialised at the failure site, and it fails the moment
anyone makes the error a view.

---

## LANGUAGE ASKS

Every construct this design wants and Avra lacks, with the site that
wants it. Ordered by what blocks what. Each belongs in ROADMAP.md's sugar
backlog as part of the change that hits it.

| # | ask | wanting site | what it buys |
|---|---|---|---|
| **A1** | `opaque type T @free_with(f)` + Drop, interleaved LIFO with `defer`/`errdefer` (spec 15.5, 9.11, 12.7) | `Db.close`, `Stmt.close`, `Tx.abandon`, `Blob.close`, `Cache.close` | G1 and G5 move from convention to COMPILER, and every `defer` line in Part XV is deleted. The open question it must answer: what a COPIED opaque value means — a `sqlite3*` cannot carry Avra's 16-byte header, so the value is a one-slot managed box and the drop is refcounted |
| **A2** | a `mut` seat on an `extern fn`, and `(status, mut out T)` projected to `Result<T, E>` at the declaration | `raw.av`'s `sqlite3_open_v2`, `sqlite3_prepare_v3`, `sqlite3_blob_open` | the driver's front door. The grammar half is one missing `( mk:"mut" )?` in `features/fns/mod.av:32`; the semantic half is what `mut` means across the C boundary. Going the last step — projecting the pair to a `Result` — deletes the hand-written wrapper the spec's own example concedes, for every C library |
| **A3** | `float` (IEEE-754 binary64) and `RtKind.F64` | `SqlValue.Real`, `Row.float_or_null`, `Stmt.bound_real` | REAL is one of five storage classes and has exactly one C door. A `double` rides a vector register on both targets, so `RtKind.F64` is not a relabelling of `I64` |
| **A4** | `bytes` as a core value category — the same box `string` has, with length-driven verbs and no NUL assumption | `SqlValue.Blob`, `Row.bytes_or_null`, `Blob.read_at` | BLOB is the fifth class. A blob round-tripped through `string` survives storage and dies at the first `==`, silently, because `==`/`contains`/`index_of`/`replace`/`split` are C string calls. It carries a PREREQUISITE this design depends on twice: those five verbs become length-driven for `string` too, or a TEXT cell holding a NUL still compares equal to its own prefix |
| **A5** | a WRITABLE byte box with a proof of unique reference — a `bytes_builder(n)` whose `finish()` freezes it | `Blob.read_at` | `sqlite3_blob_read` fills a caller-provided region, and a value born immutable cannot be filled. This is the one place this design's immutability is bent, and a builder is the shape that unbends it |
| **A6** | a `ptr` minted from an integer constant | `sqlite_transient()` — `SQLITE_TRANSIENT` is `(void*)-1` | fourteen of SQLite's forty-three function-pointer seats are this sentinel, not a callback. Without it there is no bind path at all; with it, the whole binding family clears the trampoline bucket |
| **A7** | a compiler refusal, with a named voice: an `extern fn` may not answer `string` or `bytes` | the whole of `raw.av` | closes the one seam where `AVRA_RC_GUARD` is blind by construction. Zero violations to migrate — the tree already obeys it by hand |
| **A8** | generics through a fn-typed argument, or another way to carry `T` into a collector | the typed read path; `all_accounts` | `db.all<Account>(account_of, sql, args)`. Today DOGFOODING.md:807 forbids it and warns it corrupts scalar payloads under mono. Without it, every typed read is a hand-written loop |
| **A9** | a WALK PROTOCOL for a user type — `for x in v` and comprehensions over something that is not a `List` | `all_accounts`, `richer_than`, `total_cents` (three `// LICENSED I3` sites) | `[account_of(row)? for row in stmt.rows()]`. It also collapses the streaming/materialising question: a comprehension materialises the PROJECTION, never the rows. `bytes` wants the same protocol (`elem_word` beside `length_word`), so it is one feature with two customers |
| **A10** | `while let x? = e { … }` | the step loops in `all_accounts` and `total_cents` | deletes the doubled `next()` call and the `mut cur`. `if let` already landed; this is its loop twin |
| **A11** | `Result<void, E>` (F2019) | `Stmt.bind_all`, `Tx.commit`, `Cache.close` | three verbs here answer an invented value because they may not answer nothing. `bind_all` answering a parameter count is defensible; `commit` answering a change delta is a stretch |
| **A12** | `mut` that reaches through an opaque handle — a method declarable as WRITING through a foreign pointer | `Stmt.step`, `Stmt.next`, `Blob.write_at`, `Cache.prepare` | today `let stmt = …` then `stmt.step()` compiles and advances the cursor. The compiler's mutation laws stop at the `ptr`, so **G17 is a convention and this design cannot make it anything else** |
| **A13** | a bare enum variant in an ARGUMENT seat (`db.run(sql, [.Int(7)])`) | every call site in this document | today the enum is spelled at every seat. The want exists for a typed let, a field default and a fn's tail — and not for an argument |
| **A14** | `@borrows(param)` (spec 15.4) | `Stmt.bind_at`'s `sqlite_transient()` | `SQLITE_STATIC` is exactly the `@borrows` contract. Landing it turns one `memcpy` per bind into zero for a large blob, with the lifetime compiler-checked instead of commented |
| **A15** | compiler-generated trampolines (spec 15.3) | `db.trace`, `db.on_update`, `db.authorize`, custom functions and collations | 29 real callbacks, all OPTIONAL for the driver's spine and all required for "full surface". Every one takes a `void*` user-data seat, so the spec's refusal case never fires |
| **A16** | a manifest section that BUILDS a package's own C | `packages/std-sqlite/avra.toml` | `[link] objects` names an object that must already exist, so a consumer who adds the dependency today gets a manifest pointing at nothing. It blocks SHIPPING, not building |
| **A17** | the interpreter hosting any extern (dlsym plus a fixed shape table) | every corpus program the driver ships | without it, `avra run` on a database program answers a trap where an answer belongs, and `eval == native` cannot be proved for the FFI at all |
| **A18** | a diagnostic SPAN from a byte offset inside a string literal | `SqlError.offset` | `sqlite3_error_offset` answers the byte offset of the offending token; mapping it into the `.av` source underlines the exact word of the SQL. One C call, and nothing else in the driver buys as much |
| **A19** | `nothing<T>()` / `just(v)` in core | Part V, and every `_or_null` reader | a match arm answering absence beside a present one needs the widen named, or the arms disagree |
| **A20** | `@comptime`, and the compiler preparing a statement against the package's own migrations | `describe` | P10's whole later era: sqlx's fidelity with sqlc's hermeticity, which no system in the field has both of. It needs A17 first — a compiler that can call `sqlite3_prepare_v3` through the interpreter can check a query with no new machinery beyond `@comptime` |

---

## WEAKNESSES

Where this philosophy costs something. Stated before the panel does.

1. **`mut` does not reach through a `ptr`, so the compiler cannot see a
   single mutation this design makes.** `let stmt = db.prepare(sql)?`
   followed by `stmt.step()` compiles, advances the cursor and consumes a
   row. Every handle here is a one-field record over `ptr`, and a `ptr`
   is unmanaged and unwritten-through as far as the type system knows.
   **The entire "resource honesty" claim rests on types the compiler
   cannot look inside.** ASK A12 is the fix and it is the deepest one in
   the list; until it lands, this design is honest about the RESOURCES
   and silent about the MUTATIONS.
2. **A `Row` can escape its step, and I traded corruption for
   staleness.** It cannot use-after-free — it holds no foreign pointer,
   and every read copies inside the read — but a `Row` stored in a list
   and read after two more steps answers the CURRENT row's cells with no
   diagnostic. That is a quiet wrong answer, which is the failure mode
   this document spends most of its budget refusing everywhere else. ASK
   A9 removes the escape by removing the value; nothing else does.
3. **The copy per TEXT/BLOB cell is unconditional and unavoidable.** A
   caller reading a 100 MB blob to compare its first four bytes pays
   100 MB. `open_blob` is the answer, and it is a different verb with a
   different shape, so the caller has to know to reach for it. Every
   memory-safe binding pays this; naming it does not make it cheaper.
4. **Refuse-on-mismatch will be reported as unergonomic, and the
   complaint will be correct.** Against a legacy database whose INTEGER
   column holds text, the first experience of this driver is a wall of
   refusals. `SqlValue` and the `_lossy` verbs are the hatches, but they
   are hatches: the default costs an afternoon of somebody's temper, and
   the argument for it (P9, I18, P1, P7) is a design argument, not a
   user's.
5. **Thirteen read verbs is a big surface for P1.** `int` versus
   `int_or_null` is a choice an LLM makes wrong against a nullable
   column, and gets a RUNTIME refusal for. Only the compile-time checker
   (A20) turns that into a compile error, and it is the last era.
6. **The cache evicts by age, not by use.** A workload with one hot query
   and thirty cold ones behind a cap of sixteen evicts the hot one every
   pass. The reason is P4 — a use-ordered index rebuilds on every read —
   but the caller who hits it has to know to raise `cap`, and nothing
   tells them.
7. **The savepoint name is a reserved constant, and reservation is a
   convention.** `frame_name()` nests correctly to any depth with no
   counter, which is genuinely nice, and a caller who runs `SAVEPOINT
   avra_frame` through `db.run` corrupts the nesting with no diagnostic.
   A minted-per-frame name would need per-connection mutable state, which
   is the thing this design most wanted to avoid.
8. **`bind_all` checks arity and cannot check TYPES.** SQLite will not
   tell you a parameter's type — only how many there are. So `WHERE id =
   ?` bound with a `SqlValue.Text` is accepted, matches nothing (an
   INTEGER never equals a TEXT), and answers zero rows. That is Part V's
   ladder mirrored onto the write side, and this design has no answer for
   it below the compile-time checker.
9. **`Tx` asks `get_autocommit` rather than keeping a counter, which is
   right and surprising.** A caller who runs `COMMIT` through `db.run`
   inside a `Tx` scope leaves a `Tx` whose drop rolls back nothing. The
   state is truthful because it is SQLite's; it is also not the state the
   `Tx` value's name implies.
10. **No pool, no threads, no async — and nothing in the language can say
    "one owner at a time".** That is right for SQLite, and it means a
    service on this driver serializes access itself with no help from the
    type system. LAW K11 has no enforcement anywhere in this campaign's
    scope.
11. **Four of the design's load-bearing types do not exist.** Without
    `float`, `bytes`, out-params and Drop, what compiles today is a
    driver over INTEGER and TEXT with hand-written `defer`s — real, but
    not the thing. Until those land this document is a plan, and every
    code block naming `float`, `bytes`, a `mut`-seated extern or a Drop
    is marked as such rather than as working code.
12. **`Fault.Defect` softens a law I quoted.** `SQLITE_MISUSE` is the
    driver's bug, and semantics_traps LAW S9 says a driver that maps it
    into its public error enum teaches callers to retry past it. I put it
    in the enum anyway, because a library that traps a user's process on
    its own bug is worse. The message names the driver; the tests assert
    it never fires; the law is still bent.

---

## CONFIDENCE LEDGER

| # | load-bearing claim | how verified | confidence |
|---|---|---|---|
| 1 | A generic scope combinator cannot be written: fn-typed arguments carry no T-evidence, and pinning over one corrupts scalars under mono | DOGFOODING.md:807, read verbatim | HIGH |
| 2 | A lambda in an argument seat does not read the seat's answer (F2043) | CLAUDE.md, "The subset today", quoted | HIGH |
| 3 | `defer`/`errdefer` behave as this design uses them — `errdefer` on the failure channel only, `defer` at the statement list's frame | `corpus/defers.av` + `corpus/defers.expected`, read together | HIGH |
| 4 | `if let` exists; `while let` does not | `corpus/if_let.av`; `features/loops/mod.av:21` is the only `while` rule and it takes an expression | HIGH |
| 5 | A trait method always has an implicit receiver, so a `FromRow` constructor cannot be a trait method | `@std/errors:43-45`, `@std/process:969-971`, `@std/cli:48-50` — every trait in the tree | HIGH |
| 6 | `impl Show for Box<T>` is refused (F2031), so a generic row-decoding trait does not land | RESEARCH_probe_log.md, Part II, the compiler's own text | HIGH |
| 7 | `ptr` is unmanaged, so a handle needs no retain and no release, and a foreign pointer crosses safely | `language/memory.av:42-43`; `core/runtime_api.av:95-99` | HIGH |
| 8 | A one-scalar-field record is FLATTENED and travels as its field — fatal for a drop hook on a struct | CLAUDE.md, "WHETHER A VALUE RIDES A POINTER…"; prior_art B3 | HIGH (doctrine, not re-probed) |
| 9 | `sqlite3_column_text`/`_blob` pointers die at the next step, reset, finalize, or a type conversion | sqlite3.h:5470–5505, quoted verbatim in api_surface §4.2 | HIGH |
| 10 | `sqlite3_column_blob` returns NULL for THREE things — SQL NULL, a zero-length blob, and OOM | sqlite3.h:5411, :5519-25, quoted in RESEARCH_probe_log §2a | HIGH |
| 11 | `sqlite3_errmsg`'s buffer may be overwritten by any later call on the connection | sqlite3.h:4199–4202, quoted | HIGH |
| 12 | `reset` does NOT clear bindings, so a reused cached statement writes the previous caller's values | semantics_traps LAW S7, from the C docs | HIGH |
| 13 | RELEASE and ROLLBACK TO target the MOST RECENT savepoint with a matching name, so one constant name nests correctly | semantics_traps LAW X6, from lang_savepoint.html | HIGH on the rule; **MEDIUM** on my conclusion that a constant name is therefore safe at every depth — it follows from the rule but was not run |
| 14 | `ROLLBACK TO` does not pop the savepoint; a RELEASE is still needed | semantics_traps LAW X6, quoted | HIGH |
| 15 | `COMMIT` can answer BUSY and leave the transaction open | semantics_traps LAW X5, quoted | HIGH |
| 16 | Some errors roll the transaction back by themselves, so a blind ROLLBACK buries the cause | semantics_traps LAW X4; lang_transaction.html and get_autocommit.html agree | HIGH |
| 17 | `sqlite3_close_v2` zombifies and dies with its last derived object, which is what makes drop ORDER not matter | semantics_traps LAW S22, from the C docs | HIGH |
| 18 | `PRAGMA foreign_keys` is a no-op inside a transaction, so pragmas are set at open, first | semantics_traps LAW X8, quoted | HIGH |
| 19 | A pragma answers the setting actually in force, so `journal_mode` must be read back | semantics_traps LAW P1 | HIGH |
| 20 | `SQLITE_TRANSIENT` is `(void*)-1` and `SQLITE_STATIC` is `0`, so 14 of 43 function-pointer seats need no trampoline | sqlite3.h:6353-6355 | HIGH |
| 21 | A negative length to `bind_text` means `strlen`, so a text holding a NUL truncates | semantics_traps LAW B2, from bind_blob.html | HIGH |
| 22 | The extended code's low eight bits are the primary code | semantics_traps LAW E1 | HIGH |
| 23 | Extended codes are OFF by default and must be enabled per connection | semantics_traps LAW E2 | HIGH |
| 24 | A blob handle expires on any modification of its row, and writes before the expiry are NOT undone by it | semantics_traps LAW B6, LAW B8 | HIGH |
| 25 | A blob cannot be resized through its handle | semantics_traps LAW B7 | HIGH |
| 26 | Splitting the API by the SQL's leading verb breaks on `INSERT … RETURNING`; `column_count` is the decider | orm_substrate §1.5 | HIGH |
| 27 | `prepare` compiles only the FIRST statement of a text, so a migration file needs a tail loop | semantics_traps LAW S3 | HIGH |
| 28 | `sqlite3_bind_double(nan)` writes NULL, so a `float` column is not a total round trip | numeric_tower §4.1 hazard 1 | HIGH on the behaviour; **MEDIUM** on refusing rather than writing — that is a policy choice this document makes |
| 29 | A REAL-affinity column may hand back `SQLITE_INTEGER`, so a `float` reader must accept INTEGER | semantics_traps LAW T5; numeric_tower §4.1 hazard 3 | HIGH on the rule; MEDIUM on the on-disk mechanism |
| 30 | SQLite will not report a parameter's TYPE — only the count | orm_substrate §1.10, quoting sqlx's own docs | HIGH |
| 31 | `str_len` falls back to `strlen` when the header's `len` is 0, so an empty box is unmeasurable until that clause is deleted | bytes_blob §2.3; `runtime/avra_runtime.c:272-275` | HIGH |
| 32 | `==`, `contains`, `index_of`, `replace`, `split` on `string` are C string calls and truncate at a NUL | `runtime/avra_runtime.c:477, 1145, 1149, 1160, 1208, 1234`, listed in three research files | HIGH |
| 33 | `AVRA_RC_GUARD` is blind at the foreign-pointer seam — it watches retain/release events and an untagged pointer raises none | RESEARCH_probe_log Part I §6; mechanism read in `avra_runtime.c` | HIGH |
| 34 | An extern's arguments are BORROWED and its answer is never released | `language/memory.av:124, 130, 190-196, 316-327`; `core/runtime_api.av:101-104` | HIGH |
| 35 | The `spec`/`given`/`then` DSL compiles to a native binary carrying every package's `[link]` promise, so a spec case can call SQLite today | tdd_and_gates §2, citing `cli/src/commands/test.av` and `shared.av:275` | HIGH |
| 36 | Every code block in this document obeys "The subset today" | read against CLAUDE.md's list item by item — no struct destructuring, no `\|` in patterns, no type alias, no pipe, no `@`, no `mut` in a fn type, no `Result<void, E>`, no bare-statement match arm, no `m["k"]`, no `List.reverse`, comma-list forms respected | **MEDIUM.** Nothing here was compiled — the machine rule forbids it. The shapes most at risk are the next two rows |
| 37 | `just(...)` / `nothing<T>()` in match arms widen correctly into a `Result<T?, E>` tail | reasoned from "expected types thread through match arms" (DOGFOODING, Generics) plus `captured_absent<N>`'s precedent | **MEDIUM** — one scratch `./avra check` settles it |
| 38 | `self.rows.find(it.sql == sql)` answering `Kept?`, and `for (j, v) in args.enumerate()` | both idioms are live in the tree (`process.av:275`'s `terminators().find(it.name == name)`; DOGFOODING I19) | HIGH |
| 39 | `x with { … }` applied to a CALL's result | not found anywhere in the tree — every use is on a binding or on `self` | **LOW.** This design therefore binds first (`let o = at(path)`) and never writes `at(path) with { … }` |
| 40 | A bare enum variant in an ARGUMENT seat | field defaults use it (`stdin: Stdin = .Closed`); argument seats were not found | **LOW** — which is why every enum here is spelled at every seat, and A13 asks for the shorter form |
| 41 | A `string` is a pointer to a headered box with no SSO, so the wall may hand C a payload address and foreign text must be copied | `2026_09_05_STRING_REPRESENTATION.md`, DECIDED by the owner 2026-09-05; it supersedes legacy 9.15 | HIGH |
| 42 | `bytes` is a DISTINCT type sharing the string box (not a view, not `List<u8>`), decode fallible with a total lossy twin, encode total | `RESEARCH_strings_reconciliation.md` D1, D2, D4 — the vision and the bytes design reached this independently and the reconciliation adopts it | HIGH |
| 43 | A zero-copy `bytes` VIEW over a string's buffer was considered and DECLINED — the header has no offset field, and a view's cost is invisible (Erlang's sub-binary) | `RESEARCH_strings_reconciliation.md` D2 | HIGH |

**WEAKEST LINK: row 36.** Nothing here was run, by the machine rule. The
first thing the build should do is `./avra check` a scratch file holding
the `_or_null` reader, the `Tx` match arms and the step loop — three
sub-second probes that settle rows 36, 37 and 40 together, and any one of
them coming back a refusal is a defect in this document rather than a
language ask.

**SECOND WEAKEST: row 13.** The constant savepoint name is this design's
one clever mechanism, and cleverness is what a red team eats first. It
follows from a documented rule, and it has not been run to three levels of
nesting with a failure at level two. That test is written before the
mechanism ships.
