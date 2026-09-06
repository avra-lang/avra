# The uniform extern host — calling any C function from the interpreter with no codegen and no libffi

Lane sqlite research, 2026-09-05. Independent study for the decision
"teach the interpreter to host any extern", so that every C binding in
every package runs identically under `avra run` and natively.

Everything ABI in this paper was MEASURED on this machine
(`arm64`, macOS 26.5.2, Apple clang 21.0.0) and, where Rosetta could
run it, on `x86_64` as well. Every claim about the tree was read out
of the tree or probed with `./avra check` on a scratch file, with the
output pasted. Where I could not measure, I say so.

**THE THREE HEADLINES, before the detail.**

1. **The trampoline collapses to TWO shapes, not a table.** The
   integer and floating register files are allocated by *independent*
   counters on both AAPCS64 and SysV, so a callee's *interleaving* of
   `int`/`double` parameters is invisible to the caller — only the
   per-class ordinal matters. `f(int64_t×8, double×8) -> int64_t` and
   its `-> double` twin call **every** C function with ≤ 8
   integer/pointer parameters and ≤ 8 double parameters, in any order.
   Measured, six interleavings, both targets. That is **273 of
   SQLite's 284 entry points** — every non-variadic function of arity
   ≤ 8, the four `double`-touching ones included. The naive design, a
   generated table over (arity × which-arguments-are-double × return
   class), is ~1022 prototypes; it is not needed.
2. **The return-width defect is worse than "zeroed".** The tree
   already records that a C `int` of -1 reads as 4294967295. It is not
   merely zero-extension: `int trunc_of(int64_t x){return (int)x;}`
   compiles at -O2 to a bare `ret`, so a caller reading `x0`/`rax` as
   64 bits sees **the argument's high bits**. Measured: 0xdead0000000005
   in, 0xdead0000000005 out, on **both** arm64 and x86-64. 157 of
   SQLite's 284 entry points answer C `int`.
3. **The interpreter cannot host a symbol that lives only in a static
   object.** `dlopen` refuses a `.o` and refuses a `.a` (pasted
   below), and `build/avra` never links the *program's* `[link]` words.
   A vendored `sqlite3.o` is reachable natively and unreachable under
   `avra run`. The way out is to build the vendored amalgamation as a
   **dylib as well**, named by a new manifest row the loader can
   compose per platform.

---

## 1. THE CURRENT STATE, quoted from the tree

### 1.1 Declaration and parse

The extern is one grammar rule in the `fns` feature, a NARROWER copy of
the `fn` rule beside it (`features/fns/mod.av:32`):

```
stmt = "extern" "fn" n:NAME "(" ( ps:NAME ":" pt:type ( "," ps:NAME ":" pt:type )* ","? )? ")" ( "->" r:type )? END @recover(sync_to: "END") -> extern_fn(n, ps, pt, r)
```

Its builder is `build_extern` (`features/fns/builders.av:70-76`):

```avra
fn build_extern(mut b: Builder) -> Result<LangNode, string> {
    let n = b.token(0)?
    let ps = b.tokens(1)?
    let ends: int? = b.span_end()
    if ends == null { return .Err("an extern declaration without a span") }
    b.make_stmt(Stmt.ExternFn(n.text, seats(ps, aligned_param_types(ps, b.type_refs(2)?, ends!)), b.answer(3)))
}
```

The node is `Stmt.ExternFn(name, params, ret)` (`core/nodes.av:402-404`),
projected once by `extern_parts` (`core/parts.av:250-256`). A
declaration is extern when `extern_parts` answers
(`features/decls.av:603-608`), and an extern's symbol is its BARE name
— no module mangling (`features/decls.av:664-666`):

```avra
fn symbol(d: DeclId) -> string {
    let x = self.decl(d)
    if self.is_extern(d) { return x.name }
    …
}
```

**A GRAMMAR DEFECT FOUND WHILE PROBING — new, not previously recorded.**
An extern whose RETURN TYPE IS GENERIC swallows the following line:

```
$ printf 'extern fn a(x: int) -> List<int>\nlet z = 1\n' > c5.av && ./avra check c5.av
error[F0100]: expected BREAK while parsing `stmt`
  ╭─[…/c5.av:2:1]
2 │ let z = 1
  · ┬
  · ╰──
──╯
```

The mechanism is the LINE LAW, not the extern rule: `>` is a
continuing operator (`grammar/lexer.av:423-429`), so the BREAK after
`List<int>` is dropped and the next statement is read as the extern's
continuation. Every other statement whose type annotation can end in
`>` is followed by `{`, `=` or `,`; the extern is the only tail
position in the grammar. `-> List<int>`, `-> Map<K, V>` and
`-> Result<T, E>` are all effectively unusable as extern answers
today. **This belongs in "The subset today".**

### 1.2 Type checking — there is no extern type law at all

`declare_fn` sends an extern down the SAME path as an ordinary fn
(`language/typing_declare.av:133-145`):

```avra
fn declare_fn(s: StmtId) {
    let parts: FnParts? = self.view.store.fn_parts(s)
    if parts != null { … return self.declare_sig(s, fp.params, fp.ret) }
    let host: ExternParts? = self.view.store.extern_parts(s)
    if host != null { self.declare_sig(s, host!.params, host!.ret) }
}
```

`declare_sig` checks duplicate parameter names and that each annotation
NAMES A TYPE. Nothing asks whether the type can cross a C boundary.
Probed, each shape alone, `./avra check`, empty output = accepted:

```
OK    : extern fn f(p: Pt) -> Pt              (a struct by value)
OK    : extern fn f(p: Pt) -> int
OK    : extern fn f(x: int) -> Pt
OK    : extern fn f(x: int?) -> int
OK    : extern fn f(x: int) -> int?
OK    : extern fn f(x: List<int>) -> int
OK    : extern fn f(x: int) -> List<int>
OK    : extern fn f(x: Map<string, int>) -> int
OK    : extern fn f(x: int) -> Result<int, string>
OK    : extern fn f(x: string) -> string
OK    : extern fn f(x: bool) -> bool
OK    : extern fn f(x: ptr) -> ptr
OK    : extern fn f(x: int)
OK    : extern fn c_enum(c: Col) -> Col        (an enum by value)
OK    : extern fn c_get() -> ptr?
```

Refused, and only for reasons that have nothing to do with the seam:

```
extern fn c_fn(f: fn(int) -> int) -> int   F0100 "expected BREAK while parsing `stmt`"
extern fn c_dyn(v: dyn Show) -> int        F2032 "`dyn Show` names no trait"   (the trait is undeclared)
extern fn c_i32(x: int) -> i32             F2001 "`i32` names no type"
extern fn c_f64(x: float) -> float         F2001 "`float` names no type"
                       help: the types today are `int`, `string`, `bool`, and your declared types
```

**So the extern wall's type vocabulary today is: everything the
language has, minus fn types.** A `Map<string, int>` seat is accepted
and will hand C an `AvraMap*`; a struct by value is accepted and will
hand C the record's box pointer (or its one flat field). There is no
law, no diagnostic, no warning. That is the single largest gap this
research found on the *declaration* side, and it is independent of the
interpreter.

Two type facts that ARE laws and speak well:

```
$ ./avra check r2.av      # `if p == null` over a bare `ptr`
error[F2000]: `== null` asks a nullable, this is `ptr`
help: `ptr` is a guarantee — it is never absent
```

`ptr?` is accepted end to end (declaration, `== null`, `p!`), and its
representation is the null pointer itself — the right shape for C.

### 1.3 Lowering

`Lowered` carries the program's externs as registry rows
(`language/lower.av:30-39`), gathered by `extern_rows`/`extern_row_of`
(`language/lower.av:47-56`):

