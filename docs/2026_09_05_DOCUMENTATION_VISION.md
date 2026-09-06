# Documentation — The Compiler Already Knows, And Nothing Asks It

> **Status:** vision, written to be worked BACKWARDS from. The doc campaign's
> north star. Part VIII is the ladder — what exists today, what each rung
> needs, who owns it. Aspirational syntax is marked `[v1]`/`[v2]`/`[v3]`;
> unmarked code and every number below was measured against THIS tree at
> **`bd5c024`, 2026-09-05** — and the tree moved three times while this was
> written (`6553ec6` → `e046ba2` → `bd5c024`), so every figure here names
> its base and a re-derivation is one command. Counting method, so it is
> reproducible: a symbol is a line matching `^export (fn|type|enum|
> component|trait)`; it counts as documented when the nearest preceding
> line that is not an `@`-attribute starts with `///`. A raw grep of
> `export` lines (978) or of `///` lines (5488) counts different units and
> can neither confirm nor refute these — LAND D checked and said so rather
> than reporting agreement, which is the discipline this tree learned the
> hard way today.
>
> **THE EVIDENCE REVISION (2026-09-06).** A commissioned prior-art survey
> — `2026_09_05_DOC_RESEARCH_prior_art.md`, beside this file — overturned
> four decisions in the first draft and killed three novelty claims. The
> load-bearing result: **examples teach, prose does not**, measured three
> times independently. arXiv:2606.16827 (June 2026) ran Part VII's own
> experiment on Gleam and MoonBit — RAG over the official *language
> documentation* scored **1.23%** pass@1; five-shot *code examples* scored
> **8.06%**. arXiv:2409.19151, learning Kalamang from a grammar book:
> *"almost all improvements stem from the book's parallel examples rather
> than its grammatical explanations."* arXiv:2503.15231 over 1,017 APIs:
> deleting example code collapses accuracy 0.66–0.82 → 0.22–0.39, while
> deleting the description is near-neutral. **A grammar book is a language
> reference manual, and this document's first draft was a grammar book.**
> Every section below is revised accordingly and the revisions are marked.
>
> **OWNER'S RULINGS (2026-09-06).** **(a) No `@param` — RATIFIED.** Prose
> documents only the irreducible; the signature is data the compiler
> already holds and is never retyped. **(b) THE COLD START IS THE
> PRIORITY** — above every keeper, every surface and every ratchet in this
> document, and it is to be made REAL rather than designed further.
> **(c) `avra doctrine` is CUT** (was D14). **(d) The `docs: string`
> feature format GOES** — a better one is owed, see Part V. **(e) NOTHING
> MERGES** without a serious `/red-team` and `/review-round`, aggressively
> run. **(f) A STANDING GRANT for verified rot:** a doctrine claim proved
> false by a probe at a named base may be corrected with its receipt
> recorded — the grant is for *correcting refuted claims*, never for
> writing new doctrine.
>
> **Prior art, read before writing:**
> `../forge-crafting-intepreters/docs/spec_doc_system.md` (906 lines, the
> old tree's design — its `avra lang` / `avra docs` split, its six layers,
> its annotation table; identical in both old trees, never implemented).
> Its bones are good and this document keeps most of them. Where it differs
> is named at Part II. `2026_04_18_FULL_SPEC.md` Part 0 stays law.
>
> **The axioms it serves:** P1 (correct on FIRST generation — a doc system
> for an author that has never seen the language and will not iterate), P3
> (you never write what the compiler already knows), P7 (visible magic: the
> doc is how you ask the compiler what it did), P10 (the compiler holds
> semantic knowledge no other tool has — documentation is the projection of
> that knowledge, and no external tool can produce it), P11 (machine-
> readability is the substrate; the rendered page is the projection, not
> the artifact), P12 (one source of truth, many projections — the binary
> and the documentation are SIBLINGS, both projections of the same
> semantic object).

> **THE PRESENTING FACT.** This tree contains **~980 exported declarations,
> and ~80% of them already carry a `///` doc comment.** The range is
> deliberate: three text scans of the same tree answered 890/690/78%,
> 978/782/80.0% and 985/785/79.7%, differing on whether `export extern fn`
> counts (85 of them do), whether `tests/` directories count, and how an
> `@`-attribute between the doc and its declaration is walked. **All three
> are text scans, and a text scan is the wrong instrument** — the real
> number comes from the compiler over `DeclId`s, which is what D6's
> ratchet baseline must use, listing SITES and never counts. Debt is
> ~200. Somebody wrote every
> one of those by hand, as a discipline, with no tool asking for it and no
> tool reading it. `lexer.av:312` treats `//` as whitespace to end of line,
> and `///` starts with `//`. Every one of those 690 comments is discarded
> during scanning and has never reached a data structure.
>
> Meanwhile `features/mod.av:115` declares `docs: string = ""` on the
> `LanguageFeature` component. **There are 28 features and 28 of 28 fill
> it in — 100%.** (`features/` holds 29 directories; the 29th is
> `features/tests/` and appears in no `language_features()` row.) Grep the
> tree for a read of `.docs`: there is none. The language has written
> its own documentation twice over and built no surface that can see it.
>
> This is not a gap. It is a **loaded spring**. The corpus is already
> written; the campaign is to build the thing that reads it.
>
> **THE PROXIMITY CLAIM WAS AUDITED AND DOES NOT SURVIVE. I published a
> ratio; it is retracted.** LANE A refused "seven stale prose against one
> stale `///`" because a count is not a rate. I fetched denominators and
> published ~1.0% against ~0.14%. **Both figures were large
> understatements and the difference is not significant.**
>
> The audit (doc-subset): populations enumerated and **samples frozen to
> disk before anything was read** — 787 `///` runs on exports, 744 prose
> bullets, 40 drawn from each with a recorded seed, classification fixed
> in advance, unfalsifiable items excluded from the denominator.
>
> | population | stale / checkable | rate | 95% CI (Wilson) |
> |---|---:|---:|---|
> | `///` on exports | 2 / 40 | **5.0%** | 1.4 – 16.5% |
> | prose bullets | 3 / 24 | **12.5%** | 4.3 – 31.0% |
>
> **Fisher exact, two-tailed: p = 0.355.** The direction survives — prose
> is numerically worse under both scorings — but the intervals overlap
> across most of their range. **The `///` rate is 36x my published figure;
> the prose rate 12x.** And the asymmetry is precisely what lane A
> predicted: the `///` numerator was near zero **because nobody had ever
> looked.** Correcting prose alone would have made the ratio look better.
> Correcting both erased it.
>
> **WHAT SURVIVES IS STRUCTURAL, AND IT IS A BETTER FINDING THAN THE RATE
> WAS.** **40 of 40 sampled `///` comments were checkable. Only 24 of 40
> prose bullets were.** A doc comment sits on a symbol the compiler
> already knows, so it is *always* falsifiable. **Prose is ~40%
> unfalsifiable by construction — and that 40% is not the safe part, it is
> the part no tool can ever catch.** That claim needs no ratio, no
> significance test and no larger sample. It is a property of where the
> two artifacts live.
>
> **The mechanism (proximity) still stands on its own** and never needed
> the number: a `///` sits in the file its subject lives in, so the edit
> that changes the behaviour has the doc already open. A ROADMAP entry
> lives a thousand lines away.
>
> **Limits the lane stated rather than letting a reviewer find:** n=40 per
> arm is underpowered (separating 5% from 12.5% at p<0.05 needs ~200);
> one auditor wrote the classification rule and also applied it, which is
> this document's own consensus warning turned inward; and `docs/*.md` was
> outside the frame — the `BYTES_SHAPE` finding suggests that surface is
> worse than the three sampled. Both frames and samples are on disk under
> a fixed seed, so a re-run at a later base draws the same entries and
> this becomes a trend rather than an anecdote.
>
> So the migration's value is not only that the compiler can finally read
> those 690 comments. It is that they are the half we could always have
> checked and never did, while the artifacts we treat as canonical — the
> ledgers, the roadmap, the doctrine file — are the half that cannot even
> be counted without an argument about what counts.
>
> **THERE ARE THREE SPRINGS, RANKED — and the first draft picked the
> worst one for the reader it cared about.**
> arXiv:2503.15231 found that deleting an API's *description* changed
> generated-code accuracy about as little as deleting its parameter list —
> while deleting its *example* collapsed accuracy by two thirds. So the
> 690 `///` comments are the spring for the **targeted-question** surface
> (`avra doc split` — a reader who already knows the language and wants
> one fact), and they are NOT the spring for **cold start**. That spring
> is `corpus/`: **77 verified programs, gate-enforced, one per feature,**
> already passing, already the artifact the evidence says teaches.
>
> **And `corpus/` is not the best of them either — LANE B, and the reason
> is written into our own doctrine rather than accidental.** CLAUDE.md
> requires that *"a corpus program shows its FINAL statement's expression
> only, and an interpolation hole prints scalars and strings only — a list
> is shown through `join`, an index or `length`."* So every corpus program
> ends in a shape the differential runner can compare, **not one a reader
> should imitate**: `"${told(serve("a", false))} ${early(1)}"`,
> `"${doc.keys().length}"`. The bodies teach; the tails are assertion
> harness. **A corpus program is a VERIFIED program, which is not the same
> artifact as an EXAMPLE, and the difference is exactly one statement at
> the end of each.**
>
> **The best spring is the one nobody had counted: the std packages' spec
> cases.** Measured at `74fa9fc`: **638 `then` cases across the twelve
> `@std` packages**, and they are ordinary Avra calling the real API —
>
> ```avra
> then "the text round-trips, newlines and all" {
>     let p = fresh("rt.txt")
>     let _ = write_text(p, "one\ntwo\n")
>     message(read_text(p)) == "ok: one\ntwo\n"
> }
> ```
>
> — which is **exactly the five-shot shape the survey measured at 8.06%
> against prose's 1.23%.** And the `then` string is already the caption: a
> sentence about behaviour, written by someone who had just made the thing
> work. The spec DSL has been emitting (caption, minimal program) pairs
> since it landed and nobody counted them as documentation.
>
> **The counter-example proves the rule.** The compiler's own feature
> tests are the opposite artifact — `shown("${puts()}defer
> avra_puts(\\\"bye\\\")\\nhi\\n1")`, a program inside a string,
> escaped twice, which a reader must mentally unescape before they can see
> the language at all. As teaching material that is worse than nothing.
>
> **LANE B's own caveat, tested and refuted — their finding is stronger
> than they claimed.** They worried the ratio might be an artifact of who
> wrote what: a library's tests naturally call the library, a compiler's
> must quote programs. So I checked the two packages they did not write —
> `std-toml` (42 cases) and `std-testing` (9 cases) — and both look like
> the rest, with escapes confined to TOML/JSON *content* rather than
> embedded Avra. The pattern follows the artifact, not the author.
>
> All three springs are loaded. They serve different readers, and
> conflating them is how the first draft ended up designing a grammar book
> for the reader the evidence says learns from programs.

