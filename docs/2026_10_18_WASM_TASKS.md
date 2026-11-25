# Tasks on the web (wasm)

Ticket avra-8sb5.59.29.2. DRAFT for the DB lead to route: it touches the
scheduler (`runtime/avra_fiber.c`, CHANNELS' design) and the wasm backend.
Measured numbers say where and with what; `r:` is the Sprite (node 24.18,
binaryen 120) unless marked "Mac" (node 24.19, binaryen 133).

## The decision

**One park contract; the host supplies the suspension.** A task waits at
exactly one runtime row, `avra_park(gate)`. Native and the evaluator keep
the fiber stack switch. A wasm page binds the row to the host's own
suspension:

1. **JSPI** (`WebAssembly.Suspending` / `promising`) where the host has it.
   This is the default now: it ships in all three engines (table below).
   No instrumentation, no size cost, constant cost per park.
2. **Asyncify, scoped to the may-park slice**, as the fallback for hosts
   without JSPI (Safari/iOS 26 and older, older Firefox). It ships as a
   SECOND ARTIFACT (`app.asyncify.wasm`), fetched only when
   `WebAssembly.Suspending` is missing; the clean `app.wasm` is what JSPI
   hosts load. The fallback is a post-link pass and a 40-line JS driver.
3. **Compiler state machines** are the endgame only if size ever demands
   them. Not on the path: the largest compiler change, and indirect calls
   through closures (everywhere in Avra) force a conservative colouring
   that asyncify already provides.

One program, every target (P12): `spawn`, `within`, channels and `select`
are written once; no source names the mechanism.

## What exists

- `make wasm-runtime` leaves out `avra_fiber.c` and `avra_cores.c`. A task
  program fails at link: "a wasm module has no body for avra_task_spawn,
  avra_wait_*, ..." (`avra build --target wasm`).
- UI work needs none of it. `web.av` files wants (After/Every/Get) as host
  turns (`avra_ui_arm`, `avra_ui_get`): a handler, a timer and a fetch are
  turns on the browser's event loop. This stays the rule for UI.
- So the work here is `spawn` / `Tasks` / `within` / channels / `select`
  for library code (std-http handlers, workers) on a page.

## The scheduler, reused

Everything that is DATA stays in C and runs in wasm: ready queue, gates,
timers, the cancel flag, `within` deadlines, join. Only two things change:

- **who runs next.** A parked task is a suspended wasm stack (JSPI) or an
  unwound one (asyncify). The "run loop" is the JS event loop: waking a
  gate resolves that task's promise; a timer is `setTimeout`; an fd wait is
  a `fetch`/`WebSocket` callback. No poller object links (D1 in
  2026_10_06_NO_OS_FOOTPRINT.md holds).
- **`spawn`** starts a task as a fresh `promising(entry)` call (JSPI) or a
  fresh driver loop (asyncify). The main task is the same call.

## Measured

Real Avra output (`avra build --target wasm`, fib(35) + a 1M-element
comprehension and fold; r:), asyncify applied to the WHOLE program with
`fd_write` as the async import and indirect calls conservative — worst case,
since `println` is reachable from the hot function:

| build | size | time (3 runs) |
|---|---|---|
| plain `wasm-opt -O2` | 31,876 B | 131-134 ms |
| asyncified, hot path reaches the park | 44,060 B (+38%) | 251-264 ms (1.9x) |
| asyncified, hot path cannot reach it | 43,491 B (+37%) | 142-158 ms (+12%) |

Park cost, synthetic C module, a park that resolves at once (Mac, 2e5
parks; `--experimental-wasm-jspi` on node 24):

| | shallow stack | 200 frames deep x 2e4 | 2000 deep x 2e3 |
|---|---|---|---|
| JSPI | 22 ms (110 ns/park) | 36 ms | 35 ms |
| asyncify | 43 ms (215 ns/park) | 92 ms | 85 ms |

Reading: asyncify costs size on everything that can reach a park and
speed in proportion to how hot that code is and how deep the stack is at
the park; JSPI costs neither. Code that cannot reach a park costs
nothing under either. NOT MEASURED: a real program that spawns, joins,
selects and times out — it cannot be built for wasm until the row exists,
so the first slice must carry that program as its own witness.

## JSPI support (primary sources, read 2026-10-18)

MDN browser-compat-data, `webassembly/api/Suspending.json` on `main`, with
release dates from the same repo's `browsers/*.json` and Mozilla's
`firefox_versions.json`:

| engine | first version | released | status today |
|---|---|---|---|
| Chrome / Edge / Opera (desktop, Android, WebView) | 137 | 2025 | shipped (Chrome Status: origin trial 123-136, shipping 137) |
| Firefox (desktop, Android) | 153 | 2026-07-21 | shipped; 153 is the current ESR |
| Safari (macOS, iOS, WebView iOS) | 27 | 2026-09-14 | shipped; older iOS stays without it |

Implication: the fallback is for the tail (iOS < 27 and any pinned
browser), not the common case. The page picks at load time by
`typeof WebAssembly.Suspending` and fetches ONE of two artifacts (below).

## One binary or two: two

A single `.wasm` that serves both hosts would be the asyncified one, and a
JSPI host would then pay for instrumentation it never uses: asyncify's
checks sit at every call site of every instrumented function and cannot be
switched off at run time. That is exactly the "asyncified" rows above,
which were run WITHOUT ever unwinding (the same state a JSPI host would be
in):

| artifact a JSPI host would load | size | fib path |
|---|---|---|
| clean (`app.wasm`) | 31,876 B | 131-134 ms |
| the single asyncified binary | 44,060 B (+38%) | 251-264 ms (1.9x) |

So: TWO artifacts from one link. The clean one carries `avra_park` as an
import for `Suspending`; the fallback is the same link plus the asyncify
pass over the `parks` slice, BUILT BY DEFAULT for a web target;
`--no-wasm-fallback` opts out. Default-on, because off-by-default would
break a page silently on iOS 26 and older unless its author knew to ask.
The fallback costs build time and server disk only: it is fetched on
demand, so JSPI users pay nothing. The measurement above is the asyncified-vs-clean gap on real Avra
output; the JSPI-only binary is by construction the clean row.

## The may-park set

`compiler/cancel_reach.av` already computes it: per fn, `parks` (reaches
a wait here or in a callee), `spins` (a `while` back-edge, a cancel point
only), and `links` (KNOWN to reach a row, never through a value). A call
through a value is "may reach" in the pass already, which is exactly
asyncify's conservative indirect-call rule.

- The onlylist is the fns with `parks`, not `spins` — a spin is a cancel
  point and never suspends. No new analysis; one projection of the pass
  to the wasm backend's symbol names.
- The cut leaves the whole closure-call graph in whenever a task body
  calls through a value. That is the 37-38% above, and it is what an
  unscoped pass costs. A tighter slice comes from typing, not from
  asyncify: a task body whose closures are known to be non-parking.

## Owed (the slices, in order)

1. `avra_park` as the single wait row in `rt_sigs`; native keeps today's
   fiber body behind it. Wasm gets a body that calls the host import.
2. Wasm scheduler object: gates, timers, cancel, join, with no stack
   switch; `spawn` through the host.
3. JS host: `Suspending` binding, the asyncify driver, feature detection,
   the two-artifact fetch.
4. The compiler hands the `parks` set to the wasm link for the fallback.
5. A task-using program test, run under node JSPI and under asyncify, eval
   == wasm. This is the missing real measurement.

## The split of `avra_fiber.c` (slice 1) — what the review must decide

Read of the file, 2026-10-18. The single suspension point already exists:
`avra_wait_park` ends every wait row, and its one OS-dependent step is
`run_next()` -> `switch_to()`. So slice 1 adds no `rt_sigs` row. It splits
the file behind a small port (`switch_to`, `now`, `idle_wait`, `stack_get/put`,
`poll_wake`): the pure scheduler (waiters, filing and claiming, the deadline,
choosing, waiting, a task's life, the shield — about 60%) compiles for wasm;
the switch (L52-155), time, the poller, stacks, the guard and the listing stay
native-only. The tangles that make this a review and not a mechanical move:

1. **The data carries the OS.** `Fiber` holds its stack (`sp`, `floor`,
   `base`, `guard`, `wide`) and a waiter's `on` is a union of `fd`, `timer`,
   `gate` and `sig`. The port needs these behind an opaque stack sub-record
   and the fd/sig arms compiled out on wasm, or the pure part cannot name
   its own structs.
2. **Evaluator tasks** (L2897-3098) are *virtual fibers* (`fiber_new(NULL,
   1)`) sharing the policy: `next_with_world` asks the evaluator's machine
   (`g_vnext_asking`) who runs next and traps if a compiled task meets one.
   They need no switch, but they are entangled with `run_next_with_world`.
   Proposal: they stay in the pure part (they ARE the policy's second
   client) and the wasm build never creates one; a keeper asserts the wasm
   archive references no `avra_vtask_*` caller.
3. **The seeded order** (L3098-3171) is a test instrument: it draws the next
   turn from a schedule, holds `avra_tick` raised (an atomic the cold side of
   every checked back-edge reads) and calls `poll_counted`. The pure part
   needs the draw; the tick and the poller coupling are OS. On wasm the seed
   stays usable (it is how the 4-engine witness plan gets determinism), so
   `avra_tick` must exist there as a plain flag the host sets.
4. **Preemption — choose a source for the tick.** Native cancel points on
   loop back-edges read `avra_tick`, which a timer signal raises. A wasm page
   has one thread, so nothing can set a flag while wasm runs. Two sources:
   - **(a) A compiler-inserted BACK-EDGE BUDGET.** Each loop back-edge counts
     down and calls the scheduler's cold side at zero. Deterministic (the same
     program yields at the same iteration on every engine, which also makes a
     seeded schedule reproducible), no timer, and the same on EVERY target, so
     `within` and cancel cut pure compute everywhere, wasm included.
   - **(b) A Worker and a SharedArrayBuffer.** Where the page is cross-origin
     isolated, the app runs in a Worker and the main thread raises the tick
     with `Atomics`. Real-time, no per-edge arithmetic beyond today's byte
     read, but it exists only where isolation does, and then only on wasm.

   **Pick (a), universal; (b) is an accelerator for a later slice.** Cost,
   measured (wasm32 -O2 via binaryen 133, node 24.19, best of 7; a floor, since
   real bodies are heavier than these):

   | check | tight loop (4e8 iterations) | recursion (fib 40) |
   |---|---|---|
   | none | 286 ms | 280-289 ms |
   | flag byte load (today's native check, never raised) | +15% | n/a |
   | loop-local counter, check every 2^20 | +20% | n/a |
   | global budget, decremented at each edge or entry | +23% | 2.96x |
   | **strip-mined loop**, N = 256 / 1024 / 16384 | **+4.3% / +4.9% / +3.5%** | n/a |
   | depth parameter, check when `depth & 1023 == 1023` | n/a | +47% |

   **Loops are STRIP-MINED.** The compiler splits a hot loop into an inner
   run of N iterations with NO check (the body optimises as it does today) and
   an outer step that takes the budget down by N and checks once. The check's
   cost divides by N: +3.5% to +4.9% on the tightest loop there is, against
   +20% for a per-iteration check. The residue is the inner loop's variable
   trip count (`min(i + N, n)`); a loop whose count is known stays one loop.
   A seeded schedule stays reproducible, because the budget is counted in
   iterations, not time.

   **Recursion has no cheap exact check.** A call-site counter is a memory
   decrement on a body of a few instructions (2.96x on fib, native 331 to
   845 ms: the cost is the counter, not wasm). Gating on depth is cheaper
   (+47%, one extra argument and a mask) but only bounds DEEP recursion: fib
   never goes past depth 40, so it would never yield. Neither is shipped as
   the universal cost. The rule: pure recursion that neither loops nor
   waits is cut by (b) where the page is isolated, and otherwise at the next
   park or loop (cooperative); `within` around such a body fires when it
   returns. Deep recursion is bounded by the engine's own stack limit
   already. Revisit if a real program shows a pure-recursion hot spot that
   needs cancel.

5. **The case runner** (L3171-3797) and the listing (`avra tasks <pid>`) are
   native-only test and tooling surfaces; excluded.
6. **Cores and the offload threads** stay out (`avra_cores.c`, F4).
7. **Footprint D1** (a program that neither spawns nor waits links no
   scheduler object) must hold after the split: the new `avra_sched.o` must
   not become reachable from `avra_runtime.o`. `make footprint` is the keeper.

## What the first slice found (landed as `ui-sched-port`)

- **A shadow stack per task.** A JSPI stack holds wasm frames, but a C
  function's address-taken locals and spills live in linear memory, on the
  one stack `__stack_pointer` names. Two tasks interleaving on it overwrite
  each other's frames. So every hosted task owns a shadow stack
  (`HOSTED_STACK`, malloc'd at its first run), the stack pointer is saved
  before a handover and restored when the thread comes back, and a fresh
  task's entry sets it to the top of its own before anything else runs.
- **The archive's first member is `avra_runtime.o`.** The program imports
  every runtime row from `avra:rt`; a member that names the same row plain
  (`env`) while the row is still undefined is `import module mismatch` at
  the link (seen on `avra_trap`). The linker takes members in archive order,
  so the object that defines the rows goes first (Makefile).
- **One translation unit, byte-identical native code.** The seam is `#if
  AVRA_HOSTED` inside `avra_fiber.c`, not a file split: the native
  scheduler object disassembles identically to main (arm64 and x86_64), so
  the hot path gained no call. The file split can follow the same seam.

## Witness plan for the open items

Every test below is a program test run four ways: evaluator, native,
wasm under JSPI (node `--experimental-wasm-jspi` until it is unflagged),
wasm under asyncify; the four outputs must agree. Each gets a mutation
(the check removed, in `runtime/tests/mutations.py`'s style) that must turn
it red, so none is green by accident.

**Cancel and `within` across an unwind (first):**

1. `cancel_parked`: a task parked on a gate is cancelled. Asserts it
   resumes AT the park with `Cancelled`, its `defer`/`errdefer` ran exactly
   once, and nothing after the park ran. Mutation: the cancel flag is not
   read at the resume point.
2. `cancel_beats_ready`: the gate is woken and the cancel arrives in the
   same turn, before the resume. Asserts cancelled, not delivered (the
   native rule of 0e1126a2, "a cancel outranks a task's own ready arm").
3. `within_cuts_park`: `within(ms(50))` around a park on a gate nobody
   wakes. Asserts the timeout answer at a virtual 50 ms, and that the
   task's stack is released (the live-task count reads 0 after).
4. `within_nested_deep`: two nested `within`s, the inner shorter, parked
   200 frames deep. Asserts the inner scope times out, the outer
   continues, defers run inner to outer.
5. `cancel_deep_stack`: a park 2000 frames deep, then cancel. Asserts the
   stack unwinds whole and live bytes return to the baseline
   (`AVRA_MEM_STATS`).
6. `select_with_cancel`: a `select` over a channel, a timer and a cancel
   arm; each arm wins in its own run. Asserts the winner and that the
   losers' parks are released.
7. `join_after_cancel`: joining a cancelled task answers `Cancelled`, and a
   second join agrees.

**JS on the stack between a park and its entry:**

8. `host_reentry_refused` (a host test, JS side): a task parks inside a
   call that the page's JS callback made into the program. Asserts the
   runtime answers one NAMED voice (the engine's `SuspendError` mapped to
   it), never a hang and never a bare engine error.
9. `echo_starts_fresh_turn`: its positive twin. A UI echo handler that
   spawns and parks works, because each echo enters through a fresh
   `promising` call.

**Stack size:**

10. `task_recursion_depth`: recursion 10,000 deep inside a task succeeds
    under all four. Recursion past the shared budget traps with the SAME
    voice under all four (not a bare `RangeError`). The first run records
    each engine's actual limit in this doc, replacing a guess.

**Artifact choice (the load path):**

11. `artifact_picks`: the page host test run twice, with and without
    `WebAssembly.Suspending` defined. Asserts the right artifact was
    fetched, and the clean artifact exports no `asyncify_*` symbol
    (a size keeper: a clean build that grew them is red).

## The module exports nothing of the scheduler

The host calls back into two scheduler fns: the entry a fresh task starts
at and, for the fallback, the allocator of an unwind buffer. Neither is an
export. Each port call (`switch`, `idle`) passes them as FUNCTION-TABLE
INDICES, and the host reaches them through `__indirect_function_table`,
which every wasm link exports (`-Wl,--export-table`). An export is a root
the linker keeps whether or not anything reaches it; an address taken inside
a reachable fn is kept exactly when that fn is. So a page that neither
spawns nor waits links no scheduler, whatever its units' members carry: the
linker's own GC is the reachability. The runtime's two settings readers
(trace, tick) run lazily at the scheduler's first start on a hosted target,
for the same reason: a constructor is a root too. `make ui-board` counts the
board's `avra_host` and `path_open` imports and refuses any.

## Open

- Cancel and `within` across an unwind: the cancel flag must be observed
  at the resume point, and a deadline task must be able to cut a parked
  stack. Scheduler-side; witnessed by tests 1-7.
- JSPI traps if JS is on the stack between the park and the promising
  entry; the host must never call a task entry from a JS callback that the
  task itself called into. UI echoes are fine (they start fresh turns).
  Tests 8-9.
- Stack size: a JSPI stack is the engine's; `AVRA_FIBER_STACK` has no
  meaning there. Deep recursion inside a task is the engine's limit.
  Test 10 turns the guess into numbers.
