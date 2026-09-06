# THE TRAP CATALOGUE — SQLite semantics that break a naive binding

*Research for `@std/sqlite`. Every trap is numbered `Tn` so a driver test
can cite it. Nothing in the Avra tree was built, run or changed to produce
this: the only processes run were `sqlite3` CLI one-liners against scratch
databases, and web reads of sqlite.org.*

---

## Part 0 — How to read this, and what is actually known

### 0.1 The one sentence

> **SQLite answers every question you ask it, including the ones you asked
> by accident. The declared type is a hint, the storage class is the truth,
> the pointer you hold is on loan, and every conversion you request is
> performed silently and destructively. A driver's job is to make the
> engine's flexibility invisible without making it a lie.**

### 0.2 Evidence tags

Every claim carries one:

| Tag | Meaning |
|---|---|
| `MEASURED` | Output of a `sqlite3` CLI probe run for this document. The command and its output are shown. |
| `DOC` | Quoted or closely paraphrased from sqlite.org or from `sqlite3.h`'s own comments (public domain). |
| `INFERRED` | Reasoning from `DOC` + `MEASURED`. Flagged because it is the class of claim this project's own doctrine says to distrust ("MEASURE WHAT A THING DOES BEFORE EXPLAINING WHY TWO DIFFER"). |

### 0.3 The engine that was measured

```
$ sqlite3 --version
3.51.0 2025-06-12 f0ca7bba1c5e232e5d279fad6338121ab55af0c8c68c84cdfb18ba5114dcaapl (64-bit)
```

macOS 25.5.0 (darwin), APFS on SSD, Apple's *system* SQLite — **not** the
upstream amalgamation. That distinction is itself a trap (T126) and
it colours several measurements; each is marked where it does.

Header quotes are from `sqlite3.h` of that build; line numbers are given
so a re-read is cheap.

### 0.4 Three corrections to the brief that commissioned this

The brief is right about the shape of every one of these and off on the
version numbers. Recording them here because a driver that pins behaviour
to the wrong release will ship the wrong defence.

- **The floating-point rendering change is 3.53.0 (2026-04-09), not 3.41.**
  `changes.html`: *"Rounding is now done by default to 17 significant
  digits, instead of 15, as was the case for all prior versions. The
  sqlite3_db_config(SQLITE_DBCONFIG_FP_DIGITS) API can change this."*
  3.41.0 (2023-02-21) is where **`sqlite3_error_offset()`** landed —
  a different item on the brief's list. 3.52.0 was withdrawn and its
  contents moved into 3.53.0. `floatingpoint.html` still says "3.52.0",
  which is stale relative to `changes.html`. See T102–T105.
- **A negative length to `sqlite3_bind_blob()` is UNDEFINED BEHAVIOUR,
  not `strlen`.** The `-1 means strlen` rule is `bind_text`-only.
  `sqlite3.h`: *"If the fourth parameter to sqlite3_bind_blob() is
  negative, then the behavior is undefined."* See T90.
- **`SQLITE_MAX_VARIABLE_NUMBER` is not 32766 on the machine this was
  written on; it is 500000.** limits.html gives the default and the
  maximum as 32766. This build's own error message says otherwise —
  `SELECT ?1000000` fails with *"variable number must be between ?1 and
  ?500000"* — and a real bulk `INSERT … VALUES (?,?),(?,?)…` accepted
  **200 000** parameters (`MEASURED`, T115). The lesson is not the number,
  it is that the number must be *read*
  (`sqlite3_limit(db, SQLITE_LIMIT_VARIABLE_NUMBER, -1)`), never assumed.

### 0.5 Relationship to the earlier round

A previous research pass wrote a `LAW`-coded document to this same path.
It was **untracked**, so this file's creation would have destroyed it; a
byte-exact copy is preserved at

```
/private/tmp/claude-502/-Users-tristan-projects-tristanMatthias-avra/eda81224-4799-47d3-8cb1-b55f31f462e3/scratchpad/PRIOR_semantics_traps.md
```

Everything it established is carried forward here — Appendix B maps its
`LAW` codes onto these `T` numbers. This document adds: the measured
evidence, the conversion-table quotes in full, threading, text encoding,
integers, floating point, file-level realities, schema-introspection
pragmas, the build-defaults trap, and measured performance numbers.

### 0.6 The trap index

| Range | Topic |
|---|---|
| T1–T16 | Type affinity and dynamic typing |
| T17–T25 | The conversion minefield |
| T26–T33 | Pointer invalidation and bind lifetimes |
| T34–T48 | The statement lifecycle |
| T49–T61 | Busy, locked and concurrency |
| T62–T67 | Threading modes |
| T68–T80 | Transaction semantics |
| T81–T89 | Error reporting |
| T90–T99 | NULL, empty and zero |
| T100–T107 | Text encoding |
| T108–T115 | Integers |
| T116–T123 | Floating point |
| T124–T136 | File-level realities |
| T137–T150 | Pragmas that are actually API |
| T151–T162 | Performance, measured |
| T163–T174 | The remaining surprises (rowids, changes, ORDER BY, collation, upsert) |

**174 traps.** Appendix A turns the ten that matter most into tests;
Appendix B maps the earlier round's `LAW` codes onto these numbers;
Appendix C says where this document could be wrong.

---

# Part 1 — TYPE AFFINITY AND DYNAMIC TYPING (T1–T16)

## 1.1 The five storage classes

`DOC` (datatype3.html §2). Every stored value is exactly one of `NULL`,
`INTEGER`, `REAL`, `TEXT`, `BLOB`. `sqlite3_column_type()` answers one of
`SQLITE_NULL` / `SQLITE_INTEGER` / `SQLITE_FLOAT` / `SQLITE_TEXT` /
`SQLITE_BLOB` for every column of every row.

---

**T1 — THE STORAGE CLASS IS A PROPERTY OF THE VALUE, NOT OF THE COLUMN.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(a); INSERT INTO t VALUES(1),('two'),(3.5),(x'00ff'),(NULL);
                    SELECT rowid, typeof(a), quote(a) FROM t;"
1|integer|1
2|text|'two'
3|real|3.5
4|blob|X'00FF'
5|null|NULL
```

Five rows, one column, five different storage classes.

*Why it exists.* Manifest typing. SQLite's declared types select a
*conversion policy* (an affinity), never an enforcement. This is deliberate
and documented as a feature (quirks.html §2, "Flexible typing").

*The naive failure.* A driver that reads its decoder from the schema
decodes row 1 correctly and returns garbage — or a plausible zero — for
rows 2–5. This is the root trap; almost everything in Part 1 and Part 2 is
a consequence of it.

*The defence.* **Ask `sqlite3_column_type(stmt, i)` first, for every column
of every row, before touching any value accessor.** It is one call, it is
free relative to the value read, and after it the driver never has to
guess. The per-value class then selects an arm of a total registry (see
T14).

*Whose.* DRIVER. The caller must never see a storage class unless they ask
for the escape hatch.

---

**T2 — AFFINITY IS DERIVED BY SUBSTRING MATCH ON THE DECLARED TYPE TEXT,
IN A FIXED ORDER, FIRST MATCH WINS.**

*Behaviour.* `DOC` (datatype3.html §3.1), in order: (1) contains `INT` →
INTEGER; (2) contains `CHAR`, `CLOB` or `TEXT` → TEXT; (3) contains `BLOB`
**or the type is empty** → BLOB; (4) contains `REAL`, `FLOA` or `DOUB` →
REAL; (5) otherwise → NUMERIC.

`MEASURED`, storing the REAL `1.5` into five differently-declared columns:

```
$ sqlite3 :memory: "CREATE TABLE t(a 'FLOATING POINT', b STRING, c VARCHAR(10), d MIDPOINT, e);
                    INSERT INTO t VALUES(1.5,'1.5','1.5',1.5,1.5);
                    SELECT typeof(a),typeof(b),typeof(c),typeof(d),typeof(e) FROM t;"
real|real|text|real|real
```

`FLOATING POINT` contains `INT` (inside `POINT`) so rule 1 fires before
rule 4 and it has **INTEGER** affinity — the documentation's own worked
example. `MIDPOINT` likewise. `STRING` matches nothing and is NUMERIC.
`VARCHAR(10)` is TEXT.

*Why it exists.* Compatibility: SQLite accepts any type name from any
other SQL dialect and has to guess an intent. Substring matching is the
cheapest guess that gets `VARCHAR2`, `NVARCHAR`, `BIGINT`, `MEDIUMINT`
right.

*The naive failure.* A driver that generates DDL from Avra type names
emits a column whose user-facing type name happens to contain `INT` and
silently acquires numeric coercion on what the program thinks is a text
field. The round trip then depends on the *value*: `"12"` comes back as
the integer `12`, `"12abc"` stays TEXT — so the reader refuses on one row
and not the next.

*The defence.* The driver's own DDL generator emits **only** the six
STRICT-legal type names (`INT`, `INTEGER`, `REAL`, `TEXT`, `BLOB`, `ANY`)
and nothing else. Never interpolate a user-facing type name into DDL.

*Whose.* DRIVER.

---

**T3 — A COLUMN WITH NO DECLARED TYPE HAS BLOB AFFINITY, WHICH MEANS NO
COERCION AT ALL.**

*Behaviour.* `DOC` rule 3; `MEASURED` in T1 (column `a` was declared with
no type and kept every value's class exactly).

*Why.* BLOB affinity is the identity policy: *"A column with affinity BLOB
does not prefer one storage class over another and no attempt is made to
coerce data"* (datatype3.html §3.2).

*The naive failure.* A driver that treats "no declared type" as "probably
text" is wrong for four of the five classes.

*The defence.* Treat an empty decltype as an explicit `ANY` column: it can
hold anything, so only `SqlValue` (T15) or a nullable reader is honest.

*Whose.* DRIVER, and surfaced to the CALLER in schema introspection.

---

**T4 — INTEGER AFFINITY DOES NOT REJECT A REAL.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(i INT); INSERT INTO t VALUES(1.5),(2.0),('9');
                    SELECT typeof(i), quote(i) FROM t;"
real|1.5
integer|2
integer|9
```

`1.5` into an `INT` column stays REAL, because 1.5 is not losslessly an
integer. `2.0` becomes the integer `2`. `'9'` becomes the integer `9`.

*Why.* INTEGER and NUMERIC affinity are the same policy — *"A column that
uses INTEGER affinity behaves the same as a column with NUMERIC affinity"*
(datatype3.html §3.2) — and NUMERIC converts only when the conversion is
**lossless and reversible**.

*The naive failure.* An Avra `int` field reads a REAL back, a naive
`sqlite3_column_int64` performs a CAST-to-integer, and `1.5` silently
becomes `1`. No error, wrong data, arbitrarily far from the write.

*The defence.* An `int` seat accepts storage class `INTEGER` **only** and
refuses `REAL` with a named diagnostic. The lossy read is a separately
named verb (T15).

*Whose.* DRIVER refuses; CALLER chooses the lossy verb if they want it.

---

**T5 — NUMERIC AFFINITY CONVERTS TEXT THAT LOOKS NUMERIC, AND LEAVES THE
REST AS TEXT.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(x NUMERIC); INSERT INTO t VALUES('3.0'),('3.5'),('12abc'),('  7 ');
                    SELECT typeof(x), quote(x) FROM t;"
integer|3
real|3.5
text|'12abc'
integer|7
```

Note `'3.0'` → **integer 3** (REAL 3.0 is losslessly an integer, so it is
stored as one), and `'  7 '` → integer 7 (surrounding whitespace ignored).

*Why.* NUMERIC's contract is "store as a number if you can do so without
losing information".

*The naive failure.* A column of "numeric strings" read as `string`
refuses on three rows out of four, and the one that survives is the one
that looked non-numeric. A test written with `'12abc'` passes; production
data of `'3.0'` fails.

*The defence.* Same as T4 — class-first dispatch. And the driver's own
schema never uses NUMERIC affinity: it is the affinity you get by
*accident*, never the one you want on purpose.

*Whose.* DRIVER.

---

**T6 — REAL AFFINITY FORCES INTEGERS TO FLOAT, AND LOSES PRECISION ABOVE
2^53 WITHOUT SAYING SO.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(r REAL); INSERT INTO t VALUES(1),(9007199254740993),(9223372036854775807);
                    SELECT typeof(r), quote(r), CAST(r AS INTEGER) FROM t;"
real|1.0|1
real|9.007199254740992e+15|9007199254740992
real|9.22337203685477581e+18|9223372036854775807
```

Row 2: `9007199254740993` (2^53 + 1) went in and `9007199254740992`
came out. **One silently changed integer.** Row 3 survives only because
`i64::MAX` happens to round-trip through the CAST clamp.

*Why.* REAL affinity *"forces integer values into floating point
representation"* (datatype3.html §3.2), and binary64 has 53 bits of
mantissa.

*The naive failure.* This is the brief's question 11 ("what happens
binding an i64 to a column with REAL affinity") and the answer is: it is
accepted, converted, and *may be a different number*, with no diagnostic
at any layer. An id column declared `REAL` by mistake corrupts every id
above 2^53.

*The defence.* Two parts. (a) The driver's DDL never declares REAL for
anything an `int` is bound to. (b) On the read side, a `float` seat
accepts `INTEGER` **iff |v| ≤ 2^53** and `REAL` always; an `int` seat
accepts `INTEGER` only. The 2^53 bound is what makes accepting INTEGER
into a float seat honest.

*Whose.* DRIVER, and the ceiling is documented to the CALLER.

---

**T7 — COMPARISON APPLIES AFFINITY, SO `1 = '1'` IS FALSE AND
`col = '1'` IS TRUE.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT 1='1';"                                     → 0
$ sqlite3 :memory: "CREATE TABLE t(i INT); INSERT INTO t VALUES(1);
                    SELECT i='1' FROM t;"                              → 1
```

*Why.* Two literals have no affinity, so no conversion is applied and the
comparison falls back to class order — `INTEGER < TEXT`, so unequal
(quirks.html §15). With a column of INTEGER affinity on one side, NUMERIC
affinity is applied to the other and the text becomes a number.

*The naive failure.* A driver that binds numbers as text (or interpolates
them as quoted literals) writes queries that match in one shape and not
another.

*The defence.* Bind values with their real type. Never interpolate.

*Whose.* DRIVER.

---

**T8 — AFFINITY IS LOST THROUGH AN EXPRESSION IN A SUBQUERY.**

*Behaviour.* `MEASURED` — the same predicate, three ways:

```
$ sqlite3 :memory: "CREATE TABLE t(i INT); INSERT INTO t VALUES(1);
   SELECT (SELECT count(*) FROM t WHERE i='1')                       AS direct,
          (SELECT count(*) FROM (SELECT i     FROM t) WHERE i='1')   AS via_subq,
          (SELECT count(*) FROM (SELECT i+0 AS i FROM t) WHERE i='1') AS via_expr;"
1|1|0
```

A bare column passed through a subquery keeps its affinity; **an
expression does not**, and the same `WHERE` now matches nothing.

*Why.* Affinity belongs to a *table column*. A computed result column has
no declared type, therefore no affinity, therefore rule 3 of the
comparison rules applies and classes are compared directly.

*The naive failure.* The classic "works on the table, fails in the
CTE/UNION/view" bug — a query builder that wraps a user's query in a
subquery for pagination changes its results.

*The defence.* The driver's generated SQL never changes a predicate's
affinity context: paginate with `LIMIT`/`OFFSET` on the original select,
not by wrapping. And bind typed values (T7), which makes the whole
question moot.

*Whose.* DRIVER; a compile-time SQL checker should warn on a comparison
against a bare literal of a different class.

---

**T9 — ARITHMETIC COERCES BOTH OPERANDS TO NUMBERS, ALWAYS.**

*Behaviour.* `DOC` (datatype3.html §4.3): *"Mathematical operators …
interpret both operands as if they were numbers. STRING or BLOB operands
automatically convert into REAL or INTEGER."*

*The naive failure.* `UPDATE t SET n = n + 1` where `n` holds the text
`'abc'` writes `1`. Not an error.

*The defence.* Nothing at the driver layer can catch this; it is a SQL
semantics fact. It belongs in the compile-time SQL checker (P10) and in
the STRICT-tables answer (T12).

*Whose.* CALLER, informed by the driver's documentation.

---

**T10 — ONLY `INTEGER PRIMARY KEY`, SPELLED EXACTLY, ALIASES THE ROWID.**

*Behaviour.* `DOC` (autoinc.html, lang_createtable.html). `INT PRIMARY
KEY` does not. `UNSIGNED BIG INT PRIMARY KEY` does not.

*Why.* The alias is a syntactic special case, matched on the exact token
`INTEGER`.

*The naive failure.* A DDL generator that emits `INT PRIMARY KEY` for an
Avra `int` id creates a column that (a) is not the rowid, (b) accepts
`'hello'`, (c) costs a second hidden rowid and a second B-tree, and (d)
loses the O(1) primary lookup.

*The defence.* The generator emits `INTEGER PRIMARY KEY` verbatim, and a
test asserts the emitted DDL contains it.

*Whose.* DRIVER.

---

**T11 — A `PRIMARY KEY` THAT IS NOT `INTEGER PRIMARY KEY` MAY BE NULL, AND
`PRAGMA table_info` REPORTS THE ROWID ALIAS AS NULLABLE.**

*Behaviour.* `MEASURED`, two halves.

```
$ sqlite3 :memory: "CREATE TABLE p(a TEXT PRIMARY KEY); INSERT INTO p VALUES(NULL),(NULL);
                    SELECT count(*) FROM p;"
2
```

Two NULL primary keys. And introspection:

```
$ sqlite3 -header :memory: "CREATE TABLE c(id INTEGER PRIMARY KEY, pid INT, tag TEXT); PRAGMA table_info(c);"
cid|name|type|notnull|dflt_value|pk
0|id|INTEGER|0||1
...
```

`notnull` is **0** for the `INTEGER PRIMARY KEY`. Compare a `WITHOUT
ROWID` table, where the PK columns report `notnull=1`:

```
$ sqlite3 -header :memory: "CREATE TABLE w(a TEXT, b TEXT, PRIMARY KEY(a,b)) WITHOUT ROWID; PRAGMA table_info(w);"
0|a|TEXT|1||1
1|b|TEXT|1||2
```

*Why.* *"PRIMARY KEYs Can Contain NULLs"* — a long-standing documented bug
kept for backward compatibility (quirks.html §7). `WITHOUT ROWID` and
STRICT tables get it right. The rowid alias reports `notnull=0` because a
NULL insert into it is legal and means "assign one".

*The naive failure.* An ORM maps `notnull=1` to non-nullable, so it marks
the primary key of every rowid table **nullable** and the primary key of
every `WITHOUT ROWID` table non-nullable — inconsistently, from the same
introspection call. And a `TEXT PRIMARY KEY` mapped as non-nullable
refuses on legacy data.

*The defence.* The introspection layer special-cases `pk=1 AND
type='INTEGER' AND the table is a rowid table` → non-nullable identity
column. Everything else takes `notnull` at face value **and** the driver
documents that a non-STRICT `PRIMARY KEY` is not a NOT NULL.

*Whose.* DRIVER (the mapping); CALLER (the schema choice).

---

**T12 — STRICT TABLES ARE THE ESCAPE HATCH, AND THEY REFUSE ONLY LOSSY
CONVERSIONS.**

*Behaviour.* `MEASURED`, four probes:

```
$ sqlite3 :memory: "CREATE TABLE s(a INT, b TEXT, c ANY) STRICT;
                    INSERT INTO s VALUES(1,'x',1); INSERT INTO s VALUES('2','y','z');
                    SELECT typeof(a),typeof(b),typeof(c) FROM s;"
integer|text|integer
integer|text|text          ← '2' was losslessly converted to integer 2

$ sqlite3 :memory: "CREATE TABLE s(a INT) STRICT; INSERT INTO s VALUES('abc');"
Error: stepping, cannot store TEXT value in INT column s.a (19)

$ sqlite3 :memory: "CREATE TABLE s(a INT) STRICT; INSERT INTO s VALUES(1.5);"
Error: stepping, cannot store REAL value in INT column s.a (19)

$ sqlite3 :memory: "CREATE TABLE s(a INT) STRICT; INSERT INTO s VALUES(2.0); SELECT typeof(a),a FROM s;"
integer|2                  ← 2.0 IS losslessly an integer, so it is accepted

$ sqlite3 :memory: "CREATE TABLE s(a VARCHAR(10)) STRICT;"
Error: in prepare, unknown datatype for s.a: "VARCHAR(10)"

$ sqlite3 :memory: "CREATE TABLE s(a TEXT PRIMARY KEY) STRICT; INSERT INTO s VALUES(NULL);"
Error: stepping, NOT NULL constraint failed: s.a (19)
```

*Why.* STRICT (3.37.0+, stricttables.html) makes the declared type an
enforcement: only the six type names are legal, a lossy store raises
`SQLITE_CONSTRAINT_DATATYPE` (3091), and `PRIMARY KEY` is implicitly `NOT
NULL`. `ANY` preserves the value exactly.

*The naive failure (of not using it).* An Avra `int` field silently
acquires a TEXT value the first time anyone writes through raw SQL or
another tool, and every subsequent typed read refuses — a defect reported
at read time, arbitrarily far from the write that caused it.

*The defence.* **The driver's generated DDL is `STRICT`, always.** This is
the paradox collapse (P6) on "refuse or coerce": neither — make the
question unaskable where we own the schema, and refuse where we do not.
Note it does not make Part 2 dead code: STRICT constrains what a *column*
holds, not what an *expression* answers, so `SELECT a+0` still has no
affinity and `SELECT sum(x)` can still be NULL.

*Whose.* DRIVER by default; CALLER may opt out for foreign schemas.

---

**T13 — `sqlite3_column_decltype()` IS SCHEMA, NOT DATA, AND IS NULL FOR
EVERY EXPRESSION.**

*Behaviour.* `DOC` (c3ref/column_decltype.html): it answers the declared
type text for a result column that is a table column, and **NULL** for an
expression, a subquery result, or a view column. The page says outright
that a declared type does not mean the data is of that type.

`MEASURED` corroboration on the view side:

```
$ sqlite3 -header :memory: "CREATE VIEW v AS SELECT 1 AS a; PRAGMA table_info(v);"
cid|name|type|notnull|dflt_value|pk
0|a||0||0                   ← empty type
```

*The naive failure.* A driver that builds its row decoder from decltype at
prepare time decodes `SELECT count(*)` (decltype NULL) as whatever its
fallback is, and decodes a legacy TEXT-in-INTEGER row as an integer.

*The defence.* decltype is for **schema introspection** and for the future
compile-time SQL checker. It is never the reader's authority;
`sqlite3_column_type()` per value is (T1). Also: SQLite's own
*recommended* compile options include `-DSQLITE_OMIT_DECLTYPE`; the
vendored build must **not** take that recommendation if the checker is to
have decltype.

*Whose.* DRIVER.

---

**T14 — THE CLASS→SEAT TABLE IS A REGISTRY, AND A CATCH-ALL IN IT IS A
SILENT WRONG ANSWER.**

*The rule.* Five storage classes × the driver's seats. Under this project's
own `_ ->` doctrine, two or more answering arms make it a REGISTRY, and a
catch-all silently forgets the next case. Spell every arm:

| Class ↓ / seat → | `int` | `float` | `string` | `Bytes` | `bool` | `T?` |
|---|---|---|---|---|---|---|
| `NULL` | REFUSE | REFUSE | REFUSE | REFUSE | REFUSE | `null` |
| `INTEGER` | exact | exact iff \|v\| ≤ 2^53 | REFUSE | REFUSE | 0/1 only | inner |
| `REAL` | REFUSE | exact | REFUSE | REFUSE | REFUSE | inner |
| `TEXT` | REFUSE | REFUSE | exact | exact (text *is* bytes) | REFUSE | inner |
| `BLOB` | REFUSE | REFUSE | REFUSE¹ | exact | REFUSE | inner |

¹ unless the caller asked for the UTF-8-validating lossy reader.

*Why REFUSE and not coerce.* Four reasons from this project's own
doctrine. (a) **P9**: a row type is a declaration; coercing turns it into a
preference. (b) **I18**: `sqlite3_column_int()` on `"abc"` answering `0`
is `?? 0` implemented in C — the exact shape the tree refuses everywhere
else. (c) **P1**: an LLM writing against this driver gets exactly one
signal that its schema and its row type disagree, and coercion removes it.
(d) **P7**: the two lossless exceptions are written in the table rather
than discovered.

*Whose.* DRIVER.

---

**T15 — THE ESCAPE HATCHES ARE TWO, BOTH EXPLICIT, NEITHER THE DEFAULT.**

1. `SqlValue` — the total type (`Null | Int | Real | Text | Blob`). No
   refusal is possible; the storage class rides the value and the caller
   decides. This is P8.
2. A per-read **lossy** verb (`row.int_lossy(i)`), whose contract is
   literally "SQLite's CAST rules" (T25), named so no reader mistakes it
   for the strict one.

*The naive failure of omitting them.* A strict-only driver is unusable
against a foreign database, so callers drop to raw SQL and lose every
guarantee at once.

*Whose.* DRIVER provides; CALLER chooses.

---

**T16 — ROWIDS ARE REUSED WITHOUT `AUTOINCREMENT`.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(id INTEGER PRIMARY KEY, v);
                    INSERT INTO t(v) VALUES('a'),('b'),('c');
                    DELETE FROM t WHERE id=3; INSERT INTO t(v) VALUES('d');
                    SELECT id,v FROM t;"
1|a
2|b
3|d               ← id 3 was reused
```

*Why.* The default assignment is `max(rowid)+1` (autoinc.html).
`AUTOINCREMENT` makes ids monotonic and never-reused via the
`sqlite_sequence` table, at CPU, memory, disk and I/O cost, and fails with
`SQLITE_FULL` when exhausted; the docs say it *"should be avoided if not
strictly needed. It is usually not needed."*

*The naive failure.* A driver or ORM that treats `last_insert_rowid` as a
stable external identity (a URL, a cache key, an audit reference) hands
out an id that later names a different row.

*The defence.* Document it. Do not add `AUTOINCREMENT` by default — the
cost is real and the fix belongs to whoever needs stable external ids
(a UUID column, or `AUTOINCREMENT` chosen deliberately).

*Whose.* CALLER, made visible by the driver.

---

# Part 2 — THE CONVERSION MINEFIELD (T17–T25)

**This is the single most-cited SQLite binding bug, so this section quotes
the primary source in full rather than paraphrasing.** All quotes are from
`sqlite3.h` lines 5315–5510 (the `CAPI3REF: Result Values From A Query`
block), which is the same text as c3ref/column_blob.html.

## 2.1 The conversion table, verbatim

> ```
> ** <tr><td>  NULL    <td> INTEGER   <td> Result is 0
> ** <tr><td>  NULL    <td>  FLOAT    <td> Result is 0.0
> ** <tr><td>  NULL    <td>   TEXT    <td> Result is a NULL pointer
> ** <tr><td>  NULL    <td>   BLOB    <td> Result is a NULL pointer
> ** <tr><td> INTEGER  <td>  FLOAT    <td> Convert from integer to float
> ** <tr><td> INTEGER  <td>   TEXT    <td> ASCII rendering of the integer
> ** <tr><td> INTEGER  <td>   BLOB    <td> Same as INTEGER->TEXT
> ** <tr><td>  FLOAT   <td> INTEGER   <td> [CAST] to INTEGER
> ** <tr><td>  FLOAT   <td>   TEXT    <td> ASCII rendering of the float
> ** <tr><td>  FLOAT   <td>   BLOB    <td> [CAST] to BLOB
> ** <tr><td>  TEXT    <td> INTEGER   <td> [CAST] to INTEGER
> ** <tr><td>  TEXT    <td>  FLOAT    <td> [CAST] to REAL
> ** <tr><td>  TEXT    <td>   BLOB    <td> No change
> ** <tr><td>  BLOB    <td> INTEGER   <td> [CAST] to INTEGER
> ** <tr><td>  BLOB    <td>  FLOAT    <td> [CAST] to REAL
> ** <tr><td>  BLOB    <td>   TEXT    <td> [CAST] to TEXT, ensure zero terminator
> ```

