# @std/sqlite research — SQLite's C API as the spec for Avra's extern wall

Lane sqlite. The map the checklist in ROADMAP.md:1507 ("THE CHECKLIST —
written when the research lands") waits on.

WHAT THIS IS: every public `sqlite3_*` entry point, grouped, judged
REQUIRED / OPTIONAL / DEPRECATED for a full-surface driver, and each one
classified into exactly one ABI SHAPE. The shape buckets are the
language features the campaign must land — bucket (a) is what an
`extern fn` can spell today; (b)–(g) are the wall.

SOURCES, all read directly:
- `/Applications/Xcode.app/…/MacOSX.sdk/usr/include/sqlite3.h` —
  SQLite 3.51.0, `SQLITE_SOURCE_ID` `…5114dcaapl` (sqlite3.h:155–157).
  The `apl` suffix is Apple's fork marker.
- `/Applications/Xcode.app/…/MacOSX.sdk/usr/lib/libsqlite3.tbd` — the
  link stub; its export list is what the system dylib actually ships.
- `sqlite3 :memory: "PRAGMA compile_options"` on `/usr/bin/sqlite3`.
- `sqlite.org/c3ref/funclist.html`, `sqlite.org/compile.html`,
  `sqlite.org/download.html` (fetched 2026-09-05).
- The tree: `packages/std-avrac/src/core/{ir,types,runtime_api}.av`,
  `src/language/{memory,lower,llvm,interp}.av`,
  `src/features/fns/{mod,lower,builders}.av`, `runtime/avra_runtime.c`.

COUNTS, exact and grep-verified:

| set | count |
|---|---|
| functions declared in Apple's `sqlite3.h` 3.51.0 | **284** |
| globals declared there (`sqlite3_version[]`, `sqlite3_temp_directory`, `sqlite3_data_directory`) | 3 |
| upstream 3.53.4 core entry points absent from Apple's header | **13** (below) |
| session/changeset/changegroup/rebaser (`sqlite3session.h`) | **49** |
| **full upstream surface, non-Windows, non-debug** | **≈ 340** |

The upstream-only 13, by `comm` of `funclist.html` against the header:
`sqlite3_load_extension`, `sqlite3_enable_load_extension`,
`sqlite3_preupdate_hook`, `_old`, `_new`, `_count`, `_depth`,
`_blobwrite`, `sqlite3_unlock_notify`, `sqlite3_hard_heap_limit64`,
`sqlite3_db_status64`, `sqlite3_set_errmsg`, `sqlite3_str_truncate`
(plus `sqlite3_str_free`, `sqlite3_mutex_held`/`_notheld` — debug-only —
and the three `sqlite3_win32_set_directory*`, Windows-only, and
`sqlite3_carray_bind*`, an extension). **Seven of those 13 are exported
by the system dylib but undeclared in its SDK header** — the six
`sqlite3_preupdate_*` and `sqlite3_hard_heap_limit64` — and so is the
entire 49-function session API, which lives in `sqlite3session.h`, a
header the SDK does not ship at all. Apple compiles them and gives no
way to declare them. The other six of the 13
(`load_extension`, `enable_load_extension`, `unlock_notify`,
`db_status64`, `set_errmsg`, `str_truncate`) are genuinely absent from
the binary: the first three by compile flag, the last three because they
postdate 3.51.0.

---

## 1. THE SURFACE, BY FAMILY

Legend for the verdict column: **REQ** required for a full-surface
driver · **OPT** optional (a real capability, not on the critical path) ·
**DEP** deprecated, with the modern replacement named.

DEP covers two things, and the distinction matters when
`SQLITE_OMIT_DEPRECATED` is eventually set (§3.3). NINE functions carry
the `SQLITE_DEPRECATED` macro in the header and vanish under that flag:
`sqlite3_aggregate_count`, `sqlite3_expired`, `sqlite3_global_recover`,
`sqlite3_memory_alarm`, `sqlite3_transfer_bindings`, `sqlite3_profile`,
`sqlite3_trace`, `sqlite3_soft_heap_limit`, `sqlite3_thread_cleanup`.
The rest marked DEP below are SUPERSEDED, not macro-deprecated — they
stay in the binary and a driver may still bind them
(`sqlite3_open`, `sqlite3_prepare`/`_16`, `sqlite3_get_table`/
`sqlite3_free_table`, `sqlite3_wal_checkpoint`,
`sqlite3_enable_shared_cache`).

ABI shape codes, defined in full in §2:
**a** callable today · **b** double · **c** out-param · **d** callback ·
**e** variadic · **f** u64 · **g** length-carrying bytes.
A function is listed under its PRIMARY shape (precedence e > d > c > b >
g > f > a); secondary shapes appear in parentheses.

### 1.1 Version and build — 6, all shape (a)

| fn | what | verdict |
|---|---|---|
| `sqlite3_libversion()` | version text | REQ |
| `sqlite3_libversion_number()` | version as `3XXYYZZ` | REQ |
| `sqlite3_sourceid()` | build's source hash | OPT |
| `sqlite3_compileoption_used(name)` | was this flag set | **REQ** |
| `sqlite3_compileoption_get(N)` | Nth flag | **REQ** |
| `sqlite3_threadsafe()` | compiled threading mode | REQ |

The two `compileoption` calls are REQUIRED, not decorative: they are how
the driver's own test suite PROVES the vendored flag set at runtime
instead of trusting the build. That is the assertion that makes "one
version, every machine" (ROADMAP.md:1531) testable rather than claimed.

### 1.2 Library initialization and configuration — 11

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_initialize()` | a | start the library | REQ |
| `sqlite3_shutdown()` | a | stop it | REQ |
| `sqlite3_config(op, …)` | **e** | process-wide config (threading mode, log, memory, mmap) | REQ |
| `sqlite3_db_config(db, op, …)` | **e** | per-connection config (DQS, DEFENSIVE, FKEY, TRUSTED_SCHEMA) | **REQ** |
| `sqlite3_os_init()` / `sqlite3_os_end()` | a | VFS-author hooks | OPT |
| `sqlite3_enable_shared_cache(on)` | a | shared-cache mode | **DEP** — use WAL |
| `sqlite3_auto_extension(f)` | **d** | run f on every new connection | OPT |
| `sqlite3_cancel_auto_extension(f)` | **d** | undo it | OPT |
| `sqlite3_reset_auto_extension()` | a | undo all | OPT |
| `sqlite3_test_control(op, …)` | **e** | internal test hooks | OPT (never ship) |

`sqlite3_db_config` is on the critical path for one reason beyond
configuration: `SQLITE_DBCONFIG_DQS_DDL`/`_DQS_DML` turn OFF the
double-quoted-string misfeature per connection. That is the runtime
escape from the host build's `DQS=3` (§3).

### 1.3 Connection lifecycle — 29

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_open_v2(file, ppDb, flags, zVfs)` | **c** | open with flags and a named VFS | **REQ** |
| `sqlite3_open(file, ppDb)` | **c** | open, default flags | DEP — `open_v2` |
| `sqlite3_open16(file, ppDb)` | **c** (g) | open, UTF-16 filename | OPT |
| `sqlite3_close_v2(db)` | a | close; defers while statements live | **REQ** |
| `sqlite3_close(db)` | a | close; `SQLITE_BUSY` if statements live | OPT — keep for the strict close |
| `sqlite3_db_handle(stmt)` | a | the statement's connection | REQ |
| `sqlite3_db_filename(db, name)` | a | a schema's file path | REQ |
| `sqlite3_db_name(db, N)` | a | Nth attached schema's name | REQ |
| `sqlite3_db_readonly(db, name)` | a | is the schema read-only | REQ |
| `sqlite3_db_release_memory(db)` | a | drop caches | OPT |
| `sqlite3_db_cacheflush(db)` | a | flush dirty pages, hold the txn | OPT |
| `sqlite3_db_mutex(db)` | a | the connection's mutex | OPT |
| `sqlite3_next_stmt(db, stmt)` | a | iterate live statements | REQ (leak audit) |
| `sqlite3_set_clientdata(db, k, p, xDel)` | **d** | attach a keyed pointer | OPT |
| `sqlite3_get_clientdata(db, k)` | a | read it back | OPT |
| `sqlite3_database_file_object(name)` | a | the `sqlite3_file*` behind a path | OPT (VFS) |
| `sqlite3_file_control(db, zDb, op, pArg)` | a | VFS control ops | OPT |
| `sqlite3_limit(db, id, newVal)` | a | per-connection limits | REQ |
| `sqlite3_extended_result_codes(db, on)` | a | extended error codes | **REQ** |
| `sqlite3_busy_timeout(db, ms)` | a | the built-in busy handler | **REQ** |
| `sqlite3_setlk_timeout(db, ms, flags)` | a | blocking-lock timeout | OPT (`SQLITE_ENABLE_SETLK_TIMEOUT`) |
| `sqlite3_interrupt(db)` | a | cancel the running query | REQ |
| `sqlite3_is_interrupted(db)` | a | is one pending | REQ |
| `sqlite3_system_errno(db)` | a | the OS errno behind an IO error | REQ |
| `sqlite3_txn_state(db, zSchema)` | a | NONE / READ / WRITE | REQ |
| `sqlite3_get_autocommit(db)` | a | is a transaction open | **REQ** |
| `sqlite3_overload_function(db, name, nArg)` | a | placeholder for a vtab's xFindFunction | OPT |
| `sqlite3_declare_vtab(db, sql)` | a | a vtab declares its schema | OPT (vtab) |
| `sqlite3_drop_modules(db, azKeep)` | a | remove vtab modules | OPT |

### 1.4 Statement lifecycle — 24

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_prepare_v3(db, sql, n, flags, ppStmt, pzTail)` | **c** (g) | compile with prep flags | **REQ** |
| `sqlite3_prepare_v2(db, sql, n, ppStmt, pzTail)` | **c** (g) | compile | REQ |
| `sqlite3_prepare(…)` | **c** (g) | legacy: generic error codes | **DEP** — `_v2`/`_v3` |
| `sqlite3_prepare16` / `_v2` / `_v3` | **c** (g) | UTF-16 SQL | OPT |
| `sqlite3_step(stmt)` | a | advance one row | **REQ** |
| `sqlite3_reset(stmt)` | a | rewind for re-execution | **REQ** |
| `sqlite3_finalize(stmt)` | a | destroy | **REQ** |
| `sqlite3_clear_bindings(stmt)` | a | all parameters to NULL | REQ |
| `sqlite3_data_count(stmt)` | a | columns in the CURRENT row | REQ |
| `sqlite3_sql(stmt)` | a | the original SQL text | REQ |
| `sqlite3_expanded_sql(stmt)` | a | SQL with parameters substituted | REQ (diagnostics) |
| `sqlite3_normalized_sql(stmt)` | a | SQL with literals normalized | OPT (`ENABLE_NORMALIZE`) |
| `sqlite3_stmt_busy(stmt)` | a | mid-execution | REQ |
| `sqlite3_stmt_readonly(stmt)` | a | writes nothing | **REQ** (a read/write law) |
| `sqlite3_stmt_isexplain(stmt)` | a | EXPLAIN / EXPLAIN QUERY PLAN | OPT |
| `sqlite3_stmt_explain(stmt, mode)` | a | re-prepare as EXPLAIN | OPT |
| `sqlite3_stmt_status(stmt, op, reset)` | a | per-statement counters | OPT |
| `sqlite3_complete(sql)` | a | is this a complete statement | REQ (a REPL/splitter) |
| `sqlite3_complete16(sql)` | **g** | UTF-16 twin | OPT |
| `sqlite3_exec(db, sql, cb, p, pzErr)` | **d** (c) | prepare/step/finalize in one, per-row callback | OPT — the driver builds it |
| `sqlite3_get_table(db, sql, pazResult, pnRow, pnCol, pzErr)` | **c** | whole result as `char**` | **DEP** — legacy wrapper |
| `sqlite3_free_table(azResult)` | a | free the above | DEP |

`sqlite3_exec` is OPTIONAL and should stay unbound in the first slice:
it is a `char**` out-param AND a callback, and everything it does is
`prepare_v2` + `step` + `finalize`. Binding it early would spend the two
hardest language features on a convenience.

### 1.5 Binding — 16

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_bind_int(s, i, v)` | a | 32-bit int | REQ |
| `sqlite3_bind_int64(s, i, v)` | a | 64-bit int — Avra's `int` | **REQ** |
| `sqlite3_bind_null(s, i)` | a | NULL | **REQ** |
| `sqlite3_bind_double(s, i, v)` | **b** | REAL | **REQ** |
| `sqlite3_bind_text(s, i, z, n, xDel)` | **d** (g) | UTF-8 text | **REQ** |
| `sqlite3_bind_text64(s, i, z, n, xDel, enc)` | **d** (g, f) | text, `u64` length, explicit encoding | REQ |
| `sqlite3_bind_text16(s, i, z, n, xDel)` | **d** (g) | UTF-16 text | OPT |
| `sqlite3_bind_blob(s, i, p, n, xDel)` | **d** (g) | BLOB | **REQ** |
| `sqlite3_bind_blob64(s, i, p, n, xDel)` | **d** (g, f) | BLOB, `u64` length | REQ |
| `sqlite3_bind_zeroblob(s, i, n)` | a | an n-byte zero BLOB | REQ |
| `sqlite3_bind_zeroblob64(s, i, n)` | **f** | same, `u64` | OPT |
| `sqlite3_bind_value(s, i, v)` | a | copy an `sqlite3_value` | REQ |
| `sqlite3_bind_pointer(s, i, p, type, xDel)` | **d** | a typed pointer (carray, fts5_api) | REQ (fts5 handshake) |
| `sqlite3_bind_parameter_count(s)` | a | how many `?` | **REQ** |
| `sqlite3_bind_parameter_index(s, name)` | a | index of `:name` | **REQ** |
| `sqlite3_bind_parameter_name(s, i)` | a | name of index i | REQ |

Every text/blob bind takes a destructor pointer, so **the whole binding
family is bucket (d)** — but only two values of that pointer are ever
used: `SQLITE_STATIC` = `(void*)0` and `SQLITE_TRANSIENT` = `(void*)-1`
(sqlite3.h:6354–6355). See BLOCKER B-4: this is a sentinel, not a
callback, and it can be spelled `ptr` without trampolines.

### 1.6 Column access — 21

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_column_count(s)` | a | columns in the result set | **REQ** |
| `sqlite3_column_type(s, i)` | a | storage class of this cell | **REQ** |
| `sqlite3_column_int(s, i)` | a | as 32-bit int | REQ |
| `sqlite3_column_int64(s, i)` | a | as 64-bit int | **REQ** |
| `sqlite3_column_double(s, i)` | **b** | as REAL | **REQ** |
| `sqlite3_column_text(s, i)` | **g** | as UTF-8; buffer sqlite owns | **REQ** |
| `sqlite3_column_blob(s, i)` | **g** | as bytes; buffer sqlite owns | **REQ** |
| `sqlite3_column_bytes(s, i)` | a | length of the last text/blob read | **REQ** |
| `sqlite3_column_text16(s, i)` | **g** | UTF-16 | OPT |
| `sqlite3_column_bytes16(s, i)` | a | its length | OPT |
| `sqlite3_column_value(s, i)` | a | as an unprotected `sqlite3_value*` | OPT |
| `sqlite3_column_name(s, i)` | a | result column name | **REQ** |
| `sqlite3_column_name16(s, i)` | **g** | UTF-16 twin | OPT |
| `sqlite3_column_decltype(s, i)` | a | declared type of the source column | **REQ** |
| `sqlite3_column_decltype16(s, i)` | **g** | UTF-16 twin | OPT |
| `sqlite3_column_database_name(s, i)` | a | source schema | REQ¹ |
| `sqlite3_column_table_name(s, i)` | a | source table | REQ¹ |
| `sqlite3_column_origin_name(s, i)` | a | source column | REQ¹ |
| `…_database_name16` / `…_table_name16` / `…_origin_name16` | **g** | UTF-16 twins | OPT |

¹ Present only under `SQLITE_ENABLE_COLUMN_METADATA`. REQUIRED not for
the driver but for the **downstream ORM and the compile-time-checked SQL
of P10** (ROADMAP.md:1543): these three answer "which real column did
this result column come from", which is the whole basis of mapping a row
back onto a schema. Design for them now.

`column_bytes` is signature-shape (a) but semantically half of the bytes
protocol — the length companion to `column_text`/`column_blob`. Calling
them in the wrong order corrupts the answer (§4).

### 1.7 Errors — 6, all shape (a) except one

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_errcode(db)` | a | primary result code | **REQ** |
| `sqlite3_extended_errcode(db)` | a | extended result code | **REQ** |
| `sqlite3_errmsg(db)` | a | English message; sqlite owns the buffer | **REQ** |
| `sqlite3_errstr(code)` | a | message for a code, no connection | **REQ** |
| `sqlite3_error_offset(db)` | a | byte offset of the offending token | **REQ** |
| `sqlite3_errmsg16(db)` | **g** | UTF-16 twin | OPT |

`sqlite3_error_offset` is the one that makes a SQL syntax error a REAL
Avra diagnostic with a span, not a string. It is required.

### 1.8 Changes and rowid — 6, all shape (a)

`sqlite3_changes64(db)` **REQ**, `sqlite3_total_changes64(db)` **REQ**,
`sqlite3_last_insert_rowid(db)` **REQ**,
`sqlite3_set_last_insert_rowid(db, v)` OPT.
`sqlite3_changes` / `sqlite3_total_changes` are the 32-bit twins — not
formally deprecated, but they saturate; bind the 64-bit forms and skip
the others.

### 1.9 BLOB incremental IO — 6

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_blob_open(db, zDb, zTable, zCol, iRow, flags, ppBlob)` | **c** | open a BLOB as a stream | REQ |
| `sqlite3_blob_close(b)` | a | close it | REQ |
| `sqlite3_blob_reopen(b, iRow)` | a | move to another row, same column | REQ |
| `sqlite3_blob_bytes(b)` | a | its size | REQ |
| `sqlite3_blob_read(b, z, n, off)` | **g** | read n bytes at off | REQ |
| `sqlite3_blob_write(b, z, n, off)` | **g** | write n bytes at off | REQ |

This family is why a `Bytes` value category cannot be deferred: it is a
pure byte stream with no text interpretation anywhere.

### 1.10 Online backup — 5, all shape (a)

`sqlite3_backup_init(pDest, zDest, pSrc, zSrc)` REQ,
`sqlite3_backup_step(p, nPage)` REQ, `sqlite3_backup_finish(p)` REQ,
`sqlite3_backup_remaining(p)` REQ, `sqlite3_backup_pagecount(p)` REQ.
The whole family is bucket (a) — it is the ONE non-trivial capability a
driver can land with today's extern wall, and it is the natural first
integration test past `open`/`prepare`/`step`.

### 1.11 Hooks and callbacks — 13, every one shape (d)

| fn | what | verdict |
|---|---|---|
| `sqlite3_busy_handler(db, cb, p)` | called on lock contention | REQ |
| `sqlite3_progress_handler(db, n, cb, p)` | called every n VM steps — cancellation | REQ |
| `sqlite3_set_authorizer(db, cb, p)` | approve/deny each SQL action | **REQ** (the security surface) |
| `sqlite3_commit_hook(db, cb, p)` | before commit; may veto | REQ |
| `sqlite3_rollback_hook(db, cb, p)` | on rollback | REQ |
| `sqlite3_update_hook(db, cb, p)` | per row insert/update/delete | REQ |
| `sqlite3_wal_hook(db, cb, p)` | after a WAL commit | REQ |
| `sqlite3_autovacuum_pages(db, cb, p, xDel)` | how many pages to vacuum | OPT |
| `sqlite3_trace_v2(db, mask, cb, p)` | statement/profile/row/close events | REQ |
| `sqlite3_collation_needed(db, p, cb)` | an unknown collation was named | OPT |
| `sqlite3_collation_needed16(db, p, cb)` | UTF-16 twin | OPT |
| `sqlite3_trace(db, cb, p)` | legacy trace | **DEP** — `trace_v2` |
| `sqlite3_profile(db, cb, p)` | legacy profile | **DEP** — `trace_v2` |

`sqlite3_progress_handler` is the exception worth naming: its callback
takes ONLY `void*` and returns `int`. It is the smallest possible
trampoline and therefore the right first target for spec 15.3.

### 1.12 Custom SQL functions — 50

Registration (all shape **d**):
`sqlite3_create_function` REQ, `sqlite3_create_function_v2` REQ (adds
`xDestroy`), `sqlite3_create_window_function` REQ,
`sqlite3_create_function16` OPT.

Context, inside a function body (shape a):
`sqlite3_user_data(ctx)` REQ, `sqlite3_context_db_handle(ctx)` REQ,
`sqlite3_aggregate_context(ctx, nBytes)` REQ,
`sqlite3_get_auxdata(ctx, N)` OPT, `sqlite3_set_auxdata(ctx, N, p, xDel)`
OPT (**d**), `sqlite3_vtab_nochange(ctx)` OPT,
`sqlite3_aggregate_count(ctx)` **DEP** — use `sqlite3_aggregate_context`.

Answering (`sqlite3_result_*`, 19):
shape a — `_int`, `_int64`, `_null`, `_value`, `_zeroblob`,
`_error_code`, `_error_nomem`, `_error_toobig`, `_subtype`.
shape **b** — `_double`.
shape **d** (g) — `_text`, `_text16`, `_text16be`, `_text16le`,
`_text64`, `_blob`, `_blob64`, `_pointer`.
shape **g** — `_error`, `_error16`.
shape **f** — `_zeroblob64`.

Reading arguments (`sqlite3_value_*`, 19):
shape a — `_int`, `_int64`, `_type`, `_numeric_type`, `_subtype`,
`_nochange`, `_frombind`, `_pointer`, `_dup`, `_free`, `_bytes`,
`_bytes16`, `_encoding`.
shape **b** — `_double`.
shape **g** — `_text`, `_text16`, `_text16be`, `_text16le`, `_blob`.

The whole family is REQUIRED for "full surface" and every path into it
runs through a trampoline. It is the second-largest dependency on spec
15.3 after the hooks, and the LAST slice, not the first.

### 1.13 Collations — 3, all shape (d)

`sqlite3_create_collation` REQ, `sqlite3_create_collation_v2` REQ (adds
`xDestroy`), `sqlite3_create_collation16` OPT. The comparison callback is
`int(void*, int, const void*, int, const void*)` — a trampoline that also
needs bucket (g) on both sides.

### 1.14 Virtual tables — 11

`sqlite3_create_module(db, name, pModule, pClientData)` and
`sqlite3_create_module_v2(…, xDestroy)`: classified (a) and (d)
respectively by SIGNATURE, but this is misleading and must be recorded —
**`const sqlite3_module *p` is a struct of 20+ function pointers.** It is
the heaviest FFI shape in the whole API: a CALLBACK VTABLE, not a
callback. Nothing in spec 15.3 covers it.

`sqlite3_declare_vtab` (a), `sqlite3_vtab_config(db, op, …)` (**e**),
`sqlite3_vtab_on_conflict` (a), `sqlite3_vtab_nochange` (a),
`sqlite3_vtab_collation(idxInfo, i)` (a), `sqlite3_vtab_distinct` (a),
`sqlite3_vtab_in(idxInfo, iCons, bHandle)` (a),
`sqlite3_vtab_in_first(pVal, ppOut)` (**c**),
`sqlite3_vtab_in_next(pVal, ppOut)` (**c**),
`sqlite3_vtab_rhs_value(idxInfo, i, ppVal)` (**c**).

Verdict: OPTIONAL for the driver, **REQUIRED for the later `table<Row>`
integration** (ROADMAP.md:1544) — that is what a `table` literal backed
by SQLite would be built on. Design the seam, build it last.

### 1.15 VFS and filenames — 12, all shape (a)

`sqlite3_vfs_find(name)`, `sqlite3_vfs_register(vfs, makeDflt)`,
`sqlite3_vfs_unregister(vfs)` — the same vtable problem as
`create_module`: `sqlite3_vfs*` is a struct of function pointers.
OPTIONAL; a driver names an existing VFS by string in `open_v2`.

`sqlite3_uri_parameter(z, k)`, `sqlite3_uri_boolean(z, k, dflt)`,
`sqlite3_uri_int64(z, k, dflt)`, `sqlite3_uri_key(z, N)` — REQ, cheap,
shape (a); a driver that supports URI filenames reads its own options
back through them.

`sqlite3_filename_database(f)`, `_journal(f)`, `_wal(f)`,
`sqlite3_create_filename(…)`, `sqlite3_free_filename(f)` — OPT (VFS
authors only).

### 1.16 Serialize / deserialize — 2

| fn | shape | what | verdict |
|---|---|---|---|
| `sqlite3_serialize(db, zSchema, piSize, mFlags)` | **c** (g) | the whole database as bytes | REQ |
| `sqlite3_deserialize(db, zSchema, pData, szDb, szBuf, mFlags)` | **g** | load a database from bytes | REQ |

`serialize` is out-param AND bytes AND an ownership transfer
(`sqlite3_free` unless `SQLITE_SERIALIZE_NOCOPY`). It is the single
densest function in the API for FFI purposes and makes a good acceptance
test for the whole wall.

### 1.17 Snapshots — 5

`sqlite3_snapshot_get(db, zSchema, ppSnapshot)` (**c**),
`sqlite3_snapshot_open(db, zSchema, p)` (a),
`sqlite3_snapshot_free(p)` (a), `sqlite3_snapshot_cmp(p1, p2)` (a),
`sqlite3_snapshot_recover(db, zDb)` (a). OPT (`SQLITE_ENABLE_SNAPSHOT`).
`sqlite3_snapshot` is the API's clearest `opaque type … @free_with`
candidate after the connection itself.

### 1.18 WAL and checkpointing — 3

`sqlite3_wal_autocheckpoint(db, N)` (a) REQ,
`sqlite3_wal_checkpoint(db, zDb)` (a) DEP — superseded by
`sqlite3_wal_checkpoint_v2(db, zDb, eMode, pnLog, pnCkpt)` (**c**) REQ.

### 1.19 Limits, status and scan statistics — 12

`sqlite3_status(op, pCur, pHi, reset)` (**c**),
`sqlite3_status64(…)` (**c**),
`sqlite3_db_status(db, op, pCur, pHi, reset)` (**c**) — REQ, they are
the driver's whole observability story and each has TWO int out-params.
`sqlite3_memory_used()` (a), `sqlite3_memory_highwater(reset)` (a),
`sqlite3_soft_heap_limit64(N)` (a), `sqlite3_release_memory(N)` (a) — REQ.
`sqlite3_stmt_scanstatus(s, idx, op, pOut)` (**c**),
`sqlite3_stmt_scanstatus_v2(s, idx, op, flags, pOut)` (**c**),
`sqlite3_stmt_scanstatus_reset(s)` (a) — OPT
(`SQLITE_ENABLE_STMT_SCANSTATUS`); `pOut` is a `void*` whose real type
depends on `op` (int, i64, double, or `const char*`) — a **tagged
out-param**, the hardest out-param shape in the API.
`sqlite3_soft_heap_limit(N)` **DEP** — `soft_heap_limit64`.
`sqlite3_memory_alarm(…)` **DEP** — `sqlite3_config` with
`SQLITE_CONFIG_MEMSTATUS` / heap limits.

### 1.20 Memory allocator — 6

`sqlite3_malloc(n)` (a), `sqlite3_malloc64(n)` (**f**),
`sqlite3_realloc(p, n)` (a), `sqlite3_realloc64(p, n)` (**f**),
`sqlite3_free(p)` (a), `sqlite3_msize(p)` (**f**).
**`sqlite3_free` is REQUIRED** — it is the only correct way to release
what `sqlite3_serialize`, `sqlite3_expanded_sql`, `sqlite3_mprintf` and
`sqlite3_exec`'s `errmsg` hand back. The other five are OPT.

### 1.21 Mutexes — 5, all shape (a)

`sqlite3_mutex_alloc(type)`, `_free`, `_enter`, `_try`, `_leave`.
OPT — needed only if the driver exposes a shared connection across
threads. Note `sqlite3_mutex_held`/`_notheld` exist upstream under
`SQLITE_DEBUG` and are absent from Apple's header.

### 1.22 Strings, formatting and utilities — 30

`sqlite3_mprintf(fmt, …)` (**e**), `sqlite3_vmprintf` (**e**),
`sqlite3_snprintf` (**e**, g), `sqlite3_vsnprintf` (**e**, g) — OPT.
The driver builds SQL from Avra strings; SQLite's printf exists for `%q`
/ `%Q` / `%w` quoting, which a driver that always binds parameters does
not need. **Do not bind these** — they are variadic AND they invite
string-built SQL.

`sqlite3_str_new(db)` (a), `_append` (**g**), `_appendall` (a),
`_appendchar` (a), `_appendf` (**e**), `_vappendf` (**e**),
`_finish` (a), `_value` (a), `_length` (a), `_errcode` (a),
`_reset` (a) — OPT, same reasoning.

`sqlite3_strglob(g, s)` (a), `sqlite3_strlike(g, s, esc)` (a),
`sqlite3_stricmp(a, b)` (a), `sqlite3_strnicmp(a, b, n)` (**g**) — OPT.
`sqlite3_randomness(N, P)` (**g**) — OPT.
`sqlite3_sleep(ms)` (a) — OPT.
`sqlite3_log(code, fmt, …)` (**e**) — OPT.
`sqlite3_keyword_count()` (a), `sqlite3_keyword_name(i, pz, pn)` (**c**, g),
`sqlite3_keyword_check(z, n)` (**g**) — **REQ for P10**: this is how the
compiler would know whether an identifier in checked SQL needs quoting.
`sqlite3_table_column_metadata(db, zDb, zTable, zCol, pzType, pzColl,
pNotNull, pPrimaryKey, pAutoinc)` (**c**) — **REQ for the ORM**: FIVE
out-params, two of them `const char**`. The single worst out-param
signature in the API and the one the schema-checking work depends on.
`sqlite3_expired`, `sqlite3_transfer_bindings`, `sqlite3_global_recover`,
`sqlite3_thread_cleanup` — **DEP**, all four are no-ops or legacy;
replacements are `sqlite3_prepare_v2` (expired/transfer) and nothing
(the other two).

### 1.23 R-Tree — 2

`sqlite3_rtree_geometry_callback(db, zGeom, xGeom, pCtx)` (**d**, b) and
`sqlite3_rtree_query_callback(db, zQueryFunc, xQueryFunc, pCtx, xDtor)`
(**d**). OPT. Note the first also carries `sqlite3_rtree_dbl` — a
`double` (unless `SQLITE_RTREE_INT_ONLY`). The R-Tree INDEX itself is
pure SQL and needs no binding.

### 1.24 Session / changeset — 49, in `sqlite3session.h`

Not in Apple's SDK header at all; exported by the dylib (§3).
`sqlite3session_create/delete/attach/table_filter/changeset/patchset/
diff/enable/indirect/isempty/memory_used/changeset_size/config/
object_config` (14),
`sqlite3changeset_start/_v2/_strm/_v2_strm/next/op/pk/old/new/conflict/
fk_conflicts/finalize/invert/_strm/concat/_strm/apply/_v2/_strm/
_v2_strm` (20),
`sqlite3changegroup_new/add/add_change/add_strm/output/output_strm/
schema/delete` (8),
`sqlite3rebaser_create/configure/rebase/rebase_strm/delete` (5),
plus the preupdate six that pair with it.

Shapes: heavy on **c** (every `_start`, `_output`, `_changeset`,
`_patchset` writes through an out-param pair `int *pnData, void **ppData`
— out-param AND bytes together) and **d** (every `_apply` takes two
callbacks; every `_strm` takes a stream callback).

Verdict: **OPT for the driver, REQ for "full surface"** as the campaign
defines it. It is the correct LAST era — it needs every one of the wall's
features at once, which makes it the acceptance test for the whole
campaign rather than a slice of it.

### 1.25 FTS5, JSON, math, geopoly — ZERO `sqlite3_*` entry points

This is the finding that shrinks the work.

- **JSON** (`json`, `json_extract`, `->`, `->>`, `json_each`,
  `json_tree`): SQL functions and table-valued functions only. No C API.
  A driver reaches them by writing SQL.
- **Math** (`ceil`, `floor`, `pow`, `log`, `sqrt`, trig): SQL functions
  only, under `SQLITE_ENABLE_MATH_FUNCTIONS`. No C API. They return REAL,
  so they are a `float` dependency at the VALUE level, not the ABI level.
- **R-Tree index, Geopoly**: SQL virtual tables. No C API beyond the two
  rtree geometry registrars above.
- **FTS5**: SQL virtual table plus an extension API that is **a struct of
  function pointers**, `fts5_api` (sqlite3.h:11614–11660), reached by the
  documented handshake — `sqlite3_prepare_v2(db, "SELECT fts5(?1)")`,
  `sqlite3_bind_pointer(stmt, 1, &pApi, "fts5_api_ptr", NULL)`,
  `sqlite3_step`. Custom tokenizers and auxiliary functions go through
  `fts5_api.xCreateTokenizer_v2` / `xCreateFunction` and
  `Fts5ExtensionApi` (sqlite3.h:11268). Zero `sqlite3_*` symbols.

So: full-text search, JSON and math are **available to a driver that can
only prepare and step**. They cost nothing in the extern wall. Custom
FTS5 tokenizers cost a callback vtable — the same shape as
`sqlite3_module`, and the same last-era verdict.

---

## 2. THE ABI CLASSIFICATION

Every one of the 284 declared functions, in exactly one bucket, by
precedence **e > d > c > b > g > f > a**. Method: the joined declarations
were parsed and flagged mechanically (`/tmp/sq_classify.py`), then the
false positives corrected by hand (function-pointer parameters contain
`**` inside their own type; `sqlite3_free_table`, `sqlite3_drop_modules`
and `sqlite3_create_filename` take `char**`/`const char**` as INPUT
arrays, not out-params).

| bucket | needs | count | share |
|---|---|---:|---:|
| **(a)** all-int/pointer args, int/pointer/void return | *callable today* | **173** | 61% |
| **(b)** takes or returns a `double` | **`float`** (IEEE-754 f64) | **4** | 1% |
| **(c)** out-param (`T**` or `T*`) | out-params or multi-return | **24** | 8% |
| **(d)** function-pointer parameter | trampolines (spec 15.3) | **43** | 15% |
| **(e)** variadic | a variadic or op-typed extern form | **11** | 4% |
| **(f)** `sqlite3_uint64` in the signature | unsigned-64 concerns | **5** | 2% |
| **(g)** length-carrying pointer | **`Bytes`** | **24** | 8% |

Counting SECONDARY shapes too (a function may need several), the number
of functions TOUCHING each feature is: `float` **5**, out-params **25**,
trampolines **43**, variadic **11**, u64 **10**, `Bytes` **50** (plus 6
length companions of shape (a)).

**The headline: 61% of the surface is callable the day the extern wall
gets nothing but out-params, and `open_v2` / `prepare_v3` / `step` /
`column_*` / `finalize` — the spine every program walks — needs exactly
three features: out-params, `float`, and `Bytes`. Trampolines gate 15% of
the surface and NONE of the spine.**

### (b) DOUBLE — 4 members, exhaustive

```
sqlite3_bind_double(sqlite3_stmt*, int, double)      -> int
sqlite3_column_double(sqlite3_stmt*, int)            -> double
sqlite3_result_double(sqlite3_context*, double)      -> void
sqlite3_value_double(sqlite3_value*)                 -> double
```
Plus, as a secondary shape: `sqlite3_rtree_geometry_callback`
(`sqlite3_rtree_dbl` in its callback's signature).

Four functions. That is the entire `double` footprint of SQLite's C API.
Two of them (`bind_double`, `column_double`) are on the spine and
UNAVOIDABLE: a REAL column has no other door.

### (c) OUT-PARAM — 24 members, exhaustive

| fn | the out seats |
|---|---|
| `sqlite3_open` | `sqlite3 **ppDb` |
| `sqlite3_open16` | `sqlite3 **ppDb` |
| `sqlite3_open_v2` | `sqlite3 **ppDb` |
| `sqlite3_prepare` | `sqlite3_stmt **ppStmt`, `const char **pzTail` |
| `sqlite3_prepare_v2` | `sqlite3_stmt **ppStmt`, `const char **pzTail` |
| `sqlite3_prepare_v3` | `sqlite3_stmt **ppStmt`, `const char **pzTail` |
| `sqlite3_prepare16` | `sqlite3_stmt **`, `const void **pzTail` |
| `sqlite3_prepare16_v2` | `sqlite3_stmt **`, `const void **pzTail` |
| `sqlite3_prepare16_v3` | `sqlite3_stmt **`, `const void **pzTail` |
| `sqlite3_blob_open` | `sqlite3_blob **ppBlob` |
| `sqlite3_get_table` | `char ***pazResult`, `int *pnRow`, `int *pnColumn`, `char **pzErrmsg` |
| `sqlite3_serialize` | `sqlite3_int64 *piSize` |
| `sqlite3_snapshot_get` | `sqlite3_snapshot **ppSnapshot` |
| `sqlite3_status` | `int *pCurrent`, `int *pHighwater` |
| `sqlite3_status64` | `sqlite3_int64 *pCurrent`, `sqlite3_int64 *pHighwater` |
| `sqlite3_db_status` | `int *pCur`, `int *pHiwtr` |
| `sqlite3_stmt_scanstatus` | `void *pOut` (type depends on the op) |
| `sqlite3_stmt_scanstatus_v2` | `void *pOut` (type depends on the op) |
| `sqlite3_table_column_metadata` | `char const **pzDataType`, `char const **pzCollSeq`, `int *pNotNull`, `int *pPrimaryKey`, `int *pAutoinc` |
| `sqlite3_wal_checkpoint_v2` | `int *pnLog`, `int *pnCkpt` |
| `sqlite3_keyword_name` | `const char **`, `int *` |
| `sqlite3_vtab_in_first` | `sqlite3_value **ppOut` |
| `sqlite3_vtab_in_next` | `sqlite3_value **ppOut` |
| `sqlite3_vtab_rhs_value` | `sqlite3_value **ppVal` |

Plus one secondary: `sqlite3_exec` (`char **errmsg`).

Four distinct out-param KINDS, and the design must serve all four:
1. **handle out** — `T**` where T is opaque: `sqlite3**` (3 fns),
   `sqlite3_stmt**` (6), `sqlite3_blob**`, `sqlite3_snapshot**`,
   `sqlite3_value**` (3). 14 seats. Every one of them is a Class-6
   owned handle (§4.2) and therefore an `opaque type` candidate.
2. **scalar out** — `int*` / `sqlite3_int64*` (`status`, `status64`,
   `db_status`, `wal_checkpoint_v2`, `serialize`,
   `table_column_metadata`, `get_table`, `keyword_name`). 17 seats.
3. **borrowed-text out** — `const char**` pointing INTO memory the
   caller or sqlite owns: `pzTail` (6), `pzDataType`, `pzCollSeq`,
   `keyword_name`'s name. Bucket (c) AND a lifetime hazard (§4).
4. **owned-text out** — `char**` the CALLER must `sqlite3_free`:
   `sqlite3_exec`'s `errmsg`, `sqlite3_get_table`'s `pzErrmsg`, and
   its `char ***pazResult` (freed by `sqlite3_free_table`). All three
   belong to functions this document marks OPT or DEP; the design need
   not serve them first.

The `pzTail` seats deserve their own note: they point into the CALLER's
SQL buffer, not sqlite's, so their lifetime is the Avra string's. They
are how a driver splits a multi-statement script, and a driver that
ignores them silently executes only the first statement.

### (d) FUNCTION POINTER — 43 members, exhaustive

Destructor-only (the pointer is a SENTINEL — `SQLITE_STATIC` = 0,
`SQLITE_TRANSIENT` = -1 — in every driver use; **14**):
```
sqlite3_bind_blob     sqlite3_bind_blob64     sqlite3_bind_text
sqlite3_bind_text16   sqlite3_bind_text64     sqlite3_bind_pointer
sqlite3_result_blob   sqlite3_result_blob64   sqlite3_result_text
sqlite3_result_text16 sqlite3_result_text16be sqlite3_result_text16le
sqlite3_result_text64 sqlite3_result_pointer
```

Real callbacks (**29**):
```
sqlite3_auto_extension          sqlite3_cancel_auto_extension
sqlite3_autovacuum_pages        sqlite3_busy_handler
sqlite3_collation_needed        sqlite3_collation_needed16
sqlite3_commit_hook             sqlite3_rollback_hook
sqlite3_update_hook             sqlite3_wal_hook
sqlite3_create_collation        sqlite3_create_collation16
sqlite3_create_collation_v2     sqlite3_create_function
sqlite3_create_function16       sqlite3_create_function_v2
sqlite3_create_window_function  sqlite3_create_module_v2
sqlite3_exec                    sqlite3_memory_alarm (DEP)
sqlite3_profile (DEP)           sqlite3_trace (DEP)
sqlite3_progress_handler        sqlite3_set_authorizer
sqlite3_set_auxdata             sqlite3_set_clientdata
sqlite3_trace_v2                sqlite3_rtree_geometry_callback
sqlite3_rtree_query_callback
```

Every real callback except `sqlite3_auto_extension`,
`sqlite3_cancel_auto_extension` and the two rtree registrars takes a
`void *pArg` user-data seat, so spec 15.3's user-data convention fits the
API as written — the spec's refusal case ("this C API's callback does not
accept user data") applies to exactly four functions, all OPTIONAL.

Also in this bucket by NATURE though not by signature — the **callback
vtables**, which spec 15.3 does not cover at all:
`sqlite3_create_module` / `_v2` (`const sqlite3_module*`, 20+ pointers),
`sqlite3_vfs_register` / `_find` (`sqlite3_vfs*`, 20+ pointers),
`sqlite3_config` with `SQLITE_CONFIG_MALLOC` / `_PCACHE2` / `_MUTEX`
(`sqlite3_mem_methods`, `sqlite3_pcache_methods2`,
`sqlite3_mutex_methods`), and FTS5's `fts5_api` / `Fts5ExtensionApi` /
`fts5_tokenizer_v2`.

### (e) VARIADIC — 11 members, exhaustive

```
sqlite3_config(int, ...)                     -> int
sqlite3_db_config(sqlite3*, int op, ...)     -> int
sqlite3_vtab_config(sqlite3*, int op, ...)   -> int
sqlite3_test_control(int op, ...)            -> int
sqlite3_log(int, const char*, ...)           -> void
sqlite3_mprintf(const char*, ...)            -> char*
sqlite3_snprintf(int, char*, const char*, ...) -> char*
sqlite3_str_appendf(sqlite3_str*, const char*, ...) -> void
sqlite3_vmprintf(const char*, va_list)       -> char*
sqlite3_vsnprintf(int, char*, const char*, va_list) -> char*
sqlite3_str_vappendf(sqlite3_str*, const char*, va_list) -> void
```

These split cleanly in two, and only one half matters:

- **printf-family (7)** — `mprintf`, `vmprintf`, `snprintf`, `vsnprintf`,
  `log`, `str_appendf`, `str_vappendf`. All OPTIONAL. **Do not bind
  them.** Avra has interpolation; SQLite's printf exists to build SQL
  by concatenation, which a parameter-binding driver never does.
- **op-dispatch family (4)** — `config`, `db_config`, `vtab_config`,
  `test_control`. These are NOT really variadic: each is a fixed set of
  `(op, …)` overloads enumerated in the header. `SQLITE_CONFIG_*` /
  `SQLITE_DBCONFIG_*` op codes take a known, small argument shape —
  `(int)`, `(int, int*)`, `(i64)`, `(void*)`, or a methods struct. The
  right answer is NOT a variadic extern: it is **one narrow monomorphic
  extern per argument shape**, declared against the same C symbol.
  See BLOCKER B-5.

### (f) 64-BIT-ONLY CONCERNS — 5 members, exhaustive

```
sqlite3_bind_zeroblob64(sqlite3_stmt*, int, sqlite3_uint64)  -> int
sqlite3_result_zeroblob64(sqlite3_context*, sqlite3_uint64)  -> int
sqlite3_malloc64(sqlite3_uint64)                             -> void*
sqlite3_realloc64(void*, sqlite3_uint64)                     -> void*
sqlite3_msize(void*)                                         -> sqlite3_uint64
```
Plus five secondary: `sqlite3_bind_blob64`, `sqlite3_bind_text64`,
`sqlite3_result_blob64`, `sqlite3_result_text64`, `sqlite3_profile` (DEP).

**No SQLite function takes or returns a struct by value.** The (f) bucket
is therefore purely the unsigned-64 question, and it is nearly empty:
Avra's `int` IS i64, so every `sqlite3_int64` seat is already exact. Only
`sqlite3_uint64` differs, and only above 2⁶³ — a blob of 9.2 exabytes.
Every one of these ten has a 32-bit or `sqlite3_int64` twin except
`sqlite3_msize`, which is OPTIONAL. **Bucket (f) blocks nothing.**
Bind the non-`64` twins; declare the `uint64` seats as `int` with a
recorded note; move on.

### (g) LENGTH-CARRYING BYTES — 24 primary, 50 touching

Primary (the length rides IN the call, or the answer is a raw buffer):
```
sqlite3_column_blob      sqlite3_column_text      sqlite3_column_text16
sqlite3_value_blob       sqlite3_value_text       sqlite3_value_text16
sqlite3_value_text16be   sqlite3_value_text16le
sqlite3_blob_read        sqlite3_blob_write
sqlite3_deserialize      sqlite3_randomness
sqlite3_result_error     sqlite3_result_error16
sqlite3_str_append       sqlite3_strnicmp         sqlite3_keyword_check
sqlite3_errmsg16         sqlite3_complete16
sqlite3_column_name16    sqlite3_column_decltype16
sqlite3_column_database_name16 sqlite3_column_table_name16
sqlite3_column_origin_name16
```
Secondary (a bytes seat plus a heavier primary shape):
`sqlite3_bind_blob`, `_blob64`, `_text`, `_text16`, `_text64`,
`sqlite3_result_blob`, `_blob64`, `_text`, `_text16`, `_text16be`,
`_text16le`, `_text64`, `sqlite3_create_collation`, `_v2`, `_16`,
`sqlite3_serialize`, `sqlite3_prepare*` (6), `sqlite3_open16`,
`sqlite3_keyword_name`, `sqlite3_snprintf`, `sqlite3_vsnprintf`.

Length COMPANIONS, shape (a) but part of the protocol:
`sqlite3_column_bytes`, `_bytes16`, `sqlite3_value_bytes`, `_bytes16`,
`sqlite3_blob_bytes`, `sqlite3_value_encoding`.

---

## 3. THE COMPILE-FLAG MATRIX

### 3.1 What the surface costs, flag by flag

| flag | gates | default |
|---|---|---|
| `SQLITE_ENABLE_COLUMN_METADATA` | `sqlite3_column_database_name`/`_table_name`/`_origin_name` (+3 UTF-16 twins) — 6 fns | OFF |
| `SQLITE_OMIT_DESERIALIZE` | removes `sqlite3_serialize`/`sqlite3_deserialize` — 2 fns | present since 3.36; `SQLITE_ENABLE_DESERIALIZE` is now a no-op |
| `SQLITE_ENABLE_SESSION` (requires `SQLITE_ENABLE_PREUPDATE_HOOK`) | the 49 session/changeset fns | OFF |
| `SQLITE_ENABLE_PREUPDATE_HOOK` | `sqlite3_preupdate_hook`/`_old`/`_new`/`_count`/`_depth`/`_blobwrite` — 6 fns | OFF |
| `SQLITE_ENABLE_SNAPSHOT` | the 5 `sqlite3_snapshot_*` | OFF |
| `SQLITE_ENABLE_NORMALIZE` | `sqlite3_normalized_sql` | OFF |
| `SQLITE_ENABLE_STMT_SCANSTATUS` | `sqlite3_stmt_scanstatus`/`_v2`/`_reset` | OFF |
| `SQLITE_ENABLE_UNLOCK_NOTIFY` | `sqlite3_unlock_notify` | OFF |
| `SQLITE_ENABLE_RTREE` | the 2 `sqlite3_rtree_*` + the SQL index | OFF |
| `SQLITE_ENABLE_GEOPOLY` (implies RTREE) | SQL only | OFF |
| `SQLITE_ENABLE_FTS5` | SQL vtab + the `fts5_api` handshake; **no C symbols** | OFF |
| `SQLITE_ENABLE_FTS3` / `_FTS4` / `_FTS3_PARENTHESIS` | SQL only | OFF |
| `SQLITE_ENABLE_MATH_FUNCTIONS` | SQL only | OFF |
| `SQLITE_ENABLE_DBSTAT_VTAB` / `_DBPAGE_VTAB` / `_BYTECODE_VTAB` | SQL only (introspection) | OFF |
| `SQLITE_ENABLE_STAT4` | query-planner histograms; SQL only | OFF |
| `SQLITE_OMIT_LOAD_EXTENSION` | removes `sqlite3_load_extension`, `sqlite3_enable_load_extension` | not set |
| `SQLITE_OMIT_DEPRECATED` | removes the 9 `SQLITE_DEPRECATED` fns | not set |
| `SQLITE_OMIT_DECLTYPE` | removes `sqlite3_column_decltype`/`16` | not set |
| `SQLITE_OMIT_PROGRESS_CALLBACK` | removes `sqlite3_progress_handler` | not set |
| `SQLITE_OMIT_SHARED_CACHE` | removes `sqlite3_enable_shared_cache` | not set |
| `SQLITE_OMIT_AUTOINIT` | makes `sqlite3_initialize()` mandatory | not set |
| `SQLITE_ENABLE_API_ARMOR` | no surface change; validates arguments | OFF |
| `SQLITE_THREADSAFE` | 0 none / 1 serialized / 2 multi-thread | 1 |
| `SQLITE_DQS` | 0 forbids double-quoted string literals everywhere | 3 (both DDL and DML allowed) |
| `SQLITE_DEFAULT_MEMSTATUS` | 0 disables `sqlite3_status` memory tracking by default | 1 |
| `SQLITE_MAX_VARIABLE_NUMBER` | upper bound on `?NNN` | 32766 |

### 3.2 What Apple's build actually is — and the correction

**HOW DETERMINED.** Three independent reads, corroborating:
1. `sqlite3 :memory: "PRAGMA compile_options"` on `/usr/bin/sqlite3`
   (3.51.0, `…dcaapl`) — the definitive option list, quoted below.
   CAVEAT: `otool -L /usr/bin/sqlite3` shows NO `libsqlite3.dylib`
   dependency, so the CLI STATICALLY links its own copy. The options are
   therefore the CLI's build, not proven to be the dylib's.
2. `libsqlite3.tbd`'s export list (368 `sqlite3*` symbols) — every
   symbol the dylib ships. It is CONSISTENT with (1) at every testable
   point: session and preupdate symbols exported (matches `ENABLE_SESSION`
   / `ENABLE_PREUPDATE_HOOK`), `sqlite3_load_extension` and
   `sqlite3_enable_load_extension` absent (matches `OMIT_LOAD_EXTENSION`),
   `sqlite3_unlock_notify` absent (matches no `ENABLE_UNLOCK_NOTIFY`),
   `sqlite3_snapshot_*` / `_normalized_sql` / `_stmt_scanstatus` /
   `_rtree_*` present (matches those `ENABLE`s), `sqlite3_key`/`_rekey`
   present (matches `CODEC=see-cccrypt`).
3. Apple's SDK header itself: `sqlite3_column_database_name` is declared
   unconditionally at sqlite3.h:5137 — a header trimmed to what the
   binary actually has.

Verdict: the CLI's option list describes the dylib too. **Confidence
HIGH** on every flag corroborated by (2); **MEDIUM** on flags with no
symbol to test (`DQS=3`, `THREADSAFE=2`, `DEFAULT_MEMSTATUS=0`,
`MAX_*`, `ENABLE_FTS5`, `ENABLE_MATH_FUNCTIONS`, `ENABLE_STAT4`).

Apple's 3.51.0, verbatim from `PRAGMA compile_options`:
```
ATOMIC_INTRINSICS=1        BUG_COMPATIBLE_20160819   CCCRYPT256
CODEC=see-cccrypt          COMPILER=clang-21.0.0     DEFAULT_AUTOVACUUM
DEFAULT_CACHE_SIZE=2000    DEFAULT_CKPTFULLFSYNC     DEFAULT_FILE_FORMAT=4
DEFAULT_JOURNAL_SIZE_LIMIT=32768                     DEFAULT_LOOKASIDE=1200,102
DEFAULT_MEMSTATUS=0        DEFAULT_MMAP_SIZE=0       DEFAULT_PAGE_SIZE=4096
DEFAULT_PCACHE_INITSZ=20   DEFAULT_RECURSIVE_TRIGGERS
DEFAULT_SECTOR_SIZE=4096   DEFAULT_SYNCHRONOUS=2     DEFAULT_WAL_AUTOCHECKPOINT=1000
DEFAULT_WAL_SYNCHRONOUS=1  DEFAULT_WORKER_THREADS=0  DIRECT_OVERFLOW_READ
DQS=3                      ENABLE_API_ARMOR          ENABLE_BYTECODE_VTAB
ENABLE_COLUMN_METADATA     ENABLE_DBPAGE_VTAB        ENABLE_DBSTAT_VTAB
ENABLE_EXPLAIN_COMMENTS    ENABLE_FTS3               ENABLE_FTS3_PARENTHESIS
ENABLE_FTS3_TOKENIZER      ENABLE_FTS4               ENABLE_FTS5
ENABLE_LOCKING_STYLE=1     ENABLE_MATH_FUNCTIONS     ENABLE_NORMALIZE
ENABLE_PREUPDATE_HOOK      ENABLE_RTREE              ENABLE_SESSION
ENABLE_SETLK_TIMEOUT       ENABLE_SQLLOG             ENABLE_STMT_SCANSTATUS
ENABLE_UNKNOWN_SQL_FUNCTION                          ENABLE_UPDATE_DELETE_LIMIT
HAS_CODEC_RESTRICTED       HAVE_ISNAN                MALLOC_SOFT_LIMIT=1024
MAX_ATTACHED=10            MAX_COLUMN=2000           MAX_COMPOUND_SELECT=500
MAX_DEFAULT_PAGE_SIZE=8192 MAX_EXPR_DEPTH=1000       MAX_FUNCTION_ARG=127
MAX_LENGTH=2147483645      MAX_LIKE_PATTERN_LENGTH=50000
MAX_MMAP_SIZE=1073741824   MAX_PAGE_COUNT=1073741823 MAX_PAGE_SIZE=65536
MAX_SQL_LENGTH=1000000000  MAX_TRIGGER_DEPTH=1000    MAX_VARIABLE_NUMBER=500000
MAX_VDBE_OP=250000000      MAX_WORKER_THREADS=8      MUTEX_UNFAIR
OMIT_AUTORESET             OMIT_LOAD_EXTENSION       STMTJRNL_SPILL=131072
SYSTEM_MALLOC              TEMP_STORE=1              THREADSAFE=2
USE_URI
```

**THE CORRECTION.** ROADMAP.md:1526–1529 records "Apple's libsqlite3 is
built without `SQLITE_ENABLE_COLUMN_METADATA`, `DESERIALIZE` and
`SESSION`". On this machine, at 3.51.0, that is **wrong on all three**:
`ENABLE_COLUMN_METADATA` and `ENABLE_SESSION` are both listed, and
DESERIALIZE has been ON BY DEFAULT since 3.36.0 (`SQLITE_ENABLE_DESERIALIZE`
is a no-op; only `SQLITE_OMIT_DESERIALIZE` removes it) — and
`sqlite3_serialize` / `sqlite3_deserialize` are both declared
(sqlite3.h) and exported (`libsqlite3.tbd`).

**The vendoring decision does not change; its REASONS do.** Nine that
hold, each verified:
1. **`OMIT_LOAD_EXTENSION`.** No loadable extension can ever be used, and
   the two C entry points do not exist. This alone forecloses a class of
   the surface, permanently, on every Mac.
2. **`DQS=3`.** The double-quoted-string misfeature is ON in both DDL and
   DML. A typo'd column name silently becomes a string literal. It is
   fixable per connection via `sqlite3_db_config(SQLITE_DBCONFIG_DQS_*)`
   — but only if the driver remembers, on every connection, forever.
3. **No `sqlite3session.h`, no preupdate declarations.** The symbols
   exist; Apple ships no header. Binding them would be binding an
   unsupported, undocumented, Apple-private ABI.
4. **`CODEC=see-cccrypt`, `HAS_CODEC_RESTRICTED`,
   `BUG_COMPATIBLE_20160819`.** This is not stock SQLite. It carries
   Apple's SEE codec and a deliberate bug-compatibility mode.
5. **`THREADSAFE=2`** (multi-thread, not serialized) — a connection
   carries no mutex by default.
6. **No `ENABLE_UNLOCK_NOTIFY`, no `ENABLE_GEOPOLY`, no
   `ENABLE_MEMORY_MANAGEMENT`.**
7. **Version is the OS's.** 3.51.0 here; a different macOS is a different
   SQLite, with a different surface and different `PRAGMA` behaviour.
8. **Every other platform differs.** Homebrew's Python on this same
   machine links a 3.53.1 with `ENABLE_GEOPOLY`, `ENABLE_STAT4`,
   `ENABLE_UNLOCK_NOTIFY`, `ENABLE_MEMORY_MANAGEMENT`, `ENABLE_PERCENTILE`,
   `THREADSAFE=1`, `MAX_VARIABLE_NUMBER=250000` and NO session/FTS3-tokenizer
   — a different surface again, on one machine, one afternoon.
9. **P14.** One version, one static object, one binary, no host
   dependency. That is the argument that never expires.

### 3.3 The recommended vendored flag set

Two axes the campaign must not confuse: sqlite.org's "Recommended
Compile-time Options" optimizes for a SHIPPING APPLICATION, and four of
its twelve REMOVE surface. A full-surface driver takes the safety and
speed half and rejects the amputations.

```
# ── Surface: everything the campaign calls "full" ───────────────
-DSQLITE_ENABLE_COLUMN_METADATA=1     # the 6 origin-name fns (ORM, P10)
-DSQLITE_ENABLE_PREUPDATE_HOOK=1      # required by SESSION
-DSQLITE_ENABLE_SESSION=1             # the 49 changeset fns
-DSQLITE_ENABLE_SNAPSHOT=1            # the 5 snapshot fns
-DSQLITE_ENABLE_NORMALIZE=1           # sqlite3_normalized_sql
-DSQLITE_ENABLE_STMT_SCANSTATUS=1     # scanstatus (query profiling)
-DSQLITE_ENABLE_UNLOCK_NOTIFY=1       # sqlite3_unlock_notify
-DSQLITE_ENABLE_FTS5=1                # full-text search (SQL + fts5_api)
-DSQLITE_ENABLE_RTREE=1               # R*Tree index + 2 C registrars
-DSQLITE_ENABLE_GEOPOLY=1             # implies RTREE
-DSQLITE_ENABLE_MATH_FUNCTIONS=1      # ceil/floor/pow/log/trig -> REAL
-DSQLITE_ENABLE_DBSTAT_VTAB=1         # dbstat introspection
-DSQLITE_ENABLE_DBPAGE_VTAB=1         # sqlite_dbpage
-DSQLITE_ENABLE_BYTECODE_VTAB=1       # bytecode/tables_used (P7: visible magic)
-DSQLITE_ENABLE_STAT4=1               # planner histograms
-DSQLITE_ENABLE_EXPLAIN_COMMENTS=1    # readable EXPLAIN (P7)
-DSQLITE_ENABLE_OFFSET_SQL_FUNC=1     # sqlite_offset()
# deserialize needs no flag since 3.36 — do NOT set SQLITE_OMIT_DESERIALIZE
# JSON needs no flag since 3.38 — do NOT set SQLITE_OMIT_JSON

# ── Correctness and safety ─────────────────────────────────────
-DSQLITE_DQS=0                        # the misfeature OFF at the source
-DSQLITE_ENABLE_API_ARMOR=1           # validate every argument crossing the wall
-DSQLITE_LIKE_DOESNT_MATCH_BLOBS=1    # LIKE/GLOB false on BLOBs
-DSQLITE_STRICT_SUBTYPE=1             # subtype misuse is an error
-DSQLITE_DEFAULT_FOREIGN_KEYS=1       # FKs enforced by default
-DSQLITE_THREADSAFE=1                 # serialized: a connection carries its mutex
-DSQLITE_USE_URI=1                    # URI filenames on

# ── Speed ──────────────────────────────────────────────────────
-DSQLITE_DEFAULT_MEMSTATUS=0          # ~1-2%; sqlite3_status memory off by default
-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1    # NORMAL in WAL
-DSQLITE_MAX_EXPR_DEPTH=0             # no depth accounting
-DSQLITE_OMIT_AUTOINIT=1              # the driver calls sqlite3_initialize()
-DSQLITE_DEFAULT_MMAP_SIZE=268435456  # 256 MB mmap by default
-DSQLITE_MAX_MMAP_SIZE=1099511627776
-DSQLITE_DEFAULT_CACHE_SIZE=-8000     # 8 MB page cache (negative = KiB)
-DSQLITE_DEFAULT_WORKER_THREADS=0     # deterministic sorts; raise per connection
-DNDEBUG=1
-O2                                   # NOT -O3: upstream tests at -O2
```

**REJECTED from sqlite.org's twelve, and why:**
- `SQLITE_THREADSAFE=0` — a 2% gain that makes a connection unusable from
  more than one thread. Refused: P2 (a substrate for autonomous services).
- `SQLITE_OMIT_DECLTYPE` — deletes `sqlite3_column_decltype`, which the
  ORM needs to map a column back to a declared type.
- `SQLITE_OMIT_PROGRESS_CALLBACK` — deletes the smallest trampoline in the
  API, which is the right first target for spec 15.3.
- `SQLITE_OMIT_SHARED_CACHE` — harmless to keep; `sqlite3_enable_shared_cache`
  stays bindable and deprecated.
- `SQLITE_OMIT_DEPRECATED` — TAKE IT LATER. Setting it now would delete
  9 functions this document classifies; set it once the driver's
  DEPRECATED verdicts are locked and its tests prove nothing calls them.
  Record it as a checklist item, not a build flag today.

**THE FLAG SET IS A TESTABLE ARTIFACT.** Every one of the `ENABLE`/`DQS`/
`THREADSAFE` lines above is observable at runtime through
`sqlite3_compileoption_used(name)`. The first corpus program the driver
ships should assert the whole list — that turns "compiled with our flags"
from a Makefile claim into a gate.

---

## 4. POINTER LIFETIME RULES, AND THE COPY AT THE BOUNDARY

### 4.1 The law this collides with

`runtime/avra_runtime.c:8–32` and `:51–72`: every pointer Avra holds
carries a 16-byte header (`tag`, `kind`, `rc`, `len`) BEFORE the payload,
and `hdr()` recovers it by reading `(Header*)p - 1`. `str_static`
(`avra_runtime.c:302`) COPIES its input into a `KIND_STATIC` box. The
belt is the tag: `hdr()` returns NULL for an unaligned address, an
address below the image base, or a header without `0x41565241`
(`avra_runtime.c:68–72`), so `avra_rc_retain` / `_release` leave a foreign
pointer alone rather than corrupting it.

Two consequences, and they point opposite ways:

1. **A foreign `const char*` handed across as Avra `string` is a bug**,
   not a crash. `is_managed` (`language/memory.av:29–46`) says `.Str ->
   true`, so the memory pass emits a `Release` for it at scope end;
   `avra_rc_release` reads sixteen bytes BEFORE sqlite's buffer, finds no
   tag, and returns. Silent today. It becomes a wild write the moment
   those sixteen bytes happen to spell `AVRA` — and it means `.length`,
   `==`, `contains` and every string method run against memory whose
   layout Avra does not own. ROADMAP.md:1583 already records this; the
   header's tag is why it is currently invisible rather than fatal.

2. **A foreign pointer handed across as Avra `ptr` is SAFE by
   construction.** `is_managed` answers `.Ptr -> false`
   (`language/memory.av:42–43`), so no retain and no release is ever emitted
   for it, and `rt_kind_of` (`core/runtime_api.av:95–99`) rides it in a
   `RtKind.Ptr` seat. **A `sqlite3*`, a `sqlite3_stmt*`, a
   `sqlite3_value*`, a `const char*` from `sqlite3_column_text` — all of
   them cross correctly as `ptr` today.** The wall's rule is therefore
   one line: **the extern wall answers `ptr` for every sqlite-owned
   pointer, and Avra text is minted from it by an explicit copying verb.**

### 4.2 The lifetime classes

**CLASS 1 — dies on the next `step`/`reset`/`finalize`, or on a TYPE
CONVERSION.** The dangerous ones.
```
sqlite3_column_text   sqlite3_column_text16   sqlite3_column_blob
```
sqlite3.h:5500–5505, verbatim: *"The pointers returned are valid until a
type conversion occurs as described above, or until sqlite3_step() or
sqlite3_reset() or sqlite3_finalize() is called. The memory space used to
hold strings and BLOBs is freed automatically. Do not pass the pointers
returned from sqlite3_column_blob(), sqlite3_column_text(), etc. into
sqlite3_free()."*

The type-conversion clause is the trap: calling `sqlite3_column_bytes16`
after `sqlite3_column_text` forces a UTF-8→UTF-16 conversion that MAY
invalidate the pointer you already hold (sqlite3.h:5470–5498). The header
prescribes the only safe orders:
`column_text` then `column_bytes`; `column_blob` then `column_bytes`;
`column_text16` then `column_bytes16`. **Never mix.** This must be a LAW
in the driver, enforced by the shape of the API it exposes — not a
comment. Nobody frees these.

**CLASS 2 — dies on the next call into sqlite on the same connection.**
```
sqlite3_errmsg    sqlite3_errmsg16
```
sqlite3.h:4199–4202, verbatim: *"Memory to hold the error message string
is managed internally. The application does not need to worry about
freeing the result. However, the error string might be overwritten or
deallocated by subsequent calls to other SQLite interface functions."*
Copy immediately, at the call site, before anything else touches `db`.

**CLASS 3 — dies with the statement.**
```
sqlite3_column_name       sqlite3_column_name16
sqlite3_column_decltype   sqlite3_column_decltype16
sqlite3_column_database_name  sqlite3_column_table_name
sqlite3_column_origin_name    (+ their 3 UTF-16 twins)
sqlite3_bind_parameter_name   sqlite3_sql   sqlite3_normalized_sql
```
Valid until the statement is finalized (or, for the names, until the
statement is re-prepared by an automatic reprepare). Nobody frees these.

**CLASS 4 — dies with the connection.**
```
sqlite3_db_filename   sqlite3_db_name   sqlite3_db_handle
sqlite3_context_db_handle   sqlite3_db_mutex   sqlite3_next_stmt
sqlite3_filename_database / _journal / _wal
sqlite3_uri_parameter / _uri_key
sqlite3_get_clientdata   sqlite3_user_data   sqlite3_get_auxdata
sqlite3_vtab_collation   sqlite3_database_file_object
```
Nobody frees these.

**CLASS 5 — CALLER OWNS, free with `sqlite3_free`.** The leak surface.
```
sqlite3_expanded_sql   sqlite3_serialize (unless SQLITE_SERIALIZE_NOCOPY)
sqlite3_mprintf   sqlite3_vmprintf   sqlite3_snprintf(→ its own buffer)
sqlite3_str_finish
sqlite3_exec's *errmsg   sqlite3_get_table's azResult (→ sqlite3_free_table)
sqlite3_malloc / _malloc64 / _realloc / _realloc64
```
Every one of these is a `defer sqlite3_free(p)` in the driver, or a leak.

**CLASS 6 — CALLER OWNS, free with a NAMED destructor.** These are
exactly the `opaque type … @free_with` candidates of spec 15.5.
```
sqlite3*        -> sqlite3_close_v2
sqlite3_stmt*   -> sqlite3_finalize
sqlite3_blob*   -> sqlite3_blob_close
sqlite3_backup* -> sqlite3_backup_finish
sqlite3_snapshot* -> sqlite3_snapshot_free
sqlite3_value*  -> sqlite3_value_free   (only ones from sqlite3_value_dup)
sqlite3_str*    -> sqlite3_str_finish (which also frees the buffer)
sqlite3_mutex*  -> sqlite3_mutex_free
```

**CLASS 7 — immortal / statically allocated.**
```
sqlite3_libversion   sqlite3_sourceid   sqlite3_errstr
sqlite3_compileoption_get   sqlite3_vfs_find
```

**CLASS 8 — the previous hook's pointer, returned by the setter.**
`sqlite3_commit_hook`, `_rollback_hook`, `_update_hook`, `_wal_hook`,
`_profile`, `_trace` all return the PREVIOUS `pArg`. Not memory to free;
a value to chain or discard.

**CLASS 9 — borrows the CALLER's buffer.** `pzTail` from every
`sqlite3_prepare*` points into the SQL string the caller passed. Its
lifetime is the Avra string's, and Avra's refcount governs it — this is
the one out-param whose answer must not be copied but INDEXED (a byte
offset into the original), which is also the form an Avra driver wants.

### 4.3 Where the copy goes, and what it costs

**THE RULE, one line, general and not sqlite's:** the extern wall answers
`ptr`. Avra text and bytes are minted from a `(ptr, len)` pair by ONE
core verb that allocates a headered box and `memcpy`s into it — the
`Bytes`/`string` constructor from a foreign buffer. Nothing else in the
tree may turn a foreign address into a `string`.

The copy sites, exhaustively, for the spine:

| site | when | cost |
|---|---|---|
| `column_text` + `column_bytes` → `string` | every TEXT cell read | one `box_alloc` + `memcpy` of n bytes |
| `column_blob` + `column_bytes` → `Bytes` | every BLOB cell read | same |
| `errmsg` → `string` | only on a non-OK result code | one small copy per error |
| `column_name` / `decltype` / origin names → `string` | ONCE per prepared statement, cached | n columns × one copy, amortized to zero across rows |
| `sqlite3_sql` / `expanded_sql` → `string` | diagnostics only | rare |
| `serialize` → `Bytes` | explicit | one copy of the whole database, then `sqlite3_free` |
| `blob_read` → `Bytes` | explicit | the caller sizes it |

**The cost is one allocation and one `memcpy` per TEXT/BLOB cell, and
nothing per INTEGER, REAL, or NULL cell.** That is the same cost every
memory-safe SQLite binding pays (Rust's `rusqlite`, Go's `mattn`, Python's
`sqlite3` all copy at exactly this boundary); it is not a tax Avra's
header model invents. Three consequences worth designing for:

1. **Integer/real columns cost ZERO copies.** A driver whose hot path
   reads `column_int64` and `column_double` allocates nothing per row.
   That is the P4 story, and it argues for making the typed accessors the
   primary API rather than a generic `Value` enum per cell.
2. **The header's `len` makes the copy exact.** `str_box`
   (`avra_runtime.c:264`) records the length, so a blob holding NUL
   survives — provided nothing downstream calls `strlen`. Which is
   BLOCKER B-2.
3. **The name/decltype copies are per-statement, not per-row.** Cache
   them at prepare time; a 10-column × 1M-row scan pays 10 copies, not
   10 million.

---

## 5. VENDORING FACTS

Verified 2026-09-05 by `curl -sI` against sqlite.org.

| item | value |
|---|---|
| current release | **3.53.4** |
| amalgamation URL | `https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip` |
| — size | **2 946 650 bytes** (2.81 MiB), `Last-Modified: Thu, 27 Aug 2026` |
| autoconf tarball | `https://www.sqlite.org/2026/sqlite-autoconf-3530400.tar.gz` |
| — size | **3 283 177 bytes** (3.13 MiB) |
| URL shape | `https://www.sqlite.org/<YYYY>/<file>` — the YEAR OF RELEASE, not the current year. `…/2025/sqlite-amalgamation-3530400.zip` returns 404; `…/2026/…` returns 200. |
| DOWNLOAD-FILENAME encoding | `X.Y.Z` → `(X*1000000 + Y*10000 + Z*100)`, zero-padded to 7 digits: 3.53.4 → `3530400` |
| `SQLITE_VERSION_NUMBER` encoding | **DIFFERENT, and they must not be confused:** `(X*1000000 + Y*1000 + Z)`. 3.53.4 → `3053004`, NOT `3530400`. Verified in the vendored `sqlite3.h`. The probe log's `sqlite3_libversion_number()` answering `3051000` on the system library is this encoding, and decodes to 3.51.0. |

What the zip contains, and what each file is:
- **`sqlite3.c`** — THE AMALGAMATION. All of SQLite (≈ 250k lines, ~9 MB)
  concatenated into one translation unit. Compiling it as one unit is
  what buys SQLite its 5–10% speed over a per-file build: the compiler
  sees every function and inlines across what would otherwise be file
  boundaries. This is the ONE file to vendor and the ONE file to compile.
- **`sqlite3.h`** — the public header; the declarations classified above.
  Vendored alongside `sqlite3.c` as the reference the Avra `extern fn`
  declarations are checked against BY HAND (Avra does not read C headers;
  the `extern fn` line is the contract, and this document is what keeps
  it honest).
- **`sqlite3ext.h`** — the loadable-extension interface (a struct of
  every API entry point). Not needed: the driver links statically.
- **`shell.c`** — the source of the `sqlite3` command-line tool. **Not
  vendored.** It is a separate program with its own dependencies
  (readline/linenoise); the driver needs none of it.

How the amalgamation is normally compiled — one command, no build
system:
```
cc -c -O2 <the flag set from §3.3> sqlite3.c -o sqlite3.o
```
It needs `-lm` (math functions) and `-lpthread` (when `THREADSAFE != 0`)
at LINK time, and nothing else. No configure, no headers to find, no
transitive dependencies.

**How it lands in this tree.** `avra.toml`'s `[link]` section already
does exactly this job for LLVM
(`packages/std-avrac/avra.toml`: `objects = ["../../build/llvm_wrapper.o"]`,
`flags = ["-L${LLVM_PREFIX}/lib", "-lLLVM"]`), and the manifest parser
accepts `objects` and `flags` under `link`
(`language/manifest.av:57`, `:109`). So `packages/std-sqlite/avra.toml`
is:
```toml
[link]
objects = ["../../build/sqlite3.o"]
flags   = ["-lm", "-lpthread"]
```
with a Makefile rule building `build/sqlite3.o` from the vendored
`sqlite3.c` — the same shape as `build/llvm_wrapper.o`. Note the tree's
existing law: a `[link]` row is an ARGV, never a shell line
(CLAUDE.md, "A COMMAND IS AN ARGV"), so no flag in that list is
interpreted by a shell.

Vendoring hygiene worth fixing in the plan, not litigating:
- Pin the exact version and its SHA3-256 (sqlite.org publishes both) in
  the manifest or a `VENDOR` note, so a re-download is verifiable.
- `sqlite3.c` is ~9 MB of C. It is not Avra source and must not be
  walked by `make idioms`, the gate, or any tool that globs the tree.
- **Compiling it once takes ~20–40 s at `-O2`.** Under the working
  discipline this is a foreground step under the watchdog, and it must be
  a Makefile target with a real dependency on the `.c` file so it runs
  ONCE, never per gate.

---

## BLOCKERS

Things fundamentally missing from the language, the stdlib or the
runtime, with a proposed shape for each. Ordered by the dependency order
the checklist should take.

### B-1 — NO OUT-PARAMS. Blocks `open_v2` and `prepare_v3`: nothing runs.

**The gap.** `extern fn f(p: string, out db: ptr)` is F0100 "expected
`)`" (ROADMAP.md:1567). The extern grammar
(`features/fns/mod.av:32`) takes `NAME ":" type` seats and nothing else.
24 functions are primary-bucket (c), including every door into the
library.

**Proposed shape — collapse the paradox (P6).** An out-param is not a
new parameter mode; it is a **second answer**. The C signature
`int sqlite3_open_v2(const char*, sqlite3**, int, const char*)` is, in
Avra, a fn of three arguments answering TWO values. Spell it:

```
extern fn sqlite3_open_v2(path: ptr, flags: int, vfs: ptr) -> (int, ptr) @out(2)
```

`@out(n)` says: seat n of the C signature is an out-param, filled by the
callee; the extern's Avra answer is a TUPLE of the C return followed by
the out seats in order. The compiler allocates the C storage (an `alloca`
of one word per out seat), passes its address, and reads it back after
the call.

Why this and not `out db: ptr`:
- It is the SAME machinery a multi-return `fn` needs (which the language
  wants anyway — the sugar backlog has asked for tuples since
  `enumerate`), so out-params cost the language ONE feature, not two.
- It keeps every extern seat a VALUE. Nothing in the type system learns
  about addresses; `ptr` stays opaque, and the "read wears the type of
  what is read" law is untouched.
- The five-out-param case (`sqlite3_table_column_metadata`) reads as
  `-> (int, ptr, ptr, int, int, int)` — ugly, and honestly so: the C
  signature IS ugly, and P7 says show it. A named wrapper in the driver
  gives it a shape.

Dependency: tuples (or a fixed multi-return) in the type system, the IR
and both engines. **This is the first slice and the whole campaign is
behind it.**

### B-2 — NO BYTES. A BLOB cannot round-trip; `string` equality lies.

**The gap.** ROADMAP.md:1558. `string` already holds arbitrary bytes with
an exact length in the header, but `avra_str_contains`, `_index_of`,
`_starts_with`, `_ends_with`, `_replace`, `_split` and `avra_streq` are C
string calls (`core/runtime_api.av:12`, `:52–61`), so a blob compares
equal to its own truncation at the first NUL. Second hazard, recorded and
confirmed: `str_len` (`avra_runtime.c:272–275`) falls back to `strlen`
when the header's `len` is 0, so an EMPTY value and an unrecorded length
are one value.

**Proposed shape.** A `Bytes` CORE VALUE CATEGORY (`core/types.av`'s
`Type` enum), not a library type. It is the same headered box `Str`
already is — same `KIND_STR` allocation, same `len`, same refcount — with
a different TYPE and therefore a different method table: `.length` reads
the header (no strlen), `==` is `memcmp` over both lengths, no
`contains`/`split`/`replace` at all in the first slice. `Bytes` and
`string` convert explicitly, and the conversion to `string` is the one
place UTF-8 validity is asserted (spec 9.15: `string` is always valid
UTF-8).

The spec's own answer is `b"…"` literals of type `List<u8>`
(FULL_SPEC.md:5570) and `byte` as a primitive (:4821). **That divergence
must be settled before code is written**: `List<u8>` costs one boxed
element per byte under today's array layout — unusable for a 100 MB
serialize. The proposal is a spec ASK: `Bytes` as the contiguous
representation, `b"…"` as its literal, `List<u8>` as a view. Record it in
the sugar backlog naming this document.

Also fix at the same time: `str_len`'s zero-means-measure fallback. Once
every producer records a length (lane A's work landed the header `len`),
the fallback is a correctness hole, not a compatibility shim.

### B-3 — NO FLOAT. A REAL column has no home.

**The gap.** ROADMAP.md:1548. `let x: float = 1.0` is F0100 pointing AT
the `.` — the LEXER has no float literal. `RtKind` is
`{ I64, Ptr, Void }` (`core/ir.av:217`), so the extern wall cannot even
DECLARE a `double` seat: `rt_kind_of` (`core/runtime_api.av:95–99`) maps
every non-void, non-pointer type to `I64`, and a `double` passed in an
integer register is silently the wrong value on every ABI.

**Scope, precisely measured: four functions.** `sqlite3_bind_double`,
`sqlite3_column_double`, `sqlite3_result_double`, `sqlite3_value_double`.
Two of them are on the spine. There is no way around them — SQLite's REAL
storage class has exactly one C door.

**Proposed shape.** The core event ROADMAP.md:1553 already scopes: lexer
float literal, `Type.Float` in `core/types.av`, the value protocol's
`float_of`, IR (`Bin` over floats — note the LLVM lowering is `fadd`/
`fcmp` ORDERED, not the signed integer predicates), `emit_ins`,
the interpreter's `Val`, and a runtime TEXT PROJECTION that round-trips.
Add one item that document does not name: **`RtKind` grows an `F64`
variant.** That is a CORE event under the vocabulary seam rule — `RtKind`
is DATA (a registry column), so it costs a variant plus the coercion in
`llvm.av`'s `rt_arg`/`call_rt_value` (`language/llvm.av:383–426`), not an
eight-consumer instruction.

`decimal` is a SEPARATE ask and must not ride this slice. The spec's
answer is `BigDecimal` in `@std/numbers` (FULL_SPEC.md:6301–6327), a
LIBRARY type, with `@std/money` above it — not a language primitive.
SQLite has no decimal storage class; a decimal column is TEXT or INTEGER
cents by convention. The campaign's decision to land `decimal`
(ROADMAP.md:1532) is a spec divergence and should be recorded as one: it
is the ORM's requirement, not the driver's, and it does not gate a single
extern in this document. **Confidence HIGH** that `float` blocks the
driver; **HIGH** that `decimal` does not.

### B-4 — THE DESTRUCTOR SENTINEL. 14 functions look like callbacks and are not.

**The gap.** Every text/blob `bind_*` and `result_*` takes
`void(*)(void*)` as its last argument. Classified (d) by signature, they
would appear to need trampolines — putting the ENTIRE binding family
behind spec 15.3 and the driver behind a feature it does not need.

**The finding.** In every driver use, that argument is one of two integer
sentinels: `SQLITE_STATIC` = `((sqlite3_destructor_type)0)` and
`SQLITE_TRANSIENT` = `((sqlite3_destructor_type)-1)`
(sqlite3.h:6354–6355). `SQLITE_TRANSIENT` tells SQLite to COPY the buffer
immediately — which is exactly what a driver handing across an Avra
string must ask for, because the Avra box's lifetime is not the
statement's.

**Proposed shape.** Declare the seat `ptr` and pass the sentinel from a
named fn:
```
fn sqlite_transient() -> ptr   // (ptr)(-1)
fn sqlite_static() -> ptr      // (ptr)0
```
This needs ONE small thing the language lacks: a way to mint a `ptr` from
an integer constant. Nothing else. **Effect: 14 of the 43 (d) functions —
the whole binding family and most of `result_*` — move from "needs
trampolines" to "callable today", and the driver's spine clears bucket
(d) entirely.** Only the 29 real callbacks remain, all OPTIONAL for a
first driver.

### B-5 — VARIADIC `sqlite3_config` / `sqlite3_db_config`.

**The gap.** `sqlite3_db_config(db, op, ...)` is how DQS is turned off,
foreign keys enabled, and defensive mode set. It is a hard REQUIREMENT
and Avra has no variadic extern.

**Proposed shape — refuse the variadic.** These four functions are not
genuinely variadic: they are a fixed, enumerated set of `(op, args)`
overloads. Declare ONE narrow extern per ARGUMENT SHAPE, all naming the
same C symbol:
```
extern fn sqlite3_db_config(db: ptr, op: int, v: int, unused: int) -> int
```
plus a second declaration for the `(int, int*)` shape once out-params
land (`SQLITE_DBCONFIG_*` ops that report back), and a third for
`(void*)`. This is legal C ABI on every platform Avra targets (the callee
reads only what its op code says it has) and it costs the language
NOTHING.

The one thing it needs is the ability for two `extern fn` declarations to
name the SAME symbol under different Avra names — today an extern's Avra
name IS its symbol (`extern_row_of`, `language/lower.av:52–56`, uses
`decls.symbol(d.id)`). Proposed: `extern fn db_config_int(...) =
"sqlite3_db_config"`, a symbol rename on the declaration. Small, general,
and it also answers "the C name collides with an Avra keyword".

`sqlite3_test_control` and the whole printf family stay UNBOUND. Record
that as a decision, not an omission.

### B-6 — NO OPAQUE TYPES, NO DROP; A FOREIGN POINTER CROSSES AS `ptr`.

**The gap.** ROADMAP.md:1571. `opaque type Db` is F0100. A `sqlite3*` is
a bare `ptr`: no type distinction from a `sqlite3_stmt*`, no `defer`-free
close, nothing stopping a use-after-close.

**What is NOT a gap, and must be recorded so the design does not
over-build.** A foreign pointer held as `ptr` is memory-SAFE today:
`is_managed` answers `.Ptr -> false` (`language/memory.av:42–43`), so no
retain and no release is ever emitted for it, and `hdr()`'s tag check
(`avra_runtime.c:68–72`) would refuse it even if one were. The problem is
TYPE SAFETY and LIFETIME, not corruption. That means the driver can be
written and tested against bare `ptr` handles while `opaque type` is
designed — the tests will pass and the leaks will be real, which is the
right order (a leak a test can measure is better than a feature built
without a user).

**Proposed shape.** Spec 15.5 as written:
`opaque type Db @free_with(sqlite3_close_v2)`. Eight types earn one
(Class 6, §4.2). The `@free_with` drop rides the SAME machinery `defer`
already has (`cx.leaving` / `cx.failing`, CLAUDE.md's defer law) — an
opaque value's scope exit emits a call to its named destructor, exactly
where a `defer` would. That is the cheapest possible landing: no new
memory model, no refcount on foreign pointers, one new statement kind and
one new scope obligation.

Open question the design must answer and this research cannot: what
happens when an opaque value is COPIED (assigned, put in a list, returned
twice). Spec 15.5 says "values can be borrowed, moved, stored in structs,
or returned — all the normal Avra memory semantics apply", which under
refcounting means the drop must be refcounted too — and a `sqlite3*`
cannot carry Avra's 16-byte header. The likely answer is a one-slot
managed BOX holding the foreign pointer (the box carries the header, the
pointer inside does not), which is exactly the shape a flat record's
nullable already takes. **Confidence MEDIUM** — flag for design, not
settled here.

### B-7 — THE INTERPRETER TRAPS ON EVERY EXTERN.

**The gap.** `interp.av:574`: ``"`${callee}` is extern — the evaluator
cannot host it; build natively"``. Every `@std/sqlite` binding would be
native-only, and every corpus program would have a trap where an answer
belongs — breaking the tree's eval == native law at exactly the moment
the driver needs it most.

**Why today's stdlib does not hit this.** Every extern in the tree is
ALSO a row in `rt_sigs()` with a named `RtHost` variant
(`core/runtime_api.av:10–90`) — `avra_proc_*`, `avra_io_*`,
`avra_now_ns` are all hosted by hand in the interpreter. `extern_row`
(`:103–105`) is the fallback for a package's own extern, and it sets
`host: RtHost.Unhosted`. So the current design scales by HAND-WRITING an
interpreter body per extern: 60+ hand-written arms for a sqlite driver,
which is the C shim the campaign forbade, wearing a different hat.

**A second, quieter defect this exposes.** `rt_owns(name)` answers
`rt_sig_of(name)?.owns_result ?? false` (`core/runtime_api.av:124–126`),
so an extern the registry does not know NEVER owns its result. Under
`managed_dst` (`language/memory.av:324`) its `.CallRt` destination earns
no release. Today that is harmless because every `string`-answering
extern is a registry row. The moment a package declares
`extern fn f(...) -> string` outside the registry, the answer leaks. The
`ptr`-answering wall proposed in §4.1 sidesteps it — but the hole should
be named and closed, not sidestepped.

**Proposed shape.** ROADMAP.md:1536's decision, made concrete: the
interpreter hosts ANY extern through `dlsym` plus a SMALL FIXED SET of
uniform ABI shapes. Because `RtKind` is `{I64, Ptr, Void}` (+ `F64` after
B-3), an extern's shape is fully described by
`(ret_kind, param_kinds)` — and after B-1 and B-3, `(ret_kind,
param_kinds, out_seats)`. The interpreter needs one C trampoline per
`(ret_kind, arity)` pair up to some arity N: `long call_i_p_p_i(void* f,
long, long, long)` and so on. With `RtKind` at four variants and arity
capped at, say, 9 (the widest sqlite call the driver binds is
`sqlite3_table_column_metadata` at 9), that is a bounded table generated
once. `RtHost` grows one variant — `Dlsym` — and `interp.av:567`'s
`.Unhosted` arm becomes the defect it says it is.

This is the item that makes eval == native hold for the FFI by
construction rather than by discipline, and it is the difference between
a driver the corpus can test and a driver only `avra build` can run.

### B-8 — `Result<void, E>` IS REFUSED.

Standing sugar-backlog item, F2019, ROADMAP.md:1597. A driver is almost
entirely verbs that only succeed or fail: `bind_*`, `reset`, `finalize`,
`close`, `exec`, every `result_*`. Today each must answer something it
wrote. Not a hard blocker — @std/io and @std/process already live with
it — but it will shape the driver's whole API surface, so it should land
before the API is frozen rather than after.

### B-9 — CALLBACK VTABLES ARE OUTSIDE SPEC 15.3.

Spec 15.3 designs a trampoline for ONE closure crossing to ONE C function
pointer. `sqlite3_create_module` (`const sqlite3_module*`, 20+ pointers),
`sqlite3_vfs_register` (`sqlite3_vfs*`, 20+), `sqlite3_config` with a
methods struct, and FTS5's `fts5_api` all need a STRUCT OF trampolines
whose lifetime is the registration's, not the call's. Nothing in the spec
covers it.

Consequence for the plan: virtual tables, custom VFSes, custom allocators
and custom FTS5 tokenizers are the LAST era, and the campaign should say
so explicitly rather than discover it. Everything else in the "full
surface" — including FTS5, JSON, math, R-Tree and geopoly as SQL — is
reachable without it (§1.25).

---

## CONFIDENCE LEDGER

| # | claim | how verified | confidence |
|---|---|---|---|
| 1 | Apple's SDK `sqlite3.h` is SQLite 3.51.0, source id `…dcaapl` (an Apple fork) | `grep -n SQLITE_VERSION sqlite3.h` → :155–157 | HIGH |
| 2 | It declares exactly 284 functions + 3 globals | awk join of every `^SQLITE_API` decl; 287 lines, 3 non-function | HIGH |
| 3 | 9 of them carry `SQLITE_DEPRECATED` | `grep -c SQLITE_DEPRECATED` on the joined decls | HIGH |
| 4 | Upstream 3.53.4 has 13 core entry points Apple's header lacks | `comm` of funclist.html names against the header's names | HIGH |
| 5 | The dylib exports 368 `sqlite3*` symbols, including session (49) and preupdate (6), and NOT `sqlite3_load_extension` / `sqlite3_unlock_notify` | `libsqlite3.tbd` symbol list, split and sorted | HIGH |
| 6 | Every function declared in Apple's header is exported by the dylib | `comm -13 exports names` → empty | HIGH |
| 7 | Apple's build sets `ENABLE_COLUMN_METADATA`, `ENABLE_SESSION`, `ENABLE_PREUPDATE_HOOK`, `OMIT_LOAD_EXTENSION`, `DQS=3`, `THREADSAFE=2` | `PRAGMA compile_options` on `/usr/bin/sqlite3` | HIGH for the flags corroborated by the export list (session, preupdate, load_extension, unlock_notify, snapshot, normalize, scanstatus, rtree, codec); **MEDIUM** for the rest — the CLI statically links its own copy (`otool -L` shows no `libsqlite3.dylib`) |
| 8 | ROADMAP.md:1526–1529's claim that Apple lacks COLUMN_METADATA / DESERIALIZE / SESSION is wrong | (7) + `sqlite3_serialize`/`_deserialize` declared and exported; DESERIALIZE default-on since 3.36 | HIGH |
| 9 | ABI bucket counts: a 173, b 4, c 24, d 43, e 11, f 5, g 24 | mechanical classification of the joined decls, hand-corrected for function-pointer `**` and for three input `char**` arrays | HIGH on b/e/f (small, hand-checked); HIGH on d; **MEDIUM** on the a/c/g split — bucket (g) membership is a judgement about which calls TRANSPORT bytes, and reasonable people would move `strnicmp`, `keyword_check` and the UTF-16 name accessors |
| 10 | No SQLite function takes or returns a struct by value | grep of every joined decl for a non-pointer struct type in a seat | HIGH |
| 11 | `SQLITE_STATIC` = 0 and `SQLITE_TRANSIENT` = -1, so 14 (d) functions need no trampoline | sqlite3.h:6353–6355 | HIGH |
| 12 | `column_text`/`_blob` pointers die on step/reset/finalize or a type conversion | sqlite3.h:5470–5505, quoted verbatim | HIGH |
| 13 | `errmsg` may be overwritten by any later SQLite call | sqlite3.h:4199–4202, quoted verbatim | HIGH |
| 14 | FTS5, JSON, math, geopoly and the R-Tree index have ZERO `sqlite3_*` entry points; FTS5's API is `fts5_api`, a struct of pointers reached via `bind_pointer("fts5_api_ptr")` | sqlite3.h:11614–11660, :11268; the name list contains no `sqlite3_fts5*` / `sqlite3_json*` | HIGH |
| 15 | Avra's `ptr` is unmanaged, so a foreign pointer crosses safely today | `language/memory.av:42–43` (`.Ptr … -> false`); `core/runtime_api.av:95–99` | HIGH |
| 16 | A foreign `const char*` crossing as `string` is unsafe but currently silent | `memory.av:31` (`.Str -> true`) emits a Release; `avra_runtime.c:68–72` `hdr()` returns NULL on a missing tag | HIGH |
| 17 | `RtKind` is `{ I64, Ptr, Void }` — the extern wall cannot declare a `double` seat | `core/ir.av:217`; `core/runtime_api.av:95–99` | HIGH |
| 18 | The interpreter traps on any extern not in `rt_sigs()`; `extern_row` sets `host: RtHost.Unhosted` | `language/interp.av:567`, `:574`; `core/runtime_api.av:103–105`; the test at `features/fns/tests/fns_test.av:17` | HIGH |
| 19 | An unregistered extern's `string` result is never released (`rt_owns` → false) | `core/runtime_api.av:124–126` + `language/memory.av:324` | HIGH — read, not run |
| 20 | `[link] objects` / `flags` in `avra.toml` is the vendoring hook, with LLVM as precedent | `language/manifest.av:57`, `:109`; `packages/std-avrac/avra.toml` | HIGH |
| 21 | Amalgamation 3.53.4, 2 946 650 bytes, at `https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip` | `curl -sI` → 200 with `Content-length`; the `/2025/` path → 404 | HIGH |
| 22 | sqlite.org's 12 recommended options and what each does | fetched `sqlite.org/compile.html` | HIGH |
| 23 | The recommended vendored flag set in §3.3 | ASSEMBLED here from (22) plus this document's surface requirements — **not verified by a build**, since no compile may run in this tree | **LOW on the exact list compiling clean; HIGH on each flag's individual meaning.** Every line must be proved by an actual `cc -c` before it is trusted |
| 24 | Copy cost at the boundary is one alloc + one memcpy per TEXT/BLOB cell, zero per INTEGER/REAL | derived from `avra_runtime.c:244` `box_alloc` and `:264` `str_box`; not measured | MEDIUM — the SHAPE is certain, the constant is not |
| 25 | Compiling `sqlite3.c` at `-O2` takes ~20–40 s | prior knowledge; **no compile was run** | **LOW** |
| 26 | The spec's answer for bytes is `b"…"` / `List<u8>` and for decimal is `@std/numbers.BigDecimal` — both diverge from the campaign's stated plan | FULL_SPEC.md:5570, :4821, :6301–6327 | HIGH on what the spec says; the divergence is a decision for the owner, not a finding |

**WEAKEST LINK: claim 23** — the recommended flag set is assembled from
documentation, not proved by a build. `SQLITE_ENABLE_SESSION` requires
`SQLITE_ENABLE_PREUPDATE_HOOK` (documented), `SQLITE_ENABLE_GEOPOLY`
requires `SQLITE_ENABLE_RTREE` (documented), and `SQLITE_OMIT_AUTOINIT`
changes runtime obligations. The first thing the checklist should do is
compile the amalgamation once with this exact list and assert every flag
back through `sqlite3_compileoption_used`.

**SECOND WEAKEST: claim 7's MEDIUM half** — `/usr/bin/sqlite3` links its
own static copy, so the option list is the CLI's, corroborated but not
proved to be the dylib's. It does not affect any decision: the campaign
vendors, and the corrected reasons in §3.2 stand on the export list
(claim 5), which IS the dylib.
