# Avra all the way down

**Status:** plan, filed 2026-09-30, not scheduled. Epic `avra-8sb5.62`.
**Goal:** the runtime and every package shim written in Avra. C remains
only at the OS boundary, and only where the OS itself is a C API.

## 1. Where the C is today

| layer | size | role |
|---|---|---|
| `runtime/*.c` | ~5,500 lines | allocator, box headers, refcounts, lists and `Bytes`, scans, fiber scheduler, poller |
| `std-net`'s C | ~450 lines | shims over sockets, kqueue/epoll, DNS |
| `std-tls` glue | ~820 lines | the engine's edge |
| vendored mbedTLS | ~94,000 lines | crypto |

The HTTP logic (`std-http`, ~2,900 lines) is already all Avra.

The speed gap to the fastest servers is not in C. Syscalls per request
already equal the C floor (REUSE_IN_PLACE §22). What remains is about
29 small `Bytes` boxes per request (`make census-types`), and that is
compiler work.

## 2. Is it possible

Yes, down to the OS boundary. Zig and Rust write their allocators,
schedulers, SIMD scans and syscalls in the language, through a fenced
low-level subset. The one boundary no language removes is the OS
interface. On macOS that is libc, because the syscall ABI is not stable.
Calling `read` through an `extern fn` is using the OS, not writing C.
On Linux, raw syscalls are also possible.

## 3. What the language needs (`avra-8sb5.62.1`)

1. **A raw fragment** (`.62.1.1`). Pointer arithmetic, width-typed
   loads and stores, and unmanaged values with no header and no count.
   The runtime cannot count its own internals. The headered-pointer law
   still holds for every value Avra hands a program. This fragment is
   where that law is implemented, not where it is waived.
2. **Atomics with memory ordering** (`.62.1.2`). The allocator and the
   scheduler need them, and fork-join's atomic retains do too.
3. **SIMD** (`.62.1.3`). This one decides speed. libc's `memchr` is fast
   because of vectors, and header scanning is the per-request hot loop.
   The shape is the Bend doc's §5.1b: a vectorisable fragment where
   vectorisation is a checked claim `explain` reports, plus an explicit
   vector value for hand-tuned scans. The receipt is an Avra `index_of`
   within 10% of libc `memchr`.
4. **An intrinsic seat and a narrow inline-asm escape** (`.62.1.4`,
   P8). For the fiber context switch, Linux raw syscalls and CPU
   feature probes.

## 4. The ports, cheapest and safest first

| step | ticket | blocked on |
|---|---|---|
| 1. `std-net`'s shims become direct libc `extern fn`s | `.62.2` | nothing |
| 2. `Bytes` scans in SIMD Avra | `.62.3` | SIMD |
| 3. Allocator and refcounts | `.62.4` | raw fragment, atomics |
| 4. Fiber scheduler, timers, poller | `.62.5` | intrinsics, step 3 |
| 5. Crypto, last and maybe never | `.62.6` | constant-time laws |

Crypto stays vendored until the compiler can prove constant time: a law
that refuses a branch or an index on a secret-typed value. Until then,
mbedTLS plus verified primitives (the Everest X25519 already in use) is
the safe choice.

## 5. How each swap is proven

A port replaces a C function only when all four hold:

1. **An equivalence law.** For example
   `avra_index_of(b, x) == c_index_of(b, x)` for all `b`, `x`, checked
   by generated and shrunk cases (Bend doc §3, rung 2), with the C row
   kept as the oracle until the swap lands.
2. **`eval == native`** on every program test that reaches it.
3. **No regression** in `make census` counts or in `tools/bench/request`
   and `tools/bench/public.sh` on a quiet Sprite.
4. **Sizes held** by `make sizes`, since dead-code linking
   (`avra-8sb5.34.44`) now makes every byte visible.

## 6. What the parallel features do and do not buy

- One share-nothing process per core is already the optimal HTTP
  layout, so fork-join does not cut per-request cost.
- `par for` and fork-join help data-parallel work: bulk parsing,
  compression, crypto on large payloads.
- SIMD is the parallelism that matters per request.
- Laws are what make the whole port safe to do at all.
