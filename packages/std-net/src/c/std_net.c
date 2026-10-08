// @std.net's C: nonblocking stream sockets and a readiness queue —
// kqueue on Darwin, epoll on Linux — behind integer descriptors. A
// package's C answers ints only: a descriptor, a count, a NEGATIVE
// errno, never a C `int`, never a box. Bytes flow through the
// runtime's descriptor rows, which are the one place a value is
// minted; addresses come back as words the package formats.
//
// LEVEL-TRIGGERED on both platforms: the kernel re-reports readiness
// until a buffer is drained, so one read per wake is correct and a
// handler that stops early cannot stall; the write path is "write,
// and on a short count ask for writability". Edge saves control
// calls under load and is a later measured change; it touches no
// framing code.
//
// Feature macros: Darwin needs none under -std=c11. On Linux
// `accept4` is declared only under _GNU_SOURCE, which must precede
// the runtime's first include; without it the accept row sets the
// flags in two calls after the accept. The runtime's own process
// section already needs _DEFAULT_SOURCE or _GNU_SOURCE on glibc
// under a strict -std=c11 (posix_spawn, clock_gettime, strdup).

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#ifdef __APPLE__
#include <sys/event.h>
#endif
#ifdef __linux__
#include <sys/epoll.h>
#include <sys/random.h>
#endif

#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

// The runtime's trap: a verdict, exit 2, the words on stderr.
void avra_trap(const char* msg);
// The runtime's: a blocking call here holds the world, so a virtual
// clock flows at wall rate across it.
void avra_clock_hold(int64_t by);
// The scheduler's word that `fd` is closing: whoever is parked on it
// wakes to find it gone.
void avra_fiber_fd_closing(int64_t fd);
// Its word that every task parked reading `fd` has run out of time.
void avra_fiber_fd_interrupt(int64_t fd);

__attribute__((noinline, cold, noreturn))
static void net_trap_bounds(int64_t i, int64_t len) {
    char msg[80];
    snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)", (long long)i, (long long)len);
    avra_trap(msg);
    abort();
}

enum { NET_EVENTS = 256 };
// Interest and event bits: an event carries what it is ready for
// plus the peer's hangup and the socket's pending error.
enum { NET_READ = 1, NET_WRITE = 2, NET_HANGUP = 4, NET_ERROR = 8 };
enum { NET_SHUT_READ = 0, NET_SHUT_WRITE = 1, NET_SHUT_BOTH = 2 };

// SIGPIPE's default action is death: a write to a peer that has gone
// kills the process with no line on stderr, and every server meets
// such a peer. Ignored at the FIRST SOCKET VERB, never at load: a
// program that opens no socket keeps the platform's convention, where
// a write into a closed pipe ends it quietly, while one that speaks
// to peers must outlive a peer that leaves, so its writes answer
// -EPIPE and the row's caller decides. The per-socket belts
// (SO_NOSIGPIPE on Darwin, MSG_NOSIGNAL on Linux) cover only the
// sockets these rows made. A child of avra_proc_spawn has the default
// restored at spawn, so nothing it runs inherits this.
static int g_net_armed = 0;
static void net_armed(void) {
    if (g_net_armed) return;
    signal(SIGPIPE, SIG_IGN);
    g_net_armed = 1;
}

// ONE THREAD, like every table in the runtime: the events a wait
// answers are plain statics, so the leaves that read them need no
// frame.
#ifdef __APPLE__
static struct kevent g_net_events[NET_EVENTS];
#else
static struct epoll_event g_net_events[NET_EVENTS];
#endif
static int64_t g_net_nev = 0;

static int net_int(int64_t x) { return x > INT_MAX ? INT_MAX : x < INT_MIN ? INT_MIN : (int)x; }

// Nonblocking and CLOEXEC, keeping the descriptor's other flags.
static int64_t net_prepared(int fd) {
    int fl = fcntl(fd, F_GETFL);
    if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0 || fcntl(fd, F_SETFD, FD_CLOEXEC) < 0) return -errno;
    return 0;
}

// A connected stream's options: segments go as soon as they exist,
// and a write to a gone peer answers rather than signals. Best
// effort — a stream that is not TCP refuses NODELAY and is still a
// stream.
static void net_stream_options(int fd) {
    int one = 1;
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
#ifdef SO_NOSIGPIPE
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
#endif
}

