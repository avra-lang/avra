# FLOW — the canvas (v3)

Every site in the tree that hand-rolls a stream, a queue, a poll
loop, a callback registry, a readiness wait, a retry loop, a pipe or a
producer/consumer pair, and what it becomes under
docs/2026_10_05_CHANNELS.md. "Slice" is that doc's OLD slice number;
its §17 maps each to the build order and its ticket. To build, start
from docs/2026_10_06_CHANNELS_HANDOFF.md.

Surveyed on `bd36bf7`, `ui-dev` `faf9ddb` for `avra dev`, and
`../avra-os-watch` (staged) for the watch. The survey was done by
sub-agents reading each range; rows the author re-opened are marked ✓.
UNREAD marks a body outlined by grep only. "Deletes" is an estimate of
hand-rolled WAITING machinery, not of the file; the v1 numbers were
inflated and are corrected here to the independent review's counts
where it gave one (marked R).

Paths are under `packages/` unless they start with `runtime/` or
`tools/`.

## 1. The runtime

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `runtime/avra_fiber.c:125-137` `Fiber` ✓ | one `next` link, one `parked_fd`, one `timer` slot: a task waits on one descriptor and one timer | waiter nodes (four inline, an overflow list) and a wait set with a claim | 0; adds 100+ (R) | the 12 ns switch and the single-descriptor park must not slow; measure before and after | 1 |
| `:201-273` timer heap | one entry per fiber | one entry per waiter | 0 | a stale timer for a set another waker claimed: skipped at fire | 1 |
| `:287-372` `FdWaits` | lists of fibers per descriptor and direction | lists of waiters | 0 | the same lists serve `fd_closing` | 1 |
| `:575-592` `next_ready` ✓ | the one scheduling policy for both engines; traps "every task is waiting — deadlock" only when no timer and no descriptor is parked | gains a seed (slice 2). The trap is unchanged, and a server never reaches it | 0 | partial deadlock stays undetected | 2 |
| `:680-752` join | a task files itself on the joined task's waiter list; ignores the deadline | a task's done gate; join is a wait, so it hears a cancel | ~20 (R) | the join-ring check must survive | 1, 3 |
| `:760-790` `Tasks` owner set ✓ | sheds finished tasks when full | unchanged; a `Source` is settled beside it | 0 | — | 5 |
| `:802-808` `avra_fiber_sleep` | ignores the deadline | a wait on `.At` | ~5 | — | 1, 3 |
| `:811-822` `fd_closing`, `fd_interrupt` ✓ | the only stop mechanism today: wake every waiter on a descriptor, with or without `timed_out` | stay; `fd_interrupt`'s callers (`Drain`) move to cancel | 0 | a close must still wake its parked task (fibers §6b's recorded deadline) | 3 |
| `:825-845` `avra_fiber_park_fd` | the one park row | a caller of the waiting rows; the row stays until its callers move | ~15 | two landings | 1 |
| `:869-945` `avra_vtask_*` | the evaluator's twin of each row | gains twins of the six waiting rows | 0; adds ~80 | `eval == native` on arm choice, tested under slice 2 | 1 |
| `runtime/avra_cores.c` stop pipe, end pipes (`avra_cores_stopped` ~`:190`, `avra_cores_heard` ~`:221` — line numbers drift, R) | pipes that carry no bytes; EOF is the signal | STAY PIPES: a cross-process signal needs the kernel's EOF. The supervisor's wait becomes one `select` over `any(ends)` | ~4 (R) | — | 14 |
| `runtime/avra_runtime.c:3247-3300` `avra_fd_read`/`write` | EINTR loops, `-EAGAIN` | unchanged: the never-waits half of a source. This is where data enters — it is not a seam (design §10.1) | 0 | `:3839`, `:3867` `waitpid` UNREAD | — |
| `std-avrac/src/compiler/backend/interp_tasks.av:20-32,93-118` | `Job{waiters, done, answer}`: a second hand-rolled future | the done gate, shared with native | ~25 | a parked instruction re-runs on wake | 1 |
| OS signals | none handled: the only handlers are the guard page's (`avra_fiber.c:646`) and the FFI fault's (`std-avrac/src/c/ffi.c:217`) ✓ | `avra_wait_sig` and `signals([…])` | 0; adds | `avra dev` and every server need it to stop cleanly | 6 |

