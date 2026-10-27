# DEEP-INGEST: raw sources to admitted, cited facts

Researched 2026-10-26. Read-only review of `graph/extract/*`, `acceptance/RECALL.md`, `SOTA.md`, `RESEARCH.md`, `QA-RESEARCH.md`. No model was run.
Labels: **V** = read at the URL this session (abstract or page). **V~** = stated in a search-result snippet only, page not opened. **R** = recalled, unverified. **L** = measured in our tree (file named).
Estimates of gain are my estimates, not measurements; each says what to measure.

## 0. The diagnosis in five lines

1. The cascade loses facts upstream of admission (L, RECALL.md): admission refused 0 of 119 records, but 18 of 25 expected models never appear. 20 of 35 extraction-dependent questions die at the record pass, 12 at entity resolution, 9 at a planner limit (Money).
2. The record pass asks, per sentence, one 18-way closed choice and accepts only at p >= 0.95, a threshold marked `fitted: false` ("borrowed from the relation fit") (L, `cascade.py:778-810`, RECALL.md). A 4B model spreads probability over many plausible kinds and rarely reaches 0.95, so the pass is silent. My reading: a calibration defect of the design, not a recall limit of the model. Test it before believing it (R2 fast path).
3. Entity resolution works when asked (L, `er_params.json`: 51 right, 1 wrong, 0 duplicate of 54 on dev) but is almost never asked: every admitted entity has `candidates: []`, because cached extractions are requested without graph candidates (L, RECALL.md). 55 Person records became 45 entities for about 12 real people.
4. Time is not extracted into relations: all 25 relation records carry `validity={}` (L, RECALL.md).
5. Cost: 30 sources of about 450 characters (L, `acceptance/sources.jsonl`: mean 457 bytes of JSON) take about 24 minutes, about 48 s per source. That is many forward passes per tiny source. Per-sentence x per-kind choice is the wrong unit of work for speed as well as for recall.

## 1. External evidence in one table (what the field does at ingestion)

