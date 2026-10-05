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
   listen, unlisten, style. Of the elements a parent keeps, the longest
   run still in order stands still and only the rest are placed, so a
   reorder says the fewest moves. A host holds no reconciler and no table of
   the library's facts: the event's own word, what it says, the
   property to read and whether to stop it ride the `listen` patch.
   A property is held on the page as text or a flag — a number control's
   value is the text that spells it — so what was drawn and what was
   heard compare in one currency.
   A first paint is a diff against nothing; an unchanged page is no
   patch (the diff is a fold with no state of its own between paints:
   old page and new in, patches and the numbered page out); a property is compared against what the PAGE holds, so a
   field a user typed into is never written back to.
2. **One identity.** A node is WHERE IT STANDS: its parent, then its
   key or the SITE it was written at (`tree/identity.av`) — the
   literal that made it, one number a written literal, filled by the
   compiler into a field typed `@std/meta`'s `Site`. A sibling that
   comes and goes above a node moves nothing: not its element, not its
   state. Siblings one site made (a loop's, a helper's called twice)
   and siblings sharing a key are told apart by their turn, which is
   order — what must keep its own through a reorder wears a key. A
   root has no sibling, so where it was written says nothing: a page
   turned into another view keeps its root. Identity is never written
   out whole. A page gives a node's element a NUMBER when it first
   appears and the element wears it while it stays — matched, paint to
   paint, by its step among its siblings. The number is fixed in width
   however deep the node sits and counted out, never hashed, so two
   elements cannot share one. Event echo, retention and the event log
   read the number; instance state is kept by the walk that MAKES the
   tree, on the same steps, before any page numbers it. A reader's
   path is spelled only by the debug projection, which shows a site as
   the place it stands at.
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
   the host's copy (`runtime/dom/wire.gen.js`) is written from them —
   with the names a program answers to — and `make ui-host` fails when
   it is stale. `make ui-board` builds the board as a wasm reactor and
   runs it over the real page glue, each claim checked: the one run
   that holds `mount`, the entry and those names to a real module. Event kinds need no host copy:
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
9. **A second target fires events.** A terminal app is `mount(view)`
   too (`terminal/terminal.av`): the tree drawn as lines in a width,
   ONE control holding the focus, and the keys going to it through the
   same door — Tab and Shift-Tab move the focus among the controls that
   can speak, Enter presses or changes over, a typed character fills a
   field after what it holds, Ctrl-D ends. The controls on a screen, in
   reading order, are one definition the headless screen and the
   terminal share (`tree/controls.av`); the focus is kept by the path
   a control stands at, so it follows a keyed row. A field shows what
   the view says it holds. Input is read as octets, as they arrive on
   the standard input: an octet that is no character is dropped alone,
   and a character or escape sequence a read cuts is finished by the
   next. A TERMINAL LEFT IN ITS USUAL MODE SENDS WHOLE LINES, AND A
   LINE'S END IS ENTER: so there the focus cannot move without acting
   on the control it lands on, and text cannot be typed into a field
   without Enter following it. Keys one at a time need the terminal's
   raw mode, a row the runtime does not have (avra-8sb5.11.279). The board (`tools/ui-board`) is one view
   with two entries: `web/` mounts it on a page, `term/` in a terminal.
10. **One library.** One `View`, one `Node`. The `Role`/`Setting`
    model is deleted with the packages that drew it (`@std/ui_html`,
    `@std/ui_tui`); `@std/ui_http` answers a `Document` from a route as
    the page `realize/html` draws, and `@std/ui_gallery` and the site
    stand on the one model. The tokens a look names (`Size`, `Tone`,
    `Font`) are `style/tokens.av`'s; a value that shows itself where it
    is listed is `tree/shows.av`'s `Shows`. The old node's `spoken`
    is `tree/outline.av`'s `outline`.

## Instance state (seam 2's tenant)

A user component is a COMPOSITION: `fn view()` answers what it is made
of, and its `state` members are places each INSTANCE owns.

    // parts/counter.av
    @derive(View)
    export component counter(label: string) {
        ..Stand
        state n: int = 0

        fn view() -> row {
            row {
                text "${self.label}: ${self.n}"
                button "+" { on press { self.n = self.n + 1 } }
            }
        }
    }

    // parts/task_row.av
    @derive(View)
    export component task_row(todo: Todo) {
        ..Stand
        state open: bool = false

        fn view() -> item {
            item {
                button self.todo.title { on press { self.open = !self.open } }
                text "${if self.open { "open" } else { "shut" }}"
            }
        }
    }

    // the app
    fn page() -> column {
        column {
            counter "left"
            counter "right" { n: 10 }
            list visible() by it.id { t -> task_row t }
        }
    }

### Laws

1. **`describe` is the walk, and the walk says where it stands.**
   `View.describe(at: Standing) -> Node`. A container hands each child
   the standing under its own, at the child's step — `tree/identity.av`'s
   `steps` over what each child says of where it stands, the tree's one
   identity, computed
   where the tree is MADE. Every target has it and none owns it. A
   composition's view stands at a step of its own (`+view`), so a view
   that is itself a composition never shares a standing.
