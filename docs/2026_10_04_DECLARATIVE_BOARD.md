# The declarative board — the app written as a person would write it

> 2026-10-04. Base `48e8e62`. The board is the UI epic's witness: a real
> program that WANTS the language, so every construct it reaches for is
> a probed, named ask. `docs/2026_10_02_COMPILED_UI.md` is the target
> architecture; this file is what that architecture looks like from the
> author's chair, and exactly how far the compiler is from it today.
>
> Probes were run with `build/avra check` (gen-2, `make bootstrap`) on
> scratch packages under `build/scratch/`, never inside a package tree.
> The current board (`tools/ui-board/src/main.av`,
> `packages/std-ui/src/tests/board/board.av`) compiles today and is the
> floor, not the ceiling.

## The ideal board

The app a person would naturally reach for: per-item actions, a task
added from a field, filters, theming, a11y — state in, tree out, one
exhaustive `update`.

```avra
use @std.meta.{derive}
use @std.ui.{heading, column, row, list, item, field, button, checkbox, text}
use @std.ui.realize.messages.{Messages}
use @std.ui.realize.view.{View}
use @std.ui.style.theme.{Theme, default_theme}
use @std.ui.a11y.name.{Name}

type Todo = { id: int, title: string, done: bool }
enum Filter { All, Active, Done }

@derive(Messages)
enum Msg {
    Add
    Toggle(id: int)
    Delete(id: int)
    SetFilter(which: Filter)
    Draft(text: string)
}

state todos: List<Todo> = []
state draft: string = ""
state filter: Filter = .All
provide theme: Theme = default_theme

derived visible = match filter {
    .All -> todos
    .Active -> [t for t in todos if !t.done]
    .Done -> [t for t in todos if t.done]
}

fn update(m: Msg) {
    match m {
        .Add -> add()
        .Toggle(id) -> toggle(id)
        .Delete(id) -> remove(id)
        .SetFilter(f) -> filter = f
        .Draft(text) -> draft = text
    }
}

fn board_view() -> column {
    column {
        heading "Tasks"
        row {
            field "New task" {
                value: draft
                on_input: Msg.Draft(it)          // the input's own text becomes the payload
            }
            button "Add" { on_click: Msg.Add }
        }
        row {
            button "All" { on_click: Msg.SetFilter(.All) }
            button "Active" { on_click: Msg.SetFilter(.Active) }
            button "Done" { on_click: Msg.SetFilter(.Done) }
        }
        list visible() by it.id {                 // keyed reconciliation, scoped to this list
            t -> item {
                key: "${t.id}"
                checkbox t.title {
                    checked: t.done
                    on_click: Msg.Toggle(t.id)
                    a11y: Name { label: "Mark ${t.title} done" }
                }
                button "x" {
                    on_click: Msg.Delete(t.id)
                    a11y: Name { label: "Delete ${t.title}" }
                }
            }
        }
    }
}
```

Every construct above that the compiler refuses is probed below, with
the smallest spelling that compiles today so the doc stays usable.

---

## What compiles today

The same app with today's spelling. It is *not* the ideal — it is the
floor this doc is measured from — and it compiles clean at `48e8e62`.

```avra
use @std.meta.{derive}
use @std.ui.components.{heading, column, row, list, item, checkbox, text}
use @std.ui.realize.messages.{Messages}
use @std.ui.realize.view.{View}
use @std.ui.realize.prim.{prim}
use @std.ui.style.box.{Box}

type Todo = { id: int, title: string, done: bool }

@derive(Messages)
enum Msg { Toggle }

@derive(View)
@prim(.Button)
component action_button {
    ..Box
    label: string
    on_click: Msg = Msg.Toggle
}

state filter: string = "all"
state todos: List<Todo> = [Todo { id: 1, title: "Write the dec", done: false }]

fn visible() -> List<Todo> {
    match filter {
        "all" -> todos
        "done" -> [t for t in todos if t.done]
        rest -> [t for t in todos if !t.done]
    }
}

fn board_view() -> column {
    column {
        heading "Tasks"
        row {
            action_button { label: "All" }
            action_button { label: "Active" }
            action_button { label: "Done" }
        }
        list {
            for t in visible() {
                item {
                    key: "${t.id}"
                    checkbox t.title { checked: t.done }
                    action_button { label: "x" }
                }
            }
        }
    }
}
```

The `key` field, `state`, `provide theme`/`env`, filters, a11y
(`a11y: Name { label: … }`), theming (`style: Style { … }`) all work
today. What follows is what the ideal reaches for and the compiler
does not carry.

---

## Gap 1 — a message variant carries no payload

**Ideal lines.** `enum Msg { Toggle(id: int) … }`, and every
`on_click: Msg.Toggle(t.id)` / `Msg.SetFilter(.All)`.

**Probed refusal.** `@derive(Messages)` compiles a payload-carrying
variant cleanly — no diagnostic. The defect is silent and shows at the
wire. A program at `build/scratch/probe/src/tests/pay/pay.av`:

