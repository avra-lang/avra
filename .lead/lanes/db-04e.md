# DB 04e lane — ledger every outside-door site

Base: `origin/main` @ `9cdec783` (wave 2).
Worktree: `/Users/tristan/projects/tristanMatthias/avra-db-04e` (branch `db-04e`).
Sprite: `avra-db-04e` (bound).
Task: triage the outside-door sites in `tools/inputs.baseline`; license the `not inputs` at each site
(baseline only falls), move real reads through the door where a cell exists, defer the rest.

Plan source: `docs/2026_10_06_COMPILER_DB.md` §5.2 + A18; `docs/2026_10_06_DB_04_INPUT_DOOR.md` (the b–e cut).

## Log

- start: read the design §5.2/A18, `.lead/DB_AUDIT.md` (04e row), the DB_04 input-door doc, `tools/inputs.py` whole.
- `make inputs` at `9cdec783`: **65 outside** (18 door, 46 licensed). The audit's "66" is stale
  (counted at `69522c3d`); the file is 65 non-comment rows + 5 header lines.
- Sibling child lanes exist (unlanded, off older main): `db-04e-isdir`, `db-04e-octets`,
  `db-04e-tool-project` — they own the real-read moves (is_dir / octets / tool stamp).
- Slice: **license every read that is no input of what is built** — 34 sites: clock 17,
  evaluator effect 9, store IO 3, saved-read witness 3, scratch name 2. Matches the DB_04 doc's row `e`.
- Edits landed on 8 files (comment-only); `python3 tools/inputs.py` → **31 outside, 80 licensed**;
  `--accept` pruned the baseline 65 → 31.
- Red-team (licence form): 6 near-miss shapes (lowercase, no reason, uppercase reason, blank reason,
  block comment, trailing comment, a line above) — all refused. Witnessed: loosening the regex makes
  5 of 6 bite; added as permanent fixtures in `inputs.py` selftest.
- Review-round debris: 3 inert `input.*` licences removed (`refuses.av` pure `inherited()`,
  `pack.av` duplicate + a write). 1 leave-alone named: `tasks.av:164` (`dir.taken` is a method read
  the keeper does not follow) — trigger: the keeper follows methods.

- Pre-flight (Sprite `avra-db-04e`, 8 GB): `gate_changed --files… --packages std-avrac cli --no-keepers` green
  (fmt + idioms + `check --baseline`); `make keepers-static` green on the Mac (the Sprite has no `.git`, so
  fetch_compiler's self-test and pr-watcher's GitHub self-test cannot pass there); `make inputs` 65 -> 31.
- Affected suites: the full `avra test packages/std-avrac` peaks ~7.4 GB and the Sprite is 8 GB — part 2 reached
  8988/8988 module tests then OOM'd (137); running the compiler/door tests + cli in bounded pieces instead.

- CORRECTION: the suites must run through `build/avra`, as CI's suites job does
  (`AVRA_SOUND_CHECK=1 build/avra test packages/$p`). Running them through the `./avra` shim holds the
  machine lock, and `sound_check_cache_test` re-enters the shim -> every `hit()` times out at 60s, so that
  spec failed 3/381 on the cli suite (and explained the std-avrac rule-proof crawl). Re-running via `build/avra`.
- `make cache-attacks`: GREEN, 0 failed (457 builds/149 held; link-cache, turn-memory, gathered, store-reads,
  stamp, static-names, moved-tree, held-runs, fn-add, cancel, writes, cancel-bits, readfound, durable-symbol).

- Rebased onto origin/main @ de560248 (main moved 3+ commits while the lane ran); `make inputs` still green.
- Final pre-flight on the rebased tree: `gate_changed` green; `make inputs` 65 -> 31; `build/avra test packages/cli`
  **381/381**; `make keepers-static` green (Mac).
- `make cache-attacks`: RED — `expanded-attack` (93 Expanded settles, busiest file 4, limit 3). Reproduced on
  `origin/main` @ de560248 WITHOUT the lane commit, identical numbers. A pre-existing main regression, filed in PR #821.
- `avra test packages/std-avrac`: the whole package peaks past the 8 GB lane Sprite (module tests + check phase pass);
  CI runs it on its own runner.
- DRAFT PR #821 (base main, not armed): https://github.com/avra-lang/avra/pull/821
