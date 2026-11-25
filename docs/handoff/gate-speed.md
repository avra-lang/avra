# HANDOFF — lane gate-speed (avra-lane-gate-speed), 2026-11-25

## Goal
A fast program landing gate (gate.yml + tools/gate.sh) on free runners, the same checks, nothing sampled.
Owner target 12–15 min wall. Tickets: avra-8sb5.112 (12–15 min gate, split slow slices, cache rebuilds),
avra-8sb5.102 (every keeper on every gate, no added wall).

## Landed
- v3 (train21, d7cd84d9): compiler_paths one-cat key (built-from 6.4s→1.0s), cost-ledger-cold split a/b,
  census in seed (since moved), gen2-is-gen1 fact, cost per-workload facts, docs/2026_11_24_GATE_SPEED.md.
- v8.1 (36b1394e on program, from e1e213cb): slices packed into runner jobs by measured seconds
  (tools/gate.sh jobs, tools/gate/slice.seconds; 80 slices → 48 jobs, each slice alone in a fresh tree),
  census its own job + cost matrix, gen-1 over the builder's stores, cost-laid answers beside the builder,
  gen2-differs + CPU facts, pipeline-doc fix.
- LANDING DUTY still owed (check the release): publish artifacts gate-cost-answers → cost-answers.tar.gz and
  gate-builder-store → builder-store.tar.gz into release `gate-builder` beside compiler.tar.gz. Without them
  those two cuts do nothing.

## Half-done (this branch, NOT for landing as is)
Branch handoff/20261125-1144/gate-speed (also lane/gate-speed/v9-wip @ 238d1fce), on program e02d71ab:
- ecbd23d1 std-avrac share = a row per directory + one for its files (empty scope passes, all-empty fails)
- cd7e060f every keeper on every gate (keepers-a1/a2/wasm/b-1..3/alone-1..2/clock; 11 covered elsewhere)
- 2800b7e0 cli a row per test file; cli + avrac-features shares dealt by path seconds (tools/gate/path.seconds,
  `sh tools/gate.sh seconds <log>` fills it)
- 238d1fce owed keepers (tools/gate/keepers.owed; owner column = program-lead placeholder)
State: RED on run 45573783521 (gated on c9780be7 + 2bba8645 + lead's owners commit):
- 15 non-owed keepers red, several HARNESS reds (0 s: dev-server, http-cites, suites; speed-ratchet lacks
  checks.yml's warm store). Each keeper needs its checks.yml job's exact setup (handed-down store,
  speed-note cache, SPEED_HOST, browser leg, runtime-keep clock). cited/http-cites/suites/vendored-fixture
  are said to be fixed by the "wisp" bundle.
- std-avrac@features+mutation red: 90/90 cases pass, but tests/state_component is "not made on the program
  layer yet" (a written receiver a `const` holds, at the entry); program_tested is green only if every
  printing program is proved. Unresolved: per-directory rows (scope/order, store shared across rows) vs base.

## Next (exact)
1. Decide the mutation red: on a fresh tree of program, `build/avra test packages/std-avrac/src/features/mutation`
   alone. Red alone → scope or base (retry without 2bba8645); green alone but red after the consts row →
   order-dependent store answer: file a compiler defect.
2. Keepers: per keeper, copy its checks.yml job's env/setup into tools/gate.sh keepers_run (or run keeper
   slices through .github/actions/handed-down-equivalent), re-gate, owe the true base-reds with real owners.
3. After v8.1's first compiler-moved gate: read the seed's `fact gen2-differs <n> first=<off> in <section>`.
   A stamp in a data section → v9 compares modulo it and lets slices start on gen-1; .text → no.
4. Biggest lever, not gate-side: the cli's cold build ran 2–2.7× slower from train21 (cli reaches
   @std/compress + @std/http_compress, vendored zlib/brotli). `make census CMD="build packages/cli"` at
   b5a71497 vs d7cd84d9. It bounds edit-*/needs/refusal/warnings slices and the seed's two builds.

## Open questions
- Owners for keepers red on program (vocab, parser, dogfooding-rules, attack, warm-edit, footprint, inputs).
- Has the landing tool published cost-answers.tar.gz / builder-store.tar.gz?

## Runs in flight
None of mine.

## Base
program e02d71ab (github avra-lang/avra).
