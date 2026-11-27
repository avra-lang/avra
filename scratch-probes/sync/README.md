Probes quoted in docs/2026_11_27_SYNC.md §8.

- `register/` — the per-field register merge: `./avra build scratch-probes/sync/register`, run the
  binary; `AVRA_MEM_STATS=1` for memory.
- `prior_art.mjs` — Yjs and Automerge over the same workloads:
  `npm i yjs@13.6.20 @automerge/automerge@2.2.8`, then `node --expose-gc prior_art.mjs`.
- `order_keys.mjs` — fractional position key length under four insertion patterns.
