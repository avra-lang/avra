# LEAD HANDOFF 2026-11-25 11:44 UTC (account switch at 97% weekly usage)

## Resume first (first 10 minutes)
1. Recreate the sweep: CronCreate `7,27,47 * * * *` with the LEAD SWEEP prompt (in this file, under Infra).
2. Gate `gate/lane-memrow-a8ae0176` (run 45605588625, the memory ledger row) was in progress. If green, land it (the recipe is under Infra).
3. Read every lane's handoff: branches `handoff/20261125-1144/<lane>` on origin (`docs/handoff/<lane>.md` in each).
4. `list_sessions` (claude-web). Each lane is mid-HANDOFF; send each "resume: your next step from your handoff doc".
5. Respawn the local agents (wisp, targets, mem-hunt) from their worktrees (see below).

## Program
- **Head: 574c2840** (memrow landed 11:5x: peak_mb + decoded rows gate memory now). Before: e02d71ab (train24: one differ + UI perf docs). Before it: f08fb217 (train23), 36b1394e (gate speed v8.1; gates ~15 min), c9780be7 (train22c).
- **Landing queue, in order:**
  1. (memrow LANDED as 574c2840)
  2. The services fixes' RUNG alone: 2e7281aed `Type.exported`, from the defects lane bundle `avra-lane-replay-defects-svc-d7cd.bundle` in the bridge inbox. Then its two fixes c1c1554d1 (.114.9) and e66cca5d9 (.114.8) WITH services step 2 (origin/services/step2 29dbc53fe3).
  3. alloc step 1 RUNG (one annotation spelling; branch train22b in avra-train, needs a rebase).
  4. wisp/design (rename + keepers + cost + parser; .102.3 has a generation step, so ask wisp which commit is the Rung).
  5. targets/p2.
  6. The rest from the lane branches: lowering-quality (void lambda .114.10, static-low, ContentKey step 1), parity-values (vouch + opened fix), wrong-answers (warm noop + stamp paths + store-program), spec-harness keepers c978, parity-resolve-2 batch 2, laws-fusion (Map/Set phase 1 + derived Eq), config C4 (wisp settings), defects filekey.
