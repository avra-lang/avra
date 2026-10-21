# Fixture application: identity and relationships (M01)

This package is the application ontology, not a second graph engine. M01
adds declarations in [src/models/people.av](src/models/people.av): Person,
Organization, embedded Validity, PersonalRelationship, OrganizationRole and
GroupMembership. Registrations are generated with `@model` and `collect`;
validation uses standard rules plus one model-local interval rule.
P01 adds typed identity, relationship and validity bindings to those same
declarations. They are described in [../../MODEL-SEMANTICS.md](../../MODEL-SEMANTICS.md)
and verified in [../../P01-HANDOFF.md](../../P01-HANDOFF.md). Consumers still
need to implement resolution and temporal evaluation.

There is no person dictionary, relationship dispatcher, NLP provider or
startup command here yet. M02 adds commercial declarations; M03 adds
personal/event/task declarations and the minimal startup entry point.
The existing engine under `graph/src` is unchanged by M01.

## Representation choices

- A relationship is directed: `relative` is `subject`'s `relation`. Rowan's
  wife Elena and Alex Chen's wife Sora are separate records. Neither person
  gets a global `my wife` alias; Context binds the utterance speaker.
- Mother relationships follow the same direction. Elena→Ruth is separate
  from Rowan→June; a quoted speaker is not automatically the envelope author.
- Business roles are independent records with organization, title and valid
  interval. Elena's role change does not modify her marriage. The interim
  qualifier is retained in Mina's title, not discarded as noise.
- Explicit negative membership (`is_member: false`) can represent Sora's
  source-backed denial. The property is required: a missing assertion is not
  defaulted to false. This literal does not replace extraction polarity or
  provenance; E01 must still admit the underlying evidence correctly.
- Validity uses half-open UTC millisecond intervals. The fixture's 16 October
  2026 boundary is `1792108800000`. Unknown bounds remain null; they do not
  independently establish timeless validity. Receipt/knowledge time is not
  embedded in application validity. Q05 owns evaluation of declared time
  semantics, not a special case for this model or these property names.
- Descriptions expose lexical hints and direction through the catalog.
  They are not an implemented inference-policy interpreter: inverse
  relationships, title equivalence and temporal selection need the later
  generic planning/policy path. No implicit inverse, gender or household
  membership inference is implemented here.
- Default empty alias lists are construction behavior. Extraction uses
  partial proposals; it must not publish such defaults as observed facts.
  Names are not unique keys; identity normalization/linking remains L01.

## Verification and honest scope

From the repository root:

```sh
sh tools/watch.sh 3500 ./build/avra test graph/acceptance/app/src/tests
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
```

The model/store witness manually supplies records for two spouse bindings,
two mothers, the old/new business roles and a negative membership, and reads
them back with the existing generic engine. This is an **oracle-fed storage
test**, not q01–q07 passing from text or English questions. The native proof
program additionally checks cross-package descriptor generation, typed
reference decoding and reversed-interval refusal. Tests also reject invalid
email, undeclared relationship tags, absent membership booleans and empty
intervals. They preserve unknown dates and expose generated descriptions.

The task's verification receipt is [M01-HANDOFF.md](M01-HANDOFF.md).
