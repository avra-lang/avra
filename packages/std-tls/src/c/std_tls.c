/* @std/tls's own C: TLS sessions over MEMORY. mbedTLS reads the
   ciphertext Avra fed and writes the ciphertext Avra drains; no socket
   is touched here, so the handshake parks wherever Avra's reads and
   writes park. Every entry point answers an int or a pointer: a handle,
   a count, or a NEGATIVE code — mbedTLS's own, or one of TLS_ERR_*
   below, which sit outside mbedTLS's range. Bytes leave through
   (pointer, length) pairs the caller adopts before its next call.  */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "mbedtls/ssl.h"
#include "mbedtls/ssl_ticket.h"
#include "mbedtls/x509_crt.h"
#include "mbedtls/pk.h"
#include "mbedtls/error.h"
#include "psa/crypto.h"

/* Mechanisms this package promises are absent, held at compile time:
   a config that turns one on does not build. */
#if defined(MBEDTLS_SSL_RENEGOTIATION)
#error "renegotiation is compiled out of @std/tls: a peer may not restart the handshake"
#endif
#if defined(MBEDTLS_SSL_PROTO_DTLS)
#error "@std/tls is TLS over a stream; DTLS is compiled out"
#endif
#if !defined(MBEDTLS_SSL_EXTENDED_MASTER_SECRET)
#error "TLS 1.2 sessions in @std/tls bind the master secret to the handshake (RFC 7627)"
#endif

/* mbedTLS codes are -0x0001..-0x7FFF; ours sit below them. */
enum {
    TLS_ERR_HANDLE = -0x10001, /* a handle that names nothing live */
    TLS_ERR_MEMORY = -0x10002, /* an allocation failed */
    TLS_ERR_BOUNDS = -0x10003, /* a range outside the value it names */
    TLS_ERR_FULL = -0x10004,   /* fed ciphertext past the session's cap */
    TLS_ERR_CRYPTO = -0x10005, /* the PSA core would not start */
    TLS_ERR_EMPTY = -0x10006,  /* a PEM holding no certificate */
    TLS_ERR_HOST = -0x10007,   /* a host name holding a NUL */
    TLS_ERR_KEY = -0x10008,    /* PEM holding no private key */
    TLS_ERR_PAIR = -0x10009,   /* a key that is not its certificate's */
    TLS_ERR_BUSY = -0x1000a,   /* a config freed under a live session */
    TLS_ERR_NAMELESS = -0x1000b, /* a verifying client naming no host */
    TLS_ERR_PROTOCOL = -0x1000c, /* an ALPN name empty, too long, holding a NUL, or one too many */
    TLS_ERR_CHAIN = -0x1000d,  /* a chain larger than a handshake message holds */
    TLS_ERR_CLEARTEXT = -0x1000e, /* an ALPN name TLS never agrees */
    TLS_ERR_RENEGOTIATION = -0x1000f, /* the peer asked to renegotiate */
};

/* Fed ciphertext is bounded: a peer that sends faster than records are
   read is refused, never buffered without end. A receive lands at most
   one record's plaintext. */
enum { TLS_IN_CAP = 1 << 20, TLS_PLAIN_CAP = 1 << 14 };

/* ── Handles ─────────────────────────────────────────────────────
   A handle is a slot and the generation it was issued under, so a
   freed handle never names the slot's next tenant, and no handle is
   0. Freed slots are stacked and reused first.  */

enum { TLS_SLOTS = 1 << 16 };

typedef struct {
    void* live[TLS_SLOTS];
    uint32_t gen[TLS_SLOTS];
    int32_t spare[TLS_SLOTS];
    int64_t used, spares;
} Table;

static int64_t handle_of(Table* t, void* p) {
    int64_t i;
    if (t->spares) {
        i = t->spare[--t->spares];
    } else if (t->used < TLS_SLOTS) {
        i = t->used++;
        t->gen[i] = 1;
    } else {
        return TLS_ERR_MEMORY;
    }
    t->live[i] = p;
    return ((int64_t)t->gen[i] << 16) | i;
}

static void* held(Table* t, int64_t h) {
    int64_t i = h & 0xffff;
    if (h < 0 || i >= t->used || t->gen[i] != (uint32_t)(h >> 16)) return NULL;
    return t->live[i];
}

