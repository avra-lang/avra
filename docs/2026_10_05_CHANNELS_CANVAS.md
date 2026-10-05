# FLOW — the canvas

Every site in the tree that hand-rolls a stream, a queue, a poll
loop, a callback registry, a readiness wait, a retry loop, a pipe or a
producer/consumer pair, and what it becomes under
docs/2026_10_05_CHANNELS.md. "Slice" is that doc's §14.

Surveyed by grep and reading on `bd36bf7` (this worktree), `ui-dev`
`faf9ddb` for `avra dev`, and `../avra-os-watch` (staged) for the
watch. Line counts are of the hand-rolled machinery, approximate.
UNREAD marks a body that was outlined by grep and not read; the
estimate for such a row is a guess.

Paths are under `packages/` unless they start with `runtime/` or
`tools/`.

## 1. The runtime

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `runtime/avra_fiber.c:149-170` run queue | intrusive FIFO of ready fibers | unchanged | 0 | — | — |
| `:201-273` timer heap | one entry per fiber: `Timer{at, seq, fiber}` | one entry per REGISTRATION; a fiber may hold several | 0 (grows ~30) | a stale timer firing for a task that woke on another arm: clear the whole set on wake | 1 |
| `:287-372` `FdWaits` | waiter lists per descriptor and direction | unchanged; a waiter entry gains its key | 0 | — | 1 |
| `:376-425` `fd_ready` | wakes every waiter in that direction | unchanged (level-triggered: a waiter that loses re-parks) | 0 | — | — |
| `:549-610` `next_ready` | traps "every task is waiting — deadlock" | the same trap, printing each task's signals | 0 (grows) | — | 4 |
| `:680-752` join | a task files itself on the joined task's waiter list | a task is a `Wait` whose signal is its done gate; `avra_task_join` calls the wait rows | ~40 | the join-ring check must survive | 2 |
| `:802-845` `avra_fiber_sleep`, `avra_fiber_park_fd`, `fd_interrupt` | three parking rows, each its own wait; sleep and join ignore the deadline | callers of `avra_wait_on` + `avra_wait_park`; the rows stay until their callers move | ~30 | two-landing law for the new rows | 1, then 4 |
| `:869-945` `avra_vtask_*` | the evaluator's twin of every row above | gains twins of the wait rows | 0 (grows ~50) | `eval == native` on arm choice: rotation, no RNG | 1 |
| `runtime/avra_cores.c:82-98,196-203` stop pipe | a pipe whose EOF means "stop"; `stopped()` reads a byte | a source that ends; the supervisor selects over every core's end | ~30 | a fork after the scheduler starts (`avra_fiber_forked`) | 9 |
| `:229-244` per-core end pipe | EOF is the core's death notice | `core.exited()`, a source of one | ~20 | — | 9 |
| `:42-46,206-215` shared `Slot` page | atomic counters in a shared mapping | stays; the cores home's ring is its sibling | 0 | — | 9 |
| `runtime/avra_runtime.c:3247-3300` `avra_fd_read`/`write` | EINTR loops, `-EAGAIN` | unchanged: the never-waits half of a `Wait` | 0 | `:3839`, `:3867` `waitpid` sites UNREAD | — |
| `std-avrac/src/compiler/backend/interp_tasks.av:20-32,93-118` | `Job{waiters, done, answer}`: a second hand-rolled future | a task's done gate, shared with native | ~45 | the evaluator re-runs a parked instruction on wake | 2 |
| `interp_tasks.av:155-235` | park rows re-run on wake; `resume_next` | hosts the two wait rows the same way | 0 (grows) | — | 1 |

