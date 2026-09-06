# PROCESS-WIDE MUTABLE STATE — what every serious language decided, and what Avra should

Research for the language-design decision behind `@std/sqlite`'s handle table.
Recorded 2026-09-06. Sources are primary and quoted; every claim carries its
confidence.

- **[MEASURED]** — probed in this tree today, output quoted.
- **[QUOTED]** — a primary document, quoted verbatim, link in §7.
- **[READ]** — read from a primary source, paraphrased.
- **[JUDGED]** — my inference from the above. Argue with these.

---

## 0. THE ANSWER, UP FRONT

**It is TWO needs, and Avra already has one of them.**

- (b) PROCESS-WIDE STATE is **already landed**: `once fn` is Avra's static
  slot, backed by a real process-wide table in the runtime
  (`g_once[AVRA_ONCE_MAX]`, `runtime/avra_runtime.c:854`). It is write-once.
- (a) SHARED WRITING is the actual gap. The ROADMAP calls it `Cell<T>`; the
  spec reserves it at 11.3.
- The handle table is their **composition**, and needs no new syntax:
  `once fn conns() -> Mut<Table>`.

**And the handle table specifically has a narrower, better answer that should
land first**: `opaque type Db @free_with(sqlite3_close_v2)` — the spec's own
Axis 15.5, which is the WebAssembly Component Model's `resource` type under
another name. It turns the double-close from a runtime refusal into a form
that cannot be written.

**`Cell` is the wrong name**, and it is already pulling the design toward the
wrong semantics. Recommendation: **`Mut<T>`**.

---

## 1. THE GROUND TRUTH IN AVRA TODAY [MEASURED]

Four probes, this tree, `./avra run` on scratch files.

**P1 — the forcing fact confirmed.** A `once fn` answering a list; three
pushes through a `mut` borrow:

```avra
once fn slots() -> List<int> { [] }
fn bump() -> int { mut xs = slots(); xs.push(1); xs.length }
"${bump()} ${bump()} ${bump()} | table now holds ${slots().length}"
```
```
1 1 1 | table now holds 0
```

**P2 — the same through a record field, same answer.**

```avra
type Table = { rows: List<int>, label: string }
once fn t() -> Table { Table { rows: [], label: "reg" } }
fn bump() -> int { mut x = t(); x.rows.push(1); x.rows.length }
"${bump()} ${bump()} | now ${t().rows.length}"
```
```
1 1 | now 0
```

**P3 — the path-write route is REFUSED, by name.**

```avra
fn bump() -> int { t().rows.push(1); t().rows.length }
```
```
error[F2034]: `push` mutates a place, and this list is a value
help: bind it first — `mut xs = …` — then `xs.push(…)`; or build a new list
      with `concat`
```

**P4 — `once` refuses scalars, and the refusal names the mechanism.**

```avra
once fn base() -> int { 7 }
```
```
error[F2055]: `once fn base` answers `int`, which the runtime cannot keep
help: a `once` value is one the runtime owns — a string, a list, a map, an
      enum, or a record wider than one scalar field
```

**What these four together actually say** [JUDGED]. The tree does not *lack* a
process-wide box. It *has* one, and the runtime comment says so exactly
(`runtime/avra_runtime.c:840`):

> A `once fn`'s answer, settled for the process and asked by the fn's own
> SYMBOL — unique in a binary by the linker's own law. The cache keeps ONE
> reference to the key and ONE to the value, forever.

The reason a write never lands is not absence — it is Avra's own doctrine
working correctly. The `once` box is shared (the cache holds a reference, so
rc > 1), and **A BORROW ALIASES, A PATH WRITE THROUGH A SHARED INTERMEDIATE
COPIES**. Every write therefore lands in a copy. P3 shows the compiler
refusing the other route outright.

So the missing piece is not "a global". It is **a box whose writes are
visible through every alias BY DECLARATION** — which is the ROADMAP's own
words for `Cell<T>` (ROADMAP.md:10693). The two halves already exist as
separate designs and nobody has noticed they compose.

**The spec has no decision on (b) at all** [MEASURED]. `grep` over
`2026_04_18_FULL_SPEC.md` for global/process-wide/static state returns two
incidental mentions and no sub-decision:

- 11.3's `@pure` verification list includes "No mutation of external state
  (**globals**, interior-mut cells)" — the spec *assumes* globals exist.
- 8.x's FFI callback refusal says "Use a pure function **or global state**" —
  the spec *recommends* them, in an escape hatch, for a thing it never
  defined.

That silence is the conflation the question asks about, and it is in the
spec, not just in the request.

---

## 2. Q1 — IS THIS ONE NEED OR TWO?

**Two. The literature draws the line precisely, and it draws it where the
question does.** [QUOTED, then JUDGED]

The two axes answer different questions:

| | (a) INTERIOR MUTABILITY | (b) PROCESS-WIDE STATE |
|---|---|---|
| asks | **who may write?** | **how long does it live, and who can reach it?** |
| about | the aliasing discipline | storage duration and reachability |
| C++ word | — | *storage duration* |
| Rust word | *interior mutability* | *static* |

Rust's `std::cell` module docs define (a) with no reference to lifetime at
all [QUOTED]:

> Values of the `Cell<T>`, `RefCell<T>`, and `OnceCell<T>` types may be
> mutated through shared references (i.e. the common `&T` type), whereas most
> Rust types can only be mutated through unique (`&mut T`) references. We say
> these cell types provide **'interior mutability'** (mutable via `&T`), in
> contrast with typical Rust types that exhibit **'inherited mutability'**
> (mutable only via `&mut T`).