// getaddrinfo's codes are not errnos: a system failure keeps its
// errno, exhaustion is ENOMEM, and every resolution failure — no such
// host, no address of any family, a bad service — is EINVAL: the
// host argument named no peer.
static int64_t gai_errno(int rc) {
    if (rc == EAI_SYSTEM) return -errno;
    if (rc == EAI_MEMORY) return -ENOMEM;
    return -EINVAL;
}

// The stream addresses host:port names, in the resolver's order;
// `passive` asks for addresses to bind, and a NULL host asks for
// every interface — ONLY a null, never an empty text, so no spelling
// of a host means the wildcard. Answers 0 with the list, or -errno
// with none.
static int64_t net_resolved(const char* host, int64_t port, int passive, struct addrinfo** out) {
    if (port < 0 || port > 65535) return -EINVAL;
    if (host && !host[0]) return -EINVAL;
    char service[6];
    snprintf(service, sizeof service, "%d", (int)port);
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICSERV | (passive ? AI_PASSIVE : 0);
    avra_clock_hold(1);
    int rc = getaddrinfo(host, service, &hints, out);
    avra_clock_hold(-1);
    return rc == 0 ? 0 : gai_errno(rc);
}

// One candidate bound and listening, nonblocking, or -errno.
// SO_REUSEADDR alone: a restart takes the port back from TIME_WAIT,
// while a second listener on a live port is still refused. Without
// that refusal SO_REUSEPORT lets any process of the same user take
// the port, silently, on both platforms.
static int64_t net_bound(const struct addrinfo* ai, int backlog) {
    int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) return -errno;
    int one = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    int64_t err = (bind(fd, ai->ai_addr, ai->ai_addrlen) < 0 || listen(fd, backlog) < 0) ? -errno : net_prepared(fd);
    if (err < 0) { close(fd); return err; }
    return fd;
}

static int64_t net_listening(const char* host, int64_t port, int64_t backlog) {
    net_armed();
    struct addrinfo* list;
    int64_t r = net_resolved(host, port, 1, &list);
    if (r < 0) return r;
    r = -EADDRNOTAVAIL;
    for (const struct addrinfo* ai = list; ai && r < 0; ai = ai->ai_next) r = net_bound(ai, net_int(backlog));
    freeaddrinfo(list);
    return r;
}

// A listening socket on ONE interface named by host — "0.0.0.0" and
// "::" name a family's wildcard explicitly — as a nonblocking CLOEXEC
// descriptor, or -errno; an empty host is -EINVAL, never every
// interface. Port 0 asks the kernel for one (`avra_net_local_port`
// reads it back); a negative backlog is the kernel's maximum. The
// first address that binds wins.
int64_t avra_net_listen(const char* host, int64_t port, int64_t backlog) {
    return net_listening(host, port, backlog);
}

// A listening socket on EVERY interface — the wildcard, asked for by
// name and never by an empty host.
int64_t avra_net_listen_all(int64_t port, int64_t backlog) {
    return net_listening(NULL, port, backlog);
}

// Errors accept reports about the connection it did not take rather
// than about the listener: the next pending one is tried. Linux
// hands a connection's own network errors out through accept.
static int net_accept_retries(int err) {
    switch (err) {
        case EINTR: case ECONNABORTED:
        case ENETDOWN: case EHOSTDOWN: case EHOSTUNREACH: case ENETUNREACH: case ENOPROTOOPT:
#ifdef EPROTO
        case EPROTO:
#endif
#ifdef ENONET
        case ENONET:
#endif
            return 1;
        default:
            return 0;
    }
}