```avra
fn extern_row_of(decls: Decls, d: Decl) -> RtSig {
    let sig: FnSig? = fn_sig_of(decls.sig(d.id))
    let params: List<TypeId> = sig?.params ?? []
    extern_row(decls.symbol(d.id), rt_kind_of(decls.types, sig?.ret ?? decls.types.intern(Type.Void)), [rt_kind_of(decls.types, p) for p in params])
}
```

`rt_kind_of` (`core/runtime_api.av:95-99`) collapses every declared type
into three:

```avra
export fn rt_kind_of(types: TypeRegistry, ty: TypeId) -> RtKind {
    if types.shape_of(ty) is .Void { return RtKind.Void }
    if types.rides_pointer(ty) { return RtKind.Ptr }
    RtKind.I64
}
```

and `extern_row` pins the ownership columns
(`core/runtime_api.av:101-105`):

```avra
export fn extern_row(name: string, ret: RtKind, params: List<RtKind>) -> RtSig {
    RtSig { name: name, ret: ret, params: params, owns_result: false, has_owned_twin: false, host: RtHost.Unhosted }
}
```

`RtKind` is `{ I64, Ptr, Void }` (`core/ir.av:219`). There is no
floating-point slot, which is why `float` landing is an `RtKind` event
(a registry COLUMN, not an instruction) — the lane's ROADMAP already
says this and I confirm it: with `RtKind` as it stands the wall cannot
DECLARE a double seat, and `rt_kind_of` would silently route one into
an integer register.

The call lowers with NO new instruction (`features/fns/lower.av:39-51`):

```avra
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

Memory: `.Ptr` is unmanaged (`language/memory.av:29-45`), `retained_args`
retains for `.Call` and `.CallPtr` only (`language/memory.av:383-384`),
and `managed_dst` releases a `CallRt` answer only when the registry says
`owns_result` (`language/memory.av:316-327`) — which `extern_row` pins
`false`. So **an extern borrows its arguments and its answer is never
released.** For a `ptr` that is exactly right. For a foreign `string`
it is a leak that never fires, because `avra_rc_retain/release` no-op on
an untagged pointer.

### 1.4 The LLVM backend — what it coerces

Declaration (`language/llvm.av:169-181`):

```avra
fn declare_externs(lc: ptr, m: ptr, rows: List<RtSig>) {
    for s in rows {
        declare(m, s.name, ll_rt_kind(lc, s.ret), [ll_rt_kind(lc, k) for k in s.params], false)
    }
}

fn ll_rt_kind(lc: ptr, k: RtKind) -> ptr {
    match k {
        .I64 -> avra_llvm_int64_type(lc),
        .Ptr -> avra_llvm_pointer_type(lc),
        .Void -> avra_llvm_void_type(lc),
    }
}
```

Note the literal `false` in the `declare` call: **every extern is
declared non-variadic**, and `declare`'s `variadic` parameter is only
ever passed `false` from anywhere in the backend.

Argument coercion (`language/llvm.av:430-447`):

```avra
fn rt_arg(callee: string, j: int, r: Reg) -> ptr {
    let v = self.vals[r.index]
    let sig: RtSig? = self.callee_sig(callee)
    if sig == null { return v }
    if j >= sig!.params.length { return v }
    if !(sig!.params[j] is .I64) { return v }
    let i64t = avra_llvm_int64_type(self.lc)
    if self.types.rides_pointer(self.tys[r.index]) {
        return avra_llvm_build_ptr_to_int(self.b, v, i64t, "slot")
    }
    if self.types.shape_of(self.tys[r.index]) is .Bool {
        return avra_llvm_build_zext(self.b, v, i64t, "slot")
    }
    v
}
```

Result coercion (`language/llvm.av:383-402`):

```avra
fn call_rt_value(dst: Reg, callee: string, args: List<Reg>) -> ptr {
    let raw = self.call(callee, self.rt_args(callee, args))
    if self.types.shape_of(self.tys[dst.index]) is .Bool {
        return avra_llvm_build_icmp(self.b, 33, raw, avra_llvm_const_int(avra_llvm_int64_type(self.lc), 0, 0), "b")
    }
    if self.types.rides_pointer(self.tys[dst.index]) && self.answers_word(callee) {
        return avra_llvm_build_int_to_ptr(self.b, raw, avra_llvm_pointer_type(self.lc), "boxed")
    }
    raw
}
```

So the whole coercion vocabulary is: **`ptrtoint` in, `zext` for a
bool in, `icmp ne 0` for a bool out, `inttoptr` for a pointer out.**
Nothing narrows, nothing sign-extends, nothing copies. `i64` is the
declared width of every `int`-typed seat and answer.

### 1.5 The interpreter's refusal

`rt_dispatch` (`language/interp.av:500-505`) looks the callee up in the
registry index; a name the registry does not know but the program's
externs do is a trap:

```avra
fn rt_dispatch(callee: string, vals: List<Val>) -> Val {
    let sig: RtSig? = self.rt.get(callee)
    if sig == null {
        if self.l.externs.any(it.name == callee) { return self.unhosted_extern(callee) }
        return self.defect_val("an unknown runtime callee `${callee}` survived lowering")
    }
    …
}

fn unhosted_extern(callee: string) -> Val {
    self.trapped("`${callee}` is extern — the evaluator cannot host it; build natively")
    Val.I(0)
}
```

Measured, on a scratch file:

```
$ ./avra run r1.av ; echo "exit=$?"
`sqlite3_libversion_number` is extern — the evaluator cannot host it; build natively
exit=1
```

Two structural facts about the interpreter that shape the design:

- **`Val` has no pointer category** (`language/interp.av:16-28`):
  `I(int) | B(bool) | S(string) | A(id) | C(id) | M(id) | N`. A foreign
  pointer must ride `Val.I`, and **`Val.N` is the null pointer** —
  `const_int_val` already turns a `ConstInt 0` into `Val.N` when the
  destination rides a pointer (`language/interp.av:190-193`), and
  `null_eq_val` (`:323-331`) makes `Val.N == Val.N` true and
  `Val.N == Val.I(0)` FALSE. **So the empty case must be written
  first: a foreign word of 0 landing in a pointer-riding register
  answers `Val.N`, never `Val.I(0)`.** Get that backwards and
  `p == null` is false for a genuine NULL under `avra run` and true
  natively — an engine divergence in the one place the whole campaign
  is trying to close.
- **The interpreter already calls C directly.** `interp.av:888-910`
  declares 23 `extern fn`s of its own (`avra_proc_spawn`,
  `avra_io_read`, …) and `rt_dispatch`'s arms call them. The
  interpreter is compiled natively; hosting arbitrary externs means
  adding *one more* such extern — a trampoline — not a new mechanism.

---

## 2. THE ABI QUESTION

**Is it safe to declare one C function-pointer type
`long f(long,long,long,long,long,long,long,long)` and call any C
function whose parameters and return are integer- or pointer-sized, by
casting the symbol to that type and passing 8 arguments regardless of
the callee's real arity?**

**YES for the ARGUMENTS. NO for a narrow RETURN.** Detail, with the
rules and the measurements.

### 2.1 The rules

**AAPCS64 (arm64, and Apple's variant).** Integer/pointer arguments are
assigned to `x0`–`x7` by the Next General-purpose Register Number
(NGRN), incremented per argument; floating/vector arguments to `v0`–`v7`
by the Next SIMD and Floating-point Register Number (NSRN). **The two
counters are independent.** When a counter is exhausted, the remaining
arguments of that class go on the stack, in declaration order. The
result comes back in `x0` (integer/pointer) or `v0` (floating). The
CALLER owns the argument area: it allocates it and reclaims it — there
is no callee stack cleanup on either target, so a caller that pushed
more than the callee reads leaves nothing behind.

**SysV x86-64.** Same shape, different registers: INTEGER-class
arguments to `rdi, rsi, rdx, rcx, r8, r9` (six, not eight), SSE-class
to `xmm0`–`xmm7`, **again by independent counters**; overflow to the
stack in declaration order; result in `rax` (or `rdx:rax`) or `xmm0`.
Caller cleans.

**What a callee does with argument registers it never declared:
nothing.** They are call-clobbered scratch in both ABIs; a callee is
free to overwrite them and never reads them as parameters.

**What a callee's return leaves in the unused high bits: NOTHING IS
PROMISED.** AAPCS64 is explicit that a result narrower than the
register occupies the low bits and the recipient may not assume the
upper bits are a zero- or sign-extension. SysV x86-64 is the same in
practice. **This is the hazard, and it is not theoretical.**

**One more rule that matters and is easy to miss: calling a function
through an incompatible function-pointer type is undefined behaviour in
C** (C17 6.3.2.3p8). The uniform trampoline is not legal C; it is legal
*ABI*. That is workable only because the callee arrives from `dlsym` as
an opaque `void*`, so no compiler can see both sides and "exploit" the
mismatch — the call is a genuine indirect call through a register. It
would NOT be safe if the trampoline and the callee were in one
translation unit (see §2.4), and it is exactly the sort of thing
`-fsanitize=cfi-icall` exists to flag. Compile the trampoline in its
own TU, take the pointer only from `dlsym`, never enable icall CFI on
it.

### 2.2 Arguments — measured, and correct

`liblab.dylib` holds `a0` … `a8` with declared arities 0 through 8;
the driver casts every symbol to
`int64_t (*)(int64_t×8)` and always passes eight words.

```
== arity ladder, all 8 words passed regardless of declared arity ==
a0()            = 42   (want 42)
a1(7)           = 7   (want 7)
a2(1,2)         = 12   (want 12)
a3(1,2,3)       = 123  (want 123)
a4(1..4)        = 10   (want 10)
a5(1..5)        = 15   (want 15)
a6(1..6)        = 21   (want 21)
a7(1..7)        = 28   (want 28)
a8(1..8)        = 36   (want 36)

