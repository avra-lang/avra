# Data, HTTP and forms — one type, every boundary

**Status:** design, 2026-10-19, not scheduled. Read against main `e532005d`.
Supersedes the `@model(access:, delete:, trash:)` sketch and the loose
`@get`/`@post` fns of `docs/2026_09_30_HTTP_ROUTES_DX.md` §1 (the
signature rules of its §2 survive, moved into the route components).
Builds on: recovered `2026_09_24_ORM.md`, `2026_09_30_STD_VALIDATE.md`,
`2026_09_23_COMPONENT_EXPANSION.md`, `2026_09_29_UI.md` §3.3/§3.8/§16,
`2026_10_04_UI_DERIVATIONS.md` §F, `2026_10_04_SHARING_MODEL.md`.

`‡` marks language or compiler surface that does not exist today. Every
unmarked form compiles on main or is a pure library addition.

---

## 1. Thesis

**A boundary is a decode, and a router is a composition.** There is one
door into every place data lives — the HTTP body, the database row, the
form's fields — and it is the type's own derived `decode`, which runs the
type's rules. So validation stops being a feature: a `Task` that exists
passed its rules, wherever it came from (parse, don't validate). And a
router is to a server what a view is to a surface: a `component` whose
body is what it is made of (`@composes`, already landed for views). Embed
it anywhere a route goes. Every projection — the server handler, the
typed client, the observation in a view, the form, OpenAPI, the MCP
tool — is read off that one router, whose seats are typed by that one
model (P6, P12). Nothing is written twice; nothing floats loose.

---

## 2. The task board, end to end

### 2.1 Single board

```avra
// model.av — the schema
use @std.db.{model}
use @std.validate.{length}

model Task {                              // ‡ declaring block (§3.1)
    @length(1, 200) title: string
    done: bool = false
}
```

```avra
// api.av — the router: a component made of routes
use @std.db.{crud}
use @std.http.route.{delete}
use model.{Task}

export component tasks {
    crud Task                             // list, find, create, update, remove
    delete clear "/done" { () -> Task.where(done: true).remove() }
}
```

```avra
// main.av — the server embeds the router like any route
use @std.http.server.{server}
use @std.http.route.{get, group}
use @std.ui_http.{Document}
use api.{tasks}
use board.{view}

export server app {
    port: 8080
    get "/" { _req -> Document { title: "Tasks", body: view() } }
    group "/api/tasks" { tasks {} }
}

let _ = app.run()
```

```avra
// board.av — the page. No `state tasks`, no fetch, no sync button.
use @std.ui.components.{button, card, checkbox, form, item, list, progress, row, text}
use @std.db.{Patch}
use api.{tasks}
use model.{Task}

enum Show { All, Active, Done }
state filter: Show = .All                 // a PLACE: the view's own

fn admits(t: Task) -> bool { match filter { .All -> true, .Active -> !t.done, .Done -> t.done } }
fn done_count() -> int { tasks.list().filter(it.done).length }   // an OBSERVATION, live

component task_row(task: Task) {
    item {
        checkbox self.task.title {
            checked: self.task.done
            on change { done -> tasks.update(self.task.id, Patch<Task> { done: done }) }
        }
        button "Remove" { on press { tasks.remove(self.task.id) } }
    }
}

component board {
    card "Board" {
        progress "Done" { amount: done_count(), max: tasks.list().length }
        row {
            tab "All" { shows: .All }
            tab "Active" { shows: .Active }
            tab "Done" { shows: .Done }
        }
        button "Clear done" {
            on press { tasks.clear() }
            disabled: done_count() == 0
        }
        form tasks.create { submit: "Add" }            // fields + rules from `Task` (§6)
        list { for t in tasks.list().filter(admits) { task_row t { key: t.id } } }
    }
}
```

`tab`, `header`, `footer` and `about` stay as they are in
`tools/ui-board/src/board.av`. What left: `Todo` (it is `Task`), the
`tasks`/`seq` state, `add`, `marked`, `sync`, `counted`, `Fetch`, the
draft state, the hand-written request. `tasks.list()` read three times is
ONE request — an observation is keyed by its route and arguments.

### 2.2 With relations — boards own tasks, users own boards

```avra
// model.av
model User {
    @unique @email email: string
    @length(1, 80) name: string
}

model Board {
    @length(1, 80) name: string
    @owner owner: User                    // who may touch this row
    @cascade tasks: Many<Task>            // has-many; deleting a board deletes its tasks
}

model Task {
    @length(1, 200) title: string
    done: bool = false
    @owner board: Board                   // belongs-to; access inherits from the board
    @soft_delete removed_at: Time? = null // remove is reversible; reads skip it
}
```

```avra
// api.av
export guard me { req -> sessions.user(req) }      // `User?` — absent is a 401

export component boards {
    crud Board
    group "/{board}/tasks" { crud Task }           // the hole fills `Task.board` by name
}
```

```avra
// main.av
export server app {
    port: 8080
    get "/" { _req -> Document { title: "Boards", body: view() } }
    group "/api" {
        me                                         // every route below may take `me: User`
        boards {}
    }
}
```

The page reads `boards.list()` and `b.tasks` (an observation over the
nested route); everything in §2.1 carries over with `tasks.` read as
`b.tasks.`. Ten lines of model and five of api are the whole backend:
schema, migrations, CRUD, nested routes, authorization, soft delete,
cascade, validation, and the client.

---

## 3. The model layer

### 3.1 `model Task { … }` — the declaring block

`@model type Task = { id: int = 0, … }` (packages/std-db/src/db.av)
keeps working as the long spelling. The short one is the declaring block
COMPONENT_EXPANSION §9 already decided (`model User { email: string }`,
"expanded as `@derive` over it") ‡. Because the block DECLARES the
record, the derive adds what every model has and no author should type:
`id: Id<Task>` ‡ (a typed id — a `Board` id in a `Task` seat is a type
error), and the hidden version column it already reserves. ORM §12 Q6 is
answered by this.

### 3.2 What `model` derives

| Projection | From | Shape |
|---|---|---|
| table DDL, quoted identifiers, claim registry | the fields | exists (db.av) |
| `insert`, `find`, `update`, `remove`, `all` | the fields | exists, renamed `delete → remove` |
| `Task.where(done: true)` → `Query<Task>` | each field becomes a defaulted named seat | ‡ library; one equality per named argument |
| `decode`, `from_json`, `checked` | the field marks | `@derive(Decode)` exists (std-validate/src/derive.av); `model` implies it |
| `New<Task>` (no `id`, no `@owner` field the guard fills, no `@auto`) and `Patch<Task>` (every field optional) | the fields | ‡ type projections; fallback `NewTask`/`TaskPatch` names |
| `CHECK` constraints | rules with a SQL reading (`@range`, `@length`) | library (validate §5) |
| the `crud` router | the model | §4.3 |

**One connection, no seat ceremony.** Model verbs take the database as an
`ambient db: Db` seat (SHARING_MODEL §3, designed, not landed ‡), filled
from the program's `once fn db() -> Db`. Until `ambient` lands they take
`db` explicitly, as today.

### 3.3 Relations — ORM §12 Q2 resolved

| Written | Means | Stored |
|---|---|---|
| `board: Board` | belongs-to (required) | `board_id INTEGER NOT NULL REFERENCES "Board"` |
| `board: Board?` | belongs-to (optional) | same, nullable |
| `tasks: Many<Task>` | has-many | nothing — a query |
| `members: Many<User> @via(Membership)` | many-to-many through a real model | the join model's table |

- **Declared on the parent, inverse inferred.** `Many<Task>` finds the one
  `Board`-typed field on `Task`. Two such fields are a refusal naming both
  and asking for `@via(field)`; `@via` is never needed otherwise. This is
  the ORM doc's explicit recommendation minus its ceremony: the relation is
  readable on the type (P7), and the mark appears only where it says
  something.
- **`Many<T>` is a `Query<T>`, never a loaded list.** `b.tasks` is a query
  value; iterating it runs one statement. `Board.all().with(.tasks)` plans
  ONE join or ONE `IN` batch. So the ORM doc's `relation_not_loaded` trap
  disappears: there is no unloaded state to read. `avra check` flags a
  query iterated inside a loop over its parent's query, with the `.with`
  fix.
- **Cascade is a field mark.** `@cascade` on the `Many` deletes children;
  unmarked is `restrict` (the delete is refused while children exist);
  `@set_null` on an optional belongs-to clears it.
- **Many-to-many** (ORM Q8): the join is a real `model Membership { board:
  Board, user: User }` — it gets the claim registry and the id for free,
  and it is where a role field goes the day one is wanted.

### 3.4 Contracts are field marks, never `model` arguments

| Mark | Effect |
|---|---|
| `@unique` | exists; a violation becomes an `Issue` at that field's path (§7) |
| `@soft_delete removed_at: Time? = null` | `remove` sets it; every derived read filters it; `.including_removed()` opts out; the route's impact becomes `reversible` (undo, derived) |
| `@owner f: User` / `@owner f: Board` | the row's owner, or "whoever owns this parent"; the derived router filters and refuses by it (§4.4) |
| `@auto created: Time` | set by the database, never by a body |
| any `@std/validate` rule | run by every write (§7) |

Retention (`trash: days(30)`) is not a mark yet: a purge is a job, and
jobs are actions (AUTHORITY §8). Owner decision 6.

### 3.5 Migrations

- `db/schema.snap` — a committed snapshot of every model's shape, keyed by
  declaration (the `seed.sources` pattern). `avra db diff` writes
  `db/migrations/NNN_<what>.sql` from the snapshot to the source.
- **Growth crosses, moving refuses** — the compiler's own crossing law.
  A new field with a default, a new model, a new `Many` → generated. A
  rename is `@renamed_from("name")` — the SAME mark std-validate uses for
  wire evolution, so one rename moves the table and old JSON together. A
  narrowing or a type change refuses, naming the field, and asks for a
  `@migration(n) fn(old: v3.Task) -> Task` ‡ that runs over the rows.
- **Forward only** (ORM Q3): no down migrations. A migration is checked
  against a copy of the database before it runs; rollback is restoring the
  pre-migration backup the runner takes.
- `avra run` applies additive migrations to a dev database itself;
  `create-if-missing` retires the day this lands. A deploy applies only
  committed migrations.

---

## 4. HTTP — routers are components

### 4.1 The router

```avra
export component tasks {
    get list "/" { () -> Task.all() }
    get find "/{id}" { (id: Id<Task>) -> Task.find(id) }
    post create "/" { (t: New<Task>) -> t.insert() }
    patch update "/{id}" { (id: Id<Task>, change: Patch<Task>) -> Task.update(id, change) }
    delete remove "/{id}" { (id: Id<Task>) -> Task.remove(id) }
}
```

- **A component with a body is made of what it holds** — the
  `@composes` mechanism `View` uses (packages/std-ui/src/tree/view.av).
  `@std/http` exports `@composes trait Routes`, and its derive collects
  the body's routes. Nothing new in the language.
- **Embedding is naming.** `tasks {}` goes wherever a route goes: in a
  `server`, a `group`, another router. The same as a named `layer`
  (`guarded`, packages/std-http/src/tests/http_server_decl) — a router
  is listed by its name. `server`'s and `group`'s slot widen from `Route`
  to `Routes` (library).
- **A route's name is its instance name**: `get list "/" { … }` ‡ — one
  grammar alternative in components, a NAME head before the value head.
  The name is the client's method (§5). An unnamed route still compiles;
  it has no client method, and `explain` says so.

### 4.2 The signature decides — HTTP_ROUTES_DX §2, through components

The handler block is a typed arrow; the route component reads its seats ‡
(a `@std/meta` read of an arrow in a `Code` slot) and derives the reader.

| Seat | Filled from |
|---|---|
| named like a path hole (`id`) | the hole, parsed by the seat's type |
| a record, `New<T>`, `Patch<T>` | the body, through `T.decode` → 422 with every issue |
| a defaulted scalar (`page: int = 1`) | the query, `lax` coercion |
| named like a guard above (`me`) | the guard's answer; no such guard above is a compile error |
| `req: Request` | the raw request — the escape hatch, as today |

| Answer | Response |
|---|---|
| `T` | 200, `T` encoded |
| `T?` | 404 when absent |
| a model row from a `post` | 201 + `Location` at the router's `find` |
| `Result<T, ModelError>` | `.Invalid(issues)` 422 · `.Stale` 409 · `.Refused` 403 · other 500 |
| `Stream<T>` | SSE / NDJSON by `Accept` |

The `T?`/`Result` rows need `Respond` over generic types — F2031 ‡, the
one prerequisite DX §6 already lists.

### 4.3 The derived router: `crud Task`

`crud Task` expands to exactly the router in §4.1 — `avra explain crud
Task` prints it, and the printout compiles if pasted (P7, P8). Piece by
piece:

```avra
export component tasks {
    crud Task {
        create: { (t: New<Task>, me: User) -> (t with { owner: me }).insert() }   // replace one
        without: [.remove]                                                     // drop one
    }
    post archive "/{id}/archive" { (id: Id<Task>) -> Task.archive(id) }        // add one
}
```

Settings named by the operation replace its handler (the seats still
decide its reading); `without` drops operations, the same word a form
uses (§6); extra routes are siblings. A handler with real logic is an
`@action` fn the route calls — `post charge "/" { (o: Order) -> charge(o) }`
— so impact and receipts stay where AUTHORITY puts them.

### 4.4 Auth: a guard supplies a seat; a mark scopes rows

- `export guard me { req -> sessions.user(req) }` — a `layer` that answers
  a value (`User?`; absent is a 401) under its own name. Written in a
  `group`, every route below may take `me: User` — filled BY NAME, the
  `ambient` law (SHARING_MODEL §3.1), visible in the signature. A route
  that asks for `me` under no `me` guard does not compile. (Library: the
  `group`'s `expand` is the nearest common ancestor that hands children
  what they need, COMPONENT_EXPANSION §9.)
- Row access is the model's `@owner` field, enforced by the DERIVED
  router: reads filter by it, writes refuse a row `me` does not own (403),
  and `create` fills it. A hand-written route reads `Task.where(…)` with
  no filter — trusted code, listed by `explain` as unscoped. No access
  argument on `model`, no policy object.

---

## 5. The typed client

One router, three faces, chosen by where the call stands:

| Caller | `tasks.list()` is |
|---|---|
| the server process, a test | a plain call to the handler — no socket |
| a view in a browser or app | an **observation**: `Async<List<Task>>` read in render, keyed by route + args, suspending while pending (UI §3.3) |
| another program | `use @board.api.{tasks}` then `tasks.at(url).list()?` |

- **GET is an observation, every other method an action.** Reads are
  cached, prefetchable and live; writes are invoked from handlers and
  answer `Result<T, Issues>` asynchronously.
- **Live, derived.** The compiler knows each route's read set (the models
  its handler queries) and each write's models. A write pushes "Task
  changed" on the page's event channel; observations reading `Task`
  re-ask. Later the same information drives the device replica (UI §3.8)
  with no change to any call site.
