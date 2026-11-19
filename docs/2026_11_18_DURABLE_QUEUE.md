# The durable queue — design

Status: DECIDED WITH OWNER 2026-11-18 (§10). Q0's probes ran on the batch-51 compiler; §8a holds what they found.
Ticket `avra-8sb5.98.8`. Epic for jobs: `avra-8sb5.64.1`.

This is the build design for one home of `2026_10_05_CHANNELS.md` (FLOW, decided v4):
the queue homed in the program's own store (§6.4 there), its worker (§2.4, §7.1),
and jobs and schedules on top. That document decides the laws. This one decides the
surface, the packages and the slices. Where they differ, §9 says so.

## 1. What an author writes

One declaration. `durable: true` is the only line that makes it durable; the database is a context.

```avra
use @std.queue.{queue, worker, schedule, Delivery, Dead}
use @std.queue_store.{db}
use @std.time.{secs, hours, cron}

type Email = { to: string, subject: string, body: string }

queue<Email> emails {
    durable: true
    retries: 5
    backoff: secs(5)
    dedupe: hours(24)
}

queue<Dead<Email, SmtpError>> undeliverable { durable: true }

worker sender {
    reads: emails
    at_once: 10
    each: deliver
    dead: undeliverable
}

fn deliver(d: Delivery<Email>) -> Result<string, SmtpError> { smtp_send(d.item) }
```

The database is `ctx db: Db`, declared by `@std/queue_store` with no default, so it is
required: a program that sends to or runs a durable queue on a path that never set it does
not compile. `main` sets it once; a test sets `Db.memory()`.

```avra
fn main() -> Result<void, SqlError> {
    ctx db = Db.open("app.db")?      // a set stands in a fn body, never at a file's top level
    run(sender)
}
```

Sending, alone and inside the caller's transaction:

```avra
emails.send(welcome(u), id: "welcome-${u.id}")?

let tx = ctx.db.begin()?
errdefer tx.rollback()
let saved = tx.insert(u)?
tx.send(emails, welcome(saved), id: "welcome-${saved.id}")?   // one commit with the user row
tx.commit()?
```

Later, and on a schedule:

```avra
emails.send(reminder(u), after: hours(48))?

schedule nightly {
    every: cron("0 3 * * *")
    sends: reports
    item: Report { kind: "daily" }
}
```

A job is a queue and its worker in one declaration, for the common case:

```avra
job resize {
    durable: true
    retries: 3
    each: (d: Delivery<Upload>) -> thumbnails(d.item)
}

resize.later(upload)?
```

### 1a. As built (2026-11-18, after Q5 and Q4)

What compiles today, from `packages/std-queue_store/src/tests/durable_emails`:

```avra
@codec
type Email = { to: string, subject: string }

fn deliver(d: Delivery<Email>) -> Result<string, string> {
    let _ = ctx.db.run(sql("INSERT INTO sent (to) VALUES (?1)", [.Text(d.item.to)])) catch 0   // one commit with the ack
    smtp_send(d.item)
}

fn main() -> Result<string, HomeError> {
    ctx db = homed(Db.open("app.db"))?

    queue<Email> emails {
        name: "emails"
        durable: stored<Email>()
        retries: 5
    }
    queue<Dead<Email, string>> undeliverable {
        name: "undeliverable"
        durable: stored_dead<Email>()
    }
    worker sender {
        reads: emails
        at_once: 10
        in_tx: true
        each: deliver
        dead: undeliverable
    }

    let tx = transaction(ctx.db)?
    errdefer tx.rollback()
    let _ = homed(tx.db.run(sql("INSERT INTO users (name) VALUES ('grace')")))?
    let _ = emails.send(receipt(u), id: "receipt-${u.id}", tx: tx)?   // one commit with the user row
    let _ = tx.commit()?

    let serving = spawn run(sender)
    …
    sender.stop()
}
```

What Q4 holds, each a case in `tx_test`, `in_tx_test`, `letters_test` or a program:

- `send(…, tx:)` joins the transaction: its commit delivers the item, its rollback leaves none and frees the name. With `after:` too, the delayed row is written in the transaction: it exists only once that commits, and is due at its instant then. A transaction that ended, one on another connection, and any on a queue with no durable home are refused.
- A worker of this process takes nothing a transaction has not committed: the loop waits while the connection holds one it does not own (`Home.idle`), and a commit rings the queue's bell.
- `in_tx: true`: the start is counted on its own, then the handler runs inside the transaction its ack ends (`Home.settles`); a failure, a trap, a lease run out or a hold lost by the ack rolls the handler's writes back. One handler transaction stands per connection at a time; the delivery's `tx` is it, and `ctx.db` inside the handler is its connection.
- `dead:` is a queue. Burying is one transaction, so a letter on the same database holds the item or the queue does. `stored_dead<T>()` makes the letter durable; a worker's `check` refuses a letter that drops.
- A durable queue first used inside a transaction opens there when its tables stand; on a fresh database it is refused and asked again at its next use.

Where it still differs from §1, and what closes each gap:

| §1 says | Today | Closed by |
|---|---|---|
| `durable: true` | `durable: stored<Email>()` | a type argument inferred from the seat that wants it; `@std/queue` cannot name the store, so the setting stays a value the store hands over |
| no `name:` | `name: "emails"` | a component reading its own instance name |
| declared at a file's top level | declared inside the fn that sets `ctx db` | a `ctx` read charged where a fn value is called, and top-level instances as declarations (ruled, being built) |
| `tx.send(emails, …)` | `emails.send(…, tx: tx)` | a generic method (`impl Tx { fn send<T>(q: queue<T>, …) }` is refused today) |
| `durable: true` on a letter | `durable: stored_dead<Email>()` | the same seat inference as `durable: true`; `string` carrying the codec, so one `stored<Dead<Email, string>>()` serves |
| `every: cron("0 3 * * *")` | `at: cron("0 3 * * *")`, and `every: hours(1)` for a span | a seat that takes either a `Cron` or a `Duration`: no union type, and a trait impl cannot land on `Result<Cron, CronError>` |
| `schedule nightly { … }` reads its name | `name: "nightly"` | a component reading its own instance name |
| `use @std.queue.{schedule}` | `use @std.queue.schedule.{schedule}` | `export use` in the program layer (refused there as a duplicate) |

Delayed and recurring work (Q5):

```avra
emails.send(reminder(u), id: "remind-${u.id}", after: hours(48))?

queue<Report> reports { name: "reports"  durable: stored<Report>() }
schedule nightly {
    name: "nightly"
    at: cron("0 3 * * *")        // or `every: hours(1)`
    sends: reports
    item: Report { kind: "daily" }
}
let _ = reports.home().depth()?  // a home opens where the context is set
let ticking = spawn nightly.run()
```

- `after:` is one `ready_at` instant on the row (the home's `clock`); memory holds it in a heap
  by its due instant. A delayed item takes room and is owed (`depth`) from its send, holds no
  place until due, then is handed out BY ITS SEND: before anything sent after it, behind its
  key's item that is out. A delay of nothing or less is a plain send. A delay past the range of
  instants is held at the last one. `drop_oldest` and `latest` refuse a delayed send (no place
  to give up); `drop_newest` discards it like any send into a full queue.
- `cron(text) -> Result<Cron, CronError>` in `@std/time`: five fields, lists, ranges, steps,
  month and weekday names, `7` as Sunday, the `@daily` family; classic day-field rule (both
  written without `*`: either matches). `Cron.next_after(t)` and `Duration.next_after(t)`
  (a whole multiple of the span past the epoch). UTC only: `@std/time` has no zones, so DST
  is out of scope.
- `schedule`: every process finds the same tick and sends `<name>@<tick ISO>`; dedupe makes
  one item. On start the newest tick within `catch_up` (default `hours(1)`) is sent; one older
  is skipped. A wait that wakes past a tick by more than `catch_up` fires `missed`. A clock
  that steps back sends no tick twice. `check` refuses `catch_up` longer than a durable
  queue's `dedupe`.
- Owed: `take`'s walk of the free index steps over delayed rows not yet due (one per take,
  each), a cost to row in ZERO_COST before a queue holds many long delays.

