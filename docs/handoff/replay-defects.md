# HANDOFF — lane replay-defects (2026-11-25)

## Goal
Replay/defects lane for the Avra compiler: fix compiler defects the Lead assigns, each with a golden
and a census where it moves cost; send finished work as pushed lane branches.

## Base
All pushed work is rebased onto gh/program e02d71abd (avra-lang/avra, branch `program`).

## Pushed, finished, NOT yet landed (avra-lang/avra, lane/replay-defects/*)
| branch | tip | what | tickets |
|---|---|---|---|
| type-exported-generated-privates | 5ecad5f1c17d | Rung: Type.exported + type_declared; type_exported answers exports only, relation <T>Stored/Key exported where T is; generated private names kept apart per file | avra-8sb5.114.9, avra-8sb5.114.8 |
| file-key | 245c95690d52 | ON TOP of the above: Saved @derived field; evaluator crosses each declaration once; derived trait `marks` only where marks written; SourceFileAddress key (lane-minted, @derived, @sealed, no new query) | file key (approved design) |
| component-setting | 8591b453b731 | setting refused as `setting x takes T, this is U` (type.component_setting) at the setting, also inside a component's own body; VOICES.md regenerated | UI seat P1 |
| zero-enum-name | a86ce81134ba | collect_enum_zero_{nullable,all} trap fixed | defects keeper |
| two-composers | 1c92c0cac053 | body two composing traits both say is refused naming both | composes P1 |
| named-head-goldens | 1bab650bd816 | goldens for type.component_named_head (refused + fix applied) | voices gap |

Verified: all six combined on e02d71ab build clean; 8 goldens hold; voices no new gap; derived witness 10/10.
Earlier (d7cd/dad2): std-relation 349/349, std-db 296/296, std-ui 1056/1056, avrac-a/g + findings-d PASS,
std-program 505/506 (frontier "dir it can't write" fails only as root, pre-existing).
Cost (file-key, census check-cli vs dad2): all gated rows down (boxes −3.2%, list writes −3.3%,
string compares −6.2%, empty opens −0.07%); map boxes +0.39% (ungated). Not re-censused on e02d71ab.

## Half-done
Nothing uncommitted. Working tree /work/p14 clean (worktree of /work/avra).

## What's next
- Wait for the gate on the six lane branches; fix any red on its exact line. Lead deletes refs after landing (403 for us).
- ContentKey moved to the lowering-quality lane; design note sent: /work/out/2026_11_24_CONTENT_KEY.md
  (stale bits: module_dir_files was dropped; NameKey unification is theirs).
- The gate runs the snapshot-moving cost accepts; don't run them locally.

## Open questions
- None pending with the Lead.

## Runs in flight
- None.

## Notes for whoever resumes
- Container: /work/p14 is the worktree; standing compiler build/avra is a d7cd-era rung product
  (backup build/avra.bak-fk2). If `make compiler` falls to the seed bootstrap, copy a recent build/avra-try
  over build/avra and use `make compiler RUNGS="..."` (space-separated) to ladder.
- Disk: the full witness harness needs >14 GB; run it in chunks (scratchpad wit-chunks.sh pattern).
- Push: `git -c push.negotiate=true push gh <branch>:refs/heads/lane/replay-defects/<what>`.

## Resumed 2026-11-25 (session avra-lane-r2-replay-defects)
All six rebased onto program 574c2840 with no conflicts, pushed as `lane/replay-defects/<what>-574c`
(old e02d71ab refs untouched): type-exported-generated-privates bcf2bb19b294 (rung 8246ba6a),
file-key 453d09f76e65 (on top), component-setting fd4a0a4dda1b, zero-enum-name 76ec16f8e952,
two-composers d4c39f9e9a32, named-head-goldens e054fb8c2f0d; all six combined: combined-574c d0334eb9.
Verified on 574c2840: `make compiler RUNGS=8246ba6a` green (rung 572 s, then HEAD twice);
std-program saved_*/source_facts 75/75, std-avrac item_tapes/settle_named + type_content_key 23/23 +
program proved, cli objects_salt 4/4; combined `make try` green, 7/7 program-refusal cases hold,
voices no new gap, VOICES.md unchanged. Not re-censused; not run: full suites, idioms, cost.

## Landed 2026-11-26
program f842bf34 (train27) carries the whole stack: the `Type.exported` rung (79bf7fd7), .114.9, .114.8,
file-key ×4, component-setting (with its two idiom sites paid), zero-enum-name, two-composers,
named-head-goldens. Rebasing lane/replay-defects/combined-79bf-b onto f842bf34 drops every commit as
already upstream. Nothing pending in this lane.
Finding passed to the lead: train25's red at decl_grain_test.av:110,117 came from train25's
law_findings.av (`const_gathering`, a per-file query), not from this lane.

## Landed by 2026-11-26 (program f43cefa0)
- .114.12 spread-extend (evaluator's extend retains its slots) — train31.
- .131 lambda-fail (no-param lambdas promise their seat; generic `Result` seats of known failure;
  trailing blocks unchanged) — train41.
- .139 fd-scratch (a read lands in the reading task's slot; the evaluator files landings per task;
  case_test parks at `AVRA_SLOT_KEYS - 1`; `avra_io_list` says `traps: true`) — train41.
Nothing pending. Pre-flight for runtime changes includes `make runtime-tests`.
Seen red on program 42ed174d and not owed when last checked: host-events, families-left,
hooks-released (the tools package does not build: `type.host_seat` on `avra_fn_declared` and
`avra_cell_bytes_run`).
