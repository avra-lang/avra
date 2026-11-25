# hd-store handoff (2026-11-02)
- Branch `hd-store` (worktree ../avra-hd-store), pushed at c67ae934 (base hd-clean 55b635b1 + 2 hd-ghrun picks).
- Done: 19356b65 runs (#1201 port) + reachability window · 2e4a3ceb body v8 binary (172 vs 477 B/row, packs 36.9→8.3 MB, open 140→1.4 ms, edit keep 340→327 ms) · cb483858 values are octets, Answer raw (469 B/row) · 004e13ba attack fixes (torn rows/tables said, claim vs body, no lock retry) — UNVERIFIED by the attack scripts yet.
- Specs: 126/126 store specs on a GitHub runner (pre-004e13ba); std-avrac check clean locally after 004e13ba.
- In flight when stopped: GitHub run 41397503059 = store_attacks + store_clean_attack on 004e13ba (output → .measure/attacks1.out, untracked).
- Next 1: read that run; store_clean's 4 (window of two left N bodies; "evicted rev" not named; `cache show` on evicted rev) likely need prune/clean to count a revision as a HEAD and fold to ≤N bodies on clean (pack_clean seals whole then prune_bodies) — check reclaim.out.
- Next 2: cold keep +2 s (16.5→18.5): run `.measure/cold.sh avra-try` (untracked, sums `Q store sealed … us`); suspect Writer byte-per-push encoding in body_bytes/index_bytes — build bytes as concatenated chunks.
- Dropped (lead): record.av / settlement_wire / family_wire framings; unit-row bytes (die with hd-decl's unit_kept).
- Open: close PR #1201 citing 19356b65; .val unchanged (29.5 MB, 33 MB of it unit rows).
- Untracked probe: packages/std-avrac/src/compiler/tests/probe_test.av (delete before any commit).
