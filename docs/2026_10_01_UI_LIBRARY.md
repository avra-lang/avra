# `@std/ui` — the library, properly

> Design charter, 2026-10-01. For owner review.
> Companions: `2026_09_29_UI.md` (the program and the platform),
> `2026_09_29_WEB_UI.md` (the web constitution), `LIBRARIES.md` (how
> any Avra library is built). This document is the LIBRARY: its
> layers, its component contract, its taxonomy, its quality bars, and
> its build order. It is written to the standard of Material 3,
> Fluent 2, SwiftUI, Radix and Flutter — taking what each does best
> and refusing what Avra can do better.

## 0. The bar — what makes this not a toy

A toy has: a dozen components, one theme, hard-coded colors, no
layout worth the name, accessibility as an afterthought, no state, no
forms, no overlays, no adaptation, no tests, no story for a real app.

This library must have, before it is called done:

- **Every component a real product needs**, not every component a
  demo needs (the taxonomy in §7), each with variants, sizes, states
  and an accessibility contract.
- **A real theme system**: primitives → semantic roles → component
  tokens; light/dark/high-contrast; density; brand from one seed;
  contrast guaranteed at the token level, not eyeballed.
- **A real layout system**: flex and grid, hug/fill/fixed sizing,
  alignment and distribution, wrapping, scrolling, safe areas,
  left-to-right and right-to-left, responsive by size class.
- **Interaction**: focus, keyboard, pointer and gesture events;
  overlays and layers with focus trapping and dismissal; forms with
  validation and error display; async with pending/failed/empty.
- **Data**: bound to `state`, `@model` and live queries, not bolted on.
- **Accessibility as a subsystem**, with obligations enforced where
  they can be — some at compile time.
- **Many targets**: web (SSR + live), terminal, native, test, and an
  inspector, from one tree.
- **Provenance**: every node knows where it came from, so diagnostics,
  the inspector, hot reload, tests and agents all point home.
- **Extensibility**: compose new components from primitives; new
  targets are new directories; a versioned, closed primitive set.
- **Proof**: geometry equivalence across layout engines, snapshot and
  keyboard traces, byte and frame budgets, adversarial tests.

## 1. Principles

Echoing Avra's, with library teeth:

1. **The component is the node.** A component's fields are its props,
   its schema, its docs and its accessibility contract. No parallel
   `Node`, no `Role` payload enum, no `XProps` beside `X`.
2. **Semantics, never pixels.** A component names an interaction
   contract; a target draws it. `button` is not a rectangle.
3. **Data is data.** Tokens, themes, palettes, breakpoints, icon
   names and catalogues are values (consts, `embed`), never logic.
4. **Contracts are traits; extension is composition.** What several
   implementations must satisfy is a trait; a new component is a
   composition of primitives, never an edit to a central enum.
5. **One definition per idea.** Shared settings are one record spread
   into every component; a component family's variants are one enum.
6. **Everything is inspectable.** Every node carries its origin; the
   tree, its styles, its layout and its actions are data a tool can
   read.
7. **Accessible by construction.** The default is the accessible
   control; a generic clickable surface is visibly expensive.
8. **Idiomatic or it waits.** When the idiomatic form does not compile
   we file the language ask and design it — never ship the workaround.
9. **A fixed substrate, an open surface.** The data — component
   records, `Style`/`Layout`/`Name`, the environment, a component
   block's settings — is fixed and machine-readable; the surface a
   person writes (chaining, `if` values, slots, environment, sugar) is
   open. One substrate, many projections.
10. **Settings ARE the surface.** A component's `key: value` settings
    are its style, layout and a11y, and chaining is their projection:
    `text("hi").pad(.S)` and `text("hi") { pad: .S }` are the same
    fields, never a second mechanism.

## 2. The layers and their seams

Ten layers. Each seam states what crosses it, what owns the one
definition, and how it grows.

```
  program        view · state · action · @model            (UI.md)
     │  semantics
  components     text · button · column · field · dialog …  (§6–7)
     │  look + layout + a11y + events, all data
  style/layout   Style · Layout · Name  (per-instance)       (§4–5)
     │  token names
  theme          semantic roles, modes, density, motion      (§3)
     │  primitive values
  tokens         scales: space · radius · type · colour · time
     │  the visitor draws
  realizers      Html · Tui · Dom · Test · Describe · UIKit …
     │  target output
  targets        one directory each; capability matrix       (§11)
```

