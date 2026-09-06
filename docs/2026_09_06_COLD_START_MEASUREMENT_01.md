# The first cold-start measurement — and why its headline number is NOT a cold-start number

> **BASE.** Run 2026-09-06 against `build/avra` in the primary worktree.
> HEAD at the start of the run was **`74501ef`** ("fix(lexer): a leading
> comment's LENGTH changed the parse"); the binary was built 00:27:52,
> two minutes BEFORE that commit's timestamp. **Verified by behaviour,
> not by timestamp**: the leading-comment defect that commit fixes does
> not reproduce on this binary (three probes — no comment, `//ab`,
> `// leading` — all parse identically), so the build already carried the
> fix and the commit followed it. That check mattered: cold-start
> programs routinely open with a comment, and a pre-fix binary would have
> refused some of them for a reason having nothing to do with the model.
>
> All checks were single-file `./avra check` runs. No `make`, no package
> run, nothing backgrounded. Diagnostic codes were listed with
> `grep -oE 'F[0-9]{4}' | sort -u` before any conclusion — LANE D's law.

---

## THE HEADLINE, STATED HONESTLY

| arm | what the model had | compiled |
|---|---|---:|
| **treatment** | CLAUDE.md (involuntary) + a 6000-token generated brief | **9 / 10** |
| **control** | CLAUDE.md (involuntary) only | **2 / 10** |

**The 9/10 is real, and it is NOT a cold-start pass rate.** The subjects
were not cold. Read the next section before quoting any number from this
document.

**What IS valid is the delta: +7 of 10 from the brief alone**, measured
as a controlled A/B where the brief is the only difference between arms.

---

# Part I — THE HARNESS WAS NOT COLD, AND I FOUND OUT BY RUNNING A CONTROL

## What happened

I am the wrong subject for this experiment — I have read CLAUDE.md in
full, the whole "subset today" section, and run ~100 probes. So the
subjects were fresh subagents, each confined to a sandbox holding exactly
two files (the brief and one task), instructed to read nothing else. All
ten reported exactly 3 tool calls (2 reads, 1 write) and no other file,
and an independent check found **no API used that the brief did not
attest** — the only unattested identifier across all ten programs was
`bumped`, which the task itself asked the model to define.

The isolation of the *sandbox* held. The isolation of the *context* did
not, and nothing about the sandbox could have fixed it.

**A subagent launched in this project inherits the project's CLAUDE.md in
its system prompt.** I did not infer this. I asked one, with tools
forbidden:

> **1. Yes.** The information is coming from **instructions in my
> context/system prompt** — specifically a `# claudeMd` block quoting
> `/Users/tristan/projects/tristanMatthias/avra/CLAUDE.md` … I have
> **nothing about Avra from pretraining**.

Asked four language questions with zero tool calls, it answered three
correctly out of that context — including two straight from "The subset
today":

> **`List.reverse()` — no.** Explicitly listed under "Methods the runtime
> lacks" … **Or-pattern separator: the word `or`.** From "The subset
> today" …

So every subject in both arms was carrying **the single most valuable
Avra reference in this repository**, including the 47-entry refusal list
this campaign spent the day verifying.

## The tell that made me look

The control arm — agents given *no brief at all* — produced this:

```avra
let disc: Shape = .Circle(4)
area(disc)
```

A typed `let` so a bare variant reads its want is a CLAUDE.md-documented
subtlety. A model with no Avra information does not write that. **The
result was too good, in the arm designed to be bad**, which is the only
reason the contamination surfaced.

## What this does and does not invalidate

- **Invalid:** "9/10 of cold-start Avra compiles." Nothing here supports
  that. Neither arm was cold.
- **Valid:** the **delta**. Both arms carry identical CLAUDE.md
  contamination; the brief is the only difference. +7/10 is a clean
  controlled result about what the brief adds *on top of* CLAUDE.md.
- **Unknown:** the true cold number. It is bounded above by 9/10 and, on
  the published baselines (1.23% retrieval, 8.06% five-shot), likely far
  below.

## What a real cold start needs

A subject with **no project context injected** — a separate session
outside this repository, or a direct API call with a bare system prompt.
I cannot produce that from inside this lane; every model I can reach here
is handed CLAUDE.md before it sees anything I write. **This is the single
blocking dependency for rung D13**, and it is a harness requirement, not
a research question.

---

# Part II — PREDICTION VS RESULT

Written to `PREDICTION.md` and frozen (md5 `4ae2246e…`) **before** the
brief was generated and before any task ran.

| | predicted | actual |
|---|---|---|
| my band | 15–30% (2–3 of 10) | **9 / 10** |
| lead's band | 10–25% | |
| dominant failure mode | syntactic | **1 failure, and it was syntactic** |

Both predictions were far too low — **because both of us were predicting a
cold start, and this was not one.** The prediction was not wrong about the
subject it named; the experiment failed to produce that subject. I am
recording the miss rather than rescoring the band.

Two called shots did land. My predicted trap #5 — *"`use @std/io` with a
SLASH; the spelling is `@std.io` with a DOT"* — was the **only** failure
in the treatment arm. And the predicted syntactic dominance held: every
control failure was a name or a parse error, none semantic.

The tasks were frozen (00:31:26) before the brief existed, so the brief
could not be tuned to them. Neither was touched after results came in.

---

# Part III — THE ATTRIBUTION, WHICH IS THE PRODUCT

## Treatment arm: one failure, one cause, one character

`t03` was the only refusal:

```
error[F0100]: expected `.` while parsing `stmt`
1 │ use @std/io.{read_text}
  ·         ┬
error[F3000]: no `fn read_text` is defined
```

Changing **one character** — `/` to `.` — and nothing else makes it
compile clean:

```
$ diff  →  < use @std/io.{read_text}   > use @std.io.{read_text}
exit=0  codes=
```

**The fact whose absence caused it: how an import is spelled.** And the
brief could not have carried it, by construction:

```
$ grep -c 'use @std\|^use ' brief.txt   → 0
$ grep -c '@std' brief.txt              → 0
```

**Zero occurrences.** The assembly method guaranteed this hole: `then`
cases were extracted as bare expressions, stripped of the `use` lines
above them, and `corpus/` programs are loose entry files that import
nothing. **The brief was assembled from programs that never import, so it
could not teach importing.** That is a defect of the generator, not of the
model — and it is exactly the kind of gap this measurement exists to name.

## Control arm: the one fact worth more than any other

The eight control failures attribute to four facts:

| rank | fact absent | failures |
|---:|---|---:|
| 1 | **how a program shows a value** (`println` does not exist as a free fn; an entry file SHOWS its final expression) | **6** |
| 2 | import spelling and the `@std` prefix (`no module std.io`) | 1 |
| 3 | the `spec`/`given`/`then` assertion shape (invented `expect`) | 1 |
| 4 | statement/BREAK shape (F0100) | 1 |

Six of eight control failures are **one fact**. `println` was reached for
in t02, t05, t07, t08, t09 — every task that needed to show a result.

The brief fixed it in two places at once: its header states *"An entry
file runs its TOP-LEVEL STATEMENTS in order; there is no main(). A
function's LAST EXPRESSION is its answer,"* and all 16 corpus programs
demonstrate it. In the treatment arm `println` appears **zero** times.

**Both arms therefore point at the same two facts** — how to show a value,
and how to import. The brief carried the first and structurally could not
carry the second. Adding import lines is a one-line generator change with
a predicted 10/10.

---

# Part IV — WHAT WAS BUILT

**The suite (frozen 00:31:26, before the brief existed).** 10 ordinary
tasks: an enum with a total match; a filtering comprehension; read a file
and count words; a struct with a method; an absent value; a
`spec`/`given`/`then`; a three-way branch; a sum; a `Result`-answering
fn; a join.

**The brief (frozen, md5 `ba64dacc…`, 6014 est. tokens).** Assembled from
programs, in the order the campaign specified:

| source | available | used |
|---|---:|---:|
| `then` cases from `@std` (single-line, <160 chars) | 415 | **139** |
| `corpus/` bodies, harness tails dropped | 77 | **16** |
| feature `docs` prose, last and least | 28 | **17** |

Generator seeded (`20260906`) and deterministic; `then` cases
round-robined across packages for coverage.

**The harness.** A fixture package in the scratchpad with all 12 `@std`
packages wired as path dependencies, so a missing dependency could never
be scored as a model failure. Each answer is copied to `src/main.av` and
checked as a single file — light by the wrapper's own rule (heavy only
when an argument is a directory).

