# HANDOFF — collections (pipeline) lane

## What I was doing
Driving epic `avra-8sb5.65.3` (S1 — pipeline, inline lambdas, ranges, core verbs).
Worktree: `/Users/tristan/projects/tristanMatthias/avra-collections-chains`
(HEAD detached, CLEAN — every landed commit is pushed+merged).

## Landed (all on main)
- `.3.1` Pipeline IR (#135)
- chains: adapters/terminals/aggregates/slice verbs (#161 #168 #184 #193 #201)
- `take/drop/take_while/drop_while/filter_map/flat_map/flatten` (#193 #201 + shape #204)
- `.3.3` inline lowering `can_inline`/`inlined` (#205) + `Step.Inline`/`step_of` wiring (#212)
- `.3.4` range: `Expr.Range` (#208), seed (#209), `Type.Range` (#213), receiver `head_of` + `on_walk` rows (#214), tests + core `element(.Range)=int` (#264)
- `.3.7` `find_last` (#229)
- `.3.8` `count/sum/min/max` (#184), `min_by/max_by` (#215)
- `.3.9` `removed_at`/`inserted` (#263)
- `.3.11` map insertion-order guarantee (#260)
- string lenses: WalkKind.Bytes/Codepoints, Source.elem, `chars`/`bytes` lowering (#210); Bytes half (#265, opened)
- maps (mapswalks): `has/keys/values` (#207), `remove/is_empty` (#211), `for k,v in m` (#266)

## Open / remaining (mine, not started)
- `.3.2.1` relation planner narrows method chains
- `.3.2.2` retire `bool_comprehension_*` rules
- `.3.5` `scan`, `chunks`, `windows`
- `.3.6` `distinct` (blocked: no `Set` type — own ticket)
- `.3.7` `index_of → int?`, `pop → T?` (migration, many sites)
- `.3.8` `fold` (2-param fn-seat typing)
- `.3.9` `partition`, `join` on `List<Bytes>`
- `.3.10` `entries()` — parked on core `Entry<K,V>` ticket `avra-8sb5.65.3.10.1`
- `.3.12` `T?` migration; `.3.14` renames (last, batched)
- **`avra-8sb5.65.3.13.1`** Codepoints emission bug (below) — unreachable on main because stringlenses split `chars` out of its PR.

## The one open bug — avra-8sb5.65.3.13.1
`s.chars()` LOWERING emits unbounded IR (build/run >2.5 GB, CI 6 GB); `check` is clean; List/Bytes kinds are fine; Codepoints only. `emit.av` `walk_width`/`walk_code`/`lead_width`/`lead_mark`/`byte_tail`/`between` read BOUNDED (~30 regions/head), so the true loop is not yet found — a blind edit is unsafe.
Fallback plan: move the codepoint step/decode behind a runtime row (`avra_str_codepoint_width`/`_at`) so `walk_step`/`walk_elem` become trivial calls (no unbounded IR).

## Lessons
- A dequeue → force-push → re-enqueue RACES the queue: #259's squash took the pre-push head, silently dropping the core `element(.Range)=int` change. Never dequeue+push a queued PR; open a new PR for the delta (deepwalks did, #264).
- Land in waves; one writer per file; batch 3–5 related verbs per PR — the queue is the wall.
- A branch-local compile (`prepare`) is the real proof; local seed checks are stale and hide cascades.

## Blockers at close
- Sprite pool saturated (every slot taken) — could not run the 13.1 repro.
- `entries` needs a built-in `Entry<K,V>` (core/types event).
- `distinct` needs a `Set` type.
