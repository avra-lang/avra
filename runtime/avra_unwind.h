// THE FRAMES AN UNWIND PASSED, AND THE SHIELD A COLD EXIT RAISES, the core's: a list of at most AVRA_UNWIND_CAP
// frames, the middle dropped and counted when full. The main program's list
// is the core runtime's own; a task's sits on its record, and the scheduler
// names it through `avra_unwind_running` once it is linked, so a program that
// spawns nothing links no scheduler to keep its frames.
#ifndef AVRA_UNWIND_H
#define AVRA_UNWIND_H
#include <stdint.h>

enum { AVRA_UNWIND_CAP = 16 };

typedef struct { int64_t frames[AVRA_UNWIND_CAP]; int64_t n; int64_t dropped; } AvraUnwind;

// The running task's list, named by the scheduler once it is linked; unset,
// the main program's.
extern AvraUnwind* (*avra_unwind_running)(void);

AvraUnwind* avra_unwind_main(void);
void avra_unwind_clear(void);
void avra_unwind_push(void* frame);
int64_t avra_unwind_count(void);
void* avra_unwind_at(int64_t i);
int64_t avra_unwind_dropped(void);

// A cancel point's shield around a cold exit, the scheduler's to keep, named
// once it is linked; unset, a program with no task to cancel shields nothing.
extern void (*avra_shield_entered)(void);
extern void (*avra_shield_left)(void);

#endif
