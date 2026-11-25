# THE TRAP CATALOGUE — SQLite semantics that break a naive binding

174 traps, each a way SQLite's real behaviour differs from what a
binding author assumes. Compressed from the 5,147-line research report
(git history has the full text of every entry, with its transcripts,
sources and confidence ledger).

**What survives here, and why.** The INDEX below carries all 174 — a
trap you have not read is a trap you cannot look up, and the index is
what tells a driver author writing an unwritten verb which hazards that
verb has. The FULL ENTRY survives for the traps the package cites in
its own code; those are reproduced verbatim, evidence included, because
a citation in a test is a claim about what this file says.

`MEASURED` = run against SQLite 3.51.0 and quoted. `DOC` = sqlite.org,
cited. *Whose* = who must defend it: DRIVER (the binding), CALLER (the
program using it), or SQLITE (nothing can be done, document it).

---

## The index — all 174

### T1–T16 — Type affinity and dynamic typing

| | Trap | Whose | Ev |
|---|---|---|---|
| **T1** | THE STORAGE CLASS IS A PROPERTY OF THE VALUE, NOT OF THE COLUMN | DRIVER | MEASURED |
| T2 | AFFINITY IS DERIVED BY SUBSTRING MATCH ON THE DECLARED TYPE TEXT, IN A FIXED ORDER, FIRST MATCH WINS | DRIVER | MEASURED |
| T3 | A COLUMN WITH NO DECLARED TYPE HAS BLOB AFFINITY, WHICH MEANS NO COERCION AT ALL | DRIVER | MEASURED |
| T4 | INTEGER AFFINITY DOES NOT REJECT A REAL | DRIVER | MEASURED |
| T5 | NUMERIC AFFINITY CONVERTS TEXT THAT LOOKS NUMERIC, AND LEAVES THE REST AS TEXT | DRIVER | MEASURED |
| T6 | REAL AFFINITY FORCES INTEGERS TO FLOAT, AND LOSES PRECISION ABOVE 2^53 WITHOUT SAYING SO | DRIVER | MEASURED |
| T7 | COMPARISON APPLIES AFFINITY, SO `1 = '1'` IS FALSE AND `col = '1'` IS TRUE | DRIVER | MEASURED |
| T8 | AFFINITY IS LOST THROUGH AN EXPRESSION IN A SUBQUERY | DRIVER | MEASURED |
| T9 | ARITHMETIC COERCES BOTH OPERANDS TO NUMBERS, ALWAYS | CALLER | DOC |
| T10 | ONLY `INTEGER PRIMARY KEY`, SPELLED EXACTLY, ALIASES THE ROWID | DRIVER | DOC |
| T11 | A `PRIMARY KEY` THAT IS NOT `INTEGER PRIMARY KEY` MAY BE NULL, AND `PRAGMA table_info` REPORTS THE ROWID ALIAS AS NULLABLE | DRIVER | MEASURED |
| T12 | STRICT TABLES ARE THE ESCAPE HATCH, AND THEY REFUSE ONLY LOSSY CONVERSIONS | DRIVER | MEASURED |
| T13 | `sqlite3_column_decltype()` IS SCHEMA, NOT DATA, AND IS NULL FOR EVERY EXPRESSION | DRIVER | MEASURED |
| **T14** | THE CLASS→SEAT TABLE IS A REGISTRY, AND A CATCH-ALL IN IT IS A SILENT WRONG ANSWER | DRIVER |  |
| T15 | THE ESCAPE HATCHES ARE TWO, BOTH EXPLICIT, NEITHER THE DEFAULT | DRIVER |  |
| T16 | ROWIDS ARE REUSED WITHOUT `AUTOINCREMENT` | CALLER | MEASURED |

### T17–T25 — The conversion minefield