```avra
@derive(Messages)
enum Pay { Toggle(id: int) }

let one = Pay.Toggle(1)
let two = Pay.Toggle(2)
println("sites_equal=${one.site() == two.site()}")
println("resolved=${Pay.from_site(one.site()) != null}")
```

answers `sites_equal=true`, `resolved=false`. Two different messages
hash to one site (the site is `event_site(decl, variant.name)`, the
payload is not in it), and `from_site` covers only payload-free
variants (`messages.av`'s `let plain = [v for v in t.variants if
v.fields.is_empty()]`). The host echoes a site the app cannot resolve,
so a per-item click does nothing and nobody is told.

**What the author meant.** `Msg.Toggle(2)` is a distinct fact from
`Msg.Toggle(1)`; the site is the *variant's* identity and the payload
is the *value*. `docs/2026_10_02_COMPILED_UI.md` says the action is
lifted into "a typed variant carrying its captures".

**Smallest spelling that compiles today.** A payload-free `Msg`
(`enum Msg { Toggle }`) with one global action, as the floor board
does — there is no per-item spelling for a dynamic list, because a
payload-free variant has one site for every instance.

**Upstream half, probed too.** The tree's `Action` is
`{ kind: EventKind, site: int }` (`realize/render.av`) — there is no
payload channel on the wire at all, so even a resolved `from_site`
would have nothing to rebuild the payload from.

**Ask.** Generated `Msg` variants carry their captures as TYPED
payloads; the site stays the variant's identity and the payload rides
the frame; `from_site` rebuilds a variant from `(site, payload)`.
Callsite: `packages/std-ui/src/realize/messages.av` (`derive`, the
`plain` filter), `packages/std-ui/src/realize/render.av` (`Action`),
`tools/ui-board/src/main.av:74`. Parent `avra-xubk.2`.

## Gap 2 — the instance-body event spelling

**Ideal line.** `checkbox t.title { on_click: Msg.Toggle(t.id) }` is
today's shape; the ideal the epic names is the block form
`on click { t.done = !t.done }`.

**Probed refusal.**

```
error[parse.expected]: expected BREAK while parsing `stmt`
   ╭─[…/c2.av:9:16]
 9 │             on click { t.done = !t.done }
   ·                ┬
```

at `click` — the instance body's grammar (`features/components/mod.av`:
`( s:setting | s:stmt | BREAK )*`) has no `on <kind>` production.

**What the author meant.** Write the handler where the control is; the
compiler lifts it, capturing whatever the body reads. `avra-xubk.2`'s
own comment calls this "the `on click { … }` instance-body grammar so a
site is per INSTANCE (its source text), not per (declaration, action)".

**Smallest spelling today.** A custom component with an explicit
`on_click: Msg` field (the floor board's `action_button`), or the
app-level `board { on_click: Msg }`. State writes inside the handler
are not available; the handler dispatches a payload-free message.

**Ask.** The `on <kind> { … }` instance-body production, lowering each
instance to a content-addressed site and a generated update arm.
Callsite: `packages/std-avrac/src/features/components/mod.av` (the
`instance_body` rule), `tools/ui-board/src/main.av`. Parent
`avra-xubk.2`.

## Gap 3 — an event field on a std component (typed payload from input)

**Ideal line.** `field "New task" { value: draft, on_input:
Msg.Draft(it) }`.

**Probed refusal.**

```
error[type.struct_fields]: `field` has no field `on_input`
   ╭─[…/p_input/src/main.av:14:23]
14 │             on_input: Msg.Draft(it)
   ·                       ┬
