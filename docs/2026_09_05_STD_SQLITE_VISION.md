# @std/sqlite — A Schema Is A Type The Compiler Has Never Been Allowed To Read

> **Status:** vision, written to be worked BACKWARDS from. The SQLITE lane's
> north star; the ladder in Part VI says what exists today, what each rung
> needs, and which lane owns the piece. Sibling to `THE PROGRAM IS THE
> AUTHORITY` (@std/process) and `THE ROOT IS THE ONLY DOOR` (the filesystem);
> the older `forge` tree is a DESIGN SOURCE, not law — two of its
> decisions are already superseded here (9.15's small-string optimization,
> and 31.3's placement of `decimal` in a library package). Axis 15 (FFI and
> Foreign Type Modeling) is the design this document implements.
> Aspirational syntax is marked `[v1]`/`[v2]`/`[v3]`; unmarked code is
> written against the tree as it stands on 2026-09-05.
>
> **Sources:** six research reports commissioned for this doc, beside it as
> `2026_09_05_STD_SQLITE_RESEARCH_*.md` — the C API surface and its ABI
> classification, prior art across fifteen bindings, SQLite's semantic traps,
> the file-by-file cost of a new core value category, the uniform-ABI extern
> host, and the numeric tower. Read them before promising anything this
> document marks MEDIUM or LOW.
>
> **The axioms it serves:** P1 (a model that has never seen this database
> writes the right query or is refused with the fix attached), P3 (SQL's
> spelling, none of SQL's ceremony), P4 (one prepared statement, one copy the
> call site can see, no allocation the schema did not require), P6 (every
> section of Part II is a paradox dissolved, not a horn picked), P7 (`avra
> explain sqlite` prints the schema the binary was compiled against), P8 (the
> whole C wall is public and the face is written in its terms), P9 (a schema
> is a boundary and a boundary is a contract), P10 (the compiler holds
> semantic knowledge no other tool has — and a schema is exactly that
> knowledge), P12 (one schema, many projections: types, migrations, the ORM,
> the docs), P14 (no daemon, no server, no container — the database is a
> file and the driver is in the binary).

> A typed language spends its whole life proving that a value is what it
> claims to be, and then it opens a database. At that boundary every
> guarantee is handed back: the row arrives as `Any`, as `Object`, as
> `Value`, as a `void*` and a promise, and the programmer is invited to
> swear an oath about it. SQLite makes the injury precise, because SQLite is
> honest where other databases are merely quiet — its values are typed
> **per value**, not per column, so `select score from users` may hand you an
> integer in the first row and a string in the second, and it is not a bug.
> Every data-access defect of the last thirty years lives in the gap between
> a schema (which is a type, written down, checked, and versioned) and a
> driver (which has never been allowed to read it). Close that gap and the
> ORM stops being a layer and becomes a projection.

---

## Table of contents

1. Part I — The presenting bug: we can hold three of five
2. Part II — The paradoxes, collapsed (nine of them)
3. Part III — A day in the perfect world (the code)
4. Part IV — The canonical model (the wall, the face, the values, the errors)
5. Part V — The language this driver forces into existence
6. Part VI — Working backwards: the ladder, v0 → v3
7. Part VII — The laws (what must never be true)
8. Part VIII — The proof obligations

---

## Part I — The presenting bug: we can hold three of five

SQLite has exactly five storage classes. Every value in every row of every
database is one of them:

| SQLite storage class | What it holds | Avra, 2026-09-05 |
|---|---|---|
| `NULL` | absence | `T?` — **have it** |
| `INTEGER` | signed 64-bit | `int` — **have it** |
| `TEXT` | UTF-8 (or UTF-16) | `string` — **have it, with a caveat** |
| `REAL` | IEEE-754 binary64 | *nothing* — `let x: float = 1.5` does not parse |
| `BLOB` | arbitrary bytes | *nothing* — no byte type exists |

That is the whole campaign in one table. A driver written today could bind
`sqlite3_column_double` and would have nowhere to put the answer; it could
bind `sqlite3_column_blob` and would have to lie about the result by calling
it a `string`. The lie is not academic. Our `string` carries its length in
its 16-byte header, so it *holds* arbitrary bytes — but only half its
operations respect that length. `.length`, `substring`, `starts_with`,
`ends_with`, `char_code`, `trim`, `+` and `join` read the header and are
byte-honest. `==`, `contains`, `index_of`, `replace` and `split` are C string
calls and stop at the first NUL. So a blob stored as a `string` **compares
equal to its own truncated prefix**. A driver built on that is a driver that
silently corrupts.

