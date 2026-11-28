Probes quoted in docs/2026_11_27_SYNC.md §11.

- `live/` — live queries: subscriptions indexed by equality key, fan-out per write against a
  scan: `./avra build scratch-probes/sync/live`, run the binary. `live_memory/` holds 1,000,000
  subscriptions and their index; run it under `AVRA_MEM_STATS=1` for memory per subscription.
- `register/` — the per-field register merge: `./avra build scratch-probes/sync/register`, run the
  binary; `AVRA_MEM_STATS=1` for memory.
- `prior_art.mjs` — Yjs and Automerge over the same workloads:
  `npm i yjs@13.6.20 @automerge/automerge@2.2.8`, then `node --expose-gc prior_art.mjs`.
- `order_keys.mjs` — fractional position key length under four insertion patterns.
