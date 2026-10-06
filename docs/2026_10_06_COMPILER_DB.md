# The compiler DB — the one document

2026-10-06 · branch `db-design` · worktree `../avra-db-design` · epic `avra-8sb5.57` ·
code checked against `origin/main` @ `05fe643`
Start here, then [`2026_10_06_COMPILER_DB_HANDOFF.md`](2026_10_06_COMPILER_DB_HANDOFF.md).
This replaces the first draft, which an independent review ruled NOT READY (appendix A9).

**What this is.** Every fact the compiler knows becomes a query answer in one database.
Every answer is saved automatically with the list of what it read. A plugin uses the same
three words the compiler uses (`@relation`, `@query`, `@input`) and decides nothing about
caching. Warm commands are fast in a cold process, with no daemon.

**Labels.** `READ` I opened the line · `READ(agent)` a sub-agent's report (appendix A8 says
which) · `PROBED` I ran it; the command and its output are beside it · `MEASURED (source)` ·
`ESTIMATED` · **PROPOSED** = not built.

---

## 1. The goal and the decisions

### 1.1 The owner's words

| date | the owner said | where |
|---|---|---|
| 09-18 | "build packages/cli … cold < 60 s · edit < 1 s" · "We need <1s edit recompiles" | codex session :5-11, :14964 |
| 09-18 | "i don't want this to be a list we need to maintain as new things are added. this will be generic right? i want this to scale" | codex session :6920 |
| 09-18 | "Keep the stateless store design" (his pick against "a resident compiler") | codex session :8565 |
| 09-26 | "The compiler's DB is a real database, and every tool is a THIN QUERY over its rows." Generic · easy to integrate · very performant · extremely centralized · resumable | townhall :64-78 |
| 10-06 | "a saved answer is its value plus the list of inputs it read with their digests, recorded automatically by the kernel, valid only if every digest still matches — one rule, no hand-written checks." | brief |
| 10-06 | "EVERYTHING needs to be in the DB and queryable and maximally easy to work with as a consumer/plugin." "Pluggable. Performant. Simple seams." | brief |
| 10-06 | "Why wouldn't we always save? I feel like we should figure that out." | brief |
| 10-06 | "Yes!!!!!! This is what I have been asking for!!! I want to standardize on this as MUCH AS POSSIBLE." | brief |
| 10-06 | "It should be blazing fast." | brief |
| 10-06 | "I want a tidy work tree, a single document and a single epic that I can give to a new session and say do this work." | brief |

### 1.2 Decided

| # | decision | what it means here |
|---|---|---|
| D1 | **Always save.** | Every query's answer is saved. No `@kept`, no hand-written cover, no grain flag. The compiler picks the grain from the key (law L4). A plugin author decides nothing. |
| D2 | **One engine first.** | `@query` and `@input` become kernel cells on every Db. The second memo and the unarmed hooks are deleted. The 32 families move to the same spelling one at a time under a counter that only falls. |
| D7 | **The speed bar**, on `packages/cli`, cold process, no daemon. | unchanged `check` ≤ 60 ms · one body edit `check` ≤ 300 ms (goal 150) · `build` after one edit ≤ 500 ms. The first draft's 2.0 s gate is deleted. |
| — | **A read list holds saved answers as well as inputs.** | The rule is a *verifying trace*: an answer stands if every digest in its list still matches. |

### 1.3 PENDING OWNER — the document is written with the recommendation (R)

| # | question | A | B | R |
|---|---|---|---|---|
| D3 | Is the Db passed by hand? | `@query fn icons_in(dir: string)` — implicit inside a query | `@query fn icons_in(db: Db, dir: string)` — first argument everywhere (today) | **A**: the wrong-Db mistake cannot be written |
| D4 | Can a query write rows? | no: `Icon` is the indexed answer of `icons_in`; reading its index asks that query | yes (today): `Icon.insert(db, …)` inside a query | **A**: B caused three probed defects (appendix A6) |
| D5 | How is a lint written? | `rule` is the one way, for third parties too | keep `rule` and add `@check @query` | **A** |
| D6 | What may a plugin read at compile time? | only what its package manifest grants; every read recorded | any file, env var or tool | **A**; the grant policy is the sources design's, decided with you |
| D8 | Is the cache thrown away when the compiler is rebuilt? | answers keyed by the code of the query that made them | one store per compiler binary (today) | **B now**, A recorded as the next step |
| D9 | What identifies a tool (clang, the linker)? | digest its bytes every process (~100 ms for clang, ESTIMATED) | path + size + mtime; full digest on demand | **B**, for tools and the compiler binary only — never for sources |

---

## 2. The laws

| # | law | one line |
|---|---|---|
| **L1** | **One input door.** | Anything outside the program is an *input*: a stable name and the digest of exactly what was read. Only `Host` reads the world. Absence is a value. |
| **L2** | **One engine.** | Every derived fact is a query: one kernel cell, one registration, one dependency list. `@query`, `@input`, a relation read and a compiler family are the same thing. |
| **L3** | **The saved-answer rule.** | A saved answer is its value plus the list of what it read, each with its digest, recorded by the kernel. It is valid only if every digest still matches. No other validity check exists. |
| **L4** | **Always save; the key picks the grain.** | A query keyed by a durable name is saved, with no mark. A query keyed by a local id lives in memory and belongs to the saved answer that owns the id; reading it from anywhere else is refused at the read. |
| **L5** | **Names are stable, ids are local.** | A name is a path plus a number *among same-named siblings of one owner*. A local id is (owner declaration, index). A saved value holds names, never dense ids or absolute offsets. |
| **L6** | **Every fact is a query answer.** | Small keyed facts with indexes are relations. Trees are blobs behind a query. A relation is filled by the driver (an input) or is the answer of one named query. A query never writes rows. |
| **L7** | **One codec; the digest covers the whole value.** | The bytes saved are the bytes digested and the bytes that cross to a plugin. |
| **L8** | **Warm is never worse than cold, and never O(program).** | Validation before derivation. One derivation alive. Nothing on the warm path walks the whole program. |
| **L9** | **Every answer can say why.** | One command prints any answer, what it read, what moved, who reads it. Every refusal names its query and key. |
| **L10** | **Purity is checked.** | A keeper refuses a world read outside the door. The kernel refuses a cross-owner local read. An edit corpus proves no saved answer is stale. |

Three rules ride L3, carried from `docs/2026_09_21_COMPILER.md`: **a refusal is never saved**
(:118); **an incomplete answer is never saved** (:273 — a cycle member, a budget stop); an
answer *with diagnostics* is an answer and is saved.

**What L4 saves.** Always: the answer's digest and its direct durable reads (inputs and other
saved answers). The value too when the compiler says it is worth it — one constant per
family, set from a measurement (§4.1 "saved as"). An answer that cannot be encoded (a closure,
a `Cell`) keeps only its digest; its value lives in memory.

**PENDING M1** (§7.3): if the whole kernel graph is ~5 M edges, every cell's digest and reads
are saved and L4's refusal is a speed lint. If it is ~50 M, the refusal is a correctness law.
The plugin author's view is the same either way.

---

## 3. The consumer surface

### 3.1 What runs today

PROBED: `build/avra run /tmp/db-doc/t1` → `/a b 2->3` (0.48 s; compiler
`avra-ui-own-state/build/avra` @ `6c9add3`, `LLVM_PREFIX=/opt/homebrew/opt/llvm`):

```avra
use @std.relation.{relation, query, input}
use @std.relation.db.{Db, new_db}

@relation
type Route = { id: int, @key path: string, @index verb: string, handler: string }

@input
fn listing(_db: Db, dir: string) -> List<string> { ["a.svg", "b.svg"] }

@query
fn gets(db: Db) -> List<string> { [r.path for r in Route.by_verb(db, "GET")] }

@query
fn svgs(db: Db, dir: string) -> int { listing(db, dir).length }

let db = new_db()
Route.insert(db, path: "/a", verb: "GET", handler: "a")
Route.insert(db, path: "/b", verb: "POST", handler: "b")
let one = gets(db).join(",")
let before = svgs(db, "icons")
set_listing(db, "icons", ["a.svg", "b.svg", "c.svg"])
"${one} ${Route.by_key(db, RouteKey { path: "/b" })?.handler ?? "-"} ${before}->${svgs(db, "icons")}"
```

The spelling is right. The engine under it is not what the owner asked for:

| today | evidence | fixed by |
|---|---|---|
| `@query` is a second memo. One write anywhere on the Db invalidates every answer | READ(agent) `std-relation/src/db.av:511-519`; PROBED by the review (`c3`): three queries asked three times ran nine times | DB 01 |
| `@input` records no read; its first reader is marked a writer | READ(agent) `db.av:625-649` | DB 01 |
| An annotation that calls a `@query` traps the compiler | PROBED `build/avra run /tmp/db-doc/t2` → ``avra: side table `of_expr` holds [0, 31) — id 37 is outside it``. Same annotation, no query: `/tmp/db-doc/t2ok` → `<svg/> \| <svg/>` | bug `.57.182`, DB 10 |
| Nothing a `@query` answers is saved in production | READ(agent): `Db.answers` has one caller, a test | DB 06 |
| A query that inserts rows leaves readers empty or stale | PROBED by the review (`c1`, `c4`) | D4, DB 06 |

### 3.2 What an author holds (PROPOSED, under D3-A and D4-A)

Five things: **a row type · its key and indexes · a query · an input read · `quote`**.

```avra
use @std.relation.{relation, query}
use @std.source.{listing, blob, Blob}

@relation(from: icons_in)                 // Icon rows ARE icons_in's answer, indexed
export type Icon = { @key set: string, @key name: string, svg: Blob }

@query                                    // saved automatically: its key is a string
export fn icons_in(dir: string) -> List<Icon> {
    [Icon { set: dir, name: e.name, svg: blob("${dir}/${e.name}") }
        for e in listing(dir) ?? [] if e.name.ends_with(".svg")]
}

icons_in("assets/icons")                  // ask
Icon.by_set("assets/icons")               // index read: asks icons_in("assets/icons"), records it
```

| | today | PROPOSED |
|---|---|---|
| the Db | first argument of every call | implicit inside a query; a program has one default Db (D3) |
| rows from a query | `Icon.insert(db, …)` as a side effect | the query *answers* rows; the relation names its producer (D4) |
| an index read across producers | reads whatever happened to be inserted | a generated two-level query: one small answer per producer key, one root over them — one producer's edit dirties one small answer |
| saving | never | always (L4) |
| world reads | `@std.io`, unrecorded | the nine reads of §5.2; each is a recorded input |
| selecting declarations | `Decl.by_marks(db, "model")` — a string | `DeclRow.wearing(model)` — by the annotation's own declaration |

The exact spelling of `@relation(from: …)` and of a second Db is settled in DB 06 and DB 10.
The laws are fixed: a query never writes rows, and an index read asks the producer.

### 3.3 Plugin A — a build-time sources provider (PROPOSED; lands at DB 10)

`@icons("assets/icons") type Icons` makes one constant per `.svg`. The whole plugin is §3.2's
relation and query plus:

```avra
use @std.meta.{Type, Declared, Directive, literal}

export fn icons(t: Type, dir: string) -> Declared {
    Declared { made: [constant(t, stem(i.name), i.svg) for i in icons_in(dir)] }
}

fn constant(t: Type, n: string, svg: Blob) -> Directive {
    Directive { twin: "", name: n, at: t.at, source: quote { export const ${n}: Blob = ${literal(svg)} } }
}
```

