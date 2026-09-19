# Build cache interface audit

The parse-free hold remains disabled in `build_cache.av`. A settled const can now
round trip through a `Stored.Unit` row, and the small `export_const` fixture built
correctly after an edit with the hold enabled. That does not establish a sound
interface for the compiler package.

## Evidence

- `build packages/cli`, cold under the experimental hold: 79.29 s user CPU,
  145.56 s wall. The cold target is under 60 s.
- With holding disabled and the whole-program object path restored, a true
  cold build using the optimized compiler took 33.59 s user CPU and 63.94 s
  wall. An isolated `clang -O1` compile of that LLVM module took 39.38 s wall.
  This is closer to the cold target but still above it on this machine.
- A whitespace edit to `workspace.av` reached a trap after 10.80 s user CPU.
  The debugger traced it through `Decls.store -> TypeCx.seat_names ->
  TypeCx.seat_contracts`. A held function's parameter names still come from its
  parse store, which does not exist. The edit target is under 1 s.
- Before that, a held const reached `Workspace.settled_at -> const_value` and
  trapped for the same reason. The value row fixes that one read, but it is only
  one member of the interface contract.
- The small fixture also exposed missing private user types, declaration
  visibility, and source-file ownership in the original flat record. Those
  are required even when only exported consts are read.

## The scalable boundary

A held file may be used only through a complete interface. The compiler should
define that interface at the query API that callers already use, then persist
the answers with stable identities. Any attempt to read a held file's parse
store is an interface miss and must trigger a safe rebuild. The completeness
check must be generic; a list of declaration kinds allowed to hold will drift
when the language grows.

The store's unit row can hold const settlement results generically: the codec
handles every `MetaVal` variant exhaustively, including heap nodes and maps.
The interface still needs a complete type and callable contract. In particular,
`FnSig` alone does not carry parameter names or seat marks, and trait and method
relationships are outside `DeclSig`. A flat record of only `fn`, `struct`,
`enum`, `named`, and `const` is therefore insufficient.

Signature rows also need immutable content keys and an atomic locator from a
module identity to its current row. The present module-keyed `Stored.Sig` row
is overwritten in place. Object keys must include every compilation input:
source path and bytes, consumed interface keys, compiler format, and optimizer
mode. When an edit changes an interface, dependents must be revalidated before
their held objects are linked.

## Completion gate

1. Make the interface query boundary complete and fail closed on any parse-store
   read from a held file. Keep the value codec as one `Stored.Unit` use.
2. Stage changed interfaces before deciding which dependent files can hold.
3. Prove the const fixture, a callable with named and `mut`/`const` seats, a
   trait or method call, and a compiler-package edit against the cold build.
4. Measure cold and edit user CPU independently. The current per-file `clang
   -O1` cold path exceeds the cold target even before the edit path is sound.
