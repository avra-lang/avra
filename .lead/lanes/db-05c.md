# db-05c — the store's gc and time travel

Branch `db-05c` off `origin/main` @ `9cdec783`. Worktree `/Users/tristan/projects/tristanMatthias/avra-db05c-tail`.
Goal: §6.7 — a bounded store (size/age/LRU + the N-revision time window),
`avra cache gc` reclaiming by the design's rule, and the time-travel read
(answer an older revision from the sealed body/idx; no second format).

## heartbeat

- 2026-10-15T00:00Z started; read §6.1/§6.7/§6.2 step 6 + DB_AUDIT 05c row.
  Main already has the sealed body/idx (#582) and `keep_bodies` (KEPT_BODIES=2,
  `AVRA_STORE_REVISIONS`). No `avra cache`, no time-travel read, no size/age/LRU.
  No free Sprite at `work new` — created the worktree manually; a Sprite is owed
  before any heavy run.
- 2026-10-16T08:20Z built; unit 8/8; store_gc_attack 12/12 green on Sprite
  `avra-db05c-tail`. Added `pack_gc`/`prune_bodies` (window/size/age, newest
  never doomed), `body_scan_rev`+`pack_get_rev`/`pack_rows_rev`, `Store.gc()`,
  `avra cache gc|log|show <rev>`, `tools/store_gc_attack.sh`, `make store-attacks`.
  Receipt on packages/cli: cold store 71 MiB/10 revs; default gc keeps 10;
  `AVRA_STORE_MAX_MB=64` gc -> 1 rev, 65 MiB. Found+fixed two units bugs (mtime
  is wall SECONDS, `now_ns` is monotonic; the age limit was evicting the newest).
  NOTE: `tools/store_attacks.sh` (§6.8) is separately red on main by design
  (a stage-1 S2 `fail`) plus a flaky contested-lock case; `make store-attacks`
  runs the gc list and is green.
- 2026-10-16T09:20Z PUSHED + DRAFT PR #816 (base main, unarmed). Head
  `f33b5004`. Final receipts on the frozen Sprite tree: gate_changed clean
  (fmt 0 differing, idioms hold), keepers-static 0, cache-attacks 0 failed
  (store-gc 13/13), cli suite 381/381, gc unit 8/8. Red-team 10 classes run;
  survivors fixed (wall-vs-monotonic age clock, roots-protected age, cold
  hold writer, 6 store-read licenses). Review round: centralized `store_dir_of`
  and `store_file_bytes` (three `"store"` spellings -> one), probes moved to
  /tmp. ONE definition, one format. Blockers: none; PR is BEHIND main, a
  rebase is owed at landing.