== pointers through the same trampoline ==
p_len(s)        = 11  (want 11)
p_id(s)         = "hello, seam"
v_puts printed this
```

The `void` callee (`v_puts`) is called through the `int64_t`-returning
shape and prints correctly; its answer register holds garbage, which
the caller ignores. **So `RtKind.Void` needs no separate trampoline
shape** — the existing `CallRtVoid` already discards the destination.

Caller-cleans, proved by repetition and by a stack argument:

```
a2 through a 12-word trampoline, 10000 times: acc=120000 (want 120000)
a9 through a 12-word trampoline (9th arg on the stack): 45 (want 45)
```

Ten thousand calls that hand a 2-parameter callee twelve words drift by
nothing; a 9-parameter callee reached through a 12-word prototype reads
its stack-passed 9th argument correctly.

### 2.3 THE RETURN WIDTH — the wrong answer, and it is not zero

The tree already records (ROADMAP, 2026-09-05, lane A) that a C `int`
of -1 read as an Avra `int` answers 4294967295, and closed our half
with `make externs`. **That record understates the hazard.** It
describes the *common* code shape — a callee whose last write to the
answer register is a 32-bit write, which architecturally zeroes the
upper half on both targets. But nothing forces a 32-bit write.

`int trunc_of(int64_t x) { return (int)x; }` at -O2 on arm64:

```asm
_trunc_of:
                                        ; kill: def $w0 killed $w0 killed $x0
	ret
```

**A bare `ret`.** `x0` still holds the full 64-bit argument. Running
it, arm64:

```
C says trunc_of(0xdead0000000005) == 5  (a C caller sees the int)
word  trunc_of(0xdead0000000005) -> 0xdead0000000005  <-- the upper half is the ARGUMENT's
word  sum_of(-1, 0)    -> 0xffffffff  (a W write zeroed 63:32)
word  shr_of(-1)       -> 0xffffffff  (sxth to 32 bits, then zero)
word  nz_of(0xdead0000000005)    -> 0x1
```

and the identical program on x86-64 (Rosetta):

```
C says trunc_of(0xdead0000000005) == 5  (a C caller sees the int)
word  trunc_of(0xdead0000000005) -> 0xdead0000000005  <-- the upper half is the ARGUMENT's
word  sum_of(-1, 0)    -> 0xffffffff
word  shr_of(-1)       -> 0xffffffff
word  nz_of(0xdead0000000005)    -> 0x1
```

**Both targets, arbitrary garbage, not zero.** So the class is not
"negatives read as huge positives" — it is "**a 32-bit C answer read as
64 bits is a 64-bit value with no relationship to the answer**". A
value that happens to be small and positive today can carry a leftover
address tomorrow, from the same binary, after an unrelated optimizer
decision. The three narrowing shapes seen above — `sxth` (sign-extend
to 32), `add w0` (32-bit write), bare `ret` (nothing) — are all legal
and all in one file compiled at one level.

**What it costs SQLite:** 152 `int` + 5 deprecated `int` + 1
`unsigned int` = **157 of 284 entry points** answer a 32-bit type. That
is `sqlite3_step`, `sqlite3_prepare_v2`, `sqlite3_open_v2`, every
`bind_*`, `sqlite3_column_int`, `sqlite3_column_type`,
`sqlite3_column_bytes`, `sqlite3_errcode`. Return-type histogram over
the SDK's `sqlite3.h`:

```
  152  int            13  void *          2  const unsigned char *
   42  void           12  const void *    2  sqlite3_value *
   20  const char *    9  sqlite3_int64   2  sqlite3 *
    7  char *          5  SQLITE_DEPRECATED int          … (18 more, ≤2 each)
    2  double