| | Trap | Whose | Ev |
|---|---|---|---|
| T17 | EVERY VALUE ACCESSOR IS A CONVERSION REQUEST, AND THE CONVERSION IS PERFORMED IN PLACE ON SQLITE'S OWN COPY OF THE VALUE | DRIVER | DOC |
| T18 | `sqlite3_column_type()` IS ONLY MEANINGFUL BEFORE ANY CONVERSION, AND UNDEFINED AFTER ONE | DRIVER | DOC |
| T19 | `sqlite3_column_bytes()` IS A CONVERSION TOO. CALLING IT FIRST DESTROYS THE VALUE YOU WERE ABOUT TO READ | DRIVER | DOC |
| T20 | THERE IS EXACTLY ONE SAFE CALLING ORDER, AND THE DOCUMENTATION NAMES IT | DRIVER | DOC |
| T21 | THE THREE CONVERSIONS THAT INVALIDATE A POINTER YOU ALREADY HOLD | DRIVER | DOC |
| T22 | ON OUT-OF-MEMORY, A COLUMN READ IS INDISTINGUISHABLE FROM NULL | DRIVER | DOC |
| T23 | A COLUMN ACCESSOR OUTSIDE `SQLITE_ROW` IS UNDEFINED, NOT AN ERROR | DRIVER | DOC |
| T24 | `sqlite3_column_value()` RETURNS AN *UNPROTECTED* VALUE AND IS NOT FOR APPLICATION CODE | DRIVER | DOC |
| T25 | CAST IS THE PREFIX RULE, AND IT NEVER ERRORS | CALLER | MEASURED |

### T26–T33 — Pointer invalidation and bind lifetimes

| | Trap | Whose | Ev |
|---|---|---|---|
| T26 | EVERY POINTER SQLITE RETURNS FROM A COLUMN DIES ON THE NEXT `step`, `reset` OR `finalize` | DRIVER | DOC |
| T27 | `SQLITE_STATIC` MEANS "I PROMISE THIS BUFFER OUTLIVES THE STATEMENT", AND AVRA CANNOT MAKE THAT PROMISE TODAY | DRIVER | DOC |
| T28 | THE BIND DESTRUCTOR RUNS EVEN WHEN THE BIND FAILS — EXCEPT IN TWO CASES | DRIVER | DOC |
| **T29** | A BIND WITH A NULL POINTER IS `bind_null`, NOT AN EMPTY VALUE | DRIVER | DOC |
| T30 | `sqlite3_errmsg()`'s BUFFER IS BORROWED AND CONNECTION-SCOPED | DRIVER | DOC |
| T31 | A RESULT COLUMN'S NAME IS ALSO A BORROWED POINTER, AND IS UNSPECIFIED WITHOUT `AS` | DRIVER | DOC |
| T32 | THE 32-BIT `sqlite3_column_int` / `sqlite3_bind_int` SPLIT | DRIVER | DOC |
| T33 | A BLOB LARGER THAN MEMORY NEEDS `zeroblob` + INCREMENTAL I/O, AND THE HANDLE HAS ITS OWN LIFETIME RULES | DRIVER | DOC |

### T34–T48 — The statement lifecycle

