# Adding a projection to the compiler DB

> Describes the `@relation`/`@query` design (docs/2026_09_26_COMPILER_DB_TOWNHALL.md,
> §6). **Status:** `@relation`, its accessors and `@query` are on main
> and gate-verified — the plugin half below is a real program. The
> durable pack for relations and the compiler's own relations (`Decl`,
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

Two annotations, four field marks and a field named `id`. The derive
writes the rest.

```avra
@relation
type Decl = { id: int, @key name: string, @index owner: string, exported: bool }
```

Accessors are static fns on the relation (design doc §4, decision 9) —
one spelling for the compiler's relations and a plugin's:

| Mark | Means | Generates |
|---|---|---|
| a field named `id` | the Db mints it on insert; it is an `int`, or a `@dense` type (`use @std.meta.{dense}`, a record of one int) | `Decl.get(db, id) -> Decl?` |
| `@key f` (one or more fields) | together, the row's stable name; a known key REPLACES its row, keeping the id | `Decl.by_key(db, DeclKey { f: v }) -> Decl?` |
| `@unique f` | a lookup that answers one row; an insert of a value another row holds is refused (a nullable field: among present values — any number of rows may be null) | `Decl.by_f(db, v) -> Decl?` |
| `@index f` | a lookup that answers a list, in id order; a list field files its row under every element, a nullable field only when present (`by_f(db, v)` takes the value itself; a null is in no bucket) | `Decl.by_f(db, v) -> List<Decl>` |
| `@local f` | a column this process alone reads: out of the stable hash and the codec | `DeclStored`, the row without its `@local` columns, which `Decl.decoded(bytes)` answers |
| (always) | the rows | `Decl.insert(db, f: v, …) -> Decl`, its fields as named seats with no `id` (the row as stored; `Result<Decl, InsertRefused>` when a field is `@unique`), `Decl.all(db) -> List<Decl>` |

A field is an `int`, a `bool`, a `string`, an enum (carried by its
variant's name), a record of those (a column, hashed and written field by
field), or a list or nullable of them. `@index` alone takes arguments,
`ordered` and `grain`, each once: `@index(grain)` names the bucket `get`
records a row's read through, on one field only.

`@query fn q(db, …)` (`use @std.relation.{query}`) is the second
annotation: a fn over a Db whose answer is kept per call. A kept answer
is reused until a write to a relation the query read, then the body
reruns. A QUERY WRITES NO ROWS OF ITS OWN: an insert in its body with no
owner's run open is refused. Rows that a computation produces belong to
a NAMED OWNER — `let o = db.owner_named("icons")`, `db.opened_run(o)`,
the inserts, `db.closed_run(o)` — and a rerun of that owner replaces
them (a keyed row keeps its id, a row the run no longer writes is
dropped). Two owners writing one row are refused, and a relation an open
run has written is read by no one until the run closes. `Rel.prior(db)`
is gone with query-owned rows: what a run left is read after it closes,
with the relation's ordinary lookups. ORM's program
`packages/std-relation/src/tests/query/` pins each of these. Answers and
rows live in memory for the life of the Db; persisting them is
avra-8sb5.57.6.

`id` is fast in-process identity; `@key` is identity that will survive
to the next process. A relation needs no `@key` if nothing updates or
references its rows.

## Worked example: `avra docs` (on paper)

Docs reads two things: one name's declaration(s), and every exported
declaration. `@query` is built, but the compiler's own `Decl` relation is
not (avra-8sb5.57.8), so this is a sketch, not a program:

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
use @std.relation.{relation, query}
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
/// order they were first written. Its answer is kept per call and rerun
/// after a write to `Todo`.
@query
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
updated row kept its id and the count stayed three. The second line for
`ann` shows the rewrite because the write made `open_for`'s kept answer
rerun.

