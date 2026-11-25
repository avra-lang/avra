# Implicit context: prior art and what went wrong

Research date: 2026-11-16. Scope: values that reach a block without being passed (theme, locale, logger,
allocator, deadline, DB handle). The focus is failure modes and complaints, not feature tours.

Conventions:
- **UNVERIFIED** marks a claim I could not confirm from a source fetched during this research (memory or
  secondary inference only).
- "Fetched" sources were read directly. Search-summary sources are cited, but they are weaker evidence.

---

## 0. The design axes used throughout

Every system below picks a point on each axis. Most of the trouble lives where two axes interact.

| Axis | Options |
|---|---|
| Resolution | **lexical/static** (compiler resolves at the call site) vs **dynamic** (nearest binding on the runtime stack/tree) |
| Key | **by type** (Scala given, Kotlin context param, SwiftUI `@Environment(T.self)`) vs **by name/key object** (Odin field, Go key, React Context object, Java `ScopedValue` static) |
| Carrier | hidden parameter / register (Odin, Jai, Scala, Kotlin) vs thread-/task-local slot (Java, Swift TaskLocal, Lisp, Clojure, Python) vs tree node (React, SwiftUI, Compose, Flutter) vs explicit value (Go, Zig) |
| Missing value | default (React, Compose, Odin, Swift TaskLocal) vs compile error (Scala, Kotlin, Haskell `?x`, Rust proposal) vs runtime throw (Java `get()`, SwiftUI `@EnvironmentObject`, Flutter Provider) |
| Deferred code | captures at **creation** vs reads at **call** time |
| Mutability | immutable rebinding only (Java ScopedValue, Swift TaskLocal, Compose) vs mutable (ThreadLocal, Odin copy-on-write field writes, Jai) |

---

## 1. Odin `context`

**Mechanism.** Every procedure using the default `"odin"` calling convention receives a hidden pointer to a
`runtime.Context` struct (allocator, temp allocator, logger, assertion proc, RNG, `user_ptr`/`user_index`).
Each scope has an implicit `context`; assigning to it is copy-on-write, so changes do not propagate back out.

```odin
my_proc :: proc() {
    context.allocator = my_arena_allocator()   // affects calls made from here on, in this scope
    s := make([]int, 10)                        // allocated from the arena
    third_party.do_stuff()                      // also allocates from the arena
}
```

**Set / read.** Assign a field (`context.logger = ...`) or the whole thing (`context = runtime.default_context()`);
read `context.x`. Scope-local; callers never see a callee's change.

**Lookup.** Lexical-ish *by construction* (it is a parameter), dynamic *in effect* (whatever the caller held).
By field name; the struct is fixed.

**Cost.** One pointer argument per Odin-convention call, passed "by pointer to each procedure call made in that
scope" ([gingerbill, 2025](https://gingerbill.org/article/2025/12/15/odins-most-misunderstood-feature-context)).
No TLS. A copy on first write in a scope.

