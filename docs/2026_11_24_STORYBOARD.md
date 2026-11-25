# The storyboard

The design proposal (§1–§9, phase 1) was approved with rulings; §10 is what is built, slice by slice.

Every view in std-ui, in every state its own members imply, drawn under every OS dial on every target:
a page for the owner, a gate for the machine, and later a parity check between targets.
It is a PROPOSAL. Nothing in std-ui or the gallery has changed. The probes are under
`scratch-probes/storyboard/`, and `viewed_and_story.patch` there is the one probe that ran on a scratch
copy of std-ui.

**The compiler that answered every probe** is the gate-builder release asset
(`build/.avra-built-from`: `e144e35b… ab37abcd… 2`). That is program head `ab37abc`, generation 2.

**Spelling.** This doc writes `@View`, the annotation the owner approved (the alloc lane is building it),
where the tree still writes `@derive(View)`. `@story` and `@case` are plain fn annotations, and the
change of spelling does not touch them.

---

## 1. In one table

| Question | Answer | Mechanism (exists today?) |
|---|---|---|
| Which components? | Every type the View derive made a view of: **29** (25 primitives + `form_inputs`, `shape_inputs`, `model_form`, `model_table`) | The derive writes a `@viewed` row beside each one, and `collect … = @viewed in package` gathers them. This is the `@seat` pattern std-ui already uses (`tree/seats.av`). **The collect exists; the row is ~25 lines in `view.av`.** |
| Where does a story stand? | In the component's own file, beside its declaration | A `@story` fn answering the component's type. **Works today** (probe P5). |
| Who writes the states? | The compiler. `@story` reads the component's members with `type_named` and writes one case per member varied | A declaring annotation. **Works today** (P3, P5) |
| How are stories gathered across files? | `collect stories = @case_of in package` | **Works today** (P3, P5) |
| No story? | Refused, naming the component | Today a gate test names the missing ones (P6). A refusal at build time is ask A2. |
| Dials and targets | A `table<Dial>` and a `table<Target>`: data, never code per story | Exists today (`table`, `Mode`, `Contrast`) |

## 2. The spelling on three real components

The author writes the base, and only where content is needed. Everything in the right-hand column is
derived.

```avra
// components/button.av — beside `@View @prim(.Button) export component button(…)`
/// Words to press.
@story
fn button_story() -> button { button "Save" }
```

```avra
// components/field.av
/// A name to type.
@story
fn field_story() -> field { field "Name" { placeholder: "Ada Lovelace" } }
```

```avra
// components/dialog.av
/// A question that stands over the page.
@story
fn dialog_story() -> dialog {
    dialog "Delete the task?" {
        text "It cannot be undone."
        button "Delete"
    }
}
```

A hand-written NAMED case answers the same type and is gathered beside the derived ones. Its owner is
its answer type:

```avra
/// Saving: pressed, and waiting on the server.
@case("busy")
fn button_busy() -> button { button_story() with { loading: true, disabled: true } }
```

