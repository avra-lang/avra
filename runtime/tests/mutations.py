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
FIBER, CLOCK = "avra_fiber", "avra_runtime"
sources = {name: open(f"runtime/{name}.c").read() for name in (FIBER, CLOCK)}
arm = platform.machine() in ("arm64", "aarch64")

FLOOR = ('    "    b.lo 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jb 1f\\n"\n', '    "    nop\\n"\n')
CANARY = ('    "    cbnz x10, 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jne 1f\\n"\n', '    "    nop\\n"\n')

MUTATIONS = [
    ("the switch does not test the floor", *FLOOR),
    ("the switch does not test the canary", *CANARY),
    ("a claimant leaves the winner filed", "    waiter_out(w);\n    return set_claimed(w->fiber, w->arm, w->member, by);", "    return set_claimed(w->fiber, w->arm, w->member, by);"),
    ("a compiled join is not in the trace", "    if (TRACING) traced_join(self, task_id(task));\n", ""),
    ("a virtual join's waking is not in the trace", "    if (TRACING) traced_joined(virtual_at(t), by);\n", ""),
    ("a cancel displaces a claim", "    if (f->parked && !f->legacy) set_claimed(f, -1, 0, by);", "    if (!f->legacy) { f->arm = -1; f->member = 0; if (f->parked) set_claimed(f, -1, 0, by); }"),
    ("a cancel wakes a sleep or a join", "    if (f->parked && !f->legacy) set_claimed(f, -1, 0, by);", "    if (f->parked) set_claimed(f, -1, 0, by);"),
    ("a cancel is not heard at the next wait", "    if (f->cancel_by != 0) { set_claimed(f, -1, 0, f->cancel_by - 1); return 0; }\n", ""),
    ("a standing cancel is answered before a claim made while arming", "    if (f->claimed) return 0;\n    if (f->cancel_by != 0) {", "    if (f->cancel_by != 0 && f->claimed) { f->arm = -1; f->member = 0; return 0; }\n    if (f->claimed) return 0;\n    if (f->cancel_by != 0) {"),
    ("a task that ends leaves its waits filed", "    retract(self);\n    self->claimed = 0;\n    waiter_out(&self->due);\n", "    waiter_out(&self->due);\n"),
    ("a task that ends leaves its deadline filed", "    retract(self);\n    self->claimed = 0;\n    waiter_out(&self->due);\n", "    retract(self);\n    self->claimed = 0;\n"),
    ("the deadline wakes a sleep or a join", "    if (f->parked && f->heeds) set_claimed(f, -1, 1, BY_DEADLINE);", "    if (f->parked) set_claimed(f, -1, 1, BY_DEADLINE);"),
    ("a scope's end leaves its deadline filed", "    if (f->due.filed && f->due_at != outer) waiter_out(&f->due);\n", ""),
    ("a claimed wait keeps heeding the deadline", "    f->claimed = 0;\n    f->heeds = 0;\n    retract(f);\n    return claim;", "    f->claimed = 0;\n    retract(f);\n    return claim;"),
    ("a child does not inherit its spawner's deadline", "    f->deadline = g_current->deadline;          // a task inherits its spawner's `within`\n", ""),
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
    ("the switch does not repoint the task's locals", "    g_current = next;\n    avra_task_local = next->local;\n    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller has already filed itself", "    g_current = next;\n    avra_fiber_switch(&self->sp, next->sp);\n    bury_finished();\n}\n\n// The caller has already filed itself"),
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
    ("a run's schedule ends and its clock does not", "    g_choices = outer.choices;\n    avra_clock_run_ends();", "    g_choices = outer.choices;"),
    ("the evaluator asks the poller at every switch", [("    Fiber* next = next_ready();\n    if (!next->virtual)", "    Fiber* next = next_with_world();\n    if (!next->virtual)"), ("    if (g_until_poll > 0) return;\n", "")], None),
    ("a join answers a cancelled task", "    if (cells[TASK_END] == END_CANCELLED) join_refused();\n", ""),
    ("a fired timer's task answers nothing", "    cells[TASK_ANSWER] = (int64_t)(uintptr_t)unit;\n", "    avra_rc_release(unit);\n"),
    ("a virtual claim names whoever the host runs", "    return gate_claimed(gate, id_of(virtual_at(t)));", "    return gate_claimed(gate, id_of(g_current));"),
    ("a virtual task's end is not traced", "    if (TRACING) traced_fiber(\"end\", virtual_at(t), 0);\n", ""),
    ("a virtual task keeps the policy's count for its id", "    virtual_at(t)->own.id = id;\n", ""),
]
CLOCK_MUTATIONS = [
    ("freezing loses the present reading", "        avra_clock.at = clock_real() + avra_clock.skew;", "        avra_clock.at = 0;"),
    ("flowing again starts from the wall", "    } else avra_clock.skew = avra_clock.at - clock_real();", "    } else avra_clock.skew = 0;"),
    ("a held clock stays frozen", "    int frozen = avra_clock.virtual && avra_clock.held == 0;", "    int frozen = avra_clock.virtual;"),
    ("a jump can move the clock back", "    if (at > avra_clock.at) avra_clock.at = at;", "    avra_clock.at = at;"),
    ("a task waiting on a frozen clock is never told", "    if (g_clock_asks_most > 0 && ++avra_task_local->clock_asks > g_clock_asks_most) clock_never_comes();\n", ""),
    ("a limit of none still traps", "    if (g_clock_asks_most > 0 && ++avra_task_local->clock_asks", "    if (++avra_task_local->clock_asks"),
    ("the limit is not the setting's", "    g_clock_asks_most = n;\n", ""),
    ("a limit that is no number is read as one", "    if (*end != 0 || n < 0) avra_trap(CLOCK_ASKS_SETTING", "    if (0) avra_trap(CLOCK_ASKS_SETTING"),
    ("a hold let go too often goes unsaid", "    if (avra_clock.held < 0) avra_trap(", "    if (0) avra_trap("),
    ("dropped holds still hold", "    int64_t held = avra_clock.held;\n    avra_clock.held = 0;", "    int64_t held = avra_clock.held;"),
    ("a run begins with its host's holds", "    g_clock_outer[g_clock_runs++] = avra_clock;\n    avra_clock.held = 0;", "    g_clock_outer[g_clock_runs++] = avra_clock;"),
    ("a run's end keeps its clock", "    avra_clock = g_clock_outer[--g_clock_runs];", "    --g_clock_runs;"),
]
TESTS = ["flow_test", "clock_test", "seed_test", "cores_test", "vtask_test", "fiber_test", "fiber_adversarial_test"]
BOUND = 60

os.makedirs(out, exist_ok=True)
for test in TESTS:
    subprocess.run(["cc", "-c", "-O2", *flags, "-o", f"{out}/{test}.o", f"runtime/tests/{test}.c"], check=True)

# What a break of one file links beside it: every other object, and for
# the clock's the scheduler built whole.
ALL = [(FIBER, m) for m in MUTATIONS] + [(CLOCK, m) for m in CLOCK_MUTATIONS]
subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{out}/{FIBER}.o", f"runtime/{FIBER}.c"], check=True)
rest = {FIBER: objects, CLOCK: [o for o in objects if not o.endswith(f"/{CLOCK}.o")] + [f"{out}/{FIBER}.o"]}


def tried(numbered):
    at, (which, (name, old, new)) = numbered
    text = sources[which]
    for a, b in old if isinstance(old, list) else [(old, new)]:
        if text.count(a) != 1:
            return name, "rotten", f"its line is not in the source (x{text.count(a)})"
        text = text.replace(a, b)
    here = f"{out}/{at}"
    os.makedirs(here, exist_ok=True)
    open(f"{here}/{which}.c", "w").write(text)
    built = subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{here}/{which}.o", f"{here}/{which}.c"], capture_output=True, text=True)
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
