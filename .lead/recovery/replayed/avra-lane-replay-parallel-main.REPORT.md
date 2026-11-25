# Replay: parallel-main (transcript cse_01QBqJupZAzei2S1S6XXPJDN)

Branch `avra-lane-replay-parallel-main`, off the held ref `refs/lanes/parallel-main/walk-bounds` = adecf056.
Bundle: `/work/out/avra-lane-replay-parallel-main.bundle` (1 ref, tip fbde9f4e: the replayed commit plus one follow-up; prerequisites are the same 30 boundary commits as
all-lanes.bundle, every one an ancestor of e2bce925).

## Rebuilt commits

| original | new | subject | verified against | notes |
|---|---|---|---|---|
| 7f6419fa | 0f9bae25 | boxes: a slot the box's type proves is read with no bounds test | the transcript's `git diff --stat` after each edit (3 files 33+/6−; 5 files 53+/20−); fmt counts (6 examined/3 written; witness 1 written; lower_test 0 written); `git status` file list at commit (9 paths, identical); the three `grep -n` lines after the enums edit (identical line numbers 744/1014/1041); commit message byte-for-byte from the heredoc | none UNCERTAIN. All edits came from Bash heredocs; the full transcript has no Write or Edit calls in this window. The sha differs only in author/committer date. |

## Stop point / what was NOT lost
- The lane's last act was running receipts on 7f6419fa (the gate passed: avrac-a..g, edit-a..g). It hit its usage limit
  before doing anything more to the tree, so there is no `-wip` branch.
- **ZERO_COST candidate row for candidate 2 (the `&`-mask range rule): never written by the lane (now written in fbde9f4e).** The lead asked for it
  (02:22:17), and the lane said it would add it "as its own commit on top of 1, once the receipts free /work/avra".
  The receipts were still running when the lane stopped. It still needs doing; its content is in the lane's
  design post (transcript, 02:21:56): a masked `mut` cell whose every store is `x & (avra_array_len(L) - 1)`,
  the reads are `avra_array_get(L, load c)`, and a returning `is_empty(L)` region stands before them. A general
  value-range fact would subsume it.
- **Open follow-up the lane found and didn't fix (now fixed in fbde9f4e, below):** idioms reports 5 NEW sites from 7f6419fa.
  - `compiler.duplicated_message` ×2 in core/boxed.av: `payload_proven` repeats `payload_at`'s refusal text. The lane's
    plan was one body, with the read chosen by a flag.
  - `compiler.modified_copy_literal` ×3 in features/enums/lowers.av: `Chosen { …, region: s.region, tested: s.tested }`
    should be `s with { … }`.
  - So 7f6419fa alone fails the idioms baseline check.

## Follow-up (new work, at the lead's request)

| sha | subject | what |
|---|---|---|
| fbde9f4e | boxes: a payload's refusal named once, a chosen subject copied by `with` | the 5 NEW idioms sites: `payload_of_none()` names the refusal both readers say (2× duplicated_message); the three `Chosen { … region: s.region, tested: s.tested }` literals are now `s with { v, ty, variants }` (3× modified_copy_literal). ZERO_COST.md: the bounds-check row names box slots; a new `masked index range proof` candidate row, written from the 02:21:56 design (shape, ~0.2 s, detector: census guarded-read sites over a masked cell; a general value-range fact subsumes it) |

Receipts on fbde9f4e (head gen-1 → gen-2 by `make avra` twice, from 0f9bae25's gen-2):
- `make -o avra idioms`: exit 0, 0 NEW.
- payload_proven: eval == native == expected. lower_test: 69/69. Affected suites: 1632/1659, the same 27 failures as
  0f9bae25 and adecf056.
- **Cost slice** (`CENSUS_BUILDER=build/avra sh tools/cost.sh`, each tree's census compiler built by its own gen-2, base
  adecf056 first, then head; judged by the lane's cost_vs_base.py over cost_ratchet's judge):
  `cost: 55 rows, 0 over, 3 fell (head vs base, snapshot adecf056, tolerance 0.05%)`
  - build-cli string_compares 333473000 → 333292577 (−0.054%)
  - check-cli list_reads 13888774209 → 13887792835 (−0.007%)
  - cold-with-store-fill list_reads 14118348251 → 14117200452 (−0.008%)
  - Snapshot note: tools/cost.baseline pins a6d0d0a0, which this shallow clone lacks, so both runs used
    `COST_SNAPSHOT=adecf056`. The rows that fell were not accepted into tools/cost.baseline.

## Receipts (this replay)
- Compiler chain, per the lead: /opt/avra-tc avra → `make avra` at a73903d2 (b56) → 6abff86d (b57) → 0f9bae25 gen-1 →
  gen-2. Each step produced a distinct binary, with 0 errors in every step log. The b57 step did not hit the
  `@derive(Saved)` annotation cap here (no `written_into` errors), so the `[lifted] memory = 64` workaround wasn't
  applied. Env: AVRA_MEM_POOL_MB=12500 plus /etc/profile.d/avra.sh. gen-2's `build/.avra-built-from` names 0f9bae25.
- `features/enums/tests/payload_proven`: `eval == native == expected`. The expected line is the transcript's
  (`0,3,8,30,9,8 ?,n3,… 6 -1 18`).
- `compiler/tests/lower_test.av`: 69/69 (transcript: 69/69).
- The IR probe (two-variant switch, `f`): tag read and case payloads `avra_slot_get` ×3, the rest's arm `avra_array_get`
  ×2. This is line for line the transcript's output.
- Affected suites (enums, results, nullable, closures, tasks, loops/tests, lower_test): 1632/1659 on 0f9bae25 gen-2, against 1631/1658 on adecf056 built by `make avra` from that gen-2. Both have the same
  27 failures (diff empty); the extra test is the payload_proven witness. The transcript's own run was 1631/1658 with
  "new failures:" empty, measured before the witness was added.
- Not run, per the brief: cost slice, full gate, idioms.
