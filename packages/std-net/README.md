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
| `NetError` | A failed verb: `verb`, `subject`, `errno`. `timed_out()` says whether a deadline ended it. Implements `Error`. |
| `Listener` | A bound, listening port. `port` is the one the kernel gave. |
| `Conn` | A nonblocking stream to a peer. |
| `Poller` | A readiness queue over descriptors. |
| `Event` | One readiness report: `fd`, `readable`, `writable`, `hangup`, `failed`. |
| `Interest` | What a poller watches for: `Read`, `Write`, `Both`, `None`. |
| `Read` | What `try_read` found: `Data(b)`, `Eof`, `Pending`. |
| `listen(host, port)` | A listener on one named interface. Port 0 is the kernel's choice. |
| `listen_all(port)` | A listener on every interface. |
| `connect(host, port, timeout)` | A connection made within `timeout`, across every address the host resolves to. |
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
| `Conn.close()` | Closes; answers the descriptor. |
| `Conn.peer()` | The peer as `ip:port`, v6 in brackets; `""` once gone. |
| `Conn.named()` | The connection's name in a refusal. |
| `Poller.watch(fd, interest)` | Sets interest in `fd`; `.None` stops watching. |
| `Poller.wait(timeout)` | The descriptors ready now; a null timeout waits until one is. |
| `Poller.close()` | Closes the queue. |

## Laws

- **Parking verbs park the task, not the process.** `accept`, `read`,
  `write` and `connect` park the calling task; other tasks run meanwhile.
  Inside a `within`, a park that outlasts it fails the verb with
  `timed_out()` true. The `try_` twins never wait.
- **A budget is never a sentinel.** A negative `timeout` is refused, never
  read as "forever". Forever is a null `Poller.wait` timeout. A zero
  `connect` budget looks once.
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
make objects                      # builds build/std_net.o
build/avra test packages/std-net  # every test, evaluator and native
```

Tests live in `src/tests/`: module tests (`net_test.av`,
`net_adversarial_test.av`) and program tests, one directory each.

## Roadmap

`docs/2026_09_29_HTTP_ROADMAP.md`.
