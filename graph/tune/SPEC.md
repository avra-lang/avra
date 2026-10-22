# Corpus spec (authors read this, then `corpus/vet_clinic.json`)

One JSON file per invented domain: `graph/tune/corpus/<domain>.json`. Labels are
never written by hand as prompts: the real cascade and planner run over your
gold and ask their own questions; you only state what is true of the text.

## Exclusions (hard)

- Never: luxury fashion/retail, weddings/family events, home workshop, garden, tool lending.
- Never these names (eval fixtures; `corpus.py` refuses them): Rowan, Elena, Vale, Maison Aster,
  Odalys, Teodor, Wren, Pim, Greenholt, Sora, Ruth, June, Fig, Alex Chen, Moreau, Khan, Cole,
  Torres, Stone, Brenner, Haldane, Castellanos, Okafor. No name reused across domains.
- No text copied from graph/acceptance, graph/planner/bench, graph/extract/bench.

## Worked mini-domain

```json
{"domain": "beekeeping_assoc",
 "models": {
  "Member": {"description": "A member of the association.", "properties": {"name": "string", "email": "string?"}, "identities": ["email"]},
  "Apiary": {"description": "A site where hives stand.", "properties": {"name": "string"}},
  "SiteRole": {"description": "Who keeps or inspects an apiary.",
   "properties": {"member": "Member", "apiary": "Apiary", "role": ["keeps", "inspects"]},
   "relation": {"from": "member", "to": "apiary", "label": "role", "phrasing": "{from} {label} {to}",
    "labels": {"keeps": {"forward": ["keeps", "keeper of"], "reverse": ["keeper"]},
               "inspects": {"forward": ["inspects", "inspector of"], "reverse": ["inspector"]}}}},
  "Harvest": {"description": "Honey taken from an apiary. weighed stays empty until a weight is recorded.",
   "properties": {"apiary": "Apiary", "taken_by": "Member", "checked_by": "Member?", "jars": "integer",
                  "state": ["planned", "done"], "weighed": "boolean?", "note": "string?"},
   "absences": {"weighed": "no_weight_record"}}},
 "entities": {
  "ines": {"model": "Member", "name": "Ines Ferraz"},
  "ines_b": {"model": "Member", "name": "Ines Barta"},
  "kofi": {"model": "Member", "name": "Kofi Adjei"},
  "hilltop": {"model": "Apiary", "name": "Hilltop"}},
 "messages": [
  {"id": "m01", "text": "Kofi Adjei: I keep Hilltop now. Ines Ferraz inspects Hilltop, not me.",
   "mentions": [["Kofi Adjei", "kofi"], ["I", "kofi", "ref"], ["Hilltop", "hilltop"], ["Hilltop", "hilltop"],
                ["Ines Ferraz", "ines"], ["me", "kofi", "ref"]],
   "facts": [
    {"model": "SiteRole", "in": "I keep Hilltop now.", "from": "kofi", "to": "hilltop", "label": "keeps", "act": "assert"},
    {"model": "SiteRole", "in": "Ines Ferraz inspects Hilltop", "from": "ines", "to": "hilltop", "label": "inspects", "act": "assert"},
    {"model": "SiteRole", "in": "not me", "from": "kofi", "to": "hilltop", "label": "inspects", "act": "assert", "deny": true}]},
  {"id": "m02", "text": "Ines Barta wrote: \"We took 14 jars from Hilltop today.\" Ines Ferraz checked the jars. Ines will weigh them on Friday, she said.",
   "mentions": [["Ines Barta", "ines_b"], ["Hilltop", "hilltop"], ["Ines Ferraz", "ines"], ["Ines", "ines", "?"], ["she", "?", "ref"]],
   "quotes": [["We took 14 jars from Hilltop today.", "ines_b"]],
   "facts": [{"model": "Harvest", "in": "We took 14 jars from Hilltop today.",
              "fields": {"apiary": "hilltop", "jars": 14, "state": "done"}, "act": "report"}]},
  {"id": "m03", "text": "Maybe Kofi will take the spring harvest at Hilltop, if Ines Ferraz agrees.",
   "mentions": [["Kofi", "kofi"], ["Hilltop", "hilltop"], ["Ines Ferraz", "ines"]],
   "facts": [{"model": "Harvest", "in": "Maybe Kofi will take the spring harvest at Hilltop",
              "fields": {"apiary": "hilltop", "taken_by": "kofi", "state": "planned"}, "act": "condition"}]}],
 "questions": [
  {"q": "Who is the keeper of Hilltop?", "speaker": null, "cypher": "MATCH (n0:Apiary)-[:keeper]->(n1:Member) WHERE n0.name = 'Hilltop' RETURN n1.name AS name"},
  {"q": "Which apiaries do I keep?", "speaker": "kofi", "cypher": "MATCH (n0:Member)-[:keeps]->(n1:Apiary) WHERE id(n0) = $speaker RETURN n1.name AS name"},
  {"q": "How many harvests are there?", "speaker": null, "cypher": "MATCH (n0:Harvest) RETURN count(n0) AS count"},
  {"q": "Is there a record of the Hilltop harvest being weighed?", "speaker": null,
   "cypher": "MATCH (n0:Apiary)<-[:apiary]-(n1:Harvest) WHERE n0.name = 'Hilltop' RETURN coalesce(n1.weighed, false) AS weighed"}]}
```

