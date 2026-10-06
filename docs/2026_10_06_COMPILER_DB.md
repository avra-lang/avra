# The compiler DB — final design

2026-10-06 · branch `db-design` · checked against `origin/main` @ `05fe643`
Inventory of prior work: [`2026_10_06_DB_INVENTORY.md`](2026_10_06_DB_INVENTORY.md) ·
Hand-offs: [`2026_10_06_DB_HANDOFFS.md`](2026_10_06_DB_HANDOFFS.md)

**Supersedes** (§12 says exactly what dies): the townhall's §6.5 and §6.6,
`2026_09_24_DB_REDESIGN.md`, `2026_10_05_BUILD_TIME_SOURCES.md` §1, and the "M3 layer"
asks in tickets `.57.101.11/.12`. It **absorbs** the townhall's §4, §6.2–§6.4, §6.5a.

Labels: `READ` file:line opened by me · `READ(agent)` see the inventory appendices ·
`PROBED` run · `MEASURED (source)` · `ESTIMATED` · **`PROPOSED`** = new in this design.

---

## 1. The laws

| # | law | one line |
|---|---|---|
| **L1** | **One input door.** | Anything outside the program is an *input*: a stable name and the digest of exactly what was read. Only `Host` reads the world, and only for the Db. |
| **L2** | **One query door.** | A derived fact is a `@query`: a pure fn of its key that reads inputs, rows and other queries. The kernel records what it read. Nobody writes a dependency by hand. |
| **L3** | **One saved-answer rule.** | A saved answer is its value plus the list of what it read, each with its digest, written by the kernel in one commit. It is valid iff every digest still matches. There is no other validity check anywhere. |
| **L4** | **Two grains, one graph.** | *Fine* cells live in one process and never persist. *Kept* answers and *inputs* are the durable grain. A kept answer's list holds its **direct durable reads**: the inputs and the kept answers it read, seen through any fine cells in between. |
| **L5** | **Names are stable, ids are local.** | A durable name never holds a dense id, an offset or an ordinal. A saved value holds keys, and spans relative to its anchor declaration. |
| **L6** | **Everything is a relation.** | Every fact a consumer reads is a typed row of a `@relation` with declared indexes. No walk over the program outside a query. |
| **L7** | **The digest covers the whole value.** | The bytes saved are the bytes digested; both come from the row type's derived codec. |
| **L8** | **Partly held is never worse than cold.** | Validation happens before any derivation; one derivation is alive at a time. Time and peak memory of a partly-held run ≤ a cold run. A gate holds it. |
| **L9** | **Every answer can say why.** | One command prints any answer's value, what it read, what moved, and who reads it. |
| **L10** | **Purity is checked, not trusted.** | A keeper refuses a world read outside the door; a double-run mode recomputes kept answers and traps on disagreement. |

The owner's rule is L3 word for word. L4 is the one refinement, forced by a measurement:
recording at the kernel's own grain is **≥51.6 M deps** on the cli and cannot persist
(MEASURED, townhall §6.5a, READ `avra/docs/2026_09_26_COMPILER_DB_TOWNHALL.md:2427-2433`).
So the list is taken at the grain that is saved — a few thousand answers, tens of reads each.

---

## 2. What a consumer sees (the whole surface)

Seven things. Five exist today; two are new.

| # | thing | status |
|---|---|---|
| 1 | `Db` — the handle every read takes | on main (`@std.relation.db.Db`) |
| 2 | `@relation type R` with `@key`, `@index` → `R.insert / get / by_<index> / all` | on main, PROBED |
| 3 | `@query fn q(db: Db, k…) -> T` | on main, PROBED |
| 4 | `@kept` — this query's answer is saved across runs | **PROPOSED** (a stacked mark parses today: PROBED) |
| 5 | the nine world reads: `text bytes range listing exists env tool target pinned` (all take `db`) | **PROPOSED** as `@std/source`; `@input` (on main) stays as the escape hatch |
| 6 | `Blob` — big bytes by content digest | **PROPOSED** |
| 7 | `avra explain <anything>` | **PROPOSED** (replaces `avra cache why`) |

PROBED today (`/tmp/db-design/pk`, `avra-ui-own-state/build/avra` @ `6c9add3`, 0.76 s, prints `/a,/c 3 true`):

```avra
use @std.relation.{relation, query, input}
use @std.relation.db.{Db, new_db}
use @std.io.{read_text}

@relation
type Route = { id: int, @key path: string, @index verb: string, handler: string }

@input
fn file_text(_db: Db, path: string) -> string { read_text(path) catch "" }

@query
fn gets(db: Db) -> List<string> { [r.path for r in Route.by_verb(db, "GET")] }

@query
fn line_count(db: Db, path: string) -> int { file_text(db, path).split("\n").length }
```

The design does not add a third spelling. It finishes this one: the compiler's own facts
become these relations and queries, world reads go through item 5 instead of `@std.io`,
and `@kept` makes an answer outlive the process under L3.

### 2.1 Reading the world (L1)

