---
name: red-team
description: Adversarial pass against a just-built feature — assume it is broken and prove it, systematically and deterministically. Every survivor becomes a permanent test. Run BEFORE /review-round on every commit. Use when asked to red-team, attack, break, or stress a feature.
---

# The red team

Run this BEFORE `/review-round`, on every commit. The review round
asks "is this beautiful?"; the red team asks **"how does this
break?"** — and it assumes the answer is "many ways", because so far
it always has been.

The posture is adversarial, not curious. You are not checking that
the feature works; you are trying to make it produce a WRONG ANSWER,
a CRASH, an INTERNAL DEFECT shown to a user, or a DIVERGENCE between
the two engines. You wrote this code, so you are the worst person to
ask whether it is correct — which is exactly why the attack list is
mechanical rather than inspired.

## Deterministic, never random

`make fuzz` is the random half and it already runs. This pass is the
SYSTEMATIC half: every attack is enumerated from the feature's own
surface, so the same feature always yields the same attack set and a
rerun after a fix proves the fix. No sampling, no "a few cases" — if
a class has six positions, attack all six.

## The attack classes — work every one, in order

For each, write the program, RUN it (`./avra check`, `./avra run`,
`./avra build`), and record what happened.

1. **DEGENERATE SHAPES.** The N=0, N=1 and N=max of every list the
   feature has: zero variants, one variant, one arm, one field,
   empty body, empty program. The N=1 path is where special-casing
   hides (a single-arm match reads no tag; a one-element list).
2. **EVERY SLOT, EVERY WRONG TYPE.** For each position the feature
   accepts a value, put every other type there: int, bool, string,
   list, struct, enum, a type NAME, a fn call, a hole. Each must
   refuse in its own words — never accept, never defect.
3. **MALFORMED SURFACE, POSITION BY POSITION.** Take the feature's
   syntax and, for each token: delete it, duplicate it, swap it with
   its neighbour, and replace it with a keyword. Every one must
   produce a DIAGNOSTIC (never a crash, never silence). This is the
   class that finds "expected BREAK" messages hiding real mistakes.
4. **CROSS EVERY OTHER FEATURE.** The feature inside and around: a
   fn body, a fn parameter, a fn return, a block, a `while`, a
   `for`, an `if`, a `when`, a `match`, a list element, a struct
   field, a `mut` binding, an interpolation hole, and recursion.
   Both directions — the feature containing them, them containing
   the feature.
5. **NAMES AGAINST NAMES.** The feature's identifiers vs: a keyword,
   a reserved word, a shadowing outer binding, the same name at two
   levels, a name declared AFTER use, a name declared twice, and the
   feature's own name reused as a value.
6. **THE TWO ENGINES.** Every program that is ACCEPTED must give
   `eval == native`. A refusal must refuse in both. Any divergence
   is the most serious finding available here.
7. **OWNERSHIP.** Put a managed value (a string, an interpolation
   result) wherever the feature holds or moves a value. Does
   something get released while still reachable? Does a slot outlive
   its scope? If the feature cannot handle managed values yet, it
   must REFUSE them — silence here is a use-after-free waiting for
   the next rung.
8. **REFUSAL QUALITY.** Every refusal names WHAT is wrong, WHERE,
   and the remedy; the diagnostic COUNT is exact (one mistake, one
   message — cascades are bugs); and no user-facing message says
   "defect" (that channel is for the compiler blaming itself).

## Every survivor becomes a test

A finding is not fixed until a test would have caught it. Tests land
in the feature's own test directory as
`<feature>_adversarial_test.av` — kept apart from the vertical
`<feature>_test.av` so the adversarial set can grow without drowning
the feature's own story. Group them by attack class with `given`
blocks named for the class ("degenerate shapes", "wrong types in
every slot", ...).

Write the test FIRST, watch it fail, then fix. A test written after
the fix proves nothing about whether it would have caught the bug.

Two shapes keep an adversarial file readable as it grows:
- NAME THE FIXTURES. The subject under attack is boilerplate; a
  `fn ab()` returning the standard declaration lets each test show
  only its attack. Thirty repetitions of the same enum buried the
  attacks in the first suite.
- NEVER ASSERT A DISJUNCTION. `A || B` asserts neither — if the
  outcome is uncertain, RUN it and assert what actually happens.

## Report

- Lead with anything that produced a WRONG ANSWER or a DIVERGENCE;
  those outrank everything.
- Then internal defects shown to users, then crashes, then poor
  refusals.
- Say how many programs you actually ran, per class — "attacked 6
  positions" beats "attacked the syntax".
- Name what SURVIVED honestly: a class you ran and found nothing in
  is a real result, and says the feature is solid there.
- Nothing commits without the user's word.
