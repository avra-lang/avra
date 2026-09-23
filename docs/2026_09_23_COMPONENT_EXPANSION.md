# Component expansion — a library's block syntax

> 2026-09-23, lane/components (`../avra-components`), over main 0e8a63c.
> DECIDED with the owner, case by case (§9). Tracker: epic avra-8sb5.33.
> Follows the old tree's Components V2 DESIGN (`2026_05_08`) and its
> shipped `component_decl` + `@std.cli.cmdgen`, never their code.

## 0. What a user writes

```avra
use @std.cli.{cli, command, flag, arg}

cli avra {
    description: "Avra compiler"
    command build {
        flag release { short: "-r" }
        arg target { required: true }
        run() { build(self.target, self.release) }
    }
}
```

```avra
use @std.time.{within, ms}
let line = within ms(500) { conn.read(64) }
```

## 1. The one idea

**A component is a record type with defaults that a block instantiates.
If it has an `expand()` method answering code, the block becomes that
code; if not, the block is the record.** Libraries never write grammar:
every component block has ONE shape, parsed by the compiler.

- the answer type is the effect (the standing law): `expand() -> Decls`
  generates declarations, `-> Code` an expression. No `@expand`.
- a component with no `expand` is plain data — a record literal at run
  time. Most of the vision's sugar needs nothing more (§3).

## 2. The declaration

```avra
export component command {
    config { description: string = "" }          // fields with defaults
    children { flags: List<flag>, args: List<arg> }  // typed child slots
    run: Stmts                                   // a code slot
    fn expand() -> Decls { quote { … } }         // optional: the effect
}

export component within(limit: Duration) {       // a VALUE head
    body: Stmts                                  // the block IS the slot
    fn expand() -> Code { quote { … ${self.limit} … ${self.body} } }
}
```