## Correctness, not just compilation

`./avra check` proves a program compiles, not that it is right. All nine
compiling programs were run:

| task | answer | correct |
|---|---|---|
| t01 area(Circle(4)) | `48` | yes (3·4·4) |
| t02 evens of 10 numbers | `4` | yes |
| t03 (after the 1-char fix) | `0` | yes — `/etc/hostname` does not exist on this host, and the task said treat unreadable as empty |
| t04 bump twice from 0 | `2` | yes |
| t05 first long / absent | `four none` | yes |
| t06 spec block | *(no output)* | **unverified** — running a spec needs `avra test`, a package run this lane may not make |
| t07 label(5) | `small` | yes |
| t08 sum | `31` | yes |
| t09 both outcomes | `port 4 \| refused: a port needs a value` | yes |
| t10 join | `hello brave world!` | yes |

**8 of 10 verified correct; 1 compiles but is unverifiable here; 1 failed
to compile.** Zero warnings across all ten.

---

# Part V — HONEST LIMITS

- **The subjects were not cold.** Part I. This is the dominant limitation
  and it caps what any number here means.
- **The tasks are ordinary by design and may simply be easy.** The suite
  was written to the campaign's spec ("jobs a competent author should
  manage") and is **not adversarial**: nothing in it forces `sort`,
  `reverse`, a trailing lambda, a `dyn` want, a generic, or any of the
  47 refusals in the verified subset corpus. A trap-dense suite would
  score far lower, and that corpus is sitting there ready to become one.
