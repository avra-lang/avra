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
   without JSPI (Safari/iOS 26 and older, older Firefox). The same
   `.wasm` ships; the fallback is a post-link pass and a 40-line JS driver.
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
browser), not the common case. The runtime picks at load time by
`typeof WebAssembly.Suspending`; the page loads one module either way.

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
3. JS host: `Suspending` binding, the asyncify driver, feature detection.
4. The compiler hands the `parks` set to the wasm link for the fallback.
5. A task-using program test, run under node JSPI and under asyncify, eval
   == wasm. This is the missing real measurement.

## Open

- Cancel and `within` across an unwind: the cancel flag must be observed
  at the resume point, and a deadline task must be able to cut a parked
  stack. Both are scheduler-side; neither is designed here.
- JSPI traps if JS is on the stack between the park and the promising
  entry; the host must never call a task entry from a JS callback that the
  task itself called into. UI echoes are fine (they start fresh turns).
- Stack size: a JSPI stack is the engine's; `AVRA_FIBER_STACK` has no
  meaning there. Deep recursion inside a task is the engine's limit.
