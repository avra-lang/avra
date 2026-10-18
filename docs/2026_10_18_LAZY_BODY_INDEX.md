# The sealed body, read lazily

Status: design note, nothing built. Owner: db-warm. Coordinated with db-externs
(stored codec, branch db-stored): it does not touch `store/body.av` or
`BODY_VERSION`, and rebases onto this bump if it lands first.

## Why

An unchanged `check packages/cli` is a pure store hit and costs ~130 ms on a
Sprite (`check --time`, #919). The first `store.get` opens the sealed body and
costs 34-43 ms of it, to answer 3-4 rows:

| part | ms |
|---|---|
| `read_bytes` of the 4.6 MB `body-<rev>.pack` | 9-11 |
| frame digest check over those bytes | 5-6 |
| `body_read`: 5061 slots + 12193 rows decoded into `pack.slots`, `pack.records`, `pack.order` | 19-24 |

The body grows with the store (+12 MB / +16 ms came with the per-module producer
rows), so the cost is linear in everything ever kept, not in what a command asks.

## Shape

`pack.records` (Map record_key -> Held), `pack.order` (ordinal -> record_key) and
`pack.slots` (digest -> place in `.val`) are three eagerly built tables. Make the
SEALED half answer from the file and keep the maps for what this process writes.

- `records` becomes an overlay (writes, withdrawals, merged segments: today's map)
  over a `Sealed` reader. `record_of` asks the overlay, then `Sealed.find(key)`.
- `Sealed.find` binary-searches `body-<rev>.idx` (S4's fan-out over the first byte
  of the action key, sorted keys, parallel offsets — already written at seal, read
  by nothing today) and decodes ONE row from a span read of the pack.
- A row carries its value's place (`at`, `len`) and its set id and ordinal inline,
  so `slots` is not a table: digest sharing costs a few repeated offsets.
- `order` (ordinal -> key) is used by `sealed_readers` only. A reverse run names
  rows by ordinal; the body stores a key table next to the reverse section, read
  on demand, never at open.
- The frame check: a torn body is caught by the commit marker and a length; each
  value is already checked against its own digest on read, and an index/row that
  does not decode answers absent, which is a miss. The whole-body digest is not
  re-run on open.
- Open reads the header, names, sets (octets, already lazy) and the idx fan-out:
  tens of KB. A hit reads the rows it asks (manifest, closure, 3 row families).

## Users to pay (each changes with the overlay)

`store/body.av`: `body_scan`, `body_read`, `seal`, `body_payload`,
`referenced_digests`, `standing_slots`, `action_keys`, `sealed_readers`, `resident`,
`record_of`. `store/pack.av`: `opened_at`, `pack_found`, `pack_reads`,
`pack_get_rev`, `pack_rows_rev`, `withdrawn`, segment merge (`scan_segment`), clean
and compaction (`pack_clean`). Seal and clean are writer paths: they may read every
row once; only a hit must not.

## Proof

- COUNT, not only ms: `check --time` prints `rows read N` for the hit (a tally of
  rows decoded from the sealed body). A hit of `packages/cli` reads <= 8; today it
  decodes 17254 items. A cache-attack keeps that number gated.
- Eval parity: every store attack (`make cache-attacks`, `store-attacks`) unchanged.
- A body written by BODY_VERSION 4 is a miss once, then rewritten.

## Not in this change

Reading ~1100 input files (`inputs`, ~35 ms) is a separate floor: the host read is
~22 ms, near the 15 us/file a plain read costs on the same machine, blake3 4 ms.
No mtime/size shortcut (the 10-06 design refuses stat-first).
