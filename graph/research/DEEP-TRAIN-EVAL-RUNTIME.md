# Training, evaluation and runtime for the local graph: deep research

Written 2026-10-26. Read-only diagnosis of `graph/tune/` (worktree avra-graph-tune) and `graph/planner/bench/`; no model was run.
Evidence tags: **L** = measured in our files (path given). **V** = read on a fetched source page. **S** = search snippet only, not opened. **R** = recalled, not re-verified. Anything tagged S or R must be re-read before it drives a decision.
Machine facts (L): Mac mini M1, 16 GB (`hw.memsize`), one resident generative model.

---

## 0. Ten-line answer

1. The LoRA did not fail at learning; it learned a distribution the bench does not contain (section 1).
2. Training never saw an item over ~464 tokens or over 16 options. Bench has 18 of 109 decisions with 8 to 26 options, and prompts up to 5,354 characters. Those are exactly the kinds that fail (hop 3/7, narrowing 5/9, property 11/17).
3. Held-out loss fell 1.6 to 0.17, but the held-out domains come from the same authoring pipeline and the same generator, so it measures template learning. A falling val loss with a flat bench is the expected signature.
4. r3 on extract is a real regression (+0/-7, one-sided sign test p about 0.008). p1 (-2 of 109) is noise.
5. The unit is wrong more than the model: sibling roles (actor vs recipient) are indistinguishable by label; only the data separates them (see `QA-RESEARCH.md` section 4). More decision-level SFT cannot add that signal.
6. Recommended: stop SFT on gold-path decisions. Build a **schema-conditioned execution gym** (Avra generates worlds, questions and gold by running the DB) and use it three ways: as the eval, as a verifiable-reward RL environment, and as the label source for a small cross-encoder discriminator.
7. Eval: today 13 walks cannot detect less than a 40-point swing. A synthetic gym of 1,000+ paired items detects 5 points. Keep the fixtures as a sealed canary, never a tuning target.
8. Runtime: choose-ops are prefill-bound (one token out), so speculative decoding is irrelevant for them. The wins are batching tails over a shared prefix, a two-level persisted prefix cache, shorter option lists, and skipping the LLM when a fitted gate is confident.
9. Models: do not chase size (8B was worse, 4B to 8B is +3.5 on zero-shot BIRD per `QA-RESEARCH.md`). Run a bake-off on the gym between Qwen3-4B-2507 (baseline), Qwen3.5-4B, Gemma 4 E4B and Phi-4-mini; add a fine-tuned encoder discriminator.
10. Beyond SoTA: **a per-user gym built from the owner's declared schema alone.** No personal data is needed to train skills on their ontology.

---

## 1. LoRA post-mortem

### 1.1 What the files show (all L)

| Fact | Where |
|---|---|
| p1: planner-only, 8,154 examples, rank 8, 16 layers, scale 20, lr 5e-5, batch 1 x accum 8, best step 3500, held-out loss 1.60 to 0.17 | `tune/adapters/p1/best.json`, `adapter_config.json` |
| r3: all kinds, 23,443 examples, best step 2250, held-out 2.35 to 0.35 | `tune/adapters/r3/best.json` |
| Bench result p1: 85/109 vs base 87/109 decisions, 4/13 walks both | `planner/bench/results/bench-20261025T162947.json` vs `...20261022T141526.json` |
| r3 on benches: planner 74 to 73 (+4 -5); extract 47 to 40 (+0 -7); er 12 to 10 (+0 -2). Gold probability on `kind` fell 0.995 to 0.522; on extract 0.892 to 0.652 | `tune/results/eval-r3-20261022T012702.json` |
| Train option counts: 2 options = 11,510 of 23,443 (49%); max 16; only 58 items have 14 options and 8 have 16 | `tune/data/train.jsonl` |
| Bench option counts: 2: 53, 3: 11, 4: 16, 5: 3, 7: 3, 8: 6, 9: 4, 10: 11, 25: 1, 26: 1 | `planner/bench/decisions.jsonl` |
| Train prompt length: p50 386 chars, p99 993, max 1,933. Bench context plus options: up to 5,354 chars | computed from both files |
| Bench accuracy by kind (base): speaker gate 11/13, arrival 13/15, mode 13/13, property 11/17, property more 16/19, anchor 6/6, hop 3/7, narrowing 5/9, recorded 8/9 | `bench-20261022T141526.json` |
| Train has only 406 `hop` and 174 `narrowing` examples, the two weakest kinds | `tune/data/train.jsonl` |
| Latency: median 1.56 s per decision (both orders), 1.2 s for 2 options, 13.5 to 14.3 s for the 25/26-option ones | `bench-20261022T141526.json` |
| 26 of 23,443 prompts are duplicates; negligible | computed |

