# db-inputs-2 handoff (2026-10-08)

Worktree: /Users/tristan/projects/tristanMatthias/avra-db-inputs (Sprite avra-phase-c — slow/wedged, lead says leave it; work on the Mac).

## Branches
- db-inputs-d2 @ e1fa559 (pushed, force-with-lease) = PR #411. 3 commits on origin/main 70e45d5 (#433):
  490f38b d2 (tools as inputs), 8c74283 "wip: review 411", e1fa559 "wip: rebase drift". SQUASH to one commit before landing
  (`git reset --soft $(git merge-base HEAD origin/main)` — NEVER `reset --soft origin/main` after a fetch moved it; that reverted 35 files once).
- db-link-holes @ 5892c4a (pushed) = .250 (unset `${VAR}` inside a [link] word refused). Green; PR state: ask lead.
- db-sound-key = .249, MERGED as #407. db-inputs-d1 = #395 MERGED. db-inputs-c2b = #380 MERGED.

## #411 review fixes (all in 8c74283, + e1fa559 test_workspace drift)
- MUST1: told() null for [] and untold; tools row kept only when told != null; tests "no tools never reuses", "untold then [] never reuses".
- MUST2: Toolchain doc = "driver of each tool it runs"; filed .257 (stamp real linker/sysroot).
- (a) dev page_at/page_of(lister, …) uses the session workspace (dev_test too). (c) tools row = Read.Tool digest keys.
- Filed .258 (ran() hand-mints Tool), .259 (real disk_tool/stat test).

## build/avra (Mac)
= d2's product built at 70e45d5-rebase by `make avra` (exit 0, 0 errors), builder was a copy of ../avra-fast-loop/build/avra (built from #433).
build/avra.pre = old Oct-6 binary (too old for the tree; ignore). Main checkout's build/avra (5b6ba32) is TOO OLD (refuses `@declares` Marker).
`make bootstrap` on Mac failed before #433 (seed section `avra_sites`); #433 fixes it — bootstrap should work now.

## Verified
- Pre-rebase (on 351e054 base, Sprite): earlier full targeted set green incl. witness (tool check removed -> build_tools 2/4 fail).
- After review fixes + rebase: ONLY that `make avra` builds. Tests NOT yet run on the rebased tree.

## Exact next step
1. On the Mac: targeted tests with build/avra (std-avrac: input_door, world, cache_walk, build_mode, compiler_print,
   compiler_print_adversarial, store_sweep_liveness, source_stamp_adversarial, workspace; cli: build_tools (6 cases), dev, explain),
   then `sh tools/gate_changed.sh --files <d2 .av files> --packages packages/std-avrac packages/cli --no-keepers`.
   (tools/proof_tmp.sh has the loop; it is untracked scratch — don't commit it.)
2. Squash (see trap above), push --force-with-lease, send lead the tip; lead requeues #411.
3. .258 fold-in (if lead wants it in #411): replace shared.av `ran()` hand-minted Tool with a @std/process door that mints from a resolved path.

## Traps
- `./avra` takes the machine lock for package-scale runs; nodes/fast-loop also build on this Mac — check ps first, one heavy build at a time.
- Tests of std-avrac now build workspaces with `test_workspace(host, root)` (#394), not new_workspace/avra().
- docs/DIAGNOSTICS.md is generated (`./avra diagnostics`) — a new diagnostic kind needs its entry AND the header count.
- `// LICENSED input.<why>` collides with the idioms license check (ticket .243) — don't use it.
