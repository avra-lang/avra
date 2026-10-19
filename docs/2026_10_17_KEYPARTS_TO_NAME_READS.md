# KeyParts to name reads — the plan, in steps that each land

Status: K1-K5a DONE, K5b closed. Owner: db-gather. Design source: `2026_10_06_COMPILER_DB.md` §2 laws,
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

## Where it stands (after K1-K4d, K5a)

Measured on `check packages/cli`, one literal moved (body edit) and one `export fn` added (interface edit):

| | before | now |
|---|---|---|
| body edit: judge_fallbacks | ~420 | 0 |
| interface edit: judge_fallbacks | 420 | 3-4 |
| interface edit: narrowed names judgement | 674 ms | 60 ms, ~700 lookups |
| first kept verdict, body edit | 246 ms | 10 ms |
| KeyParts builds on an edit | 1056 | 86 |
| building a module's view (reach) per edit | ~350 ms (2 views) | from producer rows |

What is left of KeyParts: it is still the IDENTITY of an object (its key is a hash of the parts), the
judge's fallback, and what `keep` writes the file rows' reads from. The cost of deriving it is now
`view_parts` (a module's reach, the narrowed index) and 86 `key_parts` builds per edit.

## Steps

K1-K4d are done (see the PR). K5 is in two parts, because the second is the one flag day.

K5a - views from producer rows (no key changes). A module's reach read each reached module's record
by decoding it: `place_files` (the `file` lines), the non-builtin `ref` rows, the re-export lines and
the typed index (every declaration row's wires). Those are now lines of the producer row (`placed`,
`rrefs`, `reexport`, `typed`), made by the same functions from the same record, so every key is the
one the record route computed. `narrow_index` still reads records (24-47 ms an edit) and moves next.
Receipt: reach of two views 346 ms -> producer-row walks; interface-edit `keep` ~690 -> ~515 ms and
`load` ~1.3 -> ~1.1 s.

K5b - CLOSED, not built. THE LAW: a content-addressed key must name its inputs. An object lives at
`obj/<okey>.o` and the link key folds the okeys, so one key may never hold two byte strings; the
narrowed view digest in `KeyParts` IS that record of what the object was made from. After K1-K5a
`KeyParts` is exactly that and nothing else: the judge no longer builds it, and deriving it reads
producer rows (~150 ms an edit, down from ~450). Deleting it would mean per-path overwritten object
rows and a link key over content, a different store, for no further saving; what remains of the
cost is not the key but the reads the key stands on (see the const outline fix, then DB 07).

The (file, name) relation in `@std/relation` (an index by name over a file's spelled names) stays the
replacement for `spelling`'s per-file map; it lands with the per-declaration answers (DB 07).

## What each step must keep true

- A stamp that stands implies every narrowed view it covers stands: a module's stamp covers its
  record's interface, imports and references and the listing of its files, and a viewer's reach
  is a function of those and of its own record, so nothing a view reads moves under a stamp.
- The fallback is the old derivation, never a second opinion: `judge_fallbacks` says how often
  it ran, and `AVRA_DB_VERIFY=filesaid` compares every judged row with the file-row rule.
- No step adds a counter that is not ratcheted, and none leaves two judges for one row.
