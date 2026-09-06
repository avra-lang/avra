# @std/sqlite — the ORM substrate

What the ORM that will be built on this driver needs FROM the driver,
specified before the driver exists so it is designed for rather than
retrofitted. The driver is substrate; this document is the contract
the endpoint will hold it to.

Sources: the SQLite C API and pragma documentation; the ORM designs of
Rust (Diesel, SeaORM, sqlx), Python (SQLAlchemy Core/ORM), Elixir
(Ecto), TypeScript (Prisma, Drizzle, Kysely), Go (sqlc), Swift (GRDB),
Java (jOOQ, Hibernate). Every external claim carries its URL in the
CONFIDENCE LEDGER at the tail.

---

## 0. The one sentence

An ORM needs from its driver exactly four things nobody can add later:
**typed values including float and bytes**, **a describe that runs
before any row exists**, **transaction primitives including
savepoints**, and **an error that names its extended code and its byte
offset**. Everything else can be built above the seam. Those four
cannot.

---

## 1. THE DRIVER-LEVEL FEATURE LIST

### 1.1 Schema reflection — table_info, foreign_key_list, index_list

**Who demands it.** SQLAlchemy's SQLite dialect reflection is built
entirely on `PRAGMA table_info()` and `PRAGMA foreign_key_list()`.
GRDB carries a whole schema cache with `ForeignKeyInfo` and
`IndexInfo` record types and a `clearSchemaCache()` the app must call
when another connection changes the schema. jOOQ's entire code
generator is reverse-engineering of a live schema — "there should only
be one source of truth for your meta model, and that's the DDL you ran
in your database". Alembic and Ecto's migration runners diff against
it.

**Why.** Three separable needs: the migration diff (declared model vs
actual schema), the write planner (which column is the primary key,
which foreign keys cascade), and nullability (a `NOT NULL` column maps
to `T`, everything else to `T?`).

**The SQLite affordance, and the design consequence.** Since 3.16.0
every side-effect-free pragma is also a **table-valued function**:
`SELECT * FROM pragma_table_info('users')`, joinable and filterable.
So reflection needs **no new C entry point** — it is a query. That is
the paradox collapse (P6): the driver does not grow a reflection
subsystem; it grows nothing, and reflection is a schema over its
existing query surface.

What the driver must still do:

- Ship the pragma rows as **typed records**, because they are facts
  about SQLite and not about any mapping: `ColumnInfo` (from
  `table_xinfo` — `cid, name, type, notnull, dflt_value, pk, hidden`),
  `ForeignKeyInfo`, `IndexInfo` (from `index_list`:
  seq/name/unique/origin `c|u|pk`/partial), `TableInfo` (from
  `table_list`, 3.37.0+: `schema, name, type, ncol, wr, strict`).
- Pass the **schema argument**. `PRAGMA table_info` resolves across
  attached databases implicitly; SQLAlchemy carries a bug for exactly
  this. Always `pragma_table_info(?, ?)` with the schema pinned.
- Keep the **cache out**. GRDB's cache needs manual invalidation
  because SQLite gives no notification; that is a policy, and a policy
  belongs above the seam. `PRAGMA schema_version` (header offset 40,
  auto-incremented on schema change) is the cheap invalidation token
  the ORM will key on — expose it, do not use it.
- Say plainly that `dflt_value` is **SQL text, not a value**.
  SQLAlchemy keeps it as text. An ORM that wants the value evaluates
  it with `SELECT <expr>`.

`table_xinfo`, not `table_info`: the latter hides generated and hidden
columns, and a migration diff that cannot see a generated column will
try to add it.

### 1.2 sqlite3_column_database_name / table_name / origin_name

Needs `SQLITE_ENABLE_COLUMN_METADATA`, **off by default** and absent
from macOS's system build. Returns NULL when the result column is an
expression or subquery rather than a table column.

**What an ORM does with it — four things, in descending order of
value:**

1. **Join hydration.** `SELECT * FROM users JOIN posts ON …` yields
   two columns named `id`. The name alone cannot say which entity owns
   which slot. `(database, table, origin)` per result column gives the
   ORM a key it can split the flat row on, so eager loading works
   without the ORM having to rewrite the user's SQL with generated
   aliases. Every ORM that does not have this metadata solves the same
   problem by *rewriting the SQL* — which is why Drizzle, Kysely and
   SQLAlchemy all emit `users_id`, `posts_id` prefixed aliases.
2. **Nullability inference for raw SQL.** sqlx's own note: inference
   on SQLite "depends primarily on observing NOT NULL constraints on
   columns". Origin gives `(table, column)`;
   `sqlite3_table_column_metadata` turns that into the NOT NULL bit.
   That pair is the entire mechanism by which a raw SELECT gets an
   Avra row type with correct `T` vs `T?` — see §4.
3. **Writable result sets / identity.** A column with an origin came
   from a real row, so the ORM may register it in an identity map and
   later issue an `UPDATE … WHERE pk = ?`. A column without one is a
   computed value and must be read-only. Without the family, an ORM
   must assume every projection is read-only or trust the user.
4. **Tooling parity.** JDBC's `ResultSetMetaData.getTableName()` /
   `getSchemaName()` are defined against it; better-sqlite3's
   `statement.columns()` returns `{name, column, table, database,
   type}` verbatim. A first-class driver exposes the family; a
   second-class one does not.

**The lifetime rule is load-bearing for Avra.** The returned string is
"valid until the prepared statement is destroyed … or until the
statement is automatically reprepared by the first call to
sqlite3_step() … or until the same information is requested again in a
different encoding". A `const char*` from SQLite is **not a headered
box**, so it can never become an Avra `string` by aliasing —
CLAUDE.md:188 (EVERY POINTER AVRA HOLDS CARRIES A HEADER). The driver
copies it into a headered allocation at describe time and never holds
the borrow across a step. This is the same law that forced
`str_static` and `str_owned` on @std/process.

### 1.3 Prepared-statement caching keyed by SQL text

**Who demands it.** sqlx caches prepared statements per connection —
"it only needs to be parsed once in the connection's lifetime, and any
generated query plans can be retained" — with a configurable capacity
where 0 disables. Every serious driver does this because on SQLite the
parse and plan are a large fraction of a small query's cost.

**What the driver must get right:**

- **Key on SQL text, scoped to the connection.** A `sqlite3_stmt`
  belongs to one `sqlite3*`; sharing one across connections is a
  use-after-free waiting for a pool.
- **`sqlite3_prepare_v3` with `SQLITE_PREPARE_PERSISTENT`** for cached
  statements — the flag exists precisely to tell SQLite the statement
  will be retained, changing its allocation strategy.
- **Reset and clear before reuse.** A statement left un-reset holds a
  read transaction open. `sqlite3_reset` + `sqlite3_clear_bindings` is
  the reuse ritual; skipping `clear_bindings` leaves a stale value in
  a slot the next caller does not bind, which SQLite will silently
  use.
- **The cache OWNS the statements**, and eviction finalizes. Under
  Avra that is a `Map<string, Stmt>` whose values carry a drop — which
  is B3 (opaque types), not an afterthought.
