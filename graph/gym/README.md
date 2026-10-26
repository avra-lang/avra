# Execution gym

Verifiable tasks over invented domains; the graph engine is the oracle.

Pipeline (`domain.py`, resumable, one directory per world under `out/<family>/<seed>/`):

1. `skeleton.py` structure only (entity, relation and record kinds, sibling references, look-alike relations, optional/money/date/flag properties), seeded.
2. `names.py` the generator invents every word (domain, models, properties, labels); structure checks only.
3. `avgen.py` models in the real declaration form, compiled by the real compiler into a graph binary.
4. `world.py` entities (same-name pairs), records, superseded statements, tombstones, ordered sources.
5. `render.py` + `facts.py` source texts from fact lines; kept only if every name and literal is carried.
6. `plans.py` plans in the planner's own form (Cypher subset + params + valid-time view): lookup, hop, filter, aggregate, temporal, unanswerable. Kept only if the engine answers as the kind intends; the engine's answer is the label.
7. `render.py` questions from plan steps; kept only if structurally faithful, the round trip picks the plan, and person is right.
8. `split.py` freezes `splits/<name>.jsonl` (+ provenance: generator model id and prompt hash per text); `disjoint` checks train vs eval.
9. `evalrun.py` runs a pinned planner snapshot over a split; cluster-BCa intervals, exact mid-p McNemar for A/B, risk-coverage.

Families: `eval` and `train` use different seed spaces and different question prompts. Fixture names are refused from fixture files (`contam.py`). Generation uses the hosted generator only for invented content (`--generator hosted`, default) or a running local service (`--generator local`); the gym never starts a model.
