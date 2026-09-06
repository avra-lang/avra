# `@std/sqlite` — prior art: what to steal, what to refuse

Research for the Avra standard library's SQLite driver. Every claim that is a
*fact about another system* carries a URL. Every claim that is a *fact about
this tree* carries a `file:line`. Every claim that is a *design opinion* says
so, with a confidence mark.

Organised as: **§0** the frame — why every SQLite binding is the same three
decisions; **§1** the sources — fifteen bindings, each with its real shape and
one steal / one refuse; **§2** the affordances that proved beautiful; **§3** the
bug taxonomy — the shapes authors regret, each paired with the design that makes
it *unwritable*; **§4** compile-time-checked SQL, the prior art and what it costs;
**§5** the ranked adoption table; then **BLOCKERS** and the **CONFIDENCE LEDGER**.

---

## §0 The frame

A SQLite binding is not a database client. It is a projection of a C library
with roughly 300 entry points onto a host language's value model, and the whole
design space collapses to three decisions that every survey entry makes,
differently, and mostly wrongly.

**Decision 1 — who owns the two objects.** The C API is a state machine over
`sqlite3*` and `sqlite3_stmt*`. Everything else is a verb on one of them. Every
binding's real API is its answer to "when does `sqlite3_finalize` run, and what
happens to a statement whose connection died first". Rust answers with
lifetimes and pays in ergonomics; Go answers with a connection *pool* and pays in
`SQLITE_BUSY`; Python answers with refcounts and a hidden statement cache; JS
answers with a GC and a "connection is busy" runtime error.

