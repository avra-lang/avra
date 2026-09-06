# `@std/sqlite` — the FFI the spec declares, and the FFI the tree has

Research for the SQLite campaign. Two halves: the SPEC's Axis 15 quoted
in full (it is the law the campaign implements), and the tree's actual
`extern fn` seam read line by line. The delta between them is the
campaign's language-work checklist.

**Sources.** The spec is
`../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`, cited by
line. Tree citations are `file:line` under
`/Users/tristan/projects/tristanMatthias/avra-lane-sqlite`. SQLite
prototypes are quoted from sqlite.org's C API reference, fetched
2026-09-05, with the page named. Nothing here was compiled or run — the
machine rule forbids it — so every claim about *behaviour* is marked
HIGH (read from source that admits one reading), MEDIUM (read, but the
composition is inferred), or LOW (inferred, needs a probe).

---

## PART 1 — THE SPEC'S FFI

### 1.0 The spine

Axis 15 (spec:2873–3079) is seven sub-decisions. Every one of them is
marked **"ships with C ABI FFI in v1.x"**. The campaign implements
15.1 tier 1 and all of 15.2–15.7.

### 1.1 Sub-decision 15.1 — FFI target languages (spec:2875–2897)

> - **Decision:** **(b) Tiered FFI — C ABI core, runtime bridges for Go/JVM, interpreter embedding for Python/JS**
> - **Tier 1 — C ABI (v1.x):**
>   - Direct function calls through C calling convention
>   - Trivially interoperates with C, Rust, Swift, Zig, any language exposing a C interface
>   - Zero runtime overhead; calls are native
>   - Visible costs (allocation, copy for strings/structs as needed)
> - **Visibility:** all FFI boundaries are annotated, their costs are documented, and they appear clearly in code so programmers (and LLMs) see when they're crossing language boundaries.
> - **Versioning:** v1.0 reserves all FFI syntax; v1.x ships C ABI; v2.0+ adds higher tiers progressively based on user demand.

The sqlite driver is squarely tier 1. Tiers 2 and 3 are out of scope and
must not be designed for.

**"Visible costs (allocation, copy for strings/structs as needed)"** is
the sentence that licenses a boundary copy — it is not a hole in the
zero-shim rule, it is the spec's own expectation.

### 1.2 Sub-decision 15.2 — C type modeling (spec:2899–2927)

