# HANDOFF: lane lowering-quality (2026-11-25 11:44)

## Goal now
ContentKey, ticket **avra-8sb5.103**: one 128-bit+length key for identity, `ContentKey`, minted at one door; NameKey folded in; then the TYPED law `identity.text_compare`, then the sweep.
- **Design:** /work/in/2026_11_24_CONTENT_KEY.md. Two parts are out of date:
  - `module_dir_files` was dropped from the final file key.
  - NameKey unification is this lane's.

## Pushed to GitHub (avra-lang/avra), each rebased onto gh/program e02d71ab
All were tested on d7cd84d9's tree (f9ccac32), not yet rebuilt on e02d71ab.

| branch | tip | what | status |
|---|---|---|---|
| `lane/lowering-quality/static-low` | 45882a34 | wasm `--global-base=65536` (link.av `DATA_BASE`): the bundled-image trap; spec + std-ui `asset_painted` | received, next train |
| `lane/lowering-quality/void-lambda` | 9e1830ec | avra-8sb5.114.10: a void lambda drops its tail, `{}` in a void seat is a block, ret type guard (llvm_emit) | received, next train |
| `lane/lowering-quality/content-key` | 41aaa0ef | a0e2e38e census `--identity` (step 1) + 41aaa0ef ContentKey/content_key/text_key, NameKey folded in | ck2 sent, not yet acked |
| `handoff/20261125-1144/lowering-quality` | (this) | = content-key + docs/handoff/lowering-quality.md | handoff |
| `scratch/push-test-lowering-quality` | e5ece5c0 | push test: **please delete** (sessions get a 403 on deletes) | |

Already landed in e02d71ab: quiet-call borrows (memory.av), runtime keepers (trap-marks / clock-holds).

## Done
- **ContentKey step 1 (census):** 418.4M text compares at 925 sites on snapshot 91ebc6c5. Full list: /work/out/avra-lane-replay-lowering-quality-ck1.identity.txt.
- **ContentKey step 2:**
  - `ContentKey{high,low,length}` is in std-program answer_record.av; `content_key` and `text_key` are in interned.av.
  - The names table interns `ContentKey`.
  - Tests: content_key_test 6/6, interned 19/19.
  - Cost vs parent: check-cli flat, laid ≤ +0.034%.

## Half-done
Nothing is uncommitted in the ContentKey work.
- **Not started:** `identity.text_compare`.
  - Groundwork read: a law is `export law {kind, on: [NodeKind.ExprBinary], judge: fn(ItemView, At)}` (compiler/laws/law.av); typed nodes come through `ItemView.typed_run()` (compiler/item_view.av).
- **Not in this lane's tree:** the file key (`SourceFileAddress.key`, the note's commit 1) isn't at e02d71ab/d7cd. Asked the Lead whose it is; no answer yet.
- **wt-w2** (an old lane at e9266ae9) has one modified file. It's from an earlier phase, not ContentKey; not looked at.

## Next
1. `cd /work/wt-ck && git checkout push/content-key`. It sits on gh/program e02d71ab; rebuild there first: `make avra` ×2 with a d7cd-era builder (/work/wt-img/build/avra.j2).
2. Write the law `identity.text_compare` in packages/std-avrac/src/compiler/ (a new item_identity_laws.av beside item_body_laws.av):
   - **Judges:** `ExprBinary` `==`/`!=`, both operand types `string`.
   - **Where:** the enclosing fn is `@query`/`@cut_query` or a law body.
   - **What:** an operand read from `SourceFileAddress` (file) or a name's text (names table / `DeclaredName`).
   - **Then:** voice, golden, witness.
3. Build it behind no gate, then run `avra check` over the tree and hand-classify every site to get the TP rate (that's the law's spec).
4. Then: the DOGFOODING entry, the baseline in tools/idioms.baseline, and the sweeps, each measured against its parent with tools/cost.sh `COST_PART="warm laid" COST_EDITS=99/99`.

## Open questions
- Who lands the file key (`SourceFileAddress.key`)?
- Is a package name an identity (its own key) or a label (licensed text compare)? The note says count file and name compares only until it is decided.
- The storyboard "pictured icon/image" pins for static-low weren't in d7cd's tree; the owning lane re-pins.

## Runs in flight
None.

## Environment notes
- **Pushing:** `gh` remote = https://github.com/avra-lang/avra.git. Push with `git -c push.negotiate=true push gh <br>:refs/heads/lane/lowering-quality/<what>` after a rebase onto gh/program.
- **Census:**
  - The pinned cost snapshot ea25dd42 isn't available here; use `COST_SNAPSHOT=91ebc6c5b`.
  - cost.sh refuses a builder whose record doesn't match the tree, so run the parent's census in its own worktree (see /work/replay/probes/ck2.sh).
- **Wasm builds:** with wasi-sdk 27, the SDK is in the scratchpad (sdk27/); with clang 22, set `CC` to a wrapper adding `--sysroot=/opt/wasi-sysroot`.
- **Disk:** fills fast. Clear `/tmp/avra-cost` and old build/cost-*, avra.census-* between runs.