## 2. `@std/net`

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-net/src/net.av:919-1011` + `c/std_net.c:289-327` `Bell` | a pipe pair, a `parked` flag, a ring counter; two descriptors each | a `Gate` and a counter; the API holds until its callers are channels | ~110 | `Bell {}` as a literal with a lazy pipe must keep working | 1 |
| `net.av:1016-1021` `unopened` | sleeps 10 ms so a waiter cannot spin | gone with the pipe | 6 | — | 1 |
| `net.av:253-259` `Listener.accept` | try, park, recurse | `wait(self)`; a listener is a source of `Conn` | 5 | recursion per wake was a real stack overflow once (fibers §7) | 2 |
| `net.av:294-305` `Conn.read` | ready check, park, try, park, recurse | `wait(self.readable())` then the read | 8 | `parked_eof` edge: a peer's end must still wake | 2 |
| `net.av:309-317` `Conn.write` | `try_write` loop, park on 0 | `wait(self.writable())` in the loop | 4 | — | 2 |
| `net.av:685-755` `Race` | a PRIVATE poller, parked through its descriptor, a staggered dial timer, first success wins | `select` over the dials and `after(stagger)` | ~60 | happy-eyeballs ordering must hold | 2 |
| `net.av:414-436` + `c/std_net.c:329-420` `Poller` | a user-facing second kqueue/epoll, blocking `avra_net_wait` | retire: `select` is the poller | ~110 | public API: check for callers outside the tree first | 2 |
| `net.av:596-611` `looked_up`/`awaited` | park on the lookup's pipe with a hand-kept deadline | `select { a in lookup -> …  after(left) -> … }` | ~12 | — | 2 |
| `c/std_net.c:487-735` DNS on a pthread | `getaddrinfo` on a detached thread; wakes through a pipe byte | stays: a thread cannot touch a gate. The pipe is the thread-to-task crossing | 0 | — | — |

## 3. `@std/http`

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-http/src/server.av:695-860` h2 conversation (`talked`, `waited_on`, `bell_waited`, `stall_left`) | a reader task, per-stream handler tasks and a framer meet at ONE `Bell`; every wake rescans every line; four deadlines computed by hand into one timeout | `select` over the inbox, the replies channel, each window's opening, `after(idle)`, `after(stall)` | ~170 | the largest and most load-tested code here; the h2 conformance rows must stay green | 3 |
| `server.av:980-1024` `Inbox`, `read_beside` | `Cell<Inbox>` appended by the reader task; blocks at 256 KiB by waiting on the bell | `channel<Bytes>(n)` with the reader task as its one writer | ~35 | the bound is in octets, the channel's in items: capacity by weight is a want (below) | 3 |
| `server.av:976,787,1039` `Line.reply: Cell<H2Reply?>` | a one-shot slot a handler sets, then rings | the handler's `Task<H2Reply>` as an arm | ~40 | — | 2 |
| `h2_serve.av:173-262` `Inbound`, `stream_body` | a one-slot mailbox behind a fake `Transport`; reader parks on the bell | a `Source<Bytes>` per stream; the body reads it | ~90 | window is given back only for octets TAKEN (framing laws §5.5): the take must do it | 6 |
| `server.av:158,273,632-661` `Drain` | `reading: List<bool>` by descriptor so `stop()` can interrupt each parked reader; every wait clipped by hand | a stop on the server's scope: every wait hears it | ~45 | graceful drain ordering (GOAWAY, linger) | 4 |
| `server.av:321-324,393-403` `stopped_with`, `core_ended` | `while flag != 0 { park_fd }`, one task per core as a wait-any | one `select` over the cores' ends | ~20 | — | 9 |
| `server.av:293-304` accept loop | `conns.push(spawn self.connection(c, app))` | `for c in listener { conns.push(spawn …) }` | 3 | — | 2 |
| `server.av:422-450` h1 connection loop | frame, flush, `within` read, keep-alive | unchanged in shape; its read is a `wait` | 0 | — | — |
| `server.av:578-590,914-945` `pumped`, `h2_pumped` | pull a piece, write it, `sleep(ms(0))` to yield | `for piece in body { write }`; the write parks | ~35 | "one piece per stream in memory" (framing laws §6) | 6 |
| `server.av:1065-1072` `lingered` | bell wait until a deadline | `select { _ in inbox -> …  after(linger) -> … }` | 8 | — | 3 |
| `http.av:354` `Stream { pull, length, ended }`, `Pulled` | outgoing body: a record of closures | `Stream<Bytes, E>`; `length` rides the response | ~40 | public API in every handler that streams; a bridge release | 6 |
| `body.av:51-304` `Body`, `Inflow`, `Pull`, `next_piece`, `listened` | incoming body: a `Cell` state machine, refill loop, per-read patience | a `Stream<Bytes, BodyError>` over the connection's source; patience is a `within` | ~150 of 300 | the framing state machine stays; only the waiting goes | 6 |
| `body.av:371,397` `all_of`, `skipped_in` | gather-all and skip-to-end loops | `.list(max:)`, a fold | ~30 | — | 6 |
| `fetch.av:80,523` `Payload.Stream(next: fn() -> Bytes?, …)` | a THIRD pull shape, for uploads | `Stream<Bytes>` | ~20 | — | 6 |
| `sse.av:31-115` `Source`, `Next`, `Resume` | a record with `next: fn(Duration) -> Next`; `Quiet` becomes a keep-alive | `Source<Event>`; quiet is `after(quiet)` in the writer's `select` | ~50 | name clash: this `Source` is retired, not renamed | 6 |
| `sse.av:193-258` `Feed` | a ring log, a cursor per observer, a bell | a channel with `readers: .each, keeps: .last(n)` | ~65 | "an expired cursor is told" must hold | 6 (terms from 10) |
| `sse.av:161` writer loop | `while true` (UNREAD) | a `for` over the source | ? | UNREAD | 6 |
| `ws.av:207-345` `receive`, `frame`, `Pending` | frame loop, fragment reassembly, ping/pong inline | a `Source<Message, WsError>`; reassembly stays | ~40 of 150 | close codes are protocol law | 6 |
| `ws.av:258,383,416` close wait, drain | readiness waits with patience | `within` + `wait` | ~25 | — | 4 |
| `pool.av:67-178` `Pool` | lend/keep counts; a waiter parks on `freed` and recursively re-checks until its deadline | a channel of idle carriers per origin; `take` is `select { c in idle -> …  after(wait) -> … }` | ~70 | per-host caps and admission | 3 |
| `fetch.av:232-265` `Retry`, `tried` | retry by recursion with exponential backoff under a total deadline | a retry policy value shared with `queue`'s `backoff` | ~25 | "never with a stream body, never past the deadline" (HTTP tour) | 10 |
| `fetch.av:85,148,426` `Timeouts` | staged `within`s | unchanged | 0 | — | — |
| `h2_client_drive.av:91-128,173,191` | pump until every id answered; parallel arrays by index; a deadline | `select` over the connection and each answer's task | ~60 | bodies UNREAD | 3 |
| `client.av:292-362` h1 reply | read until whole (UNREAD beyond signatures) | a streamed `Answer.body` becomes possible: today the client cannot stream a response at all | 0 (adds a feature) | UNREAD | 6 |
| `files.av:159-183` `file_stream` | a file as `Stream`, 64 KiB per pull | a `yield` loop | ~15 | — | 6 |
| `quota.av:41-90` token bucket | per-key bucket in a `Cell<Map>` | unchanged: a rate, not a stream | 0 | — | — |
| `std-http_compress/src/http_compress.av:135,151` | stream-to-stream encoder (UNREAD) | `.map` over a `Stream<Bytes>` | ~20 | UNREAD | 6 |