| System | Ingestion mechanism | Number (and label) | Lesson for us |
|---|---|---|---|
| Graphiti/Zep | Raw episode kept; LLM finds entities, then facts, then a separate temporal pass sets valid_at/invalid_at; entity resolution is in-line against existing nodes; contradiction invalidates the old edge, never deletes (V~ [help.getzep.com](https://help.getzep.com/how-graph-creation-works), [mirror](https://mintlify.com/getzep/graphiti/concepts/temporal-model)) | Ingestion about 1.3M input tokens and $0.56 per episode vs Mem0 about 224K and $0.11, gpt-4.1-mini (V~ [MEME 2605.12477](https://arxiv.org/pdf/2605.12477) snippet); REMem says Graphiti indexing is about two orders of magnitude costlier than Mem0 (V~ [2602.13530](https://arxiv.org/pdf/2602.13530)) | In-line ER and a separate temporal pass are right; many LLM calls per episode is not. Our encoder-first design is the cheaper shape. |
| Mem0 | One LLM extraction, then ADD/UPDATE/DELETE/NOOP against top-k similar memories | 91% lower p95 latency and over 90% token saving vs full context; 26% relative J gain over OpenAI memory (V [2504.19413](https://arxiv.org/abs/2504.19413)); claimed 93.4% LongMemEval measured 73.8% independently (V~ via SOTA.md, [Maximem](https://www.maximem.ai/blog/state-of-ai-memory-2026-claimed-vs-observed)) | A single-pass write path wins on cost; destructive update is what not to copy. |
| Hindsight | LLM writes 2-5 self-contained facts per exchange, coreference and time resolved; 4 retrieval channels | 39% to 83.6% with a 20B open model; 91.4% LongMemEval and 89.61% LoCoMo with a larger backbone (V [2512.12818](https://arxiv.org/abs/2512.12818)). SOTA.md says LoCoMo 83.2; the abstract I fetched says 89.61 for the larger backbone, so check which backbone SOTA.md meant. | Write-time interpretation by a generative model; a small open model suffices. |
| xmemory | Schema says what to remember, ignore and never infer. Write path = object detection, field detection, field-value extraction, validation gates, local retries | 90.42% object accuracy, 97.10% F1 vs 80.16-87.24% for baselines (V [2604.27906](https://arxiv.org/abs/2604.27906)); baselines unnamed in the abstract | Closest published analogue of our plan. It is dynamic; ours can be compiled. |
| EverMemBench | Benchmark | Multi-hop with multi-party attribution 26% even with oracle evidence; temporal fails without version semantics (V [2602.01313](https://arxiv.org/abs/2602.01313)) | Speaker attribution and explicit versioning are ingestion obligations. |
| MEME | Benchmark, 6 tasks incl. Cascade, Absence, Deletion | Six memory systems average 3% on Cascade and 1% on Absence; only a file agent with Opus 4.7 partly closes it, at about 70x cost (V [2605.12477](https://arxiv.org/abs/2605.12477)) | Absence and deletion are unsolved. A typed store with tombstones answers them exactly if ingestion records them. |
| TEPA / MemoryAgentBench | Conflict-resolution tests | Current-key replacement (last-write-wins) 0.890 vs append-only 0.583 on a single-hop conflict split (V~ [TEPA 2608.07429](https://arxiv.org/pdf/2608.07429), third-party method) | Keyed replacement captures most of the update gain. Declare keys; do not ask an LLM. |
| ScrapeGraphAI-100k | Distilled schema-constrained extraction | 1.7B student: key F1 0.8866 vs 0.8915 for the 30B-A3B reference; schema conformance 0.9167 vs 0.9363. Labels are teacher pseudo-labels; baselines not fine-tuned on the same targets (V [alphaXiv 2602.15189](https://www.alphaxiv.org/abs/2602.15189.md)) | A 1.7B-4B model fine-tuned for the generic skill "fill this schema" is enough. |
| NuExtract 2.0 | Fine-tuned 2B-8B extraction models | Vendor claim: beats GPT-4.1 on its own benchmark; 8B about 73 F-score (V~ [numind blog](https://numind.ai/blog/outclassing-frontier-llms----nuextract-2-0-takes-the-lead-in-information-extraction); no independent evaluation found) | Same direction; a base model to test, not evidence. |
| GLiNER2 / GLiNER-Relex | Encoder span and relation extraction | GLiNER2 CrossNER 0.590 vs GPT-4o 0.599, zero-shot classification 0.72 vs 0.84 (V~ [2507.18546](https://arxiv.org/pdf/2507.18546) snippets). GLiNER-Relex: "competitive", abstract gives no numbers (V [2605.10108](https://arxiv.org/abs/2605.10108)); a search summary says it beats GLiNER2 and GPT-5-mini on document-level sets (V~, not seen in the paper) | Encoder = good span candidates, not records. A Relex swap-in is cheap but low priority. |
| Propositioner | 0.6B model splits text into atomic propositions before extraction | Helps weak extractors' relation recall; strong LLMs need a fallback combination (V [2604.02866](https://arxiv.org/abs/2604.02866)); no numbers in the abstract | Optional; our sentence units already segment. |
| Qwen3.5 small | 0.8B/2B/4B/9B, Apache-2.0, March 2026 (V~ [Artificial Analysis](https://artificialanalysis.ai/articles/qwen3-5-small-models)); IFEval 4B 89.8, 9B 91.5 (V~ third-party) | No structured-extraction numbers found; MLX via mlx-vlm (V~), mlx-lm support unconfirmed | Candidate scorer/generator upgrade; measure. |

## 2. Ranked recommendations

Ranking = (questions unblocked x confidence) / cost. R1-R4 attack the measured root causes; R5-R6 are structural; R7-R10 are speed, training and hygiene.

### R1. Feed graph candidates into every extraction request; block ER by name containment
- **Change.** Resolve in-line at admission, not post-hoc. The request carries the graph's `referents` for each mention: exact identity keys first, then token-subset and normalised-alias match so "Elena" finds "Elena Vale", then embedding top-k within the same declared type, then thread participants and author as a prior. `resolve.py`'s closed choice (select 1 of N, NEW, UNSURE) stays as the decider.
- **Evidence.** L: 92 of 92 entity records `resolution.kind: new`, `candidates: []`; 12 questions blocked (q01, q02, q03, q06, q07, q08, q16, q17, q41, q44, q46, q48). L: chooser already fitted, 51 right / 1 wrong / 0 duplicate of 54. External: select-1-of-N beats pairwise match across 8 datasets and 10 LLMs (V [ComEM 2405.16884](https://arxiv.org/abs/2405.16884), no F1 in abstract); WorldDB reports the ER layer as +7.0 pp on LongMemEval-S (V~ via SOTA.md, preprint); Graphiti resolves in-line (V~).
- **Gain.** Up to 12 of 35 dependent questions (upper bound; some also need other fixes). Measure entities per real person (45 vs about 12 today); wrong merges must stay 0.
- **Cost.** Low: plumbing plus a blocking function, no new model.
- **Risk.** A wrong merge poisons answers. Merges are already explicit and reversible (`split`), margin fitted for "no wrong merge first". Add a hard veto: two different identity keys of one kind never merge; same first name with different surname stays UNSURE.

### R2. Replace the per-sentence 18-way record pass with one schema-compiled, grammar-constrained generation per source window
- **Fast path first (a day).** Replace the 18-way letter choice with one yes/no per plausible kind (kinds pre-filtered by encoder labels and the kind's declared description), prefix-cached, with per-kind thresholds fitted on labelled decisions. Refit `ACCEPT_RECORD`, `fitted: false` today (L). Write every drop reason into the result `log` (cached results carry `log: []`, so no drop can be diagnosed today; L). This tells us within hours whether calibration alone explains the silence.
- **Full change.** One generation per window (a chat turn group or paragraph run) of JSON lines `{kind, fields}`; each field value is a pointer to a candidate span (encoder spans plus numerals and time spans found deterministically), an enum member, or `null`. Grammar and validators come from the declared models (R5). Admission gate unchanged: every value anchors to source text, required fields present, else drop with a stored reason. Keep closed choice for ER and antecedents.
- **Evidence.** L: section 0. External: every system with high write-time numbers uses a generative extractor with validation (Hindsight V, xmemory V, ScrapeGraphAI V, NuExtract V~). Encoder-only zero-shot relation work stays weak: classification 0.72 vs 0.84 (V~), BioNLP 2025 triplet extraction no model above 0.5 F1 (R, via SOTA.md). SOTA.md already says the "LLM only scores closed choices" ban is too narrow; this is the same finding with our own failure counts behind it.
- **Gain.** Targets the 20 of 35 record-pass questions. Speed estimate: seconds per window rather than tens of seconds; measure on the 30 sources against 24 min.
- **Cost.** Medium: constrained decoding on the chosen runtime (R7), acceptance refit.
- **Risk.** A small model may invent a pointer or skip events. Mitigations: pointers to candidate spans only, anchor gate, one bounded "any other record?" glean, agreement audit (R10).

### R3. Extract validity and dates as ordinary record fields; normalise deterministically
- **Change.** Relation and state records get declared `valid_from` / `valid_until` as span-anchored time expressions. `timex.py` resolves them against the source's `received_at` and stores observed, referenced and resolved dates (Mastra's three dates, V~ via SOTA.md). The small model only picks the time span, never produces a date; an 8B query expander hurt temporal recall in LongMemEval (V~ via SOTA.md).
- **Evidence.** L: 25 of 25 relations have `validity={}`; s18 states "through 15 October 2026 inclusive. From 16 October 2026, Mina Torres is interim creative director" and none of it is read (q02-q04; q10, q12, q13, q41, q46 lose dated record fields). EverMemBench: temporal fails without version semantics (V).
- **Gain.** 3 questions directly, up to 5 more via dated records.
- **Cost.** Low-medium. **Risk.** Relative expressions need the message timestamp as reference, never ingest time; keep `test_timex.py` as the oracle.

### R4. Planner: give composite values (Money) an extraction route, and report unextractable models at compile time
- **Change.** `Plan.embeddable` stops refusing required embedded values. Money = amount (numeral span, deterministic parse of digits and separators) + currency (declared enum member or span) + declared scale. Missing parts yield a stated refusal, not silence.
- **Evidence.** L: 8 models blocked (Invoice, Payment, Quote, SalesOrder, ServiceOffer, PaymentStatus, DepositTopUp, ConversionGap), 9 questions (q19, q20, q22, q23, q25, q26, q33, q34, q39); source text is plain ("EUR 210 per jacket").
- **Gain.** Up to 9 questions. **Cost.** Low-medium. **Risk.** Locale number formats: take them from a declared locale, no hardcoded list.
- **Avra angle.** Today this is one log line (`skip Invoice: required fields without an evidence route`). The compiler knows it at declaration time: make it an `avra check` diagnostic ("model X cannot be extracted: field Y has no route"). P7, P10.

### R5. Compile extraction from the declarations
- **Change.** From each `model`, generate in one pass and hash together: the constrained grammar, the GLiNER2 label set and descriptions, field validators, per-field `never infer` marks (xmemory's idea, V), kind descriptions, key and cardinality (R6), extractor identity. Put the schema header first in the prompt and persist its KV cache per schema hash; only the source is prefilled per request. Today `Scorer.begin` caches the source as the prefix (L, `cascade.py:376-383`), which reuses work inside one source only.
- **Evidence.** xmemory's gains come from schema-governed writes (V). Closed-choice scoring is prefill-bound (SOTA.md, reasoning; blog benchmarks V~, no M1 data).
- **Gain.** Speed (removes instruction prefill per request; measure) and no drift between grammar, validator and descriptor.
- **Cost.** Medium. **Risk.** Grammar size on a large schema: two stages (pick kinds, then a small per-kind grammar).

### R6. Bitemporal write handlers declared on the model: key, cardinality, supersede versus contradict
- **Change.** A model declares its key and whether a relation is single-valued. The handler closes the prior version's validity (`superseded_by`) for a single-valued key, and records a `contradicts` link (keeping both) only when equal-authority sources disagree for the same valid time. No LLM adjudicates. Store valid time and transaction time (Graphiti, V~).
- **Evidence.** Keyed replacement 0.890 vs append-only 0.583 (V~ TEPA, third-party, one split). WorldDB handler-per-edge-type (V~ via SOTA.md). EverMemBench version semantics (V). MEME Deletion/Absence near zero for six systems (V): they need tombstones.
- **Gain.** "Who held the role on date D" and update questions. **Cost.** Medium; engine change. **Risk.** A wrong cardinality declaration hides history; always keep history, change only which row is current.

### R7. Runtime: benchmark the generator and constrained decoding on this Mac (another lane owns heavy runs)
- **Candidates.** (a) mlx-lm with a hand-built logit processor enforcing the per-kind grammar (the pointer vocabulary is small); (b) llama.cpp with GBNF/llguidance plus KV prefix cache; (c) stay on MLX, generate the JSON skeleton in code and use letter-token choices only for pointers. (c) needs no grammar engine and keeps today's reliability.
- **Evidence.** One blog says `mlx_lm` silently ignores `response_format` (V~, single post; check the source). JSONSchemaBench: constrained decoding helps and llguidance has the best coverage (V~ via SOTA.md). Qwen3.5 4B/9B available (V~); extraction quality unmeasured.
- **Risk.** A model swap changes the extractor identity and invalidates every fitted parameter (they record the scorer revision); budget a refit.

### R8. Skills fine-tuning on schema-sampled invented worlds (self-verifying)
- **Change.** A world sampler draws structured ground truth from declared schemas of invented domains (not the owner's models, not fixtures): entities, relations with validity, state records, corrections, negations, deletions. A model verbalises each world into messy sources. The extractor must recover the exact records; keep only verbalisations whose truth is recoverable. Train a LoRA on the generic skill: fill a schema, point to spans, abstain, never infer.
- **Evidence.** Distilled small extractors reach teacher quality on schema extraction (ScrapeGraphAI, V; caveat above). Synthetic schema-and-guideline generation lifts zero-shot NER up to 7 F1 (V~ [GUIDEX](https://preview.aclanthology.org/credits/2025.findings-acl.1245)). Round-trip filtering of synthetic graph-to-text data lets LLMs bootstrap their own triple extraction (V~ abstract only, [Zeinalipour et al., ACL 2026 Industry](https://aclanthology.org/2026.acl-industry.140); datasets and gains unread). Our twist: the label is the world state, so no annotator or teacher label.
- **Constraint check.** Fits "skills, not data" (invented domains only) and "nothing hardcoded" (schemas sampled, not templates). Needs a verbaliser (open question 1).
- **Gain.** Unknown; do it after R2 gives a baseline. **Cost.** High. **Risk.** Synthetic-to-real gap; touch the sealed held-out set once.

### R9. Background consolidation (sleep-time) for cross-source work
- **Change.** When idle, with the model resident: batch re-resolution of name-only entities with full blocking, staged `same_as` proposals, supersession and contradiction sweeps. Incremental by dirtiness. Ingestion and consolidation never overlap, which respects one resident model.
- **Evidence.** Letta sleep-time agents consolidate and deduplicate memory in downtime (V~ [Letta](https://letta.com/blog/sleep-time-compute); no ER evidence found); offline compute helps most when later queries are predictable (V~ commentary).
- **Gain.** Fixes late evidence (a surname in source 20 for the "Elena" of source 2) off the critical path. **Cost.** Medium. **Risk.** Retroactive merges change past answers; record them as store revisions.

### R10. Extraction-versus-reader agreement as an audit now, a reward later
- **Change.** After admission, a reader answers questions generated from the admitted records (the compiler knows each model's question shapes) from the raw text. Disagreement flags the record, triggers one targeted re-extraction, or asks the user. On synthetic worlds (R8) the same agreement is a verifiable reward.
- **Evidence.** REMem: time-aware gists plus facts and an agentic retriever give +3.4 and +13.4 absolute and more robust refusal (V [2602.13530](https://arxiv.org/abs/2602.13530)). RLVR for relation extraction: 7B near 70% out-of-domain (V~ [R1-RE](https://arxiv.org/html/2507.04642v1)); a community GRPO graph extractor with reference-free rewards (V~ [model card](https://huggingface.co/rst0070/tiny-graph-extractor-qwen3.5-0.8b-qlora)). Nobody tests this on a personal graph.
- **Cost.** Medium-high. **Risk.** Extractor and reader share blind spots; use different prompts and treat disagreement as a flag only.

## 3. Answers to the brief's questions

- **4B LLM + GLiNER2 the right extractor?** The pairing yes, the division of labour no. GLiNER2 for spans (V~ near-parity NER). The 4B should generate records under constraint (R2), not rank 18 kinds per sentence. Try a 9B only after R2; one resident model plus GLiNER2 and an embedder leaves little headroom (9B 8-bit is about 9.8 GB, V~).
- **Post-admit ER right?** Not alone. In-line with candidates plus a background pass (R1, R9). The mechanism (select 1 of N, fitted margin, reversible merge) is right.
- **Schema-conditioned, open IE then canonicalise, or other?** Schema-conditioned: abstention depends on "not in the schema". Open IE (KGGen, AutoSchemaKG: V~ via SOTA.md) is a source of schema suggestions only.
- **Learned or induced schema?** Propose, never apply: cluster rejected or "other" records and emit a model diff as Avra source for the user to accept (P11). Evidence is weak (AutoSchemaKG 92-95% alignment, V~ via SOTA.md). Low priority.
- **Incremental and streaming?** Already one source per unit with hash skip. Add window-level result streaming, the schema-prefix KV cache (R5), and encoder-gated routing so a source with no candidate spans skips the generator.
- **Provenance granularity.** Keep exact evidence spans. Store normalised values with their evidence span and normalisation recorded separately (SOTA.md argues the same). Add the producing run and the grammar/prompt identity.
- **Coreference.** Keep the closed-choice antecedent step with speaker/addressee frames and "cannot tell" as first-class. Evidence is thin: LLM coreference in CRAC 2025 matched a pairwise system at higher cost (V~ [2025.crac-1.10](https://aclanthology.org/2025.crac-1.10.pdf)); LLMs disambiguate well but badly detect ambiguity (V~ [2509.14456](https://arxiv.org/abs/2509.14456v2)), so the abstain threshold must be fitted. A Maverick or xCoRe chain generator is untested here (R); try it only if antecedent calls dominate time after R2.
- **Negation, factuality, quotes.** Keep the FactBank-style fields (`CT+`, `Uu`, `PS+`), emitted in the same generation as a closed enum. No small-model evidence exists; MAVEN-Fact calls event factuality hard for fine-tuned models and LLMs (V~ [2407.15352](https://arxiv.org/abs/2407.15352)). Measure on our set; R8 worlds can include negated, planned and quoted statements with known labels.

## 4. Keep as-is, and why

| Keep | Why |
|---|---|
| Admission gate: exact anchors, validators, partial-claim admission | RECALL.md: 0 refusals, 0 problems in 119 records. The gate is not the loss. |
| Extractor identity hashing its code; fitted params with provenance and data hashes | Reproducible numbers; it is what exposed `accept_record fitted: false`. |
| Closed-choice scorer for ER and antecedents | Fitted, 1 wrong of 54; select-1-of-N is the evidenced formulation (V ComEM). |
| GLiNER2 for span candidates | Near-parity NER at about 205M parameters (V~). Swap to Relex only if measured better. |
| Deterministic `timex.py` | Small LLMs hurt time handling (V~). Extend it (R3), do not replace it. |
| One resident generative model behind a socket | Owner constraint; avoids per-request load. |
| Reversible merge/split, confidence as metadata | WorldDB, Graphiti, Hindsight keep corrections as new, reversible state (V~/V). |
| Content-hash skip, dirty-run scheduling | Cheapest speedup there is. |
| Abstention and exact-span citation | Matches the citation-lock result (V~ Agent Zero via SOTA.md). |

## 5. Beyond SoTA: what only this setup can do

1. **Schema-sampled, self-verifying training (R8).** The compiler holds the declared models, so it can sample ground-truth worlds from them, verbalise, and check exact recovery. Published synthetic-IE work needs an annotating teacher (GUIDEX, ScrapeGraphAI) or round-trip filters on triples only (Zeinalipour, V~). A declared bitemporal schema yields labels for entities, validity, negation, supersession and deletion together, with no personal data and no annotator.
2. **Extractability as a compile-time property (R4, R5).** `avra check` states which models have no extraction route, which fields can never be inferred, and which schema edits invalidate which cached extractions. The surveyed systems find this at run time or never; here it was a log line hiding 9 questions.
3. **Supersession by declaration (R6).** Key and cardinality compile into the write handler; no LLM adjudicates updates. The one third-party datum (V~) says keyed replacement captures most of the gain.
4. **Absence and deletion as typed facts.** MEME: 3% and 1% for six systems (V). A store with tombstones and closed validity answers "no record of X" and "X was removed" exactly, provided ingestion records negations and retractions as first-class records.
5. **Extraction-versus-reader agreement (R10)** as an audit on real sources and a verifiable reward on synthetic worlds where the compiler knows the truth.

## 6. Order of work

1. R1 plumbing, then count entities per real person on the 30 sources.
2. R2 fast path (per-kind yes/no, refit, drop reasons logged).
3. R3 and R4 in the planner.
4. R7 benchmark decides R2's full design; R5 and R6 follow.
5. R8, R9, R10 after a measured baseline.

## 7. Open questions for the owner

- R8 needs a verbaliser for invented worlds. Is a development-time use of a hosted frontier model on invented content acceptable under "fully local", or must the generator be a local model run offline?
- Is fitting thresholds on the dev oracle (as `calibrate.py` does today) acceptable, or should R2's thresholds be fitted on schema-sampled synthetic worlds only, keeping fixtures out of every fit?

## 8. Not verified

GLiNER-Relex numbers (abstract only), NuExtract 2.0 independent results, any 4B/9B structured-extraction benchmark, mlx-lm constrained-decoding behaviour, ComEM F1 and cost figures, the WorldDB ER ablation (+7.0 pp) and Agent Zero numbers (carried from SOTA.md, not re-fetched), and the Zeinalipour paper body. All gain estimates are mine and untested.
