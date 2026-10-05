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
   key, or its place among its unkeyed siblings (`realize/identity.av`).
   Siblings sharing a key are told apart by their turn. Event echo,
   per-instance state, retention and the event log all read it. The
   compiler's site fingerprint replaces "place" through the same seam.
3. **A primitive says what it projects to.** Primitives are a closed
   set the library owns; each member says what it is — `@attr(Label)`,
   `@children`, `@style(color)`, an event, or the spread `..Box` — and
   `@derive(View)` refuses a member that says nothing. Each word is
   checked against the library's own declaration (`Attribute`,
   `EventKind`'s words, `Style`), so no second table exists. A user
   component is a COMPOSITION and invents no projection. No meaning is
   read from a field's spelling.
4. **An event is a declared member.** `on input(typed: string)` in the
   component, `on input { typed -> … }` at the instance. The member is
   named by the event's own word; `on_x` is never written or shown. A
   handler hears all its event says, or none of it. An event a
   component does not declare is refused by name, with the events
   there are (`type.component_event`).
5. **One vocabulary for what a control says**: nothing, text, a flag, a
   number (a point and a key later). `Said` is the value and `Handler`
   the listener, arm for arm. Closed: every target answers every arm,
   and the frame tells the host which one each event says.
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

## Decided (owner, 2026-10-05)

- THE NEUTRAL WORD IS `press`, never `click`: a mouse word names one
  platform. `on press { … }`.
- A URL IN THE TREE IS CHECKED: `href` and `src` carry `Url`
  (`realize/url.av`), a type with NO unsafe value — a reference that
  names no scheme, or one of `Scheme`'s. `url(text)` reads foreign text
  strictly and answers absence; `local("/docs")` and `https("x.dev")`
  write one. No target checks a URL. (`@std/url` is not used: it models
  an ABSOLUTE URL parsed by RFC 3986, and a link's usual target is a
  relative reference it refuses.)

## Open

- The object cache across targets: PR #272, `avra-8sb5.67`.
