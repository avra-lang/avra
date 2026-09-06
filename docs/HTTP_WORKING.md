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

## Slice 2 — the net substrate (NEXT)

Runtime rows, one section beside the process rows: listen/accept/connect,
nonblocking read (an exact-size Bytes) and write (a count from an offset),
close/shutdown, and a readiness poller (kqueue on darwin, epoll on linux) —
`poll_new`, `watch`, `wait`, `event_fd`, `event_flags`. The HTTP server is an
event loop in Avra over these until Axis 18's fibers exist; the handler is
`fn(Request) -> Response`, synchronous, so the API is fiber-shaped from day
one. C draft by agent `net-substrate` in the scratchpad; integrated by hand.

## Slice 3 — `@std.http` (AFTER)

Message types, an index-driven HTTP/1.1 framer over `Bytes`, a route trie
compiled once, the server loop, a blocking client. Then `/red-team`,
`/review-round`, benchmarks against nginx/h2o numbers.
