# HTTP roadmap — the world's best HTTP library and server

Epic: `avra-8sb5.1`. This is the ONE plan for `@std/net` + `@std/http`;
every open HTTP ticket sits under that epic (tasks db, `tasks tree
avra-8sb5.1`). The other HTTP documents are law or history, listed at
the end. Numbers here are claims until `tools/bench` reproduces them.

## Where it stands (main, 2026-09-29)

Landed, both engines, 447 std-http + 25 std-net tests: an HTTP/1.1
framer over `Bytes` (chunked both ways, pipelining, 100-continue, HEAD,
limits, typed refusals), a route trie with typed routes, the query
reader, a server with one task per connection and one process per
core, a blocking client with deadlines. Three red teams, ~400 programs.

| one core, Linux Sprite | Avra | C floor |
|---|---|---|
| wrk pipelined x16, c=200 | 330k req/s, 3.05 µs CPU | 1.14M, 0.88 µs |
| wrk keep-alive, c=50 | 56.6k | 72.7k |
| 4 cores | 3.8 to 4.5x one core | the kernel's scaling |

Not built, at all: TLS, HTTP/2, streaming bodies, SSE, WebSocket, a URL
type, DNS off the loop, a connection pool, redirects, cookies, forms,
static files, compression, CORS, OpenAPI, graceful drain.

## The sub-epics

| id | name | prio | depends on |
|---|---|---|---|
| `.1.24` | H1 hygiene — open bugs and debts of the 1.1 core | P1 | — |
| `.1.25` | H2 transport security — `@std/tls`, HTTPS both sides | P0 | — |
| `.1.26` | H3 streaming — body streams, SSE, WebSocket, backpressure | P0 | — |
| `.1.27` | H4 HTTP/2 (HTTP/3 recorded) | P1 | H2 ALPN, H3 body stream |
| `.1.28` | H5 client tier — URL, DNS, pool, redirects, `http.get(url)?` | P1 | https from H2 |
| `.1.29` | H6 app tier — cookies, forms, static, compression, CORS, OpenAPI | P1 | multipart from H3; json floats |
| `.34` | H7 the C level — per-request cost to the floor | P1 | — |
| `.1.30` | H8 conformance + hardening — RFC checklist, fuzz, soak | P1 | rolling |
| `.1.31` | H9 docs — one HTTP doc set | P2 | — |

## The plan, parallelised

Five lanes run at once from day one; two join later. Each lane is one
worktree off main, lands slices through `tools/land.sh` as they gate,
and each slice carries its red team and review round.

```
week   1        2        3        4        5        6        7        8
H1  ████████
H2  ████████████████████████                    (TLS lib → TlsConn → certs → ALPN → http over tls → red team)
H3  ████████████████████████                    (resp stream → req stream → SSE → WebSocket → Autobahn)
H5  ████████████████████████                    (url → dns → pool → request api → policy → red team)
H6  ████████████████████████████████            (cookies, forms*, static, encoding, json, CORS, OpenAPI)
H4                          ████████████████████ (HPACK ∥ framing → server → h2spec → client)
H7  ████████████████████████████████████████    (batched writes, bench harness, then levers by census)
H8          ████████████████████████████████████ (checklist, fuzz, soak — as each lane lands)
H9  ████                                        (dedupe ROADMAP, close the ledger, READMEs)
```
`*` forms' multipart waits for H3's request-body reader (week 3).

Lane 1, H2 TLS (P0). Week 1 measures the library choice under the
package-C standard (BoringSSL, LibreSSL, mbedTLS, rustls-ffi: size,
build time, non-blocking API, licence) and lands it as `libstd-tls`.
Then `TlsConn` over `net.Conn` with the handshake parked on the poller,
certs and SNI, hostname verification on by default, ALPN and resumption,
then the `tls:` seat on the server and `https://` on the client. Closes
with its red team. About four weeks.

Lane 2, H3 streaming (P0). Response body as a producer the connection
pulls, with backpressure from a slow peer; then request bodies read
incrementally under `Limits`; then SSE; then WebSocket (RFC 6455) both
sides with Autobahn green. The design doc's attack table becomes
fixtures under `AVRA_RC_GUARD`. About four weeks.