## 4. `@std/process`

Its pump does not use the scheduler: it blocks in its own `poll()` on
a 20 ms turn (`std_process.c:472`). CLAUDE.md's "ORDER, NOT
GRANULARITY" law records what that cost.

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-process/src/process.av:983-1049` `ticked`, `pumped`, `past`, `turn_ms` | one turn: poll, drain, feed, reap; deadline asked before the poll; a tuned 20 ms interval | `select { o in out -> …  e in err -> …  x in child.exited() -> …  stdin.writable() if left -> …  after(left) -> … }` | ~60 (+30 of invariant comments) | every invariant in that comment block is a test that must still pass; the tuned turn is the smell the law names | 2 |
| `process.av:1074-1102` `grace`, `still_held` | keep sweeping while a grandchild holds a pipe, then KILL | the same `select` after exit, with `after(grace)`; the arms end when the pipes do | ~30 | the CPU-not-wall witness (CLAUDE.md) | 2 |
| `process.av:856-942` `landed`, `bite`, `poured`, `shut_when_fed` | bounded drain (cap + 1), stdin feed with short writes | stays: the never-waits half. The cap is the byte-weight want again | ~10 | "a bound tested after the work" (CLAUDE.md) | 2 |
| `process.av:955-969` `paced`, `graced` | one wait paces a sweep of many stages (`waited` flag) | one `select` over every stage's sources | 15 | — | 2 |
| `process.av:624-790` `Child` | text buffer per turn, `until_ready`, `read_line`, `wait`, TERM/grace/KILL | `child.lines()` a `Stream<string>`; `exited()` a source; `stop` under `within` | ~90 of 165 | public API | 6 |
| `process.av:1189-1231` `Pipeline.outcome` | launch stages, sweep all until `pending == 0` | one `select` over all stages | ~25 | `consumer_left`: SIGPIPE counts as success (law 8's `false`) | 2 |
| `process.av:1243-1288` `parallel` | refill to `limit`, sweep, collect in input order | `cs.stream().at_once(limit).map(it.outcome())` | ~40 | — | 8 |
| `process.av:1293-1341` `race` | staggered launch, first to finish wins, rest killed | `race { }` over tasks; a loser is stopped | ~40 | losers must be killed, not left (the old tree's bug) | 4 |
| `std_process.c:472-522` `avra_proc_ready` | the package's own `poll()` on three descriptors, sticky-HUP handling | the three descriptors park in the scheduler; the row goes | 50 (C) | the evaluator hosts package C in-process: it must park virtually too | 2 |
| `std_process.c:528` `avra_proc_reap` | non-blocking reap | stays | 0 | exit is not a descriptor on macOS without `EVFILT_PROC`: `exited()` needs a kqueue filter or a pidfd | 2 |

## 5. `@std/ui` and `avra dev`

`@std/ui` has no queue, no timer, no `fetch` and no paint scheduler
today: every event is one synchronous call through `App.turn`, and
`repaint()` stands in for async.

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-ui/src/app/app.av:45-49` `App.turn` | runs the act, paints if it ran | unchanged; `mount`'s loop is `select` over `on.inbox` and a frame timer (design §2.6) | 0 (adds ~15) | reentrancy: a handler must `post`, never `send` | 3 |
| `app/app.av:35-39` `paint` | immediate, no coalescing | the timer arm: many turns, one paint | 0 | — | 3 |
| `terminal/terminal.av:177-190` terminal `mount` | a blocking `avra_fd_read(0, 4096)` loop | `for octets in stdin { … }` beside the inbox in one `select` | ~10 | raw mode is a missing runtime row (avra-8sb5.11.279) | 3 |
| `terminal/terminal.av:124`, `headless/headless.av:61` `repaint()` | a manual paint for "a timer, an answer arriving" | gone: answers enter the inbox | 2 + its tests | — | 3 |
| `web/web.av:22,44-65` `host_seat`, `seated_text`, `host_event` | a one-slot text buffer the host fills before each call in | the reactor's export for `act in on.inbox` | ~15 | the wasm seam's shape is the UI lane's | 5 |
| `realize/dom/live.av:26,57,90-95` `heard` | latest-wins per property, drained by the next paint | a channel with `overflow: .latest` per key | ~10 | — | 3 |
| `headless/headless.av:27-57` | `press`/`fill`/… each a synchronous `turn` | `scripted` events into the same inbox, under virtual time | 0 | tests stay as they read | 7 |
| `cli/src/commands/dev.av:99-120` (`ui-dev`) `hosted` | `while true { sleep(pause)  turn() }`, 250 ms | design §2.2: `select` over the watch, the build's answer and a signal | ~20 | no shutdown path exists today | 2 |
| `dev.av:185-212,273-303` `Mark`, `looked`, `still`, `Page.turn` | re-list and stamp every input each turn | the watch (`../avra-os-watch`); polling kept as its §5 fallback | ~50 | — | 2 |
| `dev.av:222-234,351-367` `standing: Cell`, `moved: Bell`, `next_after`, `events` | latest value + bell + SSE `Source` adapter | `channel<Standing>(1, overflow: .latest, readers: .each)`; each browser reads it | ~20 | — | 3, 6 |
| `os-watch: std-io/src/io.av` `Watch.next` | `while true { taken()?  … park_fd }` | `wait(self)`; the watch is a `Wait<Seen>` (`taken`, `Signal.Readable(fd)`) | 6 | the doc says `next(wait: Duration?)`, the source `next()`: settle on `next()` and `within` | 2 |