## 2. `@std/net`, `@std/tls`

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-net/src/net.av:919-1011` + `c/std_net.c:289-327` `Bell` | a pipe pair, a `parked` flag, a ring counter | a gate and a counter; the API holds | ~75 (R) | `Bell {}` as a literal with a lazy open | 1 |
| `net.av:1016-1021` `unopened` | sleeps 10 ms so a waiter cannot spin | gone with the pipe | 6 | — | 1 |
| `net.av:253-259` `Listener.accept` | try, park, recurse | a `Source<Conn>`; `accept` is its `next` | 5 | recursion per wake overflowed a stack once (fibers §7) | 6 |
| `net.av:294-317` `Conn.read`, `Conn.write` | check, park, try, park, recurse | waits on `.Readable`/`.Writable` | ~12 | `parked_eof`: a peer's end must still wake | 6 |
| `net.av:685-755` `Race` | a PRIVATE poller parked through its own descriptor, a staggered dial timer, `live: List<int>` dials | `select` over `any(dials)` and `after(stagger)` | ~60 | needs `any`: the arm set is dynamic | 6 |
| `net.av:414-436` + `c/std_net.c:329-420` `Poller` | a user-facing second kqueue/epoll | retire | ~110 | it HAS an in-tree caller: `std-http-soak/src/main.av:81` ✓ and five test files (R) | 6 |
| `net.av:596-611` `looked_up`/`awaited` | park on the lookup's pipe with a hand-kept deadline | `within` around a wait on the pipe | ~12 | — | 6 |
| `c/std_net.c:487-735` DNS on a pthread | wakes its task through a pipe byte | stays: a gate is not thread-safe | 0 | — | — |
| `std-tls/src/tls.av:408-419, :469-480` ✓ (first range) | `.Reading -> { self.heard("read")?  self.read(max) }`: try, park, recurse | a wait in a loop | ~10 | missed by v1; `std-https` UNREAD | 6 |

## 3. `@std/http`

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-http/src/server.av:695-860` h2 conversation (`talked`, `waited_on`, `bell_waited`, `stall_left`; bell waits at `:849,854,860` ✓) | a reader task, per-stream handler tasks and a framer meet at ONE bell; every wake rescans every line; four deadlines folded by hand into one timeout | one `select`: the inbox, ONE replies channel every handler task sends into, `after(idle)`, `after(stall)`. Windows open when a WINDOW_UPDATE arrives through the inbox, so they are not arms | ~60 (R): the protocol logic stays | the most load-tested code here; the conformance rows | 8b |
| `server.av:980-1024` `Inbox`, `read_beside` (`:1017` ✓) | `Cell<Inbox>` appended by the reader task; waits on the bell at 256 KiB | a channel the reader task `produce`s | ~25 | the bound is octets, a channel's is items: capacity by weight (§9) | 8b |
| `server.av:976,787,1039` `Line.reply: Cell<H2Reply?>` | a one-shot slot a handler sets, then rings | the replies channel above | ~30 | v1 said both "a task per arm" and "a channel"; it is the channel | 8b |
| `server.av:780` `sleep(ms(0))` | a yield used as an ORDERING dependency (R) | must be understood before it moves | 0 | missed by v1 | 8b |
| `h2_serve.av:173-262` `Inbound`, `stream_body` (`:255` ✓) | a one-slot mailbox behind a fake `Transport` | a `Source<Bytes>` per stream | ~60 | a window is given back only for octets TAKEN (framing laws §5.5, READ(agent)) | 8b |
| `server.av:158,273,632-661` `Drain` | `reading: List<bool>` by descriptor so `stop()` can interrupt each parked reader | a cancel on the server's scope | ~45 | GOAWAY then linger is cleanup that waits: its own `within` | 3 |
| `server.av:321-324,393-403` `stopped_with`, `core_ended` | one task per core as a wait-any | `select` over `any(ends)` | ~15 | — | 14 |
| `server.av:293-304` accept loop | `conns.push(spawn self.connection(c, app))` | `for c in listener { … }` | 3 | — | 6 |
| `server.av:578-590,914-945` `pumped`, `h2_pumped` | pull a piece, write, `sleep(ms(0))` | a `for` over the body's stream; the write parks | ~30 | "one piece per stream in memory" | 9 |
| `server.av:1065-1072` `lingered` (`:1071` ✓) | bell wait until a deadline | a `select` with a bound `after` | 6 | — | 8b |
| `http.av:354` `Stream { pull, length, ended }` ✓ | outgoing body: a record of closures (pull) | `TryStream<Bytes, E>` | ~40 | public API in every streaming handler; the NAME is taken | 9 |
| `body.av:51-304` `Body`, `Inflow`, `Pull` | incoming body: a `Cell` state machine and a refill loop (pull) | a `TryStream<Bytes, BodyError>`; the framing machine stays | ~100 | — | 9 |
| `fetch.av:80,523` `Payload.Stream(next: fn() -> Bytes?, …)` | uploads (pull) | `Stream<Bytes>` | ~20 | — | 9 |
| `form.av:193` `Sink { take: fn(Bytes) -> bool, ended: fn(bool) -> void }` ✓ | a multipart part's consumer (PUSH) | `Sink<Bytes>` | ~15 | missed by v1: the tree has FOUR stream shapes, not three; the NAME is taken | 9 |
| `sse.av:31-115` `Source`, `Next`, `Resume` ✓ (`:40`) | a record with `next: fn(Duration) -> Next`; `Quiet` becomes a keep-alive | a `Source<Event>`; the keep-alive is a `quiet` arm in the writer | ~50 | the NAME is taken | 9 |
| `sse.av:193-258` `Feed` (`:252` ✓) | a ring log, a cursor per observer, a bell | `readers: .each, keeps: .last(n)` | ~35 (R) | "an expired cursor is told" | 10 |
| `ws.av:207-345` `receive`, `frame`, `Pending` | frame loop, reassembly, ping/pong | a `TrySource<Message, WsError>`; reassembly stays | ~30 | close codes are protocol law | 9 |
| `pool.av:67-178` `Pool` (`:176` ✓) | lend/keep counts; a waiter parks on `freed` and re-checks | the wait becomes a gate wait. NOT a channel of carriers: that cannot say newest-first reuse, a filtered take, or "wait for a slot" (R) | ~12 (R) | — | 1 |
| `fetch.av:232-265` `Retry`, `tried` | retry by recursion with backoff | the same policy value a `queue` uses | ~20 | never with a stream body, never past the deadline | 10 |
| `h2_client_drive.av:91-128,173,191` | pump until every id answered; parallel arrays (UNREAD bodies) | `select` over the connection and `any(answers)` | ~40 | UNREAD | 8b |
| `client.av:292-362` h1 reply | read until whole (UNREAD) | a streamed `Answer.body` becomes possible | adds | UNREAD | 9 |
| `files.av:159-183` `file_stream` | a file as `Stream`, 64 KiB per pull | a `yield` loop | ~15 | — | 9 |
| `quota.av:41-90` token bucket | a rate | unchanged | 0 | — | — |