- **Schema change needs no invalidation for the statement, and full
  invalidation for the describe.** `prepare_v2`/`v3` auto-recompile on
  schema change instead of returning `SQLITE_SCHEMA`. But the column
  metadata cached beside a statement goes stale at exactly that
  reprepare (§1.2's lifetime rule says so). Key the describe on
  `PRAGMA schema_version`; do not key the statement on anything.

### 1.4 Parameter binding by index AND by name

SQLite's five forms: `?`, `?NNN`, `:AAA`, `@AAA`, `$AAA`. A bare `?`
and a bare named parameter each take "a number one greater than the
largest already assigned"; `?NNN` pins its own.

**Who demands which.** A query BUILDER wants positional —
deterministic, no collision, no user-chosen names (Kysely, Drizzle,
Diesel, jOOQ all compile to positional). A RAW-SQL escape hatch wants
named — the user typed `:user_id` and expects to bind by that name
(GRDB's `StatementArguments` accepts both an array and a dictionary;
SQLAlchemy Core compiles to named binds). An ORM with both a builder
and an escape hatch needs both. **Ship both.**

**Three obligations beyond the obvious:**

- **1-based.** `sqlite3_bind_*` indices start at 1;
  `sqlite3_column_*` indices start at 0. This off-by-one is the most
  common SQLite binding bug in the field. The Avra surface should
  refuse to inherit it: bind by a 0-based Avra index and add one
  inside, or bind a whole `List` of values in one verb so no index is
  ever typed.
- **Refuse an under-filled statement.** An unbound parameter is NULL,
  silently. That is a wrong answer, not an error, and P9 (boundaries
  are contracts) says the driver must not let it through. Compare
  `sqlite3_bind_parameter_count` against what was bound and refuse.
- **Expose the limit.** `SQLITE_MAX_VARIABLE_NUMBER` defaults to
  **32766 since 3.32.0 and 999 before**, and a connection may lower it
  via `sqlite3_limit`. An ORM that generates `IN (?, ?, …)` from a
  list MUST chunk at `floor(limit / cols)`. Every ORM that hard-codes
  999 has an open issue about it. Expose
  `sqlite3_limit(SQLITE_LIMIT_VARIABLE_NUMBER, -1)` as a read.

### 1.5 RETURNING

SQLite 3.35.0. Diesel gates it behind
`returning_clauses_for_sqlite_3_35`; SeaORM behind
`sqlite-use-returning-for-3_35`. Both feature flags exist because the
ORM's write path is *structurally* different with and without it: with
RETURNING an insert is one round trip that hands back the persisted
row (server defaults, generated columns, trigger-applied values);
without it the ORM must INSERT, read `last_insert_rowid()`, then
SELECT — three statements and a race if another connection writes
between them.

**The caveats the driver must publish, because they change the ORM's
algorithm:**

- "The rows emitted by the RETURNING clause appear in an **arbitrary
  order**." A multi-row `INSERT … RETURNING` therefore CANNOT be
  zipped positionally against the input list. The ORM must match by
  primary key, which means RETURNING must include the PK.
- Top-level DELETE/INSERT/UPDATE only; not usable as a subquery; not
  available on DELETE/UPDATE against virtual tables; no top-level
  aggregates or window functions; may only reference the table being
  modified.
- The values are "as seen by the top-level statement" and do not
  reflect subsequent trigger changes.

**The driver-shape consequence, and it is the important one.** A DML
statement with RETURNING **yields rows**. If the driver splits its API
into `exec` (no rows) and `query` (rows) *by the verb the SQL starts
with*, RETURNING breaks it and the ORM must special-case. The correct
seam: ONE step that may yield a row, and `sqlite3_column_count(stmt) >
0` is the decider — a prepare-time property, safe before any step.
Note that this is a DIFFERENT question from read/write:
`sqlite3_stmt_readonly` is false for `INSERT … RETURNING`, and it is
true for `BEGIN` but false for `BEGIN IMMEDIATE`.

### 1.6 last_insert_rowid and changes()

SeaORM's `InsertResult` carries `rows_affected` and `last_insert_id`.
Diesel notes SQLite exposes `last_insert_rowid` but does not re-export
it. It is the identity fallback when RETURNING is unavailable.

**The caveats, all of which have bitten a shipped ORM:**

- `sqlite3_changes` counts "rows modified, inserted or deleted by the
  most recently completed INSERT, UPDATE or DELETE" and **does not
  count** changes from triggers, foreign key actions, or REPLACE
  constraint resolution; nor rows from `CREATE TABLE AS SELECT`; nor
  changes to a view intercepted by an INSTEAD OF trigger. So a
  cascading delete reports the parent count, not the total.
- It is **per connection**, and inside a trigger the value is saved and
  restored around the trigger body.
- `last_insert_rowid` is meaningless for a WITHOUT ROWID table and for
  a table whose primary key is not an INTEGER alias for the rowid.
  SeaORM issue #2151 lives here.
- Use `sqlite3_changes64` / `sqlite3_total_changes64`. Avra's `int` is
  64-bit; the narrow variants buy nothing.

Publish the caveats at the call site. CLAUDE.md's diagnostic law wants
help text where a boundary is a contract; this is where.

### 1.7 Batch / multi-row insert

**The field's evidence.** Diesel: "On backends that support the
DEFAULT keyword (all backends except SQLite), the data will be
inserted in a single query. On SQLite, one query will be performed per
row" — unless you set `treat_none_as_default_value = false`, which
"enables … real batch inserts with the SQLite backend". So an ORM's
bulk path is **conditional on the driver making a wide multi-row
VALUES cheap**, and the condition is about `DEFAULT`, not about
SQLite's ability to take many rows.

**What the driver owes:**

- The parameter limit (§1.4) so the ORM can chunk to `floor(32766 /
  cols)` rows per statement.
- Cheap statement reuse: bind / step / reset in a loop over ONE
  prepared statement. This is the classic fast path and it needs the
  reset ritual to be a single verb.
- Transaction control, because on SQLite wrapping N inserts in one
  transaction is a larger constant than statement reuse — one fsync
  instead of N.
- Nothing for UPSERT: `INSERT … ON CONFLICT DO UPDATE` (3.24.0) is
  plain SQL. Document it; do not build it.

### 1.8 Savepoints for nested transactions

**Who demands it.** Kysely "doesn't support true nested transactions,
but you can use savepoints", and exposes a `ControlledTransaction`
with savepoint / rollbackToSavepoint. SQLAlchemy's `begin_nested()` is
a SAVEPOINT. GRDB has `inSavepoint`. Ecto nests by savepoint. The
second, quieter demand: **every ORM's test helper** runs each test
case inside a transaction it rolls back, which requires the test's own
transactions to be savepoints.

**SQLite's semantics the driver must state:**

- An outermost SAVEPOINT outside a `BEGIN…COMMIT` "is the same as
  BEGIN DEFERRED TRANSACTION".
- RELEASE removes savepoints "back to and including the most recent
  savepoint with a matching name" — it is a commit *of the savepoint
  only*: "an inner transaction might commit (using the RELEASE
  command) but then later have its work undone by a ROLLBACK in an
  outer transaction".
- `ROLLBACK TO` reverts but leaves the transaction open.

**The security seam, and it is real.** A savepoint name is an
IDENTIFIER, not a bindable parameter — `SAVEPOINT ?` does not exist.
So the name is concatenated into SQL, and a caller-supplied name is an
injection. **The driver mints the name itself** (a per-connection
counter, `sp_<n>`) and refuses any caller-supplied name that is not
`[A-Za-z_][A-Za-z0-9_]*`. This is CLAUDE.md's "A COMMAND IS AN ARGV,
never a shell line" law one level down: **an identifier is not a
parameter, so the driver mints it.**

Also expose `sqlite3_get_autocommit` so the ORM can answer "am I in a
transaction" truthfully rather than by tracking.

### 1.9 A hook for query logging and tracing

**Who demands it.** Ecto's Repo emits telemetry with timing for every
query; SQLAlchemy has `echo=` and `before_cursor_execute`; Kysely has
a `log` option on the `QueryExecutor`; Prisma emits query events.
Nobody ships an ORM without it.

**SQLite's affordance.** `sqlite3_trace_v2(D, M, X, P)` registers one
callback under a mask of `SQLITE_TRACE_STMT` / `PROFILE` / `ROW` /
`CLOSE`; PROFILE carries nanoseconds. Beside it:
`sqlite3_expanded_sql` (the SQL with parameter values substituted) and
`sqlite3_normalized_sql` (needs `SQLITE_ENABLE_NORMALIZE`, off by
default) for grouping distinct SQL into one shape.

**Two rules:**

1. **`expanded_sql` inlines the VALUES.** A logger that prints it
   leaks credentials, tokens and PII into a log file. The driver
   exposes raw SQL and expanded SQL as SEPARATE verbs, and the default
   log projection is raw SQL plus a parameter COUNT — never the
   values. This mirrors spec 22.2's automatic exclusion of `Secret<T>`
   from every public projection: the same instinct, at the driver.
2. **The v1 seam is in Avra, not in C.** `sqlite3_trace_v2` takes a C
   callback with a `void*`, so it needs spec 15.3's compiler-generated
   trampolines, which do not exist (B9). But the driver is the ONLY
   path to the database, so the driver can time its own step loop and
   offer the hook as an **Avra fn field on the connection's context** —
   DOGFOODING.md:1129 (Capability contexts: data + driver-wired fns).
   That covers every statement the ORM issues. `trace_v2` becomes
   necessary only for statements the driver did not issue, of which
   there are none. MEDIUM confidence that this is sufficient for v1;
   HIGH that it is sufficient for logging specifically.

The callbacks that genuinely need trampolines and cannot be faked:
`update_hook` / `commit_hook` / `rollback_hook` (the ORM's cache
invalidation and reactive-query layer — GRDB's ValueObservation is
built on them), `create_function_v2` and `create_collation_v2` (custom
SQL functions, locale-aware ORDER BY), `set_authorizer` (refusing DDL
inside user-supplied SQL), `progress_handler` and `busy_handler`.

### 1.10 Introspection of parameter and column counts and declared types

The describe surface, and the single most important verb in the driver
for §4:

