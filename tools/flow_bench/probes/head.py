"""A copy of runtime/avra_fiber.c with the fiber's record grown to the
size the waiter design gives it (392 bytes), written two ways: the whole
record zeroed at spawn, as today's one assignment does, or its live
prefix alone.

    head.py <avra_fiber.c> <full|prefix> <out.c>
"""
import sys

src, how, out = sys.argv[1:4]
text = open(src).read()


def once(old, new):
    global text
    assert text.count(old) == 1, old
    text = text.replace(old, new)


once("    int virtual;         // the evaluator's: filed here, switched by the evaluator\n};",
     "    int virtual;\n    char pad[312];\n};")
if how == "prefix":
    once("#include <string.h>\n", "#include <string.h>\n#include <stddef.h>\n")
    once("    *f = (Fiber){ .map = map, .task = task, .parked_fd = -1 };",
         "    memset(f, 0, offsetof(Fiber, pad));\n    f->map = map;\n    f->task = task;\n    f->parked_fd = -1;")
open(out, "w").write(text)
