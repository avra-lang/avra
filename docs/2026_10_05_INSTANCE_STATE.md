# Per-instance state reached by an extracted handler

> 2026-10-05. The UI epic's identity gap (`avra-ee0u`): a handler lowered to
> a top-level function runs on an event that crossed a serialisation
> boundary, so everything it needs must be reachable by NAME or ride the
> payload as something serialisable. Module state is reachable by name and
> today's board works; a REUSABLE component's state is per instance, the
> name no longer identifies one place, and the function cannot find it.

## The forcing constraint (measured, not assumed)

The event channel carries a content-addressed SITE and a typed PAYLOAD —
one scalar (`int`/`string`/`bool`) today; a record is refused
(`@std.ui.realize.payload`, `@derive(Messages)`). A captured Cell is a
heap pointer and is meaningless on the far side. The mechanism is
therefore a top-level function plus a **serialisable KEY that resolves to
the place** — identity by key, never by pointer.

## Probes (gen-2 at `982c405` + this branch)

| probe | result |
|---|---|
| a lambda capturing a `state` SEAT | `error[resolve.immutable]`: "captured by value — a lambda cannot assign to it". A state seat is **not** shared into a closure; only a `state` BINDING is (`capture_regs` packs a `.Def`'s Cell, never a `.Param`'s). |
| a lambda capturing module `state` | shares the Cell; a write through it lands in the module place. `state c` + `() -> { c = c + 1 }` answers `6` over three calls. |
| per-instance state in a `type` record | `type R = { state n: int = 0 }`; two `R {}` copies are INDEPENDENT (`a=1 b=0`). The Cell is seeded per instance. |
| per-instance state in a `component` | `component C { state n: int = 0 }` is REFUSED: "a component holds its fields and its `fn`s, and nothing else". A plain field works (`todos: List<string> = []` is independent per instance) but is a VALUE, so a handler capture copies it. |
| `state` seat on a component head | `component C(state n: int)` is a parse error — a component head takes no seat marks. |
| `@derive(View)` over a `fn()` event field | LANDED since: a std control's event field is `Run`/`Hear` and `on click { … }` fills it; the frame keeps the handler and the host echoes the node. |

So a shared, top-level handler driven by a serialised event cannot reach a
per-instance place by capturing it. It needs a KEY.

## The design: a keyed table, and TWO lifetimes

The table maps `key -> value` and is reached by name from the handler.
The key is serialisable and STABLE across renders — a model row's id, or
the instance's own key, never a positional ordinal that renumbers when a
sibling lands.

**LIFETIME IS THE IDENTITY'S, never the render's.** This is the part that
must not be collapsed:

- **MODEL-KEYED** (`model: true`): lives exactly as long as the model row
  it is keyed by. Deleting the row releases it (`forget`); nothing else
  may. **A filter that merely HIDES the row must not free it** — a hidden
  row's state is what un-hiding it reads back. This is the trap: "seen in
  this render" is the wrong live-set for model-keyed state, and a single
  mechanism for both kinds loses data the moment anyone filters.
- **INSTANCE** (`model: false`): lives while its instance is MOUNTED. The
  render owns it: `opening` clears the frame's seen set, each rendered
  instance `touch`es its key, and `sweep` AFTER the frame drops every
  unseen instance entry.

The sweep runs after the frame is built and no event is in flight, so a
key it drops is one the frame did not name; an event naming a live key can
never reach a dead place.

## What is built

`packages/ui-instance/src/ui_instance.av` — the table: `opened`, `at`,
`ensure`, `put`, `forget`, `opening`, `touched`, `sweep`, `held`.
`packages/ui-instance/src/tests/instances/instances.av` is the witness,
proven `eval == native == expected`:

```
start a1- b1- a2- tasks=3 panels=2      two board instances, independent
toggle a1 a1+ b1- a2-                   a click in one changes only that one
toggle b1 a1+ b1+ a2-
filter open a1+ b1+ a2- held=3          a hidden MODEL entry SURVIVES the filter
remove b1 a1+ a2- held=2                the deleted row's state is released
unmount b panels=1 tasks=2              the INSTANCE panel is swept; MODEL entries stay
remount b panels=2
```

Clicks are routed through the real channel's two doors — the
content-addressed SITE and the echoed typed PAYLOAD
(`event_at` + `Msg.from_site`), the exact body of `avra_event` — then
`update` and `sweep`. `held` is the table's accounting: the eviction is
watched, not assumed.

## The compiler bug this exposed (fixed here)

A `@derive(Messages)` enum whose payload variants are ALL wide (all
`string`) crashed native codegen the moment it filled a `dyn Messages`
seat:

```
Call parameter type does not match function signature!
  %pack1 = insertvalue { i64, i64 } %pack, i64 %2, 1
 ptr  %3 = call ptr @"…Messages.marks$…~~Msg"({ i64, i64 } %pack1)
FATAL: LLVM verification failed for …Messages.marks$…~~Msg$v
```

Root cause: the dyn box's vtable (`Decls.trait_method_names`) listed a
trait's STATIC members (`derive`, `marks`) as if they took a receiver, so
the value-record receiver-unboxing shim (`dyn_entry`) was built for a
member with no receiver and disagreed with the method's own currency. A
`bool`-payload enum dodged it only because its vtable entry was never
reached the same way. Fixed by excluding static members from the vtable
(they stay in `trait_fns` for the checks that read every member). `std-ui`
136/136 + 18 programs pass; the all-wide enum now runs in both engines.

## What is NAMED, not landed

- **The browser byte wire.** The witness exercises the channel's doors,
  not the socket; `tools/ui-board/demo.mjs`-style wasm hosting is the
  remaining half. (The `@derive(View)` `fn()` event field is also the
  sibling's `on click { … }` slice.)
- **Compiler-managed registration.** The table is declared by the app and
  lived by the app's verbs — A's LIFETIME semantics with B's ownership.
  The next slice is the compiler minting the key from the component's
  instance, generating `ensure`/`touch`/`sweep` at the instance sites, so
  the author writes none of it. The seam is the `@derive(View)` projection
  and the component's Box `key`.
- **Runtime byte accounting for a program under `avra run`.** The
  evaluator shares the compiler's heap, so `avra_mem_live` reports the
  compiler's bytes (41 MB and rising) around a user program — it cannot
  witness a program's release in-process. `held` is the honest accounting
  here; a native-only instrument is the ask.
- **A nullable of a FLAT one-field record** (`T?` over `{ open: bool }`)
  triggers a second LLVM verifier failure (a PHI operand type mismatch in
  a generic `ensure`). The witness uses a two-field state record; the
  defect is real and filed here, not worked around.
