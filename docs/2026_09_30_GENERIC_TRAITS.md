# Generic traits — `trait X<T>`, impl chosen by its argument

> 2026-09-30. Decided with the owner (UI.md §19.3, C2; Rust's model).
> Branch lane/gtraits. Map of the machinery: the research pass in
> this conversation (every file named below).

## What a user writes

```avra
trait Realize<T> {
    fn draw(t: T) -> string
}

impl Realize<Text> for Html {
    fn draw(t: Text) -> string { "<p>${t.content}</p>" }
}

impl Realize<Button> for Html {
    fn draw(t: Button) -> string { "<button>${t.label}</button>" }
}

let h = Html {}
h.draw(Text { content: "hi" })          // the Realize<Text> impl, by the argument's type
```

## Laws

- A trait may declare type parameters. Its members read them.
- One type may implement one generic trait at several arguments. Their
  same-named methods coexist; nothing else may share a method name.
- A call picks the ONE impl whose instantiated member accepts the
  arguments (static: a direct call to that impl, no lookup at run).
  None → "`Html` implements `Realize` for `Text` and `Button` — not
  for `Link`". Two → refused, naming both (no silent preference).
- Two impls of one trait at one argument on one type → refused.
- A bound names its argument: `fn f<R: Realize<Text>>(r: R)`.
- `dyn Realize<Text>` is C2b; the completeness law (every component a
  program uses is realized by every target it builds) is C2b too.

## Slices

| | Delivers |
|---|---|
| C2a.1 | grammar + nodes: `trait X<T, …>`, `impl X<A, …> for Y`; printer; a trait's tparams are Vars its member sigs read |
| C2a.2 | declaration: methods filed per impl INSTANCE (`method_clashes` exempts same-name members of distinct instantiations of one generic trait; `declare_method`/`method` answer every candidate); overlap refused |
| C2a.3 | resolution: `declared_call` selects among candidates by argument type (the ambiguity and no-impl voices); the choice recorded per call in facts so lowering, failures, receivers and structural types read ONE answer |
| C2a.4 | bounds with arguments; held (warm) interface carries the trait arguments |
| C2b | `dyn X<A>` (`Type.Dyn` gains args), dispatch table per trait instance, the completeness law |
| C2c | `From<T>` in the prelude — the first non-UI consumer |

Each slice: program tests eval == native, a golden per voice, red team,
review round, compiler suite on a Sprite.

## The pre-typing passes read the shared contract

Failures, receivers and structural types resolve a dot-call by name.
Where a generic trait gives a type several same-named members they
read the TRAIT's member (`Decls.shared_member`) — the signature and
receiver contract every impl agrees to — never the first impl found.

## Recorded, not landed

- **`dyn` over a generic trait** (`dyn Realize<Text>`) does not parse.
  A `dyn` type names its trait alone, so a box has no slot for the
  trait's arguments. Fires when a value must hold "something that draws
  `Text`" without naming its type; a bound (`<R: Realize<Text>>`)
  covers every case where the type is known at the call.