```

**THE FIX BELONGS AT THE DECLARATION, NOT THE TRAMPOLINE.** The
trampoline is honest — it hands back a 64-bit word, which is exactly
what the ABI produced. What is missing is the language's ability to say
"this answer is 32 bits wide, sign-extended". Spec Axis 15.2 already
specifies it (`i32`, `u32`, `i64`, `u8` map to fixed-width C types);
`extern fn f() -> i32` is `F2001 "i32 names no type"` today. Until
those land:

- **Every trampoline shape must narrow explicitly**, and the width must
  come from the declaration. A `RtKind` of `I64` cannot express it. The
  minimum honest interim is a second word-return trampoline that does
  `return (int64_t)(int32_t)raw;` — but nothing in the declaration
  says which to pick, so it is a guess dressed as a fix.
- **The interim rule the tree can enforce today** is the one lane A
  wrote for our own C: an extern read as `int` must be backed by a C
  body that answers 64 bits. `make externs` enforces it where we own
  the body, and says so where we do not. For sqlite we own neither the
  header nor the bodies, so **`i32` is a prerequisite of a correct
  driver, not a nicety.** I would put it in the ladder ahead of the
  interpreter host: hosting the extern makes both engines agree on a
  wrong answer faster.

### 2.4 One caveat I could not test: pointer authentication

On `arm64e` (iOS, and macOS kernel space), function pointers are signed
with a discriminator that can be derived from the *function type*. A
cast between incompatible function-pointer types would then change the
discriminator and the authenticated call would trap. macOS user-space
binaries are plain `arm64`, `dlsym` returns an unsigned pointer, and
none of this bites today — every measurement above is on `arm64`. I had
no `arm64e` target available and did not test it. If Avra ever targets
iOS, the uniform trampoline is the first thing to re-measure.

---

## 3. THE VARIADIC PROBLEM

**Confirmed, and the failure is platform-asymmetric in the worst
possible direction.**

Apple's ARM64 ABI deviates from the generic AAPCS64: after the NAMED
arguments are assigned as usual, the register counters are abandoned
and **every variadic argument is assigned to 8-byte stack slots**
(`va_list` is a plain `char*`, not the generic PCS struct). On generic
AAPCS64 (Linux/aarch64) and on SysV x86-64, variadic arguments ride the
same registers as named ones.

Measured — the callee lives in a dylib and arrives through `dlsym`, so
no compiler can see both sides:

**arm64 (this machine):**
```
fixed callee  via uniform trampoline : 60  (want 60)
VARIADIC callee via uniform trampoline: 6476399376  (want 60)
VARIADIC callee via variadic prototype: 60  (want 60)
snprintf via uniform trampoline      : "60-20" (5)  (want "7-9" (3))
snprintf via variadic prototype      : "7-9" (3)
```

**x86-64 (same source, Rosetta):**
```
fixed callee  via uniform trampoline : 60  (want 60)
VARIADIC callee via uniform trampoline: 60  (want 60)
VARIADIC callee via variadic prototype: 60  (want 60)
snprintf via uniform trampoline      : "7-9" (3)  (want "7-9" (3))
snprintf via variadic prototype      : "7-9" (3)
```

**The uniform trampoline calls variadic functions CORRECTLY on x86-64
and silently wrongly on Apple Silicon.** (On x86-64 it works by
accident: the caller does not set `%al` to the vector-register count,
which is required for a variadic call. A garbage `%al` makes the
callee's prologue spill `xmm0`–`xmm7` into its own frame needlessly and
then read the integer arguments from the correct save area. It would
break the moment a `double` appeared among the varargs.)

That asymmetry is the argument for refusing at the DECLARATION rather
than testing. A test suite on x86-64 CI would be green.

### SQLite's variadic surface — all eight

```
int   sqlite3_config(int, ...)
int   sqlite3_db_config(sqlite3*, int op, ...)
char* sqlite3_mprintf(const char*, ...)
char* sqlite3_snprintf(int, char*, const char*, ...)
int   sqlite3_test_control(int op, ...)
void  sqlite3_str_appendf(sqlite3_str*, const char *zFormat, ...)
void  sqlite3_log(int iErrCode, const char *zFormat, ...)
int   sqlite3_vtab_config(sqlite3*, int op, ...)
```

None is needed by a driver. `sqlite3_mprintf`/`snprintf` are string
formatting Avra already does better; `sqlite3_config`/`db_config` have
`_v2`-shaped alternatives for the settings that matter or are
process-global setup; `test_control` is not public API in spirit;
`str_appendf` and `log` are optional. **Refusing all eight costs the
driver nothing.**

### The refusal to design

There is no way to declare a variadic extern today — the grammar has no
`...`, so a variadic C function is simply *mis-declared* as a fixed one
and calls it with the wrong convention. **The refusal therefore cannot
be at the declaration, because the declaration cannot express the
mistake.** Two honest halves:

1. **A LAW THE COMPILER CANNOT HOLD, SAID OUT LOUD.** Until `...`
   exists in the grammar, "an extern binding a variadic C function is
   a wrong program" belongs in the same place as the return-width
   rule: `tools/externs.py`, extended to read a *third-party header
   named by the manifest* — for sqlite we have `sqlite3.h` in the SDK
   and, once vendored, in the tree. Eight names in a header is a
   cheap, exact check.
2. **THE GRAMMAR GROWS `...`, AND THE COMPILER REFUSES IT.** The
   better shape, and small: `extern fn f(a: ptr, ...)` parses, and
   the seat law refuses it with a named diagnostic (§7). That converts
   "the compiler cannot see the mistake" into "the compiler names the
   mistake", which is what P7 asks for. The declaration then also
   *carries* the fact, so a later slice can host variadics by
   generating one prototype per call-site arity if anyone ever needs
   one.

I recommend (2), with (1) as the day-one keeper because it lands in an
afternoon and needs no language change.

---

## 4. THE FLOATING-POINT PROBLEM — and the paradox collapse

### 4.1 The problem is real

Doubles ride `v0`–`v7` / `xmm0`–`xmm7`, a separate file. Measured:

```
d_arg(10, 2.5) correct prototype        = 12  (want 12)
d_arg(10, <2.5 as a WORD>) uniform      = 10  (want 12)     <-- the double never arrived
d_ret() read as a WORD                  = 0x0  (x0/rax is untouched)
d_ret() read as a DOUBLE (fd8 shape)    = 3.5  (want 3.5)
d_id(2.5) via correct prototype         = 2.5  (want 2.5)
d_id(<2.5 as a WORD>) via fd8           = 1.86752e-312  (want 2.5)
i_only(3,4) read through the fd8 shape  = 1.86752e-312
```

An all-integer trampoline can neither pass nor return a double. A
double-returning trampoline reads the double correctly — so the RETURN
class is one axis, and the ARGUMENT class is another.

### 4.2 The collapse — TWO shapes, no table

The naive design is a dispatch table over (arity × which-arguments-are-
double × return class). For arity ≤ 8 that is
`Σ 2^n for n in 0..8 = 511` argument masks × 2 return classes ≈ **1022
prototypes**, generated. That is the design to refuse.

**It collapses to two, because the register files are allocated by
independent counters, so a callee's interleaving is invisible to the
caller.** Declare:

```c
typedef int64_t (*trW)(int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,
                       double,double,double,double,double,double,double,double);
typedef double  (*trD)(int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,int64_t,
                       double,double,double,double,double,double,double,double);
```

Place each argument at its **class-relative ordinal**: the k-th
integer/pointer parameter goes in word slot k, the k-th double
parameter in double slot k. The declared interleaving is never
consulted. Measured, arm64:

```
mix5 interleaved, placed BY CLASS   = 8503209  (want 8503209)
bind_like(stmt,2,3.25) by class     = 6130641485  (want 6130641485)
result_like wrote                   = 6.75  (want 6.75)
column_like(stmt,3) double answer   = 2.75  (want 2.75)
dfirst(1.5, 2, 3.5, 4) by class     = 11  (want 11)
eight8, 8 words + 8 doubles         = 3608  (want 3608)
```

and the identical program on x86-64 (Rosetta):

```
mix5 interleaved, placed BY CLASS   = 8503209  (want 8503209)
bind_like(stmt,2,3.25) by class     = 13099788869  (want 13099788869)
result_like wrote                   = 6.75  (want 6.75)
column_like(stmt,3) double answer   = 5.75  (want 5.75)
dfirst(1.5, 2, 3.5, 4) by class     = 11  (want 11)
eight8, 8 words + 8 doubles         = 3608  (want 3608)
```

`mix5` is `(int64_t, double, int64_t, double, int64_t)` — a maximally
interleaved shape — and `dfirst` puts the double FIRST. `bind_like`,
`result_like` and `column_like` are `sqlite3_bind_double`,
`sqlite3_result_double` and `sqlite3_column_double`'s exact shapes.
All correct on both targets, through the same two prototypes.

**THE CLASSIFICATION RULE, which is the whole of it:**

> For a declared extern, count `nw` = the number of parameters whose
> `RtKind` is `I64` or `Ptr`, and `nd` = the number whose `RtKind` is
> `F64`. Refuse if `nw > 8` or `nd > 8`. Pick `trD` if the answer's
> `RtKind` is `F64`, else `trW` (a `Void` answer uses `trW` and
> discards). Fill word slot 0..nw-1 in declaration order from the
> integer/pointer arguments, double slot 0..nd-1 in declaration order
> from the double arguments, zero the rest.

That is a dozen lines of Avra and one C function per shape. No table,
no generator, no `avra new trampoline`.

### 4.3 The boundary, and why the refusal is grounded

The collapse holds **only while both classes fit in registers**. Past
that, the ABI spills in DECLARATION order and the interleaving becomes
load-bearing again. Measured:

```
nine(...,9th=777) through the (8 words, 8 doubles) shape = 1    (want 777)
nine(...,9th=777) through a 12-word shape               = 777  (want 777)
```

A 9-integer-parameter callee reached through the two-file shape reads
garbage; reached through a 12-word all-integer shape it is correct.

**The honest limit on SysV x86-64 is SIX integer arguments, not eight**
— `rdi, rsi, rdx, rcx, r8, r9`. Arguments 7 and 8 go on the stack, and
the two-file shape still places them right *as long as no double
overflows too*, because the stack layout for a 7th/8th INTEGER argument
is the same whether the prototype interleaves doubles or not (doubles
7..8 are in `xmm6/xmm7`, still registers). My `eight8` measurement —
eight words and eight doubles, correct on x86-64 — is exactly that
case, so the ≤8/≤8 bound is measured good on both targets. I would
still write the refusal at ≤8/≤8 and not try to extend it.

### 4.4 What it covers

SQLite's arity histogram, non-variadic (276 functions):

```
   0 args :  13      5 args :  19
   1 args : 104      6 args :   6
   2 args :  69      7 args :   1
   3 args :  35      8 args :   2
   4 args :  24      9 args :   2      10 args : 1
