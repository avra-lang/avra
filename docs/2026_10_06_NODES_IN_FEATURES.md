# Nodes in their feature file — the cut

Checked against `origin/main` @ `faf1afc`. Paths under `packages/std-avrac/src/`. `READ` = file:line opened. `ESTIMATE` = a guess. Nothing was run.

**Short answer:** yes, it is an enum collect, and most of the machinery exists. Three things are missing: payloads, a derive that can see gathered variants, and an ordinal that stops mattering.

---

## 1. What `collect enum` does today

```avra
@family(6, "DeclId", "DeclSig")
type Sig = {}
…
export collect enum Family = @family in self by it.mark.args[0] dense     // compiler/families/families.av:149
```

| question | answer | READ |
|---|---|---|
| What is a member? | any declaration wearing the mark; the variant is named by the declaration's own name | `compiler/typing/declare.av:149` |
| Can a variant carry a payload? | **No.** Every variant gets an empty payload list | `declare.av:147-150` |
| What decides the ordinal? | position after sorting by the `by` keys | `compiler/lower/lower.av:1174-1184` |
| What is `by`? | one or more `it.…` paths; here the mark's first argument, compared as an int | `features/collects/order.av:44-52` |
| What is `dense`? | exactly one key, every value an int, sorted values are 0..N with no gap or repeat — else refused | `features/collects/check.av:218-237` |
| When does the enum exist? | **at signature time**, not lowering. It is an ordinary `DeclSig.Enum` | `declare.av:138-153`, `:1255` |
| Scope | `self` = the file · `package` = the owner's package, private names included · `closure` = that plus other packages' exports | `features/decls.av:1586-1593` |
| Is the package complete when asked? | yes — the first gather admits every file of the package | `features/decls.av:1555-1560` |

So the worry "a collect is synthesised at lowering, too late for the parser" applies to `collect` *values* (`rules`). A `collect enum` is a real type before any body is typed. `Family` is matched exhaustively all over the driver today (`compiler/dep_audit.av:92`).

**Layering.** `core/`, `features/` and `compiler/` are modules of one package. The layering keeper reads `use` lines (`tools/layers.py:1-6`). A collect gathers by declaration rows, not by import. So this is legal today:

```avra
// core/nodes.av — core names no feature; the package scope reaches them
export collect enum Stmt = @node_stmt in package by it.mark.args[0] dense
```

The enum lives in `core/nodes.av`. `SyntaxArena` holds it as it does now.

---

## 2. What must be added

### 2.1 Payloads from a record's fields

```avra
@node_stmt(21)
type Defer = { body: ExprId, on_error: bool }       // → Stmt.Defer(body: ExprId, on_error: bool)
```

`declare_collect_enum` reads each member's record signature and uses its field types, in field order, as the payload. About ten lines beside the written-enum twin (`declare.av:118-129`). Construction and patterns stay positional, so **no consumer changes**: `Stmt.Defer(b, e)` and `.Defer(_, on_error)` read as before.

Variant marks ride the record; payload marks ride the field:

```avra
@node_stmt(3) @declares
type FnDecl = { name: Scoped, … }                   // today: `@declares FnDecl(…)`, core/nodes.av:899
```

### 2.2 The ordinal

Position is read in three places: the runtime tag (`declare.av:116`), `@derive(Identity)` (`core/identity_derive.av:2`), and `@derive(Matchable)`'s `shallow_*`/`tag_*` (`core/shape_derive.av:75`, header). Only the last two cross generations: a rule's pattern is folded by the compiler that *builds* the product and compared by the product.

| option | what it does | verdict |
|---|---|---|
| explicit number + `dense` | `@node_stmt(21)`; the compiler refuses a gap or a repeat | **fences.** Exists today. A feature *reorder* cannot move it; a hand edit of a number still can |
| append-only ledger file | a script holds the order, as `tools/families.order` does | fences, outside the compiler; a second copy |
| name-keyed fold | the two derives fold the variant's **name**, not its index | **removes.** Position stops being read across generations |

**Recommend: number + `dense` first, name-keyed fold second.** Give every node its *current* position as its number. Then the migration changes no ordinal at all, so no baked shape moves and no generation ladder is owed for it. Afterwards change one expression in each of the two derives:

```avra
// core/shape_derive.av, core/identity_derive.av — `at` is the variant's index in `t.variants`
fp(${tag}, [${at}, …])            // today
fp(${tag}, [fp_str("${v.name}"), …])   // after: a rename moves it, a reorder cannot
```

That change is itself a moved fold: it lands as its own PR with a seed refresh. After it, the number is only the runtime tag and `dense` is only a tidy-ness check.

### 2.3 The seven derives over a gathered enum

Today a derive receives the annotated statement's own variants, from the parse tree (`features/crossing.av:442`; CLAUDE.md: a declaring annotation "reaches only what the parse tree holds"). A `collect enum` statement has no written variants.

Needed: for a `collect enum`, the type handed to a derive is built from the **members' parse trees** — name, fields, marks — in ordinal order. All three are parse facts; marks are already indexed at admission (`features/decl_rows.av:56`). No signature and no typing is needed, which keeps the "derive's file is typed while the annotated file is registering" law intact: the derive files still stand alone, and nothing new is typed early.