| C call | When valid | Answers |
|---|---|---|
| `sqlite3_bind_parameter_count` | after prepare | how many slots |
| `sqlite3_bind_parameter_name(i)` | after prepare | `:name`, or NULL for a bare `?` |
| `sqlite3_bind_parameter_index(name)` | after prepare | the slot for a name |
| `sqlite3_column_count` | after prepare | how many result columns |
| `sqlite3_column_name(i)` | after prepare | the name or alias |
| `sqlite3_column_decltype(i)` | after prepare | the DECLARED type text, NULL for an expression |
| `sqlite3_column_database_name/table_name/origin_name(i)` | after prepare | the origin triple (§1.2) |
| `sqlite3_stmt_readonly` | after prepare | makes no direct change |
| `sqlite3_data_count` | after step | 0 before the first step and after DONE |
| `sqlite3_column_type(i)` | after a row step | the STORAGE CLASS of THIS value |

**The hard ceiling, and the ORM must be designed around it.** sqlx's
own documentation: "SQLite can only tell us the number of parameters",
where PostgreSQL gives full type information. **SQLite will not tell
you a parameter's type.** So a compile-time checker can verify column
names, column count, and result types — and for parameters it can
verify only arity. Type-checking a parameter requires inferring it
from its syntactic position (`WHERE email = ?` against a known column),
which is the ORM's job and not the driver's. State this ceiling in the
driver's docs so the ORM is not designed as if it were absent.

**`decltype` is text, not a type.** It answers `VARCHAR(255)`
verbatim, and NULL for any expression. SQLAlchemy's dialect keeps a
lookup map and falls back to "the SQLite type affinity scheme when a
particular type name is not located". The affinity rules are a
five-rule string algorithm over the declared text; they belong ABOVE
the seam, in the ORM. The driver hands back the text.

**`column_type` is per row, per value.** SQLite is dynamically typed
per value: a column declared INTEGER may hold TEXT. An ORM MUST handle
that, which means the driver's row API must expose the ACTUAL storage
class of each value, not only a coerced read. STRICT tables (3.37.0)
are the escape hatch and `PRAGMA table_list` reports the `strict` flag
per table — expose it, so the ORM can relax its defensive reads on a
strict table.

**The verb.** `describe(conn, sql) -> Result<StmtInfo, SqlError>`:
prepare, read everything above, finalize. **Never step.** Preparing a
DDL statement does not execute it; preparing a DML statement does not
execute it. That property is what makes describe safe to run at
compile time (§4).

### 1.11 Streaming large result sets without materialising

**Who demands it.** SeaORM: "use async stream … for reducing memory
allocation to improve efficiency", with the warning that "the stream
object will exclusively hold onto the connection until dropped".
Kysely's `DatabaseConnection.streamQuery(compiledQuery, chunkSize)`.
SQLAlchemy's `yield_per`.

**SQLite's model is already streaming.** `sqlite3_step` yields one row
per call with no buffer. Materialising is what a *bad* driver adds.
The driver's job is to not add it, and to name the hazard.

**The hazard.** An open statement holds a read transaction on its
connection. A second query on the same connection while a stream is
open sees the older snapshot or contends on a write. Every ORM in the
survey documents this; SeaORM's "exclusively hold onto the connection"
is the same fact wearing an async coat.

**The Avra shape, and it collides with an idiom.** Avra has no
lifetimes, only refcounts and drop. The honest streaming form is a
**fold with the statement borrowed for the duration**:

```
conn.each(sql, args, (row) -> { … })      // streams; statement held
conn.all(sql, args)                        // materialises a List
```

The comprehension is Avra's beautiful form (DOGFOODING.md:546, "List
comprehensions for filter/map") and it is the MATERIALISING one — a
comprehension needs a `List` to iterate. So the two verbs must be
named so the cost is visible (P7): `all` materialises and says so,
`each` streams. A cursor value with its own drop is the escape hatch
(P8) for the caller who needs to interleave.

**Incremental BLOB I/O is the other half.** `sqlite3_blob_open(db,
zDb, zTable, zColumn, iRow, flags, ppBlob)` plus `blob_read` /
`blob_write` / `blob_bytes` / `blob_reopen` / `blob_close` streams one
BLOB without loading it. Restrictions: **the size may not be changed**
through the handle (use UPDATE), and the handle **expires** with
`SQLITE_ABORT` if the row is modified. This is what an ORM's
large-object field needs and what a `Bytes` value alone cannot give.

### 1.12 The rest of the surface, named

- **Errors.** `sqlite3_errmsg`, `sqlite3_errcode`,
  **`sqlite3_extended_errcode`**, `sqlite3_errstr`,
  **`sqlite3_error_offset`**. The extended code is what separates
  `SQLITE_CONSTRAINT_UNIQUE` from `SQLITE_CONSTRAINT_FOREIGNKEY` —
  without it an ORM cannot turn a constraint failure into "email
  already taken" versus "no such author", and every ORM that lacks it
  does a REGEX over the message. CLAUDE.md forbids string-matching to
  detect behavior: the extended code is the discriminator, and a parse
  of the message ("UNIQUE constraint failed: users.email") only fills
  the payload. `sqlite3_error_offset` "returns the byte offset of the
  start of that token", −1 when none — see §4.
- **Connection config.** `sqlite3_open_v2` flags (READONLY / READWRITE
  / CREATE / FULLMUTEX / NOMUTEX / URI / MEMORY / EXRESCODE),
  `sqlite3_busy_timeout`, `PRAGMA journal_mode=WAL`, `PRAGMA
  synchronous`, `PRAGMA foreign_keys`. Every ORM's connection setup
  sets these; a driver that hides them is unusable in production.
- **`sqlite3_interrupt`** — cancellation for a request timeout.
- **`sqlite3_serialize` / `sqlite3_deserialize`** — on by default since
  3.36.0. Build the schema once, serialize the image, deserialize a
  fresh copy per test case in microseconds. Under this tree's
  test-driven doctrine (a `spec`/`given`/`then` file beside every
  module) this is the fixture story, and it is far better than the
  field's `:memory:`-plus-rerun-the-DDL.
- **Session extension** — `SQLITE_ENABLE_SESSION` **plus**
  `SQLITE_ENABLE_PREUPDATE_HOOK`, both off by default, both in the
  amalgamation since 3.13.0. Changesets are the ORM's audit-log, sync
  and offline-first story.
- **`PRAGMA optimize`** — run at connection close; it sets its own
  temporary analysis limit so no `analysis_limit` tuning is needed.
- **`PRAGMA data_version`** — "the integer values returned by two
  invocations … from the same connection will be different if changes
  were committed to the database by any other connection in the
  interim". A poll-based stand-in for `update_hook` while trampolines
  are missing (B9). MEDIUM: it detects *that* something changed, never
  *what*.
- **Backup API** — `sqlite3_backup_init/step/finish`.
- **DECLINE `SQLITE_ENABLE_STMT_SCANSTATUS`**: the compile-options doc
  says it imposes a runtime cost "even when unused".

---

## 2. THE ARCHITECTURAL LESSON — Ecto and SQLAlchemy Core

### 2.1 What the two best designs actually say

**Ecto splits four ways, and the docs name each in four words:**

| Module | Ecto's own words |
|---|---|
| `Ecto.Repo` | "where the data is" |
| `Ecto.Schema` | "what the data is" |
| `Ecto.Query` | "how to read the data" |
| `Ecto.Changeset` | "how to change the data" |

And the load-bearing sentence: **"You do not need to define schemas in
order to interact with repositories."** Queries "can also be made
directly against a table by giving the table name as a string. In such
cases, the data to be fetched must be explicitly outlined." Beneath
all four, an escape hatch at full power: "most adapters provide direct
APIs for queries, like `Ecto.Adapters.SQL.query/4`, allowing developers
to completely bypass Ecto queries."

**SQLAlchemy splits two ways and says the split out loud:** "The ORM
layer is an optional component built on the Core." Core "presents a
system of representing the primitive constructs of the relational
database directly **without opinion**, which is in contrast to ORM
that presents a high level and abstracted pattern of usage." What the
ORM adds is one thing: the unit of work, which "translates changes in
state against mutable objects into INSERT, UPDATE and DELETE
constructs". Core has "no sessions, no identity map, no dirty
tracking".

### 2.2 The lesson, as a law

> **The query layer is a function of SQL and rows. The mapping layer
> is a function of TYPES and IDENTITY. They must not share a value.**

Four reasons it earns its keep, each observable rather than
theoretical:

1. **The mapping layer is contested; the query layer is not.** Every
   language has ONE reasonable "run this SQL, get these rows" shape
   and five reasonable mapping shapes: active record (Rails, SeaORM's
   ActiveModel), data mapper (Doctrine, SQLAlchemy ORM), changeset
   (Ecto), unit of work (Hibernate), codegen (sqlc, jOOQ). The spec
   makes exactly this argument one layer up, for `model` being a
   provider rather than a keyword: "the model concept is rich and
   contested — there's no single 'right' answer about identity
   semantics … migration strategy … relation representation" (spec
   22.1). The same reasoning at the driver says: `@std/sqlite` may be
   first-party and singular precisely BECAUSE it is not the contested
   part.
2. **Most real queries are not entity-shaped.** Reports, aggregates,
   `count(*)`, `GROUP BY`, window functions. Ecto answers with
   schemaless queries and an explicit `select:` map; SQLAlchemy
   answers with Core. An ORM whose only exit is "hydrate an entity"
   forces users to declare fake entities for report rows — which is
   how every ORM in the field acquires its `@Query(nativeQuery=true)`
   wart. P8: the escape hatch must be at the same power as the main
   road.
3. **Migrations run before any mapping is true.** At migration time
   the mapped types deliberately do NOT match the database — that is
   what a migration is. Ecto's migrations use DDL and
   `Ecto.Adapters.SQL.query`, never schemas. If the driver sits
   beneath the mapping layer, the runner uses the driver directly and
   the circularity disappears. If it does not, the ORM has to boot
   twice.
4. **Testability.** A driver with no ORM inside it is tested against
   SQL and rows alone — real files, real statements, `given`/`then`.
   An ORM tested through a driver mock tests the mock.

### 2.3 The line, drawn

**BELOW the line — `@std/sqlite`, the substrate:**

- connection: open/close, flags, `busy_timeout`, pragma read/write
- statement: prepare / bind / step / reset / clear / finalize; the
  per-connection statement cache
- values: `int`, `float`, `string`, `bytes`, null — written and read,
  with the STORAGE CLASS readable per value
- describe: parameter count and names; column count, names, decltypes,
  and the `(database, table, origin)` triple
- transactions: BEGIN / COMMIT / ROLLBACK; SAVEPOINT / RELEASE /
  ROLLBACK TO with **driver-minted names**; `get_autocommit`
- `last_insert_rowid`, `changes64`, `total_changes64`
- errors: code, extended code, message, **byte offset** — as a typed
  Avra error
- reflection RECORDS from the pragma table-valued functions
- hooks: trace/profile; update/commit/rollback, authorizer, progress,
  busy, custom functions and collations (when trampolines land)
- blob streaming; serialize/deserialize; backup
- **NOT**: SQL generation. **NOT**: a query builder. **NOT**: a schema
  model. **NOT**: type mapping beyond the five storage classes.
  **NOT**: identity, change tracking, or relations.

**ABOVE the line — the ORM:**

- the schema model (tables, columns, relations, refinements) and its
  derivation from `model` / `@derive Model` (spec 22.1, 22.2)
- SQL generation and the query AST / builder
- type mapping: Avra type ↔ storage class + affinity, including
  `decimal`, `Timestamp`, enums, JSON
- identity map, change tracking, unit of work, association loading
- migrations: the diff, the ordering, the 12-step rewrite, the safety
  classification (spec 22.3)
- validation / changesets
- the further projections: REST, OpenAPI, admin UI, MCP tool
  descriptions (spec 22.2)

**ON the line — three genuinely ambiguous items, decided here:**

- **Reflection.** It is a query, so it *could* live above. **DECIDE:
  below.** The driver ships the raw pragma rows as typed records
  because they are facts about SQLite, not about any mapping — this is
  what GRDB does (`ForeignKeyInfo`, `IndexInfo`). The schema CACHE and
  its invalidation policy live above; GRDB's cache needs manual
  clearing, which proves it is a policy.
- **The statement cache.** **DECIDE: below.** Its correctness depends
  on reset/clear discipline the ORM cannot see, and its lifetime is
  the connection's. sqlx puts it in the driver. Expose capacity and
  `clear()`.
- **`IN (…)` chunking.** **DECIDE: above** — it is SQL generation. But
  the driver must expose the LIMIT, or every ORM hard-codes 999.

**The Avra-specific consequence.** CLAUDE.md's layering law is one-way
and features never import features. Applied here: the ORM package
imports `@std/sqlite`, and `@std/sqlite` never learns the ORM exists.
Therefore the driver must be **complete enough to be an endpoint on
its own** — a person writing plain SQL against it should never need
the ORM. That is the test of whether the line was drawn in the right
place.

---

## 3. MIGRATIONS

### 3.1 Transactional DDL — the unusual, valuable thing

SQLite can roll back `CREATE`, `ALTER` and `DROP`. MySQL cannot;
Oracle cannot. So on SQLite a migration is genuinely
**all-or-nothing**: a failed step leaves the file untouched. Every
runner that supports SQLite exploits it, and Ecto/Alembic expose
`--no-transaction` as the opt-out rather than the default.

**Put the version bump inside the same transaction as the DDL.** That
is the entire crash-safety story, and SQLite gives it free. A runner
that bumps `user_version` after COMMIT has a window.

