# ctx step 3, part b: the walk ("placed, not written"), a ruling ask

## The fact
std-ui's generated composition does this:

    fn made() -> List<dyn View> { let made = gathered { <body> }; made.items }
    fn describe(at) { made_of(at, me.made(), self.key) }

The body's `ctx theme = …` is a statement inside `gathered { … }`, so it ends when that block ends.
That is before `made_of` → `each_described` → `v.describe(...)` draws any child. With step 3a alone, a
child therefore never sees its parent's set.

F1's own example settles what "placed" means. In `form_box { button "Save" { on press {
ctx.form.submit() } } }`, the button is BUILT by the caller (before form_box sets `form`) but PLACED by
form_box's body, as `self.body`, after the set. So the frame a child is drawn under is the one in force
at the statement of the parent's body that yields it into `gathered`: not where it was built, and not
where the walk later calls it. Sets can sit between placements (`text "a"; ctx theme = dark; text
"b"`), so it is per item.

## Options
**A (recommended): `gathered` records each item's frame, and the walk enters it.**
- In a program that frames anything, a `gathered` block whose items are `dyn View`s (more generally,
  any `@placed` trait: View is marked) pushes, beside each item, the frame in force at its statement,
  into a hidden `frames` lane of the gathered record. One `avra_ctx_frame()` per placed item; nothing
  in a program with no context, so the zero-diff receipt still holds.
- std-ui's generated `describe` hands `made_of` the frames with the items. `each_described` draws item
  j under frame j through an `@std/meta` door, `placed_under(frame, () -> v.describe(...))`. It is
  lowered as the inline check plus avra_ctx_enter / back, the same IR as a framed lambda's entry, so no
  new row.
- `Frame` is an opaque `@std/meta` type, a managed pointer.
- Step 2's survey: a View item's reads are owed at its placement statement (like a lambda at its
  making), not at the walk's dyn call. That replaces rule (i)'s union for `@placed` traits only;
  `dyn Sink`, `dyn Measure` and the rest keep (i) and the caller's frame.
- **F1** follows: a handler made by the caller runs under the frame its node was drawn under. The walk
  is inside `placed_under` when the primitive's `describe` builds the Node, and the derive reframes
  each handler field that reads a context with `avra_ctx_reframed(box, frame)` (R2's row), only where
  it differs.
- **F2:** the standing keeps the frame its instance was last placed under (`Standing.frame`). A lone
  repaint enters it; an ancestor's paint refreshes it.
- **F3:** a set's value is evaluated under the paint's read tracking, so the cells it reads through
  calls become structural reads of the composition holding the set. That part is std-ui-only.

**B: no `gathered` change; std-ui wraps each item at placement into a framed lambda.** The derive
rewrites the body's bare statements `x` to `place(x)`, where `place` makes `(at) -> x.describe(at)` at
the statement. The lambda captures the frame by 3a's rule, so no new door is needed. But it rewrites
the user's body text, costs a closure per placed item in every program (no zero-cost path, because a
library unit can't know whether the program has contexts), and breaks a body that uses an item's
value.

## Asks
1. A, with `@placed` on View, and the survey owing a placed item's reads at its placement?
2. Is `placed_under` / `Frame` in `@std/meta` acceptable as the door? Its IR is 3a's entry, so there's
   no new row and no new Ins.
