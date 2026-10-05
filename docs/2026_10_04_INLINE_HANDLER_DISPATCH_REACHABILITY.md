# Inline-handler dispatch reachability — the library-type angle, probed

> 2026-10-04, lane ui-libtype, over main 5727f7e.
> Follows `2026_09_23_COMPONENT_EXPANSION.md` §3's `on click { }` paragraph
> and the four earlier attempts (#251, #253, #254, #258).

## The angle

Instead of generating a TYPE per handler, ship ONE library type
(`std-ui/src/tests/inline`'s `Inline`: a site and a `Payload?`) and let
`on click { … }` fill its fields:

```avra
Inline { site: <const for this source spot>, value: pack(<narrowed captures>) }
```

No generated type, so typing never waits on captures. The claim under
test is that the dispatch table (site → handler code) is built at
LOWERING, where the lifted handler fns exist.

## Probe answers

### 1. Does a hand-written library `impl Messages` coerce into `dyn Messages?`?

**YES.** `Inline` is an ordinary `type` with a hand-written
`impl Messages for Inline`; `button { on_click: Inline { … } }` compiles
and the frame carries the action.

```
$ build/avra run packages/std-ui/src/tests/inline/inline.av
inc_site=1201
add_site=1202
...
add_payload=5
```

So the field's `dyn Messages?` is ordinary `dyn` coercion — a concrete
implementor is accepted. The "message VALUE is the wall" reading of #258
is too narrow: the message VALUE is not the wall. (#258's refusal is only
about the *lambda*, which is no implementor.)

### 2. Can site + narrowed capture be built at the construction site?

**YES, hand-written.** `packages/std-ui/src/tests/inline/inline.av` now
builds the value INSIDE a keyed element body, where the row binder is in
scope, with the payload narrowed to the one scalar the handler needs
(`r.id`), one shared site for the source spot:

```avra
fn row_list() -> list {
    list rows by it.id { r ->
        item { items: [button "Remove" { on_click: Inline { site: 1301, value: Payload.Text(r.id) } }] }
    }
}
```

```
$ build/avra test packages/std-ui
136/136 tests passed
packages/std-ui/src/tests/inline/inline: eval == native == expected
```

with

```
row_actions=3 row_sites_shared=true
row_payloads=r1,r2,r3
fire_r3=true
rows_after=[r1,r2] removed=r3
fire_r1=true
rows_after2=[r2] removed=r1
```

One site, three payloads, each firing removes exactly its own row. The
destination shape is expressible; the compiler still has to produce it.

### 3. Is a static site → code table expressible at lowering?

**Expressible, but NOT reachable.** Lowering knows every lifted handler:
`LowerCx.jobs.lifts` (`features/worklist.av`) holds `{ lam, name }` for
each `cx.lift(e)`, and `Decls.lifted_symbol(file, e)` names it
deterministically. The IR can switch on the site (`SwitchStart`) and call
those symbols — a table of code addresses is data, and the tree itself
still carries only `site` + `payload`.

What blocks the acceptance is that a lowering-time body has **no name the
typed program can call**. The actual dispatch paths in the tree are typed
edges:

- `@derive(Messages)`'s `Msg.from_site` — a declaration the derive mints
  *before* typing, from the enum's SHAPE (not its captures);
- the board's `avra_event` (`tools/ui-board/src/main.av`) calls
  `Msg.from_site` then `update` — typed names;
- #251's inline test calls `inline_event` directly — a hand-written
  typed edge.

Nothing generates an edge from a typed program to lowering-time code. A
fixed-symbol entry (`extern fn avra_inline_dispatch …` satisfied by a
compiler-emitted body) does not exist, and would need new plumbing in
both engines: the evaluator binds an extern to a runtime ROW, and a
compiler-emitted body is not a row.

### 4. Is the angle alive or dead?

**Alive for the half it targeted; dead as a route to acceptance alone.**

It removes type generation (probes 1 and 2 prove the value compiles and
dispatches *in process*). It does not remove the wall. It RELOCATES it,
one level up: from "a type must exist while the file is typed" to "a call
edge must exist while the file is typed". Four attempts treated the wall
as type synthesis; the real wall is **dispatch reachability** — the
handler's code has no reachable name until after captures are known.

The missing stage is unchanged and is the one the epic doc already names:
an expansion AFTER typing (S6) that mints a reachable dispatcher
declaration — or a new fixed-symbol/link mechanism that both engines
carry. A library type is necessary but not sufficient.

## What lands here

- `packages/std-ui/src/tests/inline/inline.av` + `.expected` — the keyed
  per-row payload witness (probe 2), hand-written and labelled as the
  destination the generator must reach. Both engines agree.
- This document — the four probe answers and the reachability conclusion.

## Addendum: the reserved-name angle, probed

> 2026-10-04, lane ui-reserved, over main `44922a2`.
> Tests the reachability wall named above, on the hypothesis that a
> RESERVED declaration — not an `extern` — is the edge a typed program
> needs, because reachability comes from the NAME EXISTING AT TYPING
> TIME, not from where the body comes from.

The mechanism: `@std/prelude` declares
`__inline_event(site: int, tag: int, num: int, text: string) -> bool`;
`bind_weakly` gives the name to every file, so a call is an ordinary
typed call; and `lower_inline_event` (compiler/lower/lower.av) builds
its body in IR instead of parsing it, the way `lower_collect`,
`wrapped_body` and every lambda lift already do. Every one of the four
questions answers YES.

1. **A fn's body may be the compiler's.** `lower_collect` is the
   precedent: a declaration whose body is SYNTHESISED in IR, reached by
   the name the typed program calls. `lower_inline_event` is the same
   shape for the door.
2. **The name exists at typing time.** The prelude binds weakly into
   every file. The name resolves as an ordinary fn — a first draft named
   `inline_event` collided with the test witness's hand-written 2-arg fn
   and the typer answered `error[type.mismatch]: \`inline_event\` takes
   2 arguments, found 4` at the call.
3. **Lowering emits the body.** The synthesized body emits a real site
   comparison (`Bin` + `region`, the `match site` shape) and answers
   `at7=true, at8=false`. A real dispatcher would switch the same way and
   call `jobs.lifts`' symbols (probe 3 above).
4. **The evaluator handles it — this is the one the hypothesis named as
   the likely failure.** It does not fail. The evaluator's `.Call`
   resolves the callee by SYMBOL through `body_index(…)` — a body in
   `Lowered.fns`, no runtime row and no host arm. Both engines ran the
   synthesized body, not the source body's `false`:

   ```
   packages/std-ui/src/tests/inline/probe: eval == native == expected
   ```

   So the extern-row concern does not arise: this is not an `extern`.

**The dispatch-reachability wall is passable.** A reserved declaration
whose body lowering synthesizes is reachable from typed code in both
engines, with no post-typing stage and no new link mechanism. The
addendum RELOCATES the wall to the half #255 and #258 already named, and
that half is unchanged: the tree's `on_click` field must carry a
CONCRETE `dyn Messages?` value whose site and narrowed captures come
from the same handler expression. `on click { … }` still has no route to
produce that value — the compiler cannot name `@std/ui`'s `Messages`
(or the app's `Inline`), and the captures are a resolve/type-time fact
no parse-time builder can see. The reserved door carries a SITE the host
echoes; it does not build the value the tree must carry for the host to
echo one.

Probe receipt: the reserved declaration (`@std/prelude`'s
`__inline_event`), the lowering hook (`lower_inline_event`, the shape of
`lower_collect`), and the program test that pinned `at7=true, at8=false`
in both engines. The mechanism is NOT landed on main: doubling it would
ship a dispatcher over an empty handler list with no consumer, which is
dead plumbing, and the value half above is what a real dispatcher needs
first. The patch and the raw outputs are recorded on `avra-xubk.2.2`,
and the hook is 50 lines anyone can re-add.
