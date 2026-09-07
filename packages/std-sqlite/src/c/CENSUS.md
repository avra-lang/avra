# THE WALL'S ABI CENSUS — every `sqlite3_*` entry point, by the shape a binding must express

The wall (`src/c/`) declares SQLite's entry points by their own names. This
file says which of them a declaration can express today, which wait on a
named FFI capability, and which can never be declared at all. It is the
sequencing document: each class below names how many entry points one
capability buys.

Nothing here is inferred from a signature's appearance. Where a claim is
about behaviour it was RUN, and the output is quoted.

## How it was made

1. `vendor/sqlite3.h` preprocessed with the package's own flag set
   (`vendor/FLAGS.md`), so the surface is the one THIS build has:
   `clang -E -P $(the flags) vendor/sqlite3.h`.
2. The result parsed into `(name, return type, parameters)` — top-level
   declarations only, struct bodies and typedefs skipped.
3. Classified mechanically, then the false positives corrected BY HAND with
   the reason named at the correction (§4a).
4. Cross-checked against the object's own symbol table:
   `nm -gU build/sqlite3.o`.

The header and the object DISAGREE, and the object is the authority.

## 1. Three numbers, and the different question each one answers

A binding is bounded by the smallest.

| | | the question it answers |
|---|---:|---|
| `SQLITE_API` declarations in the header TEXT | 365 | what SQLite's API IS |
| entry points the header declares UNDER OUR FLAGS | **362** | what a declaration can name |
| `sqlite3_*` text symbols the object EXPORTS | **357** | what a declaration can LINK |

362 is this census's denominator and 357 is the wall's ceiling. The
three between 365 and 362 are `sqlite3_activate_cerod`
(`#ifdef SQLITE_ENABLE_CEROD`) and `sqlite3_mutex_held` /
`sqlite3_mutex_notheld` (`#ifndef NDEBUG`, and our flags carry
`-DNDEBUG=1`); none of the three is in the object either. §18.

The five between 362 and 357 are named here, because a binding to any of
them **compiles clean and fails at LINK** — demonstrated, not inferred.
`sqlite3_win32_set_directory` was declared in the wall and referenced
from one fn; `./avra check` accepted the declaration with no signal of
any kind, and the build answered:

```
Undefined symbols for architecture arm64:
  "_sqlite3_win32_set_directory", referenced from:
      _av_tests$2Ereaches_it in cases-640f92.o
ld: symbol(s) not found for architecture arm64
clang: error: linker command failed with exit code 1
avra: clang failed linking packages/std-sqlite/build/cases — exited with code 1
```

**That is what this failure looks like, so the next reader recognises
it.** The linker names the SYMBOL and the Avra fn that reached it, which
is enough to find the declaration; nothing earlier in the toolchain says
a word, because nothing earlier reads the object. A DECLARATION IS NOT
EVIDENCE THE SYMBOL EXISTS, and `nm` is the only step that knows.

The five:

```
sqlite3_win32_set_directory      sqlite3_win32_set_directory8
sqlite3_win32_set_directory16    (Windows only)
sqlite3_carray_bind              sqlite3_carray_bind_v2
                                 (needs SQLITE_ENABLE_CARRAY, which we do not set)
```

**THE HEADER IS NOT A STATEMENT OF WHAT THE LIBRARY EXPORTS.** It declares
`sqlite3_snapshot_get`, `sqlite3_unlock_notify` and the six
`sqlite3_column_*_name` functions unconditionally — the FLAG decides whether
a body is compiled, not whether a prototype is visible. Turn a flag off and
the declarations stay; the link breaks. The keeper for the wall is therefore
`nm`, not the header (§14).

Our flag set's own contribution, measured by preprocessing twice:

```
no flags at all      298 entry points
our flag set         362 entry points
  the flags ADD       66   (59 session/changeset, 6 preupdate, sqlite3_normalized_sql)
  the flags REMOVE     2   (sqlite3_mutex_held, sqlite3_mutex_notheld — `-DNDEBUG=1`)
```

Nine entry points carry `SQLITE_DEPRECATED`: `sqlite3_trace`,
`sqlite3_profile`, `sqlite3_aggregate_count`, `sqlite3_expired`,
`sqlite3_transfer_bindings`, `sqlite3_global_recover`,
`sqlite3_thread_cleanup`, `sqlite3_memory_alarm`, `sqlite3_soft_heap_limit`.
They vanish the day the build takes `SQLITE_OMIT_DEPRECATED`.

## 2. The classes

| | class | what a binding needs |
|---|---|---|
| **(a)** | integer/pointer arguments, integer/pointer/void return | nothing — declarable today |
| **(b)** | takes or returns a `double` | `float` |
| **(c)** | takes a FUNCTION POINTER | a trampoline (spec 15.3) |
| **(d)** | takes an OUT-PARAMETER | a `mut` seat on an `extern fn`, and a SIZED one (§11) |
| **(e)** | VARIADIC | refused at the declaration — §9 |
| **(f)** | needs a pointer SENTINEL | **BLOCKED ON THE MINT** — `SQLITE_STATIC` is `(void*)0` (`sqlite3.h:6429`) and reachable today; its contract (`:4946-4950`) outlives the statement, and `SQLITE_TRANSIENT` is `(void*)-1` (`:6430`) with no spelling. §10 |
| **(g)** | returns a narrow C `int` | sized integer types — a correctness gap, not an expressibility one |

(a)–(e) are EXCLUSIVE under the precedence `e > d > c > b > a`: a function is
counted once, in the class that blocks it hardest. (f) and (g) CROSS-CUT —
(f) is a subset of (c), and (g) rides on any class — so they are counted
separately and never summed with the others.

Three companion attributes the campaign needs and this letter set does not
carry: a BORROWED pointer return (58), a caller-supplied BUFFER (2), and an
OP-TYPED `void*` (6). §12.

## 3. The counts

**Exclusive, `e > d > c > b > a`, summing to 362:**

| class | count | share |
|---|---:|---:|
| (a) declarable today | **234** | 65% |
| (b) `double` | **5** | 1% |
| (c) function pointer | **56** | 15% |
| (d) out-parameter | **59** | 16% |
| (e) variadic | **8** | 2% |

**Touching — a function may need several, so these do NOT sum:**

| class | count |
|---|---:|
| (b) `double` | 6 |
| (c) function pointer | 63 |
| (d) out-parameter | 59 |
| (e) variadic | 8 |
| (f) pointer sentinel — **BLOCKED ON THE MINT**, §10 | 14 |
| (g) narrow `int` return | **226** |

## 4. What each capability buys

Cumulative, because the spine needs them in this order. Measured by
counting the functions whose every blocking class is served.

| capability | entry points bindable | gained |
|---|---:|---:|
| — nothing new — | **234** | |
| + out-parameters | **286** | +52 |
| + `float` | **291** | +5 — four of them the spine a driver touches to move a REAL in and out (`bind`/`column`/`value`/`result`), the fifth session-gated |
| + the pointer sentinel's named mint — the 14 are **BLOCKED ON THE MINT**, never on out-params (`sqlite3.h:6429`/`:4946-4950`/`:6430`, §10) | **305** | +14 |
| + trampolines | **354** | +49 |
| + variadic | *never* | 8 refused |

**THERE IS NO STEP BETWEEN 286 AND 291 AND THE ABSENCE IS DELIBERATE.**
`SQLITE_STATIC` is `(void*)0` (`sqlite3.h:6429`) so a `ptr?` seat already
reaches those 14 with nothing new — and its contract
(`sqlite3.h:4946-4950`) requires the bound object to outlive the
statement, while `SQLITE_TRANSIENT`, which copies, is `(void*)-1`
(`sqlite3.h:6430`) and has no spelling. CALLABLE, NOT CORRECT.

A ladder counts CALLABILITY, and a reader who trusts a ladder schedules
its cheapest step first — so the step that costs nothing is the one that
must not appear on it. §10 has the contract in full.

**Out-parameters are the largest single unlock and the only one on the
critical path**: without them no connection and no statement exists, so
234 of the 234 "bindable today" functions have no handle to be called
with. That is the whole of the sequencing answer — out-params first, and
nothing else competes. **AND THEY ARE NOT SUFFICIENT ON THEIR OWN**: 19
of the 59 write through a narrow `int*` (Appendix A.2), so the seat must
carry the C WIDTH or those 19 answer 4294967295 for every negative.

### 4a. The hand corrections, named at the site

Mechanical classification put five functions in the wrong class. Each
correction and its reason:

| function | was | is | why |
|---|---|---|---|
| `sqlite3_free_table` | (d) | (a) | the `char**` is the array being FREED — an input |
| `sqlite3_drop_modules` | (d) | (a) | the `const char**` is the keep-list — an input |
| `sqlite3_create_filename` | (d) | (a) | the `const char**` is the parameter array — an input |
| `sqlite3_stmt_scanstatus` | (a) | (d) | `void *pOut` is written by the callee |
| `sqlite3_stmt_scanstatus_v2` | (a) | (d) | same |
| `sqlite3_file_control`, `sqlite3session_object_config`, `sqlite3session_config`, `sqlite3changegroup_config` | (a) | (d) | a `void*` the op code types, written back |

And in the other direction: a `void(*)(void*)` seat is only a SENTINEL when
the driver fills it with `SQLITE_STATIC`/`SQLITE_TRANSIENT`. `sqlite3_rollback_hook`,
`sqlite3_set_auxdata`, `sqlite3_create_function_v2` and eight others carry
that exact type as a REAL callback. Class (f) is therefore the
`sqlite3_bind_*` / `sqlite3_result_*` family alone — 14, listed in §10.

## 5. (a) — 234 entry points, declarable today

Every argument is an integer or a pointer; the answer is an integer, a
pointer or `void`. Nothing in the language is missing.

Their answers split:

| answer | count | the note |
|---|---:|---|
| a narrow C `int` | 124 | class (g) rides on all of them — §11 |
| `void` | 36 | |
| a pointer (`const char*`, `void*`, a handle) | 61 | 50 of them are text- or bytes-shaped — §12 |
| `sqlite3_int64` / `sqlite3_uint64` | 13 | exact: Avra's `int` IS i64 |

They are declarable and they are unreachable: 234 of them take a
`sqlite3*` or a `sqlite3_stmt*` and no such value exists until
out-parameters land. The class is a promise, not an inventory.

A `ptr` and a `ptr?` seat on an `extern fn` both accept, verified against
this lane's binary:

```
extern fn sqlite3_errmsg(db: ptr) -> string
extern fn sqlite3_column_int(stmt: ptr, col: int) -> int
extern fn sqlite3_finalize(stmt: ptr?) -> int
extern fn sqlite3_column_text(s: ptr, c: int) -> ptr?
  ./avra check -> clean
```

## 6. (b) — 6 entry points touch a `double`

`float` names no type (`F2001: 'float' names no type`, re-run on an
`extern fn` seat), so all six wait.

| entry point | signature |
|---|---|
| `sqlite3_bind_double` | `int (sqlite3_stmt*, int, double)` |
| `sqlite3_column_double` | `double (sqlite3_stmt*, int iCol)` |
| `sqlite3_result_double` | `void (sqlite3_context*, double)` |
| `sqlite3_rtree_geometry_callback` | `int (sqlite3 *db, const char *zGeom, int (*xGeom)(sqlite3_rtree_geometry*, int, sqlite3_rtree_dbl*,int*), void *pContext)` |
| `sqlite3_value_double` | `double (sqlite3_value*)` |
| `sqlite3changegroup_change_double` | `int (sqlite3_changegroup*, int, int, double)` |
**`float` UNBLOCKS FIVE, OF WHICH FOUR ARE THE SPINE A DRIVER TOUCHES TO
MOVE A REAL IN AND OUT — `bind_double`, `column_double`, `value_double`,
`result_double` — AND THE FIFTH IS SESSION-GATED**
(`sqlite3changegroup_change_double`). That is the sentence, not the
integer; the integer has been re-litigated twice. The sixth member of
the class, `sqlite3_rtree_geometry_callback`, TOUCHES `double` and is
NOT unblocked by `float`: it takes a function pointer and waits on a
trampoline too.

`bind_double` and `column_double` have no alternative door — they are
the only way a REAL column is written or read. `sqlite3_rtree_geometry_callback` touches the
class through its callback's `sqlite3_rtree_dbl*` seat, and
`sqlite3changegroup_change_double` arrived with 3.53's changegroup
builders.

That is the entire `double` footprint of the C API. **`float` gates the
REAL storage class and nothing else.**

## 7. (c) — 63 entry points take a function pointer

Fourteen are the destructor SENTINEL and never carry a real callback in
a driver. They are **BLOCKED ON THE MINT** — `SQLITE_STATIC` is
`(void*)0` (`sqlite3.h:6429`) so a `ptr?` seat already reaches it, and
its contract (`sqlite3.h:4946-4950`) requires the bound object to outlive
the statement; `SQLITE_TRANSIENT`, which copies, is `(void*)-1`
(`sqlite3.h:6430`) and has no spelling. CALLABLE, NOT CORRECT — §10.

The other **49 are real callbacks**, and the question a trampoline design
must answer for each is whether the C API carries a `void*` the closure's
environment can ride in.

**47 of the 49 do. Two do not, and cannot.**

```
sqlite3_auto_extension(void(*xEntryPoint)(void))
sqlite3_cancel_auto_extension(void(*xEntryPoint)(void))
```

Their callback takes NO parameters at all, so there is nowhere for an
environment to arrive — a closure is impossible in principle, and only a
bare fn is bindable. Both are OPTIONAL; nothing on the spine needs them.

For the other 47, spec 15.3's user-data convention fits the API as
written. The column below is the callback's OWN first seat: where it is
`void*`, the trampoline receives the environment directly.

