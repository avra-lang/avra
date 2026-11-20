# The flip, with the old check as a net (branch avra-lane-flip, on next-base c6adf93c; NOT landed)

## One place chooses (packages/cli/src/commands/shared.av)
- `program_door()` = `AVRA_PROGRAM != "0"`: the program layer by default; `AVRA_PROGRAM=0` = old path.
- `program_net()` = door && `AVRA_PROGRAM_NET != "0"`: the net is ON by default.
- NET: the old path judges first, in a process of its own (`answered_apart`), so its memory leaves
  with it (in-process it deadlocked the build's forked workers on the memory pool). What it judges
  (`NetJudge`):
  - build/run: what the old BUILD reads. `Workspace.judged_for_build(entry)` = the Want.Binary
    derivation's hold/admit/analyse, plus the entry's law (`Program.outside_entry`, the same rule
    files_checked reads), and nothing lowered.
    An acceptance is kept as a verdict under `build-judged:<entry>` (keep_check_verdict, reading every
    source of the closure), so a warm build answers from it; a refusal is never kept.
  - check: the old `check` (the whole package, as its entry sees it), as today.
  - test: the old `check` of the package the path stands in, with no entry, because that is what the old
    test's suite reads. (An old check of a program-test FILE refuses on the entry law where the old test
    runs it.)
  A refusal prints in the old words, exit 1. A program-layer refusal of what the net accepted prints
  under "program-layer false refusal — the old path accepts this program, so what follows is a defect of
  the program layer:" and exits 1. A net that dies with no verdict is said, and the layer judges alone.
- A kept (warm) program-layer build says `time: lower+emit · cache hit` under --time, as the old path
  does (`build_stood`, the same test rebuilt_said reads).
- explain --why reads program_door. Nothing else reads AVRA_PROGRAM.

## Receipts on c6adf93c (the default opt level is now the old path's; scratchpad flip5/, flip6/)
- make try: exit 0. Fixed point: make avra #1 (pre-flip, old path), #2 (gen1: net + layer), #3 by gen2
  with the cli store emptied: gen2 == gen3 (e91298ff71efe9bc).
- cli build, cold (stores and machine cache emptied) / warm:
  net ON 256.7 s, 7.44 GB / 2.30 s;  net OFF 186.7 s, 7.42 GB / 0.31 s. The net costs ~70 s cold and
  ~2 s warm (its verdict's reads). Before the verdict, a warm build re-analysed: 55 s.
- doors witness: green (incl. W2's target and std-pin cases).
- cli spec suite: AVRA_PROGRAM=0 418/438 (28283568), no env 419/438 (c6adf93c). Same failing names, except
  kept_settle_test:164, which passes on the new path.
- Earlier (8cb5d1f6) the doors on std-text, std-relation and std-http: same, except std-http check's
  +1 dependency warning.

## W2 (wasm per target) and program_door
Nothing needed from program_door: the target is decided inside the program branch of built_binary
(toolchain_with), so it takes the net and the false-refusal header like any build. One fix rode the merge:
run.av sent every run to program_ran before looking at `--target`, so a wasm run built the module and
then tried to exec it natively. A `--target` run now goes to run_wasm_command first, which builds through
built_binary on whichever path the door chooses.

## cli spec suite on 28283568 (scratchpad suite4/)
- AVRA_PROGRAM=0 (parent and children old): 418/438.
- no env (parent and child `avra` flipped, net on): 419/438.
- The failing names are identical (19, the sandbox-env cases in explain*, explain_holds, explain_sites
  and sound_check_cache), except kept_settle_test:164: it fails on the old path and passes on the new.
- The program tests after the 438 specs never run on either path: the runner stops at the first failing
  stage, and the spec stage fails on both (the sandbox-env cases).

## Receipts to gate it on the Mac (run from the tree root, the branch checked out)
Empty every `.avra-cache` under packages/ and the machine cache before 3 and 4, so they are cold.
1. `make try` → exit 0. The standing compiler predates the flip, so this is an old-path build of the
   flipped tree.
2. Fixed point, no env: `make avra` three times; `cp build/avra /tmp/g2` after #2; then
   `find packages/cli/.avra-cache -delete` and `make avra` (#3, cold);
   `cmp build/avra /tmp/g2` → identical. #1 is the old path; #2 and #3 are net + program layer.
3. cli build, cold then warm, net on (no env) and off (`AVRA_PROGRAM_NET=0`):
   `build/avra build packages/cli` → exit 0 in all four; note the seconds.
   Linux reference (c6adf93c): on 257 s / 2.3 s, off 187 s / 0.31 s.
4. Every door, no env vs `AVRA_PROGRAM=0`, on std-text, std-relation, std-http:
   `build/avra {test,check,build,run} packages/<p>` → same exit and stdout. Known: std-http check +1
   coalesce_never warning in a dependency (the old path's print gap).
5. cli spec suite, no env, with `build/avra` the flipped compiler (the suite's children run ./avra):
   `build/avra test packages/cli` → the same passed count and the same failing names as
   `AVRA_PROGRAM=0 build/avra test packages/cli`.
6. `sh tools/witness_program_doors.sh build/avra` → green.
7. `sh tools/witness_program_refusal.sh build/avra` → the trunk count (its old side names AVRA_PROGRAM=0).
8. The net, by hand:
   - a lone file `fn f() -> int { "no" }` + `f()`, `build/avra build f.av` → the old check's words, exit 1;
   - `AVRA_PROGRAM_NET=0` on the same → the program layer's words.
   - A grep of every package build for "program-layer false refusal" → 0 lines.
9. CI pinned: `grep -n 'AVRA_PROGRAM: "0"' .github/workflows/{checks,lane-run,orders}.yml` → 3 lines.

## Places that assume the old default (land AFTER the net)
- Makefile: OLD_PATH_TARGETS (every wasm-*, ui-board, ui-browser) export AVRA_PROGRAM=0 until their
  witnesses hold on W2's program-layer wasm build.
  try/avra/compiler/test/suites/keepers follow the standing compiler's default.
- tools: the old side of each old-vs-new witness names AVRA_PROGRAM=0 (refusal, warnings, differential,
  body_consts). Every other witness names 0/1. The doors witness is green.
- .github/workflows checks.yml, lane-run.yml, orders.yml: `env: AVRA_PROGRAM: "0"` pins CI.
- pre-commit hook: fmt only, unaffected.
- Seed: `make seed` = `./avra emit`, which has no program door, so the seed is always emitted by the
  OLD path; its content is the flipped compiler. Bootstrap: gen-1 by the old path (pre-flip seed),
  gen-2 by net + program layer. seed-check: old path until a post-flip `make seed`, then net + layer.

## Order to land
1. This branch (default flipped, net on, CI pinned 0).
2. Unpin CI workflow by workflow (checks.yml last); watch for "program-layer false refusal".
3. `make seed` once CI is green unpinned.
4. AVRA_PROGRAM_NET=0 by default once false refusals stay at zero; then remove the net.
5. Retire OLD_PATH_TARGETS target by target as each wasm witness holds on the program layer.

## Roll back in one command
`export AVRA_PROGRAM=0` (old path everywhere, no commit), or `git revert` the flip commits.
