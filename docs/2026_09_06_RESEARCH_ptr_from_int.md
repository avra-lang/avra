# Minting a pointer from an integer — the ruling, and what it rests on

Research for the `ptr` decision. Compressed from the 822-line survey; git
history carries the full prior-art quotations for Rust, Zig, Swift, Go, C#,
Java, D/Nim/Odin, C, and the provenance models (strict provenance, PNVI,
CHERI). What survives is the probe, the danger analysis, and the
recommendation — the parts a decision rests on.

## 0. The Avra situation, probed

`./avra check` on four scratch files, this tree, 2026-09-06:

```
let q: ptr = 0        error[F2024]: `q` declares `ptr`, this is `int`
let q: ptr = null     error[F2024]: `q` declares `ptr`, this is `null`
let q: ptr = n as ptr error[F0100]: expected BREAK while parsing `stmt`
use_ptr(q)  q: ptr?   error[F2000]: argument 1 of `use_ptr` wants `ptr`, found `ptr?`
```

So: no integer seat, no null seat, no `as` operator at all (there is no cast
syntax in the grammar to extend), and `ptr?` is a distinct type from `ptr`
with a null niche (`scratch/sqlite/q_ptrnull.av` already proves `p == null`
over an `extern fn` answer).

The forcing case is C sentinels. Note what `SQLITE_TRANSIENT` actually is —
straight from `sqlite/src/sqlite.h.in`:

```c
typedef void (*sqlite3_destructor_type)(void*);
#define SQLITE_STATIC      ((sqlite3_destructor_type)0)
#define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
```

It is a **function** pointer, not a data pointer. That matters exactly once,
in §2's hazard table, and nowhere else. `MAP_FAILED` is `((void *)-1)`; `RTLD_DEFAULT` is
`((void *)0)` on glibc and `((void *)-2)` on Darwin.

---

---

## 1. What the prior art rules — the survey, in one table

Nine languages, each asked: can you make a pointer from an integer, how is it
spelled, and where is the danger drawn?

| Language | Spelling | Allowed in the safe subset? | Where danger is drawn |
|---|---|---|---|
| **Rust** | `ptr::without_provenance(n)`; `n as *const T` (lint-flagged) | Yes — safe to *create* | At the dereference; provenance governs access, not materialization |
| **Zig** | `@ptrFromInt(n)` — a builtin, no cast form | Yes, comptime and runtime | "as long as ptr is never dereferenced"; address 0 needs `allowzero` |
| **Swift** | `UnsafeRawPointer(bitPattern: n)` — **failable**, `nil` for 0 | Yes | At the load; the initializer is `init?` precisely because 0 is absent |
| **Java (FFM)** | `MemorySegment.ofAddress(n)` | Yes, unrestricted | `reinterpret` is the restricted call; `ofAddress` alone cannot read |
| **C#/.NET** | `new IntPtr(-1)`, `(void*)n` | `IntPtr` safe; `void*` needs `unsafe` | UB "if the result is dereferenced" |
| **Go** | `unsafe.Pointer(uintptr(n))` | Discouraged; GC-unsafe | Forbids the round-trip for GC reasons |
| **C** | `(void*)n` | Implementation-defined | Trap representations (Itanium-class only) |
| **D / Nim / Odin** | direct cast | Yes | At the dereference |
| **CHERI** | integer→pointer yields an untagged capability | Yes | Hardware tag fault on dereference |

**The convergent ruling: every language that revisited this moved toward a
NAME and away from a CAST.** Rust shipped `as`, then added named constructors,
then a lint against the cast. Zig never had one. Swift uses an argument label,
Java a static factory, .NET a constructor. Nobody chose an operator on purpose.

---

## 2. Is it dangerous? Three questions, not one

The literature conflates these constantly; separated, the answer is clear.

- **(a) CREATING a bogus pointer value — not dangerous**, on any target Avra
  ships to, in any model surveyed. Rust: "always sound for an integer to
  pretend to be a pointer 'for fun'". Zig, C#, Java agree. The one theoretical
  hazard is C's trap-representation clause, which exists for Itanium-class
  machines; no bit pattern traps on load on x86-64 or AArch64. Confidence HIGH.
- **(b) DEREFERENCING it — this is the entire danger, and Avra does not have
  the operation.** No load, no store, no pointer arithmetic. Every citation in
  every model puts the UB here.