| | Trap | Whose | Ev |
|---|---|---|---|
| T34 | USE `prepare_v2` OR `_v3`, NEVER `sqlite3_prepare`, AND THE REASON IS THE ERROR CHANNEL | DRIVER | DOC |
| T35 | PASS AN EXPLICIT `nByte`, NEVER `-1` | DRIVER | DOC |
| **T36** | `prepare` COMPILES ONLY THE FIRST STATEMENT; `pzTail` IS THE ONLY WAY TO RUN A SCRIPT | DRIVER | DOC |
| **T37** | COMMENT-ONLY OR EMPTY SQL PREPARES TO A NULL STATEMENT AND `SQLITE_OK` | DRIVER | DOC |
| T38 | PARAMETER INDICES ARE 1-BASED; COLUMN INDICES ARE 0-BASED | DRIVER | DOC |
| T39 | A REPEATED NAMED PARAMETER IS ONE INDEX; `?NNN` SETS ITS OWN | DRIVER | DOC |
| T40 | AN UNBOUND PARAMETER IS NULL, SILENTLY | DRIVER | DOC |
| T41 | `reset` DOES NOT CLEAR BINDINGS. `clear_bindings` DOES | DRIVER | DOC |
| T42 | WHAT `step` RETURNS, AND WHAT EACH OBLIGES | DRIVER | DOC |
| T43 | THE DOCUMENTED RETRY RULE FOR `SQLITE_BUSY` FROM `step` DEPENDS ON WHETHER YOU ARE IN A TRANSACTION | DRIVER | DOC |
| T44 | SINCE 3.6.23.1 `step` AUTO-RESETS INSTEAD OF RETURNING `SQLITE_MISUSE` — UNLESS THE BUILD SAYS OTHERWISE | DRIVER | DOC |
| T45 | `reset` RETURNS AN ERROR CODE THAT `step` MAY NEVER HAVE SHOWN YOU | DRIVER | DOC |
| T46 | `SQLITE_MISUSE` MEANS "YOU HAVE A BUG", NOT "THE QUERY FAILED" | DRIVER | DOC |
| T47 | BINDING A STEPPED-BUT-UNRESET STATEMENT IS A MISUSE, AND THE API MUST MAKE IT UNREPRESENTABLE | DRIVER |  |
| T48 | `prepare_v2`/`v3` SILENTLY RE-PREPARE ON A SCHEMA CHANGE, AND THE STATEMENT'S SHAPE CAN CHANGE UNDER A CACHE | DRIVER | DOC |

### T49–T61 — Busy, locked and concurrency

| | Trap | Whose | Ev |
|---|---|---|---|
| **T49** | `SQLITE_BUSY` IS ANOTHER CONNECTION; `SQLITE_LOCKED` IS *THIS* CONNECTION. ONE IS RETRYABLE AND THE OTHER NEVER IS | DRIVER | DOC |
| T50 | THE FIVE LOCK STATES, AND WHY OPENING MORE CONNECTIONS MAKES CONTENTION WORSE | DRIVER | DOC |
| T51 | WAL GIVES READERS-DON'T-BLOCK-WRITERS, AND CHARGES FOR IT | DRIVER | MEASURED |
| T52 | `journal_mode=WAL` IS PERSISTENT: SETTING IT CHANGES THE FILE FOR EVERY FUTURE CONNECTION | DRIVER | MEASURED |
| T53 | WAL DOES NOT ABOLISH `SQLITE_BUSY` | DRIVER | MEASURED |
| T54 | `busy_timeout` AND `busy_handler` REPLACE EACH OTHER | DRIVER | DOC |
| T55 | THE BUSY HANDLER IS NOT GUARANTEED TO RUN, AND THE REASON IS DEADLOCK | DRIVER | DOC |
| T56 | THE BUSY HANDLER IS NOT REENTRANT AND MUST NOT TOUCH THE CONNECTION | DRIVER | DOC |
| T57 | A BUSY HANDLER MUST NOT BE USED WITH A SHARED CACHE | DRIVER | DOC |
| T58 | THE ONE-WRITER RULE IS A PROPERTY OF THE FILE, NOT OF THE PROCESS | CALLER | DOC |
| T59 | CHECKPOINTING IS A LATENCY SPIKE CHARGED TO A RANDOM WRITER | CALLER | DOC |
| T60 | CHECKPOINT STARVATION TURNS A 4 MB WAL INTO AN UNBOUNDED ONE | DRIVER | DOC |
| T61 | WAL2 IS NOT IN THE MAINLINE BUILD, AND ASKING FOR IT SUCCEEDS SILENTLY | DRIVER | MEASURED |

### T62–T67 — Threading modes

