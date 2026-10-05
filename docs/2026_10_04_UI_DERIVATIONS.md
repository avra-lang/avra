# UI derivations — the compiler writes the second copy

> 2026-10-04. Design, not scheduled. Base `origin/main` at the time of
> writing. This is the UI epic's second copy: the things an author
> writes once and a framework makes them write again.
>
> Companions: `2026_10_02_COMPILED_UI.md` (the per-site update graph),
> `2026_10_01_UI_LIBRARY.md` (the library and its component contract),
> `2026_09_29_UI.md` (the program and the platform),
> `2026_09_30_STD_VALIDATE.md` (rules and the form projection),
> `2026_10_04_SHARING_MODEL.md` (places, `state`, `ambient`),
> `2026_10_05_UI_ARCHITECTURE.md` (the seams the library stands on).

## The thesis

Every item below is one rule applied:

> **You write the intent. The compiler writes the second copy.**

A route table, a loading flag, a serializer, a `Msg` dispatch, a form's
validation, an undo stack, an `isAnimating` timer, a style guide, a
source map — each is a second copy of something the author already
said. The framework's job is to delete the second copy.

No other framework can do most of this. The reason is three decisions
already made in this tree, not a wish:

1. **The tree is data.** `view(state) -> tree` is pure and the tree is a
   comparable, serializable, inspectable value — no closures, no hidden
   virtual DOM nodes. `2026_10_02_COMPILED_UI.md` builds the whole
   architecture on this.
