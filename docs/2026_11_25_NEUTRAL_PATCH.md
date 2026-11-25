# One differ, many targets — proposal (iOS spike)

**The question:** how can ONE differ serve both the web and a native host, without the web paying anything for it?

**Short answer:** the lean holds, with two corrections.

1. **Element ids cannot equal Node ids.** A `Node` has no id. Ids are minted by the differ (`Diffed.next`) when an element is first placed. What a 1:1 native lowering gives instead is **structural identity**: one element per Node, standing at the Node's own step (`Box.stand()`). A `Placed` box, which follows the Node tree, then lines up with the element tree by path. That is enough for the solver, but it is a correspondence by path, not by number.
2. **"Chosen" is not data on the board's Node.** std-ui has `Attribute.Selected`, which the web writes as `aria-selected`. The board's `tab` never sets it: it marks the chosen tab only with `tab_style(on)`, a fill (`tools/ui-board/src/board.av:172`). A native host can only draw "chosen" as data once the component says it, which is a change to the board (or to a std-ui tab component), not to the differ.

## Probes (gap-2 compiler at `build/avra`, files in /tmp/probe)

| Probe | What it asks | Output |
|---|---|---|
| p1 | trait `Elem { fn id() -> int; fn kids() -> List<Self> }`, an unbounded `type Differ<E>`, free fns `fn count<E: Elem>(xs: List<E>)` | `2 1`: works |
| p2 | `type Live<E: Elem> = {…}` | `error[parse.expected]: expected '=' while parsing 'stmt'` |
| p3 | `impl Differ<E> { fn ids() { … x.id() … } }` | `error[type.method]: 'E' has no known methods` |
| p4 | the same impl, with the bound on the method's own parameter: `fn ids<F: Elem>(xs: List<F>)` | `1`: works |
| p5 | `enum Kind { Html(tag: string), Prim(p: int) }` as a field, matched | `2`: works |

So option (i), a generic differ, can be spelled today, but only as free functions or as a type parameter on every method. `Differ`'s 10 methods and `Live`'s 25 would each carry `<E: Elem>`. No associated types are needed. Option (ii), one `Element` whose kind is a sum, needs nothing new.

## 1. Algorithm versus HTML vocabulary (by function; line counts are ranges)

