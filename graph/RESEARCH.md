# Research and end-to-end direction

Reviewed 2026-10-20. This is a candidate/evaluation plan, not a claim that
Avra already runs these models or that one system is universally SOTA.

## Contract

Feed text or structured items, automatically build evidence-backed facts,
and ask contextual English questions that return structured facts and
their sources. No generative LLM is required on the ingestion path. A
worker is an ordinary service, not a reasoning agent. The models remain
the only ontology-specific source: names, descriptions, linguistic labels,
relationship roles, validation, and eventual extraction/policy annotations.

Pretrained discriminative encoders are still language models in the broad
sense. Here “no LLM extraction” means no chat/autoregressive generation
of facts. It does not exclude transformer span scorers or classifiers.

## Candidates, with evidence boundaries

| Component | Research | What to evaluate here |
| --- | --- | --- |
| Schema-conditioned extraction | [GLiNER2, EMNLP 2025 demos](https://aclanthology.org/2025.emnlp-demos.10/) | Encoder-based entities, classifications and structured records using one schema interface. A strong deployment candidate, not proof of personal-graph accuracy. |
| Joint entities and relationships | [GLiNER-Relex, May 2026 preprint](https://arxiv.org/abs/2605.10108) | Shared bidirectional encoder with inference-time entity/relation labels; compare with GLiNER2's current JointIE implementation. The paper reports competitive results, not universal dominance. |
| Separate relationship extractor | [GLiREL, NAACL 2025](https://aclanthology.org/2025.naacl-long.418/) | Useful modular baseline when entities already come from source metadata or a different recognizer. |
| Efficient grounding | [ReLiK, ACL Findings 2024](https://aclanthology.org/2024.findings-acl.839/) | Retrieve candidate entities, then jointly contextualize and link them. Its published public-KB results do not establish accuracy for private/new entities. |
| Within/across-document coreference | [Maverick, ACL 2024](https://aclanthology.org/2024.acl-long.722/), [xCoRe, EMNLP 2025](https://aclanthology.org/2025.emnlp-main.1737/) | Link named and pronominal mentions; xCoRe adds cross-context clustering. Their benchmark SOTA claims are dataset/date-specific. |
| Personal references in conversation | [CREL / ConEL-2, CIKM 2022](https://arxiv.org/abs/2206.07836), [authors' code](https://github.com/informagi/conversational-entity-linking-2022) | Particularly relevant formulation for “my wife”, “my city”, and conversational antecedents. Older foundational work, not a current overall SOTA claim. |

[GLiNER2's current implementation](https://github.com/fastino-ai/GLiNER2)
also exposes joint typed entity–relation decoding. That is newer software
than the original demo paper; keep implementation capability separate
from the paper's evaluated claims. Pin model/library revisions for a test.

## Ingestion: cheap first, expensive only when useful

1. A source adapter supplies immutable payload, source identity, author,
   participants, timestamps, and attachment structure when available.
   Do not infer what an email header already says.
2. Hash normalized inputs. Skip unchanged revisions. Chunk changed text
   while retaining source-coordinate mappings and speaker boundaries.
3. A small classifier selects relevant declared extraction schemas. Batch
   similar windows, cache schema representations where supported, and
   keep the model loaded. Never load a model for each CLI request.
4. A schema-conditioned encoder proposes spans, properties and relations.
   Prefer joint extraction when it measures better than separate passes.
5. Link exact source identities first; retrieve private-graph candidates
   for ambiguous mentions and optionally rerank them with an encoder.
   Name similarity alone does not establish identity. Unknown entities
   get stable local identities; ambiguous mentions remain unresolved.
6. Standard model validation and reference checks admit partial claims
   with observation revision and source locators. Scores are metadata,
   not an instruction to choose a truth. Negated, quoted, hypothetical,
   and planned statements must not become unconditional current facts.
7. Publish atomically under producer/scope. Persist job/dependency state
   so source, schema, or extractor-version changes can schedule refresh.

These stages are architecture, not all implemented. The current graph
accepts publications and exposes dirty prior runs; it does not yet run a
classifier, schedule new sources, resolve coreference, or compile an
extraction schema from model annotations. No provider is installed by
this document and no personal text is sent to an external service.

An arbitrary new model cannot become reliably extractable just because
it compiles. Useful descriptions, roles and sometimes examples/training
are needed. Their declarations belong beside the model, not in a growing
adapter switch. Unsupported fields stay absent rather than fabricated.

## Contextual questions: “what did my wife say about X?”

The request needs a context frame: principal, speaker, conversation,
relevant time, and available sources. These are generic bindings; the
engine must not hardcode personal relationship vocabulary.

1. Resolve “my” to the frame's speaker. A quoted speaker changes that
   binding; it does not rewrite the user's identity.
2. Ground the relationship phrase to declared schema semantics. Follow
   supported relationship facts from that speaker to candidate people.
3. Filter authored statements/messages by those identities and relevant
   time. Combine exact/FTS matching with semantic retrieval for X.
4. Return structured results containing entities, properties/values,
   ambiguity status, observation revisions and supporting source spans.

This is a bounded join/search plan, not a global alias “my wife = p17”.
Within-document coreference alone cannot establish a relationship that
was never observed. Missing or multiple candidates require abstention or
a question, not a guessed merge. Valid time (“who was my wife then?”)
is separate from transaction time (“when did we learn this?”); the
current graph revision is not yet a bitemporal relationship model.

For broad English, evaluate a constrained query parser separately from
extraction. Embedding-based schema matching and small discriminative
models can cover common forms. An optional question-only LLM may emit
a validated, read-only query plan; the engine supplies facts. Neither
route can promise unrestricted human-level understanding today.

## Evaluation before selecting a stack

- [LongMemEval](https://arxiv.org/abs/2410.10813): extraction, cross-session
  and temporal reasoning, updates and abstention. Do not mistake reader
  quality for extractor or store correctness.
- [EverMemBench, 2026](https://arxiv.org/abs/2602.01313): multi-party roles,
  interleaved topics and evolving facts. Particularly relevant to the
  difference between “my wife” from different speakers.
- [IRC-Bench, 2026 preprint](https://arxiv.org/abs/2605.06142): implicit
  references needing evidence scattered through a narrative. A warning
  against treating this as solved NER, not a personal-KB benchmark.
- [STaRK](https://stark.stanford.edu/): retrieval that combines textual
  conditions and graph relationships; useful query-design inspiration,
  not an ingestion or personal-reference benchmark.

Build a small, consented personal-domain evaluation set with held-out
documents: unknown names, same-name people, repeated mentions, quotes,
pronouns, ownership phrases, relationship changes, negation, corrections,
and genuinely unanswerable questions. Score extracted spans, grounded
entity IDs, relation direction/roles, unsupported-assertion rate,
abstention, source attribution, structured answer accuracy, CPU/RAM and
p50/p95 latency. Keep oracle-extraction and oracle-retrieval runs to
attribute failures to a stage. Calibrate thresholds on validation data.

Initial recommendation: compare GLiNER2 joint extraction against
GLiNER-Relex on that set, with exact metadata identity as the cheap path.
Add coreference and retrieval/reranking only where measured failures
justify them. A model-service boundary keeps Avra's engine independent
of Python/PyTorch and leaves room for measured local-runtime alternatives.
