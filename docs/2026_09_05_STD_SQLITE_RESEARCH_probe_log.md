# @std/sqlite — THE PROBE LOG: what the compiler actually does, measured

> Every line below was run against `build/avra` in this worktree
> (branch `lane/sqlite`) on 2026-09-05. Nothing here is inferred. Where a
> refusal is quoted it is the compiler's own text, copied. PROBE, DON'T
> REASON — and a design whose code contradicts this file is a design
> defect, not a language ask.
>
> **THE BASE MOVED UNDER THIS FILE, AND EVERY ENTRY IS DATED TO THE
> COMPILER THAT ANSWERED IT.** These probes were run against a
> `build/avra` compiled from **`d96a328`**. The worktree has since been
> advanced to **`cabce5f`** by the campaign's other session, so the
> SOURCE here is newer than the BINARY that produced these answers, and a
> probe re-run today may answer differently for a reason that is not a
> language change but a base change.
>
> **One entry has already moved that way**, and it is recorded rather
> than silently corrected — see §II's `once fn` note. The lesson is
> cheap and general: *a probe log in a shared worktree is a historical
> document unless its base is named*. Re-bootstrap before re-probing, or
> quote the base with the answer.
>
> Read this before writing any Avra in a design document.

---

## Part I — WHAT ALREADY WORKS

### 1. Avra calls SQLite today. No shim, no compiler change.

A scratch package whose whole manifest link section is one row:

```toml
[link]
flags = ["-lsqlite3"]
```

and whose entry file is:

```avra
extern fn sqlite3_libversion_number() -> int
extern fn println(s: string)

let v = sqlite3_libversion_number()
println("sqlite ${v}")
"${v > 3000000}"
```

`./avra build <pkg>` succeeds (peak 3 MB) and the binary prints:

```
sqlite 3051000
true
```

**What this establishes.** The `[link]` path serves a package that is
NOT the compiler — previously shown only for `@std/avrac`'s LLVM wall.
The extern declaration, the symbol's route to the linker, and the call
itself all work with no language change. THE ENTIRE CAMPAIGN IS
LANGUAGE GAPS AND NOTHING ELSE.

### 1b. The VENDORED amalgamation works end to end — our source, our flags, no system dependency.

`packages/std-sqlite/vendor/sqlite3.c` (3.53.4, 269,649 lines, 9.5 MB)
compiled with the recommended flag set: **2.1 MB object, 13s CPU, peak
526 MB**, no warnings. Then linked by the manifest alone:

```toml
[link]
objects = ["../../../build/sqlite3.o"]     # and NO -lsqlite3
```

```avra
extern fn sqlite3_libversion() -> string
extern fn sqlite3_libversion_number() -> int
extern fn sqlite3_threadsafe() -> int
```

Prints `vendored 3.53.4 number=3053004 threadsafe=1`.

**What this establishes.** Three things at once: the `[link] objects`
path works for a package that is not the compiler; our compile flags
reach the binary (`threadsafe=1` is `-DSQLITE_THREADSAFE=1` observed from
Avra, not assumed); and the VERSION DRIFT is real and measured — this
machine's system library is **3.51.0** while upstream is **3.53.4**, so a
driver bound to the host's sqlite would have test results that differ by
machine and by OS release. The decision to vendor is now evidence-backed
rather than a preference.

### 1c. THE GAP THIS OPENED: a manifest says what to LINK, never how to BUILD it.

`[link] objects = […]` names an object file that must ALREADY EXIST.
Nothing in `avra.toml` says how it comes to exist. Today the root
`Makefile` builds `llvm_wrapper.o` for `@std/avrac`, so a package's
private native detail lives in the tree's root build file — tolerable for
the compiler's own wrapper, wrong for a std package that anyone may
depend on.

`@std/sqlite` cannot ship this way: a consumer who adds the dependency
gets a manifest pointing at an object no step in their build produces.
THE ASK: a package declares its own native build (source, flags, output),
and the compiler runs it before linking — the same argv discipline the
`[link]` rows already have (`avra_spawn_status(prog, args)`, no shell
line, no character meaning anything but itself). Recorded here as a
LANGUAGE/TOOLCHAIN ASK with its wanting site, per CLAUDE.md's dogfooding
rule; it blocks shipping, not building, so it is not on the critical path
to the first row.

