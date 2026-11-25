# The sealed body, read lazily

Built. `store/body.av` (format `BODY_VERSION` 5) and `store/pack.av`. Coordinated
with db-externs (stored codec, branch db-stored): it does not touch the body
layout and rebases onto this bump.

## Why

An unchanged `check packages/cli` is a pure store hit and cost ~175 ms on a
Sprite. Its first `store.get` opened the sealed body and cost 34-43 ms, to
answer 3-4 rows: reading the 4.6 MB `body.pack` (9-11), checking the frame
digest (5-6), decoding 5061 slots and 12193 rows into three eager tables
(19-24). The body grows with everything ever kept, not with what a command asks.

## The format

`body-<rev>.pack` is a head, then six sections:

| section | what | read |
|---|---|---|
| head | one framed record: magic, version, rev, value rev, print, row count, and each section's place and check | at open |
| index | one 51-byte line a row, in body order: `\n`, the first 32 hex digits of the row's action key, offset and length in the rows section (zero-padded decimal) | at open |
| slots | one line a referenced value: `\n`, its whole digest, offset and length in the `.val` | on the first value read |
| names, sets | the read-set tables, as before | when a read set is asked |
| reverse | input name -> ordinals of the rows that read it, as before | when suspects are asked |
| rows | one framed record a row: family, key, digest, set id | a row at a time |

A lookup is one `index_of` over the index bytes; the line's position is the row's
ordinal. The row is decoded from one span read and held to the key it was asked
by (a row that decodes to another key is absent). A value's place is found by its
digest in the slots section. Every section but rows carries its check in the head,
verified when the section is read; each row carries its own frame check. A torn
head or index is a torn body at open; damage past them answers absent where it is
read. `pack.slots` stays as the in-process placements a seal makes; the sealed
body answers the rest.

## The open index

`Pack.records` is the OVERLAY: this process's segment rows and writes, over a
`Sealed` reader (`Pack.sealed`, none or one). `record_of` asks the overlay, then
the sealed body. A seal folds every row, so `materialized` lifts the sealed rows
and slots into the overlay once (a writer path; a hit never calls it). The old
`.idx` file, written and read by nothing, is gone.

## Proof

- COUNT: `Traffic.rows` tallies the rows decoded from the sealed body and
  `store/row` is its trace line. `tools/store_index_attack.sh` gates that a warm
  check of 10, 400 and 1600 records decodes at most 8 rows, never more as the
  record count grows, and that the open reads a part of the `.pack`, not all of it.
- The warm hit of `packages/cli`: ~175 -> ~140 ms (index alone); store open 35 -> ~1 ms.
- `store_seal_attack.sh`: a flipped head byte is a torn body; a flipped middle byte
  changes no answer. pack_test (12/12), store tests (34/34), `store_clean_attack`,
  `store_reads_attack`, `store_quiet_attack` and `cache_attacks.sh` (477 builds,
  0 failed) pass. `store_attacks.sh` fails the same three attacks it failed before
  this change.
- A body of BODY_VERSION 4 is a miss once, then rewritten (`pack_format` folds the
  version into every key).

## Not here

The `inputs` read of ~1100 source files (~35 ms) is a separate floor: the host read
is ~22 ms, near a plain read's 15 us a file; no mtime or size shortcut.