| | Trap | Whose | Ev |
|---|---|---|---|
| T62 | THE THREE MODES, AND THE EXACT RULE OF EACH |  | DOC |
| T63 | YOU CAN DOWNGRADE AT RUNTIME BUT NEVER UPGRADE PAST THE COMPILE-TIME SETTING | DRIVER | DOC |
| T64 | `sqlite3_threadsafe()` REPORTS THE COMPILE-TIME SETTING ONLY | DRIVER | DOC |
| T65 | FOR A SYNCHRONOUS, NO-ASYNC-RUNTIME LANGUAGE, BUILD `SQLITE_THREADSAFE=2` AND ENFORCE ONE OWNER STRUCTURALLY | DRIVER |  |
| T66 | WHAT BREAKS IF A HANDLE CROSSES THREADS ANYWAY | DRIVER | DOC |
| T67 | A CONNECTION IS NOT SENDABLE, AND AVRA CANNOT SAY SO TODAY | DRIVER |  |

### T68–T80 — Transaction semantics

| | Trap | Whose | Ev |
|---|---|---|---|
| T68 | AUTOCOMMIT IS THE OBSERVABLE, AND IT IS THE ONLY WAY TO KNOW WHETHER A TRANSACTION IS STILL OPEN | DRIVER | DOC |
| T69 | SOME ERRORS ROLL THE TRANSACTION BACK BY THEMSELVES, AND THE ONLY WAY TO FIND OUT IS TO ASK | DRIVER | MEASURED |
| T70 | `sqlite3_txn_state()` IS THE FINER INSTRUMENT, AND IT DISTINGUISHES READ FROM WRITE | DRIVER | DOC |
| T71 | THE UPGRADE DEADLOCK: `BEGIN DEFERRED` THAT READS THEN WRITES IS THE MOST-REPORTED SQLITE PRODUCTION BUG | DRIVER | DOC |
| T72 | `SQLITE_BUSY_SNAPSHOT` AND `SQLITE_ABORT_ROLLBACK` ARE THE TWO CODES THAT MEAN "START OVER", NOT "WAIT" | DRIVER | DOC |
| T73 | `COMMIT` CAN FAIL WITH `SQLITE_BUSY` AND LEAVE THE TRANSACTION OPEN | DRIVER | DOC |
| T74 | TRANSACTIONS DO NOT NEST; SAVEPOINTS ARE THE NESTING MECHANISM | DRIVER | MEASURED |
| T75 | `ROLLBACK TO` DOES NOT POP THE SAVEPOINT; `RELEASE` DOES | DRIVER | MEASURED |
| T76 | SAVEPOINT NAMES NEED NOT BE UNIQUE, AND THE MOST RECENT ONE WINS | DRIVER | MEASURED |
| T77 | AN UNSTEPPED-TO-DONE STATEMENT HOLDS A READ TRANSACTION AND BLOCKS THE WRITER | DRIVER | DOC |
| T78 | `ROLLBACK` ABORTS PENDING STATEMENTS | DRIVER | DOC |
| T79 | `PRAGMA foreign_keys` IS A SILENT NO-OP INSIDE A TRANSACTION | DRIVER | MEASURED |
| T80 | DO NOT CLOSE A CONNECTION WITH UNFINALIZED STATEMENTS — AND `close_v2` CHANGES WHAT THAT MEANS, NOT WHETHER IT MATTERS | DRIVER | DOC |

### T81–T89 — Error reporting

