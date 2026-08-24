# Dogfooding Avra

Patterns proven in this tree — reach for these before writing the
C-style version. Probe unfamiliar features in scratch first; known
gaps live in CLAUDE.md "bs2 subset notes".

## `when` for dispatch chains

Any if/return ladder over conditions is a `when` expression:

```avra
when {
    c == 10 -> emit(token(TokenKind.Break, "", i, i + 1), i + 1)
    is_space(c) -> skip(i + 1)
    is_name_start(c) -> { ... }
    _ -> fail("unexpected character", i, i + 1)
}
```

## List comprehensions for filter/map

```avra
fn op_texts(r: LexResult) -> List<string> {
    [t.text for t in r.tokens if t.kind == TokenKind.Op]
}
```

Lists only — comprehensions cannot iterate ranges.

## `it` projection for simple lambdas

```avra
let names = self.rules.map(it.name)
```

Complex bodies fail `it` inference — use an annotated param:
`cases.filter((c: BreakCase) -> count_breaks(lex_grammar(c.src)) != c.breaks)`.

## Typed table literals for fixture data

```avra
type BreakCase = { src: string, breaks: int }
let cases: List<BreakCase> = table {
    src                    | breaks
    "a = b\n   | c\nd = e" | 2
    "\na = b"              | 1
}
```

Row type annotation is required (a typed `let` — field position is
not enough). Use for pure data cases; keep named `then` blocks where
per-case failure names matter. Cells hold fn VALUES and enum values
too — a registry or an operator set is literally a table:

```avra
let rows: List<BuilderRow> = table {
    name          | build
    "int_lit"     | build_int_lit
    "fold_binary" | build_fold_binary
}
let ops: List<OpRow> = table {
    text | op
    "+"  | BinOp.Add
    "-"  | BinOp.Sub
}
```

## `with` for modified copies

```avra
cap("rules", rule_ref("rule")) with { rep: Rep.Plus }   // rare modifiers
r with { farthest: merged }                             // struct update
```

## Methods via `impl` (cross-file works)

```avra
impl Grammar {
    fn defects(self) -> List<Diagnostic> { ... }
}
// callers: g.defects()
```

A method is also the place a CONTRACT gets its name:

```avra
impl Token {
    /// Text equality, never against quoted input — data, not syntax.
    fn lit_matches(self, text: string) -> bool { ... }
}
```

`impl` works on enums too — derived properties live with the type:

```avra
impl Rep {
    fn suffix(self) -> string { match self { .One -> "", .Star -> "*", ... } }
}
impl Prim {
    fn token_name(self) -> string? { ... }
    fn answers_to(self, token: string) -> bool { ... }  // null-guarded ==
}
```

## Nullability instead of sentinels

Absence is `T?`, never `-1` or `""`: `label: string?`, `build: Build?`
(null = pass-through), `expect: Expect?`. Consume with `??`, `!`, and
null/`let x ->` match arms.

```avra
text = text + (unescape(e) ?? src.substring(j, j + 2))
```

## Extractor + `want` for typed unwrapping

Per-kind extractors return `T?`; one `want` owns the Result plumbing
and the error vocabulary. `?` chains the rest:

```avra
fn want<T>(x: T?, what: string) -> Result<T, string> {
    let out: Result<T, string> = if x == null { Result.Err("expected ${what}") } else { Result.Ok(x!) }
    out
}
// let body = want(alt_of(args[1]), "an alternation")?
```

A `T?` argument is direct evidence, so `want` needs no explicit `<T>`.

## `?` propagation on Result

```avra
fn call_args(v: Captured<GrammarNode>) -> Result<List<string>, string> {
    mut out: List<string> = []
    for x in as_list(v)? {
        let t = want(tok_of(x), "an argument name")?
        out.push(t.text)
    }
    Result.Ok(out)
}
```

## Generics: what infers, what needs pins

Proven capabilities:

- Generic enums with payload fields (`Captured<N>`), generic structs
  with fn-typed fields (`MatchContext<N>.build`), generic fns taking
  fn-typed params, and generic impls (`impl Arena<N>` — methods
  specialize per instantiation) all work — including TWO
  instantiations of the same fn in one compile unit.
- A bare `T`/`T?` argument is direct evidence — `want(x: T?, what)`
  never needs `<T>` at call sites.
- Constructions infer under a typed `let` and in a fn's TAIL position
  (expected types thread through match arms, if-branches, and list
  elements). Early `return`s do NOT get this — keep the typed let there.

Pin explicitly (`f<N>(...)`) when:

- the only N-evidence rides inside a struct argument
  (`match_rule<N>(cx, ...)` — `cx: MatchContext<N>` is not enough), or
- the call happens inside another generic fn's body, even at a
  concrete type (`concat<Diagnostic>(diagnostics, r.diagnostics)`).