**Pain points.**
- **The purpose is misunderstood.** Bill Hall's own 2025 article is titled "context — Odin's Most
  Misunderstood Feature": people think it is for "reducing parameter passing, dynamic scoping, or
  convenience", but "the entire point of the context system is to intercept third-party code, and to change
  how it does things" ([gingerbill](https://gingerbill.org/article/2025/12/15/odins-most-misunderstood-feature-context)).
  Lesson: the *intended* use (interception of code you don't own) is narrower than the use people reach for.
- **No user fields.** The layout is fixed because custom fields "would not be ABI consistent, and thus not be
  stable" across LIB/DLL boundaries (same source). Users wanting their own context values get `user_ptr`, an
  untyped hole.
- **Copy-on-write surprises.** A forum user set `context.allocator` in `init()` and was surprised it did not
  affect later `step()`/`shutdown()` calls made separately by a WASM host; the answer was that each entry point
  gets its own context ([forum thread](https://forum.odin-lang.org/t/why-shouldnt-context-inside-a-procedure-require-an-explicit-procedure-parameter/1791)).
  The user asked for the context to be an *explicit* parameter so changes would be visible in signatures.
- **C callbacks lose it.** `"c"` procedures get no context; inside them you must write
  `context = runtime.default_context()`, which yields *defaults*, not the caller's logger/allocator
  ([gingerbill](https://gingerbill.org/article/2025/12/15/odins-most-misunderstood-feature-context);
  [r/odinlang report about an SDL3 log callback](https://r.enesgenc.dev/r/odinlang/comments/1jzby0m/getting_current_context_in_c_procedure)).
  The fix is `user_ptr`/userdata, i.e. back to explicit passing.
- **Threads.** `core:thread` takes an optional `init_context`; without it a thread gets a fresh temp allocator
  ([core:thread docs](https://pkg.odin-lang.org/core/thread)). Whether the parent's allocator/logger are
  inherited by default is unclear from docs (**UNVERIFIED**); forum users report confusion that
  `default_context()` "literally initializes a new context with all default values"
  ([forum](https://forum.odin-lang.org/t/passing-context-through-foreign-calling-conventions-is-this-not-working-as-intended/762)).
- **"Contextless" marking demanded.** Users want procedures that don't use context marked so; Hall refuses:
  "you don't actually know if the code needs it or not (which is by design)". So *every* call pays the
  pointer, and you cannot tell from a signature what a procedure reads.

**What the community/author would change.** Hall states no regrets; he explicitly rejected a thread-local
stack of contexts (DLL boundaries, crash recovery, freestanding targets, fibers would need fiber-local
storage, and it would make "back-propagation trivial", which he does not want)
([gingerbill](https://gingerbill.org/article/2025/12/15/odins-most-misunderstood-feature-context)).

---

## 2. Jai `context`

**Mechanism.** Same family as Odin: an implicit `Context` struct passed to every procedure not marked
`#c_call`/`#no_context`. Unlike Odin, modules can **add fields** with `#add_context`, and a block can push a
whole new context.

```jai
#add_context this_is_the_way := true;
new_context := context;
new_context.allocator = my_arena;
push_context new_context {
    push_allocator(temp);   // restores at scope exit
    call_subroutine();      // sees the arena / temp allocator
}
```

Source: *The Way to Jai*, ch. 25 (community book; Jai is closed beta, no public official docs)
([25A_Context.md](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/25A_Context.md)).

**Set / read.** `push_context c { ... }` for the whole struct; `push_allocator(a)` macro for one field until scope
exit; read `context.field`. `Context_Base` also carries `temporary_storage`, `stack_trace`, `print_style`,
`thread_index`, logger, assertion handler.

**Lookup.** Implicit parameter; by field name; fields are program-global once added.

**Cost.** One hidden argument per call. With `build_options.stack_trace` on (default), every call also links a
`Stack_Trace_Node` into the context (same chapter). The context is large (dynamic entries, print style), but
passed by pointer.

**Pain points.**
- **`#c_call` callbacks have no context**: `print` cannot be called inside a `#c_call` routine; you must
  `push_context` a fresh one inside the callback ([ch. 29, Interacting with C](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/29A_Interacting_with_C.md)).
  Same failure as Odin.
- **Per-thread context.** "Each thread has its own Context"; a spawned thread does not inherit e.g. a
  `stack_base` set via `#add_context`, so you "need to call `init_stack_checker()` on that thread"
  ([ch. 31](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/31A_Working_with_threads.md),
  [ch. 25](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/25A_Context.md)).
- **`#add_context` is global.** Any module can grow everyone's context; Odin rejects exactly this for ABI
  reasons (see §1). No public post-mortem exists; community complaints are **UNVERIFIED** (closed beta).

---

## 3. Scala 2 implicits → Scala 3 `given`/`using`, context functions `?=>`

**Mechanism.** Parameters marked implicit are filled by the compiler by **type** from the lexical "implicit
scope" (locals, imports, companion objects of involved types).

```scala
// Scala 3
def run(q: Query)(using db: Db): Rows = db.exec(q)
given Db = Db.connect(url)
run(q)                      // compiler supplies db
run(q)(using testDb)        // explicit override
```

**Set / read.** Define a `given` in scope (or import it with `import x.given`); declare `using` on the function.
Context functions: `type Executable[T] = ExecutionContext ?=> T`; an expression expected to have that type is
wrapped as `(ec: ExecutionContext) ?=> E`, so the given is available inside
([Scala 3 reference: context functions](https://docs.scala-lang.org/scala3/reference/contextual/context-functions.html)).
This is how the `table { row { cell(...) } }` builder works with no explicit plumbing.

**Lookup.** Fully static, by type, at compile time. Missing → compile error. Ambiguous → compile error.

**Cost.** Zero at runtime beyond an ordinary extra parameter (and a closure for `?=>` values). Cost is paid at
**compile time** (implicit search) and in **readability**. The reference claims an opaque-type + extension
pattern is "close in efficiency to the best possible code one could write by hand" (same page).

**Pain points (Scala's own "Critique of the Status Quo", [Scala 3 reference](https://docs.scala-lang.org/scala3/reference/contextual/)).**
1. Over-use and mis-use, "especially implicit conversions", which shared syntax with legitimate type-class
   instances.
2. Over-reliance on implicit imports → "cryptic type errors that disappear with the right import", and it is
   hard to tell which implicits a program uses.
3. One `implicit` modifier for many constructs "conveys mechanism instead of intent".
4. Arguments not marked at call sites: `currentMap("abc")` looks like a normal argument but fills the implicit
   section; only one implicit section, must be last; must be named even if unused.
5. Tooling: availability depends on context, so completion/Scaladoc struggle; failed searches give vague errors.

**What Scala 3 changed.** Separate keywords per intent (`given` / `using` / `extension` / `Conversion`),
`using` marked at call sites, multiple `using` clauses, `import x.given` so givens can't hide in wildcard
imports, conversions demoted to a library type needing an import
([same page](https://docs.scala-lang.org/scala3/reference/contextual/);
[relationship with implicits](https://scala-lang.org/api/docs/contextual/relationship-implicits.html)).
Note that the **lookup rules were kept largely the same** for migration
([Rock the JVM](https://blog.rockthejvm.com/givens-and-implicits/)). The fix was mostly *syntax and intent*,
not semantics. Scala 2 implicits still compile in Scala 3 and "might be deprecated" later.

**Community verdict.** The reputation came from *conversions* and *invisible imports*, not from contextual
parameters themselves. Type-class/context passing via `using` is broadly accepted. Remaining complaints:
discoverability of where a given came from, and slow compile/implicit-search blowups
(**UNVERIFIED** for specific numbers).

---

## 4. Kotlin context receivers → context parameters

**Mechanism (current).** `context(name: Type)` declares named implicit parameters resolved **by type** from the
caller's implicit scope; supplied with `context(value) { ... }` blocks or existing receivers.

```kotlin
context(logger: Logger)
fun process(x: Int) { logger.info("processing $x") }

context(ConsoleLogger()) { process(1) }
```

**Status (late 2026).** Context receivers (2022, experimental) were **dropped**; context parameters were Beta in
2.2.0 and became **Stable in Kotlin 2.4.0 (released 2026-07-14)**, except explicit context arguments and
callable references, which remain Experimental ([What's new in 2.4](https://kotlinlang.org/docs/whatsnew24.html)).

**Why receivers were dropped.** Scope pollution: a context *receiver* made all its members callable unqualified,
so "too many functions became available unqualified", making it hard to find the right one and to tell where a
member came from ([KEEP: context parameters](https://github.com/Kotlin/KEEP/blob/context-parameters/proposals/context-parameters.md)).
The redesign gives each context a **name** (or `_`) and reads members through that name.

**Lookup.** Static, by type, through the scope tower. None found → candidate not applicable (compile error).
Two compatible values at the same level → "context ambiguity" error (KEEP).

**Cost.** On JVM, context parameters are **extra leading parameters** (before the extension receiver and value
parameters); names do not affect ABI (KEEP). Zero runtime lookup.

**Pain points.**
- **Overload resolution churn.** Kotlin 2.3.20 changed overload resolution so overloads differing only by context
  parameters "can become ambiguous"; 2.4 adds *explicit context arguments* (`sendNotification(emailSender = x)`)
  as the escape hatch, still experimental ([whatsnew24](https://kotlinlang.org/docs/whatsnew24.html)).
- **Callable references resolve eagerly**: "The required context parameters must be resolved in the context in
  which the reference is created", and the resulting type no longer mentions the context (KEEP). So a function
  reference *captures* context at creation; flexible resolution is "future work".
- **Function types.** `context(A) () -> B` exists; for typing it is equivalent to a function with those as
  leading value parameters. Context parameters in lambdas are inferred **only** when a contextual function type
  is the lambda's expected type (KEEP). Lambdas otherwise do not get a context slot.
- **A three-year migration.** Libraries (Arrow, Ktor experiments) adopted context receivers, then had to migrate.
  Users on Slack noted "context parameters really aren't stable yet" during 2.2
  ([kotlinlang Slack](https://slack-chats.kotlinlang.org/t/30351497/turns-out-context-parameters-really-aren-t-stable-yet-just-f)).
- **Coroutines are a separate, dynamic system.** `CoroutineContext` elements are inherited by child coroutines,
  but a `ThreadLocal` must be wrapped with `asContextElement()` to survive thread hops, and there were real bugs
  where values were not restored after undispatched `withContext`; the fix "impacts suspend/resume performance"
  ([asContextElement docs](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/as-context-element.html);
  [kotlinx.coroutines #3592](https://github.com/Kotlin/kotlinx.coroutines/issues/3592)).

**Would do differently.** JetBrains' own course correction: name contexts, don't inject members into scope.

---

## 5. Haskell: `?x` implicit parameters, and the ReaderT pattern

**Mechanism.** `ImplicitParams` expresses a dynamically bound variable as a type constraint.

```haskell
sort :: (?cmp :: a -> a -> Bool) => [a] -> [a]
sort = sortBy ?cmp
let ?cmp = compare in sort xs
```

**Set / read.** Bind with `let ?x = ...` / `where`; read `?x`. Constraints propagate through inferred types
([GHC user guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/implicit_parameters.html)).

**Lookup.** By **name**; statically checked (unbound → type error), but the *value* is the dynamically
innermost binding at the point the constraint is discharged.

**Cost.** Dictionary-passing: an extra argument. Cheap.

**Pain points.**
- **Type signatures change runtime behavior.** The GHC guide itself: "Adding a type signature dramatically
  changes the result!" — `len1 "hello"` returns 0, `len2 "hello"` (with a signature) returns 5. And under the
  monomorphism restriction a `let`-bound `y` using `?x` is not generalised, so it sees the *outer* `?x`
  ([GHC guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/implicit_parameters.html);
  [GHC #23656](https://gitlab.haskell.org/ghc/ghc/-/issues/23656);
  [haskell-cafe 2022 "inference with implicitparams seems broken"](https://mail.haskell.org/pipermail/haskell-cafe/2022-March/135169.html)).
  The root problem: *whether a binding is generalised decides whether it captures at definition or at use.*
  This is the "runs later" problem (§B) appearing inside type inference.
- **Not allowed in class/instance contexts**, because instances are invoked implicitly and it would be unclear
  which `?x` is in use (GHC guide). The same issue Rust's proposal hits with context-dependent impls (§13).
- Little adoption; the ecosystem standardised on **ReaderT** (`ReaderT Env IO` plus `Has`-style classes)
  instead — an explicit, monadic environment that is lexically clear but infects every signature with a monad
  (the FP Complete "ReaderT design pattern" article; fetch failed: **UNVERIFIED** quote-level detail).

---

## 6. Lisp special variables, Clojure `binding`

**Mechanism.** A global var declared special/dynamic; `let`/`binding` gives it a new value for the dynamic extent
of a form, per thread.

```clojure
(def ^:dynamic *locale* "en")
(binding [*locale* "fr"] (render))   ; render and everything it calls sees "fr"
```

**Lookup.** Dynamic, by name (the var), per thread. Unbound → root value.

**Cost.** A thread-local binding stack; each read checks for a thread binding (**UNVERIFIED** detail of
Clojure's fast path).

**Pain points.**
- **Laziness escapes the binding.** A lazy seq realized after `binding` returns sees the root value; the fix is
  to capture into a `let` first or bind where the seq is realized
  ([Clojure group: lazy sequences in dynamic environments](https://groups.google.com/g/clojure/c/YYW08NuHX70);
  [ClojureVerse](https://clojureverse.org/t/whats-the-right-way-to-handle-lazy-evaluation-in-a-dynamic-binding/10279);
  [cemerick, "Be mindful of Clojure's binding"](https://cemerick.com/blog/2009/11/03/be-mindful-of-clojures-binding.html)).
  Clojure's own design wiki says the traditional notions "don't interact well with laziness or thread pools"
  ([Improve Binding](https://archive.clojure.org/design-wiki/display/design/Improve%2BBinding.html)).
- **Threads.** Since Clojure 1.3, `future`, `send`, `pmap`, core.async `go` *convey* the caller's bindings
  ("binding conveyance") — but raw `Thread.` and arbitrary executors do not, which users call "a hidden feature
  of future" ([ClojureVerse](https://clojureverse.org/t/binding-in-the-context-of-future-vs-thread/3718);
  [ask.clojure: should bindings persist across thread pool uses](https://ask.clojure.org/index.php/11533/should-dynamic-bindings-persist-across-thread-pool-uses)).
  Real bug: `spec/explain-data` intermittently produced wrong reports when specs relied on dynamic vars
  ([CLJ-2229](https://clojure.atlassian.net/browse/CLJ-2229)).
- **Common Lisp**: "when a thread first begins execution, it has no dynamic bindings"; bordeaux-threads
  compensates with `*default-special-bindings*` evaluated in the new thread, and threads made by *other* APIs
  skip even that ([bordeaux-threads docs](https://sionescu.github.io/bordeaux-threads/threads/default-special-bindings);
  [SO via mirror](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/50925658/how-to-convey-current-thread-s-bindings-to-another-thread)).
- **Closures capture the var, not its value**: closing over a dynamic var does not snapshot it.

**Verdict.** Dynamic scope is fine for synchronous, eager code. It breaks at *every* deferral seam: lazy values,
closures, threads, pools. Each seam got its own ad-hoc patch (conveyance in some APIs, not others).

---

## 7. Java `ThreadLocal` → `ScopedValue`

**Mechanism (ScopedValue, final in JDK 25, [JEP 506](https://openjdk.org/jeps/506)).**

```java
static final ScopedValue<User> USER = ScopedValue.newInstance();
ScopedValue.where(USER, u).run(() -> handle());   // bound for the dynamic extent of run()
User me = USER.get();                              // NoSuchElementException if unbound
```

**Set / read.** `where(...).run/call`; no `set()`; rebinding only in a nested scope; `get()`, `isBound()`,
`orElse()` (no longer accepts `null` in 25), `orElseThrow()`
([happycoders](https://www.happycoders.eu/java/scoped-values/); [InfoQ](https://www.infoq.com/news/2025/05/jdk-news-roundup-may12-2025)).

**Lookup.** Dynamic, by key object (a `static final` field acts as the name and carries the type).

**Why ThreadLocal failed** (as summarised from the JEP by [happycoders](https://www.happycoders.eu/java/scoped-values/);
the JEP page returned 403 to my fetch):
- **Unconstrained mutability**: anyone can `set()` at any time; data flow is untraceable.
- **Unbounded lifetime**: lives until `remove()` or thread death; forgotten `remove()` in pools is a classic leak
  (and a classic cross-request data leak).
- **Expensive inheritance**: `InheritableThreadLocal` copies the whole map into every child thread — fatal with
  millions of virtual threads.

**Inheritance.** Threads forked by `StructuredTaskScope` inherit bindings *by reference*; threads from
`Thread.ofVirtual().start()` or an `ExecutorService` do **not** (unbound there). Structured concurrency itself
was still **preview** in JDK 25 ([JEP 506](https://openjdk.org/jeps/506);
[InfoQ JEP 505](https://www.infoq.com/news/2025/05/jep-505-concurrency-preview-5)). So the "good" inheritance
only exists inside a construct whose lifetime nests inside the binding.

**Cost.** Designed for cheap reads on virtual threads; inheritance is O(1) by sharing. (JEP claims cacheable
reads; specific numbers **UNVERIFIED**.)

**Lesson.** Java's fix was: immutable bindings, lexically-bounded lifetime, inheritance only along *structured*
(nested-lifetime) forks, and a hard error on missing. The unresolved part is every unstructured async API.

---

## 8. Go `context.Context`

**Mechanism.** An explicit first parameter carrying cancellation, deadline, and an untyped key→value chain.

```go
func Handle(ctx context.Context, req Req) error {
    ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
    defer cancel()
    return db.QueryContext(ctx, q)
}
```

**Rules** ([pkg.go.dev/context](https://pkg.go.dev/context)): don't store contexts in structs; pass first, named
`ctx`; never pass nil (use `context.TODO`); "Use context Values only for request-scoped data that transits
processes and APIs", not optional parameters; keys should be unexported types to avoid collisions.

**Lookup.** Explicit value; `Value(key)` walks a linked list of parents (dynamic, by key, untyped `any`).

**Cost.** One interface parameter per call (two words). `Value` is O(depth) per lookup. Cancellation registers
goroutines/channels.

**Pain points.**
- **Virality.** "Context should go away for Go 2" (Michal Štrba, 2017): it "spreads like a virus"; every function
  on a possibly-slow path must accept it, so code fills with `context.TODO()`
  ([faiface blog](https://faiface.github.io/post/context-should-go-away-go2/);
  [golang-nuts thread](https://groups.google.com/g/golang-nuts/c/eEDlXAVW9vU)).
- **Untyped values.** `ctx.Value` is "not statically typed at all", needs documentation of keys, collides, and
  lookup over the linked list is slow with many values (same post). Peter Bourgon argues context values hide
  dependencies; at most a request-scoped logger might qualify ([bourgon.org](https://bourgon.org/blog/2016/07/11/context)).
- **Two concerns conflated.** Cancellation and values share one object; Štrba: a solution should "only solve the
  cancelation problem". Go's own later additions confirm the tension: Go 1.21 added `WithoutCancel` (keep
  values, drop cancellation — e.g. for work that must outlive the request) and `AfterFunc`
  ([pkg.go.dev/context](https://pkg.go.dev/context)). That is, "runs later" code needed the *values* but not the
  *deadline*, and the bundle couldn't express it until 2023.
- Counter-position: Go issue #28342 commenters argue virality is an application design flaw, not the package's
  ([golang/go#28342](https://golang.org/issue/28342)). No Go 2 language change ever happened.

**Lesson.** Explicit passing avoids every dynamic-scope bug but buys virality and boilerplate; and an *untyped*
value bag gets the worst of both (implicit dependencies with explicit ceremony).

---

## 9. React Context

**Mechanism.** `createContext(default)`; a provider node in the tree; consumers read the nearest provider above.

```jsx
const Theme = createContext('light');
<Theme value="dark"><Page/></Theme>      // React 19: context object is its own provider
function Button() { const t = use(Theme); ... }   // `use` may be called conditionally
```

**Set / read.** Provider element; `useContext(C)` (top-level only) or React 19 `use(C)` (allowed in `if`/loops)
([useContext](https://react.dev/reference/react/useContext); [use](https://react.dev/reference/react/use)).

**Lookup.** Dynamic over the **component tree** (render-time ancestry), keyed by context object identity.

**Missing value.** The `createContext` default — "only if there is no matching provider above at all". A provider
with *no* `value` prop silently gives `undefined`, not the default (useContext docs).

**Pain points.**
- **Re-render storms.** "React automatically re-renders all the children that use a particular context starting
  from the provider that receives a different `value` ... Skipping re-renders with `memo` does not prevent the
  children receiving fresh context values." A provider passing a fresh object each render re-renders every
  consumer each time; the docs' fix is `useMemo`/`useCallback` on the value (useContext docs).
- **No selectors.** RFC 119 (context selectors, 2019) never shipped; userland `use-context-selector` requires its
  own `createContext` ([marmelab 2024](https://marmelab.com/blog/2024/10/16/usecontextselector-a-faster-usecontext-for-react.html);
  [use-context-selector](https://github.com/jwalton/use-context-selector)). People split one context into many
  ("provider hell") or move to external stores to get granularity.
- **Identity bugs.** Two copies of the context module (symlinks, duplicate packages) mean provider and consumer
  use different objects and the consumer silently sees the default (useContext troubleshooting).
- **A component can't read its own provider**: `use(context)` "does not consider context providers in the
  component from which you're calling" ([use](https://react.dev/reference/react/use)).
- **Renderer boundaries drop context.** Context does not cross React renderers (react-dom → react-three-fiber
  `<Canvas>`); the ecosystem needs `useContextBridge`/`its-fine`, and the React issue is still open
  ([drei useContextBridge](https://drei.docs.pmnd.rs/misc/use-context-bridge);
  [react#13332](https://github.com/facebook/react/issues/13332)).
- **Server Components can't read context** with `use` ([use](https://react.dev/reference/react/use)).
- **Portals are fine**: a portal child "can access the context provided by the parent tree" — React tree, not DOM
  tree ([createPortal](https://react.dev/reference/react-dom/createPortal)).

**Callbacks.** An event handler closes over the value read *during render* (creation-time capture); stale
closures are a well-known React complaint generally (**UNVERIFIED** specific citation).

---

## 10. SwiftUI `@Environment`, `@EnvironmentObject`, `@Entry`; Swift `@TaskLocal`

**Mechanism.** Values flow down the view tree via modifiers; views read by key path or by type.

```swift
extension EnvironmentValues { @Entry var accent: Color = .blue }
Text("Hi").environment(\.accent, .red)
struct V: View { @Environment(\.accent) var accent; @Environment(Model.self) var model; ... }
```

**Lookup.** Dynamic over the view hierarchy; `EnvironmentValues` by key path (always has a default), objects by
**type** (no default).

**Missing value.**
- By key path: the default. With `@Entry`, the default is a *computed getter*, evaluated on every fallback read.
- By type (`@EnvironmentObject`, `@Environment(Model.self)`): **runtime crash** — "No ObservableObject of type X
  found" / "No Observable object of type X found". Apple's docs: if a view asks for an object by type and it isn't
  present, SwiftUI throws; optional declaration returns nil instead
  ([Apple: Environment](https://developer.apple.com/documentation/swiftui/environment);
  [Apple forums 735189](https://developer.apple.com/forums/thread/735189)).

**Pain points.**
- **Crashes in previews and odd launch paths.** Previews crash unless every type-keyed object is injected
  ([Apple forums 744444](https://developer.apple.com/forums/thread/744444)); apps launched in the background
  crash because the App-level `environmentObject` isn't applied
  ([Apple forums 744194](https://developer.apple.com/forums/thread/744194)).
- **Sheets/popovers/new hierarchies.** Long-standing reports that `.sheet` content "creates different view
  hierarchy so `.environmentObject` is not injected"; the workaround is re-injecting in the sheet closure. Apple
  forum replies claim it was fixed in Xcode 12 beta 4, later reports contradict; Mac-only and dismiss-gesture
  variants exist ([SO mirror 59693018](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/59693018/problems-with-environmentobject-in-modalview);
  [SO mirror 67743048](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/67743048/environmentobject-disappearing-when-used-on-modal-sheet);
  [Apple forums 738201](https://developer.apple.com/forums/thread/738201)). Current (iOS 18/26) behaviour for
  sheets is **UNVERIFIED**; community advice remains "inject explicitly".
- **Unstable defaults cause invalidation.** `@Entry var logger = AppLogger()` makes a *new* instance on every
  fallback read; SwiftUI compares environment values, sees a changed reference, and re-evaluates views — "Every
  fallback access returns a new reference". Xcode 27 now warns about this
  ([Nil Coalescing](https://www.nilcoalescing.com/blog/UnstableDefaultEnvironmentValuesInSwiftUI)).
  The same article recommends making must-provide values *optional* because "silently using a default would hide
  an app configuration error" — a default can mask a missing provider.
- **Modifier order** matters: an `.environment` modifier applies only to the view it wraps, so placing it on the
  wrong side of a `.sheet`/`NavigationStack` changes what descendants see ([fatbobman](https://fatbobman.com/en/posts/swiftui-environment-concepts-and-practice/)).

**Swift `@TaskLocal`** (concurrency's dynamic context): declared with a **required default**, bound only with
`$x.withValue(v) { ... }`, inherited by structured children and by `Task {}`, **not** by `Task.detached` or by
work handed to `DispatchQueue`/threads ([Apple TaskLocal](https://developer.apple.com/documentation/swift/tasklocal);
page body didn't render, details from SE-0311 knowledge — **UNVERIFIED** against the page text).

---

## 11. Jetpack Compose `CompositionLocal`

**Mechanism.** Tree-scoped named keys with a default factory; provided by `CompositionLocalProvider`, read with
`.current` inside composables.

```kotlin
val LocalElevations = compositionLocalOf { Elevations() }
CompositionLocalProvider(LocalElevations provides e) { Card() }
@Composable fun Card() { val e = LocalElevations.current }
```

**Lookup.** Dynamic over the Composition, by key object.

**Static vs dynamic locals.** `compositionLocalOf`: changing the value invalidates only readers of `current`.
`staticCompositionLocalOf`: reads are **not tracked**; a change recomposes the *entire* provided `content`; use it
for values "highly unlikely to change" ([Android docs](https://developer.android.com/develop/ui/compose/compositionlocal)).
This is a user-visible performance knob: you choose between per-read tracking cost and whole-subtree
recomposition.

**Google's own warnings** (same page):
- "**CompositionLocal makes a composable's behavior harder to reason about.** As they create implicit
  dependencies, callers of composables that use them need to make sure that a value for every CompositionLocal is
  satisfied."
- "there might be no clear source of truth ... **debugging the app when a problem occurs can be more challenging**"
  — mitigated by Find Usages and the Layout Inspector.
- "A CompositionLocal **should have a good default value**." Without one, tests and previews must always provide
  it.
- Avoid for things not "tree-scoped"; the canonical anti-pattern is a screen's `ViewModel` in a local. Prefer
  explicit parameters, inversion of control, or content lambdas.
- Naming convention `Local*` "for better discoverability with auto-complete" — a discoverability crutch
  bolted onto a dynamic mechanism.

**Callbacks.** `.current` is readable only during composition, so an `onClick` lambda captures what was read at
composition (creation-time). Dialogs/popups receive parent locals through the parent `CompositionContext`
(**UNVERIFIED** against docs this session); interop roots (a `ComposeView` hosted in a View) start from defaults
(**UNVERIFIED**).

---

## 12. Flutter `InheritedWidget` / Provider

**Mechanism.** `context.dependOnInheritedWidgetOfExactType<T>()` (wrapped as `Theme.of(context)`,
`context.watch<T>()`) walks up the *element* tree from a `BuildContext` and registers a rebuild dependency.

```dart
final theme = Theme.of(context);
ChangeNotifierProvider(create: (_) => Cart(), child: App());
context.read<Cart>().add(item);
```

**Lookup.** Dynamic over the element tree, **by type**. Missing → `ProviderNotFoundException` (runtime) for
Provider; `Theme.of` falls back to a default.

**Pain points.**
- **BuildContext across async gaps.** A `BuildContext` used after `await` may belong to an unmounted element;
  the analyzer ships `use_build_context_synchronously`, requiring a `mounted` check, because storing a context
  across a gap "can lead to difficult-to-diagnose crashes" ([Dart lint](https://dart.dev/tools/diagnostics/use_build_context_synchronously)).
  The lint misses `.then()`/`catchError` callbacks ([linter #4923](https://github.com/dart-lang/linter/issues/4923)).
  This is "the context is a *location*, and the location can die before the callback runs".
- **Routes and dialogs are not children.** `showDialog`/`Navigator.push` build under the Navigator, so providers
  from the caller's subtree are not found → `ProviderNotFoundException`; fixes are re-providing with
  `.value`, or hoisting providers above `MaterialApp`
  ([SO mirror 57968453](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/57968453/how-to-access-provider-providers-in-dialogs-in-flutter);
  [SO mirror 60138448](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/60138448/unable-to-access-provider-in-new-page-route-widget)).
- **Themes captured explicitly.** Flutter added `InheritedTheme.capture(from:, to:)` precisely because route
  content "built in one context but shown elsewhere" otherwise loses the themes in effect where it was built
  ([InheritedTheme](https://api.flutter.dev/flutter/widgets/InheritedTheme-class.html)). So Flutter offers an
  explicit **creation-site capture** primitive as a patch on a **draw-site** lookup.
- **Wrong context object.** The `context` passed to a builder above the provider can't see it (needs a
  `Builder`); `dependOn...` is illegal in `initState`. Riverpod was created largely to escape BuildContext-keyed
  lookup and runtime not-found errors ([Riverpod scopes doc](https://docs-v2.riverpod.dev/docs/concepts/scopes);
  motivation **UNVERIFIED** as a quote).

---

## 13. Algebraic effects: Koka, OCaml 5, Unison

**Mechanism.** A computation *performs* an operation; the nearest enclosing *handler* answers it. A "reader"
effect (`ask : () -> Env`) is exactly an implicit context.

```koka
effect ask<a> { fun ask() : a }
fun greet() : ask<string> string { "hello " ++ ask() }
with handler { fun ask() "world" } greet()
```

**Lookup.** Conventionally **dynamic** — "the dynamically closest enclosing handler is chosen"
([Lexa, OOPSLA 2024](https://cs.uwaterloo.ca/~yizhou/papers/lexa-oopsla2024.pdf)). Koka types it: the effect
row in the signature (`ask<string>`) makes the requirement visible and checked; unhandled is a compile error.

**Cost.** Koka compiles via *evidence passing*: handlers become an evidence vector passed like a parameter, and
static effect types let lookup be constant-time rather than a linear stack search
([Xie & Leijen, ICFP 2021](https://www.microsoft.com/en-us/research/uploads/prod/2021/08/genev-icfp21.pdf);
[Collège de France abstract](https://www.college-de-france.fr/en/agenda/seminar/control-structures-from-goto-to-algebraic-effects/design-and-compilation-of-efficient-effect-handlers-in-the-koka-language)).
A tail-resumptive operation like `ask` costs about a function call (**UNVERIFIED** exact claim). OCaml 5 is
untyped and searches the handler stack at runtime.

**Pain points.**
- **Closures created under one handler and called under another.** OCaml users report that an effect performed
  inside a closure is handled by whatever handler is on the stack *when called*, not where the closure was
  written; a commenter: "I don't see OCaml changing in this regard"; effects are "an unsafe, limited, form of
  delimited control intended for writers of concurrency libraries". The 2026 `affect` library makes call
  handlers inherited by child async calls as a workaround
  ([discuss.ocaml.org thread](https://discuss.ocaml.org/t/effect-composability-actual-callstack-vs-syntactic-scope/17536)).
- **Escaping continuations** need dynamic-wind work (SLE 2026 paper) — resumption after the handler's scope
  ended is its own class of bugs ([SLE 2026](https://conf.researchr.org/details/sle-2026/sle-2026/14/Dynamic-Wind-for-OCaml-Effect-Handlers-with-Escaping-Continuation-Support)).
- **Lexical handlers** (Lexa; Effekt's capability-passing) treat a handler as a capability that only code in its
  lexical scope or code *passed* the capability can use — fixing accidental handling at the cost of explicitness
  (Lexa paper). This is the research community's own "dynamic was wrong for closures" verdict.
- **Unison** keeps abilities on *function types* only: a value can't carry an unhandled ability, so deferred
  work is a thunk `'{IO} a` whose type still lists the ability, and the handler is chosen when it is forced
  ([Unison delayed computations](https://www.unison-lang.org/docs/language-reference/delayed-computations);
  [abilities intro](https://unison-lang.org/docs/fundamentals/abilities)). That makes "runs later" *visible in the
  type* rather than resolving it silently.

**Lesson.** Typing the requirement (Koka/Unison) makes a missing context a compile error and makes deferral
visible; it does not by itself decide *which* handler a closure sees.

---

## 14. Zig and Rust: the deliberate "no", and Rust's proposals

**Zig.** No hidden allocations, no hidden control flow: allocation is "always exposed to the API by the function
that is ultimately calling for the memory"; the std library cannot allocate unless handed an allocator
([Wikipedia: Zig](https://en.wikipedia.org/wiki/Zig_(programming_language));
[openmymind: heap memory](https://openmymind.net/learning_zig/heap_memory)). The allocator parameter is the
*signal* that a function allocates. Cost: allocator-parameter virality — the Go-context complaint applied to
memory (community sentiment; **UNVERIFIED** as a single citation). A Ziggit thread notes the principle is
incomplete (syscalls aren't marked) ([Ziggit](https://ziggit.dev/t/syscall-marker/3342)).

**Rust.** No implicit context; thread-locals and explicit params. Tyler Mandry's "Contexts and capabilities in
Rust" (Dec 2021) proposed:

```rust
capability alloc: Allocator;
fn deserialize(...) with alloc { ... }               // requires context
with alloc = &arena { load_all() }                   // provides context
impl Deserialize for &Foo with arena::basic_arena { ... }
```

- Missing context "will result in a compiler error"; it "compiles down to the code you would write anyway"
  (ordinary arguments after monomorphization)
  ([tmandry blog](https://tmandry.gitlab.io/blog/posts/2021-12-21-context-capabilities/)).
- The motivating case is **context-dependent impls** — a trait impl that needs an arena the trait knows nothing
  about. Consequence: "trait bounds can no longer be taken to be global facts"
  ([nadrieril 2026](https://nadrieril.github.io/blog/2026/03/22/what-if-traits-carried-values.html)).
- **Closures/threads are the hard part**: a context value may not be `Send`/`'static`, so a spawned closure
  can't use it; the post invents *scoped bounds* `where with('static + Send) T: Deserialize`.
- Thread-locals were rejected as the answer: can't hold stack values, skip destructors, don't carry into work on
  other threads (same post).
- Open: `dyn` trait objects. Status: "nobody is actively working on the design", prioritization
  ([Yoshua Wuyts 2023](https://blog.yoshuawuyts.com/capabilities-1); [initiative charter](https://nikomatsakis.github.io/context-capabilities-initiative/CHARTER.html)).
  Commenters objected to calling them "capabilities" (real capabilities are unforgeable)
  ([internals thread](https://internals.rust-lang.org/t/blog-post-contexts-and-capabilities-in-rust/15833)).

---

## 15. Also relevant: Python `contextvars`

Not requested, but the cleanest 2026 data point on "runs later": Python 3.14 added
`sys.flags.thread_inherit_context` (default 1 on free-threaded builds, 0 on GIL builds). `ThreadPoolExecutor`
starts workers lazily inside `submit()`, so "a pool worker permanently captures whatever context was active at
whichever `submit()` call happened to create it" — behaviour depends on pool warmth; surfaced as
pytest-dev/pytest#14077. A 2018 fix was rejected for symmetry with process pools
([discuss.python.org](https://discuss.python.org/t/make-threadpoolexecutor-propagate-context-at-submit-time/108274)).
`asyncio` tasks copy the context at task creation (**UNVERIFIED** this session; well-known).

---

# Synthesis

## A. Dynamic scope vs lexical/static resolution

| Failure mode | Belongs to | Evidence |
|---|---|---|
| Missing provider found only at runtime (crash or silent default) | dynamic | SwiftUI type-keyed objects, Flutter `ProviderNotFoundException`, Java `get()`, React default/undefined |
| Deferred code sees a different value than its author meant | dynamic | Clojure lazy seqs, OCaml effects in closures, Lisp threads, Python pools |
| "Where did this value come from?" | dynamic (tree walk) | Compose docs; React DevTools troubleshooting |
| Ambiguity / overload churn | static, by type | Kotlin 2.3.20 ambiguity, Scala ambiguous givens |
| Cryptic errors fixed by an import | static, with import-driven scope | Scala 2 critique #2 |
| Scope pollution | static, receiver-style | Kotlin context receivers (dropped) |
| Semantics depend on inference/generalisation | static by constraint, dynamic value | Haskell `?x` + MR |
| Virality / boilerplate | explicit | Go, Zig |
| Context-dependent trait impls | static | Rust proposal; Haskell forbids `?x` in instances |

Key observation: **static resolution moves failures to compile time but creates resolution ambiguity**, which is
worse when keyed *by type* (two `Logger`s). **By-name keys** (Odin field, Java/Compose key object) avoid
ambiguity. Kotlin's fix — name every context parameter — is the convergent answer.

Odin/Jai show a third option: a **hidden parameter whose value is dynamic** (whatever the caller held). It is
cheap and thread-safe (no TLS), but has dynamic scope's deferral problems wherever code is not called directly
(C callbacks, threads, WASM entry points).

## B. The "runs later" problem

| System | Closure / callback | Spawned task/thread | Lazy | Async gap |
|---|---|---|---|---|
| Odin / Jai | value at call (hidden param) | new context (`init_context` / per-thread) | n/a | n/a |
| Scala / Kotlin params | lexical capture at creation (it's a variable) | captured like any variable | captured | captured |
| Kotlin callable refs | resolved **at creation** (KEEP) | — | — | — |
| Haskell `?x` | depends on whether the binding generalises | — | — | — |
| Clojure binding | **call time** (var read) | conveyed by `future`/`pmap`/`go`, not `Thread.` | call time → root value | — |
| Common Lisp | call time | **none** unless `*default-special-bindings*` | — | — |
| Java ScopedValue | call time | inherited only via `StructuredTaskScope` | — | — |
| Swift TaskLocal | call time within task | `Task{}` yes, `detached` no | — | — |
| Python contextvars | call time | pools: whichever submit created the worker | — | tasks snapshot at creation (UNVERIFIED) |
| React / Compose | value read at render/composition, captured by the handler | — | — | stale closure |
| Flutter | `BuildContext` captured, looked up at use | — | — | crash if unmounted (`mounted` lint) |
| OCaml effects | **call time** (handler on stack) | — | — | — |

**Which choice produced bugs:** every *call-time* system grew bugs at each deferral seam (Clojure lazy seqs, CL
threads, OCaml closures, Python pools), and each patched the seams one API at a time (Clojure conveyance in some
APIs; Java only for structured forks; Swift not for detached; Python opt-in flags). Creation-time capture
(lexical systems, React/Compose handlers) produced *staleness* bugs — the value is fixed but may be outdated —
and Flutter's hybrid (capture the location, look up later) produced the worst: crashes when the location dies.
The working rule that survived in Java and Swift: **inherit along structured (nested-lifetime) spawns; make
unstructured spawns explicit.**

## C. "Built here, drawn there" in UI trees

| Framework | Rule | What breaks |
|---|---|---|
| React | **logical (React) tree**, i.e. where the element is rendered; portals keep it | renderer boundaries (`<Canvas>`), Server Components, duplicated context modules |
| SwiftUI | view hierarchy where presented; `.sheet` etc. historically a separate hierarchy | sheets/popovers lose `@EnvironmentObject`; App-level injection missing on background launch |
| Compose | composition ancestry; dialogs/popups via parent `CompositionContext` (UNVERIFIED) | interop roots (UNVERIFIED) |
| Flutter | **element tree at the draw site**; routes/dialogs hang under Navigator | providers not found in dialogs/routes; `InheritedTheme.capture` exists to restore creation-site themes |

React's choice (logical parent, independent of physical placement) has the fewest complaints. Flutter's
draw-site lookup produced an entire FAQ genre and a capture API. Note that a child *constructed* inside one
provider and *passed as a prop* to render under another sees the **render-site** provider in React (element
descriptions are inert until rendered) — usually what users want for theme, sometimes not (**UNVERIFIED** as a
documented complaint).

## D. Function values, dynamic dispatch, FFI

- **Function types must say whether they carry context.** Kotlin: `context(A) () -> B` is a distinct type, and
  context is inferred into lambdas only when that type is expected; callable references resolve context eagerly.
  Scala: `A ?=> B`. Unison: abilities on arrows. Odin/Jai: the calling convention *is* the context flag
  (`"c"`/`#c_call` = none).
- **Interfaces/trait impls.** Haskell forbids `?x` in instances; Rust's proposal makes it the central feature and
  discovers that bounds stop being global facts and that `dyn` is unresolved. A vtable method can't add a context
  requirement its interface lacks unless the context is ambient (dynamic) or the interface is generic over it.
- **FFI/C callbacks.** Every hidden-parameter design (Odin, Jai) loses context at C callbacks and falls back to
  *defaults*, not the caller's values; the recommended fix is userdata (`user_ptr`). TLS-based designs survive C
  callbacks on the same thread but not callbacks on foreign threads.

## E. Missing value

| Choice | Systems | Regret |
|---|---|---|
| Default | React, Compose (recommended), Odin, Swift `EnvironmentValues`, `@TaskLocal` | Silent wrong value: React's `undefined` from a provider without `value`; Nil Coalescing recommends optionals because a default "would hide an app configuration error"; unstable default instances cause invalidation |
| Compile error | Scala, Kotlin, Haskell, Koka, Rust proposal | Ambiguity errors, import-dependent errors (Scala 2), overload churn (Kotlin) |
| Runtime throw | SwiftUI type-keyed, Flutter Provider, Java `get()` | Crashes in previews, background launch, sheets; Google's Compose guidance exists to avoid this |

Pattern: **defaults are right for ambient policy** (theme, locale, logger, allocator) and **wrong for resources
with identity** (a DB handle, a ViewModel) — Compose's guidance says exactly this. Defaults that *allocate* must be
singletons.

## F. Discoverability ("spooky action")

What helped: marking at the **declaration** (Kotlin `context(...)`, Scala `using`, Koka effect rows); marking at
**call sites** when explicit (Scala 3 `(using x)`, Kotlin explicit context arguments); **naming conventions**
(`Local*` in Compose); **given-only imports** (Scala 3); **tooling** (Compose Layout Inspector, React DevTools);
**lints** (Flutter `use_build_context_synchronously`, Xcode 27's unstable-default warning).

What did not: one keyword for many mechanisms (Scala 2); members injected into scope (Kotlin receivers); untyped
key bags (Go `Value`, Odin `user_ptr`); a hidden parameter with no marking either way (Odin's refusal of
"contextless" annotations means signatures never say what is read).

## G. Performance

| Who pays | Where | Evidence |
|---|---|---|
| Every call | one hidden pointer argument | Odin, Jai (plus stack-trace node per call in Jai by default) |
| Readers only | extra ordinary parameter | Scala, Kotlin (JVM leading params), Rust proposal "code you would write anyway" |
| Reads | linked-list walk | Go `Value` — "slow, especially with many values" |
| Spawns | map copy per child | Java `InheritableThreadLocal` (fixed by sharing in ScopedValue) |
| Suspend/resume | context save/restore | Kotlin `ThreadContextElement` fix "impacts suspend/resume performance" |
| UI subtrees | re-renders | React (all consumers, `memo` doesn't help), Compose static locals recompose whole content, SwiftUI unstable defaults |
| Compiler | implicit search | Scala (UNVERIFIED numbers) |

The measurable damage in practice is in **UI invalidation granularity**, not call overhead: React's missing
selectors and Compose's static/dynamic trade-off are the cost stories. In systems languages the cost argument is
about the always-on pointer (Odin) vs pay-for-use parameters (Scala/Kotlin/Rust proposal).

---

# Ten lessons, ranked

1. **Resolve statically and key by name, not type** — two values of one type become ambiguity errors (Kotlin 2.3.20, Scala givens; Kotlin's receiver→named-parameter redesign).
2. **Decide deferral semantics in the type system, not per API** — call-time lookup broke at every seam and was patched one API at a time (Clojure lazy/conveyance, Python pools, OCaml closures).
3. **Inherit context only along structured (nested-lifetime) spawns; make detached work explicit** (Java ScopedValue + StructuredTaskScope, Swift `Task.detached`).
4. **Bindings are immutable and block-scoped; rebinding only in a nested block** — mutable TLS leaked and was untraceable (Java ThreadLocal → ScopedValue; Odin copy-on-write confusion).
5. **Default for ambient policy, compile error for resources with identity; never a runtime crash** (Compose guidance vs SwiftUI/Flutter crashes; Nil Coalescing on defaults hiding misconfiguration).
6. **Function types must carry the context requirement, and FFI boundaries must be a typed seam with an explicit hand-off** (Kotlin `context(A) () -> B`; Odin/Jai C callbacks silently falling back to defaults).
7. **UI context follows the logical tree, not the draw site** (React portals work; Flutter needed `InheritedTheme.capture`; SwiftUI sheets lost objects).
8. **Pay only where read: no always-on hidden pointer, no whole-subtree invalidation; track reads per value** (Odin's per-call pointer, React's all-consumers re-render, Compose static locals).
9. **Separate cancellation/deadlines from values** — Go needed `WithoutCancel` to recover values without the deadline (Go context).
10. **One mechanism, one keyword, visible at declaration; no context injected via imports or receivers** (Scala 2 critique; Kotlin receivers dropped).
