// THE TERMINAL ROWS, over a pseudo-terminal: its size, its mode, and what a
// process leaves it as however the process ends — a normal exit, a trap's
// exit, a terminating signal, a fault — and that disarming leaves nothing.
#define _XOPEN_SOURCE 600
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

extern int64_t avra_fd_tty_size(int64_t fd);
extern int64_t avra_fd_tty_raw(int64_t fd, int64_t on);
extern void avra_fd_exit_writes(int64_t fd, const char* bytes);
extern void avra_sig_raise(int64_t kind);
extern const char* avra_bytes_adopted(const void* p, int64_t n);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "tty_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static int signals(int fd) {
    struct termios t;
    return tcgetattr(fd, &t) == 0 && (t.c_lflag & ISIG);
}

static int cooked(int fd) {
    struct termios t;
    return tcgetattr(fd, &t) == 0 && (t.c_lflag & ICANON) && (t.c_lflag & ECHO);
}

static const char* bytes_of(const char* s) { return avra_bytes_adopted(s, (int64_t)strlen(s)); }

enum { QUIET, EXIT0, TRAP_EXIT, TERM, FAULT, DISARMED, INTERRUPT, RAISED };

// A child that raises the terminal's mode and arms its parting bytes, then
// ends the way `how` says. Answers its wait status.
static int child_ends(int slave, int how) {
    pid_t pid = fork();
    if (pid == 0) {
        avra_fd_tty_raw(slave, how == INTERRUPT ? 2 : 1);
        avra_fd_exit_writes(slave, bytes_of("<BYE>"));
        if (how == DISARMED) avra_fd_exit_writes(slave, bytes_of(""));
        if (how == TERM) raise(SIGTERM);
        if (how == RAISED) avra_sig_raise(1);
        if (how == FAULT) raise(SIGSEGV);
        if (how == TRAP_EXIT) exit(2);
        exit(0);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    return status;
}

static int master_holds(int master, const char* what) {
    char buf[256];
    size_t have = 0;
    for (int tries = 0; tries < 50; tries++) {
        ssize_t got = read(master, buf + have, sizeof buf - 1 - have);
        if (got > 0) have += (size_t)got;
        buf[have] = 0;
        if (strstr(buf, what)) return 1;
        usleep(2000);
    }
    return 0;
}

int main(void) {
    signal(SIGINT, SIG_DFL);   // a background shell starts its jobs ignoring it, and an ignored signal is left so
    int master = posix_openpt(O_RDWR | O_NOCTTY);
    if (master < 0 || grantpt(master) != 0 || unlockpt(master) != 0) { perror("pty"); return 1; }
    int slave = open(ptsname(master), O_RDWR | O_NOCTTY);
    if (slave < 0) { perror("pty slave"); return 1; }
    fcntl(master, F_SETFL, O_NONBLOCK);

    struct winsize ws = { .ws_row = 30, .ws_col = 100 };
    ioctl(master, TIOCSWINSZ, &ws);
    CHECK(avra_fd_tty_size(slave) == 100 * 65536 + 30, "a terminal says its columns and lines");
    int quiet[2];
    if (pipe(quiet) != 0) { perror("pipe"); return 1; }
    CHECK(avra_fd_tty_size(quiet[0]) == 0, "a pipe has no size");
    CHECK(avra_fd_tty_raw(quiet[0], 1) == 0, "a pipe cannot be raw");
    struct winsize none = { 0, 0, 0, 0 };
    ioctl(master, TIOCSWINSZ, &none);
    CHECK(avra_fd_tty_size(slave) == 0, "a terminal of no size says none");
    ioctl(master, TIOCSWINSZ, &ws);

    CHECK(cooked(slave), "a fresh terminal is cooked");
    CHECK(avra_fd_tty_raw(slave, 1) == 1, "cbreak mode is entered");
    struct termios t;
    tcgetattr(slave, &t);
    CHECK(!(t.c_lflag & (ICANON | ECHO)) && (t.c_oflag & OPOST), "cbreak: keys unechoed and unbuffered, output processing kept");
    CHECK(signals(slave), "cbreak keeps Ctrl-C a signal");
    CHECK(avra_fd_tty_raw(slave, 1) == 1, "cbreak twice is cbreak");
    CHECK(avra_fd_tty_raw(slave, 0) == 1, "cbreak mode is left");
    CHECK(cooked(slave), "the mode saved is the mode given back");
    CHECK(avra_fd_tty_raw(slave, 0) == 0, "leaving twice changes nothing");
    CHECK(avra_fd_tty_raw(slave, 2) == 1, "raw mode is entered");
    tcgetattr(slave, &t);
    CHECK(!(t.c_lflag & (ICANON | ECHO | ISIG)) && (t.c_oflag & OPOST), "raw: the signal keys arrive as keys, output processing kept");
    CHECK(avra_fd_tty_raw(slave, 0) == 1 && cooked(slave), "raw is given back too");

    // however a process ends, its bytes are on the terminal and its mode is back
    int s = child_ends(slave, EXIT0);
    CHECK(WIFEXITED(s) && WEXITSTATUS(s) == 0, "a normal exit stays 0");
    CHECK(master_holds(master, "<BYE>"), "a normal exit leaves its bytes");
    CHECK(cooked(slave), "a normal exit gives the mode back");

    s = child_ends(slave, TRAP_EXIT);
    CHECK(WIFEXITED(s) && WEXITSTATUS(s) == 2, "a trap's exit stays 2");
    CHECK(master_holds(master, "<BYE>"), "a trap's exit leaves its bytes");
    CHECK(cooked(slave), "a trap's exit gives the mode back");

    s = child_ends(slave, TERM);
    CHECK(WIFSIGNALED(s) && WTERMSIG(s) == SIGTERM, "a terminating signal still ends the process by it");
    CHECK(master_holds(master, "<BYE>"), "a terminating signal leaves its bytes");
    CHECK(cooked(slave), "a terminating signal gives the mode back");

    s = child_ends(slave, RAISED);
    CHECK(WIFSIGNALED(s) && WTERMSIG(s) == SIGINT, "a raised SIGINT ends the process by it, as one from outside would");
    CHECK(master_holds(master, "<BYE>"), "a raised SIGINT leaves its bytes");
    CHECK(cooked(slave), "a raised SIGINT gives the mode back");

    s = child_ends(slave, FAULT);
    CHECK(WIFSIGNALED(s) && WTERMSIG(s) == SIGSEGV, "a fault still ends the process by it");
    CHECK(master_holds(master, "<BYE>"), "a fault leaves its bytes");
    CHECK(cooked(slave), "a fault gives the mode back");

    // under cbreak SIGINT is still a signal the process dies by, and the bytes
    // and the mode are still restored
    {
        pid_t pid = fork();
        if (pid == 0) {
            avra_fd_tty_raw(slave, 1);
            avra_fd_exit_writes(slave, bytes_of("<BYE>"));
            for (;;) pause();
        }
        usleep(100000);
        kill(pid, SIGINT);
        int st = 0;
        waitpid(pid, &st, 0);
        CHECK(WIFSIGNALED(st) && WTERMSIG(st) == SIGINT, "SIGINT still ends a cbreak process by it");
        CHECK(master_holds(master, "<BYE>"), "SIGINT leaves its bytes");
        CHECK(cooked(slave), "SIGINT gives the mode back");
    }

    s = child_ends(slave, DISARMED);
    CHECK(WIFEXITED(s) && WEXITSTATUS(s) == 0, "a disarmed exit is a normal one");
    CHECK(!master_holds(master, "<BYE>"), "empty bytes disarm what was armed");
    CHECK(cooked(slave), "disarmed bytes still give the mode back");

    printf("tty: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}