**PROPOSED** `@std/source` — the same nine fns serve a plugin at compile time (they cross
to the compiler's `Host`) and a program at run time (a quiet Db reads `@std.io`):

```avra
use @std.source.{text, bytes, range, listing, exists, env, tool, target, pinned}

text(db, "assets/schema.sql")            // string?   — null when absent; absence is recorded
bytes(db, "assets/logo.png")             // Bytes?
range(db, "assets/big.bin", 0, 512)      // Bytes?    — digest covers those 512 bytes only
listing(db, "assets/icons")              // List<Entry>? — names + kinds, sorted; null = no dir
exists(db, "tests/x.expected")           // bool
env(db, "DATABASE_URL")                  // string?   — unset ≠ empty
tool(db, "wasm-opt")                     // Tool?     — resolved path + identity
target(db)                               // Target
pinned(db, "https://…/pet.yaml", "sha256:…")   // Bytes — refused unless the pin matches
```

A path is relative to the package that declares the caller. That is its stable name
(`@acme/icons:assets/icons`); an absolute path never enters a name (L5).

### 2.2 Declaring and asking facts (L2, L6)

A feature or a plugin declares rows and queries the same way. Keys and rows are typed;
there are no strings to match.

```avra
@relation
export type Icon = { id: int, @key name: string, @index set: string, svg: Blob }

@kept @query
export fn icons_in(db: Db, dir: string) -> List<Icon> {
    [Icon.insert(db, name: e.name, set: dir, svg: blob(db, bytes(db, "${dir}/${e.name}")!))
        for e in listing(db, dir) ?? [] if e.name.ends_with(".svg")]
}

icons_in(db, "assets/icons")             // ask — typed key, typed rows
Icon.by_set(db, "assets/icons")          // index read — recorded per bucket
```

A query owns the rows it inserts; a rerun replaces exactly its own (on main: READ
`std-relation/src/db.av:7-13`). A kept answer saves **its value and its owned rows** together
(today only a run that wrote no rows persists — READ `db.av:550-562`; §4.4 lifts that).

### 2.3 The compiler's facts, readable by any package (L6)

**PROPOSED**: `@std/meta` re-exports the compiler's core relations, minus `@local` columns
(townhall §4.10), and `compiling()` hands compile-time code the compile's own Db.

| relation | key | indexes | on main as |
|---|---|---|---|
| `Package` | name | — | hand list |
| `Module` | dotted path | package | `@relation` (`features/file_rows.av`) |
| `File` | package-relative path | module | `@relation` |
| `Decl` | module · owner · name · kind | name, word, **marks**, owner, file | `@relation` (`features/decl_rows.av`) |
| `Field`, `Variant`, `Param` | decl key · name | decl | inside signatures (**new rows**) |
| `Impl` | trait key · type key | trait, type | full scan `implementors_of` (`features/decls.av:2623`, READ(agent C2)) |
| `Ref` | from decl · site | target | `@relation`, rebuilt whole |
| `Finding` | rule · place | rule, file | `@relation` (`compiler/findings.av`) |
| `ErrorSite`, `Raised` | decl key | decl | `@relation` (`compiler/failures.av`) |
| `DocFact` | decl key | — | `@relation` |

Today a plugin has three ask verbs — `embed`, `type_named`, `type_exported` — and cannot ask
"every type marked `@model`" (READ `std-meta/src/meta.av:338-362`; READ(agent C2 §12)).
After: `Decl.by_marks(db, "model")`, recorded as one bucket read, so adding a `@model` type
reruns exactly the queries that asked.

`collect xs = @mark in closure as T { … } by …` stays as the language sugar; it lowers to a
kept query over `Decl.by_marks` (it already reads that index: `Decls.gathered`,
`features/decls.av:1585`, READ(agent C2 §1)).

### 2.4 Two plugins, end to end

Sketches against today's `@std/meta` (`Declared`, `Directive`, `quote` — READ
`std-relation/src/query.av:47-58`); `compiling`, `@std/source`, `@kept`, `Blob`, `@check`
are PROPOSED.

**A — a build-time source provider** (`@icons("assets/icons") type Icons`):

```avra
//! @acme/icons — every .svg under a folder becomes a typed constant.
use @std.relation.{relation, query, kept}
use @std.relation.db.{Db}
use @std.source.{listing, bytes, blob, Blob}
use @std.meta.{Type, Declared, Directive, compiling, name, literal}

@relation
export type Icon = { id: int, @key name: string, @index set: string, svg: Blob }

@kept @query
export fn icons_in(db: Db, dir: string) -> List<Icon> {
    [Icon.insert(db, name: stem(e.name), set: dir, svg: blob(db, bytes(db, "${dir}/${e.name}")!))
        for e in listing(db, dir) ?? [] if e.name.ends_with(".svg")]
}

/// The annotation: one `const` per icon. It reads through `icons_in`, so its own
/// saved answer lists `icons_in(dir)` — never the files.
export fn icons(t: Type, dir: string) -> Declared {
    Declared { made: [constant(t, i) for i in icons_in(compiling(), dir)] }
}

fn constant(t: Type, i: Icon) -> Directive {
    Directive { twin: "", name: i.name, at: t.at, source: quote { export const ${name(i.name)}: Blob = ${literal(i.svg)} } }
}

fn stem(file: string) -> string { file.substring(0, file.length - 4) }
```

What the author did **not** write: a cache key, a file watcher, an invalidation rule, a
codec. What happens: add `x.svg` → `Listing(assets/icons)` moves → `icons_in` reruns → its
answer's digest moves → the annotation's saved answer is stale → it re-splices. Edit a
comment in the file holding `@icons` → nothing above reruns (§4.6).

**B — a whole-program lint** (every `@model` has a `@key`):

```avra
//! @acme/orm_lints
use @std.relation.{query, kept}
use @std.relation.db.{Db}
use @std.meta.{Decl, Field, Finding, check}

@check @kept @query
export fn keyless_models(db: Db) -> List<Finding> {
    [Finding.insert(db, rule: "orm.keyless_model", at: d.key, text: "`${d.name}` is a @model with no @key field")
        for d in Decl.by_marks(db, "model") if !Field.by_decl(db, d.key).any(it.marks.contains("key"))]
}
```

`avra check` asks every query gathered by `collect checks = @check in closure` — the
mechanism `rules` already uses (READ `collect rules: List<RuleEntry> = rule in closure …`).
The findings are rows: `avra check`, the baseline ratchet and an editor read the same
`Finding.by_file`.

**C — an ORM schema**, six lines: `@kept @query fn schema(db) -> List<Table> { [table_of(db, d) for d in Decl.by_marks(db, "model")] }`.

