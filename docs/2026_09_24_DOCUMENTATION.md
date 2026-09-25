# Documentation — the complete design

> **Status:** consolidated reference, 2026-09-24. Replaces six documents that
> accreted across one campaign day (2026-09-05/06) and had grown redundant
> with each other: `2026_09_05_DOCUMENTATION_VISION.md`,
> `2026_09_06_DOC_DB_ARCHITECTURE.md`, `2026_09_05_DOC_SPINE_DESIGN.md`,
> `2026_09_05_DOC_RESEARCH_prior_art.md`, `2026_09_05_DOC_SUBSET_PROBE_LOG.md`,
> `2026_09_06_SHOW_FORMAT.md`, `2026_09_06_COLD_START_MEASUREMENT_01.md`. Their
> substance lives here; the files themselves are deleted (git history holds
> them if the day-by-day narrative is ever needed). Historical note: the
> vision document had already absorbed most of the show-format and
> cold-start-measurement content verbatim by the time it was last edited —
> this document finishes that consolidation and adds what changed since.
>
> **Checked against the tree as it stands, not as the campaign left it.**
> Where a design was proposed and has since been built, built differently, or
> superseded by a later design, that is stated explicitly (§4, §8).
>
> **Interacts with:** `2026_09_24_DIAGNOSTICS_ARCHITECTURE.md` (kills F-codes
> — changes doc addressing, §4.6, §6), `2026_09_24_AUTONOMOUS_SYSTEMS_AND_STATE.md`
> (a Command→Receipt primitive doc verification should reuse, §10.3),
> `2026_09_24_ORM.md` / `@model type` (a data substrate for docs, §4.0).

---

## 1. The thesis, in one page

**Documentation is a compile target.** `avra build` projects the semantic
object into a binary; `avra doc` projects the same object into
documentation. Same query engine, same fact tables, same incrementality.
Change one function and the pages that describe it re-derive; nothing else
does.

**No `@param`.** The signature is data the compiler already holds — a
parameter's name and type. You write only what the signature cannot say:
the invariant, the failure mode, the unit, the warning. If the name and
type say everything, the parameter gets no prose, and that is the correct
amount, not an omission. **Ratified by the owner** (2026-09-06) and backed
empirically beyond the drift argument: an ablation over 1,017 real API docs
found that deleting the parameter list from an LLM's context *slightly
improves* generated-code accuracy (arXiv:2503.15231) — this is not merely
a maintenance-burden argument, it is measurably the more useful document.

**A doc entry and a diagnostic are the same object seen from two sides.** A
diagnostic says: here is the law, here is where you broke it, here is the
fix. A doc entry says: here is the law, here is where it applies, here is
the form. **The undocumented is a diagnostic, not a coverage percentage
read once a quarter** — a warning at the site, with a structured fix,
riding the exact machinery that already renders every other error.

**Examples teach; prose does not — measured three times, three domains**
(§2). The loaded spring for a model with no prior exposure to Avra is
*verified running programs*, not hand-written prose: `@std`'s own `then`
spec cases (638 of them, already (caption, program) pairs) and `corpus/`
(gate-enforced feature programs), ahead of the ~700 `///` comments, which
serve a different reader — the one who already knows the language and
wants one fact.

**The negative space is a verified corpus.** "The subset today" — every
place the compiler refuses something a newcomer will reach for — stops
being hand-maintained prose and becomes `lang/subset/*.av`: compiled
programs, each asserting both a refusal and its exact wording, failing
`make gate` the day the refusal becomes legal. This is the one idea in the
whole campaign the prior-art survey certified as genuinely novel (§2).

**Staleness is a query dependency, not a heuristic.** A doc's prose is
part of what a declaration *is* — editing it must be able to invalidate
whatever depends on it, the same as editing the declaration's body would.
(As it turns out, the tree already does this, more simply than the design
proposed — §4.2.)

**The compiler never writes prose. It emits a work order.** `avra doc
--stale --json` produces a value: {symbol, old prose, old/new signature,
structural diff, house style}. An agent — never the compiler — writes the
replacement sentence. The compiler stays a pure function (P14); the model
is the driver, not a dependency.

**One resolver, project symbols before language features, with a hint on
fallthrough.** Kept from the old-tree spec verbatim — it was right the
first time. Extended here: **`avra explain` collapses into `avra docs`**
(§6) — one address space, one command, for a diagnostic kind, a language
feature, a grammar fragment, a user's own declaration, or a package's
declared capability.

**One relation, one render query — no renderer per surface.** Every doc
atom (a symbol's prose, a `@shows` example, a diagnostic's explanation, a
feature's grammar fragment, a corpus example) is a row in one relation.
Formatting — verdict-leading a refusal, dedenting a block, picking
examples under a budget — happens exactly once, in the query that renders
a row or a set of rows to text, memoized like any other compiler query
(§4). `avra docs` at a terminal, an LSP hover, `--md`, and a generated
brief are the *same* query called with a different selection and limit,
never four implementations that each re-learn how to format a doc. A
surface that needs structure instead of prose (`--json`, a future MCP
tool schema) reads the row's typed columns directly — it skips rendering,
it does not reimplement it.

**The capability index.** A package declares what it is *for*
(`avra docs --for "read a file"` routes to `@std/io`), generalizing
`@std/process`'s existing manifest-capability idea.

**The cold-start gate outranks every other rung.** Owner's explicit ranking
(2026-09-06): above every keeper, every surface, every ratchet — *"must be
made real rather than designed further."* Three weeks later it still is
not (§5).

---

## 2. The evidence, condensed

Everything above is a design opinion until it is checked against what is
actually known about how models use documentation. A commissioned survey
did that check and overturned parts of the first draft. Kept here because
the design decisions above depend on it, not as a literature review for
its own sake.

**The keystone experiment exists and was already run.** Giagnorio,
Martín-López and Bavota, *No Resource, No Benchmarks, No Problem?*
(arXiv:2606.16827, June 2026), measured code generation for Gleam and
MoonBit — languages that stabilised after model training cutoffs, so this
is a genuine zero-prior test:

| condition | Gleam | MoonBit |
|---|---:|---:|
| zero-shot | 0–1% | 0–1% |
| retrieval over official **language documentation** | 1.23% | — |
| **five-shot code examples** | — | **8.06%** |
| fine-tuned | 3.04% | 10.93% |
| pre-trained further | 12.47% | 25.86% |
| + instruction transfer | 26.08% | 32.60% |

**Syntactic errors — code that does not parse — were 66–90% of no-resource
failures**, versus under 10% for established languages. Few-shot examples
cut syntactic errors 15.36%; documentation retrieval cut them 8.94%.

**Three independent studies, three domains, one conclusion: examples
teach, prose does not.**

| study | domain | finding |
|---|---|---|
| arXiv:2606.16827 | Gleam/MoonBit code-gen | examples beat doc-RAG, above |
| arXiv:2409.19151 | Kalamang translation from a grammar book | *"almost all improvements stem from the book's parallel examples rather than its grammatical explanations"* — and *"no evidence that long-context LLMs can make effective use of grammatical explanations"* |
| arXiv:2503.15231 | 1,017 APIs, 4 Python libraries | deleting **example code** collapses accuracy 0.66–0.82 → 0.22–0.39; deleting the **description** is near-neutral; deleting the **parameter list** *slightly improves* it |

**What this overturned in the first draft:** the plan was to degrade a
generated brief by *resolution* (fewer details per feature at low budget).
That is backwards — a low-budget brief built that way is 29 one-line
syntax summaries, the exact shape the Kalamang study found teaches almost
nothing. **Degrade by feature *coverage* instead: fewer features, one
complete compiling program each.** A model that has seen three real Avra
programs transfers to a fourth feature better than one that has seen 29
syntax lines and no program.

**The negative space is not as novel as first claimed, and the honest
version of the claim is stronger, not weaker.** Julia's "Noteworthy
Differences from other Languages" (2013), Elixir's official anti-patterns
catalogue, and Rust's `rustc --explain` (a program that triggers the code,
plus a fix) all ship some version of "here is what you'll reach for and
what happens instead" — as prose that rots silently and nothing catches.
**What nobody does: publish it as a self-falsifying compiled test suite.**
Claim that precisely — "no language has ever documented what doesn't
exist" is false and gets caught by the first reader who knows Julia.