2. **The instance that stands is the first one built there.** An
   instance is a value, built fresh each paint. The walk keeps the
   first one at a standing; a later one hands it its PROPS (a copy
   shares its `state` cells) and `view()` runs on that. A handler is a
   closure over `self`, so it holds the kept cells.
3. **A seed is read once.** A state member's value at the instance
   (`n: 10`, or its default) seeds the place when the instance first
   stands; while it stands, later values are not read. A new key is a
   new instance.
4. **A paint offers what stood, once.** Each standing a paint reaches
   is opened: the instance and the standings that stood there are
   offered to this paint, and what it does not take is gone. So an
   instance lives exactly while a paint reaches it — no list of the
   living, no sweep. A keyed row keeps its standing through a reorder;
   a row a filter hides has LEFT, and its instance state leaves too.
5. **State that must outlive a hide is the MODEL's**: a `state` field
   of the model's own record, or module state. It lives as long as the
   row does and no paint frees it.
6. **A standing is never handed to another component.** One kept by
   a component and reached by another is not read: state can be lost
   to a moved place, never read by a stranger.
7. **The app owns what stands.** A kept instance is held by its
   standing, behind a fn, under the app's root: two screens over one
   view share nothing, and a dropped screen takes its instances with
   it. A component's `once fn <name>_kept()` is only the typed SEAT an
   instance is handed across; it holds nothing between two calls.
   `App.held()` counts what stands.
8. **A write during the walk is a write.** It lands, the rest of that
   paint reads it, and no paint follows from it — only the loop's door
   paints. A place is a `Cell`: nothing stands between a writer and
   it, so nothing can speak. Pinned (`tests/instance_life`).
9. **An unkeyed instance stands at its site.** Two instances of one
   component written at two places never trade state, whatever comes
   and goes between them. Instances ONE site made, with no key, are
   told apart by order: the walk cannot refuse a tree it is handed, so
   it SAYS so, once a component a paint — `App.warnings()`, a
   terminal's error stream:
   "`counter` keeps state, and here its instances are told apart by
   their order alone — they share a key, or one site made them and
   none wears one: give each its own `key`".
10. **`tree_of(view)` is a tree standing alone** — no paint before it,
   none after — for a document, a gallery, a test of one node.

### The language

- `component C { state n: T = v }`: a field, as a record's is.
- A WRITE THROUGH A `state` FIELD ASKS NOTHING OF ITS ROOT. The cell
  takes it, so `self.n = …` in a handler and `c.n = …` on a parameter
  run; `self.plain = …` keeps `resolve.immutable`'s words. The root's
  verdict is spoken at typing, where the field is known. Such a write
  marks no receiver written.
- `@std/meta`: `Field.state`, and `Type.fns` — the fns a component
  wrote in its own body.
- `@std/meta`'s `Site`: A FIELD'S TYPE IS ITS MEANING. A record literal
  that leaves a `Site` field unset holds its own site — its file and
  its own content, folded — so it owes no default. One constant a
  literal; content-addressed, so a line added above it moves nothing,
  and two literals written alike in one file share one.

### Refused (`@std/ui:<kind>`)

- `prim`: "a view is a primitive or is made of views, and `x` says
  neither"
- `stateful-primitive`: "a primitive draws what it is told, and `n` is
  a place it would keep"
- `boxed-composition`: "a composition wears its view's box, and `x`
  spreads one of its own"
- `stand`: "a view is told from its siblings by where it stands, and
  `x` does not say" — a composition spreads `..Stand`
- `marked-composition`: "a composition projects nothing of its own,
  and `title` is marked `@attr`"

### Rejected

- a cell bound when the node is placed: the view READS state while it
  is built, before any place exists.
- state on the page's node number: only a page numbers, and it
  numbers after `describe`.
- the hand-keyed store (`ui-instance`): a second identity, spelled by
  the author.
- call-order slots behind an ambient cursor: a hidden global, and an
  identity by ORDER of calls.
- a process-wide table per component: a dropped screen's rows are
  never reclaimed.
- the kept instance as a `dyn` in the trie, read back by a checked
  downcast: the language has none.

### Not foreclosed

A standing is a path of steps, the same in every process, so a dev
reload can carry `path -> state fields` across where the fields
encode; a `Cell`'s address could not.

## Where it lives

`tree/` is the neutral tree and what is read off it whatever draws it
(`Node`, `View`, identity, the URL, the controls on a screen, the
readable outline); `realize/` is the targets, one directory each
(`html`, `dom`, `tui`, and the draw-only `canvas`); `app/` is the loop;
`web/`, `terminal/` and `headless/` are where an app is mounted.

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
  (`tree/url.av`), a type with NO unsafe value — a reference inside
  the site, or one of `Scheme`'s. `url(text)` reads foreign text
  strictly and answers absence: a scheme (read from the first path
  segment alone) that is not ours, a network path (`//host`, with
  slashes or backslashes), any control character. `local("/docs")` and
  `https("x.dev")` write one, and the writer makes a value built by
  hand safe too — behind `./`, behind `/.`, a control character as its
  percent escape. No target checks a URL. (`@std/url` is not used: it models
  an ABSOLUTE URL parsed by RFC 3986, and a link's usual target is a
  relative reference it refuses.)

## Open

- The object cache across targets: PR #272, `avra-8sb5.67`.