---

## Table of contents

1. Part I — The presenting bug is a cold start, and it is mine
2. Part II — What documentation IS here (and where the old spec was wrong)
3. Part III — The paradoxes, collapsed (nine)
4. Part IV — A day in the perfect world
5. Part V — The canonical model
6. Part VI — The keepers: six deterministic checks
7. Part VII — The cold-start gate: docs with a pass rate
8. Part VIII — Working backwards: the ladder
9. Part IX — The asks
10. Part X — Honest limits
11. Part XI — Slogans

---

# Part I — The presenting bug is a cold start, and it is mine

I am the primary author of Avra code (P1). Here is what actually happens
when I open this repository in a fresh context, and it is not a
hypothetical — it is the transcript of every lane in this campaign:

1. I `ls`. I `grep`. I read four files that look representative.
2. I infer the idioms from what I see. I get maybe 70% of them.
3. I write a function. It uses a `for` loop with a `push` because that
   is what every other language taught me.
4. `make idioms` fails on I1. I read `DOGFOODING.md`, 1321 lines.
5. I write `xs.reverse()`. There is no `reverse`. I discover this from a
   compile error, not a doc.
6. I write `let xs: List<int>? = []`. F2024. I did not know empty
   literals do not adopt a nullable want. **Nothing could have told me
   except trying it.**
7. Somebody adds an entry to `CLAUDE.md`'s "The subset today" — by hand —
   so the next agent does not repeat step 6.

Step 7 is the tell. **"The subset today" is the single most valuable
document in this repository and it is maintained by hand, by exhaustion.**
It is **47 entries** (27 the grammar lacks, 11 the typer does not carry,
5 methods the runtime lacks, 4 runtime facts — counted at `1937ea1`) of
"I reached for X, here is the refusal, here is what to write instead,"
each one paid for by an agent burning a compile cycle and a human's
patience. It rots the instant the compiler accepts one of its entries,
and the only thing that catches the rot is somebody re-probing 47 entries
by hand.

**It rotted twice today, and both were found by luck.** LANE B found the
entry claiming "`?.` cannot call a method yet" *after* another lane had
landed `a?.m(args)` — the quoted code no longer existed anywhere in the
source — and only looked because a peer's message made them suspicious.
LANE C found three ROADMAP entries asserting "`ptr` is receive-only
today", which stopped being true an hour earlier when `avra_ptr_at`
landed. Three places asserted a thing the compiler no longer does and
nothing failed.

A stale *reference* entry is an inconvenience. **A stale subset entry is
worse than no entry at all**, because it says "do not write this" — so a
rotted one costs every future author the workaround, forever, and reads
exactly like a live one while doing it.

That document should be **generated and verified**. Every entry is a
program and an expected refusal. The compiler can run all 47 in under a
second and tell you which ones are now lies.

That is the shape of this whole campaign. Not "let us write docs." The
observation is:

> **Everything an LLM needs to know about a language is already a fact the
> compiler holds, and every doc system ever built has thrown that away and
> asked a human to retype it into Markdown.**

JSDoc retypes the parameter names. RustDoc retypes the signature. Every
one of them creates a second copy of something the compiler knows exactly,
and then spends its entire engineering budget on the drift between the
two copies. **We have no second copy. We have a query engine.**

## What I actually want, stated plainly

Not "documentation." These, in priority order, because they are what
determine whether I write correct Avra on the first try:

| # | Want | Why it beats a doc page |
|---|---|---|
| 1 | **The whole language, complete, in a token budget I name** | 80% of a language is worse than 100% at low resolution — the 20% I lack is exactly what I will write wrong *confidently* |
| 2 | **The negative space** — what does NOT exist and what I will reach for anyway | I already know ten languages. My failure mode is transfer, not ignorance |
| 3 | **The refusal, before I earn it** | A counterexample teaches more than an example, because the example is in my prior and the refusal is not |
| 4 | **Idioms as enforced law, not prose** | Prose I read once and forget. A diagnostic at my site with the fix attached, I cannot forget |
| 5 | **Docs that cannot be wrong** | I trust docs completely and have no way to tell a stale one from a live one. That is a *safety* property, not a nicety |
| 6 | **Answers shaped like my question**, addressable and diffable | I do not want a page. I want the one line, and a stable address to cite in a follow-up |
| 7 | **What changed since I last looked** | Resuming work should cost a diff, not a re-read |
| 8 | **The answer routed to me at the moment I need it** | A correct doc I did not find is indistinguishable from a missing one |

Row 8 is the one this campaign nearly missed, and LAND D named it: the
subset entry on empty literals in nullable seats is **correct, verbatim,
and cost a lane an hour anyway** — while that lane was actively working
inside the subset it documents. That is not rot. **That is SIZE**: a right
answer that failed to reach a reader who was looking for it. A verified
corpus fixes truth and does nothing for reach.

The answer is that **the refusal is the routing surface**. F2024 already
fires at exactly the moment that entry is relevant, at exactly the site,
to exactly the reader who needs it — so a subset entry carries the
diagnostic code it explains, every diagnostic gains a doc-address footer,
and the highest-traffic doc surface in the system turns out to be the
error message we already ship. Nobody has to find the section; the section
finds them.

Everything in this document exists to serve that table.

---

# Part II — What documentation IS here

## The one-line thesis

**Documentation is a compile target.**

`avra build` projects the semantic object into a binary. `avra doc`
projects the *same object* into documentation. Same query engine, same
fact tables, same memoization, same incrementality. Change one function
and exactly one doc page re-derives, because `sig(d)` is a memoized
query whose hash is unchanged for every function that merely *calls* it.
We do not have to *build* incremental documentation. `docs/MINIMUM.md`
already built it; nobody has asked it for a page yet.

Three consequences follow immediately and each is a design rule:

**(a) The signature is not documentation. It is data.**
You never write `@param radius - the radius`. The compiler knows there is
a parameter named `radius` of type `float`. Writing it again creates the
drift the entire system then has to police. **You write only what the
signature cannot say** — the meaning that the name and the type together
fail to carry, the invariant, the failure mode, the unit. If a parameter's
name and type say everything, it gets no prose, and that is not an
omission; it is the correct amount.

This is P3 applied to documentation, and it is the *only* reason 890
symbols is a tractable coverage target. The generated half can never be
wrong. The written half is small enough to keep true.

**(b) A doc entry and a diagnostic are the same object seen from two
sides.** A diagnostic says: here is the law, here is where you broke it,
here is the fix. A doc entry says: here is the law, here is where it
applies, here is the form. This tree already builds world-class
diagnostics with structured fixes and a registry of 106 codes. The doc
system is not built *beside* that machinery — it is built *out of* it.
`avra explain F2040` and `avra doc registry-holes` resolve to the same
row.

