# Documentation systems — prior-art survey, and where the vision is wrong

Research for the Avra documentation campaign. Pressure-tests
`docs/2026_09_05_DOCUMENTATION_VISION.md`.

Every claim that is a *fact about another system* carries a URL. Every claim
that is a *design opinion* is marked as such. Every number is labelled with
where it came from and how confident I am in it. Nothing here was measured in
this tree; this lane wrote no code and ran no build.

Organised as: **§0** the verdict, **§1** the confidence ledger, **§A** doc
systems that generate from the compiler, **§B** Unison and the literate
tradition, **§C** doc-example verification, **§D** the LLM cold-start
frontier, **§E** the keystone question, **§F** the negative space, **§G**
where the vision is wrong.

---

## §0 The verdict, in five findings

**F1 — THE KEYSTONE EXPERIMENT EXISTS, IT WAS RUN THIS YEAR, AND IT SAYS
DOCUMENTATION BARELY WORKS.** Part VII claims "this is the part I have not
seen anywhere." It has been seen. Giagnorio, Martin-Lopez and Bavota,
*No Resource, No Benchmarks, No Problem?* (arXiv:2606.16827, June 2026), took
two languages released after model training cutoffs — **Gleam** and
**MoonBit** — and measured exactly the vision's question. On the hard
benchmark, zero-shot pass@1 was **0–1%**. Retrieval over the *language
documentation* moved Gleam to **1.23%**. Five-shot *code examples* moved
MoonBit to **8.06%**. Pre-training plus instruction transfer reached
**26.08% / 32.60%**. And the metric the vision proposes — does it compile —
is the one the authors emphasise: **syntactic errors were 66–90% of
no-resource failures, versus under 10% for established languages.**
<https://arxiv.org/html/2606.16827v1>

**F2 — THREE INDEPENDENT STUDIES, THREE DOMAINS, ONE CONCLUSION: EXAMPLES
TEACH, PROSE DOES NOT.** This is the single most important finding in the
survey and it is aimed directly at the brief's design.

| study | domain | finding |
|---|---|---|
| arXiv:2606.16827 | Gleam / MoonBit code gen | few-shot examples cut syntactic errors **15.36%**; doc retrieval **8.94%** |
| arXiv:2409.19151 | Kalamang translation from a grammar book | "almost all improvements stem from the book's **parallel examples** rather than its **grammatical explanations**" |
| arXiv:2503.15231 | 1,017 APIs across 4 Python libraries | deleting **example code** collapses accuracy 0.66–0.82 → **0.22–0.39**; deleting the **description** is near-neutral; deleting the **parameter list** *slightly improves* it |

<https://arxiv.org/abs/2409.19151> · <https://arxiv.org/html/2503.15231v1>

The Kalamang authors state it flatly: *"we find no evidence that long-context
LLMs can make effective use of grammatical explanations for XLR translation."*
A grammar book is the natural-language analogue of a language reference
manual. The vision's `avra brief` is a grammar book.

**F3 — PART II(a) IS RIGHT AND HAS BETTER EVIDENCE THAN IT CITES, BUT THE
SAME EVIDENCE UNDERCUTS THE "LOADED SPRING".** arXiv:2503.15231's ablation
found that deleting the parameter list *slightly improved* generated-code
accuracy. That is empirical vindication of "no `@param`", stronger than the
drift argument. But the same table shows deleting the prose *description* was
also near-neutral. If parameter lists and prose descriptions are both
near-neutral and only examples matter, then **the 690 hand-written `///`
comments are not the loaded spring. The 77 verified corpus programs are.**

**F4 — THE NEGATIVE SPACE HAS SHIPPED THREE TIMES; WHAT HAS NEVER SHIPPED IS
A VERIFIED ONE.** Julia's manual has an official *"Noteworthy Differences from
other Languages"* page organised by the language you are arriving from. Elixir
ships an official anti-patterns catalogue — four categories, each entry
Name / Problem / Example / Refactoring. Rust ships `rustc --explain` with a
triggering program and a fix for every error code. The vision's claim that
"no other language's documentation has ever led with it" is **false about
existence and true only about placement**. The genuinely novel part is K5:
refusals as compiled programs that **fail the build when they become legal**.
Nobody has that. Claim the narrow thing.

**F5 — `llms.txt` IS THE MEASURED FAILURE OF EXACTLY THE `avra brief`
PROJECTION, AND THE REASON IT FAILED IS INSTRUCTIVE.** SE Ranking's ~300,000-
domain analysis found **no correlation** between having an `llms.txt` and AI
citation frequency; adoption sits near **10%**; Google has publicly said it
does not use it, and as of Q1 2026 no major lab had committed to reading it.
<https://blog.tobira.ai/does-llms-txt-actually-work/> ·
<https://mecanik.dev/en/posts/does-llms-txt-do-anything-yet/>
It failed because it is a format shipped without ever asking the consumer
whether it helped. **Avra escapes this only if Part VII lands. Without Part
VII, `avra brief` is llms.txt with a compiler behind it.**

---

## §1 Confidence ledger

