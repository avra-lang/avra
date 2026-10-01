# Fibers — Axis 18 built

The spec decided the language (FULL_SPEC Axis 18): Go-style green
threads, no `async`, no function colouring. `spawn { }` makes a
`Task<T, E>`; `.await` answers `Result<T, E>`; I/O that would block
parks the fiber, not the thread. This doc decides how it is BUILT.
Wanting site: `@std/http`'s server, where one slow handler stalls
every connection (ROADMAP "AXIS 18", avra-8sb5.10.1).

## 0. Decided (owner, 2026-09-22)

- EVERY BLOCK IS A SCOPE. A task is joined at the `}` of the block
  that spawned it; a failing block cancels its children. A `Task`
  escaping its block is refused. Longer lives spawn INTO an owner
  value (`server.spawn { }`). Nothing spawns into nowhere.
- EXACT FRAMES WHERE PROVABLE: a body with no recursion and no
  dynamic call gets a frame sized from the call graph; everything
  else a guarded stack.
- PARALLELISM IS SUGGESTED, NEVER SILENT: independent calls earn a
  hint with the `all { }` fix. Automatic only for PROVEN read-only
  calls, later.
- `avra test` RUNS UNDER A SEEDED DETERMINISTIC SCHEDULER with
  virtual time; interleavings are explored; a failure prints its seed.
- PAY FOR WHAT YOU USE: a program that never spawns or parks links no
  scheduler. Blocking rows go to a helper thread by their effect
  column. Numbers vs Go, tokio and a C loop are published.
- Cancellation arrives only at a pause point, as a failure on the
  `Result` channel; deadlines belong to scopes (`within`).
  `atomic { }` is a region the compiler proves pause-free.
- The worked example is docs/2026_09_22_FIBERS_TOUR.md.

## 1. Shape

