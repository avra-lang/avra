# Binding and sharing — `let`, `mut`, `state`, `once`, and the `ambient` seat

> **Superseded for events (2026-10-05).** A handler is a closure now:
> `on click { … }` fills a fn-typed field and the frame keeps it;
> `@derive(Messages)`, sites and the payload wire are gone. An app that
> wants one `update` writes `on click { update(.Toggle(t.id)) }`. The
> `Msg` samples below are the design as it stood.

> 2026-10-04. Base `3137b8f`. This doc fixes the vocabulary the owner
> has been driving and then takes it OUTSIDE the UI: servers,
> services, models, robotics, and the distributed case. It is written
> in code, not prose. Every claim carries a probe or is named an ask.
>
> **Status of the five decisions: SETTLED.** They are recorded here,
> not re-litigated. What is OPEN is marked `OPEN` inline and collected
> in §8. Asks are filed in §9.
>
> Probes were run with this worktree's gen-2 compiler
> (`make bootstrap`, commit `3137b8f`) as
> `build/avra check <file>` from `/tmp/avra-probe`, never inside a
> package tree. A seeded binary predates the providers feature and
> answers these spellings with parse errors; the generation is named
> with every probe that could rot.

---

## 0. The one-line model

> **A binding names either a VALUE (copied) or a PLACE (shared by
> identity).** `let` and `mut` are values; `state` is a place;
> `once` is a lifetime; `provide`/`env` are deleted.

| construct | is | identity | capture | scope | lifetime |
|---|---|---|---|---|---|
| `let x` | a value | no | copies | lexical | frame |
| `mut x` | a value you may reassign | no | copies | lexical | frame |
| `state x` | a **place** (a `Cell<T>`) | yes | shares | module: app-wide / component: per-instance / seat: caller's | its owner's |
| `once fn` | a **lifetime** (one value per process) | yes, but immutable | n/a | process | process |
| `ambient x` | a **seat** filled by name from the caller | n/a (a seat) | n/a | call | call |

`let`, `mut`, `state` are the three binding words. `once` is an
orthogonal modifier on a declaration (it says WHEN, not WHERE).
`ambient` is a seat mark (it says HOW a parameter is filled).

---

## 1. The five decisions

### 1.1 `let` stays: a VALUE. A capture copies.

```avra
fn outer() -> int {
    let n: int = 0
    let f = () -> n
    f()
}
outer()
```

`let` is a copy, and a lambda that names it captures a copy.

### 1.2 `mut` stays: a value you may reassign, frame-local, captures copy.

The shared-value trap is refused loudly:

```avra
fn counter() -> fn() -> int {
    mut n: int = 0
    () -> {
        n = n + 1        // error[resolve.immutable]
        n
    }
}
```

```
error[resolve.immutable]: `n` is captured by value — a lambda cannot assign to it
help: a capture is a copy: bind a `mut` inside the lambda, or answer the new value and let the caller keep it
```

And even a capture that only READS the `mut` sees a snapshot:

```avra
fn outer() -> int {
    mut n: int = 0
    let f = () -> n
    n = 5
    f()
}
outer()
```

```
0
```

That `0` is the whole reason §3 cannot fold `state` into `mut`.

### 1.3 `state` stays: a SHARED PLACE (identity). It IS `Cell<T>`.

`state n` reads as `n: T` and writes as `n = v`; under the hood the
binding holds a `Cell<T>` (`state_held(s) = cell_inner(def_type(s))`,
`compiler/typing/typing.av`). The read is a load, the write is a store,
and a capture shares the cell:

```avra
fn outer() -> int {
    state n: int = 0
    let f = () -> n
    n = 5
    f()
}
outer()
```

```
5
```

The same `mut`/`state` pair, with the lambda WRITING, separates cleanly:
a captured `mut` is F3005, a captured `state` runs.

```avra
fn counter() -> fn() -> int {
    state n: int = 0
    () -> {
        n = n + 1
        n
    }
}
let c = counter()
c() + c() + c()
```

```
6
```

Scopes, all landed:

```avra
// module scope: one place the whole app shares
state filter: string = "all"

// a `state` SEAT: the CALLER's place (landed, #234)
fn stepper(state n: int) { n = n + 1 }

// component scope: one place per INSTANCE — NOT landed (see the correction)
```