| # | Claim | Conf | Basis |
|---|---|---|---|
| 1 | Gleam/MoonBit zero-shot 0–1%, doc-RAG 1.23%, 5-shot 8.06%, instr-transfer 26–33% | HIGH | paper HTML read directly |
| 2 | Syntactic errors are 66–90% of no-resource failures | HIGH | same |
| 3 | Grammar explanations contribute ~nothing to Kalamang translation | HIGH | abstract read verbatim |
| 4 | Deleting example code drops API accuracy 0.66–0.82 → 0.22–0.39 | HIGH | paper HTML, quoted |
| 5 | Deleting the parameter list *slightly improved* accuracy | MEDIUM | reported in the extraction table; I did not see the per-library figures |
| 6 | Elm compiler errors: NO DOCS / DOCS MISTAKE / NO TYPE ANNOTATION | HIGH | `Reporting/Error/Docs.hs` read |
| 7 | Elm enforcement applies to modules exposed in `elm.json` | HIGH | elm docs + Docs.hs |
| 8 | Rust `missing_docs` is allow-by-default *because it is noisy* | HIGH | rustdoc book |
| 9 | Rust doctests were per-snippet binaries until the 2024 edition | HIGH | edition guide + rust#75341 |
| 10 | Go has no `@param`-style tags; Examples verified via `// Output:` | HIGH | go.dev/doc/comment, go.dev/blog/examples |
| 11 | Unison docs are values of type `Doc`, snippets typechecked | HIGH | unison-lang.org docs |
| 12 | Unison attaches a doc by the **name** convention `foo.doc` | HIGH | same |
| 13 | Unison doc *prose* can still rot; only snippets are guarded | MEDIUM | inference from the mechanism; not stated by Unison |
| 14 | 75.89% of ~1.16M real Jupyter notebooks fail to execute | HIGH | Pimentel et al., widely cited |
| 15 | llms.txt: ~10% adoption, no measured citation lift | MEDIUM | secondary analyses of SE Ranking data, not the primary study |
| 16 | AGENTS.md in 60,000+ projects since Aug 2025 | MEDIUM | vendor/blog sources, not an independent count |
| 17 | Doc augmentation *hurt* high-frequency APIs by 39.02% absolute | MEDIUM | search summary of arXiv:2407.09726; PDF not parsed |
| 18 | "Lost in the middle": >30% degradation mid-context | MEDIUM | secondary summaries of TACL 2024 |
| 19 | Elixir anti-patterns page is official, four categories, no enforcement | HIGH | hexdocs page read |
| 20 | Julia's "Noteworthy Differences" is an official manual page | HIGH | multiple mirrors of docs.julialang.org |
| 21 | Nuxt ships `/llms.txt` ~5K tokens and `/llms-full.txt` 1M+ tokens | MEDIUM | Nuxt docs via search summary |
| 22 | Unison's own team calls its doc experience best-in-class | HIGH | their experience report |
| 23 | Estimates of "fraction of surface policing drift" | LOW | my characterisation, not a measurement — see §A.7 |

---

## §A Doc systems that generate from the compiler

### A.1 The axis that matters

The vision's framing — *"every doc system ever built has thrown that away and
asked a human to retype it"* — is **half right, and the half it gets wrong
matters**. There are two families, and only one retypes.

**Family 1: derive-everything-structural.** godoc, Haddock, Roc, Swift DocC,
rustdoc. These read the compiler's own symbol table. The author writes prose;
nothing structural is retyped; there is no drift to police because there is no
second copy.

**Family 2: retype-in-comments.** JSDoc, Doxygen, and (partially) TypeDoc.
These were designed for languages where the compiler did *not* know the types,
so the comment had to carry them. TypeScript deleted the reason and the tags
survived — `eslint-plugin-jsdoc` ships a `no-types` rule whose entire purpose
is to strip type annotations from `@param`/`@returns` because they are now
redundant with the compiler.
<https://github.com/gajus/eslint-plugin-jsdoc/blob/main/docs/rules/no-types.md>

**Verdict for the vision:** Part II(a) is correct but should stop claiming
universality. Go has never had `@param`. Haskell has never had `@param`. The
sentence to keep is "the signature is data"; the sentence to drop is "every
doc system ever built."

### A.2 Go — the purest derive, and the strictest example verification

Go's doc comment convention has **no structured tags at all**:

> "A function's doc comment should explain what the function returns or, for
> functions called for side effects, what it does. Named parameters and
> results can be referred to directly in the comment, without any special
> syntax like backquotes."

<https://go.dev/doc/comment>

The only special forms are `Deprecated:` paragraphs, `MARKER(uid):` notes, and
`[Name]` doc links. **Coverage is not enforced by anything.** Examples are:
`ExampleFoo` functions in `_test.go`, whose stdout is compared against a
trailing `// Output:` comment by `go test`, and which render into the docs.
<https://go.dev/blog/examples>

This is the closest live system to Part III ¶3 ("docs vs tests, collapsed"),
and it is worth noting **Go did not build a doc-test runner** — it made an
example a *test that also renders*. Avra's corpus-as-examples is the same move
with the arrow pointed the other way.

### A.3 Elm — the only mandatory-coverage language, and it is a warning

Elm is the one system that genuinely refuses to publish an undocumented public
symbol, and the details matter because the vision's K1 is proposing the same
thing. From `compiler/src/Reporting/Error/Docs.hs`:

- **NO DOCS** — "You must have a documentation comment between the module
  declaration and the imports."
- **IMPLICIT EXPOSING** — "I need you to be explicit about what this module
  exposes"
- **DOCS MISTAKE (undocumented)** — "I do not see `X` in your module
  documentation, but it is in your `exposing` list" → "Add a line like
  `@docs X` to your module documentation!"
- **DOCS MISTAKE (unexposed)** — "I do not see `X` in the `exposing` list, but
  it is in your module documentation"
- **DUPLICATE DOCS**, **NO TYPE ANNOTATION**, and a family of PROBLEM IN DOCS
  parse errors.

