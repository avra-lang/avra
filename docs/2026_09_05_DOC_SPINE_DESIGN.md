# The doc spine — D1, D2, D3, landable

> **Status:** design, worked against the real tree. Every claim below
> names its artifact. Probes are marked **PROBED** (output quoted),
> **READ** (a mechanism read from source, file:line given), or
> **UNVERIFIED**.
>
> **Base: `312bd0d`**, `build/avra` 2026-09-06 00:10 (2 064 272 bytes).
> **The tree moved twice under this design and the binary moved once.**
> The first draft was probed at `e046ba2` against a binary of 2026-09-05
> 23:40 (2 064 224 bytes); the lead's brief quoted `bd5c024`; HEAD is now
> `312bd0d`. Every line number and every probe below was re-derived at
> `312bd0d` against the binary standing now. This is the
> version-attribution law doing its job three times in one session — a
> receipt from any of those three bases is a historical document.
>
> Implements rungs D1–D3 of `2026_09_05_DOCUMENTATION_VISION.md`
> Part VIII. Five findings change that document's Part V; they are
> collected at §5. Section A is a live defect found while probing and
> is not part of the spine.

---

## A — PROBED FIRST: the line law, and a live defect in the code D1 touches

Written before any design prose, on the lead's instruction and lane A's.
The line law lives inside `collapse_breaks` (`lexer.av:362`) — the exact
function D1's change sits next to — so if capturing doc runs shifted a
break, every multi-line expression in the tree would change meaning
silently and all at once.

### A.1 The harness

Each shape is one program written three ways: the marker line **absent**,
the marker line as a **plain `//`**, and the marker line as a **doc
`///`**. Three shapes (`s2`, `s3`, `s4`) are chosen so the two candidate
parses differ in **validity** — if the break survived, the program is a
syntax error — so "the three agree" is a claim about the parse and not
merely "all three compile".

**The first harness reported a false difference and I nearly explained
it.** It diffed the rendered diagnostics, which carry line numbers, and
inserting a comment line necessarily shifts them: `s8` reported
`none≠plain` because one said `:2:5` and the other `:3:5`. Same code,
same column, same token. The instrument was wrong, not the tree — which
is "MEASURE WHAT A THING DOES BEFORE EXPLAINING WHY TWO DIFFER" catching
its own author. The harness now normalizes `:<line>:` and the gutter, and
compares exit codes separately.

### A.2 Result — the eight shapes agree

```
SHAPE                              none   plain  doc     VERDICT
s1_comment_only_line               0      0      0       AGREE
s2_after_continuing_op             0      0      0       AGREE
s3_inside_parens_after_comma       0      0      0       AGREE
s4_only_line_in_list               0      0      0       AGREE
s5_before_closing_brace            0      0      0       AGREE
s6_before_else                     0      0      0       AGREE
s7_before_chain_step               0      0      0       AGREE
s8_deeper_indent_after_value       1      1      1       AGREE
```

**The comment-only line stays a blank line** (`s1`), and it stays one for
`///` exactly as for `//` — the tree's own claim at
`grammar/tests/lexer_test.av:110`, re-confirmed at `312bd0d`. Under D1
that cannot change, because a doc line still emits no token and the
newline after it still becomes a Break, exactly as today (§1.4).

### A.3 THE DEFECT: a leading comment changes the parse, by its LENGTH

While probing `line_indent` I found a live bug at `312bd0d`. It is not
caused by D1 and D1 does not fix it, but it lives in the function D1
touches and it fires on this tree's own house style.

`collapse_breaks` seeds the enclosing line's indent from a **byte
offset** and then compares it against a **character distance**:

```
365:    mut line_indent = if raw.is_empty() { 0 } else { raw[0].span.lo }
372:            let next_indent = if j < raw.length { raw[j].span.lo - raw[j - 1].span.hi } else { 0 }
374:            if boundary(raw, j) && ... && !continued_by(raw, j, next_indent > line_indent, out.last()!) {
375:                line_indent = next_indent
```

`next_indent` is correct — a Break spans exactly its newline, so
`raw[j].span.lo - raw[j-1].span.hi` is the next line's indent. The
**seed** is not: with no leading comment `raw[0]` is the first real token
at offset 0, but with one, `raw[0]` is the Break ending the comment line,
whose `span.lo` is that line's **length**. Leading breaks never push
(`out.is_empty()`), so `line_indent` is never corrected until the first
break that *does* push — and that first decision is made in the wrong
unit.

**PROBED.** The `.name` chain-continuation rule reads
`deeper = next_indent > line_indent`, so it flips:

```
$ printf '"  x  ".trim()\n    .length\n'              > lead_none.av
$ printf '//! leading\n"  x  ".trim()\n    .length\n' > lead_bang.av
none         EXIT=0
plain        EXIT=1 error[F2043]: `.length` needs a known enum — nothing here says which
doc          EXIT=1 error[F2043]: ...
bang         EXIT=1 error[F2043]: ...
```

Without a leading comment the two lines are one method chain. With any
leading comment — `//`, `///`, or the `//!` **every file in this tree
carries** — the break survives, `.length` becomes its own statement, and
it parses as a bare variant literal.

**The mechanism was confirmed by a discriminating prediction, not by
reading.** If the seed is the comment line's length, the bug must depend
on that length: a leading comment shorter than the continuation's indent
must leave the chain intact. Continuation indent is 4, so the flip must
fall between 3 and 4 characters:

```
leading "//"         len=2   exit=0
leading "//a"        len=3   exit=0
leading "//ab"       len=4   exit=1
leading "//abc"      len=5   exit=1
leading "//abcd"     len=6   exit=1
leading "//abcdefgh" len=10  exit=1
```

Exactly at the predicted boundary. **A method chain's continuation
depends on the length of the file's first comment.**

And it reaches a realistic file in this tree's own style:

```
$ cat real.av
//! A module header, exactly as every file in this tree carries one.
let words = "  alpha beta  ".trim()
    .split(" ")
let z = words.length

$ ./avra check real.av
error[F2043]: `.split` needs a known enum — nothing here says which
  ╭─[real.av:3:5]
3 │     .split(" ")

$ sed '1d' real.av > real_noheader.av && ./avra check real_noheader.av; echo $?
0
```

**Blast radius.** `line_indent` is only stale until the first *pushed*
break, so exposure needs a `.name` continuation at a file's first pushed
break. Real files open with `//!` then `use` lines, and no `use` is
followed by a chain step, so the tree is not currently mis-parsed —
`make gate` is green and the corpus pins the meanings. The exposure is an
**entry file whose first statement is a chain**, which is what `real.av`
above is.

**This is not D1's to fix.** The one-line correction (seed the indent as
a column, i.e. 0, since leading breaks always drop) changes how existing
sources parse, so it is a slice with its own gate and its own corpus
case. Riding it on D1 would mean a doc-comment change and a layout change
landing together — and if anything then broke, neither could be
exonerated. **Flagged to the lead as its own slice.**

**What it does mean for D1** is that the wording "a comment is
whitespace" is *false today* and must not be written into the design. The
tree's own test says a comment-only line is a blank line
(`lexer_test.av:110`) and that is true for **break counting**; it is not
true for the **`line_indent` seed**. D1's invariant is narrower and
provable: the doc path leaves `s.token` null, so `raw` is byte-identical,
so every layout decision — including this defective one — is bit-for-bit
what it is today.

