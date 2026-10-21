# Personal/business acceptance set

**30 synthetic inputs, 50 questions, structured expected answers.** This
tests the intended product, not capabilities the graph already implements.

Maison Aster is a fictional luxury-fashion microbusiness. Rowan runs it;
his wife Elena also works there. The documents mix production, a wholesale
prospect, a stylist, launch planning, invoices and payments, customer
orders, stock, family, a cat's appointment and a cancelled supplier trip.
All identities, messages, amounts and relationships are invented.

## Files

| File | Purpose |
| --- | --- |
| [manifest.json](manifest.json) | Context, time, money, evidence and evaluation assumptions. |
| [sources.jsonl](sources.jsonl) | Chronological raw inputs; one JSON object per input. |
| [entities.jsonl](entities.jsonl) | Gold identity dictionary for the grader, not an engine registry. |
| [questions.jsonl](questions.jsonl) | English questions, checkpoints and normalized expected projections. |
| [tasks.jsonl](tasks.jsonl) | Small agent assignments with dependencies, owned paths and acceptance criteria. |
| [PLAN.md](PLAN.md) | Execution order, delegation brief, handoff format and verification gates. |
| [validate.py](validate.py) | Dependency-free integrity checks and negative self-tests. |

## Stories worth reading first

- **Personal relationships:** s01, s09, s22, s30. “My wife” depends on the
  speaker; Elena's mum is Ruth, Rowan's is June, and Alex Chen's wife is Sora.
- **Two Alexes:** s02, s08, s23–s25. An ambiguous reminder is clarified;
  changing a production contact's name/phone must not create a new person.
- **Business roles change:** s18 records a future-effective transition.
  Elena remains Rowan's wife after Mina becomes interim creative director.
- **Money:** s04, s13–s14, s17. Quote, invoice, deposit and payment differ.
  The revised required deposit is EUR 4,050; EUR 3,780 is paid; top-up is
  EUR 270. No GBP exchange rate exists.
- **Possible is not actual:** s07, s08, s19, s30. Wholesale interest,
  availability for a shoot, a possible purchase and a dinner promise are
  not confirmed orders, bookings, sales or completions.
- **Stock:** s27–s29. Black available-to-sell stock is 18 − 2 = 16; a
  quarantined return does not restore availability. Navy remains 12;
  total available is 28. PO-60 is separate, undelivered production stock.
- **Corrections:** s03→s26, s10→s20, s11→s21, s13→s17, s02→s25 are
  source revisions, not unrelated documents. Keep original payloads and
  provenance while excluding old interpretations from current answers.
- **Trust:** s12 contains rejected marketing claims and an injected
  “system override.” Source text cannot authorize writes or contact exports.

## Reading a question

At `checkpoint: 15`, ingest only s01..s15, in sequence. Do not preload later
sources, gold facts or the complete final graph and pretend to rewind it.
Use manifest context unless a question overrides it. A `valid_at` date
asks about when a fact held; the checkpoint says what evidence was known.
The question clock otherwise stays at `evaluation_time`. q24 explicitly
selects `source_view: history` to read the first invoice after revision 2;
current-view evidence cannot cite a superseded source revision.

`expect.answer` is the normalized **required projection**, not exact prose
or a requirement to expose these fixture IDs in production. The grader maps
real graph IDs to gold identities. Every field must be correct; objects
allow additional supported fields, candidate lists compare as sets, and
any extra contradictory or unsupported assertion is a failure. Other
ordered lists retain order unless the contract explicitly says otherwise.
q19's price-exclusion list is an unordered set, like candidate lists.
Require all `evidence_all` sources and at least one `evidence_any` source
when that list is present. Additional relevant evidence is allowed.
`policy_all` names trusted interface policies, not source text. q49 needs
`query.read_only` and may be refused before retrieving any document.

`unknown` can carry a known partial answer and a missing-evidence reason.
For example, EUR 270 is known but its GBP equivalent is not. Unknown must
not become zero, false, or a confident guess. “Scheduled appointment”
must not become “attended appointment” just because its date passed.

q50 is a multi-turn question following q46. Execute the preceding question
normally and carry its actual referents forward; never insert its gold
answer into the planner's context. Resolve quotations in the same way.

No question grants action authority: this is a read-only answer interface.
q49's requested writes/export must be refused regardless of document text.
The input sequence itself is authorized ingestion; question execution is
not allowed to mutate facts, jobs, contacts, bookings or payments.

## What is and is not supplied

Supplied now: raw data, gold entity identities, 50 expected answer projections,
source citations, a task DAG and integrity validation. Fine-grained mention
spans, complete gold claims, Avra fixture models, extraction adapters,
automatic workers, English query planning and an answer scorer are planned
tasks, not existing features. The integrity checker cannot certify that an
expected answer is semantically right or that an NLP model extracted it.
The author self-audit and its corrections are recorded in [AUDIT.md](AUDIT.md).
The entity dictionary covers identities needed by these questions; it is
not exhaustive NER gold for every organization/place mentioned in the text.

The 35 development questions and 15 reserved questions share a published
synthetic corpus. This is an engineering acceptance reservation, not a
sealed research test set or a SOTA benchmark. Before a real accuracy claim,
add new independently authored cases, realistic noisy sources and
consented/anonymized real-world material.

## Validate

From the worktree root:

```sh
python3 graph/acceptance/validate.py
python3 graph/acceptance/validate.py --self-test
```

The checks use only Python's standard library, no model weights or network.
See [PLAN.md](PLAN.md) before assigning implementation work.

## Score

```sh
python3 graph/acceptance/score.py --self-test
python3 graph/acceptance/score.py --mode e2e --extractor <cmd> --planner <cmd> [--only q01,q02]
python3 graph/acceptance/score.py --mode oracle-facts --planner <cmd>
```

Per checkpoint it builds a fresh db, ingests exactly sources 1..N (any other
selection is refused), publishes facts, then asks each question through the
planner and the graph's `query` op (plan in, C01 `Answer` out). Hooks read JSON
on stdin: the extractor takes a bare source envelope (`{schema}` in its command expands to the app's schema file) and answers a C01 extraction
result; the planner takes question, context, source view and schema and answers
a `ReadPlan`. Oracle mode reads grader-only data from `oracle/`: `facts.jsonl`
(`{source, records}`, each record anchored by source text that becomes its
locator), `plans.jsonl` (`{question, steps, output}`) and `gold.jsonl`
(source anchors that join null-identity entities to gold ids). Questions
without an oracle plan are `not-run`. A missing hook or oracle
file is `not-run`, never a pass. Columns: answer match, provenance, abstention
(status). Results land in `results/` (ignored). Exit 0 only when all pass.