// A pending connection as a nonblocking, CLOEXEC, NODELAY socket;
// -EAGAIN when none is pending, -errno for the listener's own
// failure (EMFILE says stop accepting until a close).
int64_t avra_net_accept(int64_t lfd) {
    for (;;) {
#if defined(__linux__) && defined(_GNU_SOURCE)
        // the clock: the listener is O_NONBLOCK, an accept answers at once
        int fd = accept4((int)lfd, NULL, NULL, SOCK_NONBLOCK | SOCK_CLOEXEC);
        if (fd >= 0) { net_stream_options(fd); return fd; }
#else
        // the clock: the listener is O_NONBLOCK, an accept answers at once
        int fd = accept((int)lfd, NULL, NULL);
        if (fd >= 0) {
            int64_t err = net_prepared(fd);
            if (err < 0) { close(fd); return err; }
            net_stream_options(fd);
            return fd;
        }
#endif
        if (errno == EAGAIN || errno == EWOULDBLOCK) return -EAGAIN;
        if (!net_accept_retries(errno)) return -errno;
    }
}

// One candidate's connect started, nonblocking, or -errno.
static int64_t net_dialed_to(const struct addrinfo* ai) {
    int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) return -errno;
    int64_t err = net_prepared(fd);
    if (err == 0) {
        net_stream_options(fd);
        // the clock: the socket is O_NONBLOCK, a connect starts and answers EINPROGRESS
        if (connect(fd, ai->ai_addr, ai->ai_addrlen) != 0 && errno != EINPROGRESS) err = -errno;
    }
    if (err < 0) { close(fd); return err; }
    return fd;
}

// The errnos a peer answers when it drops a connection under the
// caller: a reset, and a write into a connection it closed.
int64_t avra_net_errno_reset(void) { return ECONNRESET; }
int64_t avra_net_errno_pipe(void) { return EPIPE; }

// The errno a verb on a closed connection answers: its descriptor is
// no longer its own.
int64_t avra_net_errno_closed(void) { return EBADF; }

// The errno a connect answers when admission refused every address.
int64_t avra_net_errno_denied(void) { return EACCES; }

// A dial's outcome once its descriptor is writable: 0 connected, or
// the -errno the connect failed with.
int64_t avra_net_dialed(int64_t fd) {
    int err = 0;
    socklen_t len = sizeof err;
    if (getsockopt((int)fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0) return -errno;
    return -err;
}

// Closed: 0, or -errno for a descriptor that was not open. An
// interrupted close is a close — the descriptor is gone on both
// platforms, and a retry would close its next tenant.
int64_t avra_net_close(int64_t fd) {
    avra_fiber_fd_closing(fd);
    if (close((int)fd) == 0 || errno == EINTR) return 0;
    return -errno;
}

// Every task parked reading `fd` answers timed out; `fd` stays open.
int64_t avra_net_interrupt(int64_t fd) {
    avra_fiber_fd_interrupt(fd);
    return 0;
}

// One direction or both shut: 0 read, 1 write, 2 both; 0 or -errno.
int64_t avra_net_shutdown(int64_t fd, int64_t how) {
    int h = how == NET_SHUT_READ ? SHUT_RD : how == NET_SHUT_WRITE ? SHUT_WR : how == NET_SHUT_BOTH ? SHUT_RDWR : -1;
    if (h < 0) return -EINVAL;
    return shutdown((int)fd, h) == 0 ? 0 : -errno;
}

// A readiness queue, as a CLOEXEC descriptor or -errno.
int64_t avra_net_poll_new(void) {
#ifdef __APPLE__
    int fd = kqueue();
    if (fd < 0) return -errno;
    fcntl(fd, F_SETFD, FD_CLOEXEC);
    return fd;
#else
    int fd = epoll_create1(EPOLL_CLOEXEC);
    return fd < 0 ? -errno : fd;
#endif
}

// The queue's interest in `fd` set to `interest` — NET_READ,
// NET_WRITE, both, or 0 to stop watching; 0 or -errno. Idempotent:
// watching again replaces, and removing what is not watched is 0.
// A closed descriptor leaves the queue on its own.
#ifdef __APPLE__
int64_t avra_net_watch(int64_t pfd, int64_t fd, int64_t interest) {
    struct kevent ch[2], receipt[2];
    EV_SET(&ch[0], (uintptr_t)fd, EVFILT_READ, ((interest & NET_READ) ? EV_ADD | EV_ENABLE : EV_DELETE) | EV_RECEIPT, 0, 0, NULL);
    EV_SET(&ch[1], (uintptr_t)fd, EVFILT_WRITE, ((interest & NET_WRITE) ? EV_ADD | EV_ENABLE : EV_DELETE) | EV_RECEIPT, 0, 0, NULL);
    int r;
    // the clock: not a wait on time — a change list answered by receipts
    while ((r = kevent((int)pfd, ch, 2, receipt, 2, NULL)) < 0 && errno == EINTR) {}
    if (r < 0) return -errno;
    for (int i = 0; i < r; i++) {
        int err = (int)receipt[i].data;
        if (err != 0 && !((ch[i].flags & EV_DELETE) && err == ENOENT)) return -err;
    }
    return 0;
}
#else
int64_t avra_net_watch(int64_t pfd, int64_t fd, int64_t interest) {
    if (interest == 0) {
        // Darwin deletes a knote by ident and answers ENOENT for one it
        // does not hold; ELF's epoll validates the descriptor first, so
        // an unknown one answers EBADF. Both mean "no such watch", and
        // removing a watch that is not held is not an error.
        if (epoll_ctl((int)pfd, EPOLL_CTL_DEL, (int)fd, NULL) == 0 || errno == ENOENT || errno == EBADF) return 0;
        return -errno;
    }
    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);
    ev.events = ((interest & NET_READ) ? EPOLLIN : 0) | ((interest & NET_WRITE) ? EPOLLOUT : 0) | EPOLLRDHUP;
    ev.data.fd = (int)fd;
    if (epoll_ctl((int)pfd, EPOLL_CTL_MOD, (int)fd, &ev) == 0) return 0;
    if (errno != ENOENT) return -errno;
    return epoll_ctl((int)pfd, EPOLL_CTL_ADD, (int)fd, &ev) == 0 ? 0 : -errno;
}
#endif

