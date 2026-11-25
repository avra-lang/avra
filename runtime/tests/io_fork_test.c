// A temp across a fork: the child never writes through its parent's temp.
// Linked with std-io's object (Makefile), the one runtime test that reaches
// a package's C.
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

int64_t avra_io_temp(const char* path);
int64_t avra_io_temp_fd(int64_t h);

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "io_fork_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

int main(void) {
    char target[] = "/tmp/avra-io-fork-target-XXXXXX";
    char mine[] = "/tmp/avra-io-fork-mine-XXXXXX";
    close(mkstemp(target));
    close(mkstemp(mine));
    int64_t h = avra_io_temp(target);
    CHECK(h >= 0, "a temp opens");
    pid_t pid = fork();
    if (pid == 0) {
        for (int fd = 3; fd < 256; fd++) close(fd);
        for (int i = 0; i < 64; i++) open(mine, O_RDWR);
        int64_t fd = avra_io_temp_fd(h);
        if (fd >= 0) (void)!write((int)fd, "x", 1);
        _exit(0);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    struct stat st;
    stat(mine, &st);
    CHECK(WIFEXITED(status) && st.st_size == 0, "a child never writes through its parent's temp");
    unlink(mine);
    unlink(target);
    fprintf(stderr, "io_fork: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails == 0 ? 0 : 1;
}
