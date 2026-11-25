# The compiled update graph

> 2026-10-02. The target architecture for the UI epic, reasoned from first
> principles after the first wasm board ran end to end. Supersedes the
> "tree + reconcile for everything" reading of `2026_09_29_UI.md`; the tree
> SURVIVES as the reference semantics every lowering must match.

## The five facts everything follows from

1. **A UI is a function of state**: `view(state) -> tree`.
2. **The tree and the code are two projections of ONE program** — so the
   map from an event back to code is derivable from the program, never from
   a string table or a runtime registry (both are second sources of truth
   that nothing checks).
3. **An event is a fact from outside**: at a PLACE, of a KIND, with a PAYLOAD.
4. **A place must be stable across renders**, or the target rebuilds rather
   than patches. Lexical position is stable; an index is not.
5. **Everything stays DATA** — because data is what we can compare
   (`no_change`), serialize, inspect, test, hot-reload, and send across the
   wasm boundary. A tree holding closures is none of those things.

These force one shape:

    view(state) -> tree                     // pure; the tree is DATA
    update(state, msg) -> (state, effects)  // pure; msg and effects are DATA

with the compiler generating everything between them.

## Identity: sites, not ordinals

- **A call site is a stable lexical place.** The compiler numbers each
  event-bearing site. No strings, no registry, no typo possible.
- **Inside a loop, identity is (site, key).** `key` disambiguates
  instances; that is its ONLY job.
