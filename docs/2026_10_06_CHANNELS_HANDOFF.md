# CHANNELS — the hand-off

Epic `avra-8sb5.34.53`. This page is the MAP. The SPEC is
`docs/2026_10_05_CHANNELS.md` (long; start at its index). The list of
code that moves onto channels is `docs/2026_10_05_CHANNELS_CANVAS.md`.

## 1. What this is

- Nothing is built. This campaign builds it, slice by slice (§6).
- Today a task can wait on ONE thing: a socket, or a timer, or a watch.
- After: `select` waits on many, channels carry values between tasks,
  a `queue` survives a crash, and `avra test --faults` attacks it.
- THE ONE IDEA: a stream is declared with a CONTRACT (how many times an
  item is delivered, in what order, where it lives). The compiler checks
  the code against the contract, and the same contract drives the tests.
- Errors are first class: every end, timeout and cancel is a typed value
  someone must handle. Nothing is silent.

## 2. What an author writes

All six are PROPOSED. None runs today (`select` and `channel` are
reserved words with no meaning yet). The spec's §2 says what was probed.

**A channel.** Nobody closes it; it ends when the producer's block ends.

```avra
let pages = produce<Page>(8) { out -> for u in seeds { out.send(fetch(u)) } }
for p in pages { store(p) }          // send parks while 8 pages wait
```

**A returned stream.** Whoever receives it owns it. When the owner's
block ends, the producer is cancelled and joined.

```avra
fn feed(urls: List<string>) -> Source<Page> {
    produce<Page>(8) { out -> for u in urls { out.send(fetch(u)) } }
}
```

**`select`, an end arm, a timer.** A source that can end MUST have its
`.ended` arm, or the build refuses (`flow.end_arm`).

```avra
select {
    _ in saves           -> { dirty = true }
    quiet(ms(50)) if dirty -> {      // 50 ms in which no arm fired
        dirty = false
        rebuild()
    }
    _ in quit            -> { return 0 }
    saves.ended          -> { return 1 }
    quit.ended           -> { return 0 }
}
```

**A queue, a guarantee, a worker, named keys.**

```avra
queue charges of Charge {
    store: Main
    delivery: .exactly_once
    capacity: 10000
    lease: secs(30)
    dedupe: hours(24)
    retries: 3
    dead: failed_charges
}
worker settle { reads: charges  each: pay }

fn pay(d: Delivery<Charge>) -> Result<Receipt, PayError> {
    if d.item.fee > 0 { charge(d.key.at("fee"), d.item.fee)? }
    charge(d.key.at("total"), d.item.total)
}
```

**A deadline.** The block answers `Result<T, TimedOut>`.

```avra
let page = within secs(5) { fetch(url) } catch t -> {
    log(t.at)                        // where the task was when time ran out
    cached(url)
}
```

**Cores.** One process per core; items are copied across.

```avra
worker thumbs { reads: uploads  on: .cores  each: thumbnail }
```

## 3. The laws

1. A `Stream` is a recipe. A `Source` is one running. A `Sink` feeds one.
2. A running stream is owned by ONE block and ends with it.
3. The owner leaving cancels the producer, then joins it.
4. A channel says how much it holds. `0` hands over directly.
5. Dropped items are counted, never hidden.
6. A `select` has an arm for every source that can end.
7. Arms take turns; a ready arm waits at most `arms − 1` turns.
8. A task answers once.
9. Cancel unwinds the cancelled task and is a typed VALUE to whoever
   watches it (§4, decision 2).
10. Cleanup that waits says for how long.
11. A failure is the last item of a stream and carries its path.
12. No queue item is left behind: acked, or in a dead letter.
13. An item is acked when its handler returns `Ok`.
14. Delivery is promised per EFFECT, by key.
15. The sender mints an item's id; the home remembers it for `dedupe`.
16. A lease has an epoch; a stale worker's ack is refused.
17. `fold` goes left. `reduce` groups in one fixed tree. Same answer on
    every machine.
