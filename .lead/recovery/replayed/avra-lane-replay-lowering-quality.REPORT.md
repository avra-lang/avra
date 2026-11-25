# avra-lane-replay-lowering-quality: rebased onto land58 afd7c921

Bundle: `avra-lane-replay-lowering-quality.bundle`, prerequisite **afd7c921** (land58-afd7, over dc78a97a and 0f278326).
The -bf and -wip branches are dropped, as asked.

| branch | tip | what |
|---|---|---|
| `avra-lane-replay-lowering-quality` | **2678cff6** | the lane, 6 commits on afd7c921 |
| `avra-lane-replay-lowering-quality-plainfirst` | 198e1d97 | optional: the plain-first walk ported onto land58's walk, on top of the lane; moves no measured row (below) |

## The lane on afd7c921
| was (e9266ae9 lineage) | now | subject | rebase notes |
|---|---|---|---|
| 2c2e53c2 | f1aa6575 | work ahead: a check finds each file's laws and rules across cores, as a build lowers them | **merged by hand with land58's 2623f323** (std verdicts, a dependency's warnings its own check's): `program_worked` keeps land58's `vouched` and takes the lane's `FileWave`; each wave's `is_known`/`ask` is handed whether the file is vouched. `bodies_wave` is land58's `file_worked(e, f, vouched)` unchanged. `checks_wave` asks no law of a vouched file, and asks warnings, rule rows and stale citations only of the program's own files, as land58's check reports them. `check` keeps land58's `warnings_apart`, and its time flag (`timed` or `AVRA_QUERY_TIMES=1`). |
| 5c99af4c | 0f24023b | program layer: a file's frames read its bodies' own frames, its units grouped once per build | clean |
| 1592e06c | 27bbc000 | dev link: the overlay carries its unwind tables' index, so a trap unwinds through it | gate.sh witness-b list: land58's row plus `layered_unwind_attack` |
| 58c29e00 | cd078bba | work ahead: a check reads every file's names in a wave of its own before it finds its rules | the wave list keeps `vouched`; `reads_wave` ignores it |
| 5d3cc9c0 | 4f8fb30c | check: its store is kept by an heir, as a build's, so a check answers before it's saved | keeps land58's `times_said(engine)` after the keep, as a build does |
| d7a265c8 | **dropped** | frontier order fix | land58 already has 0a5db713 ("settle a change's readers in reading order, never hash order"), which makes the walk order-independent its own way and conflicts with this one whole |
| 3741b8f5 | → `-plainfirst` 198e1d97 | plain-first walk | ported onto land58's walk (`plainly_reached` over its flat written-readers; `readers_of` reaches a plain place undecided). Measured over land58: the warm rows are identical (edit-added 58, added_after 42, all 8 equal) and its cold rows are within 0.010%, so it is held apart with that message, not on the lane |
| 7c7f2278 | 2678cff6 | subset: `x?[i] ?? d` leaves the fn where `x` is absent; a nullable index read asked for | ROADMAP's `Callsite:` now says the plain-first walk spelled it that way, since it is off the lane; the message no longer cites 3741b8f5's sha |

**ItemId:** nothing refused. The lane's code holds no item id as an int; gen-1 built from the old head's compiler with no error.
fmt with the rebased compiler changed 3 lines my merges wrote; each fix is in the commit that wrote the line.

## Receipts (wt-rb at 2678cff6)
- Builder chain: the replayed head's gen-2 → the rebased tree, gen-1 and gen-2; then the final tree `make avra` ×3: gen-3 = gen-2, byte-identical.
- `fmt --write` over the 6 touched .av files: 0 written.
- subset runtime_test: 10/10. layered_unwind_attack: 2 held, exit 0.
- `sh tools/gate.sh program`: `GATE program 2678cff6 PASS rows=5 failed=0`.
- Cold `check packages/cli`, work ahead on vs `AVRA_WORK_AHEAD_OFF=1`: both exit 0, stdout identical.
- **Cost (census of 2678cff6 over snap57):**
  - against tools/cost.baseline (base57's rows): `cost: 54 rows, 0 over, 53 fell`. Most of the fall is land58's own: land58's head alone falls the same way, for example check-cli boxes −19.9% and edit-added 167 → 58.
  - **against land58 afd7c921's own rows** (its compiler built twice, its census, the same cost.sh): 59 rows, **0 over, 13 fell**. All the falls are build-cli (boxes −0.546%, list_writes −0.677%, empty_grown −0.676%, list_buffers −0.641%, reclaims −0.567%, …) plus check-program list_reads −0.005%. Warm rows equal: noop 0, inline 18, literal 13, comment 13, body 14, signature 30, added 58, added_after 42.
  - So on land58 the frames trade no longer costs build-cli anything: the lane's build-cli is below land58's. The accept that rides the landing is a `make cost-accept` over snap57, which only lowers rows.