- **n = 10, one sample per task.** pass@1 from a single draw has large
  variance; no repeat sampling was done.
- **The `then` cases carry context they cannot supply.** Extracted as
  bare expressions, many reference package-local helpers (`said`, `door`,
  `kind_of`, `words()`) a reader cannot call. They teach SHAPE but read as
  callable API. This did not cause a failure here, but it is a real defect
  of assembling from assertions.
- **The fixture package is generous.** 12 dependencies wired. A loose
  scratch file would have failed t03 regardless, with F3015.
- **`avra check` is the oracle for the headline**; correctness was checked
  separately and is reported separately.

## The wording law, applied to myself

This lane's own K5 rule, sharpened by LAND D: *a verifier's strong claim
is "this did not reproduce as written"; the claim it must not make is
"this is false."* Applied here: **t03 is a failure of this brief on this
run — not evidence that a model cannot write an Avra import.** It is
evidence that a brief assembled from non-importing programs cannot teach
importing, which is a statement about the generator.

---

# Part VI — WHAT TO DO NEXT, IN ORDER

1. **Fix the harness before trusting any absolute number.** A subject
   outside this repository, with no CLAUDE.md injection. Everything else
   is secondary; without it D13 measures the wrong thing.
2. **Add imports to the generator.** One `use` line per `@std` package
   the brief cites, plus the `@std.name` spelling. Predicted 10/10, and
   cheap to falsify.
3. **Build the adversarial suite from the verified subset corpus.** 47
   refusals already exist as runnable programs with recorded wordings.
   That is the other end of the range and it costs almost nothing.
4. **Then ratchet.** A rate is only a baseline once its harness is
   honest; ratcheting the current number would lock in the contamination.

## Artifacts

All under the session scratchpad's `cold/`: `PREDICTION.md` (frozen
before the run), `tasks/` (frozen before the brief), `gen_brief.py`,
`brief.txt` + `brief_manifest.json`, `run1/t*/answer.av` (treatment),
`ctrl/t*/answer.av` (control), `pkg/` (the fixture), `results.txt`.

---

# Part VII — THE INSTRUMENT, WITH ITS HOLE NAMED

Added after the campaign lead independently identified the contamination
described in Part I and asked for the harness to be built **with the
subject as a named hole** rather than filled by a contaminated stand-in.
The diagnosis matched what the control arm had already exposed; what was
genuinely missing was the instrument as a *separable artifact* and a
demonstration that it can fail.

## `score.sh` — everything except the subject

```
sh score.sh <solutions-dir> [label]
```

`<solutions-dir>` holds one candidate per task (`t01.av` … `t10.av`),
**however produced**. That is the hole: the script does not create
solutions and has no opinion about what wrote them. Give it a directory
and it answers a pass rate and a failure attribution. Swapping in a real
cold subject later is a directory swap and nothing else.