Every cell of that table is a *silent* conversion. There is no error path.

---

**T17 — EVERY VALUE ACCESSOR IS A CONVERSION REQUEST, AND THE CONVERSION
IS PERFORMED IN PLACE ON SQLITE'S OWN COPY OF THE VALUE.**

*Behaviour.* `DOC`: *"The first six interfaces (_blob, _double, _int,
_int64, _text, and _text16) each return the value of a result column in a
specific data format. If the result column is not initially in the
requested format … then an automatic type conversion is performed."*
And: *"Note that when type conversions occur, pointers returned by prior
calls to sqlite3_column_blob(), sqlite3_column_text(), and/or
sqlite3_column_text16() may be invalidated."*

*Why.* SQLite stores one representation per value and rewrites it in place
when you ask for another, because holding both would double the memory of
every row.

*The naive failure.* Calling `sqlite3_column_text(stmt, i)` on an INTEGER
column does not merely *return* a rendering — it **replaces the value's
representation with that rendering**. Everything that reads the column
afterwards, including `sqlite3_column_type()`, is reading the converted
value.

*The defence.* **Exactly one value accessor per column per row, chosen by
`sqlite3_column_type()` beforehand.** No second read, not even for a
diagnostic message.

*Whose.* DRIVER. This is invisible to callers by construction.

---

**T18 — `sqlite3_column_type()` IS ONLY MEANINGFUL BEFORE ANY CONVERSION,
AND UNDEFINED AFTER ONE.**

*Behaviour.* `DOC`, verbatim: *"The value returned by
sqlite3_column_type() is only meaningful if no automatic type conversions
have occurred for the value in question. After a type conversion, the
result of calling sqlite3_column_type() is undefined, though harmless.
Future versions of SQLite may change the behavior of
sqlite3_column_type() following a type conversion."*

*The naive failure.* A driver whose refusal path is written as "read the
value, discover it does not fit, ask what class it was to build the error
message" reports **TEXT for every refusal**, because rendering the value
for the message converted it. Every diagnostic the driver emits about a
type mismatch is then wrong about the type.

*The defence.* The class is captured **first**, into a local, before any
accessor runs. The refusal message is built from the captured class, and
the value in the message — if any — is rendered from the copy the driver
already took, never by asking SQLite again.

*Whose.* DRIVER.

---

**T19 — `sqlite3_column_bytes()` IS A CONVERSION TOO. CALLING IT FIRST
DESTROYS THE VALUE YOU WERE ABOUT TO READ.**

*Behaviour.* `DOC`, verbatim: *"If the result is a numeric value then
sqlite3_column_bytes() uses sqlite3_snprintf() to convert that value to a
UTF-8 string and returns the number of bytes in that string."* And:
*"If the result is a UTF-16 string, then sqlite3_column_bytes() converts
the string to UTF-8 and then returns the number of bytes."*

*Why.* "How many bytes is this?" is only answerable in a specific
encoding, so asking forces the value into that encoding.

*The naive failure.* The instinctive C idiom — *measure, allocate, copy* —

```c
int n = sqlite3_column_bytes(stmt, i);      /* converts an INTEGER to TEXT */
const void *p = sqlite3_column_blob(stmt, i); /* now returns the TEXT rendering */
```

hands the driver `"12345"` where the column held the integer `12345`, and
its "blob" is the ASCII of a number.

*The defence.* **The order is value, then length, then copy.** Never
measure first.

*Whose.* DRIVER.

---

**T20 — THERE IS EXACTLY ONE SAFE CALLING ORDER, AND THE DOCUMENTATION
NAMES IT.**

*Behaviour.* `DOC`, verbatim:

> *"The safest policy is to invoke these routines in one of the following
> ways:*
> - *sqlite3_column_text() followed by sqlite3_column_bytes()*
> - *sqlite3_column_blob() followed by sqlite3_column_bytes()*
> - *sqlite3_column_text16() followed by sqlite3_column_bytes16()*
>
> *In other words, you should call sqlite3_column_text(),
> sqlite3_column_blob(), or sqlite3_column_text16() first to force the
> result into the desired format, then invoke sqlite3_column_bytes() or
> sqlite3_column_bytes16() to find the size of the result. Do not mix
> calls to sqlite3_column_text() or sqlite3_column_blob() with calls to
> sqlite3_column_bytes16(), and do not mix calls to
> sqlite3_column_text16() with calls to sqlite3_column_bytes()."*

*The defence, as the driver's one read verb.* The whole of Parts 2 and 3
collapses into a single function that no feature may bypass:

```
read_column(stmt, i):
    cls = sqlite3_column_type(stmt, i)        # 1. class FIRST, captured
    if cls == SQLITE_NULL: return Null        #    (T18, T97)
    match cls:
      INTEGER -> Int(sqlite3_column_int64(stmt, i))     # scalars: no pointer
      FLOAT   -> Real(sqlite3_column_double(stmt, i))
      TEXT    -> p = sqlite3_column_text(stmt, i)       # 2. VALUE
                 n = sqlite3_column_bytes(stmt, i)      # 3. LENGTH
                 Text(copy_into_avra_box(p, n))         # 4. COPY (T26)
      BLOB    -> p = sqlite3_column_blob(stmt, i)       # 2. VALUE
                 n = sqlite3_column_bytes(stmt, i)      # 3. LENGTH
                 Blob(copy_into_avra_box(p, n))         # 4. COPY
```

Four steps, one order, no exceptions, ≤ 3 SQLite calls per column (2 for
scalars). Every trap in Parts 2 and 3 is a way of violating one of the
four steps. A driver test should assert the *call sequence*, not just the
values — a counting shim over the C entry points makes T17–T21 mechanically
checkable.

*Whose.* DRIVER.

---

**T21 — THE THREE CONVERSIONS THAT INVALIDATE A POINTER YOU ALREADY HOLD.**

*Behaviour.* `DOC`, verbatim:

> - *"The initial content is a BLOB and sqlite3_column_text() or
>   sqlite3_column_text16() is called. A zero-terminator might need to be
>   added to the string."*
> - *"The initial content is UTF-8 text and sqlite3_column_bytes16() or
>   sqlite3_column_text16() is called. The content must be converted to
>   UTF-16."*
> - *"The initial content is UTF-16 text and sqlite3_column_bytes() or
>   sqlite3_column_text() is called. The content must be converted to
>   UTF-8."*

And the one exception: *"Conversions between UTF-16be and UTF-16le are
always done in place and do not invalidate a prior pointer, though of
course the content of the buffer that the prior pointer references will
have been modified. Other kinds of conversion are done in place when it is
possible, but sometimes they are not possible and in those cases prior
pointers are invalidated."*

*The naive failure.* A driver that reads `column_blob(i)`, holds the
pointer, then calls `column_text(i)` **on the same column** to build a
diagnostic string has just freed the pointer it is about to copy from.
This is the failure mode T18's defence exists to prevent, seen from the
memory side.

*The defence.* Step 4 of T20: copy *before* anything else touches the
statement, and never call a second accessor on a column.

*Whose.* DRIVER.

---

**T22 — ON OUT-OF-MEMORY, A COLUMN READ IS INDISTINGUISHABLE FROM NULL.**

*Behaviour.* `DOC`, verbatim: *"If an out-of-memory error occurs, then the
return value from these routines is the same as if the column had
contained an SQL NULL value. Valid SQL NULL returns can be distinguished
from out-of-memory errors by invoking the sqlite3_errcode() immediately
after the suspect return value is obtained and before any other SQLite
interface is called on the same database connection."*

The five interfaces subject to OOM: `column_blob`, `column_text`,
`column_text16`, `column_bytes`, `column_bytes16`.

*Why.* The conversion may need to allocate; there is no error channel in a
function that returns a pointer.

*The naive failure.* Under memory pressure, rows silently become NULL and
the program records absence where there was data.

*The defence.* In `read_column`'s TEXT/BLOB arms, after the value read: if
the pointer is NULL **and** the class was not NULL, call
`sqlite3_errcode()` before anything else and raise. Note the interaction
with T97: a zero-length blob *also* returns NULL, so the test is
`ptr == NULL && n > 0` → check errcode; `ptr == NULL && n == 0` → empty.

*Whose.* DRIVER.

---

**T23 — A COLUMN ACCESSOR OUTSIDE `SQLITE_ROW` IS UNDEFINED, NOT AN
ERROR.**

*Behaviour.* `DOC`, verbatim: *"These routines may only be called when the
most recent call to sqlite3_step() has returned SQLITE_ROW and neither
sqlite3_reset() nor sqlite3_finalize() have been called subsequently. If
any of these routines are called after sqlite3_reset() or
sqlite3_finalize() or after sqlite3_step() has returned something other
than SQLITE_ROW, the results are undefined."* Also: *"If the SQL statement
does not currently point to a valid row, or if the column index is out of
range, the result is undefined."*

*The naive failure.* A driver that hands the caller a `Row` value which
outlives the iteration step — an ergonomic API shape, and the most natural
one in a language with values — produces undefined behaviour the moment the
caller keeps it.

*The defence.* A `Row` is **not** a value that can escape. Either the row
is decoded eagerly into owned Avra values at each `SQLITE_ROW` (the
default), or the cursor API is shaped so a row handle cannot outlive its
turn. Index bounds are checked in Avra against `sqlite3_column_count()`
before any accessor call, because SQLite will not check them.

*Whose.* DRIVER, and it constrains the public API shape.

---

**T24 — `sqlite3_column_value()` RETURNS AN *UNPROTECTED* VALUE AND IS NOT
FOR APPLICATION CODE.**

*Behaviour.* `DOC`, verbatim: *"Warning: The object returned by
sqlite3_column_value() is an unprotected sqlite3_value object. In a
multithreaded environment, an unprotected sqlite3_value object may only be
used safely with sqlite3_bind_value() and sqlite3_result_value(). If the
unprotected sqlite3_value object returned by sqlite3_column_value() is used
in any other way, including calls to routines like sqlite3_value_int(),
sqlite3_value_text(), or sqlite3_value_bytes(), the behavior is not
threadsafe. Hence, the sqlite3_column_value() interface is normally only
useful within the implementation of application-defined SQL functions or
virtual tables, not within top-level application code."*

*The naive failure.* It looks like the elegant answer to T14 — one call
that hands back a tagged value. It is not; it is a thread-unsafe handle
with no lifetime of its own.

*The defence.* The driver does not expose `column_value` at all. It
becomes relevant only if and when Avra hosts SQL functions or virtual
tables, where `sqlite3_value_*` is the *protected* API on the argument
side.

*Whose.* DRIVER (by omission).

---

**T25 — CAST IS THE PREFIX RULE, AND IT NEVER ERRORS.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT CAST('12abc' AS INTEGER), CAST('abc' AS INTEGER), CAST('  9 ' AS INTEGER),
                           CAST('0x10' AS INTEGER),  CAST('1e3' AS INTEGER), CAST('1e3' AS REAL),
                           CAST(3.9 AS INTEGER),     CAST(-3.9 AS INTEGER);"
12|0|9|0|1|1000.0|3|-3
```

`'12abc'` → 12. `'abc'` → 0. `'0x10'` → **0** (hex is not accepted by
CAST). `'1e3'` → **1** as an integer (the integer prefix stops at `e`) but
**1000.0** as a REAL. Floats truncate toward zero.

*Why.* `DOC` (lang_expr.html): *"the longest possible prefix of the value
that can be interpreted as an integer number is extracted … and the
remainder ignored … If there is no prefix that can be interpreted as an
integer number, the result of the conversion is 0."*

*The naive failure.* This is the rule the C column accessors implement
(the conversion table above). `sqlite3_column_int64()` on the TEXT `"abc"`
answers `0` — indistinguishable from a stored zero, from a NULL (T22), and
from an OOM.

*The defence.* The prefix rule appears in this driver in exactly one
place: behind the explicitly-named lossy reader of T15. Nowhere else.

*Whose.* CALLER opts in; DRIVER never does it implicitly.

---

# Part 3 — POINTER INVALIDATION AND BIND LIFETIMES (T26–T33)

**T26 — EVERY POINTER SQLITE RETURNS FROM A COLUMN DIES ON THE NEXT
`step`, `reset` OR `finalize`.**

*Behaviour.* `DOC`, verbatim: *"The pointers returned are valid until a
type conversion occurs as described above, or until sqlite3_step() or
sqlite3_reset() or sqlite3_finalize() is called. The memory space used to
hold strings and BLOBs is freed automatically. Do not pass the pointers
returned from sqlite3_column_blob(), sqlite3_column_text(), etc. into
sqlite3_free()."*

*Why.* The value lives in the statement's own register file, which is
reused for the next row.

*The naive failure, and why it is worse for Avra than for C.* In C the bug
is a use-after-free. **In Avra it is a corrupted heap.** This project's
runtime law is that *every pointer Avra holds carries a header* — sixteen
bytes before the payload holding tag, kind, refcount and length — and
`avra_rc_retain`/`release` read that header. A borrowed SQLite pointer
handed across as an Avra `string` makes the refcounter read sixteen bytes
of SQLite's private allocator state as though it were our header. The tag
check will usually catch it and trap; when it does not, the runtime
decrements a refcount inside SQLite's memory.

*The defence.* **Copy at the boundary, into an Avra box, before the next
`step`, always.** The copy verb allocates `n + 1` and writes the NUL
itself (T100), because `column_bytes` excludes the terminator and Avra's
`str_box(n)` allocates `n + 1` expecting one.

*The cost, stated honestly.* One allocation and one `memcpy` per TEXT or
BLOB column per row. Scalars cost zero — `column_int64`/`column_double`
return by value and mint no box. The budget is therefore: **0 allocations
per all-scalar row, exactly 1 per text/blob column, never 2.** The second
copy is what a driver accidentally pays when it renders a value for a
diagnostic (T18) or measures before reading (T19).

*Whose.* DRIVER, unconditionally. There is no configuration in which
borrowing is offered.

---

**T27 — `SQLITE_STATIC` MEANS "I PROMISE THIS BUFFER OUTLIVES THE
STATEMENT", AND AVRA CANNOT MAKE THAT PROMISE TODAY.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, bind block):

> *"(2) The special constant, SQLITE_STATIC, may be passed to indicate
> that the application remains responsible for disposing of the object.
> In this case, the object and the provided pointer to it must remain
> valid until either the prepared statement is finalized or the same SQL
> parameter is bound to something else, whichever occurs sooner."*
>
> *"(3) The constant, SQLITE_TRANSIENT, may be passed to indicate that the
> object is to be copied prior to the return from sqlite3_bind_*(). The
> object and pointer to it must remain valid until then. SQLite will then
> manage the lifetime of its private copy."*

The constants: `SQLITE_STATIC` is `(sqlite3_destructor_type)0`,
`SQLITE_TRANSIENT` is `(sqlite3_destructor_type)-1` (`sqlite3.h`:6354–6355).

*Why the driver cannot use STATIC.* The buffer would be an Avra box. A
bind call is a runtime row (`CallRt`), and **a runtime row borrows its
arguments** — this project's own convention: `retained_args` retains for
`.Call`/`.CallPtr` only. So a `bind_text` with `SQLITE_STATIC` inside a
helper function hands SQLite a pointer that the helper's scope exit
releases, and the next `step` reads freed memory. There is no annotation
today that makes Avra hold it.

*The defence.* **Bind `SQLITE_TRANSIENT`, always, until the FFI ownership
annotations exist.** The escape, when they land, is precisely
`@borrows(param)` — "the C function borrows the parameter for the duration
of the call; Avra retains ownership" — which is the `SQLITE_STATIC`
contract with a compile-checked lifetime. That is the P6 answer to "safe
or fast"; until then the answer is "safe", written at the site with the
reason.

*The cost.* One `memcpy` per bind. Negligible for a 40-byte string;
10 MB per bind for a 10 MB blob — which is what T33's `zeroblob` +
incremental I/O path exists to avoid.

*Whose.* DRIVER; the cost is documented to the CALLER for large blobs.

---

**T28 — THE BIND DESTRUCTOR RUNS EVEN WHEN THE BIND FAILS — EXCEPT IN TWO
CASES.**

*Behaviour.* `DOC`, verbatim: *"A destructor to dispose of the BLOB or
string after SQLite has finished with it may be passed. It is called to
dispose of the BLOB or string even if the call to the bind API fails,
except the destructor is not called if the third parameter is a NULL
pointer or the fourth parameter is negative."*

*The naive failure.* A driver that later adds a custom destructor (to hand
SQLite an Avra box directly and release it on SQLite's schedule) leaks
exactly on the paths where the pointer is NULL or the length is negative —
which are the empty-value and the "let strlen decide" paths, i.e. the two
this document already flags as traps.

*The defence.* If a custom destructor is ever used, the driver never
passes a NULL pointer or a negative length to a bind. Which is already
T90's and T96's rule.

*Whose.* DRIVER.

---

**T29 — A BIND WITH A NULL POINTER IS `bind_null`, NOT AN EMPTY VALUE.**

*Behaviour.* `DOC`, verbatim: *"If the third parameter to
sqlite3_bind_text() or sqlite3_bind_text16() or sqlite3_bind_blob() is a
NULL pointer then the fourth parameter is ignored and the end result is
the same as sqlite3_bind_null()."*

*Why.* The NULL pointer is spent as the encoding of absence — the exact
shape of this project's standing law, **an encoding spends the empty
value**, on the bind side.

*The naive failure.* An empty Avra `Bytes` whose backing pointer is NULL
(a plausible representation for a zero-length buffer) binds SQL NULL. The
program wrote an empty blob and the database holds an absence. The write
succeeds, and the bug surfaces at read time as a NOT NULL violation or as
`null` in a non-nullable seat.

*The defence.* **Write the empty case first.** The driver's bind verb
asserts a non-NULL pointer for every non-null value, and mints a
one-byte-backed zero-length buffer if its own representation would
otherwise be NULL. A test binds an empty string and an empty blob and
asserts `typeof` is `text`/`blob` and not `null` — see T97 for the
matching read-side test.

*Whose.* DRIVER.

---

**T30 — `sqlite3_errmsg()`'s BUFFER IS BORROWED AND CONNECTION-SCOPED.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`:4199–4202): *"Memory to hold the
error message string is managed internally. The application does not need
to worry about freeing the result. However, the error string might be
overwritten or deallocated by subsequent calls to other SQLite interface
functions."*

*The naive failure.* A driver that stores the `const char*` in its error
value and returns it up the stack hands the caller a pointer the next
query rewrites — and, per T26, a pointer with no Avra header at all.

*The defence.* Copy the message into an Avra box **at the moment of the
error, before any other SQLite call — including the `reset` in the
`defer`.** See T85 for the ordering rule this implies.

*Whose.* DRIVER.

---

**T31 — A RESULT COLUMN'S NAME IS ALSO A BORROWED POINTER, AND IS
UNSPECIFIED WITHOUT `AS`.**

*Behaviour.* `DOC` (c3ref/column_name.html): the returned string is valid
until `finalize`, until the statement is automatically re-prepared by the
next `step`, or until the next `column_name` call on the same column; and
*"If there is no AS clause then the name of the column is unspecified and
may change from one release of SQLite to the next."*

*The naive failure.* A name→index map built once and consulted after a
schema change reads freed memory. And a driver that maps result columns to
row fields **by name** breaks on `SELECT a+b FROM t` across a version bump.

*The defence.* Map by **index**. Expose names as owned copies taken once,
immediately after prepare. The driver's own generated SQL always writes
`AS`.

*Whose.* DRIVER.

---

**T32 — THE 32-BIT `sqlite3_column_int` / `sqlite3_bind_int` SPLIT.**

*Behaviour.* `DOC`: `sqlite3_column_int()` returns a 32-bit `int`;
`sqlite3_column_int64()` returns `sqlite3_int64`. Rowids are 64-bit
(`sqlite3.h`: *"Each entry in most SQLite tables … has a unique 64-bit
signed integer key called the rowid"*).

*The naive failure.* Using `column_int` on a rowid truncates every id
above 2^31 to a wrong 32-bit value, silently. Avra's `int` is 64-bit, so
the truncation is pure loss with no compensating benefit.

*The defence.* **The driver never links `sqlite3_column_int` or
`sqlite3_bind_int`.** Only the `_int64` forms appear in the FFI surface, so
the mistake is unrepresentable. Same for `sqlite3_changes` vs
`_changes64` and `sqlite3_total_changes` vs `_total_changes64`.

*Whose.* DRIVER, enforced by omission from the extern list.

---

**T33 — A BLOB LARGER THAN MEMORY NEEDS `zeroblob` + INCREMENTAL I/O, AND
THE HANDLE HAS ITS OWN LIFETIME RULES.**

*Behaviour.* `DOC` (c3ref/blob_open.html, bind_blob.html):
`bind_zeroblob(N)` *"binds a BLOB of length N that is filled with zeroes …
intended to serve as placeholders for BLOBs whose content is later written
using incremental BLOB I/O"*, and *"A negative value for the zeroblob
results in a zero-length BLOB"*. Then:

- `blob_open` works only on a real **rowid table** column — not a view,
  not a virtual table, not `WITHOUT ROWID`; in write mode, not an indexed
  / PRIMARY KEY / UNIQUE column, and not a child key column with foreign
  keys enabled.
- *"If the row that a BLOB handle points to is modified by an UPDATE,
  DELETE, or by ON CONFLICT side-effects then the BLOB handle is marked as
  'expired'"* and subsequent reads/writes *"fail with a return code of
  SQLITE_ABORT"*.
- *"Writes to the BLOB that occurred before the BLOB handle expired are
  not rolled back by the expiration of the handle."*
- *"The size of a blob may not be changed by this interface."*
- An unclosed handle keeps `sqlite3_close()` returning `SQLITE_BUSY`
  (T80).

*The naive failure.* Three, stacked: a driver without `zeroblob` bounds
the maximum writable blob by RAM rather than by `SQLITE_MAX_LENGTH`; a
driver that treats `SQLITE_ABORT` from `blob_write` as "nothing was
written" and retries from offset 0 **double-writes the prefix**; and a
leaked handle pins the connection open forever.

*The defence.* Expose `zeroblob(N)` + a streaming handle as an explicit,
separately-named path. The handle is an `opaque type` with
`@free_with(sqlite3_blob_close)`. `SQLITE_ABORT` from a blob operation
maps to a distinct error variant whose help says "re-open the handle and
restart", never to a generic failure. The size is fixed at `zeroblob`
time, so the caller must know it up front — say so in the verb's contract.

*Whose.* DRIVER provides; CALLER must know the size in advance.

---

# Part 4 — THE STATEMENT LIFECYCLE (T34–T48)

```
prepare_v2/v3  →  bind*  →  step ⇄ column*  →  reset  →  (bind* → step …)
                                              ↘ clear_bindings
                                                    ↘ finalize
```

---

**T34 — USE `prepare_v2` OR `_v3`, NEVER `sqlite3_prepare`, AND THE REASON
IS THE ERROR CHANNEL.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, step block):

> *"Goofy Interface Alert: In the legacy interface, the sqlite3_step() API
> always returns a generic error code, SQLITE_ERROR, following any error
> other than SQLITE_BUSY and SQLITE_MISUSE. You must call sqlite3_reset()
> or sqlite3_finalize() in order to find one of the specific error codes
> that better describes the error. We admit that this is a goofy design.
> The problem has been fixed with the "v2" interface."*

And: *"In the legacy interface, the return value will be either
SQLITE_BUSY, SQLITE_DONE, SQLITE_ROW, SQLITE_ERROR, or SQLITE_MISUSE. With
the "v2" interface, any of the other result codes or extended result codes
might be returned as well."*

*Why.* v2/v3 also **re-prepare automatically** when the schema changes, so
`SQLITE_SCHEMA` is never returned to the application.

*The naive failure.* Under v1, a UNIQUE violation, a NOT NULL violation
and a foreign key violation are all `SQLITE_ERROR` at `step`. The driver's
error enum is one branch wide, and the specific code is only available
after a `reset` the driver has probably already discarded.

*The defence.* `sqlite3_prepare_v3` exclusively, with
`SQLITE_PREPARE_PERSISTENT` for cached statements (T157).

*Whose.* DRIVER.

---

**T35 — PASS AN EXPLICIT `nByte`, NEVER `-1`.**

*Behaviour.* `DOC`: a negative `nByte` means "read to the first zero
terminator". `DOC` also notes that passing the length *including* the
terminator lets SQLite avoid a copy in some cases.

*Why it matters here.* Avra's string header already carries the length, so
passing it costs nothing, and `strlen` per prepare costs a scan. More
importantly, SQL text holding an embedded NUL (which Avra strings *can*
hold — see T105) is truncated at prepare with no diagnostic.

*The defence.* Always pass the header's length.

*Whose.* DRIVER.

---

**T36 — `prepare` COMPILES ONLY THE FIRST STATEMENT; `pzTail` IS THE ONLY
WAY TO RUN A SCRIPT.**

*Behaviour.* `DOC` (c3ref/prepare.html): *"These routines only compile the
first statement in zSql."*

*The naive failure.* A migration file of six `CREATE TABLE`s silently
applies one, and the driver reports success.

*The defence.* A `script`/`migrate` verb loops on `pzTail` until the
remaining text is exhausted, and checks each statement's result.

*Whose.* DRIVER.

---

**T37 — COMMENT-ONLY OR EMPTY SQL PREPARES TO A NULL STATEMENT AND
`SQLITE_OK`.**

*Behaviour.* `DOC` (c3ref/prepare.html): *"if the input text contains no
SQL (if the input is an empty string or a comment) then *ppStmt is set to
NULL."* — and the return is `SQLITE_OK`.

*Why.* This is the empty-value law again (T96): "no statement" is encoded
as the NULL pointer, and the success code is unchanged.

*The naive failure.* Two symmetric bugs. The `pzTail` loop of T36
dereferences a NULL statement on the trailing newline or trailing comment
of a migration file. Or, defending against that, it treats NULL as an
error and refuses every file that ends in a comment.

*The defence.* **Write the empty case first.** `prepare` returning OK with
a NULL statement means "nothing to run" — skip it and continue the loop.
A test runs a migration file that ends in `-- done\n`.

*Whose.* DRIVER.

---

**T38 — PARAMETER INDICES ARE 1-BASED; COLUMN INDICES ARE 0-BASED.**

*Behaviour.* `DOC`, verbatim: *"The leftmost SQL parameter has an index of
1"*; *"The leftmost column of the result set has the index 0."*

*The naive failure.* An off-by-one that is invisible in a one-column,
one-parameter test and wrong everywhere else.

*The defence.* No caller ever spells an index. Parameters are bound **by
name** through `sqlite3_bind_parameter_index()`; columns are addressed by
the row type's field order. The two bases exist in exactly one file.

*Whose.* DRIVER.

---

**T39 — A REPEATED NAMED PARAMETER IS ONE INDEX; `?NNN` SETS ITS OWN.**

*Behaviour.* `DOC`, verbatim: *"When the same named SQL parameter is used
more than once, second and subsequent occurrences have the same index as
the first occurrence."* And: *"The index for "?NNN" parameters is the value
of NNN."*

