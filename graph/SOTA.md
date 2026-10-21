# SOTA: building and maintaining personal knowledge graphs / agent memory (2024–2026)

Researched 2026-10-21. Complements `avra-graph-v2/graph/RESEARCH.md`; it does not repeat the GLiNER2/ReLiK/Maverick/CREL rows there.
Legend: **PR** = peer-reviewed venue. **pre** = arXiv preprint. **V** = vendor self-report (often disputed).
"Local?": can the published configuration run fully offline on an M1 with 16 GB?

## 0. Read this first: the benchmark numbers are mostly not trustworthy

| Fact | Evidence |
|---|---|
| LoCoMo is broken as a ranking instrument | Audit: 99/1540 answer keys wrong (6.4%); the LLM judge accepted 62.8% of deliberately wrong answers ([Penfield audit](https://penfieldlabs.substack.com/p/we-audited-locomo-64-of-the-answer), blog, with scripts). Zep says category 5 has no ground truth ([Zep](https://blog.getzep.com/lies-damn-lies-statistics-is-mem0-really-sota-in-agent-memory/)). Mastra skipped it for the same reasons. |
| On LoCoMo, full context beats most memory systems | Mem0's own table: full-context 72.9 J vs Mem0 66.9 / Mem0g 68.4 ([Mem0, pre](https://arxiv.org/abs/2504.19413)). |
| Vendor LongMemEval claims do not reproduce | Mem0 claims 93.4%. An independent re-run (gpt-5 reader, binary judge, 5 seeds) observed **73.8%**, attributing the gap to vendor answer/judge prompts with "lean toward yes" rules ([Maximem](https://www.maximem.ai/blog/state-of-ai-memory-2026-claimed-vs-observed); itself a vendor, but it publishes prompts and archives). |
| Reader model dominates | Mastra OM: gpt-4o 84.2% → gpt-5-mini 94.9%, same memory. Hindsight: OSS-20B 83.6% → Gemini-3-Pro 91.4%. Comparing systems across readers is meaningless. |
| Multi-session aggregation is the ceiling | Best multi-session score is about 87% for both Mastra and Hindsight. EverMemBench: multi-party multi-hop reaches **26% even with oracle evidence** ([EverMemBench, pre](https://arxiv.org/abs/2602.01313)). |

**Use instead:** LongMemEval-S/M ([ICLR 2025](https://arxiv.org/abs/2410.10813)) with a pinned **local** reader and judge, EverMemBench for speaker attribution, and our own consented set. Report per-category results, never only the overall number.

## 1. Agent-memory systems

| System | Core mechanism | Best measured result | Weaknesses | Local? |
|---|---|---|---|---|
| **Zep / Graphiti** ([paper, pre](https://arxiv.org/abs/2501.13956), [repo](https://github.com/getzep/graphiti)) | Episodes (raw input, non-lossy) → entities and fact-edges. **Bi-temporal edges**: `t_valid/t_invalid` plus `created/expired`. An LLM detects contradictions and sets the old edge's `t_invalid` instead of deleting it. ER = embedding + FTS candidates, then the LLM decides. The speaker is always an entity. Writes use fixed Cypher, never LLM-written queries. Custom entity types are Pydantic models. | LongMemEval-S gpt-4o 71.2% vs full context 60.2%; latency 2.6 s vs 29 s; context 1.6k vs 115k tokens. DMR 94.8%. | Lost on single-session-assistant (80.4 vs 94.6). Many LLM calls per episode. Needs Neo4j/FalkorDB. Its 2026 standing is well below the leaders. | Partly: Ollama works, but extraction quality depends on the LLM. |
| **Mem0 / Mem0g** ([pre](https://arxiv.org/abs/2504.19413)) | An LLM extracts candidate memories, then picks ADD/UPDATE/DELETE/NOOP against the top-k similar memories. The graph variant adds entity/relation triples and a conflict resolver. | LoCoMo J 66.9 (graph 68.4), below full context at 72.9. The V-claimed 93.4% LongMemEval measured 73.8% independently. | Destructive UPDATE/DELETE (history in a side log). Weak temporal reasoning. Disputed evaluations. | Yes, with a local LLM. |
| **Hindsight** ([pre, Dec 2025](https://arxiv.org/abs/2512.12818), [repo](https://github.com/vectorize-io/hindsight)) | Four networks: world facts, agent experience, observations, and **opinions with confidence**. An LLM writes **2–5 self-contained narrative facts per exchange**, with coreference resolved, time normalised and participants attributed. ER = string similarity + co-occurrence + temporal proximity. Retrieval runs **4 channels in parallel** (vector, BM25, graph spreading activation, temporal range), fuses with **RRF k=60**, then reranks with a **cross-encoder (MiniLM-L6)**. Opinions move by ±α per reinforce/weaken/contradict. | LongMemEval-S **83.6% with open GPT-OSS-20B** vs 39.0% full context with the same model. Temporal 79.7, knowledge-update 84.6, multi-session 79.7. 91.4% with Gemini-3-Pro. LoCoMo 83.2. | No component ablation published. The 20B model is about 13 GB, tight on 16 GB. | **Yes**: the best published fully-open result. |
| **Mastra Observational Memory** ([V](https://mastra.ai/research/observational-memory)) | No retrieval at all. An *Observer* LLM compresses old turns into dated, prioritised bullet observations, each with three dates: observed, referenced, relative. A *Reflector* merges them and drops superseded items. The prompt prefix stays stable, so the cache hits. | LongMemEval-S 84.2% (gpt-4o, above the 82.4% oracle), 94.9% (gpt-5-mini). | V-only. Bounded by context size. Not a queryable graph. No provenance. | Not with its published models. |
| **WorldDB** ([pre, Apr 2026](https://arxiv.org/abs/2604.18478)) | Content-addressed immutable nodes (Merkle history). **Edge types carry write-time handlers**: a supersession closes validity, **a contradiction keeps both sides**, and `same_as` only *stages a merge proposal*. "No raw append path." | LongMemEval-S 96.4% (Claude Opus reader). Its **ER/graph layer ablates to +7.0 pp**. | Single author. Frontier reader. One benchmark. | Design yes, reported numbers no. |
| **Agent Zero Memory** ([pre, Aug 2026](https://arxiv.org/abs/2608.29606)) | Event timeline, entity-event KG, and curated fact store. An intent gate skips retrieval. A **"citation lock"** means an answer may cite only evidence actually opened; otherwise it abstains. | Claims LongMemEval 95.6, LoCoMo 93.6, with 3.4 pts spread across 8 readers. | Preprint. Readers unnamed. No measured fabrication rate. | Unknown. |
| **xmemory, schema-grounded** ([pre, 2026](https://arxiv.org/abs/2604.27906)) | The **schema says what to remember, what to ignore, and which values must never be inferred**. Write path: object detection → field detection → field-value extraction, with validation gates and local retries. Reads are constrained queries over verified records. | 97.1% F1 vs 80–87% for unnamed baselines; 90.4% object accuracy. | Baselines and models not named in the abstract. Preprint. | Unknown. |
| **A-Mem** ([NeurIPS 2025, PR](https://arxiv.org/abs/2502.12110)) | Zettelkasten notes: an LLM writes keywords, tags and context, links each new note to old ones, and *evolves* old notes. | Beats MemGPT on LoCoMo multi-hop F1. Mem0's table: 48.4 J. | Mutates old notes (provenance loss). Weak in third-party re-runs (59.8 on PersonaMem). | Yes. |
| **Letta/MemGPT, LangMem, Cognee** | Letta: an agent self-edits memory blocks plus archival search; its V blog has a plain filesystem agent at 74.0 LoCoMo. LangMem: 58.1 J (Mem0 table). Cognee: V-only HotPotQA on 24 questions. | Weak or V-only. | None worth adopting. | Yes. |

**Pattern across the top systems (Hindsight, WorldDB, Agent Zero, xmemory):** interpret at **write time** into self-contained, time-normalised, speaker-attributed facts. Keep raw episodes. Use multi-channel retrieval with fusion and a rerank. Supersede facts rather than delete them. Answer with citations. Graph structure helps mainly through **entity resolution** (WorldDB +7 pp), not graph algorithms.

## 2. KG construction from text

| Work | Mechanism | Evidence | Verdict for us |
|---|---|---|---|
| **HippoRAG 2** ([ICML 2025, PR](https://arxiv.org/abs/2502.14802)) | Open triples; phrase nodes plus **passage nodes**; synonym edges. Query → top-5 triples, then an **LLM "recognition" filter**, then Personalized PageRank seeded by phrases with passages at weight 0.05. Falls back to dense retrieval if no triple survives. | Reported average F1 59.8 vs 57.0 for NV-Embed-v2 dense (Llama-3.3-70B reader). **GraphRAG 49.6 and RAPTOR 48.8, both below plain dense**; LightRAG collapsed to 6.6 in this harness. Indexing: 99 min vs 12 min dense vs 277 min GraphRAG. | Steal PPR over entity+passage nodes for multi-hop. A graph alone loses to dense retrieval on simple QA. |
| **MS GraphRAG / LightRAG** ([LightRAG, EMNLP Findings 2025](https://preview.aclanthology.org/new-sigs/2025.findings-emnlp.568/)) | Community summaries (GraphRAG); dual-level keyword retrieval (LightRAG). | Below dense retrieval in HippoRAG 2's harness. [RAG vs GraphRAG (pre)](https://arxiv.org/abs/2502.11371): RAG wins on single-hop and detail questions, GraphRAG on multi-hop and summarisation. [GraphRAG-Bench (ICLR 2026)](https://arxiv.org/abs/2506.05690): graphs help reasoning and summarisation, not fact lookup, and quality is highly LLM-sensitive. | Skip community summaries; personal QA is mostly fact lookup. |
| **KGGen** ([pre](https://arxiv.org/abs/2502.09956)) | LLM extraction, then **iterative LLM clustering of entities and relation labels** (normalisation). | MINE ~66% vs GraphRAG 48% vs OpenIE 30% (secondary source; v2 softened to "comparable to GraphRAG"). | Steal: normalise relation labels by clustering; open extraction alone yields sparse duplicate graphs. |
| **AutoSchemaKG** ([ACL 2026, PR](https://arxiv.org/abs/2505.23628)) | Extracts entities *and events*, then **induces a schema** by conceptualising instances into types. | Induced schema aligns with human schemas 92–95%. 900M nodes. | Evidence that type proposals from clusters of unmatched instances are viable. |
| **iText2KG** ([WISE 2024, PR](https://arxiv.org/abs/2409.03284)) | Incremental: local entities are matched to global ones by cosine similarity with a threshold. | Lower false-discovery rate in resolution than baselines. | The threshold is a known weakness (the authors say so). |
| **Encoder IE at zero shot** | GLiNER2 on CrossNER: 0.590 vs GPT-4o 0.599 ([pre](https://arxiv.org/abs/2507.18546), secondary numbers). Zero-shot classification ~0.72 vs 0.84 for GPT-4o. Doc-level RE: GLiDRE ~17 F1 on DocRED ([pre](https://arxiv.org/abs/2508.00757)). BioNLP 2025: **no model above 0.5 F1** on zero-shot triplet extraction. | NER is near parity; **relations and classification are not.** | Encoders for spans, not for relations, attribution or temporal normalisation. |

## 3. Maintenance

| Problem | Best-evidenced practice | Source |
|---|---|---|
| Entity resolution over time | Generate candidates from embedding + FTS + co-occurrence + time, then a model decides. **The "select one of N candidates (or none)" formulation beats pairwise match/no-match** and is cheaper. Task-tuned small models trail GPT-4o by only ~5 F1 on *select*. | [ComEM, COLING 2025, PR](https://aclanthology.org/2025.coling-main.8); Graphiti; Hindsight |
| Value of ER | The graph/ER layer is worth +7.0 pp on LongMemEval. | WorldDB ablation (pre) |
| Contradiction / update | Invalidate, never delete: set `t_invalid` on the old fact (Graphiti). Distinguish **supersession** (closes validity) from **contradiction** (keep both, flag). EverMemBench: temporal reasoning fails "without explicit **version semantics** beyond timestamps". | Graphiti; WorldDB; EverMemBench |
| Merges | Stage a merge as a *proposal* (`same_as`). Immutable content-addressed history makes merges reversible. | WorldDB |
| Belief strength | Bounded confidence moved by reinforce (+α) / weaken (−α) / contradict (−2α), for opinions and preferences only. | Hindsight |
| Incremental cost | HippoRAG 2 indexes ~2.4× faster than LightRAG and ~2.8× faster than GraphRAG. Avoid any global re-summarisation step. | HippoRAG 2 |
| Schema evolution | No peer-reviewed system auto-evolves an ontology well. Human-in-the-loop iterative refinement is the evidenced shape ([LLMs4SchemaDiscovery, pre](https://arxiv.org/abs/2504.00752)). Fully autonomous Evo-DKD is simulated and weak ([pre](https://arxiv.org/abs/2507.21438)). AutoSchemaKG shows that clustering instances into types aligns well with human schemas. | — |
| User corrections | No benchmark measures them. WorldDB, Graphiti and Agent Zero all keep them as new facts with higher-priority provenance over immutable history. | (gap) |

## 4. Retrieval and QA over personal graphs

| Practice | Evidence |
|---|---|
| **Multi-channel + RRF + cross-encoder** (vector, BM25, graph walk, temporal range) | Hindsight (83.6% with an open 20B model); Graphiti found the cross-encoder the most accurate of its rerankers. |
| **Fact-augmented keys**: index each source round with its extracted facts as extra keys | LongMemEval (ICLR 2025): **+9.4% recall@k and +5.4% accuracy** on average; round-level R@10 0.692 → 0.784. |
| **Round-level, not session-level, values** | LongMemEval §5.2: "significantly enhances reading". |
| **Time-aware query expansion** (resolve "last spring" into a range filter) | +11.3% temporal recall with GPT-4o as the expander, but **Llama-3.1-8B made it worse** (R@5 0.421 → 0.384). A small LLM must not free-generate time ranges. |
| Keep raw text answerable | Graphiti's episodes; HippoRAG 2's passage nodes and dense fallback; RAG beats GraphRAG on detail questions. |
| Reading strategy | Chain-of-Note / JSON reading: up to +10 pts. With oracle retrieval, a bad reading strategy costs up to 10 pts. |
| Citation lock and abstention | Agent Zero (pre). Matches our "evidence-backed" contract. |
| Personal entity linking ("my wife") | Still a gap. The only benchmarks are ConEL-2 / ConEL-PE, at personal-entity-linking precision ~61–71 ([2606.13717](https://arxiv.org/abs/2606.13717)). EverMemBench shows speaker attribution is the main failure. No system resolves "my X" through a typed relation from the asker. Our join plan (RESEARCH.md) is ahead of the field here, but unmeasured. |

## 5. Small local models and runtimes (M1, 16 GB)

| Role | Candidate | Evidence | Note |
|---|---|---|---|
| Spans / NER / classification | GLiNER2 (~205M) | CrossNER ≈ GPT-4o; ~130–210 ms on CPU | Already chosen; weak at RE. |
| Embedder | **Qwen3-Embedding-0.6B** ([pre](https://arxiv.org/abs/2506.05176)) / **EmbeddingGemma-300M** ([pre](https://arxiv.org/abs/2509.20354)) | Qwen3-0.6B MTEB-eng v2 70.7. EmbeddingGemma is #1 under 500M on MTEB multilingual (~61). | Apache / Gemma licences. Both supported by llama.cpp (GGUF). |
| Reranker | Qwen3-Reranker-0.6B; ms-marco-MiniLM-L6 (used by Hindsight) | MiniLM is proven in the Hindsight stack. | A cross-encoder over the top ~50 is cheap. |
| Scorer / structured LLM | Qwen3-4B / 8B class at Q4 (~2.5 / 5 GB); GPT-OSS-20B (~13 GB) is the published open SOTA backbone but tight | Hindsight's open 20B reaches 83.6%. LongMemEval: an 8B model was a *bad* query expander. | Measure 4B vs 8B on our own set. |
| Constrained output | llguidance / XGrammar / llama.cpp GBNF | [JSONSchemaBench (ICML 2025 workshop / pre)](https://arxiv.org/abs/2501.10868): constrained decoding raises task accuracy (GSM8K 80.1 → 83.7–83.8). Guidance/llguidance has the best coverage; Outlines collapses on hard schemas. | Keep schemas simple: flat enums and spans. |
| Runtime | llama.cpp vs MLX | MLX decodes ~35% faster at 4B; **llama.cpp prefills ~4× faster** (TTFT 67 vs 289 ms) (blog benchmarks, M4/M5 — no M1 data). | Closed-choice scoring is *prefill-bound* (one forward pass per option), so favour llama.cpp with prompt/KV-prefix caching of the shared schema header. |
| Calibration | Token logprob over the closed options | Protocol-sensitive ([2605.27752, pre](https://arxiv.org/abs/2605.27752)). Logprobs are best-calibrated in MC/yes-no settings, but there is no small-model evidence. | Fit temperature/isotonic calibration on our validation set; never trust raw probabilities. |

## What our design should steal / change (ranked)

1. **Write-time fact records, not only spans: let the local LLM *propose* structured records under grammar, and keep span anchoring as the admission gate.** Every top system (Hindsight 2–5 self-contained facts per exchange; xmemory object→field→value with validation gates; Mastra observations) interprets at write time with a generative model. Encoder zero-shot RE stays below 0.5 F1 across BioNLP 2025, GLiDRE and GLiNER2 classification (0.72 vs 0.84). Keep GLiNER2 for span *candidates*. Have Qwen3-4B/8B fill the declared model's fields by grammar-constrained decoding, where each value is a choice among candidate spans or entity IDs, or a normalised value **plus its anchor span**. Adopt xmemory's per-field "**never infer**" annotation on models.
2. **Full bitemporal facts with explicit version semantics.** Use valid time and transaction time, `superseded_by` links, and a separate `contradicts` relation that keeps both sides. Evidence: Graphiti's t_valid/t_invalid design; EverMemBench (temporal fails "without explicit version semantics beyond timestamps"); WorldDB (supersede ≠ contradict).
3. **Retrieval = four channels + RRF(k=60) + cross-encoder rerank, over both facts and raw rounds.** Channels: BM25/FTS, embedding, graph walk/PPR from resolved entities, temporal range. Evidence: Hindsight 83.6% open-model; HippoRAG 2 (graph alone < dense on simple QA; PPR + passages > both); RAG vs GraphRAG.
4. **Fact-augmented keys and round-level indexing.** Store each message/round as its own retrievable value, keyed by its text plus the facts extracted from it. Evidence: +9.4% recall, +5.4% QA (LongMemEval, ICLR 2025).
5. **Entity resolution as "select 1 of N candidates or NEW/ABSTAIN", with merges as staged proposals.** Generate candidates from FTS + embedding + co-occurrence + time window, then score with the closed-choice LLM. Evidence: ComEM (select > pairwise; small models within ~5 F1); WorldDB's ER ablation (+7 pp, the biggest single lever measured); Hindsight's ER signals.
6. **Speaker, author and audience are first-class on every claim**, and "my" is bound per utterance speaker. Evidence: EverMemBench (multi-party attribution collapses to 26% even with oracle evidence); Graphiti always extracts the speaker.
7. **Time normalisation must be deterministic or closed-choice, never free-generated by a small LLM.** Store observed / referenced / relative dates (Mastra's three dates). Evidence: the 8B expander *hurt* recall in LongMemEval; Mastra and Hindsight both normalise time at write time.
8. **Schema evolution = cluster rejected or "other" candidates into proposed types/fields, with the user approving.** Do not auto-apply. Evidence: AutoSchemaKG's induced types align 92–95% with human schemas; the only HITL work that worked is LLMs4SchemaDiscovery; autonomous Evo-DKD is not credible.

### What the evidence says is WRONG in the current design

- **"Small LLM used *only* as a closed-choice scorer."** Too narrow. No evidenced system reaches high quality with encoder spans plus scoring alone. Relations, coreference, attribution and time need a generative step (grammar-constrained, span-anchored). The admission gate is right; the ban on generation is not.
- **"Bitemporal-ish."** Half-temporal fails exactly the knowledge-update and temporal categories where memory systems differ most. Make it fully bitemporal with explicit supersession.
- **Exact-span anchoring applied to *values*.** "next Friday" → a date and "she" → Person#12 are not substrings. Anchor the *evidence span* and record the normalisation separately. A literal-substring rule would reject the most valuable facts.
- **Raw-probability "calibrated choices".** Calibration is protocol-sensitive and unmeasured for small models. Fit calibration on held-out data per decision type.
- **Any plan to judge quality on LoCoMo or vendor tables.** Use LongMemEval-S/M per category, EverMemBench and our own set, with a fixed local reader and judge, and report oracle-retrieval runs.
- **(If planned) GraphRAG-style community summaries or LightRAG.** Below dense retrieval in HippoRAG 2's harness, and costly to update incrementally. Not worth building.