**`llms.txt` is a measured failure of exactly the "generated compact brief"
idea**, and the reason is instructive, not incidental: a ~300,000-domain
analysis found no correlation between having one and AI citation frequency;
adoption sits near 10%; no major lab has committed to reading it. It
failed because it shipped without ever measuring whether it helped. §5 is
how this design avoids repeating that mistake.

**Unison is the closest existing system to "docs are values,"** and its
own limit is instructive: doc blocks are typechecked and evaluated at
render time, but the *prose around them* is exactly as unguarded as
anywhere else — content-addressing did not solve staleness, deriving did.
Unison's own team calls it the best documentation experience in any
language ecosystem they've used, **and it did not move adoption.** Doc
excellence is a real good; it is not, on this evidence, a growth
mechanism. For Avra the argument has to be made rather than assumed: the
author is the audience, and the audience is measurable (P1).

**Notebooks and literate programming failed on authoring cost and on
execution environment, not on the idea.** 75.89% of ~1.16M sampled GitHub
notebooks failed to execute at all. The environment problem does not
weaken just because the author is now a model — corpus programs solve it
by running under `make gate`, in the same controlled tree, always. Any
future move toward a *live* doc site re-acquires that risk and should be
checked against the 75.89% figure before it ships.

**Two genuinely novel things, both currently underweighted in favor of
claims that are not novel:** (1) the verified-refusal corpus (K5, above);
(2) closing the measure→attribute→fix→re-measure loop for documentation
itself, which three papers run partially and none close. §10.6 proposes
sourcing that loop from this repo's own agent-friction stream.

---

## 3. Nine paradoxes, collapsed

P6 says a forced trade-off means the model is wrong.

1. **Complete vs. concise.** Not one axis — completeness (every feature
   present) and resolution (detail per feature) are independent, and only
   coverage may degrade. **A program cannot be truncated, only kept or
   dropped** — a half-program teaches nothing (`s.ordinal` means nothing
   once its declaring `enum` is gone). So the atom is the whole example,
   and completeness has a computable floor: `feature_count × median
   example size` — measured at ~31 tokens/example, ~868 tokens for 28
   features. A budget below the floor is refused with the number, never
   silently served incomplete.
2. **Written by humans vs. generated by machines.** Split by what can be
   derived. Signature, failure set, callers, effects, examples, refusals —
   all derived, unwritable by hand (there is no field to type them into).
   Intent, invariant, warning — written, and hash-guarded against the
   derived shape it describes. Neither half can rot silently: one
   regenerates, the other invalidates.
3. **Docs vs. tests.** This tree already solved it without noticing:
   `corpus/<feature>.av` + `.expected` is verified, gate-enforced, one
   program per feature. Those *are* the examples. A doc example that stops
   working fails `make gate`, not a doc build.
4. **Human-readable vs. machine-readable.** P11: text and JSON are two
   renderings of one value; `render` is called twice, once per sink.