static void released(Table* t, int64_t h) {
    int64_t i = h & 0xffff;
    t->live[i] = NULL;
    t->gen[i]++;
    t->spare[t->spares++] = (int32_t)i;
}

/* ── A byte run ──────────────────────────────────────────────────── */

typedef struct {
    unsigned char* at;
    size_t len, cap;
} Run;

static int run_append(Run* r, const unsigned char* p, size_t n) {
    if (r->len + n > r->cap) {
        size_t cap = r->cap ? r->cap : 4096;
        while (cap < r->len + n) cap *= 2;
        unsigned char* grown = realloc(r->at, cap);
        if (!grown) return 0;
        r->at = grown;
        r->cap = cap;
    }
    if (n) memcpy(r->at + r->len, p, n);
    r->len += n;
    return 1;
}

static void run_drop(Run* r, size_t n) {
    memmove(r->at, r->at + n, r->len - n);
    r->len -= n;
}

/* ── Configs ─────────────────────────────────────────────────────
   One per side of a service: its roots, its identities, whether it
   verifies, the protocols it offers. Sessions borrow it, so it is
   freed only once every session made from it has ended.  */

typedef struct Identity {
    mbedtls_x509_crt chain;
    mbedtls_pk_context key;
    struct Identity* next;
} Identity;

/* ALPN names in preference order, NULL-terminated as mbedTLS reads
   them. */
enum { TLS_PROTOCOLS = 8 };

/* A client remembers the last session each host granted, so its next
   connection there resumes; the oldest is forgotten first. */
enum { TLS_REMEMBERED = 32, TLS_HOST_MAX = 255 };

typedef struct {
    char host[TLS_HOST_MAX + 1];
    mbedtls_ssl_session session;
    int held;
} Remembered;

typedef struct {
    mbedtls_ssl_config conf;
    mbedtls_x509_crt roots;
    Identity* identities;
    mbedtls_ssl_ticket_context tickets;
    int server;
    int verifies;
    int64_t sessions;
    char* protocols[TLS_PROTOCOLS + 1];
    int nprotocols;
    Remembered remembered[TLS_REMEMBERED];
    int next_remembered;
    int64_t resumed;
} Config;

static Table g_configs;

/* ── Serving by name ─────────────────────────────────────────────
   A server holding several identities answers a client's SNI with the
   first whose certificate names that host; a host none names, or no
   SNI at all, gets the first identity added.  */

static int ascii_caseeq(const unsigned char* a, const unsigned char* b, size_t n) {
    for (size_t i = 0; i < n; i++) {
        unsigned char x = a[i] >= 'A' && a[i] <= 'Z' ? a[i] + 32 : a[i];
        unsigned char y = b[i] >= 'A' && b[i] <= 'Z' ? b[i] + 32 : b[i];
        if (x != y) return 0;
    }
    return 1;
}

/* Whether a certificate's DNS name answers `host`: equal ignoring
   ASCII case, or `*.rest` standing for exactly one leftmost label. */
static int name_answers(const unsigned char* name, size_t n, const unsigned char* host, size_t h) {
    if (n == h && ascii_caseeq(name, host, n)) return 1;
    if (n < 3 || name[0] != '*' || name[1] != '.') return 0;
    const unsigned char* dot = memchr(host, '.', h);
    if (!dot || dot == host) return 0;
    size_t rest = h - (size_t)(dot - host);
    return rest == n - 1 && ascii_caseeq(name + 1, dot, rest);
}

static int identity_answers(const Identity* id, const unsigned char* host, size_t h) {
    for (const mbedtls_x509_sequence* san = &id->chain.subject_alt_names; san && san->buf.p; san = san->next) {
        if ((san->buf.tag & MBEDTLS_ASN1_TAG_VALUE_MASK) == MBEDTLS_X509_SAN_DNS_NAME &&
            name_answers(san->buf.p, san->buf.len, host, h)) {
            return 1;
        }
    }
    return 0;
}

static int sni_chosen(void* ctx, mbedtls_ssl_context* ssl, const unsigned char* host, size_t h) {
    Config* c = ctx;
    for (Identity* id = c->identities; id; id = id->next) {
        if (identity_answers(id, host, h)) return mbedtls_ssl_set_hs_own_cert(ssl, &id->chain, &id->key);
    }
    return 0;
}

