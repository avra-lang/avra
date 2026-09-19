# Cache handoff III — the shared-table copy law

Supersedes handoff II's §5 and §6. Read §2 first: it is the finding.

## 1. Where it is now

Warm edit (user CPU): **1.16 s → 0.63–0.71 s**. No-op 0.11 s. Cold unchanged (~29 s).

| commit | what | measured |
|---|---|---|
| `7fe0d00` | a record's tab-split computed once per module | warm 1.16 → 1.05 s |
| `dbca4db` | `children` is one shared slot | mint 310 → 233 ms |
| `7e83fe2` | six member tables are one shared slot | fill 107 → 39 ms |
| `c6012b4` | `decl_ids` is one shared slot | mint 215 → 50 ms |

Each rides a seed refresh (`a2d9f10`, `451665f`, `1cbb478`, `4db2648`).

## 2. THE LAW — a vocabulary write through a shared intermediate copies it

`v = t[i]; v.push(x); t.set(i, v)` — or any `.set` on a `List<List<T>>` /
`List<SideTable<T>>` field — **deep-copies the whole table when the intermediate
is shared**. At ~6,400 declarations that is ~26–33 µs a write: `children` 80 ms,
`decl_ids` 170 ms, `written_seats` most of a 68 ms fill.

**The signature:** the cost is INVARIANT to how the write is spelled. The `.set`
twin, a direct nested `push`, a dedup-scan removal and a borrow-scoping all
measured neutral; only REMOVING the call helped. A body-invariant, call-dependent
cost is a shared intermediate, not the body.

**The fix is `Cell`**, exactly as `@std/sqlite` uses it: `List<Cell<List<T>>>`,
appends via `.push`, reads via `.get()`, indexed writes via `.set_at`. A Cell is
one slot every copy of the table reads, so the write lands in that slot and
copies nothing.

Converted: `children`, `module_files`, `file_decls`, `expansion_voices`,
`methods`, `impls`, `written_seats`, `decl_ids`. NOT converted — measured
NEUTRAL, do not re-chase: `seat_marks`, `marks`, `generations`. Not every nested
table is shared.

## 3. Corrections to handoff II

- **§6.1 "compact per-module declaration bundle" is the WRONG lever.** Its fork
  was "type interning vs table writes"; the answer is table writes — but a
  per-declaration COW, not the volume of writes. A bundle would not fix it.
- **Format parsing is cheap**: `m-decode` 27 ms + `m-facts` 14 ms + `l-decode`
  6 ms of a ~310 ms mint. A format-level bundle targets ~47 ms.
- Handoff II §5's reconstruction budget is now load ~120 + mint ~65 + fill ~40.

## 4. Measurement discipline (each cost real time)

- **`rm -rf .avra-cache` mid-session breaks the link.** Clearing between a build
  and its link leaves objects incoherent and the next link fails on an undefined
  symbol (`prelude.eprintln`, twice). Clear only BETWEEN builds.
- **An A/B must restore a good compiler.** A semantic-breaking variant installed
  as `build/avra` corrupts every later build. `cp build/avra.good-<hash>` back
  before each variant, and rebuild with `rm -rf .avra-cache`.
- **Per-declaration clocks inflate budgets.** `CLOCK_PROCESS_CPUTIME_ID` is not
  free, and the per-phase print (`ns / 1000000`) truncates sub-ms entries to
  `0ms`. The reliable budget is two clocks around a whole pass.
- **The phase timers are WALL (`CLOCK_MONOTONIC`)** and swing 2.5× under load
  (`union` read 224 ms then 578 ms on consecutive runs). Switch `avra_now_ns` to
  `CLOCK_PROCESS_CPUTIME_ID` (runtime/avra_runtime.c) before trusting a phase
  comparison; child processes then read 0.
- **The stable oracle is warm-edit USER CPU** (`/usr/bin/time -p`).

## 5. The next lever

`lower` ~230 ms is now the biggest bloc, and it is `union` (~224 ms) — the
worklist walk — not `memory` (~0 ms) and not `held_stubs` (~6 ms). Prime suspect:
`held_deps` reads each held unit's edge row from the store (stat + read + wire
parse per unit). The A/B was inconclusive because the phase timer is wall-clock;
**switch the clock first**, then A/B `held_deps`.

Also open: `analyze` ~134 ms, `load` ~120 ms.