| | Trap | Whose | Ev |
|---|---|---|---|
| T81 | THE PRIMARY CODE IS THE LOW 8 BITS OF THE EXTENDED CODE | DRIVER | DOC |
| T82 | EXTENDED RESULT CODES ARE OFF BY DEFAULT, AND WITHOUT THEM THE DRIVER CANNOT TELL A UNIQUE COLLISION FROM A NOT NULL VIOLATION | DRIVER | MEASURED |
| T83 | `SQLITE_MISUSE`'s MESSAGE MAY DESCRIBE A DIFFERENT ERROR ENTIRELY | DRIVER | DOC |
| **T84** | `sqlite3_error_offset()` GIVES A SPAN FOR PARSE ERRORS — AND IS `-1` WHEN THERE IS NO TOKEN | DRIVER | DOC |
| T85 | THE ERROR CODE AND MESSAGE ARE STALE AFTER THE NEXT API CALL, SO READ THEM FIRST AND CLEAN UP SECOND | DRIVER | DOC |
| T86 | `sqlite3_errstr()` IS THE ONLY MESSAGE FUNCTION SAFE WITHOUT A CONNECTION, AND IT IS NOT ENOUGH ON ITS OWN | DRIVER | DOC |
| T87 | AN `open` THAT FAILS STILL RETURNS A HANDLE, AND YOU MUST STILL CLOSE IT | DRIVER | DOC |
| T88 | `errmsg` IS CONNECTION-SCOPED, NOT THREAD-SCOPED, SO A SECOND THREAD CAN OVERWRITE YOUR ERROR | DRIVER | DOC |
| T89 | WHICH CODES ARE RETRYABLE, IN ONE PLACE | DRIVER |  |

### T90–T99 — NULL, empty and zero

| | Trap | Whose | Ev |
|---|---|---|---|
| T90 | A NEGATIVE LENGTH TO `bind_text` MEANS `strlen`; A NEGATIVE LENGTH TO `bind_blob` IS UNDEFINED BEHAVIOUR | DRIVER | DOC |
| T91 | `x = NULL` IS NULL, NEVER TRUE, NEVER FALSE | DRIVER | DOC |
| T92 | NULL IN A `WHERE` IS "NOT TRUE", SO THE ROW IS FILTERED OUT | CALLER |  |
| T93 | NULLS ARE DISTINCT IN A UNIQUE INDEX AND INDISTINCT IN `DISTINCT`, `GROUP BY` AND `UNION` | DRIVER | MEASURED |
| T94 | NULL PROPAGATES THROUGH ARITHMETIC, AND `CASE WHEN null` TAKES THE `ELSE` | CALLER | DOC |
| **T95** | `sum()` OF NOTHING IS NULL, AND `sqlite3_column_int64` TURNS THAT INTO `0` | DRIVER | MEASURED |
| **T96** | SQL NULL, THE EMPTY STRING AND THE ZERO-LENGTH BLOB ARE THREE DIFFERENT VALUES, AND SQLITE KEEPS THEM APART | DRIVER | MEASURED |
| **T97** | `sqlite3_column_blob()` RETURNS A NULL POINTER FOR A ZERO-LENGTH BLOB, AND THAT IS NOT A SQL NULL | DRIVER | DOC |
| T98 | THE SAME PROBLEM EXISTS ON THE `sqlite3_value_*` SIDE | DRIVER | DOC |
| T99 | A NULL NEVER FILLS A NON-NULLABLE SEAT, AND THE READER IS ONE MATCH | DRIVER |  |

### T100–T107 — Text encoding

| | Trap | Whose | Ev |
|---|---|---|---|
| T100 | `sqlite3_column_bytes()` IS BYTES, NEVER CHARACTERS, AND EXCLUDES THE TERMINATOR | DRIVER | DOC |
| T101 | THE UTF-8 AND UTF-16 ENTRY POINTS ARE PARALLEL AND MUST NOT BE MIXED; USE UTF-8 ONLY | DRIVER | DOC |
| T102 | THE DATABASE'S TEXT ENCODING IS FIXED WHEN THE FILE IS CREATED, AND THE PRAGMA THAT CHANGES IT LIES | DRIVER | MEASURED |
| T103 | UTF-16 BIND INPUT USES A BOM, AND INVALID UNICODE IS SILENTLY REPLACED | DRIVER | DOC |
| T104 | SQL `length()` IS CHARACTERS FOR TEXT AND BYTES FOR BLOBS, AND NEITHER IS `column_bytes` | DRIVER | MEASURED |
| T105 | SQLITE STORES EMBEDDED NULs IN TEXT, AND THEN CALLS EXPRESSIONS OVER THEM UNDEFINED | DRIVER | MEASURED |
| T106 | `column_text16` RETURNS NATIVE-ENDIAN UTF-16 REGARDLESS OF THE DATABASE ENCODING | DRIVER | DOC |
| T107 | SQLITE DOES NOT VALIDATE UTF-8 ON INPUT | DRIVER | DOC |

