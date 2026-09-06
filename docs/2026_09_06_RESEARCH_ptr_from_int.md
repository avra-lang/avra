# Minting a pointer from an integer — prior art, and what it costs

Research for the `ptr` decision. Every claim below is either a quote from a
primary source (language reference, standard, stdlib doc, compiler doc) or
marked with its confidence. Where a claim could be probed, it was probed and
the OUTPUT is quoted, not the reasoning.

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
in §5, and nowhere else. `MAP_FAILED` is `((void *)-1)`; `RTLD_DEFAULT` is
`((void *)0)` on glibc and `((void *)-2)` on Darwin.

---

## 1. Rust

### `1usize as *const u8` IS allowed in safe Rust

This is the misconception the question anticipated. The cast needs no
`unsafe`. From the [Rust Reference, operator
expressions](https://doc.rust-lang.org/reference/expressions/operator-expr.html),
cast table:

| Type of `e` | `U` | Cast performed by `e as U` |
|---|---|---|
| `*T` where `T: Sized` | Integer type | Pointer to address cast |
| Integer type | `*V` where `V: Sized` | Address to pointer cast |

> **Address to pointer cast** — Casting from an integer to a raw pointer
> interprets the integer as a memory address and produces a pointer
> referencing that memory.
>
> **Warning:** This interacts with the Rust memory model, which is still under
> development. A pointer obtained from this cast may suffer additional
> restrictions even if it is bitwise equal to a valid pointer. Dereferencing
> such a pointer may be undefined behavior if aliasing rules are not followed.

The `unsafe` is on the **dereference**, not the creation. Confidence: HIGH.

### Creating an invalid pointer is not UB; accessing through it is

From [behavior considered
undefined](https://doc.rust-lang.org/reference/behavior-considered-undefined.html),
the UB entry is about **access**:

> "Accessing (loading from or storing to) a place that is dangling or based on
> a misaligned pointer."
>
> "Note that a place based on a misaligned pointer only leads to undefined
> behavior when it is loaded from or stored to." — and `&raw const`/`&raw mut`
> on such a place is allowed.

And the validity requirements make the asymmetry explicit:

> "An integer (`i*`/`u*`), floating point value (`f*`), or raw pointer must be
> initialized, i.e., must not be obtained from uninitialized memory."

versus

> "A reference or `Box<T>` must be aligned and non-null, it cannot be dangling,
> and it must point to a valid value…"

A raw pointer as a **value** may be null, misaligned, or dangling. Only
`&`/`Box` carry validity. Confidence: HIGH.

### Strict provenance, and why it exists

A Rust pointer is not just an address. From
[`std::ptr`](https://doc.rust-lang.org/std/ptr/index.html):

> A pointer value semantically contains "the **address** it points to… [and]
> the **provenance** it has, defining the memory it has permission to access.
> Provenance can be absent, in which case the pointer does not have permission
> to access any memory."

> "It is undefined behavior to access memory through a pointer that does not
> have provenance over that memory."

Why the strict-provenance APIs were introduced:

> "Entirely avoiding integer-to-pointer casts successfully side-steps the
> inherent ambiguity of that operation. This benefits compiler optimizations,
> and it is pretty much a requirement for using tools like Miri and
> architectures like CHERI that aim to detect and diagnose pointer misuse."

The concrete optimization hazard is spelled out by Ralf Jung (Rust opsem
lead) in [*Pointers Are Complicated III, or: Pointer-integer casts
exposed*](https://www.ralfj.de/blog/2022/04/11/provenance-exposed.html): three
individually sound optimizations (replacing equal integers, removing dead
casts, eliminating loads after writes through `restrict`/`noalias` pointers)
compose to change a program's output, because

> "casting a pointer to an integer *has a side-effect*, and that side-effect
> has to be preserved even if we don't care about the result of the cast."
>
> "When you cast a pointer to an integer, you are basically declaring that its
> permission is 'up for grabs', and any future integer-pointer cast may end up
> endowing the resulting pointer with this permission."

**Note the direction.** The hazard is in `ptr → int` (which *exposes*
provenance) and in `int → ptr` *picking up* an exposed provenance. A pointer
minted from a constant that was never a pointer exposes nothing and claims
nothing.

### `ptr::without_provenance` — Rust's blessed sentinel constructor

```rust
pub const fn without_provenance<T>(addr: usize) -> *const T
```

Stable since **1.84.0**, `const`, and **safe** (not `unsafe`). Its own docs:

> Creates a pointer with the given address and no provenance. This is
> equivalent to `ptr::null().with_addr(addr)`.
>
> Without provenance, this pointer is not associated with any actual
> allocation. Such a no-provenance pointer may be used for zero-sized memory
> accesses (if suitably aligned). … No-provenance pointers are little more
> than a `usize` address in disguise.
>
> This is different from `addr as *const T`, which creates a pointer that
> picks up a previously exposed provenance.

And the `std::ptr` module doc names **this exact use case**, unprompted:

> "Create a pointer without provenance from just an address (see
> `without_provenance`). Such a pointer **cannot be used for memory accesses**
> (except for zero-sized accesses). **This can still be useful for sentinel
> values like `null` or to represent a tagged pointer that will never be
> dereferenceable.**"

And, the money quote for §5:

> "In general, it is **always sound for an integer to pretend to be a pointer
> 'for fun' as long as you don't use operations on it which require it to be
> valid** (non-zero-sized offset, read, write, etc)."

Confidence: HIGH. This is Rust's official position, in the stdlib docs, and
it says the Avra case is sound.

### `as` casts from integers ARE now lint-flagged

The lint is `implicit_provenance_casts` (allow-by-default, behind
`#![feature(strict_provenance_lints)]`). From [the rustc lint
listing](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#implicit-provenance-casts):

```
warning: cast from `usize` to `*const u8` implicitly relies on exposed provenance
  = help: if conforming to strict provenance is not possible,
          use `std::ptr::with_exposed_provenance()`
help: use `.with_addr()` to adjust the address of a valid pointer in the same allocation
```

> "Earlier versions of Rust did not have a clear answer how integer-to-pointer
> and pointer-to-integer casts interact with provenance. Such casts are now
> defined to use the exposed provenance model, but in many cases the code can
> be updated to strict provenance APIs, which is preferable as it enables more
> precise reasoning about unsafe code, both by humans and by tools like Miri."

Rust's trajectory is unambiguous: **away from the cast operator, toward named
constructors.** For a sentinel the lint-clean answer is `without_provenance`,
which is safe, `const`, and stable.

### Function pointers are harder in Rust than data pointers

There is **no** `as` cast from an integer to a function pointer. Real-world
proof — `rusqlite`'s `libsqlite3-sys/src/lib.rs`:

```rust
pub fn SQLITE_STATIC() -> sqlite3_destructor_type { None }

pub fn SQLITE_TRANSIENT() -> sqlite3_destructor_type {
    Some(unsafe { mem::transmute::<isize, unsafe extern "C" fn(*mut core::ffi::c_void)>(-1_isize) })
}
```

Three things to note, all directly relevant:
1. `SQLITE_STATIC` (address 0) is `None` — the **Option niche**, not a
   pointer. Exactly the Swift shape, exactly Avra's `ptr?`.
2. `SQLITE_TRANSIENT` needs `unsafe` + `transmute` only because Rust has no
   safe int→fnptr path; the *data*-pointer twin would need neither.
3. Both are wrapped in a **named function**, once, at the binding layer.

---

## 2. Zig

`@ptrFromInt` from the [language
reference](https://ziglang.org/documentation/master/#ptrFromInt) (quoted from
`doc/langref.html.in` at master, verbatim):

```
@ptrFromInt(address: usize) anytype
```

> Converts an integer to a pointer. The return type is the inferred result
> type. To convert the other way, use `@intFromPtr`. **Casting an address of 0
> to a destination type which in not optional and does not have the
> `allowzero` attribute will result in a Pointer Cast Invalid Null panic when
> runtime safety checks are enabled.**
>
> If the destination pointer type does not allow address zero and `address` is
> zero, this invokes safety-checked Illegal Behavior.

### Compile-time or runtime?

**Both, and it is not an error in general.** The langref's own test file
`doc/langref/test_comptime_pointer_conversion.zig` is:

```zig
test "comptime @ptrFromInt" {
    comptime {
        // Zig is able to do this at compile-time, as long as
        // ptr is never dereferenced.
        const ptr: *i32 = @ptrFromInt(0xdeadbee0);
        const addr = @intFromPtr(ptr);
        try expect(@TypeOf(addr) == usize);
        try expect(addr == 0xdeadbee0);
    }
}
```

Read that comment again — it is Zig's language reference stating the exact
premise of this decision: **minting is fine as long as you never dereference.**
It works at comptime *and* at runtime; the identical test exists without the
`comptime` block (`test_integer_pointer_conversion.zig`).

### Address 0

Zig routes zero through the **type system**, three ways:
- `?*T` — optional pointer, and null *is* address 0 (the niche).
- `*allowzero T` — a pointer permitted to be zero. From the langref:
  "This is only ever needed on the freestanding OS target, where the address
  zero is mappable. **If you want to represent null pointers, use Optional
  Pointers instead.** Optional Pointers with `allowzero` are not the same size
  as pointers."
- `[*c]T` — C pointers, which allow zero.

For a plain `*T`, address 0 is a `Pointer Cast Invalid Null` panic at runtime
(with safety on) and a compile error at comptime. Confidence: HIGH.

### Alignment

The langref does **not** state an alignment rule for `@ptrFromInt`. In
practice Zig checks it against the destination type:
[ziglang/zig#24326](https://github.com/ziglang/zig/issues/24326) shows
`@as([*c]u64, @ptrFromInt(1))` failing with

```
pointer type '[*c]u64' requires aligned address
```

while `@as([*c]u64, 1)` compiles. Confidence: MEDIUM-HIGH (issue-reported, not
langref-documented; design intent unresolved in the thread).

**This detail matters for Avra and cuts in our favour:** the check is against
the *pointee type's* alignment. `anyopaque` has alignment 1, so
`@ptrFromInt(0xFFFF_FFFF_FFFF_FFFF)` into `?*anyopaque` — the sentinel case —
is unconstrained. Avra's `ptr` is opaque by construction, so an alignment rule
would be vacuous.

### How does Zig fence this with no `unsafe` blocks?

It doesn't fence the creation at all. The fencing is three other things, and
all three are available to Avra:

1. **A named `@`-builtin, never an operator or implicit conversion.** It is
   greppable, it cannot arrive by inference, and it never appears by accident.
2. **The type encodes which addresses are legal** (`*T` / `?*T` /
   `*allowzero T` / `[*c]T`) — so the zero case is a *type* question, answered
   at the seat, not a runtime discipline.
3. **Safety-checked Illegal Behavior** turns the one genuinely invalid case
   (0 into a non-optional) into a panic in Debug/ReleaseSafe.

Zig's answer to "how do you make the dangerous thing hard to write by
accident" is *naming plus type distinctions*, not a block.

---

## 3. Swift

```swift
init?(bitPattern: Int)
init?(bitPattern: UInt)
```

> Creates a new raw pointer from the given address, specified as a bit
> pattern.
>
> - Parameter `bitPattern`: A bit pattern to use for the address of the new
>   raw pointer. **If `bitPattern` is zero, the result is `nil`.**

It returns `UnsafeRawPointer?`, and **no `unsafe` context is required** —
Swift has no such construct here. The entire safety signal is the *type name*:
`UnsafeRawPointer`. Confidence: HIGH.

### Why failable — and this is the part that maps onto Avra

The rationale, from Jordan Rose (Swift core team) on the Swift Forums thread
["Why is UnsafePointer(bitPattern:)
failable?"](https://forums.swift.org/t/why-is-unsafepointer-bitpattern-failable/11038):

> "The initializer isn't trying to protect you; it's just doing the same thing
> that C does when you say `(void *)bitPattern`."

and, on forcing zero into a non-optional pointer anyway:

> "you're likely to run afoul of optimizations that assume things about
> optional and non-optional pointers if you do."

So the failability is **not a safety check**. It is a *representation* fact:
Swift's `Optional<UnsafeRawPointer>` uses the null-pointer bit pattern as its
`nil` — the niche — so a **non-optional** pointer structurally cannot hold 0.
The `init?` is not "this might fail", it is "the answer type is the one that
can express every input".

This is Avra's situation exactly. Probed above: `ptr?` exists, `null` compares
against it, and `let q: ptr = null` is refused (F2024). Avra has the same
niche, so it has the same constraint, so the same answer shape is available:
**answer `ptr?`, and let 0 be `null`.** That is not a failure mode; it is the
correct answer, because in Avra's representation address zero *is* the absent
pointer.

---

## 4. Everyone else

### Go — the strictest, and it says "don't"

From `src/unsafe/unsafe.go`, verbatim:

> "Conversion of a uintptr back to Pointer is not valid in general.
>
> A uintptr is an integer, not a reference. Converting a Pointer to a uintptr
> creates an integer value with no pointer semantics. Even if a uintptr holds
> the address of some object, the garbage collector will not update that
> uintptr's value if the object moves, nor will that uintptr keep the object
> from being reclaimed.
>
> **The remaining patterns enumerate the only valid conversions from uintptr
> to Pointer.**"

The six valid patterns, summarized:

1. `*T1` → `Pointer` → `*T2`, where T2 is no larger than T1 and they share an
   equivalent memory layout (e.g. `math.Float64bits`).
2. `Pointer` → `uintptr`, one-way, for printing/arithmetic. (Not back.)
3. `Pointer` → `uintptr` → arithmetic → `Pointer`, **both conversions in the
   same expression**, and the result must stay inside the original allocated
   object. Advancing one-past-the-end is `// INVALID: end points outside
   allocated space.` Storing the intermediate in a variable is `// INVALID:
   uintptr cannot be stored in variable`.
4. `Pointer` → `uintptr` as a `syscall.Syscall` argument — the conversion must
   appear **in the call expression itself**.
5. `reflect.Value.Pointer()` / `UnsafeAddr()` results — converted to `Pointer`
   **immediately after the call, in the same expression**.
6. `reflect.SliceHeader` / `StringHeader` `Data` field, when the header points
   at an actual slice or string.

**Not one of the six is "an arbitrary integer".** Go's reason is not
provenance in the C sense — it is the **moving garbage collector**: a `uintptr`
neither pins nor tracks. Go's consequence for sentinels is therefore
structural: keep the sentinel as `uintptr` and never convert. Low-level `mmap`
returns a `uintptr` and `MAP_FAILED` is compared as an integer.

Go is the outlier because Go has a constraint Avra does not: a relocating
collector. Avra refcounts headered boxes and never moves them. Confidence:
HIGH on the rules, HIGH on the reason.

### C# — the boundary is the dereference, and there are two types

From the [C# standard, `unsafe-code.md`
(draft-v7)](https://github.com/dotnet/csharpstandard/blob/draft-v7/standard/unsafe-code.md):

> Explicit conversions: "From `sbyte`, `byte`, `short`, `ushort`, `int`,
> `uint`, `long`, or `ulong` to any *pointer_type*" (and back).
>
> "if the resulting pointer is not correctly aligned for the pointed-to type,
> **the behavior is undefined if the result is dereferenced**."

The UB is explicitly conditioned on the dereference. `(void*)n` needs an
`unsafe` context; `void*` cannot be dereferenced or arithmetic'd anyway
("Because the referent type is unknown, the indirection operator cannot be
applied to a pointer of type `void*`").

**And here is the .NET data point that matters most:** the idiomatic .NET
sentinel does not use `void*` at all. `INVALID_HANDLE_VALUE` is
`new IntPtr(-1)` — constructed in **fully safe code**, no `unsafe` context —
and the BCL ships `SafeHandleZeroOrMinusOneIsInvalid` as a first-class base
class built on exactly that. .NET has **two** address types: `IntPtr`/`nint`,
safe and non-dereferenceable, and `void*`, unsafe and dereferenceable.

**Avra's `ptr` is `IntPtr`, not `void*`.** Confidence: HIGH.

### Java — the FFM API, and the clearest ruling on this exact question

This is the strongest structural precedent, because Java's Foreign Function &
Memory API (JEP 454, final in JDK 22) is the most recently designed,
most safety-conscious FFI in wide use, and it had to answer *precisely* this
question. Verified against the JDK 25 javadoc:

| Method | Restricted? |
|---|---|
| `static MemorySegment ofAddress(long address)` | **NO** |
| `MemorySegment reinterpret(long newSize)` | **YES** |

`ofAddress` javadoc, in full:

> "Creates a zero-length native segment from the given address value.
> Throws `IllegalArgumentException` if `address == Long.MIN_VALUE`."

`reinterpret` javadoc carries the badge:

> "`reinterpret` is a restricted method of the Java platform. Programs can only
> use `reinterpret` when access to restricted methods is enabled. Restricted
> methods are unsafe, and, if used incorrectly, might crash the JVM or result
> in memory corruption."

And on why zero-length segments exist at all:

> "The size of the segment is zero. Any attempt to access these segments will
> fail with `IndexOutOfBoundsException`. This is a crucial safety feature: as
> these segments are associated with a region of memory whose size is not
> known, any access operations involving these segments cannot be validated.
> **In effect, a zero-length memory segment wraps an address, and it cannot be
> used without explicit intent.**"

`MemorySegment.NULL` is defined as `ofAddress(0L)`.

Java drew the safety line **exactly between creating an address and reading
through one**, and put "create" on the safe side. Confidence: HIGH.

(Aside worth a grin, given this tree's law that *an encoding spends the empty
value*: `ofAddress` rejects `Long.MIN_VALUE`. Somewhere in there an encoding
spent a value, and the API had to carve it back out. Write the empty case
first.)

### D, Nim, Odin

- **D**: casting a non-pointer type to a pointer type is not permitted in
  `@safe` code; it requires `@system`, or `@trusted` — a function with "a safe
  interface" that "internally… ha[s] all the capabilities of `@system`
  functions". D is the one surveyed language that gates the *creation* itself,
  and it gates it with a **wrapper function**, not a block. Confidence:
  MEDIUM-HIGH (the spec's @safe prohibition list is phrased generally —
  "Casts that break the type system", "Modification of pointer values").
- **Nim**: `cast[pointer](0xdeadbeef)` is permitted; `cast` is documented as
  unsafe by convention only. No enforcement.
- **Odin**: no safe/unsafe partition at all. `rawptr` is the `void*` analog;
  the sanctioned path is `uintptr` → `rawptr` conversion, unrestricted.

### C itself

C17/C23 §6.3.2.3¶5:

> "An integer may be converted to any pointer type. Except as previously
> specified, the result is implementation-defined, might not be correctly
> aligned, might not point to an entity of the referenced type, and might be a
> **trap representation**."

Implementation-defined, not undefined. And every implementation Avra targets
defines it, because `MAP_FAILED` would not exist otherwise.

---

## 5. Is it actually dangerous?

Split the three, because they are genuinely different questions and the
literature conflates them constantly.

### (a) CREATING a bogus pointer value

**Not dangerous, on any target Avra ships to, in any model surveyed.**

- Rust: "always sound for an integer to pretend to be a pointer 'for fun'".
- Rust's UB list ties UB to *access*; raw pointers as values need only be
  initialized.
- Zig: works, at comptime and runtime, "as long as ptr is never dereferenced"
  (its own langref comment).
- C#: UB is conditioned on "if the result is dereferenced".
- Java: `ofAddress` is unrestricted; `reinterpret` is restricted.
- C: implementation-defined.

The single theoretical hazard is C's **trap representation** clause: on a
machine where loading a bad bit pattern into a *pointer register* itself
faults, merely materializing the value could trap. That clause exists for
machines like Itanium (NaT bits) and segmented architectures. On x86-64 and
AArch64 no pointer bit pattern traps on load. **Theoretical, not practical**,
for our targets. Confidence: HIGH.

### (b) DEREFERENCING it

**This is the entire danger, and Avra does not have the operation.**

Every citation above puts the UB here. Rust: "It is undefined behavior to
access memory through a pointer that does not have provenance over that
memory." Java: `IndexOutOfBoundsException`. Zig: the pointer works until you
load. CHERI: hardware tag fault.

A language with no load, no store, and no pointer arithmetic has removed the
only operation that any of these models calls dangerous.

### (c) PASSING it to foreign code

**Here is the real risk — and it is a CONTRACT risk, not a provenance risk.**

If the C function dereferences what you handed it, you segfault. No amount of
provenance discipline in Avra prevents that, and no provenance discipline is
what protects you today either.

The decisive observation is that **this capability already exists**. Avra can
already hand C:
- a pointer it received from a *previous* C call and held past a `free`;
- a pointer from library A handed to library B that expects a different type;
- a `ptr` from an unrelated `extern fn`, at any seat typed `ptr`.

Every one of those is a pointer C will happily dereference, and every one is
*more* dangerous than `-1`, because a stale real pointer **looks valid** and
often reads without faulting, whereas `-1` faults immediately and loudly on
the first byte. Minting a sentinel does not widen the attack surface; it
occupies a corner of a surface that is already open.

And the specific case: a callee that compares against a documented sentinel
and never loads from it — `sqlite3_bind_text`'s `xDel`, `mmap`'s return —
cannot go wrong at all. The value is a tag. It is compared by identity. It is
never followed.

### Platform and ABI hazards, honestly rated

| Hazard | Bites? |
|---|---|
| **Optimizer / provenance** (`noalias`, `restrict`) | **No.** The optimizations at risk are about *memory accesses through* the pointer. Nothing reads through it. See §6. |
| **CHERI** | **No.** Integer→pointer yields an untagged, NULL-derived capability with the right address. It can be held, stored, passed, and compared; it faults only on dereference. CHERI's actual rule — never round-trip a *real* pointer through a non-`uintptr_t` integer type — is about *losing* provenance a pointer had, which is a different mistake. Confidence: HIGH from the CHERI literature and the SOSP 2023 CHERI tutorial: "cast from provenance-free integer type to pointer type will give pointer that can not be dereferenced". |
| **arm64e pointer authentication — data pointers** | **No.** Clang docs, verbatim: "The current implementation in Clang does not sign pointers to ordinary data by default." Also: null pointers keep "their usual representation" and are not signed. |
| **arm64e PAC — FUNCTION pointers** | **The one real caveat.** "C function pointers are currently signed with the IA key without address diversity and with a constant discriminator of 0." `SQLITE_TRANSIENT` *is* a function pointer. It is safe in practice — SQLite recognizes the sentinel before ever calling `xDel`, and the C side builds its own `((type)-1)` constant, so `==` matches; `libsqlite3-sys` transmutes `-1isize` into a signed-fnptr type and ships on Apple silicon. But the mechanism is "nobody authenticates it", not "it is a valid signed pointer". Confidence: HIGH empirically (it works in the field today), MEDIUM on the exact ABI mechanism. **Write it down: a sentinel in a function-pointer seat is safe only for as long as the callee never calls it.** The day Avra grows real C callbacks, a real callback in that seat must be correctly signed and the sentinel must not be. |
| **Tagged pointers** (Objective-C, JS engines) | **No.** Those are conventions *inside* a runtime that owns its own pointers. A sentinel handed to a C API that documents it is not participating. |

---

## 6. Provenance, specifically

The strongest argument against minting pointers is that a pointer carries
provenance beyond its address, and an integer-derived one has none. Does that
matter for a value that is only compared?

**No, and every provenance model says so explicitly.**

### Rust / strict provenance

The stdlib documentation states the answer for our exact case, twice, without
being asked:

> "Create a pointer without provenance from just an address. Such a pointer
> cannot be used for memory accesses (except for zero-sized accesses). **This
> can still be useful for sentinel values like `null` or to represent a tagged
> pointer that will never be dereferenceable.**"

> "In general, it is always sound for an integer to pretend to be a pointer
> 'for fun' as long as you don't use operations on it which require it to be
> valid (non-zero-sized offset, read, write, etc)."

Crucially, `without_provenance` is **not** the problematic operation. The
problematic operation is the `as` cast, and the reason is *exposure*: an `as`
cast may pick up a previously exposed provenance, which is what makes it
un-analyzable. From the module docs on `with_exposed_provenance`:

> "unlike in `with_addr` there is no indication of what the correct provenance
> for the returned pointer is – and that is exactly what makes
> integer-to-pointer casts so tricky to rigorously specify! … Only one thing
> is clear: if there is *no* previously 'exposed' provenance that justifies the
> way the returned pointer will be used, the program has undefined behavior."

Read the last sentence carefully — the UB is conditioned on **"the way the
returned pointer will be used."** A pointer that is never used to access
memory triggers nothing.

A provenance-free pointer is the *good* case. It declares no permission, so it
constrains no optimization. It is the value that a strict-provenance checker
like Miri is happiest with, and the value CHERI represents natively as an
untagged capability.

### C's PNVI models (N2577, the provenance TS)

Under PNVI-\* (provenance-not-via-integers), integers have **no** provenance at
all; provenance is recovered at the int→ptr cast by asking which live
allocation contains the address (PNVI-ae adds "and was it exposed", PNVI-ae-udi
adds one-past-the-end round-tripping). An address that lies in no live
allocation — `-1`, `-2`, `0xdeadbeef` — yields a pointer with **empty
provenance**: a legal value, non-dereferenceable.

On comparison, N2577's stated design goal is that "the numeric results of all
operations on integers should be unaffected by the provenances of their
arguments," and it notes that for PNVI-\* "this question is moot, as there
integer values have no provenance." Pointer equality in these models compares
**addresses** (with a documented wrinkle about one-past-the-end pointers that
is irrelevant to sentinels). Confidence: MEDIUM-HIGH — the models are drafts,
and the one-past-the-end case has genuinely contested semantics, but nothing
in that contest touches a value that names no object.

### CHERI, the hardest test

CHERI is the architecture that makes provenance *physical* — a tag bit in
hardware, checked on every dereference. It is the acid test, and it passes:

- An integer cast to a pointer becomes a **NULL-derived, untagged capability**
  with the address set to the integer.
- "only pointers implemented using valid capabilities can be dereferenced" —
  dereferencing an untagged capability is a tag fault.
- The value can be held, stored, passed, and compared. Comparison is on the
  address.

So on the one machine where provenance is enforced by silicon, an
integer-derived sentinel is a first-class representable value that faults only
if someone follows it. That is the design Avra wants, implemented in hardware.

**Summary of §6:** provenance governs *access*. A value that is compared and
never followed has nothing to be provenant of.

---

## 7. Recommendation

For a language whose pointers are opaque and non-dereferenceable, that needs C
sentinels, and that wants the dangerous thing to be hard to write by accident:

### 7.1 A named constructor, never a cast operator — HIGH confidence

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

### 7.2 It answers `ptr?`, and 0 answers `null` — HIGH confidence

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

### 7.3 The sentinel gets a home at the binding, not a language restriction — HIGH confidence

```
// the C macro is ((sqlite3_destructor_type)-1)
fn sqlite_transient() -> ptr? { ptr_at(-1) }
```

One unwrap, written once, beside the `extern` block that names the foreign
contract. That is P9 (boundaries are contracts) and it makes the tree's entire
sentinel inventory one grep. It is also precisely what Rust does
(`libsqlite3-sys`'s `SQLITE_TRANSIENT()` is a named fn wrapping the transmute)
and what .NET does (`SafeHandleZeroOrMinusOneIsInvalid`).

### 7.4 Do NOT restrict to compile-time constants — MEDIUM-HIGH confidence

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

### 7.5 Do NOT introduce a second, distinguishable pointer type — HIGH confidence

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

### 7.6 Ship one direction only — HIGH confidence

Add `int → ptr`. Do **not** add `ptr → int` in the same slice.

The reverse direction is the genuinely dangerous one, and it is dangerous in
all three literatures at once: it is Rust's `expose_provenance` (the operation
Rust documents as being on "much less solid footing", that "will not work
(well) with tools like Miri and CHERI"); it is the direction Go forbids for GC
reasons; and it is the operation CHERI actually breaks, because casting a real
capability to a non-`uintptr_t` integer **destroys the tag**. Sentinels need
none of it. Leave it out until something forces it, and when something does,
research it separately.

### 7.7 Teach the compiler to say it — MEDIUM confidence, cheap

Today the refusal is bare:

```
error[F2024]: `q` declares `ptr`, this is `int`
```

The compiler knows the answer (P10, P7). Give F2024 a help line naming
`ptr_at` when the declared type is `ptr` and the value is an int, and a
matching one when it is `null`. That is the "escape hatches everywhere" (P8)
half of the design, and it turns a wall into a signpost for the LLM-first
first-generation metric (P1).

### 7.8 One thing to write down now

The arm64e function-pointer caveat from §5. `SQLITE_TRANSIENT` is a function
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