| entry point | callback seats | a `void*` user-data seat | the callback's own first seat |
|---|---|---|---|
| `sqlite3_auto_extension` | 1 | **NO** | `void` |
| `sqlite3_autovacuum_pages` | 2 | yes | `void*`, `void*` |
| `sqlite3_busy_handler` | 1 | yes | `void*` |
| `sqlite3_cancel_auto_extension` | 1 | **NO** | `void` |
| `sqlite3_carray_bind` | 1 | yes | `void*` |
| `sqlite3_carray_bind_v2` | 1 | yes | `void*` |
| `sqlite3_collation_needed` | 1 | yes | `void*` |
| `sqlite3_collation_needed16` | 1 | yes | `void*` |
| `sqlite3_commit_hook` | 1 | yes | `void*` |
| `sqlite3_create_collation` | 1 | yes | `void*` |
| `sqlite3_create_collation16` | 1 | yes | `void*` |
| `sqlite3_create_collation_v2` | 2 | yes | `void*`, `void*` |
| `sqlite3_create_function` | 3 | yes | `sqlite3_context*`, `sqlite3_context*`, `sqlite3_context*` |
| `sqlite3_create_function16` | 3 | yes | `sqlite3_context*`, `sqlite3_context*`, `sqlite3_context*` |
| `sqlite3_create_function_v2` | 4 | yes | `sqlite3_context*`, `sqlite3_context*`, `sqlite3_context*`, `void*` |
| `sqlite3_create_module_v2` | 1 | yes | `void*` |
| `sqlite3_create_window_function` | 5 | yes | `sqlite3_context*`, `sqlite3_context*`, `sqlite3_context*`, `sqlite3_context*`, `void*` |
| `sqlite3_exec` | 1 | yes | `void*` |
| `sqlite3_memory_alarm` | 1 | yes | `void*` |
| `sqlite3_preupdate_hook` | 1 | yes | `void *pCtx` |
| `sqlite3_profile` | 1 | yes | `void*` |
| `sqlite3_progress_handler` | 1 | yes | `void*` |
| `sqlite3_rollback_hook` | 1 | yes | `void *` |
| `sqlite3_rtree_geometry_callback` | 1 | yes | `sqlite3_rtree_geometry*` |
| `sqlite3_rtree_query_callback` | 2 | yes | `sqlite3_rtree_query_info*`, `void*` |
| `sqlite3_set_authorizer` | 1 | yes | `void*` |
| `sqlite3_set_auxdata` | 1 | yes | `void*` |
| `sqlite3_set_clientdata` | 1 | yes | `void*` |
| `sqlite3_trace` | 1 | yes | `void*` |
| `sqlite3_trace_v2` | 1 | yes | `unsigned` |
| `sqlite3_unlock_notify` | 1 | yes | `void **apArg` |
| `sqlite3_update_hook` | 1 | yes | `void *` |
| `sqlite3_wal_hook` | 1 | yes | `void *` |
| `sqlite3changegroup_add_strm` | 1 | yes | `void *pIn` |
| `sqlite3changegroup_output_strm` | 1 | yes | `void *pOut` |
| `sqlite3changeset_apply` | 2 | yes | `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_apply_strm` | 3 | yes | `void *pIn`, `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_apply_v2` | 2 | yes | `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_apply_v2_strm` | 3 | yes | `void *pIn`, `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_apply_v3` | 2 | yes | `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_apply_v3_strm` | 3 | yes | `void *pIn`, `void *pCtx`, `void *pCtx` |
| `sqlite3changeset_concat_strm` | 3 | yes | `void *pIn`, `void *pIn`, `void *pOut` |
| `sqlite3changeset_invert_strm` | 2 | yes | `void *pIn`, `void *pOut` |
| `sqlite3changeset_start_strm` | 1 | yes | `void *pIn` |
| `sqlite3changeset_start_v2_strm` | 1 | yes | `void *pIn` |
| `sqlite3rebaser_rebase_strm` | 2 | yes | `void *pIn`, `void *pOut` |
| `sqlite3session_changeset_strm` | 1 | yes | `void *pOut` |
| `sqlite3session_patchset_strm` | 1 | yes | `void *pOut` |
| `sqlite3session_table_filter` | 1 | yes | `void *pCtx` |
Also in this class by nature though not by signature — the CALLBACK
VTABLES, which spec 15.3 does not cover: `sqlite3_create_module`/`_v2`
(a `sqlite3_module*`, 20+ pointers), `sqlite3_vfs_register`/`_find`
(`sqlite3_vfs*`), and `sqlite3_config`'s `SQLITE_CONFIG_MALLOC` /
`_PCACHE2` / `_MUTEX` method structs. A vtable is a struct of function
pointers, not a function pointer; it needs a different mechanism.

## 8. (d) — 59 entry points take an out-parameter

The blocker, and the whole of the critical path. An `extern fn` refuses a
`mut` seat today:

```
extern fn sqlite3_open(p: string, mut db: ptr) -> int
  error[F0100]: expected `)` while parsing `stmt`
  1 │ extern fn sqlite3_open(p: string, mut db: ptr) -> int
    ·                                   ┬
```

Four out KINDS, and the design must serve all four:

1. **handle out** — `T**` where T is opaque. `sqlite3**` (3),
   `sqlite3_stmt**` (6), `sqlite3_blob**`, `sqlite3_snapshot**`,
   `sqlite3_value**` (6), `sqlite3_session**`, `sqlite3_changeset_iter**`
   (4), `sqlite3_changegroup**`, `sqlite3_rebaser**`.
2. **scalar out** — `int*` / `sqlite3_int64*`. **These carry the narrow-int
   defect in the WRITE direction — §11 measures it.**
3. **borrowed-text out** — `const char**` pointing into memory the CALLER
   or sqlite owns: `pzTail` (6), `pzDataType`, `pzCollSeq`,
   `keyword_name`'s name, `changeset_op`'s `pzTab`.
4. **owned-text out** — `char**` the caller must `sqlite3_free`:
   `sqlite3_exec`'s `errmsg`, `sqlite3_get_table`'s `pzErrmsg`,
   `sqlite3_load_extension`'s `pzErrMsg`, `sqlite3session_diff`'s and
   the two `changegroup_change_*`'s `pzErr`.

And a fifth shape that is NOT a seat any declaration can type: the
OP-TYPED `void*`, where the op code decides what is written (§12).

| entry point | the out seats | also needs |
|---|---|---|
| `sqlite3_blob_open` | `sqlite3_blob **ppBlob` | — |
| `sqlite3_db_status` | `int *pCur`, `int *pHiwtr` | — |
| `sqlite3_db_status64` | `sqlite3_int64*`, `sqlite3_int64*` | — |
| `sqlite3_exec` | `char **errmsg` | c |
| `sqlite3_file_control` | `void* (op-typed)` | — |
| `sqlite3_get_table` | `char ***pazResult`, `int *pnRow`, `int *pnColumn`, `char **pzErrmsg` | — |
| `sqlite3_keyword_name` | `const char**`, `int*` | — |
| `sqlite3_load_extension` | `char **pzErrMsg` | — |
| `sqlite3_open` | `sqlite3 **ppDb` | — |
| `sqlite3_open16` | `sqlite3 **ppDb` | — |
| `sqlite3_open_v2` | `sqlite3 **ppDb` | — |
| `sqlite3_prepare` | `sqlite3_stmt **ppStmt`, `const char **pzTail` | — |
| `sqlite3_prepare16` | `sqlite3_stmt **ppStmt`, `const void **pzTail` | — |
| `sqlite3_prepare16_v2` | `sqlite3_stmt **ppStmt`, `const void **pzTail` | — |
| `sqlite3_prepare16_v3` | `sqlite3_stmt **ppStmt`, `const void **pzTail` | — |
| `sqlite3_prepare_v2` | `sqlite3_stmt **ppStmt`, `const char **pzTail` | — |
| `sqlite3_prepare_v3` | `sqlite3_stmt **ppStmt`, `const char **pzTail` | — |
| `sqlite3_preupdate_new` | `sqlite3_value **` | — |
| `sqlite3_preupdate_old` | `sqlite3_value **` | — |
| `sqlite3_serialize` | `sqlite3_int64 *piSize` | — |
| `sqlite3_snapshot_get` | `sqlite3_snapshot **ppSnapshot` | — |
| `sqlite3_status` | `int *pCurrent`, `int *pHighwater` | — |
| `sqlite3_status64` | `sqlite3_int64 *pCurrent`, `sqlite3_int64 *pHighwater` | — |
| `sqlite3_stmt_scanstatus` | `void* (op-typed)` | — |
| `sqlite3_stmt_scanstatus_v2` | `void* (op-typed)` | — |
| `sqlite3_table_column_metadata` | `char const **pzDataType`, `char const **pzCollSeq`, `int *pNotNull`, `int *pPrimaryKey`, `int *pAutoinc` | — |
| `sqlite3_vtab_in_first` | `sqlite3_value **ppOut` | — |
| `sqlite3_vtab_in_next` | `sqlite3_value **ppOut` | — |
| `sqlite3_vtab_rhs_value` | `sqlite3_value **ppVal` | — |
| `sqlite3_wal_checkpoint_v2` | `int *pnLog`, `int *pnCkpt` | — |
| `sqlite3changegroup_change_begin` | `char **pzErr` | — |
| `sqlite3changegroup_change_finish` | `char **pzErr` | — |
| `sqlite3changegroup_config` | `void* (op-typed)` | — |
| `sqlite3changegroup_new` | `sqlite3_changegroup **pp` | — |
| `sqlite3changegroup_output` | `int *pnData`, `void **ppData` | — |
| `sqlite3changeset_apply_v2` | `void **ppRebase`, `int *pnRebase` | c |
| `sqlite3changeset_apply_v2_strm` | `void **ppRebase`, `int *pnRebase` | c |
| `sqlite3changeset_apply_v3` | `void **ppRebase`, `int *pnRebase` | c |
| `sqlite3changeset_apply_v3_strm` | `void **ppRebase`, `int *pnRebase` | c |
| `sqlite3changeset_concat` | `int *pnOut`, `void **ppOut` | — |
| `sqlite3changeset_conflict` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_fk_conflicts` | `int *pnOut` | — |
| `sqlite3changeset_invert` | `int *pnOut`, `void **ppOut` | — |
| `sqlite3changeset_new` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_old` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_op` | `const char **pzTab`, `int *pnCol`, `int *pOp`, `int *pbIndirect` | — |
| `sqlite3changeset_pk` | `unsigned char **pabPK`, `int *pnCol` | — |
| `sqlite3changeset_start` | `sqlite3_changeset_iter **pp` | — |
| `sqlite3changeset_start_strm` | `sqlite3_changeset_iter **pp` | c |
| `sqlite3changeset_start_v2` | `sqlite3_changeset_iter **pp` | — |
| `sqlite3changeset_start_v2_strm` | `sqlite3_changeset_iter **pp` | c |
| `sqlite3rebaser_create` | `sqlite3_rebaser **ppNew` | — |
| `sqlite3rebaser_rebase` | `int *pnOut`, `void **ppOut` | — |
| `sqlite3session_changeset` | `int *pnChangeset`, `void **ppChangeset` | — |
| `sqlite3session_config` | `void* (op-typed)` | — |
| `sqlite3session_create` | `sqlite3_session **ppSession` | — |
| `sqlite3session_diff` | `char **pzErrMsg` | — |
| `sqlite3session_object_config` | `void* (op-typed)` | — |
| `sqlite3session_patchset` | `int *pnPatchset`, `void **ppPatchset` | — |
## 9. (e) — 8 entry points are variadic, and the declaration must REFUSE them

| entry point | signature |
|---|---|
| `sqlite3_config` | `int (int, ...)` |
| `sqlite3_db_config` | `int (sqlite3*, int op, ...)` |
| `sqlite3_log` | `void (int iErrCode, const char *zFormat, ...)` |
| `sqlite3_mprintf` | `char * (const char*, ...)` |
| `sqlite3_snprintf` | `char * (int, char*, const char*, ...)` |
| `sqlite3_str_appendf` | `void (sqlite3_str*, const char *zFormat, ...)` |
| `sqlite3_test_control` | `int (int op, ...)` |
| `sqlite3_vtab_config` | `int (sqlite3*, int op, ...)` |
Plus three that take a `va_list` rather than `...` — `sqlite3_vmprintf`,
`sqlite3_vsnprintf`, `sqlite3_str_vappendf`. Their ABI is ordinary (a
`va_list` is one pointer on this target) and they are still unreachable:
Avra has no way to BUILD a `va_list`.

### THE MEASUREMENT THAT DECIDES THE DESIGN

The api_surface report (B-5) proposes reaching `sqlite3_db_config` — how
DQS is turned off, foreign keys enabled and defensive mode set — by
declaring one narrow FIXED-ARITY extern per argument shape against the
same C symbol, and states:

> This is legal C ABI on every platform Avra targets (the callee reads
> only what its op code says it has) and it costs the language NOTHING.

**That is measured wrong on `arm64-apple-darwin25.5.0`.** Against the real
vendored symbol, two translation units, the only difference the
declaration:

```
$ cat vasq2.c
int sqlite3_test_control(int op, int x);          /* fixed arity */
  ... printf("%d", sqlite3_test_control(13, 12345));
$ cat vasq3.c
int sqlite3_test_control(int op, ...);            /* honest */
  ... printf("%d", sqlite3_test_control(13, 12345));

$ clang -O2 vasq2.c build/sqlite3.o && ./a.out
fixed    sqlite3_test_control(ALWAYS, 12345) -> -298729216
$ clang -O2 vasq3.c build/sqlite3.o && ./a.out
variadic sqlite3_test_control(ALWAYS, 12345) -> 12345
```

`SQLITE_TESTCTRL_ALWAYS` is `int x = va_arg(ap,int); return x`
(`vendor/sqlite3.c:191848`), so 12345 is the right answer and
-298729216 is a stack slot nobody wrote. The emitted calls say why:

```
fixed      mov  w1, #12345          ; the argument goes in a REGISTER
           bl   _sqlite3_test_control
variadic   mov  w8, #12345
           str  x8, [sp]            ; the argument goes on the STACK
           bl   _sqlite3_test_control
```

On Apple's arm64 ABI a variadic callee reads its varargs from the stack.
A fixed-arity declaration puts them in registers. The callee reads a slot
the caller never wrote — **a silent wrong answer, not a link error and
not a trap**, on the four calls that configure the connection's safety.

**THE CONSEQUENCE, AND IT IS PERMANENT.** Class (e) is not a "later": a
uniform trampoline puts an argument in a register and a variadic callee
reads it from the stack, so no uniform call can ever reach one. The
refusal belongs AT THE DECLARATION, by name — the "one narrow extern per
argument shape" workaround is off the table, and so is any declaration
that lies about arity. A variadic C function needs a declaration that
MARKS its variadic seats so the backend emits the stack ABI, or it stays
unbound. (Measured twice, independently: here against
`sqlite3_test_control`, and against the callee's own
`sub sp, …` / `ldr x0, [sp, …]` prologue.)

**What the refusal COSTS is §19**, which exists because the first thing
it broke was found by accident: a compile flag whose only runtime undo
is `sqlite3_config`. The eight are:
`sqlite3_config`, `sqlite3_db_config`, `sqlite3_vtab_config`,
`sqlite3_test_control` (the op-dispatch four, one of them REQUIRED by the
design) and `sqlite3_mprintf`, `sqlite3_snprintf`, `sqlite3_str_appendf`,
`sqlite3_log` (the printf family, all OPTIONAL and none of them wanted —
Avra has interpolation and a binding driver never builds SQL by
concatenation).

An earlier form of this measurement AGREED, and was wrong: with the
variadic prototype and the fixed one in the SAME translation unit, clang
resolves the second to the first and emits the honest call. The probe
above keeps them apart, which is the only way the question can be asked.

## 10. (f) — 14 entry points need a pointer sentinel, and the half that is REACHABLE is the unsafe half

The destructor seat of the bind/result family, where a driver passes
`SQLITE_STATIC` (`(void*)0`) or `SQLITE_TRANSIENT` (`(void*)-1`). All
fourteen are **BLOCKED ON THE MINT**, and on nothing else — out-params
do not reach them, because the one that is reachable is the one that is
not safe:

```
                    ── BLOCKED ON THE MINT ──
