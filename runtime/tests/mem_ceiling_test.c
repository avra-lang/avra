// THE MEMORY CEILING: live bytes past AVRA_MEM_CEILING_MB trap with
// status 2 and the words naming the variable; 0 turns it off. The
// ceiling is read at load, so each case re-executes this binary with
// its own environment and a role word.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_runtime.h"

void* avra_array_new(void);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "mem_ceiling_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// Pushes until `mb` megabytes of list buffer are live, then exits 0.
static int grow(int64_t mb) {
    void* xs = avra_array_new();
    for (int64_t i = 0; i < (mb << 20) / 8; i++) avra_array_push(xs, i);
    return 0;
}

// This binary, rerun with the ceiling set and a role; its status and stderr.
static int run_as(const char* self, const char* ceiling, const char* role, char* err, size_t cap) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        if (ceiling) setenv("AVRA_MEM_CEILING_MB", ceiling, 1); else unsetenv("AVRA_MEM_CEILING_MB");
        execl(self, self, role, (char*)NULL);
        _exit(127);
    }
    close(out[1]);
    size_t got = 0;
    for (ssize_t n; got < cap - 1 && (n = read(out[0], err + got, cap - 1 - got)) > 0;) got += (size_t)n;
    err[got] = 0;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

int main(int argc, char** argv) {
    // bounded, so a ceiling that never fires fails with 3, never with the machine
    if (argc > 1 && strcmp(argv[1], "forever") == 0) { grow(1024); return 3; }
    if (argc > 1 && strcmp(argv[1], "grow64") == 0) return grow(64);
    char err[512];

    int s = run_as(argv[0], "32", "forever", err, sizeof err);
    CHECK(s == 2, "1 GB live under a 32 MB ceiling exits 2, never 3");
    CHECK(strstr(err, "avra: memory ceiling exceeded: 32 MB (AVRA_MEM_CEILING_MB)") != NULL,
          "the trap names the ceiling and its variable");

    s = run_as(argv[0], "0", "grow64", err, sizeof err);
    CHECK(s == 0, "a ceiling of 0 is off: 64 MB live runs clean");

    s = run_as(argv[0], NULL, "grow64", err, sizeof err);
    CHECK(s == 0, "the default ceiling admits 64 MB live");

    s = run_as(argv[0], "32", "grow64", err, sizeof err);
    CHECK(s == 2, "64 MB live under a 32 MB ceiling exits 2");

    if (g_fails) { fprintf(stderr, "mem_ceiling_test: %d of %d checks failed\n", g_fails, g_checks); return 1; }
    printf("mem_ceiling_test: %d checks passed\n", g_checks);
    return 0;
}
