# HTTP/1.1 framing laws — what the parser must refuse, and what the fast ones do

Status: research, 2026-09-06, for `lane/http`. Nothing here was compiled or run. Every
claim cites a spec section or a source file read today (raw GitHub `master` of
picohttpparser, h2o, nginx, httparse, hyper; line numbers are today's). Two receipts
could not be fetched: Kazuho's SSE post refused connections twice (its 68–90% SSE gain
is second-hand, from a search summary) and the Hacker News thread returned 429. No
published ns/request exists for httparse or nginx's parser alone. Companion to
`2026_09_06_STD_HTTP_DESIGN.md` (law 8: bounds are named and adjustable) and
`2026_09_06_STD_HTTP_TYPED_ROUTES.md` (its percent-encoding and "every split point"
rows are honoured below).

Recommendation in one line: **strict CRLF, single SP, no obs-fold, no bare LF/CR, and
every `MAY` in RFC 9112 that widens the grammar is taken as "refuse"** — the spec says
lenient parsing "can result in request smuggling security vulnerabilities if there are
multiple recipients" ([9112 §3](https://www.rfc-editor.org/rfc/rfc9112.html#section-3)).
A server with no legacy clients pays nothing for strictness and the scan gets simpler.

## 1. The framing laws

Sources: [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html) (HTTP/1.1, cited bare),
[RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html) (semantics),
[RFC 3986](https://www.rfc-editor.org/rfc/rfc3986.html) (URI).

### 1.1 Lines and bytes (§2.2, §2.3, §3)

- `request-line = method SP request-target SP HTTP-version` CRLF (§3). Method is a
  `token`, case-sensitive (§3.1). `HTTP-name = %s"HTTP"` (case-sensitive) and
  `HTTP-version = HTTP-name "/" DIGIT "." DIGIT` (§2.3): one digit each side.
- Recipients "MAY recognize a single LF as a line terminator and ignore any preceding
  CR"; a bare CR: "MUST consider that element to be invalid or replace each bare CR with
  SP" (§2.2). **Choose CRLF only: 400 on bare LF and bare CR.** A scan that stops at the
  first byte `< 0x20` or `== 0x7F` and then demands `CR LF` gets this for free.
- "SHOULD ignore at least one empty line (CRLF) received prior to the request-line"
  (§2.2); picohttpparser skips exactly one (`parse_request`, "skip first empty line").
- Whitespace before the first header line: "MUST either reject the message as invalid
  or consume each whitespace-preceded line" (§2.2). **Reject.**
- §3 permits parsing "on whitespace-delimited word boundaries" and warns in the same
  paragraph that this enables smuggling. **Single SP only; 400 on `SP SP`, HTAB, VT, FF.**
- Invalid request-line: "SHOULD respond with either a 400 (Bad Request) error or a 301"
  (§3). Method longer than any implemented: 501 SHOULD. Target longer than the server
  will parse: "MUST respond with a 414" (§3). Support at least 8000-octet lines (§3).
- Unsupported major version: 505 "does not support, or refuses to support, the major
  version" (9110 §15.6.6). A higher minor version of the same major: "SHOULD process the
  message as if it were in the highest minor version … to which the recipient is
  conformant" (9110 §6.2).

### 1.2 Request target (§3.2, §3.3; 9110 §7.2; RFC 3986)

- `request-target = origin-form / absolute-form / authority-form / asterisk-form`; "No
  whitespace is allowed in the request-target" (§3.2). `origin-form = absolute-path
  [ "?" query ]` (§3.2.1), so a target starts with `/`, or is `*` (OPTIONS only, §3.2.4),
  a scheme (absolute-form), or `host:port` (CONNECT only, §3.2.3).
- "A server MUST accept the absolute-form in requests" (§3.2.2); "The target URI is the
  request-target when the request-target is in absolute-form" (§3.3): its authority wins
  over `Host`, and a proxy MUST replace `Host` from it (§3.2.2).
- **AND ACCEPTING IT IS HALF THE MUST.** An ORIGIN server routes on the target's PATH, so
  `/p` and `http://h/p` name ONE resource; a reader that answered the whole URI made them
  two, and a front end that normalises one form into the other then disagrees with the
  origin behind it about which route answers. `Request.path()` answers the PATH COMPONENT
  of every form — origin-form as sent, absolute-form with scheme and authority stripped
  (an empty path is `/`, 9110 §4.2.3), and ABSENT for `*` and CONNECT's authority, which
  name no resource. `Request.authority()` hands back what it stripped, which is what §3.3's
  "its authority wins over `Host`" needs in order to be obeyable at all.
- `Host = uri-host [ ":" port ]` (9110 §7.2). "A server MUST respond with a 400 (Bad
  Request) status code to any HTTP/1.1 request message that lacks a Host header field
  and to any request message that contains more than one Host header field line or a
  Host header field with an invalid field value" (§3.2). HTTP/1.0 may omit it.
- The `http` URI carries no fragment on the wire (9110 §4.2.1 ABNF); `#` in a target is
  a client bug. **400** (nginx silently truncates at `#`; refusing is smaller).
