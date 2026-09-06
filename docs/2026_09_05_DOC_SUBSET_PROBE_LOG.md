# "The subset today" — THE PROBE LOG: which entries still tell the truth

> **THE BASE THAT ANSWERED THIS FILE.** Every line below was run against
> `build/avra` in the primary worktree
> (`/Users/tristan/projects/tristanMatthias/avra`, branch `main`) on
> 2026-09-05/06. HEAD was **`e046ba2`** ("merge: lane sqlite —
> docs(sqlite): cut the campaign's prose by 80%"), committed 23:39:46;
> the binary was built 23:40:22 — **the binary POSTDATES its source**, so
> no staleness gap applies to these answers. The working tree was clean
> apart from this document.
>
> Nothing here is inferred. Every refusal is the compiler's own text,
> copied from its output. PROBE, DON'T REASON — a claim in CLAUDE.md that
> this file contradicts is a doc defect, not a language ask.
>
> **RE-VERIFIED AGAINST A MOVED BASE.** While this log was being
> written the tree advanced nine commits to **`312bd0d`** and
> `build/avra` was rebuilt at 00:10:44 (27s after that HEAD). The full
> corpus was re-run against the new binary: **0 failed**, in about two
> seconds. Every verdict below therefore holds on BOTH bases. The
> section of CLAUDE.md this log describes is `1937ea1` and is byte-identical
> at both — checked, not assumed.
>
> Rung **D5** of `docs/2026_09_05_DOCUMENTATION_VISION.md`. The corpus
> this log verifies is the future `lang/subset/`; it lives in a scratch
> directory and lands in the repo only when someone decides it should.

---

## The verdict, in one table

| Verdict | Count | Meaning |
|---|---:|---|
| **HOLDS** | **38** | refuses (or behaves) exactly as CLAUDE.md records |
| **DRIFTED** | **3** | still refuses, but the recorded wording or note is wrong |
| **STALE** | **3** | now COMPILES — the entry is a doc that actively lies |
| **NEEDS-PACKAGE** | **2** | cannot be reproduced from a loose scratch file |
| **PARTIAL** | **1** | one half verified, the other needs a package build |
| **UNREPRODUCIBLE** | **0** | — |
| **total** | **47** | bullets, counted in CLAUDE.md's four subsections |

Counted per CLAUDE.md **bullet** (27 + 11 + 5 + 4 = 47); Part II splits
several bullets into sub-rows where they carry more than one claim, so
its row count is higher.

**Three entries of 47 — 6% — are now false.** The other 41 still refuse,
38 of them in the exact words recorded. For ~80 claims maintained by
hand, by exhaustion, with no tool checking any of them, that is a better
result than the campaign assumed. But the three that rotted all rotted in
the same direction — **the typer got MORE capable and nobody retired the
entry** — and that is a direction which will keep producing them.

---

# Part I — THE THREE STALE ENTRIES

These are docs that lie. Each one costs an author a compile cycle spent
writing a workaround for a restriction that no longer exists.

## S1 · A `null` literal as a list element under `List<T?>` — NOW COMPILES

CLAUDE.md, "Syntax the grammar lacks", last bullet:

> A `null` LITERAL as a list element under `List<T?>` (`[null for c in
> cs]`, `T` a struct): F2006 "a list element cannot hold this yet" —
> lane C's PAIRS IN SLOTS. A `T?`-answering fn fills the slot
> (`[nothing_yet() for c in cs]`).

```avra
type C = { n: int, m: int }
fn f(cs: List<int>) -> List<C?> {
  let out: List<C?> = [null for c in cs]
  out
}
```

```
--- exit 0 ---
```

Clean. Probed across four shapes — a one-field record, a two-field
record, a record with a managed field, and a plain `[null, null]`
literal — **all four compile**, and the program runs:

```
$ ./avra run   # [null, null, null] built through the comprehension
3
```

The recommended workaround (`[nothing_yet() for c in cs]`) is now
unnecessary ceremony.

## S2 · A `dyn` want DOES reach a CALL's seat — NOW COMPILES

CLAUDE.md, "Wants the typer does not carry yet", third bullet, final
clause:

> Nor into a CALL's seat: `refused(e)` with `fn refused(e: dyn Error)`
> and a `ProcessError` in hand is F2000 "argument 1 of `refused` wants
> `dyn Error`, found `ProcessError`" — bind `let boxed: dyn Error = e`
> first, or take what the trait answers (the message) instead.

```avra
trait Error { fn message() -> string }
type ProcessError = { code: int, why: string }
impl Error for ProcessError { fn message() -> string { "pe:${self.why}" } }
type IoError = { path: string }
impl Error for IoError { fn message() -> string { "io" } }
fn refused(e: dyn Error) -> string { e.message() }
let p = ProcessError { code: 1, why: "spawn" }
let i = IoError { path: "/x" }
"${refused(p)} ${refused(i)}"
```

```
--- exit 0 ---
$ ./avra run
pe:spawn io
```

It compiles **and dispatches correctly** to two different impls. The
other two clauses of that same bullet — the `match` arms and the `if`
branches — still HOLD (Part II, B3/B3b). So the entry must lose its
third clause and keep its first two.

## S3 · A `List<T>` DOES adopt a `List<T?>` want — NOW COMPILES

CLAUDE.md, "Methods the runtime lacks", last bullet, second clause:

> A `List<T>` never adopts a `List<T?>` want: `let tys: List<TypeRef?>
> = [t for t in refs]` is F2024 "`tys` declares `List<TypeRef?>`, this
> is `List<TypeRef>`" — the element's nullable is not widened through
> the list.

```avra
type TypeRef = { index: int, kind: int }
fn f(refs: List<TypeRef>) -> int {
  let tys: List<TypeRef?> = [t for t in refs]
  tys.length
}
```

```
--- exit 0 ---
```

The first clause of that same bullet (a struct-literal FIELD seat plants
no want, F2010) still HOLDS exactly — see C5a in Part II.

## The mechanism the three share, and the boundary that survives

S1 and S3 are **one change seen twice**: a declared `List<T?>` want is
now honoured, both as the want for a bare `null` element and as a
widening target for a `List<T>`. The boundary is worth recording
precisely, because half of the old rule is still live:

| shape | verdict | today's answer |
|---|---|---|
| `let out: List<C?> = [null …]`, C a struct | **compiles** | — |
| `let tys: List<string?> = [t for t in ss]` | **compiles** | — |
| `let tys: List<int?> = [t for t in ns]` | refuses | F2019 "a `List` slot cannot hold this yet" |
| `let xs: List<int?> = [null, null]` | refuses | F2019 "a `List` slot cannot hold this yet" |
| `let xs = [null, null]` (no want) | refuses | F2006 "a list element cannot hold this yet" |
| `[v]` where `v: int?` (no want) | refuses | F2006 "a list element cannot hold this yet" |

So **F2006 is alive** — it fires whenever no want is declared. What
changed is that a declared want for a MANAGED element type is now
honoured; a nullable SCALAR element is still refused, but by a different
code (**F2019**, the slot law) than either entry quotes.

An entry rewritten from this table would be shorter *and* truer than the
two it replaces.

---

# Part II — EVERY ENTRY, ITS PROBE, ITS VERDICT

Refusal text is the compiler's, copied. Programs are in the scratch
corpus (one file per entry, named in the "corpus" column).

> **One fidelity note.** The compiler quotes identifiers in backticks
> (`` `enumerate` pairs only… ``). The tables below drop those inner
> backticks so the cells render; every verbatim quote in Parts I and III,
> and every `@refuses:` string in the corpus, keeps them exactly. When
> the two disagree, the corpus file is the receipt.

## Section A — Syntax the grammar lacks (27 bullets)

| # | entry | verdict | today's first refusal | corpus |
|---|---|---|---|---|
| A1 | struct destructuring in `let` | HOLDS | F0100 `expected = while parsing stmt` | `struct-destructuring-in-let` |
| A2 | or-pattern separator `\|` | HOLDS | F0100 `expected } to close the match` | `or-pattern-pipe` |
| A2b | a BINDING across `or` alternatives | HOLDS | F2039 `an or arm binds nothing — its alternatives take wildcards only` | `or-arm-binds-nothing` |
| A3 | destructuring `enumerate()` | HOLDS | F2005 `enumerate pairs only under a paired for head — pairs as values arrive with tuples` | `enumerate-destructuring` |
| A4 | type aliases / newtypes | HOLDS | F0100 `expected { while parsing stmt` | `type-aliases` |
| A5 | `table` literal without its row type | HOLDS | F0100 `expected BREAK while parsing stmt` | `table-literal-without-row-type` |
| A6 | the pipe `\|>` | HOLDS | F0100 `expected BREAK while parsing stmt` | `pipe-operator` |
| A7 | bitwise `\|`, `<<`, `>>` (lexed, no grammar) | HOLDS | F0100 `expected BREAK while parsing stmt`, at the operator | `bitwise-or/-shl/-shr` |
| A7b | bitwise `&`, `^`, `~` (not lexed) | HOLDS | F0001 `unexpected character` | `bitwise-and/-xor/-not` |
| A8 | a range takes no methods | HOLDS | F0100 `expected ) to close the group`, at the `..` | `range-takes-no-methods` |
| A9 | `export use`, a re-export | **DRIFTED** | F3014 fires as recorded — but see below | `export-use-reexport` |
| A10 | `once fn` with type parameters | HOLDS | F0100 `expected ( while parsing stmt` | `once-fn-type-parameters` |
| A11 | `once fn` answering a SCALAR | HOLDS | F2055 `once fn seed answers int, which the runtime cannot keep` | `once-fn-scalar-answer` |
| A11b | `once fn` taking arguments (incl. `mut`) | HOLDS | F2055 `once fn seed takes arguments — a once answer is one value for the whole process` | `once-fn-takes-arguments` |
| A12 | a trailing-lambda call | HOLDS | F0100 `expected BREAK while parsing stmt`, at the `{` | `trailing-lambda-call` |
| A13 | a generic fn as a value | HOLDS | F0100 `expected BREAK while parsing stmt` | `generic-fn-as-value` |
| A14 | `@comptime` | **DRIFTED** | refuses at the `@`, but the token list moved — see below | `comptime-annotation` |
| A15 | the bare component form | HOLDS | F0100 `expected BREAK while parsing stmt` | `bare-component-form` |
| A15b | instantiation is a STATEMENT | HOLDS | F2000 `the body answers void but made declares Cfg` | `component-instantiation-is-a-statement` |
| A16 | present-bind arm after a comma-ended arm | HOLDS | F0100 `expected } to close the match` | `present-bind-arm-after-comma` |
| A17 | a match arm whose body is `{}` | HOLDS | F2013 `a match's arms disagree: void vs the first arm's {}` | `match-arm-empty-block` |
| A18 | a `\u` escape is not an escape | HOLDS | compiles; the six-character text has `.length` **6** | `u-escape-is-not-an-escape` |
| A19 | a match arm whose body is a bare STATEMENT | HOLDS | F0100 `expected } to close the match` | `match-arm-bare-statement` |
| A20 | `?` then a field on a Result | HOLDS | F2023 `?. reaches into a nullable, this is Result<P, E>` | `propagate-then-field-on-result` |
| A21 | `export let` / `export const` | HOLDS | F3014 `export marks a fn, type, enum or trait — not this statement` | `export-let-const` |
| A22 | `is` with a PAYLOAD pattern | HOLDS | F0100 `expected BREAK while parsing stmt` | `is-with-payload-pattern` |
| A23 | `Result<void, E>` as a fn's answer | HOLDS | F2019 `a Result slot cannot hold this yet` | `result-void-answer` |
| A24 | `const` in a MODULE file | **NEEDS-PACKAGE** | a loose file is an ENTRY — `const` compiles clean there | — |
| A25 | a METHOD after `?` on a Result | HOLDS | F2023 `?. reaches into a nullable, this is Result<R, string>` | `method-after-propagate-on-result` |
| A26 | `fail` inside a `catch` ARM's block | HOLDS | F2029 `a catch arm answers the ok side: int, this is Result<int, string>` | `fail-inside-catch-arm` |
| A27 | a `null` literal under `List<T?>` | **STALE** | compiles — see S1 | — |

### A9's drift — the entry's own reproduction note is wrong

CLAUDE.md says:

> To reproduce it you need a PACKAGE: a loose scratch file answers F3015
> "this file is not in a package — `use` needs a root" first, and never
> reaches the re-export law.

It does reach it. A loose file emits **both**, F3015 then F3014:

```
error[F3015]: this file is not in a package — `use` needs a root
error[F3014]: `export use` — a re-export — arrives with a later slice
```

The law HOLDS; only the "you need a package" note is false. This one
matters beyond its own row: it is the reason a verifier should
**re-derive** which entries need a package rather than trust the prose,
and it moves `export use` out of the NEEDS-PACKAGE column.

### A14's drift — the quoted token list names a keyword that is gone

CLAUDE.md quotes the refusal as:

> "expected `mod`, `use`, … while parsing `stmt`"

The actual first token is `use`; **`mod` does not appear** anywhere in
the expected set:

```
error[F0100]: expected `use`, `export`, `spec`, `let`, `const`, `impl`,
`trait`, `mut`, `while`, `for`, `if`, `type`, `component`, `enum`,
`fail`, `defer`, `errdefer`, `extern`, `fn`, `once`, `return`, `!`, `-`,
`(`, `self`, `true`, `false`, `when`, NAME, `match`, `null`, `.`,
`table`, `grammar`, NUMBER, `[`, `{`, STRING, ISTR_BEGIN, BREAK or EOF
while parsing `stmt`
```

The refusal HOLDS; the elision hid a keyword's retirement. A quote that
ends in "…" cannot be machine-checked against a prefix — which is an
argument for recording the STABLE fragment, not the opening one.

## Section B — Wants the typer does not carry yet (11 bullets)

| # | entry | verdict | today's refusal | corpus |
|---|---|---|---|---|
| B1 | a generic struct literal's field seat unifies | HOLDS | F2000 `N is not pinned by the arguments` | `generic-struct-literal-field-pin` |
| B2 | a LAMBDA in a FIELD/ARGUMENT seat | HOLDS | F2043 `.Ok needs a known enum — nothing here says which` | `lambda-in-field-seat` |
| B3 | a `dyn` want in match ARMS | HOLDS | F2013 `a match's arms disagree: Q vs the first arm's P` | `dyn-want-match-arms` |
| B3b | a `dyn` want in `if` BRANCHES | HOLDS | F2000 `an if's branches disagree: P vs Q` | `dyn-want-if-branches` |
| B3c | a `dyn` want in a CALL's seat | **STALE** | compiles and dispatches — see S2 | — |
| B4 | a trait impl over a GENERIC type | HOLDS | F2031 `Box is generic — a trait impl over a generic type is recorded, not landed` | `trait-impl-over-generic-type` |
| B5 | variant arms on a NULLABLE enum | HOLDS | F2013 `match chooses over an enum, found K?` | `match-variants-on-nullable-enum` |
| B6 | `is` over a NULLABLE enum | HOLDS | F2013 `is asks an enum for its variant, found Cause?` | `is-over-nullable-enum` |
| B7 | a generic impl naming its own `T` in a local | HOLDS | F2001 `T names no type` | `generic-impl-local-annotation` |
| B8 | `it` through a self-method wrapper | HOLDS | F2033 `it has no element here — this seat takes int, not a fn` | `it-through-self-method-wrapper` |
| B9 | `is` payload, in a `match` context | HOLDS | F0100 `expected } to close the match` | `is-payload-pattern-in-match` |
| B10 | `join` over a list that is not text | HOLDS | F2005 `join reads a list of text, this one holds int` | `join-over-non-text-list` |
| B11 | `==` between lists | HOLDS | F2000 `== compares scalars for now` | `eq-between-lists` |
| B11b | `contains` over structs | HOLDS | F2005 `contains scans by value — scalars and text for now, this list holds K` | `contains-over-structs` |
| B11c | a payload-FREE enum compares fine | HOLDS | compiles; `.Timeout == .Refused` answers **false** | `eq-enum-payload-free` |
| B11d | an enum CARRYING a payload | HOLDS | F2000 + help `match on it instead — only an enum carrying nothing compares, by variant` | `eq-enum-carrying-payload` |

**A note on B5's own example.** The entry's spelling `match k { .A -> …,
null -> … }` produces a second, unmentioned refusal before the one it
documents — `null` in that arm position is F3002 "`null` is a keyword /
cannot be a name". The documented F2013 still fires; the example just is
not minimal.

## Section C — Methods the runtime lacks (5 bullets)

| # | entry | verdict | today's refusal | corpus |
|---|---|---|---|---|
| C1 | `List.reverse()` | HOLDS | F2030 `.reverse(…) calls a method, and List<int> has none` | `list-reverse` |
| C1b | `List.sort()` | HOLDS | F2030 `.sort(…) calls a method, and List<int> has none` | `list-sort` |
| C2 | `List.find_index(pred)` | HOLDS | F2030 `.find_index(…) calls a method, and List<int> has none` | `list-find-index` |
| C3 | `m["k"]` on a map | HOLDS | F2000 `[...] indexes a List, found Map<string, int>` | `map-bracket-index` |
| C4 | an empty literal under a nullable aggregate want | **DRIFTED** | F2024 as recorded for `let`; the fn-tail wording moved — see below | `empty-list-under-nullable-want`, `empty-map-under-nullable-want`, `empty-list-fn-tail-nullable` |
| C4b | an empty STRING adopts `string?` | HOLDS | compiles | `empty-string-adopts-nullable` |
| C5a | a struct-literal FIELD seat plants no want | HOLDS | F2010 `field slots is List<TypeId?>, this is List<TypeId>` | `struct-field-seat-plants-no-want` |
| C5b | a `List<T>` never adopts a `List<T?>` want | **STALE** | compiles — see S3 | — |

### C4's drift — one character

CLAUDE.md records the fn-tail refusal as:

> a fn tail says "the body answers `[]?` but … declares `List<int>?`"

The compiler says:

```
error[F2000]: the body answers `[]` but `f` declares `List<int>?`
```

`[]`, not `[]?`. The `let` and map halves of the bullet match exactly.
Trivial as prose — fatal to a verifier that matches on the quoted
string, which is why it is recorded rather than waved through.

## Section D — Runtime facts, ours to ratify (4 bullets)

| # | entry | verdict | evidence |
|---|---|---|---|
| D1 | a string's `.length` is a LOAD; `str_len` distrusts a ZERO length | HOLDS | `runtime/avra_runtime.c:365` reads `return (h && h->len) ? h->len : strlen(s);` — verbatim as quoted |
| D2 | `split` drops a trailing empty segment, keeps a leading one | HOLDS | `./avra run` answers `1 2 0` for `"a."`, `".a"`, `""` |
| D3 | a string holds a NUL only half-way | **PARTIAL / NEEDS-PACKAGE** | the literal half HOLDS: the six-character `ab\0cd` spelling has `.length` **6**, so `\0` is not an escape. The five lossy primitives need `@std/text`'s `from_codepoint(0)` to mint a NUL, and `use @std/text` from a loose file is F3015 |
| D4 | `avra run` traps past 400 nested calls | **PARTIAL** | the interpreter half HOLDS: `recursion too deep — 400 nested calls`, exit 1. The native half ("`avra test`/`build` run 5000 deep") needs a package build, for which this lane does not hold the lock |

---

# Part III — WHAT THE PROBING FOUND THAT IS NOT IN THE DOC

Three facts established while probing that no entry records. Offered as
candidates; only the owner writes doctrine.

**1. `.length` counts BYTES, not code points.**

```avra
let s = "é"
let t = "e"
"${s.length} ${t.length}"
```
```
2 1
```

This is the load-bearing premise underneath D3 (a NUL is one byte among
others) and underneath A18 (the `\u` spelling is six *characters* — six
ASCII bytes, not one code point). Neither entry says it, and an author
who assumes code points will size a buffer wrong. It also names exactly
what a `Bytes` value would formalise.

**2. A bare `table { … }` parses as a STRUCT LITERAL of a type named
`table`.** Not the documented refusal, and reached by a different route:

```
error[F3000]: no `type table` is declared
```

The documented "expected BREAK" appears only when the body is
*well-formed table syntax* (a pipe-separated header). Both are refusals,
so the entry HOLDS — but an author who writes `table { id: 1 }`, the
brace-map shape a JSON habit produces, gets a message about a missing
*type* and no hint that `table<Row>` is what they wanted. The remedy is
a diagnostic, not a doc row.

**3. `Result<void, E>` and nullable list slots share F2019 and one help
string** — "nullable slots arrive with ownership's next slice" — while
`List<int?>` reports "a `List` slot cannot hold this yet" and
`Result<void, E>` reports "a `Result` slot cannot hold this yet". One
law, two nouns, correctly parameterised. Worth knowing when reading
S1/S3: the boundary that survived is *this* law, not the one the stale
entries name.

---

# Part IV — THE CORPUS, AND WHETHER THE KEEPER IS BUILDABLE

## What was built

**63 scratch programs** — one per HOLDS/DRIFTED claim, plus three added
in Part V — in the shape Part V of the vision proposes, with two tag
vocabularies rather than one:

```avra
//! A RANGE TAKES NO METHODS.
//! @refuses: expected `)` to close the group
//! @instead: [f(i) for i in 0..n].any(...)
fn f(n: int) -> bool { (0..n).any(it == 2) }
```

Roughly a fifth of "The subset today" records something that
**compiles** — `\u` is not an escape, `split`'s empty segments, a
payload-free enum comparing, an empty string adopting `string?`, the
400-call trap. The vision's `@refuses:` cannot express those, so the
corpus adds three tags, and they are the reason the verifier catches
more than staleness:

| tag | asserts |
|---|---|
| `@refuses: <text>` | `avra check` FAILS and prints `<text>` |
| `@compiles: yes` | `avra check` SUCCEEDS |
| `@answers: <text>` | `avra run` prints exactly `<text>` |
| `@traps: <text>` | `avra run` FAILS and prints `<text>` |

`@instead:` and `@note:` are prose, carried for the reader and for
`avra brief`'s negative-space section.

## Is `avra doc --verify-subset` buildable? Yes — it already runs

A 30-line shell driver reads the tags out of each file and asserts them.
Over the full corpus:

```
---
verified 63, failed 0
sh verify-subset.sh subset  1.15s user 0.73s system 81% cpu 2.285 total
```

**Under 2.3 seconds for the whole negative space**, and it was run twice
over on two different binaries nine commits apart. That is `make gate` leg
territory with no argument needed about cost. Nothing in it requires
compiler work: it is `avra check`, `avra run`, an exit code and a
substring. The Avra implementation buys structure and better reporting,
not capability — so **K5 can land before D1, exactly as the ladder
claims**.

## The keeper's own failure, witnessed

CLAUDE.md: *"A green check whose failure has never been witnessed is an
untested instrument."* Four fixtures, one per failure mode, run against
the real driver — not a copy of its logic:

```
BROKE   pretend-broke — recorded as compiling, now refuses
DRIFTED pretend-drifted
        recorded: `.reverse()` is not a thing on lists
        actual:   `.reverse(…)` calls a method, and `List<int>` has none
MOVED   pretend-moved — recorded '9 9 9', answers '1 1 1'
STALE   pretend-stale — now COMPILES; the entry is lying
---
verified 0, failed 4
exit 1
```

Each mode is named, the drifted one prints both strings, and the status
is a verdict (exit 1), not a count. Had this existed, S1, S2 and S3
would have been caught the day the typer changed.

## Four things learned by hand that the automated version must inherit

**1. A malformed probe reads exactly like a stale entry.** The first
`table` probe used `table { id: 1 }` — brace-map shape, not table shape —
and produced F3000 instead of the recorded F0100. That looked like drift
and was a bad probe. **A verified corpus removes this failure mode
permanently**, because the program is stored once, next to its claim,
instead of being re-improvised by each prober. This is the single
strongest argument for D5, and it is not the staleness argument.

**2. Match on the STABLE fragment, not the whole line.** Refusals
interpolate types (`Result<P, E>`, `List<int>`), so a corpus program's
own type names appear inside the asserted string. Substring matching on
a hand-chosen fragment works; matching a whole rendered line would make
the corpus fail on every unrelated rename.

**3. A `…`-elided quote cannot be verified.** A14 is the case: the entry
quotes a prefix that has since lost its first keyword. Record a fragment
that is stable, or record the whole thing and accept churn — the
ellipsis picks the worst of both.

**4. The prose about reproduction rots too.** A9 says a loose file
"never reaches the re-export law"; it does. The verifier must **derive**
NEEDS-PACKAGE by trying, not read it from a note.

## Cost of the manual pass, for whoever sizes the automated one

~50 probe programs written, ~25 compiler invocations, four rounds of
digging where a first result surprised me (`table`, the `List<T?>`
shapes, the `dyn` call seat, the `\u` byte encoding). **Three of those
four digs changed the verdict** — two from "stale" back to "holds" (bad
probes), one from "holds" to "stale" (a probe too narrow to see it).
That ratio is the argument for storing the programs.


---

# Part V — ROUTED ENTRIES: an entry with a scheduled expiry, and two rots

Four items routed by the campaign lead from peer lanes, probed here
against **`312bd0d`** (binary built 00:10:44).

## V.1 · THE FLAGSHIP — an entry whose falsification is SCHEDULED

Lane A re-probed both bitwise tiers and found them true. So did I, on
this base:

**Tier 1 — lexes, no grammar.** `|`, `<<`, `>>`, each pointing AT the
operator:

```
error[F0100]: expected BREAK while parsing `stmt`
4 │ fn f() -> int { 3 | 2 }
  ·                   ╰──
```

**Tier 2 — not lexed at all.** `&`, `^`, `~`:

```
error[F0001]: unexpected character
```

Both tiers **HOLD**. And both become false when the bitwise slice merges,
which is being built right now. That makes this the cleanest possible
test of the whole D5 thesis, because the question is not *whether* the
entry rots but *what happens on the day it does*.

### What `make docs` prints that day

Not a prediction. The post-slice state was **simulated faithfully** —
each of the six corpus files keeps its recorded `@refuses:` line verbatim
while its program becomes one the compiler accepts, which is exactly the
state "the operator now parses" puts the file in — and the real driver
was run over it:

```
STALE   bitwise-and — now COMPILES; the entry is lying
STALE   bitwise-not — now COMPILES; the entry is lying
STALE   bitwise-or — now COMPILES; the entry is lying
STALE   bitwise-shl — now COMPILES; the entry is lying
STALE   bitwise-shr — now COMPILES; the entry is lying
STALE   bitwise-xor — now COMPILES; the entry is lying
---
verified 0, failed 6
exit 1
```

Six lines, one per spelling, naming exactly which became legal — and a
red gate, so **the bitwise slice cannot merge while the doc still says
the opposite**. The author of that slice does not need to know "The
subset today" exists; the gate tells them, at merge time, with the file
names to delete.

Compare the status quo, which is the mechanism that produced all three
stale entries in Part I: the slice merges green, the entry keeps saying
"no spelling exists", and the next author writes the SUM workaround for a
restriction that was lifted weeks earlier. **Nobody is at fault in that
story, which is the point** — there is no step at which a careful person
was careless.

## V.2 · A ROT ALREADY CORRECTED — and a FOURTH SITE THAT IS NOT

Lane C reported three ROADMAP entries asserting "`ptr` is receive-only"
after `avra_ptr_at` landed. Verified: the capability landed at
**`f7a8bba`** (23:55:17) and lane C corrected all three at **`df7d926`**
(00:03:45). They now read "`ptr` WAS receive-only" — past tense, correct.

**But the sweep was scoped to the ROADMAP, and the claim lives on a third
surface.** `docs/2026_09_05_BYTES_SHAPE.md:239-241` still asserts it in
the present tense:

> `SQLITE_TRANSIENT` — which COPIES, and is therefore the safe default —
> is `(void*)-1`, **unspellable**: `ptr` is receive-only, `let p: ptr = 0`
> is F2024, and there is no int→ptr mint.

Probed, clause by clause:

| clause | verdict | probe |
|---|---|---|
| "`ptr` is receive-only" | **FALSE** | `extern fn avra_ptr_at(address: int) -> ptr` — exit 0 |
| "`let p: ptr = 0` is F2024" | **TRUE** | `error[F2024]: p declares ptr, this is int` |
| "there is no int→ptr mint" | **FALSE** | `avra_ptr_at(0 - 1)` — exit 0, on `-> ptr` and `-> ptr?` alike |

So `(void*)-1` — the sentinel that document calls **unspellable** — is
spellable today, in one line. Which means the document's headline
conclusion,

> **THE EASY CALL IS THE DANGEROUS ONE AND THE SAFE CALL CANNOT BE
> WRITTEN.**

and its consequence — *"Until then the driver must not offer a bind at
all"* — are **discharged**, and the document still tells the sqlite lane
not to ship a bind. That is a rot with a decision attached to it.

**The generalisable finding is the scoping.** Lane C's fix was correct
and complete *for the surface it swept*. A doctrine claim is not owned by
one file, so a sweep keyed to a file leaves the same sentence standing
somewhere else. A keeper keyed to the CLAIM finds all four; a careful
author sweeping the ROADMAP finds three.

**And note which clause survived.** Clause 2 is still true while 1 and 3
are false — the fourth time in this log that a multi-clause entry rotted
clause-by-clause (S2 lost one of three, S3 one of two, C4 one of three).
**Verification must be per-CLAUSE, not per-entry**, or a corpus file
asserts the true half and passes while the false half keeps lying. This
is a concrete design constraint on `--verify-subset`, earned four times.

## V.3 · A HISTORICAL ROT — measured, and its lesson is about F-CODES

Lane B's finding is confirmed and **already fixed** — my extract carries
the corrected text, which is why Part II records A25 as HOLDS.

The old entry:

> - A METHOD after `?` on a Result (`shell(line)?.run()`): F0102
>   "`?.` cannot call a method yet — chain methods are recorded"

The receipts:

| event | commit | when |
|---|---|---|
| `a?.m(args)` lands; the diagnostic is deleted | `2d6356c` | 2026-09-05 06:54:51 |
| lane B corrects CLAUDE.md | `bd76326` | 2026-09-05 15:05:40 |

**The rot window: 8.2 hours and 14 commits**, during which a document
that exists to say "do not write this" forbade something the compiler
had started accepting that morning. Confirmed working today:
`a?.run(2)` on an `R?` — exit 0.

### The sharper lesson: an F-code is not an identity

Lane B reported the quoted code as no longer existing. It is worse than
that, and more instructive. **F0102 exists and always has** —
`packages/std-avrac/src/language/codes.av:19` files it as
`"build.failed" | "a builder rejected its captures"`, unchanged since the
projection seam was created. The deleted rule was never a registry row at
all; it was a hand-written string inside a builder:

```
-  if links[jn].text == "?." { return .Err("`?.` cannot call a method yet — chain methods are recorded") }
```

so it *surfaced* as F0102 because that is the generic code for any
builder rejection. The doc attached a stable-looking identifier to a
message that had no identifier of its own.

**Consequence for the keeper, and it is a real one:** a verifier that
asserted "F0102 still exists" would have PASSED this entry for all 8.2
hours. Codes are shared by many rules and outlive the rules that prompted
a citation. `--verify-subset` must assert on the **wording** and the
**behaviour**, never on the code — which is what the corpus does, and it
is now the reason rather than an accident.

## V.4 · THE NEW ENTRY WAS ALREADY COVERED

Lane C's `is`-with-a-payload entry (`p is .Bind(_)` → "expected BREAK
while parsing `stmt`") was already present in `1937ea1`, the version this
log extracted. It is **A22**, verdict HOLDS, corpus file
`is-with-payload-pattern`; its `match`-context twin is **B9**
(`is-payload-pattern-in-match`). No action — recorded so the lead can see
the routing closed rather than dropped.

## V.5 · WHAT THE ROUTED ITEMS CHANGE ABOUT THE PROPOSAL

Three refinements, each paid for by one of the items above:

1. **Assert wording and behaviour, never an F-code** (V.3). A code is
   shared and outlives its rules.
2. **A corpus file asserts ONE clause** (V.2, and S2/S3/C4 before it).
   Multi-clause entries rot one clause at a time, and a file that asserts
   the surviving clause passes while the dead one lies.
3. **The gate belongs to the SLICE AUTHOR, not the doc author** (V.1).
   Its value is that it fires in the merge that invalidates the entry,
   naming the files to delete, for someone who has never read the subset
   list. That is a different and larger claim than "docs stay fresh".

And one number the routed items supply that the manual pass could not:
**8.2 hours and 14 commits** is the measured cost of one rot in this
tree, on a day when four lanes were watching. That is the interval
`--verify-subset` closes to zero.
