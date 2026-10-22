# Extraction recall: why e2e gets 0/36

Analysis over the cached extractions (`~/.cache/avra-graph-score`, MPS identity `7239165e`, schema `e0ec5c08`) and
`results/score-e2e-20261022T052430.json`. No model was run. Development questions only (36; held-out sealed).
Oracle = `oracle/facts.jsonl`; extracted = the 30 cached results plus their admission receipts.

## Headline

- Admission is not the loss: all 30 sources admitted every extracted record, `problems: []`, 0 refusals.
- The loss is upstream. Across 30 sources the cascade emitted 119 records: Person 55, Organization 25,
  OrganizationRole 22, Product 6, Pet 3, PersonalRelationship 3, Group 3, FibreShare 1, VeganStatus 1.
  The oracle expects 25 models; 18 of the 25 never appear at all.
- Where the text is right but the answer still fails (q01), the entity is not the gold one: no name-based merge happens.

## Top 3 causes (root facts across 35 extraction-dependent dev questions; q49 is the injection refusal, not extraction)

| # | Cause | Stage | Questions touched |
| --- | --- | --- | --- |
| 1 | State/event records never emitted (Event, PersonalTask, Commitment, Appointment, StockMovement, PurchaseOrder, Refund, TravelBooking, Trip, WholesaleProspect, Fibre, MarketingClaim) | Qwen record choice (`record_pass`/`fill`) | 20 |
| 2 | Entities never merge by name across sources or within a chat | coreference / ER | 12 |
| 3 | Money-bearing models cannot be proposed at all | Plan (descriptor) | 9 |

Next, smaller: relation validity is always `{}` (q02, q03, q04, and every time fact downstream); a negated or
role relation not emitted (q02, q04, q07); encoder label noise (4 facts).

### 1. Record pass is silent (20 questions)

Of the 18 plannable record models, 16 are needed by dev questions and none of their records appear.
Only `FibreShare` (s03, a draft label) and `VeganStatus` (s26) came out, 2 records in 30 sources.
Mechanism in `cascade.py`: `record_pass` asks the scorer, per sentence, which of 18 kinds it states and accepts only
at `p >= ACCEPT_RECORD` (0.95, `fitted: false`, "borrowed from the relation fit; no labelled record-pass decisions yet");
`fill` then needs every required field (enum pick, ref pick, text span, number) at that same threshold and drops the
whole record otherwise (`drop {model} at ..: no evidence for [...]`, `reject ..: not stated`).
Which of the gates dropped each record cannot be read: cached results carry `log: []`, and the drop lines are only in LOG.
Wrong-kind evidence (the encoder entity pass wins the span instead):

| Source | Should be | Extracted instead |
| --- | --- | --- |
| s27 "NJ-01 black 18 jackets; NJ-01 midnight navy 12" | StockMovement opening_count x2 | Product code="NJ-01 black" (resolution abstain), Product "NJ-01 midnight navy" |
| s06 "Send Alex Moreau the final NJ-01 grading sheet" | PersonalTask due 2026-10-14T16:00Z | Product code="NJ-01 grading sheet" |
| s30 "keep the Nocturne launch guest list to 40" | Event + Commitment | Organization "Nocturne" |
| s21 "F-19, Rowan Vale's Hotel Bellora reservation ... cancelled" | TravelBooking cancelled + Trip | Organization "Hotel Bellora" |
| s16, s20, s23, s29 | Event, Appointment, PersonalTask, Refund + StockMovement | Persons only; s29 "Avery" typed Organization |

### 2. Entity resolution is identity-keys only (12 questions)

All 92 entity records admitted as `resolution.kind: new` with `candidates: []`; the only merges (11) are shared
email/phone identities. Person 55 records -> 45 entities (oracle: about 12 people), Organization 25 -> 25 (about 6).
Cached extractions are requested without graph candidates, so a mention can only be linked inside its own source.

| Real entity | Entities in the graph |
| --- | --- |
| Elena | "Elena Vale" s01, "Elena Vale" s18, "Elena Vale" s02+s25 (email), plus "Elena" in s05, s06, s09, s15, s16, s22, s30 |
| Rowan | "Rowan Vale" s01+s04 (email), 3 more "Rowan Vale", 12 "Rowan" |
| Maison Aster | 6 entities (s01, s02, s13, s14, s18, s25); Velluto Works 5; Lune Store 4 |
| Alex Chen | s02+s08+s25 (email) and s22 "Alex Chen" separately |
| Fig | 3 (s01, s10, s20) |

