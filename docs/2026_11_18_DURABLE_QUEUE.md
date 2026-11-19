# The durable queue — design

Status: PROPOSED 2026-11-18. Nothing here is probed yet; §8 lists the probes owed first.
Ticket `avra-8sb5.98.8`. Epic for jobs: `avra-8sb5.64.1`.

This is the build design for one home of `2026_10_05_CHANNELS.md` (FLOW, decided v4):
the queue homed in the program's own store (§6.4 there), its worker (§2.4, §7.1),
and jobs and schedules on top. That document decides the laws. This one decides the
surface, the packages and the slices. Where they differ, §9 says so.

## 1. What an author writes

One declaration. `store:` is the only line that makes it durable.

```avra
use @std.queue.{queue, worker, schedule, Delivery, Dead}
use @std.db.{store}
use @std.time.{secs, hours, cron}

@store type App = { path: string = "app.db" }

type Email = { to: string, subject: string, body: string }

queue<Email> emails {
    store: App
    retries: 5
    backoff: secs(5)
    dedupe: hours(24)
    dead: undeliverable
}

queue<Dead<Email, SmtpError>> undeliverable { store: App }

worker sender {
    reads: emails
    at_once: 10
    each: deliver
}

fn deliver(d: Delivery<Email>) -> Result<string, SmtpError> { smtp_send(d.item) }
```

Sending, alone and inside the caller's transaction:

```avra
emails.send(welcome(u), id: "welcome-${u.id}")?

let tx = App.begin()?
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
    store: App
    retries: 3
    each: (d: Delivery<Upload>) -> thumbnails(d.item)
}

resize.later(upload)?
```

## 2. What it promises

| Promise | How it is kept |
|---|---|
| A sent item is never lost | a row, committed before `send` answers |
| At least once | a lease on the row; a crashed worker's lease runs out and the item is taken again |
| A stale worker cannot ack | every take raises the row's `epoch`; an ack with an old epoch answers `false` |
| One send per id within `dedupe` | `flow_seen` remembers the id and its answer |
| Exactly once for store writes | the handler's writes and the ack are one commit (`worker { store: App }` hands it the `Tx<App>`) |
| A poison item ends | an attempt is counted when the handler STARTS; past `retries` it is buried, never dropped |
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
| The body | T's stable byte codec from `@std/relation` (CHANNELS §6.3); a record may grow at its end |
| Waking | `@std/task`: a send in this process rings the queue's gate; another process polls every `min(patience, 250 ms)` |
| Time | `@std/time`: `Duration`, `now()`, `every`; `cron` is new there |
| Workers | `@std/task` tasks, `at_once` of them, cancelled as a scope |
| Operating it | `@std/crud` over `FlowItem` gives the admin router: list, peek, retry, discard |
| Reading it | `avra explain flow` prints each queue's home, terms, depth and who reads it |

Packages:
- `@std/queue` keeps the declaration, `Home`, and the memory home. It gains no dependency.
- `@std/queue_store` holds the store home and depends on `@std/db` and `@std/sqlite`.
  A program that never names `store:` links no SQLite.

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
- A dead letter is a queue; a buried item is a `FlowItem` under the letter's name, moved in one transaction.

| Verb | Statement |
|---|---|
| `send` | find the id in `FlowSeen`; present: answer what it answered. Absent: insert both rows |
| `take` | one `UPDATE … RETURNING` over the oldest ready rows with no live lease: set `reader`, `epoch + 1`, `leased_until` |
| `began` | `attempt + 1` where the epoch still matches; `false` if the lease was lost |
| `ack` | delete where id and epoch match; 0 rows is `false` |
| `release` | clear the lease, set `ready_at = now + backoff` |
| `bury` | delete and insert under the letter, one transaction |

`take` is the wanting site for typed `sql{}` (44.6): it is the one statement the model
queries cannot say. Until that lands it is a prepared `@std/sqlite` statement.

## 5. The worker loop

