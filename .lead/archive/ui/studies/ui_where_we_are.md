# UI: where we left off (authoring, theming, state)

Read-only audit of branch `program`, 2026-11-16. Every claim below comes from the code
or tests cited. Nothing was built or run. "Works" means a program test or spec covers it
in the tree. It does not mean I ran it.

Paths are relative to the repo root. `std-ui/` means `packages/std-ui/src/`.

---

## 1. How it is written today

### 1A. Component authoring

There are two kinds of component, and the compiler tells them apart by one annotation
(`std-ui/tree/view.av:1-26`):

- **Primitive**: `@derive(View) @prim(.X)`. It has no body. Its fields are tagged with
  what they project to (`@attr`, `@children`, `@style`, `@host … on`). It projects to
  one neutral `Node`.
- **Composition**: a `component` with a body. It has no derive and no spread. The
  body is the views it is made of, and its `state` members belong to the instance.

**Primitive, simple** (`std-ui/components/text.av:8-15`):
```avra
@derive(View)
@prim(.Text)
export component text(@attr(.Text) content: string) {
    ..Box

    words: Words = no_words()
    reads: Cells = []
}
```

**Primitive with an event** (`std-ui/components/button.av:8-18`):
```avra
@derive(View)
@prim(.Button)
export component button(@attr(.Label) label: string) {
    ..Box
    words: Words = no_words()
    reads: Cells = []
    @attr(.Disabled) disabled: bool = false
    @attr(.Loading) loading: bool = false
    @attr(.Submits) submits: bool = false
    @host(web: .Click, terminal: .Enter) on press
}
```

**Primitive with children and an event** (`std-ui/components/dialog.av:10-19`):
```avra
@derive(View)
@prim(.Dialog)
export component dialog(@attr(.Label) label: string) {
    ..Box
    words: Words = no_words()
    reads: Cells = []
    @attr(.Open) open: bool = false
    @children items: List<dyn View> = []
    @host(web: .Cancel, terminal: .Escape, always: true) on dismiss
}
```

**An event that carries a value** (`std-ui/components/field.av:18`):
`@host(web: .Input) on input(typed: string)`. This field has no terminal event. The
terminal handles typing through its own match on the primitive
(`std-ui/terminal/terminal.av:233,259`).

**A compile-time check on a primitive** (`std-ui/components/image.av`): it has
`fn check() -> List<Diagnostic> { image_words(self.alt, self.decorative) }`. The
compiler refuses an image that has neither `alt` nor `decorative`, or has both.

**The shared box** (`std-ui/style/box.av:11-16`). Every primitive spreads it in:
```avra
export type Box = {
    style: Style = Style {},
    layout: Layout = Layout {},
    a11y: Name = Name {},
    ..Stand,          // key, site, via, structural, opaque
}
```

**A user's own composition**, from the board (`tools/ui-board/src/board.av:188-195, 232-249`):
```avra
/// One filter: pressed, it is the filter in force.
component tab(label: string) {
    shows: Show                                  // required field, set by name
    button self.label {
        on press { filter = self.shows }         // module-level state, read bare
        style: tab_style(filter == self.shows)
    }
}

component new_task {
    state draft: string = ""                     // instance-owned
    row {
        layout: inline_layout()
        field "New task" {
            value: self.draft
            placeholder: "Type a task…"
            on input { body -> self.draft = body }   // handler binds the event's seat
        }
        button "Add" {
            on press {
                add(self.draft)
                self.draft = ""
            }
            style: sunk_style()
        }
    }
}
```

How each piece is spelled:

| concern | spelling | evidence |
|---|---|---|
| props, positional | head seats: `component chip(label: string)`, used as `chip "x"` | `std-ui/tests/prop_cell/prop_cell.av:10,18` |
| props, by name | fields with defaults; set in the block as `name: value` | board.av:190,215 (`tab "All" { shows: .All }`) |
| defaults | `field: T = expr`; a field with no default is required | board.av:190; `std-ui/forms/form_inputs.av:13-14` |
| children, primitive | `@children items: List<dyn View> = []`; block statements fill it | column.av:11, board.av:287-298 |
| children, from a fn | `items: [..]` or a bare `[…]` statement in the block | `std-ui/tests/keyed_list/keyed_list.av:17,21`; `packages/std-ui_gallery/src/gallery.av:41` |
| children, user composition | no example and no test. Every composition in the tree takes data props, never a children slot | grep for `@children`/`List<dyn View>` on non-`@prim` components: none |
| event, declare | `on name(seat: T)` in the component | `std-ui/forms/form_inputs.av:44-45` |
| event, handle | `on press { … }`, `on change { checked -> … }` | board.av:257 |
| event, forward | `on typing: self.typing` | form_inputs.av:59-60 |
| event, fire | `let fire? = self.typing else { return }` then `fire(…)` | form_inputs.av:76-86 |
| conditional | `if`/`else`/`match` as body statements | board.av:270-276; form_inputs.av:48-66 |
| list | `for t in xs { … }` in a body | board.av:274 |
| keyed list | `list xs by it.id { r -> … }` | keyed_list.av:23-27; form_inputs.av:46 |
| explicit key | `key: "${t.id}"` setting (`string?` only) | board.av:274; identity.av:37 |
| methods | `fn` inside the component; fields read as `self.x` | form_inputs.av:72-86 |
| generic composition | `component marked<T> { held: List<T> = [] … }` | `std-ui/tests/generic_composition_test.av:27-31` |

Library compositions also exist: `form_inputs`, `shape_inputs`, `model_form<T: Decode>`
and `model_table<T: Decode>`, in `std-ui/forms/`.

### 1B. Theming

The model has three layers. A token is a *name* (an enum), the theme maps names to
values, and `Style` and `Layout` carry tokens only, never values.

**Tokens** (`std-ui/style/tokens.av:10-50`). All are closed enums:
```avra
export enum Size { None, Xs, S, M, L, Xl }                     // @word(..) each
export enum Tone { Text, Muted, Danger, Surface, SurfaceRaised, SurfaceSunk, SurfaceHover }
export enum Font { Body, Heading, Footnote, Mono }
export enum Level { Flat, Low, Medium, High, Highest }
export enum TypeSize { Display, Headline, Title, Body, Label }
export enum LineHeight { Tight, Normal, Loose }
export enum Tracking { Tight, Normal, Wide }
```

**Theme** (`std-ui/style/theme.av:18-24, 28-58`):
```avra
export type Theme = {
    mode: Mode,                       // Light | Dark | HighContrast
    space: Map<string, int>,
    radius: Map<string, int>,
    color: Map<string, string>,
    face: Map<string, string>,
}
export const default_theme = Theme { mode: .Light, space: {"none": 0, "xs": 4, …},
    color: {"text": "#111111", …, "surface-hover": "#f0f0f0"}, face: {"body": "system-ui, sans-serif", …} }
export const dark_theme = default_theme with { mode: .Dark, color: { … } }
export const high_contrast_theme = default_theme with { mode: .HighContrast, color: { … } }
```
The theme has no maps for elevation, type size, line height or tracking.

**Style** (`std-ui/style/style.av:11-36`) and **Layout** (`std-ui/style/layout.av:21-50`):
```avra
export enum Interaction { Hover, Focus, Pressed, Disabled }
export type StateStyle = { state: Interaction, style: Style }
export type Style = { radius: Size?, fill: Tone?, color: Tone?, elevation: Level?, face: Font?,
    text_size: TypeSize?, line_height: LineHeight?, tracking: Tracking?, states: List<StateStyle> = [] }
export enum Sizing { Hug, Fill, Fixed(int), Percent(float) }
export type Layout = { direction: Axis?, wrap: Wrap?, gap: Size?, pad: Edge?, margin: Edge?,
    align: Align?, distribute: Distribute?, width: Sizing?, height: Sizing?, grow: int = 0,
    aspect: float?, inset: Edge?, order: int = 0 }
```

**Applying a style to a node.** Use a setting in the instance block, usually through a
helper fn. Board, lines 173-186 and 287-289:
```avra
fn sunk_style() -> Style { Style { fill: .SurfaceSunk, radius: .S } }
fn spread_layout() -> Layout { Layout { gap: .M, align: .Center, distribute: .SpaceBetween } }
card "Board" {
    style: Style { fill: .SurfaceRaised, radius: .M }
    layout: Layout { gap: .M, pad: around(.M) }
    …
```
A component can also fix a token through a field, as in `std-ui/components/error_text.av:14`:
`@style(color) tone: Tone = .Danger`.

