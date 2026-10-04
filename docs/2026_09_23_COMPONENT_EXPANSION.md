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

export component within(limit: Code) {           // a VALUE head
    body: Code                                   // the block IS the field
    fn expand() -> Code {
        quote {
            {
                let limit: Duration = ${self.limit}   // the head's law, named
                let outer = avra_fiber_within(limit.ms)
                defer avra_fiber_within_end(outer)
                ${self.body}
            }
        }
    }
}
```

- A FIELD'S TYPE IS ITS MEANING. `Code` (or `Stmts`) holds the user's
  code, spliced where the template writes it; any other type is a value
  (S3). So `within`'s head is `Code`, and a typed `let` in the template
  states the law the user meets: "`limit` declares `Duration`, this is
  `int`", at the user's head.
- fields are bare lines (`name: T = default`); `config { }` still parses
  and retires with S3's `key:` ladder.
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
  `component cli avra { … }` keeps working with the keyword. The lexer
  tags it `COMPONENT`, and `NAME` still accepts it — a `use` line imports
  it and a property wears it; F2081 refuses a binder that does.
- every exported component is a block word; one its instance cannot stand
  in for (no block field, an `expand` that computes) refuses AT THE
  INSTANCE in the library's words. An instance inside the component's own
  module is no instance (the pre-scan reads other modules' parses only,
  so a held sibling is never parsed) — pinned, one refusal.
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
- WRITTEN TYPES TOO: a template's `let limit: Duration` resolves in the
  library — a user's own `Duration` never reaches it — while a type that
  came through a HOLE (`TypeRef.spliced`, a derive's `${t}`) resolves
  where it lands. A copied template keeps its own file's spans, so its
  errors point home, and range ownership reads it as the instance's.
- No injected names: a code slot reads the instance through `self` — the
  expander makes the record type (`flag release` → `release: bool`) and
  the slot becomes its method. To verify in S3: the user's `self` binds to
  the generated method's receiver (a receiver is a seat, not a name).

## 6. Refusals

As built in S2 (goldens: features/components/tests):
- at the LIBRARY — F2112 "`expand` answers the code an instance becomes"
  · F2113 "the template of `made` reads `self.body` twice" (code runs
  where the template writes it, once; bind it with `let` to reuse it).
- at the INSTANCE — "`lim` writes its head value before its block" ·
  "an instance of `lim` writes its block after its head" · "`made`
  declares no field for an instance's block" · "the `expand` of `made`
  is not one `quote` over its own fields" · "`two` declares 2 head
  fields, and its instance writes one value".
- NAMES — F2081 "`lim` is a block word here, and nothing else in this
  file may wear it" (one voice for sublanguages and components).
- TYPES — the expansion is typed as ordinary code; the template states a
  head's law with a typed binding. A template's own operators can still
  surface (`+` needs `int`), at the user's block — the author's cue to
  type what the block must answer.

Still to design (S3+): a child no slot takes · `expand() -> Result<Decls,
Diagnostic>` with `refuse_as_at` for a library's own meaning laws.

## 7. Visible (P7), escapable (P8), fast (P4, P14)

- `avra expand <file>` notes every instance's expansion under its
  statement: "// `within` (from @std.time) expands to:" and the code.
- A NOTE, NOT PASTEABLE SOURCE — corrected from this doc's first draft,
  which promised the printed expansion compiles. A template's names are
  the provider's (`within` calls `@std/time`'s own extern) and a user's
  file cannot spell them: Avra has no qualified expression paths. RECORDED
  TRIGGER: when they land (ROADMAP sugar backlog, "A PRELUDE, or QUALIFIED
  EXPRESSION PATHS"), print qualified names and round-trip it.
- `avra explain within` (a block word) — S3, with the reference card.
- the expansion is ordinary code, no runtime layer. RECEIPT (`avra ir`,
  S2): `within`'s step is `call avra_fiber_within`, the body, `call
  avra_fiber_within_end` — the core form's instructions exactly. Getting
  there took one general change: a `defer` of ONE call answering nothing,
  every argument a scalar literal or capture, is a direct call at each
  exit (`Deferral.Direct`) — no closure box, so every such `defer` in any
  program got cheaper, and the core's `Deferral.Deadline` was its one
  special case. `server`: `tools/bench` on a Sprite (S5).

## 8. The slices

**S2 — `within` leaves the core.** DONE 2026-09-23. Exercises: a value
head, a code slot, an imported block word, substitution at the parse.
AS BUILT, beyond the plan: origin runs cover statements and patterns
(a template's `let` binders are its own — they were not); written types
resolve where written; the pre-scan reads every `use` the parse BUILT,
so a line only the word can parse no longer hides its own import; the
direct `defer`. Red team: ~95 programs over the eight classes; one wrong
answer (a template reading its block twice ran it once — now F2113), six
poor refusals, one cascade, all tested.
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

**S3 — data components.** THE BODY, settled here: one rule for every
data instance — `key: value` settings, then any statement. The
settings become the record's fields; EVERYTHING ELSE stays as written
and becomes `collect { … }`, the one children slot's value:
- `collect { … }` is CORE (lists feature): a list of every value its
  statements would discard, in the order they ran. `for`, `while`,
  `if`, `match` and `let` inside it are the ordinary statements,
  lowered as always — the one hook is the expression statement (a
  kept value joins the open `collect`), typed by the list literal's
  own law and lowered by the comprehension's growth. A lambda's
  statements are its own.
- Why core and not a component: "does this statement leave a value?"
  is a TYPING fact, and a component expands at parse. A library
  component cannot tell `o.id` from `println(…)`.
- A component with more than one children slot places them by name
  (`slot_name { … }`, each its own `collect`); one slot takes the body.
- The instance desugars to its record literal, so every type law is
  the record's and the list's, and nothing new runs downstream.
Heads: a component with head fields takes a VALUE (`text "hi"`); one
without takes a NAME (`cli avra { … }`), which BINDS at statement
position and fills a declared `name` field; as a member of another
instance it is a child and binds nothing. A block is optional
(`secret stripe_key`). `c from base { key: v }` is `base with { … }`:
settings only — a child there refuses, its children are its base's.
`on click { }` — DEFERRED to APPS, the reason corrected by probe
(ui-onflag): the grammar LANDED (`on` is a soft keyword, #253) and the
body becomes a nullary lambda whose captures resolve and lift (#254),
so the wall is neither the spelling nor capture EXTRACTION. It is the
message VALUE: the event field is `dyn Messages?`, a lambda is no
implementor, and making `on` a body DECLARATION does not change that.
A body declaration is a `collect` of record VALUES built at the parse
(`command`'s flags expand to `flags: collect { flag json { … } }`), not
a declaration-minting stage; the only declaration generator
(`compiler/expand.av`) is driven by an annotation on a DECLARATION and
reads a `Type`'s shape, never an expression's captures, and a
computing `expand()` is refused per instance ("is not one `quote` over
its own fields"). The bridge is a synthesized `Messages` implementor
plus a per-file dispatcher — an expansion stage AFTER typing (S6),
which the body-declaration spelling reaches at no earlier point.
S3a AS BUILT: a component with no `expand` is `Instancing.Record`; its
instance is an `Expr.Component` whose view is the record literal (so
the printer keeps the written form and `avra expand` shows the
literal). Head by position; settings by name; the body's other
statements `collect`ed into the one `List` field no setting names; a
headless record named at a statement binds (`grid report { … }` is a
marked `let`) and fills a `name` field when it declares one. Every
field law is the record literal's own (unknown, twice, missing, wrong
type). Two general fixes rode along: a list literal (`[…]`, a
comprehension, `collect`) RE-HEARS its seat — one typed before its
seat's type was known is typed again under it, so a stranger is
refused where it stands and a `dyn` slot boxes each element; and
`dyn` acceptance asks the trait DECLARATION, so a user need not
import a provider's trait to fill its `List<dyn T>` field.
S3b AS BUILT: a kept LIST spreads inside `collect` (a comprehension
child is its rows), unless the collect holds lists; a NAMED instance
(`secret api`) is kept as a child at any depth and binds for its
siblings; a record with two `List` fields takes each by name as a
setting — `left: collect { … }` — no slot sugar, since `name { … }`
collides with a struct literal. `from` NEEDS NO SYNTAX: `production
with { region: "eu" }` is exactly its meaning (settings only, children
the base's), and reserving `from` would break ~166 names in the tree.
S3c AS BUILT: `fn check() -> List<Diagnostic>` (F2114 holds the
shape) runs at compile time over each instance that reads only what
the compiler knows — literals, declarations, `const`s and what the
instance binds itself; one built from a local, a parameter or `self`
is a run's value and is not checked. It is a hidden `instance.check()`
the builder mints and typing walks; lowering SETTLES it as a `const`
expression, decodes the answer with the annotation crossing's
`Diagnostic` reader, and speaks each at the instance (F2115); a check
that traps says it did not run. The hole it found: a component's own
fns were signed and never REGISTERED as methods — callable nowhere,
though the feature's doc said they were — fixed for parsed and held
files alike.
S3d AS BUILT: every `component LanguageFeature f { k = v }` in the
compiler is `LanguageFeature lists { k: v }` now — the binding names
the feature and fills its `name` field (an explicit `name:` setting
wins, as `quote_lit` needs, `quote` being a keyword). The legacy
instance statement, its builder and printer arm, and the `config { }`
block are gone; `config` is a name again. Inside the component's own
module an instance is its record literal (`Cfg { name: "one" }`), as
`features/mod.av`'s `feature()` and the tests now write it.
S3e MOVED to the docs campaign (owner, 2026-09-23): a component's
reference card is one declaration kind's docs, and belongs with how
every declaration's docs are generated, not ahead of them.
Sub-slices: S3a heads, settings, bodiless, the named binding (DONE) · S3b
children (typed, dynamic, calls, named placement) · S3c `check()`,
`from` · S3d the `key: value` ladder over the 40 legacy sites, `config
{ }` retired · S3e `avra explain <component>` (the reference card).
The rest of the plan, unchanged: `key: value` (the 40-site ladder), typed
children, dynamic children, calls as children, named slot placement,
`check()`, `from`, bodiless instances, instances as declarations, the
reference card. No compile-time evaluation — the cheapest way to make
the face real.

**Later — typed expansion.** An `expand` that SEES its body's types
(Zig comptime, Scala 3 macros): typing pauses, library code rewrites
the typed body, the answer is typed again. It would let `collect` move
out of core. RECORDED TRIGGER: the first component whose meaning
depends on an expression's type that `collect` and a record literal
cannot express.

**S4 — `cli avra { command build { … } }` over `@std/cli`.** AS BUILT
(owner chose data components over the expand stage, 2026-09-23):
`@std/cli`'s data model IS five components — `flag`, `option`, `arg`,
`command` (whose `run: dyn Runnable` is its behaviour) and `cli`. Three
general pieces carried it, none CLI-specific:
- ROUTING: a child INSTANCE lands in the `List` field its component is
  the element of (`flag …` in `flags`, `arg …` in `args`), read off the
  provider's declared field types; any other child needs the one open
  field. A setting of a field lists first, its routed children after.
- DECLARED INSTANCES: an EXPORTED top-level instance is a declaration
  — a `const` built once per run at its first read (`lower_root`'s
  `once` body), so it may hold behaviour. `export command check { … }`
  in commands/check.av, `use commands.{check}` and `cli avra { check
  … }` in main.av: the `_command()` wrappers are gone. A plain
  top-level instance stays a statement (a script's instance may read
  its `let`s).
- A `const` holding a fn or `dyn` ANYWHERE inside is refused (F2063)
  with the way to build it — it reached a lowering defect before.
A reserved word or keyword (`level`, `grammar`) cannot bind, so such an
instance is named by its `name:` setting (`command language { name:
"grammar" … }`). DEFERRED, with the trigger: `run() { … }` code slots
and a typed `self.target` per command need the EXPAND stage — the first
user of S6's declaring blocks.

**S6 — models are types, not components.** DECIDED WITH THE OWNER
(2026-09-24). A component instance is always a VALUE (a server, a
route, a layer, a command); a TYPE is always declared with `type`, and
generated behaviour comes from `@derive` — one engine, one spelling:

```avra
@model
type User = {
    @unique email: string
    name: string
}
```

`@model` is a library ANNOTATION FN bundling derives (`Model.derive(t)
.concat(Json.derive(t))`) — SwiftData's `@Model`. A trait's `derive`
is `static fn derive(t: Type) -> List<Directive>` with an optional
`marks`, held to that contract where the trait is declared (F2134) and
at each `@derive` (F2072, F2066); an unclaimed mark is F2092. The
generator sees the declaration's SHAPE — fields, spelled types, marks,
`///`, annotations — and its output is typed with the program, so a
model's generated code may name any other model (joins). Every model at
once is `collect models = impl Model in closure` (avra-8sb5.28).
CONSIDERED AND DEFERRED: `model User { … }` as a word — the same shape
as a VALUE component with a TYPE after each colon, so a reader could
not tell a declaration from a value without looking the word up; it
can be added later as "the annotation, spelled as a word".

