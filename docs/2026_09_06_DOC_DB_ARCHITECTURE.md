# The doc DB — documentation as a query family over any Avra source

> **Status:** ratified design. Supersedes the `LanguageFeature.shows` plan in
> `2026_09_06_SHOW_FORMAT.md`, which was compiler-only and is wrong at its
> carrier. The ROW SHAPE from that document survives unchanged; only where it
> lives moves. Four independent designs, four adversarial critiques; every
> claim below was probed at `5721386` or later.

**The requirement:** docs are for **any** Avra source, in any package, by any
author. They live in the **query database**. Every surface — CLI, website,
LSP, agent tool definitions — is a projection of it. The compiler documenting
its own features is the **first consumer**, not the mechanism.

```
SOURCE     @shows tags inside ordinary /// and //! comments
  ↓
DB         docs(ws, f: FileId) -> DocFacts      attachment, prose, rows
           shown(ws, id: int)  -> Outcome       what a program actually did
  ↓
SURFACES   avra doc · brief · coverage lint · LSP · website · tool defs
```

---

## 1. The syntax — three tags in an ordinary doc comment

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

- `@shows <claim>` opens. The claim is the rest of the line.
- Lines indented deeper than the tag are the **program**, dedented to their
  floor. Blank lines inside are kept.
- `@answers <text>` / `@refuses <codes>` closes. A non-empty rest-of-line is
  the value; an empty one means the indented block below is the value; both
  empty is the empty answer. **No slot is ever reinterpreted** — the encoding
  law, which the first row shape broke.

**`@refuses` TAKES A SET, NOT A CODE — a format hole found before the
fiftieth row.** `Expect.Refuses(code: string)` held exactly one, and a
program can refuse with several. Probed at `ec14ac2`:

```
export use @std.text.{from_codepoint}     ->  F3014  F3015
```

A row recording the FIRST code writes `Refuses("F3015")` — *"this file is
not in a package"* — and **passes while teaching the false law**, because
the entry it documents is about the re-export arriving in a later slice
(F3014). The single-code shape does not merely lose information; it
**certifies the wrong claim**, which is the conjunction defect wearing the
other hat: not two mechanisms in one row, but one mechanism reported by half.

So `Refuses` holds the **exact set**, deduplicated and sorted — which is
precisely `grep -oE 'F[0-9]{4}' | sort -u`, the command this campaign
already mandates over a truncated window. **The assertion and the
instrument are then the same operation.** An exact set also catches a new
cascade appearing, which a subset assertion would swallow.

*(Found by LANE B, who recognised it fast because it is a scar: they once
concluded the re-export law was unreachable in a loose file, having read
`./avra check … | head -6` with F3014 six lines below the window. **A pipe
that truncates reports the absence of what it cut.** My row would have
inherited that error one layer down.)*

**The grammar gains nothing.** No rule, no builder, no keyword. That matters:
`Grammar.keywords()` derives from the assembled grammar's identifier-shaped
literals, so a `shows` statement would reserve the word tree-wide — and
`shows`/`show` already appear 99 times as bare words in `packages/`.

**The lexer gains one arm**, the same one D1 already owed: the `c == 47` arm
splits on the third byte and records `DocLine { file_level: bool, span: Span }`.
Spans, not text — text would mint ~6900 string boxes per parse on the compile
path where nothing reads them.

### The deciding probe: a fence is an escape wearing a fence's clothes

Every rival spelling puts the program in a `"""` raw block. `scan_triple`
reads no escapes, so **a program containing `"""` ends its own container**:

```
error[F0100]: expected BREAK while parsing `stmt`
2 │     let s = """hi"""
  ·                ┬
```

A doc system built on `"""` has a hole exactly at its own container — it
cannot document Avra's raw string. **A `///` prefix has no terminator content
can spell**: the run ends where the prefix stops, and every content line
carries one by construction. Probed at exit 0: one doc comment holding
programs that contain `"""`, ``` fences, and their own `///` lines, extracted
and run clean.

This is the poison-byte law one substrate over — **make the reinterpretation
impossible, not merely unlikely.**

### False-positive rate, measured before shipping

The tag rule is `@word` at the run's base column followed by space-or-EOL.
Across **7,449** existing doc lines in `packages/`, it matches **one**
(`features/builders.av:163`, prose about `@recover`). Drop the space
requirement and it matches twelve. An unrecognised tag stays prose — warning
there would be F2040's shape again.

### Members

