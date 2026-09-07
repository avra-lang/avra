# Typed routes — one format, two directions

Status: proposed semantics, 2026-09-06. Companion to
`2026_09_06_STD_HTTP_DESIGN.md`. No new syntax or runtime behavior is
implemented by this document.

## The inherited idea

`../forge-crafting-intepreters/docs/2026_06_30_STRINGS_FROM_THE_FUTURE.md`
already proposes typed string captures (Part III), bidirectional formats
(Part V, Move 1), streaming recognition (Move 4), and route overlap analysis
(Move 5). These are the foundation of this design, not discoveries of this
HTTP lane. The older HTTP vision already supplies declarative routes and
typed request handling.

The connection is direct: a route is a typed format. Incoming matching
extracts values; outgoing construction encodes those same values. The route
contract supplies both operations and their schema.

Illustrative spelling, following the document's named-format example:

```avra
route IdeaPath = "/ideas/{id: IdeaId}"

let fields = IdeaPath.parse("/ideas/42")?
let target = IdeaPath.print(id: fields.id)
```

`IdeaId` needs a declared component codec; its name does not imply an integer
representation. Both construction and parsing preserve its nominal identity.
A domain ID also does not prove the caller has authority over that resource.

The route in a server could then read:

```avra
GET "/ideas/{id: IdeaId}" -> ideas.get(id)
```

The exact declaration, import, and named-operation spelling remains to be
reconciled with component expansion. Pattern captures are bindings; ordinary
string interpolation evaluates expressions. A registered format parser must
keep those contexts distinct. Literal braces must have an explicit escape.

## URL structure belongs in the format

Generic substring extraction is insufficient. The format must know which
component it is reading or producing:

- Path captures consume one segment unless a tail capture is explicitly
  declared. A delimiter in capture data cannot create another segment.
- Query parameters are keyed fields whose wire order is independent of their
  declaration order. A typed query record supplies field names, codecs,
  cardinalities, defaults, and missing-value rules.
- Header fields have their own name, repetition, and encoding rules. They
  cannot reuse a URL component codec merely because both carry bytes.
- Body decoding selects a representation and has its own consumption lifetime.

Proposed query laws: a scalar occurs at most once, a list preserves repeated
values in encounter order, a required value must be present, an optional value
preserves absence, and a default applies only to absence. Invalid input is
never converted to absence or replaced by a default. Missing, bare-key, and
empty-value inputs remain distinguishable until the field codec judges them.
Unknown-field handling is a declared schema policy; compatibility and signed
requests can need different policies. A literal plus and a space are distinct
in generic URI syntax; form decoding is a separately selected codec.