*The naive failure.* A driver that counts occurrences rather than asking
`sqlite3_bind_parameter_count()` binds the wrong argument to the second
use of `:id`. And a query mixing `?` with `?5` produces a sparse parameter
space where `bind_parameter_count()` answers 5 for two visible parameters.

*The defence.* Bind by name; validate with
`sqlite3_bind_parameter_count()` against the arguments supplied (T40); and
the driver's own generated SQL uses named parameters exclusively.

*Whose.* DRIVER.

---

**T40 — AN UNBOUND PARAMETER IS NULL, SILENTLY.**

*Behaviour.* `DOC` (c3ref/bind_blob.html): unbound parameters are NULL.

*The naive failure.* A forgotten bind inserts NULL. If there is a `NOT
NULL` constraint the error arrives at step time, blaming the statement; if
there is not, the row is written with a hole and nothing is reported ever.

*The defence.* The driver counts `sqlite3_bind_parameter_count()` against
the arguments it was given and **refuses a short call before stepping**,
naming the missing parameter.

*Whose.* DRIVER.

---

**T41 — `reset` DOES NOT CLEAR BINDINGS. `clear_bindings` DOES.**

*Behaviour.* `DOC`, verbatim, and stated **twice** in the same block
(`sqlite3.h`, reset): *"Any SQL statement variables that had values bound
to them using the sqlite3_bind_blob | sqlite3_bind_*() API retain their
values. Use sqlite3_clear_bindings() to reset the bindings."* … *"The
sqlite3_reset(S) interface does not change the values of any
sqlite3_bind_blob|bindings on the prepared statement S."*

*Why.* Reuse: rebinding one parameter and re-stepping is the fast path for
a bulk insert, and clearing would force a full rebind every time.

*The naive failure.* **A data-corruption bug that passes every test where
all parameters are always bound.** A cached statement reused for a second
insert with only *some* parameters rebound writes the previous row's
values into the unbound slots. The rows are all valid; some of them are
another row's data.

*The defence.* Two rules, and the driver picks the second. (a) Always
rebind every parameter — which T40's count check enforces. (b) Call
`clear_bindings` on every `reset` of a **cached** statement, so a partially
bound reuse fails loudly at T40 instead of silently. The cost of
`clear_bindings` is a loop over the parameter array; it is paid once per
statement reuse, not per row of output.

*Whose.* DRIVER.

---

**T42 — WHAT `step` RETURNS, AND WHAT EACH OBLIGES.**

| Code | # | Meaning | The driver's move |
|---|---|---|---|
| `SQLITE_ROW` | 100 | a row is available | read columns (T20), step again |
| `SQLITE_DONE` | 101 | finished successfully | `reset` before any further use |
| `SQLITE_BUSY` | 5 | could not get the lock | see T43 — **not** a plain retry inside a transaction |
| `SQLITE_ERROR` and every other code | | run-time error | do not step again; `reset` to reclaim, after reading the error (T85) |
| `SQLITE_MISUSE` | 21 | the API was used wrongly | a **driver defect**, never a caller error (T46) |

`DOC`, verbatim on DONE: *"sqlite3_step() should not be called again on
this virtual machine without first calling sqlite3_reset() to reset the
virtual machine back to its initial state."*
And on ERROR: *"sqlite3_step() should not be called again on the VM."*

*Whose.* DRIVER.

---

**T43 — THE DOCUMENTED RETRY RULE FOR `SQLITE_BUSY` FROM `step` DEPENDS ON
WHETHER YOU ARE IN A TRANSACTION.**

*Behaviour.* `DOC`, verbatim: *"SQLITE_BUSY means that the database engine
was unable to acquire the database locks it needs to do its job. If the
statement is a COMMIT or occurs outside of an explicit transaction, then
you can retry the statement. If the statement is not a COMMIT and occurs
within an explicit transaction then you should rollback the transaction
before continuing."*

*Why.* Inside a transaction the connection is already holding locks, so
waiting can deadlock (T55). The only way to release them is to roll back.

*The naive failure.* The universal wrong retry loop: `while step() ==
SQLITE_BUSY { sleep(); }` inside a transaction. It spins for the full
timeout and then fails anyway, having held its own locks throughout and
blocked everyone else — the retry *causes* the contention it is waiting on.

*The defence.* The driver's retry policy is a two-arm decision made from
`sqlite3_get_autocommit()` (or `sqlite3_txn_state()`), not from the code
alone: outside a transaction, or on a COMMIT → retry under the busy
policy. Inside a transaction, and not a COMMIT → **roll back and re-run
the whole transaction body**, or return the error.

*Whose.* DRIVER decides retry-vs-rollback; the CALLER's transaction body
must be re-runnable, which the `tx` verb's contract must state.

---

**T44 — SINCE 3.6.23.1 `step` AUTO-RESETS INSTEAD OF RETURNING
`SQLITE_MISUSE` — UNLESS THE BUILD SAYS OTHERWISE.**

*Behaviour.* `DOC`, verbatim: *"For all versions of SQLite up to and
including 3.6.23.1, a call to sqlite3_reset() was required after
sqlite3_step() returned anything other than SQLITE_ROW before any
subsequent invocation of sqlite3_step(). Failure to reset the prepared
statement using sqlite3_reset() would result in an SQLITE_MISUSE return
from sqlite3_step(). But after version 3.6.23.1, sqlite3_step() began
calling sqlite3_reset() automatically in this circumstance rather than
returning SQLITE_MISUSE. This is not considered a compatibility break
because any application that ever receives an SQLITE_MISUSE error is
broken by definition. The SQLITE_OMIT_AUTORESET compile-time option can be
used to restore the legacy behavior."*

*The naive failure.* A driver that relies on the auto-reset behaves
differently on a build with `SQLITE_OMIT_AUTORESET`. Since the driver
vendors its own amalgamation this is controllable — but only if someone
decides it.

*The defence.* Do not set `SQLITE_OMIT_AUTORESET`, **and** reset
explicitly anyway, so the driver's behaviour does not depend on the flag.

*Whose.* DRIVER (build config + explicit reset).

---

**T45 — `reset` RETURNS AN ERROR CODE THAT `step` MAY NEVER HAVE SHOWN
YOU.**

*Behaviour.* `DOC`, verbatim: *"The sqlite3_reset(S) interface might also
return an error code if there were no prior errors but the process of
resetting the prepared statement caused a new error. For example, if an
INSERT statement with a RETURNING clause is only stepped one time, that
one call to sqlite3_step(S) might return SQLITE_ROW but the overall
statement might still fail and the sqlite3_reset(S) call might return
SQLITE_BUSY if locking constraints prevent the database change from
committing. Therefore, it is important that applications check the return
code from sqlite3_reset(S) even if no prior call to sqlite3_step(S)
indicated a problem."*

*Why.* A `RETURNING` clause produces its row before the statement's
effects are committed. The failure has nowhere else to appear.

*The naive failure.* A driver that runs `reset` in a `defer` and discards
its return reports **success** for an `INSERT … RETURNING` whose write did
not land, and hands the caller the returned row as proof.

*The defence.* `reset`'s return is checked and, if non-OK, becomes the
operation's error — even on the success path. This is the single strongest
argument against putting `reset` in a fire-and-forget `defer`.

*Whose.* DRIVER.

---

**T46 — `SQLITE_MISUSE` MEANS "YOU HAVE A BUG", NOT "THE QUERY FAILED".**

*Behaviour.* `DOC`, verbatim: *"SQLITE_MISUSE means that the this routine
was called inappropriately. Perhaps it was called on a prepared statement
that has already been finalized or on one that had previously returned
SQLITE_ERROR or SQLITE_DONE. Or it could be the case that the same
database connection is being used by two or more threads at the same
moment in time."* And, on the auto-reset change: *"any application that
ever receives an SQLITE_MISUSE error is broken by definition."*

Also `DOC` (`sqlite3.h`:4226–4229): when an interface is misused, *"the
error code and message may or may not be set"* — so `errmsg` may describe
an unrelated earlier failure.

*The naive failure.* A driver that maps `SQLITE_MISUSE` into its public
error enum teaches callers to retry their way past the driver's own bug,
and hands them a stale error message while doing it.

*The defence.* `SQLITE_MISUSE` goes to the same channel as this project's
`lower_defect` — a named, unignorable internal defect that names the
driver, not the query. It is never a `Result::Err` a caller is expected to
handle.

*Whose.* DRIVER, as a defect.

---

**T47 — BINDING A STEPPED-BUT-UNRESET STATEMENT IS A MISUSE, AND THE
API MUST MAKE IT UNREPRESENTABLE.**

*Behaviour.* `INFERRED` from T46's quote plus the bind block: a bind
against a statement mid-iteration is exactly the "called inappropriately"
case.

*The naive failure.* A driver that hands out a `Row` or `Cursor` object
holding the live statement and lets the caller rebind mid-iteration.

*The defence.* Same structural answer as T23: the statement is never
reachable from a value the caller holds during iteration. A rebind is only
possible through the driver's own reset-then-bind path.

*Whose.* DRIVER, enforced by API shape.

---

**T48 — `prepare_v2`/`v3` SILENTLY RE-PREPARE ON A SCHEMA CHANGE, AND THE
STATEMENT'S SHAPE CAN CHANGE UNDER A CACHE.**

*Behaviour.* `DOC` (c3ref/prepare.html): the v2/v3 interfaces re-prepare
automatically, so `SQLITE_SCHEMA` is never returned. `INFERRED`
consequence: the column count, the column names and the decltypes may all
differ across a re-prepare, because the statement was compiled against a
different schema.

*The naive failure.* A driver that caches a decoded row **shape** — the
column-count, the name→index map, the per-column decoder — alongside a
cached statement decodes the new schema with the old shape after an
`ALTER TABLE`. `SELECT *` is the sharp case: a dropped column shifts every
index.

*The defence.* Either (a) re-read `sqlite3_column_count()` at each
`SQLITE_ROW` and compare against the cached shape, or (b) invalidate the
whole statement cache when `PRAGMA schema_version` changes. (b) is one
integer read per transaction and is the cheaper of the two. **And the
driver's generated SQL never uses `SELECT *`** — an explicit column list
makes the shape a property of the query text, which is the cache key.

*Whose.* DRIVER.

---

# Part 5 — BUSY, LOCKED AND CONCURRENCY (T49–T61)

**T49 — `SQLITE_BUSY` IS ANOTHER CONNECTION; `SQLITE_LOCKED` IS *THIS*
CONNECTION. ONE IS RETRYABLE AND THE OTHER NEVER IS.**

*Behaviour.* `DOC` (rescode.html): `SQLITE_BUSY` (5) — *"database file
cannot be written (or read) because of concurrent activity by some other
database connection, usually a database connection in a separate
process"*. `SQLITE_LOCKED` (6) — a write conflict **within the same
database connection**, or between two connections sharing a shared cache.

*The naive failure.* A retry loop that treats `SQLITE_LOCKED` as retryable
spins forever, because the conflicting lock is held by the loop's own
connection and will never clear on its own. This is a hang, not an error —
the worst failure shape there is.

*The defence.* `SQLITE_BUSY` is retryable under policy (T43).
`SQLITE_LOCKED` is a **program-structure error**, reported immediately,
with help naming the usual cause: writing to a table while a `SELECT` over
it is still stepping. (isolation.html says the same fact from the other
side: modifying a table while a `SELECT` over it is in progress is
*undefined*, and *"developers should diligently avoid writing applications
that make assumptions about what will occur in that circumstance"*.)

*Whose.* DRIVER classifies; CALLER fixes a `LOCKED`.

---

**T50 — THE FIVE LOCK STATES, AND WHY OPENING MORE CONNECTIONS MAKES
CONTENTION WORSE.**

*Behaviour.* `DOC` (lockingv3.html): UNLOCKED → SHARED (readers, many) →
RESERVED (one intending writer, still reading) → PENDING (waiting for
readers to drain; **new readers are refused**) → EXCLUSIVE (writing).

*Why PENDING exists.* Writer starvation. *"The PENDING lock allows
existing readers to continue but prevents new readers from connecting to
the database."*

*The naive failure.* A driver whose retry strategy is "open a fresh
connection and try again" **is** the starvation it is trying to escape:
against a database with a waiting writer, new readers are refused by the
PENDING lock, so the retry sees `SQLITE_BUSY` and the loop spins. A
connection pool sized to "more parallelism" makes a write-contended
database slower, not faster.

*The defence.* One writer connection, reused. Readers may be pooled under
WAL (T51) and should not be under a rollback journal.

*Whose.* DRIVER's connection model.

---

**T51 — WAL GIVES READERS-DON'T-BLOCK-WRITERS, AND CHARGES FOR IT.**

*Behaviour.* `DOC` (wal.html). The guarantee: *"Writers and readers can
run at the same time. However, since there is only one WAL file, there can
only be one writer at a time."* The costs, each documented:

| Cost | Quote / fact |
|---|---|
| Two extra files | `-wal` and `-shm` beside the database. `MEASURED`: after `PRAGMA journal_mode=WAL`, a 32768-byte `a.db-shm` and a 0-byte `a.db-wal` appear. |
| One host only | *"All processes using a database must be on the same host computer; WAL does not work over a network filesystem."* |
| WAL/db separation is corruption | *"If a database file is separated from its WAL file, then transactions that were previously committed might be lost, or the database file might become corrupted."* |
| Checkpoint starvation | *"no checkpoints will be able to complete and hence the WAL file will grow without bound"* under continuously overlapping readers |
| Large transactions | *"WAL does not work well for very large transactions … WAL mode may fail with an I/O or disk-full error"* past a gigabyte |
| Read perf decays | read performance deteriorates as the WAL grows |
| `page_size` frozen | cannot be changed while in WAL mode |
| Read-only media | needs `-shm`; since 3.22.0 a read-only WAL database works only if `-shm`/`-wal` already exist, the directory is writable, or `immutable=1` is used |

*The naive failure.* A driver that sets WAL unconditionally breaks any
deployment whose database lives on NFS/SMB — and the failure presents as
corruption or `SQLITE_IOERR_SHMOPEN`, **not** as "WAL is unsupported here".

*The defence.* WAL is the driver's *offered* default with a documented
opt-out, and the pragma's answer is **checked** (T137).

*Whose.* DRIVER default; CALLER opts out for network storage.

---

**T52 — `journal_mode=WAL` IS PERSISTENT: SETTING IT CHANGES THE FILE FOR
EVERY FUTURE CONNECTION.**

*Behaviour.* `DOC`: *"Unlike the other journaling modes, PRAGMA
journal_mode=WAL is persistent. If a process sets WAL mode, then closes
and reopens the database, the database will come back in WAL mode."*
`MEASURED`:

```
$ sqlite3 a.db "PRAGMA journal_mode=WAL; CREATE TABLE t(x); INSERT INTO t VALUES(1);"
wal
$ sqlite3 a.db "PRAGMA journal_mode;"     ← a NEW process
wal
```

*The naive failure.* A driver that sets WAL "for its own connection" has
in fact converted the user's database file, permanently, for every other
tool that opens it — including tools on older SQLite versions, and
including the user's `sqlite3` shell on a network mount.

*The defence.* Setting WAL is a **file-level side effect** and belongs in
the open verb's documented contract, not in a silent default. The driver
states it at the open verb (P7, visible magic).

*Whose.* DRIVER discloses; CALLER decides.

---

**T53 — WAL DOES NOT ABOLISH `SQLITE_BUSY`.**

*Behaviour.* `DOC` (wal.html): busy still occurs when *"another database
connection has the database mode open in exclusive locking mode"*, during
cleanup when the last connection closes, and during recovery after a
crash. Plus the promotion case (T71).

`MEASURED`, the rollback-journal case, showing that a *reader* is not
blocked by a writer's RESERVED lock but a second *writer* is:

```
# connection A holds: BEGIN IMMEDIATE; INSERT ...;   (not yet committed)
$ sqlite3 busy.db "INSERT INTO t VALUES(3);"
Error: stepping, database is locked (5)          ← second writer, immediate
$ sqlite3 busy.db "SELECT count(*) FROM t;"
1                                                ← reader succeeds, pre-txn snapshot
```

*The defence.* Never document "WAL means no BUSY". The busy policy applies
in every journal mode.

*Whose.* DRIVER.

---

**T54 — `busy_timeout` AND `busy_handler` REPLACE EACH OTHER.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, busy_handler block): *"There can
only be a single busy handler defined for each database connection.
Setting a new busy handler clears any previously set handler. Note that
calling sqlite3_busy_timeout() or evaluating PRAGMA busy_timeout=N will
change the busy handler and thus clear any previously set busy handler."*
And: *"Calling this routine with an argument less than or equal to zero
turns off all busy handlers."*

*The naive failure.* A driver that sets a default `busy_timeout` at open
and later installs a caller's custom handler (or the reverse) silently
drops one of them, and the program's concurrency behaviour is whichever
call happened last.

*The defence.* The driver owns *one* slot. A caller either sets a timeout
or supplies a handler, never both, and the API makes that exclusive.

*Whose.* DRIVER, by API shape.

---

**T55 — THE BUSY HANDLER IS NOT GUARANTEED TO RUN, AND THE REASON IS
DEADLOCK.**

*Behaviour.* `DOC`, verbatim and worth reading in full:

> *"The presence of a busy handler does not guarantee that it will be
> invoked when there is lock contention. If SQLite determines that invoking
> the busy handler could result in a deadlock, it will go ahead and return
> SQLITE_BUSY to the application instead of invoking the busy handler.
> Consider a scenario where one process is holding a read lock that it is
> trying to promote to a reserved lock and a second process is holding a
> reserved lock that it is trying to promote to an exclusive lock. The
> first process cannot proceed because it is blocked by the second and the
> second process cannot proceed because it is blocked by the first. If both
> processes invoke the busy handlers, neither will make any progress.
> Therefore, SQLite returns SQLITE_BUSY for the first process, hoping that
> this will induce the first process to release its read lock and allow the
> second process to proceed."*

*The naive failure.* A driver that documents "we retry for you, we set a
busy timeout" is wrong **exactly in the case that matters** — the
read-then-write transaction of T71. The busy timeout smooths transient
contention; it cannot save a held lock, and the case it cannot save is the
common one.

*The defence.* `BEGIN IMMEDIATE` (T71) is the real fix; the busy timeout
is the smoothing on top. Say so in the documentation, because callers will
otherwise assume the timeout is the answer.

*Whose.* DRIVER; disclosed to the CALLER.

---

**T56 — THE BUSY HANDLER IS NOT REENTRANT AND MUST NOT TOUCH THE
CONNECTION.**

*Behaviour.* `DOC`, verbatim: *"The busy callback should not take any
actions which modify the database connection that invoked the busy
handler. In other words, the busy handler is not reentrant. Any such
actions result in undefined behavior. A busy handler must not close the
database connection or prepared statement that invoked the busy handler."*

*The naive failure.* A handler that logs contention *into the same
database*. Undefined behaviour, reached only under load, in production.

*The defence.* If Avra callbacks across the FFI boundary ever exist, the
busy-handler seat's contract forbids touching the connection, and the
driver's own default handler is `busy_timeout` — which is implemented
inside SQLite and cannot re-enter.

*Whose.* DRIVER's contract on a CALLER-supplied handler.

---

**T57 — A BUSY HANDLER MUST NOT BE USED WITH A SHARED CACHE.**

*Behaviour.* `DOC` (c3ref/busy_handler.html and sharedcache.html): with
shared cache enabled, contention between connections sharing the cache
surfaces as `SQLITE_LOCKED_SHAREDCACHE` (262), which the busy handler does
not and cannot resolve — the blocking connection is inside the same cache
and is not going to release on a timer. The documented mechanism for that
case is the unlock-notify API, not a busy handler.

*The naive failure.* A driver that enables shared cache "for efficiency"
and keeps its busy timeout turns every intra-cache conflict into a full
timeout followed by a failure.

*The defence.* **The driver does not enable shared cache.** It is
documented by SQLite itself as discouraged for new code, its
`SQLITE_LOCKED_SHAREDCACHE` behaviour is a different error model, and
`:memory:` sharing (its main remaining use) is better served by
`file::memory:?cache=shared` chosen explicitly by a caller who wants it
(T131).

*Whose.* DRIVER, by omission.

---

**T58 — THE ONE-WRITER RULE IS A PROPERTY OF THE FILE, NOT OF THE
PROCESS.**

*Behaviour.* `DOC` (faq.html): *"Multiple processes can have the same
database open at the same time. Multiple processes can be doing a SELECT
at the same time. But only one process can be making changes to the
database at any moment in time, however."*

*The naive failure.* A service that scales writes by scaling processes.
Throughput does not increase; contention does.

*The defence.* The driver's documentation states the rule at the top, and
the write path is shaped so batching (T152) is the obvious way to get
throughput rather than concurrency.

*Whose.* CALLER's architecture, informed by the driver.

---

**T59 — CHECKPOINTING IS A LATENCY SPIKE CHARGED TO A RANDOM WRITER.**

*Behaviour.* `DOC` (wal.html): the automatic checkpoint threshold is 1000
pages (≈4 MB at the 4096-byte default). PASSIVE *"does as much work as it
can without interfering with other database connections"*; FULL, RESTART
and TRUNCATE are progressively more aggressive and can block.

*The naive failure.* Whichever commit happens to cross the threshold pays
the entire WAL-to-database copy. A service measuring p99 write latency
sees an unexplained spike proportional to WAL size.

*The defence.* Leave `wal_autocheckpoint` at its default for general use.
Expose it, and expose `wal_checkpoint(TRUNCATE)`, so a latency-sensitive
service can disable autocheckpointing and checkpoint on its own schedule.

*Whose.* CALLER's choice; DRIVER exposes both.

---

**T60 — CHECKPOINT STARVATION TURNS A 4 MB WAL INTO AN UNBOUNDED ONE.**

*Behaviour.* `DOC` (wal.html): *"If a database has many concurrent
overlapping readers and there is always at least one active reader, then
no checkpoints will be able to complete and hence the WAL file will grow
without bound."*

*The naive failure.* A connection pool that holds long-lived read
transactions — an ORM "session" spanning a request, or a driver that leaves
a cursor open across a caller's turn boundary — prevents every checkpoint.
Disk fills; read performance decays continuously as it does.

*The defence.* **A read transaction is a resource with a lifetime.** The
driver's read verb never leaves one open across a turn boundary: a query
either materialises its rows or holds the cursor within a scope that the
driver closes. Any API that hands out a long-lived cursor documents this
cost at the site.

*Whose.* DRIVER's API shape.

---