**(c) Therefore: the undocumented is a diagnostic.**
Not a coverage report you run in CI and read once a quarter. A
warning-grade diagnostic, at the site, with a structured fix, in the same
column errors arrive in. This is what the owner asked for ("a linter to
show you where you haven't documented") and it is the right shape because
it rides machinery that already exists — and because *this tree's own
doctrine says so*: "A LINT COUNTS WHAT ITS DOCTRINE COUNTS." Coverage is
exactly countable. There is no proxy.

> **The F2040 warning, taken seriously.** CLAUDE.md records that F2040
> fired at 191 sites and 0 were the defect, and that a lint nobody must
> act on trains the reader to skip the column errors arrive in. A doc
> coverage lint is *at risk of being exactly that*. Part VI states its
> true-positive discipline before a line of it is written: it fires only
> on **exported** symbols, only on the kinds where prose is irreducible,
> and its rate is measured before it ships and again when its doctrine
> moves. A doc lint that fires 600 times on day one is a doc lint that
> gets `# noqa`'d into silence by week two.

## Where the old spec (`spec_doc_system.md`) was right, and where it was wrong

**Right, and kept wholesale:**
- Two audiences, one system: language docs and project docs share a
  format and a resolver. Its fallthrough design (`avra docs closures`
  finds the language feature when no project symbol matches) is exactly
  right and we keep it verbatim.
- Everything is addressable by dot-path.
- Doc comments are a **language feature every project gets**, not
  internal compiler tooling.
- Examples are tests, tests are examples; `--llm` is a first-class
  output format, not an afterthought.
- Its `--validate` instinct. We sharpen it into a gate.

**Wrong, or written before the tree knew better:**

| Old spec | Why it does not survive | What replaces it |
|---|---|---|
| `@param name - description` (JSDoc, restated) | Creates the second copy. The drift problem is *self-inflicted* | Prose only for what the signature cannot say (Part II(a)) |
| Annotation vocabulary hardcoded in a table | Violates THE VOCABULARY SEAM RULE — tags are DATA, five consumers query them | Tag **registry** rows, features contribute (Part V) |
| Doc content lives on nodes / in comments and is re-parsed per surface | Violates "node facts live in side tables keyed by typed ids" | `docs(ws, f) -> DocFacts`, a query family (Part V) |
| Coverage as a report with a percentage and a CI threshold | A number nobody reads. And a threshold means 94% is *fine* forever | Coverage as a diagnostic at the site, ratcheted like idioms |
| `--llm` as one fixed compact format | A fixed size is the wrong knob. My budget varies by two orders of magnitude | `--budget N`, and a **completeness invariant** (Part IV) |
| "Won't the LLM format get stale? It's generated." | Generated ≠ *effective*. Nothing here measures whether it works | The cold-start gate: docs with a pass rate (Part VII) |
| Six layers, listed | A list, not a mechanism. Nothing says what happens when they disagree | One semantic object, N projections; disagreement is impossible by construction |

The largest addition is Part VII. The old spec asks "is it generated?"
The question that matters is **"does an LLM that read only this write
Avra that compiles?"** — and that is a number.

---

# Part III — The paradoxes, collapsed

P6 says a forced trade-off means the model is wrong. Nine, each of which
a normal doc system picks a horn of.

**1. Complete vs. concise. — REVISED, the axis was backwards.**
Every doc system picks: a 400-page reference nobody reads, or a
cheat-sheet that omits what you need.

*The first draft's collapse was:* completeness and resolution are
different axes, so the brief degrades by dropping **detail**, never
**features** — at 800 tokens every feature gets its syntax line.

**That artifact has been measured and it scores 1.23%.** A brief of 29
syntax lines is the closest possible thing to a grammar summary, which is
exactly what arXiv:2409.19151 found contributes almost nothing and what
arXiv:2606.16827 scored against real tasks. The axis was inverted: it
degraded along the dimension that *teaches* and preserved the one that
does not.

*The corrected collapse:* **degrade by COVERAGE OF THE LANGUAGE, not by
resolution of each entry.** At low budget, ship **fewer features with one
complete compiling program each**. At high budget, add features, then
refusals, then prose. The bet — and it is a bet, to be settled by Part
VII's first experiment — is that a model that has read three real Avra
programs transfers to a fourth feature better than one that has read 29
one-liners and no program. Every study in the survey says it will.

The paradox still collapses, just on the other axis: **you were never
choosing between complete and concise, you were choosing between
complete-and-inert and partial-and-generative.** The second one composes;
the first does not.

**2. Written by humans vs. generated by machines.**
Generated docs are accurate and lifeless; written docs are useful and
stale. *Collapse:* **split them by what can be derived.** The signature,
the failure set, the callers, the effects, the examples, the refusals —
all derived, and *unwritable* by hand (there is no place to type them).
The intent, the invariant, the warning — written, and *hash-guarded*
against the derived part it describes. Neither half can rot: one is
regenerated, the other is invalidated.

**3. Docs vs. tests.**
Keeping them in sync is a permanent tax. *Collapse:* **this tree already
solved it and did not notice.** `corpus/<feature>.av` + `.expected` is
77 verified programs, gate-enforced, one per feature. Those ARE the
examples. `avra doc enums --examples` reads `corpus/enums.av`. Zero new
artifacts, zero sync problem, and a doc example that stops working fails
`make gate` — not a doc build, the *actual* gate.

**4. Human-readable vs. machine-readable.**
*Collapse:* P11 — the doc is a value; text and JSON are two renderings of
it, and the value is the artifact. `avra doc --json` and `avra doc` are
`render` called twice. This tree already did exactly this for
diagnostics; we are copying a solved problem.

**5. Accurate vs. current.**
Docs describing code that has moved. *Collapse:* **staleness is a query
diff, not a heuristic.** A written doc records the hash it was authored
against. A comment reformat changes no hash. A changed return type
changes it, and the doc is flagged **at that symbol** with the old shape,
the new shape, and the diff. Not "docs might be stale" — *this* line
described *that* shape and the shape moved.

**And the hash exists — do not invent a second one.** LANE C: `fn
stmt_fingerprint(id: StmtId) -> int` at `core/nodes.av:664`, a method on
`NodeStore`, already read by `core/tests/nodes_test.av`. For a declaration
the route is two steps — `decls.decl(d).root` for the root `StmtId`, then
`store.stmt_fingerprint(root)`. It is **maintained**, which is the
property freshness actually needs: lane C's `once fn` slice folded the
`mut` and `once` marks into it (`restamp(s, tag)`, tags 61 and 62) when
two declarations differing only by a mark hashed alike. A stale hash is
worse than no hash.

**Its caveat splits freshness in two, and the design must say which it
means.** `stmt_fingerprint` hashes the WRITTEN STATEMENT: identical text
in two modules hashes alike, and a declaration whose *meaning* changed
because a type it names changed does not change its own hash. So —
**"the source moved" is the fingerprint; "the meaning moved" is the memo
kernel's dependency edges**, which already exist and are a better reuse
than any second hash. K4 uses the first and is honest about its floor;
the transitive question is a later rung.

**AND THERE ARE TWO ROT MECHANISMS, NOT ONE — LANE B's, and the second
one this design would otherwise have made worse.** A prose entry rots
because *the world moved*: the gate runs it and asks whether it still
earns the quoted refusal. **A `///` rots because its SUBJECT DIED** —
lane D's `@std/toml` `code_at` carried a well-formed, correct-looking doc
on a function left unused after a sweep moved its callers. Nothing about
that doc is *false*; its subject is simply a corpse nobody swept.

Different cause, different check, and the asymmetry is the point:

| what rots | why | the check |
|---|---|---|
| a prose entry | the world moved | run it — does it still earn its refusal (K5) |
| a `///` | its subject died | is anything referencing this symbol (K7) |
| a `///` | **its subject was REPLACED under it** | the fingerprint it was authored against no longer matches (K4) |
| **either** | **it was never true** | run it on day one — K5 again, and this is the case proximity cannot help |

**The third row was found in the audit and it is the one this design
would have rendered beautifully.** `core/text.av:63`: a doc run whose
first line describes `sorted_texts`, four lines below — because a commit
inserted a function *between a doc run and its subject*. **The run was
not orphaned**, which is the shape F0911 catches; it was **ADOPTED BY THE
WRONG SYMBOL**, and no attachment rule can see that, because the
attachment is structurally valid. The doc is well-formed, correctly
extracted, and about a different function.

**K4 is what catches it**, and this is the strongest argument for
freshness that the campaign has produced: the doc records the fingerprint
of the symbol it was **authored for**, and the symbol that adopted it has
a different one. A freshness check written for "the source moved" turns
out to answer "a different subject moved in underneath you" for free —
which no coverage lint, no liveness check and no attachment law can.

**The fourth row is not rot at all, and LANE A supplied it against
themselves.** A ROADMAP entry headed "THE WELL IS DRY FOR LANE A"
asserted the remaining cost was three things and that further rounds
would invent work. **It was false when written** — its reasoning argued
that since LTO measured neutral the cost must be "the bodies, not the
calls", and it was neither; it was the frame the bodies were forced to
build. It stayed false and unchallenged because, in their words, *a
heading like that is a tree telling you a question is closed.* Another
lane read it, believed it, repeated it back, and it cost a day.

Proximity does nothing for a claim that was wrong at birth, and neither
does freshness — there is no earlier version it drifted from. **A verified
corpus is the only one of the three that catches it, and it catches it on
day one**, because an entry that never refused fails `--verify-subset` the
first time it runs. That is the strongest argument for executability over
adjacency, and it came from the author of the artifact it indicts.

**Rendering makes the second case WORSE than leaving it in the source.**
A reader of a generated doc site sees a beautifully extracted atom on a
function nobody calls, describing behaviour nobody can observe — and,
unlike a reader of the file, **cannot see that it has no callers.** A doc
system without a liveness check does not merely fail to catch dead
documentation; it launders it into something more authoritative.

**6. Determinism vs. LLM assistance.**
The owner wants both: a deterministic checker AND regenerated prose when
things drift. *Collapse:* **the compiler never calls a model. It emits
the work order.** `avra doc --stale --json` produces a prompt-shaped
artifact: the symbol, the old prose, the old sig, the new sig, the diff,
the neighbours, the house style rules, the tests that changed. An agent
consumes it and writes the prose. The compiler stays a pure function
(P14 — no runtime, no network, no key), and the LLM is the *driver*, not
a dependency. The work order is the seam, and it is a value.

**7. Language docs vs. project docs.**
*Collapse:* the old spec had this right. One resolver, project symbols
first, language second, and a hint on fallthrough. `@std/*` packages are
"project docs" that happen to ship with the compiler; there is no third
category.

**8. Reference docs vs. task docs.**
Reference is organised by the language's structure. I arrive with a
*task* ("read a file", "spawn a process"). *Collapse:* **the capability
index** — a package declares what it is *for*, not just what it
*exports*, and `avra doc --for "read a file"` routes to `@std/io`. This
is `@std/process`'s manifest idea generalised: capability is already a
declared, compile-time fact in this tree.

**9. ~~Documenting the language vs. documenting the compiler's own
doctrine.~~ CUT BY THE OWNER — kept only as the reasoning, since the
mechanism recurs elsewhere.**
CLAUDE.md is ~500 lines of hard-won law. Some laws have keepers
(`make idioms`, `make vocab`, `make externs`); most are prose that a
future agent may or may not read. *Collapse:* **doctrine is a doc kind
with a keeper column.** `avra doctrine --unenforced` lists every law with
no ratchet, no diagnostic, and no test. The project's own doctrine becomes
a checkable artifact, and "THE EXEMPTION LAW" (a deviation not written at
the site is an unbounded amnesty) gets a surface that can *count*
amnesties.

---

# Part IV — A day in the perfect world

## The first thirty seconds of a cold agent `[v1]`

```
$ avra brief
```

```
Avra 0.1 · language hash 8f3a21c4 · 29 features · 106 diagnostics
Budget: 6000 tokens (default). Complete: 29/29 features present.

── WRITE THIS ─────────────────────────────────────────────────────
let x = 1                    immutable binding
mut y = 2                    mutable binding (writes need `mut`)
fn f(a: int) -> int { a }    last expression is the answer
[f(x) for x in xs]           comprehension — NOT a for+push loop
xs.find(it.id == n)          scan — NOT a flag loop
a ?? b   a?.f   a!           absence: default, reach, force
match e { .A(n) -> n, ... }  every variant, or `rest`

── DO NOT WRITE THIS ──────────────────────────────────────────────
xs.reverse()          no such method       → core's `reversed(xs)`
[1,2].join(",")       F2005, list is int   → map to text first
let xs: List<int>? = []   F2024            → bind the empty at its type
(0..n).any(...)       ranges take no methods → [f(i) for i in 0..n].any
p is .Bind(_)         `is` takes a BARE variant → one-arm match
type Id = int         no aliases           → single-field struct

── 29 FEATURES ────────────────────────────────────────────────────
enums     `enum S { a b(int) }`; `.a` constructs; `match` covers all
...

Next: `avra brief --budget 20000` for examples and refusals.
      `avra doc <symbol>` for one answer. `avra explain F2005` for a code.
```

Two sections before the feature list, and the **second one is the one
that matters**. That is the negative space, generated from a verified
refusal corpus, and no other language's documentation has ever led with
it.

## Asking one question `[v1]`

```
$ avra doc split
@std/text · fn split(s: string, sep: string) -> List<string>

Splits at each occurrence of `sep`.

  ⚠ Stops at the first NUL — this is a C string call. A five-byte
    text containing a NUL splits as its two-byte prefix.
    See: avra doc lang.nul-law

Drops a trailing empty segment, keeps a leading one:
  "a.".split(".")  → ["a"]      ".a".split(".") → ["", "a"]
  "".split(".")    → []
                                    ↑ verified: corpus/strings.av:41

Fails with: nothing (total)
Used by: 34 sites · avra doc split --callers
```

The warning is written prose (irreducible — no signature says it). The
examples are *run*. `Fails with:` is derived from the lowering. `Used by:`
is a query. Only one sentence of that page was typed by a person.

## Asking why, and getting the law `[v1]`

```
$ avra explain F2040
F2040 · type.registry_hole · warning

  LAW: `_ ->` over our own enums is decided by COUNTING THE ANSWERING
  ARMS. One arm answers → a projection, and a catch-all is honest.
  Two or more answer → a REGISTRY, and a catch-all silently forgets
  the next variant.

  Refused:      Accepted:            License:
  match k {     match k {            match k {
    .A -> 1       .A -> 1              .A -> 1
    .B -> 2       .B -> 2              rest -> 0
    _  -> 0       .C -> 0            }
  }             }                    ← `rest` is a SPELLING both
                                       the compiler and the ratchet read

  Doctrine: CLAUDE.md "Rules" · Keeper: F2040 + make idioms I22
  True-positive rate: measured 2026-09-05 — see avra doctrine F2040
```

## The keeper refusing an undocumented export `[v2]`

```
$ avra check packages/std-text
warning[F0910]: `weave` is exported and says nothing
  ┌─ packages/std-text/src/text.av:88
  │
88│ export fn weave(parts: List<string>, sep: string) -> string
  │            ^^^^^ a caller outside this package sees only this line
  │
  = help: the signature already says the names and the types. Write
          only what it cannot: what it answers when `parts` is empty.
  = fix:  insert `/// ` above  (avra doc --fix)
```

It does not ask for `@param`. It asks the *one question the signature
cannot answer* — and it picked that question because it knows `parts` is
a `List` and the empty case is the one that hides (CLAUDE.md's encoding
law, as a doc prompt).

## Staleness as a work order `[v2]`

```
$ avra doc --stale
2 of 690 docs describe a shape that has moved.

  @std/sqlite · fn open(path: string) -> Result<Db, SqlError>
    doc written against sig 3f21ab90 · current sig 9c04de11
    changed: answer  Result<Db, string>  →  Result<Db, SqlError>
    doc says: "...or the message from sqlite"       ← now a typed error

$ avra doc --stale --json > order.json
# → hand to an agent. Contains: symbol, address, old prose, both sigs,
#   the structural diff, the callers that changed, the house style rules,
#   the sibling docs for tone. The compiler wrote no prose.
```

## What changed since I was last here `[v2]`

```
$ avra doc --since 6553ec6
+ @std/sqlite            new package · 84 declarations · avra doc @std/sqlite
~ fn open                answer type changed (see --stale)
+ F2055                  new diagnostic: `once fn` answers a managed value
~ lang.subset            1 entry retired: `?.` on a nullable now calls methods
```

Four lines instead of a re-read. **For an agent resuming work this is the
single highest-leverage surface in the system** and it costs one query diff.

---

# Part V — The canonical model

## The seam: where doc text enters the compiler

Doctrine (`CLAUDE.md`): *node facts live in side tables keyed by typed
ids, never on nodes*, and *NodeStore is parse-owned and never accretes
pass facts*. So:

1. **The lexer becomes lossless about doc runs.** `///` and `//!` stop
   being whitespace. They emit **trivia — a SPAN, and no text**:
   `DocLine { file_level: bool, span: Span }` into a list on `Parsed`. The
   lexer learns no tag vocabulary; it learns one character.
   **Spans, not text, and the reason is a cost the compile path would
   otherwise pay for a feature it never uses:** text would mint ~6900
   string boxes on every parse of every file — on `avra check`, `avra
   build` and every `make gate` — where nothing reads them. The `docs`
   query slices `SourceFile.text` when a page is actually asked for.
   *(Part IX's string-interning ask is withdrawn: there is nothing to
   intern.)*
2. **A new query family, `docs(ws, f: FileId) -> DocFacts`.** It owns the
   attachment (which run belongs to which `DeclId`), the tag parse, and
   its own diagnostics. It is the fourteenth family and it obeys the
   standard pass signature.
3. **Nothing else changes.** `parsed` stays parse-owned. `sig`, `typed`,
   `lowered` never see a doc comment. Doc facts are a *sibling* of
   semantics, not a participant in it — which is precisely why a doc can
   never change what a program means.

```
docs(ws, f: FileId) -> DocFacts     file → docs by DeclId, its voices
                                    depends on: source, parsed, items
```

**THAT `source` DEPENDENCY IS NOT TIDINESS — WITHOUT IT THE CACHE SERVES
STALE PROSE, AND NOTHING COULD EVER CATCH IT.** doc-spine found it:
`parsed` settles on `program_hash` (`workspace.av:319`), a fold of
STRUCTURAL statement fingerprints, and `core/nodes.av:3-5` says outright
that *"reformatting never changes a fingerprint."* So editing a doc
comment re-runs `parsed` but leaves its `changed_at` where it was (early
cutoff, `db.av:154-162`) — and a `docs` cell depending on `parsed` alone
is marked green over prose that has changed (`ask`, `db.av:106-119`). One
line fixes it (`touch(source(ws, f))`) and it carries the law at the site.

**It is invisible today** because `disarmed` (`workspace.av:224`) kills
the verifiers and nothing edits — `workspace.av:64-67` says so itself.
That is *AN ASSUMPTION NOTHING HAS EVER TRIED TO VIOLATE IS NOT A
GUARANTEE*, arriving in the one place where the whole "documentation is a
compile target" claim rests. **D2 ships the two-revision fixture that
makes it go red**, per K0.

**And once fixed, the property is STRONGER than Part II claims:** a doc
edit re-derives the doc **and nothing else** — not `items`, not `sig`,
not `typed`, not `lowered`. Documentation gets red-green incrementality
that is strictly finer than the code's.

**THE LAW IS WIDER THAN THIS FAMILY, AND BOTH LANES SHARPENED IT PAST MY
FRAMING. LANDED IN CLAUDE.md AT `ceacb0d` BY LANE A.**

I said "a query whose input is TEXT rather than STRUCTURE cannot depend
on `parsed`." That is true and it **undersells the defect**, because the
problem is not the consumer's input. **THE HASH DOES NOT COVER THE VALUE
IT SUMMARISES.** `Parsed` is `{ store, stmts, source, voices }` — it
carries the `SourceFile`'s whole TEXT, and the store's side tables carry
every SPAN, which are byte offsets. `program_hash` (`workspace.av:313`)
folds structural statement fingerprints **alone**, exactly as
`core/nodes.av:3-5` intends: *"a node's identity is the hash of its
structure alone: reformatting never changes a fingerprint."* So `settle`
keeps `changed_at` on an unchanged hash **while the value genuinely
changed.**

So the class is not "doc comments are invisible to the cache." It is
**any edit that moves text without changing structure** — a blank line, a
reindent, an ordinary `//` — after which every later span is stale and a
consumer that renders one **points at the wrong place and is certified
fresh doing it.** A doc comment is merely the member that made it
visible.

The member that bites a user is **reformatting**. Reindent a file, rewrap
a line, add a blank: `parsed` re-runs and mints NEW spans, `program_hash`
is unchanged, `changed_at` does not move, and every dependent cell stays
green — **holding diagnostics whose `Loc` is a byte offset into the OLD
text.** The renderer resolves that stale `lo` against the CURRENT
`SourceFile`, and the caret underlines the wrong line. A stale doc is
inert and a reader can tell. **A diagnostic pointing confidently at the
wrong line actively misleads, in the one artifact a user is trusting most
at that moment.**

~~Lane B asked what happens when the file got SHORTER; I READ the code and
answered that `linecol` clamps to the last line and returns a plausible,
wrong column.~~ **TRUE WHEN READ, FALSE WHEN RUN — RETRACTED WITHIN THE
HOUR, AND THE RETRACTION IS THE POINT.** Lane B probed it instead of
taking my read: offset 99 of an 8-byte file did answer `3:94`, so the
reading of `linecol` was right — **but rendering a diagnostic carrying
that span no longer clamps. It traps**: `avra: a span reaches outside its
own text — offset 99 of 8 in t.av`. The guard is
`diagnostics/source.av:36-38` and it landed at **`e0e88c8`** — *"a span
outside its own text is a wreck, not the last line"* — inside the last
twelve commits, **after the tree I had read**. It covers negatives too.

So the out-of-range case **is** written now and is no longer spent as a
normal one; that framing is retired. **This is the second time in two
days that a claim about behaviour was true when read and false when run**
— and both times the standard held: quoting the OUTPUT caught what
quoting the code could not.

**It reshapes the LSP constraint rather than removing it, and makes it
worse to live with.** The cache hole is unchanged — `program_hash` is
still blind to spans, so a green cell can still hand a stale `Loc` to a
renderer over a shortened file. What used to be a misleading caret is now
a **trap**, and in a long-lived editor process a trap is a **crashed
language server** rather than a confusing squiggle. Lane A's per-consumer
cutoff is still the fix and its argument is stronger: the failure moved
from *wrong output* to *the server dies*, which is easier to sell and
harder to tolerate.

**AND MY FIX DOES NOT REACH IT — Lane A, and they are right.**
`touch(source(ws, f))` correctly fixes the `docs` family. It does nothing
for every other consumer of `parsed` that reads a span, **which is most
of them.**

**THE REAL FIX IS NOT ONE HASH, AND THIS IS THE PART TO ARGUE BEFORE
ANYONE BUILDS INCREMENTAL EDITING.** Hashing the text restores soundness
and destroys the property that makes the structural fingerprint worth
having — that reformatting does not re-run typing. Those pull opposite
ways **only while there is ONE cutoff.** Lane A's resolution: **THE
CUTOFF MUST BE PER CONSUMER.** What a dependent actually READ decides
which fingerprint may cut it off — a consumer that read only structure
cuts off on the structural fold; one that read spans or text may not. So
`parsed` owes **two fingerprints rather than one**. Recorded, not built:
incremental editing does not exist yet, and a two-hash kernel today would
be speculation with no consumer to prove it.

Lane B's consumer-side statement of the same law stands as the rule to
write at a site: ***a query whose answer carries SPANS or TEXT cannot
depend on `parsed` alone, because `parsed`'s identity is deliberately
blind to both.*** The blindness is CORRECT for incremental compilation
and wrong for anything that renders source.

Both instances are latent today for the same reason — `disarmed` kills
the verifiers and a one-shot compile never re-edits — so this is a
**design constraint for the LSP and watch surfaces**, not a bug to fix
this week. Its consequence for us is concrete: **whatever key `docs` adds
must be usable by the diagnostics path too**, never a doc-only side
channel.

**AND THE WAY IT WAS FOUND IS THE POINT.** It cannot fail today: compiles
are one-shot, `disarmed` kills the verifiers at revision one, nothing
edits. No test could have caught it and no reading of the kernel had. It
surfaced because an outsider designed a new consumer **against** the
kernel rather than reading it — which is this document's own untested-
instrument law, arriving inside the memo kernel, found by the one method
available. The two-revision fixture ships with `docs` because a keeper
whose failure has never been witnessed is what this campaign has spent
two days finding.

**THREE CONSTRAINTS ON THE FAMILY, and the first is a directive of mine
that was WRONG ON BOTH HORNS.**

- ~~The table goes inside `ws.db`, or `disarmed` needs a fourth line.~~ I
  read `disarmed`'s hand-written list as "every table must be listed" and
  issued a directive on that premise. **Its membership rule is narrower,
  and its own comment says so:** `ws.analyses` is cleared *because
  `Analysis` holds a closure* — `program: fn() -> Program`
  (`analysis.av:18`), the only `fn` field in the struct — while the
  Workspace's **thirteen other** value tables are pure data and none is
  cleared. `DocFacts` is pure data and joins them; the family's *verifier*
  closes over `ws` and is discharged by `ws.db.disarm()` on line one,
  free. **And `ws.db` cannot hold it**: `db.av:14` is explicit — *"Values
  live in the families' own typed tables; the kernel holds only
  bookkeeping"* — so a typed value table there makes the kernel
  language-aware, a worse trade than the one I was avoiding.
  **What D2 adds is the MEMBERSHIP RULE, not an entry**: a comment saying
  this list is not every table but every table whose VALUE holds a closure
  over `ws`, plus the invariant this design owes back — the day `DocFacts`
  gains a lazy field backed by a closure, it joins the list, **and nothing
  but that sentence will say so.** The registry-hole law still applies; it
  applies to the missing *rule*, not to a missing entry.
- **Registered at ordinal 10**, after `Folded` and before `Analysis`,
  because it depends on `parsed` and `items`. `built` (`workspace.av:207`)
  already refuses a botched renumber.
- **A fact every body may read is answered from the DEFINER.** Satisfied
  by one field: `Decl.file` is set at mint from the admitted file
  (`decls.av:336`), so it names the defining file even for a declaration
  reached through a `use`. Lookup is
  `docs(ws, decl_at(ws, d).file).for_decl(d)` — keyed by definer, never by
  asker. **The spec case's second conjunct is the half that matters**: a
  two-file fixture where the symbol is defined in `lib.av` and rendered
  from `main.av` asserts `docs(main).for_decl(d) == null`, so an
  implementation cannot pass by accidentally recording the doc on whoever
  asked.

**AND THE FRESHNESS SPELLING HAD A TYPE ERROR IN IT, plus a trap worth
more than the fix.** `decls.decl(d).root` is an `ExprId?` — *"the
expression a body IS"* — not a `StmtId`; the statement is `Decl.stmt`, so
the spelling is `store.stmt_fingerprint(decls.decl(d).stmt)`. **The trap:
`stmt_fingerprint` must NOT be the `docs` family's settle hash.** It is
precisely the hash that does not move when a comment changes — that is
what makes the stale-doc cell above possible — so using it there would
rebuild the bug it sits beside. **The two hashes answer opposite
questions**, and a design reaching for the nearest available fingerprint
would have closed one hole by reopening the other.

**AND THE PROBES FOUND A LIVE DEFECT IN THE FUNCTION D1 TOUCHES, WHICH
KILLS A SENTENCE THIS DESIGN RESTED ON.** "A comment is whitespace" is
**false today**. `collapse_breaks` seeds the enclosing line's indent from
a byte OFFSET and compares it against a character DISTANCE
(`lexer.av:365` against `:372`), so with a leading comment `raw[0]` is the
Break ending that comment line and the seed becomes **that line's
length**. Reproduced at `6cfdd12`: a continued chain as a file's FIRST
statement parses one way bare and another with a comment above it, and
**the flip falls exactly between a 3-character and a 4-character comment**
against a continuation indent of 4 — predicted from the hypothesis before
being tested, which is what makes it a mechanism rather than a
coincidence. One preceding statement masks it entirely, so the tree is
not currently mis-parsed; the exposure is an entry file whose first
statement is a chain.

**FIXED AND LANDED BY LANE A AT `74501ef`, AND THE UNFALSIFIABLE
QUESTION IS SETTLED.** My lane could not answer whether the tree was
*currently* mis-parsed anywhere — that needs the lock. Lane A held it:
seed fixed, rebuilt, full corpus run, **no golden moved — 1908 tests, 77
programs, eval == native == expected.** Nothing in this tree was parsing
on the defect, exactly as the masking analysis predicted; the exposure was
real and unrealised, one `use` line from firing. The fix carries its
reason at the site — **the seed is a COLUMN, and a file's first statement
stands at column zero;** `span.lo` only reads as a column while the first
token is on line one. The regression pins six prefixes and **was verified
to have teeth** by restoring the old seed and watching it fail by name.

**Keeping it out of D1 was the right call** — a layout change and a lexer
change in one merge leaves neither exonerable if something breaks — What it
changes here is the INVARIANT: not "comments are whitespace, so capture
is free", but **`s.token` stays null → `raw` is byte-identical → every
layout decision, the defective one included, is bit-for-bit unchanged.**

**The hazard that goes first, from LANE A.** The LINE LAW lives in the
lexer, and this change is inside it: breaks are dropped directly inside
`(`/`[` and after a continuing operator. **A comment-only line is a blank
line today, and whatever it becomes, it becomes that everywhere at
once.** If capturing a `///` between a continuing operator and its operand
changes whether a break survives, every multi-line expression in the tree
shifts meaning silently and simultaneously. Four probes, before any design
prose: the comment-only line; a `///` between a continuing operator and
its operand; one between a comma and the next argument inside `(`; one
alone inside `[ … ]`. **One case is eliminated by MEASUREMENT and one only
looks eliminated.** Lane B's count reproduces — zero doc markers inside
`grammar { … }` or `table<Row> { … }` literals — **but the REASON does
not, and the difference is a test.** Only `grammar` lexes its own body:
`opens_grammar` (`lexer.av:122-128`) fires on one word,
`before.text == "grammar"`. **A `table<Row> { … }` body is lexed normally
by the same `scan_step`**, so a `///` inside one WOULD become a doc line
under D1. Zero **by measurement, not by construction** — and an
implementer taking the reason at face value would skip the case that is
actually load-bearing. D1 ships that test.

The attachment law, stated so it does not drift: **a `///` run attaches
to the next declaration that starts after it with no blank line
between.** A `//!` run attaches to the FILE. A run attached to nothing is
`F0911` (a doc comment with nothing to describe) — because a doc comment
that documents nothing is exactly the shape of a doc comment left behind
by a deleted function.

**AND THAT LAW, AS FIRST WRITTEN, WOULD HAVE FIRED F0911 AT 156 SITES OF
WHICH 155 ARE CORRECT DOC COMMENTS.** doc-spine measured it: **145 doc
runs sit on enum VARIANTS and 10 on struct FIELDS** — 6.4% of the tree's
2436 runs — and they cannot attach, because `Variant` (`core/nodes.av:358`)
and `Param` (`core/nodes.av:335`) carry no span and mint no id, and
`DeclKind` (`core/nodes.av:111`) has no member variant. Densest:
`core/nodes.av` (59), `std-sqlite/error.av` (19), `core/ir.av` (19),
`core/types.av` (18).

**That is the F2040 trap for the third time in this campaign**, and this
time it was caught before a line was written. *The collapse:* a run
INSIDE a declaration's span is that declaration's **MEMBER run** — held
under the enclosing `DeclId`, unaddressed, silent. F0911 tree-wide drops
from 156 to **one**, and the one is a real defect: `features/values.av:22`,
a `///` describing `grown_box` stranded above a `use` line, while
`grown_box` (`values.av:34`) is an undocumented export. **True-positive
rate 100%, measured before it ships**, which is what this document's own
F2040 paragraph demands of every lint here.

**Three attachment traps, each found by reading rather than assuming:**
- **The blank-line wording is load-bearing.** Nine doc runs are separated
  from their declaration by a plain `//` line, and **every one is a
  `// LICENSED I<n>:`** — the exemption law's required spelling, which
  must stay at the site. "Immediately preceding line" detaches all nine;
  "no blank line between" keeps both. No ambiguous case exists.
- **`Decl.lo`/`Decl.hi` are ExprId INDICES, not byte offsets**
  (`decls.av:24`, filled by `range_bodies` walking the expression arena).
  Source bytes come from `Decls.decl_span(d)` (`decls.av:276`). A design
  reaching for `Decl.lo` compares a byte offset to an arena index and is
  silently wrong.
- **Attachment excludes `DeclKind.Main`**, whose stmt is `stmts.first()`
  (`decls.av:216`) — so `decl_span(Main)` is the first statement's span,
  usually a `use` line, and a run above it would attach to a synthetic
  `main`.

## The feature format — `docs: string` goes (owner's ruling d)

The presenting fact was that 28 of 28 features fill a `docs: string` and
nothing reads it. **The right response is not to build a reader. It is to
notice what that field is and replace it**, because every measured result
in this document indicts it:

- **It is PROSE**, and retrieval over prose scored 1.23% where programs
  scored 8.06%.
- **It is UNVERIFIED.** Nothing checks that a word of it is true, which
  is how `?.`-cannot-call-a-method survived 8.2 hours and 14 commits.
- **It is ONE BLOB.** Not addressable, so no diagnostic can point into
  it; not divisible, so a budget cannot degrade it by resolution.
- **It restates the `gram`**, which is the second-copy problem this
  campaign exists to refuse — inside the campaign's own presenting fact.

**THE REPLACEMENT: a feature documents itself in the currency it already
uses for everything else — a TABLE OF ROWS, each row a CLAIM and a
PROGRAM, every one compiled and checked.** A feature already declares
`builders`, `diags`, `properties`, `methods` and `types` as tables. Its
documentation becomes one more:

```avra
let shows = table<Show> {
    claim                            | program                                  | answers   | refuses
    "declares a closed set"          | "enum Suit { clubs hearts }"             | ""        | ""
    "a variant constructs by name"   | "Suit.clubs.ordinal"                     | "0"       | ""
    "match must cover every variant" | "match s { .clubs -> 1 }"                | ""        | "F2013"
    "`is` takes a BARE variant"      | "s is .clubs(_)"                         | ""        | "expected BREAK"
}
```

`Show { claim, program, answers, refuses }` — **exactly one of `answers`
and `refuses` is filled**, and that single shape carries both halves of
the documentation this campaign has been treating as two systems:

| what it buys | how |
|---|---|
| **It cannot be wrong** | every row compiles and runs at gate time; a false claim fails the build |
| **It is the shape that teaches** | (caption, minimal program) — the five-shot form, measured at 8.06% against prose's 1.23% |
| **The negative space is not a separate artifact** | a `refuses` row IS a subset entry, per feature, owned by the feature that would falsify it — which is what makes the gate belong to the SLICE AUTHOR |
| **It is addressable** | `lang.feature.enums.show.2`, so a diagnostic can point at one row |
| **It is budgetable** | the brief drops ROWS, weighted by surprise — the degradation axis Part III ¶1 corrected to |
| **Coverage is countable without a proxy** | a feature with no `shows` is undocumented, and that is a fact, not a judgement |
| **It reuses the tree's own seam rule** | rows are DATA and five consumers query them; nothing dispatches |

**Prose does not vanish — it stops being the artifact.** A one-line
`summary: string` survives for the resolver's index and for a human
skimming. Everything that *teaches* is a row. And the ~980 `///` comments
keep their job, which the evidence says is the **targeted-question**
reader (`avra doc split`) and not the cold-start one.

**What this collapses, and it is why the ruling is right rather than
merely ordered:** `lang/subset/*.av`, the feature `docs` string, the
brief's source, and the coverage metric were four artifacts in the first
draft. They are **one table** in this one. The 47 subset entries become
`refuses` rows on the features that own them; doc-subset's four verbs
(`@refuses`/`@compiles`/`@answers`/`@traps`) become columns; and
LAND D's clause law falls out for free, because **a row asserts one
claim** by construction.

**One honest cost, stated before anyone pays it:** a row's program is a
string in a table, which is the escaped-source shape lane B measured at
81% in the compiler's own feature tests and called *worse than nothing*
as teaching material. **The rows must therefore be extracted and rendered
as real source before a reader sees them** — the brief prints programs,
never string literals — and the format needs a spelling that keeps
authoring readable. That is the open question this design owes, and it is
the first thing to prototype.

## The tag registry — data, not dispatch

THE VOCABULARY SEAM RULE decides this in one question: is a tag DATA or
BEHAVIOR? A tag is a name, an arity, the declaration kinds it may attach
to, and how it renders. **Five consumers query it and nothing dispatches
on it.** So: a registry row — but **DRIVER-OWNED, not feature-contributed,
and the first draft had this exactly backwards.**

doc-spine's correction, and it is the sharpest critique the design
received: features contribute `DiagCode` rows because **those codes are
their own laws** — `enums/mod.av:32` registers eight enum laws. **No
feature owns `@warn`.** A `doc_tags: List<DocTag> = []` config field that
28 of 28 features leave empty **is `docs: string` happening a second
time** — this campaign's own presenting fact, reproduced by the campaign,
in the design meant to fix it. So: ship `doc_tags()` beside `pass_codes()`
(`language/codes.av:26`), and add the config field **at the first feature
that actually owns a tag**, not before.

```avra
export type DocTag = {
  name: string,        // "warn", "since", "see", "unit"
  attaches: TagSeat,   // .Decl | .Member | .File  (per the member-run law)
  arity: TagArity,     // .Prose | .Ref | .Word
  summary: string,     // what `avra doc --tags` says about it
}
```

The starting vocabulary is deliberately **tiny**, because every tag is a
thing an author can get wrong:

| tag | on | why it is irreducible |
|---|---|---|
| *(bare prose)* | anything | the meaning the signature cannot carry — **the default and the common case** |
| `@warn` | decl | a cost or policy the caller must weigh — and **only after tiers 1 and 2 below were ruled out** |
| `@see` | any | a cross-reference the type graph cannot derive |
| `@since` | decl | version, when we have versions |
| `@unit` | param/field | seconds vs. milliseconds — the classic irreducible fact |
| `@example` | decl | names a corpus program; **never inline code** |

**`@warn` carries a test, not a category — LANE B's, earned in
`@std/process`, where the cases split THREE ways and the middle tier is
the one a doc system forgets:**

1. **UNSPELLABLE** — best, and where most of `@std/process` landed. No
   verb takes a command string, so there is no shell to inject. The
   hazard has no spelling, so it needs no warning and no doc atom.
2. **A REFUSAL WITH A VOICE** — the shape is legitimate, one use of it is
   not. `word` refuses a leading dash; `F4611` refuses `after_options` on
   a tool declaring no terminator; `F4608` catches a hole inside
   `cmd(sh, ["-c", …])`. The knowledge lives in the compiler and speaks
   **at the moment of the mistake**, which beats a doc comment nobody is
   reading at that moment.
3. **A DOC WARNING** — last resort. In `@std/process` this tier is nearly
   *empty*, precisely because the first two absorbed the cases. What
   remains is not hazard but POLICY: that a child's PATH is the invoker's
   with relative entries stripped, that `max_capture: 0` lifts the cap.

**THE TEST: if a warning could have been a refusal, it is a bug in the
library, not a doc to render.** A `@warn` that could have been an F-code
is the doc-system equivalent of a licensed idiom with a false reason — and
its presence, correctly used, becomes *evidence that someone considered
tiers 1 and 2 and ruled them out*.

Not present, and each absence is a decision: `@param` (derived),
`@returns` (derived), `@throws` (derived from the lowering), `@type`
(derived), `@deprecated` (that is a diagnostic, not a tag).

## The doc atom, and its address

Everything is addressable, everything is citable, every diagnostic can
point at one:

```
lang.feature.enums                 a feature
lang.feature.enums.gram            its grammar fragment
lang.diag.F2040                    a diagnostic's law
lang.diag.F2040.counterexample     the program that produces it
lang.subset.ranges-take-no-methods a refusal in the negative space
lang.doctrine.evidence-law         a CLAUDE.md law + its keeper
std.text.split                     a symbol
std.text.split.warn.0              one warning on it
std.text.split.example.1           one verified example
pkg.myapp.auth.create_token        a user's symbol — same space
```

`avra doc <address>` resolves any of these. Resolution order is the old
spec's, unchanged: project symbol → language feature → symbol/keyword →
type → diagnostic code → capability → fuzzy.

## The negative space, as a first-class artifact

"The subset today" becomes `lang/subset/*.av` — one file per entry:

```avra
//! A RANGE TAKES NO METHODS.
//! @refuses: expected `)` to close the group
//! @instead: [f(i) for i in 0..n].any(...)
let bad = (0..n).any(it == 2)
```

