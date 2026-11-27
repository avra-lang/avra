// The tick thread is born with every signal blocked: read back from the kernel the moment
// `avra_tick_armed` returns, before the new thread has had a turn of its own, in a fresh
// child each time, so a thread that blocks only once it runs is caught in its gap.
#if defined(__linux__)
#define _GNU_SOURCE
#endif
#include <dirent.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_platform.h"

#define CHILDREN 200

#if defined(__linux__)
// 1 when a thread of this process other than the caller blocks SIGTERM, 0 when one does not,
// -1 when no other thread stands.
static int other_blocks_term(void) {
    DIR* d = opendir("/proc/self/task");
    if (!d) return -1;
    int seen = -1;
    struct dirent* e;
    while ((e = readdir(d))) {
        if (e->d_name[0] == '.' || atoi(e->d_name) == getpid()) continue;
        char path[64];
        snprintf(path, sizeof path, "/proc/self/task/%s/status", e->d_name);
        FILE* f = fopen(path, "r");
        if (!f) continue;
        char line[256];
        while (fgets(line, sizeof line, f)) {
            unsigned long long blk;
            if (sscanf(line, "SigBlk: %llx", &blk) == 1) seen = (blk >> (SIGTERM - 1)) & 1 ? 1 : 0;
        }
        fclose(f);
        if (seen == 0) break;
    }
    closedir(d);
    return seen;
}

int main(void) {
    int open = 0, none = 0;
    for (int i = 0; i < CHILDREN; i++) {
        pid_t p = fork();
        if (p == 0) {
            avra_tick_armed();
            int seen = other_blocks_term();
            _exit(seen == 1 ? 0 : seen == 0 ? 1 : 2);
        }
        int st = 0;
        waitpid(p, &st, 0);
        int code = WIFEXITED(st) ? WEXITSTATUS(st) : 3;
        if (code == 1 || code == 3) open++;
        if (code == 2) none++;
    }
    if (open > 0 || none == CHILDREN) {
        fprintf(stderr, "tick_mask_test: FAILED — %d of %d ticks could take a TERM before they ran, %d stood up no thread\n", open, CHILDREN, none);
        return 1;
    }
    printf("tick_mask_test: %d ticks, each born with SIGTERM blocked\n", CHILDREN - none);
    return 0;
}
#else
int main(void) {
    printf("tick_mask_test: no /proc here — the mask is read on Linux\n");
    return 0;
}
#endif
