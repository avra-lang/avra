// The kernel's floor for the bench's workload: epoll edge-triggered on
// Linux, kqueue on macOS, every request answered with the same bytes
// the Avra server writes, no parsing beyond counting request
// terminators. What an HTTP server on this host cannot beat without
// fewer syscalls.
//
// CORES=n serves on n processes, share-nothing. LISTEN picks how they
// meet the port: `shared` (default) forks after one listen and every
// process accepts from its one queue; `reuseport` gives each process
// its own socket and queue under SO_REUSEPORT. ROUTE picks the reply:
// unset is tools/bench/serve's, `plaintext` and `json` are
// tools/bench/scenarios' routes of those names. PORT is the port, 18080
// unless set.
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>
#ifdef __APPLE__
#include <sys/event.h>
#else
#include <sys/epoll.h>
#endif

static const char *reply = "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 5\r\n\r\nhello";
static size_t reply_len;

static const char *chosen(const char *route) {
    if (!route) return reply;
    if (!strcmp(route, "plaintext"))
        return "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 13\r\n\r\nHello, World!";
    if (!strcmp(route, "json"))
        return "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\ncontent-length: 27\r\n\r\n{\"message\":\"Hello, World!\"}";
    exit(2);
}

static int listening(int reuseport) {
    int l = socket(AF_INET, SOCK_STREAM, 0);
    fcntl(l, F_SETFL, O_NONBLOCK);
    int on = 1;
    setsockopt(l, SOL_SOCKET, reuseport ? SO_REUSEPORT : SO_REUSEADDR, &on, sizeof on);
    struct sockaddr_in a = { .sin_family = AF_INET, .sin_port = htons(getenv("PORT") ? atoi(getenv("PORT")) : 18080), .sin_addr.s_addr = htonl(INADDR_LOOPBACK) };
    if (bind(l, (struct sockaddr*)&a, sizeof a) || listen(l, 511)) exit(1);
    return l;
}

static int accepted(int l) {
    int c = accept(l, NULL, NULL);
    if (c < 0) return c;
    int on = 1;
    fcntl(c, F_SETFL, O_NONBLOCK);
    setsockopt(c, IPPROTO_TCP, TCP_NODELAY, &on, sizeof on);
    return c;
}

// Reads what `fd` has and answers every complete request in it with one
// write; closes it on end or error.
static void drained(int fd) {
    static char buf[16384], out[16 * 256];
    for (;;) {
        ssize_t got = read(fd, buf, sizeof buf);
        if (got <= 0) { if (got == 0 || errno != EAGAIN) close(fd); return; }
        int reqs = 0;
        for (ssize_t j = 3; j < got; j++) reqs += buf[j] == '\n' && buf[j - 1] == '\r' && buf[j - 2] == '\n';
        size_t len = 0;
        for (int k = 0; k < reqs && k < 16; k++) { memcpy(out + len, reply, reply_len); len += reply_len; }
        if (len && write(fd, out, len) < 0) { close(fd); return; }
        if ((size_t)got < sizeof buf) return;
    }
}

#ifdef __APPLE__
static void serve(int l) {
    int kq = kqueue();
    struct kevent ev;
    EV_SET(&ev, l, EVFILT_READ, EV_ADD, 0, 0, NULL);
    kevent(kq, &ev, 1, NULL, 0, NULL);
    struct kevent evs[256];
    for (;;) {
        int n = kevent(kq, NULL, 0, evs, 256, NULL);
        for (int i = 0; i < n; i++) {
            int fd = (int)evs[i].ident;
            if (fd != l) { drained(fd); continue; }
            int c;
            while ((c = accepted(l)) >= 0) {
                EV_SET(&ev, c, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, NULL);
                kevent(kq, &ev, 1, NULL, 0, NULL);
            }
        }
    }
}
#else
static void serve(int l) {
    int ep = epoll_create1(0);
    struct epoll_event ev = { .events = EPOLLIN | EPOLLEXCLUSIVE, .data.fd = l };
    epoll_ctl(ep, EPOLL_CTL_ADD, l, &ev);
    struct epoll_event evs[256];
    for (;;) {
        int n = epoll_wait(ep, evs, 256, -1);
        for (int i = 0; i < n; i++) {
            int fd = evs[i].data.fd;
            if (fd != l) { drained(fd); continue; }
            int c;
            while ((c = accepted(l)) >= 0) {
                struct epoll_event ce = { .events = EPOLLIN | EPOLLET, .data.fd = c };
                epoll_ctl(ep, EPOLL_CTL_ADD, c, &ce);
            }
        }
    }
}
#endif

int main(void) {
    reply = chosen(getenv("ROUTE"));
    reply_len = strlen(reply);
    int cores = getenv("CORES") ? atoi(getenv("CORES")) : 1;
    int reuseport = getenv("LISTEN") && !strcmp(getenv("LISTEN"), "reuseport");
    int shared = reuseport ? -1 : listening(0);
    for (int i = 1; i < cores; i++)
        if (fork() == 0) serve(reuseport ? listening(1) : shared);
    serve(reuseport ? listening(1) : shared);
}
