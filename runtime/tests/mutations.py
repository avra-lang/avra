"""THE SCHEDULER'S TESTS, TESTED: each entry breaks one line of
runtime/avra_fiber.c, and some runtime test must fail for it. A break
every test survives is a law nothing holds; a pattern that no longer
matches the source is a break nobody is checking. Either fails the run.

    mutations.py <build dir> <cc flags> <object>...

The objects are the runtime's, the scheduler's own left out.
"""
import os
import platform
import subprocess
import sys

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
]
TESTS = ["flow_test", "cores_test", "vtask_test", "fiber_test", "fiber_adversarial_test"]

os.makedirs(out, exist_ok=True)
killed, alive, rotten = 0, [], []
for name, old, new in MUTATIONS:
    if source.count(old) != 1:
        rotten.append(name)
        print(f"  {name}: its line is not in the source (x{source.count(old)})")
        continue
    open(f"{out}/avra_fiber.c", "w").write(source.replace(old, new))
    built = subprocess.run(["cc", "-c", "-O2", *flags, "-Iruntime", "-o", f"{out}/avra_fiber.o", f"{out}/avra_fiber.c"], capture_output=True, text=True)
    if built.returncode:
        rotten.append(name)
        print(f"  {name}: does not build — {built.stderr.strip().splitlines()[0][:120]}")
        continue
    by = None
    for test in TESTS:
        subprocess.run(["cc", "-O2", *flags, "-o", f"{out}/{test}", f"runtime/tests/{test}.c", f"{out}/avra_fiber.o", *objects], check=True, capture_output=True)
        try:
            ran = subprocess.run([f"{out}/{test}"], capture_output=True, timeout=200)
            if ran.returncode != 0:
                by = test
        except subprocess.TimeoutExpired:
            by = f"{test} (it hung)"
        if by:
            break
    if by:
        killed += 1
        print(f"  {name}: killed by {by}")
    else:
        alive.append(name)
        print(f"  {name}: SURVIVED every runtime test")
print(f"runtime-mutations: {killed} of {len(MUTATIONS)} killed" + (f"; {len(alive)} survive" if alive else "") + (f"; {len(rotten)} no longer apply" if rotten else ""))
sys.exit(1 if alive or rotten else 0)