### 2. A C NULL reads as Avra `null`.

Probed against libc directly, because the answer decides whether a
failed handle is detectable at all:

```avra
extern fn getenv(name: string) -> ptr

let unset: ptr? = getenv("AVRA_DEFINITELY_UNSET_XYZ_123")
let present: ptr? = getenv("PATH")
"${unset == null} ${present == null}"     // true false
```

**What this establishes.** The widen from `ptr` to `ptr?` PRESERVES the
null pointer — a nullable pointer's representation is the null pointer
itself. So a failed `sqlite3_open` (which leaves the handle NULL) and an
empty `sqlite3_prepare_v2` (which leaves the statement NULL) are both
detectable with today's language. One whole piece of the handle story is
already built.

**And it is SPECIFIED, not accidental.** `features/values.av:229-231`
picks a nullable's layout by what it carries: a flat record is `Boxed`, a
pointer-shaped value is `Repr.Niche`, everything else is a `Pair`
(a `{present, value}` register pair). Its own words: *a pointer-shaped
value IS its own nullable (the null pointer is absence)*. So `ptr?` costs
exactly what `ptr` costs — no allocation, no flag register — and it is
the right shape for every handle SQLite hands back. (Established with
lane B.)

### 2a. THE COROLLARY THAT SHAPES THE COLUMN API: a niche spends the null pointer and cannot get it back.

Because absence IS the null pointer, NULL at the boundary can only ever
mean absence. Any C function that returns NULL to mean something else
loses that meaning silently, with nowhere for it to go. SQLite has such a
function, and it is the one the driver reads every row through.

Verified against the SDK header (`sqlite3.h:5411` and `:5519-5525`,
sqlite 3.51.0) — `sqlite3_column_blob` returns NULL for **three**
distinct conditions:

1. the column holds SQL NULL;
2. **the column holds a ZERO-LENGTH BLOB** — quoted: *"The return value
   from sqlite3_column_blob() for a zero-length BLOB is a NULL pointer."*;
3. **an out-of-memory error** — quoted: *"If an out-of-memory error
   occurs, then the return value from these routines is the same as if
   the column had contained an SQL NULL value. Valid SQL NULL returns can
   be distinguished from out-of-memory errors by invoking
   [sqlite3_errcode()] immediately after the suspect return value is
   obtained and before any other SQLite interface is called on the same
   [database connection]."*

**THE LAWS THIS FORCES ON EVERY DESIGN.** A column read NEVER tests the
pointer to decide what it found. It asks `sqlite3_column_type` FIRST and
branches on the storage class; the pointer is read only after the class
says a value is there. And an OOM check, where the driver makes one, is
`sqlite3_errcode` IMMEDIATELY — before any other call on that connection,
which means it cannot be deferred to a wrapper, a lambda, or a later
line. A design in which `column_blob(…) ?? <empty>` reads naturally is a
design that silently maps an out-of-memory to an empty blob.

### 2b. THE `defer` COLLISION: "immediately" is not a strong enough word

SQLite says the errcode check must come *before any other SQLite
interface is called on the same connection*. Avra's `defer` can violate
that on a line the reader is not looking at.

THE MECHANISM (lane B, who built `defer`): a `defer` runs when its
statement list's frame closes — but an EARLY EXIT runs every open frame's
deferred calls FIRST, innermost frame first, ahead of the exit
instruction (`leaving()` for `return`, `failing()` for the failure
channel). **`?` is an early exit. So is `fail`. So is a selective `catch`
that propagates what it did not match.**

So between a suspect NULL and its `sqlite3_errcode` there may be no `?`,
no `return`, and no `fail` — each of them runs every open frame's
deferred calls on the way out, and if one of those touches the same
connection, the errcode is already gone. The offending call is not on the
line and not in the function's visible flow: it is a
`defer stmt.reset()` registered twenty lines earlier, firing on a control
path nobody is reading. The test passes whenever the allocation
succeeded, which is nearly always.

**THE LAW, in its strong form:** THE SUSPECT READ AND ITS ERRCODE CHECK
SHARE A FRAME, AND NOTHING BETWEEN THEM MAY LEAVE. Where the check cannot
be adjacent, the read must not be deferred-guarded at all — hoist the
cleanup out of that frame, or take the errcode into a local at the read
site and branch on the local later.

