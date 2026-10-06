"""THE SCHEDULER'S TESTS, TESTED: each entry breaks one line of
runtime/avra_fiber.c, and some runtime test must fail for it. A break
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
source = open("runtime/avra_fiber.c").read()
arm = platform.machine() in ("arm64", "aarch64")

FLOOR = ('    "    b.lo 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jb 1f\\n"\n', '    "    nop\\n"\n')
CANARY = ('    "    cbnz x10, 1f\\n"\n', '    "    nop\\n"\n') if arm else ('    "    jne 1f\\n"\n', '    "    nop\\n"\n')

MUTATIONS = [
    ("the switch does not test the floor", *FLOOR),
    ("the switch does not test the canary", *CANARY),
    ("a claimant leaves the winner filed", "    waiter_out(w);\n    return set_claimed(w->fiber, w->arm, w->member, by);", "    return set_claimed(w->fiber, w->arm, w->member, by);"),
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
    ("the poller is never asked while tasks are ready", "            if (g_parked_fds > 0) poller_wait(0);\n            else g_until_poll = POLL_IDLE;", "            g_until_poll = FAIR_TURNS;"),
    ("the evaluator asks the poller at every switch", [("    Fiber* next = next_ready();\n    if (!next->virtual)", "    Fiber* next = next_with_world();\n    if (!next->virtual)"), ("        if (g_until_poll <= 0) {", "        if (1) {")], None),
]
TESTS = ["flow_test", "cores_test", "vtask_test", "fiber_test", "fiber_adversarial_test"]
BOUND = 60

os.makedirs(out, exist_ok=True)
for test in TESTS:
    subprocess.run(["cc", "-c", "-O2", *flags, "-o", f"{out}/{test}.o", f"runtime/tests/{test}.c"], check=True)


def tried(numbered):
    at, (name, old, new) = numbered
    text = source
    for a, b in old if isinstance(old, list) else [(old, new)]:
        if text.count(a) != 1:
            return name, "rotten", f"its line is not in the source (x{text.count(a)})"
        text = text.replace(a, b)
    here = f"{out}/{at}"
    os.makedirs(here, exist_ok=True)
    open(f"{here}/avra_fiber.c", "w").write(text)
    built = subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{here}/avra_fiber.o", f"{here}/avra_fiber.c"], capture_output=True, text=True)
    if built.returncode:
        return name, "rotten", "does not build — " + built.stderr.strip().splitlines()[0][:120]
    for test in TESTS:
        subprocess.run(["cc", "-O2", *flags, "-o", f"{here}/{test}", f"{out}/{test}.o", f"{here}/avra_fiber.o", *objects], check=True, capture_output=True)
        try:
            ran = subprocess.run([f"{here}/{test}"], capture_output=True, timeout=BOUND)
        except subprocess.TimeoutExpired:
            return name, "killed", f"{test} (it outlived {BOUND} s)"
        if ran.returncode != 0:
            words = [line for line in ran.stderr.decode(errors="replace").splitlines() if "FAILED" in line]
            return name, "killed", test + (f": {words[0].split('FAILED ', 1)[1][:70]}" if words else f" (exit {ran.returncode})")
    return name, "alive", ""


with ThreadPoolExecutor(max_workers=max(2, (os.cpu_count() or 2) // 2)) as pool:
    results = list(pool.map(tried, enumerate(MUTATIONS)))
for name, how, by in results:
    print(f"  {name}: " + {"killed": f"killed by {by}", "alive": "SURVIVED every runtime test", "rotten": by}[how])
killed = sum(how == "killed" for _, how, _ in results)
alive = sum(how == "alive" for _, how, _ in results)
rotten = sum(how == "rotten" for _, how, _ in results)
bound = sum("outlived" in by for _, how, by in results if how == "killed")
print(f"runtime-mutations: {killed} of {len(MUTATIONS)} killed, {killed - bound} by a failing check and {bound} by the bound" + (f"; {alive} survive" if alive else "") + (f"; {rotten} no longer apply" if rotten else ""))
sys.exit(1 if alive or rotten else 0)