- **Optimistic by impact.** A `routine` write (the default for
  `post`/`patch`) applies to the observations holding that row at once
  and settles on the answer; a `reversible` remove (a `@soft_delete`
  model) hides the row and offers undo; a plain `remove` is `destructive`
  and confirms. Every write carries the row's version; a stale one is 409
  and the form re-bases.

```text
$ avra explain tasks
tasks  (api.av:4)            mounted at /api/tasks by app (main.av:9)
  list    GET    /           -> List<Task>   observation · reads Task
  find    GET    /{id}       -> Task?        observation · 404 when absent
  create  POST   /           New<Task> -> Task    routine · 201 · 422 issues: title 1..200
  update  PATCH  /{id}       Patch<Task> -> Task  routine · 409 when stale
  remove  DELETE /{id}       -> Task         destructive · confirm (derived)
  clear   DELETE /done       -> int          destructive · confirm (derived)
  client  board.av: list ×3 (one request) · update · remove · clear · create (form)
  also    OpenAPI /openapi.json · MCP tools: list, find (writes need a mandate)
```

---

## 6. Forms

A form is a projection of a TYPE, and a route's body is a type.

| Written | Form |
|---|---|
| `form tasks.create {}` | the fields of `New<Task>`; submit calls `tasks.create` |
| `form tasks.update(t) {}` | the fields of `Patch<Task>`, filled from `t`; submits only what changed, with `t`'s version |
| `form Task.without(.done) { on submit { t -> … } }` | a model projected (UI_DERIVATIONS §F), for a local use |
| `form charge {}` | an `@action` fn's seats (exists: std-action) |