It obeys two laws earned by this campaign:

- **LANE D's law** — every diagnostic code is listed with
  `grep -oE 'F[0-9]{4}' | sort -u` before any conclusion. No verdict is
  read off a truncated window.
- **A missing candidate is MISSING, never a failure.** It is excluded
  from the denominator (`PASS 1 / 9`, not `1 / 10`), so a subject that
  declines to answer cannot be silently scored as one that answered
  wrongly.

## K0 — the instrument's own failure, witnessed

CLAUDE.md: *"A green check whose failure has never been witnessed is an
untested instrument."* Nine candidates, each wrong in a **named** way,
plus one correct and one deliberately absent:

```
t01  FAIL  a character the lexer does not accept                F0001
t02  FAIL  a method the runtime does not have                   F2030
t03  FAIL  import spelling: @std.name uses a DOT [read_text]    F0100 F3000
t04  FAIL  how a program shows a value (no free println) [println] F3000
t05  FAIL  an unknown fn [totally_absent_fn]                    F3000
t06  FAIL  statement or expression shape                        F0100 F2000
t07  FAIL  statement or expression shape                        F0100 F2001
t08  FAIL  statement or expression shape                        F0100 F2000
t09  PASS
t10  MISSING
----------------------------------------------------------------
PASS 1 / 9   (11%)   missing=1
```

Every named failure mode is named back; the correct program passes; the
absent one is excluded rather than counted.

### The limitation this exposed, stated rather than papered over

**Three distinct defects collapse into one bucket.** The `|` or-pattern,
the `type Id = int` alias, and `(0..n).any(…)` all report
`statement or expression shape` — because all three are F0100, a generic
parse error, and the harness cannot separate them without a rule per
shape. So the attribution is **precise for named facts** (a missing
`println`, an import spelling, an absent method, a rejected character)
and **coarse for syntax**. Since the published literature puts 66–90% of
no-resource failures in exactly that syntactic bucket, this is the half
of the instrument that most needs sharpening before the number it
produces can steer doc content. The 47-entry subset corpus already holds
the wordings that would do it.

## Two arms, through the instrument

| arm | pass | attribution |
|---|---:|---|
| CONTROL — CLAUDE.md only | 2 / 10 | 5× no free `println`; 1× `@std` prefix; 1× unknown fn `expect`; 1× syntax |
| APPROXIMATION — CLAUDE.md + brief | **9 / 10** | 1× import spelling (`@std.io` takes a DOT) |

**The 9/10 is labelled an UPPER BOUND and is not the pass rate.** Both
arms carry CLAUDE.md; only their delta is a clean result.

## What the subject must be, precisely

A model with **no exposure to this repository**: no CLAUDE.md in its
system prompt, no access to the tree, nothing but `brief.txt` and one
`task.txt`. Confirmed unavailable from inside this lane:

```
ANTHROPIC_API_KEY: absent
CLAUDE_API_KEY:    absent
OPENAI_API_KEY:    absent
```

So the subject requires an **API call originating outside this project
context** — the one place this system would touch a network — and
therefore the owner's key and budget. That is a decision, not a task, and
it is the single blocking dependency for D13.

Until it exists, this document reports a **bounded approximation with a
named hole**, which is the honest artifact. A contaminated number
presented as the measurement would poison the ratchet it is meant to
seed — and a ratchet set from an upper bound is worse than no ratchet,
because every later honest run would read as a regression.

---

# Part VIII — MEASUREMENT 02: the one-line fix landed, and it broke something else

Measurement 01 stands unmodified. This is the second measurement, reported
beside it, per the standing commitment in `PREDICTION.md`. Still an
**UPPER BOUND** — the subjects carry CLAUDE.md.

## The change

One generator section, built from real source: 11 `use @std.name.{…}`
lines grepped out of `packages/`, under the heading *"A module path uses
DOTS, never slashes: `@std.io`, not `@std/io`."* Brief v1 contained
**zero** occurrences of `@std`; v2 contains 12. Tasks unchanged, still
frozen at 00:31:26.

## Prediction, frozen before the run

`PREDICTION_02.md` (md5 `ed0aeb4e…`) predicted **10/10** and named three
ways to be wrong. **Falsification case 2 is what happened**, and it was
written down in advance:

> A DIFFERENT task regresses. The brief is regenerated, not patched …
> **A net 10/10 that hides a regression plus a fix is NOT the same result
> as a clean 10/10**, so I will diff per task, never just compare totals.

## The result

| | v1 | v2 |
|---|---:|---:|
| pass | 9 / 10 | **9 / 10** |

**The total did not move. The composition did.**

```
t03   FAIL   PASS      <<< FAIL -> PASS      the import fix landed
t06   PASS   FAIL      <<< PASS -> FAIL      a regression
```

Comparing totals alone would have read as *"the fix did nothing"* —
wrong about both halves. This is the strongest argument in either
measurement for **diffing per task and never trusting a rate**.

## The regression, attributed exactly

Brief v1 carried `corpus/specs.av`. Brief v2 does not:

```
v1 'spec "' occurrences: 1        v2: 0
v1 'then "' occurrences: 1        v2: 0
```

**One program in the whole brief demonstrated the `spec`/`given`/`then`
shape, and the IMPORTS section displaced it.** The corpus selector is a
greedy character-budget fit, so consuming ~370 tokens upstream reshuffled
which programs fit and `specs` fell out.

What the model wrote, with and without that single example:

```avra
// v1 — the example was present:      PASS
then "two plus two is four" { 2 + 2 == 4 }

// v2 — the example was gone:         FAIL
then 2 + 2 == 4
```
```
error[F0100]: expected STRING while parsing `then_case`
3 │         then 2 + 2 == 4
  ·              ╰──
```

The model still knew `spec`/`given`/`then` existed — the feature-notes
prose names them, and CLAUDE.md does too. It did not know `then` takes a
**caption string** before its block. So:

> **Prose names a construct; only an example carries its shape.**
> Measured, not asserted — one example was load-bearing, and its removal
> broke the only task that needed it.

## This independently validates the routed renderer's design

The regression is a live demonstration of exactly what
`assemble(rows, budget)` was built to prevent. Its contract:

> `budget` is a count of SHOWS, never of characters or lines — a program
> cannot be truncated, only kept or dropped … Selection keeps at least
> one show per feature before any feature gets a second.

**My generator has neither property**, and both failures follow from
that: it packs by characters (so a feature can be squeezed out) with no
round-robin (so nothing guarantees coverage). Verified against the
renderer's own fixtures:

```
budget=  1 -> shows= 1     budget=  5 -> shows= 5
budget=  2 -> shows= 2     budget= 11 -> shows=11
budget=  3 -> shows= 3     budget= 99 -> shows=11   (capped, not padded)
```

**The generator should be replaced by `assemble`, not patched.** A
completeness invariant is not a refinement here; its absence is the
defect that produced the regression.

## The completeness floor, computed rather than extrapolated

Campaign estimate: ~900 tokens for 28 features, from seven hand-written
shows. Measured across 11 real rows through `render_show`:

| | tokens/show |
|---|---:|
| median | 31 |
| mean | 31 |
| min / max | 21 / 39 |

**Floor for 28 features: 868 tokens (median), 858 (mean).** The estimate
is confirmed — shape exact, figure within 4%. The 6000-token budget used
in both measurements is **~7× the floor**, so neither is near it; a
smaller-budget arm would be, and `assemble` should refuse below it with
the number rather than emit something satisfying no invariant.

## An integration finding on the routed entry point

`shows_of` parses the **struct-literal** form of a `Show` only. Against
`fmt/j_three_features.av` — the table-form fixture, 8 shows across 3
features — it returns **zero rows, silently**:

```
j_three_features.av      rows=0        k_struct_form.av    rows=5
```

Not a defect (the real renderer holds `List<Show>` and parses nothing —
the extractor says so in its own docstring), but a **live green-by-accident
hazard for me**: a generator built on it and fed table-form sources emits
an empty brief and every downstream check still passes. The same class as
the trailing-newline defect doc-spine warned about. **Any caller must
assert `len(rows) > 0` and per-feature coverage before emitting.**

The three routed warnings were checked rather than taken on trust, and
all three hold: every `program` ends in **exactly one** newline (never
append); `budget` counts shows exactly; `verify` covers refusals fully and
answers only halfway — which is why every program in both measurements
was **run**, not merely checked.