Lane 3, H5 client (P1). `@std/url` first, shared with the router and
the app tier; DNS off the event loop with IPv4+IPv6; a pool per
(scheme, host, port); the spec's `http.get(url)?` shape with per-phase
timeouts; explicit redirect and retry policy. `https` slots in when
lane 1 lands. About four weeks.

Lane 4, H6 app tier (P1). Independent slices in any order: cookies,
static files (sendfile, ETag, Range, no path escape), content encoding
(vendored zlib/brotli), typed JSON bodies once `@std/json` takes floats
(`avra-8sb5.53`), CORS and security-header layers, OpenAPI from the
typed routes, observability hooks, rate limits. Forms' multipart joins
in week 3. Five to six weeks; this lane can be two agents.

Lane 5, H7 performance (P1). Batched writes and the public benchmark
harness first (wrk/oha, TechEmpower-style, nginx and h2o beside the C
floor), then levers by census: R11d, representation candidates,
preemption and growable stacks when their triggers fire. Continuous.

Lane 6, H4 HTTP/2 (P1), starts week 4 when ALPN and the body stream
exist. HPACK and framing in parallel, then the server over the same
router, h2spec green plus the rapid-reset/HPACK-bomb red team, then the
client over lane 3's pool. About four weeks.

Lane 7, H8 conformance, rolling from week 2: the RFC 9110/9112
checklist as fixtures, fuzzers over every framer, a 10k-connection soak
on every core with memory flat.

H1 and H9 are one agent's first week: the DoS bound in `query.av`
(`avra-8sb5.11.10`) and graceful drain are the two that matter; the
ROADMAP duplicate is a one-line delete.

Whole programme: about eight weeks with five to six agents, gated
per slice. TLS and streaming are the long poles; nothing waits on
HTTP/2 except HTTP/2's own client.

## Definition of done

- HTTPS, HTTP/1.1 and HTTP/2 served from one `server` declaration; the
  same route answers identically over each, both engines.
- Streams: a 1 GB upload and download in bounded memory; SSE and
  WebSocket with Autobahn and h2spec green.
- Client: `http.get(url)?` over a pool with typed redirect and retry
  policy, verification on by default.
- Pipelined one-core throughput within 2x of the C floor; keep-alive at
  the floor's syscall count; 4 cores scale as the kernel does.
- Every RFC MUST a fixture; framers fuzzed with a checked-in corpus; the
  soak flat.
- One doc set: this roadmap, the framing laws, the typed-routes design.

## The other HTTP documents

- `docs/2026_09_06_HTTP_FRAMING_LAWS.md` — law; stays, gains an H2 section.
- `docs/2026_09_06_STD_HTTP_TYPED_ROUTES.md` — design; stays.
- `docs/2026_09_06_STD_HTTP_DESIGN.md` — the original design; its
  "current source inspected" section is historical.
- `docs/HTTP_WORKING.md` — the campaign ledger (1932 lines), closed
  2026-09-08; history, not a plan.
- `docs/2026_09_22_FIBERS_DESIGN.md` §10–13, `docs/2026_09_23_REUSE_IN_PLACE.md`
  — the fibers and C-level campaigns as built; their leftovers are
  H7's tickets.
- `ROADMAP.md` — the HTTP campaign section, opened 2026-09-06; history.

## H7 numbers

`sh tools/bench/public.sh` produces this table; how it does, and what a
row means, is the methodology below.

### Methodology

**The command.** `make libs` first — `public.sh` builds the scenarios
server and the floor, but the package libraries are `make libs`'s on
purpose, because that target may rebuild a stale compiler and a
rebuild must not be a benchmark's side effect. Then
`sh tools/bench/public.sh`. `CORES` is how many cores the server
serves on, `CONNS` the wrk connections, `ROUNDS` and `SECS` the load,
`SERVERS` a subset (`SERVERS="avra floor"`), `PORT` when 18080 is
taken, and `KEEP=1` keeps the work directory (logs, configs) for
inspection.