**`@refuses:` ALONE IS INSUFFICIENT — measured, not guessed.** About a
FIFTH of the 47 entries record something that *compiles*: `\u` is not an
escape, `split` drops a trailing empty segment, a payload-free enum
compares by variant, the interpreter traps at 400 nested calls. A refusal
tag cannot express any of those. So the corpus carries four verbs, not
one — **`@refuses:`, `@compiles:`, `@answers:`, `@traps:`** — and that is
what lets the verifier catch drift in *behaviour* rather than only
staleness in *refusals*. (doc-subset, D5.)

**Three of the 47 cannot be a loose file, and they are the ones that
matter most.** LAND D probed this today and hit the wall: `export use`
answers `F3015` "this file is not in a package — `use` needs a root" and
**never reaches the re-export law the entry exists to pin**; `const` in a
module file needs a module *and* an entry before `F0902` means anything;
the NUL entry is single-file only if you reach the codepoint through
`extern fn avra_str_from_codepoint` rather than `@std/text`. So the format
is one program per entry for 44, and a **fixture directory** — a minimal
package with a manifest — for the rest. That case is built in from the
start, not deferred, for the reason LAND D gives: those are precisely the
entries nobody can cheaply check by hand, **which makes them the entries
most likely to rot — the problem concentrated in exactly what a naive
instrument would skip.**

