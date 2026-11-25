# avra-lane-emit-speed-3 — the link floor: a DEV build that does not relink the world

Linux sandbox, 4 cores. Measured on the cli's real link inputs, frozen from a cold
new-pipeline build on 763009d7 + lane -2:
- 32 bucket objects (51 MB);
- the packages' own C (llvm_wrapper.o, ffi.o, std_*.o, std_hash.a);
- libavra_runtime.a;
- static LLVM (about 70 -lLLVM* archives).

Times are medians of 5 runs unless noted (min–max in brackets). Nothing here is committed. The
prototype is a scratch script.

## Where the 0.3–0.4 s goes
| link | wall | output |
|---|---|---|
| today: lld, static LLVM | 0.39 s (0.36–0.41) | 92 MB (65 MB of it is LLVM) |
| lld, LLVM as libLLVM-22.so | 0.19 s (0.17–0.21) | 27 MB |

lld's time follows the output's size, not the number of inputs (next section).

## Options
| option | warm-edit link | cold link cost | runtime (`check std-program`, 3 runs) | startup (`--help`) |
|---|---|---|---|---|
| A. today, one static binary | 0.39 s | 0.39 s | 13.72 / 13.37 / 13.60 s | 4.8 ms |
| B. same, LLVM shared | 0.19 s | 0.19 s | 14.27 / 14.09 / 13.53 s | 10.3 ms |
| C. `ld -r` pre-linked world (31 buckets + package C), final link world.o + 1 bucket | 0.35 s (static LLVM) / 0.195 s (shared) | +0.78–0.82 s for the `ld -r` | same binary as A/B | same as A/B |
| D. one .so per bucket (32) + libpkgs.so, exe = runtime + 33 .so | 0.033 s (median bucket, 950 KiB) / 0.042 s (largest, 2.4 MB): only the edited bucket's .so | 32 .so serial 1.15 s + pkgs 0.085 s + exe 0.09 s | 17.91 / 17.92 / 18.01 s (+32%); with -Bsymbolic-functions 16.78 / 16.94 / 17.46 s (+25%) | 15.8 ms lazy / 22.5 ms bind-now |
| E. two levels: libworld.so (unchanged buckets + runtime + package C, -Bsymbolic-functions) + libov.so (the edited buckets) + a 6 KB exe that needs ov then world | 0.04 s (0.037–0.048): the overlay only | world 0.17 s + overlay 0.04 s + exe 0.094 s ≈ 0.30 s | 13.31 / 13.27 / 13.16 s (= A) | 9.8 ms |
| F. gold --incremental (lld has no incremental mode; neither mold nor wild is installed) | 0.82–0.95 s static LLVM / 0.20 s shared | 1.36 / 0.34 s | — | — |

The behaviour check covers B, D and E. Each binary ran the old-path `check std-program`, and its
stdout and stderr are identical to A's, exit 0. Each B/D/E binary was linked from the very same
objects as A, so no generated code differs.

### Why D costs at run time and E does not
In D, every call between buckets, and every runtime call (rc, boxes), crosses a .so boundary
through the PLT. At opt 0 the hot runtime leaves are not inlined, so those calls are frequent.
In E, everything that did not change, runtime included, sits in one .so whose calls bind directly
(-Bsymbolic-functions). Only calls into or out of the overlay go through the PLT.

### What E costs, exactly
- **Overlay rule.** The world must not hold a bucket the overlay holds: with -Bsymbolic-functions the world would keep calling its own stale copy. So the overlay set is "the buckets this dev session has re-emitted since the world was linked".
  - An edit that only re-touches overlay buckets relinks the overlay: 0.04 s.
  - An edit that touches a new bucket also relinks the world without it: 0.17 s, so 0.21 s total.
  - A one-literal cli edit owes 2 buckets: its home bucket and the code-hash bucket 31. The overlay therefore always holds bucket 31.
- **The exe** needs relinking only when the set of .so names changes. Name them by role (world, overlay), not by content, and replace each atomically.
- **Product behaviour.**
  - Process-wide state must exist once. The runtime lives only in the world, and every bucket's statics are private, so they are unaffected.
  - Weak-ODR instantiations duplicated across world and overlay bind to the first definition the loader sees. That is the same code, so it is safe while the bodies agree, which they do: one tree, one key.
  - Function-pointer identity across the two .so files goes through the GOT and stays canonical.
  - Unmeasured: anything that reads its own symbols by address range or dladdr.
- **Release stays A:** one static binary, the cache keys unchanged. DEV is a different link of the same objects, so the binary key must name the mode.

## macOS (unmeasured; ld64 there)
- B: Homebrew ships libLLVM.dylib, so -lLLVM there.
- D/E: dylibs. With ld64's two-level namespace a call binds to (library, symbol), so an overlay does not override the world by load order.
  - E would need the world linked with `-undefined dynamic_lookup` for the overlay's symbols, and the world must not define them (the same overlay rule).
  - Or the world could be linked `-flat_namespace`, which makes every call interposable, which is D's cost.
- C: `ld -r` works with ld64 too.
- None of this has been run on the Mac. ld64 (ld-prime) link times there are also unmeasured.

## Recommendation
- **First step, and the cheapest one: B.** Halves every native link (0.39 → 0.19 s), runtime unchanged within noise, startup +5.5 ms. The program layer already chooses the link words. It does not reach 300 ms by itself on a warm edit, because the link alone is ~0.2 s.
- **Then E for DEV builds.** A warm edit links 0.04 s (0.21 s when a new bucket joins the overlay). Runtime is the same as static, startup 9.8 ms.
  - Cost: two link shapes to keep green, and the overlay rule above.
  - The prototype is a handful of clang invocations. Making it real is about 150 lines in tapes.av's bucket_kept and link_refused, plus the key naming the mode.
- **Not C, not F:** no real gain.
- **Not D as the dev product:** +25–32% runtime.
