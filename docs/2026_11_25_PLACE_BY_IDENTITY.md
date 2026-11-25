# Placement proportional to what changed — plan (no code)

**The aim:** a window move places only its new rows; a kept row's box costs a lookup and an addition.

## Why the solver cannot today (place/solve.av, 647 lines)

- **Sizes live for one call, keyed by path.** `place_fine` makes a fresh `Ctx { known: no_sizes() }` per call, and
  `max_w`, `min_w` and `height_at` remember their answers under `"M${path}"`, `"N${path}"` and the like, where a path is
  the child index chain (`"0.3.17"`). Nothing survives between paints; and in a windowed list a move shifts every row's
  index, so within one call a row's sizes are keyed by where it stands, not by what it is.
- **Boxes are absolute.** `arrange(cx, n, path, x, y, w, asked_h, sure)` receives its absolute `x, y`, and every `Rect`
  it returns is "from the root's top-left corner". A subtree placed last paint cannot be reused at another offset without
  rewriting every rect under it.
- **`kept_of(cx, n, path)` depends on the path.** The terminal's measure keeps a gutter beside the node the keys go to
  (`Cells.focus`, compared to the path), so one of the measure's own answers is path-dependent today.

## The change, inside place/ (the public `place`/`place_fine`/`Placed` stay as they are)

1. **A solver that persists** — `export type Solver = { sizes: Cell<Map<string, int>>, placed: Cell<Map<string, Local>> }`
   held by a target between paints, and `place_with(s: Solver, root, m, width) -> Placed`. `place` and `place_fine`
   become `place_with` over a fresh solver, so every existing caller is unchanged.
2. **Sizes keyed by node identity**: `max_w`, `min_w` and `height_at` key on the node's identity (its box address, the
   node held by the solver so the address stays its own — the same rule as the native lowering memo) plus the width or
   room asked, never the path. Identity is sound because a node is a value: the same node at the same width sizes alike.
3. **A placed subtree relative to its parent**: an inner `arrange_local(cx, n, w, asked_h, sure) -> Local` answers the
   node's size and its children's offsets from its own corner (`Local = { w, h, kids: List<Offset> }`,
   `Offset = { dx, dy, at: Local }`), remembered by (identity, w, asked_h, sure). A kept row is then one lookup.
   `arrange` becomes the walk that turns a `Local` into today's absolute `Placed`, adding offsets on the way down.
4. **A list's offsets by arithmetic**: a column's children are laid by `flow`; with each child's `Local` a lookup, the
   offsets are the running sum of heights and gaps — what `flow` already computes, now over remembered sizes. A spacer
   is a fixed height. Only a new row is measured and arranged.
5. **The path-dependent measure answer**: `kept_of` (the terminal's focus gutter) must stay out of what is remembered by
   identity alone. Either the measure says which nodes it answers by path (`Measure.by_path(n) -> bool`, true only for the
   focused node) and those are not remembered, or the focus mark becomes a property of the node (an attribute the
   terminal sets), so it is part of the node's identity. **An ask**, below.
6. **Forgetting**: the solver drops entries no paint reached in the last two (as the spike's caches do) and forgets
   everything when the target says its measures are stale ("measure again").

## Size of the change, by fn

| fn | Change | Lines (estimate) |
|---|---|---|
| `Ctx`, `no_sizes`, new `Solver`, `place_with` | the persistent solver; `place`/`place_fine` over a fresh one | ~30 |
| `max_w`, `min_w`, `height_at`, `remembered` | keys by node identity and width, not path | ~15 |
| `arrange` → `arrange_local` + the absolute walk | relative boxes, remembered by identity | ~40 |
| `flow`, `cross_sizes`, `item_of` | read children's sizes through the remembered `Local`s; no new math | ~15 |
| `kept_of` | the path-dependent answer kept out of the memo (per the ask) | ~10 |
| `whole` | unchanged: snapping still runs over the absolute boxes, so rounding is byte-identical | 0 |

About 110 lines of 647, all inside place/.

## What the web and the terminal see

**Nothing.** `place` and `place_fine` answer the same `Placed` for the same tree: absolute boxes are rebuilt from
relative ones by the same additions in the same order, and `whole` snaps the absolute edges as it does now, so no
rounding moves. Witnesses:
- place/tests (41 cases and their programs) byte-identical;
- the layout oracle (`make layout-oracle`: the solver against Firefox on random trees) unchanged;
- the terminal's and tui's suites unchanged;
- a check mode in `place_with` that also places fresh and traps where a remembered box differs (as `AVRA_SPIKE_CHECK`
  does for kept rows), run once over the iOS bench.

## What it buys (from the simulator's numbers)

Placement is ~1.5 ms a window move over ~34 rows and ~1.1 ms for the solver's walk alone; with kept rows a lookup, a move
of ~9 new rows should place in ~0.3–0.4 ms, and a toggle (one row) in under 0.1 ms.

## Asks

1. The path-dependent measure answer (`kept_of`, the terminal's focus gutter): kept out of the memo by a `by_path`
   question on `Measure`, or made a property of the node?
2. The solver persisting per target (held beside the native page and the web page), or per app?
3. Node identity by address, through the runtime's box key as the native lowering memo uses it: the same row, shared by
   both memos?
