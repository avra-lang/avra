# HTTP conformance checklist — RFC 9112, RFC 9110 and RFC 9113 against @std/http

Every MUST / MUST NOT of [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html)
and the server-relevant ones of [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html),
each with the fixture that pins it or the ticket that owns the gap. Sentences
were extracted mechanically from the RFC text (87 MUSTs in 9112, all here).
The framers are also fuzzed (`make fuzz-http`, corpus and every kept
finding in `packages/std-http-fuzz`) and soaked (`make soak-http`).
A fixture is named `suite › "then"`; every suite lives in
`packages/std-http/src/tests/`.

| Suite | File |
|---|---|
| C | `conformance_test.av` — this checklist's own rows |
| F / FA | `frame_test.av` / `frame_adversarial_test.av` |
| R | `reply_test.av` |
| H | `http_adversarial_test.av` |
| RA / T | `route_adversarial_test.av` / `target_form_adversarial_test.av` |
| S / SA | `server_test.av` / `server_adversarial_test.av` |
| CT / CA | `client_test.av` / `client_adversarial_test.av` |
| D | `date_test.av` |

Role words: **N/A** — the requirement binds a role @std/http does not play
(proxy, intermediary, cache, registry). **Handler** — it binds a response only
an application can build (a 401's challenge, a PUT's 201); the library neither
writes nor forbids it. A gap is a ticket under `avra-8sb5.1.30`.

## Deliberate deviations (legal, and chosen)

- Every widening MAY is refused (the framing laws): bare LF, obs-fold, `SP SP` —
  save obs-fold in a REPLY, which a user agent MUST read as spaces (9112 §5.2).
- A `date` field is the writer's: a handler naming one is the server's 500.
- A caller's `te` is refused: the client asks for no transfer coding.
- A client refuses to send a head its own framer would refuse.
- `obs-text` in a field value is refused (9110 §5.5 lets a recipient keep it).
- An empty `Host` is refused, though `uri-host` may be empty.
- Two equal `Content-Length` lines are refused (9110 §8.6 MAY merge them).

## RFC 9112 — every MUST

