# Handoff: lane avra-lane-alloc

Written 2026-11-19, at the cloud-budget cutover.

## Lane and scope

Allocation lane: cutting boxes, retains and releases in emitted code. Census counts are the receipt; wall time is too noisy to count.

- Landed: packed lists of scalars (batch 48); the strided rung (batch 52, as 1e0d5d1c).
- Now: the strided lowering for batch 54, then wide value enums (`At` as a word pair).
- Queued: the nullable flat record, (2).

Standing rules, from the Lead:
- Commit as you go. Push nowhere.
- No `rm` (use `find -delete`), no `git stash`, no `reset --hard`, no `--no-verify`.
- Run fmt on touched .av files.
- Comments are evergreen.
- One heavy job at a time.
- New items get a design post first.
- Receipts:
  - census on the same sources;
  - findings identical;
  - witness_program_refusal 0 failing;
  - idioms 0 NEW;
  - gate slices with no unpinned failure.
- Bundle as `<base>..HEAD`.

## Base

**batch53**: `d5062c32` (from /work/batch53.bundle, prerequisite d750dfa7).

## Branches in lane.bundle (`git bundle create … alloc54 pack-fix wide54 ^batch53`)

### `alloc54` = batch53 + 3: the batch-54 bundle, receipts done

| sha | what |
|---|---|
| f994d797 | lists: a list of flat records of scalars lays each element's words in place (strided lowering; was 9cb4555df on 51) |
| 3e41a85b | make: a census stands on the objects its compiler links (was 877621026) |
| b6381f9a | runtime: a wide value enum's tagged box. Rung: `avra_enum_boxed2`, `avra_enum_word_at` (Unhosted), `Takes.CountedWords`, enum_wide_test.c. It also regenerates features/rt.av: batch53 itself fails `make rt-ns`, because 9f87c4b9 gave `avra_ctx_reframed` a third seat without a refresh. |

Receipts on b6381f9a, all on batch53's sources:

- **Fixpoint.** keep-b53g2 builds h1, then h2 == h3 (`659767606c93`). rt-header and rt-ns pass (280 rows). runtime-tests rc=0. runtime_counts 5/5.
- **Census**, `build packages/cli`:
  - boxes 1226.16M → 1211.80M (−14.36M, all list boxes);
  - releases 4486.73M → 4471.95M (−14.78M);
  - peak 3792 → 3791 MB.
  - Summaries are in measure/.
- **Findings**: identical, cold, for std-avrac, std-program and cli.
- **Witness**: 978/1012 hold, 34 known, 0 failing.
- **Idioms**: idioms-avrac, idioms and idioms-cli vs batch53, all PASS.
- **Gate** on a fresh pack: pack, program, build, avrac-a through avrac-g, and cli all PASS (cli finished after cutover: rows=1 failed=0).
  - The first pack was stale (see pack-fix) and turned avrac-a red with a link error. The rerun on a fresh pack is the receipt.
- **Not yet sent.** The Lead asked for batch53..HEAD for batch 54, with the pack fix included. So the bundle to send is alloc54 + pack-fix's commit, once the pack witness runs (next item 1); every receipt for alloc54 itself is in.

### `pack-fix` = alloc54 + 1

| sha | what |
|---|---|
| 7b11f4d8 | gate: a pack stands on the objects it ships. `gate.sh pack`/`seed` run `make objects` as a row before tarring. The Lead asked for it in this bundle. |

The witness has **NOT** been run yet; its commit message says so. The script is scripts/packwit.sh: it runs the unfixed gate.sh from alloc54, then the fixed one, after the checkout switch. Expect the packed archive to lack `avra_enum_boxed2` before and hold it after. Once it does, put the result in the message ("Witnessed: …"). It needs a worktree on pack-fix: /work/rung-wide was one.

### `wide54` = alloc54 + 1 WIP: the wide-enum layout, unbuilt and untested

| sha | what |
|---|---|
| 1c21e812 | WIP (not for landing): wide value enums |

The design was approved by the Lead: the **general** rule, not a special case for `At`. What it does:

- A value enum carries its tag plus up to `MOST_VALUED_WORDS` = 2 words in registers, with one counted mask per word.
- A list of one with every mask 0 strides at 1 + words.
- One-word enums keep the exact code they have today (the same rows, a mask-0 call).

Done in the WIP:

- `Layout.Tagged(counted: List<int>)`, `tag_masks()`, `slots()`.
- The program-path law in core/layout.av (`enum_declared`, `payload_word`, `word_or_none`).
- The old-path law in features/decls.av `laid_out`, plus core/types.av (`RepRow.counted: List<int>`, `counted_mask` → List, `slot_width`).
- crossing.av (`enum_boxed2` / `enum_word_at`), boxed.av (push_leaf, leaf_written, tagged_value, payload_at `1 + k`, unboxed_at), strided.av (`layout_stride` + `stride_parts`), calls.av `packs`, lowering.av `spare_tagged`, static_data.av, item_consts.av, item_const_json.av.
- llvm.av aggregate width; llvm_emit (`tag_masks`, absent_valued zero-fills every word, counted_by_tag loops over words).
- Interp arms EnumBoxed2/EnumWordAt and the RtHost variants; runtime_api hosts.
- Old path: values.av, emit.av (`enum_crossing`, unboxed), statics.av.
- docs/ZERO_COST.md: a technique row giving the census reason for 2, and a classifier row.
- Test: features/enums/tests/wide_value_enums/{.av,.expected}. Its expected output was computed by hand; check it.
- fmt was run.

