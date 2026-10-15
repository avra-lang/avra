# Memory, ownership and representation — RC with non-RC speed
2026-10-15 · design note (draft) · CHANNELS lead, on the owner's questions

## The premise
Refcounting is a **semantic** choice (deterministic destruction, no collector, no
pause, nothing to link when nothing needs it). The **counts** are a **codegen**
choice. Keeping the first while paying for the second only where unavoidable is a
solved design — this note names it, says what Avra already has, and what is missing.

## Three separate overheads (they are usually conflated)
| | what it is | addressed by |
|---|---|---|
| **(a) counts** | a retain/release per hop | **RC elision** (below) |
| **(b) headers** | 16 bytes (tag, kind, rc, len) before every payload | **representation** (a layout choice) |
| **(c) indirection** | a pointer per element vs inline storage | **specialisation** (a layout choice) |

**RC elision removes (a) and nothing else.** A stream of boxed records pays (b) and
(c) no matter how perfect the counts are. So the two questions are separate, and
Avra needs an answer to both.

## Part 1 — RC semantics, ownership-typed codegen (the (a) answer)
**Perceus** (Reinking/Xie/de Moura/Leijen, PLDI 2021; the runtime behind Koka) shows
RC can be GC-competitive — ~**1.0 counts per allocation** vs naive ARC's 2–4× — by
moving the decisions to the compiler:
1. **Borrow inference** — infer which seats are borrowed, so a read-only call emits
   ZERO counts. **Avra has this** (`A PARAMETER IS BORROWED`; callee-cleans cost 1.3
   billion counts in one `check` and 15% of its CPU before removal).
2. **Dup/drop specialisation** — emit a count only where a value is actually
   duplicated or dropped; a value whose last use is a store into a fresh slot is a
   **MOVE**. **Missing.**
3. **Reuse** (FBIP, "functional but in-place") — hand a **dying** value's storage to
   its replacement, so the heavy path is no free + alloc at all. **Missing.**

With all three, ownership is **inferred** — the author writes plain code, the
compiler proves borrow/own/consume exactly as a linear-type system would. That is
linear-type performance with refcount semantics and no ceremony (P6: not a trade).

**Avra today:** ✅ borrow, ✅ uniqueness (`rc == 1` → in-place write,
`avra_cell_unique`), ✅ unboxed scalar slabs; ❌ last-use moves, ❌ reuse, ❌ weak
captures (CYCLE leaks — 922 MB in the test binary, sugar backlog).

## Part 2 — Representation (the (b)+(c) answer, and where the owner's instinct is right)
A stream of values that are all boxes pays the header and the indirection whatever
the counts do, and **this generalises far past channels** — lists, maps, queues,
streams, every container of records.

The substrate already has the tools (`runtime/avra_box.h`):
- an `AvraArray` is a **slab of `int64` cells with one mark byte each** — scalars are
  **unboxed** ("a nullable int lives in one word and one bit, with no box");
- a managed element is a **pointer + a mark**, not a fresh box;
- static aggregates are laid-out globals (`Ins.StaticAddr`) — the binary's own data;
- a record of ONE scalar field **flattens** to the field.

What is missing is **generality**: the layout is chosen per shape today, not by rule.
The design rule to adopt:
> **The element type decides the representation, and the compiler picks the cheapest
> layout that preserves the semantics.**
- unmanaged (`int`/`float`/`bool`/`Ptr`) → a **slab** of that width;
- a record of scalars → a **flat struct array** (AoS), not pointers to boxes;
- a managed value → a **handle** (pointer + one count) — the honest cost;
- a **stream** → a ring that carries the element's layout, so a producer and a
  consumer share one buffer with **no per-item allocation at all** (the SPSC ring);
- and an **escape hatch** where it matters: a way to force a layout at a seat,
  because a rule with no exception is a rule people work around.

This is P12 (one source of truth, many projections) applied to memory: the value is
one thing; its **layout is a projection**.

## Part 3 — Where the passes live, and whether to iterate ("rolling")
Passes have ONE signature (`pass(parsed, ...upstream) -> Facts`), each OWNS its fact
tables (and its diagnostics), and `analyze` is the **only** place the order exists.
So this work is not one pass but a small family, and their homes are:

1. **An `Ownership` facts table** — per register: borrowed / owned / dying /
   shared. **Consumed by memory**, not merged into it (a fact table owns its facts).
2. **The memory pass** (`compiler/memory/memory.av`) is where counts are PLACED —
   so dup/drop specialisation and last-use moves are an enhancement of *it*, driven
   by (1).
3. **A cell read-modify-write pass** — recognise `let t = c.get(); …; c.set(t)` and
   lower it to an in-place update behind a uniqueness check. This removes the
   **whole-buffer copy** that makes a `Cell`-held collection quadratic, and it is
   the P6 collapse: value semantics stay, the copy moves from read to write and
   disappears when unique.
4. **A reuse pass** (last) — pairs a dying allocation with the new value's shape.

**On iterating ("rolling"): yes, and Avra is unusually well placed for it.** Some
optimisations feed each other (inlining exposes constant folding exposes inlining),
so a pass manager runs a small pipeline to a **fixpoint**. The trap is that
iteration is unbounded and its cost is compile time. What makes it cheap here: the
passes are **pure queries over a memoized DB**, so re-running one whose inputs did
not change costs a cache hit — iteration is almost free in this architecture
precisely because of the DB campaign. So: iterate where the gain compounds, bound
the rounds, and measure the compile-time cost with the same instruments
(`explain --stats`, `make census`) as the runtime cost.

**Guiding principle, from the campaign's own ledger:** *price the frame-to-body
ratio before paying.* These are optimisations paid for in COMPILE time to buy RUN
time — so each one needs a counted before/after on both sides, never a stopwatch.

## Part 4 — The measurement that decides the order (all three counts)
One channel drain, measured as THREE per-item counts — **allocations, retains +
releases, copies** — with the sites for whichever dominates:
- dominated by **copies** → the cell-RMW pass (§Part 3.3) + the in-place API;
- dominated by **counts** → ownership elision (§Part 1.2–3);
- dominated by **allocations** → reuse (§Part 3.4).

**All three are wanted in the end; the census decides the ORDER, not the choice.**