/* ── Resumption ──────────────────────────────────────────────────
   A server issues tickets and counts the ones it accepts back; a
   client keeps the last session per host and offers it next time.  */

static int ticket_written(void* ctx, const mbedtls_ssl_session* session, unsigned char* start,
                          const unsigned char* end, size_t* len, uint32_t* lifetime) {
    Config* c = ctx;
    return mbedtls_ssl_ticket_write(&c->tickets, session, start, end, len, lifetime);
}

static int ticket_parsed(void* ctx, mbedtls_ssl_session* session, unsigned char* buf, size_t len) {
    Config* c = ctx;
    int rc = mbedtls_ssl_ticket_parse(&c->tickets, session, buf, len);
    if (!rc) c->resumed++;
    return rc;
}

static Remembered* remembered_for(Config* c, const char* host) {
    for (int i = 0; i < TLS_REMEMBERED; i++) {
        if (c->remembered[i].held && !strcmp(c->remembered[i].host, host)) return &c->remembered[i];
    }
    return NULL;
}

static void remember(Config* c, const mbedtls_ssl_context* ssl, const char* host) {
    Remembered* r = remembered_for(c, host);
    if (!r) {
        r = &c->remembered[c->next_remembered];
        c->next_remembered = (c->next_remembered + 1) % TLS_REMEMBERED;
    }
    if (r->held) mbedtls_ssl_session_free(&r->session);
    mbedtls_ssl_session_init(&r->session);
    r->held = !mbedtls_ssl_get_session(ssl, &r->session);
    if (r->held) {
        strncpy(r->host, host, TLS_HOST_MAX);
    } else {
        mbedtls_ssl_session_free(&r->session);
    }
}

static void forgotten(Config* c) {
    for (int i = 0; i < TLS_REMEMBERED; i++) {
        if (c->remembered[i].held) mbedtls_ssl_session_free(&c->remembered[i].session);
    }
    for (int i = 0; i < c->nprotocols; i++) free(c->protocols[i]);
}

static int crypto_started(void) {
    static int started;
    if (!started) started = psa_crypto_init() == PSA_SUCCESS;
    return started;
}

/* A config for a server (1) or a client (0): TLS 1.2 at the least, a
   client verifying its peer, a server issuing resumption tickets. */
int64_t avra_tls_config(int64_t server) {
    if (!crypto_started()) return TLS_ERR_CRYPTO;
    Config* c = calloc(1, sizeof *c);
    if (!c) return TLS_ERR_MEMORY;
    c->server = server != 0;
    mbedtls_ssl_config_init(&c->conf);
    mbedtls_x509_crt_init(&c->roots);
    mbedtls_ssl_ticket_init(&c->tickets);
    int rc = mbedtls_ssl_config_defaults(&c->conf,
        c->server ? MBEDTLS_SSL_IS_SERVER : MBEDTLS_SSL_IS_CLIENT,
        MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT);
    if (!rc) {
        mbedtls_ssl_conf_min_tls_version(&c->conf, MBEDTLS_SSL_VERSION_TLS1_2);
        c->verifies = !c->server;
        mbedtls_ssl_conf_authmode(&c->conf, c->verifies ? MBEDTLS_SSL_VERIFY_REQUIRED : MBEDTLS_SSL_VERIFY_NONE);
        mbedtls_ssl_conf_ca_chain(&c->conf, &c->roots, NULL);
    }
    if (!rc && c->server) {
        mbedtls_ssl_conf_sni(&c->conf, sni_chosen, c);
        rc = mbedtls_ssl_ticket_setup(&c->tickets, PSA_ALG_GCM, PSA_KEY_TYPE_AES, 256, 86400);
        if (!rc) mbedtls_ssl_conf_session_tickets_cb(&c->conf, ticket_written, ticket_parsed, c);
    }
    int64_t h = rc ? rc : handle_of(&g_configs, c);
    if (h < 0) {
        mbedtls_ssl_ticket_free(&c->tickets);
        mbedtls_x509_crt_free(&c->roots);
        mbedtls_ssl_config_free(&c->conf);
        free(c);
    }
    return h;
}

/* PEM text as mbedTLS parses it: a copy ending in the NUL it demands. */
static unsigned char* terminated(const unsigned char* p, int64_t n) {
    unsigned char* t = malloc((size_t)n + 1);
    if (!t) return NULL;
    if (n) memcpy(t, p, (size_t)n);
    t[n] = 0;
    return t;
}