- **Controls from types**: `string` → field, `bool` → checkbox, an enum →
  picker, `int` → number, `Time` → date, a belongs-to → a picker over the
  observation of its model's `list` (scoped by `@owner`). Labels from
  field names; `.with(.title.label("What needs doing?"))` overrides one.
  A field instance in the block replaces the derived control for that
  field: `field .title { placeholder: "Type a task…" }` ‡ (a field named
  by its path).
- **The same rules on both ends.** The client runs `New<Task>`'s derived
  `checked` per field on blur and in full on submit — the same function
  compiled to wasm, so the message is byte-identical. The server
  re-decodes; the client is a convenience, the decode is the contract.
- **Issues come home.** A 422's `Issues` are decoded by the client and
  each lands in the `error_text` slot of the control at its `path`
  (`title`, `items[3].qty`); an issue whose path no control shows is a
  form-level line. A `@unique` collision arrives as a path issue too, so
  "email is taken" sits under the email field with no code.
- **Submit lifecycle** is the action's: pending/speculative by impact,
  idempotency key per submission (std-action's wire), double-submit
  answered by the first receipt, the draft kept on failure.

---

## 7. Validation everywhere — one rule set

Rules are `@std/validate` fns used as field marks (`@length(1, 200)`).
They exist once, on the model; every projection of the model carries
them (`New<T>` and `Patch<T>` keep each field's marks; `Patch` runs a
field's rules when present and the cross-field `check` on the merged row,
validate §9.13).

| Boundary | Runs | On failure |
|---|---|---|
| a literal in source (`Task { title: "" }`) | the const settler, at compile time | a diagnostic at the literal |
| a form | `checked`, in the client | issues in the field slots, no request |
| HTTP in | `T.decode` at the route seat, before the handler | 422 problem+json, every issue |
| a model write (`insert`/`update`) from anywhere — a route, a job, the CLI, an agent | `checked`, then the SQL | `ModelError.Invalid(Issues)` |
| a constraint the database holds (`@unique`, `CHECK`) | the database | resolved to an `Issue` at the field's path |
| HTTP out (a client reading another service) | `T.decode` of the answer | a typed error naming the path |

Rows read back are not re-checked: the migration law is what keeps them
valid. **The shape, end to end, is `Issue { path, rule, message,
received, fix }`** (packages/std-validate/src/issue.av) — in the
compiler's diagnostic, in `ModelError`, in the 422 body, in the form
slot. One value, never translated.

One codec: `@derive(Decode)` (std-validate) and `@json` (std-json codec)
read the same JSON two ways today. `model` uses Decode; owner decision 8.

---

## 8. What exists, what is new, in what order

| Piece | Today | Change | Kind |
|---|---|---|---|
| `@model`, CRUD, `@unique`, claim registry | packages/std-db/src/db.av | `remove`, `where`, `all`, implies Decode, runs `checked` | library |
| rules, `decode`, `Issues` | packages/std-validate/src/*.av | `checked(t)` over a typed value; SQL `CHECK` projection | library |
| route components, `group`, `server`, `layer` | packages/std-http/src/route.av, server.av | `Routes` composer; slots take `Routes`; `guard` | library |
| `@composes` bodies | packages/std-avrac/src/features/components (landed for `View`) | choose the composer by the body's words, so one file holds a view and a router (today `two_composers` refuses) | compiler ‡ |
| named + value head `get list "/"` | instance grammar has one or the other | one alternative | compiler ‡ |
| typed handler seats | `{ req -> req.params.id }` | meta read of an arrow's seats in a `Code` slot | compiler ‡ |
| `Respond` over `T?`, `Result` | F2031 refuses trait impls over generics | land F2031 | compiler ‡ |
| `ambient` seats | designed (SHARING_MODEL §3) | land | compiler ‡ |
| `model X { }`, `Id<T>`, `New<T>`/`Patch<T>` | decided (COMPONENT_EXPANSION §9), unbuilt | declaring block; type projections | compiler ‡ |
| client stubs, observations | `Fetch<T>`, `fetched` (packages/std-ui/src/app) | derived per route; invalidation channel | library |
| forms | `form`, `field`, `error_text` (packages/std-ui/src/components); std-action's derived form | `form <route>` / `form <Type>` projection | library |
| OpenAPI, MCP | packages/std-openapi, packages/std-mcp | read the router | library |

**Build order — each lands alone, library first.**

1. `checked` in std-validate; `@model` runs it on write and maps `@unique`
   to an `Issue`. *(library)*
2. `remove`/`where`/`all`, `@soft_delete`, `@auto`. *(library)*
3. Relations: belongs-to columns, `Many<T>` as `Query<T>`, `.with`,
   `@cascade`. *(library; `type_named` already resolves a sibling model)*
4. Migrations: snapshot, `avra db diff`, the growth law. *(library + one
   CLI command)*
5. `Routes` composer, routers embedded in `server`/`group`; handlers keep
   `{ req -> … }`. The board runs on a real api here. *(library)*
6. Compiler: named route heads; composer by body. *(compiler)*
7. Compiler: typed handler seats, F2031. Then the DX §2 table, `guard`,
   `crud`. *(compiler, then library)*
8. Client stubs + observations + invalidation; the board loses its state.
   *(library)*
9. Form projection over routes and types; issues to slots. *(library)*
10. `model X { }`, `Id<T>`, `New`/`Patch`, `ambient db`. The short
    spellings arrive last; every earlier step works with
    `@model type`, `int` ids and named projection types. *(compiler)*

---

## 9. Owner decisions — each with a recommendation

1. **Relations (ORM Q2).** Recommend: `Many<T>` declared on the parent,
   inverse inferred, `@via` only when two fields could be the inverse;
   `Many<T>` is a query, never a loaded list.
2. **Down migrations (ORM Q3).** Recommend: forward only, a verified
   backup before each run.
3. **`model X { }` (ORM Q6).** Recommend: yes — it is the decided
   declaring block, and it is what lets the derive add `id` and the
   version instead of asking the author to type `id: int = 0`.
4. **Many-to-many (ORM Q8).** Recommend: the join is a real model.
5. **Derived vs explicit routers.** Recommend both, as one thing: `crud
   Task` is an expansion `explain` prints as the explicit router;
   overrides by operation name, `without` to drop.
6. **Auth shape.** Recommend: a `guard` that supplies a named seat, and
   `@owner` field marks enforced by the derived router only. Capability
   types on model queries (ORM Phase 7) stay later; retention/purge is a
   job, not a mark.
7. **Client naming.** Recommend: `<router>.<route>()` — routers are
   plural nouns, routes verbs; `crud` names `list find create update
   remove` (`delete` is the route component's word).
8. **One JSON codec.** Recommend: `@derive(Decode)` is the door; `@json`
   becomes its alias, then retires.
9. **Live reads.** Recommend: invalidation by model over the page's event
   channel now; the replica (UI §3.8) later, behind the same calls.