// Waits up to timeout_ms (-1: until something is ready, 0: a look)
// and answers how many events the next `avra_net_event_*` reads
// carry, at most NET_EVENTS; 0 on an interrupt, -errno otherwise.
// kqueue reports a descriptor's read and write readiness as TWO
// events; epoll merges them into one — a consumer dispatches per
// event and holds for neither shape.
int64_t avra_net_wait(int64_t pfd, int64_t timeout_ms) {
#ifdef __APPLE__
    int64_t ms = timeout_ms < 0 ? 0 : timeout_ms;
    struct timespec ts = { (time_t)(ms / 1000), (long)(ms % 1000) * 1000000L };
    avra_clock_hold(1);
    int n = kevent((int)pfd, NULL, 0, g_net_events, NET_EVENTS, timeout_ms < 0 ? NULL : &ts);
    avra_clock_hold(-1);
#else
    avra_clock_hold(1);
    int n = epoll_wait((int)pfd, g_net_events, NET_EVENTS, timeout_ms < 0 ? -1 : net_int(timeout_ms));
    avra_clock_hold(-1);
#endif
    g_net_nev = n > 0 ? n : 0;
    if (n >= 0) return n;
    return errno == EINTR ? 0 : -errno;
}

// Event i of the last wait: its descriptor. Out of range traps.
int64_t avra_net_event_fd(int64_t i) {
    if (__builtin_expect(i < 0 || i >= g_net_nev, 0)) net_trap_bounds(i, g_net_nev);
#ifdef __APPLE__
    return (int64_t)g_net_events[i].ident;
#else
    return g_net_events[i].data.fd;
#endif
}

// Event i of the last wait: its NET_* bits. Out of range traps.
int64_t avra_net_event_flags(int64_t i) {
    if (__builtin_expect(i < 0 || i >= g_net_nev, 0)) net_trap_bounds(i, g_net_nev);
#ifdef __APPLE__
    const struct kevent* e = &g_net_events[i];
    int64_t eof = (e->flags & EV_EOF) != 0;
    int64_t failed = (e->flags & EV_ERROR) != 0 || (eof && e->fflags != 0);
    return (e->filter == EVFILT_READ ? NET_READ : e->filter == EVFILT_WRITE ? NET_WRITE : 0)
         | (eof ? NET_HANGUP : 0) | (failed ? NET_ERROR : 0);
#else
    uint32_t ev = g_net_events[i].events;
    return ((ev & EPOLLIN) ? NET_READ : 0) | ((ev & EPOLLOUT) ? NET_WRITE : 0)
         | ((ev & (EPOLLHUP | EPOLLRDHUP)) ? NET_HANGUP : 0) | ((ev & EPOLLERR) ? NET_ERROR : 0);
#endif
}