| # | § | Requirement | Fixture or gap |
|---|---|---|---|
| 1 | 1.1 | BCP 14 keywords | N/A |
| 2 | 2.2 | parse as octets, a superset of US-ASCII | RA › "an obs-text target the framer admits is unrouted, not a wreck"; H › "A TARGET THE FRAMER ADMITS AND UTF-8 CANNOT SPELL IS ABSENT, NEVER EMPTY" |
| 3 | 2.2 | sender generates no bare CR | H › "A CRLF IN A VALUE IS NOT A SECOND FIELD"; CA › "A CRLF IN A HEADER VALUE IS NOT A SECOND FIELD" |
| 4 | 2.2 | a bare CR is invalid (or SP) | FA › "a CR with no LF in the request line is refused"; F › "a bare LF or a bare CR is a line-end refusal" |
| 5 | 2.2 | UA sends no CRLF before or after a request | C › "a body-less request ends at its blank line — no CRLF before or after" |
| 6 | 2.2 | a body's trailing CRLF counts in its length | C › "a request with a body ends where its length says" |
| 7 | 2.2 | no whitespace between start-line and first field (sender) | H › "a space in a name is refused" |
| 8 | 2.2 | …reject it or ignore the line (recipient) | F › "obs-fold and a whitespace-led first line refuse" |
| 9 | 2.3 | intermediaries send their own version | N/A |
| 10 | 3 | target too long: 414 | F › "a request line past the line bound is 414, before any line has ended" |
| 11 | 3.2 | client sends Host in every 1.1 request | CA › "a plain request frames with its host alone"; CA › "an empty host is not a host" |
| 12 | 3.2 | client's Host equals the URI authority minus userinfo | C › "the path and query are the target, and the authority less userinfo the host"; C › "the scheme's own port is not written"; C › "an IPv6 host keeps its brackets" |
| 13 | 3.2 | client sends an empty Host when the URI has no authority | N/A (an `http` or `https` URI always has one): C › "a URL with no host aims nowhere" |
| 14 | 3.2 | server: 400 for a missing, repeated or invalid Host | F › "1.1 needs exactly one valid Host; 1.0 needs none"; C › given "the host law" (12 rows) |
| 15 | 3.2.1 | client sends only path and query to an origin | C › "the path and query are the target, and the authority less userinfo the host"; C › "a fragment is never sent" |
| 16 | 3.2.1 | client sends `/` for an empty path | C › "an empty path is sent as /" |
| 17 | 3.2.2 | client to a proxy sends absolute-form | N/A (the client speaks to no proxy) |
| 18 | 3.2.2 | client sends Host beside absolute-form | CA › "a plain request frames with its host alone" (Host is always written) |
| 19–20 | 3.2.2 | proxy replaces Host from absolute-form | N/A |
| 21 | 3.2.2 | origin ignores Host for absolute-form, uses the target's host | T › "absolute-form hands it over"; T › "origin-form and absolute-form reach the SAME route" |
| 22 | 3.2.2 | server accepts absolute-form | F › "absolute-form is accepted"; C › "a scheme opens with a letter and holds letters, digits, `+`, `-` and `.`"; C › "a scheme holding a `?` is no scheme, so the target is refused (fuzz: trap-272-75247)" |
| 23 | 3.2.3 | client CONNECT sends host:port only | N/A (the client sends no CONNECT) |
| 24 | 3.2.4 | client server-wide OPTIONS sends `*` | N/A (the caller's target is written as given) |
| 25 | 3.2.4 | last proxy rewrites to `*` | N/A |
| 26 | 4 | server sends the SP before an absent reason | C › "an unregistered status carries its class's reason after the space" (a reason is never absent) |
| 27 | 5.1 | server: 400 for whitespace between name and colon | F › "space before the colon or an empty name refuses; OWS around a value is not the value" |
| 28 | 5.1 | proxy strips it from responses | N/A |
| 29 | 5.2 | sender generates no obs-fold | H › "A CRLF IN A VALUE IS NOT A SECOND FIELD" |
| 30 | 5.2 | server: obs-fold is 400 (or SP) | F › "obs-fold and a whitespace-led first line refuse"; FA › "OBS-FOLD IS NOT A CONTINUATION, it is a line with no name" |
| 31 | 5.2 | proxy: obs-fold response is 502 | N/A |
| 32 | 5.2 | UA replaces an obs-fold in a response with SP | R › "a fold by space or tab keeps its length and joins its field"; CA › "a folded field reads with each fold as spaces"; CA › "a close hidden in a fold is heard" |
| 33 | 6.1 | recipient parses chunked | F › "sizes in either case, with leading zeros, and the empty body all decode"; S › "a chunked body is decoded before the handler runs"; CA › "a chunked reply is decoded across reads" |
| 34 | 6.1 | sender chunks at most once | H › "a handler's transfer-encoding is refused beside a length" (nothing is ever sent chunked) |
| 35 | 6.1 | request codings end in chunked | CA › "and a transfer-encoding beside a length is the smuggling shape" (the client sends no coding) |
| 36 | 6.1 | response codings end in chunked or close | H › "a handler's transfer-encoding is refused beside a length" |
| 37 | 6.1 | no TE in 1xx or 204 | H › "a handler's transfer-encoding is refused beside a length" |
| 38 | 6.1 | no TE in a 2xx to CONNECT | C › "a handler's 2xx to CONNECT goes out as the server's 500, with no tunnel promised" |
| 39 | 6.1 | client sends TE only to a 1.1 server | CA › "and a transfer-encoding beside a length is the smuggling shape" |
| 40 | 6.1 | server sends TE only to a 1.1 request | H › "a handler's transfer-encoding is refused beside a length" |
| 41 | 6.1 | TE beside CL: close after responding | C › "a length beside chunks is 400 and the connection closes"; F › "chunked beside a content-length refuses" |
| 42 | 6.1 | a 1.0 message with TE is faulty; close | F › "chunked on HTTP/1.0 refuses"; R › "chunked on an HTTP/1.0 reply refuses, as it does on a request" |
| 43 | 6.2 | no CL beside TE | H › "a handler's transfer-encoding is refused beside a length" |
| 44 | 6.3 | client ignores CL/TE of HEAD, 1xx, 204, 304, CONNECT 2xx | R › "a HEAD's answer has none whatever its length says", "a 204 has none", "a 304 has none", "a 1xx has none"; C › "a CONNECT's 2xx is a tunnel, its length ignored" |
| 45 | 6.3 | intermediary drops CL before forwarding | N/A |
| 46 | 6.3 | request TE not ending in chunked: 400 and close | F › "chunked that is not final refuses; unknown codings before a final chunked are 501"; S › "a refused head is answered 400 and the connection closed" |
| 47–48 | 6.3 | invalid CL in a request: 400 and close | F › "anything but 1*DIGIT refuses, and so does a 20-digit number"; F › "a list, a duplicate, or a disagreement refuses" |
| 49 | 6.3 | proxy: invalid CL response is 502 | N/A |
| 50 | 6.3 | UA: invalid CL response — close and discard | CA › "a reply the framer refuses is an error naming the law"; CA › "a refused reply ends it, and its bytes are never the next reply" |
| 51 | 6.3 | a body cut short is incomplete; close | C › "a body cut short by the peer's close is not answered, and the connection closes"; SA › "a peer gone mid-head is dropped"; CA › "a body cut short by the close is an error" |
| 52 | 6.3 | UA request with a body sends a valid CL | CA › "a body earns a length, which the server reads" |
| 53 | 6.3 | client sends chunked only to a 1.1 server | CA › "and a transfer-encoding beside a length is the smuggling shape" |
| 54 | 6.3 | client never treats extra data as a response | CA › "a reply past the one asked for is never the next request's" |
| 55 | 7.1 | recipient decodes chunked | as row 33 |
| 56 | 7.1 | large hex sizes never overflow | F › "seventeen digits refuse and sixteen past the body bound are 413" |
| 57 | 7.1.1 | unrecognized chunk extensions are ignored | F › "extensions are ignored"; C › "bad whitespace before a chunk extension is dropped" |
| 58 | 7.1.2 | a retained trailer is kept apart or merged | F › "trailers are parsed and dropped, framing unchanged" (none is retained) |
| 59 | 7.1.2 | a trailer is never merged into the head | F › "trailers are parsed and dropped, framing unchanged" |
| 60–62 | 7.3 | transfer-coding registrations | N/A |
| 63 | 7.4 | client sends no `chunked` in TE | CA › "a caller's te is refused — chunked most of all" |
| 64 | 7.4 | a TE sender lists TE in Connection | N/A (the client sends no TE): CA › "a caller's te is refused — chunked most of all" |
| 65 | 8 | client records an incomplete response | CA › "a body cut short by the close is an error" |
| 66 | 9.2 | client keeps outstanding requests in order | N/A (the client never pipelines) |
| 67 | 9.2 | data with no request outstanding is not a response | CA › "a reply past the one asked for is never the next request's"; a pooled connection that turned readable while idle is closed, never lent (`pool.av`) |
| 68 | 9.3 | a client without persistence sends close | N/A (the client persists) |
| 69 | 9.3 | a server without persistence sends close | N/A (the server persists) |
| 70 | 9.3 | server reads the whole body or closes | C › "a body is read whole before the request behind it, and both answer in order"; SA › "a body past its bound is 413 and the connection closes" |
| 71 | 9.3 | client reads the whole body before reuse | CA › "two replies ride one connection" |
| 72 | 9.3 | proxy keeps no persistence with 1.0 | N/A |
| 73 | 9.3.2 | pipelined responses in request order | S › "two pipelined requests are answered in order" |
| 74 | 9.3.2 | client does not pipeline a retried connection | N/A (the client never pipelines) |
| 75 | 9.6 | client that sent close sends no more | CA › "a request saying close ends it, whatever the reply says" |
| 76–77 | 9.6 | server receiving close: close after responding, process nothing more | S › "connection: close is honoured"; C › "a request pipelined behind connection: close is never processed" |
| 78–79 | 9.6 | server sending close: close, process nothing more | SA › "the last permitted request carries connection: close"; S › "a refused head is answered 400 and the connection closed" |
| 80 | 9.6 | client receiving close ceases sending | CA › "a reply saying close ends it" |
| 81 | 9.7 | HTTP over TLS is application data | @std/https (`wire.av`'s `Transport`: TLS carries the same framing) |
| 82–83 | 9.8 | closure alerts before close | `packages/std-https/src/tests/https_test.av` › "closure alerts" |
| 84 | 10.1 | message/http replaces obs-fold | N/A (no message/http) |

## RFC 9110 — the server-relevant MUSTs

Numbers are the extraction's (201 sentences). Rows below are every one a
server, a recipient of requests, or the library's writer can break.

| # | § | Requirement | Fixture or gap |
|---|---|---|---|
| 2 | 2.2 | generate only what the ABNF allows | H › "a status line carries three digits, so 1000 cannot be written"; H › "a space in a name is refused" |
| 4 | 2.3 | parse elements as long as those generated | F › "too many fields, a field past its bound, a head past its bound are 431" (bounds named in `Limits`) |
| 8, 10 | 4.2.1, 4.2.2 | reject an http(s) URI with an empty host | C › "absolute-form with an empty host is refused"; T › "an EMPTY authority names no host, and the target is refused (RFC 9110 §4.2.1)" |
| 22 | 5.3 | no repeated field lines (sender) | H › "a handler's content-length does not join the writer's" (the writer's own fields once; a handler's are the handler's) |
| 23 | 5.3 | apply no request before its whole head | SA › "a terminator torn at each of its seams completes, never refuses"; S › "a body split across reads is gathered before the handler runs" |
| 24 | 5.4 | oversized fields earn a 4xx | F › "too many fields, a field past its bound, a head past its bound are 431"; SA › "a head past its bound is 431 and the connection closes" |
| 25 | 5.5 | OWS is not part of a value | F › "space before the colon or an empty name refuses; OWS around a value is not the value"; FA › "tabs are OWS on both sides" |
| 26 | 5.5 | CR, LF, NUL in a value: reject (or SP) | FA › "a NUL in a value is not visible ASCII"; F › "a control byte in a value refuses, a high byte too" |
| 28–29 | 5.6.1.2 | ignore empty list members | C › "empty list members before chunked are ignored"; C › "empty list members around close are ignored" |
| 30 | 5.6.3 | generate no BWS | nothing generated carries BWS (no chunked output) |
| 31 | 5.6.3 | parse and drop BWS | C › "bad whitespace before a chunk extension is dropped"; C › "bad whitespace torn from its extension waits for the rest" |
| 34–35 | 5.6.7 | generate HTTP-dates as IMF-fixdate | D › given "IMF-fixdate (RFC 9110 §5.6.7)" (7 rows) |
| 39 | 6.2 | send only a version one conforms to | S › "a GET is answered exactly, and the handler saw its state" (`HTTP/1.1`) |
| 40 | 6.5.1 | generate no trailer unless permitted | nothing is sent chunked, so no trailer is generated |
| 41 | 6.5.1 | never merge a trailer into the head | F › "trailers are parsed and dropped, framing unchanged" |
| 43 | 6.6.1 | an origin with a clock sends Date in 2xx–4xx | C › "every response is dated, this second, in IMF-fixdate (RFC 9110 §6.6.1, §5.6.7)"; D › "a handler's own date is the server's to write, so it is not sendable" |
| 46 | 7.1 | authority-form and `*` with their methods only | F › "authority-form is CONNECT's and the asterisk is OPTIONS'" |
| 48–49 | 7.4 | reject a target whose scheme's requirements fail (https over plain) | `scheme_test.av` › "an https target is misdirected", "the scheme is judged ignoring case"; `std-https` `https_test.av` (421 for http over TLS) |
| 54 | 7.6.1 | no connection option for an end-to-end field | H › "a handler's connection contradicts the fate the writer speaks" |
| 64–70 | 7.8 | Upgrade: 101 and 426 carry it, `upgrade` listed in Connection, 1.0 ignored, 100 before 101 | `avra-8sb5.1.30.13`, on lane/http-streaming (a219e8c) until it lands; here no 1xx is sendable: C › "a 1xx is interim, never an answer, so it is not sendable" |
| 73 | 8.6 | a HEAD's CL equals the GET's | S › "a HEAD carries the body's length and none of its bytes"; C › "a HEAD to a GET route carries the GET's length and no body" |
| 74 | 8.6 | a 304's CL equals the 200's | C › "a 304 states no length" |
| 75 | 8.6 | no CL in 1xx or 204 | C › "a 204 states no length"; C › "a 1xx is interim, never an answer, so it is not sendable" |
| 76 | 8.6 | no CL in a 2xx to CONNECT | C › "a handler's 2xx to CONNECT goes out as the server's 500, with no tunnel promised" |
| 77 | 8.6 | large CL numerals never overflow | FA › "NINETEEN DIGITS ARE REFUSED AS A NUMBER, never wrapped" |
| 86 | 9.1 | support GET and HEAD | C › "a HEAD no HEAD route answers is answered by the GET route"; C › "a HEAD route answers before the GET route"; C › "only a HEAD falls back — a POST is never answered by a GET route" |
| 89 | 9.3.2 | no content in a HEAD's answer | S › "a HEAD carries the body's length and none of its bytes"; SA › "AND SO DOES A HEAD — the body it strips is the WRITTEN response's, never the handler's" |
| 95 | 9.3.6 | reject CONNECT with an empty or invalid port | C › "CONNECT with no port is refused", "CONNECT with an empty port is refused", "CONNECT with a port that is not digits is refused", "CONNECT with no host is refused" |
| 97 | 9.3.6 | no TE/CL in a 2xx to CONNECT | as row 76 |
| 98 | 9.3.6 | client ignores CL/TE of a CONNECT 2xx | C › "a CONNECT's 2xx is a tunnel, its length ignored" |
| 105 | 10.1.1 | ignore 100-continue on HTTP/1.0 | F › "100-continue is noted in any case; another expectation is 417; 1.0 ignores it" |
| 106–109 | 10.1.1 | send 100 without waiting for content, then a final status | S › "100 Continue is written before the body is sent" |
| 146–147, 153, 155, 158–159, 162 | 13–14 | ignore If-Range without Range, conditionals and Range where undefined | hold trivially: the library evaluates no conditional or Range field (static files, `avra-8sb5.1.29.3`, will) |
| 165 | 15.2 | no 1xx to an HTTP/1.0 client | F › "100-continue is noted in any case; another expectation is 417; 1.0 ignores it"; C › "a 1xx is interim, never an answer, so it is not sendable" |
| 166 | 15.2 | client parses 1xx before the final reply | CA › "interim replies are read and passed over, torn or whole, to the answer"; CA › "a 101 is the answer, not an interim reply, and the connection is no longer HTTP's" |
| 168, 189 | 15.2.2, 15.5.22 | 101 and 426 carry Upgrade | `avra-8sb5.1.30.13`, as rows 64–70 |
| 169 | 15.3.6 | no content in a 205 | C › "a 205 carrying content is not sendable" |
| — | 15.3.5, 15.4.5 | no content in a 204 or 304 (the body rule behind rows 74–75) | C › "a 204 carrying content is not sendable"; C › "a 304 carrying content is not sendable"; C › "and each goes out as the server's own 500" |

The rest, by role (9110 extraction numbers):

- **Client or user agent** — 11–19 (TLS identity: H2, `avra-8sb5.1.25`),
  7, 9 and 12 (an empty host, userinfo: C › "userinfo is never generated — a URL carrying it is refused"), 37–38, 47, 94, 100–104, 110–114
  (113: CA › "a request saying close ends it, whatever the reply says"), 117, 126, 145, 148–149, 160, 164, 170, 178–182,
  184 (redirects: H5, `avra-8sb5.1.28`).
- **Handler** — 3, 5–6, 27, 32–33, 36, 44–45, 52, 71–72 (encodings and
  multipart: H6, `avra-8sb5.1.29`), 80–85, 87, 90–93, 115 and 186 (a 405
  writes Allow — the router answers 404, never 405), 118–120, 124–125,
  129–144, 150–152, 154, 156–157, 161, 163, 171–177, 183, 185.
- **Proxy, intermediary, cache, gateway** — 20–21, 50–51, 53, 55–63, 78–79,
  88, 96, 99, 116, 121–123, 127–128, 167, 187–188.
- **Registries and BCP 14** — 1, 42, 190–201.

## RFC 9113 — every MUST

Every MUST / MUST NOT of [RFC 9113](https://www.rfc-editor.org/rfc/rfc9113.html),
extracted mechanically (210 sentences, all here). @std/http plays the
server role only: there is no HTTP/2 client, and push is never sent — the
server's SETTINGS carries `SETTINGS_ENABLE_PUSH` 0 and no PUSH_PROMISE is
ever written (`h2.av`'s `server_settings`, `dispatched`). The h2 suites
live on `lane/http-http2` until it lands.

| Suite | File |
|---|---|
| H2 | `std-http/src/tests/h2_test.av` |
| H2A | `std-http/src/tests/h2_adversarial_test.av` |
| H2S | `std-http/src/tests/h2_serve_test.av` |
| HP / HPA | `std-http/src/tests/hpack_test.av` / `hpack_adversarial_test.av` |
| TA / TC | `std-tls/src/tests/alpn_test.av` / `certs_test.av` |
| program | `h2_attack_digest`, `h2_starved`, `h2_stream`, `h2_stream_laws`, `h2c_serve`, `hpack_roundtrip` (std-http), `h2_versions` (std-https) — cited `dir › "expected line"` |

**h2spec §x.y** — a test group of h2spec 2.6.0 (`tools/h2spec.sh`, run in
the clear and over TLS). h2spec numbers its groups by RFC 7540 (§3.5 is
9113's §3.4; §8.1.2.x is 9113's §8.2–8.3) and its `hpack` groups by
RFC 7541. **Construction** — no fixture, but the code has no path that
breaks the requirement; the reason is named.

| # | § | Requirement | Fixture or gap |
|---|---|---|---|
| 1 | 2.2 | BCP 14 keywords | N/A |
| 2 | 3.2 | `h2c` never selected over TLS | gap `avra-8sb5.1.30.16` |
| 3 | 3.2 | after TLS, both ends send a preface | H2 › "the server owes its SETTINGS before it reads a byte: 100 streams, the 1.1 head as the list bound"; h2_versions › "h2 agreed over TLS: h2"; h2spec §3.5 |
| 4 | 3.3 | h2 over TLS uses ALPN | gap `avra-8sb5.1.30.17` — ALPN agrees (TA › "both prefer h2 and both agree on it"; h2_versions › "h2 agreed over TLS: h2") but is not required |
| 5 | 3.3 | server sends a preface | H2 › "the server owes its SETTINGS before it reads a byte: 100 streams, the 1.1 head as the list bound"; h2spec §3.5 |
| 6 | 3.4 | client preface is followed by SETTINGS | H2 › "a first frame that is not SETTINGS is a PROTOCOL_ERROR"; H2 › "a first SETTINGS that is an ACK is a PROTOCOL_ERROR" (receipt; the rule binds a client) |
| 7 | 3.4 | server's first frame is SETTINGS | H2 › "the server owes its SETTINGS before it reads a byte: 100 streams, the 1.1 head as the list bound"; h2spec §3.5 |
| 8 | 3.4 | preface SETTINGS acknowledged | H2 › "the client's SETTINGS is acknowledged"; h2spec §6.5.3 |
| 9 | 3.4 | invalid preface: connection PROTOCOL_ERROR | H2 › "a wrong preface ends the connection with PROTOCOL_ERROR"; H2 › "a preface torn across reads is waited for"; h2spec §3.5 (over TLS; see the deviation below) |
| 10 | 4.1 | send no frame past the peer's max frame size | H2 › "DATA never passes the peer's frame size"; H2 › "an answer's head past the frame size continues in CONTINUATIONs" |
| 11 | 4.1 | unknown frame types ignored | H2 › "a frame of an unknown type is ignored"; h2spec §4.1, §5.5 |
| 12–13 | 4.1 | unused flags and the reserved bit: unset on send, ignored on receipt | h2spec §4.1 |
| 14 | 4.2 | receive frames up to 2^14 octets | h2spec §4.2 |
| 15 | 4.2 | oversize or undersize frame: FRAME_SIZE_ERROR | H2 › "a frame longer than the advertised size is a FRAME_SIZE_ERROR, read from its head alone"; H2 › "a PING of seven octets is a FRAME_SIZE_ERROR"; h2spec §4.2 |
| 16 | 4.2 | size error on a connection-state frame: connection error | H2A › "a prioritised HEADERS too short for its five octets is a FRAME_SIZE_ERROR, not a trap"; H2A › "a padded, prioritised HEADERS whose padding leaves too little is a FRAME_SIZE_ERROR"; h2spec §4.2 |
| 17 | 4.3 | a field block's frames sent contiguously | H2 › "an answer's head past the frame size continues in CONTINUATIONs" |
| 18–19 | 4.3 | undecodable field block: COMPRESSION_ERROR | H2 › "a malformed header block is a COMPRESSION_ERROR"; HPA › "index zero is refused"; h2spec §4.3; h2spec hpack §2.3, §4.2, §5.2, §6.1, §6.3 |
| 20 | 4.3.1 | acked table reduction: encoder opens with a size update | H2A › "a SETTINGS that shrinks the peer's table opens the next answer with the size update"; HPA › "a resize is announced at the next block's start, least then final" |
| 21 | 4.3.1 | block after our reduction lacking the update: COMPRESSION_ERROR | HPA › "a lowered limit is owed a resize: a field first is refused"; HPA › "a lowered limit refuses a resize over it" |
| 22 | 5.1 | idle: only HEADERS or PRIORITY, else PROTOCOL_ERROR | H2 › "DATA on an idle stream is a PROTOCOL_ERROR"; H2 › "RST_STREAM on an idle stream is a PROTOCOL_ERROR"; H2 › "PRIORITY on an idle stream is taken and opens nothing"; h2spec §5.1 |
| 23 | 5.1 | HEADERS on a server-initiated idle stream: PROTOCOL_ERROR | N/A (push is never sent, so the server initiates no stream) |
| 24–27 | 5.1 | reserved states: what may be sent and received | N/A (push is never sent, so no stream is reserved; a client's PUSH_PROMISE is refused, row 177) |
| 28 | 5.1 | half-closed (remote): more frames are STREAM_CLOSED | H2 › "DATA after the stream ended is STREAM_CLOSED on the stream"; h2spec §5.1 |
| 29 | 5.1 | nothing but PRIORITY sent on a closed stream | H2 › "an answer on a stream that is gone writes nothing"; H2A › "a stream the peer reset is never hungry, and cancelling it says nothing more" |
| 30 | 5.1 | after our RST_STREAM, process then discard | H2 › "frames in flight to a stream this end reset are ignored"; H2A › "a malformed head still moves the table" |
| 31 | 5.1.1 | client streams odd, server streams even | H2 › "HEADERS on an even stream is a PROTOCOL_ERROR" (receipt; the server opens none) |
| 32 | 5.1.1 | a new stream id exceeds every earlier one | H2 › "a stream id below one already opened is a PROTOCOL_ERROR" (receipt) |
| 33 | 5.1.1 | unexpected stream id: connection PROTOCOL_ERROR | H2 › "HEADERS on an even stream is a PROTOCOL_ERROR"; H2 › "a stream id below one already opened is a PROTOCOL_ERROR"; h2spec §5.1.1 |
| 34 | 5.1.2 | never exceed the peer's stream limit | N/A (the server opens no stream) |
| 35 | 5.1.2 | past our stream limit: PROTOCOL_ERROR or REFUSED_STREAM | H2 › "a stream past the concurrency bound is REFUSED_STREAM"; H2A › "a block on a stream past the concurrency bound still moves the table"; h2spec §5.1.2 |
| 36 | 5.2.1 | sender respects the receiver's flow control | H2 › "an answer past the window sends what fits and owes the rest until WINDOW_UPDATE"; h2_stream › "downloaded 4194304 octets; with its window held shut after 65535, the server had pulled 1 piece(s)"; h2spec §6.9.1 |
| 37 | 5.2.2 | read frames as soon as data is available | gap `avra-8sb5.1.30.18` |
| 38 | 5.4 | a connection error is reported | H2 › "a wrong preface ends the connection with PROTOCOL_ERROR"; h2spec §5.4.1 |
| 39 | 5.4.1 | close TCP after an error GOAWAY | h2_starved › "closed: true, goaway: 0, body octets sent: 0, within 3 s: true"; h2spec §5.4.1 |
| 40 | 5.4.2 | after sending RST_STREAM, take what was in flight | H2 › "frames in flight to a stream this end reset are ignored"; H2A › "a refusal sent while the body flows ignores the DATA the client had in flight" |
| 41 | 5.4.2 | never RST_STREAM in answer to RST_STREAM | Construction — `reset_by_peer` owes nothing; H2 › "a reset request is dropped before anything answers it" asserts the drop, not the silence |
| 42 | 5.5 | unknown values in extensible elements ignored | H2 › "an unknown setting is ignored"; h2spec §5.5, §6.5.2, §7 |
| 43 | 5.5 | unknown frame types discarded | H2 › "a frame of an unknown type is ignored"; h2spec §5.5 |
| 44 | 5.5 | extension frame inside a field block: PROTOCOL_ERROR | H2 › "any other frame inside a header block is a PROTOCOL_ERROR"; h2spec §5.5 |
| 45–46 | 5.5 | extensions negotiated; off by default | N/A (no extension is spoken) |
| 47 | 6.1 | DATA padding zero when sent | Construction — the server writes no padding (`frame_onto`) |
| 48–49 | 6.1 | DATA on stream 0: PROTOCOL_ERROR | H2 › "DATA on stream 0 is a PROTOCOL_ERROR"; h2spec §6.1 |
| 50 | 6.1 | DATA outside open/half-closed (local): STREAM_CLOSED | H2 › "DATA after the stream ended is STREAM_CLOSED on the stream"; H2 › "DATA on a stream the peer reset is STREAM_CLOSED on the stream"; h2spec §6.1 |
| 51 | 6.1 | DATA padding ≥ payload: PROTOCOL_ERROR | H2 › "padding that claims the whole frame is a PROTOCOL_ERROR"; h2spec §6.1 |
| 52 | 6.2 | HEADERS padding zero when sent | Construction — the server writes no padding (`frame_onto`) |
| 53 | 6.2 | HEADERS without END_HEADERS: CONTINUATION follows | H2 › "an answer's head past the frame size continues in CONTINUATIONs" |
| 54 | 6.2 | other frame inside a HEADERS block: PROTOCOL_ERROR | H2 › "any other frame inside a header block is a PROTOCOL_ERROR"; H2 › "a CONTINUATION on another stream is a PROTOCOL_ERROR"; h2spec §4.3, §6.2 |
| 55–56 | 6.2 | HEADERS on stream 0: PROTOCOL_ERROR | H2 › "HEADERS on stream 0 is a PROTOCOL_ERROR"; h2spec §6.2 |
| 57 | 6.2 | HEADERS padding ≥ payload: PROTOCOL_ERROR | H2A › "a padded frame with an empty payload is a PROTOCOL_ERROR"; h2spec §6.2 |
| 58 | 6.3 | PRIORITY on stream 0: PROTOCOL_ERROR | H2 › "PRIORITY on stream 0 is a PROTOCOL_ERROR"; h2spec §6.3 |
| 59 | 6.3 | PRIORITY not 5 octets: stream FRAME_SIZE_ERROR | H2 › "PRIORITY of four octets is a stream FRAME_SIZE_ERROR"; h2spec §6.3 |
| 60 | 6.4 | after a peer's RST_STREAM, send nothing on it | H2 › "an answer on a stream that is gone writes nothing"; H2 › "a reset request is dropped before anything answers it" |
| 61 | 6.4 | after our RST_STREAM, take late frames | H2 › "frames in flight to a stream this end reset are ignored"; H2A › "a refusal sent while the body flows ignores the DATA the client had in flight" |
| 62–63 | 6.4 | RST_STREAM on stream 0: PROTOCOL_ERROR | H2 › "RST_STREAM on stream 0 is a PROTOCOL_ERROR"; h2spec §6.4 |
| 64 | 6.4 | never RST_STREAM an idle stream | gap `avra-8sb5.1.30.19` |
| 65 | 6.4 | RST_STREAM on an idle stream: PROTOCOL_ERROR | H2 › "RST_STREAM on an idle stream is a PROTOCOL_ERROR"; h2spec §5.1, §6.4 |
| 66 | 6.4 | RST_STREAM not 4 octets: FRAME_SIZE_ERROR | H2 › "RST_STREAM of three octets is a FRAME_SIZE_ERROR"; h2spec §6.4 |
| 67 | 6.5 | both ends send SETTINGS at the start | H2 › "the server owes its SETTINGS before it reads a byte: 100 streams, the 1.1 head as the list bound"; h2spec §3.5 |
| 68 | 6.5 | every defined setting supported | H2 › "the peer's settings are held"; h2spec §6.5.2 |
| 69–70 | 6.5 | SETTINGS ACK with a payload: FRAME_SIZE_ERROR | H2 › "an ACK with a payload is a FRAME_SIZE_ERROR"; h2spec §6.5 |
| 71–72 | 6.5 | SETTINGS on a stream: PROTOCOL_ERROR | H2 › "SETTINGS on a stream is a PROTOCOL_ERROR"; h2spec §6.5 |
| 73 | 6.5 | badly formed SETTINGS: PROTOCOL_ERROR | H2 › "ENABLE_PUSH other than 0 or 1 is a PROTOCOL_ERROR"; H2 › "a frame size outside 2^14 .. 2^24-1 is a PROTOCOL_ERROR" |
| 74 | 6.5 | SETTINGS length not ×6: FRAME_SIZE_ERROR | H2 › "a length that is not a multiple of six is a FRAME_SIZE_ERROR"; h2spec §6.5 |
| 75 | 6.5.2 | no PUSH_PROMISE when the client disables push | N/A (push is never sent) |
| 76 | 6.5.2 | client refuses PUSH_PROMISE after disabling push | N/A (no HTTP/2 client) |
| 77 | 6.5.2 | ENABLE_PUSH not 0 or 1: PROTOCOL_ERROR | H2 › "ENABLE_PUSH other than 0 or 1 is a PROTOCOL_ERROR"; h2spec §6.5.2 |
| 78–79 | 6.5.2 | a server's ENABLE_PUSH, when sent, is 0 | H2 › "the server owes its SETTINGS before it reads a byte: 100 streams, the 1.1 head as the list bound" (its payload spells ENABLE_PUSH 0) |
| 80 | 6.5.2 | client refuses ENABLE_PUSH 1 | N/A (no HTTP/2 client) |
| 81 | 6.5.2 | INITIAL_WINDOW_SIZE past 2^31-1: FLOW_CONTROL_ERROR | H2 › "an initial window past 2^31-1 is a FLOW_CONTROL_ERROR"; h2spec §6.5.2 |
| 82 | 6.5.2 | advertised MAX_FRAME_SIZE within 2^14 .. 2^24-1 | Construction — the server advertises none (the default 2^14 stands) |
| 83 | 6.5.2 | MAX_FRAME_SIZE out of range: PROTOCOL_ERROR | H2 › "a frame size outside 2^14 .. 2^24-1 is a PROTOCOL_ERROR"; h2spec §6.5.2 |
| 84 | 6.5.2 | unknown setting ignored | H2 › "an unknown setting is ignored"; h2spec §6.5.2 |
| 85 | 6.5.3 | settings applied on receipt | H2 › "the peer's settings are held"; H2 › "a window shrunk by SETTINGS below zero holds DATA until it is positive"; h2spec §6.9.2 |
| 86 | 6.5.3 | settings processed in order | h2spec §6.5.3 |
| 87 | 6.5.3 | unsupported settings ignored | H2 › "an unknown setting is ignored" |
| 88 | 6.5.3 | SETTINGS acknowledged at once | H2 › "the client's SETTINGS is acknowledged"; h2spec §6.5.3 |
| 89 | 6.6 | promised id is a valid next id | N/A (push is never sent) |
| 90 | 6.6 | PUSH_PROMISE padding zero | N/A (push is never sent) |
| 91 | 6.6 | PUSH_PROMISE without END_HEADERS: CONTINUATION follows | N/A (push is never sent) |
| 92 | 6.6 | other frame inside a PUSH_PROMISE block: PROTOCOL_ERROR | N/A (receiving a promise is a client's; the server refuses every one, row 177) |
| 93 | 6.6 | PUSH_PROMISE only on a peer's open stream | N/A (push is never sent) |
| 94 | 6.6 | PUSH_PROMISE on stream 0: PROTOCOL_ERROR | N/A (receiving a promise is a client's; row 177) |
| 95 | 6.6 | no PUSH_PROMISE when the peer disables push | N/A (push is never sent) |
| 96 | 6.6 | PUSH_PROMISE after disabling push: PROTOCOL_ERROR | N/A (receiving a promise is a client's; row 177) |
| 97 | 6.6 | PUSH_PROMISE only on open streams, valid promised id | N/A (push is never sent) |
| 98 | 6.6 | PUSH_PROMISE on a wrong-state stream: PROTOCOL_ERROR | N/A (receiving a promise is a client's; row 177) |
| 99 | 6.6 | promises raced with our RST_STREAM handled | N/A (receiving a promise is a client's; row 177) |
| 100 | 6.6 | illegal promised id: PROTOCOL_ERROR | N/A (receiving a promise is a client's; row 177) |
| 101 | 6.6 | PUSH_PROMISE padding ≥ payload: PROTOCOL_ERROR | N/A (receiving a promise is a client's; row 177) |
| 102 | 6.7 | PING carries 8 octets | H2 › "a PING of seven octets is a FRAME_SIZE_ERROR"; H2 › "a PING is answered with an ACK carrying its payload" |
| 103–104 | 6.7 | PING answered with ACK and the same payload | H2 › "a PING is answered with an ACK carrying its payload"; h2spec §6.7 |
| 105 | 6.7 | PING ACK not answered | H2 › "a PING ACK is not answered"; h2spec §6.7 |
| 106 | 6.7 | PING on a stream: PROTOCOL_ERROR | H2 › "a PING on a stream is a PROTOCOL_ERROR"; h2spec §6.7 |
| 107 | 6.7 | PING not 8 octets: FRAME_SIZE_ERROR | H2 › "a PING of seven octets is a FRAME_SIZE_ERROR"; h2spec §6.7 |
| 108 | 6.8 | after GOAWAY, open no streams | N/A (the server opens no stream) |
| 109 | 6.8 | GOAWAY on a stream: PROTOCOL_ERROR | h2spec §6.8 |
| 110 | 6.8 | GOAWAY's last stream id never raised | Construction — one GOAWAY per connection (`closing` ends all further writes of one) |
| 111 | 6.8 | after GOAWAY, field blocks still processed | Construction — after its GOAWAY the link is shut, drained and closed (`lingered`); no stream outlives it |
| 112 | 6.8 | stored debug data safeguarded | Construction — a GOAWAY's debug data is read past, never logged or stored |
| 113 | 6.9 | flow-control-exempt frames accepted | Construction — only DATA is charged to a window (`data`) |
| 114 | 6.9 | WINDOW_UPDATE of 0: PROTOCOL_ERROR | H2 › "a WINDOW_UPDATE of zero is a PROTOCOL_ERROR — on the stream or the connection"; h2spec §6.9 |
| 115 | 6.9 | WINDOW_UPDATE on half-closed/closed is no error | H2 › "an answer past the window sends what fits and owes the rest until WINDOW_UPDATE" (half-closed remote); closed: Construction (`window_update` ignores it) |
| 116 | 6.9 | every DATA charged to the connection window | H2 › "a POST's DATA is its body, charged to the connection's window"; H2A › "a flood of one-octet DATA nobody reads earns one connection WINDOW_UPDATE per half window and none on the stream" |
| 117 | 6.9 | WINDOW_UPDATE not 4 octets: FRAME_SIZE_ERROR | H2 › "a WINDOW_UPDATE of five octets is a FRAME_SIZE_ERROR"; h2spec §6.9 |
| 118 | 6.9.1 | never send past either window | H2 › "an answer past the window sends what fits and owes the rest until WINDOW_UPDATE"; h2_stream › "uploaded 4194304 octets: 4194304 octets read, no piece past a window: true"; h2spec §6.9.1 |
| 119–120 | 6.9.1 | window past 2^31-1: FLOW_CONTROL_ERROR | H2 › "a WINDOW_UPDATE past 2^31-1 is a FLOW_CONTROL_ERROR — on the stream or the connection"; h2spec §6.9.1 |
| 121 | 6.9.2 | INITIAL_WINDOW_SIZE change shifts every stream window | H2 › "a window shrunk by SETTINGS below zero holds DATA until it is positive"; h2spec §6.9.2 |
| 122 | 6.9.2 | negative window tracked; no DATA until positive | H2 › "a window shrunk by SETTINGS below zero holds DATA until it is positive"; h2spec §6.9.2 |
| 123 | 6.9.2 | change overflowing a window: FLOW_CONTROL_ERROR | H2 › "an initial window past 2^31-1 is a FLOW_CONTROL_ERROR"; h2spec §6.9.2 |
| 124 | 6.9.3 | receive DATA past a lowered window | Construction — the server never lowers its initial window (the default 65535 stands) |
| 125 | 6.10 | CONTINUATION without END_HEADERS: another follows | H2 › "an answer's head past the frame size continues in CONTINUATIONs" |
| 126 | 6.10 | other frame inside a block: PROTOCOL_ERROR | H2 › "any other frame inside a header block is a PROTOCOL_ERROR"; H2 › "a CONTINUATION on another stream is a PROTOCOL_ERROR"; h2spec §6.10 |
| 127–128 | 6.10 | CONTINUATION on stream 0: PROTOCOL_ERROR | h2spec §6.10 |
| 129–130 | 6.10 | CONTINUATION without an open block: PROTOCOL_ERROR | H2 › "a CONTINUATION with no header block open is a PROTOCOL_ERROR"; h2spec §6.10 |
| 131 | 7 | unknown error codes trigger nothing | h2spec §7 |
| 132 | 8.1 | no frame between HEADERS and its CONTINUATIONs | H2 › "an answer's head past the frame size continues in CONTINUATIONs" |
| 133 | 8.1 | trailers carry no pseudo-field (sender) | Construction — the server sends no trailers |
| 134 | 8.1 | pseudo-field in trailers: malformed | H2 › "trailers that do not end the stream, or carry a pseudo-field, reset it"; h2spec §8.1.2.1 |
| 135 | 8.1 | second HEADERS without END_STREAM: malformed | H2 › "trailers that do not end the stream, or carry a pseudo-field, reset it"; h2spec §8.1 |
| 136 | 8.1 | client keeps a response despite RST_STREAM NO_ERROR | N/A (no HTTP/2 client) |
| 137 | 8.1.1 | intermediary forwards nothing malformed | N/A |
| 138 | 8.1.1 | malformed message: stream PROTOCOL_ERROR | H2 › "a malformed head resets its stream with PROTOCOL_ERROR"; H2 › "a body shorter or longer than its content-length resets the stream"; h2spec §8.1.2.6 |
| 139 | 8.1.1 | client refuses a malformed response | N/A (no HTTP/2 client) |
| 140 | 8.2 | field names lowercased when sent | H2S › "a text answer is :status, its fields lowercased, its length, then its body"; H2S › "folding lowercases ASCII letters alone" |
| 141–142 | 8.2.1 | name holds no CTL, SP, uppercase or high octet | H2 › "an uppercase name, a connection field, or te other than trailers is malformed"; h2spec §8.1.2 |
| 143 | 8.2.1 | no colon in a regular name | H2 › "a pseudo-field after a regular one, or an unknown one, is malformed" |
| 144 | 8.2.1 | value holds no NUL, LF or CR | H2 › "a value with a CR, a NUL, or a space at an end is malformed" |
| 145 | 8.2.1 | value has no leading or trailing SP/HTAB | H2 › "a value with a CR, a NUL, or a space at an end is malformed" |
| 146 | 8.2.1 | a bad field makes the message malformed | H2 › "a malformed head resets its stream with PROTOCOL_ERROR" |
| 147 | 8.2.1 | non-processing intermediary drops bad fields | N/A |
| 148 | 8.2.2 | no connection-specific field sent | H2S › "a connection-scoped field is dropped; one no wire could carry is the server's 500" |
| 149 | 8.2.2 | connection-specific field: malformed | H2 › "an uppercase name, a connection field, or te other than trailers is malformed"; h2spec §8.1.2.2 |
| 150 | 8.2.2 | TE only `trailers` | H2 › "an uppercase name, a connection field, or te other than trailers is malformed"; h2spec §8.1.2.2 |
| 151 | 8.2.2 | 1.x→2 intermediary strips connection fields | N/A |
| 152 | 8.2.3 | Cookie crumbs joined with `; ` | H2S › "cookie crumbs are joined into one field (§8.2.3)"; h2c_serve › "GET /who: 200 \| text/plain; charset=utf-8 \| nobody at h cookie a=1; b=2" |
| 153 | 8.3 | only defined pseudo-fields generated | H2S › "a text answer is :status, its fields lowercased, its length, then its body" |
| 154 | 8.3 | request/response pseudo-fields stay on their side | H2 › "a pseudo-field after a regular one, or an unknown one, is malformed" (`:status` in a request); h2spec §8.1.2.1 |
| 155 | 8.3 | no pseudo-field in trailers (sender) | Construction — the server sends no trailers |
| 156 | 8.3 | undefined or invalid pseudo-field: malformed | H2 › "a pseudo-field after a regular one, or an unknown one, is malformed"; H2S › "a pseudo-field value outside its grammar is malformed before any head is spelled"; h2spec §8.1.2.1 |
| 157 | 8.3 | pseudo-fields before regular fields (sender) | H2S › "a text answer is :status, its fields lowercased, its length, then its body" |
| 158 | 8.3 | pseudo-field after a regular one: malformed | H2 › "a pseudo-field after a regular one, or an unknown one, is malformed"; h2spec §8.1.2.1 |
| 159 | 8.3 | no pseudo-field repeated (sender) | Construction — `answered_on` writes one `:status` |
| 160 | 8.3 | repeated pseudo-field: malformed | H2 › "a missing, empty or doubled pseudo-field is malformed"; h2spec §8.1.2.3 |
| 161 | 8.3.1 | Host ignored for the target when `:authority` present | gap `avra-8sb5.1.30.20` — H2S › "a host field the request sent wins over the authority" pins the opposite |
| 162 | 8.3.1 | client conveys authority in `:authority` | N/A (no HTTP/2 client) |
| 163 | 8.3.1 | client's Host equals `:authority` | N/A (no HTTP/2 client) |
| 164 | 8.3.1 | non-origin servers normalize Host/`:authority` | N/A (an origin server may apply any normalization) |
| 165–166 | 8.3.1 | intermediary builds `:authority` / Host | N/A |
| 167 | 8.3.1 | `:authority` has no userinfo (sender) | N/A (no HTTP/2 client) |
| 168 | 8.3.1 | `:path` non-empty for http(s) | H2 › "a missing, empty or doubled pseudo-field is malformed" (receipt); h2spec §8.1.2.3 |
| 169 | 8.3.1 | server-wide OPTIONS sends `:path` `*` | N/A (no HTTP/2 client) |
| 170 | 8.3.1 | exactly one `:method`, `:scheme`, `:path` | H2 › "a missing, empty or doubled pseudo-field is malformed"; h2spec §8.1.2.3 |
| 171 | 8.3.2 | every response carries `:status` | H2S › "a text answer is :status, its fields lowercased, its length, then its body"; h2_stream_laws › "an interim status: 500  / then 200 hello" |
| 172 | 8.4 | promised requests safe and cacheable | N/A (push is never sent) |
| 173 | 8.4 | client resets an unsafe or bodied promise | N/A (no HTTP/2 client) |
| 174 | 8.4 | uncacheable pushes not stored | N/A (cache) |
| 175 | 8.4 | pushed `:authority` is one we are authoritative for | N/A (push is never sent) |
| 176 | 8.4 | client refuses an unauthoritative push | N/A (no HTTP/2 client) |
| 177 | 8.4 | server: PUSH_PROMISE received is PROTOCOL_ERROR | H2 › "a PUSH_PROMISE from a client is a PROTOCOL_ERROR"; h2spec §8.2 |
| 178 | 8.4.1 | promise carries a full request head | N/A (push is never sent) |
| 179 | 8.4.1 | promised `:method` safe and cacheable | N/A (push is never sent) |
| 180 | 8.4.1 | client rejects an incomplete or unsafe promise | N/A (no HTTP/2 client) |
| 181 | 8.4.1 | clients send no PUSH_PROMISE | N/A (no HTTP/2 client; receipt is row 177) |
| 182 | 8.4.1 | push only on an open client stream | N/A (push is never sent) |
| 183 | 8.4.2 | client validates pushed authority | N/A (no HTTP/2 client) |
| 184 | 8.5 | CONNECT omits `:scheme` and `:path` | H2 › "CONNECT takes an authority and neither a scheme nor a path"; H2S › "CONNECT's target is its authority" |
| 185 | 8.5 | tunnel stream carries DATA and management frames only | N/A (no tunnel is opened; CONNECT reaches the handler as a request) |
| 186 | 8.5 | proxy resets TCP on a tunnel error | N/A |
| 187 | 8.7 | "not processed" claimed only when guaranteed | H2 › "a stream past the concurrency bound is REFUSED_STREAM" (refused before the stream opens) |
| 188 | 8.7 | no REFUSED_STREAM after processing; GOAWAY id covers processed streams | Construction — REFUSED_STREAM only for a stream never opened (`opened`); GOAWAY names the highest stream the peer opened (`last`) |
| 189 | 9.1.1 | reused connection's certificate passes the client's checks | N/A (no HTTP/2 client) |
| 190 | 9.2 | TLS 1.2 or higher | Construction — `mbedtls_ssl_conf_min_tls_version(…, TLS1_2)` (std_tls.c) |
| 191 | 9.2 | TLS supports SNI | TC › "SNI for localhost is answered by the localhost leaf"; TC › "SNI for a name under the wildcard is answered through its intermediate" |
| 192 | 9.2 | client sends server_name | N/A (no HTTP/2 client) |
| 193 | 9.2.1 | TLS 1.2 compression disabled | Construction — mbedTLS carries no TLS compression |
| 194 | 9.2.1 | TLS 1.2 renegotiation disabled | Construction — std_tls.c refuses to build with `MBEDTLS_SSL_RENEGOTIATION` |
| 195 | 9.2.1 | renegotiation: connection PROTOCOL_ERROR | gap `avra-8sb5.1.30.21` |
| 196 | 9.2.1 | renegotiation only before the preface | Construction — renegotiation is compiled out |
| 197 | 9.2.1 | DHE ≥ 2048 bits, ECDHE ≥ 224 bits | Construction — no finite-field DHE suite is compiled; the curves are 255 bits and up (std_tls_crypto_config.h) |
| 198 | 9.2.1 | clients accept DHE up to 4096 bits | N/A (no HTTP/2 client) |
| 199 | 9.2.2 | INADEQUATE_SECURITY not raised for allowed suites | Construction — INADEQUATE_SECURITY is never sent |
| 200 | 9.2.2 | TLS 1.2 supports ECDHE_RSA_AES_128_GCM_SHA256 on P-256 | Construction — ECDHE-RSA, AES, GCM, SHA-256 and secp256r1 are compiled in (std_tls_ssl_config.h, std_tls_crypto_config.h) |
| 201 | 9.2.3 | server sends no post-handshake CertificateRequest | Construction — mbedTLS implements no post-handshake authentication |
| 202 | 9.2.3 | client refuses a post-handshake CertificateRequest | N/A (no HTTP/2 client) |
| 203–204 | 10.3 | translating intermediary validates and strips fields | N/A |
| 205 | 10.4 | tenants push only what they own | N/A (push is never sent) |
| 206 | 10.4 | unauthoritative pushes not used or cached | N/A (no HTTP/2 client) |
| 207 | 10.5.1 | every field block processed for table state | H2A › "a block on a stream past the concurrency bound still moves the table"; H2A › "a block on a stream the peer already ended still moves the table"; H2A › "a malformed head still moves the table"; HPA › "a too-large block still moves the table, so the next block reads it" |
| 208–209 | 10.6 | no shared compression of secret and attacker data | gap `avra-8sb5.1.30.22` |
| 210 | 10.6 | no generic stream (TLS) compression | Construction — mbedTLS carries no TLS compression |

### Gaps found

- **2** (§3.2) — the ALPN list is the caller's (`offering`), and nothing refuses `h2c` in it, so a server can be configured to select it over TLS.
- **4** (§3.3) — a TLS link whose ALPN did not agree `h2` still turns HTTP/2 on a preface (`conversed` asks `opens_h2` whatever was negotiated).
- **37** (§5.2.2) — a handler's run holds its connection: PING, SETTINGS and WINDOW_UPDATE wait until it answers, unless it is reading its own body.
- **64** (§6.4) — a zero-increment WINDOW_UPDATE on an idle stream is answered RST_STREAM (the increment is judged before the stream's state), as is a malformed or self-dependent PRIORITY on one (§6.3's stream error meets §6.4 here).
- **161** (§8.3.1) — `head_text` keeps a sent `host` over `:authority`; the 1.1 head's Host must come from `:authority` when present.
- **195** (§9.2.1) — renegotiation is refused at the TLS layer (compiled out), but the HTTP/2 connection is not ended with PROTOCOL_ERROR.
- **208–209** (§10.6) — every answer field enters one HPACK dynamic table; none is marked never-indexed (`set-cookie`, `authorization` included), so a secret and a reflected value share a compression context.

Deliberate deviation: h2spec §3.5's invalid-preface case fails on the clear
port only, where HTTP/1.1 and h2c share a listener — octets that are not the
preface are a 1.1 request and are answered 400. Over TLS it passes (row 9).