**THIS IS BUILT AND IT RUNS IN 2.26 SECONDS.** 60 corpus programs and a
30-line driver, `verified 60, failed 0` — gate-leg territory, needing no
compiler change at all, which confirms the ladder's claim that **K5 can
land before D1.** Its failure is witnessed against four fixtures running
the REAL driver (K0): it names STALE / DRIFTED / MOVED / BROKE and exits
1. Had it existed, all three stale entries below would have been caught
the day the typer changed.

`avra doc --verify-subset` compiles all 47, asserts each refuses with
**that wording**, and fails the gate on any that now compiles — because a
refusal that has become legal is a doc that is actively lying to me.

**THE GATE BELONGS TO THE SLICE AUTHOR, NOT THE DOC AUTHOR — and that is
a larger claim than freshness.** doc-subset simulated the bitwise slice's
landing faithfully (each corpus file keeps its recorded `@refuses:` line
while its program becomes one the compiler accepts) and ran the real
driver:

```
STALE   bitwise-and — now COMPILES; the entry is lying
STALE   bitwise-not — now COMPILES; the entry is lying
...
verified 0, failed 6            exit 1
```

**It fires in the merge that invalidates the entry, names the six files
to delete, and reaches someone who has never heard of "The subset
today."** The status quo is precisely the mechanism that produced all
three of Part I's stale entries: the slice merges green, the entry keeps
lying, and the next author writes the workaround it recommends. **Nobody
is careless at any step** — which is the point, and why a keeper beats a
discipline.

