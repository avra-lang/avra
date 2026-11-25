# ctx step 3 — capture: the mechanism, for a ruling before it's built

The design (H2, F1–F3) says what is captured. This note is how, because it changes every closure's box
and costs something on every closure call.

## The frame rides in the closure box, at slot 1
- A box is today `[code, lanes…]`; it becomes `[code, frame, lanes…]`. The frame is managed (the box
  holds a reference), and it is NULL where nothing is set. The slot can't trail the lanes: a body
  learns its lanes as it lowers, and its entry needs the frame's slot first.
- A lambda with no captures is today a static box (`[code]`, no allocation). It stays static while no
  frame is set. Where one is set at its making, a new row `avra_fn_framed(static)` makes
  `[code, frame]`. A program that never sets a context pays nothing at a making.
- A lifted body's entry reads slot 1 when the box is longer than one slot. It calls a new row
  `avra_ctx_enter(frame) -> int`:
  - when the frame is already current (the common case: both NULL, or the same frame), it changes
    nothing and answers 0;
  - otherwise it pushes a frame holding the made frame's pairs over the caller's (prev = the caller's
    frame) and answers 1, so the step-1 back restores the caller's frame by every way out.
  - The body's scope ends with `back` only where the answer was 1.
- **Cost per closure call, no contexts:** one length test, one load, one call that compares and
  returns 0, and one branch at the end. With contexts and a different frame: one frame of 1 + 2k words.
- A named fn taken as a value (H2: the reference is a making) gets the same treatment through its
  wrapper box. A `dyn` box's methods are not makings and capture nothing (they run under the caller's
  frame, as ruled).
- A task its block owns: the spawn's box captures the frame, so the task starts under it (inherits).
  A detached task and a call from C start empty: their box is made with no frame.
- Rows: `avra_ctx_frame()` (the current frame, retained), `avra_ctx_enter(frame) -> int`, and
  `avra_fn_framed(box) -> box`. These go up the ladder as R2 (rows, C bodies, C tests, `Rung:`), then
  S2.

## UI (F1–F3), on top of that
- **F1:** a handler filling a node's event runs under the frame the node was drawn under, not where
  the closure was made. When the walk places a node, it re-frames its handlers with a fourth row,
  `avra_fn_reframed(box, frame) -> box`: a copy of the box with slot 1 replaced, and the same box when
  the frame is already the one it holds.
- **F2:** the standing keeps the frame its instance was drawn under. A child's lone repaint enters it
  around the body, and a full paint of an ancestor refreshes it.
- **F3:** a set's value is evaluated under the paint's read tracking, so the cells it reads through
  any call are structural reads of the composition holding the set. A set outside any composition
  that reads a `state` warns.
- **The walk sets as it enters:** an instance value records the frame current where it is made
  (placed, not written). The walk enters that frame around the body it draws.

## Asks
1. Is the slot-1 frame in every dynamic closure box acceptable? It's one word per box, plus the
   call-entry test above.
2. Is F1's re-framing at placement acceptable (a copy of a handler's box per placement only where the
   frame differs)? The alternative, marking handler closures at making so they never capture, is
   smaller but leaves a handler made outside the walk with no frame of its own.
