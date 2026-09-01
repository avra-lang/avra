---
name: review-round
description: The usual aggressive review round for this repo — dogfooding, centralizing, cleaning, DRYing, beautifying, simplifying the recent arc; gates green; ledgers fed; honest verdicts. Use when asked for "the usual review round", a polish round, or aggressive cleanup.
---

# The review round

The standing order: "aggressive rounds of dogfooding, updating
dogfooding, centralizing, drying, beautifying, simplifying." A round
is aggressive in what it hunts and conservative in what it claims —
every finding verified, every change gated, every leave-alone named.

## What a round is NOT

- Not churn: cosmetic rewrites that change no reading experience are
  noise. The rounds that earned "great work" found REAL things —
  fake node ids in test fillers, a duplicated truth-read across
  features, a stale front-door README, seven loops violating our own
  doctrine.
- Not invention: when the well is dry, SAY the well is dry. "Further
  rounds would start inventing work" is a valued verdict, not a
  failure. The next real gains usually arrive with the next
  milestone's code.
- Not obedient: reviews may refuse a premise (P6). "Feel free to
  design and push back" is standing license — the best rounds have
  answered a request with a better-shaped alternative, or refused a
  trade (the uniform-node refusal) with the reasoning written down.

## Scope

Everything since the last round: `git status`/`git log` for the arc,
`wc -l | sort -rn` to find where the weight is. When a package is
named ("the language package is getting noisy"), read it WHOLE —
every file, no skimming. Claims like "the tree is clean" are only
made after literally reading everything they cover.

## The axes (hunt in this order)

1. DEBRIS: probe files, dead fns, stale scratch, leftover
   `gprobe`-style mains, no-longer-true comments. `git status` and
   grep are the brooms. When a RUNG lands, grep the diagnostics for
   promises of it (`arrive with`, `are recorded`) — a refusal that
   promised the future must either speak the landed remedy or name
   the NEXT recorded rung (the T2 round found four; two exposed an
   unscheduled ladder hole).
2. DOGFOODING VIOLATIONS: DOGFOODING.md is a CHECKLIST, not a
   suggestion — apply it back at the code. Loop shapes (`mut j`
   counters where `enumerate`/range-`for` belong — index arithmetic
   is the licensed exception), scans written as loops, sentinel
   values where `T?` belongs, unwrap ladders where one nested match
   belongs, `or`-runs for shared arms, `is` for single-variant
   questions, `with` chains over reassignment ladders.