> **Probe correction (2026-10-05, `982c405` + the ui-instance branch).** A
> component body cannot seed a place: `component C { state n: int = 0 }` is
> `error[build.failed]` "a component holds its fields and its `fn`s, and
> nothing else", and a component head takes no seat mark
> (`component C(state n: int)` is a parse error at the `(`). Per-instance
> state in a PLAIN `type` record DOES land (`type R = { state n: int = 0 }`;
> two `R {}` copies are independent), and a plain component field is
> independent per instance but is a VALUE, so a handler capture copies it.
> AND a `state` SEAT is not SHARED into a closure: a lambda capturing a
> state seat is `error[resolve.immutable]` "captured by value", because
> `capture_regs` packs a `state` BINDING's Cell and never a `.Param`'s. So a
> shared top-level handler driven by a serialised event reaches a
> per-instance place only through a serialisable KEY, never by capturing
> it.

### 1.4 `once` stays, untouched: a different axis (LIFETIME).

`once fn` is one value for the whole process. Nothing here touches it.

```avra
once fn painted() -> string { compute_expensive_color() }
fn read() -> string { painted() }
```

The answer must be a value the runtime owns; a one-field scalar record
flattens and is refused:

```avra
type Env = { dark: bool }
once fn env_of() -> Env { Env { dark: false } }
```

```
error[type.once_fn]: `once fn env_of` answers `Env`, which the runtime cannot keep
help: a `once` value is one the runtime owns — a string, a list, a map, an enum, or a record wider than one scalar field
```

### 1.5 `provide` and `env T` ARE DELETED.

Landed: the feature, its grammar, its two typing/lowering stacks and
its `type.provider` voice are gone; `env T` and `provide x: T = v`
refuse at parse, and `env`/`provide` are ordinary names again.

`env T` invents a SECOND lookup rule (by TYPE) when every other name in
the language resolves by NAME; it needs a bespoke scope stack duplicated
in typing AND lowering; it hides dependencies; and its two keywords
encode ONE flag. The owner: *"it's all such a fucking mess."*

The probe that settles it — a `provide` does not flow into a `fn` body
at all, while an ordinary declaration does:

```avra
type Theme = { dense: bool }
provide theme: Theme = Theme { dense: true }
fn read_theme() -> bool { (env Theme).dense }
```

```
error[type.provider]: no `Theme` is provided above this `env`
help: add `provide x: Theme = …` above it
```

```
type Theme = { dense: bool }
provide theme: Theme = Theme { dense: true }
env Theme.dense
```

```
(exit 0)
```

So a `provide` is scoped to the statement list it stands in and does
NOT reach a declaration's body, while a top-level `state`/`const`
does. **A type-keyed environment is strictly weaker than the lexical
rule the rest of the language already uses.** Ambience must be name
lookup.

---

## 2. The rejected alternative: folding `state` into `mut`

The owner considered making `mut` an identity and rejected it. The
reason is observable, and the probes in §1 are the receipt:

- A `Cell` is a heap box with a header and a refcount; a local is a
  register. The difference is not an implementation detail — it is
  exactly whether a capture shares.
- §1.2 and §1.3 print `0` and `5` for the SAME program with `mut`
  and `state`. Making `mut` an identity would have to keep locals in
  registers for the common case and only box the escaping ones —
  escape analysis, which is real work and a subtle source of the
  memory bugs this tree has a documented history of.
- The complexity is real, not hypothetical: TWO bugs landed in the
  `state` seat machinery in one night, both about identity crossing a
  call boundary (`#242` fixed; `avra-2fkh` still open). Both were
  invisible until a different consumer — a second call path, a
  backend — read them. Hiding the difference does not remove it.

Verdict: **keep three words.** `mut` is a value, `state` is a place,
and the compiler says which.

---

## 3. Ambience: the `ambient` seat mark

### 3.1 The spelling

```avra
component text(content: string, ambient env: Env = Env.default) { … }
```

- Filled from the **caller's scope by NAME** — the ordinary lexical
  lookup. No new rule, no type-keyed stack.
- **Per-call overridable**: `text("Hi", env: dark_env)`.
- It appears in the **signature**, so the dependency is visible,
  documented, testable — the real objection to `provide`/`env`, solved.