### T108–T115 — Integers

| | Trap | Whose | Ev |
|---|---|---|---|
| T108 | ROWIDS ARE 64-BIT, AND SO IS EVERY SQLITE INTEGER | DRIVER | DOC |
| T109 | THE `int` / `int64` API SPLIT IS A TRAP WITH NO UPSIDE |  |  |
| T110 | INTEGER OVERFLOW IN ARITHMETIC SILENTLY BECOMES A REAL | DRIVER | MEASURED |
| T111 | `sum()` OVERFLOW IS AN ERROR, WHICH IS *NOT* WHAT `+` DOES | DRIVER | MEASURED |
| T112 | AN INTEGER LITERAL TOO LARGE FOR i64 IS PARSED AS A REAL | DRIVER | MEASURED |
| T113 | INTEGER DIVISION TRUNCATES, AND `%` CASTS BOTH OPERANDS TO INTEGER | DRIVER | MEASURED |
| T114 | BINDING AN i64 TO A REAL-AFFINITY COLUMN LOSES PRECISION ABOVE 2^53, SILENTLY | DRIVER |  |
| T115 | THE LIMITS ARE BUILD-SPECIFIC. READ THEM; DO NOT HARDCODE THEM | DRIVER | MEASURED |

### T116–T123 — Floating point

| | Trap | Whose | Ev |
|---|---|---|---|
| T116 | `REAL` IS IEEE-754 BINARY64, AND AVRA HAS NO `float` YET | LANGUAGE | DOC |
| T117 | SQLITE STORES NaN AS NULL | DRIVER | MEASURED |
| T118 | INFINITIES ARE STORED, AND THEIR TEXT RENDERING IS `9.0e+999` — WHICH IS NOT A NUMBER ANY OTHER PARSER ACCEPTS | DRIVER | MEASURED |
| T119 | REAL→TEXT USES 15 SIGNIFICANT DIGITS AND DOES NOT ROUND-TRIP — UNTIL 3.53.0 | DRIVER | MEASURED |
| T120 | `SQLITE_DBCONFIG_FP_DIGITS` MAKES THE RENDERING CONFIGURABLE, SO A DRIVER SHOULD SET IT | DRIVER | DOC |
| T121 | `fcmp` MUST USE ORDERED PREDICATES, AND `NaN != NaN` IS THE SPEC'D ANSWER | LANGUAGE |  |
| T122 | REAL AFFINITY MAY STORE AN INTEGRAL REAL AS AN INTEGER ON DISK | DRIVER | MEASURED |
| T123 | TEXT→REAL CONVERSION ACCEPTS MORE THAN A FLOAT LITERAL DOES | DRIVER | MEASURED |

### T124–T136 — File-level realities