2. **Sites are content-addressed.** A call site is a stable lexical
   place numbered by `(file, enclosing fn, hash of the site's text)`,
   never an ordinal. Landed (`avra-xubk.2`, PR #225): the wire carries a
   31-bit hash and a node inserted above moves nothing.
3. **The compiler owns a READ SET.** `features/read_set.av` computes
   which state each expression reads, through the complete child walk,
   with closures contributing their captures and calls staying opaque.
   Landed (`avra-xubk.3`, PR #227) and already emitting a per-site
   lowering plan (`lowering_plan`, PR #238).

Everything below is a *derivation* those three make possible rather
than magical. Where an item needs something absent, it says so, names
the ask, and names the real wanting site.

The board (`tools/ui-board/src/main.av`) is the running witness: a real
program that wants these, already compiling in a reduced form so each
gap is a floor, not a fiction.

---

## A. Routing from a screen's signature

**Deletes.** The route table, the path-to-params parser, the query
parser, the URL builder, and the hand-written typed link. This is the
single largest boilerplate item in web UI.

**You write.**

```avra
screen board(id: TaskId) {
    title board_title(id)
    heading "Board ${id}"
}

screen settings(state tab: SettingsTab = .profile) {
    picker tab
}
```

**The compiler writes.**

- `/board/:id` from the required parameter, and `?tab=` from each
  `state` parameter (UI.md §3.1: required parameters form the path,
  `state` parameters form the query).
- The parameter decoder, validated before the handler — via
  `@std/validate`, the same door a body takes: a bad `TaskId` answers
  problem+json with the issue, never reaches the handler
  (`2026_09_30_STD_VALIDATE.md` §10).
- Typed link building:

  ```avra
  link "Open" { to: board(t.id) }          // one call, one type
  go board(next)                            // push; the browser's own stack
  ```

  `link`'s `to` seat takes a screen value, so a wrong type is a compile
  error, a renamed screen renames every link, and a missing argument
  cannot be spelled (UI.md §3.1, §2.2).
- The route table from one `collect` over every `screen` in a package,
  the pattern already used for components in
  `packages/std-ui/src/components/catalogue.av:6`:

  ```avra
  collect screens: List<RouteEntry> = @screen in package as RouteEntry { … } by it.path
  ```

  Two screens deriving one path is a **compile error** — the `by` key is
  the path, exactly as `by it.name` dedups the component catalogue. The
  server serves the table; the client router reads the same one.

**Depends on / does not exist yet.**

- The `screen` keyword (UI.md §2.3). Today a screen is a plain `fn` and
  `tools/ui-board/src/main.av:61`'s `board_action` wrapper plus the
  `paint()` call are what stands in for one.
- `@screen` as a `collect` subject and a route entry.
- `link`/`go` as typed calls (UI.md §3.7, and the HTTP epic's
  `avra-8sb5.1.33.5` "projections from route fns: typed client, typed
  links, OpenAPI, MCP tools").
- `@action` already derives a POST route and a form from a signature
  (P0.5, `avra-8sb5.59.5`), so the route-derivation machinery exists;
  this extends it to `screen`.

**Already designed.** `2026_09_29_UI.md` §3.1 and the `screen` word
(§2.3); the sugar is `avra-8sb5.59.18`'s "a screen's signature as its
route". This child is a build against a settled design, not a new one.

---

## B. Async as a stream, projected to four states

**Deletes.** `loading`, `error`, `empty` and `data` flags, plus every
`if loading { spinner } else if error { … } else if items.is_empty() {
… }` ladder.

**The model is a STREAM, not a container.** Services and robotics want
the same shape — a value that arrives over time, may fail, and may end.
The UI is one projection of it. `Async<T>` is the four-state
projection, already named in `2026_10_02_COMPILED_UI.md`
("`Async<T> = .Idle · .Loading · .Failed(E) · .Ready(T)` so the UI
cannot forget a branch").

```avra
// a source, not a container: the server, a socket, a robotics sensor
let robots: Stream<Robot> = fleet_api.robots()

// the view projects the current value
view fleet() {
    stream robots {
        loading -> spinner "Loading robots…"
        error e -> error_state e
        empty -> empty "No robots yet"
        items -> list items by it.id { r -> robot_row(r) }
    }
}
```

**The compiler writes.** The four arms are a projection of the stream's
current value; the match is exhaustive, so a view cannot forget
`empty`. `stream` lowers to the read set: each arm is a site, so a
partial body patches only the arm that changed. The observation/place
split in UI.md §3.3 is the same rule at the data layer: an observation
suspends while pending, fails to the nearest `failed { }`, stays live.

**Depends on / does not exist yet.**

- A `Stream<T>` type and its `stream` view construct. Nothing in the
  tree carries a streaming value into `@std/ui` today.
- The four `Async` states as an enum the compiler knows is exhaustive
  (straightforward once `stream` exists).
- The `spinner`, `empty`, `error_state` components exist
  (`packages/std-ui/src/components/`), so the leaves are there.
- Effects/typed requirements for the subscription (`avra-xubk.5`).

**Already partly named.** `Async<T>`'s four states are in
`2026_10_02_COMPILED_UI.md`'s "Other features worth having"; the
observation/failure semantics are UI.md §3.3. The new move is calling it
a **stream projection** rather than a new async container, so services
and robotics share it.

---

## C. Undo/redo and optimistic updates from the message log

**Deletes.** The undo stack, the redo stack, every inverse operation
written by hand, and the "optimistic" state copy + rollback.

**Why it is free.** Messages are content-addressed **data** and state
is snapshotable (thesis decision 1). So:

- `undo` is a replay to the previous state.
- `redo` is a replay forward.
- optimistic update is a speculative state applied before the receipt,
  rolled back if the receipt fails.

```avra
// nothing here is written by hand — the log already exists
button "Undo" { on click { undo() } }
```

`@action`'s impact record already carries the recovery
(`.destructive with { safeguard: .trash(days(30)) }`, UI.md §3.4), and
the derived discharge for `.reversible` / `.trash` is an undo toast.
The log turns that discharge from a *convention* into a **mechanism**:
undo is not a special toast handler, it is the message log's inverse.

**Depends on / does not exist yet.**

- Generated `Msg` variants carrying typed payloads and one exhaustive
  `update` (`avra-xubk.2.1`) — the log is exactly this stream of
  messages, so this item **rides `avra-xubk.2.1`, it does not precede
  it**. Today `tools/ui-board/src/main.av:44`'s `enum Msg` is
  payload-free, so there is no log to replay.
- Snapshot/replay of `state` (the `@model`/authority work,
  `avra-8sb5.59.12`, and the DB-as-versioned-value in
  `2026_09_24_ORM.md` §"DB as a versioned value": agent self-undo,
  audit-grade history).
- A `log`/`history` API over the generated update.

**This is the strongest argument for the generated-message design.** Once
messages are data and sites are content-addressed, time travel, undo,
redo, audit and optimistic updates are the same artifact. A framework
that stores fns in the tree (the rejected alternative 2a in
`2026_10_02_COMPILED_UI.md`) can never replay anything.

---

## D. State backed by a SOURCE — the general place wrapper

**Deletes.** The per-source synchronisation code: read the URL, write
the URL, read the file, save the file, subscribe to the socket, persist
to the DB row. Each is a second copy of "this value lives over there."

**The general thing is a place backed by a source.** `{ synced: url }`
is too UI-shaped; the same shape covers the URL, a file, an env var, a
socket, a DB row.

```avra
// UI spelling — a query parameter, validated, and the screen's URL is its state
screen board(id: TaskId, @query_param("filter") filter: Filter = .all) { … }

// the general spelling — the declaration says where the place lives
state filter: Url<Filter> = .all
state config: File<Config> = "avra.toml"
state port: Env<int> = 8080
```

**The compiler writes.** The read/write pair to the source, the
subscription (a URL push, a file watch, a socket ready), and the
invalidation of everything whose read set names the place. The author's
`filter` reads and writes do not change.

`@query_param("filter")` is the UI projection of the general wrapper:
for a screen, the source is the route (§A already treats `state`
parameters as the URL, UI.md §3.1). The `.url` state profile stays
retired — a screen's URL *is* its `state` parameters.

**Depends on / does not exist yet.**

- **Place-wrapper transparency**: `state x: W<T>` must read and write in
  `T`, and `Cell<T>` becomes the default spelling of `W`. Today
  `state n: Replicated<int> = 0` is `error[type.binding]` because the
  wrapper is read as a value type
  (`2026_10_04_SHARING_MODEL.md` §4.5, §9.3; ask `avra-2y5c.20`).
- The concrete `Url` / `File` / `Env` wrappers over `Cell`, and their
  verbs.
- `@query_param` as an annotation and the route decoder (§A).

**Connect to the distributed exploration.** `2026_10_04_SHARING_MODEL.md`
§4.5 is the **same shape**: a place whose declaration says where it
lives (`Cell` local, `Replicated` merged, `Remote` routed,
`Relation` durable). The wrapper is not only a sharing mechanism but a
small capability with verbs. This item is the read/write half; the
sharing half is `avra-2y5c.20`. Say so, because a `Url` state and a
`Remote` state are the same declaration with different mechanics.

---

## E. Selection as a direct child, like `for`

**Deletes.** `selectedId`, `selectedIds`, shift-click range tracking,
`selectAll` flags, arrow-key handlers, and the "clear selection on
outside click" handler. Every list of selectable things hand-writes all
of these.

**You write.**

```avra
list tasks by it.id select: sel {
    t -> task_row(t)
}
```

**The compiler writes.**

- The selected id (single), the selection set (multi), and the anchor
  for a range.
- Range selection: shift-click and shift-arrow derive the range over the
  ordered source.
- Keyboard nav: up/down, home/end, page, type-ahead.
- Select-all, invert, clear-on-escape, focus management and roving
  tabindex.
- The a11y announcement of selection state.

**Selection is a general cursor over a collection, not a UI feature.**
The same cursor serves a table, a tree, a canvas scene graph, and a
robotics waypoint list. It composes with `list … by it.id`
(`avra-xubk.3.1`) because the key is already the identity the cursor
needs: the selection is a set of keys, so reorders and reconciles keep
it.

**Depends on / does not exist yet.**

- `list <source> by it.<field> { x -> … }` (`avra-xubk.3.1`) — the
  keyed list is the substrate.
- A `select: name` clause on the list grammar and a `Selection<T>` value
  the body can read (`sel.contains(t.id)`, `sel.count()`).
- Keyboard/focus machinery (`avra-8sb5.59.26`, L3 interaction).

---

## F. Forms and validation derived from models

**Deletes.** The form's HTML, the client-side validation copy, the
server-side validation copy, the per-field error display, and the
"which fields does the server own" list. All five are second copies.

**The design already exists.** `2026_09_30_STD_VALIDATE.md` establishes:

- Rules are field annotations on the model: `@email`, `@range(13, 130)`,
  `@matches(password)`, a rule on a named type.
- A decode is derived per type: `Signup.decode(v)? -> Result<Signup,
  Issues>`, with `from_json`.
- Every issue carries path, rule, message, received and a structured
  fix; a decode never stops at the first problem (§3).
- **§5 "Projections (one source, many outputs)" already names "HTML form
  attributes and per-field error slots (the UI epic's forms)"** —
  the form is a projection of rules the compiler already holds.
- §10 validates a route's typed parameter before the handler and
  answers problem+json with EVERY issue.
- §7.5 / §131 have the same rules run on both ends, so a form shows the
  server's exact error with identical messages.

And P0.5 (`avra-8sb5.59.5`) already built `@action`'s derived form:
"POST route, form view from the signature, validation from types +
check(), redirect-after-post, idempotency id, per-field refusals."

**You write.**

```avra
@model
type Todo = {
    @length(1, 200) title: string
    done: bool = false
    @after(now) due: Date? = null
}
```

**The compiler writes.**

- The form's fields, their input types and HTML attributes.
- Client-side validation from the same rules, and the server's
  validation from the same rules.
- Per-field error slots fed by an `Issues`, and the cross-field `check`
  run on the server.
- The submit route and the decode/validate before it.

**The new idea: `with` / `without` to project a model to a form.** A
form usually omits fields the server owns (`id`, `created_at`, a
computed field). Rather than a second "form model", project the model:

```avra
form Todo.form().without(.id, .created_at)
form Todo.form().with(.title.label("What needs doing?"))
```

`without` removes the fields the server owns; `with` overrides a label
or a control. This is field-spread's projection surface
(`2026_09_30_FIELD_SPREAD.md`) applied to a form, one source of truth
with many outputs (P12).

**Depends on / does not exist yet.**

- A `Validates`-kind annotation answering a `Rule<T>` (`@std/validate`'s
  prerequisite, `avra-8sb5.59.11.92`).
- `@model` (`avra-8sb5.59.27.3`).
- A form projection surface (the `form <model>` clause and
  `with`/`without`).
- The `form`, `field`, `error_text` components exist
  (`packages/std-ui/src/components/`).

**This child is a BUILD, not a design.** Two docs and one landed task
already settle it; the work is the projection surface and the join to
`@std/validate`.

---

## G. Animation as a component property — animating the DIFF

**Deletes.** Every `isAnimating` flag, `setTimeout`/`requestAnimationFrame`
timer, transition class, and cleanup. The author tracks "am I inside a
transition" by hand, and a framework that only knows the new tree
cannot help.

**Not a suffix; a property like the rest.** `Style` gains `motion`
(UI.md §3.7 names `animate` a pending word; UI_LIBRARY §4's `Style` is
the substrate):

```avra
card "Board" {
    style: Style {
        fill: .SurfaceRaised
        motion: Motion { enter: .FadeUp, exit: .FadeDown, duration: .Normal, ease: .Standard }
        states: [ StateStyle { state: .Hover, style: Style { elevation: .Two } } ]
    }
}
```

**The interesting part: the compiler animates THE CHANGE.** Because the
read set says what each site reads and the previous tree is data, the
compiler knows exactly what changed between two frames — which node was
inserted, which text changed, which list moved. So it can choose the
transition for that delta, not for a blanket "isAnimating" window:

- a value change on a bound leaf: animate the leaf's property,
- a list reorder: animate the moves (the keyed reconciler knows the
  key path),
- an insert/remove: animate enter/exit,
- a whole-subtree swap: animate the root of the swap.

**Depends on / does not exist yet.**

- `Motion` in `Style` / the `Theme` motion tokens (UI_LIBRARY §3 already
  lists `duration` and `ease` primitives).
- Frame-to-frame diff exposed to the lowering: the source of "what
  changed" is the same plan `lowering_plan` (`features/read_set.av`)
  already computes per site — but the plan does not yet reach the frame
  (`avra-xubk.3`'s named follow-on: fold the callee's read set through a
  call).
- The DOM realizer's op stream (`avra-8sb5.59.10`) — animations lower to
  transition ops.
- Reduced-motion: `when reduced_motion { }` (UI.md §3.5) gates every
  motion by capability.

**Already named as a layer.** "motion" is L7 (`avra-8sb5.59.30`) and
`animate` is a UI.md word. The contribution here is the *diff* framing:
animate the change, not the flag.

---

## H. Keyboard as a subcomponent with a block

**Deletes.** The global `keydown` listener, the modifier-key string
comparison, the conflict check, and the help text. Like the CLI's flag
declarations — `keyboard "cmd+s" { save() }` reads the way a `flag`
does.

**You write.**

```avra
view editor(t: Todo) {
    keyboard "cmd+s" { save(t) }
    keyboard "cmd+z" { undo() }
    keyboard "cmd+shift+z" { redo() }
    keyboard "escape" { dismiss() }
    field "Title" { value: t.title }
}
```

**The compiler writes.**

- The global handler registration, scoped to the view's life (installed
  on enter, removed on exit — an effect's release, `defer`).
- Conflict detection: two live bindings for the same chord is a compile
  error (or a named runtime precedence when they are in different
  scopes).
- The a11y help text: every binding described in the command palette
  and the shortcuts help, derived, not maintained.
- The command-palette entry and the platform chord (`.primary` = ⌘ on
  Apple, Ctrl elsewhere, UI.md §3.7's `hotkey .primary + "k"`).

**Depends on / does not exist yet.**

- The `keyboard` block grammar and a chord literal (`.primary + "k"`).
- The `hotkey` item is already in the UI backlog (UI.md §3.7 and
  WEB_UI's L2 table: `hotkey "cmd+k" { }`).
- View lifecycle for install/remove (`avra-8sb5.59.26`, L3 interaction).
- The same door as `@action`: UI.md §3.7 lists "keyboard shortcut,
  command palette" as a derived door of an action, so `keyboard "cmd+s"
  { save(t) }` and `@action fn save` should be **one** derivation where
  the body names an action.

---

## I. Capabilities as ambience

**Deletes.** The app wiring every capability through props: `open_url`,
`navigate`, `fetch`, `storage`, `toast`, `dismiss`, a focus handle. The
app declares where they live once; components read them by name.

**Ambience is a seat, not a type-keyed provider.**
`2026_10_04_SHARING_MODEL.md` §3 settles this: `provide`/`env T` are
deleted (`avra-xubk.6.1`), and a component declares an `ambient` seat
filled from the caller's scope **by name** (`avra-xubk.6.2`):

```avra
component dialog(title: string, ambient toasts: Toasts = Toasts.none, ambient dismiss: fn() -> void = noop) {
    …
}
```

A capability is a fn value or a `dyn Trait` seat (SHARING_MODEL §3.3):
a trait is for "give me something of YOUR type that does X"; a value is
for "give me a value of MY type."

**You write (the app, once).**

```avra
const env: Env = Env { theme: default_theme, density: .Comfortable, direction: .Ltr }
state toasts: Toasts = Toasts.none          // supply is a binding in scope
fn navigate(to: Route) { … }                // a fn in scope, read by name
```

**The compiler writes.** The seat's argument at each call site, resolved
by the ordinary lexical walk; a missing binding is a compile error. No
runtime provider stack, no type-keyed lookup, no second scope.

**Depends on / does not exist yet.**

- The `ambient` seat mark (`avra-xubk.6.2`) — today `fn f(ambient env:
  Env = …)` is a parse error at the mark, and a component HEAD default is
  a separate ask.
- The deletion of `provide`/`env T` (`avra-xubk.6.1`) — DONE; neither
  spelling exists.
- Capability wrappers (`Toasts`, `Navigator`, `Storage`) as library
  types.

**Cross-reference.** `avra-xubk.6.1`/`.6.2` are the asks; this item is
the *UI surface* of them. It adds nothing to the design, it names the
app's wiring that dies.

---

## J. Persistence as an annotation

**Deletes.** Every serializer, deserializer, storage key, load-on-start
and save-on-write. A remembered toggle, a remembered filter, a draft
that survives a reload — all hand-written today.

**You write.**

```avra
state filter: Filter = .all @persisted
state dark: bool = false @persisted
state draft: string = "" @persisted(session: true)
```

**The compiler writes.** The storage read on first access, the write on
change, the schema (the type's own shape), and the migration policy
(`@version`, `2026_09_30_STD_VALIDATE.md` §9 decision 7). `@persisted`
is the in-memory-to-durable projection of the *same* declaration — the
`state` : `@model` framing in `2026_10_04_SHARING_MODEL.md` §4.3
("one is in-memory and process-local; the other is durable … both are
places").

**Depends on / does not exist yet.**

- An annotation on a `state` declaration (annotations on single record
  fields exist; a `state` annotation is new).
- A storage backend (`@std/sqlite` on the web via OPFS,
  `avra-8sb5.59.14`; `@std/db` elsewhere).
- Serialization derived from the type — the same decode/encode the ORM
  and `@std/validate` already derive.
- Encryption for `@secret`/`@pii` fields (`@std/validate` §7.9).

**Already designed in pieces.** `@model` already owns durability and
derives storage (`2026_09_24_ORM.md`); `@persisted` is the projection of
that machinery onto a bare `state`. The board's `state filter`
(`tools/ui-board/src/main.av`) is the wanting site: it is lost on every
reload.

---

## K. Visible compiler knowledge — the dev HUD

**Deletes.** The profiler and the guesswork. "Why did this re-render?"
is answered by a profiler in every other framework; here it is a list.

**Example overlay.**

```
frame 41  ← `filter` changed
  · 3 subtrees hoisted (never re-evaluated)
  · heading patched (text)
  · list reconciled: 12 keys, 2 moved, 0 rebuilt
  · 0 subtrees rebuilt
```

Or, on click:

```
site S0x…  `button "Add"`  →  Msg.Add  →  state.tasks (append)  →  list reconciled
```

**Why it is nearly free.** The compiler already computes the read set
and a per-site lowering plan (`features/read_set.av`:
`read_set_of`, `hoistable_of`, `SiteLowering`, `lowering_plan`). The
data the HUD shows **is the compiler's own analysis**, emitted as data
alongside the program. No instrumentation, no sampling, no shadow tree.

- **Inspector**: the tree is data, so the running tree is inspectable
  and its origin is a content-addressed site.
- **Time travel**: state and messages are data (item C), so a frame can
  be replayed.
- The HUD is a *target* over the same tree (a debug realizer), not a
  bolt-on.

**Depends on / does not exist yet.**

- A dev build that emits the read set + lowering plan alongside the
  program (the plan exists compiler-internally; the seam to a running
  program is `avra-xubk.3`'s named undecided seam).
- `#` origin on every node — the Node record (`avra-8sb5.59.20`, closed)
  already carries origin.
- A HUD realizer / `avra dev` (`avra-8sb5.59.11`).

**Already named.** "inspector and time travel (free: the state, msgs and
effects are all data)" in `2026_10_02_COMPILED_UI.md`. The reach here is
the *causal chain*: name the cause, not just show the tree.

---

## L. Click a rendered node → jump to the source

**Deletes.** Source maps, build plugins, and the debug-id convention.
Mainstream frameworks fight for this because their runtime is a string
template or a virtual tree with no provenance.

**You write.** Nothing. The author already wrote `button "Add" { … }`
at a place.

**The compiler writes.** The mapping from a rendered node back to its
source, because:

- sites are content-addressed (`(file, enclosing fn, hash)`) — the
  running app IS a projection and the mapping already exists in the tree;
- every node carries its origin (Node record, `avra-8sb5.59.20`).

So `avra dev`'s overlay can let a click on a rendered node open the
exact source span in the editor. No source map, no plugin, no
build-mode-only artifact — it is the same identity that drives
invalidation.

**Depends on / does not exist yet.**

- A dev overlay that reads a node's origin and opens the span.
- The editor integration (a CLI/link, `avra explain <site>`).
- `avra dev` (`avra-8sb5.59.11`), whose `explain screen <name>` already
  prints route/reads/writes/realizes.

**Already partly built.** Content-addressed sites landed (`avra-xubk.2`);
the Node record's origin landed (P0.0). This is the projection *out* to
the editor.

---

## M. A generated gallery — every component × every control state

**Deletes.** The hand-maintained style guide, the storybook, and the
per-component demo. Add a component, it appears; add a state, every
component gains a cell.

**Already half-present.** `packages/std-ui/src/components/catalogue.av:6`
enumerates every component via `collect components = @prim in package as
ComponentEntry { name: it.name } by it.name` — a new component is one
declaration and the catalogue sees it. `ControlState` is named as a
universal enum in `2026_10_01_UI_LIBRARY.md` §6 ("the library defines
`ControlState` (`Enabled`, `Hover`, `Focus`, `Pressed`, `Disabled`,
`Loading`, `Selected`, `Invalid`)") — though it does not exist in the
tree yet.

**The compiler writes.** The gallery: for each component × each control
state × each variant, a cell, rendered by every realizer as a snapshot
test. Because both the component list and the state list are data, the
matrix generates itself — and a target missing a component fails to
compile in the gallery too, which is the missing-component witness
already required per phase.

**Depends on / does not exist yet.**

- A universal `ControlState` enum and a way to force a component into a
  state for rendering (the state is data in `Style.states` today; a
  forced state needs a dev override).
- The gallery as a realizer/CLI (`avra ui gallery`, B6; the current
  `packages/std-ui_gallery` is the floor).
- Snapshot/geometry equivalence across layout engines (UI_LIBRARY §5,
  §15).

**Already named.** P0.6 gallery v0 (`avra-8sb5.59.6`, closed) and L7
(`avra-8sb5.59.30`). This advances it from "render every fn" to "every
component × every state".

---

## What already exists (so the child is a build)

| item | design source | state |
|---|---|---|
| A routing | `2026_09_29_UI.md` §2.3/§3.1; `avra-8sb5.59.18`; `avra-8sb5.1.33.5` | typed links partly built (P0.3) |
| B async stream | `2026_10_02_COMPILED_UI.md` (`Async<T>`); UI.md §3.3 | leaves built, stream absent |
| C undo/redo | `2026_10_02_COMPILED_UI.md`; UI.md §3.4; `2026_09_24_ORM.md` | rides `avra-xubk.2.1` |
| D source-backed state | `2026_10_04_SHARING_MODEL.md` §4.5; `avra-2y5c.20` | wrapper transparency is the ask |
| E selection | — | new derivation |
| F forms | `2026_09_30_STD_VALIDATE.md` §5/§10; P0.5 (`avra-8sb5.59.5`) | BUILD; projection named |
| G animation | UI.md §3.7 `animate`; `avra-8sb5.59.30` | BUILD; diff framing is new |
| H keyboard | UI.md §3.7; WEB_UI L2 `hotkey` | BUILD |
| I capabilities | `2026_10_04_SHARING_MODEL.md` §3; `avra-xubk.6.1`/`.6.2` | BUILD of existing asks |
| J persistence | `2026_09_24_ORM.md`; `2026_10_04_SHARING_MODEL.md` §4.3 | BUILD; projection of `@model` |
| K dev HUD | `2026_10_02_COMPILED_UI.md`; `features/read_set.av` | analysis landed, seam open |
| L click-to-source | `avra-xubk.2` (sites); `avra-8sb5.59.20` (origin) | mapping exists; projection out is new |
| M gallery | `2026_10_01_UI_LIBRARY.md` §6; P0.6; L7 | catalogue exists; matrix advances it |

## Build order

1. **A + F** — routing and forms are the largest boilerplate and both
   stand on designs already settled (screen signature, validate §5).
   A also unblocks D's UI spelling.
2. **C** (after `avra-xubk.2.1`) and **I** (after `avra-xubk.6.1`/`.6.2`)
   — they ride asks already queued, so they land second.
3. **B + E** — the stream projection and the selection cursor; both are
   value types over collections/effects already in flight.
4. **D + J** — source-backed and persisted state; both wait on
   place-wrapper transparency (`avra-2y5c.20`) and the ORM.
5. **G + H + K + L + M** — the compiler-reactivity surface, after the
   read set reaches the frame (`avra-xubk.3`'s follow-on); K, L and M
   are dev tooling that reads the same analysis.

---

## Machinery gaps — what a serious cross-platform framework still needs

> 2026-10-04. The derivations above are *compiler* wins. This is the
> other ledger: machinery a framework needs that the compiler cannot
> conjure. Filed under `avra-8sb5.59`.

**The core is strong and rare.** The compiler owns a read set and a
per-site lowering plan (`features/read_set.av`, #227/#238); the tree is
data; events are typed with payloads (#237/#249/#250); one vocabulary
realizes several targets (#222); and state has an identity with a
proven lifetime (#217–#234, #257). Those are the hard parts and they
exist. **The gaps are the periphery — and a framework is judged on its
periphery.** No user sees the read set; they see a long list scroll, a
field they can type into, a device rotation survive.

| # | gap | why it blocks | task | depends on |
|---|---|---|---|---|
| 1 | Virtualization | a 10,000-row list builds, walks and diffs 10,000 nodes every paint; no mechanism fixes a list that should not have been built | `.35` | L1 scroll + `.36` text metrics + keyed `list … by` (#248, landed) |
| 2 | Text measurement / font metrics | every text-dependent size is a guess — wrapping, ellipsis, intrinsic min/max, baselines, variable row heights | `.36` | nothing to start; unblocks L1 and `.35` |
| 3 | Gestures | input is click/change/input — no drag, pinch, fling, long-press; composition (the gesture arena) is the hard half | `.37` | payload widening `avra-4a34`; scheduler #223 (landed); source-backed state `.34.4` |
| 4 | App lifecycle | one entry exists (`avra_start`) and no background/resume/terminate, which native shells all need | `.38` | routing `.34.1`; the wasm entry that exists |
| 5 | Platform abstraction | density, safe areas, native input methods and per-platform a11y decide whether "cross-platform" is true | `.39` | native targets L6 (`.29`); ambient `avra-xubk.6.2` |
| 6 | Internationalization | RTL, plurals, date/number formats, collation, text expansion — cheap now, expensive later | `.40` | ambient `avra-xubk.6.2`; text measurement `.36` |
| 7 | Dev server / hot reload | the edit loop decides adoption, and today it is manual | `.41` | nothing blocking; pairs with the dev HUD `.34.11` |
| 8 | Real text editing | a `field` is not a text input without IME composition, selection, caret and undo | `.42` | `avra-9zav` (value attribute); payload widening `avra-4a34`; gestures `.37` |

**The order that matters.** (1) **The emitter** (`avra-xubk.3`, in
flight) — nothing is faster until it lands, because the per-site plan is
inert until a frame consumes it. (2) **The native targets** (`.29`, L6)
— until uikit/appkit/android exist, "cross-platform" is half true.
(3) **Layout + text measurement** (`.24`, L1 + `.36`) — the layout
engine computes sizing with no metrics, so text is a guess.
(4) **Virtualization** (`.35`) — table stakes for any real list.
(5) **Gestures + focus/keyboard** (`.37` + `.26`, L3) — the interaction
floor every platform expects.

**The honest note about wanting sites.** Doctrine here is that sugar
arrives when a wanting site appears. Measured against the tree:

| gap | wanting site on main |
|---|---|
| text measurement | yes — `style/layout.av`; canvas/tui |
| text editing | yes — `components/field.av`; the board's add-field |
| virtualization | weak — the board's task list is short |
| platform abstraction | partial — `realize/dom/frame.av`, `a11y/` |
| **gestures** | **none — the board does not drag** |
| **app lifecycle** | **none beyond `avra_start`** |
| **internationalization** | **none — nothing is localized** |
| **dev server / hot reload** | **weak — `tools/ui-board/` is reloaded by hand** |

A gap with no wanting site is exactly the one that gets forgotten until
it is expensive. Said here rather than hidden.

**Cross-references.**
`2026_10_01_UI_LIBRARY.md` — §11 realizers and targets (the capability
matrix), §7 the taxonomy, §15 the definition of done.
`2026_09_30_STD_VALIDATE.md` — §5 projections, §10 route validation
(the forms work).
`2026_10_04_SHARING_MODEL.md` — §4 outside the UI (the place wrapper
behind source-backed state).
`2026_10_02_COMPILED_UI.md` — "the compiler picks the mechanism per
site" (the update graph the emitter must reach).