`sse.av:155-163` is `data_lines`, a pure line splitter ✓ — v1 listed
it as a writer loop; the row is removed.

## 4. `@std/process`

Its pump blocks in its own `poll()` on a 20 ms turn
(`std_process.c:472`). CLAUDE.md's "ORDER, NOT GRANULARITY" law
records what that cost.

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `process.av:983-1049` `ticked`, `pumped`, `turn_ms` | one turn: poll, drain, feed, reap; a tuned interval | one `select`: out, err, `exited`, stdin writable (guarded), a bound `after` | ~60 | every invariant in that comment block is a test; ranked after two smaller programs | 8 |
| `process.av:1074-1102` `grace` | sweep while a grandchild holds a pipe, then KILL | the same `select` after exit with a bound `after(grace)` | ~30 | the CPU-not-wall witness | 8 |
| `process.av:856-942` `landed`, `poured` | bounded drain (cap + 1), stdin feed | stays: the never-waits half | ~10 | — | 8 |
| `process.av:1189-1231` `Pipeline.outcome` | sweep all stages until `pending == 0` | `select` over `any(stages)`: the set is dynamic | ~25 | `consumer_left`: SIGPIPE is success | 8 |
| `process.av:1243-1288` `parallel` | refill to `limit`, sweep, collect in order | `.at_once(limit)` | ~40 | — | 9 |
| `process.av:1293-1341` `race` | staggered launch; first wins; rest killed | a `race` scope: a loser is cancelled, and its `defer` kills the child | ~40 | losers must die | 8 |
| `process.av:624-790` `Child` | text buffer, `until_ready`, `read_line`, `wait`, TERM/grace/KILL | `lines()` a stream; `exited()` a task | ~90 | public API | 9 |
| `std_process.c:472-522` `avra_proc_ready` | the package's own `poll()` | the descriptors park in the scheduler | 50 (C) | the evaluator hosts package C in-process | 8 |
| `std_process.c:528` `avra_proc_reap` | non-blocking reap | `avra_wait_exit`: `EVFILT_PROC` or a pidfd | adds a row | a row family, two landings | 8 |