- A **default** makes it optional, so a library component is not a tax
  on an app that ignores it.

**A SEAT, not an annotation.** A seat is overridable, appears in the
type, and is the same shape as `mut` — one concept, not a new
declaration form.

### 3.2 Supply is a binding in scope

No `provide`. The app has the value in scope and children read it by
name:

```avra
type Env = { theme: Theme, density: Density, direction: Direction }

// supply: one binding, at whatever scope owns the app
state env: Env = Env { theme: default_theme, density: .Comfortable, direction: .Ltr }
```

A subtree override is a binding in that block — nearest wins, for
free, because it is the same scope walk:

```avra
fn panel() {
    let env = env with { density: .Compact }   // read the outer place, shadow it here
    text("dense panel")                         // the ambient seat fills from THIS `env`
}
```

> **Probe correction (2026-10-04).** The design first wrote the supply
> as `mut env: Env = …` at module scope. A top-level `let`/`mut` is a
> RUNTIME binding, and a fn body cannot see it:
>
> ```avra
> mut env: Env = Env { dark: false }
> fn read() -> bool { env.dark }
> ```
> ```
> error[resolve.runtime_binding]: `env` is a run-time binding of the top level
> help: pass `env` in as a parameter, or make it a fn
> ```
>
> The supply that a fn body CAN read is a top-level `const env: Env`
> or `state env: Env` — both are DECLARATIONS. `state` is the natural
> supply when the subtree may write it; `const` when it may not. This
> is not a flaw in the model; it is the const law telling us the
> supply is a declaration-shaped thing, which `state` already is.
> `with` and the shadow override both compile (probed, exit 0).

### 3.3 The three shapes of a shared need

The library/app split decides which shape a need takes.

```avra
// 1. the library OWNS the type -> a value seat with a default. No trait.
component panel(ambient env: Env = Env.default) { … }

// 2. the APP supplies its OWN type -> a `dyn Trait` seat, which already works
type Route = { path: string }
trait Navigator { fn navigate(to: Route) }
component link_row(label: string, nav: dyn Navigator) { … }
fn drive(n: dyn Navigator, r: Route) { n.navigate(r) }

// 3. a capability -> a function value, the cheapest door
fn noop() { }
component dialog(title: string, ambient dismiss: fn() -> void = noop) { … }
```

`dyn Trait` as a seat is landed — a free-fn seat and a component HEAD
seat both compile (probed, exit 0). A fn-valued seat with a default
compiles in a free fn's parameter list.

> **The rule, one sentence:** *a trait is for "give me something of
> YOUR type that does X"; a value is for "give me a value of MY type".*

### 3.4 Extensibility without type-keying

You add a SEAT, not a field, not an injection. A plugin that needs its
own ambient value declares it; the app has one in scope under that
name. Different name, different type, no collision, no "only one
`Theme` allowed":

```avra
type Registry = { verbs: List<string> }
component plugin_host(ambient registry: Registry = Registry { verbs: [] }) { … }
```

Two plugins each declare their own `ambient billing: Billing` and
`ambient analytics: Analytics`; neither can collide with `env`, because
the key is the NAME. This is the exact thing `env V` cannot do.

### 3.5 What is refused today

```avra
type Env = { dark: bool }
component text(content: string, ambient env: Env = Env { dark: false }) { x: int = 0 }
```