- `config { }` — today's feature, unchanged: fields with defaults.
- `children { }` — typed slots; a nested block of that component lands
  in its slot in order (V2's auto-push). A block no slot takes refuses at
  the user's line, naming the slots.
- a CODE SLOT (`run: Stmts`, `body: Code`) holds the user's code. An
  instance fills it with `run() { … }`; a value-head component's whole
  block is its one code slot.
- the head: none (`component cli`) → an instance NAME, `cli avra { }`;
  params (`component within(limit: Duration)`) → a VALUE, `within ms(5) { }`.
- methods in the declaration are the record's `impl` — ordinary methods.

## 3. The instance — one grammar

```
<word> <name>? { ( key: value | <child> … { … } | slot() { … } | BREAK )* }   // named head
<word> <expression> { <statements> }                                        // value head
```

- `<word>` is an imported component name — a block word, exactly as a
  sublanguage's word is (the `use` pre-scan and lexer word set exist).
  `component cli avra { … }` keeps working with the keyword.
- config is `key: value` — the struct literal's and named argument's
  spelling. Today's `key = value` goes (40 sites, the syntax ladder).
- inner words (`command`, `flag`, `description`) are CONTEXTUAL: they mean
  something only inside the block. Only the imported word is reserved,
  only where imported.

## 4. Two stages, each reusing what exists

| component | runs | position | machinery |
|---|---|---|---|
| no `expand` | never — it is data | anywhere | a record literal; children are list fields |
| `expand` is ONE `quote` whose holes read only `self` | at the PARSE, by substitution | anywhere | copy the provider's template (its plain parse), fill holes with the user's nodes — as a sublanguage mints |
| `expand` computes | the EXPAND stage, in the evaluator | top level only | `@derive`'s path: the instance crosses as a meta value, `Decls` admitted |

- Nothing evaluates inside a parse, so a parse never depends on another
  module's analysis and no import cycle can form through an expander.
- A computing component written in an expression position refuses at
  the library's word: "`cli` generates declarations — write it at the top
  level". A substituting one works anywhere.
- The instance crosses to `expand()` as the record: config values are
  VALUES (so they must settle — literals, consts), children are records,
  code slots are `Code`/`Stmts` handles (opaque: splice only).

## 5. Hygiene — already paid

- A template's names resolve where the quote was written; its binders are
  origin-keyed (`resolve.av`'s `keyed`). `within`'s `outer` never meets a
  user's `outer`, and its extern resolves in `@std/time`.
- A slot's user code keeps the user's origin.
- No injected names: a code slot reads the instance through `self` — the
  expander makes the record type (`flag release` → `release: bool`) and
  the slot becomes its method. To verify in S3: the user's `self` binds to
  the generated method's receiver (a receiver is a seat, not a name).

## 6. Refusals

- shape (a wrong child, a missing `{`) — the generic grammar's words at
  the user's line, plus "`fleg` is not a child of `command` — it takes
  `flag`, `arg`".
- meaning — `expand() -> Result<Decls, Diagnostic>` fails with
  `refuse_as_at("E1", …)`: `error[@std/cli: E1]`, golden in the library.
- types — the expansion is typed as ordinary code, so a value head goes
  through a seat that names the law: `within 5 { }` says "`within`'s
  `limit` is `Duration`, this is `int`", never "no field `ms`".
- compiler codes (next free F-numbers, re-checked at landing): a child no
  slot takes · a computing component off the top level · a substituting
  `expand` whose hole reads more than `self` · an expander that failed.

## 7. Visible (P7), escapable (P8), fast (P4, P14)

- `avra expand <file>` prints every instance as what it became, under
  `// from component within (@std/time time.av:12)`.
- `avra explain within` prints the declaration and its `expand`.
- THE PRINTED EXPANSION COMPILES: a witness per component round-trips
  `expand` → build → same output. The hand-written form is one command away.
- the expansion is ordinary code: no runtime layer. `within`'s `defer` is
  exactly `Deferral.Deadline` today (`lower/walk.av:351`); receipt: `avra
  ir` identical modulo registers. `server`: `tools/bench` on a Sprite.

## 8. The slices

**S2 — `within` leaves the core.** Exercises: a value head, a code slot,
an imported block word, substitution at the parse.
1. ~~The evaluator's door for runtime rows~~ — RETRACTED. The trap
   ("`avra_fiber_within` is extern and this image does not carry it")
   came from main's `build/avra`, a binary OLDER than the F5 rows; the
   lane's own compiler at 5a59a44 runs the same probe clean (`6 5 0`)
   — `rt_dispatch` already routes a row to its arm. A probe names the
   binary that answered it.
2. `component` declarations grow params, code slots, methods, `export`.
3. The block word for components; the value-head instance rule.
4. Substitution at the parse.
5. `@std/time` declares `within`; std-http and std-net import it.
6. Delete `Expr.Within`, the tasks feature's within rule/typing/lowering,
   `Deferral.Deadline`; retire F2110.
7. Green: FIBERS §12 probes, std-net `parked_eof`, std-http suites,
   `http_slow_route`, eval == native; `avra ir` identical.

**S3 — data components.** `key: value` (the 40-site ladder), typed
children, dynamic children, calls as children, named slot placement,
`check()`, `from`, bodiless instances, instances as declarations, the
reference card. No compile-time evaluation — the cheapest way to make
the face real.

**S4 — `cli avra { command build { … } }` over `@std/cli`.** Exercises:
the expand stage, `self.flags`, `run { }` slots, ancestor-owned relations.

**S6 — `model` and declaring blocks** (§10 item 1), after S5.

**S5 — `server` / `api` over `@std/http`.** Routes as child blocks,
typed formats as their paths, a typed handler slot per route, a
generated client. Its spelling (`server 8080 { get "/x" { … } }` vs
the vision's `GET "/x" -> …`) is designed after S3.

## 9. Decided, with the owner (2026-09-23)

| case | decision |
|---|---|
| block syntax | V2's ONE shared block shape; libraries write no grammar (a per-library grammar hook was proposed and dropped) |
| keyword | an imported component name opens its block; `component` stays optional |
| config | `key: value`; `=` goes |
| children | typed slots, auto-push; data components need no expander |
| expander | an `expand()` method on the component; the answer type is the effect |
| code slots | read the instance through `self`, typed fields; no injected names |
| paths on `self` | by SLOT name: `self.flags.release`, `self.args.target` — kinds never collide |
| declaring blocks | yes — a component may say its block is a record declaration (`model User { email: string }`), expanded as `@derive` over it |
| slot spelling | no parens: `run { }`, `on click { }`, `each email { }`; one superset block body, classified by the declaration |
| dynamic children | a DATA component's children may be produced by `for` / `if` / `match`, lowered to plain list code; a children area admits only settings, child blocks, code slots and those three — one exhaustive match, no catch-all; no `let` there (for now) |
| calls as children | any expression whose TYPE a slot takes (`order_row(o)`); the type is the guard, so `println(…)` still refuses |
| named slot placement | a slot's name opens a block for it (`header { … }`) when slots share a type |
| `check()` | a component method answering `List<Diagnostic>`, run at compile time over settled settings |
| `from` | `deploy staging from production { … }` — an instance built on another (`with` underneath) |
| growth | an exported component's new setting must carry a default; a required one added later refuses |
| folded in | canonical layout (one line with commas, or one per line without); `avra explain <component>` prints a reference card; `expands_to` golden helper for library authors |
| units | later, their own design (`5 seconds` stays `secs(5)` for now) |
| bodiless instances, instances as declarations, self-describing fields | folded in (§10 items 3, 6, 7) |
| parents, siblings, uncles | no back-pointers (a cycle never frees); the nearest common ancestor's `expand` owns every relation and hands children what they need |
| stages | substitution at the parse for one-`quote` expanders; the expand stage for the rest |
| `within` | a component in `@std/time`, spelled as today: `within ms(500) { … }` |
| inner words | contextual |

V2, concept by concept: `@comptime` → no mark (the stage is the call's) ·
`quote`/`~` → `quote`/`${}` · `@expand(f)` → `expand()` on the component ·
`config`/`children` → the same · `implements` → methods in the declaration,
and the `impl` an expander emits · `body: TokenStream` → `grammar w { }`
sublanguages · `comp_*` helpers → typed fields on `self` · `@unhygienic`
→ not needed · `bs2 expand` → `avra expand`.

## 10. The face — a gallery, and what it asks of the design

Components are how most people will meet Avra. Each sketch is a target
spelling (not built); the notes name what it needs beyond §1–§8.

```avra
view counter {                          // UI (spec Axis 23)
    state count: int = 0
    column {
        text "Clicked ${count} times"
        button "Add one" {
            on click { count = count + 1 }
        }
        for item in items {
            row { text item.name }
        }
    }
}

model User {                            // data (spec 22.1)
    email: string @unique
    name: string
    joined: Time @auto
    posts: List<Post>
}

queue emails of Email {                 // work
    retries: 3
    backoff: 5 seconds
}
worker sender {
    reads: emails
    at_once: 10
    each email { send(email) }
}
every 5 minutes { sweep_sessions() }

deploy production {                     // infra (spec Axis 19)
    region: "eu-west"
    service api { runs: app, replicas: 3, memory: 512 MB }
    database main { engine: postgres, size: 20 GB }
    secret stripe_key
}

agent support {                         // AI (spec Axis 21)
    model: "claude-sonnet-5"
    instructions: "Help customers with their orders."
    tool find_order
    tool refund { approval: required }
}
train sentiment {
    data: reviews
    epochs: 10
    on epoch { log(self.loss) }
}

test "adding two numbers" {             // tests (spec 24.1)
    expect add(2, 2) == 4
}
```

What the gallery asks for, beyond §1–§8:

1. **Declaring blocks.** `model User { email: string }` holds TYPES after
   the colon; `server app { port: 8080 }` holds VALUES. A component says
   which: a declaring component receives a record DECLARATION (fields,
   marks like `@unique`) and expands over it as `@derive` does over a type.
2. **A block body is one superset** — `key: value`, nested blocks, code
   slots, statements — classified by the component's declaration, never
   by the parser. That frees slot spelling: `on click { }`, `each email
   { }`, `run { }` (no V2 `run() { }` parens).
3. **Bodiless instances.** `text "hi"`, `secret stripe_key`, `tool
   find_order` — a head with no block.
4. **Dynamic children.** `for` / `if` / `match` among a DATA component's
   children, collected at run time (a UI list). An EXPANDING component's
   children stay static — its `expand` must see them.
5. **Units.** `5 seconds`, `512 MB`, `100 per minute` — a number followed
   by an imported unit word. Today it is `secs(5)`.
6. **Instances are declarations.** A top-level `queue emails` is module-
   wide and order-free, like a `const`, so `reads: emails` can name it
   before or after, and the reference is TYPED (a worker reads a queue).
7. **Self-describing fields.** A config field's `///` doc is what the
   editor shows and what a refusal quotes: "`retrys` is not a setting of
   `queue` — did you mean `retries`? (how many times a failed item is tried)".
8. **Not foreclosed, not built here:** UI reactivity (`state`, re-render —
   Axis 23), refinements (`where`), migrations. The mechanism must host
   them; each is its own design.

## 11. Projections, and apps across platforms

**Projections.** The answer type is the effect, one more time:
`fn project() -> List<Artifact>` runs at build time and the BUILD writes
each artifact under `build/<target>/` (the library does no I/O — the
purity law holds). `avra explain` lists them; each can be ejected. The
consumers: an app's platform shell (Xcode project, Gradle, `index.html`),
`model` (migrations, OpenAPI), `deploy` (K8s, Terraform), `api` (OpenAPI,
foreign clients). Designed now, built with its first consumer.

**Cross-platform apps: native Avra + renderers** (decided). The logic
compiles to each platform ONCE (LLVM for arm64 iOS/Android, WASM for the
web) — one meaning everywhere, never a translator per language (code
slots stay opaque, by §3). The UI is a data-component tree; a renderer
package per platform (`@std/ui-web`, `@std/ui-ios`, `@std/ui-android`)
draws native widgets; projections make the shell.

**Full apps are their own campaign, after S3** (decided): state (a view
is a function of its state answering a tree; the renderer diffs trees),
screens as typed routes, the `api` client, `model` on device, platform
needs projected. S3 owes it two hooks so nothing is foreclosed: a code
slot may WRITE its instance's state (`mut self`), and data components
stay plain records (cheap to rebuild on every change).

Gaps, each its own campaign: cross-compilation (PROBED: no target-triple
handling in the backend or runtime — host only) · `@std/meta.target()`
(compiler doc §7d) · state and re-rendering (spec Axis 23) · bridges to
Swift / Kotlin / JS (C only today).

## Status

- 2026-09-23 — designed and decided with the owner. S2 next.