Split URI components before decoding reserved delimiters; decode each value
once. The router, authorization, cache keys, and handler must consume the
same resolved target, with the raw target retained separately for signatures
and diagnostics. [RFC 3986 §2.4](https://www.rfc-editor.org/rfc/rfc3986.html#section-2.4)

The typed route API should use a portable segment domain that excludes slash,
backslash, control characters, and complete dot segments after decoding.
This is a proposed application-route policy, not the URI protocol grammar.
Raw URI values remain representable at the protocol layer. Unsupported
values must be rejected when constructing a segment value, so a route printer
can be total over its accepted domain. Legitimate broader addressing requires
a separate declared policy with an explicit proxy/normalization contract.

## The round-trip law must state its domain

For values admitted by a route and its codecs:

```text
parse(print(value)) = value
```

For accepted wire input:

```text
print(parse(wire)) = canonical(wire)
```

The second law is not byte identity: numeric spellings, percent-encoding,
query order, and omitted defaults can have more than one accepted spelling.
Canonicalization must be defined from the declared codec's semantics, and
raw-input fidelity requires retaining raw input. Query list order is semantic
unless its schema explicitly says otherwise.

This is a restricted bidirectional format. An arbitrary custom parser or
printer does not come with an inverse proof. Static overlap checking and
complexity guarantees likewise apply only to analyzable codec descriptions.
Opaque custom code receives an explicit unknown result from proof queries;
unknown is never reported as proven. The URI Template standard also limits
reverse matching to suitable delimiter structures.
[RFC 6570 §1.4](https://www.rfc-editor.org/rfc/rfc6570.html#section-1.4)

## HTTP framing stays byte-oriented

The strings vision's sample `parse_http` is an illustration of typed patterns,
not a production framing design. Converting the entire received buffer to
UTF-8 and trimming lines loses the distinction between protocol syntax and
content. HTTP/1.1 parsing must establish message structure over octets before
applying text interpretations to individual elements.
[RFC 9112 §2.2](https://www.rfc-editor.org/rfc/rfc9112.html#section-2.2)

A single-value header map also cannot preserve all repeated fields. The
protocol layer must retain occurrences and apply each field's combination
and framing rules before a typed projection is available. Syntax recovery
used for editing source code is not permission to recover an ambiguous
network message and process it.

## Performance obligations

Compile a static route set once, sharing prefix recognition across routes.
Measure dispatch as route count and target length grow; scanning every route
independently does not meet the intended scaling target. No backtracking for
the built-in path grammar. Typed numbers parse directly from bounded spans
with checked overflow. Parse query structure once, then project its fields.
Enforce size and field-count bounds before expensive allocation or decoding.

The intended fast path reads unescaped captures as views. A view must retain
or borrow the buffer owner and survive only within its documented lifetime.
An escaped capture may need decoded storage; an escaping tiny view must not
accidentally pin a large receive buffer indefinitely. Allocation and retained
memory are separate measurements. SIMD scanning is a benchmark candidate,
not an implied consequence of declarative syntax.

The string representation decision in `2026_09_05_STRING_REPRESENTATION.md`
supersedes the older document's SSO premise. Ordinary strings are headered
boxes, not arbitrary interior pointers. Owned spans/views therefore need a
real representation and language lifetime contract. This design does not
silently change strings to ropes or describe copying substring operations
as zero-copy.

At source base `85e6344`, `features/enums/builders.av` builds a string pattern
as `Pat.Lit(Expr.StrLit(...))`; typed extraction is not represented by that
builder. The generic grammar executor has parameterized captured values,
but a generic executor alone supplies neither bidirectional printing nor a
resumable network parser. These are source observations, not executed probes.

## Baseline probes

Executed at `85e6344` in `avra-lane-http`, 2026-09-06, after
`sh tools/watch.sh 4000 make bootstrap` rebuilt the compiler from this tree.
Bootstrap succeeded with a reported peak of 642 MB. Each refusal below was
checked with `./avra check` and exited 1 with exactly one diagnostic.

Typed capture attempt:

```avra
match "/ideas/42" {
    "/ideas/{id: int}" -> id
    _ -> 0
}
```

Result: F3000, "`id` is not defined". The pattern does not introduce a binding.

Literal-pattern control:

```avra
match "/ideas/{id: int}" {
    "/ideas/{id: int}" -> "literal"
    _ -> "miss"
}
```

Result: `./avra run` and the binary from `./avra build` both print `literal`.
The existing behavior is literal equality, not extraction. Adding captures
must preserve an unambiguous way to match literal braces.

Byte-value prerequisite:

```avra
fn size(value: Bytes) -> int { value.length }
```

Result: F2001, "`Bytes` names no type".

Named-format prerequisite:

```avra
grammar IdeaPath = "/ideas/{id: int}"
```

Result: F0100, "expected BREAK while parsing `stmt`", at `IdeaPath`.

Four programs executed: three frontend refusals and one accepted program in
both engines. This is a capability baseline, not the implementation's
adversarial suite or a performance benchmark. Temporary sources were removed
and the probe binary moved outside the worktree to a temporary directory;
the complete sources and outcomes are retained here.

## Domain identity capability probes

Recovery follow-up on 2026-09-06, at the unchanged source base
`85e6344bef51ce74dfa9e436839a460bc9759807`, using the compiler bootstrapped
above. Five additional programs ran through `./avra check`, `./avra run`,
and `./avra build`. The accepted program's native binary ran separately.
These are prerequisite probes, not an HTTP implementation or a completed
`/red-team` or `/review-round` pass. Temporary sources and binaries were
removed after execution.

The accepted control:

```avra
type IdeaId = { value: int }
fn idea(id: IdeaId) -> int { id.value }
idea(IdeaId { value: 42 })
```

Checking succeeds; interpreted and native execution both print `42`.

The first refusal adds `type RunId = { value: int }` and replaces the final
expression with `idea(RunId { value: 42 })`. All three commands exit 1 with
exactly one F2000: "argument 1 of `idea` wants `IdeaId`, found `RunId`".
The second refusal instead replaces the control's final expression with
`idea(42)`. All three commands exit 1 with exactly one F2000:
"argument 1 of `idea` wants `IdeaId`, found `int`".

The remaining two programs each contain only one declaration:

```avra
type IdeaId = int
```

```avra
type Port = int where 1 <= it && it <= 65535
```

Both refuse under all three commands with exactly one F0100:
"expected `{` while parsing `stmt`", pointing at `int`. The latter probe
does not reach the predicate; it establishes only that the proposed
refinement declaration cannot be expressed in this spelling at this base.

The immediate foundation distinction is **identity versus validation**.
Nominal records already keep ID domains apart; route capture must preserve
that existing property. A nominal record alone does not establish a range,
a valid segment spelling, or authorization. This probe also establishes
nothing about allocation cost or an unboxed representation.

Before implementing typed route expansion, require a codec witness that
constructs the declared domain type through its validation boundary and
prints it through the same contract. Before calling that path zero-cost,
measure its generated representation and allocations. Scalar newtype sugar
and refinement declarations need their own language design; neither is
justified by treating the demonstrated record spelling as the final API.

## Deterministic attacks to turn into fixtures

These are design cases, not a completed executable `/red-team` pass.

| Input or scenario | Required outcome |
| --- | --- |
| `/ideas/42` under an integer-backed `IdeaId` codec | One typed capture |
| `/ideas/42/extra` | No full-route match |
| `/ideas/` | Required capture missing |
| Integer capture at min/max and one beyond each | Exact accepted bounds; overflow rejected |
| `%`, `%2`, `%GG` | Malformed percent encoding rejected |
| `%2F` in a portable segment | Segment-domain refusal, never another route segment |
| `%252F` in a portable segment | Decodes to literal `%2F` once; no downstream second decoding |
| Encoded complete dot segments or backslash | Portable segment-domain refusal |
| Query fields in reverse order | Same scalar record |
| `limit=1&limit=2` for a scalar | Duplicate-field refusal |
| `tag=a&tag=b` for a list | Both values in order |
| Missing, empty, and malformed `limit` | Absence/default handled separately from invalid data |
| Literal plus versus `%20` | Different values under generic URI decoding |
| Invalid UTF-8 in a textual capture | Codec refusal without changing raw framing |
| A static route overlaps a capture route | Declared specificity or a compile diagnostic, never incidental registration order |
| Two custom capture codecs have unknown overlap | Proof result is unknown; no invented disjointness proof |
| Every split point in a streamed request target | Same result as the complete-buffer case |
| A capture escapes and the receive buffer is reused | Stable captured value, no dangling view |

Typed patterns and component codecs are reusable foundations. HTTP supplies
their component boundaries, route semantics, and wire-specific obligations.
