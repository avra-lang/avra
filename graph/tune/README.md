# Capability tuning (LoRA on the shared Qwen3-4B)

Teaches the scorer to make the cascade's and planner's closed choices over
ANY declared schema. Training text is invented domains only; no owner data,
no fixture text (`corpus.py` refuses fixture names). Runtime stays local.

```sh
python3 corpus.py [domain …]                 # validate authored gold
python3 extract_drive.py > out/extract.jsonl # real cascade, gold spans, oracle choices
python3 plan_drive.py   > out/plan.jsonl     # real planner, gold walks, oracle choices
$VENV/python convert.py out/extract.jsonl out/plan.jsonl --out data/   # real Scorer.choose prompts, both orders
sh train.sh                                  # mlx_lm lora, held-out domains for early stopping
$VENV/python evaluate.py --adapter adapters/<run>  # base vs adapter on the benches
```

`VENV=~/.cache/avra-graph-ml/venv/bin`. Decisions are produced by running
the real code with a recording oracle, so prompts match production exactly.
A decision the gold does not settle is not recorded; a planner question whose
composed query differs from its gold is reported and dropped.

## Authoring a domain (`corpus/<domain>.json`)

```json
{"domain": "rowing_club",
 "models": {"<Model>": {"description": "...", "properties": {"<prop>": <shape>},
            "identities": ["email"], "absences": {"<prop>": "<code>"},
            "relation": {"from": "<prop>", "to": "<prop>", "label": "<enum prop>", "phrasing": "{to} is {from}'s {label}",
                         "labels": {"<value>": {"forward": ["word", …], "reverse": ["word", …]}}},
            "embedded": false}},
 "entities": {"<id>": {"model": "<Model>", "name": "<full name>", "fields": {"email": "…"}}},
 "messages": [{"id": "m01", "text": "…",
   "mentions": [["<surface>", "<entity id>"], ["<surface>", "<id>", "?"], ["she", "<id>|none|?", "ref"]],
   "quotes": [["<quoted text without its quote marks>", "<id>|author|?"]],
   "facts": [{"model": "<relation model>", "in": "<sentence or clause>", "from": "<id>", "to": "<id>", "label": "<value>",
              "act": "assert|report|plan|request|condition|draft", "deny": false, "fields": {"<bool prop>": true}},
             {"model": "<record model>", "in": "<sentence>", "fields": {"<prop>": "<value|entity id|int|bool>"}, "act": "…"}]}],
 "questions": [{"q": "…", "speaker": "<id>|null", "cypher": "<planner dialect>"}]}
```

Shapes: `string`, `integer`, `boolean`, `[string]`, a model name (reference; embedded
if that model says `"embedded": true`), suffix `?` optional, a JSON list = closed enum.
The first property of an entity model is its required name.

Gold rules:
- `mentions`: every occurrence of an entity's name (full or short), in text order; a
  repeated surface is listed again. Third element `"?"`: the text alone cannot tell
  which entity a short name means. Every pronoun/possessive (incl. I/me/my/we in a
  `Name:` turn) that points at an entity: `["her", id, "ref"]`; `none` = someone unnamed.
- A fact belongs to the punctuation sentence containing the start of its `in` cue.
  A relation's two ends must both be mentioned (name or pronoun) in that sentence;
  `from`/`to` make the declared phrasing true. A denial is the fact with `deny: true`.
- Record `fields`: every field that sentence states and nothing else; text values
  are exact substrings of the sentence, integers appear as digits, references are ids.
- `act`: assert = stated as current fact; report = what someone else said; plan =
  future intention; request = asked of someone; condition = holds only if; draft =
  tentative ("I think", "maybe", "pencilled in").

Planner dialect (the gold must be what `structured.plan` composes; `plan_drive.py` prints
the composed query on a miss): `MATCH (n0:M)` then hops `-[:label]->(n1:T)` (relation
label or reverse word) or `<-[:refprop]-(n1:R)` / `-[:refprop]->(n1:T)`, WHERE joined by
AND from: `id(n0) = $speaker`; `n0.name = 'Whole Value'` (only when the question spells the
whole stored value); `nK.label = 'v'` (relation records' label only); `nK.prop CONTAINS 'word'`
(a lowercase word shared by the question and a stored text value). RETURN from the last
node: `nK.prop AS prop, …` | `count(nK) AS count` | `coalesce(nK.flag, false) AS flag`.

## Results

### r3, best step 2250 (full held-out loss 0.3523 vs base 2.3460)

`evaluate.py --adapter adapters/r3/best`, base then adapter, untouched benches
(full output: `results/eval-r3-20261022T012702.json`).

| bench | base | adapter | gold probability |
|---|---|---|---|
| planner (96) | 74 | 73 (+4 -5) | 0.719 -> 0.677 |
| extract (52) | 47 | 40 (+0 -7) | 0.892 -> 0.652 |
| er (13) | 12 | 10 (+0 -2) | 0.906 -> 0.716 |

Losses concentrate in extract/relation (19 -> 13), planner/property (9 -> 7) and
er/antecedent (12 -> 10). Verdict: not promoted; the base stays the service default.
