# UI emit probe — where a paint actually spends its work

> 2026-10-04. Before a consumer is built for `lowering_plan`
> (`features/read_set.av`), four probes, run against the current
> compiler. The result redirects the epic and fixes a defect it would
> otherwise have shipped.

## P3 — the frame, not construction, is the cost of a paint

`tools/bench/uibench` builds a 40-leaf `Node` tree and times the
paint's stages natively (200 runs, 82 ops, a 1331-byte frame):

| stage | ns/run |
|---|---|
| `construct` (`branch(40)`) | 19,900 |
| `plan(node)` (walk the tree into ops) | 10,600 |
| `frame(node)` (`plan` + serialize every op) | 48,900 |
| `Live.diff` (frame + byte compare, unchanged) | 50,600 |

The component layer makes construction heavier — a 40-row
`view().describe()` measured ~62µs in a scratch probe against a
~251µs frame — but does not change the conclusion. `frame` dominates,
by 2.5x over bare `Node` construction and by 4.6x over the walk alone:
the **serialize** is the cost.

What `Live.diff` does today with an unchanged subtree: `frame(root)`
walks the WHOLE tree, serializes every op into a fresh `Bytes`, then
compares that to the last frame and returns `no_change` — two bytes.
`no_change` is a whole-frame equality, never a per-subtree skip. So
`Hoist`'s value is not only "build once": it is also **never
re-planning or re-serializing a subtree that cannot have changed**, and
that is the larger half.

## P1 — a Hoist op stream is constant, but the plan called OPEN sites Hoist

`frame(branch(40))` twice is byte-identical (1331 bytes), so a
state-free, input-free subtree is genuinely constant.

But `fn f(x: int) -> int { x + 1 }` read no state and held no call —
and the plan said **Hoist**. Its value differs on every call. The plan
proved "reads no state", not "constant"; `hoistable_of`/`site_lowering_of`
let parameters, receivers, and outer locals through. The `Direct` leaf
had the identical hole (`fn f(x: int) -> int { state n: int = 0; n + x }`
was `Direct(n)`, a targeted write that would miss `x`). A consumer that
took `Hoist` at its word would have frozen any parameterized view or
screen (`screen board(id: TaskId)`) to its first call's arguments.

Fixed in `read_set.av`: a site must be **closed** (`closed_of` — no
parameter, receiver, or binding from outside the site; a `state` place
is the read set's, not this check's) before it earns `Hoist` or
`Direct`. Four spec cases pin it; the package's 7760 cases pass.

## P2 — construction cannot be intercepted today (the crux)

A component instance lowers to its fields array, then to a `dyn View`
box `[fields, describe_fn, type_tag]`. From `avra ir` of `heading
"Tasks" { rank: 1 }`:

    r7  = avra_array_sized(6)         // fields
    r8  = avra_array_new()
    call avra_array_push_moved(r8, r7)
    r9  = addr @std.ui.components.heading.describe
    call avra_array_push(r8, r9)      // the vtable's one method
    r10 = int 490752735               // the dyn TYPE tag
    call avra_array_push(r8, r10)

The `.describe()` that turns a component into a `Node` is a `dyn`
dispatch whose subject comes from `List<dyn View>` — type-erased at
the `items` boundary (`realize/view.av` generates `[v.describe() for v
in self.items]`). The compiler's `lowering_plan` is over the VIEW
expression sites, and `site_lowering_of` never sees the `describe()`
consumer. There is no seam at which the compiler can replace a
component construction with a prebuilt `Node` without **owning view
construction** — devirtualizing `List<dyn View>` and its `describe`
chain. Shape (a) as literally stated is not available today. That is
the epic's deepest tension, named.

## P4 — a construction site carries a per-TYPE tag, not a per-site id

The only constant at a construction site is the `dyn` type tag
(490752735 for `heading`, 210102596 for `text`) — identical for two
`heading`s at different source sites. `Action.site` carries a
content-addressed site for EVENTS only. A per-site identity on the
node the frame walks does not exist; it would be new.

## What follows

The measurement redirects the first slice: the win is not only
avoiding construction, it is avoiding the whole-tree plan+serialize on
every paint. That needs the frame layer to skip an unchanged subtree,
which needs a per-site identity on the `Node` (or the component value).
P4 says it is new; P2 says the compiler cannot inject it without owning
view construction. The least-risky first move is to stamp the
content-addressed site the plan ALREADY computes
(`SitePlan.site = expr_fingerprint`) onto the component value at
construction, carry it to the `Node`, and cache the subtree's op
stream/bytes by site in `frame.av` — with the P1 fix making `Hoist`
trustworthy for that consumer.
