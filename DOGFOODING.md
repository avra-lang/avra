# Dogfooding Avra

Patterns proven in this tree — reach for these before writing the
C-style version. Probe unfamiliar features in scratch first; known
gaps live in CLAUDE.md "bs2 subset notes".

## `when` for dispatch chains

Any if/return ladder over conditions is a `when` expression:

```avra
when {
    c == 10 -> emit(tok(TokKind.Break, "", i, i + 1), i + 1)
    is_space(c) -> skip(i + 1)
    is_name_start(c) -> { ... }
    _ -> fail("unexpected character", i, i + 1)
}
```

## List comprehensions for filter/map

```avra
fn op_texts(r: LexResult) -> List<string> {
    [t.text for t in r.toks if t.kind == TokKind.Op]
}
```

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

Row type annotation is required. Use for pure data cases; keep named
`then` blocks where per-case failure names matter.

## `with` for modified copies

```avra
cap("rules", rule_ref("rule")) with { rep: Rep.Plus }   // rare modifiers
r with { far: far }                                     // struct update
```

## Methods via `impl` (cross-file works)

```avra
impl Grammar {
    fn defects(self) -> List<GrammarDefect> { ... }
}
// callers: g.defects()
```

## Nullability instead of sentinels

Absence is `T?`, never `-1` or `""`: `label: string?`, `build: Build?`
(null = pass-through), `expect: Expect?`. Consume with `??`, `!`, and
null/`let x ->` match arms.

```avra
text = text + (unescape(e) ?? src.substring(j, j + 2))
```

## Pinned-type constructors (bs2 generics workaround)

bs2 infers generics only from call arguments. Give every generic
construction a tiny fn whose signature pins the parameter:

```avra
fn absent_val<N>() -> Val<N> { Val.Absent }
fn st_at<N>(cursor: int, binds: List<Bind<N>>) -> St<N> { ... }
// call sites: ok_res<N>(st_at<N>(c, binds), absent_val<N>(), ...)
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

## Comprehension as list copy

The safe-snapshot idiom (never alias a list a rollback still holds):

```avra
mut xs = [x for x in items]
xs.push(v)
```

## Match guards

```avra
match self {
    .A(n) if n > 10 -> "big",
    .A(_) -> "small",
    .B -> "none",
}
```

## `?` propagation on Result

```avra
fn quarter(n: int) -> Result<int, string> {
    let h = half(n)?
    half(h)
}
```

## Proven but awaiting their first honest use

- **Traits** (`trait Show` + `impl Show for T`) — first customer is
  Diag rendering in parse_grammar.
- **Pipe `|>`** — first real pipeline, not two-arg call rewrites.
- **`?` propagation** — first customer is the builder chain in
  grammar/builders.av.