Slices: **S6b** `@std/db` over @std/sqlite with `@model` (table,
insert, find) — its first work: an annotation fn calling a trait's
static `derive` (F2033 today: a trait's static fn is taken as generic
over `Self`), and `@model` over a multi-line record with a field mark
(a parse failure to diagnose). **S6c** a computed child placed by its
TYPE — a typer rule, since a derive never sees types. Supertraits
(`trait A: B`) are filed as avra-8sb5.43.

**S5 — `server` / `api` over `@std/http`.** DECIDED WITH THE OWNER
(2026-09-23): the user writes `get "/robots/{id: RobotId}" { req ->
state_of(req.params.id) }` — a route's handler names only what it
wants. PATH PARAMETERS LIVE ON THE REQUEST (`req.params.id`, typed by
the route's pattern), never as bare names in the body. The MECHANISM
is general and landed first — THE OFFER: a lambda filling a seat of
ONE record takes the record's fields by NAME, any subset and order
(`{ db, req -> … }`); a lone parameter no field wears is the record
whole; no parameters takes nothing; a name not offered is F2117,
naming what is. A component author declares ONE handler slot
(`handle: fn(Offer) -> dyn Respond`) and every form a user writes fits
it. Matching on the body's form (`quote` patterns in a computing
`expand`) stays S6's escape hatch, never the default.
Routes as child blocks,
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
| `from` | REVISED: `production with { … }` — the existing `with`, no new word (a keyword would reserve `from` everywhere) |
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

