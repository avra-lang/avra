# State 2026-11-24 (evening, PST) — lead's handoff

## Landed today (program, newest last)
2e85bb22 A2 pack route (cold check-cli 91→43 s) · cf0c9a15 hygiene/shared store · 984ea852 defects guards ·
28be744c STORE POISONING FIX · 37ee7901 warm store + Cell port + cost-laid speed · 428d4a3c rule gating ·
91ebc6c5 answers laid by hard link · c19e2987 warm open one walk + chain by size · 5a8f5de6 cost snapshot moved ·
f688e52c PASS LEDGER + indexed reach · 395215ac ledger rows accepted · 71a13951 alloc rung A ·
58289f5b defects poison (a refused value poisons only what depends on it) · e46cd866 held-values + GENERATED CODE JUDGED + listing fix ·
cccc5ecb frontier orphans + walk check gated + alloc rung B · 1127e43f ledger isolation · d91061ef laws-fusion train 2 (names by 128-bit key).
Warm cli: noop 10.3 s → ~0.13–0.2 s; body edit 12.9 s → ~0.2–0.24 s (in flight: train 20); signature ~0.3 s.

## Owner decisions today
- Cost calls are the lead's. Identity is a 128-bit content key (ContentKey), never a text compare on a hit.
- Map/Set design APPROVED (docs/2026_11_24_MAPS_AND_SETS_DESIGN.md §11; epic avra-8sb5.99). Set.of first; literal later (avra-8sb5.99.4; lead: `#{a, b}`).
- @std/config (docs/2026_11_24_CONFIG.md; epic avra-8sb5.64.7): component spelling preferred (lead: lowers to record+derive), secret = handle, drop secret("key"), live waits for `state x: Live<T>` (tracked), strict.
- Internal CLI named `wisp` (epic avra-8sb5.100). Determinism check at zero wall (ledger twins). Durability measured and deferred (docs/2026_11_24_DURABILITY_DEFERRED.md).
- Centralize one definition per layer (epic avra-8sb5.104); core protocols as traits (avra-8sb5.99.6); SIMD deferred for its own design.

## Epics opened today
avra-8sb5.99 Map/Set · .100 wisp · .101 store soundness (door, fsck, fuzzer) · .102 every keeper on every gate (65/79 unrun; 4 of 9 red) ·
.103 ContentKey · .104 centralize · .105 warm noop.

## In flight (lane → work)
- spec-harness: the DELETION (fixing 3 gate failures: suites mislabeled "Binary", tool-identity build keeping, laid cost +7%); then keepers audit; then wisp.
- wrong-answers: train 20 (part-aware meet + stale-reader fix, refusals per package [laid compares fix], ledger re-check columns); the fuzzer's pre-existing rename/revert/delete trip; store fsck; noop inputs list + lazy stamps.
- defects: @derived Saved field + file key (on d910), then ContentKey (+NameKey), identity.text_compare law, view cut.
- parity-values: noop cuts (−57% instr), then vouch by stamp (~65% of a laid noop), items-read column, derived persistence.
- laws-fusion: Map/Set phase 1 (runtime Swiss index), core protocols section, then one Name type.
- alloc: C+D rebase onto d910 (checking.av conflict), then perfect hashing / roaring / Eytzinger + Techniques section.
- parity-types: re-pick onto d910, fix +148k empty lists, then one side-table type.
- lowering-quality: quiet-call borrow law, censusing cold.
- std-config-design: revising the doc with the owner's answers; then C1.

