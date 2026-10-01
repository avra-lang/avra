# @std/net

Stream sockets and readiness as values. A `Listener` is a bound port, a
`Conn` a stream, a `Poller` a readiness queue: kqueue on darwin, epoll on
linux. Every verb answers a `Result` whose failure names the verb, its
subject and the platform's errno.

```avra
use @std.net.{NetError, listen, connect}
use @std.time.{secs}

fn dialed() -> Result<int, NetError> {
    let l = listen("127.0.0.1", 0)?
    let c = connect("127.0.0.1", l.port, secs(1))?
    c.close()
}
```

## Surface

All of it is in `src/net.av`, imported as `@std.net`.

| Export | What it is |
|---|---|
| `NetError` | A failed verb: `verb`, `subject`, `errno`, and `denied`, the address an admission refused. `timed_out()` says whether a deadline ended it, `closed()` whether the conn was already closed. Implements `Error`. |
| `Listener` | A bound, listening port. `port` is the one the kernel gave. |
| `Conn` | A nonblocking stream to a peer: its `fd`, and an `open` cell every copy shares. |
| `Poller` | A readiness queue over descriptors. |
| `Event` | One readiness report: `fd`, `readable`, `writable`, `hangup`, `failed`. |
| `Interest` | What a poller watches for: `Read`, `Write`, `Both`, `None`. |
| `Read` | What `try_read` found: `Data(b)`, `Eof`, `Pending`. |
| `Address` | A resolved address: `family` (`V4`, `V6`) and its canonical `text`. |
| `Admission` | Which resolved addresses a connect may dial: `Anywhere`, `Public`, or `Where(admits)`. |
| `public(a)` | Whether the public internet routes to `a`; any non-canonical spelling is refused. |
| `Bell`, `bell()` | A doorbell tasks park on: `bell()` opens one its owner holds until `close`; `Bell {}` opens with its first waiter and closes behind its last. |
| `listen(host, port)` | A listener on one named interface. Port 0 is the kernel's choice. |
| `listen_all(port)` | A listener on every interface. |
| `connect(host, port, timeout, admission)` | A connection made within `timeout`, across every resolved address `admission` admits (default `.Anywhere`). |
| `poller()` | A new readiness queue. |

Methods:

| Method | What it does |
|---|---|
| `Listener.accept()` | The next connection; parks the task until one arrives. |
| `Listener.try_accept()` | The next pending connection, or null. Never waits. |
| `Listener.close()` | Closes; answers the port. |
| `Conn.read(max)` | Up to `max` bytes, parking until some arrive; null once the peer finished writing. |
| `Conn.write(bytes)` | All of `bytes`, parking while the socket is full. |
| `Conn.try_read(max)` | `.Data`, `.Eof` or `.Pending`. Never waits. |
| `Conn.try_write(bytes, from)` | As much as the socket takes from `from`; 0 when it would block. |
| `Conn.shutdown_write()` | Closes the write side; the peer reads EOF. |
| `Conn.close()` | Closes in every copy; answers the descriptor. |
| `Conn.live(verb)` | The descriptor while open; refused as closed, naming `verb`, once any copy closed it. |
| `Conn.peer()` | The peer as `ip:port`, v6 in brackets; `""` once gone. |
| `Conn.address()` | The peer's `Address`, or null once gone. |
| `Conn.named()` | The connection's name in a refusal. |
| `Poller.watch(fd, interest)` | Sets interest in `fd`; `.None` stops watching. |
| `Poller.wait(timeout)` | The descriptors ready now; a null timeout waits until one is. |
| `Poller.close()` | Closes the queue. |
| `Bell.waited(timeout)` | Parks until a ring, the task's `within` or `timeout` (null: none); either deadline fails it `timed_out()`. |
| `Bell.ring()` | Wakes every parked task, and counts the ring. |
| `Bell.rouse()` | Wakes every parked task, uncounted. |
| `Bell.rings()` | How many times it has rung. |
| `Bell.waited_since(seen, timeout)` | `waited`, unless it has rung since `seen` rings — then at once. |
| `Bell.close()` | Closes its pipe and lets go of it; a parked task wakes. |

## Laws

- **Parking verbs park the task, not the process.** `accept`, `read`,
  `write` and `connect` park the calling task; other tasks run meanwhile.
  Inside a `within`, a park that outlasts it fails the verb with
  `timed_out()` true. The `try_` twins never wait.
- **A budget is never a sentinel.** A negative `timeout` is refused, never
  read as "forever". Forever is a null `Poller.wait` timeout. A zero
  `connect` budget looks once.
- **A closed conn is closed in every copy.** The kernel hands a closed
  descriptor's number to the next connection, so every `Conn` verb reaches
  the kernel through `live`, which asks the `open` cell the copies share.
  A verb on a closed conn, through any copy, is refused with `closed()`
  true and never touches the number.
- **Admission judges the resolved address, never the name.** `connect`
  resolves, drops every address its `Admission` refuses, and dials the
  rest by literal — the list judged is the list dialed, so a name that
  answers differently later cannot slip past. All refused is a
  `NetError` whose `denied` names the first. `public` withholds the
  loopback, this network, private, shared, link-local (cloud metadata),
  unique local, multicast, documentation and reserved blocks, and judges
  a mapped, NAT64 or 6to4 v6 address as the v4 one it carries.
- **A waiting task costs nothing until it is woken.** A `Bell` parks
  its waiters on a pipe the scheduler watches; one nobody holds is opened
  by the first waiter and closed behind the last, so an idle bell holds
  nothing. A ring nobody waits for is kept by nobody, and costs no write:
  a waiter looks at what it waits for BEFORE it parks, and no task runs
  between the look and the park. A task that may pause between the two
  counts the rings first and parks with `waited_since`.
- **One interface, or all, asked for by name.** `listen("")` is refused;
  the wildcard is `listen_all`.
- **The NUL boundary.** A host crosses to the resolver as a C string, so a
  host that is empty or holds a NUL is refused before it crosses. Judge
  text bound for C over its bytes, never with `==`. See CLAUDE.md, "A GUARD
  IS A PROPERTY OF EVERY CROSSING".
- **The C borrows, and answers ints only.** `src/c/std_net.c` answers a
  descriptor, a count or a negative errno, never a box. It borrows every
  argument and keeps none. Bytes cross only through the runtime's
  descriptor rows (`avra_fd_read`, `avra_fd_write`). See
  `docs/2026_09_07_PACKAGE_C_STANDARD.md` §2.4.
- **Level-triggered readiness.** One read per wake is correct, and a
  handler that stops early cannot stall.

## Tests

```sh
make libs                         # each package's library; the evaluator binds C through it
build/avra test packages/std-net  # every test, evaluator and native
```

Tests live in `src/tests/`: module tests (`net_test.av`,
`net_adversarial_test.av`) and program tests, one directory each.

## Roadmap

`docs/2026_09_29_HTTP_ROADMAP.md`.