5. **Accurate vs. current.** Staleness is a query diff, not a heuristic. A
   written doc records the shape it was authored against; a change to that
   shape flags the doc at that symbol, old shape and new shape both shown
   — never a vague "docs might be stale."
   — **Two rot mechanisms, not one, and they need different checks:** a
   prose claim rots because *the world moved* (checked by re-running it —
   K5); a `///` rots because *its subject died* (checked by liveness — is
   anything still calling it — K7, not yet built); a `///` can also be
   *adopted by the wrong symbol* when code is inserted between a doc run
   and its declaration — invisible to attachment rules, caught only by a
   fingerprint mismatch (K4).
   — **A claim can also simply be wrong on day one**, with no earlier
   version it drifted from — proximity and freshness both do nothing for
   this; only running the claim (K5's mechanism) catches it, and only on
   day one.
6. **Determinism vs. LLM assistance.** The compiler never calls a model.
   It emits the work order — a prompt-shaped value: symbol, old prose, old
   and new signature, the diff, house style, sibling docs for tone. An
   agent consumes it and writes prose. The compiler stays a pure function;
   the model is the driver.
7. **Language docs vs. project docs.** One resolver: project symbols
   first, language features second, with a hint on fallthrough. `@std/*`
   packages are project docs that happen to ship with the toolchain —
   there is no third category.
8. **Reference docs vs. task docs.** The capability index: a package
   declares what it's *for*, not only what it exports, so `avra docs --for
   "read a file"` routes by capability rather than by name.
9. ~~Documenting the language vs. documenting the compiler's own
   doctrine.~~ **Cut by the owner** (`avra doctrine` is not being built).
   The underlying mechanism — "a law with no keeper is prose nobody
   checks" — still generalizes and shows up again at §4.6 (the negative
   space) and in `CLAUDE.md`'s own exemption law.

---

## 4. The canonical technical model

### 4.0 The architecture: one relation, one render query, thin projections

This is the constraint every subsection below serves, stated once so it
does not have to be re-argued per surface.

**Correction, made while implementing step 2 of the ladder (§12): `@model`
does not exist in this tree yet.** A grep for `@model` across every
package returns nothing — the ORM work (`2026_09_24_ORM.md`) is a design
document, uncommitted, with no derive, no query engine, and no `Db` type
behind it. The `@model type DocAtom = { ... }` shape below is the *target*
shape, to migrate to the day that derive is real (§10.1) — it is not
buildable today. **What is buildable today, in the same spirit and with
the same discipline, is a plain Avra registry** — exactly the pattern
`rt_sigs()` and `pass_codes()` already use elsewhere in this compiler: a
`List<DocAtom>` (or `table<DocAtom>` if the rows end up short and aligned),
queried with ordinary `.find`/`.filter`, never a second hand-rolled lookup
per command. The word "query" in every table below means *that ordinary
function call*, not literal SQL, until the ORM lands.

**The relation, target shape:**

```avra
// TARGET SHAPE — not buildable until @model exists (see correction
// above). Today: a plain `type DocAtom = { ... }` and a
// `doc_atoms() -> List<DocAtom>` fn, assembled once, queried with
// `.find`/`.filter` like every other registry in this compiler.
@model
type DocAtom = {
    address: string,       // "std.text.split", "F2013"→its kind string, "lang.enums"
    kind: AtomKind,        // Symbol | Feature | Diagnostic | Show | Capability
    subject: SubjectRef,   // what compiler table this atom is *about* — never duplicated
    prose: List<string>,   // the written `///` lines, as captured (§4.2)
    tags: List<Tag>,       // parsed @shows/@answers/@refuses rows (§4.4)
    fingerprint: int,      // the shape this prose was authored against (§4.3)
}

@model
type ShownReceipt = {
    atom: DocAtom,
    ran_at: Revision,
    outcome: Outcome,      // Compiled | Refused(codes) | Answered(text) | Trapped(text)
}
```

`DocAtom` is the *fact* table (what the parse and the attachment law
produce, §4.2). `ShownReceipt` is the *verification* table (what actually
happens when a `@shows` row is run, §4.6) — kept separate on purpose, so
`check`/`build` never compile a documentation example as a side effect of
an ordinary build. Nothing about the subject's own signature, callers, or
type is duplicated into `DocAtom` — `subject: SubjectRef` is a foreign key
into the compiler's existing tables (`Decls`, `NodeStore`), read live, not
copied.

**A second correction, also found while implementing: the relation is not
uniformly cheap, and pretending it is would re-hide a cost this repo's own
prior design already knew about.** Renaming `avra explain` to `avra docs`
(§6, done) surfaces the fact directly — its seven arms split into two
tiers with a real cost difference between them, not seven equally-thin
lookups:

- **Registry arms — free, answerable from `avra()`'s once-per-process
  assembly**: a feature's own doc, a diagnostic code/kind, a method row.
  These *can* be a real `DocAtom` list today, built once, queried with
  `.find`.
- **Package arms — cost a live compile**: a declared symbol's own doc
  (`explain_doc`), an annotation's signature (`explain_annotation`), a
  type's representation (`explain_repr`), a write-flow chain
  (`explain_writes`), a package's own declared diagnostic kind
  (`kind_rows`), and the package's declared tools (`process`). Every one
  of these needs `root_program(here())` — a whole-package parse and type
  check — before it can answer anything.

So "one query" does not mean "one flat table scan ahead of time." It means
**one `DocAtom`-shaped answer, however it was produced** — the registry
arms build theirs from a list already sitting in memory; the package arms
build theirs by paying for a compile and shaping the result the same way.
`rendered()` (below) does not know or care which tier produced the atom it
is formatting. This is exactly the asymmetry the original vision document
(before this consolidation) called out for `avra doc <symbol>` — *"a
symbol costs a compile"* — and it is preserved here rather than designed
away, because it is a real cost, not an implementation accident.

**The one render query.**

```avra
fn rendered(atom: DocAtom) -> string
```

Every formatting rule this document states — verdict leads a refusal
(§4.5), a program is kept or dropped whole and never truncated (§3, item
1), budget counts examples never characters (§4.5), the block-to-source
dedent algorithm (§4.5), a claim states only what its program shows (§4.5)
— lives *inside this one function*, memoized exactly like `sig(ws, d)` or
`typed(ws, d)` already are. No other file in the tree is allowed to know
how a `DocAtom` becomes text. A second implementation of any formatting
rule anywhere else is the defect this section exists to prevent.

**Every surface is a query, never a renderer.** The `SELECT`/`JOIN` spelling
below is the target shape once `DocAtom` is real (either as a plain
registry or, later, as `@model`, per the correction above) — read it as
"a `.find`/`.filter` over the same list," not as literal SQL that compiles
today.

| surface | query (target shape) |
|---|---|
| `avra docs <address>` | `SELECT * FROM DocAtom WHERE address = ?` → `rendered(atom)` |
| LSP hover | the same query, same `rendered`, different sink |
| `avra docs --md` | the same query, `rendered` output written to a file — not a second format, because the rendered text is already the right shape |
| `avra docs --brief --budget N` | `SELECT * FROM DocAtom GROUP BY subject.feature ORDER BY surprise LIMIT ...` → `rendered` over the selected rows, joined in budget order |
| `avra docs --for "<task>"` | `SELECT * FROM DocAtom WHERE kind = Capability AND ... ` |
| `avra docs --stale` | `SELECT * FROM DocAtom a JOIN live_fingerprint(a.subject) f WHERE a.fingerprint != f` — a comparison, not a render |
| `avra docs --json` | `SELECT *` — the row's typed columns, marshaled; `rendered` is not called |
| a future tool schema | `SELECT address, subject.signature FROM DocAtom` mapped into a fixed schema shape — a field mapping, not per-symbol logic |
| `make docs`'s keepers (§7) | joins and comparisons over the same two tables — never a call to `rendered` to *check* something, only to *show* it |

**What is done and what is not.** The *name* collapsed (§6): `avra
explain` no longer exists, `avra docs <address>` answers all seven forms,
verified against the real compiler (`avra docs F2013` renders its live
witness; `avra explain` answers "unknown command"). **The internal dispatch
did not** — `commands/docs.av` still branches by hand across the same
seven sources (`avra().features`, `avra().rows.codes`,
`avra().rows.methods`, a package's `kind_rows()`, `explain_annotation`,
`explain_doc`, `explain_repr`, `explain_writes`), each with its own
`println`. That is still "custom shit per projection," seven times over,
under the new name. Building the registry side (§4.0's tiering) so those
branches collapse into `doc_atoms().find(...)` → `rendered(atom)` is the
next real piece of this ladder (§12, step 2) — the rename was the cheap,
safe, verifiable-in-one-sitting part; the unification is the part that
needs the registry designed and built.

### 4.1 Where doc text enters the compiler — BUILT

`///` and `//!` are no longer discarded as whitespace. The lexer captures
each run as a `DocComment { lines, before, at, line_ats, pkg }`
(`grammar/lexer.av:101`) and the parse attaches it to the next statement,
or files it as an orphan remark when nothing claims it
(`attach_docs`/`doc_target`, `compiler/program.av:206-228`). This shipped
as a side effect of the formatter's round-trip requirements, not as a
dedicated doc-system change, and it is more capable than the original
design assumed: it already holds full text (not just spans), and it
already has an attachment law with red-team coverage
(`compiler/tests/docs_adversarial_test.av`):

- A blank line detaches a doc group from its declaration; the group
  survives as an ordinary remark.
- An orphan run before a closing brace becomes a remark there and cannot
  drift onto the next declaration.
- A trailing same-line `///` is a remark, never a doc.
- A doc on a nested declaration lands on that declaration, not its owner.
- An annotated member's `///` (an enum variant, say) round-trips as a
  remark, not a dropped doc, and does not fold into the next real
  declaration's identity — a mark (`@m` on a variant) looks like an
  annotation-wrapped declaration to the lexer, and the doc law must not
  let its doc drift onto whatever statement happens to follow.
- Variant and field docs have no table of their own yet (no `VariantId`/
  `FieldId` exists) — they survive as remarks, not documentation of the
  thing they precede. Tracked as a known gap in ROADMAP; ~6% of doc runs
  in the tree land here today.

A declaration's doc and annotations are already queryable within one
package: `Decls.doc_of(DeclId)` and `Decls.annotations_of(DeclId)` read
straight off this table, and `Program.explain_doc(name)` / `.
explain_annotation(name)` (`compiler/program.av:256-277`) already render
them — currently reachable only via `avra explain <name>` (§6).

### 4.2 Staleness — BUILT, and simpler than designed

The original worry (`doc-spine`, §2.4 of the source material) was real and
specific: the parsed-program cache settles on a *structural* fingerprint
that reformatting never changes, so a naive `docs` query depending on
`parsed` alone would stay cached across a doc edit and serve stale prose —
a live defect in the memo kernel, found by designing a new consumer
*against* it rather than reading it. **The tree solved this a different
way, already:** `store.document(s, lines, at)` folds the doc text directly
into the statement's own fingerprint —
`fp(115, [old_fingerprint, fp_str(lines.join("\n"))])`
(`core/store.av:583`) — so a doc edit changes the identity a dependent
cell is keyed on. There is no second hash to design, no `touch(source(…))`
line to remember: the doc text was never invisible to the cache to begin
with. This closes the specific defect the campaign found; it does not by
itself give freshness a symbol-level, cross-file surface (`F0912`, §7) or
solve the liveness half (§3, item 5) — those still need to be built.

### 4.3 The show/tag format — the ratified design, and what it replaced

**The row shape is settled; where it lives changed once, and the final
answer generalizes past the compiler's own features.**

The first design put `shows: List<Show> = []` directly on
`LanguageFeature`, replacing the dead `docs: string` field. It was probed
hard and mostly survived:

```avra
export enum Expect { Answers(text: string), Refuses(code: string) }
export type Show = { claim: string, program: string, expect: Expect }
```

- **A row's program is real source, not an escaped string.** A `"""` raw
  block works inside a struct literal — `scan_triple` (`lexer.av:175`)
  consumes the whole block as one token, so nothing inside it (including
  `|`, `}`, `"`, or a `///`) breaks the container. Verified across five
  shapes, all exit 0.
- **`table<Row>` is the wrong container** for a multi-line cell. A table
  buys *alignment*; a program-sized cell *spends* it — the header promises
  columns that don't exist, row boundaries become invisible, and every
  program must sit flush-left, fighting the file's own indentation. The
  tree's own precedent (`rt_sigs()`, 78 struct literals in a `List`, not a
  `table<Row>`) already draws this line: short aligned rows get `table`,
  long rows get struct literals.