```

- Two shapes cover all **273** functions of arity ≤ 8 — which is 273 of
  276 non-variadic, and includes all 4 double-touching functions
  (`bind_double`, `result_double`, `column_double`, `value_double`).
- **3 functions exceed 8 arguments**: `sqlite3_create_function_v2` (9),
  `sqlite3_create_window_function` (9), `sqlite3_table_column_metadata`
  (10). The first two take C function pointers and are blocked on
  callbacks anyway; the third is a metadata convenience. Refuse them
  by name with the arity diagnostic.
- **8 variadic**, refused as §3.
- A THIRD shape, `int64_t f(int64_t × 12)`, would pick up
  `table_column_metadata` and cost one more prototype and one more
  branch. It is not needed day one; it is the natural next rung and it
  is measured working above (`a9` through 12 words).

**Day one, with no `float`:** one shape,
`int64_t f(int64_t × 8)`, covers every one of the 30 functions a
minimal driver needs except `sqlite3_column_double` and
`sqlite3_bind_double` — and those are already blocked by the absence of
`float` in the language, not by the trampoline. So **the trampoline is
never the binding constraint.**

---

## 5. SYMBOL RESOLUTION — and the static-object crux

### 5.1 What the interpreter knows at run time

`link_words` (`language/workspace.av:948-956`) is the only projection of
the manifest's `[link]` rows:

```avra
export fn link_words(ws: Workspace) -> List<string> {
    let promised = [expanded(f) for f in link_inputs(ws)]
    [w for w in promised if !w.is_empty()]
}
```

`link_inputs` (`:939-946`) is `[objects under the package root] ++
[flags]`, with `${NAME}` holes filled from the environment
(`expanded`, `:960-970`). Its ONE consumer is `clang_words`
(`cli/src/commands/shared.av:275-278`):

```avra
fn clang_words(ll_path: string, p: Program, opt: string) -> List<string> {
    ["-w", opt, ll_path, "build/avra_runtime.o"].concat(link_words(p.ws)).concat(["-o", binary_name(ll_path)])
}
```

**So the `[link]` rows reach clang at BUILD time and reach nothing
else.** `Program.run()` (`workspace.av:1068-1071`) calls
`run_lowered(self.lowered_checked()?)`, and `run_lowered(l: Lowered)`
takes only the lowering — which carries `externs: List<RtSig>` and no
manifest at all. The interpreter today knows the extern's NAME, its
parameter kinds and its return kind. It knows nothing about where the
symbol lives.

That is a small, clean change: `Program.run()` already holds `ws`, so
it can hand the loader what the workspace promised without lowering
learning anything about manifests. `run_lowered(l, libs)` — the
lowering stays pure.

### 5.2 `dlsym(RTLD_DEFAULT)` versus `dlopen`

`RTLD_DEFAULT` searches the images already loaded into the process. For
`build/avra` that is: the compiler's own body, `avra_runtime.o`,
`llvm_wrapper.o`, `libLLVM`, and libSystem. Measured:

```
dlsym(RTLD_DEFAULT,"sqlite3_libversion") = 0x0
dlopen("libsqlite3.dylib")             = 0x35cb9ce40
  sqlite3_libversion()                 = 3.51.0
  dlsym(RTLD_DEFAULT,"sqlite3_libversion") after dlopen = 0x18a35cdbc
dlopen("libsqlite3.so")                = 0x0
```

Three facts in that block:

- **`dlopen("libsqlite3.dylib")` works on macOS 26 even though
  `/usr/lib/libsqlite3.dylib` does not exist on disk** — the dyld
  shared cache serves it. `ls /usr/lib/libsqlite3*` finds nothing.
  Any "check the file exists before loading" logic is wrong on macOS.
- **After `dlopen`, `RTLD_DEFAULT` resolves the symbol.** So the loader
  can be "dlopen once per library, then dlsym by name" with no handle
  bookkeeping per symbol — though keeping the handle is cheaper and
  more precise.
- **`-lsqlite3` is not a filename.** `libsqlite3.so` fails on macOS.
  A `[link] flags = ["-lsqlite3"]` row cannot be turned into a
  `dlopen` target without knowing the platform's naming convention.

**The portable manifest shape** is therefore not a flag but a NAME.
A new `[link]` key — `libraries = ["sqlite3"]` — carries the stem, and
the loader composes `lib<stem>.dylib` on Darwin, `lib<stem>.so` on
Linux (with `lib<stem>.so.N` as a documented fallback), while the
build path still emits `-l<stem>` onto clang's line. One row, two
projections, P12. `known_key` (`manifest.av:99-107`) is the one place a new key is
admitted:

```avra
if section == "link" { return key == "objects" || key == "flags" }
```

and `Manifest` (`manifest.av:35`) gains one field, read by
`words_of("link", "libraries")` (`manifest.av:290-296`). Everything else —
the argv law, the `${NAME}` expansion — is already there.

### 5.3 THE CRUX: can the interpreter host an extern that lives in a static object it never linked?

**No. Directly, and with the measurements.**

**(a) A static object cannot be `dlopen`ed at all.**

```
dlopen("./vendored.o")   = 0x0
  dlopen(./vendored.o, 0x0002): … (unloadable mach-o file type 1 './vendored.o') …
dlopen("./libvend.a")    = 0x0
  dlopen(./libvend.a, 0x0002): … (slice is not valid mach-o file) …
dlopen("./libvend.dylib")= 0x6fcf0a40  sym=0x1021602d8
```

Mach-O object files (type 1, `MH_OBJECT`) and static archives are not
loadable images. Only a dylib (or a bundle) is.

**(b) A static object IS reachable once linked into the running image —
but only if the linker kept it.**

```
direct call vendored_answer()          = 4242
dlsym(RTLD_DEFAULT,"vendored_answer") = 0x1045dc5b4
dlsym(RTLD_DEFAULT,"vendored_unused") = 0x1045dc5bc

