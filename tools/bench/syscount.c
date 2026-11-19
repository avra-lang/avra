// Counts a server's I/O calls through libc: a preloaded library whose
// counters live in a file mapped shared, so every forked core adds to
// one table and a killed server has already reported.
//
//   cc -O2 -shared -fPIC -o build/syscount.so tools/bench/syscount.c   (-ldl on Linux)
//   cc -O2 -DREPORT -o build/syscount tools/bench/syscount.c
//   SYSCOUNT=/tmp/counts DYLD_INSERT_LIBRARIES=build/syscount.so server   (LD_PRELOAD on Linux)
//   build/syscount /tmp/counts [requests]    each count, and per request
//
// Counting starts at zero when SYSCOUNT's file is made; `build/syscount
// FILE 0` zeroes it again, so a warm-up can be left out.
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/uio.h>
#include <time.h>
#include <unistd.h>

__attribute__((unused)) static const char* names[] = {
    "read", "write", "readv", "writev", "recvfrom", "sendto", "sendmsg",
    "kevent", "epoll_wait", "epoll_ctl", "poll", "accept", "close", "clock_gettime",
};
enum { READ, WRITE, READV, WRITEV, RECVFROM, SENDTO, SENDMSG, KEVENT, EPOLL_WAIT, EPOLL_CTL, POLL, ACCEPT, CLOSE, CLOCK, CALLS };

#ifdef REPORT
int main(int argc, char** argv) {
    if (argc < 2) { fprintf(stderr, "usage: syscount FILE [requests]\n"); return 1; }
    int fd = open(argv[1], O_RDWR);
    if (fd < 0) { perror(argv[1]); return 1; }
    _Atomic long* n = mmap(NULL, CALLS * sizeof(long), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (n == MAP_FAILED) { perror("mmap"); return 1; }
    double reqs = argc > 2 ? atof(argv[2]) : -1;
    if (reqs == 0) { for (int i = 0; i < CALLS; i++) n[i] = 0; return 0; }
    for (int i = 0; i < CALLS; i++) {
        if (!n[i]) continue;
        if (reqs > 0) printf("%-14s %12ld  %.3f per request\n", names[i], (long)n[i], n[i] / reqs);
        else printf("%-14s %12ld\n", names[i], (long)n[i]);
    }
    return 0;
}
#else
static _Atomic long spare[CALLS];
static _Atomic long* counts = spare;

__attribute__((constructor)) static void mapped(void) {
    const char* path = getenv("SYSCOUNT");
    if (!path) return;
    int fd = open(path, O_RDWR | O_CREAT, 0644);
    if (fd < 0 || ftruncate(fd, CALLS * sizeof(long)) < 0) return;
    void* m = mmap(NULL, CALLS * sizeof(long), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (m != MAP_FAILED) counts = m;
}

#define COUNT(i) atomic_fetch_add_explicit(&counts[i], 1, memory_order_relaxed)

#ifdef __APPLE__
#include <sys/event.h>
#define INTERPOSE(ours, theirs) \
    __attribute__((used)) static struct { const void* a; const void* b; } interpose_##theirs \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)ours, (const void*)theirs }

static ssize_t c_read(int fd, void* b, size_t n) { COUNT(READ); return read(fd, b, n); }
static ssize_t c_write(int fd, const void* b, size_t n) { COUNT(WRITE); return write(fd, b, n); }
static ssize_t c_readv(int fd, const struct iovec* v, int n) { COUNT(READV); return readv(fd, v, n); }
static ssize_t c_writev(int fd, const struct iovec* v, int n) { COUNT(WRITEV); return writev(fd, v, n); }
static ssize_t c_recvfrom(int fd, void* b, size_t n, int f, struct sockaddr* a, socklen_t* l) { COUNT(RECVFROM); return recvfrom(fd, b, n, f, a, l); }
static ssize_t c_sendto(int fd, const void* b, size_t n, int f, const struct sockaddr* a, socklen_t l) { COUNT(SENDTO); return sendto(fd, b, n, f, a, l); }
static ssize_t c_sendmsg(int fd, const struct msghdr* m, int f) { COUNT(SENDMSG); return sendmsg(fd, m, f); }
static int c_kevent(int kq, const struct kevent* c, int nc, struct kevent* e, int ne, const struct timespec* t) { COUNT(KEVENT); return kevent(kq, c, nc, e, ne, t); }
static int c_accept(int fd, struct sockaddr* a, socklen_t* l) { COUNT(ACCEPT); return accept(fd, a, l); }
static int c_close(int fd) { COUNT(CLOSE); return close(fd); }
static int c_clock_gettime(clockid_t c, struct timespec* t) { COUNT(CLOCK); return clock_gettime(c, t); }

INTERPOSE(c_read, read);
INTERPOSE(c_write, write);
INTERPOSE(c_readv, readv);
INTERPOSE(c_writev, writev);
INTERPOSE(c_recvfrom, recvfrom);
INTERPOSE(c_sendto, sendto);
INTERPOSE(c_sendmsg, sendmsg);
INTERPOSE(c_kevent, kevent);
INTERPOSE(c_accept, accept);
INTERPOSE(c_close, close);
INTERPOSE(c_clock_gettime, clock_gettime);
#else
#include <dlfcn.h>
#include <poll.h>
#include <sys/epoll.h>
#define WRAP(ret, name, params, args, i)                                   \
    ret name params {                                                      \
        static ret (*real) params;                                         \
        if (!real) real = (ret (*) params)dlsym(RTLD_NEXT, #name);         \
        COUNT(i);                                                          \
        return real args;                                                  \
    }
WRAP(ssize_t, read, (int fd, void* b, size_t n), (fd, b, n), READ)
WRAP(ssize_t, write, (int fd, const void* b, size_t n), (fd, b, n), WRITE)
WRAP(ssize_t, readv, (int fd, const struct iovec* v, int n), (fd, v, n), READV)
WRAP(ssize_t, writev, (int fd, const struct iovec* v, int n), (fd, v, n), WRITEV)
WRAP(ssize_t, recvfrom, (int fd, void* b, size_t n, int f, struct sockaddr* a, socklen_t* l), (fd, b, n, f, a, l), RECVFROM)
WRAP(ssize_t, sendto, (int fd, const void* b, size_t n, int f, const struct sockaddr* a, socklen_t l), (fd, b, n, f, a, l), SENDTO)
WRAP(ssize_t, sendmsg, (int fd, const struct msghdr* m, int f), (fd, m, f), SENDMSG)
WRAP(int, epoll_wait, (int e, struct epoll_event* v, int n, int t), (e, v, n, t), EPOLL_WAIT)
WRAP(int, epoll_ctl, (int e, int op, int fd, struct epoll_event* v), (e, op, fd, v), EPOLL_CTL)
WRAP(int, poll, (struct pollfd* p, nfds_t n, int t), (p, n, t), POLL)
WRAP(int, accept, (int fd, struct sockaddr* a, socklen_t* l), (fd, a, l), ACCEPT)
WRAP(int, close, (int fd), (fd), CLOSE)
WRAP(int, clock_gettime, (clockid_t c, struct timespec* t), (c, t), CLOCK)
#endif
#endif