- Percent-encoding the router honours (3986): `pct-encoded = "%" HEXDIG HEXDIG`, hex
  case-insensitive (§2.1); "URIs that differ in the replacement of a reserved character
  with its corresponding percent-encoded octet are not equivalent" (§2.2) — `%2F` is not
  `/`; encoded unreserved chars (`ALPHA DIGIT - . _ ~`) are equivalent and should decode
  (§2.3, §6.2.2.2); "must not percent-encode or decode the same string more than once"
  (§2.4). Split on `/` and `?` FIRST, decode each piece ONCE, then apply the typed-routes
  segment domain (no `/`, `\`, CTL, no `.`/`..` after decoding). `%`, `%2`, `%GG`: 400.

### 1.3 Field lines (§5; 9110 §5)

- `field-line = field-name ":" OWS field-value OWS`; `field-name = token`; `tchar = "!" /
  "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~" /
  DIGIT / ALPHA` (9110 §5.6.2); `OWS = *( SP / HTAB )` (9110 §5.6.3).
- "A server MUST reject, with a response status code of 400 (Bad Request), any received
  request message that contains whitespace between a header field name and colon"
  (§5.1). An empty name (`: v`) is not a token: 400.
- Values: `field-vchar = VCHAR / obs-text`, `obs-text = %x80-FF`, inner `SP / HTAB`;
  "A field value does not include leading or trailing whitespace"; CR, LF, NUL: "MUST
  either reject the message or replace each of those characters with SP"; other CTLs
  "also invalid" (9110 §5.5). **Reject every byte `< 0x20` except HTAB, and `0x7F`; keep
  `>= 0x80` as opaque bytes.**
- `obs-fold = OWS CRLF RWS`: "MUST either reject the message by sending a 400 … or
  replace each received obs-fold with one or more SP" (§5.2). **Reject.**
- Oversize: "larger than it wishes to process MUST respond with an appropriate 4xx"
  (9110 §5.4); 431 ([RFC 6585 §5](https://www.rfc-editor.org/rfc/rfc6585.html#section-5)).
- End of head: the first empty line, `CRLF CRLF` under strict CRLF. With
  `index_of("\r\n\r\n", from)` the check costs one scan of the NEW bytes: start at
  `max(0, previous_length - 3)` (picohttpparser's `is_complete`, "a fast countermeasure
  against slowloris", `pico.c:197-222, 415-419`).

### 1.4 Body length: the rules of §6.3 and the MUST-400-and-close list (§6)

1. HEAD responses and 1xx/204/304 responses "cannot contain a message body or trailer
   section" regardless of headers.
2. A 2xx to CONNECT: the connection "will become a tunnel immediately after the empty
   line"; "A client MUST ignore any Content-Length or Transfer-Encoding header fields".
3. TE and CL both present: "the Transfer-Encoding overrides the Content-Length. Such a
   message might indicate an attempt to perform request smuggling … and ought to be
   handled as an error." §6.1: a server "MAY reject a request that contains both … or
   process such a request in accordance with the Transfer-Encoding alone. Regardless,
   the server MUST close the connection after responding to such a request".
4. TE with chunked final: chunked framing. In a REQUEST with chunked not final: "the
   server MUST respond with the 400 (Bad Request) status code and then close the
   connection". In a RESPONSE with chunked not final: read to close.
5. No TE and an invalid CL: "unrecoverable error", unless it is a comma list whose values
   are all valid and equal; in a request "the server MUST respond with a 400 (Bad
   Request) status code and then close the connection"; a user agent "MUST close the
   connection to the server and discard the received response".
6. Valid CL, no TE: that many octets; early close or timeout: "MUST consider the message
   to be incomplete and close the connection".
7. A request with none of the above: zero-length body. 8. A response: read to close.

Also: `Content-Length = 1*DIGIT`; "MUST anticipate potentially large decimal numerals
and prevent parsing errors due to integer conversion overflows"; `42, 42` MAY be taken
as 42 or rejected (9110 §8.6). HTTP/1.0 with Transfer-Encoding: "MUST treat the message
as if the framing is faulty, even if a Content-Length is present, and close the
connection" (§6.1). Unknown coding: "SHOULD respond with 501" (§6.1). Body without CL:
MAY 411 (§6.1). A server "MUST NOT send a Transfer-Encoding header field" in 1xx, 204 or
a 2xx to CONNECT, and never CL together with TE (§6.1, §6.2).

What the fast servers do with TE + CL (read today):
- nginx: 400 `"Content-Length" and "Transfer-Encoding" headers at the same time`; TE on
  HTTP/1.0: 400; TE other than exactly `chunked` (case-insensitive): 501; duplicate
  CL/TE/Host lines: 400 (`ngx_http_process_unique_header_line`)
  (`src/http/ngx_http_request.c:2035-2085`).
- hyper: TE wins, CL removed, `keep_alive = false`; TE without final chunked:
  `transfer_encoding_invalid`; TE on HTTP/1.0: `transfer_encoding_unexpected`; differing
  CLs: `content_length_invalid`; equal duplicates accepted (`src/proto/h1/role.rs:228-352`).
- h2o: TE not `chunked`: 400 "unknown transfer-encoding"; CL `h2o_strtosize` refuses: 400;
  CL over `max_request_entity_size` (1 GiB default): 413 (`lib/http1.c:339-359`).
- llhttp: errors by default on TE+CL, a coding after `chunked`, bare LF, CR without LF, a
  missing CRLF after chunk data, spaces after a chunk size; every `llhttp_set_lenient_*`
  switch is documented as exposing "request smuggling"
  ([README](https://github.com/nodejs/llhttp/blob/main/README.md);
  [node `--insecure-http-parser`](https://nodejs.org/api/cli.html#--insecure-http-parser)).

### 1.5 Chunked (§7.1)

```
chunked-body    = *chunk last-chunk trailer-section CRLF
chunk           = chunk-size [ chunk-ext ] CRLF chunk-data CRLF
chunk-size      = 1*HEXDIG            last-chunk = 1*("0") [ chunk-ext ] CRLF
chunk-ext       = *( BWS ";" BWS chunk-ext-name [ BWS "=" BWS chunk-ext-val ] )
trailer-section = *( field-line CRLF )
```

- "A recipient MUST be able to parse and decode the chunked transfer coding" (§7.1).
  "All transfer-coding names are case-insensitive" (§7).
- "A recipient MUST ignore unrecognized chunk extensions. A server ought to limit the
  total length of chunk extensions … and generate an appropriate 4xx" (§7.1.1).
- Trailers: a sender "MUST NOT generate a trailer field unless … the field to be sent in
  trailers"; a recipient "MUST NOT merge a trailer field into a header section unless"
  its definition permits (9110 §6.5.1). **Parse trailers with the field-line parser, then
  drop everything not on an allowlist; a trailer can never re-frame, route or authenticate.**
- Decoding (§7.1.3): read size (+ext) CRLF; while size > 0: read data CRLF, append, read
  next size; read trailers; `Content-Length := length`.
- In practice: both hex cases; leading zeros are legal. picohttpparser caps at 16 hex
  digits and allows only `SP HTAB ; CR LF` after them (`pico.c:560-583`); nginx checks
  `size > NGX_MAX_OFF_T_VALUE / 16` before each digit (`ngx_http_parse.c`, `sw_chunk_size`);
  hyper uses `checked_mul(16)` (`src/proto/h1/decode.rs`). All three skip the extension
  to CR and refuse a bare LF inside it. After chunk data exactly `CR LF`. picohttpparser
  aborts a stream whose chunked overhead reaches 100 KiB while data is under 25%
  (`pico.c:693-695`).

### 1.6 Responses: no-body cases, 1xx, CONNECT, HEAD (9110)

- "A 1xx response is terminated by the end of the header section; it cannot contain
  content or trailers"; "A client MUST be able to parse one or more 1xx responses
  received prior to a final response, even if the client does not expect one" (§15.2);
  the same terminator sentence for 204 (§15.3.5) and 304 (§15.4.5).
- HEAD: "the server MUST NOT send content in the response" (§9.3.2) — the response
  parser needs the request METHOD as an input to frame the answer.
- CONNECT: "Any 2xx (Successful) response indicates that the sender … will switch to
  tunnel mode immediately after the response header section" (§9.3.6).
- hyper's client decoder is the reference order: 204/304 → zero; HEAD → zero; CONNECT +
  2xx → zero + upgrade; 1xx → skipped; then TE (chunked, else close-delimited), then CL
  (invalid → error), else close-delimited (`role.rs:1266-1322`).
- "A client that receives an incomplete response message … MUST record the message as
  incomplete" (§8) — never hand a short body to the caller as complete.

### 1.7 Persistence, pipelining, close, Expect (§9.3, §9.6; 9110 §10.1.1)

- In order: `close` present → not persistent; HTTP/1.1 → persistent; HTTP/1.0 with
  `keep-alive`, "either the recipient is not a proxy or the message is a response, and
  the recipient wishes to honor" it → persistent; else close (§9.3). "all messages on a
  connection need to have a self-defined message length" — an HTTP/1.0 keep-alive
  response must carry Content-Length.
- Pipelining: "MUST send the corresponding responses in the same order that the requests
  were received" (§9.3.2). A server that receives or sends `close` "MUST NOT process any
  further requests received on that connection"; a client receiving it "MUST cease
  sending requests" (§9.6).
- Staged close: "the server performs a half-close by closing only the write side … then
  continues to read from the connection until it receives a corresponding close by the
  client, or until … reasonably certain" the response was acknowledged (§9.6). "a TCP
  connection that is half-closed by the client does not delimit a request message, nor
  does it imply that the client is no longer interested in a response" (§9.6).
- Expect: value case-insensitive; in HTTP/1.0 "MUST ignore that expectation"; "MAY omit
  sending a 100 (Continue) response if it has already received some or all of the
  content"; unknown expectation MAY 417; a client "MAY proceed to send the content even
  if it has not yet received a response" (9110 §10.1.1) — body bytes may already sit
  behind the head. h2o writes the literal `HTTP/1.1 100 Continue\r\n\r\n`, and 417 +
  close for any other value (`lib/http1.c:713-731`).

### 1.8 Limits servers actually enforce

| Server | request line | one field line | whole head | fields | body | source |
|---|---|---|---|---|---|---|
| nginx | 8k (one large buffer, else 414) | 8k (else 400/494) | 1k + 4×8k | — | 1m (413) | [core](https://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers) |
| h2o | — | — | `8192 + 4096*100` = 417,792 (400) | 100 | 1 GiB (413) | `include/h2o/header.h:37,45`; `lib/http1.c:628-649` |
| hyper | — | — | `8192 + 4096*100` = 417,792 (`TooLarge`) | 100 | app | `src/proto/h1/io.rs`; `role.rs:31` |
| Apache | 8190 | 8190 | — | 100 | unlimited | [core](https://httpd.apache.org/docs/2.4/mod/core.html#limitrequestline) |
| Node | — | — | 16 KB | — | app | [cli](https://nodejs.org/api/cli.html#--max-http-header-sizesize) |
| Go | — | — | 1 MB | — | app | [net/http](https://pkg.go.dev/net/http#DefaultMaxHeaderBytes) |

Timeouts: nginx `client_header_timeout 60s`, `client_body_timeout 60s` (per read),
`keepalive_timeout 75s`, `keepalive_requests 1000`, `send_timeout 60s`, `lingering_close
on` ([core](https://nginx.org/en/docs/http/ngx_http_core_module.html)); h2o
`http1-request-timeout 10` s, `http1-request-io-timeout 5` s
([h2o](https://h2o.examp1e.net/configure/http1_directives.html)).

Proposed `@std.http` defaults (named and adjustable, design law 8): request line 8 KiB
(414), field line 8 KiB (431), head 64 KiB (431 + close), 100 fields (431), body 1 MiB
(413), chunk-ext total 4 KiB (400), trailers 16 fields / 4 KiB, head timeout 10 s, body
idle 60 s, keep-alive idle 75 s, 1000 requests per connection.

## 2. What makes the fast parsers fast

### 2.1 picohttpparser (h2o's HTTP/1 parser)

- **Direct scan, no state, no allocation**: outputs are pointers into the caller's buffer.
- Partial input returns `-2`; the caller reads more and **calls again over the whole
  buffer** with the previous length as `last_len`; `is_complete` scans from `last_len - 3`
  for two consecutive line ends and returns `-2` without re-parsing when the head is not
  there (`pico.c:197-222, 415-419`; README's loop passes `prevbuflen`). Re-parsing is fine
  because a head is parsed to completion once; the incomplete case costs only the scan.
- A 256-entry `token_char_map` indexed by the byte (`pico.c:96`).
- End-of-line is the hottest loop: 8× unrolled `IS_PRINTABLE_ASCII(c) = ((unsigned
  char)(c)-040u < 0137u)` — one unsigned compare classifies `0x20..0x7E` — branching out
  for the rest, where HTAB and `>= 0x80` are accepted and `< 0x20` / `0x7F` end the token
  (`pico.c:53, 148-179`). SSE4.2 `_mm_cmpestri` replaces it when available (`findchar_fast`).
- Line ends `CR LF` or bare `LF`; CR without LF is an error (`pico.c:180-190`). Request
  line: `parse_token` to SP, then `do { ++buf } while (*buf == ' ')` (multiple spaces
  skipped), path is any byte `>= 0x20` except `0x7F`, version is seven `EXPECT_CHAR`s of
  `HTTP/1.` plus a digit (`pico.c:357-398, 287-293`). A header line starting with SP/HTAB
  is an obs-fold continuation with `name = NULL` (`pico.c:299-350`).
- `phr_decode_chunked`: a small resumable state machine decoding IN PLACE.
- Measured: 100,000 parses of a 9-header 430-byte GET on a 3 GHz i7 (2014): pico
  0.036571 s (≈366 ns/req), http-parser 0.289766 s (≈2.9 µs/req)
  ([fast-http README at the commit pico's README cites](https://github.com/fukamachi/fast-http/tree/6b9110347c7a3407310c08979aefd65078518478)).
  SSE4.2: 68–90% faster, second-hand ([blog](http://blog.kazuhooku.com/2014/12/improving-parser-performance-using-sse.html)).

### 2.2 llhttp (Node)

- **Generated byte-at-a-time state machine** (TypeScript DSL → llparse → C), resumable
  at any byte, spans delivered by callbacks, no allocation; "All optimizations and
  multi-character matching in llhttp are generated automatically"
  ([README](https://github.com/nodejs/llhttp/blob/main/README.md)).
- Its table: 8192 MB input, llhttp 1777.24 MB/s, 3,583,799 req/s (≈279 ns/req at ≈520
  B/req); http_parser 694.66 MB/s, 1,406,180 req/s (≈711 ns/req). Strict by default (§1.4).

### 2.3 nginx `ngx_http_parse_request_line` / `ngx_http_parse_header_line`

- **Hand-written switch state machine, one byte per iteration, resumable**: on exhaustion
  `b->pos = p; r->state = state; return NGX_AGAIN`.
- Method by length then `ngx_str3_cmp`/`ngx_str4cmp` — a 4-byte integer compare with
  unaligned little-endian loads (`ngx_http_parse.c:42-80, 172-209`).
- Header names through a 256-byte `lowcase[]` table (`A-Z` → `a-z`, digits and `-` to
  themselves, else 0); the lowercased name and an incremental `ngx_hash` are built while
  scanning (`ngx_http_parse.c:889, 926-970`). A name byte `<= 0x20`, `0x7F` or a leading
  `:` → `INVALID_HEADER` (400); other bytes mark the line invalid and
  `ignore_invalid_headers on` drops it (`ngx_http_request.c:1490-1498`). NUL in a value:
  invalid; bare LF accepted; multiple spaces before the URI skipped
  (`sw_spaces_before_uri`); a line with no `HTTP/` is HTTP/0.9 (`sw_http_09`).
- Buffers: `client_header_buffer_size` 1k first; when full,
  `ngx_http_alloc_large_header_buffer` takes one of `large_client_header_buffers` (4×8k),
  **copies the partial line and fixes every saved pointer**; a line that will not fit one
  large buffer is 414 (request line) or 494→400 (header)
  (`ngx_http_request.c:1268, 1447-1468, 1685-1705`).

### 2.4 httparse / hyper

- **Direct scan like pico**, no allocation, borrows the input; `Status::Partial` means
  "call again with a longer buffer" and restarts at byte 0 (README). Three 256-entry
  `bool` tables: `URI_MAP` (`!`..`~`, `0x80..=0xFF`), `TOKEN_MAP` (tchar),
  `HEADER_VALUE_MAP` (HTAB, SP..`~`, `0x80..=0xFF`) (`src/lib.rs:69-97`). Version by one
  8-byte integer compare against `HTTP/1.0`/`HTTP/1.1`; `GET `/`POST` by 4-byte compare
  (`lib.rs:764-818`). Bare LF accepted; CR needs LF (`Error::NewLine`). Obs-fold and
  multi-space request lines refused unless a `ParserConfig` flag is set; the obs-fold flag
  exists for RESPONSES only (`lib.rs:212-310`). `TooManyHeaders` when the slice fills.
- hyper: `INIT_BUFFER_SIZE 8192`, adaptive doubling to `8192 + 4096 * 100`, `TooLarge`
  when the head is incomplete at the cap (`src/proto/h1/io.rs`). Chunked states `Start
  Size SizeLws Extension SizeLf Body BodyCr BodyLf Trailer TrailerLf EndCr EndLf End`;
  extensions capped at 16 KiB per body; trailers by `h1_max_headers` and a 16 KiB
  `TRAILER_LIMIT` (`decode.rs`).

### 2.5 What a scalar parser over `Bytes` (`at`, `length`, `slice`, `index_of`) borrows

1. **One pass, no parser state.** Parse the head from offset 0 every call. First
   `index_of("\r\n\r\n", max(0, prev_len - 3))`: absent → `Incomplete`, no further work.
   Refuse before scanning once `length` passes the head cap: a slowloris costs one
   bounded scan per read.
2. **One 256-entry class table** with bit flags `TCHAR`, `VALUE` (HTAB, `0x20..0x7E`,
   `0x80..0xFF`), `TARGET` (`0x21..0x7E`, `0x80..0xFF`), `DIGIT`, plus a hex-value table.
   Every scan is `while table[at(i)] & CLASS { i += 1 }` — pico's `token_char_map`,
   nginx's `lowcase[]` and httparse's three maps in one.
3. **Scan for the first byte outside the class, then look at it** — never a per-byte
   `match`. pico's `(b - 0x20) < 0x5F` is one compare; a table load is one load. Unroll
   by 8 only if a probe shows the bounds-checked `at(i)` loop is the cost.
4. **Names and values are (lo, hi) offsets**, never a `slice` until the application asks
   (`slice` copies). Known-header dispatch: compare length, then bytes against a
   pre-lowercased constant via `lower(at(i))` — lowercase the wire byte in the compare,
   never build a lowered copy (nginx lowers as it scans).
5. **Method by length then bytes** (`3: GET PUT`, `4: HEAD POST`, `7: OPTIONS CONNECT`);
   version by seven fixed bytes and one digit. **Content-Length by digits only** with an
   overflow guard before each `*10 + d`; chunk size the same in base 16, 16-digit cap.
6. **Pipelining is an offset**: the unconsumed tail stays in the buffer and the next parse
   starts there; compact only when the buffer must grow — at most one copy per request.
7. **Return a reason, not −1.** pico and httparse answer only "error"; hyper maps each to a
   400 with words. A `Refusal` enum naming the law is what the attack table asserts against.

## 3. The event loop (kqueue on macOS, epoll on Linux)

Man pages, Linux from man7.org: [epoll(7)](https://man7.org/linux/man-pages/man7/epoll.7.html), [accept(2)](https://man7.org/linux/man-pages/man2/accept.2.html), [listen(2)](https://man7.org/linux/man-pages/man2/listen.2.html), [send(2)](https://man7.org/linux/man-pages/man2/send.2.html), [socket(7)](https://man7.org/linux/man-pages/man7/socket.7.html), [tcp(7)](https://man7.org/linux/man-pages/man7/tcp.7.html), [signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html), [writev(2)](https://man7.org/linux/man-pages/man2/writev.2.html);
BSD/macOS: [kqueue(2)](https://man.freebsd.org/cgi/man.cgi?query=kqueue&sektion=2), [setsockopt(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/setsockopt.2.html), [listen(2)](https://www.unix.com/man_page/osx/2/listen/).
Code: nginx `src/event/{ngx_event.h,ngx_event.c,ngx_event_accept.c,modules/ngx_epoll_module.c,modules/ngx_kqueue_module.c}`;
h2o `lib/common/socket/evloop.c.h`, `evloop/{epoll,kqueue}.c.h`.

### 3.1 Level or edge

- epoll(7): `EPOLLET` delivers an event only on a state change; the documented failure is
  2 kB arriving, 1 kB read, and the next `epoll_wait` blocking forever. "The suggested
  way to use epoll as an edge-triggered (EPOLLET) interface": nonblocking fds and waiting
  "only after read(2) or write(2) return EAGAIN"; for stream sockets a short read also
  proves the buffer drained (Q9).
- kqueue(2): `EV_CLEAR` "Reset the state of the event after it is retrieved by the user"
  is kqueue's edge mode; without it the filter is level. `EVFILT_READ` on a socket returns
  in `data` "the number of bytes of protocol data available to read", sets `EV_EOF` when
  the read side has shut down with the socket error in `fflags`; `EVFILT_WRITE` returns
  the send-buffer space left and `EV_EOF` when the reader disconnects.
- **h2o is level-triggered on both**: epoll events are only `EPOLLIN`/`EPOLLOUT`
  (`epoll.c.h`, `update_status`); kevents carry `EV_ADD` and never `EV_CLEAR`
  (`kqueue.c.h`); interest is toggled with `EPOLL_CTL_MOD` / `EV_ADD`+`EV_DELETE` as a
  socket starts or stops reading/writing. **nginx is edge-triggered for connections**:
  `NGX_CLEAR_EVENT` is `EPOLLET` (`ngx_event.h:353`) or `EV_CLEAR` (`ngx_event.h:331`),
  used by `ngx_handle_read_event` (`ngx_event.c:287`); **listeners are added with flags 0**,
  i.e. level (`ngx_event.c:887, 908`). nginx reads `kevent.data` into `ev->available` and
  stops reading when it is spent, and `EV_EOF` into `pending_eof` (`ngx_kqueue_module.c`).
- **Pick level-triggered on both platforms.** One `read` per wake-up is correct (the
  kernel re-reports), a handler that did not drain cannot stall, and the write path is
  "write now; if short, add OUT interest; on OUT, drain; when empty, remove OUT". Edge
  saves `epoll_ctl` calls under load and is a later optimisation that touches no framing.

### 3.2 The loop, verb by verb

- Listener: `socket` → `SO_REUSEADDR` ("allow reuse of local addresses", socket(7)) →
  `bind` → `listen(backlog)` → nonblocking → register READ. Backlog: Linux caps at
  `/proc/sys/net/core/somaxconn`, 4096 since 5.4 (128 before), and it "specifies the
  queue length for completely established sockets" (listen(2)); macOS: "The backlog is
  currently limited (silently) to 128" (listen(2) osx). nginx passes 511 on Linux and −1
  on macOS/FreeBSD ([listen](https://nginx.org/en/docs/http/ngx_http_core_module.html#listen));
  h2o passes 65535 "and let the kernel clip it" (`include/h2o.h:66-68`).
- `SO_REUSEPORT`: Linux ≥3.9 distributes `accept` across listeners of one effective UID
  (socket(7)); on macOS it "allows completely duplicate bindings" for multicast/broadcast
  and balances nothing (macOS setsockopt(2)); nginx enables it only on Linux 3.9+,
  DragonFly, FreeBSD 12+. One listener, one thread: skip it.
- Accept: on READ, loop `accept4(fd, …, SOCK_NONBLOCK | SOCK_CLOEXEC)` until `EAGAIN`
  (accept(2); nginx `do { … } while (ev->available)`). macOS has no `accept4`: `accept`,
  then `fcntl(F_SETFL, O_NONBLOCK)` and `FD_CLOEXEC` (h2o's `#if H2O_USE_ACCEPT4` fallback,
  `evloop.c.h`); "On Linux, the new socket returned by accept() does not inherit file
  status flags such as O_NONBLOCK". `EAGAIN` → done; `EINTR` → retry; `ECONNABORTED` →
  continue; `EMFILE`/`ENFILE` → stop accepting until a socket closes (nginx
  `ngx_accept_disabled`); Linux "passes already-pending network errors on the new socket
  as an error code from accept()": `ENETDOWN EPROTO ENOPROTOOPT EHOSTDOWN ENONET
  EHOSTUNREACH EOPNOTSUPP ENETUNREACH` are treated "like EAGAIN by retrying" (accept(2)).
  A readiness event does not guarantee a pending connection.
- Per socket: `TCP_NODELAY` = 1 ("segments are always sent as soon as possible", tcp(7));
  h2o sets it in the accept path (`set_nodelay_if_likely_tcp`), nginx on the keep-alive
  transition (`ngx_http_set_keepalive`). A response written as ONE `writev` (head, body)
  is one segment when small, and NODELAY keeps a larger one's tail from waiting on a
  delayed ACK. `TCP_CORK`/`TCP_NOPUSH` pay only with `sendfile` (nginx `tcp_nopush off`).
- Read: into the connection buffer at its fill offset. `0` → peer FIN: not a request
  delimiter, not disinterest (§9.6) — finish any in-flight response, then close.
  `EAGAIN` → wait; `EINTR` → retry; `ECONNRESET` and the rest → drop. h2o reserves 4096
  bytes per read and loops until `EAGAIN` or its cap (`evloop.c.h`); nginx reads exactly
  the space left in the current header buffer.
- Write: `writev` with `{head, body}`: "data is written in the order specified"; up to
  `IOV_MAX` = 1024 entries; a short count is not an error (writev(2)) — advance the iovec,
  register OUT. h2o uses `sendmsg` with up to `IOV_MAX` iovecs (`evloop.c.h`).
- SIGPIPE: writing to a peer-closed socket returns `EPIPE` AND raises `SIGPIPE`, default
  action Term (signal(7), send(2)). Fixes: process-wide `signal(SIGPIPE, SIG_IGN)`
  (portable, simplest); Linux `MSG_NOSIGNAL` per `send` ("The EPIPE error is still
  returned"); macOS `SO_NOSIGPIPE` per socket ("returns with the error EPIPE"), which
  covers `send` but not `write`. **Ignore it process-wide; EPIPE/ECONNRESET mean drop.**
- EINTR: `epoll_wait`, `epoll_pwait`, `poll`, `select` are "never restarted after being
  interrupted by a signal handler, regardless of the use of SA_RESTART" (signal(7));
  `kevent` fails with `EINTR` likewise (kqueue(2)). Loop on `EINTR` around every wait and
  `epoll_ctl`/`kevent` change, as h2o does (`while (… == -1 && errno == EINTR)`).
- Peer-close signals: epoll `EPOLLRDHUP` (nginx registers `EPOLLIN|EPOLLRDHUP`, sets
  `pending_eof`); on `EPOLLERR|EPOLLHUP` nginx ORs in `EPOLLIN|EPOLLOUT` so "at least one
  active handler" runs; kqueue `EV_EOF` with errno in `fflags`. `EPOLLEXCLUSIVE` is for a
  thundering herd across processes: irrelevant single-threaded.
- Staged close after an error response (§9.6): `shutdown(SHUT_WR)`, read and discard until
  EOF or a timeout, then `close`. nginx's `ngx_http_set_lingering_close` does this with a
  4 KiB scratch buffer, `lingering_timeout` per read and `lingering_time` overall, and
  marks `r->lingering_close = 1` on header-too-large (`ngx_http_request.c:1447, 3728-3851`).
  `reset_timedout_connection` (SO_LINGER 0 → RST) is for timed-out sockets only.
- Per-connection state (nginx, h2o): fd; one read buffer with `fill`/`consumed` offsets
  (nginx 1k then up to 4×8k by copy-and-relocate; h2o one growable buffer capped at
  `H2O_MAX_REQLEN`; hyper 8 KiB doubling to 417,792); the previous length for the
  `is_complete` scan (h2o `_prevreqlen`, `lib/http1.c:70,643`); pending output iovecs and
  a written offset; the head's offsets; body decoder state; keep-alive flag; request
  count; two timers (head/body idle, keep-alive idle). Nothing else is needed.

## 4. Deterministic attack table

Each row is a fixture: bytes in, required verdict, law. "400+close" = respond 400 with
`Connection: close`, then staged close. "Incomplete" = keep reading. Rows 1–5 are the
split and pipelining family; the parser must give the SAME verdict for every split of
every other row (rows 2–3 are the harness that proves it).

| # | Input (`\r\n` shown as `␍␊`) | Required outcome | Law |
|---|---|---|---|
| 1 | `GET / HTTP/1.1␍␊Host: a␍␊␍␊` | Complete at 30 bytes; body 0; keep-alive | §3, §6.3 r7, §9.3 |
| 2 | Row 1 in 30 one-byte reads | Incomplete ×29 then the row-1 result; each call scans only from `prev-3` | pico `is_complete` |
| 3 | Any row split into 3 reads at every pair of boundaries | Verdict identical to the unsplit row | typed-routes "every split point" |
| 4 | `…␍␊␍`+`␊`; `…␍`+`␊␍␊`; `…`+`␍␊␍␊` | Incomplete, then Complete; never a 400 from a torn terminator | §2.2 |
| 5 | Row 1 twice in one read | First parsed; second parsed from offset 30 after the first response; responses in order | §9.3.2 |
| 6 | `POST / HTTP/1.1␍␊Host: a␍␊Content-Length: 5␍␊␍␊helloGET / HTTP/1.1␍␊Host: a␍␊␍␊` | Body `hello`; next head starts at `GET`; body bytes never read as a request line | §6.3 r6 |
| 7 | `␍␊GET / HTTP/1.1␍␊Host: a␍␊␍␊` / `␍␊␍␊GET …` | one leading empty line ignored / 400 (pin the count at one; h2o closes a CRLF-only buffer with no response) | §2.2 |
| 8 | `GET  / HTTP/1.1␍␊…` / `GET /␉HTTP/1.1␍␊…` / `GET / HTTP/1.1 ␍␊…` | 400 each (two SP, HTAB, trailing SP) | §3 lenient → smuggling |
| 9 | `get / HTTP/1.1␍␊Host: a␍␊␍␊` | Parses (token); dispatch answers 501/405 — never treated as GET | §3.1 |
| 10 | `GET / http/1.1␍␊…` / `HTTP/1.10` / `HTTP/1` | 400 each | §2.3 |
| 11 | `GET / HTTP/2.0␍␊…` / `HTTP/0.9` / `HTTP/1.2` | 505 / 505 / processed as 1.1, answered `HTTP/1.1` | 9110 §15.6.6, §6.2 |
| 12 | `GET / HTTP/1.1␊Host: a␊␊` (bare LF) | 400 (our choice; pico, nginx, httparse accept it) | §2.2 MAY |
| 13 | `GET / HTTP/1.1␍Host: a␍␊␍␊` (bare CR) / NUL anywhere in the head | 400 / 400 | §2.2; 9110 §5.5 |
| 14 | `GET /a b HTTP/1.1␍␊…` | 400 | §3.2 no whitespace |
| 15 | `GET example.com:80 HTTP/1.1␍␊…` / `GET * HTTP/1.1␍␊…` | 400 / 400 (authority-form is CONNECT-only, `*` OPTIONS-only) | §3.2.3, §3.2.4 |
| 16 | `CONNECT example.com:443 HTTP/1.1␍␊Host: example.com:443␍␊␍␊` | Parses; 405/501 unless tunnelling; a 2xx turns the socket into raw bytes | §3.2.3; 9110 §9.3.6 |
| 17 | `GET http://h/p?q HTTP/1.1␍␊Host: other␍␊␍␊` | Accepted; target authority is `h`; `Host` unused for the target | §3.2.2, §3.3 |
| 18 | `GET /a#b HTTP/1.1␍␊…` | 400 | 9110 §4.2.1 |
| 19 | Request line of 8 001 printable bytes; of 70 000 | 414; the buffer never grows past the head cap | §3 MUST 414 |
| 20 | No Host on 1.1 / two `Host` lines / `Host: a b` / no Host on 1.0 | 400 / 400 / 400 / OK, close after response | §3.2; §9.3 |
| 21 | `Name : v` / `: v` / `Name:v` / `Name:  v  ` | 400 / 400 / `v` / `v` | §5.1; 9110 §5.5 |
| 22 | `X: a␍␊ b␍␊` (obs-fold) / ` X: a␍␊` as the first line | 400 / 400 | §5.2; §2.2 |
| 23 | `X: a\x7Fb` / `X: a\x01b` / `X: a\x80b` | 400 / 400 / accepted, 3 opaque bytes | 9110 §5.5 |
| 24 | 101 fields; one 8 193-byte field line; 64 KiB+1 head | 431 / 431 / 431+close, lingering | 9110 §5.4; RFC 6585 |
| 25 | `Content-Length: 5, 5`; two `Content-Length: 5` lines | 400+close (RFC permits 5; nginx and h2o refuse; refuse) | §6.3 r5; 9110 §8.6 |
| 26 | `Content-Length: 5` + `Content-Length: 6` | 400+close | §6.3 r5 |
| 27 | `Content-Length: -1` / `+5` / `0x5` / empty / `5abc` / `5 5` / `18446744073709551616` | 400+close each | 9110 §8.6 |
| 28 | `Content-Length: 5 ` (trailing OWS) | 5 | §5 OWS |
| 29 | `Content-Length: 5` + `Transfer-Encoding: chunked` | 400+close (nginx); hyper takes TE and closes — either is legal, the close is not optional | §6.1, §6.3 r3 |
| 30 | `Transfer-Encoding: chunked, gzip` / `chunked, chunked` | 400+close / 400+close | §6.3 r4; §6.1 |
| 31 | `Transfer-Encoding: gzip, chunked` / `xchunked` | 501+close (coding not implemented) | §6.1; PortSwigger TE.TE |
| 32 | `Transfer-Encoding : chunked` / `Transfer-Encoding:␉chunked` / `Transfer-Encoding: CHUNKED` | 400 / chunked (HTAB is OWS) / chunked (names case-insensitive) | §5.1; §5; §7 |
| 33 | ` Transfer-Encoding: chunked` (leading SP) / `X: X␊Transfer-Encoding: chunked` | 400 / 400 (bare LF; the channel is the value) | §2.2; 9110 §5.5 |
| 34 | `POST / HTTP/1.0␍␊Host: a␍␊Transfer-Encoding: chunked␍␊␍␊` | 400+close | §6.1 (1.0 + TE) |
| 35 | `5␍␊hello␍␊0␍␊␍␊` / `A␍␊` / `a␍␊` / `000005␍␊` / `00␍␊␍␊` | OK / OK / OK / OK / empty body | §7.1 `1*HEXDIG`, `1*("0")` |
| 36 | `5;ext=1␍␊hello␍␊0;last␍␊␍␊` | OK; extensions ignored | §7.1.1 |
| 37 | `5 ␍␊hello␍␊…` (SP, no `;`) | 400 (llhttp default; nginx/pico accept) | §7.1 BWS only before `;` |
| 38 | `5␍␊hello world␍␊…` (data longer than size) | 400+close at byte 5 (`␍` expected, ` ` found) | §7.1 |
| 39 | `5␍␊hel` then EOF / `0␍␊` then EOF | Incomplete → close, no response | §8; §7.1 |
| 40 | `0x5␍␊` / `-1␍␊` / `␍␊` (empty size) / `G␍␊` | 400+close each | §7.1 HEXDIG |
| 41 | `10000000000000000␍␊` (17 digits) / `FFFFFFFFFFFFFFFF␍␊` | 400+close (overflow) / 413+close (over body cap) | 9110 §8.6 spirit; pico 16-digit cap |
| 42 | `5␍␊hello␊0␍␊␍␊` (bare LF after data) / `5;a␊b␍␊…` (LF in ext) | 400+close / 400+close | §7.1; pico, nginx, hyper agree |
| 43 | `0␍␊Trailer: v␍␊␍␊` / `0␍␊Content-Length: 99␍␊␍␊` | Complete; trailer parsed as a field-line and dropped; framing unchanged | §7.1.2; 9110 §6.5.1 |
| 44 | `0␍␊GET / HTTP/1.1␍␊…` (final CRLF missing, next request glued) | 400+close (a trailer line without `:`) | §7.1.2 |
| 45 | Chunk sizes summing past the body cap; 4 KiB+1 of extensions | 413+close before buffering the excess / 400+close | design law 8; §7.1.1 |
| 46 | `Expect: 100-continue` + CL 5, no body bytes yet / with `hello` already buffered | write `HTTP/1.1 100 Continue␍␊␍␊` then read body / MAY skip the 100, body is `hello` | 9110 §10.1.1 |
| 47 | `Expect: 100-Continue` / `Expect: foo` / HTTP/1.0 with Expect | as row 46 / 417 / ignored | 9110 §10.1.1 |
| 48 | Handler answers 403 before reading a CL 1 GiB body | Response carries `Connection: close`, staged close | 9110 §10.1.1; §9.6 |
| 49 | 1.1 no `Connection` / 1.1 `close` / 1.0 none / 1.0 `keep-alive` | persist / close after response / close / persist only if the response carries CL | §9.3 |
| 50 | `Connection: close` request followed by a pipelined request in the same read | Second request never processed | §9.6 |
| 51 | Client: `HTTP/1.1 200 OK␍␊Content-Length: 10␍␊␍␊hello` then FIN | Incomplete: discard, connection dead, no automatic retry of a non-idempotent request | §6.3 r6, §8 |
| 52 | Client: `HTTP/1.1 200 OK␍␊␍␊hello` then FIN | Body `hello`, close-delimited; not reusable | §6.3 r8 |
| 53 | Client: HEAD → `…Content-Length: 1234␍␊␍␊` / `204` with `Content-Length: 5` | No body, reusable at once / no body, CL ignored | §6.3 r1 |
| 54 | Client: `HTTP/1.1 100 Continue␍␊␍␊HTTP/1.1 200 OK␍␊Content-Length: 0␍␊␍␊`; two `103` then `200` | Interim responses skipped; final is 200 | 9110 §15.2 |
| 55 | Client: `HTTP/1.1 200 ␍␊` (SP, empty reason) / `HTTP/1.1 200␍␊` (no SP) / `HTTP/1.1 20 OK` | accept / accept (client-side leniency; httparse does) / invalid | §4 `[ reason-phrase ]`, whitespace MAY, 3 DIGIT |
| 56 | Client: `Transfer-Encoding: gzip` in a response, no chunked | Read to close | §6.3 r4 (response) |
| 57 | Client: CONNECT → `HTTP/1.1 200 OK␍␊Content-Length: 5␍␊␍␊` | Tunnel; CL ignored | §6.3 r2 |
| 58 | Client: TE chunked + CL 5 in a response / `Connection: close` on a response | Chunked, close after / read by framing, then close; nothing pipelined | §6.3 r3; §9.6 |