**State-dependent style** (hover, pressed, disabled). The only spelling is a list
inside `Style`. Only a render test uses it (`std-ui/realize/tests/render_test.av:155-161`):
```avra
style: Style { fill: .Surface, states: [
    StateStyle { state: .Hover, style: Style { fill: .SurfaceHover } },
    StateStyle { state: .Pressed, style: Style { fill: .SurfaceSunk } } ] }
```

**Switching the theme.** It is app-wide only. A program passes a `fn() -> Theme`
to `mount` (`std-ui/web/web.av:60`, `mount(view, theme: fn() -> Theme = plain)`), and the
board computes it from state (board.av:143):
```avra
export fn theme() -> Theme { if dark { dark_theme } else { default_theme } }
```
`tools/ui-board/src/main.av` mounts it as `mount(view, theme)`.

**Reaching the web** (`std-ui/realize/html/css.av:1-8, 419-447`):
- Each token field becomes an atomic class named after the token: `fill-surface`, `gap-m`.
- Each class reads a CSS variable that the theme fills: `--tone-surface`, `--space-m`, `--radius-s`, `--face-body`.
- `root_vars(t)` writes `:root{color-scheme:…;--space-xs:4px;…}`.
- An interaction override prefixes the class (`hover:fill-surface-hover`), and the
  rule gets the pseudo-class (`pseudo_class`, css.av:30-37: `:hover`, `:focus-visible`,
  `:active`, `:disabled`).
- Alternate themes are emitted under `@media (prefers-color-scheme: dark)` and
  `(prefers-contrast: more)` (css.av:494-503).
- A page's base look is hand-written CSS in `base_rules()` (css.av:476-491): the
  button border, the dialog position and so on.

**Dark mode** is a whole replacement `Theme` (`dark_theme`), not a token layer.

**Density** has no spelling anywhere (grep `density`: none).

**The terminal ignores theming.** `render(root: Node, _env: Env, width)`
(`std-ui/realize/tui/tui.av:16`) drops the env, and the terminal `mount` takes no theme
(`std-ui/terminal/terminal.av:724`).

### 1C. State

`state` has four homes, and all of them share one rule: a `state` is a PLACE, not a
value.

1. **Module-level.** The board keeps most of its state here (board.av:62-69):
   ```avra
   state filter: Show = .All
   state dark: bool = false
   state tasks_ask: Fetch<List<Todo>> = fetch()
   ```
   Reads and writes are bare: `filter = self.shows`, `dark = !dark`.
2. **Component instance.** `state draft: string = ""` inside a composition, read and
   written as `self.draft` (board.av:233). The instance is kept by where it stands
   and lives while a paint reaches it (`std-ui/tree/view.av:21-26`).
3. **fn local and fn parameter.** `state` on a parameter makes it a place the caller
   owns (`std-ui/tests/param_state/param_state.av:3-13`):
   ```avra
   fn stepper(state n: int) { n = n + 1 }
   fn counted() -> int { state c: int = 0; stepper(c); stepper(c); stepper(c); c }   // 3
   ```
   The compiler enforces the law that a `state` seat's argument is a `state` binding
   (`std-avrac/src/features/checks.av:1849-1866`).
4. **Record field.** `type Todo = { id: string, title: string, state starred: bool = false }`.
   The place lives on the model, so it lasts as long as the todo does
   (`std-ui/tests/parts/task_row.av:5`).

**Passing state to a child composition.** A component's head seat cannot be marked
`state`: the grammar is `hseat = marks* name ":" type`
(`std-avrac/src/features/components/mod.av:45`). So a child gets the value plus
events back up, which is the React "lift state" pattern. `form_inputs.av:20-26`:
```avra
shape_inputs self.shapes {
    typed: self.typed
    ticked: self.ticked
    issues: self.issues
    on typing { t -> self.typed = {..self.typed, "${t.at}": t.typed} }
    on ticking { t -> self.ticked = {..self.ticked, "${t.at}": t.on} }
}
```
A stateful composition's comparable head prop is held as a cell, so a later paint
writes the new prop and keeps the instance's state
(`std-ui/tests/prop_cell/prop_cell.av:1-6`).