- **`Expect` as one field, not `answers: string` + `refuses: string`, is
  load-bearing, not stylistic.** A two-field row spends the empty value —
  a real program can genuinely answer `""` (`"".is_empty()`, `split`
  dropping a trailing segment) — and "exactly one of the two is filled" is
  prose nothing enforces. One field with two variants makes the bad shapes
  *unspellable*.
- **A conjunction is a defect when its halves test different mechanisms.**
  One row asserting `.length`, `contains`, and `==` under a single name
  once certified a false sentence, because nobody could tell which half of
  the pass was doing the work. The rule is not "one assertion per row" —
  a single mechanism exercised over several inputs, answered together, is
  a table and is fine — it is **one mechanism per row.**

**Then the carrier was rejected, correctly, and the row shape moved.** A
feature is not a symbol — its meaning attaches to no single declaration —
so a `LanguageFeature.shows` field can only ever describe the compiler's
own 28 built-in features, never a user's `split` or a `@std` package's
`open`. Worse: rendering it requires *executing* the package that declares
it (a component config field is an ordinary Avra value), which is the
two-hats law firing at the doc boundary. **The generalizing fix: put the
same row shape inside the ordinary `///`/`//!` doc-comment channel, tagged,
so any Avra declaration anywhere gets it for free:**

```avra
/// Splits at each occurrence of `sep`.
///
/// @shows a trailing empty segment is dropped
///     "a.".split(".").length
/// @answers 1
///
/// @shows a range answers no methods
///     (0..3).any(it == 2)
/// @refuses F0100
fn split(s: string, sep: string) -> List<string> { ... }
```