sqlite3_bind_blob     sqlite3_bind_blob64    sqlite3_bind_text
sqlite3_bind_text16   sqlite3_bind_text64    sqlite3_bind_pointer
sqlite3_result_blob   sqlite3_result_blob64  sqlite3_result_text
sqlite3_result_text16 sqlite3_result_text16be sqlite3_result_text16le
sqlite3_result_text64 sqlite3_result_pointer
```

Both sentinels are pointer values, and the header spells them so
(`sqlite3.h:6429-6430`):

```c
typedef void (*sqlite3_destructor_type)(void*);
#define SQLITE_STATIC      ((sqlite3_destructor_type)0)
#define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
```

**`SQLITE_STATIC` IS REACHABLE TODAY, AND IT IS THE ONE THAT IS NOT
SAFE.** A `ptr?` seat takes `null`, and the niche's absence IS the null
pointer, so the call emits `ptr null` — which is `SQLITE_STATIC`
exactly. Measured, this lane's binary:

```avra
extern fn sqlite3_bind_text(stmt: ptr, i: int, z: string, n: int, dtor: ptr?) -> int
fn bind_static(s: ptr) -> int { sqlite3_bind_text(s, 1, "hi", -1, null) }
```
```
$ ./avra emit p5.av
declare i64 @sqlite3_bind_text(ptr, i64, ptr, i64, ptr)
%1 = call i64 @sqlite3_bind_text(ptr %0, i64 1, ptr getelementptr ... , i64 -1, ptr null)
```

Declared non-nullable, the same `null` is refused with a voice —
`F2000: argument 5 of 'sqlite3_bind_text' wants 'ptr', found 'null'` — so
the seat's spelling is what carries the meaning, and it is `ptr?`.

**AND `SQLITE_STATIC` HANDS SQLITE A BORROW WITH NO END DATE.** The
header's contract, `sqlite3.h:4946-4950`, verbatim:

> ^ (2) The special constant, [SQLITE_STATIC], may be passed to indicate
> that the application remains responsible for disposing of the object.
> ^In this case, the object and the provided pointer to it must remain
> valid until either the prepared statement is finalized or the same SQL
> parameter is bound to something else, whichever occurs sooner.

An Avra box bound that way and released before the `step` is a
USE-AFTER-FREE INSIDE SQLITE, at a site with no relationship to the bind.
Nothing in the language enforces the lifetime: the guarantee would be
"the driver holds the box", which is a discipline and not a mechanism —
the same answer this tree already refused for the errcode frame, where
holding it depended on every future author knowing not to put a `defer`
nearby.

**`SQLITE_TRANSIENT` IS THE SAFE ONE — it COPIES before the bind returns,
and it is what every other binding reaches for by default. It has no
spelling at all.** There is no way to mint `(void*)-1`:

```
let p: ptr  = 0    error[F2024]: `p` declares `ptr`, this is `int`
let p: ptr? = 1    error[F2024]: `p` declares `ptr?`, this is `int`
```

**SO THE EASY CALL IS THE DANGEROUS ONE AND THE SAFE CALL CANNOT BE
WRITTEN, AND THAT INVERSION IS THE WHOLE FINDING.** These 14 are
CALLABLE, not CORRECT. The class is blocked on the named mint and the
lowering that guards it, and a STATIC-only bind is not a smaller version
of it — a hazard documented at a verb the caller can reach is a hazard
shipped.

Within the 14, the six `sqlite3_bind_*` are the ones the mint reaches
first: they need only a statement handle beside it. The eight
`sqlite3_result_*` need a `sqlite3_context*`, which arrives only inside a
callback, so they wait on trampolines whatever the mint does.

## 11. (g) — 226 entry points return a narrow C `int`, and the widening is a WRONG ANSWER

Avra's `int` is 64 bits and C's is 32. The extern seam declares `i64`
(`declare i64 @sqlite3_bind_text(ptr, i64, ptr, i64, ptr)`, emitted
above), and a C body answering `int` writes only the low half.

`tools/externs.py` measured this class over our OWN C on 2026-09-05 and
now fails the gate on it. It says, at its own head, that it cannot see a
third party's headers. **Here is the same measurement against the vendored
library**, the symbols declared exactly as an Avra `-> int` extern declares
them:

```
stricmp("a","b") as i64 = 4294967295  (0xffffffff)     C answers -1
stricmp("b","a") as i64 = 1                            C answers  1
strnicmp         as i64 = 4294967295                   C answers -1
a < 0 answers false
```

Five more, on a live connection, each provoked into its documented error
answer:

```
db_readonly("nosuchdb")   C=-1   as-Avra-int=4294967295
txn_state("nosuchschema") C=-1   as-Avra-int=4294967295
limit(id=999, -1)         C=-1   as-Avra-int=4294967295
error_offset (after a failed prepare)
                          C=-1   as-Avra-int=4294967295
```

**Six entry points MEASURED to ANSWER a negative, every one reading as
4294967295:** `sqlite3_stricmp`, `sqlite3_strnicmp`,
`sqlite3_db_readonly`, `sqlite3_txn_state`, `sqlite3_limit`,
`sqlite3_error_offset` — and a seventh, `sqlite3_wal_checkpoint_v2`,
WRITES -1 through its out seats (below). Two more are negative by documentation and were not provoked here
(they need a WAL snapshot and a preupdate hook respectively):
`sqlite3_snapshot_cmp` ("returns a negative value if P1 refers to an
older snapshot"), `sqlite3_preupdate_blobwrite` ("returns -1"). One is
negative only on overflow: `sqlite3_total_changes`, which is why
`sqlite3_total_changes64` exists.

`sqlite3_strlike` and `sqlite3_strglob` are NOT in the list, checked at
the source: both answer `patternCompare(...)`, which is 0/1/2
(`vendor/sqlite3.c:134824`). The face's `like`/`glob` compare `== 0` and
are exact.

### THE HALF NOBODY HAD WRITTEN DOWN: an `int*` OUT-PARAMETER HAS THE SAME DEFECT

An out-param design that hands C the address of an Avra `int` cell hands
it EIGHT bytes; C writes FOUR. Measured with a real SQLite out-param that
answers -1:

```
int64_t nLog = 0;
sqlite3_wal_checkpoint_v2(db, 0, 0, (int*)&nLog, (int*)&nCkpt);
  -> rc=0   slot-as-int32 = -1   slot-as-int64 = 4294967295