| File (lines) | ALGORITHM, target-neutral in shape | HTML VOCABULARY |
|---|---|---|
| `patch.av` (486) | `Stands`, `standing_at`, `found`, `places` (StepTable), `pair_off`, `matched`, `marked`, `first_not_before`, `still` (keyed matching and the longest stable run): 212–316, about 105 lines. `Differ.siblings`, `drawn`, `made`, `say`, `later`, `diff`, `hearing`: 321–410 and 466–481, about 110 lines. | `Patch` variants `SetAttr`/`DropAttr`/`SetProp`/`Style`/`Call`/`SetVar`/`DropVar`/`Adopt`, typed by `HtmlAttrName`, `HtmlTag`, `css` (23–39). `Says`/`Listening`/`Heard`/`Held`/`shut_by`/`read_from`/`rest_of`/`property`/`door`, which say which `HtmlAttrName` a control's value is read from or shuts (41–185, about 145 lines). `attributes`, `variables`, `properties`, `doors` (414–465). |
| `live.av` (400) | `Bound`, `fire`/`hear`/`keep` (the identity of whoever hears), `owners`, the paint/turn plumbing (`patches`, `patches_drawn`, `drawn_turn`, `exactly`, `exact_turn`), `synced` | `lowered_on` (the HTML lowering), `rules_of_notice` (CSS rules), `restyled`/`adopted`/`adopt`/`take_over` (a page's sheet and adoption), `said`/`paint` → `frame` (the wire) |
| `element.av` (365) | `lower`/`lower_each`/`seat_of`/`stepped` (walking the Node tree, steps and crowding) | `Tagged.tag: HtmlTag`, `attrs: List<HtmlAttr>`, `vars: List<CssVar>`, `wrote` (Attribute → aria/HTML), `labelled` (label + span + input), `headings` (Card → h2, Fieldset → legend), `said_of` (words as a child run), `class_attrs`/`node_attrs` (style → class words) |
| `exact.av` (267) | watching cells, recomputing a reading, `structural_cells`, `opaque_*` | `words_host`/`named_host`: they assume the words sit in a child Text run (or a labelled span), and `says: List<HtmlAttrName>` repeats them in `aria-label` |

**The split:** the matching core (Step-keyed pairing, stable runs, minting ids, hearing) is about 215 lines and already neutral in shape. It is typed over `Element`, and it reads only `seat()`, `id()`, `kids`, `hears`, and the attribute and property lists as opaque pairs. Everything HTML-specific is the element's CONTENTS and the `Patch` variants that carry them.

## 2. The 24 Prims: web lowering and native element

Rows marked **✱** do not lower to one element on the web.

| Prim | Web lowering today | Native element (lean) |
|---|---|---|
| Text ✱ | `span` + a child text run | text (words as an attribute) |
| Heading ✱ | `h1`–`h6` (from `Level`) + a run | heading(rank) |
| Button ✱ | `button type=button\|submit` + a run | button(words, submits) |
| Link ✱ | `a href` + a run | link(href, words) |
| Image | `img` (void); children become siblings | image(source, alt) |
| Icon | `img` (void), as Image | icon |
| Field ✱ | `label` ⟨`span` words, `input type=text\|password`⟩ | field(label, value, placeholder, masked) |
| Checkbox ✱ | `label` ⟨`input type=checkbox`, `span`⟩ | checkbox(label, checked) |
| Switch ✱ | `label` ⟨`input type=checkbox role=switch`, `span`⟩ | switch(label, on) |
| Slider ✱ | `label` ⟨`span`, `input type=range` min/max⟩ | slider(label, value, min, max) |
| Progress ✱ | `label` ⟨`span`, `progress max value`⟩ | progress(label, amount, max) |
| Row | `div` + class `dir-row` | row (direction as data) |
| Column | `div` + class `dir-col` | column |
| Surface | `div` | surface |
| Alert | `div` + `aria-live` | alert(urgency) |
| Spinner | `div` | spinner |
| List | `ul` | list |
| Item | `li` | item(placed at/of) |
| Card ✱ | `article` + an `h2` title child | card(title) |
| Fieldset ✱ | `fieldset` + a `legend` child | fieldset(title) |
| Dialog ✱ | `dialog closedby=any` + a run, opened by `Call showModal` | dialog(open, title) |
| Divider | `hr` (void); children become siblings | divider |
| Form | `form` | form |
| Key | `div hidden data-chord=…` | key(chord), not drawn |

**Native rule:** one element per Node, its `Attribute`s kept as they are (typed, not strings), its words an attribute, its children inside it.

## 3. Style and state on the Node, before lowering

- **Style:** `Node.box.style: Style { radius, fill: Tone, color: Ink, elevation: Level, face, text_size, line_height, tracking, states }` and `Node.box.layout: Layout { direction: Axis, wrap, gap: Size, pad: Edge, margin, align, distribute, width, height, grow, aspect, inset, order }` (`style/style.av:27`, `style/layout.av:36`). The web flattens these into class words in `class_attrs` (`fill-<tone>`, `gap-<z>`, …), and the sheet maps them to `light-dark()` variables (`realize/html/css.av`). The spike's `frame.av` rebuilds these roles by parsing the class words. A native lowering would read `Style` and `Layout` directly.
- **State** is in `Attribute`: `Disabled(flag)`, `Selected(flag)` (the web's `aria-selected`), `Invalid(flag)` (`aria-invalid`), `Loading(flag)` (`aria-busy`; "busy"), `Checked`, `Open`. There is no separate "chosen": a component either sets `Selected` or styles a fill, and the board styles.

## 4. Theme, appearance, text size, contrast

- `Env` (`env.av`) holds only `direction` and `locale`, and nothing sets it on the web beyond its defaults.
- The theme is NOT in `Env`. The root `Node.theme: Stamp { theme: Theme }` carries it, with `Theme.mode: Mode` (`.System` or dark/light) and `contrast: Contrast` (`.System`/`.More`) (`style/theme.av:19,74`). The board sets `ctx theme = ctx.theme with { mode: if dark { .Dark } else { .System } }`.
- **On the web** the program never learns the device's appearance: `light-dark()` and media queries resolve it inside the browser. In the spike, switching the simulator to dark sent no frame at all.
- **Native lean:** the frame carries `theme.mode` and `contrast` as data. The host maps `.System` to UIKit following the device, and forced Dark/Light to `overrideUserInterfaceStyle`. Dynamic Type and Increase Contrast stay the host's job unless the program must reflow; if it must, they are an `Env` field the host sets (an ask, below).

## 5. Events

`Patch.Listen(id, to: Listening)`:
- **Neutral already:** `Listening.action: Action { seat: Seat, handler }`; the seat is a typed slot (`row_at(seat).prim`, which the spike already reads). The answer path, `fire(id, seat, Said?)` with `Said = Text | Flag | Number`, is neutral too.
- **HTML-typed:** `reads: HtmlAttrName?` (the property the value is read from) and `shuts` (the attribute a dialog's dismissal clears), plus `web_event(seat)`, which filters which seats a page hears. A native target needs `reads` as a role ("value", "checked") or not at all, because the host knows its own control's value.

## 6. The exact path and placement

- `exact.av` assumes the HTML shape. Words are a child `Text` run (`words_host`), possibly inside a labelled `span`, and the patch it says is `SetText(run_id)`. Under a native element whose words are an attribute, the exact path would say "words of `id`" instead: a `SetWords(id, text)`, or `SetText` aimed at the element itself.
- The `Placed` type in `exact.av` (readings) is unrelated to `place/`'s `Placed` (boxes): same name, two concepts.
- `place/` itself is neutral and walks the Node tree.

## 7. What frame.av becomes, and what SwiftUI reads

Under the lean, `frame.av` stops reconstructing prims from tags and roles from classes. It becomes a serializer of a native `Patch` stream: create(id, prim), set(id, attribute), role(id, style/layout field), place, remove, listen(id, seat), plus `rect(id, x, y, w, h)` once the solver runs. The SwiftUI twin (slice 3) reads the same stream into an observable model keyed by id: each element is a struct of prim + attributes + roles + children, and SwiftUI views switch on prim. The SwiftUI side does no diffing, only patch application.

## Option (i) versus option (ii), and the web's cost

| | (i) differ generic over `E: Elem` | (ii) one `Element`, kind and attribute name as sums |
|---|---|---|
| Spellable today | yes, with a bound on every method (p2–p4) | yes (p5) |
| Change size | `patch.av` + `live.av` + `exact.av`: every fn gains `<E: Elem>`, and `Live` splits into a generic core plus a web shell | `Tagged.tag: HtmlTag` → `Kind`, `HtmlAttr.name` → `AttrName = Html(HtmlAttrName) \| Role(Role)`; the matcher is untouched |
| Web pays | nothing at runtime after monomorphisation; compile time grows | a payload enum where a plain tag was: one box per element and per attribute, plus a match per compare. **The web pays.** |
| Wire safety | by type: the web's wire only ever sees `Html` | by a runtime refusal in each wire |

**Recommendation: (i).** It is the one where the web pays nothing. It is larger to write, but mechanical: the matcher (about 215 lines) moves first, behind a trait of exactly what it reads (`seat`, `id`, `kids`, `hears`, an opaque attribute compare). Witness: every existing wire golden and `realize/dom/tests` byte-identical, `make census` counts unchanged on the board's paint, and the `exact_counts` answered/declined numbers unchanged on the web fixtures.

## 8. Order, each step leaving the web's goldens byte-identical

1. Extract the matcher from `patch.av` (Stands…still, siblings, made, drawn) into `realize/diff/` behind `trait Diffable`; `Tagged` implements it. Web goldens unchanged.
2. Make `Patch` generic over its payload (`Patch<A>`: Create/Place/Remove/Listen/Text neutral, attribute and style variants carrying `A`). The web is `Patch<HtmlPatch>`, the wire unchanged.
3. Add `realize/native/`: `lower(n: Node) -> NativeElement` (one per Node, attributes typed, style and layout as roles, theme mode as data) and `NativePatch`. The spike's `frame.av` serializes it.
4. Teach the exact path a words-on-the-element host (`SetWords`).
5. Add placement: `place(root, measure, width)` over the same Node; rects keyed by the native element's path, which is 1:1 with the Node.

**Prototype first on this branch:** step 3 alone, as spike code outside std-ui. It is a native lowering plus a hand-written diff over Node pairs (by step), feeding `frame.av`. That unblocks the solver (step 5) without touching std-ui, and measures how much of the matcher a native element really needs before step 1 is cut.

## 9. Asks for a ruling

1. Option (i), the generic differ with per-method bounds, over (ii), the sum kind, because (ii) costs the web a box per element. Or rule that std-ui wants bounds on a type's own parameters (`type Live<E: Elem>`, today a parse error) first; that would make (i) much smaller.
2. "Chosen" as data: should the board's (or a std-ui) `tab` set `Attribute.Selected`, so every target reads it rather than a fill?
3. A native lowering keeps ONE element per Prim, including Field, Progress, Card and Fieldset (no label/legend children). Agreed?
4. Theme mode and contrast travel in the native frame; device appearance stays the host's own; Dynamic Type is an `Env` field only if the program must reflow. Agreed?
5. `Listening.reads`/`shuts` become target-supplied (HTML names for the web, none for native). Agreed?
6. Rename the exact path's `Placed` (readings) to free the name for `place/`'s boxes?
7. May I prototype step 3 (native lowering + a Node-pair diff) as spike code on `ios-spike`, outside std-ui?
