# Where extraction time goes

Measured 2026-10-26 on the fixture sources (`acceptance/sources.jsonl`), schema fingerprint `e0ec5c08`.
Tool: `extract/where_time.py` (per cascade method and per encoder query). Raw logs of an older cold run are in
`~/.cache/avra-graph-score/acceptance/logs`.

## Conditions (read before trusting a number)

- The Mac was shared with other lanes (swap 6.5 of 8 GB at one point, a second client on the model service, the data
  volume at 100%). Absolute seconds are inflated; shares are the finding.
- Only one generative model was resident (the beam lane's Qwen3-4B service). The profile therefore sent each closed
  choice to that service and charged it the service's own `compute_s`. The extraction's per-source prefix cache is not
  used on this path, so each choice pays the source's prefill (sources are 190-470 characters, so the cost is small:
  a bench of the real path measured 1.1-2.1 s per call with and without the prefix, `extract/bench/prefix-latency.txt`).
- The encoder ran locally (GLiNER2-large, 3.8 GB footprint), beside the service.

## Run A: 6 sources, current cascade (`s01 s05 s17 s21 s26 s30`: 1,764 characters, 222 LLM calls)

| Stage | Seconds | Share |
| --- | --- | --- |
| LLM closed choices (all) | 426 | 87% |
| Encoder queries | 61 | 12% |
| Encoder start | 20 | (once per batch) |

### LLM time by cascade method

| Method (what it asks) | s | calls | ms/call | Share of LLM |
| --- | --- | --- | --- | --- |
| `sentence_records` (which record kind a sentence states, 17 kinds + none) | 102 | 31 | 3297 | 24% |
| `value_of` (pick each field's value among spans, refs, enum members) | 89 | 57 | 1566 | 21% |
| `fill` (stated-check: does the sentence say this field) | 50 | 32 | 1575 | 12% |
| `timed` + `meaning` (time field: which expression, which date) | 84 | 40 | 2100 | 20% |
| `qualifiers` (speech act, polarity per record) | 47 | 28 | 1689 | 11% |
| `relate` (relation readings) | 19 | 8 | 2362 | 4% |
| `choose_speaker` | 18 | 13 | 1415 | 4% |
| `valued`, `quantity_field`, `antecedent` | 16 | 13 | 1230 | 4% |

The record pass as a whole (`sentence_records`, `value_of`, `fill`, `timed`, `meaning`, `qualifiers`, `valued`,
`quantity_field`) is 386 s, 79% of everything the extraction does. Relations, speakers and antecedents are 9%.

### Encoder time by query kind

| Query | s | calls | s/call |
| --- | --- | --- | --- |
| `fields` (21 labels: every required text field and quantity unit of all kinds) | 30.1 | 6 | 5.0 |
| `record:*` (one structure query per record kind with text fields) | 18.4 | 84 | 0.22 |
| `attributes:*` | 4.1 | 18 | 0.23 |
| `entities` (6 labels) | 3.6 | 6 | 0.6 |
| `statements`, `times`, `quotations` | 4.6 | 18 | 0.26 |

One `fields` call costs more than all 14 `record:*` calls of a source. GLiNER2 cost scales with the label count and
their descriptions; the text is only about 100 tokens.

## Run B: the logged cold run of all 30 sources (22 Oct, earlier cascade, cache `logs/`)

| Part | Seconds |
| --- | --- |
| Encoder phase (30 sources, one process) | 384 (12.8 per source) |
| Choices (sum of `choices_s`, 774 LLM calls) | 1,422 (1.84 per call) |
| Prefix and entities | 28 |

Choices are 78% of the cold run; the 24-minute figure is this run.

## Top 3 costs

1. **The record pass's LLM choices: about 80% of an extraction.** One 18-way kind choice per sentence is a quarter of it;
   the rest is per-field work (`value_of`, `fill`, time) on the records that kind choice or a loose gate lets through.
2. **Per-call overhead of a closed choice (1.2-3 s on this machine), times 222 calls for 1,764 characters.** The number of
   calls, not their size, is what costs: 12.6 calls per 100 characters.
3. **Encoder: `fields` query (about half the encoder) and 14 separate `record:*` calls per source.** 12-20% of the run.

## What this says about the record-pass redesign (DEEP-INGEST R2)

- A per-kind yes/no is **not** a speed path. It turns one kind choice per sentence into one per kind per sentence:
  17 kinds x 31 sentences = 527 calls at about 1 s each, against 31 calls at 3.3 s now, so the kind step would cost
  about five times more and the whole extraction about twice.
- It is a **calibration** path: the yes/no's p(yes) does not depend on how many kinds the schema declares, so a threshold
  fitted on invented domains transfers to any schema. The 18-way's top probability does depend on the width of the choice,
  so its threshold only transfers when it is fitted at the deployed width (`fit_records.py --mode choice --kinds N`).
- The levers that cut time are fewer calls per record (stated-check and qualifiers repeat per field and per record) and
  encoder label count; both change extraction behaviour and need a measured refit, so they are not part of this change.