| | Trap | Whose | Ev |
|---|---|---|---|
| T124 | THE `SQLITE_OPEN_*` FLAGS, AND WHAT EACH ACTUALLY DOES | DRIVER | DOC |
| **T125** | `""` AND `":memory:"` ARE TEMPORARY DATABASES THAT VANISH, AND THEY ARE NOT THE SAME | DRIVER | DOC |
| T126 | THE SYSTEM SQLITE IS NOT THE SQLITE IN THE DOCUMENTATION. VENDOR THE AMALGAMATION | DRIVER | MEASURED |
| **T127** | OPENING IS LAZY. A BAD DATABASE IS DISCOVERED AT PREPARE, NOT AT OPEN | DRIVER | MEASURED |
| T128 | OPENING A DIRECTORY, OR A PATH THAT CANNOT BE CREATED, GIVES `SQLITE_CANTOPEN` WITH USEFUL EXTENDED CODES | DRIVER | MEASURED |
| **T129** | A `PRAGMA` READ ALONE CREATES A ZERO-BYTE DATABASE FILE | DRIVER | MEASURED |
| **T130** | URI FILENAMES ARE OFF BY DEFAULT AND CHANGE THE MEANING OF A PATH | DRIVER | MEASURED |
| T131 | `:memory:` IS PRIVATE PER CONNECTION; SHARING ONE REQUIRES A URI AND SHARED CACHE | DRIVER | MEASURED |
| T132 | THE FILES A CONNECTION CREATES BESIDE THE DATABASE | DRIVER | MEASURED |
| T133 | TEMPORARY FILES ARE WHERE `ORDER BY` GOES, AND `temp_store` DECIDES | CALLER | MEASURED |
| T134 | CORRUPTION IS REPORTED AS `SQLITE_CORRUPT` (11) FROM WHEREVER IT IS NOTICED, INCLUDING FROM `integrity_check` ITSELF | DRIVER | MEASURED |
| T135 | RECOVERY IS AUTOMATIC AND IS ANNOUNCED ONLY ON THE LOG CHANNEL | DRIVER | DOC |
| T136 | A PROCESS TRAP CANNOT BE CAUGHT, AND THAT IS FINE — THE JOURNAL IS THE RECOVERY | DRIVER |  |

### T137–T150 — Pragmas that are actually API

| | Trap | Whose | Ev |
|---|---|---|---|
| T137 | A PRAGMA'S ANSWER IS DATA. CHECK IT; NEVER ASSUME IT | DRIVER | MEASURED |
| T138 | `foreign_keys` IS OFF BY DEFAULT, AND MOST BINDINGS GET THIS WRONG. TURN IT ON | DRIVER | MEASURED |
| T139 | `journal_mode` — WAL by default, checked, and disclosed |  |  |
| T140 | `synchronous` — NORMAL under WAL ONLY, and it is a durability decision that belongs to the caller | DRIVER | MEASURED |
| T141 | `cache_size`'s SIGN CHANGES ITS UNIT, AND THE DEFAULT'S SIGN IS BUILD-SPECIFIC | DRIVER | MEASURED |
| T142 | `busy_timeout` — set it, and know what it cannot do |  | MEASURED |
| T143 | `mmap_size` TURNS AN I/O ERROR INTO A SEGFAULT | CALLER | MEASURED |
| T144 | `temp_store` — expose, do not set |  |  |
| T145 | `wal_autocheckpoint` — leave the default, expose the manual checkpoint |  | MEASURED |
| T146 | DOUBLE-QUOTED STRING LITERALS: THE MOST DANGEROUS DEFAULT IN SQLITE | DRIVER | MEASURED |
| T147 | `optimize` ON CLOSE, BOUNDED BY `analysis_limit` | DRIVER | MEASURED |
| T148 | THE SCHEMA INTROSPECTION PRAGMAS AN ORM NEEDS, AND WHAT EACH ACTUALLY ANSWERS | DRIVER | MEASURED |
| T149 | INTROSPECTING A TABLE THAT DOES NOT EXIST ANSWERS *NOTHING*, NOT AN ERROR | DRIVER | MEASURED |
| T150 | `integrity_check` VS `quick_check`, AND WHAT THEY COST | CALLER | MEASURED |

### T151–T162 — Performance, measured

