# THE EXTERN HOST — the shape, for lane C

> **Status:** a design, not a patch. Lane C asked for it and will land
> it; `language/interp.av` is theirs and this lane has written no line
> in it. Grounded in the campaign's ABI analysis (in git history) and
> re-verified against the tree where it matters.
>
> **What it closes:** today `avra run` traps on ANY extern —
> "`X` is extern — the evaluator cannot host it; build natively",
> exit 1. So every FFI binding is native-only, `eval == native` is
> unprovable for exactly the code that most needs proving, and an
> LLM-first language hands a user a dead end on the verb they point at
> code they have not read.

---

## 0. THE SPINE, IN THREE SENTENCES

The interpreter resolves a symbol with `dlsym` and calls it through **one
fully-applied C prototype**, because the integer and floating-point
register files are independent and a callee cannot observe arguments it
does not declare. Only the RETURN needs distinct handling, and the
return vocabulary is **the width vocabulary already landing for B3** —
not a second table. Everything the uniform frame cannot express is
classified AT THE DECLARATION and refused BY NAME with its reason.

**No libffi** (the spec rejects it, Axis 15.3), no codegen, no
per-extern hand-written arm.

## 1. THE COLLAPSE THAT MAKES IT TRACTABLE

The naive table is combinatorial: with each of N arguments either
integer-class or FP, shapes number 2^N per arity per return kind —
roughly 2000 for N ≤ 8. **It does not need to be.**

Two facts do the work. **(i)** The register files are independent and
each is filled in class order, so the mapping from "the k-th
integer-class value" to a machine location is fixed regardless of how
the arguments interleave. **(ii)** A callee reads only the argument
registers its own prototype declares and ignores the rest.

Therefore ONE prototype, ALWAYS FULLY APPLIED, serves every non-variadic
scalar callee whose integer-class arity is ≤ MAX_I and FP arity ≤ MAX_F:

```c
#define AVRA_FFI_MAX_I 10   /* SQLite's own maximum, named not guessed:
                               sqlite3_create_window_function */
#define AVRA_FFI_MAX_F 8    /* the FP file's depth on both targets */
```

Integer parameters first, then doubles. On arm64 that fills `x0`–`x7`,
spills `i8,i9` to `[sp+0]`,`[sp+8]`, and fills `d0`–`d7`. On x86-64 it
fills `rdi..r9`, spills `i6..i9`, and fills `xmm0`–`xmm7`. In both cases
**the k-th stacked integer of the SHAPE lands exactly where the k-th
stacked integer of any all-integer callee lands**, because the doubles
never reach the stack.

**Measured against the real surface** (`sqlite3.h`, 284 entry points):
maximum integer-class arity 10; functions touching `double` — **four**,
each needing at most one FP argument; structs by value — **none**; f32
anywhere — **none**.

## 2. THE SHAPE TABLE, AGAINST `RtKind` — AS LANE C ASKED

`RtKind` is `{ I64, Ptr, Void, I32, U32, F64 }` (`core/ir.av:331`) —
three variants when this was written, six now: `I32`/`U32` from the
width slice and `F64` from float. Re-probe every citation below against
your own base. The width
work landing this hour adds seat widths. **The host's argument
coercions are exactly `RtKind`'s three, and its return coercions are
exactly the width vocabulary.** This is the design's one real economy and
it should be stated plainly:

| direction | `RtKind` | what the host does |
|---|---|---|
| argument | `I64` | pass the Avra `int` in the next integer slot, **narrowed by the seat's declared width, with the sign that width names** |
| argument | `Ptr` | pass the box pointer (or 0 for `null`) in the next integer slot |
| argument | *(a future `F64`)* | pass in the next FP slot — **arrives with `float`, not before** |
| return | `Void` | discard |
| return | `Ptr` | the raw pointer; **never adopted as a `string`** (§5) |
| return | `I64` | read the return register **through the seat's declared width, sign- or zero-extended as that width names** |

**THE POINT: the extern host does not invent a return vocabulary.** B3's
width work narrows and widens at the NATIVE call site; the host does the
same at the INTERPRETED call site, from the same declaration. One
declaration, two consumers — which is also what makes `eval == native`
true by construction rather than by agreement between two hand-written
tables.

