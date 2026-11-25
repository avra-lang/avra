# HANDOFF: avra-lane-laws-fusion

## Lane and scope
Lane `avra-lane-laws-fusion`, working for the Lead (controller) over claude-bridge. It started by
fusing the program layer's laws into one driver (NodeKind `on`, `judge(view, at)`, findings
identical, warm == cold). Since then it has been a series of CPU cuts in the program layer,
laws, parse and store. Every cut ships with receipts: findings cmp-identical (cli, std-avrac,
std-program), the `--release` cli product cmp-identical, and gate slices. Bundles go to the
Lead as `<batch>..avra-lane-laws-fusion`.

Rules from LANE_BRIEF: no `rm` (use `find ... -delete`), no `git stash`, no `reset --hard`,
no `--no-verify`, never push, one heavy build at a time. Run `build/avra-try fmt --write`
on touched .av files. Keep both sides of a conflict unless the block is a match-arm list.
Post to the Lead only at a bundle, a blocker or a ruling, in 12 lines or fewer.

## Base
batch55 = 912fc732, the newest batch I hold (its prerequisite is d750dfa7). The repo is
/work/avra, checked out on branch `small-cuts`; `avra-lane-laws-fusion` points at the same
commit.

## Commits ahead of batch55 (first-parent)
- 0841555f WIP (UNBUILT): the kids walk pushes onto the walk's own stack, with no list per
  node (see In flight).
- ce2fc78e Merge of batch55: each law family is a fn on the item's view, guarded by
  `item_held`. 18 conflicts, all resolved the same way: my view wrapper plus the warm lane's
  `item_held` guard. GATED, see below.
- bad4862c Merge of batch53 (conflict in law_findings.av: kept the pinned view and batch53's
  `unread`).
- 71df5b17 std-program names.av: `Name = { id }` is a dense per-process id, saved and folded
  as its TEXT. Tests names_minted_first and names_minted_last mint in opposite orders and
  print the same saved hash and key.
- 437ac954 share_merge_attack asserts the property: under `AVRA_QTRACE` the store says
  "share K of N published" and "an answer read from a share". The pack count is no longer
  read.
- 629e7cb3 Fold: 17 per-item law families held as Cells on ItemView. `pinned_while` keeps
  the judged item's view from being evicted, and `file_found_by` serves the four file checks.
- 1a4ba48a Small cuts: body_ungiven and unmet_in guards, TapeReader.count fast path, kids
  named in one list literal.
1a4ba48a..437ac954 went out as bundle 7. batch53..bad4862c went out for batch 54.
**ce2fc78e (the batch55 merge) has NOT been sent yet.** It is ready: the Lead asked for
`batch55..HEAD`.

## Receipts for ce2fc78e (the batch55 merge)
- Findings, cold, on the tree /work/fixed55 (batch55): cmp-identical for std-program,
  std-avrac and cli, comparing build/avra-b55 with build/avra-m55. User CPU: cli 92.7 →
  83.2 s, std-avrac 127.4 → 111.4 s.
- Warm edit (/work/handoff/bin/warm55.sh, a literal edited in cli's cache.av): 22 answers
  worked out with b55 and 22 with m55. Warm findings identical.
- Gate (/work/out/gate-chain.log): seed, idioms-avrac (base 912fc732), program, witness-b
  (20 rows) and edit-a..g all PASS. refusal and avrac slices were not re-run after the
  batch55 merge; they PASSed on bad4862c.
- Not yet done for the merge: the `--release` product cmp (/work/handoff/bin/rel.sh,
  adjusted to /work/fixed55).

## In flight
- Kids walk, direct call (0841555f, WIP, unbuilt): the Matchable derive
  (core/shape_derive.av) generates `kids_pushed_{expr,stmt,pat}(node, mut onto: List<At>) -> int`.
  `SyntaxArena.kids_pushed` and `kids_walked_pushed` live in core/shape.av. `places_under`
  reverses the pushed segment, and `walk_under` in compiler/item_view.av uses one shared stack.
  The first build failed for two reasons, both fixed in the commit but not rebuilt: `Stmts` was
  not imported, and `for _ in` is refused. Next: `AVRA_PROGRAM=1 make try`, then confirm
  findings are identical and that census boxes at kids_expr/kids_stmt (15.2 M) fall. The alloc
  lane is making `At` a 2-word value; the Lead asked for a direct call, not a callback (done).
- Interned names migration: names.av exists, but nothing uses it yet.

## Next 3, in order
1. Send `batch55..avra-lane-laws-fusion` (ce2fc78e; drop or include the WIP commit by
   asking the Lead) with a .md. Optionally run the rel.sh product cmp first.
2. Build and measure the kids walk (above). Then run `AVRA_ALIAS_LOG=1` once and post the
   top 3 box_clone sites (an open ask from the Lead).
3. Migrate to Name by census rank. The streq sites are in /work/handoff/streq-sites.txt;
   resolve each address with addr2line against a census build (bin/census-parts.sh). Lead
   rule: every hash or fingerprint of a Name hashes its TEXT, never its id. Wait for the warm
   lane's `file_declares_named` before touching declaring_item.
After that, per the Lead: the grammar executor's matching recursion (match_seq/alt/prim,
9.2 s of item_tape's 15.5 s) is the next parse target.

## Open rulings and asks
- Lead: is the WIP kids-walk commit acceptable inside the next bundle, or should it go
  separately?
- Lead (earlier ask, still owed): the top 3 box_clone sites from an `AVRA_ALIAS_LOG=1` run.
- Lead noted that witness-b flow-trace flakes on the first run after a compiler swap (the
  b6 compiler fails it too). I reported it; nobody owns it yet.
- Bisect answer (given): the law_findings/item_unknown_types doubling was resolve-2's
  family, not this lane's.

## Trip hazards
- Compilers kept in /work/avra/build: avra-b55 (batch55), avra-m55 (the merge ce2fc78e),
  avra-b53, avra-m53, avra-b6, avra-f3/f4/f5. `build/avra-try` holds the last build.
- Fixed trees for findings: /work/fixed55 (batch55 worktree, compilers in its build/),
  /work/fixed53, and /work/fixed (batch45c, too old for the current compilers' std tests).
  Scripts are in /work/handoff/bin (originals in /work/bin): findings55.sh, qt53.sh, qt.sh,
  rel.sh, warm55.sh, gate-chain.sh, census-parts.sh/.py.
- gate-chain.sh runs in /work/gate-wt (a detached worktree; check out the commit to gate
  first). Its idioms base is set inside by `echo <sha>`, currently 912fc732. It writes
  /work/out/gate-chain.log.
- Running as root fails std-program's frontier_adversarial "a store that can't write" (root
  writes any directory). The gate pins that case out, so use the gate's `program` slice and
  not a bare `avra test packages/std-program`.
- `avra run` on one file compiles the whole package. Dir tests (`tests/<n>/<n>.av` +
  `.expected`) run with `build/avra-try test <dir>`.
- `AVRA_STORE_KEPT_HERE=1` (set by tools/lib/attack.sh) saves in-process. Without it, an
  heir saves after exit, so packs counted right after a build can still change.
- The checkout branch is `small-cuts`, but the lane branch is `avra-lane-laws-fusion`. After
  committing, move it with `git branch -f avra-lane-laws-fusion HEAD`.
- Measurement files: qt-*.err are AVRA_QUERY_TIMES output (B531 = batch53 compiler, M531 =
  merge); warm-*.err are the warm counts.