/* Trust anchors added from PEM text: how many parsed. A bundle may
   hold certificates this build cannot read, and those are skipped; a
   bundle holding none it can is refused. */
int64_t avra_tls_config_roots(int64_t cfg, const unsigned char* pem, int64_t n) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    if (n < 0) return TLS_ERR_BOUNDS;
    unsigned char* t = terminated(pem, n);
    if (!t) return TLS_ERR_MEMORY;
    int before = 0;
    for (mbedtls_x509_crt* x = &c->roots; x && x->raw.len; x = x->next) before++;
    int rc = mbedtls_x509_crt_parse(&c->roots, t, (size_t)n + 1);
    free(t);
    int after = 0;
    for (mbedtls_x509_crt* x = &c->roots; x && x->raw.len; x = x->next) after++;
    if (rc < 0) return rc;
    return after > before ? after - before : TLS_ERR_EMPTY;
}

/* A chain is sent whole in one handshake message, which the record
   layer bounds; room is kept for the message's own framing. */
enum { TLS_CHAIN_MAX = MBEDTLS_SSL_OUT_CONTENT_LEN - 1024 };

/* The bytes a chain occupies in a Certificate message. */
static size_t chain_bytes(const mbedtls_x509_crt* x) {
    size_t n = 0;
    for (; x && x->raw.len; x = x->next) n += x->raw.len + 8;
    return n;
}

/* A certificate chain (leaf first) and its private key, from PEM. The
   first identity added answers a peer that names no host. */
int64_t avra_tls_config_identity(int64_t cfg, const unsigned char* chain, int64_t chain_n,
                                 const unsigned char* key, int64_t key_n) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    if (chain_n < 0 || key_n < 0) return TLS_ERR_BOUNDS;
    Identity* id = calloc(1, sizeof *id);
    unsigned char* tc = terminated(chain, chain_n);
    unsigned char* tk = terminated(key, key_n);
    int rc = id && tc && tk ? 0 : TLS_ERR_MEMORY;
    if (id) {
        mbedtls_x509_crt_init(&id->chain);
        mbedtls_pk_init(&id->key);
    }
    if (!rc) rc = mbedtls_x509_crt_parse(&id->chain, tc, (size_t)chain_n + 1);
    if (!rc && chain_bytes(&id->chain) > TLS_CHAIN_MAX) rc = TLS_ERR_CHAIN;
    if (!rc && mbedtls_pk_parse_key(&id->key, tk, (size_t)key_n + 1, NULL, 0)) rc = TLS_ERR_KEY;
    if (!rc && mbedtls_pk_check_pair(&id->chain.pk, &id->key)) rc = TLS_ERR_PAIR;
    if (!rc) rc = mbedtls_ssl_conf_own_cert(&c->conf, &id->chain, &id->key);
    if (tk) mbedtls_platform_zeroize(tk, (size_t)key_n + 1);
    free(tc);
    free(tk);
    if (rc) {
        if (id) {
            mbedtls_x509_crt_free(&id->chain);
            mbedtls_pk_free(&id->key);
        }
        free(id);
        return rc > 0 ? TLS_ERR_EMPTY : rc;
    }
    Identity** tail = &c->identities;
    while (*tail) tail = &(*tail)->next;
    *tail = id;
    return cfg;
}

/* Whether the peer's certificate must verify: 1 required, 0 not
   checked at all — the insecure seat, never the default. */
int64_t avra_tls_config_verify(int64_t cfg, int64_t required) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    c->verifies = required != 0;
    mbedtls_ssl_conf_authmode(&c->conf, c->verifies ? MBEDTLS_SSL_VERIFY_REQUIRED : MBEDTLS_SSL_VERIFY_NONE);
    return cfg;
}

/* An application protocol offered (a client) or accepted (a server),
   after those already named — a server picks by its own order. A name
   is 1 to 255 bytes with no NUL; eight at most. */
/* Whether an ALPN name is registered for cleartext TCP alone: `h2c`,
   which a TLS client MUST NOT offer nor a server select (RFC 9113 §3.2).
   ALPN names compare as exact octets (RFC 7301 §3.1). */
static int cleartext_only(const unsigned char* name, int64_t n) {
    return n == 3 && memcmp(name, "h2c", 3) == 0;
}