- `@shows <claim>` opens; the claim is the rest of the line. Lines
  indented deeper than the tag are the program, dedented to their floor
  (§4.4's block rule). `@answers <text>` / `@refuses <codes>` closes.
- **`@refuses` holds a set of codes, not one.** A single program can
  refuse with several diagnostics at once (an entry point re-export
  outside a package fires both "not in a package" and "re-export not
  supported"); a row recording only the first certifies the wrong law
  while passing. `Refuses` is the exact, sorted, deduplicated set — which
  is precisely `grep -oE 'F[0-9]{4}' | sort -u`, the instrument this
  design already mandates elsewhere, made structural.
- **The `"""`-fence alternative was tried and killed by one probe**: a raw
  block has no terminator content can spell, so a program containing
  `"""` ends its own container. A `///`-prefixed run has no such hole — the
  prefix terminates each line by construction, so a doc comment can hold a
  program that itself contains `"""`, ` ``` `, and its own `///` lines,
  extracted and run clean. (This is the "make the reinterpretation
  impossible, not merely unlikely" law, one substrate over.)
- **False-positive rate, measured before shipping:** the `@word` tag
  syntax matches exactly **one** existing comment out of 7,449 real doc
  lines in the tree (prose about `@recover`, an unrelated grammar
  mechanic). An unrecognized `@word` stays ordinary prose.
- **The tag registry is driver-owned data, not feature-contributed.**
  Features contribute `DiagCode` rows because those codes are *their own
  laws*; no feature owns `@warn` or `@since`. A `doc_tags: List<DocTag> =
  []` config field left empty by every feature is `docs: string`
  happening a second time, inside the campaign meant to retire it. Ship
  `doc_tags()` beside `pass_codes()`; add a feature's own tag only once
  that feature actually owns one.
- **`@warn` should be the last resort, and the test is sharp:** *if a
  warning could have been a refusal, it is a bug in the library, not a
  doc to render.* Real cases split three ways, best first — unspellable
  (no verb takes a raw command string, so there is no hazard to warn
  about), a refusal with a voice (the compiler speaks at the moment of the
  mistake, which beats a comment nobody is reading then), and only last, a
  genuine doc warning for policy that has no other home (a child's PATH
  behavior, a cap that can be lifted). A library where tier 3 is nearly
  empty is a library that used tiers 1 and 2 correctly.

### 4.4 Rendering and authoring rules

Carried forward unchanged — these are properties of *rendering*, not of
where a row is declared, so the carrier change in §4.3 does not touch
them.

**Verdict leads.** A rendered refusal that reads like a valid example is
worse than no documentation — the reader copies a program that cannot
compile. The fix is structural: the verdict comes first, so a skimmer of
code blocks alone can always tell a refusal from an example.

```
`enum` declares variants; `Suit.clubs` constructs one
    enum Suit { clubs hearts }
    let s = Suit.clubs
    s.ordinal
    → 0

✗ REFUSED F0100 — a range answers no methods
    let hit = (0..3).any(it == 2)
    hit

comprehend a range, then scan the list
    let hit = [i for i in 0..3].any(it == 2)
    hit
    → true
```

**The remedy for a refusal is another show, never a prose `instead:`
field.** A refusal and the working form that replaces it are a pair — both
verified, neither able to rot silently.

**Budget counts examples, never characters or lines.** Selection is
round-robin: every feature gets one example before any feature gets a
second. A character-budget packer can squeeze an entire feature out by
accident — measured live: a naive generator lost the only `spec`/`given`/
`then` example in a brief purely because unrelated content earlier in the
same seeded draw reshuffled which programs fit, and the one task needing
that shape regressed silently (§5).

**A claim states what its program demonstrates, never the property it
gestures at.** The verifier checks the program against `Expect`; it cannot
check that the *claim* is no wider than the program. "Declares a **closed
set**; constructs a variant" passed verification while showing nothing
about closedness — the closedness claim belonged on the `match`-refusal
example instead. This is unmechanisable and is the reason it is written
down: a green row can still teach something false, exactly the way a
correctly-passing but over-named test can.

**A claim takes colons and semicolons, never an em-dash** — the renderer
spends the em-dash as its own refusal separator (`✗ REFUSED F2013 — <claim>`),
so a claim containing one renders as two claims with no way to tell which
half is the verdict. Any future rendering that claims a character owes an
authoring rule at the same site, or it will silently mangle a legal row.

**The block-to-source dedent rule is stated over the text, never over a
library's `split`,** because the two authoring forms (flush-left vs.
indented closing fence) hit different edge cases of any given `split`
implementation and a rule tied to one mangles the other:

> Drop the opening line's remainder (asserting only whitespace precedes
> the first newline). Drop the spaces and tabs following the *final*
> newline — never the newline itself, so a trailing blank line survives.
> Strip the common indent. A block whose content begins on the fence's own
> line is refused, not guessed at.

### 4.5 The cross-file query family — designed, partially built

This is the same split as §4.0's `DocAtom`/`ShownReceipt`, described here
in the terms the original design used before this document renamed it: a
fourteenth query family, `docs(ws, f: FileId) -> DocFacts`, depending on
`source` (not merely `parsed` — see §4.2's now-moot worry) and `items`,
holding a file's own `//!` run, its declarations' `///` runs keyed by
`DeclId`, and member runs (§4.1) held unaddressed. A second, separate
family, `shown(ws, id) -> Outcome`, keyed by an interned ask, handles
*verification* — running an `@shows` example — deliberately apart from
`docs`, so that `check` and `build` never compile a documentation example
as a side effect of an ordinary build.

**What exists today is narrower but real:** `Decls.doc_of`/`annotations_of`
already answer per-declaration within the current package, and
`Program.explain_doc` already renders them. What's missing is (a) the
`docs`/`shown` split with example verification as its own family, (b) a
fact answered from the *definer*, not the asker, when a symbol crosses a
`use` boundary — the general rule (`CLAUDE.md`: *a fact every body may read
is answered from the program, never from a pass's own fact tables*) — and
(c) the tag-parsing layer of §4.3 wired into whichever family reads it.

### 4.6 The negative-space corpus (`lang/subset/`)

**`@refuses:` alone is insufficient — measured, not assumed.** About a
fifth of "The subset today"'s entries record something that *compiles* —
`\u` is not an escape, `split` drops a trailing empty segment and keeps a
leading one, a payload-free enum compares by variant. The corpus needs
four verbs: `@refuses:`, `@compiles: yes`, `@answers:`, `@traps:`.

**One file per entry, for 44 of 47; a fixture directory for the other
three, and the gate never silently skips one.** Two subset entries cannot
be reproduced as a loose file at all: `export use` (a loose file answers
`F3015`, "not in a package," *before* reaching the re-export law the entry
exists to pin) and `const` in a module file (a loose file *is* an entry,
so the law never fires). **These two fail differently, and the difference
decides the gate's design:** `const` is *inexpressible* — any attempt
announces itself immediately with the wrong refusal. `export use` is
*mis-expressible* — a row claiming the wrong code (`F3015`) **passes**
while teaching a false law. Mis-expressible is strictly worse than
inexpressible, because it is silently wrong rather than loudly absent.
**The gate must name its exclusions and fail on any entry that is neither
expressed nor named — never skip one quietly.** The exclusion list is a
registry, not a skip: `45 expressed, 2 excluded (named)`, never `45
passed`. This is the exemption law at corpus scale.

**Verification asserts wording and behavior, never a code — a diagnostic
code is not an identity.** A rule can retire while the code it happened to
surface under keeps existing for unrelated reasons: a hand-written
`.Err("`?.` cannot call a method yet")` string inside a builder retired
the day `a?.m(args)` shipped, but the generic code it surfaced under
(`F0102`, "a builder rejected its captures") still exists and always did.
A verifier asserting "F0102 still exists" would have passed a lying entry
for the full 8.2-hour, 14-commit window it took a human to notice. **This
independently converges with today's diagnostics redesign** (which is
deleting F-codes as identities entirely, §6) — both arrived at the same
conclusion from opposite directions: address and verify by kind string and
exact wording, never by number.

**One corpus entry asserts exactly one clause.** A multi-clause entry rots
clause by clause — measured four separate times across this campaign's own
probing, where an entry with two or three claims kept one true and one
false, and stayed green because the surviving clause was the one checked.

**A verified corpus, run by hand, caught real rot the same day it was
built:** 3 of 47 entries had gone stale (things the compiler now accepts
that the doc still forbade), 3 had drifted wording, and a hand-run 63-file
version of the harness verified in 2.3 seconds — cheap enough to be a
`make gate` leg with no compiler change required at all.

### 4.7 What the tree does not yet have, named so nobody re-derives it

- Member docs (enum variants, struct fields) — no `VariantId`/`FieldId` to
  attach a run to.
- A cross-file/cross-package `docs` query and a definer-keyed lookup
  (§4.5).
- Any coverage diagnostic (`F0910`-shaped).
- A liveness check (K7 below) — is anyone still calling the documented
  symbol.
- Any corpus/brief assembly wired to real output (`avra docs --brief`,
  §5).

---

## 5. The cold-start gate

This is the only oracle in the system that is not part of this repo's own
consensus — every other check here (a compiler test, a golden file, a
`.expected`) was written by an author who already understood Avra, so it
can agree with a wrong design forever. A model that has never seen this
repository cannot.

**The mechanism.** A fixed suite of ordinary tasks ("write a fn that
counts words in a file," "define an enum and exhaustively match it"). A
harness hands a model *only* the generated brief — no repository access,
no `CLAUDE.md`, nothing beyond what the brief itself contains — and
compiles what comes back. The pass rate is a ratcheted number, run outside
`make gate` proper (`make coldstart`) because it costs tokens and is
non-deterministic.

**Two measurements have been run, both contaminated, and the contamination
was found by the experiment itself working too well.**

| arm | subject had | compiled |
|---|---|---:|
| treatment | (accidental) project context + a 6000-token generated brief | 9/10 |
| control | (accidental) project context only | 2/10 |

The control arm — designed to fail — wrote `let disc: Shape = .Circle(4)`,
a typed `let` chosen precisely so a bare variant literal reads its type
from the annotation: a documented Avra subtlety a model with genuinely no
Avra exposure does not reach for. That is what triggered the check: every
subagent launched inside this repository inherits its project instructions
in the system prompt, whether or not the harness ever opens a file for it.
**Neither arm was cold.** The valid result is the *delta* (+7/10 from the
brief, holding the contamination constant across both arms); the absolute
9/10 is an upper bound and must never be quoted as a cold-start rate.

**A second run, fixing one attributed failure, demonstrates why the
composition must be diffed per task and never read as a total.** Both runs
scored 9/10 — a naive read says "the fix did nothing." Per-task diffing
shows two things happened, not zero: an import-spelling fix landed (one
task flipped fail→pass) and an unrelated regression appeared (a different
task flipped pass→fail), because a naive character-budget generator lost
its only `spec`/`given`/`then` example when unrelated content shifted a
shared seeded draw. **The model still knew the construct existed — prose
elsewhere named it — it did not know the caption-string shape**, because
prose names a construct and only an example carries its form. This
independently re-derives the whole thesis of §2, by accident, in an arm
nobody designed to test it.

**The completeness floor is measured, not guessed.** Median 31 tokens per
example across real rows → ~868 tokens for 28 features. Both cold-start
runs used 6000 tokens (~7× the floor), so neither run is anywhere near the
constraint that actually matters at low budget; a smaller-budget arm would
be, and the assembly logic should refuse to emit a brief below the floor
rather than silently satisfy no invariant.

**What is blocking a real number, unchanged for three weeks:** a subject
with genuinely no project context — a session outside this repository, or
a bare API call carrying only the brief and one task. Every model
reachable from inside this repo already carries `CLAUDE.md`. This needs a
decision (an external key and a small budget), not more design.

**Why the first honest number must not become the ratchet:** a ratchet set
from a contaminated upper bound is worse than none, because every later
honest run reads as a regression, and a gate that reports regressions for
being correct gets switched off. Fix the harness, add the one attributed
generator defect (imports — a brief assembled from non-importing corpus
programs cannot teach the `use @std.x` spelling), sharpen syntax-error
attribution (currently coarse — three distinct grammar refusals all
collapse into one bucket because they share an F-code), *then* ratchet.

**Why this outranks coverage as a gate (§7, K1 vs. K8):** Elm made doc
coverage mandatory and got `{-| The name. -}` as the equilibrium, plus a
second copy of its own `exposing` list to keep in sync, plus a decade of
false "MISSING DOCUMENTATION" bug reports. Rust deliberately ships
`missing_docs` allow-by-default *because it is noisy*. Do not ratchet
coverage before a real cold-start number exists to say whether prose
coverage buys anything at all; if it does not, the budget it would have
spent goes to examples instead.

---

## 6. The command surface — `avra docs`, one address space

**DONE: `avra explain` and `avra doc` are one command, `avra docs
<address>`.** `explain.av` already resolved seven different address shapes
through one `run(args)` dispatch, and most of them were already doc lookups
in every sense that matters — they only lived under the wrong name. The
rename shipped: `packages/cli/src/commands/explain.av` → `docs.av`,
`ExplainCmd` → `DocsCmd`, the arg renamed `code` → `address`, every embedded
`avra explain` reference in the compiler's own comments/help/hints updated
to `avra docs`, `avra explain` now answers "unknown command." Verified:
`packages/cli` (63/63) and `packages/std-avrac` (188 program proofs)
unchanged; `avra docs F2013` renders its live witness end to end.

**What `avra docs` resolves, today, verified against `packages/cli/src/
commands/docs.av`:**

| form | resolves to |
|---|---|
| `avra docs process` | the tools the package you stand in declares |
| `avra docs repr <type>` | a type's runtime representation |
| `avra docs writes <fn>` | its write-flow chain (package-scoped) |
| `avra docs <scope/name>:<kind>` | a package's own declared diagnostic kind |
| `avra docs @name` | an annotation fn's signature, which *is* its effect |
| `avra docs <code-or-kind>` | a registered `DiagCode` row, with its live witness rendered |
| `avra docs <name>` (fallback) | a declared fn/type/enum/trait/const's own `///` doc and `@name(args)` annotations — `Program.explain_doc` |

**NOT YET DONE: the internal dispatch is still the same seven-branch
if-ladder, only renamed.** Replacing it with the one-query shape (§4.0) is
the next real step:

1. Every source `docs.av` currently reaches by hand — feature table,
   diagnostic registry, method table, a package's own `kind_rows()`,
   annotation signatures, declaration docs — becomes `DocAtom`-shaped
   (§4.0), written once by whichever pass already produces that fact
   today, split into the two tiers §4.0 found (registry vs. package-cost).
   Nothing about those passes changes; only where their output *lands*
   changes.
2. The registry-tier arms (feature, diagnostic, method) collapse into
   `doc_atoms().find(it.address == q)` → `rendered(atom)` first — they need
   no compile and no design beyond the registry itself. The package-tier
   arms keep calling `root_program(here())` but shape their answer as a
   `DocAtom` too, so `rendered()` is still the only formatter for either
   tier.
3. Resolution order (the old-tree spec's, corrected for what this repo now
   knows): project symbol → language feature → diagnostic kind string
   (never an F-code, §4.6) → grammar/keyword → capability query (§8, D15)
   → fuzzy fallback. A miss still names what was searched — the highest-
   value line in the file for a cold reader, kept from the current
   fallback.
4. **No F-code addressing, anywhere, ever, even transitionally.** Today's
   diagnostics redesign (`2026_09_24_DIAGNOSTICS_ARCHITECTURE.md`) is
   deleting F-codes as identities in favor of a dotted kind string
   (`results.catch`) qualified automatically by the owning feature,
   because a hand-picked "highest + 1" number is the only thing that was
   ever actually racing between two lanes. `avra docs` should never grow a
   second addressing scheme only to delete it when that redesign lands —
   `address` is a kind string from the first row ever written.
5. Cross-package, definer-keyed resolution and the capability index (§8,
   D15) are new selection logic over the same registry, not new commands
   and not new renderers.

**`avra explain` does not survive as an alias.** Confirmed by the rename
that already shipped — a second name for the same resolver is a second
thing to keep straight, and the whole point of the collapse is that there
was only ever one address space.

---

## 7. The keepers — six deterministic checks plus the one that isn't

`make gate` grows a leg, `make docs`, riding machinery that already exists
elsewhere in this repo for diagnostics and idioms. **Every keeper below is
a query or a comparison over `DocAtom`/`ShownReceipt` (§4.0) — none of
them call `rendered()`.** A keeper that formats a row to *check* it is the
same defect as a surface that formats a row to *show* it a second way; the
two things a keeper is allowed to do are compare columns and count rows.

- **K1 · coverage.** Every exported symbol has a doc — diagnostic-grade,
  at the site, ratcheted with a baseline that lists sites (never a count,
  per DOGFOODING's own law). **Gated on §5's cold-start number showing
  that prose coverage correlates with correctness** — if it does not, this
  rung is deferred and the budget goes to examples instead.
- **K2 · structure.** A doc says the right *kind* of thing for its
  declaration's shape — an `enum`'s doc mentions what closes the set, a
  fallible fn's doc mentions the failure. Checkable without reading
  English, because the compiler already knows the shape. Held to a
  measured true-positive rate before it ships (the same discipline
  `CLAUDE.md` already applies to `F2040`).
- **K3 · examples run, via the corpus, never inline.** Every `@shows`/
  `@example` reference is verified by compiling and running the row
  itself (§4.3/§4.5) — never by a second, ad hoc "execute this code block
  inside a rendered doc" path. Rust ran that second architecture for a
  decade (a 44-doctest crate spending 22 of 26 seconds on doctests) before
  rearchitecting it; Python's version is the most-complained-about test
  tool in that language. A doc example that breaks fails `make gate`
  directly, because it *is* a gate-enforced program.
- **K4 · freshness.** A written doc that names a shape (§4.2's fingerprint
  fold already gives this for free at the source-text level) flags when
  that shape changes. Its floor is stated, not hidden: it catches "the
  source moved," not "the meaning moved silently under an unchanged
  signature" — the mitigation for that gap is K3.
- **K5 · the refusals still refuse.** `lang/subset/*.av` compiled, each
  asserting its recorded refusal and exact wording. An entry that now
  compiles fails the gate: "this is no longer true — delete the entry." —
  and it fires in the merge that invalidates the entry, naming the files
  to delete, reaching someone who has never read the subset corpus at all.
- **K6 · the brief's coverage is *reported*, not gated.** A set difference
  over *mentions* ("every feature appears somewhere in the brief") is
  exactly `F2040`'s own trap — a proxy for the real doctrine ("the reader
  can write this feature correctly"), and it would pass a brief that
  teaches nothing. Worse: gating on uniform mention forbids the *correct*
  design, which is to weight the brief by surprise — nothing spent on
  `let x = 1`, most of the budget on the handful of things a newcomer will
  confidently write wrong. Report the set difference; gate on K8 instead.
- **K7 · the subject is alive.** A doc atom whose subject nothing
  references is a defect — but only for a private declaration. **An
  exported symbol with zero in-tree callers is the normal case for a
  library** (half of `@std/path`'s surface has one or none) — so the check
  must ask whether a spec case or corpus program exercises an exported
  symbol, never whether anything in the tree happens to call it, or every
  standard-library package renders as a graveyard.
- **K8 · the cold-start pass rate does not regress.** The keeper K6 gave
  up. Lives in `make coldstart`, outside `make gate` proper, because it is
  non-deterministic and costs tokens. **It is the only keeper here that
  measures the doctrine directly rather than a proxy for it.**
- **K0 · the keepers are tested by breaking them, with real fixtures
  against the real checker.** Every one of K1–K7 ships with a case that
  makes it fail on purpose (a deleted doc, a corrupted example output, a
  moved signature, an entry that now compiles) — run through the actual
  checker, never an inline copy of its logic. Both halves of this rule
  have already bitten this campaign once each: a keeper that had only ever
  guarded a three-variant enum turned out to miss an entire test shape the
  day the enum grew; a self-test built from its own duplicate of the rule
  it was meant to exercise passed while the real rule it duplicated had
  already drifted.

---

## 8. Current build inventory

| Piece | State |
|---|---|
| One-relation architecture — `DocAtom`/`ShownReceipt`, one `rendered()` query, thin per-surface reads (§4.0) | **Proposed here, not built** — supersedes treating `docs`/`shown` as bespoke query families with a renderer per command. `@model` does not exist in this tree; the near-term shape is a plain registry (§4.0's correction), not literal SQL |
| Lexer captures `///`/`//!`, attaches to the next statement | **Built** — `grammar/lexer.av:101`, `compiler/program.av:206-228` |
| Attachment law (blank-line detach, member runs, marked-variant non-bleed, nested-declaration ownership) | **Built and red-teamed** — `compiler/tests/docs_adversarial_test.av` |
| Doc text folds into the statement's own fingerprint (source-level staleness) | **Built**, simpler than the design proposed — `core/store.av:583` |
| Per-declaration doc/annotation query, within one package | **Built** — `Decls.doc_of`/`annotations_of`, exercised by `Program.explain_doc`/`explain_annotation` |
| A resolver exposing the above by address, under one command | **Built** — `avra docs <name>` (§6); its internal dispatch is still 7 hand-written branches, not yet a `DocAtom` registry |
| `@shows`/`@answers`/`@refuses`/`@compiles`/`@traps` tag parsing | **Designed, not built** |
| Cross-file/cross-package resolution, definer-keyed | **Designed, not built** — a `WHERE subject.file = ...` clause over `DocAtom` (§4.0), not a separate mechanism |
| Coverage diagnostic (`F0910`-shaped) | **Not started** — intentionally gated on §5 |
| Liveness check (K7) | **Not started** |
| `corpus/` as a differential-test fixture set | **Built** — 20 feature directories, gate-enforced, ready to be *read by* a doc surface |
| `lang/subset/` verified negative-space corpus | **Not committed, but proven** — a hand-run 63-entry version verified in 2.3s and caught real rot the same day |
| A real, uncontaminated cold-start number | **Blocked** — needs an out-of-repo API subject (§5) |
| `avra docs --brief` / assembly with the completeness invariant | **Partially built, not shipped** — the completeness-invariant logic (budget-counts-examples, round-robin selection) exists and is tested; no committed CLI surface uses it, and the one hand-rolled generator that skipped it produced a measured regression |
| `avra explain`/`avra docs` collapse (§6) | **Done** — command renamed, resolver arms unchanged, verified against the rebuilt compiler |
| `LanguageFeature.docs: string = ""` legacy field | **Done** — removed from the component and its 37 call sites; verified against the rebuilt compiler |

---

## 9. Open decisions for the owner

1. ~~Ratify the `avra explain` → `avra docs` collapse (§6).~~ **Done** —
   shipped on `lane/docs`, verified, not yet on `main`.
2. **Ratify the one-relation architecture (§4.0).** `DocAtom` +
   `ShownReceipt` as a plain registry today (`@model` does not exist yet
   — §4.0's correction), migrating to `@model` once it does; one
   `rendered()` query, every surface a thin read. This is the decision
   every other rung in §12 now assumes.
3. **Confirm kind-string-only addressing** (§4.6, §6) once the diagnostics
   redesign lands — no F-code fallback, even transitional.
4. **Coverage: report before gate.** Run even a crude cold-start
   measurement before ratcheting `F0910` coverage (§5, §7's K1). This is
   the same recommendation as three weeks ago, repeated because nothing
   has changed to make it less true.
5. **Fund the real cold-start subject** — an API call from outside this
   repository's context. The single blocking dependency on the owner's own
   top-ranked priority.
6. ~~Remove `features/mod.av`'s `docs: string` field.~~ **Done** — shipped
   on `lane/docs`, verified, not yet on `main`.
7. **Member-doc addressing** (enum variants, struct fields) is out of
   scope for the next rung; flagged so it isn't rediscovered as a surprise.

---

## 10. New directions

**10.1 — promoted to §4.0.** Docs as a relation, queried thinly, rendered
once, is no longer a "new direction" — it is the architecture. What
remains here as genuinely *new* work: `DocAtom`/`ShownReceipt` should be
real `@model` types the moment that derive can carry them, so `avra docs`
is the ORM's first real consumer, proving out the typed-query engine on a
small, low-risk, compiler-internal dataset before it carries user-facing
weight.

**10.2 Docs and diagnostics render off one causal graph.** Today's
diagnostics redesign adds a `causes: X -> List<Y>` walk for
`explain-failures` — which error variants can reach a function, and
through which calls. A doc page for that function should render off the
*same* walk: "what this returns" and "what can go wrong reaching here" are
one graph with two projections, not two systems that happen to agree
today and drift tomorrow.

**10.3 Doc verification rides the Command/Receipt primitive, once it
exists.** `2026_09_24_AUTONOMOUS_SYSTEMS_AND_STATE.md` proposes, for all
durable state: observe a snapshot, propose a typed command, check it
deterministically, record an atomic transition, return a receipt. A
`@shows` example — propose a program, run it against a throwaway compile,
get a pass/fail/timing receipt — is exactly this shape. `shown` (§4.5)
should be built on that primitive once Phase 7 of that design exists, not
beside it as a second, doc-only verification pipeline.

**10.4 Generate agent tool schemas from signature + doc, for free.** P2:
Avra is substrate for autonomous services. Any exported fn with a doc
already carries everything an MCP/tool-use schema needs — name, typed
parameters, description. `avra docs --tool-schema <symbol>` turns any
package into an agent-callable tool surface with zero extra ceremony — P3
applied to agent tooling instead of only human docs. Nothing in the
prior-art survey does this; Context7 *serves* docs over MCP, it does not
generate typed tool schemas from a compiler-verified signature.

**10.5 Live staleness in the LSP, not a batch gate.** Since doc text is
already part of a statement's fingerprint (§4.2), a language server can
flag "this doc no longer matches this signature" the moment the signature
changes — before a save, let alone a commit. This is close to free: it
rides infrastructure that exists today for an unrelated reason (the
formatter's round-trip check).

**10.6 Mine this repo's own agent friction into negative-space corpus
candidates.** The `/feedback` skill already collects friction, sugar-asks,
and defects from every session — a live stream of "I reached for X, the
compiler refused, here's what worked," which is exactly the raw material
`lang/subset/*.av` needs. A tool that watches failed compiles and agent
retries and drafts candidate entries closes the loop the prior-art survey
found missing everywhere in the industry (measure → attribute a failure to
a missing fact → add the fact → re-measure) — sourced from real friction
across every campaign this repo has run, not a synthetic ten-task batch.

**10.7 A live playground for the negative-space corpus.** The verified
refusal corpus (§4.6) is this campaign's one certified-novel idea, and
nobody has "click run, watch it fail with the exact wording the compiler
ships, live." A WASM-compiled Avra plus `lang/subset/` turns the
campaign's best idea into something felt in ten seconds on a website
rather than read about in a design document.

**10.8 Contract tags double as docs and as the commit-time law.**
`AUTONOMOUS_SYSTEMS_AND_STATE.md` wants `authority`, `preserves`,
`compensates` on state transitions, checked at commit. Rather than invent
a second contract syntax, extend the doc-tag registry (§4.3) with
`@authority`, `@compensates`, `@idempotent` tags, so the same annotation a
reviewer reads as documentation is what the commit-boundary checker
enforces — one declaration, two consumers, the seam that document's §4.7
asks for and doesn't yet have.

---

## 11. Honest limits

- **A doc system cannot make a bad API good.** `@std/sqlite`'s original
  `open(path)` was ambiguous between a filename and a URI; the fix was two
  verbs (the two-hats law), not a warning tag. When a doc lane's first
  instinct is to write a `@warn`, its first move should be to ask whether
  the shape can be made unspellable instead.
- **Coverage is not quality.** 100% coverage of "returns the result" is
  worth nothing. K2 (§7) attacks this and will only partly succeed; the
  cold-start gate (§5) is the real answer.
- **The cold-start gate is non-deterministic and costs money.** It lives
  outside `make gate`. Its number is a band, not a point.
- **Staleness detection has a false-negative floor.** A signature that is
  unchanged while the *meaning* moves silently underneath it (a fn that
  quietly starts trimming its input) is invisible to fingerprint-based
  freshness. K3 (examples actually running) is the partial mitigation.
- **The tag vocabulary will be under pressure to grow.** Every tag is a
  thing an author can get wrong and a consumer must handle correctly.
  Growth is a registry row plus a rationale (§4.3); the answer to most
  requests should still be "write prose."
- **`--json` is a public contract the moment an agent parses it** (P9) —
  versioned from the first release or not shipped at all.
- **"Docs that cannot be wrong" is an over-claim.** The honest form:
  *the derived half cannot be stale; the written half knows what shape it
  described.* Unison went further than anyone and its prose is still
  unguarded — content-addressing bought nothing here that a memoized query
  engine doesn't already have.
- **Doc excellence is not, on the evidence, a growth mechanism.** It is
  worth building for Avra anyway because the argument here is different:
  the author is the audience, and the audience (P1's success metric) is
  measurable.

---

## 12. The ladder

Reflects where the tree actually stands (§8), not where the campaign left
it three weeks ago — most of D1 shipped already, for a different reason,
and the cheap, well-specified rungs after it are the ones nobody picked up.

1. ~~Remove `features/mod.av`'s `docs: string` field.~~ **Done**, verified
   against the rebuilt compiler (`lane/docs`, not yet on `main`).
2. ~~Collapse `avra explain` into `avra docs` (§6).~~ **Done, partially** —
   the *name* is one command now, resolving all seven forms, verified end
   to end. **The sequencing in this ladder's first draft was wrong**: it
   assumed the rename depended on the relation existing first. It does
   not — the rename is a mechanical, relation-independent move, and doing
   it first is what surfaced §4.0's cost-asymmetry correction (registry
   arms vs. package-compile arms) before any registry code was written
   against a false assumption.
3. **Stand up the relation (§4.0): `DocAtom` as a plain registry (not
   `@model` — it doesn't exist yet), `ShownReceipt`, and the one
   `rendered()` query.** Seed the registry tier from what already exists —
   the feature table, the diagnostic registry, the method table — and give
   the package-compile tier (`Decls.doc_of`/`annotations_of`, §4.1, and
   `docs.av`'s remaining four arms) a `DocAtom`-shaped answer too, so
   `rendered()` is the only formatter either tier uses. This is what
   actually collapses `docs.av`'s seven branches into one lookup; the
   rename in step 2 did not do this by itself.
4. **Fund and build the real cold-start harness.** The owner's top
   priority, unmoved for three weeks because it needs an API call from
   outside this repository's context. Everything downstream of §7's K1/K8
   depends on having one honest number.
5. **`@shows`/`@answers`/`@refuses`/`@compiles`/`@traps` tag parsing**,
   populating `DocAtom.tags` (step 3) and `ShownReceipt` (step 3). The row
   shape and the false-positive rate are already proven (§4.3); this is
   implementation, not design.
6. **Commit `lang/subset/`.** The format is proven by hand (63 entries,
   2.3 seconds, caught real rot on day one) — this is transcription into
   the already-validated shape, not new design. Each entry is a `DocAtom`
   row like any other, not a parallel corpus format.
7. **Wire `corpus/` and `@std`'s `then` cases into `avra docs --brief`** —
   a query over the registry (§4.0), grouped by feature and ordered by
   surprise, never a new hand-rolled generator. The one generator that
   skipped the completeness invariant produced a measured regression.
8. **Coverage diagnostic (`F0910`)** — only after step 4 gives a real
   number to check it against.
9. **The extensions in §10**, roughly in order of leverage: 10.1 (`DocAtom`
   migrating to a real `@model`, once that derive exists) and 10.5 (LSP)
   are cheap wins off the relation once it exists; 10.2/10.3 depend on the
   diagnostics and autonomous-systems designs landing first; 10.4/10.6/
   10.7/10.8 are new surface area and should wait until the core ladder
   above is real.
