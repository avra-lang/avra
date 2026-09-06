# The interpreter's extern host — dlsym plus a fixed shape table

Lane sqlite research, 2026-09-05. Scope: the mechanism by which the
IR interpreter calls an arbitrary `extern fn`, so `avra run` hosts
every binding and eval == native holds for the FFI by construction.

WHAT THIS ESTABLISHES: the mechanism is SOUND, and it collapses
further than the campaign assumed — **one argument block and six
return casts cover the whole of SQLite**, because integer and
floating-point arguments ride SEPARATE register files on both
targets and a callee ignores the argument registers it does not
declare. It also establishes that the seam has a defect TODAY,
independent of the interpreter: **a foreign 32-bit `int` result is
read as 64 bits, so a negative `int` comes back as 4294967295** —
the native backend is wrong before the interpreter is written. And
it establishes that `dlsym(RTLD_DEFAULT, …)` alone CANNOT reach
sqlite: `avra run` interprets inside `build/avra`, which never links
the program's `[link]` words, so the foreign tier needs `dlopen` —
and `dlopen` runs a library's initializers, which is the
supply-chain shape the tree already paid for once.

---

## 0. The seam as it stands

Read, not inferred:

- `Lowered` carries the program's externs as registry rows —
  `externs: List<RtSig>` (`language/lower.av:30-39`), built by
  `extern_rows` / `extern_row_of` (`:47-56`).
- `extern_row_of` collapses every declared type through
  `rt_kind_of` into `RtKind.I64 | .Ptr | .Void`
  (`core/runtime_api.av:110-114`), and pins
  `owns_result: false, has_owned_twin: false, host: RtHost.Unhosted`
  (`:119-121`).
- Lowering emits an extern call as a runtime call by its bare
  symbol — `CallRt` / `CallRtVoid` (`features/fns/lower.av:41-51`).
  No new instruction; the IR already carries it.
- The backend declares every extern row like a runtime row —
  `declare_externs` (`language/llvm.av:169-173`), through
  `ll_rt_kind` (`:175-181`), always `i64` for `RtKind.I64`,
  `variadic = false` (`:189-195`).
- The interpreter dispatches a runtime call by the registry's host
  column; a callee the registry does not name, but the program's
  externs do, TRAPS (`language/interp.av:501-505`), with the voice
  `unhosted_extern` (`:572-576`).
- Therefore an extern whose name IS a registry row is already
  hosted: `avra_now_ns()` answers under the evaluator
  (`features/fns/tests/fns_test.av:19-21`). The gap is names the
  registry does not know.
- `.Ptr` is UNMANAGED (`language/memory.av:29-45`), so no retain,
  no release, no cell settling touches a foreign pointer. The
  memory pass needs nothing.
- `avra run` interprets IN PROCESS: `Program.run()` calls
  `run_lowered` (`language/workspace.av:1068-1071`,
  `language/interp.av:54-56`). The program's `[link]` words reach
  clang only at BUILD time (`cli/src/commands/shared.av:277`).

So the change is bounded: **one branch in `rt_dispatch`, a widened
`RtKind`, and one C translation unit.** No IR variant, no memory-pass
change, no `RtHost` variant (the trampolines are called from
interp.av's own `extern fn` declarations, exactly as
`avra_proc_spawn` is at `interp.av:888` — they are not part of the
lowered vocabulary and so earn no `rt_sigs()` row).

---

## 1. THE ABI ANALYSIS

### 1.1 AAPCS64 (AArch64, the base standard)

Argument allocation runs three stages with three counters — NGRN
(next general-purpose register), NSRN (next SIMD/FP register), NSAA
(next stacked argument address), all initialized at Stage A.

- An **integral or pointer** argument of ≤8 bytes with NGRN < 8 goes
  in `x[NGRN]`; NGRN increments. Eight integer registers, `x0`–`x7`.
- A **floating-point** argument with NSRN < 8 goes in the least
  significant bits of `v[NSRN]`; NSRN increments. Eight FP
  registers, `v0`–`v7`. **A SEPARATE FILE** — an integer argument
  never consumes an FP register and the reverse. This is the fact
  the whole shape table rests on.
- When a file is exhausted, the argument goes to the stack at NSAA,
  which then advances. Arguments already in registers do not
  reserve stack.
- Results: an integral or pointer result in `x0`; a
  floating-point result in `v0`; a result whose size the caller
  cannot determine is returned indirectly through a caller-allocated
  buffer whose address rides `x8`.
- **"The unused bits in a register holding an argument smaller than
  8 bytes are unspecified."** In the base standard the CALLEE
  extends narrow arguments; the caller may leave garbage above them.

### 1.2 Apple's three divergences (arm64, macOS and iOS)

Apple's platform ABI is AAPCS64 with named exceptions. Three matter:

1. **VARIADIC ARGUMENTS GO ON THE STACK.** Under Apple's ABI every
   argument past the last NAMED parameter is passed on the stack,
   8-byte aligned, never in `x0`–`x7` or `v0`–`v7`. The base
   standard passes them in registers exactly like named arguments.
   The structural evidence is `va_list` itself: on Linux/AArch64 it
   is a struct of `__stack`, `__gr_top`, `__vr_top`, `__gr_offs`,
   `__vr_offs` — a register save area, needed only because
   registers carry variadic arguments; on Darwin it is a plain
   pointer, because there is nothing but stack to walk.
   **CONSEQUENCE: a variadic C function cannot be called through a
   non-variadic prototype on Apple silicon.** `sqlite3_mprintf`,
   `sqlite3_config`, `sqlite3_db_config`, `sqlite3_vtab_config`,
   `sqlite3_snprintf`, `sqlite3_str_appendf`, `sqlite3_log` and
   `sqlite3_test_control` are all variadic (`sqlite3.h`, 8 of 284
   public entry points).
