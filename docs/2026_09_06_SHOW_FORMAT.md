# The show format — what replaces `docs: string`

> **Status:** design, decided by probe. Format accepted by the lead;
> §6–§7 added after acceptance. Base: **`c13ff3c`**, `build/avra`
> 2026-09-06 00:33. The tree moved eight times during this work
> (`6553ec6` → `e046ba2` → `bd5c024` → `74fa9fc` → `312bd0d` → `6cfdd12`
> → `e0e88c8` → `173ddb8` → `c6ce7b7`); every probe below was run against
> the binary standing at the end, and the ones that mattered were re-run
> when it moved. Probes are **PROBED** (output quoted) or **UNVERIFIED**.
>
> The lead's proposal is in the vision, Part V. **It survives on the
> point the lead feared and loses on a point nobody had raised.** The
> verdict is at §1; the honest comparison the lead asked for is at §4.

---

## 1 — The verdict, up front

| question | answer |
|---|---|
| Is a row's program an escaped string? | **No — this was the fatal objection and it is dead.** A `"""` raw string works in a table cell (PROBED). Programs are real source. |
| Is `table<Row>` the right container? | **No.** A table buys ALIGNMENT; a multi-line cell spends it. The tree's own registry exemplar already agrees. |
| Is the row shape right? | **No — two defects, both killed by one field.** |
| Is the spec-case route better? | **No, and decisively: a refusing program cannot be a spec case** (PROBED). It cannot carry the negative space. |
| Is the file route better? | **No.** Same failure on refusals, plus a second artifact and a rot site. |

**What I would build:**

```avra
/// What a show EXPECTS. ONE field, so "exactly one of two" is
/// unspellable rather than merely documented, and an empty answer is a
/// real value rather than the absent one.
enum Expect { Answers(text: string), Refuses(code: string) }

/// One SHOW: a claim, the program that demonstrates it, and what the
/// program does. Every show compiles and runs at gate time.
type Show = { claim: string, program: string, expect: Expect }
```

carried as `shows: List<Show> = []` on `LanguageFeature`, written as
**struct literals with `"""` programs** — not as a `table`.

**So: the lead's idea is right and the lead's spelling is not.** The
collapse of four artifacts into one, the `refuses` row as a subset entry
owned by the feature that would falsify it, the gate belonging to the
slice author — all of that stands and is the good part. The container and
the row shape change.

---

## 2 — What the probes killed and what they saved

### 2.1 SAVED: the program is real source, not an escaped string

The lead's known cost was that a row's program is a string in a table —
lane B's escaped-source shape, measured at 81% and called worse than
nothing. **It does not apply, because a `"""` raw string works in a
table cell.** `scan_triple` (`lexer.av:175`) consumes the whole block
into ONE `Str` token, so the newlines inside never become `Break`s and
the row's boundary survives.

**PROBED** — all `EXIT=0` at `173ddb8`:

| probe | shape | result |
|---|---|---|
| A | single-line string cells | `EXIT=0` |
| B | `\n`-escaped multi-line cell | `EXIT=0` |
| **C** | **`"""` raw-string cell, multi-line** | **`EXIT=0`** |
| D | cells holding `\|`, `\|\|`, `}`, `"`, and a `///` | `EXIT=0` |
| E | `"""` block indented to match the table | `EXIT=0` |

D is the one that matters after C: a program contains the table's own
delimiters, and `scan_triple` makes all of them inert. The cell grammar
is `table_row = c:expression ( "|" c:expression )*`
(`features/tables/mod.av:20`) — a cell is an **expression**, and a raw
string is one.

### 2.2 KILLED: `table<Row>` is the wrong container for multi-line cells

Here is the lead's format, authored for real. This is three of the
enums rows, exactly as written:

```avra
    let rows = table<Show> {
        claim | program | expect
        "declares a closed set; `.variant` constructs" | """
enum Suit { clubs hearts }
let s = Suit.clubs
s.ordinal
""" | Expect.Answers("0")
        "`match` must cover every variant" | """
enum Suit { clubs hearts }
let s = Suit.clubs
match s { .clubs -> 1 }
""" | Expect.Refuses("F2013")
```

It compiles. It does not author.

- **The header describes nothing.** `claim | program | expect` is a
  promise of three aligned columns, and there are no columns.
- **Row boundaries are invisible.** A row begins where a line happens to
  start with a quoted claim. At six rows this is already hard to scan;
  the enums feature would carry a dozen.