**T61 — WAL2 IS NOT IN THE MAINLINE BUILD, AND ASKING FOR IT SUCCEEDS
SILENTLY.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 a.db "PRAGMA journal_mode=WAL2;"
wal                                        ← not wal2; no error
```

WAL2 exists only on SQLite's `wal2` branch. On a mainline build the
pragma is not an error — it answers the mode actually in force.

*Why.* `PRAGMA journal_mode=X` always answers the resulting mode, and an
unrecognised mode name leaves the current one alone.

*The naive failure.* A driver that runs `PRAGMA journal_mode=WAL2` and
ignores the result reports WAL2 and runs WAL. Generalised, this is T137:
**a pragma's answer is data, and discarding it is how a driver comes to
believe things about a database that are not true.**

*The defence.* Every mode-setting pragma the driver issues has its result
row read and compared against what was asked; a mismatch is a diagnostic,
not a shrug.

*Whose.* DRIVER.

---

# Part 6 — THREADING MODES (T62–T67)

**T62 — THE THREE MODES, AND THE EXACT RULE OF EACH.**

*Behaviour.* `DOC` (threadsafe.html):

| Mode | `SQLITE_THREADSAFE` | Rule |
|---|---|---|
| Single-thread | 0 | *"all mutexes are disabled and SQLite is unsafe to use in more than a single thread at once"* |
| Multi-thread | 2 | safe from many threads *"provided that no single database connection nor any object derived from database connection, such as a prepared statement, is used in two or more threads at the same time"* |
| Serialized | 1 (**the default**) | *"API calls to affect or use any SQLite database connection … can be made safely from multiple threads"* |

Note the numbering is not the ordering: **1 is serialized, 2 is
multi-thread.**

---

**T63 — YOU CAN DOWNGRADE AT RUNTIME BUT NEVER UPGRADE PAST THE
COMPILE-TIME SETTING.**

*Behaviour.* `DOC`: *"If single-thread mode is selected at compile-time,
then critical mutexing logic is omitted … and it is impossible to enable
either multi-thread or serialized modes at start-time or run-time."*
Start-time: `sqlite3_config()` with `SQLITE_CONFIG_SINGLETHREAD` /
`_MULTITHREAD` / `_SERIALIZED`. Per-connection: `SQLITE_OPEN_NOMUTEX`
(multi-thread) or `SQLITE_OPEN_FULLMUTEX` (serialized) at
`sqlite3_open_v2`.

*The naive failure.* Vendoring with `SQLITE_THREADSAFE=0` — which is on
SQLite's own *recommended compile options* list, and is right for a
single-threaded CLI — permanently forecloses ever running a connection
under a fiber scheduler or a second OS thread. There is no runtime fix.

*The defence.* See T65.

*Whose.* DRIVER's build config, decided once.

---

**T64 — `sqlite3_threadsafe()` REPORTS THE COMPILE-TIME SETTING ONLY.**

*Behaviour.* `DOC`, verbatim: *"The return value of the
sqlite3_threadsafe() interface is the value of SQLITE_THREADSAFE set at
compile-time. It does not reflect changes … made at runtime."*

*The naive failure.* A driver that reports its threading guarantee by
calling `sqlite3_threadsafe()` after a `sqlite3_config()` downgrade tells
the caller the opposite of the truth.

*The defence.* The driver knows what it configured; it reports that, and
uses `sqlite3_threadsafe()` only as a *floor check* at init (refuse to run
if the linked library was built single-threaded when the driver expects
otherwise).

*Whose.* DRIVER.

---

**T65 — FOR A SYNCHRONOUS, NO-ASYNC-RUNTIME LANGUAGE, BUILD
`SQLITE_THREADSAFE=2` AND ENFORCE ONE OWNER STRUCTURALLY.**

*The argument.* Three options, and only one survives:

- **`=0` (single-thread).** Rejected. It disables the **global** mutexes
  too, so two OS threads touching two *different* connections corrupt
  SQLite's shared allocator state. Avra targets autonomous services (P2);
  a library that cannot survive a second thread anywhere in the process is
  not a substrate.
- **`=1` (serialized, the default).** Rejected as a default. It acquires
  and releases a mutex on every one of the millions of `column_*` calls in
  a scan — a measurable per-row cost bought to defend against a sharing
  pattern the driver's API does not permit anyway.
- **`=2` (multi-thread).** **Chosen.** Global structures are mutexed; the
  per-connection mutex is not taken. The rule it imposes — no connection
  or derived object used by two threads *at the same time* — is exactly
  the rule the driver already enforces by API shape (T23, T47).

*The residual uncertainty, marked.* `INFERRED`: mode 2 permits *moving*
a connection between OS threads as long as use is never simultaneous.
threadsafe.html states the constraint as *"at the same time"*, which is a
simultaneity constraint rather than a thread-affinity one, but it does not
say so explicitly. If a fiber scheduler is ever introduced, this must be
re-verified before a connection is allowed to migrate — and the safe
interim is one connection, one thread, for its whole life.

*Whose.* DRIVER's build config; the constraint is documented to the
CALLER.

---

**T66 — WHAT BREAKS IF A HANDLE CROSSES THREADS ANYWAY.**

*Behaviour.* `DOC`, three separate statements that all point at the same
hazard:

- *"It could be the case that the same database connection is being used
  by two or more threads at the same moment in time"* — a documented cause
  of `SQLITE_MISUSE`.
- *"If sqlite3_step() or sqlite3_reset() or sqlite3_finalize() are called
  from a different thread while any of these [column accessor] routines
  are pending, then the results are undefined."*
- `sqlite3_get_autocommit`: *"If another thread changes the autocommit
  status of the database connection while this routine is running, then
  the return value is undefined."*

Plus T88: the error message is *connection*-local, not thread-local, so a
second thread's failure can overwrite the message before the first thread
reads it.

*The naive failure.* Not a crash, usually. **A wrong answer**: an
undefined column read, a stale error message attributed to the wrong
query, an autocommit test that returns garbage and sends the transaction
wrapper down the wrong branch (T74).

*The defence.* One owner at a time, structurally (T65).

*Whose.* DRIVER.

---

**T67 — A CONNECTION IS NOT SENDABLE, AND AVRA CANNOT SAY SO TODAY.**

*Behaviour.* `INFERRED`. There is no Avra facility today that expresses a
"not Sync" or "one owner" constraint at the type level.

*The defence.* Until there is: the connection type carries the rule in its
documentation **and in its API shape** — there is no way to obtain two
live cursors on one connection, and no way to hand a live statement to
another owner. Shape is the only enforcement available, so it must carry
the whole weight.

*Whose.* DRIVER, until the language can help.

---

# Part 7 — TRANSACTION SEMANTICS (T68–T80)

**T68 — AUTOCOMMIT IS THE OBSERVABLE, AND IT IS THE ONLY WAY TO KNOW
WHETHER A TRANSACTION IS STILL OPEN.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, get_autocommit block):
*"Autocommit mode is on by default. Autocommit mode is disabled by a BEGIN
statement. Autocommit mode is re-enabled by a COMMIT or ROLLBACK."*

*Whose.* DRIVER.

---

**T69 — SOME ERRORS ROLL THE TRANSACTION BACK BY THEMSELVES, AND THE ONLY
WAY TO FIND OUT IS TO ASK.**

*Behaviour.* `DOC`, verbatim: *"If certain kinds of errors occur on a
statement within a multi-statement transaction (errors including
SQLITE_FULL, SQLITE_IOERR, SQLITE_NOMEM, SQLITE_BUSY, and SQLITE_INTERRUPT)
then the transaction might be rolled back automatically. The only way to
find out whether SQLite automatically rolled back the transaction after an
error is to use this function."*

Note the word: **might**.

`MEASURED`, what an unconditional rollback then produces:

```
$ sqlite3 :memory: "ROLLBACK;"
Error: stepping, cannot rollback - no transaction is active
```

*The naive failure.* A `tx` wrapper whose error path unconditionally
issues `ROLLBACK` gets "cannot rollback - no transaction is active" on top
of the real error and reports **that** to the caller. The original cause —
the disk-full, the I/O error — is lost, replaced by a message about
transaction bookkeeping.

*The defence.* On any error, ask `sqlite3_get_autocommit()` (or
`sqlite3_txn_state()`, T70); issue `ROLLBACK` **only** if a transaction is
still open. This is why the wrapper cannot be written blind, and it is
the first thing to test.

*Whose.* DRIVER.

---

**T70 — `sqlite3_txn_state()` IS THE FINER INSTRUMENT, AND IT
DISTINGUISHES READ FROM WRITE.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, txn_state block): states are
`SQLITE_TXN_NONE` (0), `SQLITE_TXN_READ` (1), `SQLITE_TXN_WRITE` (2).
*"The SQLITE_TXN_READ state means that the database is currently in a read
transaction. Content has been read from the database file but nothing in
the database file has changed. The transaction state will advanced to
SQLITE_TXN_WRITE if any changes occur and there are no other conflicting
concurrent write transactions."* With a NULL schema argument it returns
the highest state across all schemas; with an invalid schema name, −1.

*Why it matters.* It is the direct observable for T71 (a read transaction
that will need promoting) and for T77 (an open statement holding a read
transaction).

*The defence.* Use it in the `tx` wrapper's error path and in the driver's
diagnostics ("this connection is in a read transaction; the write will
need to promote"). Availability caveat: on this build it is annotated
`API_AVAILABLE(macos(12.0), …)`, i.e. it is version-gated in Apple's
system library — one more reason to vendor (T126).

*Whose.* DRIVER.

---

**T71 — THE UPGRADE DEADLOCK: `BEGIN DEFERRED` THAT READS THEN WRITES IS
THE MOST-REPORTED SQLITE PRODUCTION BUG.**

*Behaviour.* `DOC` (lang_transaction.html):

| Form | When the write lock is taken |
|---|---|
| `BEGIN` / `BEGIN DEFERRED` | at the first statement that needs it — *"the transaction does not actually start until the database is first accessed"* |
| `BEGIN IMMEDIATE` | at the `BEGIN`; *"might fail with SQLITE_BUSY if another write transaction is already active"* |
| `BEGIN EXCLUSIVE` | at the `BEGIN`, and also blocks readers; in WAL mode *"it behaves identically to IMMEDIATE"* |

A DEFERRED transaction that reads first and writes later must **promote**
its read lock, and promotion can fail with `SQLITE_BUSY_SNAPSHOT` (517),
documented as *"read transaction cannot be promoted to write
transaction"*.

*Why it is not retryable in place.* The reader's snapshot is stale.
Waiting cannot make it fresh; only rolling back and re-reading can. And
the busy handler will not even be invoked, because waiting here is the
deadlock case T55 describes.

*The naive failure.* `database is locked` under concurrency, from code
that looks entirely innocent — read a row, decide, write it back. A busy
timeout does not help. The bug is invisible in single-connection tests and
appears the moment there are two writers.

*The defence.* **The driver's `tx` verb is `BEGIN IMMEDIATE` by default**,
with `tx_read` (DEFERRED) as the explicitly-named read-only form. The
write lock is taken at the top, where a `SQLITE_BUSY` *is* retryable
(T43), instead of in the middle where it is not.

*Whose.* DRIVER's default; the CALLER opts into `tx_read`.

---

**T72 — `SQLITE_BUSY_SNAPSHOT` AND `SQLITE_ABORT_ROLLBACK` ARE THE TWO
CODES THAT MEAN "START OVER", NOT "WAIT".**

*Behaviour.* `DOC` (rescode.html) + `sqlite3.h`:535–567. The retry
classification, in full:

| Class | Codes | Action |
|---|---|---|
| Retryable after a bounded wait | `SQLITE_BUSY` (5, except `_SNAPSHOT`), `SQLITE_BUSY_RECOVERY` (261), `SQLITE_BUSY_TIMEOUT` (773), `SQLITE_PROTOCOL` (15) | wait, retry the statement |
| Retryable only after a full rollback and re-run | `SQLITE_BUSY_SNAPSHOT` (517), `SQLITE_ABORT_ROLLBACK` (516) | roll back, re-run the whole transaction body |
| Never retryable | everything else — specifically `SQLITE_LOCKED` (6), all `SQLITE_CONSTRAINT_*`, `SQLITE_MISUSE` (21), `SQLITE_CORRUPT` (11), all `SQLITE_READONLY_*`, `SQLITE_FULL` (13), `SQLITE_TOOBIG` (18), `SQLITE_RANGE` (25) | report |

*The naive failure.* A blanket retry on any non-OK code turns a constraint
violation into an infinite loop and a corrupt database into a hot spin.

*The defence.* The classification is a **registry** in the driver — every
code spelled, no catch-all — because a catch-all here silently
misclassifies the next extended code SQLite adds.

*Whose.* DRIVER.

---

**T73 — `COMMIT` CAN FAIL WITH `SQLITE_BUSY` AND LEAVE THE TRANSACTION
OPEN.**

*Behaviour.* `DOC` (lang_transaction.html): if COMMIT fails with
`SQLITE_BUSY`, *"the transaction remains active and the COMMIT can be
retried later after the reader has had a chance to clear."* This is also
the case `step`'s own guidance singles out as retryable (T43).

*The naive failure.* A wrapper that treats a failed COMMIT as "the
transaction is over" leaks an **open write transaction for the life of the
connection**, blocking every other writer, until close silently rolls it
back and the work is lost.

*The defence.* A `SQLITE_BUSY` from COMMIT is retried under the busy
policy; if it still fails, the transaction is **rolled back** and the
error returned. It is never left open.

*Whose.* DRIVER.

---

**T74 — TRANSACTIONS DO NOT NEST; SAVEPOINTS ARE THE NESTING MECHANISM.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "BEGIN; BEGIN;"
Error: stepping, cannot start a transaction within a transaction
```

`DOC`: *"An attempt to invoke the BEGIN command within a transaction will
fail with an error, regardless of whether the transaction was started by
SAVEPOINT or a prior BEGIN."*

*The naive failure.* A `tx { }` block called from inside another `tx { }`
— which happens the moment two library verbs each open one — fails, and
the inner block's rollback path rolls back the **outer** transaction.

*The defence.* The wrapper keeps a depth counter it owns. Depth 0 →
`BEGIN IMMEDIATE`. Depth > 0 → `SAVEPOINT`.

*Whose.* DRIVER.

---

**T75 — `ROLLBACK TO` DOES NOT POP THE SAVEPOINT; `RELEASE` DOES.**

*Behaviour.* `MEASURED`, both halves:

```
$ sqlite3 :memory: "SAVEPOINT s1; ROLLBACK TO s1; ROLLBACK TO s1; SELECT 'second rollback-to ok';"
second rollback-to ok            ← the savepoint is still on the stack

$ sqlite3 :memory: "SAVEPOINT s1; RELEASE s1; RELEASE s1;"
Error: stepping, no such savepoint: s1    ← RELEASE pops
```

`DOC` (lang_savepoint.html): `ROLLBACK TO` *"does not cancel the
transaction. Instead of cancelling the transaction, the ROLLBACK TO
command restarts the transaction again at the beginning"*. `SAVEPOINT`
outside a transaction behaves as `BEGIN DEFERRED`; `RELEASE` of the
outermost savepoint is a COMMIT.

*The naive failure.* A nested-tx implementation that treats `ROLLBACK TO`
as "the savepoint is gone" leaks a stack entry per failed inner block, and
the outer `RELEASE` then releases the wrong frame.

*The defence.* Success → `RELEASE s<n>`. Failure → `ROLLBACK TO s<n>`
**then** `RELEASE s<n>`. Both paths pop exactly once.

*Whose.* DRIVER.

---

**T76 — SAVEPOINT NAMES NEED NOT BE UNIQUE, AND THE MOST RECENT ONE
WINS.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(x);
                    SAVEPOINT s; INSERT INTO t VALUES(1);
                    SAVEPOINT s; INSERT INTO t VALUES(2);
                    ROLLBACK TO s; SELECT count(*) FROM t;"
1                     ← rolled back to the INNER s; the outer insert survived
```

*The naive failure.* Two library layers that each use a fixed savepoint
name (`"tx"`, `"sp"`) silently target each other's frames. An unbalanced
pair then releases the wrong one, and the damage is a partially committed
transaction with no error.

*The defence.* The driver **mints savepoint names from a depth counter it
owns** (`avra_sp_1`, `avra_sp_2`, …), never from a caller-supplied string,
and never from a fixed constant.

*Whose.* DRIVER.

---

**T77 — AN UNSTEPPED-TO-DONE STATEMENT HOLDS A READ TRANSACTION AND BLOCKS
THE WRITER.**

*Behaviour.* `INFERRED` from `DOC` (isolation.html, lockingv3.html, and
T70's `SQLITE_TXN_READ` definition): a statement that has returned
`SQLITE_ROW` and not yet reached `SQLITE_DONE` holds the connection in a
read transaction. In autocommit mode the implicit transaction ends only
when the statement finishes or is reset.

*The naive failure.* Three, all common:

- `for row in db.query(...)` where the caller `break`s early leaves the
  read transaction open — under a rollback journal it blocks writers, and
  under WAL it is a checkpoint-starvation source (T60).
- A driver that lazily iterates and hands rows out one at a time cannot
  know when the caller stopped, so the transaction closes at an
  unpredictable time.
- The same connection then tries to write and gets `SQLITE_LOCKED` (T49),
  which is *not* retryable, from a program that "only reads".

*The defence.* Every query path in the driver either (a) materialises the
result and resets the statement before returning, or (b) holds the cursor
inside a scope the driver closes — a `defer`ed `reset`, at the frame the
cursor was created in. An early `break` must still reach the reset. Given
this project's `defer` frame law, the reset belongs at a **statement-list
frame**, not a raw scope bracket.

*Whose.* DRIVER.

---

**T78 — `ROLLBACK` ABORTS PENDING STATEMENTS.**

*Behaviour.* `DOC` (lang_transaction.html): pending statements *"will
often be aborted, causing them to return an SQLITE_ABORT or
SQLITE_ABORT_ROLLBACK error"* (516).

*The naive failure.* A cursor held open across a rollback answers
`SQLITE_ABORT` at the next step. A driver that maps `SQLITE_ABORT` to a
generic error hides a cause the caller could have avoided.

*The defence.* `SQLITE_ABORT_ROLLBACK` is its own error variant, in the
"start over" class (T72), with help that names the rollback.

*Whose.* DRIVER.

---

**T79 — `PRAGMA foreign_keys` IS A SILENT NO-OP INSIDE A TRANSACTION.**

*Behaviour.* `MEASURED` — the clearest single demonstration in this
document:

```
$ sqlite3 :memory: "PRAGMA foreign_keys;
                    BEGIN; PRAGMA foreign_keys=ON; SELECT 'inside:'; PRAGMA foreign_keys;
                    COMMIT;  PRAGMA foreign_keys=ON; SELECT 'outside:'; PRAGMA foreign_keys;"
0
inside:
0              ← set to ON inside a transaction: still OFF, and no error
outside:
1              ← set to ON outside: ON
```

`DOC` (pragma.html): *"foreign key constraint enforcement may only be
enabled or disabled when there is no pending BEGIN or SAVEPOINT."*

*The naive failure.* A driver that sets its pragmas lazily on first use
sets `foreign_keys=ON` inside the caller's first transaction, where it
does nothing and reports nothing. Referential integrity is off for the
life of the connection and the driver's documentation says it is on.

*The defence.* **All pragmas are set at connection open, before any
statement and before any transaction**, and their answers are checked
(T137).

*Whose.* DRIVER.

---

**T80 — DO NOT CLOSE A CONNECTION WITH UNFINALIZED STATEMENTS — AND
`close_v2` CHANGES WHAT THAT MEANS, NOT WHETHER IT MATTERS.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, close block):

> *"If the database connection is associated with unfinalized prepared
> statements, BLOB handlers, and/or unfinished sqlite3_backup objects then
> sqlite3_close() will leave the database connection open and return
> SQLITE_BUSY. If sqlite3_close_v2() is called with unfinalized prepared
> statements, unclosed BLOB handlers, and/or unfinished sqlite3_backups,
> it returns SQLITE_OK regardless, but instead of deallocating the database
> connection immediately, it marks the database connection as an unusable
> "zombie" and makes arrangements to automatically deallocate the database
> connection after all prepared statements are finalized, all BLOB handles
> are closed, and all backups have finished."*

And: *"If an sqlite3 object is destroyed while a transaction is open, the
transaction is automatically rolled back."* Passing NULL is a harmless
no-op.

*The naive failure.* `sqlite3_close()` in a `defer` returns
`SQLITE_BUSY`, the connection stays open, the file stays locked, the WAL
is not checkpointed — and the driver reports success.

*The defence.* `close_v2` is the connection's `@free_with`. But note what
`close_v2` does **not** fix: a zombie connection still holds the file
until the last statement is finalized, so a leaked statement cache is
still a leaked lock — it is merely no longer an error the driver can see.
So: finalize every statement explicitly at close, **and** use `close_v2`
as the belt. (This project's own idiom: the tag is the belt, the law is
the braces.)

*Whose.* DRIVER.

---

# Part 8 — ERROR REPORTING (T81–T89)

**T81 — THE PRIMARY CODE IS THE LOW 8 BITS OF THE EXTENDED CODE.**

*Behaviour.* `DOC` (`sqlite3.h`:535–567): every extended code is
`primary | (n << 8)`. `SQLITE_CONSTRAINT_UNIQUE` = 19 | (8<<8) = 2067.

*The naive failure.* An error enum matched on the extended value that
omits the mask never matches its own primary arm: `2067 == 19` is false,
so a `SQLITE_CONSTRAINT` arm never fires once extended codes are on.

*The defence.* Keep **both** numbers in the driver's error value.
`primary = extended & 0xFF`, computed once at construction.

*Whose.* DRIVER.

---

**T82 — EXTENDED RESULT CODES ARE OFF BY DEFAULT, AND WITHOUT THEM THE
DRIVER CANNOT TELL A UNIQUE COLLISION FROM A NOT NULL VIOLATION.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`): *"The extended result codes
are disabled by default for historical compatibility."* Enable per
connection with `sqlite3_extended_result_codes(db, 1)`, or per open with
the `SQLITE_OPEN_EXRESCODE` flag (`sqlite3.h`:623, `0x02000000`).

There are **77** extended codes in this build (`MEASURED`, by counting the
`#define SQLITE_X_Y (SQLITE_X | (n<<8))` lines).

*Why it matters.* Each constraint sub-code is a *different action* for the
caller:

| Code | # | The caller's move |
|---|---|---|
| `SQLITE_CONSTRAINT_UNIQUE` | 2067 | retry with a different key — often recoverable |
| `SQLITE_CONSTRAINT_PRIMARYKEY` | 1555 | same, for the PK |
| `SQLITE_CONSTRAINT_NOTNULL` | 1299 | a program bug — a required field was absent (T40) |
| `SQLITE_CONSTRAINT_FOREIGNKEY` | 787 | the parent row is missing |
| `SQLITE_CONSTRAINT_CHECK` | 275 | the value violates a domain rule |
| `SQLITE_CONSTRAINT_DATATYPE` | 3091 | a STRICT column refused the class (T12) |
| `SQLITE_CONSTRAINT_TRIGGER` | 1811 | a `RAISE()` in a trigger |
| `SQLITE_CONSTRAINT_ROWID` | 2579 | explicit rowid collision |

Without extended codes all eight are `SQLITE_CONSTRAINT` (19).

*The defence.* **The driver enables extended codes at open,
unconditionally** — via `SQLITE_OPEN_EXRESCODE` at `open_v2` so there is
no window before the call.

*Whose.* DRIVER.

---

**T83 — `SQLITE_MISUSE`'s MESSAGE MAY DESCRIBE A DIFFERENT ERROR
ENTIRELY.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`:4226–4229): when an interface is
invoked incorrectly, *"the error code and message may or may not be set."*

*The naive failure.* A driver that reports MISUSE with `errmsg` attached
prints a message about some earlier, unrelated failure, and the debugging
starts in the wrong place.

*The defence.* MISUSE is a defect (T46) and its report names the driver's
own call site, not `errmsg`.

*Whose.* DRIVER.

---

**T84 — `sqlite3_error_offset()` GIVES A SPAN FOR PARSE ERRORS — AND IS
`-1` WHEN THERE IS NO TOKEN.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`:4210–4215): *"If the most recent
error references a specific token in the input SQL, the
sqlite3_error_offset() interface returns the byte offset of the start of
that token. The byte offset returned by sqlite3_error_offset() assumes
that the input SQL is UTF8. If the most recent error does not reference a
specific token in the input SQL, then the sqlite3_error_offset() function
returns -1."*

