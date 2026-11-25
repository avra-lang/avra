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