## 6. Elsewhere

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-mcp/src/mcp.av:332-343,355` `serve_stdio`, `written` | read fd 0, split lines, answer each in turn; write-all loop | `for line in stdin.lines() { … }`; server-to-client notifications become possible (a second arm) | ~15 | MCP has no notifications, no pending table, no SSE today | 6 |
| `std-sqlite/src/stmt.av:152` `step` | `step() -> Result<bool, SqlError>`; callers write `while s.step()?` | `rows()` a `Stream<Row, SqlError>` by `yield` | 0 (adds a verb) | `Stmt.done` rides a `Cell` on purpose (CLAUDE.md) | 6 |
| `std-io/src/io.av:205-213` `drained` | read-to-EOF loop | a fold over `lines()`/`pieces()` | ~6 | — | 6 |
| `std-io/src/c/std_io.c:312-346` `avra_io_compile_slot` | `flock` scan with `usleep(200000)` forever | stays C: it runs before any scheduler | 0 | — | — |
| `std-cli`, `std-json`, `std-text` | cursors over whole strings | nothing: no waiting, no stream | 0 | — | — |

### The compiler: not a channel

| site | today | verdict |
|---|---|---|
| `std-avrac/src/query/fixpoint.av:205-231` | FIFO of members, re-enqueue on change | a worklist is a fold to a fixpoint in one task. No wait, no second party. Not a channel. |
| `query/kernel.av:69-70,432-527` `pending`, `open` | a stack of per-frame dependency sinks | a stack. No. |
| `compiler/lower/lower.av:352-378,641-700`, `features/worklist.av:348` `Jobs` | mono worklists with several output lists | the outputs are results of one pass. A `yield`-written `Walk` could tidy the cursor-indexed loops (`lower.av:607`, `:753`, `record.av:1163`, `:1541`), under COLLECTIONS S3, not this design. |
| `diagnostics/mod.av:78` `Voices` | a list merged by `concat` at every join | a sink in name only. No. |
| `cli/src/stage.av:77`, `commands/refuses.av:35` | suite binaries and `.refuses` legs run in sequence | `.at_once(n)` would run them n at a time; the machine's one-heavy-process rule decides, not the language. |

### tools/ (shell and Python; listed, not migrated)

`tools/work:77-83,156-175` (poll `gh` for a verdict), `tools/sp:201-229`
(a ticket-file queue, UNREAD), `tools/watch.sh:280-439` (a slot queue
and a memory poller racing `wait`, UNREAD), `tools/memcap.sh:64-75`,
`tools/capped.sh:60-69` (an exit status smuggled in-band through a
pipe), `tools/queue_keeper.sh` (UNREAD). No file under `tools/` is
named or documented as a heartbeat. Each is a `select` over a child's
exit and a timer; they move only if the tools become Avra programs.

## 7. Ranked migration order

Ranked by (what it unblocks) × (lines and hazards removed) ÷ risk.

1. **`Bell` → `Gate`** (slice 1). Four `@std/http` files wait on one at ten
   sites, each through a pipe pair. Smallest change, removes two descriptors per bell, and
   everything after stands on it.
2. **`avra dev`** (slice 2). A 250 ms poll becomes a wait on the
   watch, the build and a signal; gains a shutdown path it lacks. The
   first whole program on `select`.
3. **`@std/ui`'s door, paint and terminal input** (slice 3). The three
   waiting consumers. Adds lines; removes `repaint()`.
4. **`@std/process`'s pump** (slice 2). Removes the package's private
   `poll()` and the tuned 20 ms turn behind the defects CLAUDE.md records
   under "ORDER, NOT GRANULARITY". Highest hazard removed per line; high risk, so
   after two smaller programs have proved `select`.
5. **`@std/http`'s h2 conversation, inbox and pool** (slice 3). The
   most hand-rolled waiting in the tree (~400 lines across
   `server.av`, `h2_serve.av`, `pool.av`). Behind the conformance and
   soak suites.
6. **One `Stream<Bytes>`** for http's three pull shapes, the body, SSE
   and the file stream (slice 6). A public API change: bridge release.
7. `@std/net`'s `Race`, `Poller`, parking verbs (slice 2).
8. `Drain`, `ws` close waits (slice 4). `@std/process`'s `parallel`
   and `race` (slices 8, 4).
9. `@std/mcp`, `@std/sqlite` `rows()`, the cores supervisor (slices 6,
   9).

## 8. Lines

Summed from the "deletes" column; UNREAD rows counted at half.

| area | removed | added |
|---|---|---|
| runtime C | ~120 | ~230 (wait set, gate, twins) |
| `@std/net` | ~315 | ~30 |
| `@std/http` | ~1,050 | ~250 |
| `@std/process` (Avra + C) | ~390 | ~120 |
| `@std/ui`, `avra dev`, the watch | ~135 | ~60 |
| the rest | ~65 | ~40 |
| the compiler: `features/select/`, the task law, `yield` | 0 | ~900 |
| `@std/task` | 0 | ~600 |
| **total** | **~2,075** | **~2,230** |

The count is a wash. What goes is sixteen copies of park-and-look-again,
three pull protocols, two hand-rolled futures, two private pollers and
every hand-computed timeout. What arrives is written once.

## 9. Wants the canvas found

- CAPACITY BY WEIGHT. h2's inbox bounds octets (262,144), std-process
  bounds captured bytes, a channel bounds items. `channel<Bytes>(n,
  weigh: it.length)` would say it. Sites: `server.av:1008`,
  `process.av:856`.
- A THREAD-TO-TASK WAKE. DNS runs on a pthread and wakes its task
  through a pipe (`std_net.c:487`). A gate is not thread-safe. The
  pipe stays until the cores campaign's atomics.
- EXIT AS A DESCRIPTOR. `child.exited()` needs `EVFILT_PROC` on macOS
  or a pidfd on Linux; today a reap is polled.