## 2. What it promises

| Promise | How it is kept |
|---|---|
| A sent item is never lost | a row, committed before `send` answers |
| At least once | a lease on the row; a crashed worker's lease runs out and the item is taken again |
| A stale worker cannot ack | every take raises the row's `epoch`; an ack with an old epoch answers `false` |
| One send per id within `dedupe` | `flow_seen` remembers a send that was answered an id; a send the terms turned away files nothing, so a retry is a fresh send |
| Exactly once for store writes | the handler's writes and the ack are one commit (`worker { in_tx: true }` hands the handler the transaction) |
| A poison item ends | an attempt is counted when the handler STARTS; an item whose starts have reached `retries` is buried without running, its letter saying `Unanswered`; never dropped |
| Order | `fifo`, or `by_key`: keys run apart, each key in send order |

No home delivers exactly once to the outside world. An effect outside the store repeats
on redelivery unless the provider dedupes by key (CHANNELS §7.2, a language ask, §7 here).

## 3. The pieces, and the std package each one is

| Piece | Built from |
|---|---|
| The declaration | the `queue`, `worker` components std-queue has today, grown; `schedule` and `job` beside them |
| The seam | a `Home` record of fns under `Queue<T>` (CHANNELS §6.2). Memory is one home, the store another |
| The rows | `@model` types in `@std/db`: `FlowItem`, `FlowSeen`, `FlowShape`. Migrations and table claims are std-db's |
| Take and ack | `@std/sqlite` statements in one `begin immediate` transaction |
| The body | T's stable byte codec from `@std/relation` (CHANNELS §6.3); a record may grow at its end. Read by people through a projection (§4) |
| Waking | `@std/task`: a send in this process rings the queue's gate; another process polls every `min(patience, 250 ms)` |
| Time | `@std/time`: `Duration`, `now()`, `every`; `cron` is new there |
| Workers | `@std/task` tasks, `at_once` of them, cancelled as a scope |
| Operating it | `@std/crud` over `FlowItem` gives the admin router: list, peek, retry, discard |
| Reading it | `avra explain flow` prints each queue's home, terms, depth and who reads it |

Packages:
- `@std/queue` keeps the declaration, `Home`, and the memory home. It gains no dependency.
- `@std/queue_store` holds the store home and depends on `@std/db` and `@std/sqlite`.
  A program with no durable queue links no SQLite.

## 4. The tables

```avra
@model
type FlowItem = {
    seq: int = 0,                 // the order
    queue: string,
    id: string,
    key: string,
    shape: int,
    body: Bytes,
    sent_at: Time,
    ready_at: Time,               // `after:` and backoff
    attempt: int = 0,
    epoch: int = 0,
    reader: string? = null,
    leased_until: Time? = null,
}
```

- Indexes: `(queue, ready_at, seq)` for take; unique `(queue, id)`.
  Both are wanting sites for declared indexes (44.8) and composite unique (44.7).
- `FlowSeen { queue, id, at, answer }`, pruned after `dedupe`.
- `FlowShape { hash, descriptor }`: one row per element shape, for readers of an older or newer build.
- A dead letter is a queue whose overflow never drops; a buried item is a `FlowItem` under the letter's name, moved in one transaction. A letter carries `Dead<T, E> { item, fate: Fate<E>, path }`, and `Fate<E>` is `Failed(error: E)` or `Unanswered`.
- A delivery's id is `<mark>-<row>`: the mark is the database's own (`FlowMark`, one row, minted at creation), so a delivery from another database or another home answers `false` on every verb.
- Counts live in a `FlowRoom` row kept by triggers; a count that is missing is rebuilt from the rows, never read as zero. A home is opened outside a transaction.
- `FlowUnread` holds rows no item could be read from, with the reason; `forget_unreadable(before)` clears them.