18. A value crosses a process by copy, by descriptor, or not at all.
19. A wait on another machine says how long.
20. A trap ends one process. What it held is under lease.

## 4. Decided (owner, 2026-10-05/06)

| # | decision |
|---|---|
| 1 | A trap ends its whole process. Isolation comes from separate processes. |
| 2 | Cancel has two faces of ONE event. Inside the cancelled task: it unwinds by a compiler-checked flag, `defer`s run, no boilerplate. At every boundary where another task watches: a typed value (`Cancelled`, `TimedOut`) with the trace of where the task was. A task may opt in to see it at a point. Table below. |
| 3 | A fn may return a running stream. The receiver owns it. |
| 4 | `reduce` groups in fixed chunks that keep order. Associativity is enough; vector lanes also need commutativity. The constants (8 × 128) are fixed only after one measurement. |
| 5 | A law that is tested but not proven may license reordering in a release build. The build output marks it. `laws: .proven` turns it off per deploy. **`law` declarations do not exist in this tree yet** (design: `docs/2026_09_22_BEND_LAWS_PARALLEL_AND_BEYOND.md`). |
| 6 | Named keys for retries: **PENDING THE OWNER'S OK**. Explained below. |
| 7 | A queue's home: BOTH. Known at build → PROVEN, printed "proven". Chosen at run time → works, with a safety row on each side, printed "checked at run time". |
| 8 | Many cores = separate processes with copying, now. No data-parallel speed promise until shared-memory threads exist (BEND). |
| 9 | BOTH queues ship here: the database one first, then the remote one. The remote one's auth verifier is designed first (its own slice). |
| 10 | Order: core → database queue with effect contracts → fault testing → remote queue → four best-in-class designs. |
| — | `\|>` is plain application (`x \|> f(a)` is `f(x, a)`), never a send. Landing on branch `pipe-op`. |

**Decision 2: who sees a cancel.**

| who | sees |
|---|---|
| the cancelled task | nothing to write. It unwinds at its next wait; `defer`s run |
| the same task, opting in | `cancellable { … }` answers `Result<T, Cancelled>`; its arm runs, then the unwind goes on. A cancel cannot be swallowed |
| the `within` that timed out | `Err(TimedOut { after, at })` |
| whoever joins the task, or has an arm over it | `Err(Cancelled { by, at })`. Never a made-up answer |
| the reader of its stream | `.ended` binds `.Done` or `.Cancelled(c)`; a `TrySource`'s last item is the `Err` |
| a queue | the item is not acked; it is redelivered; the hop is recorded |

