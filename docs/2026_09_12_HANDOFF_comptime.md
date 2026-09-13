# Comptime lane — status and next-session handoff

> 2026-09-12, lane/comptime. This file is the resume: it maps the
> design doc's queue to what LANDED and carries a self-contained
> prompt for the next session. The design doc
> (`docs/2026_09_09_COMPTIME_DESIGN.md`, its status header, LANE
> HANDOFF and THE REMAINING QUEUE) remains the source of truth.

## Where the design stands

| slice | doc status | actual |
|---|---|---|
| S1 `const` settles (reach chain, budgets, `embed`, exportable) | — | **DONE** (incl. `export const`) |
| S2 `embed` + aggregate consts | STATUS: LANDED | **DONE** |
| S3a–S3e `@std/meta`, answer-type effects, effect doors | DONE | **DONE** |
| S3f two-tier namespace + generated twins | LANDED | **DONE** |
| S3g visible magic (`explain`, provenance, `expand`, doc comments, source printer) | LANDED | **DONE** (doc comments `f868c2f`) |
| S3h the proof (`Diagnostics` lint, Fn→Fn `@traced`, `@deprecated`) | LANDED | **DONE** |
| S4 `quote` + `${}` + `@derive` + `Show`/`Eq` | LANDED | **DONE** |
| S5a `const` seat mark | LANDED | **DONE** (one `SeatMark` channel, not parallel lists) |
| S5b settled seats widen `Sub` | LANDED | **DONE** (F2073 call-site law) |
| S5c per-instantiation folding | LANDED | **DONE** (also fixed a P1 wrong answer: a `const` reading a plain param) |
| BEYOND compiler self-derive (`@derive(Projections)`, `@derive(ValueProtocol)`) | LANDED | **DONE** |
| `export const` dogfooding | — | **DONE**: 87 `export const`, 368 call sites, 5 commits; F0902 relaxed |
| S5 refinements (forwarding, aggregate literal) | **OPEN** | pinned by failing-until-fixed tests |
| S4r `Code<T>` claim | **OPEN** | today a quote is `string` |
| S4r origin hygiene | **OPEN** | generated source resolves wholesale at the splice |
| shared `param` grammar rule | leave-alone, trigger named | not forced yet |
| private top-level `const` module scope | **NEW ASK** (dogfooding) | today file-local + order-sensitive |
| later list | open | static aggregate data, JIT, type operators, typed holes, manifest grants, parallel settlement, `@total` |

**Working state:** branch `lane/comptime`, worktree
`/Users/tristan/projects/tristanMatthias/avra-lane-comptime`, gate
green (compiler 2,292/2,292 spec + 88 programs; sqlite 414/414;
process 95/95; io 47/47), `make idioms` debt 0, tree clean.

---

## Prompt for the next session

