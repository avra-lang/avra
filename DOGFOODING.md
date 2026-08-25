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

## The native list vocabulary

`push`, `length`, indexing, `set(i, v)`, `get`, `pop`, `insert`,
`slice`, `join`, `map`, `filter`, `reduce`, `foreach`, `enumerate`,
`zip`, `sort`, `reverse`, `contains(v)` (-> bool), `index_of(v)`,
`find(pred)` (-> `T?`), `any(pred)`, `all(pred)`, `first()`/`last()`
(-> `T?`), `is_empty()` — all native, and native closures are
mono-safe (unlike fn args through OUR generics). They work in
`<N>`-generic bodies too (`bindings.find(it.label == label)`).

A scan is never a loop:

```avra
codes.find(it.kind == kind)?.id                        // first match, projected
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
f.builders.any(it.name == name)
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
if !defects.is_empty() { return unassembled(features, defects) }
let tail: Token? = tokens.last()
```

A loop earns its keep only for: `?` propagation in the body, folds
with ordering semantics (`closest`'s tie-break), index arithmetic,
and stateful transforms.

## `it` projection for lambdas

```avra
let names = self.rules.map(it.name)
self.ranges.find(offset >= it.lo && offset < it.hi)?.feature
cases.all(count_breaks(lex_grammar(it.src)) == it.breaks)
causes.all(cause_registered(it))
```

`it` binds at the nearest enclosing METHOD call — call wrappers and
bare-argument use inside the body are fine. A nested method call in
the body starts its own `it` scope (innermost method wins).

## Typed table literals for fixture data

```avra
type BreakCase = { src: string, breaks: int }
let cases = table<BreakCase> {
    src                    | breaks
    "a = b\n   | c\nd = e" | 2
    "\na = b"              | 1
}
```

The row type rides the literal (`table<Row>`) — the one form every
compile mode accepts. Use for pure data cases; keep named `then`
blocks where per-case failure names matter. Cells hold fn VALUES and
enum values too — a registry or an operator set is literally a table:

```avra
let rows = table<BuilderRow> {
    name          | build
    "int_lit"     | build_int_lit
    "fold_binary" | build_fold_binary
}
let ops = table<OpRow> {
    text | op
    "+"  | BinOp.Add
    "-"  | BinOp.Sub
}
```

## `with` for modified copies

```avra
cap("rules", rule_ref("rule")) with { rep: Rep.Plus }   // rare modifiers
r with { farthest: merged }                             // struct update
feature("clash", "clash_rule = NAME") with { diags: rows }  // extend a factory value
```

`with` chains, takes several fields at once, and applies to any
expression — a whole mut-reassignment ladder is one push:

```avra
ds.push(pointed(error_at(kind, at, msg), "used here")
    with { secondary: defined, help: "move the definition above this use" })
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

`?.` projects a field out of an optional; with `??` it collapses the
whole "if null, default, else unwrap and read" ladder — including
directly on a nullable call's result:

```avra
fn later_def(self, name: string) -> StmtId? {
    self.all_defs.find(it.name == name)?.stmt
}
engine_codes().find(it.cause == c)?.kind ?? "language.defect"
```

`?.` reaches FIELDS only; mapping a present value through a fn or
constructor is still a null/`let x ->` match.

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
  elements) — `Captured.Many([Captured.Terminal(t), v])` needs no
  pinned intermediate, and a generic ctor works as a match-arm tail.
  Early `return`s do NOT get this — keep the typed let there. Neither
  does a construction whose only N-evidence is SIBLING fields
  (`MatchResult { status: r.status, state: state, ... }` — F1002):
  that one keeps its typed-let pin.

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
fn is_single_op(ch: string) -> bool { "=|()*+?:,-".contains(ch) }
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
    ExprId { index: nodes.length - 1 }
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

## `or` arms for shared bodies

Same-body arms are ONE arm — the interesting variant stands alone and
the rest read as a set. Wildcards only; a binding cannot ride an `or`:

```avra
match p {
    .Group(inner) -> call_names_in_alt(inner),
    .Ref(_) or .Lit(_) or .Named(_) -> [],
}
```

## `_` by match species: projection vs dispatch

A PROJECTION asks one variant for its payload; every other arm is the
same absence or rejection. A new variant can never change the right
answer — the fn's contract pins it — so `_` is correct and
enumeration is churn:

```avra
fn node_of(v: Captured<GrammarNode>) -> GrammarNode? {
    match v {
        .Node(g) -> g,
        _ -> null,
    }
}
```

A DISPATCH decides behavior per variant — a walker's recursion, a
renderer's shapes, a checker's rules. There a new variant needs a
human decision, so `_` is banned (CLAUDE.md) and the site must break
at compile time; `or`-runs keep the enumeration one line:

```avra
match self.store.expr(e) {
    .Ident(name) -> self.resolve_name(e, name),
    .Binary(_, l, right) -> { ... recurse ... }
    .IntLit(_) or .Error -> self.nothing(),   // a new Expr must land HERE, visibly
}
```

Open domains (strings, codepoints, `when` chains) always take `_` —
there is nothing to enumerate.

Test assertions are projections-of-truth: "is this a Let named x,
else false" ends in `_ -> false`, so tests never break when the node
model grows. Only the PASSES' dispatch matches enumerate — those are
the sites a new variant must visibly break.

## Absence flows through, never re-matched

A mapping fn takes the OPTIONAL and passes absence through, so every
caller with a `T?` in hand maps in place instead of re-matching
(`loc_at(file, span?) -> Loc?`). Where a present value becomes 0-or-1
things, `some_list` turns the optional into a comprehension source:

```avra
let edits = [Edit { loc: l, replacement: n.name } for l in some_list(at)]
```

Both idioms end the `null -> []` / `null -> null` arms `??` cannot
reach (it defaults — yields the LEFT side when present — it does not
map).

And before reaching for either: check whether the optional should
exist at all. TWO levels of absence (`primary: Frame?` wrapping
`Frame.loc: Loc?`) forced a mapping match at every construction and
read; collapsing to ONE level (the frame is always present, only its
loc is optional — P6) deleted the matches everywhere at once:

```avra
primary: Frame { label: null, loc: loc }          // error_at: no match
d with { primary: d.primary with { label: label } }  // pointed: no match
if d.primary.loc != null { ... }                  // render: one check
```

## `enumerate` for indexed walks

```avra
for (i, m) in out.enumerate() {
    if i == idx { next.push(m with { expect: ... }) } else { next.push(m) }
}
```

## `concat` / `flatten` / `joined` / `filled` / `some_list` from core/lists

```avra
diagnostics = concat<Diagnostic>(diagnostics, r.diagnostics)
diagnostics: flatten([p.diagnostics, r.diagnostics, t.diagnostics])  // N lists, in order
"[${joined([render(x) for x in items], " ")}]"
targets: filled<StmtId?>(p.store.exprs.count(), null)   // dense-table prefill
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

fn let_stmt() -> LanguageFeature {
    component LanguageFeature f {
        name = "let_stmt"
        docs = "`let <name> = <expression>`, ended by the line."
        gram = """
stmt = "let" n:NAME "=" v:expression BREAK -> let_stmt(n, v) @recover(sync_to: "BREAK")
"""
        builders = rows
    }
    f
}
```

Config pairs are newline-separated; the `component`-prefixed
instantiation works cross-file (the bare form does not). A consumer
that cannot instantiate (metadata-compiled tests) goes through an
in-package factory and extends the value with `with`.

## Triple-quoted strings for embedded text

Grammar fragments, docs, fixtures, and GOLDEN test expectations —
an exact multi-line rendering compares against one `"""` block —
never `\n`-joined literals:

```avra
gram = """
expression = additive
primary = v:NUMBER -> int_lit(v) | n:NAME -> ident(n)
"""
```

In gram text, a zero-capture build is `-> f()` — bare `-> f` is a
CAPTURE reference and defects at assembly ("uncaptured label").

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

## Traits for contracts

A trait names a contract; types join by `impl Trait for` — across
package boundaries too. Keep mandatory methods to the one thing every
implementor must say (bs2 cannot materialize default bodies):

```avra
// @std.errors
export trait Error {
    fn describe(self) -> ErrorInfo
}

// any package
impl Error for Diag {
    fn describe(self) -> ErrorInfo { info(self.kind, self.message) }
}
```

Heterogeneous behaviour pairs data with `dyn Trait` — the CLI's
`Subcommand { meta: CommandSpec, body: dyn Runnable }` dispatches
each command through the one-method trait. `NodeSemantics` scales the
same shape to a MULTI-method contract: a feature's whole per-pass
behavior as one impl, and `semantics_of` — the ONE exhaustive map —
returns it directly (typed-let boxed; no strings, no lookup, no miss
possible). The impl is the completeness gate: a missing pass method
fails to compile. A method that deliberately does no work calls
`nothing()` — the decision is written, never implied. One limit: no
generic-enum returns through `dyn` — report through a capability fn
instead.

## The three seams of a pass

Every pass is standard at exactly two seams, and hand-shaped between:

1. DRIVER: `pass(p: ParsedProgram, ...upstream Facts) -> Facts` —
   facts own their diagnostics; `analyze` is the only place order
   exists.
2. FEATURE: one `NodeSemantics` method per pass, `(self, cx, e)`.
3. Between them, the driver's own walk stays plain code — three
   similar 8-line visitors beat one generic walker until a fourth
   pass proves the shape.

A pass's STATE is `{ p: ParsedProgram, ...upstream Facts, ...own
tables }` — the program held as ONE immutable field, never exploded
into copied store/features/file fields. That is the "one big
context", done right: read-context is one shared value; write-state
stays owned per pass, because shared mutable context is the
god-object that makes pass order implicit and memoization
impossible. And passes are NOT a trait: their typed signatures ARE
the data-flow contract (`type_check(p, r)` cannot run without
resolution, provably); a `trait Pass` erases that and has no
consumer until the query engine memoizes passes uniformly — that is
its trigger, not before.

## Capability contexts: data + driver-wired fns

A context struct crosses layers DOWNWARD carrying fn fields the
driver wires at construction — features call capabilities without
importing the pass, and pass state stays with the pass. The engine's
`MatchContext.build` and every pass Cx are the same pattern:

```avra
let cx = TypeCx {
    store: p.store,
    type_at: (e: ExprId) -> t.of_expr[e.index],
    intern: (sh: Type) -> t.types.intern(sh),
    emit: (d: Diag) -> t.speak(d),
    ...
}
```

Closures capture the LET-bound state struct (never a `mut` local) and
mutate through it — the rebind-alias idiom underneath.

## Values are literal nodes

Evaluation reduces an expression to a LITERAL in the tree —
`1 + 2` becomes a synthesized `IntLit(3)` (null span). No parallel
Value enum exists to grow per type (P6): a feature's literal IS its
value representation, printing is the owner's projection, and the
same reduction is `@comptime` folding when it arrives.

## Proven but awaiting their first honest use

- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.
