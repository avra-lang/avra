# HANDOFF: lane alloc (avra-lane-replay-alloc), 2026-11-25

Repo worktree: /work/m-base (remote `gh` = https://github.com/avra-lang/avra.git, attached with push).
A second worktree, /work/lang, holds the older branches (alloc-one-spelling = fde64224, and the replay history).

## 1. Pushed and finished, not yet seen landed

- **`lane/alloc/lazy-link`** = 0d5f84b3 on gh/program e02d71ab.
  - Ticket avra-8sb5.59.29.7 (a): a package's `[link]` C is archived, so it rides only a program
    that reaches it.
  - The board's terminal mount goes from 2.79 MB of text to 1.23 MB, with no sqlite symbol.
  - Write-up: /work/out/lazy-link.md.
  - Tested on c9780be7's tree (6dbbbbb9): compiler byte-identical, footprint keeper clean (32
    self-test rules), std-sqlite/crud/io/process/time suites green, std-net same 6 sandbox failures
    as base.
  - The rebase onto e02d71ab was clean; NOT re-tested there.

## 2. Half-done: ONE ANNOTATION SPELLING, step 1, ported onto gh/program

Ticket: the newest under avra-8sb5.10 (one annotation spelling). Note: docs/2026_11_24_ONE_ANNOTATION_SPELLING.md.

- `wip-handoff` = step-1 commit 7a3b7612 (cherry-pick of 1e71626e onto gh/program e02d71ab) plus
  a WIP commit. Pushed as handoff/20261125-1144/alloc.
- Port done in the cherry-pick:
  - item_generators.av conflicts resolved to my side;
  - `resolved_in` → `stratum_resolved` in annotation_meant (item_annotations.av), derive_meta
    (item_meta.av) and trait_named (item_generators.av);
  - docs/DIAGNOSTICS.md and docs/VOICES.md taken from upstream (`--ours`) — THEY MUST BE REGENERATED.
- WIP commit: item_meta.av gets its own `const META_DERIVE`, because upstream added a second private
  `DERIVE` (item_signatures.av), which made the read ambiguous (`resolve.kept_apart`).
- Build state: gen-1 built (dc3ce2592d3a) with that fix. gen-2/gen-3 were running (background task
  bcuurek6x, `make avra` in /work/m-base, logs /work/sq/sp_g{2,3}.out). `make libs` failed earlier
  only because gen-1 had failed; rerun it.

Next commands (in /work/m-base, on wip-handoff):

    . /etc/profile.d/avra.sh; export AVRA_STORE_KEPT_HERE=1 AVRA_MEM_POOL_MB=12500
    make avra && make avra   # gen-2 == gen-3 fixpoint
    make libs
    ./avra diagnostics > build/D.gen   # write docs/DIAGNOSTICS.md from it
    ./avra voices --report > docs/VOICES.md
    ./avra test packages/std-avrac/src/features/annotations/tests/derive_by_word
    ./avra test packages/std-avrac/src/features/annotations/tests/annotations_test.av
    # also: std-validate tests; idioms (./build/avra check packages/std-avrac --baseline tools/idioms.baseline); cost
    # then squash the WIP into 7a3b7612 (keep the `Rung:` trailer) and push lane/alloc/one-spelling-step1

- Earlier receipts, on the de4e83ec base: fixpoint a9259f55b6dd; std-validate 22 files green;
  annotations 32/32; refusals 1170/1171; idioms clean; cost string_compares +0.013%.
- Pre-existing on that base: `type.component_named_head` has no witness (left out of the docs), and
  annotations_adversarial_test fails 5 of 77.

## 3. Queued after step 1 lands

- **Step 2, the sweep** (approved, FAST route):
  - Script /work/replay/sweep_apply.py: apply the `annotation.derive_spelled` spans `avra check`
    reports, one package at a time, std-avrac last.
  - Run `fix --repair` only on the small packages, then `avra fix --only modules.unused_import`.
  - Receipt: std-avrac's gen-2 hash is unchanged.
  - Plan: /work/out/sweep-plan.md.
- Step 3: retire `@derive`.
- After that:
  - the data-structure techniques (perfect hashing, roaring bitsets, Eytzinger), each a ZERO_COST.md row;
  - a "Techniques" section in the program design doc.

## 4. Closed / informational

- footprint RED: stood down. It's spec-harness's harness defect. Analysis is in /work/out/footprint-red.md.

## Open questions

- Should `@std/meta`'s `derive` stay declared after step 3 (seeds and old packages)? The note says yes
  until a later commit.

## Runs in flight

- bcuurek6x: `make avra` gen-2/3 in /work/m-base (step-1 port). Its result is in
  /tmp/claude-0/.../tasks/bcuurek6x.output and /work/sq/sp_g*.out.
