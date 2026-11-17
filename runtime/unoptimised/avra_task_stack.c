// THE TASK STACK OF A BINARY EMITTED UNOPTIMISED. An -O0 frame keeps its
// values in slots of their own, about two and a half times an optimised
// frame, so the same recursion needs a stack that much deeper: 640 KiB
// here against the runtime's 256 KiB. The link of a binary emitted at -O0
// names this object, whose definition overrides the runtime's weak one;
// AVRA_FIBER_STACK overrides either.
#include <stdint.h>

const int64_t avra_task_stack_bytes = (int64_t)640 << 10;