- **Component → style/layout/a11y**: typed, optional, token-valued
  records. Crossing is a value; nothing target-specific crosses.
- **Style → theme**: token *names* cross; the theme resolves them.
  No realizer holds a value, and no component holds a colour.
- **Theme → tokens**: the theme is data (records + a default const);
  a user replaces it whole. Primitives are the only raw numbers.
- **Component → realizer**: the visitor (`Realizer`, one method per
  component). The target owns its output type behind a `Cell`
  accumulator. A target missing a component fails to compile.
- **Realizer → target**: a target is a directory implementing the
  visitor; its capability matrix says what it can draw and its refusal
  names what it cannot.

Each seam has ONE definition. A second spelling of a concept (a
`Node` beside a component, a colour in a component, a target check in
a component) is a defect.

## 3. Tokens and theming

Three tiers, one direction:

1. **Primitives** — the raw scales. Never used by a component.
   - `space` (0,2,4,8,12,16,24,32,48,64), `radius`, `border`
   - `font_size`, `line_height`, `weight`, `tracking`
   - `duration` (instant/fast/normal/slow), `ease` (standard/decel/
     accel/spring)
   - `z` (base/raised/overlay/modal/toast/tooltip)
   - `breakpoint` (compact/medium/expanded), `density`
   - `elevation` (0–5)
2. **Semantic roles** — what a component names.
   - colour: `primary`, `on_primary`, `primary_container`,
     `on_primary_container`, `surface`, `on_surface`,
     `surface_variant`, `outline`, `error`, `warning`, `success`,
     `info`, `scrim`, and their `_hover`/`_pressed`/`_disabled` states.
   - type: `display`, `headline`, `title`, `body`, `label`, each
     `large`/`medium`/`small`.
   - `surface` roles carry elevation; `interactive` roles carry the
     five control states.
