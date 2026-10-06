# The compiler DB — the one document

2026-10-06 · branch `db-design` · worktree `../avra-db-design` · epic `avra-8sb5.57` ·
code checked against `origin/main` @ `05fe643`
Start here, then [`2026_10_06_COMPILER_DB_HANDOFF.md`](2026_10_06_COMPILER_DB_HANDOFF.md).
Both documents land on main in one docs PR (team-lead opens it) and then live in `docs/`.
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
| 09-26 | "The compiler's DB is a real database, and every tool is a THIN QUERY over its rows." Generic · easy to integrate · very performant · extremely centralized · resumable | townhall :64-78 |
| 10-06 | "a saved answer is its value plus the list of inputs it read with their digests, recorded automatically by the kernel, valid only if every digest still matches — one rule, no hand-written checks." | brief |
| 10-06 | "EVERYTHING needs to be in the DB and queryable and maximally easy to work with as a consumer/plugin." "Pluggable. Performant. Simple seams." | brief |
| 10-06 | "Why wouldn't we always save? I feel like we should figure that out." | brief |
| 10-06 | "Yes!!!!!! This is what I have been asking for!!! I want to standardize on this as MUCH AS POSSIBLE." | brief |
| 10-06 | "It should be blazing fast." | brief |

### 1.2 Decided by the owner (2026-10-06)

| # | decision | what it means here |
|---|---|---|
| D1 | **Always save.** | Every query's answer is saved. No `@kept`, no hand-written cover, no grain flag. The compiler picks the grain from the key (L4). A plugin author decides nothing |
| D2 | **One engine first.** | `@query` and `@input` are kernel cells. The second memo is deleted. The 32 families move to the same spelling under a counter that only falls |
| D3 | **The Db is not an argument.** "Are we passing the db as an arg or not? If so, then not." | `@query fn icons_in(dir: string)`. Inside a query the Db is implicit |
| D4 | **A query never writes rows.** | You do not insert a derived fact; you return it (§3.0). A producer's keys must be listable (A11) |
| D5 | **`rule` is the one way to write a lint**, for third parties too. | no `@check @query` |
| D6 | **A plugin reads the outside only through what its manifest grants.** | every such read is a recorded input; the grant policy is the sources design's |
| D7 | **The speed bar**, `packages/cli`, cold process, no daemon. | unchanged `check` ≤ 60 ms · one body edit ≤ 300 ms (goal 150) · `build` after one edit ≤ 500 ms |
| D8 | **One store per compiler binary now**; answers keyed by their query's own code later. | the later step is ticket `.57.186` |
| D10 | **The re-ask of the sources is retired at DB 07, with no switch.** | Today a *failure* under a held answer is asked again of the sources. After DB 07 an answer stands on the digests of its reads; the edit corpus and the attack cases in CI are the net. No flag, no CI mode |
| D9 | **A tool is identified by path + size + modified-time**; full digest on demand. | for tools and the compiler binary only. Source files are always read |
| D11 | **The engine lives in `@std/relation`**, the library that already holds `@relation`/`@query`/`@input`. No new package. "ok fine do this" | the compiler and a running program share ONE engine (§5.1). It is a library, not `avrac-*`, because a running program imports it too |
| — | **No bisect.** | M3 is phase timings on main today (§7.2) |
| — | **A read list holds saved answers as well as inputs.** | a *verifying trace* |

### 1.3 PENDING OWNER

Nothing is open. D1–D11 are decided above (there is no D-numbered question left).

---

## 2. The laws