What compiles today: the annotation half over a literal list (PROBED `t2ok`, above), and
`const TEXT: string = embed("assets/x.txt")` with an edit rebuilding (PROBED
`build/avra run /tmp/db-doc/t4` → `5`; edit the file → `7`; #282). What does not: the query
call from the annotation (`t2`, the trap).

What the author did not write: a cache key, a file watcher, an invalidation rule, a codec.

| event | what happens |
|---|---|
| add `x.svg` | `Listing(@acme/icons:assets/icons)` moves → `icons_in` reruns → its digest moves → the expansion reruns |
| edit one svg | that file's `Bytes` input moves → `icons_in` reruns → one constant differs |
| a comment above `@icons` | the file is parsed; the declaration's syntax digest is unchanged → the saved expansion stands (§6.3) |
| edit the plugin | only answers made by the plugin's queries rerun (its code is one of their reads) |

### 3.4 Plugin B — a lint (PROPOSED under D5-A; lands at DB 10)

Today a `rule` is a `quote` pattern with a fix, and only the compiler's own packages declare
one (READ `packages/std-avrac/src/compiler/idioms.av:19`; `build/avra rules` lists them).
A whole-program lint needs a second arm kind — a relation read instead of a pattern:

```avra
use @std.meta.{DeclRow, FieldRow, said}
use @acme.orm.{model, key}

/// Every @model has a @key field.
export rule keyless_model {
    each d in DeclRow.wearing(model) if !FieldRow.of(d).any(it.wears(key)) -> said(d.at, "`${d.name}` is a @model with no @key field")
}
```

A finding's id is the rule's own name (`@acme.orm_lints.keyless_model`), as on main
(READ(agent) `rules_table.av:88-90`). Baselines and `// LICENSED` keep working because a
finding has a place. The findings are the rule's saved answer; `avra check` asks every rule
in scope. Nothing is pushed into a core relation (townhall §6.9: core never reads a plugin's
relation).

### 3.5 What each existing consumer is on this DB

| consumer | today | on this DB | PR |
|---|---|---|---|
| `collect` | gathers by a raw bucket read that records nothing (READ(agent) `features/decls.av:1336-1340`). PROBED `build/avra run /tmp/db-doc/t3` → `2 A,B` | **membership** ("which declarations wear this mark, in this scope") is a saved query, so adding a member reruns exactly the collects that asked. The **projection** stays lowering: its value is data in the output program and may hold fn values. Order: every expansion that can mint a member of a scope finishes before that scope's membership is answered; one that reads a membership its own output joins is refused, naming both | DB 10 |
| idiom `rule` engine | a tree walk per file; findings to a throwaway Db | the walk stays (the AST is an arena, not rows — townhall P4 ruling). The saved answer is `Findings(declaration)` | DB 07 |
| `avra docs` | two `@query` full scans plus the hand witness `DocFacts`/`still_valid` | two saved queries keyed by name; a doc fact is the value of `Doc(declaration)`. The hand witness is deleted | DB 06 |
| references | `Ref` rebuilt whole; every identifying column is `@local` | `Refs(declaration)`: the sites inside one declaration, each (target name, local index). "Who refers to X" is a two-level index read | DB 07 |
| `avra explain --why` | absent. `avra cache why` re-derives the program in process | reads the store: the answer's record, the previous record (still in the append-only file), and the reverse index | DB 02, DB 05 |
| `embed` | three hand sites (#282) | `text(path)`: an input like any other | DB 04 |
| an editor | none | an input has a `set`; an unsaved buffer is `set_text(path, buffer)` | DB 01 |

### 3.6 Inspection (PROPOSED; DB 02)

```
$ avra explain packages/cli/src/commands/fmt.av --why
Typed(@std.cli.commands · fmt.av · run)              saved · RECOMPUTED, same digest (readers stand)
  moved   Text(cli:src/commands/fmt.av)               was 81aa…  now c40e…
  reads   Sig(@std.avrac.compiler · Program.parsed)   ✓ 3c07…        … 14 more
  read by Lowered(… fmt.av · run) · Findings(… fmt.av · run)
$ avra explain --stats         # cells, deps, saved answers, reads per answer p50/p99, bytes
$ avra explain '@acme.icons.icons_in("assets/icons")' --json
```

It never writes the store it inspects (the `.57.153` law).

---

## 4. The two tables that are the migration

### 4.1 The 32 families

READ `packages/std-avrac/src/compiler/families/families.av:17-149` (key, answer). "Encodes
today" is READ(agent). "Saved as" is PROPOSED and confirmed per family by M2 and M4.
Durable key = it becomes a name at DB 03. No family is keyed by a node id, so all 32 are
saved; the in-memory grain is below them (side tables and arena nodes keyed by `ExprId`).

| # | family | key | answer | encodes today? blocked by | saved as |
|---|---|---|---|---|---|
| 0 | Source | file | `SourceFile` | yes | it is the input `Text(file)` |
| 1 | Parsed | file | `Parsed` (arena) | no: arena + Cells | digest only |
| 2 | Items | file | `List<DeclId>` | dense ids | value (names) |
| 3 | Namespace | module | `ModuleNames` | `Map` + dense ids | value |
| 4 | Visible | file | `Namespace` | `Map` + dense ids | digest; value by M4 |
| 5 | Resolved | file | `NameFacts` | `ExprId` side tables | split per declaration; digest |
| 6 | Sig | declaration | `DeclSig` | `TypeId` | **value** — what importers load by name |
| 7 | Methods | declaration | `List<DeclId>` | dense ids | value |
| 8 | Typed | declaration | `TypeFacts` | `ExprId` tables, `TypeId` | digest + diagnostics; value by M4 |
| 9 | ConstTyped | settle int → const name | `TypeId` | `TypeId` | value |
| 10 | Folded | file | `TypeFacts` | as 8 | split per declaration; digest |
| 11 | Analysis | file | `Analysis` | no: closures | in memory; a view that dissolves at DB 07 |
| 12 | Settled | settle int → const name · seats | `Settlement` | yes | value (DB 09) |
| 13 | Lowered | ask int → declaration · type args | `Unit` | `TypeId`, `FileId` | value |
| 14 | Lifted | lift int → annotation · declaration · args | `LiftResult` | yes; spans | value (DB 09) |
| 15 | Manifest | int → package name | `Manifest` | yes | value over `Text(avra.toml)` |
| 16 | Receivers | whole program | `bool?` | yes | split per impl; a root over digests |
| 17 | Expanded | file | `List<DeclId>` | dense ids | value |
| 18 | Plain | file | `Parsed` | no (as 1) | digest only |
| 19 | References | whole program | `List<Ref>` | every column `@local` | split: `Refs(declaration)` |
| 20 | Failures | whole program | `Raised` | dense ids | one record per cycle group |
| 21 | HeldSig | module | `string` | yes | deleted at DB 07 (it is the hold) |
| 22 | Raised | declaration | `List<TypeId>` | `TypeId` | value |
| 23 | MethodDiags | file | `List<Diag>` | spans | value |
| 24 | LiftLowered | lift int (as 14) | `Unit` | as 13 | value |
| 25 | Syntax | declaration | `int` | yes | digest (the answer is one) |
| 26 | Names | declaration | `int` | yes | digest |
| 27 | Marks | declaration | `List<Diag>` | spans | value |
| 28 | Admitted | file | `Unit` | as 13 | deleted at DB 07 (by-name loading) |
| 29 | Named | int → name | `Unit` | as 13 | value |
| 30 | ReadReach | whole program | `int` | yes | one record per cycle group |
| 31 | DeclReads | declaration | `bool` | yes | value |

Count: 9 encode today · 3 never will (1, 11, 18) · 20 wait on DB 03. The four whole-program
families (16, 19, 20, 30) are the ones that make any edit O(program); each is split.

### 4.2 Every second mechanism, and the PR that removes it

| on main | size | removed by |
|---|---|---|
| std-relation `Memo<V>` and the Db write counter — a second memo engine | `db.av:475-580` | DB 01 |
| `Hooks`: nine erased closures; `opened`/`settled`/`running` unarmed | `db.av:50-62`, `workspace.av:581`, `decls.av:702` | DB 01 |
| `@input` (records nothing) vs `Memo.input` (records; 3 callers) | `input.av`, `query/memo.av:128-141` | DB 01 |
| world reads outside any door | 172 sites; ~50 behind `Host`; ~35 are not inputs | DB 04 a–e |
| `admit_embeds` (callee matched by the string `"embed"`) | `whole.av:171` | DB 04 c |
| `@family(rank, "Key", "Answer")` (unchecked strings) and `family_word`'s 32 arms | `families.av`, `workspace.av:523` | DB 12, a counter |
| the compiler's own `Db`, `DbRow` (8 durable variants), `DbKind`, `durable_key` | `compiler/db.av` (732 lines) | DB 06, then DB 12 |
| `Db.answers`, `answer_name`, the hex codec | `answers.av` (46) | DB 06 |
| hand format 1: `KeyParts` content key, `stands_in` | `record.av:1097-1306` | DB 07 |
| hand format 2: module record lines (`written_from`) | `record.av:840` | DB 07 |
| hand format 3: kept-settle lines `u c m f b e` (+ `l`, unlanded) | `kept_settle.av` (324) | DB 09 |
| hand format 4: `program_key` | `build.av:589-609` | DB 08 |
| hand format 5: links witness | `build.av:318-330` | DB 06 |
| hand format 6: `DocFacts` + `FileWitness`, `still_valid` | `compiler/db.av:84-153, 660-695` | DB 06 |
| hand formats 7–9: `proved_key`, `clean_key`, `canon_key` | `suite.av:184`, `derive.av:192`, `fmt.av:79` | DB 08 |
| five unvalidated remembered rows: `closure`, `embeds`, `homes`, `parts`, `seen` | `build.av`, `derive.av`, `record.av` | DB 08 (`parts`, `seen`: DB 07) |
| string-keyed memo maps: `Records` 12, `Keys` 8, `Hold` 6, Workspace 8, `Decls` 10 | 35 in the Workspace, 45 with `Decls` | each dies with the family it caches: DB 07; the three `*_asks_index` at DB 09 |
| `Store.keep`'s `read` slot, the `.deps` files (7,981 in one cache, never read back), `Stored.Sig`/`Fp` | `store/store.av` | DB 05 |
| a `@side` column a query cannot reach (`DocFact`) | `.57.9.7` | DB 06 |
| `Decls.gathered`'s raw bucket read (`collect`) | `decls.av:1336-1340` | DB 10 |
| `@std/meta` ask verbs, each its own extern row + evaluator arm + host closure | `meta.av:338-366` | DB 10 |
| `avra cache why / dependents / changed / held` (re-derive in process) | `cache_walk.av` (218) | DB 02 |
| three types named `Db` | sqlite, relation, compiler | DB 12 (the compiler's dissolves); D3 hides the relation's |
| `Expr`/`Stmt` as `@relation @arena` | relations in name only | **stays**: trees are blobs behind a query (L6) |

---

## 5. The engine and the plugin crossing

### 5.1 One kernel (DB 01)

- **One registration.** `@query`, `@input`, a relation's index bucket and a compiler family
  each register a kernel family by stable name (`@acme.icons.icons_in`). `@family` becomes a
  second spelling of that same call and is retired one family at a time (DB 12).
- **Every Db has a kernel.** A plain `new_db()` owns a private one. `Memo<V>`, the write
  counter and the unarmed hooks are deleted. The kernel moves below `@std/relation` so both
  packages use it directly.
- **A dependency is a packed int.** Today each edge is a boxed `Key`: 375 MB in 5,326,142
  boxes on a cold `check packages/cli` (MEASURED, ticket `.57.167`). Packed: ~9 B an edge
  (ESTIMATED) → ~48 MB.
- **A recorded read costs ≤ 350 instructions**, held by a census in CI. Today a kernel read is
  ~125 unrecorded · ~315 stamped repeat · ~1,900 first read (MEASURED, townhall :2753), and a
  recorded relation read is ~938 against ~90 raw (MEASURED, ticket `.57.8.1`). The townhall set
  350 as its own condition (:2106) and it was never held.
- **Refusals speak.** Two owners of one key, a late write, a cross-owner local read, a cycle,
  an unencodable key: each names the query and its key. Today they are bare traps.
- **Cycles.** A recursive query re-enters and contributes nothing (`start_recursive`). A
  set-growing group (`Raised`, reachability) is solved as one group and saved as one record
  with one set hash (townhall N5). A member whose answer shrinks is a defect, never a loop.

### 5.2 One input door (DB 04)

```avra
// PROPOSED — @std/source. Each is a kernel input: named, digested, recorded.
text("assets/schema.sql")        // string?        null = absent, and absence is recorded
bytes("assets/logo.png")         // Bytes?
range("assets/big.bin", 0, 512)  // Bytes?         the digest covers those 512 bytes only
listing("assets/icons")          // List<Entry>?   names and kinds, sorted; null = no directory
exists("tests/x.expected")       // bool
env("DATABASE_URL")              // string?        unset is not empty
tool("wasm-opt")                 // Tool?          identity by D9
target()                         // Target
pinned("https://…/pet.yaml", "sha256:…")   // Bytes — refused unless the pin matches
```

| rule | detail |
|---|---|
| names | `package:relative/path`, as written. Never absolute, never a `FileId`. A symlinked package is one file under two names: name it as written, digest the bytes |
| sources are always read and digested | no stamp shortcut (`92b24db`: 36–42 ms at 730 files, MEASURED) |
| the compiler and tools | identified by path + size + mtime (D9) — the one place a stamp answers |
| a per-process memo | holds the digest of bytes read *this revision*; dropped when the revision moves (`avra dev`, in-process edit suites) |
| not inputs | the store's own IO, a program's effects under the evaluator, phase timing, debug flags — ~35 sites, each `// LICENSED` at the site so the keeper's baseline can reach zero |
| clock, pid, argv, cwd | refused inside a query. `AVRA_CWD` is read by the driver and enters as an argument |
| a plugin | reaches the nine reads through host rows, under what its manifest grants (D6). `env`, `tool`, `pinned` are the compiler's own until D6 is decided |
| a native tool in a child process | "the tool opens nothing": a read is a message the compiler checks, answers and records (sources design :649). This document supplies the input mechanism; the protocol is the sources campaign's |
| package C run at const settlement | refused unless the row declares its inputs. Open; recorded under DB 04 e |

### 5.3 The saved-answer rule in the kernel (DB 06)

```
settle(q):                                      one append per read; no walk; nothing flattened
    q.reads = for each direct dep d of q:
        d is an input or a saved answer   →  (name(d), digest(d))
        d is in memory, owned by q        →  d.reads            (already a short list)
        d is in memory, owned by another  →  REFUSED at the read, naming q and d
    q is keyed by a durable name          →  append record(q) = digest · reads · value?
```

| question | answer |
|---|---|
| what failed on 09-28? | flattening: one transitive closure copied into 770 file records (33,286,285 edges; the direct deps of the same files were 13,578 — `3806c7d`, MEASURED). Not saving |
| is it a verifying or a constructive trace? | verifying. Values are also findable by content, so A → B → A is warm while the old record is still in the file |
| a query's own code | is a read: the digest of the unit that declares it. A plugin edit reruns that plugin's answers (pays `.57.4.6`) |
| the longest in-memory list | printed by `avra explain --stats`, with p99 reads per saved answer. A family that breaks the gate has the wrong key |
| the guard | `AVRA_DB_CHECK=1` runs an **edit corpus**: one mutation per input and per declaration of a fixture package, then compares against a cold derivation. A second run on an unchanged tree proves nothing |

### 5.4 The plugin crossing (DB 10)

| | today | PROPOSED |
|---|---|---|
| where a plugin query runs | each annotation run is a fresh machine; rows and memo die with it (READ(agent) `interp.av:220,362,404`) | registered in the **compiler's kernel**; only its body runs in the evaluator |
| how key and answer cross | `MetaVal` trees by slot order; no fn or `Cell` variant, so a `Db` cannot cross | the **same encoded bytes the store saves**. One codec for disk and for the crossing |
| a plugin's rows | in the evaluator's heap | the encoded answer of its query, held by the kernel |
| reading compiler facts | three ask verbs (`embed`, `type_named`, `type_exported`) | `@std/meta` row relations: `DeclRow`, `FieldRow`, `VariantRow`, `ParamRow`, `ImplRow`, `RefRow`. A decoded row is a different type with no `@local` columns (townhall §4.10) |
| names | `Field`, `Variant`, `Param` are already `@std/meta` types; `Decl` is a name it forbids (`meta.av:480-482`) | the `…Row` names above |
| `compiling()` | cannot exist as the first draft described | not needed: the Db is implicit (D3) |
| direction | — | core never reads a plugin relation; a plugin writes only its own answers |
| a plugin relation in a module nobody imports | would silently not register (townhall :2665, open) | a manifest dependency contributes all its files to registration. PROPOSED; decided in DB 10 |

Two defects are fixed first, each with its probe as the acceptance test: the annotation trap
(`.57.182`) and template hygiene (`.57.183`: a user relation named `Field` breaks inside
`relation.av`).

---

## 6. The store

### 6.1 Format (DB 05)

```
.avra-cache/<compiler print>/store        ONE file · memory-mapped · append-only
    header    magic · format · compiler print
    segment*  each ends in a commit marker (length + checksum); a torn tail is ignored
        names     name bytes → name id            interned once; ids are this store's own
        inputs    name id · kind · digest         THE MANIFEST: every input any saved answer read
        records   name id · shape · value digest · reads[(name id, digest)] · value
                  value = Inline(bytes) | Blob(sha256, size) | None (digest only)
        readers   name id → [record name id]      the reverse index
        index     name digest → newest record offset
.avra-cache/<compiler print>/obj/, bin/   object files and binaries stay files (the linker opens them)
~/.avra/cache/bytes/<hh>/<sha256>         big values by content; shared across worktrees (DB 11)
```

Why not a file per record: one root holds 8,440 files today; opening 1,300 small files costs
60–100 ms and 10,994 costs 490 ms (PROBED by the review, warm page cache). The no-op budget
is 60 ms.

### 6.2 What a warm command does, in order

| # | step | cost on `packages/cli` |
|---|---|---|
| 1 | start; map the store; find the last commit marker | ~15 ms (MEASURED 09-21: "startup 15") + < 2 ms |
| 2 | **the manifest first**: digest every input it names | 20–40 ms for ~730 sources (PROBED by the review) |
| 3 | each changed input → the reverse index → its transitive readers are *suspect* (ids only; nothing decoded) | microseconds per reader |
| 4 | the command asks its roots. An answer that is not suspect stands **untouched** | < 2 ms when nothing moved |
| 5 | a suspect answer is verified root-down: its suspect reads first; recompute only on a real mismatch; **early cutoff** — same digest, so its readers stand | one declaration re-typed: 5–30 ms |
| 6 | whatever a recomputation needs is loaded **by name**, in place, on demand | no load or admit phase |
| 7 | append the new records, the reverse-index delta and one commit marker | 2–10 ms |

Floors (ESTIMATED from the measured parts): unchanged 40–60 ms · one body edit 60–110 ms.
The ancestor of this tree measured 0.04 s and 0.18 s on 09-21 at file grain (§7.1).

### 6.3 Names (L5; DB 03)

| thing | name | note |
|---|---|---|
| package | `@acme/icons` | |
| module | `@acme.icons.render` | imports are canonical: one module, one spelling |
| file | `@acme/icons:src/render.av` | as written, relative to its package |
| declaration | file · owner path · name · sibling | `sibling` counts same-(owner, name) declarations only — the recorded key (`decl_rows.av:26-31`). Two `impl X`, or one private name in two files of a module, stay apart. Inserting a declaration above moves nothing |
| generated declaration | its maker's name · its own name · sibling | the maker is (annotation, annotated declaration, argument digest) |
| a local id (`ExprId`, `StmtId`, a lambda) | (owner declaration, index within it) | never saved outside its owner's value |
| a span | (anchor declaration, offset from its start) | also for a span into *another* file: a copied template, a reference site, a raised site |
| a type (`TypeId`) | its spelling as a tree, declared types by name | never the interned id |
| an input | kind · `package:path` (· range) | |
| a query answer | the query's own path · its key's encoded bytes | each component length-prefixed: `("a.b","c")` is not `("a","b.c")` |

The honest cost: `sibling` is an ordinal, confined to same-named siblings of one owner. The
first draft's "never an ordinal" could not name the second `impl X`.

A comment above a declaration: `Text(file)` moves → the file is parsed → every declaration's
`Syntax` digest is unchanged → nothing above stands on absolute offsets, so everything stands.

### 6.4 Processes, crashes, other compilers

| case | answer |
|---|---|
| crash mid-commit | no commit marker → the tail is ignored; the previous state is whole |
| two processes | a segment is one `write` on an append descriptor under an advisory lock; a reader sees whole segments. A process that cannot take the lock skips saving — a lost write is a recompute |
| two processes that saw different inputs | each record carries the digests *it* saw; a reader validates against the world *now* |
| a store from another compiler | a different directory (the compiler print), and the header repeats the print. Never read |
| a compiler rebuild | a new store; nothing derived survives (D8-B). Bytes in the byte store survive |
| a record of another shape | the shape fingerprint differs → not read. Nothing decodes across shapes |
| growth of the file | records only append. `avra cache gc` rewrites the live ones and renames; the newest four compilers are kept (today's rule) |
| a value's blob is gone | the record does not stand; a swept blob is a miss, never an error |

### 6.5 The codec (L7)

One codec, derived from the type: length-prefixed strings (NUL is data), count-prefixed
lists, one presence byte per `?` layer, an enum by its variant's **name**, every sequence
folded to one value. It must grow payload enums and recursive records (refused today:
READ(agent) `relation.av:296-306`), or `Lifted`'s generated code cannot be saved. A `fn`,
`Cell` or `Map` field is refused at the declaration, naming the field: that answer is
digest-only.

---

## 7. Speed: what is measured, the targets, the gates

### 7.1 Baselines and the regression

| what | value | source |
|---|---|---|
| 09-21 `check cli`, one edit, cold process, 289 files | **~0.18 s** (startup 15 · load 36 · mint/fill 26 · parse+typing ~20 · lower 16 · keep 16 ms) | MEASURED `2026_09_21_COMPILER.md:136-150` |
| 09-21 `check cli` no-op · `build cli` no-op · `build cli` one body edit | ~0.04 s · 0.08 s · 0.31–0.40 s | same |
| 09-30 warm one-line edit | 20.9 s → 2.3 s | MEASURED `e203c0d` (#48) |
| 10-01 warm one-line edit | 8.06 → 5.93 s, then 6.30 → **4.27 s** | MEASURED `e61260b` (#119), `b8311ee` (#124) |
| 10-01 its phases | ast, sublang, load, admit: ~1.0–1.4 s each | MEASURED (inventory G2; A8) |
| today `check cli` no-op, 408 files | 0.22 s | MEASURED ticket `.57.6.5` |
| cold `check cli` peak | 1,869 MB; 375 MB of it dependency edges; 412 MB per-declaration fact columns | MEASURED tickets `.57.167`, `.57.168` |
| a partly-held rebuild | 3,442 MB against 2,168 MB cold | MEASURED ticket `.57.163` |
| file-then-directory test | past 4.5 GB → 2,153 MB with PR #289 | MEASURED PR #289 |

The three warm-edit rows are separate before/after pairs on different days, not one series.
**Why 0.18 s became seconds is INFERRED, not measured**: the dates fall inside the campaign
that moved declarations into recorded relation rows, and the four phases above are
O(program). Inputs also grew (289 → 408 files).

### 7.2 Targets and CI gates (`packages/cli`, cold process, no daemon)

| scenario | gate | goal | today |
|---|---|---|---|
| unchanged `check` | ≤ 60 ms | 40 ms | 220 ms |
| one body edit, `check` | ≤ 300 ms | 150 ms | 4.27 s |
| one body edit, `build` | ≤ 500 ms | 300 ms (the link is ~110 ms) | unmeasured since 09-21 |
| one signature edit | proportional to the declarations that mention the name | — | unmeasured |
| any partly-held state: time and peak | ≤ cold | — | 1.6 × cold |
| a recorded read | ≤ 350 instructions | — | ~938 (relation) |
| cold, saving on against off | ≤ +15 % (ESTIMATED; M4 sets it) | — | — |
| longest in-memory read list; p99 reads per saved answer | set from M2 | — | — |

The time rows run on the CI runner with an instruction-count twin, so machine noise cannot
hide a regression. The gates switch on as each PR makes them reachable (§8). Every timing
round uses fresh edit text: a repeated text is a cache hit (HANDOFF 10-01 :100).

### 7.3 Three measurements still owed — being run by `db-measure`

| # | question | result | what it changes |
|---|---|---|---|
| M1 | How big is the kernel's graph on a cold `check cli`? 51.6 M (an uncommitted count, townhall :2427) or ~5.3 M (ticket `.57.167`)? | **PENDING M1** | ~5 M: save every cell's digest and reads; L4's refusal is a lint; DB 06 is simpler. ~50 M: the refusal is a correctness law and DB 03 must finish before DB 06 saves a compiler family |
| M2 | Under L4: how many saved answers, reads per answer, the longest in-memory list? | **PENDING M2** | §4.1's "saved as" column; the two gates in §7.2; the store size (ESTIMATED today: ~80 k records, ~2.4 M reads, 15–20 MB) |
| M3 | Where did 0.18 s → 4.27 s go? A bisect of the one-edit benchmark over ~6 commits | **PENDING M3** | if recorded relation reads are the cause, DB 01's read budget comes before any further family conversion (as ordered). If not, the order of DB 01–03 is free and the named phase gets its own PR |

M4–M7 (bytes per row, digest MB/s, store IO, where the 220 ms no-op goes) are measured
inside DB 05 and gate nothing earlier.

---

## 8. The PR list

Each lands alone and leaves main green. "Ladder" is what the seed and generation laws cost
(CLAUDE.md "How work lands"). Order matters: 00 → 01 → 02, 03, 04 → 05 → 06 → 07 → 08, 09 →
10 → 11. DB 12 runs throughout.

| PR | ticket | what lands | "when this lands, the owner can run …" | ladder | closes |
|---|---|---|---|---|---|
| **DB 00** secure, measure, fence | `.57.169` | the M1–M3 harness landed from branch `db-measure` (`tools/db_measure/`: kernel counters behind an env flag, `warm_edit.sh`); PR #289 landed with `make turn-memory-attack` in CI; `keepers-green` landed: `make keepers` (codecs, fmt-lossless, cache-attacks) on every PR and train; defects filed | `make keepers` green and required · the counters flag on `build/avra check packages/cli` prints the per-family table · `sh tools/db_measure/warm_edit.sh` prints the one-edit median | none | `.57.165`; the memory half of `.57.163` |
| **DB 01** one engine | `.57.170` | §5.1: `@query`/`@input` are kernel cells on every Db; `Memo<V>`, the write counter, the unarmed hooks deleted; packed deps; the read-cost census; refusals name the query; `make families` starts at 32 | three pure queries each run **once** after an unrelated insert (nine times today) · `Kernel.newly_read` < 60 MB (375 today) · `make read-cost` ≤ 350 | the kernel moves below std-relation: no new syntax, `seed-check` must pass; build twice before trusting a peak | `.57.167` |
| **DB 02** `avra explain` | `.57.171` | §3.6 over the in-memory graph; `--stats`, `--why`, `--json`; never writes; `avra cache …` become aliases | `build/avra explain --stats packages/cli` · edit a file, `explain <file> --why` names what moved · twice gives the same output | none | — |
| **DB 03** names and the id codec | `.57.172` | §6.3 and §6.5: `Decl` gets its key; typed ids encode as names, local ids as (owner, index); the codec grows payload enums and recursive records; a round trip per encodable family | `make codecs` round-trips every encodable family answer · a declaration inserted above changes no other declaration's bytes | none expected | — |
| **DB 04** the input door a–e | `.57.173` | §5.2 as five PRs: (a) the digest row; (b) `Source`, `Manifest`; (c) `embed`, listings; (d) env, tool, target, compiler; (e) the rest by subsystem. `make inputs` with site licences | `make inputs` prints the count outside the door and fails on a new one · `explain --stats` lists inputs by kind | (a) is **two landings**: the row, then its declaration after the seed refresh | `.57.184` |
| **DB 05** the store | `.57.174` | §6.1, §6.4: today's rows move in as opaque values first, so no meaning changes. M4–M6 measured here | one `store` file per compiler · `make cache-attacks` green · the kill-mid-commit and two-process attacks pass | none | — |
| **DB 06** the saved-answer rule | `.57.175` | §5.3, on by default by key. First consumers are already pure lists: the compiler's two `@query` (`DocFacts`, `FileWitness`, `still_valid` deleted) and the links witness. The edit corpus | `build/avra docs LanguageFeature` twice on std-avrac: the second ≤ 0.05 s · `make db-corpus` · the 17 `redteam/m3-witness-attacks` cases pass | none | `.57.9.7`; absorbs `.57.101.12`, `.57.12.5`, `.57.4.6`'s unpaid half |
| **DB 07** per-declaration answers; the hold deleted | `.57.176` | §4.1 rows 2–10, 13, 16, 19–23, 25–28; `KeyParts`, `Keys`, `stands_in`, `verify_held`, `HeldSig`, the module record lines and the memo maps deleted; no O(program) phase on the warm path | `sh tools/db_measure/warm_edit.sh`: unchanged ≤ 60 ms, one body edit ≤ 300 ms · the `.57.163` repro peaks ≤ cold | none for the seed; the riskiest — lands behind the edit corpus on a Sprite | `.57.163`; absorbs `.57.101.11` |
| **DB 08** roots | `.57.177` | `Verdict(package)`, `Linked(program, target)`, `Proved(suite)`; `program_key`, `proved_key`, `clean_key`, `canon_key` and the five remembered rows deleted; tools, env and link words are inputs | `build` after one edit ≤ 500 ms · change `CC` → relink · edit a test → the suite binary is rebuilt | none | links `avra-8sb5.68`, `.69`, `.31`, `.25.20` |
| **DB 09** `Settled` and `Lifted` | `.57.178` | `kept_settle.av` deleted; its tiers become four digest-only answers (appendix A4); `Lifted` saved with relative spans | a comment above 1,000 generated types: ≤ 0.06 s (0.25 s today) · cache-attacks green with the layout line deleted | none | — |
| **DB 10** the plugin crossing | `.57.179` | §5.4; `…Row` relations; `collect` membership recorded; the lint arm (D5); plugin reads under grants (D6) | the two-package probe prints `a_close \| b_open` (a trap today) · add a `@model` type → only the lint that asked reruns | each host row is **two landings** | `.57.182`, `.57.183` |
| **DB 11** byte store, `Blob`, gc | `.57.180` | §6.1's byte store (SHA-256, verified on first use); `avra cache gc` | `build/avra cache gc` · two worktrees share one copy of a 5 MB input | none | links `avra-8sb5.37`, `.40.17` |
| **DB 12** families → `@query` | `.57.181` | not one PR: `make families` prints N of 32 and may only fall; a family converts in the PR that touches it. At 0: `@family`, `family_word`, the compiler's `Db`/`DbRow`/`DbKind` are deleted | `make families` | a bridge only where the compiler checks the change about its own source | `.57.12` on adoption |

**Live bugs stay open with their repros** until the PR above passes them: `.57.163`,
`.57.165`, `.57.9.7`, `avra-8sb5.46` and `.79` (weak hashes — no PR here touches the
in-process hash; linked, not absorbed), `avra-8sb5.68`, `.69`.

---

## 9. Decisions this document reverses

"A decision is reopened only with a measurement" (townhall :2065).

| earlier decision | now | the measurement or the word |
|---|---|---|
| first draft: opt-in `@kept` | always save (D1) | the owner, 10-06. And the cost it feared was flattening: 13,578 direct deps against 33,286,285 flattened (`3806c7d`) |
| first draft: hand-written `cover` per family | none; ownership follows the key | `.57.101.11`: an interface-only digest is not a superset of what importers read. A cover that lies cannot be seen by a double run |
| first draft: `Icon.insert` inside a query | a query answers rows (D4, pending) | PROBED `c1`, `c4`: empty and stale reads; the sketch's own key traps |
| first draft: families convert last, in one PR | a counter from DB 01 (D2) | the owner, 10-06 |
| first draft: gate one edit at 2.0 s | 300 ms (D7) | this tree measured 0.18 s on 09-21 |
| first draft: one file per record | one packed file | 1,300 opens = 60–100 ms. This restores townhall §6.6 |
| first draft: "everything is a relation", `Expr.by_shape` | every fact is a query answer; the AST stays an arena | townhall P4 ruling (:2761); a first read is ~15× |
| townhall §6.5a: the durable witness is `KeyParts`; kernel-grain deps stay in process | `KeyParts` is deleted at DB 07 | **PENDING M1/M2.** "≥51.6 M deps" was never committed; two later measurements say ~5 M |
| `.57.148`: keep `@family(rank, key, answer)` | families become `@query` | the owner overruled it, 10-06. `.148` stays closed |
| COMPILER.md law 6: "The sources are the hold's oracle. A hold bug costs time, never a wrong answer" | retired at DB 07. The net is the edit corpus in CI, and `--cold` stays as the oracle | the hold is what re-asks the sources; it is deleted. **Named because the safety net changes** |
| sources §15a Q12: the two doors are designed with the owner | unchanged. This document supplies the mechanism; the grant policy is D6 | the first draft claimed the doors silently |
| COMPILER.md: no resident compiler | stands | the targets need no daemon (§6.2) |

Restored without change after the first draft dropped them silently: "durable by default,
with nothing to tune" (townhall :2277) · a recorded read ≤ ~350 instructions (:2106) · a
decoded row is a different type (§4.10) · core never reads a plugin relation (:2656).

Hostile cases, each answered: appendix A0.

---

# Appendix — evidence. Not needed to start.

## A0. Hostile cases

| case | what happens |
|---|---|
| a file added to a folder | `Listing(dir)` moves → whoever listed it reruns |
| a third module declares a name two others already declare, in a file nothing has read | the package's listing is a read of the name lookup; it moves (attack carried from DB_REDESIGN :268) |
| a comment above a saved expansion | `Syntax(declaration)` unchanged → `Lifted` stands; spans are relative (§6.3) |
| a generic's body, a const's value or a copied template edited in another module | the reader read `Lowered`/`Settled`/the template's `Syntax` of *that declaration* — a saved answer, in its list — so it reruns. An interface digest alone would miss it |
| a new `impl` anywhere | only the per-impl answer and the roots over digests are visited; a `Typed` that never asked about that type stands |
| an empty index bucket later gains a row | the read recorded the (empty) owner-level answer; it moves |
| a dependency's manifest changes | `Text(dep:avra.toml)` → `Manifest` reruns → early cutoff if the resolved graph is the same |
| an env var read at compile time | the compiler's own: an `Env` input, unset ≠ empty. A plugin's: refused unless granted (D6) |
| a tool upgraded | its identity moves → `Linked` reruns (today: nothing — `avra-8sb5.68`, `.69`) |
| clock skew, equal mtimes | irrelevant for sources: nothing answers from a stamp |
| a key holding a dense id | refused at the declaration: a key must encode. In memory, dense ids are fine |
| a value holding a closure or a `Cell` | digest-only; the value stays in memory |
| a cycle; a query that refused; a budget stop | never saved (§2). A set-growing group is one record |
| a query declared in an imported module whose body changes | its code is one of its reads (§5.3) |
| a plugin that lies about purity | it cannot read the world except through host rows; the edit corpus catches a stale answer in CI |
| map iteration order | a `Map` field is refused by the codec; set hashes are order-free; a list answer keeps the query's order |
| the empty case of every encoding | absent ≠ empty input · no directory ≠ empty listing · an answer with zero reads stands always and `explain` says so · `T??` keeps both absences |
| 10,000 rows of one relation | buckets are two-level (§3.2); a bucket hash is a sum over finalised row hashes, so swapped fields do not collide (townhall :2370) |
| a 5 MB input | digested once per revision by a C row; stored once by content |
| a symlinked package | named as written; the bytes are digested (§5.2) |
| two worktrees | each has its own store; they share only bytes |
| the 17 cases of `redteam/m3-witness-attacks` | appendix A5; all are DB 06's acceptance |

## A1. Laws carried from the documents this one replaces

Deleting the old documents loses nothing below. Sources: **C** `2026_09_21_COMPILER.md`
(on main; describes what is on main; deleted by DB 07) · **RD** `2026_09_24_DB_REDESIGN.md`
(on main; deleted by DB 06) · **TH** the townhall (kept as history).

| law | wording | source | where it lives now |
|---|---|---|---|
| a file's object is the file's | "every plain body it declares, so no program's reach shapes it" | C:85 | DB 07 keeps one object per file; per-function objects stay refused (C:510) |
| an instantiation is the program's | "owned by no file, weak, riding the program's module" | C:87 | `Lowered(declaration · type args)`; A0 row 4 |
| a generic's home is never held while an instantiation is owed from it | | C:91 | becomes a read: the instantiation reads the home's `Lowered` |
| a layout is one law's answer and it is in the interface | | C:95 | `Layout(type)`, appendix A4 |
| a file's key folds what its bodies can see | "its text, its own module's interface, the closure of its imports, the texts its compile-time runs read" | C:97 | replaced by the recorded read list |
| a refusal is never kept | | C:118 | §2 |
| an incomplete query result must not be memoized | "`methods(target)` cached empty while resolving" | C:273 | §2 |
| a whole-program pass never runs inside a resolve | | C:271 | §4.1: the four whole-program families are split |
| a store is one compiler's | "`.avra-cache/<print>/` … the newest four kept" | C:114 | §6.4, D8 |
| move the content, not the key | | C:191 | L3 |
| held by name is held by accident | | C:195 | L5 |
| a symbol outlives every id a run hands out | | C:197 | L5 |
| the binary's key covers the closure the last derivation admitted | | C:202 | `Linked`'s read list (DB 08) |
| a list that only grows is a hold that only shrinks | | C:211 | reads are per answer, per run |
| the gate never edits a file | "so it cannot see a hold wrong for an edit nobody tried" | C:229 | the edit corpus (§5.3) |
| a suite that never held attacked nothing | "22 green steps at `held 0/6`" | C:231 | every attack asserts a *count* of answers that stood |
| a cache can cost more than what it keeps | "A type-wire memo doubled `fill`; a stamp row per file lost to reading the file" | C:238 | value-or-digest is measured (M4) |
| a text record spends its separators; the empty name is a name | | C:244 | §6.5: length-prefixed |
| a memo keyed on nothing answers for the day it was filled | | C:247 | every memo is a keyed query |
| a workspace is an identity, never a value | | C:252 | unchanged |
| the saved-answer rule, first written | `if !record.deps.all((d) -> current_content_hash(d) == d.content_hash) { return null }` | RD:134 | L3 |
| closures never become rows | "`Analysis` … never becomes a `Row` — it holds a closure" | RD:75 | §4.1 row 11 |
| one Db per command | LANDED `514c5f9`: −42.6 % instructions | TH:2067 | unchanged |
| dense addressing only | "No scans, no whole-collection `get()` on a hot path, no string keys built per ask" | TH:2072 | names are interned to dense ids at once (TH:2510) |
| a witness is (stable name, value hash) | "Never a dense id, never \"was it read\"" | TH:2086 | L3, L5 |
| a row and its witness settle in one step | | TH:2094 | §6.1: one record, one commit |
| a query owns its rows; a rerun upserts by key | | TH:2150 | superseded by D4: a query answers rows |
| a query never reads the relation it owns | | TH:2158 | holds trivially under D4 |
| no cascade | "A row referencing a vanished row is not deleted: its reader's witness fails" | TH:2161 | a missing read is a mismatch |
| two owners, one key, is refused, naming both | | TH:2163 | §5.1 refusals |
| a row with no owning query is an input | | TH:2166 | L6 |
| a relation's stable name is its import path | | TH:2312 | §6.3 |
| a key says what the source declares, never where | | TH:2324 | §6.3 `sibling` |
| a missing dep is a mismatch | | TH:2349 | §6.4 |
| a phantom read: a new row under a key someone looked up | "an index bucket is itself a Kernel cell" | TH:2366 | §3.2 two-level buckets |
| a bucket hash is a sum through a nonlinear finalizer | "(a,1),(b,2) and (a,2),(b,1) sum alike" without it | TH:2370 | A0 |
| registration is the declaration | "a dense family slot by its STABLE name … never persisted" | TH:2647 | §5.1 |
| a core answer must not depend on demand order | | TH:2653 | unchanged; a plugin asking first exposes the bug |
| arena relations record at the owner's grain, never per node | | TH:2735 | L4, L6 |
| a per-query seen set allocated at every begin | "+14.9 % … did not ship" | TH:2757 | DB 01: nesting safety allocates nothing |
| fixpoint semantics | worklist over the group; a shrinking member is a defect; a turn cap speaks | TH:2877-2888 | §5.1 |
| persisted rows key by a member's name, never its position | "a test must add a member in the middle" | TH:1304 | DB 03 acceptance |

Open items of C §7b that survive (the rest are closed by a PR above): the parser fast path
(C:386) · a kept suite verdict needs `[test] hermetic` — owner's call (C:388) · the seal is
whole-program, `avra-8sb5.21` (C:396) · a `dyn` field boxes only where the trait is imported,
`.22` (C:399) · a lone file outside a checkout has no prelude, `.20` (C:400) · `codes.av`
never moved (C:417).

## A2. The nine hand-written validity formats, and the five rows nothing validates

READ(agent) `agent-facts.md` §7. The first draft counted four.

| # | format | records | holes | removed by |
|---|---|---|---|---|
| 1 | `KeyParts` | module, path, text digest, digests of texts its compile-time runs read, each seen module's interface key | which runs and modules is read from format 2; env, tools, listings | DB 07 |
| 2 | module record lines | per file: the text print it was written from | the rest of the record is trusted once the print matches | DB 07 |
| 3 | kept-settle lines | `u c m f b e` + the value in a second row (two writes, not atomic) | env read by the evaluator, spawns; A4 | DB 09 |
| 4 | `program_key` | compiler id, entry, every build input, embeds, package objects | the *set* comes from unvalidated rows; linker, `CC`, link words | DB 08 |
| 5 | links witness | each linked file + its digest | none — already a pure list | DB 06 |
| 6 | `DocFacts` + `FileWitness` | root, listing digest, (path, digest) per file read | reads `@std.io` directly; absent = empty | DB 06 |
| 7 | `proved_key` | path, the `.expected` text, every reachable file's digest | `.refuses` markers, target | DB 08 |
| 8 | `clean_key` | `asked_print` of the instantiation roots | key existence only | DB 08 |
| 9 | `canon_key` | compiler id, block-word key, the file's text | needs a parse before the lookup | DB 08 |

Unvalidated, feeding the keys above: `closure` (`build.av:526`), `embeds` (`build.av:538`,
added by #282), `homes` (`derive.av:189`), `parts` (`record.av:1310`), `seen`
(`record.av:1323`). #282 added a line kind, key lines and a remembered row: one fix, three
hand sites.

## A3. World reads by subsystem (the split of DB 04)

READ(agent) `agent-facts.md` §5: 152 file/dir/env/tool/spawn call lines + 20 clock lines = 172.

| group | sites | PR |
|---|---|---|
| behind `Host` already (`modules.av` 11, `suite.av` 10, `build.av` 9, `packages.av` 6, …) | ~50 | DB 04 b, c — one change at the `Host` record (`cli/commands/shared.av:63-75`) |
| recorded by the kernel today (`Source`, `Manifest`) | 2 | DB 04 b |
| CLI plumbing and tool discovery (`shared.av` 35) | 35 | DB 04 d |
| `dev.av` 12, `fmt.av` 7, `process.av` 5, `test.av` 3, `stage.av` 3 | 30 | DB 04 e |
| `build.av` 8, `compiler/db.av` 4, `whole.av:555` (link-word env), debug flags | ~15 | DB 04 d, e |
| **not inputs** — licensed at the site: `store.av` 5, the evaluator's 6, 20 clock lines, `AVRA_QTRACE`/`DEP_AUDIT` | ~35 | DB 04 e |

## A4. What replaces `kept_settle.av` (DB 09)

READ(agent) `agent-facts.md` §8. Two of its line kinds are not "every digest matches":

| line | today's check | becomes a read of |
|---|---|---|
| `u` a unit the run lowered | text same, OR (file not held AND declaration syntax same), OR (not entered AND one wanted AND re-lowered call shape same) | `Syntax(declaration)` when the run entered the body; `CallShape(unit)` when it only reached it |
| `f` a file of a seen module | text same, OR (file read this process AND outline same) | `Outline(file)` |
| `c` a const the run read | re-settle and compare | `Settled(const)` |
| `m` a module seen | file list equal as text | `Listing(module directory)` |
| `b` budgets | equal | an input: the budget configuration |
| `e` an embedded file | digest, or `!why` | `Text(path)` — absence is its own value |
| `l` layout (unlanded, `keepers-green`) | the crossing layout of the const's type | `Layout(type)` |

Each OR is a monotone chain (text same ⇒ syntax same ⇒ call shape same), so the coarse tier
is early cutoff for the fine one — which is what a digest-only saved answer gives for free.
The four write-time vetoes (an unnameable read `x`; `body_asks` moved; a non-structural
refusal; seats present) become one law: such a run is not saved. Open: validating
`CallShape` means lowering the unit; if that costs more than it saves, the read stays at
`Syntax`.

## A5. Attack cases carried

From `origin/redteam/m3-witness-attacks` @ `a644ba4` (written against deleted code; "6 of 17
cases fail by design, and one case traps"). Each asserts the correct behaviour:

| case | the attack |
|---|---|
| ATK1 | a file with a diagnostic gains a leading comment between processes → the fresh report, never the stored positions |
| ATK2a | a new sibling file defines a name the file could not resolve → fresh |
| ATK2b | a new earlier file adds a second impl of a method → a clash, even when another file ran the scan first |
| ATK3 | a callee's return type changes; the caller is unchanged → a fresh type error |
| ATK6 | two files in one process: every file records the same edges, not only the first asker |
| ATK9 | the callee is deleted, its file stays → undefined, never a stored "clean" |
| c-Parsed | a file that never existed is not a hash; a removed file ≠ an emptied file |
| c-Sig, c-Methods | a removed declaration's edge is unresolved, not a hash |
| d | the record-shape fingerprint is compared |
| c-Manifest | an ordinal past the packages answers unresolved, never traps |

Also carried: the two-process stale refusal pinned in `cache_attacks` ("a signature edit
re-reads its importers, a body edit holds them", TH:2445) · `("a.b","c")` against
`("a","b.c")` (TH:2319) · the 62-build `make cache-attacks` (C:154) · `tools/hold_sweep.sh`
(every source touched, one at a time) becomes the edit corpus.

## A6. The review's probes, kept as repros

| probe | output | shows |
|---|---|---|
| `c1` | `before=0 cached_before=0 first=3 … after set_listing, before re-ask: rows=3 count=3 \| reasked=1 rows=1 count=1` | a reader of `Icon.by_set` sees nothing until someone asks the producer, and stays stale after the input moves |
| `c3` | `icons,fonts,pure,icons,fonts,pure,icons,fonts,pure` | on a plain Db any write invalidates every answer |
| `c4` | ``avra: `Icon` row 0 is written by two owners`` | the first draft's own schema traps over two folders sharing a file name |
| `a5` (= `/tmp/db-doc/t2`) | ``side table `of_expr` holds [0, 31) — id 37 is outside it`` | an annotation calling a `@query` traps the compiler |
| `a2`, `a4`, `a6` | ``side table `alias_copies` holds [0, 47) — id 137 is outside it`` | the same for a relation member |
| `e3` | `a hole in name position takes a string, an int or a named meta value, found Code` | `${name(x)}` is not the spelling; `${x}` is |
| `e6` | 6+ errors inside `relation.av:682-689` | a user relation named `Field` (bug `.57.183`) |

Sources under `/tmp/db-review-consumers/` and `/tmp/db-doc/` do not survive a reboot; the
two-package repro is written out in ticket `.57.182`.

## A7. Prior work: where it is

| what | where | state |
|---|---|---|
| the direct-dep witness prototype (one family recorded, root-down validation, never measured end to end) | `origin/perf/witness-folded` @ `c7a1756` | unlanded; the closest prior art to §5.3 |
| the deleted 09-28 layer: `witness.av` 1,067 lines, `store/pack.av` 649, `store/explain.av` 212 | `cd3df92` (ancestor of main; tags `db155-prerebase`, `db47-preraid`) | re-runnable |
| the pack remainder: `pack.av` 640 | `dcaba11` (ancestor of main) | re-runnable |
| 17 witness attack cases | `origin/redteam/m3-witness-attacks` @ `a644ba4` | A5 |
| `DbKind` as a `collect enum` | `origin/lane/n3-apply` @ `af411a2` | moot at DB 12 |
| one derivation alive at a time | PR #289, `origin/warm-memory` @ `210caa0` | open; lands in DB 00 |
| the `Line` layout fix; three keepers into CI | `origin/keepers-green` @ `a23c730` (`01c219c`, `5f495f5`) | branch only; lands in DB 00 |
| the embed law | PR #282 → `04a6a89` | merged |
| the build-time sources design | `origin/sources-design` @ `06594b4` | the consumer brief; §1 is not replaced until D6 |
| hand `ReachWitness` (70/70 held, ~3 % win: 3.90 → 3.78 s) | `avra-warm101-11` — **deleted with its worktree**, never committed | only its finding survives (§9 row 2) |
| typed `it.mark.args[i]` in `collect`; a doc-fact witness test | `origin/q148-prototype`, `origin/docfact-side` | 0 commits ahead of main; mostly on main as `collects/order.av` |

## A8. Measurements, with their sources

| what | value | source | kind |
|---|---|---|---|
| flattened witness, cold `check std-avrac` | 74,600 edges/file median; 33.3 M edges; pack 279 MB; +62 % / +38 % / +116 % / +216 % | TH:2404-2413 | MEASURED |
| direct deps of the same 770 files | 13,578 (17.6/file, median 9) | `3806c7d` | MEASURED |
| "kernel grain": ≥2.54 M keys, ≥51.6 M deps | "still climbing when stopped"; no commit, no harness | TH:2427-2434 | UNREPRODUCIBLE |
| `Kernel.newly_read`, cold `check cli` | 375 MB in 5,326,142 live boxes, ~70 B an edge | ticket `.57.167` | MEASURED |
| same, earlier run | 363 MB in 5.1 M boxes | `avra-8sb5.76` | MEASURED |
| per-declaration fact columns | 154 MB (`side_table<bool>`, 142,264 tables) + 258 MB (`side_grow<DeclAt>`) | ticket `.57.168` | MEASURED |
| kernel read | ~120 unrecorded · ~315 stamped repeat · ~1,900 new dep | TH:2753 | MEASURED |
| relation recorded read | ~938 instructions against ~90 raw | ticket `.57.8.1` | MEASURED |
| `KeyParts` hold on a warm cli edit | 397/399 held "at near-zero cost" | TH:2436 | MEASURED |
| always-hash sources | ~36–42 ms at 730 files | `92b24db` | MEASURED |
| hashing all 1,513 `.av` under `packages/` (11.0 MB) | stat 3.2 ms · read 31 ms · read + SHA-256 40 ms | review E3 (Python, warm cache) | PROBED there |
| opening small store files | 1,300 = 60–100 ms · 10,994 = 490 ms | review B5 | PROBED there |
| one `.avra-cache` root | 8,440 files / 108 MB | review E1 | PROBED there |
| `.avra-cache` across worktrees | ~15.9 GB over ~140 worktrees | ticket `.57.18.4` | MEASURED |
| warm no-edit check | 0.36 B instructions, peak 7 MB | TH:2497 (`1c0cad6`) | MEASURED |
| `avra docs LanguageFeature`, second call | 8.05 s → 0.037 s | RD:19-24 | MEASURED |
| 1,000 generated types, a comment edit | 0.04 s → 0.25 s | sources design :212 | PROBED there |
| twelve turned attempts | peak 92 MB under a 273 MB ceiling | PR #289 | MEASURED |
| the witness as landed 09-28 | cold 27–38 s against 6.3–10 s; edited 95–150 s; OOM at 4.4 GB → shipped off | `e4d4420` | MEASURED |
| packed dep ≈ 9 B · saved records ≈ 80 k · reads ≈ 2.4 M · store 15–20 MB · cold cost +10–15 % | — | review E2 | ESTIMATED |
| rustc pays ~15–25 % of a cold build for incremental bookkeeping | — | review E1 | RECALLED, unchecked |

Not measured anywhere: bytes per relation row · codec throughput · digest MB/s
(`digest_bytes` is an Avra loop) · lines per kept settlement. Owed by M4–M5 inside DB 05.

`READ(agent)` in this document means one of: `agent-facts.md`, `agent-consumers.md`,
`agent-history.md`, `agent-sweep.md` (the review's evidence, 2026-10-05) or the prior-art
extraction made for this rewrite. The line numbers were read by those agents at
`origin/main` @ `05fe643`; re-open a line before building on it.

## A9. What this document absorbed

| document | fate |
|---|---|
| the first draft of this file (`516bbed`) | replaced. Kept from it: L1, L3, L5, L7, L9 in outline, the input kinds, the hostile-case list |
| the independent review (REVIEW.md, 493 lines, sections A–H) | every blocking flaw B1–B11 is answered above; its probes are A6, its order is §8 |
| `2026_10_06_DB_INVENTORY.md` + eight sub-reports (≈585 KB) | deleted from the branch. Its two useful tables are A7 and A8; the rest is in branch history at `516bbed` |
| `2026_10_06_DB_HANDOFFS.md` | deleted; its dispositions are ticket edits. Its H14 (a message to legacy sessions) is dropped: nothing is relayed |
| `2026_09_26_COMPILER_DB_TOWNHALL.md` | kept as history, marked superseded at its top |
| `2026_09_24_DB_REDESIGN.md` | on main; where the rule was first written (RD:132-138). Deleted by DB 06 |
| `2026_09_21_COMPILER.md` | on main; describes main until DB 07 deletes the hold, and it |
| `HANDOFF_COMPILER_DB_2026_10_01.md`, `MY_PLAN.md`, `codex-session-….md` (the stale `avra/` checkout) | read. The timing law and three owner rulings are in §1 and §7. `MY_PLAN.md` holds no DB decision |
| `BUILD_TIME_SOURCES.md` §1 | **not** replaced by a pointer until D6 is decided |

## A10. The sources design's questions D1–D13, re-answered

| D | answer | state |
|---|---|---|
| D1 one mechanism for a kept run? | yes: a saved answer. A native step's result (`Action`) is the sources campaign's | open for `Action` |
| D2 which mechanism is door 1? | one input declaration on the kernel (DB 01); `Memo.input` and `@input` merge | answered |
| D3 `KeyParts.runs` → typed parts | deleted with `KeyParts` at DB 07; until then only text reads un-hold a file | **open**: a listing read by a lift is not covered before DB 07 |
| D4 where a build's inputs are remembered | the manifest (§6.1) | answered |
| D5 a kept lift must be span-free | §6.3: spans are (anchor declaration, offset), also across files | **open** until DB 03 lands the codec |
| D6 hashing large inputs | a C row; SHA-256 for content, the fast digest for keys; M5 | answered |
| D7 raw bytes outside the tree | `~/.avra/cache/bytes`, verified on first use | answered |
| D8 the witness atom | (name, digest) where the name is an input or a saved answer; A4 lists the answers that replace each tier | **open** until M2 counts them |
| D9 the store's read slot | deleted; the record carries its reads (§6.1) | answered |
| D10 `.57.4.6` before answers are saved | a query's code is one of its reads (§5.3) | **open** until DB 06 |
| D11 the five rows outside P1–P5 | A2 | answered |
| D12 a per-process tool memo | tools are identified by a stamp re-read at each ask (D9); a digest memo lives one revision (§5.2) | **open**: D9 is the owner's |
| D13 who owns the two doors | the owner, with the sources session (§15a Q12); this document is the mechanism | answered |