| Component | Members (the compiler's dump, P4) | Derived cases |
|---|---|---|
| button | `label:string · disabled=:bool · loading=:bool · submits=:bool · on press` | base · label empty/long/rtl · disabled · loading · submits = **7** |
| field | `label · initial=:string · value!=:string · shown=:string? · placeholder=:string · invalid=:bool · masked=:bool · on input` | base(own) · label ×3 · given `{value:"Ada"}` · own-seeded `{initial:"Ada"}` · shown `{shown:"Ada"}` · invalid · masked = **9** |
| dialog | `label · initial=:bool · open!=:bool · shown=:bool? · items=:List<dyn View> · on dismiss` | base(own, shut) · label ×3 · given `{open:true}` · own-seeded `{initial:true}` · shown `{shown:true}` · empty `{items:[]}` = **8** |

## 3. Where the states come from: the derivation table

The product is bounded by changing **one member at a time from the base**. There is never a cross
product. The rule is a REGISTRY over the member's shape. A shape not listed derives nothing, and the
author adds a `@case` for it.

| Member shape (`Field` from `@std.meta`) | Cases | Example |
|---|---|---|
| (always) | `base` | `button "Save"` |
| required `string` (head or field) | `empty`, `long` (≈200 chars), `rtl` (Arabic script) | `label`, `content`, `message`, `legend`, `chord` |
| `bool`, not a place | its default flipped | `disabled`, `invalid`, `selected`, `decorative` |
| enum | each variant but the default | `alert.urgency` +1, `error_text.ink` +9 |
| a place (`state`) | `given` (the place handed in), `own` (seeded through `initial`) | `field.value`, `dialog.open`, `checkbox/switch.checked` |
| `@over` optional (`shown: T?`) | `shown` (bool → `true`, string → the head's words) | `field.shown`, `dialog.shown` |
| `List<dyn View>` children | `empty` | `card`, `column`, `dialog`, … |
| `int`, `Picture`, `Url`, `fn`, a generic `T` | none: the author writes a `@case` | `heading.rank`, `slider.amount`, `model_form<T>` |
| `on event` | no snapshot case; an **operability claim** (§5b) | `on press`, `on input` |

Every generated case carries its own spelling as a literal (for example `button_story() with { disabled:
true }`). The owner's page shows that as the case's source.

**Count: 116 derived cases over 29 components**, plus the named cases (~10 expected), so **≈126**.

| alert 5 | button 7 | card 5 | checkbox 7 | column 2 | dialog 8 | divider 1 | error_text 13 |
|---|---|---|---|---|---|---|---|
| **field 9** | **fieldset 5** | **form 2** | **form_inputs 1** | **heading 4** | **icon 1** | **image 2** | **item 3** |
| **key 4** | **link 4** | **list 2** | **model_form 1** | **model_table 2** | **progress 4** | **row 2** | **shape_inputs 1** |
| **slider 4** | **spinner 4** | **surface 2** | **switch 7** | **text 4** | | | |

## 4. Dials and targets are data

```avra
export type Dial = { name: string, mode: Mode, contrast: Contrast, text: int }

export const dials = table<Dial> {
    name    | mode   | contrast  | text
    "light" | .Light | .Standard | 100
    "dark"  | .Dark  | .Standard | 100
    "more"  | .Light | .More      | 100
    "large" | .Light | .Standard | 200
}

export const targets = table<Target> {
    name       | draws
    "web"      | .Html        // fragment + the theme's sheet; the browser draws it
    "terminal" | .Text(80)    // gallery_text's render
    "headless" | .Outline     // tree/outline
}
```

- A dial changes the SHEET, not the html, so a semantic snapshot is per case × target, plus one sheet
  snapshot per dial. In the browser, every case is drawn under every dial.
- A native target is one more row (`.Native`). Parity (§5c) compares rows, not stories.

## 5. Three uses of one set (all inside `@std/ui_gallery`)

Placement. `@story`, `@case` and the case type live in **std-ui** (`tree/story.av`), because a
component's file cannot import the gallery, which depends on std-ui. Everything that READS the set lives
in **`@std/ui_gallery`**: the page, the snapshots, `changed`, the dials and the claims. Decision for the
UI lead: the gallery's `Case` moves down to std-ui, so there is one definition and no parallel type.

**(a) The owner's page.** `avra dev tools/storyboard` is a `[bin]` of three lines:
`mount(storyboard(views, stories, dials))`.

| Part | Spelling |
|---|---|
| index | every row of `views`, with its count of cases; a component with none is shown red |
| filter | a `field` over component and case names, plus a bool and a place toggle |
| light/dark side by side | two frames of one page, each holding `Mode`; with `ctx theme` (A4) it becomes one page |
| source | each case's generated spelling; the base's own text needs A3 |

**(b) The gate.**

| Check | How | Asserts |
|---|---|---|
| semantic snapshots | a program test in `std-ui_gallery` prints `view/case/target digest`, ≈126×3 lines plus 4 sheets, against its `.expected`; `changed` names what moved | what each case SAYS (html, outline, terminal) |
| coverage | a `then` naming every view with no story (P6's output, as its failure) | every component has a story |
| ui-browser claims | ONE JS table keyed by what the node says (Prim/Attribute), never per story | below |

| The node says | The claim, under every dial |
|---|---|
| a label or words | the accessible name equals the words, and they are drawn (width > 0) |
| words on a surface | computed ink ≠ fill; ratio ≥ 4.5 (words), ≥ 3 (border, focus) |
| an event seat | Tab reaches it unless it is `disabled`; Enter/Space fires the seat once; a tap fires it (webkit-iphone) |
| `disabled` | not reachable; pressing it fires nothing |
| a place | typing or ticking moves what is shown; `given` shows the given value |
| `long` | no overflow past its box (`scrollWidth ≤ clientWidth`) |
| `rtl` | computed `direction` is `rtl`. **This fails today**: P7's html has no `dir` (§6) |

**(c) Parity, later.** Same case ids, a native target row, and a comparison of what each target says.

## 6. The probes and their output (gate compiler `ab37abc`)

| # | Probe (`scratch-probes/storyboard/`) | Output | Means |
|---|---|---|---|
| P1 | `p1`: `collect = @prim in closure` from a program importing `button` | `25: alert,button,card,checkbox,column,dialog,divider,error_text,field,fieldset,form,heading,icon,image,item,key,link,list,progress,row,slider,spinner,surface,switch,text` | The primitives are already the compiler's list |
| P2 | `p4`: a `component` collected with `kind: it` as `Type` | `avra: the program layer doesn't build this program yet — \`Ident\`, at the entry` (the same collect over a `type`: `Gadget 1 Widget 3`) | A collect cannot hand a COMPONENT over as its description → A1 |
| P3 | `p5`: a `@story` declaring annotation; `type_named(f.answer)`; one case per bool; `@case_of in package` | `button_base_cases: base = button "Save" ; disabled = button "Save" disabled ; loading = button "Save" loading ; submits = button "Save" submits` | States derived from members, gathered across files |
| P4 | `p6`: every member of all 25, read at compile time | `field: label:string \| initial=:string \| value!=:string \| shown=:string? \| placeholder=:string \| invalid=:bool \| masked=:bool \| on input=:fn(string) -> void?  spreads Box+Sighted` (and 24 more rows) · `alert: … urgency=:Urgency{Polite,Assertive}` · `error_text: … ink=:Ink{Text,Muted,Disabled,Danger,Success,Warning,Link,Border,Field,Focus}` | Bools, places (`!`), optionals, enum variants and events are all readable. An enum must be visible in the file, which a component's own file always is |
| P5 | `p9` on a scratch std-ui (`viewed_and_story.patch`): the View derive writes `@viewed`; `@story` stands IN `button.av` | `29 views: alert(message,urgency) button(label,disabled,loading,submits,press) … form_inputs(…) … model_form(…) model_table(…) … shape_inputs(…) …` · `button_story_cases: base = … ; disabled = … ; loading = … ; submits = …` | Every view, compositions included, from a program that imports nothing; a story in the component's own file. `check packages/std-ui` on the copy: the same one warning as the tree, nothing new |
| P6 | `p5`: views without a story | `25 components, 1 with a story; no story: alert, card, checkbox, …` | Coverage is a list the gate can print |
| P7 | `p7`: `with` over component values | `field "Name" value="Ada" placeholder=""` · `dialog "Confirm" open` · `alert "Saved" assertive` · `<label class="th-1"><span>نام</span><input type="text" aria-label="نام" value="" placeholder=""></label>` | `given`, `shown`, enum variants and RTL are all spellable. **The RTL html has no `dir`**, which is the storyboard's first real finding |
| P8 | `p8`: 120 cases through `snapshots` twice, `changed`, `gallery_text` | native `120 snapshots, 0 changed, terminal 4779 chars`: **0.048 s**; 1200 cases 0.50 s; evaluator (`avra run`) 0.54 s | Snapshots cost nothing; compiling dominates |

Friction: `alert "Saved" with {…}` reads `with` on the string, so it is written `(alert "Saved") with {…}`.
Generated code writes the parentheses.

## 7. Cost against the gate budget (each slice < ~12 min; `gate.sh` wall is 900 s)

| Item | Measured | Proposed |
|---|---|---|
| derived + named cases | — | ≈126 |
| drawn in the browser | — | 126 × 4 dials = 504 per engine (gate: Firefox; checks: + WebKit, iPhone) |
| semantic snapshots | 120 cases 0.05 s native, 0.54 s evaluator (P8) | ≈380 texts: < 1 s per engine; the suite's compile ≈ 15–20 s (cold probes ran 15 s) |
| ui-browser slice today | `GATE ui-browser 69ff97ef PASS rows=5 205s` (ui-board 40 s, ui-browser 101 s, board-dev 52 s), run 45495505856 | unchanged |
| storyboard row, estimated | — | page build ≈ 40 s (the board's build) + Firefox ≈ 25 s (one load, 4 dial passes, one `evaluate` each, ≈50 key sequences) ≈ **65–90 s** |
| as its own slice (recommended) | — | ≈ 2.5–3 min with unpack: runs in parallel and fails under its own name |
| folded into ui-browser instead | — | ≈ 205 + 90 ≈ **5 min**, still under 12 |

The browser numbers are estimates from the board's measured rows. The snapshot numbers are measured.

## 8. What it needs that the language lacks (stated generally)

| # | Ask | Today | Needed for |
|---|---|---|---|
| A1 | **A collect projects any declaration it gathers as its compile-time description**, a component as a record type is (`kind: it` → `Type`) | P2: refused for a component, accepted for a `type` | Optional: removes the `@viewed` row; the derive's row works without it |
| A2 | **A build-time law over a settled value**: a const or collection whose check refuses the BUILD, naming what it found (here: a gathered declaration of one kind with no partner of another) | the check is a test (P6) | "one with no story is refused" as a compile error, not a red suite |
| A3 | **A declaration's own source text, at compile time** (`Fn.text`, or `Loc.file` as a readable path) | `f.at` gives `p5/src/button_story.av#801238622:8-53`: a module key, not a path | showing the base's own source; derived cases need nothing |
| A4 | **A value scoped to a subtree** (`ctx theme`, already planned in UI.md) | absent | light and dark side by side on ONE page; two frames until then |

Library work, which is not language: the `@viewed` row in `view.av` (~25 lines, P5), `tree/story.av`
(`@story`, `@case`, the derivation registry), and the gallery's page, dials, snapshot test and the claims
table.

## 9. Rulings asked of the UI lead

1. Is the list "every view the View derive made" (29, with compositions), or only `@View` primitives (25)?
2. `Case` moves down to std-ui (one type), and the gallery reads it?
3. Should the storyboard be its own gate slice (recommended), or a row in ui-browser?
4. RTL: does a node carry `dir` (or `dir="auto"`) from its words? P7 shows it carries none today.
5. `long` is ≈200 characters, and `rtl` is one Arabic phrase: are these fixed data in the dial table's file?

---

## 10. Built

### Slice 1 — the list, the stories, the page (on program `69ff97e`)

| Piece | Where | What it does |
|---|---|---|
| `@viewed` | `std-ui/src/tree/viewed.av`, the View derive (`tree/view.av`'s `view_row`) | a row beside every view the derive makes, primitive or composition; `views` is std-ui's, by `@viewed in package` |
| `@story`, `@case` | `std-ui/src/tree/story.av` | a fn answering a component; the derivation REGISTRY over the member's `Kind`; `stories` gathers this package's |
| fixed data | `std-ui/src/tree/story_text.av`, `std-ui/art/story.svg` | `long_text` (≈200 chars), `unbroken_text` (65 letters, no space, no hyphen), `sample_text`, `story_picture` |
| `Case` | moved to `tree/story.av`; the gallery reads it | one type |
| the page | `std-ui_gallery/src/storyboard.av`, `tools/storyboard` | an index with counts (danger ink for none), a filter, every case in light and dark side by side under `ctx theme`, each case's spelling |

Rulings applied: the list is every view, compositions included (29); a story's fn sits in its
component's file; required text derives `empty`, `long`, `unbroken`; script coverage is one named
`@case("scripts")` on `text` and one on `field`; RTL is not a case (the direction dial is slice 5).

**The registry** (`derived`, one arm per `Kind`, every kind spelled):

| Member | Cases |
|---|---|
| `string`, required | `<m> empty`, `<m> long`, `<m> unbroken` |
| `string` with a default | `<m> given` (the sample) |
| `bool` | flipped from the base (`<m>`, or `not <m>`) |
| a place (`Cell<bool>`, `Cell<string>`) | `<m> given` |
| `bool?`, `string?` | `<m>` (true, the sample) |
| `List<…>` | `<m> empty` |
| a plain enum | `<m> <Variant>`, each but the base's |
| an event, `int`, a record, a fn, … | none: the author names a `@case` |

`@story("chord")` keeps a member fixed (a key's chord is a grammar, not text). A case that draws
exactly what its base draws is set aside by NAME on the page (`drawn as the base: initial`): a
place's seed (`initial`) given after the base was built does not reseed it.

**Counts.** 32 stories (29 bases + `button busy`, `text scripts`, `field scripts`), 124 cases
before the page sets aside the ones drawn as the base. The page says `29 views · 119 cases · 0 with no
story` for std-ui's own stories.

**Refusals**, each spoken once, where the story stands, under the library's kind (fixture
`packages/cli/src/commands/tests/story_refused/`):

```
error[@std/ui:story-answer]: a story's fn answers the component it tells — `tells_a_number` answers `int`
error[@std/ui:story-view]: a story tells a view — `Plain` is no component that draws
error[@std/ui:story-fixed]: `nosuch` names no member of `button`, so there is nothing to keep fixed
error[@std/ui:story-seated]: a story's fn takes no arguments — its base is the one value it answers
error[@std/ui:story-unnamed]: a case is named — `@case` on `names_no_case` names none
```

**Zero cost (ruling a).** The board was built three ways on the same machine, from the tree at
`69ff97e` and from this one: the wasm module, the native server and the native page. Two are
byte-identical and the third is the same size. Nothing an app does not read is carried.

| | `69ff97e` | with 32 stories, 29 rows |
|---|---|---|
| board wasm module | 316,595 B | 316,595 B (identical bytes) |
| board server, `--release` | 3,095,944 B | 3,095,944 B (identical bytes) |
| board page drawer, `--release` | 2,430,784 B | 2,430,784 B |
| `tools/storyboard` wasm module | — | 326,693 B |

**The board's own views (ruling 1, measured before slice 1 lands).** `collect … = @viewed in
package` from a copy of `tools/ui-board` answers `package 12: about bar board board_page filters
footer header new_task tab task_row task_rows toggle`. Every plain composition with a body is
gathered. `in closure` answers 37: the board's 12 plus the 25 primitives its imports reach (the
forms module is not reached, so it is not counted).

**Findings.**
- `avra dev` serves no bundled asset: the page asks `/assets/<digest>.svg` and is answered 404, so
  `icon` and `image` draw no picture under `avra dev`. Their semantic cases are whole.
- A literal instance refuses a value for a place (`type.seat`: "takes a place, and this is a
  value"), while `with` on an instance sets it: the derived `given` cases draw the value given.
- `avra fmt` drops the parentheses in `(a ?? 0) == (b ?? -1)`. That is no parse change: `??` binds
  tighter than `==`, so `a ?? 0 == b ?? -1` reads back as the same expression, the same IR and the
  same answer (`a() ?? 0 == b() ?? -1` over `null` and `0` answers `true`). It is a legibility
  question, since a reader who assumes C#'s precedence would misread it. The refusal first blamed
  on it was the `.length` read through `x?.cases`, which is refused before formatting too.
- Two `std-ui_gallery` tests were red on `69ff97e` (theming added `th-1` to every html); they are
  updated here.

### Slice 1, the UI lead's page fixes

| Ask | Done |
|---|---|
| 1. every frame named and bounded | each frame carries its dial's name over it, and a 4 px band in the dial's `Neutral` tone around the dial's `Canvas`, both in the dial's own theme |
| 2. a narrow frame | the dial table has a `width` column: `Sizing.Fill` (grows to the room the page gives, never past it) and a `narrow` row at `Sizing.Fixed(320)` |
| 3. the page on a phone | an index entry is a button that shows its view alone, under the index; frames stand one a row by default. iPhone 13 (390 px): no sideways scroll once a view's labels fit; a label's unbroken word still widens the page to 558 px with every view shown (frames one a row), and that waits on ruling 2 |
| 4. dials choosable | a checkbox per row of the table, `light` and `dark` first |
| 5. set-aside cases | the index says `dialog 7 +1 aside`, and the tally says `29 views · 119 cases drawn · 5 set aside, drawing exactly what their base draws · 0 with no story` |

**What an alert with no words draws.** Its node is `alert polite` with no text, so its HTML is
`<div aria-live="polite" class="th-1"></div>`. The theme gives `alert` no look (`unstyled`), so it
draws no surface and is zero high. That is right for a live region with nothing to say. The dark
block in the first screenshots was the pane's own padding.

**What the phone needed of the library (the UI lead's rulings).**
- `overflow-wrap:anywhere` on the body was proposed and DROPPED: it lowers every Hug box's least width
  to one character, so a shrinking row could break "Save" mid-word. It returns as its own change,
  with the layout oracle's Firefox result and two claims: an unbroken 60-character token in a 320 px
  frame does not overflow, and a button's label in a too-narrow row never breaks inside a word.
- A field's input is held to its box now (`input:not([type=checkbox]){min-width:0;max-width:100%}`,
  realize/html/css.av). That is containment only; whether a field FILLS its box is the layout study's
  call. A box to tick keeps its size: the first form of the rule shrank a checkbox beside long words
  to 0–3 px, and the `tickable` claim now holds that.
- "A wrapping row whose items hold a least width" is on the layout study's list (ROADMAP, the
  storyboard's asks). "One frame a row" is the interim.
- The seed defect (finding 4) is P1 and routed to the warm lane. The five set-aside cases stay named.

**A place's seed via `with` (finding 4)**, as sent for the ruling, on `69ff97e`:

```avra
use @std.ui.components.{checkbox}
use @std.ui.tree.view.{tree_of}
use @std.ui.tree.outline.{outline}
fn base() -> checkbox { checkbox "Remember me" }
"with:    ${outline(tree_of(base() with { initial: true }))}\nwritten: ${outline(tree_of(checkbox "Remember me" { initial: true }))}\nfield:   ${(base() with { initial: true }).checked}"
```
```
with:    checkbox "Remember me"
written: checkbox "Remember me" checked
field:   false
```
The place is seeded when the VALUE is built: `checked`'s default `self.initial` is read at
construction, so the field already holds `false`, and `with` changes `initial` beside it. By the UI
lead's law (seeded when MOUNTED), this is a model defect (ruled P1).

### Slice 2 — semantic snapshots and coverage, in the gate

| Piece | Where |
|---|---|
| a `Snapshot` per case on three targets: `html` (web), `outline` (headless), `terminal` (80 columns) | `std-ui_gallery/src/gallery.av` (`terminal`, `terminal_width`; the digest folds all three, each text's length leading it) |
| the dial table, as data | `std-ui_gallery/src/storyboard.av`'s `dials`: light, dark, more, large (200 %), narrow (320 px) |
| a sheet snapshot per dial | `sheet_snapshots()`: `worn_by` of the theme under the dial |
| the golden | `src/tests/storyboard_snapshots/`: 124 lines (`view/case digest`, 119 cases + 5 sheets), and two runs give 0 `changed` |
| coverage | `storyboard_test.av`: `untold(shelves(views, stories))` is empty, so a view with no story is named |
| the gate | `tools/gate.sh`'s slice `storyboard`: `test std-ui_gallery`, cold |

Cost: `build/avra test packages/std-ui_gallery`, cold, takes **22 s** here: 47 cases, plus the golden's
program run in both engines (17.8 s of that). That is well under the slice budget. The browser row
(slice 3) joins this slice.

### Slice 3 — the claims, every case under every dial, with the mutant

`tools/storyboard/claims.mjs` (engine-agnostic over `../ui-board`'s page drivers: Firefox by BiDi,
WebKit and Chromium by Playwright) and `tools/storyboard_browser.sh` (the gate's row
`storyboard-browser`, with the same "a run that cannot judge fails" contract as the board's).

**Every event a story's base declares is heard.** `@story` wires each event member of the base to
`heard("<view>.<event>")` (an event whose seat names a type parameter is left as written), and the
page draws `heard: button.press 2 · …`. A gesture's claim reads that line before and after.

| Family | Holds, of every frame (585 = 117 cases × 5 dials) | Mutant that must fail it |
|---|---|---|
| named | every control is named (label, words, aria-label) | every button's words and label emptied |
| legible | words 4.5:1 against what they stand on, 3:1 if large; a disabled control owes nothing | every word grey on white |
| contained | nothing stands past the frame, as wide as its dial holds it | a 2000 px box in every frame |
| input-held | a field's input stands inside its frame | `min-width: 2000px` on inputs |
| tickable | a box to tick is ≥ 10 px wide | checkboxes at 0 px |
| reachable | an enabled control drawn takes the focus and is in the key order; a disabled one does not | `tabindex=-1` everywhere |
| scheme | each case's canvas AND the surface under it are darker under `dark` than under `light` (luminance) | every canvas white |
| operable | Enter, Space, a letter or → on the case's own control is heard exactly once (0 when disabled), and a ticked box or a typed letter reads back from what is drawn | every gesture stopped at the window |
| touched | (with a phone device) a tap is heard exactly once | — |

**Run here** (Chromium 1280×900; Firefox and WebKit are not on this machine): 585 frames, 62
failures, all pinned (`tools/storyboard/pinned.txt`, each with what it waits on), and every mutant
caught (95 to 1152 times each). 47 s for the claims, 50 s for the row with `avra dev`'s build.

**What the claims found**, pinned until ruled:
- A control with an empty label has no name at all (button, checkbox, field, link, slider, switch).
- `error_text` in the Disabled ink (3.45:1) and the Border ink (1.45:1) — the UI lead's text-ink ruling.
- A label's unbroken word widens its inline-flex box past a 320 px frame (checkbox, field, progress,
  slider, switch, fieldset's legend), and pushes a field's input out. This is ruling 2's ground.
- A `fieldset` stands 13 px past a 320 px frame whatever its legend: the engine's own least width
  for a fieldset. New.

**Touch** is wired but NOT in the gate yet. On a phone the page still overflows sideways (the
unbroken labels above), the engine zooms out, and a tap lands where the layout says it is not. With
the page held to one view that does not overflow (`--view button`), every tap is heard once. It joins
the checks' WebKit (iPhone) run once the page cannot overflow (ruling 2).

**Zero cost holds**: the board's wasm module and native server are unchanged by the stories and
their wiring (316,595 B and 3,095,944 B with the input rule left out). The input rule itself costs
the board +149 B of wasm and the page drawer +240 B.

### Landing slices 1–3, on program `b6dce5f2`

The nine commits were rebased onto `b6dce5f2` (the deletion). `tools/gate.sh` keeps HEAD's
`findings-a` line and comment, with the storyboard's line and `slice_storyboard()` beside them. The
gate's `storyboard` slice runs the claims in FIREFOX, which is how the Firefox path is verified: this
machine has only Chromium.

| Ruling | Done |
|---|---|
| (4) no least width from an engine's legacy default | `fieldset{min-width:0}` in the web realizer; `contained` holds for every fieldset case but the unbroken legend (ruling 2's) |
| Disabled exempt from legibility, as data | the claims table's `inactive` list: `:disabled`, `[aria-disabled=true]`, `.color-disabled` (words in the theme's disabled ink); the `ink Disabled` pin is gone |
| a baseline that only shrinks | `tools/storyboard/pinned.txt`: each line `<family> <view>/<case>/[dial] — why — waits on: <ruling>`, and `# at most 17`. The claims refuse a stale pin, a line with no reason or no ruling, and more lines than the ceiling |
| the page shows a pinned case as pinned | `tools/storyboard` embeds the baseline (`pins_of`); each pinned case says `pinned: <family> — <why> — waits on <ruling>` in the warning ink |
| the image cases stay pinned | a new family, `pictured`: every picture a frame draws has drawn. Its mutant puts a missing picture in every frame. The icon and image cases are pinned on lowering-quality's P1 (a bundled picture traps in wasm). On `b6dce5f2`, `avra dev` still answers the asset 404 |

**Terminal goldens did not move.** No `.expected` under `realize/tui` or the terminal program
tests changed: `scale`, `screen`, `contained_terminal`, `instance_terminal`, `terminal`,
`terminal_timer` and `terminal_window` all read `eval == native == expected`. The storyboard golden's
80-column drawings also held.

**Byte goldens that did move,** both from the web realizer's base rules (the input rule and the
fieldset rule together): wire 3539 → 3616 and mount 3721 → 3798 octets on the first frame.

**Run here** (Chromium; the gate's Firefox is the verdict): 585 frames, 76 failures, all under the
17 pins; every family's mutant caught (35–1110 times). std-ui 1058/1058 with all 87 program proofs;
std-ui_gallery 50/50 with the golden.

**A Mac compiler of this head** cannot be made here (a Linux container, with no macOS SDK or
toolchain). On a Mac, `make bootstrap` from the landed head builds it, or the pipeline's own build
once this lands.

### The first Firefox run, and what it changed

The gate's first Firefox run (train22) failed the storyboard row on two STALE pins. On d7cd84d9,
`avra dev` serves the bundled picture and Firefox draws it, so `pictured icon/` and `pictured image/`
fail no more, and the baseline falls to `# at most 15`. Every other failure was pinned. The summary
read `fail` for a family whose failures were all pinned, and that hid the real cause, so a family now
reads `ok`, `pinned` (n failures, each on its ruling) or `FAIL`. Firefox 158 here: 585 frames, 51
failures, all pinned, every mutant caught, exit 0 (86 s with the mutants).

### Ruling (1), a control always has a name (avra-8sb5.109.9)

| Part | Done |
|---|---|
| a computed empty name is a `ui:` dev warning | `tree/named.av`: `names_itself` (a registry over `Prim`: button, link, field, checkbox, switch, slider) and `nameless(tree)`; the app's paint says each once: "a `button` is drawn with no words, and a control's words are its name: give it a label that is not empty" (`tree/tests/named_test.av`) |
| the registry derives no `empty` case for a control's name | a text member's `empty` case is dropped where it would draw a control with no words, judged on the drawn node, not on the member's spelling: the six controls lose `label empty`, while dialog, card, alert and spinner keep theirs (124 → 118 cases; the golden loses exactly those six lines) |
| a LITERAL `""` refused where written | built as each control's `fn check()` and NOT landed. A component that has a `check` loses its row `key` to the repeated-rows law (`features/repeated.av`'s `rows_under` reads `store.walked(e)`, which answers the judged form). Repro and route sent to the lead |
| the six `named` pins | gone; the baseline is `# at most 9` |

### Ruling (2), text takes an ink subset (avra-8sb5.109.13): how ink reaches words

| Seat | What it inks | Today |
|---|---|---|
| `Style.color: Ink?` (style/style.av) | the words of any primitive | all ten inks |
| `Wear.ink: Ink?` (style/look.av) | a theme's default words for a primitive | all ten |
| `error_text.ink: Ink = .Danger` (`@style(color)`, laid over `Style.color`) | its message | all ten, and the derivation draws each |
| `Wear.line: Ink?` (style/look.av) | a primitive's line: a field's edge (`.Field`), a border, the focus ring | all ten; this is where Border, Field and Focus belong |

So the subset is the inks WORDS wear: `Style.color`, `Wear.ink` and `error_text.ink` take it, and
`Wear.line` keeps the whole `Ink`. Proposed spelling for the warm lane: name the subset over the one
enum, so no variant is copied and a value stays an `Ink` (no conversion, one `color_word` table):
`alias Words = Ink.{Text, Muted, Disabled, Danger, Success, Warning, Link}`. A seat of `Words`
refuses a literal outside it; a computed `Ink` crosses by a match. The derivation's enum rule reads
the subset's variants once `type_named` answers them for such an alias, so `error_text`'s `ink
Border/Field/Focus` cases go and the last `legible` pin goes with them. Disabled is exempt from
legibility as data already (`inactive` in the claims table).

**A finding on the way:** after an edit to the story generator, `check` and `avra dev` trapped with
`index 19 is out of bounds (length 15)` until the packages' `.avra-cache` was emptied. A store entry
made under the old generator's shape was read under the new one.