**THE TEST THAT CATCHES IT** (deterministic, no out-of-memory required):
a frame holding a `defer` that touches the connection, a NULL read, and a
`?` between the read and the check — then assert the errcode is still the
expected one. It fails the moment the `defer` is in place.

This rules out one shape further than §2a did: not only
`column_blob(…) ?? <empty>`, but any design where the `?` sits on a
different line from the read and looks unrelated to it.

**AND NOTE THE SHAPE OF IT.** This is the third place where the EMPTY
case is where a representation quietly loses information: `write_text`
truncating on `strlen`, `str_len` distrusting a zero header length, and
now NULL meaning three things at once. Empty is not a boring edge in this
tree; it is where the encodings collide.

**BUT THE LANGUAGE ITSELF IS INNOCENT — MEASURED.** Empty and absent stay
distinct inside Avra, four representations, both engines:

```avra
type Nothing = { }
let an_empty_list: List<int> = []
let list_empty: List<int>? = an_empty_list      // present
let text_empty:  string?    = ""                // present
let rec_empty:   Nothing?   = Nothing { }       // present
let zero:        int?       = 0                 // present
// -> any_empty_reads_null=false all_absent_read_null=true, eval == native
```

An empty aggregate is a real box with a NON-NULL pointer, so the niche
never confuses it with absence. **THE NULL IS SPENT TWICE ONLY AT THE C
BOUNDARY**, where a foreign function answers NULL to mean "empty". That
makes the hazard sharper, not weaker, and it narrows the first `Bytes`
test precisely: the question is NOT whether the box can represent an
empty blob — it can — but whether EVERY RUNTIME ROW THAT ANSWERS ONE
returns an empty box rather than NULL.