The interval it closes is measured, not asserted: the F0102 rot window
was **8.2 hours and 14 commits**, on a day four lanes were actively
watching the tree.

**THREE DESIGN CONSTRAINTS THE PROBES PAID FOR, each earned rather than
reasoned:**

1. **ASSERT WORDING AND BEHAVIOUR, NEVER AN F-CODE.** F0102 did not
   vanish when the `?.`-method rule retired — **it exists and always
   has**, registered at `codes.av:19` as `"build.failed" | "a builder
   rejected its captures"`. The retired rule was never a registry row at
   all; it was a hand-written `.Err(…)` string inside a builder, which
   merely *surfaced* as F0102 because that is the generic code for any
   builder rejection. **A verifier asserting "F0102 still exists" would
   have passed that entry for all 8.2 hours.** Codes are shared and
   outlive their rules.
2. **ONE CORPUS FILE ASSERTS ONE CLAUSE.** Earned four separate times —
   S2 lost 1 of 3 clauses, S3 1 of 2, C4 1 of 3, and `BYTES_SHAPE.md` 2
   of 3. **A multi-clause entry rots clause by clause, and a file
   asserting the surviving clause passes while the dead one keeps
   lying.**
3. **A KEEPER IS KEYED TO THE CLAIM, NOT TO THE FILE.** Lane C swept all
   three ROADMAP entries asserting `ptr` was receive-only — correctly and
   completely for the ROADMAP. The same claim was standing in a fourth
   place, `docs/2026_09_05_BYTES_SHAPE.md:239-241`, **with a decision
   hanging off it**: that page calls `SQLITE_TRANSIENT`'s `(void*)-1`
   *unspellable* and concludes *"the driver must not offer a bind at
   all."* Probed at `91b6b61`: `avra_ptr_at(0 - 1)` compiles, exit 0.
   **A stale sentence was telling a live lane to withhold a feature.** A
   sweep keyed to a file leaves the claim standing elsewhere; a keeper
   keyed to the claim finds all four.

**AND THE STRONGEST ARGUMENT FOR THE CORPUS TURNED OUT NOT TO BE
STALENESS.** doc-subset's finding, and it reframes the whole rung: **a
malformed probe reads exactly like a stale entry.** Their first `table`
probe used the brace-map shape and produced F3000 where the entry records
F0100 — which looks precisely like drift and was simply a bad probe. Four
results surprised them; three digs changed the verdict, and **two came
back from "stale" to "holds".** So a hand-maintained subset section has a
second failure mode nobody had named: it is re-improvised by every prober,
and a prober's mistake is indistinguishable from the document's rot. A
stored program written once beside its claim removes that permanently —
which means the corpus is not merely a freshness gate, **it is the thing
that makes a refusal claim falsifiable at all.** The
hand-maintained section of CLAUDE.md then *generates from* this
directory, and the day an entry starts compiling, the gate says so
instead of an agent discovering it six weeks later.

> This directly discharges CLAUDE.md's own standard for those entries —
> *"Every entry was probed with `./avra check` on a scratch file and
> quotes the refusal, so a re-probe is cheap"* — by making the re-probe
> automatic, and by making a probe result **name the base that answered
> it** (the version-attribution law) without anyone having to remember.
> An entry the gate cannot run records its base anyway — LAND D lost time
> today to a lane's refusal they could not reproduce, where both parties
> were right because one binary predated its own checkout by twelve
> minutes and the grammar had gained a marker in between.

### The second kind of negative space: what the library permits and you must not