## Later 2026-11-24 (PST evening)
- THE DELETION LANDED: program = dad28699 (mirror b6dce5f2), gate 45505024128 81/81. Also landed since: 41f703cd docs (config + maps/sets designs), 43590971 train 20 (part-aware meet, refusals per package, ledger re-checks), 5ee901c3 alloc C+D (owner's two asks).
- Gating: config C1 (866772d3), board (a42b1f94), quiet-call (cc4c384a), storyboard s1-2 (eccd8c78), gate-speed (27fb5d1f).
- New lanes: std-config-design (cse_01F8zAGayWKBAGq3JHRJeDUy), storyboard (cse_01F8zAGbvHcsYh4fzdi9qCow), web-first-paint (cse_01F8zAGbdQrykCBDo7aSviUR), gate-speed (cse_01F8zAGbS1m9MmwcqzEtZuzZ).
- Keepers audit: 79 keepers, 13 run by the gate; 16 real reds routed (spec-harness own + regenerations; cores/pool -> lowering-quality; ceilings -> parity-values; collect_enum trap + voices witness -> defects).
- UI rulings today: storyboard (approved, slices), board Auto/Light/Dark + field submit, @seeded_at_need (approved; View trait wears it), be28700 overflow-wrap dropped.

## program history flattened (11-24)
- Local `program` = origin/program (clean mirror history, same tree). The old history with the 106 MB `.staged` blob is kept at `refs/archive/program-pre-flatten-2026-11-24`.
- Landing: `program`, `program-gh` and origin/program are one history now. Push a landed commit straight to origin/program.

## Decisions 11-24

Owner:
- The pass ledger is the most important metric: instrumented in the CLI, shown on every PR (07:33).
- Every named top-level instance is a declaration, `export` meaning visibility only; an instance reading a top-level `let` is refused with a `state` remedy (avra-8sb5.10.211, unbuilt).
- Land in trains: drop a red lane, regate the rest; individually green gates stack onto the head as one train (lead 17:46).
- No paid runner: free GitHub runners only (11-25 01:09).
- Everything a lane does is documented or tracked in an existing doc (20:53). Every error of a change is listed at once, never in rounds (22:45).
- SIMD deferred for its own design (avra-8sb5.62.1.3). One typed settings source replaces the AVRA_* vars (avra-8sb5.104.6).
- `fail` in a zero-parameter lambda whose seat answers a Result is allowed (9ba1b2b2, spec line changed); the owner may reverse it.

Laws the lead ruled (each in its commit; fold into CLAUDE.md where general):
- Every body that will run is type-checked at `check`, generated code included; its errors point at the annotation or instance that made it. Generated items are judged inside the per-item cache, so a warm edit re-judges nothing; generators built into the compiler are judged too.
- A generic body wrong for every instance is refused at its definition only.
- A quote's `${t}` hole carries the type it was handed, never a name re-resolved in the derive's scope.
- An unrecorded read is sound only while its key covers what it read; where the read misses, the answer records the read.
- A refused operand poisons only what depends on its value, never a type the node knows without it.
- fmt never chooses a grouping for code the checker refuses.
- An instrument must not move what it measures: counted cost runs run ledger-free.
- A phase's total includes first-time work it triggers: count body runs, not totals.
- Laws are selected by a declared property, never by a kind-text prefix. Warm work is never traded for cold.
- One stack whose entries carry both facts, never two parallel lists kept in step.
- The std-answers writer is complete by construction, whenever compaction fires.
- Parity: the old path was the oracle except where its refusal was a mechanism, not a law.
- An unexplained trap is recorded as unexplained, its hypothesis labelled.
- A deletion is not held for a small cost residue; the cut lands on top or the residue is accepted. Gate cost slices replace a lane's local multi-hour cost run.

Machine (after the 11-25 crash):
- No heavy local work while another session runs browsers or builds; one build at a time, capped at 3 GB under tools/watch.sh; builds wait under 30% free; at most one simulator.
- Lanes use durable worktrees, never /private/tmp; copy the depot compiler instead of bootstrapping; commit as they go.
- The main checkout `avra/` index is stale (landing moves `program` without it); `git checkout -f program` only on the owner's say.

UI lead's rulings not yet in docs/2026_11_16_UI.md (theirs to record):
- State seeding: own `state` seeded at build stays the default; `@seeded_at_need` opts in (avra-8sb5.109.8).
- A control always has a name (avra-8sb5.109.9); a field's input is contained (.109.10); phone overflow by the layout oracle (.109.11); text takes an ink subset (.109.13).
- `tab` and `scheme_tab` are two typed place-form compositions until generic compositions land (avra-8sb5.10.209); no licence or rule for two twins.
- No new derive capability to add an annotation to its subject: marks go on the trait, as `@placed` does.
- A collect projecting a component (storyboard A1) is not asked for; `@viewed` suffices. A3 (a declaration's source text) deferred.

Doc entries owed on program's tree (the main checkout's ROADMAP/ZERO_COST are behind program, so not edited here):
- ROADMAP sugar backlog: `with` binds to an instance (avra-8sb5.10.212); a build-time law over a settled value (avra-8sb5.10.213).
- ZERO_COST.md: the six inefficiency families and their detectors (avra-8sb5.104.5); the quiet-call borrow row if its lane has not added it.

## Lane sweep 11-25 02:55 (every lane, nothing hanging)
- Train22 (re-gate 45532377667): services s22+step2, storyboard 1-3, lowering-quality keepers.
- Train22b, after train22: alloc step 1 (Rung).
- Train23: TARGETS doc 4516414a, iOS step A (ios-sim 3 commits, reword 78821e27), config C2 96a34e41, wrong-answers warm-noop, parity-values vouch-stamp + residue fix, warm board-train 9338a132, layer-commands c20381f0 (rebased, resend owed), parity-types params fix (owed).
- Gate-speed v6: its own train after 22 (it changes the gate).
- Working: laws-fusion (Map/Set ph1 verify), config C3, wrong-answers stamp paths, parity-values (residue, then the warm-edit matrix), parity-resolve-2 batch 2, parity-types side table, lowering-quality (static-low fix + ContentKey), defects (filekey fix), first-paint (WebKit double fetch P0, then slice 2), storyboard (rulings), spec-harness (witnesses), warm (lazy seeding).
- Local: mem-hunt (report owed), targets (P2 build), wisp (inventory and design), iOS → UI lead (handoff), train22 agent.
- Done, nothing owed: false-refusals, parallel-main, std-config design.

## Outside feedback 11-25: an app writer

From a session that built ../claude_usage_trigger in Avra.
1. No early exit from a catch arm: avra-8sb5.10.217 (P1)
2. User parse error cascades into stdlib errors: avra-8sb5.11.401 (P1)
3. eval != native, child stdin .Inherit: avra-8sb5.11.405 (P1)
4. "expected BREAK" with no fix named: avra-8sb5.11.402
5. Surface inconsistencies: avra-8sb5.10.218 (+ comment on avra-8sb5.10.109)
6. stdin with a timeout, file reads vs tasks: avra-8sb5.11.406
7. Signal/health-check another process: avra-8sb5.11.407
8. detach, parent pid, argv[0]: avra-8sb5.11.408
9. repeat avra-8sb5.10.28, int->float avra-8sb5.10.120, sort avra-8sb5.11.305 (comments); list a type's methods avra-8sb5.11.404
10. avra build -o: avra-8sb5.11.403
11. Exit with an int status: avra-8sb5.10.219
12. json { … } literal: avra-8sb5.10.220
13. App-writer cookbook: avra-8sb5.7.3 (P1)
Strengths (fix-carrying type errors, alias_copy catching a real bug): comment on avra-8sb5.11.