**The scenarios.** `/plaintext` is one fixed body; `/json` is a small
object serialized per request in Avra — nginx answers it with a fixed
string and h2o serves a static file, so their json rows are
floor-shaped, never a like-for-like serializer comparison; `/db` is
Avra only, one random row of a 10,000-row in-memory SQLite table per
request, each core holding its own table.

**The servers.** `avra` is `tools/bench/scenarios`, the same
`served(…)` server a program writes, on `CORES` processes that share
only the listener; `floor` is `tools/bench/floor`, the kernel's floor
for this workload (epoll/kqueue, no parsing past the request
terminator, every answer the same bytes the Avra server writes) and
serves plaintext and json only; `nginx` and `h2o` run when installed,
under the generated configs, so the comparison is to the shipped
defaults of two mature servers rather than to tuned ones.

**The machine and pinning.** The header names the commit and the
machine, because neither is portable. On Linux the server is pinned to
cores `0..CORES-1` and wrk to the rest; macOS has no pinning, so the
scheduler places both and the numbers are the noisier for it.

**Rounds are interleaved.** Every server takes its turn before any
takes a second, so a load that drifts over the run hits every column
alike instead of penalizing whoever ran last; each cell lists every
round, and a second generator (oha, when installed) repeats the
unpipelined rows as an independent word on the same result.

**Read the honesty columns with the speed.** A row whose responses
were not all 2xx says so, and so do wrk's socket errors: a count of
fast refusals is not throughput. On a shared machine read the CPU per
request, not req/s — req/s moves with the load while CPU per request
moves with the code (this Mac's rounds moved 50% and 20%, at load 30
to 70). The Linux Sprite rows under "Where it stands" are the
reference; a Mac table is the same harness on a machine without
pinning.

Commit 0d3e1ad, 2026-09-30, Apple M1, 8 cores, macOS 26.6.2, load average at the end 70.42 73.60 59.59.
Server on 1 core(s), wrk -t7 -c256, 5 s x 3 interleaved rounds (each cell: every round).

| scenario | server | wrk req/s | p99 | server CPU/req | non-2xx | socket errors | oha req/s |
|---|---|---|---|---|---|---|---|
| plaintext | avra | 168464 / 121889 / 228861 | — / — / — | 2.04 µs / 1.58 µs / 2.13 µs | 0 / 0 / 0 | 0 / 0 / 0 | — / — / — |
| plaintext | floor | 433620 / 425632 / 578082 | — / — / — | 0.57 µs / 0.64 µs / 0.61 µs | 0 / 0 / 0 | 0 / 0 / 0 | — / — / — |
| plaintext | nginx | 49951 / 49659 / 67368 | — / — / — | 7.05 µs / 5.92 µs / 6.95 µs | 0 / 0 / 0 | 0 / 0 / 0 | — / — / — |
| plaintext | h2o | 65038 / 92565 / 93529 | — / — / — | 5.10 µs / 5.27 µs / 5.20 µs | 0 / 0 / 0 | 0 / 0 / 0 | — / — / — |
| json | avra | 19651 / 18944 / 28386 | 175.54ms / 154.39ms / 103.98ms | 13.33 µs / 10.56 µs / 13.46 µs | 0 / 0 / 0 | 0 / 0 / 0 | 21378 / 19437 / 27568 |
| json | floor | 35303 / 30131 / 54386 | 107.67ms / 232.89ms / 90.21ms | 6.74 µs / 8.30 µs / 7.13 µs | 0 / 0 / 0 | 0 / 0 / 0 | 37987 / 36080 / 63763 |
| json | nginx | 25989 / 28423 / 39677 | 162.57ms / 95.32ms / 104.99ms | 12.47 µs / 9.57 µs / 11.04 µs | 0 / 0 / 0 | 0 / 0 / 0 | 24829 / 22542 / 32979 |
| json | h2o | 26505 / 38523 / 29937 | 211.71ms / 153.70ms / 146.78ms | 9.21 µs / 8.88 µs / 8.89 µs | 0 / 0 / 0 | 0 / 0 / 0 | 26577 / 43652 / 31361 |
| db | avra | 19762 / 20672 / 22777 | 137.25ms / 139.32ms / 181.51ms | 17.61 µs / 13.45 µs / 15.28 µs | 0 / 0 / 0 | 0 / 0 / 0 | 16964 / 16030 / 18043 |