**To update a row, key it.** Writing a known `@key` replaces that row.
Outside a `@query`, a keyless relation only appends: three identical
inserts are three rows, and no verb removes or replaces one
(`Todo.remove` is refused: "`Todo` has no static fn `remove`"). A plain
fn that inserts what it derives, run twice against one Db, doubles its
rows; written as a `@query`, its rerun replaces them. `@key` may sit on
several fields, which together are the key: `Todo.by_key(db, TodoKey {
owner: o, title: t })`.

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
| a field of `float`, a named type (`type OwnerId = int`), or a generic `T`, unless it is `@local` | `kind_not_carried` — fields carry int, bool, string, enums, records of those, and lists and nullables of them |
| an `id` that is not an `int` or a `@dense` type (`id: CallId`) | `id_not_int` |
| a `@dense` id held anywhere but the row's `id` or a `@local` column | `dense_unmarked` — a dense id means nothing in another process |
| `@key` and `@local` on one field | `key_local` — a key is the row's stable name |
| a list field under `@key` or `@unique` | `many_valued` — a list files its row under every element, so mark it `@index` |
| a lookup mark on any kind but int, bool, string (an enum or `@dense` id included), or a list or nullable of one | `lookup_kind` |
| a nullable field under `@key` or `@index(grain)` | `null_bucket` — a null is in no bucket, and a key or a grain names one |
| `@unique @index` on one field | `answer_clash` |
| a mark twice, or a mark outside the four (`@key`, `@unique`, `@index`, `@local`) | `duplicate_mark`, `unknown_mark` |
| an argument on a mark, other than `@index(ordered)` or `@index(grain)` | `mark_args` |
| a second `@index(grain)` in one relation | `grain_twice` — `get` records a row's read through one bucket |
| a field named like a generated member: `insert`, `get`, `all`, `encoded`, `stable_hash`, … | `name_collision` |
| a field named `db`, the Db's seat on `insert` | `seat_collision` |
| a `@unique` or `@index` field named `key`, beside `@key` fields | `lookup_collision` — the `@key` fields' lookup is `by_key` |

Store what a refused kind stands for as one that is carried — a float as
an int in a fixed unit — or mark the column `@local`, which holds any
type and stays out of the hash and the codec.

### What misleads today

Found by using the accessors as a plugin author would:

- `insert` takes the row's fields as seats and no `id`; writing one is
  refused at the call, in the typer's words: "`Todo.insert` has no seat
  named `id`", help "its seats are `db`, `title`, `done`".
- There is no remove verb: `Todo.remove(db, id)` is refused, "`Todo` has
  no static fn `remove`". Key the row to update it, or let a `@query`
  own the rows it writes (see "To update a row, key it").
- `@query` written in the root package's own files — the package you
  `avra run` or `avra test` — is refused, `annotation.wrap_missing`:
  "`@query` asks to wrap `f$body`, and its `source` declares no fn of
  that name". The same text works in a package another package depends
  on, as the plugin above does, and in `@std/relation`'s own tests
  (avra-8sb5.57.4.15).
- The generated `TodoKey` and `TodoStored` records are not exported with
  `export type Todo`, so another package cannot write `TodoKey { … }` and
  `by_key` is out of its reach: export a fn of your own that calls it
  (avra-8sb5.57.4.16).

Two names to avoid, from the language and not the derive: `Task` is a
built-in type, and `level` is reserved.

### Not yet

| You want | Status | Ticket |
|---|---|---|
| a query's answer persisted with its dependency list | not built — answers and rows are memory for the life of the Db | avra-8sb5.57.6 (M3) |
| a fixpoint over a plugin relation | the Kernel's fixpoint mode landed; `@query` takes no `fixpoint` argument (`fixpoint` is not defined), and a query reading a relation it writes is refused | avra-8sb5.57.13.1 |
| a plugin's rows in the durable pack | not built — rows are memory for the life of the Db | avra-8sb5.57.6 (M3) |
| a `float` or a named type in a hashed column | refused at the field; hold it in a `@local` column or store an int | — |
| a plugin's relations in the compiler's own Db | two `Db` types today | avra-8sb5.57.4.7 |

## What you get for free, and what you still write

Free from `@relation`: the accessors above, a stable hash over every
field but the `@local` ones, a codec, and per-Db row stores with their
indexes kept current on each insert.

Free from `@query`: an answer kept per call and rerun only after a write
to a relation it read, and the rows it writes owned — replaced on rerun,
refused when two queries write one key.

Still to come with the durable pack (avra-8sb5.57.6): an answer
persisted with its dependency list, so a later process reuses it after
checking those dependencies' current hashes, no re-parsing.

Still yours, permanently: the fn body's own logic — what a query reads
and how it renders. The derive generates the plumbing around a
computation; it was never going to write the computation.

## Why this is enough (the short version)

Every read goes through a generated accessor, so there is no raw table
to bypass and no dependency a witness can miss. By design every answer's
hash and dependency list persist whether or not its value does, so a
cold process validates a warm answer by checking file (and env/manifest)
digests alone — the durable half is avra-8sb5.57.6. A query owns exactly
the rows it inserts, so a relation is derived data that reruns and
invalidates itself rather than a mutable table something else might
corrupt.

The mechanics behind those three sentences — how a witness is built,
how an index bucket's hash stays cheap to maintain, how identity
survives across processes — are in the design doc
(docs/2026_09_26_COMPILER_DB_TOWNHALL.md, §6.4-§6.5). A projection
author does not need them to get started; they matter once you are
asking "why didn't my cache invalidate," not before.