static int64_t net_peer(int64_t fd, struct sockaddr_storage* ss) {
    socklen_t len = sizeof *ss;
    return getpeername((int)fd, (struct sockaddr*)ss, &len) == 0 ? 0 : -errno;
}

// The peer's address family: 4, 6, 0 for another, or -errno with no peer.
int64_t avra_net_peer_family(int64_t fd) {
    struct sockaddr_storage ss;
    int64_t r = net_peer(fd, &ss);
    if (r < 0) return r;
    return ss.ss_family == AF_INET ? 4 : ss.ss_family == AF_INET6 ? 6 : 0;
}

// The peer's port, or -errno.
int64_t avra_net_peer_port(int64_t fd) {
    struct sockaddr_storage ss;
    int64_t r = net_peer(fd, &ss);
    if (r < 0) return r;
    if (ss.ss_family == AF_INET) { struct sockaddr_in a; memcpy(&a, &ss, sizeof a); return ntohs(a.sin_port); }
    if (ss.ss_family == AF_INET6) { struct sockaddr_in6 a; memcpy(&a, &ss, sizeof a); return ntohs(a.sin6_port); }
    return 0;
}

// Word `i` of an address, big-endian sixteen bits: two words for
// v4, eight for v6; -EINVAL past them or for another family.
static int64_t net_word(const struct sockaddr_storage* ss, int64_t i) {
    const unsigned char* p;
    int64_t words;
    if (ss->ss_family == AF_INET) { p = (const unsigned char*)&((const struct sockaddr_in*)ss)->sin_addr; words = 2; }
    else if (ss->ss_family == AF_INET6) { p = (const unsigned char*)&((const struct sockaddr_in6*)ss)->sin6_addr; words = 8; }
    else return -EINVAL;
    if (i < 0 || i >= words) return -EINVAL;
    return (p[2 * i] << 8) | p[2 * i + 1];
}

// Word `i` of the peer's address; -errno with no peer.
int64_t avra_net_peer_word(int64_t fd, int64_t i) {
    struct sockaddr_storage ss;
    int64_t r = net_peer(fd, &ss);
    if (r < 0) return r;
    return net_word(&ss, i);
}

// The port the descriptor is bound to — what a listener on port 0
// was given — or -errno.
int64_t avra_net_local_port(int64_t fd) {
    struct sockaddr_storage ss;
    socklen_t len = sizeof ss;
    if (getsockname((int)fd, (struct sockaddr*)&ss, &len) < 0) return -errno;
    if (ss.ss_family == AF_INET) {
        struct sockaddr_in a;
        memcpy(&a, &ss, sizeof a);
        return ntohs(a.sin_port);
    }
    if (ss.ss_family == AF_INET6) {
        struct sockaddr_in6 a;
        memcpy(&a, &ss, sizeof a);
        return ntohs(a.sin6_port);
    }
    return -EAFNOSUPPORT;
}

// How far the address a descriptor is bound to reaches, as the kernel
// holds it: 0 every interface (the wildcard), 1 this machine alone (the
// loopback), 2 one other address — or -errno.
int64_t avra_net_local_reach(int64_t fd) {
    struct sockaddr_storage ss;
    socklen_t len = sizeof ss;
    if (getsockname((int)fd, (struct sockaddr*)&ss, &len) < 0) return -errno;
    if (ss.ss_family == AF_INET) {
        struct sockaddr_in a;
        memcpy(&a, &ss, sizeof a);
        uint32_t host = ntohl(a.sin_addr.s_addr);
        if (host == INADDR_ANY) return 0;
        return (host >> 24) == 127 ? 1 : 2;
    }
    if (ss.ss_family == AF_INET6) {
        struct sockaddr_in6 a;
        memcpy(&a, &ss, sizeof a);
        if (IN6_IS_ADDR_UNSPECIFIED(&a.sin6_addr)) return 0;
        return IN6_IS_ADDR_LOOPBACK(&a.sin6_addr) ? 1 : 2;
    }
    return -EAFNOSUPPORT;
}