- **`""" | Expect.Answers("0")` is unreadable** — a closing delimiter, a
  column separator and a value on one line, three different languages.
- **The programs must sit flush-left to read**, which fights every other
  indentation level in the file.

A `table<Row>` earns its keep by ALIGNMENT — that is the entire reason
this tree uses it for `builders`, `diags`, `methods` and `properties`,
whose rows are short. **A multi-line cell spends the alignment and leaves
the syntax behind.** What remains is a list of records wearing table
clothing, which is strictly worse than a list of records.

**The tree already settled this, and CLAUDE.md cites the file by name.**
`rt_sigs()` — *"a REGISTRY ROW: `rt_sigs()` is one table and five
consumers QUERY it"* — is **78 struct literals in a `List`**, not a
`table<Row>` (`core/runtime_api.av:10-`). So "the currency features
already use" is not uniformly `table`: this tree uses `table` for short
aligned rows and struct literals for long ones. `Show` rows are long.

### 2.3 KILLED: the row shape spends the empty value

`Show { claim, program, answers, refuses }` with *"exactly one of the
last two filled"* has two defects, and the first is a law this tree
already wrote down.

**AN ENCODING SPENDS THE EMPTY VALUE.** `answers: ""` means "no
expectation" — but a real Avra program **can answer the empty string**. A
show demonstrating that `"".is_empty()` is true, or that `split` drops a
trailing segment, has `""` as its genuine answer. The encoding gives one
value two meanings, at the exact boundary the law names, in the first row
shape written for it.

**And "exactly one of two" is an invariant the type does not state** —
it is prose, so a row with both filled, or neither, compiles.

**One field kills both.** PROBED, `EXIT=0` in a table cell and in a
struct literal:

```avra
enum Expect { Answers(text: string), Refuses(code: string) }
```

`Expect.Answers("")` is now a real, distinct value; "both filled" and
"neither filled" are unspellable. This is the tree's own preference for
making the unsafe shape unspellable rather than documenting it.

---

## 3 — The format, written out

Two features' worth, as they would appear. **PROBED: `EXIT=0`.**

```avra
fn enums_shows() -> List<Show> {
    [
        Show {
            claim: "declares a closed set; `.variant` constructs",
            program: """
                enum Suit { clubs hearts }
                let s = Suit.clubs
                s.ordinal
            """,
            expect: Expect.Answers("0"),
        },
        Show {
            claim: "`match` must cover every variant",
            program: """
                enum Suit { clubs hearts }
                let s = Suit.clubs
                match s { .clubs -> 1 }
            """,
            expect: Expect.Refuses("F2013"),
        },
        Show {
            claim: "`rest` is the deliberate remainder",
            program: """
                enum Suit { clubs hearts spades }
                let s = Suit.spades
                match s { .clubs -> 1, rest -> 0 }
            """,
            expect: Expect.Answers("0"),
        },
    ]
}

fn loops_shows() -> List<Show> {
    [
        Show {
            claim: "`for` counts a half-open range",
            program: """
                mut total = 0
                for i in 0..3 { total = total + i }
                total
            """,
            expect: Expect.Answers("3"),
        },
        Show {
            claim: "a range takes no methods — comprehend instead",
            program: """
                let hit = (0..3).any(it == 2)
                hit
            """,
            expect: Expect.Refuses("F0100"),
        },
    ]
}
```

Field names label every part, braces bound every row, the programs sit at
a uniform indent, and the negative space is a peer of the positive rather
than a separate system.

**The three refusal codes were checked, not assumed** — which is exactly
the property the format exists to give:

```
v1  error[F2013]: `match` on `Suit` must handle `.hearts`
v2  error[F0100]: expected `)` to close the group
v3  error[F0100]: expected BREAK while parsing `stmt`
```

**The dedent is safe, and it stopped being a hazard an hour ago.** An
extracted program carries its cell indentation. PROBED that uniform
indentation preserves meaning — the same chained program flush-left and
indented eight both answer `EXIT=0`. That was only true *conditionally*
until this morning: the `line_indent` defect (spine design §A.3) made a
program's meaning depend on what preceded it, so dedenting could have
changed it. **`74501ef` fixed that**, so the extractor may dedent freely.

---

## 4 — The honest comparison

The lead asked whether the spec-case route is strictly better. **It is
not, and the reason is one probe.**

