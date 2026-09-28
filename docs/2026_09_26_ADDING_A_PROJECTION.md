# Adding a projection to the compiler DB

> Describes the `@relation`/`@query` design (docs/2026_09_26_COMPILER_DB_TOWNHALL.md,
> §6). **Status:** `@relation` and its accessors are on main and
> gate-verified — the plugin half below is a real program. `@query`, the
> durable pack for relations, and the compiler's own relations (`Decl`,
> …) are not built; where a section describes them it says so and names
> the ticket. Until they land, the design doc is the source of truth.

A projection is a tool that answers a question from the compiler's own
facts — `avra docs`, `avra check`'s rule findings, an error's call
chain, an LSP hover. Every one of them is a THIN QUERY over rows: no
side cache, no hand-written invalidation, no codec.

## Step 0: do you need a new relation?

Most projections don't. Ask first:

1. **Can existing relations answer it?** Write query fns over them and
   stop. `avra docs` needs no new relation — the compiler's own
   declaration table already carries everything it reads.
2. **Does it need a fact nothing computes yet?** Declare a `@relation`
   and insert its rows from the code that knows them (error topology's
   `ErrorSite` is this case — design doc §6.7). A plugin is always this
   case: see "Adding a relation from a plugin".
3. There is no step 3: no codec, no hash, no index code, either way.

## The whole API

Two annotations, three field marks and a field named `id`. The derive
writes the rest.

```avra
@relation
type Decl = { id: int, @key name: string, @index owner: string, exported: bool }
```

Accessors are static fns on the relation (design doc §4, decision 9) —
one spelling for the compiler's relations and a plugin's:

| Mark | Means | Generates |
|---|---|---|
| a field named `id` | the Db mints it on insert; it must be `int` | `Decl.get(db, id) -> Decl?` |
| `@key f` (one or more fields) | together, the row's stable name; a known key REPLACES its row, keeping the id | `Decl.by_key(db, DeclKey { f: v }) -> Decl?` |
| `@unique f` | a lookup that answers one row; an insert of a value another row holds is refused | `Decl.by_f(db, v) -> Decl?` |
| `@index f` | a lookup that answers a list, in id order | `Decl.by_f(db, v) -> List<Decl>` |
| (always) | the rows | `Decl.insert(db, f: v, …) -> Decl`, its fields as named seats with no `id` (the row as stored; `Result<Decl, InsertRefused>` when a field is `@unique`), `Decl.all(db) -> List<Decl>` |

`@query fn q(db, k)` is the second annotation: a memoized, dependency-
recorded, persisted wrapper. **Not built** (avra-8sb5.57.4.6): today a
query is a plain fn, recomputed on every call.

`id` is fast in-process identity; `@key` is identity that will survive
to the next process. A relation needs no `@key` if nothing updates or
references its rows.

## Worked example: `avra docs` (on paper)

Docs reads two things: one name's declaration(s), and every exported
declaration. Written against the design — the compiler's own `Decl`
relation is not built yet (avra-8sb5.57.8), so this is a sketch, not a
program:

```avra
@query
fn explained(db: Db, name: string) -> string? {
    let matches = Decl.by_name(db, name)
    if matches.length > 1 { return collision_text(matches) }
    let d? = matches.first() else { return null }
    render_doc(db, d)
}

@query
fn dump(db: Db) -> List<DocRow> {
    [dump_row(d) for d in Decl.all(db) if d.exported && !(d.kind is .Builtin)]
}
```

`render_doc`, `collision_text` and `dump_row` are the only docs-owned
code, and they are pure presentation — turning a `Decl` row's fields
into prose. Nothing about storage, caching or process-to-process reuse
belongs to docs.

## Adding a relation from a plugin

A plugin is a package that declares a relation and the fns that read
it. Nothing in it names the compiler. The example below is a real
program test — `packages/std-relation/src/tests/plugin_guide/`, run by
the gate, its output pinned — and the code here is excerpted from it,
line for line.

**The plugin package** (`plugin/src/todos.av`) declares the relation and
a query over it:

```avra
use @std.relation.{relation}
use @std.relation.db.{Db}

/// One task. The Db mints `id`; `title` is the row's key, so writing a
/// title again replaces its row and keeps its id; `owner` files a row
/// under its owner.
@relation
export type Todo = { id: int, @key title: string, @index owner: string, done: bool }

/// Add a task, or update the one already so titled.
export fn record(db: Db, owner: string, title: string, done: bool) -> Todo {
    Todo.insert(db, title: title, owner: owner, done: done)
}

/// A query over the relation: an owner's tasks not yet done, in the
/// order they were first written.
export fn open_for(db: Db, owner: string) -> List<Todo> {
    [t for t in Todo.by_owner(db, owner) if !t.done]
}
```

**A projection** (`src/main.av`) reads it and renders one line:

```avra
use @std.relation.db.{new_db, Db}
use @example.todos.{Todo, record, open_for}

fn agenda(db: Db, owner: string) -> string {
    let titles = [t.title for t in open_for(db, owner)]
    "${owner}: ${if titles.is_empty() { "nothing open" } else { titles.join(", ") }}"
}
```

The program writes three tasks, re-writes one by its key, and prints
`ann: write the guide, red-team the accessors | ann: red-team the
accessors | bo: review | cy: nothing open | id kept | 3 rows` — the
updated row kept its id and the count stayed three.

