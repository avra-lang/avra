# db-gather status

PR #869 (db-07k-judge, base main; behind, watcher refreshes): K1 K2 K3 K4a-d on the branch, head 11fcd88d.
- K1 judge by stored stamps: judge_fallbacks 0 on a body edit
- K3 names digest off producer row: first kept verdict 246 -> ~3 ms (body edit)
- K4a-c narrowed names judged by what moved: interface edit 674 -> 60 ms, lookups 56k -> ~700 (spell_lookups gated at 0 for edit/unchanged)
- K4d file rows judged by moved plain fns (frame vs forms digests): interface-edit judge_fallbacks 420 -> 4
- AVRA_DB_VERIFY=producers,filesaid now compares cheap vs by-view for every row; attacks a/b, core, producers_test, idioms green
Interface edit vs body edit (Sprite, check packages/cli): lower ~800 vs ~444 ms, keep ~690 vs ~500 ms.
- keep: const_units +165 ms from keep_interfaces' blanket KeyParts cache clear (goes with K5)
- lower: flat perf diff is diffuse (streq, rc, memmove +1% each): no single hotspot
Next: K5 plan (delete KeyParts; (file,name) relation in @std/relation also replaces tokens_of). Awaiting lead's call.

## 2026-10-18 update
- #869 merged; #969 (K5a: views, index, bytes key on producer rows) open, head 3574c7e2. KeyParts 440-490 -> 140-160 ms/edit.
- all_said: the 344 ms is rule_findings on the edited file (1568 nodes, 29259 rule runs of ~12 us; ~19 any_root rules per node).
- export-const edit: 64 re-reads trace to shared.av's file outline (includes every const's full syntax) failing kept const verdicts; fix = outline carries const type not value + unspelled consts join narrowed names; soundness question open with lead.
- K5b as written (text-only object key) conflicts with content-addressed obj/<okey>.o and the link key; proposed closing K5 at K5a. Awaiting lead.
- NEXT RULES ITEM after K5b: compile the rule table into one dispatch over the node kind (most any_root rules begin with a node-kind test) to cut the 29k runs to a few thousand; per-declaration findings cache rides DB 07.

## 2026-10-19 update
- #969 head d8ff4a10 (const edit 14 s -> ~4 s, held 468 -> 531/533); local c8a5ad70 (cold build keeps unit rows: store +17 MB, first edit lower 970 -> 640 ms) goes with #1008's rebuild.
- CHAIN PEAK: core's 137 (OOM) at the end of the cache-attacks chain seen 3 times (a,b under VERIFY, then core); core alone peaks 1.9 GB. The chain's peak is near the Sprite's limit; not chased.
- Body edit `lower` (~640 ms) is `union` ~480 ms: drained 134 (unit_of 19, kept_instance 58, 1480 held stubs ~55), code_hashes 350 (graph 36, hashing 49 asked targets over 3361 fact sets ~292). Held stubs mint nothing (probed). The 314 minted files per edit are not from stubs.
- Open: per-target code hash reuse when no reachable symbol was lowered fresh (DB 05b shape); rules walk per statement (344 ms, keep); Typed/ConstTyped per declaration (codec, db-externs).
- Code hashing: the "fn values by type" hub (plus ordinary call chains) makes 26,011 of 31,545 graph nodes reachable from the 49 asked targets (~292 ms, ~11 us a node). Precision (a narrower fn-value over-approximation), not caching, is the lever; a persisted per-symbol table would save ~160 ms of ~3.3 s. Deferred.
- Cold timing 4d82ad00 (check packages/cli, store cleared, 2 runs each, idle Sprite): without (d8ff4a10) analyze 35.9/39.5 lower 24.7/25.3 keep 17.0/17.2; with analyze 30.4/30.4 lower 26.3/26.5 keep 19.8/18.0. Rows cost lower+keep ~+3 s of ~42 s; analyze varies +-6 s run to run (sublang 4 vs 8 s) and dominates.