2. **THE CALLER EXTENDS NARROW ARGUMENTS.** Where the base standard
   leaves the unused bits unspecified and makes the callee extend,
   Apple requires the caller to sign- or zero-extend an argument
   smaller than 32 bits, up to 32 bits, and lets the callee rely on
   it. Harmless for us: we pass full 64-bit words, and two's
   complement truncation makes a narrow read of a wide word correct
   in both signs.
3. **STACK SLOTS ARE NATURALLY SIZED, NOT ROUNDED TO 8.** A
   4-byte argument on the stack occupies four bytes, not eight;
   padding appears only to satisfy alignment. The base standard
   rounds each stacked argument up to 8. **CONSEQUENCE: a callee
   whose OVERFLOW arguments (past the 8th integer) include a narrow
   type has a stack layout a uniform all-`int64_t` shape cannot
   reproduce.** SQLite is safe here — its three functions of more
   than eight arguments (`sqlite3_create_window_function` at 10,
   `sqlite3_create_function_v2` and `sqlite3_table_column_metadata`
   at 9) overflow only pointers — but the law must be stated and
   the refusal must exist.

### 1.3 x86-64 System V

- Integer/pointer arguments: `%rdi, %rsi, %rdx, %rcx, %r8, %r9` —
  **SIX**, not eight.
- Floating-point arguments: `%xmm0`–`%xmm7` — eight, a separate
  file, allocated in order among FP arguments.
- Overflow, in either class, goes on the stack in SOURCE order,
  each argument in one or more eightbytes; the caller cleans.
- Results: INTEGER class in `%rax` (then `%rdx`); SSE class in
  `%xmm0` (then `%xmm1`); MEMORY class through a hidden pointer.
- **Variadic:** `%al` is a hidden argument carrying the number of
  vector registers used — an UPPER BOUND, not an exact count. The
  callee's prologue saves the general-purpose argument registers
  unconditionally and guards the `%xmm` spill on `%al` being
  non-zero. So an integer-only variadic call through a non-variadic
  prototype happens to work on this target. It does not on Apple
  arm64, and that is what decides the rule.

### 1.4 Calling through a wrong-but-compatible prototype

**By the language: undefined.** C11 6.5.2.2p9 — calling a function
through a pointer to a type incompatible with the function's
definition is undefined behavior. There is no reading under which
this is standard-conforming, and no report should pretend otherwise.

**By the two ABIs: well-determined**, under four conditions, all of
which are checkable at the declaration:

1. **Every argument the callee READS must be in the register or
   stack slot the callee's own prototype assigns it.** Because the
   two register files are allocated independently and in class
   order, a call whose integer values are supplied in their relative
   order and whose FP values are supplied in theirs produces the
   same register state as the callee's true prototype, WHATEVER the
   source-level interleaving. `long f(long,long,double)` and
   `long f(double,long,long)` both put the two longs in `x0,x1`
   (`rdi,rsi`) and the double in `d0` (`xmm0`).
2. **Extra arguments are harmless.** Argument registers are
   caller-saved on both ABIs, and stack arguments are caller-cleaned
   on both. A callee that declares three parameters and is handed
   eighteen reads three and ignores fifteen. Nothing in either ABI
   lets a callee observe the count.
3. **The callee must not be variadic** (§1.2, divergence 1), must
   take no argument by value that is a struct, union or array
   (those classify by field and may split across registers or ride
   memory), and must have no `long double`/`__int128`/vector
   parameter.
4. **The RETURN TYPE MUST BE EXACT.** This is the one place where
   "compatible enough" is false, and it is the finding of this
   section.

**BUILD-FLAG CONSTRAINT:** clang's `-fsanitize=function` (included
in `-fsanitize=undefined`) traps precisely on an indirect call
through a mismatched function-pointer type, and `-fsanitize=cfi-icall`
does the same. The trampoline translation unit must carry
`__attribute__((no_sanitize("function")))` or be compiled without
them. Not a problem today (the tree builds with `-w -O1`,
`Makefile:38`); a trap waiting for the day someone turns UBSan on.

**POINTER AUTHENTICATION:** on `arm64e` a raw code pointer must be
signed before an indirect call. macOS user binaries are `arm64`, not
`arm64e`, so this does not bite; it would on iOS. (MEDIUM confidence
— inferred from the arm64/arm64e split, not probed here.)

### 1.5 THE RETURN-WIDTH LAW — and a live defect

Neither ABI guarantees the bits above a narrow result. AAPCS64's
"unused bits are unspecified" governs `x0` on return as it governs
`x0` on entry; System V assigns `%rax` to the INTEGER class without
promising anything above the result's own width.

In practice both compilers materialize a 32-bit result with a
32-bit write (`mov w0, …` on arm64, `mov eax, …` on x86-64), which
zeroes the upper half. **So a negative `int` result reads back, at
64 bits, as its unsigned image.**

`declare_externs` (`language/llvm.av:169-173`) declares EVERY extern
returning `RtKind.I64` as `i64`, and `rt_kind_of`
(`core/runtime_api.av:110-114`) maps Avra's `int` there. Avra's
`int` is 64 bits; C's `int` is 32.

- `sqlite3_column_int` returns C `int`. A column holding `-1` will
  answer **4294967295** in a program that declares
  `extern fn sqlite3_column_int(s: ptr, i: int) -> int`. Both
  engines will agree — on the wrong answer. eval == native is not
  the same property as correct.
