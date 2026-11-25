# avra-lane-soundness-cells — lane note

## Branches handed back

- **avra-lane-soundness-cells**: the HELD unshared-slot relaxation of L2. It is waiting for `state` slots to wear `Cell<T>`.
  - becac71: the relaxation.
  - afeb489 and fb469c4: the interned_str and witness-row idiom fixes. These are local only and not in any bundle yet.
- **avra-lane-soundness-cells-coverage**: in next-base. It only tightens the checker:
  - a forget hands its cell's reference to the load that takes it;
  - an emptied cell is read by nothing until a store refills it;
  - an arm may not yield a register it holds no reference to;
  - a load that earned its own reference is exempt (6b47fe8).
- **avra-lane-soundness-cells-lent**: the Rule T (lent answer) checker K1–K4, GATED OFF by `checked(…, lent = {})`, plus 18 attack programs in `compiler/soundness/tests/lent_answer/`.

## Findings

- **State-local typing gap.** A `state` local's slot and its Load are typed `T`, not `Cell<T>`, so the IR cannot tell a `state` local's slot from a `mut` local's. Assigned to front-defects.
- **Unannotated state local miscompile.** An unannotated `state` local got no Cell at all, and its writes went into the binary's static data. Fixed by front-defects.
- **rc-elision-2 R2a leak.** The rule moved `release r2` into the other arm, while the handing arm kept the inner scope's `retain r2`. One box leaked per call, at 7 sites: std-net ×4, std-io.watch ×2, Workspace.settled_at. The fix was re-sent as rc-elision-r2a, and it is clean on:
  - the cli sound check;
  - the suite's compile;
  - handed_counted at 0 live bytes;
  - gen-2 == gen-3 byte-identical, with gen-1 and gen-2 live-at-exit identical.
- **Gate row added.** `AVRA_SOUND_CHECK=1 check packages/cli`, failing on any `defect: in` line. It takes ~4 min and 9 GB here, and catches leaks that RC_GUARD cannot.
- **Old `avra test` runner memory: RULED NOT TO FIX.** `test packages/std-avrac` exceeds 14 GB here with or without the checker (both runs 13.95 GB max RSS). One process holds it all, the compiler itself:
  - RSS plateaus at ~9.3 GB through the 510-program proof batch, then climbs to 13.6 GB during the per-program proofs.
  - The top live sites are the relation engine, the store and the front end: Kernel.begin, meant_lowered, Table.keep, loc_span, SyntaxArena, range_bodies. None is in memory/ or soundness/.
  - Not fixed because the program-layer `test` that replaces this runner already runs each evaluator leg in its own process.

## Rule T: conditions missing from (a)–(e)

- **M1 escape:** a store, push, pack, env, upward answer, yield or consuming seat must count the answer first.
- **M2 calls in between:** a call that can reach the root (state lambda, Cell, mut seat, mut self) needs the answer held across it.
- **M3 transitive root:** (b) and (c) bind the root of the argument's chain, not the argument register.
- **M4 one convention, all callers:** fn values, dyn and trait dispatch, spawn, defer, the evaluator and cached callers must all agree. The T mark is ABI, so code hashes and cached objects must key on it.
- **M5 per mono instance:** (d) must be judged after mono.
- **M6 lending steps only:** the answer chain inside the callee crosses no owning step.
- **M7 wrapped answers are not views:** an Ok or nullable box holding a view must count it.
- **M8 seat kinds:** p is not consuming and not `state`; there is one p only.
- **M9 unwind:** an uncounted answer never enters a cleanup's release list.