**And it inherits B3's correctness for free.** A C `int` of -1 read
through a `-> i32` seat is -1 in both engines. Read through an untyped
`-> int` seat it is 4294967295 in both. The host cannot be more correct
than the declaration, and it must not be *differently* correct.

## 3. WHAT CANNOT BE UNIFORM — AND WHERE IT REFUSES

Lane C asked what happens on the paths that cannot be uniform, and said
the honest answer is a refusal with a good voice rather than a silent
wrong call. Agreed. **The subtlety is that the right refusal is not at
the declaration**, and getting that wrong would break the native path.

| shape | why the uniform frame cannot host it |
|---|---|
| **variadic callee** | Apple's arm64 ABI reads variadic arguments **from the stack**, not the register block |
| > 10 integer-class arguments | past the block |
| > 8 FP arguments | past the FP file |
| a struct/union/array **by value** | classifies by field; may split registers or ride memory |
| a struct **returned** by value | may ride the indirect-result pointer (`x8`, or a hidden first argument) |
| `long double`, `__int128`, a vector | their own classes |
| an overflow argument narrower than 8 bytes | Apple packs stack slots to natural size |
| an **f32 parameter** | half of a `v` register; a double there is read wrong |

*(An f32 RETURN can be read correctly by casting the pointer, which is
why a return-side f32 is admissible and an argument-side one is not.)*

> **CORRECTED 2026-09-07. THE PARENTHESIS ABOVE IS FALSE ON THE FRAME
> THAT LANDED, and it is kept because the package-C standard quoted it
> into §5.6.8 as "an f32 RETURN is fine and passes".** Nothing casts a
> pointer: the frame's f64 door is `avra_ffi_call_f64`, which calls
> through a `double`-answering prototype and reads `v0` WHOLE, and
> there is no `f32` width word for the answer to be read back through.
> A C `float` writes only the low half. Measured on a witness body
> answering `1.5f` through a declared `f64`: `5.28426686e-315`, in BOTH
> engines — a green differential over a wrong number. `make externs`
> holds a declared `f64`/`float` to a C `double` now. The claim was
> true of the DESIGN this paper describes and never of the code; the
> citation is what carried it.

### The refusal, placed correctly

> **CORRECTED 2026-09-07. THE PARAGRAPH BELOW WAS FALSE AND IS KEPT SO
> NOBODY RE-DERIVES IT.** It claimed the native path hosts variadics and
> concluded the refusal belongs at INTERPRETATION. Measured on main:
> every caller of `declare(…, variadic)` — `llvm.av` 109, 111, 121, 172,
> 179, 199 — passes **false**, the extern path hard-wires **0**, and the
> grammar has **no ellipsis**. **A variadic C body under a fixed
> declaration emits a fixed call on the native path too**, which this
> paper's own `12345 -> -298729216` measurement demonstrates three
> sections above. The claim and its refutation were on the same page and
> nobody put them together.
>
> **THE REFUSAL BELONGS AT THE DECLARATION, FOR BOTH ENGINES**, in a
> keeper that reads the C (`make externs`), narrowing to the evaluator
> only on the day a variadic seat is spellable. Refusing at
> interpretation would let a variadic declaration compile natively and
> answer a silently wrong value — the class this campaign opened on. A
> declaration-level refusal makes the unsound thing UNSPELLABLE rather
> than merely unhosted. Found by the HTTP lane reading this paper against
> the tree instead of trusting it.

**~~A NATIVE-ONLY SIGNATURE IS NOT AN ERROR.~~** ~~The native path can host
variadics perfectly well — LLVM knows the Darwin rule, and `declare`
already takes the vararg flag (`language/llvm.av:189-195`), hard-wired
`false` at both call sites. Refusing a variadic extern at its
declaration would break a program that only ever builds.~~

~~So: classify once, at the declaration; refuse at the point of
interpretation, by name, with the reason and the fix.~~

```
`sqlite3_db_config` is variadic — the evaluator calls through a uniform
frame, and Apple's arm64 ABI reads a variadic callee's arguments from
the stack. Build natively; a variadic C function cannot be declared
with a fixed argument list.
```

**THE SECOND SENTENCE OF THAT WORDING WAS ONCE "or bind one narrow
extern per argument shape", AND IT WAS MEASURED WRONG.** The
api-surface report proposed exactly that escape route for the variadic
eight — one fixed-arity extern per shape against the same C symbol,
"legal C ABI on every platform Avra targets". Against the real vendored
symbol, in two translation units so the compiler cannot see through it:

```
fixed prototype     sqlite3_test_control(ALWAYS, 12345)  ->  -298729216
variadic prototype  sqlite3_test_control(ALWAYS, 12345)  ->  12345
```

The assembly says why: the fixed prototype emits `mov w1, #12345` — a
REGISTER — and the variadic emits `str x8, [sp]` — the STACK. Apple's
arm64 reads a variadic callee's arguments off the stack, so the callee
reads a slot nobody wrote. `SQLITE_TESTCTRL_ALWAYS` is
`int x = va_arg(ap, int); return x`, so 12345 is the right answer and
`-298729216` is garbage.

**No link error. No trap. A silent wrong answer** — and the function it
would bite is `sqlite3_db_config`, which is how DQS, foreign keys and
defensive mode are set. So the escape route is CLOSED: a variadic symbol
is declared variadic or not at all, and the refusal must not offer the
fixed-arity form as a workaround.

That is strictly better than today's blanket trap in three ways: it fires
for a NAMED SHAPE rather than for the whole category, it says WHY, and it
says what to do instead. **The trap does not disappear — it shrinks from
"every extern" to an enumerated list, and gains a reason.** Promising its
death would be overselling this design.

### Variadics, honestly

The tails SQLite actually wants are integer-only and short —
`sqlite3_db_config(db, op, int, int)`, `sqlite3_config(op, int)`. When
they are needed, a hand-written set of variadic trampolines (`int f(void*,
int, ...)` with one, two and three integer varargs) covers them: **four
more C functions, enumerated at the site, not a table.** Recommended
order: land the non-variadic mechanism first and refuse variadic by name;
add the enumerated shapes when `sqlite3_db_config` is actually needed.
The extern grammar has no `...` today either (`features/fns/mod.av:32`),
so the spelling is missing before the mechanism is.

## 4. SYMBOL RESOLUTION — AND THE CONSTRAINT THAT SHAPES THE WHOLE DESIGN

Lane C asked what `dlsym` is asked of: the process, or a library the
manifest names. **The answer is forced, and it is not the comfortable
one.**

**`avra run` interprets inside `build/avra`'s own process**
(`language/workspace.av:1068-1071`), and a package's `[link]` words
reach clang **only when a native binary is built**
(`cli/src/commands/shared.av:277`). So the compiler's image does not
contain sqlite3, and `dlsym(RTLD_DEFAULT, "sqlite3_open")` **answers
NULL**. *The image tier alone cannot host the driver.*

### Tier 1 — THE IMAGE: `dlsym(RTLD_DEFAULT, name)`

Reaches everything already loaded: the runtime's own C, the LLVM
wrapper, libLLVM, libSystem.

- **It retires the trap for every extern the tree declares TODAY**, which
  moves `corpus/native/externs.av` into the eval-and-native corpus — the
  single best proof the mechanism works, and it needs no new file.
- No loading, no initializers, nothing new on disk.
- **It is not harmless.** libc is in the image, so under tier 1
  `extern fn system(cmd: string) -> i32` runs a shell under `avra run`.
  The honest framing: `avra build` already grants a program all of libc,
  so tier 1 widens no BUILT program's power. It widens what the **"just
  look at it" verb** can do — and `avra run` is precisely the verb a
  person points at code they have not read.

### Tier 2 — A LIBRARY: `dlopen`

**`dlopen` runs the library's initializers before any Avra code runs** —
`.init_array`, `__attribute__((constructor))`, ObjC `+load`. That is
arbitrary native execution named by a file path, with no shell needed. It
is a **strictly worse shape than the supply-chain execution this tree has
already paid for** (a dependency's `[link] flags` spliced into a
`system()` string, fixed structurally with an argv row).

And the premise that finding falsified must not be re-adopted here: *"a
`[link]` row is the project's own word"* is **true of the root package and
false of every dependency.**

### The constraint for `@std/sqlite` specifically, argued in the open

The driver's symbols live in a static object built for the native link.
Under tier 1 they are unreachable, so **`avra run` cannot host the driver
without tier 2 or without the symbols entering the compiler's image.**