Not done:

- Build g1 with keep-h2, then g2 with g1. g2 is where the compiler's own code (`At`, and every 2-payload enum) goes wide.
- The fixpoint.
- The test run.
- Receipts:
  - census against laws-fusion's remaining `List<At>` sites (below);
  - findings, witness, idioms, gate;
  - plus a cold+warm stress run, since an ABI-wide layout change is exactly the class of change that hid step 0's miscompile.

Then squash it into a real commit message.

## Next 3, in order

1. Run the pack-fix witness and amend 7b11f4d8's message with the result. Send `batch53..pack-fix` (4 commits) as the batch-54 bundle via send_files, with the receipts above.
2. Build `wide54` (rebased onto pack-fix): g1, g2, g3 fixpoint. Run the wide_value_enums test. Then the full receipts.
3. Then (2), the nullable flat record as Maybe(Fields). It waits for parallel-main's aggregate rewrite, which is now IN batch 53 (323fe0a1), so it may be unblocked; ask the Lead. Acceptance is in nullable-pair-step0.md, "What (2) must carry".

## Open rulings and asks

- laws-fusion, via the Lead. Sites still building a `List<At>`:
  - SyntaxArena.kids_at / kids_walked / places_under (core/shape.av:146,162,172);
  - kids_arms / kids_of_arm / kids_view (shape.av:475-498);
  - sugars.under (sugars.av:204);
  - ItemView.nodes_on (item_view.av:116);
  - shape holes.
  Their planned walk is a direct call (`kid_count`, `kid_at -> At`). We may take the shape.av sites if we land first. Measure the census delta against those.
- Reported to the Lead, not ours to fix: batch53's rt.av was stale (ctx lane, 9f87c4b9). Regenerated in b6381f9a.
- RecordedRead by frame moved to the warm lane. The release cascade moved to parallel-main.

## What a fresh session will trip on

- **Environment.**
  - `. /etc/profile.d/avra.sh` first.
  - `AVRA_STORE_KEPT_HERE=1` for builds.
  - The stable check settings are `AVRA_WORK_AHEAD_OFF=1 AVRA_SCHED_SEED=0`.
- **Building.** `make avra` builds with whatever binary is in build/avra; copy a kept binary there first.
- **Kept binaries** in /work/cut45/build:
  - keep-b53g2: batch53's compiler, fixpoint, builder for HEAD;
  - keep-h2 / keep-h3: alloc54 b6381f9a's compiler;
  - keep-h1-stale: built before the rt.av refresh; do not use;
  - keep-census-b53 / keep-census-a54: census compilers;
  - keep-t3: strided on batch51;
  - keep-b51, keep-w1: older.
- **Branch switches** retire objects through tools/stamps.sh. Run `make build/llvm_wrapper.o build/ffi.o build/libavra_runtime.a` after any checkout before linking or packing. batch53 lacks the Makefile census fix, so a census on a batch53 checkout fails on a missing ffi.o unless you make it first.
- **Gate packs** made before pack-fix can carry a stale libavra_runtime.a. Delete build/gate/compiler-*.tar.gz and reseed after `make objects`.
- **Census recipe** (scripts/rec54.sh):
  1. Base: the batch's census compiler via `make census CMD="build packages/cli"` on the base checkout.
  2. Head: a census compiler built on HEAD, run over the BASE sources with `sh tools/memcap.sh 60000 <census-bin> build packages/cli` and `AVRA_PROGRAM_NET=0 AVRA_WORK_AHEAD_OFF=1 AVRA_CENSUS_TOP=400 AVRA_MEM_STATS=1`.
  3. Compare the `rc:`, `alloc:` and `mem: peak` lines.
- **rt.av / avra_rt.h are generated.** The change that adds rows owns the refresh: `./avra runtime-namespace > packages/std-avrac/src/features/rt.av`, `./avra runtime-header > runtime/avra_rt.h`, using a compiler built from the tree that has the rows.
- **Worktrees.** /work/cut45 (on alloc54; the gate's build/ is there) and /work/rung-wide (on wide54; its build/ is stale, from a9c423447).
- **Scratch.** Scripts and logs lived under /tmp/claude-0/.../scratchpad/we/. The ones a successor needs are copied to handoff/scripts and handoff/measure.
- **Lambda syntax** needs parentheses: `(w) -> …`. `it.any(w -> …)` is a parse error.