### 1.2 Diagnosis, ranked by how much evidence supports it

**A. Support mismatch (strongest).** The bench's failures are long-list, real-schema decisions (about 70 models, option lists of 8 to 26 relation or property names). Training is short, 2-option, invented-domain items; `max_seq_length` was set to the longest training example (464). A LoRA cannot learn a regime it never sees. The bench kinds with zero change (mode 13/13, anchor 6/6) are the ones that were already solved; the kinds that moved are the ones nearest the training distribution, in both directions. Position/list-length effects are known to matter most for the smallest models (S: "Ordering or Pruning?", NeurIPS 2026, 0.5B to 7B, catalogs of 8 to 128, [neurips.cc](https://neurips.cc/virtual/2026/171201); V for the abstract).

**B. The held-out set is not independent of the generator.** The 4 validation domains were authored by the same pipeline under the same SPEC (15 to 25 messages, 4 to 7 models, same confusable-reference template, same question dialect) and converted by the same `convert.py`. The loss measures how well the adapter learned that generator's regularities. It dropped 9x on val and not at all on the bench. This is "SFT memorizes, RL generalizes" (V abstract, [arXiv 2501.17161](https://arxiv.org/abs/2501.17161), ICML 2025) in miniature, and the LoRA literature agrees LoRA regularizes but cannot invent a regime ([Biderman et al., arXiv 2405.09673](https://arxiv.org/html/2405.09673v2), S). Not a leak: names are refused by `corpus.py`, the split is by domain, and I found no fixture text in the data. But the validation set is the wrong instrument for early stopping.

**C. Wrong supervision signal for the actual failure.** Labels come from a recording oracle on the gold walk, one hard letter per state, only on states the gold path visits. The failures we care about are sibling ambiguities (actor / recipient / requested_by) where the label text carries no discriminating information; the data does. Decision-level SFT on label text pushes the model to memorize naming habits of 40 invented domains. Plan-level, execution-grounded supervision gives the missing signal (section 3, rec 1). Also: the model never sees its own mistakes, so no recovery behaviour is learned (exposure bias). With p about 0.8 per step over about 8 steps, walks fail at the rate observed (`QA-RESEARCH.md` section 4).

