# Handoff — std-config lane (2026-11-25)

**Goal:** `@std/config` (docs/2026_11_24_CONFIG.md), slices C1–C4. **Base:** `gh/program` at `e02d71ab`.

| Slice | State | Where |
|---|---|---|
| C1, C2, C3 | landed | `b5a71497`, `f08fb217` |
| C4 — the compiler's settings, one declaration and its projections | done, pushed, not landed | `lane/std-config/c4-settings` @ `826a5b4e` |

## C4: done
- `tools/src/settings/declared.av`: one `component Settings { user, debug }` holding 56 `@variable("AVRA_X")` leaves, by package (`program`, `avrac`, `cli`).
- `avra-tools tree_settings` (to become `wisp tree settings`): `--write`, `--check`, and with no flag prints each value with its origin.
- Generated (never hand-edit):
  - `packages/std-program/src/settings/settings.av` (holds the readers, exported)
  - `packages/std-avrac/src/core/settings/settings.av`
  - `packages/cli/src/settings/settings.av`
  - `tools/src/settings/named.av` (`enum Setting`, the oracle's names)
- 69 env reads migrated; `Configured.variables()`; text sources read `1`/`0` as switches.
- Tests: tools 49/49, std-config 38/38, std-program 493/494 (the red case is chmod-under-root, environmental), gate_changed clean.
  - All of these ran before the rebase onto e02d71ab.
  - After the rebase: `check packages/cli` 0 errors and `--check` fresh, on a compiler built at 62f2a454.

## Cost (cold `check packages/cli` vs 62f2a454)
| Pass | Change |
|---|---|
| tape | +0.042% |
| summary | +0.044% |
| resolve | +0.054% |
| laws | +0.148% |
| generate | +0.047% |
| typing | −0.069% |
| lower | −0.078% |

The overage on laws and resolve comes from the 3 new files. CONFIG §8.7 has the full table.

## Open questions (lead's)
1. Accept the laws/resolve overage, or fold the three projections into one generated file in std-program.
2. The `--check` keeper row goes into wisp's keepers table (static set), which belongs to the wisp lane.
3. C4 needs a tools build by a compiler at or after `f08fb217`, so main's current published compiler. An older release fails on std-config's `secret.av`.

## Half-done
None. C4b (the runtime's C names, via a header generated from the same declaration) is not started.

## Next
- If the lead folds to one file: edit `LANDINGS` in `tools/src/settings/projected.av`, then run
  `build/avra build tools && tools/src/main tree_settings --write`, then re-measure with the cold cli check (CONFIG §8.7 method).
- Otherwise: land `lane/std-config/c4-settings` as is.

## Filed asks
ROADMAP "Interim record — the config component's asks", A1–A6. A6 is an imported component's static call (`Outer.fields()`).

## Runs in flight
None.
