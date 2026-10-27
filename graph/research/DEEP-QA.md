# DEEP-QA: question answering for the local personal graph

Researched 2026-10-26. Builds on QA-RESEARCH.md (2026-10-25), SOTA.md, RESEARCH.md; not repeated.
Labels: **V** = read at a fetched source this session. **S** = search-result snippet only, page not read. **R** = recalled, or carried from QA-RESEARCH.md unverified. **E** = my estimate, not measured.
Web access returned abstracts and snippets, not result tables. No source tests a 4B model on KBQA over a personal typed schema. Every transfer is by analogy.

## 0. What the bench actually says (read from p1-bench.out, latest run)

The latest run (bench-20261025T162947) is 85/109 decisions, 4/13 walks. The brief says 87/109; this file is the 85 run.

| Decision kind | right / total |
|---|---|
| anchor, mode, recorded, kind | 6/6, 13/13, 9/9, 1/1 |
| arrival | 13/15 |
| speaker gate | 11/13 |
| **hop** | **3/7** |
| **narrowing** | **5/9** |
| **property** | **11/17** |
| **property more** | **13/19** |

Hop, narrowing and the two property kinds hold **20 of the 24 errors**. Every one is a choice among siblings (`actor` / `requested_by` / `assignee`) or among filters. Gold plans in `gold.jsonl` show it: q46 vs q47 differ only in which sibling reference to the same Person is followed. The kinds that are label-decidable (mode, recorded, anchor, kind) are already near-perfect.

So the question is not "is a 4B good at planning". It is "can the LM be taken out of the sibling choices, where labels carry no signal and the data does".

## 1. Is query planning the right paradigm? Paradigm verdicts

