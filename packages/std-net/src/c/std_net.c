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
#endif

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

// The runtime's trap: a verdict, exit 2, the words on stderr.
void avra_trap(const char* msg);

__attribute__((noinline, cold, noreturn))
static void net_trap_bounds(int64_t i, int64_t len) {
    char msg[80];
    snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)", (long long)i, (long long)len);
    avra_trap(msg);
    abort();
}

// A monotonic clock, milliseconds.
static int64_t net_now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
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
    int rc = getaddrinfo(host, service, &hints, out);
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
        int fd = accept4((int)lfd, NULL, NULL, SOCK_NONBLOCK | SOCK_CLOEXEC);
        if (fd >= 0) { net_stream_options(fd); return fd; }
#else
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

// An in-flight connect's outcome: 0 once the socket is writable with
// no pending error, that error, or -ETIMEDOUT at the deadline (-1:
// none). A zero budget looks once.
static int64_t net_settled(int fd, int64_t deadline) {
    struct pollfd p = { fd, POLLOUT, 0 };
    for (;;) {
        int64_t remain = deadline < 0 ? -1 : deadline - net_now_ms();
        int r = poll(&p, 1, remain < 0 && deadline >= 0 ? 0 : net_int(remain));
        if (r > 0) break;
        if (r == 0) return -ETIMEDOUT;
        if (errno != EINTR) return -errno;
    }
    int err = 0;
    socklen_t len = sizeof err;
    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0) return -errno;
    return -err;
}

// One candidate connected, nonblocking, or -errno.
static int64_t net_connected(const struct addrinfo* ai, int64_t deadline) {
    int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (fd < 0) return -errno;
    int64_t err = net_prepared(fd);
    if (err == 0) {
        net_stream_options(fd);
        err = connect(fd, ai->ai_addr, ai->ai_addrlen) == 0 ? 0
            : errno == EINPROGRESS ? net_settled(fd, deadline) : -errno;
    }
    if (err < 0) { close(fd); return err; }
    return fd;
}

// A connection to host:port as a nonblocking, CLOEXEC, NODELAY
// socket, made within timeout_ms (negative: no limit) or -ETIMEDOUT.
// The budget spans the whole call: every resolved address is tried
// in the resolver's order until one connects or the deadline
// passes, and the last refusal is the answer when none does. An
// empty host names no peer: -EINVAL.
int64_t avra_net_connect(const char* host, int64_t port, int64_t timeout_ms) {
    net_armed();
    if (host[0] == 0) return -EINVAL;
    struct addrinfo* list;
    int64_t r = net_resolved(host, port, 0, &list);
    if (r < 0) return r;
    int64_t deadline = timeout_ms < 0 ? -1 : net_now_ms() + timeout_ms;
    r = -EINVAL;
    for (const struct addrinfo* ai = list; ai && r < 0 && r != -ETIMEDOUT; ai = ai->ai_next) r = net_connected(ai, deadline);
    freeaddrinfo(list);
    return r;
}

// Closed: 0, or -errno for a descriptor that was not open. An
// interrupted close is a close — the descriptor is gone on both
// platforms, and a retry would close its next tenant.
int64_t avra_net_close(int64_t fd) {
    if (close((int)fd) == 0 || errno == EINTR) return 0;
    return -errno;
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
    int n = kevent((int)pfd, NULL, 0, g_net_events, NET_EVENTS, timeout_ms < 0 ? NULL : &ts);
#else
    int n = epoll_wait((int)pfd, g_net_events, NET_EVENTS, timeout_ms < 0 ? -1 : net_int(timeout_ms));
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

// Word `i` of the peer's address, big-endian sixteen bits: two words
// for v4, eight for v6; -EINVAL past them, -errno with no peer.
int64_t avra_net_peer_word(int64_t fd, int64_t i) {
    struct sockaddr_storage ss;
    int64_t r = net_peer(fd, &ss);
    if (r < 0) return r;
    const unsigned char* p;
    int64_t words;
    if (ss.ss_family == AF_INET) { p = (const unsigned char*)&((struct sockaddr_in*)&ss)->sin_addr; words = 2; }
    else if (ss.ss_family == AF_INET6) { p = (const unsigned char*)&((struct sockaddr_in6*)&ss)->sin6_addr; words = 8; }
    else return -EINVAL;
    if (i < 0 || i >= words) return -EINVAL;
    return (p[2 * i] << 8) | p[2 * i + 1];
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
