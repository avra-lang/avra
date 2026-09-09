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

Two rules:
1. The emission vocabulary lives as METHODS on the pass context. A
   helper that takes `cx` first becomes `cx.helper(...)`. CLAUDE.md
   already says a state struct's impl is its vocabulary; this finishes
   the move for every pass.
2. A call may take its LAST fn-typed argument as a trailing block:
   `f(a) { x -> body }` is `f(a, (x) -> body)`. An `else { }` after the
   block fills a second trailing fn argument.

## What it buys
A region is one expression whose arms are blocks, so open, arm-end and
close are written once inside the method and cannot be mismatched at a
call site. Every scoped-resource verb (`db.tx { }`, `with_file { }`)
reads the same way.

## Cost
Grammar: a `{` after a call's `)` currently reads as "expected BREAK".
The block must parse as an argument only when the callee's last seat is
fn-typed — a typing question, so the parse admits it and the checker
refuses a block on a non-fn seat with a named refusal.

## Trigger
Lands with the first pass rewritten to it; the idiom ratchet then
refuses a new `verb(cx, ...)` free fn in a pass.