- **Gate rules:** one gate run at a time (a new push cancels the running one). A Rung lands alone. A cost rise needs an accept commit citing its run (cost calls are the lead's). cost-laid may not repeat (.112.7).

## Lanes
| Lane | Where | Handoff branch | State / next |
|---|---|---|---|
| warm | cse_01F8zAGbP6ttngJgZYkMcqpG | handoff/…/warm | READ_SETS approved (see READ_SETS_RULING.md): build rules 1–8, then the (a)–(e) section. Tape pass .114.1 after |
| laws-fusion | cse_01F8zAGf2XkSxrS1pQeBa9Zt | …/laws-fusion | Map/Set ph1 rebase, derived Eq (36 same_*), then the ONE NAME census |
| parity-values | cse_01F8zAGcTEDwZw1cEU4MoXs7 | …/parity-values | vouch + QueryEngine.opened fix; queries_computed accepted; next: the warm-edit matrix .105.1 |
| lowering-quality | cse_01F8zAGd6HfM74N8MHwe9u2z | …/lowering-quality | ContentKey (.103), with the design note in its /work/in |
| parity-resolve-2 | cse_01F8zAGdrtYcDmqsd1aiBuSv | …/parity-resolve-2 | batch 2, then impls_at and item_misses |
| config | cse_01F8zAGayWKBAGq3JHRJeDUy | …/std-config | C4 = `wisp tree settings` (option B), after wisp lands |
| alloc | cse_01F8zAGcrEZmJD3X6NiEW5ms | NO handoff branch seen | step 1 rung; sweep plan approved (fast route); sqlite-in-client .59.29.7 |
| parity-types | cse_01F8zAGfNZ22M3Y7XGxySq4z | NO handoff branch seen | side table .104.2; parameters() fix |
| wrong-answers | cse_01F8zAGd8jkL9fcEgc8KsvYz | …/replay-wrong-answers | store-program resend, place_kill/disk_full, inputs keeper, then .101.1 |
| storyboard | cse_01F8zAGbvHcsYh4fzdi9qCow | …/storyboard | Firefox claim fixes + rulings (1)/(2) |
| defects | cse_01F8zAGdtNLvaD1sT958ky96 | …/replay-defects | svc fixes done (in queue); filekey resend |
| spec-harness | cse_01F8zAGbEisHhtt7dQwaH8ie | …/spec-harness | keepers c978 (harness fix) |
| gate-speed | cse_01F8zAGbS1m9MmwcqzEtZuzZ | …/gate-speed | v9: every keeper with its real setup; seed cut |
| first-paint | cse_01F8zAGbdQrykCBDo7aSviUR | …/avra-lane-web-first-paint | landed; next is the taps-before-adoption proposal |
| wisp (local) | ../avra-wisp | …/wisp | see the queue |
| targets (local) | ../avra-targets | …/targets | P2 ready; P1 compiler slices to schedule |
| mem-hunt (local) | ../avra-memhunt(-s1) | …/mem-hunt | S1 gating; S3 sweep failed (rebase to e02d71ab first), then the knee table |
| UI lead (peer) | "Avra UI" session | origin ios-spike 94582f98 | its doc: UI_HANDOFF_2026_11_25.md (here) |
| Services (peer) | "Avra Services" session | origin services/step2 | its doc: HANDOFF_2026_11_25.md (here) |

Local worktree WIP: 171 dirty or unpushed worktrees are snapshotted as refs `refs/handoff/20261125-1144/local/<worktree>` in this repo, and pushed to origin `handoff/20261125-1144/local/<worktree>` where GitHub accepted them (see pushlog: old histories with the 101 MB blob are refused, but they're local refs either way).

## Open owner items
- Disk is nearly full (~2–3 GB free; 886 GB used outside avra). The UI lead asked about clearing Xcode data, still unanswered.
- READ_SETS (a)–(e), TARGETS P3, sqlite in the client: tabled in the UI handoff doc.

## Owner decisions this session (also in memory)
- No paid runner. Gate speed first. UI owns all iOS. TARGETS approved. One annotation spelling. Delete obsolete items rather than port them to wisp (list each deletion for the owner). The old parser fallback is deleted outright (the grammar stays). Cloud lanes push to GitHub themselves (the App is installed). Screenshots go with every UI step.

## Infra
- **Bridge dead** ("browser has been closed"): `cd ~/projects/tristanMatthias/claude_web_mcp && bun src/cli.ts stop`, then any claude-web tool call restarts it.
- **Landing a green gate:**
  1. Push the mirror sha to `refs/heads/program` (its parent must equal origin/program).
  2. Run `git update-ref` for program and program-gh in the main checkout.
  3. `gh run download <run>` the gate-pack, gate-builder-store and gate-cost-answers artifacts, then `gh release upload gate-builder compiler.tar.gz builder-store.tar.gz cost-answers.tar.gz --clobber`.
  4. Delete the gate branch.
- **Mac compiler:** a runner `make seed` from gate-builder, then `make recover` locally (~3 GB). Depot: ~/.cache/avra/compilers/avra-macos-f08fb217 (newest).
- **Cron prompt:** see this session's LEAD SWEEP text (in the transcript); it's the 5-step sweep (gates, lanes, local agents, bridge, a short user line).
- **Pointers:** .lead/PROGRAM_DESIGN.md (centralization plan, memory regression), .lead/handoff/RECOVERY_2026_11_24_STATE.md, the tasks db `TASKS_DB=.tasks/avra.db`, and the `/handoff` skill.

## Late finding (11:46): runner builds on e02d71ab fail under `builder:`
targets (run 45605549898), wisp (45605678435) and mem-hunt S3 (45605454825) all failed in the PREP compiler build with the same errors: type.host_seat on `avra_cell_bytes_run` (Cell<Bytes>), type.quote_pat_subj, and an @derive refusal on TinyNode.octets (Bytes on a tape). The cause isn't any lane's change. Suspect the `builder:` path fetches an OLDER published compiler (e.g. "latest avrac-…" from the main cache) instead of gate-builder e02d71ab. FIRST THING: run lane-run on bare origin/program with the gate-builder recipe and see. Ticket avra-8sb5.112.6 (lane-run for program branches) is the fix's home. Lane handoff docs: avra-targets/HANDOFF.md, avra-wisp/HANDOFF.md (Rung 387752ae30 then 0f5afd3e29), avra-memhunt/HANDOFF.md.