Added in 3.41.0 (changes.html: *"Added the sqlite3_error_offset()
interface, which can sometimes help to localize an SQL error to a specific
character."*). On this build it is `API_AVAILABLE(macosx(13.0), …)` —
version-gated in the system library (T126).

*Why this matters more here than in most bindings.* This project's
diagnostics already render spans. A byte offset into the SQL text is
exactly a span, so a SQL parse error can be reported with the same caret
rendering as an Avra compile error. That is P10 territory — the compiler
holding knowledge no other tool has — and it costs one extra FFI call.

*The naive failure.* Two: forgetting the `-1` case and rendering a caret
at byte 0 of every non-parse error; and assuming the offset is a character
index (it is a **byte** offset, and the SQL is UTF-8).

*The defence.* Capture it alongside code and message at the failure site
(T85). Render a span only when it is ≥ 0.

*Whose.* DRIVER.

---

**T85 — THE ERROR CODE AND MESSAGE ARE STALE AFTER THE NEXT API CALL, SO
READ THEM FIRST AND CLEAN UP SECOND.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`:4180–4192): *"The values returned
by sqlite3_errcode() and/or sqlite3_extended_errcode() might change with
each API call. Except, there are some interfaces that are guaranteed to
never change the value of the error code."* The error-code-preserving list
is exactly: `sqlite3_errcode()`, `sqlite3_extended_errcode()`,
`sqlite3_errmsg()`, `sqlite3_errmsg16()`, `sqlite3_error_offset()`.

**`sqlite3_reset()` is not on that list.**

*The naive failure.* The single most common error-handling bug in a
binding written with RAII or `defer`:

```
step() fails
  → defer runs reset()          ← clobbers the error state
  → the handler reads errmsg()  ← reports the reset's status
```

The driver reports "not an error" or a lock message for a constraint
violation.

*The defence.* **Build the whole error value at the failure site, before
any cleanup.** Code, extended code, an owned copy of the message (T30),
`error_offset`, and the SQL text — five reads, all from the preserving
list, then clean up. The error value is self-contained: it holds no
borrowed pointer and no connection reference (a connection reference in an
error value is also a refcount cycle, which this project's runtime cannot
collect).

*Whose.* DRIVER.

---

**T86 — `sqlite3_errstr()` IS THE ONLY MESSAGE FUNCTION SAFE WITHOUT A
CONNECTION, AND IT IS NOT ENOUGH ON ITS OWN.**

*Behaviour.* `DOC`, verbatim: *"The sqlite3_errstr(E) interface returns
the English-language text that describes the result code E, as UTF-8, or
NULL if E is not a result code for which a text error message is
available."*

*The naive failure.* A driver that keeps only `errstr` reports
"constraint failed" and never says **which** column. `errmsg` gives
`UNIQUE constraint failed: users.email` — the difference between an error
a caller can act on and one they cannot.

*The defence.* Keep both: `errstr` for the code's name (and for errors
with no connection, e.g. a failed `open` where the handle is NULL),
`errmsg` for the specifics. Note `errstr` can return NULL for an unknown
code — the empty case, again.

*Whose.* DRIVER.

---

**T87 — AN `open` THAT FAILS STILL RETURNS A HANDLE, AND YOU MUST STILL
CLOSE IT.**

*Behaviour.* `DOC`, verbatim (c3ref/open.html): *"A database connection
handle is usually returned in *ppDb, even if an error occurs"*, and
resources *"should be released by passing it to sqlite3_close() when it is
no longer required."*

*The naive failure.* An error path that returns early without closing
leaks the handle — and, worse, cannot read `sqlite3_errmsg()` for the
cause, because the caller threw the handle away.

*The defence.* The open verb reads the error from the returned handle,
then closes it, then returns the error. The empty case first: if the
handle *is* NULL (an out-of-memory open), fall back to `errstr(rc)`.

*Whose.* DRIVER.

---

**T88 — `errmsg` IS CONNECTION-SCOPED, NOT THREAD-SCOPED, SO A SECOND
THREAD CAN OVERWRITE YOUR ERROR.**

*Behaviour.* `DOC` (c3ref/errcode.html): the interfaces report the most
recent failure on the connection, and *"it might be the case that a second
error occurs on a separate thread in between the time of the first error
and the call to these interfaces."*

*The naive failure.* A shared connection produces error messages that
belong to another fiber's query — a wrong answer, not a crash, and one
that survives code review.

*The defence.* One owner per connection at a time (T65) closes this by
construction. It is a good argument for why the threading decision is a
*correctness* decision and not only a performance one.

*Whose.* DRIVER.

---

**T89 — WHICH CODES ARE RETRYABLE, IN ONE PLACE.**

See T72's table. The rule this document adds: **the classification is a
registry with every arm spelled**, because a `_ ->` in it silently
misclassifies the next extended code SQLite ships, and the direction of
that mistake ("unknown → retryable") is an infinite loop.

*Whose.* DRIVER.

---

# Part 9 — NULL, EMPTY AND ZERO (T90–T99)

> **This project already has a law for this section, and SQLite is its
> textbook case: AN ENCODING SPENDS THE EMPTY VALUE, SO WRITE THE EMPTY
> CASE FIRST.** An encoding earns its efficiency by spending a value it
> believes is spare, and the spare value is almost always the empty one —
> the null pointer, the zero length, the absent terminator. SQLite spends
> the null pointer **twice**: once for SQL NULL and once for a zero-length
> blob. Below, every place that costs something.

---

**T90 — A NEGATIVE LENGTH TO `bind_text` MEANS `strlen`; A NEGATIVE LENGTH
TO `bind_blob` IS UNDEFINED BEHAVIOUR.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, bind block): *"If the fourth
parameter to sqlite3_bind_text() or sqlite3_bind_text16() is negative,
then the length of the string is the number of bytes up to the first zero
terminator. **If the fourth parameter to sqlite3_bind_blob() is negative,
then the behavior is undefined.**"*

And, on the non-negative case: *"If a non-negative fourth parameter is
provided to sqlite3_bind_text() … then that parameter must be the byte
offset where the NUL terminator would occur assuming the string were NUL
terminated."*

*Why.* `bind_text`'s `-1` is a C-string convenience. A blob has no
terminator convention, so there is nothing for `-1` to mean.

*The naive failure.* A driver with one generic `bind(ptr, len)` helper
that defaults `len` to `-1` works for text and is undefined for blobs. A
zero-length blob passed as `(NULL, -1)` is the worst case: T29 says NULL
makes it a `bind_null`, and the `-1` says nothing is defined anyway.

*The defence.* **Always pass an explicit, non-negative length**, taken
from the Avra box header, on both `bind_text` and `bind_blob`. There is no
path in the driver that passes `-1`.

*Whose.* DRIVER.

---

**T91 — `x = NULL` IS NULL, NEVER TRUE, NEVER FALSE.**

*Behaviour.* `DOC` (nulls.html, lang_expr.html). The tests are `IS NULL` /
`IS NOT NULL`; `IS` and `IS NOT` *"work like `=` and `!=` except when one
or both of the operands are NULL. If both operands are NULL, then the IS
operator evaluates to 1 (true)"*.

*The naive failure.* A generated `WHERE col = ?` with NULL bound matches
nothing, silently. This is the classic "the ORM's filter returns zero rows
for a null field", and it looks like missing data rather than a bug.

*The defence.* The driver's query builder emits `IS ?` (or branches to
`IS NULL`) whenever the bound value **may** be null — which the Avra type
system says exactly, because the seat is `T?` or it is not.

*Whose.* DRIVER's query builder.

---

**T92 — NULL IN A `WHERE` IS "NOT TRUE", SO THE ROW IS FILTERED OUT.**

*Behaviour.* Three-valued logic reaches the row filter as two-valued: only
TRUE passes.

*The naive failure.* `WHERE flag != 1` does **not** return the rows where
`flag IS NULL`. Almost never what the caller meant, and the missing rows
are silent.

*The defence.* The compile-time SQL checker's territory (P10): warn on a
comparison against a nullable column without an `IS NULL` companion. At
the driver level, document it.

*Whose.* CALLER; DRIVER warns if it can.

---

**T93 — NULLS ARE DISTINCT IN A UNIQUE INDEX AND INDISTINCT IN `DISTINCT`,
`GROUP BY` AND `UNION`.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE t(e TEXT UNIQUE); INSERT INTO t VALUES(NULL),(NULL),(NULL);
                    SELECT count(*) FROM t;"
3
```

Three rows in a UNIQUE column. `DOC` (nulls.html) calls the split
*"somewhat arbitrary"* and notes *"the SQL standards documents suggest
that NULLs should be distinct everywhere. Yet as of this writing, no SQL
engine tested treats NULLs as distinct in a SELECT DISTINCT statement or
in a UNION."*

*The naive failure.* An ORM documents a `UNIQUE` column as "at most one
row per value" — wrong for NULL. And an **upsert keyed on a nullable
unique column never conflicts** and inserts duplicates forever, which is
data corruption at a slow leak.

*The defence.* The driver's schema DSL refuses (or loudly warns on) a
`UNIQUE` column that is nullable, because the constraint does not mean
what the name implies there. `ON CONFLICT` targets must be non-nullable.

*Whose.* DRIVER's schema layer.

---

**T94 — NULL PROPAGATES THROUGH ARITHMETIC, AND `CASE WHEN null` TAKES
THE `ELSE`.**

*Behaviour.* `DOC` (nulls.html): adding anything to null gives null;
multiplying null by zero gives null; `CASE WHEN null THEN 1 ELSE 0 END` is
`0`, because the NULL condition is not true.

*The naive failure.* A computed column that is NULL for one input makes
the whole expression NULL, and a non-nullable Avra seat refuses at read
time far from the cause.

*The defence.* Nothing at the driver layer. Document, and let the row
type's nullability be the honest signal.

*Whose.* CALLER.

---

**T95 — `sum()` OF NOTHING IS NULL, AND `sqlite3_column_int64` TURNS THAT
INTO `0`.**

*Behaviour.* `MEASURED`, both the empty and the all-NULL case:

```
$ sqlite3 :memory: "CREATE TABLE t(x); INSERT INTO t VALUES(NULL),(NULL);
                    SELECT quote(sum(x)), typeof(sum(x)), total(x), count(*), count(x), avg(x) FROM t;"
NULL|null|0.0|2|0|

$ sqlite3 :memory: "CREATE TABLE t(x); SELECT quote(sum(x)), total(x), count(*) FROM t;"
NULL|0.0|0
```

`sum()` → NULL. `total()` → **0.0** (and always REAL). `count(*)` counts
rows; `count(x)` counts non-NULL values; `avg()` of nothing is NULL.

*The naive failure.* **The canonical SQLite data-loss bug.** A balance,
a total, a count of matching money: `SELECT sum(amount) …` over zero rows
answers NULL, `sqlite3_column_int64` answers `0` (the conversion table's
first row), and a report shows a balance of zero for "no rows". Nothing
errors, nothing logs, and the number is wrong in the direction that looks
plausible.

*The defence.* Two layers. (a) T14: a NULL never fills a non-nullable
seat, so `sum()` typed as `int` **refuses**, loudly, at the read. (b) The
driver documents `total()` as the "0.0 instead of NULL" form, and the
query builder prefers it where the caller asked for a non-nullable number.

*Whose.* DRIVER refuses; CALLER chooses `total()` or a nullable seat.

---

**T96 — SQL NULL, THE EMPTY STRING AND THE ZERO-LENGTH BLOB ARE THREE
DIFFERENT VALUES, AND SQLITE KEEPS THEM APART.**

*Behaviour.* `MEASURED`, the whole distinction in one probe:

```
$ sqlite3 :memory: "SELECT typeof(x''), length(x''), quote(x''),
                           typeof(''),  length(''),  quote('');"
blob|0|X''|text|0|''

$ sqlite3 :memory: "CREATE TABLE t(b BLOB); INSERT INTO t VALUES(x''),(NULL),('');
                    SELECT rowid, typeof(b), length(b), quote(b), b IS NULL FROM t;"
1|blob|0|X''|0        ← zero-length blob:   present, class BLOB, IS NULL false
2|null||NULL|1        ← SQL NULL:           absent
3|text|0|''|0         ← empty string:       present, class TEXT, IS NULL false
```

Note also that inserting `''` into a BLOB-affinity column keeps it TEXT —
BLOB affinity performs no coercion (T3).

*Why it is a trap anyway.* The **engine** keeps them apart perfectly. It
is the **C boundary** that spends the null pointer twice (T97), and it is
the driver's job not to lose at the boundary what the engine preserved.

*The defence.* This is exactly this project's standing law, and it is a
**test, not a discipline**: for the blob/text representation the driver
adds, the empty case is the first case written, on both sides. The
round-trip test writes all three values and asserts three distinct
readings back. A diff shows whether it was done.

*Whose.* DRIVER.

---

**T97 — `sqlite3_column_blob()` RETURNS A NULL POINTER FOR A ZERO-LENGTH
BLOB, AND THAT IS NOT A SQL NULL.**

*Behaviour.* `DOC`, verbatim: *"Strings returned by sqlite3_column_text()
and sqlite3_column_text16(), even empty strings, are always
zero-terminated. **The return value from sqlite3_column_blob() for a
zero-length BLOB is a NULL pointer.**"*

So on the read side there are **three** distinct meanings of a NULL
pointer from `column_blob`:

| `column_type` | `column_bytes` | pointer | meaning |
|---|---|---|---|
| `SQLITE_NULL` | 0 | NULL | SQL NULL |
| `SQLITE_BLOB` | 0 | **NULL** | zero-length blob |
| anything | > 0 | NULL | **out of memory** (T22) |

*The naive failure.* Testing the pointer for NULL to detect SQL NULL maps
an empty blob to `null`, which is a silent type change from "present and
empty" to "absent". If the Avra seat is `Bytes` (non-nullable), the driver
then refuses a perfectly valid row.

*The defence.* **The only test for SQL NULL is
`sqlite3_column_type(i) == SQLITE_NULL`, asked first** (T1, T20). The
pointer is never a nullity test. And the three-way table above is the
driver's actual branch, written out, with the OOM case included.

*Whose.* DRIVER.

---

**T98 — THE SAME PROBLEM EXISTS ON THE `sqlite3_value_*` SIDE.**

*Behaviour.* `DOC` (c3ref/value_blob.html): `sqlite3_value_type()`,
`sqlite3_value_blob()` and friends carry the identical conversion,
invalidation, ordering and zero-length-blob rules as their `column_*`
twins. `sqlite3_value_nochange()` and `sqlite3_value_frombind()` add
UPDATE-specific and bind-provenance information.

*Why it matters later.* This is the argument surface for
application-defined SQL functions and virtual tables. If the driver ever
hosts an Avra SQL function, **every trap in Parts 2, 3 and 9 applies
again on that side**, with the extra hazard that a `column_value` object
is *unprotected* (T24) while a function argument is *protected*.

*The defence.* When that lands, `read_value` is the same four-step shape
as `read_column` (T20), sharing the class registry. Write it once.

*Whose.* DRIVER (future).

---

**T99 — A NULL NEVER FILLS A NON-NULLABLE SEAT, AND THE READER IS ONE
MATCH.**

*The rule.* `SQLITE_NULL` → `null` for a `T?` seat; **refuse** for every
other seat. No zero, no empty string, no `false`.

*The shape.* This project already refuses a two-arm null match with no
payload logic on both arms, so the reader is an if-null early return
followed by the class registry:

```
if cls == SQLITE_NULL { return null }   # or refuse, per the seat
<the five-arm class registry of T14>
```

One match, no catch-all.

*Whose.* DRIVER.

---

# Part 10 — TEXT ENCODING (T100–T107)

**T100 — `sqlite3_column_bytes()` IS BYTES, NEVER CHARACTERS, AND EXCLUDES
THE TERMINATOR.**

*Behaviour.* `DOC`, verbatim: *"The values returned by
sqlite3_column_bytes() and sqlite3_column_bytes16() do not include the
zero terminators at the end of the string. For clarity: the values
returned by sqlite3_column_bytes() and sqlite3_column_bytes16() are the
number of bytes in the string, not the number of characters."*

*The naive failure.* Two. (a) Treating it as a character count and sizing
a UTF-16 or grapheme buffer from it. (b) Copying `n` bytes into a buffer
of `n` bytes: this project's `str_box(n)` allocates `n + 1` **because
every caller writes the trailing NUL**, and a copy that stops at `n`
leaves the sentinel byte unwritten. That matters more here than it looks:
this tree's `str_len` does not trust a zero length and falls back to
`strlen`, which is safe only because the sentinel is always written.

*The defence.* The copy verb allocates `n + 1`, copies `n`, and writes the
NUL itself. Always.

*Whose.* DRIVER.

---

**T101 — THE UTF-8 AND UTF-16 ENTRY POINTS ARE PARALLEL AND MUST NOT BE
MIXED; USE UTF-8 ONLY.**

*Behaviour.* `DOC`: `sqlite3_column_text`/`_bytes` are UTF-8;
`_text16`/`_bytes16` are UTF-16; `prepare_v2`/`prepare16_v2`,
`bind_text`/`bind_text16`, `errmsg`/`errmsg16` are the same split. Mixing
the pairs is exactly what invalidates pointers (T21) and what the "do not
mix" rule of T20 forbids.

*Why UTF-8 for this driver.* Avra strings are byte strings with a length
header, and the natural interchange is UTF-8. Choosing UTF-16 anywhere
would mean a conversion on every read *and* a second one on every write,
plus the endianness question of T106.

*The defence.* **The driver's FFI surface contains no `*16` function at
all.** The mistake is unrepresentable, which is the same technique as T32.

*Whose.* DRIVER, by omission.

---

**T102 — THE DATABASE'S TEXT ENCODING IS FIXED WHEN THE FILE IS CREATED,
AND THE PRAGMA THAT CHANGES IT LIES.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 e16.db "PRAGMA encoding='UTF-16le'; CREATE TABLE t(x); PRAGMA encoding;"
UTF-16le
$ sqlite3 e16.db "PRAGMA encoding='UTF-8'; PRAGMA encoding;"
UTF-16le                ← the set was ignored; no error
```

`DOC` (pragma.html): the encoding may only be set *before* the database is
created; afterwards the pragma is a no-op that answers the current value.
Default is UTF-8 (`MEASURED`: `PRAGMA encoding` → `UTF-8` on a fresh file).

*The naive failure.* A driver that opens a UTF-16 database (created by
another tool) and calls `sqlite3_column_text()` on every column pays a
**UTF-16 → UTF-8 conversion per value** and — per T21 — invalidates any
pointer it held. It works, silently, at a cost nobody measured.

*The defence.* Read `PRAGMA encoding` at open. If it is not UTF-8, either
refuse (with help naming the conversion cost) or record it and document
the cost. Do not silently pay it. The driver's own created databases are
UTF-8, set before creation.

*Whose.* DRIVER detects; CALLER decides for a foreign database.

---

**T103 — UTF-16 BIND INPUT USES A BOM, AND INVALID UNICODE IS SILENTLY
REPLACED.**

*Behaviour.* `DOC`, verbatim: *"The byte-order of UTF16 input text is
determined by the byte-order mark (BOM, U+FEFF) found in first character,
which is removed, or in the absence of a BOM the byte order is the native
byte order of the host machine … If UTF16 input text contains invalid
unicode characters, then SQLite might change those invalid characters into
the unicode replacement character: U+FFFD."*

*Why it is recorded here even though T101 says never to use `*16`.* It is
the one place SQLite documents **silently modifying data on the way in**.
If the `*16` entry points are ever added, this is the reason to think hard
first.

*Whose.* DRIVER (by not using them).

---

**T104 — SQL `length()` IS CHARACTERS FOR TEXT AND BYTES FOR BLOBS, AND
NEITHER IS `column_bytes`.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT length('héllo'), length(CAST('héllo' AS BLOB)), octet_length('héllo');"
5|6|6
```

`length()` on TEXT counts **characters** (5); on a BLOB it counts bytes
(6); `octet_length()` counts bytes always. `sqlite3_column_bytes()` also
counts bytes (T100).

*The naive failure.* A validation rule written as `CHECK(length(name) <=
32)` bounds characters, while the driver's own buffer sizing and any
`column_bytes` assertion bound bytes. A 32-character name of accented
Latin is 33+ bytes; a 32-character CJK name is up to 96. The two limits
disagree and the disagreement is data-dependent.

*The defence.* Pick one and say which. The driver reports **bytes**
everywhere (matching Avra's `.length`, which is a header load of a byte
count), and any generated `CHECK` uses `octet_length()`, not `length()`.

*Whose.* DRIVER; the choice is documented to the CALLER.

---

**T105 — SQLITE STORES EMBEDDED NULs IN TEXT, AND THEN CALLS EXPRESSIONS
OVER THEM UNDEFINED.**

*Behaviour.* `MEASURED` — the sharpest result in this document:

```
$ sqlite3 :memory: "SELECT length(char(97,0,98)), typeof(char(97,0,98)), quote(char(97,0,98)),
                           char(97,0,98)='a', hex(char(97,0,98));"
1|text|'a'|0|610062
```

Read that row carefully. The value is three bytes (`hex` = `610062`).
`length()` says **1**. `quote()` renders it as **`'a'`**. But `= 'a'`
answers **0** — the comparison sees all three bytes. And:

```
$ sqlite3 :memory: "SELECT hex(CAST(char(97,0,98) AS BLOB)), length(CAST(char(97,0,98) AS BLOB));"
610062|3
```

Cast to BLOB and the length is 3.

`DOC` (quirks.html §14): *"NUL characters (ASCII code 0x00 and Unicode
U+0000) may appear in the middle of strings in SQLite"*. And, decisively,
`sqlite3.h`'s bind block: *"If any NUL characters occurs at byte offsets
less than the value of the fourth parameter then the resulting string
value will contain embedded NULs. **The result of expressions involving
strings with embedded NULs is undefined.**"*

*Why this is the single most important interaction with Avra.* This
project already carries the mirror-image law: an Avra `string` **holds** a
NUL (the header carries the length) and a program can **mint** one with no
foreign input at all (`from_codepoint(0)`), while five primitives —
`==`, `contains`, `index_of`, `split`, `replace` — are C string calls that
stop at the first NUL. So a NUL-bearing text has *two* truncation points:
Avra's, and SQLite's. They are not the same set of operations, and a value
can survive one and be mangled by the other.

*The naive failure.* A text arrives from a file, a process's output, or a
database blob with a NUL in it. Avra's `.length` says 5; SQLite's
`length()` says 2; `quote()` in a log line shows the 2-byte prefix; `=`
compares all 5; and any SQL expression over it is, by SQLite's own words,
undefined. The driver has faithfully stored data that neither side can
reason about.

*The defence, and it is a decision the driver must make explicitly:*

- The driver **never truncates**: it passes the header's byte length to
  `bind_text` (T90) and copies `column_bytes` bytes back (T100). Storage
  and retrieval are lossless, and that is testable.
- But it **must not pretend SQL is safe over such values.** The honest
  positions are (a) refuse to bind a text containing a NUL to a TEXT
  column, with help saying "bind it as a blob", or (b) accept it and
  document that SQL comparisons, `LIKE`, `length()` and collation over it
  are undefined. **(a) is the recommendation**: it matches P9 (boundaries
  are contracts), it costs one scan of a length the driver already knows,
  and it makes a genuinely undefined behaviour unreachable instead of
  merely documented. Bytes go in a BLOB column, where every byte is
  defined.
- Either way, a corpus test must pin the chosen behaviour, because the two
  choices are indistinguishable until a NUL appears in production.

*Whose.* DRIVER decides and enforces; the CALLER is told at the refusal.

---

**T106 — `column_text16` RETURNS NATIVE-ENDIAN UTF-16 REGARDLESS OF THE
DATABASE ENCODING.**

*Behaviour.* `DOC`, verbatim: *"Strings returned by sqlite3_column_text16()
always have the endianness which is native to the platform, regardless of
the text encoding set for the database."*

*The naive failure.* Assuming the returned bytes match the database's
declared `UTF-16be`/`UTF-16le`.

*The defence.* Not applicable — the driver has no `*16` entry points
(T101). Recorded so the decision is not re-litigated.

*Whose.* DRIVER (by omission).

---

**T107 — SQLITE DOES NOT VALIDATE UTF-8 ON INPUT.**

*Behaviour.* `DOC`, verbatim: *"If the third parameter to
sqlite3_bind_text() is not NULL, then it should be a pointer to
well-formed UTF8 text."* "Should", not "must be, and is checked". SQLite
stores the bytes.

*The naive failure.* A driver that reads bytes from a file, calls them a
`string`, and binds them as TEXT stores ill-formed UTF-8 in a TEXT column.
Every later `length()`, `substr()`, `upper()` and `LIKE` over that value
behaves unpredictably, and the corruption is invisible until someone
renders it.

*The defence.* If the source of a value is not known to be UTF-8, it is a
**BLOB**, not TEXT. The driver's `Bytes` → BLOB path exists exactly to
give ill-formed bytes a home where they are defined. (Whether the driver
*validates* on the TEXT path is a cost decision: one scan per bind. The
recommendation is to validate on the `string` → TEXT path only when the
value crossed a foreign boundary, and to make the strict form available.)

*Whose.* DRIVER's typing; CALLER's choice of column type.

---

# Part 11 — INTEGERS (T108–T115)

**T108 — ROWIDS ARE 64-BIT, AND SO IS EVERY SQLITE INTEGER.**

*Behaviour.* `DOC` (`sqlite3.h`, last_insert_rowid block): *"Each entry in
most SQLite tables (except for WITHOUT ROWID tables) has a unique 64-bit
signed integer key called the rowid. The rowid is always available as an
undeclared column named ROWID, OID, or _ROWID_ as long as those names are
not also used by explicitly declared columns. If the table has a column of
type INTEGER PRIMARY KEY then that column is another alias for the rowid."*

Storage is variable-width (0, 1, 2, 3, 4, 6 or 8 bytes by magnitude), but
the *value* domain is always i64.

*Whose.* DRIVER — and it maps cleanly onto Avra's `int`, which is the one
piece of good news in this part.

---

**T109 — THE `int` / `int64` API SPLIT IS A TRAP WITH NO UPSIDE.**

See T32 — the driver links only the `_int64` forms, so a 32-bit truncation
is unrepresentable. Repeated here because it belongs to both parts, and
because the same rule applies to `sqlite3_changes64` and
`sqlite3_total_changes64`.

---

**T110 — INTEGER OVERFLOW IN ARITHMETIC SILENTLY BECOMES A REAL.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT 9223372036854775807 + 1, typeof(9223372036854775807 + 1);"
9.22337203685478e+18|real

$ sqlite3 :memory: "SELECT 9223372036854775807 * 2, typeof(9223372036854775807*2);"
1.84467440737096e+19|real
```

`DOC` (lang_expr.html): the arithmetic operators *"perform integer
arithmetic if both operands are integers and no overflow would result, or
floating point arithmetic, per IEEE Standard 754, if either operand is a
real value **or integer arithmetic would produce an overflow**."*

*The naive failure.* A counter column that overflows becomes REAL. A
coercing driver then reads it as a truncated, wrong integer. **Our driver
refuses it** (T4/T14), which is the *good* outcome: the program learns
that its counter left the integer domain, at the read, with a diagnostic.

*The defence.* No change needed — this is a case where the strict ladder
already pays for itself. Document it as such, because a caller will
otherwise report the refusal as a driver bug.

*Whose.* DRIVER's ladder; CALLER's schema.

---

**T111 — `sum()` OVERFLOW IS AN ERROR, WHICH IS *NOT* WHAT `+` DOES.**

*Behaviour.* `MEASURED` — two overflow paths, two different behaviours:

```
$ sqlite3 :memory: "CREATE TABLE t(x INT); INSERT INTO t VALUES(9223372036854775807),(1);
                    SELECT sum(x) FROM t;"
Error: stepping, integer overflow
```

compared with `SELECT 9223372036854775807 + 1` above, which answered a
REAL with no error.

*Why.* `sum()` accumulates in an integer when all its inputs are integers,
and raises rather than silently changing type. `total()` always
accumulates in a double and therefore never raises (it loses precision
instead).

*The naive failure.* A driver whose error mapping assumes "arithmetic
never fails at step time" hits an unhandled `SQLITE_ERROR` from a query
containing only a `SELECT sum(...)`. And a caller who switches `sum()` to
`total()` to avoid the error has silently switched to lossy accumulation.

*The defence.* Map it: `SQLITE_ERROR` with the message "integer overflow"
is worth its own diagnostic, whose help names `total()` **and** its
precision cost. Two behaviours from one concept is exactly the kind of
asymmetry a driver should surface rather than smooth over.

*Whose.* DRIVER's error mapping.

---

**T112 — AN INTEGER LITERAL TOO LARGE FOR i64 IS PARSED AS A REAL.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT typeof(9223372036854775808), quote(9223372036854775808);"
real|9.22337203685477581e+18

$ sqlite3 :memory: "SELECT -9223372036854775808;"
-9223372036854775808        ← i64::MIN is special-cased and stays an integer
```

*The naive failure.* A driver that builds SQL by interpolating a number
(which it should not — T7) can change the storage class of the value it
meant to write, purely by magnitude.

*The defence.* Bind; never interpolate. The bound path uses
`sqlite3_bind_int64` and the value's class is decided by the API, not by
the parser.

*Whose.* DRIVER.

---

**T113 — INTEGER DIVISION TRUNCATES, AND `%` CASTS BOTH OPERANDS TO
INTEGER.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT 5 / 2, typeof(5/2), 5.0/2, 9223372036854775807 % 2, typeof(9223372036854775807 % 2);"
2|integer|2.5|1|integer
```

`DOC`: `%` *"casts both of its operands to type INTEGER"* — so it does not
follow the overflow-to-REAL rule of T110, and `7.5 % 2` is `1`, not `1.5`.

*The naive failure.* A generated `avg`-like expression written as
`sum(a)/count(*)` truncates to an integer. This is a SQL-semantics
difference from most host languages' float division and it is silent.

*The defence.* The driver's query builder, when generating a division
whose result seat is `float`, emits `CAST(x AS REAL) / y` or `x * 1.0 /
y`. Document `%`'s cast.

*Whose.* DRIVER's builder; CALLER's raw SQL.

---

**T114 — BINDING AN i64 TO A REAL-AFFINITY COLUMN LOSES PRECISION ABOVE
2^53, SILENTLY.**

See T6 for the measurement (2^53 + 1 went in, 2^53 came out). Repeated
under Integers because this is where a caller will look for it.

*The defence.* The driver's DDL never gives REAL affinity to a column an
`int` is bound to; and if a foreign schema does, the read side refuses
(T14) rather than handing back a number that is not the one stored.

*Whose.* DRIVER.

---

**T115 — THE LIMITS ARE BUILD-SPECIFIC. READ THEM; DO NOT HARDCODE
THEM.**

*Behaviour.* `DOC` (limits.html) gives defaults; `MEASURED` shows this
build disagreeing with several of them.

| Limit | Documented default | This build (`PRAGMA compile_options`) |
|---|---|---|
| `SQLITE_MAX_LENGTH` | 1 000 000 000 | **2 147 483 645** |
| `SQLITE_MAX_COLUMN` | 2 000 | 2 000 |
| `SQLITE_MAX_FUNCTION_ARG` | 1 000 (≥ 3.48.0) | **127** |
| `SQLITE_MAX_PAGE_COUNT` | 4 294 967 294 | **1 073 741 823** |
| `SQLITE_MAX_MMAP_SIZE` | build-dependent | 1 073 741 824 |
| `SQLITE_MAX_ATTACHED` | 10 | 10 |
| `SQLITE_MAX_EXPR_DEPTH` | 1 000 | 1 000 |
| `SQLITE_MAX_COMPOUND_SELECT` | 500 | 500 |
| `SQLITE_MAX_LIKE_PATTERN_LENGTH` | 50 000 | 50 000 |

And the variable-number limit, which the driver most needs. limits.html
gives 32 766 as **both** the default and the maximum. `MEASURED`, this
build disagrees by more than an order of magnitude — and says so itself:

```
$ sqlite3 :memory: "SELECT ?32766 IS NULL;"    → 1
$ sqlite3 :memory: "SELECT ?32768 IS NULL;"    → 1
$ sqlite3 :memory: "SELECT ?100000 IS NULL;"   → 1
$ sqlite3 :memory: "SELECT ?1000000 IS NULL;"
Error: in prepare, variable number must be between ?1 and ?500000
```

And in the shape that actually matters — a bulk insert:

```
$ # INSERT INTO t(a,b) VALUES (?,?),(?,?),… with N parameters
  32766 params ( 16383 rows) : ok
  40000 params ( 20000 rows) : ok
 100000 params ( 50000 rows) : ok
 200000 params (100000 rows) : ok
```

The engine named its own limit in an error message. **That is the cheapest
way to discover a limit, and no documentation could have told you.**

`MAX_PAGE_COUNT` is the one with teeth: 1 073 741 823 pages × 4096 bytes
caps this build's databases at ≈**4 TB**, not the 281 TB the documentation
advertises.

*The naive failure.* A bulk-insert verb that chunks at a hardcoded 32 766
parameters, or a size check against a hardcoded 1 GB, is wrong on some
builds in the safe direction and on others in the unsafe one. Here it is
wrong in the *slow* direction by 6× — the driver would split a 100 000-row
insert into seven transactions the engine would have taken in one.

*The defence.* **Read every limit the driver depends on at open**, with
`sqlite3_limit(db, SQLITE_LIMIT_*, -1)` (a negative argument queries
without setting). The batch verb chunks by the *read* parameter limit, not
by a constant, and chunks by **parameter count**, never by row count.

*Whose.* DRIVER.

---

# Part 12 — FLOATING POINT (T116–T123)

**T116 — `REAL` IS IEEE-754 BINARY64, AND AVRA HAS NO `float` YET.**

*Behaviour.* `DOC` (datatype3.html §2): a REAL is *"a floating point
value, stored as an 8-byte IEEE floating point number"*.

*The blocker, stated once.* Avra's `core.Type` has no float variant and
the lexer has no float literal. Until it does, `sqlite3_column_double` and
`sqlite3_bind_double` have no Avra type to answer or accept, and a REAL
column can only be read as text — which, per T120, **loses precision**.
This is the driver's hardest language dependency and everything below is
its specification.

*Whose.* LANGUAGE, then DRIVER.

---

**T117 — SQLITE STORES NaN AS NULL.**

*Behaviour.* `MEASURED`, three ways of producing a NaN, all of which land
as NULL:

```
$ sqlite3 :memory: "SELECT quote(9e999 - 9e999), typeof(9e999-9e999);"
NULL|null

$ sqlite3 :memory: "SELECT quote(0.0/0.0), typeof(0.0/0.0), quote(1.0/0.0), typeof(1.0/0.0);"
NULL|null|NULL|null

$ sqlite3 :memory: "CREATE TABLE t(r REAL); INSERT INTO t VALUES(9e999),(-9e999),(9e999-9e999);
                    SELECT rowid, typeof(r), quote(r) FROM t;"
1|real|9.0e+999
2|real|-9.0e+999
3|null|NULL          ← the NaN became a SQL NULL on the way in
```

Note also that **division by zero is NULL, not an error and not an
infinity** — `1.0/0.0` is NULL.

*Why.* SQLite has no NaN in its value domain; the documented behaviour is
that a NaN is stored as NULL.

*The naive failure, and it is a data-loss bug.* Round-tripping a
`List<float>` through a REAL column turns every NaN into a NULL. If the
seat is non-nullable `float`, the read then **refuses** — which is at
least loud. If the seat is `float?`, the NaN comes back as `null` and the
program silently confuses "not a number" with "no measurement", which are
different facts in exactly the domains (sensors, statistics) that produce
NaNs.

*The defence.* The driver **refuses to bind a NaN to a REAL column**, with
help naming the two honest encodings: store the payload as TEXT/BLOB, or
model absence explicitly with a nullable column plus a sentinel. This is
the empty-value law once more — SQLite spends NULL to encode NaN, so the
driver must not let a program spend NULL for anything else in the same
column. A test binds NaN and asserts the refusal.

*Whose.* DRIVER refuses; CALLER chooses the encoding.

---

**T118 — INFINITIES ARE STORED, AND THEIR TEXT RENDERING IS
`9.0e+999` — WHICH IS NOT A NUMBER ANY OTHER PARSER ACCEPTS.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "SELECT quote(9e999), typeof(9e999), quote(-9e999);"
9.0e+999|real|-9.0e+999

$ sqlite3 :memory: "SELECT 9e999, -9e999, 9e999-9e999;"
Inf|-Inf|                      ← the CLI's own rendering differs from quote()'s
```