| Verb | Statement |
|---|---|
| `send` | find the id in `FlowSeen`; present: answer its id again. Absent: insert both rows |
| `take` | one `UPDATE … RETURNING` over the oldest ready rows with no live lease: set `reader`, `epoch + 1`, `leased_until` |
| `began` | `attempt + 1` where the epoch still matches; `false` if the lease was lost |
| `ack` | delete where id and epoch match; 0 rows is `false` |
| `release` | clear the lease, set `ready_at = now + backoff` |
| `bury` | delete and insert under the letter, one transaction |

THE BODY IS BYTES AND ITS READING IS A PROJECTION (P11, P12). The row holds the compact
codec, so a send and a take cost no text; `FlowShape` holds each shape's descriptor, so a
row describes itself without the program's source. People read it three ways, all decoding
through that descriptor: `avra queue peek <name>` prints items as records; the admin router
answers them as JSON; and the store registers a SQL function, so
`select flow_json(shape, body) from flow_item` works in any session the program or the CLI
opens. Owed: the encode and decode cost per item, measured beside JSON's, before Q2 closes.

`take` is the wanting site for typed `sql{}` (44.6): it is the one statement the model
queries cannot say. Until that lands it is a prepared `@std/sqlite` statement.

## 5. The worker loop

`run(sender)` lives as long as its scope. `drain(sender)` (today's verb) stays: run to empty, for tests and scripts.

1. Take up to `at_once - busy` items; park on the gate when there are none.
2. For each: `began`, run the handler in its own task under the lease as a deadline.
3. `Ok` acks. `Err` releases with `backoff × 2^attempt` (capped), or buries past `retries`.
4. A handler that outlives its lease is cancelled; the item is taken again elsewhere.
5. On cancel: stop taking, let running handlers finish inside their leases, release the rest.

- A backing-off item keeps its place: under `fifo` nothing behind it is handed out while it waits; under `by_key` only its key waits.

- The handler's error type is its own: `each: fn(Delivery<T>) -> Result<R, E>`, and the letter is `Dead<T, E>`.
  Today both are `string`.
- A schedule needs no leader. Every process computes the same tick and sends with
  id `"<schedule>@<tick>"`; `dedupe` makes it one item however many processes run.
- Blocking: a SQLite call blocks its core (CHANNELS §6.1). Takes and acks are batched
  per turn so a busy worker pays one transaction per batch, not per item.

## 6. Testing

- The same declaration without `durable:` is the memory home: unit tests need no file.
- `ctx db = Db.memory()` runs every store statement with no disk.
- The crash witness: a program test whose child takes an item and exits without acking;
  the parent reopens the file and takes it again with `epoch + 1`.
- The two-process witness: two children share one file, send and take concurrently;
  every id is handled, none twice under `in_tx:` handlers.
- Each verb above has its attack in CHANNELS §3. Those move from the memory home's tests to a shared set both homes run.

## 7. What it asks of the language

To the lead as a list, one sample each, before the slice that needs it. None blocks Q1–Q3.

| Ask | Needed by | Without it |
|---|---|---|
| `ctx` in std library code | Q2 | allowed once batch 50 lands (lead, 2026-11-18); a program importing it is new-only |
| A named argument on a component method call (`send(v, id:, after:)`) | Q2 | probe; may work today |
| `effect`, `reading` marks and the `keyed` seat | exactly once for outside effects | at least once, printed with a warning |
| Typed `sql{}` | `take` | a prepared statement |

## 8. Slices

Each is one commit set on `services`, red-teamed, its own suite green.

| Slice | What lands | Works after it |
|---|---|---|
| Q0 | DONE (§8a): the probes: a required `ctx db` read from a component's methods and from a spawned worker, named args on `send`, `@model` with `Bytes`, `UPDATE … RETURNING` and a registered SQL function through std-sqlite | the surface in §1 is confirmed or corrected |
| Q1 | BUILT: `Home<T>` under `Queue<T>`; memory home behind it; handler error generic; release with a backoff | 17 tests, 14 programs |
| Q2 | BUILT and red-teamed (79 attacks; 13 findings, all fixed): `@std/queue_store` — rows, send, take, ack, release, bury, dedupe, batches, named sync, unreadable rows set aside | a queue survives a restart; 105 store tests, 25 shared laws and 33 attacks over both homes |
| Q3 | BUILT: `run` (`at_once`, a lease deadline per handler, backoff ×2 to a cap, `stop()`), a home that waits (a bell in this process, a bounded poll across processes), `durable:` over `ctx db`, a coded item's wire derived (`@codec` writes `impl Storable`), a newer writer's item let go for a newer reader | a long-lived worker; the showcase program. Owed: the two-process witness |
| Q4 | BUILT and red-teamed: a send that joins the caller's transaction (`tx:`), a worker's `in_tx:`, a dead letter that is a queue and outlives the process | exactly once for store writes; 19 new store cases, 2 programs |
| Q5 | BUILT and red-teamed (fuzzed cron text found one trap, fixed): `after:` on both homes, `cron`/`hours` in `@std/time`, `schedule` with `at:`/`every:` | delayed and recurring work; 14 shared delay laws over both homes, 5 store delay cases, 35 cron cases with a minute-walk oracle and 400 fuzzed lines, 20 schedule cases |
| Q6 | `job`, the admin router, `explain flow` | the one-declaration job; operating it |

### 8a. What the probes found (batch-51 compiler, 2026-11-18)

| Asked | Answer |
|---|---|
| a library's required `ctx db`, read by its fns, a component method, an owned `spawn`, a test | works; unset is `ctx.required` at build |
| a worker's `each: deliver` (a named fn in a top-level instance) | reads the context where it is CALLED; a lambda reads where it was made |
| two databases | a setting that is an enum, or a fn defaulted in the library, chooses the context |
| `send(v, id:, after:)` | named arguments work on a component method |
| `UPDATE … RETURNING` with bound parameters | works through `@std/sqlite` |
| a fn body naming a top-level queue (`emails.send(…)` in `fn signup`) | REFUSED today (`resolve.runtime_binding`); ruled to become a declaration nameable from any fn and importable. Until then: a parameter, or a module `state` |
| `@model` with a `Bytes` field | REFUSED: the derive has no `Bytes` kind; a `Time` column's DDL type is a placeholder word. std-db's to fix, before or with Q2 |
| a SQL function registered from Avra (`flow_json`) | not possible: no C callback trampoline. That projection waits; `peek` and the admin router do not |
| `ctx db = …` when the read is through a fn value | a false `ctx.unread` warning; reported |

Later, not in this run: the remote home over HTTPS (CHANNELS §6.5), effect contracts (§7.2), Postgres.

## 9. Where this differs from CHANNELS

- The declaration is `queue<Email> emails { … }`, the component spelling that was built, not `queue emails of Email`.
- The tables are `@model` types, so std-db owns their migrations, where CHANNELS wrote SQL.
- `ready_at` is new: one column serves `after:`, backoff and schedules.
- `job` and `schedule` are new surface; the laws they keep are CHANNELS'.
- `dead:` is the worker's, where CHANNELS put it on the queue. The worker's handler decides the error type, so the worker owns everything typed in it: the letter and the `failed` and `buried` events. A queue names no letter. (A component cannot infer one type parameter from a field while another is written; if it learns to, `dead:` may return.)
- The store is `ctx db`, where CHANNELS wrote `@store type Main` and `Tx<Main>`. One database needs no type to tell it apart; the dual-write check (`flow.dual_write`) reads the transaction value.

## 10. Decisions (owner, 2026-11-18)

1. The database is a context, `ctx db: Db`, not a `@store` type. A second database is a
   second named context; how a queue names it is a Q0 probe.
2. No `job fn` language mark. `job` is a component.
3. The body at rest is the stable byte codec, read by people through projections (§4).
   Fast is the substrate; readable is a projection of it.
4. Models stay `@model` types, not components (S6, 2026-09-24).
