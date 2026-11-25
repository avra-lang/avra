// MEMORY PER PARKED TASK in C: n threads block on one condition variable,
// the resident set is read from the process's own status, then the threads
// are released and joined. Prints bytes per parked task and the count.
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int env_int(const char* name, int fallback) {
    const char* v = getenv(name);
    return v && *v ? atoi(v) : fallback;
}

static long rss_bytes(void) {
    FILE* f = fopen("/proc/self/status", "r");
    if (!f) return 0;
    char line[256];
    long kb = 0;
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, "VmRSS:", 6) == 0) {
            sscanf(line + 6, "%ld", &kb);
            break;
        }
    }
    fclose(f);
    return kb * 1024;
}

static pthread_mutex_t pm = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t pc = PTHREAD_COND_INITIALIZER;
static int released;

static void* park(void* p) {
    pthread_mutex_lock(&pm);
    while (!released) pthread_cond_wait(&pc, &pm);
    pthread_mutex_unlock(&pm);
    return (void*)(intptr_t)1;
}

int main(void) {
    int n = env_int("BENCH_N", 10000);
    pthread_t* ts = malloc(sizeof(pthread_t) * n);
    long before = rss_bytes();
    for (int i = 0; i < n; i++) pthread_create(&ts[i], NULL, park, NULL);
    // Give every thread a turn to reach its wait, then read the growth.
    struct timespec nap = {0, 50 * 1000 * 1000};
    nanosleep(&nap, NULL);
    long after = rss_bytes();
    long per = n ? (after - before) / n : 0;
    pthread_mutex_lock(&pm);
    released = 1;
    pthread_cond_broadcast(&pc);
    pthread_mutex_unlock(&pm);
    long sum = 0;
    for (int i = 0; i < n; i++) {
        void* out;
        pthread_join(ts[i], &out);
        sum += (long)(intptr_t)out;
    }
    free(ts);
    printf("parked_bytes\t%ld\tbytes\t1\n", per);
    printf("parked_n\t%d\tops\t1\n", n);
    (void)sum;
    return 0;
}