Read the CPU column, not req/s: this Mac was shared with other lanes'
compilers (load 30 to 70) and req/s moved 50% between rounds while CPU
per request moved 20%. Pipelined, Avra spends 1.6 to 2.1 µs a request
against the floor's 0.6 µs, about 3.2x; the definition of done asks
for 2x. Keep-alive json costs 10.6 to 13.5 µs against 6.7 to 8.3 µs.
The Linux Sprite rows above (`## Where it stands`) remain the
reference; this table is the Mac's, same harness.

## H2 decision: TLS library

**mbedTLS 4.1 LTS** (4.1.1, supported to March 2029), vendored in
`packages/std-tls/vendor/` by `vendor/import.sh` from the release tarball
(sha256 checked against the upstream release notes). Measured on macOS
arm64, 2026-09-29, on a shared machine at load average 40 to 70, so the
speed rows are best-of-three and read as ratios, not absolutes. Linux was
not measured here.

Every candidate completed a verified TLS 1.3 handshake between a client
and a server over two memory buffers, then one record each way. So the
non-blocking question is settled for all four. What separates them is the
toolchain and the size.

| | mbedTLS 4.1/4.2 | LibreSSL 4.3.2 | BoringSSL 0.20260929 | rustls-ffi 0.15.4 |
|---|---|---|---|---|
| toolchain | C99, no dependency | C plus a portability layer and a generated config | C++17; every program links libc++ | cargo, plus aws-lc's C and CMake |
| fits `build/%.o: %.c` | yes, 66 units | no | no | no |
| memory API | `mbedtls_ssl_set_bio` callbacks, WANT_READ | memory BIOs | memory BIOs | `read_tls`/`write_tls` callbacks |
| stripped probe, both sides | 464 KB default config; 261 KB ours | 1.04 MB | 1.10 MB plus libc++ | 3.15 MB |
| build | 29 s at -j4; ours 24 s serial | 45 s at -j4 | 150 s at -j4 | 81 s plus the crate fetch |
| handshake, both sides | 4.0 ms | 1.8 ms | 0.5 ms | not measured |
| AES-128-GCM bulk | 476 MB/s | 132 MB/s (it chose ChaCha20) | 2382 MB/s | not measured |
| licence | Apache-2.0 or GPL-2.0+ | ISC and OpenSSL | Apache-2.0 and OpenSSL/ISC | Apache/MIT/ISC; aws-lc Apache/ISC |
| support | LTS to March 2029 | OpenBSD's cadence | no API promise | 0.x |

**Why mbedTLS.** It is the only candidate the package-C standard can
build as it stands. Each upstream unit compiles through the one generic
rule via a one-line wrapper, and the units are archived so a program
carries only what its handshake reaches. The other three each bring a
second toolchain into every program: C++ and libc++, or cargo. P14 says
no runtime, and libc++ is one.

**What it costs.** Speed. BoringSSL's hand-written assembly makes its
handshake about 8x cheaper and its AES-GCM about 5x faster. With
resumption tickets (ticket .4), a returning client skips the signature,
which is most of the handshake. The rest is an H7 lever: mbedTLS takes
accelerated crypto through its PSA driver interface, so faster
primitives can land without changing the engine.

**Why 4.1 and not 3.6 or 4.2.** 3.6 LTS ends in March 2027. 4.2 is a
feature release. 4.1 is the LTS through March 2029.

**The config is the mechanism list.** `src/c/std_tls_ssl_config.h` and
`std_tls_crypto_config.h` name every protocol and primitive compiled in:
TLS 1.2 and 1.3, ECDHE only, ECDSA and RSA certificates, AES-GCM and
ChaCha20-Poly1305, SNI, ALPN and tickets. Renegotiation, DTLS, static
RSA, PSK-only, CBC, SHA-1 and mbedTLS's own sockets are left out. Fork
safety comes from mbedTLS's RNG, which reseeds when the pid changes, so
one process per core is safe.