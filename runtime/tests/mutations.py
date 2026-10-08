"""THE SCHEDULER'S TESTS, TESTED: each entry breaks one line of
runtime/avra_fiber.c — or, for the clock, of runtime/avra_runtime.c —
and some runtime test must fail for it. A break
every test survives is a law nothing holds; a pattern that no longer
matches the source is a break nobody is checking. Either fails the run.

    mutations.py <build dir> <cc flags> <object>...

The objects are the runtime's, the scheduler's own left out. A break is
one line, or the few that make one fault. Each runs apart from the
others, at once, and a test that outlives its bound is a kill: a hang
is a failure too, and the bound keeps the whole run short.
"""
import os
import platform
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

out, flags, objects = sys.argv[1], sys.argv[2].split(), sys.argv[3:]
FIBER, CLOCK, DOOR = "avra_fiber", "avra_runtime", "avra_door"
sources = {name: open(f"runtime/{name}.c").read() for name in (FIBER, CLOCK)}
# THE DOOR'S HEADER is the scheduler's too: a break of it is written beside
# an unbroken copy of the scheduler, whose include finds it first.
sources[DOOR] = open(f"runtime/{DOOR}.h").read()
arm = platform.machine() in ("arm64", "aarch64")

FLOOR = ('    "    b.lo 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jb 1f\\n"\n', '    "    nop\\n"\n')
CANARY = ('    "    cbnz x10, 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jne 1f\\n"\n', '    "    nop\\n"\n')

