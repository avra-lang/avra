# Avra with no OS — what it would take (design note; nothing here is built)

Ticket `avra-8sb5.85` (future). The gate that exists today is `make footprint` (PR #330, `avra-8sb5.34.53.30`). Base `380b909`. A number is MEASURED (the lane's Sprite, Linux x86-64, clang 22.1.2), PROBED by someone else and cited, GENERAL (common knowledge, not measured here) or ESTIMATE. `r:` is `runtime/avra_runtime.c`, `f:` is `runtime/avra_fiber.c`.

**In plain words.** Go is criticised on small machines because every Go program carries the whole runtime: collector, scheduler, a megabyte before the first line. Avra does not work that way: a program links only the runtime pieces it reaches, and there is no collector. A one-line Avra program is 27 KB on Linux; Go's is 1.6 MB. That is the good half. The other half: Avra still needs an operating system and a C library underneath, and every string, list and map lives on a heap. Rust's `no_std` needs neither. Getting there is three separate steps, and only the first two are realistic.

## 1. What a binary depends on today (MEASURED, `nm -u`)
| layer | size | what it asks the system for |
|---|---|---|
| `println("hi")` | 26,856 B file, 22,848 stripped, text 11,488, **bss 3,147,232** | `malloc`, stdio (`fputs fputc fwrite fflush`), `exit`, `getenv`, `getpid`, `getrandom`, `clock_gettime`, `signal`, `mallinfo2`, `dl_iterate_phdr`, `memcpy`, `strlen` |
| + text, a list, a map (`tools/footprint/data`) | 35,200 stripped, text 27,335 | adds `free realloc calloc memmove memset memmem bcmp abort` |
| + one `spawn` (`tools/footprint/spawns`) | 52,712 file, text 31,647 | adds `mmap munmap mprotect madvise sigaltstack sigaction epoll_create1 epoll_wait sysconf open fopen fscanf write _exit` |
| + `sleep(ms(1))` and no spawn | 38,904 file | links `avra_fiber_sleep`, `_yield`, `_switch`: **a wait is enough to link the scheduler** |
| `@std/*` C, per object | text 77 (`std_time`) to 6,645 (`std_net`) | `std_io`: files; `std_io_watch`: inotify; `std_net`: sockets, `epoll_*`, `pthread_create`, `getaddrinfo`; `std_process`: `posix_spawn`, `poll`, `waitpid` |

By archive member: `avra_hot.o` names **0** libc symbols, `avra_runtime.o` 69, `avra_fiber.o` 29, `avra_cores.o` 24. The 3 MB of bss is one table, `g_sites` (r:258-260, the memory instruments). The runtime already has a switch for it: built with `AVRA_INSTRUMENTS=0` (`runtime/avra_platform.h:27-30`) the same program is **17,568 B, 14,632 stripped, text 7,901, bss 360** (MEASURED by hand-linking; no `avra build` flag reaches it on a native target).

## 2. Three things people mean by "no runtime"
**(a) A small static binary on an OS.** Close. Static against glibc: Avra 838,816 B, a C `puts` 825,280 B, so Avra's own share is about 13.5 KB and the rest is glibc. A musl link was NOT measured (no musl on the Sprite). What is missing is a link mode, not a design.

| hello, Linux x86-64, MEASURED | bytes |
|---|---:|
| C, clang -O2, dynamic | 16,000 |
| Avra, instruments off / as shipped | 17,568 / 26,856 |
| Avra wasm32 floor (`tools/wasm-size.baseline:8`) | 30,326 |
| Rust 1.90 `std`, `opt-level=z`, stripped | 363,312 |
| Go 1.25.1 `println`, as built / `-s -w` | 1,623,257 / 1,069,240 |

GENERAL, not measured here: Rust `no_std` and Zig `ReleaseSmall` reach hundreds of bytes to a few KB with no libc; TinyGo reaches tens of KB on microcontrollers by replacing Go's runtime. Avra today is in Rust-`std` territory for dependencies (needs libc) and below it for size.

**(b) No OS, but a heap.** Possible, and the wasm32 port is the precedent: it already runs with no fork, no stack switching and neither scheduler object (`tools/wasm-archive.sh`). What must change: (1) every box comes from `fresh()` (r:609-611), which calls `malloc`; list buffers `realloc` (r:1442) and map indexes `calloc` (r:2214) beside it — all three need one pool behind them and an answer for "the pool is full" (a trap by name); (2) `avra_runtime.c` is one 4,093-line object mixing boxes with files, processes, directories and `mmap` (its `#include`s at r:3153-3156, r:3600-3629), separated only by `--gc-sections` — a core/OS split by file makes the boundary visible; (3) output, time, randomness (the hash seed) and exit become five or six functions a board supplies; `avra_platform.h` is 32 lines and three predicates today, all about wasm; (4) a compiler target for a bare triple, as `--target wasm` is one.

**(c) No heap at all.** Not coherent as Avra. Every string, list, map, closure, multi-field record, payload enum and task is a box with the 16-byte header (`runtime/avra_box.h:40-45`); interpolation, `+` on text and every comprehension allocate. What survives without a heap is integers, floats, bools, one-scalar-field records (they travel as the field) and `const` aggregates (immortal data in the binary, `Ins.StaticAddr`). That is a C-like subset with constant tables, not the language. Recommendation: do not promise (c); promise (b) with a fixed pool, which is what most "embedded Rust with `alloc`" projects actually run.

## 3. Tasks on a small device
A fixed pool of small stacks, no poller, timers from a tick. Against slice 01's decisions:
- **256 KiB reservation per stack (f:788) hurts.** It is cheap only because the OS commits pages on touch (resident 4.1 KiB a stack, PROBED, `docs/2026_10_06_FLOW_01_DESIGN.md:72`). With no MMU a reservation IS the memory: stacks become a static array of N × 2–8 KiB, and the size is a build constant, not `AVRA_FIBER_STACK` read from the environment (f:898).
- **The guard policy helps.** One function decides it (`guards_settle`, FLOW_01:74), and its fallback — a canary word checked at every switch-out — needs no `mprotect`. A device runs "K = 0" all the time.
- **The 448-byte task head (PROBED, FLOW_01:2) is acceptable** next to a 2 KiB stack; the four-slot table (`runtime/avra_runtime.h:27-28`, 40 B, fixed, in the core runtime) helps: no allocation, no scheduler needed to read it.
- **The poller hurts by being in the same object.** `spawns` waits on no descriptor and still links `epoll_create1`/`epoll_wait` (f:487-489, f:715-725). Timers (f:384-386, a growing array) and gates would be the whole device scheduler; descriptor waits would not exist.
- The switch is assembly for arm64 and x86-64 only (f:63, f:106); a Cortex-M or RISC-V port is a third and fourth body.

## 4. DOORS — rules for channels slices 02–19 that keep (b) possible
| # | rule | true on main today? | slices that could break it |
|---|---|---|---|
| D1 | A program that neither spawns nor waits links no scheduler object | YES, held by `make footprint` | 3 (if the cancel flag every fn checks lives in `avra_fiber.o` — keep it in `avra_task_local`, r:3311), 2 (a virtual clock read by non-task code), 5 (channel code placed in `avra_runtime.c`) |
| D2 | `avra_hot.o` calls nothing in libc | YES, 0 names MEASURED; not gated | 3 (a cancel or deadline check added to a hot leaf) |
| D3 | A new OS call lands in the scheduler, cores or a package object — never in the box, text, list or map code | PARTLY: true of the code paths, invisible in the file (`avra_runtime.o` names 69) | 6 (`avra_wait_sig`), 9, 14 (`avra_wait_exit`), 16 |
| D4 | Descriptor waits stay separable from timers and gates: nothing a timer or gate wait runs may require the poller | NO at link level (one object; `spawns` links epoll) — YES in control flow is unverified | 1b–6: every new wait kind |
| D5 | Every capacity is a stated constant or a declared number, never unbounded and never environment-only | PARTLY: slots 4, `HELD` waiters, channel capacity is in the source (law 4); the timer array and the waiter overflow list (`Over* more`, f:202) grow | 5 (`produce` buffers), 7 (`capacity:`), 10 (fault tables) |
| D6 | Server-sized static tables sit behind `AVRA_INSTRUMENTS` or in the scheduler object | YES for `g_sites` (bss 360 B with it off); `g_fd_buf` is 1 MiB in the core object (r:3262-3263), dropped only when unreached | 2 (trace buffers, f:301-307), 10 |
| D7 | No thread and no thread-local in `runtime/*.c` | YES (none found by grep); `std_net.o` uses `pthread_create` | 9 (fibers F4 offload), 16, BEND threads |
| D8 | New heap structures allocate through `box_alloc`/`fresh` or ONE named buffer door | PARTLY: boxes yes; lists `realloc`, map indexes `calloc`, fiber records `malloc` (f:259) | 1b, 5 (channel buffers), 7 |

## 5. Cost, as a ladder (every size an ESTIMATE)
1. **A small profile on an OS**: an `AVRA_INSTRUMENTS=0` archive beside the normal one and a build flag that picks it (as the wasm archive is built). ~150 lines. Buys 27 KB → 17.5 KB and bss 3 MB → 360 B. **Do this first**: it is the only step that pays today, and it puts a second runtime configuration under the gate so the rest has somewhere to stand.
2. **A static/musl link word.** ~50 lines plus musl in the CI image. Buys tier (a) with a measured number.
3. **Split `avra_runtime.c` into core and OS files**; gate "the core object names only the allocator, `mem*` and the platform functions". No new logic, ~4,000 lines re-homed, one keeper. Makes D3 checkable.
4. **The platform seam**: output, clock, random, exit, allocate, release as functions in `avra_platform.h` with the libc bodies as one implementation. ~600–1,000 lines touched.
5. **A fixed-pool allocator** behind `fresh`, the buffer door and the map index, with a named out-of-memory trap. ~300 lines plus tests.
6. **A bare target** (one triple, startup, UART `write`, trap = halt), modelled on the wasm32 port (`docs/2026_10_02_WASM32.md`). ~1,500 lines; needs hardware or QEMU in CI.
7. **A device scheduler**: static stack pool, canary-only guards, tick timers, gates, no descriptors; a switch for one more architecture. ~800 lines of C plus assembly, and an adversarial review like slice 01's.

Steps 1–2 are days and independent of channels. Steps 3–5 are a campaign of their own and should wait until channels slices 1–6 stop moving the scheduler. Steps 6–7 only make sense with a named board and a user.

## Unverified
musl; macOS numbers; whether timers and gates run without the poller being initialised (D4's control-flow half); the 448 B and 4.1 KiB figures (cited, not re-measured); `size`'s "text" on ELF includes read-only data.