- The tree already has two instances, right by accident:
  `backend/llvm_wrapper.c:554` `int avra_llvm_print_module_to_file`
  and `:577` `int avra_llvm_verify_module_print`, declared
  `-> int` at `language/llvm_api.av:60-61` and read only as
  `!= 0` (`language/llvm.av:71`) or discarded (`:154-155`). Their
  values are 0 and 1, and a `mov w0, #0` zeroes `x0`. The
  neighbouring `avra_llvm_verify_function` was written `int64_t`
  (`llvm_wrapper.c:585`) — the convention is unpoliced, not
  observed.

This is the same shape as the ROADMAP's foreign-`string` finding
(`ROADMAP.md:1605-1638`): the seam works often enough to be trusted
and fails exactly where the driver lives. It is a BLOCKER, and it is
a blocker for the NATIVE path, not only the interpreted one.

---

## 2. THE SHAPE TABLE

### 2.1 The measurement

`sqlite3.h` (macOS SDK, SQLite 3.51), 284 public entry points:

| arity | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| count | 13 | 104 | 69 | 36 | 23 | 15 | 8 | 3 | 2 | 2 | 1 |

- Maximum integer-class arity: **10** (`sqlite3_create_window_function`).
- Functions touching `double`: **four**, and they need one FP
  argument at most — `sqlite3_bind_double(stmt, i, double)`,
  `sqlite3_result_double(ctx, double)`, `sqlite3_column_double →
  double`, `sqlite3_value_double → double`.
- Struct or union passed or returned BY VALUE: **none**.
- `float` (f32) anywhere: **none**.
- Variadic: **eight**.
- Return types: `int` ×153, `void` ×40, a pointer ×57,
  `sqlite3_int64` ×9, `double` ×2, `sqlite3_uint64` ×1,
  `unsigned int` ×1.

### 2.2 The collapse

The naive table is combinatorial: with each of N arguments either
integer-class or FP, the shapes number 2^N per arity per return
kind — ~2000 for N ≤ 8. **It does not need to be.**

Two facts from §1 do the work. (i) The register files are
independent and each is filled in class order, so the mapping from
"the k-th integer value" to a machine location is fixed regardless
of interleaving. (ii) A callee cannot observe arguments it does not
declare. Therefore ONE prototype, always fully applied, serves every
callee whose integer-class arity is ≤ MAX_I and whose FP arity is ≤ 8:

```c
#define AVRA_FFI_MAX_I 10   /* SQLite's maximum, named not guessed */
#define AVRA_FFI_MAX_F 8    /* the FP file's depth on both targets */
```

The canonical prototype puts all integer parameters first, then all
double parameters. On arm64 that fills `x0`–`x7`, spills `i8,i9` to
`[sp+0]`,`[sp+8]`, and fills `d0`–`d7`. On x86-64 it fills
`rdi..r9`, spills `i6..i9` to `[rsp+0..24]`, and fills `xmm0`–`xmm7`.
In both cases the k-th stacked integer of the SHAPE lands exactly
where the k-th stacked integer of any all-integer callee lands,
because the doubles never reach the stack. A callee reading fewer
arguments reads a prefix; a 10-argument callee reads all of them.

Only the RETURN needs distinct casts, and the widths that occur are
few. **Six**:

```c
enum { FFI_VOID, FFI_I32, FFI_U32, FFI_I64, FFI_F64, FFI_F32 };
```

`FFI_I64` also serves `uint64_t` and every pointer — the register
read is identical and the value is opaque to Avra. `FFI_F32` earns
its place for generality, not for SQLite.

### 2.3 The C surface

```c
/* runtime/avra_runtime.c — THE FOREIGN CALL. A callee reads the
   argument registers it declares and ignores the rest, so one
   fully-applied prototype serves every non-variadic scalar
   signature of at most AVRA_FFI_MAX_I integer and AVRA_FFI_MAX_F
   floating arguments. The RETURN is the one thing that must be
   exact: a narrow result leaves the bits above it unspecified. */

typedef int64_t (*ffi_i64)(int64_t,int64_t,int64_t,int64_t,int64_t,
                           int64_t,int64_t,int64_t,int64_t,int64_t,
                           double,double,double,double,
                           double,double,double,double);
typedef int32_t  (*ffi_i32)(/* … the same eighteen … */);
typedef uint32_t (*ffi_u32)(/* … */);
typedef void     (*ffi_void)(/* … */);
typedef double   (*ffi_f64)(/* … */);
typedef float    (*ffi_f32)(/* … */);

/* The symbol, or NULL. `lib` empty means the running image. */
__attribute__((no_sanitize("function")))
int64_t avra_ffi_symbol(const char* lib, const char* name);

/* One foreign call. `words` and `texts` are Avra lists of the same
   length; bit i of `text_mask` says slot i's value is the text's
   address. `reals` is the FP lane. The answer is the callee's, in
   an int64 word; a double answer rides its bit pattern. */
__attribute__((no_sanitize("function")))
int64_t avra_ffi_call(int64_t fn, int64_t ret_kind,
                      void* words, void* texts, int64_t text_mask,
                      void* reals);
```

`words`, `texts` and `reals` arrive as `AvraArray*`
(`runtime/avra_runtime.c:514-523`) — the same convention
`avra_proc_spawn` already uses for `List<string>`
(`runtime/avra_runtime.c:1683`). A `List<string>`'s slots ALREADY
hold `const char*`, so the merge is one branch per slot and no
per-argument conversion:

```c
iargs[i] = (text_mask >> i) & 1
         ? (int64_t)(uintptr_t)texts->data[i]
         : words->data[i];
```

The text lane also fixes the lifetime for free: the interpreter's
`List<string>` is a live local across the call, and every Avra
string is NUL-terminated (`str_owned` writes `buf[n] = '\0'`,
`runtime/avra_runtime.c:1122-1128`; `str_static` copies `n+1`,
`:302-307`).