### 4.1 The spec-case route cannot express a refusal

A `then` body is an expression answering a bool — a caption-plus-program
pair that already runs and is already gated. For `Answers` rows it is
genuinely attractive: the DSL exists, the programs are real source, lane
B counted 638 of them.

**But a `then` body must COMPILE.** A program that must *not* compile
cannot live in one. PROBED:

```
$ cat f_spec_refuses.av
enum Suit { clubs hearts }
spec "enums" {
    given "coverage" {
        then "a match missing a variant is refused" {
            let s = Suit.clubs
            match s { .clubs -> 1 } == 1
        }
    }
}
$ ./avra check f_spec_refuses.av
EXIT=1
error[F2013]: `match` on `Suit` must handle `.hearts`
```

The file is refused at check time. So the spec-case route **cannot carry
the negative space** — the 80 subset entries, and Part I's wants #2 and
#3, which the vision itself calls the half no other language's docs lead
with. That is not a gap to work around; it is the campaign's highest-value
material.

Two lesser marks against it: a `then` body is an **assertion**, so the
reader sees `== 0` noise where a show wants a program and its answer; and
a spec case is owned by the test suite, so the doc surface would be
reading a fixture rather than a declared surface.

**Verdict: spec cases stay what they are — the tests.** They are not the
show format. (They remain the best *source* of candidate rows: 638
existing caption+program pairs to mine when filling `shows` for the
`@std` packages.)

### 4.2 The file route loses on the same axis, plus friction

`program: "shows/enums_declares.av"` gives real source with no escaping
and no dedent. But:

- **A refusing program as a real `.av` file breaks any gate that compiles
  the tree.** It must live outside the compiled sources — which makes it
  a file nobody compiles, the definition of a rot site.
- **Two artifacts**, so claim and program are never adjacent while
  authoring. ~112 files at four shows across 28 features.
- The extraction a reader needs is identical either way.

**A string is inert data until a harness runs it.** That is precisely
what lets one currency serve `Answers` and `Refuses` alike, and it is the
strongest argument for the lead's original instinct.

### 4.3 A feature with no shows

**Countable with no proxy.** `shows: List<Show> = []` is the default, and
the metric is a set difference over the 28 features
(`compiler/mod.av:118`): `[f.name for f in avra().features if
f.shows.is_empty()]`. The gate's claim is "every feature has at least one
show"; the baseline lists **feature names, never a count**, per
DOGFOODING's first law. There is no proxy to drift, which is the property
CLAUDE.md demands of a lint and which a coverage percentage would not
have.

---

## 5 — The build order — HELD at the lead's ruling

**Steps 1–3 are held.** Not because they are wrong: `shows` is the durable
source for the brief, and **we do not yet know what content the brief
needs.** doc-subset gets the first cold-start number from a *scripted*
brief assembled from existing spec cases and corpus bodies; that number's
**failure attribution — which facts' absence caused which refusals — is
what tells us what a row must carry and how many a feature needs.**
Building `shows` first would fit the format to a guess about what teaches.
MEASURE THEN CHANGE, applied to us.

The order, for when it is unheld:

1. **`Expect`, `Show`, and `shows: List<Show> = []` on `LanguageFeature`**
   — replacing `docs: string`, which is cut.
2. **Fill three features** (enums, if_expr, loops) — written above,
   compiles.
3. **`avra brief`** emitting every show: the claim as the caption, the
   program dedented, the expectation rendered. That is the cold-start
   artifact, and it exists after step 3 with no keeper, no ratchet and no
   query family.
4. **The harness**, after the number exists: run each show — `Answers`
   compiles and runs and compares; `Refuses` compiles and asserts the
   F-code. That is when the four artifacts actually collapse.

Steps 1–3 need no lexer change, no `docs(ws, f)` family, and no `avra doc`
resolver. **D1/D2/D3 stay below the line, as ruled.**

**What is already built and needs nothing held:** the extractor, the
renderer and the row verifier (§6), which run at scratch scale today and
feed doc-subset's scripted brief directly.

---

## 6 — The renderer: what a reader actually sees

Built and run against the rows in §3. The extractor, the verifier and the
four candidate renderings live in the scratchpad
(`scratchpad/render/{shows,verify,render}.py`) — say the word and they
become a `tools/` script.