MUTATIONS = [
    ("the switch does not test the floor", *FLOOR),
    ("the switch does not test the canary", *CANARY),
    ("a claimant leaves the winner filed", "    waiter_out(w);\n    return set_claimed(w->fiber, w->arm, w->member, by);", "    return set_claimed(w->fiber, w->arm, w->member, by);"),
    ("a compiled join is not in the trace", "    if (TRACING) traced_join(self, task_id(task));\n", ""),
    ("a virtual join's waking is not in the trace", "    traced_joined(f, by);\n    ready_push(f);\n", "    ready_push(f);\n"),
    ("a spawn's site is not in the trace", "    traced_site(f, site_of(body), (const void*)(uintptr_t)((AvraArray*)body)->data[0]);\n", ""),
    ("code no row names is read as the first row's", "        if (rows[i].code == code) return rows[i].site;\n", "        return rows[i].site;\n"),
    ("the site table is read short by a row", "    for (size_t i = 0; i < n; i++) {\n        if (rows[i].code == code)", "    for (size_t i = 1; i < n; i++) {\n        if (rows[i].code == code)"),
    ("a virtual task's site is not in the trace", "    if (TRACING) traced_site(virtual_at(t), site, NULL);\n", ""),
    ("a cancel displaces a claim", "    if (f->parked && !(f->legacy && f->virtual)) set_claimed(f, -1, 0, by);", "    if (!(f->legacy && f->virtual)) { f->arm = -1; f->member = 0; if (f->parked) set_claimed(f, -1, 0, by); }"),
    ("a cancel wakes an evaluated task's sleep or join", "    if (f->parked && !(f->legacy && f->virtual)) set_claimed(f, -1, 0, by);", "    if (f->parked) set_claimed(f, -1, 0, by);"),
    ("a cancel cuts no sleep, join or descriptor park", "    if (f->parked && !(f->legacy && f->virtual)) set_claimed(f, -1, 0, by);", "    if (f->parked && !f->legacy) set_claimed(f, -1, 0, by);"),
    ("a cancel is not passed down a scope's join", "    if (f->deaf && f->joining) { task_cancelled(f->joining, by); return; }\n", ""),
    ("a scope's end does not cancel what it owns", "    if (g_current->cancel_by != 0) task_cancelled(task, id_of(g_current));\n", ""),
    ("a scope's end is cut by a cancel", "    task_awaited(task, 1);", "    task_awaited(task, 0);"),
    ("a cut sleep sets no unwind bit", "    run_next();\n    if (claimed_by_cancel(self)) cancel_met();\n}", "    run_next();\n}"),
    ("a cut descriptor park sets no unwind bit", "        run_next();\n        if (claimed_by_cancel(self)) cancel_met();\n", "        run_next();\n"),
    ("a park a cancel claims sets no unwind bit", "    if (park_begun(self)) run_next();\n    if (claimed_by_cancel(self)) cancel_met();\n", "    if (park_begun(self)) run_next();\n"),
    ("a standing cancel lets a sleep park", "    if (cancel_stands(self)) return;\n    alone(self);\n    waits_until(", "    alone(self);\n    waits_until("),
    ("a standing cancel lets a join park", "    if (!deaf && cancel_stands(self)) return cells;\n", ""),
    ("a standing cancel lets a descriptor park", "    if (!f->virtual && cancel_stands(f)) { f->timed_out = 1; return 0; }\n", ""),
    ("a yield is no cancel point", "    if (__builtin_expect(g_current->cancel_by != 0, 0)) cancel_met();\n", ""),
    ("a cut yield stops switching", "    if (__builtin_expect(g_current->cancel_by != 0, 0)) cancel_met();\n", "    if (__builtin_expect(g_current->cancel_by != 0, 0)) { cancel_met(); return; }\n"),
    ("a cut join hands back an answer that does not exist", "    if (!cells[GATE_OPEN]) join_cut();\n", ""),
    ("the switch leaves the unwind bit where it was", "    self->unwinding = avra_unwinding;\n    avra_unwinding = next->unwinding;\n    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller", "    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller"),
    ("a body that unwinds ends answered", "    cells[TASK_END] = avra_unwinding ? END_CANCELLED : END_ANSWERED;", "    cells[TASK_END] = END_ANSWERED;"),
    ("a cancel is not heard at the next wait", "    if (f->cancel_by != 0) { set_claimed(f, -1, 0, f->cancel_by - 1); return 0; }\n", ""),
    ("a standing cancel is answered before a claim made while arming", "    if (f->claimed) return 0;\n    if (f->cancel_by != 0) {", "    if (f->cancel_by != 0 && f->claimed) { f->arm = -1; f->member = 0; return 0; }\n    if (f->claimed) return 0;\n    if (f->cancel_by != 0) {"),
    ("a task that ends leaves its waits filed", "    retract(self);\n    self->claimed = 0;\n    waiter_out(&self->due);\n", "    waiter_out(&self->due);\n"),
    ("a task that ends leaves its deadline filed", "    retract(self);\n    self->claimed = 0;\n    waiter_out(&self->due);\n", "    retract(self);\n    self->claimed = 0;\n"),
    ("the deadline wakes a sleep or a join", "    if (f->parked && f->heeds) set_claimed(f, -1, 1, BY_DEADLINE);", "    if (f->parked) set_claimed(f, -1, 1, BY_DEADLINE);"),
    ("a scope's end leaves its deadline filed", "    if (f->due.filed && f->due_at != f->deadline) waiter_out(&f->due);\n    return landed;", "    return landed;"),
    ("a claimed wait keeps heeding the deadline", "    f->claimed = 0;\n    f->heeds = 0;\n    retract(f);\n    return claim;", "    f->claimed = 0;\n    retract(f);\n    return claim;"),
    ("a child does not inherit its spawner's deadline", "    scope_inherited(f, g_current);\n", ""),
    ("a virtual child does not inherit its spawner's deadline", "void avra_vtask_inherits(int64_t t, int64_t from) { scope_inherited(virtual_at(t), virtual_at(from)); }", "void avra_vtask_inherits(int64_t t, int64_t from) { (void)t; (void)from; }"),
    ("a child inherits the owner over the standing request", "from->scope_by != 0 ? scope_at(from, from->armed) :", "from->scope_by != 0 ? scope_at(from, from->owner) :"),
    ("a child inherits a copy of its spawner's id", "    child->scope[0] = *s;\n", "    child->scope[0] = (Scope){ s->id + 1, s->at };\n"),
    ("the owner is the inner scope on a tie", "        if (f->deadline != 0 && at >= f->deadline) continue;", "        if (f->deadline != 0 && at > f->deadline) continue;"),
    ("an opened scope never takes the deadline", "    if (f->deadline == 0 || at < f->deadline) {\n        f->owner = i;\n        f->deadline = at;\n    }\n    return id;", "    return id;"),
    ("an opened scope takes the deadline on a tie", "    if (f->deadline == 0 || at < f->deadline) {\n        f->owner = i;", "    if (f->deadline == 0 || at <= f->deadline) {\n        f->owner = i;"),
    ("a scope opened under a standing request may ask", "    if (f->armed != i) return id;\n", ""),
    ("scope ids are task ids", "    int64_t id = SCOPE_IDS | ++g_scope_seq;", "    int64_t id = ++g_scope_seq;"),
    ("scope ids repeat", "    int64_t id = SCOPE_IDS | ++g_scope_seq;", "    int64_t id = SCOPE_IDS | (g_scope_seq++ % 64);"),
    ("a scope ends out of order", "    if (n == 0 || scope_at(f, n - 1)->id != id) scope_out_of_order(f, id);\n", ""),
    ("a scope's end lands any request", "    int64_t landed = f->scope_by == id;", "    int64_t landed = f->scope_by != 0;"),
    ("a landed request stands on", "    if (landed) f->scope_by = 0;\n", ""),
    ("a scope's end leaves the owner as it was", "    if (f->armed > n) {\n        f->armed = n;\n        owner_found(f);\n    }\n", ""),
    ("a fifth scope is written over the fourth", "    return i < SCOPES ? (Scope*)&f->scope[i] : &f->deeper[i - SCOPES];", "    return i < SCOPES ? (Scope*)&f->scope[i] : (Scope*)&f->scope[SCOPES - 1];"),
    ("a scope's limit outranks a task's cancel", "    if (f->cancel_by != 0) {\n        if (TRACING) traced_dropped(f, id, f->cancel_by);\n        f->armed = 0;\n        f->deadline = 0;\n        return;\n    }\n", ""),
    ("a dropped request is not traced", "        if (TRACING) traced_dropped(f, id, f->cancel_by);\n", ""),
    ("an inner request stays when the outer's limit passes", "    f->scope_by = id;\n    f->armed = f->owner;", "    if (f->scope_by == 0) f->scope_by = id;\n    f->armed = f->owner;"),
    ("an inner scope may ask after the outer did", "    f->scope_by = id;\n    f->armed = f->owner;", "    f->scope_by = id;"),
    ("the next owner is not filed when one asks", "    if (f->deadline != 0) due_filed(f);\n}", "}"),
    ("a standing scope request lets a park wait", "    if (f->scope_by != 0) return 1;\n    if (f->deadline == 0) return 0;", "    if (f->deadline == 0) return 0;"),
    ("a limit found passed at a park asks nothing", "        deadline_reached(f);\n        return f->scope_by != 0;", "        return 0;"),
    ("a task's cancel leaves a scope's request standing", "    if (f->scope_by != 0) {\n        if (TRACING) traced_dropped(f, f->scope_by, by + 1);\n        f->scope_by = 0;\n    }\n", ""),
    ("the request read forgets a task's cancel", "{ return g_current->cancel_by ? g_current->cancel_by : g_current->scope_by; }", "{ return g_current->scope_by; }"),
    ("a fork keeps other tasks' waiters", "        retract(f);\n        if (f != g_current) waiter_out(&f->due);\n", "        if (f != g_current) waiter_out(&f->due);\n"),
    ("a fork keeps other tasks' deadlines", "        retract(f);\n        if (f != g_current) waiter_out(&f->due);\n", "        retract(f);\n"),
    ("a fork drops the timer's tasks", "    g_ready_head = g_ready_tail = NULL;\n    g_parked_fds = 0;", "    g_ready_head = g_ready_tail = NULL;\n    g_timers_len = 0;\n    g_parked_fds = 0;"),
    ("a freed virtual task leaves its waits filed", "    retract(f);\n    waiter_out(&f->due);\n    if (f->state == FIBER_READY) {", "    waiter_out(&f->due);\n    if (f->state == FIBER_READY) {"),
    ("a freed virtual task leaves its deadline filed", "    retract(f);\n    waiter_out(&f->due);\n    if (f->state == FIBER_READY) {", "    retract(f);\n    if (f->state == FIBER_READY) {"),
    ("two sets at once are allowed", "    if (f->held_n != 0 || f->claimed) avra_trap(\"a task waited inside a wait it had not parked\");", ""),
    ("the one-set check ignores a claimed set", "    if (f->held_n != 0 || f->claimed) avra_trap", "    if (f->held_n != 0) avra_trap"),
    ("a descriptor park that timed out reads as ready", "        f->timed_out = arm != 0;", "        f->timed_out = 0;"),
    ("an interrupt reads as readiness", "        set_claimed(f, -1, 1, BY_CLOSE);", "        set_claimed(f, 0, 0, BY_CLOSE);"),
    ("a late parker takes an edge that came before it", "    if ((size_t)fd < g_fds_cap && g_fds[fd].head[writable != 0]) poller_wait(0);\n", ""),
    ("a closing descriptor keeps its registration", "waiter_claims(w->head[d], BY_CLOSE);\n    w->armed = 0;\n", "waiter_claims(w->head[d], BY_CLOSE);\n"),
    ("a waiter's gate is never let go", "    if (w->kind == W_GATE) avra_rc_release(w->on.gate);\n    else g_parked_fds--;", "    if (w->kind != W_GATE) g_parked_fds--;"),
    ("a timer task is not released when it fires", "    gate_opened(task, BY_TIMER);\n    avra_rc_release(task);", "    gate_opened(task, BY_TIMER);"),
    ("a task's slots outlive it", "        self->own.slot[i] = NULL;\n        avra_rc_release(held);", "        self->own.slot[i] = NULL;"),
    ("the switch does not repoint the task's locals", "    g_current = next;\n    avra_task_local = next->local;\n    self->unwinding = avra_unwinding;\n    avra_unwinding = next->unwinding;\n    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller has already filed itself", "    g_current = next;\n    self->unwinding = avra_unwinding;\n    avra_unwinding = next->unwinding;\n    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller has already filed itself"),
    ("the guarded count never runs out", "            if (!g_guards_all) g_each_left -= n;\n", ""),
    ("a stack given back forgets what guards it", "    if (f->base) stack_give((Stack){ f->base, f->guard });", "    if (f->base) stack_give((Stack){ f->base, f->base - g_page });"),
    ("a guarded stack is not preferred", "    return pool_taken(g_guarded.len > 0 ? &g_guarded : &g_shared);", "    return pool_taken(g_shared.len > 0 ? &g_shared : &g_guarded);"),
    ("a misspelled guard count is read as none", "        if (!end || *end != 0 || errno != 0) guards_misspelled(env);\n", ""),
    ("a switch with a timer filed reads no clock", "    return __builtin_expect(g_timers_len == 0 && left > 0, 1);", "    return __builtin_expect(left > 0, 1);"),
    ("filing a descriptor waiter does not bring the poller within reach", "        if (g_until_poll > FAIR_TURNS) g_until_poll = FAIR_TURNS;\n", ""),
    ("the poller's turn comes every million switches", "#define FAIR_TURNS 64\n", "#define FAIR_TURNS 1000000\n"),
    ("the world is asked only when nobody is ready", "    return __builtin_expect(g_timers_len == 0 && left > 0, 1);", "    return 1;"),
    ("the poller is never asked while tasks are ready", "    if (g_parked_fds > 0) poller_wait(0);\n    else g_until_poll = POLL_IDLE;", "    g_until_poll = FAIR_TURNS;"),
    ("a pick among one is counted as a choice", "    if (n < 2) return ready_pop();\n    uint64_t k = chosen(n);", "    if (n < 1) return ready_pop();\n    uint64_t k = chosen(n);"),
    ("schedule 0 draws like any other", "    if (g_schedule == 0) return 0;\n", ""),
    ("the pick ignores the schedule's choice", "    uint64_t k = chosen(n);", "    uint64_t k = chosen(n) * 0;"),
    ("a seeded switch takes the fast path", "    if (pinned()) {\n        g_until_poll = 0;\n        g_pinned_until_poll = FAIR_TURNS;", "    if (pinned()) {\n        g_until_poll = POLL_IDLE;\n        g_pinned_until_poll = FAIR_TURNS;"),
    ("a seeded run asks the poller at every switch", "        if (g_parked_fds > 0 && --g_pinned_until_poll <= 0) poller_wait(0);", "        if (g_parked_fds > 0) poller_wait(0);"),
    ("a seeded run never asks the poller while tasks are ready", "        if (g_parked_fds > 0 && --g_pinned_until_poll <= 0) poller_wait(0);\n        return;", "        return;"),
    ("a poll in a seeded run hands the next switches to the fast path", "    g_polls++;\n    poll_counted();", "    g_polls++;\n    g_until_poll = g_parked_fds > 0 ? FAIR_TURNS : POLL_IDLE;"),
    ("a settle leaves the order seeded", "    g_seeded = 0;\n    return g_choices;", "    return g_choices;"),
    ("the pick walks the whole queue", "enum { PICK_WINDOW = 16 };", "enum { PICK_WINDOW = 16384 };"),
    ("a seed does not restart the count of choices", "    g_choices = 0;\n", ""),
    ("a frozen clock never jumps", "        if (world_waited_virtually()) continue;\n", ""),
    ("the clock jumps past a descriptor's waiter", "    return g_parked_fds == 0 && g_timers_len > 0 && avra_clock_jumped(g_timers[0].at);", "    return g_timers_len > 0 && avra_clock_jumped(g_timers[0].at);"),
    ("the poller's wait does not hold the clock", "        if (held) avra_clock_hold(1);\n", ""),
    ("the poller's hold is never given back", "        if (held) avra_clock_hold(-1);\n", ""),
    ("the scheduler's reads of the clock count as a task's waiting", "static inline int64_t now_ns(void) { return avra_clock_read(); }", "static inline int64_t now_ns(void) { return avra_now_ns(); }"),
    ("a task that parks keeps its count of clock reads", "    if (avra_clock.virtual && g_current->state == FIBER_PARKED) g_current->local->clock_asks = 0;\n", ""),
    ("a task that yields begins its count of clock reads again", "    if (avra_clock.virtual && g_current->state == FIBER_PARKED) g_current->local->clock_asks = 0;", "    if (avra_clock.virtual) g_current->local->clock_asks = 0;"),
    ("a virtual clock leaves the switch on the fast path", "static int pinned(void) { return g_seeded || avra_clock.virtual; }", "static int pinned(void) { return g_seeded; }"),
    ("the evaluator's count of clock reads outlives its task's park", "    if (parked) avra_task_local->clock_asks = 0;\n", ""),
    ("after a settle every switch asks the world", "    if (g_parked_fds > 0) poller_wait(0);\n    else g_until_poll = POLL_IDLE;", "    if (g_parked_fds > 0) poller_wait(0);"),
    ("a forked child inherits its parent's schedule", "    g_seeded = 0;\n}", "}"),
    ("a virtual join parks on nothing", "    alone(f);\n    waits_gate(f, task, 0, 0);\n    legacy_parked(f);\n    return host_waited(1);", "    alone(f);\n    legacy_parked(f);\n    return host_waited(1);"),
    ("a virtual join heeds its task's deadline", "    waits_gate(f, task, 0, 0);\n    legacy_parked(f);\n    return host_waited(1);", "    waits_gate(f, task, 0, 0);\n    return host_waited(park_begun(f));"),
    ("a virtual join of an ended task parks", "    if (task_cells(task)[GATE_OPEN]) return 0;\n    alone(f);", "    alone(f);"),
    ("a run begins with its host's schedule", "    g_seeded = 0;\n    avra_clock_run_begins();", "    avra_clock_run_begins();"),
    ("a run's end keeps its seed", "    g_seeded = outer.seeded;\n", ""),
    ("a run's end restarts the outer schedule's stream", "    g_seed_state = outer.state;\n", "    g_seed_state = (uint64_t)outer.schedule;\n"),
    ("a run's choices are counted as its host's", "    g_choices = outer.choices;\n", ""),
    ("a run's schedule ends and its clock does not", "    avra_clock_run_ends();\n}\n\n// THE TRIPWIRE", "}\n\n// THE TRIPWIRE"),
    ("a deadlock inside a case ends the process", "            if (case_deadlocked()) continue;\n", ""),
    ("a case that leaks passes", "    g_case_answer = left == 0 && !g_case_spoiled ? answer : 0;", "    g_case_answer = answer;"),
    ("a task that outlives its case is named and left alive", "    for (int64_t i = 0; i < n; i++) abandoned(alive[i]);\n", ""),
    ("an abandoned task stays where it is filed", "    cells[TASK_END] = END_CANCELLED;\n    gone(f);", "    cells[TASK_END] = END_CANCELLED;"),
    ("an abandoned task reads as alive to whoever holds it", "    gone(f);\n    avra_vgate_open(task);", "    gone(f);"),
    ("a task's number counts from the process's first spawn", "(uint64_t)id_of(f) - g_case_first - 1);", "(uint64_t)id_of(f) - 1);"),
    ("a case's body runs on a task's own stack", "    ((Fiber*)(uintptr_t)task_cells(task)[TASK_FIBER])->wide = 1;\n", ""),
    ("tasks made before the case count as its own", "!f->virtual && (uint64_t)id_of(f) > g_case_first && f->state", "!f->virtual && f->state"),
    ("a case inside a case is allowed", "    if (g_case_waited || g_timers_len > 0 || g_parked_fds > 0) return case_refused();", "    if (g_timers_len > 0 || g_parked_fds > 0) return case_refused();"),
    ("a case runs beside a filed timer", "    if (g_case_waited || g_timers_len > 0 || g_parked_fds > 0) return case_refused();", "    if (g_case_waited) return case_refused();"),
    ("a case inside a case leaves its outer case passing", "        g_case_spoiled = 1;\n", ""),
    ("a timer's task the case left filed passes it", "    int64_t left = case_cleared(0) + case_timers_cleared() + case_holds_cleared();", "    int64_t left = case_cleared(0) + case_holds_cleared();"),
    ("a hold outlives its abandoned holder", "    free(alive);\n    avra_clock_holds_let_go(held);", "    free(alive);"),
    ("a case that ends holding the world passes", "    int64_t left = case_cleared(0) + case_timers_cleared() + case_holds_cleared();", "    int64_t left = case_cleared(0) + case_timers_cleared();"),
    ("every hold is let go when a case leaks", "    free(alive);\n    avra_clock_holds_let_go(held);", "    free(alive);\n    avra_clock_holds_dropped();"),
    ("a deep case's pages stay resident", "    wide_given_back();\n    return g_case_answer;", "    return g_case_answer;"),
    ("a guest waits beside its host's timer", "    if (g_runs == 0 || (g_timers_len == 0 && g_parked_fds == 0)) return;", "    return;"),
    ("a host outside any run is tripped", "    if (g_runs == 0 || (g_timers_len == 0", "    if ((g_timers_len == 0"),
    ("a case that made no choice runs every schedule", "        if (choices == 0) return 1;\n", ""),
    ("a failing schedule passes the case", "        if (!case_under(k, &choices)) return choices == 0 && k == 0 ? 0 : case_failed_under(label, k);", "        case_under(k, &choices);"),
    ("the seed setting is not heard", "    if (g_sched_only >= 0) return case_under", "    if (0) return case_under"),
    ("the runs setting is not heard", "    g_sched_runs = whole_setting(SCHED_RUNS_SETTING, 1, SCHED_RUNS_DEFAULT);", "    g_sched_runs = SCHED_RUNS_DEFAULT;"),
    ("the count is never said", "    if (!g_any_chose || g_sched_only >= 0) return;", "    return;"),
    ("a trap does not know its case's schedule", "    avra_case_schedule = schedule;\n", ""),
    ("a seeded deadlock names no schedule", "    if (g_seeded) fprintf(stderr, \"avra: under schedule %lld — \" SCHED_SEED_SETTING", "    if (0) fprintf(stderr, \"avra: under schedule %lld — \" SCHED_SEED_SETTING"),
    ("a case's answer is read past its lowest bit", "{ return g_case_body() & 1; }", "{ return g_case_body() != 0; }"),
    ("a case with one order names a schedule when it fails", "return choices == 0 && k == 0 ? 0 : case_failed_under(label, k);", "return case_failed_under(label, k);"),
    ("a case runs on the wall's clock", "    if (g_case_clock_virtual) {\n        avra_clock_run_begins();\n        avra_clock_virtual(1);\n    }", "    if (0) {\n        avra_clock_run_begins();\n        avra_clock_virtual(1);\n    }"),
    ("a case's clock outlives it", "    if (g_case_clock_virtual) avra_clock_run_ends();\n", "    if (g_case_clock_virtual) avra_clock_virtual(0);\n"),
    ("the clock setting is not heard", "    g_case_clock_virtual = 0;\n", ""),
    ("a spin on the frozen clock ends the process", "    avra_clock_spun_hook = case_spun;\n", ""),
    ("a run a stopped case opened outlives it", "        while ((int64_t)g_runs > runs) avra_sched_run_ends();\n", ""),
    ("a clock run a stopped case opened outlives it", "        while (avra_clock_run_depth() > clocks) avra_clock_run_ends();\n", ""),
    ("a stopped task says nothing of why", "    if (f == g_case_spinner) { fputs(", "    if (0) { fputs("),
    ("the evaluator asks the poller at every switch", [("    Fiber* next = next_ready();\n    if (!next->virtual)", "    Fiber* next = next_with_world();\n    if (!next->virtual)"), ("    if (g_until_poll > 0) return;\n", "")], None),
    ("a join answers a cancelled task", "    if (cells[TASK_END] == END_CANCELLED) join_refused();\n", ""),
    ("a fired timer's task answers nothing", "    cells[TASK_ANSWER] = (int64_t)(uintptr_t)unit;\n", "    avra_rc_release(unit);\n"),
    ("a virtual claim names whoever the host runs", "    return gate_claimed(gate, id_of(virtual_at(t)));", "    return gate_claimed(gate, id_of(g_current));"),
    ("a virtual task's end is not traced", "    if (TRACING) traced_fiber(\"end\", virtual_at(t), 0);\n", ""),
    ("a virtual task keeps the policy's count for its id", "    virtual_at(t)->own.id = id;\n", ""),
    ("the handler leaves the switch's countdown alone", "    g_until_poll = 0;\n    prior_called(", "    prior_called("),
    ("a switch never answers an ask", "        if (__builtin_expect(g_asked, 0)) tasks_answered();\n", ""),
    ("a forked child is asked under its parent's id", "    g_asked = 0;\n    tasks_door_named();\n    // a schedule", "    g_asked = 0;\n    // a schedule"),
    ("an evaluated program's line names the host's task", "    if (g_evaluated) {", "    if (0) {"),
    ("a handler set before ours is no longer called", "    prior_called(sig, info, context);\n", ""),
    ("a forked child owes its parent's ask", "    g_asked = 0;\n    tasks_door_named();\n    // a schedule", "    tasks_door_named();\n    // a schedule"),
    ("a second signal is not answered by the handler", "    if (g_asked++ > 0 && !g_in_world && g_until_poll == 0) {", "    if (0) {"),
    ("the handler answers from inside the world's path", "    if (g_asked++ > 0 && !g_in_world && g_until_poll == 0) {", "    if (g_asked++ > 0 && g_until_poll == 0) {"),
    ("an ask is answered without an ask file", "    if (ask_ours(dfd, names)) listing_written(dfd, names);", "    listing_written(dfd, names);"),
    ("an ask that is no plain file is taken as ours", "S_ISREG(st.st_mode) && st.st_uid == geteuid();\n}", "st.st_uid == geteuid();\n}"),
    ("an answered ask is left in place", "    unlinkat(dfd, names->ask, 0);\n    renameat(dfd, names->tmp,", "    renameat(dfd, names->tmp,"),
    ("the handler's line shares the listing's file", "    unlinkat(dfd, names->line, 0);\n    int fd = openat(dfd, names->line,", "    unlinkat(dfd, names->tmp, 0);\n    int fd = openat(dfd, names->tmp,"),
    ("a relative door directory is used", "chosen[0] == '/' ? chosen : \"\"", "chosen"),
    ("the door's directory is chosen once", "    g_asked = 0;\n    tasks_door_named();\n    const DoorNames*", "    g_asked = 0;\n    const DoorNames*"),
    ("the handler's line is stamped with no time", "    k += digits_put(line + k, (long long)now_ns());", "    line[k++] = '0';"),
    ("a task that has not run is listed as parked", "    for (uint32_t i = 0; i < f->held_n; i++) waiter_listed(out, now, f, &f->held[i]);", "    if (!f->sp) fprintf(out, \"ts=%lld park id=%lld src=at arm=0:0\\n\", (long long)now, id);\n    for (uint32_t i = 0; i < f->held_n; i++) waiter_listed(out, now, f, &f->held[i]);"),
    ("the door is never opened", "    guard_handler_install();\n    tasks_door_opened();", "    guard_handler_install();"),
]
DOOR_MUTATIONS = [
    ("a door directory others may write is a door", " && (st.st_mode & 077) == 0) return dfd;", ") return dfd;"),
    ("a door directory that is a link is followed", "    int dfd = open(dir, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);", "    int dfd = open(dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);"),
]
CLOCK_MUTATIONS = [
    ("a hold on the world is charged to no task", "    avra_task_local->clock_holds += by;\n", ""),
    ("a wait on the world does not restart a task's reads", "    if (by < 0) avra_task_local->clock_asks = 0;\n", ""),
    ("freezing loses the present reading", "        avra_clock.at = clock_real() + avra_clock.skew;", "        avra_clock.at = 0;"),
    ("flowing again starts from the wall", "    } else avra_clock.skew = avra_clock.at - clock_real();", "    } else avra_clock.skew = 0;"),
    ("a held clock stays frozen", "    int frozen = avra_clock.virtual && avra_clock.held == 0;", "    int frozen = avra_clock.virtual;"),
    ("a jump can move the clock back", "    if (at > avra_clock.at) avra_clock.at = at;", "    avra_clock.at = at;"),
    ("a task waiting on a frozen clock is never told", "    if (g_clock_asks_most > 0 && ++avra_task_local->clock_asks > g_clock_asks_most) clock_never_comes();\n", ""),
    ("a limit of none still traps", "    if (g_clock_asks_most > 0 && ++avra_task_local->clock_asks", "    if (++avra_task_local->clock_asks"),
    ("the limit is not the setting's", "    g_clock_asks_most = n;\n", ""),
    ("a limit that is no number is read as one", "    if (*end != 0 || n < 0) avra_trap(CLOCK_ASKS_SETTING", "    if (0) avra_trap(CLOCK_ASKS_SETTING"),
    ("a hold let go too often goes unsaid", "    if (avra_clock.held < 0) avra_trap(\"the world was let go", "    if (0) avra_trap(\"the world was let go"),
    ("dropped holds still hold", "    int64_t held = avra_clock.held;\n    avra_clock.held = 0;", "    int64_t held = avra_clock.held;"),
    ("a run begins with its host's holds", "    g_clock_outer[g_clock_runs++] = avra_clock;\n    avra_clock.held = 0;", "    g_clock_outer[g_clock_runs++] = avra_clock;"),
    ("a run's end keeps its clock", "    avra_clock = g_clock_outer[--g_clock_runs];", "    --g_clock_runs;"),
]
TESTS = ["flow_test", "case_test", "verdict_test", "tasks_door_test", "clock_test", "seed_test", "cores_test", "vtask_test", "fiber_test", "fiber_adversarial_test"]
BOUND = 60