**To update a row, key it.** Writing a known `@key` replaces that row.
A keyless relation only appends: three identical inserts are three rows,
and nothing removes or replaces one. Re-running a projection that
inserts what it derives, against one Db, doubles its rows. `@key` may
sit on several fields, which together are the key: `Todo.by_key(db,
TodoKey { owner: o, title: t })`.

**A `@unique` field guards its value.** An insert that repeats a value
another row holds is not stored: a relation with a `@unique` field
inserts as `Result<T, InsertRefused>`, a type named by `use
@std.relation.refused.{InsertRefused}`. On the refusal,
`e.describe().message` reads "`Account.email` is `@unique`, and row 0
already holds `ann@x`". Re-writing a row under its own key is no repeat,
and may change its `@unique` value: the old value's lookup then answers
none. A relation with no `@unique` field inserts as plain `T`.

**Where the rows live.** In a `Db` from `@std.relation.db.new_db()`, in
memory, for as long as it lives. Each Db keeps its own rows. This is not
the compiler's own `Workspace.db`: they are two different `Db` types
today (avra-8sb5.57.4.7). `db.close()` lets every relation's rows go, and
any later reach into that Db — insert, get, all, a lookup — traps,
naming it: "relation rows reached through Db 0 after it closed — a closed
Db's rows are gone; open a new Db".

**Two plugins may share a relation name.** A relation's stable name is
its module's full import path plus its name (`@example.a.Todo`,
`@example.b.Todo`); the stores and hashes are separate.

### What the derive refuses

Each is spoken at the field, with a help, as `error[@std/relation:<kind>]`.
All were compiled to check:

| Declaration | Refusal |
|---|---|
| a field of `float`, a named type (`type OwnerId = int`), an enum, or a generic `T` | `kind_not_carried` — fields carry int, bool, string, and lists and nullables of them |
| `id: CallId`, or any `id` that is not `int` | `id_not_int` |
| a lookup mark on `string?`, or any kind but int, bool, string | `lookup_kind` |
| `@unique @index` on one field | `answer_clash` |
| a mark twice, or a mark outside the three (`@key`, `@unique`, `@index`) | `duplicate_mark`, `unknown_mark` |
| a field named like a generated member: `insert`, `get`, `all`, `encoded`, `stable_hash`, … | `name_collision` |
| a field named `db`, the Db's seat on `insert` | `seat_collision` |
| a `@unique` or `@index` field named `key`, beside `@key` fields | `lookup_collision` — the `@key` fields' lookup is `by_key` |

Store what a refused kind stands for as one that is carried — a float as
an int in a fixed unit, an enum as its name.

### What misleads today

Found by using the accessors as a plugin author would:

- `insert` takes the row's fields as seats and no `id`; writing one is
  refused at the call, in the typer's words: "`Todo.insert` has no seat
  named `id`", help "its seats are `db`, `title`, `done`".
- There is no remove verb, and asking for one is answered as if it were
  an enum's: `Todo.remove(db, id)` is `type.unknown_prop`, "`Todo` is a
  record, not an enum". Key the row to update it (see "To update a row,
  key it"); removal arrives with `@query`.

Two names to avoid, from the language and not the derive: `Task` is a
built-in type, and `level` is reserved.

### Not yet

| You want | Status | Ticket |
|---|---|---|
| a memoized, dependency-tracked, persisted query (`@query`) | not built — your query is a plain fn | avra-8sb5.57.4.6 |
| a fixpoint over a plugin relation | the Kernel's fixpoint mode landed; a plugin cannot spell it until `@query` exists | avra-8sb5.57.13.1, .57.4.6 |
| a plugin's rows in the durable pack | not built — rows are memory for the life of the Db | avra-8sb5.57.6 (M3) |
| typed-id, enum or float fields, as the design doc's own relations use (§6.3, §6.7) | refused today, by name, at the field | — |
| a query that owns its rows and replaces them on rerun | not expressible — no remove verb, no `@query` | avra-8sb5.57.4.6 |
| a plugin's relations in the compiler's own Db | two `Db` types today | avra-8sb5.57.4.7 |

## What you get for free, and what you still write

Free from `@relation`, today: the accessors above, a stable hash over
every field, a codec, and per-Db row stores with their indexes kept
current on each insert.

Free from `@query`, once it exists: memoization, recorded reads, early
cutoff on the hash, and an answer persisted with its dependency list —
so a later process reuses it after checking those dependencies' current
hashes, no re-parsing.

Still yours, permanently: the fn body's own logic — what a query reads
and how it renders. The derive generates the plumbing around a
computation; it was never going to write the computation.

## Why this is enough (the short version)

Every read goes through a generated accessor, so there is no raw table
to bypass and no dependency a witness can miss. Every answer's hash and
dependency list persist whether or not its value does, so a cold
process validates a warm answer by checking file (and env/manifest)
digests alone. A query owns exactly the rows it inserts, so a relation
is derived data that reruns and invalidates itself rather than a
mutable table something else might corrupt.

The mechanics behind those three sentences — how a witness is built,
how an index bucket's hash stays cheap to maintain, how identity
survives across processes — are in the design doc
(docs/2026_09_26_COMPILER_DB_TOWNHALL.md, §6.4-§6.5). A projection
author does not need them to get started; they matter once you are
asking "why didn't my cache invalidate," not before.