**Decision 2 — the coercion policy.** SQLite has five storage classes (NULL,
INTEGER, REAL, TEXT, BLOB) and *per-value* types; a column's declared type is an
*affinity*, a hint, not a constraint
(<https://blog.sqlite.ai/types-and-affinities-sqlite>). Every statically-typed
host must decide what happens when the row disagrees with the type the caller
asked for. Every binding that answers "coerce quietly" has shipped a data-loss
bug. Every binding that answers "refuse" has shipped an ergonomics complaint.

**Decision 3 — copy or alias.** `sqlite3_column_blob()` and
`sqlite3_column_text()` hand back a pointer that SQLite owns:

> "The pointers returned are valid until a type conversion occurs as described
> above, or until sqlite3_step() or sqlite3_reset() or sqlite3_finalize() is
> called." — <https://www.sqlite.org/c3ref/column_blob.html>

A binding either copies at every read (safe, an allocation per cell) or hands
the alias to the host (fast, a use-after-free the moment a row outlives its
step). Every "lazy row" bug in §3 is this decision, made once and regretted.

**Avra's P6 applies at the top.** The forced trade-off across the whole survey
is *complete or ergonomic*: APSW is complete and verbose, better-sqlite3 is
ergonomic and covers maybe a fifth of the C API. The collapse is that these are
properties of *different layers*: completeness belongs to the **extern layer**
(one `extern fn` per C entry point, mechanically total), ergonomics to the
**projection over it** (`Db`, `Stmt`, `Row`, records). Every binding in this
survey conflated them because its host language could not declare 300 externs
cheaply. Avra can — `extern fn` already exists and is already used at scale
(`packages/std-process/src/process.av:15-29`, fifteen externs for the process
seam). That is the whole campaign in one sentence: *the surface is the C API,
and the beauty is a projection, not a subset.*

---

## §1 The sources

Format: **the shape** (open / prepare-bind-step / read / transaction / error /
blob) → **steal** (one affordance) / **refuse** (one concrete bug class, keyed
to §3).

### 1.1 Rust — `rusqlite` + `libsqlite3-sys`

<https://github.com/rusqlite/rusqlite> · <https://docs.rs/rusqlite/latest/rusqlite/struct.Statement.html>

```rust
let conn = Connection::open_in_memory()?;
conn.execute("INSERT INTO person (name, data) VALUES (?1, ?2)", (&me.name, &me.data))?;

let mut stmt = conn.prepare("SELECT id, name, data FROM person")?;
let person_iter = stmt.query_map([], |row| {
    Ok(Person { id: row.get(0)?, name: row.get(1)?, data: row.get(2)? })
})?;
```

Named parameters bind as pairs: `stmt.query_map(&[(":id", &"one")], |row| row.get(0))?`.
Type conversion is the `ToSql` / `FromSql` trait pair — the extension point third-party
crates implement for `chrono`, `uuid`, `serde_json`. Optional surface is behind cargo
features: `bundled`, `blob`, `functions`, `window`, `vtab`, `backup`, `hooks`,
`load_extension`, `session`, `column_decltype`, `collation`, `serialize`.
`libsqlite3-sys`'s `bundled` feature compiles the amalgamation from embedded source with
`cc`, which is *the* answer to "which SQLite am I actually running".

The famous wart: `Rows` is not an `Iterator`.

> "The `Rows` interface is not compatible with Rust's Iterator trait, because the
> lifetime of the returned row is tied to the lifetime of self. This is a fallible
> 'streaming iterator'." — <https://docs.rs/rusqlite/latest/rusqlite/struct.Rows.html>

And `prepare_cached` keys on the query *string*, and a cached statement borrows the
connection, so a statement must be dropped before its transaction commits
(<https://users.rust-lang.org/t/rusqlite-prepared-statements-in-transactions/41373/4>,
<https://github.com/rusqlite/rusqlite/issues/1598>).

**Steal:** the `ToSql`/`FromSql` *pair* as the one extension point, and the
`bundled` posture — vendor the amalgamation, compile it yourself, never inherit
the platform's build.

**Refuse:** a statement cache keyed on SQL text with no eviction policy and a
borrow that fights the transaction (§3.6, §3.7).

### 1.2 Rust — `sqlx`

<https://github.com/launchbadge/sqlx> · <https://docs.rs/sqlx/latest/sqlx/macro.query.html>

The macro checks the query against a live database *at compile time*:

```rust
let row = sqlx::query!("SELECT id, name FROM person WHERE id = ?", id)
    .fetch_one(&pool).await?;
```

The macro requires a literal:

> "The query must be a string literal, or concatenation of string literals using `+`"

Column types come back from the engine; nullability is inferred, and where the
inference is wrong the developer overrides *in the SQL*, in the column alias:
`"col!"` forces non-null, `"col?"` forces nullable, `"col!: Type"` does both.
For SQLite specifically the driver does something remarkable:

> "The SQLite driver will pull the bytecode of the prepared statement and step
> through it to find any instructions that produce a null value for any column in
> the output." — <https://deepwiki.com/launchbadge/sqlx/4.2-compile-time-query-checking>

Offline builds cache that metadata: `cargo sqlx prepare` writes `.sqlx/*.json`,
committed to the repo (<https://deepwiki.com/transact-rs/sqlx/4.2-offline-mode-and-sqlx-prepare>).
The regrets are all about the *build* becoming a database client: a missing
`DATABASE_URL` fails the build, a migration that changes a column type stops the
code compiling, a stale cache is a silent lie, and runtime-built SQL cannot be
checked at all (<https://github.com/launchbadge/sqlx/issues/2087>,
<https://cosmichorror.dev/posts/speeding-up-sqlx-compile-times/>).

**Steal:** the *in-SQL override*. When the checker's inference is wrong, the fix
is written in the query, not in a config file — the knowledge stays where the
query is. This is the single most reusable idea in the compile-time-SQL space.

**Refuse:** requiring a live database to compile (§4). Avra vendors the
amalgamation and can therefore *link the checker to the same SQLite the program
runs*, so the schema is a file in the repo, not a service.

### 1.3 Go — `mattn/go-sqlite3` under `database/sql`

<https://github.com/mattn/go-sqlite3>

Configuration is smuggled through the DSN query string: `_busy_timeout`,
`_journal_mode`, `_txlock`, `cache=shared`. The README's own guidance for
"database is locked" is `cache=shared` plus `db.SetMaxOpenConns(1)` — i.e. defeat
the pool `database/sql` exists to provide. `:memory:` gives every pooled
connection *a different database* unless `file::memory:?cache=shared` is used.
Extensions (FTS5, JSON, ICU) are *build tags*, so what your binary can do depends
on how it was compiled.

The pool is the wound. `SQLITE_BUSY` is normal for concurrent connections
(<https://www.sqlite.org/rescode.html#busy>), and a `COMMIT` that fails with
`SQLITE_BUSY` can leave the transaction open while `database/sql` believes the
`driver.Tx` finished — the connection returns to the pool poisoned
(<https://github.com/mattn/go-sqlite3/issues/632>,
<https://github.com/mattn/go-sqlite3/issues/274>).

**Steal:** nothing about the connection model. Steal only the honesty of the
README, which tells you to set the pool to one.

**Refuse:** the *generic driver interface*. `database/sql` was designed for
client-server databases; wrapping an embedded, single-writer, in-process library
in a connection pool is the survey's clearest example of an abstraction
inverting its subject (§3.3).

### 1.4 Go — `modernc.org/sqlite` (pure Go)

<https://gitlab.com/cznic/sqlite> · <https://datastation.multiprocess.io/blog/2022-05-12-sqlite-in-go-with-and-without-cgo.html>

SQLite's C, transpiled to Go by `ccgo`. Buys cross-compilation and no cgo;
costs roughly 2× on INSERT, 10%–2× on SELECT, worse as the dataset grows, with a
larger standard deviation attributed to the GC.

**Steal:** the *evidence* that a transpiled SQLite is a real option and a real
cost. It is the honest baseline for "what does not compiling C buy you".

**Refuse:** it as a model for Avra. P4 (Rust-level performance or better)
forecloses a 2× write penalty for a portability win Avra buys another way — it
already links C objects through the manifest's `[link]` rows
(`packages/std-avrac/src/language/manifest.av:57`).

### 1.5 Python — stdlib `sqlite3`

<https://docs.python.org/3/library/sqlite3.html>

The DB-API 2.0 shape: `connect`, `cursor`, `execute(sql, params)`, iterate the
cursor, `commit`. Its defining flaw is that it *manages transactions for you*,
by parsing your SQL:

> "If autocommit is LEGACY_TRANSACTION_CONTROL, isolation_level is not None, sql
> is an INSERT, UPDATE, DELETE, or REPLACE statement, and there is no open
> transaction, a transaction is implicitly opened before executing sql."

DDL is not in that list, so `CREATE TABLE` autocommits and silently ends your
transaction (<https://docs.sqlalchemy.org/en/20/dialects/sqlite.html>). Python
3.12 added `autocommit=` and named the old behaviour `LEGACY_TRANSACTION_CONTROL`,
with the default scheduled to change — a deprecation of the module's own
foundational design decision.

Type handling is the second flaw: `detect_types` defaults to off, and turning it
on with `PARSE_DECLTYPES` reads the *declared* type — which does not exist for
computed columns, so `max(data)` comes back as `str` regardless.

**Steal:** nothing. This entry exists to name the anti-pattern precisely.

**Refuse:** *SQL-sniffing to decide transaction boundaries* (§3.1). It is the
purest instance of a library lying about what the database is doing, and it took
sixteen years to start unwinding.

### 1.6 Python — APSW

<https://rogerbinns.github.io/apsw/> · <https://rogerbinns.github.io/apsw/pysqlite.html>

The declared philosophy is the campaign's own:

> "APSW provides access in whatever way is normal for SQLite. It makes no effort
> to hide how SQLite is different from other databases." … "**Nothing** happens
> behind your back."

Concretely, against the stdlib module: no implicit transactions; nested
transactions via SAVEPOINT; multiple statements per `execute`; `executemany` works
with SELECT; the same `Connection` is usable across threads without extra locking;
*an exception per SQLite error code, with the extended code*, where the stdlib
folds several codes into one DB-API exception; and callbacks that raise propagate
into SQLite as errors instead of being swallowed. The surface covers FTS5, the
session extension, virtual tables, VFS, incremental BLOB I/O, backup, and
`trace_v2`.

```python
connection = apsw.Connection("dbfile")
connection.execute("insert into log values(?, ?)", (7, "transmission started"))
for row in connection.execute("select * from point"):
    print(row)                      # (1, 2, 3)

with connection:                    # SAVEPOINT-backed, nests
    connection.execute("insert into point values(2, 2, 2)")

blob = connection.blob_open("main", "blobby", "y", rowid, True)
blob.write(b"hello world"); blob.seek(2000); blob.read(24); blob.close()
```

**Steal:** all of it — this is the reference philosophy. Specifically: *one error
value per SQLite result code including the extended code*, incremental BLOB I/O
as a first-class object, and SAVEPOINT-backed nesting so a transaction block
composes.

**Refuse:** only its ergonomics ceiling — rows are positional tuples, so every
read is `row[2]` and the schema lives in the reader's head. Avra's projection
layer fixes that without touching the extern layer.

### 1.7 Swift — GRDB.swift

<https://github.com/groue/GRDB.swift>

Database access is *scoped to a closure*, and that is the whole design:

```swift
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")

try dbQueue.write { db in
    try db.execute(sql: "INSERT INTO player (name, score) VALUES (?, ?)",
                   arguments: ["Arthur", 100])
}
try dbQueue.read { db in
    let players = try Player.fetchAll(db)
}
```

Records are protocol conformances over ordinary structs — nothing is inherited,
nothing is generated:

```swift
struct Player: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: Int64
    var name: String
    var score: Int
}
try Player(id: 1, name: "Arthur", score: 100).insert(db)
```

Raw rows are still available (`row["name"]`), and so are scalar fetches
(`try Int.fetchOne(db, sql: "SELECT MAX(score) FROM player")`). `DatabaseQueue`
serialises; `DatabasePool` uses WAL for concurrent readers. Errors split into
`DatabaseError` (SQLite said no) and `RecordError` (the record layer said no).

**Steal:** two things. **(a)** The closure scope — a connection handle that
*cannot escape the block that owns it* makes "statement outlived its connection"
unrepresentable rather than diagnosed. **(b)** The *decomposed record protocols*:
`FetchableRecord` (can be read) and `PersistableRecord` (can be written) are
separate, so a read-only projection over a join is a first-class citizen and not
a crippled model object.

**Refuse:** nothing structural. The cost is Swift-specific (closures capture, and
GRDB must document escaping rules carefully); in Avra the same shape is a
`defer`-backed bracket, which is cheaper.

### 1.8 Swift — SQLite.swift

<https://github.com/stephencelis/SQLite.swift>

A typed expression DSL over the schema, declared by hand:

```swift
let db = try Connection("path/to/db.sqlite3")
let users = Table("users")
let id = SQLite.Expression<Int64>("id")
let name = SQLite.Expression<String?>("name")

try db.run(users.insert(name <- "Alice", email <- "alice@mac.com"))
try db.run(alice.update(email <- email.replace("mac.com", with: "me.com")))
try db.scalar("SELECT count(*) FROM users")
```

Nullability rides the generic parameter (`Expression<String?>`), which is the
right idea. The declarations are hand-written and hand-maintained, which is the
wrong half — they are a *second* source of truth for the schema, and nothing
checks them against the database.

**Steal:** nullability in the type of the column reference, not in the read site.

**Refuse:** a hand-maintained schema mirror (§3.11). Avra's answer is generation
or comptime derivation from the migration files, never a parallel hand-kept model.

### 1.9 C# — `Microsoft.Data.Sqlite`

<https://learn.microsoft.com/en-us/dotnet/standard/data/sqlite/>

```csharp
using var connection = new SqliteConnection("Data Source=hello.db");
connection.Open();
using var command = connection.CreateCommand();
command.CommandText = "SELECT name FROM user WHERE id = $id";
command.Parameters.AddWithValue("$id", id);
using var reader = command.ExecuteReader();
while (reader.Read()) { var name = reader.GetString(0); }
```

ADO.NET's generic shape, and it inherits ADO.NET's generic problems: `AddWithValue`
infers the parameter's type from the CLR value, `GetString(0)` asserts a type by
ordinal, and `using` is the only thing standing between you and an unfinalized
statement. The one genuinely good piece is `SqliteBlob`, a `Stream` over
`sqlite3_blob_*` — incremental BLOB I/O typed as the host language's ordinary
stream abstraction.

**Steal:** BLOB-as-stream. A 200 MB blob should never require a 200 MB value.

**Refuse:** `AddWithValue`-style inference from the host value (§3.2) — the
parameter's SQL type should be a property of the *statement*, which SQLite can be
asked about, not of the value that happens to be in hand.

### 1.10 Elixir — `exqlite` / `ecto_sqlite3`

<https://github.com/elixir-sqlite/exqlite> · <https://hexdocs.pm/exqlite/readme.html>

A NIF on the **dirty scheduler**, chosen deliberately over the older `esqlite`
design of a per-connection command pool: "maintaining each SQLite connection's
command pool is complicated and error prone". The README then states the
constraints plainly: "Simultaneous writing is not supported by SQLite3 and will
not be supported in exqlite", "Statements must be kept isolated to one process",
and prepared statements "are not cached, not immutable" with no concurrent
manipulation.

**Steal:** the *refusal to paper over single-writer*. A driver that says "one
writer" in its README is a driver whose users do not learn it from a corrupted
production database.

**Refuse:** "not cached" as the final answer. The right shape is a cache the
*caller* opts into and can see (§2.4), not a hidden one and not none.

### 1.11 Zig — `zig-sqlite`

<https://github.com/vrischmann/zig-sqlite>

The only entry in the survey that validates SQL *in the compiler itself*, with
no database and no code generation:

```zig
var db = try sqlite.Db.init(.{
    .mode = sqlite.Db.Mode{ .File = "/path/to/db" },
    .open_flags = .{ .write = true, .create = true },
    .threading_mode = .MultiThread,
});

var stmt = try db.prepare("SELECT id FROM user WHERE weight > ?{usize}");
defer stmt.deinit();
const rows = try stmt.all(usize, allocator, .{}, .{ .weight = @as(usize, 200) });
```

`prepare` takes a **comptime** query string; the library parses it at compile
time to count bind markers and check them against the arguments, and the optional
`?{usize}` annotation gives each marker a type. A mismatch is a compile error:
"value type bool is not the bind marker type usize". Rows map into structs
field-by-field; `one` / `oneAlloc` / `all` split by whether allocation is
permitted; `sqlite.Blob` and `sqlite.Text` disambiguate the two byte-shaped
storage classes at the type level. Custom types join by declaring `BaseType`,
`bindField` and `readField`.

**Steal:** three things, and this is the highest-density entry in the survey.
**(a)** Compile-time *arity* checking with no schema and no database — it costs
one string parse and catches the commonest SQL bug there is. **(b)** The **in-SQL
type annotation** (`?{usize}`), which is sqlx's `as "col!"` idea applied to the
input side. **(c)** `Blob` vs `Text` as *distinct types*, not one bytes type with
a flag.

**Refuse:** allocation policy leaking into three method names. Avra's memory
model makes `one`/`oneAlloc` a distinction without a difference.

### 1.12 Node — `node-sqlite3` vs `better-sqlite3`

<https://github.com/TryGhost/node-sqlite3> · <https://github.com/WiseLibs/better-sqlite3>

The sync-vs-async argument, settled in public. better-sqlite3's position:

> node-sqlite3 "uses asynchronous APIs for tasks that are either CPU-bound or
> serialized. That's not only bad design, but it wastes tons of resources. It
> also causes mutex thrashing which has devastating effects on performance."

and the counter-intuitive claim that follows: a synchronous API gives *better*
concurrency than an asynchronous one, because the work was serialised anyway and
the async machinery only added contention. The benchmark table claims 11.7×
(single row), 24.4× (iteration), 15.6× (batch transactions) over the async
libraries (<https://github.com/WiseLibs/better-sqlite3#benchmark>). The reasoning
in the issue thread is the durable part: async helps when you *wait* on something
external; it does nothing for CPU work that blocks regardless
(<https://github.com/WiseLibs/better-sqlite3/issues/181>).

```javascript
const db = require('better-sqlite3')('foobar.db');
db.pragma('journal_mode = WAL');
const row  = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
const rows = db.prepare('SELECT * FROM users').all();
db.prepare('INSERT INTO users VALUES (?)').run(value);
const insertMany = db.transaction((users) => { for (const u of users) insert.run(u) });
```

Its own regret is the iterator: by default the library refuses to mutate the
database while a result set is open, and an abandoned iterator leaves "This
database connection is busy executing a query"
(<https://github.com/JoshuaWise/better-sqlite3/issues/78>,
<https://github.com/JoshuaWise/better-sqlite3/issues/203>). The escape hatch is
`db.unsafeMode()`, documented as able to corrupt the database.

**Steal:** **(a)** synchronous by default, with the argument attached — this is
directly Avra's position and it has a citable champion. **(b)** `transaction(fn)`
as a *function combinator*: the transaction is a wrapper that makes a function
transactional, not a pair of statements the caller must balance.

**Refuse:** an unfinished iterator that poisons the connection, and an
`unsafeMode()` whose documented cost is corruption (§3.5, §3.12).

### 1.13 The built-ins — `bun:sqlite`, `node:sqlite`

<https://bun.com/docs/runtime/sqlite> · <https://docs.deno.com/api/node/sqlite/>

`bun:sqlite` is better-sqlite3's API with the rough edges filed off, and it is
the state of the art for ergonomics:

```javascript
import { Database } from "bun:sqlite";
const db = new Database("mydb.sqlite");

const q = db.query("SELECT * FROM users WHERE id = $id");   // cached (20 by default)
const p = db.prepare("SELECT * FROM users WHERE id = $id"); // fresh
q.all({ $id: 1 }); q.get({ $id: 1 }); q.run({ $name: "Alice" }); q.values({ $id: 1 });
for (const row of q.iterate()) { }

const strict = new Database(":memory:", { strict: true });  // bind without $ prefixes
strict.query("SELECT $id").all({ id: 5 });

const rows = db.query("SELECT title FROM movies").as(Movie).all();  // rows as a class
const safe = new Database(":memory:", { safeIntegers: true });      // i64 as BigInt
const insertMany = db.transaction(cats => { ... });
insertMany.deferred(cats); insertMany.immediate(cats); insertMany.exclusive(cats);
```

`query()` caches and `prepare()` does not — *the cache is in the verb's name*.
BLOBs are `Uint8Array` in both directions. `safeIntegers` is opt-in per
connection, which is honest about the fact that the host's number type cannot
hold an i64. `node:sqlite`'s `DatabaseSync` (also in Deno ≥2.2) confirms the
industry conclusion: the *standard library* SQLite API of 2026, in the two
newest runtimes, is synchronous.

**Steal:** **(a)** *the cache is named by the verb* — `query` caches, `prepare`
does not, and neither hides. **(b)** BEGIN mode as three named methods on the
transaction (`deferred`/`immediate`/`exclusive`) rather than a string.
**(c)** `strict: true` — a mode where parameter names are ordinary names.

**Refuse:** `strict` being a *mode* at all. If unprefixed names are right, they
are right always; a flag that changes binding semantics is two languages in one
library (§3.10).

### 1.14 Java — `sqlite-jdbc` (xerial)

<https://github.com/xerial/sqlite-jdbc/blob/master/USAGE.md>

```java
try (Connection c = DriverManager.getConnection("jdbc:sqlite:C:/work/mydatabase.db")) { }
SQLiteConfig config = new SQLiteConfig();
config.setSharedCache(true); config.enableLoadExtension(true);
```

JDBC's generic surface over a non-generic database, plus a distribution model
that is its own bug source: the jar carries per-platform native libraries and
*extracts one into `java.io.tmpdir`* at driver load. The issue tracker is a list
of platforms that were not in the jar — ARM, AIX/ppc64, Apple Silicon before it
was added, Alpine/musl detected wrongly, Android's different JNI packaging
(<https://github.com/xerial/sqlite-jdbc/issues/562>,
<https://github.com/xerial/sqlite-jdbc/issues/623>).

**Steal:** `SQLiteConfig` as a *typed* configuration object rather than a DSN
query string — the one thing JDBC does better than Go here.

**Refuse:** shipping a binary per platform and extracting it at runtime (§3.9).
Avra compiles the amalgamation as part of the build; there is no artefact to
extract and no platform to have forgotten.

### 1.15 Ruby — `sqlite3-ruby`

<https://github.com/sparklemotion/sqlite3-ruby> · <https://github.com/sparklemotion/sqlite3-ruby/blob/master/API_CHANGES.md>

```ruby
db = SQLite3::Database.new "test.db"
db.execute("INSERT INTO students (name, email) VALUES (?, ?)", ["Jane", "me@janedoe.com"])
db.execute("select * from numbers") { |row| p row }
stmt = db.prepare "SELECT :inspect"; stmt.execute(...).to_a; stmt.close
```

The 2.0 rewrite is the interesting artefact: the SWIG-generated C adapter was
replaced by a hand-written one, and among the breaking changes,
`SQLite3::Statement#step` now "automatically converts to Ruby types, where before
all values were automatically yielded as strings". A binding that returned
*everything as a string* survived to a 2.0. Thread safety is documented at the
object level: only `Database` is safe to share.

**Steal:** the migration document itself as a model — an `API_CHANGES.md` that
names each behaviour that changed. (Avra's equivalent is a diagnostic that names
the old spelling.)

**Refuse:** stringly-typed reads with a translation layer bolted on
(`type_translation=`, since deprecated) — §3.2.

---

## §2 The affordances that proved beautiful

Ten, named, with the source that proved them.

**2.1 Synchronous, with the argument attached.** better-sqlite3 and, following
it, `bun:sqlite` and `node:sqlite`. SQLite is in-process and serialised; async
adds contention and buys nothing. Avra's position by default; the value here is
the *citation*, so the design does not have to re-argue it.

**2.2 Closure-scoped connections.** GRDB. The handle is only valid inside the
block; "statement outlived its connection" is unrepresentable, not diagnosed.

**2.3 Decomposed record protocols.** GRDB's `FetchableRecord` / `PersistableRecord`
split. A read-only projection over a join is a first-class record. Contrast every
ORM whose model must be a table.

**2.4 The cache named by the verb.** `bun:sqlite`'s `query()` (cached) vs
`prepare()` (fresh). The commonest hidden-state bug in the survey becomes a word
the caller typed.

**2.5 Transaction as a function combinator.** better-sqlite3 / `bun:sqlite`
`db.transaction(fn)`, with `deferred` / `immediate` / `exclusive` as methods.
Nothing to balance, and the BEGIN mode is a name.

**2.6 Nested transactions on SAVEPOINT.** APSW. `with connection:` nests, because
SQLite has SAVEPOINT and a binding that models only BEGIN/COMMIT has thrown that
away.

**2.7 One error per result code, extended codes included.** APSW again, explicitly
against the stdlib's folding. `SQLITE_CONSTRAINT_UNIQUE` and
`SQLITE_CONSTRAINT_FOREIGNKEY` are different problems with different fixes.

**2.8 Comptime arity and marker types.** zig-sqlite's `prepare` over a comptime
string, `?{usize}` markers. No schema, no database, no codegen — and it catches
the bind-count bug, which is the one every developer writes.

**2.9 The in-SQL override.** sqlx's `as "col!: Type"`. When the checker's
inference is wrong, the correction lives in the query. Nothing drifts, because
there is nowhere else for it to live.

**2.10 BLOB as a stream.** `Microsoft.Data.Sqlite`'s `SqliteBlob`; APSW's
`blob_open`. `sqlite3_blob_read/write` exists precisely so a large value need not
be a value.

---

## §3 The bug taxonomy — what proved wrong

Each class: where it bit, then **the design that makes it unwritable in Avra**.

### 3.1 Implicit transaction control

Python's `sqlite3` opens a transaction by *sniffing your SQL* for INSERT/UPDATE/
DELETE/REPLACE, misses DDL, and therefore autocommits `CREATE TABLE` in the
middle of what you believed was a transaction. Deprecated in 3.12 as
`LEGACY_TRANSACTION_CONTROL`, sixteen years on.

**Unwritable:** the driver never issues a statement the caller did not write. A
transaction is a bracket the caller opens (`db.transaction(() -> ...)`), and the
bracket's implementation is a visible `BEGIN`/`COMMIT`/`ROLLBACK` pair — P7,
visible magic. **No code path in `@std/sqlite` parses SQL to decide behaviour**;
that is the same law as the tree's "no string tags or string-matching to detect
behavior" (CLAUDE.md, Rules).

### 3.2 Implicit type coercion

Ruby's pre-2.0 "everything is a string"; C#'s `AddWithValue` inferring from the
CLR value; Python's `detect_types`/`PARSE_DECLTYPES`, which reads a *declared*
type that computed columns do not have, so `max(data)` silently arrives as `str`.
Underneath all of it: SQLite affinity is a hint, and a column declared `INTEGER`
can hold a string.

**Unwritable:** a read names the storage class it wants and *refuses* on
mismatch, with the actual class in the message —
`row.int(0)` answering `Result<int, SqliteError>` where the error names
`SQLITE_TEXT`. A `dyn`-free `Value` enum (`Null | Int | Real | Text | Blob`) is
the escape hatch for callers who want the truth (P8). The affinity is never
consulted to decide a host type; `sqlite3_column_type` is.

### 3.3 The connection pool over an embedded database

`database/sql` + `mattn/go-sqlite3`: a pool over a single-writer in-process
library, whose documented cure is `SetMaxOpenConns(1)`. Worse, a `COMMIT` failing
with `SQLITE_BUSY` leaves the transaction open while the pool believes it closed,
poisoning the connection for its next borrower.

**Unwritable:** there is no pool. A `Db` is one `sqlite3*`. Concurrency is
expressed the way SQLite expresses it — WAL, one writer, N readers, each reader
its own connection opened explicitly — and the driver never hands you a
connection you did not open.

### 3.4 Connection-per-thread / per-goroutine models

Python's stdlib requires the connection and its cursors in the same thread; APSW
does not. Ruby documents that only `Database` is shareable. exqlite requires
statements isolated to one process.

**Unwritable in the near term, and honestly so:** Avra has no threads today.
The design constraint this imposes is *forward*: the `Db` value must not bake in
"single-threaded" assumptions that a later `SQLITE_OPEN_FULLMUTEX` cannot lift.
The open flags are a parameter from day one (§1.14's `SQLiteConfig` shape),
never a constant.

### 3.5 Lazy rows that outlive their statement

rusqlite's `Rows` cannot be an `Iterator` because the row borrows the statement.
better-sqlite3 refuses to mutate during `.iterate()` and leaves the connection
"busy" if the iterator is abandoned; its escape is `unsafeMode()`, documented as
corrupting. Under the C API this is not a language quirk, it is the documented
rule: the pointers from `sqlite3_column_blob/text` die at the next
`sqlite3_step`.

**Unwritable:** a `Row` handed to user code is **materialised** — every cell
copied into an Avra-owned box before the next step. The alias never escapes.
Streaming is a *fold*, not an iterator: `stmt.each((row) -> ...)`, where the
row's validity is exactly the callback's extent. GRDB's closure discipline (2.2)
applied one level down. Cost: an allocation per cell for the ergonomic path — and
the escape hatch for the hot path is the fold, which never allocates because the
callback reads within the step.

### 3.6 Hidden statement caches

sqlite4java grew its statement cache unboundedly until the heap died
(<https://github.com/tyut05000/sqlite4java/issues/35>); the general shape is a
cache keyed by SQL text with no eviction, filled by string-concatenated queries
that are never identical. rusqlite's `prepare_cached` keys on the query string
and is documented as "kind of sub-optimal" for it. `bun:sqlite` caches 20 by
default — but says so in the verb.

**Unwritable:** the cache is a *value the caller holds*, with a declared
capacity, and the verb says which you got (2.4). A cache with no bound cannot be
constructed. Corollary: `finalize` is not optional — SQLite's own docs are blunt
that a missing `sqlite3_finalize` leaks until process exit
(<https://sqlite.org/forum/forumpost/127dec782d>), which is why the statement is
a `defer`-closed resource, not a GC-closed one.

### 3.7 Resource lifetime tied to the wrong scope

rusqlite: a cached statement borrows the connection, so it must be dropped
before its transaction commits. C#: the only thing finalizing a statement is
`using`. JDBC: `try-with-resources`, or nothing.

**Unwritable:** `defer`/`errdefer` exist and the tree's law is written
(CLAUDE.md: "A `defer`'s FRAME IS ITS STATEMENT LIST"). Every C handle the driver
mints is closed by a `defer` in the function that minted it, or is owned by a
value whose drop closes it. Spec 15.5's `opaque type SQLite3 @free_with(sqlite3_close)`
is the compiler-managed form and is the campaign's target (BLOCKER B3).

### 3.8 Success by default / error codes as ordinary integers

Not observed as a *driver* bug in this survey, but present everywhere the C API
is used directly: `sqlite3_step` returns `SQLITE_ROW`, `SQLITE_DONE`,
`SQLITE_BUSY`, `SQLITE_ERROR`, `SQLITE_MISUSE` — five different meanings in one
`int`, three of which are not failures. The stdlib Python module folds distinct
codes into shared exceptions; APSW names this as a defect (§1.6).

**Unwritable:** `step` answers a three-state enum (`Row | Done | Failed(err)`),
never an int, and `SqliteError` carries the *primary* code, the *extended* code,
and `sqlite3_errmsg`'s text. This is the tree's existing law generalised: "A
PROCESS STATUS IS A VERDICT, never a count" (CLAUDE.md).

### 3.9 Ambient SQLite

sqlite-jdbc ships a native library per platform and extracts it to a temp dir at
load; the issue tracker is the list of platforms it forgot. Python on macOS gets
Apple's libsqlite3, which is built *without* `SQLITE_ENABLE_COLUMN_METADATA`, so
`sqlite3_column_table_name()` and friends do not exist
(<https://sqlite.org/forum/info/e2919aa79344de19>,
<https://github.com/simonw/til/blob/main/sqlite/sqlite-version-macos-python.md>).
Go makes FTS5 and JSON *build tags*, so a binary's capabilities depend on how it
was compiled and nothing says so at runtime.

**Unwritable:** the amalgamation is vendored and compiled with our flags, linked
through the manifest's `[link]` row
(`packages/std-avrac/src/language/manifest.av:57` — `objects` and `flags`;
`packages/std-avrac/src/language/workspace.av:939`). Exactly rusqlite's `bundled`
posture, and it is what makes "full surface" a claim we can keep: column
metadata, `serialize`/`deserialize`, and the session extension are compile
options we set, not options we hope for.

### 3.10 Behaviour flags that change the language

`bun:sqlite`'s `strict: true` changes how parameter names bind. Go's DSN
smuggles `_busy_timeout` and `_txlock` through a URL query string. C#'s
connection string does the same.

**Unwritable:** configuration is a typed value with named fields (`OpenFlags`,
`Pragmas`), never a string parsed by the driver, and never a mode that changes
what a call *means*. Same law as 3.1.

### 3.11 A hand-maintained schema mirror

SQLite.swift's `Expression<Int64>("id")` declarations, jOOQ without codegen,
every ad-hoc "models" file. Two sources of truth, and nothing compares them.

**Unwritable in the later phase:** the comptime-SQL slice derives column names,
types and nullability from *the migrations in the package*, by preparing the
statement against a schema built from them (§4). There is nothing to hand-maintain
because there is nothing hand-written.

### 3.12 An unsafe mode with an undo-able cost

`db.unsafeMode()` — documented as permitting operations that "could potentially
corrupt your database".

**Unwritable:** P8 says escape hatches everywhere, and P7 says visible magic —
but an escape hatch whose failure mode is *silent data corruption* is neither. If
mutation-during-iteration is needed, the driver's answer is the shape that is
actually safe (materialise the row set, then mutate), and the diagnostic says so.

---

## §4 The compile-time-checked query — the prior art

Six systems, one table. The question that separates them is **where the schema
lives at check time**.

| System | Schema source at check time | What the developer does | What breaks |
|---|---|---|---|
| **sqlx** (Rust) | A **live database** at `DATABASE_URL`; the engine prepares the query and reports column types + nullability. For SQLite the driver walks the prepared statement's *bytecode* to infer nullability. | Writes ordinary SQL in a `query!` macro; overrides bad inference in the column alias (`as "col!: Type"`). Runs `cargo sqlx prepare` to cache into `.sqlx/`. | The build needs a database. A migration breaks compilation. A stale `.sqlx` is a silent lie. Runtime-built SQL is unchecked. (<https://github.com/launchbadge/sqlx/issues/2087>) |
| **Diesel** (Rust) | A generated `schema.rs` of `table!` macros, produced by `diesel print-schema`. | Writes queries in a typed DSL, not SQL. Regenerates `schema.rs` after migrations. | Compiler errors become "40 lines of generic type vomit"; dynamic query shapes fight the type system. (<https://leapcell.io/blog/diesel-and-sqlx-a-deep-dive-into-rust-orms>) |
| **sqlc** (Go) | The **DDL files themselves** — sqlc parses `CREATE TABLE` statements and the query files, with no database running. | Writes SQL in `.sql` files annotated `-- name: GetX :one`. Runs `sqlc generate`. | Nullability becomes `sql.NullString`; unwrapping without checking `.Valid` is the new bug. Generated code is committed and can drift. (<https://conroy.org/introducing-sqlc>) |
| **jOOQ** (Java) | A live database or DDL, via the code generator. | Runs codegen in the build; writes queries in a typed DSL. | "The build may break in perfectly acceptable situations, when parts of your database are temporarily unavailable." Some teams commit generated code, some regenerate. (<https://www.jooq.org/doc/latest/manual/code-generation/codegen-version-control/>) |
| **Kysely** (TypeScript) | A hand-written `Database` interface, or `kysely-codegen` introspecting a live database into `.d.ts`. | Passes the interface as a generic parameter; the types flow through the builder. | Type-level only; regeneration required after every migration; runtime SQL unchecked. (<https://github.com/kysely-org/kysely/blob/master/site/docs/generating-types.md>) |
| **zig-sqlite** | **Nothing.** No schema at all. | Writes SQL as a comptime string; optionally annotates markers `?{usize}`. | Only *arity* and *marker types* are checked — column names and types are not. |

### What this says for Avra

Three findings, and they are the ones that change the design.

**F1 — sqlc and zig-sqlite prove the check does not need a running database.**
sqlc parses DDL; zig-sqlite parses the query. Avra's position is stronger than
either: the package **vendors and links SQLite itself**, so the compiler can
*prepare the statement against a real in-memory database built from the package's
migrations* and read back `sqlite3_column_count`, `sqlite3_column_name`,
`sqlite3_column_decltype`, and — because we set the compile flag —
`sqlite3_column_table_name`/`origin_name`. That is sqlx's *fidelity* with sqlc's
*hermeticity*, and no other system in the table has both. Confidence: **MEDIUM**
on feasibility (it requires the compiler to link and call SQLite at comptime,
which is a real capability question — see BLOCKER B7), **HIGH** on it being the
right target.

**F2 — the whole table's shared failure is nullability.** sqlx: fragile,
observed by walking bytecode, corrected by hand in the alias. sqlc: mapped to
`NullString`, unwrapped unsafely. Kysely: whatever the codegen guessed. SQLite's
own `sqlite3_column_decltype` is the reason:

> "For a SELECT statement, if the Nth column of the returned result set is a
> table column (not an expression or subquery), then the declared type of the
> table column is returned. However, if the Nth column of the result set is an
> expression or subquery, then a NULL pointer is returned."
> — <https://sqlite.org/c3ref/column_decltype.html>

So *computed columns have no type and no nullability, ever*. The design must
therefore ship **the override with the checker**, not after it: sqlx's
`as "col!: Type"` is not a wart, it is a load-bearing part of the feature, and
Avra should land it in the same slice. Confidence: **HIGH**.

**F3 — arity checking is nearly free and should land first.** zig-sqlite gets
real value from parsing the query string alone. Avra can count `?`/`:name`/`$name`
markers in a literal SQL string at comptime and check them against the bind call
with no schema, no database, no migrations — a small, shippable first rung that
does not wait on B7. Confidence: **HIGH**.

**One refusal.** Every DSL entry in the table (Diesel, jOOQ, Kysely,
SQLite.swift) reports the same cost: the DSL is a second language, dynamic
shapes fight it, and its errors are worse than the SQL's. Avra should check
**SQL**, not replace it. This is P17 (composability over featurefulness) and it
is the majority verdict of the prior art.

---

## §5 The ranked adoption table

Ranked by (value to the driver) × (cost to reach). "Has it?" is about the tree
**today**, verified where marked.

| # | Affordance | Source | Language feature needed | Avra has it? |
|---|---|---|---|---|
| 1 | One `extern fn` per C entry point; zero shim | campaign / rusqlite `-sys` | `extern fn`, **out-params**, **fn-pointer seats**, **`ptr` literals** | **Partly.** `extern fn` yes (`packages/std-process/src/process.av:15`); the three others **no** — B1, B2, B4 |
| 2 | REAL columns read and bound without loss | every entry | **`float` (IEEE-754 f64)** + an **F64 ABI kind** | **No.** `Type` has no float (`packages/std-avrac/src/core/types.av:12-60`); `RtKind { I64, Ptr, Void }` (`packages/std-avrac/src/core/ir.av:217`) — B5 |
| 3 | BLOB columns read and bound intact | every entry | **`Bytes`** core value category | **No** — B6 |
| 4 | Handles closed automatically, never leaked | GRDB, APSW, rusqlite | `defer` (have) + **`opaque type @free_with`** | **Partly.** `defer`/`errdefer` landed; opaque types **no** — B3 |
| 5 | One error value per result code, extended codes | APSW | enums + `Result` (have) | **Yes.** Named-enum error + `Result` is the tree's standard shape |
| 6 | Synchronous, no async wrapper | better-sqlite3, bun, node | nothing — the absence of a feature | **Yes**, by construction |
| 7 | `transaction(fn)` combinator, `deferred`/`immediate`/`exclusive` | better-sqlite3, bun | lambdas + `Result` (have) | **Yes** |
| 8 | Nested transactions on SAVEPOINT | APSW | a depth counter on `Db` — `mut` state (have) | **Yes** |
| 9 | Materialised rows; streaming as a fold | §3.5 | lambdas (have) | **Yes** |
| 10 | Cache named by the verb, bounded capacity | bun:sqlite | `Map` + a declared cap (have) | **Yes** |
| 11 | Typed config value, never a DSN string | sqlite-jdbc | structs (have) | **Yes** |
| 12 | Decomposed record protocols (readable / writable) | GRDB | traits (have; **default bodies landed** — ROADMAP, lane C) | **Yes** |
| 13 | Comptime bind-arity check | zig-sqlite | `@comptime` over a literal string | **No.** `@comptime` refuses at the `@` (CLAUDE.md, The subset today) — B7 |
| 14 | In-query type/nullability override (`as "col!"`) | sqlx | ships with 13 | **No** — B7 |
| 15 | Full schema check against vendored SQLite | F1 | 13 + compiler linking SQLite at comptime | **No** — B7, and the hardest |
| 16 | BLOB as a stream (`sqlite3_blob_*`) | C#, APSW | 3 + opaque handle | **No** — needs B3, B6 |
| 17 | Scalar/aggregate functions, hooks, authorizer, VFS | APSW | **callback trampolines** | **No** — B4 |
| 18 | i64 fidelity | bun (`safeIntegers`) | Avra `int` is already i64 | **Yes**, free — a genuine advantage over every JS and Python entry |
| 19 | `Blob` and `Text` as distinct types | zig-sqlite | 3, done right | Falls out of B6 if `Bytes` and `string` stay separate |
| 20 | Vendored amalgamation, our flags | rusqlite `bundled` | manifest `[link]` (have) | **Yes** (`packages/std-avrac/src/language/manifest.av:57`) |

---

## BLOCKERS

Seven. B1, B2 and B5 stop the *first line of the driver from compiling*; the rest
stop "full surface". Each has a proposed shape; each shape is checked against the
tree's laws and against spec Axis 15, which — usefully — uses SQLite as its own
worked example throughout
(`forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md:2989-3029`).

### B1 — There is no way to call an out-parameter constructor. **Blocking.**

Nearly every SQLite constructor returns its handle through a `**` out-param:
`sqlite3_open_v2(path, &db, flags, vfs)`, `sqlite3_prepare_v2(db, sql, n, &stmt, &tail)`,
`sqlite3_blob_open(..., &blob)`. Avra has no `*T`, no `&x`, and no way to spell
`*mut *SQLite3`. `extern fn` seats are ordinary Avra types
(`packages/std-avrac/src/features/fns/tests/fns_test.av:11`).

The spec anticipates exactly this and writes `db: *mut *SQLite3`
(spec:3012) — but a raw pointer-to-pointer type in the surface language is a
poor fit for a tree whose law is "nothing reads through it"
(`packages/std-avrac/src/core/types.av:19-21`).

**Proposed shape — the out-param is the ANSWER.** Declare the C convention, let
the compiler generate the honest signature (this is spec 15.4 + 15.7 composed,
and it is the shape the spec already sketches for `@returns_ownership(db)`):

```
extern fn sqlite3_open_v2(path: string, flags: int, vfs: ptr) -> ptr
  @out(1)                              // the handle rides C parameter 2
  @error_if(it != 0, sqlite_error)     // generated: -> Result<ptr, SqliteError>
```

The compiler allocates the slot, passes its address, reads it back, and the call
answers `Result<ptr, SqliteError>`. No pointer-to-pointer type enters the
language; the FFI declares one more C convention, which is precisely what the
annotation vocabulary is for. Confidence in the *need*: **HIGH** (read from the
SQLite API). Confidence in *this* shape: **MEDIUM** — a plain `out` seat
(`out db: ptr`) is the alternative and is simpler, but it makes the caller
declare a binding whose only purpose is to be written, which the tree's
"a write reaches a PLACE" discipline (DOGFOODING) already treats as a smell.

### B2 — A foreign `char*` cannot be an Avra `string`, and there is no verb to make one. **Blocking.**

The tree's law: "EVERY POINTER AVRA HOLDS CARRIES A HEADER" (CLAUDE.md). A
string box is sixteen bytes of header (tag, kind, rc, len) followed by the
payload (`runtime/avra_runtime.c:56-61`). `sqlite3_column_text` and
`sqlite3_errmsg` return pointers that have no such header — and whose validity
ends at the next `sqlite3_step`/`reset`/`finalize`
(<https://www.sqlite.org/c3ref/column_blob.html>).

Typing such an extern's answer as `string` is *quietly* wrong, which is worse
than loudly wrong. Verified in the tree:

- `hdr()` refuses a pointer that is unaligned, sub-image, or untagged
  (`runtime/avra_runtime.c:68-74`), so `avra_rc_retain` / `avra_rc_release`
  **no-op** on a foreign pointer (`runtime/avra_runtime.c:383-386`, `:415-417`).
  No crash, no diagnostic.
- `.length` falls through to `strlen` for a non-box (`runtime/avra_runtime.c:271-275`),
  so it *works* — and truncates at an embedded NUL.
- An extern's result is never released: `managed_dst` gives a `CallRt` result an
  owner only when the registry says `owns_result`
  (`packages/std-avrac/src/language/memory.av:316-327`), and a program-declared
  extern's row is `extern_row(...) owns_result: false`
  (`packages/std-avrac/src/core/runtime_api.av:103`).

So the value is a borrowed alias with no lifetime, held by a type whose whole
contract is that it is owned. The moment it is pushed into a list, stored in a
field, or handed to an Avra call, the pack rewrite and `retained_args`
(`packages/std-avrac/src/language/memory.av:120-131`, `:383-385`) will retain
something that is not ours — today a silent no-op, tomorrow whatever SQLite put
in the sixteen bytes before its buffer.

**Proposed shape — one core verb, not a SQLite shim.** A runtime row that
copies a foreign region into a headered box:

```
avra_str_from_host(p: ptr, len: int) -> string     // owns_result: true
avra_bytes_from_host(p: ptr, len: int) -> Bytes    // with B6
```

This is *language infrastructure*, not a shim: it is the general FFI answer for
every C library, it is one registry row plus one C body (the "VOCABULARY SEAM
RULE" — data, so a registry row), and the precedent is exact:
`avra_str_from_codepoint` is a row minted for `@std/text`
(`packages/std-avrac/src/core/runtime_api.av:88`). It also satisfies the campaign's "zero hand-written C shim" literally:
there is no SQLite-specific C anywhere.

**The law this must carry:** an `extern fn` may **never** declare `string` or
`Bytes` as its answer. The extern layer answers `ptr` and `int`; the projection
copies. That should be a compiler refusal with a named voice, not a convention.
Confidence: **HIGH** — every step verified in the tree.

### B3 — No opaque types, no `@free_with`. **Blocking "full surface", not the first line.**

`ptr` is inspectable-by-nobody but also distinguished-from-nothing: a
`sqlite3*`, a `sqlite3_stmt*` and a `sqlite3_blob*` are all `ptr`, so passing a
statement where a connection belongs is not a type error. And nothing runs
`sqlite3_close_v2`/`sqlite3_finalize` on drop.

**Proposed shape:** spec 15.5 verbatim — `opaque type SQLite3 @free_with(sqlite3_close_v2)`.
Values are heap pointers the compiler wraps; drop calls the named C function
(spec:2999-3006). Near-term stand-in with today's language: a one-field struct
per handle (`type Db = { raw: ptr }`), which buys the type distinction and
nothing else, plus a `defer` at every mint. Confidence in the need: **HIGH**.
Note the tree's flattening rule bites here — "WHETHER A VALUE RIDES A POINTER IS
ITS DECLARATION'S ANSWER" (CLAUDE.md): a one-scalar-field record is *flattened*,
so `Db { raw }` travels as its `ptr`. That is fine for the ABI and fatal for a
`@free_with` drop hook, which is another reason the real feature is the opaque
type, not the struct.

### B4 — No function-pointer seats, no trampolines. **Blocking "full surface".**

`sqlite3_create_function_v2`, `sqlite3_exec`'s callback, `sqlite3_update_hook`,
`sqlite3_commit_hook`, `sqlite3_set_authorizer`, `sqlite3_busy_handler`,
`sqlite3_progress_handler`, `sqlite3_trace_v2` and every virtual-table method all
take C function pointers. Avra's `Fn` type is a *box* — "the runtime shape is a
box `[code address, captures…]`" (`packages/std-avrac/src/core/types.av:53-57`)
— which is not a C function pointer, and there is no way to declare a seat that
wants one.

Worse, a `mut` seat cannot even be spelled in a fn type today (CLAUDE.md, The
subset today), so a callback that writes to caller state has no honest signature.

**Proposed shape:** spec 15.3's compiler-generated trampolines — the compiler
emits a C-ABI function per closure type that unpacks `void* user_data` and calls
the Avra closure (spec:2929-2951). SQLite is the ideal first customer because
*every* one of its callbacks takes a `void*` user-data argument, so the "C API
without user_data" refusal path (spec:2948) is never hit. Confidence: **HIGH**
on the need; the design is already decided in the spec.

### B5 — No float, and the extern ABI has no float kind. **Blocking.**

Two distinct gaps, and the second is easy to miss.

1. The language has no floating-point type. `Type` runs
   `Int, Bool, Str, Ptr, Struct, Enum, App, Dyn, List, Map, Res, Fn, Void`
   (`packages/std-avrac/src/core/types.av:12-60`); the JSON slice records the
   consequence in the ROADMAP: "numbers are INTEGERS (the language has no float:
   a fraction or exponent is `Fraction(at)`, refused by name, never rounded)"
   (`ROADMAP.md:1029`).
2. **The host-call ABI has no float kind.** `RtKind { I64, Ptr, Void }`
   (`packages/std-avrac/src/core/ir.av:217`), and `rt_kind_of` maps every type to
   one of the three (`packages/std-avrac/src/core/runtime_api.av:95-99`). On
   both x86-64 SysV and AArch64 AAPCS a `double` argument travels in a *vector*
   register, not an integer one. So even with `float` in the type system,
   `sqlite3_bind_double` would receive garbage until `RtKind` grows `F64` and the
   backend declares and coerces it (`packages/std-avrac/src/language/llvm.av:175`,
   `ll_rt_kind`).

**Proposed shape:** `float` as IEEE-754 binary64, `RtKind.F64` added with its
backend and interpreter arms — the IR vocabulary protocol's "PAY THE CONSUMERS"
rule applies (CLAUDE.md), though `RtKind` is a *kind* table rather than an
instruction, so the cost is the four sites that match it, not the eight. The
campaign's `decimal` is a separate, later value category and does **not** block
SQLite: SQLite has no decimal storage class, and money in SQLite is an INTEGER of
minor units or a TEXT — which Avra already has. Confidence: **HIGH** on the two
gaps (both read from source); **HIGH** on decimal being out of the critical path.

### B6 — No bytes type; `string` is byte-safe in the box and NUL-unsafe in every verb. **Blocking.**

The box is right: a string header carries `len` (`runtime/avra_runtime.c:56-61`)
and `str_len` reads it (`:271-275`), so a `string` *can* hold NULs and
`.length` is a load. The verbs are wrong — verified, every one:

| Verb | Implementation | Site |
|---|---|---|
| `==` | `strcmp` | `runtime/avra_runtime.c:477` |
| `contains` | `strstr` | `:1145` |
| `starts_with` | `strncmp` — stops at either NUL | `:1149` |
| `index_of` | `strstr` | `:1160` |
| `replace` | `strlen` ×3 + `strstr` loop | `:1208-1217` |
| `split` | `strlen` + `strstr` | `:1234-1244` |

So a BLOB round-tripped through `string` survives storage and dies on the first
comparison, silently. (The tree has already fixed one instance of exactly this
class — commit `3c622be`, "a write reads the header's length, never strlen"; and
`avra_proc_run`'s `stdin_text` still measures with `strlen` at
`runtime/avra_runtime.c:1919`, which is the same bug awaiting the same fix.)

**Proposed shape:** `Bytes` as a core value category — a headered box with a
length and *no* NUL assumption, its own verbs (`length`, `slice`, `==` by
`memcmp`, `concat`), and explicit, fallible conversions to and from `string`
(`text(b) -> string?` refusing invalid UTF-8; `bytes(s) -> Bytes` total). Keep
`Bytes` and `string` distinct at the type level — zig-sqlite's `Blob`/`Text`
split is the right precedent, and it makes `sqlite3_bind_blob` versus
`sqlite3_bind_text` a type decision instead of a flag. This is a *core event*
under the tree's protocol (the value protocol grows with value categories, never
per feature — CLAUDE.md). Confidence: **HIGH**.

### B7 — No `@comptime`; the interpreter cannot host an arbitrary extern. **Blocking the later phase and the eval==native promise.**

Two halves.

**(a) `@comptime` does not exist.** "refuses at the `@`" (CLAUDE.md, The subset
today). Every §4 affordance above rung 13 needs it.

**(b) The interpreter hosts externs by *name*, not by symbol.** An extern the
runtime registry knows *is* hosted — `avra_now_ns()` runs under `avra run`
(`packages/std-avrac/src/features/fns/tests/fns_test.av:19-21`) — and one it does
not know traps: "`avra_host_is_dir` is extern — the evaluator cannot host it;
build natively" (`:17`). The mechanism is `RtHost`, an *exhaustive enum with one
variant per host body* (`packages/std-avrac/src/core/ir.av:219-232`), which is
precisely why an arbitrary `sqlite3_*` cannot be hosted: there is no variant for
it and there cannot be.

**Proposed shape for (b):** a `RtHost.Foreign` arm whose body is
`dlopen`/`dlsym` plus a **fixed set of uniform ABI shapes** keyed by the
declared `RtKind` sequence — `(I64) -> I64`, `(Ptr, I64) -> Ptr`, … The
prior art splits cleanly here: Deno went to libffi and then JIT-compiled
trampolines for speed (<https://littledivy.com/turbocall.html>), Bun implemented
`dlopen`/`linkSymbols`/`CFunction` natively in JavaScriptCore
(<https://bun.com/docs/runtime/ffi>). For an *interpreter*, a fixed shape table
is the right trade: no libffi dependency, no JIT, and the shapes are enumerable
because `RtKind` has three members (four with F64). N parameters × 4 kinds is a
generated switch, not a design problem. Confidence: **MEDIUM** — the shape is
sound and the arity bound needs choosing (SQLite's widest common entry point is
`sqlite3_create_function_v2`, 8 parameters).

**Note the dependency:** (b) is what makes "eval == native holds by
construction" true, and it is *also* the cheapest path to (a)'s hardest rung
— a compiler that can call `sqlite3_prepare_v2` through the interpreter can
check a query at comptime with no new machinery beyond `@comptime` itself.

---

## What this survey says is genuinely new

Most of the above is theft and says so. Three things are not.

- **The layer split (§0).** Every binding in the survey chose between complete
  and ergonomic because declaring 300 foreign functions was expensive in its host
  language. Avra's `extern fn` makes the extern layer mechanical, so the choice
  disappears — the surface is the C API and the beauty is a projection over it.
  No surveyed binding is structured this way.
- **F1 — hermetic *and* faithful comptime SQL.** sqlx is faithful and needs a
  live database; sqlc is hermetic and re-implements a SQL front end. A package
  that *vendors and links SQLite* can prepare the real statement against a schema
  built from its own migrations. Nothing in the table has both properties.
- **B2's law.** No surveyed FFI states "an `extern fn` may never answer the
  host's owned value type". Every one of them either copies by convention or
  aliases and documents the hazard. In a tree whose memory model is a header on
  every pointer, it is a *compiler refusal* — and it is the one law that keeps
  "zero C shim" from meaning "use-after-free with no diagnostic".

---

## The five, in one line each

1. **The extern layer is total; the beauty is a projection over it.**
2. **A read names the storage class it wants, and refuses on mismatch.**
3. **A row handed to user code is copied; streaming is a fold, never an iterator.**
4. **Nothing happens behind your back** — no SQL sniffing, no implicit BEGIN, no hidden cache.
5. **The SQLite we run is the SQLite we compiled**, with our flags, from our vendored source.

---

## CONFIDENCE LEDGER

| # | Load-bearing claim | How verified | Confidence |
|---|---|---|---|
| 1 | `extern fn` exists and is used at scale | `packages/std-process/src/process.av:15-29`, 15 declarations | HIGH |
| 2 | An extern call lowers to `CallRt`/`CallRtVoid` and its arguments are **borrowed** | `packages/std-avrac/src/features/fns/lower.av:41-50`; `retained_args` fires only for `.Call`/`.CallPtr`, `packages/std-avrac/src/language/memory.av:120-131`, `:383-385` | HIGH |
| 3 | An extern's result is never released (no `owns_result`) | `packages/std-avrac/src/core/runtime_api.av:103` (`extern_row`), `:124` (`rt_owns`), `packages/std-avrac/src/language/memory.av:316-327` | HIGH |
| 4 | `avra_rc_retain`/`release` silently no-op on a foreign pointer | `runtime/avra_runtime.c:68-74` (`hdr`), `:383-386`, `:415-417` | HIGH |
| 5 | `.length` on a foreign pointer falls back to `strlen` | `runtime/avra_runtime.c:271-275` | HIGH |
| 6 | `==`, `contains`, `starts_with`, `index_of`, `replace`, `split` are NUL-truncating | `runtime/avra_runtime.c:477, 1145, 1149, 1160, 1208-1217, 1234-1244` | HIGH |
| 7 | No float type; `RtKind` has no float kind | `packages/std-avrac/src/core/types.av:12-60`; `packages/std-avrac/src/core/ir.av:217`; `ROADMAP.md:1029` | HIGH |
| 8 | A double must travel in a vector register on x86-64 SysV / AArch64 AAPCS | ABI knowledge, **not** verified in this tree | MEDIUM |
| 9 | The interpreter hosts externs by registry *name*, not symbol; unknown externs trap | `packages/std-avrac/src/features/fns/tests/fns_test.av:17` and `:19-21`; `RtHost` enum, `packages/std-avrac/src/core/ir.av:219-232` | HIGH |
| 10 | Packages can link C objects and flags via the manifest | `packages/std-avrac/src/language/manifest.av:57`, `:109`; `packages/std-avrac/src/language/workspace.av:939, 953`; `packages/cli/src/commands/shared.av:277` | HIGH |
| 11 | `ptr` is a spellable type with no literals and no conversions | `packages/std-avrac/src/language/typing.av:322`; `packages/std-avrac/src/core/types.av:19-21`; no producer found by grep other than an extern's answer | HIGH |
| 12 | A one-scalar-field record is flattened by declaration | CLAUDE.md, "WHETHER A VALUE RIDES A POINTER…" | HIGH (doctrine, not re-probed) |
| 13 | Spec Axis 15 prescribes `opaque type @free_with`, ownership annotations, `@error_if`, trampolines, `CString`/`CStr` | `forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md:2873-3060` | HIGH |
| 14 | SQLite column pointers die at the next `step`/`reset`/`finalize` | <https://www.sqlite.org/c3ref/column_blob.html> | HIGH |
| 15 | `SQLITE_STATIC` vs `SQLITE_TRANSIENT` copy semantics; bind index is 1-based | <https://www.sqlite.org/c3ref/bind_blob.html> | HIGH |
| 16 | `sqlite3_open_v2` returns a handle even on failure; it must still be closed | <https://www.sqlite.org/c3ref/open.html> | HIGH |
| 17 | `sqlite3_column_decltype` returns NULL for expressions | <https://sqlite.org/c3ref/column_decltype.html> | HIGH |
| 18 | macOS's system libsqlite3 lacks `SQLITE_ENABLE_COLUMN_METADATA` | <https://sqlite.org/forum/info/e2919aa79344de19>; <https://github.com/simonw/til/blob/main/sqlite/sqlite-version-macos-python.md> | MEDIUM — reported consistently, not measured on this machine |
| 19 | APSW's "nothing happens behind your back"; per-code exceptions; threading | <https://rogerbinns.github.io/apsw/pysqlite.html> | HIGH |
| 20 | Python `sqlite3` opens transactions by sniffing SQL and misses DDL | <https://docs.python.org/3/library/sqlite3.html>; <https://docs.sqlalchemy.org/en/20/dialects/sqlite.html> | HIGH |
| 21 | better-sqlite3's sync argument and benchmark multipliers | <https://github.com/WiseLibs/better-sqlite3>; <https://github.com/WiseLibs/better-sqlite3/issues/181> | HIGH for the argument; MEDIUM for the numbers (author-run) |
| 22 | `bun:sqlite` — `query` caches (20), `prepare` does not; `.as(Class)`; `safeIntegers`; `deferred`/`immediate`/`exclusive` | <https://bun.com/docs/runtime/sqlite> | HIGH |
| 23 | rusqlite `Rows` is not an `Iterator`; `prepare_cached` keys on SQL text | <https://docs.rs/rusqlite/latest/rusqlite/struct.Rows.html>; <https://users.rust-lang.org/t/rusqlite-prepared-statements-in-transactions/41373/4> | HIGH |
| 24 | sqlx requires a literal query; `as "col!: T"` overrides; `.sqlx` offline cache; SQLite nullability by walking bytecode | <https://docs.rs/sqlx/latest/sqlx/macro.query.html>; <https://deepwiki.com/launchbadge/sqlx/4.2-compile-time-query-checking> | HIGH |
| 25 | zig-sqlite checks bind arity and marker types at comptime | <https://github.com/vrischmann/zig-sqlite> | HIGH |
| 26 | sqlc parses DDL + queries with no live database | <https://conroy.org/introducing-sqlc>; <https://github.com/sqlc-dev/sqlc> | HIGH |
| 27 | `database/sql` + SQLite: pool poisoning on `SQLITE_BUSY` at COMMIT; the `MaxOpenConns(1)` cure | <https://github.com/mattn/go-sqlite3/issues/632>; <https://github.com/mattn/go-sqlite3> | MEDIUM — issue-thread reporting, widely corroborated |
| 28 | modernc.org/sqlite is ~2× slower on INSERT, 10%–2× on SELECT | <https://datastation.multiprocess.io/blog/2022-05-12-sqlite-in-go-with-and-without-cgo.html> | MEDIUM — one benchmark author |
| 29 | exqlite uses the dirty scheduler and refuses to support simultaneous writing | <https://github.com/elixir-sqlite/exqlite> | HIGH |
| 30 | sqlite-jdbc extracts a per-platform native library to `java.io.tmpdir` | <https://github.com/xerial/sqlite-jdbc/blob/master/SQLiteJDBC.wiki> | HIGH |
| 31 | GRDB scopes `Database` to read/write closures; record protocols are decomposed | <https://github.com/groue/GRDB.swift> | HIGH — README fetched; the Concurrency guide returned 403 and was not read |
| 32 | Deno FFI uses libffi + JIT trampolines; Bun implements dlopen natively | <https://littledivy.com/turbocall.html>; <https://bun.com/docs/runtime/ffi> | MEDIUM |
| 33 | Vendoring the amalgamation is the answer to ambient SQLite | rusqlite `bundled` (<https://github.com/rusqlite/rusqlite>) + claim 18 + claim 10 | HIGH |
| 34 | The layer split, the F1 hermetic-and-faithful claim, and B2's law are new | Not found in any surveyed system — an argument from absence | **LOW-MEDIUM** — absence of evidence across fifteen systems |

**Weakest link:** claim 8 (the float ABI register class) is ABI knowledge rather
than a reading of this tree, and it is what makes B5 *two* gaps instead of one.
It is cheap to settle: a scratch probe declaring an extern with a `float` seat,
once `float` exists, against a C body that prints its argument. Second weakest:
claim 34, which is an argument from absence and should be held loosely.