> - **Decision:** **(c) Both — explicit C types available in `@std/c`, automatic mapping in `extern` declarations**
> - **Automatic mapping in `extern` declarations:**
>   ```
>   extern fn strlen(s: CString) -> int
>   // Compiler translates int → size_t for the C ABI
>
>   extern fn add(a: i32, b: i32) -> i32
>   // Explicit-size types map directly
>   ```
> - **Explicit C types from `@std/c`:**
>   ```
>   use @std/c.{c_int, c_long, c_size_t, CString}
>
>   extern fn sqrtf(x: c_float) -> c_float
>   extern fn read(fd: c_int, buf: *u8, count: c_size_t) -> c_ssize_t
>   ```
> - **Rules:**
>   - Avra's `int` maps to platform pointer-sized int in `extern` declarations (usually i64)
>   - `i32`, `i64`, `u8`, etc. map to fixed-width C types directly
>   - `string` (Avra's heap-allocated string) requires explicit conversion to `CString` at the boundary
>   - `CString` is null-terminated UTF-8, matches C's `const char*`

Four load-bearing consequences:

1. **`@std/c` is a real package the campaign must create** — `c_int`,
   `c_long`, `c_size_t`, `c_float`, `c_ssize_t`, `CString`.
2. **`i32` must exist at the extern boundary.** The spec files sized
   integers under "systems level" (31.1, spec:6249–6252) but 15.2 uses
   them in `extern` declarations directly, with no `systems { }` block.
   Where the two disagree, 15.2 is the more specific rule for the
   boundary. MEDIUM — the spec does not resolve this explicitly.
3. **`string` may NOT cross.** "requires explicit conversion to
   `CString` at the boundary" is a prohibition, and the tree violates it
   today (§2.7).
4. **A pointer type syntax is used but never defined.** `*u8`,
   `*SQLite3`, `*mut *SQLite3` appear in the 15.2/15.4/15.5 examples;
   no sub-decision defines them. This is a genuine spec hole (§1.12).

### 1.3 Sub-decision 15.3 — Callback / trampoline mechanism (spec:2929–2951)

> - **Decision:** **(b) Compiler-generated trampolines for closures crossing to C ABI**
> - **How it works:**
>   ```
>   // Avra code:
>   let threshold = 10
>   c_sort(items, (a, b) -> a - b)       // closure captures nothing in this case
>   c_sort(items, (a, b) -> (a % threshold) - (b % threshold))  // captures threshold
>   ```
> - **Compiler generates:**
>   - A C-callable function with the C ABI signature
>   - The closure's captures are boxed into a `user_data` struct
>   - The trampoline unpacks `user_data`, calls the Avra closure, returns the result
>   - The generated code follows the target C API's `void* user_data` convention
> - **C APIs that don't support user_data:** closure capture is rejected with a compile error and clear guidance: "this C API's callback does not accept user data; closure cannot capture variables. Use a pure function or global state."
> - **Memory safety:** trampolines hold the closure's captures alive for the duration of the C API's use. For synchronous callbacks this is the lexical scope of the call; for asynchronous (e.g., event loops) the programmer must manage lifetime explicitly (via `Rc<T>` or static lifetime).

The trampoline is **compiler-generated, statically, per closure type** —
never libffi, never runtime codegen. That constraint is the whole reason
the decision is (b), and it is binding.

### 1.4 Sub-decision 15.4 — FFI memory ownership (spec:2953–2987)

> - **Decision:** **(b) Annotations — ownership declared explicitly per extern function**
> - **Rationale:** Unspecified ownership (a) is a recipe for memory leaks and double-frees — exactly the bugs Avra is trying to prevent. Inference (c) cannot reliably determine ownership from C signatures alone (`int foo(char* s)` — does foo take ownership of `s`?). Explicit annotations (b) force programmers to document the contract, and the compiler generates the correct memory management.
> - **Annotation vocabulary:**
>   - `@takes_ownership(param)` — the C function takes ownership of the parameter; Avra does NOT free it
>   - `@returns_ownership` — the C function returns a pointer Avra must eventually free
>   - `@borrows(param)` — C function borrows the parameter for the duration of the call; Avra retains ownership
>   - `@returns_borrowed(from: param)` — returned pointer's lifetime is tied to a parameter
>   - `@free_with(fn_name)` — the C function for freeing a returned value (e.g., `@free_with(free)`, `@free_with(sqlite3_close)`)
> - **Example:**
>   ```
>   // strdup: returns a new string caller must free
>   extern fn strdup(s: CString) -> CString
>     @returns_ownership
>     @free_with(free)
>
>   // strlen: borrows the string for the call
>   extern fn strlen(s: CString) -> c_size_t
>     @borrows(s)
>
>   // sqlite3_open: returns a handle requiring cleanup
>   extern fn sqlite3_open(path: CString, db: *mut *SQLite3) -> c_int
>     @returns_ownership(db)
>     @free_with(sqlite3_close)
>   ```
> - **Compiler behavior:**
>   - `@returns_ownership` wraps the returned value in an Avra `Owned<T>` with the specified `@free_with` as drop
>   - `@borrows` ensures the Avra value outlives the C call (compile error if not)
>   - `@takes_ownership` moves the value and prevents further Avra use

Note the spec's own SQLite example uses an **out-parameter**
(`db: *mut *SQLite3`) and attaches `@returns_ownership(db)` — the
annotation takes a *parameter name*, naming the out-param as the thing
owned. The vocabulary therefore has two arities:
`@returns_ownership` (bare, the return value) and
`@returns_ownership(param)` (an out-param).

`Owned<T>` is named but never defined by its own sub-decision. It is the
compiler-generated wrapper whose drop is the `@free_with` fn.

### 1.5 Sub-decision 15.5 — Opaque types across FFI (spec:2989–3029)

> - **Decision:** **(c) Compiler-managed opaque types with automatic Drop**
> - **Syntax:**
>   ```
>   opaque type SQLite3 @free_with(sqlite3_close)
>   opaque type FILE @free_with(fclose)
>   opaque type CurlHandle @free_with(curl_easy_cleanup)
>   ```
> - **Semantics:**
>   - `opaque type T` creates a type that Avra code cannot inspect — only hand to C functions
>   - Values are always heap pointers (the compiler generates zero-size wrapper with the pointer)
>   - Drop automatically calls the `@free_with` function when the value goes out of scope
>   - Values can be borrowed, moved, stored in structs, or returned — all the normal Avra memory semantics apply
> - **Example:**
>   ```
>   opaque type SQLite3 @free_with(sqlite3_close)
>
>   extern fn sqlite3_open(path: CString, db: *mut *SQLite3) -> c_int
>     @returns_ownership(db)
>
>   extern fn sqlite3_prepare(db: *SQLite3, sql: CString, stmt: *mut *Statement) -> c_int
>     @borrows(db)
>     @returns_ownership(stmt)
>
>   fn query_users(db_path: string) -> Result<List<User>, DbError> {
>     let db_path_c = CString.from(db_path)
>     let db = sqlite3_open_wrapped(db_path_c)?
>     // db is an Avra value holding the opaque SQLite3 pointer
>     // When this function returns, Drop calls sqlite3_close(db) automatically
>
>     // ... use db ...
>   }
>   ```
> - **Why this matters:** wrapping a library like SQLite or libcurl normally requires careful `defer` pairings throughout user code. With compiler-managed opaque types, the cleanup is guaranteed and the programmer cannot avrat it.

**The spec's motivating example for 15.5 IS SQLite.** This campaign is
the sub-decision's intended first user; the design must land in the
shape 15.5 names, not a variation.

### 1.6 Sub-decision 15.6 — String encoding across FFI (spec:3031–3055)

> - **Decision:** **(c) Both — declared per extern function; `CString` default, `CStr` for explicit length**
> - **Types:**
>   - **`CString`** — null-terminated UTF-8, matches `const char*` in traditional C APIs
>   - **`CStr`** — pointer + length, matches `const char*, size_t` pairs in modern APIs
> - **Conversion from Avra `string`:**
>   - `CString.from(s)` — allocates a null-terminated copy; Avra retains ownership (auto-freed at scope end) unless passed with `@takes_ownership`
>   - `CStr.from(s)` — creates a pointer+length view into the Avra string; no allocation; borrows for the call
> - **Example:**
>   ```
>   extern fn strlen(s: CString) -> c_size_t
>   extern fn memcmp(a: CStr, b: CStr) -> c_int
>
>   let hello = "hello"
>   let len = strlen(CString.from(hello))        // allocates, frees after
>   let cmp = memcmp(CStr.from(hello), CStr.from("world"))  // no allocation
>   ```
> - **Encoding errors:** `string` is always valid UTF-8 (invariant from 9.15). `CString.from` fails only if the string contains embedded null bytes, in which case it returns an error.

Two things the campaign must hold to:

- **`CStr` is a pointer+length pair.** It is the spec's answer for
  `sqlite3_bind_text(stmt, i, ptr, nByte, dtor)` and for
  `sqlite3_column_blob` + `sqlite3_column_bytes`. It is NOT a `Bytes`
  value category — it is a *borrowed view*. An owning, NUL-safe byte
  value is a separate ask the spec does not make (§1.12).
- **`CString.from(s)` is fallible on an embedded NUL.** So a `string`
  round-tripped through `CString` can never hold a NUL — which is
  exactly why BLOB needs `CStr`/`Bytes` and not `string`.

### 1.7 Sub-decisions 15.7 and 12.12 — FFI error mapping (spec:3057–3078, 2537–2562)

15.7:

> - **Decision:** **(b) `@error_if` annotations — consistent with decision 12.12**
> - **See full details in decision 12.12.** Key annotations:
>   - `@error_if(condition, error_constructor)` — e.g., `@error_if(it < 0, IoError.from_errno)`
>   - `@error_null(ErrorType)` — for NULL-returning APIs
>   - `@error_map(fn)` — arbitrary mapping
> - **Composition with other FFI annotations:** `@error_if` stacks with `@returns_ownership`, `@borrows`, etc. Compiler handles the composition correctly.
> - **Example:**
>   ```
>   extern fn open(path: CString, flags: c_int) -> c_int
>     @error_if(it < 0, IoError.from_errno)
>
>   // Generated wrapper signature:
>   // fn open(path: CString, flags: c_int) -> Result<c_int, IoError>
>   ```

12.12 (spec:2537–2562), the fuller statement:

> - **Syntax:**
>   ```
>   extern fn open(path: CString, flags: int) -> int
>     @error_if(it < 0, IoError.from_errno)
>
>   // Compiler generates wrapper:
>   // fn open(path: CString, flags: int) -> Result<int, IoError> {
>   //   let result = extern_open(path, flags)
>   //   if result < 0 { .err(IoError.from_errno(errno())) }
>   //   else { .ok(result) }
>   // }
>   ```
> - **Annotation variations:**
>   - `@error_if(condition, error_constructor)` — single-condition conversion
>   - `@error_map(fn)` — arbitrary mapping function applied to the return value
>   - `@error_null(ErrorType)` — shorthand for pointer-returning APIs that use NULL for errors
> - **Why this matters for wrapping large C APIs:** wrapping something like libcurl or libxml requires hundreds of FFI bindings. With annotation-based error conversion, each becomes a single line with the error semantics visible. Without it, each would require a hand-written wrapper — days of work to wrap a medium-sized library.

`it` is the pronoun for the raw return value inside `@error_if` — the
same `it` the tree already has for lambdas (DOGFOODING.md:640).

The annotation **generates a wrapper fn that shadows the extern's
name**; the raw symbol becomes internal (`extern_open` in the sketch).
That is a name-binding consequence the campaign must design, not a
detail.

### 1.8 The annotation surface the FFI rides — Axis 30 (spec:6110–6227)

30.1 (spec:6112–6156):

> - **Decision:** **(a) `@name(args)` — Java/Python/Swift-style annotations**
> - **Syntax:**
>   ```
>   @takes_ownership(s)
>   extern fn consume_string(s: CString)
>   ```
> - **Forms:**
>   - `@name` — no arguments
>   - `@name(arg)` — single positional argument
>   - `@name(arg1, arg2, key: value)` — multiple args, can be positional or keyword
>   - Multiple annotations stack on one declaration; applied in declaration order (outer-first)
> - **Placement:**
>   - On declarations: `fn`, `type`, `shape`, `trait`, `enum`, `const`, `model`, `service`, etc.
>   - On struct fields and enum variants: inline annotations
>   - On expressions (rarely): for `@inline` call sites, `@unchecked` casts — limited, documented cases
>   - Module-level: at the top of a file before declarations
> - **`@` conflicts:** `@` is also used as the prefix for package namespaces (`@std/...`, `@myorg/...`). These are syntactically distinguishable because annotations are followed by an identifier directly, package names are followed by `/`. Parser handles the disambiguation cleanly.

**Note the placement disagreement inside the spec itself.** 30.1's
example puts `@takes_ownership(s)` *above* the declaration
(spec:6136–6137); 15.4 and 15.7 put the annotations *below*, indented
after the signature (spec:2970–2981, 3072–3073). MEDIUM: the campaign
should support the 30.1 form (prefix, the general annotation placement)
and treat the Axis-15 trailing form as the spec's informal rendering.
Prefix placement is also the only one the tree's grammar can take
without a statement-tail ambiguity (§2.1).

30.3 (spec:6194–6227) requires each annotation to declare an effect:

> - **Effect categories:**
>   - **`Effect.metadata`** — pure metadata, no compilation effect.
>   - **`Effect.validate`** — runs a compile-time check; emits diagnostics if check fails. Does NOT modify generated code.
>   - **`Effect.transform_body`** — wraps or modifies the body of the annotated declaration.
>   - **`Effect.derive`** — adds additional declarations alongside the annotated one.
>   - **`Effect.codegen_attribute`** — passes hints to codegen without transforming source-level code. Example: `@inline`, `@no_mangle`, `@link_section("...")`.
> - **Visible effects:**
>   - `avra explain annotation @audited` lists what `@audited` does: its effect category, what it validates, what it transforms, what it generates

So the FFI annotations classify as: `@borrows` / `@takes_ownership` →
`Effect.validate`; `@returns_ownership` / `@free_with` → `Effect.derive`
(they mint a drop); `@error_if` / `@error_null` / `@error_map` →
`Effect.transform_body` (they mint the wrapper). `avra explain
annotation` is a P7 obligation, not a nicety.

Also binding, spec:5630–5631 (Axis 28, naming):

> - Cannot be disabled project-wide; individual exceptions via `@allow(non_canonical_name)` on specific declarations for FFI boundaries and other pragmatic cases
> - **FFI exception:** bindings to C libraries retain C naming: `c_printf`, `c_strlen`. Marked with `@ffi_binding` — exempt from warnings.

`sqlite3_column_text` keeps its C name. `@ffi_binding` is the marker.

### 1.9 Numerics the boundary needs — Axis 31 (spec:6230–6427)

31.2, float (spec:6293–6314):

> - **Decision:** **(c) `float` (64-bit IEEE 754) at app level, `f32` and `f64` at systems level**
> - **App level:**
>   - **`float`** — 64-bit IEEE 754 double-precision
>   - No `double` alias (`float` IS double at app level)
> - **Special values:** IEEE 754 semantics — `NaN`, `Infinity`, `-Infinity` are valid values. Available as `Float.nan`, `Float.infinity`, `Float.neg_infinity`. Comparisons with NaN follow IEEE rules (NaN != NaN).
> - **No implicit int-float conversion:** `let x: float = 5` is a compile error. Write `let x: float = 5.0` or `let x: float = (5).to_float()`.
> - **Float literals:** must have a decimal point or exponent: `5.0`, `1e10`, `2.5e-3`. `5` alone is an integer literal.
> - **Division semantics:** `int / int = int` (truncating), `float / float = float`. Mixed arithmetic requires explicit conversion.
> - **Versioning:** `float` ships in v1.0.

`float` is a **v1.0** obligation the tree has not met.
`sqlite3_column_double` returns a C `double`; there is no honest binding
without it.

31.3, exact decimal (spec:6316–6345):

> - **Decision:** **(b) `BigInt` / `BigDecimal` in `@std/numbers` — explicit types, no silent promotion**
> - **Types:**
>   - **`BigDecimal`** — arbitrary-precision decimal with explicit scale; useful for money, scientific data, anything where `0.1 + 0.2 == 0.3` matters
> - **Money type:** `@std/money` provides `Money` built on `BigDecimal` with currency tagging — the idiomatic choice for financial apps.
> - **Performance note:** every `BigInt` / `BigDecimal` operation allocates.
> - **Versioning:** `@std/numbers` ships in v1.0 with `BigInt` and `BigDecimal`.

The campaign's "decimal" is the spec's **`BigDecimal` in `@std/numbers`**,
a library type, not a primitive. SQLite has no DECIMAL storage class —
`BigDecimal` round-trips through TEXT. The driver must not invent one.

31.5, literals (spec:6347–6395) — the boundary-relevant parts:

> - Integer suffixes: `i8`, `i16`, `i32`, `i64`, `i128`, `u8`, `u16`, `u32`, `u64`, `u128`, `uint`, `int`
> - Float suffixes: `f32`, `f64`, `float`
> - `b'a'` — byte literal (type `u8`), value is the ASCII code
> - **Rationale:** ... Type suffixes (b) are essential for FFI ...

### 1.10 The memory laws the boundary must obey

9.10, drop ordering (spec:1313–1319):

> - **Rationale:** Standard across C++ and Rust. Matches how programmers mentally model lifetime — things declared later often depend on things declared earlier, so they must drop first for RAII patterns to work safely.

9.11, defer vs Drop (spec:1336–1364):

> - **Decision:** **(c) Interleaved by declaration order — both defer and Drop obey reverse-declaration order at scope exit**
> - **Drop** is the type-level mechanism. Used when a type has inherent cleanup semantics (File closes, Connection releases, Lock unlocks). The cleanup travels with the type; anyone using the type gets correct cleanup automatically. This is the primary mechanism for resource management.
> - **Why both:** using only Drop forces the programmer to define a wrapper type for every ad-hoc cleanup (verbose). Using only defer misses the type-level correctness guarantee (a File without Drop could leak on early return).

12.7 (spec:2310–2333):

> - **Decision:** **(d) All three — Drop, defer, and errdefer compose under unified LIFO ordering**
> - **Ordering (from 9.11):** all three obey LIFO at scope exit. Drop operations, defer blocks, and errdefer blocks (if the scope exits via error) all interleave in reverse declaration order.

So `opaque type T @free_with(f)` lands **as a Drop**, and Drop must
interleave with the tree's existing `defer`/`errdefer` frames in one
LIFO order. The tree's defer-frame machinery (CLAUDE.md, "A `defer`'s
FRAME IS ITS STATEMENT LIST") is the seat Drop plugs into — not a
parallel mechanism.

9.15, the string invariant the boundary inherits (spec:1462–1500):

> - **Encoding:** UTF-8 internally, always. No UTF-16 or UCS-4 representations.
> - `string.length` returns **byte count** by default (cheap, O(1))
> - `s[i]` indexes by byte position and returns `u8` (not char) — explicit and efficient

`string` is UTF-8-valid by invariant. A SQLite BLOB is arbitrary bytes.
They are different types; the campaign's `Bytes` premise is right, and
the spec's name for the *borrowed* form is `CStr` (§1.6).

### 1.11 The versioning contradiction, stated plainly

Axis 9's versioning ladder (spec:1672, 1683, 1688):

> 10. **Lexer reserves all future keywords.** `systems`, `bare`, `hardware`, `owned`, `borrow`, `move`, `level`, `unsafe`, `extern`, `async`, `spawn`, `await`, `channel`, `select` are all reserved in v1.0 even if not implemented.

> **v1.0-reserved (parsed but errored):**
> - `extern fn`, `@c_abi`, FFI syntax

> **v2.0:** Bare level implementation. FFI via bare level.

Axis 15's every sub-decision says "ships with C ABI FFI in **v1.x**",
and 12.12 says "ships when FFI lands (**v2.0**)".

**Reconciliation.** The three statements are inconsistent as written.
The tree has already decided by landing `extern fn` at app level with no
`bare { }` block (ROADMAP.md:5249, "PARITY RUNG 12 LANDED (2026-09-03) —
THE HOST SEAM"), which matches Axis 15's v1.x and rejects "FFI via bare
level". The campaign follows the tree and Axis 15. **The `@error_if`
family's "v2.0 / FFI reserved for future use" line (spec:2561) is
superseded** — a spec divergence to flag to the owner, not to silently
absorb.

### 1.12 What the spec does NOT say — real holes

These are not gaps in the tree; they are gaps in the LAW. Each needs an
owner decision before the corresponding driver code can be written.

| Hole | Why it bites the sqlite driver |
|---|---|
| **No pointer type syntax sub-decision.** `*u8`, `*SQLite3`, `*mut *SQLite3` are used in 15.2/15.4/15.5 examples and defined nowhere. 9.x reserves `&T`, `&mut T`, `Ref<T>`, `Box<T>` (spec:1681) — a *different* vocabulary. | Every out-param (`sqlite3_open_v2`, `sqlite3_prepare_v2`, `sqlite3_exec`'s `errmsg`) needs one. |
| **No variadics.** The word does not appear in the spec. | `int sqlite3_config(int, ...)` is variadic (sqlite.org/c3ref/config.html). So are `sqlite3_db_config`, `sqlite3_mprintf`, `sqlite3_vtab_config`. |
| **No out-parameter model.** 15.4's example passes `db: *mut *SQLite3` and annotates `@returns_ownership(db)`, but nothing says how Avra *produces* the address or reads the slot back. | It is the most common shape in the SQLite API. |
| **No owning byte value.** `CStr` is a borrowed view only. | A BLOB read must outlive `sqlite3_step` (the pointer dies at the next step — sqlite.org/c3ref/column_blob.html), so it must be *copied* into an owning value. |
| **No symbol resolution model.** Nothing says how `extern fn sqlite3_open` finds `sqlite3_open` — link-time, `dlopen`, per-package. | Decides whether the interpreter can host externs at all. |
| **Nothing on the interpreter and externs.** Axis 26 (spec:5062+) never says an IR evaluator must agree with native across the FFI seam. | The campaign's `eval == native` promise is a tree law (CLAUDE.md, the IR protocol's "a corpus program proving eval == native"), not a spec law. Good — the design is ours to set. |
| **`Owned<T>` named, never specified** (spec:2984). | `@returns_ownership` cannot be implemented without deciding what `Owned<T>` *is*. |
| **`@std/c` named, never enumerated** (spec:2905, 2917). | The campaign must invent the full type list. |

---

## PART 2 — WHAT THE TREE HAS TODAY

### 2.1 The grammar — one line

`packages/std-avrac/src/features/fns/mod.av:32`:

```
stmt = "extern" "fn" n:NAME "(" ( ps:NAME ":" pt:type ( "," ps:NAME ":" pt:type )* ","? )? ")" ( "->" r:type )? END @recover(sync_to: "END") -> extern_fn(n, ps, pt, r)
```

Read exactly:

- The anchor is the keyword `extern`. It is also in `reserved()`
  (`language/resolve.av:22–26`), so no program may bind the name.
- **Every parameter MUST be typed.** `ps:NAME ":" pt:type` — the colon
  and type are not optional, unlike `fn_decl` on the next line where
  it is `( ":" pt:type )?`. HIGH.
- The parameter list takes a trailing comma (`","?`), per the tree's
  comma law.
- The answer is optional; absent means `void`.
- **There is no annotation slot.** No `@`-prefixed item anywhere in the
  rule, and no annotation grammar exists in the tree at all (CLAUDE.md,
  "The subset today": `@comptime` "refuses at the `@`").
- **There is no `<T>` slot** — externs are never generic.
- The branch recovers to `END`; it is the only `extern`-anchored branch,
  so recovery here is lawful under CLAUDE.md's ordered-choice rule.

`export extern fn …` **parses and passes the module law**: the modules
feature contributes `"export" d:stmt -> export_stmt(d)`
(`features/modules/mod.av:51`), and the law refuses only statements whose
`declared_kind` is null (`features/modules/check.av:13`) —
`declared_kind` answers `DeclKind.Fn` for an extern
(`core/parts.av:232`). MEDIUM (read, not probed): whether the symbol then
resolves through a package boundary.

### 2.2 The node, and its one projection

`core/nodes.av:402–404`:

```
/// `extern fn name(params) -> ret` — a fn the host provides: a
/// signature with no body, called by its bare symbol.
ExternFn(name: string, params: List<Param>, ret: TypeRef)
```

Built at `features/fns/builders.av:66–74`:

```
/// `extern fn name(p: T, …) -> R` — every seat typed by the grammar,
/// so the names and types pair by index.
fn build_extern(mut b: Builder) -> Result<LangNode, string> {
    let n = b.token(0)?
    let ps = b.tokens(1)?
    let ends: int? = b.span_end()
    if ends == null { return .Err("an extern declaration without a span") }
    b.make_stmt(Stmt.ExternFn(n.text, seats(ps, aligned_param_types(ps, b.type_refs(2)?, ends!)), b.answer(3)))
}
```

Projected once at `core/parts.av:250–257` into
`ExternParts { name, params, ret }` (`core/parts.av:267–268`).

### 2.3 The declaration, and how its symbol reaches the linker

- An extern is a `DeclKind.Fn` with no body (`core/parts.av:232`).
- `Decls.is_extern(d)` — `features/decls.av:593–595`:
  `x.kind is .Fn && self.store(d).extern_parts(x.stmt) != null`.
- **The symbol is the BARE NAME, unmangled** — `features/decls.av:654`:
  `if self.is_extern(d) { return x.name }`, inside `Decls.symbol`
  (`decls.av:652`). Every other fn is mangled.
- Gathered whole-table, once per lowering (`language/lower.av:42–50`):
  `extern_names` (strings, for the emitter's unknown-callee refusal) and
  `extern_rows` (registry rows).
- `extern_row_of` (`language/lower.av:52–56`) turns the signature into a
  row through `rt_kind_of`.
- Carried on `Lowered.externs: List<RtSig>` (`language/lower.av:167`).
- The backend declares them exactly like runtime rows
  (`language/llvm.av:168–173`):
  ```
  /// The program's own host fns, declared like the runtime's rows.
  fn declare_externs(lc: ptr, m: ptr, rows: List<RtSig>) {
      for s in rows {
          declare(m, s.name, ll_rt_kind(lc, s.ret), [ll_rt_kind(lc, k) for k in s.params], false)
      }
  }
  ```
  The final `false` is `declare`'s `variadic` parameter
  (`language/llvm.av:189–195`) — the knob exists and is **always passed
  false**. HIGH.
- **THE CLOSURE LAW** (`language/llvm.av:79–95`, `unheld_name`): every
  symbol any instruction names must be a lowered body, a runtime row, or
  one of the program's externs, or the module refuses before emission
  with "internal compiler error: nothing declares `<name>` — the program
  is not closed".

### 2.4 Which types may cross — three machine kinds, and no more

`core/runtime_api.av:92–98`:

```
/// The runtime kind a type rides in a call across the host seam:
/// scalars are words, every pointer shape a pointer, void nothing.
export fn rt_kind_of(types: TypeRegistry, ty: TypeId) -> RtKind {
    if types.shape_of(ty) is .Void { return RtKind.Void }
    if types.rides_pointer(ty) { return RtKind.Ptr }
    RtKind.I64
}
```

`RtKind` is **`I64 | Ptr | Void`** — three kinds
(`language/llvm.av:175–181` maps them to `int64`, `pointer`, `void`).

Consequences, all HIGH:

- **No `i32`.** A C `int` seat is declared `i64`.
- **No `double`/`f64`.** Not expressible at all.
- **No struct-by-value.** An Avra record rides as its box pointer.
- **`bool` rides as `i64`**, zero-extended at the seat
  (`language/llvm.av:434–436`).
- **Every managed Avra value rides as its raw box pointer** — a `string`
  crosses as `const char*` at the *payload*, a `List<T>` as its
  `AvraArray*`. `corpus/native/externs.av:10` proves `List<string>`
  crosses.

The type surface an extern seat may name is
`features/type_expr/mod.av:34–41`: `T`, `T?`, `dyn T`, `T<A, B>`. So
**`ptr?` parses** (`type = n:NAME "?"`).

`ptr` itself, `core/types.av:19–21`:

```
/// An opaque host pointer — what an extern fn passes and answers;
/// nothing reads through it.
Ptr
```

Its properties, read from source:

| Question | Answer | Where |
|---|---|---|
| Rides a pointer? | yes | `core/types.av:118–125` (`ptr_shape`) |
| Refcounted? | **no** | `language/memory.av:42–43` |
| Comparable (`==`, `<`)? | **no** | `features/checks.av:427–429` — `sh is .Int \|\| sh is .Bool \|\| sh is .Str` |
| Nullable (`ptr?`)? | yes, as a **NICHE** | `features/values.av:228–232` (`inner_repr`: `rides_pointer` → `Repr.Niche`); presence is `v != 0` (`values.av:243–250`) |
| Named in an annotation? | yes | `language/typing.av:322` |

**`ptr?` is the tree's existing, working null-pointer test.** A niche
nullable *is* its pointer; `presence_of` emits `Bin(Ne, v, 0)`; and
`rt_kind_of(Opt(Ptr))` answers `Ptr` because `rides_pointer` sees
through the `Opt` (`core/types.av:248–258`). MEDIUM-HIGH (read
end-to-end, unprobed): `extern fn f() -> ptr?` should already give the
driver a NULL-checkable handle **today**, with no language work.

### 2.5 Lowering the call

`features/fns/lower.av:12–13` routes a call whose callee is extern
(`features/contexts.av:271–275`, `extern_callee`) to:

```
/// A call across the host seam: the extern's bare symbol as a
/// runtime call — void ones answer nothing.
fn extern_call_reg(mut cx: LowerCx, e: ExprId, symbol: string, regs: List<Reg>) -> Reg {
    if cx.shape_at(e) is .Void {
        cx.emit(Ins.CallRtVoid(symbol, regs))
        let dst = cx.result(e)
        cx.emit(Ins.ConstInt(dst, 0))
        return dst
    }
    let dst = cx.result(e)
    cx.emit(Ins.CallRt(dst, symbol, regs))
    dst
}
```
(`features/fns/lower.av:39–51`)

**No new IR variant.** An extern call IS a runtime call — the same
`CallRt`/`CallRtVoid` the registry uses. This is THE VOCABULARY SEAM
RULE applied: an extern is DATA (a row), not BEHAVIOR (an instruction).
ROADMAP.md:5253–5258 records the decision.

Seat coercion at emission, `language/llvm.av:428–444` (`rt_arg`): a
declared `I64` param takes a `ptr_to_int` from a pointer-riding register
and a `zext` from a bool. A declared `Ptr` param takes the value as-is.

### 2.6 What the memory pass owes an extern — nothing, in both directions

Three separate reads, all HIGH:

1. **Arguments are BORROWED.** `retained_args` is called from the
   `.Call` and `.CallPtr` arms only (`language/memory.av:124, 130`);
   `.CallRt`/`.CallRtVoid` fall into the pass-through arm
   (`language/memory.av:190–196`), which calls `manages` and emits the
   instruction with no retains. This is CLAUDE.md's "A RUNTIME ROW
   BORROWS ITS ARGUMENTS".
2. **The answer is BORROWED.** `managed_dst`
   (`language/memory.av:316–327`):
   ```
   .CallRt(_, callee, _) -> if rt_owns(callee) { dst } else { null },
   ```
   and `rt_owns` reads `rt_sig_of(name)` — the **static** registry index
   (`core/runtime_api.av:105–107, 118–124`), which never contains a
   program's externs. `extern_row` hard-codes `owns_result: false`
   (`core/runtime_api.av:101–104`). So an extern's managed answer is
   **never released**.
3. **There is no owned twin.** `extern_row` sets
   `has_owned_twin: false`, so `owned_form`
   (`language/memory.av:335–349`) never rewrites an extern call.

Net: **the tree's `extern fn` implements exactly one of the spec's five
ownership annotations — `@borrows` — and implements it as the only
option, not as a declared choice.**

### 2.7 The header law — the hard constraint on what may cross

`runtime/avra_runtime.c:56–73`:

```c
typedef struct {
    uint32_t tag;
    int32_t kind;
    int32_t rc;
    uint32_t len;
} Header;

static Header* hdr(void* p) {
    uintptr_t a = (uintptr_t)p;
    if ((a & 15) != 0 || a < 0x100000000ull) return NULL;
    Header* h = (Header*)p - 1;
    return h->tag == AVRA_TAG ? h : NULL;
}
```

Sixteen bytes before every payload; `AVRA_TAG` is `"AVRA"`
(`avra_runtime.c:52`). `avra_rc_retain`/`avra_rc_release`
(`avra_runtime.c:383, 417`) read it. `str_len` reads it
(`avra_runtime.c:272–275`).

**An Avra `string` at the machine level IS a `const char*` to a
NUL-terminated payload.** That is why `extern fn
avra_selfhost_file_exists(path: string) -> int` works and why the
existing runtime C bodies take `const char*`.

**The reverse does not hold.** A `const char*` that C produced is NOT an
Avra `string`: `hdr()` reads the 16 bytes *before* it. Today the tag
check makes that non-fatal (a wrong tag answers NULL and `str_len` falls
back to `strlen`), but it is an out-of-bounds read of foreign memory on
every `.length`, and a direct violation of CLAUDE.md's "EVERY POINTER
AVRA HOLDS CARRIES A HEADER". `extern fn sqlite3_column_text(...) ->
string` is **forbidden**, not merely unwise. HIGH.

The existing `-> string` externs are lawful only because their C bodies
are ours and answer `str_static`/`str_owned`
(`avra_runtime.c:302–308, 1122`).

### 2.8 Strings are NUL-truncating at every operator but `.length`

| Operation | Implementation | NUL-safe? |
|---|---|---|
| `.length` | `str_len` reads `h->len` | **yes** (`avra_runtime.c:272–275`) |
| `==` | `strcmp` | no (`avra_runtime.c:475–478`) |
| `contains` | `strstr` | no (`avra_runtime.c:1144`) |
| `index_of` | `strstr` | no (`avra_runtime.c:1159–1160`) |
| `replace` | `strlen` + `strstr` | no (`avra_runtime.c:1208–1220`) |
| `split` | `strlen` + `strstr` | no (`avra_runtime.c:1234–1246`) |

The campaign's BLOB premise is confirmed exactly. HIGH.

### 2.9 The link seam

Three files, one path:

1. **The manifest row.** `[link] objects = [...]`, `flags = [...]` —
   `language/manifest.av:35, 57, 109`. `manifest.av:109` is the whole
   schema: `if section == "link" { return key == "objects" || key == "flags" }`.
   This tree's own use, `packages/std-avrac/avra.toml`:
   ```toml
   [link]
   objects = ["../../build/llvm_wrapper.o"]
   flags   = ["-L${LLVM_PREFIX}/lib", "-lLLVM"]
   ```
2. **Gathering.** `language/workspace.av:935–946`:
   ```
   /// WHAT THE PROGRAM LINKS: every package's `[link]` promise, in
   /// package order — the objects it names (under its own root) and
   /// the flags it asks for. A package that declares `extern fn` says
   /// here who keeps the promise.
   export fn link_inputs(ws: Workspace) -> List<string> {
       flatten([package_link(ws, pkg) for pkg in ws.packages])
   }
   ```
   `objects` are joined under the package's own root; `flags` are not.
   `link_words` (`workspace.av:953–956`) expands `${NAME}` holes from the
   environment (`expanded`, `workspace.av:960–969`) and drops empty
   words. **Each is one argv element** — nothing quotes, nothing fences.
3. **The link line.** `packages/cli/src/commands/shared.av:276–278`:
   ```
   fn clang_words(ll_path: string, p: Program, opt: string) -> List<string> {
       ["-w", opt, ll_path, "build/avra_runtime.o"].concat(link_words(p.ws)).concat(["-o", binary_name(ll_path)])
   }
   ```
   run as argv (`shared.av:289–291`), with the C compiler from `CC` else
   `clang` (`shared.av:304–309`).

**Objects are built outside the toolchain.** `Makefile:63–69` compiles
`runtime/avra_runtime.c` and `backend/llvm_wrapper.c` with plain `cc`.
There is no `[build]` section, no C source list, no per-object flags.
For a vendored `sqlite3.c` compiled with our own defines this matters
(BLOCKER 8).

### 2.10 The interpreter

`language/interp.av:500–506`:

```
fn rt_dispatch(callee: string, vals: List<Val>) -> Val {
    let sig: RtSig? = self.rt.get(callee)
    if sig == null {
        if self.l.externs.any(it.name == callee) { return self.unhosted_extern(callee) }
        return self.defect_val("an unknown runtime callee `${callee}` survived lowering")
    }
```

and `language/interp.av:573–577`:

```
/// An extern fn is the host's — the evaluator has no body for it.
fn unhosted_extern(callee: string) -> Val {
    self.trapped("`${callee}` is extern — the evaluator cannot host it; build natively")
    Val.I(0)
}
```

Two facts, both proven by the tree's own tests
(`features/fns/tests/fns_test.av:17, 19–21`):

- An extern whose **name collides with a registry row** IS hosted —
  `extern fn avra_now_ns() -> int` runs under `avra run` and answers
  `true`. The interpreter never checks that the declared signature
  matches the row's. MEDIUM: a mismatched redeclaration would silently
  mis-dispatch.
- Any other extern **traps**.

`rt_dispatch` is an exhaustive match over `RtHost` (`core/ir.av:270–290`)
— a hard-wired, per-symbol dispatch. There is no `dlopen`, no `dlsym`,
no libffi anywhere in `runtime/avra_runtime.c` or
`backend/llvm_wrapper.c` (grepped; zero hits). HIGH.

The evaluator's value enum (`language/interp.av:16–28`) is
`I | B | S | A | C | M | N` — **there is no pointer variant**. A `ptr`
would ride `Val.I`.

### 2.11 The proof that is already in the gate

`corpus/native/externs.av` is a running extern wall: ten declarations
including `-> string` answers, `List<string>` arguments, a `void` extern,
and a nine-argument call. `corpus/native/externs.expected` pins its
output. This is the pattern `corpus/sqlite.av` follows.

### 2.12 The honest good news — what needs NO language work

Reading the above together, these sqlite bindings are expressible
**today**, with no compiler change (MEDIUM-HIGH; read end-to-end,
unprobed):

```
extern fn sqlite3_libversion_number() -> int              // C int, small and positive
extern fn sqlite3_close_v2(db: ptr) -> int
extern fn sqlite3_finalize(stmt: ptr) -> int
extern fn sqlite3_step(stmt: ptr) -> int
extern fn sqlite3_reset(stmt: ptr) -> int
extern fn sqlite3_column_count(stmt: ptr) -> int
extern fn sqlite3_column_type(stmt: ptr, i: int) -> int
extern fn sqlite3_changes64(db: ptr) -> int               // sqlite3_int64 — exact
extern fn sqlite3_last_insert_rowid(db: ptr) -> int       // sqlite3_int64 — exact
extern fn sqlite3_errmsg(db: ptr) -> ptr?                 // ptr?, NEVER string
```

That is roughly the control skeleton of a driver. Everything that moves
*data* needs the work below.

---

## BLOCKERS

Ordered by how hard they block. Each carries a proposed shape.

### BLOCKER 1 — `int` is i64; C's `int` is i32, and a negative return reads as a huge positive

`rt_kind_of` has no i32 (`core/runtime_api.av:92–98`), so `-> int`
declares an `i64` return for a symbol that returns `i32`. The tree
already carries live instances: `backend/llvm_wrapper.c:554`
`int avra_llvm_print_module_to_file(...)` and `:577`
`int avra_llvm_verify_module_print(...)` are declared `-> int` at
`language/llvm_api.av:60–61`. They survive because their answers are
non-negative; `avra_llvm_verify_function` was deliberately written
`int64_t` (`llvm_wrapper.c:586`) — someone already saw this.

Under both mainstream ABIs the callee writes the 32-bit register
(`eax` / `w0`), which zeroes the upper half. So a C `int` of `-1` is read
by Avra as `4294967295`. MEDIUM-HIGH on the mechanism (standard
lowering); a probe would settle it in one corpus program.

SQLite exposure: `sqlite3_column_int` returns a signed `int` that is
routinely negative; so does every `int` count and index in the API.

**Proposed shape.** Grow `RtKind` with `I32` (and the rest of the widths
only when a driver needs them — resist the size soup 31.1 warns about).
`rt_kind_of` cannot infer it; the seat's **declared type** must say so,
which means the language grows `i32` as a type name
(`language/typing.av:322`'s `shape_named` table plus one `Type` variant,
or — cheaper — an `@std/c` alias resolving to a distinct `Type`). The
backend then emits `sext`/`trunc` at the seat
(`language/llvm.av:428–444` is the one place). **Size: MEDIUM.** Touches
`RtKind`'s consumers, which are named and few (`llvm.av:175–181`,
`interp.av`, `memory.av`).

### BLOCKER 2 — no `float`, at any level

The lexer scans a **digit run only** (`grammar/lexer.av:318–322`):

```
// Number: a digit run; adjacent letters lex as their own Name.
is_digit(c) -> {
    let j = scan_while(src, n, i + 1, is_digit)
    numbered(src.substring(i, j), i, j)
}
```

`1.5` lexes as three tokens. `shape_named` (`language/typing.av:317–324`)
knows `int | string | bool | void | ptr` and nothing else. `Type` has no
float variant (`core/types.av:12–70`). `RtKind` has no F64. HIGH.

Spec obligation: 31.2, "**`float` ships in v1.0**".

SQLite exposure: `double sqlite3_column_double(sqlite3_stmt*, int iCol)`
and `int sqlite3_bind_double(sqlite3_stmt*, int, double)`
(sqlite.org/c3ref/column_blob.html, /c3ref/bind_blob.html). REAL is one
of SQLite's five storage classes; a driver without it is not a driver.

**Proposed shape.** A campaign of its own, and the largest single item:
lexer (decimal point, exponent, no implicit int→float per 31.2),
`Type.Float`, the registry's `canon`/`name_of`/`ptr_shape`/`rides_pointer`
(all exhaustive — the compiler lists the sites), the `Bin` op set
(`fadd`/`fsub`/`fmul`/`fdiv`/`fcmp`), `RtKind.F64` with a real `double`
in `ll_rt_kind`, the interpreter's `Val.F`, `to_float`/`to_int`,
`Float.nan`/`infinity`, and printing. **Size: LARGE.** It is a language
milestone, not an FFI item — but the FFI is what forces it.

The ABI subtlety that must not be missed: a float argument travels in the
SSE/FP register file, not the integer file, so `RtKind.F64` is not a
relabelling of I64 — `declare_externs` must emit a real `double` type or
every float call is wrong.

### BLOCKER 3 — no owning byte value; `string` truncates at NUL

§2.8. `string` is UTF-8-by-invariant (spec:1490, 9.15) and its operators
are `strcmp`/`strstr`. A BLOB is arbitrary bytes.

SQLite exposure: `const void *sqlite3_column_blob(sqlite3_stmt*, int)`
plus `int sqlite3_column_bytes(...)`, with the docs' explicit lifetime
rule (sqlite.org/c3ref/column_blob.html):

> "The pointers returned are valid until a type conversion occurs as described above, or until sqlite3_step() or sqlite3_reset() or sqlite3_finalize() is called."

So a blob **must be copied** before the next `step`. A borrowed view
(`CStr`, 15.6) is not sufficient for a row value that outlives the step.

**Proposed shape.** Two types, where the spec has one:

- **`CStr`** (spec 15.6) — the borrowed `(ptr, len)` pair, for
  `sqlite3_bind_blob`/`bind_text` arguments. Zero-copy.
- **`Bytes`** — an owning, headered, length-carrying, NUL-safe byte box.
  The runtime already has the box: `str_box`/`box_alloc` with `KIND_STR`
  carry `h->len` (`avra_runtime.c:262–268`). `Bytes` is a new `Type`
  variant whose *operators* are length-driven (`memcmp`/`memmem`),
  sharing the allocation machinery with `Str` and none of its `strcmp`
  verbs. Conversion rows: `avra_bytes_from_c(ptr, len) -> Bytes` and
  `avra_bytes_ptr(Bytes) -> ptr`.

This is a **core value category** event (CLAUDE.md: "The protocol grows
with value categories — a core event"), needing a `bytes_of` protocol
read alongside `text_of`/`truth_of`/`elems_of`. **Size: MEDIUM-LARGE.**

### BLOCKER 4 — no out-parameters, and no pointer-to-pointer

`sqlite3_open_v2(const char*, sqlite3 **ppDb, int, const char*)` and
`sqlite3_prepare_v2(sqlite3*, const char*, int, sqlite3_stmt**, const char**)`
are the API's front door. Avra cannot form the address of a local.

**Proposed shape, and it is cheap.** The IR already has what is needed:
`Ins.Alloca(dst)` is a real LLVM alloca (`language/llvm.av:292`:
`avra_llvm_build_alloca(self.b, self.reg_type(dst), "slot")`), and
`features/emit.av:54–68` already writes `seeded_cell`/`loaded` over
`Alloca`/`Store`/`Load`. A call-site `out` seat lowers to:

```
Alloca(cell)                              // cell's reg type is the OUT type
CallRt(dst, symbol, [ …, cell, … ])       // the alloca IS the address
Load(x, cell)                             // read back after
```

**No new IR variant.** The grammar grows one keyword in the extern
parameter slot (`out ps:NAME ":" pt:type`). Paradox collapse (P6): the
extern declares `out`, the CALL SITE says nothing, and the compiler mints
the cell and changes the call's answer shape — which is the spec's own
model (15.4's `@returns_ownership(db)` names the out-param and the
wrapper returns the handle). Avra has no tuples, so the honest landing
is: an extern with exactly one `out` seat and an `@error_if`-shaped
answer generates
`fn sqlite3_open_v2(path, flags, vfs) -> Result<ptr, i32>`. That composes
15.4 with 15.7 in one step and is worth doing together.
**Size: SMALL-MEDIUM** for the mechanism, MEDIUM for wrapper generation.

### BLOCKER 5 — no ownership annotations, so every foreign allocation leaks

§2.6: `extern_row` hard-codes `owns_result: false` and
`has_owned_twin: false`; `retained_args` never runs for `CallRt`. There
is exactly one ownership policy and no way to declare another.

SQLite exposure: `sqlite3_exec`'s `char **errmsg` must be released with
`sqlite3_free`; `sqlite3_mprintf`, `sqlite3_expanded_sql` and
`sqlite3_serialize` all return memory the caller frees.

**Proposed shape.** The annotation grammar (BLOCKER 7) plus three fields
on the extern's row:

- `@borrows(p)` — today's behaviour, made explicit; `Effect.validate`.
- `@takes_ownership(p)` — the memory pass **skips** the scope's release
  for that argument's register (it is already skipping the retain).
- `@returns_ownership` + `@free_with(f)` — the answer becomes an
  `Owned<T>`: a one-field record carrying the pointer whose **Drop calls
  `f`**. Which means BLOCKER 6.

The memory pass is the right home: `managed_dst`
(`memory.av:316–327`) already asks "does this callee own its answer?"
through `rt_owns`; the fix is to ask the **extern's own row** and not
only the static registry. **Size: SMALL** once the annotations parse —
the pass has the seam already.

### BLOCKER 6 — no Drop, so `opaque type T @free_with(f)` has nowhere to land

`Drop` appears nowhere in `packages/` (grepped; zero hits). The tree has
`defer`/`errdefer` (`features/defers/mod.av:29–30`) and nothing
type-level. The spec makes Drop the **primary** resource mechanism
(9.11, spec:1345) and requires it to interleave LIFO with defer (12.7,
spec:2317).

**Proposed shape.** A `Drop` trait plus a compiler-called drop at scope
exit, plugged into the *existing* defer frames (CLAUDE.md: "A `defer`'s
FRAME IS ITS STATEMENT LIST"), so ordering is one mechanism, not two —
exactly what 9.11 demands. `opaque type SQLite3 @free_with(sqlite3_close)`
then desugars to a single-field record (the tree's typed-id idiom,
DOGFOODING.md:1055) with a generated `impl Drop`. The opacity is a
resolve-level rule (the field is unnameable outside its declaring
module), not a new representation — 15.5's "zero-size wrapper with the
pointer" is exactly the tree's FLAT record (`core/types.av:197–205`,
`mark_flat`).

**Size: MEDIUM-LARGE.** The second-largest item after `float`, and the
one that makes the driver *safe* rather than merely possible. Heed
CLAUDE.md's standing warning: a closure capturing its own owner is a
cycle counting never frees.

### BLOCKER 7 — no annotation grammar at all

`@` is refused at the statement level (CLAUDE.md, "The subset today":
`@comptime` → "expected `mod`, `use`, … while parsing `stmt`"). Every
Axis 15 ownership and error facility is an annotation. Nothing in Axis 15
can land until `@name(args)` parses.

**Proposed shape.** 30.1's syntax, prefix placement (§1.8), as a
statement-modifier branch in the same shape as `export`
(`features/modules/mod.av:51`'s `"export" d:stmt -> export_stmt(d)`).
Annotations attach to the statement they precede and land in a side table
keyed by `StmtId` — never on the node (CLAUDE.md: "Node facts (spans
included) live in side tables keyed by typed ids"). The `@`-vs-`@std/...`
disambiguation the spec promises (spec:6153) already exists in the lexer:
an `@`-word is one `TokenKind.Pkg` token
(`grammar/lexer.av:327–331`). **Size: SMALL-MEDIUM** for the grammar and
table; the *meaning* of each annotation is the work.

Also required by 30.3: `avra explain annotation @free_with`. The CLI's
one-file-per-subcommand rule (CLAUDE.md) makes that one file.

### BLOCKER 8 — the toolchain cannot build a vendored `sqlite3.c`

`[link]` has exactly two keys (`language/manifest.av:109`): `objects` and
`flags`. Objects are paths to files someone else built —
`Makefile:63–69` uses bare `cc`, outside the compiler.

The campaign needs `sqlite3.c` compiled **with our own defines**
(`SQLITE_ENABLE_COLUMN_METADATA`, `SQLITE_ENABLE_DESERIALIZE`,
`SQLITE_ENABLE_SESSION`, `SQLITE_ENABLE_PREUPDATE_HOOK`,
`SQLITE_THREADSAFE=0`, …) — which is precisely the campaign's stated
reason for rejecting the system library.

**Proposed shape.** A `[csources]` (or `[link] sources`) manifest
section: C files with per-package `cflags`, compiled by the same `CC` the
linker already resolves (`shared.av:304–309`), cached by content hash
beside the package, and joined into `link_words`'s argv. This is *not* a
C shim — it is the build system learning to build the dependency the
manifest already promises. **Size: MEDIUM**, and mostly in the CLI: one
new file plus one manifest key (`manifest.av:109` is the whole schema
check).

### BLOCKER 9 — the interpreter cannot host any extern

§2.10. Every sqlite call under `avra run` traps.

**Proposed shape**, matching the campaign's plan and the tree's grain:

1. `dlopen`/`dlsym` in the runtime C, plus a **fixed set of uniform ABI
   shapes** as registry rows — `avra_ffi_call_iN(sym, a0..aN) -> int64`,
   `avra_ffi_call_p*`, `avra_ffi_call_d*` — one row per
   `(return kind, arity)` pair. Because the seat kinds are already only
   `I64 | Ptr | Void` (plus the new `I32`/`F64`), the shape count is
   bounded and small.
2. `unhosted_extern` (`interp.av:573`) becomes a **dlsym dispatch** keyed
   by the extern's own `RtSig` — which the machine already holds on
   `Lowered.externs`.
3. The evaluator gains `Val.P(addr)`, or rides `Val.I` (`ptr` is
   unmanaged, so `Val.I` is honest).

**The catch, and it needs an owner decision:** `dlsym(RTLD_DEFAULT, …)`
finds a symbol only if it is loaded into the *interpreter's* process.
`sqlite3.o` linked into the compiled program is not. So either the
manifest names a **shared library** the interpreter dlopens (a
`[link] dylibs = [...]` key, resolved from the same manifest that names
the object for the linker), or the interpreter refuses externs whose
package declares no dylib and says exactly that. **Size: MEDIUM.**

### BLOCKER 10 — no callback / trampoline

15.3 is the whole of it. SQLite exposure, ranked by how soon it bites:

- `sqlite3_bind_text`/`bind_blob`'s fifth argument is `void(*)(void*)`
  (sqlite.org/c3ref/bind_blob.html) — but the two values that matter are
  **not real function pointers**:
  ```c
  typedef void (*sqlite3_destructor_type)(void*);
  #define SQLITE_STATIC      ((sqlite3_destructor_type)0)
  #define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
  ```
  (sqlite.org/c3ref/c_static.html). `SQLITE_TRANSIENT` is the pointer
  `(void*)-1`. Avra can express neither — `ptr` has no literal and no
  arithmetic. **A `ptr` sentinel is needed long before a trampoline is.**
  Cheapest honest answer: a runtime row
  `avra_ffi_sentinel(n: int) -> ptr` (a cast, made visible — P7), or an
  `@std/c` fn `c_transient() -> ptr`.
- `sqlite3_exec`'s callback, `sqlite3_create_function_v2`'s three
  callbacks, `sqlite3_update_hook`, `sqlite3_progress_handler`,
  `sqlite3_trace_v2` — all take `void* user_data`, so all are
  trampoline-able exactly as 15.3 describes.

**Proposed shape.** The tree already lowers a lambda into a box
`[code address, captures…]` called through `CallPtr`
(`core/types.av:53–57`, `features/values.av:163–188`), and already emits
per-lambda bodies (`language/lower.av:238`, `lower_lambda`). A trampoline
is a **second** generated body per lambda type: C-ABI parameters in,
unpack `user_data` (which is the capture box), call the Avra body, return
the result. 15.3's lifetime rule ("trampolines hold the closure's
captures alive for the duration of the C API's use") maps onto retaining
the capture box for the call's scope. **Size: LARGE**, and correctly
LAST — the driver's whole read/write path works without it, and
`sqlite3_exec` is better written over `prepare`/`step`/`finalize` anyway.

### BLOCKER 11 — no variadics

`declare`'s `variadic` flag exists and is always `false`
(`language/llvm.av:189–195`; `declare_externs` at `:168–173` passes
`false`). No grammar spells it. `int sqlite3_config(int, ...)` is
variadic (sqlite.org/c3ref/config.html).

**Proposed shape.** SMALL: a grammar `,` `...` in the extern parameter
list, one `bool` on the row, thread it to the existing knob. Extra
arguments are typed by their own shapes and pass with C's default
promotions — which for `I64`/`Ptr` seats is already what happens. Worth
landing early precisely because it is nearly free.

### BLOCKER 12 — `ptr` has no null literal and no comparison

`comparable` is `Int | Bool | Str` (`features/checks.av:427–429`).
`p == null` on a `ptr` is refused with "`==` compares scalars for now"
(`features/expr_spine/check.av:255`); the help for `.Ptr` reads "compare
scalars or strings" (`expr_spine/check.av:170`) — wrong advice at an FFI
seat.

**But `ptr?` already works** (§2.4) — a niche nullable whose presence
test is `!= 0`. So the *language* answer exists; what is missing is
(a) declaring extern answers as `ptr?` in the driver, and (b) a way to
hand C a NULL. **Proposed shape:** let `null` widen into a `ptr?`
argument seat (it already widens through `adopted`,
`features/values.av:294–300`, where a niche adoption is identity), and
fix the `.Ptr` compare help to point at `ptr?`. **Size: SMALL.**

---

## PART 4 — THE DELTA TABLE

Sizes are estimates (LOW confidence on the sizes, MEDIUM on the
ordering), read from the exhaustive-match consumer lists the tree names.

| # | Spec feature | Spec cite | What exists today | What is missing | Gap |
|---|---|---|---|---|---|
| 1 | `extern fn name(p: T) -> R` | 15.2 | **whole** — `fns/mod.av:32` | annotations, `out`, variadics, generics (never) | — |
| 2 | Bare-symbol linkage | 15.1 | **whole** — `decls.av:654`, `llvm.av:168` | — | — |
| 3 | Zero-overhead native call | 15.1 | **whole** — `CallRt`, `fns/lower.av:39` | — | — |
| 4 | `@borrows(p)` | 15.4 | **behaviour, not syntax** — `memory.av:190` | the annotation that *declares* it | S |
| 5 | `@takes_ownership(p)` | 15.4 | nothing | annotation + memory-pass arm | S |
| 6 | `@returns_ownership` | 15.4 | nothing (`extern_row` pins `false`, `runtime_api.av:104`) | annotation + `Owned<T>` + release | M |
| 7 | `@returns_borrowed(from:)` | 15.4 | nothing | annotation + a lifetime model the tree has none of | L |
| 8 | `@free_with(f)` | 15.4, 15.5 | nothing | annotation + **Drop** | L |
| 9 | `opaque type T` | 15.5 | nothing (flat records are the representation, `types.av:197`) | declaration syntax, opacity rule, generated Drop | M |
| 10 | Automatic `int` → C mapping | 15.2 | **i64 only** — `runtime_api.av:92` | i32 and the rest of the widths | M |
| 11 | `i32`/`u8`/… at the boundary | 15.2, 31.1 | nothing | type names + `RtKind` + seat coercion | M |
| 12 | `float` / `f64` | 31.2 (**v1.0**) | **nothing at all** — `lexer.av:319` | lexer, `Type`, ops, `RtKind.F64`, interp, print | **XL** |
| 13 | `BigDecimal` (`@std/numbers`) | 31.3 (**v1.0**) | nothing | a library over text or big-int arithmetic | L |
| 14 | `CString` | 15.2, 15.6 | `string` crosses raw (unlawful for foreign answers, §2.7) | the type, `CString.from` (fallible on NUL), scope-freed | M |
| 15 | `CStr` (ptr+len view) | 15.6 | nothing | the type + a two-seat expansion at the call | M |
| 16 | Owning bytes | — (spec hole) | nothing; `string` truncates (`avra_runtime.c:475`) | `Bytes` core value category | M-L |
| 17 | `@error_if` / `@error_null` / `@error_map` | 15.7, 12.12 | nothing | annotations + wrapper generation + name shadowing | M |
| 18 | Trampolines for closures | 15.3 | lambdas + `CallPtr` exist (`values.av:188`) | the C-ABI second body per lambda type | L |
| 19 | Variadics | — (spec hole) | the knob, always `false` (`llvm.av:195`) | grammar + one row field | **S** |
| 20 | Out-params / `*mut *T` | 15.4 ex., 15.5 ex. | `Alloca`/`Store`/`Load` exist (`llvm.av:292`) | grammar + call-site lowering | S-M |
| 21 | `ptr` NULL test | — | **`ptr?` works** (`values.av:228`) | `null` into a `ptr` seat; better help text | S |
| 22 | `ptr` sentinels (`SQLITE_TRANSIENT`) | — | nothing | one `@std/c` fn or runtime row | S |
| 23 | Extern under the interpreter | — (tree law) | traps (`interp.av:573`) | dlopen/dlsym + shape rows + `[link] dylibs` | M |
| 24 | Building vendored C | — | `[link] objects/flags` only (`manifest.av:109`) | a C-sources manifest section | M |
| 25 | `@ffi_binding`, `@allow(non_canonical_name)` | 28.x (spec:5631) | nothing (no naming lint either) | the annotations, once #4 lands | S |
| 26 | `avra explain annotation` | 30.3 | nothing | one CLI file | S |
| 27 | `@std/c` package | 15.2 | nothing | the package | S-M |
| 28 | Tier 2/3 bridges | 15.1 | nothing | **out of scope** | — |

S ≈ a slice. M ≈ a milestone. L ≈ a lane. XL ≈ a campaign of its own.

---

## PART 5 — PROPOSED LANDING ORDER

Cheapest first. Each is justified by what the **sqlite driver** cannot do
without it — nothing here is landed for the spec's sake alone.

**Wave 0 — free wins, no design debt (S each)**

1. **`ptr?` in the driver, and `null` into a `ptr` seat.** Nothing to
   build for the first half (§2.4); the second is one widening edge.
   *Why sqlite:* `sqlite3_errmsg` returns NULL when there is no error;
   `sqlite3_column_text` returns NULL for a NULL column; `sqlite3_open_v2`'s
   `vfs` argument is normally NULL. Without this, each is undetectable or
   unpassable.
2. **Variadics** (BLOCKER 11). One grammar token, one row field, one knob
   already present.
   *Why sqlite:* `sqlite3_config(SQLITE_CONFIG_*, …)` is the only way to
   configure the library before `sqlite3_initialize`, and it is variadic.
3. **A `ptr` sentinel verb** (BLOCKER 10's first bullet).
   *Why sqlite:* `SQLITE_TRANSIENT` is `(void*)-1`. Every
   `sqlite3_bind_text`/`bind_blob` that does not want to manage the
   caller's buffer passes it. There is no bind path without this.

**Wave 1 — the boundary types (M each), in this order**

4. **`i32` seats** (BLOCKER 1). Before any data path, because every
   SQLite result code and every `bind`/`column` index is a C `int`, and a
   wrong-width read is a silent wrong answer, not a crash.
   *Why sqlite:* `sqlite3_column_int` can return a negative value.
5. **`CString`, and the ban on `string` as a foreign answer** (§2.7).
   Includes the runtime rows `avra_cstring_from(string) -> ptr`
   (scope-freed) and `avra_string_from_c(ptr) -> string` (a **copy** into
   a headered box).
   *Why sqlite:* `sqlite3_open_v2`'s path and every `prepare`'s SQL text
   go out; `sqlite3_errmsg` and `sqlite3_column_text` come back, and
   coming back as `string` today is a header-law violation.
6. **Out-parameters** (BLOCKER 4). The IR already has `Alloca`.
   *Why sqlite:* `sqlite3_open_v2` and `sqlite3_prepare_v2` are the only
   ways to get a `sqlite3*` and a `sqlite3_stmt*`. Without out-params
   there is no driver at all.

At the end of Wave 1 the driver can open a database, prepare a statement,
step it, read INTEGER and TEXT columns, bind INTEGER and TEXT parameters,
read errors, and finalize — **natively**. That is a real, testable
milestone and the right place for the first `corpus/sqlite.av`.

**Wave 2 — correctness and ergonomics (M each)**

7. **The annotation grammar** (BLOCKER 7). Nothing in Axis 15 lands
   without it, and it is a general language facility, not FFI-specific.
8. **`@error_if` / `@error_null`** (delta #17).
   *Why sqlite:* roughly 200 entry points return an `int` result code.
   12.12's own rationale is exactly this: "wrapping something like libcurl
   or libxml requires hundreds of FFI bindings… each becomes a single
   line". Written by hand instead, the driver is a thousand lines of
   `if rc != 0`.
9. **`@borrows` / `@takes_ownership` / `@returns_ownership` /
   `@free_with`** (BLOCKER 5). The memory pass has the seam
   (`memory.av:316–327`).
   *Why sqlite:* `sqlite3_exec` writes a `char**` the caller must release
   with `sqlite3_free`; leaking it on every failed statement is not
   acceptable in substrate something else is built on.
10. **The interpreter's dlsym hosting** (BLOCKER 9), with the
    `[link] dylibs` decision.
    *Why sqlite:* the tree's `eval == native` law (CLAUDE.md, the IR
    protocol) is what keeps the two engines honest. Land it before the
    driver is large, or the corpus can only prove one engine and the
    campaign's own promise goes unkept.

**Wave 3 — the data model completes (L each)**

11. **`float`** (BLOCKER 2). XL, and a v1.0 spec obligation (31.2), so it
    deserves its own lane — but it must land before the driver claims
    full surface.
    *Why sqlite:* REAL is one of five storage classes.
    `sqlite3_column_double` has no honest binding today.
12. **`Bytes`** (BLOCKER 3) and **`CStr`**.
    *Why sqlite:* BLOB is the fifth storage class, and
    `sqlite3_column_blob`'s pointer dies at the next `step`
    (sqlite.org/c3ref/column_blob.html) — the value must be copied into an
    owning box.
13. **Drop + `opaque type`** (BLOCKERS 6 and 9's type half).
    *Why sqlite:* 15.5's own motivating example. A `Db` that closes itself
    and a `Stmt` that finalizes itself are what make the driver safe to
    hand to the ORM. Until then every user writes `defer` pairings — which
    15.5 names as the problem it exists to solve.

**Wave 4 — last, and only when a real caller asks**

14. **Trampolines** (BLOCKER 10).
    *Why sqlite, and why last:* `sqlite3_exec`, custom SQL functions,
    `update_hook`, `progress_handler`, virtual tables. Every one has a
    prepare/step alternative or is an extension of the driver rather than
    its core. Landing 15.3's hardest machinery early would be building for
    a surface nobody has asked for.
15. **`@std/numbers`' `BigDecimal`** — 31.3, for the ORM's money column.
    It rides TEXT in SQLite, so it is a library over `string` (or
    `Bytes`), not a storage-class question. **It does not block the
    driver.**

**Deliberately not scheduled, with the reason recorded:**
`@returns_borrowed(from: param)` (15.4). The tree has no lifetime model
at all (9.8's inferred lifetimes are v1.x systems level, spec:1243), and
inventing one for a single annotation is the wrong shape. The driver gets
the same safety from `Bytes` (copy at the boundary) — the copy is exactly
the "visible cost" 15.1 licenses.

---

## PART 6 — DESIGNING FOR THE LATER EXPANSIONS

Two constraints to hold now, so neither expansion needs a rewrite.

**Compile-time-checked SQL.** The compiler already holds per-declaration
fact tables and a memoizing query kernel (`query/`, CLAUDE.md's layering
rule). A schema-aware SQL check is a *pass* over a fact the driver
records, not a driver feature. The constraint that matters today: **the
SQL text must reach the compiler as a literal it can read** — so the
driver's `prepare` must take a `string`, never a runtime-assembled
`CString`, on its primary path. Keep the `CString` conversion inside the
driver, below the API.

**SQLite as the backing store for `table<Row> { … }`.** `table` is
already sugar over field defaults (ROADMAP.md:1574–1576, rung 14) and the
tables feature exists (`features/tables/`). The constraint: the driver's
row-reading path must be expressible as a **generic** over `Row`, which
means the column readers must be a trait, not a match, so the later
`table` binding can implement it per declared row type. Write
`ColumnRead` as a trait from day one, even though the driver's first
caller is concrete.

---

## CONFIDENCE LEDGER

| Claim | Confidence | How verified |
|---|---|---|
| Axis 15's seven sub-decisions, quoted | HIGH | Read `2026_04_18_FULL_SPEC.md:2873–3079` in full; grepped the whole file for `opaque`, `extern`, `CString`, `free_with`, the ownership words, `variadic`, `trampoline` — no Axis-15 material outside those lines |
| 12.12 is 15.7's fuller statement | HIGH | `spec:2537–2562`, and 15.7's own "See full details in decision 12.12" (`spec:3065`) |
| The FFI annotations require Axis 30's `@name(args)` | HIGH | `spec:6112–6156`; 30.1's own example is `@takes_ownership(s)` on an extern (`spec:6136–6137`) |
| The spec contradicts itself on FFI's version (v1.x vs v2.0 vs "FFI via bare level") | HIGH | `spec:1683`, `1688`, `2561` against Axis 15's seven "ships in v1.x" lines |
| `float` is a **v1.0** obligation | HIGH | `spec:6314` |
| The spec never defines `*T` / `*mut *T`, variadics, out-param mechanics, `Owned<T>`, or `@std/c`'s contents | HIGH | Grepped the whole spec for each; only example usages, no sub-decision |
| Extern grammar is exactly one line; params are always typed | HIGH | `features/fns/mod.av:32`, compared to the `fn_decl` line at `:33` |
| No annotation grammar exists in the tree | HIGH | No `@` item in any feature's `gram`; CLAUDE.md's "The subset today" records the `@comptime` refusal |
| The extern symbol is the bare name, unmangled | HIGH | `features/decls.av:652–654` |
| `RtKind` is `I64 \| Ptr \| Void` only | HIGH | `core/runtime_api.av:92–98`; `language/llvm.av:175–181` |
| Extern args are borrowed; the answer is never released | HIGH | `language/memory.av:124, 130, 190–196, 316–327`; `core/runtime_api.av:101–104` |
| The variadic knob exists and is always `false` | HIGH | `language/llvm.av:189–195`, `168–173` |
| Avra `string` is a NUL-terminated `const char*` with a 16-byte header | HIGH | `runtime/avra_runtime.c:56–73, 244–275` |
| `==`, `contains`, `index_of`, `replace`, `split` truncate at NUL; `.length` does not | HIGH | `avra_runtime.c:475–478, 1144, 1159, 1208, 1234` against `272–275` |
| No `float`: the lexer scans a digit run only | HIGH | `grammar/lexer.av:318–322`; `language/typing.av:317–324`; `core/types.av:12–70` |
| No `Drop` anywhere in the tree | HIGH | Grepped `packages/` for `Drop`, `destructor`, `drop_of` — zero hits |
| The interpreter traps on any extern the static registry does not name | HIGH | `language/interp.av:500–506, 573–577`; proven by `features/fns/tests/fns_test.av:17` |
| No dlopen/dlsym/libffi in the runtime or the wrapper | HIGH | Grepped `runtime/avra_runtime.c` and `backend/llvm_wrapper.c` — zero hits |
| `[link]` has exactly two keys | HIGH | `language/manifest.av:109` |
| Link words become argv elements on clang's line | HIGH | `language/workspace.av:948–969`; `packages/cli/src/commands/shared.av:276–291` |
| `ptr` is unmanaged, pointer-riding, and not comparable | HIGH | `language/memory.av:42–43`; `core/types.av:118–125`; `features/checks.av:427–429` |
| `ptr?` is a niche nullable whose presence test is `!= 0`, and rides `RtKind.Ptr` | MEDIUM-HIGH | `features/values.av:228–232, 243–250`; `core/types.av:184–186, 248–258`; `core/runtime_api.av:92–98`. Read end-to-end; **not probed** — one scratch `./avra check` would settle it |
| `Ins.Alloca` is a real LLVM alloca, so out-params need no new IR variant | HIGH | `language/llvm.av:292`; `features/emit.av:54–68` |
| A C `int` return read as Avra `int` yields a huge positive for negative values | MEDIUM-HIGH | The mechanism is the standard x86-64/AArch64 32-bit return lowering; the live mismatch is `backend/llvm_wrapper.c:554, 577` against `language/llvm_api.av:60–61`. **Needs a probe** on this toolchain |
| `export extern fn` parses and passes the module law | MEDIUM | `features/modules/mod.av:51`; `features/modules/check.av:13`; `core/parts.av:232`. Cross-package resolution unread |
| SQLite prototypes for the bind and column families | HIGH | sqlite.org/c3ref/bind_blob.html, sqlite.org/c3ref/column_blob.html (fetched 2026-09-05) |
| `SQLITE_TRANSIENT` is `((sqlite3_destructor_type)-1)`, `SQLITE_STATIC` is `0` | HIGH | sqlite.org/c3ref/c_static.html (fetched 2026-09-05) |
| `sqlite3_config` is variadic | HIGH | sqlite.org/c3ref/config.html (fetched 2026-09-05) |
| Column blob/text pointers die at the next `step`/`reset`/`finalize` | HIGH | sqlite.org/c3ref/column_blob.html, quoted in BLOCKER 3 |
| `sqlite3_db_config`, `sqlite3_mprintf`, `sqlite3_vtab_config` are variadic | LOW | Not fetched; asserted from memory of `sqlite3.h`. Verify before relying on it |
| Gap sizes (S/M/L/XL) and the wave boundaries | LOW–MEDIUM | Estimated from the exhaustive-match consumer lists the tree names (`core/ir.av:185–210`, the IR protocol's eight consumers), not from a spike |

**Next free idiom number: I37** (DOGFOODING.md:62 ratchets through I36).
Any pattern this campaign discovers lands there at discovery, with a
matcher or an UNRATCHETED reason.
