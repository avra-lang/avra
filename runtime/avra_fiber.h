// The scheduler's rows: tasks on fibers, one OS thread, switched only
// where a task waits. A separate object in the runtime library, so a
// program that never spawns, parks or sleeps links none of it.
#ifndef AVRA_FIBER_H
#define AVRA_FIBER_H

#include <stdint.h>
#include <stdio.h>

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
// How a task ended: 0 live, 1 answered, 2 cancelled.
int64_t avra_task_ended(void* task);
// THE RUNNING TASK'S UNWIND BIT: set where a cancel meets a cancel point,
// and read after every call that may reach one. A switch saves it into
// the task it leaves and loads the next task's.
extern uint8_t avra_unwinding;

// Every other ready task runs once before the caller resumes.
void avra_fiber_yield(void);

// Parks the caller for `ms` milliseconds; below one, a yield.
void avra_fiber_sleep(int64_t ms);

// Parks the caller until `fd` is readable (`writable` 0) or writable
// (`writable` 1), or `timeout_ms` passes (below zero: never). 1 when
// the descriptor may be ready — a caller retries its read or write —
// and 0 when the time ran out or the park was interrupted.
int64_t avra_fiber_park_fd(int64_t fd, int64_t writable, int64_t timeout_ms);
// Whether the caller's last descriptor park ended by an interrupt.
int64_t avra_fiber_interrupted(void);

// ── The wait set ────────────────────────────────────────────────
//
// A task registers what it waits on, then parks ONCE: the first source
// to claim the set wakes it and the park answers that source's `arm`
// and `member`; every other waiter is taken back. A row that registers
// runs between a task's own test and its park, and nothing else runs
// there.

// The caller also waits for `fd` to be readable (`writable` 0) or
// writable (1) — having read or written and found nothing, as the
// descriptor park asks. One the poller cannot watch claims at once.
void avra_wait_fd(int64_t fd, int64_t writable, int64_t arm, int64_t member);
// … for the scheduler's clock (`avra_now_ns`) to reach `at_ns`.
void avra_wait_until(int64_t at_ns, int64_t arm, int64_t member);
// … for `gate` to claim it. The gate is kept while the waiter is filed.
// An open gate claims at once.
void avra_wait_gate(void* gate, int64_t arm, int64_t member);
// … for `task` to end.
void avra_wait_task(void* task, int64_t arm, int64_t member);
// Parks the caller on what it registered and answers the claim:
// `arm << 32 | member`. Arm -1 is the scheduler's: member 0 a cancel,
// member 1 the task's deadline. A claim made while the set was arming
// is answered without a switch; then a cancel that stands; then a
// deadline that has passed.
int64_t avra_wait_park(void);

// A gate: a queue of waiters in memory, owned.
void* avra_gate_new(void);
// Claims the first waiter whose set nothing has claimed, readies its
// task and answers the waiter's `member`; -1 when no one waits.
int64_t avra_gate_claim(void* gate);

// A task nothing runs, owned: `avra_task_answer` ends it.
void* avra_task_pending(void);
// One the timer heap ends, with no answer, at `at_ns`.
void* avra_task_at(int64_t at_ns);
// Ends a fiberless task with the answer `v` (kept) and claims its
// waiters. A task answers once: twice is a trap.
void avra_task_answer(void* task, void* v);
// Records a cancel on the task and claims its set when nothing has —
// a claim is never displaced: the task resumes on its arm and hears the
// cancel at its next cancel point. A sleep and a descriptor park are
// cut; a join is cut and traps. A fiberless task ends, unanswered.
void avra_task_cancel(void* task);

// A `within`'s scope opens on the calling task with its own limit, `ms`
// from now, and answers the scope's id — process-unique, never a task's.
// The task's deadline is the earliest limit of its scopes; the scope
// holding it OWNS it, the outer one on a tie.
int64_t avra_fiber_within(int64_t ms);
// The innermost scope, `id`, ends (any other traps by name): 1 when the
// request that stands is this scope's, which then stands no longer.
int64_t avra_scope_end(int64_t id);
void avra_fiber_within_end(int64_t id);
// The task's standing request: 0 for none (or a task that has ended), a
// scope's id when its limit passed, else 1 + the id of the task that
// cancelled it. ONE STANDS: a task's cancel outranks any scope, an outer
// scope an inner one. A deadline's request claims a park as its time
// (`-1:1`) and sets no unwind bit: no code can land it yet.
int64_t avra_task_request(void* task);

