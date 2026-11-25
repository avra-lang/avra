# A cell computed inside a re-entry is provisional (lead's design, avra-8sb5.57.182)

Law: a cell whose computation ran while a key it (transitively) sits under was RE-ENTERED saw a world
that key had not finished making. Its answer is provisional: it answers its asker, but it is never
memoized. The outer computation of the re-entered key, once it finishes, is the first answer that may stand.

Today: `start_recursive` on re-entry (kernel `ask` answers Cycle because `active(key)`) begins a NESTED
compute and records nothing. Cells computed above the outer frame then settle and memoize normally,
so `folded(plugin)` memoizes [0,32) while `expanded(plugin)` is still open and later splices more nodes.

Mechanism (std-relation engine, kernel.av):
- Each open frame (the `asker.open` stack entry) carries `provisional: bool` (false at begin).
- In `ask`, when the key is `active` (the Cycle case), find the OUTERMOST open frame with that key and
  mark every frame ABOVE it provisional (not the outer frame itself).
- In `settle`, a provisional frame does not store its value (abandon, as `db.abandon(k)` does for
  `methods`), and its asker stays provisional, which the marking above already covers.
- `methods`' hand-written guard is this law for one case. Leave it alone in this change; delete it after,
  if the law covers it (a follow-up).

Proof:
- the .182 two-annotation repro (`compiler/tests/query_annotation` with TWO `@icons` uses) prints
  `<svg/> | <svg/>` with no trap;
- std-relation tests by path (kernel/answers/fixpoint/frame tests: grep tests for `start_recursive`, `Cycle`);
- compiler tests that exercise recursion: `grep -rln "recursive\|cycle" packages/std-avrac/src/compiler/tests | head`;
- PERF: warm `check packages/cli` time before/after (3 runs each). A big regression means re-entries are
  common and recomputation is costly; report it rather than ship it.
