# Sugar 5 — named arguments

## The want
    gathered(cx, w, read.parts, text, want)

Five positional arguments; two are the same type. The reader opens the
callee to learn which is which.

## The form
    gathered(w, parts: read.parts, text, want: want)

A call may name any argument with `name:`. Named and positional mix;
positional arguments fill seats in order, named ones fill their seat by
name, and no seat may be filled twice.

## Rules
- A name that is not a parameter of the callee is a refusal naming the
  parameters.
- Order among named arguments is free; positional ones keep their
  order.
- A struct literal already names its fields; this is the same
  affordance for calls, with the same spelling.
- No default arguments in this slice; a missing seat is the existing
  arity refusal.

## A named argument in block form
Sugar 1 landed a second trailing block behind the word `else`:

    pick(c) { 1 } else { 2 }
    cx.region(k, e) { cx -> a } else { cx -> b }

The word is positional — it separates the call's last two fn seats
and means nothing — but it READS as a branch, because `if … else`
teaches it to. Wherever the second seat is not the other arm of a
choice (a cleanup, a tie-breaker, a `finally`) the site lies about
the callee. The sweep used it only on regions and choosers, so no
site lies today; the language permits one.

THE LABEL IS THE SEAT'S NAME — a named argument, in block form:

    cx.region(k, e) { cx -> a } other: { cx -> b }
    with_file(path) { f -> … } finally: { … }
    pick(c) { 1 } else: { 2 }

`NAME ":" trailing` follows the first block; the name must be a seat
of the callee (a wrong one refuses naming the seats), no seat is
filled twice, and `else:` is just what a callee calls a seat that is
an else. True by construction, and the same rule as `name:` in the
parentheses. This slice RETIRES sugar 1's bare `else` block in the
same change: the grammar's `"else" trailing` becomes `NAME ":"
trailing`, the fold checks the label against the callee's seats at
typing, and the region verbs' sites read `other:`.

## What it buys
Calls with three or more seats of one type become readable at the site.
The idiom bar can then refuse a positional call where two adjacent
seats share a type. And the second trailing block says what it is.

## Cost
One grammar branch in the argument list (`NAME ":" expression`, tried
before the expression floor, as a keyword anchor is). Typing matches
names to seats before the existing positional check.

## Trigger
Lands standalone; no dependency on sugars 1–4, except that it retires
sugar 1's `else` block — the two land as one change, or this one
first.
