"""A copy of runtime/avra_fiber.c with the fiber's record grown to the
size the waiter design gives it (392 bytes), written two ways: the whole
record zeroed at spawn, as today's one assignment does, or its live
prefix alone.

A third copy, `late`, leaves the record its size and binds a task's
stack at its FIRST RUN: the record comes from the heap at spawn.

    head.py <avra_fiber.c> <full|prefix|late> <out.c>
"""
import sys

src, how, out = sys.argv[1:4]
text = open(src).read()


def once(old, new):
    global text
    assert text.count(old) == 1, old
    text = text.replace(old, new)


if how == "late":
    once("""    char* map = stack_take();
    Fiber* f = (Fiber*)(map + g_map_bytes - FIBER_HEAD);
    *f = (Fiber){ .map = map, .task = task, .parked_fd = -1 };
    uint64_t* frame = (uint64_t*)((((uintptr_t)f) & ~(uintptr_t)15) - FIBER_FRAME);
    memset(frame, 0, FIBER_FRAME);
    frame[FIBER_RETURN] = (uint64_t)(uintptr_t)fiber_start;
    f->sp = frame;
    return f;
}""", """    Fiber* f = malloc(sizeof(Fiber));
    *f = (Fiber){ .task = task, .parked_fd = -1 };
    return f;
}

static void fiber_bound(Fiber* f) {
    f->map = stack_take();
    uint64_t* frame = (uint64_t*)((((uintptr_t)(f->map + g_map_bytes)) & ~(uintptr_t)15) - FIBER_FRAME);
    memset(frame, 0, FIBER_FRAME);
    frame[FIBER_RETURN] = (uint64_t)(uintptr_t)fiber_start;
    f->sp = frame;
}""")
    once("static void switch_to(Fiber* next) {", "static void fiber_bound(Fiber* f);\nstatic void switch_to(Fiber* next) {")
    once("    g_current = next;\n    avra_fiber_switch(&self->sp, next->sp);",
         "    g_current = next;\n    if (__builtin_expect(!next->sp, 0)) fiber_bound(next);\n    avra_fiber_switch(&self->sp, next->sp);")
    once("    stack_give(g_finished->map);\n    g_finished = NULL;", "    stack_give(g_finished->map);\n    free(g_finished);\n    g_finished = NULL;")
    open(out, "w").write(text)
    sys.exit(0)

once("    int virtual;         // the evaluator's: filed here, switched by the evaluator\n};",
     "    int virtual;\n    char pad[312];\n};")
if how == "prefix":
    once("#include <string.h>\n", "#include <string.h>\n#include <stddef.h>\n")
    once("    *f = (Fiber){ .map = map, .task = task, .parked_fd = -1 };",
         "    memset(f, 0, offsetof(Fiber, pad));\n    f->map = map;\n    f->task = task;\n    f->parked_fd = -1;")
open(out, "w").write(text)
