# @std/validate — one way to accept data

**Status:** design, 2026-09-30, not scheduled. Epic in the tasks db
(search "@std/validate").
**Goal:** the best validation library in any language, standalone, used
by every Avra package that accepts data: HTTP bodies, config files,
CLI arguments, env vars, database rows, agent tool calls.

## 1. The shape

Constraints are annotations on fields and types. An annotation is an
ordinary function that answers a `Rule<T>`, so the set is open and the
compiler type-checks every use.

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

- `@length` on an `int` field is a compile error: `length` answers
  `Rule<string>`, and the field is not a string.
- An annotation on a named type (`Username`) travels with the type:
  every field of that type is checked, and a `Username` value is a
  proof that it passed. Parse, don't validate.
- A literal is checked at compile time (`let u: Username = "a"` is
  refused where it is written). Everything else is checked at the
  boundary that decodes it.
- Messages are defaults with keys: `@range(13, 130, "you must be 13 or over")`.
- A new rule is a function: `fn slug() -> Rule<string> { rule { it -> … } }`.

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
