# HTTP conformance checklist — RFC 9112 and RFC 9110 against @std/http

Every MUST / MUST NOT of [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html)
and the server-relevant ones of [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html),
each with the fixture that pins it or the ticket that owns the gap. Sentences
were extracted mechanically from the RFC text (87 MUSTs in 9112, all here).
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

Role words: **N/A** — the requirement binds a role @std/http does not play
(proxy, intermediary, cache, registry). **Handler** — it binds a response only
an application can build (a 401's challenge, a PUT's 201); the library neither
writes nor forbids it. A gap is a ticket under `avra-8sb5.1.30`.

## Deliberate deviations (legal, and chosen)

- Every widening MAY is refused (the framing laws): bare LF, obs-fold, `SP SP`.
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
| 12 | 3.2 | client's Host equals the URI authority minus userinfo | gap `avra-8sb5.1.30.8` |
| 13 | 3.2 | client sends an empty Host when the URI has no authority | gap `avra-8sb5.1.30.8` |
| 14 | 3.2 | server: 400 for a missing, repeated or invalid Host | F › "1.1 needs exactly one valid Host; 1.0 needs none"; C › given "the host law" (12 rows) |
| 15 | 3.2.1 | client sends only path and query to an origin | gap `avra-8sb5.1.30.8` |
| 16 | 3.2.1 | client sends `/` for an empty path | gap `avra-8sb5.1.30.8` |
| 17 | 3.2.2 | client to a proxy sends absolute-form | N/A (the client speaks to no proxy) |
| 18 | 3.2.2 | client sends Host beside absolute-form | CA › "a plain request frames with its host alone" (Host is always written) |
| 19–20 | 3.2.2 | proxy replaces Host from absolute-form | N/A |
| 21 | 3.2.2 | origin ignores Host for absolute-form, uses the target's host | T › "absolute-form hands it over"; T › "origin-form and absolute-form reach the SAME route" |
| 22 | 3.2.2 | server accepts absolute-form | F › "absolute-form is accepted" |
| 23 | 3.2.3 | client CONNECT sends host:port only | N/A (the client sends no CONNECT) |
| 24 | 3.2.4 | client server-wide OPTIONS sends `*` | N/A (the caller's target is written as given) |
| 25 | 3.2.4 | last proxy rewrites to `*` | N/A |
| 26 | 4 | server sends the SP before an absent reason | C › "an unregistered status carries its class's reason after the space" (a reason is never absent) |
| 27 | 5.1 | server: 400 for whitespace between name and colon | F › "space before the colon or an empty name refuses; OWS around a value is not the value" |
| 28 | 5.1 | proxy strips it from responses | N/A |
| 29 | 5.2 | sender generates no obs-fold | H › "A CRLF IN A VALUE IS NOT A SECOND FIELD" |
| 30 | 5.2 | server: obs-fold is 400 (or SP) | F › "obs-fold and a whitespace-led first line refuse"; FA › "OBS-FOLD IS NOT A CONTINUATION, it is a line with no name" |
| 31 | 5.2 | proxy: obs-fold response is 502 | N/A |
| 32 | 5.2 | UA replaces an obs-fold in a response with SP | gap `avra-8sb5.1.30.6` |
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
| 50 | 6.3 | UA: invalid CL response — close and discard | CA › "a reply the framer refuses is an error naming the law" (discard); close: gap `avra-8sb5.1.30.7` |
| 51 | 6.3 | a body cut short is incomplete; close | C › "a body cut short by the peer's close is not answered, and the connection closes"; SA › "a peer gone mid-head is dropped"; CA › "a body cut short by the close is an error" |
| 52 | 6.3 | UA request with a body sends a valid CL | CA › "a body earns a length, which the server reads" |
| 53 | 6.3 | client sends chunked only to a 1.1 server | CA › "and a transfer-encoding beside a length is the smuggling shape" |
| 54 | 6.3 | client never treats extra data as a response | gap `avra-8sb5.1.30.9` |
| 55 | 7.1 | recipient decodes chunked | as row 33 |
| 56 | 7.1 | large hex sizes never overflow | F › "seventeen digits refuse and sixteen past the body bound are 413" |
| 57 | 7.1.1 | unrecognized chunk extensions are ignored | F › "extensions are ignored"; C › "bad whitespace before a chunk extension is dropped" |
| 58 | 7.1.2 | a retained trailer is kept apart or merged | F › "trailers are parsed and dropped, framing unchanged" (none is retained) |
| 59 | 7.1.2 | a trailer is never merged into the head | F › "trailers are parsed and dropped, framing unchanged" |
| 60–62 | 7.3 | transfer-coding registrations | N/A |
| 63 | 7.4 | client sends no `chunked` in TE | gap `avra-8sb5.1.30.10` |
| 64 | 7.4 | a TE sender lists TE in Connection | gap `avra-8sb5.1.30.10` |
| 65 | 8 | client records an incomplete response | CA › "a body cut short by the close is an error" |
| 66 | 9.2 | client keeps outstanding requests in order | N/A (the client never pipelines) |
| 67 | 9.2 | data with no request outstanding is not a response | gap `avra-8sb5.1.30.9` |
| 68 | 9.3 | a client without persistence sends close | N/A (the client persists) |
| 69 | 9.3 | a server without persistence sends close | N/A (the server persists) |
| 70 | 9.3 | server reads the whole body or closes | C › "a body is read whole before the request behind it, and both answer in order"; SA › "a body past its bound is 413 and the connection closes" |
| 71 | 9.3 | client reads the whole body before reuse | CA › "two replies ride one connection" |
| 72 | 9.3 | proxy keeps no persistence with 1.0 | N/A |
| 73 | 9.3.2 | pipelined responses in request order | S › "two pipelined requests are answered in order" |
| 74 | 9.3.2 | client does not pipeline a retried connection | N/A (the client never pipelines) |
| 75 | 9.6 | client that sent close sends no more | gap `avra-8sb5.1.30.10` |
| 76–77 | 9.6 | server receiving close: close after responding, process nothing more | S › "connection: close is honoured"; C › "a request pipelined behind connection: close is never processed" |
| 78–79 | 9.6 | server sending close: close, process nothing more | SA › "the last permitted request carries connection: close"; S › "a refused head is answered 400 and the connection closed" |
| 80 | 9.6 | client receiving close ceases sending | gap `avra-8sb5.1.30.10` |
| 81 | 9.7 | HTTP over TLS is application data | gap `avra-8sb5.1.30.11` (TLS lane, H2) |
| 82–83 | 9.8 | closure alerts before close | gap `avra-8sb5.1.30.11` |
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
| 34–35 | 5.6.7 | generate HTTP-dates as IMF-fixdate | gap `avra-8sb5.1.30.4` (no date is generated yet) |
| 39 | 6.2 | send only a version one conforms to | S › "a GET is answered exactly, and the handler saw its state" (`HTTP/1.1`) |
| 40 | 6.5.1 | generate no trailer unless permitted | nothing is sent chunked, so no trailer is generated |
| 41 | 6.5.1 | never merge a trailer into the head | F › "trailers are parsed and dropped, framing unchanged" |
| 43 | 6.6.1 | an origin with a clock sends Date in 2xx–4xx | gap `avra-8sb5.1.30.4`; pinned by C › "KNOWN GAP avra-8sb5.1.30.4: no Date field is written (RFC 9110 §6.6.1) — flips when it lands" |
| 46 | 7.1 | authority-form and `*` with their methods only | F › "authority-form is CONNECT's and the asterisk is OPTIONS'" |
| 48–49 | 7.4 | reject a target whose scheme's requirements fail (https over plain) | gap `avra-8sb5.1.30.12`; pinned by T › "the scheme is not the axis — https and an unregistered one route alike" |
| 54 | 7.6.1 | no connection option for an end-to-end field | H › "a handler's connection contradicts the fate the writer speaks" |
| 64–70 | 7.8 | Upgrade: 101 and 426 carry it, `upgrade` listed in Connection, 1.0 ignored, 100 before 101 | gap `avra-8sb5.1.30.13`; today no 1xx is sendable: C › "a 1xx is interim, never an answer, so it is not sendable" |
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
| 166 | 15.2 | client parses 1xx before the final reply | gap `avra-8sb5.1.30.5` |
| 168, 189 | 15.2.2, 15.5.22 | 101 and 426 carry Upgrade | gap `avra-8sb5.1.30.13` |
| 169 | 15.3.6 | no content in a 205 | C › "a 205 carrying content is not sendable" |
| — | 15.3.5, 15.4.5 | no content in a 204 or 304 (the body rule behind rows 74–75) | C › "a 204 carrying content is not sendable"; C › "a 304 carrying content is not sendable"; C › "and each goes out as the server's own 500" |

The rest, by role (9110 extraction numbers):

- **Client or user agent** — 11–19 (TLS identity: H2, `avra-8sb5.1.25`),
  7, 9 and 12 (an empty host, userinfo: `avra-8sb5.1.30.8`), 37–38, 47, 94, 100–104, 110–114
  (113: `avra-8sb5.1.30.10`), 117, 126, 145, 148–149, 160, 164, 170, 178–182,
  184 (redirects: H5, `avra-8sb5.1.28`).
- **Handler** — 3, 5–6, 27, 32–33, 36, 44–45, 52, 71–72 (encodings and
  multipart: H6, `avra-8sb5.1.29`), 80–85, 87, 90–93, 115 and 186 (a 405
  writes Allow — the router answers 404, never 405), 118–120, 124–125,
  129–144, 150–152, 154, 156–157, 161, 163, 171–177, 183, 185.
- **Proxy, intermediary, cache, gateway** — 20–21, 50–51, 53, 55–63, 78–79,
  88, 96, 99, 116, 121–123, 127–128, 167, 187–188.
- **Registries and BCP 14** — 1, 42, 190–201.
