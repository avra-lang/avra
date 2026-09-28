# Adding a projection to the compiler DB

> Describes the `@relation`/`@query` design landing in M2 of
> avra-8sb5.57 (docs/2026_09_26_COMPILER_DB_TOWNHALL.md, §6). Until M2
> lands, that doc is the source of truth; this is the guide a
> contributor reads once it has. Worked example: `avra docs`, the
> first projection built this way.

A projection is a tool that answers a question from the compiler's own
facts — `avra docs`, `avra check`'s rule findings, an error's call
chain, an LSP hover. Every one of them is a THIN QUERY over the `Db`:
no side cache, no hand-written invalidation, no codec.

## Step 0: do you need a new relation?

Most projections don't. Ask first:

1. **Can existing relations answer it?** Write `@query` fns and stop.
   `avra docs` needs no new relation at all — `Decl`, the compiler's
   own declaration table, already carries everything it reads.
2. **Does it need a fact nothing computes yet?** Declare a `@relation`
   and insert its rows from the query that produces them (error
   topology's `ErrorSite` is this case — see the design doc, §6.7).
3. There is no step 3: no codec, no cache, no invalidation code, either
   way.

## The whole API

Two annotations, four field marks. That's it — the derive generates
everything else.

```avra
@relation
type Decl = { id: DeclId, @key module: ModuleId, @key owner: string, @key @index name: string, @key sibling: int, … }

@query
fn raised_by(db: Db, f: DeclId) -> List<TypeId> { … }
```

| Mark | Means | Generates |
|---|---|---|
| a field named `id` | the Db mints it; it IS the typed id | `db.decl(id) -> Decl` |
| `@key f` (one or more) | together, the row's stable name on disk | `db.decl_by_key(k) -> Decl?` |
| `@unique f` | a constraint, naming nothing | `db.user_by_email(v) -> User?`; a second insert is refused |
| `@index f` | a partition | `db.decl_by_name(v) -> List<Decl>` |
| (always) | the whole relation | `db.decl_all() -> List<Decl>` |

`id` is fast in-process identity; `@key` is identity that survives to
the next process. A relation needs no `@key` at all if nothing ever
references its rows by id (a pure membership set, like a call-site
table keyed only by `@index`s).

## Worked example: `avra docs`

Docs reads two things: one name's declaration(s), and every exported
declaration. Both are queries over `Decl`, nothing else:

```avra
@query
fn explained(db: Db, name: string) -> string? {
    let matches = db.decl_by_name(name)
    if matches.length > 1 { return collision_text(matches) }
    let d? = matches.first() else { return null }
    render_doc(db, d)
}

@query
fn dump(db: Db) -> List<DocRow> {
    [dump_row(d) for d in db.decl_all() if d.exported && !(d.kind is .Builtin)]
}
```

Wired to the CLI, with nothing else to write:

```avra
fn explained_decl(name: string, json: bool) -> int {
    let text? = explained(db_for(here()), name) else {
        eprintln("avra: nothing registered under `${name}` — no diagnostic kind or declared fn/type/enum/trait/const wears it")
        return 1
    }
    print_decl(name, text, json)
    0
}
```

That's the whole projection. `render_doc`, `collision_text` and
`dump_row` are the only docs-owned code, and they're pure presentation
— turning a `Decl` row's fields into prose. Nothing about storage,
caching, or process-to-process reuse belongs to docs; the derive owns
all of it.

## What you get for free, and what you still write

Free, from `@relation`/`@query` alone:
- The accessor (`db.decl_by_name`, `db.decl_all`, …).
- A memoized wrapper: every read it makes is recorded, its answer
  persists a hash and a dependency list, and a later process reuses it
  after checking those dependencies' current hashes — no re-parsing,
  no rebuilding what produced them.
- The witness. A lookup by `@index` is invalidated exactly when a row
  is added to or removed from that specific bucket — nothing coarser,
  and nothing to hand-assemble.

Still yours, permanently: the fn body's own logic — what a query reads
and how it renders. `@query` generates the caching around a
computation; it was never going to write the computation.

## Why this is enough (the short version)

Every read a query makes goes through a generated accessor, so there
is no raw table to bypass and no dependency a witness can miss. Every
answer's hash and dependency list persist whether or not its value
does, so a cold process validates a warm answer by checking file (and
env/manifest) digests alone — no parsing, no rebuilding anything, all
the way down to the inputs. A query owns exactly the rows it inserts,
so a relation is derived data that reruns and invalidates itself
rather than a mutable table something else might corrupt.

The mechanics behind those three sentences — how a witness is built,
how an index bucket's hash stays cheap to maintain, how identity
survives across processes — are in the design doc
(docs/2026_09_26_COMPILER_DB_TOWNHALL.md, §6.4-§6.5). A projection
author does not need them to get started; they matter once you're
asking "why didn't my cache invalidate," not before.
