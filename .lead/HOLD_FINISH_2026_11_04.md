
## 2026-11-04 (fourth session): the edit's cost was a write nobody reads

`hold-out` = **`dc5ca0b5`**. Merged since `4de44a4e`: `L-names2` (`ffacda97`, `Names` family deleted,
26 → 25), `L-hold3` (`a6c3aff8`, 5 commits, −354 lines: the hold's file set, its tables, its
per-attempt records, `held_paths`), `L-lowercost` (`537cf531`).

**`L-lowercost` is the win.** `lowered_unit_of` is a lasting `@query` whose `@codec` answer made every
unit savable; its leaves (a name bucket's members, a parsed file, a body's typing) never verify in a
new process, so all 21 089 units recomputed and 9 658 still wrote 178 MB of records per edited run.
`lowered_saved` now calls the engine's existing `in_process_only()`. One file, +7/−2.

| `check --time packages/cli` | before | after |
|---|---|---|
| cold wall | 105.8 s | **69.2 s** (`lower` 52.5 → 20.3) |
| unchanged | 209 ms | **117 ms** |
| one comment edit | 99.5 s, 0 errors | **55.5 s, 0 errors** (`lower` 49.1 → 13.6) |

**What is left, and it is one thing.** The edit now spends `analyze 32.7 s` (of which `bodies 15.0`)
and `lower 13.6`. Both are the same defect: a declaration's identity is its ARENA RANGE, not a
stable one. `placement_of` is `@scoped_by(in_arena)` — "names nothing past the process" — and
`typed_body` is `@scoped_by(body_scope)`/`@recursive`, so every decl-grain answer is process-local
and no warm run can reuse one. Fixing it is the Nodes/DB epic slice: key and hash a declaration by
path + module + declaration symbol, never by arena position. That is the only route to ≤300 ms.

**Two findings to carry:**
- `syntax_in` is documented durable ("two declarations of one shape fold alike wherever they sit")
  but has no `@lasting`; `names_in` DOES have `@lasting` today while folding `decls.ids()` into its
  answer. Hand-declared durability is already inconsistent in both directions in one day — it should
  be inferred and refused when unprovable.
- Under `AVRA_SOUND_CHECK=1`, `check packages/std-avrac` against a store warmed by `check packages/cli`
  traps "a source text was read before the workspace staged it": judging a saved `manifest_in` record
  asks its `file_text` leaf, a lazy load the `unstaged` law forbids. `L-lowercost`'s removing of
  dormancy exposed it; it is a real record-shape defect, not a test artefact.