// 1 when a read (`writing` 0) or write (1) on `fd` may find something —
// always, until a task has waited on it; 0 once a read found it drained
// or a task parked on it, until the next edge. A reader that sees 0
// parks before reading, and saves the syscall that would find nothing.
int64_t avra_fiber_fd_ready(int64_t fd, int64_t writing);

// `fd` is about to close: every task parked on it is ready, and its
// retry reports the closed descriptor. A close never strands a waiter,
// and the number's next tenant inherits none.
void avra_fiber_fd_closing(int64_t fd);

// Every task parked reading `fd` wakes on a claim of its own, `-1:2` —
// no deadline, no cancel: a descriptor park answers 0 and says it was
// interrupted. The descriptor stays open, registered, and unread.
void avra_fiber_fd_interrupt(int64_t fd);

// The caller is a FORKED CHILD, and the calling task is all it keeps:
// no other task runs again, and the poller — the parent's own under
// epoll, not inherited under kqueue — opens afresh at the next park.
void avra_fiber_forked(void);

// ── The evaluator's tasks: no stack; the policy above files them and
// names the next, and the evaluator switches its own call stacks. ──

// A new task, filed nowhere until readied or parked; `site` is where it
// was spawned, for the trace.
int64_t avra_vtask_new(void);
// The same, under the id its machine counts it by: what the trace and
// every claimant's name for it read.
int64_t avra_vtask_new_at(int64_t site, int64_t id);
void avra_vtask_free(int64_t t);
// A task whose body answered: the trace says so, then it is freed.
void avra_vtask_end(int64_t t);
// Where the task's body was written, `file:line`, for the trace.
void avra_vtask_sited(int64_t t, const char* site);
void avra_vtask_ready(int64_t t);
// Every live task, one line each — who, where it was spawned, what it
// waits on, how long it has run at most. `avra tasks <pid>` reads it
// through the signal door; a target with no signals calls it directly.
void avra_tasks_listed(FILE* out);
// A join in the evaluator's own files, said to the trace as a compiled
// one is: `joins` when the task is about to wait for the task `on`
// (negative: one nothing runs), `joined` when `by`'s end readies it.
void avra_vtask_joins(int64_t t, int64_t on);
void avra_vtask_joined(int64_t t, int64_t by);
void avra_vtask_sleep(int64_t t, int64_t ms);
// 1 when parked; 0 when it did not wait: the descriptor cannot be
// watched (ready at once, so its read or write reports the error), or
// the task's deadline has passed (`avra_vtask_timed_out` says 1).
int64_t avra_vtask_park_fd(int64_t t, int64_t fd, int64_t writable, int64_t timeout_ms);
int64_t avra_vtask_timed_out(int64_t t);
int64_t avra_vtask_interrupted(int64_t t);
int64_t avra_vtask_within(int64_t t, int64_t ms);
void avra_vtask_within_end(int64_t t, int64_t id);
// The task's deadline, in ns; 0 when none.
int64_t avra_vtask_deadline(int64_t t);
// The new task `t` takes the limit `from` stands under, as a compiled
// spawn does.
void avra_vtask_inherits(int64_t t, int64_t from);
// The wait set, for the task `t`. `avra_vtask_park` answers 1 when the
// task is parked — the policy names it once it is claimed — and 0 when
// its set is claimed already; either way `avra_vtask_claim` reads the
// claim and takes the losers back.
void avra_vtask_wait_fd(int64_t t, int64_t fd, int64_t writable, int64_t arm, int64_t member);
void avra_vtask_wait_until(int64_t t, int64_t at_ns, int64_t arm, int64_t member);
void avra_vtask_wait_gate(int64_t t, void* gate, int64_t arm, int64_t member);
// `t` joins `task`, parked as a compiled join parks: on the task's own
// gate, heeding no cancel and no deadline, readied where the task ends —
// by the timer heap, for a task its time ends. 1 parked; 0 when the task
// has ended already.
int64_t avra_vtask_join(int64_t t, void* task);
int64_t avra_vtask_park(int64_t t);
int64_t avra_vtask_claim(int64_t t);
// A cancel on `t`, asked by the task whose id is `by`.
void avra_vtask_cancel(int64_t t, int64_t by);
// The gate stands open for ever: every waiter is claimed, and a later
// wait on it is claimed at once — what a finished task's gate does.
void avra_vgate_open(void* gate);
// `avra_gate_claim`, made by the task `t`: the claimed waiter's member,
// or -1.
int64_t avra_vgate_claim(int64_t t, void* gate);

