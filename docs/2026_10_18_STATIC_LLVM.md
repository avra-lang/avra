# The compiler links LLVM statically

Status: built (a bridge: the image and Sprite side, #991, lands first). Owner: db-warm.

## Why

Every `avra` command pays the dynamic loader for libLLVM before it runs a line:
`avra --version` is 24 ms on a Sprite, where fork+exec of `true` is 5.3 ms and a
native Avra hello 6.3 ms. A C `main(){return 0;}` linked against `libLLVM.so.22`
costs 20.7 ms against 5.9 ms without it. Callgrind of `--version` is 22.2M
instructions, ~75% in ld.so relocation and symbol lookup (260k relative and 14k
symbol relocations of the shared library) plus LLVM's static constructors; Avra's
own code is negligible. `check`, `fmt` and `explain` never emit LLVM.

## Measured (Sprite, Linux x86-64, LLVM 22.1.2 distro static archives, same compiler source)

| link | `avra --version` | binary | relative relocs |
|---|---|---|---|
| shared libLLVM (today) | 22.6-24.6 ms | 20 MB + 150 MB `.so` | 260 k (+ 14 k symbol) |
| static LLVM, PIE | 13.9-16.4 ms | 88 MB | 137 k |
| static LLVM, `-no-pie` | 12.6 ms | 85 MB | 2 k |
| `true` (floor) | 5.2-5.5 ms | | |

Static plus `-no-pie` removes ~12 ms of the ~19 ms above the floor; what is left is
LLVM's static constructors, page faults and the CLI's own start. The static binary
builds and runs: it compiled and ran a program, and `check packages/cli` exits 0. Its
`[link] libs` were the 49 components `llvm-config --link-static --libs core analysis
bitwriter bitreader linker passes native webassembly target irreader` names, plus
`z`, `zstd` (system shared), `stdc++`, `pthread`, `dl`, `m`. A restricted set of
targets (native + WebAssembly, the two the wrapper initializes) is what keeps it
85 MB and not the 354 MB of all archives.

## Versus a lazy `dlopen`

A `libavra_llvm` loaded on first use would also remove the cost for non-emitting
commands, but it adds a second artifact to find at run time (against P14: no
runtime, no container, one binary), 98 generated stubs from the wrapper's rows, and
the same two link sites. Static linking needs no stubs and no second file; it spends
disk (85 MB) and link time (+~20 s on the Sprite) instead, both paid by the
compiler's own build, never a user's program.

## As built

- `packages/std-avrac/avra.toml` `[link] libs` names the static component libraries in
  `llvm-config --link-static`'s order, AArch64 and WebAssembly beside X86 so one list
  serves both hosts, then `z`, `zstd`, `${AVRA_CXX_RUNTIME}`, `pthread`, `dl`, `m`.
  `[link]` takes library NAMES only (a dependency's option would otherwise reach the
  linker), so no flag and no response file rides it.
- `tools/llvm_link.py --words` gives those words to the hand-written clang lines
  (`make recover`, `make seed-check`) from the same manifest row; `--check` (`make
  llvm-libs`, part of `gate`) holds the list to `llvm-config` and the archives on disk.
- `AVRA_CXX_RUNTIME` is `stdc++` (Linux) or `c++` (macOS), set by the Makefile, the `./avra`
  shim, the CI image's ENV and a Sprite's profile; `AVRA_SYS_SEARCH` adds
  `/opt/homebrew/lib` on macOS (zstd). #991 carries the image and Sprite side
  (`libzstd-dev`, `zlib1g-dev`, the variable) and lands first.
- No compiler change, so no seed refresh: the seed links through the Makefile's words.

## Receipts

- `make bootstrap` green on a Sprite (`cp build/avra build/avra.pre` first): recover (the
  seed linked static), gen-1, gen-2, 394 s, `build/avra` 88.7 MB, `avra --version` runs.
- `check packages/cli` exits 0 and a program compiles and runs with the static compiler.
- Link time: the cli's final link is 5.8-7.2 s on 8 cores and 6.4 s pinned to 4 cores
  (`taskset -c 0-3`), against ~1.9 s with the shared library.
- macOS arm64 (Homebrew LLVM 23.1, a C program that initializes the native and WebAssembly
  targets, steady-state average of 40 runs): shared 12.6-15.5 ms, static 9.8 ms (62 MB),
  static with `-Wl,-dead_strip` 7.5 ms (46 MB), an empty C program 2.7 ms. PIE is not
  optional on arm64, so the saving there is ~3-5 ms, not Linux's ~11. The first run of a
  freshly linked binary is slower (31 ms) once. `make llvm-libs` passes against Homebrew
  (66 component libraries named, all on disk).
- CI: the hand-down tar excludes `build/avra` (`--exclude=build/avra`), so it does not
  grow. The `avra-compiler` artifact and the published compiler grow 20 MB -> 88 MB raw,
  ~6 MB -> ~30 MB zipped (zip 29.97 MB, gzip -6 30.0 MB), downloaded by each job that
  needs the compiler.

## Not here

`-rdynamic` stays: the evaluator resolves the image's own symbols by name. An export list
(`--export-dynamic-symbol=avra_*`) with `--gc-sections` measured 70.8 MB and 5.8 s link
(vs 87.9 MB and 7.2 s) with the same start-up; it is a follow-up that needs the
evaluator's whole symbol set proved first. macOS `-dead_strip` is likewise not wired.

## Risks

CI's image must carry the static archives and zstd (`libllvm-22-dev`, `libzstd-dev`; the
Sprites show 231 `.a`), and macOS Homebrew's LLVM carries them. A link-flag error leaves
no compiler, so `cp build/avra build/avra.pre` first, as for any link change.
