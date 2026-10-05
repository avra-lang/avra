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

1. **Diff lives in Avra.** A node lowers to its target's elements
   (`realize/html/element.av` — the one place that knows a control sits
   under its label); two element trees are matched by id
   (`realize/dom/patch.av`) and a host applies the patches: create,
   create text, place (after a sibling — one op inserts and moves),
   remove, set attribute, drop attribute, set property, set text,
   listen, unlisten, style. A host holds no reconciler and no table of
   the library's facts: the event's own word, what it says, the
   property to read and whether to stop it ride the `listen` patch.
   A first paint is a diff against nothing; an unchanged page is no
   patch (the diff is a fold with no state of its own between paints:
   old page and new in, patches and the numbered page out); a property is compared against what the PAGE holds, so a
   field a user typed into is never written back to.
2. **One identity.** A node is WHERE IT STANDS: its parent, then its
   key or its place among its unkeyed siblings (`realize/identity.av`);
   siblings sharing a key are told apart by their turn. Identity is
   never written out whole. A page gives a node's element a NUMBER when
   it first appears and the element wears it while it stays — matched,
   paint to paint, by its step among its siblings. The number is fixed
   in width however deep the node sits and counted out, never hashed,
   so two elements cannot share one. Event echo, per-instance state,
   retention and the event log read the number; a reader's path is
   spelled only by the debug projection. The compiler's site
   fingerprint replaces "place" as a step.
3. **A primitive says what it projects to.** Primitives are a closed
   set the library owns; each member says what it is — `@attr(.Label)`,
   `@children`, `@style(color)`, an event, or the spread `..Box` — and
   `@derive(View)` refuses a member that says nothing. Each word AND
   its type is checked against the library's own declaration (`Prim`,
   `Attribute`, `EventKind`'s words, `Style`), read by `type_exported`,
   so no second table exists; what two members say twice is refused. A user
   component is a COMPOSITION and invents no projection. No meaning is
   read from a field's spelling.
4. **An event is a declared member.** `on input(typed: string)` in the
   component, `on input { typed -> … }` at the instance, `on input:
   handler` to hand on a handler that is already a value. The member
   is named by the event's own word; `on_x` is never written or shown.
   A handler hears all its event says, or none of it. An event a
   component does not declare, one heard twice, and a handler naming
   some of its seats are each refused by name
   (`type.component_event`).
5. **One vocabulary for what a control says**: nothing, text, a flag, a
   number (a point and a key later). `Said` is the value and `Handler`
   the listener, arm for arm. Closed: every target answers every arm,
   and the frame tells the host which one each event says.
6. **One table per fact.** Patch ops and what a control says carry
   their wire numbers as `@code` on the variant (`realize/dom/wire.av`);
   the host's copy (`runtime/dom/wire.gen.js`) is written from them and
   `make ui-host` fails when it is stale. Event kinds need no host copy:
   the host echoes a kind it never reads.
7. **`mount(view)` is the app.** No app writes the host seam: the
   page's exports and its one import are the web module's own
   (`web/web.av`), and the program's statements are its start. THE LOOP
   IS ONE DOOR (`App.turn`, `app/app.av`): whatever may change the
   state runs through it — a control speaking, later a timer or an
   answer arriving — and a paint follows only when it ran. A target is
   what the door paints on: a page sent patches, a screen held in
   memory. Text a control says crosses in a seat the program hands out
   for exactly its octets, so no text has a longest length.
8. **A test names no platform.** The headless target
   (`headless/headless.av`) is the tree itself, held in memory, and its
   verbs speak to a control BY ITS WORDS — `press`, `fill`, `check`,
   `slide`, `submit` — through the same door; `text()` is the screen as
   a reader finds it. What a reader could not reach does not speak: a
   disabled control, a control in a dialog that is not open.
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