// A LOOKUP resolves a name on a HELPER THREAD, so the core keeps
// running its tasks while the resolver takes its time: getaddrinfo
// blocks for as long as the network makes it, and a blocked core
// blocks every connection it holds. The caller gets a descriptor that
// turns readable when the answer is in, and parks on it like any
// other; the answer is then read out of the lookup, which never
// re-resolves — the addresses counted are the addresses dialed.
//
// THE THREAD TOUCHES NO BOX AND NO TABLE. It owns one `NetLookup` of
// plain memory, fills it, publishes it with a release store, writes
// one byte to wake the caller and drops its hold. The table of
// lookups is the main thread's alone. Whoever lets go LAST frees the
// lookup, so a caller that times out and closes costs nothing: the
// thread finishes into a pipe nobody reads (SIGPIPE is ignored by
// the first socket verb) and frees what it held.
//
// A NUMERIC HOST NEVER STARTS A THREAD: an address literal is read
// in place with AI_NUMERICHOST and the lookup is born answered.
enum { NET_LOOKUP_MAX = 16 };
// Why a name resolved to nothing, beside the errno: the kinds
// getaddrinfo tells apart that a caller acts on differently.
enum { NET_UNRESOLVED_NONE = 0, NET_NO_SUCH_NAME = 1, NET_NO_ADDRESS = 2, NET_TRY_AGAIN = 3, NET_RESOLVER_FAILED = 4 };

typedef struct NetLookup {
    _Atomic int holders;
    _Atomic int done;
    char* host;
    int wake;
    int64_t status;
    int failure;
    int count;
    struct sockaddr_storage addrs[NET_LOOKUP_MAX];
} NetLookup;

static NetLookup** g_lookups = NULL;
static int64_t g_lookups_cap = 0;

static void lookup_let_go(NetLookup* l) {
    if (atomic_fetch_sub_explicit(&l->holders, 1, memory_order_acq_rel) != 1) return;
    free(l->host);
    free(l);
}

static int lookup_failure(int rc) {
    if (rc == EAI_NONAME) return NET_NO_SUCH_NAME;
#ifdef EAI_NODATA
    if (rc == EAI_NODATA) return NET_NO_ADDRESS;
#endif
#ifdef EAI_ADDRFAMILY
    if (rc == EAI_ADDRFAMILY) return NET_NO_ADDRESS;
#endif
    if (rc == EAI_AGAIN) return NET_TRY_AGAIN;
    return NET_RESOLVER_FAILED;
}

// The stream addresses `host` names, copied out of the resolver's
// list, a duplicate kept once; `flags` adds AI_NUMERICHOST for the
// literal pass.
static void lookup_fill(NetLookup* l, int flags) {
    struct addrinfo hints;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = flags;
    struct addrinfo* list = NULL;
    // the clock: on the resolver's own thread; the task waits on its pipe through the scheduler
    int rc = getaddrinfo(l->host, NULL, &hints, &list);
    if (rc != 0) {
        l->status = gai_errno(rc);
        l->failure = lookup_failure(rc);
        return;
    }
    for (const struct addrinfo* ai = list; ai && l->count < NET_LOOKUP_MAX; ai = ai->ai_next) {
        if (ai->ai_family != AF_INET && ai->ai_family != AF_INET6) continue;
        struct sockaddr_storage ss;
        memset(&ss, 0, sizeof ss);
        memcpy(&ss, ai->ai_addr, ai->ai_addrlen);
        int seen = 0;
        for (int k = 0; k < l->count && !seen; k++) seen = memcmp(&l->addrs[k], &ss, sizeof ss) == 0;
        if (!seen) l->addrs[l->count++] = ss;
    }
    freeaddrinfo(list);
    if (l->count == 0) {
        l->status = -EINVAL;
        l->failure = NET_NO_ADDRESS;
    }
}

// The answer published, the caller woken, the thread's hold let go.
static void lookup_answered(NetLookup* l) {
    atomic_store_explicit(&l->done, 1, memory_order_release);
    char one = 1;
    ssize_t w;
    do { w = write(l->wake, &one, 1); } while (w < 0 && errno == EINTR);
    close(l->wake);
    lookup_let_go(l);
}