Examples: **q01** returns "Elena Vale" (correct text) but the edge lands on s01's name-only Elena, while the gold
`person:elena` joins to the s02 email-identified entity, so `answer: false`. **q06/q07** `Alex Chen -wife-> Sora`
(s22) has a subject that is not the email-identified Alex Chen who asks. **q03** the s18 role is on an Elena entity
that holds no email, so the "creative director on 14 October" fact belongs to a different person than the one asked about.

### 3. Money cannot be planned (9 questions)

`Plan.embeddable` accepts an embedded value only if every field may be absent; `Money` requires `minor` and `currency`,
so any model with a required Money field is blocked before extraction. Blocked: Invoice, Payment, Quote, SalesOrder,
ServiceOffer, PaymentStatus, DepositTopUp, ConversionGap (log: `skip Invoice: required fields without an evidence route:
['unit_price', 'goods_total', 'required_deposit']`). Affects q19, q20, q22, q23, q25, q26, q33, q34, q39.
Source text is plain ("EUR 210 per jacket", "Required deposit 30% = EUR 3,780"), so this is a planner limitation, not an encoder miss.

### Also: relation validity (q02, q03, q04) and everything time-shaped

All 25 relation records carry `validity={}`. `emit` fills embeddable fields with `{}` and never reads the dates
("remains creative director through 15 October 2026 inclusive. From 16 October 2026, Mina Torres is interim creative
director") that s18 states, and s18 yields no Mina role and no design-adviser role. Dated record fields
(`due_on`, `event_on`, `scheduled_at_ms`) are only reachable through the silent record pass, so q10, q12, q13, q41, q46
lose time as a consequence. s25 does state both new roles (Mina interim creative director, Elena design adviser) but with empty validity.

## Class counts (all dependency facts, 35 questions)

| Class | Facts |
| --- | --- |
| missing-entity | 35 |
| wrong-entity | 12 |
| wrong-kind | 6 |
| missing-time | 5 |
| missing-relation | 4 |
| missing-property | 3 |
| present-equal | 2 |
| wrong-value | 2 |

Root facts by stage (cascade facts excluded):

| Stage | Root facts | Questions | Which |
| --- | --- | --- | --- |
| record pass | 29 | 20 | q10, q12, q13, q15, q16, q17, q20, q27, q28, q29, q30, q35, q36, q39, q40, q41, q43, q44, q46, q47 |
| entity resolution | 12 | 12 | q01, q02, q03, q06, q07, q08, q16, q17, q41, q44, q46, q48 |
| plan-blocked (Money) | 11 | 9 | q19, q20, q22, q23, q25, q26, q33, q34, q39 |
| encoder mentions | 4 | 4 | q29, q39, q41, q48 |
| relation pass | 3 | 3 | q02, q04, q07 |
| validity not extracted | 3 | 3 | q02, q03, q04 |

Present-and-equal is rare because most questions were chosen to need records the extractor does not emit; what is
present and correct is people with email, Organization/Pet names, and the s22/s01 PersonalRelationship edges (modulo cause 2).

## Per question

| Q | Dependencies [class] |
| --- | --- |
| q01 | Rowan -wife-> Elena (s01) [wrong-entity] |
| q02 | Elena -wife-> the one holding the role [wrong-entity]; Elena design adviser (s18) [missing-relation]; valid_from 16 Oct [missing-time] |
| q03 | Elena creative director (s18) on gold entity [wrong-entity]; valid until 15 Oct [missing-time] |
| q04 | Mina interim creative director (s18) [missing-relation]; valid_from 16 Oct [missing-time] |
| q06 | Alex Chen -wife-> Sora (s22) [wrong-entity] |
| q07 | Alex Chen -wife-> Sora (s22) [wrong-entity]; Sora not a member of styling crew [missing-relation] |
| q08 | Alex Moreau + Alex Chen persons with emails (s02) [present-equal]; candidate set polluted by name-only 'Alex' entities (s23, s24) [wrong-entity] |
| q10 | PersonalTask lead-time (s23) [missing-entity]; due_on 'tomorrow' = 2026-10-18 [missing-time] |
| q12 | PersonalTask grading sheet (s06) extracted as a Product [wrong-kind]; due_at 2026-10-14T16:00Z [missing-time]; assignee Rowan / recipient Alex Moreau [missing-relation] |
| q13 | Event launch (s16) [missing-entity]; event_on 2026-11-06, status planned [missing-property] |
| q15 | Event guest-limit 40 (s30) extracted as Organization 'Nocturne' [wrong-kind]; Commitment keep list to 40 (s30) [missing-entity] |
| q16 | Commitment request by Elena (s30) [missing-entity]; speaker Elena on gold entity [wrong-entity] |
| q17 | WholesaleProspect 24 units (s07) [missing-entity]; buyer Lune Store (4 Lune Store entities) [wrong-entity] |
| q19 | Quote unit_price EUR 210 (s04) [missing-entity] |
| q20 | PurchaseOrder PO-60 (s13, s17) [missing-entity]; Invoice unit_price 225.00 EUR (s17) [missing-entity] |
| q22 | Invoice required_deposit 4050 EUR (s17) [missing-entity]; Payment 3780 EUR (s14) [missing-entity] |
| q23 | Payment 3780 EUR (s14) [missing-entity]; Invoice INV-204 (s17) [missing-entity] |
| q25 | Invoice required_deposit rev 2 (s17) [missing-entity] |
| q26 | Invoice / Payment for the EUR top-up (s14, s17) [missing-entity] |
| q27 | PurchaseOrder estimated_dispatch 2026-11-02 (s17) [missing-entity]; arrival_confirmed false [missing-property] |
| q28 | Event launch date (s16) [missing-entity]; PurchaseOrder estimated_dispatch (s17) [missing-entity] |
| q29 | Product NJ-01 code 'NJ-01 tech pack' (s26) [wrong-value]; FibreShare viscose 82 / silk 18 (s26) [missing-entity] |
| q30 | Fibre silk animal_origin (s26) [missing-entity]; MarketingClaim vegan (s12) [missing-entity] |
| q33 | ServiceOffer day_rate GBP 650 (s08) [missing-entity] |
| q34 | ServiceOffer proposed_on 2026-10-27 (s08) [missing-entity] |
| q35 | StockMovement opening black 18 (s27) extracted as Product 'NJ-01 black' [wrong-kind]; StockMovement opening navy 12 (s27) extracted as Product [wrong-kind]; StockMovement dispatch R-88 (s28) [missing-entity]; StockMovement return_quarantined (s29) [missing-entity] |
| q36 | StockMovement openings (s27) as Products [wrong-kind]; StockMovement dispatch / return (s28, s29) [missing-entity] |
| q39 | SalesOrder R-88 (s28) [missing-entity]; return StockMovement (s29) [missing-entity]; customer Avery extracted as Organization (s29) [wrong-kind] |
| q40 | Refund paid=false (s29) [missing-entity] |
| q41 | Appointment Fig 2026-10-16T11:00Z (s20) [missing-entity]; Pet name 'Fig the cat' (s10, s20) [wrong-value]; three Fig entities (s01, s10, s20) [wrong-entity] |
| q43 | Appointment (no attendance) (s20) [missing-entity] |
| q44 | TravelBooking hotel cancelled (s21) [missing-entity]; Trip Florence (s21) [missing-entity]; traveller Rowan Vale not the email-identified Rowan [wrong-entity] |
| q46 | PersonalTask dinner (s30) [missing-entity]; Commitment request by Elena (s30) [missing-entity]; requested_by Elena on gold entity [wrong-entity] |
| q47 | Commitment promise by Rowan (s30) [missing-entity] |
| q48 | name / phone / email of Alexandre Moreau (s25) [present-equal]; aliases ['Alex'] [missing-property]; production-contact role split over two Velluto Works entities [wrong-entity] |

## Method and limits

Classification is manual from source text, oracle facts and extracted records, joined by model, name and source.
Stage attribution for cause 1 is by elimination (plan allows the models; admission accepted everything; records absent);
the exact gate (kind pick, a required field, or the 0.95 threshold) is unobservable from the cache. Keeping `LOG` in the
cached result, or one logged re-run of s20/s21/s30, would settle it. The schema was read from the fixture app
(`app/src/main request` `{"op":"schema"}`, fingerprint `e0ec5c08`, equal to the cached results').