---

## 0 — What ships before D1: `avra doc <feature>`

**`features/mod.av:115` declares `docs: string = ""`. Nothing in the
tree reads it.**

```
$ grep -rn "\.docs" --include="*.av" packages/
$ echo $?
1
```

Twenty-eight features fill it (one `docs =` per feature `mod.av`; the
list is `language/mod.av:118`'s `language_features()`), and
`commands/new.av:147` scaffolds `docs = "TODO: the one-line surface."`
into every new one — the tree asks for the string at birth and has
never once read it back.

**Correction to the vision's presenting fact.** It says *"28 of the 29
features fill it in."* There are **28 features**, and **28 of 28** fill
it — 100%, not 96.6%. `packages/std-avrac/src/features/` holds 29
directories, but `features/tests/` is a test directory
(`facts_test.av`, `mod_test.av`), not a feature; it appears in no
`language_features()` row.

### The change

`LanguageFeature` already carries everything a feature page needs:
`name`, `docs`, `gram: Grammar` (`features/mod.av:112-124`), and
`diags: List<DiagCode>`. `render_grammar(g: Grammar) -> string`
(`grammar/render.av:8`) renders any `Grammar`, merged or fragment —
`avra grammar` calls it on the merged one (`commands/grammar.av`),
and a feature's own `f.gram` is the same type.

So `packages/cli/src/commands/doc.av`:

```avra
//! `avra doc <address>` — one answer, from the compiler's own
//! registries.
use @std.cli.{Subcommand, CliResult, Runnable, ArgDef}
use @std.avrac.language.{avra}
use @std.avrac.features.{LanguageFeature, MethodRow}
use @std.avrac.grammar.{render_grammar}
use @std.avrac.diagnostics.{DiagCode}
use @std.io.{println, eprintln}

type DocCmd = { }

impl Runnable for DocCmd {
    fn run(args: CliResult) -> int { resolved(args.arg("address")) }
}

/// THE RESOLVER, in the old spec's order: project symbol, language
/// feature, diagnostic code, method, then the miss. Only the arms
/// whose registry exists today are spelled; each new arm is a
/// function, never a widening of this one.
fn resolved(q: string) -> int {
    let feature: LanguageFeature? = avra().features.find(it.name == q)
    if feature != null { return feature_page(feature!) }
    let code: DiagCode? = avra().rows.codes.find(it.id == q || it.kind == q)
    if code != null { return code_page(code!) }
    let method: MethodRow? = avra().rows.methods.find(it.name == q)
    if method != null { return method_page(method!) }
    unknown(q)
}
```

`avra()` is a `once fn` (`language/mod.av:171`) — the assembly is one
value the process shares, and `avra grammar` already pays for it.
This command opens **no workspace, no Program, no `phased`** — it is
an `arg_command` like `explain`, and it answers in the time
`avra grammar` takes.

**It is shippable today, before D1, and it retires the loaded spring
for the 28 language features.** It is also the file every later rung
edits: D1 adds nothing to it, D2 adds the symbol arm, D3 adds the
projections.

One shape to fix now, while it is one file: `resolved` grows by a
**named function per arm**, never by widening an existing arm. The
registry law does not reach it literally — that law is about `_ ->`
over our own enums, and this is an if-ladder over four different
tables — but the failure it names is the same one available here: an
arm that quietly answers for an address kind it was not written for.
`unknown(q)` is the only fallthrough, and it says what it searched.

---

## 1 — D1: the lexer keeps doc runs

### 1.1 Where it is

`grammar/lexer.av:312`, one arm of `scan_step`'s `when`:

```avra
        // `//` comment: whitespace to end of line — the newline
        // itself still arrives as layout.
        c == 47 && i + 1 < n && src.char_code(i + 1) == 47 -> skip(line_end(src, n, i))
```

(The vision cites `lexer.av:310`; it is 312 at `e046ba2`.)

### 1.2 One scanner, confirmed

**READ.** `scan_step` (`lexer.av:303`) is called from exactly one
place, `lex_with` (`lexer.av:435`), which both flavors enter:
`lex_grammar` = `lex_with(src, rule_boundary, false)` (`lexer.av:502`),
`lex_source` = `lex_with(src, line_boundary, true)` (`lexer.av:513`).
The comment arm is not behind `interpolate` or any other mode. So
**yes, still one scanner, and doc capture necessarily applies to both
flavors.**

**What that costs: nothing.** `lex_grammar` is called from
`parse_grammar` (`grammar/parse.av:12`), which reads only
`lexed.tokens` and `lexed.errors` — a third field on `LexResult` is
invisible to it. And no grammar fragment in the tree contains a doc
marker:

```
grammar blocks containing /// or //!: 0 []
```

(measured by walking every `grammar {` block in `packages/**/*.av`
with a brace counter that skips string literals — the same rule
`scan_raw_block` uses at `lexer.av:134`.)

### 1.3 The smallest change: a third channel on `ScanStep`

`ScanStep` (`lexer.av:93`) is `{ token: Token?, err: LexError?,
opens_hole: bool, next: int }` — the scanner's whole output contract.
It gains a fourth:

```avra
/// One doc line the scanner kept: `///` (a declaration's) or `//!`
/// (the file's), over the span its marker opened. TEXT IS NOT HELD —
/// the span indexes the SourceFile every reader already has, so the
/// compile path pays no allocation for a comment it will not read.
export type DocLine = { file_level: bool, span: Span }

type ScanStep = { token: Token?, err: LexError?, opens_hole: bool, doc: DocLine?, next: int }
```

`LexResult` (`lexer.av:63`) gains the list:

```avra
export type LexResult = { tokens: List<Token>, errors: List<LexError>, docs: List<DocLine> }
```

The comment arm splits into two, anchor-first:

```avra
        // A DOC LINE — `///` or `//!` — is whitespace the scanner
        // REMEMBERS. It emits no token, so layout cannot see it; the
        // run it belongs to, and what that run describes, are the
        // docs query's law and never the lexer's.
        c == 47 && doc_marker(src, n, i) != null -> doc_line(src, n, i),
        c == 47 && i + 1 < n && src.char_code(i + 1) == 47 -> skip(line_end(src, n, i)),
```

with three new leaves beside `emit`/`skip` (`lexer.av:96,101`):

```avra
/// The third character of a doc marker — `/` for a declaration's
/// run, `!` for the file's — or absence for a plain comment.
fn doc_marker(src: string, n: int, i: int) -> int? {
    if i + 2 >= n || src.char_code(i + 1) != 47 { return null }
    let c = src.char_code(i + 2)
    if c == 47 || c == 33 { return c }
    null
}

/// The doc line starting at `i`, to end of line.
fn doc_line(src: string, n: int, i: int) -> ScanStep {
    let hi = line_end(src, n, i)
    kept(DocLine { file_level: doc_marker(src, n, i)! == 33, span: span_of(i, hi) }, hi)
}

/// A step that produced a doc line and no token.
fn kept(d: DocLine, next: int) -> ScanStep {
    ScanStep { token: null, err: null, opens_hole: false, doc: d, next: next }
}
```

`doc_marker` is guarded by `c == 47`, so it runs at the tree's 1 534
plain comments, 6 894 doc lines and division sites — **not once per
character**, which is what the file's own note at `lexer.av:276-279`
warns about (*"this is the scanner's inner loop"*). It is named once
and read twice, which is the idiom bar's rule 3, not a violation of
it.

and `lex_with` grows one push and one field:

```avra
    mut docs: List<DocLine> = []
    ...
        if s.doc != null { docs.push(s.doc!) }
    ...
    LexResult { tokens: tokens, errors: errors, docs: docs }
```

**Total edit surface: 7 `ScanStep {}` literals** (`lexer.av:97, 102,
112, 161, 183, 260, 266) taking `doc: null`, **one struct field, three
new leaf fns, one new type, one arm, one push, one `LexResult`
field.** Nothing
else in the tree constructs either struct — `LexResult` is built once,
at `lexer.av:485`.

### 1.4 Why layout cannot change — a proof, not a hope

**READ.** In `lex_with` (`lexer.av:435-486`) the token list `raw` is
written at exactly one site:

```
461:        if s.token != null { raw.push(s.token!) }
```

`s.token` is `null` on the doc path (`kept` above), exactly as it is
today on the `skip` path. Every layout decision reads `raw`:
`collapse_breaks(raw, boundary)` (`lexer.av:477`), and inside it
`continues(out.last()!)`, `continued_by(raw, j, …)`, `opened`,
`separates`. **`raw` is byte-identical before and after the change, so
`tokens` is byte-identical.** The other three readers of `s.token` in
`lex_with` — `in_hole` (braces only), the Break check, and
`opens_grammar` — all test `s.token`, which stays null.

That is the whole reason to put the doc on its own channel rather than
give it a `TokenKind`. A `TokenKind.Doc` would cost only one arm
(`lit_matches`, `lexer.av:34`, is the tree's **only** exhaustive match
over `TokenKind` — checked), but it would put a doc value *into the
token stream*, where the layout rules are, and the safety would then
rest on every path remembering to divert it. A typed side channel
cannot leak.

### 1.5 What breaks — probed, and the answer is nothing

The lead flagged: *"A comment-only line is currently a blank line —
does capturing trivia change that?"*

**Under this design, no, by §1.4.** But the baseline was probed anyway,
because the four comment tests in `grammar/tests/lexer_test.av:101-121`
are what will be asked to keep passing:

| test | asserts | survives? |
|---|---|---|
| `lexer_test.av:102` | `//` is whitespace in BOTH lexers — counts Name and Op tokens | yes, `raw` unchanged |
| `lexer_test.av:110` | `count_breaks(lex_source("a\n// note\nb")) == 2` — a comment-only line is a blank line | yes, and `//` is not even a doc marker |
| `lexer_test.av:113` | a comment at end of input needs no newline | yes |
| `lexer_test.av:118` | a lone `/` is division | yes — `doc_marker` requires two more characters |

**The layout probes are §A**, which supersedes an earlier and weaker
version of them: eight shapes, each written three ways (absent / `//` /
`///`), three of them chosen so the alternative parse is a syntax error.
All eight agree. **Those eight, spelled with `///`, are D1's required new
tests** — they are precisely the cases that fail if a later change ever
routes a doc line into `raw`. Per K0, D1 also ships the fixture that
*makes* the guard fail: a `///` pushed into `raw` must turn them red.

§A also records why the answer here is "nothing breaks" rather than "a
comment is whitespace": at `312bd0d` a comment is **not** whitespace —
a leading one changes the parse (§A.3). D1's invariant is the narrower,
provable one from §1.4, and it holds over the defect as well as over the
correct behaviour.

**One token-count assertion exists** —
`lexer_test.av:196`, `lex_source("9223372036854775808").tokens.length
== lex_source("1").tokens.length` — and it holds a number-literal
claim, not a comment one. No golden in the tree asserts a token count
for a commented source.

### 1.6 Two hazards the lexer already handles, and one it reveals

**A doc marker inside a raw string is not a doc line.** `scan_triple`
(`lexer.av:175`) swallows `"""…"""` whole before `scan_step` ever sees
the interior. The tree has exactly one `//!` that is not at a file
head — `packages/cli/src/commands/new.av:171` — and it is inside a
`"""` template that scaffolds a new feature's `semantics.av`. A
line-oriented text scanner reads that as a file-level doc comment for
`commands/new.av`. The lexer does not, for free.

**A doc marker inside a `grammar { … }` block is not a doc line.**
`scan_raw_block` (`lexer.av:134`) takes the block's body to its
matching brace as one `Str` token. Zero such markers exist today, and
after D1 they still would not reach `scan_step`.

**LANE B's measurement holds, its reason does not — and the difference
is a test D1 must keep.** Lane B reports that no `///` or `//!` appears
inside a `grammar { … }` **or** a `table<Row> { … }` literal anywhere in
the packages, and gives the reason that "those two sub-languages lex
their own bodies". Both halves of the measurement reproduce here at
`312bd0d` — `grammar` literals: 0, `table<Row>` literals: 0 — but only
`grammar` lexes its own body. `opens_grammar` (`lexer.av:122-128`) fires
on one word:

```avra
    before.kind == TokenKind.Name && before.text == "grammar"
```

A `table<Row> { … }` body is lexed **normally**, character by character,
by the same `scan_step`. So a `///` written inside a table literal *would*
become a doc line under D1. It is zero **by measurement**, not zero **by
construction**, and the two are not interchangeable: an implementer who
took lane B's reason at face value would skip the test that is actually
load-bearing. D1 ships a case putting a `///` inside a `table<Row>` and
pinning what happens to it (it is trivia inside a declaration's span, so
§2.3's member rule holds it and F0911 stays silent).

Together these are the argument for D1 over "parse the comments with a
script": **the lexer is the only thing in the tree that already knows a
comment from a string.**

### 1.7 Cost

**Space.** 6 894 doc lines in `packages/**/*.av` (5 488 `///`, 1 406
`//!`) across 336 files — ~20.5 per file. Each is a `DocLine` of a
bool and two ints. **No string is minted.**

This is a deliberate divergence from the vision, which asks for *"a
span and its raw text"* (Part V ¶1). Holding the text would mint ~6 900
string boxes **on every parse of every file, on the compile path,
where nothing reads them** — `avra check`, `avra build` and `make gate`
would all pay for `avra doc`. The span indexes `SourceFile.text`
(`diagnostics/source.av:6`), which every reader of `Parsed` already
holds (`Parsed.source`, `language/program.av:36-41`), so the docs query
slices the text out **only when someone asks for a page.** P6: neither
lossless-ness nor a free compile path has to be given up.

That also settles the vision's Part IX ask *"String interning for doc
text — 690 doc strings will be minted per parse"*: **the ask is
withdrawn, because the minting is.**

**Time.** One extra `char_code` per `//` occurrence — 1 534 plain
comments plus 6 894 doc lines tree-wide. Not measurable. **UNVERIFIED
by measurement** — a lane holding the lock should confirm with
`make census CMD="check packages/std-avrac"` before and after, per
MEASURE-THEN-CHANGE; the prediction is "inside the noise."

### 1.8 How the doc lines reach `Parsed`

`Parsed` (`language/program.av:36-41`) gains one field:

```avra
export type Parsed = {
    store: NodeStore,
    stmts: List<StmtId>,
    source: SourceFile,
    // the file's doc lines in source order, uninterpreted: the
    // lexer learned one character, and every rule about them is
    // the docs query's
    docs: List<DocLine>,
    voices: Voices,
}
```

`Parsed` is constructed at exactly two sites, both in
`language/program.av` (lines 60 and 67) — the empty case takes `[]`,
the real one takes `lexed.docs`. **PROBED:**

```
$ grep -rn "Parsed {" --include="*.av" packages/
packages/std-avrac/src/language/program.av:60:        return Parsed { store: ..., stmts: [], source: src, voices: ... }
packages/std-avrac/src/language/program.av:67:    Parsed {
```

(the other four hits are `-> Parsed` return types.)

This obeys the doctrine: doc lines are a **lexical fact of the file**,
parse-owned like `source`, so `Parsed` is their home; `NodeStore` never
sees them, and no pass fact accretes onto it.

---

## 2 — D2: `docs(ws, f: FileId) -> DocFacts`

### 2.1 The cost of the fourteenth family — every site

`Family` (`language/workspace.av:114-129`) has thirteen rows today, and
the enum is guarded by two exhaustive matches by design (its own doc
comment: *"both exhaustive, so a new family cannot ship
half-registered"*). Adding `Docs` after `Folded` costs exactly:

| # | site | edit |
|---|---|---|
| 1 | `workspace.av:114` `enum Family` | one variant |
| 2 | `workspace.av:135` `fn ordinal` | one arm — **and renumber `Analysis`…`Receivers`** |
| 3 | `workspace.av:156` `fn families()` | one element, in ordinal position |
| 4 | `workspace.av:262` `fn refetched` | one arm: `.Docs -> touch(docs(ws, file_at(arg)))` |
| 5 | `workspace.av:59` `type Workspace` | one field: `doc_facts: Table<DocFacts>` |
| 6 | `workspace.av:196` `fn built` | one initializer: `doc_facts: new_table()` |
| 7 | `workspace.av` (new) | the query fn itself |

Seven sites, four of them one line. The ordinal renumbering is not
optional and not risky: `built` (`workspace.av:207`) refuses at
startup if the registration order and `ordinal` disagree —
`"defect: the families registered out of ordinal order"`. **The
existing keeper catches a botched renumber; nothing else needs to.**

`docs` may sit anywhere after `Items`. Placing it at ordinal 10 (after
`Folded`, before `Analysis`) keeps the enum in pipeline order, which is
what its doc comment promises.

**THE `disarmed` QUESTION, and the answer is: no fourth line.**
`disarmed` (`workspace.av:223-230`) is a hand-written list of this
workspace's cycle sources, and the lead is right that a hand-written
registry silently forgetting its next member is the law this campaign
keeps meeting. But its membership rule is narrower than "every table":

```avra
export fn disarmed(mut ws: Workspace) {
    ws.db.disarm()
    ws.decls.disarm()
    // an Analysis holds a closure over `ws`: the table of them is
    // the second loop through the same box
    ws.analyses = new_table()
    ws.closed = true
}
```

The comment names the rule: `ws.analyses` is cleared **because `Analysis`
holds a closure**, and it does — `program: fn() -> Program`
(`language/analysis.av:18`), the only `fn` field in the struct. The
Workspace's **thirteen other** value tables (`sources`, `manifests`,
`externs`, `programs`, `file_items`, `module_names`, `visibles`,
`name_facts`, `sig_voices`, `decl_facts`, `method_clashes`, `folds`,
`units`) are pure data and none is cleared.

`DocFacts` as designed in §2.2 is pure data — a nullable run, two
tables of runs, and `Voices`. **So the doc table joins its thirteen
data-only siblings and `disarmed` does not change.** The family's
*verifier* does close over `ws`, and that is discharged by
`ws.db.disarm()`, the first line, at no cost to this design.

The lead's directive — *"put the doc table inside `ws.db` if you possibly
can"* — cannot be followed, and should not be: the kernel's own contract
forbids it. `query/db.av:14`: *"Values live in the families' own typed
tables; the kernel holds only bookkeeping."* Putting a typed value table
inside `Db` would make the kernel language-aware.

So the landmine is not armed — **but it is worth naming the rule at the
site**, because that is what makes it stay unarmed. The line D2 should
add to `disarmed`'s comment is the membership test, not a doc entry:

> this list is not every table — it is every table whose VALUE holds a
> closure over `ws`. A table of plain data cannot make a cycle.

**The invariant this design owes back:** `DocFacts` holds data only. The
day it gains a lazily-computed field backed by a closure over `ws` — a
`render: fn() -> string`, say — it joins the list, and nothing but this
sentence will say so.

> **Cheaper alternative, and why it is refused.** `docs` could be a
> plain memo-free function over `parsed`+`items`. It would work and
> cost one file. It is refused because the vision's thesis is that
> documentation is a *compile target on the same engine* (Part II), and
> because §2.4 below is a memo-kernel correctness property that only
> exists if `docs` is a real cell.

### 2.2 The value

```avra
/// One doc run: consecutive doc lines of one marker kind, and what
/// they describe. `text` is sliced from the SourceFile on demand,
/// never held by the parse.
export type DocRun = { file_level: bool, lo: int, hi: int }

/// A file's docs: the file's own run, each declaration's, and the
/// runs that describe a MEMBER — an enum variant or a struct field —
/// which has no id to key by yet. Keyed by DeclId, per the side-table
/// law; `voices` are this pass's own.
export type DocFacts = {
    file: DocRun?,
    by_decl: Map<int, DocRun>,        // DeclId.index -> its run
    members: Map<int, List<DocRun>>,  // enclosing DeclId.index -> runs inside it
    voices: Voices,
}
```

`by_decl` is keyed by `DeclId.index` rather than by `DeclId` because
`Map` is string-keyed today (`features/maps` — `m.get(k)` answers
`T?`); the honest shape is a dense `List<DocRun?>` by `DeclId.index`,
which is what every other fact table in the tree is
(`decls.av:44-49`). **Use the dense list.** The `Map` spelling above is
illustrative only.

### 2.3 The attachment law, and the 155 runs that break the naive one

The vision states: *"a `///` run attaches to the next declaration that
starts after it with no blank line between… A run attached to nothing
is `F0911`."*

**Measured against the tree, that rule fires F0911 at 156 sites, and
155 of them are correct doc comments.**

```
doc runs by what follows: {'run_to_decl': 2279, 'run_to_export': 782,
                           'run_to_nondecl': 156, 'run_to_blank_or_eof': 1}

non-decl doc runs by target shape:
   145  variant
    10  field
     1  other: use features.{MethodCall, arm_end, open_...

files holding field/variant doc runs:
    59  packages/std-avrac/src/core/nodes.av
    19  packages/std-sqlite/src/error.av
    19  packages/std-avrac/src/core/ir.av
    18  packages/std-avrac/src/core/types.av
    13  packages/std-process/src/process.av
     7  packages/std-sqlite/src/open.av
```

(counted by walking every `.av` under `packages/`, grouping consecutive
`///` lines into runs and classifying the next non-comment line. Each
count is a unique `file:line`, so this is sites, not lines.)

**Why they cannot attach: enum variants and struct fields have no
`DeclId` and no span.** `DeclKind` (`core/nodes.av:111-124`) has ten
variants — `Builtin, Fn, Record, Enum, Trait, Method, Default, Impl,
Main, Case`. A record's field **default** is a declaration
(`DeclKind.Default`); the field itself is not. And the node shapes
carry no span:

```
core/nodes.av:358: export type Variant = { name: string, payloads: List<Param> }
core/nodes.av:335: export type Param   = { name: string, ty: TypeRef?, default: ExprId?, mutable: bool }
core/nodes.av:449: StructDecl(name: string, tparams: List<string>, fields: List<Param>)
core/nodes.av:453: EnumDecl(name: string, tparams: List<string>, variants: List<Variant>)
```

Attaching a doc to a variant is therefore a **node-model change** —
mint a `VariantId`/`FieldId` and a span side table (spans must not go
on the node: `core/nodes.av:3-5`, *"Every per-node fact — span, content
fingerprint, later types — lives in a side table keyed by the id, so a
node's identity is the hash of its structure alone"*). That is a
different-sized slice than D1+D2 and it is **not in this design.**

**The collapse (P6).** The choice is not "156 false warnings" versus
"drop 6.4% of the corpus". A run *inside* a declaration's span is a
**member run**: recorded under its enclosing `DeclId`, addressable the
day members get ids, and silent today. So:

> **THE ATTACHMENT LAW.** A `//!` run attaches to the FILE. A `///` run
> attaches to the declaration whose span starts nearest after it with
> no BLANK LINE between. A `///` run that falls INSIDE a declaration's
> span is that declaration's MEMBER run — held, unaddressed, silent.
> A `///` run that is neither is `F0911`, and it is the shape a doc
> comment takes when the code it described was deleted.

Every term of that law is answerable from what exists:

- **the declaration's span** — `Decls.decl_span(d) -> Span?`
  (`features/decls.av:276`), already called from outside the module at
  `workspace.av:923`. **Note it is source BYTES, not the arena range:**
  `Decl.lo`/`Decl.hi` (`decls.av:24`) are **ExprId indices**, filled by
  `range_bodies` walking `0..store.exprs.count()` (`decls.av:242-259`).
  A design that reached for `Decl.lo` would compare a byte offset to an
  expression index and be silently wrong.
- **"starts after"** — a comment produces no token, and a rule's span
  is `consumed_span(tokens, entry, cursor)` =
  `tokens[from].span.cover(tokens[until-1].span)`
  (`grammar/executor.av:360,396-398`). **A span can never contain a
  comment.** PROBED — a diagnostic under a two-line doc run points at
  the declaration's own first token:

  ```
  $ cat p5.av
  /// doc
  export let bad = 1
  $ ./avra check p5.av
  error[F3014]: `export` marks a fn, type, enum or trait — not this statement
    ╭─[…/p5.av:2:8]
  2 │ export let bad = 1
    ·        ┬
  ```

- **"inside a declaration's span"** — the same `decl_span`. PROBED that
  a declaration's span reaches through its body: a record's field
  default at column 21 of line 2 is owned by a `Default` declaration
  nested inside the record's statement span, and the ownership is what
  makes F3020 fire there:

  ```
  $ cat p7.av
  let seed = 7
  type R = { n: int = seed }
  let r = R { }
  let z = r.n
  $ ./avra check p7.av
  error[F3020]: `seed` is a run-time binding of the top level …
    ╭─[…/p7.av:2:21]
  2 │ type R = { n: int = seed }
    ·                     ┬
  ```

- **"no BLANK LINE between"** — a text scan of
  `src.text.substring(run.hi, decl_lo)` for two newlines separated by
  whitespace only. Do **not** use `SourceFile.linecol`
  (`diagnostics/source.av:26-32`): it is a full loop over
  `line_starts` with no early exit, so line-number arithmetic here is
  O(lines) per run — 2 436 runs × thousands of lines.

**The blank-line wording is load-bearing, not stylistic.** Nine doc
runs in the tree are separated from their declaration by a plain `//`
line, and in every case it is `// LICENSED I<n>:` — THE EXEMPTION
LAW's required spelling, which must stay *at the site*:

```
runs with a plain // between run and decl: 9
    packages/std-avrac/src/grammar/lexer.av:352 (+2 plain // between)
    packages/std-avrac/src/core/lists.av:30 (+1)
    packages/std-avrac/src/features/mod.av:95 (+1)
    packages/std-avrac/src/features/mod.av:101 (+1)
    packages/std-avrac/src/features/decls.av:94 (+1)
    packages/std-avrac/src/features/enums/check.av:345 (+1)
    packages/std-avrac/src/features/enums/lower.av:21 (+1)
    packages/std-avrac/src/grammar/tests/executor_test.av:29 (+2)
    packages/std-avrac/src/grammar/tests/compose_test.av:11 (+2)
```

A rule spelled "on the immediately preceding line" detaches all nine
and forces the licence comment above the doc, which is the opposite of
what the exemption law demands. A rule spelled "no blank line between"
keeps both. There are **zero** cases of doc-run / plain-`//` / doc-run
in the tree, so no ambiguity about which run wins.

### 2.4 The stale-doc trap — a memo-kernel defect in the vision's design

**This is the finding that most changes Part V, and it is invisible
today.**

`parsed` settles on `program_hash` (`workspace.av:313,319-321`):

```avra
fn program_hash(p: Parsed) -> int {
    fp(17, [p.store.stmt_fingerprint(s) for s in p.stmts])
}
```

and a statement's fingerprint is structural, by design:
`core/nodes.av:3-5` — *"a node's identity is the hash of its structure
alone: reformatting never changes a fingerprint."* `alloc_stmt`
(`nodes.av:604-610`) pushes `fingerprint_stmt(s)`; the span goes to the
arena, never to the hash.

**So editing a doc comment does not move `parsed`'s hash.** And the
kernel's early cutoff (`query/db.av:155-163`) keeps `changed_at` when a
recomputed hash is unchanged, while `ask` (`db.av:106-119`) marks a
cell green when no dep's `changed_at` exceeds its own `verified_at`.

Trace it: edit a `///` line → `source`'s input hash moves → `parsed`
re-runs (its `ask` misses) and stores the **fresh** `Parsed`, doc lines
included, in `ws.programs` → but `settle` sees the same
`program_hash` and **keeps the old `changed_at`** → a `docs` cell whose
only dep is `Parsed` is marked green → **`docs` returns the previous
`DocFacts`, and `avra doc` prints the old prose.**

**The fix is one line, and it must carry the law:**

```avra
export fn docs(ws: Workspace, f: FileId) -> DocFacts {
    let k = key(Family.Docs, f.index)
    if ws.db.ask(k) is .Reuse { return ws.doc_facts.at(f.index)! }
    ws.db.begin(k)
    // A DOC EDIT MOVES NO STATEMENT. `parsed` settles on the
    // structural fingerprint, so a changed comment leaves its
    // changed_at where it was — a docs cell depending on `parsed`
    // alone would be green over stale prose. The TEXT is the
    // dependency.
    touch(source(ws, f))
    let p = parsed(ws, f)
    touch(items(ws, f))
    let out = attached(ws, f, p)
    ws.db.settle(k, fp(23, [run_print(p.source, r) for r in out.runs()]))
    ws.doc_facts.keep(f.index, out)
    out
}
```

**And once fixed it is strictly better than the vision claimed.**
Because `docs` settles on a hash of the doc *text*, and every other
family settles on structure, the two waves never cross: **editing a doc
comment re-runs `parsed` and `docs` and nothing else — not `items`, not
`sig`, not `typed`, not `lowered`.** The vision says *"change one
function and exactly one doc page re-derives"*; the true property is
also *"change one doc and nothing but the doc re-derives."*

**Why it is invisible today.** `disarmed` (`workspace.av:223-230`)
replaces every verifier with `never_verify` once an analysis has run,
and nothing edits a live workspace — `workspace.av:64-67` says so
directly: *"A host that changes under a running workspace (Era IV's
live editing) invalidates these with the revision; today no host
does."* So the revision never advances and the bug cannot fire. This is
CLAUDE.md's *"AN ASSUMPTION NOTHING HAS EVER TRIED TO VIOLATE IS NOT A
GUARANTEE"* exactly: green forever, wrong from birth, and the first
thing that tests it is Era IV. **D2 ships the K0 fixture that makes it
fail**: a two-revision memory-host test that edits only a `///` line
and asserts the new text comes back — and that same test, with
`touch(source(...))` removed, must go red.

### 2.5 The tag registry — where it lives

The vision puts `DocTag` rows on features, *"exactly as `DiagCode` rows
are today."* The parallel does not hold, and following it repeats the
`docs: string` mistake.

**READ.** `DiagCode` rows live in two places: `builtin_codes()`
(`language/codes.av:44`) — the **driver's** table, holding the engine's
five causes and ten pass codes — and `f.diags` per feature, holding
codes that feature **owns** (`features/enums/mod.av:32-41` registers
F2012/F2013/F2015/F2016/F2038/F2039/F2040/F2043, all of them enum
laws). `code_registry` (`language/mod.av:112`) concatenates them. A
feature contributes a row *because the row is that feature's law.*

**No feature owns `@warn`, `@see`, `@since`, `@unit` or `@example`.**
They are language-wide, exactly like `resolve.unresolved` in
`pass_codes()`. So:

- `doc_tags() -> List<DocTag>` is a `table<DocTag>` in the docs module,
  shaped like `pass_codes()` (`language/codes.av:26-41`).
- `LanguageFeature` gains **no** `doc_tags` field until a feature
  actually owns a tag. Adding a config field that 0 features fill is
  how `docs: string` got here.

The row shape survives from the vision, minus one field:

```avra
/// One doc tag: its word, where it may attach, what follows it, and
/// what `avra doc --tags` says about it. DATA, per the vocabulary
/// seam rule — five consumers query it and nothing dispatches on it.
export type DocTag = { name: string, attaches: TagSeat, arity: TagArity, summary: string }

/// Where a tag may sit. `Member` is an enum variant or a struct
/// field: it has no id yet, so a tag there is held and unaddressed.
export enum TagSeat { Decl, Member, File }
export enum TagArity { Prose, Ref, Word }
```

`TagSeat` drops the vision's `.Field`/`.Variant`/`.Param` split into
one `Member`, because §2.3 established there is nothing to tell them
apart by. Splitting it the day members get ids is a registry edit.

**`TagSeat` and `TagArity` are PROJECTION enums, not registries** — one
arm answers, and the catch-all is honest. Whoever writes the consumers
should count the answering arms before reaching for `_ ->` and should
re-count when a seat is added.

### 2.6 The voices

Two codes, and the F-code space has room at `F09xx` (used today:
F0900 defect, F0901 no-projection, F0902 entry-only — `codes.av:20,32,33`).

| code | kind | fires |
|---|---|---|
| `F0911` | `doc.orphan` | a `///` run describing nothing — inside no declaration, before no declaration |
| `F0910` | `doc.undocumented` | D6, not D2 — an exported declaration with no run. **Not in this slice.** |

**F0911's true-positive rate, measured before it ships** — which is
what CLAUDE.md demands of a lint, and what the vision's own F2040
paragraph asks for. Under §2.3's law, the tree-wide count is **one**:

```
packages/std-avrac/src/features/values.av:22
```

```
/// A fresh box, its slots pushed in order. `dst` is minted by the
/// caller, before the first instruction is emitted — registers are
/// numbered in emission order.
use features.{MethodCall, arm_end, open_region, const_int, const_bool, close_region_as}
```

That run sits above a `use` line. It describes `grown_box`
(`features/values.av:34`) — which is an `export fn` with **no doc of
its own**. It is a doc comment stranded by a code move, and it is
exactly the shape the vision predicted F0911 would catch. **One site,
one true positive, rate 100%.** That number is F0911's spec and must be
re-measured when the law moves.

**THE ATTACHMENT MUST EXCLUDE `DeclKind.Main`, and here is why.**
`Main` is minted with `stmts.first() ?? no_stmt()` as its statement
(`decls.av:217`), and `decl_span` returns `store.stmt_span(x.stmt)` for
every kind but `Builtin`, `Default` and `Case` (`decls.av:276-281`).
So **`decl_span(Main)` is non-null and is the FIRST STATEMENT's span**
— usually a `use` line. A `///` run above a file's first statement
would otherwise attach to a synthetic declaration named `main` that
spans one `use`, which is both wrong and invisible. `owns_a_range`
already excludes `Main` for the arena-range walk (`decls.av:269`); the
attachment excludes it for the same reason and says so at the site.

*(values.av's own run survives as a true positive either way — its
first statement is `use core.{…}` at line 14, before the run at line
22 — but that is the file's layout, not the law.)*

### 2.7 The coverage number, for D6's baseline

The vision says *"890 exported symbols. 690 of them — 78% — already
carry a `///` doc comment."* Measured at `e046ba2`:

| | |
|---|---|
| `export` declarations (grep, `packages/**/*.av`) | **978** |
| — of which `export extern fn` | 85 |
| — the rest (`fn`/`type`/`enum`/`trait`/`component`/`once fn`) | 893 |
| with a `///` run directly above (plain `//` lines skipped) | **782** |
| coverage | **80.0%** |
| debt | **196** |

These are **text counts, not `items()` counts** — they are the right
order of magnitude for planning D6's ratchet and the wrong number to
put in the ratchet itself. D6's baseline must be produced by the
compiler, over `DeclId`s, listing **sites and never counts**
(DOGFOODING's first law). Methods inside exported impls, which have
`DeclId`s and are part of a package's surface, are in neither figure.

### 2.8 The freshness door exists — and it is NOT the docs family's hash

Lane C is right that D7 must not invent a hash, and **one detail of its
message is wrong in a way that would not compile.**

**Verified at `312bd0d`.** `fn stmt_fingerprint(id: StmtId) -> int`
exists at `core/nodes.av:664`, is exercised by nine assertions in
`core/tests/nodes_test.av:112-164`, and is maintained: `restamp(s, tag)`
(`nodes.av:637-639`) folds a mark into an existing fingerprint, called
from `mark_mutating` for `mut fn` (`nodes.av:616`) and from `mark_once`
for `once fn` (`nodes.av:627`) — exactly the two marks lane C named, and
the reason two declarations differing only by a mark stopped hashing
alike.

**The correction.** Lane C says *"`decls.decl(d).root` gives the root
`StmtId`"*. It does not — `Decl.root` is an **`ExprId?`**, "the
expression a body IS"; the statement is `Decl.stmt`:

```
decls.av:24: export type Decl = { id: DeclId, file: FileId, stmt: StmtId, name: string,
                                  kind: DeclKind, exported: bool, owner: string,
                                  parent: DeclId?, nested: bool, root: ExprId?, lo: int, hi: int }
```

The spelling is `store.stmt_fingerprint(decls.decl(d).stmt)`. Handing
`root` to a `StmtId` seat is F2000, which CLAUDE.md already lists.

**And the caveat splits freshness in two, exactly as lane C says.**
`fingerprint_stmt` (`nodes.av:865`) is structural over the written
statement — `.Let(name, ty, value) -> fp(5, [fp_str(name), type_fp(ty),
…])`. So:

| question | mechanism | why |
|---|---|---|
| **did the SOURCE move?** | `stmt_fingerprint(decl.stmt)` | syntactic, cheap, already maintained and already tested |
| **did the MEANING move?** | the kernel's dependency edges | a declaration whose type moved because a type it *names* moved has an unchanged statement, so its own fingerprint is unchanged |

The second is the better reuse and it is already built: `sig(ws, d)` is a
cell whose deps are discovered by execution (`db.ask`/`db.settle`,
`query/db.av:106,155`), so "this declaration's signature changed" is a
`changed_at` comparison, not a hash anyone has to design. D7 should ask
the kernel, and use `stmt_fingerprint` only for "the prose was written
against *this text*".

**One thing lane C's door does NOT replace: the `docs` family's own
settle hash.** §2.4 is the reason — `stmt_fingerprint` is precisely the
hash that *does not move* when a comment changes, which is what makes the
stale-doc cell possible. `docs` settles on a hash of the **doc text**;
using a statement fingerprint there would rebuild the very bug §2.4
exists to close. The two hashes answer opposite questions and must stay
separate.

### 2.9 A doc is a fact EVERY BODY MAY READ — so it is answered per DEFINER

CLAUDE.md: *a fact every body may read is answered from the PROGRAM,
never from a pass's fact tables*, because a fact table is right in the
body that recorded it and wrong everywhere else. A doc surface rendering
`@std/io` while compiling something else must read the **defining**
file's docs, not the importing file's.

**The design already satisfies this, and the reason is one field.**
`Decl.file` is a `FileId` (`decls.av:24`), set at mint from the file
being admitted (`decls.av:336`, `Decl { … file: f … }`), so it is the **defining** file for every
declaration, including one reached through a `use`. The lookup is
therefore keyed by the definer and never by the asker:

```avra
/// A declaration's doc, wherever it was reached from: asked of the file
/// that DECLARED it. A doc read from the importing file's facts would be
/// right in that file and wrong in every other.
fn doc_of(ws: Workspace, d: DeclId) -> DocRun? {
    docs(ws, decl_at(ws, d).file).for_decl(d)
}
```

**The case, written before the prose, as lane A asked.** It is a
two-file memory host — the tests' host (`workspace.av:33`) — where the
symbol is *defined* in one file and *rendered from* another:

```avra
spec "docs across a module boundary" {
    given "a symbol defined in one file and imported by another" {
        then "the doc comes from the DEFINING file, not the importer" {
            let ws = workspace_over({
                "/r/avra.toml": "[package]\nname = \"r\"\n",
                "/r/src/lib.av":  "/// Trims both ends.\nexport fn trim2(s: string) -> string { s.trim() }\n",
                "/r/src/main.av": "use lib.{trim2}\nlet z = trim2(\" a \")\n",
            })
            // the DeclId is reached from main.av's namespace; its doc must
            // still be lib.av's, and `docs(main)` must hold nothing for it
            let d: DeclId = decl_named(ws, "trim2")
            doc_of(ws, d)!.text(ws) == "Trims both ends." &&
                docs(ws, file_id(ws, "/r/src/main.av")).for_decl(d) == null
        }
    }
}
```

The second conjunct is the half that matters: it asserts the importing
file's `DocFacts` is **empty** for that declaration, so a future
implementation cannot pass by accidentally recording the doc on whoever
asked.

---

## 3 — D3: `avra doc`, and what it can answer when

`packages/cli/src/commands/doc.av`, one file, `doc_command() ->
Subcommand`, one line added to `main.av`'s list — the CLI doctrine
(`commands/mod.av`).

**Two shapes, and the split matters:**

`explain.av` is the model for the **registry** arms: `arg_command`,
no `phased`, reads `avra()`, answers in milliseconds. `grammar.av` is
the model for the **language** arms: `bare_command`, `avra()`,
`render_grammar`.

`check.av` is the model for the **symbol** arm: it needs a `Program`,
which is a whole-package compile. `avra doc split` therefore costs what
`avra check packages/std-text` costs.

That asymmetry is the design decision D3 must make explicitly, and the
answer is to keep them in one command with two costs, not two
commands:

```avra
/// THE RESOLVER, in the old spec's order. Each arm is a named fn and
/// every arm is spelled: a registry, not a projection — a catch-all
/// here silently forgets the next address kind.
fn resolved(args: CliResult) -> int {
    let q = args.arg("address")
    let feature: LanguageFeature? = avra().features.find(it.name == q)
    if feature != null { return feature_page(feature!) }
    let code: DiagCode? = avra().rows.codes.find(it.id == q || it.kind == q)
    if code != null { return code_page(code!) }
    let method: MethodRow? = avra().rows.methods.find(it.name == q)
    if method != null { return method_page(method!) }
    // A SYMBOL COSTS A COMPILE — everything above answered from the
    // assembled language alone.
    if args.arg("at").length > 0 { return on_program(args, (p: Program) -> symbol_page(p, q)) }
    unknown(q)
}
```

**Why `on_program` and not `phased`.** `phased(args, phase, act)` takes
`act: fn(Program) -> Result<int, string>` (`commands/phase.av:10`), and
the act is required by doctrine to be a **named** fn — which cannot
close over the address the user typed. `phased`'s own body is the
precedent: it calls `on_program(args, (p: Program) -> { … })` with an
`int`-answering lambda over `args` (`phase.av:11`). `doc.av` does the
same. Two subset entries make this the only shape that compiles: a
lambda in an argument seat does not read the seat's answer (so a
`Result`-answering lambda there is F2043), and a trailing-lambda call
does not parse.

The registry arms — feature, code, method — and `unknown` **ship at
D0, before D1.**
`symbol_page` ships at D3 and reads `docs(ws, f)`.

`unknown(q)` is the old spec's fallthrough hint and it is the highest-
value line in the file for P1: it names what *was* searched — the 28
features, the 106 codes, the method vocabulary — so a miss teaches the
address space instead of just failing.

**One CLI fact to respect:** `args.arg("address")` is required
(`ArgDef { required: true }`), and `avra doc` with no argument is a
usage error (exit 2), not a table of contents. `avra brief` (D4) is
the no-argument surface; it is a **different subcommand**, per the
one-file-per-subcommand rule.

---

## 4 — Landing order, and the riskiest step

| step | touches | gate | blocked by |
|---|---|---|---|
| **D0** `avra doc <feature>` / `<F-code>` | `cli/src/commands/doc.av` (new), `main.av` (+1 line) | `make test` | nothing |
| **D1** doc lines survive lexing | `grammar/lexer.av` (~15 edits), `language/program.av` (2 literals + 1 field) | `make gate` + 4 new lexer tests + the K0 fixture | nothing |
| **D2** the `docs` family | `workspace.av` (7 sites), `language/docs.av` (new), `language/codes.av` (+1 row) | `make gate` + the two-revision staleness fixture | D1 |
| **D3** `avra doc <symbol>` | `commands/doc.av` (+1 arm) | `make test` | D2 |

**D0 does not block on anything and should land first.** It is the
smallest change in the campaign, it retires the loaded
spring, and it makes `doc.av` exist so D3 is an arm rather than a file.

**The riskiest step is D2, and the risk is not the family — it is the
attachment law.** D1 is provably layout-neutral (§1.4) and its blast
radius is a struct field. D2's risk is that its law is *measured
against a corpus that already exists*, so a wrong rule is loud
immediately: 156 F0911s instead of 1. That is the good kind of risk —
it fails at `make gate`, not in six weeks. The **silent** risk in D2 is
§2.4, the stale-doc green cell, which cannot fail today at all; it is
the one line in this design that ships with a fixture whose only job is
to prove the check can go red.

**Two sequencing facts from the lead, recorded.** The bitwise-operator
slice adds character arms to the *same* `when` in `scan_step` that D1
edits, and it lands first — D1 rebases onto it. That costs this design
nothing: the arm D1 adds is keyed on `c == 47`, which no bitwise
operator uses (`&` 38, `^` 94, `~` 126), so the two changes touch
disjoint arms of one `when`. And §A.3's `line_indent` fix, if the lead
takes it, must **not** ride D1 — a layout change and a lexer change
landing together leave neither exonerable if something breaks.

**The syntax-change protocol does not apply.** D1 changes the lexer but
adds no syntax: no source file in the tree becomes unparseable, and no
existing source needs rewriting. `cp build/avra build/avra.pre` is
still cheap insurance, but the merge does not need a quiet tree, and no
lane's first build after it must be `make bootstrap` — the standing
binary can read every file it could read before. **This corrects the
vision's Part IX coordination ask.**

---

## 5 — What changes in the vision's Part V

1. **The lexer holds spans, not text.** Part V ¶1 says doc runs emit
   *"a span and its raw text."* Holding text mints ~6 900 string boxes
   per full-tree parse on the compile path, where nothing reads them.
   `DocLine { file_level, span }` costs no allocation; the docs query
   slices `SourceFile.text` when a page is asked for. **The Part IX ask
   for doc-string interning is withdrawn — there is nothing to intern.**

2. **`docs` must depend on `source`, not on `parsed` alone.** A doc
   edit does not move `program_hash` (`workspace.av:319`, structural
   fingerprints, `core/nodes.av:3-5`), so the kernel's early cutoff
   (`query/db.av:155-163`) marks a `parsed`-only `docs` cell green over
   stale prose. One line fixes it; it ships with the fixture that makes
   it fail. **The corrected property is stronger than the claimed one:
   a doc edit re-derives the doc and nothing else.**

3. **The tag registry is driver-owned, not feature-contributed.**
   Features contribute `DiagCode` rows because those codes are *their
   laws* (`features/enums/mod.av:32`). No feature owns `@warn`. A
   `doc_tags: List<DocTag> = []` config field that 28 of 28 features
   leave empty is `docs: string` happening a second time. Ship
   `doc_tags()` beside `pass_codes()`; add the config field at the
   first feature that owns a tag.

4. **`TagSeat` cannot have `.Field`, `.Variant` or `.Param` yet, and
   the attachment law needs a third case.** `Variant`
   (`core/nodes.av:358`) and `Param` (`core/nodes.av:335`) carry no
   span and mint no id; `DeclKind` (`core/nodes.av:111`) has no member
   variant. **145 doc runs on enum variants and 10 on struct fields —
   6.4% of the tree's 2 436 runs — attach to nothing**, and the
   vision's rule as written turns every one into an F0911. The law
   gains: *a run INSIDE a declaration's span is that declaration's
   member run — held, unaddressed, silent.* That drops F0911's
   tree-wide count from 156 to **1**, and the one is a genuine
   defect (`features/values.av:22`, a doc for `grown_box` stranded
   above a `use` line). Member addressing is a node-model slice of its
   own.

5. **The presenting fact's numbers.** 28 features, **28 of 28** fill
   `docs` (the 29th directory is `features/tests/`). Exported
   declarations: **978** by grep (893 + 85 `export extern fn`), **782**
   with a doc run directly above — **80.0%**, debt **196**. The
   vision's 890/690/78% is close but is not the number that goes in a
   ratchet; D6's baseline must come from the compiler, over `DeclId`s,
   listing sites and never counts.

---

## 5b — What this design does not cover

**TWO ROT MECHANISMS, and the spine only serves one.** Lane B's point,
recorded here and deliberately not solved: prose rots when **the world
moves**, and a `///` also rots when **its subject dies**. Lane D's
`@std/toml` `code_at` is the instance — a correct-looking doc on a
function left unused after a sweep moved its callers. Nothing about the
doc was wrong; it described something nobody calls. That needs a
**liveness** check, not a **freshness** one, and §2.8's two mechanisms
answer neither: `stmt_fingerprint` says the text is unchanged and the
kernel's edges say the meaning is unchanged. Both are true of a dead
function.

**The door the spine owes it is open.** A `DeclId` carrying docs can be
asked whether anything references it, with what exists:
`NameFacts.bindings` is a `List<Binding?>` keyed by `ExprId`
(`features/facts.av:47`), and `Binding.Decl(decl: DeclId)`
(`core/nodes.av:102`) is what a resolved reference to a declaration
*is*. So "does anything reference `d`?" is a scan of `resolved(ws, f)`
over the workspace's files for `.Decl(d)` — per-file, memoized, and
keyed the right way round. **D2 does not build that; it only guarantees
the `DeclId` a doc attaches to is the same `DeclId` a reference
resolves to,** which is what makes the keeper the lead is adding a query
rather than a re-parse.

**Also out of scope, named so nobody assumes otherwise:** member
addressing (§2.3 — enum variants and struct fields need ids before a doc
can point at one), the `F0910` coverage lint and its ratchet (D6), the
`line_indent` defect (§A.3 — its own slice), and every projection past
the terminal one.

---

## 6 — Left unverified

- **Whether the tree is currently mis-parsed by §A.3.** Argued not —
  the first pushed break in every real file follows a `use` line, and
  `make gate` is green — but "no file relies on the buggy branch" is
  unfalsifiable from outside the compiler. A lane holding the lock could
  settle it by fixing the seed and diffing the corpus's `.expected`.
- **The scan cost of `doc_marker`** (§1.7). Predicted inside the noise;
  needs `make census CMD="check packages/std-avrac"` before and after,
  by a lane holding the machine lock.
- **An enum declaration's statement span reaching its `}`.** READ from
  `grammar/executor.av:360,396` (a branch's span is its whole consumed
  token range) and corroborated by the record-default probe in §2.3,
  but not probed on an `enum` directly — enums hold no expression for
  a diagnostic to point at. D2's first test should pin it.
- **Every measurement in §2.3 and §2.7** is a text scan of
  `packages/**/*.av`, not a compiler count. Right for planning, wrong
  for a ratchet.
