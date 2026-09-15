# Sugar 2 — type literals

## The want
A pass that needs a type value interns it by hand, inside out:

    let str_opt = cx.view.types.intern(Type.Opt(cx.view.types.intern(Type.Str)))

Every level of nesting is another `intern`, and the reader rebuilds the
type in their head from the inside.

## The form (LANDED 2026-09-09)
    let str_opt = cx.type(string?)

`v.type(T)` is a POSTFIX like the rest: `T` is a type in the language's
own spelling, `v` is the table it interns into. Generic and nested
types read as they are written anywhere else:

    cx.type(List<string?>)
    cx.type(Result<int, err>)
    types.type(fn(mut Cx, int) -> int)
    cx.type(Map<string, want>)

## How it works
Pure sugar at PARSE time. The literal expands to ONE method call on
the receiver, `interned`, over the spelling as a value of core's
`TypeLit` enum — bare variants, heard from the seat:

    cx.type(List<string?>)   ==>   cx.interned(.List(.Opt(.Str)))

So the receiver is read once, no site imports anything, and the
receiver is any value with `interned(t: TypeLit) -> TypeId`: the
registry (`TypeRegistry.interned` IS the fold — children first,
through the one `intern`), and TypeCx, LowerCx, Decls, which forward.

## Rules
- The words `int float bool string ptr void`, the constructors
  `List<T>` `Map<K, V>` `Result<T, E>`, `fn(…) -> R` with its `mut`
  marks, and `?` spell shapes.
- Any other NAME is a HOLE: the `TypeId` binding it names, in scope.
  `cx.type(Map<string, want>)` reads `want`. A hole is a NAME, never
  an expression — a computed part binds a name first.
- A declared type has no spelling here (`Foo<int>`, `dyn Show`): its
  id is a binding, so the hole is how it is named. Refused in those
  words at parse time.
- A receiver without `interned`, a value in the slot, a hole of the
  wrong type, a block after the literal: each refuses in the
  LITERAL's words, never the expansion's (the call and its holes are
  MARKED in the store).
- `a?.type(T)` chains, as every `?.` link does.

## Two decisions the first draft got wrong
- The word is `type`, not `ty`. A new keyword reserves a name, and
  `ty` names 273 bindings in the tree; `type` was already reserved.
- The receiver is EXPLICIT, not "the context in scope". The 128 sites
  spelled ten different receivers, so no binding was "the" table.
  `cx.type(int)` reads as wanted because the contexts carry the verb.

## What it bought
87 sites swept; 37 stay, each a shape the literal cannot spell
(`Enum`/`Struct`/`App`/`Var`/`Dyn`/`TypeName`, `Error`, `Null`, the
empty literals) or a computed part. I40 ratchets the hand-built form.
A type in a pass now looks like a type in a program, and an interned
tree built in the wrong order cannot be written.

## Cost
One postfix alternative in the spine (two, with the chain), the
`TypeLit` enum, one fold, three forwarding verbs, two store marks.