int64_t avra_tls_config_protocol(int64_t cfg, const unsigned char* name, int64_t n) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    if (n < 1 || n > 255 || memchr(name, 0, (size_t)n) || c->nprotocols == TLS_PROTOCOLS) return TLS_ERR_PROTOCOL;
    if (cleartext_only(name, n)) return TLS_ERR_CLEARTEXT;
    char* copy = (char*)terminated(name, n);
    if (!copy) return TLS_ERR_MEMORY;
    c->protocols[c->nprotocols++] = copy;
    c->protocols[c->nprotocols] = NULL;
    int rc = mbedtls_ssl_conf_alpn_protocols(&c->conf, (const char**)c->protocols);
    return rc ? rc : c->nprotocols;
}

/* How many sessions a server has resumed from its tickets. */
int64_t avra_tls_config_resumed(int64_t cfg) {
    Config* c = held(&g_configs, cfg);
    return c ? c->resumed : TLS_ERR_HANDLE;
}

int64_t avra_tls_config_free(int64_t cfg) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    if (c->sessions) return TLS_ERR_BUSY;
    released(&g_configs, cfg);
    for (Identity* id = c->identities; id;) {
        Identity* next = id->next;
        mbedtls_x509_crt_free(&id->chain);
        mbedtls_pk_free(&id->key);
        free(id);
        id = next;
    }
    forgotten(c);
    mbedtls_ssl_ticket_free(&c->tickets);
    mbedtls_x509_crt_free(&c->roots);
    mbedtls_ssl_config_free(&c->conf);
    free(c);
    return cfg;
}

/* ── Sessions ────────────────────────────────────────────────────
   `in` holds ciphertext fed and not yet read by mbedTLS, `out` the
   ciphertext it wrote and Avra has not drained, `plain` the last
   decrypted run, valid until the session's next call.  */

typedef struct {
    mbedtls_ssl_context ssl;
    Config* config;
    char host[TLS_HOST_MAX + 1];
    Run in, out;
    unsigned char plain[TLS_PLAIN_CAP];
} Session;

static Table g_sessions;

static int wire_send(void* ctx, const unsigned char* p, size_t n) {
    Session* s = ctx;
    return run_append(&s->out, p, n) ? (int)n : MBEDTLS_ERR_SSL_ALLOC_FAILED;
}

static int wire_recv(void* ctx, unsigned char* p, size_t n) {
    Session* s = ctx;
    if (!s->in.len) return MBEDTLS_ERR_SSL_WANT_READ;
    if (n > s->in.len) n = s->in.len;
    memcpy(p, s->in.at, n);
    run_drop(&s->in, n);
    return (int)n;
}

/* A session under `cfg`. A client names the host it expects — the SNI
   it sends and the name its peer's certificate must carry; a server
   names none, and a verifying client must name one. The name is read
   by its length: one holding a NUL would mean a prefix of itself to
   mbedTLS, and is refused. */
int64_t avra_tls_session(int64_t cfg, const unsigned char* host, int64_t n) {
    Config* c = held(&g_configs, cfg);
    if (!c) return TLS_ERR_HANDLE;
    if (n < 0) return TLS_ERR_BOUNDS;
    if (n && memchr(host, 0, (size_t)n)) return TLS_ERR_HOST;
    if (!n && !c->server && c->verifies) return TLS_ERR_NAMELESS;
    char* name = (char*)terminated(host, n);
    Session* s = name ? calloc(1, sizeof *s) : NULL;
    if (!s) {
        free(name);
        return TLS_ERR_MEMORY;
    }
    mbedtls_ssl_init(&s->ssl);
    int rc = mbedtls_ssl_setup(&s->ssl, &c->conf);
    if (!rc && !c->server && n) rc = mbedtls_ssl_set_hostname(&s->ssl, name);
    if (!rc && !c->server && n) {
        strncpy(s->host, name, TLS_HOST_MAX);
        Remembered* r = remembered_for(c, s->host);
        if (r) (void)mbedtls_ssl_set_session(&s->ssl, &r->session);
    }
    free(name);
    int64_t h = rc ? rc : handle_of(&g_sessions, s);
    if (h < 0) {
        mbedtls_ssl_free(&s->ssl);
        free(s);
        return h;
    }
    mbedtls_ssl_set_bio(&s->ssl, s, wire_send, wire_recv, NULL);
    s->config = c;
    c->sessions++;
    return h;
}

