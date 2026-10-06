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
| state | places the app owns | module `state`, a model's `state` fields, a component instance's |
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
   listen, unlisten, style, call. A `call` asks an element for a verb of
   its own, said last in its frame: a DOOR is state an attribute would
   enter another way — a dialog shown by `open` stands in the page's
   flow, `showModal` stands it over the page with the focus inside — so
   the attribute is never sent and its arriving and going are calls. Of the elements a parent keeps, the longest
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
   field a user typed into is never written back to — and a door too: a
   dialog the user sent away is closed by the page before the program
   hears, so it is not closed again, and is shown again if the program
   still says it is open. A property a
   paint does not name is at rest, whether the last paint or the user
   moved it. THE DIFF'S LAW IS RUN, NOT ARGUED: for trees grown and edited
   by chance from a seed, the frame that repaints one as the next is
   applied to a host modelled from the wire alone, and the page must be
   the one the next tree lowers to, each kept element still itself, a
   second paint silent and each handler the new tree's
   (`realize/dom/tests/support`; `make ui-fuzz` runs it at length, and
   `make ui-host-test` holds the page's own host to the model's page).
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
   component is a COMPOSITION and invents no projection: its BODY is
   the views it is made of, drawn in place under its own parent, with
   no `@derive` and no spread written (below). No meaning is
   read from a field's spelling.
4. **An event is a declared member.** `on input(typed: string)` in the
   component, `on input { typed -> … }` at the instance, `on input:
   handler` to hand on a handler that is already a value. The member
   is named by the event's own word; `on_x` is never written or shown.
   A handler hears all its event says, or none of it. An event a
   component does not declare, one heard twice, and a handler naming
   some of its seats are each refused by name
   (`type.component_event`). A dialog declares `on dismiss`: the key
   or the press outside that sends it away, heard by a page as the
   browser's own `cancel` and by a headless screen as `dismiss()`. A
   form's submit and a dialog's dismissal are heard on a page whether or
   not a handler is: the page's own answer to each would undo what the
   program drew.
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
   that holds `mount`, the entry and those names to a real module. `make
   ui-browser` serves that module over an HTTP origin and drives it in
   headless Firefox with the browser's own pointer and keys
   (`tools/ui-board/browser.mjs`): what only an engine can show — the
   sheet styling the page, a caret kept while typing, the keyboard's
   reach. Event kinds need no host copy:
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

## Compositions and instance state (seam 2's tenant)

A user component is a COMPOSITION: ITS BODY IS ITS VIEW. What it holds
beside its fields and its `fn`s is what it is made of, and its `state`
members are places each INSTANCE owns. The author writes no `@derive`,
no spread, no `fn view()`, no return type, and may use it in the file
that declares it.

    use @std.ui.components.{button, text}

    component counter(label: string) {
        state n: int = 0
        text "${self.label}: ${self.n}"
        button "+" { on press { self.n = self.n + 1 } }
    }

    component task_row(todo: Todo) {
        state open: bool = false
        item {
            button self.todo.title { on press { self.open = !self.open } }
            if self.open { text self.todo.notes }
        }
    }

    fn page() -> column {
        column {
            counter "left"
            counter "right" { n: 10 }
            for t in visible() {
                task_row t { key: t.id }
            }
        }
    }

### What a composition is

- **A body draws IN PLACE.** A composition has no node of its own: what
  its body makes — none, one or several nodes — stands under the
  composition's own parent (`View.describe` answers a list). A page
  holds no element for it.
- **Its standing is one step; its nodes are stepped through it.** The
  instance is kept at its own step under its parent (its key, else its
  site). Each node it draws carries that step in front of its own
  (`Stand.via`), so two instances' nodes are told apart beside each
  other: moving a keyed composition moves exactly its nodes.
- **Its key shows on the first node it draws.** A composition has no
  node to wear a key, so the first node its body makes wears it — a
  page's `data-key` — where that node wears none of its own.
