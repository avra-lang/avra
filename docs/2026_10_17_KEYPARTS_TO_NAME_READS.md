# KeyParts to name reads — the plan, in steps that each land

Status: PROPOSED. Owner: db-gather. Design source: `2026_10_06_COMPILER_DB.md` §2 laws,
§6.2 steps 2–5, A2 (the nine validity formats), A11 (rows and reads), A16 (the deletion
ledger: `KeyParts` is deleted at DB 07).

## Where KeyParts stands, measured

A one-body edit of `packages/cli`, fresh store, one literal moved (`check --counts --time`):

| what | cost before K1/K2 | after |
|---|---|---|
| judging 365 suspect file rows (KeyParts + `view_parts` per module) | ~415 ms | ~0 (`judge_fallbacks` 0) |
| every held file's object key rebuilt from KeyParts at keep | ~200 ms, 1056 builds | 86 builds |
| first kept-settle verdict (builds the same views) | ~175 ms | not yet moved (K3) |
| `load` phase | 1.4–1.6 s | ~1.3 s |

`KeyParts { module, path, text, runs, gathered, seen }` feeds three things:

1. the **file-rows judge** (`file_judged`): is a kept row still standing?
2. the **object key** of every held file (`held_okey` / `obj_key_cached`): the identity of
   its stored compiled object, its `said`/`asks`/`codes`/`rules` rows, its link entry;
3. **kept-settle lines** (`kept_settle.av`): six line kinds, six `*_stands` fns.

`seen` is the expensive part: a per-module VIEW (`view_parts`: `reach` + `narrow_index` over the
decoded records of every module seen), narrowed per file by the names it mentions.

## The target

A read records `(row name, digest)`; an answer stands when every read it was kept with has
its digest now (A11). Nothing is derived to judge: the digests are the rows'.

- a file's reads are its text, the run files it read, and the rows it resolved BY NAME
  (declaration wires with their signature digests), not a digest of a module view;
- an object's key is the digest of its reads, so two builds that read the same rows share it;
- the suspect set is the reverse index of the names that moved (§6.2 step 3), cut by early
  cutoff where a name's digest is unchanged (step 5).

`KeyParts`, `view_parts`, `reach`, `narrow_index`, `seen_by_name`, `stands_in`'s hand formats
and `kept_settle`'s six line kinds are deleted when this is done (A16: `record.av` 1605 → ~300,
`kept_settle.av` 324 → ~40, `derive.av` 867 → ~400).

## Why it is not one change, and where the flag day is

The judge and the object key read the same `KeyParts`; kept-settle lines read the same views
again. Two readers of ONE derived value can move one at a time as long as the value still
exists, and that is what K1 and K2 did: the judge now asks a stored stamp first, the object key
of a standing file is its stored row, and `KeyParts` is built only for files whose rows do not
stand. The part that cannot move piecemeal is the IDENTITY of an object: its key is a hash of
the parts, so changing what the parts are changes every key at once and strands every stored
object. That is the one flag day, and it comes last, after nothing else reads the parts.

## Steps

Each step lands alone, green on `cache-attacks-a/b` and the core suite under
`AVRA_DB_VERIFY=producers,filesaid`, with its counter drop in the PR body.

K1 — the judge by stored stamps (done on `db-07k-judge`). A row also reads `sp <module>`: the
digest of the module's record seen-lines and its file listing, kept in the module's producer
row. A row whose stamps stand is judged without rebuilding any view; the rebuild is the
fallback, counted by `judge_fallbacks` (0 on a body edit, ratcheted at 0). Witness: judge
~415 ms → ~0, `keyparts` builds 1056 → 86.

K2 — a held file's object key is its stored row (done, same branch): `okey-row` is kept beside
the other file rows and read for a file held because its rows stand. A file whose rows moved
still derives its key from the parts.

K3 — kept-settle lines as name reads. Each line kind (`u c m f b e`) becomes a read
`(name, digest)` kept with the settlement row; `*_stands` becomes the generic judge. The value
and its reads are ONE row (today two non-atomic writes, A2 #3). Witness: the first kept-settle
verdict stops costing a view build (175 ms), `kept_settle.av` shrinks by the six fns.

K4 — reads by NAME for the file rows. The names a file's analysis resolved (the leaves its
`Analysis` read: declaration wire + signature digest, as `typed_said_pass` already collects)
replace `Seen` / `SeenSet`. The stored stamp of K1 is the module-grain placeholder this
replaces. Witness: a body edit leaves every importer's rows unsuspected (suspect rows 365 → ~1),
and a signature edit suspects exactly the files that read that declaration.

K5 — the flag day. Objects are keyed by their reads (K4's names); `object_key_of_parts` and
`KeyParts` go, with `view_parts`, `reach`, `narrow_index`, `seen_by_name`, `stands_in`'s
formats and the record's `ref`/`file` columns that only fed them. One commit rewrites every key
and the store restarts cold; the packaged seed is refreshed in the same landing.

## Order and cost

K1–K2 are done and measured. K3 ~1 day. K4 ~2–3 days (the reverse index over names, the leaf
collection for every file answer, a witness per answer family). K5 ~1 day plus a cold bootstrap
cycle. K5 must follow db-externs' codec work only if the reads are stored through it; the
current text rows suffice, so the codec is not on this path.

## What each step must keep true

- A stamp that stands implies every narrowed view it covers stands: a module's stamp covers its
  record's interface, imports and references and the listing of its files, and a viewer's reach
  is a function of those and of its own record, so nothing a view reads moves under a stamp.
- The fallback is the old derivation, never a second opinion: `judge_fallbacks` says how often
  it ran, and `AVRA_DB_VERIFY=filesaid` compares every judged row with the file-row rule.
- No step adds a counter that is not ratcheted, and none leaves two judges for one row.
