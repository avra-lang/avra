// What the runtime reads of the machine it stands on. Kept apart from
// avra_box.h, which is pure LAYOUT shared with the backend: a platform
// predicate is not a layout, and the backend includes the layout alone.
#ifndef AVRA_PLATFORM_H
#define AVRA_PLATFORM_H

// The caller's own address, where the accounting names a site. A
// WebAssembly module has no return-address read, so the instruments
// that use it carry no site there rather than fail to compile.
#if defined(__wasm32__)
#define AVRA_CALLER() ((void*)0)
#else
#define AVRA_CALLER() __builtin_return_address(0)
#endif

// Whether the allocator says how many bytes it holds. wasi-libc's does
// not, so a memory ceiling has nothing to measure there.
#if defined(__wasm32__)
#define AVRA_MEASURES_MEMORY 0
#else
#define AVRA_MEASURES_MEMORY 1
#endif

// THE INSTRUMENTS — the ledger's report, the reference guard, the alias
// log, a pinned hash seed — are switched on by the environment, at
// load. A runtime built AVRA_INSTRUMENTS=0 has no switch to read: each
// is the constant 0, so the bodies behind it are in nothing it links.
#ifndef AVRA_INSTRUMENTS
#define AVRA_INSTRUMENTS 1
#endif

// THE TICK: the scheduler's nudge that time passed while tasks were
// ready — one byte the scheduler reads (`avra_tick`) and its source
// sets. The SOURCE is the target's: a hosted target runs a thread, a
// target with a timer interrupt sets the byte there, wasm has neither
// and never preempts. The scheduler calls these two verbs to bring the
// source up and let it stand down; a target with no source defines
// them empty. They live in an object of their own, never in the
// scheduler's `runtime/*.c`, so a kernel with no threads still builds
// the scheduler (D7).
void avra_tick_armed(void);
void avra_tick_stood_down(void);
// How many times a cold arm has read the process id. A test holds the hot
// arm to reading none: the count stands still across it.
uint64_t avra_tick_pid_reads(void);

#endif