An answer of `FFI_I64` returns the word. `FFI_I32` returns
`(int64_t)(int32_t)…` — the sign extension the native backend must
also emit. `FFI_U32` zero-extends. `FFI_F64`/`FFI_F32` return the
double's bit pattern, so **the FP lane needs no `float` in the
Avra type system to exist**: the integer lanes can land first and
`float` extends them.

### 2.4 The Avra side

`interp.av:501-505` becomes:

```avra
let sig: RtSig? = self.rt.get(callee)
if sig == null { return self.hosted_extern(callee, vals) }
```

and `hosted_extern` replaces `unhosted_extern` (`:572-576`): it
finds the extern's row in `self.l.externs`, resolves the symbol
once per machine (a `Map<string, int>` beside `onces`), builds the
three lanes from `vals` by their Val variant, and calls
`avra_ffi_call` — declared as an `extern fn` at interp.av's tail
beside `avra_proc_spawn` (`:888`). **No `rt_sigs()` row, no
`RtHost` variant, no `Ins` variant.** The vocabulary does not grow.

`RtKind` does grow, and that is the right seam: it is "a slot in a
runtime signature" (`core/ir.av:206`), and the C width is exactly
that. Adding `I32, U32, F64, F32` breaks `ll_rt_kind`
(`language/llvm.av:175-181`) and `rt_kind_of`
(`core/runtime_api.av:110-114`) at compile time, which is the
guarantee the tree wants.

### 2.5 Where it does NOT collapse — and so must refuse

| shape | why the uniform call cannot host it |
|---|---|
| variadic callee | Apple arm64 reads variadic arguments from the stack (§1.2) |
| >10 integer-class arguments | past the block; raise `AVRA_FFI_MAX_I` or refuse |
| >8 FP arguments | past the FP file on both targets |
| a struct/union/array by value | classifies by field; may split registers or ride memory |
| a struct by value returned | may ride the indirect-result pointer (`x8`, or a hidden first argument) |
| `long double`, `__int128`, a vector type | their own classes |
| an overflow argument narrower than 8 bytes | Apple packs stack slots to natural size (§1.2, divergence 3) |
| `float` (f32) parameter | half of a `v` register; a double there is read wrong |

The last row is worth its own note: an f32 PARAMETER cannot be
faked with a double, but an f32 RETURN can be read correctly by
casting the pointer, which is why `FFI_F32` exists on the return
side and no f32 lane exists on the argument side.

### 2.6 Variadics, honestly

The native path CAN host them, and should: LLVM knows the Darwin
rule, so `declare i32 @sqlite3_db_config(ptr, i32, ...)` plus a
variadic call site lowers correctly on both targets.
`declare` already takes the flag (`language/llvm.av:189-195`,
`vararg`) and is hard-wired `false` at both call sites (`:171`,
`:187`). What is missing is the SPELLING — the extern grammar has
no `...` (`features/fns/mod.av:32`).

The interpreter cannot follow with one uniform shape, but it does
not need one: the variadic tails SQLite actually wants are
integer-only and short (`sqlite3_db_config(db, op, int, int)`,
`sqlite3_config(op, int)`). A hand-written set of variadic
trampolines — `int f(void*, int, ...)` with one, two and three
integer varargs — covers them, and everything else refuses. That
is four more C functions, enumerated at the site, not a table.

RECOMMENDED ORDER: land the non-variadic mechanism first and refuse
variadic at the declaration; add the enumerated variadic shapes when
`sqlite3_db_config` is actually needed.

---

## 3. WHAT MUST BE REFUSED, AND WHERE

**AT THE DECLARATION, never at the call.** A signature the
mechanism cannot host is a fact about the declaration; refusing at
the call would repeat one mistake per call site and would let a
program that never calls it pass a check. The home is
`declare_fn`'s extern arm (`language/typing_declare.av:143-144`),
whose rule bodies belong in `features/fns/check.av` with the
voices at that file's tail (CLAUDE.md: a LAW never assembles PROSE).

Drafted in this tree's register — `refusal(kind, loc, message,
label, help)`, as `features/enums/check.av:330-338` writes them.
F-codes from the next free typing code (F2055 is the highest in
use, `features/fns/mod.av:28`).

```avra
// ── The voices ──

/// A variadic host fn: Apple's arm64 ABI passes variadic arguments
/// on the stack, so no fixed shape can carry them.
fn variadic_host(mut cx: TypeCx, s: StmtId, name: string) {
    cx.emit(refusal("type.extern_shape", cx.stmt_loc(s),
        "`${name}` is variadic — a host fn's variadic tail has no fixed shape",
        "declared variadic here",
        "call the fn's fixed-arity twin, or pin the tail: `extern fn ${name}(op: i32, a: i64)`"))
}

fn too_many_seats(mut cx: TypeCx, s: StmtId, name: string, n: int) {
    cx.emit(refusal("type.extern_shape", cx.stmt_loc(s),
        "`${name}` takes ${n} word seats — the host call carries ten",
        "the eleventh seat is here",
        "a host fn past ten words is called through a fn the package links itself"))
}

fn unhostable_seat(mut cx: TypeCx, s: StmtId, name: string, seat: string, ty: string) {
    cx.emit(refusal("type.extern_shape", cx.stmt_loc(s),
        "seat `${seat}` of `${name}` is `${ty}` — a host seat rides one word or one double",
        "this seat",
        "hand the host a `ptr` to it; a record crosses by address, never by value"))
}

