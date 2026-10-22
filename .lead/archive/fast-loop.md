# fast-loop handoff

- Worktree: /Users/tristan/projects/tristanMatthias/avra-fast-loop (no Sprite bound). build/avra = build/avra.gen2-portable (stable, bootstrapped from #433's seed).
- In flight: branch `entry-skips-tests`, tip 3ede223, PUSHED, no PR yet (.253 step 2 cheap half).
  - A BUILD (Want.Binary) of an entry outside tests/ walks root files minus tests (`entry_files`, modules.av; `built_entry(at)` in derive.av; `held_modules(ws, store, built)`); a check reads every test. `used_packages` skips test files.
  - Witness: packages/cli/src/commands/tests/entry_tests_test.av, 3/3 with the product (build/avra-after2) as build/avra; main's product fails 2/3.
  - Also green with the product: cli kept_settle 10/10, sibling_programs 4/4, build_report 4/4.
  - Cold cli: 488 → 451 files parsed; compile phase total within noise (33–37 s both ways).
- NEXT STEP: with the product as build/avra (`make try`, then `cp build/avra-try build/avra`), run `sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers`, restore build/avra, then ask the lead to open the PR.
- Other branches: held-runs (#416 merged), stable-keys (#428), wasm-stamps (#430), portable-seed (#433 merged), drop-cold-bodies (#426), program-symbol (#424). Tickets: avra-8sb5.57.261, .262.
- Measurement: /tmp/fl/step.sh (a `make avra` equivalent, timed with --time, prints held/N); /tmp/fl/cold.sh <binary> (cold build via a re-signed copy, so it gets a fresh store; reports held, parse, analyze and the compile phase total). Use phase totals: wall time includes waits on the watch.sh lock (40–190 s noise).
- TRAPS:
  - cli tests (kept_settle, sibling_programs, entry_tests) SPAWN build/avra: install the branch's product there first, or the test checks a stale compiler (#416 was dropped twice this way).
  - gate_changed's keepers also use build/avra: a stale one fails codecs/flow-trace/witnesses spuriously.
  - `avra test X` compiles the TREE's source as the subject (std-avrac tests); to witness "red before", revert the source, not the binary.
  - The ui-browser keeper fails on this Mac (headless Firefox): environment, not the change.