**THE ACTIONABLE RULE (lane D's):** a row answers an EMPTY BOX for empty,
and NULL only for ABSENT. That is the law the Bytes rows are written to,
and the first test written against them. (Lane D measured it, lane B
reproduced it and withdrew a more pessimistic reading, and it is
re-run here.)

An aside worth its own line, found while probing this: an empty literal
does NOT infer into a nullable seat — `let xs: List<int>? = []` is
`F2024: 'xs' declares 'List<int>?', this is '[]'`. A typed let first, then
the widen. Sugar-backlog shaped.

### 3. A `ptr` rides in a struct field.

```avra
type Handle = { raw: ptr }              // accepted
```

A handle type needs nothing new to hold its pointer.

### 4. A `List<T>` crosses an extern seat.

`avra_proc_run(file: string, argv: List<string>, …)` is a live extern in
`corpus/native/externs.av`. An argument vector needs no marshalling
vocabulary.

### 5. A lambda in an argument seat works.

```avra
fn tx(body: fn() -> int) -> int { body() }
let r = tx(() -> 42)                    // accepted
```

So `db.tx(() -> { … })` is expressible TODAY. This is the shape every
scoped-resource design depends on.

### 6. A foreign `const char*` crosses as `string` — and this is a TRAP, not a feature.

```avra
extern fn sqlite3_libversion() -> string
extern fn sqlite3_sourceid() -> string
```

Answers `3.51.0` with `.length` 6, `sourceid` with `.length` 84; `==` and
`starts_with("3.")` both true. It works because `hdr`
(`runtime/avra_runtime.c:68`) refuses a pointer without the AVRA tag, so
`avra_rc_retain`/`release` no-op on it, and `str_len` falls back to
`strlen`.

**THE BELT HOLDS ONLY FOR TEXT THAT IS IMMORTAL AND NUL-TERMINATED.** It
hides three wrongs, and a database driver is made of all three:

| wrong | when it bites | why nothing catches it |
|---|---|---|
| TEXT WITH A LIFETIME — `sqlite3_column_text` | at the next `step`/`reset`/`finalize`; Avra goes on holding the pointer | no header, so no refcount, so no event |
| BYTES — a blob | immediately; a blob's length is not `strlen` | `.length` silently answers the prefix |
| TEXT HOLDING A NUL — which SQLite permits | immediately, while the buffer is perfectly alive | same fallback, quietly short string |

**AND THE INSTRUMENT IS BLIND HERE.** `AVRA_RC_GUARD=1` reports clean on
the probe above. It watches retain and release EVENTS; an untagged
pointer raises none. So the guard cannot distinguish a correct borrow
from a use-after-free and prints clean for both, forever. Everywhere else
in this tree the guard is the instrument of record; at this seam it is
silent by construction. (Established with lane B.)

**CONSEQUENCE FOR EVERY DESIGN:** the extern wall answers `ptr` for
everything SQLite returns as text, and copies at the boundary. Declaring
`-> string` on a foreign function is a defect even when it appears to
work.

**THE TREE IS CLEAN TODAY** (lane B's audit): seven externs answer
`string` tree-wide and every one is backed by a real headered box
(`str_owned`/`str_static`, and `str_static` COPIES —
`runtime/avra_runtime.c:302`); `llvm_api.av`'s wall answers `ptr` and the
wrapper copies. So the spec's `@returns_borrowed` (15.4) is not a fix for
a mess — it locks a door the whole tree already steps around, with zero
violations to migrate.

---

### 7. A `mut` BINDING COPIED FROM ANOTHER `mut` BINDING **ALIASES** — open, and a floor the driver must not stand on

```avra
type Id = { index: int, tag: int }

fn bump(mut i: Id, by: int) -> int {
    i.index = i.index + by
    i.index
}

mut held = Id { index: 1, tag: 0 }
bump(held, 4)                       // held.index -> 5
mut copy = held
bump(copy, 100)                     // copy.index -> 105
"held=${held.index} copy=${copy.index}"
```

```
held=105 copy=105
```

**`mut copy = held` does not copy — it aliases**, so a write through
`copy` lands in `held` as well. Measured here on both engines, with a
TWO-field record, so it is neither the flattening bug (fixed at
`349c74d`) nor a consequence of its fix. This is the RECEIVER-ALIASING
hole the ROADMAP already names; it is **open**, and it belongs to a
later slice. (Found by lane C while fixing the flattening defect, and
flagged so this campaign does not build on a floor it believes solid.
Re-run here.)

**WHAT IT FORBIDS IN THE DRIVER'S DESIGN**, stated now rather than
discovered later:

- **No `mut` builder that a caller could copy.** A `Query`/`Statement`
  builder whose methods mutate — `mut q2 = q1` then `q2.bind(…)` — would
  write into `q1`. The merged design's chained, VALUE-RETURNING form
  (`sql("…").args([…])`) is immune, and this is now its *reason* rather
  than a stylistic preference.
- **A `Cursor` may be `mut` but must never be copied into a second
  binding.** `mut w2 = w` would give two names for one statement; that
  happens to be *true* of a cursor, but true by accident is not a design
  — and it stops being harmless the moment `Cursor` carries anything of
  its own (it carries `cols`).
- **`Row` stays immutable**, which the design already requires for
  staleness reasons; this is a second, independent reason for the same
  rule.

## Part II — WHAT IS REFUSED (the campaign's language checklist)

Each refusal is quoted from the compiler.

| probe | refusal |
|---|---|
| `let x: float = 1.0` | `F0100: expected BREAK while parsing 'stmt'` — pointing AT the `.`. The lexer has no float literal; the gap starts before the type surface. |
| `let x: f64 = 1` | `F2001: 'f64' names no type` — help: **"the types today are `int`, `string`, `bool`, and your declared types"** |
| `let b: Bytes = "hi"` | `F2001: 'Bytes' names no type` |
| `opaque type Db` | `F0100: expected BREAK while parsing 'stmt'` |
| `extern fn f(p: string) -> ptr @free_with(g)` | `F0100` AT the `@` — no annotation vocabulary at all |
| `extern fn f(p: string, out db: ptr) -> int` | `F0100: expected ')'` — no out-params |
| `h.raw == h.raw` where `raw: ptr` | `F2000: '==' compares scalars for now` — help: "compare scalars or strings". A BARE `ptr` has no null test; `ptr?` is the only one. |
| `impl Show for Box<T>` | `F2031: 'Box' is generic — a trait impl over a generic type is recorded, not landed` |
| `tx { 42 }` (trailing lambda) | `F0100: expected BREAK while parsing 'stmt'` — the spelling is `tx(() -> 42)` |
| `avra run` on any extern | `'<name>' is extern — the evaluator cannot host it; build natively`, exit 1 |

### The two refusals that most constrain a design

**F2031 — no trait impl over a generic type.** A generic decoding trait
(`impl Decode for Column<T>`, `impl Row for Table<T>`) does not land. A
type-driven design must express row mapping WITHOUT it: inherent generic
impls (`impl Box<T>`) DO land, and a non-generic type may impl a trait
freely. Design around it or make it an explicit LANGUAGE ASK — do not
write code that F2031 refuses.

**No trailing-lambda sugar.** Every scoped-resource shape is spelled
`db.tx(() -> { … })`, never `db.tx { … }`. This is a legitimate sugar
backlog ask with an obvious wanting site, and it should be filed as one.

### THE OUT-PARAM IS A `mut` SEAT, AND THE LANGUAGE ALREADY HAS ONE

The campaign's first blocker is far smaller than "add out-params to
Avra". THREE SPELLINGS, kept apart because they are three different
things and conflating them mis-sizes the work:

| # | spelling | status |
|---|---|---|
| 1 | `fn g(mut p: int) -> int` — a `mut` seat in a fn DECLARATION | **WORKS TODAY.** It even warns well: `F2051: 'p' is a 'mut' seat — 'g' never writes through it` |
| 2 | `type Row = { check: fn(mut Cx, int) -> int }` — a `mut` seat in a fn TYPE | **CLOSED ON MAIN** at `656e650` ("feat(types): `mut` in a fn type — the seat law's missing half"). Still `F0100: expected '}'` at THIS lane's base `d96a328`; picked up at the next rebase. A fn type now carries its seats' contract: a writing fn is refused by a seat that promised not to write, a call through the seat needs a `mut` place, and — the sound asymmetry — a NON-writing fn still fits a `mut` seat, so a row's fn never needs marking just to satisfy a signature. **The driver's row tables are designed against this, not around it.** |
| 3 | `extern fn f(mut p: ptr) -> int` — a `mut` seat in an EXTERN | REFUSED, `F0100: expected ')'`. **NEW — this file's finding.** |

**AND THE CAUSE IS VISIBLE IN ONE LINE.** `features/fns/mod.av` carries
both rules next to each other:

```
:32   stmt = "extern" "fn" n:NAME "(" ( ps:NAME ":" pt:type … )? ")" …
:33   stmt = "fn" n:NAME …             "(" ( ( mk:"mut" )? ps:NAME ( ":" pt:type )? … )? ")" …
```

The extern rule is a NARROWER COPY of the fn rule: it simply lacks
`( mk:"mut" )?`. So the syntactic half of out-params is aligning two
grammar rules that were meant to agree, not inventing a feature. The
semantic half — what `mut` MEANS across the C boundary, which is *pass
the address of the caller's slot* — is the real work, and it is now
scoped to exactly that question.

**A RETRACTION, KEPT VISIBLE BECAUSE THE ARGUMENT WAS LOAD-BEARING.**
This file briefly claimed that `features/fns/mod.av:34` (`once fn`) was a
SECOND narrower copy, and that two of three sibling rules had DRIFTED —
so the fix was to align a family. **That is wrong.** `once fn` takes no
parameters at all, by a law that already speaks:

```
once fn seed(n: int) -> int { n }
  F2055: `once fn seed` takes arguments — a `once` answer is one value
         for the whole process
  help:  drop the parameters, or drop `once`
```

Its rule accepts a parameter list ONLY so that law can reach the mistake
— parse permissively, refuse with a voice, which is the right design.
Whether that rule offers `( mk:"mut" )?` is semantically moot. The
drifting-family story was inferred from the SHAPE of three grammar lines
without measuring what any of them MEANS.

**THE CORRECTED PICTURE — two things, not one family of three:**

1. **`extern fn` cannot take a `mut` seat** — a REAL capability gap, and
   the one the driver needs. Whether a C row may take one is an ABI
   question, so it belongs to whoever owns the boundary's semantics.
2. **`once fn f(mut x: int)` is a DIAGNOSTIC defect, not a capability
   gap** — the same mistake gets `F2055` *with a reason* when written
   `(x: int)`, and a bare `F0100: expected ')'` when written
   `(mut x: int)`. The law exists; the parse error hides it. Adding
   `( mk:"mut" )?` there costs nothing semantically and makes the
   existing law reachable.

(Retraction measured by lane D, confirmed by lane B, re-run here.)

**AND AN UNRELATED `once` FACT WORTH HAVING**, since the driver will want
a process-wide value: a `once fn` answers only a MANAGED value.
`once fn seed() -> string` is accepted; `once fn seed() -> int { 7 }` is
`F2055: 'once fn seed' answers 'int', which the runtime cannot keep`.

**AND IT IS ONE GAP WITH THREE CUSTOMERS**, which is a different
conversation from a gap this driver wants: the compiler's own walks want
#2, the soundness hole wants #2, and `sqlite3_open`'s `sqlite3**` wants
#3. Propose them together. (Framing from lane B.)

### The out-param blocker, and why no workaround is permitted

`sqlite3_open_v2` and `sqlite3_prepare_v2` — the two calls every program
makes — both answer their handle through a `T**`. SQLite offers no
variant that returns the handle directly. There is no way to express this
today, and the tempting hack — passing a one-element `List<int>` as the
out-param seat — does not merely offend the doctrine, it does not work:
an extern taking `List<int>` receives the `AvraArray` pointer, whose
FIRST FIELD IS THE CAPACITY, not the data, so what C writes through it is
not what Avra reads back. Making it work needs a C body that knows the
array's layout — which is precisely the shim the campaign forbids. The
no-shim rule and the out-param gap are the same constraint seen twice,
and landing `mut` seats on externs buys back both at once. (Lane B hit
the adjacent version of this building the process substrate.)

**THE PARADOX WORTH COLLAPSING (P6):** a C function that answers a status
code AND writes a handle to an out-param IS a `Result` — the status is
the error channel, the out-param is the value. The spec (15.4) stops at
annotating the parameter and then writes `sqlite3_open_wrapped` in its own
example, conceding a hand-written wrapper. Going one step further — the
compiler projecting `(status, out T)` directly to `Result<T, E>` at the
declaration — deletes the wrapper layer for every C library, not just
this one. Any design that hand-writes an open-wrapper should say why the
collapse does not apply.

---

## Confidence ledger

| claim | how verified | confidence |
|---|---|---|
| `[link]` works for a non-compiler package | built and ran; printed `3051000` | HIGH |
| C NULL reads as Avra `null` through `ptr?` | built and ran against libc `getenv`; `true false` | HIGH |
| foreign `const char*` crosses as `string` | built and ran; `.length` and `==` both behave | HIGH |
| `AVRA_RC_GUARD` cannot see this class | mechanism read in `avra_runtime.c` (`hdr` tag check gates `rc_note`); guard run clean on a known-borrowed pointer | HIGH |
| `sqlite3_column_text`'s buffer dies at the next step | SQLite documentation, NOT probed here — no database is opened yet | MEDIUM, pending the driver's first row |
| every refusal in Part II | `./avra check` on a scratch file, text copied | HIGH |
| seven externs answer `string`, all headered | lane B's audit, RE-RUN here: the seven names greped out of `packages/*/src` and `corpus/native`, each body read in `avra_runtime.c` — `avra_selfhost_get_arg_cstr` and `avra_host_env` and `avra_errno_text` through `str_static`, `avra_io_taken`/`avra_proc_take`/`avra_proc_which`/`avra_str_from_codepoint` through `str_owned`. No eighth. | HIGH |
| an empty string answers length 0 eight ways | run under both engines in this worktree: literal, `"" + ""`, `substring(1,1)`, `substring(3,3)`, `trim` of blanks, replace-to-empty, `join` of empties, concat of two empty substrings — `0,0,0,0,0,0,0,0`, eval == native. The premise the `str_len` change rests on. | HIGH |
| `defer` + `?` can eat the errcode | mechanism from lane B, who built `defer`; NOT yet reproduced here (needs an open connection, which needs out-params) | MEDIUM — the test is specified above and runs the day the driver opens a database |
| no `List<int>` hack for out-params | reasoned from `AvraArray`'s layout in the runtime, NOT probed — nobody should probe it | LOW as a measurement, HIGH as a prohibition |
