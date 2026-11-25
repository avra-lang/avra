# The retain → cell_release bucket: a design note

Scope: what is left of the direct `Ins.Retain` runs whose next runtime call is `avra_cell_release`,
on a cold `avra build packages/cli` (program layer). No code here — the shapes, what each rule
would be, and its hazards.

## Measure

Census compilers built on Linux from one source (lane tree at 63ca9c2, R2a in), retain sites
classified by the first call after the site (top 400 sites, 473.8 M of 973.6 M retains):
**61.6 M retains → avra_cell_release.** The bucket splits two ways. A split is "A" when the register
handed to the retain is loaded from the same frame slot whose address the next `avra_cell_release`
takes:

| shape | runs | top sites |
| --- | --- | --- |
| A — the answer is a load of a cell the same exit settles | 22.7 M | SignedType.word 3.2, Stack.top 2.2, flatten (two instances) 4.3, question_held 2.0 |
| other — an early answer that is a param or a view, and stores of a value that does not move | 38.2 M | Lexing.routed 12.8, DiskStore.unpublished_answer 1.9, Segment.saved_in 1.8, reaches_out 1.5, TapeWriter.number_of 1.3 |

(Linux census: a census runtime needs `-fno-omit-frame-pointer` and the census compiler built with
`AVRA_FRAME_POINTERS=1`. `note_made` reads `__builtin_return_address(2)`, which walks off a frame
with no frame pointer: a segfault in `box_alloc` from `avra_args_init` under `AVRA_MEM_STATS`.)

## Shape A — an answer that moves out of its cell (≈ 23 M)

```
r26 = load r3          // mut out: the answer's own cell
retain r26             // "retain: a load that outlives its cell"
call avra_cell_release(r7)
call avra_cell_release(r3)
yield r26
```

The scope's close settles the cell, and its yield is that cell's own load. Retaining the load and
then releasing the cell is a transfer: the cell's reference becomes the answer's. **Rule:** a
`ScopeExit`/`FnExit`/`RetVal` whose `gives` is a `Load` of a cell that this same exit settles, with
no other borrow of the cell read after it, emits `avra_cell_forget(slot)` in place of
`Retain(gives)` + `avra_cell_release(slot)`. The machinery exists already: `Handover.Emptied`,
`cell_forget` and `refilled_cell`'s `borrowed_past`.

Hazards:
- **A second load of the same cell still read.** `borrowed_past` already asks this question.
- **A view of the load yielded instead of the load.** The rule applies only when `gives` *is* the load.
- **The cell is settled by an outer scope, not the exiting one.** At an early exit, `exit_cells`
  settles every scope from the floor. The forget replaces exactly that cell's settle, wherever it is
  placed in the exit's list.
- **The exit runs more than once per store,** e.g. a `LoopJump` turn's end. Only a function or scope
  exit that takes the cell with it qualifies, never a turn.

Witness shapes: `mut out = []; …; out` (flatten); `let held? = … else { return … }; held` through a
narrowing cell (Stack.top); an early `return cell_value` beside a later read of the same cell
(must keep the retain).

## Shape B — an early answer that is a param (Lexing.routed 12.8 M): MEASURED, DROPPED

`return s` with `s` a param: "retain: an early answer no scope owns", then the exit settles the
function's cells. The retain is the answer's own count under A PARAMETER IS BORROWED. The proposal:
an ANSWERABLE seat (some exit yields param j itself) answered with no count, and every direct call
followed by a settle row — release the dying argument unless the answer is it, or retain the answer
if it is the kept argument.

Tallied on a cold cli build (lane tree on 3d35d216, probes each adding one balanced retain+release,
so each delta is an exact run count; reclaims identical):
- static: 230 fns with an answerable seat; 780 of 98,955 direct call sites call one; at 255 the
  argument dies there; 4 marked fns are taken as values (std-relation `Scope.file_spelled` /
  `file_unspelled` instantiations);
- dynamic: 21.95 M calls of marked fns; 19.94 M answering runs; 13.87 M calls whose argument dies;
  so the pairs saved lie between 11.86 M (inclusion–exclusion) and 13.87 M — about 1 % of
  1.355 G retains — for a settle row (compare and branch) at all 21.95 M calls and a new row the
  L2 checker must learn.

Dropped: it does not pay for a row at every call of 230 fns. Not to be reopened without a cheaper
form that needs no runtime compare.

## Shape C — a store of a value that does not move (the rest, ≈ 25 M)

The mut-cell protocol: `Retain(src)` when `src` does not die at the store, then `avra_cell_release`
of what the cell held. In the top sites `src` is a view: a lending read, or a load of another cell.
Typical is the loop variable or cursor re-pointed every turn to a part of a box that stands for the
whole loop (`TapeWriter.number_of`/`wrote`, the untold parser's `r76` captures). **Rule (a cell of
borrows):** a counted cell whose every store is a view rooted at a standing register (a param, or a
load of a cell that no store in the cell's life changes), and none of whose loads is given upward,
holds no reference. Its stores take no retain, and nothing settles it. Hazards:
- the root changes while the cell holds a view of it (a store into the root's cell, or a user call
  handed the root) — the same question `root_handed`/`cell_handed` already answer per call;
- a load of the cell that escapes upward (a yield, a store into another cell, a pack), which then
  needs its own retain at that point — the `borrow_outlives` scan, run from each load;
- a mixed cell, where one store is owned and another borrowed, stays counted.

Measure each before building: tally the placed sites with `AVRA_RC_REASONS` first (a "candidate:"
reason per shape), then the census, as for R2a and R1b′.

## Where the counts stand: the census by reason, and two rules measured and dropped

Cold cli build on the program layer, one probe compiler adding a balanced retain+release beside every
count of one reason, one census per reason from one source (each delta an exact run count):

| reason | runs | share of 1,364 M retains |
| --- | --- | --- |
| owned-twin rows (a lending read taking its owned twin; rows answering a stood box) | 736.6 M | 54.0 % |
| row keeps (`_owned` push / put / set of a managed value) | 364.6 M | 26.7 % |
| owned load (a cell load outliving its cell) | 71.1 M | 5.2 % |
| held view across a call | 37.2 M | 2.7 % |
| scope yield not owned | 29.0 M | 2.1 % |
| cell store of a value that does not move | 19.5 M | 1.4 % |
| early answer no scope owns | ≈ 16.3 M | 1.2 % |
| flat-record pack | 12.0 M | 0.9 % |
| runtime-internal rest | 78.0 M | 5.7 % |

**A LENT ANSWER (rule T) — DROPPED.** A fn whose every answer is a view of one seat answers it
uncounted, the caller riding its own argument. 76 fns qualify (11 taken as values); 219.2 M calls;
210.2 M twin retains held for their answers (gross). Under the independent lane's conditions — the
result counted wherever it escapes or is kept (M1) and held across any call that can reach its root
(M2) — 11.95 M pairs remain (0.9 %), at 143 call sites, for an ABI mark every caller kind, cache key
and checker must learn. Not to be reopened as an ABI rule; see the inline design below for the same
views without one.

**A KEEP THAT MOVES — CLOSED.** Of the 364.6 M keeps, 174.0 M keep a param and 166.4 M a view:
borrowed values a keeper must count. Of 22.8 M whose value is, or rides, an owned register dying at
the keep, 0 move without a new row (the pass already moves each one it can), 2.45 M need a moving twin
for a row that has none, 20.36 M need a row that TAKES the element out of the dying box. The count
elision line stops here: the counts are near the floor local rules reach.