- ONE OS THREAD FIRST. Cooperative M:1. A fiber switches only at a
  yield point: `.await`, a parking I/O row, `yield_now()`, `sleep`.
  Non-atomic RC stays sound (spec 18.1: "single-threaded from the
  fiber's perspective"). M:N rides the fork-join campaign's atomic
  retains (docs/2026_09_22_BEND_LAWS_PARALLEL_AND_BEYOND.md §4).
- THE SCHEDULER IS RUNTIME, the language is IR. Runtime C (not
  generated C — P14 holds: the runtime is the one static library).
  Codegen stays LLVM.
- THE MAIN FIBER IS THE OS STACK. `main` runs where it runs today, so
  the compiler (deep recursion) never touches a fiber stack.
- NO TASK OUTLIVES ITS OWNER. `main`'s block is the root scope, so
  the process exits only after every task is joined or cancelled.
- NO SCHEDULER UNLESS USED. The union of reachable bodies (the
  lowering already computes it) decides whether the scheduler links;
  it starts lazily at the first spawn, so an Avra library called from
  C never starts one it does not use.

## 2. Runtime (`runtime/avra_fiber.c`, one header)

- Context switch: hand-written, callee-saved registers only, arm64 and
  x86_64 (`avra_fiber_switch(from, to)`), ~20 instructions each. No
  `ucontext` (slow, deprecated on darwin).
- Stacks: `mmap` a reservation (default 1 MiB, `AVRA_FIBER_STACK`)
  with a `PROT_NONE` guard page below. Pages commit on touch, so an
  idle fiber costs what it touched. Freed stacks go to a warm pool.
  Overflow hits the guard: a `sigaltstack` SIGSEGV handler that
  recognises a guard address traps "a task's stack overflowed"
  (exit 2, `avra_trap`'s contract).
- Run queue: FIFO of ready fibers. One kqueue/epoll owned by the
  scheduler for parked fds and timers.
- Idle: nothing ready -> wait on the kqueue with the nearest deadline.
  Nothing ready AND nothing parked -> trap "every task is waiting —
  deadlock" (exit 2); a join that closes a ring traps at that join,
  whatever else waits. A deadlock is never a hang.
- Rows (`rt_sigs`, the vocabulary seam's DATA shape):
  - `avra_task_spawn(body: ptr) -> ptr` — runs a closure box on a new
    fiber. Answers the TASK box.
  - `avra_task_join(task: ptr) -> ptr` — parks until done. Answers the
    owned answer.
  - `avra_task_done(task: ptr) -> int`
  - `avra_fiber_yield()`
  - `avra_fiber_park_fd(fd: int, writable: int, timeout_ms: int) -> int`
    — parks until ready (1) or the timeout (0).
  - `avra_fiber_sleep(ms: int)`
- A TASK IS A RECORD — a slot array `{fiber, body, answer, done,
  waiters}` the core already reclaims, releasing what it owns — so no
  new kind and no C chain to grow.

## 3. C calls an Avra closure — the one new seam

A closure box is `[code, captures…]`, called with the box at seat 0
(features/closures/mod.av). `avra_task_spawn` calls
`((void*(*)(void*))box[0])(box)` on the new stack. So the LOWERING
guarantees every spawned body has the signature `fn() -> ptr`: the
body answers a managed box (the task's `Result<T, E>` — box it if the
representation is flat). One signature, one C cast, nothing variadic.

BOTH ENGINES USE THE SAME SCHEDULER. The evaluator's arm for
`avra_task_spawn` hands the C row a NATIVE closure (a lambda in
interp.av) that runs the interpreted closure on the new fiber. Each
fiber's interpreted frames then live on that fiber's native stack.
First job of slice F2: prove interp's per-call state is on the native
stack. Any per-machine frame stack is forked per fiber. `eval ==
native == expected` for every task program.

## 4. Language (feature `features/tasks/`)

- `spawn { body }` — a primary. `spawn` is already reserved
  (resolve.av:26), so no program breaks. The block is a closure:
  captures are copies (F3005), `?` and `fail` inside it are the task's
  failure channel.
- `Task<T, E>` — `.await` answers `Result<T, E>`, so `t.await?`
  propagates. `.done` reads without parking. The body's type decides
  `T`, and its failures (or the want) decide `E`. An infallible body
  still answers `Result` from `.await` (the spec's "mirrors Result").
  The lane settles how `E` is spelled when nothing fails, by probe,
  and records it.
- EVERY BLOCK IS A SCOPE (§0). Lowered as the block's frame: the
  join-all at `}` rides the SAME mechanism `defer` does (a `defer`'s
  frame is its statement list), and a failing exit cancels before it
  joins, as `errdefer` runs before `FnExit`. A block that spawns
  nothing lowers to nothing.
- ESCAPE: a `Task` value reaching past its block (answered, stored,
  captured by an outer owner) is refused (F2107 in the tour). An
  OWNER value (`server`, `cluster`, a `Scope`) is the only door to a
  longer life: `owner.spawn { }`.
- CANCELLATION arrives at a pause point as a failure (`Cancelled`) on
  the task's `Result` channel, so `?`, `defer` and `errdefer` already
  handle it. `within d { }` is a scope with a deadline (`TimedOut`).
  `all { }` and `race { }` are scopes whose statements are tasks.
- `atomic { }` — a region the compiler proves free of pause points.
  "May pause" is a fact folded over the call graph like `Reach`
  (a row's column says it parks), never a colour on a signature.
- HINTS (decision 3): two awaited calls with no data dependency earn
  a hint whose fix is the `all { }`. Silent only for PROVEN read-only
  calls, later.
- `yield_now()`, `sleep(ms)` in the prelude floor only if a program
  cannot be compiled without them; otherwise `@std/task`.
- IR: prefer rows over new `Ins` variants (`CallRt` carries value
  runtime needs). An `Ins` is justified only if the memory pass must
  see the fork (it must not: spawn LENDS like a call, join MINTS like
  a call's answer).
- Voices (every refusal a named voice, F-code registered, golden):
  `.await` on a non-task; `spawn` of a body that answers void (answers
  `Task<void, E>`? probe `Result<void,…>`'s F2019 first); a spawn
  body writing a capture (F3005 already speaks).

## 4b. F2c as decided (supersedes §4 where they differ)

- `spawn e` — any expression, a block included: `spawn db.user(id)`,
  `spawn { … }`. `Task<T>`, ONE parameter: the body's answer. `.await`
  answers `T`; a failing body answers `Result`, so `t.await?` reads as
  every other propagation. Cancellation needs no channel in the value:
  it reaches whoever awaits at their OWN pause point (§4).
- A TASK IS JOINED WHEN ITS LAST OWNER ENDS. An owner is a binding or a
  list holding the task; at the owner's scope exit its tasks are
  joined (idempotent — a copy's second join is free). A spawn nobody
  holds (`spawn log(x)` as a statement) is owned by its block. So
  `tasks.push(spawn fetch(u))` in a loop runs concurrently and joins
  where `tasks` ends — never once per turn.
- NO OWNER OUTLIVES ITS BLOCK: a type containing `Task` is refused as a
  fn's or lambda's answer, a record or enum field, a map value, and a
  capture. Passing one to a fn is fine — the callee cannot keep it.
- The joins are EXPLICIT at each owner's scope exit (the `defer` frames'
  second entry kind), never a refcount side effect, so both engines run
  them at the same instruction.
- The evaluator runs every task on its one machine: a task is its own
  call stack, the C policy (§2, `avra_vtask_*`) names the next, and a
  parked instruction re-runs when its task resumes.

## 5. I/O parks

- `@std/net`: a read/write that finds `EAGAIN` parks the calling fiber
  on the scheduler's kqueue (`avra_fiber_park_fd`) and retries. The
  `.Pending` answer stays for the explicit poller API. The
  blocking-looking verbs are the new default.
- `@std/http` server: accept loop on main, ONE FIBER PER CONNECTION,
  handler written synchronously (it already is: `fn(mut A, Request)
  -> Response`). Keep-alive, pipelining and the framing laws are
  unchanged: the per-connection loop is the old per-event logic.
- `@std/http` client: blocking-looking, parks instead of polling
  every 1000 ms.
- THE BAR: the old event loop's numbers (102–118k keep-alive
  requests/s on one core, 8.2 µs CPU/request, HTTP_WORKING.md).
  Fiber-per-connection within 15% of them, with a handler that sleeps
  100 ms no longer stalling the others (the witness: two clients, one
  slow route, the fast one answers first).

## 6. Slices (each: red-team, review-round, gate)

THE HTTP CUT, first: F1, F2 (without `all`/`race`), F4's network
parking only, F5. That is the smallest set after which `@std/http`
serves a connection per fiber and streams. Blocking-row offload waits:
a helper thread minting boxes needs a thread-safe allocator, which is
the cores placement's work.

- F1 runtime core: switch, stacks, guard, run queue, rows, deadlock
  trap. Unchanged by §0.
- F2 language: `spawn`, `Task<T, E>`, `.await`, EVERY BLOCK A SCOPE
  (join at `}`, cancel on failure, F2107 escape), both engines.
- F3 deterministic test scheduler: `avra test` seeds the run queue,
  virtual time, interleaving exploration, a failure prints its seed.
  Early on purpose: every later slice is tested under it.
- F4 parking I/O + blocking-row offload (the effect column); `sleep`;
  timers; `within`.
- F5 `@std/http`: fiber per connection, client parks, the bar above.
- F6 `all`/`race`, channels (18.4), `select` (18.5).
- F7 `atomic { }`, the may-pause fact, `explain --tasks`, the task
  tree, hint H0301.
- F8 exact frames from the call graph; guarded stacks stay the
  fallback.
- THEN the compute placements (§8): the Bend doc's fork-join, kernel
  and cluster campaigns, on this scope algebra.

## 6b. F1 as built (measured on this machine, one core, best of five)

| | Avra | Go 1.25 (GOMAXPROCS=1) |
|---|---|---|
| a switch (two tasks yielding) | 12 ns (x86_64 under Rosetta: 5 ns) | 132 ns |
| spawn + run + join, stack reused | 126 ns | 333 ns |
| spawn + run + join, 10k alive at once | 4–8 µs | 1.3 µs |

- THE RUNTIME IS A LIBRARY (`build/libavra_runtime.a`, one object per
  `runtime/*.c`): a program links only what it reaches, so one that
  never spawns carries no scheduler (measured: 0 scheduler symbols in
  hello-world). THE COMPILER HOLDS EVERY ROW: `avra_rt.h`'s host table,
  generated from `rt_sigs()` and included by the extern host, pulls
  every runtime object into `build/avra`.
- A task is a RECORD (a slot array the core already reclaims); a
  fiber's own record lives at the top of its stack mapping.
- Stacks come a slab of 64 at a time and return to a warm pool with no
  syscall; the pool's cold end gives its pages back only when the
  scheduler is idle. The cold-burst cost is the first-touch page fault
  plus the guard (~2 µs unloaded) — F8's exact frames are what beat Go
  there, since small frames pack into warm memory.
- A FRAME NEVER SKIPS A GUARD: every function Avra emits carries
  `probe-stack`, and C built here probes too, so an overflow always
  lands on the guard page.
- Waiters are filed by DESCRIPTOR AND DIRECTION; readiness wakes one
  and re-arms for the rest. A join that closes a ring traps at once.
- The rows were UNHOSTED until F2 (the two-landing ladder); a
  declaration naming a row is judged by the crossing law, which exempts
  only the rows the evaluator hosts.

### Deadlines F2 and F3 inherit (conditions that expire)

- `ffi.c`'s static staging area is correct only while no extern call
  can switch fibers mid-call. It holds while parking happens in Avra
  code between extern calls; the first extern that parks inside C
  expires it — then the frame is per fiber.
- Closing a descriptor a task is parked on must wake that task (and
  clear its waiters) — otherwise it waits forever, or wakes on the next
  descriptor to reuse the number. F3's close row owns this.
- The evaluator must run each interpreted task on its own native fiber
  (§3); per-machine interpreter state that is not on the native stack
  must be per fiber.

## 7. Recorded, not built

- Preemption at call safepoints (spec 18.1): the trigger is the first
  CPU-bound handler measured starving a server.
- M:N: rides atomic retains (Bend doc §4.4–4.5).
- Growable stacks: the trigger is a measured program overflowing the
  default reservation on real work. PROBED AND NOT MET (2026-10-01,
  avra-8sb5.1.24.7): the one overflow measured on a real server —
  `Inbound.wire_read` (h2_serve.av) adding a frame per bell-wake — was
  unbounded RECURSION, a defect, and is fixed by waiting in place
  (f5ce1ef), not by a bigger stack. With that fix every h2 program fits
  `AVRA_FIBER_STACK=65536`, and the default 1 MiB reservation is
  unchanged. Growable stacks stay unbuilt until real work overflows.

## 8. One scope algebra, four placements

A scope is a scope wherever its work runs: join at `}`, cancellation
at a pause point, deadlines, `all`/`race`, the task tree and the
deterministic test mode hold for every placement. What differs is the
PROOF the compiler demands before work may go there.

| placement | spelled | proof demanded |
|---|---|---|
| fiber | `spawn { }` | none: copies cross, `atomic` guards |
| cores | `parallel { }`, `par for` | the fork law: no world reach, no `mut` capture |
| vector / device | `par for` over the kernel fragment, `on .gpu { }` | flat numbers, no allocation, no recursion |
| nodes | `cluster.spawn { }`, `on rank(r) { }` | every crossing value is plain data |

- PLACEMENT IS A SCOPE PROPERTY, like a deadline. Unpinned work is
  placed by the cost model; `explain` prints every decision; `on`
  pins it (P7, P8).
- A REDUCTION TREE IS FIXED BY THE DATA, never the worker count, so a
  float sum is bit-identical on one core or a cluster. A `law`
  proving associativity licenses reshaping it.
- `durable "name" { }` checkpoints at its `}` per iteration; a failed
  child (dead node, straggler's `TimedOut`) restarts from the last
  checkpoint. Elastic training is cancellation plus a durable scope.
- Worked programs: the tour's Part II. Campaigns and slices:
  docs/2026_09_22_BEND_LAWS_PARALLEL_AND_BEYOND.md §4, §5, §7.

## 9. Where this departs from FULL_SPEC Axis 18

- 18.7 `scope concurrent { }` -> EVERY block is a scope; no keyword.
- 18.2 `Task.all/race/any([..])` -> `all { }` / `race { }` scopes.
- 18.1 preemption at call safepoints -> cooperative, with `atomic`
  proven and preemption a recorded trigger (§7).
- 18.3 `spawn cpu { }` -> placement is a scope property (`on .cores`).
- NEW: deterministic test scheduler, `atomic`, hints, exact frames,
  pay-for-what-you-use, fixed reduction trees, `durable`.
- The tour's `Task<T, E>` -> `Task<T>`: a failing body answers
  `Result<T, E>`, so the error side rides the answer and `t.await?`
  propagates like any `Result` (§4b).

## 10. As built (F2)

- A task's body is a TASK LIFT: the lambda `spawn` builds, lifted to
  answer a one-cell list, so C calls ONE signature whatever the answer
  (`void` leaves the list empty).
- OWNERS: a `Task<T>`, a `Task<T>?` (the niche — absence joins
  nothing) and a `List<Task<T>>`. The join is a `Deferral.Settle`
  entry in the `defer` frames, so both engines run it at the same
  instruction. Every other holder is F2107.
- F2107 refuses a task in an answer (a fn's, a method's, a lambda's,
  a task's own), a record field, an enum payload, a generic slot, a
  lambda VALUE's capture (a task's own body may capture a sibling: it
  is joined in the same block), a holder no block joins (`Map`,
  `Cell`, a list of lists), and a WRITE over a task (reassignment, an
  index write, `set`), which would orphan it.
- An owner type (`server.spawn { }`) is the only planned door to a
  longer life; until it lands, a task's answer is what leaves:
  `t.await`.

## 11. As built (parking I/O)

- `@std/net`'s plain verbs PARK: `accept`, `read` (answers `Bytes?`,
  null at EOF), `write` (all of it), and `connect` (its timeout spans
  every resolved address). Their `try_` twins never wait and keep
  `.Pending`/`0`/null for a poller loop. The wait is Avra's, through
  `avra_fiber_park_fd`, never C's: the evaluator runs the same C
  in-process and parks its tasks virtually.
- A CLOSE NEVER STRANDS A WAITER: `avra_fiber_fd_closing` readies every
  task parked on a descriptor before it closes, and each retry reports
  the closed descriptor.
- `@std/time.sleep(d)` parks the calling task on the scheduler's timer.
- Per-call timeouts are not parameters: the `within d { }` scope
  carries one deadline for every park inside it (§12).

## 12. As built (F5 — @std/http, one task per connection)

- DEADLINES ARE A SCOPE, NEVER A PARAMETER (P6). A timeout parameter is
  explicit at one call and threads by hand through every layer; a callee
  the caller does not own (a handler's query) cannot inherit it.
  `within d { … }` is both: lexically visible, and every park inside —
  in this task or one it spawns — ends by it. Nested scopes take the
  earlier deadline; the block restores the outer one however it exits.
  A park past it fails its verb (`NetError.timed_out()`); `sleep` is
  unaffected until F4 brings cancellation at every pause point. The head
  is a `Duration`: `within` is `@std/time`'s component, and its template's
  typed `limit` says so ("`limit` declares `Duration`, this is `int`").
  One mechanism for the concept: @std/process's
  `within:` parameters were renamed `limit:`, and moving them onto the
  scope is recorded.
- `Tasks` IS THE OWNER A LOOP THAT NEVER ENDS NEEDS. `Tasks.new()`,
  `owner.push(spawn e)`: answers are discarded, and a full owner sheds
  its finished tasks before it grows (O(1) amortized — 2M tasks through
  one owner peak at 25 MB). It is an owner under the task law: joined
  where its binding ends, refused in a field, an answer or a capture.
- THE SERVER: `run` accepts on the calling task and spawns each
  connection; `stop` closes the listener. Each connection holds its OWN
  COPY of the application: a plain field is that connection's state,
  and shared state is a `Cell` the application declares. The framing
  laws are the old loop's, unchanged. The client parks under `within`.
- THE POLLER REGISTERS ONCE, EDGE-TRIGGERED, and caches readiness: an
  edge sets a direction's bit, a short read or a park clears it, and a
  read whose socket is known drained parks before reading. A peer's end
  is STICKY readiness, or a FIN landing with the last bytes is never
  seen (std-net's `parked_eof`, witnessed stalling without it). It holds
  while every close of a parkable descriptor goes through
  `avra_fiber_fd_closing`.
- MEASURED on a Linux Sprite (8 × EPYC, server pinned to one core, wrk
  on the rest; `tools/bench/wrk.sh`, `FLOOR=1` for the C floor):

  | | keep-alive c=50 | c=200 | c=1000 | pipelined ×16 |
  |---|---|---|---|---|
  | old event loop | 39.4k | 35.6k | 33.8k | 167k |
  | task per connection | 41.9k | 41.5k | 36.0k | 164k |
  | C floor (epoll, read + write only) | 65.4k | 65.5k | 60.9k | 1.03M |

  Syscalls per request match the floor (one read, one write). The gap is
  user space — about 5 µs a request against the floor's 1 µs
  (`tools/bench/request`): immutable values copied instead of reused.
  That is the reuse-in-place campaign's, not HTTP's.


## 13. As built (cores — @std/http on every core)

- ONE PROCESS PER CORE, SHARING NOTHING (P6: the thread-vs-process
  choice dissolves once nothing is shared — then a process IS the
  thread-local runtime, with the kernel as the isolation proof). Every
  global the runtime holds (`g_current`, the free lists, the poller, the
  timer heap, the descriptor table) stays a plain global. Measured on
  the Sprite (x86-64, the runtime's `-fPIC` archive): a free-list take
  + give costs 3.1 ns as a global and 6.0 ns as `__thread` (every
  access through the TLS resolver), and every allocation pays it; a
  fork costs 2.5 ms with 64 MB touched, once at start. Threads return
  with the fork campaign's atomic retains (§1), for work that SHARES.
- ONE LISTENER, FORKED: the cores accept from one queue. SO_REUSEPORT
  measured no better on the C floor (below, within noise at every N),
  and it would weaken the listener's refusal of a second binder
  (std-net's `net_bound`).
- `runtime/avra_cores.c`: a GROUP is a private record, one shared page
  of slots (a core's live count, what it accepted, its errno), and
  pipes that carry no bytes. The supervisor holds the ONE stop pipe's
  write end: closing it — or dying — is end-of-file in every core. Each
  core holds the write end of its OWN pipe, closed by the kernel however
  the core ends, so the supervisor parks on it and learns of a crash
  without a signal handler. A core keeps the calling task alone
  (`avra_fiber_forked`) and closes every descriptor but the standard
  three, the listener and its two pipe ends; buffered output is flushed
  before the fork, so nothing prints once per core.
- A CELL IS PER CORE, AND THE TYPE SAYS SO (owner, 2026-09-23): the
  server takes a MAKER, run once on each core — `served(l, () -> App {
  hits: Cell.new(0) }, …)`. Its seat is `isolated`: a fn that shares
  nothing with its caller. F2111 refuses a lambda there that captures an
  identity (a `Cell`, a task, a pointer, a fn value, a `dyn`, a type
  parameter — or a record or enum holding one), and a fn VALUE whose
  captures are unknown; a declared fn and an `isolated` parameter pass
  on. The promise is `SeatMark.unshared`, so it rides the fn type: a fn
  with an `isolated` seat does not fit a fn type promising none.
  Cross-core shared state (`Shared<T>`, atomics) is a later slice.
- ONE SPELLING: `s.run()` serves on every core this process may run on
  (its affinity mask); `s.run(cores: 1)` serves on the calling task with
  no process of its own, as F5 did. The default needed F2104 narrowed:
  a default whose seat names no type parameter is one body even in a
  generic fn (and a generic call now unifies only the seats it writes).
- A CORE THAT CRASHES STOPS THE SERVER (fail-fast): placement never
  changes what a program means, so a trap on one core of four ends it as
  it would on one. The rest are told to stop, drain their connections,
  and `run` traps "core i of n ended with status s — the server
  stopped" (or "was killed by signal k"). Restart is policy for a
  process manager above, which sees the exit. A core whose accept FAILS
  (not a crash) answers `run`'s `Err`. `stop` (or the supervisor dying)
  reaches every core.
- MEASURED on a Linux Sprite (8 × EPYC; the server on cores 0..N-1, wrk
  on the rest; `CORES=N sh tools/bench/wrk.sh`, `FLOOR=1` for the C
  floor, forked N ways the same way):

  | req/s | N | keep-alive c=50 | c=200 | c=1000 | pipelined ×16 |
  |---|---|---|---|---|---|
  | Avra | 1 | 43.8k | 42.6k | 35.5k | 151k |
  | Avra | 2 | 86.7k (1.98×) | 85.3k (2.00×) | 73.2k (2.06×) | 294k (1.95×) |
  | Avra | 4 | 165k (3.77×) | 184k (4.31×) | 161k (4.55×) | 592k (3.92×) |
  | C floor | 1 | 73.3k | 70.7k | 61.4k | 1.08M |
  | C floor | 2 | 143k | 143k | 129k | 2.14M |
  | C floor | 4 | 261k | 264k | 254k | 3.21M |

  Within 10% of linear at 4 cores in every column. Server CPU per
  request does not move with N (23 µs keep-alive, 6.7 µs pipelined), so
  the scaling is the kernel's; the gap to the floor is the per-request
  user space (reuse in place, §12). At 4 cores the floor's pipelined
  column is wrk-bound (4 generator threads), not server-bound.
- RECORDED, NOT BUILT: `isolated` is spelled on a declared fn's seats
  (`fn`, `static fn`, `mut fn`) — a lambda's, a trait's and a fn TYPE's
  cannot spell it yet; `@std/meta`'s `Param` does not carry it across
  the derive crossing; a descriptor held as an `int` inside a captured
  record is closed in each core, so its use fails loud (EBADF) rather
  than sharing. The ELF link now puts the runtime archive LAST, so a
  member only a package object reaches is not dropped.
