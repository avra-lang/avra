# HANDOFF — lane gate-speed (avra-lane-r2-gate-speed), 2026-11-25

## Goal
A fast program landing gate (gate.yml + tools/gate.sh) on free runners, the same checks, nothing sampled.
Owner target 12–15 min wall. Tickets: avra-8sb5.112 (12–15 min gate, split slow slices, cache rebuilds),
avra-8sb5.102 (every keeper on every gate, no added wall).

## Landed
- v3 (train21, d7cd84d9) and v8.1 (36b1394e on program): slices packed into runner jobs by measured
  seconds, census its own job, gen-1 over the builder's stores, cost-laid answers beside the builder.
- The release `gate-builder` carries compiler.tar.gz, builder-store.tar.gz and cost-answers.tar.gz.

## v9 (branch lane/gate-speed/v9, on program 79bf7fd7) — not gated yet
- std-avrac share: a row per directory + one for its files; cli a row per test file; shares dealt by path
  seconds (tools/gate/path.seconds, `sh tools/gate.sh seconds <log>` fills it).
- Every keeper on every gate, a row each; keepers red on program owed in tools/gate/keepers.owed (owner, why).
- A row judges its UNPROVED PROGRAMS by path (tools/gate/<package>.unproved). v8.1's `tested` passed over the
  suite's exit once any case failed by a pinned name, so a share holding lists/maps hid mutation's unmade
  state_component; that was the "mutation red" — red alone on program too, not order-dependent.
- Keeper setups: AVRA_TOOLS_COMPILER=build/avra for the whole gate (avra_tools.sh otherwise builds the tools
  package with MAIN's published compiler, which refuses program's laws — families-left, hooks-released,
  host-events, and the lead's late finding about runner builds); dev-server builds the wasm runtime first;
  tool-witnesses gets build/avra-try (the seed's gen-2); speed-ratchet runs on the clock runner with
  SPEED_HOST=ci-warm; keepers-alone honours keepers.owed.

## Open
- Owners in keepers.owed beyond the lead's five are guesses: codecs→targets, cited/http-cites/suites/
  vendored-fixture→wisp, read-lists→lead, cutoff-witness→warm, defects→defects, ui-browser→first-paint,
  runtime-mutations→mem-hunt. state_component (std-avrac.unproved) has no named owner.
- speed-ratchet measures 8 phases and gates 0: tools/speed.budget has no ci-warm rows for them, and it costs
  ~800 s. Lead's call: accept rows from a gate run, or owe it.
- voices: docs/VOICES.md is one voice behind (regenerate with `./avra voices --report > docs/VOICES.md`).
- After a compiler-moved gate: read the seed's `fact gen2-differs`; a stamp in a data section lets slices
  start on gen-1.
- Biggest lever, not gate-side: the cli's cold build 2–2.7× slower since train21 (@std/compress,
  @std/http_compress). `make census CMD="build packages/cli"` at b5a71497 vs d7cd84d9.

## Next (exact)
Pre-flight (lead's standing rule) in this container, then hand the branch to the lead for a gate run.