- **A tree has one root.** A root that drew none or several nodes is
  held in a column — the one wrapper, and only there.
- **A primitive is the other kind**: `@prim`, marked members, no body,
  drawn by its target. A declaration with both is refused by name.

### Laws

1. **`describe` is the walk, and the walk says where it stands.**
   `View.describe(at: Standing) -> List<Node>`. A container hands each child
   the standing under its own, at the child's step — `tree/identity.av`'s
   `steps` over what each child says of where it stands, the tree's one
   identity, computed
   where the tree is MADE. Every target has it and none owns it. What
   a composition is made of stands under the composition's standing,
   so one made of a single composition never shares its standing.
2. **The instance that stands is the first one built there.** An
   instance is a value, built fresh each paint. The walk keeps the
   first one at a standing; a later one hands it its PROPS (a copy
   shares its `state` cells) and its body runs on that. A handler is a
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
   it. Beside each composition its derive mints one `once fn` — only
   the typed SEAT an instance is handed across; it holds nothing
   between two calls. Its name, and the name of the method a body
   becomes, are ones no program can write, so a component's own `fn`s
   and its file's take any name.
   `App.held()` counts what stands.
8. **A write during the walk is a write.** It lands, the rest of that
   paint reads it, and no paint follows from it — only the loop's door
   paints. A place is a `Cell`: nothing stands between a writer and
   it, so nothing can speak. Pinned (`tests/instance_life`).
9. **An unkeyed instance stands at its site.** Two instances of one
   component written at two places never trade state, whatever comes
   and goes between them — two literals written alike included: a site
   is the literal's file, its content and its turn among the literals
   like it in that file. Instances ONE site made (a loop, a
   comprehension, a fn called twice), with no key, are told apart by
   order, and so are two that share a key: the walk cannot refuse a
   tree it is handed, so it SAYS so — `App.warnings()` after each
   paint, and once an app on a target's error stream (a terminal's, a
   page's console):
   "`counter` keeps state, and here its instances are told apart by
   their order alone — they share a key, or one site made them and
   none wears one: give each its own `key`".
10. **`tree_of(view)` is a tree standing alone** — no paint before it,
   none after — for a document, a gallery, a test of one node.

### The language

- **A component's body.** A component declaration takes statements
  beside its fields and `fn`s — child instances, `if`/`for`/`match`, a
  `let`, a call whose answer is a view — never a declaration of its
  own. The compiler folds them into one quote; nothing walks a body
  where it is written.
- **`@composes(Carried)`** (`@std/meta`), worn by a trait: A COMPONENT
  WITH A BODY IS ONE OF THESE. It is derived over that trait exactly as
  a written `@derive` would derive it — the trait's `derive` receives
  the body as `Type.body` and splices it where it means something —
  and it CARRIES the record the mark names as if it spread it. So the
  compiler names no library: `@std/ui` writes `@composes(Stand) export
  trait View`, and `key:` and the site are fields of every composition
  with nothing written.
- **Which trait is found along what the file names**: the nearest
  files that declare a trait wearing `@composes`, walking outward from
  the component's file — the files its `use` lines' names are declared
  in and the files of its own module, then theirs. A body made of
  `text` reaches `@std/ui`'s `View` through `text`'s file; a body made
  only of other compositions reaches it through theirs, with no `use`
  of the library written. Only files a build already reads are read —
  never a package's tests. Two libraries each compose their own
  components; a body with none in reach is refused, and so is one
  whose nearest ring holds two.
- **A generated impl names its trait where the name was WRITTEN.**
  `impl View for counter` is the library's text: `View` is read in the
  library's file, whatever the component's file imports — nothing, or
  an unrelated `View` of its own. No import is bound into the user's
  file; what lands in it is the impl and the seat of law 7, under
  names no program can write.
