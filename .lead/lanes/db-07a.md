# DB 07a — mint ownership (slice 1)

[2026-10-14] HEAD `db-07a` off `origin/db-slice` @ `ec276593` (S4c). Sprite `avra-db-07a`
(created — none free; all 56 pool sprites bound). Lane worktree
`/Users/tristan/projects/tristanMatthias/avra-db-07a`.

## Base reconciliation (the brief's line refs are stale)
REPORT 8 / the brief describe the eager mint as `settle_holds`' third loop at
`derive.av:998-1005` (main `708e712b`). On this base that loop only registers FileIds —
`mint_module` is called only from `file_ensured` and `named_minted`. The eager mint left
is `held_ensured()` (~`decls_mint.av:387`): a loop over every held file's `ensure_file`,
called by `indexed`/`indexed_by_mark`/`externs`; `named_rows` had no ensure. That is the
loop deleted here, and the four readers are the ones covered.

## What landed (the diff)
- `Hold.named_by`/`worded_by`/`marked_by`/`externed_by`, filled in `load_imports`
  (`note_producers`, record.av) from the fields `read_row`/`facts_unblocked` already
  decode: line p[5]=name, facts p[14]=word, facts p[0]=external, annotations=marks.
- Four armed hooks on Decls (`ensure_named`/`worded`/`marked`/`external`); the four
  bucket readers call them before the read; the workspace mints the listed modules.
- `held_ensured` deleted; `Q mint` qtrace in `mint_module`.

## Receipts (Sprite, gen-1 product from this source)
- `cache-attacks`: 449 builds / 145 under a hold / **0 failed**.
- `avra test packages/std-avrac`: **8807/8811** — four pre-existing `Writes`-family
  failures (decl_grain 183/188, family_reflect 9/12).
- `avra test packages/cli`: **369/375** — six failures (explain_holds 77/90,
  kept_settle 152, sound_check_cache 35/42/47). **Attributed: identical on the stashed
  base** (`git stash` then same suite) — pre-existing on `origin/db-slice`.
- `gate_changed --no-keepers --files <5> --packages std-avrac cli`: fmt clean (5
  examined, 0 differing); **22 idiom sites, all pre-existing** (none in the new fns;
  leaves.av/body.av/fp.av/kernel.av/db.av and pre-existing `bare_interface`).
- `make keepers-static`: exit 0 on the Sprite.
- `make leaves --check`: red **identically on base** — Lifted 49/16524 and 84/26057
  (baseline 47/16170, 75/25540) — pre-existing, not this delta.
- `explain --stats --time packages/cli` after a check-warmed store: base `2 of 511,
  load 1663ms`; index-on `2 of 511, load 1807ms` — no load movement (the index is not
  on the `met_files` path).

## The finding that changes the plan
`index-off` (the index built but `minted_modules` a no-op = the loop-deleted tree) gives
the SAME `cache-attacks` 0 failed and the SAME 8807/8811. **No attack or test witnesses a
bucket read outrunning its producer**, so the four readers are fed by other paths on this
corpus (package admission mints a collector's package; `keep` mints the rest). The index
is the plan's safety net, not a witnessed fix. No 5th reader surfaced because no reader
failed. A biting case needs a held `collect enum` gatherer reached only by
`collect_enums()` with no package admission — not yet built.