=== with -Wl,-dead_strip ===
direct call vendored_answer()          = 4242
dlsym(RTLD_DEFAULT,"vendored_answer") = 0x1045dc5b4
dlsym(RTLD_DEFAULT,"vendored_unused") = 0x0
```

`vendored_unused` — linked in, referenced by nobody — is **gone** under
`-dead_strip`. "It is in the binary" is not the same as "it can be
found by name". This matters for the *native* engine's future too, if a
program ever wants to resolve one of its own externs dynamically.

**(c) `build/avra` never links the program's objects.** `clang_words`
above puts `link_words(p.ws)` on the *program's* link line. The
compiler's own manifest names `../../build/llvm_wrapper.o` and
`-lLLVM`; those are in `build/avra`. A program's `[link] objects =
["vendor/sqlite3.o"]` is in the *program's* binary only.

**Therefore: with the amalgamation vendored as a `.o`, `avra build`
works and `avra run` cannot — the symbol is not in the interpreter's
process and cannot be loaded into it.** That is the crux, and it is
decisive: the vendoring decision and the extern-host decision are
coupled.

### 5.4 The way out, with the tradeoff stated

**Build the vendored amalgamation as BOTH a static object and a
dylib**, from one source, in one build step:

```
build/sqlite3.o      -> the program's native link (P14: one static binary)
build/libsqlite3.dylib -> what the interpreter dlopens under `avra run`
```

The manifest names the library once; the two consumers project it
differently (§5.2). Cost: one extra compile of the amalgamation
(~2 MB of C, seconds) and a dylib that ships beside the toolchain, not
beside the user's program.

**The tradeoff, said plainly.** P14 is "no runtime, no framework, no
container", and a built Avra program keeps that: it statically links
`sqlite3.o` and depends on nothing. The dylib exists **only for the
interpreter**, in the toolchain's own `build/` directory — it is a
*compiler* artifact, like `build/avra_runtime.o`, not a deployment
artifact. That is the honest framing and I think it is the right one:
`avra run` is a development tool, and a development tool may need
development artifacts.

**Two alternatives I considered and would refuse:**

- *Link sqlite into `build/avra` itself.* Then `RTLD_DEFAULT` finds it
  with no dlopen and no capability question — but the compiler grows a
  dependency on every library any program might bind, which is absurd
  the moment a second library exists.
- *Have `avra run` shell out to a native build.* It is not
  interpretation; it defeats the point (fast feedback, no link step),
  and it makes `avra run` need clang.

**And one alternative worth keeping in the ladder:** for a system
library that is *already a dylib* — `-lsqlite3`, `-lz`, `-lcurl` — no
extra build step is needed at all. `dlopen("libsqlite3.dylib")` just
works, as measured. So the interpreter host lands useful on day one
against system libraries, and the vendored-dylib step is what the
sqlite lane's own vendoring decision adds on top.

---

## 6. SAFETY AND CAPABILITY

### 6.1 The threat model, honestly

`dlopen` **runs the library's initializers** — `__attribute__((constructor))`
functions, C++ static initializers, Mach-O `LC_ROUTINES`. Loading a
library is executing its code. So:

- **The new attack surface is `avra run` on untrusted source.** A
  program (or a *dependency* of a program) whose manifest names a
  library causes that library to be loaded and its initializers to run,
  the moment the program is evaluated.
- **`avra check` must stay inert.** Checking does not execute Avra
  code, and it must not execute C code either. That is free — nothing
  about type checking wants a symbol address.
- **The delta versus today is smaller than it looks, and I want to be
  fair about it.** `avra build` ALREADY hands the manifest's `[link]`
  words to clang, and a `[link] objects` row already gets an arbitrary
  object file linked into the user's binary. A malicious dependency
  can already run code at *your* program's startup. What changes is
  *when*: from "when you run the binary you built" to "when you run
  `avra run`". Meaningful, but this is not a new class of trust — it is
  the same trust, exercised earlier.
- **The tree's own precedent points the right way.** "A COMMAND IS AN
  ARGV, never a shell line" was born from exactly this shape: a
  manifest row that could smuggle execution. `link_words` already
  passes each row as one argv element so nothing quotes and nothing
  fences. A library NAME must get the same treatment — and a name is
  even easier to constrain than a flag, because it is a stem, not a
  path.
- **ROADMAP D8 already decided the doctrine**: "NEEDS ARE COMPUTED,
  GRANTS ARE WRITTEN. A library never declares capabilities: its needs
  are its extern closure, computed and published… Only a PROGRAM
  grants, at the top, deny by default… **C linkage is a TAINT: a
  package that links C needs everything unless an audit statement
  narrows it.**" And the trigger is named: "needs/grants once `extern`
  exists in the language". `extern` exists.

### 6.2 The recommendation

**Four rules, in order of how much they buy per line of code.**

1. **`avra check` never loads anything.** Resolution happens at the
   first CALL under `avra run`, never at declaration, never at
   analysis. (Free. Closes the "code execution at check time" hole
   before it opens.)
2. **A LIBRARY IS A STEM, NOT A PATH.** `[link] libraries = ["sqlite3"]`
   accepts `[A-Za-z0-9_+-]+` only — no `/`, no `.`, no `..`, no
   `${…}` expansion. The loader composes the platform filename and
   lets the system loader search its normal path. A manifest cannot
   name `/tmp/evil.dylib`, and no character in it means anything to
   anything. This is the argv law applied to a new noun, and it is
   the single highest-value rule here.
3. **THE TAINT IS COMPUTED AND SHOWN.** A package that declares any
   `extern` is tainted; a program that depends on it inherits the
   taint. `avra why` prints the chain. Deny-by-default waits for the
   grants system, but **the computation must land with the host**, not
   after it — a taint nobody can see is not a taint. Concretely: the
   first time `avra run` loads a library it was not going to load if
   the program had no dependencies, it says so on stderr, once, with
   the package that asked. Loud, not blocking.
4. **REFUSE `RTLD_GLOBAL` semantics we do not need**; open with
   `RTLD_NOW | RTLD_LOCAL` and keep the handle. `RTLD_NOW` surfaces a
   missing dependency at load rather than at an arbitrary later call;
   `RTLD_LOCAL` keeps a library's symbols from silently satisfying an
   unrelated extern's lookup, which is how a typo becomes a call into
   the wrong function.

**What I would NOT do, and why.**

- *An allowlist of library names.* It has to be maintained by someone,
  it is wrong the moment a user binds their own library, and it gives
  the *feeling* of safety while a dependency can still name `sqlite3`
  and ship a shadowing dylib in the search path. Rule 2 plus the taint
  is more honest and less work.
- *"Only symbols already in the image."* That is the status quo dressed
  as a policy — it forbids the entire feature (§5.3) while pretending
  to permit it.
- *Refuse under `avra check`, permit under `avra run`, as a security
  boundary.* It is the right BEHAVIOUR (rule 1) but it is not a
  security boundary — `avra run` is the ordinary thing a developer
  types. Do it because check has no reason to load, not because it
  protects anyone.
- *A capability the manifest must declare, gating the load.* Right
  destination, wrong rung. D8 says only a PROGRAM grants, and the
  grants system does not exist yet. Building a half-grants system here
  means building it twice. Compute the taint now (rule 3) so the
  grants system has something to consume when it lands.

---

## 7. THE DIAGNOSTIC SURFACE

Written in the tree's voice: terse, name the thing, carry the fix, one
named voice fn per refusal. F-codes below are the next free ones —
`F20xx` is the type range (highest in use `F2055`), `F09xx` the driver
range (`F0902` highest), `F40xx` the manifest range (`F4014` / `F4031`
highest).

### At the declaration (typing, `features/fns/check.av`)

```
error[F2056]: `sqlite3_column_double` declares a `float` seat, and the host wall carries words
  ╭─[src/sqlite.av:12:1]
12 │ extern fn sqlite3_column_double(stmt: ptr, col: int) -> float
   · ┬
   · ╰── declared here
──╯
help: a floating seat crosses in its own register file — `float` reaches the wall with `RtKind.F64`
```

```
error[F2057]: `sqlite3_create_function_v2` takes 9 word seats — the host wall carries 8
  ╭─[src/sqlite.av:31:1]
help: split the call behind a narrower entry point, or bind `sqlite3_create_function` (5 seats)
```

```
error[F2058]: `sqlite3_mprintf` is variadic — one call shape cannot carry two conventions
  ╭─[src/sqlite.av:44:1]
44 │ extern fn sqlite3_mprintf(fmt: string, ...) -> ptr
   ·                                        ─┬─
   ·                                         ╰── the variadic tail