So ±∞ **is** representable (unlike NaN), it survives storage, and it
renders as the out-of-range literal `9.0e+999`, which SQLite itself
re-parses back to infinity. The bare CLI output is `Inf`/`-Inf`, and a NaN
renders as an empty field.

*The naive failure.* Three. (a) A driver that reads REAL as text (because
it has no `float` — T116) gets `9.0e+999` and any ordinary float parser
either fails or returns infinity by accident. (b) A JSON or CSV export
emits `9.0e+999`, which is invalid JSON and unparseable by most CSV
consumers. (c) A caller assumes symmetry with NaN and expects infinity to
become NULL too; it does not.

*The defence.* The `float` reader accepts infinities as infinities. Any
*text projection* the driver offers (an export, a diagnostic) renders
`Infinity`/`-Infinity` explicitly, never SQLite's literal. And the
round-trip test includes ±∞ alongside ±0 and the subnormals.

*Whose.* DRIVER.

---

**T119 — REAL→TEXT USES 15 SIGNIFICANT DIGITS AND DOES NOT ROUND-TRIP —
UNTIL 3.53.0.**

*Behaviour.* `MEASURED` on 3.51.0 — the single most consequential
measurement in this part:

```
$ sqlite3 :memory: "SELECT (1.0/3.0) = CAST(CAST(1.0/3.0 AS TEXT) AS REAL), CAST(1.0/3.0 AS TEXT);"
0|0.333333333333333        ← round-trips: FALSE. 15 digits, not 17.

$ sqlite3 :memory: "SELECT 0.1+0.2, (0.1+0.2)=0.3, CAST(0.1+0.2 AS TEXT);"
0.3|0|0.3                  ← prints "0.3", which is a DIFFERENT double

$ sqlite3 :memory: "WITH v(x) AS (VALUES(1.0/3.0),(0.1),(0.1+0.2),(1e308),(5e-324),
                                        (2.2250738585072014e-308),(1.7976931348623157e308))
                    SELECT quote(x), CAST(x AS TEXT), x = CAST(CAST(x AS TEXT) AS REAL) FROM v;"
3.333333333333333148e-01 | 0.333333333333333  | 0     ← 1/3            LOSES
0.1                      | 0.1                | 1     ← 0.1            ok
3.000000000000000445e-01 | 0.3                | 0     ← 0.1+0.2        LOSES
1.0e+308                 | 1.0e+308           | 1     ← 1e308          ok
4.94065645841247e-324    | 4.94065645841247e-324 | 1  ← min subnormal  ok
2.225073858507201383e-308| 2.2250738585072e-308 | 0   ← DBL_MIN        LOSES
1.797693134862315692e+308| 1.79769313486232e+308| 0   ← DBL_MAX        LOSES
```

**Four of seven values do not survive a REAL→TEXT→REAL round trip on this
build, including `DBL_MAX` and `DBL_MIN`.**

`quote()` is not the same renderer as `CAST(… AS TEXT)`: it produces more
digits and *is* round-trip-safe here. And `format()` with the `!` flag is
exact:

```
$ sqlite3 :memory: "WITH v(x) AS (VALUES(1.0/3.0),(0.1+0.2))
                    SELECT format('%!.17g',x), x = CAST(format('%!.17g',x) AS REAL) FROM v;"
0.33333333333333331|1
0.30000000000000004|1
```

*Why, and when it changes.* `DOC` (floatingpoint.html): *"Rounding to 17
significant digits or more results in text that, when converted back into
binary-64, gives the exact same value that we started with"*, while
*"Rounding to 15 digits or less can often gives this exact round-trip
result, but not always."* SQLite ≤ 3.51.2 rounds to 15 by default. The
change to 17-by-default is **3.53.0 (2026-04-09)** per changes.html:
*"Rounding is now done by default to 17 significant digits, instead of 15,
as was the case for all prior versions. The
sqlite3_db_config(SQLITE_DBCONFIG_FP_DIGITS) API can change this."*
(floatingpoint.html attributes it to 3.52.0, which was withdrawn — a
documentation lag worth knowing about.)

*The naive failure.* Two, and both are silent data loss:

- A driver without `float` (T116) that reads REAL columns **as text**
  loses precision on most values. A physics or financial computation
  round-tripped through the database returns a different number.
- Any export, log line, or `CAST(x AS TEXT)` in generated SQL is a lossy
  projection. A "backup" written by `SELECT CAST(r AS TEXT)` is not a
  backup.

*The defence, three parts:*

1. **Vendor a SQLite ≥ 3.53.0** and the default becomes round-trip-safe.
   This is a concrete, dated reason to vendor rather than link the system
   library (T126).
2. **Never read a REAL as text.** The `float` seat uses
   `sqlite3_column_double`, which is exact by construction and is not
   affected by any of this. The rendering question only arises at the
   *program's* boundary, not the database's.
3. **Avra's own float→text projection must be shortest-round-trip**
   (Ryū/Grisu-class), independently of SQLite. `%.17g` round-trips but
   prints `0.1` as `0.10000000000000001`; `%g` does not round-trip at all.
   The corpus test is `parse(print(x)) == x` over a generated set
   including ±0, the subnormals, `DBL_MIN`, `DBL_MAX`, ±∞ — and the seven
   values in the probe above, which are a ready-made fixture.

*Whose.* DRIVER (build choice + never-as-text); LANGUAGE (the projection).

---

**T120 — `SQLITE_DBCONFIG_FP_DIGITS` MAKES THE RENDERING CONFIGURABLE, SO
A DRIVER SHOULD SET IT.**

*Behaviour.* `DOC` (changes.html, 3.53.0). From 3.53.0 the digit count is
a per-connection `sqlite3_db_config` setting.

*The defence.* Once the vendored engine is ≥ 3.53.0, set it explicitly to
17 at open rather than relying on the default — the same reasoning as
T137: a default that changed once can change again, and an explicit
setting is a fact the driver can test. `INFERRED` on the exact enum name
and argument shape, which must be read from the vendored `sqlite3.h` at
implementation time (it is not present in the 3.51.0 header measured
here).

*Whose.* DRIVER.

---

**T121 — `fcmp` MUST USE ORDERED PREDICATES, AND `NaN != NaN` IS THE
SPEC'D ANSWER.**

*Behaviour.* `INFERRED` (IEEE-754 + the Avra spec's "NaN != NaN").

*The naive failure.* Lowering Avra float comparisons to LLVM's *unordered*
predicates (`ueq`, `ult`) makes `NaN == NaN` true, contradicting the spec.
Using the **signed integer** predicates on float registers is worse and is
the kind of mistake this project's "a read wears the type of what is read"
law exists to catch.

*The defence.* `fadd`/`fsub`/`fmul`/`fdiv` and the **ordered** `fcmp`
predicates (`oeq`, `olt`, …). A corpus program proving eval == native over
NaN comparisons.

*Whose.* LANGUAGE.

---

**T122 — REAL AFFINITY MAY STORE AN INTEGRAL REAL AS AN INTEGER ON
DISK.**

*Behaviour.* `MEASURED`, the visible half:

```
$ sqlite3 :memory: "CREATE TABLE t(r REAL); INSERT INTO t VALUES(1); SELECT typeof(r), quote(r) FROM t;"
real|1.0
```

Here the read-back class is REAL. `MEDIUM` confidence on the on-disk
detail (SQLite may write an integral REAL in integer form and convert on
read); what is certain is the reader-visible contract.

*The defence.* The safe law is unconditional and costs nothing: **a
`float` seat accepts storage class INTEGER and REAL; an `int` seat accepts
INTEGER only** (T14). Written that way, whether the optimisation is
observable never matters.

*Whose.* DRIVER.

---

**T123 — TEXT→REAL CONVERSION ACCEPTS MORE THAN A FLOAT LITERAL DOES.**

*Behaviour.* `MEASURED`: `CAST('1e3' AS REAL)` → `1000.0` while
`CAST('1e3' AS INTEGER)` → `1` (T25); `CAST('  9 ' AS INTEGER)` → `9`
(leading and trailing whitespace ignored, T5).

*The naive failure.* A driver that validates a caller's numeric string
with its own parser and then lets SQLite convert it gets two different
answers for the same input — the classic double-parse divergence.

*The defence.* Parse in exactly one place. The driver binds a **typed**
value (`bind_double`/`bind_int64`), so no string is ever converted by
SQLite on the driver's path.

*Whose.* DRIVER.

---

# Part 13 — FILE-LEVEL REALITIES (T124–T136)

**T124 — THE `SQLITE_OPEN_*` FLAGS, AND WHAT EACH ACTUALLY DOES.**

*Behaviour.* `DOC` (c3ref/open.html). Exactly one of three combinations is
required:

| Flags | Meaning |
|---|---|
| `SQLITE_OPEN_READONLY` | *"The database is opened in read-only mode. If the database does not already exist, an error is returned."* |
| `SQLITE_OPEN_READWRITE` | *"opened for reading and writing if possible, or reading only if the file is write protected by the operating system"* — **note it silently degrades to read-only** |
| `SQLITE_OPEN_READWRITE \| SQLITE_OPEN_CREATE` | read/write, created if absent |

Optional flags that matter here:

| Flag | Value | Effect |
|---|---|---|
| `SQLITE_OPEN_URI` | | the filename may be a URI (T130) |
| `SQLITE_OPEN_MEMORY` | | open as an in-memory database |
| `SQLITE_OPEN_NOMUTEX` | | multi-thread mode for this connection (T63) |
| `SQLITE_OPEN_FULLMUTEX` | | serialized mode for this connection |
| `SQLITE_OPEN_SHAREDCACHE` / `_PRIVATECACHE` | | shared cache on/off (T57: leave off) |
| `SQLITE_OPEN_EXRESCODE` | `0x02000000` | extended result codes from the start (T82) |
| `SQLITE_OPEN_NOFOLLOW` | | *"The database filename is not allowed to contain a symbolic link"* |

*The naive failure.* `SQLITE_OPEN_READWRITE`'s silent degradation: a
driver that opens read/write on a write-protected file gets a working
connection and discovers the read-onlyness at the first write, as
`SQLITE_READONLY` from a `step` deep inside a transaction.

*The defence.* Open with the flags the caller asked for, and if the caller
asked for write access, **prove it at open** — `sqlite3_db_readonly(db,
"main")` answers directly, and failing fast beats failing mid-transaction.
Always pass `SQLITE_OPEN_EXRESCODE`. Consider `SQLITE_OPEN_NOFOLLOW` for a
path that came from untrusted input.

*Whose.* DRIVER.

---

**T125 — `""` AND `":memory:"` ARE TEMPORARY DATABASES THAT VANISH, AND
THEY ARE NOT THE SAME.**

*Behaviour.* `DOC`, verbatim: *":memory:"* — *"A private, temporary
in-memory database is created for the connection. This in-memory database
will vanish when the database connection is closed."* And `""` (the empty
filename) — *"A private, temporary on-disk database will be created. This
private database will be automatically deleted as soon as the database
connection is closed."*

*Why the empty case is the trap.* This is the empty-value law at the
filename level: the **empty string is spent** to mean "give me a private
temp database on disk". A driver that treats an empty path as "the caller
forgot to configure a path" and passes it through creates a database that
silently disappears — every write succeeds, and the data is gone at close.

*The naive failure.* A config file with a missing `path =` key produces an
empty string, the driver opens it, the service runs, all writes succeed,
and the database is deleted on shutdown. No error at any point.

*The defence.* **Write the empty case first.** The driver's open verb
refuses an empty path with a named diagnostic, and offers `open_temp()`
and `open_memory()` as explicit, separately-named verbs for the two
temporary forms. `":memory:"` is likewise never spelled by a caller as a
path.

*Whose.* DRIVER.

---

**T126 — THE SYSTEM SQLITE IS NOT THE SQLITE IN THE DOCUMENTATION. VENDOR
THE AMALGAMATION.**

*Behaviour.* `MEASURED` — `PRAGMA compile_options` on the macOS system
library, compared with upstream defaults:

```
BUG_COMPATIBLE_20160819          ← an Apple-specific behaviour switch
CODEC=see-cccrypt                ← a proprietary encryption codec
CCCRYPT256
HAS_CODEC_RESTRICTED
DQS=3                            ← double-quoted strings fully ON (T146)
DEFAULT_CACHE_SIZE=2000          ← upstream: -2000 (a DIFFERENT UNIT, T141)
DEFAULT_JOURNAL_SIZE_LIMIT=32768 ← upstream: -1 (unlimited)
DEFAULT_MEMSTATUS=0              ← sqlite3_status() memory metrics DISABLED
DEFAULT_WAL_SYNCHRONOUS=1
MAX_FUNCTION_ARG=127             ← upstream default 1000 since 3.48
MAX_PAGE_COUNT=1073741823        ← upstream 4294967294; caps this build at ~4 TB
MAX_MMAP_SIZE=1073741824
ENABLE_API_ARMOR
ENABLE_FTS3 / FTS4 / FTS5 / RTREE / SESSION / SNAPSHOT / PREUPDATE_HOOK
```

And the corresponding runtime pragma defaults, also `MEASURED` on a fresh
file database:

```
journal_mode delete    synchronous 2      foreign_keys 0     busy_timeout 0
cache_size   2000      page_size   4096   temp_store   0     mmap_size    0
wal_autocheckpoint 1000  analysis_limit 0  encoding UTF-8    auto_vacuum  0
secure_delete 2 (=FAST) locking_mode normal  legacy_alter_table 1
journal_size_limit 32768  automatic_index 1   trusted_schema 0   query_only 0
```

Note `secure_delete=2` (FAST) and `legacy_alter_table=1`, neither of which
is the upstream default.

*Why.* Every distributor compiles SQLite with its own options. The
documentation describes the *upstream defaults*, which almost nobody
ships.

*The naive failure, and it bites twice.* (a) A driver that reasons about
defaults from the documentation is **wrong on the very machine it is being
developed on**. (b) Worse: a driver developed against the system library
and shipped against a vendored one changes behaviour silently — different
DQS setting, different cache unit, different limits, different float
rendering (T119).

*The defence — this is the single highest-leverage decision in the whole
driver:*

1. **Vendor the SQLite amalgamation.** Pin the version. Then the docs
   describe the engine, `PRAGMA compile_options` is a fixed known list,
   and a corpus test can assert it.
2. **Set explicitly every pragma the driver depends on** (T137–T150) and
   check the answers. A default is not a fact.
3. **Read every limit at open** (T115).
4. Choose the compile options deliberately: `-DSQLITE_DQS=0`,
   `-DSQLITE_THREADSAFE=2` (T65), **not** `-DSQLITE_OMIT_DECLTYPE` (T13),
   **not** `-DSQLITE_OMIT_AUTORESET` (T44), and a version ≥ 3.53.0 for
   T119.
5. `PRAGMA compile_options` is itself a test fixture: the gate asserts the
   list, so a build-flag change cannot land silently.

*Whose.* DRIVER's build, decided once, tested forever.

---

**T127 — OPENING IS LAZY. A BAD DATABASE IS DISCOVERED AT PREPARE, NOT AT
OPEN.**

*Behaviour.* `MEASURED`:

```
$ echo "this is not a database" > notdb.db
$ sqlite3 notdb.db "SELECT 1;"
Error: in prepare, file is not a database (26)
```

The error arrives from **prepare**, not from open, and its code is
`SQLITE_NOTADB` (26). The `sqlite3` shell opened the file without
complaint.

*Why.* `sqlite3_open_v2` does little more than record the filename and
allocate the connection; the header is not read until a statement needs
the schema.

*The naive failure.* A driver whose `open()` returns `Ok` on a corrupt,
truncated or non-database file, and whose health check is "did open
succeed". The failure then surfaces at the first query, blaming the query.

*The defence.* The open verb runs one trivial statement — `PRAGMA
user_version` or `SELECT count(*) FROM sqlite_schema` — before returning
`Ok`, so "the connection opened" and "the file is a database" are the same
answer. It costs one page read.

*Whose.* DRIVER.

---

**T128 — OPENING A DIRECTORY, OR A PATH THAT CANNOT BE CREATED, GIVES
`SQLITE_CANTOPEN` WITH USEFUL EXTENDED CODES.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 /tmp "SELECT 1;"
Error: unable to open database "/tmp": unable to open database file

$ sqlite3 "file:nonexistent.db?mode=rw" "SELECT 1;"
Error: unable to open database "file:nonexistent.db?mode=rw": unable to open database file
```

`DOC` (rescode.html): the extended codes are `SQLITE_CANTOPEN_ISDIR`
(526), `_FULLPATH` (782), `_CONVPATH` (1038), `_SYMLINK` (1550, with
`SQLITE_OPEN_NOFOLLOW`), `_DIRTYWAL`, `_NOTEMPDIR`.

*The naive failure.* Reporting "unable to open database file" for all of
them. The user cannot tell "you gave me a directory" from "the parent
directory does not exist" from "you followed a symlink and I refused".

*The defence.* Map the extended codes to distinct diagnostics with help
naming the fix. This is a cheap, high-value use of T82.

*Whose.* DRIVER.

---

**T129 — A `PRAGMA` READ ALONE CREATES A ZERO-BYTE DATABASE FILE.**

*Behaviour.* `MEASURED`:

```
$ ls fl/                                  # empty directory
$ sqlite3 a.db "PRAGMA journal_mode;"     # a READ-ONLY pragma
delete
$ ls -la
-rw-r--r--  1 tristan  wheel  0 Sep  5 17:57 a.db     ← created, zero bytes
```

The default open flags include `CREATE`, so merely opening creates the
file — and a zero-byte file **is** a valid empty SQLite database (the
header is written on the first write).

*The naive failure.* A "does this database exist?" check implemented as
"open it and see" **creates** it, and the answer is always yes from then
on. A driver's `probe()`, a health check, or a CLI's `--check` flag all
land here.

*The defence.* Existence is a filesystem question, answered before the
open, or answered by opening with `SQLITE_OPEN_READONLY` (which errors if
absent — T124). Never by an open with `CREATE`.

*Whose.* DRIVER.

---

**T130 — URI FILENAMES ARE OFF BY DEFAULT AND CHANGE THE MEANING OF A
PATH.**

*Behaviour.* `MEASURED`, the parameters that matter:

```
$ sqlite3 "file:ro.db?mode=rwc" "CREATE TABLE t(x); INSERT INTO t VALUES(1);"     → ok
$ sqlite3 "file:ro.db?mode=ro"  "INSERT INTO t VALUES(2);"
Error: stepping, attempt to write a readonly database (8)
$ sqlite3 "file:ro.db?mode=ro"  "SELECT * FROM t;"                               → 1
$ sqlite3 "file:ro.db?mode=ro&immutable=1" "SELECT * FROM t;"                    → 1
```

`DOC` (uri.html): URI handling requires `SQLITE_OPEN_URI` (or
`SQLITE_USE_URI` at compile time). Parameters include `mode=` (`ro`/`rw`/
`rwc`/`memory`), `cache=` (`shared`/`private`), `psow=`, `nolock=`,
`immutable=`, and `vfs=`.

*The naive failure, and it is a security issue.* If URI handling is on and
a **caller-supplied path** reaches `sqlite3_open_v2` unfiltered, a path
beginning `file:` becomes a URI, and `?mode=`, `?vfs=` and `?nolock=1`
become caller-controlled. `nolock=1` in particular disables locking and is
a corruption vector; `vfs=` selects an alternate VFS.

*The defence.* Two shapes, and the driver picks the second:

- Leave URI handling **off**, so a path is always a path — but then
  `file::memory:?cache=shared` and read-only opens are unavailable.
- Enable it, and **never pass a caller's raw string as the filename**.
  The driver's open verb takes a path plus typed options (read-only,
  in-memory, shared), and constructs the URI itself with proper
  percent-encoding. A caller-supplied string that starts with `file:` is
  refused, not reinterpreted.

The second is the P8/P9 answer: the capability exists, and the boundary is
a contract rather than a string.

*Whose.* DRIVER.

---

**T131 — `:memory:` IS PRIVATE PER CONNECTION; SHARING ONE REQUIRES A URI
AND SHARED CACHE.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 "file::memory:?cache=shared" "CREATE TABLE t(x); SELECT count(*) FROM sqlite_schema;"
1
```

`DOC` (inmemorydb.html): two connections both opening `":memory:"` get
**two different databases**. Sharing requires `file::memory:?cache=shared`
(same-process, shared cache) or a named `file:name?mode=memory&cache=shared`.

*The naive failure.* A test suite that opens `:memory:` in a setup helper
and again in the test body finds an empty database and concludes the
driver's writes do not work. Or, in production, a "shared in-memory cache"
that is silently N private caches.

*The defence.* `open_memory()` is one connection's private database, and
says so. Sharing is a separate, explicitly-named verb which necessarily
brings shared cache with it — and therefore brings `SQLITE_LOCKED_SHAREDCACHE`
and the busy-handler exclusion of T57. That is a real trade, so it is a
separate verb with its own documentation, not a flag.

*Whose.* DRIVER.

---

**T132 — THE FILES A CONNECTION CREATES BESIDE THE DATABASE.**

*Behaviour.* `MEASURED` for WAL:

```
$ sqlite3 a.db "PRAGMA journal_mode=WAL; CREATE TABLE t(x); INSERT INTO t VALUES(1);"
$ ls -la
-rw-r--r--  8192  a.db
-rw-r--r-- 32768  a.db-shm
-rw-r--r--     0  a.db-wal
```

`DOC` (tempfiles.html): the full set a connection may create is
`<db>-journal` (rollback), `<db>-wal` and `<db>-shm` (WAL),
`<db>-journal` variants for super-journals in multi-database transactions,
plus unnamed temporary files for statement journals, the sorter, temp
tables, materialisations and the `TEMP` database.

*The naive failures.* (a) An application file-format or a deployment that
copies "the database" copies only `a.db` and — per T51 — loses committed
transactions or corrupts the file. (b) A container image or a
read-only-rootfs deployment where the *directory* is not writable: WAL
cannot create `-shm` and the database is unusable even for reading. (c) A
backup taken with `cp` while a connection is open.

*The defence.* The driver documents the file set at the open verb, offers
`VACUUM INTO` / the online backup API as the *correct* copy primitive, and
its diagnostics for `SQLITE_CANTOPEN`/`SQLITE_IOERR_SHMOPEN` name the
directory-writability requirement explicitly.

*Whose.* DRIVER documents; CALLER's deployment.

---

**T133 — TEMPORARY FILES ARE WHERE `ORDER BY` GOES, AND `temp_store`
DECIDES.**

*Behaviour.* `DOC` (tempfiles.html, pragma.html): temp tables, indices,
the sorter, materialised subqueries and transient views all live in the
TEMP database. `temp_store=MEMORY` (2) puts them in RAM; `FILE` (1) on
disk; `DEFAULT` (0) uses the compile-time setting. `MEASURED`: this
build's default is `0`.

*The naive failure.* Either direction. On disk: a sort spills into
`TMPDIR`, which in a container may be a tiny tmpfs, and the query fails
with a disk-full error unrelated to the database's own disk. In memory: a
large sort now consumes RAM and can OOM where it previously spilled — and
in a refcounted runtime with a memory watchdog, an OOM inside SQLite is
not a recoverable Avra error.

*The defence.* Do **not** blanket-set `temp_store=MEMORY`. Expose it, and
document both failure modes. The sorter's memory is also bounded by
`PRAGMA cache_size`, which is the knob that actually controls spill
behaviour.

*Whose.* CALLER; DRIVER exposes and documents.

---

**T134 — CORRUPTION IS REPORTED AS `SQLITE_CORRUPT` (11) FROM WHEREVER IT
IS NOTICED, INCLUDING FROM `integrity_check` ITSELF.**

*Behaviour.* `MEASURED` — 200 bytes of `0xFF` written over a page:

```
$ sqlite3 corrupt.db "PRAGMA integrity_check;"
Error: in prepare, database disk image is malformed (11)
$ sqlite3 corrupt.db "SELECT * FROM t;"
Error: in prepare, database disk image is malformed (11)
```

Note that `PRAGMA integrity_check` did **not** return a report of
problems — it failed with the error, because the corruption was bad enough
to break schema parsing. On a healthy database it answers `ok`
(`MEASURED`).

*The naive failure.* A driver whose "is this database healthy?" check is
`PRAGMA integrity_check` and which only handles the *result rows*, not the
*error*. On the databases that most need checking, the check itself
errors.

*The defence.* The health verb handles three outcomes, not two: a single
`ok` row; one or more problem rows; **and** an error return. And
`SQLITE_CORRUPT` is never in the retryable set (T72) — retrying a
corrupt database is a hot spin over a broken file.

*Whose.* DRIVER.

---

**T135 — RECOVERY IS AUTOMATIC AND IS ANNOUNCED ONLY ON THE LOG
CHANNEL.**

*Behaviour.* `DOC` (rescode.html): `SQLITE_NOTICE_RECOVER_WAL` (283) and
`SQLITE_NOTICE_RECOVER_ROLLBACK` (539) are *"not returned by the C
interface"* — they appear only through `SQLITE_CONFIG_LOG`.

*Why it matters.* After a process is killed mid-transaction, the next
connection recovers from the hot journal or the WAL automatically. That is
the correct behaviour, and it is also the only signal that the previous
process died badly.

*The naive failure.* A service that crashes and silently recovers on every
restart, with nobody ever learning that it is crashing.

*The defence.* Install a `SQLITE_CONFIG_LOG` handler at init and surface
notices through the driver's diagnostics. This also catches
`SQLITE_WARNING_AUTOINDEX` (284) — SQLite telling you a query needed an
index it had to build on the fly, which is a performance finding nobody
else will report.

*Whose.* DRIVER.

---

**T136 — A PROCESS TRAP CANNOT BE CAUGHT, AND THAT IS FINE — THE JOURNAL
IS THE RECOVERY.**

*Behaviour.* `INFERRED` from this project's own process law: `avra_trap`
exits 2 and nothing runs after it, so `defer`/`errdefer` frames do not
execute.

*What this means for the `tx` wrapper.* It **cannot rely on unwinding for
correctness**. It relies on the connection's close-time rollback (T80) and
on SQLite's journal (T135): an aborted process leaves a hot journal or an
uncheckpointed WAL, and the next connection recovers.

*The failure to actually avoid is the opposite one:* a wrapper that
catches a trap and continues, leaving a half-applied transaction visible
to the same process. It must not exist.

*Whose.* DRIVER's design constraint.

---

# Part 14 — PRAGMAS THAT ARE ACTUALLY API (T137–T150)

**T137 — A PRAGMA'S ANSWER IS DATA. CHECK IT; NEVER ASSUME IT.**

*Behaviour.* `MEASURED`, four different ways a pragma can silently not do
what it was told:

```
$ sqlite3 a.db     "PRAGMA journal_mode=WAL2;"      → wal        (T61: unknown mode, ignored)
$ sqlite3 :memory: "PRAGMA journal_mode=WAL;"       → memory     (a memory db cannot be WAL)
$ sqlite3 e16.db   "PRAGMA encoding='UTF-8';"       → UTF-16le   (T102: fixed at creation)
$ sqlite3 :memory: "BEGIN; PRAGMA foreign_keys=ON;
                    PRAGMA foreign_keys;"           → 0          (T79: no-op in a transaction)
```

