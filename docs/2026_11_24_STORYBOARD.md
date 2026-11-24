# The storyboard — phase 1 design proposal

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