```
Continue the comptime lane.

Worktree: /Users/tristan/projects/tristanMatthias/avra-lane-comptime
(branch lane/comptime). Read CLAUDE.md, then
docs/2026_09_09_COMPTIME_DESIGN.md — its status header, the LANE
HANDOFF at §6, and THE REMAINING QUEUE. Also read
docs/2026_09_12_HANDOFF_comptime.md's status table. Those are the
source of truth; do not re-derive what they pin.

WHERE THE LANE STANDS. S1 (including `export const`), S2, S3a–S3h,
S4 (quote/`${}`/`@derive`, `Show`/`Eq`), S5a/S5b/S5c, the BEYOND
self-derive, and the `const` dogfooding are DONE and gated. HEAD is
`6134110`. The gate is green — keep it so.

YOUR TASK — pick the first unblocked item below, in this order unless
the owner says otherwise:

1. S5 REFINEMENTS (small, ~1 day together; the failing tests already
   exist). Two boundaries that per-unit folding did NOT lift:
   - a settled seat FORWARDED to another fn: `fn outer(const y: int)
     -> int { inner(y) }` refuses F2073 today. Pinned at
     features/fns/tests/fns_test.av:256.
   - a direct AGGREGATE literal at a settled seat: `take(P { x: 3 })`
     refuses F2073. Pinned at
     features/fns/tests/fns_adversarial_test.av:170.
   Both want the OUTER unit's value carried through the template,
   which types ONCE and has no per-unit value; the mechanism is in
   the S5c landing (SeatValue rides Wanted/LowerCx, lower_root seeds
   registers, settled_symbol keys per unit) — extend it rather than
   inventing a second channel. A `dyn` method's settled seat stays
   enforced-but-unspecialized by construction: do not try to fold it.

2. S4r ORIGIN HYGIENE (~1–2 days, the higher-value S4 refinement). A
   template's own names must resolve in the module that WROTE the
   quote; a hole's at the splice site. Today generated source is
   parsed wholesale in the target, so a derive's private helper must
   be qualified and a `let tmp` could capture. Land a template-origin
   side table keyed by the spliced node plus a resolve that reads it.
   Proof: a derive's UNQUALIFIED private helper is found, and it
   cannot capture a user name.

3. S4r THE `Code<T>` CLAIM (~1 day). A quote's value is typed by its
   position and checked at splice; today it is a plain `string`.
   Land a `Code` meta type whose parameter is the claim, the hole's
   position types it, and a mismatch blames the annotation AND the
   template line. Proof: a wrong-shape hole refuses at the hole; a
   right one splices. (Design §3.5/§7 question 2 weighs `Code<T>`
   vs untyped `Code` — decide it and write the reason down.)

4. THE PRIVATE-CONST ASK (a language migration, not a patch). A
   private `fn` is module-visible and order-free; a private top-level
   `const` is FILE-LOCAL and F3001 "used before its definition", so
   ~60 internal constants had to be exported in the dogfooding
   (sugar backlog, survey 2026-09-12 #5). Make a non-exported
   top-level `const` a module declaration — WARNING: admitting every
   top-level const as a Decl changes same-name shadowing and turns
   two `const N` into a clash, so
   features/consts/tests/consts_adversarial_test.av must be updated
   DELIBERATELY. Get the owner's word before a semantic migration.

DO NOT START the fingerprint derive (`fingerprint_stmt`/`Expr`'s
per-variant arms) unless S4 quotes/templates are exercised first —
its per-variant choices are semantic and a guessed shape is a mirror
(design's Part-5 note; the inventory's classes D/E).

THE BAR, every commit. One heavy process at a time, in the FOREGROUND,
under the watchdog: `sh tools/watch.sh 4000 make gate`. `make idioms`
must stay at debt 0 (it ratchets; a NEW violation fails and you may
not raise the baseline). Tests: `sh tools/watch.sh 4000 ./avra test
<dir>` — and a SINGLE `.av` file runs alone (`./avra test <file>`),
which is sub-second and the way to iterate one spec. A program test
lives in a `tests/<name>/` package with a `.expected`.

THE GOTCHAS THAT COST REAL TIME HERE (all verified this lane):
- USING `export const` (or any new syntax) IN THE COMPILER'S OWN
  SOURCE STALES THE COMMITTED SEED: `seed-check` then fails (F3014 +
  a `text_of` cascade from the broken module). Run `make seed` in the
  SAME commit and let `make gate` prove `seed-check`.
- Recovery: if `build/avra` breaks, `make recover` links the committed
  seed and STOPS; `make bootstrap` ends with `make avra` and would
  overwrite the clean compiler — save the binary first, then rebuild.
- A compiler-source `@derive` cannot be built by a binary that
  predates it: build a guard-only compiler, save it, re-add the
  @derive, build with the save.
- A `const` in a specialized body may read ONLY its unit's settled
  seats (F2074). A template body skips its consts; a real unit folds
  them.
- A multi-line body must stay MULTI-LINE when converting a fn to a
  `const` — a single-line collapse makes the first `//` comment
  swallow the rest of the expression (the grammar-of-grammars trap).
- A global rename must respect SCOPE: a same-name definition in
  another file (`fn halver`, `fn words`, a method `words`) is hit by a
  name-only replace.
- Probe first: `./avra check` on a scratch file or a `tests/<name>`
  package answers most questions before any test exists.

Report at the end with the commits, the gate result, and any new law
you pinned (file it where the doc says, and add it to the design
doc's queue/status).
```

---

## Not surveyed / deliberately left

- The "later list" (static aggregate data, JIT behind `run_call`, type
  operators, typed sublanguage holes, manifest read grants, parallel
  settlement, `@total`) — each is its own campaign, not a lane slice.
- §7's five open questions are decisions, not work: type-as-value
  spelling, `Code<T>` vs `Code`, arms as a quote kind, budget defaults,
  package-namespaced diagnostic kinds.
- Test-file constant fns (the audit found many) were deliberately NOT
  swept: a converted const is shared across spec cases and each would
  need `export`, for little gain.