The third row of the table carries the caveat and it is the same caveat:
TEXT and BLOB are different storage classes in SQLite, they round-trip
differently, they sort differently, and `typeof()` tells them apart. A driver
that maps both to `string` has thrown away a distinction the database is
keeping for it.

**So the driver does not begin with the driver.** It begins with two core
value categories the language does not have — and, because the ORM is
downstream and money columns are coming, a third the language will want
before it is asked: `decimal` — which the ORM campaign carries, as core.

This is not scope creep. It is the campaign refusing to paper. A binding that
maps REAL to `int` and BLOB to `string` would compile, would pass a
hand-picked test suite, and would be a permanent lie in the standard library.

---

## Part II — The paradoxes, collapsed

P6 says a binary choice is usually a false dichotomy. Nine of them stand
between here and the driver; here is the design where both sides win.

### II.1 — Faithful vs. beautiful

APSW's author argues a binding should expose SQLite *completely* and add
nothing; rusqlite and GRDB argue a binding should be idiomatic first. Both
are right and the argument is about layering, not about API design.

**The collapse: the WALL is total, the FACE is curated, and the face is
written in the wall's own terms.** Every public `sqlite3_*` entry point is
declared and exported. On top sits one small, gloriously declarative surface
that most callers never leave. Dropping from the face to the wall is a
*continuation*, not an escape — the face's `Db` **is** the wall's connection
handle, the face's `Stmt` **is** the wall's statement handle, so a caller who
needs `sqlite3_blob_reopen` reaches for it with the same value they were
already holding. P8: escape hatches everywhere, and no hatch that costs you
your context.

### II.2 — Dynamically typed values vs. a statically typed language

SQLite's values are typed per value. Avra's are typed at compile time. The
usual answers are both bad: pretend the column has one type and crash when it
does not, or hand back a `Value` union and make every read a match.

**The collapse: there are TWO truths and a correct driver carries both.** The
*storage class* is a runtime fact — model it exactly, as a five-armed enum,
and never lie about it. The *declared type* is a compile-time fact — it lives
in the schema, the compiler can read the schema, and from it the driver
derives the static type. They are different facts and they disagree only in a
database that is already broken.

So: `Cell` is the honest runtime value, and `rows<T>` is the typed
projection, and the projection **states its conversion law** rather than
guessing. `STRICT` tables (SQLite 3.37+) make the two truths provably agree,
and the driver should recommend them the way it recommends foreign keys.

### II.3 — Copy at the boundary vs. zero-copy

`sqlite3_column_text` hands back a pointer SQLite owns, valid until roughly
the next thing you do. Borrowing it is fast and dangling; copying it is safe
and costs a memcpy per column.

**The collapse: our runtime makes the copy the ownership model, and the copy
is one the caller would have paid anyway.** Every pointer Avra holds carries
a 16-byte refcount header, so a SQLite-owned pointer *cannot* be handed into
Avra — the refcounter would read memory that is not ours. `str_owned(p, n)`
is therefore not a tax we chose; it is the boundary. And it is exactly one
memcpy, into a box the caller was going to own regardless.

Zero-copy stays available where it actually pays: **incremental blob IO**
(`sqlite3_blob_open`/`read`) streams a large value without materialising it,
which is the case a memcpy would genuinely hurt. Small values copy; large
values stream; the caller sees which one they asked for.

### II.4 — Manual close vs. garbage collection

A `sqlite3*` must be closed exactly once, after every statement made from it
is finalized. `defer` makes you remember. A finalizer runs whenever it likes.

**The collapse: the spec already decided this and nobody has built it —
`opaque type Db @free_with(sqlite3_close_v2)` (Axis 15.5).** The compiler
knows the handle's type, knows its destructor, and emits the close at scope
exit, in the same pass that already releases managed values at a scope's end.
Not a `defer` the caller writes and can forget; not a finalizer at an
unpredictable time. The memory pass we already have is the mechanism —
`@free_with` teaches it one new kind of releasable thing.

This is the single largest piece of *language* in the campaign, and it is
undesigned and unowned today. Part V owns it.

### II.5 — Interpreted vs. native

`avra run` interprets and refuses every extern: *"`sqlite3_open_v2` is extern
— the evaluator cannot host it; build natively."* So a binding today exists
in one engine only, and the `eval == native` doctrine — the tree's best test
— simply does not apply to bindings.