Zig's langref defines (b) with no reference to aliasing at all [QUOTED]:

> Namespace level variables have **global lifetime** and are order-independent
> and lazily analyzed. […] If a namespace level variable is `const` then its
> value is `comptime`-known, otherwise it is runtime-known.

**All four quadrants are inhabited in shipping languages**, which is the
proof that neither implies the other:

| | not process-wide | process-wide |
|---|---|---|
| **not shared-writable** | an ordinary local | Rust `static N: u32 = 3` · Erlang `persistent_term` · **Avra's `once fn` today** |
| **shared-writable** | Rust `Cell<T>` in a struct · OCaml `ref` in a closure · **the ROADMAP's `Cell<Decls>` reached via `ws`** | Rust `static R: Mutex<Vec<T>>` · Go package `var` · Swift `static var` · **the sqlite handle table** |

**What each is actually FOR** [JUDGED, from the survey in §3]:

- **(a) is for a value with more than one holder that must agree.** Caches,
  memo tables, interners, lazy initialization, refcount-shared graph state,
  observers. Spec 11.3's own list: "caches, lazy initialization, thread-local
  state, pooled resources." Crucially, (a)'s scope is *whatever its owner's
  scope is* — a `Cell<Decls>` reached through `ws` dies with `ws`. **(a) never
  needs (b).**
- **(b) is for a thing that is singular *in the world* because the PROCESS is
  singular.** The OS's view of you: file descriptors, signal handlers, the
  environment, the CWD. A C library's one-time init (`sqlite3_initialize`).
  The set of resources this process currently owns. Interned symbol tables.
  **The discriminator is not convenience — it is whether the thing being
  mirrored is itself process-scoped.**

That discriminator is the one design rule to carry out of this section: a
cache does not need (b), it needs (a) at its owner's scope. A handle table
*does* need (b), because "the connections this process has open" is a fact
about the process. The `@std/sqlite` ask is honest on this test; most asks
for globals are not.

---

## 3. Q2 — HOW EVERY SERIOUS LANGUAGE HANDLES (b)

### 3.1 Rust — removed the raw form, kept the capability, typed the discipline

`static mut` requires `unsafe`, and in edition 2024 references to it are
`deny` by default. The Edition Guide's rationale [QUOTED]:

> Merely taking such a reference in violation of Rust's mutability XOR
> aliasing requirement has always been *instantaneous* undefined behavior,
> **even if the reference is never read from or written to**. Furthermore,
> upholding mutability XOR aliasing for a `static mut` requires *reasoning
> about your code globally*, which can be particularly difficult in the face
> of reentrancy and/or multithreading.

And on migration [QUOTED]:

> There is no automatic migration to fix these references to `static mut`. To
> avoid undefined behavior you must rewrite your code to use a different
> approach.

RFC 3560's motivation [QUOTED]:

> The existing `static mut` feature is difficult to use correctly (it's
> trivial to obtain aliasing exclusive references or encounter UB due to
> unsynchronised accesses to variables declared with `static mut`) […] is
> becoming redundant due to the expansion of the interior mutability
> ecosystem which easily replaces `static mut`'s functionality.

The Edition Guide names exactly four replacements: **atomics**,
**`Mutex`/`RwLock`**, **`OnceLock`/`LazyLock`**, and **raw pointers**
(`&raw mut`, with the aliasing obligation on you). `OnceLock`'s own docs
[QUOTED]:

> A synchronization primitive which can nominally be written to only once.
> This type is a thread-safe `OnceCell`, and can be used in statics. […]
> Unlike `Mutex`, `OnceLock` is never poisoned on panic.

The standard idiom for a global registry today is
`static REG: LazyLock<Mutex<HashMap<K, V>>>`.

**The lesson for Avra** [JUDGED], and it is the structural one: **Rust did not
remove the capability. It removed the untyped form and replaced it with typed
forms, each of which names its synchronization discipline in the type.**
`static REG: Mutex<T>` spells (b) with `static` and (a) with `Mutex`, as two
words that compose. That is precisely the decomposition §2 argues for, made
visible in the syntax.

### 3.2 Zig — plain, unfenced, and constrained by the allocator instead

Container-level `var` is ordinary Zig. It has global lifetime, is
order-independent, lazily analysed, and its initializer is implicitly
comptime [QUOTED, §3.1 above]. `threadlocal var` gives per-thread instances;
"Thread local variables may not be `const`" [QUOTED].

The interaction with Zig's memory model is the interesting part [QUOTED, from
Zig's stated principles and community docs]:

> There is no such thing as a global allocator. […] Any function requiring
> dynamic allocations must accept an allocator as a parameter.

**So a Zig global registry cannot allocate at declaration time.** In practice
it is either a fixed-capacity array sized at comptime, or a
`var x: ?*T = null` filled by an explicit `init(allocator)`. [JUDGED] This is
the same constraint Avra faces and the same answer Avra's runtime already
picked: `#define AVRA_ONCE_MAX 256`, and `avra_trap("more \`once\` values than
the cache holds")` on overflow. Zig is the honest counter-example to "everyone
is running from globals" — but note that Zig has no aliasing model to protect
and pushes safety to the programmer everywhere else, which Avra explicitly
does not (P1).

