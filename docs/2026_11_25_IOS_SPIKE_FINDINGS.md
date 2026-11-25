# iOS spike: findings to date (slices 1, 2a, 2b), 2026-11-25

Commits on `ios-spike`: 486c7f3 (slice 1 runs), 539871b (real state), 72c0c3a (board mounts), cfacd12 (vocabulary),
d7f5782 (server), 891f6b9 (roles as data). Compiler: build/avra, the gap-2 one (seed 9589557f58).

## What runs
- Counter round trip 0 → 3 through accessibility; witness "all held".
- Modes: a ticking task ticks 10/10 in a held scroll, 9 under an alert. Sync: an in-call handler answers 42; one
  that waits is refused in the runtime's words.
- Budget: idle 339 display frames, longest gap 222 ms; with a spinning task 7 frames, longest gap 408 ms.
- Binary 674 KB; first frame 288–766 ms after process start (simulator).
- The board's own `view`, unedited: 190 records in its first frame (52 create, 52 place, 50 attr, 20 text,
  12 listen, 1 style, 1 prop). Controls: UILabel, UIButton, UITextField, UISwitch, UIProgressView, hairline, sheet.
- The board reads the owner's server over @std/http at a base the launch names; a POST from the app lands (201).
- Tones and inks map to UIKit semantic colours; light and dark follow the device.

## What is wrong on screen
- Placement is UIStackView: the filter row overflows ("Newest first" is "…"); a task row stacks vertically.
- "Done" and "New task" show twice (a label's text run and its control's own label).
- "Clear done" wears the chosen tab's fill: both are only class fills. No `on-<tone>` ink applied.

## Compiler defects
- D1 (avra-8sb5.114.10): `run(() -> {})` ICEs for the iOS target only: `{}` lowers as an empty map.
- D2 (avra-8sb5.109.15): `owned_app` over a stateful component at an entry's top level is refused; the same
  inside a generic fn in another module builds.

## std-ui changes wanted (none made)
1. Keep the Prim on `Tagged`, or diff `Node` before lowering. The host guesses prims from tags and class strings.
2. Layout, tone and "chosen" as data, not class words. A tab's chosen state exists only as a fill.
3. The theme mode as data in the frame: the board's "Dark mode" press changes only the CSS sheet
   (`style 4517 ; attr 8 aria-label Light mode ; text 9 Light mode`).
4. The device's appearance change reaches the program: today no frame, the program never learns.
5. A base address for a native target: a parameter on `opened(on, net)` (native/sources.av) or `over_http`
   (native/net.av). `Request.url` is a bare path on the web.
6. Start-of-app work reachable from every entry: the board's `load()` is private and only its web main calls it,
   so a native app has no observation to refresh after a write (the list did not redraw after Add).
7. A native stream for `Want.Listen`: native/sources.av answers `unheard`, so there is no live feed.
8. Apple runtime: `avra_cores.c` is left out but sqlite's C needs `avra_fork_hook`; a no-op is stubbed in the host.
9. `avra build` has no output path: it writes `<entry>.iphonesimulator` beside the entry.

## Placement by our solver: why it stopped
- `place(root, m, width)` (place/solve.av) answers a `Placed` tree of rects over the NODE tree, in sixtieths.
- A UIKit `Measure` answers `own(n, avail)` by `sizeThatFits`, `min_own`, `kept` (zero), `hidden`, `holds`, and
  the gap and pad steps; called synchronously inside a turn (the sync witness proves that path).
- The host's views are keyed by the ELEMENT ids `live` mints AFTER lowering Node to Element, and lowering adds and
  changes nodes (a text run becomes its own element; a field's label becomes a label element plus the control).
  Nothing maps a `Placed` box to an element id. So rects cannot be attached to views without (1) above.
- `Measure.own` is handed a bare Node the host has never seen: it needs the prim, words and attributes, or the id.

## DOM-shaped pieces of std-ui
realize/html/element.av (365 lines; the Prim is lost at tags.av:123 `tag_for`), realize/dom/patch.av (486),
realize/dom/live.av (400; lowers Node to Element + CSS before it diffs), realize/dom/wire.av (447).
