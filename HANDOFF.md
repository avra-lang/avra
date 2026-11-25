# HANDOFF — mem-hunt (avra-8sb5.119)

Goal: cold cli build peaks ~5.3 GB RSS; cause is the @saved families' process-wide `${f}_held` tables holding every answer to exit. Design: docs/2026_11_25_HELD_ANSWERS.md. Rules: no new AVRA_* env var, never trade warm for cold, no Mac compiler rebuilds, no rm/stash.

## S1 — DONE, awaiting gate
- lane/memhunt-s1 at a8ae0176c90ce333a4e6aa66af041e88b0bb71f2, on origin/program e02d71ab. Sha sent to lead for gating.
- peak_mb + decoded rows in tools/cost_ratchet.py, `answers_decoded` counter. Run 45568630032 green; 64 MB witness tripped build-cli peak_mb (3957 -> 4021).

## S3 — HALF-DONE (this branch, handoff/20261125-1144/mem-hunt; base d7cd84d9, NOT rebased onto e02d71ab)
- held_clock.av: CLOCK cache, HELD_BUDGET const 64 MB. Earlier result: cold memory halved, warm build +73% wall (working set > 64 MB, thrashes).
- Approved sweep: 64/256/1024 MB (sweep.sh). Run 45605454825 FAILED before measuring: ladder rung 1 did not build —
  `refused by @derive` at packages/std-program/src/tests/support/tiny_tree.av:85 (`export collect enum TinyNode = @tiny_node in package by it.name`). Likely a seed/base mismatch with this old base; undiagnosed.
- Next: rebase onto origin/program (e02d71ab), confirm the tree builds (`sh tools/work run "make avra"`), then
  `sh tools/work run --for 150 "bash sweep.sh"`. Report the knee table (cold/warm build rss+wall, warm check, decoded, check-warm sites) to the lead.
  If no fixed budget gives cold -50% with warm within noise, size the budget from the run itself (typed setting or one named constant, no env var).
- Scratch scripts committed here (sweep.sh, heldab.sh, memgens.sh, memhunt.sh, s1.sh, s3.sh, 1.sh, zz-measure.sh) are measurement tools, not for landing.