**What triggers a repaint.** Any handler, timer or answer runs through
`App.turn(act)`. If the act ran, the app marks itself dirty and the whole view is
walked again: at once, or at the target's frame (`std-ui/app/app.av:314-330, 225-232`).
There is no per-cell subscription on the default path. The exact path, which patches
only the texts that read changed cells, exists but is **off unless `AVRA_EXACT` is
set** (`std-ui/realize/dom/live.av:54-59`). A state written outside a turn, or while
the view is being described, paints nothing (`std-ui/tests/parts/eager.av`).

**Instance identity** (`std-ui/tree/identity.av:36-63`):
```avra
export type Stand = { key: string? = null, site: Site, via: string? = null, structural: Structural = [], opaque: Opaque = false }
export enum Step { Keyed(key: string, turn: int)  Sited(site: Site, turn: int, at: int)  Part(name: string)  Through(via: string, step: Step) }
```
- A sibling is matched by its key if it has one, else by the lexical site where it
  was written plus a turn counter (that is, by order).
- At compile time, an unkeyed stateful instance inside a `for` or a comprehension is
  refused with `type.component_row`: "a repeated `tick` keeps state and wears no key, so its state stays with its place and lands on whichever row holds that place next" (`std-avrac/src/features/repeated.av:47-55`).
- A row made by a helper fn is only warned about at runtime (`ui: …` on stderr,
  `std-ui/app/app.av` `warn`).

**Ambient and environment values.** None exist. `Env { theme, direction, locale }`
(`std-ui/env.av:11-15`) is a plain record. Only the html `Page` header and the tui
signature read it. No component can read a value from above, and there is no
`provide`, `env` or `ambient` mark (grep `ambient` over `packages/`: zero hits).

**Async and observations** (`std-ui/app/async.av:7-12, 35`; `app/asks.av:34`; `app/typed.av:19-66`):
```avra
export enum Async<T> { Idle  Loading  Failed(message: string)  Ready(value: T) }
export type Fetch<T> = { now: Cell<Async<T>>, id: int, at: Cell<Entry?>, last: Cell<T?>, seen: Cell<int> }
state tasks_ask: Fetch<List<Todo>> = fetch()
let _ = ask_list(tasks_ask, doors().list!, Nothing {})                               // board.av:309
let _ = send(saving, doors().update!, t with { done: done }, foresee: Overlay.Patch("id", "${t.id}"))  // board.av:156-161
```
- GETs are cached and shared by key.
- A write is a layer shown at once (`Overlay.Append`/`Patch`/`Hide`/`Custom`, `app/layers.av:13`).
- A feed stream keeps entries fresh (`app/feeds.av`).
- The view reads `tasks_ask.value()` and `.failure()`.
- Timers: `later(ms(100), act)` and `repeating(...)` (`app/asks.av:10-17`).

**Persistence.** Nothing persists to device storage (grep `storage`/`persist`: only DOM
event names). The only carrying is `ship(...)`, which moves server-render or
hot-swap state into the page (`std-ui/shipped/shipped.av:1-16`). It is opt-in, and each
state needs its own hand-written read and write fn (board.av:75-122).

---

## 2. A full small example

`tools/ui-board/src/board.av` is the most representative program. It uses all three
areas: compositions, a keyed row, instance and module state, theme switching,
observations and styles. Lines 251-299 and 329-368:

```avra
// tools/ui-board/src/board.av
/// One task's row. Its key is the task's id, so its node goes where the
/// task goes.
component task_row(task: Todo) {
    item {
        checkbox self.task.title {
            checked: self.task.done
            on change { checked -> mark(self.task, checked) }
            style: title_style(self.task.done)
        }
        button "Remove" {
            on press { remove(self.task) }
            style: sunk_style()
        }
    }
}

/// The task rows: ONE list of keyed rows, so a reorder or an insert
/// keeps every node. An empty view is a word, never a stray row.
component task_rows {
    if visible().is_empty() {
        text "Nothing here yet." { style: Style { color: .Muted } }
    } else {
        list {
            for t in visible() { task_row t { key: "${t.id}" } }
        }
    }
}

component board {
    card "Board" {
        style: Style { fill: .SurfaceRaised, radius: .M }
        layout: Layout { gap: .M, pad: around(.M) }
        progress "Done" {
            amount: done_count()
            max: tasks().length
        }
        filters {}
        new_task {}
        divider {}
        task_rows {}
    }
}

component about {
    dialog "About" {
        open: dialog_open
        on dismiss { dialog_open = false }
        heading "Task board" { rank: 2 }
        text "The board is made of compositions; each keeps what is its own."
        button "Close" {
            on press { dialog_open = false }
            style: sunk_style()
        }
    }
}

export fn view() -> surface {
    surface {
        style: Style { fill: .Surface, radius: .M }
        layout: Layout { gap: .M, pad: around(.L) }
        header {}
        board {}
        footer {}
        about {}
    }
}
```

