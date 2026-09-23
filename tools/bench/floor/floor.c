// The kernel's floor for the bench's workload: one thread, epoll
// edge-triggered, every request answered with the same bytes the Avra
// server writes, no parsing beyond counting request terminators. What an
// HTTP server on this host cannot beat without fewer syscalls.
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

static const char reply[] =
    "HTTP/1.1 200 OK\r\ncontent-type: text/plain; charset=utf-8\r\ncontent-length: 5\r\n\r\nhello";

int main(void) {
    int l = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);
    int on = 1;
    setsockopt(l, SOL_SOCKET, SO_REUSEADDR, &on, sizeof on);
    struct sockaddr_in a = { .sin_family = AF_INET, .sin_port = htons(18080), .sin_addr.s_addr = htonl(INADDR_LOOPBACK) };
    if (bind(l, (struct sockaddr*)&a, sizeof a) || listen(l, 511)) return 1;
    int ep = epoll_create1(0);
    struct epoll_event ev = { .events = EPOLLIN, .data.fd = l };
    epoll_ctl(ep, EPOLL_CTL_ADD, l, &ev);
    struct epoll_event evs[256];
    static char buf[16384], out[16 * sizeof reply];
    for (;;) {
        int n = epoll_wait(ep, evs, 256, -1);
        for (int i = 0; i < n; i++) {
            int fd = evs[i].data.fd;
            if (fd == l) {
                int c;
                while ((c = accept4(l, NULL, NULL, SOCK_NONBLOCK)) >= 0) {
                    setsockopt(c, IPPROTO_TCP, TCP_NODELAY, &on, sizeof on);
                    struct epoll_event ce = { .events = EPOLLIN | EPOLLET, .data.fd = c };
                    epoll_ctl(ep, EPOLL_CTL_ADD, c, &ce);
                }
                continue;
            }
            for (;;) {
                ssize_t got = read(fd, buf, sizeof buf);
                if (got <= 0) { if (got == 0 || errno != EAGAIN) close(fd); break; }
                int reqs = 0;
                for (ssize_t j = 3; j < got; j++) reqs += buf[j] == '\n' && buf[j - 1] == '\r' && buf[j - 2] == '\n';
                size_t len = 0;
                for (int k = 0; k < reqs && k < 16; k++) { memcpy(out + len, reply, sizeof reply - 1); len += sizeof reply - 1; }
                if (len && write(fd, out, len) < 0) { close(fd); break; }
                if ((size_t)got < sizeof buf) break;
            }
        }
    }
}