## 5. `@std/ui`, `avra dev`, the watch

`@std/ui` has no queue, no timer, no `fetch` and no paint scheduler:
every event is one synchronous `App.turn`.

| site | today | becomes | deletes | risk | slice |
|---|---|---|---|---|---|
| `std-ui/src/app/app.av:45-49` `App.turn` | runs the act, paints if it ran | UNCHANGED. Native mounts loop over an unbounded inbox (design §2.6) | 0; adds ~10 | law 7's paint rule is kept | 7 |
| `terminal/terminal.av:177-190` terminal `mount` | a blocking `avra_fd_read(0, 4096)` loop | stdin as a source beside the inbox | ~10 | raw mode is a missing row (avra-8sb5.11.279) | 7 |
| `terminal/terminal.av:124`, `headless/headless.av:61` `repaint()` | a manual paint standing in for "a timer, an answer arriving" | answers enter the inbox | 2 + tests | — | 7 |
| `web/web.av:22,44-65` `host_seat`, `host_event` | how text crosses to the program; one event per call | UNCHANGED: the seat is the crossing, not a queue (R). Nothing parks on wasm until WASM32 step 6 | 0 | — | — |
| `realize/dom/live.av:25` handler registry; `:26,90-95` `heard` | `bound: Cell<List<Bound>>` rebuilt per paint; latest-wins per property | unchanged; not waiting machinery | 0 | — | — |
| `headless/headless.av:27-57` | each verb a synchronous `turn` | unchanged; a scripted source feeds the same inbox for timed tests | 0 | — | 7 |
| `cli/src/commands/dev.av:99-120` (`ui-dev`) `hosted` | `while true { sleep(pause)  turn() }`, 250 ms; no shutdown path | design §2.2 | ~20 | — | 6 |
| `dev.av:185-303` `Mark`, `looked`, `still` | re-stamp every input each turn | the watch; polling kept as its fallback | ~50 | — | 6 |
| `dev.av:222-234,351-367` `standing`, `moved: Bell`, `events` | latest value + bell + an SSE `Source` adapter | a `.latest` channel each browser reads | ~20 | — | 6, 9 |
| `os-watch: std-io/src/io.av` `Watch.next` | `while true { taken()?  … park_fd }`; a `within` running out answers `.Quiet` (FILE_WATCH §1 ✓: `next()` takes no argument) | `changes()` a `Source<Seen>`; a deadline is the `within`'s `TimedOut`; `.Quiet` stays for `taken()` | 6 | a change to the watch's contract; agree it with that lane before it lands | 6 |

## 6. Elsewhere