The other files of the board:
- `tools/ui-board/src/main.av` mounts it as `ship_state(); mount(view, theme); load()`.
- `tools/ui-board/term/src/*.av` mounts the same `view` in a terminal.
- `tools/ui-board/model/src/*.av` declares the shared `@crud @json type Todo`.

An older board in a different style also stands at `std-ui/tests/board/board.av`
(276 lines). It uses fns that return `List<dyn View>` and `let … : List<dyn View>` pins.

---

## 3. What is missing or rough

### Authoring

- **No children slot proven for user compositions.** Only `@prim` components declare
  `@children`, and no test has a composition that takes a body of views. A React
  `children` / SwiftUI `@ViewBuilder content` has no witness.
  Evidence: the `List<dyn View>` hits are all primitives or `let` pins
  (`std-ui/tests/identity/identity.av:28`, `instance_sites.av:31`).
- **The primitive set is closed.** `Prim` is a 24-variant enum (`std-ui/tree/node.av:20-45`).
  A user cannot add a primitive, only compose. Several common controls are missing:
  select/picker, radio, textarea, tabs, table, scroll container, menu, tooltip, toast.
  Evidence: the `Prim` enum; `model_table` fakes a table out of `row`s of `text`
  (`std-ui/forms/model_table.av:18-26`).
- **Event payloads are limited to four shapes.** `Handler` is `Nothing | Text | Flag | Number`
  (`std-ui/tree/node.av:59-64`). A slider is `int`-only (`components/slider.av:11-17`).
  There is no float, no record and no pointer or position payload.
- **Every worded primitive repeats compiler-plumbing fields.** `words: Words = no_words()`
  and `reads: Cells = []` appear in 12 component files. These are the exact-patch path's
  fill-ins, not component API.
  Evidence: `components/text.av:13-14`, `button.av:12-13`, `dialog.av:14-15`.
- **Firing an optional event is a three-line pattern** repeated per event:
  `let fire? = self.x else { return }; fire(...)`.
  Evidence: `std-ui/forms/form_inputs.av:76-86` (twice) and `forms/model_form.av:24-27`.
- **There is no two-way binding.** Every input is spelled as `value:` plus
  `on input { v -> self.x = v }`. Evidence: board.av:236-240; form_inputs.av:62-66.
- **`self.` is required everywhere inside a composition**, while module state is read
  bare. A component mixes both spellings: `filter == self.shows` at board.av:193.
- **A key is `string?` only**, so an int id is interpolated: `key: "${t.id}"`
  (board.av:274; `tree/identity.av:37`).
- **There are no lifecycle hooks** (appear, disappear, effect). The board calls
  `load()` at module top after `mount` (`tools/ui-board/src/main.av`). grep for
  `appear`, `onMount` and `lifecycle`: none.
- **Programmatic focus and refs are not exposed.** Only `Placed(reveal)` is
  (`tree/node.av:168`).
- **Components that declare events must not live in the entry file.** The seat
  collection does not reach that file, and the program traps at runtime:
  "or it is declared in the entry file, which a closure collection does not reach"
  (`std-ui/tree/seats.av:87`). This is why the board keeps everything in `board.av`
  and `main.av` is six lines.
- **Generic stateful compositions keep their state as text.** "a `once fn` takes no type
  parameters, and a stateful composition's keeper is one"
  (`std-ui/forms/model_form.av:8-11`). Lists of records in forms are unsupported
  (`.Records(_) -> .Unlisted`, form_inputs.av:101).
- **The board's doc comment and its code disagree.** board.av:9-10 says
  "`list visible() by it.id`", but the code uses an explicit `key:` (board.av:274).
