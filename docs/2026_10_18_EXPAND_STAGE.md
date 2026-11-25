# The expand stage, and validation as refinement

2026-10-18 · design only · code read at `b0d98c49` (main) and `origin/ui-assets` (#898).
Labels: **READ** = I opened the line · **ASSUMED** = not run; a witness in §1.8 settles it.

Two asks. Part 1: component instances that generate declarations, as memoized queries.
Part 2: `@range(13, 130) type Age = int` as a refinement type with no new syntax.

---

# Part 1 — the expand stage

## 1.0 The answer in six lines

| question | answer |
|---|---|
| surface | ONE generator shape, `fn(...) -> Declared` (exists). Two call spellings: an annotation (stands on a declaration) and an instance (its settings record is the argument). Same query. |
| query | new family `Generated`, one row per MAKER (an instance or an annotation use), not per file |
| key | the maker string `maker_said` already mints, plus the instance's settings fingerprint |
| inputs | the settings, the generator's code hash, and every world read, each through the input door |
| cutoff | the fingerprint of the generated CODE TEXT, never of the minted `DeclId`s |
| names before resolve | only the instance's own name; members are FIELDS of a generated record, typed lazily |

Nothing here needs a daemon, a stat-first path or a new evaluator. It moves a memo boundary
and adds one read verb.

## 1.1 What exists (READ)

| piece | where | state |
|---|---|---|
| Declares annotation runs a fn at compile time, answers `List<Directive>` or `Declared { made, problems }` | `std-meta/src/meta.av:547-556`, `annotations/check.av:177-190` | built |
| Materializer: `materialized` → `directed` → `materialized_directive` → `admit_code` | `compiler/expand.av:145-223, 696` | built |
| Granularity: `Family.Expanded` is keyed by FILE (`start_recursive(f.index)`), early cutoff is `fp(31, [d.index for d in made])` | `expand.av:99-134` | built, coarse |
| Per-maker bookkeeping: `generation_opened(f, maker)` / `generation_kept` retire a maker's stale rows | `features/decls_mint.av:743-756` | built |
| Splice dedupe key is `"${f.index}\n${maker}\n${code.text()}"` | `expand.av:699` | built |
| Argument law: every argument is a literal or a const chain naming one (`spelled_at`), else the run yields `[]` and F2067 speaks | `expand.av:152-157, 202-215`; `annotations/check.av:84-92` | built |
| A component with a body already derives through its composing trait | `expand.av:338-368` (`composed`) | built |
| A literal-path file read at compile time, judged once (`embed_placed`) and read again through the settlement (`embed_read`) | `fns/check.av:760`, `compiler/whole.av:368-394` | built, TEXT only |
| The world door: `Read` rows `Text, Octets, Range, Listing, Exists, Env, Tool, Compiler, Embedded` | `compiler/host/input.av:29, 84` | built |
| `provided<T: Provider>("path")` and `asset NAME = "path"`: a value const settled from a file's octets, one judge | #898 (`features/asset/mod.av`, `std-assets`) | draft PR |
| Hygiene: a `quote`'s names resolve where it was written, holes where spliced; copied nodes keep their origin file | `std-meta/meta.av:21-24`; `Elsewhere.written_in: fn(FileId) -> Namespace` at `features/contract.av:95`, read at `resolve/walk.av:397` | built |
| Diagnostics: a copied template's spans are its ORIGIN file's offsets; passes ask `store.spanned_elsewhere(e)` | CLAUDE.md "A COPIED TEMPLATE'S SPANS" | built |

**Correction to the brief.** There is no `Builder.written_in`. `WrittenIn { Signature, Pattern }`
(`contract.av:264`) is something else (what a written type is read in). The hygiene that exists is
`Elsewhere.written_in` plus nodes wearing their file. §1.5 uses that.

**What is missing, in one sentence.** The generator's RUN has no query of its own — it is a
loop body inside the per-file `expanded`, so it cannot be reused, cut off or tied to the
files it read.

## 1.2 The surface (P6: one spelling)

A generator is already one shape. Annotations pass the declaration as seat one; an instance
passes its settings record. Same body, same `Declared` answer.

```avra
// the generator — written once, in a library
export type Icons = { source: Path }

export trait Expands {
    static fn expand(self: Self) -> Declared
}

impl Expands for Icons {
    static fn expand(self: Icons) -> Declared {
        let files = list(self.source, "svg")           // a Listing read
        Declared { made: [member(f) for f in files] }  // see 1.4
    }
}
```

```avra
// the use — either spelling reaches the same generator
icons glyph { source: "art/icons" }          // instance: the settings ARE the argument
@expands(Icons) const glyph = Icons { source: "art/icons" }   // the annotation spelling, for a hand-built record
picture hero { source: "art/hero.jpg", dark: "art/hero-dark.jpg" }
typeface body { source: "art/Inter.var.ttf" }
schema db { source: "db/schema.sql" }
```

Rules that keep it one spelling:

- **A component opts in by implementing `Expands`** — the way it opts into `@derive` composition today
  (`composed`, `expand.av:338`). No `expand` keyword, no new declaration kind.
- **The instance is its own maker.** `maker_said` already names work "no written annotation asked for"
  by the declaration and callee (`expand.av:254`); an instance is exactly that.
- **Annotation-generated and component-generated declarations are indistinguishable downstream**:
  same `Directive`, same `admit_code`, same diagnostics, same `explain`.
- **Why not a `generated` block inside the component.** It would be a second place the generator
  can live, and `Declared` is already the answer type.

Relation to the UI assets work: see §1.9. Short form — the 10-05 design wrote assets as
components (`export picture hero { source, variant { … } }`, `export icons glyph`, `export typeface
inter`); #898's `asset NAME = "path"` + `Provider` was a v1 retreat because "the declaring-expansion
probe FAILED (an annotation can't hand a path to embed)". This stage is the missing piece, so the
component forms return and `asset` becomes the unpinned member of the same family.

## 1.3 The query

New family `Generated`, registered in `Family`'s declaration order (the ordinal law,
`workspace.av:1031`).

| | |
|---|---|
| family | `Generated` |
| key | `(file, maker)`, interned like `input_names` (a name's place is its cell key) |
| value | `GeneratedRow { code: List<Code text>, problems: List<Diag>, reads: List<InputName> }` |
| depends on | (1) the instance's settings fingerprint, (2) the generator's code hash (its `Sig`/`Typed` closure, as `code_hash` already does per family), (3) each world read, as an `Input` cell |
| fingerprint (cutoff) | fold of the generated code TEXTS and problems. NOT `DeclId`s. |
| recursion | none inside the family: a generator is typed in ANOTHER file (`same_file` guard, `expand.av:1027`), so it never asks `Expanded` for its own file |

`Expanded(f)` stays, shrunk to a JOIN: the instances in `f` (found from the parse, no typing) →
each `Generated(f, maker)` → admit. Its cutoff is unchanged. So:

- an edit to an unrelated statement re-asks `Expanded(f)`, which reuses every `Generated` row;
- an edit to one instance's settings re-runs ONE row;
- an edit to a world input re-runs the rows that read it.

**Why the cutoff is on text.** `fp(31, ids)` cuts off on identity, which is stable because
generated keys are stable (`generation_kept`). That is right for "did the SET of declarations
change" and wrong for "did their CONTENT change". Content is what downstream `Sig` queries read.
Text-fingerprint at the row, id-fingerprint at the join, gives both cutoffs.

**World reads.** One new meta verb family, every row a judged path, never a string built at run
time:

| verb | `Read` kind | what the generator learns |
|---|---|---|
| `list(dir, ext)` | `Listing` | the entries (names only) |
| `head(path, n)` | `Range` | the first `n` octets — sizes, kinds, glyph tables' directories |
| `text(path)` | `Text` / `Embedded` | whole text (SQL, OpenAPI, token files) |
| `bytes(path)` | `Octets` | whole octets, for what a header cannot say |

`head` is the efficiency lever. An icon whose pixels change but whose header does not digests
equal at the `Range` input, so the row is not even re-run. Settle at the finest read the
generator asked for.

**The path law is the embed law.** A `Path` seat is a settled literal, judged at the literal
(inside the package, no link, exists — `embed_placed`), and a generator may read only what a
`Path` seat of its own instance names, under it. A path nobody wrote reads nothing
(`embed_read`, `whole.av:388`). The door's rule stands: the world is named, never resolved
(A18, DB 04).

**Purity.** A generator is a lifted run. `const.reach` ("a const cannot read the world") stays;
the reads above are the one door it already has for `embed`, widened to four verbs, not a
hole. Budget is the manifest's `[lifted]` row.

## 1.4 Names before resolve

This is F2067's real constraint. READ: the argument law exists because `Declares` runs inside
the resolve its generated names serve, and typing is unavailable there (`expand.av:140-144`).

What it actually needs is "no typed values". A world read is not typed. So:

| input to a generator | allowed before resolve | why |
|---|---|---|
| literal, or const chain to one (`spelled_at`) | yes (today) | source-known |
| a `Path` literal → file bytes | **yes (new)** | the input door needs no typing |
| a computed expression | no (F2067, unchanged) | needs typed facts |

Settings are a record of literals, so the instance's argument stays source-known. The file
contents ride the world door, not the argument.

**What names exist before reading the file?** Only the instance's own: `glyph`, `hero`, `db`.
Everything else is a MEMBER, spelled as a field read:

```avra
icons glyph { source: "art/icons" }
icon glyph.close {}              // glyph is a const of generated record type Glyph; .close is a field
```

- the generator's one top-level `made` is `type Glyph = { close: Picture, arrow_left: Picture, … }`
  and `const glyph: Glyph = …`;
- a typo is the ordinary no-field refusal listing the members (the #898 draft's wanted behavior,
  for free);
- nothing needs `use art.{close}`: no member is a namespace entry, so no member must exist
  while names are being made.

A provider that must mint top-level types (`schema db {…}` → `User`, `Order`) generates a real
MODULE (lead's decision): `db` is the instance's name, its generated declarations are the module's
members, and `db.User` / `use db.{User}` resolve as any module member does. No new resolve case;
`explain` and docs see a module (P7). The module's member NAMES depend on the input, so a name
lookup into it asks `Generated(f, maker)` — the same two-tier lookup `expanded` already serves
(`expand.av:99`) — and a file that never names `db` never runs it. ASSUMED: a generated module's
member lookup rides that two-tier path unchanged; E5's witness settles it.

## 1.5 Hygiene and diagnostics

| situation | rule | mechanism |
|---|---|---|
| names the generator's `quote` writes (helpers, std calls) | resolve in the GENERATOR's module | `Elsewhere.written_in`, nodes wearing their file |
| names a hole splices (the member name, the type) | resolve where spliced | hole law, unchanged |
| a generated name collides with a written one | spoken at the instance, never silent | `generated_taken` (`expand.av:721`) |
| two instances generate one name | `resolve.duplicate_in_module`, naming both instances | the maker is the label |
| an error INSIDE generated code | points at the INSTANCE, with the template location as the secondary label | `spanned_elsewhere` already says "these spans are foreign" |
| an error IN THE INPUT (a bad `schema.sql` line, a corrupt font table) | points at the input file, line and column | `Declared.problems[i].at` takes a `Loc` into a non-`.av` file |
| the generator fails to run | `annotation.unsettled` at the instance (`voices.av:532`), message carried whole | the builder-words law |

A voice states the LAW. The input-file voice reads "`schema` could not read `db/schema.sql`
line 14: …", not "the generator trapped".

## 1.6 Efficiency

Maximal by construction: nothing runs that the DB can prove unchanged.

| edit | re-runs | downstream |
|---|---|---|
| unrelated statement | `Expanded(f)` join only | none |
| instance's settings | that one `Generated` row | cutoff on text; none if the text is equal |
| icon pixels, same header | none (`Range` digest equal) | none |
| icon added or removed | the one `Listing` input's row | its members' sigs only |
| whitespace in `schema.sql` | that one row | cutoff: same generated text, zero re-typing |
| the generator's own code | every row that uses it | cutoff per row |

Cold-process warm commands (the DB design's whole point) get this for free: a row saves with its
`reads` list, so a fresh process re-verifies the inputs and skips the run.

## 1.7 What is NOT in this design

- No typed expansion (library code rewriting a typed body — the 09-23 doc's "later" item). This is
  the UNTYPED stage: settings in, declarations out. Its recorded trigger is unchanged.
- No watch of directories beyond what a `Listing` input already is.
- No transform of asset bytes: checking reads headers, `build` encodes (#898 law 9). Generated
  declarations hold handles, never payloads.

## 1.8 Phases and witnesses

Each phase lands alone; each has a counted witness, not a green run.

| phase | change | witness |
|---|---|---|
| E0 | `Generated` family; the run moves out of `expanded` into it; join stays | `AVRA_QTRACE`: edit an unrelated statement in a file with 3 instances → `Q ask Generated … reuse` ×3, `compute` ×0 |
| E1 | settings fingerprint + text cutoff | edit one instance's setting → exactly 1 `compute`; revert to equal text → 0 downstream `Sig` computes |
| E2 | the four read verbs through the door; `reads` recorded | edit one input file that one instance reads → exactly that instance recomputes; the other two reuse |
| E3 | `Expands` trait + instance spelling for a component | `picture hero {…}` and `@expands(Picture)` on a record generate byte-identical code; one test, both spellings |
| E4 | first provider: `icons` (Listing + Range) | icon pixel edit → 0 computes; icon added → 1 compute, members' sigs only |
| E5 | `schema` provider generating a module; `db.User` resolves as a module member | whitespace edit to `schema.sql` → 1 compute, 0 re-typing |
| E6 | `typeface` (Range over font directory tables) | table-preserving edit → 0 computes |

Keepers owed (CLAUDE.md's "a check that never failed is untested"): witness that E2 fails with
the read left OUT of `reads` (the row stays stale after an input edit). A `make vocab` row for
the new `Family` and `Read` consumers.

Dependencies: E4 and E6 need #898's one judge for octets. E0–E3 need nothing outside main.

## 1.9 Reconciliation with the UI assets work (read: 268468b7 design, #898, DB doc A14.1, UI lead log)

| UI-lane fact | how this design meets it |
|---|---|
| the probe failed: a Declares annotation cannot give `embed` a path (embed wants a literal at its own call; `const.reach` forbids other reads) | the generator reads through the four door verbs (§1.3) on a `Path` seat of its own instance — the literal is still judged once (`embed_placed`), the read is the door's, no `embed` call needed |
| v1 REQUIRES the pin (`asset logo: Picture = "p"`) because a desugared const cannot take its type from bytes | a generator reads `head(path, n)` and EMITS the typed const, so the type comes from the bytes with no new statement kind. `asset logo = "p"` becomes `asset` the component: its `expand` runs the collected `Provider`s (#898: `provide(path, octets) -> Self?`) on the head and emits `export const logo: <winner's type> = …` |
| `Provider.provide` takes octets | unchanged. Kinds stay library code in `@std/assets`; the expand stage only supplies WHEN and HOW OFTEN it runs (once per instance, re-run only when its `Range`/`Octets` digest moves) |
| 10-05 forms `picture`, `icons`, `typeface`, `variant { mode: .Dark, source }` | each is a component implementing `Expands`; `variant` children are routed into a `List<Variant>` field (S3b routing, already built), so each variant's file is another `Path` seat and another read of the same row |
| "unreached costs zero bytes", shipped name `<stem>.<key8>.<ext>`, key = source bytes ⊕ recipe ⊕ codec | NOT in `Generated`. A handle's `id` is path-derived and its size is a header read, so declarations never hold content. The content key is a separate BUILD query over an `Octets` input per reached asset (the UI log's table gathered by a mark through `collect … in closure`). Editing pixels moves that build query and cuts off at `Generated` — exactly the §1.6 "same header → 0 computes" row |
| the asset table is gathered by a MARK | a generator's `quote` may carry the mark (`@asset export const ${n}: Picture = …`); marks on generated declarations gather like written ones. ASSUMED: needs one witness that a generated declaration's mark reaches `collect` (E3) |
| A14.1 `@icons("assets/icons") type Icons` | the annotation spelling of `icons`; its events table (add file → Listing moves; edit one svg → one constant; comment above → syntax digest unchanged, expansion stands) is §1.6, with `Generated`'s row as the saved expansion. A14.1's "the query call from the annotation (`t2`, the trap)" is what E2 removes |
| path rules: `embed` beside its source, asset verbs from the package root (log 2026-10-17) | one rule per verb family stays: the read verbs here take the ASSET rule (package root), never embed's |
| #898's widened embed judge (text or octets, one judge) | the four verbs call that same judge; E2 depends on #898 landing it |

Consequence for the phases: E4 (`icons`) and E6 (`typeface`) are the 10-05 design's own kinds;
add **E3b: `asset` as a component** (unpinned form via `Provider`), which retires the pin
requirement and the "type from bytes" sugar-backlog item.

---

# Part 2 — compile-time validation as refinement

## 2.1 Does today's Validates path run at compile time, and could it run `@range`?

**Yes, a Validates annotation runs at compile time. No, `@range(13, 130)` is not one, and no
rule runs at a literal today.**

| claim | evidence (READ) |
|---|---|
| a `List<Diagnostic>` answer is the VALIDATES effect | `annotations/check.av:182-184` (`effect_of`) |
| it runs at compile time through `lifted`, speaking each non-warning as a diagnostic | `check.av:100-104`, `spoken_said` at `check.av:512` (kind `annotation.said`) |
| but its first seat is the DECLARATION (`Fn`/`Type`/`Named`), so it judges the declaration, never a value | `receiver_fits` at `check.av:54`, defined `check.av:155` |
| `@range` is `fn range(v: int, lo, hi) -> Result<int, string>` — its first seat is a VALUE | `std-validate/src/validate.av:60` |
| an annotation on a record, enum or named type whose first seat takes a value is a RULE: `is_rule` is true and `check_annotation` RETURNS before running anything | `is_rule` at `check.av:140-144`, the early return at `check.av:43` |
| a rule is data a reader splices where it reads the value; the one reader is `@derive(Decode)`, which CALLS each annotation over what was read, at run time | `std-validate/src/derive.av:7-10` |
| a literal filling a named type is judged by shape only | `features/checks.av:425-440` (`named_accepts`: `accepts(e, of!)`, no rule consulted) |

So `let a: Age = 5` and `let a: Age = 500` both check clean today if `Age` carries
`@range(13, 130)`. The refinement is recorded and never enforced.

F2070 itself: no literal `F2070` is in `packages/` (the code is projected from the kind, as
`Cause.Builder` → F0102 is). CLAUDE.md:1185 attributes it to a failed lift in the Declares path.
I did not trace its projection; the voice a refused literal needs is new anyway (§2.3).

## 2.2 The design: the rule runs at the literal

`@range(13, 130) type Age = int` IS the refinement. No `where`, no new grammar. The compiler
already holds every piece: the rule is a pure fn, the literal's value is source-known, and
const settlement evaluates pure fns at compile time (`Workspace.settled`,
`workspace_analysis.av:581`).

**Seats (a literal's seat is where a want lands):**

| seat | runs the rule? | why |
|---|---|---|
| a literal filling a named type: `let a: Age = 5`, a field `age: Age`, an argument, a default, an element | **yes** | `named_accepts` (`checks.av:425`) is the one door every such seat shares |
| a literal through `Age?` | yes, on the present arm | the nullable path calls `named_accepts` too (`checks.av:325-330`) |
| a field annotation: `@range(13, 130) age: int` in a record | yes, at a literal filling that FIELD | the field's mark is the rule; same door |
| a computed value | **no** — it never fills a named seat (the opacity law) | it crosses through `Age(x)` |
| `Age(x)` over a computed `x` | answers `Result<Age, string>` | a checked constructor; the rule's own `Result` is the answer |
| `Age(5)` over a literal | the rule runs at compile time | a literal through a constructor is a literal fill |

One mechanism, and it is the SAME rule fn the Decode derive calls at run time. The compiler
and the runtime cannot disagree about what is valid: one source of truth, two projections (P12).

**How the rule runs.** `named_accepts` already knows the literal and the named type. After
`accepts(e, of!)` succeeds, collect the type's rules (the annotations whose first seat takes a
value), and for each settle `rule(literal, args…)` through `settled`. A `Result.Err(m)` is a
refusal; a `Result.Ok` is a pass. Rules are pure by their signature (`-> Result`), so the const
law holds; a rule that reads the world is `const.reach`, spoken as it is today.

**Cost.** One settlement per distinct (rule, literal, args), memoized. A hot literal-heavy file
pays once per literal. No runtime cost at all, and the runtime validator is untouched (P4).

## 2.3 The voice

New kind `type.refined`, one named voice fn, the law not the symptom:

```
error[F2xxx]: `5` does not satisfy `Age`
  --> src/main.av:12:20
   |
12 |     let a: Age = 5
   |                  ^ `@range(13, 130)`: must be between 13 and 130
   |
help: a computed value crosses through `Age(x)`, which answers `Result<Age, string>`
```

- The rule's own message is carried WHOLE (a builder's words are its claim). `range`'s default
  message is the voice; `@range(13, 130, message: "…")` already overrides it.
- A `Result.Err(Issue)` rule (`one_of`, `matches`) carries its field path; at a literal, the
  field is the seat.
- One refusal per literal, not per rule, with every failing rule listed (no fix-one-find-next).

## 2.4 Sealed types

`@sealed` says: outside the declaring module no literal fills it, no `Name(value)` builds it
(`features/sealed.av:1-6`; the refusal is `sealed_built`, `sealed.av:55`).

| combination | behavior |
|---|---|
| `@range(…) type Age = int`, not sealed | literals checked at compile time; `Age(x)` is the checked constructor, open everywhere. A value may exist unchecked? NO — `Age(x)` over a computed value answers `Result`, so no unchecked `Age` is constructible |
| `@sealed @range(…) type Age = int` | outside the module nothing fills or converts; the module exports `fn age(x: int) -> Result<Age, string>`. A literal is refused by the seal first (`type.sealed`), never by the rule |
| inside the declaring module | a literal is a literal fill: the rule runs at compile time |

So **refinement without a seal still cannot be forged**: the only paths to an `Age` are a
checked literal and `Age(x) → Result`. `@sealed` adds the OTHER law (who may build one at all),
orthogonal. They compose; neither implies the other, and the seal's voice wins when both refuse
because it names who may build.

## 2.5 What this does not do

- No flow-sensitive refinement (`if x > 12 { x as Age }`). That is a `where` clause's job and the
  owner asked for none.
- No rule on a type parameter. A generic `Bounded<T>` has no literal to judge.
- A rule that needs a sibling field (`matches`) is a record-level rule and judges a record
  literal, not a scalar one. Same door, richer subject; phase R3.

## 2.6 Phases and witnesses

| phase | change | witness |
|---|---|---|
| R0 | probe: a rule fn settles through `settled` at a literal | scratch `const ok = range(20, 13, 130)` and `range(5, 13, 130)`: Ok, and `const.trap`-free Err |
| R1 | `named_accepts` runs scalar rules; voice `type.refined` | `let a: Age = 5` refused, `= 20` clean; golden rendering test; eval == native unaffected (compile-time only) |
| R2 | `Age(literal)` at compile time; `Age(x)` answers `Result` | `Age(5)` refused at the literal; `Age(n)` types as `Result<Age, string>` |
| R3 | record literals: field annotations, sibling rules | a field `@range` refused at the record literal; `matches` judged on the whole |
| R4 | sealed interplay | a sealed refined type: outside the module the seal speaks, inside the rule speaks |

Keeper: witness the rule NOT running (comment out the `named_accepts` hook) fails R1's case.
That is the "a green check that never failed" law.

---

# Decisions

**DECIDED 2026-10-18 (owner):** 1 yes (one `Expands` trait) · 2 yes, block form: `picture logo { source: "…" }` is THE single-file spelling, the `asset` keyword retires by the M1–M5 script rewrite · 3 yes (a generated real module). 4 and 5 recommended, awaiting the owner.

## Table

| # | decision | recommendation |
|---|---|---|
| 1 | Generator surface: one `Expands` trait over a component's settings record, instance and annotation sharing it | yes — P6, zero new kinds. **Lead recommends yes.** |
| 2 | Assets: ONE spelling, from syntax that already exists. The single-file case is the plain component instance `picture logo { source: "art/logo.svg" }` (probed, §Probe below). The `asset` KEYWORD retires; `asset` may remain as an ordinary component word for "kind read from the bytes" | **Lead recommends yes; owner: "if we have a better existing syntax … I am all ears" — this is it.** Migration below |
| 3 | A provider that mints top-level TYPES (`schema db` → `db.User`) generates a real module | **Lead recommends the module**: no new resolve case, `db.User` resolves as any member, `explain` sees a module |
| 4 | Refinement enforces at literals and `Age(literal)` only; computed values cross through `Age(x) -> Result` | **Lead recommends yes** — refinement without `where`, one rule fn for compiler and runtime |
| 5 | `@sealed` and refinement stay orthogonal (seal wins the voice when both refuse) | **Lead recommends yes** |

## Probe: the single-file spelling with syntax that exists (decision 2)

Checked with `avra check` on scratch files, base `70e317d6` (a lone file; `component` declared in it).

| spelling | result |
|---|---|
| `picture logo { source: "art/logo.svg" }` (name + block) | **compiles**; `logo.source` reads |
| `export picture logo { source: "…" }` (exported declaration) | **compiles** |
| `let logo = picture "art/logo.svg"` (value head, `component picture(source: string)`) | **compiles**; `logo.source` reads |
| `export const logo = picture "art/logo.svg"` (value head as a const) | **compiles** |
| `let logo = picture "…" { alt: "A" }` (value head + block) | **compiles** |
| `picture logo "art/logo.svg"` (name AND value head) | refused: "expected BREAK while parsing `stmt`" |
| `picture logo "art/logo.svg"` over a name-headed component | refused: `build.failed` "`picture` takes no head value — name it at a statement (`picture name { … }`), or write `picture { … }`" |
| `picture("art/logo.svg")` (call spelling) | refused: "`picture` is a component, and a parenthesis after its word is read as a call" |

**Recommendation.** The block form, always: `picture logo { source: "art/logo.svg" }`. One line for
one file, the same shape as a folder (`icons glyph { source: "art/icons" }`), a variant list, or a
font with a licence — nothing to relearn when a file grows a `dark:` variant. The value-head form
is a const (a value), not a named declaration, so it cannot mint a module, a folder record, or a
type: it would be a second spelling that covers only the smallest case. Name-plus-value
(`picture logo "path"`) does not parse and would need grammar for no gain.

## Migration of #898's `asset` statement (decision 2)

| step | change | gate |
|---|---|---|
| M1 | land #898 as is (the `asset` statement desugars to `provided<Kind>("path")`; pinned form works today) | its own tests |
| M2 | E3b: `picture` (and `blob`, `typeface`, `icons`) as `Expands` components; `asset` as a plain component word whose `expand` runs the collected `Provider`s (kind from bytes) | the #898 program tests pass through the new spellings |
| M3 | every `asset logo: Picture = "p"` line is rewritten to `picture logo { source: "p" }` by one script over the tree and the docs | `make gate`, the program tests unchanged |
| M4 | the `asset` statement's grammar rule and builder are deleted; `asset` stays only as the component word | `make idioms` clean |
| M5 | docs and `avra new app` write the component spellings | doc build |

No author-visible loss: an unpinned single file still takes its kind from its bytes (`asset logo { source: "p" }`), and a pinned one names its kind by the word.
