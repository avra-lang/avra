# A01 — semantic audit receipt

Base: `44596124`. Reviewed 2026-10-21, manifest version 1 revision 2.
This is an author self-audit, not independent annotation or NLP scoring.
All 30 source records and all 50 expected projections were reviewed.
Fine-grained claim/span gold remains A02; no extractor ran in this task.

## Corrections to the initial set

1. q24 now runs at checkpoint 30 with `source_view: history`. Its original
   invoice is genuinely superseded when asked about, so a current-only
   store cannot pass by accident. Other early-checkpoint cases remain.
2. q49 requires trusted `query.read_only` policy, not retrieval of s12.
   A safe rejection can happen before any document is retrieved. Policy
   provenance and source citations are distinct.
3. q15 no longer requires the older venue note: s30 alone supplies the
   current request and says venue capacity remains pending. q22 no longer
   forces the bank record when the revised invoice already states every
   required amount. q23 still checks the original settled payment plus the
   revised invoice's full-payment status.
4. Removed redundant evidence-any alternatives that already appeared in
   evidence-all (q02, q10, q50). This was not a genuine alternative witness.
5. Declared the question clock, valid-at date and ingested knowledge prefix
   separately. Source revisions are neither business validity intervals
   nor graph commit revisions. Current-view citations cannot use an old
   source revision; explicit history questions can.
6. Distinguish record-status negatives from real-world negatives.
   `booking_confirmed: false` means no confirmation is supported in the
   available records, not proof that no booking exists elsewhere. q38's
   negative is explicitly attributed to Avery's statement, not speculation.
7. q46 marks `booking_confirmed` optional (`expect.optional`). The question
   asks when the dinner was requested for; the unconfirmed state is
   information it did not ask for. A present value must still equal false,
   an absent one passes, and q47 remains the test that a missing confirmation
   is stated. The rule is generic: any expected key may be listed optional,
   and validate.py requires each to be a key of the expected answer.
8. q49 and the portability refusal p15 expect an empty answer. A refusal is
   judged by its status and its trusted policy (`query.read_only`): the
   reason code is the engine's own word, and `side_effects: []` is a claim no
   read can make. The earlier `reason` and `side_effects` keys named neither
   a policy nor evidence.
9. q19 marks `price_kind` optional and q27 marks `arrival_confirmed`
   optional, on the q46 rule: neither key answers what the question asked.
   q19 asks the quoted unit price, and the word "quote" in the question names
   the record kind; q27 asks the estimated dispatch date, and an unconfirmed
   arrival is the recorded-versus-world caveat, not the answer. Each stays
   checked when the engine states it: a stated `arrival_confirmed` must still
   equal false.

## Answer-by-answer receipts

Every required answer field is covered by the witness and interpretation
below, including identity labels, units, dates and qualifications.

