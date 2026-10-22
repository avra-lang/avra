# Local extraction cascade (spike)

An encoder proposes spans; a small local LLM only scores closed choices;
E01 admission decides what enters. Nothing here writes a fact the source
does not quote.

```sh
python graph/extract/cascade.py < request.json > result.json          # C01 ExtractionRequest in
python graph/extract/cascade.py --catalog schema.json < envelope.json  # or a bare I01 envelope
python graph/extract/request.py s01 schema.json > request.json         # request from a fixture row
python graph/extract/summary.py result.json                            # one line per record
python graph/extract/cascade.py --serve                                # keep both models resident
```

With a service listening on `~/.cache/avra-graph-ml/cascade.sock`, cascade.py is a
thin client; without one it runs in-process (`--local` forces that). Every
choice about one source reuses the source text as a cached KV prefix
(`--no-prefix` turns it off).

The socket speaks one JSON line in, one out, per connection:
`{"op":"generate","messages":[…],"max_tokens":n,"stop":[…]}` answers `{"text":…}`, ended before the first stop string
(greedy), so other local tools share the one resident model; `{"request":…}`
answers an extraction; a failure answers `{"error":…}`. An antecedent links only with a 0.5 margin;
it becomes a new entity only when no candidate is plausible, else abstains.

`schema.json` is the app's `{"op":"schema"}` answer. stdout is always one
C01 ExtractionResult (`failed` with a problem when the models cannot load);
timings, peak RSS and skipped models go to stderr.

## Stages

1. **Plan** (catalog only): reference targets whose required fields are text
   become entity models; models with a relation binding become relation
   models, closed labels from the binding, free labels as spans. Anything
   else is skipped with a reason.
2. **Spans**: GLiNER2 entities (model name + description as label), then a
   record-mode structure for the other text fields; identity keys follow
   the model's identity bindings.
3. **Choices** (LLM, next-token probabilities over option letters): the
   antecedent of a partial name, the speaker of a passage or quotation, the
   labelled reading of each candidate pair (both directions, every declared
   label, or "none"), modality and polarity.
4. **Anchors**: every field quotes exact UTF-8 bytes and names its innermost
   proposed frame (chat turns, quotations).

## Environment

Outside the repo: `~/.cache/avra-graph-ml/venv` (Python 3.12, `gliner2[local]`
2.1.0, `mlx-lm` 0.32.2) and `HF_HOME=~/.cache/avra-graph-ml/hf`. Models are
pinned by revision in `cascade.py`.

## Admission

`acceptance/app/src/tests/extract_admission` runs E01 over recorded pairs:

```sh
EXTRACT_CATALOG=1 EXTRACT_ADMISSION="/abs/req.json,/abs/res.json;…" \
  ./build/avra test graph/acceptance/app/src/tests/extract_admission
```

The catalog fingerprint folds compiler validator hashes, so a request must
bind the catalog of the program that admits it (`EXTRACT_CATALOG` prints
it); the app binary's `schema` answer differs. `recorded/` holds the slice's
proposals as produced, bound to the app binary's catalog.

## Choice bench

`bench/decisions.jsonl` holds 42 hand-labelled closed choices from the slice:
34 the cascade asked plus 8 harder ones (requests, promises, denials,
cross-source names). `python bench_choices.py qwen|jevk5` scores one backend;
keep only one model resident. jevk5 (ollaya) takes at most 16 options, so a
labelled-pair choice is asked as label-or-none and then direction.
Probabilities are logged raw for later calibration.

## Time candidates

`timex.candidates(anchor_ms)` enumerates what a time expression in a source
written at `anchor_ms` could mean, by calendar arithmetic only: every date
`time_window_days` (service_parameters.json) either side of the anchor's UTC
day, labelled with weekday, day, month and year; the anchor instant itself;
and "this is not a specific time" / "cannot tell from the text". A closed
choice picks one, and `timex.chosen` gives the TIMEX3 normalization
(`timex_type`, ISO 8601 `value`, `reference` = the anchor) to put beside the
field's anchor passage. The model never writes a date. Durations and sets
come later. `python3 -m unittest test_timex` in this directory.
