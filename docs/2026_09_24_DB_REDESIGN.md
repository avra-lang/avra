# The db — two types, everything else collapses into them

> **Status:** Phase 1 SHIPPED (2026-09-25) — one kind (`DbRow.Decl`),
> wired to `avra docs <name>`. §1–§3 below are the ORIGINAL target
> design, kept as the shape later phases still aim at; §9 says exactly
> where Phase 1 diverged from it and why, in the same order §1–§6 raise
> the questions. Read §9 alongside §1–§6, not after them.
> **Renamed:** `query/db.av`'s `Db` → `Kernel` (mechanism unchanged) —
> shipped exactly as designed.
> **Shipped, not yet retired:** `Memo<T>`, `Store`/`Stored`, the `Family`
> enum — Phase 1 is additive (`compiler/db.av` is a new file); nothing
> yet routes through it except `avra docs <name>`'s decl/collision
> answer. Retirement is Phase 3's, once every family has migrated.
> **Motivated by:** `avra docs` paying a full package recompile on every
> invocation while `build`/`check` already don't, traced to three separate
> hand-wired caches that don't talk to the real query kernel or each other,
> and to a general excess of names (`Table`, `Memo`, `Db`, `Store`, `Family`)
> for what is fundamentally one idea.
> **Measured (packages/std-avrac, `avra docs LanguageFeature`):** first
> call (cold row) 8.15s, unchanged from before this landed — it still
> derives the whole program. Second call (same unchanged source): 8.05s
> → **0.037s**. `check`'s own cold/warm numbers (11.27s / 0.042s before,
> 10.94s / 0.038s after) are untouched, within noise — this phase never
> touches `check`'s path.

## 1. The two types, and why exactly two