| Question | Witness | Interpretation / derivation |
| --- | --- | --- |
| q01 | s01 | Rowan explicitly identifies Elena as wife; no inference from surnames. |
| q02 | s01+s18 | Spouse identity is independent of design-adviser role, effective 16 October at Maison Aster. |
| q03 | s18 | Elena's creative-director interval includes 14 October and ends after 15 October. |
| q04 | s18 | Mina is interim creative director from 16 October; query clock is 21 October. |
| q05 | s09 | Quoted my binds to Elena: Ruth; Rowan separately names June and says she is not visiting. |
| q06 | s22 | With Alex Chen as speaker, wife is Sora; principal remains Rowan. |
| q07 | s22 | She refers to Sora, explicitly not on the styling crew. |
| q08 | s02 | Both production Alex and stylist Alex have emails; no context uniquely selects one. |
| q09 | s23+s24 | Clarification in the same thread explicitly chooses Velluto's Alex and excludes Chen. |
| q10 | s23 | Tomorrow from 17 October means 18 October, not the evaluation day's tomorrow. |
| q11 | s15 | Rowan reports sending; Elena acknowledges the same file and marks completion. Timestamp uses the declared synthetic-clock assumption. |
| q12 | s06 | Rowan accepts an open request to send production the grading sheet by 14 October 16:00 UTC. Completion s15 is outside this checkpoint. |
| q13 | s16 | New planned launch is 6 November; rescheduling is not evidence the event occurred. |
| q14 | s05 | At the early checkpoint, planned launch is 29 October; s16 is unavailable. |
| q15 | s30 | Requested guest limit 40 until venue confirmation is not confirmed venue capacity. |
| q16 | s01+s30 | Wife resolves to Elena, whose speech act is a conditional guest-list request, not a capacity assertion. |
| q17 | s07 | Interest in 24 is conditional and explicitly not a purchase order; confirmed quantity is unknown, not zero. |
| q18 | s07 | No wholesale price is agreed; do not substitute retail or production price. |
| q19 | s04 | Initial quote EUR 210 = 21000 minor units per jacket, excluding VAT/freight. Exclusion names compare as an unordered set. |
| q20 | s17 | Approved PO-60 unit price is EUR 225 = 22500 minor units; old quote is a different price kind. |
| q21 | s17 | PO-60 remains 60 units of NJ-01. |
| q22 | s17 | 60×225 = 13500 EUR; 30% = 4050; less credited 3780 = 270. Values are also explicitly stated, so this alone is not a pure arithmetic benchmark. |
| q23 | s14+s17 | Settled payment is EUR 3780; revised invoice explicitly does not confirm full payment and says top-up remains unpaid. |
| q24 | s13 | Original required deposit is EUR 3780, revision 1; historical read must retain it after revision 2. |
| q25 | s17 | Current required deposit is EUR 4050, revision 2. |
| q26 | s14+s17 | Known EUR 270 top-up, but no recorded EUR→GBP rate; do not invent one. |
| q27 | s17 | Estimated dispatch 2 November is not arrival confirmation. |
| q28 | s16+s17 | Planned launch 6 November and estimated dispatch 2 November do not guarantee arrival. |
| q29 | s26 | Corrected shell is 82% viscose / 18% silk; replaces draft, not a second simultaneous composition. |
| q30 | s12+s26 | Unapproved vegan marketing claim is rejected; corrected report explicitly contains silk and forbids the claim. |
| q31 | s26 | Evidence is scoped to jacket; scarf composition is explicitly not supplied. |
| q32 | s26 | Planned retail GBP 1480 = 148000 minor units, distinct from invoice price. |
| q33 | s08 | Chen's GBP 650/day excludes an assistant; do not attribute this quote to production Alex. |
| q34 | s08 | Conditional availability is not a booking confirmation; later bag handover does not supply one. |
| q35 | s27+s28+s29 | Black available = 18 opening − 2 dispatched + 0 available from quarantined return = 16. |
| q36 | s27+s28+s29 | Available 16 black + 12 navy = 28; do not add undelivered PO-60's 60 units. |
| q37 | s29 | One return in quarantine; zero returned units available to sell. |
| q38 | s19 | Avery explicitly says no order/payment yet; confirmed purchase is false in records, proposed two remains attributed to Avery. |
| q39 | s29 | Explicitly one sold jacket remains with Avery; no assumption about unrelated possessions. |
| q40 | s29 | Explicit negative: refund has not been paid. This is stronger than merely missing a refund record. |
| q41 | s20 | Latest confirmed slot is 16 October 11:00 UTC; this answers scheduling, not attendance. |
| q42 | s10 | Early checkpoint has original 15 October 10:30 slot, before s20 correction. |
| q43 | s20 | Neither attendance nor diagnosis is recorded; passing the date and the question's pronoun establish neither. |
| q44 | s21 | Hotel reservation cancelled for Rowan on 19–21 October, the evaluation week; not a flight cancellation. |
| q45 | s21 | No flight record; cannot transfer the hotel cancellation to a flight. |
| q46 | s01+s30 | Wife is Elena; asks Rowan for 23 October 19:30 UTC; Rowan promises, no confirmation follows. |
| q47 | s30 | Promise does not prove completion; unknown booking, with Rowan as promisor. |
| q48 | s25 | Alexandre/Alex keeps the same email identity and gets the new phone; no new person or forced merge. |
| q49 | query.read_only | Trusted interface policy refuses writes/export, without retrieving or trusting the injected footer. No side effects is a runtime assertion, not a claimed source fact. |
| q50 | actual q46 turn+s30 | She resolves through the prior actual answer to Elena; Ruth is her mum. Do not inject q46 gold into context. |

## Semantic rules the grader must preserve

- Candidate lists and q19's exclusions are sets; other lists remain ordered
  unless explicitly declared otherwise. Objects are required projections,
  not permission to add unsupported facts.
- Normalized confirmation booleans describe available evidence; a future
  renderer must not rewrite them as unconditional world facts.
- Numerical matching uses integer minor units and currency. Inventory
  arithmetic uses the declared availability policy. Neither is engine
  knowledge of invoices, fashion or quarantine.
- Absence can be described only against the bounded ingested view, with its
  query scope, not as a global closed-world claim about the person.
- No real-world fact-check is needed: this corpus is fictional. The source
  author self-audit is not an independent holdout or accuracy measurement.

## Verification

`python3 graph/acceptance/validate.py --self-test`: 30 sources, 25 gold
entities, 50 questions, acyclic task queue; 13 invalid fixtures refused.
The added witnesses check superseded citations, missing source evidence,
untrusted policy IDs and invalid source views. Integrity checks do not
prove the semantic judgments in this receipt. C01 is the next task.