// The next task to run, waiting on the world as long as it takes; a
// world with nothing to wait on and nothing ready traps, deadlocked.
int64_t avra_vtask_next(void);

// THE ORDER IS SEEDED from now: at every switch with more than one task
// ready, which runs is a CHOICE the schedule makes. Schedule 0 always
// takes the queue's head — the unseeded order, its choices counted —
// and any other draws from its own number, so one schedule is one order,
// for a compiled program's tasks and the evaluator's alike. A run that
// never calls this is untouched.
void avra_sched_seed(int64_t schedule);
// A RUN INSIDE ANOTHER PROGRAM — the evaluator's, in the compiler's own
// process — HAS ITS OWN SCHEDULE AND ITS OWN CLOCK. It begins unseeded,
// on its host's clock; a seed it takes, a clock it turns virtual and
// every jump it makes end with it, and its host's stand again exactly
// as they stood.
void avra_sched_run_begins(void);
void avra_sched_run_ends(void);
// The seeded run ends and the order is the queue's own again: how many
// choices it made. None means the run has one order.
int64_t avra_sched_settle(void);

// A CASE IN ITS OWN TASK: `body` runs as a task on a stack the size of
// the main thread's, and the caller — the runner — waits on its end.
// Answers what the body answered, or 0 when the case DEADLOCKED (every
// task waiting and nothing able to wake one: each is named with what it
// waits on) or LEAKED (a task it made outlived it: each is named). The
// tasks are then abandoned — no `defer` runs — so the next case begins
// with none. Outside a case, a deadlock is the trap it always was.
int64_t avra_case_run(int64_t (*body)(void));
// THE RUNNER'S VERDICT ON ONE CASE: `code` is the case's body (no
// arguments, answering bool), run through `avra_case_run` under
// schedule 0, then — only if it made a choice — under schedules 1, 2, …
// up to AVRA_SCHED_RUNS (1 until time is virtual). The first schedule that fails is named on
// stderr with the number that replays it; AVRA_SCHED_SEED=<k> runs
// schedule k alone. Each schedule runs on a VIRTUAL CLOCK of its own,
// or the wall's under AVRA_CLOCK=real. 1 the case held under every schedule run, else 0.
int64_t avra_case_verdict(int64_t code, const char* label);
// Once, at a suite's end: how many schedules a case that chose ran, and
// what they cannot reach. Nothing when no case chose.
void avra_case_schedules_said(void);
// A program test's verdict: its top level (`code`, answering a word) run
// on the root under a case's schedules and clock, each one's output held
// to `expected`; the first that prints otherwise is said on stdout.
int64_t avra_program_verdict(int64_t code, const char* label, const char* expected);
// The settings an EVALUATED leg reads, as the native one does: how many
// schedules to run, the schedule the i-th run uses, and whether a run's
// clock is virtual.
int64_t avra_sched_runs_wanted(void);
int64_t avra_sched_schedule_at(int64_t i);
int64_t avra_case_clock_virtual(void);

// How many runs inside the program stand open (`avra_sched_run_begins`).
int64_t avra_sched_run_depth(void);
// How many tasks are alive; how many pages of the wide stack are resident.
int64_t avra_sched_tasks(void);
int64_t avra_sched_wide_resident(void);
// An evaluated run's first task row: traps when its host has a timer or
// a descriptor waiter filed, which the run would share.
void avra_sched_guest_waits(void);

// How many entries the timer heap holds, how many waiters are filed on
// descriptors, how many times the poller has been asked, and how many
// links of the queue the seeded pick has walked.
int64_t avra_sched_timers(void);
int64_t avra_sched_fd_waiters(void);
int64_t avra_sched_polls(void);
int64_t avra_sched_pick_links(void);
// How many switches left the fast path to ask the world.
int64_t avra_sched_world_visits(void);

#endif
