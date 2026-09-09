# Sugar 1 — the context as receiver, and trailing-lambda blocks

## The want
Pass code threads its context through every call and spells region
brackets by hand:

    open_presence(cx, crossed, str_opt)
    let text = carried_of(cx, crossed, str_opt)
    arm_end(cx, adopted(cx, want, false, gathered(cx, w, read.parts, text, want)))
    let none = absent_of(cx, want)
    close_region_as(cx, want, none)

Eight of nine lines carry `cx`. The brackets are three verbs that must
pair, and nothing checks that they do.

## The form
    cx.presence(crossed, want) { text ->
        cx.adopted(want, gathered(w, read.parts, text, want))
    } else { cx.absent(want) }

## Three levels
1. **Verbs as methods on the state.** `presence(cx, r)` becomes
   `cx.presence(r)`. CLAUDE.md already says a state struct's impl is
   its vocabulary; this finishes the move for every pass. Nothing new
   in the language.
2. **Trailing blocks.** A call may take its LAST fn-typed argument as a
   block after the parentheses: `f(a) { x -> body }` is
   `f(a, (x) -> body)`; an `else { }` after it fills a second trailing
   fn seat. This is Swift's trailing closure, Ruby's block, Rust's
   `thread::scope(|s| …)` without the punctuation.
3. **Implicit receiver inside the block** — NOT proposed here. In
   Kotlin a lambda-with-receiver makes the block's free calls resolve
   against the receiver, so `cx.` vanishes and a builder reads like a
   declaration. It costs visible magic (P7): a reader cannot see which
   calls touch the context. Decide after 1 and 2 exist.

## Where it applies
Not one pass. Every value threaded through many calls, and every verb
that owns a scope:
- the lowering and typing contexts (`LowerCx`, `TypeCx`)
- builders: the HTTP reply writer, a string builder
- scoped resources: `db.tx { }`, `with_file(path) { f -> … }`,
  the extern frame's staged call
- the test harness: `given "…" { then "…" { … } }`

## What it buys
A region is one expression whose arms are blocks, so open, arm-end and
close are written once inside the method and cannot be mismatched at a
call site. Scoped verbs stop taking `() -> { … }` argument lambdas.

## Cost
Grammar: a `{` after a call's `)` currently reads as "expected BREAK".
The parse admits the block; the checker refuses one on a callee whose
last seat is not fn-typed, with a named refusal. Level 1 is a sweep,
not a language change.

## Trigger
Lands with the first pass rewritten to it; the idiom ratchet then
refuses a new `verb(cx, ...)` free fn in a pass.
