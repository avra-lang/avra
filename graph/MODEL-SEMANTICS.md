# Typed semantics beside model declarations

Descriptions help classifiers and question planners understand a schema.
They are not sufficient to tell a generic engine which field is an identity,
which direction a relationship runs, or what a number's unit means.

`@model` accepts an optional, typed quoted `Semantics` expression. Existing
bare declarations keep empty semantic bindings. For example, an unrelated
device ontology can declare its identity without a device handler:

```avra
use @avra.graph.{model, Semantics, IdentityBinding}

@model(quote { Semantics {
    identities: [IdentityBinding {
        namespace: "device:registry",
        path: ["tag"],
        normalization: .Trim,
    }],
} })
export type Instrument = { tag: string }
```

The expression is ordinary Avra checked as `Semantics` in the generated
model factory. It is trusted application source, never question-supplied
code or a JSON executable. `std.validate` still owns model value validation;
the metadata expression is not passed to the value decoder as a rule.

## Bindings

- `IdentityBinding`: explicit namespace, property path and normalization
  (`Exact`, `Trim`, `AsciiLowerTrim`). A display name does not become an
  identity unless the application explicitly declares it one. The ASCII
  policy is not Unicode case folding, email canonicalization or phone
  parsing. L01 implements resolution using these declarations.
  `scoped_by` lists up to four paths that scope the key: text, or a
  reference whose target declares keys of its own. An invoice number
  within its issuer is `IdentityBinding { namespace: "invoice", path:
  ["number"], scoped_by: [["issuer"]] }`. The key is one JSON array of
  the scope values and the normalized key, so no two splits collide; a
  reference stands for each declared `[namespace, key]` its target holds,
  and a target with no key yet leaves the record unkeyed. Scope chains
  that return to their owner are refused. Producers never spell scoped
  keys by hand; one that contradicts the declared key is refused.
- `RelationBinding`: distinct `from`/`to` reference paths and a text `label`
  path. `RelationLabel` maps a stored value to declared forward/reverse
  phrases. Empty label mappings leave an open vocabulary; they do not
  authorize guessing inverse names. A reverse phrase describes direction,
  not a newly asserted inverse fact.
- `ValidityBinding`: optional `from` and `until` paths and explicit
  `UnixMillis`, `IsoDate` or `IsoInstant` representation. Intervals are
  half-open. Null means an unspecified bound, not independently proven
  timeless validity. Q05 owns parsing/evaluation and relative-date grounding;
  metadata validation checks representation shapes, not timestamp contents.
- `QuantityBinding`: numeric `amount` path, `UnitBinding.Field(path)` or
  `UnitBinding.Constant(name)`, and decimal places (0..18). The represented
  value is the stored amount divided by 10 to that power. No unit name,
  exchange rate, conversion or financial policy is inferred. P03 owns
  evidence-aware arithmetic; integer amounts retain exactness requirements.

Paths are lists of exact property-name tokens, with 1..16 nonempty tokens.
They may traverse optional embedded records, not lists or entity references.
Referencing another entity requires an actual query join. Terminal optional
properties are allowed; their missing values remain unknown at execution.
There is no dotted-string parser or property-name convention.

Catalog admission checks every path against the collected shapes, rejects
incompatible shapes and conflicting bindings, and bounds metadata counts
(64 identities/quantities, 128 relation labels/phrases). Standard model rules
remain authoritative for actual values and allowed relation tags.

The catalog descriptor carries `semantics.version = 1`; all bindings
participate in its fingerprint. Editing them therefore makes earlier
interpretations stale under the existing conservative catalog policy.
Persisted old schema documents remain unchanged. This adds no table layout
and does not reinterpret opaque legacy locators.

This is machine-readable metadata, not an identity resolver, NLP model,
temporal engine or policy interpreter. Those consumers remain separate tasks.
No automatic merge or fact publication follows from declaring a binding.

## Compiler prerequisite

Optional annotation parameters require the general compiler fix tracked as
`avra-8sb5.10.151`. Use a compiler built from that fix; an older binary may
reject bare `@model` with `annotation.seats`. This is not a second graph
annotation dialect or an instruction to add empty arguments to every model.
Preserving descriptions above quoted arguments also requires
`avra-8sb5.11.389`. Both fixes are in this branch and its rebuilt compiler;
comments need not move away from their normal declaration-leading position.

## Derivations

A derived answer is an ordinary typed fn declared beside the models:

```avra
use @avra.graph.{derived, Unknown, difference, total, same_unit}

/// The deposit still owed on an invoice.
@derived
export fn deposit_top_up(invoice: Invoice, payments: List<Payment>) -> Result<TopUp, Unknown> { … }
```

Parameters say what a read plan supplies: `T` one row of model `T`,
`T?` at most one, `List<T>` every row of a plan node, and `string`,
`int` or `bool` one literal argument. The answer is a registered model,
or `Result<Model, Unknown>`. The plan wires its inputs, so which payments
belong to an invoice is the plan's typed `follow`, not a second
declaration. The engine decodes each row with its model's standard
decoder (a gap or a competing claim is unknown, never a default), calls
the fn on one snapshot, checks the output against its model and cites
every input row's support.

Integer `+` and `-` wrap; derivations use `difference`, `total` and
`same_unit`, which answer `Unknown` (`overflow`, `mixed_units`) instead.
`Unknown.known` carries what was established before stopping. No unit is
converted and no rate is assumed.

The catalog refuses unknown models, duplicate names and dependency cycles
(a derivation reading, through others, its own output). Each
derivation's description and code hash join the fingerprint as a
versioned section; a catalog with none keeps its model-only identity.
