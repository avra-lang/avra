# @std/tls

TLS 1.2 and 1.3, client and server. `TlsConn` wears `@std.net`'s `Conn`
verbs — `read`, `write`, `shutdown_write`, `close`, `peer`, `fd` — each
parking the calling task exactly where `Conn`'s own verb would, so a
caller written for one transport reads the other. Under it a `Config`
is one side of a service and a `Session` is one connection's engine,
touching no socket: the peer's ciphertext is `fed` in and its own
`outgoing` drained out, so TLS runs over any wire.

```avra
use @std.tls.{TlsError, client_config, dial}
use @std.time.{secs}

fn online(host: string) -> Result<int, TlsError> {
    let cfg = client_config()?
    let c = dial(host, 443, secs(5), cfg)?
    c.write("GET / HTTP/1.1\r\nHost: ${host}\r\n\r\n".bytes())
}
```

## Surface

All of it is in `src/tls.av`, imported as `@std.tls`.

| Export | What it is |
|---|---|
| `TlsError` | Why a TLS verb failed: `Engine(verb, subject, code)`, `Net(e)`, `Cut(verb, subject)` (the peer hung up without close_notify), `Unanchored(why)`, `Untrusted(host, why)`. Implements `Error`; `timed_out()` and `cause()`. |
| `Side` | Which end of a handshake a config serves: `Client`, `Server`. |
| `Config` | One side of a service: its trust anchors, identities, verification and protocols. Sessions borrow it; it is freed only once they have ended. |
| `Step` | What a handshake step needs next: `Done`, `Reading`. |
| `Opened` | What a receive found: `Data(b)`, `Reading`, `Closed`. |
| `Session` | One connection's engine over memory, touching no socket. |
| `TlsConn` | A TLS stream over a `Conn`, wearing `Conn`'s verbs. |
| `wired(r)` | A net result as TLS's: the failure wears `.Net`. |
| `client_config()` | A verifying client config against the system trust anchors (`roots_path`); resumes the last session per host. |
| `anchored(pem)` | A verifying client config trusting the authorities in `pem` and no other — a private CA, or a test's. |
| `roots_path()` | The bundle a client reads: `SSL_CERT_FILE`, else the first usual platform bundle present, else null. |
| `server_config()` | A server config: presenting nothing until an identity is added, issuing resumption tickets. |
| `session(config, host)` | A session under `config`; a client names the host it expects, a server passes `""`. |
| `dial(host, port, timeout, config)` | Connect and handshake within `timeout`; `host` is the name the certificate must carry. |
| `handshake(conn, config, host)` | Make a `TlsConn` over an already-connected `Conn`. |
| `handshake_after(conn, config, host, heard)` | The same, when the first flight was already read off the wire. |

Methods:

| Method | What it does |
|---|---|
| `Config.trusting(pem)` | Add trust anchors from PEM; answers how many the text held. Text holding none this build can read is refused. |
| `Config.presenting(chain, key)` | A certificate chain (leaf first) and its private key, from PEM; a key that is not the leaf's is refused. |
| `Config.unverified()` | Take the peer's certificate on trust — no chain, no name. For a throwaway certificate; never the default. |
| `Config.offering(protocols)` | Application protocols, most preferred first; a server insists a peer offer one of its own. |
| `Config.resumed()` | How many connections a server has resumed from its tickets. |
| `Config.free()` | Return the config's handle to the engine — refused while a session made from it has not ended. |
| `Session.fed(b)` | Queue the peer's ciphertext for the engine. |
| `Session.step()` | One handshake step: `.Done`, or `.Reading` when the peer's next flight is needed. |
| `Session.outgoing()` | Take every byte of ciphertext owed to the peer. |
| `Session.sealed(b, from)` | Seal plaintext for the peer, one record at most; answers how many bytes it took. |
| `Session.opened(max)` | Plaintext from the peer, up to `max`: `.Reading` for a partial record, `.Closed` at close_notify. |
| `Session.closing()` | Queue close_notify for the peer. |
| `Session.version()` / `Session.protocol()` | The settled version (`0x0303` TLS 1.2, `0x0304` TLS 1.3) / the agreed application protocol, or null. |
| `Session.end()` / `Session.named()` / `Session.distrust()` | Return the engine's state / the session's name for a refusal / why the certificate was not trusted. |
| `TlsConn.read(max)` / `write(bytes)` | Bytes from the peer, or null at close_notify / all of `bytes`. |
| `TlsConn.shutdown_write()` / `close()` | Half-close (the peer's close_notify still to come) / close the socket. |
| `TlsConn.peer()` / `version()` / `protocol()` | The peer's address / the settled version / the agreed protocol. |

## Verification is on by default

`client_config()` checks the peer's chain against the system's trust
anchors and the host it named; `anchored(pem)` against a private
authority instead. A refusal names its reason (`.Untrusted(host, why)`,
`.Unanchored(why)`). `unverified()` is the one way off, named for what
it gives up. A peer that hangs up without close_notify reads `.Cut`,
never an ordinary end: the stream may have been truncated.

## Certificates and keys

Both sides load PEM as `Bytes`: a client its trust anchors
(`trusting`, `anchored`), a server its identity (`presenting(chain,
key)`). A server holding several identities answers each client's SNI
with the first whose leaf names that host — a `*.` name covering exactly
one label — and a client naming no host, or one no leaf names, gets the
first. A client names the host in `session`/`dial`: it is the SNI sent
*and* the name the certificate must carry.

## The C boundary

- **Borrowed in.** Every `Bytes` handed to the engine is borrowed for
  the call, never kept: PEM is copied into an engine structure, and a
  session reads and writes the buffers it was given.
- **Adopted out.** An answer the engine points at (a protocol name,
  verification words, received plaintext) is copied into a value of
  ours with `avra_bytes_adopted` after its pointer and length are
  tested — never `!`, which would read a header a foreign pointer does
  not have.
- **The NUL guard.** A name crossing to mbedTLS is read by its length,
  and one holding a NUL is refused (`TLS_ERR_HOST`): to a C string it
  would mean a prefix of itself. ALPN names must be 1..255 bytes with
  no NUL, eight at most. PEM text is copied with the terminator mbedTLS
  demands. The guard is at the row that hands C the pointer, not in
  every caller.
- **Lifetime.** A `Config` lives in the runtime's handle table; sessions
  borrow it, so `free` is refused until every session made from it has
  ended.

## The vendored engine

- **mbedTLS 4.1.1**, the 4.1 LTS (supported to March 2029), Apache-2.0
  (`vendor/mbedtls/LICENSE`).
- Source: `https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-4.1.1/mbedtls-4.1.1.tar.bz2`
- sha256: `3359a349e23db3d5536fcee032ae7b2ecbfc08972fab643089b5cbf2a375c98c`,
  the value in the upstream release notes.
- `vendor/import.sh <tarball>` makes `vendor/` from the tarball and
  nothing else; upgrading is re-running it.
- The X25519 key agreement is Everest's formally verified HACL* code,
  shipped in the same tarball (Apache-2.0 only, which is how the engine
  is taken): `tools/bench/handshake` measures what it buys.

Each upstream unit compiles as its own object through a one-line
wrapper (`vendor/mbedtls_<unit>.c`), and the objects are archived as
`build/mbedtls.a`. The mechanisms compiled in are exactly the two
config headers in `src/c/`. Why mbedTLS, with the numbers:
`docs/2026_09_29_HTTP_ROADMAP.md`, "H2 decision: TLS library".
