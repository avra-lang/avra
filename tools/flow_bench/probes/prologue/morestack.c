// split-stack's runtime, stubbed: the check in each prologue is real, and
// with the thread's limit slot at zero it is never taken.
#include <stdlib.h>
void __morestack(void) { abort(); }
void __morestack_non_split(void) { abort(); }
