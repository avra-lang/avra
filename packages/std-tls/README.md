# @std/tls

TLS 1.2 and 1.3, client and server, over memory: a `Session` is fed the
peer's ciphertext and drained of its own, so it runs over any wire.

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