Never nest a generic type inside an explicit type argument —
`concat<Captured<N>>(...)` does not take (write the loop instead).
Fn-typed arguments carry no T-evidence, and pinning `<T>` over one
corrupts scalar payloads through mono — never thread fn args through
generics.

```avra
fn captured_absent<N>() -> Captured<N> { Captured.Absent }
```

## Vocabulary over ceremony

When every author would write the same wrap/unwrap stack, name it once
and the stack disappears from every call site. Bundle a call's world
into a context struct and the vocabulary becomes methods on it:

```avra
fn build_int_lit(b: Builder) -> Result<LangNode, string> {
    let t = b.token(0)?                    // not want(token_at(args, 0), "...")?
    b.make_expr(Expr.IntLit(t.int_value()))  // not Ok(Node(NExpr(alloc(..., span))))
}
```

The context carries what the engine knows (`b.span`, the store) so
authors never thread it; raw fields stay public as the escape hatch.

## Generic engine, concrete client

A generic engine takes ONE node type; a client with many node kinds
supplies a wrapper enum and unwraps behind its own accessors:

```avra
export enum GrammarNode { NGrammar(g: Grammar), NRule(r: Rule), ... }
run_grammar<GrammarNode>(g, tokens, grammar_build)
// consumers never match GrammarNode — they call grammar_result(o)
```

## First-class functions

```avra
fn scan_while(src: string, from: int, pred: fn(int) -> bool) -> int
// call: scan_while(src, i + 1, is_name_cont)
```

## Operator/escape sets as data

```avra
fn is_single_op(ch: string) -> bool { "=|()*+?:,".index_of(ch) >= 0 }
```

## Map as a built-once index

`.get` returns `T?`; missing keys are honest nulls.

```avra
mut rules: Map<string, Rule> = {}
for r in g.rules { rules.set(r.name, r) }
// lookup: let found: Rule? = cx.rules.get(name)
```

## Range `for` over index windows

```avra
for i in 1..xs.length - 1 { out = "${out}, ${xs[i]}" }
```

## Rebind-alias for shared mutation

Params and captured structs are immutable, but rebinding a ptr-backed
list to a `mut` local aliases the same storage — the arena idiom:

```avra
fn alloc_expr(self, e: Expr, span: Span?) -> ExprId {
    mut nodes = self.exprs
    nodes.push(e)
    ExprId(nodes.length - 1)
}
```

(Do NOT capture a `mut` struct in a closure — bs2 emits invalid IR;
capture the `let` struct and go through a fn like this instead.)

## Comprehension as list copy

The safe-snapshot idiom (never alias a list a rollback still holds):

```avra
mut xs = [x for x in items]
xs.push(v)
```

## `is` for single-variant questions

```avra
tail.prim is .Group && tail.rep == Rep.Star
```

A full match earns its place only when payloads are extracted.

## `enumerate` for indexed walks

```avra
for (i, m) in out.enumerate() {
    if i == idx { next.push(m with { expect: ... }) } else { next.push(m) }
}
```

## `concat` / `joined` from core/lists

```avra
diagnostics = concat<Diagnostic>(diagnostics, r.diagnostics)
"[${joined([render(x) for x in items], " ")}]"
```

Pin `concat<T>` inside generic fn bodies — mono needs the explicit
type there even when T is concrete.

## Components for self-describing bundles

A named bundle with defaulted fields is a `component` (the spec's
feature shape): only the fields that matter get spelled. Instantiation
is a STATEMENT binding the instance name — bind, then return it.

```avra
export component LanguageFeature {
    config {
        name: string,
        docs: string = "",
        gram: string = "",
        builders: List<BuilderRow> = [],
    }
}

fn harness() -> LanguageFeature {
    component LanguageFeature h {
        name = "harness"
        gram = "prog = e:expression BREAK -> e"
    }
    h
}
```

Config pairs are newline-separated; the `component`-prefixed
instantiation works cross-file (the bare form does not).

## Triple-quoted strings for embedded text

Grammar fragments, docs, fixtures — never `\n`-joined literals:

```avra
gram: """
expression = additive
primary = v:NUMBER -> int_lit(v) | n:NAME -> ident(n)
""",
```

## Typed ids are single-field structs

`type ExprId = { index: int }`, never an int newtype — newtype scalars
corrupt through generic/mono flows (subset note). Struct ids ride
every boundary safely and stay nominally distinct.

## Match guards

```avra
match self {
    .A(n) if n > 10 -> "big",
    .A(_) -> "small",
    .B -> "none",
}
```

## Proven but awaiting their first honest use

- **Traits** (`trait Show` + `impl Show for T`) — first customer is
  Diagnostic rendering in parse_grammar.
- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.