Four silent no-ops. **None of them is an error.**

*Why.* A setting pragma answers the value actually in force, which is
SQLite's honest way of reporting a refusal without breaking programs that
set pragmas blindly.

*The naive failure.* A driver that runs its pragmas through
`sqlite3_exec` and ignores the result rows believes things about the
database that are not true, and documents them to its callers. Every
concurrency guarantee in its README becomes false at once.

*The defence.* **Every pragma the driver sets is set with a prepared
statement, stepped, and its answer compared against what was asked.** A
mismatch is a diagnostic naming both values. This is one function, used
for all of them.

*Whose.* DRIVER.

---

**T138 — `foreign_keys` IS OFF BY DEFAULT, AND MOST BINDINGS GET THIS
WRONG. TURN IT ON.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "PRAGMA foreign_keys;"                     → 0

$ sqlite3 :memory: "CREATE TABLE p(id INTEGER PRIMARY KEY);
                    CREATE TABLE c(pid INT REFERENCES p(id));
                    INSERT INTO c VALUES(999);
                    SELECT 'orphan inserted:', count(*) FROM c;"
orphan inserted:|1              ← the REFERENCES clause did nothing

$ sqlite3 :memory: "PRAGMA foreign_keys=ON; ...same...; INSERT INTO c VALUES(999);"
Error: stepping, FOREIGN KEY constraint failed (19)
```

`DOC` (quirks.html §6, foreignkeys.html): off by default *"for backwards
compatibility"*.

*The argument, since the brief asks for it.* **The driver sets
`foreign_keys=ON` at open, unconditionally, and the reasoning is not
"integrity is nice":**

- A `REFERENCES` clause that does nothing is **worse than no clause at
  all**. The schema states a constraint, every reader believes it, and
  nothing enforces it. That is a lie encoded in the schema — precisely
  what P9 forbids.
- The cost is real and bounded: a parent lookup per write, and — the part
  that actually bites — *"Indices are not required for child key columns
  but they are almost always beneficial"*, because without one, each
  parent delete is a table scan of the child. The driver's schema DSL
  therefore **indexes child key columns by default**, which converts the
  cost from O(n) to O(log n) and makes the default affordable.
- It cannot be turned on later: it is a no-op inside a transaction (T79),
  so a lazily-configured driver never enables it at all.
- The counter-argument — "it changes behaviour for existing databases" —
  is real, and is why it is a documented, one-argument opt-out at the open
  verb (P7, P8), not a hidden default.

*The one thing to also expose.* `defer_foreign_keys`: *"enforcement of all
foreign key constraints is delayed until the outermost transaction is
committed"* — the only way to write a cycle of mutual references. It is
*"automatically switched off at each COMMIT or ROLLBACK"*, so it must be
set **per transaction**; a driver that sets it once at open is setting
nothing.

*Whose.* DRIVER default; CALLER opts out.

---

**T139 — `journal_mode` — WAL by default, checked, and disclosed.**

See T51, T52, T61, T137. The driver offers WAL as its default, checks the
answer, and documents that setting it **changes the file permanently for
every other reader**.

---

**T140 — `synchronous` — NORMAL under WAL ONLY, and it is a durability
decision that belongs to the caller.**

*Behaviour.* `DOC` (pragma.html, wal.html): *"WAL mode is safe from
corruption with synchronous=NORMAL"* and it is *"the best balance between
performance and safety for most applications running in WAL mode"* — but
*"A transaction committed in WAL mode with synchronous=NORMAL might roll
back following a power loss."* In rollback-journal mode, NORMAL is **not**
corruption-safe.

`MEASURED` — the performance half of the trade, 5000 single-row
autocommit inserts:

| journal | synchronous | rows/s |
|---|---|---|
| delete | FULL | 3 338 |
| delete | NORMAL | 3 152 |
| delete | OFF | 4 262 |
| wal | FULL | 14 147 |
| wal | NORMAL | **26 592** |

**`synchronous=NORMAL` buys nothing under a rollback journal** (3 152 vs
3 338 — noise, and in the wrong direction) and **1.9× under WAL**. That is
exactly what the documentation implies, and it is worth having measured:
the pragma is only meaningful in combination with the journal mode.

*The defence.* The driver's default is WAL + NORMAL **and it is documented
at the open verb**, with `FULL` one argument away. Under a rollback
journal the driver keeps `FULL`, because NORMAL there costs safety for no
speed.

*Whose.* DRIVER's default; CALLER's decision, made visible.

---

**T141 — `cache_size`'s SIGN CHANGES ITS UNIT, AND THE DEFAULT'S SIGN IS
BUILD-SPECIFIC.**

*Behaviour.* `DOC` (pragma.html): *"If the argument N is positive then the
suggested cache size is set to N [pages]. If the argument N is negative,
then the number of cache pages is adjusted to be a number of pages that
would use approximately abs(N*1024) bytes."* It *"only endures for the
current session"* — it is per connection.

`MEASURED`: this build reports `cache_size` = **2000** (positive: 2000
*pages* = ~8 MB at 4 KiB) and its compile options say
`DEFAULT_CACHE_SIZE=2000`. Upstream's default is `-2000` (negative: ~2 MB).
**Same number, different unit, 4× the memory.**

*The naive failure.* A driver that "raises the cache to 8 MB" by setting
`2000` on a build whose page size is 8192 gets 16 MB; on a build already
using the negative convention it gets a 4× surprise. And N connections
cost N × the cache, so a pool multiplies the mistake.

*The defence.* **The driver always sets the negative (KiB) form**, so the
meaning does not depend on `page_size` or on the build's convention, and
it always sets it explicitly rather than inheriting. The value is a
documented open option, because the right number depends on the workload
and on how many connections exist.

*Whose.* DRIVER sets the form; CALLER sets the number.

---

**T142 — `busy_timeout` — set it, and know what it cannot do.**

Default is **0** (`MEASURED`), i.e. `SQLITE_BUSY` is returned immediately
on the first conflict. The driver sets a default (5000 ms is the
conventional choice) at open. See T54 (it and `busy_handler` replace each
other), T55 (it cannot save the promotion deadlock), T43 (the retry rule
is transaction-dependent). A long timeout converts a lock-ordering bug
into a hang, which is why it is exposed and bounded.

---

**T143 — `mmap_size` TURNS AN I/O ERROR INTO A SEGFAULT.**

*Behaviour.* `DOC` (mmap.html): with memory-mapped I/O, *"I/O errors can
cause a segmentation fault rather than returning an error code."*
`MEASURED`: default is `0` (off) on this build; `MAX_MMAP_SIZE` is
1 073 741 824.

*The naive failure.* A driver that enables mmap by default for the read
speedup has converted a recoverable `SQLITE_IOERR` into a process crash —
on network storage, on a failing disk, on a truncated file.

*The defence.* **Off by default; opt-in with the hazard documented at the
site.** A driver whose whole thesis is "no silent wrong answers" does not
enable, by default, a mode that converts a reportable error into a crash.

*Whose.* CALLER opts in.

---

**T144 — `temp_store` — expose, do not set.** See T133.

---

**T145 — `wal_autocheckpoint` — leave the default, expose the manual
checkpoint.** See T59, T60. Default is 1000 pages (`MEASURED`).

---

**T146 — DOUBLE-QUOTED STRING LITERALS: THE MOST DANGEROUS DEFAULT IN
SQLITE.**

*Behaviour.* `MEASURED` on this build (`DQS=3`, i.e. fully enabled):

```
$ sqlite3 :memory: 'CREATE TABLE t(name TEXT); INSERT INTO t VALUES(1);
                    SELECT * FROM t WHERE "no_such_column" = "no_such_column";'
1                    ← a misspelled identifier became a string literal; always true
```

`DOC` (quirks.html §10): *"SQLite will also interpret a double-quotes
string as string literal if it does not match any valid identifier."*
Since 3.27.0 it logs a warning; since 3.29.0 it is controllable at runtime
via `sqlite3_db_config()` with `SQLITE_DBCONFIG_DQS_DDL` (1014) and
`SQLITE_DBCONFIG_DQS_DML` (1013), and at compile time with
`-DSQLITE_DQS=N`:

| N | DDL | DML | |
|---|---|---|---|
| 3 | yes | yes | the default — **and this build's setting** |
| 2 | yes | no | |
| 1 | no | yes | |
| **0** | **no** | **no** | *"The recommended setting is 0"* |

*The naive failure.* `WHERE name = "alice"` with a misspelled column name
becomes `WHERE 'alice' = 'alice'` — always true — and returns the whole
table. A DELETE with the same typo deletes everything. There is no error,
no warning the application sees, and a compile-time SQL checker cannot
help if the engine accepts it.

*The defence.* Both belts: **`-DSQLITE_DQS=0` in the vendored build,
AND `sqlite3_db_config` for both DDL and DML at open** — because the
driver may one day be linked against someone else's library (this build,
for instance). This is the same belt-and-braces discipline this project
applies to the box header.

Corollary: the driver's identifier quoter **always** quotes, with `"`.
Given DQS=0 that spelling is unambiguous, and SQLite permits keywords as
identifiers (`CREATE TABLE union(true INT, with BOOLEAN)` is valid), so
unquoted identifiers are never safe to generate.

*Whose.* DRIVER, twice.

---

**T147 — `optimize` ON CLOSE, BOUNDED BY `analysis_limit`.**

*Behaviour.* `DOC` (pragma.html): *"applications with short-lived database
connections should run `PRAGMA optimize;` once, just prior to closing each
database connection"*; `analysis_limit` *"prevents the ANALYZE invocations
from running for too long"*. `MEASURED`: this build's `analysis_limit`
default is **0** (unlimited), and `PRAGMA analysis_limit=400; PRAGMA
optimize;` runs cleanly.

*The naive failure.* Running `optimize` with `analysis_limit=0` on a large
table makes every connection close slow and unpredictable — an ANALYZE
scan on a path nobody expects to take time.

*The defence.* Set `analysis_limit=400` at open **and** run `PRAGMA
optimize` at close. Both, or neither; `optimize` without the limit is the
trap.

*Whose.* DRIVER.

---

**T148 — THE SCHEMA INTROSPECTION PRAGMAS AN ORM NEEDS, AND WHAT EACH
ACTUALLY ANSWERS.**

*Behaviour.* `MEASURED`, against this schema:

```sql
CREATE TABLE p(id INTEGER PRIMARY KEY, name TEXT NOT NULL DEFAULT 'x');
CREATE TABLE c(id INTEGER PRIMARY KEY, pid INT REFERENCES p(id) ON DELETE CASCADE,
               tag TEXT COLLATE NOCASE);
CREATE UNIQUE INDEX c_tag ON c(tag);
CREATE TABLE w(a TEXT, b TEXT, PRIMARY KEY(a,b)) WITHOUT ROWID;
```

```
PRAGMA table_info(c);
cid|name|type|notnull|dflt_value|pk
0|id|INTEGER|0||1                       ← note notnull=0 for the rowid alias (T11)
1|pid|INT|0||0
2|tag|TEXT|0||0

PRAGMA table_xinfo(c);                   ← same, plus a `hidden` column
cid|name|type|notnull|dflt_value|pk|hidden
0|id|INTEGER|0||1|0
...

PRAGMA foreign_key_list(c);
id|seq|table|from|to|on_update|on_delete|match
0|0|p|pid|id|NO ACTION|CASCADE|NONE

PRAGMA index_list(c);
seq|name|unique|origin|partial
0|c_tag|1|c|0                            ← origin: 'c'=CREATE INDEX, 'u'=UNIQUE, 'pk'=PRIMARY KEY

PRAGMA index_info(c_tag);
seqno|cid|name
0|2|tag

PRAGMA index_xinfo(c_tag);               ← the COLLATION and the auxiliary columns
seqno|cid|name|desc|coll|key
0|2|tag|0|NOCASE|1
1|-1||0|BINARY|0                         ← cid=-1 is the rowid; key=0 means auxiliary

PRAGMA table_list;
schema|name|type|ncol|wr|strict
main|w|table|2|1|0                       ← wr=1 means WITHOUT ROWID
main|c|table|3|0|0
main|p|table|2|0|0
main|sqlite_schema|table|5|0|0
temp|sqlite_temp_schema|table|5|0|0
```

The distinctions that matter:

| Pragma | Use it for | The gotcha |
|---|---|---|
| `table_info` | columns, types, notnull, default, pk position | omits hidden columns; `notnull=0` for a rowid alias (T11) |
| `table_xinfo` | the same **plus hidden** columns | the only way to see a virtual table's or a generated column's hidden columns |
| `table_list` | every table with `ncol`, `wr` (WITHOUT ROWID) and **`strict`** in one query | includes `sqlite_schema` and the temp schema — filter them |
| `foreign_key_list` | FK definitions incl. `on_delete`/`on_update`/`match` | ordered by `id`,`seq` for composite keys — group by `id` |
| `index_list` | indices, uniqueness, **origin**, partial | `origin` tells an explicit index from an implicit UNIQUE/PK one — an ORM must not try to recreate implicit ones |
| `index_info` | key columns only | silently omits auxiliary columns |
| `index_xinfo` | key **and** auxiliary columns, with `desc` and `coll` | `cid = -1` is the rowid; `key = 0` marks auxiliary |

Every one of these has a **table-valued function** form
(`pragma_table_info('c')`, …) that can be joined and filtered
(`MEASURED`), which is how introspection should actually be written:

```
$ sqlite3 :memory: "CREATE TABLE c(id INTEGER PRIMARY KEY, tag TEXT);
                    SELECT name, type, \"notnull\", pk FROM pragma_table_info('c');"
id|INTEGER|0|1
tag|TEXT|0|0
```

*The defence.* The driver's introspection layer uses the `pragma_*`
table-valued functions, not the pragma statements, so the results are
ordinary rows that can be joined, filtered and bound — and so the
"iterate a pragma's result set" special case never exists. Use
`table_xinfo` and `index_xinfo` (the supersets), and `table_list` for the
`strict`/`wr` facts nothing else reports.

*Whose.* DRIVER.

---

**T149 — INTROSPECTING A TABLE THAT DOES NOT EXIST ANSWERS *NOTHING*, NOT
AN ERROR.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "PRAGMA table_info(nope);"
                                          ← zero rows, exit 0, no error
```

*Why.* This is the empty-value law at the introspection layer: "no such
table" and "a table with no columns" are encoded identically, and only one
of them can actually exist.

*The naive failure.* A migration tool asks `table_info(users)`, gets zero
rows, and concludes the table exists but has no columns — or, more
commonly, its `for column in table_info(t)` loop simply does nothing and
the migration reports success having done nothing.

*The defence.* **Write the empty case first.** Existence is established by
`sqlite_schema` / `table_list`, never inferred from an empty `table_info`.
The driver's `columns_of(table)` verb answers `Result` or a nullable, and
its empty answer means "no such table", stated at the call.

*Whose.* DRIVER.

---

**T150 — `integrity_check` VS `quick_check`, AND WHAT THEY COST.**

*Behaviour.* `DOC` (pragma.html): `integrity_check` verifies the whole
database including index consistency and content; `quick_check` skips the
index-content verification and is therefore much faster. Both answer a
single row `ok` on success (`MEASURED`), or one row per problem, up to a
limit (`PRAGMA integrity_check(N)`).

*The naive failure.* Running `integrity_check` on a large database as a
routine health check reads every page. See T134 for the third outcome
(the check itself erroring) that the naive two-outcome handler misses.

*The defence.* Expose both, name the cost in each verb's contract, and
handle three outcomes.

*Whose.* CALLER; DRIVER exposes.

---

## 14.1 THE DEFAULTS DECISION TABLE

Everything above, as one table a reviewer can argue with.

| Pragma / setting | Driver default | Why | What it costs |
|---|---|---|---|
| `SQLITE_OPEN_EXRESCODE` | **on** | T82: otherwise every constraint is code 19 | nothing |
| `foreign_keys` | **ON** | T138: an unenforced `REFERENCES` is a lie in the schema | a parent lookup per write; index child keys |
| `journal_mode` | **WAL**, checked | T51: readers never block the writer | one host only; two extra files; unbounded WAL under overlapping readers; permanent file change (T52) |
| `synchronous` | **NORMAL under WAL, FULL otherwise** | T140: measured 1.9× under WAL, nothing under a rollback journal | a committed transaction may roll back on power loss |
| `busy_timeout` | **5000 ms** | T142: turns transient BUSY into a wait | cannot save the promotion deadlock (T55); a long value hides lock-order bugs |
| `cache_size` | **negative form, explicit** | T141: the unit is sign-dependent and the default's sign is build-specific | RSS per connection |
| `analysis_limit` | **400** | T147: bounds `optimize` | approximate statistics |
| `optimize` | **at close** | T147 | a bounded ANALYZE |
| `mmap_size` | **0 (off)** | T143: mmap turns an I/O error into a segfault | forgoes a read speedup |
| `temp_store` | **unset (expose)** | T133: both directions have a failure mode | — |
| `secure_delete` | **unset (expose)** | a secrets database wants `FAST`; that is a caller's call | — |
| `page_size` | **unset** | applies only at creation or `VACUUM`; setting it on an existing database silently does nothing | — |
| `wal_autocheckpoint` | **default 1000 (expose)** | T59 | a random writer pays the checkpoint |
| `query_only` | **ON for read-only connections** | a cheap checkable guarantee | — |
| `defer_foreign_keys` | **exposed, per transaction** | T138: the only way to write mutual references | reset at every COMMIT/ROLLBACK |
| DQS (`db_config` + `-DSQLITE_DQS=0`) | **off, both** | T146: the most dangerous default in SQLite | rejects DDL that relied on it |
| `SQLITE_THREADSAFE` | **2 (multi-thread)** | T65 | one owner at a time, enforced by API shape |
| Vendored version | **≥ 3.53.0** | T119: float rendering round-trips | — |

---

# Part 15 — PERFORMANCE, MEASURED NOT REASONED (T151–T162)

> *All numbers below were measured on the machine described in §0.3
> (Apple SQLite 3.51.0, macOS, APFS on SSD) using the `sqlite3` shell.
> They include SQL **parse** cost per statement, because the shell
> re-parses every line — so they are a **floor** for a driver that reuses
> prepared statements, not a ceiling. Timings are wall clock over the
> whole process, single runs. They are honest, they are not a benchmark
> suite, and the driver's own numbers must be re-measured with its own
> harness.*

---

**T151 — A QUERY IS A FUNCTION CALL, NOT A ROUND TRIP, AND THAT INVERTS
CLIENT-SERVER INTUITION.**

*Behaviour.* `DOC` (np1queryprob.html): *"Queries do not involve message
round-trips, only a function call. The latency of a single SQL query is far
less in SQLite."*

*Why it matters for the ORM built on this driver.* The N+1 query pattern
that is a catastrophe against Postgres is **acceptable** against SQLite.
A driver or ORM that imports client-server assumptions — eager-loading
machinery, join-flattening, a query batcher — adds complexity to solve a
problem that does not exist here, and the complexity has its own bugs.

*Whose.* DRIVER's API design; ORM's design.

---

**T152 — THE TRANSACTION IS THE UNIT OF DISK COST. MEASURED: 134× ON THIS
MACHINE, NOT 1000×.**

*Behaviour.* `MEASURED`, 5000 single-row inserts, rollback journal,
`synchronous=FULL`:

| Shape | rows/s | ratio |
|---|---|---|
| autocommit (one transaction per INSERT) | 3 338 | 1× |
| one enclosing `BEGIN … COMMIT` | **448 316** | **134×** |

And under WAL + `synchronous=NORMAL`:

| Shape | rows/s | ratio |
|---|---|---|
| autocommit | 26 592 | 1× |
| one transaction | **386 255** | **14.5×** |

At scale, 200 000 rows in one transaction under WAL + NORMAL:
**642 689 rows/s** (0.311 s).

*Why the famous number is different.* `DOC` (faq.html): *"each INSERT
statement is its own transaction"*, and *"Transaction speed is limited by
the rotational speed of your disk drive. A transaction normally requires
two complete rotations of the disk platter, which on a 7200RPM disk drive
limits you to about 60 transactions per second."* Against 60 tps, batching
is ~7 500×. On this SSD the floor is 3 338/s, so the same batching is
134×. **The multiplier is a property of the storage device, not of
SQLite.** Quoting "1000×" as a fact is the exact failure mode this
project's doctrine names: an explanation written before either side was
run.

*The naive failure.* A driver whose only write verb is a single autocommit
`INSERT` makes every caller's bulk load two orders of magnitude slower,
and no amount of driver-level optimisation recovers it.

*The defence.* The write surface makes batching the **easy** thing: a
`tx` block (T71) and a batch-insert verb that chunks by the *read*
parameter limit (T115). The ratio itself is a published, regression-tested
number, measured on the CI machine, not quoted from folklore.

*Whose.* DRIVER's API shape.

---

**T153 — WAL IS A 4× WIN ON SMALL WRITES, BEFORE ANY CONCURRENCY
BENEFIT.**

*Behaviour.* `MEASURED`, 5000 autocommit inserts:

| journal | synchronous | rows/s | vs baseline |
|---|---|---|---|
| delete | FULL | 3 338 | 1.0× |
| delete | NORMAL | 3 152 | 0.94× |
| delete | OFF | 4 262 | 1.3× |
| memory | OFF | 5 326 | 1.6× |
| **wal** | **FULL** | **14 147** | **4.2×** |
| **wal** | **NORMAL** | **26 592** | **8.0×** |

Two findings worth stating separately:

- **WAL alone, at full durability, is 4.2×** on small transactions. It is
  not only a concurrency feature.
- **`synchronous=OFF` under a rollback journal buys only 1.3×** — the
  journal file's create/write/delete cycle dominates the fsync. Turning
  off durability is a bad trade there: most of the safety, almost none of
  the speed.

*Whose.* DRIVER's default (T140).

---

**T154 — PREPARED STATEMENT REUSE IS THE MAIN DRIVER-LAYER LEVER.**

*Behaviour.* `INFERRED`, and marked as such: the numbers above **include**
a parse per row, so they do not isolate prepare from step. `DOC` gives the
mechanism: prepare is a parse, a name resolution and a query-plan compile;
step is the plan running. Reuse turns per-call cost from "parse + plan +
run" into "reset + bind + run".

*The naive failure.* A driver that prepares per call spends most of its
CPU in the parser. This is the *only* documented-mechanism reason a SQLite
binding is ever slow at the driver layer — the engine is not the
bottleneck, the binding is.

*The defence.* A statement cache keyed by the SQL text, with
`reset` + `clear_bindings` between uses (T41), `SQLITE_PREPARE_PERSISTENT`
on cached statements (T157), and a bounded size whose memory is
**measured and reported** rather than hoped at.

*The measurement the driver owes.* Prepare-vs-step is not measurable from
the shell, so it must be measured in the driver's own harness: the same
query N times, prepared once versus prepared per call. Until that number
exists, this trap's magnitude is unquantified — which is exactly why it is
marked `INFERRED`.

*Whose.* DRIVER.

---

**T155 — `sqlite3_exec` CANNOT BIND, AND STRINGIFIES EVERY RESULT.**

*Behaviour.* `DOC` (c3ref/exec.html): a convenience wrapper around
`prepare_v2`/`step`/`finalize` that *"runs zero or more UTF-8 encoded,
semicolon-separated SQL statements"*; its callback receives `char**`
values, so **every column is stringified**; its `errmsg` out-parameter
must be freed with `sqlite3_free`. It has **no parameter binding at all**.

*The naive failure.* A driver that reaches for `exec` for "simple"
queries re-parses the SQL every call, destroys the storage class of every
value (Part 1's entire foundation), and forces string interpolation for
parameters — which is the injection surface and the DQS surface (T146) at
once.

*The defence.* `exec`'s only legitimate use in this driver is a pragma or
a parameterless migration script, and even there the result is checked.
Better: do not link it at all, and write the tail loop of T36 by hand —
one function, and the `sqlite3_free` obligation disappears with it.

*Whose.* DRIVER, by omission.

---

**T156 — BINDING BEATS INTERPOLATION ON EVERY AXIS.**

Interpolation re-parses (T154), destroys the storage class (T155, Part 1),
invites injection, and — via DQS (T146) — can turn a misspelled identifier
into an always-true predicate. There is no axis on which it wins. Recorded
as a trap because "just format the number in, it's faster" is a real
instinct.

---

**T157 — `SQLITE_PREPARE_PERSISTENT` EXISTS FOR CACHED STATEMENTS.**

*Behaviour.* `DOC`, verbatim (`sqlite3.h`, prepare flags): *"The
SQLITE_PREPARE_PERSISTENT flag is a hint to the query planner that the
prepared statement will be retained for a long time and probably reused
many times. Without this flag, sqlite3_prepare_v3() … assume that the
prepared statement will be used just once or at most a few times and then
destroyed using sqlite3_finalize() relatively soon. The current
implementation acts on this hint by avoiding the use of lookaside memory
so as not to deplete the limited store of lookaside memory."*

*The naive failure.* A statement cache without the flag drains the
lookaside pool (`DEFAULT_LOOKASIDE=1200,102` on this build — about 122 KB
per connection), so every *other* allocation on that connection falls back
to the general heap and gets slower. The cache makes the connection
slower in a way that profiling attributes to the wrong place.

*The defence.* Cached statements are prepared with
`SQLITE_PREPARE_PERSISTENT`; one-shot statements are not. Also useful:
`SQLITE_PREPARE_NO_VTAB` (refuse a statement that uses virtual tables) and
`SQLITE_PREPARE_DONT_LOG` (compile without writing to the error log —
exactly right for a compile-time SQL checker doing test compiles).

*Whose.* DRIVER.

---

**T158 — COLUMN ACCESS ORDER DOES NOT MATTER FOR SPEED, BUT ACCESS *COUNT*
DOES.**

*Behaviour.* `INFERRED` from the C API's shape: `sqlite3_column_*` reads
from an already-materialised register array, so the *order* of columns
within a row is not a cost. What costs is the **number of SQLite calls
per column** and the **conversions** those calls trigger (T17, T19).

*The budget, restated as a testable number.* Per column:
`column_type` + one value accessor + (`column_bytes` for text/blob) =
**≤ 3 calls, 2 for scalars**. A driver that reads a value twice, or
measures before reading, or renders for a diagnostic, pays 4–6 and an
extra conversion.

*The defence.* The single `read_column` of T20 makes the count structural.
A test shim that counts C entry-point calls per row turns this budget into
a gate.

*Whose.* DRIVER.

---

**T159 — THE `column_text` CONVERSION COST IS PAID *INSIDE* SQLITE AND IS
INVISIBLE TO AVRA PROFILING.**

*Behaviour.* `INFERRED` from T17/T19: converting an INTEGER or REAL to
TEXT runs `sqlite3_snprintf` inside the engine and allocates in SQLite's
allocator.

*Why it is a trap for this project specifically.* This tree's memory
accounting (`AVRA_MEM_STATS`) reports **Avra's** allocations by category
and site. A conversion inside SQLite is invisible to it: the profile shows
a fast Avra path and the wall clock disagrees, and the standing advice
("profile, don't reason") points at the wrong half of the process.

*The defence.* Never convert (T20's class-first dispatch means the driver
requests the format the value already has). And when profiling the driver,
sample the **process**, not just the Avra allocator, and measure driver
time against the `sqlite3` shell doing the same work — *"driver time minus
engine time"* is the only honest overhead number, and it is obtainable
because the engine is vendored (T126).

*Whose.* DRIVER's measurement discipline.

---

**T160 — PAGE SIZE IS SET ONCE, AT CREATION OR AT `VACUUM`.**

*Behaviour.* `DOC` (pragma.html): *"Specifying a new page size does not
change the page size immediately"* — it applies when the database is first
created, or at the next `VACUUM`. Default 4096 since 3.12.0 (`MEASURED`:
4096 on this build); legal values are powers of two from 512 to 65536.
And in WAL mode the page size cannot be changed at all (T51).

*The naive failure.* A driver that sets `page_size` on an existing
database appears to succeed and does nothing. The pragma's answer is the
*current* size, which is how to detect it — T137 again.

*The defence.* Do not set it. If a caller needs a different page size, it
is a creation-time option, and the driver's create path is the only place
it is legal.

*Whose.* CALLER at creation.

---

**T161 — THE PERFORMANCE BUDGET, AS NUMBERS A TEST CAN FAIL ON.**

A driver claim is not a claim until it is a measurement. The proposed
gate, each item measurable with this project's existing tools:

| Property | Budget |
|---|---|
| Allocations per row, all-scalar row type | **0** — scalars ride registers, no box is minted (T26) |
| Allocations per TEXT/BLOB column | **exactly 1** — the mandatory copy, sized from `column_bytes`, never a second for length or diagnostics |
| `strlen` calls per bind and per read | **0** — the header carries the length on both sides (T35, T90) |
| SQLite calls per column read | **≤ 3** (2 for scalars) — T158 |
| Prepares per distinct SQL text per connection | **1** — T154 |
| Bytes resident per cached statement | measured and reported, so the cache bound is a number |
| Insert throughput, 100k rows, one transaction, WAL + NORMAL | pinned; the **ratio** to the same rows in autocommit is the published claim (T152), re-measured on the CI machine |
| Interpreted vs native answers | **identical**, by construction |

---

**T162 — MEASURE THE DRIVER AGAINST THE SHELL, NOT AGAINST ANOTHER
LANGUAGE'S BINDING.**

*The rule.* A benchmark against a Python binding proves only that Python
is slow. The honest number is *driver time minus engine time*, and the
`sqlite3` shell running the same SQL is the closest available measure of
engine time.

*The trap it prevents.* Publishing a favourable ratio against a slow
comparator and never discovering that the driver's own overhead is 3× the
engine's.

*Whose.* DRIVER's benchmark design.

---

# Part 16 — THE REMAINING SURPRISES (T163–T174)

*Not in the brief's fifteen topics, but each one breaks a naive binding,
and several break an ORM built on one.*

---

**T163 — `last_insert_rowid` IS CONNECTION-SCOPED, TRIGGER-AWARE, NOT
ROLLED BACK, AND SILENT ABOUT `WITHOUT ROWID`.**

*Behaviour.* `MEASURED` — the `WITHOUT ROWID` case, which is the sharp
one:

```
$ sqlite3 :memory: "CREATE TABLE w(a TEXT PRIMARY KEY) WITHOUT ROWID;
                    CREATE TABLE r(x);
                    INSERT INTO r VALUES(9);        -- rowid 1
                    INSERT INTO w VALUES('k');      -- WITHOUT ROWID: not recorded
                    SELECT last_insert_rowid();"