<https://github.com/elm/compiler/blob/main/compiler/src/Reporting/Error/Docs.hs>

Enforcement applies to modules listed as `exposed-modules` in `elm.json`.
<https://github.com/elm/package.elm-lang.org/blob/master/assets/help/documentation-format.md>

**Three lessons, all of them for K1:**

1. Elm enforces **presence and structure**, never meaning. Nothing stops
   `{-| The name. -}`.
2. Elm's `@docs` list is **a second copy of the `exposing` list** — Elm
   created the exact drift the vision warns against, and then had to ship
   errors for *both directions* of it. This is the strongest single piece of
   evidence for Part II(a) and the vision does not cite it.
3. The mandatory version is **buggy in a specific, demoralising way**: the
   compiler has repeatedly reported MISSING DOCUMENTATION for functions that
   *are* documented — text after the last `@docs` line, `@docs` on the first
   line, `@docs` not starting a line.
   <https://github.com/elm/compiler/issues/993> ·
   <https://github.com/elm/compiler/issues/1982>

### A.4 Rust — the deliberate refusal to enforce

`missing_docs` exists and is **allow-by-default**. The rustdoc book's stated
reason: *"This lint is 'allow' by default because it can be noisy, and not all
projects may want to enforce everything to be documented."*
<https://doc.rust-lang.org/rustdoc/lints.html>

Coverage is a separate, still-unstable flag: `--show-coverage`, tracked at
<https://github.com/rust-lang/rust/issues/58154>.

So the language with the most-praised documentation culture in the industry
looked at mandatory coverage and **chose not to**. That is a data point
against K1's placement in the ladder, not against K1 existing.

Rust's genuinely relevant contribution is `rustc --explain <code>`: every
error code carries a long-form Markdown explanation with a program that
triggers it and advice to fix it, stored in `rustc_error_codes`.
<https://rustc-dev-guide.rust-lang.org/diagnostics.html>
**This is `avra explain F2040` almost exactly**, including the "show the
refused program" shape in the vision's Part IV mock-up. It is not novel; it is
well-trodden and it works. Adopt it without claiming it.

### A.5 Haddock, Swift DocC, Roc

- **Haddock**: annotations are *optional* — with none at all, it still emits
  signatures, data declarations and class declarations for everything
  exported. Derive-first by default.
  <https://www.haskell.org/haddock/doc/html/ch03s02.html>
- **Swift DocC**: compiles a **symbol graph** (a machine-readable directed
  graph of declarations and their relationships, emitted by the Swift
  compiler) and merges it with an authored `.docc` catalogue. This is the
  closest industrial analogue to "documentation is a compile target," and it
  is explicitly a *second compiler* consuming the first one's output rather
  than a query into the same engine.
  <https://github.com/swiftlang/swift-docc> ·
  <https://github.com/swiftlang/swift-docc-symbolkit>
- **Roc**: `roc docs` follows imports transitively; types are optional in
  source but always inferred, so signatures render whether or not anyone wrote
  them. <https://www.roc-lang.org/docs>

### A.6 Idris / Agda — the literate branch

Agda supports `.lagda.md`, `.lagda.tex`, `.lagda.rst`, `.lagda.typ`: the
document *is* the source file, and every code block is typechecked. Blocks can
be hidden from the rendered output inside HTML comments.
<https://agda.readthedocs.io/en/latest/tools/literate-programming.html>
Idris has bird-style literate support.

Note what this buys and what it does not: **the code in the document compiles;
the prose around it is unguarded.** That is the same boundary Unison lands on
(§B.1) and the same one Avra's K4 lands on.

### A.7 "What fraction of the surface exists purely to police drift?"

The lead asked for a fraction. **I will not invent a number** — nobody has
measured this and I could not find a study. What I can do is name the
machinery, which answers the question directionally with LOW confidence on any
figure and HIGH confidence on the direction:

| system | machinery that exists only because of a second copy |
|---|---|
| godoc / pkg.go.dev | **none.** No structural retyping exists to drift. |
| Haddock | near-none; annotations are optional overlays on derived output |
| Roc, Swift DocC | none structural (symbol graph is derived) |
| rustdoc | `broken_intra_doc_links`, `invalid_html_tags`, `bare_urls`, `missing_docs`, `--show-coverage`, and the entire doctest runner — a substantial minority of the tool |
| **Elm** | the `@docs` list itself, plus **6 of its 7 documentation error classes** exist to check one list against another |
| JSDoc / TypeDoc | the majority. `eslint-plugin-jsdoc` exists substantially to check comments against code; `no-types` exists to delete the copy outright |

**The honest verdict:** the drift tax is not a law of doc systems. It is the
price of a *retyped* copy, and half the industry already stopped paying it.
Avra's Part II(a) puts it in the "derive-everything" family, alongside Go —
good company, and not a new idea.

---

## §B The two systems closest to the thesis

### B.1 Unison — docs as values, and the honest limit

**What they actually built.** A `{{ ... }}` block is an expression of type
`Doc`. It is a first-class value: bindable, composable, embeddable in other
docs. A doc block placed immediately before a definition is auto-named
`<definition>.doc`, which is how `ucm`'s `docs` command finds it. Inside a
doc: double-backtick inline snippets are **typechecked**; triple-backtick
blocks are **evaluated at render time** and display their results;
`@source{term}` and `@signature{term}` transclude the real implementation and
the real signature.
<https://www.unison-lang.org/docs/usage-topics/documentation/>

Because the codebase is content-addressed, a rename does not break a doc's
references — the references are to hashes, and names are a separate layer.
<https://www.unison-lang.org/docs/the-big-idea/>

