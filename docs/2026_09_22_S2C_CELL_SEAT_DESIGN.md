# S2c — the receiver/parameter cell-seat ABI: what it means today

Scope note: `docs/2026_09_07_S2C_DESIGN.md` is a DIFFERENT "S2c" — the
HTTP campaign's per-package dylib for `avra run`'s extern host. Not
this. This note is `avra-8sb5.4.4.2`, the third of S2a/S2b/S2c.

RECOMMENDATION UP FRONT (detail below): do not build an inout ABI.
S2a and S2b already deliver everything S2c's four phrases were meant
to buy, by a different mechanism than the one they were coined for.
Retire the one live gap (F3005's wording) and close the task.

## 1. Today's mechanism, quoted

**`mut` LOCAL rebinding** (S2a, landed `e0c6c61`): `mut ys = <place>`
copies. No cell, no aliasing — `features/mutation/check.av` types it
as an ordinary slot.

**`mut` PARAMETER / `mut fn` RECEIVER**: unchanged by S2a — still
aliases the caller's box, exactly as before H3 narrowed it. A method
call lowers the receiver as a plain value register, no address:
`declared_dispatch` — `let recv = cx.reg_of(subject)` ... `Ins.Call(dst,
symbol, [recv].concat(regs))` (`features/impls/lower.av:52-58`).
Ordinary calls do the same: `call_lower`'s plain path,
`features/fns/lower.av:6-21` — `let regs = [cx.reg_of(a) for a in
args]`, then a bare `Ins.Call`. No `mut` seat carries an address on an
Avra-to-Avra call, today or ever — write-through works only because
a MANAGED value already rides a shared heap pointer, so a field write
mutates what every alias sees. This is F2047's whole subject
(`features/checks.av:587-621`, `mut_place`/`receiver_law`/`root_word`):
a WARNING, still, on a writing call through a non-`mut` place.

**F3005 — a `mut` seat assigned WHOLE**: refused, and its own words
say why nothing backs it: `features/mutation/resolve.av:64-67`,
`seat_whole` — *"`${n}` is a `mut` seat — assigning it whole arrives
with the inout ABI"*, doc comment above it: *"RECORDED TRIGGER: … lands
with the inout ABI, where the seat is the caller's cell (ROADMAP: the
inout receiver, S2); until then a seat is written along a path."* This
is a forward reference to the ORIGINAL 2026-09-04 "S2 THE ABI" design
(ROADMAP.md:14743-14747), never built.

**The EXTERN inout ABI — fully built, C-only.** A `mut` seat on an
`extern fn` hands C the ADDRESS of a LOCAL's cell:
`features/fns/check.av:29` (`checked_extern` → `inout_able`, seats
`ptr`/`i64`/`i32`/`u32` only), `features/fns/check.av:417-424`
(`inout_args_law`, `cellless_place` — "only a LOCAL binding owns a
cell"), `features/fns/lower.av:37-54` (`host_regs`/`seat_reg`/
`cx.cell_of(a)`). `cell_of` (`features/contexts.av:401-407`) answers a
register ONLY for `.Def(s)` — a `mut x = e` LOCAL — and `null` for
`.Param`, `.Receiver`, every other binding kind. `core/ir.av`'s own
doc: *"`cells[j]` is the width of the CELL BEHIND an inout seat …
Only an extern fills it: the registry's own rows take addresses of
nothing."* `RtHost` (the evaluator's per-row arm enum) carries
`CellUnique`/`CellRelease`/`SlotUnique`/`SlotSet` — the runtime
primitives a `mut` LOCAL's box and `Cell<T>` share, not a receiver/
parameter ABI. This machinery is real, general (any C body), and has
nothing to do with S2c — the two must not be conflated when scoping
"the runtime row and its host."

**`Cell<T>`** (`features/cells/mod.av`): `new`/`get`/`set`/`push`/
`set_at`. `set`/`push`/`set_at` carry `ReceiverEffect.Shared`
(`features/mod.av:49-61`), NOT `.Write` — so `row_writes` answers
false and F2047 never fires on a Cell mutation, by design: Q2(a)'s
"get/set, no forwarding" ruling is exactly this row shape. Backed by
`avra_slot_set`/`avra_array_push`/`avra_cell_unique` — the SAME
primitives a `mut` local's box uses (`features/places.av:49-58`,
`unique_box`'s `.Root` case).