3. **Component tokens** — a component may name a role as its default
   (`button`'s fill is `primary`), so a theme can retune one component
   without touching the rest.

`Theme` is one record of these tables plus `mode`, `density` and
`platform`. A default ships; a user replaces it whole. DTCG/Figma
tokens import through `embed` into the same record.

**Contrast is a token guarantee, not a review.** A `Theme` is checked
when it is made: every `on_X`/`X` pair must meet the profile's ratio
(AA normal text 4.5, large 3.0, non-text 3.0) and a check names the
failing pair. **Brand from one seed**: a tonal-palette generator
(Material's HCT-class, our own implementation) turns a seed colour
into every role for light and dark; this is a sub-project of its own,
flagged in §17.

## 4. Style

`Style` is what a component instance was given: typed, optional,
token-valued. Absent means "not given" — never "given the default"
(the `null`/`.None` distinction is a pinned law).

```avra
export type Style = {
    radius: Size? = null
    fill: Tone? = null
    color: Tone? = null
    border: Border? = null
    elevation: Level? = null
    face: Font? = null
    text_size: TypeSize? = null
    line_height: LineHeight? = null
    tracking: Tracking? = null
    opacity: Percent? = null
}
```

Geometry (gap, padding, width, grow, alignment) is `Layout`'s, never
`Style`'s — one home per idea.

A `Style` merges by field; a component's default style is a const it
can name. Style never holds a color or a length — only a token.

**Settings are the surface.** A component's shared settings are the
`style`/`layout`/`a11y` records; a flat body key (`color: .Muted`) and
a chain (`text("hi").color(.Muted)`) are sugar over those same fields,
so there is one representation and no drift. **State and capability
are VALUES**, read by `if`: `fill: if pressed { .SurfaceSunk } else {
.Surface }`, `if hovered`, `if compact`, `if platform is .ios`
(UI.md §15), lowered to CSS or traits where the target can — never a
hidden style layer a target cannot see.

## 4a. Interaction states

A component may look different while a platform interaction state holds:
`Hover`, `Focus`, `Pressed`, `Disabled`. The override is DATA on the
`Style` in the node (`Style.states: List<StateStyle>`), and each target
maps it to its own mechanism — CSS `:hover`/`:focus-visible`/`:active` on
web (no script), native highlight/focus state elsewhere. A state is never
written back to app state; the realizer tracks it.

The first spelling is the data form:

```avra
button("Buy") {
    style: Style {
        fill: .Primary,
        states: [
            StateStyle { state: .Hover, style: Style { fill: .PrimaryHover } },
            StateStyle { state: .Pressed, style: Style { fill: .PrimaryPressed } },
        ],
    }
}
```

A `hover { … }` block is SUGAR over the same list and is filed in the
sugar backlog (epic `avra-8sb5.10`) with the component state-style
spelling as its wanting site; it lands only if the data form proves
insufficient.

## 5. Layout

One semantics, two engines (UI.md §4.3): the browser's flex/grid on
web, ONE Avra engine (over Yoga/Taffy first) elsewhere. The library
exposes the same vocabulary everywhere.

```avra
export type Layout = {
    direction: Axis? = null          // Row | Column
    wrap: Wrap? = null
    gap: Size? = null
    pad: Edge? = null
    align: Align? = null             // cross axis
    distribute: Distribute? = null   // main axis
    width: Sizing? = null
    height: Sizing? = null
    grow: int = 0                    // flex weight
    aspect: Ratio? = null
    inset: Edge? = null              // safe areas
    order: int = 0
}

export enum Sizing { Hug, Fill, Fixed(int), Percent(float) }
export enum Align { Start, Center, End, Stretch, Baseline }
export enum Distribute { Start, Center, End, SpaceBetween, SpaceAround, SpaceEvenly }
```

- `row`/`column`/`stack` are flex containers; `grid` adds columns,
  spans and gap; `scroll` adds an axis and clipping; `spacer` grows.
- **Responsive** is a size class (`compact`/`medium`/`expanded`) and
  a breakpoint table; a view selects a layout by class, not by width
  arithmetic in user code.
- **RTL** mirrors logical edges (`start`/`end`, `Edge` is logical),
  never physical `left`/`right`.
- **Geometry equivalence** between engines is a test over the gallery
  corpus within a stated tolerance.

## 6. The component contract

Every component is a `component` type whose fields come from **shared
groups** (spread) plus its own content. This is the single most
important structural rule: it makes every component consistent,
documented and checkable in one shape.

```avra
/// The groups every component shares, spread in so there is ONE
/// definition per concern (LIBRARIES rule 2).
export type Look = { style: Style = Style {} }
export type Placed = { layout: Layout = Layout {} }
export type Named = { a11y: Name = Name {} }
export type Keyed = { key: string? = null }

/// …or one box they all spread, which is what components write.
export type Box = { ..Look, ..Placed, ..Named, ..Keyed }

export component button(label: string) {
    ..Box
    kind: Kind = .Filled
    size: ControlSize = .Medium
    icon: Icon? = null
    trailing: Icon? = null
    on_press: Action? = null
    disabled: bool = false
    loading: bool = false
}
```

Rules of the contract:

- **Content comes first** in the head and is required where a
  component cannot exist without it (`button(label)`, `image(src)`).
- **Variants are one enum per family** (`Kind`, `ControlSize`), never
  booleans multiplying into states. A variant that cannot be realized
  by a target is refused for that target.
- **States are universal** and separate from variants: the library
  defines `ControlState` (`Enabled`, `Hover`, `Focus`, `Pressed`,
  `Disabled`, `Loading`, `Selected`, `Invalid`), a target maps states
  to visuals, and `disabled`/`loading` on the component feed it.
- **Events are actions**: a component carries `on_<event>: Action?`
  (one action, every door — UI.md §3.7); a target wires the platform
  event to it.
- **Children** are `items: List<dyn View>` on containers only; how
  they are laid out is the container's field, never a wrapper node.
- **A11y is a field, not a wrapper**: the `a11y: Name` group; a
  component whose name cannot be derived (an icon button with no
  label) carries a required rule and is refused at compile time when
  unnamed.
- **The doc is in the component**: each component's doc states its
  semantics, its a11y contract, its states, and what each target does
  — the doc IS the catalogue entry.

### 6.1 Settings, chaining, values

A component's shared settings live in three records — `style`,
`layout`, `a11y` — beside its own content props. The records are the
substrate (data a tool reads, a value you can name and reuse); the
flat and chained forms are sugar over the same fields, so there is
one representation and no drift:

```avra
// the substrate — grouped records, machine-readable
text("hi") {
    style: Style { color: .Muted, face: .Mono }
    layout: Layout { pad: Edge.around(.M) }
}

// sugar A — a flat setting in the body routes to its group
// (a component-grammar ask; wantingsite: every component)
text("hi") { color: .Muted, pad: .M }

// sugar B — chaining projects the same fields
text("hi").color(.Muted).pad(.M)

// a named, reusable setting
export const card = Style { pad: Edge.around(.M), radius: .M, fill: .SurfaceRaised }

// state and capability are values, not modifier stacks
row {
    style: Style { fill: if pressed { .SurfaceSunk } else { .SurfaceRaised } }
    if compact { text "…" }
}
```

The three sugars (flat keys, chaining, value spread) are language
asks in the ROADMAP backlog, each named by its wanting site; the
substrate is what ships first, so the sugar never becomes a second
mechanism.

### 6.2 Environment — context that flows down

What a subtree shares is provided once and read below, never threaded
through every level (WEB_UI §5.3):

```avra
provide theme: Theme = brand
view toolbar() {
    let t = env Theme
    row { text("Hi").color(t.color.muted) }
}
```

A `provide`/`env` pair carries VALUES and ACTIONS (`dismiss`,
`open_url`, `refresh`, a focus handle); a missing provider is a
compile error in the static case, a listed runtime lookup where
composition is dynamic. The library provides its own defaults —
theme, density, direction, locale, size class — so `env Theme` always
resolves, and a user key is declared once and typed.

Because the environment is inherited, theming, density, direction,
locale and size class stay flexible without prop-drilling, and a
target reads the same environment the library does.

## 7. The component taxonomy

Grouped by function. **Core** means it ships before the library is
"Material-class"; **composition** means it is built from core pieces
and may live in a companion package.

| Group | Core | Composition / later |
|---|---|---|
| **Text & content** | `text`, `heading`, `paragraph`, `label`, `code`, `icon`, `image`, `avatar`, `badge`, `chip`, `divider` | rich text, markdown, table of contents |
| **Actions** | `button`, `icon_button`, `link`, `fab`, `segmented`, `menu_button` | split button, speed dial, command bar |
| **Selection & input** | `checkbox`, `radio`, `switch`, `slider`, `range`, `stepper`, `field` (text), `textarea`, `search`, `picker` (select), `combobox`, `otp`, `date_picker`, `time_picker` | color picker, file upload, masked input, mention, rich editor |
| **Collections & data** | `list`, `item`, `section`, `table`, `card`, `accordion`, `tabs`, `tree` | data grid (paging/sorting), virtualized list, carousel, timeline, kanban |
| **Navigation** | `app_bar`, `toolbar`, `bottom_nav`, `nav_rail`, `breadcrumb`, `pagination`, `stepper` (wizard), `menu`, `sidebar` | command palette, split view, tabs-as-route (routes do this) |
| **Structure** | `column`, `row`, `stack`, `grid`, `scroll`, `spacer`, `surface`, `section`, `aspect`, `safe_area` | masonry, portal, z_stack |
| **Overlays & layers** | `dialog`, `sheet`, `popover`, `menu`, `tooltip`, `toast`, `banner` | hover card, context menu, command menu, coach mark |
| **Feedback & state** | `progress` (linear/circular), `spinner`, `skeleton`, `empty`, `error_state`, `alert`, `status` | notification center, inline validation summary |
| **Forms** | `form`, `fieldset`, `field_row`, `error_text`, `help_text` | multi-step wizard, dynamic form from schema |
| **Media** | `canvas`, `video`, `image_zoom` | maps, charts, editors (separate packages) |
| **Escape** | `foreign` (a typed platform view), `canvas` (+ semantic peer), `raw` (target-specific literal) | webview, custom draw |

Two rules keep the taxonomy honest: every entry has a **semantics
contract** (what a person does with it) and every entry names its
**a11y obligations**. A component that cannot state both does not
ship.

## 8. Composition: children, slots, templates

- **Children** are a list of views. A container's layout field
  positions them.
- **Slots** are named blocks (a dialog's `actions`, an app bar's
  `leading`/`trailing`, a field's `prefix`/`suffix`). A slot is a
  typed fn, not a stringly key.
- **Templates** (a user component that renders a list from data) use
  the derive/`@std.meta` machinery; this is the L4 sugar row.
- **Custom components** are compositions: a new `component` type
  implementing `View`, drawing only through existing primitives. A
  genuinely NEW primitive is not a user extension — it is a library
  contribution or the `foreign`/`canvas` escape. This is the price of
  a target-neutral tree and a closed, versioned primitive set
  (LIBRARIES rule 7); it is also what keeps every target able to draw
  every tree.

## 9. Interaction, state, forms, async

- **State** is `state` parameters (L1) and `@model` fields; a
  component reads values and calls actions, and owns no truth.
- **Events** are `on_<event>: Action?`: `on_press`, `on_change`,
  `on_submit`, `on_open`/`on_close`, `on_select`, `on_dismiss`, plus
  keyboard and gesture events on the components that need them.
- **Forms** are `form { … }` over `field` children, bound to a model;
  validation is `@model` rules, errors are `error_text` in the field's
  `error` slot, and the submit action sees only valid data.
- **Async** is `?` in a view: `Pending` (skeleton/spinner), `Failed`
  (error_state with retry), `Empty` (empty), else content — a view
  handles all four or takes the theme default, and the framework
  lists which it took.
- **Overlays** carry the layer's obligations: scrim, focus trap,
  dismiss on escape/back/outside, focus restoration, anchor
  positioning, and a `modal` flag a target honors.

## 10. Accessibility as a subsystem

Every component's a11y contract (name, role, value, state) is data;
the obligations are enforced at the earliest place they can be.

| Obligation | Enforced |
|---|---|
| a control has an accessible name | compile time (a component that needs a name and has none is refused) |
| `image` has an alternative | compile time |
| heading levels form a sane outline | compile time (within a view) |
| theme colour pairs meet contrast | when the theme is made |
| keyboard operability, focus order | per-target + keyboard traces |
| no focus traps (except modals), restore on close | per-target + tests |
| live announcements, urgency/politeness | declared on `status`/`toast`; target reports |
| reflow, text spacing, reduced motion, forced colors | theme + target |
| bidi and logical edges | layout (logical `Edge`, direction) |
| canvas/GPU equivalence (a semantic peer) | `canvas` requires a peer or is refused |

Conformance **profiles** (`web-aa`, `touch-comfortable`, platform)
select thresholds; a build declares its profile and the checks use it.

## 11. Realizers and targets

A **realizer** is the visitor (`Realizer`, one method per component)
plus a typed accumulator; a **target** is a directory implementing it.

- **Capability matrix**: each target declares which components and
  which component features it can draw (`canvas` needs a peer;
  terminal has no colour depth; native has no HTML). A tree using
  something a target cannot draw is refused FOR THAT TARGET, at the
  node, with what to do instead.
- **Op stream**: the compiled core emits target-neutral ops
  (`create`/`set`/`insert`/`move`/`remove`/`listen`/`measure`); the
  visitor is the source-level spelling of the same thing; a realizer
  applies ops, one batch per committed segment.
- **Targets**: `html` (SSR) · `dom` (live) · `tui` · `test`
  (transcript + snapshot) · `describe` (the inspector/diff tree) ·
  `uikit`/`appkit`/`android` (native) · `canvas`/`gpu` · `email`
  (a constrained HTML target) · `print`/`pdf`. Each is a package, with
  a byte budget and a proof that its first tree matches `describe`.
- The `describe` target is not a second type system: it is one more
  realizer over the same tree, and the inspector, diffs and agent
  reading all use it.

## 12. Compiler integration — our edge

The library is where Avra's compiler earns its keep:

- **Provenance**: every node carries `OriginId` (source location), so
  diagnostics, the inspector, hot reload, snapshot diffs, tests and
  agents all point home (WEB_UI §3).
- **Static completeness**: every component a program uses must be
  realized by every target it builds — a compile error naming the
  component and the target, not a runtime surprise.
- **Layout equivalence**: geometry over the gallery corpus, per
  engine, within tolerance.
- **Budgets**: per-frame handler `@cost`, byte budget per target,
  layout node count; a build reports its worst case.
- **Compile-time a11y** (§10) and **contrast at theme construction**.
- **The agent door**: `@action` signatures become an MCP tool
  schema, so an agent drives the same actions a person does.

## 13. Extensibility and versioning

- **Compose** new components from primitives (the normal path).
- **A new target** is a new directory + `impl Realizer`; nothing it
  implements changes.
- **A new primitive** is a library contribution or `foreign`/`canvas`.
- **Growth crosses, moving refuses**: a component's fields may be
  appended; a target's capability row may be appended; renaming,
  reordering or shrinking a shape is a two-step (stop the door
  refusing, move it, restore the door) — the crossing law.
- **Deprecation** is visible: an old name stays with a migration note
  until a major version.

## 14. Tooling

- **Gallery/catalogue**: every component × variant × state × theme ×
  size class, generated from the components themselves (a realizer),
  run as an `avra` command, never a package.
- **Inspector**: the tree, styles, layout, actions and a11y of a
  running view, through `describe` + provenance.
- **Snapshot and transcript testing** (`testing/`): a view's semantic
  tree and its keyboard/action trace as fixtures.
- **A11y audit** and **contrast report** built from the theme and the
  obligations table.
- **Theme editor**: a tool over the `Theme` record.
- **Docs**: each component's doc is its catalogue entry; the docs
  site is the realizer output of the catalogue.

## 15. Quality bars — the definition of done

A component ships when:

1. Its fields come from the shared groups + its own content, and its
   doc states semantics, a11y and per-target behaviour.
2. It draws in `html`, `tui`, `test` and `describe`; every other
   target either draws it or refuses it with words.
3. Its a11y obligations are met (or compile-refused).
4. Its states and variants are one enum each, not boolean soup.
5. It has spec tests, an adversarial test, a snapshot and a keyboard
   trace where it is interactive.
6. It composes without a wrapper node and without a style literal.
7. The whole Sprite suite, idioms and fmt are green.

A theme ships when its colour pairs meet the declared profile and a
contrast report is generated.

A target ships when its first tree equals `describe`'s, its byte
budget is measured, and its capability matrix covers every core
component.

## 16. Build order

Each phase is many small PRs; each is independently useful and gated.
The order is least-controversial and most-useful first.

| Phase | Delivers | Proof |
|---|---|---|
| **L0 foundations** | tokens, `Theme` + default, `Style`, `Layout`, `Name`, `View`, `Realizer`, `html` + `tui` + `describe` + `test`, first components (`text`, `heading`, `button`, `column`, `row`) | suites, snapshots, geometry on the first two engines |
| **L1 layout** | `grid`, `scroll`, `spacer`, `aspect`, `safe_area`, responsive size classes, RTL | geometry equivalence; RTL snapshot |
| **L2 component set** | every **Core** row in §7, family by family | per-component DoD (§15) |
| **L3 interaction** | events, focus, keyboard, overlays (dialog/sheet/popover/menu/tooltip/toast), forms, async | keyboard traces; focus-restore tests |
| **L4 state & data** | `state` bindings, `@model` forms, live queries (aligned with L1/L2 language rungs) | end-to-end app |
| **L5 theming depth** | tonal palette from a seed, modes, density, contrast report, DTCG import | contrast report; mode snapshots |
| **L6 targets** | `dom` (live), native (`uikit`/`appkit`/`android`), `canvas`, `email`, `print` (paced) | first-tree = `describe`; byte budgets |
| **L7 polish** | motion, i18n/bidi, a11y audit, inspector, gallery, docs site | the bars in §15 |

Phase 0's existing `std-ui*` packages are **migrated then deleted**
(§17). `site` is migrated in L2 and is the first real consumer.

## 17. Open decisions

Owner steer, 2026-10-01, on the first four:

1. **Associated types** (`trait X { type Out }`) — **YES**, as its own
   small language slice (epic child .31). A painter, a codec, a
   transport each declare their own answer type; callers stop naming
   it. Design doc first, then the seed dance.
2. **Tonal palette from a seed** — **OUT of v1**, but the `Theme`'s
   shape must accept it later without changing. Ship a hand-tuned
   default + dark + high-contrast now; L5 drops the generator in.
3. **Name freezing** — no hard freeze. Internal records grow by
   appending (the crossing/ growth laws); user-facing variant enums
   grow by appending; keep names descriptive, never clever. A rename
   later is a two-step move, not a rewrite.
4. **Scope discipline** (§18) — **agreed**: charts, maps, rich-text
   and data-grid virtualization are companion packages, not core.

Still open:

5. **Modifiers: pure sugar vs a composable axis.** Owner likes both
   chaining and direct property passing; the recommendation is sugar
   over the shared groups (`text("hi").pad(.S)` ≡ `text("hi") {
   pad: .S }`) — one mechanism. A separate composable axis (SwiftUI's
   wrapping modifiers) is more powerful but adds a second mechanism
   and a wrapper node; revisit only if a real component wants it.
6. **Slots and templates** — the L4 sugar (`@template`, default slot,
   builder syntax). Design when a real component wants it.
7. **Capability matrix enforcement** — compile-time refusal per target
   is the design; the mechanism (an annotation per target, a check
   pass) is open.
8. **`foreign`/`canvas` typing** — how a platform view is typed and
   kept honest across targets; a design of its own (far shelf).
9. **The op stream vs the visitor** — today the visitor is the
   source-level spelling and the op stream is its compiled output; the
   exact IR is open when `dom` lands.
10. **`dyn Realize<T>` (C2b)** — no longer a blocker; land only for
    library ergonomics when a site wants it.

## 18. Scope discipline — what is NOT core

Not every UI need belongs in `@std/ui`. These are companion packages
built on the escapes:

- charts, graphs, maps, rich-text/markdown editors, virtualized data
  grids, browser-embedded content (`foreign`), 3D/canvas engines,
  drag-and-drop frameworks, form-schema engines, icon sets (data, not
  code), illustration assets.

Keeping them out is what keeps the core small enough to be drawn by
every target and proven on every engine.

## 19. Prior art — what we take, what we refuse

| Library | Take | Refuse |
|---|---|---|
| **SwiftUI** | modifiers + environment, composition over configuration, builders, state as a parameter | opaque-type erasure, the property-wrapper zoo, ownership confusion |
| **Material 3** | tonal palettes and semantic colour roles, the type scale, elevation, motion, a full component set with states | platform lock-in, JS-only interaction, a fixed visual language no brand can leave |
| **Fluent 2** | tokens as the contract, density, restrained motion, accessibility defaults | a single vendor's look |
| **Radix / Headless** | semantics first, accessibility as the primitive, unstyled by default | React binding, an a11y checklist instead of obligations |
| **Flutter** | one widget contract, layout primitives, an explicit constraint model | everything-is-a-widget, a runtime framework |

What none of them have and we do: one tree for every target, static
completeness (a target missing a component is refused), provenance on
every node, and the same source proving layout across two engines.

## 20. Runtime — deferred, with triggers

The patch loop is NOT a VDOM. The read set is compiler-known and
identity is `OriginId` — its source location — so a static node is
addressed, not matched, and one expression changing emits one op.
Fine-grained where reads are provable; coarse across a `dyn` boundary.

NOT designed yet (fires when the `dom` target / op stream is built):

- **Keys for dynamic lists.** Origin identity covers static structure; a
  reordered or inserted item needs `key` or a move degrades to rebuild.
- **`dyn` stability.** A node whose concrete primitive changes cannot
  patch in place; where the compiler cannot prove stability it must emit
  a runtime check.
- **Subscription budgets.** Per-node signals are cheap to update and
  expensive to hold; per-view is the reverse. Measure, never assume.
- **Hydration.** The server's HTML and the client's tree must agree;
  `OriginId` makes the ids derivable on both sides, but a mismatch is
  still a failure mode.

FORWARD-COMPAT NOW: the `Node` keeps `Box.key`, and the compiler keeps
`OriginId`; both are the identity the runtime will need.