static void* lookup_thread(void* arg) {
    NetLookup* l = arg;
    lookup_fill(l, 0);
    lookup_answered(l);
    return NULL;
}

// Room in the table for descriptor `fd`, or false when memory ran out.
static int lookups_reach(int64_t fd) {
    if (fd < g_lookups_cap) return 1;
    int64_t cap = g_lookups_cap ? g_lookups_cap : 64;
    while (cap <= fd) cap *= 2;
    NetLookup** grown = realloc(g_lookups, (size_t)cap * sizeof *grown);
    if (!grown) return 0;
    memset(grown + g_lookups_cap, 0, (size_t)(cap - g_lookups_cap) * sizeof *grown);
    g_lookups = grown;
    g_lookups_cap = cap;
    return 1;
}

static NetLookup* lookup_at(int64_t h) {
    return h >= 0 && h < g_lookups_cap ? g_lookups[h] : NULL;
}

// A FORK KEEPS THE TABLE AND LOSES THE THREADS: a lookup in flight
// when a core forks would stay unanswered in the child forever, its
// descriptor readable once the parent's thread writes. The child
// answers each such lookup as one to try again, and closes the wake
// end no thread of its will write.
static void lookups_forked(void) {
    for (int64_t h = 0; h < g_lookups_cap; h++) {
        NetLookup* l = g_lookups[h];
        if (!l || atomic_load_explicit(&l->done, memory_order_acquire)) continue;
        close(l->wake);
        l->status = -EAGAIN;
        l->failure = NET_TRY_AGAIN;
        atomic_store_explicit(&l->done, 1, memory_order_release);
        atomic_fetch_sub_explicit(&l->holders, 1, memory_order_acq_rel);
    }
}

static int g_lookups_armed = 0;
static void lookups_armed(void) {
    if (g_lookups_armed) return;
    pthread_atfork(NULL, NULL, lookups_forked);
    g_lookups_armed = 1;
}

// A thread started with every signal blocked, so no handler the
// program installed ever runs on it; the caller's mask is restored.
static int lookup_spawned(NetLookup* l) {
    sigset_t all, was;
    sigfillset(&all);
    pthread_sigmask(SIG_SETMASK, &all, &was);
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_t t;
    int rc = pthread_create(&t, &attr, lookup_thread, l);
    pthread_attr_destroy(&attr);
    pthread_sigmask(SIG_SETMASK, &was, NULL);
    return rc;
}

// A lookup of `host` started: a descriptor that turns readable once
// the answer is in, or -errno. Every lookup is closed by
// `avra_net_lookup_close`, answered or not.
int64_t avra_net_lookup(const char* host) {
    net_armed();
    lookups_armed();
    if (host[0] == 0) return -EINVAL;
    int pipe_fds[2];
    if (pipe(pipe_fds) != 0) return -errno;
    if (!lookups_reach(pipe_fds[0])) { close(pipe_fds[0]); close(pipe_fds[1]); return -ENOMEM; }
    fcntl(pipe_fds[0], F_SETFD, FD_CLOEXEC);
    fcntl(pipe_fds[1], F_SETFD, FD_CLOEXEC);
    NetLookup* l = calloc(1, sizeof *l);
    char* copy = strdup(host);
    if (!l || !copy) { free(l); free(copy); close(pipe_fds[0]); close(pipe_fds[1]); return -ENOMEM; }
    l->host = copy;
    l->wake = pipe_fds[1];
    atomic_init(&l->holders, 2);
    g_lookups[pipe_fds[0]] = l;
    lookup_fill(l, AI_NUMERICHOST);
    if (l->status == 0 || l->failure != NET_NO_SUCH_NAME) { lookup_answered(l); return pipe_fds[0]; }
    l->status = 0;
    l->failure = NET_UNRESOLVED_NONE;
    int rc = lookup_spawned(l);
    if (rc != 0) {
        l->status = -rc;
        l->failure = NET_RESOLVER_FAILED;
        lookup_answered(l);
    }
    return pipe_fds[0];
}

// Whether the lookup has answered: 1, or 0 while its thread runs.
int64_t avra_net_lookup_ready(int64_t h) {
    NetLookup* l = lookup_at(h);
    return l && atomic_load_explicit(&l->done, memory_order_acquire) ? 1 : 0;
}

