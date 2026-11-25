# Replay: wrong-answers (transcript cse_01QBqJuk1sDN2d7bA4Wx6k1D)

Bundle: `/work/out/avra-lane-replay-wrong-answers.bundle`. It holds one branch,
`refs/heads/avra-lane-replay-wrong-answers`, whose head is de30862e. It is built as
e2bce925..branch and verified: all 30 boundary prerequisites are ancestors of e2bce925.

Base: held `refs/lanes/wrong-answers/gate58` = 0182ab8c. The lane's worktree was
`/work/gate-wt`, recreated at that path.

## Rebuilt commits

| original | new | subject | verified against | notes |
|---|---|---|---|---|
| 1c43d309 | d09070b5 | cost: a warm edit's work as rows beside its answers, held stable across compilers before they count | The replayed edits' outputs matched the transcript's (self-test ok). `tools/cost_stable.sh` matches the full transcript's Write plus the lane's later comment edit, byte for byte. Same message. | The sha differs because the originals are SSH-signed with the lane's key, so no rebuilt sha can match. The same holds for every row. |
| 3bf8e534 | 21e3a4d4 | gate: a long slice is the parts of its own list; the seed ends at generation 2 with the census compiler | All 9 python edits (WLaZ75bM … t6Xw5U6k) give output identical to the transcript's. The cover check (witness-b 8/7/7/7 = 29; refusal 6 parts = 1093 cases) matches. The `gate.sh` lines 545–556 excerpt matches. `git status --short` before the commit matches (4 files). | |
| 31d8f58c | de30862e | gate: the seed takes the release as it stands where the compiler source is the release's; cli and program in finer parts | Edit vMKAHMg6 gives `ok`, as in the transcript. The `unpacked()` tail matches. `gate.sh list` gives 63 slices, as the transcript does. `cli_built on/off` sit at lines 254/255, as in the transcript. | The `gate.sh seed` run that was chained after the commit was not replayed; it is a measurement. |

There is no uncommitted work at the transcript's end: no source edit follows 31d8f58c, so there is
no `-wip` branch.

## Other lost items (text, not commits): `/work/out/avra-lane-replay-wrong-answers-files/`
- `sites57/sites58.sh` (2565 B) and `sites57/README.md` (1305 B) are taken from the heredocs in
  i8uqk2th and xzQsVdP6. Both byte sizes equal the transcript's `ls`. The data files (6abff86d.out,
  .made/.retain.byfn, the census binary) were measured output and are not reconstructable. The
  transcript shows the lead's upload of /work/sites57 succeeded (04:16, 6 files, 36 MB), so the lead
  may already hold them.
- `fixC-parked.txt` holds the three PROGRAM_DESIGN lines that park fix C. They are verbatim from
  the lane's message (line 19053). They were never a commit: the lead keeps PROGRAM_DESIGN in .lead.
- Sweep half B results: NOT rebuilt. The rerun with the revised kit (/work/sweep-share2) stood at
  302/1191 when the lane froze. results-B.tsv was never written whole, and the stopped first run's
  file was deleted on the lead's order. Rebuilding them means rerunning the 3 h sweep with that kit,
  which isn't in /work/in. It is a measurement, so it was not run.

## Receipts
- `python3 tools/cost_ratchet.py --self-test` gives `cost_ratchet self-test: ok`.
- `sh -n` passes for gate.sh, cost.sh, census_compiler.sh, cost_stable.sh and witness_program_edit.sh.
- `sh tools/gate.sh list | wc -l` gives 63.
- The pre-commit hook ran on all three commits and passed. `--no-verify` was never used.
- Compiler chain from /opt/avra-tc (e2bce925's binary), in /work/chain-wt, saved under /work/chain/:
  - a73903d2 `make avra`: ok in 1295 s, saved as avra.b56.
  - 6abff86d `make avra`: ok in 149 s, saved as avra.b57. It built clean from the first b56 with no
    manifest edit, so neither the [lifted] edit nor the twice-built b56 was needed.
  - de30862e `make avra` twice: ok in 138 s and 149 s, saved as avra.head.
  - /work/chain-wt has no changes.
- On the replayed branch, with avra.head as build/avra: `make try` passes in 132 s.
- Not run, by the brief: the cost slice, the full gate, and cost_stable.sh (about 50 min of
  measurement).
