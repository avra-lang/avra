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

### 3.1 What the types cannot say — no new annotation surface (CHECKED)

The lead's question: are `@apart` and `@rebuilt(verb)` new marks, or derivable? Answer, from the code:

**`@apart` is already there, one level up, and is enough.** Every variant that holds a `Param`, `Case` or `Variant` payload already wears the variant-level shape word `@apart` (scripted over `core/expr/expr.av` and `core/stmt/stmt.av`): `Lambda`, `FnDecl`, `ExternFn`, `StructDecl`, `EnumDecl`, `Spec`, `ComponentDecl`. The variants that hold `Arm` and `CompClause` wear `@branches` / `@clauses` (`Match`, `Comp`). Today `@apart` is a required word with no behaviour of its own (Children's `reach_of` treats it like `@sequence`; the absence of rows for `Param`/`Case`/`Variant` does the skipping). The generic rule gives the existing word its teeth, deciding at the HOLDER, so the record types carry no mark at all:

| holder's shape word | record payloads it holds |
|---|---|
| `@apart` | Children reaches nothing through them; Shape folds each by the record's own `Identity` (a `Param` fold already includes its default); Exact compares every field |
| `@branches`, `@clauses(…)`, `@sequence` | read structurally: Children reaches the expression fields, Shape folds the id-bearing ones as constants/lengths/flags and reports the ids as kids |

`FormatPart` holds no expression at all, so it needs no word either.

**`@rebuilt(verb)` is NOT derivable, and needs no mark either.** The hole-seat behaviour is a property of two records only — `Arm` (a lone hole binding the whole arm: `arm_hole`, `Filled.Arms`) and `Param` (a lone hole as a whole entry: `param_hole`, `Filled.Params`). `Filled`/`HoleKind` are keyed by what FILLS a hole, and their pairing with `List<Arm>`/`List<Param>` is by name, so there is nothing structural to derive it from. Proposed: Rebuild keeps exactly **two** rows (`List<Arm>` → `arms`, `List<Param>` → `params`), documented as "the hole SEATS", and maps every other record structurally. That is a registry of two named seats, not annotation surface. `FormatPart` becomes structural by a TYPE change, not a mark: `Hole.name` is a binder written as `string` and renamed through `scoped_name` only when the hole binds; declaring it `Scoped` (free at runtime) makes the generic name rewrite do the same (`_` is unchanged by the rewrite). `Case`, `Variant`, `CompClause`, `CatchArm` map field by field (`Variant.marks` through `Mark.call`).

So: **no owner question is open.** The only decisions are the ones above: the two named hole-seat rows, and `Hole.name: Scoped`.

Corrected tally of section 1's table: Children 2 rows and Shape 4 die; Exact 6 die; Rebuild 6 rows → 2 (the seats); `Makes` keeps 7 (builder-side). The hand fns that die are the `exact_*`/`shallow_*`/`kids_*` set and the `comp_clauses`/`cases`/`variants` Rebuilder verbs; `arms`/`params` stay as the seat verbs.

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
2. **Helper** (built): `payload_of(owner, name) -> Held?` and `Held { Record(fields), Enum(variants) }` in `@std/meta`, pinned by `record_reads`.
3. **Children** reads `Arm`/`CompClause` generically; delete 2 rows + `comp_clause_reach`'s hand walk. Witness: the existing `core/tests` child-walk goldens unchanged, plus a mutation (a record whose field order is swapped) failing.
4. **Exact**: 6 rows + `exact_arm(s)`, `exact_comp_clause(s)`, `exact_param(s)`, `exact_variant(s)`, `exact_case(s)`, `exact_format_parts` die. Witness: `Exact`'s own adversarial suite.
5. **Shape** (the fingerprint move): measured as in 3.3.
6. **Rebuild**: two seat rows remain (`Arm`, `Param`); `CompClause`, `Variant`, `Case` map generically; `Hole.name: Scoped` makes `FormatPart` generic.
7. **`catch` option A** (parked on `nodes-catch`, commit 3564737e): `CatchArm` then costs zero derive rows.

## 5. Risks

- A record whose behaviour I assumed generic is not: `Case` (a spec body) and `Variant` (its payload seats carry defaults) are read apart because their HOLDERS are `@apart`; the first witness for each is a derive-level test, not a suite pass. A new variant that holds one of them without `@apart` would walk it — the same holder law, now also checkable (a keeper can refuse a non-`@apart` holder of a record whose fields reach a default).
- Shape fingerprints moving changes which hole runs line up only if two shapes collided before and not after (or the reverse): the quote-pattern suites are the witness.
- `type_exported` needs the enum's module to EXPORT every payload record. Today every one is. A record added in a member's own file would answer absence and be refused, loudly, naming the type (finding 2).
- The probe pinned module `rprobe2.core` style names only in a throwaway; the committed test prints no module name, so it does not move with a package rename.

## 6. As built (slices 3, 4, 6; slice 5 held)

Branch `nodes-generic-records`. Each derive commit was proven on avra-nodes1b with a compiler built from the tree (the derive source runs inside that build, so the compiler compiled with the generic derives is what ran the suites): `core` 318/318 + 2 programs, `features/quote` 134, `features/enums` 478 + 17, `features/lists` 344 + 21, `features/tests` 202 + 29 — every count identical to the baseline taken on the same Sprite before the first derive changed. `make fingerprints` clean after each commit. `make avra` twice reaches a fixed point (the second build is a store hit, so the generated code did not move).

| derive | before | after |
|---|---|---|
| Children | rows for `Arm`, `CompClause` | none: both read off their declarations; `@apart` holders skip record payloads, so no new mark |
| Exact | rows for `Arm`, `CompClause`, `Variant`, `Case`, `FormatPart` + `exact_comp_clause(s)`, `exact_variant(s)`, `exact_case(s)`, `exact_format_part(s)`, `exact_hole` | none; one new row, `List<Mark>`, because a mark's equality deliberately ignores its call |
| Rebuild | rows + Rebuilder verbs for `CompClause`, `Variant`, `Case` (`comp_clauses`, `variants`, `cases` and the singular forms) | none; one new row, `List<Mark>` → `marks` |

Still hand, each for a stated reason: `Param` (holds itself through `says`, and is a hole seat), `Arm` (a hole seat; `exact_arms` also serves `exact_view`), `FormatPart` (its rebuild renames a binder spelled `string`), `Mark` (partial equality), `BodyView` (an expansion equals any expansion), `TypeRef` (holds itself). A recursive record keeps a row: the derive refuses to enter a declaration it is already inside, with a call to a function that does not exist, so the defect lands at the generated code naming the type.

**Mutation witness (Children).** With `Match` re-worded `@apart` the walk stops reaching its arms and `core/children_adversarial` fails two cases ("a match's subject and every arm's value are children…", "a match's written guard is reached between subject and value"); restored, green. The existing adversarial tests already pinned the exact order the generic walk must reproduce (guard before value).

**Shape (slice 5) — built on its own branch (`land-generic-shape`), a landing that wants a `make seed` right after it.**
`Matchable` reads `Arm`, `CompClause`, `Param`, `Variant`, `Case` and `FormatPart` off their declarations: a holder wearing `@apart` folds each by the record's own identity (`fp_list([each.identity(self) …])`, which is EXACTLY what the old `param_fps`/`variant_fps`/`case_fps` rows computed, so those shallow values do not move), every other holder folds the declaration shallowly (a record's fields in order, an enum's variant by its own name) and reports its ids as kids. Retired: the six shallow rows, the `Arm`/`CompClause` kids rows, `shallow_comp_clause(s)`, `kids_comp_clauses`, `kids_of_comp_clause`, `case_fps`, `variant_fps`. `Hole`/`FormatPart` gained `@derive(Identity)`. `Matchable` now claims the `@apart` word.

What moves: only the shallow values of nodes whose holder is NOT `@apart` and holds an `Arm`, `CompClause` or `FormatPart` — `Match`, `Comp`, the format pattern. `shallow_*` values are compared with rule patterns BAKED into the compiler binary (`known_kinds`, rules_table.av's "rule baked by an older compiler… rebuild the compiler"), so a compiler built by a compiler with the old values carries stale baked patterns for exactly those nodes.

**The baked-rule witness (PROBED, avra-nodes1b).** A scratch file with `match k { .Ready -> true, _ -> false }` (rule `enums.bool_variant_match`) and `[n > 0 for n in src].all(it)` (rule `lists.bool_comprehension_list`), checked by each generation:

| compiler | rule findings |
|---|---|
| gen1 — built from this tree by the STANDING compiler | none (baked patterns stale: the hazard) |
| gen2 — after one `make avra` | `bool_comprehension_list` x2, `bool_variant_match` x2 |
| gen3 — after a second `make avra` | the same |

So a rule over `match` and over a comprehension fires again after `make avra` once and is stable at the second; the committed seed is gen0 in that table, which is why the landing is followed by `make seed`. Suites on the gen3 compiler: core 318 + 2 programs, quote 134, enums 478 + 17, lists 344 + 21, features/tests 202 + 29, results 85 + 7, expr_spine 740 + 13 — all identical to the pre-change baseline; `make fingerprints` clean (190 parts lists); `fmt --check` clean over std-avrac and std-meta.

Build notes found on the way: `within` is a reserved word (F3002); BSD `sed` has no `\b` (a silent no-op, caught by a failed build); a bare variant in the element of a list comprehension hears the LIST's want, so a derive that builds enum variants inside a comprehension must qualify them (`CompClause.Head(…)`), as the hand verbs always did.
