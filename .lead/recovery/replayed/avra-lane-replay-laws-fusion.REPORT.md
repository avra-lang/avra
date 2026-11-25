# Replay: laws-fusion names series (3fd505bf..5c64da96, 20 commits)

Branch `avra-lane-replay-laws-fusion` in `/work/out/avra-lane-replay-laws-fusion.bundle`. The one
prerequisite is **3fd505bf**, the held ref `refs/lanes/laws-fusion/b59`. An e2bce925.. bundle would
need 30 prerequisite refs from merged lanes, so I cut it at the held ref. The tree is clean at the
tip: there was no uncommitted work, so there is no `-wip` branch.

Method: I took all 541 Bash commands from transcript line 14600 on and replayed every
tree-changing one in order, in /work/avra. Each replayed command's output was diffed against the
lane's recorded output. There were no Write/Edit tool calls in this range, and the Bash commands are
byte-identical in `/work/in/full/`.

## Commits

| # | original | new | subject | verified against |
|---|---|---|---|---|
| 1 | 994b8d20 | aa61aa54 | names: every scope-keying name is an interned Name | every iter count (344 refusals in 37 files at iter 1 … 0 at iter 13), every fixer.py tally, the 122-file +537/−434 checkpoint and the 131-files fmt; outputs identical except where the transcript cut them |
| 2 | 142bfa02 | 8240b630 | program layer: a tape interns each of its texts once… | `git diff --shortstat 3fd505bf` = 133 files, +642/−491 (exact); syntax_tape_test 24/24 |
| 3 | 08fc10dd | a29077f6 | scope: the names a file's siblings keep apart are read by name | kept_by_name grep lines; split from the amend as the lane did |
| 4 | e320dacb | 69ee5063 | names: a name's identity folds the hash its text was minted under… | edit outputs, syntax_tape tests |
| 5 | 70d9815f | 6d4697b9 | resolve: a scope keys a binder by its name and its origin, two ints | iter R1 (1 refusal) and R2 identical; stat 6 files +148/−88 (exact) |
| 6 | 0375260b | 0376d4c8 | tests: the tests that build nodes by hand mint their names | chk-shape error list, testfix output, `git diff --name-only` list identical |
| 7 | d509854f | 3ee50421 | names: a name's print is its text's fold, made once a name | `git diff --cached --stat` = 4 files +66/−24 (exact) |
| 8 | f54a8eb3 | 46ec9e1d | names: the hot reads of a name read its text once… | iter P2 (3 refusals) and P3 identical; `git diff` of nodes.av identical |
| 9 | 1db890bd | e4541dec | names: the batch's new tables allocate what they keep… | edit outputs and iters identical |
| 10 | a0e26c6f | 6ccb91b1 | program layer: every reading of a tape shares one list of name slots | edit outputs identical |
| 11 | b23b94a9 | c5cfe614 | names: a name's print is the hash its table finds it by… | iters C1–C5 identical (C2: 1 refusal, as recorded) |
| 12 | 564fe411 | cabed05e | names: the names' table hashes by its probe hash again… | `git checkout a0e26c6f -- names.av`, mapped to 6ccb91b1 |
| 13 | 1fdb4a0e | 0a10355a | store: a settle keeps a bare name's identity unless… | tests 24/24, 27/27, 30/30, 4/4 as recorded |
| 14 | a125077d | 3ae2a09d | program layer: a tape's reading takes its number when it is made | same command as 13 |
| 15 | 14c9ebe9 | 1eeee404 | program layer: an interned table's hash and equality are plain fields | interned test and iter D3 identical |
| 16 | 040f25a5 | 80779c4d | store: a settle reads where replacements begin once… | settle and nodes tests as recorded |
| 17 | af6b96ca | 7e8106cc | store: a settle reads the arena's rewrite floor where it asks… | revert of 16 (mapped to 80779c4d), then the amend; 1 file +12/−19 (exact) |
| 18 | 4b4eb812 | 189eca9a | program layer: a tape's reading reads a name's text only to mint it | tape tests as recorded |
| 19 | 1952c34a | b20382d8 | names: a name's text is two reads, a rebuilt name unchanged is the same name | tests as recorded |
| 20 | 5c64da96 | 3a9e5ac8 | bound calls: a type parameter's lookup asks the fn's parameters before the node | iter D7 identical |

The SHAs differ only because the commit dates differ. The messages and authors are the lane's.

## UNCERTAIN, and what stood in
- **Builders.** The lane's per-step gen-2 compilers (SD2, SF2, SG2, SJ2…SQ2, B572) came from cost runs
  I skipped. As stand-ins I used compilers built from the same series here: N1g2 for SD2/SF2, and the
  gen-1 of the 70d9815f tree for SG2 and the later ones. They were used only for `fmt` and as iter
  builders. Every iter refusal count and every fmt tally matched the lane's, so no edit depended on
  the swap.
- **The fmt hang at 16007/16062.** The lane's whole-tree `fmt --write` hung, was killed, and a per-file
  pass timed out on every file. Here the same fmt finished in 7 s and wrote one file. The result equals
  the lane's own checkpoint (16132: 122 files, +537/−434), so the end state is the same.
- **The first revert (29116).** It failed in the lane for lack of a git identity and was retried at
  29146, so I replayed only the retry.
- **Iter 1.** My first run gave 423 refusals: the `.avra-cache` dirs were stale from a failed seed
  build. Once I cleared them it gave the lane's 344. Every later iter matched without clearing.

## Compiler chain
/opt/avra-tc → a73903d2 (b56) → a73903d2 again (b56 gen-2) → 6abff86d (b57) → 3fd505bf ×2 (= F32).
Each step was `make avra`, with no manifest edit.

## Receipts (head 3a9e5ac8)
- Gen-1 (`make avra` with F32) and gen-2 (`make avra` with gen-1) both build: 101,045,800 bytes each.
- `WITNESS_ONLY="check lawed" sh tools/witness_program_edit.sh <gen-2>` exits 0 with 5 rows, as at the lane's 5c64da96:
  no-op == cold; held-only fn edited, warm == cold; instance-check fn edited, judged again (2), warm == cold;
  a refused item edit and its take-back, warm == cold.
- gen-2 `avra test`:
  - interned_test 19/19
  - syntax_tape_test 24/24
  - tape_derive_test 27/27
  - nodes_test 30/30
  - settle_watermark_test 4/4
  - shape_test 11/11
- I did not run the cost slice, the full gate or the release cmp, per the brief; the controller gates on GitHub.
- Sweep at the tip: the lane's 16835 regex finds 14 `text() ==`/`!=` lines outside tests. At that step the lane's
  own run found 19 (non-name strings such as `r.from.text()`). I did not check the lane's count at its final head.