### 2.5 Inspection (L9)

**PROPOSED** `avra explain` — one command, any subject. (`avra explain` is documented in
CLAUDE.md and does not exist: READ `packages/cli/src/commands/`. `avra cache why` becomes
an alias.)

```
$ avra explain packages/cli/src/commands/fmt.av
Checked(@std.cli.commands · fmt.av)                 kept · REUSED this run
  value    3 warnings                               digest 9f2c…  saved by avra 4a1e…
  reads    Text(cli:src/commands/fmt.av)            ✓ 81aa…
           Record(@std.cli.commands)                ✓ 3c07…
           Record(@std.avrac.compiler)              ✓ 77b1…
           Env(AVRA_SOUND_CHECK)                    ✓ unset
  read by  Verdict(packages/cli)

$ avra explain @icons_in                # a declaration: every answer about it, and its callers
$ avra explain 'icons_in("assets/icons")' --why
icons_in("assets/icons")                            kept · RECOMPUTED
  moved    Listing(@acme/icons:assets/icons)        was 5d01…  now a9e3…   (+ x.svg)
$ avra explain --stats                  # kept answers, reads per answer, walk cost, bytes on disk
$ avra explain --json …                 # P11: the same, machine-readable
```

It never writes the store it inspects (the `.57.153` law; `Keeping.Aside` exists for this).

---

## 3. The layers

| layer | owns | may know |
|---|---|---|
| `core/` | `Table`, digests, the codec primitives | nothing above |
| `query/` | the Kernel: cells, deps, red-green, **inputs, names, kept answers, validation** | bytes and names only — no language, no disk, no `Db` |
| `@std/relation` | `@relation` / `@query` / `@input` / `@kept` derives, `Db`, rows, indexes | its erased `Hooks` (on main) |
| `grammar/` | unchanged | — |
| `features/` | declare their relations and queries | `Db`, never the store |
| `compiler/` | `Host` (the only world reader), `Store` (the only disk writer), arming, the CLI | everything |

`query/` gets two erased doors from the compiler and nothing else (**PROPOSED**):

```avra
/// How the kernel reaches the outside. Both are the compiler's to implement.
export type Outside = {
    digest: fn(Input) -> Digest,           // the Host: what this input is NOW
    load:   fn(Name) -> Bytes?,            // the Store: a saved record, or none
    save:   fn(Name, Bytes) -> void,       // the Store: one atomic write
}
```

---

## 4. The mechanism

### 4.1 Inputs (L1)

```avra
// query/input.av  — PROPOSED
export enum InputKind { Text, Bytes, Range, Listing, Exists, Env, Tool, Target, Pin, Compiler }
export type Input = { kind: InputKind, name: string, lo: int = 0, hi: int = 0 }
```

- **One reader.** `Host` gains the nine reads, each `(db, place) -> value?`. A read (a) asks
  the kernel for the input's cell by name, (b) on first sight reads the world once and
  digests what it read, (c) records the cell as a dep of the open query. Per process, an
  input is read and digested once. This is `Memo.input` (READ `query/memo.av:128-141`) with
  a name table in front and the digest taken from the bytes.
- **Absence is a value.** A missing file, an unset variable, a missing folder each have
  their own digest — never `""` (the empty-value law). `exists` is an input like the rest.
- **A listing** digests the sorted `(name, kind)` pairs of one directory — not contents.
- **`Compiler`** is the running binary's digest (`compiler_print`). It names the store root
  (as today) and is an input of every answer.
- **`Tool`**: resolved path + identity (§10, decision 3).
- **No stamp shortcut.** Sources are always read and digested (decided on main `92b24db`;
  MEASURED ~36–42 ms warm at 730 files). Clock skew and equal mtimes cannot matter.
- **Huge inputs.** `range` digests only the range read. `pinned` trusts the lock file's
  sha, verified once at fetch. A whole-file `bytes` of a big file is digested by a C row
  (**PROPOSED**; today `digest_bytes` is an Avra loop — throughput UNMEASURED, REVIEW2 D6).
  Budget: ≥ 1 GB/s, so 5 MB ≈ 5 ms (ESTIMATED). An mtime may *order* the checks; it never
  answers one.
- **The fast path before anything is parsed** needs no special case: §4.5.

**The keeper** (L10): `make inputs` — a `rule` in `compiler/idioms.av` refusing any call of
`@std.io`'s readers, `avra_host_env`, `list_dir`, `exists`, `is_dir` or a spawn in
`packages/std-avrac` and `packages/cli` outside `compiler/host/`, with the baseline listing
today's ~177 sites (READ(agent C1 §A)) so only a NEW site fails, and the count printed. The
kernel's own audit (`Kernel.bypassed`, READ `kernel.av:203-215`) catches at run time what
the rule cannot see.

### 4.2 Queries and grains (L2, L4)

Every query family has one of three grains (**PROPOSED** flag on `Kernel.family`):

| grain | what | persists | examples |
|---|---|---|---|
| `Input` | §4.1 | its digest is recomputed, never saved | `Text`, `Listing`, `Env` |
| `Kept` | a `@kept @query` | value + reads (L3) | `Record(module)`, `Checked(file)`, `icons_in(dir)` |
| `Fine` | everything else | never (§6.5a) | `Parsed`, `Typed`, a `Decl` row, an index bucket |

In one process nothing changes: dense `(family, arg)` keys, deps discovered by execution,
red-green, early cutoff (READ `kernel.av:353-369`). A durable name is interned to a dense
`arg` at first sight (the `spec_id` lesson: never a name scan).

**A fine cell names its cover** (**PROPOSED** `cover: fn(arg) -> Key?` per family): the kept
answer that stands for it to a reader in another unit. A `Decl` row's cover is
`Record(its module)`. This generalizes two things on main: "a held read records a dep on
that module's `Sig` row" and `reads_whole` (READ `kernel.av:453-461`; one caller,
`features/decls.av:1008`). A cover must digest everything an outside reader can observe
through the cell; §8 says what catches a cover that lies.