```

The cell was zeroed, so the upper half stayed clean and the answer is
merely wrong; an un-zeroed cell is worse, and on a big-endian target the
write lands in the wrong half entirely. **A `mut` seat on an `extern fn`
is not enough on its own — the seat must carry the C WIDTH**, or every
`int*` out-param in class (d) is wrong for negatives. That is one more
customer for the spec's sized integer types, and it is on the critical
path rather than beside it.

### THE ARGUMENT DIRECTION IS SAFE, AND THE SPINE DEPENDS ON IT

153 entry points take at least one narrow `int` parameter, and the
commonest argument in the whole API is `nByte = -1` ("read to the first
NUL"). An Avra i64 -1 truncates to a C int -1. Measured:

```
prepare_v2 with i64 nByte=-1 -> rc=0 (0 is OK)
```

Truncation is only wrong above 2³¹, which for `nByte` is a 2 GB SQL
string. The rule for the wall is one line: an `int` argument is exact up
to 2³¹, an `int` ANSWER is exact only where it cannot be negative, and
where it can, the wall's comment says so and the face asks it for equality
alone (`src/c/library.av` already carries that comment on
`sqlite3_stricmp` and `sqlite3_strnicmp`).

## 12. Three companion attributes the letters do not carry

**A BORROWED POINTER RETURN — 60 entry points.** 34 answer a
`const`-qualified `char*` / `void*` / `unsigned char*`, 26 answer an
unqualified one. Declaring any of them `-> string` is a defect even when
it appears to work: the runtime's `hdr` refuses an untagged pointer, so
retain and release no-op and `AVRA_RC_GUARD` is silent by construction —
a correct borrow and a use-after-free print identically clean. The wall
answers `ptr` and the face copies. (Established in the probe log §6; not
re-measured here.)

**A CALLER-SUPPLIED BUFFER — 2 entry points.** `sqlite3_randomness(int N,
void *P)` and `sqlite3_blob_read(sqlite3_blob*, void *Z, int N, int
iOffset)` fill memory the caller owns. That is not an out-parameter and a
`mut` seat does not serve it; it is a `Bytes` value with a length, and it
is the same gap `sqlite3_column_blob` names from the other side.

**AN OP-TYPED `void*` — 6 entry points.** `sqlite3_file_control`,
`sqlite3_stmt_scanstatus`, `sqlite3_stmt_scanstatus_v2`,
`sqlite3session_object_config`, `sqlite3session_config`,
`sqlite3changegroup_config`. The op code decides what the `void*` points
at — an `int*`, an `sqlite3_int64*`, a `const char**`, a methods struct.
No single declaration types the seat. With the four variadic op-dispatch
functions (§9) that is **10 entry points whose shape is a RUNTIME value**,
and they are one problem, not two.

**`sqlite3_uint64` — 10 seats, blocking nothing.** `sqlite3_malloc64`,
`sqlite3_realloc64`, `sqlite3_msize`, `sqlite3_bind_blob64`,
`sqlite3_bind_text64`, `sqlite3_bind_zeroblob64`, `sqlite3_result_blob64`,
`sqlite3_result_text64`, `sqlite3_result_zeroblob64`, `sqlite3_profile`
(DEP). Avra's `int` IS i64, so every `sqlite3_int64` seat is exact and only
the unsigned ones differ, and only above 2⁶³ — a blob of 9.2 exabytes.
Every one has a 32-bit or `sqlite3_int64` twin except `sqlite3_msize`,
which is optional. **No SQLite function takes or returns a struct by
value**, so this is the whole of the numeric-width question beyond §11.

## 13. The spine, and what blocks each step

The eleven calls every program makes, with the class that stops each:

| step | entry point | blocked by |
|---|---|---|
| open | `sqlite3_open_v2` | (d) out-param |
| prepare | `sqlite3_prepare_v3` | (d) out-param, plus `pzTail` |
| bind an integer | `sqlite3_bind_int64` | — |
| bind text | `sqlite3_bind_text` | (f) **BLOCKED ON THE MINT** — not on out-params; the reachable `SQLITE_STATIC` is the unsafe half (`sqlite3.h:4946-4950`, §10) |
| bind a real | `sqlite3_bind_double` | (b) `float` |
| step | `sqlite3_step` | — |
| the column's class | `sqlite3_column_type` | — |
| read an integer | `sqlite3_column_int64` | — |
| read a real | `sqlite3_column_double` | (b) `float` |
| read text | `sqlite3_column_text` | borrowed pointer + `Bytes` |
| read a blob | `sqlite3_column_blob` | `Bytes`, and NULL means three things |
| finalize / close | `sqlite3_finalize`, `sqlite3_close_v2` | — |
| the error | `sqlite3_errmsg`, `sqlite3_errcode`, `sqlite3_error_offset` | borrowed pointer; `error_offset` is (g)-negative |

Seven of the thirteen are already declarable. The spine is gated by
exactly three capabilities — out-parameters, `float`, `Bytes` — and
trampolines gate none of it.

## 14. The keeper this census asks for

The header declares 362 and the object exports 357. A wall that declares a
symbol the object does not have fails at LINK, with a message that names
neither the flag nor the entry point. The check is one line against the
object's own symbol table:

```
nm -gU build/sqlite3.o | awk '$2=="T"{print $3}' | sed 's/^_//' | grep '^sqlite3'
```

versus the `extern fn sqlite3_*` names in `src/c/`. It belongs with the
package's own native build (the Slice B recommendation), not in the root
Makefile.

## 15. Cross-check against the api_surface report

The report classified **284** functions; this census finds **362**. The two
are not in disagreement — they read DIFFERENT HEADERS, and running this
census's method over the report's header reproduces its numbers.

**The report's header, found and measured.** Apple's SDK ships SQLite
3.51.0 (`SQLITE_VERSION "3.51.0"`,
`$(xcrun --show-sdk-path)/usr/include/sqlite3.h`). Preprocessed with our
flag set and parsed by the same script: **284 entry points — the report's
number exactly.**

```
3.51.0 SDK header, our flags, our parser   284
3.53.4 vendored,   our flags, our parser   362
  of the 78:  59  the session/changeset family (Apple's header has ZERO)
              19  named below
  gone since 3.51.0: 0
```

The nineteen, by why they are here:

| | |
|---|---|
| platform-only, declared and not exported (§1) | `sqlite3_win32_set_directory`, `_8`, `_16` |
| needs a flag we do not set, declared and not exported | `sqlite3_carray_bind`, `_v2` |
| our `SQLITE_ENABLE_PREUPDATE_HOOK` | the six `sqlite3_preupdate_*` |
| absent from Apple's header, present in the vendored one | `sqlite3_unlock_notify`, `sqlite3_load_extension`, `sqlite3_enable_load_extension`, `sqlite3_str_free`, `sqlite3_str_truncate`, `sqlite3_hard_heap_limit64`, `sqlite3_db_status64`, `sqlite3_set_errmsg` |

That last row is the vendoring decision restated as a measurement: eight
entry points, `sqlite3_load_extension` among them, that a driver bound to
the host's SQLite could not have declared on this machine at all.

### The class counts, on the report's own denominator

The same 284, classified by this census's method:

| shape | the report | this method, same header | |
|---|---|---|---|
| function pointer | 43 | **43** | exact |
| destructor sentinel | 14 | **14** | exact |
| `double` | 4 primary, 5 touching | **4 exclusive, 5 touching** | exact |
| variadic | 11 | **8** literal `...` + 3 `va_list` | exact, split differently |
| out-parameter | 24 + 1 secondary = 25 | **26** | one addition |
| (a) | 173 | 204 | the report's precedence pulls its own (f) u64 and (g) bytes buckets — 29 functions — out of (a) first |

**The one addition is `sqlite3_file_control`**, which the report reads as
shape (a). Its fourth argument is a `void*` whose type the op code decides
and which the callee WRITES THROUGH
(`SQLITE_FCNTL_SIZE_LIMIT`, `_PERSIST_WAL`, `_LOCKSTATE`, … all report
back). It belongs with `sqlite3_stmt_scanstatus` and the three session
`*_config` functions in the op-typed group (§12). Every one of the
report's own 25 is in this census's set; nothing it counted is missing.

The report's three hand-corrected false positives — `sqlite3_free_table`,
`sqlite3_drop_modules`, `sqlite3_create_filename` — are the same three
this census excludes, reached independently and for the same reason (§4a).

### Where the report is measured WRONG

**B-5's fixed-arity workaround for the variadic op-dispatch four.** §9 has
the run, the two answers and the assembly. `sqlite3_db_config` is how DQS,
foreign keys and defensive mode get set; under that proposal the call
would answer from a stack slot nobody wrote.

**"the two rtree registrars" lack a user-data seat.** Both take one —
`sqlite3_rtree_geometry_callback(..., void *pContext)` and
`sqlite3_rtree_query_callback(..., void *pContext, void(*)(void*))`, in
the vendored header. The user data reaches their callback through the
`sqlite3_rtree_geometry` / `sqlite3_rtree_query_info` struct's own
`pContext` field rather than as a first argument, which is presumably what
was meant; as the question "can a closure be registered", the answer for
them is yes. **Exactly two entry points cannot carry a closure**, and it is
because their callback takes no arguments at all (§7).

## 16. The full table

Flags: `b` double · `c` function pointer · `d` out-parameter · `e` variadic ·
`f` pointer sentinel (**BLOCKED ON THE MINT**, §10) · `g` narrow `int` return · `*` op-typed `void*` ·
`B` caller-supplied buffer · `!` declared but NOT in the object ·
`D` `SQLITE_DEPRECATED`. `—` is class (a) with a wide answer.

| family | entry point | header | ret | classes |
|---|---|--:|---|---|
| Run-Time Library Version Numbers | `sqlite3_libversion` | 189 | `const char *` | — |
|  | `sqlite3_sourceid` | 190 | `const char *` | — |
|  | `sqlite3_libversion_number` | 191 | `int` | g |
| Run-Time Library Compilation Options Diagnostics | `sqlite3_compileoption_used` | 216 | `int` | g |
|  | `sqlite3_compileoption_get` | 217 | `const char *` | — |
| Test To See If The Library Is Threadsafe | `sqlite3_threadsafe` | 259 | `int` | g |
| Closing A Database Connection | `sqlite3_close` | 356 | `int` | g |
|  | `sqlite3_close_v2` | 357 | `int` | g |
| One-Step Query Execution Interface | `sqlite3_exec` | 430 | `int` | cdg |
| Initialize The SQLite Library | `sqlite3_initialize` | 1689 | `int` | g |
|  | `sqlite3_shutdown` | 1690 | `int` | g |
|  | `sqlite3_os_init` | 1691 | `int` | g |
|  | `sqlite3_os_end` | 1692 | `int` | g |
| Configuring The SQLite Library | `sqlite3_config` | 1729 | `int` | eg |
| Configure database connections | `sqlite3_db_config` | 1748 | `int` | eg |
| Enable Or Disable Extended Result Codes | `sqlite3_extended_result_codes` | 2733 | `int` | g |
| Last Insert Rowid | `sqlite3_last_insert_rowid` | 2795 | `sqlite3_int64` | — |
| Set the Last Insert Rowid value. | `sqlite3_set_last_insert_rowid` | 2805 | `void` | — |
| Count The Number Of Rows Modified | `sqlite3_changes` | 2870 | `int` | g |
|  | `sqlite3_changes64` | 2871 | `sqlite3_int64` | — |
| Total Number Of Rows Modified | `sqlite3_total_changes` | 2912 | `int` | g |
|  | `sqlite3_total_changes64` | 2913 | `sqlite3_int64` | — |
| Interrupt A Long-Running Query | `sqlite3_interrupt` | 2954 | `void` | — |
|  | `sqlite3_is_interrupted` | 2955 | `int` | g |
| Determine If An SQL Statement Is Complete | `sqlite3_complete` | 2990 | `int` | g |
|  | `sqlite3_complete16` | 2991 | `int` | g |
| Register A Callback To Handle SQLITE_BUSY Errors | `sqlite3_busy_handler` | 3052 | `int` | cg |
| Set A Busy Timeout | `sqlite3_busy_timeout` | 3075 | `int` | g |
| Set the Setlk Timeout | `sqlite3_setlk_timeout` | 3108 | `int` | g |
| Convenience Routines For Running Queries | `sqlite3_get_table` | 3188 | `int` | dg |
|  | `sqlite3_free_table` | 3196 | `void` | — |
| Formatted String Printing Functions | `sqlite3_mprintf` | 3238 | `char *` | e |
|  | `sqlite3_vmprintf` | 3239 | `char *` | — |
|  | `sqlite3_snprintf` | 3240 | `char *` | e |
|  | `sqlite3_vsnprintf` | 3241 | `char *` | — |
| Memory Allocation Subsystem | `sqlite3_malloc` | 3318 | `void *` | — |
|  | `sqlite3_malloc64` | 3319 | `void *` | — |
|  | `sqlite3_realloc` | 3320 | `void *` | — |
|  | `sqlite3_realloc64` | 3321 | `void *` | — |
|  | `sqlite3_free` | 3322 | `void` | — |
|  | `sqlite3_msize` | 3323 | `sqlite3_uint64` | — |
| Memory Allocator Statistics | `sqlite3_memory_used` | 3348 | `sqlite3_int64` | — |
|  | `sqlite3_memory_highwater` | 3349 | `sqlite3_int64` | — |
| Pseudo-Random Number Generator | `sqlite3_randomness` | 3372 | `void` | B |
| Compile-Time Authorization Callbacks | `sqlite3_set_authorizer` | 3463 | `int` | cg |
| Deprecated Tracing And Profiling Functions | `sqlite3_trace` | 3571 | `void *` | cD |
|  | `sqlite3_profile` | 3573 | `void *` | cD |
| SQL Trace Hook | `sqlite3_trace_v2` | 3664 | `int` | cg |
| Query Progress Callbacks | `sqlite3_progress_handler` | 3710 | `void` | c |
| Opening A New Database Connection | `sqlite3_open` | 3990 | `int` | dg |
|  | `sqlite3_open16` | 3994 | `int` | dg |
|  | `sqlite3_open_v2` | 3998 | `int` | dg |
| Obtain Values For URI Parameters | `sqlite3_uri_parameter` | 4071 | `const char *` | — |
|  | `sqlite3_uri_boolean` | 4072 | `int` | g |
|  | `sqlite3_uri_int64` | 4073 | `sqlite3_int64` | — |
|  | `sqlite3_uri_key` | 4074 | `const char *` | — |
| Translate filenames | `sqlite3_filename_database` | 4103 | `const char *` | — |
|  | `sqlite3_filename_journal` | 4104 | `const char *` | — |
|  | `sqlite3_filename_wal` | 4105 | `const char *` | — |
| Database File Corresponding To A Journal | `sqlite3_database_file_object` | 4124 | `sqlite3_file *` | — |
| Create and Destroy VFS Filenames | `sqlite3_create_filename` | 4171 | `sqlite3_filename` | — |
|  | `sqlite3_free_filename` | 4178 | `void` | — |
| Error Codes And Messages | `sqlite3_errcode` | 4244 | `int` | g |
|  | `sqlite3_extended_errcode` | 4245 | `int` | g |
|  | `sqlite3_errmsg` | 4246 | `const char *` | — |
|  | `sqlite3_errmsg16` | 4247 | `const void *` | — |
|  | `sqlite3_errstr` | 4248 | `const char *` | — |
|  | `sqlite3_error_offset` | 4249 | `int` | g |
| Set Error Code And Message | `sqlite3_set_errmsg` | 4277 | `int` | g |
| Run-time Limits | `sqlite3_limit` | 4345 | `int` | g |
| Compiling An SQL Statement | `sqlite3_prepare` | 4595 | `int` | dg |
|  | `sqlite3_prepare_v2` | 4602 | `int` | dg |
|  | `sqlite3_prepare_v3` | 4609 | `int` | dg |
|  | `sqlite3_prepare16` | 4617 | `int` | dg |
|  | `sqlite3_prepare16_v2` | 4624 | `int` | dg |
|  | `sqlite3_prepare16_v3` | 4631 | `int` | dg |
| Retrieving Statement SQL | `sqlite3_sql` | 4681 | `const char *` | — |
|  | `sqlite3_expanded_sql` | 4682 | `char *` | — |
|  | `sqlite3_normalized_sql` | 4684 | `const char *` | — |
| Determine If An SQL Statement Writes The Database | `sqlite3_stmt_readonly` | 4734 | `int` | g |
| Query The EXPLAIN Setting For A Prepared Statement | `sqlite3_stmt_isexplain` | 4746 | `int` | g |
| Change The EXPLAIN Setting For A Prepared Statement | `sqlite3_stmt_explain` | 4781 | `int` | g |
| Determine If A Prepared Statement Has Been Reset | `sqlite3_stmt_busy` | 4802 | `int` | g |
| Binding Values To Prepared Statements | `sqlite3_bind_blob` | 5009 | `int` | cfg |
|  | `sqlite3_bind_blob64` | 5010 | `int` | cfg |
|  | `sqlite3_bind_double` | 5012 | `int` | bg |
|  | `sqlite3_bind_int` | 5013 | `int` | g |
|  | `sqlite3_bind_int64` | 5014 | `int` | g |
|  | `sqlite3_bind_null` | 5015 | `int` | g |
|  | `sqlite3_bind_text` | 5016 | `int` | cfg |
|  | `sqlite3_bind_text16` | 5017 | `int` | cfg |
|  | `sqlite3_bind_text64` | 5018 | `int` | cfg |
|  | `sqlite3_bind_value` | 5020 | `int` | g |
|  | `sqlite3_bind_pointer` | 5021 | `int` | cfg |
|  | `sqlite3_bind_zeroblob` | 5022 | `int` | g |
|  | `sqlite3_bind_zeroblob64` | 5023 | `int` | g |
| Number Of SQL Parameters | `sqlite3_bind_parameter_count` | 5044 | `int` | g |
| Name Of A Host Parameter | `sqlite3_bind_parameter_name` | 5072 | `const char *` | — |
| Index Of A Parameter With A Given Name | `sqlite3_bind_parameter_index` | 5090 | `int` | g |
| Reset All Bindings On A Prepared Statement | `sqlite3_clear_bindings` | 5100 | `int` | g |
| Number Of Columns In A Result Set | `sqlite3_column_count` | 5116 | `int` | g |
| Column Names In A Result Set | `sqlite3_column_name` | 5145 | `const char *` | — |
|  | `sqlite3_column_name16` | 5146 | `const void *` | — |
| Source Of Data In A Query Result | `sqlite3_column_database_name` | 5190 | `const char *` | — |
|  | `sqlite3_column_database_name16` | 5191 | `const void *` | — |
|  | `sqlite3_column_table_name` | 5192 | `const char *` | — |
|  | `sqlite3_column_table_name16` | 5193 | `const void *` | — |
|  | `sqlite3_column_origin_name` | 5194 | `const char *` | — |
|  | `sqlite3_column_origin_name16` | 5195 | `const void *` | — |
| Declared Datatype Of A Query Result | `sqlite3_column_decltype` | 5227 | `const char *` | — |
|  | `sqlite3_column_decltype16` | 5228 | `const void *` | — |
| Evaluate An SQL Statement | `sqlite3_step` | 5312 | `int` | g |
| Number of columns in a result set | `sqlite3_data_count` | 5333 | `int` | g |
| Result Values From A Query | `sqlite3_column_blob` | 5580 | `const void *` | — |
|  | `sqlite3_column_double` | 5581 | `double` | b |
|  | `sqlite3_column_int` | 5582 | `int` | g |
|  | `sqlite3_column_int64` | 5583 | `sqlite3_int64` | — |
|  | `sqlite3_column_text` | 5584 | `const unsigned char *` | — |
|  | `sqlite3_column_text16` | 5585 | `const void *` | — |
|  | `sqlite3_column_value` | 5586 | `sqlite3_value *` | — |
|  | `sqlite3_column_bytes` | 5587 | `int` | g |
|  | `sqlite3_column_bytes16` | 5588 | `int` | g |
|  | `sqlite3_column_type` | 5589 | `int` | g |
| Destroy A Prepared Statement Object | `sqlite3_finalize` | 5617 | `int` | g |
| Reset A Prepared Statement Object | `sqlite3_reset` | 5656 | `int` | g |
| Create Or Redefine SQL Functions | `sqlite3_create_function` | 5782 | `int` | cg |
|  | `sqlite3_create_function16` | 5792 | `int` | cg |
|  | `sqlite3_create_function_v2` | 5802 | `int` | cg |
|  | `sqlite3_create_window_function` | 5813 | `int` | cg |
| Deprecated Functions | `sqlite3_aggregate_count` | 6003 | `int` | gD |
|  | `sqlite3_expired` | 6004 | `int` | gD |
|  | `sqlite3_transfer_bindings` | 6005 | `int` | gD |
|  | `sqlite3_global_recover` | 6006 | `int` | gD |
|  | `sqlite3_thread_cleanup` | 6007 | `void` | D |
|  | `sqlite3_memory_alarm` | 6008 | `int` | cgD |
| Obtaining SQL Values | `sqlite3_value_blob` | 6136 | `const void *` | — |
|  | `sqlite3_value_double` | 6137 | `double` | b |
|  | `sqlite3_value_int` | 6138 | `int` | g |
|  | `sqlite3_value_int64` | 6139 | `sqlite3_int64` | — |
|  | `sqlite3_value_pointer` | 6140 | `void *` | — |
|  | `sqlite3_value_text` | 6141 | `const unsigned char *` | — |
|  | `sqlite3_value_text16` | 6142 | `const void *` | — |
|  | `sqlite3_value_text16le` | 6143 | `const void *` | — |
|  | `sqlite3_value_text16be` | 6144 | `const void *` | — |
|  | `sqlite3_value_bytes` | 6145 | `int` | g |
|  | `sqlite3_value_bytes16` | 6146 | `int` | g |
|  | `sqlite3_value_type` | 6147 | `int` | g |
|  | `sqlite3_value_numeric_type` | 6148 | `int` | g |
|  | `sqlite3_value_nochange` | 6149 | `int` | g |
|  | `sqlite3_value_frombind` | 6150 | `int` | g |
| Report the internal text encoding state of an sqlite3_value object | `sqlite3_value_encoding` | 6173 | `int` | g |
| Finding The Subtype Of SQL Values | `sqlite3_value_subtype` | 6191 | `unsigned int` | g |
| Copy And Free SQL Values | `sqlite3_value_dup` | 6208 | `sqlite3_value *` | — |
|  | `sqlite3_value_free` | 6209 | `void` | — |
| Obtain Aggregate Function Context | `sqlite3_aggregate_context` | 6254 | `void *` | — |
| User Data For Functions | `sqlite3_user_data` | 6269 | `void *` | — |
| Database Connection For Functions | `sqlite3_context_db_handle` | 6281 | `sqlite3 *` | — |
| Function Auxiliary Data | `sqlite3_get_auxdata` | 6350 | `void *` | — |
|  | `sqlite3_set_auxdata` | 6351 | `void` | c |
| Database Connection Client Data | `sqlite3_get_clientdata` | 6411 | `void *` | — |
|  | `sqlite3_set_clientdata` | 6412 | `int` | cg |
| Setting The Result Of An SQL Function | `sqlite3_result_blob` | 6583 | `void` | cf |
|  | `sqlite3_result_blob64` | 6584 | `void` | cf |
|  | `sqlite3_result_double` | 6586 | `void` | b |
|  | `sqlite3_result_error` | 6587 | `void` | — |
|  | `sqlite3_result_error16` | 6588 | `void` | — |
|  | `sqlite3_result_error_toobig` | 6589 | `void` | — |
|  | `sqlite3_result_error_nomem` | 6590 | `void` | — |
|  | `sqlite3_result_error_code` | 6591 | `void` | — |
|  | `sqlite3_result_int` | 6592 | `void` | — |
|  | `sqlite3_result_int64` | 6593 | `void` | — |
|  | `sqlite3_result_null` | 6594 | `void` | — |
|  | `sqlite3_result_text` | 6595 | `void` | cf |
|  | `sqlite3_result_text64` | 6596 | `void` | cf |
|  | `sqlite3_result_text16` | 6598 | `void` | cf |
|  | `sqlite3_result_text16le` | 6599 | `void` | cf |
|  | `sqlite3_result_text16be` | 6600 | `void` | cf |
|  | `sqlite3_result_value` | 6601 | `void` | — |
|  | `sqlite3_result_pointer` | 6602 | `void` | cf |
|  | `sqlite3_result_zeroblob` | 6603 | `void` | — |
|  | `sqlite3_result_zeroblob64` | 6604 | `int` | g |
| Setting The Subtype Of An SQL Function | `sqlite3_result_subtype` | 6633 | `void` | — |
| Define New Collating Sequences | `sqlite3_create_collation` | 6716 | `int` | cg |
|  | `sqlite3_create_collation_v2` | 6723 | `int` | cg |
|  | `sqlite3_create_collation16` | 6731 | `int` | cg |
| Collation Needed Callbacks | `sqlite3_collation_needed` | 6766 | `int` | cg |
|  | `sqlite3_collation_needed16` | 6771 | `int` | cg |
| Suspend Execution For A Short Time | `sqlite3_sleep` | 6811 | `int` | g |
| Win32 Specific Interface | `sqlite3_win32_set_directory` | 6927 | `int` | g! |
|  | `sqlite3_win32_set_directory8` | 6931 | `int` | g! |
|  | `sqlite3_win32_set_directory16` | 6932 | `int` | g! |
| Test For Auto-Commit Mode | `sqlite3_get_autocommit` | 6965 | `int` | g |
| Find The Database Handle Of A Prepared Statement | `sqlite3_db_handle` | 6978 | `sqlite3 *` | — |
| Return The Schema Name For A Database Connection | `sqlite3_db_name` | 7000 | `const char *` | — |
| Return The Filename For A Database Connection | `sqlite3_db_filename` | 7032 | `sqlite3_filename` | — |
| Determine if a database is read-only | `sqlite3_db_readonly` | 7042 | `int` | g |
| Determine the transaction state of a database | `sqlite3_txn_state` | 7060 | `int` | g |
| Find the next prepared statement | `sqlite3_next_stmt` | 7109 | `sqlite3_stmt *` | — |
| Commit And Rollback Notification Callbacks | `sqlite3_commit_hook` | 7158 | `void *` | c |
|  | `sqlite3_rollback_hook` | 7159 | `void *` | c |
| Autovacuum Compaction Amount Callback | `sqlite3_autovacuum_pages` | 7219 | `int` | cg |
| Data Change Notification Callbacks | `sqlite3_update_hook` | 7284 | `void *` | c |
| Enable Or Disable Shared Pager Cache | `sqlite3_enable_shared_cache` | 7334 | `int` | g |
| Attempt To Free Heap Memory | `sqlite3_release_memory` | 7350 | `int` | g |
| Free Memory Used By A Database Connection | `sqlite3_db_release_memory` | 7364 | `int` | g |
| Impose A Limit On Heap Size | `sqlite3_soft_heap_limit64` | 7430 | `sqlite3_int64` | — |
|  | `sqlite3_hard_heap_limit64` | 7431 | `sqlite3_int64` | — |
| Deprecated Soft Heap Limit Interface | `sqlite3_soft_heap_limit` | 7442 | `void` | D |
| Extract Metadata About A Column Of A Table | `sqlite3_table_column_metadata` | 7514 | `int` | dg |
| Load An Extension | `sqlite3_load_extension` | 7570 | `int` | dg |
| Enable Or Disable Extension Loading | `sqlite3_enable_load_extension` | 7602 | `int` | g |
| Automatically Load Statically Linked Extensions | `sqlite3_auto_extension` | 7640 | `int` | cg |
| Cancel Automatic Extension Loading | `sqlite3_cancel_auto_extension` | 7652 | `int` | cg |
| Reset Automatic Extension Loading | `sqlite3_reset_auto_extension` | 7660 | `void` | — |
| Register A Virtual Table Implementation | `sqlite3_create_module` | 7963 | `int` | g |
|  | `sqlite3_create_module_v2` | 7969 | `int` | cg |
| Remove Unnecessary Virtual Table Implementations | `sqlite3_drop_modules` | 7989 | `int` | g |
| Declare The Schema Of A Virtual Table | `sqlite3_declare_vtab` | 8049 | `int` | g |
| Overload A Function For A Virtual Table | `sqlite3_overload_function` | 8068 | `int` | g |
| Open A BLOB For Incremental I/O | `sqlite3_blob_open` | 8167 | `int` | dg |
| Move a BLOB Handle to a New Row | `sqlite3_blob_reopen` | 8200 | `int` | g |
| Close A BLOB Handle | `sqlite3_blob_close` | 8223 | `int` | g |
| Return The Size Of An Open BLOB | `sqlite3_blob_bytes` | 8239 | `int` | g |
| Read Data From A BLOB Incrementally | `sqlite3_blob_read` | 8268 | `int` | gB |
| Write Data Into A BLOB Incrementally | `sqlite3_blob_write` | 8310 | `int` | g |
| Virtual File System Objects | `sqlite3_vfs_find` | 8341 | `sqlite3_vfs *` | — |
|  | `sqlite3_vfs_register` | 8342 | `int` | g |
|  | `sqlite3_vfs_unregister` | 8343 | `int` | g |
| Mutexes | `sqlite3_mutex_alloc` | 8454 | `sqlite3_mutex *` | — |
|  | `sqlite3_mutex_free` | 8455 | `void` | — |
|  | `sqlite3_mutex_enter` | 8456 | `void` | — |
|  | `sqlite3_mutex_try` | 8457 | `int` | g |
|  | `sqlite3_mutex_leave` | 8458 | `void` | — |
| Retrieve the mutex for a database connection | `sqlite3_db_mutex` | 8613 | `sqlite3_mutex *` | — |
| Low-Level Control Of Database Files | `sqlite3_file_control` | 8656 | `int` | dg* |
| Testing Interface | `sqlite3_test_control` | 8675 | `int` | eg |
| SQL Keyword Checking | `sqlite3_keyword_count` | 8774 | `int` | g |
|  | `sqlite3_keyword_name` | 8775 | `int` | dg |
|  | `sqlite3_keyword_check` | 8776 | `int` | g |
| Create A New Dynamic String Object | `sqlite3_str_new` | 8821 | `sqlite3_str *` | — |
| Finalize A Dynamic String | `sqlite3_str_finish` | 8840 | `char *` | — |
|  | `sqlite3_str_free` | 8841 | `void` | — |
| Add Content To A Dynamic String | `sqlite3_str_appendf` | 8879 | `void` | e |
|  | `sqlite3_str_vappendf` | 8880 | `void` | — |
|  | `sqlite3_str_append` | 8881 | `void` | — |
|  | `sqlite3_str_appendall` | 8882 | `void` | — |
|  | `sqlite3_str_appendchar` | 8883 | `void` | — |
|  | `sqlite3_str_reset` | 8884 | `void` | — |
|  | `sqlite3_str_truncate` | 8885 | `void` | — |
| Status Of A Dynamic String | `sqlite3_str_errcode` | 8916 | `int` | g |
|  | `sqlite3_str_length` | 8917 | `int` | g |
|  | `sqlite3_str_value` | 8918 | `char *` | — |
| SQLite Runtime Status | `sqlite3_status` | 8946 | `int` | dg |
|  | `sqlite3_status64` | 8947 | `int` | dg |
| Database Connection Status | `sqlite3_db_status` | 9064 | `int` | dg |
|  | `sqlite3_db_status64` | 9065 | `int` | dg |
| Prepared Statement Status | `sqlite3_stmt_status` | 9237 | `int` | g |
| Online Backup API. | `sqlite3_backup_init` | 9749 | `sqlite3_backup *` | — |
|  | `sqlite3_backup_step` | 9755 | `int` | g |
|  | `sqlite3_backup_finish` | 9756 | `int` | g |
|  | `sqlite3_backup_remaining` | 9757 | `int` | g |
|  | `sqlite3_backup_pagecount` | 9758 | `int` | g |
| Unlock Notification | `sqlite3_unlock_notify` | 9875 | `int` | cg |
| String Comparison | `sqlite3_stricmp` | 9890 | `int` | g |
|  | `sqlite3_strnicmp` | 9891 | `int` | g |
| String Globbing | `sqlite3_strglob` | 9908 | `int` | g |
| String LIKE Matching | `sqlite3_strlike` | 9931 | `int` | g |
| Error Logging Interface | `sqlite3_log` | 9954 | `void` | e |
| Write-Ahead Log Commit Hook | `sqlite3_wal_hook` | 10004 | `void *` | c |
| Configure an auto-checkpoint | `sqlite3_wal_autocheckpoint` | 10040 | `int` | g |
| Checkpoint a database | `sqlite3_wal_checkpoint` | 10062 | `int` | g |
|  | `sqlite3_wal_checkpoint_v2` | 10161 | `int` | dg |
| Virtual Table Interface Configuration | `sqlite3_vtab_config` | 10202 | `int` | eg |
| Determine The Virtual Table Conflict Policy | `sqlite3_vtab_on_conflict` | 10290 | `int` | g |
| Determine If Virtual Table Column Access Is For UPDATE | `sqlite3_vtab_nochange` | 10316 | `int` | g |
| Determine The Collation For a Virtual Table Constraint | `sqlite3_vtab_collation` | 10351 | `const char *` | — |
| Determine if a virtual table query is DISTINCT | `sqlite3_vtab_distinct` | 10446 | `int` | g |
| Identify and handle IN constraints in xBestIndex | `sqlite3_vtab_in` | 10519 | `int` | g |
| Find all elements on the right-hand side of an IN constraint. | `sqlite3_vtab_in_first` | 10566 | `int` | dg |
|  | `sqlite3_vtab_in_next` | 10567 | `int` | dg |
| Constraint values in xBestIndex() | `sqlite3_vtab_rhs_value` | 10609 | `int` | dg |
| Prepared Statement Scan Status | `sqlite3_stmt_scanstatus` | 10739 | `int` | dg* |
|  | `sqlite3_stmt_scanstatus_v2` | 10745 | `int` | dg* |
| Zero Scan-Status Counters | `sqlite3_stmt_scanstatus_reset` | 10768 | `void` | — |
| Flush caches to disk mid-transaction | `sqlite3_db_cacheflush` | 10801 | `int` | g |
| The pre-update hook. | `sqlite3_preupdate_hook` | 10900 | `void *` | c |
|  | `sqlite3_preupdate_old` | 10913 | `int` | dg |
|  | `sqlite3_preupdate_count` | 10914 | `int` | g |
|  | `sqlite3_preupdate_depth` | 10915 | `int` | g |
|  | `sqlite3_preupdate_new` | 10916 | `int` | dg |
|  | `sqlite3_preupdate_blobwrite` | 10917 | `int` | g |
| Low-level system error code | `sqlite3_system_errno` | 10931 | `int` | g |
| Record A Database Snapshot | `sqlite3_snapshot_get` | 11008 | `int` | dg |
| Start a read transaction on an historical snapshot | `sqlite3_snapshot_open` | 11057 | `int` | g |
| Destroy a snapshot | `sqlite3_snapshot_free` | 11074 | `void` | — |
| Compare the ages of two snapshot handles. | `sqlite3_snapshot_cmp` | 11101 | `int` | g |
| Recover snapshots from a wal file | `sqlite3_snapshot_recover` | 11129 | `int` | g |
| Serialize a database | `sqlite3_serialize` | 11175 | `unsigned char *` | d |
| Deserialize a database | `sqlite3_deserialize` | 11242 | `int` | g |
| Bind array values to the CARRAY table-valued function | `sqlite3_carray_bind_v2` | 11306 | `int` | cg! |
|  | `sqlite3_carray_bind` | 11315 | `int` | cg! |
| Datatypes for the CARRAY table-valued function | `sqlite3_rtree_geometry_callback` | 11411 | `int` | bcg |
|  | `sqlite3_rtree_query_callback` | 11437 | `int` | cg |
| Create A New Session Object | `sqlite3session_create` | 11550 | `int` | dg |
| Delete A Session Object | `sqlite3session_delete` | 11569 | `void` | — |
| Configure a Session Object | `sqlite3session_object_config` | 11580 | `int` | dg* |
| Enable Or Disable A Session Object | `sqlite3session_enable` | 11635 | `int` | g |
| Set Or Clear the Indirect Change Flag | `sqlite3session_indirect` | 11665 | `int` | g |
| Attach A Table To A Session Object | `sqlite3session_attach` | 11725 | `int` | g |
| Set a table filter on a Session Object. | `sqlite3session_table_filter` | 11740 | `void` | c |
| Generate A Changeset From A Session Object | `sqlite3session_changeset` | 11855 | `int` | dg |
| Return An Upper-limit For The Size Of The Changeset | `sqlite3session_changeset_size` | 11875 | `sqlite3_int64` | — |
| Load The Difference Between Tables Into A Session | `sqlite3session_diff` | 11935 | `int` | dg |
| Generate A Patchset From A Session Object | `sqlite3session_patchset` | 11972 | `int` | dg |
| Test if a changeset has recorded any changes. | `sqlite3session_isempty` | 11993 | `int` | g |
| Query for the amount of heap memory used by a session object. | `sqlite3session_memory_used` | 12001 | `sqlite3_int64` | — |
| Create An Iterator To Traverse A Changeset | `sqlite3changeset_start` | 12044 | `int` | dg |
|  | `sqlite3changeset_start_v2` | 12049 | `int` | dg |
| Advance A Changeset Iterator | `sqlite3changeset_next` | 12093 | `int` | g |
| Obtain The Current Operation From A Changeset Iterator | `sqlite3changeset_op` | 12127 | `int` | dg |
| Obtain The Primary Key Definition Of A Table | `sqlite3changeset_pk` | 12161 | `int` | dg |
| Obtain old.* Values From A Changeset Iterator | `sqlite3changeset_old` | 12192 | `int` | dg |
| Obtain new.* Values From A Changeset Iterator | `sqlite3changeset_new` | 12226 | `int` | dg |
| Obtain Conflicting Row Values From A Changeset Iterator | `sqlite3changeset_conflict` | 12254 | `int` | dg |
| Determine The Number Of Foreign Key Constraint Violations | `sqlite3changeset_fk_conflicts` | 12271 | `int` | dg |
| Finalize A Changeset Iterator | `sqlite3changeset_finalize` | 12307 | `int` | g |
| Invert A Changeset | `sqlite3changeset_invert` | 12337 | `int` | dg |
| Concatenate Two Changeset Objects | `sqlite3changeset_concat` | 12368 | `int` | dg |
| Create A New Changegroup Object | `sqlite3changegroup_new` | 12421 | `int` | dg |
| Add a Schema to a Changegroup | `sqlite3changegroup_schema` | 12453 | `int` | g |
| Add A Changeset To A Changegroup | `sqlite3changegroup_add` | 12536 | `int` | g |
| Add A Single Change To A Changegroup | `sqlite3changegroup_add_change` | 12555 | `int` | g |
| Obtain A Composite Changeset From A Changegroup | `sqlite3changegroup_output` | 12587 | `int` | dg |
| Delete A Changegroup Object | `sqlite3changegroup_delete` | 12597 | `void` | — |
| Apply A Changeset To A Database | `sqlite3changeset_apply` | 12769 | `int` | cg |
|  | `sqlite3changeset_apply_v2` | 12784 | `int` | cdg |
|  | `sqlite3changeset_apply_v3` | 12801 | `int` | cdg |
| Create a changeset rebaser object. | `sqlite3rebaser_create` | 13081 | `int` | dg |
| Configure a changeset rebaser object. | `sqlite3rebaser_configure` | 13092 | `int` | g |
| Rebase a changeset | `sqlite3rebaser_rebase` | 13111 | `int` | dg |
| Delete a changeset rebaser object. | `sqlite3rebaser_delete` | 13125 | `void` | — |
| Streaming Versions of API functions. | `sqlite3changeset_apply_strm` | 13217 | `int` | cg |
|  | `sqlite3changeset_apply_v2_strm` | 13232 | `int` | cdg |
|  | `sqlite3changeset_apply_v3_strm` | 13249 | `int` | cdg |
|  | `sqlite3changeset_concat_strm` | 13266 | `int` | cg |
|  | `sqlite3changeset_invert_strm` | 13274 | `int` | cg |
|  | `sqlite3changeset_start_strm` | 13280 | `int` | cdg |
|  | `sqlite3changeset_start_v2_strm` | 13285 | `int` | cdg |
|  | `sqlite3session_changeset_strm` | 13291 | `int` | cg |
|  | `sqlite3session_patchset_strm` | 13296 | `int` | cg |
|  | `sqlite3changegroup_add_strm` | 13301 | `int` | cg |
|  | `sqlite3changegroup_output_strm` | 13305 | `int` | cg |
|  | `sqlite3rebaser_rebase_strm` | 13309 | `int` | cg |
| Configure global parameters | `sqlite3session_config` | 13350 | `int` | dg* |
| Configure a changegroup object | `sqlite3changegroup_config` | 13364 | `int` | dg* |
| Begin adding a change to a changegroup | `sqlite3changegroup_change_begin` | 13438 | `int` | dg |
| Add a 64-bit integer to a changegroup | `sqlite3changegroup_change_int64` | 13477 | `int` | g |
| Add a NULL to a changegroup | `sqlite3changegroup_change_null` | 13491 | `int` | g |
| Add an double to a changegroup | `sqlite3changegroup_change_double` | 13500 | `int` | bg |
| Add a text value to a changegroup | `sqlite3changegroup_change_text` | 13512 | `int` | g |
| Add a blob to a changegroup | `sqlite3changegroup_change_blob` | 13524 | `int` | g |
| Finish adding one-at-at-time changes to a changegroup | `sqlite3changegroup_change_finish` | 13577 | `int` | dg |
## 17. Confidence ledger

| claim | how | confidence |
|---|---|---|
| 362 declared / 357 exported / the 5 named | preprocessed with the package's flags; `nm -gU build/sqlite3.o` | HIGH |
| the class counts | mechanical, then hand-corrected with each correction named in §4a | HIGH |
| a fixed-arity declaration of a variadic symbol is a silent wrong answer | run against the vendored library, two translation units, assembly quoted | HIGH |
| `null` in a `ptr?` extern seat emits `ptr null` = `SQLITE_STATIC` | `./avra emit`, output quoted | HIGH |
| `SQLITE_STATIC` binds a BORROW the language cannot bound, so the 14 are callable and not correct | the header's own contract, `sqlite3.h:4946-4950`, quoted | HIGH |
| no way to mint `(void*)-1` | `./avra check`, `F2024` quoted, two spellings | HIGH |
| six entry points answer a negative `int`, read as 4294967295 | run against the vendored library on a live connection | HIGH |
| an `int*` out-param written -1 reads as 4294967295 from an 8-byte cell | run; `wal_checkpoint_v2` on a non-WAL database | HIGH |
| `nByte = -1` truncates correctly | run; `prepare_v2` answered rc=0 | HIGH |
| `sqlite3_snapshot_cmp` and `sqlite3_preupdate_blobwrite` answer negatives | SQLite's documentation; NOT provoked here (one needs a WAL snapshot, the other a registered hook) | MEDIUM |
| the api_surface report's 284 is Apple's 3.51.0 SDK header | that header preprocessed with our flags and parsed by the same script: 284, and its class counts reproduce | HIGH |
| the borrowed-pointer hazard | probe log §6, not re-run here | HIGH (theirs) |
| `-DSQLITE_USE_URI=1` made a raw `file:` path a URI with no per-open way off | `open_v2` with the flag absent from the open flags answered rc=0 and `db_filename` with the prefix STRIPPED; after the flag was removed the same call answers rc=14, and rc=0 again with `SQLITE_OPEN_URI` asked for | HIGH |
| the 24 `db_config` options' values in our build, and which 5 a PRAGMA reaches | read back from a live connection with the query form, then re-read after each candidate PRAGMA — the mapping is discovered, not name-matched | HIGH |
| `sqlite3_enable_load_extension` is a non-variadic twin for one option | run; it moves `ENABLE_LOAD_EXTENSION` 0 -> 1 | HIGH |
| `ATTACH` creates and writes a new database file from plain SQL, and cannot be switched off | run; the file appeared on disk, and neither op has a pragma, a twin or a compile symbol | HIGH |
| `DEFENSIVE` blocks the `sqlite_schema` write and SILENTLY IGNORES two of its three documented protections | set from C, which can call the variadic; `journal_mode` read back `delete` and `schema_version` read back `1` after both were set | HIGH |
| `-DSQLITE_DQS=0` refuses a double-quoted identifier used as a literal | run; SQLite's own message quoted | HIGH |
| the 365/362/357 split, and that all three extra are absent from the object | the raw header text parsed for `SQLITE_API` and diffed against the flagged set; `nm` for each of the three | HIGH |
| `sqlite3changegroup_change_double` takes a real `double` | the declaration, `sqlite3.h:13500` | HIGH |
| `sqlite3_create_function` is not an out-parameter | the declaration, `sqlite3.h:5782` — the `**` is inside the callbacks' own signatures | HIGH |

## 18. Reconciliation against the first-cut census

A first cut was made independently, by a different method: `SQLITE_API`
declarations parsed out of the raw header TEXT, continuations joined,
comments stripped, deduplicated by name — no preprocessor. It found
**365** and six class counts. The two censuses agree on four classes
exactly, and the two places they differ are both resolved below in the
first cut's favour on one and against it on the other.

| class | first cut | this census | |
|---|---:|---:|---|
| total | 365 | 362 | three, named |
| (a) plain — no other class at all | 110 | **110** | exact |
| (c) function pointer | 63 | **63** | exact |
| (e) variadic | 8 | **8** | exact, and the same eight names |
| (g) narrow `int` return | 228 | 226 | the same three |
| (b) `double` | 5 | **6** touching, 5 exclusive | the doubted one is real |
| (d) out-parameter | 54 | **59** | five, itemised |

### The three that separate 365 from 362

Not a disagreement — a different question. The first cut counts what the
HEADER TEXT declares; this one counts what the header declares UNDER OUR
FLAGS. Exactly three functions separate them, and **none of the three is
in `build/sqlite3.o`** (`nm`, 0 occurrences each):

```
sqlite3_activate_cerod      #ifdef SQLITE_ENABLE_CEROD — a proprietary
                            extension this build does not carry
sqlite3_mutex_held          #ifndef NDEBUG — and our flag set carries
sqlite3_mutex_notheld       -DNDEBUG=1
```

**So there are THREE numbers and each answers a different question**, and
the right one depends on what is being asked:

| | | the question it answers |
|---|---:|---|
| header text | 365 | what SQLite's API IS |
| header under our flags | **362** | what a declaration can name |
| object's text symbols | **357** | what a declaration can LINK |

A binding is bounded by the smallest. The 5 between 362 and 357 are
§1's win32 and carray names; the 3 above never reach a declaration at
all. **362 is the census's denominator and 357 is the wall's ceiling.**

The same three explain (g) exactly: `sqlite3_mutex_held` and
`sqlite3_mutex_notheld` both return `int`, so 228 − 2 = **226**.
As a SHARE the first cut's reading holds and is if anything stronger:
226 of 362 is **62.4%**, and of the 357 that can actually be linked,
63.3%. The width defect is the dominant class by a wide margin, and
after the widths land it is a mechanical sweep — Appendix C is that
checklist.

### `sqlite3changegroup_change_double` is REAL, not a name collision

Doubted as a false positive from the name. It is not:

```
sqlite3.h:13500
SQLITE_API int sqlite3changegroup_change_double(sqlite3_changegroup*, int, int, double);
```

A genuine `double` parameter, in a changegroup builder new since 3.51.
So the count is **6 touching, 5 exclusive**, and what `float` unblocks
is five, not four: the four core verbs plus this one.
`sqlite3_rtree_geometry_callback` is the sixth and is NOT unblocked by
`float` alone — it takes a function pointer, so it waits on a trampoline
too. §6 has the table.

### `sqlite3_create_function` is NOT an out-parameter — the doubt was right

```
sqlite3.h:5782
SQLITE_API int sqlite3_create_function(
  sqlite3 *db, const char *zFunctionName, int nArg, int eTextRep, void *pApp,
  void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
  void (*xStep)(sqlite3_context*,int,sqlite3_value**),
  void (*xFinal)(sqlite3_context*)
);
```

Not one out-parameter. The `**` a `**`-detector finds is inside
`sqlite3_value**`, in the CALLBACKS' own signatures — this census
classes it `(c) (g)`, function pointer and narrow return. It is the same
false-positive family the api_surface report hand-corrected for
`sqlite3_free_table`, `sqlite3_drop_modules` and `sqlite3_create_filename`
(§4a), and the rule that catches all four is: a function-pointer
parameter's inner text is not the enclosing function's signature.

### The five that make 54 into 59

| | why |
|---|---|
| `sqlite3_file_control` | `void*` whose type the op decides, and the callee WRITES it (`SQLITE_FCNTL_SIZE_LIMIT`, `_LOCKSTATE`, … all report back) |
| `sqlite3_stmt_scanstatus` | `void *pOut` — "Result written here" (`sqlite3.h:10743`) |
| `sqlite3_stmt_scanstatus_v2` | the same |
| `sqlite3session_object_config` | `void *pArg`, in-out per op |
| `sqlite3session_config` | the same |
| `sqlite3changegroup_config` | the same |

That is six added and one removed (`sqlite3_create_function`), which is
54 − 1 + 6 = **59**. All six are the OP-TYPED shape, which no single
declaration can type: with the four variadic op-dispatch functions they
are **ten entry points whose argument shape is a RUNTIME value**, and
they are one problem, not two. Everything else in (d) the two censuses
found alike.


## 19. THE VARIADIC AUDIT — what the permanent refusal costs, measured

Class (e) is refused at the declaration forever (§9). This section asks
what that costs: **is a variadic the ONLY way to control something, and is
that something security- or correctness-shaped?** Whatever answers yes
must be settled at COMPILE TIME, in `vendor/FLAGS.md`, because there is
no runtime path back.

The audit found ONE flag change and, more usefully, the question's
missing second half.

### 19.1 The second half of the question

`SQLITE_CONFIG_URI` was found by accident, downstream of a flag choice
rather than by looking. Auditing the rest turned up the discriminator
that explains why it was the only one needing a compile-time fix:

> **Is the thing it controls VISIBLE AT THE DRIVER'S OWN DOOR?**

URI reinterpretation is not: a caller hands over a *path*, and whether
that path silently becomes a URI is decided inside `sqlite3_open_v2`
where no verb can see it. Nothing the driver can refuse distinguishes a
path from a path. **That is why it had to be closed at the boundary.**

Everything else the audit found is visible: a caller who wants
`PRAGMA writable_schema=ON`, or `ATTACH '/tmp/x.db'`, or a
double-quoted identifier, has WRITTEN it, in SQL the driver was handed.
A driver that wants those closed refuses them at its own door, where the
refusal can be scoped per verb and per caller — which a compile flag can
never be, because a compile flag has no caller.

So the rule is two-part, and the second part is what keeps the flag set
from growing without limit. **RATIFIED AS THE CAMPAIGN'S RULE:**

> **A compile flag has no caller and cannot change its mind; a door can
> refuse per-verb, per-caller, and say why.** Settle it at compile time
> only when it is variadic-only AND invisible at the door. Visible at
> the door → refuse at the door.

### 19.2 `sqlite3_db_config` — measured, not read

The 24 options were read back from a live connection
(`sqlite3_db_config(db, op, -1, &v)` queries without changing), then every
candidate PRAGMA was run against a fresh connection and the 24 re-read, so
the PRAGMA-to-option mapping is DISCOVERED rather than matched by name.

**Our build's actual defaults**, which is the first thing this audit is
for — a flag set is a claim until something reads it back:

```
ENABLE_FKEY 1   ENABLE_TRIGGER 1   ENABLE_VIEW 1   TRUSTED_SCHEMA 1
STMT_SCANSTATUS 1   ENABLE_ATTACH_CREATE 1   ENABLE_ATTACH_WRITE 1
ENABLE_COMMENTS 1   FP_DIGITS 17
DQS_DML 0   DQS_DDL 0   DEFENSIVE 0   WRITABLE_SCHEMA 0
ENABLE_LOAD_EXTENSION 0   ENABLE_FTS3_TOKENIZER 0   ENABLE_QPSG 0
NO_CKPT_ON_CLOSE 0   TRIGGER_EQP 0   RESET_DATABASE 0
LEGACY_ALTER_TABLE 0   LEGACY_FILE_FORMAT 0   REVERSE_SCANORDER 0
(MAINDBNAME and LOOKASIDE are not `int int*` ops and do not read back)
```

**FIVE of the 24 are reached by a PRAGMA**, measured by watching the
option move:

```
PRAGMA foreign_keys              = 0  MOVES ENABLE_FKEY         : 1 -> 0
PRAGMA legacy_alter_table        = 1  MOVES LEGACY_ALTER_TABLE  : 0 -> 1
PRAGMA reverse_unordered_selects = 1  MOVES REVERSE_SCANORDER   : 0 -> 1
PRAGMA trusted_schema            = 0  MOVES TRUSTED_SCHEMA      : 1 -> 0
PRAGMA writable_schema           = 1  MOVES WRITABLE_SCHEMA     : 0 -> 1
```

**ONE has a NON-VARIADIC TWIN**, which is the reduction in blast radius
worth having:

```
sqlite3_enable_load_extension(db, 1) MOVES ENABLE_LOAD_EXTENSION : 0 -> 1
```

`sqlite3_enable_load_extension` is an ordinary two-argument function —
class (a), bindable the day out-params give us a connection. The option
is not lost.

**The remaining 18 are reachable only through `sqlite3_db_config`.** Of
those, these have a COMPILE-TIME default, so they are settled in
`FLAGS.md` or by SQLite's own default:

| option | compile symbol | ours |
|---|---|---|
| `DQS_DML` / `DQS_DDL` | `SQLITE_DQS` | **`=0`, and both read back 0** |
| `ENABLE_FTS3_TOKENIZER` | `SQLITE_ENABLE_FTS3_TOKENIZER` | unset → 0 |
| `ENABLE_QPSG` | `SQLITE_ENABLE_QPSG` | unset → 0 |
| `LEGACY_FILE_FORMAT` | `SQLITE_DEFAULT_FILE_FORMAT<4` | unset → 0 |
| `STMT_SCANSTATUS` | `SQLITE_ENABLE_STMT_SCANSTATUS` | set → 1 |
| `DEFENSIVE` | `SQLITE_DEFAULT_DEFENSIVE` | unset → 0 — §19.3 |

And these have NO route of any kind — no pragma, no twin, no compile
symbol. They are seeded unconditionally at `sqlite3.c:190835-190841` and
`sqlite3_db_config` is their only setter:

```
ENABLE_ATTACH_CREATE  1     ENABLE_ATTACH_WRITE  1     ENABLE_COMMENTS  1
ENABLE_TRIGGER 1  ENABLE_VIEW 1  NO_CKPT_ON_CLOSE 0  TRIGGER_EQP 0
RESET_DATABASE 0  FP_DIGITS 17  MAINDBNAME  LOOKASIDE
```

**`ENABLE_ATTACH_CREATE` and `ENABLE_ATTACH_WRITE` ARE A DECLARED
PROPERTY OF THIS PACKAGE, NOT A GAP IN IT.** They cannot be closed by us
at all, so the honest thing is to state the boundary rather than imply a
fix is pending — P9: a boundary is a contract.

> **A PROGRAM THAT HANDS `@std/sqlite` ARBITRARY SQL HAS HANDED IT THE
> FILESYSTEM.** `ATTACH` can create and write a database file anywhere
> the process can write, and no compile flag, pragma or bindable entry
> point can turn that off.

**THE DOOR IS `sqlite3_set_authorizer`, AND IT IS A REQUIREMENT ON THE
TRAMPOLINE RUNG — not a paragraph.** It refuses `SQLITE_ATTACH`
SEMANTICALLY, at prepare time, from the parser: it sees the STATEMENT,
never its spelling, so no comment trick, no case trick, and no false
positive on a string literal that happens to contain the word. It is
per-connection and it can say why, which is exactly what §19.1 asks of a
door. It is in class (c), so it arrives with trampolines — the right
rung rather than a stopgap.

**AND NOTHING IN THIS DRIVER TEXT-SCANS SQL, EVER.** Matching `ATTACH`
in text we do not parse is a blocklist on a language we cannot read —
`/*x*/ATTACH`, lowercase, a string literal containing the word — and it
refuses legitimate cross-database work besides. If statement-kind
filtering is ever wanted before the authorizer, it waits for the
compiler to parse SQL. A NAMED refusal is a policy; a regex over a
language we do not read is a guess.

**THE CAVEAT THAT KEEPS THIS IN PROPORTION.** Arbitrary SQL against a
fixed database was ALREADY a write primitive for that database;
`ATTACH` escalates it to the filesystem. Both are reasons the driver's
answer to untrusted input is BOUND PARAMETERS and never SQL filtering —
and the bind verb is precisely what is held until it can be written
safely (§10). Measured, from plain
SQL on a default connection:

```
ATTACH '/tmp/avra-attach-probe.db' AS side   rc=0  ACCEPTED
CREATE TABLE side.made(x)                    rc=0  ACCEPTED
file created on disk: YES
```

SQL handed to this driver can create and write a new database file
anywhere the process can write, permanently, with no switch. It is
VISIBLE AT THE DOOR — an `ATTACH` statement is a statement — so by
§19.1 the answer is a refusal at the driver's own door, not a flag.
Recorded here so the next reader does not go looking for the flag.

### 19.3 `SQLITE_DEFAULT_DEFENSIVE` — measured, and RECOMMENDED AGAINST

`DEFENSIVE` is the one option that is security-shaped, variadic-only, and
DOES have a compile symbol — so it is the audit's real candidate. It was
measured by setting it from C, which can call the variadic even though
Avra cannot, so the cost of the flag is known without a second build.

The header lists three things it disables. **Two of the three are not
disabled — they are silently ignored**, on a FILE database:

```
DEFENSIVE = 0                                  DEFENSIVE = 1
UPDATE sqlite_schema SET sql='bogus'  ACCEPTED   rc=1 "table sqlite_master may not be modified"
PRAGMA journal_mode=OFF     -> reads back "off"  rc=0, reads back "delete"
PRAGMA schema_version=99    -> reads back 99     rc=0, reads back 1
```

So it converts two of its three headline protections into SILENT
NO-OPS — accepted, ignored, no diagnostic. That is the failing-half-is-
silent shape this campaign keeps finding, and it is why LAW P1 says the
driver CHECKS what a pragma answered rather than trusting the rc.

**The recommendation is NOT to set it**, on three grounds:

1. **It is irreversible in both directions.** No pragma, no twin, and the
   runtime switch is the variadic. Compiling it ON removes
   `journal_mode=OFF` and schema surgery from every caller forever, with
   no escape hatch — which P8 refuses.
2. **What it guards is visible at the door** (§19.1). A caller who wants
   `writable_schema` wrote it. The driver can refuse that where the
   refusal can name itself and be scoped; the flag cannot.
3. **It part-lies.** Two of three protections are silent no-ops, so
   "defensive is on" would be a weaker guarantee than it reads.

### 19.4 The other seven, briefly

| variadic | what it alone controls | non-variadic twin | verdict |
|---|---|---|---|
| `sqlite3_config` | process-wide setup | — | every op we want has a compile symbol: `MEMSTATUS`, `URI`, `THREADSAFE`, `MMAP_SIZE`, `COVERING_INDEX_SCAN`, `LOOKASIDE`, `STMTJRNL_SPILL`, `SORTERREF_SIZE`, `MEMDB_MAXSIZE`. The rest (`LOG`, `SQLLOG`, `MALLOC`, `PCACHE2`, `MUTEX`) are callbacks or vtables — class (c), gated by trampolines whatever we do about variadics |
| `sqlite3_db_config` | §19.2 | `sqlite3_enable_load_extension` for one op | 5 by pragma, 1 by twin, 18 only here — one flag candidate, recommended against |
| `sqlite3_vtab_config` | a virtual table's own options | — | **costs nothing.** The header restricts it to inside `xCreate`/`xConnect`, so it is already behind a trampoline; a driver with no virtual tables never reaches it |
| `sqlite3_test_control` | test hooks | — | not for production, by its own name |
| `sqlite3_log` | writes a line to the error log | — | the log SINK is `SQLITE_CONFIG_LOG`, a callback — class (c) already. Nothing extra is lost |
| `sqlite3_mprintf` | SQL built by concatenation | `sqlite3_vmprintf` | **do not bind.** Avra has interpolation and a binding driver never builds SQL by concatenation |
| `sqlite3_snprintf` | the same into a caller buffer | `sqlite3_vsnprintf` | the same |
| `sqlite3_str_appendf` | the same into a `sqlite3_str` | `sqlite3_str_vappendf` | the same |

**The three `va_list` twins are a different refusal, and worth keeping
distinct.** `sqlite3_vmprintf(const char*, va_list)` is ABI-ORDINARY —
on this target a `va_list` is one pointer, so the declaration is
expressible and the call would use the normal register convention. What
is missing is not a way to DECLARE them but a way to BUILD a `va_list`.
They are declarable-and-unusable, where the eight `...` functions are
undeclarable. Neither is wanted, but a future reader should not conflate
them.

### 19.5 The audit's whole output

**One flag change**, and it is the URI removal already ruled on. Nothing
else in the eight controls something that is both variadic-only and
invisible at the driver's door. `DQS`, the option that prompted the
audit, was already settled by `-DSQLITE_DQS=0` and reads back 0/0 —
measured, and it does the work:

```
select * from t where "nosuchcol" = "nosuchcol"
  rc=1  no such column: "nosuchcol" - should this be a string literal in single-quotes?
```


## 20. Two properties this census established, stated as claims rather than incidents

### 20.1 A CLOSED REGISTRY SURFACES DESIGN GAPS THAT PROSE REVIEW MISSED

The tree's doctrine already says a catch-all silently forgets the next
variant (`_ ->` over our own enums; F2040 counts the answering arms).
**This is that law read FORWARDS.** The absence of a catch-all makes an
unimplemented DECISION fail to COMPILE rather than fail to HAPPEN: a
defence the design never picked up has nowhere to be spoken, and the
compiler says so at the arm that does not exist.

The evidence is the driver's `Cause`, a registry of 22 variants with no
`_ ->` by construction. Writing the first tests against it named five
refusals with no arm:

| kind | the promise, and where it is made |
|---|---|
| `sqlite.rows_discarded` | **a real promise** — the design's §7, at `run`: *"A row-yielding statement is refused here, naming `all`."* |
| `sqlite.empty_path` | a research defence the design never picked up (T125) |
| `sqlite.uri_path` | a research defence the design never picked up (T130) |
| `sqlite.no_statement` | a research defence (T37), and it prescribes SKIP for a script verb — the arm belongs to the single-statement verb alone |
| `sqlite.many_statements` | no promise anywhere; the design's own completeness critic names it: *"multi-statement SQL missing from all three"* |

Only ONE of the five had a promise behind it. The other four are the
visible edge of a drop the design already diagnosed about itself —
*"No judge read the ten research reports against the designs"* — and the
registry is where it became visible, because a closed registry cannot
hold a decision nobody made.

That `Cause` may carry the driver's OWN refusal is already settled by the
enum: `Mismatch`, `NoColumn`, `OutOfRow`, `Unfilled` and `NotUtf8` are
five of its 22 and every one is the driver refusing the caller. And none
of the 22 covers the five above — `Defect` is explicitly *"never the
caller's mistake"*, `Syntax` cannot cover comment-only SQL (prepare
answers OK), and `CantOpen` cannot cover an empty path, because SQLite
SUCCEEDS on `""` and that is the whole trap.

### 20.2 A DOOR BUILT FROM NUL-LOSSY PRIMITIVES JUDGES A PREFIX

The campaign's string law USED TO SAY that `==`, `contains`,
`index_of`, `split` and `replace` were C string calls stopping at the
first NUL. **That is no longer true**: `f57372a` moved all five onto the
header's length, so nothing on the Avra side truncates. The law that
survives is sharper, because the truncation was only ever on ONE side:
**the callee sees a different string than the guard did, and the seam
where that happens is the extern seat and only there.**

`path_fault` was such a guard, and the red team walked the empty-path
trap straight through the door built to stop it:

```
path "\0x"      Avra's .length -> 2, so not empty; the door ACCEPTED it
                 SQLite's db_filename -> []   the EMPTY path
                 which is a private temporary database, deleted at close
path "/tmp/a.db\0/../../etc/x"   opened /private/tmp/a.db
                 a path the caller did not write, silently
```

The fix reads `char_code` over `0..s.length`, both of which see every
byte. **THE GENERAL RULE: a guard and the thing it guards must read the
same bytes.** Where a value crosses into C, the guard must judge what C
will see, or judge the whole and refuse anything C would truncate — this
driver does the latter, because a path whose meaning changes at the
boundary is not a path anyone meant to write.

### 20.3 A REFUSAL REACHES FORWARD, AND THE THING IT BREAKS IS FOUND DOWNSTREAM

`SQLITE_CONFIG_URI` was **found downstream of the variadic ruling, not by
auditing it** — the flag was chosen for its own reasons months from any
thought of variadics, and the ruling that made it irreversible was made
this morning without anyone checking what it reached. The coupling is
one sentence: *a compile-time decision we could not undo at runtime,
because the undo lives in the class that was ruled out.*

That is the argument for §19 existing at all. A capability refused is not
a hole in one place; it is a constraint on every decision whose escape
hatch happened to live there — and those decisions were made earlier, by
other people, for other reasons. **The audit belongs at the moment of the
refusal, not at the moment something breaks.**


---

# Appendix A — (d) THE 59, SPLIT BY OUT KIND

**Five different landings, not one.** A function appears in every section
whose seat it carries, so the sections sum past 59 — that is the point:
`sqlite3_prepare_v3` is in A.1 AND A.3 and needs both landings before it
is correct.

| section | out kind | functions |
|---|---|---:|
| A.1 | handle `T**` | 26 |
| A.2 | scalar `int*` / `sqlite3_int64*` | 22 |
| A.3 | borrowed text `const char**` | 9 |
| A.4 | OWNED text `char**` — caller frees | 17 |
| A.5 | op-typed `void*` | 6 |


## A.1 — HANDLE OUT, `T**` (26)

The landing is a POINTER the caller then owns. Every one is an
`opaque type` candidate, and every one is a value the language has a
shape for the day the seat exists — `ptr` rides a struct field today.

| entry point | the seat(s) | also needs |
|---|---|---|
| `sqlite3_blob_open` | `sqlite3_blob **ppBlob` | — |
| `sqlite3_open` | `sqlite3 **ppDb` | — |
| `sqlite3_open16` | `sqlite3 **ppDb` | — |
| `sqlite3_open_v2` | `sqlite3 **ppDb` | — |
| `sqlite3_prepare` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_prepare16` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_prepare16_v2` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_prepare16_v3` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_prepare_v2` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_prepare_v3` | `sqlite3_stmt **ppStmt` | — · also A.3 |
| `sqlite3_preupdate_new` | `sqlite3_value **` | — |
| `sqlite3_preupdate_old` | `sqlite3_value **` | — |
| `sqlite3_snapshot_get` | `sqlite3_snapshot **ppSnapshot` | — |
| `sqlite3_vtab_in_first` | `sqlite3_value **ppOut` | — |
| `sqlite3_vtab_in_next` | `sqlite3_value **ppOut` | — |
| `sqlite3_vtab_rhs_value` | `sqlite3_value **ppVal` | — |
| `sqlite3changegroup_new` | `sqlite3_changegroup **pp` | — |
| `sqlite3changeset_conflict` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_new` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_old` | `sqlite3_value **ppValue` | — |
| `sqlite3changeset_start` | `sqlite3_changeset_iter **pp` | — |
| `sqlite3changeset_start_strm` | `sqlite3_changeset_iter **pp` | (c) |
| `sqlite3changeset_start_v2` | `sqlite3_changeset_iter **pp` | — |
| `sqlite3changeset_start_v2_strm` | `sqlite3_changeset_iter **pp` | (c) |
| `sqlite3rebaser_create` | `sqlite3_rebaser **ppNew` | — |
| `sqlite3session_create` | `sqlite3_session **ppSession` | — |

## A.2 — SCALAR OUT, `int*` / `sqlite3_int64*` (22)

**A DIFFERENT LANDING FROM A.1, AND THE ONE THAT NEEDS MORE THAN THE
SEAT.** Hand C the address of an Avra `int` cell and you hand it eight
bytes; an `int*` seat writes four. Measured (§11):
`sqlite3_wal_checkpoint_v2` on a non-WAL database writes -1 and the
8-byte cell reads back **4294967295**. So these 22 need a seat that
carries the C WIDTH — a `mut` seat alone gives the wrong answer for
every negative.

**AND THE 22 SPLIT CLEANLY, WITH NO FUNCTION IN BOTH HALVES: 19 write
through a narrow `int*` and 3 through `sqlite3_int64*`.** The three —
`sqlite3_db_status64`, `sqlite3_status64`, `sqlite3_serialize` — are
exact at any width, because Avra's `int` IS i64. **The other 19 are the
live width bug**, and they are the checklist for the seat: three of them
(`sqlite3_wal_checkpoint_v2`, `sqlite3_table_column_metadata`,
`sqlite3_keyword_name`) are reached by the driver's own first slices.

| entry point | the seat(s) | also needs |
|---|---|---|
| `sqlite3_db_status` | `int *pCur`, `int *pHiwtr` | — |
| `sqlite3_db_status64` | `sqlite3_int64*`, `sqlite3_int64*` | — |
| `sqlite3_get_table` | `int *pnRow`, `int *pnColumn` | — · also A.4 |
| `sqlite3_keyword_name` | `int*` | — · also A.3 |
| `sqlite3_serialize` | `sqlite3_int64 *piSize` | — |
| `sqlite3_status` | `int *pCurrent`, `int *pHighwater` | — |
| `sqlite3_status64` | `sqlite3_int64 *pCurrent`, `sqlite3_int64 *pHighwater` | — |
| `sqlite3_table_column_metadata` | `int *pNotNull`, `int *pPrimaryKey`, `int *pAutoinc` | — · also A.3 |
| `sqlite3_wal_checkpoint_v2` | `int *pnLog`, `int *pnCkpt` | — |
| `sqlite3changegroup_output` | `int *pnData` | — · also A.4 |
| `sqlite3changeset_apply_v2` | `int *pnRebase` | (c) · also A.4 |
| `sqlite3changeset_apply_v2_strm` | `int *pnRebase` | (c) · also A.4 |
| `sqlite3changeset_apply_v3` | `int *pnRebase` | (c) · also A.4 |
| `sqlite3changeset_apply_v3_strm` | `int *pnRebase` | (c) · also A.4 |
| `sqlite3changeset_concat` | `int *pnOut` | — · also A.4 |
| `sqlite3changeset_fk_conflicts` | `int *pnOut` | — |
| `sqlite3changeset_invert` | `int *pnOut` | — · also A.4 |
| `sqlite3changeset_op` | `int *pnCol`, `int *pOp`, `int *pbIndirect` | — · also A.3 |
| `sqlite3changeset_pk` | `int *pnCol` | — · also A.4 |
| `sqlite3rebaser_rebase` | `int *pnOut` | — · also A.4 |
| `sqlite3session_changeset` | `int *pnChangeset` | — · also A.4 |
| `sqlite3session_patchset` | `int *pnPatchset` | — · also A.4 |

## A.3 — BORROWED TEXT OUT, `const char**` (9)

The landing is a LIFETIME, not a value: the pointer written points
into memory the CALLER or SQLite owns. Six of the nine are `pzTail`,
which points into the caller's own SQL buffer — a driver that ignores
it silently executes only the first statement of a script.

| entry point | the seat(s) | also needs |
|---|---|---|
| `sqlite3_keyword_name` | `const char**` | — · also A.2 |
| `sqlite3_prepare` | `const char **pzTail` | — · also A.1 |
| `sqlite3_prepare16` | `const void **pzTail` | — · also A.1 |
| `sqlite3_prepare16_v2` | `const void **pzTail` | — · also A.1 |
| `sqlite3_prepare16_v3` | `const void **pzTail` | — · also A.1 |
| `sqlite3_prepare_v2` | `const char **pzTail` | — · also A.1 |
| `sqlite3_prepare_v3` | `const char **pzTail` | — · also A.1 |
| `sqlite3_table_column_metadata` | `char const **pzDataType`, `char const **pzCollSeq` | — · also A.2 |
| `sqlite3changeset_op` | `const char **pzTab` | — · also A.2 |

## A.4 — OWNED TEXT OUT, `char**` the caller must free (17)

The landing is a DROP OBLIGATION: what is written must go back through
`sqlite3_free`. One member is its own shape and has no sibling in all
362 — `sqlite3_get_table`'s `char ***pazResult`, the only triple
pointer in the surface, freed by `sqlite3_free_table` and NOT by
`sqlite3_free`.

| entry point | the seat(s) | also needs |
|---|---|---|
| `sqlite3_exec` | `char **errmsg` | (c) |
| `sqlite3_get_table` | `char ***pazResult`, `char **pzErrmsg` | — · also A.2 |
| `sqlite3_load_extension` | `char **pzErrMsg` | — |
| `sqlite3changegroup_change_begin` | `char **pzErr` | — |
| `sqlite3changegroup_change_finish` | `char **pzErr` | — |
| `sqlite3changegroup_output` | `void **ppData` | — · also A.2 |
| `sqlite3changeset_apply_v2` | `void **ppRebase` | (c) · also A.2 |
| `sqlite3changeset_apply_v2_strm` | `void **ppRebase` | (c) · also A.2 |
| `sqlite3changeset_apply_v3` | `void **ppRebase` | (c) · also A.2 |
| `sqlite3changeset_apply_v3_strm` | `void **ppRebase` | (c) · also A.2 |
| `sqlite3changeset_concat` | `void **ppOut` | — · also A.2 |
| `sqlite3changeset_invert` | `void **ppOut` | — · also A.2 |
| `sqlite3changeset_pk` | `unsigned char **pabPK` | — · also A.2 |
| `sqlite3rebaser_rebase` | `void **ppOut` | — · also A.2 |
| `sqlite3session_changeset` | `void **ppChangeset` | — · also A.2 |
| `sqlite3session_diff` | `char **pzErrMsg` | — |
| `sqlite3session_patchset` | `void **ppPatchset` | — · also A.2 |

## A.5 — OP-TYPED `void*` (6)

No landing at all: the op code decides what is written, so no
declaration types the seat. With the four variadic op-dispatch
functions these are ten entry points whose argument shape is a RUNTIME
value (§12) — one problem, not two.

| entry point | the seat(s) | also needs |
|---|---|---|
| `sqlite3_file_control` | `void*, typed by the op` | — |
| `sqlite3_stmt_scanstatus` | `void*, typed by the op` | — |
| `sqlite3_stmt_scanstatus_v2` | `void*, typed by the op` | — |
| `sqlite3changegroup_config` | `void*, typed by the op` | — |
| `sqlite3session_config` | `void*, typed by the op` | — |
| `sqlite3session_object_config` | `void*, typed by the op` | — |

---

# Appendix B — (c) THE USER-DATA SPLIT

In §7, in full. The counts: **63 take a function pointer — 14 are the
destructor SENTINEL — **BLOCKED ON THE MINT** (§10) — and 49 are real
callbacks. 47 of the 49 carry
a `void*` user-data seat, so a closure can capture. Two do not, and
cannot:**

```
sqlite3_auto_extension(void(*xEntryPoint)(void))
sqlite3_cancel_auto_extension(void(*xEntryPoint)(void))
```

Their callback takes NO arguments, so there is nowhere for an
environment to arrive — a pure fn is the only thing bindable there, in
principle and not merely today. Both are OPTIONAL and neither is on the
spine.

---

# Appendix C — (g) THE 226-NAME CHECKLIST

Every entry point whose return is a C `int`, so every one whose answer
is wrong for a negative value until the widths land. Six of them are
MEASURED to answer negatives (§11); the rest are wrong only where their
own documented answer can go below zero, which is why this is a
checklist and not an alarm. After `i32` lands it is a sweep: change the
declared answer, and the six in §11 stop lying.

| | | |
|---|---|---|
| `sqlite3_aggregate_count` | `sqlite3_auto_extension` | `sqlite3_autovacuum_pages` |
| `sqlite3_backup_finish` | `sqlite3_backup_pagecount` | `sqlite3_backup_remaining` |
| `sqlite3_backup_step` | `sqlite3_bind_blob` | `sqlite3_bind_blob64` |
| `sqlite3_bind_double` | `sqlite3_bind_int` | `sqlite3_bind_int64` |
| `sqlite3_bind_null` | `sqlite3_bind_parameter_count` | `sqlite3_bind_parameter_index` |
| `sqlite3_bind_pointer` | `sqlite3_bind_text` | `sqlite3_bind_text16` |
| `sqlite3_bind_text64` | `sqlite3_bind_value` | `sqlite3_bind_zeroblob` |
| `sqlite3_bind_zeroblob64` | `sqlite3_blob_bytes` | `sqlite3_blob_close` |
| `sqlite3_blob_open` | `sqlite3_blob_read` | `sqlite3_blob_reopen` |
| `sqlite3_blob_write` | `sqlite3_busy_handler` | `sqlite3_busy_timeout` |
| `sqlite3_cancel_auto_extension` | `sqlite3_carray_bind` | `sqlite3_carray_bind_v2` |
| `sqlite3_changes` | `sqlite3_clear_bindings` | `sqlite3_close` |
| `sqlite3_close_v2` | `sqlite3_collation_needed` | `sqlite3_collation_needed16` |
| `sqlite3_column_bytes` | `sqlite3_column_bytes16` | `sqlite3_column_count` |
| `sqlite3_column_int` | `sqlite3_column_type` | `sqlite3_compileoption_used` |
| `sqlite3_complete` | `sqlite3_complete16` | `sqlite3_config` |
| `sqlite3_create_collation` | `sqlite3_create_collation16` | `sqlite3_create_collation_v2` |
| `sqlite3_create_function` | `sqlite3_create_function16` | `sqlite3_create_function_v2` |
| `sqlite3_create_module` | `sqlite3_create_module_v2` | `sqlite3_create_window_function` |
| `sqlite3_data_count` | `sqlite3_db_cacheflush` | `sqlite3_db_config` |
| `sqlite3_db_readonly` | `sqlite3_db_release_memory` | `sqlite3_db_status` |
| `sqlite3_db_status64` | `sqlite3_declare_vtab` | `sqlite3_deserialize` |
| `sqlite3_drop_modules` | `sqlite3_enable_load_extension` | `sqlite3_enable_shared_cache` |
| `sqlite3_errcode` | `sqlite3_error_offset` | `sqlite3_exec` |
| `sqlite3_expired` | `sqlite3_extended_errcode` | `sqlite3_extended_result_codes` |
| `sqlite3_file_control` | `sqlite3_finalize` | `sqlite3_get_autocommit` |
| `sqlite3_get_table` | `sqlite3_global_recover` | `sqlite3_initialize` |
| `sqlite3_is_interrupted` | `sqlite3_keyword_check` | `sqlite3_keyword_count` |
| `sqlite3_keyword_name` | `sqlite3_libversion_number` | `sqlite3_limit` |
| `sqlite3_load_extension` | `sqlite3_memory_alarm` | `sqlite3_mutex_try` |
| `sqlite3_open` | `sqlite3_open16` | `sqlite3_open_v2` |
| `sqlite3_os_end` | `sqlite3_os_init` | `sqlite3_overload_function` |
| `sqlite3_prepare` | `sqlite3_prepare16` | `sqlite3_prepare16_v2` |
| `sqlite3_prepare16_v3` | `sqlite3_prepare_v2` | `sqlite3_prepare_v3` |
| `sqlite3_preupdate_blobwrite` | `sqlite3_preupdate_count` | `sqlite3_preupdate_depth` |
| `sqlite3_preupdate_new` | `sqlite3_preupdate_old` | `sqlite3_release_memory` |
| `sqlite3_reset` | `sqlite3_result_zeroblob64` | `sqlite3_rtree_geometry_callback` |
| `sqlite3_rtree_query_callback` | `sqlite3_set_authorizer` | `sqlite3_set_clientdata` |
| `sqlite3_set_errmsg` | `sqlite3_setlk_timeout` | `sqlite3_shutdown` |
| `sqlite3_sleep` | `sqlite3_snapshot_cmp` | `sqlite3_snapshot_get` |
| `sqlite3_snapshot_open` | `sqlite3_snapshot_recover` | `sqlite3_status` |
| `sqlite3_status64` | `sqlite3_step` | `sqlite3_stmt_busy` |
| `sqlite3_stmt_explain` | `sqlite3_stmt_isexplain` | `sqlite3_stmt_readonly` |
| `sqlite3_stmt_scanstatus` | `sqlite3_stmt_scanstatus_v2` | `sqlite3_stmt_status` |
| `sqlite3_str_errcode` | `sqlite3_str_length` | `sqlite3_strglob` |
| `sqlite3_stricmp` | `sqlite3_strlike` | `sqlite3_strnicmp` |
| `sqlite3_system_errno` | `sqlite3_table_column_metadata` | `sqlite3_test_control` |
| `sqlite3_threadsafe` | `sqlite3_total_changes` | `sqlite3_trace_v2` |
| `sqlite3_transfer_bindings` | `sqlite3_txn_state` | `sqlite3_unlock_notify` |
| `sqlite3_uri_boolean` | `sqlite3_value_bytes` | `sqlite3_value_bytes16` |
| `sqlite3_value_encoding` | `sqlite3_value_frombind` | `sqlite3_value_int` |
| `sqlite3_value_nochange` | `sqlite3_value_numeric_type` | `sqlite3_value_subtype` |
| `sqlite3_value_type` | `sqlite3_vfs_register` | `sqlite3_vfs_unregister` |
| `sqlite3_vtab_config` | `sqlite3_vtab_distinct` | `sqlite3_vtab_in` |
| `sqlite3_vtab_in_first` | `sqlite3_vtab_in_next` | `sqlite3_vtab_nochange` |
| `sqlite3_vtab_on_conflict` | `sqlite3_vtab_rhs_value` | `sqlite3_wal_autocheckpoint` |
| `sqlite3_wal_checkpoint` | `sqlite3_wal_checkpoint_v2` | `sqlite3_win32_set_directory` |
| `sqlite3_win32_set_directory16` | `sqlite3_win32_set_directory8` | `sqlite3changegroup_add` |
| `sqlite3changegroup_add_change` | `sqlite3changegroup_add_strm` | `sqlite3changegroup_change_begin` |
| `sqlite3changegroup_change_blob` | `sqlite3changegroup_change_double` | `sqlite3changegroup_change_finish` |
| `sqlite3changegroup_change_int64` | `sqlite3changegroup_change_null` | `sqlite3changegroup_change_text` |
| `sqlite3changegroup_config` | `sqlite3changegroup_new` | `sqlite3changegroup_output` |
| `sqlite3changegroup_output_strm` | `sqlite3changegroup_schema` | `sqlite3changeset_apply` |
| `sqlite3changeset_apply_strm` | `sqlite3changeset_apply_v2` | `sqlite3changeset_apply_v2_strm` |
| `sqlite3changeset_apply_v3` | `sqlite3changeset_apply_v3_strm` | `sqlite3changeset_concat` |
| `sqlite3changeset_concat_strm` | `sqlite3changeset_conflict` | `sqlite3changeset_finalize` |
| `sqlite3changeset_fk_conflicts` | `sqlite3changeset_invert` | `sqlite3changeset_invert_strm` |
| `sqlite3changeset_new` | `sqlite3changeset_next` | `sqlite3changeset_old` |
| `sqlite3changeset_op` | `sqlite3changeset_pk` | `sqlite3changeset_start` |
| `sqlite3changeset_start_strm` | `sqlite3changeset_start_v2` | `sqlite3changeset_start_v2_strm` |
| `sqlite3rebaser_configure` | `sqlite3rebaser_create` | `sqlite3rebaser_rebase` |
| `sqlite3rebaser_rebase_strm` | `sqlite3session_attach` | `sqlite3session_changeset` |
| `sqlite3session_changeset_strm` | `sqlite3session_config` | `sqlite3session_create` |
| `sqlite3session_diff` | `sqlite3session_enable` | `sqlite3session_indirect` |
| `sqlite3session_isempty` | `sqlite3session_object_config` | `sqlite3session_patchset` |
| `sqlite3session_patchset_strm` |