- **A component is instanced where it is declared.** A module's own
  component word is reserved nowhere, so it opens an instance where
  the line says so: before a head value (`counter "a"`, `counter id`,
  `counter self.name`) anywhere, or before a name where a statement
  starts. Its word before a `{` stays the record's literal (`header
  {}`). The parse a module's words are read off knows them by name
  already, so an instance stands there as a hole and the declaration
  around it keeps its shape.
- **A statement that fails keeps the shape around it.** Recovery
  skips the block the failed statement opened, not only its line, so
  a declaration around it still closes where it was written.
- **An instance's head keeps its brace.** After a component's word, a
  name and then a brace is the head and the instance's block: `counter
  id { key: id }` is `counter` over `id`. A record literal as a head
  that a block follows stands in parentheses — `tally (Tally { … }) {
  … }` — and `fmt` keeps them; a head naming a record is refused in
  those words (`type.component_head`). Every other head (`if`,
  `while`, `for`, `match`, `if let`, `let … else`) takes a literal
  bare, as before. A module's OWN word before a parenthesis is a call,
  refused in words that say to bind the value first.
- `component C { state n: T = v }`: a field, as a record's is.
- A WRITE THROUGH A `state` FIELD ASKS NOTHING OF ITS ROOT. The cell
  takes it, so `self.n = …` in a handler and `c.n = …` on a parameter
  run; `self.plain = …` keeps `resolve.immutable`'s words. The root's
  verdict is spoken at typing, where the field is known. Such a write
  marks no receiver written.
- `@std/meta`: `Field.state`, `Type.body`, `composes`.
- `@std/meta`'s `Site`: A FIELD'S TYPE IS ITS MEANING. A record literal
  that leaves a `Site` field unset holds its own site — its file, its
  own content and its turn among the literals like it in that file,
  folded — so it owes no default. One constant a literal;
  content-addressed, so a line added above it moves nothing, and two
  literals written alike are still two sites.

### Refused

- `type.component_body`: "a component is made of what its body holds,
  and nothing here says what `x`'s is" — no trait composes; and "one
  trait says what a component's body is, and here `A` and `B` both
  do"; what the composing trait's own `derive` refuses, in its words
  and under its package's kind. A derive that cannot run is
  `annotation.unsettled`, at the component.
- `type.component_head`: "the brace after an instance's head opens the
  instance's block, so `P { … }` is no record literal here"
- `resolve.unresolved`: "`label` is not defined — a member is read
  through its receiver", help "write `self.label`"
- `build.failed`: "a component holds its fields, its `fn`s and what it
  is made of — never a declaration of its own"; "a component's `state`
  is a field, and a field says its type — `state n: int = 0`"
- `@std/ui:prim`: "a view is a primitive or is made of views, and `x`
  is neither"
- `@std/ui:primitive-body`: "a primitive is drawn by its target, and
  `x` holds a body of its own"
- `@std/ui:stateful-primitive`: "a primitive draws what it is told,
  and `n` is a place it would keep"
- `@std/ui:boxed-composition`, `@std/ui:marked-composition`: a
  composition spreads no `Box` and marks no member

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
(`html`, `dom`, `tui`); `app/` is the loop;
`web/`, `terminal/` and `headless/` are where an app is mounted.

## `avra dev` — the loop

ONE VERB: `avra dev <path> [--port N] [--host H] [--open] [--no-watch]`,
and what it does follows what it is pointed at.

| pointed at | it |
|---|---|
| a directory that is no package | serves its files as they stand |
| a package whose program mounts a page | builds it, serves it, watches, rebuilds, tells the page |
| a package with no program | refuses: a library, and what a page is |
| a package whose program mounts no page | refuses: nothing to serve, `avra run` runs it |
| a file | refuses |

A package is a directory with a manifest. It MOUNTS A PAGE when one of
its own sources imports `@std.ui.web` — asked of the `use` lines the
workspace reads (`imported_by`), never of a file's name.

- **No JIT. The page runs a real wasm module**, the artifact that ships.
  A change triggers a rebuild — `avra build --target wasm
  --wasm_reactor`, as anyone runs it, as a child — and the compiler's
  store makes it incremental: only the files that moved are read again,
  only their objects made again, then one link and one `wasm-opt`.
  The board, on a machine under load: cold 2.7 s; a one-line edit 1.1 s
  to 1.6 s; unchanged 0.2 s to 0.3 s. Of a warm edit the compiler's own
  phases are about 0.4 s (link 100 ms the largest); the rest is
  `wasm-opt -Oz` and two process starts.
- **Serving a directory is `@std/http`'s own** (`files.av`'s
  `directory`: path-safe, validated, ranged, each file typed by its name
  — `application/wasm`, a script as a script). The smallest honest
  program today:

      use @std.http.server.{server}
      use @std.http.files.{Files, directory}

      server site {
          port: 8080
          routes: directory("/", Files { root: "public" })
      }

      match site.run() { .Ok(n) -> "served ${n}", .Err(e) -> e.describe().message }

  What stands in the way of `files "/" { root: "public" }` as a route
  line: a component that expands to code takes no `key: value` settings,
  and a component's head takes one argument (`avra-8sb5.11`, survey).
  A dev server asks for a file again every time (`max-age=0` over its
  validators).
- **The server lives in the command** (`commands/dev.av`, one file): a
  `server` declared over `@std/http`, answering on a task of its own in
  the `avra` process while the first task turns the watch. What that
  costs the compiler's own build, measured: cold 1972 MB without it and
  2177 MB with it (30 more files); after a one-file edit 339 MB and
  637 MB. Every export of `@std/http` is compiled into the compiler —
  1132 of its symbols, where a program that reaches the same server
  carries 411 — because a native program's exports are roots.
- **Ports.** Loopback by default (`--host`), port 8787 by default,
  `--port 0` for any free one; the address served is printed. A port
  that is taken is refused by name: `listen 127.0.0.1:8787: Address
  already in use — --port 0 takes any free port`.
- **The watch set is the build's own inputs** (`Workspace.build_inputs`:
  the files its key covers — the closure's sources, the manifests, the
  toolchain's own), asked again every turn, so a file that arrives is
  seen. Looked at every 250 ms: a file is its stamp, or — too young for a
  stamp to tell two writes apart — its text, so a save that changed
  nothing builds nothing. What is remembered is what a build STARTED
  from. Nothing is watched where there is nothing to rebuild.
- **The page is told over an event stream** (`/@dev/events`, `@std/http`'s
  `sse.av`): `built` says the standing module's number — the count of builds that
  made another module — and `failed` says what
  the build said. A stream and not a socket: the server only ever tells,
  the browser reopens a dropped stream by itself, and a page that joins
  late — or again after the server restarted — hears where things stand
  as its first event.
- **The reload client is dev-only glue** (`runtime/dom/dev.js`), put in
  the page's `<!--DEV-->` hole beside the number of the module the page
  is about to load. A production page never carries it.
- **A module that is no longer the one the page runs reloads the page.**
  A build that failed is shown over the page and in the terminal, and
  the last good module is still what is served and what runs.
- **The toolchain is found.** `--target wasm` is whichever WASI triple
  this machine's clang has a libc for — `CC` alone when set, else
  `LLVM_PREFIX`'s clang, then the PATH's — and a machine with none hears
  which compilers were asked for which triples.

State kept across a reload is not built: `avra-8sb5.59.41.1`.

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
- Compositions, as they stand: an instance takes ONE head value
  (`avra-8sb5.11.331`); a composition with no head is written `name
  {}`, never bare (`.332`); a name in generated code other than an
  impl's own trait still resolves in the landing file (`.333`); `fmt` prints a component's fields, then its body, then
  its `fn`s, whatever order they were written in.
