# UI targets and the live wire

> 2026-10-02. Records the layering that makes the UI neutral, how the
> live target's wire works, and its KNOWN cost. The DOM target is the
> first projection of a neutral model, not the model.

## What is HTML-only (the thin part)

- the tag names (`span`/`div`/`h1`) and the writer that spells them;
- classes and the atomic stylesheet (`realize/dom/frame.av`'s `sheet`),
  CSS variables — **there is no CSS on Apple**;
- the JS bootstrap and the op *text* encoding — both exist only because
  the browser has no differ.

## What is target-neutral (the substance)

- the vocabulary: `Prim`, `Attribute`, `Box`, `Style`, `Layout`, `Theme`, `Name`;
- the eager, keyed `Node` tree;
- the reconciliation semantics: keyed identity, order, insert/move/remove,
  attribute/text set;
- themes and tokens, interaction states, accessible names.

## The one update graph, many emitters

`realize/update.av` is the ONE update graph. The `Sink` walk owns each
node's identity (id, parent, index) and collects a stream of NEUTRAL ops:
`Mount(prim, attrs, box)`, `Words`, `Event`. No target's currency is in
it — a TAG, a CLASS, a BYTE op and a drawn LINE are an emitter's.

- `realize/dom/frame.av` SERIALIZES the graph: `frame`, `frame_text` and
  `sheet` all read `plan(root)`. The DOM names its own tag, class and
  byte op; the graph never does.
- `realize/canvas/canvas.av` is the second emitter over the SAME graph:
  a flow layout in whole theme steps, so the ops become draw calls
  (`Fill`/`Text`/`Rule`/`Block`) with coordinates.
- `realize/html` and `realize/tui` stream the same walk to a string.

"Across all platforms" is one graph with different backends, never a
lowest common denominator: the canvas has no tags, the DOM has no
geometry, and both read the same ops.

## Native projection (Swift / iOS / macOS)

| neutral | SwiftUI / UIKit |
|---|---|
| `Prim.Column` / `.Row` / `.Surface` | `VStack` / `HStack` / container + background |
| `.Text` / `.Heading` | `Text` + `.font(.headline/.title…)` |
| `.Button` / `.Link` | `Button` / `Link` (or `NavigationLink`) |
| `.List` / `.Item` | `List` + `ForEach` |
| `.Switch` / `.Checkbox` | `Toggle` |
| `.Field` / `.Slider` / `.Progress` | `TextField` / `Slider` / `ProgressView` |
| `.Dialog` / overlay | `.sheet` / `.alert` |
| `Box.style` (tone/fill/radius/face) | `.foregroundStyle` / `.background` / `clipShape` / `.font` |
| `Box.layout` (axis/gap/pad/align/distribute) | `spacing`, `.padding`, `alignment`, `Spacer()` |
| `Style.states` (hover/focus/pressed) | `ButtonStyle`, `.hoverEffect`, `@FocusState` |
| `Theme` tokens | a Swift struct + `Color`/`Font`; contrast → `\.colorSchemeContrast` |
| `Attribute.Label/Name/Text`, `Urgency` | `.accessibilityLabel`, `AccessibilityNotification` |
| `Node.key` | structural identity — `ForEach(id:)` wants exactly this |

### The design choice for native

1. SHIP OPS — a Swift applier analogous to the JS bootstrap. Works, but
   re-implements diffing.
2. SHIP THE TREE — a Swift `Node` model plus a `NodeView` mapping `Prim`
   → views, and let **SwiftUI diff it** (the platform IS the differ).

**Take (2) on Apple and Android.** The op stream exists for targets with
NO differ (DOM, canvas, print); a target with one consumes the `Node`
value and diffs natively. Both consume one `Node`, one vocabulary, one
theme. Web pay: HTML; Apple pay: SwiftUI emission + a small runtime.

## The live wire (DOM) and its cost

`avra_dom_frame(ptr, len)` — ONE host call per render, a frame the
`bootstrap.js` reconciles by key. Cheap today: one call, O(nodes) Map
lookups, elements REUSED (identity survives).

KNOWN COST, in order:

1. THE TEXT ENCODING IS THE BRITTLE PART. Value escaping is mirrored on
   two sides (`esc` in Avra, `unesc` in JS) — a drift is silent, and this
   is the "a guard and the thing it guards must read the same bytes"
   hazard. JS `split`/`indexOf` per line also allocates per op.
2. AVRA STRINGS ARE IMMUTABLE, so building the frame concats: a
   `"C ${path} ${tag}"` per node is a small allocation per op. A 10k-node
   tree makes ~30k strings + lists per render.
3. FULL RE-RENDER BY CHOICE (M1): every change re-emits the whole tree.
4. THE EAGER TREE IS REBUILT per render — O(tree) program allocations,
   independent of the bridge.

### The fixes, in value order

1. **BINARY FRAME, not text.** Flat fixed-width records `[op, key, arg,
   value_ref]` in linear memory, with an interned string table. No
   escaping (kills the drift), no parsing, no per-op string allocation.
   The encoding changes behind the SAME row — vocabulary, tree, theme,
   keys and reconciler are untouched.
2. **STATIC NODES EMITTED ONCE.** Most of a UI never changes: emit a
   subtree as static, reference it by key, send only dynamic nodes. Turns
   a keystroke from O(tree) to O(changed). Needs the read set (M2).
3. **A REVISION / NO-CHANGE FRAME.** An unchanged render costs one int.
4. **A REUSABLE SCRATCH BUFFER.** Grow-once linear memory; no per-frame
   allocation.
5. **A PROTOCOL VERSION IN THE HEADER**, so a stale bootstrap REFUSES
   rather than silently misapplying.
6. **KEEP THE TEXT AS A DEBUG PROJECTION** (P7: inspectable) — one
   function that renders a frame as lines, used by tests and `explain`,
   never on the wire.