**What it feels like, per their own team:** *"The documentation experience
(both viewing and authoring documentation) is nicer than any language
ecosystem we've ever used"* and *"With a single `push` command, everything
shows up on Unison Share, the code fully hyperlinked, with live examples in
the docs."*
<https://www.unison-lang.org/blog/experience-report-unison-in-production/>

**Where it disappointed.** I found **no** public criticism of Unison's doc
system specifically — which is itself a finding, and a warning. The same
experience report's honest section is about the *ecosystem*: *"The ecosystem
and core language weren't nearly as developed when we started... Even very
basic libraries did not exist"* — they wrote TLS, HTTP, JSON and AWS bindings
themselves. **Unison built, by consensus, the best documentation experience in
any language ecosystem, and it did not move the language's adoption.** That is
the finding the vision should sit with for a minute: doc excellence was not
the binding constraint.

**The technical limit that matters for Part V.** Attachment is by the *name*
convention `foo.doc`, and the guarded parts of a doc are the transclusions and
the typechecked snippets. **The prose is unguarded.** (MEDIUM — this is my
inference from the mechanism; Unison's docs do not state what happens to a doc
whose subject changes hash.) So the strongest existing implementation of
"docs cannot go stale by construction" achieves it for exactly the half Avra
already generates from queries, and leaves stale exactly the half Part II(a)
designates as the only hand-written part.

**Net for the vision:** content-addressing is not the mechanism that makes
freshness work — *deriving* is. Avra's memoized query engine already gives it
the derived half. The narrow, true claim is: *"our derived half cannot be
stale, and our written half carries the hash of the shape it described"* —
which is K4, and which Unison does not do.

### B.2 Literate and notebook approaches — why they lost, and whether the LLM premise changes it

**Knuth's WEB.** The named causes of non-adoption, none of them about the
idea:
- Cost: *"adopting a literate programming approach might require more time —
  in the worst case, perhaps as much as double"* against business pressure to
  ship. <https://medium.com/@torazaburo/whither-literate-programming-2-what-went-wrong-e4a3d89af644>
- The tooling *"was mostly designed to overcome problems with Pascal"* —
  tangle/weave solved a language deficiency other languages didn't have.
- The exemplars were weak: *"the early examples are just not that good...
  The programs jump across abstraction layers."*
  <http://akkartik.name/post/literate-programming>

**Notebooks — the empirical verdict.** Pimentel et al. collected 1,159,166
notebooks from 264,023 GitHub repositories. Of 863,878 attempted executions of
valid notebooks, **24.11% ran without error, and 4.03% reproduced the same
results.**
<https://www.semanticscholar.org/paper/30228f5e3ecd19452a2a5388b23086569e6233f4>

That is the number to remember: **a document that must be executed to be true
acquires an environment, and three quarters of them rot.**

**Does the LLM-author premise change the answer?** Partly, and in a specific
direction:

- The *cost* objection genuinely weakens. Doubling authoring time is a
  different trade when the author generates at machine speed.
- The *exemplar* objection genuinely weakens for the same reason.
- The *environment* objection does **not** weaken at all. Avra's design
  already dodges it — corpus programs run under `make gate` in a controlled
  tree — and the dodge is the whole value. **Any future move toward "the doc
  is a live artifact" (D16, `--site`) re-acquires the environment and should
  be checked against 24.11%.**
- The strongest new argument for the literate frame is F2: if examples carry
  the teaching and prose does not, a doc built *out of* verified programs is
  not a stylistic choice, it is the empirically indicated one.

**Verdict:** the literate tradition did not fail because prose-plus-code is
wrong. It failed on authoring cost and on execution environments. Avra kills
the first with the author and the second with the corpus. That is a real
claim — and the vision does not currently make it.

---

## §C Doc-example verification

| system | mechanism | holds up at scale? | the actual complaint |
|---|---|---|---|
| **Go Examples** | `ExampleFoo` in `_test.go`, stdout vs `// Output:` | **yes** | none found; the design constraint (must be a compilable function, output must be deterministic) is the reason |
| **Rust doctests** | every ` ``` ` block in a doc comment compiled and run | **it did not, and they had to fix the architecture** | pre-2024-edition each snippet was a **separate binary**; a crate with 44 doctests and 36 normal tests spent 22 of 26 seconds on doctests |
| **Python doctest** | REPL transcripts in docstrings | **no** | whitespace-exact matching; `black` reformatting breaks every doctest; `flake8` and doctest give contradictory orders about trailing whitespace |
| **Elixir doctests** | `doctest MyModule` lifts `iex>` blocks from `@doc` | mostly | failures point at the function declaration with **no useful stack trace**; `#DateTime<...>` inspect forms are Elixir comments and **fail to compile** as expectations; ellipsis support only arrived in 1.19 |

Sources: <https://go.dev/blog/examples> ·
<https://doc.rust-lang.org/nightly/edition-guide/rust-2024/rustdoc-doctests.html> ·
<https://github.com/rust-lang/rust/issues/75341> ·
<https://github.com/rust-lang/cargo/issues/2944> ·
<https://github.com/psf/black/issues/1654> ·
<https://bugs.python.org/issue24746> ·
<https://hexdocs.pm/ex_unit/ExUnit.DocTest.html> ·
<https://github.com/elixir-lang/elixir/issues/3555>

**The pattern across all four:** the failure mode is never "the example was
wrong." It is **the comparison** — brittle output matching (Python, Elixir) or
a per-snippet compile path (Rust). Go avoided both by making the example a
real function and the output a real stdout capture.