**`Kernel`** (today's `Db`) answers one question: *has anything this depends
on changed.* Revision-tracked, dependency-graph-aware, in-memory only.
Nobody outside `Db`'s own file names it again.

**`Db`** answers the question every consumer actually has: *give me this
thing, or let me tell you what it is.* Built on `Kernel`, backed by disk,
addressed by what something *is* and what it's *called* — never by a
process-local integer a second process couldn't possibly mean the same
thing by.

```avra
type Db = {
    kernel: Kernel,             // private — the existing Key/Verdict/ask/begin/settle, unchanged
    rows: Table<Row>,           // dense array — RowId is just its index
    names: Map<string, RowId>,  // (kind,name) -> RowId, built as rows arrive this process
    root: string,               // where durable copies live
}

export once fn db() -> Db { opened_db(store_root()) }
```

`Table<T>` still exists as code — it's the right dense-array primitive, and
`Db` is built from exactly one instance of it, `Table<Row>`. Nobody writes
`Table<Whatever>` anywhere else again. `Memo<T>`, `Store`, and `Family`
don't survive even as internals — their entire job is now this one type.

## 2. `Row` — every one of the compiler's 19 existing families, one enum

```avra
enum Kind { Decl Source Parsed Typed Manifest Object Ir File }  // grows as needed; exhaustive wherever matched

enum Row {
    Decl(name: string, facts: DeclFacts)
    Source(name: string, file: SourceFile)
    Parsed(name: string, tree: Parsed)
    Typed(name: string, facts: TypeFacts)
    Manifest(name: string, m: Manifest)
    Object(name: string, bytes: Bytes)     // cached machine code
    Ir(name: string, unit: IrUnit)
    File(name: string, doc: List<string>?) // a whole file's own facts, when a row is worth it on its own
}
```

**`DeclFacts` already carries `doc: List<string>?`** — a doc was never a
separate concept from the declaration it describes, so there is no `Doc`
kind and never needs to be one. §4 shows this concretely.

**One real exception:** `Analysis` (today's family, holding
`program: fn() -> Program`) never becomes a `Row` — it holds a closure, and
`disarmed()` already forbids exactly this from surviving even a revision,
let alone a process. Anything a consumer needs from it is read off `Typed`/
`Decl` instead.

## 3. The two verbs, plus the one convenience every pass wants

```avra
impl Db {
    fn insert(row: Row) -> RowId
    fn get(kind: Kind, name: string) -> Row?

    /// The common shape: an answer if one's still good, otherwise
    /// compute it once and remember it — for every process from here on.
    fn demand(kind: Kind, name: string, compute: fn() -> Row) -> Row {
        self.get(kind, name) ?? { let r = compute(); self.insert(r); r }
    }
}
```

### `insert` — reuses `begin`/`settle` exactly as they exist today

```avra
impl Db {
    fn insert(row: Row) -> RowId {
        let k = row.kind()
        let name = row.name()
        let id = self.names.get(name) ?? self.rows.next_id()
        self.kernel.begin(Key { family: k.ordinal(), arg: id })
        self.rows.keep(id, row)
        self.names.set(name, id)
        self.kernel.settle(Key { family: k.ordinal(), arg: id }, fingerprint(row))
        durable_put(k, name, encode(row), self.kernel.pending_deps())
        id
    }
}
```

Called from inside a pass that's mid-computation, `insert` runs inside that
pass's existing `begin`/`settle` bracket — the kernel's `pending` stack
already records "the thing being computed right now read this row," which
is exactly `record_dep`'s existing job, now firing for every row instead of
only the hand-declared families.

### `get` — memory, then a validated disk read, never a bare trust

```avra
impl Db {
    fn get(kind: Kind, name: string) -> Row? {
        let id? = self.names.get(name) else { return self.recalled(kind, name) }
        match self.kernel.ask(Key { family: kind.ordinal(), arg: id }) {
            .Reuse -> self.rows.at(id),                 // bare array read — today's speed, untouched
            .Compute or .Cycle -> self.recalled(kind, name),
        }
    }

    fn recalled(kind: Kind, name: string) -> Row? {
        let record? = durable_get(kind, name) else { return null }
        if !record.deps.all((d) -> current_content_hash(d) == d.content_hash) { return null }
        let row = decode(record.bytes)!
        self.insert(row)   // warms it — every ask after this one, this process, hits Reuse
        row
    }
}
```

## 4. Worked example — a doc, associated with a declaration

```avra
fn capture_decl(d: Decl, store: NodeStore) {
    let facts = DeclFacts {
        doc: store.doc_comment(d.stmt) ?? store.file_doc(),
        sig: sig_of(d),
        annotations: store.annotations_of(d.stmt),
    }
    db().insert(Row.Decl(qualified_name(d), facts))
}

fn doc_at(package: string, name: string) -> List<string>? {
    match db().get(Kind.Decl, "${package}.${name}") {
        .Decl(_, facts) -> facts.doc,
        _ -> null,
    }
}
```

No separate association step exists to write, because there was never a
separate concept to associate.

## 5. Worked example — the comment changes

```avra
fn typed_decl(package: string, name: string) -> DeclFacts {
    match db().get(Kind.Decl, "${package}.${name}") {
        .Decl(_, facts) -> facts,                        // unchanged since it was cached — skip everything below
        _ -> {
            let facts = derive_decl_facts(package, name)  // re-parse, re-type — the expensive path
            db().insert(Row.Decl("${package}.${name}", facts))
            facts
        },
    }
}
```

Edit the doc comment, run a fresh process, ask for it again: `Db.get` finds
nothing warm (a new process starts with an empty `names` map), falls to
`recalled`, finds the old durable record, and walks its recorded
dependencies — one of which is `{ kind: Source, name: "file.av",
content_hash: OLD }`. `current_content_hash` for a `Source` dependency is
"read the file now, hash it" — the edit changed the bytes, so the hash no
longer matches, `recalled` returns `null`, and `typed_decl` takes the real
path: re-derive, re-insert. The new record **overwrites** the old one at the
identical `(kind, name)` key — every process after this one sees the new
doc, not just this one, because the stale record no longer exists to be
found by anyone.

No revision counter to propagate, nothing to invalidate by hand. The
dependency's own current content is the only fact that matters, checked
fresh at the moment it's asked.

## 6. What retires, precisely

| today | becomes |
|---|---|
| `query/memo.av`'s `Memo<T>` | deleted — `Db.get`/`insert`/`demand` do its whole job, once, for every kind |
| `compiler/store/store.av`'s `Store`/`Stored` | deleted — mechanics move inside `Db`'s private `durable_get`/`durable_put` |
| `Workspace`'s ~19 `Memo`/`Table` fields + the `Family` enum | one field: `db: Db`; `Family`'s job is now `Row`'s own variants |
| `record.av`'s `record_key`/`record_cached`, `build.av`'s `program_key`/`held_objects`, `derive.av`'s `checked()` `Warn` cache | ordinary `db().get`/`demand` calls against `Decl`/`Object`/whichever `Kind` already holds what they need |
| `query/db.av`'s `Db` type | renamed `Kernel` — same file, same algorithm, freed name |

## 7. Migration — phased, because rewiring 19 families is real surgery

1. **Phase 1 — SHIPPED.** Rename `Db` → `Kernel`. Build `Db`/`DbRow`/
   `DbKind` per this document, narrowed as §9 describes. Migrate `avra
   docs <name>`'s decl/collision answer end to end — NOT `Sig`, deferred
   to Phase 3 alongside every family with real resolved-type dependency
   fan-out. Proved fast with real timing (front-matter above), not an
   assertion.
2. **Phase 2.** Migrate `Source`/`Manifest`/`Object` for `build`'s
   held-linking; delete `record.av`'s bespoke reconstruction.
3. **Phase 3.** Migrate the remaining families (`Parsed`, `Typed`,
   `ConstTyped`, `Folded`, ...) one at a time, each verified against the
   full test suite before the next.

Nothing in phases 2–3 is designed in detail here — each one gets its own
pass once phase 1 has proven the shape holds under real load.

## 8. Honest open questions

- **Dependency-list size in practice.** `deps_still_current`'s walk is
  bounded by distinct queries touched, not by call count — but real fan-out
  for something like `Typed` on a large file is an empirical question.
  Measure before assuming it's free.
- **Compaction.** Durable records accumulate forever with no GC story yet.
  Needed before this ships at scale, not designed here.
- **`current_content_hash` for a `Row` dependency** (not a raw file) is that
  row's own already-computed fingerprint — cheap, but worth confirming
  there's no family where recomputing it is itself expensive.

## 9. Where Phase 1 actually landed, and why

Real code always narrows a sketch. Six divergences from §1–§6, each
found by building it rather than by re-reading the design:

1. **`Row`/`Kind` are `DbRow`/`DbKind`.** `compiler/` is one module —
   every file in it shares a namespace with no `use` needed — and it
   already had an unrelated private `Row` (`record.av`, interface-record
   reconstruction) and an unrelated `DeclFacts` (`features/decls.av`, a
   declaration's full resolved facts). `Row`/`Kind`/`DeclFacts` would
   have silently shadowed them. Renamed to `DbRow`/`DbKind`/`DocFacts` —
   the `Db`-owning prefix is now the actual collision-avoidance
   convention for anything this file adds later, not merely this
   round's fix.
2. **`qualified()` is `db_qualified()`.** Same reason: `compiler/
   packages.av` already has a `qualified(ModulePath, Package) ->
   ModulePath` for module-path resolution. Caught by the type checker
   immediately — wrong argument types at both call sites — not by
   inspection.
3. **`Db` does not hold a `Kernel` yet.** §1's sketch wires one in from
   the start. Phase 1's one row kind has no in-process dependency to
   track — a CLI run is one-shot, nothing re-asks a warm row and needs
   telling it went stale mid-process — so there is nothing yet for a
   `Kernel` to verify. Per this file's own rule (F2055's cousin for
   structs: don't carry a field nothing reads), the field is absent
   until a consumer needs it — almost certainly Phase 2 or 3, once a
   `Memo`-backed family routes its own asks through `Db` and genuinely
   has one query depending on another within a process.
4. **Validity is two witnesses, not a dependency list.** §3's
   `get`/`recalled` sketch walks a general `deps: List<Key>` and asks
   each one's `current_content_hash`. `DocFacts` instead carries its
   package's file-LISTING digest (`current_listing_digest`) plus one
   `FileWitness{path, digest}` per file the answer actually read. A
   listing digest is what catches a collision the original design's
   per-file deps would have missed entirely: a THIRD module declaring
   the same name, in a file nothing has ever read before, changes
   nothing on any recorded dependency's list — only the package's own
   shape moving is a witness to it. Verified live: a two-way collision
   (`alpha.Foo`, `beta.Foo`) correctly widened to three
   (`alpha.Foo`, `beta.Foo`, `gamma.Foo`) the moment `gamma/mod.av` was
   added, with nothing in the cached answer's own file list touched.
   This narrowing is Phase 1's alone — `Sig`/`Typed` in Phase 3 depend
   on RESOLVED types reaching into other files by name, not by
   membership in a listing, and need the general walk §3 describes.
5. **The store parameter, not a captured global.** §1 sketches
   `once fn db() -> Db { opened_db(store_root()) }` — a zero-argument
   constructor that already knows where its durable rows live. `once
   fn` takes no parameters (a language law, not a style choice), and
   `compiler/db.av` sits in `std-avrac`, below the CLI's `disk_host`/
   `here()` that actually knows a process's root — so `Db` cannot
   discover its own store. Every accessor takes an explicit
   `store: Store` (built by the caller via `store_at(build_cache_root(
   root_workspace(root)))`, the same construction `Workspace.checked`
   already uses for its own `Warn` cache). `Db`'s in-memory half stays
   the one `once`-held, store-agnostic table; the store is a parameter
   at every door, never a field.
6. **`@derive(Rows)`'s generated accessors use static parameter names.**
   A real, narrow template-engine limitation, found empirically and
   root-caused with a minimal reproduction before working around it: a
   name spliced into a PARAMETER's declaration (`${key}: ${key_ty}`)
   and the SAME name spliced again as an EXPRESSION reference later in
   the SAME generated body (`${name(key)}`) do not resolve to one
   binding — the second reads as undefined, even though both holes were
   filled from the identical string. A statically-written written
   parameter referenced statically works with no such issue, which is
   what `compiler/rows_derive.av` does now: every generated accessor's
   seats are named `key`/`facts` literally, in the template's own text,
   never through a hole — invisible to callers, who fill them
   positionally. Worth a real repro report against the template engine
   itself; not investigated further here since the workaround costs
   nothing a caller can see.