**The real renderer does no parsing.** It runs in Avra with the
`List<Show>` value in hand. The script recovers rows from source only so
the artifact could be looked at today; the parsing is throwaway, the
**rendering** is what was under test.

### 6.1 The criterion nobody had written down

> **Can a reader who skims only the code blocks tell a refusal from an
> example?**

A rendered refusal that looks like an example is **worse than no
documentation**: the reader copies a program that cannot compile, and the
doc has actively cost them. Every candidate was judged on this first and
on beauty second.

| candidate | shape | verdict |
|---|---|---|
| **A** prose header | claim, program, then `✗ REFUSED F2013` | **FAILS the criterion.** The marker is *below* the program, so a skimmer meets `match s { .clubs -> 1 }` looking exactly like the valid examples around it. |
| **B** Avra-native | refusal's program commented out entirely | **Passes, and costs too much.** Inert and unmistakable — but a commented-out program is degraded as a program, which is the one thing the prior art says must not be degraded. |
| **C** budget line | claim + last program line + marker | **Wrong, and instructively so** — see §6.3. |
| **D** verdict leads | `✗ REFUSED F2013 — <claim>`, then the program | **This one.** |

### 6.2 D, rendered

```
`enum` declares variants; `Suit.clubs` constructs one
    enum Suit { clubs hearts }
    let s = Suit.clubs
    s.ordinal
    → 0

✗ REFUSED F2013 — the set is CLOSED: a `match` missing a variant is refused
    enum Suit { clubs hearts }
    let s = Suit.clubs
    match s { .clubs -> 1 }

✗ REFUSED F0100 — a range answers no methods
    let hit = (0..3).any(it == 2)
    hit

comprehend a range, then scan the list
    let hit = [i for i in 0..3].any(it == 2)
    hit
    → true
```

The verdict leads, so the criterion is met by construction; the program
stays readable source; and a positive show needs no marker at all, so the
common case carries no ceremony.

**The remedy for a refusal is another SHOW, not a prose field.** The last
two blocks are a pair: the thing you would reach for, refused — then the
form that works. Both verified, neither able to rot, and no `instead:
string` field to drift. This is why `Expect` stays two variants.

### 6.3 A program cannot be truncated — only kept or dropped

Candidate C compacted by keeping the claim and the program's last line:

```
`enum` declares variants; `Suit.clubs` constructs one   s.ordinal   → 0
```

`s.ordinal` teaches nothing: the declaration that gives it meaning is
gone. **This is a real constraint on the budget design**, and it sharpens
the vision's "complete at every budget": the atom is the **whole show**.
A budget drops entire shows — and must drop them in an order that keeps
at least one per feature — but it may never truncate a program. Prose
degrades gracefully; source does not.

### 6.4 The pipeline is verified end to end, and its failure was witnessed

`verify.py` extracts every row, dedents it, writes it out, and checks it
against its own claim: an `Answers` row must compile, a `Refuses` row must
fail with the code it names.

```
  ok   enums    Answers  want=0        got=compiles      `enum` declares variants; `Suit.clubs` c
  ok   enums    Refuses  want=F2013    got=F2013         the set is CLOSED: a `match` missing a v
  ok   enums    Answers  want=0        got=compiles      `rest` covers the variants you did not s
  ok   loops    Answers  want=3        got=compiles      `for` counts a range, and the high end i
  ok   loops    Refuses  want=F0100    got=F0100         a range answers no methods
  ok   loops    Answers  want=true     got=compiles      comprehend a range, then scan the list

0 row(s) disagree with their own claim
```

**This also proves the dedent preserves meaning** — the refusal codes
still match exactly after extraction, which was the open risk in §3.

**And the check was made to fail three ways**, because a green check whose
failure has never been witnessed is an untested instrument:

```
row corrupted: wrong code       BAD  want=F9999  got=F2013
row corrupted: no longer refuses BAD  want=F2013  got=compiled clean
row corrupted: program broken   BAD  want=3      got=REFUSED F0100
```

The middle one is the vision's **K5** — *a refusal that has become legal
is a doc that is lying* — with a working instrument behind it, at scratch
scale, today.

What this does **not** cover is the `Answers` half: `check` proves a
program compiles, not that it answers `0`. Running it needs the lock. So
the scratch harness verifies **every refusal completely and every answer
halfway**, which is worth stating precisely rather than calling it green.

### 6.5 THE BLOCK-TO-SOURCE RULE, and why it is stated over the text