### 3.3 Go — permitted, and the style guide is the most useful document in this survey

Package-level `var` plus `func init()` plus `sync.Once`. The Google Go Style
Guide's "Global state" section [QUOTED]:

> Libraries should not force their clients to use APIs that rely on global
> state. They are advised not to expose APIs or export package level variables
> that control behavior for all clients as parts of their API. […] Instead, if
> your functionality maintains state, allow your clients to create and use
> instance values.

> Global state has cascading effects on the health of the Google codebase.
> Global state should be approached with **extreme scrutiny**.

Its **litmus tests** are directly adoptable. Unsafe when [QUOTED]:

> - Multiple functions interact via global state when executed in the same
>   program, despite being otherwise independent […]
> - Independent test cases interact with each other through global state.
> - Users of the API are tempted to swap or replace global state for testing
>   purposes […]
> - Users have to consider special ordering requirements when interacting with
>   global state: `func init`, whether flags are parsed yet, etc.

Safe when any of [QUOTED]:

> - The global state is logically constant […]
> - **The package's observable behavior is stateless. For example, a public
>   function may use a private global variable as a cache, but so long as the
>   caller can't distinguish cache hits from misses, the function is
>   stateless.**
> - The global state does not bleed into things that are external to the
>   program […]
> - There is no expectation of predictable behavior […]

**Two findings here, and the first is the most valuable single sentence in
this document** [JUDGED]:

1. That second "safe" case **is Avra's own cache-vs-state test**, arrived at
   independently. ROADMAP.md:2121: "A cache has a testable definition the
   kernel already asserts (`Db.sweep()`: clearing it leaves every answer
   unchanged)". Google's Go style guide and Avra's ROADMAP wrote the same
   discriminator. That convergence is strong evidence the test is right, and
   it is the sentence that resolves the spec 13.3 `@pure`/`@memo`
   contradiction (see §5.4).
2. Where Go *does* permit package state, it requires the instance API to be
   primary and the global one to be a thin proxy — the `http.Handle` →
   `http.DefaultServeMux` shape, with the added rules that the package must
   offer isolated instances, and that infrastructure libraries must not rely
   on the package-level state of packages they import. **That is a directly
   quotable rule for `@std/sqlite`.**

### 3.4 Swift — the most recent revisit, and the one Avra should read as its own future

Swift's globals were already lazily and *atomically* initialized, and the
docs say so [QUOTED]:

> Stored type properties are lazily initialized on their first access. They're
> guaranteed to be initialized only once, even when accessed by multiple
> threads simultaneously, and they don't need to be marked with the `lazy`
> modifier.

(The same docs draw the contrast that `lazy var` instance properties are *not*
thread-safe — Swift paid for global safety specifically, not laziness
generally.)

Then Swift 6 arrived. SE-0412 [QUOTED]:

> **Global state poses a challenge within concurrency because it is memory
> that can be accessed from any program context.**

The compiler now diagnoses ordinary code that has worked for a decade
[QUOTED]:

```swift
var value = 1
func f() {
  value = 2 // warning: reference to var 'value' is not concurrency-safe
            // because it involves shared mutable state
}
```

A global is now safe only if it is isolated to a global actor (`@MainActor`),
or is a `let` of `Sendable` type, or carries the opt-out [QUOTED]:

> There may be need in some circumstances to opt out of static checking to
> enable the developer to rely upon their own data isolation management, such
> as with an associated global lock serializing data access. The attribute
> `nonisolated(unsafe)` can be used to annotate the global variable (or any
> form of storage).

**This is the single most relevant precedent in the survey** [JUDGED]. Swift
is the "no threads yet, but we will" language, ten years later. It shipped
plain global mutable state, and when concurrency landed it had to make every
one of them a diagnostic and ship an ecosystem-wide escape hatch whose entire
purpose is to say *"I know, and I take responsibility."* Note precisely which
form survived unannotated: **a `let` of a `Sendable` type** — write-once and
immutable. That is `once fn`'s shape.

### 3.5 Erlang/Elixir — no shared mutable state at all; state is a process

The BEAM answer is that mutable state has an *owner*: an `Agent` or
`GenServer` process holds it and readers send messages; ETS is a shared table
with copy semantics; `persistent_term` is the read-mostly global.

`persistent_term`'s docs are worth reading for the trade-off it makes explicit
[QUOTED]:

> […] storage for Erlang terms that can be accessed in constant time, but with
> the difference that it has been highly optimized for reading terms at the
> expense of writing and updating terms.

> Term lookup (using `get/1`) is done in constant time and without taking any
> locks, and the term is not copied to the heap […]. When a persistent term is
> updated or deleted, a **global garbage collection pass** is run to scan all
> processes for the deleted term […]

> persistent terms is an advanced feature and is not a general replacement for
> ETS tables.

**What the process model buys**: no data races by construction, and — the
part that matters most for a handle table — **the state has an owner with a
lifetime and a supervisor, so "who closes the handle when the owner dies" has
an answer**. What it costs: every access is a message (a copy and a context
switch), the owner is a bottleneck and a single point of failure, and the
state's identity becomes a pid that can die.

[JUDGED] This is the closest model to "a handle table is a service", and P2
("substrate for autonomous services") points there eventually. Do not adopt
it now — it costs a scheduler and a process model Avra does not have. But note
which BEAM primitive matches a handle table: **ETS, not `persistent_term`** —
a connection table is written on every open and close, and `persistent_term`
buys lock-free reads by making writes catastrophically expensive. Getting
that backwards is a real design error available here.