// How many addresses the lookup found once answered, -EINPROGRESS
// while it is not, or the -errno it failed with.
int64_t avra_net_lookup_count(int64_t h) {
    NetLookup* l = lookup_at(h);
    if (!l) return -EBADF;
    if (!atomic_load_explicit(&l->done, memory_order_acquire)) return -EINPROGRESS;
    return l->status < 0 ? l->status : l->count;
}

// Why an answered lookup found nothing: one of NET_NO_SUCH_NAME and
// its siblings, or 0.
int64_t avra_net_lookup_failure(int64_t h) {
    NetLookup* l = lookup_at(h);
    if (!l || !atomic_load_explicit(&l->done, memory_order_acquire)) return 0;
    return l->failure;
}

static const struct sockaddr_storage* lookup_addr(int64_t h, int64_t i) {
    NetLookup* l = lookup_at(h);
    if (!l || !atomic_load_explicit(&l->done, memory_order_acquire) || l->status < 0) return NULL;
    if (i < 0 || i >= l->count) net_trap_bounds(i, l->count);
    return &l->addrs[i];
}

// Address `i`'s family, 4 or 6, or -EBADF for a lookup not answered.
int64_t avra_net_lookup_family(int64_t h, int64_t i) {
    const struct sockaddr_storage* ss = lookup_addr(h, i);
    if (!ss) return -EBADF;
    return ss->ss_family == AF_INET6 ? 6 : 4;
}

// Address `i`'s 16-bit word `w` — 0..1 for v4, 0..7 for v6.
int64_t avra_net_lookup_word(int64_t h, int64_t i, int64_t w) {
    const struct sockaddr_storage* ss = lookup_addr(h, i);
    if (!ss) return -EBADF;
    return net_word(ss, w);
}

// The lookup let go and its descriptor closed; 0, or -EBADF for one
// that is not open.
int64_t avra_net_lookup_close(int64_t h) {
    NetLookup* l = lookup_at(h);
    if (!l) return -EBADF;
    g_lookups[h] = NULL;
    avra_fiber_fd_closing(h);
    close((int)h);
    lookup_let_go(l);
    return 0;
}

// A nonblocking connect to an address LITERAL started, never resolved
// — a name is refused — or -errno.
int64_t avra_net_dial_address(const char* address, int64_t port) {
    net_armed();
    if (port < 0 || port > 65535) return -EINVAL;
    struct sockaddr_storage ss;
    memset(&ss, 0, sizeof ss);
    struct addrinfo ai;
    memset(&ai, 0, sizeof ai);
    ai.ai_socktype = SOCK_STREAM;
    ai.ai_addr = (struct sockaddr*)&ss;
    struct sockaddr_in* v4 = (struct sockaddr_in*)&ss;
    struct sockaddr_in6* v6 = (struct sockaddr_in6*)&ss;
    if (inet_pton(AF_INET, address, &v4->sin_addr) == 1) {
        v4->sin_family = AF_INET;
        v4->sin_port = htons((uint16_t)port);
        ai.ai_family = AF_INET;
        ai.ai_addrlen = sizeof *v4;
    } else if (inet_pton(AF_INET6, address, &v6->sin6_addr) == 1) {
        v6->sin6_family = AF_INET6;
        v6->sin6_port = htons((uint16_t)port);
        ai.ai_family = AF_INET6;
        ai.ai_addrlen = sizeof *v6;
    } else {
        return -EINVAL;
    }
    return net_dialed_to(&ai);
}

// 32 bits of the kernel's entropy, unpredictable to any peer: what a
// WebSocket client masks its frames and keys its handshake with (RFC
// 6455 §5.3, §4.1). Negative errno when the kernel has none to give.
int64_t avra_net_entropy32(void) {
#ifdef __APPLE__
    return (int64_t)arc4random();
#else
    uint32_t w;
    ssize_t n;
    do { n = getrandom(&w, sizeof w, 0); } while (n < 0 && errno == EINTR);
    if (n != (ssize_t)sizeof w) return n < 0 ? -errno : -EIO;
    return (int64_t)w;
#endif
}
