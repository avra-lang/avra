# The 13 subset cases the layer did not refuse — split (batch42 + 0850f4bf, AVRA_PROGRAM_NET=0)

## RETIRED (5): the layer accepts, native == eval == the right answer; case + CLAUDE.md line removed
| form | probe | native | eval |
|---|---|---|---|
| `[i for (i, m) in xs.enumerate()]` | f([7,8,9]) → length, [0], [2] | 3 0 2 | 3 0 2 |
| `fn f() -> Result<void, string> { }` | caller catches, answers 2 on Ok | 2 | 2 |
| `m.entries().length` in a lone file | f({"a":1,"b":2}) | 2 | 2 |
| unpinned `mk()` in a generic struct literal's field | `let m: MC<int> = f()` → m.xs.length | 0 | 0 |
| `Cx { get: (n: int) -> .Ok(n) }` (bare variant in a field-seat lambda) | (f().get)(5) | 5 | 5 |

## STILL REFUSED, ONE MESSAGE NOW (3): count 2 → 1 in the spec (the old path's second message was a cascade)
- a seat default on a lambda: `parse.expected` only (old also `resolve.unresolved: no fn g`)
- a pinned generic fn as a value `ident<int>`: `parse.expected` only (old also `resolve.unresolved`)
- `let x? = r catch null else {…}`: `type.catch` only (old also `type.let_else`)

## ACCEPTED UNJUDGED (5): missing laws, still pinned — to route
| form | old refusal | layer, native | layer, eval |
|---|---|---|---|
| `(0..n).length` | type.unknown_prop "no property `length` on `Range`" | builds; body `g` "not lowered yet", traps where reached | "doesn't build this program yet — `Prop`" |
| bare generic fn as a value `let g: fn(int) -> int = ident` | type.lambda "a generic fn is not a value" | builds; body `f` not lowered, traps | "the layout of `T`" |
| empty block as a match arm `1 -> {}` in a void fn | type.match "arms disagree: `{}` vs the seat's `void`" ×2 | LLVM: "PHI node operands are not the same type as the result" | 7 (runs) |
| `fail` inside a `catch` arm's block | type.catch "a `catch` arm answers the ok side" | LLVM: PHI node operands mismatch | "no!" (runs, right) |
| bound method as a value `xs.any(self.rides)` | type.unknown_prop "no field `rides` on `S`" | builds; `S.any_ride` not lowered, traps | "`Prop`" |
Two of these (empty-block arm, fail-in-catch) reach LLVM verification failure natively while the evaluator runs them: either the law is owed, or native lowering of those shapes is.

## Found on the way
`avra run --eval <lone file>` fails on ANY lone file with a fn ("a call of `f`, which names nothing this body reads, at the entry"); the same program as a package evaluates. program_refuse_evaluated opens the file's directory as a package (disk_at), not as a lone disk.