The route worth stating — and it is a **constraint, not a
recommendation**: build the vendored amalgamation **as a dylib that is a
COMPILER artifact in `build/`, never a deployment one.** The P14 argument
must be made rather than assumed: the shipped program still links the
static object into one binary with no runtime dependency and no
container; the dylib exists **only so the compiler's own interpreter has
something to resolve against during development**. If that distinction is
not held explicitly — a build artifact of the toolchain versus an artifact
of the product — it decays into "Avra programs need a shared library",
which P14 refuses.

**This is the design's sharpest open question and it is not mine to
settle**: it grants `avra run` the ability to load native code chosen by a
manifest. The capability shape belongs to whoever owns the capability
diet, and lane C has said they will not land a manifest-driven `dlopen`
without the owner's decision. **That is the right line and this document
does not argue past it.**

**Recommendation, therefore, in two steps that can be taken
independently:** land tier 1 alone. It closes the trap for every extern
the tree has today, it proves the mechanism against the existing corpus,
and it needs no capability decision. Tier 2 is a separate slice with a
separate argument, and the driver waits for it.

## 5. THE TWO LAWS THE HOST MUST NOT BREAK

**A returned pointer is never adopted as a `string`.** A foreign
`const char*` crossing as `string` works only for text that is immortal
and NUL-terminated, and it is silently wrong for text with a lifetime,
for bytes, and for text holding a NUL — with `AVRA_RC_GUARD` structurally
blind to all three, because an untagged pointer raises no retain or
release events. The host answers `Ptr`; the copy is a separate, named
step.

**Both engines answer the same or neither answers.** If the host can
call a signature the native path cannot, or the reverse, `eval == native`
becomes a claim about coverage rather than about meaning. The
classification in §3 is therefore computed ONCE, from the declaration,
and both engines consult the same verdict.

## 6. LANDING CHECKLIST

1. **The classification** — a declaration is HOSTABLE or NATIVE-ONLY,
   computed once from its seats. No engine decides it independently.
2. **The C surface** — one uniform prototype, `AVRA_FFI_MAX_I`/`MAX_F`
   named as constants with the reason each number was chosen.
3. **`RtHost` grows one variant** for the dlsym path. The registry stays
   a table; nothing dispatches per extern.
4. **Tier 1 resolution** — `dlsym(RTLD_DEFAULT, name)`, with a NAMED
   refusal when the symbol is absent (which is the driver's case, and
   the message should say so rather than say "not found").
5. **The refusal voices** — one per row of §3's table, each naming the
   shape and the fix.
6. **Tier 2, separately, or not at all yet** — with the capability
   decision made by whoever owns it.

### What proves it

- `corpus/native/externs.av` — which declares eleven externs and today
  can only run natively — **runs under `avra run` and answers
  identically.** That is the whole mechanism, proved against a file that
  already exists and that nobody wrote for this purpose.
- A variadic declaration refuses under `avra run` **by name**, and still
  builds and runs natively.
- A negative C `int` read through a width-annotated seat answers the same
  in both engines — the B3 join, and the reason the two tables must be
  one.

---

## Confidence ledger

| claim | how verified |
|---|---|
| `avra run` interprets inside `build/avra` | `language/workspace.av:1068-1071` |
| `[link]` words reach clang only on a native build | `cli/src/commands/shared.av:277` |
| therefore `dlsym(RTLD_DEFAULT, "sqlite3_open")` is NULL | follows from the two above — **the finding that forces the two-tier design** |
| ~~`RtKind` is `{I64, Ptr, Void}`~~ **STALE** — it is `{I64, Ptr, Void, I32, U32, F64}` at `core/ir.av:331`, and `make vocab` names FIVE exhaustive consumers | re-probed 2026-09-07 |
| `declare` already carries a vararg flag, hard-wired false | `language/llvm.av:189-195`, call sites `:171` and `:187` |
| the extern grammar has no `...` | `features/fns/mod.av:32` |
| Apple arm64 reads variadic arguments from the stack | the ABI research report §1.2; **not independently re-verified here** — MEDIUM, and it is the load-bearing reason variadics refuse |
| SQLite's max integer arity is 10, four functions touch `double`, no structs by value | the API-surface report's classification of all 284 entry points |
| `dlopen` runs initializers before any Avra code | POSIX/dyld semantics; the security argument does not depend on the exact hook list |
