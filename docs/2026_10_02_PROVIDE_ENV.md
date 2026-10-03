# `provide` / `env` — context that flows down

Status: built. `provide`/`env` are soft keywords (the lexer marks each
only in the shape it declares), the provider table is a lexical scope
in typing, and a missing provider is a compile error (F2xxx
`type.provider`). The reader was spelled `ambient` for one release,
because a HARD keyword `env` would have refused `@std/io`'s `env` fn
and `Tool`'s `env` field; the soft form removes that objection, so the
reader is `env` now — the spelling this note always specified.

## 1. The want

A subtree shares values — the theme, density, writing direction, locale,
size class, and the actions a component may call (`dismiss`, `open_url`,
`refresh`) — and today there is no way to read them from a component.
They are threaded explicitly: `render(root, Env { … })` passes one `Env`
to one target, and every component that wants a token must receive it
through props. That is prop-drilling, and it is why a `gap: .M` resolves
through a theme the component cannot see.

WEB_UI §5.3 already states the design:

| Need | How |
|---|---|
| a subtree shares | `provide x: T = …` above, `env T` below; missing provider = compile error; env carries ACTIONS |

## 2. The two forms

```avra
provide theme: Theme = brand          // a statement: binds `theme` for the subtree
provide density: Density = .Compact
…
view toolbar() {
    let t = env Theme                 // an expression: the nearest provider of that type
    row { text("Hi").color(t.color.muted) }
}
```

- `provide x: T = <expr>` is a **statement**. It evaluates `<expr>` in
  the enclosing scope and makes it readable as `env T` in its lexical
  subtree (the block it stands in, and everything nested).
- `env T` is an **expression** of type `T`. It names the **nearest
  provider of type `T`** lexically above it.
- The **key is the type**. `env Theme` reads "the nearest `Theme`", so a
  provider needs no global name; the binding name (`theme`) is only local
  spelling.

## 3. Scoping and conflicts

- **Nearest wins.** A nested `provide theme: Theme = dark` shadows the
  outer one for its own subtree — a new mode for a panel, for example.
- **Missing provider is a compile error**, statically: `env Theme` with
  no `provide Theme` above it refuses, naming the type and the place
  ("no `Theme` is provided above this `env`; add `provide theme: Theme =
  …`"). No runtime crash is possible in the static case — this is the
  point (the SwiftUI `@Environment` crash is refused).
- **The value is not a constant.** `provide x: T = f()` is evaluated in
  the enclosing scope; `env T` reads that one value wherever the subtree
  is evaluated.
- **Dynamic composition is listed.** A subtree assembled at runtime (a
  `dyn View` built by a plugin) may reach a `provide` it does not stand
  lexically under; that case is a listed runtime lookup, not the default,
  and says so where it happens.

## 4. Typing and lowering

- Typing: `provide` records the provided type in a scope table; `env T`
  looks it up. Both are ordinary lexical scopes, so a component body is
  typed under its provider chain the way it is typed under its locals.
- Lowering: `provide` is a value bound in the block; `env T` is a read of
  the nearest binding of type `T` resolved at compile time. In the UI
  library that means a component that reads `env Theme` receives the
  theme as an implicit lexical binding, not a field on the `Node` — the
  `Node` stays the projection it is, and the environment is read during
  construction, where the value already stands.
- Actions ride the same channel: a provided `dismiss: Dismiss` is a fn
  value, so `env Dismiss` answers a callable a component may hand to an
  event.

## 5. Refusals to design

| Case | Refusal |
|---|---|
| `env T` with no `provide T` above | compile error, names `T` and the site |
| two providers of `T` in ONE block | the nearest-wins rule is lexical; a same-block duplicate is a duplicate binding |
| a `provide` whose type is never `env`-read | warn (dead provider), or leave silent — decide |
| `env` inside a `dyn` boundary | listed runtime lookup, marked |

## 6. Wanting sites and pacing

Not needed until a **component** reads the environment. Today only a
target does (`render(root, env)`), which is explicit and fine. The first
real sites are the L1/L2 pieces:

- `if compact { … }` — a view reading `env SizeClass` to choose a layout.
- `text("Hi").color(env Theme)` / a component resolving a token through
  the theme without being handed it.
- a `dismiss`/`open` action provided to a `dialog` subtree.

So: build it with the first of those, as its own slice (grammar +
scoping + typing + lowering + proofs), with a golden for the
missing-provider refusal, and the UI library converting its explicit
`render(root, env)` seam to `provide`/`env` in the same change.

## 7. Size

Grammar: one statement (`provide`) and one primary (`env`) — small.
Scoping/typing: a provided-type table per block, mirroring locals — the
real work. Lowering: resolve `env T` to the nearest binding — mechanical
once the table exists. Proof: program tests (eval == native), the
missing-provider golden, a shadowing test, and the UI wanting site.