### 4.3 What a kept answer records (L3, L4)

When a kept query `K` settles, the kernel walks down from `K`'s recorded deps:

```
reads(K):  for each dep d of K                (depth-first, each cell visited once per walk)
    d is an Input            → record (name(d), digest(d))          stop
    d is Kept                → record (name(d), value digest of d)  stop
    d is Fine, cover(d) ≠ K  → record (name(cover), its digest)     stop
    d is Fine, private to K  → descend into d's deps
```

- This is a walk over lists the kernel already has (`deps_of`, READ `kernel.av:410-413`)
  with the visit stamp it already has (`first_visit`, READ `kernel.av:277-288`). It runs
  **once per kept settle**, never per read.
- It records **direct** durable reads. Nothing is flattened and nothing is cached per key —
  the two shapes that failed (74,600 edges/file; a per-key cache at 4 GB — MEASURED §6.5a).
- **Law of the walk:** the fine cells under a kept answer are its own, or covered. The
  gate: total cells visited by all walks ≤ 2 × the fine cells that exist (printed by
  `avra explain --stats`). A family that breaks it gets a cover or becomes kept.

**Why direct reads and not "inputs only".** If `Checked(F)` listed only files, a body edit
in any file `F` imports would rerun `F`. Listing `Record(M)` — whose digest is the module's
*interface* — is what makes a body edit hold its importers (pinned in `cache_attacks`:
"a signature edit re-reads its importers, a body edit holds them", townhall §6.5a). So a
read is `(name, digest)` where the name is an input **or a kept answer**. It is still one
rule: every digest must match.

### 4.4 The saved record (L3, L5, L7)

One file per kept answer. One atomic write (`temp` + `rename`). Value and reads are never
apart, so they cannot tear.

```
record  = name · shape · versions[≤4, newest first]
version = digest            the digest of the value's encoded bytes
          value             Inline(bytes ≤ 4 KB) | Blob(digest, size) | None (digest only)
          rows              the rows this query owns, per relation, encoded
          reads[]           (name id, digest)   — inputs first, then kept answers
```

- **Name** = the query's fully qualified path (`@acme.icons.icons_in`, townhall §6.4) + its
  arguments' encoded bytes. The file is `.avra-cache/<compiler>/kept/<hh>/<digest(name)>`.
- **Shape** = fingerprint of the answer type's fields, types, marks, order. A mismatch drops
  the record (belt; the per-compiler root is the braces).
