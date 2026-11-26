# Durability levels — measured, and deferred

Status: DEFERRED WITH OWNER 2026-11-24. Measured on 395215ac (generation 1), a noop
`check packages/cli` over a store a cold check warmed.

## What was proposed

Salsa's durability levels: each input carries a durability, std's inputs the highest,
since std never changes within a toolchain. Each answer takes the lowest durability among
its reads. A warm run then skips verifying anything that reads only durable inputs.

## Why the program layer already has it

A salsa warm run re-verifies every dependency of what it asks, unless durability exempts
it. Here the frontier does that work once, up front (`QueryEngine.frontier_opened`):
- It asks its standing inputs.
- It works out what the changed ones reach.
- Every answer no change reaches stands with no check of its reads (`settled_from_frontier`).

An edit to a user's file never reaches std, so std's answers are never suspects. The only
std work a warm run still does is asking std's inputs, which means restamping its files.

## What skipping that would save

Two throwaway probes, not committed:

| noop of `check packages/cli` | instructions | wall |
|---|---|---|
| as it is | 1.208 G | 0.217 s (n=10) |
| std's stamps never taken (the durable skip) | — | 0.219 s (n=10) |
| every input taken as held, unasked (the bound on any durability) | 1.198 G | — |

- **The durable skip:** std's file-system calls fall from 2404 to 0, and the process's from
  5022 to 369. The wall doesn't move, because a stat of a cached file costs microseconds.
- **The bound:** every input held unasked saves 0.8% of the noop's instructions. That is
  the most any durability could save.

## Where a noop does go

Callgrind, inclusive, of about 1.21 G instructions:

| share | where | owner |
|---|---|---|
| 29% | `law_findings.per_program_const`: the per-program consts settled again, which re-reads item views (`item_view`, `Declarations.read_from`), so an answer on that path is not held | parity-values |
| 13% | `program_strays`: `runs_in` asked of every item | parity-values |
| 12% | `Frontier.standing_inputs`: the frontier's entries walked to find its inputs | wrong-answers' inputs queue |
| 14% | `input_holds`: the kept stamps' table decoded; the stat is a small part of it | — |

These are the warm targets. Each is measured, and the cost gate's warm rows ratchet each.

## When durability comes back

For an INSTALLED toolchain, std lives beside the compiler (`lib/avra`) and is never edited.
There its inputs could be taken as held for the compiler that shipped them: no stat, no open
and no stamp per std file.

On a machine whose file cache is cold, a stat is no longer microseconds. So if an installed
toolchain's first warm check of a session measures the stamps as a cost, durability can be:
- one bit per input, "the toolchain's own";
- held when the compiler's bytes are the ones that recorded it;
- with no level per answer, since the frontier already keeps the unreached from being asked.

Until that measurement, it stays deferred.
