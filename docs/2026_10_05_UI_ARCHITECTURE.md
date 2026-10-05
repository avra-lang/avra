# UI architecture — the seams

> 2026-10-05. Base `60c5030` (branch `ui-arch`). The law for `@std/ui`. Epic `avra-8sb5.59.43`.
> Supersedes the "Events: generated `Msg`" section of
> `2026_10_02_COMPILED_UI.md`; the rest of that doc stands.

## The decision this reverses

`COMPILED_UI` rejected a fn in the tree ("the tree stops being data").
Five attempts to lift a handler into a generated message failed.

- A HANDLER IS A CLOSURE. That is the reference semantics.
- AN EVENT IS DATA: `(node id, kind, what it said)`. It can be logged
  and replayed against a tree. That needs stable IDENTITY, not a
  generated message type.
- Lifting a handler into `(site, captures)` stays open as a compiler
  LOWERING, indistinguishable from the reference.

## The layers

    state  ->  view  ->  lower  ->  diff  ->  host
                 ^                           |
                 +-------- runtime <---------+

| layer | is | owns |
|---|---|---|
| state | places the app owns | `state`, keyed stores |
| view | components -> the neutral tree | what a node IS, says, looks like, hears |
| lower | neutral node -> one target's elements | tags, attributes vs properties, control structure |
| diff | old elements vs new -> patches | reconciliation, ONCE, in Avra |
| host | applies patches, reports events | nothing else |
| runtime | the loop | event -> handler -> repaint -> patches; async and timers |

## The seams, and their laws

1. **Diff lives in Avra.** A host applies patches (create, remove, move,
   set attribute, set property, set text, listen, unlisten). A host
   holds no reconciler and no table of the library's facts.
2. **One identity.** A node's id derives from its parent's id and its
   key, or its position when unkeyed. Event echo, per-instance state,
   retention and the event log all read it. The compiler's site
   fingerprint replaces "position" through the same seam.
3. **A primitive says what it projects to.** Primitives are a closed
   set the library owns; each names its attributes, children and style
   explicitly. A user component is a COMPOSITION and invents no
   projection. No meaning is read from a field's spelling.
4. **An event is a declared member.** `on input(text: string)` in the
   component, `on input { text -> … }` at the instance. `on_x` is never
   written or shown. An event a component does not declare is refused
   by name.
5. **One vocabulary for what a control says** (text, flag, number; a
   point and a key later). Closed: every target answers every arm.
6. **One table per fact.** Event kinds, patch ops and their codes are
   declared once; each host's copy is generated.
7. **`mount(view)` is the app.** No app writes the host seam.
8. **A test names no platform.** A headless target and a driver
   (`press`, `type`, `text`) are the library's.
9. **A second target fires events.** The terminal proves the seams.
10. **One library.** The `Role`/`Setting` model and its packages move
    to this one. URL sanitising (`safe_url`) comes across.

## Kept

State as places · the neutral tree as the contract · style as tokens ·
one exhaustive match per target over the primitives.

## Build order

1. identity (2)
2. declared events, explicit primitives (3, 4, 5)
3. diff + patch wire + generated host (1, 6)
4. `mount` + the test driver (7, 8)
5. terminal events (9)
6. the old library deleted, its packages ported (10)

## Open

- `click` is a mouse word; `press` is the neutral one. `click` stands
  until decided.
- The object cache is not keyed by target (a wasm link is handed native
  objects). Separate from this work.