fn unwidthed_answer(mut cx: TypeCx, s: StmtId, name: string) {
    cx.emit(refusal("type.extern_width", cx.stmt_loc(s),
        "`${name}` answers `int` — a host fn's answer declares its C width",
        "the answer is here",
        "write the width the header writes: `-> i32` for C's `int`, `-> i64` for `sqlite3_int64`"))
}
```

| code | kind | refuses |
|---|---|---|
| F2056 | `type.extern_shape` | a variadic host declaration |
| F2057 | `type.extern_shape` | more than ten word seats, or more than eight double seats |
| F2058 | `type.extern_shape` | a seat that is neither a word nor a double (a record by value, a `List<T>` to a foreign library, `f32`) |
| F2059 | `type.extern_width` | a host answer spelled `int` — the C width must be declared |

F2059 is the sharp one, and it is a MIGRATION: every `extern fn …
-> int` in the tree (`language/llvm_api.av`, `language/interp.av:888-910`)
must say its width. That is the point — the tree's two accidental
cases (§1.5) get fixed by the compiler demanding a decision, which
is the exemption law applied to a seam instead of to a comment.

A softer landing exists and should be considered: warn (F4xxx)
before refusing, for one slice, so the migration is mechanical.

---

## 4. SYMBOL RESOLUTION AND THE CAPABILITY RULE

### 4.1 The finding that decides it

`avra run` interprets inside `build/avra`'s own process
(`language/workspace.av:1068-1071`). A package's `[link]` words
reach clang only when a NATIVE binary is built
(`cli/src/commands/shared.av:277`). **So the compiler's image does
not contain sqlite3, and `dlsym(RTLD_DEFAULT, "sqlite3_open")`
answers NULL.** The image tier alone cannot host the driver.

Two tiers, then, and they have very different security shapes.

### 4.2 Tier 1 — THE IMAGE. `dlsym(RTLD_DEFAULT, name)`

Reaches every symbol already loaded: the runtime's own C, the LLVM
wrapper, libLLVM, and libSystem/libc.

- Retires the trap for every extern the tree declares TODAY. That
  alone moves `corpus/native/externs.av` into the eval-and-native
  corpus — the single best proof the mechanism works.
- No loading, no initializers, no new file touched.
- **NOT harmless.** libc is in the image, so under tier 1
  `extern fn system(cmd: string) -> i32` runs a shell under
  `avra run`. Honest framing: `avra build` already grants a
  program all of libc, so tier 1 widens no BUILT program's power —
  it widens what the "just look at it" verb can do, and `avra run`
  is the verb a user points at code they have not read.

### 4.3 Tier 2 — A LIBRARY. `dlopen`

`dlopen` runs the library's initializers — `.init_array` /
`__attribute__((constructor))` / ObjC `+load` — **before any Avra
code runs**. That is arbitrary native execution named by a file
path, with no shell needed. It is a strictly worse shape than the
supply-chain execution the tree already paid for
(`ROADMAP.md:7769-7787`: a dependency's `[link] flags` spliced into
a `system()` string, fixed structurally with an argv row).

The premise that finding falsified — "a `[link]` row is the
project's own word" — is TRUE of the root package and FALSE of every
dependency. The same premise must not be re-adopted here.

### 4.4 The proposed capability rule

Conservative, and each clause names what it is defending.

1. **`avra check` and `avra build` are unchanged.** The build's
   trust boundary is decided; this design does not move it.
2. **Tier 1 is default-on for a declaration in the ROOT package or
   in a package the root reaches by a PATH dependency inside the
   workspace.** An extern declared by a remote or registry
   dependency is refused, named, and told to build. This keeps the
   corpus and `@std/sqlite` hosted with no flag — so eval == native
   holds by construction for this tree — while refusing the
   supply-chain shape by construction rather than by vigilance.
   (JUDGMENT CALL, for the owner: it trusts path dependencies. The
   tree has no registry today, so every dependency is a path
   dependency and the rule is future-proofing, not present
   protection.)
3. **Tier 2 requires BOTH:** a `[ffi] libraries = ["sqlite3"]` row
   in the ROOT package's manifest — never a dependency's, refused
   with its own voice — and an explicit `--host-externs` (or
   `AVRA_HOST_EXTERNS=1`) on the invocation. Absent either, the
   refusal names the library, the manifest key and the flag.
4. **The `[ffi]` row is a NAME, never a flag.** No `-`-leading
   token, no path a dependency can spell, resolved as
   `lib<name>.dylib` / `lib<name>.so` through the platform loader.
   This is the ROADMAP's typed-`[link]` want (`:675-678`) applied to
   a narrower surface, and it should land as that item's first
   customer. `manifest.av` grows one section
   (`:35`, `:93`, `:109` — unknown keys already ERROR).
5. **`dlopen` with `RTLD_NOW | RTLD_LOCAL`.** `RTLD_NOW` so a
   missing symbol is a load-time refusal with a name rather than a
   crash mid-interpretation; `RTLD_LOCAL` so the library's symbols
   do not join `RTLD_DEFAULT` and silently satisfy a later tier-1
   lookup. A tier-1 symbol must stay a tier-1 symbol.
6. **A resolved symbol is cached per machine, per (library, name).**
   `dlsym` on a hot path is a hash lookup in the loader; the
   interpreter already caches `once` answers this way
   (`interp.av:41`).
7. **The refusal for an unresolved symbol keeps today's register:**
   "`sqlite3_open` is extern, and no image here defines it — the
   package's `[ffi]` row names no library that has it".

### 4.5 What is still open

`dlopen` of a library that the NATIVE build would have linked
statically (a vendored `sqlite3.o` via `[link] objects`) has no
answer here: there is no shared object to open. For the vendored
amalgamation the campaign decided on
(`ROADMAP.md:1526-1533`), tier 2 needs the vendored source built
BOTH ways — an object for the native link and a `.dylib` for
`avra run` — or design (e) below.

---

## 5. THE ALTERNATIVE DESIGNS

### (a) dlsym plus uniform shapes — RECOMMENDED, in two tiers

Buys: tier 1 today for zero risk beyond what `avra build` already
grants, and the corpus proof with it. Tier 2 buys the driver under
`avra run`, at the cost of the capability surface in §4.4.
Costs: UB by the C standard, made determinate by two ABIs and four
checkable conditions; a refusal surface at the declaration; a
vendored library that must also exist as a shared object.

### (b) Refuse, and let the driver be native-only

The status quo, and it is not nothing: `avra test` is already
native (CLAUDE.md, "Runtime facts"), and `corpus/native/` exists
precisely for this (`corpus/native/externs.av`,
`corpus/native/process_seam.av`).
Buys: zero mechanism, zero risk, zero migration.
Costs: `avra run` of any sqlite program traps; the corpus's eval leg
is absent for the whole driver, so eval == native becomes a claim
with a hole exactly where the campaign's risk concentrates; and the
compiler's own `-> int` defect (§1.5) is left standing, because
nothing forces the widths to be declared.
VERDICT: cheap and honest, but it concedes the campaign's stated
goal and leaves a wrong answer in the tree.

### (c) A compiler-GENERATED dispatch table

Impossible in the stated form. `build/avra` is compiled before the
program it interprets exists, so no table baked into it can name
that program's externs — the set is open by construction. Two
variants make it possible, and both become something else:

- **Two-stage:** `avra run` emits a small C file listing the
  program's externs, compiles it, and `dlopen`s the result. That is
  dlopen plus a compiler invocation per run — strictly more
  machinery and strictly more risk than (a), with the same
  capability question unanswered.
- **JIT:** the compiler already links libLLVM (`Makefile:14-17`),
  so ORC could emit a correct trampoline per signature at run time.
  This is the most CORRECT design available: LLVM performs the real
  ABI lowering, so struct-by-value, `f32` parameters, narrow stack
  slots and **Darwin variadics** all work, and there is no
  wrong-prototype UB anywhere. It is also the most expensive: a JIT
  inside `avra run` (the "JIT-like security concerns" the spec cited
  against libffi apply verbatim), and `language/interp.av` would
  have to reach the backend — the layering
  `core -> query -> grammar -> features -> language` survives
  literally (both are `language/`) but the interpreter's
  independence from the backend, which is what makes eval == native
  meaningful as a CHECK, does not.
  It also solves nothing about symbol resolution: it still needs
  `dlsym`/`dlopen`.
  VERDICT: keep it named. If the shape table ever needs a seventh
  exception, this is the design that replaces it rather than
  extending it.

### (d) libffi — rejected by the spec, and the rejection is informed

Spec 15.3 rejects runtime-generated trampolines: "add a heavy
runtime dependency and JIT-like security concerns."

What it would have bought: correct ABI for EVERY signature on every
platform, maintained by people whose whole job is this —
struct-by-value, `long double`, narrow stack slots, and Darwin's
variadic rule (libffi carries a Darwin arm64 variadic fix
explicitly). No refusal surface at the declaration at all.

What it costs beyond the spec's two reasons: it contradicts the
runtime's own opening law — "Language semantics live in this tree,
in this file — never in a dependency"
(`runtime/avra_runtime.c:1-8`) — and `ffi_closure`, which the
callback direction needs, requires W^X pages, which is the JIT
concern wearing a different hat.

What we actually lose by refusing it, measured rather than assumed:
**struct-by-value (0 uses in SQLite) and variadics (8 of 284, all
either avoidable or coverable by four enumerated shapes, §2.6).**
The rejection stands, and now it stands on a count.

### (e) RE-LINK THE INTERPRETER — the P6 collapse, unproven

"Interpreted OR linked" is a false dichotomy. `avra run` could link
the program's `[link]` words into a host image and interpret INSIDE
it, where `dlsym(RTLD_DEFAULT, …)` finds every symbol with no
`dlopen` and no initializers beyond the ones a native build would
have run anyway.

Buys: the capability question DISAPPEARS — the code that runs is
exactly the code `avra build` would have linked, through the argv
row already hardened at `cli/src/commands/shared.av:277`. It also
fixes §4.5: a vendored `.o` links, no `.dylib` needed.
Costs: a link per run of a program with foreign externs (the
compiler is large and pulls libLLVM; it needs caching by the link
words' hash), and `build/avra` is not kept as relocatable objects
today. Unproven here.
VERDICT: the right answer for tier 2 if it proves cheap. It rides
the SAME shape table — the trampolines do not change, only where
`dlsym` looks. Land (a) tier 1 now, keep tier 2 behind §4.4's gate,
and measure (e) before the driver's foreign surface is wide.

---

## 6. LANDING CHECKLIST

Dependency order. No step starts past an open gap above it.

**S0 — THE WIDTHS (blocker, native-first).**
- `core/ir.av:206` — `RtKind` grows `I32, U32, F64, F32`. Breaks
  `ll_rt_kind` (`language/llvm.av:175-181`) and `rt_kind_of`
  (`core/runtime_api.av:110-114`) at compile time, as designed.
- `features/fns/mod.av:32` — the extern grammar admits the
  fixed-width type names at seats and answer.
- `language/lower.av:52-56` — `extern_row_of` carries the declared
  width instead of collapsing to `I64`.
- `language/llvm.av:169-173` — `declare_externs` declares the true
  width; the call site extends (`sext`/`zext`) to Avra's `int`.
- `features/fns/check.av` — F2059 and its voice.
- `language/llvm_api.av:60-61` and `backend/llvm_wrapper.c:554,577`
  — the tree's two accidental cases, made honest.
- PROOF: a runtime probe answering C `int` `-1`, read as `-1` under
  the native binary. Today it answers 4294967295 — the golden
  changes, and that change IS the fix. An IR golden shows the
  `sext`.

**S1 — THE TRAMPOLINE (tier 1).**
- `runtime/avra_runtime.c` — `avra_ffi_symbol`, `avra_ffi_call`,
  the six casts, `#include <dlfcn.h>`,
  `__attribute__((no_sanitize("function")))` at each.