The subset corpus covers what the *language* refuses. There is a second
category the reference form cannot express at all — **what compiles, runs,
reports success, and is wrong** — and `@std/sqlite`'s traps document is
this tree's exemplar. Its sharpest entry, verified by the SQLITE lane on
main at `bd5c024`:

> The door refusing an empty database path was built from `==`, a C string
> call that stops at the first NUL. The path `"\0x"` measures `.length` 2
> in Avra and reaches SQLite as **the empty string** — which opens a
> private temporary database deleted at close, so **every write succeeds
> and the data is silently gone.** The guard was not weak. It was reading
> a different string than the callee.

**And the half that belongs in front of an LLM author is the near-miss.**
`":memory:\0x"` was refused *before* the fix — **by accident**, because
`==` truncated it into a match. Right answer, wrong reason. A test suite
written that morning goes green and ships the door broken.

A reference manual has no place to put that. A signature cannot carry it.
It is not a warning about a parameter; it is a **fact about the boundary
between two things that disagree about what a string is** — and it is
exactly the class of knowledge an author with a strong prior from ten
other languages will violate confidently. Recording it as a near-miss
rather than counting it as a pass is what separates a red team from a
demo, and the doc system's job is to make sure that distinction survives
into what I read.

## The projections

One value, N renderings. Adding a renderer touches nothing else.

| projection | command | consumer |
|---|---|---|
| terminal | `avra doc X` | human, and agent reading a terminal |
| brief | `avra brief --budget N` | **agent cold start** |
| structured | `avra doc --json` | tooling, LSP, an agent asking its own question |
| work order | `avra doc --stale --json` | an agent regenerating prose |
| diff | `avra doc --since <rev>` | an agent resuming |
| markdown | `avra doc --md` | a repo's own README/docs dir |
| site | `avra doc --site` `[v3]` | the world (explicitly out of scope now) |
| tools | `avra doc --tools` `[v3]` | MCP / agent tool definitions — P12's endgame |

---

# Part VI — The keepers: six deterministic checks

`make gate` grows a leg: `make docs`. Six checks, all deterministic, all
riding machinery that exists. This is the "deterministically checked
through an avra cli command" the owner asked for, spelled out.

**K1 · COVERAGE.** Every exported symbol has a doc. Diagnostic-grade
(`F0910`), at the site, ratcheted like idioms: a baseline that **lists
sites, never counts** (DOGFOODING's first law — a count-based baseline
has a hole under it), and no tool path may add to it. Debt starts at
200 (890 − 690) and only falls. Two honest exits: write the line, or
`// LICENSED D1: reason` at the site (THE EXEMPTION LAW).

**K2 · STRUCTURE.** A doc says the right *kind* of thing for its
declaration kind. An `enum`'s doc that does not mention what closes the
set, a fallible fn whose doc never mentions the failure — these are
checkable without reading English, because the compiler knows the shape.
*Held to a measured true-positive rate before it ships.*

**K3 · EXAMPLES RUN — REVISED, and the revision avoids Rust's decade.**
Every `@example` names a corpus program that exists and passes. Inline
outputs in a doc are **extracted INTO corpus programs and never executed
in place.** The first draft said "every inline output is executed and
compared," which is Rust's doctest architecture verbatim — a per-snippet
compile path they ran for ten years (44 doctests, 22 of 26 seconds) and
rearchitected in the 2024 edition, and whose Python cousin is the
most-complained-about test tool in that language. **A doc example that
breaks fails `make gate`, not a doc build** — because it IS a corpus
program, which is the whole point of paradox 3.

**K4 · FRESHNESS.** Every written doc carries the `stmt_fingerprint` it
was authored against (`core/nodes.av:664`); a mismatch is `F0912`. Not a
warning about *possible* staleness — a statement that *this* prose
described *that* shape. **Its floor is stated, not hidden:** it catches
"the source moved" and not "the meaning moved" (Part III ¶5), and the
mitigation for the gap is K3.

**K5 · THE REFUSALS STILL REFUSE.** `lang/subset/*.av` compiled, each
asserting its recorded refusal and its wording. An entry that now
compiles fails the gate with "this is no longer true — delete the entry."

**K6 · THE BRIEF'S COVERAGE IS REPORTED — REVISED, demoted from a gate.**
The first draft gated on "the brief mentions every feature, every
diagnostic family, every subset entry." **That is the F2040 trap in this
document's own words:** a set difference over *mentions* is a proxy, and
the doctrine is "the reader can write this feature correctly." It would
go green on a brief that teaches nothing — precisely the 1.23% artifact —
and it does worse than fail silently: it **forbids the correct design**,
because token economics and the evidence both argue for weighting the
brief by SURPRISE, spending nothing on `let x = 1` and everything on the
six things that will be written wrong. Uniform coverage as a gate
condition outlaws that.

So: **gate on the pass rate (K8), report the set difference.** K6 becomes
a completeness *report* until Part VII can say whether coverage correlates
with correctness. If it does, promote it back and say so.

**K8 · THE COLD-START PASS RATE DOES NOT REGRESS.** The ratchet that K6
gave up. Part VII is the mechanism; it lives in `make coldstart`, outside
`make gate`, because it is non-deterministic and costs tokens. **It is the
only keeper here that measures the doctrine rather than a proxy for it.**

**K7 · THE SUBJECT IS ALIVE.** A doc atom whose subject nothing
references is `F0913`. The caller set is a query we are already running —
`avra doc split --callers` in Part IV is the same data — so this check is
free at the point of rendering. For a private fn, zero references is the
defect.

**FOR AN EXPORTED SYMBOL, ZERO IN-TREE CALLERS IS THE NORMAL CASE, AND A
NAIVE COUNT WOULD RENDER EVERY STD PACKAGE AS A GRAVEYARD** — LANE B, from
the sweep: `@std/json`'s `pretty` had no callers until the corpus used
one, and half of `@std/path`'s surface has one or none. A library's public
surface is answerable to its TESTS, not to its callers. So the check
splits by seat: a private fn with no references is `F0913`; an exported
symbol is asked instead whether a **spec case or a corpus program**
exercises it, and the page counts callers **across packages** and says
which currency it is quoting. Getting this wrong would have made K7 a lint
that fires on the entire standard library and is right about none of it —
this document's own F2040 trap, in the keeper added to catch a different
one. (LANE B named both the mechanism and the false positive.)

**AND K7 IS NOT A NICETY BOLTED ONTO A DOC SYSTEM** — LANE B again, and it
is the better framing. This tree has now found the same shape four times
in two days: idiom numbers colliding, I3 ratcheted with no registry entry,
`disarmed`'s hand-kept list, `@std/json`'s registry hole. The common
factor is not carelessness; it is that **ENFORCEMENT AND KNOWLEDGE LIVED
IN DIFFERENT PLACES** — a rule the tool cannot see, a registry the
compiler cannot check, a doc the renderer cannot verify. K7 moves "is this
symbol real" out of a reader's head and into the build. It is the law the
tree already applies to its enums, finally applied to its prose.

Plus the meta-keeper, and it is the one this tree's doctrine demands
loudest:

**K0 · THE KEEPERS THEMSELVES ARE TESTED BY BREAKING THEM.**
CLAUDE.md: *"A KEEPER THAT HAS ONLY EVER GUARDED A STATIC ENUM IS
UNTESTED"* and *"A green check whose failure has never been witnessed is
an untested instrument."* Every one of K1–K6 ships with a fixture that
**makes it fail**: an export with its doc deleted, an example with its
output corrupted, a sig deliberately moved, a subset entry that now
compiles. And — CLAUDE.md's *"A TEST WITH ITS OWN COPY OF THE LOGIC TESTS
THE COPY"* — those fixtures run the **real** checker, never an inline
duplicate of it. That law was earned in this tree, by the externs keeper,
three weeks ago. We do not get to re-earn it.

---

# Part VII — The cold-start gate: docs with a pass rate

~~This is the part I have not seen anywhere.~~ **IT WAS RUN THREE MONTHS
AGO AND I SHOULD HAVE KNOWN.** Giagnorio, Martín-López and Bavota, *No
Resource, No Benchmarks, No Problem?* (arXiv:2606.16827, June 2026), took
Gleam and MoonBit — both stabilised after training cutoffs — and measured
exactly this. The novelty claim is withdrawn. What survives is better:
**we can run it continuously, on our own language, as a ratchet**, which
is the thing nobody has built.

Every doc system in history is evaluated by "does it exist" and "does it
render." **The only question that matters for P1 is: does an author who
read only this write code that compiles?** That is not a feeling. It is
an experiment, it has been run, and its published numbers tell us what to
expect before we spend a token.

**THE PREDICTED FIRST NUMBER, WRITTEN DOWN BEFORE BUILDING — because a
gate whose first result reads as catastrophe gets abandoned.** Published
McEval-Hard pass@1 on a genuinely unseen language: zero-shot 0–1%;
retrieval over official *documentation* 1.23%; five-shot *code examples*
8.06%; full pre-train plus instruction transfer 26–33%. Our tasks will be
easier than McEval-Hard and our brief richer than a doc dump, so I predict
a **first run in the 10–25% band and I will not treat a 4/40 as failure.**
The ratchet is set AFTER the first measurement, never before it. Anyone
who quotes the mock-up below as a target is quoting an illustration.

```
$ make coldstart
Cold-start gate · brief @ 6000 tokens · 40 tasks · language hash 8f3a21c4

  compiled clean           7/40   (baseline 6 — ratchet holds)
  compiled with warnings   4/40
  refused                 29/40

  Refusals, grouped by what the brief failed to say:
   14 ×  syntax               — the published failure mode: 66-90% of
                                no-resource errors are syntactic
    6 ×  used `xs.sort()`     — no method, and not in the negative space
    3 ×  `match` over `K?`    — subset entry exists, unreachable at
                                this budget

  → the number is low BY CONSTRUCTION. It is a ratchet, not a score.
```

