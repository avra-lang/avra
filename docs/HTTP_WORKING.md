# HTTP working state

- Worktree `../avra-lane-http`, branch `lane/http`. Taken over 2026-09-06 by
  session avra-2a [1fab91] after the first session died; fast-forwarded to main
  at `957ba39`. The design papers are `2026_09_06_STD_HTTP_DESIGN.md` and
  `2026_09_06_STD_HTTP_TYPED_ROUTES.md`; framing laws arrive in
  `2026_09_06_HTTP_FRAMING_LAWS.md` (research agent, in flight).
- Mandate: `@std.http` client and server, backbone-grade performance, tiny and
  idiomatic; build missing foundations, never entrench a workaround. Every
  slice: `/red-team`, then `/review-round`. No commits without the owner's
  word; nothing merges from this lane until the owner rules on each
  capability (lane A: whether Avra gains a value type is the OWNER's call).

## Slice 1 — `Bytes` (BUILT, suite green, awaiting the owner's ruling)

The shape: `docs/2026_09_05_BYTES_SHAPE.md` (the sqlite campaign's paper,
written for lane A, never lane A's) with three deviations ruled correct by
lane A on the merits: `at` traps through `trap_bounds` (never -1), `slice`
traps through `trap_slice` (never clamps — a short answer parses), and NO
view kind (a view's pointer is not its data, so it breaks "a Bytes crosses as
Ptr"; a tiny view pins a receive buffer). Slices copy; the HTTP parser is
index-driven. The spare byte past the length is a NUL, by lane A's overrule
of my 0xFF: a poison byte makes an accidental C-string read a heap over-read
on network data, a NUL makes it a bounded truncation.

- Surface: `s.bytes()` (total), `[ints].bytes() -> Bytes?` (null past a
  byte), `b.text() -> string?` (null unless UTF-8; a NUL IS text — lane B's
  warning stands: the five C-string primitives on `string` are the debt, see
  ROADMAP H1), `.length`, `is_empty`, `at`, `slice`, `concat`,
  `index_of(needle, from)` (-1 on a miss; `from` may equal the length; empty
  needle found at `from`), `==`/`!=` over every byte, `Bytes?` niche-encoded.
  THE SCANS, added after the framing-laws paper (§2.5: a parser asks where a
  token ends, never what each byte is): `run(from, table)` — the end of the
  run a 256-byte class table admits, `eq_at(lo, hi, needle)`, `ieq_at` (ASCII
  letters folded). Thirteen rows; `corpus/bytes_scan.av`; two more trap rows.
- Runtime: one section in `runtime/avra_runtime.c` (`KIND_BYTES = 4`,
  `ACC_BYTES`, `box_bytes` +1 arm, no release arm), ten rows in `rt_sigs`,
  `RtHost` variants, the validator from the runtime-diff paper. Review patch
  for lane A: `docs/patches/bytes-runtime.diff` (delete before committing).
- Evaluator: `Val.Y(v: List<int>)`, held directly and PERMANENTLY (lane C:
  immutable means no identity means no handle), `language/interp_bytes.av`.
- Two collapses in lane C's files, verified by lane C and asked to land ALONE
  ahead of the ruling: `worded` exported from `features/checks.av` (str_lit
  imports it), `lower_is_empty` exported from `features/emit.av` (str_lit and
  lists deleted their copies; lane C proved the short form expands to the
  long one).
- Proof: corpus/bytes.av (eval == native), corpus/bytes-header (native-only,
  the text row reads a Bytes' header through the extern door), 41 `then`
  cases in features/bytes/tests, three rows in tools/traps.sh,
  `AVRA_RC_GUARD=1` clean, `make idioms`/`vocab`/`externs` green,
  `./avra test packages/std-avrac` 1968/1968.
- Owed: lane A's `DEMANDS` in tools/externs.py must learn `Bytes` the hour it
  lands (every Bytes extern seat is unchecked until then); lane B lands
  `read_bytes`/`write_bytes` on the seed; ROADMAP entries (Axis 18 wanting
  site, typed captures wanting site, H1's decision).

## Slice 2 — the net substrate (BUILT, split out of core on the owner's word)

THE STANDARD the owner set on 2026-09-06 (the substrate lane writes it
up and applies it to io and process): CORE owns the language's own
substrate — boxes, strings, lists, maps, Bytes, float, the process's
own facts, and DESCRIPTORS (`avra_fd_read` into a scratch,
`avra_fd_taken` minting the box once, `avra_fd_write` from an offset),
because a managed value is minted ONLY by a core row — and that law is
MECHANICAL, not moral (the substrate lane measured it): an `extern fn`
that is not a row has `owns_result: false` hard-coded, so what it mints
is never released; `avra_fd_taken` as a bare extern leaked 3 MB per
200k takes, 0 as a row. The three doors are `rt_sigs` rows with
`RtHost` variants and evaluator arms, so the evaluator hosts the fd
half; the socket half stays native-only. Everything
socket-shaped is `packages/std-net/src/c/net.c`, built to
`build/std_net.o` by the Makefile, linked by the manifest's `[link]`,
declared by `extern fn` in `net.av`, answering ints only (a peer
address comes back as words the package formats). SIGPIPE is ignored
at the FIRST SOCKET VERB, never at load, so a program that opens no
socket keeps the platform's convention. The evaluator hosts no socket
row: `corpus/net` is native-only until the substrate lane's extern
host lands. Level-triggered on both platforms; kqueue reports read
and write as two events per descriptor, epoll as one; act on every
event or unwatch. The C was drafted by agent `net-substrate` (109
loopback checks) and integrated by hand.

The face, `@std.net`: `listen(host, port)`, `connect(host, port,
timeout)`, `poller()`, `Listener.accept() -> Conn?`, `Conn.read(max)
-> Read` (`.Data(b)`, `.Eof`, `.Pending`), `Conn.write(b, from) ->
int` (0 when it would block), `shutdown_write`, `close`, `peer`,
`Poller.watch(fd, readable, writable)`, `wait(timeout?) ->
List<Event>`; every failure a `NetError { verb, subject, errno }`
implementing `Error`. Loopback spec in `packages/std-net/src/tests`.

## Slice 3 — `@std.http` (IN PROGRESS)

`frame.av`: the framer, stateless and strict (every widening MAY
refused; a refusal names its law and its status; every line end CRLF),
index-driven over `run`/`index_of`/`eq_at`/`ieq_at`; the chunked
decoder is RESUMABLE (`chunker`/`fed`, a `Phase`), never a re-walk;
45 attack-table rows pinned in `tests/frame_test.av`. `http.av`:
`Request` (spans into its own buffer; `header(name)` slices on ask),
`Response`, `wire`, `reason`. NEXT: `server.av` (the event loop, a
handler `fn(mut A, Request) -> Response`, app state threaded as a
value), the response framer, `client.av`. The strings lane's typed
patterns will replace the hand-written scans; until then the framer is
the oracle they are measured against.

## Slice 3 — `@std.http` (AFTER)

Message types, an index-driven HTTP/1.1 framer over `Bytes`, a route trie
compiled once, the server loop, a blocking client. Then `/red-team`,
`/review-round`, benchmarks against nginx/h2o numbers.