| # | law | one line |
|---|---|---|
| **L1** | **One input door.** | Anything outside the program is an *input*: a stable name and the digest of exactly what was read. Only `Host` reads the world. Absence is a value. |
| **L2** | **One engine.** | Every derived fact is a query: one kernel cell, one registration, one dependency list. `@query`, `@input`, a relation read and a compiler family are the same thing. |
| **L3** | **The saved-answer rule.** | A saved answer is its value plus the list of what it read, each with its digest, recorded by the kernel. It is valid only if every digest still matches. No other validity check exists. |
| **L4** | **Always save; the key picks the grain.** | A query keyed by a durable name is saved, with no mark. A query keyed by a local id lives in memory and belongs to the saved answer that owns the id; reading it from anywhere else is refused at the read. |
| **L5** | **Names are stable, ids are local.** | A name is a path plus a number *among same-named siblings of one owner*. A local id is (owner declaration, index). A saved value holds names, never dense ids or absolute offsets. |
| **L6** | **Every fact is a query answer.** | Small keyed facts with indexes are relations. Trees are blobs behind a query. A relation is filled by the driver (an input) or is the answer of one named query. A query never writes rows. HELD TODAY for a `@query` body (an un-owned insert there is refused) and for the owners that hand their rows over as a value (`ErrorSite`'s survey, `Raised`'s solve — `Rel.replaced`) or name the ids they keep (a file's declarations — `Rows.kept_of`); the compiler's `File` and `Module` rows are still inserted with no owner under open kernel queries — `avra-8sb5.57.206` gives them owners and widens the refusal. |
| **L7** | **One codec; the digest covers the whole value.** | The bytes saved are the bytes digested and the bytes that cross to a plugin. An answer with no bytes takes the digest of its input, or the fold of its parts' digests — never a narrower fingerprint. |
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

**Which keys are durable.** `FileId`, `DeclId`, `ModuleId`, the interned settle/ask/lift
ints and a row id are all *process-local numbers*. A key is durable when its type has a
**name** (§6.3) the codec can write; the dense number is that name, interned. After DB 03
every family key has one, so all 32 families are saved. What has no name: a node id
(`ExprId`, `StmtId` — never a key, only inside a value) and a row of a keyless relation.
So for the compiler L4's refusal is a rule about **keyless rows**; M2 counts them. A row
and an index bucket are *named parts of their producer's answer* (A11).

**M1 and M2 are in** (A21): 70,015 cells, 5.3 M direct edges; 54,947 of the cells are
saved answers with short lists (median 3 reads). Always-save is blocked by **names**, not
by size (§7.4). A read with no durable name makes its reader unsavable; it is never dropped.

---

## 2b. What gets simpler

"What will consumers write? Consumers will be the language compiler itself right?" —
**yes: each language feature first**, then the std packages, then third-party plugins. All
three write the same thing.

### The picture, in ten lines (PROPOSED spelling)

```avra
@input fn text(path: string) -> string?            // 1. an input: the outside, named and digested

@relation(from: declarations_of)                   // 2. a relation: rows are one query's answer
type Declaration = { @key file: string, @key name: string, @index kind: Kind, exported: bool }

@query                                             // 3. a query: pure; saved automatically
fn declarations_of(file: string) -> List<Declaration> {
    [Declaration { file: file, name: d.name, kind: d.kind, exported: d.exported } for d in parsed(file).items]
}

declarations_of("cli:src/main.av")                 // 4. ask
Declaration.by_kind(Kind.Trait)                    // 5. an index read: recorded; no walk
// $ avra explain 'declarations_of("cli:src/main.av")' --why        6. ask why
```

### What a language feature writes to own one fact

| today, by hand | on the DB |
|---|---|
| a `@family(rank, "Key", "Answer")` marker, a line in `tools/families.order` (its word is the variant's `.name`) | `@query fn …` |
| a side table keyed by typed ids, owned by the pass | the query's answer type |
| a string-keyed memo map on the `Workspace` (35 today) | nothing: the kernel memoizes |
| a key recipe, a `Store.keep` call, a validity format and its `*_stands` fn (nine formats) | nothing: the read list is recorded |
| a walk over every file or declaration to find its subjects | an index read |

**One family end to end: `Sig`, a declaration's signature.** Today (READ, line
counts by `awk` at `36eb0a1`), ~80 lines in four files:

```avra
@family(6, "DeclId", "DeclSig")                 // families.av:41 — key and answer are unchecked strings
type Sig = {}
.Sig -> touch(self.sig(decl_at_arg(arg))),      // workspace.av:941 a `touch` arm; its word is `Family.Sig.name`
fn sig(d: DeclId) -> DeclSig? {                 // workspace.av:1682-1709, 28 lines
    let k = key(Family.Sig, d.index)
    let x = self.decls.decl(d)
    if self.is_held(x.file) {                   // the held path: a second way to answer
        self.held_sig_dep(x.file)               //   :1719, 10 lines + held_sig :1738 + family HeldSig
        self.file_ensured(x.file)               //   :856, 12 lines
        self.fill_ensured(d)                    //   interface.av:307, 12 lines
        return self.decls.sigs.get()[d.index]   //   the side table decls.av:447
    }
    if !(self.db.ask(k) is .Compute) || x.kind is .Builtin { return self.decls.sigs.get()[d.index] }
    self.db.begin(k)
    …                                           // sign it; keep its diagnostics in a second side table
    self.db.settle(k, sig_hash(out))            // :2056, a hand fingerprint
    out
}                                               // + its lines in the module record, validated by hand
```

On the DB, in the feature that computes it (PROPOSED):

```avra
/// A declaration's own signature.
@query
fn sig(d: DeclName) -> Signed { signed(declaration(d)) }     // Signed = { sig: DeclSig, voices: List<Diag> }
```

Memo, the held path, the two side tables, the fingerprint and the record lines are the
saved-answer rule's job. ~80 lines → 3.

Two more, worked the same way in appendix A19: `embed` (PR #282's hand validity path, ~165
lines → one recorded read) and `avra docs` (~143 lines → ~6).

### The deletion ledger

MEASURED = `wc -l` or `grep` at `origin/main` @ `4294595`, non-test. "After" is ESTIMATED.

| what disappears | today | after |
|---|---|---|
| `compiler/kept_settle.av` — six line kinds, six `*_stands` fns | 324 lines | 0; four digest-only queries, ~40 |
| `compiler/db.av` — the compiler's own `Db`, `DbRow`/`DbKind` (24 kinds), `DocFacts`, `still_valid`; `answers.av` | 732 + 46 lines | 0 |
| `compiler/verify_held.av` — the held path's hand checks | 439 lines | 0 |
| `families.av` markers + `tools/families.py` + `families.order` | 149 + 154 + 32 | 0; 32 `@query` declarations |
| `compiler/record.av` — module record lines, `KeyParts`, `parts`/`seen` rows | 1,605 lines | ~300: the encoding is derived |
| `compiler/interface.av` — the hand-written interface wire | 869 lines | ~200 |
| `compiler/derive.av` — try the held path, fail, derive again (what PR #289 tamed) | 867 lines | ~400: one path |
| `compiler/workspace.av` — 37 fields, 35 string-keyed memo maps | 2,095 lines | ~800 |
| `compiler/store/store.av` + 7,981 `.deps` files nobody reads | 197 lines | one packed store, ~400 new |
| mentions of `KeyParts`/`stands_in`/`view_parts` · of the six key recipes · of held/unheld in `compiler/` | 41 · 22 · 135 lines | 0 |
| world reads outside any door | 172 sites | ~35, each licensed at its site |

Deleted whole, MEASURED: **1,908 lines** (the first four rows). Net of everything, ESTIMATED:
4–6 thousand lines gone against ~1,000 new (the store, the name codec, `explain`).

### What becomes possible, almost for free, once reads are recorded

| ask | which query it is |
|---|---|
| `avra explain X --why` | X's record, its previous record, the reverse index |
| `avra dev`'s watch set | the input manifest: every file any answer read (today a hand-built list that misses embeds, `.57.185`) |
| test selection | a test reruns only if a read of `Proved(test)` moved (today `tools/work test` selects by package) |
| find references, unused exports, go to definition, hover | `RefRow.to(name)` · `Declaration.by_name` · `Sig(declaration)` — one read each |
| `collect xs = @mark in scope …` | `Declaration.wearing(mark)`: an index read; adding a member reruns exactly the collects that asked |

### Collections: no bespoke walks

A relation read answers an ordinary list, so the standard verbs, comprehensions and `|>`
apply. PROBED today — `build/avra run /tmp/db-doc/t6` → `a 2 true`:

```avra
let names = Declaration.by_kind(db, "fn").filter(it.exported).map(it.name)     // index read, then verbs
let n = [d.name for d in Declaration.all(db) if d.exported].length             // a comprehension over rows
Declaration.by_kind(db, "fn").any(it.name == "b")
```

The standing rule (owner, 09-24): the store is a database — relations, indexes, typed
queries, no bespoke whole-program walks. What to write instead of each kind of walk: A19.

---

## 3. The consumer surface

### 3.0 "How do I insert?" — you return

You do not insert a derived fact. **You return it.** A relation's rows are the answer of its
one producer query. A row a re-run no longer returns is gone, by construction — there is
nothing to delete and nothing to sweep.

```avra
@relation(from: declarations_of)
type Declaration = { @key file: string, @key name: string, @index kind: Kind }

@query
fn declarations_of(file: string) -> List<Declaration> { … }     // "inserting a declaration" is being in this answer
```

| I want to … | I write |
|---|---|
| add a derived row | return it from the producer |
| remove one | stop returning it |
| change one | return the new value; readers of that row rerun, others stand |
| bring in data from outside (a file, an env var, an editor buffer) | an input: `text(path)`, or `set_text(path, buffer)` from the driver. Inputs are the only things anyone *sets* |
| push a finding from deep inside a query | return it; `rule` gathers findings per declaration |


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

### 3.2 What an author holds (PROPOSED spelling; D3 and D4 decided)

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
| the Db | first argument of every call | never an argument (D3); a program has one default Db |
| rows from a query | `Icon.insert(db, …)` as a side effect | the query *answers* rows; the relation names its producer (D4) |
| an index read on another column (`by_name`, `wearing`) | reads whatever happened to be inserted | the producer's keys are listable (D4), so the read brings every producer up to date, then reads one **bucket root** the store maintains by delta — never rebuilt from rows (A11) |
| saving | never | always (L4) |
| world reads | `@std.io`, unrecorded | the nine reads of §5.2; each is a recorded input |
| selecting declarations | `Decl.by_marks(db, "model")` — a string | `DeclRow.wearing(model)` — by the annotation's own declaration |

The exact spelling of `@relation(from: …)` is settled in DB 06. The laws are fixed.

Two plugins end to end (a build-time sources provider and a lint), what each existing
consumer becomes, and `avra explain`'s output: appendix A14.

---

## 4. The two tables that are the migration

### 4.1 The 32 families

READ `packages/std-avrac/src/compiler/families/families.av:17-149` (key, answer). "Encodes
today" is READ(agent). "Saved as" is PROPOSED and confirmed per family by M2 and M4.
Every key below is a local number whose name arrives at DB 03 (§2), so all 32 are saved.
Relation rows and buckets (A11) hold almost none of the 5.3 M edges today (M1: 2).

| # | family | key | answer | encodes today? blocked by | saved as |
|---|---|---|---|---|---|
| 0 | Source | file | `SourceFile` | yes | it is the input `Text(file)` |
| 1 | Parsed | file | `Parsed` (arena) | no: arena + Cells | digest only = `Text(file)`'s (readers see text and spans) |
| 2 | Items | file | `List<DeclId>` | dense ids | value (names) |
| 3 | Namespace | module | `ModuleNames` | `Map` + dense ids | value |
| 4 | Visible | file | `Namespace` | `Map` + dense ids | digest; value by M4 |
| 5 | Resolved | file | `NameFacts` | `ExprId` side tables | split per declaration; digest |
| 6 | Sig | declaration | `DeclSig` | `TypeId` | **value** — what importers load by name. M2: 13,240 answers, median 4 reads, p95 618 |
| 7 | Methods | declaration | `List<DeclId>` | dense ids | value |
| 8 | Typed | declaration | `TypeFacts` | `ExprId` tables, `TypeId` | digest + diagnostics; value by M4. M2: 13,626 answers, median 11, p95 583, max 2,564 |
| 9 | ConstTyped | settle int → const name | `TypeId` | `TypeId` | value |
| 10 | Folded | file | `TypeFacts` | as 8 | split per declaration; digest |
| 11 | Analysis | file | `Analysis` | no: closures | digest = fold of its parts'; dissolves at DB 07 f |
| 12 | Settled | settle int → const name · seat fingerprint | `Settlement` | yes | value (DB 09). M2: 501 cells, 0.81 M edges, a **root**: named at DB 03 a (§7.4) |
| 13 | Lowered | ask int → declaration · type args | `Unit` | `TypeId`, `FileId` | value. M2: 12,324 cells, 1.07 M edges, a **root**: named at DB 03 a (§7.4) |
| 14 | Lifted | lift int → annotation · declaration · args | `LiftResult` | yes; spans | value (DB 09) |
| 15 | Manifest | int → package name | `Manifest` | yes | value over `Text(avra.toml)` |
| 16 | Receivers | whole program | `bool?` | yes | split per impl (DB 07 c). M2: 1 answer, **41,435 reads** |
| 17 | Expanded | file | `List<DeclId>` | dense ids | value |
| 18 | Plain | file | `Parsed` | no (as 1) | digest only, as 1 |
| 19 | References | whole program | `List<Ref>` | every column `@local` | split: `Refs(declaration)` (DB 07 c). M2: 1 answer, **13,030 reads** |
| 20 | Failures | whole program | `Raised` | dense ids | one record per cycle group |
| 21 | HeldSig | module | `string` | yes | deleted at DB 07 (it is the hold) |
| 22 | Raised | declaration | `List<TypeId>` | `TypeId` | value |
| 23 | MethodDiags | file | `List<Diag>` | spans | value; split per (file, type it mentions) (DB 07 c). M2: 438 answers × exactly 994 reads |
| 24 | LiftLowered | lift int (as 14) | `Unit` | as 13 | value |
| 25 | Syntax | declaration | `int` | yes | digest (the answer is one) |
| 26 | Names | declaration | `int` | yes | digest |
| 27 | Marks | declaration | `List<Diag>` | spans | value |
| 28 | Admitted | file | `Unit` | as 13 | deleted at DB 07 (by-name loading) |
| 29 | Named | int → the name's text | `Unit` | as 13 | value; its key is a **name bucket**: 2.27 M of the 5.31 M edges read one (§7.4) |
| 30 | ReadReach | whole program | `int` | yes | one record per cycle group |
| 31 | DeclReads | declaration | `bool` | yes | value |

Count: 9 encode today · 3 never will (1, 11, 18) · 20 wait on DB 03. The four whole-program
families (16, 19, 20, 30) are the ones that make any edit O(program); each is split.

**4.2** Every second mechanism on main, each with the PR that removes it: appendix A16.

---

## 5. The engine and the plugin crossing

### 5.1 One kernel (DB 01)

- **One registration.** `@query`, `@input`, a relation's index bucket and a compiler family
  each register a kernel family by stable name (`@acme.icons.icons_in`). `@family` becomes a
  second spelling of that same call and is retired one family at a time (DB 12). A family is
  addressed by name, so its ordinal stops being a durable address (handoff, DB 01 e).
- **The engine lives in `@std/relation`** (D11): `query/kernel.av` (717 lines) and
  `marks.av` move beside the surface they serve. `std-avrac` depends on `@std/relation` as
  today and arms nothing: the nine-closure `Hooks`, `Memo<V>` and the write counter are
  deleted. `query/` in `std-avrac` keeps what is the compiler's own use of the engine
  (`memo.av`, `fixpoint.av`).
- **One engine, three users.** The compiler's Db is built on a kernel. A running program's
  `new_db()` owns one. A plugin's query runs in the evaluator, where the Db *is* the
  compiler's — an ask is a host row into the same kernel, never a second one in the
  evaluator's heap (§5.4).
- **This fixes what M1 found**: today the three std-relation families hold 2 edges between
  them, and declaration reads are recorded on `Named`/`Items`/`Methods` instead — two
  engines. After DB 01b a `@query` in the compiler is a kernel cell with its own edges.
- **A dependency is a packed int.** Today each edge is a boxed `Key`: 375 MB in 5,326,142
  boxes on a cold `check packages/cli` (MEASURED, ticket `.57.167`). Packed: ~9 B an edge
  (ESTIMATED) → ~48 MB.
- **A recorded read stays cheap**: ≤ 2 × an unrecorded one, held by `readbench` in CI
  (MEASURED today: list 4 ns, relation unrecorded 35–38, recorded 67–75). This bounds DB 12's
  migration; it is not why warm edits are slow today (§7.2).
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

Names are `package:relative/path`. Sources are always read and digested; only tools and
the compiler binary may answer from a stamp (D9, decided). A plugin reads only what its manifest
grants (D6). The rest — what is not an input, clock and cwd, a native tool in a child
process, package C — is appendix A18.

### 5.3 The saved-answer rule in the kernel (DB 06)

```
settle(q):                                      one append per read; no walk; nothing flattened
    q.reads = for each direct dep d of q:
        d is an input or a saved answer   →  (name(d), digest(d))
        d has no name, owned by q         →  d.reads            (already a short list)
        d has no name, owned by another   →  REFUSED at the read, naming q and d   (keyless rows)
    q is keyed by a durable name          →  append record(q) = digest · reads · value?
```

| question | answer |
|---|---|
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

Why not a file per record: one cold check writes 8,964 files today (M2); 1,300 opens cost 60–100 ms.

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
The 09-21 tree measured 0.046 s and 0.36–0.51 s at file grain on the same Sprite (§7.1).

### 6.3 Names (L5; DB 03)

A declaration's name is `file · owner path · name · sibling`, where `sibling` counts
same-(owner, name) declarations only — so inserting a declaration above moves nothing. A
local id is (owner declaration, index). A span is (anchor declaration, offset). A type is
its spelling, never the interned id. The full table, and why an ordinal is the honest cost:
appendix A17.

Processes, crashes, other compilers, gc: A12. The codec: A13.

---

## 7. Speed: what is measured, the targets, the gates

All of M1–M3 are measured (`origin/db-measure` @ `064cd27`, `tools/db_measure/RESULTS.md`).
M1 and M2 in full: A20, A21.

### 7.1 Two points, one Sprite, one harness (`check packages/cli`)

| | 09-21 `86d7009` | main `05fe643` |
|---|---|---|
| `.av` files in the tree · files the check holds | 680 · 289 | 1,513 · 458 |
| cold | 17.9 s | 62.8–65.1 s |
| unchanged | 0.046 s | 0.20 s |
| one body edit | 0.36–0.51 s | 4.7–7.2 s |

No commit is named (no bisect). COMPILER.md's 0.18 s was a Mac figure. Every round uses fresh edit text.

### 7.2 Where a one-edit check goes today, and what removes each part

One string literal edited in one body; wall 4.7–4.9 s (6.1–6.4 s when the file is in the cli).
`load` is 2.0 s in the split run and grows ~4 ms per held file whatever was edited — the O(program) phase.

| phase | ms | what it does today | what the edit needed | removed by → then (ESTIMATED) |
|---|---|---|---|---|
| **load: minting** | 890–920 | mints every declaration of all 453 held files, every run. Eager because a row minted inside a query arrives after its reader, and the relation refuses a late write | the declarations something reads | a row is part of its producer's answer, pulled by its first read — no write, so nothing is late (DB 07 a; needs DB 03 a's names and DB 01 b's "a read asks the producer") → ~0 |
| **load: keys** | 590–600 | re-keys and validates every hold; 460–470 of it builds each file's key parts | the files the edit reaches | the input manifest and reverse index (DB 05) → ~10 ms. Early: `.57.193` step 2 |
| **load: the rest** | 450–470 | registers every file (240–250), reads and decodes module records (120), opens the store (85–96) | one module | a file is a name, interned when asked (DB 03 a); records read in place (DB 05) → ~30 ms |
| **admit** | 1,075–2,100 | parses **13 files** for an edit in std-avrac, 25 for one in the cli (each parse fires twice, hence "23" and "50"). 1 is needed. Ten come from one defect: `admit_all` (`whole.av:132-143`) parses every unheld file of an admitted module, and a file nothing reaches never gets a record line. Twelve more for a cli edit: a compile-time run is keyed by the whole text of every file it read | 1 file | **DB 00a**, being built: 13 → 3 files, most of the 1.1 s. The twelve go when a run's reads are recorded per declaration (DB 07) → ~50 ms |
| **analyze** | 450–530 | re-types 308–316 declarations; rebuilds **all 994 method tables** on every edit (`.57.192`) | one declaration | per-declaration answers and the per-impl split (DB 07 b, c) → 30–80 ms. Earlier if `.57.192` finds one whole-table read |
| **lower** | 720–760 | 225–232 lowerings | the edited fn | `Lowered` named and saved (DB 03 a, DB 07) → 10–30 ms |

| what the phases do not show | evidence | answer |
|---|---|---|
| **a discarded attempt is paid in full** | std-avrac: every one-edit check discards a 3.9 s attempt to read one test program back (3,943 ms discarded + 5,807 standing of 10,382 — PR #306, which now prints it) | validation before derivation (DB 07). Now: the cause, as **DB 00d**, `.57.194` |
| **std-http's hold is refused for this edit** | held 0/121: its "one edit" is a 13 s cold check | a bug: `.57.190` |
| **the unchanged check's 0.20 s** | ~0.125 s fixed + 0.1 ms per file; the kernel does nothing; ~0.18 s is outside every phase timer | split it (M7, in DB 05). 09-21 measured 0.046 s on the same machine |

**Recorded relation reads did not cause this.** The review inferred they did; this
document repeated it. MEASURED: 3 recorded reads of `@std/relation` families on the
one-edit path; 1.38–1.55 M kernel reads, 93 % `HeldSig` (none in `load`: they happen in
analyze and lower); at 67–75 ns a read that bounds to
0.11 s of the edit. The read-cost budget is not a fix for today's slowness. It bounds DB
12: as 32 families become queries, a recorded read must stay cheap.

### 7.3 Targets, and when each becomes reachable

| scenario (`packages/cli`, cold process, no daemon) | gate | today |
|---|---|---|
| unchanged `check` | ≤ 60 ms (goal 40) | 200 ms |
| one body edit, `check` | ≤ 300 ms (goal 150) | 4.7–7.2 s |
| one body edit, `build` | ≤ 500 ms | unmeasured (only `check` was) |
| any partly-held state: time and peak | ≤ cold | 1.6 × cold |
| a recorded relation read | ≤ 2 × an unrecorded one, by `readbench` | 67–75 ns against 35–38 |
| reads per saved answer | p95 ≤ 600; none over 3,000 after DB 07 c | p95 510, max 41,435 |

| after | one body edit, `check` (ESTIMATED from §7.2's rows) |
|---|---|
| DB 00a (the admit defect); `.57.193` step 2 (re-key only moved parts) | ~3.8 s: admit 1.1 s → ~0.2 s for an edit outside the cli; step 2 takes a further 0.46 s for a leaf-file edit |
| DB 01 b + DB 03 a + lazy minting (DB 07 a pulled forward) | ~2.5 s: minting and file registration, 1.15 s, are gone |
| DB 05, DB 06 | ~2 s: the manifest replaces the key work and the record decode. The rule lands on pure lists only, so the hold still decides the rest |
| DB 07 d (saved syntax; nothing loaded until asked) | ~1.3 s: what is left is analyze and lower |
| DB 07 b, c and `Lowered` saved | **150–250 ms — the first point the 300 ms gate is reachable** |

**7.4** M2 exposes three gaps, each closed by a PR (A20): name buckets have no durable name
(DB 03 a, before DB 06) · `Lowered` and `Settled` are roots keyed by ask numbers (DB 03 a) ·
three long read lists (DB 05, DB 07 c). Always-save is blocked by names, not by size.

---

## 8. The PR list

Each lands alone and leaves main green. "Ladder" is what the seed and generation laws cost
(CLAUDE.md "How work lands"). Order matters: 00 → 01 → 02, 03, 04 → 05 → 06 → 07 → 08, 09 →
10 → 11. DB 12 runs throughout. M3 added DB 00 a–c; DB 01 c–d need not lead.

| PR | ticket | what lands | "when this lands, the owner can run …" | ladder | closes |
|---|---|---|---|---|---|
| **DB 00** secure, measure, fence | `.57.169` | the harness (`tools/db_measure/`, branch `db-measure`) landed; `keepers-green`: three keepers on every PR. Then three small PRs M3 asks for: **00a** why 22 unchanged files are parsed (`.57.191`); **00b** the load profile and, if it allows, the early fix (`.57.193`); **00c** `--time` prints a discarded attempt's cost (`.57.189`). Bugs filed: `.57.190` (std-http), `.57.192` (994 method tables) | `make keepers` green and required · `sh tools/db_measure/warm_edit.sh` · the table of why each unchanged file was read | none | `.57.165`; half of `.57.163` |
| **DB 01** one engine, as a–e | `.57.170` | §5.1: (a) the kernel moves into `@std/relation`; the layering rule restated and pinned by a keeper; (b) `@query`/`@input` are kernel cells on every Db, the second memo and the hooks deleted; (c) packed deps; (d) the read-cost census; (e) families register by name, refusals speak, `make families-left` starts at 32, `tools/families.py`'s order contract retired | a std-relation program test: three pure queries each run **once** after an unrelated write (nine times today) · the M1 graph shows the compiler's `@query` cells holding their own edges (2 today) · `Kernel.newly_read` < 60 MB (375) | `seed-check` must pass; build twice before trusting a peak | `.57.167` |
| **DB 02** `avra explain` | `.57.171` | A14.4 over the in-memory graph: `--stats` and "what did this read". `--why` re-derives in process, as `avra cache why` does today, until DB 05–06 give it the store | `build/avra explain --stats packages/cli` · `explain <file>` prints its reads | none | — |
| **DB 03** names, the id codec, as a–c | `.57.172` | §6.3, A13: (a) the name scheme and `Decl`'s key — waits on `file` leaving `@local` (`decl_rows.av:26`, owner: ERRORS); (b) the codec grows payload enums and recursive records; (c) one codec per family answer, ~20, each its own small PR | `make codecs` · a declaration inserted above changes no other declaration's bytes | none expected | — |
| **DB 04** the input door a–e | `.57.173` | §5.2 as five PRs: (a) the digest row; (b) `Source`, `Manifest`; (c) `embed`, listings; (d) env, tool, target, compiler; (e) the rest | `make inputs` prints the count outside the door and fails on a new one | (a) is **two landings** | `.57.184` |
| **DB 05** the store | `.57.174` | §6.1, A12; today's rows move in as opaque values, so no meaning changes; M4–M6 | one `store` file · `make cache-attacks` · the kill and two-process attacks | none | — |
| **DB 06** the saved-answer rule | `.57.175` | §5.3, on by default. First on formats that are already pure lists: the two docs queries and the links witness. The edit corpus | `build/avra docs LanguageFeature` twice: the second ≤ 0.05 s · `make db-corpus` · the 17 attack cases (A5), ported — they were written against deleted code | none | `.57.9.7`; absorbs `.57.101.12`, `.57.12.5` |
| **DB 07** per-declaration answers; the hold deleted, as a–f | `.57.176` | (a) rows and buckets become named parts of their producer's answer (A11) — "minted by one query, filed by another" ends; (b) `Resolved`, `Folded` split per declaration; (c) the four whole-program families split; (d) by-name loading replaces load/admit; (e) the hold, its record lines and the memo maps deleted; (f) `Analysis` dissolves | `warm_edit.sh`: unchanged ≤ 60 ms, one body edit ≤ 300 ms · the `.57.163` repro peaks ≤ cold | none for the seed; the riskiest — behind the edit corpus on a Sprite. The re-ask of the sources is deleted with the hold (D10: no switch) | `.57.163`; absorbs `.57.101.11` |
| **DB 08** roots | `.57.177` | `Verdict`, `Linked`, `Proved`; formats 4, 7–9 and the remembered rows deleted (A2); tools and env are inputs | `build` after one edit ≤ 500 ms · change `CC` → relink | none | links `avra-8sb5.68`, `.69`, `.31`, `.25.20` |
| **DB 09** `Settled` and `Lifted` | `.57.178` | `kept_settle.av` deleted (A4); `Lifted` saved with relative spans | a comment above 1,000 generated types: ≤ 0.06 s (0.25 s today) | none | — |
| **DB 10** the plugin crossing | `.57.179` | §5.4; `…Row` relations; `collect` membership; the lint arm of `rule`; manifest grants | the two-package probe prints `a_close \| b_open` (a trap today) | each host row is **two landings** | `.57.182`, `.57.183` |
| **DB 11** byte store, `Blob`, gc | `.57.180` | §6.1's byte store; `avra cache gc` | `build/avra cache gc` · two worktrees share one copy of a 5 MB input | none | links `avra-8sb5.37`, `.40.17` |
| **DB 12** families → `@query` | `.57.181` | not one PR: `make families-left` prints N of 32 and may only fall. At 0 `@family` and the compiler's `Db`/`DbRow`/`DbKind` are deleted | `make families-left` | a bridge only where the compiler checks its own source | `.57.12` on adoption |

**Live bugs stay open with their repros** until the PR above passes them: `.57.163`,
`.57.165`, `.57.9.7`, `avra-8sb5.46` and `.79` (weak hashes — no PR here touches the
in-process hash; linked, not absorbed), `avra-8sb5.68`, `.69`.

**9.** Every earlier decision this overturns, with its measurement: appendix A15. Hostile
cases, each answered: appendix A0.

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
| an env var read at compile time | the compiler's own: an `Env` input, unset ≠ empty. A plugin's: refused unless its manifest grants it |
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
| a store is one compiler's | "`.avra-cache/<print>/` … the newest four kept" | C:114 | A12, D8 |
| move the content, not the key | | C:191 | L3 |
| held by name is held by accident | | C:195 | L5 |
| a symbol outlives every id a run hands out | | C:197 | L5 |
| the binary's key covers the closure the last derivation admitted | | C:202 | `Linked`'s read list (DB 08) |
| a list that only grows is a hold that only shrinks | | C:211 | reads are per answer, per run |
| the gate never edits a file | "so it cannot see a hold wrong for an edit nobody tried" | C:229 | the edit corpus (§5.3) |
| a suite that never held attacked nothing | "22 green steps at `held 0/6`" | C:231 | every attack asserts a *count* of answers that stood |
| a cache can cost more than what it keeps | "A type-wire memo doubled `fill`; a stamp row per file lost to reading the file" | C:238 | value-or-digest is measured (M4) |
| a text record spends its separators; the empty name is a name | | C:244 | A13: length-prefixed |
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
| a missing dep is a mismatch | | TH:2349 | A12 |
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
refusal; seats present) become one law: such a run is not saved.

Open question for DB 09: validating `CallShape` means lowering the unit again. If that costs
more than it saves, the `u` line reads `Syntax(declaration)` in both cases and `CallShape`
is not built.

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
`("a","b.c")` (TH:2319) · the 62-build `make cache-attacks` (C:154).
`tools/hold_sweep.sh` (it touches every source, one at a time) becomes the edit corpus.

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
| the build-time sources design | `origin/sources-design` @ `06594b4` | the consumer brief |
| hand `ReachWitness` (70/70 held, ~3 % win: 3.90 → 3.78 s) | `avra-warm101-11` — **deleted with its worktree**, never committed | only its finding survives (§9 row 2) |
| typed `it.mark.args[i]` in `collect`; a doc-fact witness test | `origin/q148-prototype`, `origin/docfact-side` | 0 commits ahead of main; mostly on main as `collects/order.av` |

## A8. Measurements, with their sources

| what | value | source | kind |
|---|---|---|---|
| flattened witness, cold `check std-avrac` | 74,600 edges/file median; 33.3 M edges; pack 279 MB; +62 % / +38 % / +116 % / +216 % | TH:2404-2413 | MEASURED |
| direct deps of the same 770 files | 13,578 (17.6/file, median 9) | `3806c7d` | MEASURED |
| "kernel grain": ≥2.54 M keys, ≥51.6 M deps | "still climbing when stopped"; no commit, no harness. Not an edge count: M1 measured 5,314,590 edges and 37.2 M read calls | TH:2427-2434 | UNREPRODUCIBLE |
| the kernel graph, cold `check cli` | 70,015 cells · 5,314,590 direct edges · 37.2 M recorded read calls · 45.7 MB as text | M1, `AVRA_DB_GRAPH=1`, branch `db-measure` | MEASURED |
| `Kernel.newly_read`, cold `check cli` | 375 MB in 5,326,142 live boxes, ~70 B an edge | ticket `.57.167` | MEASURED |
| same, earlier run | 363 MB in 5.1 M boxes | `avra-8sb5.76` | MEASURED |
| per-declaration fact columns | 154 MB (`side_table<bool>`, 142,264 tables) + 258 MB (`side_grow<DeclAt>`) | ticket `.57.168` | MEASURED |
| kernel read | ~120 unrecorded · ~315 stamped repeat · ~1,900 new dep | TH:2753 | MEASURED |
| relation recorded read | ~938 instructions against ~90 raw | ticket `.57.8.1` (PERF's `kbench`, outside the repo) | MEASURED; not re-measured (no instruction counter on a Sprite) |
| the same, by `readbench` (ns per read, native) | list 4 · relation unrecorded 35–38 · recorded 67–75 | M3, `origin/db-measure` @ `064cd27` | MEASURED |
| one-edit `check cli` by phase | start 16–20 · load 1,820–1,900 · admit 1,075–1,200 (2.1 s for a cli file) · analyze 450–530 · lower 720–760 · keep 175–190 ms; wall 4.68–4.85 s (6.1–6.4 s) | M3 | MEASURED |
| the same edit by package size (files held → load) | 4 → 6 ms · 14 → 120 ms · 458 → 1.85 s · 867 → 3.2–3.4 s | M3 | MEASURED |
| kernel recorded reads on the one-edit path | 1,383,865–1,553,242; `HeldSig` 1.33–1.44 M for 75 module cells — **0 of them inside `load`**; `@std/relation` families: 3 | M3; Follow-up 3 | MEASURED |
| `load`, split (2.00–2.03 s, three rounds within 3 %) | minting every held declaration 890–920 (45 %) · re-keying and validating holds 590–600 (29 %; key parts 460–470) · registering each file 240–250 (12 %) · records read and decoded 120 (6 %) · store opened 85–96 (4 %) | `origin/db-measure` @ `5b5290d`, `raw/load_split.txt`, `AVRA_LOAD_SPLIT=1` | MEASURED |
| why unchanged files are parsed | `Q parse` fires twice a file: 13 files for a std-avrac edit (the edit, the entry and its provider, ten from `admit_all`), 25 for a cli edit (twelve more by compile-time run keys) | same, `raw/parsed_why.txt` | MEASURED |
| a discarded attempt, std-avrac one edit | 3,943 ms discarded + 5,807 ms standing of 10,382 ms | PR #306 | MEASURED |
| a discarded attempt | std-avrac one edit 8.4–8.7 s wall, phases 4.5 s; first edit after cold 31.7 s, two discarded | M3 | MEASURED |
| not measured | instructions per read · where the unchanged check's 0.18 s goes · which commits cost what · `build` | M3 | — |
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
| warm one-line edit, before/after pairs on different days | 20.9 → 2.3 s (`e203c0d`, #48) · 8.06 → 5.93 s (`e61260b`, #119) · 6.30 → 4.27 s (`b8311ee`, #124); phases on 10-01: ast, sublang, load, admit ~1.0–1.4 s each | commit bodies; inventory G2 | MEASURED |
| the witness as landed 09-28 | cold 27–38 s against 6.3–10 s; edited 95–150 s; OOM at 4.4 GB → shipped off | `e4d4420` | MEASURED |
| saved answers under L4, cold `check cli` (simulated) | 54,947 of 70,015 cells; reads 1,091,224 (median 2, p95 19, max 32,114) strictly; 3,359,012 (median 3, p95 510, max 41,435) with name buckets durable | M2, `graph.py`, `origin/db-measure` @ `6b12cf8` | MEASURED |
| the same at file grain (what main saves) | 4,184 answers; 2.67 M reads; median 5, p95 5,090 | M2 | MEASURED |
| digest (`core/digest.av`, native) | 362 MB/s; 0.63 µs at 72 B, 1.35 µs at 288 B, 8.3 µs at 2.3 KB | M2, `digest_bench.sh` | MEASURED |
| today's store after a cold `check cli` | 8,964 files, 58 MB (unit 5,010 / 30.8 MB · rows 1,172 / 26.7 MB · warn 2,752 / 0.13 MB) | M2 | MEASURED |
| `perf/witness-folded` reproduced in kind, std-avrac today | `Analysis`: 867 files, 37,258 direct deps, 43 a file, median 23 | M2 | MEASURED |
| packed dep ≈ 9 B · cold encoding cost | — | review E2 | ESTIMATED; encoding unmeasured |
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
| `BUILD_TIME_SOURCES.md` §1 | D6 is decided (grants). Its §1 becomes a pointer here when the sources session and the owner agree the grant rules |

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
| D12 a per-process tool memo | tools are identified by a stamp re-read at each ask (D9, decided); a digest memo lives one revision (§5.2) | answered |
| D13 who owns the two doors | the owner, with the sources session (§15a Q12); this document is the mechanism | answered |

## A11. Rows, buckets and index reads under L4 and L6

**Today** (READ `features/decls.av:704-706`): "no query OWNS a row here: a declaration is
minted by one query and its facts filed by another, and nothing sweeps it". Row and bucket
cells are keyed by a dense row id. They hold almost no kernel edges today (M1: the three
std-relation families hold 2): row reads are recorded on the reading family's own cells. 259 non-test
call sites read `.decl(…)` (PROBED by grep at `05fe643`).

| thing | what it is on this DB | PR |
|---|---|---|
| a `Decl` row | a **named part of its producer's answer**: `Items(file)` for a written declaration, `Lifted(…)` for a generated one. The producer's record carries one digest per row | DB 07 a |
| a row's filed facts (signature, marks, doc) | the answers of `Sig(declaration)`, `Marks(declaration)`, `Doc(declaration)` — no longer columns written into the row by a second query | DB 07 a |
| a row read | records (row name, row digest). The producer reruns, the row's digest is unchanged, the reader stands | DB 07 a |
| the 259 `.decl(` sites | keep their spelling. The change is under `Decls`: the read records the row part instead of a name bucket | DB 07 a |
| a bucket of one producer (`Icon` rows of `icons_in("a")` with `name = "close"`) | a named part too: its digest is the sum of its rows' finalised hashes | DB 06 |
| a row of a keyless relation (`Finding`, `Ref` today) | has no name: readable only under its producer; from elsewhere it is refused. Each gets a key or stays private | DB 07 c |
| an `@local` column (`stmt: StmtId`) | never saved; reading the node it points at is a read of that file's `Parsed`, or better of `Syntax(declaration)` | DB 03 a |

**An index read on a column that is not the producer's key** (`Icon.by_name("close")`,
`DeclRow.wearing(model)`):

| question | rule |
|---|---|
| over which producers? | a derived relation's producer either takes no key (the relation is one answer) or names a query that lists its keys: `@query(over: icon_dirs)`. "Those asked so far" is never the answer — it would depend on who asked first. For `Decl` the list is the package's files |
| what does the read do? | reads the key list (a recorded read), brings every listed producer up to date (when warm, only suspect ones do any work), then reads the **bucket root** `(relation, index, value)` |
| how is the root kept? | by the store, by delta. When a producer's answer is replaced, its old and new bucket parts are subtracted and added to the roots of exactly the values they touch. Cost: the rows that changed. Never a rebuild over all rows — that would be the O(program) step L8 forbids |
| who becomes suspect? | readers of the roots whose digest moved. Not readers of other buckets |
| a phantom or negative read | a read of an empty bucket records its root with digest 0. A row appearing later moves that root, so the reader is suspect |
| two producer calls answer the same `@key` | refused, naming both producer keys |
| early cutoff | at the producer (same answer → no delta) and at the root (a delta that sums to the same digest) |

This is decided before DB 06, where `@relation(from: …)` first exists. It is the reason D4
is one question: "a query never writes rows" only works if producers can be listed.

## A12. The store under processes, crashes and other compilers (DB 05)

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

## A13. The codec (L7; DB 03)

One codec, derived from the type: length-prefixed strings (NUL is data), count-prefixed
lists, one presence byte per `?` layer, an enum by its variant's **name**, every sequence
folded to one value. It must grow payload enums and recursive records (refused today:
READ(agent) `relation.av:296-306`), or `Lifted`'s generated code cannot be saved. A `fn`,
`Cell` or `Map` field is refused at the declaration, naming the field: that answer is
digest-only.

## A14. Two plugins, the existing consumers, inspection

### A14.1 Plugin A — a build-time sources provider (PROPOSED; lands at DB 10)

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

### A14.2 Plugin B — a lint (PROPOSED; D5 decided; lands at DB 10)

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

### A14.3 What each existing consumer is on this DB

| consumer | today | on this DB | PR |
|---|---|---|---|
| `collect` | gathers by a raw bucket read that records nothing (READ(agent) `features/decls.av:1336-1340`). PROBED `build/avra run /tmp/db-doc/t3` → `2 A,B` | **membership** ("which declarations wear this mark, in this scope") is a saved query, so adding a member reruns exactly the collects that asked. The **projection** stays lowering: its value is data in the output program and may hold fn values. Order: every expansion that can mint a member of a scope finishes before that scope's membership is answered; one that reads a membership its own output joins is refused, naming both | DB 10 |
| idiom `rule` engine | a tree walk per file; findings to a throwaway Db | the walk stays (the AST is an arena, not rows — townhall P4 ruling). The saved answer is `Findings(declaration)` | DB 07 |
| `avra docs` | two `@query` full scans plus the hand witness `DocFacts`/`still_valid` | two saved queries keyed by name; a doc fact is the value of `Doc(declaration)`. The hand witness is deleted | DB 06 |
| references | `Ref` rebuilt whole; every identifying column is `@local` | `Refs(declaration)`: the sites inside one declaration, each (target name, local index). "Who refers to X" is a two-level index read | DB 07 |
| `avra explain --why` | absent. `avra cache why` re-derives the program in process | reads the store: the answer's record, the previous record (still in the append-only file), and the reverse index | DB 02, DB 05 |
| `embed` | three hand sites (#282) | `text(path)`: an input like any other | DB 04 |
| an editor | none | an input has a `set`; an unsaved buffer is `set_text(path, buffer)` | DB 01 |

### A14.4 Inspection (PROPOSED; DB 02)

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

## A15. Decisions this document reverses

"A decision is reopened only with a measurement" (townhall :2065).

| earlier decision | now | the measurement or the word |
|---|---|---|
| first draft: opt-in `@kept` | always save (D1) | the owner, 10-06. And the cost it feared was flattening: 13,578 direct deps against 33,286,285 flattened (`3806c7d`) |
| first draft: hand-written `cover` per family | none; ownership follows the key | `.57.101.11`: an interface-only digest is not a superset of what importers read. A cover that lies cannot be seen by a double run |
| first draft: `Icon.insert` inside a query | a query answers rows (D4, decided 10-06) | PROBED `c1`, `c4`: empty and stale reads; the sketch's own key traps |
| first draft: families convert last, in one PR | a counter from DB 01 (D2) | the owner, 10-06 |
| first draft: gate one edit at 2.0 s | 300 ms (D7) | this tree measured 0.18 s on 09-21 |
| first draft: one file per record | one packed file | 1,300 opens = 60–100 ms. This restores townhall §6.6 |
| first draft: "everything is a relation", `Expr.by_shape` | every fact is a query answer; the AST stays an arena | townhall P4 ruling (:2761); a first read is ~15× |
| townhall §6.5a: the durable witness is `KeyParts`; kernel-grain deps stay in process | `KeyParts` is deleted at DB 07 | M1, MEASURED: 5,314,590 direct edges in 70,015 cells; 45.7 MB as text. "≥51.6 M" was not an edge count |
| `.57.148`: keep `@family(rank, key, answer)` | families become `@query` | the owner overruled it, 10-06. `.148` stays closed |
| COMPILER.md law 6: "The sources are the hold's oracle. A hold bug costs time, never a wrong answer" | retired at DB 07, with no switch (D10) | the owner, 10-06: "no switch". The hold that re-asks the sources is deleted; the edit corpus and the attack cases in CI are the net. What it can miss: a stale saved answer shown as a false error between a bug landing and the corpus catching it |
| sources §15a Q12: the two doors are designed with the owner | unchanged. This document supplies the mechanism; the grant policy is D6 | the first draft claimed the doors silently |
| COMPILER.md: no resident compiler | stands | the targets need no daemon (§6.2) |

Restored without change after the first draft dropped them silently: "durable by default,
with nothing to tune" (townhall :2277) · a bound on what a recorded read costs (:2106) · a
decoded row is a different type (§4.10) · core never reads a plugin relation (:2656).
| second draft: the kernel moves to a new package `@std/query` | no new package: it lives in `@std/relation` (D11) | the owner, 10-06: "I don't want @std/query", then, shown that a running program cannot link the compiler: "ok fine do this" |
| second draft: an eight-commit bisect for M3 | phase timings on main today | the owner, 10-06: "it's too expensive" |

## A16. Every second mechanism on main, and the PR that removes it

| on main | size | removed by |
|---|---|---|
| std-relation `Memo<V>` and the Db write counter — a second memo engine | `db.av:475-580` | DB 01 |
| `Hooks`: nine erased closures; `opened`/`settled`/`running` unarmed | `db.av:50-62`, `workspace.av:581`, `decls.av:702` | DB 01 |
| `@input` (records nothing) vs `Memo.input` (records; 3 callers) | `input.av`, `query/memo.av:128-141` | DB 01 |
| world reads outside any door | 172 sites; ~50 behind `Host`; ~35 are not inputs | DB 04 a–e |
| `admit_embeds` (callee matched by the string `"embed"`) | `whole.av:171` | DB 04 c |
| `@family(rank, "Key", "Answer")` (unchecked strings) | `families.av` | DB 12, a counter |
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

## A17. Names (L5; DB 03)

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

## A18. The input door's rules (DB 04)

| rule | detail |
|---|---|
| names | `package:relative/path`, as written. Never absolute, never a `FileId`. A symlinked package is one file under two names: name it as written, digest the bytes |
| sources are always read and digested | no stamp shortcut (`92b24db`: 36–42 ms at 730 files, MEASURED) |
| the compiler and tools | identified by path + size + mtime (D9) — the one place a stamp answers |
| a per-process memo | holds the digest of bytes read *this revision*; dropped when the revision moves (`avra dev`, in-process edit suites) |
| not inputs | the store's own IO, a program's effects under the evaluator, phase timing, debug flags — ~35 sites, each `// LICENSED` at the site so the keeper's baseline can reach zero |
| clock, pid, argv, cwd | refused inside a query. `AVRA_CWD` is read by the driver and enters as an argument |
| a plugin | reaches the reads through host rows, only for what its manifest grants (D6, decided). The grant rules are the sources design's |
| a native tool in a child process | "the tool opens nothing": a read is a message the compiler checks, answers and records (sources design :649). This document supplies the input mechanism; the protocol is the sources campaign's |
| package C run at const settlement | refused unless the row declares its inputs. Open; recorded under DB 04 e |

## A19. Two more features, before and after

**`embed`** (MEASURED: `git show --stat 04a6a89`, PR #282). Making "edit an
embedded file → the binary rebuilds" true took a hand validity path in four files:
`kept_settle.av` +5 (an `e` line kind), `build.av` +44 (`embed_line`, `embeds_key`,
`keep_embeds`: key lines and a remembered row), `whole.av` +95 (`admit_embeds`: a walk over
every expression, matching the callee by the string `"embed"`), `host.av` +23. On the DB the
feature keeps its law (the path is beside the file, inside the package) and writes one read:

```avra
fn embedded(from: string, path: string) -> string { text(beside(from, path)) ?? refused(path) }
```

Whatever used the read reruns. Those ~165 lines are never written (ESTIMATED).

**`avra docs`** (READ `compiler/doc_rows.av`, 38 lines; `compiler/db.av:84-153` and
`:660-695`, ~105 lines). Today: two full scans that answer a `DocKey` and then re-find the
row ("a dense id never crosses a query's answer"), plus `FileWitness`, `DocFacts`, two hand
codecs, `still_valid`, `current_listing_digest`, `current_file_digest`. On the DB:

```avra
@query export fn named(name: string) -> List<Declaration> { Declaration.by_name(name) }
@query export fn exported(package: string) -> List<Declaration> { Declaration.by_package(package).filter(it.exported) }
```

~143 lines → ~6 (ESTIMATED after). The witness is the read list; the row is the answer.

**Collections — what a consumer writes instead of a walk**

| a consumer wants | it writes | never |
|---|---|---|
| a filter, a projection, a count | `.filter(…)`, `.map(…)`, `.length`, a comprehension, `\|>` | a second relation holding the filtered copy |
| one column value; a grouping | `R.by_<index>(v)`; each group is a bucket | a loop with an `if` over `R.all()`; a `Map` built by hand |
| a whole-program fact | a query over index reads, or a fixpoint group (§5.1) | a pass that walks every file |
| every declaration wearing a mark | `collect`, or `Declaration.wearing(mark)` | `Decls.gathered` over a raw bucket |

## A20. M2 in detail (a simulation; nothing was persisted)

Source: `tools/db_measure/graph.py` replaying the M1 graph of a cold `check packages/cli`,
`origin/db-measure` @ `6b12cf8`. "Second reading" = name buckets counted as durable inputs.

| family (second reading) | saved answers | reads per answer |
|---|---|---|
| `Sig` | 13,240 | median 4, p95 618 |
| `Typed` | 13,626 | median 11, p95 583, max 2,564 |
| `MethodDiags` | 438 | exactly 994 each |
| `Analysis` | 458 | median 29 |
| `Receivers` | 1 | 41,435 |
| `References` | 1 | 13,030 |
| all | 54,947 | total 3,359,012 · median 3 · p95 510 · max 41,435 |

| what it shows | consequence |
|---|---|
| strict reading loses 2.27 M reads (3.36 M − 1.09 M) | those are name-bucket reads; a dependency that is not recorded is a stale answer. Hence the law in §7.4 row 1 |
| 15,068 cells are keyed by an ask number; 705 sit under a saved answer; `Lowered` and `Settled` are roots | DB 03 a names every interned-int key. After it, no family cell is in memory only |
| declaration grain: median 3, p95 510. File grain: median 5, p95 5,090 | finer grain gives *shorter* lists, the opposite of what the 09-28 flattening suggested |
| `MethodDiags` reads 994 of something in every one of 438 files | it asks every type's methods; it should ask only for the types the file mentions |
| digest cost is under 1 % of a cold check | the cold-cost budget is about encoding, which nobody has measured (M4) |
| the store today is 8,964 files for one check | one packed file (§6.1) |

**The three gaps, in full**

| gap | answer | PR |
|---|---|---|
| **2.27 M of 5.31 M edges read a `Named` name bucket**, which today is neither a saved answer nor an input. Under the strict rule that dependency is *lost* | a name bucket is the by-name index root of A11, named by the name's own text. And a law: **a read with no durable name makes its reader unsavable — it is never dropped.** `explain --stats` prints "reads with no name"; it must be 0 for a family before that family is saved | DB 03 a, before DB 06 |
| **`Lowered` (12,324 cells, 1.07 M edges) and `Settled` (501, 0.81 M) are keyed by ask numbers and read by no saved answer.** They are roots: only 705 of 15,068 in-memory cells sit under an owner, so "belongs to the saved answer that owns it" has nothing to say | they get names, not a "re-derived" status: `Lowered(declaration · type arguments)`, `Settled(const · seat fingerprint)` — the key and the artifact's name from one derivation (CLAUDE.md, `settled_symbol`) | DB 03 a |
| **three long lists**: `Receivers` 41,435 reads, `References` 13,030, `MethodDiags` 994 in every file | unchanged run: no list is walked — an answer that no changed input reaches through the reverse index is never touched (§6.2). After an edit: each is split so one edit dirties a short list — per impl, per declaration, per (file, type it mentions) | DB 05 (reverse index); DB 07 c (the splits) |


## A21. M1 and M2 as measured

| # | question | result | what it changes |
|---|---|---|---|
| M1 | How big is the kernel's graph on a cold `check cli`? | **MEASURED** (`AVRA_DB_GRAPH=1`, branch `db-measure`, `tools/db_measure/graph.py`): **70,015 cells, 5,314,590 direct edges**. 37.2 M recorded read *calls* — 7 per kept edge; 17.8 M on `Named`, 14.5 M on `Items`. In memory 74 B an edge (375 MB) and ~1,050 B a cell (70 MB) of a 1,867 MB peak; as plain text the graph is 45.7 MB. 54,947 cells are keyed by file, module, declaration or unit; 15,068 by a process-local ask number. The three std-relation families hold 2 edges between them | save every cell's digest and reads (≈ 46 MB before packing). The 15,068 ask-number cells need names at DB 03. The cost to cut is the 37 M calls, on `Named` and `Items` — DB 01 c–d |
| M2 | Under L4: how many saved answers, how many reads each? | **MEASURED** (a simulation over the M1 graph, `graph.py`; nothing persisted): **54,947 of 70,015 cells are saved answers.** Direct durable reads per answer: total 1,091,224, median 2, p95 19 as keys are typed today; total 3,359,012, median 3, p95 510, max 41,435 once name buckets count as durable. File grain (what main saves today): 4,184 answers, 2.67 M reads, median 5, p95 5,090. Digest 362 MB/s: 55 k answers ≈ 0.05–0.5 s, under 1 % of a 63 s cold check | **Always-save at declaration grain is ~55 k records with short lists. It is blocked by names, not by size** (§7.4) |