- `language/interp.av:501-505,572-576` — `hosted_extern` replaces
  `unhosted_extern`; the `extern fn avra_ffi_*` declarations join
  the tail at `:888`; a symbol cache joins `Machine` beside `onces`
  (`:41`).
- PROOF, the load-bearing one: **`corpus/native/externs.av` moves
  to `corpus/externs.av`** and `make corpus` requires
  eval == native == expected for the whole host seam
  (`Makefile:99-113`). The file already exercises eleven externs
  including `List<string>` seats and a `void` extern.
- `features/fns/tests/fns_test.av:17` and `:23` invert:
  `refused_at_run` becomes `shown`.

**S2 — THE REFUSALS.**
- `features/fns/check.av` — F2056, F2057, F2058 with their voices;
  the arity and seat laws read from the declared signature.
- `features/fns/mod.av` — the four rows in the feature's `diags`
  table; the extern grammar admits `...` so a variadic declaration
  is EXPRESSIBLE and therefore refusable by its own law rather than
  by a parse error.
- PROOF: a `refused_with` per law in `fns/tests/fns_test.av`, and a
  golden rendering test per code (CLAUDE.md: every diagnostic has
  one).

**S3 — THE CAPABILITY.**
- `language/manifest.av:35,93,109` — the `[ffi]` section,
  `libraries` only, names only.