| | Trap | Whose | Ev |
|---|---|---|---|
| T151 | A QUERY IS A FUNCTION CALL, NOT A ROUND TRIP, AND THAT INVERTS CLIENT-SERVER INTUITION | DRIVER | DOC |
| T152 | THE TRANSACTION IS THE UNIT OF DISK COST. MEASURED: 134× ON THIS MACHINE, NOT 1000× | DRIVER | MEASURED |
| T153 | WAL IS A 4× WIN ON SMALL WRITES, BEFORE ANY CONCURRENCY BENEFIT | DRIVER | MEASURED |
| T154 | PREPARED STATEMENT REUSE IS THE MAIN DRIVER-LAYER LEVER | DRIVER | DOC |
| T155 | `sqlite3_exec` CANNOT BIND, AND STRINGIFIES EVERY RESULT | DRIVER | DOC |
| T156 | BINDING BEATS INTERPOLATION ON EVERY AXIS |  |  |
| T157 | `SQLITE_PREPARE_PERSISTENT` EXISTS FOR CACHED STATEMENTS | DRIVER | DOC |
| T158 | COLUMN ACCESS ORDER DOES NOT MATTER FOR SPEED, BUT ACCESS *COUNT* DOES | DRIVER |  |
| T159 | THE `column_text` CONVERSION COST IS PAID *INSIDE* SQLITE AND IS INVISIBLE TO AVRA PROFILING | DRIVER |  |
| T160 | PAGE SIZE IS SET ONCE, AT CREATION OR AT `VACUUM` | CALLER | MEASURED |
| T161 | THE PERFORMANCE BUDGET, AS NUMBERS A TEST CAN FAIL ON |  |  |
| T162 | MEASURE THE DRIVER AGAINST THE SHELL, NOT AGAINST ANOTHER LANGUAGE'S BINDING | DRIVER |  |

### T163–T174 — The remaining surprises

| | Trap | Whose | Ev |
|---|---|---|---|
| T163 | `last_insert_rowid` IS CONNECTION-SCOPED, TRIGGER-AWARE, NOT ROLLED BACK, AND SILENT ABOUT `WITHOUT ROWID` | DRIVER | MEASURED |
| **T164** | `changes()` AND `total_changes()` COUNT DIFFERENT THINGS, AND NEITHER COUNTS WHAT MOST PEOPLE THINK | DRIVER | MEASURED |
| T165 | NO `ORDER BY` MEANS NO ORDER, AND `ORDER BY` IS NOT A STABLE SORT | DRIVER | MEASURED |
| T166 | BARE COLUMNS IN AN AGGREGATE QUERY ARE LEGAL, AND USUALLY ARBITRARY | DRIVER | DOC |
| T167 | UNICODE CASE FOLDING IS ASCII-ONLY | CALLER | DOC |
| T168 | `LIKE` HAS A PATTERN-LENGTH CEILING AND A COMPILE-TIME BEHAVIOUR SWITCH | DRIVER | MEASURED |
| T169 | COMMA JOINS HAVE THE SAME PRECEDENCE AS OTHER JOINS | DRIVER | DOC |
| T170 | THERE IS NO `BOOLEAN` AND NO `DATETIME` | DRIVER | DOC |
| T171 | `sqlite3_stmt_readonly` CALLS `BEGIN`/`COMMIT` READ-ONLY | DRIVER | DOC |
| T172 | `SQLITE_ENABLE_API_ARMOR` IS WORTH HAVING ON | DRIVER | MEASURED |
| T173 | `UPSERT`'s CONFLICT TARGET MUST BE A REAL UNIQUE CONSTRAINT, AND NULLS DEFEAT IT | DRIVER | MEASURED |
| T174 | SQLITE ACCEPTS DUBIOUS SQL WITHOUT WARNING, ON PURPOSE | T | MEASURED |

Bold = cited by the package's code; full entry below.

---

## The cited traps, in full

These fifteen are referenced by name from `packages/std-sqlite/src`.
Text is verbatim from the research report.

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
