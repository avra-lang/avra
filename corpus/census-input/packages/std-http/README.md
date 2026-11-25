# @std/http

HTTP/1.1, strict and small: a framer over bytes, a router, a server loop
and a client. It sits on `@std/net`.

```avra
use @std.http.route.{get}
use @std.http.server.{server}

export server app {
    port: 8080
    get "/health" { _req -> "ok" }
    get "/ideas/{id}" { req -> "idea " + req.params.id }
}

let _ = app.run()
```

## Modules

Each module is imported by its own path:
`use @std.http.frame.{…}`, `@std.http.http`, `@std.http.query`,
`@std.http.route`, `@std.http.server`, `@std.http.client`.

| Module | Owns |
|---|---|
| `frame` | The framer: a head over `Bytes`, stateless and strict. |
| `http` | The values a handler sees and answers. |
| `query` | What follows the target's `?`, as keyed fields over raw octets. |
| `route` | The router: a route is a grammar over the path. |
| `server` | The loop: a listener, a handler, one task per connection. |
| `client` | One connection as a value, the reply framed as it arrives. |

### `frame`

| Export | What it is |
|---|---|
| `Span` | A byte range in the buffer a head was framed from. |
| `Field` | One field line as two spans. |
| `Fields` | A head's fields as four offsets each; `count`, `field(i)`, `named(buf, wanted)`. |
| `Method` | The nine registered methods, and `Other`. |
| `TargetForm` | `Origin`, `Absolute`, `Asterisk`, `Authority`, `Other`. |
| `Body` | How a request body is delimited: `None`, `Length(n)`, `Chunked`. |
| `Head` | A framed head; `end` is the first byte past the blank line. |
| `Refusal` | Why a head was refused. Each variant is one law. |
| `Framed` | `Partial`, `Complete(head)` or `Refused(why)`. |
| `Limits` | The bounds a server names: line, field, head, fields, body, ext, trailers. |
| `limits()` | The default bounds. |
| `status_of(why)` | The status a refusal earns. |
| `admits(pred)` | A 256-entry class table from a predicate. |
| `is_tchar(c)` | Whether an octet may be in a token. |
| `is_vchar(c)` | Whether an octet may be in a field value. |
| `is_target(c)` | Whether an octet may be in a request target. |
| `framed(buf, from, scanned, limits)` | The head at `from`, or why not. |
| `target_form(buf, method, lo, hi)` | Which form a target is in. |
| `scheme_end` | The octets `://`. |
| `Reply` | A framed reply. |
| `ReplyBody` | `None`, `Length(n)`, `Chunked`, `UntilClose`. |
| `FramedReply` | `Framed`'s twin for a reply. |
| `framed_reply(buf, from, scanned, limits, asked)` | The reply at `from` to a request made with `asked`. |
| `Phase` | Where a chunked decode stands. |
| `Chunker` | A chunked body in flight. |
| `chunker(at)` | A decoder starting at `at`. |
| `Chunked` | What a fed decoder answers. |
| `fed(c, buf, limits)` | The decoder advanced over `buf`. |
| `hex_of(c)` | One hex digit's value, or null. |

### `http`

| Export | What it is |
|---|---|
| `Request<P>` | The raw buffer, the head, the body, the peer, and the route's `params`. |
| `Unrouted` | The params of a request no route has read. |
| `Header` | One outgoing field: `name`, `value`. |
| `Response` | `status`, `headers`, `body`. `content-length` is written from the body. |
| `Handler` | `fn(Request<Unrouted>) -> Response`. |
| `Respond` | What a handler may answer: a `Response`, a `string` as a 200, an `int` as a status. |
| `text(status, body)` | A plain-text response. |
| `ok(body)` | A 200 of plain text. |
| `status(code)` | A bare status. |
| `reason(status)` | The reason phrase. |
| `wire(r, keep_alive, minor)` | The response as bytes on the wire. |
| `as_sent(r)` | `r` when a peer could read it, the server's own 500 when not. |
| `sendable(r)` | Whether a response can go on a wire at all. |
| `fields_writable(headers, written_by)` | Whether every field is framable and none is one the writer writes itself. |
| `writable(h)` | Whether one field obeys the framer's classes. |
| `every_octet(s, class)` | Whether every octet of `s` is in `class`. |
| `names_one_of(name, written_by)` | Whether `name` is one of `written_by`, ASCII-folded. |
| `token_char`, `value_char` | The class tables for a field name and a field value. |
| `separates(b, i)` | Whether a segment ends at offset `i`. |
| `falls_under(path, prefix)` | Whether `path` is `prefix` or beneath it, by whole segments. |
| `read_size()` | How much a socket is asked for per read. |