3. DUPLICATION, by the rule of three: "two copies may wait; three
   never do." The third copy NAMES the concept — extract it where it
   belongs (core if core owns the type, the features root for shared
   feature checks, the pass file for pass logic). When only two
   copies exist, name the trigger that will force it ("the third
   arrives with `while`") and leave it.
4. CENTRALIZING / SEAMS: interfaces between things. Asymmetric
   shapes at a boundary (main smeared across fields while fns got
   real Bodies), fake values constructed to cross a seam, consumers
   keeping lists an owner should provide (`dst_of` beside the enum).
   The question: "what other interface improvements between things?"
5. IMPL GROUPING / VOCABULARY: a state struct's impl is its
   vocabulary — free fns that read as methods on an obvious receiver
   become methods (`store.stmt_value(s)`, not `stmt_value(store,
   s)`). Cross-module impls on core types are the proven pattern.
6. PROSE & POETRY: module docs tell the pipeline story (a module map
   in mod.av's header); the one fn that defines something reads as
   its table of contents (the language_features stanza); enums group
   by what variants ARE, not by the order milestones added them;
   extern walls move to their own file so the design file opens at
   the design; README tells the truth about today.
7. TEST HONESTY: no fake ids, no `value_missing()` fillers, no
   hand-rolled projections duplicating product code (a test golden
   should pin the REAL renderer). Goldens are exact; `contains` only
   where exactness is noise.
8. TOUCH-POINT AUDITS: when a milestone lands, count where the code
   actually went — capability cost (per-milestone, paid once) vs
   feature cost (steady state). Keep the growth ledger honest; audit
   falsifiable claims after the trial and AMEND them in writing.

## The species hunt (the round that earned "EXACTLY the type of cleanup I want")

Hunting NEW idiom species is a method, not a mood:

1. GREP BATTERIES: name a candidate smell, grep the whole tree for
   its shape (`mut found` flag scans, `xs[xs.length - 1]`,
   bool-literal if-else, name->value if-ladders, spelled-out
   pipelines, duplicated string literals, `.length == 0`). Run
   several related patterns per battery; batch them.
2. TRIAGE EVERY HIT, honestly: convert / license WITH A NAMED
   EXCUSE (reverse scan, index pairing, rebind-alias, dual-channel
   fold) / catalog for a later construct. A licensed site's excuse
   goes in the registry entry so it is never re-litigated.
3. PROBE BEFORE ASSUMING: when a conversion depends on a subset
   capability nobody has proven (`?` in a comprehension, `||` in a
   find predicate, index_of's miss value), write a scratch probe
   FIRST. Record the result in CLAUDE.md either way — working
   shapes shrink the trap-fear that causes ugly-but-safe drafts;
   corrupting shapes get a symptom signature.
4. EXTRACT SHARED LAWS, expecting bugs: a rule copied by hand is a
   law waiting to disagree with itself. The types_disagree
   extraction FOUND a user-facing cascade (one copy was one-sided).
   When an extraction changes behavior, that is a finding, not a
   conflict — probe it end to end (`./avra check` on a witness
   program), fix, and TIGHTEN the test that let it hide
   (contains() without a diagnostics COUNT hides cascades).
5. SWEEP EVERY PACKAGE, cli and tools included, and smoke-test any
   CLI path touched (`./avra explain F3005` both hit and miss).
6. Choose the RIGHT form, not the fanciest: match (returned
   directly) before table; table only when consumed as data; when
   only for condition arms. Over-abstraction is a smell too.

## The idiom registry and its ratchet

DOGFOODING.md opens with a NUMBERED idiom registry (I-codes) — the
future idiom engine's rulebook, written by dogfooding. Every round:

- Apply the registry back at the code (that is axis 2), and HUNT
  for idioms the registry does not know yet — a repeated shape
  with a more beautiful form is a NEW entry, landed in the round.
- A new idiom that a grep can catch gets a RATCHET RULE in
  tools/idioms.sh with its count pinned in tools/idioms.baseline;
  `make idioms` runs inside the gate and FAILS when a smell count
  rises. Deliberate exceptions bump the baseline in the same
  commit, visibly.
- When a round's fixes make a count FALL, re-pin with
  `make idioms-accept` in that round — a slack baseline lets new
  smells hide under old headroom.
- The write-time twin is CLAUDE.md's "idiom bar": first drafts are
  idiomatic, probes beat defensive loops, and probe results are
  recorded so the trap-fear zone shrinks.

## Feed the ledgers (every discovery has a home)

- bs2 gap or trap discovered -> CLAUDE.md "bs2 subset notes", with
  the symptom signature so it is never re-diagnosed.
- Pattern proven in tree -> DOGFOODING.md, with a real example —
  and an I-code entry in its registry when it is a RULE (smell +
  idiomatic form + licensed exceptions).
- The compiler's code WANTED a language construct -> ROADMAP sugar
  backlog, naming the wanting site (dogfooding is design; request
  your own features).
- Doctrine settled or trade refused -> ROADMAP, dated, with the
  reasoning ("considered and REFUSED" entries prevent relitigating).
- Deferred work -> a RECORDED TRIGGER with its firing condition,
  never a vague "later".

## Verify

`make gate` — suite plus corpus, eval == native == expected — before
any round is called done. Goldens that change must change because
the TRUTH changed, and the diff is inspected, not accepted. If a
fix touches lib-mode behavior, remember the front door is `./avra`
(never raw bs2 run) and `[dependencies]` staleness is a known class.

## Report (the shape that lands)

- Lead with what was FOUND, most substantive first — semantic finds
  before cosmetic ones.
- Quantify when quantities carry the argument (where the lines went,
  N loops fixed, files-per-feature before/after).
- Name every deliberate leave-alone WITH its trigger.
- End with the honest verdict: more to mine, or the well is dry.
- Nothing commits without the user's word; offer the commit message.