**The collapse: teach the interpreter to call C.** Avra's extern seats are
already a tiny, finite ABI (int, string, ptr, void; float once it lands). An
interpreter can resolve a symbol and call it through a small fixed set of
trampoline shapes — no code generation, no libffi. Then *every* binding in
*every* package runs under `avra run`, the corpus can prove the driver, and a
dead end in an LLM-first language dies. L3 of the roadmap ("one semantics,
three engines") gets its last exception removed by a database driver.

### II.6 — A statement is a resource vs. a statement is a string

Prepared statements are the entire performance story — `sqlite3_prepare_v2`
costs orders of magnitude more than `sqlite3_step`. But making the caller own
statement objects leaks the lifecycle into every call site.

**The collapse: the string IS the cache key.** `db.query("select …", args)`
reads like a string API and *is* a prepared-statement cache keyed by SQL
text, holding the compiled statement across calls, resetting rather than
re-preparing, and re-preparing exactly when SQLite says the schema changed.
The caller who wants the resource still gets it (`db.prepare(sql)` answers a
`Stmt`), and the cache is inspectable (P7). Nobody pays for ceremony they did
not ask for, and nobody pays 100× for the convenience.

### II.7 — Transactions: a closure or a guard

A closure scopes the transaction but cannot express "commit here, keep
going"; a guard object expresses everything and can be forgotten.

**The collapse: this tree already built the mechanism — `defer`/`errdefer`.**
A transaction is a closure whose rollback rides the *failure channel*: an
`errdefer` runs when the body fails, unconditionally, including through `?`
propagation, and the commit is the body's ordinary answer. A caller who wants
manual control gets savepoints as values. No guard to drop, no rollback to
remember, and — the part most bindings get wrong — a failure *inside* the
body cannot leave a transaction open.

And the default is `BEGIN IMMEDIATE` for a writing transaction, because
`DEFERRED` produces the classic upgrade deadlock the moment two writers meet.

### II.8 — Synchronous vs. asynchronous

SQLite is a library reading a file, usually from page cache; better-sqlite3's
maintainers argue at length that async is pure overhead for it. Avra has no
async runtime today anyway.

**The collapse: synchronous, and say so.** The honest concurrency answer for
SQLite is not futures; it is WAL mode (readers do not block writers), one
writer, `busy_timeout` set by default, and a connection per unit of
concurrency when the language grows them. The driver is designed so that this
remains true when fibers arrive: nothing in the API shape assumes a single
connection, and `Db` is a value, not a global.

### II.9 — One string type vs. two

TEXT and BLOB are different storage classes. A driver that maps both to
`string` cannot round-trip, cannot sort correctly, and — in our tree
specifically — silently truncates at NUL in five primitives.

**The collapse: `Bytes` is a real core value category, and `string` keeps its
promise.** `string` is text; `Bytes` is bytes; the driver never coerces one
into the other silently, and the conversion between them is a named,
fallible, encoding-aware verb. This is a language change that the database
merely *forced* — the tree already recorded a live bug waiting behind it (the
runtime's `str_len` distrusts a zero length and falls back to `strlen`, which
is safe only because every text box over-allocates by one; a `Bytes` box
allocated at exactly *n* makes that a real defect).

---

## Part III — A day in the perfect world

### III.1 — The opening move

```avra
use @std/sqlite.{open}
use @std/io.{println}

fn main() -> Result<int, dyn Error> {
    let db = open("app.db")?

    db.exec("
        create table if not exists users (
            id    integer primary key,
            name  text    not null unique,
            score real     not null
        ) strict
    ")?

    db.run("insert into users (name, score) values (?, ?)", ["ada", 99.5])?

    let names = [row.text("name")? for row in db.query("select name from users")?]
    println(names.join(", "))
    0
}
```

Nothing is opened that is not closed; the caller wrote no `close` and no
`defer`. The connection's `@free_with` is the compiler's obligation.

### III.2 — Rows become values

```avra
struct User { id: int, name: string, score: float }

let leaders = db.rows<User>("select id, name, score from users order by score desc limit 3")?
for u in leaders { println("${u.name} — ${u.score}") }
```

`rows<T>` is the typed projection of II.2: field names match column names,
the conversion law is stated, and a mismatch is a *refusal with the fix
attached*, never a silent zero:

```
error[F7003]: column `score` is REAL, and `User.score` is `int`
  ╭─[app.av:14:26]
14 │     db.rows<User>("select id, name, score from users …")
   ·                          ─────
   ·                          this column holds IEEE-754 doubles
   · help: declare `score: float`, or select `cast(score as integer) as score`
```

### III.3 — Transactions cannot be left open

```avra
db.tx(() -> {                            // BEGIN IMMEDIATE
    db.run("update accounts set cents = cents - ? where id = ?", [amount, from])?
    db.run("update accounts set cents = cents + ? where id = ?", [amount, to])?
})?                                       // COMMIT, or ROLLBACK on any `?`
```

The `?` in the middle of the body is the interesting line: it leaves the
closure through the failure channel, the `errdefer` behind `tx` rolls back,
and the error reaches the caller unchanged. There is no path — including a
`fail`, a trap, or an early answer — that commits a partial transaction.

### III.4 — The five storage classes, honestly

```avra
for row in db.query("select value from settings")? {
    let said = match row.cell(0)? {
        .Null      -> "unset",
        .Int(n)    -> "number ${n}",
        .Real(x)   -> "measure ${x}",
        .Text(s)   -> "text ${s}",
        .Blob(b)   -> "${b.length} bytes",
    }
    println(said)
}
```

Five arms, no catch-all, because there are exactly five and there will never
be a sixth. The registry law of this tree (`_ ->` is decided by counting the
answering arms) says this match spells every arm — and the compiler's F2040
holds it to that.

### III.5 — Blobs stream, they do not materialise

```avra
let blob = db.blob_open("main", "documents", "body", rowid, .ReadOnly)?
let head = blob.read(0, 4096)?              // 4 KB out of a 2 GB document
```

### III.6 — The wall is right there

```avra
use @std/sqlite/c.{sqlite3_db_status, SQLITE_DBSTATUS_CACHE_USED}

let used = sqlite3_db_status(db, SQLITE_DBSTATUS_CACHE_USED)?
```

The same `db` value. No unwrapping, no `into_raw`, no second connection.

### III.7 — [v2] The compiler reads the schema

```avra
@schema("db/schema.sql")

let leaders = db.rows<User>(sql"select id, name, score from users order by score desc limit 3")?
//                              ^ parsed, checked against the schema, and typed at compile time
```

```
error[F7010]: `users` has no column `nme`
  ╭─[app.av:9:41]
 9 │     db.rows<User>(sql"select id, nme from users")
   ·                                  ─┬─
   ·                                   ╰── did you mean `name`?
```

This is P10 with the safety off: the compiler holds semantic knowledge no
other tool has, and a schema is exactly that knowledge. It is also the point
at which the driver stops being a library.

### III.8 — [v3] The ORM is a projection, not a layer

```avra
table Users {
    id:    int    @primary @auto
    name:  string @unique
    score: float
}

let leaders = Users.where(it.score > 90.0).order_by(.score, .Desc).limit(3).all(db)?
```

One schema; many projections (P12): the Avra types, the migration, the
query builder, the docs, and `avra explain sqlite`. The driver's job is to be
the substrate this stands on — which is why Part IV insists on column
metadata, `last_insert_rowid`, `changes64`, `RETURNING`, savepoint nesting
and PRAGMA introspection even though nothing in v0 calls them.

---

## Part IV — The canonical model

### IV.1 — The wall

`packages/std-sqlite/src/c/` — one file per API family, every public
`sqlite3_*` entry point declared, nothing hidden, nothing renamed. The wall
is generated-shaped but hand-reviewed: its ABI classification (all-integer /
double / callback / out-parameter / variadic) comes from the API-surface
research report, and a signature that our FFI cannot express is **refused at
the declaration with a named diagnostic**, never quietly omitted.

SQLite itself is **vendored**: `packages/std-sqlite/vendor/sqlite3.c`,
version-pinned, compiled with our flags. Apple's system build omits
`SQLITE_ENABLE_COLUMN_METADATA` (which the ORM needs), `DESERIALIZE` and
`SESSION`, so "full surface" is literally unreachable on the system library —
and a driver whose behaviour depends on the OS release is not a driver this
tree can test.

### IV.2 — The values

```avra
enum Storage { Null, Int, Real, Text, Blob }        // what typeof() says

enum Cell {                                          // what a value IS
    Null,
    Int(int),
    Real(float),
    Text(string),
    Blob(Bytes),
}
```

`Cell` is the honest bottom. Everything typed is a projection of it, and
every projection states its law.

### IV.3 — The face

| Verb | Answers | What it is |
|---|---|---|
| `open(path)` / `open_with(path, flags)` | `Db` | a connection; closes itself |
| `db.exec(sql)` | `int` (statements run) | script execution, no results |
| `db.run(sql, args)` | `int` (rows changed) | one writing statement |
| `db.query(sql, args)` | `Rows` | a cursor over `Row` |
| `db.rows<T>(sql, args)` | `List<T>` | the typed projection |
| `db.one<T>(sql, args)` | `T?` | exactly one row, or none |
| `db.value<T>(sql, args)` | `T?` | one column of one row |
| `db.tx(body)` | the body's answer | `IMMEDIATE`, commit or roll back |
| `db.savepoint(name, body)` | the body's answer | nestable |
| `db.prepare(sql)` | `Stmt` | the resource, when you want it |
| `db.blob_open(...)` | `Blob` | incremental IO |
| `db.last_insert_rowid()` / `db.changes()` | `int` | the ORM's needs |
| `db.tables()` / `db.columns(table)` | schema values | PRAGMA introspection, typed |

### IV.4 — The errors

Every refusal is a value carrying **the extended result code**, the message,
and the SQL that produced it. Extended codes are the whole point: `SQLITE_BUSY`
and `SQLITE_BUSY_SNAPSHOT` demand different responses, and a driver that
throws away the low byte's neighbours has thrown away the retry decision.

```avra
enum SqlError {
    Refused { code: int, message: string, sql: string? },
    Busy { code: int, waited_ms: int },
    NoSuchColumn(string),
    WrongType { column: string, wanted: string, found: Storage },
    Misuse(string),                       // SQLITE_MISUSE is OUR bug, not the query's
    Opening { path: string, code: int },
}
impl Error for SqlError { … }
```

`SQLITE_MISUSE` gets its own arm on purpose: it never means "the query
failed", it means the driver has a bug, and a driver that reports it as a
query error sends every user hunting in the wrong file.

### IV.5 — The defaults, and why each is a decision

| Default | Why |
|---|---|
| `PRAGMA foreign_keys = ON` | off by default in SQLite for backward compatibility; every serious binding regrets leaving it off |
| `PRAGMA journal_mode = WAL` | readers do not block writers; the single biggest concurrency win |
| `PRAGMA synchronous = NORMAL` | safe under WAL, and materially faster than FULL |
| `PRAGMA busy_timeout = 5000` | a bare `SQLITE_BUSY` on first contention is a broken default |
| `sqlite3_prepare_v3` | proper errors from `step`, and the persistent-statement hint for the cache |
| explicit lengths on every bind | `-1` means `strlen`, which truncates any text holding a NUL |
| `SQLITE_TRANSIENT` unless proven otherwise | `SQLITE_STATIC` with a value the caller may free is a use-after-free |

---

## Part V — The language this driver forces into existence

This is the part the campaign exists to do honestly. Each item is a real gap,
found by probing, recorded in the ROADMAP, and owned by a lane.

1. **`float` (IEEE-754 binary64)** — a core value category. Lexer, type
   surface, value protocol, IR, LLVM backend (a double is not pointer-sized —
   the highest-risk unknown in the campaign is whether anything in this
   compiler assumes every value is i64 or a pointer), interpreter `Val`,
   runtime text projection (shortest round-trip printing is an algorithm, not
   a format string), and the equality question IEEE-754 forces on a language
   whose `==` "compares scalars".
2. **`Bytes`** — a core value category, and the honest home for BLOB. Its box
   is allocated at exactly *n*, which turns the runtime's `str_len`
   zero-length fallback from a safe convention into a live bug; that gets
   fixed as part of landing it.
3. **`decimal` — DEFERRED, and relocated.** It gates ZERO externs: SQLite
   has no decimal storage class at all. It moves to the ORM campaign, whose
   money columns are the real customer — and it lands as a CORE VALUE
   CATEGORY, not a library type (owner, 2026-09-05, overriding spec 31.3's
   `@std/numbers`).
4. **The FFI axis (spec 15.2–15.6)** — `CString` at the boundary,
   out-parameters (`sqlite3_open_v2` takes `sqlite3**`), ownership
   annotations (`@returns_ownership`, `@borrows`, `@takes_ownership`,
   `@free_with`), **`opaque type` with compiler-emitted drop**, and
   compiler-generated callback trampolines for the `void*`-carrying C
   callbacks (hooks, custom functions, collations).
5. **The interpreter's extern host** — so `avra run` and the native binary
   are one semantics for bindings too.
6. **`Result<void, E>`** — refused today (F2019). A writing verb currently
   has to answer something it did not compute.

Nothing on this list is a nice-to-have for the driver. Items 1 and 2 are the
difference between a driver and a lie; item 4 is the difference between a
binding and a C shim; item 5 is the difference between one semantics and two.

---

## Part VI — Working backwards: the ladder

Each rung is provable on its own, merges to main on its own, and unblocks the
next. Rungs marked ∥ can run in parallel.

**v0 — the ground (∥ across four lanes)**

- ∥ **CORE**: `float` lands end to end — literal, type, arithmetic,
  comparison, printing, both engines, corpus proof.
- ∥ **CORE**: `Bytes` lands end to end, and the `str_len` zero-length defect
  dies with it.
- ∥ **FFI**: `CString`, out-parameters, and `opaque type` + `@free_with` with
  compiler-emitted drop.
- ∥ **HOST**: the interpreter hosts an all-integer extern; a corpus program
  proves eval == native across the C boundary.
- ∥ **DRIVER**: the vendored amalgamation, the build wiring, the test
  harness, and the integer/text slice of the wall — open, exec, prepare,
  bind, step, column, errors, transactions. TDD from the first line.

**v1 — the driver is real**

- The complete wall, every family, with the ABI classification honoured and
  unexpressible signatures refused by name.
- The face of IV.3, `Cell`, the error model, the defaults, the statement
  cache, incremental blob IO, `rows<T>`.
- Callback trampolines: hooks, custom SQL functions, collations.

**v2 — the compiler reads the schema**

- `@comptime` and a SQL grammar the compiler can parse; `sql"…"` literals
  checked against a declared schema; bind parameters and result columns
  typed. P10 with the safety off.

**v3 — the ORM is a projection**

- `table` declarations, the query builder, migrations, and `avra explain
  sqlite`. One schema, many projections.

---

## Part VII — The laws

What must never be true, in the voice the tree uses for laws.

- **A COLUMN READ NEVER BORROWS SQLITE'S MEMORY.** Every pointer Avra holds
  carries a header; a `sqlite3_column_text` pointer does not. It is copied
  through `str_owned(p, n)` at the boundary or it is not read at all.
- **THE EMPTY BLOB IS NOT NULL.** `sqlite3_column_blob` answers a null pointer
  for a zero-length blob — SQLite spends the empty value exactly where our own
  law says an encoding always spends it. The storage class is asked *first*,
  and the empty case is the first case written.
- **A BIND PASSES AN EXPLICIT LENGTH, NEVER `-1`.** `-1` means `strlen`, and a
  text value holding a NUL is truncated silently.
- **A TEXT VALUE AND A BLOB VALUE ARE DIFFERENT TYPES.** No silent coercion in
  either direction.
- **A WRITING TRANSACTION BEGINS IMMEDIATE.** `DEFERRED` upgrades under
  contention and deadlocks.
- **EVERY ERROR CARRIES ITS EXTENDED CODE.** The low byte alone cannot decide
  a retry.
- **`SQLITE_MISUSE` IS OUR BUG.** It is never reported as a query failure.
- **NO STATEMENT OUTLIVES ITS CONNECTION.** The connection's drop finalizes
  what the cache holds, in order.
- **A COLUMN'S TYPE IS ASKED BEFORE ITS VALUE IS TAKEN.** Calling
  `column_text` on an INTEGER mutates the value's representation and can
  invalidate a pointer already taken from `column_blob`.

---

## Part VIII — The proof obligations

- `spec`/`given`/`then` tests beside every module, as every package in this
  tree has.
- **TDD is the campaign's method, not its garnish**: the failing test is
  written first, and it is written against the *behaviour SQLite documents*,
  with the trap number from the semantics research report cited in the test's
  name.
- An adversarial suite per slice (`red-team` before `review-round`, every
  slice, as the standing order requires).
- Corpus pairs proving `eval == native` — which is only possible because of
  II.5, and is the reason II.5 is in v0 rather than v2.
- Golden diagnostic renderings for every refusal this document promises.
- `make gate` green through the machine-wide lock, every time.
- A measured claim, never a reasoned one: the statement cache, the
  transaction batching and the WAL defaults each ship with the number that
  justifies them.

---

*Written 2026-09-05 by the SQLITE lane. The decisions in Parts I, II and VI
were taken with the owner in a design interview and are recorded in the
ROADMAP; the research reports beside this file carry the evidence.*