/* Ciphertext from the peer: `n` bytes of `b` from `from`, queued for
   the next read. Answers how many are queued. */
int64_t avra_tls_feed(int64_t ses, const unsigned char* b, int64_t from, int64_t n) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    if (from < 0 || n < 0) return TLS_ERR_BOUNDS;
    if (s->in.len + (size_t)n > TLS_IN_CAP) return TLS_ERR_FULL;
    if (!run_append(&s->in, b + from, (size_t)n)) return TLS_ERR_MEMORY;
    return (int64_t)s->in.len;
}

/* mbedTLS may answer WANT_READ after consuming part of what was fed;
   a call is repeated while it made progress, so WANT_READ reaches the
   caller only when the fed ciphertext is spent or holds no whole
   record. */
static int progressed(Session* s, size_t before, int rc) {
    if (rc == MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET) {
        if (s->host[0]) remember(s->config, &s->ssl, s->host);
        return 1;
    }
    return rc == MBEDTLS_ERR_SSL_WANT_READ && s->in.len < before;
}

/* Whether a read refused a renegotiation, the ciphertext owed the peer
   having stood at `owed` before it (SIZE_MAX for a read that began
   inside the handshake, which writes as it goes). Once the handshake is
   over, a TLS 1.2 read answers the peer only to refuse a renegotiation:
   the one handshake message a 1.2 peer may send then asks for one, and
   this build, renegotiation compiled out, answers it with a warning
   alert and reads on. It is surfaced as a failure, so a protocol that
   must end the connection on it (RFC 9113 §9.2.1) is told. */
static int renegotiation_refused(Session* s, size_t owed) {
    return s->out.len > owed && mbedtls_ssl_get_version_number(&s->ssl) == MBEDTLS_SSL_VERSION_TLS1_2;
}

/* One handshake step: 0 once it is complete, else a negative code —
   `avra_tls_want_read()` when it needs the peer's next flight. */
int64_t avra_tls_handshake(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    int rc;
    size_t before;
    do {
        before = s->in.len;
        rc = mbedtls_ssl_handshake(&s->ssl);
    } while (progressed(s, before, rc));
    if (!rc && s->host[0] && mbedtls_ssl_get_version_number(&s->ssl) == MBEDTLS_SSL_VERSION_TLS1_2) {
        remember(s->config, &s->ssl, s->host);
    }
    return rc;
}

/* The ciphertext waiting to go to the peer: its length, then where it
   is. The bytes stand until `avra_tls_sent` drops them. */
int64_t avra_tls_outgoing(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    return s ? (int64_t)s->out.len : TLS_ERR_HANDLE;
}

const unsigned char* avra_tls_outgoing_at(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    return s ? s->out.at : NULL;
}

int64_t avra_tls_sent(int64_t ses, int64_t n) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    if (n < 0 || (size_t)n > s->out.len) return TLS_ERR_BOUNDS;
    run_drop(&s->out, (size_t)n);
    return (int64_t)s->out.len;
}

/* Plaintext for the peer: up to one record of `n` bytes of `b` from
   `from`, sealed into the outgoing ciphertext. Answers how many were
   taken. */
int64_t avra_tls_send(int64_t ses, const unsigned char* b, int64_t from, int64_t n) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    if (from < 0 || n < 0) return TLS_ERR_BOUNDS;
    return mbedtls_ssl_write(&s->ssl, b + from, (size_t)n);
}

/* Plaintext from the peer, up to `max` bytes, landed where
   `avra_tls_received_at` points: the count, 0 once the peer sent
   close_notify, or a negative code. */
int64_t avra_tls_receive(int64_t ses, int64_t max) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    if (max <= 0) return TLS_ERR_BOUNDS;
    size_t want = max < TLS_PLAIN_CAP ? (size_t)max : TLS_PLAIN_CAP;
    size_t owed = mbedtls_ssl_is_handshake_over(&s->ssl) ? s->out.len : SIZE_MAX;
    int rc;
    size_t before;
    do {
        before = s->in.len;
        rc = mbedtls_ssl_read(&s->ssl, s->plain, want);
    } while (progressed(s, before, rc));
    if (renegotiation_refused(s, owed)) return TLS_ERR_RENEGOTIATION;
    return rc == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY ? 0 : rc;
}