**D. Overconfidence under shift, the visible symptom.** On r3 the adapter lowered gold probability on items the base got right (kind 0.995 to 0.522; extract 0.892 to 0.652). Hard-label cross-entropy on a single letter token, on a base that is already RL-tuned for multiple choice (Qwen3-4B-Instruct-2507), sharpens in-distribution and miscalibrates out of it. S: standard LoRA is overconfident under severe shift ([arXiv 2506.14280](https://arxiv.org/pdf/2506.14280)); fine-tuning an already-instruction-tuned model can miscalibrate it through prior knowledge ([arXiv 2505.20903](https://arxiv.org/pdf/2505.20903)). Letter-prior is a smaller factor (gold is A in 41% of train vs 48% of bench; both orders are averaged at inference).

**E. Statistics (we over-read noise in one direction and under-read it in the other).**
- p1: 85 vs 87 of 109 is two decisions; the 95% interval on the paired difference spans roughly +/-6 points. No conclusion either way.
- r3 extract: 7 losses and 0 gains. Exact sign test two-sided p = 2 x 0.5^7 = 0.0156. That one is a real regression.
- Walk accuracy 4/13 has a Wilson 95% interval of about 12 to 61% (`QA-RESEARCH.md`).

**F. Minor.** Rank 8 / 16 layers / lr 5e-5 and 4-bit base are plausible limiters but not the root cause; the LoRA learned enough to drop val loss 9x. One epoch, about 3.5k to 8k steps at batch 8, hand-picked checkpoint by a proxy loss.

### 1.3 What would have to be true for a LoRA to help

It would need (1) items drawn from the deployment distribution (real-size schemas, 8 to 26 options, long contexts), (2) hard negatives that differ only in a value-grounded way, (3) a validation set drawn from a different generator than the training set, and (4) a promote rule on a powered paired test. None of these held. The LoRA is not refuted; the experiment was under-specified.

---

## 2. What training works for small models on structured, verifiable tasks

Honest summary: the strongest small-model results all use **execution or verifier signal**, usually RL, on top of a short SFT warm start. Few are reproducible at 4B on a 16 GB Mac.

| Approach | Evidence | Fit here |
|---|---|---|
| **RLVR / GRPO with execution reward** | Arctic-Text2SQL-R1: a 7B model, reward "based solely on execution correctness", top of BIRD (V abstract, [arXiv 2505.20315](https://arxiv.org/abs/2505.20315)). SLM-SQL: 0.5B to 1.5B models, SFT then RL post-training, BIRD dev +31.4 average, 56.87 (0.5B) and 67.08 (1.5B) EX (V abstract, [arXiv 2507.22478](https://arxiv.org/abs/2507.22478)). KBQA-R1: GRPO with execution feedback on WebQSP/GrailQA/GraphQuestions, claims SOTA, no numbers in abstract (V abstract, [arXiv 2512.10999](https://arxiv.org/abs/2512.10999)). | Best match in kind. Needs the engine as verifier (we have it). |
| **Caveat on RLVR at small scale** | A documented single-author negative result: Qwen2.5-Coder-1.5B, outcome-only execution GRPO, about 0 gain on BIRD/Spider (S, [HF model card](https://huggingface.co/Anurich/slmsql-grpo-v2)). Cause: groups all-correct or all-wrong give no gradient. | Use difficulty-matched tasks (gym controls difficulty) and partial-credit rewards (consume-every-mention, right-type, right-count). |
| **SFT first, then RL** | "SFT stabilizes the output format, enabling subsequent RL" and RL generalizes to rule variants where SFT memorizes (V abstract, [arXiv 2501.17161](https://arxiv.org/abs/2501.17161)). | Our output is one letter or a short plan: the format is trivial, so a very short SFT only. |
| **DPO on execution outcomes** | ExCoT (S): DPO with execution accuracy as the only preference signal lifted LLaMA-3 70B BIRD 57.37 to 68.51, Spider 78.81 to 86.59, but only with CoT; direct-answer DPO gave marginal gain. A second study found DPO degraded 6 of 10 models (S, [arXiv 2502.11656](https://web3.arxiv.org/pdf/2502.11656)). | Weak. Our answer is one token, so there is little variation in pairs. Only worth it on plan generation, not on letters. |
| **On-policy distillation** | Student samples, teacher scores per-token reverse KL. Qwen3-8B-Base student: AIME'24 60% (off-policy SFT) to 70% in about 150 steps; Qwen3 report lists 17,920 GPU-hours RL vs 1,800 for on-policy distillation, about 10x cheaper; recovered chat ability after domain mid-training (83% vs 45% IF-eval) (V, [thinkingmachines.ai](https://thinkingmachines.ai/blog/on-policy-distillation/)). A follow-up found the KL direction matters more than on-policy-ness (S). | Strong fit **offline**: a large teacher (not resident, not at runtime) scores the 4B's own sampled choices on the gym. Needs a teacher that fits the Mac or a one-off run on a rented box with only synthetic text. Owner rule "fully local" applies to runtime; training on invented data elsewhere is allowed, but confirm. |
| **Synthetic data from templates** | SyntheT2C: template-only synthetic Cypher SFT lowered quality vs no SFT (S, [arXiv 2406.10710](https://arxiv.org/html/2406.10710v1)). Consistent with our two failed LoRAs. | Avoid templated text; render with a teacher LLM, verify by execution. |
| **Procedural verifiable environments** | Reasoning Gym: unlimited instances, difficulty knobs, automatic verification. SynLogic: 35 task types, 7B and 32B RL, +6 over R1-Distill-32B on BBEH (S, [arXiv 2505.19641](https://arxiv.org/pdf/2505.19641)). RESYN generates instances and verifiers autonomously (S, [arXiv 2602.20117](https://www.alphaxiv.org/overview/2602.20117)). | The template to follow, with our DB as the verifier. |
| **Rejection sampling / best-of-N with a verifier** | OmniSQL-7B: 63.9 single sample, 68.9 with best-of-32 reward-model pick (`QA-RESEARCH.md`, secondary). | Cheap at inference only if plans are executed (they are). |
| **LoRA vs full fine-tune** | LoRA learns less and forgets less; similar learning-forgetting curve (S, [arXiv 2405.09673](https://arxiv.org/html/2405.09673v2)). | Keep LoRA; this memory budget rules out full tuning. |

**Feasibility on a 16 GB M1.** `mlx-lm-lora` implements SFT, DPO, GRPO and PPO on MLX (S, [repo listing](https://www.sourcepulse.org/projects/23866295)). I found no GRPO memory figures for a 4B 4-bit model. GRPO needs rollouts plus a reference policy (LoRA lets the base act as reference by disabling the adapter), so a 4B 4-bit run is plausible but unmeasured; the existing 5 GB MLX memory cap in `params.json` is likely too small for rollouts of 16 samples. Run RL on a rented Linux GPU box (TRL/verl) with synthetic text only, ship back an adapter, and evaluate locally. R.

---

## 3. Ranked recommendations

Gain figures are estimates; I cannot promise numbers. Where I have none I say so.

### R1. Build the schema-conditioned execution gym (do first; it unlocks R2, R3, R5)

- **What:** An Avra-side generator that samples a *schema* (model graph with sibling references, enums, optional fields with absence codes, relation labels with near-synonyms, size 5 to 80 models), populates a *world* (entities, records, validity), emits a *question* as a plan AST from the engine's own dialect, and computes the **gold answer by executing the plan**. Text rendering of the world is the only LLM step (offline, teacher, verified by checking every planted fact appears; copy the "fidelity verifier" idea from Ground Truth First, V, [alphaxiv 2607.21962](https://www.alphaxiv.org/abs/2607.21962.md)).
- **Why it fixes the failure:** schema size and option counts match deployment; sibling ambiguity is *constructed* (same person in actor in one record and recipient in another) so only value grounding resolves it; difficulty is a knob; every label is checkable; the held-out set can come from a different schema sampler than training.
- **Evidence:** Ground Truth First's "ground truth first, text second, questions mechanically from the script" avoids the label-error problem that LongMemEval and LoCoMo have (V). Reasoning Gym/SynLogic show the pattern at scale (S).
- **Expected gain:** none directly; it is the instrument. It makes every other change measurable.
- **Cost:** 1 to 2 weeks. The engine already executes plans; schema/world sampling and the renderer are new.
- **Risk:** the renderer's text is too clean ("tidier than real users" is the stated limitation of Ground Truth First, V). Mitigate with a noisy-render pass (typos, chat turns, signatures) and keep the fixtures as an unoptimized canary.

### R2. Whole-plan selection by execution, with an RL-trained discriminator (the planner)

- **What:** Per `QA-RESEARCH.md` rec A: link mentions, enumerate every schema-valid plan to depth k, execute, drop empty/ill-typed, require each linked mention to be consumed, then ask one model one question over 3 to 10 plan descriptions with 2 to 3 real result values shown. Train that discriminator on the gym.
- **Training:** short SFT (format) then GRPO or best-of-N rejection sampling with reward = executed result equals gold, plus partial credit for mention coverage and type. Prefer RL over SFT for generalization (V, SFT-memorizes paper).
- **Evidence:** Pangu-style discrimination is SOTA-class at BERT-base scale (`QA-RESEARCH.md`, from the paper); Arctic and SLM-SQL show execution reward working at 0.5B to 7B (V abstracts).
- **Expected gain:** walks stop compounding; ceiling is oracle@k of the candidate set. First measure oracle@k and "mention coverage uniquely selects gold" on the 13 walks, no LM (a one-day experiment).
- **Cost:** enumerator plus gym (R1) plus a few GPU-hours of RL. Latency: one forward pass over the shortlist.
- **Risk:** candidate explosion; questions with no entity (aggregates); the GRPO all-correct/all-wrong problem (S) if the gym is too easy.

### R3. Distill the high-volume closed choices into a small cross-encoder (the extraction cascade)

- **What:** For the kinds the cascade asks thousands of times (antecedent, speaker, reference, stated, polarity, modality, relation), fine-tune a ModernBERT-base/large or DeBERTa-v3 cross-encoder on (context, option) pairs, labels from the gym. Keep the 4B for the residue; route by a fitted confidence gate (fitted on gym validation, with provenance in `params.json`).
- **Evidence:** cross-encoders distilled from LLM rankers match the LLM while up to 173x faster and 24x lighter (S, Rank-DistiLLM, [arXiv 2405.07920](https://arxiv.org/pdf/2405.07920)); Fin.ai trained a ModernBERT-large reranker on LLM-generated labels because LLM rerankers had latency issues (S, [fin.ai](https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin/)). I found no head-to-head against a closed-set LLM choice (S gap), so this is an extrapolation until measured. GLiNER2-level encoders are near parity on NER but not on relations (`SOTA.md`), which is why this targets *choice*, not span finding.
- **Expected gain:** extraction time down by the share of choices the gate resolves; plausible 3 to 10x on the choice portion (R, unmeasured). Accuracy: unknown; the 4B stays as fallback.
- **Cost:** 1 week after R1. Encoder batches on MPS or CPU, about tens of ms per item (R).
- **Risk:** encoder context limits (ModernBERT 8k, fine); loses the zero-shot flexibility of the LLM on unseen schemas, mitigated by gym diversity and the LLM fallback.

### R4. Fix the eval before any further training (parallel with R1)

See section 4. A promote rule on a powered paired test; fixtures sealed; gym validation from a different sampler than training.

### R5. Per-user skill training from the declared schema (beyond SoTA; section 6)

### R6. Runtime: shorten the long lists and batch the tails (section 5)

The 25- and 26-option decisions cost 13 to 14 s each and sit in the weak kinds. Hierarchical "heats" (the code already speaks of splitting into heats, `cascade.py` MAX_OPTIONS) with a shortlist order that is stable (to keep the prefix cache) is the cheap fix. "Ordering or Pruning?" says ordering helps 0.5B models and not 7B, and re-sorting breaks prefix caching (V abstract), so prune by *recall-safe* retrieval and keep a deterministic order.

### R7. Model bake-off on the gym, not on 13 walks

| Candidate | Why | Note |
|---|---|---|
| Qwen3-4B-Instruct-2507 4-bit | current baseline | pinned in `extract/pins.py` |
| Qwen3.5-4B (and 9B only as a teacher) | released 2026-03-02, 0.8B/2B/4B/9B dense, Apache 2.0 (S, [NYU summary](https://rits.shanghai.nyu.edu/ai/qwen-3-5-small-models-9b-parameters-that-beat-120b)) | Hybrid Gated-DeltaNet layers: recurrent state cannot be trimmed back to an earlier prefix like a KV cache, and vLLM reports about 0% prefix hits for the family (S, [LMCache docs](https://docs.lmcache.ai/recipes/qwen3_5.html)). Our `trim_prompt_cache` pattern may not work; copy/snapshot the state instead. |
| Gemma 4 E4B | released 2026-03-31, small tiers E2B/E4B (S, [codersera](https://codersera.com/blog/gemma-4-vs-qwen-3-5-comparison-2026/amp/)) | MLX support not confirmed in my sources. |
| Phi-4-mini, SmolLM3-3B, Llama 3.x 3B | R | SmolLM3-3B BFCL 92.3 is vendor-claimed (`QA-RESEARCH.md`). |
| Encoders: ModernBERT, DeBERTa-v3, GLiNER2 | R3 | |
| Seq2seq T5-class | R | Pangu used T5-3B at 81.7 F1 GrailQA (`QA-RESEARCH.md`, secondary). Only if plan *generation* is needed. |

Prior from the table above: more size does not help here (8B scored 73/109, L; 4B to 8B is +3.5 zero-shot BIRD per `QA-RESEARCH.md`, S). Expect the discriminator design, not the backbone, to dominate. Pick on the gym with a paired test; do not pick on the fixtures.

### R8. Not recommended

- A third decision-level LoRA on the same data (diagnosis A to C).
- DPO on single-letter outputs (no variation in pairs; S evidence it can degrade).
- 8B as scorer (worse, and it contributed to the memory crash).
- Beam over unverified candidates (`QA-RESEARCH.md`: no gain; likelihood ranking inherits the LM's error).
- Template-only synthetic text (SyntheT2C, S).

---

## 4. Evaluation, honestly and without personal data

### 4.1 What the current eval can and cannot resolve

- 109 decisions are clustered in 13 walks, so the effective n for walk accuracy is 13. Wilson 95% for 4/13 is about 12 to 61% (L).
- Paired sample size for a given gain (McNemar, alpha 0.05, power 0.8, discordant rate d): n = (1.96 sqrt(d) + 0.84 sqrt(d - delta^2))^2 / delta^2. My arithmetic:
  - delta = 10 points, d = 0.20: about 150 paired items.
  - delta = 5 points, d = 0.15: about 470 paired items.
  - On 13 walks no realistic gain is detectable. Paired tests need roughly 2x fewer items than unpaired sizing (V: median 2.15x fewer across 40 model pairs, [arXiv 2605.30315](https://arxiv.org/abs/2605.30315)).
- The same preprint reports that many public leaderboard comparisons are unresolved at 80% power, and that clustering makes it worse (V). Our decisions-in-walks structure is that clustering.

### 4.2 Proposed protocol

1. **Tier G (gym, thousands of items).** Execution-verified, from R1. Stratify by schema size, option count, hop depth, sibling-ambiguity yes/no, answer type (lookup, count, aggregate, temporal, abstain). Cluster by *world* in the bootstrap.
2. **Tier F (fixtures, 13 walks / 36 QA).** Sealed canary. Report, never tune on. Gate: non-inferiority, not superiority.
3. **Tier L (adapted LongMemEval-S and an EverMemBench-style slice).** Pinned local reader and local judge, per-category numbers only (`SOTA.md` section 0). Useful to catch regressions in memory behaviour, not to rank our planner.
4. **Statistics.** Per-item paired outcomes; exact McNemar with mid-p (S: mid-p and continuity-corrected variants are standard for small discordant counts, [arXiv 2605.30315](https://arxiv.org/abs/2605.30315)) plus a cluster-paired bootstrap (BCa had near-nominal coverage at small n; percentile bootstrap undercovered, S, [arXiv 2603.28769](https://arxiv.org/pdf/2603.28769)). Report discordant counts (b, c) not only accuracy. Pre-register the promote rule: lower bound of the paired CI on tier G above 0 and above a non-inferiority margin on tier F.
5. **Decompose by stage.** Oracle-linking, oracle-retrieval, oracle-plan runs, so failures are attributed (`RESEARCH.md`, `QA-RESEARCH.md` agree). Always report oracle@k for the candidate set.
6. **Abstention as a first-class metric.** Risk-coverage curve and wrong-answer rate at a fixed coverage. A system that is "most accurate was also the most confident when wrong; about 94% of its errors were confident wrong specifics" (V, Ground Truth First). Calibration per decision kind must be fitted on gym validation, never trusted raw (`SOTA.md`).
7. **Sampler independence.** The gym's validation worlds come from a different sampler seed family and a different renderer prompt than training. This is the fix for diagnosis B.
8. **Contamination.** Fixture names and text are refused by the gym generator (as `corpus.py` does today), and a periodic `grep` of training text against fixtures is a CI check.

---

## 5. Local runtime on Apple Silicon

### 5.1 What the numbers say about our workload (L)

- A choose-op returns **one token** (a letter) after a prefill. Median 1.2 s for 2-option decisions in both orders, so about 0.6 s per forward over a roughly 500-token prompt, which implies prefill on the order of 800 tokens/s for a 4-bit 4B on M1 (my arithmetic, not a measurement). The 26-option case takes 14 s.
- Cold extraction: 24 minutes for 30 sources, about 48 s per source. I have not seen a per-stage breakdown; the first step is to instrument calls and time per kind.

### 5.2 Ranked runtime moves

| # | Move | Evidence | Expected effect | Risk |
|---|---|---|---|---|
| 1 | **Profile first:** count choose calls and ms per kind per source; split encoder, prefill, scoring, glue. | L: no breakdown exists. | Tells which of 2 to 5 pays. | None. |
| 2 | **Gate the LLM:** skip a choice when a fitted score (encoder margin, deterministic rule, or distilled cross-encoder, R3) is confident. Gate fitted on gym, provenance in `params.json`. | cascade already does this for time and dates (`git log`: "an outright date needs no choice"). | Largest single lever: choices dominate. | Calibration drift; refit per schema family. |
| 3 | **Batch tails over a shared prefix:** one forward with B tails sharing the source KV prefix, instead of B serial calls. mlx-lm has a BatchGenerator; servers built on it report 1.5x to 3.4x throughput at 5 concurrent requests (S, [vllm-mlx](https://vllm-mlx.is-a.dev/guides/continuous-batching/)). Memory-bandwidth-bound decode benefits more than prefill, so expect less for our prefill-bound ops. | S | 1.3 to 2x on scoring (R). | Padding waste; implement and measure. |
| 4 | **Two-level prefix cache**: schema/instruction header first (persist to disk per schema hash), then source text, then decision tail. Today only the source is a prefix (`cascade.py` `begin`). | Prefix reuse gives large TTFT cuts: 5.8x on shared prefixes in one paper, 40k tokens 200 s cold vs 5 s warm (S, [arXiv 2601.19139](https://www.arxiv.org/pdf/2601.19139) and a blog). | Removes re-prefill of the shared header per source. | Qwen3.5 hybrid state cannot be trimmed (S). Keep Qwen3 dense for the trim pattern or snapshot. |
| 5 | **Single-order scoring plus a fitted letter-prior correction** instead of two orders per decision. PriDe shows selection bias is mostly an option-ID prior estimable from 2% to 20% of items and removed without labels (V abstract, [arXiv 2309.03882](https://arxiv.org/pdf/2309.03882)). | S | Halves choose cost. | Must be validated on the gym; our own bench averages both orders today. |
| 6 | **Cap and structure option lists** (heats with a stable order). | V abstract (Ordering or Pruning). | Removes the 13 to 14 s tail and the weakest kinds. | Needs recall-safe shortlisting. |
| 7 | **Encoder batching**: GLiNER2 on MPS with length-bucketed batches; run the encoder before the LLM loads and unload it, so only one model is hot. | R; the memory crash was 8B + 4B + encoder resident together (task brief). | Memory safety; some speed. | None. |
| 8 | **Run extraction as an offline pipeline over many sources per model load**, sorted by schema, so prefix caches stay warm. | L: batch mode exists (`extract_batch`). | Amortizes load and header prefill. | Scheduling. |

**Speculative decoding: skip for choose-ops.** There is no decode to speed up. It matters only for generative ops (record fill, query planning). Reported MLX results: DFlash-style drafters 1.7x to 4.1x (S, project-reported); EAGLE-3 on a 4-bit 8B model about 1.05x (S, [mlx-lm discussion 890](https://github.com/ml-explore/mlx-lm/discussions/890)). Not worth building until generation is on the critical path.

**MLX vs llama.cpp.** Reported decode advantage for MLX, 21% to 87% higher throughput across 0.6B to 30B on an M4 Max (S, [arXiv 2601.19139](https://www.arxiv.org/pdf/2601.19139)); a single M1 Max anecdote has MLX spending about 94% of the time in prefill on 650-token prompts and trailing llama.cpp there (S, [Towards AI article](https://pub.towardsai.net/apples-mlx-runs-local-llms-3x-faster-than-llama-cpp-until-your-context-hits-40k-715ec441afbb)). `SOTA.md` records llama.cpp prefilling about 4x faster (blog, M4/M5, no M1 data). Our workload is prefill-bound, so the question is real, but the evidence is anecdotal and not on M1. **Do a one-day in-house bake-off**: the same 109 bench prompts, same tokens, same quantization class, measure prefill ms and logits agreement, with llama.cpp prompt-cache slots vs mlx-lm cache. Switch only if prefill wins by more than 2x, because a switch costs the adapter and calibration tooling.

**Quantization.** 4-bit usually costs 1 to 4 points on average, with uneven tails: 0.5B intent detection 99% at 8-bit to 81.7% at 4-bit; 1.5B 96.5% to 90.7% (S, [arXiv 2502.12923](https://arxiv.org/pdf/2502.12923) and [arXiv 2508.16785](https://arxiv.org/pdf/2508.16785)). I found no study of calibration of letter-logits under quantization (S gap). Cheap test: score the gym with the 4-bit and the 8-bit 4B and compare accuracy *and* fitted-calibration error. 8-bit 4B is about 4.5 GB, affordable with one resident model.

---

## 6. Beyond SoTA: a compiler-verified, schema-conditioned gym, per user

**Claim.** Every published small-model recipe that works (Arctic, SLM-SQL, KBQA-R1, SynLogic, Reasoning Gym) needs a verifier, and those verifiers are external (a SQL engine, a puzzle checker). In Avra the *language implementation is the verifier and the schema is a first-class declared object*. That gives three things nobody else in this literature has together:

1. **Unlimited labelled tasks, free of annotators.** The DB executes every plan, so gold is a computation. This removes the LoCoMo-style answer-key error rate (6.4% wrong keys, L: `SOTA.md` section 0) and the 5% yield of LongMemEval's human filtering (S).
2. **The training distribution equals the deployment distribution at the schema level.** Every user's ontology differs. Instead of one generic model tuned on 44 hand-authored domains, sample worlds *from the owner's declared models* (names, relations, enums, absence codes) with synthetic entities and rendered text. The owner's data never enters; the skill is trained on their *ontology*. This satisfies "fine-tune skills, not data" and the nothing-hardcoded rule: the only inputs are declarations.
3. **Adversarial curriculum by construction.** The generator can mint exactly the cases the model fails: sibling references populated so that only a value separates them, same-name entities, validity intervals, negations, abstain cases. Difficulty is tracked per kind; RL batches are chosen where the current policy's pass rate is between 20% and 80% (the fix for the GRPO all-correct/all-wrong failure, S).

**Pipeline sketch.**
`declared schema -> world sampler (seeded) -> plan sampler (engine AST) -> execute (gold) -> teacher renders text, fidelity-verified -> student plays (select / generate plan) -> reward = executed result == gold, plus coverage terms -> GRPO or rejection-sampled SFT -> adapter keyed by schema hash`.
Idle-time job on the owner's machine (rank-8 adapter; the existing 5 GB MLX cap suggests SFT/rejection sampling fits, GRPO may need the heavier box, R) or shipped as a base adapter plus a short per-schema top-up. Each adapter is promoted only if the paired gym test and the fixture non-inferiority gate both pass (section 4).

**Why this is beyond SoTA rather than reproduction.** Prior work trains one model per benchmark with a fixed verifier. Here the verifier is generated from the same declaration that defines the data, so the environment is regenerated per user and per schema revision with no human labelling, and the *eval* is the same artifact as the *training environment*, with train/test separated by sampler seed family. Ground Truth First (V, single-author preprint) shows the benchmark half; nobody connects it to a per-schema RL loop. Risk: the renderer's clean text, covered in R1; and teacher dependency for rendering, which can be a one-off offline run since text, not decisions, is what it produces.

---

## 7. What to keep

- The closed-choice, schema-constrained, span-anchored admission design. It is the Pangu bet and it holds up (`QA-RESEARCH.md` section 4).
- Order-averaged letter scoring as a baseline, pending the PriDe-style comparison.
- Qwen3-4B-Instruct-2507 4-bit as the single resident generative model; GLiNER2-large as span proposer.
- The recording oracle idea: prompts come from the real code so bytes match production. Keep it; change *what* states it records (off-path, hard negatives, real-size schemas).
- `tune/` plumbing: memory caps, metrics, early-stop machinery, `params.json` with provenance, domain refusal of fixture names.
- Both LoRAs as negative results, recorded with the diagnosis above (add to `ROADMAP.md`).
- The `QA-RESEARCH.md` plan A (execution-grounded whole-plan selection). This document says how to train and evaluate it.

## 8. Open questions I could not close

- Per-stage time of the 24-minute extraction (no profile exists).
- Whether `trim_prompt_cache`-style reuse works for Qwen3.5/Gemma 4 on MLX (S: hybrid state cannot be trimmed).
- GRPO memory on a 4B 4-bit model under MLX (no figure found).
- Whether a ModernBERT/DeBERTa cross-encoder matches the 4B on our choice kinds (no head-to-head found; S gap).
- Calibration of letter-logits under 4-bit vs 8-bit (no study found).
- Exact numbers inside several S sources (Arctic, KBQA-R1 abstracts carry no tables); open the papers before quoting.