- **Site ids are CONTENT-ADDRESSED** (file + enclosing fn + a hash of the
  site's own text), never ordinals: an ordinal renumbers when an unrelated
  button is inserted above it, which resets state and breaks hot reload and
  hydration. Renaming a fn changing its sites (and so dropping their state)
  is the accepted cost.
- **Conditional structure** (`if`/`match`) keeps identity because sites are
  lexical, not positional. This is why sites must replace the pre-order ids
  the M1 wire used.

## Events: generated `Msg`, not names

The action is written where the control is; the compiler lifts it into a
typed variant carrying its captures, and generates ONE exhaustive dispatch:

    button "Add" { on click { add_card(b) } }

    // generated — never written by hand
    enum Msg { S12Toggle(card: Card, on: bool), S20Add(board: Board) }
    fn update(state: St, msg: Msg) -> (St, List<Effect>) {
        match msg {
            .S12Toggle(c, on) -> { c.done = on   (state, []) },
            .S20Add(b)        -> (state, [Effect.Post(add_card_route(b))]),
        }
    }

The frame carries `E <site> <kind>` (+ the key path inside a list); the host
echoes `(site, kind, payload)`. Nothing is named by a string. The
exhaustive match IS the check.

**Rejected alternative (2a):** a fn value stored in the tree. It is simple
and typed, but the tree stops being data — it cannot be compared (so
`no_change`, static subtrees and inspection die). React pays for exactly
this with `useCallback` and its inline-lambda footgun; Vue caches generated
handlers to dodge it; Compose needs stability annotations. We refuse the
footgun instead of documenting it.

## The collapse: perfect = the compiler picks the mechanism PER SITE

React, SwiftUI and Flutter choose ONE mechanism at runtime, for everyone: a
diff. We know statically what each expression reads, so we do not have to.

    component board(b: Board, state show: Show = .all) {
        heading "Tasks"                       // 1
        toggle b.pinned { value: b.pinned }   // 2
        list b.cards by it.id { c ->          // 3
            toggle c.title { value: c.done }
        }
        chart b.series                        // 4
    }

| site | lowering | cost per update |
|---|---|---|
| 1 static | hoisted into the binary; the frame never mentions it | 0 |
| 2 one bool | a DIRECT WRITE: "pinned changed -> set `checked` on node N" | one op |
| 3 a list | a KEYED RECONCILER scoped to that list | O(changed) |
| 4 imperative region | a TARGET CALL: `target.draw(region, data)` | O(1) |
| `dyn` / unknown | the CONSERVATIVE path: tree + reconcile (the reference) | general |

ONE analysis feeds all of it: **which state does this expression read?** The
read set is not only for invalidation — it is the input to lowering.

## Safety: the tree is the oracle

The tree + reconcile is the DEFINITION — simple, testable, obvious. Every
lowering is an optimization that must be INDISTINGUISHABLE from it:

- the reference semantics is exercised in tests (and used for `dyn`/unknown),
- the compiled path is what ships,
- a disagreement is a compiler bug the gate catches — the same differential
  discipline as `eval == native`.

## Providers and app state

- **State is a PLACE you own** (lexical: a body's, or a caller's parameter).
- **Providers are context flowing DOWN** — a value, a PLACE, or a CAPABILITY.

    provide theme: Theme = dark              // a value
    provide board: Cell<Board> = boardCell   // a place; descendants write it
    provide env: Env = envOf(app)            // capabilities: open_url, dismiss

Rules: a missing provider is a COMPILE error (lexical resolution, never a
runtime stack); nearest wins; **a provider must be stable across renders**
(a provider built per render invalidates every consumer every frame — the
React `useMemo` footgun); reads flow through the read set; and **there is no
global store** — app state is the root's `state` or a `@model`, everything
else is parameters or providers.

## Effects: borrow Effect-TS's SEMANTICS, not its surface

| effect-ts idea | ours |
|---|---|
| `Effect<A, E, R>` is a DESCRIPTION | effects are data; the runtime executes them |
| typed ERRORS | Avra's `Result<T, E>`; `catch` is exhaustive |
| `R` = REQUIREMENTS checked statically | **this is `provide`/`env`** — "this effect needs a Database" is a compile error nobody provided |
| scopes / finalizers | `defer` becomes an effect's release; subscriptions clean up |
| combinators as data (`retry`, `timeout`, `race`, `parallel`) | described, testable, inspectable |

Skip its ceremony. Keep meaning small: description, typed errors, typed
requirements, resource safety.

## Other features worth having

derived/memoized state (`derived visible = cards.filter(...)`, part of the
read set); `Async<T> = .Idle · .Loading · .Failed(E) · .Ready(T)` so the UI
cannot forget a branch; forms + validation DERIVED from the model and the
action signature; keys REQUIRED by `list xs by it.id`; declarative
subscriptions; navigation AS state (a route is a screen's `state`
parameters); speculative actions + receipts (the authority design — where we
can beat React rather than match it); inspector and time travel (free: the
state, msgs and effects are all data); a11y invariants as compile checks.

## Where the design breaks (and the hatch)

| break | why | hatch |
|---|---|---|
| 10k-row tables, canvas, games at 60fps | tree-diff is the wrong model for massive dynamic content | an IMPERATIVE TARGET consuming the same regions |
| pointer move / drag / scroll | msg->update->view->frame is too slow per move | the HOT CHANNEL: high-frequency events write transforms directly, batched to frames — a LOWERING, not a user-facing escape |
| one dataset, two sibling panes | no common owner; providers move values, not ownership | lift to the nearest common ancestor, or pass a shared `Cell` — the compiler cannot choose ownership |
| message composition at scale | Elm's `update`-knows-everything smell | per-component msgs + GENERATED composition; forwarding policy stays human |
| rich effect lifecycles | cancellation, retry, cleanup, concurrency get hairy | typed requirements + scopes + a SMALL combinator set; resist growth |
| `dyn` / polymorphic subtrees | the concrete impl is unknown, so the read set is coarse | accept over-invalidation there; measure before specializing |
| cross-boundary payloads (text in, files in) | deferred byte channel | needs a real typed channel before forms |
| server/client split (authority, offline, rooms) | two copies of state at different latencies | data makes it possible (specs, receipts, merge), not automatic |
| hot reload & hydration | depend on site stability | content-addressed sites |

## The plan

1. `@state` + the READ-SET analysis — the foundation for invalidation AND
   lowering (three birds, one analysis).
2. Site ids (content-addressed) + generated `Msg`/`update`.
3. Lowering v1: hoist statics + direct patches for leaves + a keyed list
   reconciler — this alone beats the incumbents on the common case.
4. The scheduler: batching, priorities, the hot-channel lowering.
5. Effects with typed requirements tied to `provide`/`env`.
6. Per-target emitters over ONE update graph (DOM -> SwiftUI -> canvas).
