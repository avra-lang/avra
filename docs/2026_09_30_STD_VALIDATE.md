# @std/validate — one way to accept data

**Status:** design, 2026-09-30, not scheduled. Epic in the tasks db
(search "@std/validate").
**Goal:** the best validation library in any language, standalone, used
by every Avra package that accepts data: HTTP bodies, config files,
CLI arguments, env vars, database rows, agent tool calls.

## 1. The shape

Constraints are annotations on fields and types. An annotation is an
ordinary function over the value that answers a `Result`, so the set is
open and the compiler type-checks every use.

```avra
use @std.validate.{email, range, length, matches, one_of, pattern}

type Signup = {
    @email                       email: string
    @range(13, 130)              age: int
    @length(min: 12)             password: string
    @matches(password)           confirm: string
    @one_of(["free", "pro"])     plan: string = "free"
}

@length(min: 3, max: 32) @pattern(slug)
type Username = string

fn check(s: Signup) -> Issues {                 // cross-field rules, pure
    when { s.plan == "pro" && s.age < 18 -> issue("plan", "pro needs an adult") }
}
```

- `@length` on an `int` field is a compile error: `length`'s value
  parameter is a `string`, and the field is not.
- An annotation on a named type (`Username`) travels with the type:
  every field of that type is checked, and a `Username` value is a
  proof that it passed. Parse, don't validate.
- A literal is checked at compile time (`let u: Username = "a"` is
  refused where it is written). Everything else is checked at the
  boundary that decodes it.
- Messages are defaults with keys: `@range(13, 130, "you must be 13 or over")`.
- A new rule is a plain function: its first parameter is the value, its
  answer `Result<T, string>` (or `Result<T, Issue>` for a message key or
  a fix). It fails with `fail`, composes with `?`, and answers the value,
  so a rule may NORMALISE (trim, lowercase) and the field receives what
  it answered. The rule's name is the function's name. An annotation's
  arguments are the function's parameters after the value:

  ```avra
  export fn divisible_by(v: int, n: int) -> Result<int, string> {
      if v % n != 0 { fail "must be a multiple of ${n}" }
      v
  }
  // @divisible_by(15) minutes: int
  ```

## 2. One data model, every format

Every format decodes into ONE neutral `Value` tree, as serde does:
JSON, YAML, TOML, url-encoded forms, multipart, query strings, env
vars, CLI arguments, SQL rows. `decode<T>(v: Value) -> Result<T, Issues>`
is derived once per type at compile time, so a new format is one small
adapter that produces `Value`, and it inherits every rule.

## 3. Issues, all of them

A decode never stops at the first problem. Each issue carries:

| field | example |
|---|---|
| path | `signup.age` |
| rule | `range` |
| message | `must be between 13 and 130` |
| received | `9` (redacted for `@secret` fields) |
| fix | a structured suggestion: `plan: did you mean "pro"?` |

Coercion is an explicit policy: `strict` by default, `lax` when asked
(a query-string `"42"` becomes `42`). Pydantic's lesson.

## 4. Phases

1. Shape and field rules: pure, derived, runs during decode.
2. `check(t)`: pure cross-field rules on the typed value.
3. Effectful rules (`email not taken`): an explicit async step with a
   cost, never hidden inside a pure decode. Ecto's lesson.

## 5. Projections (one source, many outputs)

The rule set is data the compiler holds, so it projects to:

- JSON Schema and OpenAPI (constraints included)
- HTML form attributes and per-field error slots (the UI epic's forms)
- SQL `CHECK` constraints in `@std/sql` migrations
- `@derive(Arbitrary)` generators that produce valid AND near-miss
  invalid values, for laws and fuzzing
- human hints in docs and forms ("12 or more characters")

## 6. Prior art taken

| from | idea |
|---|---|
| Zod, Valibot, ArkType | the schema is the type; every issue with its path; compiled validators |
| Standard Schema | one trait every validator implements, so any framework accepts any validator |
| Effect Schema | one declaration decodes and encodes |
| Pydantic v2, msgspec | strict vs lax coercion; one-pass decode+validate speed |
| serde, garde, nutype | one data model for every format; derived rules; validated newtypes |
| Iron (Scala) | compile-time checks when the value is known, runtime otherwise |
| malli, CUE, Pkl | schemas as data, composable, exportable; constraints in the type |
| Ecto changesets | cross-field and effectful checks as their own phases |
| protovalidate (CEL) | rules portable across languages |

## 7. Beyond the prior art

1. **Rules are laws.** The compiler proves a type is inhabited
   (`@range(10, 5)` is refused), generates the smallest valid and
   invalid examples for docs and tests, and flags a rule that can never
   fire.
2. **Validation feeds the optimiser.** After decode, `age: Age` is
   KNOWN to be in 13..130: later checks are dead code, bounds checks
   vanish, and `if age < 10` is flagged unreachable.
3. **Validate while streaming.** Decode and validate compile into one
   pass over the bytes, fused with the HTTP framer: a 10 MB body with a
   bad field at byte 40 is answered 400 at byte 40, before anything is
   allocated.
4. **Trust as a type.** Decoded input is `Untrusted<T>` until validated.
   SQL, HTML, shell and path sinks refuse untrusted text. Validation is
   the only door from untrusted to trusted, so injection is a type error.
5. **The same rules run on both ends.** A client compiled from the same
   types (browser via wasm, another Avra service, an agent) validates
   before sending, with identical messages. A form shows the server's
   exact error before the request exists.
6. **Schema evolution is checked.** The compiler diffs a type's rules
   against the last release and classifies each change: widening is
   compatible, narrowing breaks old writers, a new required field breaks
   old clients. A breaking change at a public boundary needs a
   migration function, which is derived when possible.
7. **Services negotiate schemas at runtime (P2).** Two services exchange
   their types' rule sets; the intersection is computed, and a caller
   learns it would be refused before it ever calls.
8. **Model output valid by construction.** A type compiles to a grammar
   (Avra already has grammars). An LLM sampler constrained by it can
   only emit a valid `Signup`; MCP tool schemas carry every rule.
9. **Privacy in the type.** `@pii` and `@secret` fields are redacted in
   issues and logs, refused from log sinks by a law, and encrypted at
   rest by `@model`.
10. **Cost-ordered checks.** Each rule has a derived cost, so cheap rules
    run first and an expensive or effectful rule never runs on a value a
    cheap one already refused.

## 8. Prerequisites

- Annotations on a single record field (avra-8sb5.11.92).
- A Validates-kind annotation that answers a `Rule<T>` the typer checks
  against the annotated field's type.
- Trait impls over generic types (F2031), so `Rule<T>` and
  `Untrusted<T>` carry impls.
- Comptime evaluation of a rule over a literal (the const settler).

## 9. The stress test

The hardest validator we could write, as a checkout order. Each
numbered comment marks a place where §1–§8 as first written could not
say it, and the decision that fixes it.

```avra
use @std.validate.{…}

@tag("type")                                       // (1) a union's tag field
enum Payment {
    Card(@luhn @secret number: string, @expiry exp: string)
    Bank(@iban iban: string)
    Voucher(@pattern(voucher_code) code: string)
}

type Item = {
    @pattern(sku_format) @exists(products.sku)     // (2) effectful, batched
    sku: string
    @range(1, 99) qty: int
    @scale(2) @positive unit_price: Money          // (3) decimal money
}

type Address = {
    @one_of(countries) country: string
    @required_if(country in ["US", "CA"])          // (4) conditional
    state: string?
    @postal_for(country) postal: string            // (5) rule reads a sibling
}

type Comment = {
    @length(1, 2000) text: string
    @depth(max: 8) replies: List<Comment>          // (6) recursion bounded
}

@version(2) @renamed_from(1, "addr", "shipping")   // (7) evolution
type Order = {
    @length(1, 50) @unique(by: sku)                // (8) list-level rules
    items: List<Item>
    shipping: Address
    billing: Address? = null
    payment: Payment
    @keys(pattern: meta_key) @size(max: 20)        // (9) maps
    meta: Map<string, string> = {}
    notes: List<Comment> = []
    @after(now) deliver_by: Date?                  // (10) the clock is context
    @within(0.0, 0.2) discount: float = 0.0
    @file(types: ["image/png"], max: 5 MB) receipt: Upload?   // (11) files
}

fn check(o: Order, cx: Context) -> Issues {        // (12) context: role, now, locale
    when {
        o.discount > 0.1 && !cx.role.is(.Admin) -> issue("discount", "over 10% needs an admin")
        total(o.items) > cx.limits.order_max -> issue("items", "order over your limit")
    }
}

@patch("/orders/{id}")
fn amend(id: OrderId, change: Partial<Order>) -> Order? { … }   // (13) PATCH
```

The decisions it forced:

1. **Unions.** `@tag("field")` on an enum picks the wire discriminator.
   Each variant's payload fields take annotations like record fields.
2. **Effectful rules batch.** `@exists` runs in phase 3, and fifty items
   make ONE query, not fifty (the DataLoader pattern, derived).
3. **Money needs a real decimal.** `float` cannot hold cents exactly.
   Blocked on the core `decimal` type.
4. **Conditional rules.** `@required_if(expr)` takes an expression over
   sibling fields, type-checked at the declaration.
5. **Rules read siblings.** Annotation arguments may name sibling fields
   (`password`, `country`). The compiler resolves them, so a typo in the
   name is a compile error, not a runtime miss.
6. **Recursion and size are bounded at decode,** before allocation:
   depth, element counts, total bytes. This is the DoS door.
7. **Evolution is declared.** `@version(n)`, `@renamed_from`,
   `@since(n)`. The compiler diffs versions (§7.6) and derives the
   upgrade path from older payloads.
8. **List rules and element rules are different targets.**
   `@length(1, 50)` on the list; the element's own rules come from its
   type; `@unique(by: field)` for identity; `@each(rule)` when the
   element type is not yours.
9. **Maps** take `@keys(…)` and `@values(…)`.
10. **Nothing reads the world in phase 1.** `now`, the user's role and
    the locale arrive in a `Context`, so decoding stays pure and
    deterministic (the Reach law), and a test can pin the clock.
11. **Files** are a type (`Upload`) with streamed rules: the content type
    is sniffed from the bytes, never trusted from the header, and the
    size is refused at the byte that crosses it.
12. **`check` takes the context.** Role-dependent rules are ordinary
    code.
13. **PATCH.** `Partial<T>` makes every field optional and applies each
    field's rules when present, then re-runs `check` on the MERGED
    value, never on the patch alone.

Error paths reach into anything: `items[3].qty`, `payment.Card.exp`,
`notes[0].replies[2].text`, `meta["x-y"]`.

## 10. Other APIs and services

**Inbound.** A route's typed parameter is decoded and validated before
the handler runs. A refusal is RFC 9457 problem+json with every issue:

```json
{ "type": "validation", "status": 422,
  "errors": [{ "path": "items[3].qty", "rule": "range",
               "message": "must be between 1 and 99", "received": 0 }] }
```

**Outbound: never trust a third party.** A client call decodes and
validates the RESPONSE too: `api.get<Weather>(url)?`. A provider that
changes its shape yields a typed error naming the path, never a crash
three functions later. External data defaults to `lax` with every
coercion logged.

**Importing other people's schemas.** A derive reads an OpenAPI, JSON
Schema, protobuf or GraphQL document at compile time and declares the
Avra types with their rules: `@from_openapi("vendor/stripe.json")`. A
vendor's constraints become compile-time types.

**Exporting ours.** JSON Schema and OpenAPI from the types; MCP tool
schemas for agents; and generated Zod and TypeScript types, so a
TypeScript front end runs the same rules with the same messages.

**Avra to Avra.** Services share a types package. The typed client
validates before sending, and the server validates again at its
boundary. Versions negotiate at connect time (§7.7).

**Queues and events.** A consumer validates each message. A refusal goes
to a dead-letter record carrying its issues, never a silent drop.

**Databases.** Rules project to SQL `CHECK` constraints in migrations.
Rows are validated on read, so drift between the database and the type
surfaces as issues rather than wrong answers.

**Config and environment at start-up.** Every issue is reported at once
and the process refuses to start. A misconfigured deploy fails in one
line, not at the first request.

**Agents.** Tool calls are validated. On refusal the issues go back as
structured feedback, so the agent corrects itself in one turn.
Grammar-constrained sampling (§7.8) makes most refusals impossible.

**One interop trait.** Any validator implements `Validates<T>` (Standard
Schema's idea), so a framework accepts any rule set, not only this one.

## 11. Every decision as code

Marked **[basics]** when it is part of the first build, **[later]** when
it follows once the basics land, and **[talk]** when the syntax is
aspirational and needs a conversation with the owner before anyone
builds it.

**Field rules** [basics]
```avra
type Signup = {
    @email            email: string
    @range(13, 130)   age: int
    @length(min: 12)  password: string
    @matches(password) confirm: string     // a typo in `password` is a compile error
}
```

**Rules on a named type** [basics]
```avra
@length(min: 3, max: 32) @pattern(slug)
type Username = string
```

**Unions with a tag field** [later]
```avra
@tag("type")
enum Payment {
    Card(@luhn @secret number: string, @expiry exp: string)
    Bank(@iban iban: string)
}
// {"type": "Card", "number": "4242…", "exp": "12/27"}
```

**Effectful rules, batched** [talk]
```avra
type Item = { @exists(products.sku) sku: string, @range(1, 99) qty: int }
// 50 items → one query
```

**Money** [later — blocked on the core `decimal` type]
```avra
@scale(2) @positive unit_price: Money
```

**Conditional required** [talk]
```avra
@required_if(country in ["US", "CA"]) state: string?
```

**A rule that reads a sibling** [basics for `@matches`, talk for the rest]
```avra
@postal_for(country) postal: string
```

**Recursion bounded** [later]
```avra
@depth(max: 8) replies: List<Comment>
```

**Versions** [talk]
```avra
@version(2) @renamed_from(1, "addr", "shipping")
type Order = { shipping: Address, @since(2) gift: bool = false }
```

**List rules vs item rules** [basics for `@length`, later for `@unique` and `@each`]
```avra
@length(1, 50) @unique(by: sku) items: List<Item>
@each(email) cc: List<string>
```

**Maps** [later]
```avra
@keys(pattern: meta_key) @values(length(max: 200)) @size(max: 20)
meta: Map<string, string>
```

**The clock and the user through a context** [later]
```avra
@after(now) deliver_by: Date?
decode<Order>(json, cx: Context { now: fixed_time, role: .Admin })
```

**Files** [talk]
```avra
@file(types: ["image/png"], max: 5 MB) receipt: Upload?
```

**Cross-field rules** [basics without context, later with it]
```avra
fn check(o: Order, cx: Context) -> Issues {
    when { o.discount > 0.1 && !cx.role.is(.Admin) -> issue("discount", "over 10% needs an admin") }
}
```

**PATCH** [talk]
```avra
@patch("/orders/{id}")
fn amend(id: OrderId, change: Partial<Order>) -> Order? { … }
```

## 12. Other APIs and services as code

**Inbound request, refused** [later — rides the HTTP DX sub-epic]
```avra
@post("/orders")
fn place(o: Order) -> Created<Order> { … }
```
```json
{ "status": 422, "errors": [{ "path": "items[3].qty", "rule": "range",
  "message": "must be between 1 and 99", "received": 0 }] }
```

**Calling someone else's API** [later]
```avra
let w = http.get<Weather>("https://api.weather.com/today")?
```

**Importing their schema** [talk]
```avra
@from_openapi("vendor/stripe.json")
module stripe
```

**Exporting ours** [later]
```sh
avra export schema Order --as json-schema > order.schema.json
avra export schema Order --as zod        > order.ts
```

**Avra to Avra** [later]
```avra
let api = client(orders_app, "https://orders.internal")
api.place(order)?
```

**Queue consumer** [talk — no queue package exists]
```avra
on queue("orders") { msg: Order -> fulfil(msg) }
```

**Database** [later — rides `@model`]
```avra
@model type Order = { @range(1, 99) qty: int }   // CHECK (qty BETWEEN 1 AND 99)
```

**Config at start-up** [basics for JSON and TOML]
```avra
let cfg = decode<Config>(toml_file("app.toml"))?
```

**Agents** [later]
```avra
@tool fn refund(order: OrderId, @range(0.01, 500.0) amount: float) -> Refund { … }
```

## 13. The first build

The basics, and nothing past them until the owner has seen it run:

1. `Issue` with a path, rule, message and received value; all issues,
   never the first.
2. The core rules as plain functions: `email`, `range`, `length`,
   `pattern`, `one_of`, `matches`.
3. The neutral `Value` tree, `decode`, strict and lax coercion.
4. JSON and TOML adapters.
5. Annotations on record fields and named types, type-checked against
   the field, and a derive that makes §11's `Signup` work as written.
6. `check(t)` for cross-field rules, without a context.

## 14. What the first build chose

Recorded as each decision landed on `lane/validate`.

- **Rules are plain fns answering `Result`** (the owner's shape). The
  framework reads a `string` or an `Issue` refusal through one trait,
  `Refusal`, so `ruled(d, slot, "range", range(v, 13, 130))` takes
  either. `Rule<T>` as a fn-type alias was built first and retired;
  it needed no F2031 either way.
- **Within one field, rules run in order and stop at the first
  refusal**, because each reads what the last one answered. Across
  fields, every issue is kept.
- **`length` is `length<T: Counted>`.** `string` is `Counted` today.
  A list is not: `impl Counted for List<T>` is F2031, so `@length` on
  a list waits on it (ticketed). A field of any type without a length
  is refused where the rule is used: "`int` does not implement
  `Counted`".
- **The derived entry point is `Signup.decode(v)`.** `decode<Signup>(v)`
  needs a static trait fn reached through a type parameter, which the
  language lacks (sugar backlog).
- **Bounds are the parser's, not only the decoder's.** `@std/json`
  now refuses nesting past 128 levels at the opener; before, 200,000
  nested `[` crashed a native program. The decoder bounds depth and
  list length again for every other format.
- **A field written twice is refused**, in both coercion modes: a
  reader that took the other copy would see another value.
- **A secret stays secret all the way down**: a secret list's
  elements and a secret object's fields never show what they received.
- **An annotation's arguments are expressions, and a reader splices
  the call.** `@range(13, 130)` on a field is recorded as the template
  `range(${value}, 13, 130)`, marked where the `@` stands; `@std/meta`'s
  `Annotation.call` carries it and `applied(a, value)` fills it. The
  `Decode` derive splices it over the value it read, so the ordinary
  typer checks it there and every refusal points at the annotation:
  a rule on the wrong type, a misspelled rule, a sibling name that
  does not exist. No second typing law exists for rules.
- **A rule on a declaration is data, not a call.** An annotation whose
  first parameter takes a VALUE rather than a declaration (`Fn`,
  `Type`, `Named`) is not run at compile time; on a named type it
  checks the value the type wraps, and on a record it is a
  **cross-field rule** over the whole value, run once every field has
  passed — the `check(t)` of §4, spelled as one more plain fn:

  ```avra
  fn adult_for_pro(s: Signup) -> Result<Signup, Issue> {
      if s.plan == "pro" && s.age < 18 { fail issue("plan", "pro needs an adult") }
      s
  }

  @derive(Decode) @adult_for_pro
  type Signup = { … }
  ```
- **`@derive(Decode)` is written.** §1's type carries no derive; the
  derive is the visible door (P7), one line.
- **JSON has a direct path, and the tree path explains it.**
  `T.from_json(text)` walks the bytes into the record, one pass, no
  tree; where the text is not JSON, a bound is passed or the coercion
  is `Lax`, it steps aside and `T.decode(from_json(text)?)` answers —
  so every refusal of malformed input is the tree's, word for word. A
  differential test holds the two to the same answer over generated,
  truncated and mutated payloads.
- **A field's rules run where it is read**, up to the first that names
  a sibling; that one, and the rules after it, run once every field is
  read, so a sibling reads what its own rules answered.

## 15. Speed

The bar: decode plus every rule at serde_json + garde speed or better,
and a refusal within 1.5x of an acceptance. `tools/bench/validate/run.sh`
is the receipt: §11's Signup (eight fields, a list of named strings, a
nullable named field, a cross-field rule) read from the same two files
by Avra, by Rust (serde_json straight into the struct, then garde) and
by C (yyjson, then hand-written rules over views into its document —
the floor, building no messages). Separate processes on one Sprite
(x86_64 Linux), interleaved round by round, median of five, ns per
payload. `instructions.sh` counts the same rows under callgrind — the
number no neighbour's load moves, so it is the one to compare.

| row | Avra before | Avra after | Rust | C |
|---|---|---|---|---|
| decode + rules, valid (ns) | 10185 | 1494 – 2041 | 1689 – 1756 | 200 – 224 |
| decode + rules, refused, every rule (ns) | 15294 | 5017 – 6674 | 2139 – 2561 | 197 – 215 |
| decode + rules, valid (instructions) | — | 20404 | 20057 | 2999 |
| decode + rules, refused (instructions) | — | 59161 | 23862 | 2990 |
| parse only, valid (ns) | 3869 | 3869 | 600 | 154 |
| tree path: `Value` + decode, valid (ns) | 10185 | 7821 | — | — |

Two ranges are two Sprites' runs; the ratio to Rust moved between
0.88x and 1.16x with the machine, while the instruction counts sat at
parity. Rust's refused row reads a copy of the struct without
`deny_unknown_fields`, so serde reaches garde and every rule's issue is
built (the strict struct stops at the first shape error, ~850 ns, one
issue); Avra reports all eight issues, each with its path, received
value and did-you-mean fix.

**What each lever bought** (instructions per accepted decode unless
said):

- *The derived direct decoder* (`T.from_json`, json.av): no `Json` and
  no `Value` tree; keys matched by length then bytes; values read where
  they stand. 10185 -> ~3700 ns.
- *Allocation-free hot rules*: `codepoint_count` stopped allocating a
  step per character (a `length` rule on a 21-character password was
  938 ns alone), the email check became one class-table scan, a record
  is built once instead of copied per present default. -> ~1900 ns.
- *One scan per plain string* (`plain_end`) and no allocating sort
  check: 20368 -> 15536 instructions without rules.
- *The refusal*: rules run where a field is read (so a payload in
  declaration order sorts nothing), paths held nearest-first and filed
  in place, the root path static, a words-only refusal built as one
  issue, bounded did-you-mean: 132470 -> 59161 instructions.

**What blocks the rest.** The accepted path meets Rust. The refused
path does not meet 1.5x (it is 2.9x): each issue costs ~5000
instructions against garde's ~550, of which roughly a third is freeing
what it allocated (105 boxes refused, 14 accepted) and the rest is
boxes, reference counts and calls around small work — interpolating a
message alone is ~1100. The asks that close it are filed under the
survey epic: an arena per decode (freed in one step), the Bytes rows as
inlined hot leaves with cross-file inlining for release builds, a text
view that shares its parent's box, interpolation without a parts list,
and one-word payload enums unboxed. The plain `parse` is its own
follow-up: the scans it could stand on now exist.
