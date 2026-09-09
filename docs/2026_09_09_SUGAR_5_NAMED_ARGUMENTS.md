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

## What it buys
Calls with three or more seats of one type become readable at the site.
The idiom bar can then refuse a positional call where two adjacent
seats share a type.

## Cost
One grammar branch in the argument list (`NAME ":" expression`, tried
before the expression floor, as a keyword anchor is). Typing matches
names to seats before the existing positional check.

## Trigger
Lands standalone; no dependency on sugars 1–4.