1                    ← the PREVIOUS insert's rowid. No error.
```

`DOC` (c3ref/last_insert_rowid.html), the full rule set:
zero if no successful insert into a rowid table has occurred on the
connection; inside a trigger it reports the trigger's insert and *"Once
the trigger program ends, the value returned by this routine reverts to
what it was before the trigger was fired"*; *"Inserts into WITHOUT ROWID
tables are not recorded"*; a constraint-failed INSERT does not change it,
but *"an INSERT is considered to be successful even if it is subsequently
rolled back"*; unpredictable if another thread inserts concurrently on the
same connection; settable with `sqlite3_set_last_insert_rowid()`.

*The naive failure.* Two wrong answers with no error either time: after a
rolled-back transaction it names a row that does not exist; after a
`WITHOUT ROWID` insert it names a completely different table's row.

*The defence.* Read it **immediately after the insert's `step`, inside the
same transaction**, never as a general "what did I just insert" query. For
`WITHOUT ROWID` tables the driver refuses to offer it at all — the table
kind is knowable from `PRAGMA table_list` (`wr` column, T148). Better
still: prefer `INSERT … RETURNING`, which answers the actual row and has
no connection-scoped state — subject to T45.

*Whose.* DRIVER.

---

**T164 — `changes()` AND `total_changes()` COUNT DIFFERENT THINGS, AND
NEITHER COUNTS WHAT MOST PEOPLE THINK.**

*Behaviour.* `MEASURED`, three cases:

```
-- an AFTER INSERT trigger that inserts into another table
changes()=1   total_changes()=2      ← the trigger's insert: excluded / included

-- ON DELETE CASCADE removing 3 child rows
changes()=1   total_changes()=8      ← the cascade: excluded / included
                                       (8 = 1 parent + 3 children inserted, then 1 + 3 deleted)

-- INSERT OR REPLACE over an existing row
changes()=1   total_changes()=2      ← the implicit DELETE is not counted
```

`DOC`: `sqlite3_changes` counts *"the number of rows modified, inserted or
deleted by the most recently completed INSERT, UPDATE or DELETE
statement"*, and *"Only changes made directly … are considered - auxiliary
changes caused by triggers, foreign key actions or REPLACE constraint
resolution are not counted"*. `sqlite3_total_changes` counts everything
since the connection opened **including** triggers and FK actions, but
**not** REPLACE constraint resolution.

*The naive failure.* An ORM reporting "1 row updated" from `changes()` on
a cascading delete is correct about the statement and wrong about the
effect. And a driver using `total_changes()` as a cheap
"did-anything-change" dirty flag misses REPLACE entirely.

*The defence.* Expose both, name what each counts in its contract, and use
the `64` variants (T32). Both are unpredictable under concurrent use of
one connection (T66).

*Whose.* DRIVER's contracts.

---

**T165 — NO `ORDER BY` MEANS NO ORDER, AND `ORDER BY` IS NOT A STABLE
SORT.**

*Behaviour.* `DOC` (lang_select.html): *"The order in which two rows for
which all ORDER BY expressions evaluate to equal values are returned is
undefined"*, and a `SELECT` without `ORDER BY` returns rows in an order
that is undefined and may change between releases and between query plans.

`MEASURED`, honestly reported: a six-row table with a tied `ORDER BY`
paginated `LIMIT 3 OFFSET 0` / `OFFSET 3` returned `1,2,3` and `4,5,6` —
i.e. **the instability did not reproduce** in a trivial case. That is
exactly what makes it dangerous: it is stable until the table is large
enough for a different plan.

*The naive failure.* Pagination. `ORDER BY created_at LIMIT 20 OFFSET 20`
over rows sharing a timestamp returns overlapping and missing rows between
pages, non-deterministically, and the bug is unreproducible in a small
test.

*The defence.* The driver's pagination helper **always appends a unique
tiebreak** (`rowid` or the primary key), and the compile-time SQL checker
warns on a `LIMIT`/`OFFSET` whose `ORDER BY` is not provably unique.
Keyset pagination (`WHERE (ts, id) > (?, ?)`) is offered as the correct
form for large result sets.

*Whose.* DRIVER's builder.

---

**T166 — BARE COLUMNS IN AN AGGREGATE QUERY ARE LEGAL, AND USUALLY
ARBITRARY.**

*Behaviour.* `DOC` (quirks.html §8): *"Output columns of an aggregate
query can be arbitrary expressions that include columns not found in the
GROUP BY clause."* With a single `min()`/`max()` the bare column comes
from the extremum row — a genuinely useful, entirely non-standard
guarantee. **Without one, it comes from an arbitrary row.**

*The naive failure.* The most portable-looking wrong query there is. It
runs, it returns plausible data, and the bare column's value is whichever
row the plan happened to end on.

*The defence.* Compile-time checker territory: **warn** on a bare column
not covered by the min/max rule. The driver's own generated SQL never
emits one.

*Whose.* DRIVER's checker; CALLER's raw SQL.

---

**T167 — UNICODE CASE FOLDING IS ASCII-ONLY.**

*Behaviour.* `DOC` (quirks.html §9): *"SQLite does not know about the
upper-case/lower-case distinction for all unicode characters"*. `upper()`,
`lower()`, `LIKE`'s case-insensitivity and `COLLATE NOCASE` are all ASCII
unless built with ICU.

*The naive failure.* A case-insensitive unique index on non-ASCII text is
a **silent lie**: `Ä` and `ä` are distinct under `NOCASE`, so the
constraint does not do what its name says, and duplicates accumulate.

*The defence.* Document it at the collation. If case-insensitive matching
over non-ASCII text is required, the honest answers are an ICU build or a
normalised shadow column the application maintains — both of which are
caller decisions with visible costs.

*Whose.* CALLER, made visible by the driver.

---

**T168 — `LIKE` HAS A PATTERN-LENGTH CEILING AND A COMPILE-TIME BEHAVIOUR
SWITCH.**

*Behaviour.* `SQLITE_MAX_LIKE_PATTERN_LENGTH` defaults to 50 000
(`MEASURED`: 50 000 on this build); a longer pattern is an error. And
`-DSQLITE_LIKE_DOESNT_MATCH_BLOBS`, which is on SQLite's *recommended*
options list, makes *"LIKE and GLOB operators always return FALSE if
either operand is a BLOB"*.

*The naive failure.* The second is a **behaviour change**, not an
optimisation: a database written by one build and queried by another
disagrees about what `LIKE` matches. Taking a recommendation without
reading it is how that lands.

*The defence.* Decide it deliberately in the vendored build (T126) and
assert it in the `compile_options` fixture.

*Whose.* DRIVER's build.

---

**T169 — COMMA JOINS HAVE THE SAME PRECEDENCE AS OTHER JOINS.**

*Behaviour.* `DOC` (quirks.html §16): *"SQLite gives all join operators
equal precedence and processes them from left to right"*, so a `FROM`
clause mixing comma joins with `RIGHT`/`FULL OUTER JOIN` parses
differently from the standard. Parentheses are the workaround.

*The defence.* The driver's generated SQL never emits a comma join.

*Whose.* DRIVER's builder.

---

**T170 — THERE IS NO `BOOLEAN` AND NO `DATETIME`.**

*Behaviour.* `DOC` (quirks.html §3, §4). Booleans are integers 0/1
(`TRUE`/`FALSE` keywords exist since 3.23.0). Dates and times are TEXT
(ISO-8601), INTEGER (unix epoch) or REAL (Julian day) — SQLite does not
choose.

*The naive failure.* For booleans: a `bool` reader that accepts any
non-zero integer silently turns a `2` into `true`. For datetimes:
**auto-detection**, which is where every other binding's timezone bugs
live — an INTEGER column is unix seconds *or* Julian days and nothing in
the database says which, so a driver that guesses is wrong for someone.

*The defence.* The `bool` reader accepts INTEGER 0 and 1 and **refuses
2**. The driver picks **one** datetime encoding, states it, and does not
auto-detect; reading a foreign column in another encoding is an explicit,
named conversion.

*Whose.* DRIVER.

---

**T171 — `sqlite3_stmt_readonly` CALLS `BEGIN`/`COMMIT` READ-ONLY.**

*Behaviour.* `DOC` (c3ref/stmt_readonly.html): transaction control
statements are classified read-only because *"the statements themselves do
not actually modify the database"*. And the guarantee is one-directional:
*"A false return does not guarantee that the statement will change the
database file"* — while a *true* return can still be wrong if a virtual
table or user function writes.

*The naive failure.* A driver that routes statements to a read replica by
`stmt_readonly` sends the transaction control to the replica and the
writes to the primary.

*The defence.* Do not route by it. It is useful as an assertion on a
`query_only` connection, not as a router.

*Whose.* DRIVER.

---

**T172 — `SQLITE_ENABLE_API_ARMOR` IS WORTH HAVING ON.**

*Behaviour.* `MEASURED`: this build has it. `DOC`: with API armor, SQLite
checks its own parameters and returns `SQLITE_MISUSE` instead of
dereferencing a bad pointer.

*Why it matters here.* A driver crossing an FFI boundary from a
refcounted language will, during development, pass a wrong pointer. API
armor turns that from a segfault into a `SQLITE_MISUSE` the driver can
report as a defect (T46) with a call site attached.

*The defence.* Compile the vendored amalgamation with
`-DSQLITE_ENABLE_API_ARMOR`, at least for the test build. The cost is a
few branches per entry point.

*Whose.* DRIVER's build.

---

**T173 — `UPSERT`'s CONFLICT TARGET MUST BE A REAL UNIQUE CONSTRAINT, AND
NULLS DEFEAT IT.**

*Behaviour.* `MEASURED`:

```
$ sqlite3 :memory: "CREATE TABLE u(k INTEGER PRIMARY KEY, v);
                    INSERT INTO u VALUES(1,'a') ON CONFLICT(k) DO UPDATE SET v='b' RETURNING k, v;"
1|a
```

The upsert took the insert path and `RETURNING` reported it. Combined with
T93 (a UNIQUE column accepts any number of NULLs), the trap is:
**an upsert whose conflict target is a nullable unique column never
conflicts**, so it inserts a new row every time.

*The defence.* T93's rule — the driver's schema layer refuses a nullable
`UNIQUE` column as a conflict target — plus `RETURNING` as the way to
learn which path was taken, subject to T45's warning that a `RETURNING`
statement's failure can arrive at `reset`.

*Whose.* DRIVER's schema and upsert verbs.

---

**T174 — SQLITE ACCEPTS DUBIOUS SQL WITHOUT WARNING, ON PURPOSE.**

*Behaviour.* `DOC` (quirks.html §12): SQLite deliberately follows Postel's
law and accepts input that other engines reject.

*Why it is the last trap in this document.* It is the gap this project is
uniquely positioned to fill. *"The compiler holds semantic knowledge no
other tool has"* (P10) — a compile-time SQL checker is not a nicety on top
of SQLite, it is **the missing half of SQLite**. Every trap in this
document marked "compile-time checker territory" (T8, T92, T165, T166) is
a warning no other SQLite binding in any language can emit, because none of
them has a compiler.

*Whose.* The campaign's later expansion.

---

# Appendix A — THE TEST PLAN

Each row is a test the driver should carry, citing its trap. Ordered by
how badly the absence of the test hurts.

## A.1 The ten that must exist before the driver is called correct

| # | Test | Cites | Passes when |
|---|---|---|---|
| 1 | **Class-first read**: a shim counts C entry-point calls per column and asserts the sequence `column_type` → value → `column_bytes` → copy | T17–T21, T158 | no other order ever occurs, for any column type |
| 2 | **Mixed-class column**: `CREATE TABLE t(a)` holding integer/text/real/blob/null in five rows, read into a typed seat | T1, T14 | rows 2–5 refuse with a diagnostic naming the class; none coerces |
| 3 | **The empty triple**: write SQL NULL, `''` and `x''`; read all three back | T96, T97, T29 | three distinct values; the empty blob is not `null`; the empty string is not `null` |
| 4 | **Empty bind**: bind an empty string and an empty blob | T29 | `typeof` answers `text`/`blob`, never `null` |
| 5 | **Rebind reuse**: cache a 3-parameter statement, reuse it rebinding only 2 | T41, T40 | refuses before stepping; never writes the previous row's value |
| 6 | **The `tx` error path**: force a `SQLITE_FULL`-class error inside a transaction | T69 | asks autocommit first; no "cannot rollback" message ever replaces the real error |
| 7 | **`BEGIN IMMEDIATE` default**: two connections, read-then-write | T71, T43 | no `SQLITE_BUSY_SNAPSHOT`; a busy from the top is retried, not from the middle |
| 8 | **Error capture ordering**: fail a step, then let the cleanup run | T85, T30 | the reported code/message/offset are the step's, and the message is an owned copy |
| 9 | **`sum()` of nothing**: `SELECT sum(x)` over zero rows into an `int` seat | T95, T14 | refuses; never answers 0 |
| 10 | **Pragma answers**: set `journal_mode`, `foreign_keys`, `encoding` in hostile conditions | T137, T79, T102, T61 | every silent no-op is detected and reported |

## A.2 The rest, by part

| Part | Test | Cites |
|---|---|---|
| 1 | STRICT DDL round trip: the generated schema refuses a lossy write | T12, T2 |
| 1 | `notnull` mapping across rowid / WITHOUT ROWID / STRICT tables | T11 |
| 1 | i64 into a REAL column: 2^53+1 in, assert the refusal (not the silent change) | T6, T114 |
| 2 | Diagnostic path does not convert: force a refusal, assert the message names the true class | T18 |
| 3 | Row cannot escape its step: the API shape makes it a compile error | T23, T26, T47 |
| 3 | OOM-vs-NULL discrimination: pointer NULL with `bytes > 0` checks `errcode` | T22 |
| 4 | Migration script with a trailing comment | T36, T37 |
| 4 | `INSERT … RETURNING` whose `reset` fails | T45 |
| 4 | Cached statement across an `ALTER TABLE` | T48 |
| 5 | `SQLITE_LOCKED` is not retried (a bounded test, not a hang) | T49 |
| 5 | A read cursor is closed at scope exit, including on early `break` | T60, T77 |
| 7 | Nested `tx` becomes a savepoint; names are minted, not fixed | T74, T75, T76 |
| 7 | Failed COMMIT leaves no open transaction | T73 |
| 7 | Connection closes with statements outstanding | T80 |
| 8 | Extended codes on: UNIQUE / NOT NULL / FK / DATATYPE map to four distinct variants | T82 |
| 8 | `error_offset` renders a span for a parse error, and `-1` renders none | T84 |
| 9 | A `UNIQUE` nullable column is refused by the schema layer | T93, T173 |
| 10 | NUL-bearing text: assert the chosen policy (refuse, or lossless round trip) | T105 |
| 10 | Byte lengths: `.length`, `column_bytes`, `octet_length` agree; SQL `length()` does not | T100, T104 |
| 11 | `sum()` overflow raises where `+` does not | T110, T111 |
| 11 | Limits are read at open, not hardcoded | T115 |
| 12 | Bind NaN → refused; bind ±∞ → round-trips | T117, T118 |
| 12 | REAL never read as text; float round-trip fixture (the 7 values of T119) | T119 |
| 13 | `open("")` is refused; `open_temp()`/`open_memory()` exist | T125 |
| 13 | `PRAGMA compile_options` fixture | T126, T168 |
| 13 | Open of a non-database fails at open, not at first query | T127 |
| 13 | Existence check does not create the file | T129 |
| 13 | A caller path beginning `file:` is refused, not reinterpreted | T130 |
| 14 | Introspection of a missing table is distinguishable from a table with no columns | T149 |
| 14 | `integrity_check` handles all three outcomes | T134, T150 |
| 15 | The batching ratio, pinned and regression-tested | T152 |
| 15 | Calls-per-column budget, asserted by the counting shim | T158, T161 |
| 16 | `last_insert_rowid` refused for `WITHOUT ROWID` tables | T163 |
| 16 | `bool` reader refuses 2 | T170 |

---

# Appendix B — MAP TO THE ROUND-1 `LAW` CODES

The earlier research pass (preserved at the scratchpad path in §0.5) used
`LAW` codes. Nothing it established was dropped; this is where each one
lives now.

| Round-1 LAW | Now |
|---|---|
| T1–T13 (types) | LAW T1–T13 → T1–T16 |
| LAW T2 affinity substring | T2 |
| LAW T3 no-decltype = BLOB | T3 |
| LAW T4 / T5 INTEGER & REAL affinity | T4, T6, T122 |
| LAW T6 `1='1'` | T7 |
| LAW T7 arithmetic coercion | T9 |
| LAW T8 / T9 / T10 rowid, PK NULLs, reuse | T10, T11, T16 |
| LAW T11 STRICT | T12 |
| LAW T12 NULL never fills a seat | T99 |
| LAW T13 decltype | T13 |
| LAW S1–S11 (lifecycle) | T34–T47 |
| LAW S12–S21 (column pointers) | T17–T26, T31, T48 |
| LAW S22 close | T80 |
| LAW X1–X8 (transactions) | T71, T74, T68, T69, T73, T75, T78, T79 |
| LAW K1–K11 (locking, threading) | T50, T51, T53, T49, T54, T55, T56, T62–T67 |
| LAW E1–E8 (errors) | T81–T89 |
| LAW B1–B10 (blobs) | T27, T90, T33, T115 |
| LAW N1–N6 (NULL) | T91–T99 |
| LAW P1, P2 (pragmas) | T137, T140 |
| F1–F8 (performance) | T151–T162 |
| LAW Q1 (DQS) | T146 |
| LAW Q2 (overflow) | T110, T111 |
| LAW Q3 (ORDER BY) | T165 |
| LAW Q4 (last_insert_rowid) | T163 |
| LAW Q5 (changes) | T164 |
| LAW Q6 (CAST) | T25 |
| LAW Q7 (LIKE) | T168 |
| LAW Q8 (stmt_readonly) | T171 |
| quirks.html §1–§16 | T1, T2, T170, T3, T138, T11, T166, T167, T146, T169, T174, T16, T105, T7 |

Round-1's **BLOCKERS** section (no `float`, no `Bytes`, no out-params, no
`opaque type`, no foreign pointers as `string`, no callbacks,
`Result<void, E>` refused, the interpreter trapping on externs) is a
*language* ledger, not a semantics one, and is unchanged. Its content is
referenced here at T116 (float), T105/T107 (Bytes), T26/T30 (pointers as
strings), T33/T80 (opaque handles + `@free_with`), T27 (`@borrows`), and
T56 (callbacks).

---

# Appendix C — CONFIDENCE LEDGER

*Where this document could be wrong, stated so a re-probe is cheap.*

| Claim | Confidence | How to settle it |
|---|---|---|
| Every `MEASURED` block | **HIGH** — the command and output are shown | re-run the command |
| Every `DOC` quote from `sqlite3.h` | **HIGH** — line numbers given | `grep` the vendored header |
| T65: mode 2 permits *moving* a connection between threads | **MEDIUM** | threadsafe.html states "at the same time"; it does not say affinity is irrelevant. Re-verify before any fiber scheduler lands. |
| T119: 3.53.0 is the version where 17-digit rendering becomes default | **MEDIUM-HIGH** | changes.html says so; floatingpoint.html says 3.52.0 (withdrawn). Confirm against the vendored release's own changelog. |
| T120: the exact `SQLITE_DBCONFIG_FP_DIGITS` argument shape | **LOW** | not in the 3.51.0 header; read it from the vendored header |
| T122: REAL affinity may store an integral REAL as an integer on disk | **MEDIUM** | the reader-visible law (T14) is written so this never matters |
| T115: this build's variable limit is 500 000, not 32 766 | **HIGH** — the engine's own error message names it, and a 200 000-parameter insert ran | re-run on the vendored build; the lesson (read the limit) does not depend on the number |
| T48: decltype/column-count can change across an automatic re-prepare | **MEDIUM** — the re-prepare is documented, the consequence is inferred | write the `ALTER TABLE` test in A.2 |
| T77: an unstepped statement holds a read transaction | **MEDIUM-HIGH** | confirm with `sqlite3_txn_state()` mid-iteration |
| T154: prepare-vs-step cost ratio | **UNQUANTIFIED** | measure in the driver's harness; the shell cannot express it |
| T152/T153 numbers | **HIGH for this machine, NOT PORTABLE** | they include parse cost and are single runs on one SSD; re-measure on CI |
| T165: `ORDER BY` instability | **HIGH (doc)**, and the probe **did not reproduce** it | that is the point — it is plan-dependent; do not conclude it is safe |
| T105: the recommendation to *refuse* NUL-bearing text | **A DESIGN CALL, not a fact** | the facts are measured; the policy is for the lane to ratify |
| Pragma defaults table (T126) | **HIGH for this build only** | the whole point: they differ per build |

**Two things this document does not know.**

1. **Nothing here was run against Avra.** No `avra` command, no build, no
   corpus program. Every claim about how the driver *should* be written is
   a design recommendation, not a verified implementation. In particular
   the memory-boundary claims (T26, T27) follow from this project's
   documented runtime laws, not from an experiment.
2. **The vendored engine has not been chosen.** Version-dependent traps —
   T119 (float rendering), T84 (`error_offset` availability), T70
   (`txn_state` availability), T126 (every compile option) — resolve only
   once it is. That decision should be made before any of the traps above
   are turned into tests.

---

# Appendix D — SOURCES

**sqlite.org pages consulted:**

- `datatype3.html` — storage classes, affinity rules, comparison affinity, arithmetic coercion
- `stricttables.html` — STRICT tables
- `quirks.html` — the sixteen surprises
- `lang_expr.html` — CAST, arithmetic, overflow-to-REAL, `%`
- `lang_createtable.html`, `autoinc.html` — INTEGER PRIMARY KEY, rowid reuse, AUTOINCREMENT
- `nulls.html` — NULL semantics, DISTINCT/UNIQUE asymmetry
- `c3ref/column_blob.html` — the conversion table, pointer invalidation, the safe order, zero-length blobs, OOM
- `c3ref/bind_blob.html` — STATIC/TRANSIENT, lengths, embedded NULs, zeroblob
- `c3ref/step.html`, `c3ref/reset.html`, `c3ref/prepare.html`, `c3ref/finalize.html`
- `c3ref/close.html` — `close` vs `close_v2`
- `c3ref/open.html` — flags, `""`, `":memory:"`, error handles
- `c3ref/errcode.html` — error codes, message lifetime, `error_offset`, the preserving list
- `c3ref/busy_handler.html`, `c3ref/busy_timeout.html` — the deadlock rule
- `c3ref/get_autocommit.html`, `c3ref/txn_state.html`
- `c3ref/last_insert_rowid.html`, `c3ref/changes.html`, `c3ref/total_changes.html`
- `c3ref/blob_open.html`, `c3ref/blob_read.html`, `c3ref/blob_write.html`
- `c3ref/stmt_readonly.html`, `c3ref/limit.html`, `c3ref/db_config.html`
- `rescode.html` — primary and extended result codes
- `threadsafe.html` — the three modes
- `wal.html` — WAL, checkpointing, starvation, the disadvantages list
- `lockingv3.html` — the five lock states
- `isolation.html` — snapshot isolation, the undefined-behaviour rule
- `lang_transaction.html`, `lang_savepoint.html`
- `pragma.html` — every pragma in Part 14
- `limits.html` — the ceilings
- `uri.html`, `inmemorydb.html`, `tempfiles.html`, `mmap.html`, `sharedcache.html`
- `floatingpoint.html` — the rendering algorithm and the digit counts
- `changes.html` — 3.41.0 (`error_offset`), 3.52.0 (withdrawn), 3.53.0 (17-digit default)
- `faq.html` — insert speed, the 60 tps figure, threading, multi-process
- `np1queryprob.html` — a query is a function call
- `foreignkeys.html` — enforcement, indices on child keys, `defer_foreign_keys`
- `compile.html` — recommended compile options

**Local, public-domain:** `sqlite3.h` of the measured build (Apple system
SQLite 3.51.0). Line numbers cited: 155 (version), 535–567 (extended
codes), 623 (`OPEN_EXRESCODE`), 2655–2670 (`DBCONFIG_*`), 4180–4240 (error
interfaces, `error_offset`), 5315–5510 (column result values), 6354–6355
(`SQLITE_STATIC` / `SQLITE_TRANSIENT`).

**Measured with:** `sqlite3` 3.51.0 CLI, ~50 probes, on scratch databases
under the session scratchpad. Every probe's command and output appears
inline above; nothing was summarised without showing it.

---

*End. 174 traps. If the driver ships with a test for each of the ten in
Appendix A.1, it will not be subtly broken in the ways this document
describes — it will be broken in new ways, which is progress.*