**"Has anyone sourced examples from an existing verified corpus rather than
prose?"** Not that I can find, in the form Avra proposes. The closest are:
Go's Examples (written *as* tests, but authored for the doc — the corpus and
the doc are the same artifact from birth, which is the same collapse arriving
from the other side); Unison's `@source{term}` transclusion (pulls a real
definition into a doc, but the *definition*, not a *program exercising it*);
and Swift DocC's snippet system. **The specific move — `avra doc enums
--examples` reads `corpus/enums.av`, an artifact that already exists for a
different reason and is already gate-enforced — I found no prior art for.
Rate it novel.** (MEDIUM: absence of evidence over a wide search, not proof.)

**The warning for K3.** The vision's K3 says two things and the second one is
Rust's mistake: "Every `@example` names a corpus program that exists and
passes" (good — zero new execution machinery, rides `make gate`) and "Every
inline output in a doc (`"a.".split(".") → ["a"]`) is executed and compared"
(**this is a new per-snippet compile-and-run path**, i.e. exactly what cost
Rust 22 of 26 seconds until they rearchitected it, and exactly what makes
Python doctest brittle). Given this tree's serial-gate and memory discipline,
inline outputs should be **extracted into corpus programs**, not executed in
place.

---

## §D LLM cold-start artifacts — the live frontier

### D.1 llms.txt — measured, and it does not work

Covered in F5. Adoption ~10%; SE Ranking's ~300k-domain analysis found no
correlation with citation; Google's John Mueller compared it to the keywords
meta tag; no major lab has committed to consuming it.

The design detail that matters for `--budget N`: Nuxt ships **two** files —
`/llms.txt` at roughly 5K tokens and `/llms-full.txt` at **1M+ tokens**.
<https://nuxt.com/docs/4.x/guide/ai/llms-txt> (MEDIUM — figures from Nuxt's
own docs via search summary.) There is no middle. Everyone shipping this has
converged on *two* sizes chosen by feel, and nobody has published a
measurement of which one produces better code. **The vision's `--budget N` is
a genuinely better knob than anything shipped — and it is untested by anyone,
including the people who shipped the two-size version.**

Also noted from the Svelte ecosystem: documentation performance *degrades when
the full docs are not loaded into context*, which is the opposite of the
compression instinct.
<https://khromov.se/getting-better-ai-llm-assistance-for-svelte-5-and-sveltekit/>
(MEDIUM — a practitioner report, not a study.)

### D.2 Context7 / MCP-served docs

Context7 (Upstash) resolves a library name to an ID and serves
version-specific documentation and examples over MCP, marketed as "no
hallucinated APIs that don't exist, no outdated code generation."
<https://github.com/upstash/context7> · <https://context7.com/docs/overview>

**I found no independent evaluation of whether it improves generated code.**
Every claim I found is the vendor's. That absence is the state of the art in
this category.

### D.3 AGENTS.md / CLAUDE.md

De-facto standard since August 2025; reported adoption in 60,000+ open-source
projects; read natively by Claude Code, Codex CLI, Cursor, Aider, Devin,
Copilot, Gemini CLI, Windsurf, Amazon Q. Now under the Agentic AI Foundation
(Linux Foundation, co-founded by OpenAI with Anthropic and Block).
<https://openai.com/index/agentic-ai-foundation/> (MEDIUM on the 60,000
figure — vendor and blog sources.)

**Nobody measures these either.** There is no benchmark for "does this
AGENTS.md make the agent better", which is precisely the gap Part VII names.

### D.4 DeepWiki

Auto-generated wiki-style documentation for GitHub repos, 30,000+ indexed,
consumed by Devin itself: when a compile error occurs, Devin *"queries its
DeepWiki index to locate matching functions."*
<https://docs.devin.ai/work-with-devin/deepwiki>

The relevant academic work is **CodeWiki** (arXiv:2510.24428), *Evaluating
AI's Ability to Generate Holistic Documentation for Large-Scale Codebases* —
note the direction: it evaluates **docs generated by AI**, not **code
generated from docs**. The whole category is pointed the wrong way for P1.

### D.5 The state of the art, stated plainly

**Everyone is shipping a concatenated Markdown file, and the one category
that has been measured at scale (`llms.txt`) shows no effect.** Nobody in the
practitioner ecosystem is measuring whether their doc bundle makes a model
write better code. The measurements that exist are all in the academic
literature (§E), and they are about *retrieval*, not about *authored
artifacts*.

---

## §E The keystone question — answered, and the answer is uncomfortable

> **"Has ANYONE evaluated documentation by 'does a model that read only this
> write code that compiles'?"**

**Yes. Twice in the last eighteen months, in two different fields, and both
times the answer was: barely, and examples beat explanations.**

### E.1 arXiv:2606.16827 — the direct hit

Giagnorio, Martin-Lopez, Bavota (June 2026). Gleam and MoonBit chosen because
both stabilised after training cutoffs (Gleam v1.0 March 2024, MoonBit
compiler December 2024) and because GitHub holds only **280 Gleam and 35
MoonBit** repositories with ≥10 stars — versus 18k Lua, 19k R.

Six conditions: zero-shot, 5-shot (retrieved code examples), **RAG over the
official language documentation**, fine-tuning, further pre-training, and
instruction transferring.

McEval-Hard pass@1:

| condition | Gleam | MoonBit |
|---|---|---|
| zero-shot | 0–1% | 0–1% |
| best in-context | **1.23%** (RAG) | **8.06%** (5-shot) |
| fine-tuned | 3.04% | 10.93% |
| pre-trained | 12.47% | 25.86% |
| + instruction transfer | 26.08% | 32.60% |

For reference: high-resource languages 59–89% zero-shot on the same suite.

On HumanEval (easier), Gleam zero-shot is 4.55–7.60%, MoonBit 7.34–12.60%,
rising to 56.23% / 50.71% with instruction transferring.

**And the failure taxonomy is the vision's own metric:** syntactic errors —
code that does not parse — are 66–90% of no-resource failures versus under 10%
for established languages. Few-shot examples reduced syntactic errors by
15.36%; documentation RAG by 8.94%.

### E.2 arXiv:2409.19151 — the same result in linguistics

Aycock, Stap, Wu, Monz, Sima'an. Follow-up to MTOB (Tanzer et al., ICLR 2024
<https://openreview.net/forum?id=tbVWug9f2h>), which showed a long-context LLM
translating Kalamang — under 200 speakers, effectively absent from the web —
from a few hundred pages of field-linguistics reference material, scoring
44.7 / 45.8 chrF against a human's 51.6 / 57.0 who learned from the same book.

The follow-up ablated the book. Verbatim from the abstract:

> "We investigate the source of this translation ability, finding **almost all
> improvements stem from the book's parallel examples rather than its
> grammatical explanations**. We find similar results for Nepali and Guarani...
> As we find **no evidence that long-context LLMs can make effective use of
> grammatical explanations** for XLR translation, we conclude data collection
> for multilingual XLR tasks such as translation is best focused on parallel
> data over linguistic description."

Their nuance is worth carrying: grammar *does* help — on grammaticality
judgement and gloss prediction. **Explanations help the model reason
*about* the system; examples help it *produce in* the system.** Avra's
cold-start need is production.

### E.3 arXiv:2503.15231 — and again, in API documentation

Chen, Chen, Cao, Shen, Cheung (HKUST, March 2025). 1,017 APIs across four
deliberately uncommon Python libraries (Polars, Ibis, GeoPandas, Ivy), 2,031
extracted examples. Component ablation:

| removed | effect |
|---|---|
| **example code** | 0.66–0.82 → **0.22–0.39** |
| description | minimal |
| **parameter list** | **slight improvement** |

> "The pass rates of LLMs decrease most after we remove example codes... The
> result shows the essential impact of example codes on the success of the
> whole RAG system."

### E.4 The counter-finding: documentation can make things worse

*On Mitigating Code LLM Hallucinations with API Documentation*
(arXiv:2407.09726, Amazon). Documentation-augmented generation lifts
low-frequency APIs (to 47.94%) but, with a sub-optimal retriever, causes a
**39.02% absolute drop** on high-frequency APIs — the docs displace a correct
prior. Their fix is to *trigger* augmentation selectively rather than always.
(MEDIUM — from search summary; the PDF did not parse.)

### E.5 What is genuinely absent

I searched for, and did **not** find:

- Any evaluation where the subject artifact is a **hand-designed doc bundle**
  rather than a retrieval corpus.
- Any evaluation of **`llms.txt` / AGENTS.md / Context7** against a
  code-correctness metric by an independent party.
- Any **doc-quality metric defined as downstream compile rate** — the phrase
  the vision uses. Compilation rate exists as a *code-generation* metric; it
  has never been turned around and used as a *documentation* metric.
- Any system that **closes the loop**: measures a doc artifact, attributes
  each failure to a missing fact, and regenerates the artifact.

**So the absence the lead most wanted confirmed is real, but it is much
narrower than stated.** The experiment exists. The *loop* does not. The
honest novelty claim for Part VII is:

> The measurement has been run, on languages nobody could change, with
> retrieval corpora nobody designed. Nobody has run it on a language whose
> compiler generates the artifact, whose author is the subject, and where a
> failure is attributable to a missing row that can be added the same day.

That is still a strong claim. "I have not seen this anywhere" is not.

---

## §F The negative space

### F.1 It has shipped, three times, as prose

**Julia — "Noteworthy Differences from other Languages."** An official manual
page organised by the language you are arriving *from*: sections for C/C++, R,
Python and MATLAB, each listing the thing you will reach for and what happens
instead (1-based indexing, `Any` vs `object`, assignment semantics, scoping).
This is the vision's Want #2 — "I already know ten languages; my failure mode
is transfer, not ignorance" — shipped in 2013.
<https://docs.w3cub.com/julia~1.2/manual/noteworthy-differences>

**Elixir — the anti-patterns catalogue.** Official language documentation.
Four categories (code-related, design-related, process-related,
meta-programming); every entry is Name / Problem / Example / Refactoring; the
catalogue originates in academic work by Vegi and Valente (ASERG/DCC/UFMG).
Opening line: *"Anti-patterns describe common mistakes or indicators of
problems in code. They are also known as 'code smells'."* **Nothing enforces
any of it.**
<https://hexdocs.pm/elixir/what-anti-patterns.html>

**Rust — `--explain` and the error index.** Every error code has a long-form
explanation containing a program that triggers it and advice to fix it.
Structurally identical to the vision's Part IV `avra explain F2040` mock-up.
<https://rustc-dev-guide.rust-lang.org/diagnostics.html>

### F.2 What is actually novel

Three things, and they are worth separating carefully because two of the three
are real:

1. **VERIFIED refusals (K5).** Julia's page, Elixir's catalogue and CLAUDE.md's
   "The subset today" are all prose that rots silently. `lang/subset/*.av` as
   compiled programs asserting *both* the refusal and its wording, failing
   `make gate` when an entry becomes legal — **I found no prior art. Novel.**
   The closest relative is a compiler test suite's `// ERROR:` expectations
   (Rust's `ui` tests, Go's `errorcheck`), which do exactly this mechanically
   — but nobody has ever *published the test suite as the documentation*.
   That inversion is the idea.
2. **The negative space FIRST.** Julia's page is deep in a manual; Elixir's is
   a separate guide. Leading a cold-start artifact with "do not write this" is
   an ordering nobody has shipped. **Novel as placement, weak as a claim** —
   it is a layout decision, and F2 says the thing that will actually move the
   number is examples, not ordering.
3. **Refusals derived from the diagnostic registry.** Rust's error index is
   hand-written Markdown per code. Deriving the negative space from the same
   rows that produce the diagnostics — one object, two projections — is P12
   applied, and I found no one doing it.

**So: the claim "documenting what does NOT exist is worth more than
documenting what does" is not novel as an insight. The claim "and it can be a
verified compile target" is.** Rewrite the boast accordingly, because the
current phrasing ("no other language's documentation has ever led with it")
will be read as false by anyone who has used Julia or Elixir, and it makes the
genuinely novel part look like more of the same.

---

## §G WHERE THE VISION IS WRONG

Ordered by how much it would cost to be wrong about.

### G1 — The brief's degradation axis is backwards, and the evidence is unanimous

Part III ¶1: *"it degrades by dropping **detail**, never by dropping
**features**... At 800 tokens every feature gets its syntax line and nothing
else. At 20,000 every feature gets a worked example and its refusals."*

**Every study in §E says the worked example is the part that teaches and the
syntax line is the part that does not.** The 800-token brief as designed is
29 syntax lines — the closest possible artifact to a grammar summary, which
arXiv:2409.19151 found contributes ~nothing, and which arXiv:2606.16827 scored
at 1.23%.

**Correction:** invert the axis. At low budget, ship **fewer features with one
complete compiling program each**. At high budget, add features and prose.
Degrade by *coverage of the language*, not by *resolution of each entry* —
because a model that has seen three real Avra programs will transfer to a
fourth feature better than one that has seen 29 one-liners and no program.
This is testable the day Part VII exists, and it should be the **first**
experiment run, because it decides the whole shape of `brief`.

### G2 — K6 is the F2040 trap, in the vision's own words

CLAUDE.md: *"A LINT COUNTS WHAT ITS DOCTRINE COUNTS, never a proxy that
correlates."*

K6 says: "At every budget, the brief mentions every feature, every diagnostic
family, and every subset entry at least once. Completeness is not a judgement
call; it is a set difference."

**A set difference over *mentions* is a proxy.** The doctrine is "the reader
can write this feature correctly." The proxy is "the feature's name appears."
K6 will be green on a brief that teaches nothing — that is precisely the
1.23% artifact. And it does worse than fail silently: it **forbids the
correct design**, because §E.4's evidence (docs displacing correct priors) and
plain token economics both argue for weighting the brief by **surprise** —
spending nothing on `let x = 1` and everything on the six things that will be
written wrong. K6 makes uniform coverage a gate condition.

**Correction:** K6 should be a *completeness report*, not a gate, until Part
VII can tell you whether completeness correlates with the pass rate. Gate on
the pass rate; report the set difference.

### G3 — Part VII's novelty claim is false, and its expected numbers are wildly optimistic

"This is the part I have not seen anywhere" — see §E.1. It was published three
months ago.

Worse than the credit: **the mock-up sets an expectation that will destroy the
gate on first contact.** Part IV shows `31/40 compiled clean (baseline 29)`.
The only published run of this experiment scored 0–1% zero-shot and 1–8% with
in-context documentation on hard tasks, 4–13% on HumanEval-easy. Avra is
strictly harder than Gleam for a cold model in one respect (it is not on the
web *at all*) and easier in another (the artifact is designed rather than
retrieved, and Avra's syntax is deliberately mainstream-shaped).

**Correction:** state a *predicted* first number before building, publicly, in
the doc. If the first run comes back 4/40 and the doc promised 31/40, the
honest reading ("this is what cold-start looks like, now let's move it") loses
to the demoralising one ("the docs are broken"). And per CLAUDE.md's own
measurement discipline: **a ratchet whose baseline was guessed is a ratchet
that will be abandoned.** Take the first measurement, then set the ratchet —
never the reverse.

### G4 — The presenting fact may be the wrong spring

Part 0 leads with 690 hand-written `///` comments as a loaded spring. But
arXiv:2503.15231 found deleting the *description* near-neutral and deleting
*examples* catastrophic. If that transfers, the 690 comments are the *least*
P1-valuable asset in the tree and the **77 corpus programs are the spring** —
already verified, already gate-enforced, already one per feature, and they are
mentioned in the vision only as a solution to the docs-vs-tests paradox.

**Correction:** this is not an argument to drop `///` — prose is what the
*human* reader and the `--stale` work order need, and §E.2 says explanations
help reasoning *about* a system. It is an argument about **ladder order**.
D4 (`avra brief`) currently assembles "feature `docs` + gram + the subset
directory" — three prose sources and no programs. **The first `brief` should
be built out of `corpus/*.av` and should be cheap enough to ship before D1
touches the lexer at all.**

### G5 — K1 (coverage) is scheduled before the thing that would justify it

The ladder puts F0910 coverage + ratchet at **v2** and the cold-start gate at
**v3**. So the tree will ratchet ~200 sites of hand-written prose *before*
anything can measure whether hand-written prose moves the number.

The prior art is not encouraging in either direction. Rust deliberately left
`missing_docs` allow-by-default *because it is noisy*. Elm made it mandatory
and got (a) `{-| The name. -}` as the equilibrium, (b) a second copy of the
exposing list, and (c) a decade of bug reports where the compiler cried
MISSING DOCUMENTATION at documented code.

And the vision **already knows this** — Part X: *"Coverage is not quality.
100% coverage of 'returns the result' is worth nothing. K2 attacks this and
will only partly succeed. The cold-start gate is the real answer and it is
v3."* That paragraph is an argument for reordering the ladder, written in the
ladder's own document, and then not acted on.

**Correction:** move the cold-start measurement — even a crude, hand-run,
10-task version — **above** K1. It is cheap (a prompt, a compiler, a tally),
it needs no compiler change at all, and it is the only thing that can tell you
whether the coverage ratchet is buying anything.

### G6 — K3's inline-output execution is Rust's mistake, verbatim

Covered in §C. "Every inline output in a doc is executed and compared" is a
new per-snippet compile path. Rust ran that architecture for a decade and
rearchitected it in the 2024 edition after a 44-doctest crate spent 22 of 26
seconds on doctests. Python's version of it is the most-complained-about
testing tool in the language.

**Correction:** `@example` names a corpus program (keep). Inline outputs are
**extracted into** corpus programs by a tool, never executed in place. This
also keeps `make gate` on one execution path, which the tree's serial-gate
discipline requires anyway.

### G7 — "Docs cannot be wrong" is over-claimed, and Unison already found the boundary

Part XI: *"Docs that cannot be wrong."* Part V's freshness model is the
strongest part of the design, and the honest statement of it is narrower than
the slogan:

- The **derived** half cannot be stale. True — and true because it is derived,
  not because of anything content-addressing adds. Unison confirms the
  mechanism; a memoized query engine already has it.
- The **written** half is guarded by a sig hash. That is **structural**
  freshness, and Part X already concedes the false-negative floor (meaning
  moves under an unchanged signature).
- Unison is the existence proof that this boundary is where every system
  lands, including the one that went furthest.

**Correction:** the slogan should be *"the derived half cannot be stale, and
the written half knows what shape it described."* The stronger version is a
promise the design does not keep, and P7 (visible magic) argues against
selling a guarantee with an unstated hole.

### G8 — Position is a design variable the budget model does not name

`--budget N` treats the brief as a bag whose contents shrink. But "lost in the
middle" is a measured effect: relevant information at the start or end of a
long context is used substantially more reliably than the same information in
the middle (TACL 2024; secondary summaries put mid-context degradation above
30% — MEDIUM).
<https://aclanthology.org/2024.tacl-1.9/>

At 20,000 tokens the brief has a middle, and K6's uniform-coverage rule means
nothing decides what lands there. The negative space — the thing the vision
says matters most — could be anywhere.

**Correction:** make ordering an explicit, testable part of the brief's
contract (negative space and the most-transferred-wrong facts at the head and
tail), and let Part VII measure it. This is a free experiment once the harness
exists and it is exactly the kind of question nobody else can run.

### G9 — The unclaimed novelty, which is being given away

Two genuinely novel things are currently buried under claims that are not
novel:

1. **K5 — verified refusals.** A refusal corpus that fails the build when a
   refusal becomes legal. No prior art found. The nearest relatives (Rust `ui`
   tests, Go `errorcheck`) do the mechanism but never publish it as the
   documentation. **This is the best idea in the document and it is D5, sixth
   in the v1 list, described as "does not need D1."** It should be first: it
   is the cheapest rung, it needs no lexer change, it discharges CLAUDE.md's
   own re-probe standard, and it is the part nobody else has.
2. **The closed loop** — measure the artifact, attribute each failure to a
   missing row, add the row, re-measure. §E has three papers that measure and
   zero that close. The vision has the loop in Part VII's failure grouping
   ("2 gaps, both in the negative space, both fixable by a row") and does not
   name it as the novel part.

Meanwhile the claims that will not survive contact: "every doc system ever
built has thrown that away" (Go and Haskell did not), "no other language's
documentation has ever led with it" (Julia and Elixir ship it), "this is the
part I have not seen anywhere" (arXiv:2606.16827).

**A vision that over-claims on three checkable points loses the reader's
trust for the two that are real.**

---

## §H One-page summary for the lead

**Keep, unchanged:** Part II(a) no-`@param` (§E.3 vindicates it empirically,
better than the drift argument does). Part III ¶3 corpus-as-examples (§E is
unanimous; Go arrived at the same collapse). K5 verified refusals (novel;
promote to first rung). K4 sig-hash freshness (Unison does not have this).
`avra explain` (well-trodden, works, do not claim it).

**Change:** the brief's degradation axis (G1). K6 from gate to report (G2).
Ladder order — cold-start measurement above coverage ratchet (G5), K5 above
everything (G9). K3's inline execution (G6). The three novelty claims (G3, F.2,
G9).

**Add:** a predicted first cold-start number, written down before the harness
exists (G3). Position as a brief contract (G8).

**Sit with:** Unison built the best doc experience in any language ecosystem,
by its own users' account, and it did not move adoption (§B.1). Documentation
excellence is a real good; it is not, on this evidence, a growth mechanism.
For Avra it does not need to be — the author is the audience and the audience
is measurable — but that is the argument, and it should be made explicitly
rather than assumed.
