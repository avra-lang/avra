# Design — `.218` part (2): per-declaration reads in the object key

APPROVED by team-lead. Ticket `avra-8sb5.57.218`. Goal: a compile-time run's read names the
declaration or body it read, so a body edit ELSEWHERE in the read file leaves its readers held
(today it re-reads every reader of the file: held 446/462 where 448 is sound; ~0.2 s/edit).

## 1. The read value, and the record shape

New value type in `compiler/record.av` (beside `Placed`, record.av:92):

```
export type Read = { path: string, digest: string, ref: string, print: string }
```

- `path`   — the read file
- `digest` — its `text_digest` at write
- `ref`    — the declaration read (`decl_ref`, settlement_wire.av:221), or `""`
- `print`  — `"${self.syntax(d)}"` of that declaration, or `""` (no declaration, or a held read file)

The same four fields the `u` line already carries per unit (kept_settle.av:107-120).

- `Hold.runs` (workspace.av:198) becomes `Cell<Map<string, List<Read>>>`.
- **`file` line / runs column** — interface.av:507 writes `hex_fields(self.ran_by(store, f.path))`.
  `ran_by`/`ran_directly` (interface.av:564,578) → `List<Read>`. Each entry encodes
  `hex(path)~digest~hex(ref)~print`, `|`-joined. `hex_fields`/`runs_of` (record.av:1713,1723)
  decode to `List<Read>`; an entry without `~` is the legacy path-alone form → `Read{ref:"", print:""}`.
- **`r` line** — `keep_verdict` (kept_settle.av:214) writes `joined(["r"].concat(read),"\t")`;
  `read` is the same encoded `Read`s. `kept_row_stands` keeps `"r" -> true` (kept_settle.av:252);
  `kept_verdict` (kept_settle.av:234) decodes `reads.slice(1,...)` to `List<Read>` and echoes
  them via `read_by` so a kept verdict still propagates its reads.
- **`key_parts`** (record.av:1249) stays `runs: List<string>` (folded tokens), so
  `key_of_parts`/`parts_wire`/`parts_of`/`parts_moved` are untouched. It folds each `Read`:
  - `ref=="" || print==""`        → `run_said(r.path)` (today's digest);
  - digest unchanged              → `r.print` (no parse);
  - digest changed                → `"${self.syntax(decl_from_ref(ref))}"` — see §2.
- `Row`/`record_line`/`record_shape` (interface.av:385,407; record.av `Row`:193) **unchanged**:
  a body/syntax print belongs on the reader's run line, never the declaration's record line.

## 2. The ordering catch, and the fix

Call path: `load_named` (record.av:628) → `meet_file` (860) → `read_why` (907) →
`obj_key_cached` (312) → `key_parts`. This runs before anything is parsed, and a key must never
trip a query. So `key_parts` CANNOT call `syntax`.

**Fix — defer the HOLD, not the key.** When a `Read` has `ref`+`print` and its digest moved,
`key_parts` returns a pending-marked token and records `hold.pending_reads:
Cell<List<PendingRead>>` (`{reader, read}`); `read_why` returns `null` (hold) and `meet_file`
seeds the read file so it is read. A new pass `resolve_pending_reads(store)` runs as the first
step of `settle_holds` (derive.av:829), before `stands_in`/`hold_only`: it calls
`parsed(file_id(read.path))`, then `syntax(decl_from_ref(read.ref))`, compares to `read.print`,
and either keeps the reader HELD (finalizing its `key_parts` memo) or
`hold.forced.put(reader, Reads.RunBy(...))` to read it. This is the ticket's "change to the order
of the hold decision" — inside hold settlement, so NO attempt is discarded.

Cycle: none in `key_parts` (stays a pure key derivation). The deferral runs inside `settle_holds`;
`parsed` → `resolved` → `load_interface` is guarded by `loaded_records`/`met_files`
(record.av:631,701).

## 3. Writer side (where ref + print come from)

- `read_by(reader, paths)` (workspace_analysis.av:576) → `read_by(reader, reads: List<Read>)`.
- `settled()` (531) holds `f`+`root`; `decls.decl_of(f, const_stmt(root))` gives the ref,
  `syntax(d)` the print (read files are parsed here).
- `logged_unit(w: Wanted)` (kept_settle.av:98) has `w.decl`/`w.file`; its `u` line already
  computes `decl_ref(d)` + `syntax(d)` — the same pair feeds the read.
- `recorded_reads(f, l, chain)` (585) maps each `Body b` by `b.file`; add the body's declaration
  (by name in that file) for ref+print.
- `run_read`/embed (563) has no declaration → `Read{ref:"", print:""}`.
- `Workspace.syntax(d)` (workspace.av:1783, `Family.Syntax`) is the one print source; `is_held`
  files yield `""` (as the `u` line does, kept_settle.av:113).

## 4. Cost and proof

+40-60 B/read (#324's cli read lines are 120,846 B). ~200-300 lines.
Tests: `kr`/`kv` (tools/cache_attacks.sh:1434,1462 — chain held; a moved body → `discarded 0`);
a NEW two-edit attack (edit elsewhere holds the reader; edit the READ declaration reads in
attempt 1, discarded 0); `tools/db_measure/store_two.sh` back to 0 differing keys;
`warm_edit.sh` held back to 448.

## Risks
- First build after upgrade is cold: the key shape changes, invalidating every store.
- A held read file yields no print → falls back to digest (no saving).
- `ref` instability (insertion moves sibling counts) must fall back to digest.
- Late module load during `settle_holds` if the read file is cross-module.
- Parse+resolve of one read file vs re-lower/re-run of the reader must be MEASURED — parsing could
  exceed the 0.2 s it saves.
- `parts_moved` must decode both record shapes during migration.
- `distinct` keeps one `Read` per (path, ref) — dedupe by path+ref, not path alone.

## Files
- `compiler/record.av` — `Read`, `key_parts` fold, `runs_of`/`hex_fields`, `read_why`/`meet_file` hook
- `compiler/kept_settle.av` — `r` line in `keep_verdict`, `kept_verdict` decode, `logged_unit`, `settle_run`
- `compiler/workspace_analysis.av` — `read_by`, `settled`, `recorded_reads`, `run_read`
- `compiler/interface.av` — `ran_by`/`ran_directly`, `file` line runs column (interface.av:507)
- `compiler/derive.av` — `settle_holds` (`resolve_pending_reads`) and `stands_in`