### 2.4 Exhaustive matches in `core/`

Unchanged. `core/parts.av`, `core/store.av`, `core/control.av` name variants of an enum in their own file's module; where the member record is written does not matter to a match.

---

## 3. The bootstrap

Three landings. None needs the four-generation ladder if ordinals are kept.

| landing | what | bridge |
|---|---|---|
| A | the compiler learns payload-carrying `collect enum` and derives over one. Its own source does not use it. Proved by program tests | none; refresh the seed on landing |
| B | `Pat` becomes gathered, members still in `core/nodes.av` | main's seed (from A) builds it |
| C… | `Stmt`, then `Expr`; then records move out to feature files | each is source-only |

The hazard is the usual one: after A merges, the first build in any worktree is `make bootstrap`, and save `build/avra` aside before B.

---

## 4. First PR, then the order

An enum is gathered whole or not at all — there is no "one gathered variant in a written enum". So "prove it on one node" is two moves: make the enum gathered **in place**, then move one record.

**PR 1 (landing A).** Payloads + derive support, with a toy in a program test:

```avra
@shape(0) type Dot = {}
@shape(1) type Line = { from: int, to: int }
collect enum Shape = @shape in self by it.mark.args[0] dense
match Shape.Line(1, 4) { .Dot -> 0, .Line(a, b) -> b - a }      // expects 3, both engines
```

**PR 2.** `Pat` gathered in place — 7 variants, 4 derives (READ `core/nodes.av:763-767`). Smallest real enum.

**PR 3.** `Stmt` gathered in place (31 variants, 6 derives). Scripted: each variant line becomes a numbered record directly above where the enum stood.

**PR 4 — the one node.** Move `Defer` to its feature. Two payloads, one feature, no desugar in other features (READ `core/nodes.av:971`, `features/defers/`).

```avra
// features/defers/mod.av
/// `defer e` — the body runs when the enclosing scope ends …
@node_stmt(21)
export type Defer = { body: ExprId, on_error: bool }
```

Nothing else changes in that PR. If it builds and `make gate` is green, the mechanism is proved.

**Then:** the other statements, one feature per PR or batched (a pure move — scriptable from a variant→feature table read off `features/dispatch.av`). Then `Expr` gathered in place (41 variants, 7 derives), then its moves. Shared variants (`Error`, `Setting`, the spine's) stay in `core/` — a node no single feature owns is honest there.

---

## 5. What gets deleted

| gone | size (READ) | when |
|---|---|---|
| the three variant lists in `core/nodes.av` | ~80 variants | as each enum is gathered |
| `tools/families.order`-style ledgers for nodes | never created | — |
| `features/node_scaffold.av` | 37 lines | when builders derive from the record |
| `core/parts.av`'s nine or-runs | most of 634 lines | only if `@derive(Parts)` lands; separate work |
| `Dispatch`, `new_dispatch`, the arms of `semantics_of` | 49 fields, 49 lines, ~90 arms | only with the claim-by-impl step; separate work |

This cut alone deletes little. What it buys is that the last two rows become possible: a derive can now read which feature file a variant lives in.

---

## 6. Risks and checks

| risk | check |
|---|---|
| An ordinal moves during migration | before/after: `avra check packages/std-avrac` with the product over its own tree — the trap CLAUDE.md records ("index 0 is out of bounds" in `match_kids`) is the signal. Plus a script diffing variant→number against the old order |
| Record names collide. A variant is named by its record, and `Error`, `Use`, `Match`, `Block`, `Call`, `Let` are common words; `Expr.Error` and `Stmt.Error` both exist | a spelled variant name on the mark, e.g. `@node_stmt(30, "Error")`, or a naming rule; decide in PR 1 |
| Two enums share one feature record name (`Collect` is in both `Expr` and `Stmt`) | same remedy |
| A feature's test fixture wears the mark and joins `Stmt` | already held: a test file's declarations are gathered only by their own file (`features/decls.av:1572-1574`) |
| A package outside std-avrac adds a node | `package` scope, not `closure`; a foreign `@node_stmt` gathers nothing |
| Held (cached) files: a member admitted from a stored record instead of a parse | the gather reads `Decl` rows, which held files also fill (`compiler/interface.av:368`); needs a cache-attack case: edit one member, check an untouched consumer |
| `fmt`, docs and `explain` read the enum's written variants | each must read the gathered signature; grep `enum_parts(` consumers in PR 1 |

**Could not determine by reading**

1. Whether a derive on a `collect enum` statement runs at all today, or is refused. Nothing in the tree does it.
2. Whether every file of the package is *parsed* before `core/nodes.av`'s derives run. `admit_scope` admits on first gather, but the derives run during name resolution of `nodes.av`, which is among the first files any compile touches. If a member's file is parsed while `nodes.av` is mid-resolve, this is the re-entry CLAUDE.md warns about.
3. Whether a record's field marks (`@body`) survive into the type a derive receives for a *variant* payload.
4. Compile-time cost: `Stmt`'s signature now reads 31 files instead of one. ESTIMATE: small, but it puts every feature file under every reader of `Stmt`'s signature, so an edit to any member record invalidates widely. Correct, and worth measuring.

**The one most likely to bite: item 2.** The derives need the full member list at the earliest moment of the compile, from files that have not been asked for yet.