| Paradigm | Verdict for us | Evidence |
|---|---|---|
| Greedy stepwise LM walk (current) | Wrong for sibling decisions. Right for mode/recorded/anchor. | Bench above. Per-step ~0.78 over ~8 steps predicts ~0.17 if independent; seen 0.31 (correlated). |
| Whole-plan generation, grammar-constrained, 4B zero-shot | Weak without training; helps validity, not correctness. | Qwen3-4B 43.9, 8B 47.5 zero-shot BIRD (R via UniQL, QA-RESEARCH). Constrained beam beats sample+vote at equal budget, bigger model beats more compute, Spider, Qwen2.5 0.5-7B 4-bit (**V** abstract, [2608.25761](https://arxiv.org/abs/2608.25761); no numbers in the abstract). |
| Enumerate typed plans, execute, discriminate (Pangu/TIARA family) | Best fit. Our schema is small and typed, so enumeration is cheap. | TIARA executes beam candidates and takes the first valid; +4.1 F1 GrailQA, +1.1 WebQSP over prior SOTA (**S**, [2210.12925](https://arxiv.org/pdf/2210.12925)). Pangu: BERT-base discriminator suffices (R, [2212.09736](https://arxiv.org/abs/2212.09736)). |
| Retrieve-and-read | Right for point lookups and fuzzy relation words; wrong for counts, orderings, exhaustive sets. | TAG, POSTTEXT, SynTQA (R, from QA-RESEARCH). |
| Graph walk / PPR (HippoRAG 2) | Good as a no-LLM candidate generator and fallback; not an answerer. Graph alone lost to dense on simple QA. | SOTA.md (HippoRAG 2 F1 59.8 vs dense 57.0; R/PR). |
| Learned dense retrieval over facts | Needed for the read path; already planned in SOTA.md rec 3. | Hindsight 83.6 LongMemEval open reader (R, SOTA.md). |
| Hybrid router | Yes, but route by **disagreement between independent derivations**, not by a classifier over words. See rec 3. | n/a (our design). |

**Answer to "is enumerate-all inefficient?"** Only if it enumerates plans. Enumerate *behaviours* instead. Do a meet-in-the-middle search: anchors (linked entities, from the linker) on one side, target type (one closed choice: which property is asked) on the other, and the k-shortest typed schema paths between them. Execute each path with early-empty pruning, then merge paths whose result-set fingerprint is equal. The number of paths between two types in a ~70-model schema is a measurable quantity; I could not find it published, so measure it first (rec 1). If it is large, the beam lane's execution pruning is the right tool and complements this.

## 2. Ranked recommendations

### R1. Zero-LM oracle@k diagnostic before building anything. Cost: about a day. Risk: none.
- **Change:** for the 13 walks and the 36+16 questions, enumerate anchor-to-target typed paths from the gold anchors and target; record (a) path count, (b) whether gold is in the set, (c) whether "consume every linked mention + non-empty result" uniquely selects gold with no model.
- **Evidence:** this is the experiment QA-RESEARCH already named; no new source needed. It decides everything below: if oracle@k is ~100% and mention coverage already selects gold on most failing walks, the 4B is almost unnecessary for planning.
- **Gain:** E: decides between R2 and R5 on data instead of opinion.

### R2. Contrastive, execution-derived discrimination over distinct behaviours. **Main recommendation.**
- **Change:** after R1's enumeration, group candidates by result-set fingerprint. For each group the DB computes a *difference description*: the entities reached, the sibling relation used, and the sample rows ("via recipient: Bob's tasks; via actor: Alice's tasks"). Ask the model ONE closed question over 2-6 behaviours, with the question and the differences shown. Unlike now, the options differ in **data**, not names.
- **Evidence:** the failing decisions are siblings; value-grounded linking is the standard cure when names are ambiguous (BRIDGE, CHESS; R). Execution-based grounding raised confidence AUC from 68.1 to 79.1 on BIRD for GPT-3.5 in the confidence-estimation paper (**V**, [2508.14056](https://arxiv.org/html/2508.14056v1)), i.e. the execution result is real information the label lacks. Does not extend that paper to a 4B (not tested).
- **Expected gain:** E: complete-walk accuracy moves toward oracle@k. Not quantifiable before R1. Dev set is 13 walks (4/13 has Wilson CI ~12-61%), so only a >15-point move is visible.
- **Cost:** enumerator plus a contrast renderer; one LM call. The DB and engine already exist.
- **Risk:** candidates that return identical results by coincidence (merge them, they are one behaviour); questions with no linked entity (pure aggregates; route to R4).

### R3. Two independent derivations must agree, or the system says so. Abstention without a threshold.
- **Change:** answer = rows (plan path). Independently run a no-LLM retrieval path: PPR from the same anchors over the fact graph, plus FTS/embedding over verbalized facts. Confidence is **set agreement of cited fact ids** between the winning behaviour and retrieval top-k. Agree: answer with citations. Disagree: return both interpretations with their sources (ambiguity as a result), or abstain if neither is supported. No numeric cutoff: "the answer's support facts are in retrieved set" is a boolean.
- **Evidence:** execution-based consistency was the best black-box confidence method on text-to-SQL, AUC 67.4 vs white-box SQL-aware 79.1 (**V**, 2508.14056, GPT-3.5, BIRD). Output-confidence readouts reached only 0.54-0.67 AUROC at detecting unanswerable questions across five 2-14B models (**S**, [Two Axes, 2607.08456](https://www.alphaxiv.org/abs/2607.08456)); the fetched abstract adds that answer-confidence is "nearly blind" to answerability and does not improve with scale (**V**). So a likelihood threshold on the 4B is the wrong abstention signal; structural agreement is not a likelihood.
- **Gain:** E: converts a share of wrong answers into abstentions or dual answers; the wrong-answer rate, not accuracy, is the metric to report.
- **Cost:** PPR is cheap and LLM-free. Needs the verbalized-facts index SOTA.md already proposes.
- **Risk:** correlated errors (both paths follow the same wrong sibling) are not caught; retrieval of a verbalized fact that includes "actor:" and "recipient:" labels mitigates, but this is untested.

### R4. A learned cross-encoder over verbalized candidate behaviours; no resident 4B on the hot path. Optional, trained as a skill.
- **Change:** each candidate behaviour has a compiler-generated verbalization (declared relation phrases, enum values, property descriptions, plus 2-3 result values). A ~100M cross-encoder scores (question, verbalization). Train on **invented schemas** where the compiler samples plans, executes them for gold, and an offline LLM paraphrases the questions. It learns the skill "match a question to a path description", not any schema's facts.
- **Evidence:** Pangu showed a BERT-base discriminator over executable candidates reaches SOTA (R). RESDSQL decouples schema ranking from decoding with a cross-encoder (R, AAAI 2023, [2302.05965](https://arxiv.org/pdf/2302.05965)). Counter-evidence: SyntheT2C found template-only synthetic data made Cypher worse than no SFT (R, [2406.10710](https://arxiv.org/html/2406.10710v1)), and both our LoRAs failed. The difference to defend: the target is a discriminator, so questions need real paraphrase diversity, and the schemas must be invented and varied.
- **Gain:** E: fits the 8B/4B RAM constraint (frees the generative model on the planning step). Not quantifiable.
- **Cost:** one training run on invented domains; ~100M model resident.
- **Risk:** invented-schema generalization to the owner's real schema is untested. Order: do R2 first (no training), use R4 only if R2's discriminator is the measured weak point (oracle@k high, top-1 low).

### R5. Grammar-constrained whole-plan generation as candidate generator for aggregates and no-anchor questions
- **Change:** compile the declared schema into a grammar (XGrammar-2 or equivalent, schema identifiers as enums, so no hallucinated name). Generate with beam, execute, group by result. Used only when R1's enumerator has nothing to anchor (counts, orderings, temporal filters).
- **Evidence:** constrained beam beats vote at matched budget in small models (**V** abstract, 2608.25761); XGrammar-2 reports ~10 ms compilation and >6x over prior engines, self-reported, preprint (**S**, [2601.04426](https://arxiv.org/pdf/2601.04426)). Execution-guided sampling gave Qwen2.5-Coder-7B about +10 points with as few as three samples (**S**, themoonlight review of Query and Conquer; not the paper).
- **Gain:** E: needed for coverage, not for the sibling failures.
- **Cost:** grammar per schema (cached by compiler fingerprint). **Risk:** weak zero-shot 4B; this does not fix siblings.
- **Whether the compiler should generate a typed query DSL:** yes, and it makes both R2 and R5 safe (every output parses, type-checks, and has a provenance-bearing plan). The DSL is the plan IR the enumerator already builds; the grammar is its projection (P12, one source of truth).

### R6. Answer text is assembled from rows, never generated
- **Change:** cited answers are rendered by the engine from the winning behaviour's rows and fact ids, using the schema's declared type renderers. The LM never writes an answer fact.
- **Evidence:** the citation-lock idea (answer may cite only evidence actually opened; Agent Zero Memory, preprint, R from SOTA.md) shows the shape; the Eywa preprint also claims provenance-grounded memory (**S**, [2605.30771](https://arxiv.org/pdf/2605.30771); its tables were not readable).
- **Gain:** fabrication of fact content becomes impossible by construction. Remaining error is plan choice, which R2/R3 address.
- **Risk:** stiff phrasing; acceptable for a cited-answer product.

### R7. Fix the evaluator before trusting any gain
- Grow the dev set by compiler-sampled plans plus offline paraphrase (invented domains only), keep the 36+16 as held-out, and run paired McNemar per question. 13 walks cannot see a 10-point move.
- Public memory benchmarks (LoCoMo, LongMemEval) have no typed schema and mostly vendor-reported numbers (Mem0 roundup 92.5 / 94.4 is self-reported, some disputed; **S**, [mem0.ai](https://mem0.ai/blog/ai-memory-benchmarks)). Use them only for the read path (R3's retrieval half), not to compare plan accuracy. Eywa notes its external LoCoMo rows are not controlled reproductions (**S**).

## 3. What to keep

- The declared-catalog design: no word lists, closed choices, declarations as the evidence source.
- The decision kinds that already work: anchor 6/6, mode 13/13, recorded 9/9, kind 1/1. Keep them as LM closed choices; the router in R3 does not need them replaced.
- Speaker-relative resolution ("my wife"): speaker gate 11/13, gold q01/q06 pass. Keep the declared relation phrase plus self entity mechanism.
- The planner's own principle "a choice the evidence settles alone is taken without the model". It is R2's law, applied earlier.
- The engine and graph: 36/36 on hand-written plans.
- Order-debiased scoring (`odds`, forward and reverse): it is the only part of option scoring that removes a known bias; use it inside R2's single question.

## 4. Do not do

- A third LoRA on the choice format before R1/R2. Two have failed; SyntheT2C is the independent warning (R).
- A bigger resident model. Qwen3-8B was worse; zero-shot 4B to 8B was +3.5 on BIRD (R).
- Likelihood or self-reported confidence as the abstention signal (V/S above).
- Community summaries (GraphRAG, LightRAG): below dense in HippoRAG 2's harness (R, SOTA.md).
- Hand-written exemplars (KB-BINDER, DIN-SQL style): excluded by the owner.

## 5. Beyond SoTA: ambiguity as a first-class, DB-computed result

Published KBQA treats a question as having one answer and the model as the judge of which plan is right. Our setup has three things no published system has together:

1. **The compiler knows the typed schema and its declared phrases**, so every candidate behaviour has a lossless, generated verbalization and a grammar (P10, P12).
2. **A local DB that executes any candidate in milliseconds with fact-level provenance**, so each behaviour carries its *support set* (the fact ids it used), not only its result (P7, P9).
3. **Sibling relations are declared**, so the system can say *why* two plans differ.

The angle: **compute the contrast, don't ask the model to guess it.** For each pair of surviving behaviours the DB derives the difference (relation used, entities reached, support facts only one sees). The model sees data, not labels (R2). If the question cannot separate the behaviours, and R3's independent derivation does not settle it, the system returns **both answers, each labelled with its interpretation and sources**, instead of picking or abstaining blindly. This turns the dominant failure (sibling confusion) into a correct, cited, inspectable output, and the abstention signal is structural agreement of support sets rather than a likelihood threshold, which Two Axes (V) shows is blind to answerability. Nothing in it is hardcoded; every piece is a declaration, an execution fact, or a closed choice.

Falsifiable claim: on the 13 failing walks, "consume every linked mention, then merge by result fingerprint" leaves at most 2-3 behaviours, and gold is among them (R1 tests this with no model).

## 6. Sources checked this session

- V: [2608.25761](https://arxiv.org/abs/2608.25761) (abstract), [2508.14056](https://arxiv.org/html/2508.14056v1) (abstract + numbers), [2607.08456](https://www.alphaxiv.org/abs/2607.08456) (abstract).
- Partial: [SALR 2609.20398](https://arxiv.org/abs/2609.20398): latent schema-anchored reasoning, +2.86 F1 over TIARA on compositional GrailQA; backbone size and absolute scores not retrieved. Not recommended: needs training in hidden states.
- S only: XGrammar-2, TIARA, Query and Conquer, Eywa, ES-Mem ([2601.07582](https://arxiv.org/pdf/2601.07582), 3B models on LoCoMo/LongMemEval; table unreadable), Zep ([2501.13956](https://arxiv.org/abs/2501.13956): DMR 94.8 vs 93.4, "up to 18.5%" LongMemEval, from snippets).
- Text2Cypher fine-tunes on schema-in-prompt (Qwen3.5-4B LoRA 869 schemas, 53.18 exec-EM on neo4j/text2cypher-2024v1) are model-card claims, not papers (**S**). No peer-reviewed result found on whether invented-schema training transfers to an unseen schema in a constrained DSL; this is the open risk for R4.
- Not found: a paper on execution-set agreement as an abstention signal for small models. R3 is therefore an extrapolation from the confidence-estimation result, not a replication.
