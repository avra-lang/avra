# Sugar 6 — a bound method as a value

## The want
A scan over a receiver's own verb spells a lambda whose only job is
to forward one argument:

    ids.any((s) -> self.stmt_rides(s))
    args.all((a) -> self.fully_bound(a, target, bound))
    fds.find((d) -> self.starts_between(d, lo, hi))

The pronoun cannot stand in: `ids.any(self.stmt_rides(it))` rebinds
`it` to the NEAREST method call, which is `stmt_rides` itself
(F2033). A free fn already is a value — `xs.any(big)` answers — so
the gap is exactly the receiver.

## The form
    ids.any(self.stmt_rides)
    args.all(self.fully_bound)   // when the seats fit; partials stay lambdas

`self.stmt_rides` without parentheses answers `fn(StmtId) -> bool`
with `self` closed over. Today it is a PROPERTY read and typing asks
the record for a field: F2003 "no field `stmt_rides` on `NodeStore`".

## The shape
A method read on a receiver mints the fn box a lambda mints — the
code address at slot 0, the receiver as the one capture, called
through `CallPtr` with the box at seat 0 exactly as `self` rides a
method call. So it is the wrapper lambda minted by the READER rather
than written by the writer, and the lambda feature owns it: the
resolver already knows when a dotted name is a method and not a
field (typing's member law asks the impl table after the fields),
and the lift is the closure lift with one capture.

The `mut` contract rides the box: a `mut fn` read as a value wears
`fn(mut …)`-shaped intent on its receiver, and the seat law reads
marks, so a writing method stored where nothing may write refuses
as any marked fn value does.

## Where it applies
Every scan that forwards one argument to a receiver's verb. Ten
sites landed as wrapper lambdas in the sugar 1 sweep and name the
want: core/nodes.av `any_rides`/`any_stmt_rides`, features/unify.av's
three `all`/`find` folds, features/checks.av `same_root`,
features/contexts.av `decl_named`, features/builder.av
`starts_between`, language/workspace.av `parse_clean` and
`registering`.

## What it buys
The predicate is the verb's name. A scan reads as the sentence it
is, and the pronoun trap that forced ten lambdas has nothing to
rebind.

## Cost
Typing: a member read whose name is a method and not a field answers
the method's fn type with the receiver's seat dropped, instead of
F2003. Lowering: one more source of a fn box, the closure lift with
a single capture. Nothing in the grammar.

## Trigger
Lands with the first of the ten sites rewritten to it; the wrapper
lambdas retire in the same change.