help: the fields are `label`, `style`, `layout`, `a11y`, `key`, `value`, `placeholder`, `invalid`
```

`field` declares no event field; no std component does except the
bespoke `board` in `tools/ui-board/src/main.av`. And even where a
component declares `on_click: Msg`, the component's *value* is not
forwarded — `it` has no meaning in the seat.

**What the author meant.** An input's typed text becomes the message's
payload; the event field is part of the component contract
(`docs/2026_10_01_UI_LIBRARY.md` §9: `on_<event>: Action?`).

**Smallest spelling today.** None for the payload. A custom component
with a payload-free `on_input: Msg` field can fire, but the input's
text never reaches the app; the board must read `state` instead, which
it cannot update from the input.

**Ask.** Event fields on the std components whose contract calls for
them (`field.on_input`, `checkbox.on_change`, `button.on_click`), with
the control's value bound to the message's payload capture. Callsite:
`packages/std-ui/src/components/field.av`,
`packages/std-ui/src/realize/view.av` (`event_kind`, `action_quote`).
Parent `avra-xubk.2`.

## Gap 4 — keyed list reconciliation (`list … by it.<field>`)

**Ideal line.** `list visible() by it.id { t -> item { … } }`.

**Probed refusal.**

```
error[build.failed]: `list` takes no head value — name it at a statement (`list name { … }`), or write `list { … }`
   ╭─[…/p_by/src/main.av:8:5]
 8 │     list todos by it.id {
   ·     ┬
```

The grammar has no `by it.<field>` clause. The `key` field on `item`
exists and the tree carries it, but `features/read_set.av`'s
`SiteLowering` has only `Hoist`, `Direct(place)` and `Tree` — its doc
comment says the `Keyed` arm "joins this registry with the `list … by`
construct", a construct that is not there. So no keyed lowering is
emitted; a reordered list reconciles by position.

**What the author meant.** The list's key field is the reconciliation
identity, and the lowering is scoped to that list
(`docs/2026_10_02_COMPILED_UI.md`, site 3).

**Smallest spelling today.** `list { for t in visible() { item { key:
"${t.id}" … } } }` — compiles, carries the key, but lowers on the
conservative tree path.

**Ask.** A `list <source> by it.<field> { x -> … }` production that
requires a key, joined to a `SiteLowering.Keyed(list)` arm and its
emitted reconciler. Callsite:
`packages/std-avrac/src/features/lists/` (the list/component
grammar), `packages/std-avrac/src/features/read_set.av`
(`SiteLowering`), `packages/std-ui/src/components/item.av`. Parent
`avra-xubk.3` (lowering v1).

## Gap 5 — `derived` state

**Ideal line.** `derived visible = match filter { … }`.

**Probed refusal.**

```
error[parse.expected]: expected BREAK while parsing `stmt`
   ╭─[…/p_derived/src/main.av:3:9]
 3 │ derived visible = [t for t in todos if !t.done]
   ·         ┬
```

**What the author meant.** A memoized projection of `state`, part of
the read set (`docs/2026_10_02_COMPILED_UI.md` "Other features worth
having").

**Smallest spelling today.** A plain `fn visible() -> List<Todo>` that
recomputes per call — correct, un-memoized.

**Ask.** A `derived` binding whose value is recomputed when its read
set changes, folded into the same read-set analysis. Callsite: the
ideal board's `visible`. Parent `avra-8sb5.59.27` (L4 state & data).

## Gap 6 — live queries

**Ideal line.** `query active = [t for t in todos if !t.done]` (any
spelling of a live query over a source).

**Probed refusal.**

```
error[parse.expected]: expected BREAK while parsing `stmt`
   ╭─[…/p_query/src/main.av:2:7]
 2 │ query active = [t for t in todos if !t.done]
   ·       ┬
```

**What the author meant.** A read that stays current as its source
changes — `docs/2026_10_01_UI_LIBRARY.md` L4 ("`@model` forms, live
queries").

**Smallest spelling today.** A `fn` that recomputes, or a `state`
updated by hand.

**Ask.** Live-query bindings tied to the read set (and, eventually,
the query kernel's memo). Callsite: the ideal board's data layer.
Parent `avra-8sb5.59.27` (L4 state & data).

## Gap 7 — `@model` forms

**Ideal line.** `@model type Todo = { title: string, done: bool = false }`
with a form derived from it.

**Probed refusal.**

```
error[resolve.unresolved]: `model` is not defined
   ╭─[…/p_model/src/main.av:4:1]
 4 │ @model
   · ┬
   · ╰── not defined anywhere in this program
```

`docs/2026_09_24_DOCUMENTATION.md` §4.0 already corrects this: "`@model`
does not exist in this tree yet."

**What the author meant.** A typed record that owns its storage,
validation and derived doors; a form binds to it, `error_text` shows
per-field failures, and submit sees only valid data
(`docs/2026_10_01_UI_LIBRARY.md` §9, §16 L4).

**Smallest spelling today.** A plain `type` record plus a hand-written
action and hand-written validation — no persistence, no derived form.

**Ask.** The `@model` derive (storage + create/update/delete doors +
validation rules + the form view). Callsite: the ideal board's task
store. Parent `avra-8sb5.59.27` (L4 state & data).

## Cross-cutting: a built-in type name is unusable

Not a gap in the ideal board itself, but it bit this file: the natural
domain name `Task` is refused.

```
error[resolve.builtin_type]: `Task` is a built-in type
   ╭─[…/probe/src/main.av:6:1]
 6 │ type Task = { id: int, title: string, done: bool }
   · ┬
help: choose another name — `int`, `string` and `bool` are the language's
```

The help names three; `Task` is not among them, and the runtime has a
task substrate (`features/tasks`). A program author reaching for the
obvious word is sent to rename. Filed as its own ask below.

---

## The gaps, in one table

| # | construct | refusal | ask home |
|---|---|---|---|
| 1 | `Msg.Variant(payload)` | silent: identical sites, `from_site` null | avra-xubk.2 |
| 2 | `on click { … }` | `expected BREAK` at `click` | avra-xubk.2 |
| 3 | `field { on_input: Msg.Draft(it) }` | `field` has no field `on_input` | avra-xubk.2 |
| 4 | `list xs by it.id { … }` | ``list`` takes no head value | avra-xubk.3 |
| 5 | `derived x = …` | `expected BREAK` at `x` | avra-8sb5.59.27 |
| 6 | `query x = …` | `expected BREAK` at `x` | avra-8sb5.59.27 |
| 7 | `@model type` | `model` is not defined | avra-8sb5.59.27 |
| — | `type Task = …` | `Task` is a built-in type | avra-8sb5.10 |