- **(c) PASSING it to foreign code — the real risk, and it is a CONTRACT risk,
  not a provenance risk.** And the capability already exists: Avra can already
  hand C a stale pointer from a previous call, or a pointer from library A at a
  seat expecting library B's. Each is *more* dangerous than `-1`, because a
  stale real pointer looks valid and often reads without faulting, while `-1`
  faults immediately and loudly. Minting a sentinel occupies a corner of a
  surface already open. And for a callee that compares against a documented
  sentinel and never loads from it — `sqlite3_bind_text`'s `xDel`, `mmap`'s
  return — nothing can go wrong: the value is a tag, compared by identity,
  never followed.

### Platform and ABI hazards, honestly rated

| Hazard | Bites? |
|---|---|
| **Optimizer / provenance** (`noalias`, `restrict`) | **No.** The optimizations at risk are about *memory accesses through* the pointer. Nothing reads through it. |
| **CHERI** | **No.** Integer→pointer yields an untagged, NULL-derived capability with the right address. It can be held, stored, passed, and compared; it faults only on dereference. CHERI's actual rule — never round-trip a *real* pointer through a non-`uintptr_t` integer type — is about *losing* provenance a pointer had, which is a different mistake. Confidence: HIGH from the CHERI literature and the SOSP 2023 CHERI tutorial: "cast from provenance-free integer type to pointer type will give pointer that can not be dereferenced". |
| **arm64e pointer authentication — data pointers** | **No.** Clang docs, verbatim: "The current implementation in Clang does not sign pointers to ordinary data by default." Also: null pointers keep "their usual representation" and are not signed. |
| **arm64e PAC — FUNCTION pointers** | **The one real caveat.** "C function pointers are currently signed with the IA key without address diversity and with a constant discriminator of 0." `SQLITE_TRANSIENT` *is* a function pointer. It is safe in practice — SQLite recognizes the sentinel before ever calling `xDel`, and the C side builds its own `((type)-1)` constant, so `==` matches; `libsqlite3-sys` transmutes `-1isize` into a signed-fnptr type and ships on Apple silicon. But the mechanism is "nobody authenticates it", not "it is a valid signed pointer". Confidence: HIGH empirically (it works in the field today), MEDIUM on the exact ABI mechanism. **Write it down: a sentinel in a function-pointer seat is safe only for as long as the callee never calls it.** The day Avra grows real C callbacks, a real callback in that seat must be correctly signed and the sentinel must not be. |
| **Tagged pointers** (Objective-C, JS engines) | **No.** Those are conventions *inside* a runtime that owns its own pointers. A sentinel handed to a C API that documents it is not participating. |

---

---

## 3. Recommendation

For a language whose pointers are opaque and non-dereferenceable, that needs C
sentinels, and that wants the dangerous thing to be hard to write by accident:

### 3.1 A named constructor, never a cast operator — HIGH confidence

Every surveyed language that has revisited this decision has moved *toward*
naming and *away* from casting:

- Rust shipped `as`, then defined it as the ambiguous exposed-provenance form,
  then added named constructors, then added a lint telling you to use them.
- Zig never had a cast — it has an `@`-builtin, deliberately unspellable
  without a name.
- Swift uses an argument label (`bitPattern:`), which is a name at the call
  site.
- Java uses a static factory (`ofAddress`).
- .NET uses a constructor (`new IntPtr(-1)`).

Nobody chose an operator on purpose. A cast is the one form that can arrive by
*inference* — through a generic seat, a widening, a coercion — which is
exactly the accident to prevent.

For Avra this is also the cheap option: the probe shows `n as ptr` is
`error[F0100]: expected BREAK` — **there is no cast syntax in the grammar to
extend.** A named fn is one declaration; a cast operator is a grammar feature,
a precedence question, a typer rule, and a new class of inference accident.
P3 (zero ceremony) is not served by an operator here; P7 (visible magic) and
the "hard to write by accident" bar are both served by the name.

### 3.2 It answers `ptr?`, and 0 answers `null` — HIGH confidence

```
fn ptr_at(address: int) -> ptr?
```

Total — it never fails, never answers a `Result`. But its answer type is `ptr?`,
and for `address == 0` the answer *is* `null`.