## Schema (exact)

- `models`: name -> `{description, properties, identities?, absences?, relation?, embedded?}`.
  Property shape: `string|integer|boolean`, a model name (reference, or embedded if that model
  has `"embedded": true`), `[shape]` list, trailing `?` optional, a JSON list = closed enum.
  An entity model's FIRST property is its required name. Relation `label` value and `reverse`
  words are single words (`\w+`); `forward` words may be phrases.
- `entities`: id -> `{model, name, fields?}`.
- `messages[]`: `{id, text, mentions, quotes?, facts}`.
  - `mentions`: `[surface, id]` for every name occurrence in text order (repeat a repeated
    surface); add `"?"` when the text alone cannot tell which entity a short name means;
    `[word, id|"none"|"?", "ref"]` for every pronoun/possessive pointing at an entity
    (`none` = someone the text never names; `?` = cannot tell). The cascade resolves pronouns
    and quote speakers only to models that are some relation's `from` end, so a person-like
    model is a `from` end.
  - `quotes`: `[inner text without quote marks, id|"author"|"?"]` for every quotation.
  - `facts`: relation `{model, in, from, to, label, act, deny?, fields?}`; record
    `{model, in, fields, act, deny?}`. `in` = exact substring; the fact belongs to the
    punctuation sentence holding its start. Both relation ends are mentioned (name or
    ref) in that sentence, and the declared phrasing with from/to filled is true.
    Record `fields` = every field that sentence states, nothing else: references are ids,
    integers appear in the sentence as digits, text values are exact substrings.
  - `act`: assert (current fact) | report (someone else said) | plan (future intention) |
    request (asked of someone) | condition (holds only if) | draft (tentative: maybe, I think,
    pencilled in). `deny: true` for a stated negation of the claim.
- `questions[]`: `{q, speaker: id|null, cypher}` in the planner dialect (README.md). The gold is
  what is correct; `plan_drive.py` reports a miss with what the planner composed.
  A relation word spoken in the question forces that hop wherever it can be taken ("Who keeps
  Hilltop?" walks back from the keeper), so phrase questions with the word for the hop you mean.

## Per-domain targets

4–7 models: ≥2 entity models, ≥1 relation model (2–4 labels, near-synonym words), ≥1 record
model with 2–3 confusable references to one entity model, a closed enum state, an optional
boolean with an absence code, an integer, an optional text. 15–25 short messages in varied form
(chat turns `Name: …`, emails with sign-offs, minutes, notes, forwarded quotes). ~15 questions.
Domains must differ in model naming, phrasing templates and message structure; do not reuse
another domain's message order or skeleton.

## Quality checks (all must pass; run from graph/tune)

```sh
python3 corpus.py <domain>                     # 0 problems (schema, placement, fixture names)
python3 extract_drive.py <domain> > /dev/null  # ≥150 decisions; every kind present
python3 plan_drive.py <domain> > /dev/null     # ≥12 walks, misses fixed or the question dropped
```
Fix a miss by making the question or gold CORRECT and expressible, never by bending gold.

## Top-up: antecedent, speaker, reference (the thin, weak kinds)

The cascade asks these only inside one message, so density must be inside messages:
- antecedent: a later short form of an earlier name in the SAME message ("Dr. Ines Ferraz …
  Ferraz …", "Ines …"), two people sharing a first or last name in one message, and short forms
  the text cannot resolve (`"?"`) or that are a new person (a third Ines).
- speaker: several quotations per message with different speakers — named before or after the
  quote, the unnamed author (`author`), and ones the text cannot attribute (`?`).
- reference: `Name:` turns where different speakers each say "my X"/"I"; pronouns with two
  same-model candidates in the sentence; possessives ("her", "their") over relation sentences;
  pronouns for someone the text never names (`none`).
Target per top-up domain: ≥25 antecedent, ≥15 speaker, ≥40 reference decisions.