- **CLAUDE.md's subset section is stale here:**
  - It says the keyed list `list xs by it.id { x -> … }` is refused ("takes no head
    value", CLAUDE.md:1703). It works: `std-ui/tests/keyed_list/keyed_list.av`
    expects `identity=true`, and `forms/form_inputs.av:46` uses it.
  - It says "`@model type` is '`model` is not defined'" (CLAUDE.md:1705). The derive
    exists in `@std/db` (`packages/std-db/src/db.av:1-12`); the refusal is only for an
    un-imported name.
- **`derived` and `query` do not parse** ("expected BREAK",
  `std-avrac/src/compiler/tests/subset/refusals_test.av:320-333`). Derived values are
  plain fns recomputed on every walk: board.av:135-141 `done_count()` and
  `open_count()` each re-filter `tasks()`, and `tasks()` itself re-filters on every call.

### Theming

- **There is no subtree theme override.** Theme is one `fn() -> Theme` per `mount`
  (`web/web.av:60`), and `Env` is never read by components (`env.av`).
- **Tokens are closed enums.** `Tone` has 7 roles, with no primary, accent, success,
  warning or border. A user cannot add a token, and the CSS emits variables only for the
  listed variants (`realize/html/css.av:24-26` hard-list `sizes`, `tones` and `fonts`
  instead of `every()`). Theme maps are keyed by string, so a misspelled key falls
  back to `""` or `0` silently (`style/theme.av:73-82`, `?? ""`).
- **Half of `Style` reaches no target.** `elevation`, `text_size`, `line_height` and
  `tracking` are declared (`style/style.av:30-34`), but `appearance_rules` emits only
  color, fill, radius and face (`realize/html/css.av:250-258`). The theme has no table
  for them. **Text size cannot be set today.**
- **A mounted page never follows the OS dark mode.** Live DOM paints always pass no
  alternates: `page_sheet(rules, theme, [])` (`realize/dom/live.av:220,250,328`).
  Only a server `Page` with `alternates` gets the `prefers-color-scheme` rules
  (`realize/html/html.av:89`).
- **The default control look is hand-written CSS** in `base_rules()`
  (`realize/html/css.av:476-491`): the button border, the dialog position and so on. It
  is not neutral `Style` data, so every new target has to reinvent it.
- **State styles are verbose and unused.** The `StateStyle { state: .Hover, style:
  Style {…} }` list appears only in a render test (`realize/tests/render_test.av:155-174`).
  No component or app uses one.
- **There is no density, no breakpoint or size class, and no animation or
  transition** (grep: none).
- **The terminal drops all colour and theme** (`realize/tui/tui.av:16`, `_env`).
- **Theme values are web-shaped strings:** colours as `"#111111"`, faces as CSS family
  lists `"system-ui, sans-serif"` (`style/theme.av:26-46`).

### State

- **A child composition cannot take a `state` seat.** The grammar has no `state` on
  `hseat` (`std-avrac/src/features/components/mod.av:45`). Sharing means props plus
  events (prop drilling, form_inputs.av:20-26 and 55-61), module state, or a raw `Cell`.
- **There is no context or ambient mechanism.** The design-as-built claims one (see the
  final note). The `typed`, `ticked` and `issues` values are threaded by hand through
  each nesting level (form_inputs.av:55-58).
- **Repaint re-walks the whole view on every turn.** The precise path (`AVRA_EXACT`) is
  opt-in staging (`realize/dom/live.av:54-59`).
- **Async ceremony:**
  - `state x: Fetch<T> = fetch()` is a record of five Cells held inside a state
    (`app/async.av:35`).
  - Every ask and send result is discarded with `let _ =`, five times in board.av
    (151, 156, 166, 309, 326).
  - The board reaches into internals: `tasks_ask.now.set(Async.Ready(read))` (board.av:117).
- **Layer keys are stringly typed:** `Overlay.Patch("id", "${t.id}")` names the key
  column as a string (board.av:160, 166; `app/layers.av:11-18`).
- **Shipping state is three hand-written fns per state:** one `ship(...)` line plus a
  `*_written` decoder (board.av:75-122). There is no `@shipped` mark on a `state`.
- **There is no client persistence** (local storage or a device store).
- **An unkeyed stateful row made by a helper fn** is only a runtime stderr warning,
  not a compile error (`std-avrac/src/features/repeated.av:5`, "a row made by a helper the
  loop calls is the runtime's to refuse").
- **A state write while describing lands silently and paints nothing**
  (`std-ui/tests/parts/eager.av`). It is allowed, not refused.

---

## 4. Target-neutrality check

The question here is which web-specific names appear in the layers a native target
would share: `components/`, `style/`, `tree/`, `app/`, `place/`, `forms/`, `shipped/`,
`native/`, `env.av`. The `realize/` and `web/` directories are excluded.

**Code, not comments:**

| file:line | what |
|---|---|
| `tree/dom_event.av` (1639 lines) | `enum DomEvent`: every w3c DOM event, generated from webref. It lives in the neutral `tree/` |
| `tree/seats.av:7, 37` | `use tree.dom_event.{DomEvent}`; `SeatRow.web: DomEvent?` |
| `tree/seats.av:38` | `SeatRow.terminal: Key?`: every target is a named field of the row. iOS would mean a third field |
| `tree/seats.av:75-79` | `web_word(seat)` traps: "has no web event, and a page listens for one" |
| `tree/view.av:54, 306, 439, 460, 482, 689, 707` | the View derive writes `DomEvent.${w}` and validates `@host(web: …)` |
| `components/button.av:17` | `@host(web: .Click, terminal: .Enter) on press` |
| `components/link.av:16` | `@host(web: .Click, terminal: .Enter) on press` |
| `components/checkbox.av:15` | `@host(web: .Change, terminal: .Enter)` |
| `components/switch.av:15` | `@host(web: .Change, terminal: .Enter)` |
| `components/field.av:18` | `@host(web: .Input)` (web only) |
| `components/slider.av:17` | `@host(web: .Change)` (web only) |
| `components/form.av:12` | `@host(web: .Submit, terminal: .Enter, prevent: true, always: true)`: `prevent` is DOM `preventDefault` |
| `components/dialog.av:18` | `@host(web: .Cancel, terminal: .Escape, always: true)` |
| `components/key.av:13` | `@host(web: .Keydown, terminal: .Shortcut)` |
| `tree/chord.av:94` | `Chord.web_spec()`: `KeyboardEvent.code` / `.key` spelling |
| `tree/terminal_key.av` | the terminal's key enum, also in neutral `tree/` |
| `style/style.av:11-17` | `Interaction.Hover`: hover has no touch meaning; the other three map to CSS pseudo-classes |
| `style/theme.av:26, 33-45` | colours as CSS hex strings; faces as CSS `font-family` lists |
| `style/words.av:45` | `@word` turns `_` into `-` (`surface-raised`): CSS-shaped token words |
| `tree/node.av:40, 159` | `Prim.Form` and `Attribute.Submits`: HTML form semantics |
| `tree/url.av` | URL law written against "as a browser reads it" (`:4, 11, 34-48`); `Href(url)` on `link` |
| `shipped/shipped.av` | a whole module for server-render and hot-swap page state |
| `place/solve.av:2-4, 81` | the layout model is "CSS flexbox … the very algorithm a browser runs". It is neutral data, but CSS semantics are the spec |

**Comment-only mentions** (no coupling):
- `style/style.av:24` ("CSS pseudo-classes")
- `tree/identity.av:12-35` ("a page")
- `place/measure.av:3`, `place/text.av:3`, `place/metrics.av:3`
- `app/app.av:38, 80, 150`

**Assessment for iOS:**
- `Node`, `Prim`, `Attribute`, `Style`, `Layout` and the solver are neutral data.
- The event layer is not neutral. Each component names its web and terminal event
  inline, and `SeatRow` has one field per target, so a new target touches every
  event-bearing component, `seats.av` and the View derive.
- Per-primitive behaviour is re-implemented per target as exhaustive matches. That is
  correct, but it is real work: about 4 such matches in `terminal/terminal.av:207-261`
  and several in `realize/tui/layout.av:43-109`.
- Default control appearance exists only as CSS (`base_rules`).

**Realizers and targets that exist** (non-test lines and files):

| dir | lines | files | what it does | completeness |
|---|---|---|---|---|
| `realize/html` | 1353 | 6 | static HTML plus the atomic CSS sheet; server render; hydration page | all 24 prims (exhaustive matches); 22 tags in `HtmlTag` |
| `realize/dom` | 3463 | 8 | live page: Avra-side diff to a patch op stream over the binary wire v15 (`wire.av:49`); exact path; adopt/hydrate | all prims. **`realize/dom/dom_event.av` (1639 lines) is a stale duplicate of `tree/dom_event.av`**: an older generator header, used only by its own test (`realize/dom/tests/dom_event_test.av:3`) |
| `realize/tui` | 466 | 6 | text drawing of a tree at a width (layout, paint, wrap, hit) | all prims as text: `[x]` boxes, `name: n (min..max)` sliders, `[image: alt]` |
| `terminal/` | 1377 | 3 | the live terminal driver (keys, screen, mount) | input for field, slider, checkbox and Enter-press; no colour |
| `headless/` | 378 | 1 | in-memory `Screen` for tests (`press`, `text`, virtual clock) | test target |
| `web/` | 324 | 1 | `mount` on a page (wasm) | |
| `native/` | 323 | 2 | **not a UI target**: timer and http sources for the loop on native tasks | |
| `runtime/dom/*.js` | 2804 total | 16 | the JS page host (bootstrap, tasks JSPI/asyncify, wire decoder) | |

There is no iOS, Android, canvas or native-widget realizer.

---

## 5. Size facts

**Catalogue:**
- 25 component files in `std-ui/components/` covering 24 `Prim` variants. `error_text`
  is a second component on `.Text`.
- 4 library compositions in `std-ui/forms/`: `form_inputs`, `shape_inputs`,
  `model_form`, `model_table`.

**Lines of `std-ui/src` by top-level directory**, non-test, with the tests inside that
directory alongside:

| dir | lines | files | tests in dir |
|---|---|---|---|
| realize | 5282 | 20 | 6028 |
| tree | 4546 | 21 | 867 |
| app | 2184 | 10 | 104 |
| terminal | 1377 | 3 | 1321 |
| place | 881 | 6 | 475 |
| components | 396 | 25 | 0 |
| headless | 378 | 1 | 309 |
| web | 324 | 1 | 295 |
| native | 323 | 2 | 0 |
| style | 286 | 6 | 242 |
| forms | 268 | 3 | 0 |
| shipped | 124 | 1 | 126 |
| a11y | 22 | 1 | 220 |
| compose | 9 | 1 | 0 |
| `ui.av` + `env.av` | 46 | 2 | |
| `tests/` (package-level tests) | | | 5338 |

That is about 16,450 non-test lines in total. Of those, 3,278 are the two generated
`dom_event.av` files, one of them dead.

**Tests in `packages/std-ui`:**
- 53 `*_test.av` spec files: 111 `spec` blocks, 984 `then` cases.
- 85 program tests (`.expected`, `.refuses` or `.verdict`). 68 test entries sit
  directly under `std-ui/tests/`.

**Compiler component feature** (`std-avrac/src/features/components/`):
- 1919 lines across 11 files.
- 35 test entries, with 428 `then` cases in its spec files.

**Proving app:**
- `tools/ui-board/src/board.av`: 368 lines.
- `packages/std-ui_gallery/src/gallery.av`: 122 lines.
- `packages/std-ui_http/src/document.av`: 38 lines.

---

## Note: `docs/2026_11_16_UI.md` "The design as built" (lines 19-43), checked against the code

| claim | verdict |
|---|---|
| "**Ambient seats** replaced `provide` / `env`." (line 33) | **Contradicted.** No `ambient` anywhere in `packages/`. The same doc's ledger says "grep `ambient` empty" (line 646). Nothing replaced provide/env. `Env` (`std-ui/env.av`) is a plain record no component reads |
| "Layout is a native solver over a CSS **flex/grid** subset" (line 34) | **Wrong on grid.** No grid in `style/layout.av`, `place/` or `css.av`. It is flex only |
| "Exact patches: a page watches the cells its texts read and patches only those (`AVRA_EXACT`)" (line 37) | **Built but off by default.** Unset `AVRA_EXACT` means the full paint (`realize/dom/live.av:54-59`) |
| "A component is the node. State belongs to a component instance" (line 26) | **Incomplete.** Primitives project to a separate `Node` record (`tree/node.av:176`), and `state` also lives at module level (the board's main store), in fn params and locals, and on record fields |
| wire version 15, closures `on press`, `asset logo: Picture`, `within` keyword, JSPI/Asyncify, `@crud` | Confirmed in code |

The doc's "Unlanded work" section is also stale in two places:
- `app/layers.av`, `app/watch.av` and the `observed_layers` / `observed_watch` tests
  **are** in `program`.
- The ui-board **does** import `@ui.board_model` with `Todo.paths` and `send`.
- Percent sizes **did** land (`place/solve.av:188` `.Percent(p) -> share(p, room)`;
  `css.av:151`).
