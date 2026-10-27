# QA-RESEARCH: question to plan to answer with a 4B local model

Researched 2026-10-25. Complements SOTA.md and RESEARCH.md (not repeated).
Labels: **PR** peer-reviewed, **pre** arXiv preprint, **V** vendor/blog, **R** recalled from memory, NOT re-verified this session.

## 0. Evidence quality, up front

The web tool returned abstracts and snippets, not result tables. Anything under **R** must be re-checked against the paper before it is quoted in a decision. No source found tests a 4B model on KBQA/graph QA over a *personal* schema. All transfer arguments below are by analogy. Our own dev set is 36 + 16 questions and only 13 complete walks: 4/13 has a 95% Wilson interval of roughly 12-61%. Any gain under about 15 points is unmeasurable on it.

## 1. Findings by question

### 1. KBQA: candidate enumeration, discrimination, generate-then-retrieve

| Work | Idea | Evidence | Relevance |
|---|---|---|---|
| [Pangu, ACL 2023, PR](https://arxiv.org/abs/2212.09736) | A **symbolic agent enumerates valid plans by executing against the KB**; the LM only *scores* candidates. BERT-base suffices for SOTA; Codex few-shot also works. | Abstract: SOTA with BERT-base. A 2025 table lists Pangu (T5-3B) at **81.7 overall F1 on GrailQA** ([source](https://arxiv.org/pdf/2502.12737)). | Closest to our design, but the unit scored is a **whole executable plan prefix verified against the data**, not an abstract multiple-choice question. |
| [ChatKBQA, ACL Findings 2024, PR](https://arxiv.org/abs/2310.08975) | Fine-tune an LLM to emit the logical form with placeholders, then **retrieve and swap real entities and relations** by unsupervised matching. | Abstract: SOTA on WebQSP/CWQ. Fine-tuned 7B (LLaMA2-7B) per paper **[R]**. | Generation of a whole plan plus symbolic grounding. Needs supervised data. |
| TIARA / DecAF / SG-KBQA ([TIARA EMNLP 2022](https://arxiv.org/abs/2210.12925), [DecAF](https://arxiv.org/abs/2210.00063), [SG-KBQA EMNLP 2025](https://arxiv.org/abs/2502.12737)) | Multi-grained retrieval of entities, schema items and exemplars *then* generation; SG-KBQA injects **schema context into both entity retrieval and generation**. | GrailQA overall F1: TIARA 78.5, DecAF(FiD-3B) 78.7, Pangu 81.7. SG-KBQA SOTA claim (PR). | Every top system retrieves candidates first, then generates once. None walks hop by hop with independent choices. |
| [ToG](https://arxiv.org/abs/2307.07697) / StructGPT / RoG | LLM-driven stepwise exploration (ToG, StructGPT) or relation-path planning (RoG). | ToG Llama-2-70B: CWQ 53.6, WebQSP 63.7 Hits@1; ToG/StructGPT with GPT-3.5: WebQSP 76.2/75.2, CWQ 57.1/55.2 ([ReKnoS table](https://arxiv.org/pdf/2503.22166)). No-graph Llama-2-7B / Qwen2-7B: 56.4 / 50.8 WebQSP ([GCR](https://arxiv.org/pdf/2410.13080)). | Stepwise LLM exploration was built for large models. No 7B number found for ToG/StructGPT; RoG and GCR fine-tune small models (**R**). **Stepwise exploration is the family our planner belongs to.** |
| KB-BINDER | Few-shot draft then *bind* to KB items. | **R**: few-shot, Codex-class model. | Needs hand-written exemplars, so out under our rules. |

Takeaway: the small-model-viable designs (Pangu, ChatKBQA, TIARA, SG-KBQA) either **score whole executable candidates** or **generate once and ground symbolically**. The ones that ask the LM for one choice per hop are the 70B/GPT-3.5 designs.

### 2. Text-to-SQL / Cypher with 3B-8B models

| Fact | Number | Source |
|---|---|---|
| RESDSQL: decouple schema linking (a cross-encoder ranks tables/columns) from decoding | Spider dev EX 81.8 (3B), 84.1 with NatSQL | [AAAI 2023, PR](https://arxiv.org/pdf/2302.05965) |
| CHESS: value retrieval (LSH over cell values) + schema selection narrowing hundreds of columns to under ten | BIRD test 71.1; schema selection about +2 points | [pre](https://arxiv.org/abs/2405.16755) (ablation via a secondary summary) |
| OmniSQL-7B single sample, BIRD dev | 63.9; **68.9 with a best-of-32 reward-model pick** (+5.0) | [pre](https://arxiv.org/pdf/2509.01308) |
| Arctic-Text2SQL-R1-7B: RL on *execution correctness only*, plus value retrieval and majority vote | BIRD leaderboard top at 7B | [ACL Findings 2026, PR](https://arxiv.org/abs/2505.20315) |
| Zero-shot base models on BIRD: Qwen3-4B 43.9, Qwen3-8B 47.5, Qwen3-32B 49.2 | 4B to 8B is only +3.5 | [UniQL, pre](https://arxiv.org/pdf/2606.08018) |
| Qwen2.5 0.5B-7B at 4-bit, **grammar-constrained** Spider: beam search and sample+vote both help, most for the smallest models; **beam beats vote at equal budget; a bigger model beats more compute** | no table read (abstract only) | [pre, Aug 2026](https://arxiv.org/abs/2608.25761) |
| PICARD constrained decoding: T5-3B 75.5 EM vs T5-base 66.6; T5QL gets 69.3 EM with T5-base | Spider dev | [PICARD, PR](https://arxiv.org/abs/2109.05093); T5QL |
| Text2Cypher: Neo4j 44,387-instance dataset, fine-tuning raises BLEU/EM | no execution numbers read | [pre](https://arxiv.org/abs/2412.10064) |
| SyntheT2C: Llama3-8B SFT on synthetic Cypher; result accuracy 27.8 to 39.7. **Template-only synthetic data made Cypher quality *worse* than no SFT** | 300 questions, 2 medical graphs | [pre](https://arxiv.org/html/2406.10710v1) |
| JSONSchemaBench: constrained decoding raised GSM8K 80.1 to 83.7 | from SOTA.md | pre |

What this says for us:
- Constrained decoding guarantees validity, not correctness. Gains are real but small, and larger for the smallest models.
- 3B-8B models reach roughly 55-69% on hard text-to-SQL **only after task-specific training or RL**. Zero-shot 4B is in the 40s.
- Model size gives little here (4B vs 8B +3.5 zero-shot), which matches our 8B-was-worse observation.
- Data matters more than size, and **template-synthesised training data can hurt**. That is consistent with our two failed LoRAs on invented domains (though ours were not template-only; unverified).
- Execution-guided selection (reward-model pick, execution-vote, execution-only RL) is the one family with consistent gains at 7B. Its signal comes from the database.

### 3. Retrieve-then-read vs query synthesis

| Claim | Evidence |
|---|---|
| Pure RAG is limited to point lookups over a few records; counting and filtering in one LM call is error-prone | [TAG, pre](https://arxiv.org/pdf/2408.14717) |
| Routing between a SQL-style view engine and a retrieval engine; SQL wins on counting/aggregation | [POSTTEXT, pre](https://arxiv.org/pdf/2306.01061), small GPT-3.5 study |
| Mixture of text-to-SQL and end-to-end reading beats either | [SynTQA, pre](https://arxiv.org/pdf/2409.16682) |
| RAG beats GraphRAG on detail lookups; graphs win on multi-hop and summaries | SOTA.md (RAG-vs-GraphRAG, GraphRAG-Bench) |
| Open-model memory with multi-channel retrieval, RRF and cross-encoder reaches 83.6% LongMemEval (20B reader) | SOTA.md, Hindsight |

Reading beats query writing when the answer is a span or a short list inside a few retrieved facts and the question's relation words are fuzzy. Querying wins when the answer is an aggregate, an ordering, a temporal filter or an exhaustive set. Both failure modes exist: the reader misses items, and the planner picks the wrong sibling edge. No paper tested a 4B reader on this split.

### 4. Value-grounded schema linking (our exact failure)

| Work | Mechanism | Evidence |
|---|---|---|
| [BRIDGE, EMNLP Findings 2020, PR](https://arxiv.org/pdf/2012.12627) | Fuzzy-match question spans to the *picklist of each field*; append the matched cell value after the field name in the encoder input. | Spider dev 71.1 (ensemble). The abstract motivates it with coded columns that field names alone cannot link. No with/without ablation retrieved. |
| CHESS | Value retrieval over millions of rows by LSH + vectors. | See table above. |
| Arctic-Text2SQL-R1 | Value retrieval as an extension of the RL model. | Findings ACL 2026. |
| RESDSQL | A learned cross-encoder ranks schema items before decoding. | AAAI 2023. |
| RSL-SQL, Graph-Link (ICML 2026) | Robust or constrained schema linking. | [RSL-SQL](https://arxiv.org/html/2411.00073v2); not read. |

No paper isolates sibling-field disambiguation (actor vs recipient). The indirect evidence is that value and entity matches are the standard cure when names are ambiguous or coded. **Our sibling references are the same problem seen from the graph side**: if the question mentions "Alice" and the linked entity Alice appears in exactly one of `actor` / `recipient` / `requested_by` on the candidate records, the data answers what the label cannot. That is an unpublished-in-this-form but small extrapolation, and it needs no examples or thresholds, because it is an execution fact (does the plan reach a non-empty result that contains the mentioned entity).

### 5. Offline / on-device personal assistants

Nothing found does graph QA over a personal schema with a sub-8B model. Nearest: Hindsight (20B open reader, 83.6, see SOTA.md), Mastra observation memory (V), and small tool-calling models (SmolLM3-3B BFCL 92.3, Cactus Needle, V) that do **single-step function selection** well. Small-model tool calling is strong when the choice is one call among typed functions and weak on deep multi-hop. Apple/Microsoft on-device work was not retrievable with the tool; no claim is made.

## 2. What does NOT work, and whether it matches us

| Does not work | Evidence | Matches our experience? |
|---|---|---|
| Stepwise LLM exploration with small models (errors compound) | ToG/StructGPT are tuned for 70B/GPT-3.5; 7B no-graph baselines 25-56 | Yes: 87/109 per decision gives 4/13 walks. A per-step rate of about 0.8 over about 8 steps predicts about 0.17 if independent; we see 0.31, so errors are correlated (siblings fail together). |
| Bigger model | Qwen3 4B to 8B +3.5 zero-shot BIRD | Yes (8B was worse). |
| Template-synthesised or invented-domain fine-tuning | SyntheT2C: template-only SFT lowers quality | Plausibly (both LoRAs failed). |
| Beam search over *unverified* candidates | The small-model grammar paper shows beam helps, but only with constraint and at fixed grammar | Mixed: our beam gave nothing. Candidates ranked by LM likelihood alone share the LM's error; the paper's gains come from a constrained space. Unverified for our case. |
| Likelihood scoring of options | Not isolated in any paper found | Matches. Sibling options have near-identical likelihood by construction. |
| Embedding shortlist of kinds | Retrieval of schema items helps in RESDSQL/CHESS, but they use a *trained* cross-encoder and *values* | Partly: we shortlisted by names only. |
| Hand-written few-shot exemplars (KB-BINDER, DIN-SQL) | Constraint violation for us | Excluded by rules. |
| Graph community summaries for fact lookup | SOTA.md | Not relevant. |

## 3. Recommendations (ranked)

### A. Execution-grounded whole-plan selection (Pangu-style), values as the discriminator. **Recommended first.**

1. Link question mentions to entities (GLiNER2 spans + exact/FTS + embedding, already available). This gives *anchors with real IDs*.
2. **Enumerate** every schema-valid plan from the anchors up to depth k by symbolic search. This is a typed graph, so it is cheap and `closed`. Sibling references become distinct candidate plans, not an LM choice.
3. **Execute** each plan. Drop plans that are type-invalid or empty. Deterministic constraint: a plan must *consume every linked mention* (the mentioned entity must appear on its path, in the arrival set or in a narrowing). This resolves actor/recipient/requested_by wherever the data differs.
4. Rank survivors with a fixed ordering of facts, not a threshold: (i) mention coverage, (ii) then a model verdict. Render each survivor as a schema-derived paraphrase (role descriptions come from the model declarations) plus 2-3 actual result values. Ask the cross-encoder / Qwen3-4B one question: which description answers the question. Single decision over about 3-10 items, not 8 chained ones.
5. Abstain when no plan covers all mentions, or the top two differ only by an unseen sibling and return different results (surface both, with sources).

- Expected gain: complete-walk accuracy should approach the oracle@k of the candidate set. Per-decision errors stop compounding. I can't give a number; the Pangu result (BERT-base SOTA, T5-3B 81.7 F1 GrailQA) shows the shape works at small scale **[R/PR]**, not that we get 80%.
- Cost: an enumerator and an executor (we have the engine), one LM call per question. Latency low.
- Risks: candidate explosion at depth (needs a closed prune: empty-result and type constraints, not a magic cap); questions with no named entity (pure aggregates); the "consume every mention" rule needs a closed notion of mention (take it from the linker, not from words).
- Measure: log oracle@k (is a gold plan in the enumerated set?), top-1 plan accuracy, complete-walk accuracy, abstain rate and wrong-answer rate on 36 dev + 16 portability. Run paired against the current planner so the 52 questions detect per-question flips (McNemar). If oracle@k is high and top-1 low, the discriminator is the problem; if oracle@k is low, enumeration or linking is.

### B. Plan generation once, under a schema grammar, then ground and verify (ChatKBQA / SG-KBQA / Arctic family)

Generate the full plan in a small DSL with xgrammar/llguidance constrained to the declared schema (identifiers are enums, so no hallucinated names), sample N, **execute all, vote on result sets** (execution-guided self-consistency, the one technique that gave +5 at 7B). Plan the grammar to emit value placeholders linked via step A's anchors.
- Expected gain: modest on its own; best as the candidate generator inside A for non-entity questions. Beam beat voting at equal budget in the small-model grammar paper (pre).
- Cost: grammar compilation per schema; N plan generations on 4B at M1 speed (prefill-bound, share the schema prefix).
- Risk: the base 4B zero-shot is weak (Qwen3-4B 43.9 on BIRD); training would fix it, but invented/templated data failed twice here and in SyntheT2C. Do **not** add a third LoRA before A.
- Measure: same metrics, plus validity rate and distinct-result-set count among N samples.

### C. Hybrid router: retrieve-then-read by default, structured ops for aggregates/temporal

Run multi-channel retrieval (FTS, embedding, graph walk from anchors, cross-encoder) over verbalised facts. The 4B reads the top facts and answers with citations (citation lock, abstain otherwise). Only questions the schema classifies as aggregate/ordering/temporal go to the plan engine, with plan = A.
- Expected gain: removes sibling-relation choice for lookup questions entirely (the reader sees "actor: Alice, recipient: Bob" in the fact text). Weak on counts and exhaustive sets (TAG, POSTTEXT).
- Cost: a reader prompt and a router. Router must be learned/fitted, not keyword-based. A closed choice over operation types declared in the engine, using the same enumeration as A.
- Risks: 4B reading accuracy unmeasured; losing structured provenance; it may paper over rather than fix planning.
- Measure: oracle-retrieval run (gold facts given) to separate reader error from retrieval error; report per question type.

Order: A, then A+B generator, with C as the fallback path when A abstains.

## 4. Verdict

**Not fundamentally flawed; under-explored in the wrong place.** The closed-choice idea (schema-constrained, enumerated options) is the same bet Pangu won with, and a small model is fine as a *discriminator*. What is flawed is the **sequence**: greedy, abstract, per-step questions where each wrong step is unrecoverable and sibling options are indistinguishable from names. Evidence:
- Every small-model-viable KBQA system scores whole candidates or generates once; stepwise exploration appears with 70B/GPT-3.5 models.
- Per-step 80% across about 8 steps explains 4/13 almost by itself.
- Our failing decisions (siblings, ambiguous narrowings) are exactly the ones data resolves and labels cannot (value-grounded linking, BRIDGE/CHESS lineage).
- What we tried (more LM likelihood, bigger LM, more beam, name-only shortlists) all draw on the same label-only signal, which explains why none moved the result.

Caveats: no paper tests this on a ~70-model personal schema with a 4B; the dev set is too small to see small gains; the claim that value/execution grounding fixes siblings is an extrapolation until oracle@k is measured. The one-day experiment that tests the verdict: enumerate plans for the 13 failing walks and compute oracle@k and "mention-coverage uniquely selects gold" with no LM at all.