**The trap the field misses.** `PRAGMA foreign_keys` is **"a no-op
within a transaction; foreign key constraint enforcement may only be
enabled or disabled when there is no pending BEGIN or SAVEPOINT"**.
SQLite's own 12-step procedure therefore orders it: step 1 is `PRAGMA
foreign_keys=OFF`, step 2 is *then* start the transaction, and step 12
re-enables **after** the commit. A runner that wraps the whole
procedure in a transaction silently keeps enforcement ON and the table
rewrite fails at step 6.

**The better shape, and it is a paradox collapse.** `PRAGMA
defer_foreign_keys` **can** be changed inside a transaction, and it
"delays enforcement of all foreign key constraints until the outermost
transaction is committed". So the runner gets FK checking AND the
table rewrite inside one transaction — both sides win (P6). Caveat the
driver must publish: "the defer_foreign_keys pragma is automatically
switched off at each COMMIT or ROLLBACK. Hence, the defer_foreign_keys
pragma must be separately enabled for each transaction."

### 3.2 The version counter

- **`PRAGMA user_version`** — "the user-version integer at offset 60
  in the database header", free for the application. A 32-bit signed
  integer in the header: no table, no row, a page-0 read. This is the
  canonical SQLite migration counter (GRDB's DatabaseMigrator,
  Android's SQLiteOpenHelper).
- **A `schema_migrations` table** — what Ecto, Rails and Alembic use,
  because `user_version` cannot express "migration 7 was skipped", or
  record *when* each ran, or carry a name.
- **`PRAGMA application_id`** — a 32-bit magic identifying the file's
  application. A runner that sets it can refuse to migrate the wrong
  database, and `file(1)` can name it. Cheap; almost nobody does it.
- **`PRAGMA schema_version`** — header offset 40, auto-incremented on
  every schema change. The runner uses it to detect concurrent schema
  change and to invalidate a describe cache.

All four are pragmas, so they cost the driver nothing beyond `query`.
The driver must expose them and **take no position** on which the ORM
uses.

### 3.3 The 12-step ALTER TABLE

Direct `ALTER TABLE` does only four things, each restricted:

- **RENAME TO** — same database only; triggers and indices follow.
- **RENAME COLUMN** — updates the table, indexes, triggers and views;
  fails on semantic ambiguity.
- **ADD COLUMN** — no PRIMARY KEY or UNIQUE; no `CURRENT_TIME/DATE/
  TIMESTAMP` default; `NOT NULL` requires a non-NULL default; no
  generated STORED (VIRTUAL is allowed); an FK column needs a NULL
  default if constraints are on.
- **DROP COLUMN** — fails if the column is a PK, is UNIQUE, is
  indexed, appears in a partial index WHERE, is used in a CHECK, an FK
  or a generated-column expression, or is referenced in a trigger or
  view.

Everything else — change a type, add NOT NULL to an existing column,
add or drop a constraint, reorder — takes the documented 12 steps:
foreign_keys off; BEGIN; `SELECT type, sql FROM sqlite_schema WHERE
tbl_name='X'`; CREATE the new table; `INSERT INTO new_X SELECT … FROM
X`; DROP X; RENAME new_X to X; recreate indexes/triggers/views;
recreate affected views; `PRAGMA foreign_key_check`; COMMIT; re-enable
foreign_keys.

**What the runner needs from the driver — and the answer is: nothing
new.**

- `sqlite_schema` is a normal table; reading it needs `query`.
- Steps 4–8 are `execute(sql)` in a transaction.
- `PRAGMA foreign_key_check` returns `(table, rowid, parent, fkid)`
  rows, so the runner can REPORT which rows broke rather than "it
  failed". Expose it as a reflection record; it is the difference
  between a usable migration tool and an unusable one.
- `PRAGMA integrity_check` for post-migration verification.
- `PRAGMA legacy_alter_table` when the runner wants pre-3.25 RENAME
  behavior (references not rewritten) because it is about to recreate
  every dependent object anyway. MEDIUM: this is what batch-mode
  runners do; the pragma exists for it and the docs describe the
  behavior, but the practice is inferred.
- `PRAGMA writable_schema` (3.38.0+) — with it, "ALTER TABLE silently
  ignores any rows of the sqlite_schema table that do not parse". The
  escape hatch for an unparseable schema. Expose it; the runner
  refuses it by default.

**The conclusion, and it is the one that shapes the campaign:** the
12-step procedure is entirely a sequence of `execute` calls plus two
pragma reads. It is an **ORM-layer algorithm over driver-layer
primitives**. Do not build it into the driver. Build it once, in the
migration runner, and prove it with a corpus program.

### 3.4 What the runner must NOT ask of the driver

Schema diffing (needs the model), migration ordering (needs the file
system — `@std/io`), SQL generation, and the safety classification
(safe / caution / dangerous — spec 22.3). All ORM.

---

## 4. THE AVRA ANGLE — what this ORM can be that others cannot

### 4.1 The state of the art, and why all four are out-of-band

| Tool | How it checks SQL | What it costs |
|---|---|---|
| sqlx | connects to a LIVE database at build time (`DATABASE_URL`) or reads a checked-in `.sqlx` cache | a database, or a cache to keep in sync |
| sqlc | "reads your SQL database schema, validates your queries against it, and then produces type-safe Go code" — a hand-written SQL parser and type checker in pure Go | a separate binary, a codegen step, a generated artifact in the repo |
| jOOQ | reverse-engineers a live schema into Java classes | a codegen step, usually a database |
| Prisma / Drizzle / Kysely | the schema is re-declared in TypeScript types | the developer keeps the TS schema and the database in sync |

All four are **out-of-band**: a separate tool, a separate artifact, a
separate sync problem. Avra's compiler can be in-band, because the
compiler already holds the schema as a semantic value and already
memoizes derivations over it (ROADMAP.md:3 — "the compiler is not a
pipeline, it is a DATABASE").

### 4.2 Three rungs

**RUNG 1 — the schema is a declaration the compiler already knows.**

Spec 22.1's `model` keyword is provider-supplied, and spec 22.2
already lists "database schema" and "migrations" among the projections
generated by default. `@derive Model` is "a lifted function that runs
at compile time and returns declarations" — not compiler magic. It
produces the DDL text, the row struct, the column tokens, and a
**schema VALUE in the compiler's store, keyed by the declaration**.
Nothing new is asked of the language for this rung; it is the derive
framework doing what the spec already says it does.

**RUNG 2 — a query is checked against that schema, at compile time.**

Two engines, and both should exist (P6 — the choice is false):

- **(a) Check in Avra, no SQLite.** A lifted fn over the schema value
  and a query BUILDER's terms: does the table exist, does the column
  exist, does the Avra binding's type match the column's. This catches
  the overwhelming majority — a typo'd column name — with no FFI at
  compile time and no `@comptime`. It is the **v1 rung**, and it is
  why the FIRST surface should be a **builder, not a string**: a
  builder's terms are Avra expressions, so the compiler types them
  with machinery it already has, and no SQL parser is needed anywhere.
- **(b) Ask SQLite itself.** At compile time, open `:memory:`, run the
  derived DDL, `sqlite3_prepare_v3` the query, read the describe
  (§1.10), finalize — **never step**. That is a complete SQL parser
  and type-affinity engine for free, and it is *the same engine that
  will run the query in production*, which is a guarantee sqlc's
  hand-written Go parser structurally cannot make. This is the escape
  hatch's checker: raw `sql"…"` text.

**The thing nobody else has.** On a syntax or name error,
`sqlite3_error_offset` "returns the byte offset of the start of that
token". A byte offset into the SQL string maps to a SPAN inside the
string literal in the user's `.av` file. So the diagnostic
**underlines the exact word in the SQL**, in the source, with an
F-code, a help line and a structured fix — the tree's diagnostic
contract applied to a foreign language embedded in an Avra literal.
sqlx reports the error; it does not point at the character. This costs
one C call and one nullable int field on the driver's error type, and
it is the single highest-leverage thing in this document.

**RUNG 3 — the describe IS the type; no entity declaration needed.**

`sqlite3_column_decltype` plus the NOT NULL bit from
`sqlite3_table_column_metadata`, reached through the origin triple, is
exactly the information needed to decide `T` versus `T?` per column.
sqlx says so in the negative: SQLite inference "depends primarily on
observing NOT NULL constraints on columns". Run the describe at
compile time and `sql"SELECT id, name FROM users"` acquires a
**derived row type** — `{ id: int, name: string? }` — with no entity,
no codegen step, no generated file. That is sqlc's promise without
sqlc and Prisma's promise without a schema file.

Rung 3 is where `SQLITE_ENABLE_COLUMN_METADATA` stops being nice and
becomes structural: without the origin triple, nullability can only be
inferred for a single-table SELECT, and every join degrades to `T?`.

### 4.3 What the driver must expose for that to be possible

The actionable list. Everything here is a driver obligation, not an
ORM one.

1. **`describe(conn, sql) -> Result<StmtInfo, SqlError>`** — prepares
   without stepping, finalizes. Side-effect-free by construction
   (preparing DDL does not run it). Callable against a database with
   schema and no data.
2. **`StmtInfo`** carrying `params: { count: int, names: List<string?>
   }` and `columns: List<ColumnInfo>` where `ColumnInfo = { name:
   string, decltype: string?, database: string?, table: string?,
   origin: string? }`. Those last three nullable fields ARE the
   `SQLITE_ENABLE_COLUMN_METADATA` payload.
3. **`SqlError`** carrying `code`, `extended_code`, `message`, and
   **`offset: int?`** from `sqlite3_error_offset` (−1 becomes null).
4. **`table_column_metadata(conn, db, table, column) ->
   Result<ColumnFacts, SqlError>`** — declared type, collation,
   notnull, pk, autoinc. This is the **drift check**: the model says
   `email: string` NOT NULL, the live database says nullable, and CI
   refuses.
5. **The reflection records** (§1.1) — the migration diff runs over
   them.
6. **`:memory:` open plus `serialize`/`deserialize`** — build the
   schema database once, then clone the image per query check. Under a
   memoizing compiler the DDL run memoizes anyway, but a serialized
   image is a **value** the content-addressed store can key on, which
   is a better fit for the north star's L0/L1 than a re-run.
7. **`sqlite3_stmt_readonly`** — so a `@derive`d read-only service
   endpoint refuses a write at COMPILE time.
8. **`sqlite3_limit(SQLITE_LIMIT_VARIABLE_NUMBER)`** — so a
   comprehension expanding to `IN (…)` is refused at compile time when
   the list's length is statically known and too large.

### 4.4 Three further Avra-only shapes

**The diagnostic is the ORM's error surface.** Extended result codes
map to typed Avra errors: `SQLITE_CONSTRAINT_UNIQUE` becomes
`.UniqueViolation(table, columns)`. Every ORM in the field derives
this by REGEX over the message string; CLAUDE.md forbids
string-matching to detect behavior, so here the **extended code is the
discriminator** and a parse of the message only fills the payload.
Correct by construction, and materially better than the field's.

**`table<Row> { … }` backed by SQLite.** The language already has a
typed table literal (DOGFOODING.md:653). Backing it with SQLite means
the same literal is a fixture in a test and a persisted table in a
service, with the compiler knowing the row type on both sides. The
seam is `component` — capability contexts, data plus driver-wired fns
(DOGFOODING.md:1129): a `table` gets a STORE capability wired at
construction, in-memory by default, SQLite when the deploy block says
so. That is P13 (collapse dev/ops/infra) reaching the data layer. What
the driver must expose for it: create-table-from-row-type (needs a
mapping for EVERY scalar — hence B1 and B2 are prerequisites), bulk
insert, and a full scan.

**`avra explain query <site>`.** Spec 22.2 already promises `avra
explain model User` prints every projection. Extend it: print the
generated SQL, the bound parameters and their types, and the `EXPLAIN
QUERY PLAN` output. `EXPLAIN QUERY PLAN` is plain SQL, so the driver
needs nothing new — but a compiler that runs it at build time and
REFUSES a query doing a full scan of an indexed table is a
`@requires`-shaped compile-time check nobody has. Speculative
(LOW–MEDIUM): the refusal needs a policy for when a scan is correct.

---

## 5. RANKED BY HOW BADLY THE ORM IS HURT WITHOUT IT

**Tier 0 — the ORM cannot exist.**

1. Prepare / bind / step / reset / finalize with typed values, and the
   value's STORAGE CLASS readable.
2. `float` in the language. A REAL column has no representation
   without it (B1).
3. `bytes` in the language. A BLOB column has no representation
   without it (B2).
4. Binding by index, with a refusal on an under-filled statement (an
   unbound slot is a silent NULL).
5. Transactions with truthful autocommit state.
6. Typed errors carrying the EXTENDED result code — without it every
   constraint failure is one undifferentiated error.

**Tier 1 — the ORM exists but is crippled.**

7. Statement cache keyed by SQL text, per connection, with the
   reset/clear ritual as one verb.
8. `describe` without stepping — param count and names; column count,
   names, decltypes.
9. `last_insert_rowid` + `changes64` — the identity path when
   RETURNING is unavailable, with the trigger and WITHOUT-ROWID
   caveats published.
10. Savepoints with driver-minted names — nested transactions AND the
    rollback-per-test-case pattern every ORM's test helper uses.
11. Streaming rows without materialising, with the held-statement
    hazard named at the verb.
12. Reflection records (`table_xinfo`, `foreign_key_list`,
    `index_list`, `table_list`) — migrations cannot diff without them.
13. `sqlite3_limit(SQLITE_LIMIT_VARIABLE_NUMBER)` — otherwise every
    generated `IN (…)` is a latent crash at 1000 elements.
14. Binding by NAME — the raw-SQL escape hatch is unusable without it.

**Tier 2 — the ORM is ordinary instead of good.**

15. `column_database_name` / `table_name` / `origin_name` — join
    hydration, writable result sets, nullability inference. **The
    single largest quality delta in this list.**
16. `sqlite3_error_offset` — the compile-time span story (§4.2). One C
    call; nothing else in the driver buys as much.
17. RETURNING, via an API that classifies by `column_count`, never by
    the SQL's leading verb.
18. `sqlite3_table_column_metadata` — the model-vs-database drift
    check.
19. Trace / profile timing, with the expanded-SQL leak guarded.
20. `busy_timeout`, WAL, `synchronous`, `foreign_keys` configuration.
21. `sqlite3_interrupt` — cancellation.
22. `PRAGMA optimize` at close.
23. UPSERT — no driver work; document it.

**Tier 3 — the ORM's distinctive features.**

24. `update` / `commit` / `rollback` hooks — reactive queries and
    cache invalidation. Needs trampolines (B9).
25. Custom functions and collations. Needs trampolines.
26. `serialize` / `deserialize` — instant per-case test fixtures.
27. Incremental BLOB I/O.
28. Session extension (changesets) — audit, sync, offline-first.
29. Authorizer — refusing DDL inside user-supplied SQL.
30. `sqlite3_normalized_sql` — trace grouping. Needs
    `SQLITE_ENABLE_NORMALIZE`.
31. Backup API.
32. `sqlite3_stmt_scanstatus` — **decline**: costs at runtime even
    when unused.

---

## BLOCKERS

Each names what is missing, the evidence in the tree, and a proposed
shape. Ordered by what must land first.

### B1 — NO FLOAT

`core.Type` has `Int`, `Bool`, `Str`, `Ptr` and no float
(packages/std-avrac/src/core/types.av:12–80). A SQLite REAL column has
no representation, and neither does `sqlite3_column_double` /
`sqlite3_bind_double`.

**Shape.** A `Type.Float` variant with its own register class. This is
a CORE event under the IR vocabulary protocol (CLAUDE.md:376) and it
must pay the protocol's consumers: `Bin`/`Un` gain float opcodes (an
add over floats is `fadd`, not `add` — the same instruction cannot
serve both), `RtKind` gains `F64` and `rt_kind_of`
(core/runtime_api.av:96) answers it, the backend's LLVM types, the
interpreter's `Val`, and the value protocol's `float_of`. The memory
pass is untouched: a float is unmanaged. Spec 31.2 pins the semantics —
`float` is f64 at app level, IEEE 754, `NaN != NaN`, no implicit
int↔float conversion, and a float literal must carry a decimal point
or exponent.

### B2 — NO BYTES

The language has no bytes type. Storage is not the problem — the
header carries the length and `.length` is a load, not a `strlen`
(CLAUDE.md:668, which retired I27 with the strlen it ratcheted). The
problem is the SEARCH verbs: `avra_str_contains`, `avra_str_index_of`,
`avra_str_replace`, `avra_str_split`, `avra_str_starts_with`,
`avra_str_ends_with` (core/runtime_api.av:57–65) are C-string-shaped
rows. MEDIUM confidence that they truncate at an embedded NUL — the
campaign brief asserts it and the row shapes are consistent with it;
runtime/avra_runtime.c was not read.

**Shape.** A `Bytes` value category: a headered box with a length and
no encoding claim, a distinct `Type.Bytes`, its own runtime rows
(`avra_bytes_len` / `_slice` / `_concat` / `_eq` / `_index_of`), and a
`bytes_of` projection in core's value protocol (CLAUDE.md's protocol
rule — one projection per value category a feature reads without its
own dispatch). Two refusals to record: **not** a `List<int>` (eight
bytes and a box per byte, and the wrong thing to hand a C API), and
**not** an alias for `string` (`==` over a blob would silently become
a byte-comparison with text semantics, and the type system would stop
distinguishing a TEXT column from a BLOB column).

### B3 — NO OPAQUE TYPES

`ptr` is nameable in source (language/typing.av:322) and `Type.Ptr` is
"an opaque host pointer — what an extern fn passes and answers;
nothing reads through it" (core/types.av:21). But **every `ptr` is the
same type**: a `sqlite3*` and a `sqlite3_stmt*` are interchangeable,
and nothing frees either. @std/process worked around this with INT
handles into a runtime-side table (`avra_proc_spawn` answers an `int`,
packages/std-process/src/process.av:15) — which is exactly the C shim
the campaign forbids.

**Shape.** Spec 15.5 verbatim: `opaque type Sqlite3
@free_with(sqlite3_close_v2)`. A distinct nominal type whose runtime
value is a pointer; `rides_pointer` true; drop calls the `@free_with`
function.

**The hard part, stated.** An opaque handle from C is NOT headered, so
CLAUDE.md:188 does not hold for it — the memory pass must never hand
one to `avra_rc_retain`. Two honest designs:

- (i) a distinct managed-ness class in the type registry
  ("foreign-owned: dropped by name, never counted") — which means no
  sharing and a move story Avra does not have; or
- (ii) an Avra-side **headered box holding the raw pointer**, so
  counting works unchanged and `@free_with` becomes the box's
  destructor at count zero.

**RECOMMEND (ii).** One allocation per handle, and it collapses the
paradox: refcounting stays uniform, the header law stays true
everywhere, sharing a connection across a struct is free, and
`@free_with` is a destructor rather than a new lifetime rule. The cost
is one indirection per call, which is nothing beside a SQLite step.

### B4 — NO OUT-PARAMETERS

`sqlite3_open_v2(path, &db, flags, vfs)` returns an int and writes the
handle through a `sqlite3**`. Avra has no `&x` and no `*mut *T`, and
`extern_row` (core/runtime_api.av:104) mints every extern as borrowed
answers with no owned twin. Every SQLite constructor is out-param
shaped: `open_v2`, `prepare_v3`, `blob_open`, and
`table_column_metadata` with FIVE out-parameters.

**Shape, two rungs.**

- (i) **A DECLARED WRAPPER.** The extern declares
  `@returns_ownership(db)` (spec 15.4) and `@error_if(it != 0, …)`
  (spec 15.7); the compiler generates the call — allocate a cell, pass
  its address, read it back, answer `Result<Sqlite3, SqlError>`. The
  programmer writes `let db = sqlite3_open_v2(path, flags, null)?` and
  never sees the pointer-to-pointer. This is the spec's own answer and
  needs no new value category.
- (ii) For multi-out-parameter calls, the same machinery generalizes to
  a **generated record** of the outputs.

**RECOMMEND (i) for v1**, with (ii) as the natural extension —
`table_column_metadata` is the only caller that needs it, and its
answer is exactly the `ColumnFacts` record §4.3 asks for.

### B5 — THE INTERPRETER CANNOT HOST AN EXTERN

`packages/std-avrac/src/language/interp.av:574` traps: "`${callee}` is
extern — the evaluator cannot host it; build natively", and
`extern_row` gives every extern `RtHost.Unhosted`
(core/runtime_api.av:104). Consequences: `avra run` cannot run one
line of the driver; the driver's `spec`/`given`/`then` files would be
native-only, breaking the tree's eval-==-native guarantee for the
whole package; and **a compile-time call into SQLite (§4.2b) is
impossible**.

**Shape.** The campaign already owns this (dlsym plus a fixed set of
uniform ABI shapes). One note for the design: **the shape set is
determined by the driver's own surface, so measure it rather than
guess it.** Enumerate the actual extern list first. The SQLite API is
overwhelmingly `(int|ptr|cstr) × up to 7 arguments → (int|int64|ptr|
double|void)`; `sqlite3_table_column_metadata` at nine arguments is
the outlier that sets the ceiling.

### B6 — `Result<void, E>` IS REFUSED

CLAUDE.md:574 — F2019, "a `Result` slot cannot hold this yet". Roughly
half a driver's surface is a writing verb with nothing to answer:
`bind_int`, `reset`, `clear_bindings`, `close`, `exec`.

**Shape.** No language change needed if the API is designed for it.
@std/io's rule is "a writing verb answers what it wrote". The driver's
equivalents: `bind` answers the statement (so binds chain), `exec`
answers `changes64()`, `reset` answers the statement, `close` answers
the path. **State this as a design constraint before the first verb is
written**, or the API gets retrofitted into it.

### B7 — NO `decimal`, AND IT IS A LIBRARY TYPE

Money is the ORM's first hard column type. Spec 31.3 puts `BigDecimal`
in `@std/numbers` and `Money` in `@std/money` — explicitly library
types, explicitly not core, explicitly with a visible allocation cost.

**Shape.** `decimal` is built above the language on `Bytes` and `Int`,
which makes **B2 a prerequisite for the money story**. The storage
decision (TEXT zero-padded for lexicographic ordering, or INTEGER
minor units) is the ORM's, not the driver's. The driver's only
obligation is to not make either impossible — which it does not, once
`float` and `bytes` exist. Record this so the campaign does not try to
make `decimal` a core type; spec 31.3 already refused that.

### B8 — THE COMPILE FLAGS ARE A ONE-TIME DECISION

`SQLITE_ENABLE_COLUMN_METADATA` is off by default and absent from
macOS's system build — the campaign's vendoring decision is already
correct. Record the flag set now so it lands once:

- **REQUIRED:** `SQLITE_ENABLE_COLUMN_METADATA` (§1.2, §4.3),
  `SQLITE_THREADSAFE=1` (the default; serialized), **`SQLITE_DQS=0`** —
  refuses double-quoted string literals, killing the classic silent
  typo where `WHERE name = "alice"` compares a column to itself;
  SQLite's own recommendation is 0 and the default is 3 for
  compatibility.
- **REQUIRED for the distinctive tier:** `SQLITE_ENABLE_SESSION`
  **and** `SQLITE_ENABLE_PREUPDATE_HOOK` — both, together; the session
  code checks for both, and the session extension has been in the
  amalgamation since 3.13.0. `SQLITE_ENABLE_NORMALIZE` for trace
  grouping.
- **WANTED:** `SQLITE_ENABLE_FTS5`, `SQLITE_ENABLE_RTREE`,
  `SQLITE_ENABLE_MATH_FUNCTIONS`.
- **ALREADY ON, do not omit:** deserialize (default since 3.36.0),
  JSON (default since 3.38.0).
- **DECLINE:** `SQLITE_ENABLE_STMT_SCANSTATUS` — "imposing runtime
  performance costs even when unused".

### B9 — NO TRAMPOLINES

Spec 15.3 decides compiler-generated trampolines for closures crossing
to the C ABI; nothing in the tree does it. Blocked without them: every
`void*`-carrying callback — `trace_v2`, `update_hook`, `commit_hook`,
`rollback_hook`, `create_function_v2`, `create_collation_v2`,
`set_authorizer`, `progress_handler`, `busy_handler`.

**Not a v1 blocker for the driver's core** — the driver is the only
path to the database, so logging and timing can be an Avra fn field on
the connection context (DOGFOODING.md:1129) rather than a C callback.

**It IS the blocker for the ORM's reactive layer.** Interim shape:
`PRAGMA data_version` as a poll — it changes when another connection
commits — which detects *that* the database changed but never *what*.
Good enough for a cache-invalidation stampede, not good enough for a
live query.

### B10 — TWO SUBSET GAPS THAT WILL BITE THE DRIVER'S OWN CODE

Not language blockers; recorded so the driver's first draft is written
around them rather than into them.

- **A LAMBDA IN A FIELD OR ARGUMENT SEAT does not read the seat's
  answer** (CLAUDE.md:605). The capability-context pattern
  (DOGFOODING.md:1129) wires fn fields at construction, which is
  exactly this seat. A NAMED fn in the seat works everywhere — write
  the driver's context hooks as named fns, not inline lambdas.
- **A `table` literal without its row type is refused**, and `m["k"]`
  on a map is refused (CLAUDE.md:528, 654). The driver's statement
  cache is a `Map<string, Stmt>`; every read is `.get(k)` answering
  `T?`, which is the right shape anyway (a cache miss is absence, not
  an error).

---

## CONFIDENCE LEDGER

| # | Claim | Confidence | How verified |
|---|---|---|---|
| 1 | Ecto splits Repo / Schema / Query / Changeset, and "You do not need to define schemas in order to interact with repositories" | HIGH | https://ecto.hexdocs.pm/Ecto.html (fetched) |
| 2 | Ecto allows `from u in "users"` schemaless queries with explicit select, and `Ecto.Adapters.SQL.query/4` bypasses Ecto queries entirely | HIGH | same |
| 3 | "The ORM layer is an optional component built on the Core"; Core is "without opinion"; the ORM adds the unit of work; Core has no session/identity map/dirty tracking | HIGH | https://docs.sqlalchemy.org/en/20/intro.html and the Core docs (search) |
| 4 | SQLAlchemy's SQLite reflection is built on `PRAGMA table_info()` and `PRAGMA foreign_key_list()`; falls back to type affinity when a decltype is not in its lookup map | HIGH | https://docs.sqlalchemy.org/en/20/dialects/sqlite.html (search) |
| 5 | `sqlite3_column_database_name/table_name/origin_name` need `SQLITE_ENABLE_COLUMN_METADATA`, return NULL for expressions, and the string is valid only until finalize / automatic reprepare / re-request in another encoding | HIGH | https://sqlite.org/c3ref/column_database_name.html (fetched, quoted) |
| 6 | `SQLITE_ENABLE_COLUMN_METADATA` is off by default | HIGH | https://sqlite.org/compile.html (fetched) |
| 7 | better-sqlite3's `statement.columns()` returns `{name, column, table, database, type}` | HIGH | https://github.com/WiseLibs/better-sqlite3/blob/master/docs/api.md (search) |
| 8 | `sqlite3_table_column_metadata` signature and its five out-parameters (declared type, collation, notnull, pk, autoinc) | HIGH | https://sqlite.org/c3ref/table_column_metadata.html (fetched, signature quoted) |
| 9 | That routine also requires `SQLITE_ENABLE_COLUMN_METADATA` | MEDIUM | the compile-options page names the three `column_*_name` functions explicitly and says "some additional APIs"; the table_column_metadata page did not state a requirement in the fetched text. Verify against `sqlite3.h` in the vendored amalgamation before relying on it. |
| 10 | sqlx caches prepared statements per connection, parsed once per connection lifetime, capacity configurable, 0 disables | HIGH | https://docs.rs/sqlx/latest/sqlx/fn.query.html and the SQLite driver docs (search) |
| 11 | sqlx: "SQLite can only tell us the number of parameters"; SQLite inference "depends primarily on observing NOT NULL constraints on columns" | HIGH | sqlx docs (search summary) |
| 12 | `prepare_v2`/`v3` auto-recompile on schema change instead of returning `SQLITE_SCHEMA`; `SQLITE_PREPARE_PERSISTENT` exists | HIGH | https://sqlite.org/c3ref/prepare.html (fetched, quoted) |
| 13 | Parameter forms `?`, `?NNN`, `:AAA`, `@AAA`, `$AAA`; bare and named take "one greater than the largest already assigned" | HIGH | https://sqlite.org/lang_expr.html#varparam (fetched) |
| 14 | `SQLITE_MAX_VARIABLE_NUMBER` defaults to 999 before 3.32.0 and 32766 after | HIGH | https://sqlite.org/limits.html (fetched, quoted) |
| 15 | RETURNING landed in 3.35.0; rows come back in arbitrary order; top-level DML only; no subquery use; not on DELETE/UPDATE against virtual tables; no top-level aggregates or window functions; may only reference the modified table | HIGH | https://sqlite.org/lang_returning.html (fetched, quoted) |
| 16 | Diesel gates SQLite RETURNING behind `returning_clauses_for_sqlite_3_35`; SeaORM behind `sqlite-use-returning-for-3_35` | HIGH | https://diesel.rs/guides/all-about-inserts.html and SeaORM 2.0 notes (search) |
| 17 | Diesel performs one query per row for SQLite batch inserts because SQLite lacks the DEFAULT keyword in multi-row VALUES; `treat_none_as_default_value = false` enables real batch inserts | HIGH | https://diesel.rs/guides/all-about-inserts.html (search, quoted) |
| 18 | `sqlite3_changes` excludes trigger, foreign-key-action and REPLACE-conflict changes, and `CREATE TABLE AS SELECT` rows; is per connection; saved/restored around triggers | HIGH | https://sqlite.org/c3ref/changes.html (fetched, quoted) |
| 19 | SeaORM's `InsertResult` carries `rows_affected` and `last_insert_id`; last_insert_id is broken for some autoincrement shapes (issue #2151) | MEDIUM-HIGH | SeaORM docs and issue #2151 (search summary; the issue was not read directly) |
| 20 | Kysely has no true nested transactions and uses savepoints; `DatabaseConnection` is `executeQuery` + `streamQuery(compiledQuery, chunkSize)` | HIGH | https://kysely-org.github.io/kysely-apidoc/interfaces/DatabaseConnection.html and kysely.dev savepoint docs (search) |
| 21 | SAVEPOINT outside BEGIN behaves as BEGIN DEFERRED; RELEASE is not durable against an outer ROLLBACK; ROLLBACK TO leaves the transaction open | HIGH | https://sqlite.org/lang_savepoint.html (fetched, quoted) |
| 22 | `sqlite3_trace_v2(D,M,X,P)` signature and the four-argument callback `(T,C,P,X)` | HIGH | https://sqlite.org/c3ref/trace_v2.html (fetched, quoted) |
| 23 | The specific meanings of SQLITE_TRACE_STMT/PROFILE/ROW/CLOSE and their P/X payloads | MEDIUM | the fetched page did not render the constant table; the mask names and PROFILE-carries-nanoseconds are from general knowledge. Re-read the page before implementing. |
| 24 | `SQLITE_ENABLE_NORMALIZE` is off by default; deserialize is on by default since 3.36.0; JSON on by default since 3.38.0; `SQLITE_ENABLE_STMT_SCANSTATUS` costs at runtime even when unused; `SQLITE_DQS` defaults to 3 with 0 recommended | HIGH | https://sqlite.org/compile.html (fetched, quoted) |
| 25 | `SQLITE_ENABLE_SESSION` requires `SQLITE_ENABLE_PREUPDATE_HOOK`; session has been in the amalgamation since 3.13.0 | HIGH | search over sqlite.org/sessionintro.html and the compile-options page |
| 26 | `sqlite3_error_offset` "returns the byte offset of the start of that token", −1 when none | HIGH | https://sqlite.org/c3ref/errcode.html (fetched, quoted) |
| 27 | `sqlite3_stmt_readonly` is true for transaction-control statements EXCEPT BEGIN IMMEDIATE/EXCLUSIVE; a false return does not guarantee a change | HIGH | https://sqlite.org/c3ref/stmt_readonly.html (fetched, quoted) |
| 28 | `sqlite3_blob_open` signature; size cannot change through the handle; the handle expires with SQLITE_ABORT when the row is modified | HIGH | https://sqlite.org/c3ref/blob_open.html (fetched, quoted) |
| 29 | The 12-step ALTER TABLE procedure, in order, with foreign_keys=OFF as step 1 and BEGIN as step 2 | HIGH | https://sqlite.org/lang_altertable.html (fetched, steps quoted) |
| 30 | Direct ALTER TABLE does only RENAME TO / RENAME COLUMN / ADD COLUMN / DROP COLUMN, with the listed restrictions | HIGH | same |
| 31 | `PRAGMA foreign_keys` is "a no-op within a transaction"; `PRAGMA defer_foreign_keys` CAN be changed inside a transaction and "is automatically switched off at each COMMIT or ROLLBACK" | HIGH | https://sqlite.org/pragma.html#pragma_foreign_keys (fetched, quoted) |
| 32 | `PRAGMA user_version` is at header offset 60; `application_id` at 68; `schema_version` at 40 and auto-incremented | HIGH | https://sqlite.org/pragma.html (fetched) |
| 33 | Pragma table-valued functions (`pragma_table_info(…)`) exist since 3.16.0 for side-effect-free pragmas | HIGH | same |
| 34 | `PRAGMA table_list` (3.37.0+) reports `schema, name, type, ncol, wr, strict` | HIGH | same |
| 35 | `PRAGMA data_version` differs between two reads from the same connection if another connection committed in between | HIGH | https://sqlite.org/pragma.html#pragma_data_version (fetched, quoted) |
| 36 | `PRAGMA writable_schema` (3.38.0+) makes ALTER TABLE silently ignore unparseable sqlite_schema rows | HIGH | https://sqlite.org/lang_altertable.html (fetched, quoted) |
| 37 | A migration runner setting `legacy_alter_table=ON` around the 12-step rename is common practice | MEDIUM | inferred from the pragma's documented purpose plus batch-migration tooling; no runner's source was read |
| 38 | sqlc "reads your SQL database schema, validates your queries against it, and then produces type-safe Go code", implementing the parser and type checker in pure Go | HIGH | https://sqlc.dev and conroy.org/introducing-sqlc (search, quoted) |
| 39 | sqlx checks queries against a live database at build time via DATABASE_URL, or a checked-in cache | HIGH | sqlx crate docs and repo README (search) |
| 40 | jOOQ generates from the live schema: "there should only be one source of truth for your meta model, and that's the DDL you ran in your database" | HIGH | https://blog.jooq.org/why-you-should-use-jooq-with-code-generation/ (search, quoted) |
| 41 | GRDB carries a schema cache with `ForeignKeyInfo`/`IndexInfo` and a `clearSchemaCache()` needed when another connection changes the schema | HIGH | GRDB/Core/Database+Schema.swift and CHANGELOG (search) |
| 42 | SeaORM's stream "will exclusively hold onto the connection until dropped" | HIGH | https://www.sea-ql.org/SeaORM/docs/advanced-query/streaming/ (search, quoted) |
| 43 | `core.Type` has no float, no bytes, and no decimal; `Ptr` is the only foreign-pointer shape and is untyped | HIGH | read packages/std-avrac/src/core/types.av:12–80; `Ptr` at :21 |
| 44 | `ptr` is nameable from Avra source | HIGH | read packages/std-avrac/src/language/typing.av:322 |
| 45 | Every extern gets `RtHost.Unhosted` and the interpreter traps on one | HIGH | read packages/std-avrac/src/core/runtime_api.av:104 and packages/std-avrac/src/language/interp.av:574 |
| 46 | @std/process uses int handles into a runtime table rather than opaque pointers | HIGH | read packages/std-process/src/process.av:15–29 |
| 47 | The tree's string search verbs are C-string-shaped rows and would truncate at an embedded NUL | MEDIUM | read the rows at packages/std-avrac/src/core/runtime_api.av:57–65; runtime/avra_runtime.c was NOT read. CLAUDE.md:668 confirms `.length` is a header load, so the storage is NUL-safe and only the search verbs are in question. |
| 48 | Spec 15.4/15.5/15.3/15.7 give `@free_with`, `opaque type`, trampolines and `@error_if`, and name `sqlite3_open`/`sqlite3_close` in the examples | HIGH | read FULL_SPEC.md:2873–3082 |
| 49 | Spec 22.1/22.2/22.3 make `model` provider-supplied, list the default projections, and choose diff-generated reviewable migrations | HIGH | read FULL_SPEC.md:4539–4731 |
| 50 | `@derive` is a lifted function returning declarations, with no hardcoded list | HIGH | read FULL_SPEC.md:91–150 |
| 51 | Spec 31.2 pins `float` as app-level f64 IEEE 754; 31.3 puts BigDecimal in `@std/numbers` and refuses core arbitrary precision | HIGH | read FULL_SPEC.md:6230–6411 |
| 52 | The tree refuses `Result<void, E>`, a lambda in a field/argument seat, a bare `table` literal, and `m["k"]` | HIGH | CLAUDE.md:574, :605, :528, :654 |
| 53 | Origin metadata is what lets an ORM split a joined row without alias rewriting; ORMs without it emit prefixed aliases | MEDIUM | the mechanism follows directly from what the API returns, and Drizzle/Kysely/SQLAlchemy do emit prefixed aliases; no ORM's source was read to confirm the causal claim |
| 54 | `EXPLAIN QUERY PLAN` at compile time could refuse an unindexed scan | LOW-MEDIUM | speculative design; the SQL is real, the policy is not designed |
| 55 | An Avra-side tracing hook is sufficient for v1 logging because the driver is the only path to the database | MEDIUM | follows from the architecture, but assumes no ATTACH-time or extension-issued statements |