- `language/workspace.av` — a root-only reader beside `link_inputs`
  (`:939-945`); a dependency's `[ffi]` row is a diagnostic, twinned
  with the poisoned-manifest case at
  `language/tests/workspace_test.av:163`.
- `cli/src/commands/run.av` — the invocation flag; the refusal when
  it is absent.
- PROOF: a workspace spec case where a DEPENDENCY declares
  `[ffi] libraries` and the program refuses; a second where the
  root declares it and the flag is absent, and the refusal names
  both doors.

**S4 — THE DRIVER'S FIRST BINDING.**
- `corpus/sqlite/` — open an in-memory database, prepare, step,
  read an `i32` column holding `-1`, finalize, close; eval ==
  native == expected. This is the first program that proves the
  whole stack, and its `-1` is deliberate.

**S5 — THE FP LANE** (lands with `float`).
- The `reals` lane and `FFI_F64`/`FFI_F32` are already in the C;
  the interpreter gains a `Val` for the double and the lane fills.
- PROOF: `sqlite3_bind_double` / `sqlite3_column_double` round-trip,
  eval == native.

**S6 — VARIADICS** (deferred until `sqlite3_db_config` is needed).
- `language/llvm.av:189-195` — the `vararg` flag reaches the
  declaration from the signature.
- Four enumerated variadic trampolines; everything else keeps F2056.

---

## BLOCKERS