```
error[parse.expected]: expected `{` while parsing `stmt`
   ╰── at the `(`
```

and on a free fn:

```avra
fn f(ambient env: Env = Env { dark: false }) -> bool { env.dark }
```

```
error[parse.expected]: expected `)` while parsing `stmt`
   ╰── at the `(`
```

So the `ambient` mark itself is an ask (no soft keyword, no mark in the
seat grammar). AND the default on a component HEAD seat is a separate
ask — the component head grammar takes no `= expr` today:

```avra
type Env = { dark: bool }
component text(content: string, env: Env = Env { dark: false }) { x: int = 0 }
```

```
error[parse.expected]: expected `{` while parsing `stmt`
```

(A seat default lands on a `fn`/`mut fn`/`static fn` seat and nowhere
else today; a component head is a different construct.) The `ambient`
ask must carry both.

### 3.6 The board, rewritten onto `ambient env`

This is the design judged against a real program. Per-item actions
(`on click { … }`), the `ambient env` seat, `state` for the app's
places, module-scope `const`/`state` for supply. The parts that are
asks are marked; the board itself is `tools/ui-board`.

```avra
use @std.meta.{derive}
use @std.ui.{heading, column, row, list, item, field, button, checkbox, text}
use @std.ui.realize.messages.{Messages}
use @std.ui.realize.view.{View}
use @std.ui.style.theme.{Theme, default_theme}
use @std.ui.a11y.name.{Name}

type Todo = { id: int, title: string, done: bool }
enum Filter { All, Active, Done }

// ── the app's PLACES (identity, per process) ────────────────────
state todos: List<Todo> = []
state draft: string = ""
state filter: Filter = .All

// ── the environment, a `const` (immutable) or `state` (writable) ─
const env: Env = Env { theme: default_theme, density: .Comfortable }

// ── messages: one variant per event, carrying its captures ──────
@derive(Messages)
enum Msg {
    Add
    Toggle(id: int)
    Delete(id: int)
    SetFilter(which: Filter)
    Draft(text: string)
}

fn update(m: Msg) {
    match m {
        .Add -> add()
        .Toggle(id) -> toggle(id)
        .Delete(id) -> remove(id)
        .SetFilter(f) -> filter = f        // writes the global place
        .Draft(text) -> draft = text
    }
}

fn board_view() -> column {
    column {
        heading "Tasks"
        row {
            field "New task" {
                value: draft
                on_input: Msg.Draft(it)             // gap 3
            }
            button "Add" { on_click: Msg.Add }
        }
        row {
            button "All"   { on_click: Msg.SetFilter(.All) }
            button "Active"{ on_click: Msg.SetFilter(.Active) }
            button "Done"  { on_click: Msg.SetFilter(.Done) }
        }
        list visible by it.id {                     // gap 4
            t -> item {
                key: "${t.id}"
                checkbox t.title {
                    checked: t.done
                    on click { t.done = !t.done }    // gap 2 — per-ITEM action
                    a11y: Name { label: "Mark ${t.title} done" }
                }
                button "x" {
                    on click { remove(t.id) }        // gap 2
                    a11y: Name { label: "Delete ${t.title}" }
                }
            }
        }
    }
}

// a themed subtree overrides the supply for its own block
fn compact_toolbar() -> row {
    let env = env with { density: .Compact }   // nearest wins at the call site
    row { button "All" { on_click: Msg.SetFilter(.All) } }
}
```

The board compiles today ONLY with the floor spellings (the board doc
lists each); the `ambient env` seat is not one of them yet. What this
shows is the SHAPE the language is being asked to read: `state` for the
app's places, one `env` binding for ambience, seats filled by name,
per-item `on click { }` lifted to typed messages.

---

## 4. Outside the UI

The question the owner asked, verbatim: *"I want to see and explore how
this will look outside of the UI components. For things like servers,
services, models, robotics, stuff, distributed computing. eg if we
change the state on one machine, could it change it somewhere else too
as a feature, etc."*

The vocabulary does not change. `state` is a place; `once` is a
lifetime; `ambient` is a fill-by-name seat; `let`/`mut` are values.

### 4.1 Servers — one process, many requests

Where does per-request state live vs server state?

```avra
use @std.http.route.{get}
use @std.http.server.{server}

// a PLACE, declared: every request reads and writes the SAME one
state hits: int = 0

export server site {
    port: 8080
    // per-request state is a LOCAL in the handler's frame; `hits` is the place
    get "/hit" { _req ->
        let n = hits            // read the shared place
        hits = n + 1            // write it — `state` is visible to the handler
        "${n}"
    }
}

let _ = site.run()
```

(The `server`/`route`/`run` shapes are `@std/http`'s, from
`docs/2026_10_01_HTTP_TOUR.md`; the counter is the model. `state hits`
is read and written by name from the handler — probed: a module-scope
`state` is visible to fn bodies and a lambda reads and writes it,
§1.3.)

**Per-request vs server state, named:** a handler's `let`/`mut` is
that request's (a copy, discarded at the frame's end); a `state` in
scope is the server's; a `once fn` is the process's.

**The honest concurrency story.** The runtime is M:1 cooperative fibers
(`docs/2026_09_22_FIBERS_DESIGN.md` §12): a fiber switches only at a
yield point (`.await`, a parking I/O row, `sleep`), never at an
arbitrary instruction. So a `Cell` written by a handler between two
parks is safe WITHOUT a lock — a plain increment cannot be half-done.
This is the same guarantee a UI event loop gives, one process wide.

**But `@std/http` serves on every core, and a core is a PROCESS that
shares nothing** (fibers §13). The server takes a MAKER, run once per
core:

```avra
served(l, () -> App { hits: Cell.new(0) }, …)   // one Cell PER CORE
```

Its seat is `isolated`; F2111 refuses a maker lambda that captures an
identity. So `state` today is **per process, and with `run()` per
CORE**. A counter like the one above counts per core, not per cluster.
That is a design choice, not a bug (P6: the thread-vs-process choice
dissolves once nothing is shared), and it is exactly the gap the
distributed wrapper (§4.5) closes.

`OPEN`: what a handler does when it needs a genuinely process-wide
mutable value across cores. Today: `once` (immutable), or nothing.
`Shared<T>`/atomics is a recorded later slice (fibers §13).

### 4.2 Services — long lives, process identities, capabilities

```avra
type Db = { pool: Pool }              // the service's own state

once fn pool() -> Pool { Pool.open(config()) }      // ONE per process
state jobs: List<Job> = []                           // the service's mutable queue

// capabilities ride `ambient`, filled by name from the caller
trait Metrics { fn count(name: string) }
component worker(ambient metrics: dyn Metrics, ambient db: Db = pool()) { … }
```

Three axes, cleanly separated:
- `once` — what is genuinely process-wide and immutable (a pool, a
  config);
- `state` — the service's own mutable places;
- `ambient` — its capabilities (a db handle, an http client, a metrics
  sink), visible in the signature.
`OPEN`: a service that wants a process-wide MUTABLE table (the sqlite
handle table, `avra-8sb5.10.5`) still has no door; `once` is
immutable and `state` is per core.

### 4.3 Models — `state` : process :: a relation : the program

The suggested framing: both are PLACES. One is in-memory and
process-local; the other is durable, content-addressed and incremental.
`@model` generates one from the other.

```avra
use @std.db.{model}

@model
type User = {
    id: int = 0,
    @unique email: string,
    name: string,
}

// in-memory place: this process, right now
state users: List<User> = []

// durable place: the row IS the schema; CRUD is derived from the record
fn save(mut db: Db, u: User) -> Result<User, ModelError> { u.insert(db) }
```

`@model` + `state` compile together (probed in a scratch package, exit 0;
warnings only). `@model` reads the type's fields to answer the DDL and
typed CRUD — one source of truth.

The framing holds, and it names a real want:

- `state` is a place whose value is a `T`; a `@model` table is a place
  whose "value" is a SET of `T`, keyed, durable, incremental. Both read
  and write; one forgets at exit, one does not.
- `@model` should GENERATE the in-memory `state` from the durable one
  (or vice versa): the same declaration, two projections. Today they
  are written twice. That is `OPEN` (the ORM epic `avra-8sb5.44`).
- When the distributed wrapper lands, `state users: Relation<User>`
  should make the two the SAME PLACE — the query becomes the
  subscription, and the read set drives invalidation. That is the
  payoff, and it is `OPEN`.

### 4.4 Robotics — a control loop over the robot's state

```avra
type Pose = { x: float, y: float, heading: float }

// the robot's place: one identity the whole program shares
state pose: Pose = Pose { x: 0.0, y: 0.0, heading: 0.0 }

// capabilities are seats: the hardware is filled by name
trait Motors { fn drive(left: float, right: float); fn stop() }
trait Sensors { fn read_pose() -> Pose }
once fn device() -> Device { Device.open("/dev/ttyACM0") }   // ONE handle per process

component controller(ambient motors: dyn Motors, ambient sensors: dyn Sensors) {
    fn tick(self) {
        let measured = self.sensors.read_pose()
        pose = measured                       // a write to the shared place
        self.motors.drive(plan(measured))
    }
}

fn loop(c: controller) {
    while true {
        c.tick()
        sleep(ms(10))
    }
}
```

Probed (exit 0): `float` fields, `state pose`, a fn that writes
`pose = …`, `once fn device() -> Device`, and `while true` all compile
today. The model holds: `state pose` is the robot's one shared place;
`ambient motors: dyn Motors` names a capability the library does not
own (the `ambient` mark is the ask, §3.5); `once fn device()` is the
one immutable handle. The control loop reads and writes the SAME place
every tick — exactly the `state` contract. `OPEN`: `sleep`/real-time —
a 10 ms loop under a cooperative scheduler must not be starved by a
handler; that is the scheduler's, not this model's.

### 4.5 Distributed — the interesting one

**Today `state x: T` means `Cell<T>`, local to this process.**
Generalize so the WRAPPER TYPE says how the place is SHARED, and the
compiler picks the mechanism from the declaration — exactly as the UI
epic picks per-site lowering.

```avra
state x: T              // Cell<T>       — local to this process
state x: Replicated<T>  // merged across nodes (CRDT-ish)
state x: Remote<T> at node   // ONE owner; reads/writes route there
state x: Relation<T>    // durable and incremental (the Db)
```

**The claim:** the author's READ and WRITE do not change — `x` answers
`T`, `x = v` assigns — and only the DECLARATION says where it lives and
how it converges. If that holds, the same construct scales from a local
register to a cluster.

**Does it hold?** The local case ALREADY holds, exactly as claimed:

```avra
state n: int = 0
fn bump() { n = n + 1 }          // `n` answers int; `n = v` assigns
```

```
(exit 0)
```

The wrapper case does NOT hold today, because the wrapper is read as a
VALUE type. The place's type is `Cell<W<T>>`, so `x` answers `W<T>`, not
`T`:

```avra
type Replicated<T> = { v: T }
state n: Replicated<int> = 0
```

```
error[type.binding]: `n` declares `Replicated<int>`, this is `int`
```

and the `at node` clause is not grammar at all:

```avra
state n: Remote<int> at node = 0
```
```
error[parse.expected]: expected EOF while parsing `program`
   ╰── at `state`
```

So the generalization is a real, coherent compiler change: make the
place WRAPPER transparent (`state x: W<T>` reads and writes in `T`, and
`Cell<T>` is just the default spelling of `W`). It is an ask, and it is
the natural generalization of the fibers design's "Cross-core shared
state (`Shared<T>`, atomics) is a later slice."

**Where it BREAKS — the honest hard parts.** The identical-syntax claim
is true for the simple, non-failing, convergent cases and false the
moment an operation can FAIL or must be TRANSACTIONAL:

1. **A remote read can fail; a bare `T` cannot say so.** `x` answering
   `T` has no channel for "node unreachable". Either the failure is a
   TRAP (fail-fast, declared with a `within` deadline), or `Remote`
   must expose a different READ (`x.get()? -> Result<T, NetError>`),
   which breaks the "read does not change" claim. There is no third
   option that keeps both properties. `OPEN` — and the same applies to
   `Relation<T>` (a SQL error) and to any `Remote` WRITE.
2. **A replicated write is an OPERATION, not an assignment.**
   `x = v` sends a value; CRDT merge needs the DELTA. Two writers
   computing `x = x + 1` and `x = x + 2` from the same `x` converge
   to one of them under last-write-wins — NOT to `x + 3`. So either
   `Replicated`'s write spelling is `x.apply(delta)` (assignment
   changes after all), or `x = v` IS last-write-wins and the CRDT
   promise is a lie for read-modify-write. This is the deepest break:
   **the wrapper does not just say where the place lives, it says what
   a write MEANS**, and the grammar of `x = v` cannot carry it.
3. **The type must constrain the wrapper.** `Replicated<T>` is sound
   only when `T` has a merge. A bound on a type's own parameter
   (`type Replicated<T: Merge>`) is F0100 today (bounds land on a free
   fn's parameters and nowhere else). So the mergeability cannot be
   stated in the declaration the design wants. `OPEN`.
4. **Partial failure and authority.** `state x: Remote<T> at node`
   routes writes to `node`; when `node` is down, a local "success" then
   a remote failure needs a durable outbox and reconciliation. No
   wrapper name solves that; it is a protocol. `OPEN`.
5. **`Relation<T>` is a QUERY, not a value.** A durable place is read
   as a set, filtered and ordered; `x` answering one `T` is the wrong
   projection for a table. The `@model`/ORM layer (§4.3) is where that
   shape lives, and it is not `Cell`-shaped.

**Conclusion.** The wrapper-type generalization is the RIGHT direction
and it HOLDS for the invariant the owner cares about — `state` is a
place, and the same `x` / `x = v` reads it whether it is a register, a
per-core cell, or a merged replica. It BREAKS where the mechanism has a
FAILURE or a NON-ASSIGNMENT write, because a bare `T` and `x = v` are
exactly the two things that cannot express either. The honest next
shape is that a wrapper is not only a sharing mechanism but a small
CAPABILITY with its own verbs (`Cell`: `get`/`set`; `Remote`:
`await`/`send`; `Relation`: `query`/`transact`), and `state x: W<T>`
keeps the DEGENERATE read/write syntax only for the wrappers where the
degenerate form is sound. That is an exploration, filed as an ask, not
a build.

---

## 5. What the compiler already answers

| construct | today | evidence |
|---|---|---|
| `let`/`mut` value + copy capture | landed | §1.1–1.2 |
| `state` place, Cell, share capture | landed | §1.3 |
| `state` SEAT (caller's place) | landed (#234) | state_test |
| module `state` shared across fns | landed | state_test |
| `once fn` (managed answer) | landed | §1.4 |
| `dyn Trait` as a free-fn / head seat | landed | §3.3 |
| `with { … }` record update | landed | §3.2 |
| `@model` + `state` beside it | landed | §4.3 |
| `provide`/`env T` | DELETED | §1.5 |

## 6. What is an ask

| ask | refusal today | home |
|---|---|---|
| `ambient` seat mark (free fn + component head) | parse error at the mark | §9.2 |
| component HEAD seat defaults (`= expr`) | parse error at `(` | §9.2 |
| place-wrapper transparency (`state x: W<T>` reads `T`) | F2019/type.binding | §9.3 |
| `at node` clause + `Remote` semantics | parse error | §9.3 |
| bound on a type's own parameter (`Replicated<T: Merge>`) | F0100 | existing (`avra-xubk.6` sibling) |
| `@model` generates the in-memory `state` | — | ORM epic |

## 7. The board's non-ambient gaps (already filed)

Per-item `on click { }`, typed message payloads, `field.on_input`,
`list … by it.id`, `derived`, live queries, `@model` forms — all probed
and filed under `avra-xubk.2`/`.3` and `avra-8sb5.59.27`. Nothing here
duplicates them.

## 8. Decided vs open

**DECIDED.** `let` value; `mut` value; `state` place (`Cell<T>`);
`once` lifetime; `provide`/`env` deleted; ambience is an `ambient`
SEAT filled by NAME with a default; supply is a binding (`const`/`state`);
value-vs-trait-vs-capability selection; extensibility by adding a seat.

**OPEN.** (a) process-wide MUTABLE state across cores; (b) whether
`Remote`/`Relation` reads carry a failure channel and how it meets
`x: T`; (c) whether `Replicated`'s write is assignment (LWW) or an op;
(d) a bound on a type's own parameter; (e) `@model` generating `state`;
(f) the exact `ambient` lowering (a param default vs a hidden field);
(g) whether `ambient` is also a READER (`env T`-style) or only a seat.
(The owner's decision is a SEAT; the reader form is dead with `env`.)

## 9. The asks, filed

| id | title | parent |
|---|---|---|
| `avra-xubk.6.2` | The `ambient` seat mark — context by NAME, not by type | `avra-xubk.6` |
| `avra-xubk.6.1` | Delete `provide`/`env T` — ambience is a name lookup, not a type-keyed one | `avra-xubk.6` — DONE |
| `avra-2y5c.20` | EXPLORE: the place WRAPPER type — `Cell`/`Replicated`/`Remote`/`Relation` as `state`'s sharing mechanism | `avra-2y5c` |

Sequencing: `.6.1` (the old spelling dies) landed before `.6.2` (the
seat exists), leaving a window with no type-keyed lookup and no seat;
the seat is the only `ambient` home now. `.20` is an
exploration, not a build. The board's non-ambient gaps stay in their
own tasks (§7).