const unsigned char* avra_tls_received_at(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    return s ? s->plain : NULL;
}

/* close_notify queued for the peer. */
int64_t avra_tls_close_notify(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    return mbedtls_ssl_close_notify(&s->ssl);
}

/* The protocol the handshake settled: 0x0303 for TLS 1.2, 0x0304 for
   1.3, 0 before it settles or once the session has ended. */
int64_t avra_tls_version(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return 0;
    return mbedtls_ssl_is_handshake_over(&s->ssl) ? (int64_t)mbedtls_ssl_get_version_number(&s->ssl) : 0;
}

/* The application protocol the handshake settled: its length, then
   where its name is; 0 when none was agreed. */
int64_t avra_tls_protocol(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    const char* p = mbedtls_ssl_get_alpn_protocol(&s->ssl);
    return p ? (int64_t)strlen(p) : 0;
}

const char* avra_tls_protocol_at(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    return s ? mbedtls_ssl_get_alpn_protocol(&s->ssl) : NULL;
}

int64_t avra_tls_end(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return TLS_ERR_HANDLE;
    released(&g_sessions, ses);
    s->config->sessions--;
    mbedtls_ssl_free(&s->ssl);
    free(s->in.at);
    free(s->out.at);
    mbedtls_platform_zeroize(s->plain, sizeof s->plain);
    free(s);
    return ses;
}

/* ── Words ───────────────────────────────────────────────────────── */

int64_t avra_tls_want_read(void) { return MBEDTLS_ERR_SSL_WANT_READ; }

int64_t avra_tls_unverified(void) { return MBEDTLS_ERR_X509_CERT_VERIFY_FAILED; }

int64_t avra_tls_want_write(void) { return MBEDTLS_ERR_SSL_WANT_WRITE; }

static char g_words[512];

/* A code's words, landed where `avra_tls_words_at` points: their
   length. */
int64_t avra_tls_words(int64_t code) {
    const char* ours = NULL;
    switch (code) {
    case TLS_ERR_HANDLE: ours = "a TLS handle that names nothing live"; break;
    case TLS_ERR_MEMORY: ours = "out of memory"; break;
    case TLS_ERR_BOUNDS: ours = "a range outside the value it names"; break;
    case TLS_ERR_FULL: ours = "the peer sent more than a session holds unread"; break;
    case TLS_ERR_CRYPTO: ours = "the crypto core would not start"; break;
    case TLS_ERR_EMPTY: ours = "PEM text holding no certificate or key this build reads"; break;
    case TLS_ERR_HOST: ours = "a host name holding a NUL"; break;
    case TLS_ERR_KEY: ours = "PEM text holding no private key this build reads"; break;
    case TLS_ERR_PAIR: ours = "a private key that is not its certificate's"; break;
    case TLS_ERR_BUSY: ours = "a config still serving sessions — end them first"; break;
    case TLS_ERR_NAMELESS: ours = "a verifying client names the host it expects"; break;
    case TLS_ERR_PROTOCOL: ours = "an ALPN name is 1 to 255 bytes with no NUL, eight at most"; break;
    case TLS_ERR_CHAIN: ours = "a chain larger than one handshake message holds — present fewer certificates"; break;
    case TLS_ERR_CLEARTEXT: ours = "h2c is HTTP/2 over cleartext TCP, which TLS never agrees (RFC 9113 §3.2)"; break;
    case TLS_ERR_RENEGOTIATION: ours = "the peer asked to renegotiate, which is refused"; break;
    }
    if (ours) {
        strncpy(g_words, ours, sizeof g_words - 1);
    } else {
        mbedtls_strerror((int)code, g_words, sizeof g_words);
    }
    return (int64_t)strlen(g_words);
}

const char* avra_tls_words_at(void) { return g_words; }

/* Why the peer's certificate was not trusted, landed where
   `avra_tls_words_at` points: its length. One reason a line. */
int64_t avra_tls_verify_words(int64_t ses) {
    Session* s = held(&g_sessions, ses);
    if (!s) return avra_tls_words(TLS_ERR_HANDLE);
    int n = mbedtls_x509_crt_verify_info(g_words, sizeof g_words, "", mbedtls_ssl_get_verify_result(&s->ssl));
    if (n <= 0) return 0;
    if (g_words[n - 1] == '\n') g_words[--n] = 0;
    return n;
}