This is Swift's `init?`, and it is Swift's design for Swift's reason, which is
also Avra's reason: **the null niche.** Probed above — `ptr?` exists,
`p == null` works, `let q: ptr = null` is F2024. Address zero *is* the absent
pointer in Avra's representation. A function that answered a non-optional
`ptr` would have to either lie about 0 or trap on it; answering `ptr?` makes
0 a correct answer rather than an error case. This is P6: the "should it be
failable or total?" dichotomy collapses — it is total, and the *type* carries
what failability would have carried.

It also gets `SQLITE_STATIC` for free: that is `((type)0)`, so
`ptr_at(0) == null`, and `rusqlite` reaches the identical conclusion
independently (`SQLITE_STATIC() -> None`).

Cost: one unwrap at each sentinel site. Which is why —

### 3.3 The sentinel gets a home at the binding, not a language restriction — HIGH confidence

```
// the C macro is ((sqlite3_destructor_type)-1)
fn sqlite_transient() -> ptr? { ptr_at(-1) }
```

One unwrap, written once, beside the `extern` block that names the foreign
contract. That is P9 (boundaries are contracts) and it makes the tree's entire
sentinel inventory one grep. It is also precisely what Rust does
(`libsqlite3-sys`'s `SQLITE_TRANSIENT()` is a named fn wrapping the transmute)
and what .NET does (`SafeHandleZeroOrMinusOneIsInvalid`).

### 3.4 Do NOT restrict to compile-time constants — MEDIUM-HIGH confidence

Tempting, and it buys nothing on the axis that matters:

- **It does not improve safety.** A literal `0xdeadbeef` is exactly as bogus as
  a runtime one. The safety comes from the absent dereference, not from when
  the number was known.
- **It breaks legitimate cases.** An address marshalled through an integer
  field, a handle from a config, a platform-conditional sentinel
  (`RTLD_DEFAULT` is `0` on glibc and `-2` on Darwin — the *value* varies).
- **Avra cannot express it today.** `@comptime` is in the subset list
  ("refuses at the `@`"), so the restriction would require building a language
  feature first, for a benefit of zero.
- **No surveyed language does it.** Zig's `@ptrFromInt` works at comptime *and*
  runtime, and the langref demonstrates both.

What actually delivers "hard to write by accident" is (a) the name, (b) the
`ptr?` answer forcing an unwrap, (c) the greppable site. All three are free.

### 3.5 Do NOT introduce a second, distinguishable pointer type — HIGH confidence

This is the recommendation I hold most firmly, and the reasoning is specific
to Avra rather than borrowed.

Every language that distinguishes a "real" pointer from a synthetic one does
so **to gate dereference**:

| Language | non-dereferenceable | dereferenceable |
|---|---|---|
| Java FFM | zero-length `MemorySegment` (`ofAddress`) | `reinterpret`'d segment (restricted) |
| .NET | `IntPtr` / `nint` (safe) | `void*` (unsafe) |
| CHERI | untagged capability | tagged capability |
| Rust | no-provenance pointer | pointer with provenance |

**Avra's `ptr` is already the left column.** It is already
`MemorySegment.ofAddress`'s answer; it is already `IntPtr`. A second type would
draw a line with no operation behind it — the "parallel concept" that the IR
vocabulary protocol's rule 2 (GENERALIZE BEFORE ADDING) exists to refuse.

And it would be actively *wrong* at the seat. `sqlite3_bind_text`'s `xDel`
parameter takes **either** a real destructor **or** `SQLITE_TRANSIENT`. In C
those are one type. If Avra made them two, that seat could hold neither
without a union, and the binding would have to lie. P9: the boundary is the
contract, and the contract says one type.

What should be visible is the **site**, not the type. The named constructor
already gives that.

### 3.6 Ship one direction only — HIGH confidence

Add `int → ptr`. Do **not** add `ptr → int` in the same slice.

The reverse direction is the genuinely dangerous one, and it is dangerous in
all three literatures at once: it is Rust's `expose_provenance` (the operation
Rust documents as being on "much less solid footing", that "will not work
(well) with tools like Miri and CHERI"); it is the direction Go forbids for GC
reasons; and it is the operation CHERI actually breaks, because casting a real
capability to a non-`uintptr_t` integer **destroys the tag**. Sentinels need
none of it. Leave it out until something forces it, and when something does,
research it separately.

### 3.7 Teach the compiler to say it — MEDIUM confidence, cheap

Today the refusal is bare:

```
error[F2024]: `q` declares `ptr`, this is `int`
```

The compiler knows the answer (P10, P7). Give F2024 a help line naming
`ptr_at` when the declared type is `ptr` and the value is an int, and a
matching one when it is `null`. That is the "escape hatches everywhere" (P8)
half of the design, and it turns a wall into a signpost for the LLM-first
first-generation metric (P1).

### 3.8 One thing to write down now

The arm64e function-pointer caveat from the hazard table in §2. `SQLITE_TRANSIENT` is a function
pointer; Clang signs C function pointers on arm64e. The sentinel is safe
because the callee compares before it calls, never because the value is a
valid signed pointer. When Avra grows real C callbacks, a real callback in
that seat needs signing and the sentinel must not get it. That is a
two-years-later bug unless it is a comment today.

---

## Sources

- [Rust Reference — operator expressions (cast table, address-to-pointer)](https://doc.rust-lang.org/reference/expressions/operator-expr.html)
- [Rust Reference — behavior considered undefined](https://doc.rust-lang.org/reference/behavior-considered-undefined.html)
- [Rust `std::ptr` — Provenance, Strict Provenance, Exposed Provenance](https://doc.rust-lang.org/std/ptr/index.html)
- [Rust `std::ptr::without_provenance`](https://doc.rust-lang.org/std/ptr/fn.without_provenance.html)
- [rustc lint `implicit_provenance_casts`](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#implicit-provenance-casts)
- [Ralf Jung — *Pointers Are Complicated III, or: Pointer-integer casts exposed*](https://www.ralfj.de/blog/2022/04/11/provenance-exposed.html)
- [Zig Language Reference — `@ptrFromInt`, Pointers, `allowzero`, Pointer Cast Invalid Null](https://ziglang.org/documentation/master/#ptrFromInt) (quoted from [`doc/langref.html.in`](https://github.com/ziglang/zig/blob/master/doc/langref.html.in) at master)
- [ziglang/zig#24326 — C pointer checks alignment with `@ptrFromInt`](https://github.com/ziglang/zig/issues/24326)
- [Swift Forums — *Why is UnsafePointer(bitPattern:) failable?*](https://forums.swift.org/t/why-is-unsafepointer-bitpattern-failable/11038)
- [Swift — `UnsafeRawPointer`](https://developer.apple.com/documentation/swift/unsaferawpointer)
- [Go — `src/unsafe/unsafe.go`, the six valid `unsafe.Pointer` patterns](https://go.dev/src/unsafe/unsafe.go)
- [C# standard (draft-v7) — unsafe code, pointer conversions](https://github.com/dotnet/csharpstandard/blob/draft-v7/standard/unsafe-code.md)
- [.NET — `SafeHandleZeroOrMinusOneIsInvalid`, `IntPtr`](https://learn.microsoft.com/en-us/dotnet/api/system.intptr)
- [Java — `MemorySegment` javadoc (JDK 25): `ofAddress`, `reinterpret`, zero-length segments](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/foreign/MemorySegment.html)
- [JEP 454: Foreign Function & Memory API](https://openjdk.org/jeps/454)
- [D — Memory-Safe-D spec](https://dlang.org/spec/memory-safe-d.html)
- [Clang — Pointer Authentication](https://clang.llvm.org/docs/PointerAuthentication.html)
- [CHERI C/C++ Programming Guide (UCAM-CL-TR-947)](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf)
- [SOSP 2023 CHERI tutorial — adapting C, answers](https://www.cl.cam.ac.uk/~pffm2/sosp2023_cheri_tutorial/exercises/6_adapt-c/answers.html)
- [N2577 — A Provenance-aware Memory Object Model for C (draft TS)](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2577.pdf)
- [CERT INT36-C — Converting a pointer to integer or integer to pointer (quotes C §6.3.2.3¶5)](https://wiki.sei.cmu.edu/confluence/display/c/INT36-C.+Converting+a+pointer+to+integer+or+integer+to+pointer)
- [sqlite — `src/sqlite.h.in` (`SQLITE_STATIC`, `SQLITE_TRANSIENT`)](https://github.com/sqlite/sqlite/blob/master/src/sqlite.h.in)
- [rusqlite — `libsqlite3-sys/src/lib.rs` (`SQLITE_TRANSIENT()`)](https://github.com/rusqlite/rusqlite/blob/master/libsqlite3-sys/src/lib.rs)