A raw block carries exactly two syntactic artifacts: **the remainder of the
opening line** (the newline right after `"""`) and **the indentation of the
closing line**. Both are positional. A blank line the author wrote is
neither, and an extractor that cannot tell them apart eats source.

**The lead's measurement is what raised it**, probed at `6a3a084`: a block
splits to `len=57 lines=4 first=[] second=[enum Suit { clubs hearts }]` —
byte-exact content, a leading empty segment, and no trailing one, because
Avra's `split` drops a trailing empty segment and keeps a leading one
(CLAUDE.md:927-929). Their conclusion — drop one leading line, never
symmetrically drop a trailing one — is right about the hazard.

**But the rule must not be stated over `split`, for two reasons.**

*It fires in only one of the two authoring forms.* The lead probed the
flush-left form, where the content ends in a bare `\n` and `split` removes
the artifact for free. **This format's own examples (§3) indent the closing
`"""`**, so the final segment is `"            "` — whitespace, not empty —
and the drop never happens. Same block, same count, different reason, and
an extractor written to the flush-left measurement mangles the indented
form.

*And it ties a renderer to a language quirk.* The asymmetry is `split`'s,
not the block's.

**So the rule is over the text:**

> Drop the opening line's remainder — asserting only whitespace precedes
> that first newline. Then drop the spaces and tabs that follow the FINAL
> newline — never the newline itself, so a blank last line survives. Then
> strip the common indent. A block whose content begins on the `"""` line
> is REFUSED, not guessed at.

Form-independent, language-independent, and it makes the author's blank
lines unreachable by the trimmer. **PROBED** across both forms and every
edge:

```
T1 indented (my format)        -> 'a\nb\n'
T2 flush-left (lead's probe)   -> 'a\nb\n'      ← identical, as it must be
T3 trailing BLANK line         -> 'a\nb\n\n'    ← survives
T4 internal blank line         -> 'a\n\nb\n'
T5 one line                    -> 'a\n'
T6 deeper continuation         -> 'a.trim()\n    .length\n'
malformed (content on the """ line) -> REFUSED
```

**The old rule and the new one diverge on TWO cases, and I only knew about
one.** Running both side by side:

```
program ending in a BLANK line   old: 'a\nb\n'   new: 'a\nb\n\n'   DIFFER
program ending normally          old: 'a\nb'     new: 'a\nb\n'     DIFFER
```

The first is the hazard the lead named. **The second is a defect I did not
know I had**: the symmetric trim dropped the trailing newline from *every*
program, and `verify.py` was hiding it by appending one before writing the
file. It would have surfaced the first time a program was rendered into a
brief by anything that did not append a newline of its own. A warning about
one end of a transform found a bug at the other end.

T6 is the case worth keeping: a chain continuation's *relative* indent
survives, which is what the chain-continuation rule reads. Verified end to
end — the show extracts and compiles.

### 6.6 The interface, and the completeness floor

One entry point, `scratchpad/render/brief.py`. Every function is pure and
moves plain data, so the caller owns ordering, policy and output; nothing
writes a file.

```python
shows_of(*paths)   -> [ {feature, claim, program, kind, expect}, … ]
render_show(row)   -> str          # one show, verdict leading
assemble(rows, budget=None, order=None) -> str
verify(rows, avra="./avra")        -> rows that disagree with their claim
```

`program` is **real dedented source ending in its own newline** (§6.5) —
write it out as-is; appending a newline is what hid a defect this morning.

**`shows_of` REFUSES a source it cannot fully read**, rather than answering
zero rows. Zero is honest for a file that declares no shows (§4.3, a feature
with none) and catastrophic for a file whose shows the parser cannot see —
and a caller cannot tell those apart from a count, so it must not have to.
Two sources now refuse, both reproduced:

```
  m_claimwidth     -> 6 rows
  n_continuation   -> 1 rows
  z_noshows        -> 0 rows                      ← honest zero, no shows written
  z_table_form     -> REFUSED: shows are struct literals, not a `table<Show>`
  z_reordered      -> REFUSED: 1 `Show {` written, 0 read
```

The lead found the first. **The second is worse and was beside it**: a row
whose fields are written in a different order is a *legal row in this
format* that the parser silently dropped. Both are the trailing-newline
defect's class — an instrument correct about what it does, wrapped by a
consumer reading its silence as success — and the fix is the one already
applied to a malformed block: refuse, naming the shortfall and the required
order.

**`budget` counts SHOWS, never characters or lines.** That is §6.3 as an
API rather than a warning: a program cannot be truncated, so the atom is
the whole show. Selection is round-robin across features, so **every
feature gets a show before any feature gets a second** — the only part of
the policy the format itself demands. `order` re-sorts *within* a feature
and is a hook, not a decision: **which** shows beyond the first is exactly
what the cold-start gate is for.

**PROBED — the completeness invariant holds at every budget:**

```
 budget  shows out  features present  invariant
      1          1                 1  n/a (budget < features)
      2          2                 2  n/a (budget < features)
      3          3                 3  OK — every feature present
      4          4                 3  OK — every feature present
      7          7                 3  OK — every feature present
      8          7                 3  OK — every feature present
```

**AND IT EXPOSES A FLOOR THE VISION DOES NOT HAVE.** Completeness is
unsatisfiable below one show per feature, so a complete brief has a hard
minimum. Measured over the seven shows written here — 87/127/158 chars
min/median/max, 3–5 lines:

```
28 features × 127 chars (median) = 3556 chars ≈ 889 tokens at 4 chars/token
```

**So "complete at every budget" is false below roughly 900 tokens, and
Part III's 800-token example sits just under its own floor.** The *shape*
of that number is exact — floor = feature count × median show — but the
number itself is an **EXTRAPOLATION from seven shows I wrote, not from 28
features' worth**, and it moves with whatever the real rows look like. The
honest statement for the vision is that the floor exists and is computable,
not that it is 889.

---

## 7 — The two rules the format imposes on authors

Everything else here is checkable by the harness. These two are not, and
they are where the format can lie while every check stays green. **Both are
authoring rules, and the second is one because of a RENDERING choice** — a
format's rendering decisions become constraints on the people writing rows,
and they belong where the author is, not in a rendering appendix.

### 7.1 The claim-width rule — the unmechanisable part

> **A CLAIM STATES WHAT ITS PROGRAM DEMONSTRATES, NEVER THE PROPERTY IT
> GESTURES AT.** A green row with an over-wide claim is `lexer_test.av:110`
> with a compiler behind it — **more convincing for being verified**, and
> wrong in exactly the way a reader cannot detect.

The verifier cannot reach it: it checks that the program does what the
`Expect` says, never that the *claim* is what the program shows. A row can
be green and teach something false.

**Two of my own first five rows were over-wide, and applying the rule is
how I found them.**

| first draft | what the program actually shows | narrowed to |
|---|---|---|
| "declares a **closed set**; `.variant` constructs" | an enum being declared and a variant constructed — **closedness is nowhere in it** | "`enum` declares variants; `Suit.clubs` constructs one" |
| "a range takes no methods — **comprehend instead**" | `.any` on a range being refused — **the remedy is not in the program** | "a range answers no methods" |

In both cases the missing half was real and belonged in a **different
row**: closedness is what the F2013 refusal demonstrates, and the remedy
is the comprehension show that now sits beside the refusal. **The rule
does not delete content; it relocates it to the program that earns it.**

A claim's honest width is the answer to: *if this program were the only
thing I saw, what would I have learned?* Write that.

### 7.2 A claim takes no em-dash

> **A CLAIM TAKES COLONS AND SEMICOLONS, NEVER AN EM-DASH.** The renderer
> spends the em-dash as its refusal separator — `✗ REFUSED F2013 — <claim>`
> — so a claim carrying one renders as two claims and the reader cannot
> tell which half is the verdict's.

It reads as a typographic nit and it is not: it is the **first instance of
a general obligation**, which is why it sits here rather than in §6. A
rendering choice reaches back and constrains authoring. The verdict-leading
layout is settled by §6.1's criterion, the separator is what makes it
scannable, and the cost of both is one character the claim may not use.

Its own instance, from my first draft: *"a range takes no methods — comprehend
instead"*, which §7.1 had already caught for a different reason. The em-dash
was doing the work a second show should do — which is the same lesson as
§7.1's, arriving through the punctuation instead of through the claim.

**The obligation this opens:** every future rendering that claims a
character — a separator, a marker, a fence — owes a rule here. The
alternative is a renderer that mangles a legal row and an author with no
way to know why.

---

## 8 — The format's scope, and what it refuses to hold

> **A CORPUS FORMAT IS A CLAIM ABOUT WHAT CAN BE VERIFIED, and every entry
> it cannot express is an unguarded hole wearing a green check.** 45 of 47
> reads identically to 47 of 47 unless the format says aloud what it
> declined to hold.

doc-subset's framing, adopted. **`Show.program` is ONE FILE**, compiled as a
lone program. That is the scope, stated rather than implied.

**Two subset entries fall outside it, and they fail DIFFERENTLY** — which is
the part that decides how the gate must behave. Both probed at `08f4638`:

| entry | as a single file | why it is excluded |
|---|---|---|
| **`export use`, a re-export** | `error[F3015]: this file is not in a package — `use` needs a root` | **MIS-EXPRESSIBLE.** A row claiming `Refuses("F3014")` fails honestly. But a row claiming `Refuses("F3015")` **passes** — and teaches that a re-export needs a package root, when the law is that `export use` arrives with a later slice. Green, and wrong. |
| **`const` in a module file** | compiles clean, exit 0 — the law never fires | **INEXPRESSIBLE.** A loose file IS the entry, so F0902 cannot arise. No honest single-file row exists. |

**The first is the dangerous one and it is why silence is not an option.**
An entry the format cannot express at all announces itself the moment
someone tries. An entry the format can express *wrongly* produces a green
row that teaches a false law — which is §7.1's failure mode arriving
through **scope** instead of through wording, and no check in §6.4 can see
it.

### The gate's obligation

**The gate NAMES its exclusions and FAILS on an entry that is neither
expressed nor named. It never skips.**

The exclusion list is a **registry, not a skip**: every excluded entry
carries its reason and its evidence, and adding to it means writing both.
That is THE EXEMPTION LAW at corpus scale — an exemption not written at the
site is an unbounded amnesty — and it is what stops "2 excluded" from
drifting into "however many we could not be bothered with". The gate's line
reads `45 expressed, 2 excluded (named)`, never `45 passed`.

### Why a second shape is not being added yet

A package fixture — `files: List<ShowFile>` behind a `Source` enum, the
`Expect` trick again — would hold both entries and cost every one of the
other 45 rows a wrapper for a 4% case. **That is ceremony charged to the
common case before the cold-start number has said whether these two entries
teach anything at all.** MEASURE THEN CHANGE, the same principle holding
steps 1–3.

So: **an explicit refusal now, with the second shape named as the known
extension and the two entries named as the reason to build it.** The
decision is reversible in one direction only — adding the shape later costs
a migration of 45 rows, which is why it waits for evidence rather than
guessing. This is the third keeper-scope defect in this tree after `make
vocab` and the externs fixture, and the first that would have shipped
knowingly; naming it is what makes that not the case.

---

## 9 — Left unverified

- **That the harness works.** "Every show compiles and runs at gate time"
  is a design claim. Running a show means compiling a program from a
  string at gate time, which is a package-scale operation I cannot run
  under this lane's constraints. **UNVERIFIED** — it is step 4 and it
  should be measured, not assumed.
- **Whether `"""` survives inside a `component` config block.** Probed in
  a `fn` body and in a `table`, not in `component LanguageFeature f {
  shows = [...] }`. One `./avra check` settles it; it needs the feature
  type in scope, so it is a package-shaped probe rather than a scratch
  one.
- **How many shows a feature actually needs** before the brief is
  complete, and **what a row must carry**. That is the cold-start gate's
  question. Per the lead's re-sequencing, the gate runs FIRST and its
  failure attribution decides both — building `shows` before the number
  would be designing the format around a guess about what teaches.
- **The row shape against the REAL `LanguageFeature`.** The lead settled
  the structural half at `6a3a084`: a raw block, an enum payload and a list
  of struct literals all survive inside a `component` config assignment
  (`check` and `run` both clean, answering `2 enums`). That was a **locally
  defined** component, so the language accepts the shape; it does not prove
  `Show`/`Expect` exported from `features/mod.av` and imported by 28 feature
  files. **The format is not dead** — that was the question — and the
  remaining half is package-shaped and still needs the lock.
- **That an `Answers` row answers what it says.** §6.4's harness proves
  every refusal completely and every answer only halfway: `check` reaches
  "it compiles", and "it prints `0`" needs a run.
- **The `@std` mining estimate.** Lane B's 638 `then` cases are candidate
  rows; how many convert cleanly is unmeasured.