- S1 data records, S2 templates, S3 `collect` + `check`, S4 `@std/cli`
  over components and exported instances as declarations — landed.
- The offer rule — a lambda takes an offered record's fields by name
  (F2117) — landed.
- S5 piece 1 — a `Format` head mints its pattern's record; an instance
  body takes a `req ->` head; zero-hole patterns match whole (F2119) —
  landed.
- S5 piece 2 — `Request<P>`, trait impls on scalars (`Respond`),
  `get`/`post`/`put`/`patch`/`delete`/`group`, `server` and `layer` —
  landed.
- `alias Name<T> = <type>` — a shorthand, the same type (F2121);
  `type` over a fn shape is opaque at seats like any name; `Handler`
  in `@std/http` — landed.
- A named instance is listed by its name and lands in the slot its
  component fills — declared anywhere in the file, or imported
  (`server web { auth  get … }`); a record's one fn field takes a body
  written as a fn (`layer auth { req, next -> … }`) — landed. A
  computed value (`let a = …`) is not placed by its type: that waits
  for typed expansion (S6); `layers: [a]` sets it by name.
- `req.under(prefix)` (whole segments, the router's law) and typed
  holes (`{id: int}` in patterns, grammars and routes; a span that is
  no int fails the match) — landed. S5 is complete.
- S6: the expand stage and declaring blocks.