| site | today | becomes | deletes | slice |
|---|---|---|---|---|
| `std-mcp/src/mcp.av:332-343,355` | read fd 0, split lines, answer in turn | `for line in stdin.lines()`; a second arm makes server notifications possible | ~15 | 9 |
| `std-sqlite/src/stmt.av:152` `step` | callers write `while s.step()?` | `rows()` a `TryStream<Row, SqlError>` | adds | 9 |
| `std-io/src/io.av:205-213` `drained` | read-to-EOF loop | a fold over `pieces()` | ~6 | 9 |
| `std-io/src/c/std_io.c:312-346` `avra_io_compile_slot` | `flock` scan with `usleep` | stays C: it runs before any scheduler | 0 | — |
| `std-cli`, `std-json`, `std-text` | cursors over whole strings | nothing | 0 | — |

### The compiler: not a channel

`query/fixpoint.av:205-231`, `query/kernel.av:69-70,432-527`,
`compiler/lower/lower.av:352-378,641-700`, `features/worklist.av:348`,
`diagnostics/mod.av:78`: worklists, a frame stack and a sink list. One
task, no wait, no second party. A `yield`-written walk could tidy the
cursor-indexed loops under COLLECTIONS S3; that is not this design.

### tools/ (shell; listed, not migrated)

`tools/work:77-83,156-175`, `tools/sp:201-229` (UNREAD),
`tools/watch.sh:280-439` (UNREAD), `tools/memcap.sh:64-75`,
`tools/capped.sh:60-69`, `tools/queue_keeper.sh` (UNREAD). Nothing
under `tools/` is a heartbeat. Each is "a child's exit or a timer".

## 7. Ranked migration order

1. **`Bell` on a gate** (slice 1). Eight wait sites in four files
   (`pool.av:176`, `h2_serve.av:255`, `server.av:849,854,860,1017,1071`,
   `sse.av:252` ✓) stop costing two descriptors each.
2. **`avra dev`** (slice 6). A 250 ms poll becomes a wait on the
   watch, the build and a signal, and gains a way to stop.
3. **`@std/ui`'s inbox** (slice 7). The door's first second writer.
4. **`@std/process`'s pump** (slice 8). Removes a private `poll()` and
   a tuned interval. High risk; after 2 and 3 have proved `select`.
5. **`@std/http`'s h2 conversation** (slice 8b). Needs `any` and a
   fan-in channel.
6. **One stream type for http's four shapes** (slice 9; blocked on
   COLLECTIONS S3).
7. `Race`, `Poller`, the parking verbs, `tls` (slice 6). `Drain`
   (slice 3).
8. `@std/mcp`, sqlite `rows()`, the cores supervisor.

Three migrations need a dynamic arm set and could not be written with
static arms: `Race`, `Pipeline.outcome`, the h2 client drive.

## 8. Lines

| area | removed | added |
|---|---|---|
| runtime C | ~70 | ~400 (waiter nodes, six rows, twins, exit, signals, seed, clock) |
| `@std/net`, `@std/tls` | ~290 | ~40 |
| `@std/http` | ~620 | ~250 |
| `@std/process` | ~345 | ~120 |
| `@std/ui`, `avra dev`, the watch | ~110 | ~50 |
| the rest | ~20 | ~40 |
| the compiler: `select`, the task law, cancel, `yield`, rules | 0 | ~1,400 |
| `@std/task`, `@std/queue` | 0 | ~900 |
| **total** | **~1,450** | **~3,200** |

This is a net addition of well over a thousand lines; v1 called it a
wash and was wrong. What goes is fourteen copies of park-and-look-again
(six on a descriptor, eight on a bell ✓), four stream shapes, two
hand-rolled futures, two private pollers and every hand-folded
timeout. Every number here is an estimate from surveyed ranges, half
of them not re-read by the author.

## 9. Wants the canvas found

- CAPACITY BY WEIGHT. h2's inbox bounds octets (262,144), std-process
  bounds captured bytes; a channel bounds items. `channel<Bytes>(n,
  weigh: it.length)`. Needed by two of this canvas's own rows.
- EXIT AS A WAIT. `avra_wait_exit` (design §5.1).
- SIGNALS AS A SOURCE. Nothing handles one today.
- A THREAD-TO-TASK WAKE. DNS wakes through a pipe; it stays one.
