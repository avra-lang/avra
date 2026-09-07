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
own facts, and DESCRIPTORS (`avra_fd_read` into ONE scratch, answering
a TOKEN — the scratch's generation — that `avra_fd_taken(token)` must
present, trapping on a stale one, so a read landing between a read and
its take is a loud wreck and never a stranger's bytes — lane B's
finding, reviewing io's shape; `avra_fd_write` from an offset),
because a managed value is minted ONLY by a core row — and that law is
MECHANICAL, not moral (the substrate lane measured it): an `extern fn`
that is not a row has `owns_result: false` hard-coded, so what it mints
is never released; `avra_fd_taken` as a bare extern leaked 3 MB per
200k takes, 0 as a row. The three doors are `rt_sigs` rows with
`RtHost` variants and evaluator arms, so the evaluator hosts the fd
half; the socket half stays native-only. AND THE SECOND-BUILD RULE
HELD, measured: a compiled program stopped leaking after one `make
avra`, the EVALUATOR only after the second (3 MB then 0), because the
product's own body was compiled by the pre-row binary. Everything
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
implementing `Error`. Loopback spec in `packages/std-net/src/tests`; the red team's survivors
in `net_adversarial_test.av`. RED-TEAMED 2026-09-07 (13 programs, native):
every wrong type in every slot refuses once in its own words (a text
port, an int host, a bool interest, a string body, an int timeout); the
edges hold. Three findings, all fixed: a NEGATIVE `Duration` reached
`connect` as "forever" (a sentinel in a value — refused now, a zero
budget looks once); a read or write on a gone peer named an EMPTY
subject (it names the descriptor now); the poller's wait named nothing.
ONE HAZARD RECORDED, NOT FIXED: a closed descriptor's NUMBER is reused
by the next open, so a stale `Conn` value's `close()` can close a
stranger — the answer is the ROADMAP's generation-tagged handle table,
which needs process-wide package state (sugar backlog); until then a
`Conn` is used once and dropped, and the tests pin the refusal words
for the honest case (EBADF).

## Slice 3 — `@std.http` (IN PROGRESS)

`frame.av`: the framer, stateless and strict (every widening MAY
refused; a refusal names its law and its status; every line end CRLF),
index-driven over `run`/`index_of`/`eq_at`/`ieq_at`; the chunked
decoder is RESUMABLE (`chunker`/`fed`, a `Phase`), never a re-walk;
45 attack-table rows pinned in `tests/frame_test.av`. `http.av`:
`Request` (spans into its own buffer; `header(name)` slices on ask),
`Response`, `wire`, `reason`. THE FRAMER'S COST, MEASURED (bench in
`corpus/build/bench-frame`, ignored): 3457 ns per four-field 112-byte
head natively, an order of magnitude off picohttpparser's 366 ns for
nine fields. Sampled top of stack: `once` reads a THIRD (`once_at` does
a strcmp per earlier entry on every read — lane A's, asked with the
numbers), refcount traffic a third (the `with`-copied `Framing` per
field and the per-field boxes — mine, to measure after lane A's fix),
the scans a tenth, the framer's own code three percent. Not hoisted
around: the code reads as it should. NEXT: `server.av` (the event loop, a
handler `fn(mut A, Request) -> Response`, app state threaded as a
value), the response framer, `client.av`. The strings lane's typed
patterns are LANDED on this branch (e49a637): `"{method} {path}
HTTP/{major}.{minor}"` binds from one scan, 120 ns against 90 ns by
hand, an untaken arm mints nothing; typed holes wait on the decimal
row; the framer's own scans stay until the `Bytes`-subject parity is
measured (the strings lane's S3), then they become patterns.

## Sub-lane: substrate — S3 (io) rulings

THREE DECISIONS, ALL MEASURED BY THE LANE, RULED 2026-09-07. (1) `avra_io_env`
STAYS A CORE ROW beside `avra_io_list`, both landing through the descriptor
scratch: a package's C cannot reach `fd_landed`, and the standard's roster
already names the environment as the process's own fact — a law, not an
exception. (2) `read_text` VALIDATES UTF-8 (lane B's word): every file the
compiler reads was scanned, 547, zero invalid; a stray `0xff` in a STRING
LITERAL passes `check` clean today, so the change closes a silent hole. The
refusal carries the PATH AND THE BYTE OFFSET (`utf8_bad_at`, never
`Bytes.text() ?? fail`, which throws the offset away), the scan folds into
the read loop's one pass, and `read_bytes` lands in the same slice as the
lossless twin — split the verb, one per promise. (3) THE FIFO stays
BLOCKING and `Other` is not refused: `read_text("/dev/null")` answers `""`
today and `/dev/null` is `Other`, so a refusal would newly reject a
legitimate read; the artifact is one doc sentence on `read_text` naming the
block and `kind_of` as the question to ask first. THE CORE DELETIONS (rows,
`RtHost` variants, evaluator arms leaving core) are the lane's to write, in
lane A's and lane C's files, for their review before merge — both told.

## Slice 3 — `@std.http` (AFTER)

Message types, an index-driven HTTP/1.1 framer over `Bytes`, a route trie
compiled once, the server loop, a blocking client. Then `/red-team`,
`/review-round`, benchmarks against nginx/h2o numbers.