**The mechanism.** A fixed suite of tasks in `tasks/` ("write a fn that
counts words in a file", "define an enum and exhaustively match it").
A harness hands a model *only* the generated brief — no repository, no
CLAUDE.md, no examples beyond what the brief itself contains — and
compiles what comes back. The pass rate is a ratcheted number.

**Why this is the keystone and not a nice-to-have:**

- It makes documentation quality **empirical**. Every argument about what
  to include stops being taste and becomes a measurement.
- It tells us **what to spend the budget on**. Every failure names the
  fact whose absence caused it. The brief's contents are then *derived
  from evidence*, not from an author's guess about what matters.
- It is the **only** honest test of P1, which is the language's own
  primary success metric. We assert "correct on first generation" as our
  north star and currently measure it nowhere.
- **It catches language regressions no other gate can see.** A change
  that makes Avra harder to write correctly passes every test in this
  repo today. It would fail this one.
- It is the direct answer to CLAUDE.md's *"AN ASSUMPTION NOTHING HAS EVER
  TRIED TO VIOLATE IS NOT A GUARANTEE"* and its companion, *"THE AGREEING
  ENGINES"*: our corpus `.expected` files are written by the same author
  from the same understanding, so they join the consensus rather than
  breaking it. **A fresh model with no context is an oracle that is not
  part of our consensus.** That is the property nothing else in this tree
  has.

**Honest constraints, stated up front.** It is non-deterministic (mitigate:
N samples, report a rate with a band, ratchet on the lower bound). It
costs tokens (mitigate: it is a nightly / pre-merge gate, not a
per-commit one, and a small model is the *right* subject — the harder the
subject, the more the docs must carry). It needs a network (mitigate: it
is the ONLY part of this system that does, it lives outside `make gate`
proper as `make coldstart`, and the compiler itself never calls a model).

---

# Part VIII — Working backwards: the ladder

Each rung is independently valuable and shippable. Nothing below is
speculative infrastructure; every rung ends with a surface somebody uses.

### v0 — THE SPRING (this exists, today, unread)
690 doc comments, 28 feature `docs` strings, 77 corpus programs, 106
diagnostic rows, 47 subset entries. **Zero readers.**

### v1 — THE SPINE AND THE FIRST ANSWER
- **D0 — SHIPPABLE TODAY, AND THE LADDER DID NOT HAVE IT.** `avra doc
  <feature>` / `<F-code>` / `<method>`, reading the `docs: string` field
  that 28 of 28 features already fill. **One new file
  (`cli/src/commands/doc.av`) plus one line in `main.av`.** `avra()` is a
  `once fn` (`language/mod.av:171`) already carrying `features` with
  `.name`/`.docs`/`.gram`, plus `rows.codes` and `rows.methods`; and
  `render_grammar` (`grammar/render.av:8`) renders a feature's OWN
  fragment, not only the merged grammar. No workspace, no `Program`, no
  `phased` — it answers as fast as `avra grammar`. It also makes `doc.av`
  exist, so D3 becomes an arm rather than a file. **The loaded spring
  fires with no compiler change at all.**
- **D1** Lexer emits doc trivia (lossless; `///` and `//!`, spans only).
  *Smallest possible compiler change. D2/D3 block on it; D0 and D5 do
  not.*
- **D2** `docs(ws, f) -> DocFacts` query family: attachment, tag parse,
  its own voices. Tag registry with the six starting rows.
- **D3** `avra doc <address>` — the resolver and the terminal projection,
  over symbols, features (reading `.docs` at last), and diagnostics.
- **D4** `avra brief` at a default budget — **assembled from PROGRAMS
  first, prose second, in this order: the 638 `@std` spec cases (caption
  + minimal program, already the five-shot shape), then `corpus/` BODIES
  with their harness tails dropped, then prose.** *Twice revised: the
  first draft assembled three prose sources and zero programs (the 1.23%
  artifact); the second reached for `corpus/`, whose tails are assertion
  harness rather than idiom (LANE B).* The extractor's one real cost is
  that spec cases lean on file-local fixtures (`fresh`, `message`), so it
  must pull or inline them.
- **D5** `lang/subset/*.av` — "The subset today" migrated to verified
  programs, with **K5** in the gate. *Pays for itself the day it lands and
  **does not need D1**, so it can start now.*

**GATE v1 — REVISED, and it moved up from v3.** A crude, hand-run
cold-start measurement: 10 tasks, one budget, the number written down. It
needs **no compiler change at all** — `corpus/` and CLAUDE.md exist today.
The survey's G5 is why it moved: Rust left `missing_docs` allow-by-default
*because it is noisy*; Elm made docs mandatory and got `{-| The name. -}`,
a second copy of the exposing list, and a decade of false MISSING
DOCUMENTATION bugs. **Do not build a coverage ratchet before you can
measure whether coverage buys anything.**

### v2 — THE KEEPERS
- **D6** `F0910` coverage diagnostic + the site-listing ratchet (K1).
  **GATED on v1's measurement showing that prose buys correctness.** If it
  does not, D6 is deferred and the budget goes to examples instead. This
  is the one rung the evidence may delete.
- **D7** Freshness over `stmt_fingerprint` + `F0912` (K4); `avra doc
  --stale`. *No new hash — the door exists (LANE C).*
- **D8** Work orders: `--stale --json` and the house-style bundle (¶6).
- **D9** Example verification (K3) — corpus wiring + inline outputs.
- **D10** `avra doc --json`, `--since`, `--md`.
- **D11** `make docs` in `make gate`, with K0 failure fixtures for each.

**GATE v2:** doc debt is a ratchet at zero-or-falling; no doc in the tree
describes a sig that has moved.

### v3 — THE SUBSTRATE
- **D12** `avra brief --budget N`, degrading by COVERAGE (Part III ¶1),
  with K6 as a *report*. The first experiment it runs is coverage-vs-
  resolution, because that decides the whole shape of `brief`.
- **D13** **The cold-start gate as a ratchet** (Part VII, K8). *The
  keystone — the measurement moved to v1; this is making it continuous.*
- **D13b** Position as a contract: head/tail placement measured, not left
  to chance. Lost-in-the-middle is real and K6's uniformity ignored it.
- **D15** Capability index + `avra doc --for "<task>"`.
- **D16** `@std/doc` — the doc model as an Avra package, so a projection
  is a library, not a compiler change.
- **D17** `--site`, `--tools`. **Explicitly deferred by the owner. Not
  before v3, and cheap when the model is a value.**

---

# Part IX — The asks

**From the language (sugar backlog, per "Dogfooding is design"):**
- **Doc comments as syntax.** The `///` attachment law needs to be
  *stated* in the language, not implied by a lexer. Wanting site: D1.
- **`@example` referencing a corpus program** needs a path type the
  compiler can verify at check time. Wanting site: D9.
- **String interning for doc text.** 690 doc strings will be minted per
  parse; they are immortal and identical across queries. Wanting site: D2.
- ~~A stable content hash exposed as a value.~~ **WITHDRAWN — the door
  exists.** `NodeStore.stmt_fingerprint` (`core/nodes.av:664`), readable
  from Avra today, maintained as the language grows. Answered by LANE C
  within an hour of the ask. What remains is the *transitive* question
  (Part III ¶5), and its answer is the memo kernel's edges, not a hash.

**From the campaign (coordination):**
- ~~D1 needs the syntax-change protocol and every lane must bootstrap.~~
  **WITHDRAWN — I over-constrained five lanes.** The protocol exists for
  changes that make existing files unparseable by the standing binary.
  **D1 adds no syntax**: `///` already lexes today (as whitespace), every
  file stays parseable, nothing needs rewriting, and no lane needs `make
  bootstrap` on account of it. What D1 *does* need is a quiet window in
  `grammar/lexer.av`, which is a merge-conflict concern and not a
  bootstrap one — and lane A owns that file and has the bitwise slice in
  it first. The correction was sent to every lane I misinformed.
- **Serial gates.** The machine has panicked twice under this tree. Doc
  lanes do research and design in parallel freely (read-only), and
  **queue** for any `make gate` / whole-package run, always under
  `sh tools/watch.sh 4000`.
- **A doc lane never merges a doctrine change to CLAUDE.md without the
  owner's word.** We *read* the doctrine; only the owner writes it.

**From the owner:**
- Ratification of Part II(a) — **no `@param`**. It is the load-bearing
  decision and it contradicts the JSDoc instinct that prompted this work.
  Everything about achievable coverage rests on it.
- A budget decision on Part VII: the cold-start gate spends tokens.
- Confirmation that `--site` stays deferred through v2.

---

# Part X — Honest limits

- **A doc system cannot make a bad API good.** `@std/sqlite`'s
  `open(path)` was ambiguous between a filename and a URI, and the fix was
  TWO VERBS (the two-hats law) — **landed on main at `f88d0ce`, verified
  by the SQLITE lane at `bd5c024`**: `open_uri()` and the `uri: bool =
  false` seat in `packages/std-sqlite/src/open.av`. Not a warning tag. A `@warn` that papers over a design
  flaw is this tree's own recorded anti-pattern: *"the unsafe shape is
  unspellable rather than merely documented, which is what the first
  answer — 'the type cannot prevent it, so the doc says so' — would have
  settled for."* **When a doc lane wants to write a warning, its first
  move is to ask whether the shape can be made unspellable instead.**
- **Coverage is not quality.** 100% coverage of "returns the result" is
  worth nothing. K2 attacks this and will only partly succeed. The
  cold-start gate is the real answer and it is v3.
- **The cold-start gate is non-deterministic and costs money.** It lives
  outside `make gate`. Its number is a band, not a point.
- **Staleness detection has a false-negative floor.** A sig that is
  unchanged while the *meaning* moved (a fn that silently starts trimming
  its input) is invisible to K4. The mitigation is K3 — examples run —
  and it is partial.
- **The tag vocabulary will be under pressure to grow.** Every tag is a
  thing an author can get wrong and a consumer must handle. Growth is a
  registry row and a rationale, and the answer to most requests is
  "write prose."
- **`--json` is a public contract the moment an agent parses it.** P9: it
  is versioned from day one, or it is not shipped.
- **"Docs that cannot be wrong" was over-claimed and is withdrawn.**
  Unison went furthest anyone has — docs are values of type `Doc`,
  snippets typecheck, transclusions are hash-linked — and **its prose is
  still unguarded.** Content-addressing buys nothing here that a memoized
  query engine does not already have. The honest form: **the derived half
  cannot be stale; the written half knows what shape it described.**
- **Doc excellence is not a growth mechanism, and we should not pretend
  it is.** Unison built what its own users call the best documentation
  experience in any language ecosystem, and it did not move adoption. For
  Avra the argument is different and has to be *made* rather than assumed:
  the author is the audience, the audience is measurable, and P1 makes
  first-generation correctness the success metric rather than a
  by-product. That is a claim about our situation, not a general law about
  documentation.

---

# Part XI — Slogans

- **The compiler already knows. Build the thing that asks it.**
- **Documentation is a compile target.** Same engine, same fact tables,
  same incrementality. The binary and the docs are siblings.
- **The signature is data. Documentation is only what the signature
  cannot say.**
- **A doc entry is a diagnostic that has not fired yet.**
- **The undocumented is a diagnostic.**
- **The negative space is the documentation.** Julia shipped it as prose
  in 2013 and Elixir and Rust each ship a version; **what is ours is that
  it COMPILES** — a refusal that has become legal fails the build.
- **A refusal that has become legal is a doc that is lying.**
- **A claim that was never true is caught on day one, or never.**
- **The compiler never calls a model. It writes the work order.** Three
  papers measure documentation; **none of them close the loop.** That is
  the second thing here nobody has built.
- **Examples teach; prose does not.** Measured three times, in three
  domains. Spend the budget accordingly.
- **Degrade by coverage, not by resolution.** Three real programs beat
  twenty-nine syntax lines.
- **Docs with a pass rate, or docs with an opinion.**
- **Write the predicted number down before you build the gate.**
- **A green check whose failure has never been witnessed is an untested
  instrument** — and that includes every keeper in this document.