`Variant` and `Param` carry no span and mint no id. A member run reads the
first NAME after the run and **requires it to be a declared member** of the
enclosing declaration — the same list the sig holds, so a typo'd member doc
is refused rather than silently dropped. Measured over 2,531 doc runs: 1,837
top-level, 533 on impl methods (which have DeclIds), **161 members**, 0 inside
a fn body.

---

## 2. The DB — two families, and `docs` never asks `shown`

```
docs(ws, f: FileId) -> DocFacts     depends on source, parsed, items
shown(ws, id: int)  -> Outcome      depends on docs; keyed by an interned ask
```

**They are separate so that `check` and `build` never compile a documentation
example.** A doc is inert on the compile path; verification is a surface you
ask for.

**The `source` edge is structural, not bolted on.** `docs` slices
`SourceFile.text` to make prose, so the dependency falls out of execution.
That closes the defect this campaign found in the kernel: `parsed` settles on
`program_hash`, a fold of *structural* fingerprints, and reformatting never
changes a fingerprint — so a cell depending on `parsed` alone goes green over
changed prose.

**Three prior beliefs corrected by measurement:**
- There are **14 families today, not 13**. `MINIMUM.md` is stale at two lines.
- Therefore **append at 14/15**, not "insert at 10". `ordinal` is read at
  exactly two sites, and family order stopped being pipeline order when
  `Manifest` and `Receivers` landed.
- `DocFacts` is pure data and joins the thirteen uncleared workspace tables;
  it does **not** join `disarmed`, whose membership rule is "the value holds a
  closure over `ws`".

**Incrementality, which is the payoff:** a doc edit re-derives `docs` for one
file and nothing else — not `items`, not `sig`, not `typed`, not `lowered`.
Documentation gets red-green granularity strictly finer than the code's.

---

## 3. A show runs in the subject's own module

**Found by running the extracts rather than reasoning about them: 5 of 9
authored shows died standalone** with `F3000: 'Suit' is not defined`. The
format's own examples all document *language features*, whose programs declare
everything they need. A show on a user's `split` cannot redeclare `split`.

**Fix, probed at 0.03s:** files in one directory are one module, and an entry
placed beside the subject's file sees module-private names **with no `use` at
all**. So the verifier materialises each show as a one-off entry file in the
subject's own directory, runs it, removes it.

Zero derived imports, zero ceremony, private declarations included, and **the
program a reader copies is the program that ran**. One at a time is not
optional — a package may have exactly one file that runs statements (F0902).

Re-run under that rule, 7 of 9 passed. The two failures were the author's own
malformed rows, caught by the harness within the hour of writing them.

---

## 4. `LanguageFeature.docs` dies

The 28 features document themselves exactly as a user package does. **One
mechanism, no second path.**

The argument that a feature is not a symbol — that `enum`'s meaning attaches
to no single declaration — was taken seriously and lost on carrier, not on
category: a component config field is an Avra **value**, and a value can only
be read by **running the package that declares it**. A doc tool that must
execute a third-party package to render its docs is the two-hats law firing at
the doc boundary.

**And the migration is nearly free:** the lexer and query work are owed to
user packages regardless, so the marginal cost of killing the field is 28
content **moves**, not 28 rewrites.

---

## 5. The public surface — the DB is the product

- **`DocAddr` names no file**, so it survives a rename: package, module,
  symbol, row index, member.
- **A miss returns the page anyway** — `Result`-typed, so an undocumented
  symbol still yields its derived half (signature, failures, callers) rather
  than nothing.
- **JSON is versioned in its first field**, from day one, with a five-way
  verdict whose counts must sum.
- **Staleness is not a query.** The DB holds only *now*. Detecting drift needs
  a **checked-in baseline** — the doc records the fingerprint it was authored
  against, and the baseline is a tracked file, not a derived value.

---

## 6. What the critiques killed

Recorded because a design nobody attacked is untested:

- The **migration plan** was refuted on three counts and is being redone.
- The **addressing scheme** was wrong at its own flagship example.
- One lane proposed a **proxy lint** — counting a correlate rather than the
  doctrine. Refused; this campaign has already paid for that once as F2040.
- The claim that the whole API surface compiles cited an artifact that was not
  the design.

---

## 7. What must be true before this lands

1. The lexer arm records doc runs and `raw` is byte-identical — proven by
   inspection, then by the corpus.
2. `docs` re-derives on a doc edit and nothing else does. Two-revision fixture.
3. A show on a user's declaration runs in its own module and passes.
4. The `@shows` scanner's false-positive rate on the existing 7,449 doc lines
   is still 1.
5. `avra doc --check` reports coverage, failures, staleness and unexercised
   rows as facts with locations.
6. A serious red-team and review-round, per the owner's standing order.