──╯
help: on Apple arm64 a variadic argument rides the stack and a named one rides a register — interpolate the text in Avra and call a fixed entry point
```

```
error[F2059]: `f` takes `Map<string, int>` across the host seam
  ╭─[src/lib.av:3:1]
help: the seats that cross are `int`, `bool`, `ptr`, `ptr?`, `string` and `void` — an aggregate crosses as a `ptr` the C side knows the shape of
```

(That last one is the missing extern type law from §1.2. It should
start as a WARNING with a measured true-positive rate — the tree's own
F2040 lesson — because `List<string>` legitimately crosses today in
`avra_proc_run`, and the law must be written to count what it means.)

### At the call, under `avra run` — interpreter traps: no F-code, a bare line, exit 1, matching `unhosted_extern`'s existing shape

```
`sqlite3_open_v2` is extern and no library here defines it; `libraries = ["sqlite3"]` in the package's `[link]` names one
```

```
`libsqlite3.dylib` would not load: dlopen(libsqlite3.dylib, 0x0002): tried: … (no such file); the package asking is `@std/sqlite`
```

```
`sqlite3_column_double` answers a floating value and this build's host wall carries words only
```

### At the manifest (`manifest.*`, `features/modules/mod.av`)

```
error[F4015]: `libraries` names a library, not a path — `../evil.dylib` is not a name
  ╭─[avra.toml:14:1]
help: a library is one word of letters, digits, `_`, `+` and `-` — the loader composes `libsqlite3.dylib` or `libsqlite3.so` from it
```

Note what none of these say: none mentions a trampoline, an ABI, a
register file, or `dlsym`. The reader's problem is always a
declaration, a manifest row, or a missing library.

---

## 8. PRIOR ART — who calls C without libffi, and what they admit

**Everyone who calls arbitrary C signatures at run time either uses
libffi or generates code. The uniform trampoline is used only where the
callee's signature is FIXED BY THE HOST.** That is the honest summary,
and it is the strongest argument for keeping our shape set tiny.

| System | Mechanism | What it says about the limit |
|---|---|---|
| **Python `ctypes` / `cffi`** | libffi | libffi exists precisely because you cannot build a call frame from a runtime-described signature in portable C. `ctypes` also has to know `restype` to narrow the answer — the same return-width problem, solved by making the user declare it. |
| **Ruby `Fiddle`, Node `node-ffi`, PHP `FFI`, Ruby/Rust `libffi` bindings** | libffi | same. |
| **LuaJIT FFI** | JIT-emits the call | Mike Pall's design note is explicit that the FFI is fast because the call is *compiled*, not interpreted; the interpreter fallback still builds a frame in assembly per platform. |
| **Bun `bun:ffi`** | generates a C wrapper and JIT-compiles it (TinyCC) | it *writes code* per signature. |
| **Deno FFI** | libffi, plus V8 "fast API" trampolines for hot shapes | the fast path is generated; libffi is the general one. |
| **Java JNI** | per-platform hand-written assembly stubs in the JVM | not portable C; that is the point. |
| **Java Panama / FFM** | JIT-generated downcall stubs per `FunctionDescriptor`, **with a "fallback linker" built on libffi** for platforms without a specialised implementation | the most sophisticated modern answer, and it still keeps libffi as the portability floor. |
| **Go `cgo`** | generates a C wrapper function per call site at BUILD time | no dynamic dispatch at all — the closest thing to Avra's native path. |
| **Zig `@cImport`** | translates the header and compiles real C | no FFI mechanism exists; there is nothing to be dynamic about. |
| **Rust `extern "C"`** | static declarations, compiled | same. |

**Who genuinely uses the fixed-trampoline trick, and what they concede:**

- **The Linux kernel's system-call table** is the canonical example: an
  array of pointers all treated as `long (*)(long,long,long,long,long,long)`,
  with the documented limits "at most 6 arguments, all register-sized,
  no floating point, no structs by value". Modern kernels moved to
  `SYSCALL_DEFINEn` macro-generated wrappers with real prototypes,
  partly for Spectre hardening and partly because the uniform cast was
  never legal C — a direct precedent for "it works, and we stopped
  relying on it working".
- **Lua's `loadlib` / `lua_CFunction`**: a loaded C function must have
  the signature `int (*)(lua_State*)`. One shape, imposed on the
  library. The library is written for the host.
- **Emacs dynamic modules**: `emacs_value (*)(emacs_env*, ptrdiff_t, emacs_value*, void*)`.
  One shape.
- **SQLite's own extension loading**: `int (*)(sqlite3*, char**, const sqlite3_api_routines*)`.
  One shape.
- **QuickJS**: `JSCFunctionEnum` selects among a small handful of fixed
  C shapes (`generic`, `generic_magic`, `constructor`, `getter`,
  `setter`, …) and `js_call_c_function` switches over them. **A small
  set of trampoline shapes, chosen by a tag** — the closest structural
  analogue to what §4.2 proposes.
- **CRuby**: `vm_insnhelper.c` defines `call_cfunc_0` through
  `call_cfunc_15` — sixteen macro-generated trampolines dispatched on
  arity. **That is the "generated dispatch table over arity" design,
  built and shipped**, and it is worth noting that Ruby needs 16
  because it dispatches on arity alone (all arguments are `VALUE`, one
  class). Our two-file collapse is what removes the mask dimension;
  Ruby never had one.

**The distinction that matters for us:** every fixed-trampoline system
above imposes its shape on the callee. We are doing the opposite —
casting *someone else's* signature to our shape. That is legal at the
ABI and undefined in C, and it is sound only inside the envelope §4.3
measured. **The literature's answer to "how do you go outside the
envelope" is unanimous: generate code, or use libffi.** The spec (Axis
15.3) rejects libffi; §9's ladder therefore keeps the envelope narrow
and the refusal loud, and reaches for codegen (which the tree already
has — it *is* an LLVM compiler) if the envelope ever proves too small.

That last point deserves a sentence of its own, because it is a P6
collapse nobody has to build yet: **Avra owns a JIT-capable backend.**
If a future signature falls outside the two shapes, the compiler can
emit a real LLVM function with the real prototype and get its address —
the same mechanism `avra build` already uses, applied to one function.
That is the escape hatch (P8), and it costs nothing to leave the door
labelled.

---

## 9. THE RECOMMENDATION

### The design in one paragraph

A new C translation unit in `runtime/avra_runtime.c` — always linked
into `build/avra` and into every program — holds a symbol resolver
(`dlopen` by stem, `dlsym` by name, both cached) and **two trampolines**:
`(int64_t×8, double×8) -> int64_t` and the same `-> double`. The
interpreter declares them as its own `extern fn`s, exactly as it
already declares `avra_proc_spawn`. `rt_dispatch`'s existing
"unhosted extern" branch becomes a call into a new `foreign_val` that
classifies the extern's `RtSig` by register class, fills the two
argument vectors by class ordinal, calls, and lifts the answer back into
`Val` — **writing the empty case first**: a pointer-riding destination
holding word 0 answers `Val.N`. The manifest gains one `[link]` key,
`libraries`, a stem-only name projected two ways: `-l<stem>` onto
clang's line, `lib<stem>.<platform suffix>` into `dlopen`. Nothing
loads under `avra check`.

### The ladder

**RUNG 0 — before any of this, and above it in priority: `i32`.**
157 of SQLite's 284 entry points answer a 32-bit C `int`, and §2.3
shows the answer is not merely widened but arbitrary. Hosting the
extern under the interpreter makes **both engines agree on the wrong
answer faster**. The sized integer types are specified (Axis 15.2),
absent, and producing wrong answers today. Land `i32`/`u32` (or at
minimum a declaration-driven narrowing at the seam) before the driver
binds anything that answers `int`. This rung is not the extern host's,
but the extern host must not ship in front of it.

**RUNG 1 — the word trampoline, system libraries only.**
One shape, `int64_t f(int64_t×8)`. `libraries` in the manifest.
Hosts: every extern with ≤ 8 word seats and a word/pointer/void answer,
in a library `dlopen` can find by stem. Day one that is **the whole
minimal sqlite driver except the two `double` calls** — `open_v2`,
`close_v2`, `prepare_v2`, `step`, `finalize`, `reset`, `bind_int64`,
`bind_text`, `bind_null`, `bind_blob`, `column_count`, `column_type`,
`column_int64`, `column_text`, `column_blob`, `column_bytes`,
`column_name`, `errmsg`, `errcode`, `changes64`, `last_insert_rowid`,
`busy_timeout`, `free`, `libversion` (max arity 5).
Refuses honestly: variadic (by name, from the header keeper), > 8
seats, any `float` seat, any symbol not found, any library that will
not load.

**RUNG 2 — the vendored dylib.** The amalgamation builds to
`build/sqlite3.o` and `build/libsqlite3.dylib` from one source. The
program links the object; the interpreter loads the dylib. Closes §5.3.

**RUNG 3 — the double shape, with `float`.** `RtKind` gains `F64`,
`rt_kind_of` routes it, `ll_rt_kind` answers `double`, the second
trampoline lands, and the classification rule of §4.2 replaces "all
words". Hosts all 4 double-touching sqlite functions and every future
one. **`RtKind` growing is a registry column, not an instruction — no
eight-consumer event.**

**RUNG 4 — the extern type law.** F2059-class: which seats may cross,
measured as a warning first (F2040's lesson), promoted when the rate
justifies it. This is the rung that stops `Map<string, int>` crossing a
C boundary by accident.

**RUNG 5 — the twelve-word shape**, if `table_column_metadata` or a
future library needs it. One prototype, one branch, measured working.

**The refusal shrinks at every rung, and every rung ships a working
compiler.**

### The exact files that change

Rung 1:

| File | Change |
|---|---|
| `runtime/avra_runtime.c` | the resolver (`dlopen` by composed name, cached handle list; `dlsym` cached by name) and the word trampoline. `#include <dlfcn.h>`. On Linux, `-ldl` for glibc < 2.34. |
| `packages/std-avrac/src/language/interp.av` | `extern fn` declarations for the resolver and trampoline (beside the existing 23 at `:888-910`); a `foreign_val` method; the `unhosted_extern` branch in `rt_dispatch` (`:500-505`) becomes the dispatch to it; **`unhosted_extern` stays** as the voice for the shapes still refused. `Machine` gains the library list. |
| `packages/std-avrac/src/language/workspace.av` | `Manifest`'s new `libraries` field surfaces as a `library_names(ws)` projection beside `link_words` (`:948-956`); `Program.run()` (`:1068-1071`) passes it. |
| `packages/std-avrac/src/language/manifest.av` | `Manifest` (`:35`) gains `libraries: List<string>`; `read_manifest` (`:57`) reads `words_of("link", "libraries")`; `known_key` (`:99-107`) admits it; the stem law refuses a path. |
| `packages/std-avrac/src/features/modules/mod.av` | one `DiagCode` row for the stem law (F4015). |
| `packages/cli/src/commands/shared.av` | `clang_words` (`:275-278`) concatenates `["-l<stem>", …]`. |
| `packages/std-avrac/src/features/fns/check.av` | the seat laws: arity > 8 (F2057), variadic (F2058 — after the grammar grows `...`), and the voices at the file tail. |
| `packages/std-avrac/src/features/fns/mod.av` | the new `DiagCode` rows. |
| `tools/externs.py` | the third-party half: read a header named by the manifest, refuse a bound variadic by name, and refuse a bound narrow return until `i32` lands. |
| `packages/std-avrac/src/language/tests/*_test.av`, `features/fns/tests/*` | spec/given/then beside each. |
| `corpus/extern_host.av` + `.expected` | **the proof: one corpus program calling a system library, eval == native.** |
| `Makefile` | nothing for rung 1; rung 2 adds the dylib build beside `build/avra_runtime.o`. |
| `ROADMAP.md`, `CLAUDE.md` | the grammar defect of §1.2 into "The subset today"; the two-register-file law into the doctrine list. |

