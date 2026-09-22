// The scheduler's rows: tasks on fibers, one OS thread, switched only
// where a task waits. A separate object in the runtime library, so a
// program that never spawns, parks or sleeps links none of it.
#ifndef AVRA_FIBER_H
#define AVRA_FIBER_H

#include <stdint.h>

// A new task running the closure box `body` (`[code, captures…]`,
// called with the box at seat 0 and answering one managed box).
// Keeps `body`; answers the task, owned. The spawner runs on.
void* avra_task_spawn(void* body);

// The task's answer, owned — parking the caller until it is done.
void* avra_task_join(void* task);

// 1 when the task has answered, else 0. Never parks.
int64_t avra_task_done(void* task);

// Every other ready task runs once before the caller resumes.
void avra_fiber_yield(void);

// Parks the caller for `ms` milliseconds; below one, a yield.
void avra_fiber_sleep(int64_t ms);

// Parks the caller until `fd` is readable (`writable` 0) or writable
// (`writable` 1), or `timeout_ms` passes (below zero: never). 1 when
// the descriptor may be ready — a caller retries its read or write —
// and 0 when the time ran out.
int64_t avra_fiber_park_fd(int64_t fd, int64_t writable, int64_t timeout_ms);

#endif