`Request` methods: `method()`, `target()`, `path()`, `query()`,
`queried()`, `header(name)`, `under(prefix)`, `form()`, `authority()`,
`absolute_path()`.

### `query`

| Export | What it is |
|---|---|
| `Pair` | One `name=value` as spans; `value` is null when there was no `=`. |
| `Query` | The pairs in encounter order: `length`, `has`, `names`, `one`, `all`. |
| `Asked` | What `one(name)` answers: `Absent`, `Bare`, `Value(v)`, `Repeated(times)`. |
| `query_of(raw, lo, hi)` | The query between `lo` and `hi`. |
| `decoded(b)` | Percent-decoding; null for a malformed escape. |

### `route`

| Export | What it is |
|---|---|
| `Reach` | How far a route reaches: `Literal`, `Width`, `Rest`. |
| `Route` | A method, a pattern, a reach and a handler. |
| `routed(…)` | A route from a grammar's reader and a typed handler. |
| `fixed(method, path, serve)` | A route with no holes. |
| `tailed(…)` | A route whose last hole takes the rest. |
| `declared(…)` | A route whose pattern declares its reach. |
| `get`, `post`, `put`, `patch`, `delete` | Route components: `get "/ideas/{id}" { req -> … }`. |
| `group` | Routes under a prefix: `group "/api" { … }`. |
| `prefixed(prefix, routes)` | The same, as a function. |
| `segments(b)` | How many segments a target or pattern has. |
| `Table` | A route table compiled once. |
| `compiled(routes)` | Compiles the table. Call it from a `once fn`. |
| `dispatch(t, q)` | The first route whose method and target both answer. |
| `faults(routes)` | What is wrong with a table, named. |

### `server`

| Export | What it is |
|---|---|
| `server` | Component: `server app { port: 8080  get "/" { … } }`. `listening()` binds it, `run()` serves it. |
| `layer` | Component: `layer auth { req, next -> … }`, a fn every request passes through. |
| `Timing` | The deadlines: `handshake`, `head`, `body`, `idle`, `requests`; and `handshakes`, the TLS handshakes a core runs at once (past them a connection is closed before its opener runs). |
| `timing()` | The default deadlines. |
| `Server<A>` | A listener, the maker of each core's app, and the handler. |
| `served(…)` | A server on a listener, each core's app made by `make`. |
| `Stateless` | The app of a server of routes alone. |
| `every_core()` | Every core this process may run on. |

`Server` methods: `run(cores)`, `stop()`, `connections()`,
`accepting(app)`.

### `client`

| Export | What it is |
|---|---|
| `Client` | A connection with a request in flight. |
| `Answer` | `status`, `headers`, `body`; `header(name)`. |
| `ClientError` | `Net(e)`, `Refused(why)`, `Closed`, `TimedOut`. Implements `Error`. |
| `connected(host, port, timeout, limits)` | A client connected within `timeout`. |
| `request(method, target, host, headers, body)` | A request as bytes, or null when a word or field breaks the framer's law. |

`Client` methods: `sent`, `received`, `fetched(asked, req, deadline)`,
`close()`.

## Laws

- **Strict framing.** Every grammar-widening MAY in RFC 9112 is refused.
  Each refusal is a `Refusal`, its status is `status_of`, and the
  connection closes behind it. The laws and their RFC sections:
  `docs/2026_09_06_HTTP_FRAMING_LAWS.md`.
- **A writer obeys the reader's law.** A `Response` whose status or fields
  the framer would refuse goes out as the server's own 500 (`as_sent`).
  `request` answers null rather than write such a request.
- **The NUL boundary.** A field value is visible ASCII and HTAB, and a
  target is visible ASCII plus `obs-text`, so a NUL in either is refused
  at framing. Text never crosses to C from here; sockets are `@std/net`'s.
- **A route matches the path, never the query.** A hole is one segment; a
  last hole marked `...` takes the rest. Declaration order picks among
  routes that answer, and `faults` names a route an earlier one shadows.
- **The query is raw octets.** `%26` is not `&`, `+` is not a space, `;`
  is not a separator. `decoded` is the only decoder. A repeated scalar
  answers `.Repeated`, never a side.
- **State.** Each core makes its own app. A plain field is one
  connection's copy; state shared across a core's connections lives in a
  `Cell`. A core that crashes stops the server.
- **C.** This package has no C. `@std/net`'s README states the borrowed
  argument law its C follows.

## Tests

```sh
make libs                          # each package's library; the evaluator binds C through it
build/avra test packages/std-http  # every test, evaluator and native
```

Tests live in `src/tests/`: module tests (`*_test.av`, with
`*_adversarial_test.av` for hostile input) and program tests, one
directory each.

## Roadmap

`docs/2026_09_29_HTTP_ROADMAP.md`.