Rung 3 additionally: `core/ir.av` (`RtKind`), `core/runtime_api.av`
(`rt_kind_of`), `language/llvm.av` (`ll_rt_kind`, `rt_arg`,
`call_rt_value`), plus everything the `float` core event touches, which
is `..._RESEARCH_core_value_cost.md`'s subject and not this paper's.

### What this buys, stated as the campaign's own metric

Every C binding in every package runs identically under `avra run` and
natively **within a measured envelope**, and outside that envelope the
compiler names the reason rather than trapping with "build natively".
The envelope is: ≤ 8 integer/pointer seats, ≤ 8 floating seats, no
variadic, a symbol in a loadable library. That covers 273 of SQLite's
284 entry points and 100% of a real driver.

---

## Appendix — the probe log

All sources are under
`/private/tmp/claude-502/…/scratchpad/abi/`. Environment: `arm64`,
macOS 26.5.2 (build 25F84), Apple clang 21.0.0, all C at `-O2`;
x86-64 results are the same sources built `-arch x86_64` and run under
Rosetta.

| # | File | What it establishes |
|---|---|---|
| P1 | `lib.c` + `tramp.c` | 8-word trampoline calls arity 0–8 correctly; pointers and void callees ride it; the narrow-return table. |
| P2 | `dirty.c` + `dirty_main.c` | `_trunc_of` is a bare `ret`; a C `int` read as a word returns the ARGUMENT's high bits. Both targets. |
| P3 | `vlib.c` + `vmain.c` | variadic through the uniform trampoline: garbage on arm64, correct on x86-64. `snprintf` both ways. |
| P4 | `fplib.c` + `fpmain.c` | a double cannot ride an integer register; a double return leaves `x0` untouched; the `-> double` shape reads it. |
| P5 | `mixlib.c` + `mixmain.c` | **the collapse**: two shapes, six interleavings including sqlite's exact double shapes, both targets. |
| P6 | `mixlib.c` + `ninemain.c` | the boundary: 9 word seats break the two-file shape, a 12-word shape carries them. |
| P7 | `stack.c` | caller-cleans, 10 000 over-long calls, and a stack-passed 9th argument. |
| P8 | `vendored.c` + `host.c` | `dlsym(RTLD_DEFAULT)` finds a linked static object's symbol — unless `-dead_strip` removed it; `dlopen("libsqlite3.dylib")` works with no file on disk; `libsqlite3.so` does not. |
| P9 | `oload.c` | `dlopen` refuses a `.o` and a `.a`, accepts a `.dylib`. |
| P10 | `sqlite3.h` (SDK) classification | 284 entry points: 8 variadic, 2 return `double`, 2 take `double`, 157 answer a 32-bit int, 3 exceed 8 arguments, 43 take a function pointer. |
| P11 | `./avra check` scratch probes | the extern type vocabulary (15 shapes, 14 accepted); `-> List<int>` swallows the next line; `ptr` refuses `== null`; `ptr?` works; `float`/`i32` name no type. |
| P12 | `./avra run` scratch probe | `` `sqlite3_libversion_number` is extern — the evaluator cannot host it; build natively``, exit 1. |

Sources consulted for the ABI rules beyond measurement:
[Writing ARM64 code for Apple platforms](https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms) ·
[AAPCS64](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst) ·
[The AArch64 processor, part 20: the classic calling convention](https://devblogs.microsoft.com/oldnewthing/20220823-00/?p=107041) ·
[JEP 442 / Panama FFM](https://openjdk.org/jeps/442) ·
[panama_ffi.md](https://github.com/openjdk/panama-foreign/blob/foreign-memaccess+abi/doc/panama_ffi.md)
