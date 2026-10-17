# Derives read payload records off their declarations

Status: design + probe, for the lead. Epic: avra-8sb5.89.15 (supersedes avra-8sb5.10.175).
Base: main 05afadef. Probe: `packages/std-meta/src/tests/record_reads` (eval == native, runs in `avra test packages/std-meta`).

## 1. The problem, measured

Six derives (`Children`, `Shape` x2 rows, `Exact`, `Rebuild`, `Makes`; `Identity`/`Fingerprint` are already structural) each hold a string-keyed row per payload RECORD type:

| record | rows | where |
|---|---|---|
| `Arm` | 7 | children, shape x2, exact, rebuild, makes x2 |
| `CompClause` (enum) | 6 | children, shape x2, exact, rebuild |
| `Param` | 5 | children (absent on purpose), shape, exact, rebuild, makes |
| `Variant` | 3 | shape, exact, rebuild |
| `Case` | 5 | shape, exact, rebuild, makes x2 |
| `FormatPart` | 3 | shape, exact, rebuild |
| **29 rows** | | `core/*derive*.av` |

Each row is backed by a hand fn: 39 definitions across `core/store.av` (fingerprints, `exact_*`), `core/shape.av` (`shallow_*`, `kids_*`), `core/rebuild.av` (`arms`, `comp_clauses`, `params`, …) and `core/nodes.av`. `catch`'s `CatchArm` would be the 7th record (about 12 sites). A new payload record today means editing six derives and four core files, and a record added without a row is caught only by `Identity` refusing it at generated code (children_derive.av says so itself).

## 2. Probe: what a derive can read of another declaration (PROBED)

`std-meta/src/tests/record_reads`: a derive over a `collect enum` whose member lives in another module (the real shape of `Expr`). Output, verbatim:

```
items: List<Elem> reads fields [a, b] variants []
far: Far is NOT readable from the enum's module
shapes: List<Shape> reads fields [] variants [Dot, Pair]
n: int names no declaration
```

Findings:

1. **`type_exported(t.module, name)` reads any record or enum the ENUM's module exports** — fields with kinds, variants with payloads. `Field.kind` already carries the name (`.List(.Named("Elem", []))`), so the recursion has what it needs.
2. **It cannot read a type only a member's file imported** (`Far`, from a third package). A generic derive therefore sees exactly the types the annotated enum's own file can name. This is the cross-module hazard's answer: there is no name-keyed table to cross, the lookup is *this module's export of this name*. An unreadable type answers absence, and the derive keeps today's loud refusal ("a payload type the derive has no row for", at the generated code) rather than a silent skip.
3. `type_named(n)` (no module) resolved the same types in the first probe (annotation-site scope) but is the call the lead flagged as name-keyed; the design uses `type_exported` only. (First probe, `/tmp`, not committed: on a plain `@derive` over a record in `main.av`, `type_named` read `Elem`, `Far` (imported) and `Shape`; `type_exported` read nothing because the types were not exported. So the two doors differ in exactly the way the hazard needs: `type_exported` never reads what an export list does not hold.)
4. All of `Arm`, `CompClause`, `Param`, `Variant`, `Case`, `FormatPart` are declared in `core/nodes.av` or exported by `core`, because every member must `use core.{…}` to name them. So every payload record the model holds is readable.

## 3. The generic rule (PROPOSED)

A payload type that is a RECORD or an ENUM and is not one of the derive's leaf rows (`ExprId`, `string`, `Scoped`, …) is read off its declaration, recursively, through the SAME per-field row table the derive already has for variant payloads:

- `List<R>`/`R?`/`R` for a record `R`: apply the derive's field rule to each field of `R`, bound by name (`a.guard`, `a.value`), in declaration order, honouring `@local`/`@facet` as the derives already do.
- an enum `E` (`CompClause`): a `match` with one arm per variant, each arm the field rule over that variant's payloads.

So `Arm`'s Children reach (`some_list(a.guard).concat([a.value])`) falls out of `{ pats: List<PatId>, guard: ExprId?, value: ExprId }` (a `PatId` has no reach row, so `pats` contributes none), and `CompClause`'s `comp_clause_reach` falls out of its two variants.

### 3.1 What the types cannot say: marks on the declaration, not rows in the derive

Four record-specific behaviours are real. Each becomes a mark ON THE TYPE (data beside the declaration, claimed by the derive that reads it, an unclaimed mark refused, as the maker derive already does), replacing a string row in a derive:

| semantics today | where | as a mark |
|---|---|---|
| **a record walked from its own root, never through its holder**: `Param` (holds a field DEFAULT), `Variant`, `Case` (a spec body), `FormatPart` | Children has no row for them on purpose | `@apart` on the record — the shape word the nodes already use for a variant, now readable on a record: Children reaches nothing through it; Shape folds it by its own `Identity` instead of shallowly |
| **a hole seat**: `Arm` (a lone hole standing as a whole arm fills with arms), `Param` (params), `FormatPart` | Rebuild's `mut fn arm`/`params`/`rebuilt_parts` with `Filled.Arms`/`.Params` | `@rebuilt(arms)` — names the Rebuilder verb; the generic walk calls it instead of mapping fields. A record with no mark is mapped field by field (so `CompClause` and `CatchArm` need none) |
| **the builder-side carrier**: one `LangNode` variant and one `Slots` accessor per record | `makers_derive` rows, `NArm`, `arms_at` | unchanged in this epic: it is the builder seat, not a derive row; the table is 1 row per record there and stays (listed as a follow-up) |
| **fold ORDER and tags**: `fp(300…315, …)` literals in `shape.av`, pinned by `make fingerprints` | Shape | the generic fold uses `derived(parts)` (`fingerprint.av`), whose tag is claimed once; see 3.3 |

Net effect on the table in section 1: Children 2 rows, Shape 4, Exact 6 die outright; Rebuild's 6 rows become 3 marks (`Arm`, `Param`, `FormatPart`) plus pure field maps for `CompClause`, `Variant`, `Case`; `Makes` keeps its 7 rows (builder side). Hand fns that die: every `exact_*`, `shallow_*` and `kids_*` for these six records, and `comp_clause_reach`; the `arms`/`comp_clauses`/`cases`/`variants` Rebuilder verbs; `arm_fps`/`comp_clause_fps`-class fingerprint helpers where `Identity` already folds the record structurally.

### 3.2 Where the recursion lives

Derives "stand ALONE in their file" (CLAUDE.md), so the recursion cannot be one shared fn imported from a sibling. Two options:

- **A (recommended):** a small helper in `@std/meta` — `payload_of(owner: Type, k: Kind) -> RecordShape?` (the record's fields, or the enum's variants, for a `Kind.Named`, through `type_exported(owner.module, name)`) — and each derive writes only its own combine step (reach / shallow / eq / rebuild). `@std/meta` is a dependency every derive file already has, and the helper is derive-agnostic.
- B: each derive inlines the lookup. Six copies of one lookup: refused by the rule of three.

### 3.3 Fingerprints, goldens, the seed ladder

- **Fingerprints move.** `shallow_arms`/`shallow_comp_clauses` use literal tags 300, 305, 306; the generic fold derives the tag from the type's name through `derived(…)`, so every Shape fingerprint of a node holding an `Arm`/`CompClause` changes value. Shape fingerprints align hole RUNS within one compile (never stored across compiles: `.avra-cache` is keyed by the compiler's own digest, which moves with any compiler change), so the change is invisible except to a golden that pins a number. Measure, never assume: run `make fingerprints` and every suite that touches quote patterns and shapes (`features/quote`, `core/tests`) before and after; any pinned number that moves is read, then re-pinned only with the reason written.
- **Not moved:** Children order (declaration order, as the hand rows), `Exact` (a conjunction of field equalities, same fields), Rebuild output.
- **Seed ladder: none.** The change is in derive SOURCE, which the standing compiler already compiles and runs — it already has `type_exported`, and the code it generates uses no construct the standing compiler lacks. It is a one-landing change that must build with the standing compiler and the committed seed (`seed-check`); no notation or engine change rides with it (this is why it is cheaper than `@fold` was). The one hazard is the front-end one in CLAUDE.md: a derive that generates a refusal for the compiler's OWN source fires during the build that adds it — land with the saved-compiler protocol (`cp build/avra build/avra.pre`).

## 4. Slices (each lands green, each deletes what it replaces)

1. **Probe lands** (done here): `record_reads` pins what a derive may read.
2. **Helper**: `payload_of` in `@std/meta` + its own suite.
3. **Children** reads `Arm`/`CompClause` generically; delete 2 rows + `comp_clause_reach`'s hand walk. Witness: the existing `core/tests` child-walk goldens unchanged, plus a mutation (a record whose field order is swapped) failing.
4. **Exact**: 6 rows + `exact_arm(s)`, `exact_comp_clause(s)`, `exact_param(s)`, `exact_variant(s)`, `exact_case(s)`, `exact_format_parts` die. Witness: `Exact`'s own adversarial suite.
5. **Shape** (the fingerprint move): measured as in 3.3.
6. **Rebuild**: marks `@rebuilt(...)`; `CompClause`, `Variant`, `Case` map generically.
7. **`catch` option A** (parked on `nodes-catch`, commit 3564737e): `CatchArm` then costs zero derive rows.

## 5. Risks

- A record whose behaviour I assumed generic is not: `Case` (a spec body) and `Variant` (its payload seats carry defaults) need `@apart`; the first witness for each is a derive-level test, not a suite pass.
- Shape fingerprints moving changes which hole runs line up only if two shapes collided before and not after (or the reverse): the quote-pattern suites are the witness.
- `type_exported` needs the enum's module to EXPORT every payload record. Today every one is. A record added in a member's own file would answer absence and be refused, loudly, naming the type (finding 2).
- The probe pinned module `rprobe2.core` style names only in a throwaway; the committed test prints no module name, so it does not move with a package rename.
