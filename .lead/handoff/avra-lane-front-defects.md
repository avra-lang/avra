# avra-lane-front-defects — hand-over
Branch avra-lane-front-defects-mutlet, base next-base cd4738e6 (on trunk cf1b3e2c); head = the commit adding this file.
DONE, handed back: avra-lane-front-defects-cells (A+B), avra-lane-front-defects (nested state, lone-file float refusal, c?.n),
avra-lane-front-defects-state-test, avra-lane-front-defects-prop-cells (on e2bce925), avra-lane-front-defects-local-state (on 933ce4bb).
IN THIS BRANCH (not handed back before), on top of cd4738e6:
- 55ae206d text reads hold a fn-local `state`'s cell (StatePlace.Own; std-ui sited_text right).
- 3a511ff8 a module `state` handed whole to a `mut` seat (mutation/state_paths made).
- 9333c626 `state` seats on the program layer (param_state, fns/tests/state_seats) + law seat_stateless
  (old words, one voice stateless_seat) + suite cases state_seat_{captured,module,valued}.
GATE on this branch at cd4738e6 (interrupted by the stop order):
- passed: make try 0; cli --built 48927/48927; AVRA_SOUND_CHECK=1 AVRA_PROGRAM=1 build packages/cli exit 0, 0 defects;
  std-ui --ran 58 made 0 failing; std-avrac --ran 642 made 0 failing.
- NOT RUN: old-path sound check, idioms cli/std-avrac, refusal suite. Next command:
  AVRA_MEM_POOL_MB=13500 build/avra-try check packages/{cli,std-avrac} --baseline tools/idioms.baseline; sh tools/witness_program_refusal.sh build/avra-try
Lone-file door: state_nested/paths/unannotated/local_shared/deep, module_state, state_lost = old == new, RC_GUARD clean.
NOT DONE: b6 stale columns (cause notes in /work/avra-lane-front-defects.md); wasm W1 moved to extern-seats.
Findings not yet reported: none beyond the posts.
Don't touch without me: core/frame_reads.av placed_cells/local_state_cell, core/calls.av state_handed, StatePlace.Own.
