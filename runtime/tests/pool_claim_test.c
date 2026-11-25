// The pool's claims, attacked: two runs each needing most of a small pool both finish, one after
// the other, rather than each holding part of it and waiting for the rest; and two runs each
// holding half the pool and each wanting one more end their deadlock at once, the one holding the
// least refusing so the other finishes.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

int64_t avra_pool_allowed(int64_t in_use);
int64_t avra_pool_free_bytes(void);

enum { SLOT = 256 << 20, ROUNDS = 10 };

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "pool_claim_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// A run that waits at `gate`, then asks for three of the pool's four slots at once and holds them
// a moment: 0 when it got them, 1 when it was refused.
static int needs_most(int gate) {
    char go;
    if (read(gate, &go, 1) != 1) return 3;
    int64_t want = avra_pool_free_bytes() + 3 * (int64_t)SLOT - SLOT / 2;
    if (avra_pool_allowed(want) < want) return 1;
    usleep(300 * 1000);
    return 0;
}

// A run that holds `holding` slots, says so on `said`, waits at `gate`, then asks for one more and
// holds it a moment: 0 when it got it, 2 when it ended a deadlock, 1 when it was refused otherwise.
static int holds_then_grows(int holding, int said, int gate) {
    int64_t held = avra_pool_free_bytes() + holding * (int64_t)SLOT - SLOT / 2;
    if (avra_pool_allowed(held) < held) return 3;
    (void)!write(said, "h", 1);
    char go;
    if (read(gate, &go, 1) != 1) return 3;
    int64_t want = held + SLOT;
    int64_t allowed = avra_pool_allowed(want);
    if (allowed == -3) return 2;
    if (allowed < want) return 1;
    usleep(300 * 1000);
    return 0;
}

// One deadlock between a run holding `first` slots and one holding `second`: each run's exit code.
static void deadlocked(int first, int second, int codes[2]) {
    int said[2], gate[2];
    if (pipe(said) != 0 || pipe(gate) != 0) exit(1);
    int holding[2] = { first, second };
    pid_t runs[2];
    for (int i = 0; i < 2; i++) {
        runs[i] = fork();
        if (runs[i] == 0) { close(said[0]); close(gate[1]); _exit(holds_then_grows(holding[i], said[1], gate[0])); }
    }
    close(said[1]);
    close(gate[0]);
    char held[2];
    int got = 0;
    while (got < 2) {
        ssize_t n = read(said[0], held + got, (size_t)(2 - got));
        if (n <= 0) break;
        got += (int)n;
    }
    (void)!write(gate[1], "gg", 2);
    close(gate[1]);
    close(said[0]);
    for (int i = 0; i < 2; i++) {
        int status = 0;
        waitpid(runs[i], &status, 0);
        codes[i] = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }
}

int main(void) {
    char dir[] = "/tmp/avra-pool-claim-XXXXXX";
    if (!mkdtemp(dir)) return 1;
    setenv("AVRA_MEM_POOL_DIR", dir, 1);
    setenv("AVRA_MEM_POOL_MB", "1024", 1);
    setenv("AVRA_MEM_POOL_WAIT_MS", "2000", 1);
    int finished = 0;
    for (int round = 0; round < ROUNDS; round++) {
        int gate[2];
        if (pipe(gate) != 0) return 1;
        pid_t runs[2];
        for (int i = 0; i < 2; i++) {
            runs[i] = fork();
            if (runs[i] == 0) { close(gate[1]); _exit(needs_most(gate[0])); }
        }
        close(gate[0]);
        (void)!write(gate[1], "gg", 2);
        close(gate[1]);
        int both = 1;
        for (int i = 0; i < 2; i++) {
            int status = 0;
            waitpid(runs[i], &status, 0);
            if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) both = 0;
        }
        finished += both;
    }
    CHECK(finished == ROUNDS, "two runs each needing most of the pool both finish, every round");
    setenv("AVRA_MEM_POOL_WAIT_MS", "60000", 1);
    int codes[2];
    deadlocked(2, 2, codes);
    CHECK((codes[0] == 0 && codes[1] == 2) || (codes[0] == 2 && codes[1] == 0),
          "two runs each holding half the pool and wanting one more: exactly one ends the deadlock, the other finishes");
    setenv("AVRA_MEM_POOL_MB", "1280", 1);
    deadlocked(3, 2, codes);
    CHECK(codes[0] == 0 && codes[1] == 2, "the run holding the least of a deadlocked pool is the one that ends it");
    fprintf(stderr, "pool_claim: %d checks, %d failed (%d of %d rounds both finished)\n", g_checks, g_fails, finished, ROUNDS);
    return g_fails == 0 ? 0 : 1;
}