## 2. The four phrases, then vs. now

**"the cell seat for receivers and parameters"** — 2026-09-04 meant a
genuine inout ABI generalized from the extern one: pass the caller's
slot ADDRESS into an Avra callee so a `mut` seat could be reassigned
whole. NEVER BUILT. The CEO's 09-16/17 ruling (avra-8sb5.4.4,
avra-8sb5.8.2) took a different fork entirely — delete aliasing for
LOCAL rebinding, keep receiver/param aliasing as it always was (a
warning, F2047), and make all OTHER sharing an explicit `Cell<T>`.
Nobody revisited whether the seat-ABI half of the old plan was still
wanted; it just stopped being the path taken.

**"the runtime row and its host"** — would have been a new `RtHost`
arm / `CallRt`-shaped vocabulary for passing a caller's slot address
on an ORDINARY call (the extern one, `inout_row`, is declaration-
scoped to `rt_sigs()`, `core/runtime_api.av:206-208`, and stays that
way per "THE VOCABULARY SEAM RULE" — DATA vs BEHAVIOR). Nothing of
the kind exists for Avra-to-Avra calls. The only "cell" runtime rows
today (`avra_cell_unique`, `avra_cell_release`, `avra_slot_set`) back
`mut` locals and `Cell<T>` — value slots, not receiver addressing.

**"flat receivers unboxed"** — MOOT, and provably so. The type
registry already forces boxing wherever a record could need
write-through: `core/types.av:337-350`, `unflatten` — *"A record
KEEPS its box: an impl may write through `self`, and a value in a
register has no identity to write through … STICKY."* Called from
THREE declare-time sites: a `mut fn` method receiver
(`compiler/typing/impls.av:~90-100`, with a documented carve-out for
a purely-reading impl, e.g. a derived `Fingerprint`, which does NOT
seal), a plain `mut` PARAMETER of record type
(`compiler/typing/declare.av:174-182`, `keep_boxed` — *"a `mut` seat
KEEPS ITS BOX … a flat record is a value in a register with no
identity to write through, so a one-field record would break where a
two-field one works"*), and a NAMED type's own mut-seat law
(`compiler/interface.av:92`). MEASURED, both engines: a record whose
only field is `int` (the flatten law's exact shape,
`features/decls.av:517-527`) with a self-writing method, called
through a plain `let`, aliases —
```
type K = { n: int }
impl K { fn bump() { self.n = self.n + 1 } }
let a = K { n: 1 }
let b = a
a.bump()
"${a.n} ${b.n}"        // eval "2 2", native "2 2"
```
`b` sees `a`'s write, which is only possible if `K` is BOXED — the
"flat, no box" case the original corpus pair worried about cannot
arise for anything the receiver/seat law ever touches. The only
genuinely-flat, forever-unboxed values are bare scalars (`int`,
`bool`, `float`, `ptr`) with no fields to box at all — and THAT case
is exactly F3005 (below), not a receiver problem.

**"the corpus pair"** — largely delivered already, under other names:
S2a's oracle triple (`features/tests/borrow_{param,local,reread}`,
`1 1 0 / 0 / 1 1 1`, both engines) and S2b's
`compiler/tests/workspace_test.av` cover the write-through/no-longer-
aliases shapes the old corpus pair enumerated (root receiver, nested,
nothing captured survives). What is NOT pinned anywhere: a program
proving `Cell<T>` is the general, working answer to "reassign a value
from inside a callee" — which the old design didn't anticipate because
it planned to solve that with the ABI instead. Probed here, clean,
both engines:
```
fn zero(c: Cell<int>) { c.set(0) }
let c = Cell.new(5)
zero(c)
c.get()                 // 0, no warning, no `mut` needed anywhere
```

## 3. What it buys — measured, not assumed