Near-miss rule for the harness: rows 12 and 33 both fail on a bare LF — assert the reason
names line termination, not header parsing; row 37 must fail at the SP, not at the CR.

## 5. HTTP/2 (RFC 9113, RFC 7541)

Sources: [RFC 9113](https://www.rfc-editor.org/rfc/rfc9113.html) (HTTP/2, cited bare),
[RFC 7541](https://www.rfc-editor.org/rfc/rfc7541.html) (HPACK). The code is
`packages/std-http/src/h2.av` and `hpack.av`; every row below is a `then` in
`src/tests/h2_test.av` (H2), `h2_adversarial_test.av` (H2A), `hpack_test.av` (HP) or
`hpack_adversarial_test.av` (HA), quoted by its name, or a program test named as one.

Recommendation in one line: **a law broken on one stream resets that stream; a law
broken on the connection ends it with GOAWAY; a header block is decoded whole even for
a stream about to be refused**, because the peer's HPACK table moved when it wrote the
block, and a decoder that skips one is out of step with every block after it (§4.3).

### 5.1 What a connection is

The connection is one value, fed octets and read back: `fed(buf, at)` takes every whole
frame in the buffer and answers where the next read continues; `out` is what is owed the
peer; `ready` the requests whose heads arrived. Nothing touches a socket, so a law is a
fixture over bytes, as §1's are. A 1.1 framer refusal answers a status and closes; an h2
refusal answers a CODE (§7), on RST_STREAM or on GOAWAY — the arm is the RFC's, law by
law, never a choice.

### 5.2 Framing (§3.4, §4, §5.5)

- The client's preface is 24 fixed octets; anything else is PROTOCOL_ERROR. A torn one
  is waited for. The first frame after it is a SETTINGS that is not an ACK (§3.4).
- A frame whose length passes this end's SETTINGS_MAX_FRAME_SIZE (16384 here) is
  FRAME_SIZE_ERROR, judged from the nine-octet head before a payload octet is held (§4.2).
- An unknown frame type is ignored — except inside a header block, where ANY frame other
  than a CONTINUATION on the same stream is PROTOCOL_ERROR (§5.5, §6.10).
- PUSH_PROMISE from a client is PROTOCOL_ERROR (§8.4).

### 5.3 Streams (§5.1)

- A client opens odd streams, each id above every one it opened before; an even id, id 0
  on a stream frame, or a lower id not remembered closed is PROTOCOL_ERROR on the
  connection (§5.1.1).
- A frame on an idle stream other than HEADERS or PRIORITY is PROTOCOL_ERROR (§5.1).
- DATA or HEADERS on a stream the peer has ended is STREAM_CLOSED on the stream, and so
  is one on a stream the peer RESET; on a stream that ENDED both ways it is STREAM_CLOSED
  on the connection; on a stream THIS END reset it is ignored, since it was in flight when
  the reset left (§5.1). The last 256 closed ids are remembered with how each closed.
- A stream past SETTINGS_MAX_CONCURRENT_STREAMS (100 here) is REFUSED_STREAM, its block
  still decoded (§5.1.2).
- A stream depending on itself — in HEADERS or in PRIORITY — is PROTOCOL_ERROR on the
  stream (§5.3.1). PRIORITY is otherwise parsed and ignored (§5.3.2).

### 5.4 The small frames (§6.3–§6.9)

| Frame | Refused as | Law |
|---|---|---|
| SETTINGS on a stream | PROTOCOL_ERROR | §6.5 |
| SETTINGS of a length not a multiple of 6; an ACK with a payload | FRAME_SIZE_ERROR | §6.5 |
| ENABLE_PUSH > 1; MAX_FRAME_SIZE outside 2^14 .. 2^24-1 | PROTOCOL_ERROR | §6.5.2 |
| INITIAL_WINDOW_SIZE > 2^31-1, or a change that overflows a stream's window | FLOW_CONTROL_ERROR | §6.5.2, §6.9.2 |
| PING not of 8 octets / on a stream | FRAME_SIZE_ERROR / PROTOCOL_ERROR | §6.7 |
| RST_STREAM not of 4 octets / on stream 0 / on an idle stream | FRAME_SIZE_ERROR / PROTOCOL_ERROR / PROTOCOL_ERROR | §6.4 |
| PRIORITY not of 5 octets | FRAME_SIZE_ERROR on the stream | §6.3 |
| WINDOW_UPDATE not of 4 octets | FRAME_SIZE_ERROR | §6.9 |
| WINDOW_UPDATE of 0 | PROTOCOL_ERROR, on the stream or the connection it names | §6.9 |
| WINDOW_UPDATE past 2^31-1 | FLOW_CONTROL_ERROR, on the stream or the connection | §6.9.1 |
| GOAWAY on a stream / under 8 octets | PROTOCOL_ERROR / FRAME_SIZE_ERROR | §6.8 |

A PING is answered with an ACK carrying its payload; a PING ACK is not answered. A peer's
GOAWAY opens no more streams and ends nothing at once: this end reads on — the answers it
owes may still need WINDOW_UPDATEs, and the peer may still PING — and says its own
GOAWAY once every stream is answered and sent (§6.8). After any GOAWAY of its own the
link shuts its write side and reads what is still in flight for a bounded linger before
it closes: a socket closed over unread octets answers with a reset, and a reset may
destroy the GOAWAY before the peer reads it.

### 5.5 Flow control (§5.2, §6.9)

Every DATA octet, padding included, is charged to both windows. The CONNECTION window
that falls below half is given back whole by one WINDOW_UPDATE, so a flood of one-octet
DATA frames earns one update per half window rather than one per frame. A STREAM's window
is given back only for octets its body's reader has TAKEN (`arrived`), and padding at
once, once half a window is free — so a peer can never have more than one window of body
in flight that nobody read, however large the body, and a request's body is read as it
arrives through the same `Body` a 1.1 request has. A body its handler never read is no
longer heard: what arrives is dropped, its window is never given back, and once the answer
has ended the stream is reset with NO_ERROR (§8.1). An answer's body is given whole or
pulled piece by piece from a `Response.stream` — only while its stream's windows are open
and nothing is owed on it, so an answer holds one piece at most; a piece past the declared
length, an end short of it and a producer's failure reset the stream after what it sent.
Measured: a gigabyte down and a gigabyte up over one h2c connection in 3 MB
(`tools/bench/h2_gigabyte`, AVRA_MEM_STATS). Sending, an answer's DATA is cut to the lesser of the connection window, the
stream window and the peer's MAX_FRAME_SIZE; what does not fit is owed on the stream and
sent when a WINDOW_UPDATE — or a SETTINGS that grows INITIAL_WINDOW_SIZE — opens it. A
SETTINGS may drive a window below zero; nothing is sent until it is positive again. An
answer whose owed octets have not moved for the idle deadline ends the link with GOAWAY,
whatever else the peer sends: a window held shut behind a trickle of PINGs holds nothing
longer than an idle link does.

### 5.5a Churn (§10.5)

The streams the peer makes end in a reset — by resetting them itself (rapid reset,
CVE-2023-44487) or by breaking a stream law so this end resets them ("made you reset") —
are counted, and past twice the concurrency bound plus the streams this end answered the
connection ends with ENHANCE_YOUR_CALM. A client that cancels no more than it lets finish
never meets the bound; one that only opens and resets meets it after 201 streams of
bounded work. A request reset before its handler ran is dropped unanswered.

### 5.6 The message (§8.1–§8.3)

- A request head: pseudo-fields first, each of `:method :scheme :path :authority` at
  most once and no other; `:method`, `:scheme` and a non-empty `:path`, except CONNECT,
  which takes `:authority` and neither of the others (§8.3.1).
- Every regular field name is a lowercase token; every value is octets the 1.1 framer
  admits, with no space or tab at either end; `connection`, `keep-alive`,
  `proxy-connection`, `transfer-encoding` and `upgrade` are refused, and `te` is admitted
  only as `trailers` (§8.2.1, §8.2.2). ONE value class serves both versions, so a field
  that frames over 1.1 frames over h2 and the other way round — a request cannot become a
  different request by changing the version it arrives on.
- A declared `content-length` must equal the DATA octets received (§8.1.1): a body is
  refused the moment it passes it, and at its end when short of it.
- A second HEADERS is trailers: it must end the stream and carry no pseudo-field (§8.1).
- Each of these is PROTOCOL_ERROR on the stream: the request is malformed and never
  reaches a handler (§8.1.1).
- A head whose decoded list passes SETTINGS_MAX_HEADER_LIST_SIZE is answered 431 and the
  stream reset with NO_ERROR, asking the client to stop sending (§8.1). A body that broke
  while its handler read it — past `Limits.body` when gathered, and the rest — is answered
  by the law it broke, as over 1.1 (§6).

### 5.7 HPACK (RFC 7541)

- Every quantity the peer names meets a bound before use: an integer is refused past
  2^31-1 or after five continuation octets (a run of `0x80` adds nothing and would never
  end); a string length past the block's end is truncated; a table size update past the
  advertised SETTINGS_HEADER_TABLE_SIZE is refused, never allocated (§5.1, §6.3).
- A size update opens a block or is refused; one this end is owed after lowering its
  limit must arrive before the next block's first field (§4.2).
- Huffman padding longer than seven bits, or not the EOS code's leading ones, is refused;
  EOS itself inside a string is refused (§5.2).
- Index 0, or an index past both tables, is refused (§6.1).
- THE HPACK BOMB: one entry kept, then indexed a thousand times, is a few KiB of block
  and megabytes of list. The decoded list is costed as the table costs a field (32 plus
  the octets) and the block answers `TooLarge` at the bound — decoded whole, so the table
  stays in step, and only that stream is refused.
- Every refusal is COMPRESSION_ERROR on the connection: a decoder that refused a block no
  longer knows the peer's table.

### 5.8 Attack table

| # | Input | Required outcome | Law | Fixture |
|---|---|---|---|---|
| H1 | `GET / HTTP/1.1…` where the preface belongs | GOAWAY PROTOCOL_ERROR | §3.4 | H2 "a wrong preface ends the connection with PROTOCOL_ERROR" |
| H2 | The preface in two reads | waited for, then taken | §3.4 | H2 "a preface torn across reads is waited for" |
| H3 | PING as the first frame | GOAWAY PROTOCOL_ERROR | §3.4 | H2 "a first frame that is not SETTINGS is a PROTOCOL_ERROR" |
| H4 | A frame head claiming 16 385 octets | GOAWAY FRAME_SIZE_ERROR, no payload read | §4.2 | H2 "a frame longer than the advertised size is a FRAME_SIZE_ERROR, read from its head alone" |
| H5 | HEADERS on streams 5 then 3 | GOAWAY PROTOCOL_ERROR | §5.1.1 | H2 "a stream id below one already opened is a PROTOCOL_ERROR" |
| H6 | HEADERS, then PING, then the CONTINUATION | GOAWAY PROTOCOL_ERROR | §6.10 | H2 "any other frame inside a header block is a PROTOCOL_ERROR" |
| H7 | HEADERS then 64 empty CONTINUATIONs (CVE-2024-27316 shape) | GOAWAY ENHANCE_YOUR_CALM at the 64th | §6.10; §10.5 | H2 "a flood of empty CONTINUATIONs is ENHANCE_YOUR_CALM at the bound" |
| H8 | CONTINUATIONs carrying 80 KB of block | GOAWAY ENHANCE_YOUR_CALM past the list bound | §10.5.1 | H2 "a header block past the list bound in CONTINUATIONs is ENHANCE_YOUR_CALM" |
| H9 | 101 open streams | the 101st REFUSED_STREAM, the rest live | §5.1.2 | H2 "a stream past the concurrency bound is REFUSED_STREAM" |
| H10 | HEADERS(END_STREAM) then RST_STREAM (rapid reset, CVE-2023-44487 shape) | the request is dropped before any handler sees it | §6.4; §10.5 | H2 "a reset request is dropped before anything answers it" |
| H11 | DATA after END_STREAM | RST STREAM_CLOSED | §5.1 | H2 "DATA after the stream ended is STREAM_CLOSED on the stream" |
| H12 | Padding length ≥ the payload | GOAWAY PROTOCOL_ERROR | §6.1 | H2 "padding that claims the whole frame is a PROTOCOL_ERROR" |
| H13 | `content-length: 5` over 3 octets of DATA | RST PROTOCOL_ERROR | §8.1.1 | H2 "a body shorter or longer than its content-length resets the stream" |
| H14 | `Accept:` (uppercase) / `connection: close` / `te: gzip` | RST PROTOCOL_ERROR | §8.2 | H2 "an uppercase name, a connection field, or te other than trailers is malformed" |
| H15 | `:status` in a request; `:method` after `accept` | RST PROTOCOL_ERROR | §8.3 | H2 "a pseudo-field after a regular one, or an unknown one, is malformed" |
| H16 | A value holding CR, NUL, or a leading space | RST PROTOCOL_ERROR | §8.2.1 | H2 "a value with a CR, a NUL, or a space at an end is malformed" |
| H17 | WINDOW_UPDATE 2^31-1 on a fresh window | FLOW_CONTROL_ERROR, stream or connection | §6.9.1 | H2 "a WINDOW_UPDATE past 2^31-1 is a FLOW_CONTROL_ERROR — on the stream or the connection" |
| H18 | INITIAL_WINDOW_SIZE 0, then an answer of 10 octets | HEADERS only; DATA follows WINDOW_UPDATEs | §6.9.2 | H2 "a window shrunk by SETTINGS below zero holds DATA until it is positive" |
| H19 | A 4 KB entry kept, then `0xbe` ×1000 (HPACK bomb) | `TooLarge`; next block still reads the entry | RFC 7541 §7.3 | HA "one kept entry indexed a thousand times is too large, not a gigabyte" |
| H20 | A table size update of 2^31-1 | COMPRESSION_ERROR, nothing allocated | RFC 7541 §6.3 | HA "a resize past the advertised limit is refused, not allocated" |
| H21 | An integer `0x7f` then ten `0xff` | COMPRESSION_ERROR, not a wrapped value | RFC 7541 §5.1 | HA "a 64-bit overflow is refused, not wrapped" |
| H22 | `0xff ×4` as a Huffman string | COMPRESSION_ERROR (EOS) | RFC 7541 §5.2 | HA "the EOS symbol inside a string is refused" |
| H23 | Every vector of RFC 7541 Appendix C | decoded AND encoded octet for octet | RFC 7541 App. C | HP, by section |
| H24 | 1000 × (HEADERS + RST_STREAM) | GOAWAY ENHANCE_YOUR_CALM at churn 201, nothing live | §10.5; CVE-2023-44487 | H2A "rapid reset: open-then-reset past twice the stream bound is ENHANCE_YOUR_CALM, with nothing live" |
| H25 | 300 malformed HEADERS | GOAWAY ENHANCE_YOUR_CALM | §10.5 | H2A "made-you-reset: malformed streams past the budget are ENHANCE_YOUR_CALM" |
| H26 | 500 answered streams beside 500 reset ones | never ENHANCE_YOUR_CALM | §10.5 | H2A "a client that cancels no more than it lets finish never meets the budget" |
| H27 | 40 000 one-octet DATA frames nobody reads | one connection WINDOW_UPDATE, none on the stream | §6.9; §10.5 | H2A "a flood of one-octet DATA nobody reads earns one connection WINDOW_UPDATE per half window and none on the stream" |
| H28 | INITIAL_WINDOW_SIZE 0, a GET, then PINGs forever | GOAWAY NO_ERROR once the idle deadline passes; no DATA | §6.9; §10.5 | program `h2_starved` |
| H29 | HEADERS or DATA on a stream that ENDED both ways | GOAWAY STREAM_CLOSED | §5.1 | H2 "DATA or HEADERS on a stream that ended both ways is STREAM_CLOSED on the connection" |
| H30 | GOAWAY then PING | the PING is answered; this end's GOAWAY follows when quiet | §6.8 | H2 "a GOAWAY from the peer is read past: a PING after it is still answered" |

### 5.9 h2spec

`make h2spec` runs h2spec 2.6.0 against `tools/h2spec` (every request's body read, then
100 KB answered), in the clear and over TLS: **TLS 146 of 146; h2c 145 of 146, 0 skipped.**
The TLS run found one defect the clear run hid by timing — a handler that had read its
declared octets answered before the excess DATA arrived (8.1.2.6 #2) — so a body is now
refused the moment it passes its length. The one h2c failure is 3.5 #2, "Sends invalid connection
preface": this port serves HTTP/1.1 AND HTTP/2 by prior knowledge, so octets that are not
the preface are a 1.1 request, and `INVALID CONNECTION PREFACE` followed by a blank line is
answered 400 as §1 requires. h2spec expects an h2-only port. The two h2spec failures that
WERE defects — HEADERS on a stream that ended both ways (a stream error where §5.1 demands
a connection error), and a peer's GOAWAY followed by a PING (the link stopped reading and
the close became a reset) — are rows H29 and H30.

## 6. Streamed bodies (as built)

A body is either WHOLE (one buffer, written with its length) or a
STREAM (a producer the connection pulls, `http.av`); an incoming body
is READ as its handler asks (`body.av`). The laws, each a fixture:

| Law | Fixture |
|---|---|
| The next piece is pulled only once the last is written, so a slow peer parks its own connection's task and memory is one piece per stream | `stream_test` (pulls hold still), `http_stream_laws`, `http_stream_download` (16 MiB in the suite; `AVRA_STREAM_PIECES=16384` streams 1 GiB at a 2 MB peak native) |
| A stalled write is cancelled at the idle deadline; the stream is ended once however the pulling stops | `stream_test`, `http_stream_laws` |
| A failure after the head ends the stream where it stands — no last chunk, a length never reached — and never writes a second status | `stream_test`, `http_stream_laws` |
| A pull is given the idle deadline; a producer answering empty pieces is as quiet as one answering nothing; every piece yields the core | `stream_test` (quiet source, spinner) |
| An empty piece writes nothing: an empty chunk is the last one | `stream_test` |
| A handler runs once its head is here; a piece is at most one socket read, a chunk of any size arrives in pieces | `body_test`, `http_stream_upload` (16 MiB in the suite; 1 GiB under 1 MB native the same way) |
| `100 Continue` goes out before the first read and never for a body nobody reads | `body_test` |
| A body left unread is dropped up to `Limits.body`, else the connection closes behind the answer | `body_test` |
| A body that broke is answered by its own law (413, 400, 408), never by the handler; a peer gone mid-body is answered nothing | `body_test`, `http_stream_laws` |
| A body kept past its handler reads what it had and ends — never another message's socket | `body_test` |
| An expired event cursor is told (`cursor-expired`) before the live stream, never silently skipped | `sse_test`, `http_sse` |
| Every WebSocket protocol law is a close code, sent and answered alike | `ws_test`, `http_ws`, Autobahn (`tools/bench/autobahn`) |
| A socket ended — by the close handshake or a broken law — answers `Closed` to every later call and touches its descriptor no more; the server closes it when the session returns | `ws_test` |
| A client opening's target and authority are words of the request line: one holding a line end is refused before a byte is sent | `ws_test` |
| A gathered body is bounded from its first piece on — one chunk past `Limits.body` is 413 | `body_test` |
| A feed's log is a ring: a publish writes one slot, and a retention of zero or less keeps nothing and still numbers | `sse_test` |
| A 1xx is interim, never a final answer; the one exception is a 101 that hands the connection over and names its protocol in `upgrade` (9110 §15.2) | `http_adversarial_test` |
| A switch is made only to what a 1.1 request's `upgrade` field listed — an HTTP/1.0 `upgrade` is ignored — else the answer is the server's 500 and nothing is handed over (9110 §7.8) | `http_adversarial_test`, `ws_test` |
| A response carrying `upgrade` gets the `upgrade` option in the `connection` field the writer owns; a 426 must carry `upgrade` (9110 §7.8, §15.5.22) | `http_adversarial_test` |
| A `100 Continue` the request asked for goes out before its 101; a switch over a body the server never read is the server's 500 | `ws_test` |

Native programs pass under `AVRA_RC_GUARD=1`; the evaluator cannot run
under the guard, since the guard also holds the compiler's own freed
boxes and its const budget runs out before the program starts.

## 6. Where each row is pinned

Suite letters as `docs/2026_09_29_HTTP_CONFORMANCE.md` names them
(`packages/std-http/src/tests/`). Where the code chose differently from
§4, the row says so.

| # | Fixture |
|---|---|
| 1 | F › "a minimal request frames complete at 27 bytes with no body, persistent" |
| 2 | SA › "a request in one-byte reads is the unsplit verdict" |
| 3 | F › "every two-read split of a request agrees with the whole" (two reads, not three) |
| 4 | F › "a torn blank line is partial, then complete, never refused"; SA › "a terminator torn at each of its seams completes, never refuses" |
| 5 | F › "the second of two requests in one read frames from the first's end"; S › "two pipelined requests are answered in order" |
| 6 | F › "a body's bytes are never read as the next request line"; C › "a body is read whole before the request behind it, and both answer in order" |
| 7 | F › "one leading empty line is ignored and two are refused" |
| 8 | F › "two spaces, a tab, or a trailing space refuse the line" |
| 9 | F › "a lowercase method is a token, framed as Other" |
| 10 | F › "a version that is not HTTP/d.d refuses" |
| 11 | F › "another major version is 505 and a higher minor is framed as its own"; SA › "HTTP/2.0 is 505" |
| 12 | F › "a bare LF or a bare CR is a line-end refusal"; SA › "bare LF is 400" |
| 13 | FA › "a CR with no LF in the request line is refused"; FA › "a NUL is not a target octet, so the line ends where it sits" |
| 14 | F › "a space inside the target refuses" |
| 15 | F › "authority-form is CONNECT's and the asterisk is OPTIONS'" |
| 16 | T › "authority-form earns the same"; C › "a handler's 2xx to CONNECT goes out as the server's 500, with no tunnel promised"; C › "CONNECT with no port is refused" |
| 17 | F › "absolute-form is accepted"; T › "absolute-form hands it over" |
| 18 | F › "a fragment in the target refuses" |
| 19 | F › "a request line past the line bound is 414, before any line has ended" |
| 20 | F › "1.1 needs exactly one valid Host; 1.0 needs none"; C › "a Host with a slash in it is refused" |
| 21 | F › "space before the colon or an empty name refuses; OWS around a value is not the value" |
| 22 | F › "obs-fold and a whitespace-led first line refuse" |
| 23 | F › "a control byte in a value refuses, a high byte too" — `\x80` is REFUSED, not kept |
| 24 | F › "too many fields, a field past its bound, a head past its bound are 431" |
| 25–26 | F › "a list, a duplicate, or a disagreement refuses" |
| 27 | F › "anything but 1*DIGIT refuses, and so does a 20-digit number" |
| 28 | F › "trailing OWS is not part of the number" |
| 29 | F › "chunked beside a content-length refuses"; C › "a length beside chunks is 400 and the connection closes" |
| 30–31 | F › "chunked that is not final refuses; unknown codings before a final chunked are 501" |
| 32 | F › "HTAB is OWS and the coding's case does not matter" |
| 33 | F › "a leading space or a bare LF in the line before it refuses" |
| 34 | F › "chunked on HTTP/1.0 refuses" |
| 35 | F › "sizes in either case, with leading zeros, and the empty body all decode" |
| 36 | F › "extensions are ignored" |
| 37 | F › "a space after the size refuses" — but whitespace before a `;` is BWS, which 9110 §5.6.3 says MUST be parsed: C › "bad whitespace before a chunk extension is dropped" |
| 38 | F › "data longer than its size refuses at the byte past it" |
| 39 | F › "a torn body waits at every cut and resumes to the same end"; C › "a body cut short by the peer's close is not answered, and the connection closes" |
| 40 | F › "a size that is not hex refuses" |
| 41 | F › "seventeen digits refuse and sixteen past the body bound are 413" |
| 42 | F › "a bare LF after data or inside an extension refuses" |
| 43 | F › "trailers are parsed and dropped, framing unchanged" |
| 44 | F › "a next request glued to the last chunk is a trailer line without a colon" |
| 45 | F › "chunks summing past the body bound are 413 before any is gathered"; F › "an extension past its bound refuses" |
| 46 | S › "100 Continue is written before the body is sent"; C › "a body sent with its head earns no 100 Continue" |
| 47 | F › "100-continue is noted in any case; another expectation is 417; 1.0 ignores it" |
| 48 | SA › "a body past its bound is 413 and the connection closes" — the body is read before a handler runs, so its bound answers first |
| 49 | F › "persistence follows the version and the connection field" |
| 50 | C › "a request pipelined behind connection: close is never processed" |
| 51 | CA › "a body cut short by the close is an error" |
| 52 | CA › "a reply with no length is whole at the close" |
| 53 | R › "a HEAD's answer has none whatever its length says"; R › "a 204 has none" |
| 54 | gap `avra-8sb5.1.30.5` — the client hands a 1xx back as its answer |
| 55 | R › "a reason may be empty"; R › "a reason may be absent"; R › "a two-digit status is refused" |
| 56 | none — a reply coded without chunked is REFUSED (`.Coding`), not read to the close |
| 57 | C › "a CONNECT's 2xx is a tunnel, its length ignored" |
| 58 | R › "chunked beside a length is refused" — refused rather than taken as chunked |

## 7. Server hardening reference — every bound and deadline

Every bound is a field of an inspectable value with a default, built at the server and
read by the framer: `served(l, make, limits, timing, handle)`. `Limits {}` and `Timing {}`
are the defaults, and a literal overrides one field at a time (`Limits { head: 16384 }`,
`Timing { idle: secs(30) }`). Read from `frame.av` and `server.av`, not from memory.

### 7.1 The framer's bounds (`Limits`)

| Bound | Default | Refused as | What it bounds, and the attack it answers |
|---|---|---|---|
| `line` | 8 KiB | `.LineLength` → 414 | One request/status line, before a line can grow without bound. |
| `field` | 8 KiB | `.FieldLength` → 431 | One field line. |
| `head` | 64 KiB | `.HeadLength` → 431 | The whole head (line, fields, blank line). |
| `fields` | 100 | `.FieldCount` → 431 | How many field lines one head carries. |
| `body` | 1 MiB | `.BodyLength` → 413 | A body GATHERED whole into memory; refused only when something asks to gather it. |
| `stream` | 1 GiB | `.BodyLength` → 413 | A body READ piece by piece; refused at the head. One piece of memory however long it runs. |
| `ext` | 4 KiB | `.Chunk` → 400 | Total chunk extensions on a body. |
| `trailers` | 16 | `.Chunk` → 400 | Trailer field count after the last chunk. |

A refusal's status is `status_of(why)`; the body limit answers 413, a line 414, a head or
field 431, and every other framing break 400.

### 7.2 The server's deadlines (`Timing`)

| Bound / deadline | Default | What it ends | Attack it bounds |
|---|---|---|---|
| `handshake` | 10 s | A TLS handshake, measured from the accept. | A peer that opens TLS and stalls. |
| `handshakes` | 1024 at once | How many handshakes run on one core. | A handshake flood across connections. |
| `head` | 10 s | A head since its last byte. | Slowloris: a head dribbled one byte at a time. |
| `body` | 60 s | A body since its last byte. | A slow or stalled body. |
| `idle` | 75 s | An idle keep-alive connection — and a peer that takes no output. | A connection parked forever. |
| `requests` | 1000 | How many requests one connection serves. | Connection reuse without end. |
| `drain` | 30 s | Every wait, once `stop` is called. | A shutdown held open by a parked reader. |

Every deadline is per connection and ends the wait it bounds; a deadline that passes
closes the connection. `handshakes` and `requests` are counts, not clocks.

### 7.3 HTTP/2's windows and caps

HTTP/2's own bounds are advertised in the server's SETTINGS, built by
`server_settings(limits)` from the same `Limits` the 1.1 framer uses.

| Setting (§6.5) | Value | Where it comes from |
|---|---|---|
| `SETTINGS_MAX_CONCURRENT_STREAMS` | 100 | `server_settings`, fixed. |
| `SETTINGS_MAX_HEADER_LIST_SIZE` | `limits.head` (64 KiB) | `server_settings(limits)`. |
| `SETTINGS_MAX_FRAME_SIZE` | 16384 | Protocol default; not raised. |
| `SETTINGS_INITIAL_WINDOW_SIZE` | 65535 | Protocol default; grown by WINDOW_UPDATE. |
| `SETTINGS_HEADER_TABLE_SIZE` | 4096 | Protocol default; HPACK's dynamic-table bound (`hpack.default_table`, RFC 9113 §6.5.2). |

A head whose decoded list passes the header-list bound is answered 431 and the stream reset
with NO_ERROR; a chunk of decoded list is bounded before it allocates, so an HPACK bomb
meets the list bound rather than the allocator. Churn — streams reset by the peer or by a
broken stream law this end resets — is counted, and past `2 × streams + answered` the
connection ends with GOAWAY ENHANCE_YOUR_CALM (rapid reset, CVE-2023-44487); a client that
only opens and resets meets it after 201 streams of bounded work.

To change an h2 cap that is not a `Limits` field yet, edit `server_settings`; the stream
cap and the frame/window defaults are protocol facts and are not caller knobs.
