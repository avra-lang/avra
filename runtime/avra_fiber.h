// The scheduler's rows: tasks on fibers, one OS thread, switched only
// where a task waits. A separate object in the runtime library, so a
// program that never spawns, parks or sleeps links none of it.
#ifndef AVRA_FIBER_H
#define AVRA_FIBER_H

#include <stdint.h>

// A new task running the closure box `body` (`[code, captures…]`,
// called with the box at seat 0, answering one managed box — the
// compiler's task lift puts the value in a one-cell list). Keeps
// `body`; answers the task, owned. The spawner runs on.
void* avra_task_spawn(void* body);

// An owner's scope ended: the task joined, its answer not kept.
void avra_task_settle(void* task);
// The same for every task in a list.
void avra_task_settle_all(void* list);

// `task` joins the `Tasks` owner, which keeps its own reference; a full
// owner first sheds the tasks that have finished.
void avra_tasks_push(void* owner, void* task);

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

// A `within`'s scope opens: the calling task's deadline narrows to
// `ms` from now (never widens) for every park until it ends. Answers
// the outer deadline, which `avra_fiber_within_end` restores.
int64_t avra_fiber_within(int64_t ms);
void avra_fiber_within_end(int64_t outer);

// 1 when a read (`writing` 0) or write (1) on `fd` may find something —
// always, until a task has waited on it; 0 once a read found it drained
// or a task parked on it, until the next edge. A reader that sees 0
// parks before reading, and saves the syscall that would find nothing.
int64_t avra_fiber_fd_ready(int64_t fd, int64_t writing);

// `fd` is about to close: every task parked on it is ready, and its
// retry reports the closed descriptor. A close never strands a waiter,
// and the number's next tenant inherits none.
void avra_fiber_fd_closing(int64_t fd);

// Every task parked reading `fd` wakes as if its `within` ran out; the
// descriptor stays open, registered, and unread.
void avra_fiber_fd_interrupt(int64_t fd);

// The caller is a FORKED CHILD, and the calling task is all it keeps:
// no other task runs again, and the poller — the parent's own under
// epoll, not inherited under kqueue — opens afresh at the next park.
void avra_fiber_forked(void);

// ── The evaluator's tasks: no stack; the policy above files them and
// names the next, and the evaluator switches its own call stacks. ──

// A new task, filed nowhere until readied or parked.
int64_t avra_vtask_new(void);
void avra_vtask_free(int64_t t);
void avra_vtask_ready(int64_t t);
void avra_vtask_sleep(int64_t t, int64_t ms);
// 1 when parked; 0 when it did not wait: the descriptor cannot be
// watched (ready at once, so its read or write reports the error), or
// the task's deadline has passed (`avra_vtask_timed_out` says 1).
int64_t avra_vtask_park_fd(int64_t t, int64_t fd, int64_t writable, int64_t timeout_ms);
int64_t avra_vtask_timed_out(int64_t t);
int64_t avra_vtask_within(int64_t t, int64_t ms);
void avra_vtask_within_end(int64_t t, int64_t outer);
int64_t avra_vtask_deadline(int64_t t);
// The next task to run, waiting on the world as long as it takes; a
// world with nothing to wait on and nothing ready traps, deadlocked.
int64_t avra_vtask_next(void);

#endif