### 3.6 Haskell — the capability is needed, no principled way exists, and the hack breaks the language's defining property

The idiom [QUOTED]:

```haskell
myGlobalVar :: IORef Int
{-# NOINLINE myGlobalVar #-}
myGlobalVar = unsafePerformIO (newIORef 17)
```

Why the wiki calls it a hack [QUOTED]:

> The meaning of a program using this pattern "is likely to change if any
> occurrence of `myGlobalVar` is replaced with the rhs of the declaration."

> There's no theoretical justification for the correctness of the idiom.

and it can "break the type system by creating a top-level `IORef` with a
polymorphic type."

The wiki's own advice: constants at top level are "No problem"; a read-only
environment should be threaded or hidden in a monad; **mutable state
"reflects a design problem"** and wants a bundle of parameters. It cites John
Hughes's survey of the unsafePerformIO hack, implicit parameters and Reader
monad transformers as concluding "none of which are totally satisfactory."

[JUDGED] Haskell is the language whose purity is nearest Avra's north star,
and its verdict is the uncomfortable one: **the capability is genuinely
needed, the language never found a principled way to give it, and the hack
the ecosystem uses violates referential transparency — the property the
language exists for.** GHC then used that hack on itself; see §4.1.

### 3.7 The brief ones

- **OCaml.** `ref` and mutable record fields are (a); a top-level
  `let r = ref 0` is (a)×(b) and entirely ordinary. Then OCaml 5 landed
  domains, and the stdlib's globals became a migration: "Global state in
  modules like `Random`, `Hashtbl`, and `Filename` has been made
  domain-local, and the default state in `Format` is now set to Domain-Local"
  [READ]. Domain-Local Storage is the mechanism. **The same story as Swift, in
  a language thirty years older.**
- **C++.** Function-local statics are the answer, and the standard buys their
  laziness with a hidden lock — [stmt.dcl]/3 [QUOTED]: "If control enters the
  declaration concurrently while the variable is being initialized, the
  concurrent execution shall wait for completion of the initialization." And
  the price, in the same paragraph: "If control **re-enters the declaration
  recursively** while the variable is being initialized, the behavior is
  undefined." Namespace-scope statics have the initialization-order fiasco
  instead, which is why function-local won.
- **Java.** `static` fields under a per-class lock — JLS 12.4.2 [QUOTED]:
  "For each class or interface C, there is a unique initialization lock `LC`."
  Another thread blocks (step 2); **the recursive case "must be a recursive
  request for initialization. Release `LC` and complete normally"** (step 3) —
  i.e. it sees a *partially initialized* class. C++ chose UB for that case;
  Java chose a wrong answer. [JUDGED] Both are the price of lazy global init,
  and both are a hazard Avra inherits the day `once` gains a lock.
- **Python.** Module globals are the singleton, blessed by the FAQ [QUOTED]:
  "The canonical way to share information across modules within a single
  program is to create a special module (often called `config` or `cfg`). […]
  Because there is only one instance of each module, any changes made to the
  module object get reflected everywhere. […] Note that using a module is also
  the basis for implementing the singleton design pattern, for the same
  reason." No synchronization; the GIL makes single bytecodes atomic and
  nothing more.

### 3.8 The pattern across all of them [JUDGED]

**No language that has threads has plain, safe, ergonomic global mutable
state.** Every one of them took one of four exits:

1. **Made it unsafe or annotated** — Rust (`unsafe` + a deny lint), Swift
   (`nonisolated(unsafe)` / a global actor).
2. **Told you not to** — Go (style guide, "extreme scrutiny"), Haskell
   ("reflects a design problem").
3. **Retrofitted it per-thread or per-domain** — OCaml (DLS), Zig
   (`threadlocal`), rustc (`SessionGlobals` in TLS).
4. **Refused it entirely** — Erlang/Elixir.

And the two that shipped it plain before concurrency — **Swift and OCaml —
both paid a whole-ecosystem migration when concurrency arrived.** Rust shipped
`static mut` in 1.0 and spent editions deprecating it. Nobody who landed the
unfenced form was glad of it.

---

## 4. Q3 — WHAT IT COSTS A PURE-CORE COMPILER

Four self-hosted precedents. They split cleanly, and the line they split on is
the answer.

### 4.1 GHC — the cautionary tale, and it is uncannily close to Avra's shape

"Modularizing GHC" (Henry, Ericson, Young, 2022), abstract [QUOTED]:

> GHC is **not exemplary of good large scale system design in a pure function
> language**. Rather ironically, it violates the properties that draw people
> to functional programming in the first place: immutability, modularity, and
> composability. […] we document in detail, GHC's architectural problems, such
> as **low coherence and high coupling of mutable state**, and their genesis.

The paper has a section titled **"3.2.5 The genesis of a global mutable
DynFlags variable."** The genesis was the **pretty-printer**. GHC commit
f7cd14fd, October 2012 [QUOTED from the paper]:

> Put the DynFlags in a global variable for tracing; fixes #7304
>
> This is an ugly kludge to make a DynFlags value available for the 'trace'
> functions. It may not be the value we really ought to use, but it'll be good
> enough for the pretty-printer to use
>
> Ideally we'd pass the real DynFlags down to all the trace calls, but this
> will do for now at least.

The comment that shipped in the source alongside it [QUOTED]:

> -- Do not use unsafeGlobalDynFlags!
> --
> -- unsafeGlobalDynFlags is a hack, necessary because we need to be able to
> -- show SDocs when tracing, but we don't always have DynFlags available.
> --
> -- **Do not use it if you can help it. You may get the wrong value!**

```haskell
GLOBAL_VAR(v_unsafeGlobalDynFlags,
           panic "v_unsafeGlobalDynFlags: not initialised", DynFlags)
unsafeGlobalDynFlags = unsafePerformIO $ readIORef v_unsafeGlobalDynFlags
```

The paper's next sentence [QUOTED]: "Notice that the default value of the
global variable is a **panic** again!" — which forced a 2015 commit, "Dont
call unsafeGlobalDynFlags if it is not set." And it eventually reached users:
under Windows, a statically-linked host compiler and its plugins got
**distinct copies of the global**, so plugin `DynFlags` were never reliably
initialized and users saw panics (GHC #18339). The paper's fix was to shrink
it to three global `Bool`s "that never panic", with: "Ideally we would get rid
of them too, but it requires a lot more work."

Then section **"3.2.6 When immutable really becomes mutable: GHCi"** [QUOTED]:

> The GHC library has mostly been designed to serve the GHC program. Hence it
> was architected to follow a **one-shot use case** […]. In this model, the
> command-line flags are constant during the whole execution […]. However, the
> implementation of the interactive REPL (GHCi) **broke this model!**

**Three lessons, and every one of them names a shape Avra has** [JUDGED]:

1. **The entry point was DIAGNOSTICS** — a printer that needed context nobody
   had threaded. Avra's compiler has that exact shape: `cx.emit(d)` reaching
   `self.facts.speak(d)`, the `voices` channel every rule wants, the
   `spoken`/`emit` voice fns at every file's tail. If a global mutable state
   ever enters this compiler, it will enter through the diagnostic channel,
   and it will look convenient.
2. **The default was a panic** — the "not yet initialized" state that no type
   made unrepresentable. Avra's `once fn` does not have this hole: the value
   is computed by the fn on first ask, so there is no uninitialized window to
   read. That is a real advantage and worth keeping deliberately.
3. **It broke when the compiler stopped being one-shot.** Avra's L5 says the
   destination is "the compiler process is the one long-lived query engine
   behind CLI, LSP, build, and — Era V — the service orchestrator." **Avra is
   walking toward GHCi.** Any process state landed now must be evaluated
   against a long-lived, multi-workspace process, not against `avra build`.

### 4.2 Go's compiler — globals were the reason the front end stayed serial

Issue #15756, "cmd/compile: parallelize compilation", states it in one line
[QUOTED]: **"For all of these changes, we'd need to de-globalize the current
compiler."** Go 1.9 shipped concurrent *backend* compilation only.

### 4.3 rustc — the honest counter-example, and the shape it chose is the lesson

rustc is a memoized pure-query engine (the query system over `TyCtxt`) **and**
it has genuine global mutable state. `SessionGlobals` [QUOTED]:

> Per-session global variables: this struct is stored in **thread-local
> storage** in such a way that it is accessible without any kind of handle to
> all threads within the compilation session, but is **not accessible outside
> the session**.

It holds `symbol_interner`, `span_interner`, `hygiene_data`, `metavar_spans`
and `source_map`, and the type is `!Send`/`!Sync`.

**Note exactly what rustc bought and how it paid** [JUDGED]:

- **Scoped, not forever** — entered via `create_session_globals_then`, so its
  lifetime is a session, not the process.
- **Thread-local, not shared** — the aliasing problem is sidestepped, not
  solved.
- **Interner-shaped** — write-once-per-key, so a re-derivation gets the same
  answer. This is what makes it compatible with a memoizing query engine at
  all: *an interner is idempotent, so a query that touches it is still a
  function of its inputs.*

And the one field the docs apologize for is — again — **the printer**
[QUOTED]: `source_map` "should only be used in places where the `Session` is
truly not available, such as `<Span as Debug>::fmt`."

The contrast worth having: **Salsa**, rust-analyzer's incrementality engine
and the closest published relative of Avra's L1 kernel, keeps interning
*inside the database handle*. An interned struct "canonicalizes an immutable
set of field values" giving "one **database-wide** identity" [READ] — reached
through the explicitly-threaded `&db`, never a global. Two engines with the
same job made opposite calls; the pure one is the one Avra's north star names.

### 4.4 The answer to Q3, stated plainly [JUDGED]

**The language gaining the capability does not threaten the compiler's design.
The compiler's own USE of it would.** The precedents split exactly on
deliberateness:

- rustc used it **deliberately**, in a shape a pure query engine tolerates
  (session-scoped, thread-local, idempotent interner). Cost: contained.
- GHC used it **accidentally**, in a shape that could not be contained
  (unscoped, panic-defaulted, printer-driven). Cost: a 2022 paper and a
  multi-year refactor.
- Go used it accidentally and paid in serial compilation.

So "the compiler declines to use it" is a correct answer **only if declining
is a MECHANISM rather than a resolution.** GHC's own source said "Do not use
it if you can help it" and it spread anyway. Avra has something GHC did not:
`make idioms`, a ratchet that fails on any *new* violation and demands a
`// LICENSED I<n>:` at the site — which is the EXEMPTION LAW, already
doctrine here: "a doctrine exemption that is not written AT THE SITE is an
unbounded amnesty."

Concrete: **land the capability and land its ratchet on the same day.**

---

## 5. Q4 — NAMING

### 5.1 What Rust's `Cell<T>` actually means [QUOTED]

> `Cell<T>` implements interior mutability **by moving values in and out of
> the cell**. That is, a `&T` to the inner value can never be obtained, and
> the value itself cannot be directly obtained without replacing it with
> something else.

> `Cell<T>` is typically used for **more simple types where copying or moving
> values isn't too resource intensive (e.g. numbers)**, and should usually be
> preferred over other cell types when possible. **For larger and non-copy
> types, `RefCell` provides some advantages.**

### 5.2 What Avra's `Cell<T>` is proposed to mean [MEASURED, from ROADMAP.md:10693]

`Cell<TypeRegistry>`, `Cell<Decls>`, `Cell<NodeStore>`, `Cell<Db>` — large
aggregates, "a shared box whose writes are visible through every alias BY
DECLARATION, **with methods forwarding in place**."

### 5.3 The collision is real and it is already costing something [JUDGED]

Avra's `Cell` is used for exactly the case Rust's docs say `Cell` is *not*
for and `RefCell` *is* for. Worse than a mismatch, the name is **pulling the
design**: spec 11.3 specifies the `get`/`set` surface, which is Rust `Cell`'s
surface, and the ROADMAP has already recorded that get/set on an aggregate is
"refused alternative (b) — it clones the fact tables per diagnostic"
(ROADMAP.md:2104). **The name imported a surface the design cannot afford,
and the ROADMAP had to refuse it in prose.** A different name would not have
proposed it.

The P1 cost compounds this. `Cell<T>`'s training distribution is
overwhelmingly Rust's `Cell<T>`. An LLM generating Avra will write
`reg.get()` / `reg.set(updated)` against a type whose entire point is in-place
forwarding — a first-generation error caused by the name alone.

### 5.4 What other languages call each concept [READ]

**(a) shared writing** — OCaml `ref`; Haskell `IORef`/`MVar`/`STRef`; Clojure
`Atom` ("Atoms provide a way to manage shared, synchronous, independent
state"), `Ref` (coordinated, transactional), `Agent` (asynchronous); Scala
`Ref`; Rust `Cell`/`RefCell`/`Mutex`/`RwLock`; C#, Java, Swift — reference
semantics via `class`, or an `actor`.

The pattern: **the good names name the SHARING DISCIPLINE, not the box.**
`Mutex` names the lock. `Atom` names atomicity. `Ref` names Clojure's
Identity — "a stable logical entity associated with a series of different
values over time" [QUOTED]. **`Cell` names nothing at all**, which is why Rust
needed three of them and a distinguishing prefix on each.

**(b) process-wide** — near-total agreement: the word is `static` (C, C++,
Rust, Zig, Swift, Java) or the storage is a module (Go, Python). Erlang has
`persistent_term`. **Nobody calls it a Cell.**

### 5.5 Recommendation

**For (b) — keep `once fn`. Add nothing.**
It already says exactly what it is: an answer settled once, for the process.
It is a *fn*, which keeps the store/query model intact — a `once fn` is a
memoized nullary derivation, which is the north star's L1 kernel applied to
itself. And it is the one global form Swift 6 still permits unannotated (a
`let` of a `Sendable` type). Do not add a `static` keyword; there is nothing
for it to do.
**Corollary: delete `OnceCell<T>` from spec 11.3.** `once fn` already is it.

**For (a) — do NOT call it `Cell`.** Ranked candidates:

1. **`Mut<T>` — recommended.** Maximally consistent with Avra's own
   vocabulary, where `mut` already means "this place may be written."
   `Mut<Decls>` reads as "a Decls that may be written through any holder." It
   makes the one new concept a *lift of a word the language already teaches*,
   which is the strongest P1/P3 answer available: an LLM that knows `mut xs`
   guesses `Mut<T>` correctly and does not import Rust's `Cell` semantics.
   The objection — that `mut` already marks a place and a seat, so a type is a
   third meaning — is weak, because it is the *same* meaning ("writable")
   lifted, which is the good kind of overload.
2. **`Ref<T>`** — the OCaml/Clojure/Scala name and the most widely understood
   word for "an identity with values over time." Avra has no reference type,
   so the word is free. Choose this if the owner wants the concept to read as
   an *identity* rather than a *permission*.
3. **`Shared<T>`** — accurate to the ROADMAP's own definition, but inverts
   Rust's `&T` = shared = not-writable, so it trades one collision for
   another.

**Keep `Lazy<T>`** (universal, unambiguous). **Reserve `Mutex<T>`** for the
thread-safe sibling as spec 11.3 already versions it.

**And if Avra ever wants Rust's actual `Cell` semantics — copy in, copy out —
that is when the name `Cell` is earned.** It almost certainly never will,
because Avra's value semantics give copy-in/copy-out for free.

---

## 6. Q5 — WHAT AVRA SHOULD DO

### 6.1 The general answer

**Two composable pieces, one of which is already landed. No new global
syntax.**

```avra
once fn conns() -> Mut<Table> { Mut(Table { slots: [], gens: [] }) }
```

- (b) `once fn` — done, and the runtime table exists.
- (a) `Mut<T>` — spec 11.3's `Cell<T>`, renamed, single-threaded by
  declaration.
- Their composition is the handle table, and it required no third concept.

[JUDGED] This is a P6 collapse. "Global mutable state, yes or no" is the false
dichotomy; the model was wrong. Avra does not need a global-variable feature
because it already has the process-wide slot, and the missing half is a
sharing discipline it already planned to build for the memo kernel.

### 6.2 But the handle table has a NARROWER answer, and it should land FIRST

The sqlite vision already names it: `opaque type Db
@free_with(sqlite3_close_v2)` (spec Axis 15.5, `FULL_SPEC.md:3004` — the spec
literally uses `opaque type SQLite3 @free_with(sqlite3_close)` as its
example).

**That is the WebAssembly Component Model's `resource` type** [QUOTED]:

> A resource is a handle to some entity that exists outside of the component.
> Resources describe entities that **can't or shouldn't be copied**: entities
> that should be passed by reference rather than by value.

> When the owner of an owned resource drops that resource, the resource is
> destroyed.

with `borrow<T>` being "a temporary loan of a resource from the caller to the
callee for the duration of the call." It is also POSIX file descriptors,
Erlang NIF resources, Vulkan handles, and the generational index — Rust's
`slotmap` [READ]: "The keys returned by slotmap are versioned. This means that
once a key is removed, it stays removed, even if the physical storage inside
the slotmap is reused for new elements." That is exactly the
`gen << 32 | idx` scheme the C runtime already runs for child processes.

**Why the narrow answer is better here** [JUDGED]:

1. **It needs no general global state at all.** The registry lives in the
   RUNTIME (C), where the child-process table already lives. The
   language-level thing is a *type with a destructor*, not a mutable global.
   `@free_with` teaches the memory pass one new kind of releasable thing —
   the ROADMAP's own framing.
2. **It moves the double-close refusal from RUNTIME to COMPILE TIME.** A
   package-owned generation table catches a second close at runtime with a
   named refusal. A resource type means the second close *cannot be written*:
   the value is released at scope exit, once, by the pass that already
   releases managed values. **P1 prefers the form that cannot be written
   wrong over the form that refuses politely.**
3. **It generalizes.** Every future binding — a socket, a file, a texture, a
   compiled regex, a curl handle — wants the same thing. One core event
   versus N packages each rolling a generation table.
4. **The seat law already pays half of it.** ROADMAP.md:2090 records that
   `close(db)` on a `let` is F2048, so "a closable handle cannot be held in an
   immutable place" — a law that arrived from unrelated work and already
   narrows the unsafe shape.

**The honest fence on the narrow answer**: a resource type gives you *one
handle's lifetime*. It does not give `@std/sqlite` everything, because the
vision wants a second thing — **the prepared-statement cache keyed by SQL
text** (II.6: "the string IS the cache key"). That cache is per-connection, so
it can live inside the `Db` resource's payload — but only if a resource may
hold mutable state, which is (a) again. And `sqlite3_initialize` is genuinely
once-per-process, which is `once fn`.

**So `@std/sqlite` needs: a resource type (handle) + (a) inside it (statement
cache) + `once` (library init, have it). It does NOT need arbitrary mutable
globals.** The forcing case, examined, forces less than it appeared to.

### 6.3 Timing: land now, in the form that survives threads

The evidence in §3.8 is one-sided, and it does *not* say wait. Waiting costs
`@std/sqlite` and every binding after it. It says: **land the form whose
migration to threads is a no-op.**

- **`once fn` is already that form.** Write-once, therefore `let`-shaped,
  therefore Sendable-shaped — the one global Swift 6 still permits
  unannotated. Its only thread work is making the `g_once` fill atomic, which
  C++ (magic statics), Java (`LC`) and Swift (`swift_once`) have each already
  solved, with the recursion hazard each documented. Cheap and known.
- **`Mut<T>` is NOT that form, and must say so from day one** — in its type,
  its docs and its diagnostics, exactly as Rust's `std::cell` does ("they do
  not implement `Sync`"). Its thread-safe sibling `Mutex<T>` is already spec
  11.3's v1.x plan. If `Mut<T>` ships declared single-threaded and the
  compiler can name it at a future thread boundary, the migration is
  mechanical rather than an ecosystem event.
- **A resource type is thread-agnostic** — it is a lifetime, not a sharing
  discipline. Nothing about threads changes it. Land it with no reservations.

### 6.4 THE FENCE

1. **No general mutable-global syntax. Ever.** No `static mut`, no
   module-level `mut`, no `global`. Every language that has one either regrets
   it (Rust), diagnoses it (Swift), or tells you not to use it (Go, Haskell).
   `once fn` × `Mut<T>` covers every case with two pieces that each say what
   they do.
2. **The instance API is primary; any process-wide one is a thin proxy over
   it.** Google's rule, stated for `@std/sqlite`: `Db.open(path)` answers a
   value the caller holds. If a convenience over a default connection ever
   appears, it must be a thin proxy over the instance API and must not be
   usable from a library. Quotable at review; enforceable.
3. **The compiler declines it, and a RATCHET enforces the declining.** No
   compiler-side `Mut<T>` site exists unless it passes the sweep test
   (clearing it leaves every answer unchanged), `// LICENSED I<n>:` at the
   site per the EXEMPTION LAW. GHC's own comment said "Do not use it if you
   can help it" and it spread anyway. A prose exemption is an unbounded
   amnesty.
4. **Amend spec 13.3 with Google's sentence.** 13.3 says `@pure` verifies "No
   mutation of external state (globals, interior-mut cells)" and `@memo`
   requires `@pure` — which forbids the memo kernel `Mut<T>` exists for. The
   ROADMAP already flagged the contradiction (ROADMAP.md:2118). The resolution
   is one sentence, already written by Google and already asserted by Avra's
   kernel: *a private cache is not external state when the caller cannot
   distinguish a hit from a miss* — testable as `Db.sweep()`. Do not invent a
   second wrapper or a new mark; amend 13.3.
5. **Watch the diagnostic channel.** GHC's global entered through the
   pretty-printer; rustc's one apologetic field is the printer. Avra's
   `voices`/`facts.speak` channel is the same shape and will be the first
   place someone wants process state. Name it now so the reviewer recognizes
   it.
6. **Note the `once` cache's own limits, don't fix them yet.**
   `AVRA_ONCE_MAX 256` traps on overflow; lookup is a linear scan with a
   `strcmp` fallback. Fine today; if `once` becomes *the* process-state
   mechanism it will be asked to hold more, and a fixed cap plus a linear
   scan is a law that will eventually speak in a program's face.

### 6.5 Order of landing [JUDGED]

1. **`@free_with` / resource types (Axis 15.5).** Unblocks the sqlite forcing
   case and every binding after it, needs no new state concept, and turns a
   runtime refusal into an unwritable form.
2. **Rename `Cell<T>` → `Mut<T>` in spec 11.3 and the ROADMAP, before any
   code carries the name.** Renaming a spec line is free. Renaming a landed
   core type is not. Delete `OnceCell<T>` in the same edit.
3. **`Mut<T>` itself** — single-threaded by declaration, with the memo kernel
   as its first user and the sweep test as its gate. This is the ROADMAP's S2
   and it is unblocked once the name is settled.
4. **`Mutex<T>`** when threads land. `once fn` needs only an atomic fill.

---

## 7. SOURCES

**Rust**
- Rust Edition Guide, "Disallow references to static mut" — https://doc.rust-lang.org/edition-guide/rust-2024/static-mut-references.html
- RFC 3560, "deprecate static mut" — https://github.com/rust-lang/rfcs (text mirrored at https://github.com/dyslexicsteak/rfcs/blob/master/text/3560-deprecate-static-mut.md)
- `std::cell` module docs — https://doc.rust-lang.org/std/cell/index.html
- `std::sync::OnceLock` — https://doc.rust-lang.org/std/sync/struct.OnceLock.html
- `rustc_span::SessionGlobals` — https://doc.rust-lang.org/nightly/nightly-rustc/rustc_span/struct.SessionGlobals.html
- rustc dev guide, queries — https://rustc-dev-guide.rust-lang.org/query.html
- Salsa — https://salsa-rs.github.io/salsa/overview.html
- `slotmap` — https://docs.rs/slotmap

**Zig**
- Language Reference, Container Level Variables / threadlocal — https://ziglang.org/documentation/master/#Container-Level-Variables

**Go**
- Google Go Style Guide, "Global state" — https://google.github.io/styleguide/go/best-practices#global-state (raw: https://raw.githubusercontent.com/google/styleguide/gh-pages/go/best-practices.md)
- golang/go#15756, "cmd/compile: parallelize compilation" — https://github.com/golang/go/issues/15756

**Swift**
- SE-0412, Strict concurrency for global variables — https://github.com/swiftlang/swift-evolution/blob/main/proposals/0412-strict-concurrency-for-global-variables.md
- The Swift Programming Language, Properties — https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/

**Erlang/Elixir**
- `persistent_term` — https://www.erlang.org/doc/apps/erts/persistent_term.html
- Elixir, Simple state with agents — https://hexdocs.pm/elixir/agents.html

**Haskell**
- HaskellWiki, Top level mutable state — https://wiki.haskell.org/Top_level_mutable_state
- HaskellWiki, Global variables — https://wiki.haskell.org/Global_variables
- Henry, Ericson, Young, "Modularizing GHC" (2022) — https://hsyl20.fr/home/files/papers/2022-ghc-modularity.pdf
- GHC #18339 — https://gitlab.haskell.org/ghc/ghc/-/issues/18339

**OCaml**
- ocaml-multicore design notes — https://github.com/ocaml-multicore/docs/blob/main/ocaml_5_design.md
- Transitioning to Multicore with TSan — https://ocaml.org/docs/multicore-transition

**C++ / Java / Python**
- [stmt.dcl] — https://eel.is/c++draft/stmt.dcl
- JLS 12.4.2 — https://docs.oracle.com/javase/specs/jls/se21/html/jls-12.html
- Python FAQ, sharing globals across modules — https://docs.python.org/3/faq/programming.html

**Other**
- WebAssembly Component Model, WIT resources — https://component-model.bytecodealliance.org/design/wit.html
- Clojure, Values and Change / Atoms — https://clojure.org/about/state, https://clojure.org/reference/atoms
- Weissflog, "Handles are the better pointers" — https://floooh.github.io/2018/06/17/handles-vs-pointers.html

**In-tree**
- `runtime/avra_runtime.c:838-885` (the once cache)
- `ROADMAP.md:2095-2125` (S2's open questions), `:8049`, `:10680-10745` (the (A)/(B) split and the `Cell` design)
- `FULL_SPEC.md:2042-2069` (11.3), `:2617-2651` (13.3), `:2971-3005` (15.5 `@free_with`)
- `docs/2026_09_05_STD_SQLITE_VISION.md` §II.4, §II.6