`at` is the trace of where the task was. Spellings (`cancellable`, the
join's type) are PROPOSED; slice 3 settles them by probe. Slice 3 also
publishes speed before and after.

**Decision 6: keys, in ten lines.** A worker can crash after it charged
a card and before it said "done". The item is delivered again.

```
attempt 1   charge(key "order-9/fee", $2) → provider charges, remembers the key   ✗ crash
attempt 2   charge(key "order-9/fee", $2) → provider sees the same key → no second charge
            handler returns Ok → item acked
```

- A KEY is a name for one effect. Each delivery carries one (`d.key`).
  `d.key.at("fee")` makes a sub-key: the same text on every attempt.
- WHERE it is remembered, one of two places:
  - the PROVIDER's table, when the extern's seat is marked `keyed`
    (Stripe's idempotency key is this);
  - a row in OUR store, written in the handler's own transaction, when
    the effect is a write to our database.
- An effect with neither repeats, and the build says which one.
- THE PENDING CHOICE: (a) a keyed call inside an `if`/loop must be named
  by hand, or the build refuses (`flow.unnamed_key`); (b) the runtime
  records every read so a retry takes the same path. Recommended: (a)
  now; (b) arrives with durable workflows.

## 5. Not designed yet

| area | state | goes to |
|---|---|---|
| supervision trees, hot upgrade (vs Erlang/OTP) | sketched: restart one core | `.18` |
| durable workflows (vs Temporal) | sketched: spec §12 | `.18` |
| event time, windows, retractions (vs Flink) | not designed | `.18` |
| automatic parallelism, SIMD from laws (vs Bend) | interface only: spec §10.3 | `.18`, BEND |
| remote queue: auth verifier, full queue, order under concurrent sends | sketched: spec §6.5 | `.20` |
| re-forking a crashed core: what the child inherits | sketched: spec §8.3 | `.14` |
| vector speed of `reduce` | to be measured, one clang experiment | `.17` |
| a third-party broker; session types; wasm tasks | not here | their own epics |

## 6. The slices, in order

Ticket ids are `avra-8sb5.34.53.N`. Kind: R runtime, C compiler, L library.

| # | slice | when it lands, the owner can | needs first | kind | ticket | landing cost |
|---|---|---|---|---|---|---|
| 1 | waiters, gates | run a C test: one task woken by a descriptor, a timer and a gate | — | R | `.1` | 2 landings per row family, seed refresh |
| 2 | seeded schedule, virtual clock | `avra test`: `sleep(secs(60))` takes no time; a failure replays by seed | 1 | R C | `.2` | 2 landings, seed refresh |
| 3 | cancel, `within` → `TimedOut` | time out any wait and get a typed value; see req/s before and after | 2 | R C L | `.3` | every `within` caller migrates; seed refresh |
| 4 | `select`, `any`, `after`, `quiet` | select over two tasks and a timer, both engines | 3 | C L | `.4` | new grammar: save `build/avra.pre`, build twice, seed refresh |
| 5 | channels, `produce`, ownership | run §2's first two examples | 4 | C L | `.6` | task law changes; `channel` leaves the reserved list |
| 6 | net, watch, signals as sources | select over a file watch, a channel and a timer; `avra dev` stops on Ctrl-C | 5 | R L | `.5` | 2 landings (`avra_wait_sig`) |
| 7 | queue + worker in memory | run §2's queue with no store; remove `dead:` and get refused | 5 | C L | `.10` | new declarations: build twice, seed refresh |
| 8 | effect contracts, keys, `explain flow` | declare `exactly_once` over an unkeyed effect and get refused by name | 7 | C | `.11` | `SeatMark` grows a field (fingerprints, `make vocab`); grammar. **Law-backed rows wait for `law`** |
| 9 | database queue, `tx.send` | crash between the row and the send; lose neither | 7 | L C | `.12` | sqlite blocks its core (fibers F4 unbuilt) |
| 10 | `avra test --faults` | run it on §2's queue with no test written; get a seed on failure | 2, 8, 9 | C R | `.19` | 1 test-only row, 2 landings. **"Law run both ways" waits for `law`** |
| 11 | remote queue: the design | read one short doc: verifier, full queue, order | 9 | doc | `.20` | none; reviewer loop |
| 12 | remote queue: the build | change one line; the queue lives on another machine | 10, 11 | L | `.16` | recursive `shape_hash` first |
| 13 | `@std/ui` inbox | a timer and a task's answer reach `App.turn` in the terminal | 2, 5 | L | `.7` | with the UI lead (`.59.44.13`) |
| 14 | `@std/process` on `select` | no private `poll()`; suites green | 6 | R L | `.8` | 2 landings (`avra_wait_exit`) |
| 15 | `@std/http` h2 on `select` | h2 conformance and soak green; req/s within noise | 5 | L | `.13` | the largest migration (canvas §3) |
| 16 | cores: links, crossing, `on_crash` | trap one core; its peers keep serving; the item is buried | 7 | R C L | `.14` | 2 landings (3 rows). Re-fork is sketched |
| 17 | `Stream`, `yield`, `.buffered` | one `yield` fn is one loop; `.buffered(8)` makes it two tasks | 5, **COLLECTIONS S3 (`avra-8sb5.65.5`)** | C L | `.9` | `yield` becomes a keyword |
| 18 | `fold`, `reduce` | `reduce` over floats: same bits on both engines | 5; **`law` for fold→reduce**; clang experiment first | C L | `.17` | `LoopStart` payload pays 11 consumers |
| 19 | four best-in-class designs | read four reviewed designs, each beating its named system | 12 | doc | `.18` | none; reviewer loop |

- 1–6 meet the epic's first acceptance. 7–10 are the flagship.
- 13–15 are migrations. They can run beside 7–12 if a second lane exists.
- Unbuilt things outside this epic that a slice names: `law` (8, 10,
  18), COLLECTIONS S3 (17), the `deploy` block (`laws: .proven` is a
  build flag until then), fibers F4 offload (9), WASM32 step 6 (any wait
  on wasm), `@std/relation` publishing changes (19), BEND threads (19).
- `|>` is only sugar for chains in 17. Nothing waits on it.

## 7. How to work here

- Read `CLAUDE.md` first: "How work lands", "Working discipline", the idiom bar, the IR protocol, the vocabulary seam rule.
- Docs live on branch `channels-design` (worktree `../avra-channels-design`). The lead opens its PR. Do not build there.
- One slice = one worktree: `sh tools/work new flow-<n>`. Then `sh tools/work test`, `sh tools/work run <cmd>`, `sh tools/work land` (only on the lead's go), `sh tools/work status`.
- Heavy runs go on Sprites. Every command is bounded to ~2 minutes.
- A runtime row the compiler's own source declares takes TWO landings (CLAUDE.md, "A REGISTRY ROW … CANNOT BE GATED IN THE COMMIT THAT ADDS IT"). A grammar change: `cp build/avra build/avra.pre` first.
- Every slice: implement → `/red-team` → `/review-round` → land.
- THE LOOP THAT WORKED for the design: author writes, an INDEPENDENT reviewer attacks with probes, repeat. Three rounds found 11, then 4, then 6 flaws. Use it for slices 11 and 19, and for slice 3's spellings.
- Probe every example before claiming it types. Probe outside the tree.
- Update the ticket when a slice lands; close it with the PR number.

## 8. Traps the reviews already paid for

1. Do not claim an example types without running it. `?` inside a block lambda, `Task<void>`, tuples and generic methods do not.
2. A cancel never displaces a wake that already claimed the wait. The promised value is taken first. Two bits: asked, and unwinding.
3. A task made in an arm head and not taken is CANCELLED, never joined. Joining waits out every unfired timer.
4. A `send` to a reader that left is a cancel point. Without it a producer that never waits hangs its owner.
5. `reduce` keeps item order (consecutive runs). Dealing by index mod 8 reorders; text came out `acegibdfhj`.
6. An effect's key is (delivery key, callee, n-th call), never the delivery id alone. `n` is unsafe under control flow: name it.
7. "In store S" means the `Tx` the handler was HANDED. A second `begin()` inside commits apart from the ack: refuse it.
8. A run-time home changes the mechanism, never the promise: an outbox row for the sender, an inbox row for the handler.
9. An attempt counts when a handler STARTS, not at `take`. A newer writer's shape is released, not buried (rolling deploys).
10. In the simulator a crash is not a cancel: no `defer` runs. A duplicate the contract permits is a note, not a failure.

## 9. Open, needing the owner

| item | state |
|---|---|
| Decision 6: named keys (a) vs recorded reads (b) | pending his OK; (a) is recommended and is what slice 8 builds |
| Slice 17 says COLLECTIONS S4 is push fused into pull; S4's ticket says "pull-based, fiber-backed" | the COLLECTIONS lead must agree before slice 17 starts |
| Spec §2.2 makes a `within` around `watch.next()` answer `TimedOut`, not `.Quiet` | the file-watch lane must agree before slice 6 |
| The spelling `cancellable { }` and the typed join | slice 3 proposes after probing; owner confirms |