**F3005 retired?** Only if the ABI is built. But `Cell<T>` already
retires the NEED (§2's probe) with zero new machinery. Building the
ABI to ALSO permit `n = 0` on a bare `mut n: int` buys a second,
narrower spelling of a capability `Cell<T>` already has in general
(a record, a list, any T) — not a new capability.

**F2047 sites retired?** MEASURED: zero, and structurally so.
`check packages/cli` on `8491d2b`/main `dcbed37` (Sprite `avra-sq-ffi`,
`AVRA_BUILD_SLOTS=1`, `--prebuild`), F2047 count deduped by
`file:line`: **67 unique sites** (68 raw warnings — one repeated
span), concentrated in `compiler/workspace.av` (12),
`features/contexts.av` (9), `compiler/lower/lower.av` (6),
`compiler/derive.av` (5), `cli/src/commands/shared.av` (4), the rest
in ones and twos across `workspace_analysis.av`, `suite.av`,
`program.av`, `build.av`, `analysis.av`, `sublang/builders.av`,
`contract.av`, `resolve/walk.av`, `cli/commands/{ir,explain,run,fmt,
expand}.av`. Every one of these fires because a writing call's ROOT
is not `mut` — the fix is always "declare the root `mut`" (free,
already works via the shared box) or, where the root is a lambda
capture, "Cell it" (S2b's exact pattern — the residue S2b's own
closing comment names as "each needing its own state celled," a
separate slice). AN INOUT ABI RETIRES NONE OF THESE: F2047 is about
non-`mut` PLACES calling writing methods, not about seats that need
addressing. The ABI's only theoretical customer is F3005, and §2/§3
already showed `Cell<T>` covers that customer today.

**Performance claim: none to measure.** An inout ABI is pure new cost
— a new calling-convention path (marks on `Arrow`, `seat_reg`-shaped
plumbing duplicated into BOTH the evaluator and LLVM, by the IR growth
protocol's own 5-step gate: JUSTIFY, GENERALIZE BEFORE ADDING, PAY
EVERY CONSUMER, catch-all-free matches, `make vocab`/`avra new ins`
scaffold). Nothing in the tree asks for faster write-through; the
existing box-aliasing path costs one retain, already accounted for
under "A PARAMETER IS BORROWED" (`compiler/memory/memory.av:1-12`).

## 4. Risks, if built anyway

**Seed/build ladder.** `mut fn` occurs 396 times, a `(mut `/`, mut `
parameter shape 892 times, tree-wide in `packages/std-avrac/src`
(non-test, grep count — an upper bound, not exact seat count). A
calling-convention change to how ANY of these pass their seat is
"A SYNTAX CHANGE TO THE COMPILER'S OWN SOURCE" and "A CHANGE THE
COMPILER MUST THEN READ REACHES THE PRODUCT ON THE SECOND BUILD"
territory (CLAUDE.md, Working discipline) — the four-generation
ladder (`cp build/avra build/avra.pre`, old-spelling build, script
rewrite, new-spelling build, gate), because the compiler's OWN 17+
aliasing sites (H3's census) and hundreds of `mut` seats would need
to compile under whichever seats gain addresses.

**Extern inout confusion.** `RtSig.cells`/`inout_row`/`cellless_place`
are a closed, working, C-specific mechanism. A new Avra-level cell
concept sharing the word "cell" (already true of `mutation`'s local
cells AND `Cell<T>`) is a THIRD unrelated use of the word in one
codebase — a documentation and a naming hazard on its own, independent
of whether the ABI is built.

**Memory pass: undesigned.** `is_managed`/`standing_regs`
(`compiler/memory/memory.av:25-77`) have no notion of "a reference
into a CALLER's frame slot" — every register today is either the
callee's own binding or a param that "stands for the call" because
the CALLER keeps it alive. An inout cell's lifetime is the CALLER's
frame, referenced from inside the CALLEE — who releases it, and when,
is a new question the pass does not currently ask anywhere.

**The read-wears-the-type-of-what-is-read family.** An inout seat's
read is the callee's LOCAL type; its write crosses back into the
CALLER's storage type. This is exactly the class of bug CLAUDE.md
documents paying for three times already (a captured callee, a
capture, a field read each once wore the wrong node's type) — a
fourth instance is not a hypothetical, it is the SHAPE of what this
ABI would add.

## 5. Sub-slice plan

Given §3 (buys nothing F2047 needs, and `Cell<T>` already buys what
F3005 needs) against §4 (a compiler-wide calling-convention change,
undesigned in the memory pass, a live bug-class magnet) — **P6, paradox
collapse: the false dichotomy was "build the ABI or leave F3005 as a
forever-unpaid promise." The collapse is that `Cell<T>` already is the
general answer; F3005 was never missing a mechanism, it was missing
the right WORDS.**

**Slice 1 — reword F3005, retire the recorded trigger.** Change
`features/mutation/resolve.av:67`'s message and help to point at
`Cell<T>` instead of a promised ABI: e.g. *"`${n}` is a `mut` seat —
assigning it whole has no shape; wrap the value in `Cell<${T}>` and
call `.set(…)`, or write a path under it."* Delete the "RECORDED
TRIGGER … ROADMAP: the inout receiver, S2" doc comment above it (the
trigger is retired by this note, not by a future landing). Update
CLAUDE.md's "The subset today" F3005 entry (it is currently silent —
F3005 is listed among "Laws that SPEAK," not in the enumerated
gaps — so this is a wording-only change, no entry to move). Files:
`features/mutation/resolve.av` (message), `dev/witnesses.av:222`
(the golden — confirm its rendering still matches). ACCEPTANCE: the
witness `CodeWitness { code: "F3005", … }` re-renders with the new
words; `impls_test.av:134-135`'s "waits on the inout ABI" case updates
to assert the Cell-pointing message; a new spec case shows the
`Cell<int>` rewrite compiling clean (the §2 probe, committed). Gate:
full suite + Sprite.

**Slice 2 (optional) — the corpus pair, explicitly.** One program,
`corpus/cell_reassign.av`: a `Cell<int>` and a `Cell<K>` (K a struct)
each reassigned whole from inside a plain (non-`mut`) parameter,
eval == native. This is the only piece of "the corpus pair" not
already covered by S2a/S2b's tests; it is a 20-line program, not a
design question.

**Slice 3 — NOT recommended, filed instead.** If the master or owner
still wants ergonomic whole-seat reassignment WITHOUT the `Cell<…>`
wrapper (`fn zero(mut n: int) { n = 0 }` compiling as sugar over an
implicit `Cell<int>` seat) — that is a NEW sugar-backlog ask, not a
completion of S2c: name it in ROADMAP's sugar backlog with this
note's §1-§4 as its design record and F3005's two witness sites as its
wanting sites, and scope it separately with its own gate (it still
carries all of §4's ABI-shaped risk if built as a REAL inout path;
if built as sugar that lowers to `Cell<T>` under the hood, it is much
smaller — a resolve-time rewrite, no new Ins, no memory-pass work —
and that is the version worth costing if anyone wants it).

**Close avra-8sb5.4.4.2** as DELIVERED-BY-DESIGN (S2a deleted the
channel F3005 warns about at the local level; the receiver/param
channel it warns about at the call level was never actually blocked
on an ABI — it was blocked on the wrong WORDS) once Slice 1 lands,
rather than carry it open waiting for machinery that would cost a
four-generation build ladder to buy nothing S2b's F2047 backlog or
`Cell<T>` don't already cover.

## Rulings needed (options + recommendation, not open questions)

**(A) Is `Cell<T>` the intended permanent answer for "reassign a value
from inside a callee," making the inout ABI out of scope for good?**
(a) YES — recommended; matches Q1(a)/Q2(a)'s ruling that Cell<T> is
the ONLY sharing door, and §3 shows it already does the job. (b) NO,
build the ABI anyway for ergonomics — costs §4's risk for a spelling
difference; not recommended.

**(B) Reword F3005 now, in this survey's own follow-up slice, or wait
for a separate task?** (a) NOW — recommended; it is a message-and-doc
change, low risk, and leaves no stale "arrives with the inout ABI"
promise standing. (b) Wait — leaves a known-wrong forward reference
live with no reason to.

**(C) Close S2c as delivered, or re-scope as a sugar-backlog item?**
(a) CLOSE, file the sugar ask separately if wanted — recommended,
matches what was actually found. (b) Re-scope S2c itself into the
sugar-over-Cell design — conflates "the ABI never needed building"
with "a new sugar feature," muddying both records.

## What I wanted from the language and did not have

A way to ask the compiler directly "is type T flat/boxed under its
CURRENT declared seats" would have turned §2's "flat receivers
unboxed" finding from a 20-minute probe-and-grep hunt into a one-line
check — the representation question this whole task turns on has no
first-class answer today, only the scattered `is_flat`/
`rides_pointer`/`boxed_flat` internals I had to read cold. This is
already tracked: `avra-39bs`, "Ship `repr_of` through `avra explain`"
(FIRED-UNPAID) — this survey is its second consumer, noted there
rather than re-asked here.