`run(sender)` lives as long as its scope. `drain(sender)` (today's verb) stays: run to empty, for tests and scripts.

1. Take up to `at_once - busy` items; park on the gate when there are none.
2. For each: `began`, run the handler in its own task under the lease as a deadline.
3. `Ok` acks. `Err` releases with `backoff × 2^attempt` (capped), or buries past `retries`.
4. A handler that outlives its lease is cancelled; the item is taken again elsewhere.
5. On cancel: stop taking, let running handlers finish inside their leases, release the rest.

- The handler's error type is its own: `each: fn(Delivery<T>) -> Result<R, E>`, and the letter is `Dead<T, E>`.
  Today both are `string`.
- A schedule needs no leader. Every process computes the same tick and sends with
  id `"<schedule>@<tick>"`; `dedupe` makes it one item however many processes run.
- Blocking: a SQLite call blocks its core (CHANNELS §6.1). Takes and acks are batched
  per turn so a busy worker pays one transaction per batch, not per item.

## 6. Testing

- The same declaration with no `store:` is the memory home: unit tests need no file.
- `Db.memory()` as the store runs every store statement with no disk.
- The crash witness: a program test whose child takes an item and exits without acking;
  the parent reopens the file and takes it again with `epoch + 1`.
- The two-process witness: two children share one file, send and take concurrently;
  every id is handled, none twice under `store:` handlers.
- Each verb above has its attack in CHANNELS §3. Those move from the memory home's tests to a shared set both homes run.

## 7. What it asks of the language

To the lead as a list, one sample each, before the slice that needs it. None blocks Q1–Q3.

| Ask | Needed by | Without it |
|---|---|---|
| `@store` on a type, and `Tx<S>` | Q4 | a library derive may do; probe first |
| A named argument on a component method call (`send(v, id:, after:)`) | Q2 | probe; may work today |
| `effect`, `reading` marks and the `keyed` seat | exactly once for outside effects | at least once, printed with a warning |
| Typed `sql{}` | `take` | a prepared statement |
| `job` as a `fn` mark (`job fn resize(u: Upload)`) | nicer than the component | the `job` component |

## 8. Slices

Each is one commit set on `services`, red-teamed, its own suite green.

| Slice | What lands | Works after it |
|---|---|---|
| Q0 | the probes: a type as a component setting, named args on `send`, `@model` with `Bytes`, `UPDATE … RETURNING` through std-sqlite | the surface in §1 is confirmed or corrected |
| Q1 | `Home` under `Queue<T>`; memory home behind it; handler error generic | today's 11 tests, unchanged |
| Q2 | `@std/queue_store`: rows, send, take, ack, release, bury, dedupe | a queue survives a restart; the crash witness |
| Q3 | `run`: `at_once`, backoff, lease deadline, shutdown, gate and poll | a long-lived worker; the two-process witness |
| Q4 | `@store`, `tx.send`, a worker's `store:` | exactly once for store writes |
| Q5 | `after:`, `cron`, `schedule` | delayed and recurring work |
| Q6 | `job`, the admin router, `explain flow` | the one-declaration job; operating it |

Later, not in this run: the remote home over HTTPS (CHANNELS §6.5), effect contracts (§7.2), Postgres.

## 9. Where this differs from CHANNELS

- The declaration is `queue<Email> emails { … }`, the component spelling that was built, not `queue emails of Email`.
- The tables are `@model` types, so std-db owns their migrations, where CHANNELS wrote SQL.
- `ready_at` is new: one column serves `after:`, backoff and schedules.
- `job` and `schedule` are new surface; the laws they keep are CHANNELS'.

## 10. Open decisions

1. Store handle: `@store type App` (as decided in CHANNELS) or a plain `Db` value passed to `send` and `run`.
2. Job surface now: the `job` component, with `job fn` recorded as a language ask; or wait for the mark.
3. Body encoding: the stable byte codec (decided; compact, grows at the end) or JSON text (readable with any SQLite tool, slower).