**B1 — A FOREIGN NARROW RESULT IS READ WIDE.** Every extern
answering C `int` is declared `i64` and read at 64 bits
(`language/llvm.av:169-181`, `core/runtime_api.av:110-114`), so a
negative `int` answers as its unsigned image. `sqlite3_column_int`
is the driver's most-called reader. The tree's own two cases are
right only because their values are 0 and 1
(`backend/llvm_wrapper.c:554,577`).
FIX: `RtKind` grows the C widths; the extern grammar spells them;
the backend declares and extends; F2059 demands the decision at
every declaration. Native-first — this is not an interpreter
problem.
CONFIDENCE: HIGH on the mechanism (read from source plus both
ABIs' "unused bits unspecified"); the exact witness wants a probe:
a C `int`-returning body answering `-1`, read under `./avra build`.

**B2 — NO C WIDTHS IN THE TYPE SURFACE.** `extern fn f() -> int`
can only mean `int64_t` today, and a VENDORED header cannot be
changed to agree. Spec 15.2 decided BOTH automatic mapping and
explicit C types (`@std/c`'s `c_int`, `c_long`, `CString`); the
minimum this campaign needs is the fixed-width names at the extern
seat and answer.
FIX: `i8 i16 i32 i64 u8 u16 u32 u64` (and later `f32 f64`) as
extern-seat types, typed as `int` inside Avra with the width
recorded on the row. A type-surface event, and B1's prerequisite.

**B3 — `avra run` CANNOT SEE THE PROGRAM'S LIBRARIES.** The
interpreter runs inside `build/avra`
(`language/workspace.av:1068-1071`); `[link]` words reach clang
only at build time (`cli/src/commands/shared.av:277`). `dlsym`
alone hosts the tree's existing externs and NOT sqlite.
FIX: tier 2 — `dlopen` under §4.4's capability rule, or design (e).
Either way the campaign must choose before `@std/sqlite` runs
interpreted.

**B4 — `dlopen` IS ARBITRARY NATIVE EXECUTION NAMED BY A
MANIFEST.** Initializers run before any Avra code. The tree has
already been bitten by a manifest that could run code
(`ROADMAP.md:7769-7787`), and the falsified premise there — "a
`[link]` row is the project's own word" — is the exact premise a
naive `[ffi]` row would re-adopt.
FIX: §4.4 — root manifest only, names not flags, `RTLD_NOW |
RTLD_LOCAL`, plus an explicit invocation opt-in; a dependency's
`[ffi]` row refused with its own voice.

**B5 — NO VARIADIC SPELLING, AND APPLE'S ABI MAKES IT LOAD-BEARING.**
`extern fn` has no `...` (`features/fns/mod.av:32`), and the backend
hard-wires `variadic = false` (`language/llvm.av:171,187`). A
variadic C function declared non-variadic is broken on Apple arm64
even natively, silently, because the callee reads its variadic
arguments from the stack. Eight SQLite entry points are variadic,
`sqlite3_db_config` and `sqlite3_config` among them.
FIX: the grammar admits `...`; the declaration law refuses it for
the interpreter (F2056) while the backend passes the flag through;
four enumerated variadic trampolines when the config surface is
needed.

**B6 — NO `Bytes`, SO THE TEXT LANE IS HALF A LANE.** The
trampoline's text lane hands C a `const char*` from an Avra
`string`, which is a headered, NUL-terminated byte box — right for
text, wrong for a BLOB, and it truncates a text holding a NUL.
Already recorded (`ROADMAP.md:1554-1566`); named here because the
FFI mechanism is where it becomes visible: `sqlite3_bind_blob`'s
pointer-and-length pair has no Avra spelling that survives a NUL.
FIX: lane's own — `Bytes` as a core value category. Until it lands,
the driver binds blobs through `ptr` plus an explicit length and
never through `string`.

---

## CONFIDENCE LEDGER

| claim | confidence | how verified |
|---|---|---|
| The interpreter traps on an unregistered extern; a registry-named extern already runs | HIGH | read `language/interp.av:501-505,572-576`; `features/fns/tests/fns_test.av:19-21` |
| Extern rows collapse every type to `I64/Ptr/Void`, and the backend declares `i64` | HIGH | read `core/runtime_api.av:110-121`, `language/lower.av:47-56`, `language/llvm.av:169-181` |
| `.Ptr` is unmanaged, so no retain/release touches a foreign pointer | HIGH | read `language/memory.av:29-45` |
| `avra run` interprets in `build/avra`'s process; `[link]` words reach clang only at build | HIGH | read `language/workspace.av:1068-1071`, `cli/src/commands/shared.av:277`, `language/workspace.av:939-956` |
| AAPCS64: `x0`–`x7` integer, `v0`–`v7` FP, separate files, stack overflow, `x0`/`v0` results, `x8` indirect | HIGH | ARM `abi-aa/aapcs64/aapcs64.rst`, stages A/B/C and result-return rules |
| "The unused bits in a register holding an argument smaller than 8 bytes are unspecified" | HIGH | quoted, `abi-aa/aapcs64/aapcs64.rst` |
| Apple arm64 passes variadic arguments on the stack; the base standard does not | HIGH | Apple, *Writing ARM64 Code for Apple Platforms*; corroborated structurally by Darwin's pointer `va_list` vs Linux's `__gr_top`/`__vr_top` register-save-area struct (libffi PR #577, LLVM D116774) |
| Apple arm64: the CALLER extends arguments narrower than 32 bits | HIGH | Apple's ABI notes; dotnet/runtime #101046 records the same divergence |
| Apple arm64: stack argument slots are naturally sized, not rounded to 8 | MEDIUM | Apple's ABI notes ("arguments may consume slots that are not multiples of 8 bytes"); not probed. The refusal it motivates is conservative either way |
| x86-64 SysV: 6 integer registers, 8 SSE, `%al` an upper bound on vector registers for variadic calls | HIGH | System V AMD64 psABI §3.2.3 and the varargs rule |
| Calling through an incompatible prototype is UB by C11 6.5.2.2p9 | HIGH | the standard |
| …and is determinate on both ABIs under the four conditions of §1.4 | MEDIUM-HIGH | derived from the two ABIs' allocation rules; the "extra arguments are ignored" half follows from caller-saved argument registers and caller-cleaned stack. NOT probed — S1's corpus is the probe |
| One prototype of 10 int + 8 double parameters reproduces every callee's argument locations for ≤10 int-class and ≤8 FP arguments | MEDIUM-HIGH | derived: separate files, class-order allocation, and no FP overflow means the stacked integers land in the same slots. Verify with a 10-argument C probe before relying on it |
| `-fsanitize=function` / `cfi-icall` would trap on the wrong-prototype call | HIGH | clang's documented behaviour for that check |
| arm64e pointer authentication would require signing a `dlsym` result | MEDIUM | inferred from the arm64/arm64e split; macOS user binaries are arm64, so it does not bite today |
| SQLite: max arity 10, 8 variadic entry points, 4 functions touching `double`, no struct-by-value, `int` returned by 153 of 284 | HIGH | parsed `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sqlite3.h` |
| A negative C `int` result reads back as 4294967295 through an `i64` declaration | HIGH on mechanism, UNPROBED on this tree | §1.5; both compilers materialize a 32-bit result with a 32-bit write. The probe is one C body and one `./avra build` |
| Avra strings are NUL-terminated boxes, so the text lane is safe for text | HIGH | read `runtime/avra_runtime.c:302-307,1122-1128` |
| A `List<string>`'s slots already hold `const char*`, so the merge needs no conversion | HIGH | read `runtime/avra_runtime.c:514-523` and `avra_proc_spawn`'s use at `:1683,1692-1694` |
| `dlopen` runs a library's initializers before any Avra code | HIGH | the dynamic loader's documented contract on both platforms |
| The tree has two extern declarations whose C bodies return 32-bit `int` | HIGH | read `backend/llvm_wrapper.c:554,577` against `language/llvm_api.av:60-61` |
| Spec 15.3 rejects libffi; 15.2 decided both automatic mapping and explicit C types | HIGH | `docs/2026_04_18_FULL_SPEC.md`, Axis 15.2 and 15.3 |
| The mechanism needs no `Ins`, no `RtHost` and no `rt_sigs()` growth | MEDIUM-HIGH | derived from the existing pattern — interp.av declares `extern fn avra_proc_*` at `:888-910` and calls them directly; only `RtKind` grows, and that is B1's requirement, not the host's |
