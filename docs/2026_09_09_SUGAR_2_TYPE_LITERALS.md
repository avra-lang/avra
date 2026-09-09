# Sugar 2 — type literals

## The want
A pass that needs a type value interns it by hand, inside out:

    let str_opt = cx.view.types.intern(Type.Opt(cx.view.types.intern(Type.Str)))

Every level of nesting is another `intern`, and the reader rebuilds the
type in their head from the inside.

## The form
    let str_opt = ty(string?)

`ty(T)` takes a TYPE in the language's own spelling and answers its
`TypeId`, interned in the current context's table. Generic and nested
types read as they are written anywhere else:

    ty(List<string?>)
    ty(Result<int, E>)
    ty(fn(mut Cx, int) -> int)

## Rules
- The argument is parsed with the type grammar, not the expression
  grammar; a value there is a refusal ("`ty` takes a type, this is an
  expression").
- A type parameter in scope (`T` inside a generic fn) is allowed and
  resolves to that parameter's id.
- Interning is the same `intern` the checker uses, so `ty(string?)`
  twice is one id, and the marks normalisation of fn types applies.

## What it buys
The compiler's own source stops spelling `Type.Opt(...)` trees; a type
in a pass looks like a type in a program. It also removes one class of
bug: an interned tree built in the wrong order (a Var pinned before its
argument) cannot be written.

## Cost
One primary rule in the expression grammar; typing answers `TypeId`.
The table it interns into is the active context's — `ty` is only legal
where a context is in scope, which the checker names.

## Trigger
Lands with the first typing pass rewritten to it.
