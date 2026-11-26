# HANDOFF: lane spec-harness (replay lane), 2026-11-25 11:44 UTC

## Goal

The keepers work, the untested-instrument law at scale: every keeper of the Makefile's groups runs on every gate, each slice ends with a planted fault, red keepers are pinned with their owners, and the keepers' own reds are fixed. After that, the review of wisp (avra-8sb5.100), the oracle format (.100.2).

## Base and branches

| what | branch | tip | base | state |
|---|---|---|---|---|
| the pushed handoff | `handoff/20261125-1144/spec-harness` on gh | see the push | gh/program e02d71ab | pushed |
| keepers series | the same branch, local `keepers-d910` in /work/wt-keepd | 3643d13e (+ this note, + 8f41ad57's cherry-pick) | gh/program e02d71ab | 25 commits; built here (gen 2) |
| refusal-witness disk fix | in the same branch (cherry-pick of c4cb5b25) | — | gh/program | not yet re-witnessed on gh/program |
| tape cut 2 (WIP) | local `wip-handoff-cut2` in /work/wt-cut2 | 675922da | c19e2987 (OLD; not rebased) | in the bundle only |

The series was last sent to the Lead on c9780be7 as efc094d2 (/work/out/avra-lane-replay-spec-harness.keepers-c978.bundle).

## What's done (keepers series, on gh/program)

- Gate slices: keepers-1..4, keepers-mutations, keepers-warm, keepers-try, keepers-witnesses-1..4 (tools/gate.sh).
  - Rows come from `make keepers-listed`.
  - KEEPERS_ROWED lists the keepers other slices already run.
  - Every slice ends in a planted fault (tools/keeper_planted.sh).
  - tools/gate/keepers.pinned holds red keepers with their owners; a pinned keeper that passes fails its row.
- The wasm skip-passes now refuse (WASM_SKIP stands one down locally only, never on CI).
- avra_tools.sh builds the tools with the tree's own compiler, never a fetched one (train23's keepers-3 defect).
- Fixes: inputs `link`, runtime-mutations (359/359), suites shards, http-cites, codecs registry (3 live codecs), vocab, cited, attack baseline (two `trait x<impl…>` survivors are now refused), dev-server prereqs.
- Witnesses fixed: witness_warm_edit, witness_place_kill, witness_disk_full (stale targets).
- tool-witnesses: dealt into parts; the gate's own witnesses are declared `run by` their slices; 5 are owed:
  - witness_disk_full's heir case → wrong-answers
  - store_builders/prints → wisp
  - work_test flake → lane-run .112.6
- Pushed to gh, but now the Lead's job: the gate run of this branch.

## Checked on gh/program + the series (gen-2 compiler built here, 96108fea)

- Green: parser, dogfooding-rules, vendored-fixture, codecs, vocab, cited, attack, http-cites, suites, host-events, pipeline-doc.
- RED, not yet triaged:
  - voices and witnesses: VOICES.md/DIAGNOSTICS.md were regenerated on dad28699, and the VOICES regen commit was dropped in the rebase onto gh/program (conflict). They need regenerating with gh/program's compiler: `./avra voices --report > docs/VOICES.md; ./avra diagnostics > docs/DIAGNOSTICS.md`, after checking that every kind has its witness (`make voices`).
  - inputs: pinned; recount its unclassified sites and update its pin line.
- Not run on gh/program: the long keepers, the gate slices themselves, and the refusal witness with the disk fix.

## What's half-done

1. **voices/witnesses on gh/program**, as above. Next, in a tree at the branch with a gen-2 compiler (/work/wt-dad2 is at 3643d13e, built):
   `cd /work/wt-dad2 && make -s -o avra voices; ./avra voices --report > docs/VOICES.md; ./avra diagnostics > docs/DIAGNOSTICS.md`
   If `make voices` names a kind with no witness, that kind's lane owes it; pin `voices` with that owner instead.
2. **refusal-witness disk fix on gh/program**: re-witness with `sh tools/witness_program_refusal.sh build/avra` (or the 8 refusal-N gate slices), and record peak disk.
3. **Tape cut 2** (/work/wt-cut2, branch wip-handoff-cut2, on c19e2987): `module_heads` is parted by word; `declarations_of` reads `surfacing`; `module_declares` is removed.
   - Tests updated; std-process −72% boxes; cli was +1.95% before the plain-fn change.
   - Needs: a rebase onto gh/program, pass words (`@cut_parted_query("summary")` etc.), a cli census re-run, the refusal witness and doors. Parked by the Lead.
4. Wisp review: sent (8 conditions on §5). Waiting for the wisp lane's revision.

## Open questions

- Whether the Lead wants a 5th keepers-witnesses part (part 2 ran 757 s of 900 here).
- Whether keepers-witnesses runners have WebKit's libs (two layout-oracle tests need them).

## Runs in flight

None. The last local runs finished; no background task remains.

## Remaining queue (from the Lead)

Listing kind-bit commit; re-measure tape cut 1 (drop if ~0); fold cut (3) into item_under; the ledger's "items read" unit; wisp/oracle follow-ups.
