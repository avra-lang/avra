// Two tasks that hand the thread to each other through the host's `switch`,
// as the scheduler does — the smallest module that tells the two hosts apart
// from the language. Freestanding: no libc, no scheduler. As the scheduler
// does, it exports neither fn and hands the host their table indices.
#include <stdint.h>

__attribute__((import_module("avra_host"), import_name("switch")))
extern void host_switch(void* from, void* to, int32_t ends, void* entry, void* buffers);
__attribute__((import_module("avra_host"), import_name("idle")))
extern void host_idle(int64_t ns, void* buffers);

static int log_at = 0;
static int log_words[16];
static void note(int v) { log_words[log_at++] = v; }

#define MAIN ((void*)1)
#define OTHER ((void*)2)

static char arena[1 << 20];
static int arena_at = 0;
void* avra_asyncify_buffer(int bytes) {
    void* p = &arena[arena_at];
    arena_at += bytes;
    return p;
}

// the second task: it runs when handed the thread and ends handing it back
void avra_task_entry(void) {
    note(2);
    host_switch(OTHER, MAIN, 0, (void*)avra_task_entry, (void*)avra_asyncify_buffer);
    note(4);
    host_switch(OTHER, MAIN, 1, (void*)avra_task_entry, (void*)avra_asyncify_buffer);
}

// the first task: ping-pong, a wait of the world, and an answer
__attribute__((export_name("run"))) int run(int k) {
    note(1);
    host_switch(MAIN, OTHER, 0, (void*)avra_task_entry, (void*)avra_asyncify_buffer);
    note(3);
    host_switch(MAIN, OTHER, 0, (void*)avra_task_entry, (void*)avra_asyncify_buffer);
    note(5);
    host_idle(1000000, (void*)avra_asyncify_buffer);
    note(6);
    return k + 1;
}

__attribute__((export_name("log_at"))) int get_log_at(void) { return log_at; }
__attribute__((export_name("log_word"))) int get_log_word(int i) { return log_words[i]; }