- **≤4 versions** keep A → B → A switches warm, as content keys do today.
- **`None`** — a digest-only answer: cheap to recompute, but its digest is what readers
  list (a declaration's structural fingerprint, §4.6).
- **Encoding** derives from the row type (`@std/relation`'s `stable.av` on main:
  length-prefixed, count-prefixed lists, one presence byte per `?` layer, enums by variant
  **name**). A typed id is written as its target's key. `@local` fields are skipped. A
  span is written relative to the answer's anchor declaration and re-based on load. `fn`,
  `Cell`, `@identity` and `Map` fields are refused at the derive, naming the field — such
  a query cannot be `@kept`, and the message says so.
- **Growth**: a field appended to a row type changes the shape fingerprint; the record is
  dropped and recomputed. Nothing decodes across shapes, so no crossing ceremony applies
  to saved answers. (The crossing laws still govern `@std/meta`'s rows: appended only.)

### 4.5 Validation (L3, L8)

```
current(name) -> Digest?         memoized per process
    input   → Outside.digest(name)
    kept    → record = Outside.load(name)                    none → null
              first version whose every read r has current(r.name) == r.digest → its digest
              none → null        (the caller asks the query; it computes and saves a version)
```

- **Cheapest first.** Within a version: inputs already digested this process, then other
  inputs, then kept reads. Stop at the first mismatch.
- **Root-down.** A command asks its roots (`Verdict(package)`, `Linked(program, target)`).
  A root that stands is answered having read only records and digested only inputs —
  **no parse, no analysis**. That *is* the kept-binary fast path; the remembered `closure`
  and `embeds` rows (READ `build.av:538-609`) are this list under another name.
- **Early cutoff across runs.** `Text(f)` moved → `Record(M)` cannot stand → it is computed
  → its digest equals the saved one → a new version is saved with the same digest →
  every reader's entry `(Record(M), digest)` still matches → they stand.
- **Validation before derivation** (L8): the set of answers that do not stand is known
  before anything is computed. There is no "try the held path, fail, re-derive whole".
- **A missing read is a mismatch.** A record that names a deleted file, an unknown query or
  a missing blob does not stand.

Cost of a fully warm `check packages/cli` (ESTIMATED from §4.7's counts): ~730 input
digests + ~1,300 small record reads. Today's equivalent is MEASURED at 0.22 s no-op
(ticket .57.6.5) and ~36–42 ms at 730 files (`92b24db`). Budget in §6.

### 4.6 A saved expansion survives an edit above it (L5)

Today a lift is named `lift$<file id>$<call id>$<decl id>` (READ(agent)
`workspace_analysis.av:695`) and is never persisted, so every derive and annotation in a
touched file reruns per process (PROBED by the review: 0.05 s → 1.02 s for a comment edit).

**PROPOSED**:

| | |
|---|---|
| name | `Lifted(annotation path · annotated decl key · argument digest)` — no id, no offset |
| reads | `Shape(decl key)` (digest-only kept answer: the declaration's structural fingerprint, position-free) · the provider's units · every lookup it made (`type_named`, `Decl.by_marks` buckets) · inputs it read |
| value | the generated declarations, spans relative to the annotated declaration |

A comment above: `Text(f)` moves → `f` is parsed (it must be) → `Shape(decl)` is recomputed
to the same digest → `Lifted` stands → the splice re-bases spans. An edit *inside* the
annotated type moves `Shape` and the lift reruns. The value's digest covers the relative
spans, so L7 holds.

### 4.7 What is kept (the persisted grain)

This follows §6.5a ("kernel grain cannot persist") and names the grain.

| kept answer | key | replaces on main | count on the cli (ESTIMATED) |
|---|---|---|---|
| `Packages(root)` | root | Manifest readers ×4 | ~40 |
| `Record(module)` — the interface | module path | `Sig` rows, module record lines, `SeenPart` | ~70 (MEASURED "70 view_parts", .57.101.11) |
| `Checked(file)` — warnings, findings, licenses | file | the hold's `KeyParts`; `Warn`/`Licenses`/`Findings` rows | ~408 (MEASURED 408 files, .57.6.5) |
| `Object(file, target)` | file | `Unit`/`Obj` under the object key | ~408 |
| `Shape(decl)` — digest only | decl key | — | one per annotated decl |
| `Lifted(annotation, decl, args)` | §4.6 | **never persisted today** | one per annotation site |
| `Settled(const)` | const's decl key | `kept_settle.av` + its 6 line kinds | one per `const` |
| `Verdict(package)` / `Linked(program, target)` / `Proved(suite)` | root | `program_key`, `closure`/`embeds`/`homes`/`seen`/`parts` rows, `links_unchanged`, `proved_key`, `clean_key` | a handful |
| `Canon(file)`, `Scan(file)`, `Doc(decl)` | file / decl key | `Canon`/`Scan`/`Decl` rows, `still_valid` | on demand |
| any plugin `@kept @query` | its key | `Db.answers` (unarmed) | — |

ESTIMATED total: 1–3 thousand records, tens of reads each (10 B per read with interned
names) → under 1 MB of reads for the cli. To be MEASURED by PR 3 before anything else
moves (`avra explain --stats`): records, reads per record p50/p99, walk visits.

### 4.8 Concurrency, crashes, eviction, bytes

| case | answer |
|---|---|
| crash mid-write | a record appears only by `rename`; a torn temp file is ignored and swept |
| two processes, one name | each writes a whole, self-consistent record; the last rename wins; the loser's version is recomputed later at worst |
| two processes, different inputs seen | each record carries the digests *it* saw; a reader validates against the world *now* — a mix of records is safe because every edge is a digest comparison |
| big values | written to the byte store **first** (content-named, write-once), then the record; a record whose blob is gone does not stand |
| byte store | `~/.avra/bytes/<hh>/<sha256>` — bytes only, shared across worktrees and compilers (owner-approved, SOURCES §15a Q11). Never rows. Must stay outside `.avra-cache`, which `rolled` sweeps (READ(agent) `build.av:388-392`) |
| eviction | rows: whole stores, newest 4 compilers (today's rule). Records: a record unread for N days is deleted by `avra cache gc`. Blobs: `gc` marks from every live store it can find, sweeps the rest; a swept blob is a miss, never an error |
| a compiler upgrade | a new store root: no derived answer survives (L3: the compiler is an input of everything). Bytes survive, so a re-run step that produces the same bytes writes nothing |
| locks, fsync | none needed for correctness; a lost write is a recompute |

---

## 5. Everything queryable — who uses what

| consumer | today | after |
|---|---|---|
| `collect` | `Decls.gathered` over index buckets, read unrecorded, re-gathered at 4 sites | a kept query over `Decl.by_marks`; the bucket is the dep |
| idiom `rule` engine | a tree walk per file; findings → throwaway Db → tab text under the `Warn` key | `Checked(file)` owns `Finding` rows; `rule_candidates` reads `Expr.by_shape` (index on the shallow fingerprint) |
| `avra docs` | 2 `@query` (full scan), hand witness `DocFacts` | `@kept @query` over `Decl.by_name`; `still_valid` deleted |
| references | `Ref` rebuilt whole under one unit cell | `Ref` rows owned by `Checked(file)`; `Ref.by_target(db, key)` |
| LSP-shaped asks | none | `Decl.by_name`, `Ref.by_target`, `Finding.by_file`, `DocFact.get` — each one index read; an unsaved buffer is `set_text(db, path, buffer)` (the `@input` setter on main) |
| `avra explain` | absent | §2.5 |
| derives, annotations | `Lifted`, per process | §4.6 |
| `embed` | bespoke in three places (#282) | `text(db, path)` — an input like any other |
| build-time sources | designed around two new doors | §2.4 A; its doors are L1 and L3 |
| ORM `@model` | runtime only | `Decl.by_marks(db, "model")` + a kept `schema` query |
| a third-party lint | impossible | §2.4 B |

The 28 bespoke whole-program walks and the index that replaces each: inventory appendix
C2, list (b). Five need only an index that already exists.

---

## 6. Performance

### 6.1 What things cost today

| | value | kind |
|---|---|---|
| one recorded dep | **71 B** (363 MB / 5.1 M boxes in `Kernel.newly_read`) | MEASURED avra-8sb5.76 |
| same, from layouts | ~89 B = 80 B boxed `Key` + 9 B list slot; + 8 B stamp per distinct key | ESTIMATED (C1, `runtime/avra_box.h`) |
| kernel read | ~125 instr unrecorded · ~315 stamped repeat · ~1,900 first read | MEASURED .57.30 |
| relation recorded read | ~938 instr vs ~90 raw | MEASURED .57.8.1 |
| per generated declaration | 75–140 KB of compiler memory | PROBED (SOURCES C.26) |
| per relation row | not measured anywhere | owed by PR 3 |
| warm no-op `check packages/cli` | 0.22 s (.57.6.5); 0.36B instr, 7 MB peak (`1c0cad6`) | MEASURED |
| warm one-file edit | 4.27 s (#124); phases ast/sublang/load/admit ~1.0–1.4 s each | MEASURED |
| partly-held peak | 3,442 MB vs 2,168 MB cold | MEASURED .57.163 |

### 6.2 What this design changes

| change | effect | kind |
|---|---|---|
| deps as packed ints (`family << 40 \| arg` in a `List<int>`) instead of boxed `Key` records | ~9 B per dep instead of 71 → the 363 MB becomes ~46 MB | ESTIMATED |
| recording for persistence = one walk per kept settle | O(fine cells), not O(reads); target ≤ 2 % of cold | ESTIMATED; the flattened recorder was +62…216 % MEASURED |
| validation before derivation; one derivation alive | partly-held ≤ cold | the invariant L8; `avra-warm-memory` is building the second half |
| `Lifted` kept | a comment edit stops rerunning derives (1.02 s → ~0.05 s floor PROBED by the review) | PROBED there |
| `Record(module)` values decoded lazily | attacks the ~1.0–1.4 s `load` phase of a warm edit | ESTIMATED |

### 6.3 Budgets a CI gate holds (**PROPOSED** `make db-budgets`, on a Sprite)

| scenario over `packages/cli` | time | peak memory | today |
|---|---|---|---|
| unchanged, warm `check` | ≤ 150 ms | ≤ 32 MB | 220 ms / 7 MB |
| one body edit, warm `check` | ≤ 2.0 s (first target; see decision 5) | ≤ 600 MB | 4.27 s |
| one signature edit | ≤ cold × 0.5 | ≤ cold | unmeasured |
| any partly-held state | ≤ cold × 1.05 | **≤ cold** | 1.6 × cold |
| cold, recording on vs off | ≤ +2 % instructions | ≤ +2 % | — |
| walk visits ÷ fine cells | ≤ 2 | — | — |

Gates are relative to the measured cold run of the same commit (the N − k rule), never
absolute counts, except the two warm rows.

### 6.4 Parallelism the design allows later

Kept answers are the unit: `Record(M)` per module, then `Checked(F)`/`Object(F)` per file,
have disjoint private fine cells and meet only through saved records. So N worker
*processes* (the CORES model: a process per core) can each take a set of names and share
through the store, with no lock (§4.8). The fine kernel stays single-threaded. One
precondition: a relation read answers in key order, not insertion order, wherever the
order reaches a kept value (§8, "map iteration order").

---

## 7. What gets deleted, in order

### 7.1 Bespoke path → the door that replaces it

| on main | lines / sites | replaced by |
|---|---|---|
| `compiler/kept_settle.av` — `u/c/m/f/b/e` lines and six `*_stands` fns (+ `l`, unlanded) | 324 | L3 over `Settled` |
| `KeyParts`, `SeenPart`, `view_parts`, `key_parts_cached`, `stands_in`, the `Keys` struct | 10 caches | reads of `Checked` / `Object` |
| `program_key`, `embeds_key`, `closure_key`, `homes`/`seen`/`parts` rows, `links_unchanged` | `build.av:538-609` | reads of `Linked` / `Verdict` |
| `still_valid`, `FileWitness`, `DocFacts`, `current_listing_digest`, `current_file_digest` | `db.av:84-153,658-690` | `Doc` as a kept query |
| `proved_key` (suite), `clean_key`, `canon_key` | 3 | kept queries |
| `Db.answers`, `answer_name`, the hex codec | `answers.av` (46) | `@kept` |
| `DbRow`'s 8 durable variants, `DbKind` + `tag()`, `durable_key` | `db.av:155-216,292-323` | records named by query path |
| `Store.keep`'s `read` parameter, every `.deps` file, `Stored.Sig`/`Stored.Fp` | 18 call sites | the record is one file |
| `admit_embeds` (callee matched by the string `"embed"`), the second embed reader | `whole.av:171` | `text(db, path)` |
| `compiler/inputs.av`'s `@std.io` reads; `current_*_digest` reading `@std.io` | — | `Host` reads |
| ~160 unrecorded world reads | C1 §A | recorded (they stay; they go through the door) |
| `@family(rank, "Key", "Answer")` with unchecked strings; `family_word`'s 32 arms | `families.av`, `workspace.av:523` | `@query` declarations (decision 4) |
| the Workspace's string-keyed memo maps (`Records`, `Hold`, `lift_asks`, `settle_asks`) | ~40 of ~95 hand caches | queries; the rest is state, not cache (C1 §E says which) |
| two types named `Db` | — | `compiler.db.Db` dissolves into `Kernel` + the relation `Db` |
| `avra cache why` | — | `avra explain` |

### 7.2 The PRs — each lands alone and leaves the tree green

"Ladder" = what the generation/seed laws cost. *None* = the standing compiler builds the
branch and the seed needs no refresh.

| # | PR | deletes | ladder |
|---|---|---|---|
| **1** | **Count and fence.** `make inputs` (the L1 rule + baseline of today's sites), `make db-budgets` (reports only), `cache-attacks` + `codecs` into the CI keeper loop once green (`avra-keepers-green`), these docs, the townhall committed as history | nothing | none — tools and docs |
| **2** | **The input door.** `query/input.av` (`Input`, name table, per-process digest memo), `Host`'s nine reads, a C digest row. Route `Source`, `Manifest`, `embed`, the four hand listings and the four unrecorded reads in `Parsed`/`Plain` frames through it. Behaviour-preserving; baseline shrinks | `inputs.av`'s `@std.io` reads, `admit_embeds`' string match | a runtime row the compiler's source declares: **two landings** (row first, declaration after the seed refresh — CLAUDE.md "a registry row … cannot be gated in the commit that adds it") |
| **3** | **The kept door, first consumer `Settled`.** `query/kept.av` (grain flag, cover, the walk, record codec, `current`), `Outside` armed by the compiler. `Settled(const)` moves onto it under `cache_attacks` + the 17 `avra-m3-redteam` cases. Posts the §4.7 measurements | `kept_settle.av` | none (new files; no shape the compiler checks about its own source) |
| 4 | `Lifted` kept (§4.6): span-relative codec, `Shape(decl)` | per-process reruns | none |
| 5 | Small rows → kept queries: `Doc`, `Canon`, `Scan`, `Licenses`, `Findings`; arm `@kept` for `@query` (pays .57.4.6: the name is the query's own path, so the *declaring* file's reads are in the list) | `still_valid`, `answers.av`, 8 `DbRow` variants | none |
| 6 | The hold: `Record` / `Checked` / `Object` on L3 | `KeyParts`, `Keys`, `stands_in`, `verify_held`'s hand checks | none; the riskiest — lands behind `AVRA_DB_CHECK` double-run on a Sprite for a week |
| 7 | Roots: `Verdict` / `Linked` / `Proved`; `Tool`, `Env`, link words as inputs (fixes avra-8sb5.68/.69 and the suite-key trio) | `program_key`, remembered rows, `links_unchanged` | none |
| 8 | `avra explain`; `avra cache why` aliased | `cache_walk.av`'s modes | none |
| 9 | Byte store `~/.avra/bytes`, `Blob`, `avra cache gc` | — | none |
| 10 | Compiler relations exported through `@std/meta`; `compiling()`; `@std/source` | the 3 ask verbs stay as sugar | `@std/meta` growth is appended: one commit; the first *reader* of a new field owes the seed refresh |
| 11 | Families become `@query` declarations; `DbKind` gone; `Field`/`Variant`/`Impl` rows | `@family` strings, `family_word` | **bridge**: the compiler checks this about its own source — two landings |
| 12 | Deps as packed ints | boxed `Key` deps | none (codegen-neutral; build twice before trusting a peak) |

**The first three PRs are 1, 2, 3.** PR 1 changes no behaviour and makes every later
claim checkable. PR 2 is the half every other consumer (sources, embed, dev's watch set)
is blocked on. PR 3 proves the rule on the smallest real hand format and produces the
numbers §4.7 owes.

---

## 8. Hostile cases

| case | what happens |
|---|---|
| a file added to a folder | `Listing(dir)` digest moves → whoever listed it reruns. A module's files come from a listing, so `Record(M)` is asked again |
| a comment edited above a cached expansion | §4.6: `Shape(decl)` unchanged → `Lifted` stands; spans re-based |
| a dependency's manifest changes | `Text(dep:avra.toml)` → `Packages(root)` reruns → early cutoff if the resolved graph is the same |
| an env var read by a derive | `env(db, "X")` is in `Lifted`'s reads; unset and empty differ |
| a tool upgraded | `Tool(name)` identity moves → `Linked` reruns (today: nothing — avra-8sb5.68/.69) |
| clock skew, identical mtimes | irrelevant: no stamp answers anything (§4.1) |
| a crash mid-commit | no record (§4.8) |
| two worktrees sharing bytes | bytes are content-named and write-once; rows are never shared |
| a cache from a different compiler | a different root; and the shape fingerprint refuses a record that slipped through |
| a key with a dense id that renumbers | refused at the derive: a `@kept` query's arguments and answer must encode (typed ids as keys, L5). In process, dense ids are fine |
| a value holding a closure or a `Cell` | not encodable → the query cannot be `@kept`; the derive names the field. It still memoizes in process |
| a 5 MB input | digested once per process (~5 ms at the 1 GB/s budget, ESTIMATED); stored once in the byte store; rows hold its digest |
| 10,000 rows of one relation | index buckets are lazy cells; a query that reads more than K buckets of one index records the relation's set hash instead (townhall §6.5); bucket hashes are commutative sums over finalized row hashes, O(1) per insert |
| a plugin that lies about purity | (1) `make inputs` refuses `@std.io` in compile-time code paths; (2) the kernel audit reports a row read outside the door; (3) **`AVRA_DB_CHECK=1`**: every kept answer that stood is also recomputed and the digests compared — a mismatch traps naming the answer and the first input that differs. Run in `cache-attacks` and on a sampled Sprite job. A lie costs a red gate, not a wrong binary shipped unnoticed |
| a cover that lies | the same double-run catches it: the answer stood, the recomputation differs |
| map iteration order | a `Map` field is refused by the codec; relation set hashes are order-free; a kept list answer keeps the query's own order, which is deterministic because evaluation is sequential — parallel workers (§6.4) need key-ordered reads first |
| the empty case of every encoding | absent input ≠ empty input; missing dir ≠ empty listing; a kept answer with zero reads stands always and `explain` says "reads nothing"; an empty value is saved as made; `T??` keeps both absences (one presence byte per layer); a zero-length `range` still names its file |
| a held answer needing a program-wide fact no input names (the `Line` layout defect, .57.165) | the fact is a kept answer (`Layout(type key)`), read like any other — not a seventh line kind |
| a query declared in an imported module whose body changes (.57.4.6) | the record is named by the query's own path; its reads include the declaring unit; it does not stand |

---

## 9. Answers to open questions others parked here

**SOURCES D1–D13** (`avra-sources-design/docs/2026_10_05_BUILD_TIME_SOURCES.md` §1.7):

| D | answer |
|---|---|
| D1 | One mechanism. The "kept run" is a kept answer; `RunKind` dissolves into query names |
| D2 | `Memo.input` with a name table, given `@std/source`'s face (§4.1). `@input` stays for driver-set values |
| D3 | `KeyParts.runs` is not migrated; it is deleted with `KeyParts` (PR 6). Until then inputs reach it as digests, unchanged |
| D4 | Nowhere special: the root record's reads are the list (§4.5) |
| D5 | §4.6 |
| D6 | A C digest row; measure it in PR 2; no stamp shortcut |
| D7 | `~/.avra/bytes`, outside `.avra-cache` (§4.8) |
| D8 | The atom is `(name, digest)` where the name is an input **or a kept answer**. A "derived-fact line with its own stands rule" is a read of a kept answer; its stands rule is "recompute it, compare digests". Lines per kept run: measured in PR 3 |
| D9 | The store's `read` slot is deleted. The record is one file |
| D10 | Paid by naming the record after the query (§8, last row), in PR 5, before `@kept` is armed |
| D11 | All five: `interface.av:66,85` → `Settled`; `build.av:719` → `Linked`; `derive.av:200` → root reads; `derive.av:530`, `suite.av:128` → kept queries |
| D12 | The per-process input memo is keyed by *input name* and holds a digest of bytes read this process — not a path-keyed cache of a stamp; safe because a one-shot process reads each input once |
| D13 | This design; the sources campaign is its second consumer after `Settled` |

**Tickets `.57.101.11` / `.57.101.12` vs §6.5a:** both right. `.12` asks for deps written at
settle under stable names; §6.5a says the kernel's own grain cannot be written. L4
reconciles them: reads are written at settle, at the kept grain only.

**The review's ruling "not one mechanism"** (`REVIEW.md` §D): its three ordered fixes are
PRs 2, 3–5, and the sources campaign.

---

## 10. Decisions for the owner

**1. Is "kept" opt-in or the default?**

```avra
@kept @query fn icons_in(db: Db, dir: string) -> List<Icon> { … }     // A: opt-in
@query fn icons_in(db: Db, dir: string) -> List<Icon> { … }           // B: kept whenever the answer encodes;
@local @query fn scratch(db: Db, n: int) -> int { … }                 //    opt out
```
**Recommend A.** The compiler's fine families answer encodable values too (`Syntax(decl) ->
int`), and persisting those is the ≥51.6 M-dep failure. With A, forgetting the word is
slower, never wrong, and `explain` says "not kept".

**2. The list holds kept answers as well as raw inputs — agreed?** Your sentence said
"the inputs it read".

```
A  Checked(fmt.av) reads:  Text(fmt.av), Record(@std.avrac.compiler) …      ~10–70 entries
B  Checked(fmt.av) reads:  Text of every file in its import closure         ~700 entries
```
**Recommend A.** B reruns every importer on any body edit; A holds them (today's pinned
behaviour). Still one rule: every digest must match.

**3. A tool's identity.**

```
A  digest the tool's bytes each process        clang ≈ 100+ MB → ~100+ ms per build (ESTIMATED)
B  resolved path + size + mtime + inode, full digest on `avra cache verify`
```
**Recommend B, for tools only** — the single place a stamp answers. Installers change size
and mtime; sources never get this shortcut.

**4. Do the compiler's 32 families move to the `@query` spelling?** (the fork left open on
`.57.148`)

```avra
@family(9, "FileId", "TypeFacts")  type Typed = {}                    // A: stays (two spellings)
@query fn typed(db: Db, f: FileId) -> TypeFacts { … }                 // B: one spelling; not @kept
```
**Recommend B, last (PR 11).** It buys one door and a typed catalog, not speed, and it is the
only step with a two-landing bridge.

**5. Is the ~300 ms warm-edit bar a gate of this campaign?** Last measured: 4.27 s. This
design removes revalidation and rerun-derive cost; the rest is parse + type of the edited
file plus loading its imports' records (~1 s each phase today). **Recommend:** gate at 2.0 s
now, re-measure after PR 6; 300 ms likely needs lazily decoded records or a resident
process, and `COMPILER.md` refuses the latter — that refusal is yours to keep or lift.

---

## 11. Risks, stated

| risk | why it might bite | guard |
|---|---|---|
| the walk is not cheap | a fine family shared by many kept answers without a cover | the ≤ 2× gate; PR 3 measures before PR 6 commits |
| covers are subtle | a cover that digests less than a reader observes is a stale answer | `AVRA_DB_CHECK`; the existing `Sig`-dep precedent |
| ~1,300 record opens on a no-op | file-per-record vs the townhall's pack | the 150 ms budget; if it fails, a per-package pack goes behind the same `Outside.load/save` — no consumer changes |
| doc facts as relations hit five walls (`.57.9.7`) | `@side` unreachable from a Db-only query; dense `@key` generates nothing, silently | PR 5/10 must pay them; the silent derive is a defect to fix first |
| `@std/meta` relation mirrors | every row type crossing is a crossing-law surface | appended-only; `written` holds writers to the rows (CLAUDE.md) |
| estimates in §4.7, §6.2 | not measured | each is a PR 3 receipt |

---

## 12. Docs that die or change

| doc | fate |
|---|---|
| `docs/2026_09_26_COMPILER_DB_TOWNHALL.md` | committed on this branch as **history** (it was in no tree). §4, §6.2–§6.4, §6.5a absorbed here. §6.5, §6.6 superseded. Its status line ("no open blockers") is false |
| `docs/2026_09_24_DB_REDESIGN.md` | dies — its singleton premise was found false (`db.av:8-17`) |
| `docs/2026_09_21_COMPILER.md` | stays; §2 law 6 gains "under L3"; §7's open items re-pointed here |
| `avra-sources-design/…BUILD_TIME_SOURCES.md` §1 | replaced by a pointer to L1/L3; D1–D13 closed by §9 |
| `ADDING_A_PROJECTION.md` | its persistence pointer (`.57.6`) → §2 here |
| `HANDOFF_COMPILER_DB_2026_10_01.md`, `MY_PLAN.md` (untracked, stale checkout) | read; superseded by the hand-offs doc |
| `compiler/inputs.av` header, `db.av` header | rewritten by PRs 2 and 5 |
| CLAUDE.md | "AN EARLY-CUTOFF HASH MUST COVER THE WHOLE VALUE" gains L7; the `explain` lines become true at PR 8 |