os.makedirs(out, exist_ok=True)
for test in TESTS:
    subprocess.run(["cc", "-c", "-O2", *flags, "-o", f"{out}/{test}.o", f"runtime/tests/{test}.c"], check=True)

# What a break of one file links beside it: every other object, and for
# the clock's the scheduler built whole.
ALL = [(FIBER, m) for m in MUTATIONS] + [(CLOCK, m) for m in CLOCK_MUTATIONS] + [(DOOR, m) for m in DOOR_MUTATIONS]
subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{out}/{FIBER}.o", f"runtime/{FIBER}.c"], check=True)
rest = {FIBER: objects, CLOCK: [o for o in objects if not o.endswith(f"/{CLOCK}.o")] + [f"{out}/{FIBER}.o"], DOOR: objects}


def tried(numbered):
    at, (which, (name, old, new)) = numbered
    text = sources[which]
    for a, b in old if isinstance(old, list) else [(old, new)]:
        if text.count(a) != 1:
            return name, "rotten", f"its line is not in the source (x{text.count(a)})"
        text = text.replace(a, b)
    here = f"{out}/{at}"
    os.makedirs(here, exist_ok=True)
    unit = FIBER if which == DOOR else which
    if which == DOOR:
        open(f"{here}/{DOOR}.h", "w").write(text)
        text = sources[FIBER]
    open(f"{here}/{unit}.c", "w").write(text)
    built = subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{here}/{which}.o", f"{here}/{unit}.c"], capture_output=True, text=True)
    if built.returncode:
        return name, "rotten", "does not build — " + built.stderr.strip().splitlines()[0][:120]
    for test in TESTS:
        subprocess.run(["cc", "-O2", *flags, "-o", f"{here}/{test}", f"{out}/{test}.o", f"{here}/{which}.o", *rest[which]], check=True, capture_output=True)
        try:
            ran = subprocess.run([f"{here}/{test}"], capture_output=True, timeout=BOUND)
        except subprocess.TimeoutExpired:
            return name, "killed", f"{test} (it outlived {BOUND} s)"
        if ran.returncode != 0:
            words = [line for line in ran.stderr.decode(errors="replace").splitlines() if "FAILED" in line]
            return name, "killed", test + (f": {words[0].split('FAILED ', 1)[1][:70]}" if words else f" (exit {ran.returncode})")
    return name, "alive", ""


with ThreadPoolExecutor(max_workers=max(2, (os.cpu_count() or 2) // 2)) as pool:
    results = list(pool.map(tried, enumerate(ALL)))
for name, how, by in results:
    print(f"  {name}: " + {"killed": f"killed by {by}", "alive": "SURVIVED every runtime test", "rotten": by}[how])
killed = sum(how == "killed" for _, how, _ in results)
alive = sum(how == "alive" for _, how, _ in results)
rotten = sum(how == "rotten" for _, how, _ in results)
bound = sum("outlived" in by for _, how, by in results if how == "killed")
print(f"runtime-mutations: {killed} of {len(ALL)} killed, {killed - bound} by a failing check and {bound} by the bound" + (f"; {alive} survive" if alive else "") + (f"; {rotten} no longer apply" if rotten else ""))
sys.exit(1 if alive or rotten else 0)
